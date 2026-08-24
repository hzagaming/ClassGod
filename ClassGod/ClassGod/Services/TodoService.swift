import Foundation
import Combine

@MainActor
final class TodoService: ObservableObject {
    static let shared = TodoService()

    @Published private(set) var tasks: [ClassGodTodo] = []
    @Published private(set) var projects: [TodoProject] = []

    private let storageDirectory: URL
    private let storageURL: URL
    private let persistenceQueue = DispatchQueue(
        label: "com.hanazar.classgod.todo.persistence",
        qos: .utility
    )
    private var saveTask: Task<Void, Never>?

    private init() {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        storageURL = TodoStoragePolicy.storageURL(applicationSupportRoot: root)
        storageDirectory = storageURL.deletingLastPathComponent()
        load()
    }

    func filteredTasks(
        selection: TodoListSelection,
        query: String,
        now: Date = Date()
    ) -> [ClassGodTodo] {
        TodoCollectionPolicy.filtered(
            tasks,
            selection: selection,
            projects: projects,
            query: query,
            now: now
        )
    }

    func count(for selection: TodoListSelection, now: Date = Date()) -> Int {
        TodoCollectionPolicy.filtered(
            tasks,
            selection: selection,
            projects: projects,
            query: "",
            now: now
        ).count
    }

    @discardableResult
    func save(_ task: ClassGodTodo) -> Bool {
        guard tasks.contains(where: { $0.id == task.id })
                || tasks.count < TodoContentPolicy.maximumTaskCount else { return false }
        let projectIDs = Set(projects.map(\.id))
        guard var normalized = TodoContentPolicy.normalized(task, validProjectIDs: projectIDs) else {
            return false
        }
        normalized.updatedAt = max(normalized.createdAt, Date())
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = normalized
        } else {
            tasks.append(normalized)
        }
        scheduleSave()
        return true
    }

    @discardableResult
    func toggleCompletion(_ id: UUID, at date: Date = Date()) -> Bool {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return false }
        let eventDate = max(tasks[index].createdAt, date)
        let wasCompleted = tasks[index].isCompleted
        if !wasCompleted,
           tasks[index].recurrence != .none,
           !tasks.contains(where: { $0.recurrenceParentID == id }),
           tasks.count >= TodoContentPolicy.maximumTaskCount {
            return false
        }

        tasks[index].completedAt = wasCompleted ? nil : eventDate
        tasks[index].updatedAt = eventDate
        if wasCompleted {
            tasks.removeAll {
                $0.recurrenceParentID == id
                    && !$0.isCompleted
                    && $0.createdAt == $0.updatedAt
            }
        } else if !tasks.contains(where: { $0.recurrenceParentID == id }),
                  let next = TodoRecurrencePolicy.nextOccurrence(
                    after: tasks[index],
                    completedAt: eventDate
                  ) {
            tasks.append(next)
        }
        scheduleSave()
        return true
    }

    @discardableResult
    func deleteTask(_ id: UUID) -> Bool {
        guard tasks.contains(where: { $0.id == id }) else { return false }
        tasks.removeAll { $0.id == id }
        scheduleSave()
        return true
    }

    @discardableResult
    func addProject(name: String, color: TodoProjectColor) -> UUID? {
        guard projects.count < TodoContentPolicy.maximumProjectCount else { return nil }
        let candidate = TodoProject(name: name, color: color)
        let snapshot = TodoContentPolicy.normalized(TodoSnapshot(tasks: [], projects: [candidate]))
        guard let project = snapshot.projects.first else { return nil }
        projects.append(project)
        scheduleSave()
        return project.id
    }

    @discardableResult
    func deleteProject(_ id: UUID) -> Bool {
        guard projects.contains(where: { $0.id == id }) else { return false }
        projects.removeAll { $0.id == id }
        let date = Date()
        for index in tasks.indices where tasks[index].projectID == id {
            tasks[index].projectID = nil
            tasks[index].updatedAt = max(tasks[index].createdAt, date)
        }
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
            let snapshot = TodoContentPolicy.normalized(try TodoStoragePolicy.decode(data))
            tasks = snapshot.tasks
            projects = snapshot.projects
        } catch {
            try? FileManager.default.createDirectory(
                at: storageDirectory,
                withIntermediateDirectories: true
            )
            let backup = storageDirectory.appendingPathComponent("todo-corrupted.json")
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
        let snapshot = TodoSnapshot(tasks: tasks, projects: projects)
        persistenceQueue.async {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try TodoStoragePolicy.encode(snapshot).write(to: url, options: .atomic)
            } catch {
                Task { @MainActor in
                    ErrorToastManager.shared.show(
                        title: String(localized: "todo.title"),
                        message: String(localized: "todo.save_failed")
                    )
                }
            }
        }
    }
}
