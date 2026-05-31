//
//  TabListViewModel.swift
//  ClassGod
//

import Foundation
import AppKit
import Combine
import SwiftUI

enum TabSortMode: String, Codable, CaseIterable, Identifiable {
    case manual = "manual"
    case recentlyUsed = "recentlyUsed"
    case alphabetical = "alphabetical"
    case byBrowser = "byBrowser"
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .recentlyUsed: return "Recent"
        case .alphabetical: return "A-Z"
        case .byBrowser: return "Browser"
        }
    }
    var icon: String {
        switch self {
        case .manual: return "line.3.horizontal"
        case .recentlyUsed: return "clock.arrow.circlepath"
        case .alphabetical: return "textformat.abc"
        case .byBrowser: return "globe"
        }
    }
}

@MainActor
final class TabListViewModel: ObservableObject {
    @Published var tabs: [BrowserTab] = []
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showPermissionAlert = false
    @Published var isAccessibilityTrusted = false
    
    // MARK: - Search & Filter
    @Published var searchQuery: String = ""
    
    // MARK: - Sort
    @Published var sortMode: TabSortMode = .manual {
        didSet { applySort() }
    }
    
    // MARK: - Bulk Select
    @Published var isBulkMode = false
    @Published var selectedTabIDs: Set<UUID> = []
    
    var filteredTabs: [BrowserTab] {
        let base = tabs
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty { return base }
        return base.filter {
            $0.title.lowercased().contains(query) ||
            $0.url.lowercased().contains(query) ||
            $0.tag.lowercased().contains(query)
        }
    }
    
