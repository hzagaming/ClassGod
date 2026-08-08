//
//  WidgetDataStore.swift
//  ClassGod
//
//  Shared between main app and Widget Extension via App Group when available.
//

import Foundation
import Security

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(WidgetKit)
import WidgetKit
#endif

/// App Group identifier for data sharing between main app and widgets.
nonisolated let widgetAppGroupID = "group.com.hanazar.classgod"

nonisolated struct ThemeAccent: Codable, Equatable, Hashable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    static let `default` = ThemeAccent(red: 0, green: 1, blue: 1)

    init(red: Double, green: Double, blue: Double) {
        self.red = Self.component(red)
        self.green = Self.component(green)
        self.blue = Self.component(blue)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            red: try container.decode(Double.self, forKey: .red),
            green: try container.decode(Double.self, forKey: .green),
            blue: try container.decode(Double.self, forKey: .blue)
        )
    }

    private static func component(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(1, max(0, value))
    }
}

nonisolated enum WidgetAccentPolicy {
    static func normalized(red: Double, green: Double, blue: Double) -> ThemeAccent {
        guard red.isFinite, green.isFinite, blue.isFinite else { return .default }
        return ThemeAccent(red: red, green: green, blue: blue)
    }
}

#if canImport(SwiftUI)
extension ThemeAccent {
    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}
#endif

nonisolated enum ClassGodWidgetKind: String, CaseIterable, Sendable {
    case cpu = "CPUWidget"
    case memory = "MemoryWidget"
    case disk = "DiskWidget"
    case network = "NetworkWidget"
    case battery = "BatteryWidget"
    case uptime = "UptimeWidget"
    case clock = "ClockWidget"
    case worldClock = "WorldClockWidget"
    case calendar = "CalendarWidget"
    case weather = "WeatherWidget"
    case systemInfo = "SystemInfoWidget"
    case todo = "TodoWidget"
    case notes = "NotesWidget"
    case files = "FileWidget"
    case appLauncher = "AppLauncherWidget"
    case terminal = "TerminalLogWidget"
    case asciiArt = "AsciiArtWidget"
    case crypto = "CryptoWidget"
    case quote = "QuoteWidget"

    static let systemKinds: [ClassGodWidgetKind] = [.cpu, .memory, .disk, .network, .battery, .uptime, .systemInfo]
    static let informationKinds: [ClassGodWidgetKind] = [.clock, .worldClock, .calendar, .weather]
    static let toolKinds: [ClassGodWidgetKind] = [.todo, .notes, .files, .appLauncher]
    static let funKinds: [ClassGodWidgetKind] = [.terminal, .asciiArt, .crypto, .quote]
}

nonisolated enum WidgetRefreshPolicy {
    static let hostSnapshotInterval: TimeInterval = 60

    static func nextUpdate(after date: Date) -> Date {
        date.addingTimeInterval(15 * 60)
    }

    static func timelineDates(startingAt date: Date) -> [Date] {
        (0..<15).map { date.addingTimeInterval(Double($0) * 60) }
    }
}

nonisolated enum WidgetTemperatureUnit: String, Codable, CaseIterable, Sendable {
    case celsius
    case fahrenheit

    var symbol: String { self == .celsius ? "°C" : "°F" }
    var validRange: ClosedRange<Double> { self == .celsius ? -100...80 : -148...176 }
}

nonisolated enum WidgetWeatherCondition: String, Codable, CaseIterable, Sendable {
    case clearDay = "sun.max.fill"
    case clearNight = "moon.stars.fill"
    case partlyCloudy = "cloud.sun.fill"
    case cloudy = "cloud.fill"
    case rain = "cloud.rain.fill"
    case thunderstorm = "cloud.bolt.rain.fill"
    case snow = "cloud.snow.fill"
    case fog = "cloud.fog.fill"
    case wind = "wind"
}

nonisolated struct WidgetWeatherSnapshot: Codable, Equatable, Sendable {
    var city: String
    var temperature: Double
    var apparentTemperature: Double
    var high: Double
    var low: Double
    var humidity: Int
    var condition: WidgetWeatherCondition
    var unit: WidgetTemperatureUnit
    var updatedAt: Date

    static var placeholder: WidgetWeatherSnapshot {
        WidgetWeatherSnapshot(
            city: "",
            temperature: 0,
            apparentTemperature: 0,
            high: 0,
            low: 0,
            humidity: 0,
            condition: .partlyCloudy,
            unit: .celsius,
            updatedAt: .distantPast
        )
    }
}

