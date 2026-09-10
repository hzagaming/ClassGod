import SwiftUI

struct ScreenCurtainView: View {
    @ObservedObject var service = ScreenCurtainController.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var duration = 30
    let onClose: () -> Void
    private let accent = Color(red: 1, green: 0.28, blue: 0.48)
    private var zoom: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        TrainingPanel(title: "curtain.title", subtitle: "curtain.subtitle", icon: "eye.slash.fill", accent: accent, onClose: onClose) {
            VStack(alignment: .leading, spacing: 22 * zoom) {
                Text("curtain.intro").font(.system(size: 25 * zoom, weight: .bold, design: .rounded))
                Text("curtain.description").foregroundStyle(.white.opacity(0.65))
                VStack(spacing: 18 * zoom) {
                    Image(systemName: "eye.slash.fill").font(.system(size: 52 * zoom, weight: .light)).foregroundStyle(accent)
                    Text("curtain.preview").font(.system(size: 21 * zoom, weight: .semibold, design: .rounded))
                    Label("curtain.escape", systemImage: "escape").foregroundStyle(.white.opacity(0.65))
                }
                .frame(maxWidth: .infinity, minHeight: 190 * zoom)
                .padding(22 * zoom)
                .background(.black, in: RoundedRectangle(cornerRadius: 18 * zoom))
                .overlay(RoundedRectangle(cornerRadius: 18 * zoom).stroke(accent.opacity(0.3)))
                Picker("curtain.duration", selection: $duration) {
                    ForEach([15, 30, 60, 120], id: \.self) { seconds in
                        Text(String(format: String(localized: "curtain.seconds_format"), seconds)).tag(seconds)
                    }
                }
                .disabled(service.session.isActive)
                if service.presentationFailed {
                    Label("curtain.no_screens", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                }
                if service.session.isActive {
                    Text(String(format: String(localized: "curtain.active_format"), service.screenCount, service.session.remainingSeconds))
                        .foregroundStyle(accent).monospacedDigit()
                    Button("curtain.dismiss", action: service.hide).buttonStyle(.borderedProminent)
                } else {
                    Button {
                        if service.show(duration: TimeInterval(duration)) { HapticManager.shared.generic() }
                    } label: { Label("curtain.show", systemImage: "rectangle.fill") }
                    .buttonStyle(.borderedProminent)
                }
                Text("curtain.exit_hint").foregroundStyle(.white.opacity(0.6))
                Text("curtain.limits").font(.system(size: 10 * zoom)).foregroundStyle(.white.opacity(0.5))
            }
            .font(.system(size: 12 * zoom))
        }
    }
}

struct ScreenCurtainOverlay: View {
    let deadline: TimeInterval
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let scale = min(1.5, max(0.65, min(geometry.size.width / 700, geometry.size.height / 500)))
            VStack(spacing: 24 * scale) {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 48 * scale, weight: .light)).foregroundStyle(.white.opacity(0.5))
                Text("curtain.overlay_title").font(.system(size: 30 * scale, weight: .semibold, design: .rounded))
                Text("curtain.escape").font(.system(size: 15 * scale)).foregroundStyle(.white.opacity(0.65))
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    let remaining = max(0, Int(ceil(deadline - ProcessInfo.processInfo.systemUptime)))
                    Text(String(format: String(localized: "curtain.countdown_format"), remaining))
                        .font(.system(size: 12 * scale, design: .monospaced)).foregroundStyle(.white.opacity(0.45))
                }
                Button("curtain.dismiss", action: onDismiss)
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .keyboardShortcut(.cancelAction)
                Text("curtain.not_locked").font(.system(size: 11 * scale)).foregroundStyle(.white.opacity(0.4))
            }
            .multilineTextAlignment(.center)
            .padding(24 * scale)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(.black)
        .foregroundStyle(.white)
        .tint(.gray)
        .preferredColorScheme(.dark)
        .onExitCommand(perform: onDismiss)
    }
}
