import SwiftUI
import AppKit
import ApplicationServices
import UniformTypeIdentifiers

struct ClipoView: View {
    private enum Section: String, CaseIterable, Identifiable {
        case history
        case slots
        case insights
        case settings

        var id: String { rawValue }
        var title: LocalizedStringKey {
            switch self {
            case .history: "clipo.section.history"
            case .slots: "clipo.section.slots"
            case .insights: "clipo.section.insights"
            case .settings: "clipo.section.settings"
            }
        }
        var icon: String {
            switch self {
            case .history: "clock.arrow.circlepath"
            case .slots: "square.grid.3x3"
            case .insights: "chart.bar.xaxis"
            case .settings: "slider.horizontal.3"
            }
        }
    }

    @ObservedObject private var service = ClipoService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var section = Section.history
    @State private var searchText = ""
    @State private var selectedType: ClipoType?
    @State private var newSensitiveBundle = ""
    @State private var hasAccessibility = AXIsProcessTrusted()
    @State private var confirmClearHistory = false
    @State private var confirmReset = false
    @State private var pendingImportURL: URL?
    @State private var recordingShortcut: ClipoShortcutAction?
    let onClose: () -> Void

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    private var accent: Color { prefs.preferences.themeAccent.color }
    private var filteredHistory: [ClipoItem] {
        service.filteredHistory(query: searchText, type: selectedType)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            sectionBar
            Group {
                switch section {
                case .history: historySection
                case .slots: slotsSection
                case .insights: insightsSection
                case .settings: settingsSection
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black)
        .tint(accent)
        .preferredColorScheme(.dark)
        .overlay(
            RoundedRectangle(cornerRadius: 12 * zoomScale)
                .stroke(Color.white.opacity(0.12), lineWidth: zoomScale)
                .allowsHitTesting(false)
        )
        .onAppear {
            service.start()
            hasAccessibility = AXIsProcessTrusted()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            hasAccessibility = AXIsProcessTrusted()
        }
        .confirmationDialog("clipo.confirm.clear_title", isPresented: $confirmClearHistory) {
            Button("clipo.clear_history", role: .destructive) {
                service.clearHistory()
            }
            Button("button.cancel", role: .cancel) {}
        } message: {
            Text("clipo.confirm.clear_message")
        }
        .confirmationDialog("clipo.confirm.reset_title", isPresented: $confirmReset) {
            Button("clipo.reset", role: .destructive) {
                service.resetAll()
            }
            Button("button.cancel", role: .cancel) {}
        } message: {
            Text("clipo.confirm.reset_message")
        }
        .confirmationDialog("clipo.confirm.import_title", isPresented: Binding(
            get: { pendingImportURL != nil },
            set: { if !$0 { pendingImportURL = nil } }
        )) {
            Button("clipo.import", role: .destructive) {
                guard let url = pendingImportURL else { return }
                pendingImportURL = nil
                importStore(from: url)
            }
            Button("button.cancel", role: .cancel) { pendingImportURL = nil }
        } message: {
            Text("clipo.confirm.import_message")
        }
    }

    private var header: some View {
        HStack(spacing: 10 * zoomScale) {
            Button(action: onClose) {
                Image(systemName: "minus")
                    .font(.system(size: 12 * zoomScale, weight: .bold))
                    .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                    .background(Color(white: 0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.65))
            .accessibilityLabel(Text("button.close"))

            Image(systemName: "clipboard.fill")
                .foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 1 * zoomScale) {
                Text("Clipo")
                    .font(.system(size: 14 * zoomScale, weight: .bold, design: .monospaced))
                Text("clipo.subtitle")
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            Label(
                service.settings.monitorClipboard ? "clipo.monitoring" : "clipo.paused",
                systemImage: service.settings.monitorClipboard ? "record.circle" : "pause.circle"
            )
            .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
            .foregroundStyle(service.settings.monitorClipboard ? .green : .orange)

            Text(service.settings.openShortcut.displayString)
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
                .padding(.horizontal, 7 * zoomScale)
                .padding(.vertical, 4 * zoomScale)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 5 * zoomScale))
        }
        .padding(.horizontal, 14 * zoomScale)
        .padding(.vertical, 10 * zoomScale)
        .background(Color(white: 0.025))
    }

