//
//  BrowserBypasserViewModel.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import AppKit
import Combine

@MainActor
final class BrowserBypasserViewModel: ObservableObject {
    @Published var rules: [BypassRule] = []
    @Published var isBypassActive: Bool = false
    @Published var activeBypasses: [BypassType] = []
    @Published var detectedBrowser: String = ""
    @Published var detectedURL: String = ""
    @Published var toastMessage: String?
    @Published var showToast: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private var bypassTimer: Timer?
    private var toastWorkItem: DispatchWorkItem?
    
    // Common lockdown page patterns
    let commonPatterns: [(name: String, pattern: String)] = [
        ("Canvas Quiz", "canvas.*quiz"),
        ("Blackboard Exam", "blackboard.*exam"),
        ("Moodle Quiz", "moodle.*quiz"),
        ("Respondus LockDown", "respondus.*lockdown"),
        ("Proctorio", "proctorio"),
        ("Honorlock", "honorlock"),
        ("ExamSoft", "examsoft"),
        ("Safe Exam Browser", "safeexambrowser"),
        ("Google Forms (Locked)", "docs.google.com/forms"),
        ("Microsoft Forms", "forms.office"),
    ]
    
    init() {
        _rules = Published(initialValue: StorageManager.shared.loadBypassRules())
    }
    
    deinit {
        bypassTimer?.invalidate()
        toastWorkItem?.cancel()
    }
    
    func loadRules() {
        rules = StorageManager.shared.loadBypassRules()
    }
    
    func saveRules() {
        StorageManager.shared.saveBypassRules(rules)
    }
    
    func addRule(_ rule: BypassRule) {
        rules.append(rule)
        saveRules()
        showToast(message: String(format: String(localized: "bypass.toast.added"), rule.name))
    }
    
    func updateRule(_ rule: BypassRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
            saveRules()
            showToast(message: String(format: String(localized: "bypass.toast.updated"), rule.name))
        }
    }
    
    func deleteRule(_ rule: BypassRule) {
        rules.removeAll { $0.id == rule.id }
        saveRules()
        SoundEffectManager.shared.playTabDeleted()
    }
    
    func toggleRule(_ rule: BypassRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index].isEnabled.toggle()
            saveRules()
        }
    }
    
    // MARK: - Bypass Actions
    
    func detectLockedBrowser() -> (browser: String, url: String)? {
        // Check running browsers for lockdown pages
        let browsers = ["com.apple.Safari", "com.google.Chrome", "com.microsoft.edgemac"]
        
        for bundleID in browsers {
            if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }),
               app.isActive {
                // Try to get current URL via AppleScript
                if let url = getCurrentURL(for: bundleID) {
                    detectedBrowser = app.localizedName ?? bundleID
                    detectedURL = url
                    return (detectedBrowser, url)
                }
            }
        }
        return nil
    }
    
    private func getCurrentURL(for bundleID: String) -> String? {
        let script: String
        switch bundleID {
        case "com.apple.Safari":
            script = """
            tell application "Safari"
                if exists front document then
                    return URL of front document
                end if
            end tell
            return ""
            """
        case "com.google.Chrome":
            script = """
            tell application "Google Chrome"
                if exists active tab of front window then
                    return URL of active tab of front window
                end if
            end tell
            return ""
            """
        case "com.microsoft.edgemac":
            script = """
            tell application "Microsoft Edge"
                if exists active tab of front window then
                    return URL of active tab of front window
                end if
            end tell
            return ""
            """
        default:
            return nil
        }
        
        var errorInfo: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&errorInfo)
            if errorInfo == nil, result.stringValue?.isEmpty == false {
                return result.stringValue
            }
        }
        return nil
    }
    
    func runBypass(for type: BypassType) {
        SoundEffectManager.shared.playSwitchSuccess()
        
        switch type {
        case .exitFullscreen:
            exitFullscreen()
        case .preventFocusLoss:
            startFocusLossPrevention()
        case .allowShortcuts:
            allowShortcuts()
        case .injectScript:
            injectBypassScript()
        }
        
        activeBypasses.append(type)
        isBypassActive = true
        showToast(message: String(format: String(localized: "bypass.toast.activated"), type.displayName))
    }
    
    func stopAllBypasses() {
        bypassTimer?.invalidate()
        bypassTimer = nil
        activeBypasses.removeAll()
        isBypassActive = false
        showToast(message: String(localized: "bypass.toast.all_stopped"))
    }
    
    private func exitFullscreen() {
        // Send ESC key to exit fullscreen
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x35, keyDown: true) // ESC
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x35, keyDown: false)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        
        // Also try AppleScript to exit fullscreen for Safari
        let script = """
        tell application "System Events"
            key code 53 -- ESC key
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(nil)
        }
    }
    
    private func startFocusLossPrevention() {
        // Periodically send focus events to make the page think it's still focused
        bypassTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isBypassActive else { return }
                self.sendFakeFocusEvent()
            }
        }
    }
    
    private func sendFakeFocusEvent() {
        // Inject JavaScript to maintain visibility state
        let script = """
        tell application "Safari"
            if exists front document then
                do JavaScript "
                    Object.defineProperty(document, 'visibilityState', { value: 'visible', writable: false });
                    Object.defineProperty(document, 'hidden', { value: false, writable: false });
                    window.addEventListener('blur', function(e) { e.stopImmediatePropagation(); }, true);
                    window.dispatchEvent(new Event('focus'));
                " in front document
            end if
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(nil)
        }
    }
    
    private func allowShortcuts() {
        // System-level shortcut interception is handled by the app's existing hotkey system
        // This mainly ensures our hotkeys continue to work
        showToast(message: String(localized: "bypass.toast.shortcuts_enabled"))
    }
    
    private func injectBypassScript() {
        // Single-quoted JS to avoid double-quote escaping in AppleScript
        let bypassJS = "(function(){Element.prototype.requestFullscreen=function(){return Promise.resolve()};document.exitFullscreen=function(){return Promise.resolve()};Object.defineProperty(document,'visibilityState',{get:function(){return'visible'},configurable:false});Object.defineProperty(document,'hidden',{get:function(){return false},configurable:false});window.addEventListener('blur',function(e){e.stopImmediatePropagation()},true);window.addEventListener('visibilitychange',function(e){e.stopImmediatePropagation()},true);document.addEventListener('keydown',function(e){e.stopPropagation()},true);document.addEventListener('keyup',function(e){e.stopPropagation()},true);window.onbeforeunload=null;console.log('[BB]injected')})();"
        
        let scripts = [
            "Safari": "tell application \"Safari\" to if exists front document then do JavaScript \"" + bypassJS + "\" in front document",
            "Google Chrome": "tell application \"Google Chrome\" to if exists active tab of front window then execute active tab of front window javascript \"" + bypassJS + "\"",
            "Microsoft Edge": "tell application \"Microsoft Edge\" to if exists active tab of front window then execute active tab of front window javascript \"" + bypassJS + "\""
        ]
        
        for (_, source) in scripts {
            if let appleScript = NSAppleScript(source: source) {
                appleScript.executeAndReturnError(nil)
            }
        }
    }
    
    func showToast(message: String) {
        toastWorkItem?.cancel()
        toastMessage = message
        showToast = true
        
        let item = DispatchWorkItem { [weak self] in
            self?.showToast = false
        }
        toastWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: item)
    }
}
