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
            Section(String(localized: "section.menu_bar_icon")) {
                Picker(String(localized: "setting.icon_style"), selection: $prefs.preferences.menuBarIconStyle) {
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

            Section(String(localized: "section.panel")) {
                HStack {
                    Text(String(localized: "setting.width"))
                    Slider(value: $prefs.preferences.panelWidth, in: 240...480, step: 10)
                    Text("\(Int(prefs.preferences.panelWidth))")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                HStack {
                    Text(String(localized: "setting.max_height"))
                    Slider(value: $prefs.preferences.panelMaxHeight, in: 200...800, step: 20)
                    Text("\(Int(prefs.preferences.panelMaxHeight))")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                HStack {
                    Text(String(localized: "setting.row_height"))
                    Slider(value: $prefs.preferences.rowHeight, in: 32...64, step: 4)
                    Text("\(Int(prefs.preferences.rowHeight))")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                HStack {
                    Text(String(localized: "setting.max_tabs"))
                    Slider(value: .init(
                        get: { Double(prefs.preferences.maxTabsInPopover) },
                        set: { prefs.preferences.maxTabsInPopover = Int($0) }
                    ), in: 5...100, step: 5)
                    Text("\(prefs.preferences.maxTabsInPopover)")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                HStack {
                    Text(String(localized: "setting.corner_radius"))
                    Slider(value: $prefs.preferences.panelCornerRadius, in: 0...24, step: 1)
                    Text("\(Int(prefs.preferences.panelCornerRadius))")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            Section(String(localized: "section.theme")) {
                Picker(String(localized: "setting.appearance"), selection: $prefs.preferences.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(String(localized: "section.display")) {
                Toggle(String(localized: "setting.show_browser_icon"), isOn: $prefs.preferences.showBrowserIcon)
                Toggle(String(localized: "setting.show_shortcut_badge"), isOn: $prefs.preferences.showShortcutBadge)
                Toggle(String(localized: "setting.show_url_preview"), isOn: $prefs.preferences.showURLPreview)
                Toggle(String(localized: "setting.compact_mode"), isOn: $prefs.preferences.useCompactMode)

                Toggle(String(localized: "setting.show_tab_count"), isOn: $prefs.preferences.showTabCountBadge)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    AppearanceSettingsView()
}
