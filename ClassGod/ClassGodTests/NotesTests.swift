import Foundation
import Testing
@testable import ClassGod

@Suite("Notes")
struct NotesTests {
    @Test("Pinned notes sort before recent unpinned notes")
    func sortsPinnedNotesFirst() {
        let old = Date(timeIntervalSince1970: 100)
        let recent = Date(timeIntervalSince1970: 200)
        let pinned = ClassGodNote(title: "Pinned", updatedAt: old, isPinned: true)
        let newest = ClassGodNote(title: "Newest", updatedAt: recent)
        let older = ClassGodNote(title: "Older", updatedAt: old)

        #expect(NotesCollectionPolicy.sorted([older, newest, pinned]).map(\.id) == [
            pinned.id, newest.id, older.id,
        ])
    }

    @Test("Deleting the selected note chooses the next visible note")
    func replacesSelectionAfterDeletion() {
        let first = ClassGodNote(title: "First")
        let second = ClassGodNote(title: "Second")
        let third = ClassGodNote(title: "Third")

        #expect(NotesCollectionPolicy.selectionAfterDeleting(
            second.id,
            from: [first, second, third],
            selectedID: second.id
        ) == third.id)
        #expect(NotesCollectionPolicy.selectionAfterDeleting(
            third.id,
            from: [first, second, third],
            selectedID: third.id
        ) == second.id)
        #expect(NotesCollectionPolicy.selectionAfterDeleting(
            first.id,
            from: [first, second, third],
            selectedID: third.id
        ) == third.id)
    }

    @Test("Imported note content and collection size are bounded")
    func normalizesImportedSnapshot() {
        let oversizedTitle = String(repeating: "T", count: NotesContentPolicy.maximumTitleLength + 10)
        let oversizedBody = String(repeating: "B", count: NotesContentPolicy.maximumBodyLength + 10)
        var notes = [ClassGodNote(title: oversizedTitle, body: oversizedBody)]
        notes.append(contentsOf: (1...NotesContentPolicy.maximumNoteCount).map {
            ClassGodNote(title: "Note \($0)")
        })
        let snapshot = NotesSnapshot(notes: notes, selectedNoteID: notes.last?.id)

        let normalized = NotesContentPolicy.normalized(snapshot)

        #expect(normalized.notes.count == NotesContentPolicy.maximumNoteCount)
        #expect(normalized.notes.allSatisfy { $0.title.count <= NotesContentPolicy.maximumTitleLength })
        #expect(normalized.notes.allSatisfy { $0.body.count <= NotesContentPolicy.maximumBodyLength })
        #expect(normalized.selectedNoteID == normalized.notes.first?.id)
    }

    @Test("Sidebar previews remain bounded for very large notes")
    func boundsSidebarPreviews() {
        let note = ClassGodNote(body: String(repeating: "A", count: 10_000))

        #expect(note.preview.count <= NotesContentPolicy.maximumPreviewLength + 1)
        #expect(note.preview.hasSuffix("…"))
    }

    @Test("Notes use Application Support and snapshots round-trip")
    func persistsSnapshots() throws {
        let root = URL(fileURLWithPath: "/tmp/ClassGodNotesTests", isDirectory: true)
        let url = NotesStoragePolicy.storageURL(applicationSupportRoot: root)
        let note = ClassGodNote(title: "Release", body: "Ship safely")
        let snapshot = NotesSnapshot(notes: [note], selectedNoteID: note.id)

        #expect(url == root
            .appendingPathComponent("ClassGod/Notes", isDirectory: true)
            .appendingPathComponent("notes.json"))

        let data = try NotesStoragePolicy.encode(snapshot)
        #expect(try NotesStoragePolicy.decode(data) == snapshot)
    }
}
