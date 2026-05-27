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
                    Picker(String(localized: "setting.when_adding"), selection: $prefs.preferences.defaultBrowser) {
                        Text(String(localized: "browser.auto_detect")).tag(Optional<BrowserType>.none)
                        ForEach(BrowserType.allCases) { browser in
                            Text(browser.displayName).tag(Optional(browser))
                        }
                    }
                    .pickerStyle(.radioGroup)

                    Text(String(localized: "browser.default_caption"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.browser_not_running"),
                    icon: "power",
                    defaultExpanded: true,
                    accentColor: .orange
                ) {
                    Picker(String(localized: "setting.behavior"), selection: $prefs.preferences.browserNotRunningBehavior) {
                        ForEach(BrowserNotRunningBehavior.allCases) { behavior in
                            Text(behavior.displayName).tag(behavior)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    Text(String(localized: "browser.not_running_caption"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                StatefulCollapsibleSection(
                    title: "Privacy & Security",
                    icon: "lock.shield",
                    defaultExpanded: false,
                    accentColor: .green
                ) {
                    Toggle("Ask Before Opening URL", isOn: $prefs.preferences.askBeforeOpening)
                    Toggle("Force Incognito / Private Mode", isOn: $prefs.preferences.forceIncognitoMode)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom User Agent")
                            .font(.system(size: 12, weight: .medium))
                        TextField("Leave empty to use browser default", text: $prefs.preferences.customUserAgent)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, design: .monospaced))
                    }
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.supported_browsers"),
                    icon: "checkmark.circle",
                    defaultExpanded: false,
                    accentColor: .cyan
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        browserRow(name: "Safari", icon: "safari", bundleID: BrowserType.safari.bundleIdentifier)
                        browserRow(name: "Google Chrome", icon: "globe", bundleID: BrowserType.chrome.bundleIdentifier)
                        browserRow(name: "Microsoft Edge", icon: "wave.3.forward", bundleID: BrowserType.edge.bundleIdentifier)
                    }
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.permissions"),
                    icon: "hand.raised",
                    defaultExpanded: false,
                    accentColor: .red
                ) {
                    Button(String(localized: "button.open_automation")) {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }

    private func browserRow(name: String, icon: String, bundleID: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
            Text(name)
            Spacer()
            Text(bundleID)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    BrowserSettingsView()
        .frame(width: 480, height: 600)
        .background(Color.black)
}
