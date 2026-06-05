//
//  AssessPrepHackViewModel.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import AppKit
import Combine

@MainActor
final class AssessPrepHackViewModel: ObservableObject {
    @Published var panicApps: [PanicApp] = []
    @Published var isBypassActive: Bool = false
    @Published var activeTechniques: [AssessPrepBypassTechnique] = []
    @Published var assessPrepDetected: Bool = false
    @Published var assessPrepProcessName: String = ""
    @Published var currentFrontApp: String = ""
    @Published var toastMessage: String?
    @Published var showToast: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private var bypassTimer: Timer?
    private var detectionTimer: Timer?
    private var toastWorkItem: DispatchWorkItem?
    private var targetAppForGuard: String?
    
    // Known AssessPrep process identifiers
    let knownAssessPrepIdentifiers: [String] = [
        "assessprep",
        "AssessPrep",
        "com.assessprep",
        "assessprep-helper",
        "assess-prep",
        "assessprep-proctor",
        "assessprep-browser",
    ]
    
    init() {
        loadApps()
    }
    
    deinit {
        bypassTimer?.invalidate()
        detectionTimer?.invalidate()
    }
    
    func stopDetectionTimer() {
        detectionTimer?.invalidate()
        detectionTimer = nil
    }
    
    func stopAllTimers() {
        bypassTimer?.invalidate()
        bypassTimer = nil
        stopDetectionTimer()
    }
    
    // MARK: - Persistence
    
    func loadApps() {
        panicApps = StorageManager.shared.loadPanicApps()
        if panicApps.isEmpty {
            panicApps = PanicApp.presets
            saveApps()
        }
    }
    
    func saveApps() {
        StorageManager.shared.savePanicApps(panicApps)
    }
    
    func addApp(_ app: PanicApp) {
        panicApps.append(app)
        saveApps()
        showToast(message: "Added panic app: \(app.name)")
    }
    
    func updateApp(_ app: PanicApp) {
        if let index = panicApps.firstIndex(where: { $0.id == app.id }) {
            panicApps[index] = app
            saveApps()
            showToast(message: "Updated app: \(app.name)")
        }
    }
    
    func deleteApp(_ app: PanicApp) {
        panicApps.removeAll { $0.id == app.id }
        saveApps()
        SoundEffectManager.shared.playTabDeleted()
    }
    
    func toggleApp(_ app: PanicApp) {
        if let index = panicApps.firstIndex(where: { $0.id == app.id }) {
            panicApps[index].isEnabled.toggle()
            saveApps()
        }
    }
    
    // MARK: - Detection
    