nonisolated enum WidgetWeatherPolicy {
    static func normalized(_ snapshot: WidgetWeatherSnapshot) -> WidgetWeatherSnapshot {
        let range = snapshot.unit.validRange
        let temperature = clamp(snapshot.temperature, to: range, fallback: 0)
        let apparent = clamp(snapshot.apparentTemperature, to: range, fallback: temperature)
        let first = clamp(snapshot.low, to: range, fallback: temperature)
        let second = clamp(snapshot.high, to: range, fallback: temperature)

        return WidgetWeatherSnapshot(
            city: WidgetContentPolicy.text(snapshot.city, maxLength: WidgetContentPolicy.maxCityLength, trimsWhitespace: true),
            temperature: temperature,
            apparentTemperature: apparent,
            high: max(first, second),
            low: min(first, second),
            humidity: max(0, min(100, snapshot.humidity)),
            condition: snapshot.condition,
            unit: snapshot.unit,
            updatedAt: snapshot.updatedAt
        )
    }

    static func temperatureText(_ value: Double, unit: WidgetTemperatureUnit) -> String {
        let value = clamp(value, to: unit.validRange, fallback: 0)
        if value.rounded() == value {
            return "\(Int(value))°"
        }
        return String(format: "%.1f°", value)
    }

    static func convert(_ value: Double, from source: WidgetTemperatureUnit, to destination: WidgetTemperatureUnit) -> Double {
        guard source != destination, value.isFinite else { return value }
        switch (source, destination) {
        case (.celsius, .fahrenheit): return value * 9 / 5 + 32
        case (.fahrenheit, .celsius): return (value - 32) * 5 / 9
        default: return value
        }
    }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>, fallback: Double) -> Double {
        guard value.isFinite else { return fallback }
        return min(range.upperBound, max(range.lowerBound, value))
    }
}

nonisolated enum WidgetContentPolicy {
    static let maxCityLength = 64
    static let maxTodoItems = 20
    static let maxTodoLength = 160
    static let maxNoteLength = 2_000
    static let maxFileItems = 12
    static let maxAppItems = 12
    static let maxLogLines = 8
    static let maxLogLength = 200
    static let maxQuoteLength = 320
    static let maxAuthorLength = 80
    static let maxAsciiLength = 1_000
    static let maxPriceLength = 64

    static func text(_ value: String, maxLength: Int, trimsWhitespace: Bool = false) -> String {
        let source = trimsWhitespace ? value.trimmingCharacters(in: .whitespacesAndNewlines) : value
        return String(source.prefix(max(0, maxLength)))
    }

    static func todoItems(_ items: [TodoItem]) -> [TodoItem] {
        var identifiers = Set<UUID>()
        return items.compactMap { item -> TodoItem? in
            let value = text(item.text, maxLength: maxTodoLength, trimsWhitespace: true)
            guard !value.isEmpty, identifiers.insert(item.id).inserted else { return nil }
            return TodoItem(id: item.id, text: value, isDone: item.isDone)
        }
        .prefix(maxTodoItems)
        .map { $0 }
    }

    static func fileItems(_ items: [FileItem]) -> [FileItem] {
        var identifiers = Set<UUID>()
        var paths = Set<String>()
        return items.compactMap { item in
            let path = text(item.path, maxLength: 1_024, trimsWhitespace: true)
            guard !path.isEmpty,
                  identifiers.insert(item.id).inserted,
                  paths.insert(path).inserted else { return nil }
            let name = text(item.name, maxLength: 96, trimsWhitespace: true)
            return FileItem(id: item.id, path: path, name: name.isEmpty ? URL(fileURLWithPath: path).lastPathComponent : name)
        }
        .prefix(maxFileItems)
        .map { $0 }
    }

    static func appItems(_ items: [AppLauncherItem]) -> [AppLauncherItem] {
        var identifiers = Set<UUID>()
        var bundleIDs = Set<String>()
        return items.compactMap { item in
            let bundleID = text(item.bundleID, maxLength: 255, trimsWhitespace: true)
            guard WidgetDeepLink.isValidBundleIdentifier(bundleID),
                  identifiers.insert(item.id).inserted,
                  bundleIDs.insert(bundleID).inserted else { return nil }
            let name = text(item.name, maxLength: 96, trimsWhitespace: true)
            return AppLauncherItem(id: item.id, bundleID: bundleID, name: name.isEmpty ? bundleID : name)
        }
        .prefix(maxAppItems)
        .map { $0 }
    }

    static func terminalLogs(_ lines: [String]) -> [String] {
        lines.compactMap { line in
            let value = text(line, maxLength: maxLogLength, trimsWhitespace: true)
            return value.isEmpty ? nil : value
        }
        .prefix(maxLogLines)
        .map { $0 }
    }
}

