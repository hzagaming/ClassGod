//
//  SMCService.swift
//  ClassGod
//

import Foundation
import IOKit

// MARK: - Data Models

struct TemperatureSensor: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let key: String
    var value: Double
    var maxValue: Double = 100
    var isEstimated: Bool = false
}

struct FanInfo: Identifiable, Equatable {
    let id: Int
    var name: String
    var actualRPM: Double = 0
    var minimumRPM: Double = 0
    var maximumRPM: Double = 0
    var targetRPM: Double = 0
}

enum FanControlMode: String, Codable, CaseIterable, Identifiable {
    case system = "system"
    case max = "max"
    case autoMax = "autoMax"
    case manual = "manual"
    case custom = "custom"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return "System"
        case .max: return "Max"
        case .autoMax: return "Auto Max"
        case .manual: return "Manual"
        case .custom: return "Custom"
        }
    }
}

enum TemperatureUnit: String, Codable, CaseIterable, Identifiable {
    case celsius = "celsius"
    case fahrenheit = "fahrenheit"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }

    func convert(_ celsius: Double) -> Double {
        switch self {
        case .celsius: return celsius
        case .fahrenheit: return celsius * 9.0 / 5.0 + 32.0
        }
    }

    func formatted(_ celsius: Double) -> String {
        let value = convert(celsius)
        switch self {
        case .celsius: return String(format: "%.0f°C", value)
        case .fahrenheit: return String(format: "%.0f°F", value)
        }
    }
}

// MARK: - SMC Service

private let KERNEL_INDEX_SMC: UInt32 = 2

final class SMCService {
    static let shared = SMCService()

    private var conn: io_connect_t = 0
    private(set) var isConnected = false
    private(set) var isUsingIORegistryFallback = false
    private(set) var fanAccessReason: String?
    private var cachedIORegistryTemps: [TemperatureSensor] = []
    private var hasScannedIORegistry = false
    private var cachedIORegistryFans: [FanInfo] = []
    private var hasScannedIORegistryFans = false

    // Short-term cache shared across readTemperatures/readFans consumers
    private var lastReadAll: (fans: [FanInfo], sensors: [TemperatureSensor])?
    private var lastReadAllTime: Date?
    private let readAllLock = NSLock()

    // Known sensor key mappings
    private let sensorKeys: [(name: String, key: String, max: Double)] = [
        // Intel & generic
        ("CPU Core", "TC0D", 100),
        ("CPU Proximity", "TC0P", 100),
        ("CPU Heatsink", "TC0H", 100),
        ("CPU Package", "TCAD", 100),
        ("GPU Core", "TG0D", 100),
        ("GPU Proximity", "TG0P", 100),
        ("GPU Heatsink", "TG0H", 100),
        ("Airflow Left", "TA0P", 80),
        ("Airflow Right", "TA1P", 80),
        ("Battery", "TB0T", 60),
        ("Battery 2", "TB1T", 60),
        ("Battery 3", "TB2T", 60),
        ("Memory", "Tm0P", 80),
        ("Palm Rest", "Ts0P", 50),
        ("Trackpad", "Tp0P", 50),
        // Apple Silicon CPU clusters
        ("CPU Cluster 0", "Tp09", 100),
        ("CPU Cluster 1", "Tp0T", 100),
        ("CPU Cluster 2", "Tp01", 100),
        ("CPU Cluster 3", "Tp05", 100),
        ("CPU Cluster 4", "Tp0D", 100),
        ("CPU Cluster 5", "Tp0X", 100),
        ("CPU Cluster 6", "Tp0b", 100),
        ("CPU Performance", "Tp0C", 100),
        ("CPU Efficiency", "Tp0E", 100),
        // Apple Silicon GPU
        ("GPU", "Tg05", 100),
        ("GPU 2", "Tg0D", 100),
        ("GPU 3", "Tg0F", 100),
        ("GPU 4", "Tg0H", 100),
        // Apple Silicon misc
        ("SOC", "Ts0S", 100),
        ("Airflow Top", "TA2P", 80),
        ("SSD", "Ts2S", 80),
    ]

    private init() {
        connect()
        updateFanAccessReason()
    }
    
