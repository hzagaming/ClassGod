import Foundation
import Testing
@testable import ClassGod

@Suite("Regression policies")
struct RegressionPolicyTests {
    @Test("Browser responses split at the final delimiter and require a URL")
    func parsesBrowserDetectionResponses() {
        let delimiter = "\u{001E}"
        let parsed = BrowserDetectionResponseParser.parse(
            "Section\(delimiter)Title\(delimiter)https://example.com/path",
            delimiter: delimiter,
            browser: .safari
        )

        #expect(parsed?.title == "Section\(delimiter)Title")
        #expect(parsed?.url == "https://example.com/path")
        #expect(BrowserDetectionResponseParser.parse(
            "Title\(delimiter)   ",
            delimiter: delimiter,
            browser: .safari
        ) == nil)
    }

    @Test("AppleScript literals escape quotes and backslashes")
    func escapesAppleScriptLiterals() {
        #expect(AppleScriptLiteral.escaped(#"a"b\c"#) == #"a\"b\\c"#)
    }

    @Test("Host-only matching respects URL authority boundaries")
    func matchesExactBrowserHosts() {
        #expect(BrowserURLMatchPolicy.matchesHost(
            tabURL: "https://example.com/path",
            targetURL: "https://example.com/other"
        ))
        #expect(!BrowserURLMatchPolicy.matchesHost(
            tabURL: "https://notexample.com/path",
            targetURL: "https://example.com/other"
        ))
        #expect(!BrowserURLMatchPolicy.matchesHost(
            tabURL: "https://evil.test/?next=example.com",
            targetURL: "https://example.com/other"
        ))
        let condition = BrowserURLMatchPolicy.appleScriptHostCondition(targetURL: "https://example.com/other")
        #expect(condition.contains("tabURL starts with \"https://example.com/\""))
        #expect(!condition.contains("tabURL contains"))
    }

    @Test("Shortcut capture accepts only registerable combinations")
    func validatesCapturedShortcuts() {
        #expect(!ShortcutCapturePolicy.shouldAccept(keyName: "", keyCode: nil, modifiers: 1, isFunctionKey: false, isNumericPad: false))
        #expect(!ShortcutCapturePolicy.shouldAccept(keyName: "1", keyCode: 0x12, modifiers: 0, isFunctionKey: false, isNumericPad: false))
        #expect(!ShortcutCapturePolicy.shouldAccept(keyName: "1", keyCode: 0x12, modifiers: 1, isFunctionKey: false, isNumericPad: true))
        #expect(ShortcutCapturePolicy.shouldAccept(keyName: "1", keyCode: 0x12, modifiers: 1, isFunctionKey: false, isNumericPad: false))
        #expect(ShortcutCapturePolicy.shouldAccept(keyName: "F7", keyCode: 0x62, modifiers: 0, isFunctionKey: true, isNumericPad: false))
    }

    @Test("Battery fractions remain finite and bounded")
    func normalizesBatteryFractions() {
        #expect(BatteryLevelPolicy.fraction(current: 50, maximum: 100) == 0.5)
        #expect(BatteryLevelPolicy.fraction(current: 100, maximum: 0) == 0)
        #expect(BatteryLevelPolicy.fraction(current: 150, maximum: 100) == 1)
        #expect(BatteryLevelPolicy.fraction(current: -1, maximum: 100) == 0)
    }

    @Test("Error search ignores whitespace-only queries")
    func normalizesErrorSearchQueries() {
        #expect(ErrorSearchQuery.normalized("  \n\t ") == nil)
        #expect(ErrorSearchQuery.normalized("  NSURLError -1009  ") == "NSURLError -1009")
    }

    @Test("App switching reports the actual activation or launch result")
    func resolvesAppSwitchOutcomes() {
        #expect(AppSwitchOutcome.activation(didActivate: true) == .success)
        #expect(AppSwitchOutcome.activation(didActivate: false) == .failure)
        #expect(AppSwitchOutcome.launch(hasApplication: true, hasError: false) == .success)
        #expect(AppSwitchOutcome.launch(hasApplication: false, hasError: false) == .failure)
        #expect(AppSwitchOutcome.launch(hasApplication: true, hasError: true) == .failure)
    }

    @Test("Dismissed boot sequences reject stale callbacks")
    func cancelsBootSequenceCallbacks() {
        var session = BootSequenceSession()
        let request = session.begin()
        #expect(session.isCurrent(request))
        session.cancel()
        #expect(!session.isCurrent(request))
    }

    @Test("Only the latest delayed browser switch remains current")
    func supersedesDelayedBrowserSwitches() {
        var session = BrowserSwitchSession()
        let first = session.begin()
        let second = session.begin()

        #expect(!session.isCurrent(first))
        #expect(session.isCurrent(second))
    }

    @Test("Pinned tabs preserve their relative order")
    func preservesRelativeOrderWhenGroupingPinnedTabs() {
        let first = BrowserTab(title: "First", url: "https://first.example", browser: .safari)
        let second = BrowserTab(title: "Second", url: "https://second.example", browser: .chrome, isPinned: true)
        let third = BrowserTab(title: "Third", url: "https://third.example", browser: .edge)
        let fourth = BrowserTab(title: "Fourth", url: "https://fourth.example", browser: .safari, isPinned: true)

        let ordered = TabOrderingPolicy.pinnedFirstPreservingOrder([first, second, third, fourth])

        #expect(ordered.map(\.id) == [second.id, fourth.id, first.id, third.id])
    }

    @Test("Bulk selection only includes rendered tabs")
    func limitsBulkSelectionToRenderedTabs() {
        let tabs = (1...4).map {
            BrowserTab(title: "Tab \($0)", url: "https://\($0).example", browser: .safari)
        }

        let selected = TabSelectionPolicy.visibleIDs(in: tabs, limit: 2)

        #expect(selected == Set(tabs.prefix(2).map(\.id)))
        #expect(!selected.contains(tabs[2].id))
    }

    @Test("Stale bulk selection is removed after a reload")
    func removesStaleBulkSelection() {
        let existing = BrowserTab(title: "Existing", url: "https://existing.example", browser: .safari)
        let removed = BrowserTab(title: "Removed", url: "https://removed.example", browser: .chrome)

        let reconciled = TabSelectionPolicy.reconciled(
            selectedIDs: [existing.id, removed.id],
            tabs: [existing]
        )

        #expect(reconciled == [existing.id])
    }

    @Test("Bulk actions exclude selections hidden by a later filter")
    func excludesSelectionsHiddenAfterSelection() {
        let first = BrowserTab(title: "First", url: "https://first.example", browser: .safari)
        let second = BrowserTab(title: "Second", url: "https://second.example", browser: .chrome)

        let visibleSelection = TabSelectionPolicy.selectedVisibleIDs(
            selectedIDs: [first.id, second.id],
            visibleTabs: [second],
            limit: 10
        )

        #expect(visibleSelection == [second.id])
    }

    @Test("Preference export replaces an existing file")
    func replacesExistingExportFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let destination = directory.appendingPathComponent("preferences.json")
        try Data("old".utf8).write(to: destination)

        try PreferencesExportWriter.write(Data("new".utf8), to: destination)

        #expect(try Data(contentsOf: destination) == Data("new".utf8))
    }
}
