//
//  AdvancedSettingsView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct AdvancedSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared
    @State private var showResetConfirmation = false
    @State private var showClearConfirmation = false
    @State private var importResult: ImportResult?
    
    enum ImportResult {
        case success, failure
    }
    @State private var showImportResult = false
    
    var body: some View {
        Form {
            Section(String(localized: "section.data_management")) {
                HStack {
                    Button(String(localized: "button.export")) {
                        exportPreferences()
                    }
                    
                    Button(String(localized: "button.import")) {
                        importPreferences()
                    }
                }
                
                Button(String(localized: "button.reset_all")) {
                    showResetConfirmation = true
                }
                .foregroundStyle(.red)
                
                Button(String(localized: "button.clear_all"), role: .destructive) {
                    showClearConfirmation = true
                }
            }
            
            Section(String(localized: "section.debug")) {
                Toggle(String(localized: "setting.debug_logging"), isOn: $prefs.preferences.enableDebugLogging)
                
                if prefs.preferences.enableDebugLogging {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "debug.caption"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Button(String(localized: "button.open_console")) {
                            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/Utilities/Console.app"), configuration: NSWorkspace.OpenConfiguration())
                        }
                        .font(.caption)
                    }
                }
            }
            
            Section(String(localized: "section.about")) {
                HStack {
                    Text(String(localized: "about.version"))
                    Spacer()
                    Text("\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.3.0") (Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "3"))")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text(String(localized: "about.developer"))
                    Spacer()
                    Text("Hanazar Software")
                        .foregroundStyle(.secondary)
                }
                
                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://github.com/hzagaming/ClassGod/releases")!)
                }) {
                    Label(String(localized: "about.release_notes"), systemImage: "doc.text")
                }
                
                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://github.com/hzagaming/ClassGod")!)
                }) {
                    Label(String(localized: "about.github_repo"), systemImage: "link")
                }
                
                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://github.com/hzagaming")!)
                }) {
                    Label(String(localized: "about.github_profile"), systemImage: "person.circle")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .alert(String(localized: "reset.confirm.title"), isPresented: $showResetConfirmation) {
            Button(String(localized: "button.cancel"), role: .cancel) {}
            Button(String(localized: "button.reset"), role: .destructive) {
                prefs.resetToDefaults()
            }
        } message: {
            Text(String(localized: "reset.confirm.message"))
        }
        .alert(String(localized: "clear.confirm.title"), isPresented: $showClearConfirmation) {
            Button(String(localized: "button.cancel"), role: .cancel) {}
            Button(String(localized: "button.clear"), role: .destructive) {
                StorageManager.shared.saveTabs([])
                ShortcutManager.shared.unregisterAllShortcuts()
            }
        } message: {
            Text(String(localized: "clear.confirm.message"))
        }
        .alert(String(localized: "import.result.title"), isPresented: $showImportResult) {
            Button(String(localized: "button.ok"), role: .cancel) {}
        } message: {
            switch importResult {
            case .success:
                Text(String(localized: "import.success"))
            case .failure:
                Text(String(localized: "import.failure"))
            case .none:
                Text("")
            }
        }
    }
    
    private func exportPreferences() {
        guard let url = prefs.exportToFile() else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = String(format: String(localized: "export.filename"), "")
        panel.allowedContentTypes = [.json]
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
        
        if panel.runModal() == .OK, let destination = panel.url {
            try? FileManager.default.copyItem(at: url, to: destination)
        }
    }
    
    private func importPreferences() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            let success = prefs.importFromFile(url: url)
            importResult = success ? .success : .failure
            showImportResult = true
        }
    }
}

#Preview {
    AdvancedSettingsView()
}
