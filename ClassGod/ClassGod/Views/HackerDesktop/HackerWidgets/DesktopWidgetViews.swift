//
//  DesktopWidgetViews.swift
//  ClassGod
//
//  SwiftUI views for desktop overlay widgets.
//

import SwiftUI
import Combine

private var desktopWidgetValueAnimation: Animation? {
    Anim.enabled ? .linear(duration: Anim.duration) : nil
}

// MARK: - Container

struct DesktopWidgetContainer: View {
    let widget: HackerWidgetItem
    let isEditMode: Bool
    let onDelete: () -> Void
    let onToggleLock: () -> Void

    @ObservedObject private var monitor = SystemMonitor.shared

    var body: some View {
        ZStack {
            if widget.type.isDesktopTab {
                tabContainer
            } else {
                standardContainer
            }
        }
    }
    
    private var standardContainer: some View {
        ZStack {
            // Widget content
            widgetContent
                .padding(isEditMode ? 6 : 4)
                .padding(.top, isEditMode ? 18 : 4)

            // Edit mode chrome
            if isEditMode {
                editChrome
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.05).opacity(0.88))
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isEditMode ? Color.cyan.opacity(0.6) : Color.white.opacity(0.08), lineWidth: isEditMode ? 2 : 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
    }
    
    private var tabContainer: some View {
        VStack(spacing: 0) {
            // Title bar for desktop tabs
            HStack(spacing: 6) {
                Button(action: {
                    SoundEffectManager.shared.playWidgetDeleted()
                    HapticManager.shared.warning()
                    onDelete()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 18, height: 18)
                        .background(Color(white: 0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Image(systemName: widget.type.iconName)
                    .font(.system(size: 9))
                    .foregroundStyle(.cyan)

                Text(widget.title)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)

                Spacer()

                Button(action: {
                    SoundEffectManager.shared.playWidgetLocked()
                    HapticManager.shared.generic()
                    onToggleLock()
                }) {
                    Image(systemName: widget.isLocked ? "lock.fill" : "lock.open")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(widget.isLocked ? .orange : .white.opacity(0.6))
                        .frame(width: 18, height: 18)
                        .background(Color(white: 0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .frame(height: 28)
            .background(Color(white: 0.08))
            .overlay(
                Rectangle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            
            // Content
            widgetContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(6)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.05).opacity(0.92))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isEditMode ? Color.cyan.opacity(0.5) : Color.white.opacity(0.1), lineWidth: isEditMode ? 1.5 : 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
    }

    @ViewBuilder
    private var widgetContent: some View {
        switch widget.type {
        case .cpuGauge:
            CPUWidgetContent()
        case .memoryBar:
            MemoryWidgetContent()
        case .diskGrid:
            DiskWidgetContent()
        case .networkSpeed:
            NetworkWidgetContent()
        case .processList:
            ProcessWidgetContent()
        case .uptime:
            UptimeWidgetContent()
        case .clock:
            ClockWidgetContent()
        case .battery:
            BatteryWidgetContent()
        case .tempSensors:
            TempWidgetContent()
        case .systemInfo:
            SystemInfoWidgetContent()
        case .finderFile:
            FileWidgetContent(filePath: widget.filePath)
        case .fanThermalList:
            FanThermalWidgetContent()
        case .fanControlDash:
            FanControlDashboardWidgetContent()
        case .taskManager:
            TaskManagerWidgetContent()
        case .noteTab:
            NoteTabContent()
        case .todoTab:
            TodoTabContent()
        case .terminalTab:
            TerminalTabContent()
        case .cryptoTab:
            CryptoTabContent()
        case .quoteTab:
            QuoteTabContent()
        }
    }

    private var editChrome: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: widget.type.iconName)
                    .font(.system(size: 9))
                    .foregroundStyle(.cyan)
                Text(widget.type.displayName)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Button(action: {
                    SoundEffectManager.shared.playWidgetDeleted()
                    HapticManager.shared.warning()
                    onDelete()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)
            .padding(.top, 4)
            Spacer()
        }
    }
}

// MARK: - CPU Widget

struct CPUWidgetContent: View {
    @ObservedObject private var monitor = SystemMonitor.shared

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "cpu")
                    .font(.system(size: 10))
                    .foregroundStyle(.cyan)
                Text("CPU")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: min(monitor.cpu.total / 100.0, 1.0))
                    .stroke(
                        cpuColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(desktopWidgetValueAnimation, value: monitor.cpu.total)
                VStack(spacing: 0) {
                    Text("\(Int(monitor.cpu.total))%")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("\(Int(monitor.cpu.user))% usr")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    private var cpuColor: Color {
        let v = monitor.cpu.total
        if v > 80 { return .red }
        if v > 50 { return .orange }
        return .cyan
    }
}

// MARK: - Memory Widget

struct MemoryWidgetContent: View {
    @ObservedObject private var monitor = SystemMonitor.shared

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "memorychip")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
                Text("Memory")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }

            let used = monitor.memory.usedPercent
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(memColor)
                        .frame(width: max(2, geo.size.width * CGFloat(used)))
                        .animation(desktopWidgetValueAnimation, value: used)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(Int(used * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(formatBytes(Int64(monitor.memory.used))) / \(formatBytes(Int64(monitor.memory.total)))")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    private var memColor: Color {
        let v = monitor.memory.usedPercent
        if v > 0.85 { return .red }
        if v > 0.6 { return .orange }
        return .green
    }
}

// MARK: - Disk Widget

struct DiskWidgetContent: View {
    @ObservedObject private var monitor = SystemMonitor.shared

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "internaldrive")
                    .font(.system(size: 10))
                    .foregroundStyle(.purple)
                Text("Disk")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }

            if let disk = monitor.disks.first {
                let usedRatio = 1.0 - (Double(disk.free) / Double(disk.total))
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: usedRatio)
                        .stroke(
                            diskColor(usedRatio),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(Int(usedRatio * 100))%")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                        Text("used")
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .frame(maxHeight: .infinity)

                Text("\(formatBytes(Int64(disk.free))) free")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            } else {
                Text("No disk data")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(maxHeight: .infinity)
            }
        }
    }

    private func diskColor(_ ratio: Double) -> Color {
        if ratio > 0.9 { return .red }
        if ratio > 0.75 { return .orange }
        return .purple
    }
}

