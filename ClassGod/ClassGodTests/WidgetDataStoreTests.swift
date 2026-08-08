import Testing
import Foundation
@testable import ClassGod

@Suite("Widget App Group access")
struct WidgetDataStoreTests {
    @Test("Calendar headers and leading cells follow the locale first weekday")
    func calendarLayout() {
        let symbols = ["S", "M", "T", "W", "T", "F", "S"]

        #expect(WidgetCalendarLayout.orderedWeekdaySymbols(symbols, firstWeekday: 1) == symbols)
        #expect(WidgetCalendarLayout.orderedWeekdaySymbols(symbols, firstWeekday: 2) == ["M", "T", "W", "T", "F", "S", "S"])
        #expect(WidgetCalendarLayout.leadingPlaceholderCount(weekday: 1, firstWeekday: 2) == 6)
        #expect(WidgetCalendarLayout.leadingPlaceholderCount(weekday: 2, firstWeekday: 2) == 0)
    }

    @Test("Shared widget storage requires the exact signed App Group")
    func validatesAppGroupEntitlement() {
        #expect(WidgetAppGroupAccess.isEntitled(groups: [widgetAppGroupID]))
        #expect(!WidgetAppGroupAccess.isEntitled(groups: nil))
        #expect(!WidgetAppGroupAccess.isEntitled(groups: ["group.example.other"]))
    }

    @Test("Widget timelines always refresh relative to the current request")
    func schedulesFutureWidgetRefresh() {
        let now = Date(timeIntervalSince1970: 1_000)
        #expect(WidgetRefreshPolicy.nextUpdate(after: now) == Date(timeIntervalSince1970: 1_900))
        #expect(WidgetRefreshPolicy.timelineDates(startingAt: now).count == 15)
        #expect(WidgetRefreshPolicy.timelineDates(startingAt: now).last == Date(timeIntervalSince1970: 1_840))
        #expect(WidgetRefreshPolicy.hostSnapshotInterval == 60)
    }

    @Test("Widget catalog groups every bundled kind exactly once")
    func validatesWidgetKindCatalog() {
        let grouped = ClassGodWidgetKind.systemKinds
            + ClassGodWidgetKind.informationKinds
            + ClassGodWidgetKind.toolKinds
            + ClassGodWidgetKind.funKinds

        #expect(ClassGodWidgetKind.allCases.count == 19)
        #expect(grouped.count == ClassGodWidgetKind.allCases.count)
        #expect(Set(grouped) == Set(ClassGodWidgetKind.allCases))
    }

    @Test("Widget center opens from the main panel at the widget collection")
    func selectsWidgetCollectionByDefault() {
        #expect(HackerDesktopTab.defaultSelection == .widgets)
    }

    @Test("Weather snapshots clamp values and preserve a valid range")
    func normalizesWidgetWeather() {
        let snapshot = WidgetWeatherSnapshot(
            city: "  \(String(repeating: "A", count: 80))  ",
            temperature: .infinity,
            apparentTemperature: -500,
            high: 10,
            low: 30,
            humidity: 180,
            condition: .rain,
            unit: .celsius,
            updatedAt: Date(timeIntervalSince1970: 1_000)
        )
        let normalized = WidgetWeatherPolicy.normalized(snapshot)

        #expect(normalized.city.count == WidgetContentPolicy.maxCityLength)
        #expect(normalized.temperature == 0)
        #expect(normalized.apparentTemperature == -100)
        #expect(normalized.low == 10)
        #expect(normalized.high == 30)
        #expect(normalized.humidity == 100)
        #expect(WidgetWeatherPolicy.temperatureText(normalized.temperature, unit: normalized.unit) == "0°")
    }

    @Test("Weather units convert values and enforce Fahrenheit limits")
    func convertsWidgetWeatherUnits() {
        #expect(WidgetWeatherPolicy.convert(0, from: .celsius, to: .fahrenheit) == 32)
        #expect(WidgetWeatherPolicy.convert(212, from: .fahrenheit, to: .celsius) == 100)

        let snapshot = WidgetWeatherSnapshot(
            city: "Shanghai",
            temperature: 500,
            apparentTemperature: -.infinity,
            high: 220,
            low: -200,
            humidity: -1,
            condition: .clearDay,
            unit: .fahrenheit,
            updatedAt: Date()
        )
        let normalized = WidgetWeatherPolicy.normalized(snapshot)

        #expect(normalized.temperature == 176)
        #expect(normalized.apparentTemperature == 176)
        #expect(normalized.high == 176)
        #expect(normalized.low == -148)
        #expect(normalized.humidity == 0)
    }

