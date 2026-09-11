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

    @Test("Sidebar counts match every list across task metadata combinations")
    func countsAllLists() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_767_268_800)
        let projectIDs = [UUID(), UUID()]
        let dueDates: [Date?] = [nil, now.addingTimeInterval(-86_400), now, now.addingTimeInterval(86_400)]
        var tasks: [ClassGodTodo] = []
        for projectID in [nil] + projectIDs.map(Optional.some) {
            for priority in TodoPriority.allCases {
                for dueDate in dueDates {
                    for completed in [false, true] {
                        tasks.append(ClassGodTodo(
                            title: "Task \(tasks.count)",
                            projectID: projectID,
                            dueDate: dueDate,
                            priority: priority,
                            completedAt: completed ? now : nil,
                            createdAt: now
                        ))
                    }
                }
            }
        }
        let counts = TodoCollectionPolicy.counts(tasks, now: now, calendar: calendar)
        let selections = TodoSmartList.allCases.map(TodoListSelection.smart)
            + (projectIDs + [UUID()]).map(TodoListSelection.project)
        for selection in selections {
            let listed = TodoCollectionPolicy.filtered(tasks, selection: selection, query: "", now: now, calendar: calendar)
            #expect(counts[selection, default: 0] == listed.count)
        }
        #expect(counts[.smart(.all)] == 60)
        #expect(counts[.smart(.completed)] == 60)
        #expect(counts[.smart(.today)] == 15)
        #expect(counts[.smart(.priority)] == 24)
        #expect(counts[.smart(.inbox)] == 20)
        #expect(counts[.project(projectIDs[0])] == 20)
        #expect(TodoCollectionPolicy.counts([], now: now, calendar: calendar).isEmpty)
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

    @Test("Focus recommendations preserve every active-task ordering tie-breaker")
    func preservesFocusOrdering() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_767_268_800)
        let created = now.addingTimeInterval(-7 * 86_400)
        let expected = [
            ClassGodTodo(title: "Oldest overdue", dueDate: now.addingTimeInterval(-2 * 86_400), createdAt: created),
            ClassGodTodo(title: "Overdue", dueDate: now.addingTimeInterval(-86_400), createdAt: created),
            ClassGodTodo(title: "Today", dueDate: now, createdAt: created),
            ClassGodTodo(title: "Tomorrow", dueDate: now.addingTimeInterval(86_400), createdAt: created),
            ClassGodTodo(title: "Urgent", priority: .urgent, createdAt: now),
            ClassGodTodo(title: "Older", createdAt: created.addingTimeInterval(-1)),
            ClassGodTodo(title: "Task 2", createdAt: created),
            ClassGodTodo(title: "Task 10", createdAt: created),
            ClassGodTodo(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, title: "Tie", createdAt: created),
            ClassGodTodo(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, title: "Tie", createdAt: created)
        ]
        let completed = ClassGodTodo(title: "Completed", priority: .urgent, completedAt: now, createdAt: created)
        for index in expected.indices {
            let tasks = [completed] + expected[index...].reversed()
            let snapshot = TodoFocusPolicy.snapshot(tasks, now: now, calendar: calendar)
            #expect(snapshot.focusTaskID == expected[index].id)
            #expect(snapshot.activeCount == expected.count - index)
            #expect(snapshot.completedTodayCount == 1)
            #expect(TodoCollectionPolicy.sorted(tasks, now: now, calendar: calendar).map(\.id)
                == expected[index...].map(\.id) + [completed.id])
        }
        let completedOnly = TodoFocusPolicy.snapshot([completed], now: now, calendar: calendar)
        #expect(completedOnly.focusTaskID == nil)
        #expect(completedOnly.activeCount == 0)
        #expect(completedOnly.progress == 1)
    }

    @Test("Today and overdue honor local midnight across daylight-saving changes", arguments: [
        ("America/Los_Angeles", 2026, 3, 8),
        ("America/Los_Angeles", 2026, 11, 1),
        ("Europe/Berlin", 2026, 3, 29),
        ("Europe/Berlin", 2026, 10, 25),
        ("Asia/Singapore", 2026, 9, 11)
    ])
    func classifiesDayBoundaries(zone: String, year: Int, month: Int, day: Int) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: zone))
        let start = try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
        let end = try #require(calendar.date(byAdding: .day, value: 1, to: start))
        let now = start.addingTimeInterval(3_600)
        let tasks = [
            ClassGodTodo(title: "Previous day", dueDate: start.addingTimeInterval(-1)),
            ClassGodTodo(title: "Start", dueDate: start),
            ClassGodTodo(title: "End", dueDate: end.addingTimeInterval(-1)),
            ClassGodTodo(title: "Next day", dueDate: end),
            ClassGodTodo(title: "No date"),
            ClassGodTodo(title: "Done before", completedAt: start.addingTimeInterval(-1)),
            ClassGodTodo(title: "Done at start", completedAt: start),
            ClassGodTodo(title: "Done at end", completedAt: end.addingTimeInterval(-1)),
            ClassGodTodo(title: "Done next day", completedAt: end)
        ]
        let expected: [TodoSmartList: [String]] = [
            .today: ["Start", "End"],
            .overdue: ["Previous day"],
            .upcoming: ["Start", "End", "Next day"]
        ]
        for (list, titles) in expected {
            #expect(TodoCollectionPolicy.filtered(tasks, selection: .smart(list), query: "", now: now, calendar: calendar).map(\.title) == titles)
        }
        let counts = TodoCollectionPolicy.counts(tasks, now: now, calendar: calendar)
        for (list, titles) in expected {
            #expect(counts[.smart(list)] == titles.count)
        }
        let snapshot = TodoFocusPolicy.snapshot(tasks, now: now, calendar: calendar)
        #expect(snapshot.activeCount == 5)
        #expect(snapshot.overdueCount == 1)
        #expect(snapshot.completedTodayCount == 2)
        #expect(snapshot.focusTaskID == tasks[0].id)
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