    func startDetectionTimer() {
        detectionTimer?.invalidate()
        detectionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.scanForAssessPrep()
                self?.updateFrontApp()
            }
        }
        scanForAssessPrep()
        updateFrontApp()
    }
    
    func scanForAssessPrep() {
        let runningApps = NSWorkspace.shared.runningApplications
        var found = false
        var foundName = ""
        
        for app in runningApps {
            let name = app.localizedName ?? ""
            let bundleID = app.bundleIdentifier ?? ""
            
            for identifier in knownAssessPrepIdentifiers {
                if name.lowercased().contains(identifier.lowercased()) ||
                   bundleID.lowercased().contains(identifier.lowercased()) {
                    found = true
                    foundName = name.isEmpty ? bundleID : name
                    break
                }
            }
            if found { break }
        }
        
        // Also check for common browser lockdown extensions by window title
        if !found {
            found = checkBrowserForAssessPrep()
            if found {
                foundName = "AssessPrep (Browser)"
            }
        }
        
        assessPrepDetected = found
        assessPrepProcessName = foundName
    }
    
    private func checkBrowserForAssessPrep() -> Bool {
        let script = """
        tell application "System Events"
            set windowList to {}
            try
                tell application process "Safari"
                    set windowList to name of every window
                end tell
            end try
            repeat with w in windowList
                if w contains "AssessPrep" or w contains "assessprep" or w contains "Secure Browser" then
                    return true
                end if
            end repeat
            
            set windowList to {}
            try
                tell application process "Google Chrome"
                    set windowList to name of every window
                end tell
            end try
            repeat with w in windowList
                if w contains "AssessPrep" or w contains "assessprep" or w contains "Secure Browser" then
                    return true
                end if
            end repeat
            
            return false
        end tell
        """
        
        var errorInfo: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&errorInfo)
            return result.booleanValue
        }
        return false
    }
    
    private func updateFrontApp() {
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            currentFrontApp = frontApp.localizedName ?? frontApp.bundleIdentifier ?? "Unknown"
        }
    }
    
    // MARK: - Bypass Actions
    
    func executeBypass(for app: PanicApp) {
        guard app.isEnabled else {
            showError(message: "App \(app.name) is disabled")
            return
        }
        
        SoundEffectManager.shared.playSwitchSuccess()
        
        switch app.bypassTechnique {
        case .panicSwitch:
            performPanicSwitch(to: app)
        case .focusGuard:
            startFocusGuard(targetApp: app.bundleIdentifier)
        case .screenSpoof:
            performScreenSpoof()
        case .keyboardUnlock:
            performKeyboardUnlock()
        case .processSuspend:
            performProcessSuspend()
        }
        
        if !activeTechniques.contains(app.bypassTechnique) {
            activeTechniques.append(app.bypassTechnique)
        }
        isBypassActive = true
        showToast(message: "\(app.bypassTechnique.displayName) activated")
    }
    
    func stopAllBypasses() {
        bypassTimer?.invalidate()
        bypassTimer = nil
        targetAppForGuard = nil
        activeTechniques.removeAll()
        isBypassActive = false
        showToast(message: "All bypasses stopped")
    }
    
    // MARK: - Bypass Implementations
    
    private func performPanicSwitch(to app: PanicApp) {
        // Method 1: NSWorkspace
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
        }
        
        // Method 2: AppleScript (more forceful)
        let script = """
        tell application "System Events"
            set targetApp to first application process whose bundle identifier is "\(app.bundleIdentifier)"
            set frontmost of targetApp to true
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(nil)
        }
        
        // Method 3: Also try to hide/minimize AssessPrep windows
        hideAssessPrepWindows()
    }
    
    private func startFocusGuard(targetApp: String) {
        targetAppForGuard = targetApp
        
        bypassTimer?.invalidate()
        bypassTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isBypassActive else { return }
                self.enforceFocusGuard()
            }
        }
    }
    
    private func enforceFocusGuard() {
        guard let targetBundleID = targetAppForGuard else { return }
        
        let script = """
        tell application "System Events"
            set frontApp to name of first application process whose frontmost is true
            set frontAppBundle to bundle identifier of first application process whose frontmost is true
            
            if frontAppBundle is not "\(targetBundleID)" then
                -- Check if front app is AssessPrep
                if frontApp contains "AssessPrep" or frontApp contains "assessprep" or frontApp contains "Secure Browser" then
                    -- Force switch back to target
                    set targetProc to first application process whose bundle identifier is "\(targetBundleID)"
                    set frontmost of targetProc to true
                end if
            end if
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(nil)
        }
    }
    
    private func performScreenSpoof() {
        // Inject JavaScript to spoof visibility state in all major browsers
        let spoofJS = """
        (function(){
            var origVisible = document.visibilityState;
            Object.defineProperty(document,'visibilityState',{get:function(){return'visible'},configurable:false});
            Object.defineProperty(document,'hidden',{get:function(){return false},configurable:false});
            window.addEventListener('blur',function(e){e.stopImmediatePropagation();},true);
            window.addEventListener('visibilitychange',function(e){e.stopImmediatePropagation();},true);
            document.addEventListener('mouseleave',function(e){e.stopImmediatePropagation();},true);
            document.addEventListener('mouseout',function(e){e.stopImmediatePropagation();},true);
            window.onbeforeunload=null;
            window.onblur=null;
            console.log('[APH] Screen spoof active');
        })();
        """
        
        let scripts: [String: String] = [
            "Safari": "tell application \"Safari\" to if exists front document then do JavaScript \"\(spoofJS)\" in front document",
            "Google Chrome": "tell application \"Google Chrome\" to if exists active tab of front window then execute active tab of front window javascript \"\(spoofJS)\"",
            "Microsoft Edge": "tell application \"Microsoft Edge\" to if exists active tab of front window then execute active tab of front window javascript \"\(spoofJS)\""
        ]
        
        for (_, source) in scripts {
            if let appleScript = NSAppleScript(source: source) {
                appleScript.executeAndReturnError(nil)
            }
        }
    }
    
    private func performKeyboardUnlock() {
        // Send system events to restore keyboard functionality
        // This mainly ensures our hotkeys and system shortcuts work
        let script = """
        tell application "System Events"
            -- Ensure system events accessibility is responsive
            key code 53 using {command down} -- Cmd+Escape (Force Quit dialog, then cancel)
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(nil)
        }
        
        showToast(message: "Keyboard shortcuts restored")
    }
    
    private func performProcessSuspend() {
        // Find and suspend AssessPrep process
        let script = """
        do shell script "ps aux | grep -i assessprep | grep -v grep | awk '{print $2}'"
        """
        
        var errorInfo: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&errorInfo)
            if errorInfo == nil, let pids = result.stringValue?.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
                for pid in pids where !pid.isEmpty {
                    let suspendScript = """
                    do shell script "kill -STOP \(pid)"
                    """
                    if let suspendAppleScript = NSAppleScript(source: suspendScript) {
                        suspendAppleScript.executeAndReturnError(nil)
                    }
                }
                showToast(message: "AssessPrep processes suspended")
            }
        }
    }
    
    func resumeAssessPrep() {
        let script = """
        do shell script "ps aux | grep -i assessprep | grep -v grep | awk '{print $2}'"
        """
        
        var errorInfo: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&errorInfo)
            if errorInfo == nil, let pids = result.stringValue?.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
                for pid in pids where !pid.isEmpty {
                    let resumeScript = """
                    do shell script "kill -CONT \(pid)"
                    """
                    if let resumeAppleScript = NSAppleScript(source: resumeScript) {
                        resumeAppleScript.executeAndReturnError(nil)
                    }
                }
                showToast(message: "AssessPrep processes resumed")
            }
        }
    }
    
    private func hideAssessPrepWindows() {
        let script = """
        tell application "System Events"
            try
                tell application process "Safari"
                    set visible of every window whose name contains "AssessPrep" to false
                end tell
            end try
            try
                tell application process "Google Chrome"
                    set visible of every window whose name contains "AssessPrep" to false
                end tell
            end try
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(nil)
        }
    }
    
    // MARK: - Toast
    
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
    
    func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
