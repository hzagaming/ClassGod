//
//  AppearanceSettingsView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared
    
    var body: some View {
        Form {
            Section("Menu Bar Icon") {
                Picker("Icon style", selection: $prefs.preferences.menuBarIconStyle) {
                    ForEach(MenuBarIconStyle.allCases) { style in
                        HStack(spacing: 8) {
                            Image(systemName: style.systemImageName)
                                .symbolRenderingMode(.hierarchical)
                            Text(style.displayName)
                        }
                        .tag(style)
                    }
                }
                .pickerStyle(.radioGroup)
            }
            
            Section("Panel") {
                HStack {
                    Text("Width:")
                    Slider(value: $prefs.preferences.panelWidth, in: 240...480, step: 10)
                    Text("\(Int(prefs.preferences.panelWidth))")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                
                HStack {
                    Text("Max height:")
                    Slider(value: $prefs.preferences.panelMaxHeight, in: 200...800, step: 20)
                    Text("\(Int(prefs.preferences.panelMaxHeight))")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                
                HStack {
                    Text("Row height:")
                    Slider(value: $prefs.preferences.rowHeight, in: 32...64, step: 4)
                    Text("\(Int(prefs.preferences.rowHeight))")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                
                HStack {
                    Text("Max tabs shown:")
                    Slider(value: .init(
                        get: { Double(prefs.preferences.maxTabsInPopover) },
                        set: { prefs.preferences.maxTabsInPopover = Int($0) }
                    ), in: 5...100, step: 5)
                    Text("\(prefs.preferences.maxTabsInPopover)")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            
            Section("Theme") {
                Picker("Appearance", selection: $prefs.preferences.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("Display Options") {
                Toggle("Show browser icons", isOn: $prefs.preferences.showBrowserIcon)
                Toggle("Show shortcut badges", isOn: $prefs.preferences.showShortcutBadge)
                Toggle("Show URL preview", isOn: $prefs.preferences.showURLPreview)
                Toggle("Compact mode", isOn: $prefs.preferences.useCompactMode)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    AppearanceSettingsView()
}
