//
//  SystemMonitor.swift
//  ClassGod
//

import Foundation
import Darwin
import Combine
import IOKit.ps

// MARK: - Data Models

struct CPUUsage: Equatable {
    var total: Double = 0
    var user: Double = 0
    var system: Double = 0
    var idle: Double = 0
}

struct MemoryUsage: Equatable {
    var total: UInt64 = 0
    var used: UInt64 = 0
    var free: UInt64 = 0
    var wired: UInt64 = 0
    var compressed: UInt64 = 0
    
    var usedPercent: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total)
    }
}

struct DiskInfo: Equatable, Identifiable {
    let id = UUID()
    var name: String
    var path: String
    var total: Int64
    var free: Int64
    var used: Int64 { total - free }
    var usedPercent: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total)
    }
}

struct NetworkStats: Equatable {
    var bytesIn: UInt64 = 0
    var bytesOut: UInt64 = 0
    var deltaIn: Double = 0
    var deltaOut: Double = 0
    
    var downloadSpeedKBs: Double { deltaIn / 1024 }
    var uploadSpeedKBs: Double { deltaOut / 1024 }
}

struct ProcessMonitorInfo: Equatable, Identifiable {
    var id: Int32 { pid }
    var pid: Int32
    var name: String
    var commandLine: String?
    var executablePath: String?
    var cpuPercent: Double
    var memoryMB: Double
    var uid: UInt32 = 0
    var threads: Int32 = 0
    var diskReadBytes: UInt64 = 0
    var diskWriteBytes: UInt64 = 0
    var diskReadBytesPerSecond: UInt64 = 0
    var diskWriteBytesPerSecond: UInt64 = 0
    var energyNanojoules: UInt64 = 0
    var energyNanojoulesPerSecond: UInt64 = 0
    var isEstimatedNetwork: Bool = false
    var networkRecvBytes: UInt64 = 0
    var networkSentBytes: UInt64 = 0
    var networkRecvBytesPerSecond: UInt64 = 0
    var networkSentBytesPerSecond: UInt64 = 0
}

struct BatteryInfo: Equatable {
    var isPresent: Bool = false
    var isCharging: Bool = false
    var level: Double = 0
    var timeRemaining: Int = -1
    var cycleCount: Int = 0
    var health: Double = 100
}

struct ThermalInfo: Equatable {
    var cpuTemp: Double = 0
    var gpuTemp: Double = 0
}

struct SystemInfo: Equatable {
    var hostname: String = ""
    var osVersion: String = ""
    var kernelVersion: String = ""
    var architecture: String = ""
    var model: String = ""
    var bootTime: Date?
}

// MARK: - System Monitor

final class SystemMonitor: ObservableObject, @unchecked Sendable {
    static let shared = SystemMonitor()
    
    @Published var cpu = CPUUsage()
    @Published var memory = MemoryUsage()
    @Published var disks: [DiskInfo] = []
    @Published var network = NetworkStats()
    @Published var processes: [ProcessMonitorInfo] = []
    @Published var battery = BatteryInfo()
    @Published var thermal = ThermalInfo()
    @Published var system = SystemInfo()
    
    private var timer: Timer?
    private var updateInterval: TimeInterval = 1.0
    private var previousCPUInfo: host_cpu_load_info?
    private var previousNetworkBytesIn: UInt64 = 0
    private var previousNetworkBytesOut: UInt64 = 0
    private var startCount = 0
    
    // Per-process IO / energy / CPU time history for delta calculation
    private var previousProcessRUsage: [Int32: (diskRead: UInt64, diskWrite: UInt64, energy: UInt64)] = [:]
    private var previousProcessTaskTimes: [Int32: (user: UInt64, system: UInt64)] = [:]
    
    private init() {
        loadStaticSystemInfo()
    }
    
