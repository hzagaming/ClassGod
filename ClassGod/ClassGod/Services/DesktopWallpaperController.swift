//
//  DesktopWallpaperController.swift
//  ClassGod
//

import SwiftUI
import AppKit

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

    nonisolated static func shouldRefreshContent(
        previousCoordinatesPlayback: Bool,
        currentCoordinatesPlayback: Bool
    ) -> Bool {
        previousCoordinatesPlayback != currentCoordinatesPlayback
    }
}

nonisolated struct WallpaperPresentationState: Equatable {
    let isEnabled: Bool
    let showOnDesktop: Bool
    let wallpaperID: UUID?

    var isVisible: Bool {
        isEnabled && showOnDesktop && wallpaperID != nil
    }
}

nonisolated enum WallpaperPresentationAction: Equatable {
    case none
    case show
    case hide
    case refreshContent
}

nonisolated enum WallpaperPresentationPolicy {
    static func action(
        previous: WallpaperPresentationState,
        current: WallpaperPresentationState
    ) -> WallpaperPresentationAction {
        if previous.isVisible != current.isVisible {
            return current.isVisible ? .show : .hide
        }
        guard current.isVisible, previous.wallpaperID != current.wallpaperID else { return .none }
        return .refreshContent
    }
}

/// Manages borderless wallpaper windows at the desktop level (behind Finder icons).
/// Creates one window per connected display. Windows ignore mouse events so
/// users can still click desktop icons and use Finder normally.
@MainActor
final class DesktopWallpaperController {
    static let shared = DesktopWallpaperController()
    
    private var windows: [UInt32: DesktopWallpaperWindow] = [:]
    private var screenObserver: NSObjectProtocol?
    private var stateObserver: NSObjectProtocol?
    private var presentationState = WallpaperPresentationState(
        isEnabled: false,
        showOnDesktop: false,
        wallpaperID: nil
    )
    
    deinit {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = stateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
        
        stateObserver = NotificationCenter.default.addObserver(
            forName: .wallpaperStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reconcilePresentation()
            }
        }
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
        let current = currentPresentationState()
        presentationState = current
        if current.isVisible {
            showWallpapers()
        } else {
            hideWallpapers()
        }
    }
    
    func refreshContent() {
        for (_, window) in windows {
            window.refreshContent()
        }
    }

    private func reconcilePresentation() {
        let current = currentPresentationState()
        let action = WallpaperPresentationPolicy.action(
            previous: presentationState,
            current: current
        )
        presentationState = current

        switch action {
        case .none:
            break
        case .show:
            showWallpapers()
        case .hide:
            hideWallpapers()
        case .refreshContent:
            refreshContent()
        }
    }

    private func currentPresentationState() -> WallpaperPresentationState {
        let engine = WallpaperEngine.shared
        return WallpaperPresentationState(
            isEnabled: engine.isEnabled,
            showOnDesktop: engine.showOnDesktop,
            wallpaperID: engine.currentWallpaper?.id
        )
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
            guard WallpaperDisplayPolicy.shouldRefreshContent(
                previousCoordinatesPlayback: self.coordinatesPlayback,
                currentCoordinatesPlayback: coordinatesPlayback
            ) else { return }
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
