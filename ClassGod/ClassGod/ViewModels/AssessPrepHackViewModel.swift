//
//  AssessPrepHackViewModel.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import AppKit
import Combine
import ApplicationServices

@MainActor
final class AssessPrepHackViewModel: ObservableObject {
    static let shared = AssessPrepHackViewModel()
    
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
    
    // Known proctoring / lockdown browser identifiers (bundle IDs and process-name keywords)
    let knownAssessPrepBundleIDs: [String] = [
        // Respondus LockDown Browser
        "com.respondus.LockDownBrowser",
        "com.respondus.LockDownBrowser.OEM",
        "com.respondus.Monitor",
        "com.respondus.lockdownbrowser",
        // Safe Exam Browser
        "org.safeexambrowser.SafeExamBrowser",
        "org.safeexambrowser.seb",
        // ExamSoft / Examplify
        "com.examsoft.softest",
        "com.examsoft.examplify",
        // Bluebook (College Board)
        "org.bluebook",
        "com.collegeboard.bluebook",
        // PSI / Pearson / Proctoring platforms
        "com.psi.bridge",
        "com.pearsonvue",
        "com.proctorio",
        // Generic helpers often seen alongside these apps
        "com.proctorio.helper",
        "com.honorlock",
    ]
    
    let knownAssessPrepNameKeywords: [String] = [
        "lockdown browser",
        "LockDown Browser",
        "respondus",
        "Respondus",
        "safe exam browser",
        "Safe Exam Browser",
        "SEB",
        "examplify",
        "Examplify",
        "examsoft",
        "ExamSoft",
        "bluebook",
        "Bluebook",
        "proctorio",
        "Proctorio",
        "honorlock",
        "Honorlock",
        "psi bridge",
        "pearson vue",
        "secure browser",
        "Secure Browser",
        "assessprep",
        "AssessPrep",
    ]
    
    init() {
        let savedApps = StorageManager.shared.loadPanicApps()
        let initialApps = savedApps.isEmpty ? PanicApp.presets : savedApps
        _panicApps = Published(initialValue: initialApps)
        if savedApps.isEmpty {
            StorageManager.shared.savePanicApps(initialApps)
        }
    }
    
    deinit {
        bypassTimer?.invalidate()
        detectionTimer?.invalidate()
        toastWorkItem?.cancel()
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
        showToast(message: String(format: String(localized: "panic.toast.added"), app.name))
    }
    
    func updateApp(_ app: PanicApp) {
        if let index = panicApps.firstIndex(where: { $0.id == app.id }) {
            panicApps[index] = app
            saveApps()
            showToast(message: String(format: String(localized: "panic.toast.updated"), app.name))
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
            
            // Exact bundle ID match first
            if knownAssessPrepBundleIDs.contains(where: { $0.compare(bundleID, options: .caseInsensitive) == .orderedSame }) {
                found = true
                foundName = name.isEmpty ? bundleID : name
                break
            }
            
            // Process-name keyword match
            let lowerName = name.lowercased()
            for keyword in knownAssessPrepNameKeywords {
                if lowerName.contains(keyword.lowercased()) {
                    found = true
                    foundName = name
                    break
                }
            }
            if found { break }
        }
        
        // Also check for lockdown browser windows in common browsers
        if !found {
            found = checkBrowserForAssessPrep()
            if found {
                foundName = "Lockdown Browser (Browser Window)"
            }
        }
        
        assessPrepDetected = found
        assessPrepProcessName = foundName
    }
    
