//
//  ClassGodApp.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI
import AppKit
import Carbon
import Combine

nonisolated enum LaunchDestination: Equatable {
    case mainPanel
    case permissionGate
}

nonisolated enum LaunchWindowPresentationPolicy {
    static func destination(isPermissionGateUnlocked: Bool) -> LaunchDestination {
        isPermissionGateUnlocked ? .mainPanel : .permissionGate
    }

    static func splashDelay(preferred: Double, animationDuration: Double) -> Double {
        animationDuration > 0 ? preferred : 1
    }

    static func shouldResetBeforeInitialShow(isVisible: Bool, isKeyWindow: Bool) -> Bool {
        isVisible && !isKeyWindow
    }
}

nonisolated enum SettingsWindowLayoutPolicy {
    static let baseWidth: CGFloat = 720
    static let baseHeight: CGFloat = 620
}

nonisolated enum FeatureWindowKind: CaseIterable {
    case preflight, destinTab, superSwitch, ghostProtocol, browserBypasser, assessPrepHack
    case settings, wallpaper, hackerDesktop, clipo, errorHub, fanControl
    case activityMonitor, permissionCenter, fakeLock
}

nonisolated struct FeatureWindowLayout: Equatable {
    let defaultWidth: CGFloat
    let defaultHeight: CGFloat
    let minimumWidth: CGFloat
    let minimumHeight: CGFloat
}

nonisolated enum FeatureWindowLayoutPolicy {
    static func layout(for kind: FeatureWindowKind) -> FeatureWindowLayout {
        switch kind {
        case .preflight: return .init(defaultWidth: 760, defaultHeight: 680, minimumWidth: 520, minimumHeight: 460)
        case .destinTab: return .init(defaultWidth: 520, defaultHeight: 620, minimumWidth: 360, minimumHeight: 360)
        case .superSwitch: return .init(defaultWidth: 620, defaultHeight: 660, minimumWidth: 420, minimumHeight: 400)
        case .ghostProtocol: return .init(defaultWidth: 640, defaultHeight: 620, minimumWidth: 420, minimumHeight: 380)
        case .browserBypasser: return .init(defaultWidth: 680, defaultHeight: 640, minimumWidth: 440, minimumHeight: 400)
        case .assessPrepHack: return .init(defaultWidth: 700, defaultHeight: 680, minimumWidth: 460, minimumHeight: 420)
        case .settings: return .init(defaultWidth: 720, defaultHeight: 620, minimumWidth: 560, minimumHeight: 460)
        case .wallpaper: return .init(defaultWidth: 860, defaultHeight: 600, minimumWidth: 580, minimumHeight: 420)
        case .hackerDesktop: return .init(defaultWidth: 940, defaultHeight: 680, minimumWidth: 680, minimumHeight: 480)
        case .clipo: return .init(defaultWidth: 780, defaultHeight: 640, minimumWidth: 560, minimumHeight: 420)
        case .errorHub: return .init(defaultWidth: 700, defaultHeight: 640, minimumWidth: 460, minimumHeight: 400)
        case .fanControl: return .init(defaultWidth: 680, defaultHeight: 680, minimumWidth: 500, minimumHeight: 460)
        case .activityMonitor: return .init(defaultWidth: 1_000, defaultHeight: 680, minimumWidth: 720, minimumHeight: 480)
        case .permissionCenter: return .init(defaultWidth: 900, defaultHeight: 680, minimumWidth: 680, minimumHeight: 500)
        case .fakeLock: return .init(defaultWidth: 760, defaultHeight: 650, minimumWidth: 560, minimumHeight: 440)
        }
    }
}

nonisolated enum FeatureWindowResizePolicy {
    static func shouldApplyScale(previousZoom: Double, currentZoom: Double) -> Bool {
        previousZoom.isFinite && currentZoom.isFinite && abs(previousZoom - currentZoom) > 0.000_1
    }
}

nonisolated enum WindowChromePolicy {
    static func cornerRadius(base: Double, zoom: Double) -> CGFloat {
        guard base.isFinite, zoom.isFinite, base > 0, zoom > 0 else { return 0 }
        return CGFloat(base * zoom)
    }
}

enum WidgetHostSnapshot {
    static func save(reloadWidgets: Bool = true) {
        let monitor = SystemMonitor.shared
        let store = WidgetDataStore.shared
        let disk = monitor.disks.first
        store.saveSystemSnapshot(
            cpu: monitor.cpu.total,
            memoryUsed: Double(monitor.memory.used) / 1024 / 1024 / 1024,
            memoryTotal: Double(monitor.memory.total) / 1024 / 1024 / 1024,
            diskFree: Double(disk?.free ?? 0) / 1024 / 1024 / 1024,
            diskTotal: Double(disk?.total ?? 0) / 1024 / 1024 / 1024,
            netDown: monitor.network.downloadSpeedKBs / 1024,
            netUp: monitor.network.uploadSpeedKBs / 1024,
            battery: WidgetMetricNormalization.batteryPercent(from: monitor.battery.level),
            isCharging: monitor.battery.isCharging,
            uptime: Date().timeIntervalSince(monitor.system.bootTime ?? Date())
        )
        store.saveAccent(PreferencesManager.shared.preferences.themeAccent)
        if reloadWidgets {
            store.reloadWidgets(ClassGodWidgetKind.systemKinds)
        }
    }
}

nonisolated struct WindowTransitionTracker<Key: Hashable> {
    private struct State {
        let generation: UInt
        let targetVisible: Bool
    }

    private var states: [Key: State] = [:]

    mutating func begin(for key: Key, targetVisible: Bool, currentVisible: Bool) -> UInt? {
        if let state = states[key], state.targetVisible == targetVisible { return nil }
        guard states[key] != nil || currentVisible != targetVisible else { return nil }
        let generation = (states[key]?.generation ?? 0) &+ 1
        states[key] = State(generation: generation, targetVisible: targetVisible)
        return generation
    }

    func isCurrent(_ generation: UInt, for key: Key, targetVisible: Bool) -> Bool {
        guard let state = states[key] else { return false }
        return state.generation == generation && state.targetVisible == targetVisible
    }

    func targetVisibility(for key: Key, currentVisible: Bool) -> Bool {
        states[key]?.targetVisible ?? currentVisible
    }
}

