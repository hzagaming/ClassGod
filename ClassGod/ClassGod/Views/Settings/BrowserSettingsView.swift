//
//  BrowserSettingsView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

struct BrowserSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared
    
    var body: some View {
        Form {
            Section(String(localized: "section.default_browser")) {
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
            
            Section(String(localized: "section.browser_not_running")) {
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
            
            Section(String(localized: "section.supported_browsers")) {
                VStack(alignment: .leading, spacing: 8) {
                    browserRow(name: "Safari", icon: "safari", bundleID: BrowserType.safari.bundleIdentifier)
                    browserRow(name: "Google Chrome", icon: "globe", bundleID: BrowserType.chrome.bundleIdentifier)
                    browserRow(name: "Microsoft Edge", icon: "wave.3.forward", bundleID: BrowserType.edge.bundleIdentifier)
                }
            }
            
            Section(String(localized: "section.permissions")) {
                Button(String(localized: "button.open_automation")) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
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
}
