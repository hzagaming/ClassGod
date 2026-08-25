import Foundation
import Testing
@testable import ClassGod

@Suite("Schedule Lab")
struct ScheduleTests {
    @Test("Schedule editor fits inside the minimum schedule window")
    func editorFitsMinimumWindow() {
        let window = FeatureWindowLayoutPolicy.layout(for: .schedule)

        #expect(ScheduleEditorLayoutPolicy.width <= window.minimumWidth)
        #expect(ScheduleEditorLayoutPolicy.height <= window.minimumHeight)
    }

    @Test("Schedule snapshots discard invalid and duplicate entries")
    func normalizesSnapshots() {
        let valid = ScheduleEntry(
            title: "  Algorithms  ",
            weekday: .monday,
            startMinute: 540,
            endMinute: 600,
            location: "  Room 4  ",
            notes: String(repeating: "N", count: ScheduleContentPolicy.maximumNotesLength + 20)
        )
        let invalid = ScheduleEntry(
            title: "Broken",
            weekday: .tuesday,
            startMinute: 900,
            endMinute: 800
        )
        let blank = ScheduleEntry(
            title: "   ",
            weekday: .friday,
            startMinute: 600,
            endMinute: 660
        )
        let tooShort = ScheduleEntry(
            title: "Too Short",
            weekday: .friday,
            startMinute: 600,
            endMinute: 614
        )

        let snapshot = ScheduleContentPolicy.normalized(
            ScheduleSnapshot(entries: [valid, valid, invalid, blank, tooShort])
        )

        #expect(snapshot.entries.count == 1)
        #expect(snapshot.entries[0].title == "Algorithms")
        #expect(snapshot.entries[0].location == "Room 4")
        #expect(snapshot.entries[0].notes.count == ScheduleContentPolicy.maximumNotesLength)
        #expect(ScheduleContentPolicy.minimumDurationMinutes == 15)
    }

