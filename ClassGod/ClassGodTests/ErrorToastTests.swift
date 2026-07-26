import Foundation
import Testing
@testable import ClassGod

@Suite("Error toast updates")
struct ErrorToastTests {
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
}
