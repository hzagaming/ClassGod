//
//  BrowserSwitcher.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import AppKit

final class BrowserSwitcher {
    static let shared = BrowserSwitcher()
    
    private init() {}
    
    /// AppleScript strings use doubled quotes for escaping: " → ""
    private func appleScriptEscape(_ string: String) -> String {
        return string.replacingOccurrences(of: "\"", with: "\"\"")
    }
    
    /// Extract host from URL in Swift (avoids shell injection in AppleScript)
    private func extractHost(from urlString: String) -> String {
        guard let url = URL(string: urlString), let host = url.host else {
            return urlString
        }
        return host
    }
    
    /// Check if browser is currently running
    private func isBrowserRunning(_ browser: BrowserType) -> Bool {
        return !NSRunningApplication.runningApplications(withBundleIdentifier: browser.bundleIdentifier).isEmpty
    }
    
    /// Switch to the given tab. Behavior depends on user preferences.
    func switchToTab(_ tab: BrowserTab, completion: ((Bool, String) -> Void)? = nil) {
        let prefs = PreferencesManager.shared.preferences
        let safeURL = appleScriptEscape(tab.url)
        let isRunning = isBrowserRunning(tab.browser)
        
        // If browser not running, respect user preference
        if !isRunning {
            switch prefs.browserNotRunningBehavior {
            case .doNothing:
                completion?(false, String(format: String(localized: "error.browser_not_running"), tab.browser.displayName))
                return
            case .launchOnly:
                launchBrowser(tab.browser, completion: completion)
                return
            case .launchAndOpen:
                break // fall through to open URL
            }
        }
        
        // If "always new tab" is selected, skip search and directly open URL
        if prefs.switchBehavior == .alwaysNewTab {
            openURLDirectly(tab: tab, url: safeURL, completion: completion)
            return
        }
        
        // Otherwise try to find existing tab first
        let scriptSource: String
        switch tab.browser {
        case .safari:
            scriptSource = buildSafariSwitchScript(url: safeURL, precision: prefs.urlMatchPrecision)
        case .chrome:
            scriptSource = buildChromeSwitchScript(url: safeURL, precision: prefs.urlMatchPrecision)
        case .edge:
            scriptSource = buildEdgeSwitchScript(url: safeURL, precision: prefs.urlMatchPrecision)
        }
        
        executeAppleScript(scriptSource) { result, errorMsg in
            if errorMsg != nil {
                // Fallback: try to open URL directly
                self.openURLDirectly(tab: tab, url: safeURL, completion: completion)
                return
            }
            
            let output = result?.stringValue ?? ""
            if output == "NOT_FOUND" {
                self.openURLDirectly(tab: tab, url: safeURL, completion: completion)
            } else {
                completion?(true, String(format: String(localized: "toast.switched_browser"), tab.browser.displayName))
            }
        }
    }
    
