//
//  SettingsComponents.swift
//  ClassGod
//

import SwiftUI

// MARK: - Toggle Row

struct SettingsToggleRow: View {
    let icon: String?
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey? = nil
    @Binding var isOn: Bool
    @State private var isHovered = false
    @ObservedObject private var prefs = PreferencesManager.shared

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        HStack(spacing: 10 * zoomScale) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12 * zoomScale))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 18 * zoomScale)
            }

            VStack(alignment: .leading, spacing: 2 * zoomScale) {
                Text(title)
                    .font(.system(size: 12 * zoomScale, weight: .medium))
                    .foregroundStyle(.white)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10 * zoomScale))
                        .foregroundStyle(.white.opacity(0.35))
                        .lineLimit(1)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, 10 * zoomScale)
        .padding(.vertical, 8 * zoomScale)
        .background(
            RoundedRectangle(cornerRadius: 6 * zoomScale)
                .fill(isHovered ? Color.white.opacity(0.04) : Color.clear)
        )
        .onHover { isHovered = $0 }
        .animation(Anim.enabled ? .easeInOut(duration: Anim.duration) : nil, value: isHovered)
        .onChange(of: isOn) { _, _ in
            SoundEffectManager.shared.playButtonClick()
            HapticManager.shared.generic()
        }
    }
}

// MARK: - Slider Row

struct SettingsSliderRow: View {
    let label: LocalizedStringKey
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    @State private var isHovered = false
    @State private var lastFeedbackAt = Date.distantPast
    @ObservedObject private var prefs = PreferencesManager.shared

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    private let displayFormatter: (Double) -> String

    init(
        label: LocalizedStringKey,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
        self.displayFormatter = { String(format: format, $0) }
    }

    init(
        label: LocalizedStringKey,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        suffix: String
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
        self.displayFormatter = { "\(Int($0))\(suffix)" }
    }

    init(
        label: LocalizedStringKey,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String,
        transform: @escaping (Double) -> Int
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
        self.displayFormatter = { String(format: format, Double(transform($0))) }
    }

