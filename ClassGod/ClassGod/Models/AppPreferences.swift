//
//  AppPreferences.swift
//  ClassGod
//

import Foundation
import AppKit
import Carbon

// MARK: - Enums

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
        case .fast: return 0.03
        case .normal: return 0.1
        }
    }

    var isEnabled: Bool {
        self != .instant
    }
}

enum WindowMaximizeBehavior: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case fillScreen = "fillScreen"
    case fullScreenBorderless = "fullScreenBorderless"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .none: return String(localized: "maximize.none")
        case .fillScreen: return String(localized: "maximize.fill_screen")
        case .fullScreenBorderless: return String(localized: "maximize.fullscreen_borderless")
        }
    }
}

enum ListDividerStyle: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case thin = "thin"
    case dashed = "dashed"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .none: return String(localized: "divider.none")
        case .thin: return String(localized: "divider.thin")
        case .dashed: return String(localized: "divider.dashed")
        }
    }
}

enum LanguageOverride: String, Codable, CaseIterable, Identifiable {
    case system = "system"
    case zhHans = "zh-Hans"
    case en = "en"
    case ja = "ja"
    case ko = "ko"
    case de = "de"
    case fr = "fr"
    case es = "es"
    case pt = "pt"
    case ru = "ru"
    case zhHant = "zh-Hant"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return String(localized: "lang.system")
        case .zhHans: return "简体中文"
        case .en: return "English"
        case .ja: return "日本語"
        case .ko: return "한국어"
        case .de: return "Deutsch"
        case .fr: return "Français"
        case .es: return "Español"
        case .pt: return "Português"
        case .ru: return "Русский"
        case .zhHant: return "繁體中文"
        }
    }

    var localeIdentifier: String? {
        self == .system ? nil : rawValue
    }
}

