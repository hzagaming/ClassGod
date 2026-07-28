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
    }

    @Test("Battery fractions are normalized to a clamped percentage")
    func normalizesBatteryPercentage() {
        #expect(WidgetMetricNormalization.batteryPercent(from: 0.52) == 52)
        #expect(WidgetMetricNormalization.batteryPercent(from: -1) == 0)
        #expect(WidgetMetricNormalization.batteryPercent(from: 2) == 100)
    }

    @Test("App Launcher deep links round-trip safe bundle identifiers")
    func validatesWidgetLaunchDeepLink() {
        let bundleID = "com.apple.TextEdit"
        let url = WidgetDeepLink.launchURL(bundleIdentifier: bundleID)

        #expect(url != nil)
        #expect(url.flatMap(WidgetDeepLink.launchBundleIdentifier(from:)) == bundleID)
        #expect(WidgetDeepLink.launchBundleIdentifier(from: URL(string: "https://example.com")!) == nil)
        #expect(WidgetDeepLink.launchURL(bundleIdentifier: "invalid bundle") == nil)
    }
}
