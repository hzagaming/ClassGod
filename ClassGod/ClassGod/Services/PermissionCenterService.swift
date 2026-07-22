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
    case appleEvents = "AppleEvents"
    case screenRecording = "Screen Recording"
    case fullDiskAccess = "Full Disk Access"
    case microphone = "Microphone"
    case camera = "Camera"
    case location = "Location"
    case notifications = "Notifications"
    case contacts = "Contacts"
    case reminders = "Reminders"
    case calendar = "Calendar"
    case bluetooth = "Bluetooth"
    
    var id: String { rawValue }
    
    var category: PermissionCategory {
        switch self {
        case .accessibility: return .core
        case .appleEvents, .screenRecording: return .browser
        case .fullDiskAccess, .contacts, .reminders, .calendar: return .system
        case .microphone, .camera, .location, .bluetooth: return .hardware
        case .notifications: return .optional
        }
    }
    
    var iconName: String {
        switch self {
        case .accessibility: return "figure.stand"
        case .appleEvents: return "applescript"
        case .screenRecording: return "record.circle"
        case .fullDiskAccess: return "externaldrive.fill.badge.checkmark"
        case .microphone: return "mic.fill"
        case .camera: return "camera.fill"
        case .location: return "location.fill"
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
        case .appleEvents: return String(localized: "permission.type.appleEvents.title")
        case .screenRecording: return String(localized: "permission.type.screenRecording.title")
        case .fullDiskAccess: return String(localized: "permission.type.fullDiskAccess.title")
        case .microphone: return String(localized: "permission.type.microphone.title")
        case .camera: return String(localized: "permission.type.camera.title")
        case .location: return String(localized: "permission.type.location.title")
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
        case .appleEvents:
            return String(localized: "permission.type.appleEvents.description")
        case .screenRecording:
            return String(localized: "permission.type.screenRecording.description")
        case .fullDiskAccess:
            return String(localized: "permission.type.fullDiskAccess.description")
        case .microphone:
            return String(localized: "permission.type.microphone.description")
        case .camera:
            return String(localized: "permission.type.camera.description")
        case .location:
            return String(localized: "permission.type.location.description")
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
        case .microphone:
            return [String(localized: "permission.feature.audioFeatures")]
        case .camera:
            return [String(localized: "permission.feature.videoFeatures")]
        case .location:
            return [String(localized: "permission.feature.geoFeatures")]
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
        case .accessibility: return true
        case .screenRecording: return true
        case .microphone: return true
        case .camera: return true
        case .location: return true
        case .notifications: return true
        case .bluetooth: return true
        default: return false
        }
    }
}

struct PermissionItemInfo: Identifiable, Equatable {
    let type: PermissionType
    var category: PermissionCategory { type.category }
    var title: String { type.title }
    var description: String { type.description }
    var features: [String] { type.features }
    var canPrompt: Bool { type.canPrompt }
    var id: String { type.id }
}

struct PermissionStatus: Equatable {
    let type: PermissionType
    let isGranted: Bool
    let lastChecked: Date
    let detail: String?
}

@MainActor
final class PermissionCenterService: ObservableObject {
    static let shared = PermissionCenterService()
    
    @Published var statuses: [PermissionType: PermissionStatus] = [:]
    @Published var isChecking = false
    
    var allPermissions: [PermissionItemInfo] {
        PermissionType.allCases.map { PermissionItemInfo(type: $0) }
    }
    
    private init() {}
    
    func refreshAll() {
        isChecking = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var newStatuses: [PermissionType: PermissionStatus] = [:]
            let now = Date()
            for type in PermissionType.allCases {
                let (granted, detail) = Self.checkStatus(type)
                newStatuses[type] = PermissionStatus(type: type, isGranted: granted, lastChecked: now, detail: detail)
            }
            DispatchQueue.main.async {
                self?.statuses = newStatuses
                self?.isChecking = false
            }
        }
    }
    
    func requestPermission(_ type: PermissionType) {
        switch type {
        case .accessibility:
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        case .screenRecording:
            if !CGPreflightScreenCaptureAccess() {
                CGRequestScreenCaptureAccess()
            }
        case .microphone:
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
        case .camera:
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        case .location:
            LocationPermissionHelper.shared.request()
        case .notifications:
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
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
            
        case .appleEvents:
            // AppleEvents automation is per-target. We do a lightweight probe against System Events.
            let script = NSAppleScript(source: """
                tell application "System Events"
                    return name of first process whose frontmost is true
                end tell
                """)
            var errorInfo: NSDictionary?
            _ = script?.executeAndReturnError(&errorInfo)
            let denied = (errorInfo?["OSAScriptErrorNumberKey"] as? NSNumber)?.int32Value == -1743
            return (!denied, denied ? "Permission denied for System Events" : nil)
            
        case .screenRecording:
            return (CGPreflightScreenCaptureAccess(), nil)
            
        case .fullDiskAccess:
            // Probe a system-protected location; this is only a heuristic.
            let protectedPath = "/Library/Application Support/com.apple.TCC/TCC.db"
            let granted = FileManager.default.isReadableFile(atPath: protectedPath)
            return (granted, granted ? nil : "Open System Settings → Privacy & Security → Full Disk Access")
            
        case .microphone:
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            return (status == .authorized, status == .denied ? "Denied" : nil)
            
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            return (status == .authorized, status == .denied ? "Denied" : nil)
            
        case .location:
            let status = CLLocationManager().authorizationStatus
            let granted = status == .authorizedAlways || status == .authorized
            return (granted, status == .denied ? "Denied" : nil)
            
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
            return (auth == .allowedAlways, auth == .denied ? "Denied" : nil)
        }
    }
    
    private static func openSystemSettings(for type: PermissionType) {
        let url: URL
        switch type {
        case .fullDiskAccess:
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        case .contacts:
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts")!
        case .reminders:
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders")!
        case .calendar:
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!
        case .microphone:
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
        case .camera:
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")!
        case .location:
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!
        case .bluetooth:
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth")!
        case .screenRecording:
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        case .accessibility:
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        case .appleEvents:
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
        case .notifications:
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Notifications")!
        }
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