// MARK: - Preferences Struct

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
    var enableClipboardMonitoring: Bool
    var autoSaveIntervalMinutes: Int
    var preferredLanguage: LanguageOverride

    // MARK: - Window Behavior
    var closeOnClickOutside: Bool
    var keepWindowOnTop: Bool
    var rememberWindowPosition: Bool
    var windowOpacity: Double
    var windowZoomScale: Double
    var windowMaximizeBehavior: WindowMaximizeBehavior
    var minimizeAnimationDuration: Double
    var showPopoverAnimation: Bool

    // MARK: - Shortcuts
    var showPopoverKeyCode: UInt32
    var showPopoverModifiers: UInt32
    var suppressSystemShortcutConflict: Bool

    // MARK: - Browser
    var defaultBrowser: BrowserType?
    var browserNotRunningBehavior: BrowserNotRunningBehavior
    var askBeforeOpening: Bool
    var forceIncognitoMode: Bool
    var customUserAgent: String

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
    var appIconStyle: AppIconStyle
    var borderWidth: Double
    var fontSizeScale: Double
    var enableBlurBackground: Bool
    var listDividerStyle: ListDividerStyle

    // MARK: - Version
    var version: Int

    // MARK: - Fan Control
    var enableFanControl: Bool
    var fanControlShowInMenuBar: Bool
    var fanControlUpdateInterval: Double
    var fanControlTemperatureUnit: TemperatureUnit
    var fanControlMode: FanControlMode
    var fanControlAutoMaxThreshold: Double
    var fanControlAutoMaxRules: [AutoMaxRule]
    var fanControlGradualTime: Double
    var fanControlDisableOnSleep: Bool
    var fanControlEnableNotifications: Bool
    var fanControlNotificationThreshold: Double

    // MARK: - Advanced
    var animationSpeed: AnimationSpeed
    var enableDebugLogging: Bool
    var enableSoundEffects: Bool
    var enableHapticFeedback: Bool
    var confirmBeforeDelete: Bool
    var confirmBeforeClear: Bool
    var maxTabsInPopover: Int
    var useInstantAnimations: Bool
    var chaosParticleCount: Int
    var logRetentionDays: Int
    var enableDeveloperMode: Bool
    var enableAutoBackup: Bool
    var autoBackupIntervalHours: Int

    // MARK: - Memberwise Init
    init(
        launchAtLogin: Bool,
        showPopoverOnLaunch: Bool,
        showToastNotifications: Bool,
        toastDuration: Double,
        switchBehavior: SwitchBehavior,
        urlMatchPrecision: URLMatchPrecision,
        autoDetectOnShow: Bool,
        enableKeyboardNavigation: Bool,
        switchDelayMs: Double,
        enableClipboardMonitoring: Bool,
        autoSaveIntervalMinutes: Int,
        preferredLanguage: LanguageOverride,
        closeOnClickOutside: Bool,
        keepWindowOnTop: Bool,
        rememberWindowPosition: Bool,
        windowOpacity: Double,
        windowZoomScale: Double,
        windowMaximizeBehavior: WindowMaximizeBehavior,
        minimizeAnimationDuration: Double,
        showPopoverAnimation: Bool,
        showPopoverKeyCode: UInt32,
        showPopoverModifiers: UInt32,
        suppressSystemShortcutConflict: Bool,
        defaultBrowser: BrowserType?,
        browserNotRunningBehavior: BrowserNotRunningBehavior,
        askBeforeOpening: Bool,
        forceIncognitoMode: Bool,
        customUserAgent: String,
        menuBarIconStyle: MenuBarIconStyle,
        panelWidth: Double,
        panelMaxHeight: Double,
        panelCornerRadius: Double,
        theme: AppTheme,
        showURLPreview: Bool,
        rowHeight: Double,
        showBrowserIcon: Bool,
        showShortcutBadge: Bool,
        useCompactMode: Bool,
        showTabCountBadge: Bool,
        appIconStyle: AppIconStyle,
        borderWidth: Double,
        fontSizeScale: Double,
        enableBlurBackground: Bool,
        listDividerStyle: ListDividerStyle,
        version: Int,
        animationSpeed: AnimationSpeed,
        enableDebugLogging: Bool,
        enableSoundEffects: Bool,
        enableHapticFeedback: Bool,
        confirmBeforeDelete: Bool,
        confirmBeforeClear: Bool,
        maxTabsInPopover: Int,
        useInstantAnimations: Bool,
        chaosParticleCount: Int,
        logRetentionDays: Int,
        enableDeveloperMode: Bool,
        enableAutoBackup: Bool,
        autoBackupIntervalHours: Int,
        enableFanControl: Bool,
        fanControlShowInMenuBar: Bool,
        fanControlUpdateInterval: Double,
        fanControlTemperatureUnit: TemperatureUnit,
        fanControlMode: FanControlMode,
        fanControlAutoMaxThreshold: Double,
        fanControlAutoMaxRules: [AutoMaxRule],
        fanControlGradualTime: Double,
        fanControlDisableOnSleep: Bool,
        fanControlEnableNotifications: Bool,
        fanControlNotificationThreshold: Double
    ) {
        self.launchAtLogin = launchAtLogin
        self.showPopoverOnLaunch = showPopoverOnLaunch
        self.showToastNotifications = showToastNotifications
        self.toastDuration = toastDuration
        self.switchBehavior = switchBehavior
        self.urlMatchPrecision = urlMatchPrecision
        self.autoDetectOnShow = autoDetectOnShow
        self.enableKeyboardNavigation = enableKeyboardNavigation
        self.switchDelayMs = switchDelayMs
        self.enableClipboardMonitoring = enableClipboardMonitoring
        self.autoSaveIntervalMinutes = autoSaveIntervalMinutes
        self.preferredLanguage = preferredLanguage
        self.closeOnClickOutside = closeOnClickOutside
        self.keepWindowOnTop = keepWindowOnTop
        self.rememberWindowPosition = rememberWindowPosition
        self.windowOpacity = windowOpacity
        self.windowZoomScale = windowZoomScale
        self.windowMaximizeBehavior = windowMaximizeBehavior
        self.minimizeAnimationDuration = minimizeAnimationDuration
        self.showPopoverAnimation = showPopoverAnimation
        self.showPopoverKeyCode = showPopoverKeyCode
        self.showPopoverModifiers = showPopoverModifiers
        self.suppressSystemShortcutConflict = suppressSystemShortcutConflict
        self.defaultBrowser = defaultBrowser
        self.browserNotRunningBehavior = browserNotRunningBehavior
        self.askBeforeOpening = askBeforeOpening
        self.forceIncognitoMode = forceIncognitoMode
        self.customUserAgent = customUserAgent
        self.menuBarIconStyle = menuBarIconStyle
        self.panelWidth = panelWidth
        self.panelMaxHeight = panelMaxHeight
        self.panelCornerRadius = panelCornerRadius
        self.theme = theme
        self.showURLPreview = showURLPreview
        self.rowHeight = rowHeight
        self.showBrowserIcon = showBrowserIcon
        self.showShortcutBadge = showShortcutBadge
        self.useCompactMode = useCompactMode
        self.showTabCountBadge = showTabCountBadge
        self.appIconStyle = appIconStyle
        self.borderWidth = borderWidth
        self.fontSizeScale = fontSizeScale
        self.enableBlurBackground = enableBlurBackground
        self.listDividerStyle = listDividerStyle
        self.version = version
        self.animationSpeed = animationSpeed
        self.enableDebugLogging = enableDebugLogging
        self.enableSoundEffects = enableSoundEffects
        self.enableHapticFeedback = enableHapticFeedback
        self.confirmBeforeDelete = confirmBeforeDelete
        self.confirmBeforeClear = confirmBeforeClear
        self.maxTabsInPopover = maxTabsInPopover
        self.useInstantAnimations = useInstantAnimations
        self.chaosParticleCount = chaosParticleCount
        self.logRetentionDays = logRetentionDays
        self.enableDeveloperMode = enableDeveloperMode
        self.enableAutoBackup = enableAutoBackup
        self.autoBackupIntervalHours = autoBackupIntervalHours
        self.enableFanControl = enableFanControl
        self.fanControlShowInMenuBar = fanControlShowInMenuBar
        self.fanControlUpdateInterval = fanControlUpdateInterval
        self.fanControlTemperatureUnit = fanControlTemperatureUnit
        self.fanControlMode = fanControlMode
        self.fanControlAutoMaxThreshold = fanControlAutoMaxThreshold
        self.fanControlAutoMaxRules = fanControlAutoMaxRules
        self.fanControlGradualTime = fanControlGradualTime
        self.fanControlDisableOnSleep = fanControlDisableOnSleep
        self.fanControlEnableNotifications = fanControlEnableNotifications
        self.fanControlNotificationThreshold = fanControlNotificationThreshold
    }

    // MARK: - Defaults
    static let `default` = AppPreferences(
        launchAtLogin: false,
        showPopoverOnLaunch: true,
        showToastNotifications: true,
        toastDuration: 1.5,
        switchBehavior: .activateExisting,
        urlMatchPrecision: .prefix,
        autoDetectOnShow: true,
        enableKeyboardNavigation: true,
        switchDelayMs: 0,
        enableClipboardMonitoring: false,
        autoSaveIntervalMinutes: 5,
        preferredLanguage: .system,
        closeOnClickOutside: true,
        keepWindowOnTop: false,
        rememberWindowPosition: true,
        windowOpacity: 1.0,
        windowZoomScale: 1.0,
        windowMaximizeBehavior: .none,
        minimizeAnimationDuration: 0.18,
        showPopoverAnimation: true,
        showPopoverKeyCode: 0x08,
        showPopoverModifiers: AppPreferences.defaultShowPopoverModifiers,
        suppressSystemShortcutConflict: false,
        defaultBrowser: nil,
        browserNotRunningBehavior: .launchAndOpen,
        askBeforeOpening: false,
        forceIncognitoMode: false,
        customUserAgent: "",
        menuBarIconStyle: .fill,
        panelWidth: 380,
        panelMaxHeight: 500,
        panelCornerRadius: 12,
        theme: .system,
        showURLPreview: true,
        rowHeight: 44,
        showBrowserIcon: true,
        showShortcutBadge: true,
        useCompactMode: false,
        showTabCountBadge: false,
        appIconStyle: .default,
        borderWidth: 1.0,
        fontSizeScale: 1.0,
        enableBlurBackground: true,
        listDividerStyle: .thin,
        version: 3,
        animationSpeed: .fast,
        enableDebugLogging: false,
        enableSoundEffects: true,
        enableHapticFeedback: true,
        confirmBeforeDelete: true,
        confirmBeforeClear: true,
        maxTabsInPopover: 50,
        useInstantAnimations: false,
        chaosParticleCount: 200,
        logRetentionDays: 7,
        enableDeveloperMode: false,
        enableAutoBackup: false,
        autoBackupIntervalHours: 24,
        enableFanControl: true,
        fanControlShowInMenuBar: false,
        fanControlUpdateInterval: 2,
        fanControlTemperatureUnit: .celsius,
        fanControlMode: .system,
        fanControlAutoMaxThreshold: 70,
        fanControlAutoMaxRules: [
            AutoMaxRule(fanTarget: .allFans, sensor: .highestCPU, comparison: .above, threshold: 70, hysteresis: 5, durationSeconds: 3, isEnabled: true, targetMode: .percentage, targetPercentage: 100)
        ],
        fanControlGradualTime: 21,
        fanControlDisableOnSleep: true,
        fanControlEnableNotifications: false,
        fanControlNotificationThreshold: 85
    )

    private static var defaultShowPopoverModifiers: UInt32 {
        UInt32(NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue)
    }
}

