//
//  BrowserTab.swift
//  ClassGod
//

import Foundation
import AppKit

nonisolated struct BrowserTabDraft: Equatable {
    let title: String
    let url: String
    let tag: String

    init(title: String, url: String, tag: String) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate: String
        if trimmedURL.range(of: "://") != nil {
            candidate = trimmedURL
        } else {
            candidate = trimmedURL.isEmpty ? "" : "https://\(trimmedURL)"
        }
        self.url = URLComponents(string: candidate)?.url?.absoluteString ?? candidate
    }

    var canSave: Bool {
        guard !title.isEmpty,
              let components = URLComponents(string: url),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              components.host?.isEmpty == false else { return false }
        return true
    }
}

struct BrowserTab: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var url: String
    var browser: BrowserType
    var shortcutKey: String
    var shortcutModifiers: UInt
    var createdAt: Date
    
    // MARK: - New Fields (v2)
    var isPinned: Bool
    var tag: String
    var lastAccessedAt: Date
    
    // MARK: - Codable Migration
    
    private enum CodingKeys: String, CodingKey {
        case id, title, url, browser, shortcutKey, shortcutModifiers, createdAt
        case isPinned, tag, lastAccessedAt
        case version
    }
    
    private var version: Int = 2
    
    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        browser: BrowserType,
        shortcutKey: String = "",
        shortcutModifiers: UInt = 0,
        createdAt: Date = Date(),
        isPinned: Bool = false,
        tag: String = "",
        lastAccessedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.browser = browser
        self.shortcutKey = shortcutKey
        self.shortcutModifiers = shortcutModifiers
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.tag = tag
        self.lastAccessedAt = lastAccessedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.url = try container.decode(String.self, forKey: .url)
        self.browser = try container.decode(BrowserType.self, forKey: .browser)
        self.shortcutKey = try container.decodeIfPresent(String.self, forKey: .shortcutKey) ?? ""
        self.shortcutModifiers = try container.decodeIfPresent(UInt.self, forKey: .shortcutModifiers) ?? 0
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        self.tag = try container.decodeIfPresent(String.self, forKey: .tag) ?? ""
        self.lastAccessedAt = try container.decodeIfPresent(Date.self, forKey: .lastAccessedAt) ?? Date()
        self.version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 2
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(url, forKey: .url)
        try container.encode(browser, forKey: .browser)
        try container.encode(shortcutKey, forKey: .shortcutKey)
        try container.encode(shortcutModifiers, forKey: .shortcutModifiers)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(tag, forKey: .tag)
        try container.encode(lastAccessedAt, forKey: .lastAccessedAt)
        try container.encode(version, forKey: .version)
    }
    
    static func == (lhs: BrowserTab, rhs: BrowserTab) -> Bool {
        lhs.id == rhs.id
    }
    
    var shortcutDisplayString: String {
        var parts: [String] = []
        let flags = NSEvent.ModifierFlags(rawValue: shortcutModifiers)
        if flags.contains(.command) { parts.append("⌘") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.shift) { parts.append("⇧") }
        if !shortcutKey.isEmpty {
            parts.append(shortcutKey.uppercased())
        }
        return parts.joined(separator: "")
    }
    
    var isValidShortcut: Bool {
        !shortcutKey.isEmpty && (shortcutModifiers != 0 || shortcutKey.uppercased().hasPrefix("F"))
    }
    
    var lastAccessedDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastAccessedAt, relativeTo: Date())
    }
    
    var displayTag: String {
        tag.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var hasTag: Bool {
        !displayTag.isEmpty
    }
}