    @MainActor
    func start(interval: TimeInterval = 1.0) {
        startCount += 1
        updateInterval = interval
        NettopMonitor.shared.start()
        timer?.invalidate()
        updateAll()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateAll()
            }
        }
    }
    
    @MainActor
    func stop() {
        startCount = max(0, startCount - 1)
        guard startCount == 0 else { return }
        timer?.invalidate()
        timer = nil
        NettopMonitor.shared.stop()
    }
    
    private func updateAll() {
        readCPU()
        readMemory()
        readDisks()
        readNetwork()
        readProcesses()
        readBattery()
        readThermal()
    }
    
    // MARK: - CPU
    
    private func readCPU() {
        var cpuInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }
        
        let user = Double(cpuInfo.cpu_ticks.0)
        let system = Double(cpuInfo.cpu_ticks.1)
        let idle = Double(cpuInfo.cpu_ticks.2)
        let nice = Double(cpuInfo.cpu_ticks.3)
        let total = user + system + idle + nice
        
        if let prev = previousCPUInfo {
            let prevTotal = Double(prev.cpu_ticks.0 + prev.cpu_ticks.1 + prev.cpu_ticks.2 + prev.cpu_ticks.3)
            let currTotal = total
            let totalDelta = currTotal - prevTotal
            
            if totalDelta > 0 {
                let userDelta = Double(cpuInfo.cpu_ticks.0 - prev.cpu_ticks.0)
                let systemDelta = Double(cpuInfo.cpu_ticks.1 - prev.cpu_ticks.1)
                let idleDelta = Double(cpuInfo.cpu_ticks.2 - prev.cpu_ticks.2)
                
                self.cpu = CPUUsage(
                    total: 100.0 * (1.0 - idleDelta / totalDelta),
                    user: 100.0 * userDelta / totalDelta,
                    system: 100.0 * systemDelta / totalDelta,
                    idle: 100.0 * idleDelta / totalDelta
                )
            }
        }
        
        previousCPUInfo = cpuInfo
    }
    
    // MARK: - Memory
    
    private func readMemory() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }
        
        let pageSize = UInt64(vm_kernel_page_size)
        let free = UInt64(stats.free_count) * pageSize
        let active = UInt64(stats.active_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        
        let used = active + inactive + wired + compressed
        let total = used + free
        
        self.memory = MemoryUsage(
            total: total,
            used: used,
            free: free,
            wired: wired,
            compressed: compressed
        )
    }
    
    // MARK: - Disk
    
    private func readDisks() {
        let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: [.skipHiddenVolumes]) ?? []
        var infos: [DiskInfo] = []
        
        for url in urls {
            do {
                let values = try url.resourceValues(forKeys: [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey])
                if let total = values.volumeTotalCapacity,
                   let free = values.volumeAvailableCapacity,
                   total > 0 {
                    let name = values.volumeName ?? url.pathComponents.last ?? "Disk"
                    infos.append(DiskInfo(name: name, path: url.path, total: Int64(total), free: Int64(free)))
                }
            } catch { }
        }
        
        self.disks = infos.sorted { $0.name < $1.name }
    }
    
    // MARK: - Network
    
    private func readNetwork() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }
        
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        
        var ptr = first
        while true {
            let interface = ptr.pointee
            if let data = interface.ifa_data?.withMemoryRebound(to: if_data.self, capacity: 1, { $0 }).pointee,
               String(cString: interface.ifa_name) != "lo0" {
                totalIn += UInt64(data.ifi_ibytes)
                totalOut += UInt64(data.ifi_obytes)
            }
            if interface.ifa_next == nil { break }
            ptr = interface.ifa_next!
        }
        
        let deltaIn = totalIn >= previousNetworkBytesIn ? totalIn - previousNetworkBytesIn : 0
        let deltaOut = totalOut >= previousNetworkBytesOut ? totalOut - previousNetworkBytesOut : 0
        
        self.network = NetworkStats(
            bytesIn: totalIn,
            bytesOut: totalOut,
            deltaIn: Double(deltaIn),
            deltaOut: Double(deltaOut)
        )
        
        previousNetworkBytesIn = totalIn
        previousNetworkBytesOut = totalOut
    }
    
    // MARK: - Processes
    
    private struct ProcessSample {
        let pid: Int32
        let info: ProcessMonitorInfo
        let rusage: (diskRead: UInt64, diskWrite: UInt64, energy: UInt64)
        let taskTimes: (user: UInt64, system: UInt64)
    }
    
    private func readProcesses() {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size = 0
        sysctl(&mib, u_int(mib.count), nil, &size, nil, 0)
        
        let count = size / MemoryLayout<kinfo_proc>.stride
        var procs = [kinfo_proc](repeating: kinfo_proc(), count: count)
        let result = sysctl(&mib, u_int(mib.count), &procs, &size, nil, 0)
        guard result == 0 else { return }
        
        let nettop = NettopMonitor.shared.currentDeltas()
        let interval = max(updateInterval, 0.1)
        let processorCount = max(1, ProcessInfo.processInfo.processorCount)
        
        // Snapshot previous history locally so concurrent workers can read safely.
        let prevRUsage = previousProcessRUsage
        let prevTaskTimes = previousProcessTaskTimes
        
        // Offload the heavy per-process work to a background queue so the
        // main thread never blocks on group.wait().
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            
            let queue = DispatchQueue(label: "com.classgod.sysmon.procs", qos: .userInitiated, attributes: .concurrent)
            let group = DispatchGroup()
            let lock = NSLock()
            var samples: [ProcessSample] = []
            
            for proc in procs {
                let pid = proc.kp_proc.p_pid
                guard pid > 0 else { continue }
                
                group.enter()
                queue.async {
                    defer { group.leave() }
                    
                    // Process name / path
                    var exePath = ""
                    var pathBuffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
                    if proc_pidpath(pid, &pathBuffer, UInt32(MAXPATHLEN)) > 0 {
                        exePath = String(cString: pathBuffer)
                    }
                    
                    let comm: String = {
                        if !exePath.isEmpty {
                            let name = (exePath as NSString).lastPathComponent
                            if !name.isEmpty { return name }
                        }
                        return withUnsafeBytes(of: proc.kp_proc.p_comm) { ptr -> String in
                            let buffer = ptr.bindMemory(to: CChar.self)
                            guard let addr = buffer.baseAddress else { return "?" }
                            return String(cString: addr)
                        }
                    }()
                    
                    // Detailed task info (resident memory, thread count, CPU time)
                    var taskinfo = proc_taskinfo()
                    let taskInfoSize = Int32(MemoryLayout<proc_taskinfo>.size)
                    var residentBytes: UInt64 = 0
                    var threads: Int32 = 0
                    var userTime: UInt64 = 0
                    var systemTime: UInt64 = 0
                    let taskRet = withUnsafeMutablePointer(to: &taskinfo) {
                        proc_pidinfo(pid, PROC_PIDTASKINFO, 0, $0, taskInfoSize)
                    }
                    if taskRet == taskInfoSize {
                        residentBytes = taskinfo.pti_resident_size
                        threads = taskinfo.pti_threadnum
                        userTime = taskinfo.pti_total_user
                        systemTime = taskinfo.pti_total_system
                    }
                    
                    // CPU % from task time delta (much more accurate than p_pctcpu)
                    let cpu: Double
                    if let prev = prevTaskTimes[pid] {
                        let userDelta = userTime >= prev.user ? userTime - prev.user : 0
                        let sysDelta  = systemTime >= prev.system ? systemTime - prev.system : 0
                        let totalDeltaNs = Double(userDelta + sysDelta)
                        // Normalize to percentage across all cores.
                        cpu = (totalDeltaNs / (interval * 1_000_000_000.0)) * 100.0 / Double(processorCount)
                    } else {
                        cpu = Double(proc.kp_proc.p_pctcpu) / 1000.0
                    }
                    
                    // Rusage (disk + energy)
                    var rusage = rusage_info_v6()
                    var diskRead: UInt64 = 0
                    var diskWrite: UInt64 = 0
                    var energy: UInt64 = 0
                    let rusageRet = withUnsafeMutablePointer(to: &rusage) { ptr -> Int32 in
                        proc_pid_rusage(pid, RUSAGE_INFO_V6, UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: rusage_info_t?.self))
                    }
                    if rusageRet == 0 {
                        diskRead = rusage.ri_diskio_bytesread
                        diskWrite = rusage.ri_diskio_byteswritten
                        energy = rusage.ri_energy_nj
                    }
                    
                    let prevR = prevRUsage[pid]
                    let diskDeltaRead = prevR.map { diskRead >= $0.diskRead ? diskRead - $0.diskRead : 0 } ?? 0
                    let diskDeltaWrite = prevR.map { diskWrite >= $0.diskWrite ? diskWrite - $0.diskWrite : 0 } ?? 0
                    let energyDelta = prevR.map { energy >= $0.energy ? energy - $0.energy : 0 } ?? 0
                    
                    let uid = proc.kp_eproc.e_ucred.cr_uid
                    let net = nettop[pid]
                    let netRecv = net?.deltaIn ?? 0
                    let netSent = net?.deltaOut ?? 0
                    
                    // Clamp large deltas to avoid UInt64 overflow when converting from Double.
                    let safeBps: (UInt64) -> UInt64 = { delta in
                        let scaled = Double(delta) / interval
                        guard scaled < Double(UInt64.max) else { return UInt64.max }
                        return UInt64(scaled)
                    }
                    
                    let info = ProcessMonitorInfo(
                        pid: pid,
                        name: comm,
                        executablePath: exePath.isEmpty ? nil : exePath,
                        cpuPercent: cpu,
                        memoryMB: Double(residentBytes) / 1024.0 / 1024.0,
                        uid: uid,
                        threads: threads,
                        diskReadBytes: diskDeltaRead,
                        diskWriteBytes: diskDeltaWrite,
                        diskReadBytesPerSecond: safeBps(diskDeltaRead),
                        diskWriteBytesPerSecond: safeBps(diskDeltaWrite),
                        energyNanojoules: energy,
                        energyNanojoulesPerSecond: safeBps(energyDelta),
                        isEstimatedNetwork: net == nil,
                        networkRecvBytes: netRecv,
                        networkSentBytes: netSent,
                        networkRecvBytesPerSecond: netRecv,
                        networkSentBytesPerSecond: netSent
                    )
                    
                    let sample = ProcessSample(
                        pid: pid,
                        info: info,
                        rusage: (diskRead: diskRead, diskWrite: diskWrite, energy: energy),
                        taskTimes: (user: userTime, system: systemTime)
                    )
                    
                    lock.lock()
                    samples.append(sample)
                    lock.unlock()
                }
            }
            
            group.wait()
            
            var currentRUsage: [Int32: (diskRead: UInt64, diskWrite: UInt64, energy: UInt64)] = [:]
            var currentTaskTimes: [Int32: (user: UInt64, system: UInt64)] = [:]
            var infos: [ProcessMonitorInfo] = []
            infos.reserveCapacity(samples.count)
            for sample in samples {
                currentRUsage[sample.pid] = sample.rusage
                currentTaskTimes[sample.pid] = sample.taskTimes
                infos.append(sample.info)
            }
            
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.previousProcessRUsage = currentRUsage
                self.previousProcessTaskTimes = currentTaskTimes
                self.processes = infos.sorted { $0.cpuPercent > $1.cpuPercent }
            }
        }
    }
    
    // MARK: - Battery
    
    private func readBattery() {
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first else {
            self.battery = BatteryInfo(isPresent: false)
            return
        }
        
        guard let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else { return }
        
        let state = info[kIOPSPowerSourceStateKey] as? String
        let isCharging = state == kIOPSBatteryPowerValue
        let capacity = info[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = info[kIOPSMaxCapacityKey] as? Int ?? 100
        let time = info[kIOPSTimeToEmptyKey] as? Int ?? -1
        let cycles = info["Cycle Count" as String] as? Int ?? 0
        
        self.battery = BatteryInfo(
            isPresent: true,
            isCharging: isCharging,
            level: Double(capacity) / Double(maxCapacity),
            timeRemaining: time,
            cycleCount: cycles,
            health: 100
        )
    }
    
    // MARK: - Thermal
    
    private func readThermal() {
        // First try SMCService for real hardware temperatures
        let smcTemps = SMCService.shared.readTemperatures()
        let cpuSensors = smcTemps.filter {
            $0.name.contains("CPU") || $0.name.contains("Cluster") ||
            $0.name.contains("Package") || $0.name.contains("Thermal State")
        }
        let gpuSensors = smcTemps.filter {
            $0.name.contains("GPU") || $0.name.contains("Graphics")
        }
        
        let cpuTemp = cpuSensors.map(\.value).max() ?? 0
        let gpuTemp = gpuSensors.map(\.value).max() ?? 0
        
        if cpuTemp > 0 || gpuTemp > 0 {
            self.thermal = ThermalInfo(cpuTemp: cpuTemp, gpuTemp: gpuTemp)
            return
        }
        
        // Fallback: use ProcessInfo thermal state (official API, always available)
        let state = ProcessInfo.processInfo.thermalState
        let baseTemp: Double
        switch state {
        case .nominal: baseTemp = 35.0
        case .fair: baseTemp = 50.0
        case .serious: baseTemp = 70.0
        case .critical: baseTemp = 90.0
        @unknown default: baseTemp = 40.0
        }
        
        // Blend with CPU load for a slightly more dynamic estimate
        let loadAdjusted = baseTemp + (cpu.total * 0.2)
        self.thermal = ThermalInfo(cpuTemp: loadAdjusted, gpuTemp: loadAdjusted + 3.0)
    }
    
    // MARK: - Static Info
    
    private func loadStaticSystemInfo() {
        var uts = utsname()
        uname(&uts)
        
        let hostname = withUnsafePointer(to: &uts.nodename) {
            $0.withMemoryRebound(to: CChar.self, capacity: 256) { String(cString: $0) }
        }
        let release = withUnsafePointer(to: &uts.release) {
            $0.withMemoryRebound(to: CChar.self, capacity: 256) { String(cString: $0) }
        }
        let machine = withUnsafePointer(to: &uts.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 256) { String(cString: $0) }
        }
        
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        
        self.system = SystemInfo(
            hostname: hostname,
            osVersion: osVersion,
            kernelVersion: release,
            architecture: machine,
            model: modelIdentifier(),
            bootTime: bootTime()
        )
    }
    
    private func modelIdentifier() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }
    
    private func bootTime() -> Date? {
        var mib = [CTL_KERN, KERN_BOOTTIME]
        var boot = timeval()
        var size = MemoryLayout<timeval>.size
        let result = sysctl(&mib, 2, &boot, &size, nil, 0)
        guard result == 0 else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(boot.tv_sec) + TimeInterval(boot.tv_usec) / 1_000_000)
    }
    
    var uptimeString: String {
        guard let boot = system.bootTime else { return "--" }
        let interval = Date().timeIntervalSince(boot)
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let mins = (Int(interval) % 3600) / 60
        let secs = Int(interval) % 60
        if days > 0 {
            return String(format: "%dd %02d:%02d:%02d", days, hours, mins, secs)
        }
        return String(format: "%02d:%02d:%02d", hours, mins, secs)
    }
}
