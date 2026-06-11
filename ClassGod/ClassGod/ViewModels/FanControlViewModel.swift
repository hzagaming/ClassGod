//
//  FanControlViewModel.swift
//  ClassGod
//

import Foundation
import AppKit
import Combine
import UserNotifications

@MainActor
final class FanControlViewModel: ObservableObject {
    @Published var sensors: [TemperatureSensor] = []
    @Published var fans: [FanInfo] = []
    @Published var fanMode: FanControlMode = .system
    @Published var isMonitoring = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var toastMessage: String?
    @Published var showToast = false
    @Published var menuBarDisplay: String = ""
    @Published var sensorFilter: SensorFilter = .all
    @Published var smcConnected: Bool = false
    @Published var usingIORegistry: Bool = false
    @Published var fanAccessReason: String?
    @Published var isSleeping: Bool = false
    @Published var activeRuleIDs: Set<UUID> = []
    @Published var isBoostActive: Bool = false
    @Published var sensorSearchText: String = ""

    private var timer: Timer?
    private var autoMaxTimer: Timer?
    private var gradualTimer: Timer?
    private var boostTimer: Timer?
    private var preBoostFanMode: FanControlMode?
    private let prefs = PreferencesManager.shared
    private var maxTemps: [String: Double] = [:]
    private var previousSensorValues: [String: Double] = [:]
    private var sensorHistory: [String: [Double]] = [:]
    private var fanHistory: [Int: [Double]] = [:]
    private let maxHistoryPoints = 30
    private var lastNotificationDate: Date?
    private var fanTargets: [Int: Double] = [:]
    private var ruleTriggerStartTimes: [UUID: Date] = [:]
    private var ruleActiveStates: [UUID: Bool] = [:]
    private var pendingSetRPMWorkItem: DispatchWorkItem?

    var highestTemperature: Double {
        sensors.filter { !$0.isEstimated }.map(\.value).max() ?? 0
    }

    var averageFanRPM: Double {
        guard !fans.isEmpty else { return 0 }
        return fans.map(\.actualRPM).reduce(0, +) / Double(fans.count)
    }

    var averageComputerTemp: Double {
        let real = sensors.filter { !$0.isEstimated }
        guard !real.isEmpty else { return 0 }
        return real.map(\.value).reduce(0, +) / Double(real.count)
    }

    var averageCPUTemp: Double {
        let cpuSensors = sensors.filter { !$0.isEstimated && ($0.name.contains("CPU") || $0.name.contains("Cluster")) }
        guard !cpuSensors.isEmpty else { return 0 }
        return cpuSensors.map(\.value).reduce(0, +) / Double(cpuSensors.count)
    }

    var filteredSensors: [TemperatureSensor] {
        let filtered: [TemperatureSensor]
        switch sensorFilter {
        case .all:
            filtered = sensors
        case .cpu:
            filtered = sensors.filter { $0.name.contains("CPU") || $0.name.contains("Cluster") }
        case .gpu:
            filtered = sensors.filter { $0.name.contains("GPU") }
        case .battery:
            filtered = sensors.filter { $0.name.contains("Battery") }
        case .other:
            filtered = sensors.filter { !($0.name.contains("CPU") || $0.name.contains("Cluster") || $0.name.contains("GPU") || $0.name.contains("Battery")) }
        }
        let searchFiltered = sensorSearchText.isEmpty
            ? filtered
            : filtered.filter { $0.name.localizedCaseInsensitiveContains(sensorSearchText) }
        return searchFiltered.sorted {
            // Estimated sensors should appear at the bottom so real readings are visible first.
            if $0.isEstimated != $1.isEstimated { return !$0.isEstimated }
            return $0.value > $1.value
        }
    }

    func observedMaxTemp(for key: String) -> Double? {
        maxTemps[key]
    }

