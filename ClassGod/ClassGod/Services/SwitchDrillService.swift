import Combine
import Foundation

@MainActor
final class SwitchDrillService: ObservableObject {
    static let shared = SwitchDrillService()

    @Published private(set) var targets: [SwitchDrillTarget] = []
    @Published private(set) var selectedID: UUID?
    private(set) var session = SwitchDrillSession()
    @Published private(set) var recentResults: [SwitchDrillResult] = []

    private let clock: () -> TimeInterval
    private var timerTask: Task<Void, Never>?

    var selectedTarget: SwitchDrillTarget? { targets.first { $0.id == selectedID } }

    init(clock: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.clock = clock
    }

    func updateTargets(_ targets: [SwitchDrillTarget]) {
        if selectedTarget != targets.first(where: { $0.id == selectedID }) {
            cancel()
        }
        self.targets = targets
        if !targets.contains(where: { $0.id == selectedID }) { selectedID = targets.first?.id }
    }

    func select(_ id: UUID) {
        guard !session.isActive, targets.contains(where: { $0.id == id }), id != selectedID else { return }
        cancel()
        selectedID = id
    }

    @discardableResult
    func start(delay: TimeInterval = Double.random(in: 2...5)) -> Bool {
        var next = session
        guard let selectedID, selectedTarget != nil,
              next.start(targetID: selectedID, now: clock(), delay: delay) else { return false }
        publish(next)
        timerTask?.cancel()
        let generation = session.id
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(25))
                guard !Task.isCancelled, let self, self.session.id == generation else { return }
                self.refreshTime()
                if !self.session.isActive { return }
            }
        }
        return true
    }

    func shortcutPressed(targetID: UUID) -> UUID? {
        var next = session
        let request = next.press(targetID: targetID, now: clock())
        publish(next)
        return request
    }

    func complete(requestID: UUID?, success: Bool) {
        guard let requestID else { return }
        var next = session
        _ = next.complete(requestID: requestID, success: success, now: clock())
        publish(next)
    }

    func cancel() {
        timerTask?.cancel()
        timerTask = nil
        publish(SwitchDrillSession())
    }

    func refreshTime() {
        var next = session
        next.tick(now: clock())
        publish(next)
    }

    private func publish(_ next: SwitchDrillSession) {
        if next.phase != session.phase || next.result != session.result || next.id != session.id {
            objectWillChange.send()
        }
        session = next
        if let result = next.result, !recentResults.contains(where: { $0.id == result.id }) {
            recentResults.insert(result, at: 0)
            recentResults = Array(recentResults.prefix(5))
        }
        if !next.isActive {
            timerTask?.cancel()
            timerTask = nil
        }
    }
}
