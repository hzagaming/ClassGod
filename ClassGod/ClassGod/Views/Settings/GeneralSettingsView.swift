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
            Section("Behavior") {
                Picker("Tab Switching", selection: $prefs.preferences.switchBehavior) {
                    ForEach(SwitchBehavior.allCases) { behavior in
                        Text(behavior.displayName).tag(behavior)
                    }
                }
                .pickerStyle(.radioGroup)
                
                Picker("URL Matching", selection: $prefs.preferences.urlMatchPrecision) {
                    ForEach(URLMatchPrecision.allCases) { precision in
                        Text(precision.displayName).tag(precision)
                    }
                }
                .pickerStyle(.radioGroup)
                
                Toggle("Show toast notifications", isOn: $prefs.preferences.showToastNotifications)
                
                if prefs.preferences.showToastNotifications {
                    HStack {
                        Text("Toast duration:")
                        Slider(value: $prefs.preferences.toastDuration, in: 0.5...5.0, step: 0.5)
                        Text(String(format: "%.1fs", prefs.preferences.toastDuration))
                            .frame(width: 40, alignment: .trailing)
                            .foregroundStyle(.secondary)
                    }
                    .transition(.opacity)
                }
            }
            
            Section("Animation") {
                Picker("Animation speed", selection: $prefs.preferences.animationSpeed) {
                    ForEach(AnimationSpeed.allCases) { speed in
                        Text(speed.displayName).tag(speed)
                    }
                }
                .pickerStyle(.segmented)
                
                Text("\"Off\" disables all animations for maximum responsiveness.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Startup") {
                Toggle("Launch at login", isOn: $prefs.preferences.launchAtLogin)
                    .disabled(true)
                    .help("Coming in a future update")
                
                Toggle("Show popover on launch", isOn: $prefs.preferences.showPopoverOnLaunch)
            }
            
            Section("Safety") {
                Toggle("Confirm before deleting a tab", isOn: $prefs.preferences.confirmBeforeDelete)
                Toggle("Confirm before clearing all tabs", isOn: $prefs.preferences.confirmBeforeClear)
            }
            
            Section("Feedback") {
                Toggle("Enable sound effects", isOn: $prefs.preferences.enableSoundEffects)
                Toggle("Enable haptic feedback", isOn: $prefs.preferences.enableHapticFeedback)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    GeneralSettingsView()
}
