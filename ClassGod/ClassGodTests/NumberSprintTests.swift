import Foundation
import Testing
@testable import ClassGod

@Suite("Number Sprint")
struct NumberSprintTests {
    @Test("Every difficulty generates ten unique, bounded questions reproducibly")
    func generatesRounds() {
        for difficulty in NumberSprintDifficulty.allCases {
            var first = SeededNumbers(state: 42)
            var second = SeededNumbers(state: 42)
            let questions = NumberSprintPolicy.questions(difficulty: difficulty, using: &first)
            #expect(questions.count == 10)
            #expect(Set(questions).count == 10)
            #expect(questions == NumberSprintPolicy.questions(difficulty: difficulty, using: &second))
            #expect(questions.allSatisfy { (0...99).contains($0.left) && (0...99).contains($0.right) })
            if difficulty == .warmUp { #expect(questions.allSatisfy { $0.answer >= 0 && $0.operation != .multiply }) }
        }
    }

    @Test("Every round balances its supported arithmetic operations")
    func balancesOperations() {
        for difficulty in NumberSprintDifficulty.allCases {
            var random = SeededNumbers(state: 7)
            let questions = NumberSprintPolicy.questions(difficulty: difficulty, using: &random)
            #expect(questions.filter { $0.operation == .add }.count == (difficulty == .warmUp ? 5 : 4))
            #expect(questions.filter { $0.operation == .subtract }.count == (difficulty == .warmUp ? 5 : 3))
            #expect(questions.filter { $0.operation == .multiply }.count == (difficulty == .warmUp ? 0 : 3))
        }
    }

    @Test("Invalid input does not count as an attempt and duplicate answers cannot add points")
    func validatesAnswers() {
        var session = startedSession()
        #expect(session.submit("not a number") == .invalid)
        #expect(session.submit("999999999999999999999999999") == .invalid)
        #expect(session.attempts == 0)
        #expect(session.submit("0") == .correct)
        #expect(session.submit("0") == .ignored)
        #expect(session.solvedCount == 1)
        #expect(session.firstTryCount == 1)
        #expect(session.advance() == true)
        #expect(session.attempts == 0)
    }

    @Test("Wrong answers may be corrected while revealed answers never count as solved")
    func scoresHonestly() {
        var session = startedSession()
        #expect(session.advance() == false)
        #expect(session.submit("2") == .incorrect)
        #expect(session.submit("0") == .correct)
        #expect(session.firstTryCount == 0)
        #expect(session.solvedCount == 1)
        _ = session.advance()
        #expect(session.reveal() == true)
        #expect(session.reveal() == false)
        #expect(session.submit("1") == .ignored)
        #expect(session.solvedCount == 1)
        #expect(session.advance() == true)
    }

    @Test("A full round completes once and restarting removes previous scores")
    func completesRound() {
        var session = startedSession()
        for expected in 0..<10 {
            #expect(session.submit(String(expected)) == .correct)
            #expect(session.advance() == true)
        }
        #expect(session.isComplete)
        #expect(session.solvedCount == 10)
        #expect(session.firstTryCount == 10)
        #expect(session.currentQuestion == nil)
        #expect(session.advance() == false)
        session = startedSession()
        #expect(session.solvedCount == 0)
        #expect(!session.isComplete)
    }

    @Test("Unsafe or incomplete question sets are rejected before arithmetic is evaluated")
    func rejectsInvalidRounds() {
        var session = NumberSprintSession()
        #expect(session.start(questions: []) == false)
        #expect(session.start(questions: Array(repeating: NumberQuestion(left: Int.max, right: 2, operation: .multiply), count: 10)) == false)
        #expect(!session.isStarted)
    }

    private func startedSession() -> NumberSprintSession {
        var session = NumberSprintSession()
        _ = session.start(questions: (0..<10).map { NumberQuestion(left: $0, right: 0, operation: .add) })
        return session
    }
}

private struct SeededNumbers: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
