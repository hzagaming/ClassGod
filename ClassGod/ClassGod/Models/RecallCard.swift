import Foundation

nonisolated struct RecallCard: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var question: String
    var answer: String
    var topic: String
    var dueAt: Date
    var level: Int

    init(id: UUID = UUID(), question: String, answer: String, topic: String = "", dueAt: Date = Date(), level: Int = 0) {
        self.id = id
        self.question = question
        self.answer = answer
        self.topic = topic
        self.dueAt = dueAt
        self.level = level
    }
}

nonisolated struct RecallSnapshot: Codable, Sendable {
    var version = 1
    var cards: [RecallCard]
}

nonisolated enum RecallGrade: CaseIterable {
    case again, remembered, easy
}

nonisolated enum RecallPolicy {
    static let maximumCards = 500
    static let maximumArchiveBytes = 32 * 1_024 * 1_024
    static let reviewDays = [1, 3, 7, 14, 30]

    static func text(_ value: String, limit: Int) -> String {
        String(value.prefix(limit)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalized(_ cards: [RecallCard]) -> [RecallCard] {
        var seen: Set<UUID> = []
        var result: [RecallCard] = []
        for var card in cards {
            card.question = text(card.question, limit: 500)
            card.answer = text(card.answer, limit: 5_000)
            card.topic = text(card.topic, limit: 60)
            guard !card.question.isEmpty, !card.answer.isEmpty, seen.insert(card.id).inserted else { continue }
            card.level = min(5, max(0, card.level))
            card.dueAt = normalizedDate(card.dueAt)
            result.append(card)
            if result.count == maximumCards { break }
        }
        return result
    }

    static func dueCards(_ cards: [RecallCard], now: Date) -> [RecallCard] {
        cards.filter { $0.dueAt <= now }.sorted {
            if $0.dueAt != $1.dueAt { return $0.dueAt < $1.dueAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    static func reviewed(_ card: RecallCard, grade: RecallGrade, now: Date) -> RecallCard {
        var result = card
        let level = min(5, max(0, card.level))
        switch grade {
        case .again:
            result.level = 0
            result.dueAt = normalizedDate(now).addingTimeInterval(600)
        case .remembered, .easy:
            result.level = min(5, level + (grade == .easy ? 2 : 1))
            result.dueAt = normalizedDate(now).addingTimeInterval(Double(reviewDays[result.level - 1]) * 86_400)
        }
        return result
    }

    private static func normalizedDate(_ date: Date) -> Date {
        let seconds = date.timeIntervalSince1970
        guard seconds.isFinite else { return Date(timeIntervalSince1970: 0) }
        return Date(timeIntervalSince1970: min(4_102_444_800, max(0, seconds)))
    }
}
