import Foundation
import Testing
@testable import ClassGod

@Suite("Complete uninstall safety")
struct UninstallServiceTests {
    @Test("Uninstall plan targets only ClassGod-owned paths")
    func createsScopedPlan() throws {
        let home = URL(fileURLWithPath: "/Users/tester", isDirectory: true)
        let app = URL(fileURLWithPath: "/Applications/ClassGod.app", isDirectory: true)
        let plan = try #require(UninstallPlan.make(bundleURL: app, homeDirectory: home))

        #expect(plan.bundleURL == app)
        #expect(plan.packageIdentifier == "com.hanazar.classgod.pkg")
        #expect(plan.userDataURLs.contains(home.appendingPathComponent("Library/Application Support/ClassGod", isDirectory: true)))
        #expect(plan.userDataURLs.contains(home.appendingPathComponent("Library/Application Support/com.hanazar.classgod", isDirectory: true)))
        #expect(plan.userDataURLs.contains(home.appendingPathComponent("Library/Containers/com.hanazar.classgod", isDirectory: true)))
        #expect(plan.userDataURLs.contains(home.appendingPathComponent("Library/Containers/com.hanazar.classgod.ClassGodWidget", isDirectory: true)))
        #expect(plan.userDataURLs.contains(home.appendingPathComponent("Library/Application Scripts/group.com.hanazar.classgod", isDirectory: true)))
        #expect(plan.userDataURLs.contains(home.appendingPathComponent("Library/Cookies/com.hanazar.classgod.binarycookies")))
        #expect(!plan.userDataURLs.contains(home))
        #expect(plan.systemURLs.contains(URL(fileURLWithPath: "/Library/Application Support/ClassGod", isDirectory: true)))
        #expect(plan.isSafe)
    }

    @Test("Uninstall resets every ClassGod permission domain and defaults domain")
    func resetsPermissionsAndDefaults() throws {
        let plan = try #require(UninstallPlan.make(
            bundleURL: URL(fileURLWithPath: "/Applications/ClassGod.app", isDirectory: true),
            homeDirectory: URL(fileURLWithPath: "/Users/tester", isDirectory: true)
        ))
        let commands = try #require(UninstallCommandBuilder.commands(
            plan: plan,
            userName: "tester"
        ))

        #expect(UninstallPlan.permissionBundleIdentifiers == [
            "com.hanazar.classgod",
            "com.hanazar.classgod.ClassGodWidget",
            "com.hanazar.classgod.helper",
        ])
        for identifier in UninstallPlan.permissionBundleIdentifiers {
            #expect(commands.contains { $0.contains("tccutil reset All '\(identifier)'") })
        }
        #expect(commands.contains { $0.contains("defaults delete 'com.hanazar.classgod'") })
        #expect(commands.contains { $0.contains("defaults delete 'com.hanazar.classgod.ClassGodWidget'") })
        #expect(commands.contains { $0.contains("pkill -x ClassGodWidget") })
    }

    @Test("Uninstall plan rejects broad or unexpected application targets")
    func rejectsUnsafeTargets() {
        let home = URL(fileURLWithPath: "/Users/tester", isDirectory: true)
        #expect(UninstallPlan.make(
            bundleURL: URL(fileURLWithPath: "/Applications/Other.app"),
            homeDirectory: home
        ) == nil)
        #expect(UninstallPlan.make(
            bundleURL: URL(fileURLWithPath: "/tmp/ClassGod.app"),
            homeDirectory: home
        ) == nil)
        #expect(UninstallPlan.make(
            bundleURL: URL(fileURLWithPath: "/Applications"),
            homeDirectory: home
        ) == nil)
    }

    @Test("Uninstall safety rejects forged user Library paths")
    func rejectsForgedUserDataPlan() throws {
        let home = URL(fileURLWithPath: "/Users/tester", isDirectory: true)
        let app = URL(fileURLWithPath: "/Applications/ClassGod.app", isDirectory: true)
        let valid = try #require(UninstallPlan.make(bundleURL: app, homeDirectory: home))
        let forged = UninstallPlan(
            bundleURL: valid.bundleURL,
            homeDirectory: valid.homeDirectory,
            userDataURLs: valid.userDataURLs + [home.appendingPathComponent("Library/Documents")],
            systemURLs: valid.systemURLs,
            packageIdentifier: valid.packageIdentifier
        )

        #expect(!forged.isSafe)
        #expect(UninstallCommandBuilder.command(plan: forged, userName: "tester") == nil)
    }

    @Test("Uninstall safety rejects forged home directories")
    func rejectsForgedHomeDirectory() throws {
        let valid = try #require(UninstallPlan.make(
            bundleURL: URL(fileURLWithPath: "/Applications/ClassGod.app", isDirectory: true),
            homeDirectory: URL(fileURLWithPath: "/Users/tester", isDirectory: true)
        ))
        let root = URL(fileURLWithPath: "/", isDirectory: true)
        let forged = UninstallPlan(
            bundleURL: valid.bundleURL,
            homeDirectory: root,
            userDataURLs: valid.userDataURLs.map {
                root.appendingPathComponent(
                    String($0.path.dropFirst("/Users/tester/".count))
                )
            },
            systemURLs: valid.systemURLs,
            packageIdentifier: valid.packageIdentifier
        )

        #expect(!forged.isSafe)
        #expect(UninstallCommandBuilder.command(plan: forged, userName: "tester") == nil)
    }

    @Test("Shell arguments preserve quotes without enabling command injection")
    func quotesShellArguments() {
        #expect(ShellArgument.quoted("plain") == "'plain'")
        #expect(ShellArgument.quoted("a'b; rm -rf /") == "'a'\"'\"'b; rm -rf /'")
    }
}
