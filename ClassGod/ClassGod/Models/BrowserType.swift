//
//  BrowserType.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import AppKit

enum BrowserType: String, Codable, CaseIterable, Identifiable {
    case safari = "safari"
    case chrome = "chrome"
    case edge = "edge"
    
    var id: String { rawValue }
    
    var bundleIdentifier: String {
        switch self {
        case .safari:
            return "com.apple.Safari"
        case .chrome:
            return "com.google.Chrome"
        case .edge:
            return "com.microsoft.edgemac"
        }
    }
    
    var displayName: String {
        switch self {
        case .safari:
            return "Safari"
        case .chrome:
            return "Chrome"
        case .edge:
            return "Edge"
        }
    }
    
    var sfSymbolName: String {
        switch self {
        case .safari:
            return "safari"
        case .chrome:
            return "globe"
        case .edge:
            return "wave.3.forward"
        }
    }
    
    var isInstalled: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) != nil
    }
}
