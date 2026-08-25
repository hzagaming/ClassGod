import Foundation

nonisolated enum ScheduleWeekday: Int, Codable, CaseIterable, Identifiable, Sendable {
    case monday = 1
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var id: Self { self }

    static func current(
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> ScheduleWeekday {
        let calendarWeekday = calendar.component(.weekday, from: date)
        return ScheduleWeekday(rawValue: ((calendarWeekday + 5) % 7) + 1) ?? .monday
    }
}

nonisolated enum ScheduleEntryColor: String, Codable, CaseIterable, Identifiable, Sendable {
    case cyan
    case blue
    case mint
    case violet
    case orange
    case rose

    var id: Self { self }
}

nonisolated struct ScheduleEntry: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var title: String
    var weekday: ScheduleWeekday
    var startMinute: Int
    var endMinute: Int
    var location: String
    var notes: String
    var color: ScheduleEntryColor
    var isEnabled: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        weekday: ScheduleWeekday,
        startMinute: Int,
        endMinute: Int,
        location: String = "",
        notes: String = "",
        color: ScheduleEntryColor = .cyan,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.weekday = weekday
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.location = location
        self.notes = notes
        self.color = color
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    var durationMinutes: Int { endMinute - startMinute }
}

nonisolated struct ScheduleSnapshot: Codable, Equatable, Sendable {
    var version: Int
    var entries: [ScheduleEntry]

    init(version: Int = 1, entries: [ScheduleEntry]) {
        self.version = version
        self.entries = entries
    }
}

nonisolated enum ScheduleContentPolicy {
    static let maximumEntryCount = 500
    static let maximumTitleLength = 120
    static let maximumLocationLength = 120
    static let maximumNotesLength = 5_000
    static let minimumDurationMinutes = 15

    static func normalized(_ snapshot: ScheduleSnapshot) -> ScheduleSnapshot {
        var ids = Set<UUID>()
        var entries: [ScheduleEntry] = []
        for entry in snapshot.entries where entries.count < maximumEntryCount {
            guard let entry = normalized(entry), ids.insert(entry.id).inserted else { continue }
            entries.append(entry)
        }
        return ScheduleSnapshot(entries: ScheduleCollectionPolicy.sorted(entries))
    }

    static func normalized(_ entry: ScheduleEntry) -> ScheduleEntry? {
        let title = clean(entry.title, maximumLength: maximumTitleLength)
        guard !title.isEmpty,
              (0..<1_439).contains(entry.startMinute),
              (1...1_439).contains(entry.endMinute),
              entry.durationMinutes >= minimumDurationMinutes else { return nil }
        return ScheduleEntry(
            id: entry.id,
            title: title,
            weekday: entry.weekday,
            startMinute: entry.startMinute,
            endMinute: entry.endMinute,
            location: clean(entry.location, maximumLength: maximumLocationLength),
            notes: String(entry.notes.prefix(maximumNotesLength)),
            color: entry.color,
            isEnabled: entry.isEnabled,
            createdAt: entry.createdAt,
            updatedAt: max(entry.createdAt, entry.updatedAt)
        )
    }

    private static func clean(_ value: String, maximumLength: Int) -> String {
        String(value.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maximumLength))
    }
}

