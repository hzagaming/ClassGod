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
            Section("Data Management") {
                HStack {
                    Button("Export Preferences...") {
                        exportPreferences()
                    }
                    
                    Button("Import Preferences...") {
                        importPreferences()
                    }
                }
                
                Button("Reset All Preferences") {
                    showResetConfirmation = true
                }
                .foregroundStyle(.red)
                
                Button("Clear All Saved Tabs", role: .destructive) {
                    showClearConfirmation = true
                }
            }
            
            Section("Debugging") {
                Toggle("Enable debug logging", isOn: $prefs.preferences.enableDebugLogging)
                
                if prefs.preferences.enableDebugLogging {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Debug logs are printed to Console.app")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Button("Open Console.app") {
                            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/Utilities/Console.app"), configuration: NSWorkspace.OpenConfiguration())
                        }
                        .font(.caption)
                    }
                }
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("0.1.0 (Build 1)")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Developer")
                    Spacer()
                    Text("Hanazar Software")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .alert("Reset Preferences?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                prefs.resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values. Your saved tabs will not be affected.")
        }
        .alert("Clear All Tabs?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                StorageManager.shared.saveTabs([])
                ShortcutManager.shared.unregisterAllShortcuts()
            }
        } message: {
            Text("This will permanently delete all saved tabs and shortcuts. This cannot be undone.")
        }
        .alert("Import Result", isPresented: $showImportResult) {
            Button("OK", role: .cancel) {}
        } message: {
            switch importResult {
            case .success:
                Text("Preferences imported successfully.")
            case .failure:
                Text("Failed to import preferences. The file may be corrupted or incompatible.")
            case .none:
                Text("")
            }
        }
    }
    
    private func exportPreferences() {
        guard let url = prefs.exportToFile() else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "ClassGod-Preferences.json"
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
