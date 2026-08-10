//
//  PermissionCenterService.swift
//  ClassGod
//
//  Tracks, checks and requests all macOS permissions needed by the app.
//

import Foundation
import AppKit
import ApplicationServices
import AVFoundation
import Combine
import Contacts
import CoreBluetooth
import CoreLocation
import EventKit
import Photos
import Speech
import UserNotifications

enum PermissionCategory: String, CaseIterable, Identifiable, Equatable {
    case core = "Core Access"
    case browser = "Browser Automation"
    case system = "System Info"
    case hardware = "Hardware Sensors"
    case optional = "Optional"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .core: return String(localized: "permission.category.core")
        case .browser: return String(localized: "permission.category.browser")
        case .system: return String(localized: "permission.category.system")
        case .hardware: return String(localized: "permission.category.hardware")
        case .optional: return String(localized: "permission.category.optional")
        }
    }
    
    var iconName: String {
        switch self {
        case .core: return "lock.shield"
        case .browser: return "globe"
        case .system: return "cpu"
        case .hardware: return "fanblades"
        case .optional: return "slider.horizontal.3"
        }
    }
}

enum PermissionRequirement: CaseIterable, Identifiable, Equatable {
    case required
    case recommended
    case optional

    var id: Self { self }

    var displayName: String {
        switch self {
        case .required: String(localized: "permission.requirement.required")
        case .recommended: String(localized: "permission.requirement.recommended")
        case .optional: String(localized: "permission.requirement.optional")
        }
    }
}

enum PermissionAuthorizationState: Equatable {
    case granted
    case limited
    case denied
    case notDetermined
    case restricted
    case manualReview

    nonisolated var isGranted: Bool {
        if case .granted = self { return true }
        return false
    }

    nonisolated var needsManualReview: Bool {
        if case .manualReview = self { return true }
        return false
    }

    var displayName: String {
        switch self {
        case .granted: String(localized: "permission.granted")
        case .limited: String(localized: "permission.limited")
        case .denied: String(localized: "permission.denied")
        case .notDetermined: String(localized: "permission.not_determined")
        case .restricted: String(localized: "permission.restricted")
        case .manualReview: String(localized: "permission.manual_review")
        }
    }
}

nonisolated enum PermissionAuthorizationPolicy {
    static func state(for status: PHAuthorizationStatus) -> PermissionAuthorizationState {
        switch status {
        case .authorized: .granted
        case .limited: .limited
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        @unknown default: .restricted
        }
    }

    static func state(for status: CNAuthorizationStatus) -> PermissionAuthorizationState {
        switch status {
        case .authorized: .granted
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        @unknown default: .restricted
        }
    }

    static func state(for status: EKAuthorizationStatus) -> PermissionAuthorizationState {
        switch status {
        case .authorized, .fullAccess: .granted
        case .writeOnly: .limited
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        @unknown default: .restricted
        }
    }

    static func state(for status: UNAuthorizationStatus) -> PermissionAuthorizationState {
        switch status {
        case .authorized: .granted
        case .provisional, .ephemeral: .limited
        case .notDetermined: .notDetermined
        case .denied: .denied
        @unknown default: .restricted
        }
    }
}

enum PermissionRequestMethod: Equatable {
    case nativePrompt
    case systemSettings

    var displayName: String {
        switch self {
        case .nativePrompt: String(localized: "permission.parameter.native_prompt")
        case .systemSettings: String(localized: "permission.parameter.system_settings")
        }
    }
}

enum PermissionStatusDetection: Equatable {
    case automatic
    case manual

    var displayName: String {
        switch self {
        case .automatic: String(localized: "permission.parameter.automatic_check")
        case .manual: String(localized: "permission.parameter.manual_check")
        }
    }
}

enum PermissionStatusFilter: CaseIterable, Identifiable, Equatable {
    case all
    case actionNeeded
    case granted
    case manualReview

    var id: Self { self }

    var title: String {
        switch self {
        case .all: String(localized: "permission.filter.all")
        case .actionNeeded: String(localized: "permission.filter.action_needed")
        case .granted: String(localized: "permission.filter.granted")
        case .manualReview: String(localized: "permission.filter.manual")
        }
    }
}

enum PermissionRequirementFilter: CaseIterable, Identifiable, Equatable {
    case all
    case required
    case recommended
    case optional

    var id: Self { self }

    var displayName: String {
        switch self {
        case .all: String(localized: "permission.requirement.all")
        case .required: PermissionRequirement.required.displayName
        case .recommended: PermissionRequirement.recommended.displayName
        case .optional: PermissionRequirement.optional.displayName
        }
    }

    func matches(_ requirement: PermissionRequirement) -> Bool {
        switch self {
        case .all: true
        case .required: requirement == .required
        case .recommended: requirement == .recommended
        case .optional: requirement == .optional
        }
    }
}

enum PermissionSortOrder: CaseIterable, Identifiable, Equatable {
    case attention
    case catalog
    case name

    var id: Self { self }

    var displayName: String {
        switch self {
        case .attention: String(localized: "permission.sort.attention")
        case .catalog: String(localized: "permission.sort.catalog")
        case .name: String(localized: "permission.sort.name")
        }
    }
}

