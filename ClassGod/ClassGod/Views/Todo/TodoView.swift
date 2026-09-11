import SwiftUI

nonisolated enum TodoMotionPolicy {
    static func rowDelay(index: Int, duration: Double) -> Double {
        guard duration > 0 else { return 0 }
        return Double(min(max(index, 0), 6)) * duration * 0.06
    }
}

struct TodoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var service = TodoService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var selection: TodoListSelection = .smart(.today)
    @State private var searchText = ""
    @State private var quickTitle = ""
    @State private var editingTask: ClassGodTodo?
    @State private var taskPendingDeletion: ClassGodTodo?
    @State private var projectPendingDeletion: TodoProject?
    @State private var isCreatingProject = false
    @State private var hoveredTaskID: UUID?
    @FocusState private var searchFocused: Bool
    @FocusState private var quickAddFocused: Bool

    let onClose: () -> Void

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    private var accent: Color { prefs.preferences.themeAccent.color }
    private var motionAnimation: Animation? {
        let duration = Anim.duration
        return duration > 0 ? .easeOut(duration: duration) : nil
    }
    private var panelTransition: AnyTransition {
        guard !reduceMotion, Anim.enabled else { return .opacity }
        return .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity.combined(with: .scale(scale: 0.98))
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider().background(Color.white.opacity(0.1))
            content
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.025, green: 0.09, blue: 0.14), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .tint(accent)
        .preferredColorScheme(.dark)
        .overlay(
            RoundedRectangle(cornerRadius: 12 * zoomScale)
                .stroke(Color.white.opacity(0.12), lineWidth: zoomScale)
                .allowsHitTesting(false)
        )
        .sheet(item: $editingTask) { task in
            TodoEditorSheet(
                task: task,
                projects: service.projects,
                zoomScale: zoomScale,
                accent: accent,
                onSave: save,
                onCancel: { editingTask = nil }
            )
        }
        .sheet(isPresented: $isCreatingProject) {
            TodoProjectEditorSheet(
                zoomScale: zoomScale,
                accent: accent,
                onSave: createProject,
                onCancel: { isCreatingProject = false }
            )
        }
        .confirmationDialog(
            "todo.delete_task_title",
            isPresented: Binding(
                get: { taskPendingDeletion != nil },
                set: { if !$0 { taskPendingDeletion = nil } }
            )
        ) {
            Button("todo.delete", role: .destructive) { deletePendingTask() }
            Button("button.cancel", role: .cancel) { taskPendingDeletion = nil }
        } message: {
            Text("todo.delete_task_message")
        }
        .confirmationDialog(
            "todo.delete_project_title",
            isPresented: Binding(
                get: { projectPendingDeletion != nil },
                set: { if !$0 { projectPendingDeletion = nil } }
            )
        ) {
            Button("todo.delete", role: .destructive) { deletePendingProject() }
            Button("button.cancel", role: .cancel) { projectPendingDeletion = nil }
        } message: {
            Text("todo.delete_project_message")
        }
        .onExitCommand(perform: onClose)
    }

    private var sidebar: some View {
        let counts = TodoCollectionPolicy.counts(service.tasks)
        return VStack(alignment: .leading, spacing: 12 * zoomScale) {
            HStack(spacing: 8 * zoomScale) {
                Button(action: onClose) {
                    Image(systemName: "minus")
                        .font(.system(size: 11 * zoomScale, weight: .bold))
                        .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.65))
                .accessibilityLabel(Text("button.close"))

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(accent)
                Text("todo.title")
                    .font(.system(size: 14 * zoomScale, weight: .bold, design: .rounded))
            }

            sidebarLabel("todo.focus")
            VStack(spacing: 3 * zoomScale) {
                ForEach(TodoSmartList.allCases) { list in
                    sidebarRow(
                        selection: .smart(list),
                        icon: list.icon,
                        title: Text(list.title),
                        color: list.color,
                        count: counts[.smart(list), default: 0]
                    )
                }
            }

            HStack {
                sidebarLabel("todo.projects")
                Spacer()
                Button {
                    isCreatingProject = true
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10 * zoomScale, weight: .bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(accent)
                .accessibilityLabel(Text("todo.new_project"))
            }

            if service.projects.isEmpty {
                Text("todo.no_projects")
                    .font(.system(size: 9 * zoomScale, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.horizontal, 8 * zoomScale)
                    .transition(panelTransition)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 3 * zoomScale) {
                        ForEach(service.projects) { project in
                            sidebarRow(
                                selection: .project(project.id),
                                icon: "circle.fill",
                                title: Text(project.name),
                                color: project.color.color,
                                count: counts[.project(project.id), default: 0]
                            )
                            .contextMenu {
                                Button("todo.delete_project", role: .destructive) {
                                    requestProjectDeletion(project)
                                }
                            }
                        }
                    }
                }
                .transition(panelTransition)
            }

            Spacer(minLength: 4 * zoomScale)
            todayProgress
        }
        .animation(motionAnimation, value: service.projects.map(\.id))
        .padding(14 * zoomScale)
        .frame(width: 210 * zoomScale)
        .background(Color.black.opacity(0.52))
    }

    private func sidebarLabel(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.35))
            .textCase(.uppercase)
    }

    private func sidebarRow(
        selection target: TodoListSelection,
        icon: String,
        title: Text,
        color: Color,
        count: Int
    ) -> some View {
        let selected = selection == target
        return Button {
            guard !selected else { return }
            SoundEffectManager.shared.playButtonClick()
            HapticManager.shared.generic()
            Anim.with { selection = target }
        } label: {
            HStack(spacing: 8 * zoomScale) {
                Image(systemName: icon)
                    .font(.system(size: 10 * zoomScale, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 14 * zoomScale)
                title
                    .font(.system(size: 10 * zoomScale, weight: selected ? .semibold : .regular, design: .rounded))
                    .lineLimit(1)
                Spacer(minLength: 4 * zoomScale)
                Text("\(count)")
                    .font(.system(size: 8 * zoomScale, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.38))
                    .contentTransition(.numericText(value: Double(count)))
            }
            .foregroundStyle(selected ? .white : .white.opacity(0.62))
            .padding(.horizontal, 8 * zoomScale)
            .padding(.vertical, 7 * zoomScale)
            .background(selected ? accent.opacity(0.18) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 7 * zoomScale)
                    .stroke(selected ? accent.opacity(0.45) : Color.clear, lineWidth: zoomScale)
            )
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(accent)
                    .frame(width: 2 * zoomScale, height: 16 * zoomScale)
                    .scaleEffect(y: selected ? 1 : 0)
                    .opacity(selected ? 1 : 0)
            }
            .clipShape(RoundedRectangle(cornerRadius: 7 * zoomScale))
            .scaleEffect(selected ? 1 : 0.985, anchor: .leading)
        }
        .buttonStyle(.plain)
        .animation(motionAnimation, value: selected)
        .animation(motionAnimation, value: count)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var todayProgress: some View {
        let todayTasks = service.tasks.filter { task in
            task.dueDate.map(Calendar.current.isDateInToday) == true
        }
        let completed = todayTasks.filter(\.isCompleted).count
        let total = todayTasks.count
        return VStack(alignment: .leading, spacing: 6 * zoomScale) {
            HStack {
                Text("todo.today_progress")
                    .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                Spacer()
                Text("\(completed)/\(total)")
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .contentTransition(.numericText(value: Double(completed)))
            }
            .foregroundStyle(.white.opacity(0.42))
            ProgressView(value: Double(completed), total: Double(max(1, total)))
                .progressViewStyle(.linear)
                .tint(total > 0 && completed == total ? .green : accent)
                .animation(motionAnimation, value: completed)
        }
        .animation(motionAnimation, value: total)
        .padding(9 * zoomScale)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
    }

    private var content: some View {
        let visibleTasks = service.filteredTasks(selection: selection, query: searchText)
        return VStack(spacing: 0) {
            contentHeader(taskCount: visibleTasks.count)
            Divider().background(Color.white.opacity(0.08))
            focusPulse
            Divider().background(Color.white.opacity(0.08))
            ZStack {
                if visibleTasks.isEmpty {
                    emptyState
                        .transition(panelTransition)
                } else {
                    taskList(visibleTasks)
                        .transition(panelTransition)
                }
            }
            .animation(motionAnimation, value: visibleTasks.isEmpty)
            Divider().background(Color.white.opacity(0.08))
            quickAddBar
        }
        .overlay {
            Group {
                Button { searchFocused = true } label: { EmptyView() }
                    .keyboardShortcut("f", modifiers: .command)
                Button { quickAddFocused = true } label: { EmptyView() }
                    .keyboardShortcut("n", modifiers: .command)
            }
            .frame(width: 0, height: 0)
            .opacity(0)
        }
    }

    private var focusPulse: some View {
        let snapshot = TodoFocusPolicy.snapshot(service.tasks)
        let task = snapshot.focusTaskID.flatMap { id in
            service.tasks.first { $0.id == id }
        }
        return TodoFocusPulseView(
            snapshot: snapshot,
            task: task,
            zoomScale: zoomScale,
            accent: accent,
            animation: motionAnimation
        ) { task in
            openEditor(task)
        }
    }

    private func contentHeader(taskCount: Int) -> some View {
        HStack(spacing: 12 * zoomScale) {
            VStack(alignment: .leading, spacing: 2 * zoomScale) {
                ZStack(alignment: .leading) {
                    selectionTitle
                        .font(.system(size: 20 * zoomScale, weight: .bold, design: .rounded))
                        .id(selection.id)
                        .transition(panelTransition)
                }
                .animation(motionAnimation, value: selection)
                Text(String(format: String(localized: "todo.task_count"), taskCount))
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.38))
                    .contentTransition(.numericText(value: Double(taskCount)))
                    .animation(motionAnimation, value: taskCount)
            }

            Spacer(minLength: 8 * zoomScale)

            HStack(spacing: 6 * zoomScale) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.32))
                TextField("todo.search", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10 * zoomScale, design: .rounded))
                    .focused($searchFocused)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        SoundEffectManager.shared.playButtonClick()
                        HapticManager.shared.generic()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.3))
                    .accessibilityLabel(Text("button.clear"))
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .animation(motionAnimation, value: searchText.isEmpty)
            .padding(.horizontal, 9 * zoomScale)
            .frame(width: 190 * zoomScale, height: 30 * zoomScale)
            .background(Color.white.opacity(0.055))
            .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))

            Button {
                openEditor(draftForCurrentSelection(title: ""))
            } label: {
                Label("todo.new_task", systemImage: "plus")
                    .font(.system(size: 10 * zoomScale, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 10 * zoomScale)
                    .frame(height: 30 * zoomScale)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
            .background(accent)
            .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
            .pressScale(1.025)
        }
        .padding(.horizontal, 18 * zoomScale)
        .padding(.vertical, 13 * zoomScale)
        .background(Color.black.opacity(0.3))
    }

    private func taskList(_ tasks: [ClassGodTodo]) -> some View {
        let sectionGroups = sectionGroups(for: tasks)
        let visibleTaskIDs = tasks.map(\.id)
        return ScrollView(showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 12 * zoomScale) {
                ForEach(sectionGroups) { group in
                    VStack(alignment: .leading, spacing: 6 * zoomScale) {
                        HStack {
                            Text(group.section.title)
                                .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                                .foregroundStyle(group.section.color.opacity(0.8))
                            Rectangle()
                                .fill(Color.white.opacity(0.07))
                                .frame(height: zoomScale)
                        }
                        ForEach(Array(group.tasks.enumerated()), id: \.element.id) { index, task in
                            taskRow(task)
                                .transition(panelTransition)
                                .animation(rowAnimation(index: index), value: visibleTaskIDs)
                        }
                    }
                    .transition(panelTransition)
                }
            }
            .animation(motionAnimation, value: sectionGroups.map(\.id))
            .padding(16 * zoomScale)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func taskRow(_ task: ClassGodTodo) -> some View {
        let hovered = hoveredTaskID == task.id
        return taskRowContent(task)
        .modifier(TodoTaskCardStyle(
            hovered: hovered,
            completed: task.isCompleted,
            reduceMotion: reduceMotion,
            zoomScale: zoomScale,
            accent: accent,
            animation: motionAnimation
        ))
        .onHover { updateTaskHover($0, taskID: task.id) }
        .contextMenu {
            taskContextMenu(task)
        }
    }

    private func taskRowContent(_ task: ClassGodTodo) -> some View {
        HStack(alignment: .top, spacing: 11 * zoomScale) {
            taskCompletionButton(task)
            taskDetailsButton(task)
        }
    }

    private func taskCompletionButton(_ task: ClassGodTodo) -> some View {
        Button { toggle(task) } label: {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18 * zoomScale, weight: .medium))
                .foregroundStyle(task.isCompleted ? .green : task.priority.color)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .animation(motionAnimation, value: task.isCompleted)
        .accessibilityLabel(Text(task.isCompleted ? "todo.mark_pending" : "todo.mark_done"))
    }

    private func taskDetailsButton(_ task: ClassGodTodo) -> some View {
        Button { openEditor(task) } label: {
            VStack(alignment: .leading, spacing: 6 * zoomScale) {
                HStack(spacing: 7 * zoomScale) {
                    Text(task.title)
                        .font(.system(size: 12 * zoomScale, weight: .semibold, design: .rounded))
                        .foregroundStyle(task.isCompleted ? .white.opacity(0.34) : .white.opacity(0.9))
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)
                    if task.priority != .none {
                        Image(systemName: task.priority.icon)
                            .font(.system(size: 9 * zoomScale, weight: .bold))
                            .foregroundStyle(task.priority.color)
                    }
                    Spacer(minLength: 0)
                }

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.system(size: 9 * zoomScale, design: .rounded))
                        .foregroundStyle(.white.opacity(0.38))
                        .lineLimit(2)
                }

                taskMetadata(task)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func taskContextMenu(_ task: ClassGodTodo) -> some View {
        Button("todo.edit") { openEditor(task) }
        Button(task.isCompleted ? "todo.mark_pending" : "todo.mark_done") { toggle(task) }
        Divider()
        Button("todo.delete", role: .destructive) { requestTaskDeletion(task) }
    }

    @ViewBuilder
    private func taskMetadata(_ task: ClassGodTodo) -> some View {
        let project = service.projects.first { $0.id == task.projectID }
        if task.dueDate != nil
            || project != nil
            || !task.tags.isEmpty
            || !task.subtasks.isEmpty
            || task.recurrence != .none {
            HStack(spacing: 7 * zoomScale) {
                if let dueDate = task.dueDate {
                    Label {
                        Text(dueDate, format: .dateTime.month(.abbreviated).day())
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .foregroundStyle(dueColor(dueDate, completed: task.isCompleted))
                }
                if let project {
                    Label {
                        Text(project.name)
                    } icon: {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(project.color.color)
                    }
                    .foregroundStyle(.white.opacity(0.42))
                }
                if !task.subtasks.isEmpty {
                    let completed = task.subtasks.filter(\.isCompleted).count
                    Label("\(completed)/\(task.subtasks.count)", systemImage: "checklist")
                        .foregroundStyle(completed == task.subtasks.count ? .green : .white.opacity(0.42))
                        .contentTransition(.numericText(value: Double(completed)))
                        .animation(motionAnimation, value: completed)
                }
                if task.recurrence != .none {
                    Label(task.recurrence.title, systemImage: "repeat")
                        .foregroundStyle(accent.opacity(0.7))
                }
                ForEach(task.tags.prefix(2), id: \.self) { tag in
                    Text("#\(tag)")
                        .foregroundStyle(accent.opacity(0.65))
                }
            }
            .font(.system(size: 8 * zoomScale, design: .monospaced))
            .lineLimit(1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10 * zoomScale) {
            Image(systemName: searchText.isEmpty ? "checkmark.circle" : "magnifyingglass")
                .font(.system(size: 42 * zoomScale, weight: .light))
                .foregroundStyle(accent.opacity(0.65))
                .contentTransition(.symbolEffect(.replace))
            Text(searchText.isEmpty ? "todo.empty" : "todo.no_results")
                .font(.system(size: 14 * zoomScale, weight: .semibold, design: .rounded))
            Text(searchText.isEmpty ? "todo.empty_hint" : "todo.search_hint")
                .font(.system(size: 9 * zoomScale, design: .rounded))
                .foregroundStyle(.white.opacity(0.36))
            if searchText.isEmpty {
                Button("todo.new_task") { openEditor(draftForCurrentSelection(title: "")) }
                    .buttonStyle(.borderedProminent)
                    .pressScale(1.025)
            }
        }
        .animation(motionAnimation, value: searchText.isEmpty)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var quickAddBar: some View {
        HStack(spacing: 8 * zoomScale) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(accent)
                .scaleEffect(quickAddFocused ? 1.12 : 1)
            TextField("todo.quick_add", text: $quickTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 11 * zoomScale, design: .rounded))
                .focused($quickAddFocused)
                .onSubmit(addQuickTask)
            Text("⌘N")
                .font(.system(size: 8 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.horizontal, 14 * zoomScale)
        .frame(height: 44 * zoomScale)
        .background(quickAddFocused ? accent.opacity(0.08) : Color.black.opacity(0.42))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(quickAddFocused ? accent.opacity(0.45) : Color.clear)
                .frame(height: zoomScale)
        }
        .animation(motionAnimation, value: quickAddFocused)
    }

    private var selectionTitle: Text {
        switch selection {
        case .smart(let list): Text(list.title)
        case .project(let id):
            Text(service.projects.first { $0.id == id }?.name ?? String(localized: "todo.projects"))
        }
    }

    private func sectionGroups(for tasks: [ClassGodTodo]) -> [TodoSectionGroup] {
        let grouped = Dictionary(grouping: tasks, by: taskSection)
        return TodoTaskSection.allCases.compactMap { section in
            guard let tasks = grouped[section], !tasks.isEmpty else { return nil }
            return TodoSectionGroup(section: section, tasks: tasks)
        }
    }

    private func taskSection(_ task: ClassGodTodo) -> TodoTaskSection {
        guard !task.isCompleted else { return .completed }
        guard let dueDate = task.dueDate else { return .anytime }
        let startOfToday = Calendar.current.startOfDay(for: Date())
        if dueDate < startOfToday { return .overdue }
        if Calendar.current.isDateInToday(dueDate) { return .today }
        return .upcoming
    }

    private func dueColor(_ date: Date, completed: Bool) -> Color {
        guard !completed else { return .white.opacity(0.28) }
        let startOfToday = Calendar.current.startOfDay(for: Date())
        if date < startOfToday { return .red }
        if Calendar.current.isDateInToday(date) { return .orange }
        return .white.opacity(0.42)
    }

    private func rowAnimation(index: Int) -> Animation? {
        let duration = Anim.duration
        guard duration > 0 else { return nil }
        return .easeOut(duration: duration).delay(
            TodoMotionPolicy.rowDelay(index: index, duration: duration)
        )
    }

    private func animated<Result>(_ body: () -> Result) -> Result {
        guard let motionAnimation else { return body() }
        return withAnimation(motionAnimation, body)
    }

    private func updateTaskHover(_ hovered: Bool, taskID: UUID) {
        animated {
            if hovered {
                hoveredTaskID = taskID
            } else if hoveredTaskID == taskID {
                hoveredTaskID = nil
            }
        }
    }

    private func draftForCurrentSelection(title: String) -> ClassGodTodo {
        var projectID: UUID?
        var dueDate: Date?
        var priority: TodoPriority = .none
        switch selection {
        case .project(let id):
            projectID = id
        case .smart(.today):
            dueDate = Date()
        case .smart(.upcoming):
            dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case .smart(.priority):
            priority = .high
        default:
            break
        }
        return ClassGodTodo(
            title: title,
            projectID: projectID,
            dueDate: dueDate,
            priority: priority
        )
    }

    private func addQuickTask() {
        let title = quickTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        guard animated({ service.save(draftForCurrentSelection(title: title)) }) else {
            showLimitError()
            return
        }
        quickTitle = ""
        SoundEffectManager.shared.playTabSaved()
        HapticManager.shared.success()
    }

    private func openEditor(_ task: ClassGodTodo) {
        editingTask = task
        SoundEffectManager.shared.playButtonClick()
        HapticManager.shared.generic()
    }

    private func save(_ task: ClassGodTodo) {
        guard animated({ service.save(task) }) else {
            showLimitError()
            return
        }
        editingTask = nil
        SoundEffectManager.shared.playTabSaved()
        HapticManager.shared.success()
    }

    private func toggle(_ task: ClassGodTodo) {
        guard animated({ service.toggleCompletion(task.id) }) else {
            showLimitError()
            return
        }
        task.isCompleted ? HapticManager.shared.generic() : HapticManager.shared.success()
        SoundEffectManager.shared.playButtonClick()
    }

    private func deletePendingTask() {
        defer { taskPendingDeletion = nil }
        guard let task = taskPendingDeletion else { return }
        deleteTask(task)
    }

    private func requestTaskDeletion(_ task: ClassGodTodo) {
        switch TodoDeletionPolicy.action(
            confirmBeforeDelete: prefs.preferences.confirmBeforeDelete
        ) {
        case .confirm:
            taskPendingDeletion = task
        case .deleteImmediately:
            deleteTask(task)
        }
    }

    private func deleteTask(_ task: ClassGodTodo) {
        guard animated({ service.deleteTask(task.id) }) else { return }
        SoundEffectManager.shared.playTabDeleted()
        HapticManager.shared.warning()
    }

    private func createProject(name: String, color: TodoProjectColor) {
        guard let id = animated({ service.addProject(name: name, color: color) }) else {
            ErrorToastManager.shared.show(
                title: String(localized: "todo.title"),
                message: String(localized: "todo.project_limit_reached")
            )
            return
        }
        isCreatingProject = false
        animated { selection = .project(id) }
        SoundEffectManager.shared.playTabSaved()
        HapticManager.shared.success()
    }

    private func deletePendingProject() {
        defer { projectPendingDeletion = nil }
        guard let project = projectPendingDeletion else { return }
        deleteProject(project)
    }

    private func requestProjectDeletion(_ project: TodoProject) {
        switch TodoDeletionPolicy.action(
            confirmBeforeDelete: prefs.preferences.confirmBeforeDelete
        ) {
        case .confirm:
            projectPendingDeletion = project
        case .deleteImmediately:
            deleteProject(project)
        }
    }

    private func deleteProject(_ project: TodoProject) {
        guard animated({ service.deleteProject(project.id) }) else { return }
        if selection == .project(project.id) {
            animated { selection = .smart(.inbox) }
        }
        SoundEffectManager.shared.playTabDeleted()
        HapticManager.shared.warning()
    }

    private func showLimitError() {
        ErrorToastManager.shared.show(
            title: String(localized: "todo.title"),
            message: String(localized: "todo.limit_reached")
        )
        HapticManager.shared.warning()
    }
}

private struct TodoFocusPulseView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered = false

    let snapshot: TodoFocusSnapshot
    let task: ClassGodTodo?
    let zoomScale: CGFloat
    let accent: Color
    let animation: Animation?
    let onOpenTask: (ClassGodTodo) -> Void

    private var percentage: Int {
        Int((snapshot.progress * 100).rounded())
    }

    private var taskTransition: AnyTransition {
        guard !reduceMotion, animation != nil else { return .opacity }
        return .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .scale(scale: 0.96))
        )
    }

    var body: some View {
        HStack(spacing: 14 * zoomScale) {
            progressRing
            focusContent
            Spacer(minLength: 8 * zoomScale)
            metrics
        }
        .padding(.horizontal, 16 * zoomScale)
        .padding(.vertical, 10 * zoomScale)
        .background(
            RoundedRectangle(cornerRadius: 10 * zoomScale)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(hovered ? 0.14 : 0.09), Color.white.opacity(0.025)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10 * zoomScale)
                .stroke(hovered ? accent.opacity(0.34) : Color.white.opacity(0.07), lineWidth: zoomScale)
        )
        .scaleEffect(InteractiveMotionPolicy.scale(
            active: hovered && !reduceMotion,
            requestedScale: 1.004,
            animationsEnabled: Anim.enabled
        ))
        .offset(y: hovered && !reduceMotion && Anim.enabled ? -zoomScale : 0)
        .shadow(color: hovered ? accent.opacity(0.1) : .clear, radius: 12 * zoomScale)
        .animation(animation, value: hovered)
        .animation(animation, value: snapshot)
        .onHover { value in
            withAnimation(animation) { hovered = value }
        }
        .padding(.horizontal, 16 * zoomScale)
        .padding(.vertical, 9 * zoomScale)
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 5 * zoomScale)
            Circle()
                .trim(from: 0, to: snapshot.progress)
                .stroke(
                    AngularGradient(
                        colors: [accent.opacity(0.45), accent, .green, accent],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5 * zoomScale, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(animation, value: snapshot.progress)

            if snapshot.focusTaskID == nil {
                Image(systemName: "checkmark")
                    .font(.system(size: 15 * zoomScale, weight: .bold))
                    .foregroundStyle(.green)
                    .contentTransition(.symbolEffect(.replace))
            } else {
                Text("\(percentage)%")
                    .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .contentTransition(.numericText(value: Double(percentage)))
            }
        }
        .frame(width: 52 * zoomScale, height: 52 * zoomScale)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("todo.focus_progress"))
        .accessibilityValue(Text("\(percentage)%"))
    }

    private var focusContent: some View {
        VStack(alignment: .leading, spacing: 5 * zoomScale) {
            Label("todo.focus_pulse", systemImage: "waveform.path.ecg")
                .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(accent.opacity(0.82))

            ZStack(alignment: .leading) {
                if let task {
                    Button { onOpenTask(task) } label: {
                        VStack(alignment: .leading, spacing: 3 * zoomScale) {
                            HStack(spacing: 5 * zoomScale) {
                                Text("todo.next_focus")
                                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.38))
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 7 * zoomScale, weight: .bold))
                                    .foregroundStyle(accent.opacity(0.7))
                            }
                            HStack(spacing: 6 * zoomScale) {
                                Text(task.title)
                                    .font(.system(size: 12 * zoomScale, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .lineLimit(1)
                                if task.priority != .none {
                                    Image(systemName: task.priority.icon)
                                        .font(.system(size: 8 * zoomScale, weight: .bold))
                                        .foregroundStyle(task.priority.color)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .pressScale(1.012)
                    .accessibilityHint(Text("todo.open_focus_task"))
                    .id(task.id)
                    .transition(taskTransition)
                } else {
                    VStack(alignment: .leading, spacing: 3 * zoomScale) {
                        Text("todo.all_clear")
                            .font(.system(size: 12 * zoomScale, weight: .semibold, design: .rounded))
                            .foregroundStyle(.green.opacity(0.9))
                        Text("todo.all_clear_hint")
                            .font(.system(size: 8 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.36))
                    }
                    .id("todo.focus.clear")
                    .transition(taskTransition)
                }
            }
            .animation(animation, value: snapshot.focusTaskID)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metrics: some View {
        HStack(spacing: 6 * zoomScale) {
            metric(snapshot.activeCount, title: "todo.active", color: accent)
            metric(snapshot.overdueCount, title: "todo.overdue", color: snapshot.overdueCount > 0 ? .red : .white)
            metric(snapshot.completedTodayCount, title: "todo.done_today", color: .green)
        }
    }

    private func metric(
        _ value: Int,
        title: LocalizedStringKey,
        color: Color
    ) -> some View {
        VStack(spacing: 2 * zoomScale) {
            Text("\(value)")
                .font(.system(size: 12 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(color.opacity(value > 0 ? 0.9 : 0.35))
                .contentTransition(.numericText(value: Double(value)))
            Text(title)
                .font(.system(size: 7 * zoomScale, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.32))
                .lineLimit(1)
        }
        .frame(width: 58 * zoomScale, height: 42 * zoomScale)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 7 * zoomScale))
        .animation(animation, value: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text("\(value)"))
    }
}

private struct TodoTaskCardStyle: ViewModifier {
    let hovered: Bool
    let completed: Bool
    let reduceMotion: Bool
    let zoomScale: CGFloat
    let accent: Color
    let animation: Animation?

    func body(content: Content) -> some View {
        content
            .padding(11 * zoomScale)
            .background(
                RoundedRectangle(cornerRadius: 9 * zoomScale)
                    .fill(Color.white.opacity(hovered ? 0.075 : completed ? 0.025 : 0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9 * zoomScale)
                    .stroke(hovered ? accent.opacity(0.28) : Color.white.opacity(0.07), lineWidth: zoomScale)
            )
            .clipShape(RoundedRectangle(cornerRadius: 9 * zoomScale))
            .scaleEffect(InteractiveMotionPolicy.scale(
                active: hovered && !reduceMotion,
                requestedScale: 1.006,
                animationsEnabled: Anim.enabled
            ), anchor: .leading)
            .offset(x: hovered && !reduceMotion && Anim.enabled ? 2 * zoomScale : 0)
            .shadow(color: hovered ? accent.opacity(0.1) : .clear, radius: 10 * zoomScale)
            .animation(animation, value: hovered)
            .animation(animation, value: completed)
    }
}

private struct TodoSectionGroup: Identifiable {
    let section: TodoTaskSection
    let tasks: [ClassGodTodo]
    var id: TodoTaskSection { section }
}

private enum TodoTaskSection: CaseIterable, Hashable {
    case overdue
    case today
    case upcoming
    case anytime
    case completed

    var title: LocalizedStringKey {
        switch self {
        case .overdue: "todo.overdue"
        case .today: "todo.today"
        case .upcoming: "todo.upcoming"
        case .anytime: "todo.anytime"
        case .completed: "todo.completed"
        }
    }

    var color: Color {
        switch self {
        case .overdue: .red
        case .today: .orange
        case .upcoming: .blue
        case .anytime: .white
        case .completed: .green
        }
    }
}

private struct TodoEditorSheet: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draft: ClassGodTodo
    @State private var hasDueDate: Bool
    @State private var tagsText: String
    @State private var newSubtaskTitle = ""
    @FocusState private var titleFocused: Bool

    let projects: [TodoProject]
    let zoomScale: CGFloat
    let accent: Color
    let onSave: (ClassGodTodo) -> Void
    let onCancel: () -> Void

    init(
        task: ClassGodTodo,
        projects: [TodoProject],
        zoomScale: CGFloat,
        accent: Color,
        onSave: @escaping (ClassGodTodo) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _draft = State(initialValue: task)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _tagsText = State(initialValue: task.tags.joined(separator: ", "))
        self.projects = projects
        self.zoomScale = zoomScale
        self.accent = accent
        self.onSave = onSave
        self.onCancel = onCancel
    }

    private var canSave: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var motionAnimation: Animation? {
        let duration = Anim.duration
        return duration > 0 ? .easeOut(duration: duration) : nil
    }
    private var fieldTransition: AnyTransition {
        guard !reduceMotion, Anim.enabled else { return .opacity }
        return .opacity.combined(with: .move(edge: .top))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2 * zoomScale) {
                    Text(draft.title.isEmpty ? "todo.new_task" : "todo.edit_task")
                        .font(.system(size: 17 * zoomScale, weight: .bold, design: .rounded))
                    Text("todo.editor_hint")
                        .font(.system(size: 9 * zoomScale, design: .rounded))
                        .foregroundStyle(.white.opacity(0.38))
                }
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.5))
                .accessibilityLabel(Text("button.close"))
            }
            .padding(16 * zoomScale)

            Divider().background(Color.white.opacity(0.08))

            ScrollView {
                VStack(alignment: .leading, spacing: 15 * zoomScale) {
                    editorField("todo.task_name") {
                        TextField("todo.task_name_placeholder", text: $draft.title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14 * zoomScale, weight: .semibold, design: .rounded))
                            .focused($titleFocused)
                    }

                    editorField("todo.notes") {
                        TextEditor(text: $draft.notes)
                            .font(.system(size: 11 * zoomScale, design: .rounded))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 90 * zoomScale)
                    }

                    editorField("todo.subtasks") {
                        VStack(spacing: 7 * zoomScale) {
                            ForEach($draft.subtasks) { $subtask in
                                HStack(spacing: 8 * zoomScale) {
                                    Button {
                                        let wasCompleted = subtask.isCompleted
                                        animated {
                                            subtask.completedAt = subtask.isCompleted ? nil : Date()
                                        }
                                        SoundEffectManager.shared.playButtonClick()
                                        if wasCompleted {
                                            HapticManager.shared.generic()
                                        } else {
                                            HapticManager.shared.success()
                                        }
                                    } label: {
                                        Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(subtask.isCompleted ? .green : accent)
                                            .contentTransition(.symbolEffect(.replace))
                                    }
                                    .buttonStyle(.plain)
                                    .animation(motionAnimation, value: subtask.isCompleted)
                                    .accessibilityLabel(Text(
                                        subtask.isCompleted ? "todo.restore_subtask" : "todo.complete_subtask"
                                    ))

                                    TextField("todo.subtask_placeholder", text: $subtask.title)
                                        .textFieldStyle(.plain)
                                        .strikethrough(subtask.isCompleted)
                                        .foregroundStyle(subtask.isCompleted ? .white.opacity(0.38) : .white)

                                    Button {
                                        animated {
                                            draft.subtasks.removeAll { $0.id == subtask.id }
                                        }
                                        SoundEffectManager.shared.playTabDeleted()
                                        HapticManager.shared.warning()
                                    } label: {
                                        Image(systemName: "xmark")
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.white.opacity(0.3))
                                    .accessibilityLabel(Text("todo.remove_subtask"))
                                }
                                .transition(fieldTransition)
                                .animation(motionAnimation, value: subtask.isCompleted)
                            }

                            HStack(spacing: 8 * zoomScale) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(accent)
                                TextField("todo.subtask_placeholder", text: $newSubtaskTitle)
                                    .textFieldStyle(.plain)
                                    .onSubmit(addSubtask)
                                Button("todo.add_subtask", action: addSubtask)
                                    .buttonStyle(.plain)
                                    .foregroundStyle(accent)
                                    .disabled(!canAddSubtask)
                            }
                        }
                        .animation(motionAnimation, value: draft.subtasks.map(\.id))
                    }

                    HStack(alignment: .top, spacing: 12 * zoomScale) {
                        editorField("todo.priority") {
                            Picker("todo.priority", selection: $draft.priority) {
                                ForEach(TodoPriority.allCases) { priority in
                                    Label(priority.title, systemImage: priority.icon)
                                        .tag(priority)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }

                        editorField("todo.project") {
                            Picker("todo.project", selection: $draft.projectID) {
                                Text("todo.inbox").tag(UUID?.none)
                                ForEach(projects) { project in
                                    Text(project.name).tag(Optional(project.id))
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }
                    }

                    editorField("todo.due_date") {
                        VStack(alignment: .leading, spacing: 8 * zoomScale) {
                            Toggle("todo.set_due_date", isOn: $hasDueDate)
                                .toggleStyle(.switch)
                                .onChange(of: hasDueDate) { _, enabled in
                                    animated {
                                        draft.dueDate = enabled
                                            ? (draft.dueDate ?? Calendar.current.startOfDay(for: Date()))
                                            : nil
                                    }
                                }
                            HStack(spacing: 6 * zoomScale) {
                                quickDateButton("todo.date.today", daysFromToday: 0)
                                quickDateButton("todo.date.tomorrow", daysFromToday: 1)
                                quickDateButton("todo.date.next_week", daysFromToday: 7)
                                if hasDueDate {
                                    Button("todo.date.clear") {
                                        animated {
                                            hasDueDate = false
                                            draft.dueDate = nil
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.white.opacity(0.42))
                                }
                            }
                            if hasDueDate {
                                DatePicker(
                                    "todo.due_date",
                                    selection: Binding(
                                        get: { draft.dueDate ?? Date() },
                                        set: { draft.dueDate = $0 }
                                    ),
                                    displayedComponents: [.date]
                                )
                                .labelsHidden()
                                .transition(fieldTransition)
                            }
                        }
                        .animation(motionAnimation, value: hasDueDate)
                    }

                    editorField("todo.recurrence") {
                        Picker("todo.recurrence", selection: $draft.recurrence) {
                            ForEach(TodoRecurrence.allCases) { recurrence in
                                Label(recurrence.title, systemImage: recurrence.icon)
                                    .tag(recurrence)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

                    editorField("todo.tags") {
                        TextField("todo.tags_placeholder", text: $tagsText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11 * zoomScale, design: .rounded))
                    }
                }
                .padding(16 * zoomScale)
            }

            Divider().background(Color.white.opacity(0.08))

            HStack {
                Button("button.cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Button("todo.save") { commit() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
                    .keyboardShortcut("s", modifiers: .command)
            }
            .padding(14 * zoomScale)
        }
        .frame(width: 520 * zoomScale, height: 570 * zoomScale)
        .background(Color(red: 0.025, green: 0.055, blue: 0.08))
        .tint(accent)
        .preferredColorScheme(.dark)
        .onAppear { titleFocused = true }
        .onExitCommand(perform: onCancel)
    }

    private func editorField<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7 * zoomScale) {
            Text(title)
                .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .textCase(.uppercase)
            content()
                .padding(10 * zoomScale)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.045))
                .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func commit() {
        guard canSave else { return }
        draft.tags = tagsText.split(separator: ",").map(String.init)
        if !hasDueDate { draft.dueDate = nil }
        onSave(draft)
    }

    private func animated<Result>(_ body: () -> Result) -> Result {
        guard let motionAnimation else { return body() }
        return withAnimation(motionAnimation, body)
    }

    private var canAddSubtask: Bool {
        !newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && draft.subtasks.count < TodoContentPolicy.maximumSubtaskCount
    }

    private func addSubtask() {
        let title = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canAddSubtask else { return }
        animated {
            draft.subtasks.append(TodoSubtask(title: title))
            newSubtaskTitle = ""
        }
        SoundEffectManager.shared.playButtonClick()
        HapticManager.shared.generic()
    }

    private func quickDateButton(
        _ title: LocalizedStringKey,
        daysFromToday: Int
    ) -> some View {
        Button(title) {
            animated {
                hasDueDate = true
                draft.dueDate = Calendar.current.date(
                    byAdding: .day,
                    value: daysFromToday,
                    to: Calendar.current.startOfDay(for: Date())
                )
            }
            SoundEffectManager.shared.playButtonClick()
            HapticManager.shared.generic()
        }
        .buttonStyle(.plain)
        .foregroundStyle(accent)
        .padding(.horizontal, 7 * zoomScale)
        .padding(.vertical, 4 * zoomScale)
        .background(accent.opacity(0.1))
        .clipShape(Capsule())
    }
}

private struct TodoProjectEditorSheet: View {
    @State private var name = ""
    @State private var color: TodoProjectColor = .blue
    @FocusState private var nameFocused: Bool

    let zoomScale: CGFloat
    let accent: Color
    let onSave: (String, TodoProjectColor) -> Void
    let onCancel: () -> Void

    private var motionAnimation: Animation? {
        let duration = Anim.duration
        return duration > 0 ? .easeOut(duration: duration) : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16 * zoomScale) {
            Text("todo.new_project")
                .font(.system(size: 17 * zoomScale, weight: .bold, design: .rounded))

            TextField("todo.project_name", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 13 * zoomScale, design: .rounded))
                .focused($nameFocused)
                .padding(10 * zoomScale)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))

            HStack(spacing: 10 * zoomScale) {
                ForEach(TodoProjectColor.allCases) { option in
                    Button {
                        guard color != option else { return }
                        if let motionAnimation {
                            withAnimation(motionAnimation) { color = option }
                        } else {
                            color = option
                        }
                        SoundEffectManager.shared.playButtonClick()
                        HapticManager.shared.generic()
                    } label: {
                        Circle()
                            .fill(option.color)
                            .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                            .scaleEffect(color == option ? 1.12 : 0.92)
                            .overlay(
                                Circle().stroke(.white, lineWidth: color == option ? 2 * zoomScale : 0)
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(motionAnimation, value: color)
                    .accessibilityLabel(option.title)
                    .accessibilityAddTraits(color == option ? .isSelected : [])
                }
            }

            HStack {
                Button("button.cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Button("todo.create") { onSave(name, color) }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(18 * zoomScale)
        .frame(width: 390 * zoomScale)
        .background(Color(red: 0.025, green: 0.055, blue: 0.08))
        .tint(accent)
        .preferredColorScheme(.dark)
        .onAppear { nameFocused = true }
        .onExitCommand(perform: onCancel)
    }
}

private extension TodoSmartList {
    var title: LocalizedStringKey {
        switch self {
        case .inbox: "todo.inbox"
        case .today: "todo.today"
        case .upcoming: "todo.upcoming"
        case .overdue: "todo.overdue"
        case .priority: "todo.priority"
        case .all: "todo.all"
        case .completed: "todo.completed"
        }
    }

    var icon: String {
        switch self {
        case .inbox: "tray.fill"
        case .today: "sun.max.fill"
        case .upcoming: "calendar"
        case .overdue: "exclamationmark.circle.fill"
        case .priority: "flag.fill"
        case .all: "checklist"
        case .completed: "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .inbox: .blue
        case .today: .orange
        case .upcoming: .cyan
        case .overdue: .red
        case .priority: .pink
        case .all: .white
        case .completed: .green
        }
    }
}

private extension TodoPriority {
    var title: LocalizedStringKey {
        switch self {
        case .none: "todo.priority.none"
        case .low: "todo.priority.low"
        case .medium: "todo.priority.medium"
        case .high: "todo.priority.high"
        case .urgent: "todo.priority.urgent"
        }
    }

    var icon: String { self == .none ? "minus" : "flag.fill" }

    var color: Color {
        switch self {
        case .none: .white.opacity(0.42)
        case .low: .blue
        case .medium: .yellow
        case .high: .orange
        case .urgent: .red
        }
    }
}

private extension TodoRecurrence {
    var title: LocalizedStringKey {
        switch self {
        case .none: "todo.recurrence.none"
        case .daily: "todo.recurrence.daily"
        case .weekdays: "todo.recurrence.weekdays"
        case .weekly: "todo.recurrence.weekly"
        case .monthly: "todo.recurrence.monthly"
        }
    }

    var icon: String { self == .none ? "minus" : "repeat" }
}

private extension TodoProjectColor {
    var title: Text {
        switch self {
        case .blue: Text("todo.color.blue")
        case .mint: Text("todo.color.mint")
        case .violet: Text("todo.color.violet")
        case .orange: Text("todo.color.orange")
        case .rose: Text("todo.color.rose")
        case .gray: Text("todo.color.gray")
        }
    }

    var color: Color {
        switch self {
        case .blue: Color(red: 0.28, green: 0.68, blue: 1)
        case .mint: Color(red: 0.28, green: 0.9, blue: 0.7)
        case .violet: Color(red: 0.68, green: 0.46, blue: 1)
        case .orange: Color(red: 1, green: 0.6, blue: 0.2)
        case .rose: Color(red: 1, green: 0.35, blue: 0.55)
        case .gray: Color.white.opacity(0.55)
        }
    }
}

#Preview {
    TodoView(onClose: {})
        .frame(width: 960, height: 680)
}