    func trendForSensor(key: String) -> TemperatureTrend {
        guard let previous = previousSensorValues[key] else { return .stable }
        guard let current = sensors.first(where: { $0.key == key })?.value else { return .stable }
        let delta = current - previous
        if delta > 0.5 { return .rising }
        if delta < -0.5 { return .falling }
        return .stable
    }

    func historyForSensor(key: String) -> [Double] {
        sensorHistory[key] ?? []
    }

    func historyForFan(index: Int) -> [Double] {
        fanHistory[index] ?? []
    }

    init() {
        fanMode = prefs.preferences.fanControlMode
        setupSleepObservers()
        requestNotificationPermission()
        NotificationCenter.default.addObserver(self, selector: #selector(stopMonitoring), name: .fanControlWindowWillHide, object: nil)
    }

    deinit {
        timer?.invalidate()
        autoMaxTimer?.invalidate()
        gradualTimer?.invalidate()
        boostTimer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didWakeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("fanControlWindowWillHide"), object: nil)
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // First refresh to discover fans/sensors
        refresh()

        // Apply saved fan mode to SMC now that we know fan count
        applyFanModeToSMC(fanMode)
        if fanMode == .autoMax || fanMode == .custom {
            startAutoMax()
        }

        // Start periodic refresh timer
        let interval = max(0.5, prefs.preferences.fanControlUpdateInterval)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }

