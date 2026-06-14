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
                    title: "section.behavior",
                    icon: "switch.2",
                    defaultExpanded: true,
                    accentColor: .cyan
                ) {
                    SettingsToggleRow(
                        icon: "eye",
                        title: "setting.auto_detect",
                        subtitle: "setting.auto_detect.subtitle",
                        isOn: $prefs.preferences.autoDetectOnShow
                    )

                    SettingsToggleRow(
                        icon: "keyboard",
                        title: "setting.keyboard_nav",
                        subtitle: "setting.keyboard_nav.subtitle",
                        isOn: $prefs.preferences.enableKeyboardNavigation
                    )

                    SettingsSliderRow(
                        label: "setting.switch_delay",
                        value: $prefs.preferences.switchDelayMs,
                        range: 0...500,
                        step: 50,
                        suffix: "ms"
                    )

                    SettingsPickerRow(
                        label: "setting.switch_behavior",
                        selection: $prefs.preferences.switchBehavior,
                        options: SwitchBehavior.allCases,
                        displayName: \.displayName,
                        style: .radio
                    )

                    SettingsPickerRow(
                        label: "setting.url_match",
                        selection: $prefs.preferences.urlMatchPrecision,
                        options: URLMatchPrecision.allCases,
                        displayName: \.displayName,
                        style: .segmented
                    )
                }

                StatefulCollapsibleSection(
                    title: "section.window_behavior",
                    icon: "macwindow",
                    defaultExpanded: true,
                    accentColor: .orange
                ) {
                    SettingsToggleRow(
                        icon: "xmark.circle",
                        title: "setting.close_on_click_outside",
                        subtitle: "setting.close_on_click_outside.subtitle",
                        isOn: $prefs.preferences.closeOnClickOutside
                    )

                    SettingsToggleRow(
                        icon: "pin",
                        title: "setting.keep_on_top",
                        subtitle: "setting.keep_on_top.subtitle",
                        isOn: $prefs.preferences.keepWindowOnTop
                    )

                    SettingsToggleRow(
                        icon: "location",
                        title: "setting.remember_position",
                        subtitle: "setting.remember_position.subtitle",
                        isOn: $prefs.preferences.rememberWindowPosition
                    )

                    SettingsPickerRow(
                        label: "setting.maximize_behavior",
                        selection: $prefs.preferences.windowMaximizeBehavior,
                        options: WindowMaximizeBehavior.allCases,
                        displayName: \.displayName,
                        style: .menu
                    )

                    SettingsToggleRow(
                        icon: "window.awning",
                        title: "setting.popover_animation",
                        subtitle: "setting.popover_animation.subtitle",
                        isOn: $prefs.preferences.showPopoverAnimation
                    )

                    SettingsSliderRow(
                        label: "setting.minimize_animation",
                        value: $prefs.preferences.minimizeAnimationDuration,
                        range: 0.05...0.5,
                        step: 0.05,
                        format: "%.2fs"
                    )
                }

                StatefulCollapsibleSection(
                    title: "section.toast",
                    icon: "bell",
                    defaultExpanded: false,
                    accentColor: .yellow
                ) {
                    SettingsToggleRow(
                        icon: "bell.badge",
                        title: "setting.toast",
                        subtitle: "setting.toast.subtitle",
                        isOn: $prefs.preferences.showToastNotifications
                    )

                    if prefs.preferences.showToastNotifications {
                        SettingsSliderRow(
                            label: "setting.toast_duration",
                            value: $prefs.preferences.toastDuration,
                            range: 0.5...5.0,
                            step: 0.5,
                            format: "%.1fs"
                        )
                        .transition(.opacity)
                    }
                }

                StatefulCollapsibleSection(
                    title: "section.animation",
                    icon: "sparkles",
                    defaultExpanded: false,
                    accentColor: .purple
                ) {
                    SettingsToggleRow(
                        icon: "bolt",
                        title: "setting.instant_mode",
                        subtitle: "setting.instant_mode.subtitle",
                        isOn: $prefs.preferences.useInstantAnimations
                    )

                    SettingsPickerRow(
                        label: "setting.animation_speed",
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
                    title: "section.launch",
                    icon: "power",
                    defaultExpanded: false,
                    accentColor: .green
                ) {
                    SettingsToggleRow(
                        icon: "arrow.up.circle",
                        title: "setting.launch_at_login",
                        subtitle: "launch.coming_soon",
                        isOn: $prefs.preferences.launchAtLogin
                    )
                    .disabled(true)

                    SettingsToggleRow(
                        icon: "rectangle.portrait.arrowtriangle.2.outward",
                        title: "setting.show_on_launch",
                        subtitle: "setting.show_on_launch.subtitle",
                        isOn: $prefs.preferences.showPopoverOnLaunch
                    )
                }

                StatefulCollapsibleSection(
                    title: "section.safety",
                    icon: "shield",
                    defaultExpanded: false,
                    accentColor: .red
                ) {
                    SettingsToggleRow(
                        icon: "exclamationmark.triangle",
                        title: "setting.confirm_delete",
                        subtitle: "setting.confirm_delete.subtitle",
                        isOn: $prefs.preferences.confirmBeforeDelete
                    )

                    SettingsToggleRow(
                        icon: "trash",
                        title: "setting.confirm_clear",
                        subtitle: "setting.confirm_clear.subtitle",
                        isOn: $prefs.preferences.confirmBeforeClear
                    )
                }

                StatefulCollapsibleSection(
                    title: "section.feedback",
                    icon: "speaker.wave.2",
                    defaultExpanded: false,
                    accentColor: .pink
                ) {
                    SettingsToggleRow(
                        icon: "speaker.wave.2.fill",
                        title: "setting.sound_effects",
                        subtitle: "setting.sound_effects.subtitle",
                        isOn: $prefs.preferences.enableSoundEffects
                    )

                    SettingsToggleRow(
                        icon: "hand.tap",
                        title: "setting.haptic",
                        subtitle: "setting.haptic.subtitle",
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