    var visibleTabs: [BrowserTab] {
        let sorted = sortedTabs(from: filteredTabs)
        // Pinned first, then by sort order
        return sorted.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            return false // maintain order within same pin status
        }
    }
    
    var pinnedTabs: [BrowserTab] {
        visibleTabs.filter(\.isPinned)
    }
    
    var unpinnedTabs: [BrowserTab] {
        visibleTabs.filter { !$0.isPinned }
    }
    
    var hasDuplicates: Bool {
        let normalizedURLs = tabs.map { $0.url.normalizedForComparison }
        return Set(normalizedURLs).count != normalizedURLs.count
    }
    
    var duplicateURLCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for tab in tabs {
            let key = tab.url.normalizedForComparison
            counts[key, default: 0] += 1
        }
        return counts
    }
    
    var allTags: [String] {
        Array(Set(tabs.compactMap { $0.hasTag ? $0.displayTag : nil })).sorted()
    }
    
    var onShowToast: ((String) -> Void)?
    private var cancellables = Set<AnyCancellable>()
    private var registeredTabIDs: Set<UUID> = []

    init() {
        loadTabs()
        setupStorageChangeObserver()
    }
    
    // MARK: - Tabs CRUD
    
    func loadTabs() {
        tabs = StorageManager.shared.loadTabs()
        applySort()
        refreshShortcuts()
    }
    
    func saveTabs() {
        StorageManager.shared.saveTabs(tabs)
        refreshShortcuts()
        NotificationCenter.default.post(name: .classGodTabsDidChange, object: nil)
    }
    
    func addTab(_ tab: BrowserTab) {
        tabs.append(tab)
        applySort()
        saveTabs()
        onShowToast?(String(format: String(localized: "toast.saved"), tab.title))
    }
    
    func updateTab(_ tab: BrowserTab) {
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs[index] = tab
            applySort()
            saveTabs()
            onShowToast?(String(format: String(localized: "toast.updated"), tab.title))
        }
    }
    
    func deleteTab(_ tab: BrowserTab) {
        tabs.removeAll { $0.id == tab.id }
        selectedTabIDs.remove(tab.id)
        ShortcutManager.shared.unregisterShortcut(for: tab.id)
        registeredTabIDs.remove(tab.id)
        applySort()
        saveTabs()
    }
    
    func deleteTab(at offsets: IndexSet) {
        for index in offsets {
            let tab = tabs[index]
            ShortcutManager.shared.unregisterShortcut(for: tab.id)
            registeredTabIDs.remove(tab.id)
            selectedTabIDs.remove(tab.id)
        }
        tabs.remove(atOffsets: offsets)
        applySort()
        saveTabs()
    }
    
    func bulkDeleteSelected() {
        let toDelete = tabs.filter { selectedTabIDs.contains($0.id) }
        for tab in toDelete {
            ShortcutManager.shared.unregisterShortcut(for: tab.id)
            registeredTabIDs.remove(tab.id)
        }
        tabs.removeAll { selectedTabIDs.contains($0.id) }
        let count = selectedTabIDs.count
        selectedTabIDs.removeAll()
        applySort()
        saveTabs()
        onShowToast?("Deleted \(count) tabs")
    }
    
    func togglePin(_ tab: BrowserTab) {
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs[index].isPinned.toggle()
            applySort()
            saveTabs()
            SoundEffectManager.shared.playButtonClick()
        }
    }
    
    func updateLastAccessed(_ tab: BrowserTab) {
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs[index].lastAccessedAt = Date()
            saveTabs()
        }
    }
    
    func isDuplicate(_ tab: BrowserTab) -> Bool {
        (duplicateURLCounts[tab.url.normalizedForComparison] ?? 0) > 1
    }
    
    // MARK: - Detect & Switch
    
    func detectAndAddCurrentTab() {
        BrowserDetector.shared.detectFrontmostTab { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let detected):
                guard !self.containsTab(browser: detected.browser, url: detected.url) else {
                    SoundEffectManager.shared.playButtonClick()
                    return
                }

                let newTab = BrowserTab(
                    title: detected.title,
                    url: detected.url,
                    browser: detected.browser
                )
                Anim.with {
                    self.tabs.append(newTab)
                }
                self.applySort()
                self.saveTabs()
                self.onShowToast?(String(localized: "toast.saved_current"))
                SoundEffectManager.shared.playTabSaved()
                HapticManager.shared.success()
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.showError = true
                SoundEffectManager.shared.playSwitchFailure()
                HapticManager.shared.warning()
            }
        }
    }
    
    func detectCurrentTabOnShowIfNeeded() {
        BrowserDetector.shared.detectFrontmostTab { [weak self] result in
            guard let self = self else { return }
            guard case .success(let detected) = result else { return }

            guard !self.containsTab(browser: detected.browser, url: detected.url) else { return }

            let newTab = BrowserTab(
                title: detected.title,
                url: detected.url,
                browser: detected.browser
            )
            Anim.with {
                self.tabs.append(newTab)
            }
            self.applySort()
            self.saveTabs()
        }
    }
    
    func switchToTab(_ tab: BrowserTab) {
        updateLastAccessed(tab)
        BrowserSwitcher.shared.switchToTab(tab) { [weak self] success, message in
            guard let self = self else { return }
            if success {
                self.onShowToast?(String(format: String(localized: "toast.switched"), tab.browser.displayName))
                SoundEffectManager.shared.playSwitchSuccess()
                HapticManager.shared.success()
            } else {
                self.errorMessage = message
                self.showError = true
                SoundEffectManager.shared.playSwitchFailure()
                HapticManager.shared.warning()
            }
        }
    }
    
    // MARK: - Bulk Select
    
    func toggleSelection(_ id: UUID) {
        if selectedTabIDs.contains(id) {
            selectedTabIDs.remove(id)
        } else {
            selectedTabIDs.insert(id)
        }
    }
    
    func selectAllVisible() {
        selectedTabIDs = Set(filteredTabs.map(\.id))
    }
    
    func deselectAll() {
        selectedTabIDs.removeAll()
    }
    
    // MARK: - Import / Export
    
    func exportTabs() -> Data? {
        do {
            return try JSONEncoder().encode(tabs)
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            showError = true
            return nil
        }
    }
    
    func importTabs(from data: Data) -> Bool {
        do {
            let imported = try JSONDecoder().decode([BrowserTab].self, from: data)
            // Merge: skip duplicates by URL
            var addedCount = 0
            for tab in imported {
                if !containsTab(browser: tab.browser, url: tab.url) {
                    tabs.append(tab)
                    addedCount += 1
                }
            }
            applySort()
            saveTabs()
            onShowToast?("Imported \(addedCount) tabs")
            return true
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
            showError = true
            return false
        }
    }
    
    // MARK: - Accessibility
    
    func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        isAccessibilityTrusted = trusted
        if !trusted {
            showPermissionAlert = true
            SoundEffectManager.shared.playSwitchFailure()
            HapticManager.shared.warning()
        } else {
            SoundEffectManager.shared.playSwitchSuccess()
            HapticManager.shared.success()
        }
        return trusted
    }
    
    func checkPermissionOnShow() {
        let trusted = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        )
        isAccessibilityTrusted = trusted
    }
    
    func hasShortcutConflict(excluding tabID: UUID?, key: String, modifiers: UInt) -> Bool {
        tabs.contains { existing in
            existing.id != tabID &&
            existing.shortcutKey.uppercased() == key.uppercased() &&
            existing.shortcutModifiers == modifiers
        }
    }
    
    // MARK: - Private
    
    private func applySort() {
        switch sortMode {
        case .manual:
            break // keep current order
        case .recentlyUsed:
            tabs.sort { $0.lastAccessedAt > $1.lastAccessedAt }
        case .alphabetical:
            tabs.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .byBrowser:
            tabs.sort { $0.browser.displayName < $1.browser.displayName }
        }
        // After any sort, ensure pinned stay at top
        tabs.sort { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
            return false
        }
    }
    
    private func sortedTabs(from list: [BrowserTab]) -> [BrowserTab] {
        switch sortMode {
        case .manual:
            return list
        case .recentlyUsed:
            return list.sorted { $0.lastAccessedAt > $1.lastAccessedAt }
        case .alphabetical:
            return list.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .byBrowser:
            return list.sorted { $0.browser.displayName < $1.browser.displayName }
        }
    }
    
    private func refreshShortcuts() {
        let currentIDs = Set(tabs.map { $0.id })
        let toRemove = registeredTabIDs.subtracting(currentIDs)
        for id in toRemove {
            ShortcutManager.shared.unregisterShortcut(for: id)
        }
        for tab in tabs where tab.isValidShortcut {
            ShortcutManager.shared.unregisterShortcut(for: tab.id)
            _ = ShortcutManager.shared.registerShortcut(for: tab)
        }
        registeredTabIDs = currentIDs
    }
    
    private func containsTab(browser: BrowserType, url: String) -> Bool {
        tabs.contains {
            $0.browser == browser && $0.url.normalizedForComparison == url.normalizedForComparison
        }
    }
    
    private func setupStorageChangeObserver() {
        NotificationCenter.default.publisher(for: .classGodTabsDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadTabs()
            }
            .store(in: &cancellables)
    }
}

private extension String {
    var normalizedForComparison: String {
        trimmingCharacters(in: CharacterSet(charactersIn: "/").union(.whitespacesAndNewlines))
            .lowercased()
    }
}
