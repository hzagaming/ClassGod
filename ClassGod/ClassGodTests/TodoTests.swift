import Foundation
import Testing
@testable import ClassGod

@Suite("Todo")
struct TodoTests {
    @Test("Todo row animation staggering is bounded and instant-safe")
    func boundsRowAnimationDelay() {
        #expect(TodoMotionPolicy.rowDelay(index: -1, duration: 1) == 0)
        #expect(TodoMotionPolicy.rowDelay(index: 0, duration: 1) == 0)
        #expect(TodoMotionPolicy.rowDelay(index: 3, duration: 1) == 0.18)
        #expect(TodoMotionPolicy.rowDelay(index: 100, duration: 1) == 0.36)
        #expect(TodoMotionPolicy.rowDelay(index: 3, duration: 0) == 0)
    }

    @Test("Todo deletion follows the global confirmation preference")
    func resolvesDeletionConfirmation() {
        #expect(TodoDeletionPolicy.action(confirmBeforeDelete: true) == .confirm)
        #expect(TodoDeletionPolicy.action(confirmBeforeDelete: false) == .deleteImmediately)
    }

    @Test("Focus Pulse summarizes workload and recommends the next task")
    func buildsFocusPulseSnapshot() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_767_268_800)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let overdue = ClassGodTodo(title: "Overdue", dueDate: yesterday, createdAt: yesterday)
        let today = ClassGodTodo(title: "Today", dueDate: now, createdAt: yesterday)
        let upcoming = ClassGodTodo(title: "Upcoming", dueDate: tomorrow, createdAt: yesterday)
        let doneToday = ClassGodTodo(
            title: "Done today",
            completedAt: now,
            createdAt: yesterday
        )
        let doneEarlier = ClassGodTodo(
            title: "Done earlier",
            completedAt: yesterday,
            createdAt: yesterday
        )

        let snapshot = TodoFocusPolicy.snapshot(
            [upcoming, doneEarlier, today, doneToday, overdue],
            now: now,
            calendar: calendar
        )

        #expect(snapshot.activeCount == 3)
        #expect(snapshot.overdueCount == 1)
        #expect(snapshot.completedTodayCount == 1)
        #expect(snapshot.focusTaskID == overdue.id)
        #expect(snapshot.progress == 0.25)

        let empty = TodoFocusPolicy.snapshot([], now: now, calendar: calendar)
        #expect(empty.progress == 1)
        #expect(empty.focusTaskID == nil)
    }

    @Test("Snapshot normalization removes invalid data without losing valid tasks")
    func normalizesSnapshot() {
        let project = TodoProject(name: "  School  ", color: .blue)
        let subtask = TodoSubtask(title: "  Outline  ")
        let valid = ClassGodTodo(
            title: "  Finish report  ",
            notes: "Details",
            projectID: project.id,
            tags: [" study ", "Study", "#urgent", ""],
            subtasks: [subtask, subtask, TodoSubtask(title: "   ")],
            priority: .high
        )
        let orphan = ClassGodTodo(title: "Read chapter", projectID: UUID())
        let blank = ClassGodTodo(title: "   ")

        let normalized = TodoContentPolicy.normalized(
            TodoSnapshot(tasks: [valid, valid, orphan, blank], projects: [project, project])
        )

        #expect(normalized.projects.count == 1)
        #expect(normalized.projects[0].name == "School")
        #expect(normalized.tasks.count == 2)
        #expect(normalized.tasks[0].title == "Finish report")
        #expect(normalized.tasks[0].tags == ["study", "urgent"])
        #expect(normalized.tasks[0].subtasks.map(\.title) == ["Outline"])
        #expect(normalized.tasks[1].projectID == nil)
    }

    @Test("Smart lists classify active and completed tasks")
    func filtersSmartLists() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_767_268_800) // 2026-01-01 12:00 UTC
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let project = TodoProject(name: "School", color: .mint)
        let inbox = ClassGodTodo(title: "Inbox")
        let today = ClassGodTodo(title: "Today", dueDate: now)
        let overdue = ClassGodTodo(title: "Overdue", dueDate: yesterday)
        let upcoming = ClassGodTodo(title: "Upcoming", projectID: project.id, dueDate: tomorrow)
        let priority = ClassGodTodo(title: "Priority", priority: .high)
        let completed = ClassGodTodo(title: "Done", completedAt: now)
        let tasks = [inbox, today, overdue, upcoming, priority, completed]

        #expect(TodoCollectionPolicy.filtered(tasks, selection: .smart(.today), query: "", now: now, calendar: calendar).map(\.id) == [today.id])
        #expect(TodoCollectionPolicy.filtered(tasks, selection: .smart(.overdue), query: "", now: now, calendar: calendar).map(\.id) == [overdue.id])
        #expect(TodoCollectionPolicy.filtered(tasks, selection: .smart(.upcoming), query: "", now: now, calendar: calendar).map(\.id) == [today.id, upcoming.id])
        #expect(TodoCollectionPolicy.filtered(tasks, selection: .smart(.priority), query: "", now: now, calendar: calendar).map(\.id) == [priority.id])
        #expect(TodoCollectionPolicy.filtered(tasks, selection: .project(project.id), query: "", now: now, calendar: calendar).map(\.id) == [upcoming.id])
        #expect(TodoCollectionPolicy.filtered(tasks, selection: .smart(.completed), query: "", now: now, calendar: calendar).map(\.id) == [completed.id])
    }

    @Test("Search spans title, notes, tags, and project names")
    func searchesTaskMetadata() {
        let project = TodoProject(name: "Physics", color: .violet)
        let tasks = [
            ClassGodTodo(
                title: "Lab report",
                notes: "Measure acceleration",
                projectID: project.id,
                tags: ["school"],
                subtasks: [TodoSubtask(title: "Create chart")]
            ),
            ClassGodTodo(title: "Buy milk")
        ]

        for query in ["report", "acceleration", "school", "physics", "chart"] {
            let results = TodoCollectionPolicy.filtered(
                tasks,
                selection: .smart(.all),
                projects: [project],
                query: query
            )
            #expect(results.map(\.title) == ["Lab report"])
        }
    }

    @Test("Active task ordering is deterministic and useful")
    func sortsActiveTasks() {
        let now = Date(timeIntervalSince1970: 1_767_268_800)
        let overdue = ClassGodTodo(title: "Overdue", dueDate: now.addingTimeInterval(-86_400))
        let urgent = ClassGodTodo(title: "Urgent", priority: .urgent)
        let normal = ClassGodTodo(title: "Normal")

        let sorted = TodoCollectionPolicy.sorted([normal, urgent, overdue], now: now)

        #expect(sorted.map(\.title) == ["Overdue", "Urgent", "Normal"])
    }

    @Test("Recurrence skips missed intervals and weekdays skip weekends")
    func calculatesNextRecurrence() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let due = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 9)))
        let completed = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 3, hour: 12)))

        let daily = try #require(TodoRecurrencePolicy.nextDate(
            rule: .daily,
            after: due,
            completedAt: completed,
            calendar: calendar
        ))
        let weekdays = try #require(TodoRecurrencePolicy.nextDate(
            rule: .weekdays,
            after: due,
            completedAt: completed,
            calendar: calendar
        ))

        #expect(calendar.dateComponents([.year, .month, .day, .hour], from: daily) == DateComponents(year: 2026, month: 1, day: 4, hour: 9))
        #expect(calendar.dateComponents([.year, .month, .day, .hour], from: weekdays) == DateComponents(year: 2026, month: 1, day: 5, hour: 9))
    }

    @Test("A recurring task creates a fresh pending occurrence")
    func createsNextOccurrence() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let due = Date(timeIntervalSince1970: 1_767_268_800)
        let completed = due.addingTimeInterval(3_600)
        let task = ClassGodTodo(
            title: "Daily review",
            notes: "Ten minutes",
            tags: ["routine"],
            subtasks: [TodoSubtask(title: "Open journal", completedAt: completed)],
            dueDate: due,
            priority: .medium,
            recurrence: .daily
        )

        let next = try #require(TodoRecurrencePolicy.nextOccurrence(
            after: task,
            completedAt: completed,
            calendar: calendar
        ))

        #expect(next.id != task.id)
        #expect(next.recurrenceParentID == task.id)
        #expect(next.title == task.title)
        #expect(next.notes == task.notes)
        #expect(next.tags == task.tags)
        #expect(next.recurrence == .daily)
        #expect(next.completedAt == nil)
        #expect(next.subtasks.map(\.title) == ["Open journal"])
        #expect(next.subtasks.allSatisfy { !$0.isCompleted })
    }

    @Test("Todo snapshots round trip through the local storage format")
    func storageRoundTrip() throws {
        let snapshot = TodoSnapshot(
            tasks: [ClassGodTodo(title: "Ship it", tags: ["release"], priority: .urgent)],
            projects: [TodoProject(name: "ClassGod", color: .rose)]
        )

        let decoded = try TodoStoragePolicy.decode(TodoStoragePolicy.encode(snapshot))

        #expect(decoded == snapshot)
        let root = URL(fileURLWithPath: "/tmp/Application Support")
        #expect(TodoStoragePolicy.storageURL(applicationSupportRoot: root).path == "/tmp/Application Support/ClassGod/Todo/todo.json")
    }

    @Test("Todo labels are localized in English and Simplified Chinese")
    func localizesTodoLabels() throws {
        let english = Locale(identifier: "en")
        let chineseURL = try #require(Bundle.main.url(forResource: "zh-Hans", withExtension: "lproj"))
        let chinese = try #require(Bundle(url: chineseURL))

        #expect(String(localized: "todo.title", bundle: .main, locale: english) == "Todo")
        #expect(String(localized: "todo.focus_pulse", bundle: .main, locale: english) == "Focus Pulse")
        #expect(String(localized: "todo.open_focus_task", bundle: .main, locale: english) == "Open the recommended task")
        #expect(String(localized: "todo.quick_add", bundle: .main, locale: english).contains("Return"))
        #expect(String(localized: "todo.recurrence.weekdays", bundle: .main, locale: english) == "Weekdays")
        #expect(chinese.localizedString(forKey: "todo.title", value: nil, table: nil) == "待办清单")
        #expect(chinese.localizedString(forKey: "todo.mark_done", value: nil, table: nil) == "标记为已完成")
        #expect(chinese.localizedString(forKey: "todo.all_clear", value: nil, table: nil) == "全部清空")
        #expect(chinese.localizedString(forKey: "todo.open_focus_task", value: nil, table: nil) == "打开推荐任务")
        #expect(chinese.localizedString(forKey: "todo.subtasks", value: nil, table: nil) == "子任务")
    }
}