// MARK: - Coding

extension AppPreferences {
    private enum CodingKeys: String, CodingKey {
        case launchAtLogin
        case showPopoverOnLaunch
        case showToastNotifications
        case toastDuration
        case switchBehavior
        case urlMatchPrecision
        case autoDetectOnShow
        case enableKeyboardNavigation
        case switchDelayMs
        case enableClipboardMonitoring
        case autoSaveIntervalMinutes
        case preferredLanguage
        case closeOnClickOutside
        case keepWindowOnTop
        case rememberWindowPosition
        case windowOpacity
        case windowZoomScale
        case windowMaximizeBehavior
        case minimizeAnimationDuration
        case showPopoverAnimation
        case showPopoverKeyCode
        case showPopoverModifiers
        case suppressSystemShortcutConflict
        case defaultBrowser
        case browserNotRunningBehavior
        case askBeforeOpening
        case forceIncognitoMode
        case customUserAgent
        case menuBarIconStyle
        case panelWidth
        case panelMaxHeight
        case panelCornerRadius
        case theme
        case showURLPreview
        case rowHeight
        case showBrowserIcon
        case showShortcutBadge
        case useCompactMode
        case showTabCountBadge
        case appIconStyle
        case borderWidth
        case fontSizeScale
        case enableBlurBackground
        case listDividerStyle
        case version
        case animationSpeed
        case enableDebugLogging
        case enableSoundEffects
        case enableHapticFeedback
        case confirmBeforeDelete
        case confirmBeforeClear
        case maxTabsInPopover
        case useInstantAnimations
        case chaosParticleCount
        case logRetentionDays
        case enableDeveloperMode
        case enableAutoBackup
        case autoBackupIntervalHours
        case enableFanControl
        case fanControlShowInMenuBar
        case fanControlUpdateInterval
        case fanControlTemperatureUnit
        case fanControlMode
        case fanControlAutoMaxThreshold
        case fanControlAutoMaxRules
        case fanControlGradualTime
        case fanControlDisableOnSleep
        case fanControlEnableNotifications
        case fanControlNotificationThreshold
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var preferences = AppPreferences.default
        let storedVersion = try container.decodeIfPresent(Int.self, forKey: .version) ?? 0

