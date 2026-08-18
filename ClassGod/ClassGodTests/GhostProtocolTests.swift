import Foundation
import Testing
@testable import ClassGod

@Suite("Ghost Protocol safety")
struct GhostProtocolTests {
    @Test("Only visible regular applications enter the hide plan")
    func filtersHidePlan() {
        let applications = [
            GhostApplicationDescriptor(bundleIdentifier: "com.game", isRegular: true, isHidden: false, isTerminated: false, isFrontmost: true),
            GhostApplicationDescriptor(bundleIdentifier: "com.chat", isRegular: true, isHidden: false, isTerminated: false, isFrontmost: false),
            GhostApplicationDescriptor(bundleIdentifier: "com.chat", isRegular: true, isHidden: false, isTerminated: false, isFrontmost: false),
            GhostApplicationDescriptor(bundleIdentifier: "com.cover", isRegular: true, isHidden: false, isTerminated: false, isFrontmost: false),
            GhostApplicationDescriptor(bundleIdentifier: "com.classgod", isRegular: true, isHidden: false, isTerminated: false, isFrontmost: false),
            GhostApplicationDescriptor(bundleIdentifier: "com.hidden", isRegular: true, isHidden: true, isTerminated: false, isFrontmost: false),
            GhostApplicationDescriptor(bundleIdentifier: "com.agent", isRegular: false, isHidden: false, isTerminated: false, isFrontmost: false),
            GhostApplicationDescriptor(bundleIdentifier: "com.terminated", isRegular: true, isHidden: false, isTerminated: true, isFrontmost: false),
            GhostApplicationDescriptor(bundleIdentifier: nil, isRegular: true, isHidden: false, isTerminated: false, isFrontmost: false)
        ]

        let plan = GhostProtocolPlanner.makePlan(
            applications: applications,
            targetBundleIdentifier: "com.cover",
            ownBundleIdentifier: "com.classgod"
        )

        #expect(plan.bundleIdentifiersToHide == ["com.game", "com.chat"])
        #expect(plan.originalFrontmostBundleIdentifier == "com.game")
    }

    @Test("Frontmost cover application is never restored over itself")
    func excludesCoverFromRestoreFocus() {
        let plan = GhostProtocolPlanner.makePlan(
            applications: [
                GhostApplicationDescriptor(bundleIdentifier: "com.cover", isRegular: true, isHidden: false, isTerminated: false, isFrontmost: true)
            ],
            targetBundleIdentifier: "com.cover",
            ownBundleIdentifier: "com.classgod"
        )

        #expect(plan.bundleIdentifiersToHide.isEmpty)
        #expect(plan.originalFrontmostBundleIdentifier == nil)
    }

    @Test("Hidden applications never enter the restore snapshot")
    func excludesAlreadyHiddenApplications() {
        let plan = GhostProtocolPlanner.makePlan(
            applications: [
                GhostApplicationDescriptor(bundleIdentifier: "com.hidden", isRegular: true, isHidden: true, isTerminated: false, isFrontmost: true)
            ],
            targetBundleIdentifier: "com.cover",
            ownBundleIdentifier: "com.classgod"
        )

        #expect(plan.bundleIdentifiersToHide.isEmpty)
        #expect(plan.originalFrontmostBundleIdentifier == nil)
    }

    @Test("ClassGod stays visible but is restored as the original front application")
    func restoresClassGodFocus() {
        let plan = GhostProtocolPlanner.makePlan(
            applications: [
                GhostApplicationDescriptor(bundleIdentifier: "com.classgod", isRegular: true, isHidden: false, isTerminated: false, isFrontmost: true),
                GhostApplicationDescriptor(bundleIdentifier: "com.game", isRegular: true, isHidden: false, isTerminated: false, isFrontmost: false)
            ],
            targetBundleIdentifier: "com.cover",
            ownBundleIdentifier: "com.classgod"
        )

        #expect(plan.bundleIdentifiersToHide == ["com.game"])
        #expect(plan.originalFrontmostBundleIdentifier == "com.classgod")
    }

    @Test("Built-in and SuperSwitch destinations merge without duplicates")
    func mergesDestinations() {
        let savedTargets = [
            SwitchTarget(name: "Finder Custom", bundleIdentifier: "com.apple.finder", iconName: "folder.fill"),
            SwitchTarget(name: "Study", bundleIdentifier: "com.example.study", iconName: "book.fill")
        ]

        let destinations = GhostDestination.merged(with: savedTargets)

        #expect(destinations.first?.bundleIdentifier == "com.apple.finder")
        #expect(destinations.filter { $0.bundleIdentifier == "com.apple.finder" }.count == 1)
        #expect(destinations.contains { $0.bundleIdentifier == "com.example.study" && $0.name == "Study" })
    }

    @Test("Missing settings fields adopt safe defaults")
    func decodesSafeDefaults() throws {
        let settings = try JSONDecoder().decode(GhostProtocolSettings.self, from: Data("{}".utf8))

        #expect(settings == .default)
        #expect(settings.targetBundleIdentifier == "com.apple.finder")
        #expect(settings.shortcutKey == "F7")
        #expect(settings.hideOtherApplications)
    }

    @Test("Shortcut mapping accepts supported keys and rejects unknown keys")
    func mapsShortcutKeys() {
        #expect(ShortcutManager.shared.keyCode(for: "F7") == 0x62)
        #expect(ShortcutManager.shared.keyCode(for: "a") == 0x00)
        #expect(ShortcutManager.shared.keyCode(for: "Space") == 0x31)
        #expect(ShortcutManager.shared.keyCode(for: "unknown") == nil)
    }

    @Test("ClassGod shortcuts keep priority over Ghost Protocol")
    func preservesExistingShortcutPriority() {
        let f7 = CarbonShortcut(keyCode: 0x62, modifiers: 0)
        let commandF7 = CarbonShortcut(keyCode: 0x62, modifiers: 0x0100)

        #expect(GhostShortcutPolicy.isReserved(f7, reservedShortcuts: [f7]))
        #expect(!GhostShortcutPolicy.isReserved(commandF7, reservedShortcuts: [f7]))
    }
}
