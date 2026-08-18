import AppKit
import Carbon
import Foundation
import Testing
@testable import ClassGod

@Suite("Regression policies")
struct RegressionPolicyTests {
    @Test("Imported appearance geometry is finite and constrained to UI ranges")
    func normalizesImportedAppearanceGeometry() throws {
        let data = try #require(#"""
        {
          "version": 5,
          "windowOpacity": 4,
          "windowZoomScale": -2,
          "panelWidth": 1200,
          "panelMaxHeight": -50,
          "panelCornerRadius": 100,
          "rowHeight": 4
        }
        """#.data(using: .utf8))

        let preferences = try JSONDecoder().decode(AppPreferences.self, from: data)

        #expect(preferences.windowOpacity == 1)
        #expect(preferences.windowZoomScale == 0.5)
        #expect(preferences.panelWidth == 600)
        #expect(preferences.panelMaxHeight == 200)
        #expect(preferences.panelCornerRadius == 32)
        #expect(preferences.rowHeight == 32)
    }

    @Test("Non-finite imported appearance values fall back to defaults")
    func replacesNonFiniteImportedAppearanceGeometry() throws {
        var preferences = AppPreferences.default
        preferences.windowOpacity = .nan
        preferences.windowZoomScale = .infinity
        preferences.panelWidth = -.infinity

        let normalized = preferences.normalizedForStorage()

        #expect(normalized.windowOpacity == AppPreferences.default.windowOpacity)
        #expect(normalized.windowZoomScale == AppPreferences.default.windowZoomScale)
        #expect(normalized.panelWidth == AppPreferences.default.panelWidth)
    }

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

    @Test("Shortcut modifiers discard unsupported event flags")
    func normalizesCapturedShortcutModifiers() {
        let supported = NSEvent.ModifierFlags([.command, .shift]).rawValue
        let unsupported = NSEvent.ModifierFlags([.capsLock, .function, .numericPad]).rawValue
        let legacyCarbon = UInt32(cmdKey) | UInt32(shiftKey)

        #expect(ShortcutModifierPolicy.captured(supported | unsupported) == supported)
        #expect(ShortcutModifierPolicy.normalizedStored(UInt32(supported | unsupported)) == UInt32(supported))
        #expect(ShortcutModifierPolicy.normalizedStored(legacyCarbon) == UInt32(supported))
    }

    @Test("Activity search ignores surrounding and whitespace-only input")
    func normalizesActivitySearchQueries() {
        #expect(ActivitySearchQuery.normalized("  Safari  ") == "Safari")
        #expect(ActivitySearchQuery.normalized(" \n\t ") == nil)
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

    @Test("SuperSwitch search matches names and bundle identifiers")
    func filtersSuperSwitchTargets() {
        let safari = SwitchTarget(name: "Safari Study", bundleIdentifier: "com.apple.Safari")
        let notes = SwitchTarget(name: "Quick Notes", bundleIdentifier: "com.apple.Notes")

        #expect(SuperSwitchCatalogPolicy.filteredTargets([safari, notes], query: " safari apple ").map(\.id) == [safari.id])
        #expect(SuperSwitchCatalogPolicy.filteredTargets([safari, notes], query: "com.apple.notes").map(\.id) == [notes.id])
        #expect(SuperSwitchCatalogPolicy.filteredTargets([safari, notes], query: "  ").map(\.id) == [safari.id, notes.id])
        #expect(SuperSwitchCatalogPolicy.filteredTargets([safari, notes], query: "missing").isEmpty)
    }

    @Test("Shortcut catalog refresh removes stale shortcuts and registers every unique gesture")
    func plansShortcutCatalogRefresh() {
        let staleID = UUID()
        let tab = BrowserTab(
            title: "Study",
            url: "https://study.example",
            browser: .safari,
            shortcutKey: "F7"
        )
        let duplicate = SwitchTarget(
            name: "Finder",
            bundleIdentifier: "com.apple.finder",
            shortcutKey: "f7"
        )
        let unique = SwitchTarget(
            name: "Notes",
            bundleIdentifier: "com.apple.Notes",
            shortcutKey: "F8"
        )

        let plan = ShortcutCatalogRefreshPlan.make(
            previouslyRegistered: [staleID],
            tabs: [tab],
            targets: [duplicate, unique]
        )

        #expect(plan.unregisterIDs == [staleID])
        #expect(plan.registrationIDs == [tab.id, unique.id])
        #expect(plan.conflictingIDs == [duplicate.id])
        #expect(plan.configuredShortcutIDs == [tab.id, duplicate.id, unique.id])
    }

    @Test("DestinTab gestures win deterministic conflicts with SuperSwitch")
    func prioritizesTabShortcuts() {
        let firstTab = BrowserTab(
            title: "First",
            url: "https://first.example",
            browser: .safari,
            shortcutKey: "F9"
        )
        let secondTab = BrowserTab(
            title: "Second",
            url: "https://second.example",
            browser: .chrome,
            shortcutKey: "F9"
        )
        let target = SwitchTarget(
            name: "Notes",
            bundleIdentifier: "com.apple.Notes",
            shortcutKey: "F9"
        )

        let plan = ShortcutCatalogRefreshPlan.make(
            previouslyRegistered: [],
            tabs: [firstTab, secondTab],
            targets: [target]
        )

        #expect(plan.registrationIDs == [firstTab.id])
        #expect(plan.conflictingIDs == [secondTab.id, target.id])
    }

    @Test("Shortcut catalog rejects duplicate identifiers instead of replacing registrations")
    func rejectsDuplicateShortcutIdentifiers() {
        let id = UUID()
        let first = BrowserTab(
            id: id,
            title: "First",
            url: "https://first.example",
            browser: .safari,
            shortcutKey: "F7"
        )
        let second = BrowserTab(
            id: id,
            title: "Second",
            url: "https://second.example",
            browser: .chrome,
            shortcutKey: "F8"
        )

        let plan = ShortcutCatalogRefreshPlan.make(
            previouslyRegistered: [],
            tabs: [first, second],
            targets: []
        )

        #expect(plan.registrationIDs.isEmpty)
        #expect(plan.configuredShortcutIDs == [id])
        #expect(plan.conflictingIDs == [id])
    }

    @Test("Shortcut catalog state records every failed Carbon registration")
    func recordsFailedShortcutRegistrations() {
        let tab = BrowserTab(
            title: "Study",
            url: "https://study.example",
            browser: .safari,
            shortcutKey: "F7"
        )
        let target = SwitchTarget(
            name: "Notes",
            bundleIdentifier: "com.apple.Notes",
            shortcutKey: "F8"
        )
        let plan = ShortcutCatalogRefreshPlan.make(
            previouslyRegistered: [],
            tabs: [tab],
            targets: [target]
        )

        let state = ShortcutCatalogState.make(plan: plan, registeredIDs: [tab.id])

        #expect(state.registeredIDs == [tab.id])
        #expect(state.failedIDs == [target.id])
        #expect(state.configuredShortcutIDs == [tab.id, target.id])
    }

    @Test("Preflight reports a completely armed configuration as ready")
    func reportsReadyPreflight() {
        let tab = BrowserTab(
            title: "Study",
            url: "https://study.example/path",
            browser: .safari,
            shortcutKey: "F8"
        )
        let shortcutState = ShortcutCatalogState(
            configuredShortcutIDs: [tab.id],
            registeredIDs: [tab.id],
            failedIDs: [],
            conflictingIDs: []
        )

        let report = PreflightReportPolicy.make(
            accessibilityGranted: true,
            appleEventsGranted: true,
            tabs: [tab],
            targets: [],
            installedBundleIdentifiers: [BrowserType.safari.bundleIdentifier],
            shortcutState: shortcutState
        )

        #expect(report.status == .ready)
        #expect(PreflightCheckKind.allCases.allSatisfy { report[$0] == .ready })
    }

    @Test("Preflight normalizes target application identifiers before lookup")
    func normalizesPreflightApplicationIdentifiers() {
        let tab = BrowserTab(
            title: "Study",
            url: "https://study.example",
            browser: .safari
        )
        let target = SwitchTarget(
            name: "Notes",
            bundleIdentifier: "  com.apple.Notes\n"
        )

        #expect(PreflightApplicationPolicy.requiredBundleIdentifiers(
            tabs: [tab],
            targets: [target]
        ) == [BrowserType.safari.bundleIdentifier, "com.apple.Notes"])
    }

    @Test("Preflight blocks missing permissions, destinations, apps, and failed registrations")
    func reportsBlockedPreflight() {
        let tab = BrowserTab(
            title: "Broken",
            url: "not a web URL",
            browser: .chrome,
            shortcutKey: "F10"
        )
        let shortcutState = ShortcutCatalogState(
            configuredShortcutIDs: [tab.id],
            registeredIDs: [],
            failedIDs: [tab.id],
            conflictingIDs: []
        )
        let report = PreflightReportPolicy.make(
            accessibilityGranted: false,
            appleEventsGranted: false,
            tabs: [tab],
            targets: [],
            installedBundleIdentifiers: [],
            shortcutState: shortcutState
        )
        let empty = PreflightReportPolicy.make(
            accessibilityGranted: true,
            appleEventsGranted: true,
            tabs: [],
            targets: [],
            installedBundleIdentifiers: [],
            shortcutState: .empty
        )
        let invalidTarget = SwitchTarget(name: "Broken", bundleIdentifier: "   ")
        let invalidApplication = PreflightReportPolicy.make(
            accessibilityGranted: true,
            appleEventsGranted: true,
            tabs: [],
            targets: [invalidTarget],
            installedBundleIdentifiers: [],
            shortcutState: .empty
        )

        #expect(report[.accessibility] == .blocked)
        #expect(report[.appleEvents] == .blocked)
        #expect(report[.applications] == .blocked)
        #expect(report[.urls] == .blocked)
        #expect(report[.shortcuts] == .blocked)
        #expect(report.status == .blocked)
        #expect(empty[.destinations] == .blocked)
        #expect(empty[.applications] == .ready)
        #expect(invalidApplication[.destinations] == .ready)
        #expect(invalidApplication[.applications] == .blocked)
        #expect(invalidApplication.metrics.unavailableApplicationCount == 1)
    }

    @Test("Preflight flags partial availability, invalid URLs, conflicts, and absent shortcuts")
    func reportsPreflightAttention() {
        let valid = BrowserTab(
            title: "Study",
            url: "https://study.example",
            browser: .safari,
            shortcutKey: "F11"
        )
        let invalid = BrowserTab(
            title: "Broken",
            url: "file:///tmp/unsafe",
            browser: .chrome,
            shortcutKey: "F11"
        )
        let shortcutState = ShortcutCatalogState(
            configuredShortcutIDs: [valid.id, invalid.id],
            registeredIDs: [valid.id],
            failedIDs: [],
            conflictingIDs: [invalid.id]
        )
        let report = PreflightReportPolicy.make(
            accessibilityGranted: true,
            appleEventsGranted: true,
            tabs: [valid, invalid],
            targets: [],
            installedBundleIdentifiers: [BrowserType.safari.bundleIdentifier],
            shortcutState: shortcutState
        )
        let noShortcut = PreflightReportPolicy.make(
            accessibilityGranted: true,
            appleEventsGranted: true,
            tabs: [BrowserTab(title: "Study", url: "https://study.example", browser: .safari)],
            targets: [],
            installedBundleIdentifiers: [BrowserType.safari.bundleIdentifier],
            shortcutState: .empty
        )

        #expect(report[.applications] == .attention)
        #expect(report[.urls] == .attention)
        #expect(report[.shortcuts] == .attention)
        #expect(report.status == .attention)
        #expect(noShortcut[.shortcuts] == .attention)
    }

    @Test("Tab access is recorded only after a successful switch")
    func recordsOnlySuccessfulTabSwitches() {
        #expect(TabSwitchCompletionPolicy.shouldRecordAccess(success: true))
        #expect(!TabSwitchCompletionPolicy.shouldRecordAccess(success: false))
    }

    @Test("Browser tab drafts trim fields and require a valid web URL")
    func normalizesBrowserTabDrafts() {
        let valid = BrowserTabDraft(
            title: "  Study Notes  ",
            url: " example.com/notes and tasks \n",
            tag: " school "
        )
        let blank = BrowserTabDraft(title: " \t", url: "example.com", tag: "")
        let missingHost = BrowserTabDraft(title: "Study", url: "https://", tag: "")
        let unsupportedScheme = BrowserTabDraft(title: "Study", url: "file:///tmp/test", tag: "")

        #expect(valid.title == "Study Notes")
        #expect(valid.url == "https://example.com/notes%20and%20tasks")
        #expect(valid.tag == "school")
        #expect(valid.canSave)
        #expect(!blank.canSave)
        #expect(!missingHost.canSave)
        #expect(!unsupportedScheme.canSave)
    }

    @Test("SuperSwitch target drafts trim input and reject blank values")
    func normalizesSuperSwitchTargetDrafts() {
        let valid = SuperSwitchTargetDraft(name: "  Study  ", bundleIdentifier: " com.example.study\n")
        let invalid = SuperSwitchTargetDraft(name: " \t", bundleIdentifier: "com.example.empty")

        #expect(valid.name == "Study")
        #expect(valid.bundleIdentifier == "com.example.study")
        #expect(valid.canSave)
        #expect(!invalid.canSave)
    }

    @Test("BrowserBypasser rule drafts trim input and reject blank values")
    func normalizesBrowserBypassRuleDrafts() {
        let valid = BrowserBypassRuleDraft(name: "  Canvas Quiz  ", targetURLPattern: " canvas.*quiz\n")
        let invalid = BrowserBypassRuleDraft(name: " \t", targetURLPattern: "docs.example")

        #expect(valid.name == "Canvas Quiz")
        #expect(valid.targetURLPattern == "canvas.*quiz")
        #expect(valid.canSave)
        #expect(!invalid.canSave)
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

    @Test("Settings navigation exposes every page with stable metadata")
    func validatesSettingsNavigation() {
        #expect(SettingsPage.allCases == [
            .general, .shortcuts, .appearance, .browser, .advanced, .fan, .updates,
        ])
        #expect(Set(SettingsPage.allCases.map(\.id)).count == SettingsPage.allCases.count)
        #expect(SettingsWindowLayoutPolicy.baseWidth == 720)
        #expect(SettingsWindowLayoutPolicy.baseHeight == 620)
        for page in SettingsPage.allCases {
            #expect(!page.iconName.isEmpty)
            #expect(!page.accessibilityTitle.isEmpty)
        }
    }

    @Test("Feature windows have independent defaults and minimum sizes")
    func validatesFeatureWindowLayouts() {
        let layouts = FeatureWindowKind.allCases.map(FeatureWindowLayoutPolicy.layout(for:))
        #expect(Set(layouts.map(\.defaultWidth)).count >= 6)
        #expect(Set(layouts.map(\.defaultHeight)).count >= 5)
        #expect(layouts.allSatisfy { $0.defaultWidth >= $0.minimumWidth })
        #expect(layouts.allSatisfy { $0.defaultHeight >= $0.minimumHeight })
        #expect(FeatureWindowLayoutPolicy.layout(for: .wallpaper).defaultWidth == 860)
        #expect(FeatureWindowLayoutPolicy.layout(for: .fanControl).defaultWidth == 680)
        #expect(FeatureWindowLayoutPolicy.layout(for: .permissionCenter).defaultWidth == 900)
        #expect(FeatureWindowLayoutPolicy.layout(for: .preflight).defaultWidth == 760)
    }

    @Test("Unrelated preference changes never reset manually resized feature windows")
    func preservesManualFeatureWindowSizes() {
        #expect(!FeatureWindowResizePolicy.shouldApplyScale(previousZoom: 1, currentZoom: 1))
        #expect(FeatureWindowResizePolicy.shouldApplyScale(previousZoom: 1, currentZoom: 1.2))
        #expect(WindowChromePolicy.cornerRadius(base: 12, zoom: 1.25) == 15)
        #expect(WindowChromePolicy.cornerRadius(base: -4, zoom: 1) == 0)
        #expect(WindowChromePolicy.cornerRadius(base: 12, zoom: .nan) == 0)
    }

    @Test("Fake Lock normalizes safe browser URLs")
    func normalizesFakeLockURLs() {
        #expect(FakeLockURLPolicy.normalized("  example.com/test  ")?.absoluteString == "https://example.com/test")
        #expect(FakeLockURLPolicy.normalized("https://example.com")?.host == "example.com")
        #expect(FakeLockURLPolicy.normalized("") == nil)
        #expect(FakeLockURLPolicy.normalized("ftp://example.com") == nil)
        #expect(FakeLockURLPolicy.normalized("https://") == nil)
    }

    @Test("Fake Lock applies independent backward and forward navigation locks")
    func validatesFakeLockNavigationPolicy() {
        #expect(FakeLockNavigationPolicy.decision(
            for: .backward,
            lockBackward: true,
            lockForward: false
        ) == .blocked)
        #expect(FakeLockNavigationPolicy.decision(
            for: .forward,
            lockBackward: true,
            lockForward: false
        ) == .allowed)
        #expect(FakeLockNavigationPolicy.decision(
            for: .forward,
            lockBackward: false,
            lockForward: true
        ) == .blocked)
    }

    @Test("MapTest sessions always request full screen")
    func validatesFakeLockFullScreenPolicy() {
        #expect(FakeLockSessionPolicy.shouldOpenFullScreen(mode: .mapTestBypass, requested: false))
        #expect(FakeLockSessionPolicy.shouldOpenFullScreen(mode: .safeBrowser, requested: true))
        #expect(!FakeLockSessionPolicy.shouldOpenFullScreen(mode: .safeBrowser, requested: false))
    }

    @Test("Stopped Fake Lock operations reject stale async results")
    func cancelsFakeLockOperations() {
        var session = FakeLockOperationSession()
        let first = session.begin()
        #expect(session.isCurrent(first))

        session.cancel()
        #expect(!session.isCurrent(first))
        let staleCompletion = session.complete(first)
        #expect(!staleCompletion)

        let second = session.begin()
        #expect(session.isCurrent(second))
        let currentCompletion = session.complete(second)
        #expect(currentCompletion)
        #expect(!session.isCurrent(second))
    }

    @Test("Fake Lock navigation completions require the current active session")
    func rejectsStaleFakeLockNavigationCompletions() {
        #expect(FakeLockNavigationCompletionPolicy.shouldApply(
            isSessionActive: true,
            operationIsCurrent: true
        ))
        #expect(!FakeLockNavigationCompletionPolicy.shouldApply(
            isSessionActive: false,
            operationIsCurrent: true
        ))
        #expect(!FakeLockNavigationCompletionPolicy.shouldApply(
            isSessionActive: true,
            operationIsCurrent: false
        ))
    }

    @Test("Fractional refresh intervals keep their precision")
    func formatsSettingsIntervals() {
        #expect(SettingsValueFormatter.seconds(0.5) == "0.5s")
        #expect(SettingsValueFormatter.seconds(10) == "10.0s")
    }
}
