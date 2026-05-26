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
        case .exitFullscreen: return "Exit Fullscreen"
        case .preventFocusLoss: return "Prevent Focus Loss"
        case .allowShortcuts: return "Allow Shortcuts"
        case .injectScript: return "Inject Bypass Script"
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
        case .exitFullscreen: return "Force browser to exit fullscreen/kiosk mode"
        case .preventFocusLoss: return "Block page from detecting window blur/focus loss"
        case .allowShortcuts: return "Allow ⌘+Tab and other system shortcuts"
        case .injectScript: return "Inject JavaScript to disable lockdown checks"
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