    private func checkBrowserForAssessPrep() -> Bool {
        // Return all window titles from common browsers; Swift side decides matches.
        let script = """
        tell application "System Events"
            set allTitles to ""
            set browserNames to {"Safari", "Google Chrome", "Microsoft Edge", "Brave Browser", "Opera", "Firefox", "Arc"}
            repeat with browserName in browserNames
                try
                    tell application process browserName
                        repeat with w in (every window)
                            try
                                set allTitles to allTitles & (name of w) & "\n"
                            end try
                        end repeat
                    end tell
                end try
            end repeat
            return allTitles
        end tell
        """
        
        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return false }
        let result = appleScript.executeAndReturnError(&errorInfo)
        if let err = errorInfo {
            print("[AssessPrep] Browser check error: \(err)")
            return false
        }
        guard let titles = result.stringValue else { return false }
        let lowerTitles = titles.lowercased()
        let keywords = knownAssessPrepNameKeywords + ["lockdown", "respondus", "safe exam", "examplify", "bluebook", "proctorio", "honorlock"]
        return keywords.contains { !$0.isEmpty && lowerTitles.contains($0.lowercased()) }
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
        
        guard checkAccessibilityPermission() else {
            _ = checkAccessibilityPermission(prompt: true)
            showError(message: "Accessibility permission required. Please enable ClassGod in System Settings > Privacy & Security > Accessibility, then try again.")
            return
        }
        
        var success = false
        switch app.bypassTechnique {
        case .panicSwitch:
            success = performPanicSwitch(to: app)
        case .focusGuard:
            success = startFocusGuard(targetApp: app.bundleIdentifier)
        case .screenSpoof:
            success = performScreenSpoof()
        case .keyboardUnlock:
            success = performKeyboardUnlock()
        case .processSuspend:
            success = performProcessSuspend()
        }
        
