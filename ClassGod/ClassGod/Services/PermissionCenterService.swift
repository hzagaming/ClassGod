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
        case .accessibility, .inputMonitoring, .screenRecording, .microphone, .camera,
             .photos, .speechRecognition, .location, .notifications, .contacts,
             .reminders, .calendar, .bluetooth:
            return true
        default: return false
        }
    }

    var requiresManualReview: Bool {
        switch self {
        case .filesAndFolders, .developerTools, .appManagement, .mediaLibrary, .localNetwork:
            return true
        default:
            return false
        }
    }

    var isRecommendedForSetup: Bool {
        self == .accessibility || self == .appleEvents
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
    var id: String { type.id }
}

struct PermissionStatus: Equatable {
    let type: PermissionType
    let isGranted: Bool
    let lastChecked: Date
    let detail: String?
}

enum AppleEventsPermissionCheck {
    nonisolated static func isGranted(status: OSStatus) -> Bool {
        status == noErr
    }

    nonisolated static func status() -> OSStatus {
        let target = NSAppleEventDescriptor(bundleIdentifier: "com.apple.systemevents")
        return AEDeterminePermissionToAutomateTarget(
            target.aeDesc,
            typeWildCard,
            typeWildCard,
            false
        )
    }
}

enum PermissionSettingsDestination {
    nonisolated static func url(for type: PermissionType) -> URL? {
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
    private var refreshRequestedWhileChecking = false
    
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
                let (granted, detail) = Self.checkStatus(type)
                newStatuses[type] = PermissionStatus(type: type, isGranted: granted, lastChecked: now, detail: detail)
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
        switch type {
        case .accessibility:
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        case .inputMonitoring:
            if !CGPreflightListenEventAccess() {
                _ = CGRequestListenEventAccess()
            }
        case .screenRecording:
            if !CGPreflightScreenCaptureAccess() {
                CGRequestScreenCaptureAccess()
            }
        case .microphone:
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
        case .camera:
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        case .photos:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in }
        case .speechRecognition:
            SFSpeechRecognizer.requestAuthorization { _ in }
        case .location:
            LocationPermissionHelper.shared.request()
        case .notifications:
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        case .contacts:
            CNContactStore().requestAccess(for: .contacts) { _, _ in }
        case .reminders:
            EventPermissionHelper.shared.requestReminders()
        case .calendar:
            EventPermissionHelper.shared.requestCalendar()
        case .bluetooth:
            BluetoothPermissionHelper.shared.request()
        default:
            Self.openSystemSettings(for: type)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshAll()
        }
    }
    
    private nonisolated static func checkStatus(_ type: PermissionType) -> (Bool, String?) {
        switch type {
        case .accessibility:
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
            let granted = AXIsProcessTrustedWithOptions(options as CFDictionary)
            return (granted, nil)

        case .inputMonitoring:
            return (CGPreflightListenEventAccess(), nil)
            
        case .appleEvents:
            let status = AppleEventsPermissionCheck.status()
            return (AppleEventsPermissionCheck.isGranted(status: status), nil)
            
        case .screenRecording:
            return (CGPreflightScreenCaptureAccess(), nil)
            
        case .fullDiskAccess:
            // Probe a system-protected location; this is only a heuristic.
            let protectedPath = "/Library/Application Support/com.apple.TCC/TCC.db"
            let granted = FileManager.default.isReadableFile(atPath: protectedPath)
            return (granted, nil)

        case .filesAndFolders, .developerTools, .appManagement, .mediaLibrary, .localNetwork:
            return (false, nil)
            
        case .microphone:
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            return (status == .authorized, nil)
            
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            return (status == .authorized, nil)

        case .photos:
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            return (status == .authorized || status == .limited, nil)

        case .speechRecognition:
            let status = SFSpeechRecognizer.authorizationStatus()
            return (status == .authorized, nil)
            
        case .location:
            let status = CLLocationManager().authorizationStatus
            let granted = status == .authorizedAlways || status == .authorized
            return (granted, nil)
            
        case .notifications:
            let semaphore = DispatchSemaphore(value: 0)
            var granted = false
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                granted = settings.authorizationStatus == .authorized
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 0.5)
            return (granted, nil)
            
        case .contacts:
            return (CNContactStore.authorizationStatus(for: .contacts) == .authorized, nil)
            
        case .reminders:
            return (EKEventStore.authorizationStatus(for: .reminder) == .fullAccess, nil)
            
        case .calendar:
            return (EKEventStore.authorizationStatus(for: .event) == .fullAccess, nil)
            
        case .bluetooth:
            let auth = CBCentralManager.authorization
            return (auth == .allowedAlways, nil)
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
    
    private override init() {
        super.init()
        manager.delegate = self
    }
    
    func request() {
        manager.requestWhenInUseAuthorization()
    }
}

final class BluetoothPermissionHelper: NSObject, CBCentralManagerDelegate {
    static let shared = BluetoothPermissionHelper()
    private var manager: CBCentralManager?
    
    func request() {
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Triggered side effect: instantiates CBCentralManager, which prompts on first use.
    }
}

final class EventPermissionHelper {
    static let shared = EventPermissionHelper()
    private let store = EKEventStore()

    func requestReminders() {
        store.requestFullAccessToReminders { _, _ in }
    }

    func requestCalendar() {
        store.requestFullAccessToEvents { _, _ in }
    }
}
