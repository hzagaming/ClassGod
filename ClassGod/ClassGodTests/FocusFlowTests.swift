import Foundation
import Testing
@testable import ClassGod

@Suite("Focus Flow")
struct FocusFlowTests {
    @Test("Session controls preserve exact remaining time and reject no-op actions")
    @MainActor
    func controlsSession() {
        let suiteName = "com.hanazar.classgod.tests.focusflow.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let now = Date(timeIntervalSince1970: 1_000)
        let service = FocusFlowService(defaults: defaults, now: now)

        #expect(service.startOrResume(now: now))
        #expect(!service.startOrResume(now: now))
        #expect(service.pause(now: now.addingTimeInterval(10)))
        #expect(service.runState == .paused)
        #expect(service.remainingSeconds == 1_490)
        #expect(!service.pause(now: now.addingTimeInterval(10)))

        #expect(!service.selectPreset(.quick))
        #expect(service.runState == .paused)
        #expect(service.remainingSeconds == 1_490)
        #expect(service.reset())
        #expect(service.selectPreset(.quick))
        #expect(service.runState == .idle)
        #expect(service.phase == .focus)
        #expect(service.remainingSeconds == 900)
        #expect(!service.selectPreset(.quick))
        #expect(!service.skipPhase(now: now))

        #expect(service.startOrResume(now: now))
        #expect(service.pause(now: now))
        #expect(service.skipPhase(now: now))
        #expect(service.phase == .shortBreak)
        #expect(service.remainingSeconds == 180)
        service.stop()
    }

    @Test("Preset selection survives service recreation")
    @MainActor
    func persistsPresetSelection() {
        let suiteName = "com.hanazar.classgod.tests.focusflow.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let first = FocusFlowService(defaults: defaults)
        #expect(first.selectPreset(.deep))

        let restored = FocusFlowService(defaults: defaults)
        #expect(restored.preset == .deep)
        #expect(restored.remainingSeconds == 50 * 60)
    }

    @Test("Repeated pause and resume never gifts fractional seconds")
    @MainActor
    func preservesFractionalRemainingTime() {
        let suiteName = "com.hanazar.classgod.tests.focusflow.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let service = FocusFlowService(defaults: defaults)
        var now = Date(timeIntervalSince1970: 2_000)

        for _ in 0..<4 {
            #expect(service.startOrResume(now: now))
            #expect(service.pause(now: now.addingTimeInterval(0.25)))
            now = now.addingTimeInterval(1)
        }

        #expect(service.remainingSeconds == 1_499)
        service.stop()
    }

    @Test("Presets expose bounded focus and break durations")
    func resolvesPresetDurations() {
        #expect(FocusFlowPolicy.durationSeconds(for: .focus, preset: .quick) == 15 * 60)
        #expect(FocusFlowPolicy.durationSeconds(for: .shortBreak, preset: .classic) == 5 * 60)
        #expect(FocusFlowPolicy.durationSeconds(for: .longBreak, preset: .deep) == 20 * 60)
    }

