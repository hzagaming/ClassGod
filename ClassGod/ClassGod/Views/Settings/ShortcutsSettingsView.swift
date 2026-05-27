//
//  ShortcutsSettingsView.swift
//  ClassGod
//

import SwiftUI
import AppKit
import Carbon

struct ShortcutsSettingsView: View {
    @ObservedObject var prefs = PreferencesManager.shared
    @State private var isRecordingPopoverShortcut = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0
    @State private var localMonitor: Any?

    var displayShortcut: String {
        let flags = NSEvent.ModifierFlags(rawValue: UInt(prefs.preferences.showPopoverModifiers))
        var parts: [String] = []
        if flags.contains(.command) { parts.append("⌘") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.shift) { parts.append("⇧") }
        let keyName = keyCodeToString(UInt32(prefs.preferences.showPopoverKeyCode))
        if !keyName.isEmpty {
            parts.append(keyName)
        }
        return parts.isEmpty ? String(localized: "shortcut.none") : parts.joined(separator: "")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                StatefulCollapsibleSection(
                    title: String(localized: "section.global_shortcut"),
                    icon: "keyboard",
                    defaultExpanded: true,
                    accentColor: .cyan
                ) {
                    HStack {
                        Text(String(localized: "setting.show_panel"))
                        Spacer()

                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isRecordingPopoverShortcut ? Color.white.opacity(0.12) : Color(white: 0.12))
                                .frame(width: 120, height: 36)

                            if isRecordingPopoverShortcut {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(pulseOpacity), lineWidth: 1)
                                    .frame(width: 120, height: 36)
                                    .scaleEffect(pulseScale)
                            }

                            Text(isRecordingPopoverShortcut ? String(localized: "shortcut.press_keys") : displayShortcut)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundStyle(isRecordingPopoverShortcut ? .white : .white.opacity(0.8))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(width: 120, height: 36)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            SoundEffectManager.shared.playButtonClick()
                            if isRecordingPopoverShortcut {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }
                        .accessibilityLabel(String(localized: "accessibility.record_global"))
                        .accessibilityHint(isRecordingPopoverShortcut ? String(localized: "accessibility.press_combination") : String(localized: "accessibility.tap_to_start"))
                        .accessibilityAddTraits(.isButton)

                        Button(String(localized: "button.reset")) {
                            SoundEffectManager.shared.playButtonClick()
                            prefs.preferences.showPopoverKeyCode = AppPreferences.default.showPopoverKeyCode
                            prefs.preferences.showPopoverModifiers = AppPreferences.default.showPopoverModifiers
                        }
                        .disabled(
                            prefs.preferences.showPopoverKeyCode == AppPreferences.default.showPopoverKeyCode &&
                            prefs.preferences.showPopoverModifiers == AppPreferences.default.showPopoverModifiers
                        )
                        .pressScale(0.9)
                    }

                    Text(String(localized: "shortcut.tip.caption"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                StatefulCollapsibleSection(
                    title: "Shortcut Conflict",
                    icon: "exclamationmark.triangle",
                    defaultExpanded: false,
                    accentColor: .orange
                ) {
                    Toggle("Suppress System Shortcut Conflicts", isOn: $prefs.preferences.suppressSystemShortcutConflict)

                    Text("When enabled, ClassGod will try to override system shortcuts that conflict with your chosen global shortcut. May require Accessibility permissions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                StatefulCollapsibleSection(
                    title: String(localized: "section.tips"),
                    icon: "lightbulb",
                    defaultExpanded: false,
                    accentColor: .yellow
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(String(localized: "tip.avoid_conflict"), systemImage: "exclamationmark.triangle")
                        Label(String(localized: "tip.per_tab_shortcuts"), systemImage: "keyboard")
                        Label(String(localized: "tip.restart"), systemImage: "arrow.clockwise")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .onChange(of: isRecordingPopoverShortcut) { _, recording in
            if recording && Anim.enabled {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulseScale = 1.04
                    pulseOpacity = 0.4
                }
            } else {
                if Anim.enabled {
                    withAnimation(.easeOut(duration: Anim.duration)) {
                        pulseScale = 1.0
                        pulseOpacity = 1.0
                    }
                } else {
                    pulseScale = 1.0
                    pulseOpacity = 1.0
                }
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        guard !isRecordingPopoverShortcut else { return }
        isRecordingPopoverShortcut = true
        HapticManager.shared.generic()

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [self] event in
            handleRecordingEvent(event)
        }
    }

    private func stopRecording() {
        isRecordingPopoverShortcut = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func handleRecordingEvent(_ event: NSEvent) -> NSEvent? {
        guard isRecordingPopoverShortcut else { return event }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard event.type == .keyDown else { return nil }

        let specialKeyCodes: Set<UInt16> = [
            0x24, 0x30, 0x31, 0x33, 0x35, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3F,
            0x7B, 0x7C, 0x7D, 0x7E
        ]

        if specialKeyCodes.contains(event.keyCode) {
            return nil
        }

        let char = event.charactersIgnoringModifiers ?? ""
        let userModifiers = flags.subtracting([.function, .numericPad])

        if userModifiers.isEmpty && char.rangeOfCharacter(from: .letters) != nil {
            return nil
        }

        prefs.preferences.showPopoverKeyCode = UInt32(event.keyCode)
        prefs.preferences.showPopoverModifiers = UInt32(flags.rawValue)
        SoundEffectManager.shared.playShortcutRecorded()
        HapticManager.shared.success()
        stopRecording()
        return nil
    }

    private func keyCodeToString(_ keyCode: UInt32) -> String {
        let map: [UInt32: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H", 0x05: "G",
            0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V", 0x0B: "B", 0x0C: "Q",
            0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y", 0x11: "T", 0x12: "1",
            0x13: "2", 0x14: "3", 0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=",
            0x19: "9", 0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
            0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P", 0x25: "L",
            0x26: "J", 0x27: "'", 0x28: "K", 0x29: ";", 0x2A: "\\", 0x2B: ",",
            0x2C: "/", 0x2D: "N", 0x2E: "M", 0x2F: ".", 0x32: "`",
            0x7A: "F1", 0x78: "F2", 0x63: "F3", 0x76: "F4", 0x60: "F5",
            0x61: "F6", 0x62: "F7", 0x64: "F8", 0x65: "F9", 0x6D: "F10",
            0x67: "F11", 0x6F: "F12"
        ]
        return map[keyCode] ?? String(format: String(localized: "shortcut.key_format"), keyCode)
    }
}

#Preview {
    ShortcutsSettingsView()
        .frame(width: 480, height: 600)
        .background(Color.black)
}