    private var sectionBar: some View {
        HStack(spacing: 6 * zoomScale) {
            ForEach(Section.allCases) { item in
                Button {
                    guard section != item else { return }
                    SoundEffectManager.shared.playButtonClick()
                    section = item
                } label: {
                    Label(item.title, systemImage: item.icon)
                        .font(.system(size: 10 * zoomScale, weight: .semibold, design: .monospaced))
                        .foregroundStyle(section == item ? .black : .white.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7 * zoomScale)
                        .background(section == item ? accent : Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8 * zoomScale)
        .background(Color(white: 0.035))
    }

    private var historySection: some View {
        VStack(spacing: 10 * zoomScale) {
            if !hasAccessibility {
                permissionBanner
            }

            HStack(spacing: 8 * zoomScale) {
                HStack(spacing: 7 * zoomScale) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.35))
                    TextField("clipo.search_placeholder", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11 * zoomScale, design: .monospaced))
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.3))
                        .accessibilityLabel(Text("clipo.clear_search"))
                    }
                }
                .padding(9 * zoomScale)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 7 * zoomScale))

                Button {
                    service.captureCurrentClipboard()
                } label: {
                    Label("clipo.capture", systemImage: "plus.rectangle.on.rectangle")
                }
                .clipoButtonStyle(zoomScale: zoomScale, color: accent)

                Button {
                    confirmClearHistory = true
                } label: {
                    Image(systemName: "trash")
                }
                .clipoButtonStyle(zoomScale: zoomScale, color: .red)
                .accessibilityLabel(Text("clipo.clear_history"))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6 * zoomScale) {
                    filterButton(title: String(localized: "clipo.type.all"), type: nil)
                    ForEach(ClipoType.allCases) { type in
                        filterButton(title: type.displayName, type: type)
                    }
                }
            }

            if filteredHistory.isEmpty {
                emptyState(icon: "clipboard", title: "clipo.empty_history", subtitle: "clipo.empty_history_hint")
            } else {
                ScrollView {
                    LazyVStack(spacing: 7 * zoomScale) {
                        ForEach(filteredHistory) { item in
                            ClipoHistoryRow(item: item, zoomScale: zoomScale)
                        }
                    }
                    .padding(.bottom, 8 * zoomScale)
                }
            }
        }
        .padding(12 * zoomScale)
    }

    private func filterButton(title: String, type: ClipoType?) -> some View {
        let selected = selectedType == type
        return Button {
            guard !selected else { return }
            selectedType = type
            SoundEffectManager.shared.playButtonClick()
            HapticManager.shared.generic()
        } label: {
            Text(title)
                .font(.system(size: 9 * zoomScale, weight: .semibold, design: .monospaced))
                .foregroundStyle(selected ? .black : .white.opacity(0.5))
                .padding(.horizontal, 9 * zoomScale)
                .padding(.vertical, 5 * zoomScale)
                .background(selected ? accent : Color.white.opacity(0.05))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var slotsSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12 * zoomScale) {
                Text("clipo.slots_hint")
                    .font(.system(size: 10 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10 * zoomScale), count: 3), spacing: 10 * zoomScale) {
                    ForEach(1...9, id: \.self) { number in
                        ClipoSlotCard(number: number, item: service.slots[number], zoomScale: zoomScale)
                    }
                }
            }
            .padding(14 * zoomScale)
        }
    }

    private var insightsSection: some View {
        ScrollView {
            VStack(spacing: 14 * zoomScale) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10 * zoomScale) {
                    insightCard(value: service.history.count, title: "clipo.stat.total", icon: "archivebox", color: accent)
                    insightCard(value: copiesToday, title: "clipo.stat.today", icon: "calendar", color: .green)
                    insightCard(value: service.history.filter(\.isPinned).count, title: "clipo.stat.pinned", icon: "pin.fill", color: .orange)
                    insightCard(value: Set(service.history.compactMap(\.sourceApp)).count, title: "clipo.stat.sources", icon: "app.badge", color: .purple)
                }

                clipoPanel(title: "clipo.type_distribution", icon: "chart.pie") {
                    VStack(spacing: 8 * zoomScale) {
                        ForEach(ClipoType.allCases) { type in
                            let count = service.history.filter { $0.type == type }.count
                            HStack(spacing: 8 * zoomScale) {
                                Label(type.displayName, systemImage: type.iconName)
                                    .font(.system(size: 10 * zoomScale, design: .monospaced))
                                    .frame(width: 100 * zoomScale, alignment: .leading)
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.white.opacity(0.05))
                                        Capsule().fill(accent.opacity(0.65))
                                            .frame(width: service.history.isEmpty ? 0 : geometry.size.width * CGFloat(count) / CGFloat(service.history.count))
                                    }
                                }
                                .frame(height: 6 * zoomScale)
                                Text("\(count)")
                                    .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                                    .frame(width: 28 * zoomScale, alignment: .trailing)
                            }
                            .foregroundStyle(.white.opacity(0.65))
                        }
                    }
                }

                clipoPanel(title: "clipo.top_sources", icon: "app") {
                    VStack(spacing: 7 * zoomScale) {
                        ForEach(Array(topSources.enumerated()), id: \.element.name) { index, source in
                            HStack {
                                Text("\(index + 1)")
                                    .foregroundStyle(accent)
                                Text(source.name)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(source.count)")
                            }
                            .font(.system(size: 10 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.65))
                        }
                        if topSources.isEmpty {
                            Text("clipo.no_data")
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                }
            }
            .padding(14 * zoomScale)
        }
    }

    private var settingsSection: some View {
        ScrollView {
            VStack(spacing: 12 * zoomScale) {
                clipoPanel(title: "clipo.settings.shortcuts", icon: "command") {
                    Text("clipo.shortcuts.hint")
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))

                    shortcutEditor(
                        title: "clipo.shortcuts.open",
                        action: .openPanel,
                        shortcut: $service.settings.openShortcut
                    )

                    Divider().overlay(Color.white.opacity(0.08))

                    ForEach(1...9, id: \.self) { number in
                        VStack(alignment: .leading, spacing: 6 * zoomScale) {
                            Text(String(
                                format: String(localized: "clipo.shortcuts.slot_format"),
                                number
                            ))
                                .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                                .foregroundStyle(accent)
                            shortcutEditor(
                                title: "clipo.shortcuts.save",
                                action: .saveSlot(number),
                                shortcut: $service.settings.slotSaveShortcuts[number - 1]
                            )
                            shortcutEditor(
                                title: "clipo.shortcuts.copy",
                                action: .copySlot(number),
                                shortcut: $service.settings.slotCopyShortcuts[number - 1]
                            )
                        }
                        if number < 9 {
                            Divider().overlay(Color.white.opacity(0.05))
                        }
                    }

                    HStack {
                        if !service.shortcutRegistrationFailures.isEmpty {
                            Label("clipo.shortcuts.conflict", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                        Spacer()
                        Button("clipo.shortcuts.restore_defaults") {
                            recordingShortcut = nil
                            if service.resetShortcuts() {
                                SoundEffectManager.shared.playButtonClick()
                                HapticManager.shared.generic()
                            }
                        }
                        .clipoButtonStyle(zoomScale: zoomScale, color: accent)
                    }
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                }

                clipoPanel(title: "clipo.settings.history", icon: "clock") {
                    clipoToggle("clipo.settings.monitor", isOn: $service.settings.monitorClipboard)
                    clipoToggle("clipo.settings.ignore_duplicates", isOn: $service.settings.ignoreDuplicates)
                    clipoToggle("clipo.settings.ignore_sensitive", isOn: $service.settings.ignoreSensitiveApps)
                    clipoToggle("clipo.settings.case_sensitive", isOn: $service.settings.searchCaseSensitive)
                    clipoToggle("clipo.settings.fuzzy", isOn: $service.settings.fuzzySearch)

                    Stepper(value: $service.settings.maxHistoryItems, in: 0...2_000, step: 50) {
                        HStack {
                            Text("clipo.settings.history_limit")
                            Spacer()
                            Text("\(service.settings.maxHistoryItems)")
                                .foregroundStyle(accent)
                        }
                    }
                    .font(.system(size: 10 * zoomScale, design: .monospaced))

                    Picker("clipo.settings.auto_delete", selection: $service.settings.autoDeletePolicy) {
                        ForEach(ClipoAutoDeletePolicy.allCases) { policy in
                            Text(policy.displayName).tag(policy)
                        }
                    }
                    .font(.system(size: 10 * zoomScale, design: .monospaced))
                }

                clipoPanel(title: "clipo.settings.paste", icon: "doc.on.clipboard") {
                    clipoToggle("clipo.settings.restore_paste", isOn: $service.settings.restoreClipboardAfterPaste)
                    clipoToggle("clipo.settings.restore_save", isOn: $service.settings.restoreClipboardAfterSave)
                    HStack {
                        Text("clipo.settings.paste_delay")
                        Slider(value: $service.settings.pasteDelay, in: 0...1, step: 0.05)
                        Text(String(
                            format: String(localized: "clipo.seconds_format"),
                            service.settings.pasteDelay
                        ))
                            .foregroundStyle(accent)
                            .frame(width: 48 * zoomScale)
                    }
                    .font(.system(size: 10 * zoomScale, design: .monospaced))
                }

                clipoPanel(title: "clipo.settings.appearance", icon: "paintbrush") {
                    clipoToggle("clipo.settings.show_source", isOn: $service.settings.showSourceApp)
                    clipoToggle("clipo.settings.show_time", isOn: $service.settings.showTimestamp)
                    clipoToggle("clipo.settings.compact", isOn: $service.settings.compactRows)
                }

                clipoPanel(title: "clipo.settings.sensitive_apps", icon: "lock.shield") {
                    ForEach(service.settings.sensitiveBundleIdentifiers, id: \.self) { bundleID in
                        HStack {
                            Text(bundleID)
                                .font(.system(size: 9 * zoomScale, design: .monospaced))
                                .lineLimit(1)
                            Spacer()
                            Button {
                                service.settings.sensitiveBundleIdentifiers.removeAll { $0 == bundleID }
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.red.opacity(0.7))
                            .accessibilityLabel(Text("button.delete"))
                        }
                    }
                    HStack {
                        TextField("clipo.settings.bundle_placeholder", text: $newSensitiveBundle)
                            .textFieldStyle(.roundedBorder)
                        Button("clipo.add") {
                            let value = newSensitiveBundle.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !value.isEmpty, !service.settings.sensitiveBundleIdentifiers.contains(value) else { return }
                            service.settings.sensitiveBundleIdentifiers.append(value)
                            newSensitiveBundle = ""
                        }
                        .clipoButtonStyle(zoomScale: zoomScale, color: accent)
                    }
                }

                clipoPanel(title: "clipo.settings.data", icon: "externaldrive") {
                    HStack {
                        Button("clipo.export") { exportStore() }
                            .clipoButtonStyle(zoomScale: zoomScale, color: accent)
                        Button("clipo.import") { selectImportStore() }
                            .clipoButtonStyle(zoomScale: zoomScale, color: accent)
                        Spacer()
                        Button("clipo.reset") { confirmReset = true }
                            .clipoButtonStyle(zoomScale: zoomScale, color: .red)
                    }
                }
            }
            .padding(14 * zoomScale)
        }
    }

    private var permissionBanner: some View {
        HStack(spacing: 10 * zoomScale) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2 * zoomScale) {
                Text("clipo.permission_title")
                    .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                Text("clipo.permission_description")
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            Button("clipo.permission_open") {
                PermissionCenterService.shared.requestPermission(.accessibility)
                hasAccessibility = AXIsProcessTrusted()
            }
            .clipoButtonStyle(zoomScale: zoomScale, color: .orange)
        }
        .padding(9 * zoomScale)
        .background(Color.orange.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 7 * zoomScale).stroke(Color.orange.opacity(0.25)))
    }

    private func clipoToggle(_ title: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(.system(size: 10 * zoomScale, design: .monospaced))
        }
        .toggleStyle(.switch)
        .controlSize(.small)
    }

    private func shortcutEditor(
        title: LocalizedStringKey,
        action: ClipoShortcutAction,
        shortcut: Binding<ClipoShortcut>
    ) -> some View {
        HStack(spacing: 8 * zoomScale) {
            Text(title)
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
            ShortcutPicker(
                key: shortcut.key,
                modifiers: shortcut.modifiers,
                isRecording: Binding(
                    get: { recordingShortcut == action },
                    set: { recordingShortcut = $0 ? action : nil }
                )
            )
            .frame(width: 190 * zoomScale)

            Image(systemName: shortcutStatusIcon(action: action, shortcut: shortcut.wrappedValue))
                .foregroundStyle(shortcutStatusColor(action: action, shortcut: shortcut.wrappedValue))
                .frame(width: 14 * zoomScale)
                .help(shortcutStatusHelp(action: action, shortcut: shortcut.wrappedValue))
        }
    }

    private func shortcutStatusIcon(action: ClipoShortcutAction, shortcut: ClipoShortcut) -> String {
        if service.shortcutRegistrationFailures.contains(action) { return "exclamationmark.triangle.fill" }
        return shortcut.isEnabled ? "checkmark.circle.fill" : "minus.circle"
    }

    private func shortcutStatusColor(action: ClipoShortcutAction, shortcut: ClipoShortcut) -> Color {
        if service.shortcutRegistrationFailures.contains(action) { return .orange }
        return shortcut.isEnabled ? .green.opacity(0.75) : .white.opacity(0.25)
    }

    private func shortcutStatusHelp(action: ClipoShortcutAction, shortcut: ClipoShortcut) -> String {
        if service.shortcutRegistrationFailures.contains(action) {
            return String(localized: "clipo.shortcuts.status_unavailable")
        }
        return String(localized: shortcut.isEnabled
            ? "clipo.shortcuts.status_registered"
            : "clipo.shortcuts.status_disabled")
    }

    private func clipoPanel<Content: View>(title: LocalizedStringKey, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10 * zoomScale) {
            Label(title, systemImage: icon)
                .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(accent)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12 * zoomScale)
        .background(Color.white.opacity(0.025))
        .overlay(RoundedRectangle(cornerRadius: 9 * zoomScale).stroke(Color.white.opacity(0.07)))
    }

    private func insightCard(value: Int, title: LocalizedStringKey, icon: String, color: Color) -> some View {
        VStack(spacing: 6 * zoomScale) {
            Image(systemName: icon).foregroundStyle(color)
            Text("\(value)")
                .font(.system(size: 20 * zoomScale, weight: .bold, design: .monospaced))
            Text(title)
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(12 * zoomScale)
        .background(color.opacity(0.07))
        .overlay(RoundedRectangle(cornerRadius: 9 * zoomScale).stroke(color.opacity(0.2)))
    }

    private func emptyState(icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        VStack(spacing: 8 * zoomScale) {
            Image(systemName: icon)
                .font(.system(size: 30 * zoomScale))
                .foregroundStyle(.white.opacity(0.16))
            Text(title)
                .font(.system(size: 12 * zoomScale, weight: .bold, design: .monospaced))
            Text(subtitle)
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var copiesToday: Int {
        let start = Calendar.current.startOfDay(for: Date())
        return service.history.filter { $0.lastUsedAt >= start }.count
    }

    private var topSources: [(name: String, count: Int)] {
        Dictionary(grouping: service.history.compactMap(\.sourceApp), by: { $0 })
            .map { (name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
    }

    private func exportStore() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "ClassGod-Clipo.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try service.export(to: url)
            SoundEffectManager.shared.playButtonClick()
        } catch {
            ErrorToastManager.shared.show(error: error)
        }
    }

    private func selectImportStore() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        pendingImportURL = url
    }

    private func importStore(from url: URL) {
        do {
            try service.importStore(from: url)
            SoundEffectManager.shared.playTabSaved()
        } catch {
            ErrorToastManager.shared.show(error: error)
        }
    }
}

private struct ClipoHistoryRow: View {
    @ObservedObject private var service = ClipoService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    let item: ClipoItem
    let zoomScale: CGFloat

    private var accent: Color { prefs.preferences.themeAccent.color }

    var body: some View {
        HStack(spacing: 10 * zoomScale) {
            ZStack {
                RoundedRectangle(cornerRadius: 7 * zoomScale)
                    .fill(accent.opacity(0.08))
                    .frame(width: 38 * zoomScale, height: 38 * zoomScale)
                if item.type == .image, let image = thumbnail {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 34 * zoomScale, height: 34 * zoomScale)
                        .clipShape(RoundedRectangle(cornerRadius: 5 * zoomScale))
                } else {
                    Image(systemName: item.type.iconName)
                        .foregroundStyle(accent)
                }
            }

            VStack(alignment: .leading, spacing: 3 * zoomScale) {
                Text(item.preview.isEmpty ? String(localized: "clipo.binary_data") : item.preview)
                    .font(.system(size: 10 * zoomScale, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(service.settings.compactRows ? 1 : 2)
                HStack(spacing: 6 * zoomScale) {
                    Text(item.type.displayName)
                    if service.settings.showSourceApp, let source = item.sourceApp {
                        Text("• \(source)")
                    }
                    if service.settings.showTimestamp {
                        Text("• \(item.lastUsedAt.formatted(date: .omitted, time: .shortened))")
                    }
                }
                .font(.system(size: 8 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.32))
            }

            Spacer(minLength: 4 * zoomScale)

            rowButton(icon: item.isPinned ? "pin.fill" : "pin") { service.togglePin(item.id) }
            Menu {
                ForEach(1...9, id: \.self) { number in
                    Button(String(format: String(localized: "clipo.save_to_slot"), number)) {
                        service.save(item, to: number)
                    }
                }
            } label: {
                Image(systemName: "square.grid.3x3")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 26 * zoomScale)
            .accessibilityLabel(Text("clipo.assign_slot"))
            rowButton(icon: "doc.on.doc") { service.copy(item) }
            rowButton(icon: "return") { service.paste(item) }
            rowButton(icon: "trash", color: .red) { service.delete(item.id) }
        }
        .padding(.horizontal, 10 * zoomScale)
        .padding(.vertical, service.settings.compactRows ? 6 * zoomScale : 9 * zoomScale)
        .background(Color.white.opacity(item.isPinned ? 0.045 : 0.025))
        .overlay(RoundedRectangle(cornerRadius: 8 * zoomScale).stroke(item.isPinned ? Color.orange.opacity(0.25) : Color.white.opacity(0.06)))
    }

    private var thumbnail: NSImage? {
        item.payload?.items.lazy.flatMap(\.representations).first {
            $0.type.hasPrefix("public.png") || $0.type.hasPrefix("public.jpeg") || $0.type.hasPrefix("public.tiff")
        }.flatMap { NSImage(data: $0.data) }
    }

    private func rowButton(icon: String, color: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10 * zoomScale))
                .foregroundStyle(color.opacity(0.6))
                .frame(width: 24 * zoomScale, height: 24 * zoomScale)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(actionLabel(for: icon)))
    }

    private func actionLabel(for icon: String) -> LocalizedStringKey {
        switch icon {
        case "pin": "clipo.action.pin"
        case "pin.fill": "clipo.action.pin.fill"
        case "doc.on.doc": "clipo.action.doc.on.doc"
        case "return": "clipo.action.return"
        default: "clipo.action.trash"
        }
    }
}

