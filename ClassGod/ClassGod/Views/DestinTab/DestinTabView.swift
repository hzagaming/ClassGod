//
//  DestinTabView.swift
//  ClassGod
//

import SwiftUI
import UniformTypeIdentifiers

struct DestinTabView: View {
    @StateObject private var viewModel = TabListViewModel()
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    @State private var showAddSheet = false
    @State private var editingTab: BrowserTab?
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var toastOffset: CGFloat = 20
    @State private var tabToDelete: BrowserTab?
    @State private var headerScale: CGFloat = 0.98
    @State private var headerOpacity: Double = 0
    @State private var toastWorkItem: DispatchWorkItem?
    @State private var showImportPanel = false
    @State private var showExportPanel = false
    @State private var showSortPicker = false

    var onClose: () -> Void

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .scaleEffect(headerScale)
                    .opacity(headerOpacity)

                headerDivider
                    .opacity(headerOpacity)

                // Search + tools bar
                searchBar
                    .opacity(headerOpacity)

                tabList

                Divider()
                    .opacity(headerOpacity)

                footer
                    .opacity(headerOpacity)
            }

            scanlineOverlay
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius * zoomScale)
                .fill(Color.black)
        )
        .overlay(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius * zoomScale)
                .stroke(Color.white.opacity(0.15), lineWidth: 1 * zoomScale)
        
            .allowsHitTesting(false))
        .preferredColorScheme(prefs.preferences.theme.colorScheme)
        .sheet(isPresented: $showAddSheet) {
            AddTabView(viewModel: viewModel, tab: nil)
        }
        .sheet(item: $editingTab) { tab in
            AddTabView(viewModel: viewModel, tab: tab)
        }
        .alert(String(localized: "error.title"), isPresented: $viewModel.showError) {
            Button(String(localized: "button.ok"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? String(localized: "error.unknown"))
        }
        .alert(String(localized: "permission.required.title"), isPresented: $viewModel.showPermissionAlert) {
            Button(String(localized: "button.open_settings")) {
                openAccessibilitySettings()
            }
            Button(String(localized: "button.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "permission.required.message"))
        }
        .alert(String(localized: "delete.confirm.title"), isPresented: .init(
            get: { tabToDelete != nil },
            set: { if !$0 { tabToDelete = nil } }
        )) {
            Button(String(localized: "button.cancel"), role: .cancel) { tabToDelete = nil }
            Button(String(localized: "button.delete"), role: .destructive) {
                if let tab = tabToDelete {
                    Anim.with { viewModel.deleteTab(tab) }
                    SoundEffectManager.shared.playTabDeleted()
                    HapticManager.shared.warning()
                }
                tabToDelete = nil
            }
        } message: {
            Text(String(format: String(localized: "delete.confirm.message"), tabToDelete?.title ?? ""))
        }
        .overlay(toastOverlay, alignment: .bottom)
        .fileImporter(
            isPresented: $showImportPanel,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .fileExporter(
            isPresented: $showExportPanel,
            document: TabsJSONDocument(data: viewModel.exportTabs() ?? Data()),
            contentType: .json,
            defaultFilename: "classgod-tabs"
        ) { result in
            if case .success = result {
                SoundEffectManager.shared.playButtonClick()
                showToast(message: "Exported tabs to JSON")
            }
        }
        .onAppear {
            viewModel.onShowToast = { [weak viewModel] msg in
                guard viewModel != nil else { return }
                guard prefs.preferences.showToastNotifications else { return }
                showToast(message: msg)
            }

            if prefs.preferences.autoDetectOnShow {
                viewModel.detectCurrentTabOnShowIfNeeded()
            }

            Anim.with {
                headerScale = 1.0
                headerOpacity = 1.0
            }
        }
        .onDisappear {
            toastWorkItem?.cancel()
            toastWorkItem = nil
            showToast = false
            headerScale = 0.98
            headerOpacity = 0
        }
    }

    // MARK: - Toast

    private var toastOverlay: some View {
        Group {
            if showToast, let message = toastMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12 * zoomScale))
                        .foregroundStyle(.white)
                    Text(message)
                        .font(.system(size: 12 * zoomScale, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12 * zoomScale)
                .padding(.vertical, 7 * zoomScale)
                .background(Color(white: 0.12))
                .overlay(Rectangle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                .padding(.bottom, 10 * zoomScale)
                .offset(y: toastOffset)
                .transition(.opacity)
            }
        }
    }

    private func showToast(message: String) {
        toastWorkItem?.cancel()
        toastMessage = message
        toastOffset = 20
        showToast = true
        Anim.with { toastOffset = 0 }
        let item = DispatchWorkItem {
            Anim.with {
                toastOffset = 20
                showToast = false
            }
        }
        toastWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + prefs.preferences.toastDuration, execute: item)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                onClose()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10 * zoomScale, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                    .background(Color(white: 0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 0) {
                Text("DestinTab")
                    .font(.system(prefs.preferences.useCompactMode ? .subheadline : .headline, design: .monospaced))
                    .foregroundStyle(.white)
                Text("Manage & switch browser tabs")
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }

            if prefs.preferences.showTabCountBadge {
                Text("\(viewModel.tabs.count)")
                    .font(.system(size: 10 * zoomScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 6 * zoomScale)
                    .padding(.vertical, 2 * zoomScale)
                    .background(Color(white: 0.14))
                    .overlay(Rectangle().stroke(Color.white.opacity(0.2), lineWidth: 0.5 * zoomScale))
            }

            Spacer()

            // Duplicate warning
            if viewModel.hasDuplicates {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11 * zoomScale))
                    .foregroundStyle(.orange)
                    .help("Duplicate URLs detected")
            }

            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                showAddSheet = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.monochrome)
            }
            .buttonStyle(.plain)
            .help(String(localized: "button.add_tab"))
        }
        .padding(.horizontal, 16 * zoomScale)
        .padding(.vertical, (prefs.preferences.useCompactMode ? 6 : 10) * zoomScale)
    }

    private var headerDivider: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [Color.clear, Color.white.opacity(0.15), Color.clear],
                startPoint: .leading, endPoint: .trailing
            ))
            .frame(height: 1)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11 * zoomScale))
                        .foregroundStyle(.white.opacity(0.4))
                    TextField("Search tabs...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white)
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: { viewModel.searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12 * zoomScale))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8 * zoomScale)
                .padding(.vertical, 5 * zoomScale)
                .background(Color(white: 0.06))
                .overlay(Rectangle().stroke(Color.white.opacity(0.1), lineWidth: 1))

                // Sort picker
                Menu {
                    ForEach(TabSortMode.allCases) { mode in
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            viewModel.sortMode = mode
                        }) {
                            HStack {
                                Image(systemName: mode.icon)
                                Text(mode.displayName)
                                if viewModel.sortMode == mode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: viewModel.sortMode.icon)
                        .font(.system(size: 12 * zoomScale))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 26 * zoomScale, height: 26 * zoomScale)
                        .background(Color(white: 0.08))
                        .overlay(Rectangle().stroke(Color.white.opacity(0.1), lineWidth: 1 * zoomScale))
                }
                .menuStyle(.borderlessButton)
                .frame(width: 28 * zoomScale, height: 28 * zoomScale)
                .help("Sort: \(viewModel.sortMode.displayName)")

                // Bulk mode toggle
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    viewModel.isBulkMode.toggle()
                    if !viewModel.isBulkMode {
                        viewModel.deselectAll()
                    }
                }) {
                    Image(systemName: viewModel.isBulkMode ? "checkmark.square.fill" : "square")
                        .font(.system(size: 12 * zoomScale))
                        .foregroundStyle(viewModel.isBulkMode ? .cyan : .white.opacity(0.6))
                        .frame(width: 26 * zoomScale, height: 26 * zoomScale)
                        .background(viewModel.isBulkMode ? Color.cyan.opacity(0.1) : Color(white: 0.08))
                        .overlay(Rectangle().stroke(viewModel.isBulkMode ? Color.cyan.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1 * zoomScale))
                }
                .buttonStyle(.plain)
                .help(viewModel.isBulkMode ? "Exit bulk mode" : "Bulk select")
            }

            // Bulk action bar
            if viewModel.isBulkMode {
                HStack(spacing: 8) {
                    Text("\(viewModel.selectedTabIDs.count) selected")
                        .font(.system(size: 10 * zoomScale, design: .monospaced))
                        .foregroundStyle(.cyan)

                    Spacer()

                    Button("All") {
                        SoundEffectManager.shared.playButtonClick()
                        viewModel.selectAllVisible()
                    }
                    .font(.system(size: 10 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .buttonStyle(.plain)

                    Button("None") {
                        SoundEffectManager.shared.playButtonClick()
                        viewModel.deselectAll()
                    }
                    .font(.system(size: 10 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .buttonStyle(.plain)

                    Button(action: {
                        SoundEffectManager.shared.playTabDeleted()
                        viewModel.bulkDeleteSelected()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11 * zoomScale))
                            .foregroundStyle(.red.opacity(viewModel.selectedTabIDs.isEmpty ? 0.3 : 0.8))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.selectedTabIDs.isEmpty)
                }
                .padding(.horizontal, 4 * zoomScale)
            }
        }
        .padding(.horizontal, 16 * zoomScale)
        .padding(.vertical, 6 * zoomScale)
    }

    // MARK: - Tab List

    private var tabList: some View {
        ScrollView {
            if viewModel.visibleTabs.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    let visible = Array(viewModel.visibleTabs.prefix(prefs.preferences.maxTabsInPopover))
                    // Pinned section header
                    if !viewModel.pinnedTabs.isEmpty && viewModel.searchQuery.isEmpty {
                        HStack {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 8 * zoomScale))
                                .foregroundStyle(.cyan.opacity(0.6))
                            Text("PINNED")
                                .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                                .foregroundStyle(.cyan.opacity(0.6))
                            Spacer()
                        }
                        .padding(.horizontal, 12 * zoomScale)
                        .padding(.vertical, 4 * zoomScale)
                        .background(Color(white: 0.03))
                    }

                    ForEach(visible) { tab in
                        TabRow(
                            tab: tab,
                            viewModel: viewModel,
                            isDuplicate: viewModel.isDuplicate(tab),
                            isSelected: viewModel.selectedTabIDs.contains(tab.id)
                        ) {
                            viewModel.switchToTab(tab)
                        } onEdit: {
                            editingTab = tab
                        } onDelete: {
                            if prefs.preferences.confirmBeforeDelete {
                                tabToDelete = tab
                            } else {
                                Anim.with { viewModel.deleteTab(tab) }
                                SoundEffectManager.shared.playTabDeleted()
                                HapticManager.shared.warning()
                            }
                        } onTogglePin: {
                            viewModel.togglePin(tab)
                        } onToggleSelect: {
                            viewModel.toggleSelection(tab.id)
                        }
                        .contextMenu {
                            Button("Open") { viewModel.switchToTab(tab) }
                            Button("Edit") { editingTab = tab }
                            Button(tab.isPinned ? "Unpin" : "Pin") {
                                viewModel.togglePin(tab)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                if prefs.preferences.confirmBeforeDelete {
                                    tabToDelete = tab
                                } else {
                                    Anim.with { viewModel.deleteTab(tab) }
                                    SoundEffectManager.shared.playTabDeleted()
                                    HapticManager.shared.warning()
                                }
                            }
                        }
                        .transition(.opacity)

                        if tab.id != visible.last?.id {
                            Divider()
                                .padding(.leading, (prefs.preferences.showBrowserIcon ? 44 : 16) * zoomScale)
                                .opacity(0.5)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: prefs.preferences.panelMaxHeight * zoomScale)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.white.opacity(0.1)).frame(width: 52 * zoomScale, height: 52 * zoomScale)
                Image(systemName: "link.badge.plus")
                    .font(.system(size: 24 * zoomScale))
                    .foregroundStyle(.white.opacity(0.7))
                    .symbolRenderingMode(.monochrome)
            }
            .bounce(intensity: 1.03)

            Text(viewModel.searchQuery.isEmpty ? String(localized: "empty.title") : "No matches")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))

            Text(viewModel.searchQuery.isEmpty ? String(localized: "empty.subtitle") : "Try a different search term")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: (prefs.preferences.useCompactMode ? 80 : 120) * zoomScale)
        .padding(16 * zoomScale)
        .slideIn(from: .bottom, delay: 0.05)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                Anim.with { viewModel.detectAndAddCurrentTab() }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14 * zoomScale))
                        .symbolRenderingMode(.monochrome)
                    Text(String(localized: "button.save_current_tab"))
                        .font(.system(size: 13 * zoomScale, weight: .semibold, design: .monospaced))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .padding(.horizontal, 16 * zoomScale)
            .padding(.vertical, 10 * zoomScale)
            .background(LinearGradient(
                colors: [Color(white: 0.06), Color(white: 0.1)],
                startPoint: .top, endPoint: .bottom
            ))
            .overlay(Rectangle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            .contentShape(Rectangle())

            Divider()

            HStack(spacing: 14) {
                footerButton(title: String(localized: "button.settings"), icon: "gear") {
                    SoundEffectManager.shared.playButtonClick()
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }

                footerButton(title: "Import", icon: "square.and.arrow.down") {
                    SoundEffectManager.shared.playButtonClick()
                    showImportPanel = true
                }

                footerButton(title: "Export", icon: "square.and.arrow.up") {
                    SoundEffectManager.shared.playButtonClick()
                    showExportPanel = true
                }

                footerButton(title: String(localized: "button.automation"), icon: "lock.shield") {
                    SoundEffectManager.shared.playButtonClick()
                    openAutomationSettings()
                }

                Spacer()
            }
            .padding(.horizontal, 16 * zoomScale)
            .padding(.vertical, 8 * zoomScale)
        }
    }

    private func footerButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .symbolRenderingMode(.monochrome)
                Text(title)
                    .font(.system(size: 11, design: .monospaced))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.6))
    }

    // MARK: - Import/Export

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let data = try Data(contentsOf: url)
                if viewModel.importTabs(from: data) {
                    SoundEffectManager.shared.playTabSaved()
                    HapticManager.shared.success()
                }
            } catch {
                showToast(message: "Import failed: \(error.localizedDescription)")
            }
        case .failure(let error):
            showToast(message: "Import failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Scanline

    private var scanlineOverlay: some View {
        GeometryReader { geo in
            VStack(spacing: 2) {
                ForEach(0..<Int(geo.size.height / 4), id: \.self) { _ in
                    Rectangle().fill(Color.white.opacity(0.015)).frame(height: 1)
                    Spacer().frame(height: 3)
                }
            }
        }
    }

    private func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    private func openAutomationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") else { return }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - TabRow

struct TabRow: View {
    let tab: BrowserTab
    let viewModel: TabListViewModel
    let isDuplicate: Bool
    let isSelected: Bool
    let onOpen: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onTogglePin: () -> Void
    let onToggleSelect: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false
    @FocusState private var isFocused: Bool
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        Button(action: {
            if viewModel.isBulkMode {
                SoundEffectManager.shared.playButtonClick()
                onToggleSelect()
                return
            }
            SoundEffectManager.shared.playButtonClick()
            Anim.with { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                Anim.with { isPressed = false }
            }
            onOpen()
        }) {
            HStack(spacing: 8) {
                // Bulk select checkbox
                if viewModel.isBulkMode {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .font(.system(size: 14 * zoomScale))
                        .foregroundStyle(isSelected ? .cyan : .white.opacity(0.3))
                        .frame(width: 20 * zoomScale)
                }

                // Pin icon
                if tab.isPinned && !viewModel.isBulkMode {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9 * zoomScale))
                        .foregroundStyle(.cyan.opacity(0.7))
                        .frame(width: 14 * zoomScale)
                }

                if prefs.preferences.showBrowserIcon {
                    browserIcon
                }

                VStack(alignment: .leading, spacing: (prefs.preferences.useCompactMode ? 0 : 2) * zoomScale) {
                    HStack(spacing: 4 * zoomScale) {
                        Text(tab.title)
                            .font(.system(size: (prefs.preferences.useCompactMode ? 12 : 13) * zoomScale, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        if isDuplicate && !viewModel.isBulkMode {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 8 * zoomScale))
                                .foregroundStyle(.orange.opacity(0.8))
                                .help("Duplicate URL")
                        }
                    }

                    if prefs.preferences.showURLPreview {
                        Text(tab.url)
                            .font(.system(size: (prefs.preferences.useCompactMode ? 9 : 10) * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Tag badge
                if tab.hasTag && !viewModel.isBulkMode {
                    Text(tab.displayTag)
                        .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.8))
                        .padding(.horizontal, 5 * zoomScale)
                        .padding(.vertical, 1 * zoomScale)
                        .background(Color.cyan.opacity(0.08))
                        .overlay(Rectangle().stroke(Color.cyan.opacity(0.2), lineWidth: 0.5 * zoomScale))
                }

                // Last accessed
                if !viewModel.isBulkMode {
                    Text(tab.lastAccessedDisplay)
                        .font(.system(size: 8 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }

                if prefs.preferences.showShortcutBadge && tab.isValidShortcut && !viewModel.isBulkMode {
                    Text(tab.shortcutDisplayString)
                        .font(.system(size: (prefs.preferences.useCompactMode ? 10 : 11) * zoomScale, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 7 * zoomScale)
                        .padding(.vertical, 2 * zoomScale)
                        .background(Color(white: 0.15))
                        .overlay(Rectangle().stroke(Color.white.opacity(0.2), lineWidth: 0.5 * zoomScale))
                }

                // Hover actions
                if isHovered && !viewModel.isBulkMode {
                    HStack(spacing: 4 * zoomScale) {
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            onTogglePin()
                        }) {
                            Image(systemName: tab.isPinned ? "pin.slash" : "pin")
                                .font(.system(size: 11 * zoomScale))
                                .foregroundStyle(.cyan)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            onEdit()
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 11 * zoomScale))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            onDelete()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11 * zoomScale, weight: .bold))
                                .foregroundStyle(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16 * zoomScale)
            .padding(.vertical, (prefs.preferences.useCompactMode ? 4 : 8) * zoomScale)
            .frame(minHeight: prefs.preferences.rowHeight * zoomScale)
            .contentShape(Rectangle())
            .background(Rectangle().fill(backgroundColor))
            .overlay(Rectangle().stroke(borderColor, lineWidth: 1))
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .focusable(prefs.preferences.enableKeyboardNavigation)
        .focused($isFocused)
        .help(tab.url)
        .onHover { hovering in
            if Anim.enabled {
                withAnimation(.easeOut(duration: Anim.duration)) {
                    isHovered = hovering
                }
            } else {
                isHovered = hovering
            }
        }
        .padding(.horizontal, 4 * zoomScale)
        .padding(.vertical, 1 * zoomScale)
    }

    private var backgroundColor: Color {
        if isSelected && viewModel.isBulkMode {
            return Color.cyan.opacity(0.12)
        }
        if isPressed { return Color.white.opacity(0.15) }
        if isHovered { return Color.white.opacity(0.1) }
        if isFocused { return Color.white.opacity(0.18) }
        return Color.clear
    }

    private var borderColor: Color {
        if isSelected && viewModel.isBulkMode { return Color.cyan.opacity(0.3) }
        if isHovered || isFocused { return Color.white.opacity(0.25) }
        return Color.clear
    }

    private var browserIcon: some View {
        Group {
            switch tab.browser {
            case .safari:
                Image(systemName: "safari").foregroundStyle(.white.opacity(0.8))
            case .chrome:
                Image(systemName: "globe").foregroundStyle(.white.opacity(0.8))
            case .edge:
                Image(systemName: "wave.3.forward").foregroundStyle(.white.opacity(0.8))
            }
        }
        .font(.system(size: (prefs.preferences.useCompactMode ? 14 : 16) * zoomScale, weight: .medium))
        .frame(width: 20 * zoomScale)
        .symbolRenderingMode(.monochrome)
    }
}

// MARK: - JSON Document for Export

struct TabsJSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        guard let d = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = d
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    DestinTabView(onClose: {})
}