nonisolated enum ScheduleCollectionPolicy {
    static func sorted(_ entries: [ScheduleEntry]) -> [ScheduleEntry] {
        entries.sorted { lhs, rhs in
            if lhs.weekday != rhs.weekday { return lhs.weekday.rawValue < rhs.weekday.rawValue }
            if lhs.startMinute != rhs.startMinute { return lhs.startMinute < rhs.startMinute }
            if lhs.endMinute != rhs.endMinute { return lhs.endMinute < rhs.endMinute }
            if lhs.title != rhs.title {
                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    static func entries(
        for weekday: ScheduleWeekday,
        in entries: [ScheduleEntry]
    ) -> [ScheduleEntry] {
        sorted(entries.filter { $0.weekday == weekday })
    }
}

nonisolated enum ScheduleConflictPolicy {
    static func conflicts(_ lhs: ScheduleEntry, _ rhs: ScheduleEntry) -> Bool {
        lhs.id != rhs.id
            && lhs.isEnabled
            && rhs.isEnabled
            && lhs.weekday == rhs.weekday
            && lhs.startMinute < rhs.endMinute
            && rhs.startMinute < lhs.endMinute
    }

    static func conflictingIDs(_ entries: [ScheduleEntry]) -> [UUID] {
        let entries = ScheduleCollectionPolicy.sorted(entries)
        var conflictingIDs = Set<UUID>()
        for leftIndex in entries.indices {
            for rightIndex in entries.index(after: leftIndex)..<entries.endIndex {
                let lhs = entries[leftIndex]
                let rhs = entries[rightIndex]
                if rhs.weekday != lhs.weekday || rhs.startMinute >= lhs.endMinute { break }
                if conflicts(lhs, rhs) {
                    conflictingIDs.insert(lhs.id)
                    conflictingIDs.insert(rhs.id)
                }
            }
        }
        return entries.compactMap { conflictingIDs.contains($0.id) ? $0.id : nil }
    }
}

nonisolated struct ScheduleEntryLayout: Equatable, Sendable {
    let id: UUID
    let lane: Int
    let laneCount: Int
}

nonisolated struct ScheduleLaneGeometry: Equatable, Sendable {
    let cardWidth: CGFloat
    let gap: CGFloat
}

nonisolated enum ScheduleTimelineGeometryPolicy {
    static func lanes(
        timelineWidth: CGFloat,
        laneCount: Int,
        preferredGap: CGFloat
    ) -> ScheduleLaneGeometry {
        let width = max(0, timelineWidth)
        let laneCount = max(1, laneCount)
        guard width > 0 else { return ScheduleLaneGeometry(cardWidth: 0, gap: 0) }
        let gap = laneCount > 1
            ? min(max(0, preferredGap), width / CGFloat(laneCount) * 0.12)
            : 0
        let cardWidth = max(
            0,
            (width - CGFloat(laneCount - 1) * gap) / CGFloat(laneCount)
        )
        return ScheduleLaneGeometry(cardWidth: cardWidth, gap: gap)
    }
}

nonisolated enum ScheduleLayoutPolicy {
    static func layouts(for entries: [ScheduleEntry]) -> [ScheduleEntryLayout] {
        ScheduleWeekday.allCases.flatMap { weekday in
            layoutsForDay(ScheduleCollectionPolicy.entries(for: weekday, in: entries))
        }
    }

    private static func layoutsForDay(_ entries: [ScheduleEntry]) -> [ScheduleEntryLayout] {
        var result: [ScheduleEntryLayout] = []
        var cluster: [ScheduleEntry] = []
        var clusterEnd = 0

        func appendCluster(_ cluster: [ScheduleEntry], to result: inout [ScheduleEntryLayout]) {
            guard !cluster.isEmpty else { return }
            var laneEnds: [Int] = []
            var assignments: [(id: UUID, lane: Int)] = []
            for entry in cluster {
                let lane = laneEnds.firstIndex(where: { $0 <= entry.startMinute })
                    ?? laneEnds.endIndex
                if lane == laneEnds.endIndex {
                    laneEnds.append(entry.endMinute)
                } else {
                    laneEnds[lane] = entry.endMinute
                }
                assignments.append((entry.id, lane))
            }
            result.append(contentsOf: assignments.map {
                ScheduleEntryLayout(id: $0.id, lane: $0.lane, laneCount: laneEnds.count)
            })
        }

        for entry in entries {
            if !cluster.isEmpty, entry.startMinute >= clusterEnd {
                appendCluster(cluster, to: &result)
                cluster.removeAll(keepingCapacity: true)
            }
            cluster.append(entry)
            clusterEnd = max(clusterEnd, entry.endMinute)
        }
        appendCluster(cluster, to: &result)
        return result
    }
}

nonisolated enum ScheduleLiveState: Equatable, Sendable {
    case active(entryID: UUID, remainingMinutes: Int)
    case upcoming(entryID: UUID, minutesUntil: Int)
    case clear
}

nonisolated enum ScheduleLivePolicy {
    static func state(
        entries: [ScheduleEntry],
        weekday: ScheduleWeekday,
        minute: Int
    ) -> ScheduleLiveState {
        let entries = ScheduleCollectionPolicy.entries(for: weekday, in: entries)
            .filter(\.isEnabled)
        if let active = entries
            .filter({ $0.startMinute <= minute && minute < $0.endMinute })
            .min(by: { lhs, rhs in
                lhs.endMinute == rhs.endMinute
                    ? lhs.startMinute < rhs.startMinute
                    : lhs.endMinute < rhs.endMinute
            }) {
            return .active(entryID: active.id, remainingMinutes: active.endMinute - minute)
        }
        if let upcoming = entries.first(where: { $0.startMinute > minute }) {
            return .upcoming(entryID: upcoming.id, minutesUntil: upcoming.startMinute - minute)
        }
        return .clear
    }
}

nonisolated struct ScheduleTimelineRange: Equatable, Sendable {
    let startMinute: Int
    let endMinute: Int
}

nonisolated enum ScheduleTimelinePolicy {
    static func visibleRange(entries: [ScheduleEntry]) -> ScheduleTimelineRange {
        let earliest = entries.map(\.startMinute).min() ?? 360
        let latest = entries.map(\.endMinute).max() ?? 1_320
        let start = max(0, min(360, earliest / 60 * 60))
        let roundedEnd = min(1_440, ((latest + 59) / 60) * 60)
        return ScheduleTimelineRange(startMinute: start, endMinute: max(1_320, roundedEnd))
    }
}

nonisolated enum ScheduleTimePolicy {
    static func minute(of date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }

    static func date(for minute: Int, calendar: Calendar = .current) -> Date {
        let minute = min(max(0, minute), 1_440)
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = 2001
        components.month = 1
        components.day = 1
        components.hour = minute / 60
        components.minute = minute % 60
        return calendar.date(from: components) ?? Date(timeIntervalSinceReferenceDate: 0)
    }

    static func endMinute(startMinute: Int, durationMinutes: Int) -> Int {
        min(1_439, max(0, startMinute) + max(0, durationMinutes))
    }
}

nonisolated enum ScheduleStoragePolicy {
    static func storageURL(applicationSupportRoot: URL) -> URL {
        applicationSupportRoot
            .appendingPathComponent("ClassGod/Schedule", isDirectory: true)
            .appendingPathComponent("schedule.json")
    }

    static func encode(_ snapshot: ScheduleSnapshot) throws -> Data {
        try JSONEncoder().encode(snapshot)
    }

    static func decode(_ data: Data) throws -> ScheduleSnapshot {
        try JSONDecoder().decode(ScheduleSnapshot.self, from: data)
    }
}
