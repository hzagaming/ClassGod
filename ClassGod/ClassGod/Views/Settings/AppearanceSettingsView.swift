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
                    title: "section.panel",
                    icon: "rectangle.split.3x3",
                    defaultExpanded: true,
                    accentColor: .blue
                ) {
                    SettingsSliderRow(
                        label: "setting.width",
                        value: $prefs.preferences.panelWidth,
                        range: 240...600,
                        step: 10,
                        suffix: "px"
                    )

                    SettingsSliderRow(
                        label: "setting.max_height",
                        value: $prefs.preferences.panelMaxHeight,
                        range: 200...900,
                        step: 20,
                        suffix: "px"
                    )

                    SettingsSliderRow(
                        label: "setting.row_height",
                        value: $prefs.preferences.rowHeight,
                        range: 32...72,
                        step: 4,
                        suffix: "px"
                    )

                    SettingsSliderRow(
                        label: "setting.max_tabs",
                        value: .init(
                            get: { Double(prefs.preferences.maxTabsInPopover) },
                            set: { prefs.preferences.maxTabsInPopover = Int($0) }
                        ),
                        range: 5...150,
                        step: 5,
                        suffix: ""
                    )

                    SettingsSliderRow(
                        label: "setting.corner_radius",
                        value: $prefs.preferences.panelCornerRadius,
                        range: 0...32,
                        step: 1,
                        suffix: "px"
                    )

                    SettingsSliderRow(
                        label: "setting.window_zoom",
                        value: $prefs.preferences.windowZoomScale,
                        range: 0.5...2.0,
                        step: 0.1,
                        format: "%.0f%%"
                    ) {
                        Int($0 * 100)
                    }
                    .onChange(of: prefs.preferences.windowZoomScale) { _, _ in
                        (NSApp.delegate as? AppDelegate)?.updateAllWindowSizes()
                    }
                }

                StatefulCollapsibleSection(
                    title: "section.theme",
                    icon: "paintbrush",
                    defaultExpanded: true,
                    accentColor: .purple
                ) {
                    SettingsPickerRow(
                        label: "setting.appearance",
                        selection: $prefs.preferences.theme,
                        options: AppTheme.allCases,
                        displayName: \.displayName,
                        style: .segmented
                    )

                    SettingsSliderRow(
                        label: "setting.window_opacity",
                        value: $prefs.preferences.windowOpacity,
                        range: 0.5...1.0,
                        step: 0.05,
                        format: "%.0f%%"
                    ) {
                        Int($0 * 100)
                    }
                }

                StatefulCollapsibleSection(
                    title: "section.display",
                    icon: "eye",
                    defaultExpanded: true,
                    accentColor: .cyan
                ) {
                    SettingsToggleRow(
                        icon: "globe",
                        title: "setting.show_browser_icon",
                        subtitle: "setting.show_browser_icon.subtitle",
                        isOn: $prefs.preferences.showBrowserIcon
                    )

                    SettingsToggleRow(
                        icon: "command",
                        title: "setting.show_shortcut_badge",
                        subtitle: "setting.show_shortcut_badge.subtitle",
                        isOn: $prefs.preferences.showShortcutBadge
                    )

                    SettingsToggleRow(
                        icon: "link",
                        title: "setting.show_url_preview",
                        subtitle: "setting.show_url_preview.subtitle",
                        isOn: $prefs.preferences.showURLPreview
                    )

                    SettingsToggleRow(
                        icon: "rectangle.compress.vertical",
                        title: "setting.compact_mode",
                        subtitle: "setting.compact_mode.subtitle",
                        isOn: $prefs.preferences.useCompactMode
                    )

                    SettingsToggleRow(
                        icon: "number",
                        title: "setting.show_tab_count",
                        subtitle: "setting.show_tab_count.subtitle",
                        isOn: $prefs.preferences.showTabCountBadge
                    )
                }

                StatefulCollapsibleSection(
                    title: "section.menu_bar_icon",
                    icon: "menubar.rectangle",
                    defaultExpanded: false,
                    accentColor: .green
                ) {
                    SettingsPickerRow(
                        label: "setting.icon_style",
                        selection: $prefs.preferences.menuBarIconStyle,
                        options: MenuBarIconStyle.allCases,
                        displayName: \.displayName,
                        style: .radio
                    )
                }

                StatefulCollapsibleSection(
                    title: "section.stealth",
                    icon: "eye.slash",
                    defaultExpanded: false,
                    accentColor: .red
                ) {
                    SettingsPickerRow(
                        label: "setting.app_icon",
                        selection: $prefs.preferences.appIconStyle,
                        options: AppIconStyle.allCases,
                        displayName: \.displayName,
                        style: .radio
                    )
                    .onChange(of: prefs.preferences.appIconStyle) { _, newStyle in
                        AppIconManager.shared.applyStyle(newStyle)
                    }

                    Text("setting.app_icon.caption")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    AppearanceSettingsView()
        .frame(width: 480, height: 600)
        .background(Color.black)
}
