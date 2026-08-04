//
//  FanControlViewModel.swift
//  ClassGod
//

import Foundation
import AppKit
import Combine
import UserNotifications

nonisolated enum FanNotificationPolicy {
    static func canDeliver(
        isEnabled: Bool,
        authorizationStatus: UNAuthorizationStatus,
        currentTemperature: Double,
        threshold: Double
    ) -> Bool {
        guard isEnabled, currentTemperature >= threshold else { return false }
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        case .notDetermined, .denied: return false
        @unknown default: return false
        }
    }
}

@MainActor
enum FanRuleSensorResolver {
    static func value(
        for sensor: RuleSensor,
        specificKey: String? = nil,
        sensors: [TemperatureSensor]
    ) -> Double? {
        let candidates = sensors.filter { !$0.isEstimated }
        if let specificKey {
            return candidates.first(where: { $0.key == specificKey })?.value
        }
        switch sensor {
        case .highestCPU:
            return candidates.filter { $0.name.contains("CPU") || $0.name.contains("Cluster") }
                .map(\.value).max()
        case .averageCPU:
            let cpuSensors = candidates.filter { $0.name.contains("CPU") || $0.name.contains("Cluster") }
            guard !cpuSensors.isEmpty else { return nil }
            return cpuSensors.map(\.value).reduce(0, +) / Double(cpuSensors.count)
        case .highestGPU:
            return candidates.filter { $0.name.contains("GPU") }.map(\.value).max()
        case .anySensor:
            return candidates.map(\.value).max()
        }
    }
}

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
    @Published var helperAvailable = false
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
    private var pendingRPMWriteTokens: [Int: UUID] = [:]
    private var refreshGate = FanRefreshGate()
    private var shouldApplySavedModeAfterRefresh = false
    private var rescanGate = FanRefreshGate()
    private var notificationGate = FanRefreshGate()
    private var toastWorkItem: DispatchWorkItem?
    private var toastState = TransientFeedbackState<String>()

    var highestTemperature: Double {
        sensors.filter { !$0.isEstimated }.map(\.value).max() ?? 0
    }

    var averageFanRPM: Double {
        FanControlRouting.averageLiveRPM(in: fans) ?? 0
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

    func historyForFan(id: Int) -> [Double] {
        fanHistory[id] ?? []
    }

    init() {
        fanMode = prefs.preferences.fanControlMode
        setupSleepObservers()
        NotificationCenter.default.addObserver(self, selector: #selector(stopMonitoring), name: .fanControlWindowWillHide, object: nil)
    }

    deinit {
        timer?.invalidate()
        autoMaxTimer?.invalidate()
        gradualTimer?.invalidate()
        boostTimer?.invalidate()
        toastWorkItem?.cancel()
        pendingRPMWriteTokens.removeAll()
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didWakeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("fanControlWindowWillHide"), object: nil)
    }

    func startMonitoring() {
        if isMonitoring {
            // Already running: just re-sync the timer interval and mode timers
            // so preference changes take effect immediately.
            restartRefreshTimer()
            if fanMode == .autoMax || fanMode == .custom {
                startAutoMax()
            } else {
                autoMaxTimer?.invalidate()
                autoMaxTimer = nil
            }
            return
        }
        isMonitoring = true
        fanMode = prefs.preferences.fanControlMode
        shouldApplySavedModeAfterRefresh = true

        // Ensure SystemMonitor is running so CPU-estimated temperature fallback
        // has live CPU load data instead of defaulting to zero.
        SystemMonitor.shared.start(client: .fanControl, interval: 1.0)

        // Discover fans before restoring the saved mode.
        refresh()

        // Start periodic refresh timer
        restartRefreshTimer()
        startGradualTimer()
    }

    private func restartRefreshTimer() {
        let interval = FanRefreshPolicy.normalized(prefs.preferences.fanControlUpdateInterval)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }
    
    func rescanHardware() {
        guard rescanGate.begin() else { return }
        pendingRPMWriteTokens.removeAll()
        // Clear cached history since sensor keys may change after rescan
        sensorHistory.removeAll()
        fanHistory.removeAll()
        maxTemps.removeAll()
        previousSensorValues.removeAll()
        Task { @MainActor [weak self] in
            let hardwareState = await Task.detached(priority: .userInitiated) {
                SMCService.shared.rescan()
                return (
                    smcConnected: SMCService.shared.isConnected,
                    usingIORegistry: SMCService.shared.isUsingIORegistryFallback,
                    fanAccessReason: SMCService.shared.fanAccessReason,
                    helperAvailable: SMCService.shared.isHelperAvailable
                )
            }.value
            guard let self else { return }
            self.rescanGate.end()
            guard self.isMonitoring else { return }
            self.shouldApplySavedModeAfterRefresh = true
            self.refresh()
            self.smcConnected = hardwareState.smcConnected
            self.usingIORegistry = hardwareState.usingIORegistry
            self.fanAccessReason = hardwareState.fanAccessReason
            self.helperAvailable = hardwareState.helperAvailable
            self.showToast(message: String(localized: "fan.toast.rescan_complete"))
            self.restartRefreshTimer()
            self.startGradualTimer()
        }
    }

    private func applyFanModeToSMC(_ mode: FanControlMode) -> Bool {
        let fanIDs = FanControlRouting.controllableIDs(in: fans)
        if mode == .system, fanIDs.isEmpty {
            SMCService.shared.restoreSystemFanControl()
            return true
        }
        guard mode == .system || !fanIDs.isEmpty else { return false }
        var success = true
        for fanID in fanIDs {
            if !SMCService.shared.setFanMode(mode, fanIndex: fanID) {
                success = false
            }
        }
        return success
    }

    @objc func stopMonitoring() {
        toastWorkItem?.cancel()
        toastWorkItem = nil
        toastState.reset()
        showToast = false
        guard isMonitoring else { return }
        isMonitoring = false
        shouldApplySavedModeAfterRefresh = false
        timer?.invalidate()
        timer = nil
        autoMaxTimer?.invalidate()
        autoMaxTimer = nil
        gradualTimer?.invalidate()
        gradualTimer = nil
        boostTimer?.invalidate()
        boostTimer = nil
        pendingRPMWriteTokens.removeAll()
        
        // Balance the SystemMonitor start call from startMonitoring().
        SystemMonitor.shared.stop(client: .fanControl)
        
        // When the panel closes, release fans back to system control so they
        // don't stay stuck at the last commanded RPM. Update the local mode to
        // reflect the real SMC state; the saved preference is left untouched so
        // the panel can restore the user's chosen mode on next open.
        if fanMode != .system {
            SMCService.shared.restoreSystemFanControl()
            fans = fans.map {
                var f = $0
                f.targetRPM = 0
                return f
            }
            fanTargets.removeAll()
            activeRuleIDs.removeAll()
            ruleActiveStates.removeAll()
            ruleTriggerStartTimes.removeAll()
            fanMode = .system
        }
        
        isBoostActive = false
        preBoostFanMode = nil
        preSleepFanMode = nil
    }

    func refresh() {
        guard refreshGate.begin() else { return }
        // Save previous values for trend detection while still on MainActor
        let previous = sensors.reduce(into: [String: Double]()) { $0[$1.key] = $1.value }

        // Move the SMC / helper I/O off the main thread so the UI stays fluid.
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let all = SMCService.shared.readAll()
            let hardwareState = (
                smcConnected: SMCService.shared.isConnected,
                usingIORegistry: SMCService.shared.isUsingIORegistryFallback,
                fanAccessReason: SMCService.shared.fanAccessReason,
                helperAvailable: SMCService.shared.isHelperAvailable
            )
            await MainActor.run {
                defer { self.refreshGate.end() }
                self.previousSensorValues = previous
                self.sensors = all.sensors
                self.fans = all.fans
                self.smcConnected = hardwareState.smcConnected
                self.usingIORegistry = hardwareState.usingIORegistry
                self.fanAccessReason = hardwareState.fanAccessReason
                self.helperAvailable = hardwareState.helperAvailable

                if self.isMonitoring, self.shouldApplySavedModeAfterRefresh {
                    self.shouldApplySavedModeAfterRefresh = false
                    let applied = self.applyFanModeToSMC(self.fanMode)
                    if !applied {
                        self.failSafeToSystem(message: String(localized: "fan.error.mode_set_failed"))
                    } else if self.fanMode == .autoMax || self.fanMode == .custom {
                        self.startAutoMax()
                        self.evaluateAutoMaxRules()
                        self.applyGradualRamp()
                    }
                }

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
                for fan in self.fans {
                    guard fan.hasPlausibleLiveRPM else {
                        self.fanHistory[fan.id] = []
                        continue
                    }
                    var history = self.fanHistory[fan.id] ?? []
                    history.append(fan.actualRPM)
                    if history.count > self.maxHistoryPoints {
                        history.removeFirst(history.count - self.maxHistoryPoints)
                    }
                    self.fanHistory[fan.id] = history
                }

                self.updateMenuBarDisplay()
                self.checkTemperatureNotification()
            }
        }
    }

    func setFanMode(_ mode: FanControlMode) {
        let controllableFanIDs = FanControlRouting.controllableIDs(in: fans)
        guard mode == .system || !controllableFanIDs.isEmpty else {
            showError(message: String(localized: "fan.error.read_only"))
            return
        }
        pendingRPMWriteTokens.removeAll()
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

        var smcSuccess = true
        if mode == .system, controllableFanIDs.isEmpty {
            SMCService.shared.restoreSystemFanControl()
        }
        for fanID in controllableFanIDs {
            if !SMCService.shared.setFanMode(mode, fanIndex: fanID) {
                smcSuccess = false
            }
        }

        if !smcSuccess {
            failSafeToSystem(message: String(localized: "fan.error.mode_set_failed"))
            return
        }

        if mode == .autoMax || mode == .custom {
            startAutoMax()
            // Apply rules immediately so the UI and fans react right away
            // instead of waiting for the next timer tick.
            evaluateAutoMaxRules()
            applyGradualRamp()
            guard fanMode == mode else { return }
        }

        // Refresh to show updated target RPMs
        fans = SMCService.shared.readFans()

        showToast(message: String(format: String(localized: "fan.toast.mode_set"), mode.displayName))
    }

    func setFanRPM(_ rpm: Double, fanID: Int, debounce: Bool = false) {
        guard let position = FanControlRouting.position(of: fanID, in: fans),
              fans[position].canControl else {
            showError(message: String(localized: "fan.error.read_only"))
            return
        }
        if debounce {
            let token = UUID()
            pendingRPMWriteTokens[fanID] = token
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self, self.pendingRPMWriteTokens[fanID] == token else { return }
                self.pendingRPMWriteTokens.removeValue(forKey: fanID)
                self._applySetFanRPM(rpm, fanID: fanID)
            }
        } else {
            pendingRPMWriteTokens.removeValue(forKey: fanID)
            _applySetFanRPM(rpm, fanID: fanID)
        }
    }

    private func _applySetFanRPM(_ rpm: Double, fanID: Int) {
        guard let position = FanControlRouting.position(of: fanID, in: fans) else { return }
        let success = SMCService.shared.setFanRPM(rpm, fanIndex: fanID)
        if success {
            fans[position].targetRPM = rpm
            fanTargets[fanID] = rpm
        } else {
            failSafeToSystem(message: String(localized: "fan.error.rpm_set_failed"))
        }
    }

    func resetMaxTemperatures() {
        maxTemps.removeAll()
        showToast(message: String(localized: "fan.toast.max_temps_reset"))
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
        showToast(message: String(localized: "fan.toast.sensor_data_copied"))
    }

    // MARK: - Boost

    func startBoost(duration: TimeInterval = 30) {
        let controllableFanIDs = FanControlRouting.controllableIDs(in: fans)
        guard !controllableFanIDs.isEmpty, !isBoostActive else {
            if controllableFanIDs.isEmpty {
                showError(message: String(localized: "fan.error.read_only"))
            }
            return
        }
        pendingRPMWriteTokens.removeAll()
        // Save current mode
        let previousMode = fanMode

        // Set all fans to max
        var success = true
        for fanID in controllableFanIDs {
            if !SMCService.shared.setFanMode(.max, fanIndex: fanID) {
                success = false
            }
        }
        guard success else {
            failSafeToSystem(message: String(localized: "fan.error.mode_set_failed"))
            return
        }

        isBoostActive = true
        preBoostFanMode = previousMode
        fanMode = .max
        fans = SMCService.shared.readFans()

        showToast(message: String(format: String(localized: "fan.toast.boost_active"), Int(duration)))

        boostTimer?.invalidate()
        boostTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isBoostActive = false
                // Restore previous mode
                self.setFanMode(previousMode)
                self.preBoostFanMode = nil
                self.showToast(message: String(format: String(localized: "fan.toast.boost_ended"), previousMode.displayName))
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
        let interval = FanRefreshPolicy.normalized(prefs.preferences.fanControlUpdateInterval)
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
            guard let sensorValue = FanRuleSensorResolver.value(
                for: rule.sensor,
                specificKey: rule.specificSensorKey,
                sensors: sensors
            ) else {
                ruleActiveStates[rule.id] = false
                ruleTriggerStartTimes.removeValue(forKey: rule.id)
                activeRuleIDs.remove(rule.id)
                continue
            }
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

            for fanID in FanControlRouting.targetIDs(for: rule.fanTarget, in: fans) {
                guard let position = FanControlRouting.position(of: fanID, in: fans) else { continue }
                let targetRPM: Double
                switch rule.targetMode {
                case .percentage:
                    targetRPM = fans[position].minimumRPM
                        + (fans[position].maximumRPM - fans[position].minimumRPM)
                        * (rule.targetPercentage / 100.0)
                case .rpm:
                    targetRPM = max(fans[position].minimumRPM, min(rule.targetRPM, fans[position].maximumRPM))
                }
                fanTargets[fanID] = targetRPM
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
                guard fans[i].canControl, fans[i].targetRPM != 0 else { continue }
                // Only write once per fan to avoid spamming SMC
                guard SMCService.shared.setFanMode(.system, fanIndex: fans[i].id) else {
                    failSafeToSystem(message: String(localized: "fan.error.mode_set_failed"))
                    return
                }
                fans[i].targetRPM = 0
            }
            return
        }

        for (fanID, targetRPM) in fanTargets {
            guard let position = FanControlRouting.position(of: fanID, in: fans),
                  fans[position].canControl else { continue }
            let currentTarget = fans[position].targetRPM
            let delta = targetRPM - currentTarget

            if abs(delta) < 10 {
                guard SMCService.shared.setFanRPM(targetRPM, fanIndex: fanID) else {
                    failSafeToSystem(message: String(localized: "fan.error.rpm_set_failed"))
                    return
                }
                fans[position].targetRPM = targetRPM
                continue
            }

            let step = delta / gradualTime
            let newTarget = currentTarget + step
            guard SMCService.shared.setFanRPM(newTarget, fanIndex: fanID) else {
                failSafeToSystem(message: String(localized: "fan.error.rpm_set_failed"))
                return
            }
            fans[position].targetRPM = newTarget
        }
    }

    private func failSafeToSystem(message: String) {
        pendingRPMWriteTokens.removeAll()
        autoMaxTimer?.invalidate()
        autoMaxTimer = nil
        fanTargets.removeAll()
        activeRuleIDs.removeAll()
        ruleActiveStates.removeAll()
        ruleTriggerStartTimes.removeAll()
        SMCService.shared.restoreSystemFanControl()
        fanMode = .system
        prefs.preferences.fanControlMode = .system
        fans = SMCService.shared.readFans()
        showError(message: message)
    }

    // MARK: - Notifications

    private func checkTemperatureNotification() {
        guard prefs.preferences.fanControlEnableNotifications else { return }
        let threshold = prefs.preferences.fanControlNotificationThreshold
        let temp = highestTemperature

        guard temp >= threshold else { return }
        guard lastNotificationDate == nil || Date().timeIntervalSince(lastNotificationDate!) > 600 else { return }
        guard notificationGate.begin() else { return }

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.notificationGate.end() }
                let currentTemperature = self.highestTemperature
                let currentThreshold = self.prefs.preferences.fanControlNotificationThreshold
                guard self.isMonitoring,
                      FanNotificationPolicy.canDeliver(
                        isEnabled: self.prefs.preferences.fanControlEnableNotifications,
                        authorizationStatus: settings.authorizationStatus,
                        currentTemperature: currentTemperature,
                        threshold: currentThreshold
                      ),
                      self.lastNotificationDate == nil || Date().timeIntervalSince(self.lastNotificationDate!) > 600 else {
                    return
                }

                self.lastNotificationDate = Date()
                let unit = self.prefs.preferences.fanControlTemperatureUnit
                let content = UNMutableNotificationContent()
                content.title = String(localized: "fan.notification.high_temperature.title")
                content.body = String(
                    format: String(localized: "fan.notification.high_temperature.body"),
                    unit.formatted(currentTemperature),
                    unit.formatted(currentThreshold)
                )
                content.sound = .default

                let request = UNNotificationRequest(
                    identifier: "fancontrol-high-temp-\(Date().timeIntervalSince1970)",
                    content: content,
                    trigger: nil
                )
                do {
                    try await UNUserNotificationCenter.current().add(request)
                    SoundEffectManager.shared.playTemperatureWarning()
                } catch {
                    self.lastNotificationDate = nil
                }
            }
        }
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
        pendingRPMWriteTokens.removeAll()
        // If boost is active, restore the real pre-boost mode before saving sleep state.
        if isBoostActive {
            cancelBoost()
        }
        preSleepFanMode = fanMode
        if prefs.preferences.fanControlDisableOnSleep {
            SMCService.shared.restoreSystemFanControl()
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
        guard isMonitoring else {
            preSleepFanMode = nil
            return
        }
        // Resume monitoring
        let interval = FanRefreshPolicy.normalized(prefs.preferences.fanControlUpdateInterval)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
        startGradualTimer()
        if fanMode == .autoMax || fanMode == .custom {
            startAutoMax()
        }
        // Restore pre-sleep fan mode if sleep-disable is enabled.
        // Reapply the saved mode, then restart rule-driven control when needed.
        if prefs.preferences.fanControlDisableOnSleep, let mode = preSleepFanMode {
            if applyFanModeToSMC(mode) {
                fanMode = mode
            } else {
                failSafeToSystem(message: String(localized: "fan.error.mode_set_failed"))
            }
            if fanMode == .autoMax || fanMode == .custom {
                startAutoMax()
                evaluateAutoMaxRules()
                applyGradualRamp()
            }
        }
        preSleepFanMode = nil
    }

    // MARK: - Helpers

    private func updateMenuBarDisplay() {
        guard prefs.preferences.fanControlShowInMenuBar else {
            menuBarDisplay = ""
            return
        }

        let unit = prefs.preferences.fanControlTemperatureUnit
        let tempStr = sensors.contains(where: { !$0.isEstimated }) ? unit.formatted(highestTemperature) : "--"
        let rpmStr = FanControlRouting.averageLiveRPM(in: fans).map { "\(Int($0)) RPM" } ?? "-- RPM"
        menuBarDisplay = "\(tempStr) / \(rpmStr)"
    }

    func requestPrivilegedHelperAuthorization() {
        do {
            let status = try PrivilegedHelperManager.shared.requestAuthorization()
            switch status {
            case .enabled:
                showToast(message: String(localized: "fan.toast.helper_enabled"))
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    SMCHelperClient.shared.disconnect()
                    self?.rescanHardware()
                }
            case .requiresApproval:
                showToast(message: String(localized: "fan.toast.helper_approval_required"))
                PrivilegedHelperManager.shared.openApprovalSettings()
            case .notRegistered, .notFound:
                showError(message: String(localized: "fan.error.helper_not_found"))
            }
        } catch {
            showError(message: String(format: String(localized: "fan.error.helper_authorization"), error.localizedDescription))
        }
    }

    func showToast(message: String) {
        toastWorkItem?.cancel()
        let token = toastState.present(message)
        toastMessage = message
        showToast = true
        let item = DispatchWorkItem { [weak self] in
            guard let self, self.toastState.dismiss(ifCurrent: token) else { return }
            self.showToast = false
            self.toastWorkItem = nil
        }
        toastWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: item)
    }

    private func showError(message: String) {
        SoundEffectManager.shared.playSwitchFailure()
        HapticManager.shared.warning()
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
    var displayName: String {
        switch self {
        case .all: return String(localized: "permission.category.all")
        case .cpu: return "CPU"
        case .gpu: return "GPU"
        case .battery: return String(localized: "widget.battery")
        case .other: return String(localized: "fan.filter.other")
        }
    }
}
