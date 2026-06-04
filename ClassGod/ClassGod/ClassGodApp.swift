//
//  ClassGodApp.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI
import AppKit
import Carbon

@main
struct ClassGodApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 0.001, height: 0.001)
        .commands {
            CommandGroup(replacing: .appSettings) {}
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var mainWindow: NSWindow?
    var destinTabWindow: NSWindow?
    var superSwitchWindow: NSWindow?
    var browserBypasserWindow: NSWindow?
    var assessPrepHackWindow: NSWindow?
    var settingsWindow: NSWindow?
    var wallpaperBrowserWindow: NSWindow?
    var hackerDesktopWindow: NSWindow?
    var errorHubWindow: NSWindow?
    var showPopoverCustomHotKeyID: UInt32?

    var splashWindow: NSWindow?
    private var clickOutsideMonitor: Any?

    private var targetWindowAlpha: CGFloat {
        CGFloat(PreferencesManager.shared.preferences.windowOpacity)
    }

    private var windowLevel: NSWindow.Level {
        PreferencesManager.shared.preferences.keepWindowOnTop ? .floating : .normal
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize desktop wallpaper controller early so it can react to persisted state
        _ = DesktopWallpaperController.shared
        
        showSplashScreen()

        // Phase 1: Splash (2s) -> Phase 2: Chaos Animation -> Phase 3: Main Window
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.closeSplashScreen()
            self.setupStatusItem()
            self.setupShowPopoverShortcut()
            self.setupGlobalHotKeyHandler()

            PreferencesManager.shared.onPreferencesChanged = { [weak self] _ in
                self?.setupShowPopoverShortcut()
                self?.updateStatusItemIcon()
                self?.updateMainWindowSize()
                self?.updateAllWindowLevels()
                self?.updateClickOutsideMonitor()
                self?.updateAllWindowSizes()
            }
            
            // Apply saved icon style immediately
            AppIconManager.shared.refreshIcon()
            self.updateClickOutsideMonitor()

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.tabsDidChange),
                name: .classGodTabsDidChange,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.windowPositionDidChange),
                name: .draggableWindowDidMove,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.showErrorHubFromNotification(_:)),
                name: .classGodShowErrorHubEntry,
                object: nil
            )

            // Phase 2: Setup main menu window first (hidden at bottom layer)
            self.setupMainWindow()
            self.setupDestinTabWindow()
            self.setupSuperSwitchWindow()
            self.setupBrowserBypasserWindow()
            self.setupAssessPrepHackWindow()
            self.setupSettingsWindow()
            self.setupErrorHubWindow()
            if let window = self.mainWindow {
                window.alphaValue = 0
                window.orderBack(nil)
                
                // Phase 3: Chaos glitch animation
                LaunchAnimationManager.shared.startChaosAnimation(mainWindow: window) { [weak self] in
                    // Phase 4: Animation complete
                    if PreferencesManager.shared.preferences.showPopoverOnLaunch {
                        self?.mainWindow?.makeKeyAndOrderFront(nil)
                    }
                }
            }

            // Permission checks are deferred to feature views — no blocking on launch
        }
    }

    // MARK: - Splash Screen

    private func showSplashScreen() {
        let prefs = PreferencesManager.shared.preferences
        let size = NSSize(width: prefs.panelWidth, height: prefs.panelMaxHeight)
        
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .popUpMenu
        window.backgroundColor = .black
        window.contentView = NSHostingView(rootView: SplashScreenView())
        
        // Center on screen, same position as main window
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2
            let y = screenFrame.midY - size.height / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        window.orderFront(nil)
        splashWindow = window
    }

    private func closeSplashScreen() {
        guard let window = splashWindow else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            window.animator().alphaValue = 0
        } completionHandler: {
            window.orderOut(nil)
            self.splashWindow = nil
        }
    }

    // MARK: - Main Window

    private func setupMainWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = NSSize(
            width: prefs.panelWidth * zoom,
            height: min(prefs.panelMaxHeight, CGFloat(prefs.maxTabsInPopover) * CGFloat(prefs.rowHeight) + 120) * zoom
        )

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = windowLevel
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        
        // Apply corner radius to the window itself
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = prefs.panelCornerRadius
        window.contentView?.layer?.masksToBounds = true
        window.alphaValue = targetWindowAlpha

        // Restore saved position or center on screen
        if prefs.rememberWindowPosition,
           let originString = UserDefaults.standard.string(forKey: "com.hanazar.classgod.mainWindowOrigin") {
            let origin = NSPointFromString(originString)
            // Ensure the window is still on a visible screen
            let targetFrame = NSRect(origin: origin, size: size)
            if let screen = NSScreen.screens.first(where: { $0.frame.intersects(targetFrame) }) ?? NSScreen.main {
                let visibleFrame = screen.visibleFrame
                let clampedX = max(visibleFrame.minX, min(origin.x, visibleFrame.maxX - size.width))
                let clampedY = max(visibleFrame.minY, min(origin.y, visibleFrame.maxY - size.height))
                window.setFrameOrigin(NSPoint(x: clampedX, y: clampedY))
            }
        } else if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2
            let y = screenFrame.midY - size.height / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let rootView = MenuBarWindowView(onClose: { [weak self] in
            self?.hideMainWindow()
        }, onOpenDestinTab: { [weak self] in
            self?.showDestinTabWindow()
        }, onOpenSuperSwitch: { [weak self] in
            self?.showSuperSwitchWindow()
        }, onOpenBrowserBypasser: { [weak self] in
            self?.showBrowserBypasserWindow()
        }, onOpenAssessPrepHack: { [weak self] in
            self?.showAssessPrepHackWindow()
        }, onOpenSettings: { [weak self] in
            self?.showSettingsWindow()
        }, onOpenWallpaper: { [weak self] in
            self?.showWallpaperBrowserWindow()
        }, onOpenHackerDesktop: { [weak self] in
            self?.showHackerDesktopWindow()
        }, onOpenErrorHub: { [weak self] in
            self?.showErrorHubWindow()
        })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .overlay(WindowResizeHandles())

        window.contentView = NSHostingView(rootView: rootView)

        mainWindow = window
    }
    
    // MARK: - DestinTab Window
    
    private func setupDestinTabWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = NSSize(
            width: prefs.panelWidth * zoom,
            height: min(prefs.panelMaxHeight, CGFloat(prefs.maxTabsInPopover) * CGFloat(prefs.rowHeight) + 120) * zoom
        )

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .normal
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = prefs.panelCornerRadius
        window.contentView?.layer?.masksToBounds = true

        // Position slightly offset from main window
        if let main = mainWindow {
            let mainFrame = main.frame
            let offset: CGFloat = 20
            window.setFrameOrigin(NSPoint(x: mainFrame.minX + offset, y: mainFrame.minY - offset))
        } else if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2 + 20
            let y = screenFrame.midY - size.height / 2 - 20
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let rootView = DestinTabWindowView(onClose: { [weak self] in
            self?.hideDestinTabWindow()
        })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .overlay(WindowResizeHandles())

        window.contentView = NSHostingView(rootView: rootView)

        destinTabWindow = window
    }
    
    func showDestinTabWindow(animated: Bool = true) {
        guard let window = destinTabWindow else {
            setupDestinTabWindow()
            showDestinTabWindow(animated: animated)
            return
        }
        
        SoundEffectManager.shared.playWindowOpen(feature: "destintab")
        
        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func hideDestinTabWindow() {
        guard let window = destinTabWindow else { return }
        SoundEffectManager.shared.playWindowClose(feature: "destintab")
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.destinTabWindow?.orderOut(nil)
        }
    }
    
    @objc func toggleDestinTabWindow() {
        guard let window = destinTabWindow else {
            setupDestinTabWindow()
            showDestinTabWindow(animated: true)
            return
        }
        
        if window.isVisible && window.alphaValue > 0 {
            hideDestinTabWindow()
        } else {
            showDestinTabWindow(animated: true)
        }
    }
    
    // MARK: - SuperSwitch Window
    
    private func setupSuperSwitchWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = NSSize(
            width: prefs.panelWidth * zoom,
            height: prefs.panelMaxHeight * zoom
        )

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .normal
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = prefs.panelCornerRadius
        window.contentView?.layer?.masksToBounds = true

        if let main = mainWindow {
            let mainFrame = main.frame
            let offset: CGFloat = 20
            window.setFrameOrigin(NSPoint(x: mainFrame.minX - offset, y: mainFrame.minY + offset))
        } else if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2 - 20
            let y = screenFrame.midY - size.height / 2 + 20
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let rootView = SuperSwitchWindowView(onClose: { [weak self] in
            self?.hideSuperSwitchWindow()
        })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .overlay(WindowResizeHandles())

        window.contentView = NSHostingView(rootView: rootView)

        superSwitchWindow = window
    }
    
    func showSuperSwitchWindow(animated: Bool = true) {
        guard let window = superSwitchWindow else {
            setupSuperSwitchWindow()
            showSuperSwitchWindow(animated: animated)
            return
        }
        
        SoundEffectManager.shared.playWindowOpen(feature: "superswitch")
        
        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func hideSuperSwitchWindow() {
        guard let window = superSwitchWindow else { return }
        SoundEffectManager.shared.playWindowClose(feature: "superswitch")
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.superSwitchWindow?.orderOut(nil)
        }
    }
    
    @objc func toggleSuperSwitchWindow() {
        guard let window = superSwitchWindow else {
            setupSuperSwitchWindow()
            showSuperSwitchWindow(animated: true)
            return
        }
        
        if window.isVisible && window.alphaValue > 0 {
            hideSuperSwitchWindow()
        } else {
            showSuperSwitchWindow(animated: true)
        }
    }
    
    // MARK: - BrowserBypasser Window
    
    private func setupBrowserBypasserWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = NSSize(
            width: prefs.panelWidth * zoom,
            height: prefs.panelMaxHeight * zoom
        )

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .normal
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = prefs.panelCornerRadius
        window.contentView?.layer?.masksToBounds = true

        if let main = mainWindow {
            let mainFrame = main.frame
            let offset: CGFloat = 20
            window.setFrameOrigin(NSPoint(x: mainFrame.minX + offset * 2, y: mainFrame.minY - offset * 2))
        } else if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2 + 40
            let y = screenFrame.midY - size.height / 2 - 40
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let rootView = BrowserBypasserWindowView(onClose: { [weak self] in
            self?.hideBrowserBypasserWindow()
        })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .overlay(WindowResizeHandles())

        window.contentView = NSHostingView(rootView: rootView)

        browserBypasserWindow = window
    }
    
    func showBrowserBypasserWindow(animated: Bool = true) {
        guard let window = browserBypasserWindow else {
            setupBrowserBypasserWindow()
            showBrowserBypasserWindow(animated: animated)
            return
        }
        
        SoundEffectManager.shared.playWindowOpen(feature: "browserbypasser")
        
        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func hideBrowserBypasserWindow() {
        guard let window = browserBypasserWindow else { return }
        SoundEffectManager.shared.playWindowClose(feature: "browserbypasser")
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.browserBypasserWindow?.orderOut(nil)
        }
    }
    
    @objc func toggleBrowserBypasserWindow() {
        guard let window = browserBypasserWindow else {
            setupBrowserBypasserWindow()
            showBrowserBypasserWindow(animated: true)
            return
        }
        
        if window.isVisible && window.alphaValue > 0 {
            hideBrowserBypasserWindow()
        } else {
            showBrowserBypasserWindow(animated: true)
        }
    }
    
    // MARK: - AssessPrepHack Window
    
    private func setupAssessPrepHackWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = NSSize(
            width: prefs.panelWidth * zoom,
            height: prefs.panelMaxHeight * zoom
        )

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .normal
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = prefs.panelCornerRadius
        window.contentView?.layer?.masksToBounds = true

        if let main = mainWindow {
            let mainFrame = main.frame
            let offset: CGFloat = 20
            window.setFrameOrigin(NSPoint(x: mainFrame.minX - offset * 2, y: mainFrame.minY - offset * 2))
        } else if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2 - 40
            let y = screenFrame.midY - size.height / 2 - 40
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let rootView = AssessPrepHackWindowView(onClose: { [weak self] in
            self?.hideAssessPrepHackWindow()
        })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .overlay(WindowResizeHandles())

        window.contentView = NSHostingView(rootView: rootView)

        assessPrepHackWindow = window
    }
    
    func showAssessPrepHackWindow(animated: Bool = true) {
        guard let window = assessPrepHackWindow else {
            setupAssessPrepHackWindow()
            showAssessPrepHackWindow(animated: animated)
            return
        }
        
        SoundEffectManager.shared.playWindowOpen(feature: "assessprephack")
        
        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func hideAssessPrepHackWindow() {
        guard let window = assessPrepHackWindow else { return }
        SoundEffectManager.shared.playWindowClose(feature: "assessprephack")
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.assessPrepHackWindow?.orderOut(nil)
        }
    }
    
    @objc func toggleAssessPrepHackWindow() {
        guard let window = assessPrepHackWindow else {
            setupAssessPrepHackWindow()
            showAssessPrepHackWindow(animated: true)
            return
        }
        
        if window.isVisible && window.alphaValue > 0 {
            hideAssessPrepHackWindow()
        } else {
            showAssessPrepHackWindow(animated: true)
        }
    }
    
    // MARK: - Settings Window
    
    private func setupSettingsWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = NSSize(width: 520 * zoom, height: 480 * zoom)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .normal
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 12
        window.contentView?.layer?.masksToBounds = true

        if let main = mainWindow {
            let mainFrame = main.frame
            window.setFrameOrigin(NSPoint(x: mainFrame.midX - size.width / 2, y: mainFrame.midY - size.height / 2))
        } else if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2
            let y = screenFrame.midY - size.height / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let rootView = SettingsWindowView(onClose: { [weak self] in
            self?.hideSettingsWindow()
        })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .overlay(WindowResizeHandles())

        window.contentView = NSHostingView(rootView: rootView)

        settingsWindow = window
    }
    
    func showSettingsWindow(animated: Bool = true) {
        guard let window = settingsWindow else {
            setupSettingsWindow()
            showSettingsWindow(animated: animated)
            return
        }
        
        SoundEffectManager.shared.playWindowOpen()
        
        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func hideSettingsWindow() {
        guard let window = settingsWindow else { return }
        SoundEffectManager.shared.playWindowClose()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.settingsWindow?.orderOut(nil)
        }
    }
    
    @objc func toggleSettingsWindow() {
        guard let window = settingsWindow else {
            setupSettingsWindow()
            showSettingsWindow(animated: true)
            return
        }
        
        if window.isVisible && window.alphaValue > 0 {
            hideSettingsWindow()
        } else {
            showSettingsWindow(animated: true)
        }
    }

    // MARK: - Wallpaper Browser Window

    private func setupWallpaperBrowserWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = NSSize(width: 520 * zoom, height: 480 * zoom)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = windowLevel
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false

        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 12
        window.contentView?.layer?.masksToBounds = true

        if let main = mainWindow {
            let mainFrame = main.frame
            window.setFrameOrigin(NSPoint(x: mainFrame.midX - size.width / 2, y: mainFrame.midY - size.height / 2))
        } else if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2
            let y = screenFrame.midY - size.height / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let rootView = WallpaperBrowserView(onClose: { [weak self] in
            self?.hideWallpaperBrowserWindow()
        })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .overlay(WindowResizeHandles())

        window.contentView = NSHostingView(rootView: rootView)

        wallpaperBrowserWindow = window
    }

    func showWallpaperBrowserWindow(animated: Bool = true) {
        guard let window = wallpaperBrowserWindow else {
            setupWallpaperBrowserWindow()
            showWallpaperBrowserWindow(animated: animated)
            return
        }

        SoundEffectManager.shared.playWindowOpen()

        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hideWallpaperBrowserWindow() {
        guard let window = wallpaperBrowserWindow else { return }
        SoundEffectManager.shared.playWindowClose()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.wallpaperBrowserWindow?.orderOut(nil)
        }
    }

    @objc func toggleWallpaperBrowserWindow() {
        guard let window = wallpaperBrowserWindow else {
            setupWallpaperBrowserWindow()
            showWallpaperBrowserWindow(animated: true)
            return
        }

        if window.isVisible && window.alphaValue > 0 {
            hideWallpaperBrowserWindow()
        } else {
            showWallpaperBrowserWindow(animated: true)
        }
    }

    // MARK: - Hacker Desktop Window

    private func setupHackerDesktopWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let size = NSSize(width: min(900, screenFrame.width - 100) * zoom, height: min(600, screenFrame.height - 100) * zoom)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = windowLevel
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false

        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 12
        window.contentView?.layer?.masksToBounds = true

        let x = screenFrame.midX - size.width / 2
        let y = screenFrame.midY - size.height / 2
        window.setFrameOrigin(NSPoint(x: x, y: y))

        let rootView = HackerDesktopView(onClose: { [weak self] in
            self?.hideHackerDesktopWindow()
        })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .overlay(WindowResizeHandles())

        window.contentView = NSHostingView(rootView: rootView)

        hackerDesktopWindow = window
    }

    func showHackerDesktopWindow(animated: Bool = true) {
        guard let window = hackerDesktopWindow else {
            setupHackerDesktopWindow()
            showHackerDesktopWindow(animated: animated)
            return
        }

        SoundEffectManager.shared.playWindowOpen(feature: "hackerdesktop")

        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hideHackerDesktopWindow() {
        guard let window = hackerDesktopWindow else { return }
        SoundEffectManager.shared.playWindowClose(feature: "hackerdesktop")

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.hackerDesktopWindow?.orderOut(nil)
        }
    }

    @objc func toggleHackerDesktopWindow() {
        guard let window = hackerDesktopWindow else {
            setupHackerDesktopWindow()
            showHackerDesktopWindow(animated: true)
            return
        }

        if window.isVisible && window.alphaValue > 0 {
            hideHackerDesktopWindow()
        } else {
            showHackerDesktopWindow(animated: true)
        }
    }

    // MARK: - Error Hub Window

    private func setupErrorHubWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = NSSize(width: 520 * zoom, height: 600 * zoom)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = windowLevel
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false

        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 12
        window.contentView?.layer?.masksToBounds = true

        if let main = mainWindow {
            let mainFrame = main.frame
            window.setFrameOrigin(NSPoint(x: mainFrame.midX - size.width / 2, y: mainFrame.midY - size.height / 2))
        } else if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2
            let y = screenFrame.midY - size.height / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let rootView = ErrorHubWindowView(onClose: { [weak self] in
            self?.hideErrorHubWindow()
        })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .overlay(WindowResizeHandles())

        window.contentView = NSHostingView(rootView: rootView)

        errorHubWindow = window
    }

    func showErrorHubWindow(animated: Bool = true) {
        guard let window = errorHubWindow else {
            setupErrorHubWindow()
            showErrorHubWindow(animated: animated)
            return
        }

        SoundEffectManager.shared.playWindowOpen(feature: "errorhub")

        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hideErrorHubWindow() {
        guard let window = errorHubWindow else { return }
        SoundEffectManager.shared.playWindowClose(feature: "errorhub")

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.errorHubWindow?.orderOut(nil)
        }
    }

    @objc func toggleErrorHubWindow() {
        guard let window = errorHubWindow else {
            setupErrorHubWindow()
            showErrorHubWindow(animated: true)
            return
        }

        if window.isVisible && window.alphaValue > 0 {
            hideErrorHubWindow()
        } else {
            showErrorHubWindow(animated: true)
        }
    }
    
    @objc func showErrorHubFromNotification(_ notification: Notification) {
        showErrorHubWindow(animated: true)
    }

    private func updateMainWindowSize() {
        guard let window = mainWindow else { return }
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let newSize = NSSize(
            width: prefs.panelWidth * zoom,
            height: min(prefs.panelMaxHeight, CGFloat(prefs.maxTabsInPopover) * CGFloat(prefs.rowHeight) + 120) * zoom
        )
        window.setContentSize(newSize)
    }

    func showMainWindow(animated: Bool = false) {
        guard let window = mainWindow else { return }

        // Always center the main window on screen before showing
        centerWindowOnScreen(window)

        SoundEffectManager.shared.playWindowOpen()

        let useAnimation = animated && PreferencesManager.shared.preferences.showPopoverAnimation

        if useAnimation {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.alphaValue = targetWindowAlpha
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func centerWindowOnScreen(_ window: NSWindow) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visibleFrame = screen.visibleFrame
        let size = window.frame.size
        let x = visibleFrame.midX - size.width / 2
        let y = visibleFrame.midY - size.height / 2
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func hideMainWindow() {
        guard let window = mainWindow else { return }
        SoundEffectManager.shared.playWindowClose()

        if PreferencesManager.shared.preferences.showPopoverAnimation {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                context.timingFunction = .init(name: .easeIn)
                window.animator().alphaValue = 0
            } completionHandler: { [weak self] in
                self?.mainWindow?.orderOut(nil)
            }
        } else {
            window.alphaValue = 0
            window.orderOut(nil)
        }
    }

    @objc func toggleMainWindow() {
        guard let window = mainWindow else {
            // If window doesn't exist yet, create and show it
            setupMainWindow()
            showMainWindow(animated: true)
            return
        }

        if window.isVisible && window.alphaValue > 0 {
            hideMainWindow()
        } else {
            showMainWindow(animated: true)
        }
    }

    // MARK: - Window Behavior Helpers

    private func updateAllWindowLevels() {
        let level = windowLevel
        mainWindow?.level = level
        destinTabWindow?.level = level
        superSwitchWindow?.level = level
        browserBypasserWindow?.level = level
        assessPrepHackWindow?.level = level
        settingsWindow?.level = level
    }

    func updateAllWindowSizes() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)

        // mainWindow
        if let w = mainWindow {
            let baseH = min(prefs.panelMaxHeight, CGFloat(prefs.maxTabsInPopover) * CGFloat(prefs.rowHeight) + 120)
            w.setContentSize(NSSize(width: prefs.panelWidth * zoom, height: baseH * zoom))
        }

        // destinTabWindow
        if let w = destinTabWindow {
            let baseH = min(prefs.panelMaxHeight, CGFloat(prefs.maxTabsInPopover) * CGFloat(prefs.rowHeight) + 120)
            w.setContentSize(NSSize(width: prefs.panelWidth * zoom, height: baseH * zoom))
        }

        // superSwitchWindow
        if let w = superSwitchWindow {
            w.setContentSize(NSSize(width: prefs.panelWidth * zoom, height: prefs.panelMaxHeight * zoom))
        }

        // browserBypasserWindow
        if let w = browserBypasserWindow {
            w.setContentSize(NSSize(width: prefs.panelWidth * zoom, height: prefs.panelMaxHeight * zoom))
        }

        // assessPrepHackWindow
        if let w = assessPrepHackWindow {
            w.setContentSize(NSSize(width: prefs.panelWidth * zoom, height: prefs.panelMaxHeight * zoom))
        }

        // settingsWindow
        if let w = settingsWindow {
            let base = NSSize(width: 520, height: 480)
            w.setContentSize(NSSize(width: base.width * zoom, height: base.height * zoom))
        }

        // wallpaperBrowserWindow
        if let w = wallpaperBrowserWindow {
            let base = NSSize(width: 520, height: 480)
            w.setContentSize(NSSize(width: base.width * zoom, height: base.height * zoom))
        }

        // hackerDesktopWindow
        if let w = hackerDesktopWindow, let screen = NSScreen.main {
            let frame = screen.visibleFrame
            let baseW = min(900, frame.width - 100)
            let baseH = min(600, frame.height - 100)
            w.setContentSize(NSSize(width: baseW * zoom, height: baseH * zoom))
        }
    }

    private func updateClickOutsideMonitor() {
        // Remove existing monitor
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }

        guard PreferencesManager.shared.preferences.closeOnClickOutside else { return }

        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.handleClickOutside()
        }
    }

    private func handleClickOutside() {
        guard PreferencesManager.shared.preferences.closeOnClickOutside else { return }

        let mouseLoc = NSEvent.mouseLocation
        let windows: [(NSWindow?, () -> Void)] = [
            (mainWindow, { [weak self] in self?.hideMainWindow() }),
            (destinTabWindow, { [weak self] in self?.hideDestinTabWindow() }),
            (superSwitchWindow, { [weak self] in self?.hideSuperSwitchWindow() }),
            (browserBypasserWindow, { [weak self] in self?.hideBrowserBypasserWindow() }),
            (assessPrepHackWindow, { [weak self] in self?.hideAssessPrepHackWindow() }),
            (settingsWindow, { [weak self] in self?.hideSettingsWindow() }),
        ]

        for (window, hideAction) in windows {
            guard let w = window, w.isVisible, w.alphaValue > 0 else { continue }
            if !NSPointInRect(mouseLoc, w.frame) {
                hideAction()
            }
        }
    }

    // MARK: - Maximize

    private var maximizedWindows: Set<ObjectIdentifier> = []
    private var windowFramesBeforeMaximize: [ObjectIdentifier: NSRect] = [:]

    func toggleMaximize(for window: NSWindow?) {
        guard let window = window else { return }
        let behavior = PreferencesManager.shared.preferences.windowMaximizeBehavior
        guard behavior != .none else { return }

        let id = ObjectIdentifier(window)
        let isMaximized = maximizedWindows.contains(id)

        if isMaximized {
            // Restore
            if let originalFrame = windowFramesBeforeMaximize[id] {
                window.setFrame(originalFrame, display: true, animate: true)
            }
            maximizedWindows.remove(id)
            windowFramesBeforeMaximize.removeValue(forKey: id)
        } else {
            // Maximize
            windowFramesBeforeMaximize[id] = window.frame
            let screenFrame: NSRect
            if behavior == .fullScreenBorderless, let screen = window.screen {
                screenFrame = screen.frame
            } else if let screen = window.screen {
                screenFrame = screen.visibleFrame
            } else {
                screenFrame = NSScreen.main?.visibleFrame ?? window.frame
            }
            window.setFrame(screenFrame, display: true, animate: true)
            maximizedWindows.insert(id)
        }
    }

    // MARK: - Lifecycle

    func applicationWillTerminate(_ notification: Notification) {
        DesktopWallpaperController.shared.hideWallpapers()
        
        if let id = showPopoverCustomHotKeyID {
            ShortcutManager.shared.unregisterCustomHotKey(id: id)
        }
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        ShortcutManager.shared.unregisterAllShortcuts()
        LaunchAnimationManager.shared.cancelAnimation()
        if let window = destinTabWindow {
            window.orderOut(nil)
        }
        if let window = superSwitchWindow {
            window.orderOut(nil)
        }
        if let window = browserBypasserWindow {
            window.orderOut(nil)
        }
        if let window = assessPrepHackWindow {
            window.orderOut(nil)
        }
        if let window = settingsWindow {
            window.orderOut(nil)
        }
        if let window = wallpaperBrowserWindow {
            window.orderOut(nil)
        }
        if let window = hackerDesktopWindow {
            window.orderOut(nil)
        }
        if let window = errorHubWindow {
            window.orderOut(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        toggleMainWindow()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItemIcon()

        if let button = statusItem.button {
            button.action = #selector(toggleMainWindow)
            button.target = self
        }
    }

    @objc private func tabsDidChange() {
        updateStatusItemIcon()
    }
    
    @objc private func windowPositionDidChange(_ notification: Notification) {
        guard PreferencesManager.shared.preferences.rememberWindowPosition,
              let window = notification.object as? NSWindow,
              window == mainWindow,
              let origin = notification.userInfo?["origin"] as? NSPoint else {
            return
        }
        UserDefaults.standard.set(NSStringFromPoint(origin), forKey: "com.hanazar.classgod.mainWindowOrigin")
    }

    private func updateStatusItemIcon() {
        let style = PreferencesManager.shared.preferences.menuBarIconStyle
        let showBadge = PreferencesManager.shared.preferences.showTabCountBadge
        let count = StorageManager.shared.loadTabs().count

        let baseImage = NSImage(
            systemSymbolName: style.systemImageName,
            accessibilityDescription: "ClassGod"
        ) ?? NSImage(size: NSSize(width: 18, height: 18))
        baseImage.isTemplate = true

        let badgeText = count > 99 ? "99+" : "\(count)"
        statusItem?.button?.image = baseImage
        statusItem?.button?.imagePosition = .imageLeading
        statusItem?.button?.title = showBadge && count > 0 ? " \(badgeText)" : ""
        statusItem?.button?.toolTip = "ClassGod"
    }

    // MARK: - Global Shortcut

    private func setupShowPopoverShortcut() {
        // Unregister previous custom hotkey if any
        if let id = showPopoverCustomHotKeyID {
            ShortcutManager.shared.unregisterCustomHotKey(id: id)
            showPopoverCustomHotKeyID = nil
        }

        let prefs = PreferencesManager.shared.preferences
        let keyCode = prefs.showPopoverKeyCode
        let modifiers = prefs.showPopoverModifiers

        guard keyCode != 0 || modifiers != 0 else { return }

        showPopoverCustomHotKeyID = ShortcutManager.shared.registerCustomHotKey(
            keyCode: keyCode,
            cocoaModifiers: modifiers
        ) { [weak self] in
            self?.toggleMainWindow()
        }
    }
    
    // MARK: - Unified HotKey Handler
    
    private func setupGlobalHotKeyHandler() {
        ShortcutManager.shared.addHotKeyHandler { id in
            // Try BrowserTab first
            let tabs = StorageManager.shared.loadTabs()
            if let tab = tabs.first(where: { $0.id == id }) {
                BrowserSwitcher.shared.switchToTab(tab) { _, _ in }
                return
            }
            
            // Try SwitchTarget
            let targets = StorageManager.shared.loadSwitchTargets()
            if let target = targets.first(where: { $0.id == id }) {
                let runningApps = NSWorkspace.shared.runningApplications
                if let app = runningApps.first(where: { $0.bundleIdentifier == target.bundleIdentifier }) {
                    app.activate(options: [.activateAllWindows])
                } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: target.bundleIdentifier) {
                    let config = NSWorkspace.OpenConfiguration()
                    config.activates = true
                    NSWorkspace.shared.openApplication(at: url, configuration: config)
                }
            }
        }
    }
}

