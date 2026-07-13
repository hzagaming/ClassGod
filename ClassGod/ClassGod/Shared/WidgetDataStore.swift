//
//  WidgetDataStore.swift
//  ClassGod
//
//  Shared between main app and Widget Extension via App Group when available.
//

import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

/// App Group identifier for data sharing between main app and widgets.
let widgetAppGroupID = "group.com.hanazar.classgod"

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
        if let sharedDefaults = UserDefaults(suiteName: widgetAppGroupID) {
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