    @Test("Configurable widget payloads stay compact and renderable")
    func boundsWidgetPayloads() {
        let items = (0..<30).map { index in
            TodoItem(
                id: UUID(),
                text: index == 0 ? "   " : String(repeating: "T", count: 300),
                isDone: false
            )
        }
        let normalized = WidgetContentPolicy.todoItems(items)

        #expect(normalized.count == WidgetContentPolicy.maxTodoItems)
        #expect(normalized.allSatisfy { !$0.text.isEmpty && $0.text.count <= WidgetContentPolicy.maxTodoLength })
        #expect(WidgetContentPolicy.terminalLogs(Array(repeating: "duplicate", count: 20)).count == WidgetContentPolicy.maxLogLines)

        let duplicateID = UUID()
        let todos = WidgetContentPolicy.todoItems([
            TodoItem(id: duplicateID, text: "first", isDone: false),
            TodoItem(id: duplicateID, text: "duplicate id", isDone: true)
        ])
        #expect(todos.map(\.text) == ["first"])

        let files = WidgetContentPolicy.fileItems([
            FileItem(id: UUID(), path: "/tmp/a", name: "a"),
            FileItem(id: UUID(), path: "/tmp/a", name: "duplicate")
        ])
        #expect(files.count == 1)
    }

    @Test("Battery fractions are normalized to a clamped percentage")
    func normalizesBatteryPercentage() {
        #expect(WidgetMetricNormalization.batteryPercent(from: 0.52) == 52)
        #expect(WidgetMetricNormalization.batteryPercent(from: -1) == 0)
        #expect(WidgetMetricNormalization.batteryPercent(from: 2) == 100)
        #expect(WidgetMetricNormalization.batteryPercent(from: .nan) == 0)
        #expect(WidgetMetricNormalization.batteryPercent(from: .infinity) == 0)
    }

    @Test("Widget metrics reject non-finite and negative snapshots")
    func normalizesSystemMetrics() {
        #expect(WidgetMetricNormalization.nonnegativeFinite(.nan) == 0)
        #expect(WidgetMetricNormalization.nonnegativeFinite(.infinity) == 0)
        #expect(WidgetMetricNormalization.nonnegativeFinite(-1) == 0)
        #expect(WidgetMetricNormalization.nonnegativeFinite(42) == 42)
        #expect(WidgetMetricNormalization.percentage(120) == 100)
        #expect(WidgetMetricNormalization.boundedComponent(12, total: 8) == 8)
        #expect(WidgetMetricNormalization.boundedComponent(-1, total: 8) == 0)
        #expect(WidgetMetricNormalization.boundedComponent(4, total: .nan) == 0)
    }

    @Test("Uptime advances with each generated timeline entry")
    func advancesUptimeAcrossTimeline() {
        let snapshot = Date(timeIntervalSince1970: 1_000)

        #expect(WidgetMetricNormalization.uptime(
            storedSeconds: 3_600,
            snapshotDate: snapshot,
            entryDate: snapshot.addingTimeInterval(120)
        ) == 3_720)
        #expect(WidgetMetricNormalization.uptime(
            storedSeconds: 3_600,
            snapshotDate: snapshot,
            entryDate: snapshot.addingTimeInterval(-120)
        ) == 3_600)
        #expect(WidgetMetricNormalization.uptime(
            storedSeconds: .nan,
            snapshotDate: snapshot,
            entryDate: snapshot
        ) == 0)
    }

    @Test("App Launcher deep links round-trip safe bundle identifiers")
    func validatesWidgetLaunchDeepLink() {
        let bundleID = "com.apple.TextEdit"
        let url = WidgetDeepLink.launchURL(bundleIdentifier: bundleID)

        #expect(url != nil)
        #expect(url.flatMap(WidgetDeepLink.launchBundleIdentifier(from:)) == bundleID)
        #expect(WidgetDeepLink.launchBundleIdentifier(from: URL(string: "https://example.com")!) == nil)
        #expect(WidgetDeepLink.launchURL(bundleIdentifier: "invalid bundle") == nil)
        #expect(WidgetDeepLink.launchURL(bundleIdentifier: "com..example") == nil)
        #expect(WidgetDeepLink.launchURL(bundleIdentifier: "com.example.") == nil)
        #expect(WidgetDeepLink.launchURL(bundleIdentifier: String(repeating: "a", count: 256)) == nil)
    }

    @Test("Theme accents clamp RGB values and preserve the hacker black background")
    func normalizesThemeAccent() {
        let accent = ThemeAccent(red: -1, green: 0.5, blue: 2)

        #expect(accent.red == 0)
        #expect(accent.green == 0.5)
        #expect(accent.blue == 1)
        #expect(ThemeAccent.default == ThemeAccent(red: 0, green: 1, blue: 1))
    }

    @Test("Decoded theme accents cannot bypass RGB normalization")
    func normalizesDecodedThemeAccent() throws {
        let data = Data(#"{"red":-2,"green":0.4,"blue":3}"#.utf8)
        let accent = try JSONDecoder().decode(ThemeAccent.self, from: data)

        #expect(accent == ThemeAccent(red: 0, green: 0.4, blue: 1))
    }

    @Test("Widget accent snapshots use normalized shared RGB values")
    func normalizesWidgetAccentSnapshot() {
        let accent = WidgetAccentPolicy.normalized(red: .nan, green: -0.5, blue: 1.5)

        #expect(accent == .default)
        #expect(WidgetAccentPolicy.normalized(red: 0.2, green: 0.4, blue: 0.6) == ThemeAccent(red: 0.2, green: 0.4, blue: 0.6))
    }
}
