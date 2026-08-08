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
        let entry = loadEntry(store: WidgetExtensionStore())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> ()) {
        let now = Date()
        let store = WidgetExtensionStore()
        let entries = WidgetRefreshPolicy.timelineDates(startingAt: now).map { loadEntry(date: $0, store: store) }
        let nextUpdate = WidgetRefreshPolicy.nextUpdate(after: now)
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // MARK: - Data Loading
    
    private func loadEntry(date: Date = Date(), store: WidgetExtensionStore) -> WidgetEntry {
        let snapshotDate = store.date(forKey: .lastUpdate) ?? date
        let memoryTotal = WidgetMetricNormalization.nonnegativeFinite(store.double(forKey: .memoryTotal))
        let diskTotal = WidgetMetricNormalization.nonnegativeFinite(store.double(forKey: .diskTotal))
        return WidgetEntry(
            date: date,
            accent: store.contains(.accentRed)
                ? WidgetAccentPolicy.normalized(
                    red: store.double(forKey: .accentRed),
                    green: store.double(forKey: .accentGreen),
                    blue: store.double(forKey: .accentBlue)
                )
                : .default,
            cpuUsage: WidgetMetricNormalization.percentage(store.double(forKey: .cpuUsage)),
            memoryUsage: WidgetMetricNormalization.boundedComponent(
                store.double(forKey: .memoryUsage),
                total: memoryTotal
            ),
            memoryTotal: memoryTotal,
            diskFree: WidgetMetricNormalization.boundedComponent(
                store.double(forKey: .diskFree),
                total: diskTotal
            ),
            diskTotal: diskTotal,
            networkDown: WidgetMetricNormalization.nonnegativeFinite(store.double(forKey: .networkDown)),
            networkUp: WidgetMetricNormalization.nonnegativeFinite(store.double(forKey: .networkUp)),
            batteryLevel: WidgetMetricNormalization.percentage(store.double(forKey: .batteryLevel)),
            batteryIsCharging: store.bool(forKey: .batteryIsCharging),
            uptimeSeconds: WidgetMetricNormalization.uptime(
                storedSeconds: store.double(forKey: .uptimeSeconds),
                snapshotDate: snapshotDate,
                entryDate: date
            ),
            clockCity: WidgetContentPolicy.text(
                store.string(forKey: .clockCity) ?? String(localized: "Local"),
                maxLength: WidgetContentPolicy.maxCityLength,
                trimsWhitespace: true
            ),
            weather: WidgetWeatherPolicy.normalized(
                store.value(forKey: .weatherSnapshot, type: WidgetWeatherSnapshot.self) ?? .placeholder
            ),
            todoItems: WidgetContentPolicy.todoItems(store.array(forKey: .todoItems, type: TodoItem.self)),
            noteContent: WidgetContentPolicy.text(
                store.string(forKey: .noteContent) ?? "",
                maxLength: WidgetContentPolicy.maxNoteLength
            ),
            filePaths: WidgetContentPolicy.fileItems(store.array(forKey: .filePaths, type: FileItem.self)),
            appItems: WidgetContentPolicy.appItems(store.array(forKey: .appBundleIDs, type: AppLauncherItem.self)),
            cryptoBTC: WidgetContentPolicy.text(
                store.string(forKey: .cryptoBTC) ?? "--",
                maxLength: WidgetContentPolicy.maxPriceLength,
                trimsWhitespace: true
            ),
            cryptoETH: WidgetContentPolicy.text(
                store.string(forKey: .cryptoETH) ?? "--",
                maxLength: WidgetContentPolicy.maxPriceLength,
                trimsWhitespace: true
            ),
            quoteText: WidgetContentPolicy.text(
                store.string(forKey: .quoteText) ?? "",
                maxLength: WidgetContentPolicy.maxQuoteLength,
                trimsWhitespace: true
            ),
            quoteAuthor: WidgetContentPolicy.text(
                store.string(forKey: .quoteAuthor) ?? "",
                maxLength: WidgetContentPolicy.maxAuthorLength,
                trimsWhitespace: true
            ),
            terminalLogs: WidgetContentPolicy.terminalLogs(store.stringArray(forKey: .terminalLogs)),
            asciiArt: WidgetContentPolicy.text(
                store.string(forKey: .asciiArt) ?? "",
                maxLength: WidgetContentPolicy.maxAsciiLength
            )
        )
    }
}

// MARK: - Extension-Specific Store

struct WidgetExtensionStore {
    private let defaults: UserDefaults

    init() {
        if WidgetAppGroupAccess.currentProcessIsEntitled,
           FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: widgetAppGroupID) != nil,
           let sharedDefaults = UserDefaults(suiteName: widgetAppGroupID) {
            defaults = sharedDefaults
        } else {
            defaults = .standard
        }
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

    func contains(_ key: WidgetDataKey) -> Bool {
        defaults.object(forKey: key.rawValue) != nil
    }
    
    func date(forKey key: WidgetDataKey) -> Date? {
        defaults.object(forKey: key.rawValue) as? Date
    }
    
    func array<T: Codable>(forKey key: WidgetDataKey, type: T.Type) -> [T] {
        guard let data = defaults.data(forKey: key.rawValue),
              let array = try? JSONDecoder().decode([T].self, from: data) else { return [] }
        return array
    }

    func value<T: Codable>(forKey key: WidgetDataKey, type: T.Type) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    func stringArray(forKey key: WidgetDataKey) -> [String] {
        defaults.stringArray(forKey: key.rawValue) ?? []
    }
}
