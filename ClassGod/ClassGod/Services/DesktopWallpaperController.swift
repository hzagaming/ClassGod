//
//  DesktopWallpaperController.swift
//  ClassGod
//

import SwiftUI
import AppKit
import Combine

/// Manages borderless wallpaper windows at the desktop level (behind Finder icons).
/// Creates one window per connected display. Windows ignore mouse events so
/// users can still click desktop icons and use Finder normally.
@MainActor
final class DesktopWallpaperController {
    static let shared = DesktopWallpaperController()
    
    private var windows: [NSScreen: DesktopWallpaperWindow] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var screenObserver: NSObjectProtocol?
    
    private init() {
        // Listen for screen configuration changes (plug/unplug monitors)
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshWindows()
        }
        
        // React to engine state changes
        let engine = WallpaperEngine.shared
        
        engine.$showOnDesktop
            .receive(on: DispatchQueue.main)
            .sink { [weak self] show in
                if show && engine.isEnabled {
                    self?.showWallpapers()
                } else {
                    self?.hideWallpapers()
                }
            }
            .store(in: &cancellables)
        
        engine.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                if enabled && engine.showOnDesktop {
                    self?.showWallpapers()
                } else {
                    self?.hideWallpapers()
                }
            }
            .store(in: &cancellables)
        
        engine.$currentWallpaper
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard engine.showOnDesktop, engine.isEnabled else { return }
                self?.refreshContent()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Window Management
    
    func showWallpapers() {
        let engine = WallpaperEngine.shared
        guard engine.isEnabled, engine.currentWallpaper != nil else {
            hideWallpapers()
            return
        }
        
        let screens = NSScreen.screens
        let connectedIDs = Set(screens.compactMap { $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber })
        
        // Remove windows for disconnected screens
        let disconnected = windows.keys.filter { screen in
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return true }
            return !connectedIDs.contains(id)
        }
        for screen in disconnected {
            windows[screen]?.orderOut(nil)
            windows.removeValue(forKey: screen)
        }
        
        // Create/update windows for each screen
        for screen in screens {
            if let existing = windows[screen] {
                existing.updateFrame(screen)
                existing.refreshContent()
            } else {
                let window = DesktopWallpaperWindow(screen: screen)
                windows[screen] = window
                window.orderBack(nil)
            }
        }
    }
    
    func hideWallpapers() {
        for (_, window) in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
    }
    
    func refreshWindows() {
        let engine = WallpaperEngine.shared
        if engine.showOnDesktop {
            showWallpapers()
        }
    }
    
    func refreshContent() {
        for (_, window) in windows {
            window.refreshContent()
        }
    }
}

// MARK: - Desktop Wallpaper Window

private final class DesktopWallpaperWindow: NSWindow {
    private var hostingView: NSHostingView<WallpaperPlayerView>?
    
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Desktop-level window — sits at the very bottom of the window stack
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.isReleasedWhenClosed = false
        
        // Critical: mouse events pass through to Finder icons below
        self.ignoresMouseEvents = true
        
        // No animations on show/hide
        self.animationBehavior = .none
        
        setupContent()
    }
    
    func updateFrame(_ screen: NSScreen) {
        setFrame(screen.frame, display: true)
    }
    
    func setupContent() {
        guard let wallpaper = WallpaperEngine.shared.currentWallpaper else { return }
        
        let playerView = WallpaperPlayerView(wallpaper: wallpaper)
        let hostingView = NSHostingView(rootView: playerView)
        hostingView.frame = contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        
        contentView = hostingView
        self.hostingView = hostingView
    }
    
    func refreshContent() {
        // Remove old hosting view
        hostingView?.removeFromSuperview()
        hostingView = nil
        
        guard let wallpaper = WallpaperEngine.shared.currentWallpaper else {
            contentView = nil
            return
        }
        
        let playerView = WallpaperPlayerView(wallpaper: wallpaper)
        let hostingView = NSHostingView(rootView: playerView)
        hostingView.frame = contentView?.bounds ?? frame
        hostingView.autoresizingMask = [.width, .height]
        
        contentView = hostingView
        self.hostingView = hostingView
    }
}
