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
                .frame(maxWidth: .infinity, minHeight: 28, alignment: .center)
                .background(isRecording ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.accentColor : Color.clear, lineWidth: 1.5)
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
                    .foregroundStyle(.secondary)
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
                
                let char = event.charactersIgnoringModifiers ?? ""
                
                if flags.subtracting([.function, .numericPad]).isEmpty && char.rangeOfCharacter(from: .letters) != nil {
                    return event
                }
                
                self.key = char.uppercased()
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
