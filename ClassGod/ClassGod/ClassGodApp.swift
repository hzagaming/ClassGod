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
        Settings {
            SettingsContainerView()
                .frame(minWidth: 520, minHeight: 400)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var mainWindow: NSWindow?
    var showPopoverHotKeyRef: EventHotKeyRef?

    var splashWindow: NSWindow?

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
            }

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.tabsDidChange),
                name: .classGodTabsDidChange,
                object: nil
            )

            // Phase 2: Setup main window first (hidden behind glitch windows)
            self.setupMainWindow()
            self.mainWindow?.alphaValue = 0
            self.mainWindow?.orderFront(nil)
            
            // Phase 3: Chaos glitch animation
            LaunchAnimationManager.shared.startChaosAnimation { [weak self] in
                // Phase 4: Reveal main window after all glitch windows close
                self?.showMainWindow(animated: true)
            }

            let trusted = AXIsProcessTrustedWithOptions(
                [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
            )
            if !trusted {
                // Do not force permission alert on first launch
            }
        }
    }

    // MARK: - Splash Screen

    private func showSplashScreen() {
        let window = NSWindow(
            contentRect: NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .popUpMenu
        window.backgroundColor = .black
        window.contentView = NSHostingView(rootView: SplashScreenView())
        window.makeKeyAndOrderFront(nil)
        splashWindow = window
    }

    private func closeSplashScreen() {
        splashWindow?.orderOut(nil)
        splashWindow = nil
    }

    // MARK: - Main Window

    private func setupMainWindow() {
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
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        
        // Apply corner radius to the window itself
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = prefs.panelCornerRadius
        window.contentView?.layer?.masksToBounds = true

        // Center on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2
            let y = screenFrame.midY - size.height / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let rootView = MenuBarWindowView()
            .frame(width: size.width, height: size.height)
            .background(Color.clear)

        window.contentView = NSHostingView(rootView: rootView)

        mainWindow = window
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

        SoundEffectManager.shared.playPopoverOpen()

        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.timingFunction = .init(name: .easeOut)
                window.animator().alphaValue = 1.0
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func hideMainWindow() {
        guard let window = mainWindow else { return }
        SoundEffectManager.shared.playPopoverClose()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
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
    var body: some View {
        MenuBarView()
    }
}

// MARK: - Settings Container

struct SettingsContainerView: View {
    @State private var selectedTab = 0
    @ObservedObject private var prefs = PreferencesManager.shared

    var body: some View {
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
        .padding()
        .preferredColorScheme(prefs.preferences.theme.colorScheme)
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