// MARK: - Network Widget

struct NetworkWidgetContent: View {
    @ObservedObject private var monitor = SystemMonitor.shared

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "network")
                    .font(.system(size: 10))
                    .foregroundStyle(.blue)
                Text("Network")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }

            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 9))
                        .foregroundStyle(.green)
                    Text(formatSpeed(monitor.network.downloadSpeedKBs))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 9))
                        .foregroundStyle(.cyan)
                    Text(formatSpeed(monitor.network.uploadSpeedKBs))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxHeight: .infinity)

            Text("Total: \(formatBytes(Int64(monitor.network.bytesIn))) ↓  \(formatBytes(Int64(monitor.network.bytesOut))) ↑")
                .font(.system(size: 7, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
        }
    }
}

// MARK: - Process Widget

struct ProcessWidgetContent: View {
    @ObservedObject private var monitor = SystemMonitor.shared

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
                Text("Top Processes")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }

            VStack(spacing: 2) {
                ForEach(monitor.processes.prefix(5), id: \.pid) { proc in
                    HStack(spacing: 4) {
                        Text(proc.name)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text("\(Int(proc.cpuPercent))%")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(procColor(proc.cpuPercent))
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private func procColor(_ cpu: Double) -> Color {
        if cpu > 50 { return .red }
        if cpu > 20 { return .orange }
        return .white.opacity(0.6)
    }
}

// MARK: - Uptime Widget

struct UptimeWidgetContent: View {
    @ObservedObject private var monitor = SystemMonitor.shared
    @State private var tick = 0

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 10))
                    .foregroundStyle(.pink)
                Text("Uptime")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }

            Text(monitor.uptimeString)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .frame(maxHeight: .infinity)
                .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                    tick += 1
                }
        }
    }
}

