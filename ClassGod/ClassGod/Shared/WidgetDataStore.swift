//
//  WidgetDataStore.swift
//  ClassGod
//
//  Shared between main app and Widget Extension via App Group when available.
//

import Foundation
import Security

#if canImport(WidgetKit)
import WidgetKit
#endif

/// App Group identifier for data sharing between main app and widgets.
nonisolated let widgetAppGroupID = "group.com.hanazar.classgod"

nonisolated enum WidgetRefreshPolicy {
    static func nextUpdate(after date: Date) -> Date {
        date.addingTimeInterval(15 * 60)
    }

    static func timelineDates(startingAt date: Date) -> [Date] {
        (0..<15).map { date.addingTimeInterval(Double($0) * 60) }
    }
}

nonisolated enum WidgetMetricNormalization {
    static func batteryPercent(from fraction: Double) -> Double {
        min(100, max(0, fraction * 100))
    }
}

nonisolated enum WidgetCalendarLayout {
    static func orderedWeekdaySymbols(_ symbols: [String], firstWeekday: Int) -> [String] {
        guard !symbols.isEmpty else { return [] }
        let offset = max(0, min(symbols.count - 1, firstWeekday - 1))
        return Array(symbols[offset...] + symbols[..<offset])
    }

    static func leadingPlaceholderCount(weekday: Int, firstWeekday: Int) -> Int {
        (weekday - firstWeekday + 7) % 7
    }
}

