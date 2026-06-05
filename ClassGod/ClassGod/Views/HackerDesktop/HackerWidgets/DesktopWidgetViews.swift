//
//  DesktopWidgetViews.swift
//  ClassGod
//
//  SwiftUI views for desktop overlay widgets.
//

import SwiftUI
import Combine

// MARK: - Container

struct DesktopWidgetContainer: View {
    let widget: HackerWidgetItem
    let isEditMode: Bool
    let onDelete: () -> Void

    @ObservedObject private var monitor = SystemMonitor.shared

    var body: some View {
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
                Button(action: onDelete) {
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
                    .animation(.linear(duration: 0.5), value: monitor.cpu.total)
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
                        .animation(.linear(duration: 0.5), value: used)
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
