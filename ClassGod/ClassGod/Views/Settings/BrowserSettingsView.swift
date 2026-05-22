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
            Section("Default Browser") {
                Picker("When adding manually", selection: $prefs.preferences.defaultBrowser) {
                    Text("Auto-detect (none)").tag(Optional<BrowserType>.none)
                    ForEach(BrowserType.allCases) { browser in
                        Text(browser.displayName).tag(Optional(browser))
                    }
                }
                .pickerStyle(.radioGroup)
                
                Text("The default browser is used when you manually add a tab without a browser currently open.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Browser Not Running") {
                Picker("Behavior", selection: $prefs.preferences.browserNotRunningBehavior) {
                    ForEach(BrowserNotRunningBehavior.allCases) { behavior in
                        Text(behavior.displayName).tag(behavior)
                    }
                }
                .pickerStyle(.radioGroup)
                
                Text("Determines what happens when you trigger a shortcut for a browser that is not currently running.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Supported Browsers") {
                VStack(alignment: .leading, spacing: 8) {
                    browserRow(name: "Safari", icon: "safari", bundleID: BrowserType.safari.bundleIdentifier)
                    browserRow(name: "Google Chrome", icon: "globe", bundleID: BrowserType.chrome.bundleIdentifier)
                    browserRow(name: "Microsoft Edge", icon: "wave.3.forward", bundleID: BrowserType.edge.bundleIdentifier)
                }
            }
            
            Section("Permissions") {
                Button("Open Automation Settings...") {
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
