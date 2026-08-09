import Foundation
import ServiceManagement
import Combine

enum HelperAuthorizationStatus: Equatable {
    case notRegistered
    case enabled
    case requiresApproval
    case notFound
}

enum HelperBundlePolicy {
    static let daemonRelativePath = "Contents/Library/LaunchDaemons/com.hanazar.classgod.helper.plist"
    static let executableRelativePath = "Contents/Resources/ClassGodHelper"

    static func hasEmbeddedService(
        in bundleURL: URL,
        fileManager: FileManager = .default
    ) -> Bool {
        let plistURL = bundleURL.appendingPathComponent(daemonRelativePath)
        let executableURL = bundleURL.appendingPathComponent(executableRelativePath)
        return fileManager.fileExists(atPath: plistURL.path)
            && fileManager.isExecutableFile(atPath: executableURL.path)
    }
}

enum HelperAuthorizationPolicy {
    static func canRequest(
        status: HelperAuthorizationStatus,
        hasEmbeddedService: Bool
    ) -> Bool {
        status != .notFound || hasEmbeddedService
    }
}

@MainActor
final class PrivilegedHelperManager: ObservableObject {
    static let shared = PrivilegedHelperManager()
    static let plistName = "com.hanazar.classgod.helper.plist"

    @Published private(set) var status: HelperAuthorizationStatus = .notRegistered

    private let service = SMAppService.daemon(plistName: plistName)
    var hasEmbeddedService: Bool {
        HelperBundlePolicy.hasEmbeddedService(in: Bundle.main.bundleURL)
    }

    private init() {
        refreshStatus()
    }

    @discardableResult
    func refreshStatus() -> HelperAuthorizationStatus {
        switch service.status {
        case .notRegistered:
            status = .notRegistered
        case .enabled:
            status = .enabled
        case .requiresApproval:
            status = .requiresApproval
        case .notFound:
            status = .notFound
        @unknown default:
            status = .notFound
        }
        return status
    }

    @discardableResult
    func requestAuthorization() throws -> HelperAuthorizationStatus {
        switch refreshStatus() {
        case .enabled, .requiresApproval:
            return status
        case .notRegistered, .notFound:
            guard HelperAuthorizationPolicy.canRequest(
                status: status,
                hasEmbeddedService: hasEmbeddedService
            ) else {
                throw CocoaError(.fileNoSuchFile)
            }
            do {
                try service.register()
            } catch {
                if refreshStatus() != .requiresApproval {
                    throw error
                }
            }
            return refreshStatus()
        }
    }

    func openApprovalSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    func unregisterForUninstall() throws {
        switch refreshStatus() {
        case .notRegistered, .notFound:
            return
        case .enabled, .requiresApproval:
            do {
                try service.unregister()
            } catch {
                let refreshed = refreshStatus()
                guard refreshed == .notRegistered || refreshed == .notFound else {
                    throw error
                }
            }
            status = .notRegistered
        }
    }
}
