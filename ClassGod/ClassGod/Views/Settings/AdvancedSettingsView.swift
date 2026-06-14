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
                    title: "section.data_management",
                    icon: "externaldrive",
                    defaultExpanded: true,
                    accentColor: .blue
                ) {
                    HStack(spacing: 10) {
                        SettingsActionRow(
                            icon: "square.and.arrow.up",
                            title: "button.export",
                            action: { exportPreferences() }
                        )

                        SettingsActionRow(
                            icon: "square.and.arrow.down",
                            title: "button.import",
                            action: { importPreferences() }
                        )
                    }

                    SettingsActionRow(
                        icon: "arrow.counterclockwise",
                        title: "button.reset_all",
                        action: { showResetConfirmation = true },
                        isDestructive: true
                    )

                    SettingsActionRow(
                        icon: "trash",
                        title: "button.clear_all",
                        action: {
                            if prefs.preferences.confirmBeforeClear {
                                showClearConfirmation = true
                            } else {
                                clearAllTabs()
                            }
                        },
                        isDestructive: true
                    )
                }

                StatefulCollapsibleSection(
                    title: "section.chaos_animation",
                    icon: "flame",
                    defaultExpanded: false,
                    accentColor: .orange
                ) {
                    SettingsSliderRow(
                        label: "setting.particle_count",
                        value: .init(
                            get: { Double(prefs.preferences.chaosParticleCount) },
                            set: { prefs.preferences.chaosParticleCount = Int($0) }
                        ),
                        range: 50...500,
                        step: 25,
                        suffix: ""
                    )

                    Text("setting.particle_count.caption")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                }

                StatefulCollapsibleSection(
                    title: "section.debug",
                    icon: "ant",
                    defaultExpanded: false,
                    accentColor: .purple
                ) {
                    SettingsActionRow(
                        icon: "terminal",
                        title: "button.open_console",
                        subtitle: "button.open_console.subtitle",
                        action: {
                            NSWorkspace.shared.openApplication(
                                at: URL(fileURLWithPath: "/System/Applications/Utilities/Console.app"),
                                configuration: NSWorkspace.OpenConfiguration()
                            )
                        }
                    )
                }

                StatefulCollapsibleSection(
                    title: "section.about",
                    icon: "info.circle",
                    defaultExpanded: false,
                    accentColor: .cyan
                ) {
                    HStack {
                        Text(String(localized: "about.version"))
                        Spacer()
                        Text("\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.8.0") (Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "12"))")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)

                    HStack {
                        Text(String(localized: "about.developer"))
                        Spacer()
                        Text(String(localized: "about.developer_name"))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)

                    safeLinkButton(
                        label: "about.release_notes",
                        icon: "doc.text",
                        urlString: "https://github.com/hzagaming/ClassGod/releases"
                    )

                    safeLinkButton(
                        label: "about.github_repo",
                        icon: "link",
                        urlString: "https://github.com/hzagaming/ClassGod"
                    )

                    safeLinkButton(
                        label: "about.github_profile",
                        icon: "person.circle",
                        urlString: "https://github.com/hzagaming"
                    )
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

    private func safeLinkButton(label: LocalizedStringKey, icon: String, urlString: String) -> some View {
        Button(action: {
            SoundEffectManager.shared.playButtonClick()
            HapticManager.shared.generic()
            guard let url = URL(string: urlString) else { return }
            NSWorkspace.shared.open(url)
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(.cyan.opacity(0.8))
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AdvancedSettingsView()
        .frame(width: 480, height: 600)
        .background(Color.black)
}
