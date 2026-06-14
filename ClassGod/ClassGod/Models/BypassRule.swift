//
//  BypassRule.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation

enum BypassType: String, Codable, CaseIterable {
    case exitFullscreen = "exit_fullscreen"
    case preventFocusLoss = "prevent_focus_loss"
    case allowShortcuts = "allow_shortcuts"
    case injectScript = "inject_script"
    
    var displayName: String {
        switch self {
        case .exitFullscreen: return String(localized: "bypass.type.exit_fullscreen")
        case .preventFocusLoss: return String(localized: "bypass.type.prevent_focus_loss")
        case .allowShortcuts: return String(localized: "bypass.type.allow_shortcuts")
        case .injectScript: return String(localized: "bypass.type.inject_script")
        }
    }
    
    var iconName: String {
        switch self {
        case .exitFullscreen: return "arrow.down.right.and.arrow.up.left"
        case .preventFocusLoss: return "eye.slash"
        case .allowShortcuts: return "keyboard"
        case .injectScript: return "chevron.left.forwardslash.chevron.right"
        }
    }
    
    var description: String {
        switch self {
        case .exitFullscreen: return String(localized: "bypass.type.exit_fullscreen.description")
        case .preventFocusLoss: return String(localized: "bypass.type.prevent_focus_loss.description")
        case .allowShortcuts: return String(localized: "bypass.type.allow_shortcuts.description")
        case .injectScript: return String(localized: "bypass.type.inject_script.description")
        }
    }
}

struct BypassRule: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var targetURLPattern: String
    var bypassType: BypassType
    var isEnabled: Bool
    var createdAt: Date
    
    private var version: Int = 1
    
    init(
        id: UUID = UUID(),
        name: String,
        targetURLPattern: String,
        bypassType: BypassType = .exitFullscreen,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.targetURLPattern = targetURLPattern
        self.bypassType = bypassType
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
    
    static func == (lhs: BypassRule, rhs: BypassRule) -> Bool {
        lhs.id == rhs.id
    }
}
