import SwiftUI

struct UpdateSettingsView: View {
    @ObservedObject private var service = UpdateService.shared
    @ObservedObject private var prefs = PreferencesManager.shared

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    private var accent: Color { prefs.preferences.themeAccent.color }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14 * zoomScale) {
                HStack {
                    VStack(alignment: .leading, spacing: 3 * zoomScale) {
                        Text("update.title")
                            .font(.system(size: 17 * zoomScale, weight: .bold, design: .monospaced))
                        Text("update.subtitle")
                            .font(.system(size: 10 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    Spacer()
                    Text(verbatim: "v\(service.currentVersion) (\(service.currentBuild))")
                        .font(.system(size: 10 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.45))
                }

                statusCard

                if let release = service.latestRelease,
                   service.phase == .updateAvailable
                    || service.phase == .installerUnavailable
                    || service.phase == .downloading
                    || service.phase == .installerOpened {
                    releaseCard(release)
                }

                securityNotice
            }
            .padding(18 * zoomScale)
        }
        .background(Color.black)
        .onAppear {
            if service.phase == .idle { service.checkForUpdates() }
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12 * zoomScale) {
            HStack(spacing: 10 * zoomScale) {
                Image(systemName: statusIcon)
                    .font(.system(size: 22 * zoomScale, weight: .semibold))
                    .foregroundStyle(statusColor)
                VStack(alignment: .leading, spacing: 2 * zoomScale) {
                    Text(statusTitle)
                        .font(.system(size: 12 * zoomScale, weight: .bold, design: .monospaced))
                    Text(statusDetail)
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.48))
                }
                Spacer()
                Button {
                    SoundEffectManager.shared.playButtonClick()
                    service.checkForUpdates()
                } label: {
                    Label("update.check_now", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(service.phase == .checking || service.phase == .downloading)
            }

            if service.phase == .checking {
                ProgressView()
                    .controlSize(.small)
            }

            if service.phase == .downloading {
                HStack(spacing: 10 * zoomScale) {
                    ProgressView(value: service.downloadProgress) {
                        Text("update.downloading")
                            .font(.system(size: 9 * zoomScale, design: .monospaced))
                    }
                    Button("update.cancel_download") {
                        SoundEffectManager.shared.playButtonClick()
                        service.cancelDownload()
                    }
                    .buttonStyle(.bordered)
                }
            }

            if let error = service.errorMessage, service.phase == .failed {
                Text(verbatim: error)
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.red.opacity(0.85))
                    .textSelection(.enabled)
            }

            if let lastChecked = service.lastCheckedAt {
                Text(lastChecked, format: .dateTime.year().month().day().hour().minute())
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.28))
            }
        }
        .padding(14 * zoomScale)
        .background(Color.white.opacity(0.035))
        .overlay(
            RoundedRectangle(cornerRadius: 9 * zoomScale)
                .stroke(statusColor.opacity(0.35), lineWidth: zoomScale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 9 * zoomScale))
    }

    private func releaseCard(_ release: GitHubRelease) -> some View {
        VStack(alignment: .leading, spacing: 10 * zoomScale) {
            HStack {
                VStack(alignment: .leading, spacing: 2 * zoomScale) {
                    Text(verbatim: release.name)
                        .font(.system(size: 13 * zoomScale, weight: .bold, design: .monospaced))
                    Text(verbatim: release.tagName)
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(accent)
                }
                Spacer()
                if let asset = service.preferredAsset {
                    Text(verbatim: ByteCountFormatter.string(fromByteCount: asset.size, countStyle: .file))
                        .font(.system(size: 8 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }

            if !release.body.isEmpty {
                Text(verbatim: release.body)
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                    .textSelection(.enabled)
            }

            HStack(spacing: 8 * zoomScale) {
                if service.phase == .updateAvailable {
                    Button {
                        SoundEffectManager.shared.playButtonClick()
                        service.downloadAndInstall()
                    } label: {
                        Label("update.download_install", systemImage: "arrow.down.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button {
                    SoundEffectManager.shared.playButtonClick()
                    service.openReleasePage()
                } label: {
                    Label("update.view_release", systemImage: "safari")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14 * zoomScale)
        .background(accent.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 9 * zoomScale))
    }

    private var securityNotice: some View {
        HStack(alignment: .top, spacing: 9 * zoomScale) {
            Image(systemName: "exclamationmark.shield")
                .foregroundStyle(.orange)
            Text("update.security_notice")
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(12 * zoomScale)
        .background(Color.orange.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
    }

    private var statusIcon: String {
        switch service.phase {
        case .idle, .checking: "arrow.triangle.2.circlepath"
        case .upToDate: "checkmark.seal.fill"
        case .updateAvailable: "sparkles"
        case .installerUnavailable: "shippingbox.and.arrow.backward"
        case .downloading: "arrow.down.circle"
        case .installerOpened: "shippingbox.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch service.phase {
        case .upToDate: .green
        case .updateAvailable, .downloading: accent
        case .installerUnavailable: .orange
        case .installerOpened: .orange
        case .failed: .red
        case .idle, .checking: .white.opacity(0.65)
        }
    }

    private var statusTitle: LocalizedStringKey {
        switch service.phase {
        case .idle: "update.status.idle"
        case .checking: "update.status.checking"
        case .upToDate: "update.status.current"
        case .updateAvailable: "update.status.available"
        case .installerUnavailable: "update.status.installer_unavailable"
        case .downloading: "update.status.downloading"
        case .installerOpened: "update.status.installer_opened"
        case .failed: "update.status.failed"
        }
    }

    private var statusDetail: LocalizedStringKey {
        switch service.phase {
        case .idle: "update.detail.idle"
        case .checking: "update.detail.checking"
        case .upToDate: "update.detail.current"
        case .updateAvailable: "update.detail.available"
        case .installerUnavailable: "update.detail.installer_unavailable"
        case .downloading: "update.detail.downloading"
        case .installerOpened: "update.detail.installer_opened"
        case .failed: "update.detail.failed"
        }
    }
}
