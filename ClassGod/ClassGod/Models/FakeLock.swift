import AppKit
import Foundation

enum FakeLockMode: String, Codable, CaseIterable, Identifiable {
    case safeBrowser
    case mapTestBypass

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .safeBrowser: String(localized: "fake_lock.mode.safe_browser")
        case .mapTestBypass: String(localized: "fake_lock.mode.maptest")
        }
    }
}

nonisolated enum FakeLockDirection {
    case backward
    case forward
}

enum FakeLockNavigationDecision: Equatable {
    case allowed
    case blocked
}

enum FakeLockNavigationPolicy {
    static func decision(
        for direction: FakeLockDirection,
        lockBackward: Bool,
        lockForward: Bool
    ) -> FakeLockNavigationDecision {
        switch direction {
        case .backward: lockBackward ? .blocked : .allowed
        case .forward: lockForward ? .blocked : .allowed
        }
    }
}

enum FakeLockURLPolicy {
    static func normalized(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let components = URLComponents(string: candidate),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host,
              !host.isEmpty else { return nil }
        return components.url
    }
}

enum FakeLockSessionPolicy {
    static func shouldOpenFullScreen(mode: FakeLockMode, requested: Bool) -> Bool {
        mode == .mapTestBypass || requested
    }
}

nonisolated struct FakeLockOperationSession: Sendable {
    private(set) var generation: UInt = 0
    private(set) var isActive = false

    mutating func begin() -> UInt {
        generation &+= 1
        isActive = true
        return generation
    }

    mutating func cancel() {
        generation &+= 1
        isActive = false
    }

    func isCurrent(_ request: UInt) -> Bool {
        isActive && request == generation
    }

    mutating func complete(_ request: UInt) -> Bool {
        guard isCurrent(request) else { return false }
        isActive = false
        return true
    }
}

struct FakeLockConfiguration: Codable, Equatable {
    var mode: FakeLockMode
    var browser: BrowserType
    var url: String
    var lockBackward: Bool
    var lockForward: Bool
    var openFullScreen: Bool
    var shortcutKey: String
    var shortcutModifiers: UInt

    static let `default` = FakeLockConfiguration(
        mode: .safeBrowser,
        browser: .safari,
        url: "https://example.com",
        lockBackward: true,
        lockForward: true,
        openFullScreen: true,
        shortcutKey: "L",
        shortcutModifiers: NSEvent.ModifierFlags([.command, .shift]).rawValue
    )
}
