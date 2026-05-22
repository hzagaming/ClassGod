//
//  AppPreferences.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import Carbon

enum SwitchBehavior: String, Codable, CaseIterable, Identifiable {
    case activateExisting = "activateExisting"
    case alwaysNewTab = "alwaysNewTab"
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .activateExisting: return "Activate existing tab if found"
        case .alwaysNewTab: return "Always open in new tab"
        }
    }
}

enum URLMatchPrecision: String, Codable, CaseIterable, Identifiable {
    case exact = "exact"
    case prefix = "prefix"
    case hostOnly = "hostOnly"
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .exact: return "Exact URL match"
        case .prefix: return "Prefix match (recommended)"
        case .hostOnly: return "Host only (e.g. google.com)"
        }
    }
}

enum BrowserNotRunningBehavior: String, Codable, CaseIterable, Identifiable {
    case launchAndOpen = "launchAndOpen"
    case launchOnly = "launchOnly"
    case doNothing = "doNothing"
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .launchAndOpen: return "Launch browser and open URL"
        case .launchOnly: return "Launch browser only"
        case .doNothing: return "Do nothing"
        }
    }
}

enum MenuBarIconStyle: String, Codable, CaseIterable, Identifiable {
    case `default` = "default"
    case fill = "fill"
    case plain = "plain"
    case bolt = "bolt"
    case eye = "eye"
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .default: return "Default (Link Circle)"
        case .fill: return "Link Circle Fill"
        case .plain: return "Link"
        case .bolt: return "Lightning Bolt"
        case .eye: return "Eye"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .default: return "link.circle"
        case .fill: return "link.circle.fill"
        case .plain: return "link"
        case .bolt: return "bolt.circle.fill"
        case .eye: return "eye.circle.fill"
        }
    }
}

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return "Follow System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum AnimationSpeed: String, Codable, CaseIterable, Identifiable {
    case instant = "instant"
    case fast = "fast"
    case normal = "normal"
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .instant: return "Off (Instant)"
        case .fast: return "Fast"
        case .normal: return "Normal"
        }
    }
    
    var duration: Double {
        switch self {
        case .instant: return 0
        case .fast: return 0.08
        case .normal: return 0.2
        }
    }
    
    var isEnabled: Bool {
        self != .instant
    }
}

struct AppPreferences: Codable, Equatable {
    // MARK: - General
    var launchAtLogin: Bool
    var showPopoverOnLaunch: Bool
    var showToastNotifications: Bool
    var toastDuration: Double
    var switchBehavior: SwitchBehavior
    var urlMatchPrecision: URLMatchPrecision
    
    // MARK: - Shortcuts
    var showPopoverKeyCode: UInt32
    var showPopoverModifiers: UInt32
    
    // MARK: - Browser
    var defaultBrowser: BrowserType?
    var browserNotRunningBehavior: BrowserNotRunningBehavior
    
    // MARK: - Appearance
    var menuBarIconStyle: MenuBarIconStyle
    var panelWidth: Double
    var panelMaxHeight: Double
    var theme: AppTheme
    var showURLPreview: Bool
    var rowHeight: Double
    var showBrowserIcon: Bool
    var showShortcutBadge: Bool
    var useCompactMode: Bool
    
    // MARK: - Version
    var version: Int
    
    // MARK: - Advanced
    var animationSpeed: AnimationSpeed
    var enableDebugLogging: Bool
    var enableSoundEffects: Bool
    var enableHapticFeedback: Bool
    var confirmBeforeDelete: Bool
    var confirmBeforeClear: Bool
    var maxTabsInPopover: Int
    
    // MARK: - Defaults
    static let `default` = AppPreferences(
        launchAtLogin: false,
        showPopoverOnLaunch: false,
        showToastNotifications: true,
        toastDuration: 1.5,
        switchBehavior: .activateExisting,
        urlMatchPrecision: .prefix,
        showPopoverKeyCode: 0x08, // kVK_ANSI_C
        showPopoverModifiers: UInt32(cmdKey | shiftKey),
        defaultBrowser: nil,
        browserNotRunningBehavior: .launchAndOpen,
        menuBarIconStyle: .fill,
        panelWidth: 320,
        panelMaxHeight: 400,
        theme: .system,
        showURLPreview: true,
        rowHeight: 44,
        showBrowserIcon: true,
        showShortcutBadge: true,
        useCompactMode: false,
        version: 1,
        animationSpeed: .fast,
        enableDebugLogging: false,
        enableSoundEffects: true,
        enableHapticFeedback: true,
        confirmBeforeDelete: true,
        confirmBeforeClear: true,
        maxTabsInPopover: 50
    )
}
