import SwiftUI

struct HeadphoneGuardView: View {
    @ObservedObject var service = HeadphoneGuardService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    let onClose: () -> Void
    private let accent = Color(red: 1, green: 0.28, blue: 0.48)
    private var zoom: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        TrainingPanel(title: "headphone.title", subtitle: "headphone.subtitle", icon: "headphones", accent: accent, onClose: onClose) {
            VStack(alignment: .leading, spacing: 22 * zoom) {
                Text("headphone.intro").font(.system(size: 25 * zoom, weight: .bold, design: .rounded))
                Text("headphone.instructions").foregroundStyle(.white.opacity(0.65))
                statusCard
                if let trip = service.lastTrip { tripCard(trip) }
                if !service.silenced.isEmpty { restoreCard }
                Text("headphone.scope").foregroundStyle(.white.opacity(0.65))
                Text("headphone.session_hint").font(.system(size: 10 * zoom)).foregroundStyle(.white.opacity(0.5))
            }
            .font(.system(size: 12 * zoom))
        }
        .onAppear { service.startMonitoring() }
        .onDisappear { service.stopMonitoring() }
    }

    private var statusCard: some View {
        HStack(alignment: .top, spacing: 20 * zoom) {
            Image(systemName: service.isArmed ? "shield.lefthalf.filled" : "headphones")
                .font(.system(size: 36 * zoom, weight: .light)).foregroundStyle(accent)
                .symbolEffect(.pulse, isActive: service.isArmed && Anim.enabled)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 10 * zoom) {
                Text(LocalizedStringKey(service.isArmed ? "headphone.armed" : "headphone.disarmed_status"))
                    .font(.system(size: 17 * zoom, weight: .bold))
                if let device = service.guardedDevice {
                    Text(String(format: String(localized: "headphone.guarding_format"), device.name)).foregroundStyle(accent)
                }
                Text("headphone.current_output").foregroundStyle(.white.opacity(0.5))
                if let output = service.currentOutput {
                    Text(verbatim: output.name).font(.system(size: 19 * zoom, weight: .semibold)).lineLimit(3)
                    Text(LocalizedStringKey(service.currentMuted.map { $0 ? "quiet.output_muted" : "quiet.output_unmuted" } ?? "quiet.unsupported"))
                        .foregroundStyle(service.currentMuted == nil ? .orange : accent)
                } else {
                    Text("headphone.no_device")
                }
                Text(LocalizedStringKey(service.notice.titleKey))
                    .foregroundStyle(service.notice.isFailure ? .orange : .white.opacity(0.65))
                if service.isArmed {
                    Button("headphone.disarm", role: .destructive) { service.disarm(); HapticManager.shared.generic() }
                } else {
                    Button("headphone.arm") { _ = service.arm(); HapticManager.shared.generic() }
                        .buttonStyle(TrainingButtonStyle(accent: accent, zoom: zoom, prominent: true))
                        .disabled(service.currentOutput == nil)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(20 * zoom)
        .background(accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 18 * zoom))
        .overlay(RoundedRectangle(cornerRadius: 18 * zoom).stroke(accent.opacity(0.3)))
    }

    private func tripCard(_ trip: HeadphoneGuardTrip) -> some View {
        VStack(alignment: .leading, spacing: 8 * zoom) {
            Label(LocalizedStringKey(trip.outcome.titleKey),
                  systemImage: trip.outcome == .silenced ? "speaker.slash.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(trip.outcome.isFailure ? .orange : accent)
            Text(verbatim: trip.device.name).fontWeight(.semibold)
            Text(trip.date, style: .time).foregroundStyle(.white.opacity(0.5)).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(18 * zoom)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14 * zoom))
    }

    private var restoreCard: some View {
        VStack(alignment: .leading, spacing: 12 * zoom) {
            Label("headphone.silenced_list", systemImage: "arrow.uturn.backward.circle")
            ForEach(service.silenced, id: \.uid) { device in
                Text(verbatim: device.name).fontWeight(.semibold)
            }
            if let output = service.currentOutput, service.silenced.contains(where: { $0.uid == output.uid }) {
                Text("headphone.restore_warning").foregroundStyle(.orange)
            }
            Button("headphone.restore") { _ = service.restore(); HapticManager.shared.generic() }
                .buttonStyle(TrainingButtonStyle(accent: accent, zoom: zoom, prominent: !service.isArmed))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(18 * zoom)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14 * zoom))
    }
}

private extension HeadphoneGuardNotice {
    var isFailure: Bool { self == .unavailable || self == .restoreFailed }
    var titleKey: String {
        switch self {
        case .ready: "headphone.status.ready"
        case .armed: "headphone.status.armed"
        case .disarmed: "headphone.status.disarmed"
        case .unavailable: "headphone.status.unavailable"
        case .restored: "headphone.status.restored"
        case .restoreFailed: "headphone.status.restore_failed"
        }
    }
}

private extension HeadphoneGuardOutcome {
    var isFailure: Bool { self == .unsupported || self == .failed }
    var titleKey: String {
        switch self {
        case .silenced: "headphone.trip.silenced"
        case .alreadySilent: "headphone.trip.already_silent"
        case .unsupported: "headphone.trip.unsupported"
        case .failed: "headphone.trip.failed"
        }
    }
}
