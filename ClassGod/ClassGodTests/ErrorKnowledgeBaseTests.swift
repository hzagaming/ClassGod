import Combine
import Foundation
import Testing
@testable import ClassGod

@Suite("Error knowledge base loading")
@MainActor
struct ErrorKnowledgeBaseTests {
    @Test("The first search waits for the resource and its indexes")
    func awaitsFirstSearch() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("errors.json")
        let entry = sampleEntry()
        try JSONEncoder().encode([entry]).write(to: url)
        let base = ErrorKnowledgeBase(resourceURL: url)

        let results = await base.search(query: "offline")

        #expect(results.map(\.entry.id) == [entry.id])
        #expect(results.first?.relevanceScore == 55)
        #expect(results.first?.matchedField == "Title")
        #expect(base.entry(withID: entry.id) == entry)
        #expect(!base.isLoading)
        await base.ensureLoadedAndWait()
    }

    @Test("Explicit retry recovers after a resource read failure")
    func retriesFailedLoad() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("errors.json")
        let base = ErrorKnowledgeBase(resourceURL: url)
        await base.ensureLoadedAndWait()
        #expect(base.loadingError != nil)
        #expect(!base.isLoading)

        let entry = sampleEntry()
        try JSONEncoder().encode([entry]).write(to: url)
        await base.ensureLoadedAndWait()
        #expect(base.loadingError != nil)
        #expect(base.allEntries.isEmpty)
        base.retryLoading()
        await base.ensureLoadedAndWait()

        #expect(base.loadingError == nil)
        #expect(base.allEntries == [entry])
        #expect(!base.isLoading)
    }

    @Test("A successfully loaded empty resource is not read again")
    func retainsEmptyLoad() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("errors.json")
        try JSONEncoder().encode([ErrorEntry]()).write(to: url)
        let base = ErrorKnowledgeBase(resourceURL: url)
        await base.ensureLoadedAndWait()
        #expect(base.loadingError == nil)
        try FileManager.default.removeItem(at: url)

        await base.ensureLoadedAndWait()

        #expect(base.loadingError == nil)
        #expect(base.allEntries.isEmpty)
        #expect(!base.isLoading)
    }

    @Test("Entry publication exposes completed lookup indexes")
    func publishesReadyIndexes() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("errors.json")
        let entry = sampleEntry()
        try JSONEncoder().encode([entry]).write(to: url)
        let base = ErrorKnowledgeBase(resourceURL: url)
        var publishedID: UUID?
        let subscription = base.$allEntries.dropFirst().sink { entries in
            publishedID = entries.first.flatMap { base.entry(withID: $0.id)?.id }
        }
        defer { subscription.cancel() }

        await base.ensureLoadedAndWait()

        #expect(publishedID == entry.id)
    }

    @Test("Cancelled searches do not return matches")
    func cancelsSearch() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("errors.json")
        try JSONEncoder().encode([sampleEntry()]).write(to: url)
        let base = ErrorKnowledgeBase(resourceURL: url)
        await base.ensureLoadedAndWait()
        let search = Task { await base.search(query: "offline") }
        search.cancel()

        #expect(await search.value.isEmpty)
        #expect(await base.search(query: "offline").count == 1)
    }

    @Test("Searching a category with no entries does not include other categories")
    func respectsEmptyCategory() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("errors.json")
        try JSONEncoder().encode([sampleEntry()]).write(to: url)
        let base = ErrorKnowledgeBase(resourceURL: url)
        await base.ensureLoadedAndWait()

        #expect(await base.search(query: "offline", category: .swiftUI).isEmpty)
        #expect(await base.search(query: "offline", category: .network).count == 1)
    }

    @Test("Concurrent first searches share one resource load")
    func sharesInitialLoad() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("errors.json")
        let entry = sampleEntry()
        try JSONEncoder().encode([entry]).write(to: url)
        let base = ErrorKnowledgeBase(resourceURL: url)
        var loadCount = 0
        let subscription = base.$isLoading.sink { if $0 { loadCount += 1 } }
        defer { subscription.cancel() }

        async let first = base.search(query: "offline")
        async let second = base.search(query: "-1009")
        let results = await (first, second)

        #expect(results.0.map(\.entry.id) == [entry.id])
        #expect(results.1.map(\.entry.id) == [entry.id])
        #expect(results.1.first?.relevanceScore == 105)
        #expect(results.1.first?.matchedField == "Error Code")
        #expect(loadCount == 1)
        await base.ensureLoadedAndWait()
    }

    @Test("Cancelling one waiting search leaves the shared load available to other searches")
    func cancellationKeepsSharedLoad() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("errors.json")
        let entry = sampleEntry()
        try JSONEncoder().encode([entry]).write(to: url)
        let base = ErrorKnowledgeBase(resourceURL: url)
        var cancelledSearch: Task<[ErrorSearchResult], Never>?
        var loadCount = 0
        let subscription = base.$isLoading.sink { loading in
            if loading {
                loadCount += 1
                cancelledSearch?.cancel()
            }
        }
        defer { subscription.cancel() }
        let first = Task { await base.search(query: "offline") }
        cancelledSearch = first
        let second = Task { await base.search(query: "-1009") }

        #expect(await first.value.isEmpty)
        #expect(await second.value.map(\.entry.id) == [entry.id])
        #expect(loadCount == 1)
        #expect(base.allEntries == [entry])
        #expect(!base.isLoading)
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("ErrorKnowledgeBase-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func sampleEntry() -> ErrorEntry {
        ErrorEntry(category: .network, severity: .high, title: "Offline", errorCode: "-1009",
                   description: "No connection", cause: "Network unavailable", solutions: [])
    }
}
