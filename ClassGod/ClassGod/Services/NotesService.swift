import Foundation
import Combine

@MainActor
final class NotesService: ObservableObject {
    static let shared = NotesService()

    enum StorageIssue: Sendable {
        case recovered, loadFailed, saveFailed, unsupportedVersion
    }

    @Published private(set) var notes: [ClassGodNote] = []
    @Published private(set) var selectedNoteID: UUID?
    @Published private(set) var storageIssue: StorageIssue?
    @Published private(set) var canEdit = true
    @Published private(set) var hasUnsavedChanges = false

    private let storageDirectory: URL
    private let storageURL: URL
    private let persistenceQueue = DispatchQueue(
        label: "com.hanazar.classgod.notes.persistence",
        qos: .utility
    )
    private var saveTask: Task<Void, Never>?
    private var revision: UInt = 0

    var selectedNote: ClassGodNote? {
        guard let selectedNoteID else { return nil }
        return notes.first { $0.id == selectedNoteID }
    }

    init(applicationSupportRoot: URL? = nil) {
        let root = applicationSupportRoot ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        storageURL = NotesStoragePolicy.storageURL(applicationSupportRoot: root)
        storageDirectory = storageURL.deletingLastPathComponent()
        load()
    }

    func filteredNotes(query: String) -> [ClassGodNote] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return NotesCollectionPolicy.sorted(notes) }
        return NotesCollectionPolicy.sorted(notes.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.body.localizedCaseInsensitiveContains(query)
        })
    }

    @discardableResult
    func addNote() -> UUID? {
        guard canEdit, notes.count < NotesContentPolicy.maximumNoteCount else { return nil }
        let note = ClassGodNote()
        notes.append(note)
        selectedNoteID = note.id
        save()
        return note.id
    }

    @discardableResult
    func select(_ id: UUID) -> Bool {
        guard canEdit, notes.contains(where: { $0.id == id }), selectedNoteID != id else { return false }
        selectedNoteID = id
        save()
        return true
    }

    func updateSelectedTitle(_ title: String) {
        let normalized = String(title.prefix(NotesContentPolicy.maximumTitleLength))
        updateSelected {
            guard $0.title != normalized else { return false }
            $0.title = normalized
            return true
        }
    }

    func updateSelectedBody(_ body: String) {
        let normalized = String(body.prefix(NotesContentPolicy.maximumBodyLength))
        updateSelected {
            guard $0.body != normalized else { return false }
            $0.body = normalized
            return true
        }
    }

    @discardableResult
    func togglePin(_ id: UUID) -> Bool {
        guard canEdit, let index = notes.firstIndex(where: { $0.id == id }) else { return false }
        notes[index].isPinned.toggle()
        notes[index].updatedAt = Date()
        save()
        return true
    }

    @discardableResult
    func delete(_ id: UUID, visibleNotes: [ClassGodNote]? = nil) -> Bool {
        guard canEdit, notes.contains(where: { $0.id == id }) else { return false }
        let orderedNotes = visibleNotes ?? NotesCollectionPolicy.sorted(notes)
        let replacement = NotesCollectionPolicy.selectionAfterDeleting(
            id,
            from: orderedNotes,
            selectedID: selectedNoteID
        )
        notes.removeAll { $0.id == id }
        selectedNoteID = replacement
        save()
        return true
    }

    func retryStorage() {
        if canEdit {
            guard hasUnsavedChanges else { return }
            save()
        } else {
            load()
        }
    }

    func stop() {
        saveTask?.cancel()
        saveTask = nil
        enqueueSave()
        persistenceQueue.sync {}
    }

    private func updateSelected(_ change: (inout ClassGodNote) -> Bool) {
        guard canEdit, let selectedNoteID,
              let index = notes.firstIndex(where: { $0.id == selectedNoteID }) else { return }
        guard change(&notes[index]) else { return }
        notes[index].updatedAt = Date()
        save()
    }

    private func load() {
        do {
            let data = try Data(contentsOf: storageURL)
            let snapshot: NotesSnapshot
            do {
                struct Header: Decodable { let version: Int }
                guard try JSONDecoder().decode(Header.self, from: data).version == 1 else {
                    canEdit = false
                    storageIssue = .unsupportedVersion
                    return
                }
                snapshot = NotesContentPolicy.normalized(try NotesStoragePolicy.decode(data))
            } catch {
                let backup = storageDirectory.appendingPathComponent("notes-corrupted-\(UUID()).json")
                try FileManager.default.copyItem(at: storageURL, to: backup)
                storageIssue = .recovered
                canEdit = true
                return
            }
            notes = snapshot.notes
            selectedNoteID = snapshot.selectedNoteID
            storageIssue = nil
            canEdit = true
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            storageIssue = nil
            canEdit = true
        } catch {
            canEdit = false
            storageIssue = .loadFailed
        }
    }

    private func save() {
        guard canEdit else { return }
        hasUnsavedChanges = true
        revision &+= 1
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled, let self else { return }
            saveTask = nil
            enqueueSave()
        }
    }

    private func enqueueSave() {
        guard canEdit, hasUnsavedChanges else { return }
        revision &+= 1
        let revision = revision
        let directory = storageDirectory
        let url = storageURL
        let snapshot = NotesSnapshot(notes: notes, selectedNoteID: selectedNoteID)
        persistenceQueue.async { [weak self] in
            let issue: StorageIssue?
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try NotesStoragePolicy.encode(snapshot).write(to: url, options: .atomic)
                issue = nil
            } catch {
                issue = .saveFailed
            }
            Task { @MainActor [weak self] in
                guard let self, self.revision == revision else { return }
                self.storageIssue = issue
                self.hasUnsavedChanges = issue != nil
            }
        }
    }
}
