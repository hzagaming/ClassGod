import Combine
import Foundation

@MainActor
final class RecallLabService: ObservableObject {
    static let shared = RecallLabService(directory: (
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
    ).appendingPathComponent("ClassGod/RecallLab", isDirectory: true))

    enum StorageIssue {
        case recovered, loadFailed, saveFailed, unsupportedVersion
    }

    @Published private(set) var cards: [RecallCard] = []
    @Published private(set) var isReviewing = false
    @Published private(set) var isRevealed = false
    @Published private(set) var reviewedCount = 0
    @Published private(set) var sessionTotal = 0
    @Published private(set) var storageIssue: StorageIssue?
    @Published private(set) var canEdit = true

    private var reviewIDs: [UUID] = []
    private let directory: URL
    private let storageURL: URL
    private let persistenceQueue = DispatchQueue(label: "com.hanazar.classgod.recall.persistence", qos: .utility)
    private var saveTask: Task<Void, Never>?
    private var hasPendingSave = false
    private var revision: UInt = 0

    var activeCard: RecallCard? {
        guard isReviewing, let id = reviewIDs.first else { return nil }
        return cards.first { $0.id == id }
    }

    init(directory: URL) {
        self.directory = directory
        storageURL = directory.appendingPathComponent("cards.json")
        load()
    }

    @discardableResult
    func saveCard(id: UUID? = nil, question: String, answer: String, topic: String, now: Date = Date()) -> UUID? {
        guard canEdit, id != nil || cards.count < RecallPolicy.maximumCards,
              let card = RecallPolicy.normalized([
                RecallCard(id: id ?? UUID(), question: question, answer: answer, topic: topic, dueAt: now)
              ]).first else { return nil }
        if let id {
            guard let index = cards.firstIndex(where: { $0.id == id }) else { return nil }
            let old = cards[index]
            guard old.question != card.question || old.answer != card.answer || old.topic != card.topic else { return id }
            endReview()
            cards[index] = card
        } else {
            endReview()
            cards.append(card)
        }
        save()
        return card.id
    }

    @discardableResult
    func delete(_ id: UUID) -> Bool {
        guard canEdit, cards.contains(where: { $0.id == id }) else { return false }
        endReview()
        cards.removeAll { $0.id == id }
        save()
        return true
    }

    @discardableResult
    func startReview(now: Date = Date()) -> Bool {
        guard canEdit, !isReviewing else { return false }
        let due = RecallPolicy.dueCards(cards, now: now)
        guard !due.isEmpty else { return false }
        reviewIDs = due.map(\.id)
        reviewedCount = 0
        sessionTotal = due.count
        isRevealed = false
        isReviewing = true
        return true
    }

    @discardableResult
    func reveal() -> Bool {
        guard activeCard != nil, !isRevealed else { return false }
        isRevealed = true
        return true
    }

    @discardableResult
    func grade(_ grade: RecallGrade, now: Date = Date()) -> Bool {
        guard canEdit, isRevealed, let card = activeCard,
              let index = cards.firstIndex(where: { $0.id == card.id }) else { return false }
        cards[index] = RecallPolicy.reviewed(card, grade: grade, now: now)
        reviewIDs.removeFirst()
        isRevealed = false
        reviewedCount += 1
        save()
        return true
    }

    func endReview() {
        isReviewing = false
        isRevealed = false
        reviewIDs = []
        reviewedCount = 0
        sessionTotal = 0
    }

    func retryStorage() {
        if canEdit {
            save()
        } else {
            load()
        }
    }

    func flush() {
        saveTask?.cancel()
        saveTask = nil
        enqueueSave()
        persistenceQueue.sync {}
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            storageIssue = nil
            canEdit = true
            return
        }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: storageURL.path)
            guard let size = attributes[.size] as? NSNumber,
                  size.int64Value <= RecallPolicy.maximumArchiveBytes else {
                canEdit = false
                storageIssue = .loadFailed
                return
            }
            let data = try Data(contentsOf: storageURL)
            guard data.count <= RecallPolicy.maximumArchiveBytes else {
                canEdit = false
                storageIssue = .loadFailed
                return
            }
            let snapshot: RecallSnapshot
            do {
                struct Header: Decodable { let version: Int }
                guard try JSONDecoder().decode(Header.self, from: data).version == 1 else {
                    canEdit = false
                    storageIssue = .unsupportedVersion
                    return
                }
                snapshot = try JSONDecoder().decode(RecallSnapshot.self, from: data)
            } catch {
                let backup = directory.appendingPathComponent("cards-corrupted-\(UUID()).json")
                try FileManager.default.copyItem(at: storageURL, to: backup)
                storageIssue = .recovered
                canEdit = true
                return
            }
            cards = RecallPolicy.normalized(snapshot.cards)
            storageIssue = nil
            canEdit = true
        } catch {
            canEdit = false
            storageIssue = .loadFailed
        }
    }

    private func save() {
        hasPendingSave = true
        revision &+= 1
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled, let self else { return }
            self.saveTask = nil
            self.enqueueSave()
        }
    }

    private func enqueueSave() {
        guard canEdit, hasPendingSave else { return }
        hasPendingSave = false
        let snapshot = RecallSnapshot(cards: cards)
        let directory = directory
        let url = storageURL
        let revision = revision
        persistenceQueue.async { [weak self] in
            let failed: Bool
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try JSONEncoder().encode(snapshot).write(to: url, options: .atomic)
                failed = false
            } catch {
                failed = true
            }
            Task { @MainActor [weak self] in
                guard let self, self.revision == revision else { return }
                self.storageIssue = failed ? .saveFailed : nil
                if failed { self.hasPendingSave = true }
            }
        }
    }
}