    @Test("Every fourth completed focus enters a long break")
    func advancesCompletedPhases() {
        #expect(FocusFlowPolicy.completedTransition(
            after: .focus,
            completedFocusSessions: 0
        ) == FocusFlowTransition(phase: .shortBreak, completedFocusSessions: 1))
        #expect(FocusFlowPolicy.completedTransition(
            after: .focus,
            completedFocusSessions: 3
        ) == FocusFlowTransition(phase: .longBreak, completedFocusSessions: 4))
        #expect(FocusFlowPolicy.completedTransition(
            after: .longBreak,
            completedFocusSessions: 4
        ) == FocusFlowTransition(phase: .focus, completedFocusSessions: 4))
    }

    @Test("Cycle presentation stays complete during the earned long break")
    func presentsLongBreakCycle() {
        #expect(FocusFlowPolicy.normalizedCycleSessions(-1) == 0)
        #expect(FocusFlowPolicy.normalizedCycleSessions(7) == 3)
        #expect(FocusFlowPolicy.completedSessionsInCycle(
            during: .focus,
            completedFocusSessions: 3
        ) == 3)
        #expect(FocusFlowPolicy.completedSessionsInCycle(
            during: .longBreak,
            completedFocusSessions: 4
        ) == 4)
        #expect(FocusFlowPolicy.sessionsUntilLongBreak(
            during: .focus,
            completedFocusSessions: 4
        ) == 4)
        #expect(FocusFlowPolicy.sessionsUntilLongBreak(
            during: .longBreak,
            completedFocusSessions: 4
        ) == nil)
    }

    @Test("Skipping never awards a completed focus session")
    func skipsWithoutCompletion() {
        #expect(FocusFlowPolicy.skippedPhase(after: .focus) == .shortBreak)
        #expect(FocusFlowPolicy.skippedPhase(after: .shortBreak) == .focus)
        #expect(FocusFlowPolicy.skippedPhase(after: .longBreak) == .focus)
    }

    @Test("Countdown derives from an absolute deadline without drift")
    func resolvesRemainingTime() {
        let now = Date(timeIntervalSince1970: 1_000)
        #expect(FocusFlowPolicy.remainingSeconds(
            deadline: now.addingTimeInterval(10.2),
            pausedRemaining: 99,
            now: now
        ) == 11)
        #expect(FocusFlowPolicy.remainingSeconds(
            deadline: now.addingTimeInterval(-1),
            pausedRemaining: 99,
            now: now
        ) == 0)
        #expect(FocusFlowPolicy.remainingSeconds(
            deadline: nil,
            pausedRemaining: -5,
            now: now
        ) == 0)
    }

    @Test("Progress and clock text stay inside valid boundaries")
    func formatsProgress() {
        #expect(FocusFlowPolicy.progress(remainingSeconds: 75, totalSeconds: 100) == 0.25)
        #expect(FocusFlowPolicy.progress(remainingSeconds: -5, totalSeconds: 100) == 1)
        #expect(FocusFlowPolicy.progress(remainingSeconds: 10, totalSeconds: 0) == 0)
        #expect(FocusFlowTimePolicy.clockText(seconds: 1_501) == "25:01")
        #expect(FocusFlowTimePolicy.clockText(seconds: -1) == "00:00")
    }

    @Test("Daily statistics reset across calendar days and sanitize corruption")
    func normalizesDailyStatistics() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = Date(timeIntervalSince1970: 86_400)
        let sameDay = FocusFlowDailyStats(
            day: today,
            completedSessions: -4,
            focusedSeconds: -100
        )
        let previousDay = FocusFlowDailyStats(
            day: Date(timeIntervalSince1970: 0),
            completedSessions: 8,
            focusedSeconds: 12_000
        )

        #expect(FocusFlowDailyPolicy.normalized(
            sameDay,
            now: today,
            calendar: calendar
        ) == FocusFlowDailyStats(day: calendar.startOfDay(for: today)))
        #expect(FocusFlowDailyPolicy.normalized(
            previousDay,
            now: today,
            calendar: calendar
        ) == FocusFlowDailyStats(day: calendar.startOfDay(for: today)))
        #expect(FocusFlowDailyPolicy.recordingFocusSession(
            in: previousDay,
            durationSeconds: 1_500,
            now: today,
            calendar: calendar
        ) == FocusFlowDailyStats(
            day: calendar.startOfDay(for: today),
            completedSessions: 1,
            focusedSeconds: 1_500
        ))
    }

    @Test("Four-session cycle survives daily statistics rollover")
    @MainActor
    func preservesCycleAcrossDays() {
        let suiteName = "com.hanazar.classgod.tests.focusflow.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let calendar = Calendar.current
        var now = calendar.startOfDay(for: Date()).addingTimeInterval(12 * 60 * 60)
        let service = FocusFlowService(defaults: defaults, now: now)
        #expect(service.selectPreset(.quick))

        for _ in 0..<3 {
            #expect(service.startOrResume(now: now))
            now = now.addingTimeInterval(15 * 60)
            #expect(service.pause(now: now))
            #expect(service.phase == .shortBreak)
            #expect(service.skipPhase(now: now))
            #expect(service.phase == .focus)
        }

        #expect(service.completedSessionsInCycle == 3)
        #expect(service.sessionsUntilLongBreak == 1)

        let nextDay = calendar.date(byAdding: .day, value: 1, to: now)!
        service.refreshDailyStats(now: nextDay)
        #expect(service.dailyStats.completedSessions == 0)
        #expect(service.completedSessionsInCycle == 3)
        #expect(service.sessionsUntilLongBreak == 1)

        let restored = FocusFlowService(defaults: defaults, now: nextDay)
        #expect(restored.completedSessionsInCycle == 3)
        #expect(restored.sessionsUntilLongBreak == 1)
        service.stop()
    }
}
