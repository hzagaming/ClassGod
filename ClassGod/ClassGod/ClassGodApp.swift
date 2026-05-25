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
    var popover: NSPopover!
    var showPopoverHotKeyRef: EventHotKeyRef?

    var splashWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        showSplashScreen()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.closeSplashScreen()
            self.setupStatusItem()
            self.setupPopover()
            self.setupShowPopoverShortcut()

            PreferencesManager.shared.onPreferencesChanged = { [weak self] _ in
                self?.setupShowPopoverShortcut()
                self?.updateStatusItemIcon()
                self?.updatePopoverSize()
            }
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.tabsDidChange),
                name: .classGodTabsDidChange,
                object: nil
            )

            let trusted = AXIsProcessTrustedWithOptions(
                [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
            )
            if !trusted {
                // Do not force permission alert on first launch
                // User can still use the UI and will be reminded in the panel
            }

            if PreferencesManager.shared.preferences.showPopoverOnLaunch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.togglePopover()
                }
            }
        }
    }

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

    func applicationWillTerminate(_ notification: Notification) {
        if let ref = showPopoverHotKeyRef {
            UnregisterEventHotKey(ref)
        }
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        uninstallGlobalEventHandler()
        ShortcutManager.shared.unregisterAllShortcuts()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        togglePopover()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    private func showPermissionReminder() {
        let alert = NSAlert()
        alert.messageText = String(localized: "permission.alert.title")
        alert.informativeText = String(localized: "permission.alert.message")
        alert.alertStyle = .informational
        alert.addButton(withTitle: String(localized: "button.go_settings"))
        alert.addButton(withTitle: String(localized: "button.later"))

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItemIcon()

        if let button = statusItem.button {
            button.action = #selector(togglePopover)
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
        
        if showBadge && count > 0 {
            let badgeText = count > 99 ? "99+" : "\(count)"
            let imageSize = NSSize(width: 24, height: 24)
            let composited = NSImage(size: imageSize)
            
            composited.lockFocus()
            
            // Draw base icon
            baseImage.draw(in: NSRect(x: 0, y: 0, width: 18, height: 18))
            
            // Draw red badge
            let badgeSize: CGFloat = badgeText.count > 2 ? 14 : 12
            let badgeRect = NSRect(x: 18 - badgeSize / 2, y: 18 - badgeSize / 2, width: badgeSize, height: badgeSize)
            let path = NSBezierPath(ovalIn: badgeRect)
            NSColor.systemRed.setFill()
            path.fill()
            
            // Draw badge text
            let font = NSFont.systemFont(ofSize: badgeText.count > 2 ? 7 : 8, weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white
            ]
            let textSize = badgeText.size(withAttributes: attrs)
            let textRect = NSRect(
                x: badgeRect.midX - textSize.width / 2,
                y: badgeRect.midY - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            badgeText.draw(in: textRect, withAttributes: attrs)
            
            composited.unlockFocus()
            composited.isTemplate = false
            statusItem?.button?.image = composited
        } else {
            statusItem?.button?.image = baseImage
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        updatePopoverSize()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
        popover.animates = true
    }

    private func updatePopoverSize() {
        let prefs = PreferencesManager.shared.preferences
        popover?.contentSize = NSSize(
            width: prefs.panelWidth,
            height: min(prefs.panelMaxHeight, CGFloat(prefs.maxTabsInPopover) * CGFloat(prefs.rowHeight) + 120)
        )
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            SoundEffectManager.shared.playPopoverClose()
            popover.performClose(nil)
        } else {
            SoundEffectManager.shared.playPopoverOpen()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

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

// Global event handler installed once
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
                (NSApp.delegate as? AppDelegate)?.togglePopover()
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
