//
//  FanControlView.swift
//  ClassGod
//

import SwiftUI
import AppKit

struct FanControlView: View {
    @StateObject private var viewModel = FanControlViewModel()
    @ObservedObject private var prefs = PreferencesManager.shared
    @ObservedObject private var helper = PrivilegedHelperManager.shared

    var onClose: () -> Void

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    private var unit: TemperatureUnit { prefs.preferences.fanControlTemperatureUnit }
    private var hasControllableFans: Bool { viewModel.fans.contains(where: \.canControl) }
    private var hasLiveFans: Bool { viewModel.fans.contains(where: \.hasPlausibleLiveRPM) }
    private var hasRealTemperatures: Bool { viewModel.sensors.contains { !$0.isEstimated } }
    private var realTemperatureCount: Int { viewModel.sensors.filter { !$0.isEstimated }.count }
    private var averageTemperatureText: String {
        hasRealTemperatures ? unit.formatted(viewModel.averageComputerTemp) : "--"
    }
    private var averageCPUTemperatureText: String {
        viewModel.sensors.contains { !$0.isEstimated && ($0.name.contains("CPU") || $0.name.contains("Cluster")) }
            ? unit.formatted(viewModel.averageCPUTemp)
            : "--"
    }
    private var averageFanRPMText: String {
        FanControlRouting.averageLiveRPM(in: viewModel.fans).map { "\(Int($0)) RPM" } ?? "-- RPM"
    }
    private var helperRequired: Bool {
        SMCService.shared.isAppleSilicon || !hasControllableFans
    }
    private var helperHealthy: Bool {
        viewModel.helperAvailable || !helperRequired
    }
    private var canRequestHelperAuthorization: Bool {
        HelperAuthorizationPolicy.canRequest(
            status: helper.status,
            hasEmbeddedService: helper.hasEmbeddedService
        )
    }

