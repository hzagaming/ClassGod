//
//  FanControlSettingsView.swift
//  ClassGod
//

import SwiftUI

struct FanControlSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                StatefulCollapsibleSection(
                    title: "section.fan_general",
                    icon: "fanblades",
                    defaultExpanded: true,
                    accentColor: .cyan
                ) {
                    SettingsToggleRow(
                        icon: "power",
                        title: "setting.enable_fan_control",
                        subtitle: "setting.enable_fan_control.subtitle",
                        isOn: $prefs.preferences.enableFanControl
                    )

                    SettingsToggleRow(
                        icon: "menubar.rectangle",
                        title: "setting.show_fan_in_menu_bar",
                        subtitle: "setting.show_fan_in_menu_bar.subtitle",
                        isOn: $prefs.preferences.fanControlShowInMenuBar
                    )

                    SettingsSliderRow(
                        label: "setting.update_interval",
                        value: $prefs.preferences.fanControlUpdateInterval,
                        range: 0.5...10,
                        step: 0.5,
                        suffix: "s"
                    )
                }

                StatefulCollapsibleSection(
                    title: "section.temperature",
                    icon: "thermometer",
                    defaultExpanded: true,
                    accentColor: .orange
                ) {
                    SettingsPickerRow(
                        label: "setting.temperature_unit",
                        selection: $prefs.preferences.fanControlTemperatureUnit,
                        options: TemperatureUnit.allCases,
                        displayName: \.displayName,
                        style: .segmented
                    )
                }

                StatefulCollapsibleSection(
                    title: "section.notifications",
                    icon: "bell.badge",
                    defaultExpanded: false,
                    accentColor: .red
                ) {
                    SettingsToggleRow(
                        icon: "bell.badge.fill",
                        title: "setting.enable_temp_alerts",
                        subtitle: "setting.enable_temp_alerts.subtitle",
                        isOn: $prefs.preferences.fanControlEnableNotifications
                    )

                    if prefs.preferences.fanControlEnableNotifications {
                        SettingsSliderRow(
                            label: "setting.alert_threshold",
                            value: $prefs.preferences.fanControlNotificationThreshold,
                            range: 60...105,
                            step: 1,
                            suffix: "°C"
                        )
                        .transition(.opacity)
                    }

                    Text("setting.temp_alert_limit")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.horizontal, 10)
                }

                StatefulCollapsibleSection(
                    title: "section.fan_mode",
                    icon: "fanblades.fill",
                    defaultExpanded: true,
                    accentColor: .green
                ) {
                    SettingsPickerRow(
                        label: "setting.default_fan_mode",
                        selection: $prefs.preferences.fanControlMode,
                        options: FanControlMode.allCases,
                        displayName: \.displayName,
                        style: .segmented
                    )
                }

                StatefulCollapsibleSection(
                    title: "section.auto_max_rules",
                    icon: "bolt.fill",
                    defaultExpanded: false,
                    accentColor: .yellow
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("section.auto_max_rules.caption")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.horizontal, 10)

                        ForEach($prefs.preferences.fanControlAutoMaxRules) { $rule in
                            AutoMaxRuleRow(rule: $rule)
                        }

                        SettingsSliderRow(
                            label: "setting.gradual_time",
                            value: $prefs.preferences.fanControlGradualTime,
                            range: 1...120,
                            step: 1,
                            suffix: "s"
                        )
                        .padding(.horizontal, 8)

                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                            prefs.preferences.fanControlAutoMaxRules.append(AutoMaxRule())
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 10))
                                Text("button.add_rule")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                            }
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }

                StatefulCollapsibleSection(
                    title: "System",
                    icon: "desktopcomputer",
                    defaultExpanded: false,
                    accentColor: .purple
                ) {
                    SettingsToggleRow(
                        icon: "moon.fill",
                        title: "setting.disable_on_sleep",
                        subtitle: "setting.disable_on_sleep.subtitle",
                        isOn: $prefs.preferences.fanControlDisableOnSleep
                    )

                    Text("setting.disable_on_sleep.note")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.horizontal, 10)
                }

                StatefulCollapsibleSection(
                    title: "About",
                    icon: "info.circle",
                    defaultExpanded: false,
                    accentColor: .gray
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("fan.about.smc")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))

                        Text("fan.about.elevated")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))

                        Text("fan.about.restricted")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Auto Max Rule Row

struct AutoMaxRuleRow: View {
    @Binding var rule: AutoMaxRule
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var availableSensors: [TemperatureSensor] = []

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        HStack(spacing: 8) {
            Toggle("", isOn: $rule.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Picker("", selection: $rule.fanTarget) {
                        ForEach(FanRuleTarget.allCases) { target in
                            Text(target.displayName).tag(target)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 100)

                    Text("rule.to")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))

                    Picker("", selection: $rule.targetMode) {
                        ForEach(RuleTargetMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 70)

                    if rule.targetMode == .percentage {
                        Text("\(Int(rule.targetPercentage))%")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                            .frame(width: 32)

                        Slider(value: $rule.targetPercentage, in: 0...100, step: 5)
                            .frame(width: 60)
                    } else {
                        TextField("", value: $rule.targetRPM, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 55)

                        Text("unit.rpm")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                HStack(spacing: 4) {
                    Text("rule.when")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))

                    Picker("", selection: $rule.sensor) {
                        ForEach(RuleSensor.allCases) { sensor in
                            Text(sensor.displayName).tag(sensor)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 90)

                    // Specific sensor override (only shown when sensors are available)
                    if !availableSensors.isEmpty {
                        Picker("", selection: $rule.specificSensorKey) {
                            Text("rule.any_matched").tag(nil as String?)
                            ForEach(availableSensors) { sensor in
                                Text(sensor.name).tag(sensor.key as String?)
                            }
                            // Preserve a rule that references a sensor not currently discovered.
                            if let key = rule.specificSensorKey,
                               !availableSensors.contains(where: { $0.key == key }) {
                                Text(String(format: String(localized: "rule.sensor_missing"), key)).tag(key as String?)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(width: 110)
                    }

                    Picker("", selection: $rule.comparison) {
                        ForEach(RuleComparison.allCases) { comp in
                            Text(comp.displayName).tag(comp)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 60)

                    TextField("", value: $rule.threshold, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 40, maxWidth: 60)

                    Text("°C")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }

                HStack(spacing: 4) {
                    Text("rule.hysteresis")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.3))

                    TextField("", value: $rule.hysteresis, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 32, maxWidth: 50)

                    Text("°C")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.3))

                    Text("rule.hold")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.leading, 6)

                    TextField("", value: $rule.durationSeconds, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 32, maxWidth: 50)

                    Text("s")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            Spacer()

            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                HapticManager.shared.generic()
                if let index = prefs.preferences.fanControlAutoMaxRules.firstIndex(where: { $0.id == rule.id }) {
                    prefs.preferences.fanControlAutoMaxRules.remove(at: index)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.02))
        .overlay(
            RoundedRectangle(cornerRadius: 6 * zoomScale)
                .stroke(Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
                .allowsHitTesting(false)
        )
        .onAppear {
            Task.detached(priority: .userInitiated) {
                let sensors = SMCService.shared.readTemperatures().filter { !$0.isEstimated }
                await MainActor.run {
                    availableSensors = sensors
                }
            }
        }
    }
}

#Preview {
    FanControlSettingsView()
        .frame(width: 520, height: 600)
        .background(Color.black)
}
