//
//  BrowserSettingsView.swift
//  ClassGod
//

import SwiftUI

struct BrowserSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                StatefulCollapsibleSection(
                    title: String(localized: "section.default_browser"),
                    icon: "globe",
                    defaultExpanded: true,
                    accentColor: .blue
                ) {
                    SettingsPickerRow(
                        label: String(localized: "setting.when_adding"),
                        selection: $prefs.preferences.defaultBrowser,
                        options: [Optional<BrowserType>.none] + BrowserType.allCases.map { Optional($0) },
                        displayName: {
                            if let browser = $0 {
                                return browser.displayName
                            }
                            return String(localized: "browser.auto_detect")
                        },
                        style: .radio
                    )

                    Text(String(localized: "browser.default_caption"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.browser_not_running"),
                    icon: "power",
                    defaultExpanded: true,
                    accentColor: .orange
                ) {
                    SettingsPickerRow(
                        label: String(localized: "setting.behavior"),
                        selection: $prefs.preferences.browserNotRunningBehavior,
                        options: BrowserNotRunningBehavior.allCases,
                        displayName: \.displayName,
                        style: .radio
                    )

                    Text(String(localized: "browser.not_running_caption"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.supported_browsers"),
                    icon: "checkmark.circle",
                    defaultExpanded: false,
                    accentColor: .cyan
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        browserRow(name: "Safari", icon: "safari", bundleID: BrowserType.safari.bundleIdentifier)
                        browserRow(name: "Google Chrome", icon: "globe", bundleID: BrowserType.chrome.bundleIdentifier)
                        browserRow(name: "Microsoft Edge", icon: "wave.3.forward", bundleID: BrowserType.edge.bundleIdentifier)
                    }
                    .padding(.horizontal, 10)
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.permissions"),
                    icon: "hand.raised",
                    defaultExpanded: false,
                    accentColor: .red
                ) {
                    SettingsActionRow(
                        icon: "lock.shield",
                        title: String(localized: "button.open_automation"),
                        subtitle: "Open System Settings > Privacy & Security > Automation",
                        action: {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }

    private func browserRow(name: String, icon: String, bundleID: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 18)
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
            Spacer()
            Text(bundleID)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    BrowserSettingsView()
        .frame(width: 480, height: 600)
        .background(Color.black)
}
