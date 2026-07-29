import Foundation
import AppKit
import Testing
@testable import ClassGod

@Suite("Clipo clipboard policies")
struct ClipoTests {
    @Test("Settings normalization is stable and clamps persisted values")
    func settingsNormalization() {
        var settings = ClipoSettings()
        settings.maxHistoryItems = 9_999
        settings.pasteDelay = -1
        settings.sensitiveBundleIdentifiers = [
            " com.example.Secret ",
            "COM.EXAMPLE.SECRET",
            "",
            "com.example.Other",
        ]

        let normalized = settings.normalized

        #expect(normalized.maxHistoryItems == 2_000)
        #expect(normalized.pasteDelay == 0)
        #expect(normalized.sensitiveBundleIdentifiers == ["com.example.Secret", "com.example.Other"])
        #expect(normalized.normalized == normalized)
    }

    @Test("UTF-16 clipboard text decodes without data loss")
    func decodesUTF16ClipboardText() throws {
        let text = "ClassGod 剪贴板"
        let data = try #require(text.data(using: .utf16))
        let payload = ClipoPayload(items: [
            ClipoPayloadItem(representations: [
                ClipoRepresentation(type: "public.utf16-external-plain-text", data: data)
            ])
        ])

        #expect(payload.plainText == text)
        #expect(payload.preview == text)
    }

    @Test("Clipboard restoration never overwrites a newer user copy")
    func guardsClipboardRestoration() {
        #expect(ClipoClipboardRestorePolicy.shouldRestore(expectedChangeCount: 10, currentChangeCount: 10))
        #expect(!ClipoClipboardRestorePolicy.shouldRestore(expectedChangeCount: 10, currentChangeCount: 11))
    }

    @Test("Clipo panel shortcut does not conflict with the main panel shortcut")
    func usesDedicatedPanelShortcut() {
        let optionOnly = UInt32(NSEvent.ModifierFlags.option.rawValue)
        #expect(ClipoShortcutDefaults.openKeyCode == 49)
        #expect(ClipoShortcutDefaults.openModifiers != optionOnly)
        #expect(ClipoShortcutDefaults.openModifiers == UInt32(NSEvent.ModifierFlags.command.union(.option).rawValue))
    }

    @Test("Clipo keeps the last external app as the source while its panel is frontmost")
    func resolvesClipboardSourceWithoutBypassingSensitiveApps() {
        let ownBundleID = "com.hanazar.classgod"
        let sensitiveBundleID = "com.1password.1password"

        #expect(ClipoSourcePolicy.effectiveBundleIdentifier(
            frontmost: ownBundleID,
            pasteTarget: sensitiveBundleID,
            ownBundleIdentifier: ownBundleID
        ) == sensitiveBundleID)
        #expect(ClipoSourcePolicy.effectiveBundleIdentifier(
            frontmost: "com.apple.Safari",
            pasteTarget: sensitiveBundleID,
            ownBundleIdentifier: ownBundleID
        ) == "com.apple.Safari")
        #expect(ClipoSourcePolicy.shouldRememberTarget(
            candidateBundleIdentifier: "com.apple.Safari",
            ownBundleIdentifier: ownBundleID
        ))
        #expect(!ClipoSourcePolicy.shouldRememberTarget(
            candidateBundleIdentifier: ownBundleID,
            ownBundleIdentifier: ownBundleID
        ))
    }

    @Test("Clipo enum labels resolve through the string catalog")
    func resolvesLocalizedLabels() {
        #expect(ClipoType.allCases.allSatisfy { !$0.displayName.hasPrefix("clipo.") })
        #expect(ClipoAutoDeletePolicy.allCases.allSatisfy { !$0.displayName.hasPrefix("clipo.") })
    }

    @Test("Clipboard text is classified without treating prose as code")
    func classifiesClipboardContent() {
        #expect(ClipoContentClassifier.type(for: "https://example.com/docs") == .url)
        #expect(ClipoContentClassifier.type(for: "let answer = 42\nprint(answer)") == .code)
        #expect(ClipoContentClassifier.type(for: "Meeting notes for tomorrow") == .text)
    }

    @Test("Duplicate history moves to the front and remains unique")
    func deduplicatesHistory() {
        var settings = ClipoSettings()
        settings.ignoreDuplicates = true
        settings.maxHistoryItems = 10
        let older = ClipoItem(content: "alpha", createdAt: .distantPast, lastUsedAt: .distantPast)
        let newer = ClipoItem(content: "beta")
        let duplicate = ClipoItem(content: "alpha")

        let result = ClipoHistoryPolicy.updatedHistory(
            inserting: duplicate,
            into: [newer, older],
            settings: settings,
            now: Date(timeIntervalSince1970: 100)
        )

        #expect(result.map(\.content) == ["alpha", "beta"])
        #expect(result[0].lastUsedAt == Date(timeIntervalSince1970: 100))
    }

    @Test("Pinned items survive trimming before recent unpinned items")
    func preservesPinnedHistory() {
        var settings = ClipoSettings()
        settings.maxHistoryItems = 2
        let pinned = ClipoItem(content: "pinned", isPinned: true)
        let recent = ClipoItem(content: "recent")
        let incoming = ClipoItem(content: "incoming")

        let result = ClipoHistoryPolicy.updatedHistory(
            inserting: incoming,
            into: [pinned, recent],
            settings: settings,
            now: Date()
        )

        #expect(result.count == 2)
        #expect(result.contains { $0.content == "pinned" })
        #expect(result.contains { $0.content == "incoming" })
    }

    @Test("History trimming enforces a bounded persistence budget")
    func trimsHistoryByStorageBudget() {
        let items = [ClipoItem(content: "1234"), ClipoItem(content: "5678")]
        let result = ClipoHistoryPolicy.trimmed(items, limit: 10, byteLimit: 8)

        #expect(result.count == 1)
    }

    @Test("Search combines query, fuzzy matching, and type filters")
    func filtersHistory() {
        let items = [
            ClipoItem(content: "ClassGod fan control", type: .text),
            ClipoItem(content: "https://github.com/hzagaming/Clipo", type: .url),
            ClipoItem(content: "WidgetKit timeline", type: .code),
        ]

        #expect(ClipoSearch.filtered(items, query: "CGfc", type: nil, caseSensitive: false, fuzzy: true).map(\.content) == ["ClassGod fan control"])
        #expect(ClipoSearch.filtered(items, query: "github", type: .url, caseSensitive: false, fuzzy: false).count == 1)
        #expect(ClipoSearch.filtered(items, query: "widgetkit", type: .code, caseSensitive: true, fuzzy: false).isEmpty)
    }
}