enum PermissionType: String, CaseIterable, Identifiable, Equatable {
    case accessibility = "Accessibility"
    case inputMonitoring = "Input Monitoring"
    case appleEvents = "AppleEvents"
    case screenRecording = "Screen Recording"
    case fullDiskAccess = "Full Disk Access"
    case filesAndFolders = "Files and Folders"
    case developerTools = "Developer Tools"
    case appManagement = "App Management"
    case microphone = "Microphone"
    case camera = "Camera"
    case photos = "Photos"
    case mediaLibrary = "Media and Apple Music"
    case speechRecognition = "Speech Recognition"
    case location = "Location"
    case localNetwork = "Local Network"
    case notifications = "Notifications"
    case contacts = "Contacts"
    case reminders = "Reminders"
    case calendar = "Calendar"
    case bluetooth = "Bluetooth"
    
    var id: String { rawValue }
    
    var category: PermissionCategory {
        switch self {
        case .accessibility, .inputMonitoring: return .core
        case .appleEvents, .screenRecording, .localNetwork: return .browser
        case .fullDiskAccess, .filesAndFolders, .developerTools, .appManagement, .contacts, .reminders, .calendar: return .system
        case .microphone, .camera, .location, .bluetooth: return .hardware
        case .notifications, .photos, .mediaLibrary, .speechRecognition: return .optional
        }
    }
    
    var iconName: String {
        switch self {
        case .accessibility: return "figure.stand"
        case .inputMonitoring: return "keyboard.badge.ellipsis"
        case .appleEvents: return "applescript"
        case .screenRecording: return "record.circle"
        case .fullDiskAccess: return "externaldrive.fill.badge.checkmark"
        case .filesAndFolders: return "folder.badge.gearshape"
        case .developerTools: return "hammer.fill"
        case .appManagement: return "app.badge.checkmark"
        case .microphone: return "mic.fill"
        case .camera: return "camera.fill"
        case .photos: return "photo.on.rectangle.angled"
        case .mediaLibrary: return "music.note.list"
        case .speechRecognition: return "waveform.badge.mic"
        case .location: return "location.fill"
        case .localNetwork: return "network"
        case .notifications: return "bell.badge.fill"
        case .contacts: return "person.2.fill"
        case .reminders: return "checklist"
        case .calendar: return "calendar"
        case .bluetooth: return "dot.radiowaves.left.and.right"
        }
    }
    
    var title: String {
        switch self {
        case .accessibility: return String(localized: "permission.type.accessibility.title")
        case .inputMonitoring: return String(localized: "permission.type.inputMonitoring.title")
        case .appleEvents: return String(localized: "permission.type.appleEvents.title")
        case .screenRecording: return String(localized: "permission.type.screenRecording.title")
        case .fullDiskAccess: return String(localized: "permission.type.fullDiskAccess.title")
        case .filesAndFolders: return String(localized: "permission.type.filesAndFolders.title")
        case .developerTools: return String(localized: "permission.type.developerTools.title")
        case .appManagement: return String(localized: "permission.type.appManagement.title")
        case .microphone: return String(localized: "permission.type.microphone.title")
        case .camera: return String(localized: "permission.type.camera.title")
        case .photos: return String(localized: "permission.type.photos.title")
        case .mediaLibrary: return String(localized: "permission.type.mediaLibrary.title")
        case .speechRecognition: return String(localized: "permission.type.speechRecognition.title")
        case .location: return String(localized: "permission.type.location.title")
        case .localNetwork: return String(localized: "permission.type.localNetwork.title")
        case .notifications: return String(localized: "permission.type.notifications.title")
        case .contacts: return String(localized: "permission.type.contacts.title")
        case .reminders: return String(localized: "permission.type.reminders.title")
        case .calendar: return String(localized: "permission.type.calendar.title")
        case .bluetooth: return String(localized: "permission.type.bluetooth.title")
        }
    }
    
    var description: String {
        switch self {
        case .accessibility:
            return String(localized: "permission.type.accessibility.description")
        case .inputMonitoring:
            return String(localized: "permission.type.inputMonitoring.description")
        case .appleEvents:
            return String(localized: "permission.type.appleEvents.description")
        case .screenRecording:
            return String(localized: "permission.type.screenRecording.description")
        case .fullDiskAccess:
            return String(localized: "permission.type.fullDiskAccess.description")
        case .filesAndFolders:
            return String(localized: "permission.type.filesAndFolders.description")
        case .developerTools:
            return String(localized: "permission.type.developerTools.description")
        case .appManagement:
            return String(localized: "permission.type.appManagement.description")
        case .microphone:
            return String(localized: "permission.type.microphone.description")
        case .camera:
            return String(localized: "permission.type.camera.description")
        case .photos:
            return String(localized: "permission.type.photos.description")
        case .mediaLibrary:
            return String(localized: "permission.type.mediaLibrary.description")
        case .speechRecognition:
            return String(localized: "permission.type.speechRecognition.description")
        case .location:
            return String(localized: "permission.type.location.description")
        case .localNetwork:
            return String(localized: "permission.type.localNetwork.description")
        case .notifications:
            return String(localized: "permission.type.notifications.description")
        case .contacts:
            return String(localized: "permission.type.contacts.description")
        case .reminders:
            return String(localized: "permission.type.reminders.description")
        case .calendar:
            return String(localized: "permission.type.calendar.description")
        case .bluetooth:
            return String(localized: "permission.type.bluetooth.description")
        }
    }
    
