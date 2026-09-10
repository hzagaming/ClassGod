import Foundation

nonisolated struct SwitchDrillTarget: Identifiable, Equatable, Sendable {
    enum Kind: Sendable { case browser, application }
    let id: UUID
    let name: String
    let shortcut: String
    let kind: Kind
    let destination: String

    init(id: UUID, name: String, shortcut: String, kind: Kind, destination: String = "") {
        self.id = id
        self.name = name
        self.shortcut = shortcut
        self.kind = kind
        self.destination = destination
    }

    static func available(_ candidates: [Self], registeredIDs: Set<UUID>) -> [Self] {
        let groups = Dictionary(grouping: candidates, by: \.id)
        return candidates.filter { registeredIDs.contains($0.id) && groups[$0.id]?.count == 1 }
    }
}

nonisolated enum SwitchDrillPhase { case idle, waiting, ready, switching, finished }
nonisolated enum SwitchDrillOutcome { case success, tooSoon, wrongTarget, timeout, switchFailed, interrupted }

nonisolated struct SwitchDrillResult: Identifiable, Equatable, Sendable {
    let id: UUID
    let outcome: SwitchDrillOutcome
    let reactionSeconds: TimeInterval?
    let switchSeconds: TimeInterval?
}

nonisolated struct SwitchDrillSession: Equatable, Sendable {
    private(set) var phase: SwitchDrillPhase = .idle
    private(set) var targetID: UUID?
    private(set) var result: SwitchDrillResult?
    private(set) var id = UUID()
    private var cueDeadline: TimeInterval = 0
    private var cueTime: TimeInterval = 0
    private var pressedTime: TimeInterval = 0
    private var lastTime: TimeInterval = 0

    var isActive: Bool { phase == .waiting || phase == .ready || phase == .switching }

    mutating func start(targetID: UUID, now: TimeInterval, delay: TimeInterval) -> Bool {
        guard !isActive, now.isFinite, delay.isFinite, now >= 0, now < 1e12 else { return false }
        self = SwitchDrillSession()
        self.targetID = targetID
        phase = .waiting
        cueDeadline = now + min(5, max(2, delay))
        lastTime = now
        return true
    }

    mutating func tick(now: TimeInterval) {
        guard isActive, validateTime(now) else { return }
        switch phase {
        case .waiting where now >= cueDeadline:
            cueTime = now
            phase = .ready
        case .ready where now - cueTime >= 10:
            finish(.timeout, now: now)
        case .switching where now - pressedTime >= 15:
            finish(.switchFailed, now: now)
        default: break
        }
    }

    mutating func press(targetID: UUID, now: TimeInterval) -> UUID? {
        guard isActive, validateTime(now) else { return nil }
        if phase == .waiting {
            finish(.tooSoon, now: now)
        } else if phase == .switching {
            finish(.interrupted, now: now)
        } else if now - cueTime >= 10 {
            finish(.timeout, now: now)
        } else if targetID != self.targetID {
            finish(.wrongTarget, now: now)
        } else {
            pressedTime = now
            phase = .switching
            return id
        }
        return nil
    }

    mutating func complete(requestID: UUID, success: Bool, now: TimeInterval) -> Bool {
        guard requestID == id, phase == .switching, validateTime(now) else { return false }
        guard now - pressedTime < 15 else {
            finish(.switchFailed, now: now)
            return false
        }
        finish(success ? .success : .switchFailed, now: now)
        return true
    }

    mutating func cancel() { self = SwitchDrillSession() }

    private mutating func validateTime(_ now: TimeInterval) -> Bool {
        guard now.isFinite, now >= lastTime, now < 1e12 else {
            cancel()
            return false
        }
        lastTime = now
        return true
    }

    private mutating func finish(_ outcome: SwitchDrillOutcome, now: TimeInterval) {
        result = SwitchDrillResult(
            id: id,
            outcome: outcome,
            reactionSeconds: phase == .switching ? pressedTime - cueTime : nil,
            switchSeconds: phase == .switching ? now - pressedTime : nil
        )
        phase = .finished
    }
}
