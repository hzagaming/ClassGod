//
//  ErrorKnowledgeBase.swift
//  ClassGod
//
//  Optimized macOS/Swift/SwiftUI Error Database
//  Loaded asynchronously from bundled JSON with inverted-index search.
//

import Foundation
import Combine

final class ErrorKnowledgeBase: ObservableObject {
    static let shared = ErrorKnowledgeBase()
    
    @Published private(set) var isLoading = false
    @Published private(set) var loadingError: String?
    @Published private(set) var allEntries: [ErrorEntry] = []
    
    private var entriesByID: [UUID: ErrorEntry] = [:]
    private var entriesByCategory: [ErrorCategory: [ErrorEntry]] = [:]
    private var entriesByTitle: [String: ErrorEntry] = [:]
    private var categoryCounts: [ErrorCategory: Int] = [:]
    private var invertedIndex: [String: Set<UUID>] = [:]
    private var loadTask: Task<Void, Never>?
    
    private init() {}
    
    // MARK: - Loading
    
    func ensureLoaded() {
        guard allEntries.isEmpty, loadingError == nil, loadTask == nil else { return }
        isLoading = true
        loadTask = Task { [weak self] in
            await self?.loadInBackground()
        }
    }
    
    @MainActor
    private func loadInBackground() async {
        let result: Result<[ErrorEntry], Error> = await Task.detached(priority: .userInitiated) {
            do {
                guard let url = Bundle.main.url(forResource: "ErrorKnowledgeBase", withExtension: "json") else {
                    throw NSError(
                        domain: "ErrorKnowledgeBase",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "ErrorKnowledgeBase.json not found in bundle"]
                    )
                }
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let entries = try decoder.decode([ErrorEntry].self, from: data)
                return .success(entries)
            } catch {
                return .failure(error)
            }
        }.value
        
        switch result {
        case .success(let entries):
            self.allEntries = entries
            buildIndexes(entries: entries)
            self.isLoading = false
        case .failure(let error):
            self.loadingError = error.localizedDescription
            self.isLoading = false
        }
        self.loadTask = nil
    }
    
    private func buildIndexes(entries: [ErrorEntry]) {
        var byID: [UUID: ErrorEntry] = [:]
        var byCategory: [ErrorCategory: [ErrorEntry]] = [:]
        var byTitle: [String: ErrorEntry] = [:]
        var counts: [ErrorCategory: Int] = [:]
        var index: [String: Set<UUID>] = [:]
        
        for entry in entries {
            byID[entry.id] = entry
            byCategory[entry.category, default: []].append(entry)
            byTitle[entry.title] = entry
            counts[entry.category, default: 0] += 1
            
            for token in tokens(for: entry) {
                index[token, default: []].insert(entry.id)
            }
        }
        
        entriesByID = byID
        entriesByCategory = byCategory
        entriesByTitle = byTitle
        categoryCounts = counts
        invertedIndex = index
    }
    
    private func tokens(for entry: ErrorEntry) -> [String] {
        var source = ""
        source.append(entry.title)
        source.append(" ")
        source.append(entry.description)
        source.append(" ")
        source.append(entry.cause)
        source.append(" ")
        source.append(entry.errorCode ?? "")
        source.append(" ")
        source.append(entry.tags.joined(separator: " "))
        source.append(" ")
        source.append(entry.relatedErrors.joined(separator: " "))
        
        return source
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 1 }
    }
    
    // MARK: - Lookups
    
    func entry(withID id: UUID) -> ErrorEntry? {
        entriesByID[id]
    }
    
    func entries(for category: ErrorCategory) -> [ErrorEntry] {
        ensureLoaded()
        guard category != .all else { return allEntries }
        return entriesByCategory[category] ?? []
    }
    
    func entriesBySeverity(_ severity: ErrorSeverity) -> [ErrorEntry] {
        ensureLoaded()
        return allEntries.filter { $0.severity == severity }
    }
    
    func findRelated(to entry: ErrorEntry) -> [ErrorEntry] {
        ensureLoaded()
        var results: [ErrorEntry] = []
        for title in entry.relatedErrors {
            if let related = entriesByTitle[title] {
                results.append(related)
            }
        }
        for candidate in allEntries where candidate.relatedErrors.contains(entry.title) {
            if candidate.id != entry.id {
                results.append(candidate)
            }
        }
        return Array(Set(results)).sorted { $0.title < $1.title }
    }
    
    // MARK: - Search
    
    func search(query: String, category: ErrorCategory? = nil) -> [ErrorSearchResult] {
        ensureLoaded()
        let lowerQuery = query.lowercased()
        let queryTokens = lowerQuery
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        
        let pool: [ErrorEntry]
        if let cat = category, cat != .all, let catEntries = entriesByCategory[cat] {
            pool = catEntries
        } else {
            pool = allEntries
        }
        
        var scores: [UUID: Double] = [:]
        var matchedFields: [UUID: String] = [:]
        
        // Boost entries whose tokens intersect the query tokens via the inverted index.
        var indexBoost: [UUID: Double] = [:]
        for token in queryTokens {
            if let ids = invertedIndex[token] {
                for id in ids {
                    indexBoost[id, default: 0] += 5
                }
            }
        }
        
        for entry in pool {
            var score: Double = indexBoost[entry.id, default: 0]
            
            if let code = entry.errorCode, code.lowercased().contains(lowerQuery) {
                score += 100
                matchedFields[entry.id] = "Error Code"
            }
            
            let titleLower = entry.title.lowercased()
            if titleLower.contains(lowerQuery) {
                score += 50
                matchedFields[entry.id] = matchedFields[entry.id] ?? "Title"
            } else {
                for token in queryTokens where titleLower.contains(token) {
                    score += 8
                }
            }
            
            if entry.description.lowercased().contains(lowerQuery) {
                score += 30
                matchedFields[entry.id] = matchedFields[entry.id] ?? "Description"
            }
            if entry.cause.lowercased().contains(lowerQuery) {
                score += 20
                matchedFields[entry.id] = matchedFields[entry.id] ?? "Cause"
            }
            for tag in entry.tags where tag.lowercased().contains(lowerQuery) {
                score += 15
                matchedFields[entry.id] = matchedFields[entry.id] ?? "Tag"
            }
            if entry.relatedErrors.contains(where: { $0.lowercased().contains(lowerQuery) }) {
                score += 10
            }
            
            if score > 0 {
                scores[entry.id, default: 0] += score
            }
        }
        
        var results: [ErrorSearchResult] = []
        for (id, score) in scores {
            guard let entry = entriesByID[id] else { continue }
            results.append(ErrorSearchResult(
                entry: entry,
                relevanceScore: score,
                matchedField: matchedFields[id] ?? ""
            ))
        }
        
        return results.sorted { $0.relevanceScore > $1.relevanceScore }
    }
}