private struct ClipoSlotCard: View {
    @ObservedObject private var service = ClipoService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    let number: Int
    let item: ClipoItem?
    let zoomScale: CGFloat

    private var accent: Color { prefs.preferences.themeAccent.color }

    var body: some View {
        VStack(alignment: .leading, spacing: 8 * zoomScale) {
            HStack {
                Text("#\(number)")
                    .font(.system(size: 12 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(accent)
                Spacer()
                Text(shortcutSummary)
                    .font(.system(size: 7 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.25))
            }

            if let item {
                Label(item.type.displayName, systemImage: item.type.iconName)
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                Text(item.preview)
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, minHeight: 38 * zoomScale, alignment: .topLeading)
                HStack(spacing: 5 * zoomScale) {
                    slotButton("doc.on.doc", label: "clipo.action.doc.on.doc") { service.copy(item) }
                    slotButton("return", label: "clipo.action.return") { service.paste(item) }
                    Spacer()
                    slotButton("trash", label: "clipo.action.trash", color: .red) { service.deleteSlot(number) }
                }
            } else {
                Text("clipo.empty_slot")
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.25))
                    .frame(maxWidth: .infinity, minHeight: 62 * zoomScale, alignment: .center)
                Button("clipo.save_clipboard") {
                    service.saveCurrentClipboard(to: number)
                }
                .clipoButtonStyle(zoomScale: zoomScale, color: accent)
            }
        }
        .padding(10 * zoomScale)
        .frame(maxWidth: .infinity, minHeight: 132 * zoomScale, alignment: .top)
        .background(Color.white.opacity(0.025))
        .overlay(RoundedRectangle(cornerRadius: 9 * zoomScale).stroke(item == nil ? Color.white.opacity(0.06) : accent.opacity(0.18)))
    }

    private var shortcutSummary: String {
        let settings = service.settings
        return "\(settings.slotSaveShortcuts[number - 1].displayString) / \(settings.slotCopyShortcuts[number - 1].displayString)"
    }

    private func slotButton(
        _ icon: String,
        label: LocalizedStringKey,
        color: Color = .white,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 9 * zoomScale))
                .foregroundStyle(color.opacity(0.65))
                .frame(width: 23 * zoomScale, height: 23 * zoomScale)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 5 * zoomScale))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}

private extension View {
    func clipoButtonStyle(zoomScale: CGFloat, color: Color) -> some View {
        buttonStyle(.plain)
            .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 9 * zoomScale)
            .padding(.vertical, 6 * zoomScale)
            .background(color.opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: 6 * zoomScale).stroke(color.opacity(0.25)))
            .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
    }
}

#Preview {
    ClipoView(onClose: {})
        .frame(width: 760, height: 620)
}
