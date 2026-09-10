import Foundation
import Testing
@testable import ClassGod

@Suite("Recall Lab")
struct RecallLabTests {
    private let now = Date(timeIntervalSince1970: 1_000)

    @Test("Cards trim content, bound input, and reject empty questions or answers")
    func validatesContent() {
        let card = RecallCard(question: "  Question  ", answer: " Answer\n", topic: " School ", dueAt: now)
        let normalized = RecallPolicy.normalized([card])
        #expect(normalized.first?.question == "Question")
        #expect(normalized.first?.answer == "Answer")
        #expect(normalized.first?.topic == "School")
        #expect(RecallPolicy.normalized([RecallCard(question: " \n", answer: "A")]).isEmpty)
        #expect(RecallPolicy.normalized([RecallCard(question: "Q", answer: "\t")]).isEmpty)
        let long = RecallCard(question: String(repeating: "Q", count: 600), answer: String(repeating: "A", count: 6_000))
        #expect(RecallPolicy.normalized([long]).first?.question.count == 500)
        #expect(RecallPolicy.normalized([long]).first?.answer.count == 5_000)
    }

    @Test("Duplicate identities, review levels, dates, and collection size are normalized")
    func normalizesArchive() {
        var card = RecallCard(question: "Q", answer: "A")
        card.level = Int.max
        card.dueAt = Date(timeIntervalSince1970: .infinity)
        var cards = [card, card]
        cards += (0..<600).map { RecallCard(question: "Q\($0)", answer: "A") }
        let result = RecallPolicy.normalized(cards)
        #expect(result.count == 500)
        #expect(Set(result.map(\.id)).count == 500)
        #expect(result[0].level == 5)
        #expect(result[0].dueAt.timeIntervalSince1970.isFinite)
    }

    @Test("Review intervals advance with recall and reset after forgetting")
    func schedulesReviews() {
        let card = RecallCard(question: "Q", answer: "A", dueAt: now)
        let good = RecallPolicy.reviewed(card, grade: .remembered, now: now)
        #expect(good.level == 1)
        #expect(good.dueAt == now.addingTimeInterval(86_400))
        let easy = RecallPolicy.reviewed(good, grade: .easy, now: now)
        #expect(easy.level == 3)
        #expect(easy.dueAt == now.addingTimeInterval(7 * 86_400))
        let again = RecallPolicy.reviewed(easy, grade: .again, now: now)
        #expect(again.level == 0)
        #expect(again.dueAt == now.addingTimeInterval(600))
        var mastered = card
        mastered.level = Int.max
        #expect(RecallPolicy.reviewed(mastered, grade: .easy, now: now).level == 5)
    }

    @Test("Due queue excludes future cards and orders equal dates deterministically")
    func selectsDueCards() {
        let first = RecallCard(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, question: "Q1", answer: "A", dueAt: now)
        let second = RecallCard(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, question: "Q2", answer: "A", dueAt: now)
        let later = RecallCard(question: "Q3", answer: "A", dueAt: now.addingTimeInterval(1))
        #expect(RecallPolicy.dueCards([later, second, first], now: now).map(\.id) == [first.id, second.id])
    }

    @Test("A review requires reveal and each card is graded once per session")
    @MainActor
    func reviewsSession() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = RecallLabService(directory: directory)
        let id = try #require(service.saveCard(question: "Q", answer: "A", topic: "", now: now))
        #expect(service.startReview(now: now))
        #expect(!service.grade(.remembered, now: now))
        #expect(service.reveal())
        #expect(!service.reveal())
        #expect(service.grade(.remembered, now: now))
        #expect(!service.grade(.easy, now: now))
        #expect(service.reviewedCount == 1)
        #expect(service.activeCard == nil)
        #expect(service.cards.first?.id == id)
        #expect(service.cards.first?.level == 1)
        service.endReview()
        #expect(!service.startReview(now: now))
        service.flush()
        #expect(RecallLabService(directory: directory).cards == service.cards)
    }

    @Test("Editing resets scheduling only when content changes and safely ends a review")
    @MainActor
    func editsCards() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = RecallLabService(directory: directory)
        let id = try #require(service.saveCard(question: "Q", answer: "A", topic: "", now: now))
        #expect(service.startReview(now: now))
        _ = service.reveal()
        _ = service.grade(.remembered, now: now)
        _ = service.saveCard(id: id, question: "Q", answer: "A", topic: "", now: now)
        #expect(service.cards[0].level == 1)
        _ = service.saveCard(id: id, question: "Q", answer: "New answer", topic: "", now: now)
        #expect(!service.isReviewing)
        #expect(service.cards[0].level == 0)
        #expect(service.cards[0].dueAt == now)
        #expect(service.delete(id))
        #expect(!service.delete(id))
        service.flush()
        #expect(RecallLabService(directory: directory).cards.isEmpty)
    }

    @Test("Corrupted archives are backed up and future versions are never overwritten")
    @MainActor
    func preservesUnreadableData() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("cards.json")
        let broken = Data("broken".utf8)
        try broken.write(to: url)
        let recovered = RecallLabService(directory: directory)
        #expect(recovered.storageIssue == .recovered)
        #expect(recovered.canEdit)
        let backup = try #require(FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).first { $0.lastPathComponent.hasPrefix("cards-corrupted-") })
        #expect(try Data(contentsOf: backup) == broken)
        let future = Data(#"{"version":99,"entries":[]}"#.utf8)
        try future.write(to: url)
        let blocked = RecallLabService(directory: directory)
        #expect(!blocked.canEdit)
        #expect(blocked.saveCard(question: "Q", answer: "A", topic: "", now: now) == nil)
        blocked.flush()
        #expect(try Data(contentsOf: url) == future)
    }

    @Test("Retry recovers after an unreadable archive is removed")
    @MainActor
    func retriesUnavailableStorage() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("cards.json")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let service = RecallLabService(directory: directory)
        #expect(!service.canEdit)
        try FileManager.default.removeItem(at: url)
        service.retryStorage()
        #expect(service.canEdit)
        #expect(service.storageIssue == nil)
        #expect(service.saveCard(question: "Q", answer: "A", topic: "", now: now) != nil)
        service.flush()
        #expect(RecallLabService(directory: directory).cards.count == 1)
    }

    @Test("Failed writes keep the latest edits available for a successful retry")
    @MainActor
    func retriesFailedSave() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("blocked directory".utf8).write(to: directory)
        let service = RecallLabService(directory: directory)
        let id = try #require(service.saveCard(question: "Q", answer: "A", topic: "", now: now))
        service.flush()
        for _ in 0..<100 {
            if service.storageIssue == .saveFailed { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(service.storageIssue == .saveFailed)
        #expect(service.canEdit)
        #expect(service.cards.count == 1)
        _ = service.saveCard(id: id, question: "Q", answer: "Latest answer", topic: "", now: now)
        try FileManager.default.removeItem(at: directory)
        service.retryStorage()
        service.flush()
        for _ in 0..<100 {
            if service.storageIssue == nil { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(service.storageIssue == nil)
        #expect(RecallLabService(directory: directory).cards.first?.answer == "Latest answer")
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("ClassGodRecallTests-\(UUID())")
    }
}
