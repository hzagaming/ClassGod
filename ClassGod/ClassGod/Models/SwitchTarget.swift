//
//  SwitchTarget.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import AppKit

struct SwitchTarget: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var bundleIdentifier: String
    var iconName: String
    var shortcutKey: String
    var shortcutModifiers: UInt
    var createdAt: Date
    
    private var version: Int = 1
    
    init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String,
        iconName: String = "app.fill",
        shortcutKey: String = "",
        shortcutModifiers: UInt = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.iconName = iconName
        self.shortcutKey = shortcutKey
        self.shortcutModifiers = shortcutModifiers
        self.createdAt = createdAt
    }
    
    static func == (lhs: SwitchTarget, rhs: SwitchTarget) -> Bool {
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
}