// MARK: - MenuBar Window View (wrapper for window dragging)

struct MenuBarWindowView: View {
    var onClose: () -> Void
    var onOpenDestinTab: () -> Void
    var onOpenSuperSwitch: () -> Void
    var onOpenBrowserBypasser: () -> Void
    var onOpenAssessPrepHack: () -> Void
    var onOpenSettings: () -> Void
    var onOpenWallpaper: () -> Void
    var onOpenHackerDesktop: () -> Void
    var onOpenErrorHub: () -> Void = {}
    
    var body: some View {
        MenuBarView(onClose: onClose, onOpenDestinTab: onOpenDestinTab, onOpenSuperSwitch: onOpenSuperSwitch, onOpenBrowserBypasser: onOpenBrowserBypasser, onOpenAssessPrepHack: onOpenAssessPrepHack, onOpenSettings: onOpenSettings, onOpenWallpaper: onOpenWallpaper, onOpenHackerDesktop: onOpenHackerDesktop, onOpenErrorHub: onOpenErrorHub)
    }
}

// MARK: - DestinTab Window View (wrapper for window dragging)

struct DestinTabWindowView: View {
    var onClose: () -> Void
    
    var body: some View {
        DestinTabView(onClose: onClose)
    }
}

// MARK: - SuperSwitch Window View (wrapper for window dragging)

