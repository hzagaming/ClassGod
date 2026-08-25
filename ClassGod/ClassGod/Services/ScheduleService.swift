import Combine
import Foundation

@MainActor
final class ScheduleService: ObservableObject {
    static let shared = ScheduleService()

    @Published private(set) var entries: [ScheduleEntry] = []

    private let storageDirectory: URL
    private let storageURL: URL
    private let persistenceQueue = DispatchQueue(
        label: "com.hanazar.classgod.schedule.persistence",
        qos: .utility
    )
    private var saveTask: Task<Void, Never>?

    private init() {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        storageURL = ScheduleStoragePolicy.storageURL(applicationSupportRoot: root)
        storageDirectory = storageURL.deletingLastPathComponent()
        load()
    }

    func entries(for weekday: ScheduleWeekday) -> [ScheduleEntry] {
        ScheduleCollectionPolicy.entries(for: weekday, in: entries)
    }

    @discardableResult
    func save(_ entry: ScheduleEntry) -> Bool {
        guard entries.contains(where: { $0.id == entry.id })
                || entries.count < ScheduleContentPolicy.maximumEntryCount,
              var normalized = ScheduleContentPolicy.normalized(entry) else { return false }
        normalized.updatedAt = max(normalized.createdAt, Date())
        if let index = entries.firstIndex(where: { $0.id == normalized.id }) {
            entries[index] = normalized
        } else {
            entries.append(normalized)
        }
        entries = ScheduleCollectionPolicy.sorted(entries)
        scheduleSave()
        return true
    }

    @discardableResult
    func toggleEnabled(_ id: UUID) -> Bool {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return false }
        entries[index].isEnabled.toggle()
        entries[index].updatedAt = max(entries[index].createdAt, Date())
        scheduleSave()
        return true
    }

    @discardableResult
    func delete(_ id: UUID) -> Bool {
        guard entries.contains(where: { $0.id == id }) else { return false }
        entries.removeAll { $0.id == id }
        scheduleSave()
        return true
    }

    func stop() {
        saveTask?.cancel()
        saveTask = nil
        enqueueSave()
        persistenceQueue.sync {}
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        do {
            entries = ScheduleContentPolicy.normalized(
                try ScheduleStoragePolicy.decode(data)
            ).entries
        } catch {
            try? FileManager.default.createDirectory(
                at: storageDirectory,
                withIntermediateDirectories: true
            )
            let backup = storageDirectory.appendingPathComponent("schedule-corrupted.json")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.copyItem(at: storageURL, to: backup)
        }
    }

    private func scheduleSave() {
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
        let snapshot = ScheduleSnapshot(entries: entries)
        persistenceQueue.async {
            do {
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
                try ScheduleStoragePolicy.encode(snapshot).write(to: url, options: .atomic)
            } catch {
                Task { @MainActor in
                    ErrorToastManager.shared.show(
                        title: String(localized: "schedule.title"),
                        message: String(localized: "schedule.save_failed")
                    )
                }
            }
        }
    }
}
