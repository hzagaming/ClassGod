//
//  FanAndTaskWidgetContents.swift
//  ClassGod
//
//  Desktop widgets for fan/thermal monitoring and task management.
//

import SwiftUI

// MARK: - Fan Thermal List Widget

struct FanThermalWidgetContent: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var sensors: [TemperatureSensor] = []
    @State private var fanAccessReason: String? = SMCService.shared.fanAccessReason
    @State private var isLoading = true
    @State private var timer: Timer? = nil
    @State private var refreshGate = FanRefreshGate()

    private var unit: TemperatureUnit { prefs.preferences.fanControlTemperatureUnit }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "fan.desk")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
                Text("fan.thermal_sensors")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                if sensors.isEmpty, isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.5)
                }
            }

            if let reason = fanAccessReason, sensors.isEmpty {
                Text(reason)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .frame(maxHeight: .infinity)
            } else if sensors.isEmpty {
                Text("fan.no_thermal_data")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 3) {
                        ForEach(sensors.prefix(12)) { sensor in
                            sensorRow(sensor)
                        }
                    }
                }
            }
        }
        .onAppear(perform: startPolling)
        .onDisappear(perform: stopPolling)
        .onChange(of: prefs.preferences.fanControlUpdateInterval) { _, _ in
            startPolling()
        }
    }

    private func sensorRow(_ sensor: TemperatureSensor) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(sensorColor(sensor.value))
                .frame(width: 6, height: 6)

            Text(sensor.name)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(sensor.isEstimated ? .white.opacity(0.5) : .white.opacity(0.85))
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(unit.formatted(sensor.value))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(sensorColor(sensor.value))
        }
    }

    private func sensorColor(_ temp: Double) -> Color {
        if temp > 85 { return .red }
        if temp > 65 { return .orange }
        if temp > 45 { return .yellow }
        return .cyan
    }

    private func startPolling() {
        refresh()
        let interval = FanRefreshPolicy.normalized(prefs.preferences.fanControlUpdateInterval)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            refresh()
        }
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        guard refreshGate.begin() else { return }
        Task.detached(priority: .userInitiated) {
            let newSensors = SMCService.shared.readTemperatures()
            await MainActor.run {
                defer { refreshGate.end() }
                sensors = newSensors.sorted { $0.value > $1.value }
                fanAccessReason = SMCService.shared.fanAccessReason
                isLoading = false
            }
        }
    }
}

// MARK: - Fan Control Dashboard Widget

