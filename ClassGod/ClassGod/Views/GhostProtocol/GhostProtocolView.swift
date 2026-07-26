import AppKit
import SwiftUI

struct GhostProtocolView: View {
    @ObservedObject private var controller = GhostProtocolController.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var isRecordingShortcut = false
    @State private var shortcutKey = GhostProtocolController.shared.settings.shortcutKey
    @State private var shortcutModifiers = GhostProtocolController.shared.settings.shortcutModifiers

    var onClose: () -> Void

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.white.opacity(0.1))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12 * zoomScale) {
                    statusCard
                    destinationSection
                    behaviorSection
                    shortcutSection
                    safetyNote
                }
                .padding(14 * zoomScale)
            }

            Divider().background(Color.white.opacity(0.1))
            actionBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .clipShape(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius * zoomScale)
        )
        .overlay(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius * zoomScale)
                .stroke(Color.white.opacity(0.15), lineWidth: 1 * zoomScale)
                .allowsHitTesting(false)
        )
        .onAppear { controller.refresh() }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)) { _ in
            controller.refresh()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)) { _ in
            controller.refresh()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didHideApplicationNotification)) { _ in
            controller.refresh()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didUnhideApplicationNotification)) { _ in
            controller.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .ghostProtocolWindowWillHide)) { _ in
            isRecordingShortcut = false
        }
    }

    private var header: some View {
        HStack(spacing: 10 * zoomScale) {
            Button {
                SoundEffectManager.shared.playButtonClick()
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10 * zoomScale, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                    .background(Color(white: 0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "button.close"))

            VStack(alignment: .leading, spacing: 1 * zoomScale) {
                Text("ghost.title")
                    .font(.system(size: 16 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("ghost.subtitle")
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            Button {
                SoundEffectManager.shared.playButtonClick()
                controller.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11 * zoomScale, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))
                    .frame(width: 26 * zoomScale, height: 26 * zoomScale)
                    .background(Color(white: 0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(controller.isBusy)
            .accessibilityLabel(String(localized: "button.refresh"))
        }
        .padding(.horizontal, 14 * zoomScale)
        .padding(.vertical, 10 * zoomScale)
        .background(Color(white: 0.03))
    }

    private var statusCard: some View {
        HStack(spacing: 12 * zoomScale) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 46 * zoomScale, height: 46 * zoomScale)
                Image(systemName: statusIcon)
                    .font(.system(size: 20 * zoomScale, weight: .semibold))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 3 * zoomScale) {
                Text(stateTitle)
                    .font(.system(size: 12 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(statusColor)
                Text(controller.statusMessage)
                    .font(.system(size: 10 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
            }

            Spacer()

            Text(shortcutDisplay)
                .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(controller.isShortcutRegistered ? .white : .orange)
                .padding(.horizontal, 8 * zoomScale)
                .padding(.vertical, 4 * zoomScale)
                .background(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 4 * zoomScale)
                        .stroke(statusColor.opacity(0.35), lineWidth: 1 * zoomScale)
                )
        }
        .padding(12 * zoomScale)
        .background(statusColor.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 10 * zoomScale)
                .stroke(statusColor.opacity(0.25), lineWidth: 1 * zoomScale)
        )
    }

    private var destinationSection: some View {
        sectionCard(title: "ghost.cover_title", icon: "rectangle.inset.filled.and.person.filled") {
            Picker("ghost.cover_title", selection: $controller.settings.targetBundleIdentifier) {
                ForEach(controller.destinations) { destination in
                    Label(destination.name, systemImage: destination.iconName)
                        .tag(destination.bundleIdentifier)
                }
            }
            .pickerStyle(.menu)
            .disabled(controller.state != .idle)
            .onChange(of: controller.settings.targetBundleIdentifier) { _, _ in
                SoundEffectManager.shared.play(.settingsChanged)
                HapticManager.shared.generic()
            }

            HStack(spacing: 6 * zoomScale) {
                Circle()
                    .fill(controller.isTargetAvailable ? Color.green : Color.orange)
                    .frame(width: 6 * zoomScale, height: 6 * zoomScale)
                Text(targetAvailabilityTitle)
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text("ghost.target_source")
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }

    private var behaviorSection: some View {
        sectionCard(title: "ghost.behavior_title", icon: "eye.slash.fill") {
            Toggle(isOn: $controller.settings.hideOtherApplications) {
                VStack(alignment: .leading, spacing: 2 * zoomScale) {
                    Text("ghost.hide_others")
                        .font(.system(size: 11 * zoomScale, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("ghost.hide_others_hint")
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .toggleStyle(.switch)
            .disabled(controller.state != .idle)
            .onChange(of: controller.settings.hideOtherApplications) { _, _ in
                SoundEffectManager.shared.play(.settingsChanged)
                HapticManager.shared.generic()
            }

            if controller.state == .idle {
                Text(String(format: String(localized: "ghost.preview_format"), controller.previewHideCount))
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.cyan.opacity(0.75))
            } else {
                Label("ghost.behavior_locked", systemImage: "lock.fill")
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.orange.opacity(0.75))
            }
        }
    }

    private var shortcutSection: some View {
        sectionCard(title: "ghost.shortcut_title", icon: "keyboard") {
            ShortcutPicker(
                key: $shortcutKey,
                modifiers: $shortcutModifiers,
                isRecording: $isRecordingShortcut
            )
            .disabled(controller.isBusy)
            .onChange(of: shortcutKey) { _, _ in commitShortcut() }
            .onChange(of: shortcutModifiers) { _, _ in commitShortcut() }

            HStack(spacing: 5 * zoomScale) {
                Image(systemName: controller.isShortcutRegistered ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(controller.isShortcutRegistered ? .green : .orange)
                Text(shortcutStatusTitle)
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private var safetyNote: some View {
        HStack(alignment: .top, spacing: 8 * zoomScale) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.cyan.opacity(0.8))
            Text("ghost.safety_note")
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10 * zoomScale)
        .background(Color.cyan.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 8 * zoomScale)
                .stroke(Color.cyan.opacity(0.16), lineWidth: 1 * zoomScale)
        )
    }

    private var actionBar: some View {
        Button {
            SoundEffectManager.shared.playButtonClick()
            controller.toggle()
        } label: {
            HStack(spacing: 8 * zoomScale) {
                if controller.isBusy {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: controller.state == .deployed ? "arrow.uturn.backward.circle.fill" : "bolt.shield.fill")
                }
                Text(actionTitle)
                    .font(.system(size: 12 * zoomScale, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10 * zoomScale)
            .background(actionColor)
            .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
        }
        .buttonStyle(.plain)
        .disabled(controller.isBusy || (controller.state == .idle && !controller.isTargetAvailable))
        .opacity(controller.isBusy || (controller.state == .idle && !controller.isTargetAvailable) ? 0.55 : 1)
        .accessibilityHint(
            controller.state == .idle && !controller.isTargetAvailable
                ? Text("ghost.action.unavailable_hint")
                : Text("ghost.action.hint")
        )
        .padding(12 * zoomScale)
        .background(Color(white: 0.025))
    }

    private func sectionCard<Content: View>(
        title: LocalizedStringKey,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9 * zoomScale) {
            Label(title, systemImage: icon)
                .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.65))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11 * zoomScale)
        .background(Color(white: 0.035))
        .overlay(
            RoundedRectangle(cornerRadius: 9 * zoomScale)
                .stroke(Color.white.opacity(0.1), lineWidth: 1 * zoomScale)
        )
    }

    private var stateTitle: LocalizedStringKey {
        switch controller.state {
        case .idle: return "ghost.state.ready"
        case .deploying: return "ghost.state.deploying"
        case .deployed: return "ghost.state.active"
        case .restoring: return "ghost.state.restoring"
        }
    }

    private var targetAvailabilityTitle: LocalizedStringKey {
        controller.isTargetAvailable ? "ghost.target_available" : "ghost.target_unavailable"
    }

    private var shortcutStatusTitle: LocalizedStringKey {
        controller.isShortcutRegistered ? "ghost.shortcut_ready" : "ghost.shortcut_conflict"
    }

    private var statusColor: Color {
        switch controller.state {
        case .idle: return controller.isTargetAvailable ? .cyan : .orange
        case .deploying, .restoring: return .yellow
        case .deployed: return .green
        }
    }

    private var statusIcon: String {
        switch controller.state {
        case .idle: return "shield.lefthalf.filled"
        case .deploying: return "bolt.horizontal.circle.fill"
        case .deployed: return "eye.slash.circle.fill"
        case .restoring: return "arrow.uturn.backward.circle.fill"
        }
    }

    private var actionTitle: LocalizedStringKey {
        switch controller.state {
        case .idle: return "ghost.action.deploy"
        case .deploying: return "ghost.action.deploying"
        case .deployed: return "ghost.action.restore"
        case .restoring: return "ghost.action.restoring"
        }
    }

    private var actionColor: Color {
        controller.state == .deployed ? .orange : .cyan
    }

    private var shortcutDisplay: String {
        var parts: [String] = []
        let flags = NSEvent.ModifierFlags(rawValue: shortcutModifiers)
        if flags.contains(.command) { parts.append("⌘") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.shift) { parts.append("⇧") }
        if !shortcutKey.isEmpty {
            parts.append(shortcutKey.uppercased())
        }
        return parts.isEmpty ? String(localized: "shortcut.none") : parts.joined()
    }

    private func commitShortcut() {
        DispatchQueue.main.async {
            var settings = controller.settings
            settings.shortcutKey = shortcutKey
            settings.shortcutModifiers = shortcutModifiers
            controller.settings = settings
        }
    }
}
