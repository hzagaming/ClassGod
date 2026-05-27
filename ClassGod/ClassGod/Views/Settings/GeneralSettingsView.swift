//
//  GeneralSettingsView.swift
//  ClassGod
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                StatefulCollapsibleSection(
                    title: String(localized: "section.behavior"),
                    icon: "switch.2",
                    defaultExpanded: true,
                    accentColor: .cyan
                ) {
                    Toggle(String(localized: "setting.auto_detect"), isOn: $prefs.preferences.autoDetectOnShow)
                    Toggle(String(localized: "setting.keyboard_nav"), isOn: $prefs.preferences.enableKeyboardNavigation)
                    Toggle("Monitor Clipboard for URLs", isOn: $prefs.preferences.enableClipboardMonitoring)

                    sliderRow(
                        label: String(localized: "setting.switch_delay"),
                        value: $prefs.preferences.switchDelayMs,
                        range: 0...500,
                        step: 50,
                        format: "%.0fms"
                    )

                    Picker(String(localized: "setting.switch_behavior"), selection: $prefs.preferences.switchBehavior) {
                        ForEach(SwitchBehavior.allCases) { behavior in
                            Text(behavior.displayName).tag(behavior)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    Picker(String(localized: "setting.url_match"), selection: $prefs.preferences.urlMatchPrecision) {
                        ForEach(URLMatchPrecision.allCases) { precision in
                            Text(precision.displayName).tag(precision)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.window_behavior"),
                    icon: "macwindow",
                    defaultExpanded: true,
                    accentColor: .orange
                ) {
                    Toggle("Close on Click Outside", isOn: $prefs.preferences.closeOnClickOutside)
                    Toggle("Keep Window on Top", isOn: $prefs.preferences.keepWindowOnTop)
                    Toggle("Remember Window Position", isOn: $prefs.preferences.rememberWindowPosition)

                    Picker("Maximize Behavior", selection: $prefs.preferences.windowMaximizeBehavior) {
                        ForEach(WindowMaximizeBehavior.allCases) { behavior in
                            Text(behavior.displayName).tag(behavior)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    sliderRow(
                        label: "Minimize Animation",
                        value: $prefs.preferences.minimizeAnimationDuration,
                        range: 0.05...0.5,
                        step: 0.05,
                        format: "%.2fs"
                    )
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.toast"),
                    icon: "bell",
                    defaultExpanded: false,
                    accentColor: .yellow
                ) {
                    Toggle(String(localized: "setting.toast"), isOn: $prefs.preferences.showToastNotifications)

                    if prefs.preferences.showToastNotifications {
                        sliderRow(
                            label: String(localized: "setting.toast_duration"),
                            value: $prefs.preferences.toastDuration,
                            range: 0.5...5.0,
                            step: 0.5,
                            format: "%.1fs"
                        )
                        .transition(.opacity)
                    }
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.animation"),
                    icon: "sparkles",
                    defaultExpanded: false,
                    accentColor: .purple
                ) {
                    Toggle(String(localized: "setting.instant_mode"), isOn: $prefs.preferences.useInstantAnimations)

                    Picker(String(localized: "setting.animation_speed"), selection: $prefs.preferences.animationSpeed) {
                        ForEach(AnimationSpeed.allCases) { speed in
                            Text(speed.displayName).tag(speed)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(prefs.preferences.useInstantAnimations)

                    Text(String(localized: "animation.off_caption"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.launch"),
                    icon: "power",
                    defaultExpanded: false,
                    accentColor: .green
                ) {
                    Toggle(String(localized: "setting.launch_at_login"), isOn: $prefs.preferences.launchAtLogin)
                        .disabled(true)
                        .help(String(localized: "launch.coming_soon"))

                    Toggle(String(localized: "setting.show_on_launch"), isOn: $prefs.preferences.showPopoverOnLaunch)

                    HStack {
                        Text("Auto-Save Interval")
                        Slider(value: .init(
                            get: { Double(prefs.preferences.autoSaveIntervalMinutes) },
                            set: { prefs.preferences.autoSaveIntervalMinutes = Int($0) }
                        ), in: 1...60, step: 1)
                        Text("\(prefs.preferences.autoSaveIntervalMinutes)m")
                            .frame(width: 36, alignment: .trailing)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.safety"),
                    icon: "shield",
                    defaultExpanded: false,
                    accentColor: .red
                ) {
                    Toggle(String(localized: "setting.confirm_delete"), isOn: $prefs.preferences.confirmBeforeDelete)
                    Toggle(String(localized: "setting.confirm_clear"), isOn: $prefs.preferences.confirmBeforeClear)
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.feedback"),
                    icon: "speaker.wave.2",
                    defaultExpanded: false,
                    accentColor: .pink
                ) {
                    Toggle(String(localized: "setting.sound_effects"), isOn: $prefs.preferences.enableSoundEffects)
                    Toggle(String(localized: "setting.haptic"), isOn: $prefs.preferences.enableHapticFeedback)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }

    private func sliderRow(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String
    ) -> some View {
        HStack {
            Text(label)
            Slider(value: value, in: range, step: step)
            Text(String(format: format, value.wrappedValue))
                .frame(width: 50, alignment: .trailing)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

#Preview {
    GeneralSettingsView()
        .frame(width: 480, height: 600)
        .background(Color.black)
}
