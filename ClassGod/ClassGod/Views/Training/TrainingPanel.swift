import SwiftUI

struct TrainingPanel<Content: View>: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let accent: Color
    let onClose: () -> Void
    @ViewBuilder let content: Content

    private var zoom: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12 * zoom) {
                Button(action: onClose) {
                    Image(systemName: "minus")
                        .frame(width: 28 * zoom, height: 28 * zoom)
                        .background(.white.opacity(0.07), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("button.close")
                Image(systemName: icon).foregroundStyle(accent)
                VStack(alignment: .leading, spacing: 3 * zoom) {
                    Text(title).font(.system(size: 15 * zoom, weight: .bold, design: .rounded))
                    Text(subtitle)
                        .font(.system(size: 9 * zoom, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer(minLength: 0)
            }
            .padding(16 * zoom)
            .background(.black.opacity(0.3))
            Divider().overlay(accent.opacity(0.2))
            ScrollView {
                content.padding(22 * zoom).frame(maxWidth: .infinity)
            }
        }
        .background(LinearGradient(colors: [accent.opacity(0.16), .black], startPoint: .topLeading, endPoint: .bottomTrailing))
        .background(.black)
        .foregroundStyle(.white)
        .tint(accent)
        .buttonStyle(TrainingButtonStyle(accent: accent, zoom: zoom))
        .preferredColorScheme(.dark)
        .onExitCommand(perform: onClose)
    }
}

struct TrainingButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let accent: Color
    let zoom: CGFloat
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        let color = configuration.role == .destructive ? Color(red: 1, green: 0.4, blue: 0.5) : accent
        return configuration.label
            .font(.system(size: 12 * zoom, weight: .semibold))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12 * zoom)
            .padding(.vertical, 7 * zoom)
            .frame(minHeight: 30 * zoom)
            .foregroundStyle(prominent ? .black : configuration.role == .destructive ? color : .white)
            .background(prominent ? color : .white.opacity(0.075), in: RoundedRectangle(cornerRadius: 8 * zoom))
            .overlay(RoundedRectangle(cornerRadius: 8 * zoom).stroke(color.opacity(prominent ? 0 : 0.25)))
            .contentShape(RoundedRectangle(cornerRadius: 8 * zoom))
            .opacity(!isEnabled ? 0.35 : configuration.isPressed ? 0.7 : 1)
    }
}
