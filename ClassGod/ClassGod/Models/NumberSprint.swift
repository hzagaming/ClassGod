import Foundation

nonisolated enum NumberSprintDifficulty: CaseIterable, Hashable { case warmUp, mixed, challenge }
nonisolated enum NumberOperation: String, Hashable { case add = "+", subtract = "−", multiply = "×" }
nonisolated enum NumberSubmission { case invalid, incorrect, correct, ignored }

nonisolated struct NumberQuestion: Hashable {
    let left: Int
    let right: Int
    let operation: NumberOperation

    var answer: Int {
        switch operation {
        case .add: left + right
        case .subtract: left - right
        case .multiply: left * right
        }
    }

    var expression: String { "\(left) \(operation.rawValue) \(right)" }
}

nonisolated enum NumberSprintPolicy {
    static func questions<R: RandomNumberGenerator>(difficulty: NumberSprintDifficulty, using random: inout R) -> [NumberQuestion] {
        let limit = difficulty == .challenge ? 99 : 12
        var additions: [NumberQuestion] = []
        var subtractions: [NumberQuestion] = []
        var multiplications: [NumberQuestion] = []
        for left in 0...limit {
            for right in 0...limit {
                if left >= right { additions.append(.init(left: left, right: right, operation: .add)) }
                if difficulty == .challenge || left >= right {
                    subtractions.append(.init(left: left, right: right, operation: .subtract))
                }
            }
        }
        if difficulty != .warmUp {
            for left in 1...(difficulty == .challenge ? 20 : 12) {
                for right in 1...left { multiplications.append(.init(left: left, right: right, operation: .multiply)) }
            }
        }
        let questions = Array(additions.shuffled(using: &random).prefix(difficulty == .warmUp ? 5 : 4))
            + Array(subtractions.shuffled(using: &random).prefix(difficulty == .warmUp ? 5 : 3))
            + Array(multiplications.shuffled(using: &random).prefix(difficulty == .warmUp ? 0 : 3))
        return questions.shuffled(using: &random)
    }
}

nonisolated struct NumberSprintResult: Equatable {
    let question: NumberQuestion
    let attempts: Int
    let wasRevealed: Bool
}

nonisolated struct NumberSprintSession: Equatable {
    private(set) var questions: [NumberQuestion] = []
    private(set) var position = 0
    private(set) var attempts = 0
    private(set) var results: [NumberSprintResult] = []
    var isStarted: Bool { !questions.isEmpty }
    var isComplete: Bool { isStarted && position == questions.count }
    var currentQuestion: NumberQuestion? { questions.indices.contains(position) ? questions[position] : nil }
    var currentResult: NumberSprintResult? { results.indices.contains(position) ? results[position] : nil }
    var solvedCount: Int { results.filter { !$0.wasRevealed }.count }
    var firstTryCount: Int { results.filter { !$0.wasRevealed && $0.attempts == 1 }.count }

    mutating func start(questions: [NumberQuestion]) -> Bool {
        guard questions.count == 10, Set(questions).count == 10,
              questions.allSatisfy({ (0...99).contains($0.left) && (0...99).contains($0.right) }) else { return false }
        self = NumberSprintSession()
        self.questions = questions
        return true
    }

    mutating func submit(_ text: String) -> NumberSubmission {
        guard let question = currentQuestion, currentResult == nil else { return .ignored }
        guard let answer = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return .invalid }
        attempts += 1
        guard answer == question.answer else { return .incorrect }
        results.append(.init(question: question, attempts: attempts, wasRevealed: false))
        return .correct
    }

    @discardableResult mutating func reveal() -> Bool {
        guard let question = currentQuestion, currentResult == nil else { return false }
        results.append(.init(question: question, attempts: attempts, wasRevealed: true))
        return true
    }

    @discardableResult mutating func advance() -> Bool {
        guard currentQuestion != nil, currentResult != nil else { return false }
        position += 1
        attempts = 0
        return true
    }
}