struct FanControlDashboardWidgetContent: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var fans: [FanInfo] = []
    @State private var fanAccessReason: String? = SMCService.shared.fanAccessReason
    @State private var timer: Timer? = nil
    @State private var refreshGate = FanRefreshGate()

    private var mode: FanControlMode { prefs.preferences.fanControlMode }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.system(size: 10))
                    .foregroundStyle(.cyan)
                Text("fan.title")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text(mode.displayName)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(modeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(modeColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            if let reason = fanAccessReason, fans.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "fan.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.15))
                    Text(reason)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
            } else if fans.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "fan.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.15))
                    Text("fan.no_fans")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .frame(maxHeight: .infinity)
            } else {
                VStack(spacing: 6) {
                    ForEach(fans) { fan in
                        fanRow(fan)
                    }
                }
                .frame(maxHeight: .infinity)
            }

            HStack(spacing: 4) {
                modeButton(.system, label: "Sys")
                modeButton(.max, label: "Max")
                modeButton(.autoMax, label: "Auto")
            }
            .frame(height: 24)
        }
        .onAppear(perform: startPolling)
        .onDisappear(perform: stopPolling)
        .onChange(of: prefs.preferences.fanControlUpdateInterval) { _, _ in
            startPolling()
        }
    }

    private func fanRow(_ fan: FanInfo) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(fan.name)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(Int(fan.actualRPM)) RPM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(fanRPMColor(fan))
                        .frame(width: max(2, geo.size.width * fanRatio(fan)))
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(Int(fan.minimumRPM))")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                Spacer()
                Text("\(Int(fan.maximumRPM))")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
    }

    private func fanRatio(_ fan: FanInfo) -> CGFloat {
        let range = fan.maximumRPM - fan.minimumRPM
        guard range > 0 else { return 0 }
        return CGFloat((fan.actualRPM - fan.minimumRPM) / range)
    }

    private func fanRPMColor(_ fan: FanInfo) -> Color {
        let ratio = fanRatio(fan)
        if ratio > 0.85 { return .red }
        if ratio > 0.6 { return .orange }
        return .cyan
    }

    private var modeColor: Color {
        switch mode {
        case .system: return .green
        case .max: return .red
        case .autoMax: return .orange
        case .manual: return .yellow
        case .custom: return .purple
        }
    }

    private func modeButton(_ target: FanControlMode, label: String) -> some View {
        Button(action: {
            _ = SMCService.shared.setFanMode(target)
            prefs.preferences.fanControlMode = target
        }) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(mode == target ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 22)
                .background(mode == target ? modeColor.opacity(0.8) : Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private func startPolling() {
        refresh()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: FanRefreshPolicy.normalized(prefs.preferences.fanControlUpdateInterval), repeats: true) { _ in
            refresh()
        }
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        guard refreshGate.begin() else { return }
        Task.detached(priority: .userInitiated) {
            let newFans = SMCService.shared.readFans()
            await MainActor.run {
                defer { refreshGate.end() }
                fans = newFans
                fanAccessReason = SMCService.shared.fanAccessReason
            }
        }
    }
}

// MARK: - Task Manager Widget

struct TaskManagerWidgetContent: View {
    @ObservedObject private var monitor = SystemMonitor.shared
    @State private var sortBy: SortKey = .cpu
    @State private var timer: Timer? = nil

    enum SortKey {
        case cpu, memory
    }

    private var processes: [ProcessMonitorInfo] {
        let list = monitor.processes
        switch sortBy {
        case .cpu:
            return list.sorted { $0.cpuPercent > $1.cpuPercent }
        case .memory:
            return list.sorted { $0.memoryMB > $1.memoryMB }
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "list.bullet.indent")
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
                Text("widget.task_manager")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                HStack(spacing: 2) {
                    sortButton(.cpu, icon: "cpu")
                    sortButton(.memory, icon: "memorychip")
                }
            }

            // Header
            HStack(spacing: 4) {
                Text("Process")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("CPU")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 36, alignment: .trailing)
                Text("Mem")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 44, alignment: .trailing)
            }
            .padding(.horizontal, 2)

            if processes.isEmpty {
                Text("No process data")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 2) {
                        ForEach(processes.prefix(15)) { proc in
                            processRow(proc)
                        }
                    }
                }
            }
        }
        .onAppear {
            SystemMonitor.shared.start(interval: 2.0)
        }
        .onDisappear {
            SystemMonitor.shared.stop()
        }
    }

    private func processRow(_ proc: ProcessMonitorInfo) -> some View {
        HStack(spacing: 4) {
            Text(proc.name)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(Int(proc.cpuPercent))%")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(cpuColor(proc.cpuPercent))
                .frame(width: 36, alignment: .trailing)

            Text("\(Int(proc.memoryMB)) MB")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            // Future: show process details or kill action
        }
    }

    private func sortButton(_ key: SortKey, icon: String) -> some View {
        Button(action: { sortBy = key }) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(sortBy == key ? .black : .white.opacity(0.6))
                .frame(width: 22, height: 18)
                .background(sortBy == key ? Color.green.opacity(0.8) : Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }

    private func cpuColor(_ cpu: Double) -> Color {
        if cpu > 50 { return .red }
        if cpu > 20 { return .orange }
        return .white.opacity(0.6)
    }
}
