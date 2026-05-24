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
        case .activateExisting: return String(localized: "switch.activate_existing")
        case .alwaysNewTab: return String(localized: "switch.always_new_tab")
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
        case .exact: return String(localized: "match.exact")
        case .prefix: return String(localized: "match.prefix")
        case .hostOnly: return String(localized: "match.host_only")
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
        case .launchAndOpen: return String(localized: "not_running.launch_open")
        case .launchOnly: return String(localized: "not_running.launch_only")
        case .doNothing: return String(localized: "not_running.do_nothing")
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
        case .default: return String(localized: "icon.default")
        case .fill: return String(localized: "icon.fill")
        case .plain: return String(localized: "icon.plain")
        case .bolt: return String(localized: "icon.bolt")
        case .eye: return String(localized: "icon.eye")
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
        case .system: return String(localized: "theme.system")
        case .light: return String(localized: "theme.light")
        case .dark: return String(localized: "theme.dark")
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
        case .instant: return String(localized: "speed.instant")
        case .fast: return String(localized: "speed.fast")
        case .normal: return String(localized: "speed.normal")
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
    var autoDetectOnShow: Bool
    var enableKeyboardNavigation: Bool
    var switchDelayMs: Double
    
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
    var panelCornerRadius: Double
    var theme: AppTheme
    var showURLPreview: Bool
    var rowHeight: Double
    var showBrowserIcon: Bool
    var showShortcutBadge: Bool
    var useCompactMode: Bool
    var showTabCountBadge: Bool
    
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
    var useInstantAnimations: Bool
    
    // MARK: - Defaults
    static let `default` = AppPreferences(
        launchAtLogin: false,
        showPopoverOnLaunch: false,
        showToastNotifications: true,
        toastDuration: 1.5,
        switchBehavior: .activateExisting,
        urlMatchPrecision: .prefix,
        autoDetectOnShow: true,
        enableKeyboardNavigation: true,
        switchDelayMs: 0,
        showPopoverKeyCode: 0x08,
        showPopoverModifiers: UInt32(cmdKey | shiftKey),
        defaultBrowser: nil,
        browserNotRunningBehavior: .launchAndOpen,
        menuBarIconStyle: .fill,
        panelWidth: 320,
        panelMaxHeight: 400,
        panelCornerRadius: 12,
        theme: .system,
        showURLPreview: true,
        rowHeight: 44,
        showBrowserIcon: true,
        showShortcutBadge: true,
        useCompactMode: false,
        showTabCountBadge: false,
        version: 1,
        animationSpeed: .fast,
        enableDebugLogging: false,
        enableSoundEffects: true,
        enableHapticFeedback: true,
        confirmBeforeDelete: true,
        confirmBeforeClear: true,
        maxTabsInPopover: 50,
        useInstantAnimations: false
    )
}
