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
        var questions: [NumberQuestion] = []
        questions.reserveCapacity(10)
        for operation in [NumberOperation.add, .subtract, .multiply] {
            if operation == .multiply && difficulty == .warmUp { continue }
            let operandCount = operation == .multiply ? (difficulty == .challenge ? 20 : 12) : limit + 1
            let allowsNegative = operation == .subtract && difficulty == .challenge
            let population = allowsNegative ? operandCount * operandCount : operandCount * (operandCount + 1) / 2
            let count = difficulty == .warmUp ? 5 : (operation == .add ? 4 : 3)
            let offset = operation == .multiply ? 1 : 0
            var sampled: [Int] = []
            sampled.reserveCapacity(count)
            // Floyd sampling selects a uniform subset without constructing the candidate pool.
            for upperBound in (population - count)..<population {
                let candidate = Int.random(in: 0...upperBound, using: &random)
                let index = sampled.contains(candidate) ? upperBound : candidate
                sampled.append(index)
                // Canonical pairs occupy triangular rows: (0,0), (1,0), (1,1), ...
                let left = allowsNegative ? index / operandCount : Int((Double(8 * index + 1).squareRoot() - 1) / 2)
                let right = allowsNegative ? index % operandCount : index - left * (left + 1) / 2
                questions.append(.init(left: left + offset, right: right + offset, operation: operation))
            }
        }
        questions.shuffle(using: &random)
        return questions
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
