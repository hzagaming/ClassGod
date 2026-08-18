import Foundation

nonisolated struct ClassGodNote: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var body: String
    let createdAt: Date
    var updatedAt: Date
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        title: String = "",
        body: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
    }

    var inferredTitle: String? {
        let explicit = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !explicit.isEmpty { return explicit }
        return body
            .split(whereSeparator: \.isNewline)
            .lazy
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty }
            .map { String($0.prefix(60)) }
    }

    var preview: String {
        body
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
    }
}

nonisolated struct NotesSnapshot: Codable, Equatable, Sendable {
    var version: Int
    var notes: [ClassGodNote]
    var selectedNoteID: UUID?

    init(version: Int = 1, notes: [ClassGodNote], selectedNoteID: UUID?) {
        self.version = version
        self.notes = notes
        self.selectedNoteID = selectedNoteID
    }
}

nonisolated enum NotesCollectionPolicy {
    static func sorted(_ notes: [ClassGodNote]) -> [ClassGodNote] {
        notes.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            if $0.updatedAt != $1.updatedAt { return $0.updatedAt > $1.updatedAt }
            return $0.createdAt > $1.createdAt
        }
    }

    static func selectionAfterDeleting(
        _ deletedID: UUID,
        from notes: [ClassGodNote],
        selectedID: UUID?
    ) -> UUID? {
        guard selectedID == deletedID else {
            return notes.contains { $0.id == selectedID } ? selectedID : notes.first?.id
        }
        guard let index = notes.firstIndex(where: { $0.id == deletedID }) else {
            return notes.first?.id
        }
        if notes.indices.contains(index + 1) { return notes[index + 1].id }
        if index > notes.startIndex { return notes[index - 1].id }
        return nil
    }
}

nonisolated enum NotesContentPolicy {
    static let maximumTitleLength = 200
    static let maximumBodyLength = 2_000_000
    static let maximumNoteCount = 500

    static func normalized(_ snapshot: NotesSnapshot) -> NotesSnapshot {
        var seen = Set<UUID>()
        var notes: [ClassGodNote] = []
        notes.reserveCapacity(min(snapshot.notes.count, maximumNoteCount))
        for note in snapshot.notes where notes.count < maximumNoteCount {
            if seen.insert(note.id).inserted {
                notes.append(normalized(note))
            }
        }
        let selectedID = notes.contains { $0.id == snapshot.selectedNoteID }
            ? snapshot.selectedNoteID
            : notes.first?.id
        return NotesSnapshot(version: 1, notes: notes, selectedNoteID: selectedID)
    }

    static func normalized(_ note: ClassGodNote) -> ClassGodNote {
        var note = note
        note.title = String(note.title.prefix(maximumTitleLength))
        note.body = String(note.body.prefix(maximumBodyLength))
        if note.updatedAt < note.createdAt { note.updatedAt = note.createdAt }
        return note
    }
}

nonisolated enum NotesStoragePolicy {
    static func storageURL(applicationSupportRoot: URL) -> URL {
        applicationSupportRoot
            .appendingPathComponent("ClassGod/Notes", isDirectory: true)
            .appendingPathComponent("notes.json")
    }

    static func encode(_ snapshot: NotesSnapshot) throws -> Data {
        try JSONEncoder().encode(snapshot)
    }

    static func decode(_ data: Data) throws -> NotesSnapshot {
        try JSONDecoder().decode(NotesSnapshot.self, from: data)
    }
}