        startGradualTimer()
    }
    
    func rescanHardware() {
        SMCService.shared.rescan()
        // Clear cached history since sensor keys may change after rescan
        sensorHistory.removeAll()
        fanHistory.removeAll()
        maxTemps.removeAll()
        previousSensorValues.removeAll()
        // Force refresh
        refresh()
        // Update UI state
        smcConnected = SMCService.shared.isConnected
        usingIORegistry = SMCService.shared.isUsingIORegistryFallback
        fanAccessReason = SMCService.shared.fanAccessReason
        showToast(message: "Hardware rescan complete")

        // Restart periodic refresh timer
        let interval = max(0.5, prefs.preferences.fanControlUpdateInterval)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }

        startGradualTimer()
    }

    private func applyFanModeToSMC(_ mode: FanControlMode) {
        // Only command the SMC for system/max modes. Manual/custom are UI-driven.
        guard mode == .max || mode == .system else { return }
        for i in fans.indices {
            _ = SMCService.shared.setFanMode(mode, fanIndex: i)
        }
    }

    @objc func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
        autoMaxTimer?.invalidate()
        autoMaxTimer = nil
        gradualTimer?.invalidate()
        gradualTimer = nil
        boostTimer?.invalidate()
        boostTimer = nil
        
        // When the panel closes, release fans back to system control so they
        // don't stay stuck at the last commanded RPM.
        if fanMode != .system {
            for i in fans.indices {
                _ = SMCService.shared.setFanMode(.system, fanIndex: i)
            }
            fans = fans.map {
                var f = $0
                f.targetRPM = 0
                return f
            }
            fanTargets.removeAll()
        }
        
        // Restore pre-boost mode if window hides during boost
        if isBoostActive, let mode = preBoostFanMode {
            setFanMode(mode)
        }
        isBoostActive = false
        preBoostFanMode = nil
    }

    func refresh() {
        // Save previous values for trend detection while still on MainActor
        let previous = Dictionary(uniqueKeysWithValues: sensors.map { ($0.key, $0.value) })

        // Move the SMC / helper I/O off the main thread so the UI stays fluid.
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let all = SMCService.shared.readAll()
            await MainActor.run {
                self.previousSensorValues = previous
                self.sensors = all.sensors
                self.fans = all.fans
                self.smcConnected = SMCService.shared.isConnected
                self.usingIORegistry = SMCService.shared.isUsingIORegistryFallback
                self.fanAccessReason = SMCService.shared.fanAccessReason

                // Track max temperatures and history (skip estimated placeholders)
                for sensor in self.sensors {
                    if !sensor.isEstimated {
                        let currentMax = self.maxTemps[sensor.key] ?? 0
                        if sensor.value > currentMax {
                            self.maxTemps[sensor.key] = sensor.value
                        }
                    }
                    var history = self.sensorHistory[sensor.key] ?? []
                    history.append(sensor.value)
                    if history.count > self.maxHistoryPoints {
                        history.removeFirst(history.count - self.maxHistoryPoints)
                    }
                    self.sensorHistory[sensor.key] = history
                }

                // Track fan RPM history
                for (index, fan) in self.fans.enumerated() {
                    var history = self.fanHistory[index] ?? []
                    history.append(fan.actualRPM)
                    if history.count > self.maxHistoryPoints {
                        history.removeFirst(history.count - self.maxHistoryPoints)
                    }
                    self.fanHistory[index] = history
                }

                self.updateMenuBarDisplay()
                self.checkTemperatureNotification()
            }
        }
    }

    func setFanMode(_ mode: FanControlMode) {
        fanMode = mode
        prefs.preferences.fanControlMode = mode

        autoMaxTimer?.invalidate()
        autoMaxTimer = nil

        boostTimer?.invalidate()
        boostTimer = nil
        isBoostActive = false

        // Clear auto targets when leaving auto/custom/manual mode to prevent gradual ramp from fighting
        if mode != .autoMax && mode != .custom {
            fanTargets.removeAll()
            activeRuleIDs.removeAll()
        }

        // For system/max we actually command the SMC. Manual/custom are UI-driven.
        let requiresSMC: Bool = (mode == .system || mode == .max)
        var smcSuccess = true
        if requiresSMC {
            for i in fans.indices {
                if !SMCService.shared.setFanMode(mode, fanIndex: i) {
                    smcSuccess = false
                }
            }
        }

        if mode == .autoMax || mode == .custom {
            startAutoMax()
        }

        // Refresh to show updated target RPMs
        fans = SMCService.shared.readFans()

        if requiresSMC {
            if smcSuccess {
                showToast(message: "Fan mode set to \(mode.displayName)")
            } else {
                showError(message: "Failed to set fan mode. May require elevated privileges.")
            }
        } else {
            showToast(message: "Fan mode set to \(mode.displayName)")
        }
    }

    func setFanRPM(_ rpm: Double, fanIndex: Int, debounce: Bool = false) {
        guard fanIndex < fans.count else { return }
        if debounce {
            pendingSetRPMWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?._applySetFanRPM(rpm, fanIndex: fanIndex)
            }
            pendingSetRPMWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
        } else {
            _applySetFanRPM(rpm, fanIndex: fanIndex)
        }
    }

    private func _applySetFanRPM(_ rpm: Double, fanIndex: Int) {
        let success = SMCService.shared.setFanRPM(rpm, fanIndex: fanIndex)
        // In manual mode always update the local target so the UI reflects the slider.
        // In autoMax/custom only update if the SMC actually accepted the write.
        if success || fanMode == .manual {
            fans[fanIndex].targetRPM = rpm
            // Update fanTargets so gradual ramp doesn't fight manual control
            fanTargets[fanIndex] = rpm
        }
    }

    func resetMaxTemperatures() {
        maxTemps.removeAll()
        showToast(message: "Max temperatures reset")
    }

    func copySensorDataToClipboard() {
        let unit = prefs.preferences.fanControlTemperatureUnit
        var lines: [String] = []
        lines.append("ClassGod Fan Control Sensor Report")
        lines.append("Generated: \(Date().formatted(date: .abbreviated, time: .standard))")
        lines.append("")
        lines.append("=== Temperature Sensors ===")
        for sensor in sensors.sorted(by: { $0.value > $1.value }) {
            let estimateMarker = sensor.isEstimated ? " [estimated]" : ""
            let display = unit == .celsius
                ? String(format: "%.1f°C", sensor.value)
                : String(format: "%.1f°F", unit.convert(sensor.value))
            let maxDisplay = maxTemps[sensor.key].map { unit == .celsius ? String(format: "%.1f°C", $0) : String(format: "%.1f°F", unit.convert($0)) } ?? "N/A"
            lines.append("\(sensor.name): \(display) (Max: \(maxDisplay))\(estimateMarker)")
        }
        lines.append("")
        lines.append("=== Fans ===")
        for fan in fans {
            let pct = fan.maximumRPM > fan.minimumRPM
                ? Int((fan.actualRPM - fan.minimumRPM) / (fan.maximumRPM - fan.minimumRPM) * 100)
                : 0
            lines.append("\(fan.name): \(Int(fan.actualRPM)) RPM (\(pct)%) | Target: \(Int(fan.targetRPM)) RPM | Range: \(Int(fan.minimumRPM))-\(Int(fan.maximumRPM)) RPM")
        }
        lines.append("")
        lines.append("SMC: \(smcConnected ? "Connected" : (usingIORegistry ? "IORegistry Fallback" : "Unavailable"))")

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(lines.joined(separator: "\n"), forType: .string)
        showToast(message: "Sensor data copied to clipboard")
    }

    // MARK: - Boost

    func startBoost(duration: TimeInterval = 30) {
        guard !fans.isEmpty, !isBoostActive else { return }
        isBoostActive = true

        // Save current mode
        let previousMode = fanMode
        preBoostFanMode = previousMode

        // Temporarily set mode to max for UI feedback
        fanMode = .max

        // Set all fans to max
        for i in fans.indices {
            _ = SMCService.shared.setFanMode(.max, fanIndex: i)
        }
        fans = SMCService.shared.readFans()

        showToast(message: "Boost active for \(Int(duration))s")

        boostTimer?.invalidate()
        boostTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isBoostActive = false
                // Restore previous mode
                self.setFanMode(previousMode)
                self.preBoostFanMode = nil
                self.showToast(message: "Boost ended — restored \(previousMode.displayName)")
            }
        }
    }

    func cancelBoost() {
        boostTimer?.invalidate()
        boostTimer = nil
        isBoostActive = false
        // Restore actual pre-boost mode, falling back to preferences
        let mode = preBoostFanMode ?? prefs.preferences.fanControlMode
        preBoostFanMode = nil
        setFanMode(mode)
    }

    // MARK: - Auto Max

    private func startAutoMax() {
        autoMaxTimer?.invalidate()
        let interval = max(0.5, prefs.preferences.fanControlUpdateInterval)
        autoMaxTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateAutoMaxRules()
            }
        }
    }

    private func evaluateAutoMaxRules() {
        guard !isSleeping || !prefs.preferences.fanControlDisableOnSleep else { return }
        guard fanMode == .autoMax || fanMode == .custom else { return }

        let rules = prefs.preferences.fanControlAutoMaxRules.filter { $0.isEnabled }
        guard !rules.isEmpty else {
            activeRuleIDs.removeAll()
            fanTargets.removeAll()
            return
        }
        
        // Clear stale targets before re-evaluating so deactivated rules don't leave residuals.
        fanTargets.removeAll()

        // Clean up state for deleted rules
        let validRuleIDs = Set(rules.map(\.id))
        activeRuleIDs.formIntersection(validRuleIDs)
        ruleTriggerStartTimes = ruleTriggerStartTimes.filter { validRuleIDs.contains($0.key) }
        ruleActiveStates = ruleActiveStates.filter { validRuleIDs.contains($0.key) }

        let now = Date()

        for rule in rules {
            let sensorValue = valueForSensor(rule.sensor, specificKey: rule.specificSensorKey)
            let wasActive = ruleActiveStates[rule.id] ?? false

            let conditionMet: Bool
            let releaseThreshold: Double
            switch rule.comparison {
            case .above:
                conditionMet = sensorValue >= rule.threshold
                releaseThreshold = rule.threshold - rule.hysteresis
            case .below:
                conditionMet = sensorValue <= rule.threshold
                releaseThreshold = rule.threshold + rule.hysteresis
            }

            // Hysteresis: once active, stay active until sensor crosses release threshold
            let shouldBeActive: Bool
            if wasActive {
                switch rule.comparison {
                case .above: shouldBeActive = sensorValue >= releaseThreshold
                case .below: shouldBeActive = sensorValue <= releaseThreshold
                }
            } else {
                shouldBeActive = conditionMet
            }

            guard shouldBeActive else {
                ruleActiveStates[rule.id] = false
                ruleTriggerStartTimes.removeValue(forKey: rule.id)
                activeRuleIDs.remove(rule.id)
                continue
            }

            // Duration: condition must be met continuously for N seconds
            let triggerStart = ruleTriggerStartTimes[rule.id]
            if let start = triggerStart {
                if now.timeIntervalSince(start) < rule.durationSeconds {
                    continue // Not enough time yet
                }
            } else {
                ruleTriggerStartTimes[rule.id] = now
                continue // First time seeing condition
            }

            ruleActiveStates[rule.id] = true
            activeRuleIDs.insert(rule.id)

            let targetIndices: [Int]
            switch rule.fanTarget {
            case .allFans:
                targetIndices = Array(fans.indices)
            case .leftFan:
                targetIndices = fans.indices.filter { $0 == 0 }
            case .rightFan:
                targetIndices = fans.indices.filter { $0 == 1 }
            }

            for i in targetIndices {
                let targetRPM: Double
                switch rule.targetMode {
                case .percentage:
                    targetRPM = fans[i].minimumRPM + (fans[i].maximumRPM - fans[i].minimumRPM) * (rule.targetPercentage / 100.0)
                case .rpm:
                    targetRPM = max(fans[i].minimumRPM, min(rule.targetRPM, fans[i].maximumRPM))
                }
                fanTargets[i] = targetRPM
            }
        }
    }

    // MARK: - Gradual Ramping

    private func startGradualTimer() {
        gradualTimer?.invalidate()
        gradualTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.applyGradualRamp()
            }
        }
    }

    private func applyGradualRamp() {
        guard fanMode == .autoMax || fanMode == .custom else { return }
        let gradualTime = max(1.0, prefs.preferences.fanControlGradualTime)
        
        // If no rules are active, release fans back to system control gradually.
        if fanTargets.isEmpty {
            for i in fans.indices {
                guard fans[i].targetRPM != 0 else { continue }
                // Only write once per fan to avoid spamming SMC
                fans[i].targetRPM = 0
                _ = SMCService.shared.setFanMode(.system, fanIndex: i)
            }
            return
        }

        for (index, targetRPM) in fanTargets {
            guard index < fans.count else { continue }
            let currentTarget = fans[index].targetRPM
            let delta = targetRPM - currentTarget

            if abs(delta) < 10 {
                fans[index].targetRPM = targetRPM
                _ = SMCService.shared.setFanRPM(targetRPM, fanIndex: index)
                continue
            }

            let step = delta / gradualTime
            let newTarget = currentTarget + step
            fans[index].targetRPM = newTarget
            _ = SMCService.shared.setFanRPM(newTarget, fanIndex: index)
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        guard prefs.preferences.fanControlEnableNotifications else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func checkTemperatureNotification() {
        guard prefs.preferences.fanControlEnableNotifications else { return }
        let threshold = prefs.preferences.fanControlNotificationThreshold
        let temp = highestTemperature

        guard temp >= threshold else { return }
        guard lastNotificationDate == nil || Date().timeIntervalSince(lastNotificationDate!) > 600 else { return }

        lastNotificationDate = Date()
        let unit = prefs.preferences.fanControlTemperatureUnit
        let content = UNMutableNotificationContent()
        content.title = "ClassGod - High Temperature"
        content.body = "Highest temperature reached \(unit.formatted(temp)) (threshold: \(unit.formatted(threshold)))"
        content.sound = .default

        let request = UNNotificationRequest(identifier: "fancontrol-high-temp-\(Date().timeIntervalSince1970)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)

        SoundEffectManager.shared.playTemperatureWarning()
    }

    // MARK: - Sleep Observers

    private func setupSleepObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    private var preSleepFanMode: FanControlMode?

    @objc private func systemWillSleep() {
        isSleeping = true
        preSleepFanMode = fanMode
        if prefs.preferences.fanControlDisableOnSleep {
            for i in fans.indices {
                _ = SMCService.shared.setFanMode(.system, fanIndex: i)
            }
        }
        // Pause timers to save battery and avoid unnecessary SMC access
        timer?.invalidate()
        timer = nil
        autoMaxTimer?.invalidate()
        autoMaxTimer = nil
        gradualTimer?.invalidate()
        gradualTimer = nil
        boostTimer?.invalidate()
        boostTimer = nil
    }

    @objc private func systemDidWake() {
        isSleeping = false
        // Resume monitoring
        if isMonitoring {
            let interval = max(0.5, prefs.preferences.fanControlUpdateInterval)
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refresh()
                }
            }
            startGradualTimer()
            if fanMode == .autoMax || fanMode == .custom {
                startAutoMax()
            }
        }
        // Restore pre-sleep fan mode if sleep-disable is enabled
        if prefs.preferences.fanControlDisableOnSleep, let mode = preSleepFanMode {
            applyFanModeToSMC(mode)
            fanMode = mode
        }
        preSleepFanMode = nil
    }

    // MARK: - Helpers

    private func valueForSensor(_ sensor: RuleSensor, specificKey: String? = nil) -> Double {
        if let key = specificKey, let matched = sensors.first(where: { $0.key == key }) {
            return matched.value
        }
        // Aggregate rules should ignore estimated placeholders so they only react to real readings.
        let candidates = sensors.filter { !$0.isEstimated }
        switch sensor {
        case .highestCPU:
            return candidates.filter { $0.name.contains("CPU") || $0.name.contains("Cluster") }.map(\.value).max() ?? 0
        case .averageCPU:
            let cpuSensors = candidates.filter { $0.name.contains("CPU") || $0.name.contains("Cluster") }
            guard !cpuSensors.isEmpty else { return 0 }
            return cpuSensors.map(\.value).reduce(0, +) / Double(cpuSensors.count)
        case .highestGPU:
            return candidates.filter { $0.name.contains("GPU") }.map(\.value).max() ?? 0
        case .anySensor:
            return candidates.map(\.value).max() ?? 0
        }
    }

    private func updateMenuBarDisplay() {
        guard prefs.preferences.fanControlShowInMenuBar else {
            menuBarDisplay = ""
            return
        }

        let unit = prefs.preferences.fanControlTemperatureUnit
        let tempStr = unit.formatted(highestTemperature)
        let rpmStr = "\(Int(averageFanRPM)) RPM"
        menuBarDisplay = "\(tempStr) / \(rpmStr)"
    }

    func launchPrivilegedHelper() {
        let helperPath = Bundle.main.bundleURL
            .appendingPathComponent("Contents/MacOS/ClassGodHelper")
            .path
        let script = "do shell script \"sudo '\(helperPath)' > /tmp/classgod_helper.log 2>&1 &\" with administrator privileges"
        
        Task.detached {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = ["-e", script]
            do {
                try task.run()
                task.waitUntilExit()
                await MainActor.run {
                    if task.terminationStatus == 0 {
                        self.showToast(message: "Helper launched. Wait a few seconds and rescan.")
                    } else {
                        self.showError(message: "Helper launch cancelled or failed (exit \(task.terminationStatus)).")
                    }
                }
            } catch {
                await MainActor.run {
                    self.showError(message: "Failed to launch helper: \(error.localizedDescription)")
                }
            }
        }
    }

    func showToast(message: String) {
        toastMessage = message
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showToast = false
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

enum SensorFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case cpu = "CPU"
    case gpu = "GPU"
    case battery = "Battery"
    case other = "Other"

    var id: String { rawValue }
}