    var body: some View {
        HStack(spacing: 12 * zoomScale) {
            Text(label)
                .font(.system(size: 12 * zoomScale, weight: .medium))
                .foregroundStyle(.white)
                .frame(minWidth: 100 * zoomScale, alignment: .leading)

            Slider(value: $value, in: range, step: step)
                .frame(height: 16 * zoomScale)

            Text(displayFormatter(value))
                .font(.system(size: 11 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 50 * zoomScale, alignment: .trailing)
        }
        .padding(.horizontal, 10 * zoomScale)
        .padding(.vertical, 6 * zoomScale)
        .background(
            RoundedRectangle(cornerRadius: 6 * zoomScale)
                .fill(isHovered ? Color.white.opacity(0.03) : Color.clear)
        )
        .onHover { isHovered = $0 }
        .animation(Anim.enabled ? .easeInOut(duration: Anim.duration) : nil, value: isHovered)
        .onChange(of: value) { _, _ in
            playThrottledFeedback()
        }
    }

    private func playThrottledFeedback() {
        let now = Date()
        guard now.timeIntervalSince(lastFeedbackAt) >= 0.18 else { return }
        lastFeedbackAt = now
        SoundEffectManager.shared.playButtonClick()
        HapticManager.shared.generic()
    }
}

// MARK: - Picker Row

struct SettingsPickerRow<T: Hashable>: View {
    let label: LocalizedStringKey
    @Binding var selection: T
    let options: [T]
    let displayName: (T) -> String
    let style: PickerStyleType
    @State private var isHovered = false
    @ObservedObject private var prefs = PreferencesManager.shared

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    enum PickerStyleType {
        case segmented
        case radio
        case menu
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8 * zoomScale) {
            Text(label)
                .font(.system(size: 12 * zoomScale, weight: .medium))
                .foregroundStyle(.white)

            switch style {
            case .segmented:
                Picker("", selection: $selection) {
                    ForEach(options, id: \.self) { option in
                        Text(displayName(option)).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

            case .radio:
                Picker("", selection: $selection) {
                    ForEach(options, id: \.self) { option in
                        Text(displayName(option)).tag(option)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()

            case .menu:
                Picker("", selection: $selection) {
                    ForEach(options, id: \.self) { option in
                        Text(displayName(option)).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
        .padding(.horizontal, 10 * zoomScale)
        .padding(.vertical, 8 * zoomScale)
        .background(
            RoundedRectangle(cornerRadius: 6 * zoomScale)
                .fill(isHovered ? Color.white.opacity(0.03) : Color.clear)
        )
        .onHover { isHovered = $0 }
        .animation(Anim.enabled ? .easeInOut(duration: Anim.duration) : nil, value: isHovered)
        .onChange(of: selection) { _, _ in
            SoundEffectManager.shared.playButtonClick()
            HapticManager.shared.generic()
        }
    }
}

// MARK: - Action Row

struct SettingsActionRow: View {
    let icon: String?
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey? = nil
    let action: () -> Void
    var isDestructive: Bool = false
    @State private var isHovered = false
    @ObservedObject private var prefs = PreferencesManager.shared

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        Button(action: {
            SoundEffectManager.shared.playButtonClick()
            HapticManager.shared.generic()
            action()
        }) {
            HStack(spacing: 10 * zoomScale) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12 * zoomScale))
                        .foregroundStyle(isDestructive ? .red.opacity(0.7) : .white.opacity(0.4))
                        .frame(width: 18 * zoomScale)
                }

                VStack(alignment: .leading, spacing: 2 * zoomScale) {
                    Text(title)
                        .font(.system(size: 12 * zoomScale, weight: .medium))
                        .foregroundStyle(isDestructive ? .red.opacity(0.9) : .white)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 10 * zoomScale))
                            .foregroundStyle(.white.opacity(0.35))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10 * zoomScale, weight: .bold))
                    .foregroundStyle(.white.opacity(0.2))
            }
            .padding(.horizontal, 10 * zoomScale)
            .padding(.vertical, 8 * zoomScale)
            .background(
                RoundedRectangle(cornerRadius: 6 * zoomScale)
                    .fill(isHovered ? Color.white.opacity(0.06) : Color.white.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6 * zoomScale)
                            .stroke(Color.white.opacity(isHovered ? 0.1 : 0.04), lineWidth: 1 * zoomScale)
                    
                        .allowsHitTesting(false))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(Anim.enabled ? .easeInOut(duration: Anim.duration) : nil, value: isHovered)
    }
}

// MARK: - Section Reset Button

struct SectionResetButton: View {
    let action: () -> Void
    @State private var isHovered = false
    @ObservedObject private var prefs = PreferencesManager.shared

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        Button(action: {
            SoundEffectManager.shared.playButtonClick()
            HapticManager.shared.generic()
            action()
        }) {
            HStack(spacing: 4 * zoomScale) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 8 * zoomScale, weight: .bold))
                Text("button.reset")
                    .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(.white.opacity(0.35))
            .padding(.horizontal, 8 * zoomScale)
            .padding(.vertical, 3 * zoomScale)
            .background(
                Capsule()
                    .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5 * zoomScale))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(Anim.enabled ? .easeInOut(duration: Anim.duration) : nil, value: isHovered)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        SettingsToggleRow(
            icon: "bell",
            title: "Show Toast Notifications",
            subtitle: "Display feedback after actions",
            isOn: .constant(true)
        )

        SettingsSliderRow(
            label: "Window Opacity",
            value: .constant(0.85),
            range: 0.5...1.0,
            step: 0.05,
            format: "%.0f%%",
            transform: { Int($0 * 100) }
        )

        SettingsActionRow(
            icon: "externaldrive",
            title: "Export Preferences",
            subtitle: "Save settings to a file",
            action: {}
        )
    }
    .padding()
    .background(Color.black)
    .frame(width: 420)
}
