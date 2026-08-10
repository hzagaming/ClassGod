import Contacts
import EventKit
import Photos
import Testing
import UserNotifications
@testable import ClassGod

@Suite("Permission Center catalog")
struct PermissionCenterTests {
    @Test("Every permission refresh requested during a check is retained")
    func coalescesPermissionRefreshes() {
        #expect(PermissionRefreshQueuePolicy.shouldQueueFollowUp(isChecking: true))
        #expect(!PermissionRefreshQueuePolicy.shouldQueueFollowUp(isChecking: false))
    }

    @Test("Live permission checks run at a millisecond-scale interval")
    func livePermissionRefreshInterval() {
        #expect(PermissionLiveRefreshPolicy.intervalNanoseconds == 100_000_000)
        #expect(PermissionLiveRefreshPolicy.fullScanStride == 10)
        #expect(!PermissionLiveRefreshPolicy.requiresFullScan(tick: 1))
        #expect(PermissionLiveRefreshPolicy.requiresFullScan(tick: 10))
    }

    @Test("Live checks poll unresolved access immediately and granted access periodically")
    func livePermissionProbePlan() {
        let states = Dictionary(uniqueKeysWithValues: PermissionType.allCases.map { type in
            (type, type.requiresManualReview
                ? PermissionAuthorizationState.manualReview
                : PermissionAuthorizationState.granted)
        })
        var statuses = makeStatuses(states)
        statuses[.camera] = PermissionStatus(
            type: .camera,
            state: .denied,
            lastChecked: .distantPast,
            detail: nil
        )

        #expect(PermissionLiveRefreshPolicy.immediateTypes(statuses: statuses) == [.camera])
    }

    @Test("Live checks publish UI updates only when authorization changes")
    func authorizationChangeDetection() {
        let current = makeStatuses([.camera: .denied])
        let sameState = [
            PermissionType.camera: PermissionStatus(
                type: .camera,
                state: .denied,
                lastChecked: .now,
                detail: nil
            )
        ]
        let granted = makeStatuses([.camera: .granted])

        #expect(!PermissionStatusChangePolicy.hasChanges(current: current, updated: sameState))
        #expect(PermissionStatusChangePolicy.hasChanges(current: current, updated: granted))
    }

    @Test("Apple Events starts its target when the permission API cannot resolve it")
    func preparesAppleEventsTarget() {
        #expect(AppleEventsPermissionCheck.needsTargetLaunch(status: -600))
        #expect(!AppleEventsPermissionCheck.needsTargetLaunch(status: 0))
        #expect(!AppleEventsPermissionCheck.needsTargetLaunch(status: -1744))
    }

    @Test("Lists every supported ClassGod permission")
    func completeCatalog() {
        #expect(PermissionType.allCases.count == 20)
        #expect(PermissionType.allCases.contains(.inputMonitoring))
        #expect(PermissionType.allCases.contains(.filesAndFolders))
        #expect(PermissionType.allCases.contains(.developerTools))
        #expect(PermissionType.allCases.contains(.photos))
        #expect(PermissionType.allCases.contains(.mediaLibrary))
        #expect(PermissionType.allCases.contains(.speechRecognition))
        #expect(PermissionType.allCases.contains(.localNetwork))
        #expect(PermissionType.allCases.contains(.appManagement))
    }

    @Test("Every permission has complete UI metadata")
    func completeMetadata() {
        for permission in PermissionType.allCases {
            #expect(!permission.title.isEmpty)
            #expect(!permission.description.isEmpty)
            #expect(!permission.iconName.isEmpty)
            #expect(!permission.features.isEmpty)
            #expect(!permission.requestMethod.displayName.isEmpty)
            #expect(!permission.statusDetection.displayName.isEmpty)
        }
        #expect(PermissionType.appleEvents.canPrompt)
        #expect(PermissionType.accessibility.requestMethod == .nativePrompt)
        #expect(PermissionType.fullDiskAccess.requestMethod == .systemSettings)
        #expect(PermissionType.accessibility.statusDetection == .automatic)
        #expect(PermissionType.filesAndFolders.statusDetection == .manual)
    }

    @Test("Unqueryable system panes are marked for manual review")
    func manualReviewPermissions() {
        #expect(PermissionType.filesAndFolders.requiresManualReview)
        #expect(PermissionType.developerTools.requiresManualReview)
        #expect(PermissionType.localNetwork.requiresManualReview)
        #expect(PermissionType.appManagement.requiresManualReview)
        #expect(PermissionType.mediaLibrary.requiresManualReview)
        #expect(!PermissionType.photos.requiresManualReview)
        #expect(!PermissionType.speechRecognition.requiresManualReview)
    }