        // General
        preferences.launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? preferences.launchAtLogin
        preferences.showPopoverOnLaunch = try container.decodeIfPresent(Bool.self, forKey: .showPopoverOnLaunch) ?? preferences.showPopoverOnLaunch
        preferences.showToastNotifications = try container.decodeIfPresent(Bool.self, forKey: .showToastNotifications) ?? preferences.showToastNotifications
        preferences.toastDuration = try container.decodeIfPresent(Double.self, forKey: .toastDuration) ?? preferences.toastDuration
        preferences.switchBehavior = try container.decodeIfPresent(SwitchBehavior.self, forKey: .switchBehavior) ?? preferences.switchBehavior
        preferences.urlMatchPrecision = try container.decodeIfPresent(URLMatchPrecision.self, forKey: .urlMatchPrecision) ?? preferences.urlMatchPrecision
        preferences.autoDetectOnShow = try container.decodeIfPresent(Bool.self, forKey: .autoDetectOnShow) ?? preferences.autoDetectOnShow
        preferences.enableKeyboardNavigation = try container.decodeIfPresent(Bool.self, forKey: .enableKeyboardNavigation) ?? preferences.enableKeyboardNavigation
        preferences.switchDelayMs = try container.decodeIfPresent(Double.self, forKey: .switchDelayMs) ?? preferences.switchDelayMs
        preferences.enableClipboardMonitoring = try container.decodeIfPresent(Bool.self, forKey: .enableClipboardMonitoring) ?? preferences.enableClipboardMonitoring
        preferences.autoSaveIntervalMinutes = try container.decodeIfPresent(Int.self, forKey: .autoSaveIntervalMinutes) ?? preferences.autoSaveIntervalMinutes
        preferences.preferredLanguage = try container.decodeIfPresent(LanguageOverride.self, forKey: .preferredLanguage) ?? preferences.preferredLanguage