    var features: [String] {
        switch self {
        case .accessibility:
            return [
                String(localized: "permission.feature.assessPrepHack"),
                String(localized: "permission.feature.browserTabSwitching"),
                String(localized: "permission.feature.focusGuard")
            ]
        case .inputMonitoring:
            return [String(localized: "permission.feature.globalShortcuts")]
        case .appleEvents:
            return [
                String(localized: "permission.feature.browserControl"),
                String(localized: "permission.feature.processActions"),
                String(localized: "permission.feature.systemEvents")
            ]
        case .screenRecording:
            return [
                String(localized: "permission.feature.browserDetection"),
                String(localized: "permission.feature.windowCapture")
            ]
        case .fullDiskAccess:
            return [
                String(localized: "permission.feature.activityMonitor"),
                String(localized: "permission.feature.systemFiles")
            ]
        case .filesAndFolders:
            return [String(localized: "permission.feature.userFiles")]
        case .developerTools:
            return [String(localized: "permission.feature.processInspection")]
        case .appManagement:
            return [String(localized: "permission.feature.appControl")]
        case .microphone:
            return [String(localized: "permission.feature.audioFeatures")]
        case .camera:
            return [String(localized: "permission.feature.videoFeatures")]
        case .photos:
            return [String(localized: "permission.feature.wallpaperLibrary")]
        case .mediaLibrary:
            return [String(localized: "permission.feature.mediaFeatures")]
        case .speechRecognition:
            return [String(localized: "permission.feature.voiceFeatures")]
        case .location:
            return [String(localized: "permission.feature.geoFeatures")]
        case .localNetwork:
            return [String(localized: "permission.feature.networkDiscovery")]
        case .notifications:
            return [
                String(localized: "permission.feature.alerts"),
                String(localized: "permission.feature.statusUpdates")
            ]
        case .contacts:
            return [String(localized: "permission.feature.futureIntegrations")]
        case .reminders:
            return [String(localized: "permission.feature.taskIntegrations")]
        case .calendar:
            return [String(localized: "permission.feature.scheduleIntegrations")]
        case .bluetooth:
            return [String(localized: "permission.feature.peripherals")]
        }
    }
    
    /// Whether the OS supports prompting directly from the app (vs opening System Settings).
    var canPrompt: Bool {
        switch self {
        case .accessibility, .inputMonitoring, .appleEvents, .screenRecording, .microphone, .camera,
             .photos, .speechRecognition, .location, .notifications, .contacts,
             .reminders, .calendar, .bluetooth:
            return true
        default: return false
        }
    }

    var requestMethod: PermissionRequestMethod {
        canPrompt ? .nativePrompt : .systemSettings
    }

    nonisolated var requiresManualReview: Bool {
        switch self {
        case .filesAndFolders, .developerTools, .appManagement, .mediaLibrary, .localNetwork:
            return true
        default:
            return false
        }
    }

    var statusDetection: PermissionStatusDetection {
        requiresManualReview ? .manual : .automatic
    }

    var requirement: PermissionRequirement {
        switch self {
        case .accessibility, .appleEvents:
            return .required
        case .inputMonitoring, .screenRecording, .fullDiskAccess, .notifications:
            return .recommended
        default:
            return .optional
        }
    }
}

enum PermissionReviewPlan {
    static let all = PermissionRequirement.allCases.flatMap { requirement in
        PermissionType.allCases.filter { $0.requirement == requirement }
    }

    static func pending(
        types: [PermissionType] = PermissionType.allCases,
        statuses: [PermissionType: PermissionStatus]
    ) -> [PermissionType] {
        let requested = Set(types)
        return all.filter { type in
            requested.contains(type) && !PermissionCatalogPolicy.state(for: type, statuses: statuses).isGranted
        }
    }
}

nonisolated enum PermissionRequestRefreshPolicy {
    static let completionDriven: [PermissionType] = [
        .appleEvents, .microphone, .camera, .photos, .speechRecognition,
        .location, .notifications, .contacts, .reminders, .calendar, .bluetooth
    ]

    static func shouldRefreshOnCompletion(_ type: PermissionType) -> Bool {
        completionDriven.contains(type)
    }
}

enum PermissionRequestAction: Equatable {
    case refresh
    case prompt
    case openSettings
}

enum PermissionRequestPolicy {
    private static let booleanPreflightOnly: [PermissionType] = [
        .accessibility, .inputMonitoring, .screenRecording
    ]

    static func action(
        for type: PermissionType,
        state: PermissionAuthorizationState
    ) -> PermissionRequestAction {
        if state.isGranted { return .refresh }
        if state.needsManualReview || state == .restricted || state == .limited { return .openSettings }
        if state == .denied, !booleanPreflightOnly.contains(type) { return .openSettings }
        return type.canPrompt ? .prompt : .openSettings
    }
}

