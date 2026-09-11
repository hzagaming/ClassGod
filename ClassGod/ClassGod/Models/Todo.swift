import Foundation

nonisolated enum TodoPriority: Int, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case low
    case medium
    case high
    case urgent

    var id: Self { self }
}

nonisolated enum TodoRecurrence: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case daily
    case weekdays
    case weekly
    case monthly

    var id: Self { self }
}

nonisolated enum TodoProjectColor: String, Codable, CaseIterable, Identifiable, Sendable {
    case blue
    case mint
    case violet
    case orange
    case rose
    case gray

    var id: Self { self }
}

nonisolated struct TodoProject: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var color: TodoProjectColor
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        color: TodoProjectColor,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
    }
}

nonisolated struct TodoSubtask: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var title: String
    var completedAt: Date?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        completedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.completedAt = completedAt
        self.createdAt = createdAt
    }

    var isCompleted: Bool { completedAt != nil }
}

nonisolated struct ClassGodTodo: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var title: String
    var notes: String
    var projectID: UUID?
    var tags: [String]
    var subtasks: [TodoSubtask]
    var dueDate: Date?
    var priority: TodoPriority
    var recurrence: TodoRecurrence
    var recurrenceParentID: UUID?
    var completedAt: Date?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        projectID: UUID? = nil,
        tags: [String] = [],
        subtasks: [TodoSubtask] = [],
        dueDate: Date? = nil,
        priority: TodoPriority = .none,
        recurrence: TodoRecurrence = .none,
        recurrenceParentID: UUID? = nil,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.projectID = projectID
        self.tags = tags
        self.subtasks = subtasks
        self.dueDate = dueDate
        self.priority = priority
        self.recurrence = recurrence
        self.recurrenceParentID = recurrenceParentID
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    var isCompleted: Bool { completedAt != nil }
}

nonisolated enum TodoSmartList: String, CaseIterable, Identifiable, Sendable {
    case inbox
    case today
    case upcoming
    case overdue
    case priority
    case all
    case completed

    var id: Self { self }
}

nonisolated enum TodoListSelection: Hashable, Identifiable, Sendable {
    case smart(TodoSmartList)
    case project(UUID)

    var id: String {
        switch self {
        case .smart(let list): "smart.\(list.rawValue)"
        case .project(let id): "project.\(id.uuidString)"
        }
    }
}

nonisolated enum TodoDeletionAction: Equatable, Sendable {
    case confirm
    case deleteImmediately
}

nonisolated enum TodoDeletionPolicy {
    static func action(confirmBeforeDelete: Bool) -> TodoDeletionAction {
        confirmBeforeDelete ? .confirm : .deleteImmediately
    }
}

nonisolated struct TodoSnapshot: Codable, Equatable, Sendable {
    var version: Int
    var tasks: [ClassGodTodo]
    var projects: [TodoProject]

    init(version: Int = 2, tasks: [ClassGodTodo], projects: [TodoProject]) {
        self.version = version
        self.tasks = tasks
        self.projects = projects
    }
}

nonisolated struct TodoFocusSnapshot: Equatable, Sendable {
    let activeCount: Int
    let overdueCount: Int
    let completedTodayCount: Int
    let focusTaskID: UUID?

    var progress: Double {
        let total = activeCount + completedTodayCount
        return total == 0 ? 1 : Double(completedTodayCount) / Double(total)
    }
}

