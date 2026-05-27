//
//  AppIconManager.swift
//  ClassGod
//

import AppKit

final class AppIconManager {
    static let shared = AppIconManager()
    
    private var originalIcon: NSImage?
    private let bundlePath: String
    
    private init() {
        bundlePath = Bundle.main.bundlePath
        originalIcon = NSApp.applicationIconImage
    }
    
    func applyStyle(_ style: AppIconStyle) {
        switch style {
        case .default:
            restoreOriginalIcon()
        case .hidden:
            setHiddenIcon()
        case .safari, .finder, .terminal, .notes, .calculator:
            applySystemAppIcon(style)
        }
    }
    
    private func restoreOriginalIcon() {
        NSApp.applicationIconImage = originalIcon
        // Clear Finder custom icon
        NSWorkspace.shared.setIcon(nil, forFile: bundlePath, options: [])
    }
    
    private func setHiddenIcon() {
        // Create a transparent 1x1 image
        let size = NSSize(width: 1, height: 1)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        NSApp.applicationIconImage = image
    }
    
    private func applySystemAppIcon(_ style: AppIconStyle) {
        guard let appPath = style.systemAppPath else { return }
        
        // Get icon from system app bundle
        let icon = NSWorkspace.shared.icon(forFile: appPath)
        NSApp.applicationIconImage = icon
        
        // Also try to set Finder icon
        NSWorkspace.shared.setIcon(icon, forFile: bundlePath, options: [])
    }
    
    func refreshIcon() {
        let style = PreferencesManager.shared.preferences.appIconStyle
        applyStyle(style)
    }
}
