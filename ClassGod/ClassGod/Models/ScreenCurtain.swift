import Foundation

nonisolated struct ScreenCurtainSession: Equatable {
    private(set) var id = UUID()
    private(set) var isActive = false
    private(set) var remainingSeconds = 0
    private var deadline: TimeInterval = 0
    private var lastTime: TimeInterval = 0

    mutating func start(now: TimeInterval, duration: TimeInterval) -> Bool {
        guard !isActive, now.isFinite, now >= 0, now < 1e12, duration.isFinite else { return false }
        self = ScreenCurtainSession()
        let duration = min(120, max(15, duration))
        deadline = now + duration
        lastTime = now
        remainingSeconds = Int(ceil(duration))
        isActive = true
        return true
    }

    mutating func tick(now: TimeInterval) {
        guard isActive else { return }
        guard now.isFinite, now >= lastTime, now < deadline else { cancel(); return }
        lastTime = now
        remainingSeconds = Int(ceil(deadline - now))
    }

    mutating func cancel() { isActive = false; remainingSeconds = 0 }
}