// MARK: - Clock Widget

struct ClockWidgetContent: View {
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Image(systemName: "clock.digital")
                    .font(.system(size: 10))
                    .foregroundStyle(.yellow)
                Text("Clock")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }

            Text(timeString)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            Text(dateString)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentTime)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: currentTime)
    }
}

// MARK: - Battery Widget

struct BatteryWidgetContent: View {
    @ObservedObject private var monitor = SystemMonitor.shared

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "battery.100")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
                Text("Battery")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }

            if monitor.battery.isPresent {
                HStack(spacing: 8) {
                    batteryIcon
                        .font(.system(size: 28))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(monitor.battery.level * 100))%")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                        Text(monitor.battery.isCharging ? "Charging" : "Discharging")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(monitor.battery.isCharging ? .green : .white.opacity(0.5))
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                Text("No Battery")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(maxHeight: .infinity)
            }
        }
    }

    private var batteryIcon: some View {
        let level = monitor.battery.level
        let name: String
        switch level {
        case 0..<0.1: name = "battery.0"
        case 0.1..<0.25: name = "battery.25"
        case 0.25..<0.5: name = "battery.50"
        case 0.5..<0.75: name = "battery.75"
        default: name = "battery.100"
        }
        return Image(systemName: monitor.battery.isCharging ? "\(name).bolt" : name)
            .foregroundStyle(batteryColor)
    }

    private var batteryColor: Color {
        let level = monitor.battery.level
        if level < 0.2 { return .red }
        if level < 0.5 { return .orange }
        return .green
    }
}

// MARK: - Temperature Widget

struct TempWidgetContent: View {
    @ObservedObject private var monitor = SystemMonitor.shared

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "thermometer.transmission")
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                Text("Thermal")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }

            VStack(spacing: 8) {
                tempRow(label: "CPU", value: monitor.thermal.cpuTemp)
                tempRow(label: "GPU", value: monitor.thermal.gpuTemp)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func tempRow(label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text("\(Int(value))°C")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(tempColor(value))
        }
    }

    private func tempColor(_ temp: Double) -> Color {
        if temp > 80 { return .red }
        if temp > 65 { return .orange }
        return .cyan
    }
}

// MARK: - System Info Widget

struct SystemInfoWidgetContent: View {
    @ObservedObject private var monitor = SystemMonitor.shared

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
                Text("System")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                infoRow("Host", monitor.system.hostname)
                infoRow("Model", monitor.system.model)
                infoRow("Arch", monitor.system.architecture)
                infoRow("Kernel", monitor.system.kernelVersion)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 40, alignment: .leading)
            Text(value)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - File Widget

struct FileWidgetContent: View {
    let filePath: String?

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "doc")
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
                Text("File")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }

            if let path = filePath, FileManager.default.fileExists(atPath: path) {
                VStack(spacing: 4) {
                    Image(systemName: iconForPath(path))
                        .font(.system(size: 32))
                        .foregroundStyle(.cyan.opacity(0.8))
                    Text((path as NSString).lastPathComponent)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
                .onTapGesture {
                    NSWorkspace.shared.open(URL(fileURLWithPath: path))
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "questionmark.folder")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.2))
                    Text("No file set")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    private func iconForPath(_ path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.text"
        case "jpg", "jpeg", "png", "gif", "heic": return "photo"
        case "mp4", "mov", "avi": return "film"
        case "mp3", "aac", "wav": return "music.note"
        case "zip", "rar", "7z": return "doc.zipper"
        default: return "doc.text"
        }
    }
}

// MARK: - Helpers

