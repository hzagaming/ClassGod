//
//  SuperSwitchViewModel.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import AppKit
import Combine

@MainActor
final class SuperSwitchViewModel: ObservableObject {
    @Published var targets: [SwitchTarget] = []
    @Published var showAddSheet = false
    @Published var editingTarget: SwitchTarget?
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var toastMessage: String?
    @Published var showToast = false
    
    init() {
        loadTargets()
        setupShortcutCallbacks()
    }
    
    func loadTargets() {
        targets = StorageManager.shared.loadSwitchTargets()
        refreshShortcuts()
    }
    
    func saveTargets() {
        StorageManager.shared.saveSwitchTargets(targets)
        refreshShortcuts()
    }
    
    func addTarget(_ target: SwitchTarget) {
        targets.append(target)
        saveTargets()
        showToast(message: "Added \(target.name)")
    }
    
    func updateTarget(_ target: SwitchTarget) {
        if let index = targets.firstIndex(where: { $0.id == target.id }) {
            targets[index] = target
            saveTargets()
            showToast(message: "Updated \(target.name)")
        }
    }
    
    func deleteTarget(_ target: SwitchTarget) {
        targets.removeAll { $0.id == target.id }
        saveTargets()
        SoundEffectManager.shared.playTabDeleted()
    }
    
    func switchToTarget(_ target: SwitchTarget) {
        SoundEffectManager.shared.playSwitchSuccess()
        
        // Try to activate running application first
        let runningApps = NSWorkspace.shared.runningApplications
        if let app = runningApps.first(where: { $0.bundleIdentifier == target.bundleIdentifier }) {
            app.activate(options: [.activateAllWindows])
            showToast(message: "Switched to \(target.name)")
            return
        }
        
        // Try to launch application
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: target.bundleIdentifier) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: config) { app, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to launch \(target.name): \(error.localizedDescription)"
                        self.showError = true
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showToast(message: "Launched \(target.name)")
                    }
                }
            }
        } else {
            errorMessage = "Application not found: \(target.bundleIdentifier)"
            showError = true
        }
    }
    
    func switchToTarget(byID id: UUID) {
        if let target = targets.first(where: { $0.id == id }) {
            switchToTarget(target)
        }
    }
    
    func getRunningApps() -> [(name: String, bundleID: String)] {
        let apps = NSWorkspace.shared.runningApplications
        return apps.compactMap { app in
            guard let name = app.localizedName, let bundleID = app.bundleIdentifier, !app.isHidden else { return nil }
            return (name: name, bundleID: bundleID)
        }.sorted { $0.name < $1.name }
    }
    
    private func refreshShortcuts() {
        ShortcutManager.shared.unregisterAllShortcuts()
        for target in targets where target.isValidShortcut {
            _ = ShortcutManager.shared.registerShortcut(for: target)
        }
    }
    
    private func setupShortcutCallbacks() {
        ShortcutManager.shared.addHotKeyHandler { [weak self] id in
            self?.switchToTarget(byID: id)
        }
    }
    
    private func showToast(message: String) {
        toastMessage = message
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showToast = false
        }
    }
}
