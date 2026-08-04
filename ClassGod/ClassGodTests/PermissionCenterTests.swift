import Testing
@testable import ClassGod

@Suite("Permission Center catalog")
struct PermissionCenterTests {
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
        }
        #expect(PermissionType.appleEvents.canPrompt)
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

    @Test("Full review includes every permission in catalog order")
    func fullReviewScope() {
        #expect(PermissionReviewPlan.all == PermissionType.allCases)
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
        #expect(!PermissionAuthorizationState.manualReview.isGranted)
        #expect(PermissionAuthorizationState.manualReview.needsManualReview)
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
    }
}