private func formatBytes(_ bytes: Int64) -> String {
    let absBytes = Double(bytes)
    let kb = absBytes / 1024
    let mb = kb / 1024
    let gb = mb / 1024
    let tb = gb / 1024

    if tb >= 1 { return String(format: "%.1f TB", tb) }
    if gb >= 1 { return String(format: "%.1f GB", gb) }
    if mb >= 1 { return String(format: "%.0f MB", mb) }
    if kb >= 1 { return String(format: "%.0f KB", kb) }
    return "\(bytes) B"
}

private func formatSpeed(_ kbs: Double) -> String {
    if kbs > 1024 * 1024 {
        return String(format: "%.1f GB/s", kbs / 1024 / 1024)
    } else if kbs > 1024 {
        return String(format: "%.1f MB/s", kbs / 1024)
    } else {
        return String(format: "%.0f KB/s", kbs)
    }
}

// MARK: - Desktop Tab Contents

struct NoteTabContent: View {
    @State private var noteText: String = ""
    private let store = WidgetDataStore.shared
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView(showsIndicators: false) {
            Text(noteText.isEmpty ? String(localized: "widget.no_note") : noteText)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(noteText.isEmpty ? 0.4 : 0.85))
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .onAppear(perform: load)
        .onReceive(timer) { _ in load() }
    }

    private func load() {
        noteText = store.string(forKey: .noteContent) ?? ""
    }
}

struct TodoTabContent: View {
    @State private var items: [TodoItem] = []
    private let store = WidgetDataStore.shared
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView(showsIndicators: false) {
            if items.isEmpty {
                Text("No todos yet.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(items.prefix(8)) { item in
                        HStack(spacing: 4) {
                            Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                                .font(.system(size: 9))
                                .foregroundStyle(item.isDone ? .green : .white.opacity(0.4))
                            Text(item.text)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(item.isDone ? .white.opacity(0.4) : .white.opacity(0.85))
                                .strikethrough(item.isDone)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .onAppear(perform: load)
        .onReceive(timer) { _ in load() }
    }

    private func load() {
        items = store.array(forKey: .todoItems, type: TodoItem.self)
    }
}

struct TerminalTabContent: View {
    @State private var logs: [String] = []
    private let store = WidgetDataStore.shared
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView(showsIndicators: false) {
            if logs.isEmpty {
                Text("No terminal logs yet.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(logs.suffix(8).indices, id: \.self) { idx in
                        Text(logs[idx])
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.green.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .onAppear(perform: load)
        .onReceive(timer) { _ in load() }
    }

    private func load() {
        logs = store.stringArray(forKey: .terminalLogs)
    }
}

struct CryptoTabContent: View {
    @State private var btc: String = ""
    @State private var eth: String = ""
    private let store = WidgetDataStore.shared
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            cryptoRow(symbol: "BTC", value: btc, color: .orange)
            cryptoRow(symbol: "ETH", value: eth, color: .cyan)
            Spacer(minLength: 0)
        }
        .onAppear(perform: load)
        .onReceive(timer) { _ in load() }
    }

    private func cryptoRow(symbol: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(symbol)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(value.isEmpty ? "--" : value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
            Spacer(minLength: 0)
        }
    }

    private func load() {
        btc = store.string(forKey: .cryptoBTC) ?? ""
        eth = store.string(forKey: .cryptoETH) ?? ""
    }
}

struct QuoteTabContent: View {
    @State private var text: String = ""
    @State private var author: String = ""
    private let store = WidgetDataStore.shared
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text.isEmpty ? String(localized: "widget.no_quote") : "\"\(text)\"")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(text.isEmpty ? 0.4 : 0.85))
                .italic(text.isEmpty == false)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if !author.isEmpty {
                Text("— \(author)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            Spacer(minLength: 0)
        }
        .onAppear(perform: load)
        .onReceive(timer) { _ in load() }
    }

    private func load() {
        text = store.string(forKey: .quoteText) ?? ""
        author = store.string(forKey: .quoteAuthor) ?? ""
    }
}
