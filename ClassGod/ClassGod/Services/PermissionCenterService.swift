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

enum PermissionRequirement: Equatable {
    case required
    case recommended
    case optional

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
    case denied
    case notDetermined
    case restricted
    case manualReview

    var isGranted: Bool { self == .granted }
    var needsManualReview: Bool { self == .manualReview }

    var displayName: String {
        switch self {
        case .granted: String(localized: "permission.granted")
        case .denied: String(localized: "permission.denied")
        case .notDetermined: String(localized: "permission.not_determined")
        case .restricted: String(localized: "permission.restricted")
        case .manualReview: String(localized: "permission.manual_review")
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

    var requiresManualReview: Bool {
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
    static let all = PermissionType.allCases
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
        if state.needsManualReview || state == .restricted { return .openSettings }
        if state == .denied, !booleanPreflightOnly.contains(type) { return .openSettings }
        return type.canPrompt ? .prompt : .openSettings
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
        case .denied, .restricted, .notDetermined: 0
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
    nonisolated static func isGranted(status: OSStatus) -> Bool {
        status == noErr
    }

    nonisolated static func status() -> OSStatus {
        determinePermission(askUserIfNeeded: false)
    }

    nonisolated static func request() -> OSStatus {
        determinePermission(askUserIfNeeded: true)
    }

    private nonisolated static func determinePermission(askUserIfNeeded: Bool) -> OSStatus {
        let target = NSAppleEventDescriptor(bundleIdentifier: "com.apple.systemevents")
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

@MainActor
final class PermissionCenterService: ObservableObject {
    static let shared = PermissionCenterService()
    
    @Published var statuses: [PermissionType: PermissionStatus] = [:]
    @Published var isChecking = false
    @Published private(set) var pendingRequests: Set<PermissionType> = []
    private var refreshRequestedWhileChecking = false
    private var requestTracker = PermissionRequestTracker()
    
    var allPermissions: [PermissionItemInfo] {
        PermissionType.allCases.map { PermissionItemInfo(type: $0) }
    }
    
    private init() {}
    
    func refreshAll() {
        guard !isChecking else {
            refreshRequestedWhileChecking = true
            return
        }
        isChecking = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var newStatuses: [PermissionType: PermissionStatus] = [:]
            let now = Date()
            for type in PermissionType.allCases {
                let (state, detail) = Self.checkStatus(type)
                newStatuses[type] = PermissionStatus(type: type, state: state, lastChecked: now, detail: detail)
            }
            DispatchQueue.main.async {
                guard let self else { return }
                self.statuses = newStatuses
                self.isChecking = false
                if self.refreshRequestedWhileChecking {
                    self.refreshRequestedWhileChecking = false
                    self.refreshAll()
                }
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
            if !CGPreflightListenEventAccess() {
                _ = CGRequestListenEventAccess()
            }
        case .appleEvents:
            DispatchQueue.global(qos: .userInitiated).async {
                _ = AppleEventsPermissionCheck.request()
                completed()
            }
        case .screenRecording:
            if !CGPreflightScreenCaptureAccess() {
                CGRequestScreenCaptureAccess()
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
                self?.refreshAll()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
                guard self?.requestTracker.contains(type) == true else { return }
                self?.finishRequest(type)
                self?.refreshAll()
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

    private func completionHandler(for type: PermissionType) -> @Sendable () -> Void {
        { [weak self] in
            DispatchQueue.main.async {
                self?.finishRequest(type)
                self?.refreshAll()
            }
        }
    }

    private nonisolated static func checkStatus(_ type: PermissionType) -> (PermissionAuthorizationState, String?) {
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
            switch status {
            case .authorized, .limited: return (.granted, nil)
            case .notDetermined: return (.notDetermined, nil)
            case .restricted: return (.restricted, nil)
            case .denied: return (.denied, nil)
            @unknown default: return (.restricted, nil)
            }

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
            let semaphore = DispatchSemaphore(value: 0)
            var state = PermissionAuthorizationState.notDetermined
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral: state = .granted
                case .notDetermined: state = .notDetermined
                case .denied: state = .denied
                @unknown default: state = .restricted
                }
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 0.5)
            return (state, nil)
            
        case .contacts:
            return (authorizationState(for: CNContactStore.authorizationStatus(for: .contacts)), nil)
            
        case .reminders:
            return (authorizationState(for: EKEventStore.authorizationStatus(for: .reminder)), nil)
            
        case .calendar:
            return (authorizationState(for: EKEventStore.authorizationStatus(for: .event)), nil)
            
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

    private nonisolated static func authorizationState(for status: CNAuthorizationStatus) -> PermissionAuthorizationState {
        switch status {
        case .authorized, .limited: .granted
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        @unknown default: .restricted
        }
    }

    private nonisolated static func authorizationState(for status: EKAuthorizationStatus) -> PermissionAuthorizationState {
        switch status {
        case .authorized, .fullAccess, .writeOnly: .granted
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        @unknown default: .restricted
        }
    }
    
    private static func openSystemSettings(for type: PermissionType) {
        guard let url = PermissionSettingsDestination.url(for: type) else { return }
        NSWorkspace.shared.open(url)
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
