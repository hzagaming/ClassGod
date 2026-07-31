import Foundation
import Testing
@testable import ClassGod

@Suite("Regression policies")
struct RegressionPolicyTests {
    @Test("Pinned tabs preserve their relative order")
    func preservesRelativeOrderWhenGroupingPinnedTabs() {
        let first = BrowserTab(title: "First", url: "https://first.example", browser: .safari)
        let second = BrowserTab(title: "Second", url: "https://second.example", browser: .chrome, isPinned: true)
        let third = BrowserTab(title: "Third", url: "https://third.example", browser: .edge)
        let fourth = BrowserTab(title: "Fourth", url: "https://fourth.example", browser: .safari, isPinned: true)

        let ordered = TabOrderingPolicy.pinnedFirstPreservingOrder([first, second, third, fourth])

        #expect(ordered.map(\.id) == [second.id, fourth.id, first.id, third.id])
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
