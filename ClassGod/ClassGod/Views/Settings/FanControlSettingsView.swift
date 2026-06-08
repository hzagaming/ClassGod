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
                    title: "General",
                    icon: "fanblades",
                    defaultExpanded: true,
                    accentColor: .cyan
                ) {
                    SettingsToggleRow(
                        icon: "power",
                        title: "Enable Fan Control",
                        subtitle: "Monitor temperatures and control fans",
                        isOn: $prefs.preferences.enableFanControl
                    )

                    SettingsToggleRow(
                        icon: "menubar.rectangle",
                        title: "Show in Menu Bar",
                        subtitle: "Display highest temp and fan RPM in status bar",
                        isOn: $prefs.preferences.fanControlShowInMenuBar
                    )

                    SettingsSliderRow(
                        label: "Update Interval",
                        value: $prefs.preferences.fanControlUpdateInterval,
                        range: 1...10,
                        step: 1,
                        suffix: "s"
                    )
                }

                StatefulCollapsibleSection(
                    title: "Temperature",
                    icon: "thermometer",
                    defaultExpanded: true,
                    accentColor: .orange
                ) {
                    SettingsPickerRow(
                        label: "Temperature Unit",
                        selection: $prefs.preferences.fanControlTemperatureUnit,
                        options: TemperatureUnit.allCases,
                        displayName: \.displayName,
                        style: .segmented
                    )
                }

                StatefulCollapsibleSection(
                    title: "Notifications",
                    icon: "bell.badge",
                    defaultExpanded: false,
                    accentColor: .red
                ) {
                    SettingsToggleRow(
                        icon: "bell.badge.fill",
                        title: "Enable Temperature Alerts",
                        subtitle: "Show system notification when overheating",
                        isOn: $prefs.preferences.fanControlEnableNotifications
                    )

                    if prefs.preferences.fanControlEnableNotifications {
                        SettingsSliderRow(
                            label: "Alert Threshold",
                            value: $prefs.preferences.fanControlNotificationThreshold,
                            range: 60...105,
                            step: 1,
                            suffix: "°C"
                        )
                        .transition(.opacity)
                    }

                    Text("Limit: notifications will not be duplicated for at least 10 minutes.")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.horizontal, 10)
                }

                StatefulCollapsibleSection(
                    title: "Fan Mode",
                    icon: "fanblades.fill",
                    defaultExpanded: true,
                    accentColor: .green
                ) {
                    SettingsPickerRow(
                        label: "Default Mode",
                        selection: $prefs.preferences.fanControlMode,
                        options: FanControlMode.allCases,
                        displayName: \.displayName,
                        style: .segmented
                    )
                }

                StatefulCollapsibleSection(
                    title: "Auto Max Rules",
                    icon: "bolt.fill",
                    defaultExpanded: false,
                    accentColor: .yellow
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Define rules to automatically adjust fan speeds based on temperature.")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.horizontal, 10)

                        ForEach($prefs.preferences.fanControlAutoMaxRules) { $rule in
                            AutoMaxRuleRow(rule: $rule)
                        }

                        SettingsSliderRow(
                            label: "Gradual Time",
                            value: $prefs.preferences.fanControlGradualTime,
                            range: 1...120,
                            step: 1,
                            suffix: "s"
                        )
                        .padding(.horizontal, 8)

                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            prefs.preferences.fanControlAutoMaxRules.append(AutoMaxRule())
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 10))
                                Text("Add Rule")
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
                        title: "Disable on Sleep",
                        subtitle: "Return fans to System control when Mac sleeps",
                        isOn: $prefs.preferences.fanControlDisableOnSleep
                    )

                    Text("Note: On newer Macs, fans will always turn off soon after sleep.")
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
                        Text("Fan Control reads hardware sensors via the System Management Controller (SMC).")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))

                        Text("On some Macs, especially Apple Silicon models, direct fan control may require elevated privileges and may not be available.")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))

                        Text("If sensors show N/A, SMC access may be restricted on your device.")
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

                    Text("to")
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

                        Text("RPM")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                HStack(spacing: 4) {
                    Text("when")
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
                            Text("Any matched").tag(nil as String?)
                            ForEach(availableSensors) { sensor in
                                Text(sensor.name).tag(sensor.key as String?)
                            }
                            // Preserve a rule that references a sensor not currently discovered.
                            if let key = rule.specificSensorKey,
                               !availableSensors.contains(where: { $0.key == key }) {
                                Text("\(key) (missing)").tag(key as String?)
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
                    Text("hyst")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.3))

                    TextField("", value: $rule.hysteresis, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 32, maxWidth: 50)

                    Text("°C")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.3))

                    Text("hold")
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
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                .allowsHitTesting(false)
        )
        .onAppear {
            availableSensors = SMCService.shared.readTemperatures().filter { !$0.isEstimated }
        }
    }
}

#Preview {
    FanControlSettingsView()
        .frame(width: 520, height: 600)
        .background(Color.black)
}
