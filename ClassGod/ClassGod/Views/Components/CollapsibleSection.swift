//
//  CollapsibleSection.swift
//  ClassGod
//

import SwiftUI

struct CollapsibleSection<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    @Binding var isExpanded: Bool
    let accentColor: Color
    @ViewBuilder let content: Content

    @State private var hover = false
    @ObservedObject private var prefs = PreferencesManager.shared

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                HapticManager.shared.generic()
                let toggle = {
                    isExpanded.toggle()
                }
                if Anim.enabled {
                    withAnimation(.easeInOut(duration: Anim.duration), toggle)
                } else {
                    toggle()
                }
            }) {
                HStack(spacing: 10 * zoomScale) {
                    Image(systemName: icon)
                        .font(.system(size: 13 * zoomScale, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .frame(width: 20 * zoomScale)

                    Text(title)
                        .font(.system(size: 12 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11 * zoomScale, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .animation(Anim.enabled ? .easeInOut(duration: Anim.duration) : nil, value: isExpanded)
                }
                .padding(.horizontal, 12 * zoomScale)
                .padding(.vertical, 10 * zoomScale)
                .background(
                    RoundedRectangle(cornerRadius: 8 * zoomScale)
                        .fill(Color(white: 0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8 * zoomScale)
                                .stroke(Color.white.opacity(hover ? 0.1 : 0.04), lineWidth: 1 * zoomScale)
                        
                            .allowsHitTesting(false))
                )
            }
            .buttonStyle(.plain)
            .onHover { hover = $0 }

            // Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12 * zoomScale) {
                    content
                }
                .padding(.horizontal, 12 * zoomScale)
                .padding(.vertical, 12 * zoomScale)
                .background(
                    RoundedRectangle(cornerRadius: 8 * zoomScale)
                        .fill(Color(white: 0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8 * zoomScale)
                                .stroke(Color.white.opacity(0.04), lineWidth: 1 * zoomScale)
                        
                            .allowsHitTesting(false))
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top).combined(with: .scale(scale: 0.97, anchor: .top))),
                    removal: .opacity.combined(with: .scale(scale: 0.97, anchor: .top))
                ))
            }
        }
    }
}

// MARK: - Static (non-Binding) variant with internal state

struct StatefulCollapsibleSection<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    let defaultExpanded: Bool
    let accentColor: Color
    @ViewBuilder let content: Content

    @State private var isExpanded: Bool

    init(
        title: LocalizedStringKey,
        icon: String,
        defaultExpanded: Bool = false,
        accentColor: Color = .white,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.defaultExpanded = defaultExpanded
        self.accentColor = accentColor
        self.content = content()
        _isExpanded = State(initialValue: defaultExpanded)
    }

    var body: some View {
        CollapsibleSection(
            title: title,
            icon: icon,
            isExpanded: $isExpanded,
            accentColor: accentColor
        ) {
            content
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        StatefulCollapsibleSection(title: "Window Behavior", icon: "macwindow", defaultExpanded: true, accentColor: .orange) {
            Toggle("Always on top", isOn: .constant(true))
            Toggle("Close on click outside", isOn: .constant(false))
        }

        StatefulCollapsibleSection(title: "Advanced", icon: "gearshape.2", defaultExpanded: false, accentColor: .red) {
            HStack {
                Text("Opacity")
                Slider(value: .constant(0.8), in: 0.5...1.0)
            }
        }
    }
    .padding()
    .background(Color.black)
    .frame(width: 400)
}
