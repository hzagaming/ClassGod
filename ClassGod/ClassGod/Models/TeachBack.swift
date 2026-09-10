import Foundation

nonisolated enum TeachBackStep: Int, CaseIterable {
    case topic, explanation, example, gap
    var limit: Int { self == .topic ? 120 : 2_000 }
}

nonisolated enum TeachBackCheck: CaseIterable, Hashable { case ownWords, exampleFits, gapReviewed }

nonisolated struct TeachBackSession: Equatable {
    private var answers = Array(repeating: "", count: TeachBackStep.allCases.count)
    private(set) var step = TeachBackStep.topic
    private(set) var isReviewing = false
    private(set) var checked: Set<TeachBackCheck> = []

    var hasContent: Bool { answers.contains { !$0.isEmpty } }
    var canAdvance: Bool { !isReviewing && (step == .gap || !trimmed(step).isEmpty) }
    func text(for step: TeachBackStep) -> String { answers[step.rawValue] }

    mutating func update(_ step: TeachBackStep, text: String) {
        let bounded = String(text.prefix(step.limit))
        guard bounded != answers[step.rawValue] else { return }
        answers[step.rawValue] = bounded
        checked = []
        isReviewing = false
    }

    @discardableResult mutating func next() -> Bool {
        guard canAdvance else { return false }
        if let next = TeachBackStep(rawValue: step.rawValue + 1) { step = next }
        else {
            guard [.topic, .explanation, .example].allSatisfy({ !trimmed($0).isEmpty }) else { return false }
            isReviewing = true
        }
        return true
    }

    mutating func previous() {
        if isReviewing { isReviewing = false }
        else if let previous = TeachBackStep(rawValue: step.rawValue - 1) { step = previous }
    }

    mutating func toggle(_ check: TeachBackCheck) {
        guard isReviewing else { return }
        if checked.contains(check) { checked.remove(check) } else { checked.insert(check) }
    }

    func summary(headings: [String]) -> String? {
        guard isReviewing, headings.count == answers.count else { return nil }
        return TeachBackStep.allCases.compactMap { step in
            let text = trimmed(step)
            return text.isEmpty ? nil : headings[step.rawValue] + "\n" + text
        }.joined(separator: "\n\n")
    }

    private func trimmed(_ step: TeachBackStep) -> String {
        text(for: step).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