nonisolated enum WidgetMetricNormalization {
    static func nonnegativeFinite(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return max(0, value)
    }

    static func percentage(_ value: Double) -> Double {
        min(100, nonnegativeFinite(value))
    }

    static func batteryPercent(from fraction: Double) -> Double {
        percentage(fraction * 100)
    }

    static func boundedComponent(_ value: Double, total: Double) -> Double {
        let total = nonnegativeFinite(total)
        guard total > 0 else { return 0 }
        return min(total, nonnegativeFinite(value))
    }

    static func uptime(storedSeconds: TimeInterval, snapshotDate: Date, entryDate: Date) -> TimeInterval {
        nonnegativeFinite(
            nonnegativeFinite(storedSeconds)
                + nonnegativeFinite(entryDate.timeIntervalSince(snapshotDate))
        )
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

    static func isValidBundleIdentifier(_ value: String) -> Bool {
        value.count <= 255
            && !value.hasSuffix(".")
            && !value.contains("..")
            && value.range(of: #"^[A-Za-z0-9][A-Za-z0-9.-]*$"#, options: .regularExpression) != nil
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
    case weatherSnapshot = "widget.weatherSnapshot"
    case cryptoBTC = "widget.cryptoBTC"
    case cryptoETH = "widget.cryptoETH"
    case quoteText = "widget.quoteText"
    case quoteAuthor = "widget.quoteAuthor"
    case terminalLogs = "widget.terminalLogs"
    case asciiArt = "widget.asciiArt"
    case lastUpdate = "widget.lastUpdate"
    case accentRed = "widget.accentRed"
    case accentGreen = "widget.accentGreen"
    case accentBlue = "widget.accentBlue"
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

    func contains(_ key: WidgetDataKey) -> Bool {
        defaults.object(forKey: key.rawValue) != nil
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

    func setValue<T: Codable>(_ value: T, forKey key: WidgetDataKey) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key.rawValue)
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
        set(WidgetMetricNormalization.percentage(cpu), forKey: .cpuUsage)
        let normalizedMemoryTotal = WidgetMetricNormalization.nonnegativeFinite(memoryTotal)
        let normalizedDiskTotal = WidgetMetricNormalization.nonnegativeFinite(diskTotal)
        set(WidgetMetricNormalization.boundedComponent(memoryUsed, total: normalizedMemoryTotal), forKey: .memoryUsage)
        set(normalizedMemoryTotal, forKey: .memoryTotal)
        set(WidgetMetricNormalization.boundedComponent(diskFree, total: normalizedDiskTotal), forKey: .diskFree)
        set(normalizedDiskTotal, forKey: .diskTotal)
        set(WidgetMetricNormalization.nonnegativeFinite(netDown), forKey: .networkDown)
        set(WidgetMetricNormalization.nonnegativeFinite(netUp), forKey: .networkUp)
        set(WidgetMetricNormalization.percentage(battery), forKey: .batteryLevel)
        set(isCharging, forKey: .batteryIsCharging)
        set(WidgetMetricNormalization.nonnegativeFinite(uptime), forKey: .uptimeSeconds)
        set(Date(), forKey: .lastUpdate)
    }

    func saveAccent(_ accent: ThemeAccent) {
        set(accent.red, forKey: .accentRed)
        set(accent.green, forKey: .accentGreen)
        set(accent.blue, forKey: .accentBlue)
    }
    
    // MARK: - Trigger Widget Reload
    
    func reloadWidgets(_ kinds: [ClassGodWidgetKind]) {
        #if canImport(WidgetKit)
        if #available(macOS 11.0, *) {
            for kind in Set(kinds) {
                WidgetCenter.shared.reloadTimelines(ofKind: kind.rawValue)
            }
        }
        #endif
    }

    func reloadAllWidgets() {
        reloadWidgets(ClassGodWidgetKind.allCases)
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