nonisolated enum PermissionRequestFallbackPolicy {
    static func shouldOpenSettings(
        for type: PermissionType,
        requestGranted: Bool
    ) -> Bool {
        guard !requestGranted else { return false }
        return type == .inputMonitoring || type == .screenRecording
    }
}

struct PermissionRequestTracker {
    private(set) var active: Set<PermissionType> = []

    mutating func begin(_ type: PermissionType) -> Bool {
        active.insert(type).inserted
    }

    mutating func end(_ type: PermissionType) {
        active.remove(type)
    }

    func contains(_ type: PermissionType) -> Bool {
        active.contains(type)
    }
}

struct PermissionItemInfo: Identifiable, Equatable {
    let type: PermissionType
    var category: PermissionCategory { type.category }
    var title: String { type.title }
    var description: String { type.description }
    var features: [String] { type.features }
    var canPrompt: Bool { type.canPrompt }
    var requiresManualReview: Bool { type.requiresManualReview }
    var requestMethod: PermissionRequestMethod { type.requestMethod }
    var statusDetection: PermissionStatusDetection { type.statusDetection }
    var id: String { type.id }
}

struct PermissionStatus: Equatable {
    let type: PermissionType
    let state: PermissionAuthorizationState
    let lastChecked: Date
    let detail: String?

    var isGranted: Bool { state.isGranted }
}

struct PermissionSummary: Equatable {
    let queryableTotal: Int
    let granted: Int
    let actionNeeded: Int
    let manualReview: Int
    let requiredPending: Int
}

struct PermissionGateProgress: Equatable {
    let completed: Int
    let total: Int
    let pending: [PermissionType]

    var isUnlocked: Bool { total > 0 && completed == total }
}

enum PermissionGatePolicy {
    static func progress(
        statuses: [PermissionType: PermissionStatus],
        manuallyConfirmed: Set<PermissionType>
    ) -> PermissionGateProgress {
        let confirmed = sanitizedManualConfirmations(manuallyConfirmed)
        let gatedTypes = PermissionType.allCases.filter { $0.requirement == .required }
        let pending = gatedTypes.filter { type in
            if type.requiresManualReview {
                return !confirmed.contains(type)
            }
            return PermissionCatalogPolicy.state(for: type, statuses: statuses) != .granted
        }
        return PermissionGateProgress(
            completed: gatedTypes.count - pending.count,
            total: gatedTypes.count,
            pending: pending
        )
    }

    static func sanitizedManualConfirmations(
        _ confirmations: Set<PermissionType>
    ) -> Set<PermissionType> {
        confirmations.filter(\.requiresManualReview)
    }

    static func canSetManualConfirmation(
        for type: PermissionType,
        confirmed: Bool,
        didOpenSettings: Bool
    ) -> Bool {
        guard type.requiresManualReview else { return false }
        return !confirmed || didOpenSettings
    }
}

nonisolated enum PermissionGateSessionPolicy {
    static func isUnlocked(progressUnlocked: Bool, skipped: Bool) -> Bool {
        progressUnlocked || skipped
    }
}

enum PermissionCatalogPolicy {
    static func items(
        from items: [PermissionItemInfo],
        statuses: [PermissionType: PermissionStatus],
        category: PermissionCategory?,
        statusFilter: PermissionStatusFilter,
        requirementFilter: PermissionRequirementFilter,
        searchText: String,
        sortOrder: PermissionSortOrder
    ) -> [PermissionItemInfo] {
        let tokens = normalizedTokens(searchText)
        let filtered = items.filter { item in
            guard category == nil || item.category == category else { return false }
            let state = state(for: item.type, statuses: statuses)
            guard matches(state, filter: statusFilter),
                  requirementFilter.matches(item.type.requirement) else { return false }
            guard !tokens.isEmpty else { return true }
            let searchableText = ([
                item.type.rawValue,
                item.title,
                item.description,
                item.category.displayName,
                item.type.requirement.displayName,
                item.requestMethod.displayName,
                item.statusDetection.displayName,
                state.displayName,
            ] + item.features).joined(separator: " ")
            let normalizedText = normalize(searchableText)
            return tokens.allSatisfy(normalizedText.contains)
        }

        switch sortOrder {
        case .catalog:
            let indexes = Dictionary(uniqueKeysWithValues: PermissionType.allCases.enumerated().map { ($1, $0) })
            return filtered.sorted { indexes[$0.type, default: .max] < indexes[$1.type, default: .max] }
        case .name:
            return filtered.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .attention:
            return filtered.sorted { lhs, rhs in
                let left = attentionRank(for: lhs.type, statuses: statuses)
                let right = attentionRank(for: rhs.type, statuses: statuses)
                if left != right { return left.lexicographicallyPrecedes(right) }
                return PermissionType.allCases.firstIndex(of: lhs.type) ?? .max
                    < PermissionType.allCases.firstIndex(of: rhs.type) ?? .max
            }
        }
    }

