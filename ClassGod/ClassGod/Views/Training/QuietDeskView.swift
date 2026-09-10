import SwiftUI

struct QuietDeskView: View {
    @ObservedObject var service = QuietDeskService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var confirmsForget = false
    let onClose: () -> Void
    private let accent = Color(red: 1, green: 0.28, blue: 0.48)
    private var zoom: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        TrainingPanel(title: "quiet.title", subtitle: "quiet.subtitle", icon: "speaker.slash.fill", accent: accent, onClose: onClose) {
            VStack(alignment: .leading, spacing: 22 * zoom) {
                Text("quiet.intro").font(.system(size: 25 * zoom, weight: .bold, design: .rounded))
                Text("quiet.instructions").foregroundStyle(.white.opacity(0.65))
                if let device = service.restoreDevice {
                    VStack(alignment: .leading, spacing: 14 * zoom) {
                        Label("quiet.restore_saved", systemImage: "arrow.uturn.backward.circle")
                        Text(verbatim: device.name).fontWeight(.semibold)
                        if service.currentOutput?.uid != device.uid {
                            Text("quiet.output_changed").foregroundStyle(.orange)
                        }
                        statusMessage
                        Button("quiet.restore") { _ = service.restore(); HapticManager.shared.generic() }
                            .buttonStyle(.borderedProminent)
                        Button("quiet.forget", role: .destructive) { confirmsForget = true }.buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(18 * zoom)
                    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14 * zoom))
                } else {
                    Button("quiet.mute") { _ = service.mute(); HapticManager.shared.generic() }
                        .buttonStyle(.borderedProminent).disabled(service.currentMuted != false)
                    statusMessage
                }
                HStack(spacing: 20 * zoom) {
                    Image(systemName: service.currentMuted.map { $0 ? "speaker.slash.fill" : "speaker.wave.2.fill" } ?? "questionmark.circle")
                        .font(.system(size: 36 * zoom, weight: .light)).foregroundStyle(accent)
                    VStack(alignment: .leading, spacing: 10 * zoom) {
                        Text("quiet.current_output").foregroundStyle(.white.opacity(0.5))
                        if let output = service.currentOutput {
                            Text(verbatim: output.name).font(.system(size: 19 * zoom, weight: .semibold)).lineLimit(3)
                        } else { Text("quiet.no_device") }
                        Text(LocalizedStringKey(service.currentMuted.map { $0 ? "quiet.output_muted" : "quiet.output_unmuted" } ?? "quiet.unsupported"))
                            .foregroundStyle(service.currentMuted == nil ? .orange : accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(20 * zoom)
                .background(accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 18 * zoom))
                .overlay(RoundedRectangle(cornerRadius: 18 * zoom).stroke(accent.opacity(0.3)))
                Text("quiet.scope").foregroundStyle(.white.opacity(0.65))
                Text("quiet.session_hint").font(.system(size: 10 * zoom)).foregroundStyle(.white.opacity(0.5))
            }
            .font(.system(size: 12 * zoom))
        }
        .onAppear { service.startMonitoring() }
        .onDisappear { service.stopMonitoring() }
        .alert("quiet.forget_title", isPresented: $confirmsForget) {
            Button("quiet.forget", role: .destructive) { service.forget() }
            Button("button.cancel", role: .cancel) {}
        } message: { Text("quiet.forget_message") }
    }

    private var statusMessage: some View {
        Text(LocalizedStringKey(service.notice.titleKey))
            .foregroundStyle(service.notice.isFailure ? .orange : .white.opacity(0.65))
    }
}

private extension QuietDeskNotice {
    var isFailure: Bool { self == .unavailable || self == .muteFailed || self == .restoreFailed }
    var titleKey: String {
        switch self {
        case .ready: "quiet.status.ready"
        case .muted: "quiet.status.muted"
        case .restored: "quiet.status.restored"
        case .alreadyMuted: "quiet.status.already_muted"
        case .unavailable: "quiet.status.unavailable"
        case .muteFailed: "quiet.status.mute_failed"
        case .restoreFailed: "quiet.status.restore_failed"
        }
    }
}
