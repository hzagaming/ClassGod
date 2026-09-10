import Combine

@MainActor
final class TeachBackService: ObservableObject {
    static let shared = TeachBackService()
    @Published private(set) var session = TeachBackSession()

    func update(_ step: TeachBackStep, text: String) { session.update(step, text: text) }
    func next() { session.next() }
    func previous() { session.previous() }
    func toggle(_ check: TeachBackCheck) { session.toggle(check) }
    func clear() { session = TeachBackSession() }
}
