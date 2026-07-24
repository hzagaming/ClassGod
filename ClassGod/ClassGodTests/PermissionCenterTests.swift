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

    @Test("First-time setup only asks for permissions required by core switching")
    func firstTimeSetupScope() {
        let setupPermissions = PermissionType.allCases.filter(\.isRecommendedForSetup)
        #expect(setupPermissions == [.accessibility, .appleEvents])
    }

    @Test("Apple Events passive check only grants successful OSStatus")
    func appleEventsStatusMapping() {
        #expect(AppleEventsPermissionCheck.isGranted(status: 0))
        #expect(!AppleEventsPermissionCheck.isGranted(status: -1743))
        #expect(!AppleEventsPermissionCheck.isGranted(status: -600))
    }

    @Test("Every permission has a safe System Settings destination")
    func settingsDestinations() {
        for permission in PermissionType.allCases {
            #expect(PermissionSettingsDestination.url(for: permission) != nil)
        }
    }
}
