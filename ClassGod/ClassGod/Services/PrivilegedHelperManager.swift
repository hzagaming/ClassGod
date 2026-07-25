import Foundation
import ServiceManagement
import Combine

enum HelperAuthorizationStatus: Equatable {
    case notRegistered
    case enabled
    case requiresApproval
    case notFound
}

@MainActor
final class PrivilegedHelperManager: ObservableObject {
    static let shared = PrivilegedHelperManager()
    static let plistName = "com.hanazar.classgod.helper.plist"

    @Published private(set) var status: HelperAuthorizationStatus = .notRegistered

    private let service = SMAppService.daemon(plistName: plistName)

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
        case .notFound:
            throw CocoaError(.fileNoSuchFile)
        case .notRegistered:
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
}
