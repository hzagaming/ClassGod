//
//  ShortcutManager.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Cocoa
import Carbon

final class ShortcutManager {
    static let shared = ShortcutManager()
    private static let hotKeySignature = FourCharCode(bitPattern: 0x434C4744) // 'CLGD'
    
    private var registeredHotKeys: [UUID: EventHotKeyRef] = [:]
    private var callbackMap: [UInt32: UUID] = [:]
    private var nextHotKeyID: UInt32 = 1
    private var eventHandlerRef: EventHandlerRef?
    
    private var hotKeyHandlers: [(UUID) -> Void] = []
    
    private init() {}
    
    deinit {
        unregisterAllShortcuts()
        removeEventHandler()
    }
    
    // MARK: - Carbon Event Hot Keys
    
    func registerShortcut(for tab: BrowserTab) -> Bool {
        unregisterShortcut(for: tab.id)
        
        guard tab.isValidShortcut else { return false }
        
        let keyCode = keyCodeForCharacter(tab.shortcutKey)
        guard keyCode != UInt32.max else {
            print("[ShortcutManager] Unsupported key: \(tab.shortcutKey)")
            return false
        }
        
        let carbonModifiers = cocoaToCarbonModifiers(tab.shortcutModifiers)
        
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.hotKeySignature, id: nextHotKeyID)
        nextHotKeyID += 1
        
        let status = RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        guard status == noErr, let ref = hotKeyRef else {
            print("[ShortcutManager] Failed to register hotkey for \(tab.title)")
            return false
        }
        
        registeredHotKeys[tab.id] = ref
        callbackMap[hotKeyID.id] = tab.id
        
        installHotKeyHandlerIfNeeded()
        
        return true
    }
    
    func registerShortcut(for target: SwitchTarget) -> Bool {
        unregisterShortcut(for: target.id)
        
        guard target.isValidShortcut else { return false }
        
        let keyCode = keyCodeForCharacter(target.shortcutKey)
        guard keyCode != UInt32.max else {
            print("[ShortcutManager] Unsupported key: \(target.shortcutKey)")
            return false
        }
        
        let carbonModifiers = cocoaToCarbonModifiers(target.shortcutModifiers)
        
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.hotKeySignature, id: nextHotKeyID)
        nextHotKeyID += 1
        
        let status = RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        guard status == noErr, let ref = hotKeyRef else {
            print("[ShortcutManager] Failed to register hotkey for \(target.name)")
            return false
        }
        
        registeredHotKeys[target.id] = ref
        callbackMap[hotKeyID.id] = target.id
        
        installHotKeyHandlerIfNeeded()
        
        return true
    }
    
    func unregisterShortcut(for id: UUID) {
        guard let ref = registeredHotKeys[id] else { return }
        let status = UnregisterEventHotKey(ref)
        if status != noErr {
            print("[ShortcutManager] Warning: Failed to unregister hotkey (status: \(status))")
        }
        registeredHotKeys.removeValue(forKey: id)
        
        if let pair = callbackMap.first(where: { $0.value == id }) {
            callbackMap.removeValue(forKey: pair.key)
        }
    }
    
    /// Nuclear option: unregister ALL shortcuts and clear all state.
    /// Only call this on app termination or true global reset.
    func unregisterAllShortcuts() {
        for (_, ref) in registeredHotKeys {
            UnregisterEventHotKey(ref)
        }
        registeredHotKeys.removeAll()
        callbackMap.removeAll()
        nextHotKeyID = 1
    }
    
    func addHotKeyHandler(_ handler: @escaping (UUID) -> Void) {
        hotKeyHandlers.append(handler)
    }
    
    // MARK: - Hot Key Handler
    
    private func installHotKeyHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }
        
        let callback: EventHandlerUPP = { _, eventRef, _ -> OSStatus in
            guard let event = eventRef else { return OSStatus(eventNotHandledErr) }
            
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            guard status == noErr else { return OSStatus(eventNotHandledErr) }
            
            if hotKeyID.signature == ShortcutManager.hotKeySignature,
               let targetID = ShortcutManager.shared.callbackMap[hotKeyID.id] {
                for handler in ShortcutManager.shared.hotKeyHandlers {
                    handler(targetID)
                }
                return noErr
            }
            
            return OSStatus(eventNotHandledErr)
        }
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        var handler: EventHandlerRef?
        let installStatus = InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventType,
            nil,
            &handler
        )
        
        if installStatus == noErr {
            eventHandlerRef = handler
        } else {
            print("[ShortcutManager] Warning: Failed to install event handler (status: \(installStatus))")
        }
    }
    
    private func removeEventHandler() {
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
    }
    
    // MARK: - Modifier Conversion
    
    private func cocoaToCarbonModifiers(_ cocoaFlags: UInt) -> UInt32 {
        let flags = NSEvent.ModifierFlags(rawValue: cocoaFlags)
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.option)  { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.shift)   { carbon |= UInt32(shiftKey) }
        return carbon
    }
    
    // MARK: - Key Code Mapping
    
    private func keyCodeForCharacter(_ character: String) -> UInt32 {
        let upper = character.uppercased()
        
        let map: [String: UInt32] = [
            "A": 0x00, "S": 0x01, "D": 0x02, "F": 0x03,
            "H": 0x04, "G": 0x05, "Z": 0x06, "X": 0x07,
            "C": 0x08, "V": 0x09, "B": 0x0B, "Q": 0x0C,
            "W": 0x0D, "E": 0x0E, "R": 0x0F, "Y": 0x10,
            "T": 0x11, "1": 0x12, "2": 0x13, "3": 0x14,
            "4": 0x15, "6": 0x16, "5": 0x17, "=": 0x18,
            "9": 0x19, "7": 0x1A, "-": 0x1B, "8": 0x1C,
            "0": 0x1D, "]": 0x1E, "O": 0x1F, "U": 0x20,
            "[": 0x21, "I": 0x22, "P": 0x23, "L": 0x25,
            "J": 0x26, "'": 0x27, "K": 0x28, ";": 0x29,
            "\\": 0x2A, ",": 0x2B, "/": 0x2C, "N": 0x2D,
            "M": 0x2E, ".": 0x2F, "`": 0x32,
            "F1": 0x7A, "F2": 0x78, "F3": 0x63,
            "F4": 0x76, "F5": 0x60, "F6": 0x61,
            "F7": 0x62, "F8": 0x64, "F9": 0x65,
            "F10": 0x6D, "F11": 0x67, "F12": 0x6F
        ]
        
        return map[upper] ?? UInt32.max
    }
}