nonisolated enum WidgetDeepLink {
    static func launchURL(bundleIdentifier: String) -> URL? {
        guard isValidBundleIdentifier(bundleIdentifier) else { return nil }
        var components = URLComponents()
        components.scheme = "classgod"
        components.host = "launch"
        components.queryItems = [URLQueryItem(name: "bundle", value: bundleIdentifier)]
        return components.url
    }

    static func launchBundleIdentifier(from url: URL) -> String? {
        guard url.scheme?.lowercased() == "classgod", url.host?.lowercased() == "launch",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let bundleIdentifier = components.queryItems?.first(where: { $0.name == "bundle" })?.value,
              isValidBundleIdentifier(bundleIdentifier) else { return nil }
        return bundleIdentifier
    }

    private static func isValidBundleIdentifier(_ value: String) -> Bool {
        value.range(of: #"^[A-Za-z0-9][A-Za-z0-9.-]*$"#, options: .regularExpression) != nil
    }
}

nonisolated enum WidgetAppGroupAccess {
    static func isEntitled(groups: [String]?) -> Bool {
        groups?.contains(widgetAppGroupID) == true
    }

    static var currentProcessIsEntitled: Bool {
        guard let task = SecTaskCreateFromSelf(nil),
              let groups = SecTaskCopyValueForEntitlement(
                task,
                "com.apple.security.application-groups" as CFString,
                nil
              ) as? [String] else { return false }
        return isEntitled(groups: groups)
    }
}

// MARK: - Data Keys

enum WidgetDataKey: String {
    case cpuUsage = "widget.cpuUsage"
    case memoryUsage = "widget.memoryUsage"
    case memoryTotal = "widget.memoryTotal"
    case diskFree = "widget.diskFree"
    case diskTotal = "widget.diskTotal"
    case networkDown = "widget.networkDown"
    case networkUp = "widget.networkUp"
    case batteryLevel = "widget.batteryLevel"
    case batteryIsCharging = "widget.batteryIsCharging"
    case uptimeSeconds = "widget.uptimeSeconds"
    case todoItems = "widget.todoItems"
    case noteContent = "widget.noteContent"
    case filePaths = "widget.filePaths"
    case appBundleIDs = "widget.appBundleIDs"
    case clockCity = "widget.clockCity"
    case weatherCity = "widget.weatherCity"
    case weatherTemp = "widget.weatherTemp"
    case weatherCondition = "widget.weatherCondition"
    case cryptoBTC = "widget.cryptoBTC"
    case cryptoETH = "widget.cryptoETH"
    case quoteText = "widget.quoteText"
    case quoteAuthor = "widget.quoteAuthor"
    case terminalLogs = "widget.terminalLogs"
    case asciiArt = "widget.asciiArt"
    case lastUpdate = "widget.lastUpdate"
}

// MARK: - Widget Data Store

@MainActor
final class WidgetDataStore {
    static let shared = WidgetDataStore()
    
    private let defaults: UserDefaults
    let usesSharedContainer: Bool
    
    private init() {
        if WidgetAppGroupAccess.currentProcessIsEntitled,
           FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: widgetAppGroupID) != nil,
           let sharedDefaults = UserDefaults(suiteName: widgetAppGroupID) {
            defaults = sharedDefaults
            usesSharedContainer = true
        } else {
            defaults = .standard
            usesSharedContainer = false
        }
    }
    
    // MARK: - Generic
    
    func set(_ value: Any, forKey key: WidgetDataKey) {
        defaults.set(value, forKey: key.rawValue)
    }
    
    func string(forKey key: WidgetDataKey) -> String? {
        defaults.string(forKey: key.rawValue)
    }
    
    func double(forKey key: WidgetDataKey) -> Double {
        defaults.double(forKey: key.rawValue)
    }
    
    func bool(forKey key: WidgetDataKey) -> Bool {
        defaults.bool(forKey: key.rawValue)
    }
    
    func integer(forKey key: WidgetDataKey) -> Int {
        defaults.integer(forKey: key.rawValue)
    }
    
    func data(forKey key: WidgetDataKey) -> Data? {
        defaults.data(forKey: key.rawValue)
    }
    
    func date(forKey key: WidgetDataKey) -> Date? {
        defaults.object(forKey: key.rawValue) as? Date
    }
    
    func set(_ array: [String], forKey key: WidgetDataKey) {
        defaults.set(array, forKey: key.rawValue)
    }
    
    func stringArray(forKey key: WidgetDataKey) -> [String] {
        defaults.stringArray(forKey: key.rawValue) ?? []
    }
    
    func setArray<T: Codable>(_ array: [T], forKey key: WidgetDataKey) {
        guard let data = try? JSONEncoder().encode(array) else { return }
        defaults.set(data, forKey: key.rawValue)
    }
    
    func array<T: Codable>(forKey key: WidgetDataKey, type: T.Type) -> [T] {
        guard let data = defaults.data(forKey: key.rawValue),
              let array = try? JSONDecoder().decode([T].self, from: data) else { return [] }
        return array
    }
    
    // MARK: - Convenience: System Snapshot
    
    func saveSystemSnapshot(
        cpu: Double,
        memoryUsed: Double,
        memoryTotal: Double,
        diskFree: Double,
        diskTotal: Double,
        netDown: Double,
        netUp: Double,
        battery: Double,
        isCharging: Bool,
        uptime: TimeInterval
    ) {
        set(cpu, forKey: .cpuUsage)
        set(memoryUsed, forKey: .memoryUsage)
        set(memoryTotal, forKey: .memoryTotal)
        set(diskFree, forKey: .diskFree)
        set(diskTotal, forKey: .diskTotal)
        set(netDown, forKey: .networkDown)
        set(netUp, forKey: .networkUp)
        set(battery, forKey: .batteryLevel)
        set(isCharging, forKey: .batteryIsCharging)
        set(uptime, forKey: .uptimeSeconds)
        set(Date(), forKey: .lastUpdate)
    }
    
    // MARK: - Trigger Widget Reload
    
    func reloadAllWidgets() {
        #if canImport(WidgetKit)
        if #available(macOS 11.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
    }
}

// MARK: - Models

struct TodoItem: Codable, Identifiable {
    let id: UUID
    var text: String
    var isDone: Bool
}

struct FileItem: Codable, Identifiable {
    let id: UUID
    var path: String
    var name: String
}

struct AppLauncherItem: Codable, Identifiable {
    let id: UUID
    var bundleID: String
    var name: String
}