nonisolated enum TodoFocusPolicy {
    static func snapshot(
        _ tasks: [ClassGodTodo],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> TodoFocusSnapshot {
        let startOfToday = calendar.startOfDay(for: now)
        var activeCount = 0
        var overdueCount = 0
        var completedTodayCount = 0
        var focusTask: ClassGodTodo?
        for task in tasks {
            if let completedAt = task.completedAt {
                if calendar.isDate(completedAt, inSameDayAs: now) { completedTodayCount += 1 }
                continue
            }
            activeCount += 1
            if task.dueDate.map({ $0 < startOfToday }) == true { overdueCount += 1 }
            if let current = focusTask {
                if TodoCollectionPolicy.precedes(task, current, startOfToday: startOfToday) {
                    focusTask = task
                }
            } else {
                focusTask = task
            }
        }
        return TodoFocusSnapshot(
            activeCount: activeCount,
            overdueCount: overdueCount,
            completedTodayCount: completedTodayCount,
            focusTaskID: focusTask?.id
        )
    }
}

nonisolated enum TodoContentPolicy {
    static let maximumTaskCount = 5_000
    static let maximumProjectCount = 50
    static let maximumTitleLength = 300
    static let maximumNotesLength = 50_000
    static let maximumProjectNameLength = 80
    static let maximumTagCount = 12
    static let maximumTagLength = 30
    static let maximumSubtaskCount = 50
    static let maximumSubtaskTitleLength = 200

    static func normalized(_ snapshot: TodoSnapshot) -> TodoSnapshot {
        var projectIDs = Set<UUID>()
        let projects = snapshot.projects.compactMap { project -> TodoProject? in
            guard projectIDs.count < maximumProjectCount,
                  projectIDs.insert(project.id).inserted else { return nil }
            let name = clean(project.name, maximumLength: maximumProjectNameLength)
            guard !name.isEmpty else { return nil }
            return TodoProject(id: project.id, name: name, color: project.color, createdAt: project.createdAt)
        }

        var taskIDs = Set<UUID>()
        let validProjectIDs = Set(projects.map(\.id))
        let tasks = snapshot.tasks.compactMap { task -> ClassGodTodo? in
            guard taskIDs.count < maximumTaskCount,
                  taskIDs.insert(task.id).inserted else { return nil }
            return normalized(task, validProjectIDs: validProjectIDs)
        }
        return TodoSnapshot(version: 2, tasks: tasks, projects: projects)
    }

    static func normalized(
        _ task: ClassGodTodo,
        validProjectIDs: Set<UUID>
    ) -> ClassGodTodo? {
        let title = clean(task.title, maximumLength: maximumTitleLength)
        guard !title.isEmpty else { return nil }
        let notes = String(task.notes.prefix(maximumNotesLength))
        let projectID = task.projectID.flatMap { validProjectIDs.contains($0) ? $0 : nil }
        let updatedAt = max(task.createdAt, task.updatedAt)
        return ClassGodTodo(
            id: task.id,
            title: title,
            notes: notes,
            projectID: projectID,
            tags: normalizedTags(task.tags),
            subtasks: normalizedSubtasks(task.subtasks),
            dueDate: task.dueDate,
            priority: task.priority,
            recurrence: task.recurrence,
            recurrenceParentID: task.recurrenceParentID,
            completedAt: task.completedAt.map { max(task.createdAt, $0) },
            createdAt: task.createdAt,
            updatedAt: updatedAt
        )
    }

    private static func normalizedSubtasks(_ subtasks: [TodoSubtask]) -> [TodoSubtask] {
        var ids = Set<UUID>()
        return subtasks.compactMap { subtask -> TodoSubtask? in
            guard ids.count < maximumSubtaskCount, ids.insert(subtask.id).inserted else { return nil }
            let title = clean(subtask.title, maximumLength: maximumSubtaskTitleLength)
            guard !title.isEmpty else { return nil }
            return TodoSubtask(
                id: subtask.id,
                title: title,
                completedAt: subtask.completedAt.map { max(subtask.createdAt, $0) },
                createdAt: subtask.createdAt
            )
        }
    }

    private static func normalizedTags(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for rawTag in tags where result.count < maximumTagCount {
            let trimmed = rawTag.trimmingCharacters(in: .whitespacesAndNewlines)
            let tag = clean(String(trimmed.drop(while: { $0 == "#" })), maximumLength: maximumTagLength)
                .lowercased()
            guard !tag.isEmpty, seen.insert(tag).inserted else { continue }
            result.append(tag)
        }
        return result
    }

    private static func clean(_ value: String, maximumLength: Int) -> String {
        String(value.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maximumLength))
    }
}

