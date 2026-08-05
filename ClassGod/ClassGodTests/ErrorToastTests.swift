import Foundation
import AppKit
import Testing
@testable import ClassGod

@Suite("Error toast updates")
struct ErrorToastTests {
    @Test("Knowledge-base callers can await the initial resource load")
    func awaitsKnowledgeBaseLoading() async {
        await ErrorKnowledgeBase.shared.ensureLoadedAndWait()

        #expect(!ErrorKnowledgeBase.shared.isLoading)
        #expect(ErrorKnowledgeBase.shared.loadingError == nil)
        #expect(!ErrorKnowledgeBase.shared.allEntries.isEmpty)
    }

    @Test("Knowledge-base enrichment preserves toast identity")
    func preservesIdentity() {
        let toast = ErrorToastItem(
            title: "Title",
            message: "Message",
            severity: .high,
            entry: nil,
            timestamp: Date()
        )

        let entry = ErrorEntry(
            category: .general,
            severity: .high,
            title: "Reference",
            description: "Description",
            cause: "Cause",
            solutions: []
        )
        let enriched = toast.enriched(with: entry)

        #expect(enriched.id == toast.id)
        #expect(enriched.entry?.id == entry.id)
    }

    @Test("Toast positions are compact and never overlap")
    func laysOutToastStack() {
        let frame = NSRect(x: 0, y: 0, width: 1_000, height: 800)
        let size = NSSize(width: 380, height: 120)

        let first = ErrorToastLayoutPolicy.origin(index: 0, visibleFrame: frame, size: size)
        let second = ErrorToastLayoutPolicy.origin(index: 1, visibleFrame: frame, size: size)

        #expect(first == NSPoint(x: 600, y: 660))
        #expect(second == NSPoint(x: 600, y: 530))
    }

    @Test("Automatic dismissal can be cancelled")
    func cancelsAutomaticDismissal() {
        let scheduler = ErrorToastDismissalScheduler()
        let first = UUID()
        let second = UUID()

        scheduler.schedule(id: first, after: 60) {}
        scheduler.schedule(id: second, after: 60) {}
        #expect(scheduler.pendingIDs == [first, second])

        scheduler.cancel(id: first)
        #expect(scheduler.pendingIDs == [second])

        scheduler.cancelAll()
        #expect(scheduler.pendingIDs.isEmpty)
    }
}
