import AppKit
import Combine
import Foundation

enum GhostProtocolState: Equatable {
    case idle
    case deploying
    case deployed
    case restoring
}

private struct GhostWorkspaceSnapshot {
    var hiddenBundleIdentifiers: [String]
    let originalFrontmostBundleIdentifier: String?
    let coverBundleIdentifier: String
    var shouldHideCoverOnRestore: Bool
}

@MainActor
final class GhostProtocolController: ObservableObject {
    static let shared = GhostProtocolController()

    @Published var settings: GhostProtocolSettings {
        didSet {
            guard settings != oldValue else { return }
            StorageManager.shared.saveGhostProtocolSettings(settings)
            if settings.shortcutKey != oldValue.shortcutKey
                || settings.shortcutModifiers != oldValue.shortcutModifiers {
                registerShortcut()
            }
            if state == .idle {
                statusMessage = String(localized: "ghost.status.ready")
            }
            refreshPreview()
        }
    }
    @Published private(set) var destinations: [GhostDestination] = []
    @Published private(set) var state: GhostProtocolState = .idle
    @Published private(set) var previewHideCount = 0
    @Published private(set) var isTargetAvailable = false
    @Published private(set) var isShortcutRegistered = false
    @Published private(set) var statusMessage = String(localized: "ghost.status.ready")

    var selectedDestination: GhostDestination? {
        destinations.first { $0.bundleIdentifier == settings.targetBundleIdentifier }
    }

    var isBusy: Bool {
        state == .deploying || state == .restoring
    }

    private var snapshot: GhostWorkspaceSnapshot?
    private var hotKeyID: UInt32?
    private let workspace = NSWorkspace.shared
    private let activationVerificationAttempts = 10

    private init() {
        settings = StorageManager.shared.loadGhostProtocolSettings()
        refreshDestinations()
        registerShortcut()
        refreshPreview()
    }

    func refresh() {
        refreshDestinations()
        refreshPreview()
    }

    func toggle() {
        switch state {
        case .idle:
            deploy()
        case .deployed:
            restore()
        case .deploying, .restoring:
            break
        }
    }

    func deploy() {
        guard state == .idle else { return }
        refresh()
        guard let destination = selectedDestination, isTargetAvailable else {
            fail(String(localized: "ghost.error.target_unavailable"))
            return
        }

        let plan = makeCurrentPlan(targetBundleIdentifier: destination.bundleIdentifier)
        let coverApplication = runningApplication(bundleIdentifier: destination.bundleIdentifier)
        let shouldHideCoverOnRestore = coverApplication == nil || coverApplication?.isHidden == true
        state = .deploying
        statusMessage = String(localized: "ghost.status.deploying")

        activate(destination: destination) { [weak self] activated in
            guard let self, self.state == .deploying else { return }
            guard activated else {
                self.restoreCoverAfterFailedActivation(
                    bundleIdentifier: destination.bundleIdentifier,
                    shouldHide: shouldHideCoverOnRestore
                )
                self.state = .idle
                self.fail(String(localized: "ghost.error.activation_failed"))
                return
            }

            var hiddenBundleIdentifiers: [String] = []
            if self.settings.hideOtherApplications {
                for bundleIdentifier in plan.bundleIdentifiersToHide {
                    guard let application = self.runningApplication(bundleIdentifier: bundleIdentifier) else { continue }
                    if application.hide() {
                        hiddenBundleIdentifiers.append(bundleIdentifier)
                    }
                }
            }

            self.snapshot = GhostWorkspaceSnapshot(
                hiddenBundleIdentifiers: hiddenBundleIdentifiers,
                originalFrontmostBundleIdentifier: plan.originalFrontmostBundleIdentifier,
                coverBundleIdentifier: destination.bundleIdentifier,
                shouldHideCoverOnRestore: shouldHideCoverOnRestore
            )
            self.state = .deployed
            self.statusMessage = String(
                format: String(localized: "ghost.status.deployed_format"),
                destination.name,
                hiddenBundleIdentifiers.count,
                self.settings.hideOtherApplications ? plan.bundleIdentifiersToHide.count : 0
            )
            SoundEffectManager.shared.playGhostDeploy()
            if hiddenBundleIdentifiers.count == plan.bundleIdentifiersToHide.count {
                HapticManager.shared.success()
            } else {
                HapticManager.shared.warning()
            }
            self.refreshPreview()
        }
    }