    @Test("Conflicts ignore adjacent and disabled entries")
    func detectsConflicts() {
        let first = ScheduleEntry(
            title: "Math",
            weekday: .monday,
            startMinute: 540,
            endMinute: 600
        )
        let overlap = ScheduleEntry(
            title: "Lab",
            weekday: .monday,
            startMinute: 570,
            endMinute: 630
        )
        let adjacent = ScheduleEntry(
            title: "Lunch",
            weekday: .monday,
            startMinute: 630,
            endMinute: 690
        )
        let disabled = ScheduleEntry(
            title: "Muted",
            weekday: .monday,
            startMinute: 540,
            endMinute: 690,
            isEnabled: false
        )
        let otherDay = ScheduleEntry(
            title: "Tuesday",
            weekday: .tuesday,
            startMinute: 540,
            endMinute: 630
        )

        #expect(ScheduleConflictPolicy.conflictingIDs(
            [adjacent, otherDay, disabled, overlap, first]
        ) == [first.id, overlap.id])
    }

    @Test("Overlapping cards receive deterministic lanes per cluster")
    func laysOutOverlapLanes() {
        let first = ScheduleEntry(
            title: "First",
            weekday: .wednesday,
            startMinute: 540,
            endMinute: 600
        )
        let overlap = ScheduleEntry(
            title: "Overlap",
            weekday: .wednesday,
            startMinute: 570,
            endMinute: 630
        )
        let later = ScheduleEntry(
            title: "Later",
            weekday: .wednesday,
            startMinute: 660,
            endMinute: 720
        )

        let layouts = ScheduleLayoutPolicy.layouts(for: [later, overlap, first])

        #expect(layouts == [
            ScheduleEntryLayout(id: first.id, lane: 0, laneCount: 2),
            ScheduleEntryLayout(id: overlap.id, lane: 1, laneCount: 2),
            ScheduleEntryLayout(id: later.id, lane: 0, laneCount: 1),
        ])
    }

    @Test("Dense overlap lanes always stay inside the timeline width")
    func constrainsDenseLaneGeometry() {
        let geometry = ScheduleTimelineGeometryPolicy.lanes(
            timelineWidth: 480,
            laneCount: 64,
            preferredGap: 6
        )

        #expect(geometry.cardWidth > 0)
        #expect(geometry.gap >= 0)
        let occupiedWidth = geometry.cardWidth * 64 + geometry.gap * 63
        #expect(occupiedWidth <= 480.000_1)
        #expect(ScheduleTimelineGeometryPolicy.lanes(
            timelineWidth: -20,
            laneCount: 0,
            preferredGap: -2
        ) == ScheduleLaneGeometry(cardWidth: 0, gap: 0))
    }

    @Test("Late schedules render a real midnight boundary")
    func rendersMidnightBoundary() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let late = ScheduleEntry(
            title: "Night Review",
            weekday: .tuesday,
            startMinute: 1_380,
            endMinute: 1_439
        )

        let range = ScheduleTimelinePolicy.visibleRange(entries: [late])
        let midnight = ScheduleTimePolicy.date(for: range.endMinute, calendar: calendar)

        #expect(range.endMinute == 1_440)
        #expect(calendar.component(.hour, from: midnight) == 0)
        #expect(calendar.component(.day, from: midnight) == 2)
        #expect(ScheduleTimePolicy.endMinute(startMinute: 1_380, durationMinutes: 90) == 1_439)
    }

    @Test("Live status distinguishes active, upcoming, and clear time")
    func resolvesLiveStatus() {
        let current = ScheduleEntry(
            title: "Current",
            weekday: .thursday,
            startMinute: 540,
            endMinute: 600
        )
        let next = ScheduleEntry(
            title: "Next",
            weekday: .thursday,
            startMinute: 660,
            endMinute: 720
        )

        #expect(ScheduleLivePolicy.state(
            entries: [next, current],
            weekday: .thursday,
            minute: 570
        ) == .active(entryID: current.id, remainingMinutes: 30))
        #expect(ScheduleLivePolicy.state(
            entries: [next, current],
            weekday: .thursday,
            minute: 620
        ) == .upcoming(entryID: next.id, minutesUntil: 40))
        #expect(ScheduleLivePolicy.state(
            entries: [next, current],
            weekday: .thursday,
            minute: 800
        ) == .clear)
    }

    @Test("Calendar weekdays map to Monday-first schedule days")
    func mapsCalendarWeekdays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let monday = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 24
        )))
        let sunday = try #require(calendar.date(byAdding: .day, value: 6, to: monday))

        #expect(ScheduleWeekday.current(on: monday, calendar: calendar) == .monday)
        #expect(ScheduleWeekday.current(on: sunday, calendar: calendar) == .sunday)
    }

    @Test("Schedule snapshots round-trip in Application Support")
    func persistsSnapshots() throws {
        let root = URL(fileURLWithPath: "/tmp/ClassGodScheduleTests", isDirectory: true)
        let entry = ScheduleEntry(
            title: "Study",
            weekday: .friday,
            startMinute: 900,
            endMinute: 960
        )
        let snapshot = ScheduleSnapshot(entries: [entry])

        #expect(ScheduleStoragePolicy.storageURL(applicationSupportRoot: root) == root
            .appendingPathComponent("ClassGod/Schedule", isDirectory: true)
            .appendingPathComponent("schedule.json"))
        #expect(try ScheduleStoragePolicy.decode(ScheduleStoragePolicy.encode(snapshot)) == snapshot)
    }

    @Test("Schedule labels are localized in English and Simplified Chinese")
    func localizesScheduleLabels() throws {
        let english = Locale(identifier: "en")
        let chineseURL = try #require(Bundle.main.url(forResource: "zh-Hans", withExtension: "lproj"))
        let chinese = try #require(Bundle(url: chineseURL))

        #expect(String(localized: "schedule.title", bundle: .main, locale: english) == "Schedule Lab")
        #expect(String(localized: "schedule.new_entry", bundle: .main, locale: english) == "New Schedule")
        #expect(chinese.localizedString(forKey: "schedule.title", value: nil, table: nil) == "日程实验室")
        #expect(chinese.localizedString(forKey: "schedule.conflict", value: nil, table: nil) == "时间冲突")
        #expect(chinese.localizedString(forKey: "schedule.disabled", value: nil, table: nil) == "已停用")
    }
}
