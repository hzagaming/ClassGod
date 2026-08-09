import AppKit
import Combine
import Foundation

struct UninstallPlan: Equatable {
    static let applicationPath = "/Applications/ClassGod.app"
    static let bundleIdentifier = "com.hanazar.classgod"
    static let widgetBundleIdentifier = "com.hanazar.classgod.ClassGodWidget"
    static let packageIdentifier = "com.hanazar.classgod.pkg"
    private static let userRelativePaths = [
        "Library/Preferences/\(bundleIdentifier).plist",
        "Library/Preferences/\(widgetBundleIdentifier).plist",
        "Library/Application Support/ClassGod",
        "Library/Application Support/\(bundleIdentifier)",
        "Library/Caches/\(bundleIdentifier)",
        "Library/Caches/\(widgetBundleIdentifier)",
        "Library/HTTPStorages/\(bundleIdentifier)",
        "Library/Logs/ClassGod",
        "Library/Saved Application State/\(bundleIdentifier).savedState",
        "Library/WebKit/\(bundleIdentifier)",
        "Library/Containers/\(widgetBundleIdentifier)",
        "Library/Group Containers/group.com.hanazar.classgod",
        "Library/Application Scripts/\(widgetBundleIdentifier)",
    ]

    let bundleURL: URL
    let homeDirectory: URL
    let userDataURLs: [URL]
    let systemURLs: [URL]
    let packageIdentifier: String

    static func make(bundleURL: URL, homeDirectory: URL) -> UninstallPlan? {
        let bundle = bundleURL.standardizedFileURL
        let home = homeDirectory.standardizedFileURL
        guard bundle.path == applicationPath,
              isValidHomeDirectory(home) else { return nil }

        let userDataURLs = Self.userRelativePaths.map {
            home.appendingPathComponent($0, isDirectory: !$0.hasSuffix(".plist"))
        }
        let systemURLs = [
            URL(fileURLWithPath: "/Library/LaunchDaemons/com.hanazar.classgod.helper.plist"),
            URL(fileURLWithPath: "/Library/PrivilegedHelperTools/com.hanazar.classgod.helper"),
            URL(fileURLWithPath: "/tmp/com.hanazar.classgod.helper.sock"),
        ]
        let plan = UninstallPlan(
            bundleURL: bundle,
            homeDirectory: home,
            userDataURLs: userDataURLs,
            systemURLs: systemURLs,
            packageIdentifier: packageIdentifier
        )
        return plan.isSafe ? plan : nil
    }

    var isSafe: Bool {
        guard bundleURL.standardizedFileURL.path == Self.applicationPath,
              Self.isValidHomeDirectory(homeDirectory),
              packageIdentifier == Self.packageIdentifier else { return false }
        let allowedUserPaths = Set(Self.userRelativePaths.map {
            homeDirectory.appendingPathComponent($0).standardizedFileURL.path
        })
        guard Set(userDataURLs.map { $0.standardizedFileURL.path }) == allowedUserPaths else {
            return false
        }
        let allowedSystemPaths: Set<String> = [
            "/Library/LaunchDaemons/com.hanazar.classgod.helper.plist",
            "/Library/PrivilegedHelperTools/com.hanazar.classgod.helper",
            "/tmp/com.hanazar.classgod.helper.sock",
        ]
        return Set(systemURLs.map { $0.standardizedFileURL.path }) == allowedSystemPaths
    }

    private static func isValidHomeDirectory(_ url: URL) -> Bool {
        let home = url.standardizedFileURL
        return home.path.hasPrefix("/Users/") && home.pathComponents.count == 3
    }
}

enum ShellArgument {
    static func quoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
    }
}

enum UninstallCommandBuilder {
    static func command(plan: UninstallPlan, userName: String) -> String? {
        guard plan.isSafe, !userName.isEmpty else { return nil }
        let user = ShellArgument.quoted(userName)
        let userData = plan.userDataURLs.map { ShellArgument.quoted($0.path) }.joined(separator: " ")
        let systemData = plan.systemURLs.map { ShellArgument.quoted($0.path) }.joined(separator: " ")
        let app = ShellArgument.quoted(plan.bundleURL.path)
        let commands = [
            "/bin/sleep 2",
            "/bin/launchctl bootout system/com.hanazar.classgod.helper >/dev/null 2>&1 || true",
            "/usr/bin/pkill -x ClassGodHelper >/dev/null 2>&1 || true",
            "/usr/bin/pkill -x ClassGod >/dev/null 2>&1 || true",
            "/bin/sleep 1",
            "/usr/bin/sudo -u \(user) /usr/bin/tccutil reset All \(ShellArgument.quoted(UninstallPlan.bundleIdentifier)) >/dev/null 2>&1 || true",
            "/usr/bin/sudo -u \(user) /usr/bin/tccutil reset All \(ShellArgument.quoted(UninstallPlan.widgetBundleIdentifier)) >/dev/null 2>&1 || true",
            "/usr/bin/sudo -u \(user) /usr/bin/defaults delete \(ShellArgument.quoted(UninstallPlan.bundleIdentifier)) >/dev/null 2>&1 || true",
            "/usr/sbin/pkgutil --forget \(ShellArgument.quoted(plan.packageIdentifier)) >/dev/null 2>&1 || true",
            "/bin/rm -rf \(systemData) \(userData) \(app)",
        ]
        return "/bin/sh -c " + ShellArgument.quoted(
            "(" + commands.joined(separator: "; ") + ") >/dev/null 2>&1 &"
        )
    }
}

@MainActor
final class UninstallService: ObservableObject {
    static let shared = UninstallService()

    @Published private(set) var isUninstalling = false
    @Published private(set) var errorMessage: String?

    private init() {}

    func clearError() {
        errorMessage = nil
    }

    func uninstall() {
        guard !isUninstalling else { return }
        guard let plan = UninstallPlan.make(
            bundleURL: Bundle.main.bundleURL,
            homeDirectory: FileManager.default.homeDirectoryForCurrentUser
        ), let command = UninstallCommandBuilder.command(plan: plan, userName: NSUserName()) else {
            errorMessage = String(localized: "uninstall.error.invalid_installation")
            return
        }

        isUninstalling = true
        errorMessage = nil
        do {
            try PrivilegedHelperManager.shared.unregisterForUninstall()
        } catch {
            isUninstalling = false
            errorMessage = String(format: String(localized: "uninstall.error.helper"), error.localizedDescription)
            return
        }

        Task {
            let result = await Self.runAuthorized(command)
            guard result.success else {
                isUninstalling = false
                errorMessage = result.message
                return
            }
            NSApp.terminate(nil)
        }
    }

    private nonisolated static func runAuthorized(
        _ command: String
    ) async -> (success: Bool, message: String) {
        await Task.detached(priority: .userInitiated) {
            let source = "do shell script \"\(AppleScriptLiteral.escaped(command))\" with administrator privileges"
            guard let script = NSAppleScript(source: source) else {
                return (false, String(localized: "uninstall.error.script"))
            }
            var errorInfo: NSDictionary?
            _ = script.executeAndReturnError(&errorInfo)
            guard let errorInfo else { return (true, "") }
            let message = errorInfo[NSAppleScript.errorMessage] as? String
                ?? String(localized: "uninstall.error.failed")
            return (false, message)
        }.value
    }
}