    func restore() {
        guard state == .deployed, var snapshot else { return }
        state = .restoring
        statusMessage = String(localized: "ghost.status.restoring")

        var failedBundleIdentifiers: [String] = []
        for bundleIdentifier in snapshot.hiddenBundleIdentifiers {
            guard let application = runningApplication(bundleIdentifier: bundleIdentifier) else { continue }
            if application.isHidden && !application.unhide() {
                failedBundleIdentifiers.append(bundleIdentifier)
            }
        }

        if let originalBundleIdentifier = snapshot.originalFrontmostBundleIdentifier,
           let application = runningApplication(bundleIdentifier: originalBundleIdentifier) {
            _ = application.activate(options: [.activateAllWindows])
        }

        var coverRestoreFailed = false
        if snapshot.shouldHideCoverOnRestore,
           let coverApplication = runningApplication(bundleIdentifier: snapshot.coverBundleIdentifier),
           !coverApplication.isHidden {
            coverRestoreFailed = !coverApplication.hide()
        }

        if failedBundleIdentifiers.isEmpty && !coverRestoreFailed {
            let restoredCount = snapshot.hiddenBundleIdentifiers.count
            self.snapshot = nil
            state = .idle
            refreshDestinations()
            statusMessage = String(
                format: String(localized: "ghost.status.restored_format"),
                restoredCount
            )
            SoundEffectManager.shared.playGhostRestore()
            HapticManager.shared.success()
        } else {
            snapshot.hiddenBundleIdentifiers = failedBundleIdentifiers
            snapshot.shouldHideCoverOnRestore = coverRestoreFailed
            self.snapshot = snapshot
            state = .deployed
            statusMessage = String(
                format: String(localized: "ghost.error.restore_partial_format"),
                failedBundleIdentifiers.count + (coverRestoreFailed ? 1 : 0)
            )
            SoundEffectManager.shared.playSwitchFailure()
            HapticManager.shared.warning()
        }
        refreshPreview()
    }

    func shutdown() {
        if let snapshot {
            for bundleIdentifier in snapshot.hiddenBundleIdentifiers {
                guard let application = runningApplication(bundleIdentifier: bundleIdentifier), application.isHidden else { continue }
                if !application.unhide() {
                    _ = application.activate(options: [.activateAllWindows])
                }
            }
            if let originalBundleIdentifier = snapshot.originalFrontmostBundleIdentifier,
               let application = runningApplication(bundleIdentifier: originalBundleIdentifier) {
                _ = application.activate(options: [.activateAllWindows])
            }
            if snapshot.shouldHideCoverOnRestore,
               let coverApplication = runningApplication(bundleIdentifier: snapshot.coverBundleIdentifier),
               !coverApplication.isHidden {
                _ = coverApplication.hide()
            }
            self.snapshot = nil
            state = .idle
        }
        if let hotKeyID {
            ShortcutManager.shared.unregisterCustomHotKey(id: hotKeyID)
            self.hotKeyID = nil
        }
        isShortcutRegistered = false
    }

    func prepareForShortcutChanges() {
        if let hotKeyID {
            ShortcutManager.shared.unregisterCustomHotKey(id: hotKeyID)
            self.hotKeyID = nil
        }
        isShortcutRegistered = false
    }

    func reconcileShortcutAfterChanges() {
        refreshDestinations()
        registerShortcut()
        refreshPreview()
    }

    private func refreshDestinations() {
        let previousDestination = selectedDestination
        var refreshedDestinations = GhostDestination.merged(with: StorageManager.shared.loadSwitchTargets())
        if !refreshedDestinations.contains(where: { $0.bundleIdentifier == settings.targetBundleIdentifier }) {
            if state != .idle, let previousDestination {
                refreshedDestinations.append(previousDestination)
            } else {
                destinations = refreshedDestinations
                settings.targetBundleIdentifier = GhostProtocolSettings.default.targetBundleIdentifier
                return
            }
        }
        destinations = refreshedDestinations
    }

    private func refreshPreview() {
        guard let destination = selectedDestination else {
            isTargetAvailable = false
            previewHideCount = 0
            return
        }
        isTargetAvailable = runningApplication(bundleIdentifier: destination.bundleIdentifier) != nil
            || workspace.urlForApplication(withBundleIdentifier: destination.bundleIdentifier) != nil
        previewHideCount = settings.hideOtherApplications
            ? makeCurrentPlan(targetBundleIdentifier: destination.bundleIdentifier).bundleIdentifiersToHide.count
            : 0
    }

    private func makeCurrentPlan(targetBundleIdentifier: String) -> GhostProtocolPlan {
        let frontmostBundleIdentifier = workspace.frontmostApplication?.bundleIdentifier
        let applications = workspace.runningApplications.map { application in
            GhostApplicationDescriptor(
                bundleIdentifier: application.bundleIdentifier,
                isRegular: application.activationPolicy == .regular,
                isHidden: application.isHidden,
                isTerminated: application.isTerminated,
                isFrontmost: application.bundleIdentifier == frontmostBundleIdentifier
            )
        }
        return GhostProtocolPlanner.makePlan(
            applications: applications,
            targetBundleIdentifier: targetBundleIdentifier,
            ownBundleIdentifier: Bundle.main.bundleIdentifier ?? "com.hanazar.classgod"
        )
    }

