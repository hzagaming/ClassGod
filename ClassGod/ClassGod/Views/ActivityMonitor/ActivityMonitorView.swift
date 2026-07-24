//
//  ActivityMonitorView.swift
//  ClassGod
//
//  Hacker-style Activity Monitor with CPU/Memory/Energy/Disk/Network tabs.
//

import SwiftUI

struct ActivityMonitorView: View {
    @StateObject private var viewModel = ActivityMonitorViewModel()
    @ObservedObject private var monitor = SystemMonitor.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var onClose: () -> Void
    
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    
    var body: some View {
        ZStack {
            Color(white: 0.02).ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBar
                if viewModel.showPermissionPrompt {
                    permissionBanner
                }
                tabBar
                processTable
                bottomSummary
            }
        }
        .onAppear {
            viewModel.startMonitoring()
            checkPermissions()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
        .onReceive(NotificationCenter.default.publisher(for: .activityMonitorWindowDidShow)) { _ in
            viewModel.startMonitoring()
            checkPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: .activityMonitorWindowWillHide)) { _ in
            viewModel.stopMonitoring()
        }
    }
    
    // MARK: - Header
    
    private var headerBar: some View {
        HStack(spacing: 12 * zoomScale) {
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                onClose()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10 * zoomScale, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                    .background(Color(white: 0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Image(systemName: "waveform.path.ecg.rectangle")
                .font(.system(size: 14 * zoomScale))
                .foregroundStyle(.cyan)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("activity.title")
                    .font(.system(size: 14 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("activity.subtitle")
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            
            Spacer()
            
            HStack(spacing: 6 * zoomScale) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 9 * zoomScale))
                    .foregroundStyle(.white.opacity(0.4))
                TextField(String(localized: "activity.search"), text: $viewModel.searchText)
                    .font(.system(size: 10 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white)
                    .textFieldStyle(.plain)
                    .frame(width: 140 * zoomScale)
            }
            .padding(.horizontal, 8 * zoomScale)
            .padding(.vertical, 4 * zoomScale)
            .background(Color(white: 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
            .overlay(
                RoundedRectangle(cornerRadius: 6 * zoomScale)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1 * zoomScale)
            )
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 10 * zoomScale)
        .background(Color(white: 0.04))
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
                .offset(y: 0.5)
        )
    }
    
    private var permissionBanner: some View {
        HStack(spacing: 8 * zoomScale) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10 * zoomScale))
                .foregroundStyle(.orange)
            Text(String(localized: "activity.permission_banner"))
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(2)
            Spacer()
            Button(action: {
                viewModel.showPermissionPrompt = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9 * zoomScale, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 8 * zoomScale)
        .background(Color.orange.opacity(0.08))
        .overlay(
            Rectangle()
                .stroke(Color.orange.opacity(0.25), lineWidth: 1 * zoomScale)
        )
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        HStack(spacing: 4 * zoomScale) {
            ForEach(ActivityMonitorTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 8 * zoomScale)
        .background(Color(white: 0.04))
    }
    
    private func tabButton(_ tab: ActivityMonitorTab) -> some View {
        let selected = viewModel.selectedTab == tab
        return Button(action: {
            SoundEffectManager.shared.playButtonClick()
            viewModel.selectedTab = tab
            updateDefaultSort(for: tab)
        }) {
            HStack(spacing: 4 * zoomScale) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 10 * zoomScale))
                Text(tab.displayName)
                    .font(.system(size: 10 * zoomScale, weight: selected ? .bold : .medium, design: .monospaced))
            }
            .foregroundStyle(selected ? .black : .white.opacity(0.7))
            .padding(.horizontal, 12 * zoomScale)
            .padding(.vertical, 5 * zoomScale)
            .background(selected ? Color.cyan.opacity(0.85) : Color(white: 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
        }
        .buttonStyle(.plain)
    }
    
    private func updateDefaultSort(for tab: ActivityMonitorTab) {
        switch tab {
        case .cpu: viewModel.sortKey = .cpu
        case .memory: viewModel.sortKey = .memory
        case .energy: viewModel.sortKey = .energy
        case .disk: viewModel.sortKey = .diskRead
        case .network: viewModel.sortKey = .netRecv
        }
        viewModel.sortAscending = false
    }
    
    // MARK: - Process Table
    
    private var processTable: some View {
        VStack(spacing: 0) {
            tableHeader
            Divider().background(Color.white.opacity(0.06))
            
            ScrollView(showsIndicators: true) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.processes.enumerated()), id: \.element.id) { index, proc in
                        processRow(proc, index: index)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedProcess = proc
                            }
                    }
                }
            }
        }
        .background(Color(white: 0.02))
    }
    
    private var tableHeader: some View {
        HStack(spacing: 0) {
            sortableHeader("Process Name", key: .name, width: 180)
            sortableHeader("PID", key: .pid, width: 60)
            sortableHeader("User", key: .user, width: 80)
            sortableHeader("Threads", key: .threads, width: 60)
            
            switch viewModel.selectedTab {
            case .cpu:
                sortableHeader("CPU %", key: .cpu, width: 70)
                sortableHeader("Memory", key: .memory, width: 80)
            case .memory:
                sortableHeader("Memory", key: .memory, width: 80)
                sortableHeader("CPU %", key: .cpu, width: 70)
            case .energy:
                sortableHeader("Power", key: .energy, width: 90)
                sortableHeader("CPU %", key: .cpu, width: 70)
            case .disk:
                sortableHeader("Read/s", key: .diskRead, width: 80)
                sortableHeader("Write/s", key: .diskWrite, width: 80)
            case .network:
                sortableHeader("Recv/s", key: .netRecv, width: 80)
                sortableHeader("Sent/s", key: .netSent, width: 80)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 6 * zoomScale)
        .background(Color(white: 0.05))
        .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
        .foregroundStyle(.white.opacity(0.5))
    }
    
    private func sortableHeader(_ title: LocalizedStringKey, key: ActivitySortKey, width: CGFloat) -> some View {
        Button(action: { viewModel.toggleSort(key) }) {
            HStack(spacing: 2 * zoomScale) {
                Text(title)
                    .lineLimit(1)
                if viewModel.sortKey == key {
                    Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 7 * zoomScale))
                }
            }
            .frame(width: width * zoomScale, alignment: .leading)
        }
        .buttonStyle(.plain)
        .foregroundStyle(viewModel.sortKey == key ? .cyan.opacity(0.9) : .white.opacity(0.5))
    }
    
    private func processRow(_ proc: ProcessMonitorInfo, index: Int) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 6 * zoomScale) {
                processIcon(for: proc.name)
                Text(proc.name)
                    .lineLimit(1)
                    .frame(width: 160 * zoomScale, alignment: .leading)
            }
            
            Text("\(proc.pid)")
                .frame(width: 60 * zoomScale, alignment: .leading)
            
            Text(viewModel.userName(proc.uid))
                .frame(width: 80 * zoomScale, alignment: .leading)
            
            Text("\(proc.threads)")
                .frame(width: 60 * zoomScale, alignment: .leading)
            
            switch viewModel.selectedTab {
            case .cpu:
                Text(String(format: "%.1f%%", proc.cpuPercent))
                    .frame(width: 70 * zoomScale, alignment: .trailing)
                    .foregroundStyle(cpuColor(proc.cpuPercent))
                Text(viewModel.formatBytes(UInt64(proc.memoryMB * 1024 * 1024)))
                    .frame(width: 80 * zoomScale, alignment: .trailing)
            case .memory:
                Text(viewModel.formatBytes(UInt64(proc.memoryMB * 1024 * 1024)))
                    .frame(width: 80 * zoomScale, alignment: .trailing)
                Text(String(format: "%.1f%%", proc.cpuPercent))
                    .frame(width: 70 * zoomScale, alignment: .trailing)
                    .foregroundStyle(cpuColor(proc.cpuPercent))
            case .energy:
                Text(viewModel.formatEnergyRate(proc.energyNanojoulesPerSecond))
                    .frame(width: 90 * zoomScale, alignment: .trailing)
                    .foregroundStyle(.yellow)
                Text(String(format: "%.1f%%", proc.cpuPercent))
                    .frame(width: 70 * zoomScale, alignment: .trailing)
                    .foregroundStyle(cpuColor(proc.cpuPercent))
            case .disk:
                HStack(spacing: 4 * zoomScale) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 7 * zoomScale))
                        .foregroundStyle(.cyan)
                    Text(viewModel.formatSpeed(proc.diskReadBytesPerSecond))
                }
                .frame(width: 80 * zoomScale, alignment: .trailing)
                
                HStack(spacing: 4 * zoomScale) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 7 * zoomScale))
                        .foregroundStyle(.orange)
                    Text(viewModel.formatSpeed(proc.diskWriteBytesPerSecond))
                }
                .frame(width: 80 * zoomScale, alignment: .trailing)
            case .network:
                HStack(spacing: 4 * zoomScale) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 7 * zoomScale))
                        .foregroundStyle(.green)
                    Text(viewModel.formatSpeed(proc.networkRecvBytesPerSecond))
                    if proc.isEstimatedNetwork {
                        Text("*")
                            .font(.system(size: 7 * zoomScale))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .frame(width: 80 * zoomScale, alignment: .trailing)
                
                HStack(spacing: 4 * zoomScale) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 7 * zoomScale))
                        .foregroundStyle(.cyan)
                    Text(viewModel.formatSpeed(proc.networkSentBytesPerSecond))
                    if proc.isEstimatedNetwork {
                        Text("*")
                            .font(.system(size: 7 * zoomScale))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .frame(width: 80 * zoomScale, alignment: .trailing)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 5 * zoomScale)
        .background(index % 2 == 0 ? Color(white: 0.025) : Color(white: 0.045))
        .font(.system(size: 10 * zoomScale, design: .monospaced))
        .foregroundStyle(viewModel.selectedProcess?.id == proc.id ? .cyan : .white.opacity(0.85))
        .overlay(
            Rectangle()
                .fill(viewModel.selectedProcess?.id == proc.id ? Color.cyan.opacity(0.12) : Color.clear)
                .allowsHitTesting(false)
        )
        .contextMenu {
            if viewModel.canTerminate(proc) {
                Button(role: .destructive) {
                    terminate(proc, force: false)
                } label: {
                    Label(String(localized: "activity.quit"), systemImage: "xmark.circle")
                }
                Button(role: .destructive) {
                    terminate(proc, force: true)
                } label: {
                    Label(String(localized: "activity.force_quit"), systemImage: "xmark.octagon")
                }
            } else {
                Text(String(localized: "activity.system_process"))
                    .font(.system(size: 10 * zoomScale))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
    
    private func terminate(_ proc: ProcessMonitorInfo, force: Bool) {
        if viewModel.terminateProcess(proc, force: force) {
            SoundEffectManager.shared.playSwitchSuccess()
            HapticManager.shared.warning()
        } else {
            SoundEffectManager.shared.playSwitchFailure()
            HapticManager.shared.warning()
        }
    }

    private func processIcon(for name: String) -> some View {
        let icon = iconForProcessName(name)
        return Image(systemName: icon)
            .font(.system(size: 11 * zoomScale))
            .foregroundStyle(.cyan.opacity(0.7))
            .frame(width: 18 * zoomScale, height: 18 * zoomScale)
            .background(Color(white: 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4 * zoomScale))
    }
    
    private func iconForProcessName(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("safari") { return "safari" }
        if lower.contains("chrome") { return "globe" }
        if lower.contains("edge") { return "globe" }
        if lower.contains("firefox") { return "flame" }
        if lower.contains("mail") { return "envelope" }
        if lower.contains("music") || lower.contains("spotify") { return "music.note" }
        if lower.contains("code") || lower.contains("xcode") { return "hammer" }
        if lower.contains("terminal") || lower.contains("shell") { return "terminal" }
        if lower.contains("finder") { return "folder" }
        if lower.contains("calendar") { return "calendar" }
        if lower.contains("message") || lower.contains("wechat") || lower.contains("slack") { return "message" }
        return "cpu"
    }
    
    private func cpuColor(_ cpu: Double) -> Color {
        if cpu > 50 { return .red }
        if cpu > 20 { return .orange }
        if cpu > 5 { return .yellow }
        return .white.opacity(0.7)
    }
    
    // MARK: - Bottom Summary
    
    private var bottomSummary: some View {
        HStack(spacing: 0) {
            switch viewModel.selectedTab {
            case .cpu:
                cpuSummary
            case .memory:
                memorySummary
            case .energy:
                energySummary
            case .disk:
                diskSummary
            case .network:
                networkSummary
            }
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 8 * zoomScale)
        .background(Color(white: 0.04))
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
                .offset(y: -0.5)
        )
    }
    
    private var cpuSummary: some View {
        HStack(spacing: 16 * zoomScale) {
            summaryItem("User", value: String(format: "%.1f%%", monitor.cpu.user), color: .blue)
            summaryItem("System", value: String(format: "%.1f%%", monitor.cpu.system), color: .red)
            summaryItem("Idle", value: String(format: "%.1f%%", monitor.cpu.idle), color: .green)
            summaryItem("Total", value: String(format: "%.1f%%", monitor.cpu.total), color: .cyan)
            Spacer()
            Text(String(format: String(localized: "activity.process_count"), monitor.processes.count))
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
        }
    }
    
    private var memorySummary: some View {
        HStack(spacing: 16 * zoomScale) {
            summaryItem("Physical", value: viewModel.formatBytes(monitor.memory.total), color: .cyan)
            summaryItem("Used", value: viewModel.formatBytes(monitor.memory.used), color: .yellow)
            summaryItem("Free", value: viewModel.formatBytes(monitor.memory.free), color: .green)
            summaryItem("Wired", value: viewModel.formatBytes(monitor.memory.wired), color: .orange)
            summaryItem("Compressed", value: viewModel.formatBytes(monitor.memory.compressed), color: .purple)
            Spacer()
            memoryPressureBar
        }
    }
    
    private var energySummary: some View {
        HStack(spacing: 16 * zoomScale) {
            summaryItem("Battery", value: String(format: "%.0f%%", monitor.battery.level * 100), color: monitor.battery.isCharging ? .green : .cyan)
            summaryItem("State", value: monitor.battery.isCharging ? String(localized: "battery.charging") : String(localized: "battery.discharging"), color: monitor.battery.isCharging ? .green : .white.opacity(0.7))
            summaryItem("Cycles", value: "\(monitor.battery.cycleCount)", color: .yellow)
            Spacer()
            if monitor.battery.isPresent {
                Text(String(localized: "activity.energy_note"))
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            } else {
                Text(String(localized: "activity.no_battery"))
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
    }
    
    private var diskSummary: some View {
        HStack(spacing: 16 * zoomScale) {
            let totalRead = monitor.processes.reduce(0) { $0 + $1.diskReadBytesPerSecond }
            let totalWrite = monitor.processes.reduce(0) { $0 + $1.diskWriteBytesPerSecond }
            summaryItem("Total Read", value: viewModel.formatSpeed(totalRead), color: .cyan)
            summaryItem("Total Write", value: viewModel.formatSpeed(totalWrite), color: .orange)
            Spacer()
            if let disk = monitor.disks.first {
                summaryItem("Disk Free", value: viewModel.formatBytes(UInt64(max(0, disk.free))), color: .green)
                summaryItem("Disk Used", value: String(format: "%.0f%%", disk.usedPercent * 100), color: disk.usedPercent > 0.9 ? .red : .yellow)
            }
        }
    }
    
    private var networkSummary: some View {
        HStack(spacing: 16 * zoomScale) {
            summaryItem("Download", value: viewModel.formatSpeed(UInt64(monitor.network.deltaIn)), color: .green)
            summaryItem("Upload", value: viewModel.formatSpeed(UInt64(monitor.network.deltaOut)), color: .cyan)
            summaryItem("Total In", value: viewModel.formatBytes(monitor.network.bytesIn), color: .white.opacity(0.7))
            summaryItem("Total Out", value: viewModel.formatBytes(monitor.network.bytesOut), color: .white.opacity(0.7))
            Spacer()
            Text(String(localized: "activity.network_note"))
                .font(.system(size: 8 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
        }
    }
    
    private func summaryItem(_ title: LocalizedStringKey, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1 * zoomScale) {
            Text(title)
                .font(.system(size: 7 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
            Text(value)
                .font(.system(size: 10 * zoomScale, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }
    }
    
    private var memoryPressureBar: some View {
        VStack(alignment: .trailing, spacing: 2 * zoomScale) {
            Text(String(localized: "activity.memory_pressure"))
                .font(.system(size: 7 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2 * zoomScale)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 2 * zoomScale)
                        .fill(memoryPressureColor)
                        .frame(width: max(2, geo.size.width * CGFloat(monitor.memory.usedPercent)))
                }
            }
            .frame(width: 80 * zoomScale, height: 6 * zoomScale)
        }
    }
    
    private var memoryPressureColor: Color {
        let p = monitor.memory.usedPercent
        if p > 0.9 { return .red }
        if p > 0.75 { return .orange }
        if p > 0.6 { return .yellow }
        return .green
    }
    
    // MARK: - Permissions
    
    private func checkPermissions() {
        // Process enumeration via KERN_PROC_ALL generally works without extra
        // permissions for user-owned processes. If we can't read any processes,
        // prompt the user. Full access to all processes may require root.
        if monitor.processes.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if monitor.processes.isEmpty {
                    viewModel.showPermissionPrompt = true
                }
            }
        }
    }
}