    private var helperAuthorizationButton: some View {
        Button(action: {
            SoundEffectManager.shared.playButtonClick()
            HapticManager.shared.generic()
            viewModel.requestPrivilegedHelperAuthorization()
        }) {
            HStack(spacing: 4 * zoomScale) {
                Image(systemName: helper.status == .requiresApproval ? "gearshape.fill" : "checkmark.shield.fill")
                    .font(.system(size: 9 * zoomScale))
                Text(helper.status == .requiresApproval
                     ? String(localized: "fan.open_helper_settings")
                     : String(localized: "fan.authorize_helper"))
                    .font(.system(size: 10 * zoomScale, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(.green.opacity(0.9))
            .padding(.horizontal, 8 * zoomScale)
            .padding(.vertical, 4 * zoomScale)
        }
        .buttonStyle(.plain)
        .disabled(!canRequestHelperAuthorization)
        .opacity(canRequestHelperAuthorization ? 1 : 0.4)
    }

    private var helperStatusMessage: String {
        if viewModel.helperAvailable {
            return String(localized: "helper.status.running")
        }
        if !helperRequired {
            return String(localized: "helper.status.optional")
        }
        switch helper.status {
        case .enabled:
            return String(localized: "helper.status.starting")
        case .requiresApproval:
            return String(localized: "helper.status.requires_approval")
        case .notRegistered:
            return String(localized: "helper.status.not_registered")
        case .notFound:
            return String(localized: helper.hasEmbeddedService
                          ? "helper.status.service_unavailable"
                          : "helper.status.not_found")
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12 * zoomScale) {
                        temperatureSection
                        fanSection
                        diagnosticsSection
                    }
                    .padding(.vertical, 10 * zoomScale)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius * zoomScale)
                .fill(Color.black)
        )
        .overlay(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius * zoomScale)
                .stroke(Color.white.opacity(0.15), lineWidth: 1 * zoomScale)
                .allowsHitTesting(false)
        )
        .onAppear {
            helper.refreshStatus()
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
        .onChange(of: prefs.preferences.fanControlUpdateInterval) { _, _ in
            viewModel.startMonitoring()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            helper.refreshStatus()
            if helper.status == .enabled, !viewModel.helperAvailable {
                viewModel.rescanHardware()
            }
        }
        .alert(String(localized: "alert.error"), isPresented: $viewModel.showError) {
            Button(String(localized: "button.ok"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? String(localized: "error.unknown"))
        }
        .overlay(
            toastOverlay
                .animation(Anim.enabled ? .easeInOut(duration: Anim.duration) : nil, value: viewModel.showToast),
            alignment: .bottom
        )
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10 * zoomScale) {
                Button(action: {
                    HapticManager.shared.generic()
                    onClose()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10 * zoomScale, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                        .background(Color(white: 0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("button.close"))

                VStack(alignment: .leading, spacing: 0) {
                    Text("fan.title")
                        .font(.system(size: 14 * zoomScale, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)

                    Text(String(
                        format: String(localized: "fan.header.summary"),
                        averageTemperatureText,
                        averageCPUTemperatureText,
                        averageFanRPMText
                    ))
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                HStack(spacing: 0) {
                    ForEach(FanControlMode.allCases) { mode in
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                            viewModel.setFanMode(mode)
                        }) {
                            Text(mode.displayName)
                                .font(.system(size: 9 * zoomScale, weight: .medium, design: .monospaced))
                                .foregroundStyle(viewModel.fanMode == mode ? .black : .white.opacity(0.7))
                                .padding(.horizontal, 6 * zoomScale)
                                .padding(.vertical, 4 * zoomScale)
                                .background(
                                    viewModel.fanMode == mode
                                    ? Color.white
                                    : Color.white.opacity(0.05)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(mode != .system && !hasControllableFans)
                        .opacity(mode == .system || hasControllableFans ? 1 : 0.4)
                    }
                }
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))

                // Boost button
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                    if viewModel.isBoostActive {
                        viewModel.cancelBoost()
                    } else {
                        viewModel.startBoost(duration: 30)
                    }
                }) {
                    HStack(spacing: 3 * zoomScale) {
                        Image(systemName: viewModel.isBoostActive ? "bolt.fill" : "bolt")
                            .font(.system(size: 9 * zoomScale, weight: .bold))
                        Text(viewModel.isBoostActive ? String(localized: "fan.boosting") : String(localized: "fan.boost"))
                            .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                    }
                    .opacity(hasControllableFans ? 1.0 : 0.4)
                    .foregroundStyle(viewModel.isBoostActive ? .black : .yellow.opacity(0.8))
                    .padding(.horizontal, 8 * zoomScale)
                    .padding(.vertical, 4 * zoomScale)
                    .background(
                        viewModel.isBoostActive
                        ? Color.yellow
                        : Color.yellow.opacity(0.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4 * zoomScale)
                            .stroke(Color.yellow.opacity(viewModel.isBoostActive ? 1 : 0.3), lineWidth: 1)
                            .allowsHitTesting(false)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!hasControllableFans)
            }
            .padding(.horizontal)
            .padding(.vertical, 10 * zoomScale)

            // Status bar
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    let statusColor: Color = {
                        if viewModel.helperAvailable || viewModel.smcConnected && !viewModel.usingIORegistry {
                            return Color.green
                        } else if viewModel.smcConnected && viewModel.usingIORegistry {
                            return Color.yellow
                        } else if viewModel.usingIORegistry {
                            return Color.yellow
                        } else {
                            return Color.red
                        }
                    }()
                    
                    let statusText: String = {
                        if viewModel.helperAvailable {
                            return String(localized: "status.helper_connected")
                        } else if viewModel.smcConnected && !viewModel.usingIORegistry {
                            return String(localized: "status.smc_connected")
                        } else if viewModel.smcConnected && viewModel.usingIORegistry {
                            return String(localized: "status.smc_limited")
                        } else if viewModel.usingIORegistry {
                            return String(localized: "status.ioregistry")
                        } else {
                            return String(localized: "status.no_hardware")
                        }
                    }()
                    
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6 * zoomScale, height: 6 * zoomScale)

                    Text(statusText)
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Text(String(format: String(localized: "fan.sensor_fan_count"), viewModel.sensors.count, viewModel.fans.count))
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal)
            .padding(.vertical, 4 * zoomScale)

            Divider()
                .background(Color.white.opacity(0.1))
        }
    }

