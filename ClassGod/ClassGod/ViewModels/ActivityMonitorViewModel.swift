//
//  ActivityMonitorViewModel.swift
//  ClassGod
//
//  View model for the hacker-style Activity Monitor panel.
//

import Foundation
import Combine

enum ActivityMonitorTab: String, CaseIterable, Identifiable {
    case cpu = "CPU"
    case memory = "Memory"
    case energy = "Energy"
    case disk = "Disk"
    case network = "Network"
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .cpu: return String(localized: "activity.tab.cpu")
        case .memory: return String(localized: "activity.tab.memory")
        case .energy: return String(localized: "activity.tab.energy")
        case .disk: return String(localized: "activity.tab.disk")
        case .network: return String(localized: "activity.tab.network")
        }
    }

    var iconName: String {
        switch self {
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .energy: return "bolt.fill"
        case .disk: return "internaldrive"
        case .network: return "network"
        }
    }
}

enum ActivitySortKey {
    case name, cpu, memory, threads, pid, user, energy, diskRead, diskWrite, netRecv, netSent
}

enum ActivityUserSort {
    static func sorted(
        _ processes: [ProcessMonitorInfo],
        ascending: Bool,
        userName: (UInt32) -> String
    ) -> [ProcessMonitorInfo] {
        var names: [UInt32: String] = [:]
        func name(_ uid: UInt32) -> String {
            if let cached = names[uid] { return cached }
            let resolved = userName(uid)
            names[uid] = resolved
            return resolved
        }
        return processes.sorted { ascending ? name($0.uid) < name($1.uid) : name($0.uid) > name($1.uid) }
    }
}

enum ActivityPermissionPromptPolicy {
    static func shouldShow(isMonitoring: Bool, processCount: Int) -> Bool {
        isMonitoring && processCount == 0
    }
}

nonisolated enum ActivitySearchQuery {
    static func normalized(_ value: String) -> String? {
        let query = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? nil : query
    }
}

@MainActor
final class ActivityMonitorViewModel: ObservableObject {
    @Published var selectedTab: ActivityMonitorTab = .cpu
    @Published var searchText: String = ""
    @Published var sortKey: ActivitySortKey = .cpu
    @Published var sortAscending: Bool = false
    @Published var selectedProcess: ProcessMonitorInfo?
    @Published var showPermissionPrompt: Bool = false

    private let monitor = SystemMonitor.shared
    private var isMonitoring = false
    private var permissionPromptWorkItem: DispatchWorkItem?

    deinit {
        permissionPromptWorkItem?.cancel()
    }
    
    var processes: [ProcessMonitorInfo] {
        var list = monitor.processes
        
        if let query = ActivitySearchQuery.normalized(searchText) {
            let lower = query.lowercased()
            list = list.filter {
                $0.name.lowercased().contains(lower) ||
                String($0.pid).contains(lower)
            }
        }
        
        switch sortKey {
        case .name:
            list.sort { sortAscending ? $0.name < $1.name : $0.name > $1.name }
        case .cpu:
            list.sort { sortAscending ? $0.cpuPercent < $1.cpuPercent : $0.cpuPercent > $1.cpuPercent }
        case .memory:
            list.sort { sortAscending ? $0.memoryMB < $1.memoryMB : $0.memoryMB > $1.memoryMB }
        case .threads:
            list.sort { sortAscending ? $0.threads < $1.threads : $0.threads > $1.threads }
        case .pid:
            list.sort { sortAscending ? $0.pid < $1.pid : $0.pid > $1.pid }
        case .user:
            list = ActivityUserSort.sorted(list, ascending: sortAscending, userName: userName)
        case .energy:
            list.sort { sortAscending ? $0.energyNanojoulesPerSecond < $1.energyNanojoulesPerSecond : $0.energyNanojoulesPerSecond > $1.energyNanojoulesPerSecond }
        case .diskRead:
            list.sort { sortAscending ? $0.diskReadBytesPerSecond < $1.diskReadBytesPerSecond : $0.diskReadBytesPerSecond > $1.diskReadBytesPerSecond }
        case .diskWrite:
            list.sort { sortAscending ? $0.diskWriteBytesPerSecond < $1.diskWriteBytesPerSecond : $0.diskWriteBytesPerSecond > $1.diskWriteBytesPerSecond }
        case .netRecv:
            list.sort { sortAscending ? $0.networkRecvBytesPerSecond < $1.networkRecvBytesPerSecond : $0.networkRecvBytesPerSecond > $1.networkRecvBytesPerSecond }
        case .netSent:
            list.sort { sortAscending ? $0.networkSentBytesPerSecond < $1.networkSentBytesPerSecond : $0.networkSentBytesPerSecond > $1.networkSentBytesPerSecond }
        }
        
        return list
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        monitor.start(client: .activityMonitor, interval: 1.0)
        schedulePermissionPromptIfNeeded()
    }
    
