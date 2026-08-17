//
//  AdvancedSettingsView.swift
//  ClassGod
//

import SwiftUI
import UniformTypeIdentifiers

struct AdvancedSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared
    @StateObject private var uninstallService = UninstallService.shared
    @State private var showResetConfirmation = false
    @State private var showClearConfirmation = false
    @State private var showUninstallConfirmation = false
    @State private var showFinalUninstallConfirmation = false
    @State private var dataOperationResult: DataOperationResult?
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    enum DataOperationResult {
        case importSuccess, importFailure, exportSuccess, exportFailure

        var title: String {
            switch self {
            case .importSuccess, .importFailure: return String(localized: "import.result.title")
            case .exportSuccess, .exportFailure: return String(localized: "export.result.title")
            }
        }

        var message: String {
            switch self {
            case .importSuccess: return String(localized: "import.success")
            case .importFailure: return String(localized: "import.failure")
            case .exportSuccess: return String(localized: "export.success")
            case .exportFailure: return String(localized: "export.failure")
            }
        }
    }
    @State private var showDataOperationResult = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10 * zoomScale) {
                StatefulCollapsibleSection(
                    title: "section.data_management",
                    icon: "externaldrive",
                    defaultExpanded: true,
                    accentColor: .blue
                ) {
                    HStack(spacing: 10 * zoomScale) {
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
                    title: "section.uninstall",
                    icon: "trash.slash.fill",
                    defaultExpanded: false,
                    accentColor: .red
                ) {
                    SettingsActionRow(
                        icon: "trash.fill",
                        title: "uninstall.action",
                        subtitle: "uninstall.action.subtitle",
                        action: { showUninstallConfirmation = true },
                        isDestructive: true
                    )
                    .disabled(uninstallService.isUninstalling)

                    VStack(alignment: .leading, spacing: 7 * zoomScale) {
                        Label("uninstall.cleanup.permissions", systemImage: "hand.raised.slash.fill")
                        Label("uninstall.cleanup.data", systemImage: "externaldrive.badge.xmark")
                        Label("uninstall.cleanup.helper", systemImage: "gearshape.2.fill")
                        Label("uninstall.cleanup.receipt", systemImage: "shippingbox.fill")
                    }
                    .font(.system(size: 10 * zoomScale, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.52))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 11 * zoomScale)
                    .padding(.vertical, 9 * zoomScale)
                    .background(Color.red.opacity(0.045))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7 * zoomScale)
                            .stroke(Color.red.opacity(0.14), lineWidth: zoomScale)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 7 * zoomScale))

                    if uninstallService.isUninstalling {
                        HStack(spacing: 8 * zoomScale) {
                            ProgressView().controlSize(.small)
                            Text("uninstall.in_progress")
                                .font(.system(size: 11 * zoomScale))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10 * zoomScale)
                    }
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
                        range: 12...48,
                        step: 4,
                        suffix: ""
                    )

                    Text("setting.particle_count.caption")
                        .font(.system(size: 11 * zoomScale))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10 * zoomScale)
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
                    accentColor: prefs.preferences.themeAccent.color
                ) {
                    HStack {
                        Text(String(localized: "about.version"))
                        Spacer()
                        Text(versionDescription)
                            .foregroundStyle(.secondary)
                    }
                    .font(.system(size: 11 * zoomScale))
                    .padding(.horizontal, 10 * zoomScale)
                    .padding(.vertical, 4 * zoomScale)

                    HStack {
                        Text(String(localized: "about.developer"))
                        Spacer()
                        Text(String(localized: "about.developer_name"))
                            .foregroundStyle(.secondary)
                    }
                    .font(.system(size: 11 * zoomScale))
                    .padding(.horizontal, 10 * zoomScale)
                    .padding(.vertical, 4 * zoomScale)

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
            .padding(.horizontal, 8 * zoomScale)
            .padding(.vertical, 8 * zoomScale)
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
        .alert(String(localized: "uninstall.confirm.title"), isPresented: $showUninstallConfirmation) {
            Button(String(localized: "button.cancel"), role: .cancel) {}
            Button(String(localized: "uninstall.confirm.continue"), role: .destructive) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showFinalUninstallConfirmation = true
                }
            }
        } message: {
            Text(String(localized: "uninstall.confirm.message"))
        }
        .alert(String(localized: "uninstall.final.title"), isPresented: $showFinalUninstallConfirmation) {
            Button(String(localized: "button.cancel"), role: .cancel) {}
            Button(String(localized: "uninstall.final.action"), role: .destructive) {
                uninstallService.uninstall()
            }
        } message: {
            Text(String(localized: "uninstall.final.message"))
        }
        .alert(
            String(localized: "uninstall.error.title"),
            isPresented: Binding(
                get: { uninstallService.errorMessage != nil },
                set: { if !$0 { uninstallService.clearError() } }
            )
        ) {
            Button(String(localized: "button.ok"), role: .cancel) {
                uninstallService.clearError()
            }
        } message: {
            Text(uninstallService.errorMessage ?? String(localized: "uninstall.error.failed"))
        }
        .alert(dataOperationResult?.title ?? "", isPresented: $showDataOperationResult) {
            Button(String(localized: "button.ok"), role: .cancel) {}
        } message: {
            Text(dataOperationResult?.message ?? "")
        }
    }

    private func exportPreferences() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = prefs.suggestedExportFilename()
        panel.allowedContentTypes = [.json]
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")

        if panel.runModal() == .OK, let destination = panel.url {
            dataOperationResult = prefs.export(to: destination) ? .exportSuccess : .exportFailure
            showDataOperationResult = true
        }
    }

    private func importPreferences() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            let success = prefs.importFromFile(url: url)
            dataOperationResult = success ? .importSuccess : .importFailure
            showDataOperationResult = true
        }
    }

    private func clearAllTabs() {
        GhostProtocolController.shared.prepareForShortcutChanges()
        StorageManager.shared.saveTabs([])
        ShortcutCatalogCoordinator.shared.reload()
        GhostProtocolController.shared.reconcileShortcutAfterChanges()
        NotificationCenter.default.post(name: .classGodTabsDidChange, object: nil)
    }

    private var versionDescription: String {
        String(
            format: String(localized: "about.version_value"),
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—",
            Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        )
    }

    private func safeLinkButton(label: LocalizedStringKey, icon: String, urlString: String) -> some View {
        Button(action: {
            SoundEffectManager.shared.playButtonClick()
            HapticManager.shared.generic()
            guard let url = URL(string: urlString) else { return }
            NSWorkspace.shared.open(url)
        }) {
            HStack(spacing: 8 * zoomScale) {
                Image(systemName: icon)
                    .font(.system(size: 11 * zoomScale))
                    .foregroundStyle(prefs.preferences.themeAccent.color.opacity(0.8))
                Text(label)
                    .font(.system(size: 11 * zoomScale, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9 * zoomScale))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 10 * zoomScale)
            .padding(.vertical, 8 * zoomScale)
            .background(
                RoundedRectangle(cornerRadius: 6 * zoomScale)
                    .fill(Color.white.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6 * zoomScale)
                            .stroke(Color.white.opacity(0.06), lineWidth: zoomScale)
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