@main
struct ClassGodApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {}
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var mainWindow: NSWindow?
    var preflightWindow: NSWindow?
    var destinTabWindow: NSWindow?
    var superSwitchWindow: NSWindow?
    var ghostProtocolWindow: NSWindow?
    var browserBypasserWindow: NSWindow?
    var assessPrepHackWindow: NSWindow?
    var settingsWindow: NSWindow?
    var wallpaperBrowserWindow: NSWindow?
    var hackerDesktopWindow: NSWindow?
    var clipoWindow: NSWindow?
    var errorHubWindow: NSWindow?
    var fanControlWindow: NSWindow?
    var activityMonitorWindow: NSWindow?
    var permissionCenterWindow: NSWindow?
    var permissionGateWindow: NSWindow?
    var fakeLockWindow: NSWindow?
    var showPopoverCustomHotKeyID: UInt32?
    var panicHotKeyID: UInt32?
    var clipoHotKeyIDs: [UInt32] = []

    var splashWindow: NSWindow?
    private var clickOutsideMonitor: Any?
    private var widgetSnapshotTimer: Timer?
    private var widgetAccentReloadWorkItem: DispatchWorkItem?
    private var windowTransitions = WindowTransitionTracker<ObjectIdentifier>()
    private var lastObservedPreferences = PreferencesManager.shared.preferences
    private var permissionGateCancellable: AnyCancellable?
    private var launchAnimationCompleted = false
    private var gatedFeaturesActive = false
    private var mainWindowContentInstalled = false
    private var applicationObserversInstalled = false
    private var globalHotKeyHandlerInstalled = false

    private var targetWindowAlpha: CGFloat {
        CGFloat(PreferencesManager.shared.preferences.windowOpacity)
    }

    private var windowLevel: NSWindow.Level {
        PreferencesManager.shared.preferences.keepWindowOnTop ? .floating : .normal
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let launchAnimationDuration = Anim.duration
        showSplashScreen()

        let permissionService = PermissionCenterService.shared
        permissionGateCancellable = permissionService.$isGateUnlocked
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.presentPostLaunchDestination()
            }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(permissionStateNeedsRefresh),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        permissionService.refreshAll()

        let launchDelay = LaunchWindowPresentationPolicy.splashDelay(
            preferred: 2,
            animationDuration: launchAnimationDuration
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + launchDelay) { [weak self] in
            guard let self = self else { return }
            self.closeSplashScreen()
            AppIconManager.shared.refreshIcon()
            self.setupMainWindow()
            if let window = self.mainWindow {
                window.alphaValue = 0
                window.orderBack(nil)
                LaunchAnimationManager.shared.startChaosAnimation(mainWindow: window) { [weak self, weak window] in
                    if let window,
                       LaunchWindowPresentationPolicy.shouldResetBeforeInitialShow(
                           isVisible: window.isVisible,
                           isKeyWindow: window.isKeyWindow
                       ) {
                        window.alphaValue = 0
                        window.orderOut(nil)
                    }
                    self?.launchAnimationCompleted = true
                    self?.presentPostLaunchDestination()
                }
            }
        }
    }

    @objc private func permissionStateNeedsRefresh() {
        PermissionCenterService.shared.refreshAll()
    }

    private func presentPostLaunchDestination() {
        guard launchAnimationCompleted else { return }
        switch LaunchWindowPresentationPolicy.destination(
            isPermissionGateUnlocked: PermissionCenterService.shared.isGateUnlocked
        ) {
        case .mainPanel:
            activateGatedFeatures()
            hidePermissionGateWindow()
            showMainWindow(animated: false)
        case .permissionGate:
            deactivateGatedFeatures()
            hideGatedWindows()
            showPermissionGateWindow()
        }
    }

    private func activateGatedFeatures() {
        guard !gatedFeaturesActive else { return }
        gatedFeaturesActive = true
        installMainWindowContentIfNeeded()
        _ = DesktopWallpaperController.shared

        if statusItem == nil {
            setupStatusItem()
        } else {
            updateStatusItemTimer()
            updateStatusItemIcon()
        }
        startWidgetSnapshotSync()
        setupShowPopoverShortcut()
        setupPanicShortcut()
        if !globalHotKeyHandlerInstalled {
            setupGlobalHotKeyHandler()
            globalHotKeyHandlerInstalled = true
        }
        FakeLockService.shared.start()
        ClipoService.shared.start()
        clipoHotKeyIDs = ClipoService.shared.registerDefaultHotKeys { [weak self] in
            self?.toggleClipoWindow()
        }
        ShortcutCatalogCoordinator.shared.start()
        PreferencesManager.shared.onPreferencesChanged = { [weak self] preferences in
            self?.preferencesDidChange(preferences)
        }
        installApplicationObserversIfNeeded()
        AppIconManager.shared.refreshIcon()
        updateClickOutsideMonitor()
        NotificationCenter.default.post(name: .classGodTabsDidChange, object: nil)
    }

    private func deactivateGatedFeatures() {
        guard gatedFeaturesActive else { return }
        gatedFeaturesActive = false
        PreferencesManager.shared.onPreferencesChanged = nil
        statusItemTimer?.invalidate()
        statusItemTimer = nil
        statusItemUpdateTask?.cancel()
        statusItemUpdateTask = nil
        statusItem?.button?.title = ""
        widgetSnapshotTimer?.invalidate()
        widgetSnapshotTimer = nil
        SystemMonitor.shared.stop(client: .widgetHost)
        widgetAccentReloadWorkItem?.cancel()
        widgetAccentReloadWorkItem = nil
        FakeLockService.shared.stop()
        ClipoService.shared.stop()
        GhostProtocolController.shared.shutdown()
        ShortcutCatalogCoordinator.shared.stop()
        AssessPrepHackViewModel.shared.stopAllBypasses()
        DesktopWallpaperController.shared.hideWallpapers()
        SMCService.shared.restoreSystemFanControl()

        if let id = showPopoverCustomHotKeyID {
            ShortcutManager.shared.unregisterCustomHotKey(id: id)
            showPopoverCustomHotKeyID = nil
        }
        if let id = panicHotKeyID {
            ShortcutManager.shared.unregisterCustomHotKey(id: id)
            panicHotKeyID = nil
        }
        for id in clipoHotKeyIDs {
            ShortcutManager.shared.unregisterCustomHotKey(id: id)
        }
        clipoHotKeyIDs.removeAll()
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }

    private func installApplicationObserversIfNeeded() {
        guard !applicationObserversInstalled else { return }
        applicationObserversInstalled = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(tabsDidChange),
            name: .classGodTabsDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowPositionDidChange),
            name: .draggableWindowDidMove,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showErrorHubFromNotification(_:)),
            name: .classGodShowErrorHubEntry,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hideClipoForPaste),
            name: .clipoWillPaste,
            object: nil
        )
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
        window.alphaValue = 0
        window.orderOut(nil)
        splashWindow = nil
    }

    // MARK: - Main Window

    private func setupMainWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = constrainedWindowSize(
            base: NSSize(
                width: prefs.panelWidth,
                height: min(prefs.panelMaxHeight, CGFloat(prefs.maxTabsInPopover) * CGFloat(prefs.rowHeight) + 120)
            ),
            zoom: zoom
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

        window.contentView = NSHostingView(rootView: Color.black)
        updateWindowCornerMask(window)
        mainWindow = window
    }

    private func installMainWindowContentIfNeeded() {
        guard !mainWindowContentInstalled, let window = mainWindow else { return }
        let rootView = MenuBarWindowView(onClose: { [weak self] in
            self?.hideMainWindow()
        }, onOpenPreflight: { [weak self] in
            self?.showPreflightWindow()
        }, onOpenDestinTab: { [weak self] in
            self?.showDestinTabWindow()
        }, onOpenSuperSwitch: { [weak self] in
            self?.showSuperSwitchWindow()
        }, onOpenGhostProtocol: { [weak self] in
            self?.showGhostProtocolWindow()
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
        }, onOpenClipo: { [weak self] in
            self?.showClipoWindow()
        }, onOpenFanControl: { [weak self] in
            self?.showFanControlWindow()
        }, onOpenErrorHub: { [weak self] in
            self?.showErrorHubWindow()
        }, onOpenActivityMonitor: { [weak self] in
            self?.showActivityMonitorWindow()
        }, onOpenPermissionCenter: { [weak self] in
            self?.showPermissionCenterWindow()
        }, onOpenFakeLock: { [weak self] in
            self?.showFakeLockWindow()
        })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .overlay(WindowResizeHandles())

        window.contentView = NSHostingView(rootView: rootView)
        updateWindowCornerMask(window)
        mainWindowContentInstalled = true
    }

    // MARK: - Preflight Window

    private func setupPreflightWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = featureWindowSize(.preflight, zoom: zoom)
        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureFeatureWindow(window, kind: .preflight, zoom: zoom)
        window.level = windowLevel
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false

        if let main = mainWindow {
            window.setFrameOrigin(NSPoint(x: main.frame.midX - size.width / 2, y: main.frame.midY - size.height / 2))
        } else {
            centerWindowOnScreen(window)
        }
        constrainWindowToVisibleScreen(window)

        let rootView = PreflightWindowView(
            onClose: { [weak self] in self?.hidePreflightWindow() },
            onOpenDestinTab: { [weak self] in self?.showDestinTabWindow() },
            onOpenSuperSwitch: { [weak self] in self?.showSuperSwitchWindow() },
            onOpenPermissionCenter: { [weak self] in self?.showPermissionCenterWindow() }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .overlay(WindowResizeHandles())
        window.contentView = NSHostingView(rootView: rootView)
        updateWindowCornerMask(window)
        preflightWindow = window
    }

    func showPreflightWindow(animated: Bool = true) {
        guard let window = preflightWindow else {
            setupPreflightWindow()
            showPreflightWindow(animated: animated)
            return
        }
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }
        ShortcutCatalogCoordinator.shared.reload()
        PermissionCenterService.shared.refreshAll()
        SoundEffectManager.shared.playWindowOpen(feature: "preflight")

        if animated && Anim.enabled {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.alphaValue = targetWindowAlpha
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hidePreflightWindow() {
        guard let window = preflightWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        SoundEffectManager.shared.playWindowClose(feature: "preflight")
        guard Anim.enabled else {
            window.alphaValue = 0
            window.orderOut(nil)
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            guard let self, let window,
                  self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
            window.orderOut(nil)
        }
    }

    @objc func togglePreflightWindow() {
        guard let window = preflightWindow else {
            setupPreflightWindow()
            showPreflightWindow(animated: true)
            return
        }
        windowTargetIsVisible(window) ? hidePreflightWindow() : showPreflightWindow(animated: true)
    }
    
    // MARK: - DestinTab Window
    
    private func setupDestinTabWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = featureWindowSize(.destinTab, zoom: zoom)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureFeatureWindow(window, kind: .destinTab, zoom: zoom)

        window.level = .normal
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        
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
        updateWindowCornerMask(window)

        destinTabWindow = window
    }
    
    func showDestinTabWindow(animated: Bool = true) {
        guard let window = destinTabWindow else {
            setupDestinTabWindow()
            showDestinTabWindow(animated: animated)
            return
        }
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }
        
        SoundEffectManager.shared.playWindowOpen(feature: "destintab")
        
        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func hideDestinTabWindow() {
        guard let window = destinTabWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        SoundEffectManager.shared.playWindowClose(feature: "destintab")
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            guard let self, let window,
                  self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
            window.orderOut(nil)
        }
    }
    
    @objc func toggleDestinTabWindow() {
        guard let window = destinTabWindow else {
            setupDestinTabWindow()
            showDestinTabWindow(animated: true)
            return
        }
        
        if windowTargetIsVisible(window) {
            hideDestinTabWindow()
        } else {
            showDestinTabWindow(animated: true)
        }
    }
    
    // MARK: - SuperSwitch Window
    
    private func setupSuperSwitchWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = featureWindowSize(.superSwitch, zoom: zoom)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureFeatureWindow(window, kind: .superSwitch, zoom: zoom)

        window.level = .normal
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        
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
        updateWindowCornerMask(window)

        superSwitchWindow = window
    }
    
    func showSuperSwitchWindow(animated: Bool = true) {
        guard let window = superSwitchWindow else {
            setupSuperSwitchWindow()
            showSuperSwitchWindow(animated: animated)
            return
        }
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }
        
        SoundEffectManager.shared.playWindowOpen(feature: "superswitch")
        
        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func hideSuperSwitchWindow() {
        guard let window = superSwitchWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        SoundEffectManager.shared.playWindowClose(feature: "superswitch")
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            guard let self, let window,
                  self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
            window.orderOut(nil)
        }
    }
    
    @objc func toggleSuperSwitchWindow() {
        guard let window = superSwitchWindow else {
            setupSuperSwitchWindow()
            showSuperSwitchWindow(animated: true)
            return
        }
        
        if windowTargetIsVisible(window) {
            hideSuperSwitchWindow()
        } else {
            showSuperSwitchWindow(animated: true)
        }
    }

    // MARK: - Ghost Protocol Window

    private func setupGhostProtocolWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = featureWindowSize(.ghostProtocol, zoom: zoom)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureFeatureWindow(window, kind: .ghostProtocol, zoom: zoom)
        window.level = windowLevel
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        if let main = mainWindow {
            window.setFrameOrigin(NSPoint(x: main.frame.minX + 24, y: main.frame.minY + 24))
        } else if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            window.setFrameOrigin(NSPoint(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2))
        }
        constrainWindowToVisibleScreen(window)

        let rootView = GhostProtocolWindowView(onClose: { [weak self] in
            self?.hideGhostProtocolWindow()
        })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .overlay(WindowResizeHandles())
        window.contentView = NSHostingView(rootView: rootView)
        updateWindowCornerMask(window)
        ghostProtocolWindow = window
    }

    func showGhostProtocolWindow(animated: Bool = true) {
        guard let window = ghostProtocolWindow else {
            setupGhostProtocolWindow()
            showGhostProtocolWindow(animated: animated)
            return
        }
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }
        GhostProtocolController.shared.refresh()
        SoundEffectManager.shared.playWindowOpen(feature: "ghostprotocol")

        if animated && Anim.enabled {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.alphaValue = targetWindowAlpha
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hideGhostProtocolWindow() {
        guard let window = ghostProtocolWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        NotificationCenter.default.post(name: .ghostProtocolWindowWillHide, object: nil)
        SoundEffectManager.shared.playWindowClose(feature: "ghostprotocol")
        guard Anim.enabled else {
            window.alphaValue = 0
            window.orderOut(nil)
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            guard let self, let window,
                  self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
            window.orderOut(nil)
        }
    }

    @objc func toggleGhostProtocolWindow() {
        guard let window = ghostProtocolWindow else {
            setupGhostProtocolWindow()
            showGhostProtocolWindow(animated: true)
            return
        }
        if windowTargetIsVisible(window) {
            hideGhostProtocolWindow()
        } else {
            showGhostProtocolWindow(animated: true)
        }
    }
    
    // MARK: - BrowserBypasser Window
    
    private func setupBrowserBypasserWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = featureWindowSize(.browserBypasser, zoom: zoom)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureFeatureWindow(window, kind: .browserBypasser, zoom: zoom)

        window.level = .normal
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        
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
        updateWindowCornerMask(window)

        browserBypasserWindow = window
    }
    
    func showBrowserBypasserWindow(animated: Bool = true) {
        guard let window = browserBypasserWindow else {
            setupBrowserBypasserWindow()
            showBrowserBypasserWindow(animated: animated)
            return
        }
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }
        
        SoundEffectManager.shared.playWindowOpen(feature: "browserbypasser")
        
        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func hideBrowserBypasserWindow() {
        guard let window = browserBypasserWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        SoundEffectManager.shared.playWindowClose(feature: "browserbypasser")
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            guard let self, let window,
                  self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
            window.orderOut(nil)
        }
    }
    
    @objc func toggleBrowserBypasserWindow() {
        guard let window = browserBypasserWindow else {
            setupBrowserBypasserWindow()
            showBrowserBypasserWindow(animated: true)
            return
        }
        
        if windowTargetIsVisible(window) {
            hideBrowserBypasserWindow()
        } else {
            showBrowserBypasserWindow(animated: true)
        }
    }
    
    // MARK: - AssessPrepHack Window
    
    private func setupAssessPrepHackWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = featureWindowSize(.assessPrepHack, zoom: zoom)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureFeatureWindow(window, kind: .assessPrepHack, zoom: zoom)

        window.level = .normal
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        
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
        updateWindowCornerMask(window)

        assessPrepHackWindow = window
    }
    
    func showAssessPrepHackWindow(animated: Bool = true) {
        guard let window = assessPrepHackWindow else {
            setupAssessPrepHackWindow()
            showAssessPrepHackWindow(animated: animated)
            return
        }
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }
        
        SoundEffectManager.shared.playWindowOpen(feature: "assessprephack")
        NotificationCenter.default.post(name: .assessPrepHackWindowDidShow, object: nil)
        
        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func hideAssessPrepHackWindow() {
        guard let window = assessPrepHackWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        SoundEffectManager.shared.playWindowClose(feature: "assessprephack")
        NotificationCenter.default.post(name: .assessPrepHackWindowWillHide, object: nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            guard let self, let window,
                  self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
            window.orderOut(nil)
        }
    }
    
    @objc func toggleAssessPrepHackWindow() {
        guard let window = assessPrepHackWindow else {
            setupAssessPrepHackWindow()
            showAssessPrepHackWindow(animated: true)
            return
        }
        
        if windowTargetIsVisible(window) {
            hideAssessPrepHackWindow()
        } else {
            showAssessPrepHackWindow(animated: true)
        }
    }
    
    // MARK: - Settings Window
    
    private func setupSettingsWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = featureWindowSize(.settings, zoom: zoom)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureFeatureWindow(window, kind: .settings, zoom: zoom)

        window.level = .normal
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        
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
        updateWindowCornerMask(window)

        settingsWindow = window
    }
    
    func showSettingsWindow(animated: Bool = true) {
        guard let window = settingsWindow else {
            setupSettingsWindow()
            showSettingsWindow(animated: animated)
            return
        }
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }
        
        SoundEffectManager.shared.playWindowOpen()
        
        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func hideSettingsWindow() {
        guard let window = settingsWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        SoundEffectManager.shared.playWindowClose()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            guard let self, let window,
                  self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
            window.orderOut(nil)
        }
    }
    
    @objc func toggleSettingsWindow() {
        guard let window = settingsWindow else {
            setupSettingsWindow()
            showSettingsWindow(animated: true)
            return
        }
        
        if windowTargetIsVisible(window) {
            hideSettingsWindow()
        } else {
            showSettingsWindow(animated: true)
        }
    }

    // MARK: - Wallpaper Browser Window

    private func setupWallpaperBrowserWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = featureWindowSize(.wallpaper, zoom: zoom)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureFeatureWindow(window, kind: .wallpaper, zoom: zoom)

        window.level = windowLevel
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false

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
        updateWindowCornerMask(window)

        wallpaperBrowserWindow = window
    }

    func showWallpaperBrowserWindow(animated: Bool = true) {
        guard let window = wallpaperBrowserWindow else {
            setupWallpaperBrowserWindow()
            showWallpaperBrowserWindow(animated: animated)
            return
        }
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }

        SoundEffectManager.shared.playWindowOpen()

        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hideWallpaperBrowserWindow() {
        guard let window = wallpaperBrowserWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        SoundEffectManager.shared.playWindowClose()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            guard let self, let window,
                  self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
            window.orderOut(nil)
        }
    }

    @objc func toggleWallpaperBrowserWindow() {
        guard let window = wallpaperBrowserWindow else {
            setupWallpaperBrowserWindow()
            showWallpaperBrowserWindow(animated: true)
            return
        }

        if windowTargetIsVisible(window) {
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
        let size = featureWindowSize(.hackerDesktop, zoom: zoom, margin: 100, screen: screen)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureFeatureWindow(window, kind: .hackerDesktop, zoom: zoom)

        window.level = windowLevel
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false

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
        updateWindowCornerMask(window)

        hackerDesktopWindow = window
    }

    func showHackerDesktopWindow(animated: Bool = true) {
        guard let window = hackerDesktopWindow else {
            setupHackerDesktopWindow()
            // Prevent infinite recursion if screen is unavailable
            guard hackerDesktopWindow != nil else { return }
            showHackerDesktopWindow(animated: animated)
            return
        }
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }

        SoundEffectManager.shared.playWindowOpen(feature: "hackerdesktop")
        NotificationCenter.default.post(name: .hackerDesktopWindowDidShow, object: nil)

        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hideHackerDesktopWindow() {
        guard let window = hackerDesktopWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        SoundEffectManager.shared.playWindowClose(feature: "hackerdesktop")
        NotificationCenter.default.post(name: .hackerDesktopWindowWillHide, object: nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            guard let self, let window,
                  self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
            window.orderOut(nil)
        }
    }

    @objc func toggleHackerDesktopWindow() {
        guard let window = hackerDesktopWindow else {
            setupHackerDesktopWindow()
            showHackerDesktopWindow(animated: true)
            return
        }

        if windowTargetIsVisible(window) {
            hideHackerDesktopWindow()
        } else {
            showHackerDesktopWindow(animated: true)
        }
    }

    // MARK: - Clipo Window

    private func setupClipoWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = featureWindowSize(.clipo, zoom: zoom, margin: 80, screen: NSScreen.main)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureFeatureWindow(window, kind: .clipo, zoom: zoom)
        window.level = windowLevel
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            window.setFrameOrigin(NSPoint(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2))
        }

        window.contentView = NSHostingView(
            rootView: ClipoWindowView(onClose: { [weak self] in
                self?.hideClipoWindow()
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .overlay(WindowResizeHandles())
        )
        updateWindowCornerMask(window)
        clipoWindow = window
    }

    func showClipoWindow(animated: Bool = true) {
        guard let window = clipoWindow else {
            setupClipoWindow()
            guard clipoWindow != nil else { return }
            showClipoWindow(animated: animated)
            return
        }
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }

        SoundEffectManager.shared.playWindowOpen(feature: "clipo")
        ClipoService.shared.rememberPasteTarget()
        NSApplication.shared.activate(ignoringOtherApps: true)
        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hideClipoWindow(playSound: Bool = true) {
        guard let window = clipoWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        if playSound {
            SoundEffectManager.shared.playWindowClose(feature: "clipo")
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            guard let self, let window,
                  self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
            window.orderOut(nil)
        }
    }

    @objc func toggleClipoWindow() {
        guard let window = clipoWindow else {
            setupClipoWindow()
            showClipoWindow(animated: true)
            return
        }
        windowTargetIsVisible(window) ? hideClipoWindow() : showClipoWindow(animated: true)
    }

    @objc private func hideClipoForPaste() {
        hideClipoWindow(playSound: false)
    }

    // MARK: - Error Hub Window

    private func setupErrorHubWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = featureWindowSize(.errorHub, zoom: zoom)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureFeatureWindow(window, kind: .errorHub, zoom: zoom)

        window.level = windowLevel
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false

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
        updateWindowCornerMask(window)

        errorHubWindow = window
    }

    func showErrorHubWindow(animated: Bool = true) {
        guard let window = errorHubWindow else {
            setupErrorHubWindow()
            showErrorHubWindow(animated: animated)
            return
        }
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }

        SoundEffectManager.shared.playWindowOpen(feature: "errorhub")

        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hideErrorHubWindow() {
        guard let window = errorHubWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        SoundEffectManager.shared.playWindowClose(feature: "errorhub")

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            guard let self, let window,
                  self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
            window.orderOut(nil)
        }
    }

    @objc func toggleErrorHubWindow() {
        guard let window = errorHubWindow else {
            setupErrorHubWindow()
            showErrorHubWindow(animated: true)
            return
        }

        if windowTargetIsVisible(window) {
            hideErrorHubWindow()
        } else {
            showErrorHubWindow(animated: true)
        }
    }
    
    @objc func showErrorHubFromNotification(_ notification: Notification) {
        guard PermissionCenterService.shared.isGateUnlocked else {
            showPermissionGateWindow()
            return
        }
        showErrorHubWindow(animated: true)
    }

    // MARK: - Fan Control Window

    private func setupFanControlWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = featureWindowSize(.fanControl, zoom: zoom)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureFeatureWindow(window, kind: .fanControl, zoom: zoom)

        window.level = windowLevel
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false

        if let main = mainWindow {
            let mainFrame = main.frame
            let offset: CGFloat = 30
            window.setFrameOrigin(NSPoint(x: mainFrame.minX + offset, y: mainFrame.minY + offset))
        } else if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2 + 30
            let y = screenFrame.midY - size.height / 2 + 30
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let rootView = FanControlWindowView(onClose: { [weak self] in
            self?.hideFanControlWindow()
        })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .overlay(WindowResizeHandles())

        window.contentView = NSHostingView(rootView: rootView)
        updateWindowCornerMask(window)

        fanControlWindow = window
    }

    func showFanControlWindow(animated: Bool = true) {
        guard let window = fanControlWindow else {
            setupFanControlWindow()
            showFanControlWindow(animated: animated)
            return
        }
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }

        SoundEffectManager.shared.playWindowOpen(feature: "fancontrol")

        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hideFanControlWindow() {
        guard let window = fanControlWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        SoundEffectManager.shared.playWindowClose(feature: "fancontrol")
        NotificationCenter.default.post(name: .fanControlWindowWillHide, object: nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            guard let self, let window,
                  self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
            window.orderOut(nil)
        }
    }

    @objc func toggleFanControlWindow() {
        guard let window = fanControlWindow else {
            setupFanControlWindow()
            showFanControlWindow(animated: true)
            return
        }

        if windowTargetIsVisible(window) {
            hideFanControlWindow()
        } else {
            showFanControlWindow(animated: true)
        }
    }

    // MARK: - Activity Monitor Window

    private func setupActivityMonitorWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let size = featureWindowSize(.activityMonitor, zoom: zoom, margin: 80, screen: screen)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureFeatureWindow(window, kind: .activityMonitor, zoom: zoom)

        window.level = windowLevel
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false

        let x = screenFrame.midX - size.width / 2
        let y = screenFrame.midY - size.height / 2
        window.setFrameOrigin(NSPoint(x: x, y: y))

        let rootView = ActivityMonitorWindowView(onClose: { [weak self] in
            self?.hideActivityMonitorWindow()
        })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .overlay(WindowResizeHandles())

        window.contentView = NSHostingView(rootView: rootView)
        updateWindowCornerMask(window)

        activityMonitorWindow = window
    }

    func showActivityMonitorWindow(animated: Bool = true) {
        guard let window = activityMonitorWindow else {
            setupActivityMonitorWindow()
            guard activityMonitorWindow != nil else { return }
            showActivityMonitorWindow(animated: animated)
            return
        }
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }

        SoundEffectManager.shared.playWindowOpen(feature: "activitymonitor")
        NotificationCenter.default.post(name: .activityMonitorWindowDidShow, object: nil)

        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hideActivityMonitorWindow() {
        guard let window = activityMonitorWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        SoundEffectManager.shared.playWindowClose(feature: "activitymonitor")
        NotificationCenter.default.post(name: .activityMonitorWindowWillHide, object: nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            guard let self, let window,
                  self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
            window.orderOut(nil)
        }
    }

    @objc func toggleActivityMonitorWindow() {
        guard let window = activityMonitorWindow else {
            setupActivityMonitorWindow()
            showActivityMonitorWindow(animated: true)
            return
        }

        if windowTargetIsVisible(window) {
            hideActivityMonitorWindow()
        } else {
            showActivityMonitorWindow(animated: true)
        }
    }

    // MARK: - Permission Gate Window

    private func setupPermissionGateWindow() {
        let zoom = CGFloat(PreferencesManager.shared.preferences.windowZoomScale)
        let size = constrainedWindowSize(
            base: NSSize(width: 860, height: 680),
            zoom: zoom,
            margin: 60
        )
        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.minimumWindowSize = NSSize(width: 680 * zoom, height: 520 * zoom)
        window.level = .floating
        window.backgroundColor = .black
        window.hasShadow = true
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.contentView = NSHostingView(rootView: PermissionGateView {
            NSApp.terminate(nil)
        })
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 14 * zoom
        window.contentView?.layer?.masksToBounds = true
        centerWindowOnScreen(window)
        permissionGateWindow = window
    }

    private func showPermissionGateWindow() {
        guard let window = permissionGateWindow else {
            setupPermissionGateWindow()
            showPermissionGateWindow()
            return
        }
        PermissionCenterService.shared.startLiveMonitoring()
        NSApp.activate(ignoringOtherApps: true)
        window.alphaValue = targetWindowAlpha
        window.makeKeyAndOrderFront(nil)
    }

    private func hidePermissionGateWindow() {
        PermissionCenterService.shared.stopLiveMonitoring()
        permissionGateWindow?.orderOut(nil)
    }

    private func hideGatedWindows() {
        let windows = [
            mainWindow, preflightWindow, destinTabWindow, superSwitchWindow, ghostProtocolWindow,
            browserBypasserWindow, assessPrepHackWindow, settingsWindow,
            wallpaperBrowserWindow, hackerDesktopWindow, clipoWindow, errorHubWindow,
            fanControlWindow, activityMonitorWindow, permissionCenterWindow, fakeLockWindow,
        ]
        for window in windows.compactMap({ $0 }) {
            _ = windowTransitions.begin(
                for: ObjectIdentifier(window),
                targetVisible: false,
                currentVisible: window.isVisible && window.alphaValue > 0
            )
            window.orderOut(nil)
        }
    }

    // MARK: - Permission Center Window

    private func setupPermissionCenterWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let size = featureWindowSize(.permissionCenter, zoom: zoom, margin: 80, screen: screen)

        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureFeatureWindow(window, kind: .permissionCenter, zoom: zoom)

        window.level = windowLevel
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false

        let x = screenFrame.midX - size.width / 2
        let y = screenFrame.midY - size.height / 2
        window.setFrameOrigin(NSPoint(x: x, y: y))

        let rootView = PermissionCenterWindowView(onClose: { [weak self] in
            self?.hidePermissionCenterWindow()
        })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .overlay(WindowResizeHandles())

        window.contentView = NSHostingView(rootView: rootView)
        updateWindowCornerMask(window)

        permissionCenterWindow = window
    }

    func showPermissionCenterWindow(animated: Bool = true) {
        guard let window = permissionCenterWindow else {
            setupPermissionCenterWindow()
            guard permissionCenterWindow != nil else { return }
            showPermissionCenterWindow(animated: animated)
            return
        }
        PermissionCenterService.shared.startLiveMonitoring()
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }

        SoundEffectManager.shared.playWindowOpen(feature: "permissioncenter")

        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
        NotificationCenter.default.post(name: .permissionCenterWindowDidShow, object: nil)
    }

    func hidePermissionCenterWindow() {
        PermissionCenterService.shared.stopLiveMonitoring()
        guard let window = permissionCenterWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        SoundEffectManager.shared.playWindowClose(feature: "permissioncenter")

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            guard let self, let window,
                  self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
            window.orderOut(nil)
        }
    }

    @objc func togglePermissionCenterWindow() {
        guard let window = permissionCenterWindow else {
            setupPermissionCenterWindow()
            showPermissionCenterWindow(animated: true)
            return
        }

        if windowTargetIsVisible(window) {
            hidePermissionCenterWindow()
        } else {
            showPermissionCenterWindow(animated: true)
        }
    }

    // MARK: - Fake Lock Window

    private func setupFakeLockWindow() {
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let size = featureWindowSize(.fakeLock, zoom: zoom, margin: 80, screen: NSScreen.main)
        let window = DraggableWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configureFeatureWindow(window, kind: .fakeLock, zoom: zoom)
        window.level = windowLevel
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.isOpaque = false

        if let mainWindow {
            window.setFrameOrigin(NSPoint(
                x: mainWindow.frame.midX - size.width / 2,
                y: mainWindow.frame.midY - size.height / 2
            ))
        } else if let screen = NSScreen.main {
            window.setFrameOrigin(NSPoint(
                x: screen.visibleFrame.midX - size.width / 2,
                y: screen.visibleFrame.midY - size.height / 2
            ))
        }
        constrainWindowToVisibleScreen(window)

        let rootView = FakeLockWindowView(onClose: { [weak self] in
            self?.hideFakeLockWindow()
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .overlay(WindowResizeHandles())
        window.contentView = NSHostingView(rootView: rootView)
        updateWindowCornerMask(window)
        fakeLockWindow = window
    }

    func showFakeLockWindow(animated: Bool = true) {
        guard let window = fakeLockWindow else {
            setupFakeLockWindow()
            showFakeLockWindow(animated: animated)
            return
        }
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }
        SoundEffectManager.shared.playWindowOpen(feature: "fakelock")
        if animated && Anim.enabled {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = targetWindowAlpha
            }
        } else {
            window.alphaValue = targetWindowAlpha
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hideFakeLockWindow() {
        guard let window = fakeLockWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        SoundEffectManager.shared.playWindowClose(feature: "fakelock")
        guard Anim.enabled else {
            window.alphaValue = 0
            window.orderOut(nil)
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            context.timingFunction = .init(name: .easeIn)
            window.animator().alphaValue = 0
        } completionHandler: { [weak self, weak window] in
            guard let self, let window,
                  self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
            window.orderOut(nil)
        }
    }

    @objc func toggleFakeLockWindow() {
        guard let window = fakeLockWindow else {
            setupFakeLockWindow()
            showFakeLockWindow(animated: true)
            return
        }
        windowTargetIsVisible(window) ? hideFakeLockWindow() : showFakeLockWindow(animated: true)
    }

    private func updateMainWindowSize() {
        guard let window = mainWindow else { return }
        let prefs = PreferencesManager.shared.preferences
        let zoom = CGFloat(prefs.windowZoomScale)
        let newSize = constrainedWindowSize(
            base: NSSize(
                width: prefs.panelWidth,
                height: min(prefs.panelMaxHeight, CGFloat(prefs.maxTabsInPopover) * CGFloat(prefs.rowHeight) + 120)
            ),
            zoom: zoom,
            screen: window.screen
        )
        window.setContentSize(newSize)
    }

    private func constrainedWindowSize(
        base: NSSize,
        zoom: CGFloat,
        margin: CGFloat = 40,
        screen: NSScreen? = nil
    ) -> NSSize {
        let requested = NSSize(width: base.width * zoom, height: base.height * zoom)
        guard let visibleFrame = (screen ?? NSScreen.main ?? NSScreen.screens.first)?.visibleFrame else {
            return requested
        }
        return NSSize(
            width: min(requested.width, max(1, visibleFrame.width - margin)),
            height: min(requested.height, max(1, visibleFrame.height - margin))
        )
    }

    private func featureWindowSize(
        _ kind: FeatureWindowKind,
        zoom: CGFloat,
        margin: CGFloat = 40,
        screen: NSScreen? = nil
    ) -> NSSize {
        let layout = FeatureWindowLayoutPolicy.layout(for: kind)
        return constrainedWindowSize(
            base: NSSize(width: layout.defaultWidth, height: layout.defaultHeight),
            zoom: zoom,
            margin: margin,
            screen: screen
        )
    }

    private func configureFeatureWindow(
        _ window: DraggableWindow,
        kind: FeatureWindowKind,
        zoom: CGFloat
    ) {
        let layout = FeatureWindowLayoutPolicy.layout(for: kind)
        window.minimumWindowSize = NSSize(
            width: layout.minimumWidth * zoom,
            height: layout.minimumHeight * zoom
        )
    }

    private func constrainWindowToVisibleScreen(_ window: NSWindow) {
        guard let visibleFrame = (window.screen ?? NSScreen.main ?? NSScreen.screens.first)?.visibleFrame else { return }
        let frame = window.frame
        let x = min(max(frame.minX, visibleFrame.minX), visibleFrame.maxX - frame.width)
        let y = min(max(frame.minY, visibleFrame.minY), visibleFrame.maxY - frame.height)
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func showMainWindow(animated: Bool = false) {
        guard PermissionCenterService.shared.isGateUnlocked else {
            showPermissionGateWindow()
            return
        }
        guard let window = mainWindow else { return }
        guard beginWindowTransition(window, targetVisible: true) != nil else { return }

        // Status-item and global-hotkey actions do not necessarily activate an accessory app.
        // Activate first so a normal-level panel is not ordered behind the current application.
        NSApp.activate(ignoringOtherApps: true)

        // Center only on first show; respect user-dragged position afterwards
        if !PreferencesManager.shared.preferences.rememberWindowPosition || window.frame.origin == .zero {
            centerWindowOnScreen(window)
        }

        SoundEffectManager.shared.playWindowOpen()
        NotificationCenter.default.post(name: .mainWindowDidShow, object: nil)

        let useAnimation = animated && PreferencesManager.shared.preferences.showPopoverAnimation

        if useAnimation {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
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
        guard let window = mainWindow,
              let transition = beginWindowTransition(window, targetVisible: false) else { return }
        SoundEffectManager.shared.playWindowClose()
        NotificationCenter.default.post(name: .mainWindowWillHide, object: nil)

        if PreferencesManager.shared.preferences.showPopoverAnimation {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Anim.duration
                context.timingFunction = .init(name: .easeIn)
                window.animator().alphaValue = 0
            } completionHandler: { [weak self, weak window] in
                guard let self, let window,
                      self.isCurrentWindowTransition(transition, for: window, targetVisible: false) else { return }
                window.orderOut(nil)
            }
        } else {
            window.alphaValue = 0
            window.orderOut(nil)
        }
    }

    @objc func toggleMainWindow() {
        guard PermissionCenterService.shared.isGateUnlocked else {
            showPermissionGateWindow()
            return
        }
        guard let window = mainWindow else {
            // If window doesn't exist yet, create and show it
            setupMainWindow()
            showMainWindow(animated: true)
            return
        }

        if windowTargetIsVisible(window) {
            hideMainWindow()
        } else {
            showMainWindow(animated: true)
        }
    }

    // MARK: - Window Behavior Helpers

    private func beginWindowTransition(_ window: NSWindow, targetVisible: Bool) -> UInt? {
        windowTransitions.begin(
            for: ObjectIdentifier(window),
            targetVisible: targetVisible,
            currentVisible: window.isVisible && window.alphaValue > 0
        )
    }

    private func isCurrentWindowTransition(
        _ generation: UInt,
        for window: NSWindow,
        targetVisible: Bool
    ) -> Bool {
        windowTransitions.isCurrent(
            generation,
            for: ObjectIdentifier(window),
            targetVisible: targetVisible
        )
    }

    private func windowTargetIsVisible(_ window: NSWindow) -> Bool {
        windowTransitions.targetVisibility(
            for: ObjectIdentifier(window),
            currentVisible: window.isVisible && window.alphaValue > 0
        )
    }

    private func updateWindowCornerMask(_ window: NSWindow) {
        let preferences = PreferencesManager.shared.preferences
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = WindowChromePolicy.cornerRadius(
            base: preferences.panelCornerRadius,
            zoom: preferences.windowZoomScale
        )
        window.contentView?.layer?.masksToBounds = true
    }

    private func preferencesDidChange(_ preferences: AppPreferences) {
        let previous = lastObservedPreferences
        lastObservedPreferences = preferences

        if previous.showPopoverKeyCode != preferences.showPopoverKeyCode
            || previous.showPopoverModifiers != preferences.showPopoverModifiers {
            setupShowPopoverShortcut()
        }
        if previous.menuBarIconStyle != preferences.menuBarIconStyle
            || previous.showTabCountBadge != preferences.showTabCountBadge
            || previous.enableFanControl != preferences.enableFanControl
            || previous.fanControlShowInMenuBar != preferences.fanControlShowInMenuBar
            || previous.fanControlTemperatureUnit != preferences.fanControlTemperatureUnit {
            updateStatusItemIcon()
        }
        if previous.enableFanControl != preferences.enableFanControl
            || previous.fanControlShowInMenuBar != preferences.fanControlShowInMenuBar
            || previous.fanControlUpdateInterval != preferences.fanControlUpdateInterval {
            updateStatusItemTimer()
        }
        if previous.keepWindowOnTop != preferences.keepWindowOnTop {
            updateAllWindowLevels()
        }
        if previous.closeOnClickOutside != preferences.closeOnClickOutside {
            updateClickOutsideMonitor()
        }
        if previous.windowOpacity != preferences.windowOpacity {
            updateVisibleWindowOpacity()
        }

        let mainLayoutChanged = previous.panelWidth != preferences.panelWidth
            || previous.panelMaxHeight != preferences.panelMaxHeight
            || previous.rowHeight != preferences.rowHeight
            || previous.maxTabsInPopover != preferences.maxTabsInPopover
        let zoomChanged = FeatureWindowResizePolicy.shouldApplyScale(
            previousZoom: previous.windowZoomScale,
            currentZoom: preferences.windowZoomScale
        )
        if mainLayoutChanged || zoomChanged {
            updateMainWindowSize()
        }
        if zoomChanged {
            updateAllWindowSizes(
                previousZoom: previous.windowZoomScale,
                currentZoom: preferences.windowZoomScale
            )
        }
        if zoomChanged || previous.panelCornerRadius != preferences.panelCornerRadius {
            updateAllWindowCornerMasks()
        }
        if previous.themeAccent != preferences.themeAccent {
            WidgetDataStore.shared.saveAccent(preferences.themeAccent)
            widgetAccentReloadWorkItem?.cancel()
            let workItem = DispatchWorkItem {
                WidgetDataStore.shared.reloadAllWidgets()
            }
            widgetAccentReloadWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
        }
    }

    private func updateAllWindowLevels() {
        let level = windowLevel
        mainWindow?.level = level
        preflightWindow?.level = level
        destinTabWindow?.level = level
        superSwitchWindow?.level = level
        ghostProtocolWindow?.level = level
        browserBypasserWindow?.level = level
        assessPrepHackWindow?.level = level
        settingsWindow?.level = level
        wallpaperBrowserWindow?.level = level
        hackerDesktopWindow?.level = level
        clipoWindow?.level = level
        errorHubWindow?.level = level
        fanControlWindow?.level = level
        activityMonitorWindow?.level = level
        permissionCenterWindow?.level = level
        fakeLockWindow?.level = level
    }

    private func updateVisibleWindowOpacity() {
        let windows = [
            mainWindow, preflightWindow, destinTabWindow, superSwitchWindow, ghostProtocolWindow,
            browserBypasserWindow, assessPrepHackWindow, settingsWindow,
            wallpaperBrowserWindow, hackerDesktopWindow, clipoWindow, errorHubWindow,
            fanControlWindow, activityMonitorWindow, permissionCenterWindow, fakeLockWindow,
        ]
        for window in windows.compactMap({ $0 }) where windowTargetIsVisible(window) {
            window.alphaValue = targetWindowAlpha
        }
    }

    private func updateAllWindowCornerMasks() {
        let windows = [
            mainWindow, preflightWindow, destinTabWindow, superSwitchWindow, ghostProtocolWindow,
            browserBypasserWindow, assessPrepHackWindow, settingsWindow,
            wallpaperBrowserWindow, hackerDesktopWindow, clipoWindow, errorHubWindow,
            fanControlWindow, activityMonitorWindow, permissionCenterWindow, fakeLockWindow,
        ]
        windows.compactMap { $0 }.forEach(updateWindowCornerMask)
    }

    private func updateAllWindowSizes(previousZoom: Double, currentZoom: Double) {
        guard previousZoom > 0, currentZoom > 0 else { return }
        let ratio = CGFloat(currentZoom / previousZoom)
        let windows: [(DraggableWindow?, FeatureWindowKind)] = [
            (preflightWindow as? DraggableWindow, .preflight),
            (destinTabWindow as? DraggableWindow, .destinTab),
            (superSwitchWindow as? DraggableWindow, .superSwitch),
            (ghostProtocolWindow as? DraggableWindow, .ghostProtocol),
            (browserBypasserWindow as? DraggableWindow, .browserBypasser),
            (assessPrepHackWindow as? DraggableWindow, .assessPrepHack),
            (settingsWindow as? DraggableWindow, .settings),
            (wallpaperBrowserWindow as? DraggableWindow, .wallpaper),
            (hackerDesktopWindow as? DraggableWindow, .hackerDesktop),
            (clipoWindow as? DraggableWindow, .clipo),
            (errorHubWindow as? DraggableWindow, .errorHub),
            (fanControlWindow as? DraggableWindow, .fanControl),
            (activityMonitorWindow as? DraggableWindow, .activityMonitor),
            (permissionCenterWindow as? DraggableWindow, .permissionCenter),
            (fakeLockWindow as? DraggableWindow, .fakeLock),
        ]
        for (window, kind) in windows {
            guard let window else { continue }
            configureFeatureWindow(window, kind: kind, zoom: CGFloat(currentZoom))
            let scaled = NSSize(
                width: window.contentView?.bounds.width ?? window.frame.width,
                height: window.contentView?.bounds.height ?? window.frame.height
            )
            window.setContentSize(constrainedWindowSize(
                base: NSSize(width: scaled.width * ratio, height: scaled.height * ratio),
                zoom: 1,
                screen: window.screen
            ))
            constrainWindowToVisibleScreen(window)
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
        if let statusItemFrame = statusItem.button?.window?.frame,
           statusItemFrame.contains(mouseLoc) {
            return
        }
        let windows: [(NSWindow?, () -> Void)] = [
            (mainWindow, { [weak self] in self?.hideMainWindow() }),
            (preflightWindow, { [weak self] in self?.hidePreflightWindow() }),
            (destinTabWindow, { [weak self] in self?.hideDestinTabWindow() }),
            (superSwitchWindow, { [weak self] in self?.hideSuperSwitchWindow() }),
            (ghostProtocolWindow, { [weak self] in self?.hideGhostProtocolWindow() }),
            (browserBypasserWindow, { [weak self] in self?.hideBrowserBypasserWindow() }),
            (assessPrepHackWindow, { [weak self] in self?.hideAssessPrepHackWindow() }),
            (settingsWindow, { [weak self] in self?.hideSettingsWindow() }),
            (wallpaperBrowserWindow, { [weak self] in self?.hideWallpaperBrowserWindow() }),
            (hackerDesktopWindow, { [weak self] in self?.hideHackerDesktopWindow() }),
            (clipoWindow, { [weak self] in self?.hideClipoWindow() }),
            (errorHubWindow, { [weak self] in self?.hideErrorHubWindow() }),
            (activityMonitorWindow, { [weak self] in self?.hideActivityMonitorWindow() }),
            (permissionCenterWindow, { [weak self] in self?.hidePermissionCenterWindow() }),
            (fakeLockWindow, { [weak self] in self?.hideFakeLockWindow() }),
            // FanControl is intentionally excluded: it should only close via its own close button.
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
                window.setFrame(originalFrame, display: true, animate: Anim.enabled)
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
            window.setFrame(screenFrame, display: true, animate: Anim.enabled)
            maximizedWindows.insert(id)
        }
    }

    // MARK: - Lifecycle

    private func startWidgetSnapshotSync() {
        widgetSnapshotTimer?.invalidate()
        SystemMonitor.shared.start(
            client: .widgetHost,
            interval: WidgetRefreshPolicy.hostSnapshotInterval
        )
        let timer = Timer(
            fire: Date().addingTimeInterval(WidgetRefreshPolicy.hostSnapshotInterval + 0.25),
            interval: WidgetRefreshPolicy.hostSnapshotInterval,
            repeats: true
        ) { _ in
            WidgetHostSnapshot.save()
        }
        widgetSnapshotTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func applicationWillTerminate(_ notification: Notification) {
        PermissionCenterService.shared.stopLiveMonitoring()
        permissionGateCancellable?.cancel()
        permissionGateCancellable = nil
        statusItemTimer?.invalidate()
        widgetSnapshotTimer?.invalidate()
        widgetSnapshotTimer = nil
        widgetAccentReloadWorkItem?.cancel()
        widgetAccentReloadWorkItem = nil
        SystemMonitor.shared.stop(client: .widgetHost)
        statusItemUpdateTask?.cancel()
        statusItemUpdateTask = nil
        SMCService.shared.restoreSystemFanControl()
        SMCHelperClient.shared.disconnect()
        DesktopWallpaperController.shared.hideWallpapers()
        
        // Resume any suspended proctoring processes before quitting so the
        // system is not left in a broken state.
        AssessPrepHackViewModel.shared.stopAllBypasses()
        GhostProtocolController.shared.shutdown()
        ShortcutCatalogCoordinator.shared.stop()
        ClipoService.shared.stop()
        FakeLockService.shared.stop()
        
        if let id = showPopoverCustomHotKeyID {
            ShortcutManager.shared.unregisterCustomHotKey(id: id)
        }
        if let id = panicHotKeyID {
            ShortcutManager.shared.unregisterCustomHotKey(id: id)
        }
        for id in clipoHotKeyIDs {
            ShortcutManager.shared.unregisterCustomHotKey(id: id)
        }
        clipoHotKeyIDs.removeAll()
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        ShortcutManager.shared.unregisterAllShortcuts()
        LaunchAnimationManager.shared.cancelAnimation()
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
        NotificationCenter.default.removeObserver(self)
        PreferencesManager.shared.onPreferencesChanged = nil
        if let window = mainWindow {
            window.orderOut(nil)
        }
        if let window = splashWindow {
            window.orderOut(nil)
        }
        if let window = preflightWindow {
            window.orderOut(nil)
        }
        if let window = destinTabWindow {
            window.orderOut(nil)
        }
        if let window = superSwitchWindow {
            window.orderOut(nil)
        }
        if let window = ghostProtocolWindow {
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
        if let window = clipoWindow {
            window.orderOut(nil)
        }
        if let window = errorHubWindow {
            window.orderOut(nil)
        }
        if let window = fanControlWindow {
            window.orderOut(nil)
        }
        if let window = activityMonitorWindow {
            window.orderOut(nil)
        }
        if let window = permissionCenterWindow {
            window.orderOut(nil)
        }
        if let window = permissionGateWindow {
            window.orderOut(nil)
        }
        if let window = fakeLockWindow {
            window.orderOut(nil)
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard PermissionCenterService.shared.isGateUnlocked else {
            showPermissionGateWindow()
            return
        }
        for url in urls {
            guard let bundleIdentifier = WidgetDeepLink.launchBundleIdentifier(from: url) else { continue }
            guard let applicationURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
                ErrorToastManager.shared.show(
                    title: String(localized: "widget.launch_failed"),
                    message: String(format: String(localized: "widget.app_not_found"), bundleIdentifier)
                )
                continue
            }
            NSWorkspace.shared.openApplication(
                at: applicationURL,
                configuration: NSWorkspace.OpenConfiguration()
            ) { _, error in
                guard let error else { return }
                DispatchQueue.main.async {
                    ErrorToastManager.shared.show(error: error)
                }
            }
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
    private var statusItemTimer: Timer?
    private var statusItemUpdateTask: Task<Void, Never>?
    private var statusItemRefreshGate = FanRefreshGate()

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItemIcon()

        if let button = statusItem.button {
            button.action = #selector(toggleMainWindow)
            button.target = self
        }

        updateStatusItemTimer()
    }

    private func updateStatusItemTimer() {
        statusItemTimer?.invalidate()
        statusItemTimer = nil

        let prefs = PreferencesManager.shared.preferences
        guard prefs.enableFanControl, prefs.fanControlShowInMenuBar else { return }

        let interval = FanRefreshPolicy.normalized(prefs.fanControlUpdateInterval)
        statusItemTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateStatusItemIcon()
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
        let prefs = PreferencesManager.shared.preferences
        let style = prefs.menuBarIconStyle
        let showBadge = prefs.showTabCountBadge
        let count = StorageManager.shared.loadTabs().count

        let baseImage = NSImage(
            systemSymbolName: style.systemImageName,
            accessibilityDescription: "ClassGod"
        ) ?? NSImage(size: NSSize(width: 18, height: 18))
        baseImage.isTemplate = true

        let badgeText = count > 99 ? "99+" : "\(count)"
        statusItem?.button?.image = baseImage
        statusItem?.button?.imagePosition = .imageLeading

        if prefs.enableFanControl, prefs.fanControlShowInMenuBar {
            // Read fan/temp data off the main thread and coalesce overlapping ticks.
            if statusItemRefreshGate.begin() {
                statusItemUpdateTask = Task.detached(priority: .userInitiated) { [weak self] in
                    guard let self else { return }
                    let all = SMCService.shared.readAll()
                    // Only use real hardware sensors for the menu-bar summary; estimates would be misleading.
                    let realTemps = all.sensors.filter { !$0.isEstimated }
                    let highestTemp = realTemps.map(\.value).max() ?? 0
                    let avgRPM = FanControlRouting.averageLiveRPM(in: all.fans)
                    let unit = prefs.fanControlTemperatureUnit
                    let tempStr = realTemps.isEmpty ? "--" : unit.formatted(highestTemp)
                    let rpmStr = avgRPM.map { "\(Int($0)) RPM" } ?? "-- RPM"
                    let title = " \(tempStr) / \(rpmStr)"
                    await MainActor.run {
                        defer { self.statusItemRefreshGate.end() }
                        let current = PreferencesManager.shared.preferences
                        guard current.enableFanControl, current.fanControlShowInMenuBar else { return }
                        self.statusItem?.button?.title = title
                    }
                }
            }
        } else if showBadge && count > 0 {
            statusItem?.button?.title = " \(badgeText)"
        } else {
            statusItem?.button?.title = ""
        }
        statusItem?.button?.toolTip = "ClassGod"
    }

    // MARK: - Global Shortcut

    private func setupShowPopoverShortcut() {
        let ghostProtocol = GhostProtocolController.shared
        ghostProtocol.prepareForShortcutChanges()
        defer { ghostProtocol.reconcileShortcutAfterChanges() }

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
    
    // MARK: - Panic Shortcut
    
    private func setupPanicShortcut() {
        if let id = panicHotKeyID {
            ShortcutManager.shared.unregisterCustomHotKey(id: id)
            panicHotKeyID = nil
        }
        
        // Default panic hotkey: F6 (no modifiers)
        panicHotKeyID = ShortcutManager.shared.registerCustomHotKey(
            keyCode: 0x61, // F6
            cocoaModifiers: 0
        ) {
            Task { @MainActor in
                let viewModel = AssessPrepHackViewModel.shared
                
                // Step 1: try to suspend any active proctoring process first
                if let suspendApp = viewModel.panicApps.first(where: { $0.isEnabled && $0.bypassTechnique == .processSuspend }) {
                    viewModel.executeBypass(for: suspendApp)
                } else {
                    viewModel.performProcessSuspend()
                }
                
                // Step 2: switch to a safe app
                if let app = viewModel.panicApps.first(where: { $0.isEnabled && $0.bypassTechnique == .panicSwitch }) {
                    viewModel.executeBypass(for: app)
                } else {
                    // No panic app configured; fall back to Safari
                    let safari = PanicApp(name: "Safari", bundleIdentifier: "com.apple.Safari", iconName: "safari.fill", bypassTechnique: .panicSwitch)
                    viewModel.executeBypass(for: safari)
                }
            }
        }
        
        if panicHotKeyID == nil {
            print("[AssessPrep] Warning: Failed to register panic hotkey (F6 may be in use)")
        }
    }
    
    // MARK: - Unified HotKey Handler
    
    private func setupGlobalHotKeyHandler() {
        ShortcutManager.shared.addHotKeyHandler { id in
            guard PermissionCenterService.shared.isGateUnlocked else { return }
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
    var onOpenPreflight: () -> Void
    var onOpenDestinTab: () -> Void
    var onOpenSuperSwitch: () -> Void
    var onOpenGhostProtocol: () -> Void
    var onOpenBrowserBypasser: () -> Void
    var onOpenAssessPrepHack: () -> Void
    var onOpenSettings: () -> Void
    var onOpenWallpaper: () -> Void
    var onOpenHackerDesktop: () -> Void
    var onOpenClipo: () -> Void = {}
    var onOpenFanControl: () -> Void = {}
    var onOpenErrorHub: () -> Void = {}
    var onOpenActivityMonitor: () -> Void = {}
    var onOpenPermissionCenter: () -> Void = {}
    var onOpenFakeLock: () -> Void = {}

    var body: some View {
        MenuBarView(onClose: onClose, onOpenPreflight: onOpenPreflight, onOpenDestinTab: onOpenDestinTab, onOpenSuperSwitch: onOpenSuperSwitch, onOpenGhostProtocol: onOpenGhostProtocol, onOpenBrowserBypasser: onOpenBrowserBypasser, onOpenAssessPrepHack: onOpenAssessPrepHack, onOpenSettings: onOpenSettings, onOpenWallpaper: onOpenWallpaper, onOpenHackerDesktop: onOpenHackerDesktop, onOpenClipo: onOpenClipo, onOpenFanControl: onOpenFanControl, onOpenErrorHub: onOpenErrorHub, onOpenActivityMonitor: onOpenActivityMonitor, onOpenPermissionCenter: onOpenPermissionCenter, onOpenFakeLock: onOpenFakeLock)
    }
}

struct PreflightWindowView: View {
    var onClose: () -> Void
    var onOpenDestinTab: () -> Void
    var onOpenSuperSwitch: () -> Void
    var onOpenPermissionCenter: () -> Void

    var body: some View {
        PreflightView(
            onClose: onClose,
            onOpenDestinTab: onOpenDestinTab,
            onOpenSuperSwitch: onOpenSuperSwitch,
            onOpenPermissionCenter: onOpenPermissionCenter
        )
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

// MARK: - Ghost Protocol Window View

struct GhostProtocolWindowView: View {
    var onClose: () -> Void

    var body: some View {
        GhostProtocolView(onClose: onClose)
    }
}

struct ClipoWindowView: View {
    var onClose: () -> Void

    var body: some View {
        ClipoView(onClose: onClose)
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

enum SettingsPage: Int, CaseIterable, Identifiable {
    case general
    case shortcuts
    case appearance
    case browser
    case advanced
    case fan

    var id: Int { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .general: "tab.general"
        case .shortcuts: "tab.shortcuts"
        case .appearance: "tab.appearance"
        case .browser: "tab.browser"
        case .advanced: "tab.advanced"
        case .fan: "tab.fan"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .general: String(localized: "tab.general")
        case .shortcuts: String(localized: "tab.shortcuts")
        case .appearance: String(localized: "tab.appearance")
        case .browser: String(localized: "tab.browser")
        case .advanced: String(localized: "tab.advanced")
        case .fan: String(localized: "tab.fan")
        }
    }

    var iconName: String {
        switch self {
        case .general: "gear"
        case .shortcuts: "keyboard"
        case .appearance: "paintbrush"
        case .browser: "globe"
        case .advanced: "wrench.and.screwdriver"
        case .fan: "fanblades"
        }
    }
}

struct SettingsContainerView: View {
    @State private var selectedPage = SettingsPage.general
    @ObservedObject private var prefs = PreferencesManager.shared
    var onClose: () -> Void

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        VStack(spacing: 0) {
            // Hacker title bar
            HStack(spacing: 0) {
                Button(action: {
                    onClose()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10 * zoomScale, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                        .background(Color(white: 0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("button.close"))
                .padding(.leading, 12 * zoomScale)
                
                Spacer()
                
                Text("settings.title")
                    .font(.system(size: 13 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Color.clear.frame(width: 36 * zoomScale, height: 24 * zoomScale)
            }
            .padding(.vertical, 8 * zoomScale)
            .background(Color(white: 0.03))
            
            Divider().background(Color.white.opacity(0.1))

            pageNavigation
            Divider().background(Color.white.opacity(0.08))

            settingsContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(selectedPage)
        }
        .background(Color.black)
        .tint(prefs.preferences.themeAccent.color)
        .preferredColorScheme(.dark)
        .overlay(
            RoundedRectangle(cornerRadius: 12 * zoomScale)
                .stroke(Color.white.opacity(0.12), lineWidth: 1 * zoomScale)
        )
    }

    private var pageNavigation: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4 * zoomScale) {
                ForEach(SettingsPage.allCases) { page in
                    let isSelected = selectedPage == page
                    Button {
                        selectedPage = page
                    } label: {
                        HStack(spacing: 4 * zoomScale) {
                            Image(systemName: page.iconName)
                                .font(.system(size: 9 * zoomScale, weight: .semibold))
                            Text(page.title)
                                .font(.system(size: 9 * zoomScale, weight: isSelected ? .bold : .medium, design: .monospaced))
                                .lineLimit(1)
                        }
                        .foregroundStyle(isSelected ? .black : .white.opacity(0.62))
                        .padding(.horizontal, 8 * zoomScale)
                        .frame(height: 28 * zoomScale)
                        .background(isSelected ? prefs.preferences.themeAccent.color.opacity(0.86) : Color.white.opacity(0.035))
                        .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(page.accessibilityTitle)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 8 * zoomScale)
            .padding(.vertical, 6 * zoomScale)
        }
        .background(Color(white: 0.025))
        .onChange(of: selectedPage) { _, _ in
            SoundEffectManager.shared.playFeatureSwitch()
            HapticManager.shared.generic()
        }
    }

    @ViewBuilder
    private var settingsContent: some View {
        switch selectedPage {
        case .general: GeneralSettingsView()
        case .shortcuts: ShortcutsSettingsView()
        case .appearance: AppearanceSettingsView()
        case .browser: BrowserSettingsView()
        case .advanced: AdvancedSettingsView()
        case .fan: FanControlSettingsView()
        }
    }
}

// MARK: - Activity Monitor Window View

struct ActivityMonitorWindowView: View {
    var onClose: () -> Void
    
    var body: some View {
        ActivityMonitorView(onClose: onClose)
    }
}

// MARK: - Permission Center Window View

struct PermissionCenterWindowView: View {
    var onClose: () -> Void
    
    var body: some View {
        PermissionCenterView(onClose: onClose)
    }
}

struct FakeLockWindowView: View {
    var onClose: () -> Void

    var body: some View {
        FakeLockView(onClose: onClose)
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
