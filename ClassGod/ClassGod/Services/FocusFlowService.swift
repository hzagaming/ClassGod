import Combine
import Foundation

@MainActor
final class FocusFlowService: ObservableObject {
    static let shared = FocusFlowService()

    @Published private(set) var phase: FocusFlowPhase = .focus
    @Published private(set) var preset: FocusFlowPreset = .classic
    @Published private(set) var runState: FocusFlowRunState = .idle
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var dailyStats: FocusFlowDailyStats

    private static let storageKey = "com.hanazar.classgod.focusFlow.dailyStats"
    private static let presetStorageKey = "com.hanazar.classgod.focusFlow.preset"
    private let defaults: UserDefaults
    private var deadline: Date?
    private var pausedRemaining: TimeInterval
    private var timer: Timer?

    init(defaults: UserDefaults = .standard, now: Date = Date()) {
        self.defaults = defaults
        let initialPreset = defaults.string(forKey: Self.presetStorageKey)
            .flatMap(FocusFlowPreset.init(rawValue:)) ?? .classic
        preset = initialPreset
        dailyStats = Self.loadDailyStats(from: defaults, key: Self.storageKey, now: now)
        let initial = FocusFlowPolicy.durationSeconds(for: .focus, preset: initialPreset)
        remainingSeconds = initial
        pausedRemaining = TimeInterval(initial)
    }

    var phaseDurationSeconds: Int {
        FocusFlowPolicy.durationSeconds(for: phase, preset: preset)
    }

    var progress: Double {
        FocusFlowPolicy.progress(
            remainingSeconds: remainingSeconds,
            totalSeconds: phaseDurationSeconds
        )
    }

    var completedSessionsInCycle: Int {
        FocusFlowPolicy.completedSessionsInCycle(
            during: phase,
            completedFocusSessions: dailyStats.completedSessions
        )
    }

    var sessionsUntilLongBreak: Int? {
        FocusFlowPolicy.sessionsUntilLongBreak(
            during: phase,
            completedFocusSessions: dailyStats.completedSessions
        )
    }

    var clockText: String {
        FocusFlowTimePolicy.clockText(seconds: remainingSeconds)
    }

    @discardableResult
    func startOrResume(now: Date = Date()) -> Bool {
        refreshDailyStats(now: now)
        guard runState != .running else { return false }
        let remaining = runState == .paused
            ? max(0.001, pausedRemaining)
            : TimeInterval(max(1, remainingSeconds))
        pausedRemaining = remaining
        deadline = now.addingTimeInterval(pausedRemaining)
        runState = .running
        startTimer()
        update(now: now)
        return true
    }

    @discardableResult
    func pause(now: Date = Date()) -> Bool {
        guard runState == .running else { return false }
        update(now: now)
        let exactRemaining = deadline?.timeIntervalSince(now) ?? pausedRemaining
        pausedRemaining = exactRemaining.isFinite ? max(0, exactRemaining) : 0
        remainingSeconds = Int(ceil(pausedRemaining))
        deadline = nil
        runState = .paused
        stopTimer()
        return true
    }

    @discardableResult
    func reset() -> Bool {
        let changed = runState != .idle || phase != .focus
            || remainingSeconds != FocusFlowPolicy.durationSeconds(for: .focus, preset: preset)
        stopTimer()
        phase = .focus
        runState = .idle
        deadline = nil
        let duration = FocusFlowPolicy.durationSeconds(for: .focus, preset: preset)
        pausedRemaining = TimeInterval(duration)
        remainingSeconds = duration
        return changed
    }

    @discardableResult
    func selectPreset(_ newPreset: FocusFlowPreset) -> Bool {
        guard runState == .idle, newPreset != preset else { return false }
        preset = newPreset
        defaults.set(newPreset.rawValue, forKey: Self.presetStorageKey)
        _ = reset()
        return true
    }

    @discardableResult
    func skipPhase(now: Date = Date()) -> Bool {
        guard runState != .idle else { return false }
        phase = FocusFlowPolicy.skippedPhase(after: phase)
        let duration = phaseDurationSeconds
        remainingSeconds = duration
        pausedRemaining = TimeInterval(duration)
        deadline = runState == .running ? now.addingTimeInterval(pausedRemaining) : nil
        return true
    }

    func refreshDailyStats(now: Date = Date()) {
        let normalized = FocusFlowDailyPolicy.normalized(
            dailyStats,
            now: now,
            calendar: .current
        )
        guard normalized != dailyStats else { return }
        dailyStats = normalized
        saveDailyStats()
    }

    func stop() {
        stopTimer()
    }

    private func startTimer() {
        stopTimer()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.update(now: Date())
            }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func update(now: Date) {
        refreshDailyStats(now: now)
        guard runState == .running else { return }
        let remaining = FocusFlowPolicy.remainingSeconds(
            deadline: deadline,
            pausedRemaining: pausedRemaining,
            now: now
        )
        guard remaining == 0 else {
            remainingSeconds = remaining
            return
        }
        completePhase(now: now)
    }

    private func completePhase(now: Date) {
        let completedPhase = phase
        let transition = FocusFlowPolicy.completedTransition(
            after: completedPhase,
            completedFocusSessions: dailyStats.completedSessions
        )
        if completedPhase.isFocus {
            dailyStats = FocusFlowDailyPolicy.recordingFocusSession(
                in: dailyStats,
                durationSeconds: phaseDurationSeconds,
                now: now,
                calendar: .current
            )
            saveDailyStats()
        }
        phase = transition.phase
        let duration = phaseDurationSeconds
        remainingSeconds = duration
        pausedRemaining = TimeInterval(duration)
        deadline = now.addingTimeInterval(pausedRemaining)
        SoundEffectManager.shared.playFocusPhaseComplete(completedFocus: completedPhase.isFocus)
        HapticManager.shared.success()
    }

    private func saveDailyStats() {
        guard let data = try? JSONEncoder().encode(dailyStats) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    private static func loadDailyStats(
        from defaults: UserDefaults,
        key: String,
        now: Date
    ) -> FocusFlowDailyStats {
        let decoded = defaults.data(forKey: key)
            .flatMap { try? JSONDecoder().decode(FocusFlowDailyStats.self, from: $0) }
            ?? FocusFlowDailyStats(day: now)
        return FocusFlowDailyPolicy.normalized(decoded, now: now, calendar: .current)
    }
}