    /// Re-scan hardware connections and clear caches. Call this when user wants to re-detect sensors/fans.
    func rescan() {
        // Close existing connection
        if conn != 0 {
            IOServiceClose(conn)
            conn = 0
        }
        isConnected = false
        isUsingIORegistryFallback = false
        fanAccessReason = nil
        cachedIORegistryTemps.removeAll()
        hasScannedIORegistry = false
        cachedIORegistryFans.removeAll()
        hasScannedIORegistryFans = false
        
        // Reconnect
        connect()
        updateFanAccessReason()
    }
    
    var isHelperAvailable: Bool {
        SMCHelperClient.shared.isHelperAvailable
    }

    private func updateFanAccessReason() {
        if isHelperAvailable {
            fanAccessReason = "Privileged helper tool is present. If sensors/fans still show N/A, restart the helper with: sudo killall ClassGodHelper; sudo /path/to/ClassGodHelper"
            return
        }
        if isConnected {
            if isAppleSiliconMac() {
                fanAccessReason = "Apple Silicon Macs restrict fan access to system processes. Run ClassGodHelper as root to enable fan control."
            } else {
                fanAccessReason = "SMC connected but no fan data returned. This Mac may not have controllable fans."
            }
        } else {
            if isAppleSiliconMac() {
                fanAccessReason = "Apple Silicon Macs restrict fan access to system processes. Run ClassGodHelper as root to enable fan control."
            } else {
                fanAccessReason = "Could not connect to SMC. Ensure ClassGod is not sandboxed and try rescanning."
            }
        }
    }
    
    var isAppleSilicon: Bool { isAppleSiliconMac() }