nonisolated enum TodoCollectionPolicy {
    static func counts(
        _ tasks: [ClassGodTodo],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [TodoListSelection: Int] {
        let startOfToday = calendar.startOfDay(for: now)
        var counts: [TodoListSelection: Int] = [:]
        for task in tasks {
            if task.isCompleted {
                counts[.smart(.completed), default: 0] += 1
                continue
            }
            counts[.smart(.all), default: 0] += 1
            if let projectID = task.projectID {
                counts[.project(projectID), default: 0] += 1
            } else {
                counts[.smart(.inbox), default: 0] += 1
            }
            if task.priority.rawValue >= TodoPriority.high.rawValue {
                counts[.smart(.priority), default: 0] += 1
            }
            if let dueDate = task.dueDate {
                counts[.smart(dueDate < startOfToday ? .overdue : .upcoming), default: 0] += 1
                if calendar.isDate(dueDate, inSameDayAs: startOfToday) {
                    counts[.smart(.today), default: 0] += 1
                }
            }
        }
        return counts
    }

    static func filtered(
        _ tasks: [ClassGodTodo],
        selection: TodoListSelection,
        projects: [TodoProject] = [],
        query: String,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [ClassGodTodo] {
        let startOfToday = calendar.startOfDay(for: now)
        let projectNames = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0.name) })
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)

        let result = tasks.filter { task in
            guard matches(task, selection: selection, startOfToday: startOfToday, calendar: calendar) else {
                return false
            }
            guard !query.isEmpty else { return true }
            return task.title.localizedCaseInsensitiveContains(query)
                || task.notes.localizedCaseInsensitiveContains(query)
                || task.tags.contains { $0.localizedCaseInsensitiveContains(query) }
                || task.subtasks.contains { $0.title.localizedCaseInsensitiveContains(query) }
                || task.projectID.flatMap { projectNames[$0] }?.localizedCaseInsensitiveContains(query) == true
        }
        return sorted(result, now: now, calendar: calendar)
    }

    static func sorted(
        _ tasks: [ClassGodTodo],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [ClassGodTodo] {
        let startOfToday = calendar.startOfDay(for: now)
        return tasks.sorted { lhs, rhs in
            precedes(lhs, rhs, startOfToday: startOfToday)
        }
    }

    fileprivate static func precedes(_ lhs: ClassGodTodo, _ rhs: ClassGodTodo, startOfToday: Date) -> Bool {
        if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
        if lhs.isCompleted, rhs.isCompleted {
            if lhs.completedAt != rhs.completedAt { return (lhs.completedAt ?? .distantPast) > (rhs.completedAt ?? .distantPast) }
        }
        let lhsOverdue = lhs.dueDate.map { $0 < startOfToday } ?? false
        let rhsOverdue = rhs.dueDate.map { $0 < startOfToday } ?? false
        if lhsOverdue != rhsOverdue { return lhsOverdue }
        if lhs.dueDate != rhs.dueDate {
            return (lhs.dueDate ?? .distantFuture) < (rhs.dueDate ?? .distantFuture)
        }
        if lhs.priority != rhs.priority { return lhs.priority.rawValue > rhs.priority.rawValue }
        if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
        if lhs.title != rhs.title { return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    private static func matches(
        _ task: ClassGodTodo,
        selection: TodoListSelection,
        startOfToday: Date,
        calendar: Calendar
    ) -> Bool {
        switch selection {
        case .project(let projectID):
            return !task.isCompleted && task.projectID == projectID
        case .smart(let list):
            switch list {
            case .inbox:
                return !task.isCompleted && task.projectID == nil
            case .today:
                return !task.isCompleted
                    && task.dueDate.map { calendar.isDate($0, inSameDayAs: startOfToday) } == true
            case .upcoming:
                return !task.isCompleted && task.dueDate.map { $0 >= startOfToday } == true
            case .overdue:
                return !task.isCompleted && task.dueDate.map { $0 < startOfToday } == true
            case .priority:
                return !task.isCompleted && task.priority.rawValue >= TodoPriority.high.rawValue
            case .all:
                return !task.isCompleted
            case .completed:
                return task.isCompleted
            }
        }
    }
}

nonisolated enum TodoRecurrencePolicy {
    static func nextDate(
        rule: TodoRecurrence,
        after dueDate: Date?,
        completedAt: Date,
        calendar: Calendar = .current
    ) -> Date? {
        guard rule != .none else { return nil }
        var candidate = dueDate ?? completedAt
        repeat {
            guard let advanced = advance(candidate, rule: rule, calendar: calendar),
                  advanced > candidate else { return nil }
            candidate = advanced
        } while candidate <= completedAt
        return candidate
    }

    static func nextOccurrence(
        after task: ClassGodTodo,
        completedAt: Date,
        calendar: Calendar = .current
    ) -> ClassGodTodo? {
        let eventDate = max(task.createdAt, completedAt)
        guard let dueDate = nextDate(
            rule: task.recurrence,
            after: task.dueDate,
            completedAt: eventDate,
            calendar: calendar
        ) else { return nil }
        return ClassGodTodo(
            title: task.title,
            notes: task.notes,
            projectID: task.projectID,
            tags: task.tags,
            subtasks: task.subtasks.map { TodoSubtask(title: $0.title, createdAt: eventDate) },
            dueDate: dueDate,
            priority: task.priority,
            recurrence: task.recurrence,
            recurrenceParentID: task.id,
            createdAt: eventDate
        )
    }

    private static func advance(
        _ date: Date,
        rule: TodoRecurrence,
        calendar: Calendar
    ) -> Date? {
        switch rule {
        case .none:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekdays:
            var candidate = calendar.date(byAdding: .day, value: 1, to: date)
            while let date = candidate, [1, 7].contains(calendar.component(.weekday, from: date)) {
                candidate = calendar.date(byAdding: .day, value: 1, to: date)
            }
            return candidate
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        }
    }
}

nonisolated enum TodoStoragePolicy {
    static func storageURL(applicationSupportRoot: URL) -> URL {
        applicationSupportRoot
            .appendingPathComponent("ClassGod/Todo", isDirectory: true)
            .appendingPathComponent("todo.json")
    }

    static func encode(_ snapshot: TodoSnapshot) throws -> Data {
        try JSONEncoder().encode(snapshot)
    }

    static func decode(_ data: Data) throws -> TodoSnapshot {
        try JSONDecoder().decode(TodoSnapshot.self, from: data)
    }
}
