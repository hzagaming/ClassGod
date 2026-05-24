//
//  GeneralSettingsView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared
    
    var body: some View {
        Form {
            Section(String(localized: "section.behavior")) {
                Toggle(String(localized: "setting.auto_detect"), isOn: $prefs.preferences.autoDetectOnShow)
                
                Toggle(String(localized: "setting.keyboard_nav"), isOn: $prefs.preferences.enableKeyboardNavigation)
                
                HStack {
                    Text(String(localized: "setting.switch_delay"))
                    Slider(value: $prefs.preferences.switchDelayMs, in: 0...500, step: 50)
                    Text("\(Int(prefs.preferences.switchDelayMs))ms")
                        .frame(width: 50, alignment: .trailing)
                        .foregroundStyle(.secondary)
                }
                
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
                
                Toggle(String(localized: "setting.toast"), isOn: $prefs.preferences.showToastNotifications)
                
                if prefs.preferences.showToastNotifications {
                    HStack {
                        Text(String(localized: "setting.toast_duration"))
                        Slider(value: $prefs.preferences.toastDuration, in: 0.5...5.0, step: 0.5)
                        Text(String(format: "%.1fs", prefs.preferences.toastDuration))
                            .frame(width: 40, alignment: .trailing)
                            .foregroundStyle(.secondary)
                    }
                    .transition(.opacity)
                }
            }
            
            Section(String(localized: "section.animation")) {
                Toggle(String(localized: "setting.instant_mode"), isOn: $prefs.preferences.useInstantAnimations)
                
                Picker(String(localized: "setting.animation_speed"), selection: $prefs.preferences.animationSpeed) {
                    ForEach(AnimationSpeed.allCases) { speed in
                        Text(speed.displayName).tag(speed)
                    }
                }
                .pickerStyle(.segmented)
                
                Text(String(localized: "animation.off_caption"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section(String(localized: "section.launch")) {
                Toggle(String(localized: "setting.launch_at_login"), isOn: $prefs.preferences.launchAtLogin)
                    .disabled(true)
                    .help(String(localized: "launch.coming_soon"))
                
                Toggle(String(localized: "setting.show_on_launch"), isOn: $prefs.preferences.showPopoverOnLaunch)
            }
            
            Section(String(localized: "section.safety")) {
                Toggle(String(localized: "setting.confirm_delete"), isOn: $prefs.preferences.confirmBeforeDelete)
                Toggle(String(localized: "setting.confirm_clear"), isOn: $prefs.preferences.confirmBeforeClear)
            }
            
            Section(String(localized: "section.feedback")) {
                Toggle(String(localized: "setting.sound_effects"), isOn: $prefs.preferences.enableSoundEffects)
                Toggle(String(localized: "setting.haptic"), isOn: $prefs.preferences.enableHapticFeedback)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    GeneralSettingsView()
}