    private func launchBrowser(_ browser: BrowserType, completion: ((Bool, String) -> Void)?) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleIdentifier) else {
            completion?(false, String(format: String(localized: "error.browser_not_found"), browser.displayName))
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { app, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion?(false, String(format: String(localized: "error.launch_failed"), browser.displayName, error.localizedDescription))
                } else {
                    completion?(true, String(format: String(localized: "toast.launched"), browser.displayName))
                }
            }
        }
    }
    
    private func openURLDirectly(tab: BrowserTab, url: String, completion: ((Bool, String) -> Void)? = nil) {
        let scriptSource: String
        switch tab.browser {
        case .safari:
            scriptSource = buildSafariOpenScript(url: url)
        case .chrome:
            scriptSource = buildChromeOpenScript(url: url)
        case .edge:
            scriptSource = buildEdgeOpenScript(url: url)
        }
        
        executeAppleScript(scriptSource) { _, errorMsg in
            if let msg = errorMsg {
                completion?(false, msg)
            } else {
                completion?(true, String(format: String(localized: "toast.opened_url"), tab.browser.displayName))
            }
        }
    }
    
    private func executeAppleScript(_ source: String, completion: @escaping (NSAppleEventDescriptor?, String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var errorInfo: NSDictionary?
            guard let appleScript = NSAppleScript(source: source) else {
                DispatchQueue.main.async {
                    completion(nil, String(localized: "error.create_script"))
                }
                return
            }
            
            let result = appleScript.executeAndReturnError(&errorInfo)
            
            DispatchQueue.main.async {
                if let error = errorInfo {
                    let msg = error["NSAppleScriptErrorMessage"] as? String ?? String(localized: "error.unknown")
                    completion(nil, msg)
                } else {
                    completion(result, nil)
                }
            }
        }
    }
    
    // MARK: - Switch Scripts (find existing tab)
    
    private func buildSafariSwitchScript(url: String, precision: URLMatchPrecision) -> String {
        let matchCondition: String
        switch precision {
        case .exact:
            matchCondition = "tabURL = targetURL"
        case .prefix:
            matchCondition = "tabURL starts with targetURL or targetURL starts with tabURL"
        case .hostOnly:
            let host = extractHost(from: url)
            let safeHost = appleScriptEscape(host)
            matchCondition = "tabURL contains \"\(safeHost)\""
        }
        
        return """
        tell application "Safari"
            activate
            set targetURL to "\(url)"
            repeat with w in windows
                repeat with t in tabs of w
                    set tabURL to URL of t
                    if \(matchCondition) then
                        set current tab of w to t
                        set index of w to 1
                        return "FOUND"
                    end if
                end repeat
            end repeat
            return "NOT_FOUND"
        end tell
        """
    }
    
    private func buildChromeSwitchScript(url: String, precision: URLMatchPrecision) -> String {
        let matchCondition: String
        switch precision {
        case .exact:
            matchCondition = "tabURL = targetURL"
        case .prefix:
            matchCondition = "tabURL starts with targetURL or targetURL starts with tabURL"
        case .hostOnly:
            let host = extractHost(from: url)
            let safeHost = appleScriptEscape(host)
            matchCondition = "tabURL contains \"\(safeHost)\""
        }
        
        return """
        tell application "Google Chrome"
            activate
            set targetURL to "\(url)"
            repeat with w in windows
                set tabList to tabs of w
                repeat with t in tabList
                    set tabURL to URL of t
                    if \(matchCondition) then
                        tell w
                            set active tab to t
                        end tell
                        set index of w to 1
                        return "FOUND"
                    end if
                end repeat
            end repeat
            return "NOT_FOUND"
        end tell
        """
    }
    
    private func buildEdgeSwitchScript(url: String, precision: URLMatchPrecision) -> String {
        let matchCondition: String
        switch precision {
        case .exact:
            matchCondition = "tabURL = targetURL"
        case .prefix:
            matchCondition = "tabURL starts with targetURL or targetURL starts with tabURL"
        case .hostOnly:
            let host = extractHost(from: url)
            let safeHost = appleScriptEscape(host)
            matchCondition = "tabURL contains \"\(safeHost)\""
        }
        
        return """
        tell application "Microsoft Edge"
            activate
            set targetURL to "\(url)"
            repeat with w in windows
                set tabList to tabs of w
                repeat with t in tabList
                    set tabURL to URL of t
                    if \(matchCondition) then
                        tell w
                            set active tab to t
                        end tell
                        set index of w to 1
                        return "FOUND"
                    end if
                end repeat
            end repeat
            return "NOT_FOUND"
        end tell
        """
    }
    
    // MARK: - Open Scripts (new tab/window)
    
    private func buildSafariOpenScript(url: String) -> String {
        return """
        tell application "Safari"
            activate
            tell front window
                set current tab to (make new tab with properties {URL:"\(url)"})
            end tell
        end tell
        """
    }
    
    private func buildChromeOpenScript(url: String) -> String {
        return """
        tell application "Google Chrome"
            activate
            tell front window
                make new tab with properties {URL:"\(url)"}
            end tell
        end tell
        """
    }
    
    private func buildEdgeOpenScript(url: String) -> String {
        return """
        tell application "Microsoft Edge"
            activate
            tell front window
                make new tab with properties {URL:"\(url)"}
            end tell
        end tell
        """
    }
}
