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
    
    var onShowToast: ((String) -> Void)?
    
    init() {
        loadTabs()
        setupShortcutCallbacks()
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
        onShowToast?("Saved \"\(tab.title)\"")
    }
    
    func updateTab(_ tab: BrowserTab) {
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs[index] = tab
            saveTabs()
            onShowToast?("Updated \"\(tab.title)\"")
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
                let newTab = BrowserTab(
                    title: detected.title,
                    url: detected.url,
                    browser: detected.browser
                )
                Anim.with {
                    self.tabs.append(newTab)
                }
                self.saveTabs()
                self.onShowToast?("Saved current tab")
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
    
    func switchToTab(_ tab: BrowserTab) {
        BrowserSwitcher.shared.switchToTab(tab) { [weak self] success, message in
            guard let self = self else { return }
            if success {
                self.onShowToast?("Switched to \(tab.browser.displayName)")
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
    
    private func setupShortcutCallbacks() {
        ShortcutManager.shared.onHotKeyPressed = { [weak self] tabID in
            guard let self = self else { return }
            if let tab = self.tabs.first(where: { $0.id == tabID }) {
                self.switchToTab(tab)
            }
        }
    }
}
