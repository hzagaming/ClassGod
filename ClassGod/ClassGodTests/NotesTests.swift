import Foundation
import Testing
@testable import ClassGod

@Suite("Notes")
struct NotesTests {
    @Test("Closing without edits preserves existing bytes and does not create empty archives")
    @MainActor
    func preservesUneditedStorage() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ClassGodNotes-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root) }
        let url = NotesStoragePolicy.storageURL(applicationSupportRoot: root)
        NotesService(applicationSupportRoot: root).stop()
        #expect(!FileManager.default.fileExists(atPath: url.path))
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = Data(#"{ "version": 1, "notes": [] }"#.utf8)
        try data.write(to: url)
        NotesService(applicationSupportRoot: root).stop()
        #expect(try Data(contentsOf: url) == data)
    }

    @Test("Unreadable notes cannot be replaced by an empty snapshot on shutdown")
    @MainActor
    func preservesUnreadableStorage() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ClassGodNotes-\(UUID())")
        let url = NotesStoragePolicy.storageURL(applicationSupportRoot: root)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
            try? FileManager.default.removeItem(at: root)
        }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try NotesStoragePolicy.encode(NotesSnapshot(notes: [ClassGodNote(body: "Keep this note")], selectedNoteID: nil))
        try data.write(to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0], ofItemAtPath: url.path)
        #expect(throws: (any Error).self) { try Data(contentsOf: url) }
        let service = NotesService(applicationSupportRoot: root)
        #expect(service.addNote() == nil)
        service.stop()
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        #expect(try Data(contentsOf: url) == data)
        service.retryStorage()
        #expect(service.canEdit)
        #expect(service.storageIssue == nil)
        #expect(service.selectedNote?.body == "Keep this note")
    }

    @Test("Separate corrupted archives retain separate recovery backups")
    @MainActor
    func preservesRecoveryBackups() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ClassGodNotes-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root) }
        let url = NotesStoragePolicy.storageURL(applicationSupportRoot: root)
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let originals = [Data("first broken archive".utf8), Data("second broken archive".utf8)]
        for data in originals {
            try data.write(to: url)
            NotesService(applicationSupportRoot: root).stop()
            #expect(try Data(contentsOf: url) == data)
        }
        let backups = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("notes-corrupted") }
        let contents = try backups.map { try Data(contentsOf: $0) }
        #expect(contents.count == originals.count)
        #expect(originals.allSatisfy { contents.contains($0) })
    }

    @Test("Backup failures block editing until a recovery copy can be created")
    @MainActor
    func retriesFailedBackup() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ClassGodNotes-\(UUID())")
        let url = NotesStoragePolicy.storageURL(applicationSupportRoot: root)
        let directory = url.deletingLastPathComponent()
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
            try? FileManager.default.removeItem(at: root)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = Data("damaged but recoverable".utf8)
        try data.write(to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: directory.path)
        let service = NotesService(applicationSupportRoot: root)
        #expect(!service.canEdit)
        #expect(service.storageIssue == .loadFailed)
        #expect(service.addNote() == nil)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
        service.stop()
        #expect(try Data(contentsOf: url) == data)
        service.retryStorage()
        #expect(service.canEdit)
        #expect(service.storageIssue == .recovered)
        #expect(service.addNote() != nil)
        service.updateSelectedBody("New note after backup")
        service.stop()
        #expect(try NotesStoragePolicy.decode(Data(contentsOf: url)).notes.first?.body == "New note after backup")
        let backup = try #require(FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .first { $0.lastPathComponent.hasPrefix("notes-corrupted-") })
        #expect(try Data(contentsOf: backup) == data)
    }

    @Test("Unsupported archive versions remain untouched by edits, retries, or shutdown")
    @MainActor
    func preservesUnsupportedVersion() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ClassGodNotes-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root) }
        let url = NotesStoragePolicy.storageURL(applicationSupportRoot: root)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = Data(#"{"version":99,"notes":[]}"#.utf8)
        try data.write(to: url)
        let service = NotesService(applicationSupportRoot: root)
        #expect(!service.canEdit)
        #expect(service.storageIssue == .unsupportedVersion)
        #expect(service.addNote() == nil)
        service.updateSelectedTitle("Ignore")
        service.updateSelectedBody("Ignore")
        #expect(!service.delete(UUID()))
        #expect(!service.togglePin(UUID()))
        service.retryStorage()
        service.stop()
        #expect(try Data(contentsOf: url) == data)
    }

    @Test("Failed saves retain the latest edits, retry successfully, and stop rewriting once clean")
    @MainActor
    func retriesLatestEdits() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ClassGodNotes-\(UUID())")
        defer { try? FileManager.default.removeItem(at: root) }
        let url = NotesStoragePolicy.storageURL(applicationSupportRoot: root)
        let service = NotesService(applicationSupportRoot: root)
        let id = try #require(service.addNote())
        service.updateSelectedBody("Original")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        service.stop()
        for _ in 0..<100 where service.storageIssue != .saveFailed {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(service.storageIssue == .saveFailed)
        #expect(service.hasUnsavedChanges)
        #expect(service.canEdit)
        service.updateSelectedBody("Latest")
        try FileManager.default.removeItem(at: url)
        service.retryStorage()
        service.stop()
        service.updateSelectedTitle("Edited while the previous completion is pending")
        #expect(service.togglePin(id))
        service.stop()
        for _ in 0..<100 where service.hasUnsavedChanges {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(!service.hasUnsavedChanges)
        #expect(service.storageIssue == nil)
        let snapshot = try NotesStoragePolicy.decode(Data(contentsOf: url))
        #expect(snapshot.notes == service.notes)
        #expect(snapshot.notes.first?.body == "Latest")
        #expect(snapshot.selectedNoteID == id)
        let originalDate = try FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
        service.updateSelectedBody("Latest")
        service.stop()
        #expect(try FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date == originalDate)
    }

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
