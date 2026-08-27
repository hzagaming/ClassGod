import Foundation

nonisolated enum FocusFlowPhase: String, CaseIterable, Sendable {
    case focus
    case shortBreak
    case longBreak

    var isFocus: Bool { self == .focus }
}

nonisolated enum FocusFlowPreset: String, CaseIterable, Identifiable, Sendable {
    case quick
    case classic
    case deep

    var id: Self { self }

    var focusMinutes: Int {
        switch self {
        case .quick: 15
        case .classic: 25
        case .deep: 50
        }
    }

    var shortBreakMinutes: Int {
        switch self {
        case .quick: 3
        case .classic: 5
        case .deep: 10
        }
    }

    var longBreakMinutes: Int {
        switch self {
        case .quick: 10
        case .classic: 15
        case .deep: 20
        }
    }
}

nonisolated enum FocusFlowRunState: Sendable {
    case idle
    case running
    case paused
}

nonisolated struct FocusFlowTransition: Equatable, Sendable {
    let phase: FocusFlowPhase
    let completedFocusSessions: Int
}

nonisolated enum FocusFlowPolicy {
    static let focusSessionsBeforeLongBreak = 4

    static func normalizedCycleSessions(_ completedFocusSessions: Int) -> Int {
        max(0, completedFocusSessions) % focusSessionsBeforeLongBreak
    }

    static func durationSeconds(
        for phase: FocusFlowPhase,
        preset: FocusFlowPreset
    ) -> Int {
        let minutes = switch phase {
        case .focus: preset.focusMinutes
        case .shortBreak: preset.shortBreakMinutes
        case .longBreak: preset.longBreakMinutes
        }
        return minutes * 60
    }

    static func completedTransition(
        after phase: FocusFlowPhase,
        completedFocusSessions: Int
    ) -> FocusFlowTransition {
        let completed = max(0, completedFocusSessions)
        guard phase.isFocus else {
            return FocusFlowTransition(phase: .focus, completedFocusSessions: completed)
        }
        let nextCompleted = completed + 1
        let nextPhase: FocusFlowPhase = nextCompleted.isMultiple(of: focusSessionsBeforeLongBreak)
            ? .longBreak
            : .shortBreak
        return FocusFlowTransition(
            phase: nextPhase,
            completedFocusSessions: nextCompleted
        )
    }

    static func skippedPhase(after phase: FocusFlowPhase) -> FocusFlowPhase {
        phase.isFocus ? .shortBreak : .focus
    }

    static func remainingSeconds(
        deadline: Date?,
        pausedRemaining: TimeInterval,
        now: Date
    ) -> Int {
        let remaining = deadline?.timeIntervalSince(now) ?? pausedRemaining
        guard remaining.isFinite else { return 0 }
        return max(0, Int(ceil(remaining)))
    }

    static func progress(remainingSeconds: Int, totalSeconds: Int) -> Double {
        guard totalSeconds > 0 else { return 0 }
        let remaining = min(max(0, remainingSeconds), totalSeconds)
        return 1 - Double(remaining) / Double(totalSeconds)
    }

    static func completedSessionsInCycle(
        during phase: FocusFlowPhase,
        completedFocusSessions: Int
    ) -> Int {
        let remainder = normalizedCycleSessions(completedFocusSessions)
        return phase == .longBreak ? focusSessionsBeforeLongBreak : remainder
    }

    static func sessionsUntilLongBreak(
        during phase: FocusFlowPhase,
        completedFocusSessions: Int
    ) -> Int? {
        guard phase != .longBreak else { return nil }
        let remainder = normalizedCycleSessions(completedFocusSessions)
        return focusSessionsBeforeLongBreak - remainder
    }
}

nonisolated enum FocusFlowTimePolicy {
    static func clockText(seconds: Int) -> String {
        let seconds = max(0, seconds)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

nonisolated struct FocusFlowDailyStats: Codable, Equatable, Sendable {
    var day: Date
    var completedSessions: Int
    var focusedSeconds: Int

    init(day: Date, completedSessions: Int = 0, focusedSeconds: Int = 0) {
        self.day = day
        self.completedSessions = completedSessions
        self.focusedSeconds = focusedSeconds
    }
}

nonisolated enum FocusFlowDailyPolicy {
    static let maximumSessionsPerDay = 1_000
    static let maximumFocusedSecondsPerDay = 86_400

    static func normalized(
        _ stats: FocusFlowDailyStats,
        now: Date,
        calendar: Calendar
    ) -> FocusFlowDailyStats {
        let today = calendar.startOfDay(for: now)
        guard calendar.isDate(stats.day, inSameDayAs: now) else {
            return FocusFlowDailyStats(day: today)
        }
        return FocusFlowDailyStats(
            day: today,
            completedSessions: min(max(0, stats.completedSessions), maximumSessionsPerDay),
            focusedSeconds: min(max(0, stats.focusedSeconds), maximumFocusedSecondsPerDay)
        )
    }

    static func recordingFocusSession(
        in stats: FocusFlowDailyStats,
        durationSeconds: Int,
        now: Date,
        calendar: Calendar
    ) -> FocusFlowDailyStats {
        var stats = normalized(stats, now: now, calendar: calendar)
        stats.completedSessions = min(stats.completedSessions + 1, maximumSessionsPerDay)
        stats.focusedSeconds = min(
            stats.focusedSeconds + max(0, durationSeconds),
            maximumFocusedSecondsPerDay
        )
        return stats
    }
}