    private func activate(destination: GhostDestination, completion: @escaping (Bool) -> Void) {
        if let application = runningApplication(bundleIdentifier: destination.bundleIdentifier) {
            if application.isHidden {
                _ = application.unhide()
            }
            guard application.activate(options: [.activateAllWindows]) else {
                completion(false)
                return
            }
            verifyActivation(
                of: application,
                bundleIdentifier: destination.bundleIdentifier,
                attemptsRemaining: activationVerificationAttempts,
                completion: completion
            )
            return
        }

        guard let applicationURL = workspace.urlForApplication(withBundleIdentifier: destination.bundleIdentifier) else {
            completion(false)
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        workspace.openApplication(at: applicationURL, configuration: configuration) { application, error in
            DispatchQueue.main.async {
                guard let application, error == nil else {
                    completion(false)
                    return
                }
                self.verifyActivation(
                    of: application,
                    bundleIdentifier: destination.bundleIdentifier,
                    attemptsRemaining: self.activationVerificationAttempts,
                    completion: completion
                )
            }
        }
    }

    private func verifyActivation(
        of application: NSRunningApplication,
        bundleIdentifier: String,
        attemptsRemaining: Int,
        completion: @escaping (Bool) -> Void
    ) {
        if workspace.frontmostApplication?.bundleIdentifier == bundleIdentifier {
            completion(true)
            return
        }
        guard attemptsRemaining > 0, !application.isTerminated else {
            completion(false)
            return
        }
        _ = application.activate(options: [.activateAllWindows])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self, weak application] in
            guard let self, let application else {
                completion(false)
                return
            }
            self.verifyActivation(
                of: application,
                bundleIdentifier: bundleIdentifier,
                attemptsRemaining: attemptsRemaining - 1,
                completion: completion
            )
        }
    }

    private func runningApplication(bundleIdentifier: String) -> NSRunningApplication? {
        workspace.runningApplications.first { $0.bundleIdentifier == bundleIdentifier && !$0.isTerminated }
    }

    private func restoreCoverAfterFailedActivation(bundleIdentifier: String, shouldHide: Bool) {
        guard shouldHide,
              let application = runningApplication(bundleIdentifier: bundleIdentifier),
              !application.isHidden else { return }
        _ = application.hide()
    }

    private func registerShortcut() {
        if let hotKeyID {
            ShortcutManager.shared.unregisterCustomHotKey(id: hotKeyID)
            self.hotKeyID = nil
        }
        let shortcutManager = ShortcutManager.shared
        guard let keyCode = shortcutManager.keyCode(for: settings.shortcutKey),
              !isReservedClassGodShortcut(
                  keyCode: keyCode,
                  cocoaModifiers: UInt32(settings.shortcutModifiers)
              ) else {
            isShortcutRegistered = false
            return
        }
        hotKeyID = shortcutManager.registerCustomHotKey(
            keyCode: keyCode,
            cocoaModifiers: UInt32(settings.shortcutModifiers)
        ) { [weak self] in
            self?.toggle()
        }
        isShortcutRegistered = hotKeyID != nil
    }

    private func isReservedClassGodShortcut(keyCode: UInt32, cocoaModifiers: UInt32) -> Bool {
        let shortcutManager = ShortcutManager.shared
        let makeShortcut: (UInt32, UInt) -> CarbonShortcut = { candidateKeyCode, candidateModifiers in
            CarbonShortcut(
                keyCode: candidateKeyCode,
                modifiers: shortcutManager.cocoaToCarbonModifiers(candidateModifiers)
            )
        }

        let preferences = PreferencesManager.shared.preferences
        var reservedShortcuts: Set<CarbonShortcut> = [
            makeShortcut(preferences.showPopoverKeyCode, UInt(preferences.showPopoverModifiers)),
            CarbonShortcut(keyCode: 0x61, modifiers: 0)
        ]
        for tab in StorageManager.shared.loadTabs() where tab.isValidShortcut {
            if let candidateKeyCode = shortcutManager.keyCode(for: tab.shortcutKey) {
                reservedShortcuts.insert(makeShortcut(candidateKeyCode, tab.shortcutModifiers))
            }
        }
        for target in StorageManager.shared.loadSwitchTargets() where target.isValidShortcut {
            if let candidateKeyCode = shortcutManager.keyCode(for: target.shortcutKey) {
                reservedShortcuts.insert(makeShortcut(candidateKeyCode, target.shortcutModifiers))
            }
        }
        let shortcut = makeShortcut(keyCode, UInt(cocoaModifiers))
        return GhostShortcutPolicy.isReserved(shortcut, reservedShortcuts: reservedShortcuts)
    }

    private func fail(_ message: String) {
        statusMessage = message
        SoundEffectManager.shared.playSwitchFailure()
        HapticManager.shared.warning()
    }
}