    static func summary(
        for types: [PermissionType],
        statuses: [PermissionType: PermissionStatus]
    ) -> PermissionSummary {
        let queryable = types.filter { !$0.requiresManualReview }
        let granted = queryable.filter { state(for: $0, statuses: statuses).isGranted }.count
        return PermissionSummary(
            queryableTotal: queryable.count,
            granted: granted,
            actionNeeded: queryable.count - granted,
            manualReview: types.count - queryable.count,
            requiredPending: types.filter {
                $0.requirement == .required && !state(for: $0, statuses: statuses).isGranted
            }.count
        )
    }

    static func state(
        for type: PermissionType,
        statuses: [PermissionType: PermissionStatus]
    ) -> PermissionAuthorizationState {
        statuses[type]?.state ?? (type.requiresManualReview ? .manualReview : .notDetermined)
    }

    private static func matches(
        _ state: PermissionAuthorizationState,
        filter: PermissionStatusFilter
    ) -> Bool {
        switch filter {
        case .all: true
        case .actionNeeded: !state.isGranted && !state.needsManualReview
        case .granted: state.isGranted
        case .manualReview: state.needsManualReview
        }
    }

    private static func attentionRank(
        for type: PermissionType,
        statuses: [PermissionType: PermissionStatus]
    ) -> [Int] {
        let stateRank = switch state(for: type, statuses: statuses) {
        case .denied, .restricted, .limited, .notDetermined: 0
        case .manualReview: 1
        case .granted: 2
        }
        let requirementRank = switch type.requirement {
        case .required: 0
        case .recommended: 1
        case .optional: 2
        }
        return [stateRank, requirementRank]
    }

    private static func normalizedTokens(_ text: String) -> [String] {
        normalize(text).split(whereSeparator: \.isWhitespace).map(String.init)
    }

    private static func normalize(_ text: String) -> String {
        text.folding(
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: .current
        )
    }
}

enum AppleEventsPermissionCheck {
    nonisolated static let targetBundleIdentifier = "com.apple.systemevents"

    nonisolated static func isGranted(status: OSStatus) -> Bool {
        status == noErr
    }

    nonisolated static func needsTargetLaunch(status: OSStatus) -> Bool {
        status == procNotFound
    }

    nonisolated static func status() -> OSStatus {
        determinePermission(askUserIfNeeded: false)
    }

    nonisolated static func request() -> OSStatus {
        determinePermission(askUserIfNeeded: true)
    }

    private nonisolated static func determinePermission(askUserIfNeeded: Bool) -> OSStatus {
        let target = NSAppleEventDescriptor(bundleIdentifier: targetBundleIdentifier)
        return AEDeterminePermissionToAutomateTarget(
            target.aeDesc,
            typeWildCard,
            typeWildCard,
            askUserIfNeeded
        )
    }

    nonisolated static func authorizationState(status: OSStatus) -> PermissionAuthorizationState {
        switch status {
        case noErr: .granted
        case -1744: .notDetermined
        default: .denied
        }
    }
}

enum PermissionSettingsDestination {
    nonisolated static let privacyRootURL = URL(
        string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension"
    )

    nonisolated static func url(for type: PermissionType) -> URL? {
        if type == .notifications {
            return URL(
                string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=com.hanazar.classgod"
            )
        }
        let pane = switch type {
        case .fullDiskAccess: "Privacy_AllFiles"
        case .filesAndFolders: "Privacy_FilesAndFolders"
        case .developerTools: "Privacy_DeveloperTools"
        case .appManagement: "Privacy_AppBundles"
        case .photos: "Privacy_Photos"
        case .mediaLibrary: "Privacy_Media"
        case .speechRecognition: "Privacy_SpeechRecognition"
        case .localNetwork: "Privacy_LocalNetwork"
        case .contacts: "Privacy_Contacts"
        case .reminders: "Privacy_Reminders"
        case .calendar: "Privacy_Calendars"
        case .microphone: "Privacy_Microphone"
        case .camera: "Privacy_Camera"
        case .location: "Privacy_LocationServices"
        case .bluetooth: "Privacy_Bluetooth"
        case .screenRecording: "Privacy_ScreenCapture"
        case .accessibility: "Privacy_Accessibility"
        case .inputMonitoring: "Privacy_ListenEvent"
        case .appleEvents: "Privacy_Automation"
        case .notifications: "Privacy_Notifications"
        }
        return URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")
    }
}

nonisolated enum PermissionRefreshQueuePolicy {
    static func shouldQueueFollowUp(isChecking: Bool) -> Bool {
        isChecking
    }
}

nonisolated enum PermissionLiveRefreshPolicy {
    static let intervalNanoseconds: UInt64 = 100_000_000
    static let fullScanStride = 10

    static func requiresFullScan(tick: Int) -> Bool {
        tick.isMultiple(of: fullScanStride)
    }

    static func immediateTypes(
        statuses: [PermissionType: PermissionStatus]
    ) -> [PermissionType] {
        PermissionType.allCases.filter {
            !$0.requiresManualReview && statuses[$0]?.state != .granted
        }
    }
}

enum PermissionStatusChangePolicy {
    static func hasChanges(
        current: [PermissionType: PermissionStatus],
        updated: [PermissionType: PermissionStatus]
    ) -> Bool {
        guard current.count == updated.count else { return true }
        return PermissionType.allCases.contains { type in
            current[type]?.state != updated[type]?.state
                || current[type]?.detail != updated[type]?.detail
        }
    }
}

