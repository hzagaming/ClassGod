import SwiftUI

nonisolated enum ScheduleEditorLayoutPolicy {
    static let width: CGFloat = 560
    static let height: CGFloat = 500
}

struct ScheduleView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var service = ScheduleService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var selectedDay = ScheduleWeekday.current()
    @State private var editingEntry: ScheduleEntry?
    @State private var entryPendingDeletion: ScheduleEntry?

    let onClose: () -> Void

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    private var accent: Color { prefs.preferences.themeAccent.color }
    private var motionAnimation: Animation? {
        guard !reduceMotion else { return nil }
        let duration = Anim.duration
        return duration > 0 ? .easeOut(duration: duration) : nil
    }
    private var conflictingIDs: Set<UUID> {
        Set(ScheduleConflictPolicy.conflictingIDs(service.entries))
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            HStack(spacing: 0) {
                sidebar(now: context.date)
                Divider().background(Color.white.opacity(0.1))
                content(now: context.date)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.025, green: 0.1, blue: 0.15), .black],
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
        .sheet(item: $editingEntry) { entry in
            ScheduleEditorSheet(
                entry: entry,
                existingEntries: service.entries,
                zoomScale: zoomScale,
                accent: accent,
                onSave: save,
                onCancel: { editingEntry = nil }
            )
        }
        .confirmationDialog(
            "schedule.delete_title",
            isPresented: Binding(
                get: { entryPendingDeletion != nil },
                set: { if !$0 { entryPendingDeletion = nil } }
            )
        ) {
            Button("schedule.delete", role: .destructive) { deletePendingEntry() }
            Button("button.cancel", role: .cancel) { entryPendingDeletion = nil }
        } message: {
            Text("schedule.delete_message")
        }
        .onExitCommand(perform: onClose)
    }

    private func sidebar(now: Date) -> some View {
        let today = ScheduleWeekday.current(on: now)
        return VStack(alignment: .leading, spacing: 13 * zoomScale) {
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

                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(accent)
                Text("schedule.title")
                    .font(.system(size: 14 * zoomScale, weight: .bold, design: .rounded))
            }

            Text("schedule.week")
                .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))

            VStack(spacing: 4 * zoomScale) {
                ForEach(ScheduleWeekday.allCases) { weekday in
                    dayButton(weekday, today: today)
                }
            }

            Spacer(minLength: 8 * zoomScale)
            weeklySummary
        }
        .padding(14 * zoomScale)
        .frame(width: 215 * zoomScale)
        .background(Color.black.opacity(0.5))
    }

    private func dayButton(
        _ weekday: ScheduleWeekday,
        today: ScheduleWeekday
    ) -> some View {
        let selected = selectedDay == weekday
        let entries = service.entries(for: weekday)
        let hasConflict = entries.contains { conflictingIDs.contains($0.id) }
        return Button {
            guard !selected else { return }
            animated { selectedDay = weekday }
            SoundEffectManager.shared.playButtonClick()
            HapticManager.shared.generic()
        } label: {
            HStack(spacing: 8 * zoomScale) {
                Circle()
                    .fill(weekday == today ? accent : Color.white.opacity(0.18))
                    .frame(width: 6 * zoomScale, height: 6 * zoomScale)
                Text(weekday.title)
                    .font(.system(
                        size: 10 * zoomScale,
                        weight: selected ? .semibold : .regular,
                        design: .rounded
                    ))
                if hasConflict {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 7 * zoomScale))
                        .foregroundStyle(.red)
                }
                Spacer(minLength: 4 * zoomScale)
                Text("\(entries.count)")
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.38))
                    .contentTransition(.numericText(value: Double(entries.count)))
            }
            .foregroundStyle(selected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 9 * zoomScale)
            .frame(height: 32 * zoomScale)
            .background(selected ? accent.opacity(0.18) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 7 * zoomScale)
                    .stroke(selected ? accent.opacity(0.45) : .clear, lineWidth: zoomScale)
            )
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(accent)
                    .frame(width: 2 * zoomScale, height: 17 * zoomScale)
                    .opacity(selected ? 1 : 0)
            }
            .clipShape(RoundedRectangle(cornerRadius: 7 * zoomScale))
        }
        .buttonStyle(.plain)
        .animation(motionAnimation, value: selected)
        .animation(motionAnimation, value: entries.count)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var weeklySummary: some View {
        let enabledCount = service.entries.filter(\.isEnabled).count
        return VStack(alignment: .leading, spacing: 7 * zoomScale) {
            Text("schedule.weekly_signal")
                .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.38))
            HStack(spacing: 6 * zoomScale) {
                summaryMetric(
                    value: service.entries.count,
                    key: "schedule.total",
                    color: accent
                )
                summaryMetric(
                    value: enabledCount,
                    key: "schedule.enabled",
                    color: .green
                )
                summaryMetric(
                    value: conflictingIDs.count,
                    key: "schedule.conflicts",
                    color: conflictingIDs.isEmpty ? .white : .red
                )
            }
        }
        .padding(9 * zoomScale)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
    }

    private func summaryMetric(
        value: Int,
        key: LocalizedStringKey,
        color: Color
    ) -> some View {
        VStack(spacing: 2 * zoomScale) {
            Text("\(value)")
                .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(color.opacity(value > 0 ? 0.9 : 0.35))
                .contentTransition(.numericText(value: Double(value)))
            Text(key)
                .font(.system(size: 6.5 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(key))
        .accessibilityValue(Text("\(value)"))
    }

    private func content(now: Date) -> some View {
        VStack(spacing: 0) {
            contentHeader(now: now)
            Divider().background(Color.white.opacity(0.08))
            liveDashboard(now: now)
            Divider().background(Color.white.opacity(0.08))
            ScheduleTimelineView(
                entries: service.entries(for: selectedDay),
                conflictingIDs: conflictingIDs,
                selectedDay: selectedDay,
                now: now,
                zoomScale: zoomScale,
                accent: accent,
                animation: motionAnimation,
                reduceMotion: reduceMotion,
                onEdit: openEditor,
                onToggle: toggle,
                onDelete: requestDeletion
            )
        }
        .overlay {
            Button {
                openEditor(draft(for: selectedDay, now: now))
            } label: {
                EmptyView()
            }
            .keyboardShortcut("n", modifiers: .command)
            .frame(width: 0, height: 0)
            .opacity(0)
        }
    }

    private func contentHeader(now: Date) -> some View {
        let entries = service.entries(for: selectedDay)
        let isToday = selectedDay == ScheduleWeekday.current(on: now)
        return HStack(spacing: 12 * zoomScale) {
            VStack(alignment: .leading, spacing: 3 * zoomScale) {
                HStack(spacing: 7 * zoomScale) {
                    Text(selectedDay.title)
                        .font(.system(size: 20 * zoomScale, weight: .bold, design: .rounded))
                        .id(selectedDay)
                        .transition(panelTransition)
                    if isToday {
                        Text("schedule.today")
                            .font(.system(size: 7 * zoomScale, weight: .bold, design: .monospaced))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6 * zoomScale)
                            .padding(.vertical, 3 * zoomScale)
                            .background(accent)
                            .clipShape(Capsule())
                    }
                }
                Text(String(format: String(localized: "schedule.entry_count"), entries.count))
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.38))
                    .contentTransition(.numericText(value: Double(entries.count)))
            }
            .animation(motionAnimation, value: selectedDay)
            Spacer()
            Button {
                openEditor(draft(for: selectedDay, now: now))
            } label: {
                Label("schedule.new_entry", systemImage: "plus")
                    .font(.system(size: 10 * zoomScale, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 11 * zoomScale)
                    .frame(height: 31 * zoomScale)
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

    private func liveDashboard(now: Date) -> some View {
        let today = ScheduleWeekday.current(on: now)
        let minute = ScheduleTimePolicy.minute(of: now)
        let state = ScheduleLivePolicy.state(
            entries: service.entries,
            weekday: today,
            minute: minute
        )
        let dayEntries = service.entries(for: selectedDay)
        let enabledCount = dayEntries.filter(\.isEnabled).count
        let scheduledMinutes = dayEntries.filter(\.isEnabled).reduce(0) { $0 + $1.durationMinutes }
        let dayConflicts = dayEntries.filter { conflictingIDs.contains($0.id) }.count
        return HStack(spacing: 10 * zoomScale) {
            liveStatusCard(state: state, today: today)
            dashboardMetric(
                value: enabledCount,
                label: "schedule.enabled",
                icon: "bolt.fill",
                color: .green
            )
            dashboardMetric(
                value: scheduledMinutes,
                label: "schedule.minutes",
                icon: "clock.fill",
                color: accent
            )
            dashboardMetric(
                value: dayConflicts,
                label: "schedule.conflicts",
                icon: "exclamationmark.triangle.fill",
                color: dayConflicts > 0 ? .red : .white
            )
        }
        .padding(.horizontal, 16 * zoomScale)
        .padding(.vertical, 9 * zoomScale)
        .animation(motionAnimation, value: state)
    }

    private func liveStatusCard(
        state: ScheduleLiveState,
        today: ScheduleWeekday
    ) -> some View {
        let detail: (icon: String, label: LocalizedStringKey, title: String, caption: String, color: Color) = {
            switch state {
            case .active(let id, let remaining):
                let entry = service.entries.first { $0.id == id }
                return (
                    "waveform.path.ecg",
                    "schedule.active_now",
                    entry?.title ?? String(localized: "schedule.unknown"),
                    String(format: String(localized: "schedule.remaining"), remaining),
                    .green
                )
            case .upcoming(let id, let minutes):
                let entry = service.entries.first { $0.id == id }
                return (
                    "arrow.up.right",
                    "schedule.up_next",
                    entry?.title ?? String(localized: "schedule.unknown"),
                    String(format: String(localized: "schedule.starts_in"), minutes),
                    accent
                )
            case .clear:
                return (
                    "checkmark",
                    "schedule.free_now",
                    String(localized: "schedule.clear"),
                    String(localized: "schedule.clear_hint"),
                    .white
                )
            }
        }()
        return HStack(spacing: 10 * zoomScale) {
            Image(systemName: detail.icon)
                .font(.system(size: 15 * zoomScale, weight: .semibold))
                .foregroundStyle(detail.color)
                .frame(width: 34 * zoomScale, height: 34 * zoomScale)
                .background(detail.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
                .contentTransition(.symbolEffect(.replace))
            VStack(alignment: .leading, spacing: 2 * zoomScale) {
                HStack(spacing: 5 * zoomScale) {
                    Text(detail.label)
                    Text("·")
                    Text(today.shortTitle)
                }
                .font(.system(size: 7 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(detail.color.opacity(0.7))
                Text(detail.title)
                    .font(.system(size: 11 * zoomScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                Text(detail.caption)
                    .font(.system(size: 7.5 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.36))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10 * zoomScale)
        .frame(maxWidth: .infinity, minHeight: 52 * zoomScale)
        .background(
            LinearGradient(
                colors: [detail.color.opacity(0.1), Color.white.opacity(0.025)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9 * zoomScale)
                .stroke(detail.color.opacity(0.2), lineWidth: zoomScale)
        )
        .clipShape(RoundedRectangle(cornerRadius: 9 * zoomScale))
        .accessibilityElement(children: .combine)
    }

    private func dashboardMetric(
        value: Int,
        label: LocalizedStringKey,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 3 * zoomScale) {
            Image(systemName: icon)
                .font(.system(size: 8 * zoomScale, weight: .bold))
            Text("\(value)")
                .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                .contentTransition(.numericText(value: Double(value)))
            Text(label)
                .font(.system(size: 6.5 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.32))
                .lineLimit(1)
        }
        .foregroundStyle(color.opacity(value > 0 ? 0.9 : 0.38))
        .frame(width: 64 * zoomScale, height: 52 * zoomScale)
        .background(Color.black.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text("\(value)"))
    }

    private var panelTransition: AnyTransition {
        guard !reduceMotion, motionAnimation != nil else { return .opacity }
        return .opacity.combined(with: .move(edge: .bottom))
    }

    private func draft(for weekday: ScheduleWeekday, now: Date) -> ScheduleEntry {
        let isToday = weekday == ScheduleWeekday.current(on: now)
        let currentMinute = ScheduleTimePolicy.minute(of: now)
        let rounded = min(1_379, ((currentMinute + 29) / 30) * 30)
        let start = isToday ? rounded : 540
        return ScheduleEntry(
            title: "",
            weekday: weekday,
            startMinute: start,
            endMinute: min(1_439, start + 60),
            color: .cyan
        )
    }

    private func openEditor(_ entry: ScheduleEntry) {
        editingEntry = entry
        SoundEffectManager.shared.playButtonClick()
        HapticManager.shared.generic()
    }

    private func save(_ entry: ScheduleEntry) {
        guard animated({ service.save(entry) }) else {
            ErrorToastManager.shared.show(
                title: String(localized: "schedule.title"),
                message: String(localized: "schedule.limit_reached")
            )
            HapticManager.shared.warning()
            return
        }
        editingEntry = nil
        animated { selectedDay = entry.weekday }
        SoundEffectManager.shared.playTabSaved()
        HapticManager.shared.success()
    }

    private func toggle(_ entry: ScheduleEntry) {
        guard animated({ service.toggleEnabled(entry.id) }) else { return }
        SoundEffectManager.shared.playButtonClick()
        HapticManager.shared.generic()
    }

    private func requestDeletion(_ entry: ScheduleEntry) {
        if prefs.preferences.confirmBeforeDelete {
            entryPendingDeletion = entry
        } else {
            delete(entry)
        }
    }

    private func deletePendingEntry() {
        defer { entryPendingDeletion = nil }
        guard let entry = entryPendingDeletion else { return }
        delete(entry)
    }

    private func delete(_ entry: ScheduleEntry) {
        guard animated({ service.delete(entry.id) }) else { return }
        SoundEffectManager.shared.playTabDeleted()
        HapticManager.shared.warning()
    }

    private func animated<Result>(_ body: () -> Result) -> Result {
        guard let motionAnimation else { return body() }
        return withAnimation(motionAnimation, body)
    }
}

private struct ScheduleTimelineView: View {
    let entries: [ScheduleEntry]
    let conflictingIDs: Set<UUID>
    let selectedDay: ScheduleWeekday
    let now: Date
    let zoomScale: CGFloat
    let accent: Color
    let animation: Animation?
    let reduceMotion: Bool
    let onEdit: (ScheduleEntry) -> Void
    let onToggle: (ScheduleEntry) -> Void
    let onDelete: (ScheduleEntry) -> Void

    private var range: ScheduleTimelineRange {
        ScheduleTimelinePolicy.visibleRange(entries: entries)
    }
    private var hourHeight: CGFloat { 72 * zoomScale }
    private var timeColumnWidth: CGFloat { 58 * zoomScale }
    private var totalHeight: CGFloat {
        CGFloat(range.endMinute - range.startMinute) / 60 * hourHeight
    }

    var body: some View {
        ScrollView(showsIndicators: true) {
            GeometryReader { proxy in
                let timelineWidth = max(120 * zoomScale, proxy.size.width - timeColumnWidth - 8 * zoomScale)
                ZStack(alignment: .topLeading) {
                    hourGrid(width: proxy.size.width)
                    entryCards(timelineWidth: timelineWidth)
                    currentTimeLine(width: proxy.size.width)
                }
            }
            .frame(height: totalHeight)
            .padding(.horizontal, 14 * zoomScale)
            .padding(.vertical, 10 * zoomScale)
        }
        .overlay {
            if entries.isEmpty {
                VStack(spacing: 9 * zoomScale) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 38 * zoomScale, weight: .light))
                        .foregroundStyle(accent.opacity(0.65))
                    Text("schedule.no_entries")
                        .font(.system(size: 14 * zoomScale, weight: .semibold, design: .rounded))
                    Text("schedule.no_entries_hint")
                        .font(.system(size: 9 * zoomScale, design: .rounded))
                        .foregroundStyle(.white.opacity(0.36))
                }
                .transition(.opacity)
            }
        }
        .animation(animation, value: entries)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func hourGrid(width: CGFloat) -> some View {
        ForEach(Array(stride(
            from: range.startMinute,
            through: range.endMinute,
            by: 60
        )), id: \.self) { minute in
            HStack(spacing: 8 * zoomScale) {
                Text(ScheduleTimePolicy.date(for: minute), format: .dateTime.hour())
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.28))
                    .frame(width: timeColumnWidth - 8 * zoomScale, alignment: .trailing)
                Rectangle()
                    .fill(Color.white.opacity(minute % 120 == 0 ? 0.1 : 0.055))
                    .frame(width: max(0, width - timeColumnWidth), height: zoomScale)
            }
            .offset(y: yPosition(for: minute))
        }
    }

    @ViewBuilder
    private func entryCards(timelineWidth: CGFloat) -> some View {
        let entryMap = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        ForEach(ScheduleLayoutPolicy.layouts(for: entries), id: \.id) { layout in
            if let entry = entryMap[layout.id] {
                let geometry = ScheduleTimelineGeometryPolicy.lanes(
                    timelineWidth: timelineWidth,
                    laneCount: layout.laneCount,
                    preferredGap: 6 * zoomScale
                )
                let height = max(
                    14 * zoomScale,
                    CGFloat(entry.durationMinutes) / 60 * hourHeight - 4 * zoomScale
                )
                ScheduleEntryCard(
                    entry: entry,
                    hasConflict: conflictingIDs.contains(entry.id),
                    zoomScale: zoomScale,
                    accent: accent,
                    animation: animation,
                    reduceMotion: reduceMotion,
                    onEdit: { onEdit(entry) },
                    onToggle: { onToggle(entry) },
                    onDelete: { onDelete(entry) }
                )
                .frame(width: geometry.cardWidth, height: height)
                .offset(
                    x: timeColumnWidth
                        + CGFloat(layout.lane) * (geometry.cardWidth + geometry.gap),
                    y: yPosition(for: entry.startMinute) + 2 * zoomScale
                )
                .transition(.opacity.combined(with: .scale(scale: reduceMotion ? 1 : 0.97)))
            }
        }
    }

    @ViewBuilder
    private func currentTimeLine(width: CGFloat) -> some View {
        let today = ScheduleWeekday.current(on: now)
        let minute = ScheduleTimePolicy.minute(of: now)
        if selectedDay == today,
           minute >= range.startMinute,
           minute <= range.endMinute {
            HStack(spacing: 0) {
                Circle()
                    .fill(.red)
                    .frame(width: 7 * zoomScale, height: 7 * zoomScale)
                Rectangle()
                    .fill(.red.opacity(0.72))
                    .frame(height: zoomScale)
            }
            .frame(width: max(0, width - timeColumnWidth + 4 * zoomScale))
            .offset(x: timeColumnWidth - 4 * zoomScale, y: yPosition(for: minute))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .zIndex(10)
        }
    }

    private func yPosition(for minute: Int) -> CGFloat {
        CGFloat(minute - range.startMinute) / 60 * hourHeight
    }
}

private struct ScheduleEntryCard: View {
    @State private var hovered = false

    let entry: ScheduleEntry
    let hasConflict: Bool
    let zoomScale: CGFloat
    let accent: Color
    let animation: Animation?
    let reduceMotion: Bool
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    private var color: Color { entry.color.color }
    private var isCompact: Bool { entry.durationMinutes < 30 }

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 7 * zoomScale) {
                Capsule()
                    .fill(hasConflict ? .red : color)
                    .frame(width: 3 * zoomScale)
                VStack(alignment: .leading, spacing: isCompact ? 0 : 3 * zoomScale) {
                    HStack(spacing: 5 * zoomScale) {
                        Text(entry.title)
                            .font(.system(size: 10 * zoomScale, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(entry.isEnabled ? 0.92 : 0.38))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if hasConflict {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 7 * zoomScale))
                                .foregroundStyle(.red)
                        }
                        if !entry.isEnabled {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 8 * zoomScale))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                    if !isCompact {
                        Text(timeRange)
                            .font(.system(size: 7.5 * zoomScale, design: .monospaced))
                            .foregroundStyle(color.opacity(entry.isEnabled ? 0.75 : 0.35))
                            .lineLimit(1)
                    }
                    if entry.durationMinutes >= 45, !entry.location.isEmpty {
                        Label(entry.location, systemImage: "mappin.and.ellipse")
                            .font(.system(size: 7 * zoomScale, design: .rounded))
                            .foregroundStyle(.white.opacity(0.34))
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, isCompact ? 0 : 5 * zoomScale)
                .padding(.trailing, 7 * zoomScale)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [color.opacity(entry.isEnabled ? 0.18 : 0.06), Color.black.opacity(0.32)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7 * zoomScale)
                    .stroke(
                        hasConflict
                            ? Color.red.opacity(0.7)
                            : hovered ? color.opacity(0.55) : Color.white.opacity(0.09),
                        lineWidth: zoomScale
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 7 * zoomScale))
            .scaleEffect(InteractiveMotionPolicy.scale(
                active: hovered && !reduceMotion,
                requestedScale: 1.008,
                animationsEnabled: Anim.enabled
            ))
            .shadow(color: hovered ? color.opacity(0.16) : .clear, radius: 9 * zoomScale)
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(animation, value: hovered)
        .animation(animation, value: entry.isEnabled)
        .contextMenu {
            Button("schedule.edit", action: onEdit)
            Button(action: onToggle) {
                Text(entry.isEnabled ? String(localized: "schedule.disable") : String(localized: "schedule.enable"))
            }
            Divider()
            Button("schedule.delete", role: .destructive, action: onDelete)
        }
        .accessibilityLabel(Text(entry.title))
        .accessibilityValue(Text(accessibilityValue))
        .accessibilityHint(Text("schedule.edit_hint"))
    }

    private var timeRange: String {
        let start = ScheduleTimePolicy.date(for: entry.startMinute)
            .formatted(date: .omitted, time: .shortened)
        let end = ScheduleTimePolicy.date(for: entry.endMinute)
            .formatted(date: .omitted, time: .shortened)
        return "\(start) – \(end)"
    }

    private var accessibilityValue: String {
        var values = [
            timeRange,
            entry.isEnabled
                ? String(localized: "schedule.enabled")
                : String(localized: "schedule.disabled"),
        ]
        if hasConflict {
            values.append(String(localized: "schedule.conflict"))
        }
        if !entry.location.isEmpty {
            values.append(entry.location)
        }
        return ListFormatter.localizedString(byJoining: values)
    }
}

private struct ScheduleEditorSheet: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draft: ScheduleEntry
    @FocusState private var titleFocused: Bool

    let isNewEntry: Bool
    let existingEntries: [ScheduleEntry]
    let zoomScale: CGFloat
    let accent: Color
    let onSave: (ScheduleEntry) -> Void
    let onCancel: () -> Void

    init(
        entry: ScheduleEntry,
        existingEntries: [ScheduleEntry],
        zoomScale: CGFloat,
        accent: Color,
        onSave: @escaping (ScheduleEntry) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _draft = State(initialValue: entry)
        isNewEntry = !existingEntries.contains { $0.id == entry.id }
        self.existingEntries = existingEntries
        self.zoomScale = zoomScale
        self.accent = accent
        self.onSave = onSave
        self.onCancel = onCancel
    }

    private var motionAnimation: Animation? {
        guard !reduceMotion else { return nil }
        let duration = Anim.duration
        return duration > 0 ? .easeOut(duration: duration) : nil
    }
    private var canSave: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && draft.durationMinutes >= ScheduleContentPolicy.minimumDurationMinutes
            && draft.endMinute <= 1_439
    }
    private var hasConflict: Bool {
        guard canSave else { return false }
        let candidates = existingEntries.filter { $0.id != draft.id } + [draft]
        return ScheduleConflictPolicy.conflictingIDs(candidates).contains(draft.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2 * zoomScale) {
                    Text(isNewEntry ? String(localized: "schedule.new_entry") : String(localized: "schedule.edit"))
                        .font(.system(size: 17 * zoomScale, weight: .bold, design: .rounded))
                    Text("schedule.editor_hint")
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
                VStack(alignment: .leading, spacing: 14 * zoomScale) {
                    editorField("schedule.name") {
                        TextField("schedule.name_placeholder", text: $draft.title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13 * zoomScale, weight: .semibold, design: .rounded))
                            .focused($titleFocused)
                    }

                    editorField("schedule.weekday") {
                        Picker("schedule.weekday", selection: $draft.weekday) {
                            ForEach(ScheduleWeekday.allCases) { weekday in
                                Text(weekday.shortTitle).tag(weekday)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .onChange(of: draft.weekday) { oldValue, newValue in
                            guard oldValue != newValue else { return }
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                        }
                    }

                    HStack(alignment: .top, spacing: 12 * zoomScale) {
                        editorField("schedule.start_time") {
                            DatePicker(
                                "schedule.start_time",
                                selection: startBinding,
                                in: ScheduleTimePolicy.date(for: 0)...ScheduleTimePolicy.date(
                                    for: 1_439 - ScheduleContentPolicy.minimumDurationMinutes
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                        editorField("schedule.end_time") {
                            DatePicker(
                                "schedule.end_time",
                                selection: endBinding,
                                in: ScheduleTimePolicy.date(
                                    for: draft.startMinute + ScheduleContentPolicy.minimumDurationMinutes
                                )...ScheduleTimePolicy.date(for: 1_439),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                    }

                    HStack(spacing: 7 * zoomScale) {
                        Label(
                            String(
                                format: String(localized: "schedule.duration_minutes"),
                                max(0, draft.durationMinutes)
                            ),
                            systemImage: "hourglass"
                        )
                        .font(.system(size: 8 * zoomScale, design: .monospaced))
                        .foregroundStyle(canSave ? accent : .red)
                        Spacer()
                        quickDurationButton(minutes: 30)
                        quickDurationButton(minutes: 60)
                        quickDurationButton(minutes: 90)
                    }

                    if !canSave {
                        warningRow("schedule.invalid_time", color: .red)
                            .transition(fieldTransition)
                    } else if hasConflict {
                        warningRow("schedule.conflict_hint", color: .red)
                            .transition(fieldTransition)
                    }

                    editorField("schedule.location") {
                        TextField("schedule.location_placeholder", text: $draft.location)
                            .textFieldStyle(.plain)
                    }

                    editorField("schedule.notes") {
                        TextEditor(text: $draft.notes)
                            .font(.system(size: 10 * zoomScale, design: .rounded))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 80 * zoomScale)
                    }

                    editorField("schedule.color") {
                        HStack(spacing: 12 * zoomScale) {
                            ForEach(ScheduleEntryColor.allCases) { color in
                                Button {
                                    guard draft.color != color else { return }
                                    animated { draft.color = color }
                                    SoundEffectManager.shared.playButtonClick()
                                    HapticManager.shared.generic()
                                } label: {
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                                        .scaleEffect(draft.color == color ? 1.13 : 0.9)
                                        .overlay(
                                            Circle().stroke(
                                                .white,
                                                lineWidth: draft.color == color ? 2 * zoomScale : 0
                                            )
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(color.title)
                                .accessibilityAddTraits(draft.color == color ? .isSelected : [])
                            }
                        }
                        .animation(motionAnimation, value: draft.color)
                    }

                    Toggle("schedule.enabled", isOn: $draft.isEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: draft.isEnabled) { oldValue, newValue in
                            guard oldValue != newValue else { return }
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                        }
                }
                .animation(motionAnimation, value: canSave)
                .animation(motionAnimation, value: hasConflict)
                .padding(16 * zoomScale)
            }

            Divider().background(Color.white.opacity(0.08))

            HStack {
                Button("button.cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Button("schedule.save") { onSave(draft) }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
                    .keyboardShortcut("s", modifiers: .command)
            }
            .padding(14 * zoomScale)
        }
        .frame(
            width: ScheduleEditorLayoutPolicy.width * zoomScale,
            height: ScheduleEditorLayoutPolicy.height * zoomScale
        )
        .background(Color(red: 0.025, green: 0.06, blue: 0.085))
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

    private func warningRow(_ key: LocalizedStringKey, color: Color) -> some View {
        Label(key, systemImage: "exclamationmark.triangle.fill")
            .font(.system(size: 8 * zoomScale, weight: .medium, design: .rounded))
            .foregroundStyle(color.opacity(0.85))
            .padding(9 * zoomScale)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 7 * zoomScale))
    }

    private var startBinding: Binding<Date> {
        Binding(
            get: { ScheduleTimePolicy.date(for: draft.startMinute) },
            set: { date in
                let duration = max(ScheduleContentPolicy.minimumDurationMinutes, draft.durationMinutes)
                let start = min(
                    1_439 - ScheduleContentPolicy.minimumDurationMinutes,
                    ScheduleTimePolicy.minute(of: date)
                )
                animated {
                    draft.startMinute = start
                    draft.endMinute = min(1_439, start + duration)
                }
            }
        )
    }

    private var endBinding: Binding<Date> {
        Binding(
            get: { ScheduleTimePolicy.date(for: draft.endMinute) },
            set: { date in
                animated {
                    draft.endMinute = min(
                        1_439,
                        max(
                            draft.startMinute + ScheduleContentPolicy.minimumDurationMinutes,
                            ScheduleTimePolicy.minute(of: date)
                        )
                    )
                }
            }
        )
    }

    private func quickDurationButton(minutes: Int) -> some View {
        Button {
            let newEndMinute = ScheduleTimePolicy.endMinute(
                startMinute: draft.startMinute,
                durationMinutes: minutes
            )
            guard newEndMinute != draft.endMinute else { return }
            animated {
                draft.endMinute = newEndMinute
            }
            SoundEffectManager.shared.playButtonClick()
            HapticManager.shared.generic()
        } label: {
            Text(String(
                format: String(localized: "schedule.duration_short"),
                minutes
            ))
        }
        .buttonStyle(.plain)
        .font(.system(size: 8 * zoomScale, weight: .semibold, design: .monospaced))
        .foregroundStyle(accent)
        .padding(.horizontal, 7 * zoomScale)
        .padding(.vertical, 4 * zoomScale)
        .background(accent.opacity(0.1))
        .clipShape(Capsule())
    }

    private var fieldTransition: AnyTransition {
        guard !reduceMotion, motionAnimation != nil else { return .opacity }
        return .opacity.combined(with: .move(edge: .top))
    }

    private func animated<Result>(_ body: () -> Result) -> Result {
        guard let motionAnimation else { return body() }
        return withAnimation(motionAnimation, body)
    }
}

private extension ScheduleWeekday {
    var title: LocalizedStringKey {
        switch self {
        case .monday: "schedule.monday"
        case .tuesday: "schedule.tuesday"
        case .wednesday: "schedule.wednesday"
        case .thursday: "schedule.thursday"
        case .friday: "schedule.friday"
        case .saturday: "schedule.saturday"
        case .sunday: "schedule.sunday"
        }
    }

    var shortTitle: LocalizedStringKey {
        switch self {
        case .monday: "schedule.mon"
        case .tuesday: "schedule.tue"
        case .wednesday: "schedule.wed"
        case .thursday: "schedule.thu"
        case .friday: "schedule.fri"
        case .saturday: "schedule.sat"
        case .sunday: "schedule.sun"
        }
    }
}

private extension ScheduleEntryColor {
    var title: Text {
        switch self {
        case .cyan: Text("schedule.color.cyan")
        case .blue: Text("schedule.color.blue")
        case .mint: Text("schedule.color.mint")
        case .violet: Text("schedule.color.violet")
        case .orange: Text("schedule.color.orange")
        case .rose: Text("schedule.color.rose")
        }
    }

    var color: Color {
        switch self {
        case .cyan: Color(red: 0.25, green: 0.85, blue: 1)
        case .blue: Color(red: 0.3, green: 0.58, blue: 1)
        case .mint: Color(red: 0.3, green: 0.9, blue: 0.68)
        case .violet: Color(red: 0.68, green: 0.46, blue: 1)
        case .orange: Color(red: 1, green: 0.58, blue: 0.2)
        case .rose: Color(red: 1, green: 0.34, blue: 0.56)
        }
    }
}

#Preview {
    ScheduleView(onClose: {})
        .frame(width: 980, height: 700)
}