        // Window Behavior
        preferences.closeOnClickOutside = try container.decodeIfPresent(Bool.self, forKey: .closeOnClickOutside) ?? preferences.closeOnClickOutside
        preferences.keepWindowOnTop = try container.decodeIfPresent(Bool.self, forKey: .keepWindowOnTop) ?? preferences.keepWindowOnTop
        preferences.rememberWindowPosition = try container.decodeIfPresent(Bool.self, forKey: .rememberWindowPosition) ?? preferences.rememberWindowPosition
        preferences.windowOpacity = try container.decodeIfPresent(Double.self, forKey: .windowOpacity) ?? preferences.windowOpacity
        preferences.windowZoomScale = try container.decodeIfPresent(Double.self, forKey: .windowZoomScale) ?? preferences.windowZoomScale
        preferences.windowMaximizeBehavior = try container.decodeIfPresent(WindowMaximizeBehavior.self, forKey: .windowMaximizeBehavior) ?? preferences.windowMaximizeBehavior
        preferences.minimizeAnimationDuration = try container.decodeIfPresent(Double.self, forKey: .minimizeAnimationDuration) ?? preferences.minimizeAnimationDuration
        preferences.showPopoverAnimation = try container.decodeIfPresent(Bool.self, forKey: .showPopoverAnimation) ?? preferences.showPopoverAnimation

        // Shortcuts
        preferences.showPopoverKeyCode = try container.decodeIfPresent(UInt32.self, forKey: .showPopoverKeyCode) ?? preferences.showPopoverKeyCode
        preferences.showPopoverModifiers = AppPreferences.normalizedCocoaModifiers(
            try container.decodeIfPresent(UInt32.self, forKey: .showPopoverModifiers) ?? preferences.showPopoverModifiers
        )
        preferences.suppressSystemShortcutConflict = try container.decodeIfPresent(Bool.self, forKey: .suppressSystemShortcutConflict) ?? preferences.suppressSystemShortcutConflict

