import Combine

@MainActor
final class NumberSprintService: ObservableObject {
    static let shared = NumberSprintService()
    @Published var difficulty = NumberSprintDifficulty.warmUp
    @Published private(set) var session = NumberSprintSession()

    func start() {
        var random = SystemRandomNumberGenerator()
        _ = session.start(questions: NumberSprintPolicy.questions(difficulty: difficulty, using: &random))
    }

    func submit(_ answer: String) -> NumberSubmission { session.submit(answer) }
    func reveal() { session.reveal() }
    func advance() { session.advance() }
    func reset() { session = NumberSprintSession() }
}
