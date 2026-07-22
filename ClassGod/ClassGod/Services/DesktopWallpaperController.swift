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
    
    deinit {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        cancellables.removeAll()
    }
    
    private init() {
        // Listen for screen configuration changes (plug/unplug monitors)
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshWindows()
            }
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
        guard engine.isEnabled, let wallpaper = engine.currentWallpaper, wallpaper.fileExists else {
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
                window.orderFront(nil)
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
        
        // On macOS Sonoma+, Finder draws the desktop surface and icons in the same
        // window at desktopIconWindow level. To make the wallpaper actually visible
        // we place it one level above Finder; ignoresMouseEvents keeps clicks passing
        // through to the desktop icons below.
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.isReleasedWhenClosed = false
        self.isMovable = false
        self.isMovableByWindowBackground = false
        
        // Appear on all spaces and stay stationary when switching spaces
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
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
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        
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
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        
        contentView = hostingView
        self.hostingView = hostingView
    }
}
