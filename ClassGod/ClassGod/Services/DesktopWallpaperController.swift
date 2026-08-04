//
//  DesktopWallpaperController.swift
//  ClassGod
//

import SwiftUI
import AppKit
import Combine

enum WallpaperDisplayPolicy {
    static func identifier(for screen: NSScreen) -> UInt32? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    nonisolated static func disconnectedIDs(
        existing: Set<UInt32>,
        connected: Set<UInt32>
    ) -> Set<UInt32> {
        existing.subtracting(connected)
    }
}

/// Manages borderless wallpaper windows at the desktop level (behind Finder icons).
/// Creates one window per connected display. Windows ignore mouse events so
/// users can still click desktop icons and use Finder normally.
@MainActor
final class DesktopWallpaperController {
    static let shared = DesktopWallpaperController()
    
    private var windows: [UInt32: DesktopWallpaperWindow] = [:]
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
        
        let screens = NSScreen.screens.compactMap { screen in
            WallpaperDisplayPolicy.identifier(for: screen).map { ($0, screen) }
        }
        let connectedIDs = Set(screens.map { $0.0 })
        
        // Remove windows for disconnected screens
        let disconnectedIDs = WallpaperDisplayPolicy.disconnectedIDs(
            existing: Set(windows.keys),
            connected: connectedIDs
        )
        for displayID in disconnectedIDs {
            windows[displayID]?.orderOut(nil)
            windows.removeValue(forKey: displayID)
        }
        
        // Create/update windows for each screen
        let primaryDisplayID = screens.first?.0
        for (displayID, screen) in screens {
            let coordinatesPlayback = displayID == primaryDisplayID
            if let existing = windows[displayID] {
                existing.updateFrame(screen)
                existing.refreshContent(coordinatesPlayback: coordinatesPlayback)
            } else {
                let window = DesktopWallpaperWindow(
                    screen: screen,
                    coordinatesPlayback: coordinatesPlayback
                )
                windows[displayID] = window
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
    private var coordinatesPlayback: Bool
    
    init(screen: NSScreen, coordinatesPlayback: Bool) {
        self.coordinatesPlayback = coordinatesPlayback
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
        
        let playerView = WallpaperPlayerView(
            wallpaper: wallpaper,
            coordinatesPlayback: coordinatesPlayback
        )
        let hostingView = NSHostingView(rootView: playerView)
        hostingView.frame = contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        
        contentView = hostingView
        self.hostingView = hostingView
    }
    
    func refreshContent(coordinatesPlayback: Bool? = nil) {
        if let coordinatesPlayback {
            self.coordinatesPlayback = coordinatesPlayback
        }
        // Remove old hosting view
        hostingView?.removeFromSuperview()
        hostingView = nil
        
        guard let wallpaper = WallpaperEngine.shared.currentWallpaper else {
            contentView = nil
            return
        }
        
        let playerView = WallpaperPlayerView(
            wallpaper: wallpaper,
            coordinatesPlayback: self.coordinatesPlayback
        )
        let hostingView = NSHostingView(rootView: playerView)
        hostingView.frame = contentView?.bounds ?? frame
        hostingView.autoresizingMask = [.width, .height]
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        
        contentView = hostingView
        self.hostingView = hostingView
    }
}
