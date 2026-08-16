//
//  AppearanceSettingsView.swift
//  ClassGod
//

import AppKit
import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        ScrollView {
            VStack(spacing: 10 * zoomScale) {
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

                    HStack(spacing: 12 * zoomScale) {
                        VStack(alignment: .leading, spacing: 2 * zoomScale) {
                            Text("setting.accent_color")
                                .font(.system(size: 12 * zoomScale, weight: .medium))
                                .foregroundStyle(.white)
                            Text("setting.accent_color.subtitle")
                                .font(.system(size: 10 * zoomScale))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                        Spacer()
                        ColorPicker(
                            "",
                            selection: accentBinding,
                            supportsOpacity: false
                        )
                        .labelsHidden()
                        .accessibilityLabel(Text("setting.accent_color"))
                    }
                    .padding(.horizontal, 10 * zoomScale)
                    .padding(.vertical, 8 * zoomScale)

                    HStack(spacing: 8 * zoomScale) {
                        ForEach(accentPresets, id: \.self) { accent in
                            Button {
                                prefs.preferences.themeAccent = accent
                                SoundEffectManager.shared.playButtonClick()
                                HapticManager.shared.generic()
                            } label: {
                                Circle()
                                    .fill(accent.color)
                                    .frame(width: 20 * zoomScale, height: 20 * zoomScale)
                                    .overlay(
                                        Circle().stroke(
                                            prefs.preferences.themeAccent == accent ? Color.white : Color.white.opacity(0.18),
                                            lineWidth: (prefs.preferences.themeAccent == accent ? 2 : 1) * zoomScale
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("setting.accent_preset"))
                        }
                        Spacer()
                        Button("button.reset") {
                            prefs.preferences.themeAccent = .default
                            SoundEffectManager.shared.playButtonClick()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10 * zoomScale, weight: .medium, design: .monospaced))
                        .foregroundStyle(prefs.preferences.themeAccent.color)
                    }
                    .padding(.horizontal, 10 * zoomScale)

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
                    accentColor: prefs.preferences.themeAccent.color
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
                        .font(.system(size: 11 * zoomScale, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10 * zoomScale)
                }
            }
            .padding(.horizontal, 8 * zoomScale)
            .padding(.vertical, 8 * zoomScale)
        }
    }

    private var accentBinding: Binding<Color> {
        Binding(
            get: { prefs.preferences.themeAccent.color },
            set: { color in
                guard let converted = NSColor(color).usingColorSpace(.sRGB) else { return }
                prefs.preferences.themeAccent = ThemeAccent(
                    red: converted.redComponent,
                    green: converted.greenComponent,
                    blue: converted.blueComponent
                )
            }
        )
    }

    private var accentPresets: [ThemeAccent] {
        [
            .default,
            ThemeAccent(red: 0.35, green: 0.55, blue: 1),
            ThemeAccent(red: 0.6, green: 0.35, blue: 1),
            ThemeAccent(red: 1, green: 0.32, blue: 0.55),
            ThemeAccent(red: 0.25, green: 1, blue: 0.45),
            ThemeAccent(red: 1, green: 0.72, blue: 0.2),
        ]
    }
}

#Preview {
    AppearanceSettingsView()
        .frame(width: 480, height: 600)
        .background(Color.black)
}