    // MARK: - Temperature Section

    private var temperatureSection: some View {
        VStack(alignment: .leading, spacing: 8 * zoomScale) {
            HStack {
                Label(String(localized: "fan.temperatures"), systemImage: "thermometer")
                    .font(.system(size: 12 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                Spacer()

                HStack(spacing: 8) {
                    Text(String(
                        format: String(localized: "fan.highest_temp"),
                        hasRealTemperatures ? unit.formatted(viewModel.highestTemperature) : "--"
                    ))
                        .font(.system(size: 10 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))

                    Button(action: {
                        SoundEffectManager.shared.playButtonClick()
                        HapticManager.shared.generic()
                        prefs.preferences.fanControlTemperatureUnit = (prefs.preferences.fanControlTemperatureUnit == .celsius) ? .fahrenheit : .celsius
                    }) {
                        Text(unit == .celsius ? "°C" : "°F")
                            .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                            .foregroundStyle(prefs.preferences.themeAccent.color.opacity(0.7))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        SoundEffectManager.shared.playButtonClick()
                        HapticManager.shared.generic()
                        viewModel.resetMaxTemperatures()
                    }) {
                        Text("button.reset")
                            .font(.system(size: 9 * zoomScale, weight: .medium, design: .monospaced))
                            .foregroundStyle(prefs.preferences.themeAccent.color.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            // Sensor filter + search
            HStack(spacing: 6 * zoomScale) {
                HStack(spacing: 4 * zoomScale) {
                    ForEach(SensorFilter.allCases) { filter in
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                            viewModel.sensorFilter = filter
                        }) {
                            Text(filter.displayName)
                                .font(.system(size: 9 * zoomScale, weight: .medium, design: .monospaced))
                                .foregroundStyle(viewModel.sensorFilter == filter ? .black : .white.opacity(0.6))
                                .padding(.horizontal, 8 * zoomScale)
                                .padding(.vertical, 3 * zoomScale)
                                .background(
                                    viewModel.sensorFilter == filter
                                    ? prefs.preferences.themeAccent.color.opacity(0.8)
                                    : Color.white.opacity(0.05)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(filter.displayName))
                    }
                }

                HStack(spacing: 2 * zoomScale) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 8 * zoomScale))
                        .foregroundStyle(.white.opacity(0.3))

                    TextField(String(localized: "activity.search"), text: $viewModel.sensorSearchText)
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white)
                        .textFieldStyle(.plain)
                        .frame(width: 70 * zoomScale)

                    if !viewModel.sensorSearchText.isEmpty {
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                            viewModel.sensorSearchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 8 * zoomScale))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("button.clear"))
                    }
                }
                .padding(.horizontal, 6 * zoomScale)
                .padding(.vertical, 2 * zoomScale)
                .background(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 4 * zoomScale)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        .allowsHitTesting(false)
                )
            }
            .padding(.horizontal)

            VStack(spacing: 4 * zoomScale) {
                if viewModel.filteredSensors.isEmpty {
                    HStack {
                        Spacer()
                        Text(viewModel.sensorSearchText.isEmpty
                             ? String(localized: "fan.no_sensors")
                             : String(format: String(localized: "fan.no_sensor_matches"), viewModel.sensorSearchText))
                            .font(.system(size: 10 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.3))
                        Spacer()
                    }
                    .padding(.vertical, 8 * zoomScale)
                } else {
                    ForEach(viewModel.filteredSensors) { sensor in
                        TemperatureRow(
                            sensor: sensor,
                            unit: unit,
                            zoomScale: zoomScale,
                            observedMax: viewModel.observedMaxTemp(for: sensor.key),
                            trend: viewModel.trendForSensor(key: sensor.key),
                            history: viewModel.historyForSensor(key: sensor.key)
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Fan Section

    private var fanSection: some View {
        VStack(alignment: .leading, spacing: 8 * zoomScale) {
            HStack {
                Label("fan.diagnostic.fans", systemImage: "fanblades")
                    .font(.system(size: 12 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                Spacer()
                
                // Rescan button
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                    viewModel.rescanHardware()
                }) {
                    HStack(spacing: 3 * zoomScale) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 8 * zoomScale))
                        Text("fan.rescan")
                            .font(.system(size: 9 * zoomScale, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(prefs.preferences.themeAccent.color.opacity(0.7))
                    .padding(.horizontal, 6 * zoomScale)
                    .padding(.vertical, 2 * zoomScale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4 * zoomScale)
                            .stroke(prefs.preferences.themeAccent.color.opacity(0.3), lineWidth: 1 * zoomScale)
                            .allowsHitTesting(false)
                    )
                }
                .buttonStyle(.plain)

                if viewModel.fans.isEmpty {
                    Text("fan.no_fans")
                        .font(.system(size: 10 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(.horizontal)

            // Fan access reason / permission hint
            if let reason = viewModel.fanAccessReason {
                VStack(alignment: .leading, spacing: 5 * zoomScale) {
                    HStack(spacing: 6 * zoomScale) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9 * zoomScale))
                            .foregroundStyle(.yellow)

                        Text(reason)
                            .font(.system(size: 9 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }

                }
                .padding(.horizontal)
                .padding(.vertical, 6 * zoomScale)
                .background(Color.yellow.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 4 * zoomScale)
                        .stroke(Color.yellow.opacity(0.15), lineWidth: 1 * zoomScale)
                        .allowsHitTesting(false)
                )
                .padding(.horizontal)
            }

            if !hasControllableFans {
                HStack(spacing: 10 * zoomScale) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15 * zoomScale))
                        .foregroundStyle(prefs.preferences.themeAccent.color)
                    VStack(alignment: .leading, spacing: 2 * zoomScale) {
                        Text("fan.manual_unlock.title")
                            .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.88))
                        Text("fan.manual_unlock.subtitle")
                            .font(.system(size: 8 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.42))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    helperAuthorizationButton
                }
                .padding(10 * zoomScale)
                .background(prefs.preferences.themeAccent.color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 7 * zoomScale)
                        .stroke(prefs.preferences.themeAccent.color.opacity(0.18), lineWidth: zoomScale)
                )
                .padding(.horizontal)
            }

            // Active rules indicator (autoMax + custom)
            if (viewModel.fanMode == .autoMax || viewModel.fanMode == .custom) && !viewModel.activeRuleIDs.isEmpty {
                let activeRules = prefs.preferences.fanControlAutoMaxRules.filter { viewModel.activeRuleIDs.contains($0.id) }
                let activeRulesText = activeRules.map { rule in
                    let target = rule.targetMode == .rpm ? "\(Int(rule.targetRPM)) RPM" : "\(Int(rule.targetPercentage))%"
                    return "\(rule.fanTarget.displayName) \(target)"
                }.joined(separator: ", ")
                HStack(spacing: 4 * zoomScale) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8 * zoomScale))
                        .foregroundStyle(.yellow)

                    Text(String(format: String(localized: "fan.active_rules"), activeRulesText))
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.yellow.opacity(0.8))
                        .lineLimit(1)
                }
                .padding(.horizontal)
                .padding(.vertical, 3 * zoomScale)
                .background(Color.yellow.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 4 * zoomScale)
                        .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
                        .allowsHitTesting(false)
                )
                .padding(.horizontal)
            }

            VStack(spacing: 10 * zoomScale) {
                ForEach(viewModel.fans) { fan in
                    FanRow(
                        fan: fan,
                        mode: viewModel.fanMode,
                        zoomScale: zoomScale,
                        accentColor: prefs.preferences.themeAccent.color,
                        history: viewModel.historyForFan(id: fan.id),
                        onRPMChange: { newRPM in
                            viewModel.setFanRPM(newRPM, fanID: fan.id, debounce: true)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Diagnostics Section

    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 6 * zoomScale) {
            HStack {
                Label(String(localized: "fan.diagnostics"), systemImage: "stethoscope")
                    .font(.system(size: 12 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal)

            VStack(spacing: 4 * zoomScale) {
                DiagnosticRow(
                    icon: "checkmark.circle.fill",
                    title: "fan.diagnostic.fans",
                    message: viewModel.fans.isEmpty
                        ? String(localized: "fan.diagnostic.no_fan_data")
                        : String(localized: hasLiveFans ? "fan.diagnostic.fans_ok" : "fan.diagnostic.fans_detected"),
                    isGood: hasLiveFans,
                    zoomScale: zoomScale
                )

                DiagnosticRow(
                    icon: "checkmark.circle.fill",
                    title: "fan.diagnostic.sensors",
                    message: viewModel.sensors.isEmpty
                        ? String(localized: "fan.diagnostic.no_sensor_data")
                        : hasRealTemperatures
                            ? String(format: String(localized: "fan.diagnostic.sensors_active"), realTemperatureCount)
                            : String(localized: "fan.diagnostic.sensors_estimated"),
                    isGood: hasRealTemperatures,
                    zoomScale: zoomScale
                )

                // Privileged helper status
                DiagnosticRow(
                    icon: helperHealthy ? "checkmark.shield.fill" : "lock.shield.fill",
                    title: "fan.diagnostic.helper",
                    message: helperStatusMessage,
                    isGood: helperHealthy,
                    zoomScale: zoomScale
                )

                if !viewModel.sensors.isEmpty {
                    Button(action: {
                        SoundEffectManager.shared.playButtonClick()
                        HapticManager.shared.generic()
                        viewModel.copySensorDataToClipboard()
                    }) {
                        HStack(spacing: 4 * zoomScale) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 9 * zoomScale))
                            Text("fan.copy_sensor_data")
                                .font(.system(size: 10 * zoomScale, weight: .medium, design: .monospaced))
                        }
                        .foregroundStyle(prefs.preferences.themeAccent.color.opacity(0.7))
                        .padding(.horizontal, 8 * zoomScale)
                        .padding(.vertical, 4 * zoomScale)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Toast Overlay

    private var toastOverlay: some View {
        Group {
            if viewModel.showToast, let message = viewModel.toastMessage {
                HStack(spacing: 6 * zoomScale) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                    Text(message)
                        .font(.system(size: 12 * zoomScale, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12 * zoomScale)
                .padding(.vertical, 7 * zoomScale)
                .background(Color(white: 0.12))
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1 * zoomScale)
                        .allowsHitTesting(false)
                )
                .padding(.bottom, 10 * zoomScale)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Temperature Row

struct TemperatureRow: View {
    let sensor: TemperatureSensor
    let unit: TemperatureUnit
    let zoomScale: CGFloat
    var observedMax: Double?
    var trend: TemperatureTrend = .stable
    var history: [Double] = []

    private var displayValue: Double {
        unit.convert(sensor.value)
    }

    private var progress: Double {
        guard sensor.maxValue > 0 else { return 0 }
        return min(1.0, sensor.value / sensor.maxValue)
    }

    private var barColor: Color {
        switch sensor.value {
        case ..<60: return .green
        case 60..<80: return .yellow
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 6 * zoomScale) {
            Text(sensor.name)
                .font(.system(size: 11 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
                .frame(minWidth: 90 * zoomScale, alignment: .leading)
                .lineLimit(1)

            // Trend arrow
            if !sensor.isEstimated {
                Text(trend.rawValue)
                    .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(trend.color)
                    .frame(width: 14 * zoomScale, alignment: .center)
            } else {
                Color.clear.frame(width: 14 * zoomScale)
            }

            // Current value
            if sensor.isEstimated {
                HStack(spacing: 2 * zoomScale) {
                    Text("--")
                        .font(.system(size: 11 * zoomScale, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 8 * zoomScale))
                        .foregroundStyle(.white.opacity(0.25))
                }
                .frame(width: 42 * zoomScale, alignment: .trailing)
            } else {
                Text(unit == .celsius
                     ? String(format: "%.0f°C", displayValue)
                     : String(format: "%.0f°F", displayValue))
                    .font(.system(size: 11 * zoomScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .frame(width: 42 * zoomScale, alignment: .trailing)
            }

            // Observed max
            if !sensor.isEstimated, let max = observedMax, max > 0 {
                let displayMax = unit.convert(max)
                Text(unit == .celsius
                     ? String(format: "→ %.0f°C", displayMax)
                     : String(format: "→ %.0f°F", displayMax))
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 44 * zoomScale, alignment: .trailing)
            }

            if sensor.isEstimated {
                Spacer()
            } else {
                VStack(spacing: 2 * zoomScale) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2 * zoomScale)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 6 * zoomScale)

                            RoundedRectangle(cornerRadius: 2 * zoomScale)
                                .fill(barColor)
                                .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 6 * zoomScale)
                        }
                    }
                    .frame(height: 6 * zoomScale)

                    if history.count >= 3 {
                        TemperatureSparkline(
                            values: history,
                            zoomScale: zoomScale,
                            color: barColor
                        )
                        .frame(height: 10 * zoomScale)
                    }
                }
            }
        }
        .padding(.vertical, 3 * zoomScale)
        .background(
            (!sensor.isEstimated && sensor.value >= 85)
                ? Color.red.opacity(0.08)
                : Color.clear
        )
        .overlay(
            RoundedRectangle(cornerRadius: 3 * zoomScale)
                .stroke(
                    (!sensor.isEstimated && sensor.value >= 85) ? Color.red.opacity(0.25) : Color.clear,
                    lineWidth: 1 * zoomScale
                )
                .allowsHitTesting(false)
        )
        .animation(Anim.enabled ? .easeInOut(duration: Anim.duration) : nil, value: sensor.value >= 85)
    }
}

// MARK: - Temperature Sparkline

struct TemperatureSparkline: View {
    let values: [Double]
    let zoomScale: CGFloat
    let color: Color

    var body: some View {
        GeometryReader { geo in
            sparklinePath(in: geo.size)
                .stroke(color.opacity(0.6), lineWidth: 1 * zoomScale)
        }
    }

    private func sparklinePath(in size: CGSize) -> Path {
        guard let minVal = values.min(), let maxVal = values.max(), maxVal > minVal else {
            return Path()
        }

        let width = size.width
        let height = size.height
        let stepX = width / CGFloat(max(1, values.count - 1))
        let range = maxVal - minVal

        var path = Path()
        for (index, value) in values.enumerated() {
            let x = CGFloat(index) * stepX
            let y = height - ((value - minVal) / range) * height
            let point = CGPoint(x: x, y: y)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}

// MARK: - Fan Row

struct FanRow: View {
    let fan: FanInfo
    let mode: FanControlMode
    let zoomScale: CGFloat
    let accentColor: Color
    var history: [Double] = []
    var onRPMChange: ((Double) -> Void)?


    private var progress: Double {
        guard fan.hasPlausibleLiveRPM, fan.maximumRPM > fan.minimumRPM else { return 0 }
        return min(1, max(0, (fan.actualRPM - fan.minimumRPM) / (fan.maximumRPM - fan.minimumRPM)))
    }

    private var availabilityColor: Color {
        switch fan.availability {
        case .controllable: return .green
        case .readOnly: return .yellow
        case .detected: return accentColor
        }
    }

    private var availabilityKey: String {
        switch fan.availability {
        case .controllable: return "fan.control.realtime"
        case .readOnly: return "fan.control.read_only"
        case .detected: return "fan.control.detected"
        }
    }

    private var barColor: Color {
        guard fan.maximumRPM > fan.minimumRPM else { return accentColor }
        if fan.actualRPM > fan.maximumRPM * 0.9 {
            return .red
        } else if fan.actualRPM > fan.maximumRPM * 0.6 {
            return .yellow
        }
        return .green
    }

    private var displayTargetRPM: Double {
        guard fan.canControl else { return 0 }
        let target = fan.targetRPM > 0 ? fan.targetRPM : fan.actualRPM
        return min(fan.maximumRPM, max(fan.minimumRPM, target))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4 * zoomScale) {
            HStack {
                Text(fan.name)
                    .font(.system(size: 11 * zoomScale, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))

                Text(String(localized: String.LocalizationValue(availabilityKey)))
                    .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(availabilityColor)
                    .padding(.horizontal, 4 * zoomScale)
                    .padding(.vertical, 1 * zoomScale)
                    .background(availabilityColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 3 * zoomScale))

                Spacer()

                Text(fan.hasPlausibleLiveRPM ? "\(Int(fan.actualRPM)) RPM" : "-- RPM")
                    .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                let pct = fan.maximumRPM > fan.minimumRPM
                    ? Int(progress * 100)
                    : 0
                if fan.hasPlausibleLiveRPM, fan.maximumRPM > fan.minimumRPM {
                    Text("(\(pct)%)")
                        .font(.system(size: 10 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 36 * zoomScale, alignment: .trailing)
                }

                if fan.targetRPM > 0 && (mode == .autoMax || mode == .custom || mode == .manual) {
                    Text("/ \(Int(fan.targetRPM))")
                        .font(.system(size: 10 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2 * zoomScale)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 10 * zoomScale)

                    RoundedRectangle(cornerRadius: 2 * zoomScale)
                        .fill(barColor)
                        .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 10 * zoomScale)
                }
            }
            .frame(height: 10 * zoomScale)

            if history.count >= 3 {
                TemperatureSparkline(
                    values: history,
                    zoomScale: zoomScale,
                    color: barColor
                )
                .frame(height: 10 * zoomScale)
            }

            if fan.maximumRPM > fan.minimumRPM {
                HStack {
                    Text("\(Int(fan.minimumRPM))")
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))

                    Spacer()

                    Text("\(Int(fan.maximumRPM))")
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
            } else {
                Text(String(localized: String.LocalizationValue(
                    fan.hasPlausibleLiveRPM
                        ? "fan.control.read_only_detail"
                        : "fan.control.unavailable_detail"
                )))
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.yellow.opacity(0.65))
            }

            // Manual RPM slider (shown in Auto Max mode for override and Manual mode for direct control)
            if fan.canControl && (mode == .autoMax || mode == .manual) {
                HStack(spacing: 8 * zoomScale) {
                    Text(mode == .manual ? String(localized: "fan.set") : String(localized: "fan.manual_override"))
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 45 * zoomScale, alignment: .leading)

                    Slider(
                        value: Binding(
                            get: {
                                (displayTargetRPM - fan.minimumRPM) / (fan.maximumRPM - fan.minimumRPM)
                            },
                            set: { newValue in
                                let rpm = fan.minimumRPM + (fan.maximumRPM - fan.minimumRPM) * newValue
                                onRPMChange?(rpm)
                            }
                        ),
                        in: 0...1
                    )
                    .frame(height: 14 * zoomScale)

                    Text("\(Int(displayTargetRPM))")
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 40 * zoomScale, alignment: .trailing)
                }
                .padding(.top, 2 * zoomScale)
            }
        }
        .padding(.vertical, 4 * zoomScale)
    }
}

// MARK: - Diagnostic Row

struct DiagnosticRow: View {
    let icon: String
    let title: LocalizedStringKey
    let message: String
    let isGood: Bool
    let zoomScale: CGFloat

    var body: some View {
        HStack(spacing: 8 * zoomScale) {
            Image(systemName: isGood ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 10 * zoomScale))
                .foregroundStyle(isGood ? .green : .yellow)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10 * zoomScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))

                Text(message)
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 8 * zoomScale)
        .padding(.vertical, 5 * zoomScale)
        .background(Color.white.opacity(0.02))
        .overlay(
            RoundedRectangle(cornerRadius: 4 * zoomScale)
                .stroke(Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
                .allowsHitTesting(false)
        )
    }
}

// MARK: - Window Wrapper

enum TemperatureTrend: String {
    case rising = "↑"
    case falling = "↓"
    case stable = "→"

    var color: Color {
        switch self {
        case .rising: return .red.opacity(0.7)
        case .falling: return .green.opacity(0.7)
        case .stable: return .white.opacity(0.25)
        }
    }
}

struct FanControlWindowView: View {
    var onClose: () -> Void
    var body: some View {
        FanControlView(onClose: onClose)
    }
}

#Preview {
    FanControlView(onClose: {})
        .frame(width: 420, height: 600)
        .background(Color.black)
}
