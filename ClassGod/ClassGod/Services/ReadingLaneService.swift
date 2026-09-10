import Combine

@MainActor
final class ReadingLaneService: ObservableObject {
    static let shared = ReadingLaneService()
    @Published private(set) var source = ""
    @Published private(set) var session = ReadingLaneSession()

    func updateSource(_ value: String) {
        let bounded = ReadingLanePolicy.boundedSource(value)
        guard bounded != source else { return }
        source = bounded
        session = ReadingLaneSession()
    }

    @discardableResult func start() -> Bool { session.start(source: source) }
    func advance() { session.advance() }
    func previous() { session.previous() }
    func editSource() { session = ReadingLaneSession() }
    func clear() { source = ""; session = ReadingLaneSession() }
}
