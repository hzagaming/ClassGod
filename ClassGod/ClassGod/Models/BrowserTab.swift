//
//  BrowserTab.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import AppKit

struct BrowserTab: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var url: String
    var browser: BrowserType
    var shortcutKey: String
    var shortcutModifiers: UInt
    var createdAt: Date
    
    // Version for Codable migration
    private var version: Int = 1
    
    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        browser: BrowserType,
        shortcutKey: String = "",
        shortcutModifiers: UInt = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.browser = browser
        self.shortcutKey = shortcutKey
        self.shortcutModifiers = shortcutModifiers
        self.createdAt = createdAt
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
        !shortcutKey.isEmpty && shortcutModifiers != 0
    }
}
