import SwiftUI

struct ReturnDockView: View {
    @ObservedObject var service = ReturnDockService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var confirmsClear = false
    let onClose: () -> Void
    let onOpenDestinTab: () -> Void
    private let accent = Color(red: 1, green: 0.28, blue: 0.48)
    private var zoom: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        TrainingPanel(title: "return.title", subtitle: "return.subtitle", icon: "arrow.uturn.backward.circle.fill", accent: accent, onClose: onClose) {
            VStack(alignment: .leading, spacing: 22 * zoom) {
                Text("return.intro").font(.system(size: 25 * zoom, weight: .bold, design: .rounded))
                Text("return.instructions").foregroundStyle(.white.opacity(0.65))
                Toggle("return.enable", isOn: Binding(get: { service.isEnabled }, set: service.setEnabled))
                    .toggleStyle(.switch)
                    .padding(16 * zoom)
                    .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 12 * zoom))
                if service.returnFailed {
                    Label("return.failed", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                }
                if service.tickets.isEmpty {
                    VStack(spacing: 18 * zoom) {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .font(.system(size: 54 * zoom, weight: .light)).foregroundStyle(accent)
                        Text(LocalizedStringKey(service.isEnabled ? "return.empty_enabled" : "return.empty_disabled"))
                            .multilineTextAlignment(.center)
                        Button("return.open_destinations", action: onOpenDestinTab).buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 30 * zoom)
                } else {
                    HStack {
                        Label("return.recent", systemImage: "clock.arrow.circlepath")
                        Spacer()
                        Button("return.clear", role: .destructive) { confirmsClear = true }.buttonStyle(.bordered)
                    }
                    TimelineView(.periodic(from: .now, by: 2)) { _ in
                        VStack(spacing: 12 * zoom) {
                            ForEach(service.tickets) { ticket in ticketRow(ticket) }
                        }
                    }
                }
                Text("return.scope").foregroundStyle(.white.opacity(0.65))
                Text("return.session_hint").font(.system(size: 10 * zoom)).foregroundStyle(.white.opacity(0.5))
            }
            .font(.system(size: 12 * zoom))
        }
        .alert("return.clear_title", isPresented: $confirmsClear) {
            Button("return.clear", role: .destructive) { service.clear() }
            Button("button.cancel", role: .cancel) {}
        }
    }

    private func ticketRow(_ ticket: ReturnTicket) -> some View {
        let available = service.isAvailable(ticket)
        return VStack(alignment: .leading, spacing: 12 * zoom) {
            HStack(alignment: .top, spacing: 12 * zoom) {
                Image(systemName: "app.fill").foregroundStyle(accent)
                VStack(alignment: .leading, spacing: 5 * zoom) {
                    Text(verbatim: ticket.application.name).fontWeight(.semibold).lineLimit(2)
                    Text(ticket.createdAt, style: .relative).foregroundStyle(.white.opacity(0.5))
                }
                Spacer(minLength: 0)
                Button { service.remove(ticket.id) } label: { Image(systemName: "xmark") }
                    .buttonStyle(.plain).accessibilityLabel("return.remove")
            }
            if !available { Text("return.closed").foregroundStyle(.orange) }
            Button {
                if service.returnTo(ticket.id) { HapticManager.shared.success() }
                else { HapticManager.shared.warning() }
            } label: { Label("return.activate", systemImage: "arrow.uturn.backward") }
            .buttonStyle(.borderedProminent).disabled(!available)
        }
        .padding(18 * zoom)
        .background(accent.opacity(0.055), in: RoundedRectangle(cornerRadius: 14 * zoom))
        .overlay(RoundedRectangle(cornerRadius: 14 * zoom).stroke(accent.opacity(0.22)))
    }
}