        if success {
            SoundEffectManager.shared.playSwitchSuccess()
            if !activeTechniques.contains(app.bypassTechnique) {
                activeTechniques.append(app.bypassTechnique)
            }
            isBypassActive = true
            showToast(message: String(format: String(localized: "panic.toast.technique_activated"), app.bypassTechnique.displayName))
        } else {
            SoundEffectManager.shared.play(.shortcutConflict)
            showError(message: "\(app.bypassTechnique.displayName) failed")
        }
    }
    
    func stopAllBypasses() {
        bypassTimer?.invalidate()
        bypassTimer = nil
        targetAppForGuard = nil
        
        // Resume any suspended proctoring processes
        resumeAssessPrep()
        
        activeTechniques.removeAll()
        isBypassActive = false
        showToast(message: String(localized: "panic.toast.all_stopped"))
    }
    
    private func checkAccessibilityPermission(prompt: Bool = false) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // MARK: - Bypass Implementations
    
    private func performPanicSwitch(to app: PanicApp) -> Bool {
        // Launch target app
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
        }
        
        let safeBundleID = app.bundleIdentifier
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\"\"")
        let script = """
        tell application "System Events"
            try
                set targetApp to first application process whose bundle identifier is "\(safeBundleID)"
                set frontmost of targetApp to true
                -- Also try a stronger activate via the application itself
                tell application id "\(safeBundleID)"
                    activate
                end tell
                return true
            on error
                return false
            end try
        end tell
        """
        
        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return false }
        let result = appleScript.executeAndReturnError(&errorInfo)
        let frontmostOK = result.booleanValue && errorInfo == nil
        
        // Also hide any visible proctoring windows
        hideAssessPrepWindows()
        return frontmostOK
    }
    
    @discardableResult
    private func startFocusGuard(targetApp: String) -> Bool {
        targetAppForGuard = targetApp
        
        bypassTimer?.invalidate()
        bypassTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isBypassActive else { return }
                self.enforceFocusGuard()
            }
        }
        return true
    }
    
    private func enforceFocusGuard() {
        guard let targetBundleID = targetAppForGuard else { return }
        
        let safeTarget = targetBundleID
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\"\"")
        let script = """
        tell application "System Events"
            try
                set frontProc to first application process whose frontmost is true
                set frontName to name of frontProc
                set frontBundle to bundle identifier of frontProc
                
                set isProctor to false
                set proctorNames to {"LockDown Browser", "Respondus", "Safe Exam Browser", "SEB", "Examplify", "ExamSoft", "Bluebook", "Proctorio", "Honorlock", "AssessPrep", "Secure Browser", "lockdown", "respondus", "safe exam"}
                repeat with pn in proctorNames
                    if frontName contains pn then
                        set isProctor to true
                        exit repeat
                    end if
                end repeat
                
                if not isProctor then
                    return false
                end if
                
                if frontBundle is "\(safeTarget)" then
                    return false
                end if
                
                set targetProc to first application process whose bundle identifier is "\(safeTarget)"
                set frontmost of targetProc to true
                return true
            on error
                return false
            end try
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(nil)
        }
    }
    
    private func performScreenSpoof() -> Bool {
        // More robust JS payload wrapped in try/catch and with broader spoofing
        let spoofJS = """
        (function(){
            try{
                Object.defineProperty(document,'visibilityState',{get:function(){return'visible'},configurable:true});
                Object.defineProperty(document,'hidden',{get:function(){return false},configurable:true});
                window.addEventListener('blur',function(e){try{e.stopImmediatePropagation();}catch(_){}},true);
                window.addEventListener('visibilitychange',function(e){try{e.stopImmediatePropagation();}catch(_){}},true);
                document.addEventListener('mouseleave',function(e){try{e.stopImmediatePropagation();}catch(_){}},true);
                document.addEventListener('mouseout',function(e){try{e.stopImmediatePropagation();}catch(_){}},true);
                document.hasFocus=function(){return true;};
                window.onbeforeunload=null;
                window.onblur=null;
                document.onvisibilitychange=null;
                var perf=window.performance||{};
                if(perf.now){var base=perf.now();var orig=perf.now.bind(perf);perf.now=function(){return base;};}
                console.log('[APH] Screen spoof active');
            }catch(e){ console.log('[APH] Spoof error: '+e); }
        })();
        """
        
        let escapedJS = spoofJS
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
        let scripts: [String: String] = [
            "Safari": "tell application \"Safari\" to if exists front document then do JavaScript \"\(escapedJS)\" in front document",
            "Google Chrome": "tell application \"Google Chrome\" to if exists active tab of front window then execute active tab of front window javascript \"\(escapedJS)\"",
            "Microsoft Edge": "tell application \"Microsoft Edge\" to if exists active tab of front window then execute active tab of front window javascript \"\(escapedJS)\"",
            "Brave Browser": "tell application \"Brave Browser\" to if exists active tab of front window then execute active tab of front window javascript \"\(escapedJS)\""
        ]
        
        var anySuccess = false
        for (_, source) in scripts {
            guard let appleScript = NSAppleScript(source: source) else { continue }
            var errorInfo: NSDictionary?
            _ = appleScript.executeAndReturnError(&errorInfo)
            if errorInfo == nil { anySuccess = true }
        }
        return anySuccess
    }
    
    private func performKeyboardUnlock() -> Bool {
        // Open Force Quit dialog (Cmd+Option+Esc) and then cancel it with Escape.
        // This briefly breaks a lockdown app's event-tap hold in some cases.
        let script = """
        tell application "System Events"
            key code 53 using {command down, option down}
            delay 0.2
            key code 53
        end tell
        """
        
        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return false }
        _ = appleScript.executeAndReturnError(&errorInfo)
        return errorInfo == nil
    }
    
    @discardableResult
    func performProcessSuspend() -> Bool {
        let pids = matchingProctorPIDs()
        guard !pids.isEmpty else { return false }
        
        var suspended = 0
        for pid in pids {
            let script = """
            do shell script "kill -STOP \(pid)"
            """
            if let appleScript = NSAppleScript(source: script) {
                var err: NSDictionary?
                _ = appleScript.executeAndReturnError(&err)
                if err == nil { suspended += 1 }
            }
        }
        return suspended > 0
    }
    
    @discardableResult
    func resumeAssessPrep() -> Bool {
        let pids = matchingProctorPIDs()
        guard !pids.isEmpty else { return false }
        
        var resumed = 0
        for pid in pids {
            let script = """
            do shell script "kill -CONT \(pid)"
            """
            if let appleScript = NSAppleScript(source: script) {
                var err: NSDictionary?
                _ = appleScript.executeAndReturnError(&err)
                if err == nil { resumed += 1 }
            }
        }
        return resumed > 0
    }
    
    private func matchingProctorPIDs() -> [Int] {
        let ownPID = ProcessInfo.processInfo.processIdentifier
        // Use `ps -c -eo pid=,comm=` to get only PID and command name (no args).
        // This avoids false positives from innocent processes whose command-line
        // arguments happen to contain proctoring keywords.
        let script = """
        do shell script "ps -c -eo pid=,comm="
        """
        
        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return [] }
        let result = appleScript.executeAndReturnError(&errorInfo)
        guard errorInfo == nil, let output = result.stringValue else { return [] }
        
        let keywords = knownAssessPrepNameKeywords.map { $0.lowercased() }
        var matches: [Int] = []
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            // Format: "<pid> <comm>" with variable whitespace
            let components = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            guard components.count == 2,
                  let pid = Int(components[0]),
                  pid != ownPID else { continue }
            let comm = String(components[1]).lowercased()
            if keywords.contains(where: { !$0.isEmpty && comm.contains($0) }) {
                matches.append(pid)
            }
        }
        return matches
    }
    
    @discardableResult
    private func hideAssessPrepWindows() -> Bool {
        // Only hide windows of known proctoring apps, plus browser windows whose
        // titles contain proctoring keywords. Previously this hid ALL browser
        // windows, which was far too broad.
        let proctorProcessNames = ["LockDown Browser", "Respondus", "Safe Exam Browser", "SEB", "Examplify", "ExamSoft", "Bluebook", "Proctorio", "Honorlock", "AssessPrep"]
        let browserNames = ["Safari", "Google Chrome", "Microsoft Edge", "Brave Browser", "Firefox", "Arc", "Opera"]
        let windowKeywords = ["LockDown Browser", "Respondus", "Safe Exam Browser", "SEB", "Examplify", "ExamSoft", "Bluebook", "Proctorio", "Honorlock", "AssessPrep", "Secure Browser"]
        
        let proctorList = proctorProcessNames
            .map { "\"\($0.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\"\""))\"" }
            .joined(separator: ", ")
        let browserList = browserNames
            .map { "\"\($0.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\"\""))\"" }
            .joined(separator: ", ")
        let keywordList = windowKeywords
            .map { "\"\($0.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\"\""))\"" }
            .joined(separator: ", ")
        
        let script = """
        tell application "System Events"
            try
                -- Hide windows of proctoring app processes
                set proctorNames to {\(proctorList)}
                repeat with proc in (every application process)
                    try
                        set procName to name of proc
                        repeat with targetName in proctorNames
                            if procName contains targetName then
                                set visible of every window of proc to false
                                exit repeat
                            end if
                        end repeat
                    end try
                end repeat
                
                -- Hide browser windows whose titles look like a lockdown session
                set browserNames to {\(browserList)}
                set windowKeywords to {\(keywordList)}
                repeat with browserName in browserNames
                    try
                        tell application process browserName
                            repeat with w in (every window)
                                try
                                    set wName to name of w
                                    repeat with keyword in windowKeywords
                                        if wName contains keyword then
                                            set visible of w to false
                                            exit repeat
                                        end if
                                    end repeat
                                end try
                            end repeat
                        end tell
                    end try
                end repeat
                
                return true
            on error
                return false
            end try
        end tell
        """
        
        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return false }
        let result = appleScript.executeAndReturnError(&errorInfo)
        return result.booleanValue && errorInfo == nil
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
