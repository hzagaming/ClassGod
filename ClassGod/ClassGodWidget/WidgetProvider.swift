//
//  WidgetProvider.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct WidgetProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> WidgetEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> ()) {
        let entry = loadEntry()
        // Refresh every 15 minutes (WidgetKit minimum for desk widgets)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date) ?? entry.date.addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // MARK: - Data Loading
    
    private func loadEntry() -> WidgetEntry {
        let store = WidgetExtensionStore()
        return WidgetEntry(
            date: store.date(forKey: .lastUpdate) ?? Date(),
            cpuUsage: store.double(forKey: .cpuUsage),
            memoryUsage: store.double(forKey: .memoryUsage),
            memoryTotal: store.double(forKey: .memoryTotal),
            diskFree: store.double(forKey: .diskFree),
            diskTotal: store.double(forKey: .diskTotal),
            networkDown: store.double(forKey: .networkDown),
            networkUp: store.double(forKey: .networkUp),
            batteryLevel: store.double(forKey: .batteryLevel),
            batteryIsCharging: store.bool(forKey: .batteryIsCharging),
            uptimeSeconds: store.double(forKey: .uptimeSeconds),
            clockCity: store.string(forKey: .clockCity) ?? "Local",
            weatherCity: store.string(forKey: .weatherCity) ?? "",
            weatherTemp: store.string(forKey: .weatherTemp) ?? "--",
            weatherCondition: store.string(forKey: .weatherCondition) ?? "questionmark",
            todoItems: store.array(forKey: .todoItems, type: TodoItem.self),
            noteContent: store.string(forKey: .noteContent) ?? "",
            filePaths: store.array(forKey: .filePaths, type: FileItem.self),
            appItems: store.array(forKey: .appBundleIDs, type: AppLauncherItem.self),
            cryptoBTC: store.string(forKey: .cryptoBTC) ?? "--",
            cryptoETH: store.string(forKey: .cryptoETH) ?? "--",
            quoteText: store.string(forKey: .quoteText) ?? "",
            quoteAuthor: store.string(forKey: .quoteAuthor) ?? "",
            terminalLogs: store.stringArray(forKey: .terminalLogs),
            asciiArt: store.string(forKey: .asciiArt) ?? ""
        )
    }
}

// MARK: - Extension-Specific Store

struct WidgetExtensionStore {
    private let defaults = UserDefaults(suiteName: widgetAppGroupID)
    
    func string(forKey key: WidgetDataKey) -> String? {
        defaults?.string(forKey: key.rawValue)
    }
    
    func double(forKey key: WidgetDataKey) -> Double {
        defaults?.double(forKey: key.rawValue) ?? 0
    }
    
    func bool(forKey key: WidgetDataKey) -> Bool {
        defaults?.bool(forKey: key.rawValue) ?? false
    }
    
    func date(forKey key: WidgetDataKey) -> Date? {
        defaults?.object(forKey: key.rawValue) as? Date
    }
    
    func array<T: Codable>(forKey key: WidgetDataKey, type: T.Type) -> [T] {
        guard let data = defaults?.data(forKey: key.rawValue),
              let array = try? JSONDecoder().decode([T].self, from: data) else { return [] }
        return array
    }
    
    func stringArray(forKey key: WidgetDataKey) -> [String] {
        defaults?.stringArray(forKey: key.rawValue) ?? []
    }
}
