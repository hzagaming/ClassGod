//
//  AssessPrepHack.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation

enum AssessPrepBypassTechnique: String, Codable, CaseIterable, Identifiable {
    case panicSwitch = "panic_switch"
    case focusGuard = "focus_guard"
    case screenSpoof = "screen_spoof"
    case keyboardUnlock = "keyboard_unlock"
    case processSuspend = "process_suspend"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .panicSwitch: return String(localized: "panic.technique.panic_switch")
        case .focusGuard: return String(localized: "panic.technique.focus_guard")
        case .screenSpoof: return String(localized: "panic.technique.screen_spoof")
        case .keyboardUnlock: return String(localized: "panic.technique.keyboard_unlock")
        case .processSuspend: return String(localized: "panic.technique.process_suspend")
        }
    }
    
    var iconName: String {
        switch self {
        case .panicSwitch: return "bolt.fill"
        case .focusGuard: return "shield.fill"
        case .screenSpoof: return "eye.slash.fill"
        case .keyboardUnlock: return "keyboard.fill"
        case .processSuspend: return "pause.fill"
        }
    }
    
    var description: String {
        switch self {
        case .panicSwitch: return String(localized: "panic.technique.panic_switch.description")
        case .focusGuard: return String(localized: "panic.technique.focus_guard.description")
        case .screenSpoof: return String(localized: "panic.technique.screen_spoof.description")
        case .keyboardUnlock: return String(localized: "panic.technique.keyboard_unlock.description")
        case .processSuspend: return String(localized: "panic.technique.process_suspend.description")
        }
    }
}

struct PanicApp: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var bundleIdentifier: String
    var iconName: String
    var bypassTechnique: AssessPrepBypassTechnique
    var isEnabled: Bool
    var createdAt: Date
    
    private var version: Int = 1
    
    init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String,
        iconName: String = "app.fill",
        bypassTechnique: AssessPrepBypassTechnique = .panicSwitch,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.iconName = iconName
        self.bypassTechnique = bypassTechnique
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
    
    static func == (lhs: PanicApp, rhs: PanicApp) -> Bool {
        lhs.id == rhs.id
    }
}

// Predefined panic apps
extension PanicApp {
    static let presets: [PanicApp] = [
        PanicApp(name: "Safari", bundleIdentifier: "com.apple.Safari", iconName: "safari.fill", bypassTechnique: .panicSwitch),
        PanicApp(name: "Notes", bundleIdentifier: "com.apple.Notes", iconName: "note.text", bypassTechnique: .panicSwitch),
        PanicApp(name: "Calculator", bundleIdentifier: "com.apple.calculator", iconName: "function", bypassTechnique: .panicSwitch),
        PanicApp(name: "Terminal", bundleIdentifier: "com.apple.Terminal", iconName: "terminal.fill", bypassTechnique: .panicSwitch),
        PanicApp(name: "TextEdit", bundleIdentifier: "com.apple.TextEdit", iconName: "doc.text", bypassTechnique: .panicSwitch),
        PanicApp(name: "Preview", bundleIdentifier: "com.apple.Preview", iconName: "eye", bypassTechnique: .panicSwitch),
    ]
}