    @Test("Full review groups permissions by requirement with optional access last")
    func fullReviewScope() {
        #expect(Set(PermissionReviewPlan.all) == Set(PermissionType.allCases))
        let optionalStart = PermissionReviewPlan.all.firstIndex { $0.requirement == .optional }
        #expect(optionalStart != nil)
        if let optionalStart {
            #expect(PermissionReviewPlan.all[optionalStart...].allSatisfy { $0.requirement == .optional })
        }
    }

    @Test("Maximum permission review skips granted access and preserves catalog order")
    func pendingPermissionReviewScope() {
        let statuses = makeStatuses([
            .accessibility: .granted,
            .appleEvents: .denied,
            .inputMonitoring: .notDetermined,
            .filesAndFolders: .manualReview,
        ])

        let pending = PermissionReviewPlan.pending(
            types: [.filesAndFolders, .accessibility, .inputMonitoring, .appleEvents],
            statuses: statuses
        )

        #expect(pending == [.appleEvents, .inputMonitoring, .filesAndFolders])
    }

    @Test("Application gate blocks only on required permissions")
    func completePermissionGate() {
        let automatic = PermissionType.allCases.filter { !$0.requiresManualReview }
        let manual = Set(PermissionType.allCases.filter(\.requiresManualReview))
        let granted = makeStatuses(Dictionary(uniqueKeysWithValues: automatic.map { ($0, .granted) }))

        let unlocked = PermissionGatePolicy.progress(
            statuses: granted,
            manuallyConfirmed: manual
        )
        #expect(unlocked.completed == PermissionType.allCases.filter { $0.requirement == .required }.count)
        #expect(unlocked.total == PermissionType.allCases.filter { $0.requirement == .required }.count)
        #expect(unlocked.isUnlocked)

        var denied = granted
        denied[.accessibility] = PermissionStatus(
            type: .accessibility,
            state: .denied,
            lastChecked: .distantPast,
            detail: nil
        )
        let missingAutomatic = PermissionGatePolicy.progress(
            statuses: denied,
            manuallyConfirmed: manual
        )
        #expect(!missingAutomatic.isUnlocked)
        #expect(missingAutomatic.pending == [.accessibility])

        var optionalDenied = granted
        optionalDenied[.camera] = PermissionStatus(
            type: .camera,
            state: .denied,
            lastChecked: .distantPast,
            detail: nil
        )
        #expect(PermissionGatePolicy.progress(
            statuses: optionalDenied,
            manuallyConfirmed: []
        ).isUnlocked)
    }

    @Test("Permission gate can be skipped for the current session")
    func permissionGateSessionSkip() {
        #expect(!PermissionGateSessionPolicy.isUnlocked(progressUnlocked: false, skipped: false))
        #expect(PermissionGateSessionPolicy.isUnlocked(progressUnlocked: false, skipped: true))
        #expect(PermissionGateSessionPolicy.isUnlocked(progressUnlocked: true, skipped: false))
    }

    @Test("Manual permission confirmations only accept manual-review catalog entries")
    func sanitizesManualPermissionConfirmations() {
        let sanitized = PermissionGatePolicy.sanitizedManualConfirmations([
            .accessibility,
            .filesAndFolders,
            .developerTools,
        ])
        #expect(sanitized == [.filesAndFolders, .developerTools])
    }

    @Test("Manual review can only be confirmed after opening System Settings")
    func requiresManualReviewVisit() {
        #expect(PermissionGatePolicy.canSetManualConfirmation(
            for: .filesAndFolders,
            confirmed: true,
            didOpenSettings: true
        ))
        #expect(!PermissionGatePolicy.canSetManualConfirmation(
            for: .filesAndFolders,
            confirmed: true,
            didOpenSettings: false
        ))
        #expect(!PermissionGatePolicy.canSetManualConfirmation(
            for: .accessibility,
            confirmed: true,
            didOpenSettings: true
        ))
        #expect(PermissionGatePolicy.canSetManualConfirmation(
            for: .filesAndFolders,
            confirmed: false,
            didOpenSettings: false
        ))
    }

    @Test("Every permission communicates whether access is required")
    func permissionRequirementMetadata() {
        #expect(PermissionType.accessibility.requirement == .required)
        #expect(PermissionType.appleEvents.requirement == .required)
        #expect(PermissionType.inputMonitoring.requirement == .recommended)
        #expect(PermissionType.contacts.requirement == .optional)
        #expect(PermissionType.calendar.requirement == .optional)
    }

    @Test("Permission states never report manual review as denied")
    func permissionStateSemantics() {
        #expect(PermissionAuthorizationState.granted.isGranted)
        #expect(!PermissionAuthorizationState.denied.isGranted)
        #expect(!PermissionAuthorizationState.notDetermined.isGranted)
        #expect(!PermissionAuthorizationState.restricted.isGranted)
        #expect(!PermissionAuthorizationState.limited.isGranted)
        #expect(!PermissionAuthorizationState.manualReview.isGranted)
        #expect(PermissionAuthorizationState.manualReview.needsManualReview)
    }

    @Test("Only full authorization grades unlock the permission gate")
    func fullAuthorizationGrades() {
        #expect(PermissionAuthorizationPolicy.state(for: PHAuthorizationStatus.authorized) == .granted)
        #expect(PermissionAuthorizationPolicy.state(for: PHAuthorizationStatus.limited) == .limited)
        #expect(PermissionAuthorizationPolicy.state(for: CNAuthorizationStatus.authorized) == .granted)
        #expect(PermissionAuthorizationPolicy.state(for: EKAuthorizationStatus.fullAccess) == .granted)
        #expect(PermissionAuthorizationPolicy.state(for: EKAuthorizationStatus.writeOnly) == .limited)
        #expect(PermissionAuthorizationPolicy.state(for: UNAuthorizationStatus.authorized) == .granted)
        #expect(PermissionAuthorizationPolicy.state(for: UNAuthorizationStatus.provisional) == .limited)
    }

    @Test("Granted requests resolve immediately during live monitoring")
    func resolvesGrantedRequests() {
        let active: Set<PermissionType> = [.camera, .microphone]
        let statuses = makeStatuses([
            .camera: .granted,
            .microphone: .denied,
        ])

        #expect(PermissionRequestResolutionPolicy.resolved(active: active, statuses: statuses) == [.camera])
    }

    @Test("Every asynchronous prompt refreshes after its completion callback")
    func asynchronousPromptRefreshPolicy() {
        #expect(PermissionRequestRefreshPolicy.completionDriven == [
            .appleEvents, .microphone, .camera, .photos, .speechRecognition,
            .location, .notifications, .contacts, .reminders, .calendar, .bluetooth
        ])
        for permission in PermissionRequestRefreshPolicy.completionDriven {
            #expect(PermissionRequestRefreshPolicy.shouldRefreshOnCompletion(permission))
        }
        #expect(!PermissionRequestRefreshPolicy.shouldRefreshOnCompletion(.accessibility))
    }

    @Test("Permission actions distinguish refresh, native prompts, and Settings")
    func permissionRequestActions() {
        #expect(PermissionRequestPolicy.action(for: .microphone, state: .granted) == .refresh)
        #expect(PermissionRequestPolicy.action(for: .microphone, state: .notDetermined) == .prompt)
        #expect(PermissionRequestPolicy.action(for: .microphone, state: .denied) == .openSettings)
        #expect(PermissionRequestPolicy.action(for: .filesAndFolders, state: .manualReview) == .openSettings)
        #expect(PermissionRequestPolicy.action(for: .accessibility, state: .denied) == .prompt)
        #expect(PermissionRequestPolicy.action(for: .inputMonitoring, state: .denied) == .prompt)
        #expect(PermissionRequestPolicy.action(for: .screenRecording, state: .denied) == .prompt)
    }

    @Test("Failed boolean permission prompts fall back to System Settings")
    func booleanPermissionSettingsFallback() {
        #expect(PermissionRequestFallbackPolicy.shouldOpenSettings(
            for: .inputMonitoring,
            requestGranted: false
        ))
        #expect(PermissionRequestFallbackPolicy.shouldOpenSettings(
            for: .screenRecording,
            requestGranted: false
        ))
        #expect(!PermissionRequestFallbackPolicy.shouldOpenSettings(
            for: .screenRecording,
            requestGranted: true
        ))
        #expect(!PermissionRequestFallbackPolicy.shouldOpenSettings(
            for: .accessibility,
            requestGranted: false
        ))
    }

    @Test("Repeated permission clicks are coalesced until completion")
    func permissionRequestTracker() {
        var tracker = PermissionRequestTracker()
        let first = tracker.begin(.location)
        let duplicate = tracker.begin(.location)
        #expect(first)
        #expect(!duplicate)
        #expect(tracker.contains(.location))
        tracker.end(.location)
        #expect(!tracker.contains(.location))
        let retry = tracker.begin(.location)
        #expect(retry)
    }

    @Test("Apple Events passive check only grants successful OSStatus")
    func appleEventsStatusMapping() {
        #expect(AppleEventsPermissionCheck.isGranted(status: 0))
        #expect(!AppleEventsPermissionCheck.isGranted(status: -1743))
        #expect(!AppleEventsPermissionCheck.isGranted(status: -600))
        #expect(AppleEventsPermissionCheck.authorizationState(status: 0) == .granted)
        #expect(AppleEventsPermissionCheck.authorizationState(status: -1744) == .notDetermined)
        #expect(AppleEventsPermissionCheck.authorizationState(status: -1743) == .denied)
    }

    @Test("Every permission has a safe System Settings destination")
    func settingsDestinations() {
        for permission in PermissionType.allCases {
            #expect(PermissionSettingsDestination.url(for: permission) != nil)
        }
        #expect(
            PermissionSettingsDestination.url(for: .notifications)?.absoluteString
                == "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=com.hanazar.classgod"
        )
        #expect(
            PermissionSettingsDestination.url(for: .inputMonitoring)?.absoluteString
                == "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        )
        #expect(
            PermissionSettingsDestination.url(for: .screenRecording)?.absoluteString
                == "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        )
    }

    @Test("Catalog filters combine category, status, requirement, and normalized search")
    func catalogFiltering() {
        let items = PermissionType.allCases.map(PermissionItemInfo.init)
        let statuses = makeStatuses([
            .accessibility: .granted,
            .appleEvents: .denied,
            .inputMonitoring: .notDetermined,
            .filesAndFolders: .manualReview,
            .contacts: .denied,
        ])

        let browserControl = PermissionCatalogPolicy.items(
            from: items,
            statuses: statuses,
            category: .browser,
            statusFilter: .actionNeeded,
            requirementFilter: .required,
            searchText: "  Browser   Control  ",
            sortOrder: .attention
        )
        #expect(browserControl.map(\.type) == [.appleEvents])

        let manual = PermissionCatalogPolicy.items(
            from: items,
            statuses: statuses,
            category: nil,
            statusFilter: .manualReview,
            requirementFilter: .all,
            searchText: "system settings manual",
            sortOrder: .catalog
        )
        #expect(manual.contains { $0.type == .filesAndFolders })
    }

    @Test("Attention sorting prioritizes unresolved permissions before granted access")
    func attentionSorting() {
        let items = [
            PermissionItemInfo(type: .appleEvents),
            PermissionItemInfo(type: .contacts),
            PermissionItemInfo(type: .inputMonitoring),
        ]
        let statuses = makeStatuses([
            .appleEvents: .granted,
            .contacts: .denied,
            .inputMonitoring: .denied,
        ])

        let result = PermissionCatalogPolicy.items(
            from: items,
            statuses: statuses,
            category: nil,
            statusFilter: .all,
            requirementFilter: .all,
            searchText: "",
            sortOrder: .attention
        )
        #expect(result.map(\.type) == [.inputMonitoring, .contacts, .appleEvents])
    }

    @Test("Permission summary separates queryable and manual-review access")
    func permissionSummary() {
        let types: [PermissionType] = [.accessibility, .appleEvents, .filesAndFolders, .contacts]
        let statuses = makeStatuses([
            .accessibility: .granted,
            .appleEvents: .denied,
            .filesAndFolders: .manualReview,
            .contacts: .notDetermined,
        ])

        let summary = PermissionCatalogPolicy.summary(for: types, statuses: statuses)
        #expect(summary.queryableTotal == 3)
        #expect(summary.granted == 1)
        #expect(summary.actionNeeded == 2)
        #expect(summary.manualReview == 1)
        #expect(summary.requiredPending == 1)
    }

    private func makeStatuses(
        _ states: [PermissionType: PermissionAuthorizationState]
    ) -> [PermissionType: PermissionStatus] {
        states.reduce(into: [:]) { result, entry in
            result[entry.key] = PermissionStatus(
                type: entry.key,
                state: entry.value,
                lastChecked: .distantPast,
                detail: nil
            )
        }
    }
}
