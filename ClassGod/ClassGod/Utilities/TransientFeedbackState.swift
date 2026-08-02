struct TransientFeedbackState<Value: Equatable> {
    private(set) var value: Value?
    private var generation: UInt = 0

    mutating func present(_ value: Value) -> UInt {
        generation &+= 1
        self.value = value
        return generation
    }

    @discardableResult
    mutating func dismiss(ifCurrent token: UInt) -> Bool {
        guard token == generation else { return false }
        value = nil
        return true
    }

    mutating func reset() {
        generation &+= 1
        value = nil
    }
}

nonisolated enum AsyncRequestPolicy {
    static func shouldApply(request: UInt, current: UInt, isCancelled: Bool) -> Bool {
        request == current && !isCancelled
    }
}