nonisolated enum PermissionRequestResolutionPolicy {
    static func resolved(
        active: Set<PermissionType>,
        statuses: [PermissionType: PermissionStatus]
    ) -> Set<PermissionType> {
        Set(active.filter { statuses[$0]?.state.isGranted == true })
    }
}

private enum PermissionRefreshScope: Equatable {
    case all
    case immediate

    func merged(with other: PermissionRefreshScope) -> PermissionRefreshScope {
        self == .all || other == .all ? .all : .immediate
    }
}

@MainActor
final class PermissionCenterService: ObservableObject {
    static let shared = PermissionCenterService()
    
    @Published var statuses: [PermissionType: PermissionStatus] = [:]
    @Published var isChecking = false
    @Published private(set) var pendingRequests: Set<PermissionType> = []
    @Published private(set) var manuallyConfirmed: Set<PermissionType>
    @Published private(set) var openedManualReviews: Set<PermissionType> = []
    @Published private(set) var isGateUnlocked = false
    @Published private(set) var isGateSkippedForSession = false
    private var refreshInProgress = false
    private var refreshRequestedWhileChecking = false
    private var queuedRefreshShowsProgress = false
    private var queuedRefreshScope = PermissionRefreshScope.immediate
    private var liveRefreshTick = 0
    private var requestTracker = PermissionRequestTracker()
    private var liveRefreshTask: Task<Void, Never>?
    private let manualConfirmationsKey = "com.hanazar.classgod.permissionGate.manualConfirmations"
    
    var allPermissions: [PermissionItemInfo] {
        PermissionType.allCases.map { PermissionItemInfo(type: $0) }
    }
    
    private init() {
        let rawValues = UserDefaults.standard.stringArray(forKey: manualConfirmationsKey) ?? []
        manuallyConfirmed = PermissionGatePolicy.sanitizedManualConfirmations(
            Set(rawValues.compactMap(PermissionType.init(rawValue:)))
        )
        updateGateState()
    }

    var gateProgress: PermissionGateProgress {
        PermissionGatePolicy.progress(
            statuses: statuses,
            manuallyConfirmed: manuallyConfirmed
        )
    }

    func isManuallyConfirmed(_ type: PermissionType) -> Bool {
        manuallyConfirmed.contains(type)
    }

    func canConfirmManualReview(_ type: PermissionType) -> Bool {
        isManuallyConfirmed(type) || openedManualReviews.contains(type)
    }

    func setManualConfirmation(_ type: PermissionType, confirmed: Bool) {
        guard PermissionGatePolicy.canSetManualConfirmation(
            for: type,
            confirmed: confirmed,
            didOpenSettings: openedManualReviews.contains(type)
                || manuallyConfirmed.contains(type)
        ) else { return }
        if confirmed {
            manuallyConfirmed.insert(type)
        } else {
            manuallyConfirmed.remove(type)
        }
        UserDefaults.standard.set(
            manuallyConfirmed.map(\.rawValue).sorted(),
            forKey: manualConfirmationsKey
        )
        updateGateState()
    }

    func skipGateForCurrentSession() {
        isGateSkippedForSession = true
        updateGateState()
    }
    
    func refreshAll(afterAuthorization: Bool = false) {
        requestRefresh(showsProgress: !afterAuthorization, scope: .all)
    }

