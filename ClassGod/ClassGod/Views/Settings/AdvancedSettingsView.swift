//
//  AdvancedSettingsView.swift
//  ClassGod
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
        ScrollView {
            VStack(spacing: 10) {
                StatefulCollapsibleSection(
                    title: String(localized: "section.data_management"),
                    icon: "externaldrive",
                    defaultExpanded: true,
                    accentColor: .blue
                ) {
                    HStack(spacing: 12) {
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
                        if prefs.preferences.confirmBeforeClear {
                            showClearConfirmation = true
                        } else {
                            clearAllTabs()
                        }
                    }
                }

                StatefulCollapsibleSection(
                    title: "Chaos Animation",
                    icon: "flame",
                    defaultExpanded: false,
                    accentColor: .orange
                ) {
                    HStack {
                        Text("Particle Count")
                        Slider(value: .init(
                            get: { Double(prefs.preferences.chaosParticleCount) },
                            set: { prefs.preferences.chaosParticleCount = Int($0) }
                        ), in: 50...500, step: 25)
                        Text("\(prefs.preferences.chaosParticleCount)")
                            .frame(width: 42, alignment: .trailing)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Text("Number of glitch windows spawned during the boot chaos animation. Higher values are more dramatic but use more memory.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                StatefulCollapsibleSection(
                    title: "Logging & Debug",
                    icon: "ant",
                    defaultExpanded: false,
                    accentColor: .purple
                ) {
                    Toggle(String(localized: "setting.debug_logging"), isOn: $prefs.preferences.enableDebugLogging)

                    HStack {
                        Text("Log Retention")
                        Slider(value: .init(
                            get: { Double(prefs.preferences.logRetentionDays) },
                            set: { prefs.preferences.logRetentionDays = Int($0) }
                        ), in: 1...30, step: 1)
                        Text("\(prefs.preferences.logRetentionDays)d")
                            .frame(width: 36, alignment: .trailing)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

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
                        .transition(.opacity)
                    }
                }

                StatefulCollapsibleSection(
                    title: "Developer",
                    icon: "hammer",
                    defaultExpanded: false,
                    accentColor: .red
                ) {
                    Toggle("Developer Mode", isOn: $prefs.preferences.enableDeveloperMode)

                    Toggle("Auto-Backup", isOn: $prefs.preferences.enableAutoBackup)

                    HStack {
                        Text("Backup Interval")
                        Slider(value: .init(
                            get: { Double(prefs.preferences.autoBackupIntervalHours) },
                            set: { prefs.preferences.autoBackupIntervalHours = Int($0) }
                        ), in: 1...24, step: 1)
                        Text("\(prefs.preferences.autoBackupIntervalHours)h")
                            .frame(width: 36, alignment: .trailing)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .disabled(!prefs.preferences.enableAutoBackup)
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.about"),
                    icon: "info.circle",
                    defaultExpanded: false,
                    accentColor: .cyan
                ) {
                    HStack {
                        Text(String(localized: "about.version"))
                        Spacer()
                        Text("\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.3.2") (Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "5"))")
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
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
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
                clearAllTabs()
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
        panel.nameFieldStringValue = url.lastPathComponent
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

    private func clearAllTabs() {
        StorageManager.shared.saveTabs([])
        NotificationCenter.default.post(name: .classGodTabsDidChange, object: nil)
    }
}

#Preview {
    AdvancedSettingsView()
        .frame(width: 480, height: 600)
        .background(Color.black)
}
