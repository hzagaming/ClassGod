//
//  SuperSwitchViewModel.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import AppKit
import Combine

nonisolated enum AppSwitchOutcome: Equatable {
    case success
    case failure

    static func activation(didActivate: Bool) -> AppSwitchOutcome {
        didActivate ? .success : .failure
    }

    static func launch(hasApplication: Bool, hasError: Bool) -> AppSwitchOutcome {
        hasApplication && !hasError ? .success : .failure
    }
}

@MainActor
final class SuperSwitchViewModel: ObservableObject {
    @Published var targets: [SwitchTarget] = []
    @Published var showAddSheet = false
    @Published var editingTarget: SwitchTarget?
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var toastMessage: String?
    @Published var showToast = false
    
    private var registeredTargetIDs: Set<UUID> = []
    private var toastWorkItem: DispatchWorkItem?
    private var toastState = TransientFeedbackState<String>()
    
    init() {
        _targets = Published(initialValue: StorageManager.shared.loadSwitchTargets())
        refreshShortcuts()
    }
    
    deinit {
        toastWorkItem?.cancel()
        let ids = registeredTargetIDs
        Task { @MainActor in
            for id in ids {
                ShortcutManager.shared.unregisterShortcut(for: id)
            }
        }
    }
    
    func loadTargets() {
        targets = StorageManager.shared.loadSwitchTargets()
        refreshShortcuts()
    }
    
    func saveTargets() {
        GhostProtocolController.shared.prepareForShortcutChanges()
        StorageManager.shared.saveSwitchTargets(targets)
        refreshShortcuts()
        GhostProtocolController.shared.reconcileShortcutAfterChanges()
    }
    
    func addTarget(_ target: SwitchTarget) {
        targets.append(target)
        saveTargets()
        showToast(message: String(format: String(localized: "toast.added"), target.name))
    }
    
    func updateTarget(_ target: SwitchTarget) {
        if let index = targets.firstIndex(where: { $0.id == target.id }) {
            targets[index] = target
            saveTargets()
            showToast(message: String(format: String(localized: "toast.updated"), target.name))
        }
    }
    
    func deleteTarget(_ target: SwitchTarget) {
        targets.removeAll { $0.id == target.id }
        ShortcutManager.shared.unregisterShortcut(for: target.id)
        registeredTargetIDs.remove(target.id)
        saveTargets()
        SoundEffectManager.shared.playTabDeleted()
    }
    
    func switchToTarget(_ target: SwitchTarget) {
        // Try to activate running application first
        let runningApps = NSWorkspace.shared.runningApplications
        if let app = runningApps.first(where: { $0.bundleIdentifier == target.bundleIdentifier }) {
            let outcome = AppSwitchOutcome.activation(
                didActivate: app.activate(options: [.activateAllWindows])
            )
            if outcome == .success {
                SoundEffectManager.shared.playSwitchSuccess()
                HapticManager.shared.success()
                showToast(message: String(format: String(localized: "toast.switched_to"), target.name))
            } else {
                presentSwitchFailure(target: target, detail: String(localized: "error.unknown"))
            }
            return
        }
        
        // Try to launch application
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: target.bundleIdentifier) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: config) { [weak self] app, error in
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    if AppSwitchOutcome.launch(hasApplication: app != nil, hasError: error != nil) == .success {
                        SoundEffectManager.shared.playSwitchSuccess()
                        HapticManager.shared.success()
                        self.showToast(message: String(format: String(localized: "toast.launched"), target.name))
                    } else {
                        self.presentSwitchFailure(
                            target: target,
                            detail: error?.localizedDescription ?? String(localized: "error.unknown")
                        )
                    }
                }
            }
        } else {
            errorMessage = String(format: String(localized: "error.app_not_found"), target.bundleIdentifier)
            showError = true
            SoundEffectManager.shared.playSwitchFailure()
            HapticManager.shared.warning()
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
        let currentIDs = Set(targets.map { $0.id })
        let toRemove = registeredTargetIDs.subtracting(currentIDs)
        for id in toRemove {
            ShortcutManager.shared.unregisterShortcut(for: id)
        }
        for target in targets where target.isValidShortcut {
            ShortcutManager.shared.unregisterShortcut(for: target.id)
            _ = ShortcutManager.shared.registerShortcut(for: target)
        }
        registeredTargetIDs = currentIDs
    }

    private func presentSwitchFailure(target: SwitchTarget, detail: String) {
        errorMessage = String(format: String(localized: "error.launch_failed"), target.name, detail)
        showError = true
        SoundEffectManager.shared.playSwitchFailure()
        HapticManager.shared.warning()
    }
    
    private func showToast(message: String) {
        toastWorkItem?.cancel()
        let token = toastState.present(message)
        toastMessage = message
        showToast = true
        let item = DispatchWorkItem { [weak self] in
            guard let self, self.toastState.dismiss(ifCurrent: token) else { return }
            self.showToast = false
            self.toastWorkItem = nil
        }
        toastWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: item)
    }
}
