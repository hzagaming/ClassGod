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
                    SettingsToggleRow(
                        icon: "eye",
                        title: String(localized: "setting.auto_detect"),
                        subtitle: "Detect current tab when window opens",
                        isOn: $prefs.preferences.autoDetectOnShow
                    )

                    SettingsToggleRow(
                        icon: "keyboard",
                        title: String(localized: "setting.keyboard_nav"),
                        subtitle: "Navigate lists with arrow keys",
                        isOn: $prefs.preferences.enableKeyboardNavigation
                    )

                    SettingsSliderRow(
                        label: String(localized: "setting.switch_delay"),
                        value: $prefs.preferences.switchDelayMs,
                        range: 0...500,
                        step: 50,
                        suffix: "ms"
                    )

                    SettingsPickerRow(
                        label: String(localized: "setting.switch_behavior"),
                        selection: $prefs.preferences.switchBehavior,
                        options: SwitchBehavior.allCases,
                        displayName: \.displayName,
                        style: .radio
                    )

                    SettingsPickerRow(
                        label: String(localized: "setting.url_match"),
                        selection: $prefs.preferences.urlMatchPrecision,
                        options: URLMatchPrecision.allCases,
                        displayName: \.displayName,
                        style: .segmented
                    )
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.window_behavior"),
                    icon: "macwindow",
                    defaultExpanded: true,
                    accentColor: .orange
                ) {
                    SettingsToggleRow(
                        icon: "xmark.circle",
                        title: "Close on Click Outside",
                        subtitle: "Hide window when clicking outside",
                        isOn: $prefs.preferences.closeOnClickOutside
                    )

                    SettingsToggleRow(
                        icon: "pin",
                        title: "Keep Window on Top",
                        subtitle: "Window stays above other apps",
                        isOn: $prefs.preferences.keepWindowOnTop
                    )

                    SettingsToggleRow(
                        icon: "location",
                        title: "Remember Window Position",
                        subtitle: "Restore last window location",
                        isOn: $prefs.preferences.rememberWindowPosition
                    )

                    SettingsPickerRow(
                        label: "Maximize Behavior",
                        selection: $prefs.preferences.windowMaximizeBehavior,
                        options: WindowMaximizeBehavior.allCases,
                        displayName: \.displayName,
                        style: .menu
                    )

                    SettingsToggleRow(
                        icon: "window.awning",
                        title: "Popover Animation",
                        subtitle: "Animate window open and close",
                        isOn: $prefs.preferences.showPopoverAnimation
                    )

                    SettingsSliderRow(
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
                    SettingsToggleRow(
                        icon: "bell.badge",
                        title: String(localized: "setting.toast"),
                        subtitle: "Show feedback notifications",
                        isOn: $prefs.preferences.showToastNotifications
                    )

                    if prefs.preferences.showToastNotifications {
                        SettingsSliderRow(
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
                    SettingsToggleRow(
                        icon: "bolt",
                        title: String(localized: "setting.instant_mode"),
                        subtitle: "Disable all animations",
                        isOn: $prefs.preferences.useInstantAnimations
                    )

                    SettingsPickerRow(
                        label: String(localized: "setting.animation_speed"),
                        selection: $prefs.preferences.animationSpeed,
                        options: AnimationSpeed.allCases,
                        displayName: \.displayName,
                        style: .segmented
                    )
                    .disabled(prefs.preferences.useInstantAnimations)

                    Text(String(localized: "animation.off_caption"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.launch"),
                    icon: "power",
                    defaultExpanded: false,
                    accentColor: .green
                ) {
                    SettingsToggleRow(
                        icon: "arrow.up.circle",
                        title: String(localized: "setting.launch_at_login"),
                        subtitle: String(localized: "launch.coming_soon"),
                        isOn: $prefs.preferences.launchAtLogin
                    )
                    .disabled(true)

                    SettingsToggleRow(
                        icon: "rectangle.portrait.arrowtriangle.2.outward",
                        title: String(localized: "setting.show_on_launch"),
                        subtitle: "Open panel when app starts",
                        isOn: $prefs.preferences.showPopoverOnLaunch
                    )
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.safety"),
                    icon: "shield",
                    defaultExpanded: false,
                    accentColor: .red
                ) {
                    SettingsToggleRow(
                        icon: "exclamationmark.triangle",
                        title: String(localized: "setting.confirm_delete"),
                        subtitle: "Ask before deleting items",
                        isOn: $prefs.preferences.confirmBeforeDelete
                    )

                    SettingsToggleRow(
                        icon: "trash",
                        title: String(localized: "setting.confirm_clear"),
                        subtitle: "Ask before clearing all data",
                        isOn: $prefs.preferences.confirmBeforeClear
                    )
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.feedback"),
                    icon: "speaker.wave.2",
                    defaultExpanded: false,
                    accentColor: .pink
                ) {
                    SettingsToggleRow(
                        icon: "speaker.wave.2.fill",
                        title: String(localized: "setting.sound_effects"),
                        subtitle: "Play sounds on interactions",
                        isOn: $prefs.preferences.enableSoundEffects
                    )

                    SettingsToggleRow(
                        icon: "hand.tap",
                        title: String(localized: "setting.haptic"),
                        subtitle: "Haptic feedback on actions",
                        isOn: $prefs.preferences.enableHapticFeedback
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    GeneralSettingsView()
        .frame(width: 480, height: 600)
        .background(Color.black)
}
