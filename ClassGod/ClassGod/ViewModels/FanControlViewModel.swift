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

    var highestTemperature: Double {
        sensors.map(\.value).max() ?? 0
    }

    var averageFanRPM: Double {
        guard !fans.isEmpty else { return 0 }
        return fans.map(\.actualRPM).reduce(0, +) / Double(fans.count)
    }

    var averageComputerTemp: Double {
        guard !sensors.isEmpty else { return 0 }
        return sensors.map(\.value).reduce(0, +) / Double(sensors.count)
    }

    var averageCPUTemp: Double {
        let cpuSensors = sensors.filter { $0.name.contains("CPU") || $0.name.contains("Cluster") }
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
        return searchFiltered.sorted { $0.value > $1.value }
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
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // First refresh to discover fans/sensors
        refresh()

        // Apply saved fan mode to SMC now that we know fan count
        applyFanModeToSMC(fanMode)
        if fanMode == .autoMax {
            startAutoMax()
        }

        let interval = max(1.0, prefs.preferences.fanControlUpdateInterval)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }

        startGradualTimer()
    }

    private func applyFanModeToSMC(_ mode: FanControlMode) {
        guard mode != .system else { return }
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
        isBoostActive = false
    }

    func refresh() {
        // Save previous values for trend detection
        previousSensorValues = Dictionary(uniqueKeysWithValues: sensors.map { ($0.key, $0.value) })

        sensors = SMCService.shared.readTemperatures()
        fans = SMCService.shared.readFans()
        smcConnected = SMCService.shared.isConnected
        usingIORegistry = SMCService.shared.isUsingIORegistryFallback

        // Track max temperatures and history
        for sensor in sensors {
            let currentMax = maxTemps[sensor.key] ?? 0
            if sensor.value > currentMax {
                maxTemps[sensor.key] = sensor.value
            }
            var history = sensorHistory[sensor.key] ?? []
            history.append(sensor.value)
            if history.count > maxHistoryPoints {
                history.removeFirst(history.count - maxHistoryPoints)
            }
            sensorHistory[sensor.key] = history
        }

        // Track fan RPM history
        for (index, fan) in fans.enumerated() {
            var history = fanHistory[index] ?? []
            history.append(fan.actualRPM)
            if history.count > maxHistoryPoints {
                history.removeFirst(history.count - maxHistoryPoints)
            }
            fanHistory[index] = history
        }

        updateMenuBarDisplay()
        checkTemperatureNotification()
    }

    func setFanMode(_ mode: FanControlMode) {
        fanMode = mode
        prefs.preferences.fanControlMode = mode

        autoMaxTimer?.invalidate()
        autoMaxTimer = nil

        boostTimer?.invalidate()
        boostTimer = nil
        isBoostActive = false

        // Clear auto targets when leaving auto mode to prevent gradual ramp from fighting
        if mode != .autoMax {
            fanTargets.removeAll()
            activeRuleIDs.removeAll()
        }

        var success = true
        for i in fans.indices {
            if !SMCService.shared.setFanMode(mode, fanIndex: i) {
                success = false
            }
        }

        if mode == .autoMax {
            startAutoMax()
        }

        // Refresh to show updated target RPMs
        fans = SMCService.shared.readFans()

        if success {
            showToast(message: "Fan mode set to \(mode.displayName)")
        } else {
            showError(message: "Failed to set fan mode. May require elevated privileges.")
        }
    }

    func setFanRPM(_ rpm: Double, fanIndex: Int) {
        guard fanIndex < fans.count else { return }
        if SMCService.shared.setFanRPM(rpm, fanIndex: fanIndex) {
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
            let display = unit == .celsius
                ? String(format: "%.1f°C", sensor.value)
                : String(format: "%.1f°F", unit.convert(sensor.value))
            let maxDisplay = maxTemps[sensor.key].map { unit == .celsius ? String(format: "%.1f°C", $0) : String(format: "%.1f°F", unit.convert($0)) } ?? "N/A"
            lines.append("\(sensor.name): \(display) (Max: \(maxDisplay))")
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
        guard !fans.isEmpty else { return }
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
        autoMaxTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateAutoMaxRules()
            }
        }
    }

    private func evaluateAutoMaxRules() {
        guard !isSleeping || !prefs.preferences.fanControlDisableOnSleep else { return }

        let rules = prefs.preferences.fanControlAutoMaxRules.filter { $0.isEnabled }
        guard !rules.isEmpty else {
            activeRuleIDs.removeAll()
            return
        }

        // Clean up state for deleted rules
        let validRuleIDs = Set(rules.map(\.id))
        activeRuleIDs.formIntersection(validRuleIDs)
        ruleTriggerStartTimes = ruleTriggerStartTimes.filter { validRuleIDs.contains($0.key) }
        ruleActiveStates = ruleActiveStates.filter { validRuleIDs.contains($0.key) }

        let now = Date()

        for rule in rules {
            let sensorValue = valueForSensor(rule.sensor)
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
                let targetRPM = fans[i].minimumRPM + (fans[i].maximumRPM - fans[i].minimumRPM) * (rule.targetPercentage / 100.0)
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
        guard fanMode == .autoMax || !fanTargets.isEmpty else { return }
        let gradualTime = max(1.0, prefs.preferences.fanControlGradualTime)

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
    }

    @objc private func systemDidWake() {
        isSleeping = false
        // Resume monitoring
        if isMonitoring {
            let interval = max(1.0, prefs.preferences.fanControlUpdateInterval)
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refresh()
                }
            }
            startGradualTimer()
            if fanMode == .autoMax {
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

    private func valueForSensor(_ sensor: RuleSensor) -> Double {
        switch sensor {
        case .highestCPU:
            return sensors.filter { $0.name.contains("CPU") || $0.name.contains("Cluster") }.map(\.value).max() ?? 0
        case .highestGPU:
            return sensors.filter { $0.name.contains("GPU") }.map(\.value).max() ?? 0
        case .anySensor:
            return sensors.map(\.value).max() ?? 0
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

    private func showToast(message: String) {
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
