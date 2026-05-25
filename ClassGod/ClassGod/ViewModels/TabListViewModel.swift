//
//  TabListViewModel.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import AppKit
import Combine
import SwiftUI

@MainActor
final class TabListViewModel: ObservableObject {
    @Published var tabs: [BrowserTab] = []
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showPermissionAlert = false
    @Published var isAccessibilityTrusted = false

    var onShowToast: ((String) -> Void)?
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadTabs()
        setupShortcutCallbacks()
        setupStorageChangeObserver()
    }

    func loadTabs() {
        tabs = StorageManager.shared.loadTabs()
        refreshShortcuts()
    }

    func saveTabs() {
        StorageManager.shared.saveTabs(tabs)
        refreshShortcuts()
    }

    func addTab(_ tab: BrowserTab) {
        tabs.append(tab)
        saveTabs()
        onShowToast?(String(format: String(localized: "toast.saved"), tab.title))
    }

    func updateTab(_ tab: BrowserTab) {
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs[index] = tab
            saveTabs()
            onShowToast?(String(format: String(localized: "toast.updated"), tab.title))
        }
    }

    func deleteTab(_ tab: BrowserTab) {
        tabs.removeAll { $0.id == tab.id }
        ShortcutManager.shared.unregisterShortcut(for: tab.id)
        saveTabs()
    }

    func deleteTab(at offsets: IndexSet) {
        for index in offsets {
            let tab = tabs[index]
            ShortcutManager.shared.unregisterShortcut(for: tab.id)
        }
        tabs.remove(atOffsets: offsets)
        saveTabs()
    }

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
            self.saveTabs()
            self.onShowToast?(String(localized: "toast.saved_current"))
        }
    }

    func switchToTab(_ tab: BrowserTab) {
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

    private func refreshShortcuts() {
        ShortcutManager.shared.refreshShortcuts(from: tabs)
    }

    private func containsTab(browser: BrowserType, url: String) -> Bool {
        tabs.contains {
            $0.browser == browser && $0.url.normalizedForComparison == url.normalizedForComparison
        }
    }

    private func setupShortcutCallbacks() {
        ShortcutManager.shared.onHotKeyPressed = { [weak self] tabID in
            guard let self = self else { return }
            if let tab = self.tabs.first(where: { $0.id == tabID }) {
                self.switchToTab(tab)
            }
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