    func startLiveMonitoring() {
        guard liveRefreshTask == nil else { return }
        liveRefreshTick = 0
        liveRefreshTask = Task { [weak self] in
            await Self.prepareAppleEventsTargetIfNeeded()
            guard let self else { return }
            self.requestRefresh(showsProgress: false, scope: .all)
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: PermissionLiveRefreshPolicy.intervalNanoseconds)
                } catch {
                    return
                }
                self.liveRefreshTick += 1
                let scope: PermissionRefreshScope = PermissionLiveRefreshPolicy.requiresFullScan(
                    tick: self.liveRefreshTick
                ) ? .all : .immediate
                self.requestRefresh(showsProgress: false, scope: scope)
            }
        }
    }

    func stopLiveMonitoring() {
        liveRefreshTask?.cancel()
        liveRefreshTask = nil
        liveRefreshTick = 0
    }

    private func requestRefresh(showsProgress: Bool, scope: PermissionRefreshScope) {
        guard !refreshInProgress else {
            if PermissionRefreshQueuePolicy.shouldQueueFollowUp(isChecking: refreshInProgress) {
                refreshRequestedWhileChecking = true
                queuedRefreshShowsProgress = queuedRefreshShowsProgress || showsProgress
                queuedRefreshScope = queuedRefreshScope.merged(with: scope)
            }
            return
        }
        let types = scope == .all
            ? PermissionType.allCases
            : PermissionLiveRefreshPolicy.immediateTypes(statuses: statuses)
        guard !types.isEmpty else { return }
        refreshInProgress = true
        if showsProgress { isChecking = true }
        Task { [weak self] in
            let refreshedStatuses = await Self.collectStatuses(types: types)
            guard let self else { return }
            let newStatuses = self.statuses.merging(refreshedStatuses) { _, refreshed in refreshed }
            if showsProgress
                || PermissionStatusChangePolicy.hasChanges(current: self.statuses, updated: newStatuses) {
                self.statuses = newStatuses
            }
            for type in PermissionRequestResolutionPolicy.resolved(
                active: self.requestTracker.active,
                statuses: newStatuses
            ) {
                self.finishRequest(type)
            }
            self.refreshInProgress = false
            if showsProgress { self.isChecking = false }
            self.updateGateState()
            if self.refreshRequestedWhileChecking {
                let nextShowsProgress = self.queuedRefreshShowsProgress
                let nextScope = self.queuedRefreshScope
                self.refreshRequestedWhileChecking = false
                self.queuedRefreshShowsProgress = false
                self.queuedRefreshScope = .immediate
                self.requestRefresh(showsProgress: nextShowsProgress, scope: nextScope)
            }
        }
    }
    
    func requestPermission(_ type: PermissionType) {
        let fallbackState: PermissionAuthorizationState = type.requiresManualReview ? .manualReview : .notDetermined
        switch PermissionRequestPolicy.action(for: type, state: statuses[type]?.state ?? fallbackState) {
        case .refresh:
            refreshAll()
            return
        case .openSettings:
            if type.requiresManualReview {
                openedManualReviews.insert(type)
            }
            Self.openSystemSettings(for: type)
            return
        case .prompt:
            break
        }
        guard beginRequest(type) else { return }

        let completed = completionHandler(for: type)
        switch type {
        case .accessibility:
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        case .inputMonitoring:
            let granted = CGPreflightListenEventAccess() || CGRequestListenEventAccess()
            if PermissionRequestFallbackPolicy.shouldOpenSettings(
                for: type,
                requestGranted: granted
            ) {
                Self.openSystemSettings(for: type)
            }
        case .appleEvents:
            Task {
                await Self.prepareAppleEventsTargetIfNeeded()
                _ = await Task.detached(priority: .userInitiated) {
                    AppleEventsPermissionCheck.request()
                }.value
                completed()
            }
        case .screenRecording:
            let granted = CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess()
            if PermissionRequestFallbackPolicy.shouldOpenSettings(
                for: type,
                requestGranted: granted
            ) {
                Self.openSystemSettings(for: type)
            }
        case .microphone:
            AVCaptureDevice.requestAccess(for: .audio) { _ in completed() }
        case .camera:
            AVCaptureDevice.requestAccess(for: .video) { _ in completed() }
        case .photos:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in completed() }
        case .speechRecognition:
            SFSpeechRecognizer.requestAuthorization { _ in completed() }
        case .location:
            LocationPermissionHelper.shared.request(completion: completed)
        case .notifications:
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in completed() }
        case .contacts:
            CNContactStore().requestAccess(for: .contacts) { _, _ in completed() }
        case .reminders:
            EventPermissionHelper.shared.requestReminders(completion: completed)
        case .calendar:
            EventPermissionHelper.shared.requestCalendar(completion: completed)
        case .bluetooth:
            BluetoothPermissionHelper.shared.request(completion: completed)
        default:
            Self.openSystemSettings(for: type)
        }
        if !PermissionRequestRefreshPolicy.shouldRefreshOnCompletion(type) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.finishRequest(type)
                self?.refreshAll(afterAuthorization: true)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
                guard self?.requestTracker.contains(type) == true else { return }
                self?.finishRequest(type)
                self?.refreshAll(afterAuthorization: true)
            }
        }
    }

    func isRequesting(_ type: PermissionType) -> Bool {
        pendingRequests.contains(type)
    }

    private func beginRequest(_ type: PermissionType) -> Bool {
        guard requestTracker.begin(type) else { return false }
        pendingRequests = requestTracker.active
        return true
    }

    private func finishRequest(_ type: PermissionType) {
        requestTracker.end(type)
        pendingRequests = requestTracker.active
    }

    private func updateGateState() {
        isGateUnlocked = PermissionGateSessionPolicy.isUnlocked(
            progressUnlocked: gateProgress.isUnlocked,
            skipped: isGateSkippedForSession
        )
    }

    private func completionHandler(for type: PermissionType) -> @Sendable () -> Void {
        { [weak self] in
            DispatchQueue.main.async {
                self?.finishRequest(type)
                self?.refreshAll(afterAuthorization: true)
            }
        }
    }

    private nonisolated static func collectStatuses(
        types: [PermissionType]
    ) async -> [PermissionType: PermissionStatus] {
        var statuses: [PermissionType: PermissionStatus] = [:]
        for type in types {
            let (state, detail) = await checkStatus(type)
            statuses[type] = PermissionStatus(
                type: type,
                state: state,
                lastChecked: Date(),
                detail: detail
            )
        }
        return statuses
    }

    private static func prepareAppleEventsTargetIfNeeded() async {
        let status = await Task.detached(priority: .userInitiated) {
            AppleEventsPermissionCheck.status()
        }.value
        guard AppleEventsPermissionCheck.needsTargetLaunch(status: status),
              NSRunningApplication.runningApplications(
                withBundleIdentifier: AppleEventsPermissionCheck.targetBundleIdentifier
              ).isEmpty,
              let url = NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: AppleEventsPermissionCheck.targetBundleIdentifier
              ) else { return }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        configuration.addsToRecentItems = false
        await withCheckedContinuation { continuation in
            NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, _ in
                continuation.resume()
            }
        }
    }

    private nonisolated static func checkStatus(
        _ type: PermissionType
    ) async -> (PermissionAuthorizationState, String?) {
        switch type {
        case .accessibility:
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
            let granted = AXIsProcessTrustedWithOptions(options as CFDictionary)
            return (granted ? .granted : .denied, nil)

        case .inputMonitoring:
            return (CGPreflightListenEventAccess() ? .granted : .denied, nil)
            
        case .appleEvents:
            let status = AppleEventsPermissionCheck.status()
            return (AppleEventsPermissionCheck.authorizationState(status: status), nil)
            
        case .screenRecording:
            return (CGPreflightScreenCaptureAccess() ? .granted : .denied, nil)
            
        case .fullDiskAccess:
            // Probe a system-protected location; this is only a heuristic.
            let protectedPath = "/Library/Application Support/com.apple.TCC/TCC.db"
            let granted = FileManager.default.isReadableFile(atPath: protectedPath)
            return (granted ? .granted : .denied, nil)

        case .filesAndFolders, .developerTools, .appManagement, .mediaLibrary, .localNetwork:
            return (.manualReview, nil)
            
        case .microphone:
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            return (authorizationState(for: status), nil)
            
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            return (authorizationState(for: status), nil)

        case .photos:
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            return (PermissionAuthorizationPolicy.state(for: status), nil)

        case .speechRecognition:
            let status = SFSpeechRecognizer.authorizationStatus()
            switch status {
            case .authorized: return (.granted, nil)
            case .notDetermined: return (.notDetermined, nil)
            case .restricted: return (.restricted, nil)
            case .denied: return (.denied, nil)
            @unknown default: return (.restricted, nil)
            }
            
        case .location:
            let status = CLLocationManager().authorizationStatus
            switch status {
            case .authorizedAlways, .authorized: return (.granted, nil)
            case .notDetermined: return (.notDetermined, nil)
            case .restricted: return (.restricted, nil)
            case .denied: return (.denied, nil)
            @unknown default: return (.restricted, nil)
            }
            
        case .notifications:
            return await withCheckedContinuation { continuation in
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    let state = PermissionAuthorizationPolicy.state(for: settings.authorizationStatus)
                    continuation.resume(returning: (state, nil))
                }
            }
            
        case .contacts:
            return (PermissionAuthorizationPolicy.state(for: CNContactStore.authorizationStatus(for: .contacts)), nil)
            
        case .reminders:
            return (PermissionAuthorizationPolicy.state(for: EKEventStore.authorizationStatus(for: .reminder)), nil)
            
        case .calendar:
            return (PermissionAuthorizationPolicy.state(for: EKEventStore.authorizationStatus(for: .event)), nil)
            
        case .bluetooth:
            let auth = CBCentralManager.authorization
            switch auth {
            case .allowedAlways: return (.granted, nil)
            case .notDetermined: return (.notDetermined, nil)
            case .restricted: return (.restricted, nil)
            case .denied: return (.denied, nil)
            @unknown default: return (.restricted, nil)
            }
        }
    }

    private nonisolated static func authorizationState(for status: AVAuthorizationStatus) -> PermissionAuthorizationState {
        switch status {
        case .authorized: .granted
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        @unknown default: .restricted
        }
    }

    private static func openSystemSettings(for type: PermissionType) {
        if let url = PermissionSettingsDestination.url(for: type), NSWorkspace.shared.open(url) {
            return
        }
        if let fallback = PermissionSettingsDestination.privacyRootURL {
            NSWorkspace.shared.open(fallback)
        }
    }
}

// MARK: - Permission Helpers

final class LocationPermissionHelper: NSObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionHelper()
    private let manager = CLLocationManager()
    private var completion: (@Sendable () -> Void)?
    
    private override init() {
        super.init()
        manager.delegate = self
    }
    
    func request(completion: @escaping @Sendable () -> Void) {
        self.completion = completion
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined else { return }
        completion?()
        completion = nil
    }
}

final class BluetoothPermissionHelper: NSObject, CBCentralManagerDelegate {
    static let shared = BluetoothPermissionHelper()
    private var manager: CBCentralManager?
    private var completion: (@Sendable () -> Void)?
    
    func request(completion: @escaping @Sendable () -> Void) {
        self.completion = completion
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard CBCentralManager.authorization != .notDetermined else { return }
        completion?()
        completion = nil
    }
}

final class EventPermissionHelper {
    static let shared = EventPermissionHelper()
    private let store = EKEventStore()

    func requestReminders(completion: @escaping @Sendable () -> Void) {
        store.requestFullAccessToReminders { _, _ in completion() }
    }

    func requestCalendar(completion: @escaping @Sendable () -> Void) {
        store.requestFullAccessToEvents { _, _ in completion() }
    }
}