    private func isAppleSiliconMac() -> Bool {
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 256) { String(cString: $0) }
        }
        return machine == "arm64" || machine.hasPrefix("Apple")
    }

    deinit {
        if conn != 0 {
            IOServiceClose(conn)
            conn = 0
        }
    }

    // MARK: - Connection

    private func connect() {
        // Try Intel-style AppleSMC first
        var service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        
        // If not found, try Apple Silicon AppleSMCKeysEndpoint
        if service == 0 {
            service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMCKeysEndpoint"))
        }
        
        guard service != 0 else {
            print("[SMCService] No SMC service found (AppleSMC or AppleSMCKeysEndpoint)")
            return
        }
        defer { IOObjectRelease(service) }
        
        // Try standard connection type first
        var result = IOServiceOpen(service, mach_task_self_, 0, &conn)
        if result != KERN_SUCCESS {
            // Some Apple Silicon systems may use a different connection type
            result = IOServiceOpen(service, mach_task_self_, 1, &conn)
        }
        
        isConnected = (result == KERN_SUCCESS)
        if isConnected {
            print("[SMCService] SMC connected successfully")
        } else {
            print("[SMCService] Failed to open SMC connection: \(result)")
        }
    }

    // MARK: - Raw SMC Call

    private func smcCall(input: inout [UInt8], output: inout [UInt8]) -> kern_return_t {
        let inputSize = input.count
        var outputSize = output.count
        return input.withUnsafeMutableBytes { inputPtr in
            output.withUnsafeMutableBytes { outputPtr in
                guard let inputAddr = inputPtr.baseAddress, let outputAddr = outputPtr.baseAddress else {
                    return KERN_INVALID_ADDRESS
                }
                return IOConnectCallStructMethod(
                    conn,
                    KERNEL_INDEX_SMC,
                    inputAddr, inputSize,
                    outputAddr, &outputSize
                )
            }
        }
    }

    private func readSMCBytes(key: String) -> [UInt8]? {
        guard isConnected, key.count == 4 else { return nil }
        let keyCode = fourCC(key)

        var input = [UInt8](repeating: 0, count: 56)
        var output = [UInt8](repeating: 0, count: 56)

        // key at offset 0, big-endian
        input[0] = UInt8((keyCode >> 24) & 0xFF)
        input[1] = UInt8((keyCode >> 16) & 0xFF)
        input[2] = UInt8((keyCode >> 8) & 0xFF)
        input[3] = UInt8(keyCode & 0xFF)

        // Try READ_BYTES commands
        let commands: [UInt8] = [5, 6, 10]
        for cmd in commands {
            input[16] = cmd
            let kr = smcCall(input: &input, output: &output)
            if kr == KERN_SUCCESS && output[14] == 0 {
                return Array(output[24..<56])
            }
        }
        return nil
    }
    
    /// Enumerates all SMC keys and returns temperature keys (type sp78/sp79/sp7a/sp5a/si8c)
    /// that are not already in the hardcoded list.
    private func enumerateSMCTemperatureKeys() -> [(key: String, type: String)] {
        guard isConnected else { return [] }
        guard let keyCountBytes = readSMCBytes(key: "#KEY"), keyCountBytes.count >= 4 else { return [] }
        let count = Int(UInt32(keyCountBytes[0]) << 24 | UInt32(keyCountBytes[1]) << 16 |
                        UInt32(keyCountBytes[2]) << 8 | UInt32(keyCountBytes[3]))
        guard count > 0 && count < 10000 else { return [] }
        
        var results: [(key: String, type: String)] = []
        let validTypes = Set(["sp78", "sp79", "sp7a", "sp5a", "si8c"])
        
        for i in 0..<count {
            var input = [UInt8](repeating: 0, count: 56)
            var output = [UInt8](repeating: 0, count: 56)
            input[0] = UInt8((i >> 24) & 0xFF)
            input[1] = UInt8((i >> 16) & 0xFF)
            input[2] = UInt8((i >> 8) & 0xFF)
            input[3] = UInt8(i & 0xFF)
            input[16] = 8 // READ_INDEX
            let kr = smcCall(input: &input, output: &output)
            guard kr == KERN_SUCCESS && output[14] == 0 else { continue }
            let key4cc = String(bytes: output[0..<4].map { $0 }, encoding: .ascii) ?? ""
            let type = String(bytes: output[4..<8].map { $0 }, encoding: .ascii) ?? ""
            let typeLower = type.lowercased()
            guard key4cc.hasPrefix("T"), validTypes.contains(typeLower) else { continue }
            results.append((key: key4cc, type: typeLower))
        }
        return results
    }

    private func writeSMCBytes(key: String, bytes: [UInt8]) -> Bool {
        guard isConnected, key.count == 4 else { return false }
        let keyCode = fourCC(key)

        var input = [UInt8](repeating: 0, count: 56)
        var output = [UInt8](repeating: 0, count: 56)

        input[0] = UInt8((keyCode >> 24) & 0xFF)
        input[1] = UInt8((keyCode >> 16) & 0xFF)
        input[2] = UInt8((keyCode >> 8) & 0xFF)
        input[3] = UInt8(keyCode & 0xFF)

        for (i, byte) in bytes.prefix(32).enumerated() {
            input[24 + i] = byte
        }

        let commands: [UInt8] = [6, 7, 11]
        for cmd in commands {
            input[16] = cmd
            let kr = smcCall(input: &input, output: &output)
            if kr == KERN_SUCCESS && output[14] == 0 {
                return true
            }
        }
        return false
    }

    private func fourCC(_ string: String) -> UInt32 {
        var result: UInt32 = 0
        let chars = Array(string.utf8)
        for i in 0..<min(4, chars.count) {
            result = (result << 8) | UInt32(chars[i])
        }
        return result
    }

    // MARK: - Decoding

    private func decodeSP78(bytes: [UInt8]) -> Double {
        guard bytes.count >= 2 else { return 0 }
        let intPart = Int8(bitPattern: bytes[0])
        let fracPart = Double(bytes[1]) / 256.0
        return Double(intPart) + fracPart
    }

    private func decodeFPE2(bytes: [UInt8]) -> Double {
        guard bytes.count >= 2 else { return 0 }
        return Double(UInt16(bytes[0]) * 256 + UInt16(bytes[1])) / 4.0
    }

    private func encodeFPE2(value: Double) -> [UInt8] {
        let raw = UInt32(max(0, value) * 4.0)
        return [UInt8((raw >> 8) & 0xFF), UInt8(raw & 0xFF)]
    }

    // MARK: - Public API

    // MARK: - Public API

    private func temperaturesFromHelper(_ dicts: [[String: Any]]) -> [TemperatureSensor] {
        dicts.compactMap { dict in
            guard let name = dict["name"] as? String,
                  let key = dict["key"] as? String else { return nil }
            let value = dict["value"] as? Double ?? 0
            let max = dict["maxValue"] as? Double ?? 100
            return TemperatureSensor(name: name, key: key, value: value, maxValue: max)
        }
    }

    private func fansFromHelper(_ dicts: [[String: Any]]) -> [FanInfo] {
        dicts.compactMap { dict in
            guard let id = dict["id"] as? Int else { return nil }
            var info = FanInfo(id: id, name: (dict["name"] as? String) ?? fanName(for: id))
            if let v = dict["actualRPM"] as? Double { info.actualRPM = v }
            if let v = dict["minimumRPM"] as? Double { info.minimumRPM = v }
            if let v = dict["maximumRPM"] as? Double { info.maximumRPM = v }
            if let v = dict["targetRPM"] as? Double { info.targetRPM = v }
            return info
        }
    }

    /// Reads both fans and temperatures in a single shot, with a 250 ms TTL cache
    /// so multiple UI surfaces can share the same snapshot without re-hitting SMC.
    func readAll() -> (fans: [FanInfo], sensors: [TemperatureSensor]) {
        readAllLock.lock()
        defer { readAllLock.unlock() }

        let now = Date()
        if let cached = lastReadAll,
           let cachedTime = lastReadAllTime,
           now.timeIntervalSince(cachedTime) < 0.25 {
            return cached
        }

        var sensors: [TemperatureSensor] = []
        var fans: [FanInfo] = []
        var usedHelper = false

        // 1. Privileged helper: one socket round-trip returns both fans and temps.
        if isHelperAvailable {
            if let all = SMCHelperClient.shared.readAll() {
                fans = fansFromHelper(all.fans)
                sensors = temperaturesFromHelper(all.temps)
                usedHelper = !fans.isEmpty || !sensors.isEmpty
            }
            if !usedHelper {
                // Helper socket exists but returned no usable data — likely an old helper
                // running with a stale socket or permission mismatch.
                fanAccessReason = "Helper socket found but returned no data. Restart the helper: sudo killall ClassGodHelper; sudo /Applications/ClassGod.app/Contents/MacOS/ClassGodHelper"
            }
        }

        // 2. Direct SMC fallback (Intel Macs / unlocked Apple Silicon)
        if !usedHelper, isConnected {
            var seenKeys = Set<String>()
            for (name, key, max) in sensorKeys {
                if let bytes = readSMCBytes(key: key), bytes.count >= 2 {
                    let value = decodeSP78(bytes: bytes)
                    if value > -50 && value < 150 {
                        sensors.append(TemperatureSensor(name: name, key: key, value: value, maxValue: max))
                        seenKeys.insert(key)
                    }
                }
            }
            
            // Dynamic enumeration: scan all SMC keys for additional temperature sensors
            let dynamicTemps = enumerateSMCTemperatureKeys()
            for (key, _) in dynamicTemps where !seenKeys.contains(key) {
                if let bytes = readSMCBytes(key: key), bytes.count >= 2 {
                    let value = decodeSP78(bytes: bytes)
                    if value > -50 && value < 150 {
                        sensors.append(TemperatureSensor(name: key, key: key, value: value, maxValue: 100))
                    }
                }
            }

            if let numBytes = readSMCBytes(key: "FNum"), numBytes.count >= 1, numBytes[0] > 0 {
                let numFans = min(Int(numBytes[0]), 16)
                for i in 0..<numFans {
                    let actualKey = "F\(i)Ac"
                    let minKey = "F\(i)Mn"
                    let maxKey = "F\(i)Mx"
                    let targetKey = "F\(i)Tg"

                    var info = FanInfo(id: i, name: fanName(for: i))

                    if let bytes = readSMCBytes(key: actualKey) {
                        info.actualRPM = decodeFPE2(bytes: bytes)
                    }
                    if let bytes = readSMCBytes(key: minKey) {
                        info.minimumRPM = decodeFPE2(bytes: bytes)
                    }
                    if let bytes = readSMCBytes(key: maxKey) {
                        info.maximumRPM = decodeFPE2(bytes: bytes)
                    }
                    if let bytes = readSMCBytes(key: targetKey) {
                        info.targetRPM = decodeFPE2(bytes: bytes)
                    }

                    fans.append(info)
                }
            }
        }

        // IORegistry fan fallback when neither helper nor direct SMC produced fans
        if fans.isEmpty {
            if !hasScannedIORegistryFans {
                cachedIORegistryFans = readIORegistryFans()
                hasScannedIORegistryFans = true
            }
            fans = cachedIORegistryFans
            if !fans.isEmpty {
                isUsingIORegistryFallback = true
            }
        }

        isUsingIORegistryFallback = false

        // 3. IORegistry temperature fallback (scan cached after first call)
        if !hasScannedIORegistry {
            cachedIORegistryTemps = readIORegistryTemperatures()
            hasScannedIORegistry = true
        }
        let currentThermalBase = thermalStateBaseTemp()
        let refreshedIORegistry = cachedIORegistryTemps.map { sensor -> TemperatureSensor in
            guard sensor.isEstimated else { return sensor }
            var updated = sensor
            updated.value = currentThermalBase
            return updated
        }
        sensors.append(contentsOf: refreshedIORegistry)
        if !cachedIORegistryTemps.isEmpty {
            isUsingIORegistryFallback = true
        }

        // 4. ProcessInfo thermal state (official API, always available)
        let thermalStateTemps = readThermalStateTemperatures()
        if !thermalStateTemps.isEmpty {
            sensors.append(contentsOf: thermalStateTemps)
            isUsingIORegistryFallback = true
        }

        // 5. Deduplicate by key across helper/direct/IORegistry/thermal sources
        var seenKeys = Set<String>()
        sensors = sensors.filter { sensor in
            let key = sensor.key
            if seenKeys.contains(key) { return false }
            seenKeys.insert(key)
            return true
        }

        // 6. Final fallback: SystemMonitor estimates based on CPU load
        if sensors.isEmpty {
            let thermal = SystemMonitor.shared.thermal
            if thermal.cpuTemp > 0 {
                sensors.append(TemperatureSensor(name: "CPU Estimated", key: "CPU", value: thermal.cpuTemp, maxValue: 100, isEstimated: true))
            }
            if thermal.gpuTemp > 0 {
                sensors.append(TemperatureSensor(name: "GPU Estimated", key: "GPU", value: thermal.gpuTemp, maxValue: 100, isEstimated: true))
            }
        }

        if !fans.isEmpty {
            fanAccessReason = nil
        } else {
            updateFanAccessReason()
        }

        let result = (fans: fans, sensors: sensors.sorted { $0.name < $1.name })
        lastReadAll = result
        lastReadAllTime = now
        return result
    }

    func readTemperatures() -> [TemperatureSensor] {
        return readAll().sensors
    }

    func readFans() -> [FanInfo] {
        return readAll().fans
    }
    
    private func readIORegistryFans() -> [FanInfo] {
        var fans: [FanInfo] = []
        
        // Try AppleSMC / AppleSMCKeysEndpoint properties for fan data
        for serviceName in ["AppleSMC", "AppleSMCKeysEndpoint"] {
            if let matching = IOServiceMatching(serviceName) {
                var iter = io_iterator_t()
                if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS {
                    defer { IOObjectRelease(iter) }
                    while true {
                        let service = IOIteratorNext(iter)
                        guard service != 0 else { break }
                        defer { IOObjectRelease(service) }

                        var propsRef: Unmanaged<CFMutableDictionary>?
                        let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                        if kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] {
                            // Look for fan count keys
                            if let fanCount = props["FNum"] as? NSNumber ?? props["FanNumber"] as? NSNumber {
                                let count = min(Int(fanCount.intValue), 16)
                                for i in 0..<count {
                                    var info = FanInfo(id: i, name: fanName(for: i))
                                    // Try to read RPM from IORegistry properties
                                    if let rpm = props["F\(i)Ac"] as? NSNumber {
                                        info.actualRPM = rpm.doubleValue
                                    }
                                    if let minRpm = props["F\(i)Mn"] as? NSNumber {
                                        info.minimumRPM = minRpm.doubleValue
                                    }
                                    if let maxRpm = props["F\(i)Mx"] as? NSNumber {
                                        info.maximumRPM = maxRpm.doubleValue
                                    }
                                    if let targetRpm = props["F\(i)Tg"] as? NSNumber {
                                        info.targetRPM = targetRpm.doubleValue
                                    }
                                    fans.append(info)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Try IOHIDEventService for fan-related HID sensors
        if fans.isEmpty {
            if let matching = IOServiceMatching("IOHIDEventService") {
                var iter = io_iterator_t()
                if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS {
                    defer { IOObjectRelease(iter) }
                    var fanIndex = 0
                    while true {
                        let service = IOIteratorNext(iter)
                        guard service != 0 else { break }
                        defer { IOObjectRelease(service) }

                        var propsRef: Unmanaged<CFMutableDictionary>?
                        let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                        if kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] {
                            let product = props["Product"] as? String ?? ""
                            if product.lowercased().contains("fan") || product.lowercased().contains("tach") {
                                var info = FanInfo(id: fanIndex, name: product)
                                if let rpm = props["RPM"] as? NSNumber ?? props["Value"] as? NSNumber {
                                    info.actualRPM = rpm.doubleValue
                                }
                                fans.append(info)
                                fanIndex += 1
                            }
                        }
                    }
                }
            }
        }
        
        // Try AppleSPU for thermal/fan related reports
        if fans.isEmpty {
            if let matching = IOServiceMatching("AppleSPU") {
                var iter = io_iterator_t()
                if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS {
                    defer { IOObjectRelease(iter) }
                    while true {
                        let service = IOIteratorNext(iter)
                        guard service != 0 else { break }
                        defer { IOObjectRelease(service) }

                        var propsRef: Unmanaged<CFMutableDictionary>?
                        let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                        if kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] {
                            // Some SPU reports may contain fan-related channels
                            if let reports = props["IOReportLegend"] as? [[String: Any]] {
                                for report in reports {
                                    if let group = report["IOReportGroupName"] as? String,
                                       group.lowercased().contains("fan") {
                                        // We found fan-related report group but cannot extract live values here
                                        // Mark that we detected fan hardware at least
                                        if fans.isEmpty {
                                            // Create a placeholder indicating hardware detected but not readable
                                            // This is better than showing nothing
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return fans
    }

    private func fanName(for index: Int) -> String {
        switch index {
        case 0: return "Left Side"
        case 1: return "Right Side"
        default: return "Fan \(index + 1)"
        }
    }

    func setFanMode(_ mode: FanControlMode, fanIndex: Int = 0) -> Bool {
        let modeString = mode.rawValue
        if SMCHelperClient.shared.isHelperAvailable {
            return SMCHelperClient.shared.setFanMode(modeString, fanIndex: fanIndex)
        }
        switch mode {
        case .system:
            return writeSMCBytes(key: "F\(fanIndex)Tg", bytes: [0, 0])
        case .max:
            guard let maxBytes = readSMCBytes(key: "F\(fanIndex)Mx"), maxBytes.count >= 2 else { return false }
            return writeSMCBytes(key: "F\(fanIndex)Tg", bytes: Array(maxBytes.prefix(2)))
        case .autoMax, .manual, .custom:
            // autoMax/manual/custom are handled by the view model timer / UI controls.
            return true
        }
    }

    func setFanRPM(_ rpm: Double, fanIndex: Int = 0) -> Bool {
        if SMCHelperClient.shared.isHelperAvailable {
            return SMCHelperClient.shared.setFanRPM(rpm, fanIndex: fanIndex)
        }
        let bytes = encodeFPE2(value: rpm)
        return writeSMCBytes(key: "F\(fanIndex)Tg", bytes: bytes)
    }

    // MARK: - Thermal State Temperatures
    
    private func readThermalStateTemperatures() -> [TemperatureSensor] {
        var results: [TemperatureSensor] = []
        let state = ProcessInfo.processInfo.thermalState
        
        // Map thermal state to approximate temperatures based on Apple's documentation
        let baseTemp: Double
        let stateName: String
        switch state {
        case .nominal:
            baseTemp = 35.0
            stateName = "Nominal"
        case .fair:
            baseTemp = 50.0
            stateName = "Fair"
        case .serious:
            baseTemp = 70.0
            stateName = "Serious"
        case .critical:
            baseTemp = 90.0
            stateName = "Critical"
        @unknown default:
            baseTemp = 40.0
            stateName = "Unknown"
        }
        
        // Add CPU thermal state sensor — mark as estimated so Auto Max rules ignore it.
        results.append(TemperatureSensor(
            name: "CPU Thermal State (\(stateName))",
            key: "THCPU",
            value: baseTemp,
            maxValue: 100,
            isEstimated: true
        ))
        
        // Add GPU thermal state sensor (typically slightly higher)
        results.append(TemperatureSensor(
            name: "GPU Thermal State (\(stateName))",
            key: "THGPU",
            value: baseTemp + 3.0,
            maxValue: 100,
            isEstimated: true
        ))
        
        return results
    }

    // MARK: - IORegistry Fallback

    private func readIORegistryTemperatures() -> [TemperatureSensor] {
        var results: [TemperatureSensor] = []

        // 1. Try AppleARMIODevice for Apple Silicon specific sensors
        if let matching = IOServiceMatching("AppleARMIODevice") {
            var iter = io_iterator_t()
            if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS {
                defer { IOObjectRelease(iter) }
                while true {
                    let service = IOIteratorNext(iter)
                    guard service != 0 else { break }
                    defer { IOObjectRelease(service) }

                    var propsRef: Unmanaged<CFMutableDictionary>?
                    let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                    if kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] {
                        // Scan known temperature key prefixes
                        let tempPrefixes = ["T", "PMU", "ANE", "ISP"]
                        for (key, value) in props where tempPrefixes.contains(where: { key.hasPrefix($0) }) {
                            if let num = value as? NSNumber {
                                let temp = num.doubleValue
                                if temp > 10 && temp < 150 {
                                    results.append(TemperatureSensor(name: key, key: key, value: temp, maxValue: 100))
                                }
                            } else if let data = value as? Data, data.count >= 2 {
                                let bytes = [UInt8](data)
                                let temp = decodeSP78(bytes: bytes)
                                if temp > 10 && temp < 150 {
                                    results.append(TemperatureSensor(name: key, key: key, value: temp, maxValue: 100))
                                }
                            }
                        }
                        // Some devices expose temperature via location strings like "Txxx"
                        if let location = props["location"] as? String, location.hasPrefix("T"),
                           let num = props["value"] as? NSNumber ?? props["temperature"] as? NSNumber {
                            let temp = num.doubleValue
                            if temp > 10 && temp < 150 {
                                results.append(TemperatureSensor(name: location, key: location, value: temp, maxValue: 100))
                            }
                        }
                    }
                }
            }
        }

        // 2. Try AppleSMC / AppleSMCKeysEndpoint properties in IORegistry
        for serviceName in ["AppleSMC", "AppleSMCKeysEndpoint"] {
            if let matching = IOServiceMatching(serviceName) {
                var iter = io_iterator_t()
                if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS {
                    defer { IOObjectRelease(iter) }
                    while true {
                        let service = IOIteratorNext(iter)
                        guard service != 0 else { break }
                        defer { IOObjectRelease(service) }

                        var propsRef: Unmanaged<CFMutableDictionary>?
                        let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                        if kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] {
                            for (key, value) in props where key.hasPrefix("T") {
                                if let data = value as? Data, data.count >= 2 {
                                    let bytes = [UInt8](data)
                                    let temp = decodeSP78(bytes: bytes)
                                    if temp > 10 && temp < 150 {
                                        results.append(TemperatureSensor(name: key, key: key, value: temp, maxValue: 100))
                                    }
                                } else if let num = value as? NSNumber {
                                    let temp = num.doubleValue
                                    if temp > 10 && temp < 150 {
                                        results.append(TemperatureSensor(name: key, key: key, value: temp, maxValue: 100))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3. Try AppleSmartBattery for battery temperature (real hardware data)
        if let matching = IOServiceMatching("AppleSmartBattery") {
            var iter = io_iterator_t()
            if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS {
                defer { IOObjectRelease(iter) }
                while true {
                    let service = IOIteratorNext(iter)
                    guard service != 0 else { break }
                    defer { IOObjectRelease(service) }
                    
                    var propsRef: Unmanaged<CFMutableDictionary>?
                    let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                    if kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] {
                        if let tempValue = props["Temperature"] as? NSNumber {
                            let temp = tempValue.doubleValue / 100.0
                            if temp > 0 && temp < 150 {
                                results.append(TemperatureSensor(name: "Battery", key: "BAT0", value: temp, maxValue: 60))
                            }
                        }
                        if let virtualTemp = props["VirtualTemperature"] as? NSNumber {
                            let temp = virtualTemp.doubleValue / 100.0
                            if temp > 0 && temp < 150 {
                                results.append(TemperatureSensor(name: "Battery Virtual", key: "BATV", value: temp, maxValue: 60))
                            }
                        }
                    }
                }
            }
        }

        // 4. Try IOPMPowerSource for additional power-related temperatures
        if let matching = IOServiceMatching("IOPMPowerSource") {
            var iter = io_iterator_t()
            if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS {
                defer { IOObjectRelease(iter) }
                while true {
                    let service = IOIteratorNext(iter)
                    guard service != 0 else { break }
                    defer { IOObjectRelease(service) }
                    
                    var propsRef: Unmanaged<CFMutableDictionary>?
                    let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                    if kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] {
                        if let tempValue = props["Temperature"] as? NSNumber {
                            let temp = tempValue.doubleValue > 1000 ? tempValue.doubleValue / 100.0 : tempValue.doubleValue
                            if temp > 0 && temp < 150 {
                                let name = props["IORegistryEntryName"] as? String ?? "PowerSource"
                                results.append(TemperatureSensor(name: "\(name) Temperature", key: "PS_\(name)", value: temp, maxValue: 100))
                            }
                        }
                    }
                }
            }
        }

        // 5. Discover AppleARMPMUTempSensor devices (Apple Silicon).
        // These sensors exist in IORegistry but their live values are not exposed to user-space
        // on modern macOS without a privileged system extension. We list them as discovered
        // hardware with an estimated placeholder so the user can see what is present.
        results.append(contentsOf: readARMPMUTemperatures())

        // 6. Discover AppleEmbeddedNVMeTemperatureSensor if available (SSD temps).
        results.append(contentsOf: readNVMETemperatures())

        return results
    }

    private func readARMPMUTemperatures() -> [TemperatureSensor] {
        var results: [TemperatureSensor] = []
        guard let matching = IOServiceMatching("AppleARMPMUTempSensor") else { return results }

        var iter = io_iterator_t()
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS else { return results }
        defer { IOObjectRelease(iter) }

        var seen = Set<String>()
        let estimatedBase = thermalStateBaseTemp()

        while true {
            let service = IOIteratorNext(iter)
            guard service != 0 else { break }
            defer { IOObjectRelease(service) }

            var propsRef: Unmanaged<CFMutableDictionary>?
            let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
            guard kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] else { continue }

            let product = props["Product"] as? String ?? "PMU Sensor"
            let locationID = props["LocationID"] as? NSNumber ?? 0
            let key = "PMU_\(product)_\(locationID.uint32Value)"

            guard !seen.contains(key) else { continue }
            seen.insert(key)

            // Try to read a real value from properties; usually unavailable.
            let realValue: Double? = {
                if let num = props["Temperature"] as? NSNumber { return num.doubleValue }
                if let num = props["Value"] as? NSNumber { return num.doubleValue }
                return nil
            }()

            if let value = realValue, value > -50 && value < 150 {
                results.append(TemperatureSensor(name: "\(product) (loc \(locationID.uint32Value))", key: key, value: value, maxValue: 100, isEstimated: false))
            } else {
                // Placeholder so the sensor appears in the discovered list.
                results.append(TemperatureSensor(name: "\(product) (loc \(locationID.uint32Value))", key: key, value: estimatedBase, maxValue: 100, isEstimated: true))
            }
        }

        return results
    }

    private func readNVMETemperatures() -> [TemperatureSensor] {
        var results: [TemperatureSensor] = []

        for serviceName in ["AppleEmbeddedNVMeTemperatureSensor", "AppleNVMeTemperatureSensor"] {
            guard let matching = IOServiceMatching(serviceName) else { continue }
            var iter = io_iterator_t()
            guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS else { continue }
            defer { IOObjectRelease(iter) }

            var count = 0
            while true {
                let service = IOIteratorNext(iter)
                guard service != 0 else { break }
                defer { IOObjectRelease(service) }

                var propsRef: Unmanaged<CFMutableDictionary>?
                let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                guard kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] else { continue }

                let product = props["Product"] as? String ?? "NVMe Sensor"
                let key = "NVMe_\(serviceName)_\(count)"
                count += 1

                if let num = props["Temperature"] as? NSNumber {
                    let temp = num.doubleValue > 1000 ? num.doubleValue / 100.0 : num.doubleValue
                    if temp > -50 && temp < 150 {
                        results.append(TemperatureSensor(name: product, key: key, value: temp, maxValue: 100, isEstimated: false))
                        continue
                    }
                }
                if let num = props["Value"] as? NSNumber {
                    let temp = num.doubleValue
                    if temp > -50 && temp < 150 {
                        results.append(TemperatureSensor(name: product, key: key, value: temp, maxValue: 100, isEstimated: false))
                        continue
                    }
                }
            }
        }

        return results
    }

    private func thermalStateBaseTemp() -> Double {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return 35.0
        case .fair: return 50.0
        case .serious: return 70.0
        case .critical: return 90.0
        @unknown default: return 40.0
        }
    }
}
