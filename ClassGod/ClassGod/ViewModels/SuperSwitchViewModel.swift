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

enum SuperSwitchCatalogPolicy {
    static func filteredTargets(_ targets: [SwitchTarget], query: String) -> [SwitchTarget] {
        let tokens = query
            .split(whereSeparator: \.isWhitespace)
            .map { $0.lowercased() }
        guard !tokens.isEmpty else { return targets }
        return targets.filter { target in
            let searchableText = "\(target.name) \(target.bundleIdentifier)".lowercased()
            return tokens.allSatisfy(searchableText.contains)
        }
    }
}

struct SuperSwitchTargetDraft: Equatable {
    let name: String
    let bundleIdentifier: String

    init(name: String, bundleIdentifier: String) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.bundleIdentifier = bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool { !name.isEmpty && !bundleIdentifier.isEmpty }
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
    @Published private(set) var runningBundleIdentifiers: Set<String> = []
    
    private var toastWorkItem: DispatchWorkItem?
    private var toastState = TransientFeedbackState<String>()
    private var workspaceCancellables: Set<AnyCancellable> = []
    
    init() {
        _targets = Published(initialValue: StorageManager.shared.loadSwitchTargets())
        refreshRunningApplications()
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification]
            .forEach { notification in
                workspaceCenter.publisher(for: notification)
                    .receive(on: RunLoop.main)
                    .sink { [weak self] _ in self?.refreshRunningApplications() }
                    .store(in: &workspaceCancellables)
            }
    }
    
    deinit {
        toastWorkItem?.cancel()
    }
    
    func loadTargets() {
        targets = StorageManager.shared.loadSwitchTargets()
    }
    
    func saveTargets() {
        GhostProtocolController.shared.prepareForShortcutChanges()
        StorageManager.shared.saveSwitchTargets(targets)
        ShortcutCatalogCoordinator.shared.reload()
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
        saveTargets()
        SoundEffectManager.shared.playTabDeleted()
        HapticManager.shared.warning()
        showToast(message: String(format: String(localized: "superswitch.toast.deleted"), target.name))
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
        var seenBundleIdentifiers: Set<String> = []
        return NSWorkspace.shared.runningApplications.compactMap { app in
            guard app.activationPolicy == .regular,
                  let name = app.localizedName,
                  let bundleID = app.bundleIdentifier,
                  bundleID != Bundle.main.bundleIdentifier,
                  seenBundleIdentifiers.insert(bundleID).inserted else { return nil }
            return (name: name, bundleID: bundleID)
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func refreshRunningApplications() {
        runningBundleIdentifiers = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
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
