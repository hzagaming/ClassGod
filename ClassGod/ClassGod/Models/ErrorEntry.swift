//
//  ErrorEntry.swift
//  ClassGod
//
//  Created by ClassGod on 2026/05/31.
//

import Foundation

// MARK: - Error Severity
enum ErrorSeverity: String, CaseIterable, Codable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case info = "Info"
    
    var colorHex: String {
        switch self {
        case .critical: return "#FF3B30"
        case .high: return "#FF9500"
        case .medium: return "#FFCC00"
        case .low: return "#34C759"
        case .info: return "#007AFF"
        }
    }
    
    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "exclamationmark"
        case .low: return "info.circle"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - Error Category
enum ErrorCategory: String, CaseIterable, Codable, Identifiable {
    case all = "All Errors"
    case swiftCompile = "Swift Compile"
    case swiftRuntime = "Swift Runtime"
    case swiftUI = "SwiftUI"
    case appKit = "AppKit / macOS"
    case xcodeBuild = "Xcode Build"
    case network = "Network / URL"
    case fileSystem = "File System"
    case permissions = "Permissions / Sandbox"
    case memory = "Memory"
    case concurrency = "Concurrency / Thread"
    case coreData = "Core Data"
    case codeSigning = "Code Signing"
    case widgetKit = "WidgetKit"
    case combine = "Combine"
    case metal = "Metal / GPU"
    case security = "Security / Keychain"
    case notification = "Notifications"
    case audioVideo = "Audio / Video"
    case accessibility = "Accessibility"
    case localization = "Localization"
    case testing = "Testing / XCTest"
    case packageManager = "SPM / Packages"
    case general = "General"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .swiftCompile: return "swift"
        case .swiftRuntime: return "bolt.fill"
        case .swiftUI: return "rectangle.on.rectangle"
        case .appKit: return "desktopcomputer"
        case .xcodeBuild: return "hammer.fill"
        case .network: return "network"
        case .fileSystem: return "folder.fill"
        case .permissions: return "lock.shield.fill"
        case .memory: return "memorychip.fill"
        case .concurrency: return "arrow.triangle.2.circlepath"
        case .coreData: return "cylinder.split.1x2"
        case .codeSigning: return "signature"
        case .widgetKit: return "square.grid.2x2"
        case .combine: return "arrow.merge"
        case .metal: return "cpu.fill"
        case .security: return "key.fill"
        case .notification: return "bell.fill"
        case .audioVideo: return "play.rectangle.fill"
        case .accessibility: return "accessibility"
        case .localization: return "globe"
        case .testing: return "checkmark.seal.fill"
        case .packageManager: return "shippingbox.fill"
        case .general: return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - Error Entry
struct ErrorEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let category: ErrorCategory
    let severity: ErrorSeverity
    let title: String
    let errorCode: String?
    let description: String
    let cause: String
    let solutions: [String]
    let codeExamples: [CodeExample]
    let relatedErrors: [String]
    let tags: [String]
    let appleDocURL: String?
    let commonInVersions: [String]
    
    init(
        id: UUID = UUID(),
        category: ErrorCategory,
        severity: ErrorSeverity,
        title: String,
        errorCode: String? = nil,
        description: String,
        cause: String,
        solutions: [String],
        codeExamples: [CodeExample] = [],
        relatedErrors: [String] = [],
        tags: [String] = [],
        appleDocURL: String? = nil,
        commonInVersions: [String] = []
    ) {
        self.id = id
        self.category = category
        self.severity = severity
        self.title = title
        self.errorCode = errorCode
        self.description = description
        self.cause = cause
        self.solutions = solutions
        self.codeExamples = codeExamples
        self.relatedErrors = relatedErrors
        self.tags = tags
        self.appleDocURL = appleDocURL
        self.commonInVersions = commonInVersions
    }
}

// MARK: - Code Example
struct CodeExample: Codable, Hashable, Identifiable {
    let id = UUID()
    let language: String
    let title: String
    let badCode: String
    let goodCode: String
    let explanation: String
}

// MARK: - Runtime Error Capture
struct CapturedRuntimeError: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let errorDomain: String
    let errorCode: Int
    let errorMessage: String
    let stackTrace: String?
    let file: String?
    let function: String?
    let line: Int?
    
    init(
        error: Error,
        stackTrace: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        self.id = UUID()
        self.timestamp = Date()
        let nsError = error as NSError
        self.errorDomain = nsError.domain
        self.errorCode = nsError.code
        self.errorMessage = nsError.localizedDescription
        self.stackTrace = stackTrace
        self.file = (file as NSString).lastPathComponent
        self.function = function
        self.line = line
    }
}

// MARK: - Search Result
struct ErrorSearchResult: Identifiable {
    let id = UUID()
    let entry: ErrorEntry
    let relevanceScore: Double
    let matchedField: String
}