        // Browser
        preferences.defaultBrowser = try container.decodeIfPresent(BrowserType.self, forKey: .defaultBrowser) ?? preferences.defaultBrowser
        preferences.browserNotRunningBehavior = try container.decodeIfPresent(BrowserNotRunningBehavior.self, forKey: .browserNotRunningBehavior) ?? preferences.browserNotRunningBehavior
        preferences.askBeforeOpening = try container.decodeIfPresent(Bool.self, forKey: .askBeforeOpening) ?? preferences.askBeforeOpening
        preferences.forceIncognitoMode = try container.decodeIfPresent(Bool.self, forKey: .forceIncognitoMode) ?? preferences.forceIncognitoMode
        preferences.customUserAgent = try container.decodeIfPresent(String.self, forKey: .customUserAgent) ?? preferences.customUserAgent

        // Appearance
        preferences.menuBarIconStyle = try container.decodeIfPresent(MenuBarIconStyle.self, forKey: .menuBarIconStyle) ?? preferences.menuBarIconStyle
        preferences.panelWidth = try container.decodeIfPresent(Double.self, forKey: .panelWidth) ?? preferences.panelWidth
        preferences.panelMaxHeight = try container.decodeIfPresent(Double.self, forKey: .panelMaxHeight) ?? preferences.panelMaxHeight
        preferences.panelCornerRadius = try container.decodeIfPresent(Double.self, forKey: .panelCornerRadius) ?? preferences.panelCornerRadius
        preferences.theme = try container.decodeIfPresent(AppTheme.self, forKey: .theme) ?? preferences.theme
        preferences.showURLPreview = try container.decodeIfPresent(Bool.self, forKey: .showURLPreview) ?? preferences.showURLPreview
        preferences.rowHeight = try container.decodeIfPresent(Double.self, forKey: .rowHeight) ?? preferences.rowHeight
        preferences.showBrowserIcon = try container.decodeIfPresent(Bool.self, forKey: .showBrowserIcon) ?? preferences.showBrowserIcon
        preferences.showShortcutBadge = try container.decodeIfPresent(Bool.self, forKey: .showShortcutBadge) ?? preferences.showShortcutBadge
        preferences.useCompactMode = try container.decodeIfPresent(Bool.self, forKey: .useCompactMode) ?? preferences.useCompactMode
        preferences.showTabCountBadge = try container.decodeIfPresent(Bool.self, forKey: .showTabCountBadge) ?? preferences.showTabCountBadge
        preferences.appIconStyle = try container.decodeIfPresent(AppIconStyle.self, forKey: .appIconStyle) ?? preferences.appIconStyle
        preferences.borderWidth = try container.decodeIfPresent(Double.self, forKey: .borderWidth) ?? preferences.borderWidth
        preferences.fontSizeScale = try container.decodeIfPresent(Double.self, forKey: .fontSizeScale) ?? preferences.fontSizeScale
        preferences.enableBlurBackground = try container.decodeIfPresent(Bool.self, forKey: .enableBlurBackground) ?? preferences.enableBlurBackground
        preferences.listDividerStyle = try container.decodeIfPresent(ListDividerStyle.self, forKey: .listDividerStyle) ?? preferences.listDividerStyle