    func stopMonitoring() {
        permissionPromptWorkItem?.cancel()
        permissionPromptWorkItem = nil
        showPermissionPrompt = false
        guard isMonitoring else { return }
        isMonitoring = false
        monitor.stop(client: .activityMonitor)
    }

    private func schedulePermissionPromptIfNeeded() {
        permissionPromptWorkItem?.cancel()
        showPermissionPrompt = false
        guard monitor.processes.isEmpty else { return }

        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.permissionPromptWorkItem = nil
            self.showPermissionPrompt = ActivityPermissionPromptPolicy.shouldShow(
                isMonitoring: self.isMonitoring,
                processCount: self.monitor.processes.count
            )
        }
        permissionPromptWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: item)
    }
    
    func toggleSort(_ key: ActivitySortKey) {
        if sortKey == key {
            sortAscending.toggle()
        } else {
            sortKey = key
            sortAscending = false
        }
    }
    
    func formatBytes(_ bytes: UInt64) -> String {
        let kb = Double(bytes) / 1024.0
        let mb = kb / 1024.0
        let gb = mb / 1024.0
        if gb >= 1.0 { return String(format: "%.1f GB", gb) }
        if mb >= 1.0 { return String(format: "%.1f MB", mb) }
        if kb >= 1.0 { return String(format: "%.0f KB", kb) }
        return "\(bytes) B"
    }
    
    func formatSpeed(_ bytesPerInterval: UInt64, interval: TimeInterval = 1.0) -> String {
        let bps = Double(bytesPerInterval) / max(interval, 0.1)
        let kbps = bps / 1024.0
        let mbps = kbps / 1024.0
        if mbps >= 1.0 { return String(format: "%.1f MB/s", mbps) }
        if kbps >= 1.0 { return String(format: "%.0f KB/s", kbps) }
        return String(format: "%.0f B/s", bps)
    }
    
    func formatEnergyRate(_ nanojoulesPerSecond: UInt64) -> String {
        let watts = Double(nanojoulesPerSecond) / 1_000_000_000.0
        if watts >= 1000 {
            return String(format: "%.1f kW", watts / 1000)
        }
        return String(format: "%.1f W", watts)
    }
    
    func userName(_ uid: UInt32) -> String {
        let pw = getpwuid(uid)
        if let pw, let name = pw.pointee.pw_name {
            return String(cString: name)
        }
        return String(uid)
    }
    
    // MARK: - Process Control
    
    func canTerminate(_ proc: ProcessMonitorInfo) -> Bool {
        // Don't allow killing root-owned processes, our own process, or kernel_task (pid 0)
        let ownPID = ProcessInfo.processInfo.processIdentifier
        return proc.pid > 0 && proc.pid != ownPID && proc.uid != 0
    }
    
    @discardableResult
    func terminateProcess(_ proc: ProcessMonitorInfo, force: Bool = false) -> Bool {
        guard canTerminate(proc) else { return false }
        let signal = force ? SIGKILL : SIGTERM
        return kill(proc.pid, signal) == 0
    }
}
