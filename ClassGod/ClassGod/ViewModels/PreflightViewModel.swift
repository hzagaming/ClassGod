import AppKit
import Combine
import Foundation

enum PreflightStatus: Int, Comparable {
    case ready
    case attention
    case blocked

    static func < (lhs: PreflightStatus, rhs: PreflightStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum PreflightCheckKind: CaseIterable, Identifiable {
    case accessibility
    case appleEvents
    case destinations
    case applications
    case urls
    case shortcuts

    var id: Self { self }
}

struct PreflightMetrics: Equatable {
    let destinationCount: Int
    let unavailableApplicationCount: Int
    let invalidURLCount: Int
    let configuredShortcutCount: Int
    let registeredShortcutCount: Int
    let failedShortcutCount: Int
    let conflictingShortcutCount: Int
}

struct PreflightReport: Equatable {
    let status: PreflightStatus
    let checks: [PreflightCheckKind: PreflightStatus]
    let metrics: PreflightMetrics

    subscript(kind: PreflightCheckKind) -> PreflightStatus {
        checks[kind] ?? .blocked
    }
}

enum PreflightURLPolicy {
    static func isValidWebURL(_ value: String) -> Bool {
        guard let components = URLComponents(
            string: value.trimmingCharacters(in: .whitespacesAndNewlines)
        ), let scheme = components.scheme?.lowercased(),
           scheme == "http" || scheme == "https",
           components.host?.isEmpty == false else { return false }
        return true
    }
}

enum PreflightApplicationPolicy {
    static func requiredBundleIdentifiers(
        tabs: [BrowserTab],
        targets: [SwitchTarget]
    ) -> [String] {
        var seen: Set<String> = []
        let identifiers = tabs.map { $0.browser.bundleIdentifier }
            + targets.map { $0.bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines) }
        return identifiers.filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}

enum PreflightReportPolicy {
    static func make(
        accessibilityGranted: Bool,
        appleEventsGranted: Bool,
        tabs: [BrowserTab],
        targets: [SwitchTarget],
        installedBundleIdentifiers: Set<String>,
        shortcutState: ShortcutCatalogState
    ) -> PreflightReport {
        let destinationCount = tabs.count + targets.count
        let requiredApplications = Set(PreflightApplicationPolicy.requiredBundleIdentifiers(
            tabs: tabs,
            targets: targets
        ))
        let invalidApplicationCount = targets.count {
            $0.bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let availableApplications = requiredApplications.intersection(installedBundleIdentifiers)
        let unavailableApplicationCount = requiredApplications.count
            - availableApplications.count
            + invalidApplicationCount
        let validURLCount = tabs.count { PreflightURLPolicy.isValidWebURL($0.url) }
        let invalidURLCount = tabs.count - validURLCount

        let applicationStatus: PreflightStatus
        if unavailableApplicationCount == 0 {
            applicationStatus = .ready
        } else if availableApplications.isEmpty {
            applicationStatus = .blocked
        } else {
            applicationStatus = .attention
        }

        let urlStatus: PreflightStatus
        if tabs.isEmpty {
            urlStatus = .ready
        } else if invalidURLCount == 0 {
            urlStatus = .ready
        } else if validURLCount == 0 && targets.isEmpty {
            urlStatus = .blocked
        } else {
            urlStatus = .attention
        }

        let shortcutStatus: PreflightStatus
        if shortcutState.configuredShortcutIDs.isEmpty {
            shortcutStatus = .attention
        } else if shortcutState.registeredIDs.isEmpty {
            shortcutStatus = .blocked
        } else if !shortcutState.failedIDs.isEmpty
                    || !shortcutState.conflictingIDs.isEmpty
                    || shortcutState.registeredIDs.count < shortcutState.configuredShortcutIDs.count {
            shortcutStatus = .attention
        } else {
            shortcutStatus = .ready
        }

        let checks: [PreflightCheckKind: PreflightStatus] = [
            .accessibility: accessibilityGranted ? .ready : .blocked,
            .appleEvents: appleEventsGranted ? .ready : .blocked,
            .destinations: destinationCount > 0 ? .ready : .blocked,
            .applications: applicationStatus,
            .urls: urlStatus,
            .shortcuts: shortcutStatus,
        ]
        let overall = checks.values.max() ?? .blocked
        return PreflightReport(
            status: overall,
            checks: checks,
            metrics: PreflightMetrics(
                destinationCount: destinationCount,
                unavailableApplicationCount: unavailableApplicationCount,
                invalidURLCount: invalidURLCount,
                configuredShortcutCount: shortcutState.configuredShortcutIDs.count,
                registeredShortcutCount: shortcutState.registeredIDs.count,
                failedShortcutCount: shortcutState.failedIDs.count,
                conflictingShortcutCount: shortcutState.conflictingIDs.count
            )
        )
    }
}

@MainActor
final class PreflightViewModel: ObservableObject {
    @Published private(set) var report: PreflightReport
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastCheckedAt: Date?

    private let permissionService = PermissionCenterService.shared
    private let shortcutCatalog = ShortcutCatalogCoordinator.shared
    private var cancellables: Set<AnyCancellable> = []

    init() {
        report = PreflightReportPolicy.make(
            accessibilityGranted: false,
            appleEventsGranted: false,
            tabs: [],
            targets: [],
            installedBundleIdentifiers: [],
            shortcutState: .empty
        )

        Publishers.CombineLatest(permissionService.$statuses, shortcutCatalog.$state)
            .sink { [weak self] _, _ in self?.rebuildReport() }
            .store(in: &cancellables)

        permissionService.$isChecking
            .removeDuplicates()
            .sink { [weak self] checking in
                self?.isRefreshing = checking
                if !checking { self?.updateLastCheckedAt() }
            }
            .store(in: &cancellables)

        let workspace = NSWorkspace.shared.notificationCenter
        [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification]
            .forEach { notification in
                workspace.publisher(for: notification)
                    .sink { [weak self] _ in self?.rebuildReport() }
                    .store(in: &cancellables)
            }
        rebuildReport()
    }

    func refresh() {
        shortcutCatalog.reload()
        permissionService.refreshAll()
        rebuildReport()
    }

    private func rebuildReport() {
        let tabs = StorageManager.shared.loadTabs()
        let targets = StorageManager.shared.loadSwitchTargets()
        let requiredBundleIdentifiers = PreflightApplicationPolicy.requiredBundleIdentifiers(
            tabs: tabs,
            targets: targets
        )
        let installedBundleIdentifiers = Set(requiredBundleIdentifiers.filter {
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) != nil
        })
        report = PreflightReportPolicy.make(
            accessibilityGranted: permissionService.statuses[.accessibility]?.state.isGranted == true,
            appleEventsGranted: permissionService.statuses[.appleEvents]?.state.isGranted == true,
            tabs: tabs,
            targets: targets,
            installedBundleIdentifiers: installedBundleIdentifiers,
            shortcutState: shortcutCatalog.state
        )
        updateLastCheckedAt()
    }

    private func updateLastCheckedAt() {
        lastCheckedAt = permissionService.statuses.values.map(\.lastChecked).max()
    }
}