struct SuperSwitchWindowView: View {
    var onClose: () -> Void
    
    var body: some View {
        SuperSwitchView(onClose: onClose)
    }
}

// MARK: - BrowserBypasser Window View (wrapper for window dragging)

struct BrowserBypasserWindowView: View {
    var onClose: () -> Void
    
    var body: some View {
        BrowserBypasserView(onClose: onClose)
    }
}

// MARK: - AssessPrepHack Window View (wrapper for window dragging)

struct AssessPrepHackWindowView: View {
    var onClose: () -> Void
    
    var body: some View {
        AssessPrepHackView(onClose: onClose)
    }
}

// MARK: - Settings Window View

struct SettingsWindowView: View {
    var onClose: () -> Void
    
    var body: some View {
        SettingsContainerView(onClose: onClose)
    }
}

// MARK: - Settings Container

struct SettingsContainerView: View {
    @State private var selectedTab = 0
    @ObservedObject private var prefs = PreferencesManager.shared
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Hacker title bar
            HStack(spacing: 0) {
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    onClose()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 24, height: 24)
                        .background(Color(white: 0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)
                
                Spacer()
                
                Text("Settings")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Color.clear.frame(width: 36, height: 24)
            }
            .padding(.vertical, 8)
            .background(Color(white: 0.03))
            
            Divider().background(Color.white.opacity(0.1))
            
            TabView(selection: $selectedTab) {
                GeneralSettingsView()
                    .tabItem {
                        Label(String(localized: "tab.general"), systemImage: "gear")
                    }
                    .tag(0)

                ShortcutsSettingsView()
                    .tabItem {
                        Label(String(localized: "tab.shortcuts"), systemImage: "keyboard")
                    }
                    .tag(1)

                AppearanceSettingsView()
                    .tabItem {
                        Label(String(localized: "tab.appearance"), systemImage: "paintbrush")
                    }
                    .tag(2)

                BrowserSettingsView()
                    .tabItem {
                        Label(String(localized: "tab.browser"), systemImage: "globe")
                    }
                    .tag(3)

                AdvancedSettingsView()
                    .tabItem {
                        Label(String(localized: "tab.advanced"), systemImage: "wrench.and.screwdriver")
                    }
                    .tag(4)
            }
            .padding(.horizontal, 4)
            .preferredColorScheme(prefs.preferences.theme.colorScheme)
        }
        .background(Color.black)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

extension AppTheme {
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