        // Advanced
        preferences.version = storedVersion
        preferences.animationSpeed = try container.decodeIfPresent(AnimationSpeed.self, forKey: .animationSpeed) ?? preferences.animationSpeed
        preferences.enableDebugLogging = try container.decodeIfPresent(Bool.self, forKey: .enableDebugLogging) ?? preferences.enableDebugLogging
        preferences.enableSoundEffects = try container.decodeIfPresent(Bool.self, forKey: .enableSoundEffects) ?? preferences.enableSoundEffects
        preferences.enableHapticFeedback = try container.decodeIfPresent(Bool.self, forKey: .enableHapticFeedback) ?? preferences.enableHapticFeedback
        preferences.confirmBeforeDelete = try container.decodeIfPresent(Bool.self, forKey: .confirmBeforeDelete) ?? preferences.confirmBeforeDelete
        preferences.confirmBeforeClear = try container.decodeIfPresent(Bool.self, forKey: .confirmBeforeClear) ?? preferences.confirmBeforeClear
        preferences.maxTabsInPopover = try container.decodeIfPresent(Int.self, forKey: .maxTabsInPopover) ?? preferences.maxTabsInPopover
        preferences.useInstantAnimations = try container.decodeIfPresent(Bool.self, forKey: .useInstantAnimations) ?? preferences.useInstantAnimations
        preferences.chaosParticleCount = try container.decodeIfPresent(Int.self, forKey: .chaosParticleCount) ?? preferences.chaosParticleCount
        preferences.logRetentionDays = try container.decodeIfPresent(Int.self, forKey: .logRetentionDays) ?? preferences.logRetentionDays
        preferences.enableDeveloperMode = try container.decodeIfPresent(Bool.self, forKey: .enableDeveloperMode) ?? preferences.enableDeveloperMode
        preferences.enableAutoBackup = try container.decodeIfPresent(Bool.self, forKey: .enableAutoBackup) ?? preferences.enableAutoBackup
        preferences.autoBackupIntervalHours = try container.decodeIfPresent(Int.self, forKey: .autoBackupIntervalHours) ?? preferences.autoBackupIntervalHours

        // Fan Control
        preferences.enableFanControl = try container.decodeIfPresent(Bool.self, forKey: .enableFanControl) ?? preferences.enableFanControl
        preferences.fanControlShowInMenuBar = try container.decodeIfPresent(Bool.self, forKey: .fanControlShowInMenuBar) ?? preferences.fanControlShowInMenuBar
        preferences.fanControlUpdateInterval = try container.decodeIfPresent(Double.self, forKey: .fanControlUpdateInterval) ?? preferences.fanControlUpdateInterval
        preferences.fanControlTemperatureUnit = try container.decodeIfPresent(TemperatureUnit.self, forKey: .fanControlTemperatureUnit) ?? preferences.fanControlTemperatureUnit
        preferences.fanControlMode = try container.decodeIfPresent(FanControlMode.self, forKey: .fanControlMode) ?? preferences.fanControlMode
        preferences.fanControlAutoMaxThreshold = try container.decodeIfPresent(Double.self, forKey: .fanControlAutoMaxThreshold) ?? preferences.fanControlAutoMaxThreshold
        preferences.fanControlAutoMaxRules = try container.decodeIfPresent([AutoMaxRule].self, forKey: .fanControlAutoMaxRules) ?? preferences.fanControlAutoMaxRules
        preferences.fanControlGradualTime = try container.decodeIfPresent(Double.self, forKey: .fanControlGradualTime) ?? preferences.fanControlGradualTime
        preferences.fanControlDisableOnSleep = try container.decodeIfPresent(Bool.self, forKey: .fanControlDisableOnSleep) ?? preferences.fanControlDisableOnSleep
        preferences.fanControlEnableNotifications = try container.decodeIfPresent(Bool.self, forKey: .fanControlEnableNotifications) ?? preferences.fanControlEnableNotifications
        preferences.fanControlNotificationThreshold = try container.decodeIfPresent(Double.self, forKey: .fanControlNotificationThreshold) ?? preferences.fanControlNotificationThreshold

        if storedVersion < 2 {
            preferences.showPopoverOnLaunch = true
        }
        preferences.version = AppPreferences.default.version

        self = preferences
    }

    private static func normalizedCocoaModifiers(_ modifiers: UInt32) -> UInt32 {
        guard modifiers < 65_536 else { return modifiers }

        var cocoa: UInt = 0
        if modifiers & UInt32(cmdKey) != 0 { cocoa |= NSEvent.ModifierFlags.command.rawValue }
        if modifiers & UInt32(optionKey) != 0 { cocoa |= NSEvent.ModifierFlags.option.rawValue }
        if modifiers & UInt32(controlKey) != 0 { cocoa |= NSEvent.ModifierFlags.control.rawValue }
        if modifiers & UInt32(shiftKey) != 0 { cocoa |= NSEvent.ModifierFlags.shift.rawValue }
        return UInt32(cocoa)
    }
}
