//
//  AppearanceSettingsView.swift
//  ClassGod
//

import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                StatefulCollapsibleSection(
                    title: String(localized: "section.panel"),
                    icon: "rectangle.split.3x3",
                    defaultExpanded: true,
                    accentColor: .blue
                ) {
                    sliderRow(label: String(localized: "setting.width"), value: $prefs.preferences.panelWidth, range: 240...600, step: 10, suffix: "px")
                    sliderRow(label: String(localized: "setting.max_height"), value: $prefs.preferences.panelMaxHeight, range: 200...900, step: 20, suffix: "px")
                    sliderRow(label: String(localized: "setting.row_height"), value: $prefs.preferences.rowHeight, range: 32...72, step: 4, suffix: "px")

                    HStack {
                        Text(String(localized: "setting.max_tabs"))
                        Slider(value: .init(
                            get: { Double(prefs.preferences.maxTabsInPopover) },
                            set: { prefs.preferences.maxTabsInPopover = Int($0) }
                        ), in: 5...150, step: 5)
                        Text("\(prefs.preferences.maxTabsInPopover)")
                            .frame(width: 40, alignment: .trailing)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    sliderRow(label: String(localized: "setting.corner_radius"), value: $prefs.preferences.panelCornerRadius, range: 0...32, step: 1, suffix: "px")
                    sliderRow(label: "Border Width", value: $prefs.preferences.borderWidth, range: 0...3, step: 0.5, format: "%.1f")
                    sliderRow(label: "Font Scale", value: $prefs.preferences.fontSizeScale, range: 0.8...1.4, step: 0.05, format: "%.2f×")
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.theme"),
                    icon: "paintbrush",
                    defaultExpanded: true,
                    accentColor: .purple
                ) {
                    Picker(String(localized: "setting.appearance"), selection: $prefs.preferences.theme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)

                    sliderRow(label: "Window Opacity", value: $prefs.preferences.windowOpacity, range: 0.5...1.0, step: 0.05, format: "%.0f%%") {
                        Int($0 * 100)
                    }

                    Toggle("Blur Background", isOn: $prefs.preferences.enableBlurBackground)
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.display"),
                    icon: "eye",
                    defaultExpanded: true,
                    accentColor: .cyan
                ) {
                    Toggle(String(localized: "setting.show_browser_icon"), isOn: $prefs.preferences.showBrowserIcon)
                    Toggle(String(localized: "setting.show_shortcut_badge"), isOn: $prefs.preferences.showShortcutBadge)
                    Toggle(String(localized: "setting.show_url_preview"), isOn: $prefs.preferences.showURLPreview)
                    Toggle(String(localized: "setting.compact_mode"), isOn: $prefs.preferences.useCompactMode)
                    Toggle(String(localized: "setting.show_tab_count"), isOn: $prefs.preferences.showTabCountBadge)

                    Picker("List Divider", selection: $prefs.preferences.listDividerStyle) {
                        ForEach(ListDividerStyle.allCases) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.menu_bar_icon"),
                    icon: "menubar.rectangle",
                    defaultExpanded: false,
                    accentColor: .green
                ) {
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

                StatefulCollapsibleSection(
                    title: "Stealth",
                    icon: "eye.slash",
                    defaultExpanded: false,
                    accentColor: .red
                ) {
                    Picker("App Icon", selection: $prefs.preferences.appIconStyle) {
                        ForEach(AppIconStyle.allCases) { style in
                            HStack(spacing: 8) {
                                Image(systemName: style.iconName)
                                    .symbolRenderingMode(.hierarchical)
                                Text(style.displayName)
                            }
                            .tag(style)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .onChange(of: prefs.preferences.appIconStyle) { _, newStyle in
                        AppIconManager.shared.applyStyle(newStyle)
                    }

                    Text("Disguise ClassGod as another app in the Dock. The icon change takes effect immediately.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
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
        suffix: String
    ) -> some View {
        HStack {
            Text(label)
            Slider(value: value, in: range, step: step)
            Text("\(Int(value.wrappedValue))\(suffix)")
                .frame(width: 50, alignment: .trailing)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func sliderRow(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String,
        transform: (Double) -> Int
    ) -> some View {
        HStack {
            Text(label)
            Slider(value: value, in: range, step: step)
            Text("\(transform(value.wrappedValue))")
                .frame(width: 50, alignment: .trailing)
                .foregroundStyle(.secondary)
                .monospacedDigit()
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
    AppearanceSettingsView()
        .frame(width: 480, height: 600)
        .background(Color.black)
}
