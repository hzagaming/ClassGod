//
//  AppIconStyle.swift
//  ClassGod
//

import Foundation
import AppKit

enum AppIconStyle: String, Codable, CaseIterable, Identifiable {
    case `default` = "default"
    case safari = "safari"
    case finder = "finder"
    case terminal = "terminal"
    case notes = "notes"
    case calculator = "calculator"
    case hidden = "hidden"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .default: return "ClassGod"
        case .safari: return "Safari"
        case .finder: return "Finder"
        case .terminal: return "Terminal"
        case .notes: return "Notes"
        case .calculator: return "Calculator"
        case .hidden: return "Hidden (No Icon)"
        }
    }
    
    var iconName: String {
        switch self {
        case .default: return "bolt.fill"
        case .safari: return "safari.fill"
        case .finder: return "face.smiling.fill"
        case .terminal: return "terminal.fill"
        case .notes: return "note.text"
        case .calculator: return "function"
        case .hidden: return "eye.slash.fill"
        }
    }
    
    var systemAppPath: String? {
        switch self {
        case .safari: return "/System/Applications/Safari.app"
        case .finder: return "/System/Library/CoreServices/Finder.app"
        case .terminal: return "/System/Applications/Utilities/Terminal.app"
        case .notes: return "/System/Applications/Notes.app"
        case .calculator: return "/System/Applications/Calculator.app"
        default: return nil
        }
    }
}
