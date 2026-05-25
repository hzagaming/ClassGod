//
//  ShortcutPicker.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI
import Carbon

struct ShortcutPicker: View {
    @Binding var key: String
    @Binding var modifiers: UInt
    @Binding var isRecording: Bool

    @State private var localMonitor: Any?

    var body: some View {
        HStack {
            Text(displayString)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 28, alignment: .center)
                .background(isRecording ? Color.white.opacity(0.15) : Color(white: 0.1))
                .overlay(
                    Rectangle()
                        .stroke(isRecording ? Color.white : Color.white.opacity(0.15), lineWidth: 1)
                )
                .onTapGesture {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }
                .accessibilityLabel(String(localized: "accessibility.record_shortcut"))
                .accessibilityHint(isRecording ? String(localized: "accessibility.press_combination") : String(localized: "accessibility.tap_to_record"))
                .accessibilityAddTraits(.isButton)

            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                key = ""
                modifiers = 0
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            .disabled(key.isEmpty && modifiers == 0)
            .accessibilityLabel(String(localized: "button.clear"))
        }
        .onDisappear {
            stopRecording()
        }
    }

    private var displayString: String {
        if key.isEmpty && modifiers == 0 {
            return isRecording ? String(localized: "shortcut.press") : String(localized: "shortcut.tap_to_set")
        }
        var parts: [String] = []
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        if flags.contains(.command) { parts.append("⌘") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.shift) { parts.append("⇧") }
        if !key.isEmpty {
            parts.append(key.uppercased())
        }
        return parts.joined(separator: "") + (isRecording ? " …" : "")
    }

    private func startRecording() {
        isRecording = true

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [self] event in
            guard self.isRecording else { return event }

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            if event.type == .keyDown {
                let specialKeyCodes: Set<UInt16> = [
                    0x24, // Return
                    0x30, // Tab
                    0x31, // Space
                    0x33, // Delete
                    0x35, // Escape
                    0x37, // Command
                    0x38, // Shift
                    0x39, // CapsLock
                    0x3A, // Option
                    0x3B, // Control
                    0x3F, // Function
                    0x7B, // Left
                    0x7C, // Right
                    0x7D, // Down
                    0x7E, // Up
                ]

                if specialKeyCodes.contains(event.keyCode) {
                    return event
                }

                let isFunctionKey = functionKeyName(for: event.keyCode) != nil
                let keyName = keyName(for: event)

                if !isFunctionKey &&
                    flags.subtracting([.function, .numericPad]).isEmpty &&
                    keyName.rangeOfCharacter(from: .letters) != nil {
                    return event
                }

                self.key = keyName
                self.modifiers = flags.rawValue
                self.stopRecording()
                return nil
            }

            return event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func keyName(for event: NSEvent) -> String {
        if let functionKey = functionKeyName(for: event.keyCode) {
            return functionKey
        }

        return (event.charactersIgnoringModifiers ?? "").uppercased()
    }

    private func functionKeyName(for keyCode: UInt16) -> String? {
        let map: [UInt16: String] = [
            0x7A: "F1", 0x78: "F2", 0x63: "F3",
            0x76: "F4", 0x60: "F5", 0x61: "F6",
            0x62: "F7", 0x64: "F8", 0x65: "F9",
            0x6D: "F10", 0x67: "F11", 0x6F: "F12"
        ]
        return map[keyCode]
    }
}

#Preview {
    struct Preview: View {
        @State var key = ""
        @State var modifiers: UInt = 0
        @State var isRecording = false

        var body: some View {
            ShortcutPicker(key: $key, modifiers: $modifiers, isRecording: $isRecording)
                .padding()
        }
    }
    return Preview()
}
