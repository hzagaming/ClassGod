import AppKit
import Combine
import Foundation

struct ShortcutGesture: Hashable {
    let key: String
    let modifiers: UInt

    init(key: String, modifiers: UInt) {
        self.key = key.uppercased()
        self.modifiers = ShortcutModifierPolicy.captured(modifiers)
    }
}

struct ShortcutCatalogRefreshPlan: Equatable {
    let unregisterIDs: Set<UUID>
    let registrationIDs: [UUID]
    let configuredShortcutIDs: Set<UUID>
    let conflictingIDs: Set<UUID>

    static func make(
        previouslyRegistered: Set<UUID>,
        tabs: [BrowserTab],
        targets: [SwitchTarget]
    ) -> ShortcutCatalogRefreshPlan {
        let candidates = tabs.filter(\.isValidShortcut).map {
            ($0.id, ShortcutGesture(key: $0.shortcutKey, modifiers: $0.shortcutModifiers))
        } + targets.filter(\.isValidShortcut).map {
            ($0.id, ShortcutGesture(key: $0.shortcutKey, modifiers: $0.shortcutModifiers))
        }
        let duplicateIDs = Set(
            Dictionary(grouping: candidates) { $0.0 }
                .filter { $0.value.count > 1 }
                .keys
        )
        var claimedGestures: Set<ShortcutGesture> = []
        var registrationIDs: [UUID] = []
        var conflictingIDs: Set<UUID> = []

        for (id, gesture) in candidates {
            guard !duplicateIDs.contains(id) else {
                conflictingIDs.insert(id)
                continue
            }
            if claimedGestures.insert(gesture).inserted {
                registrationIDs.append(id)
            } else {
                conflictingIDs.insert(id)
            }
        }

        return ShortcutCatalogRefreshPlan(
            unregisterIDs: previouslyRegistered,
            registrationIDs: registrationIDs,
            configuredShortcutIDs: Set(candidates.map(\.0)),
            conflictingIDs: conflictingIDs
        )
    }
}

struct ShortcutCatalogState: Equatable {
    let configuredShortcutIDs: Set<UUID>
    let registeredIDs: Set<UUID>
    let failedIDs: Set<UUID>
    let conflictingIDs: Set<UUID>

    static let empty = ShortcutCatalogState(
        configuredShortcutIDs: [],
        registeredIDs: [],
        failedIDs: [],
        conflictingIDs: []
    )

    static func make(
        plan: ShortcutCatalogRefreshPlan,
        registeredIDs: Set<UUID>
    ) -> ShortcutCatalogState {
        let attemptedIDs = Set(plan.registrationIDs)
        let successfulIDs = registeredIDs.intersection(attemptedIDs)
        return ShortcutCatalogState(
            configuredShortcutIDs: plan.configuredShortcutIDs,
            registeredIDs: successfulIDs,
            failedIDs: attemptedIDs.subtracting(successfulIDs),
            conflictingIDs: plan.conflictingIDs
        )
    }
}

@MainActor
final class ShortcutCatalogCoordinator: ObservableObject {
    static let shared = ShortcutCatalogCoordinator()

    @Published private(set) var state = ShortcutCatalogState.empty
    private(set) var isRunning = false

    private init() {}

    func start() {
        guard !isRunning else { return }
        isRunning = true
        reload()
    }

    func reload() {
        guard isRunning else { return }
        let tabs = StorageManager.shared.loadTabs()
        let targets = StorageManager.shared.loadSwitchTargets()
        let plan = ShortcutCatalogRefreshPlan.make(
            previouslyRegistered: state.registeredIDs,
            tabs: tabs,
            targets: targets
        )

        for id in plan.unregisterIDs {
            ShortcutManager.shared.unregisterShortcut(for: id)
        }

        var registeredIDs: Set<UUID> = []
        let tabsByID = Dictionary(tabs.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let targetsByID = Dictionary(targets.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for id in plan.registrationIDs {
            let registered: Bool
            if let tab = tabsByID[id] {
                registered = ShortcutManager.shared.registerShortcut(for: tab)
            } else if let target = targetsByID[id] {
                registered = ShortcutManager.shared.registerShortcut(for: target)
            } else {
                registered = false
            }
            if registered {
                registeredIDs.insert(id)
            }
        }

        state = ShortcutCatalogState.make(plan: plan, registeredIDs: registeredIDs)
    }

    func stop() {
        guard isRunning else { return }
        for id in state.registeredIDs {
            ShortcutManager.shared.unregisterShortcut(for: id)
        }
        state = .empty
        isRunning = false
    }
}
