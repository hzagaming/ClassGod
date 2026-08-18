import Foundation
import Combine

@MainActor
final class NotesService: ObservableObject {
    static let shared = NotesService()

    @Published private(set) var notes: [ClassGodNote] = []
    @Published private(set) var selectedNoteID: UUID?

    private let storageDirectory: URL
    private let storageURL: URL
    private let persistenceQueue = DispatchQueue(
        label: "com.hanazar.classgod.notes.persistence",
        qos: .utility
    )
    private var saveTask: Task<Void, Never>?
    private var isLoading = false

    var selectedNote: ClassGodNote? {
        guard let selectedNoteID else { return nil }
        return notes.first { $0.id == selectedNoteID }
    }

    private init() {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        storageURL = NotesStoragePolicy.storageURL(applicationSupportRoot: root)
        storageDirectory = storageURL.deletingLastPathComponent()
        load()
    }

    func filteredNotes(query: String) -> [ClassGodNote] {
        let sorted = NotesCollectionPolicy.sorted(notes)
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sorted }
        return sorted.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.body.localizedCaseInsensitiveContains(query)
        }
    }

    @discardableResult
    func addNote() -> UUID? {
        guard notes.count < NotesContentPolicy.maximumNoteCount else { return nil }
        let note = ClassGodNote()
        notes.append(note)
        selectedNoteID = note.id
        save()
        return note.id
    }

    func select(_ id: UUID) {
        guard notes.contains(where: { $0.id == id }), selectedNoteID != id else { return }
        selectedNoteID = id
        save()
    }

    func updateSelectedTitle(_ title: String) {
        updateSelected { $0.title = String(title.prefix(NotesContentPolicy.maximumTitleLength)) }
    }

    func updateSelectedBody(_ body: String) {
        updateSelected { $0.body = String(body.prefix(NotesContentPolicy.maximumBodyLength)) }
    }

    func togglePin(_ id: UUID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].isPinned.toggle()
        notes[index].updatedAt = Date()
        save()
    }

    func delete(_ id: UUID) {
        let visibleNotes = NotesCollectionPolicy.sorted(notes)
        let replacement = NotesCollectionPolicy.selectionAfterDeleting(
            id,
            from: visibleNotes,
            selectedID: selectedNoteID
        )
        notes.removeAll { $0.id == id }
        selectedNoteID = replacement
        save()
    }

    func stop() {
        saveTask?.cancel()
        saveTask = nil
        enqueueSave()
        persistenceQueue.sync {}
    }

    private func updateSelected(_ change: (inout ClassGodNote) -> Void) {
        guard let selectedNoteID,
              let index = notes.firstIndex(where: { $0.id == selectedNoteID }) else { return }
        change(&notes[index])
        notes[index].updatedAt = Date()
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        do {
            let snapshot = NotesContentPolicy.normalized(try NotesStoragePolicy.decode(data))
            isLoading = true
            notes = snapshot.notes
            selectedNoteID = snapshot.selectedNoteID
            isLoading = false
        } catch {
            try? FileManager.default.createDirectory(
                at: storageDirectory,
                withIntermediateDirectories: true
            )
            let backup = storageDirectory.appendingPathComponent("notes-corrupted.json")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.copyItem(at: storageURL, to: backup)
        }
    }

    private func save() {
        guard !isLoading else { return }
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled, let self else { return }
            saveTask = nil
            enqueueSave()
        }
    }

    private func enqueueSave() {
        let directory = storageDirectory
        let url = storageURL
        let snapshot = NotesSnapshot(notes: notes, selectedNoteID: selectedNoteID)
        persistenceQueue.async {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try NotesStoragePolicy.encode(snapshot).write(to: url, options: .atomic)
            } catch {
                Task { @MainActor in
                    ErrorToastManager.shared.show(
                        title: String(localized: "notes.title"),
                        message: String(localized: "notes.save_failed")
                    )
                }
            }
        }
    }
}
