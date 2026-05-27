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
    var showPopoverHotKeyRef: EventHotKeyRef?

    var splashWindow: NSWindow?
    private var clickOutsideMonitor: Any?

    private var targetWindowAlpha: CGFloat {
        CGFloat(PreferencesManager.shared.preferences.windowOpacity)
    }

    private var windowLevel: NSWindow.Level {
        PreferencesManager.shared.preferences.keepWindowOnTop ? .floating : .normal
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        showSplashScreen()

        // Phase 1: Splash (2s) -> Phase 2: Chaos Animation -> Phase 3: Main Window
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.closeSplashScreen()
            self.setupStatusItem()
            self.setupShowPopoverShortcut()

            PreferencesManager.shared.onPreferencesChanged = { [weak self] _ in
                self?.setupShowPopoverShortcut()
                self?.updateStatusItemIcon()
                self?.updateMainWindowSize()
                self?.updateAllWindowLevels()
                self?.updateClickOutsideMonitor()
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

            // Phase 2: Setup main menu window first (hidden at bottom layer)
            self.setupMainWindow()
            self.setupDestinTabWindow()
            self.setupSuperSwitchWindow()
            self.setupBrowserBypasserWindow()
            self.setupAssessPrepHackWindow()
            self.setupSettingsWindow()
            if let window = self.mainWindow {
                window.alphaValue = 0
                window.orderBack(nil)
                
                // Phase 3: Chaos glitch animation
                LaunchAnimationManager.shared.startChaosAnimation(mainWindow: window) { [weak self] in
                    // Phase 4: Animation complete, main menu window is fully revealed
                    self?.mainWindow?.makeKeyAndOrderFront(nil)
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
        
        window.makeKeyAndOrderFront(nil)
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
        let size = NSSize(
            width: prefs.panelWidth,
            height: prefs.panelMaxHeight
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

        // Center on screen
        if let screen = NSScreen.main {
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
        })
            .frame(width: size.width, height: size.height)
            .background(Color.clear)

        window.contentView = NSHostingView(rootView: rootView)

        mainWindow = window
    }
    
    // MARK: - DestinTab Window
    
    private func setupDestinTabWindow() {
        let prefs = PreferencesManager.shared.preferences
        let size = NSSize(
            width: prefs.panelWidth,
            height: min(prefs.panelMaxHeight, CGFloat(prefs.maxTabsInPopover) * CGFloat(prefs.rowHeight) + 120)
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
            .frame(width: size.width, height: size.height)
            .background(Color.clear)

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
        let size = NSSize(
            width: prefs.panelWidth,
            height: prefs.panelMaxHeight
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
            .frame(width: size.width, height: size.height)
            .background(Color.clear)

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
        let size = NSSize(
            width: prefs.panelWidth,
            height: prefs.panelMaxHeight
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
            .frame(width: size.width, height: size.height)
            .background(Color.clear)

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
        let size = NSSize(
            width: prefs.panelWidth,
            height: prefs.panelMaxHeight
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
            .frame(width: size.width, height: size.height)
            .background(Color.clear)

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
        let size = NSSize(width: 520, height: 480)

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
            .frame(width: size.width, height: size.height)
            .background(Color.clear)

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
        let size = NSSize(width: 520, height: 480)

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
            .frame(width: size.width, height: size.height)
            .background(Color.clear)

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
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let size = NSSize(width: min(900, screenFrame.width - 100), height: min(600, screenFrame.height - 100))

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
            .frame(width: size.width, height: size.height)
            .background(Color.clear)

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

    private func updateMainWindowSize() {
        guard let window = mainWindow else { return }
        let prefs = PreferencesManager.shared.preferences
        let newSize = NSSize(
            width: prefs.panelWidth,
            height: min(prefs.panelMaxHeight, CGFloat(prefs.maxTabsInPopover) * CGFloat(prefs.rowHeight) + 120)
        )
        window.setContentSize(newSize)
    }

    func showMainWindow(animated: Bool = false) {
        guard let window = mainWindow else { return }

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

    func hideMainWindow() {
        guard let window = mainWindow else { return }
        SoundEffectManager.shared.playWindowClose()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.mainWindow?.orderOut(nil)
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
        if let ref = showPopoverHotKeyRef {
            UnregisterEventHotKey(ref)
        }
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        uninstallGlobalEventHandler()
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
        installGlobalEventHandlerIfNeeded()

        if let ref = showPopoverHotKeyRef {
            UnregisterEventHotKey(ref)
            showPopoverHotKeyRef = nil
        }

        let prefs = PreferencesManager.shared.preferences
        let keyCode = prefs.showPopoverKeyCode
        let modifiers = cocoaToCarbonModifiers(prefs.showPopoverModifiers)

        guard keyCode != 0 || modifiers != 0 else { return }

        let hotKeyID = EventHotKeyID(signature: showPopoverHotKeySignature, id: showPopoverHotKeyID)

        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            showPopoverHotKeyRef = hotKeyRef
        }
    }

    private func cocoaToCarbonModifiers(_ cocoaFlags: UInt32) -> UInt32 {
        let flags = NSEvent.ModifierFlags(rawValue: UInt(cocoaFlags))
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.option)  { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.shift)   { carbon |= UInt32(shiftKey) }
        return carbon
    }
}

// MARK: - Global Event Handler

private var globalEventHandlerInstalled = false
private var globalEventHandlerRef: EventHandlerRef?
private let showPopoverHotKeySignature = FourCharCode(bitPattern: 0x53484F57) // 'SHOW'
private let showPopoverHotKeyID: UInt32 = 9999

func installGlobalEventHandlerIfNeeded() {
    guard !globalEventHandlerInstalled else { return }

    let callback: EventHandlerUPP = { _, eventRef, _ -> OSStatus in
        guard let event = eventRef else { return OSStatus(eventNotHandledErr) }
        var hkID = EventHotKeyID()
        let result = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hkID
        )
        if result == noErr && hkID.signature == showPopoverHotKeySignature && hkID.id == showPopoverHotKeyID {
            DispatchQueue.main.async {
                (NSApp.delegate as? AppDelegate)?.toggleMainWindow()
            }
            return noErr
        }
        return OSStatus(eventNotHandledErr)
    }

    var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    var handler: EventHandlerRef?
    let status = InstallEventHandler(GetEventDispatcherTarget(), callback, 1, &eventType, nil, &handler)
    if status == noErr {
        globalEventHandlerRef = handler
        globalEventHandlerInstalled = true
    }
}

func uninstallGlobalEventHandler() {
    if let ref = globalEventHandlerRef {
        RemoveEventHandler(ref)
        globalEventHandlerRef = nil
    }
    globalEventHandlerInstalled = false
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
    
    var body: some View {
        MenuBarView(onClose: onClose, onOpenDestinTab: onOpenDestinTab, onOpenSuperSwitch: onOpenSuperSwitch, onOpenBrowserBypasser: onOpenBrowserBypasser, onOpenAssessPrepHack: onOpenAssessPrepHack, onOpenSettings: onOpenSettings, onOpenWallpaper: onOpenWallpaper, onOpenHackerDesktop: onOpenHackerDesktop)
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
