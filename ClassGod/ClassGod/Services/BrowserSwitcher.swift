//
//  BrowserSwitcher.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import AppKit

nonisolated struct BrowserSwitchSession: Sendable {
    private(set) var generation: UInt = 0

    mutating func begin() -> UInt {
        generation &+= 1
        return generation
    }

    func isCurrent(_ request: UInt) -> Bool {
        request == generation
    }
}

final class BrowserSwitcher {
    static let shared = BrowserSwitcher()

    private var pendingSwitchWorkItem: DispatchWorkItem?
    private var switchSession = BrowserSwitchSession()

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
        let delay = max(0, prefs.switchDelayMs) / 1000
        pendingSwitchWorkItem?.cancel()
        let request = switchSession.begin()

        if delay > 0 {
            let item = DispatchWorkItem { [weak self] in
                guard let self, self.switchSession.isCurrent(request) else { return }
                self.pendingSwitchWorkItem = nil
                self.performSwitchToTab(tab, prefs: prefs, request: request, completion: completion)
            }
            pendingSwitchWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
        } else {
            pendingSwitchWorkItem = nil
            performSwitchToTab(tab, prefs: prefs, request: request, completion: completion)
        }
    }

    private func performSwitchToTab(
        _ tab: BrowserTab,
        prefs: AppPreferences,
        request: UInt,
        completion: ((Bool, String) -> Void)? = nil
    ) {
        guard switchSession.isCurrent(request) else { return }
        guard tab.browser.isInstalled else {
            complete(
                request: request,
                success: false,
                message: String(format: String(localized: "error.browser_not_found"), tab.browser.displayName),
                completion: completion
            )
            return
        }
        
        let safeURL = appleScriptEscape(tab.url)
        let isRunning = isBrowserRunning(tab.browser)

        // If browser not running, respect user preference
        if !isRunning {
            switch prefs.browserNotRunningBehavior {
            case .doNothing:
                complete(
                    request: request,
                    success: false,
                    message: String(format: String(localized: "error.browser_not_running"), tab.browser.displayName),
                    completion: completion
                )
                return
            case .launchOnly:
                launchBrowser(tab.browser, request: request, completion: completion)
                return
            case .launchAndOpen:
                break // fall through to open URL
            }
        }

        // If "always new tab" is selected, skip search and directly open URL
        if prefs.switchBehavior == .alwaysNewTab {
            openURLDirectly(tab: tab, url: safeURL, request: request, completion: completion)
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
            guard self.switchSession.isCurrent(request) else { return }
            if errorMsg != nil {
                // Fallback: try to open URL directly
                self.openURLDirectly(tab: tab, url: safeURL, request: request, completion: completion)
                return
            }

            let output = result?.stringValue ?? ""
            if output == "NOT_FOUND" {
                self.openURLDirectly(tab: tab, url: safeURL, request: request, completion: completion)
            } else {
                self.complete(
                    request: request,
                    success: true,
                    message: String(format: String(localized: "toast.switched_browser"), tab.browser.displayName),
                    completion: completion
                )
            }
        }
    }

    private func launchBrowser(_ browser: BrowserType, request: UInt, completion: ((Bool, String) -> Void)?) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleIdentifier) else {
            complete(
                request: request,
                success: false,
                message: String(format: String(localized: "error.browser_not_found"), browser.displayName),
                completion: completion
            )
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { app, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.complete(
                        request: request,
                        success: false,
                        message: String(format: String(localized: "error.launch_failed"), browser.displayName, error.localizedDescription),
                        completion: completion
                    )
                } else {
                    self.complete(
                        request: request,
                        success: true,
                        message: String(format: String(localized: "toast.launched"), browser.displayName),
                        completion: completion
                    )
                }
            }
        }
    }

    private func openURLDirectly(
        tab: BrowserTab,
        url: String,
        request: UInt,
        completion: ((Bool, String) -> Void)? = nil
    ) {
        guard switchSession.isCurrent(request) else { return }
        guard tab.browser.isInstalled else {
            complete(
                request: request,
                success: false,
                message: String(format: String(localized: "error.browser_not_found"), tab.browser.displayName),
                completion: completion
            )
            return
        }
        
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
                self.complete(request: request, success: false, message: msg, completion: completion)
            } else {
                self.complete(
                    request: request,
                    success: true,
                    message: String(format: String(localized: "toast.opened_url"), tab.browser.displayName),
                    completion: completion
                )
            }
        }
    }

    private func complete(
        request: UInt,
        success: Bool,
        message: String,
        completion: ((Bool, String) -> Void)?
    ) {
        guard switchSession.isCurrent(request) else { return }
        completion?(success, message)
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
            set targetURL to "\(url)"
            if (count of windows) = 0 then
                make new document with properties {URL:targetURL}
            else
                tell front window
                    set current tab to (make new tab with properties {URL:targetURL})
                end tell
            end if
        end tell
        """
    }

    private func buildChromeOpenScript(url: String) -> String {
        return """
        tell application "Google Chrome"
            activate
            set targetURL to "\(url)"
            if (count of windows) = 0 then
                make new window
                set URL of active tab of front window to targetURL
            else
                tell front window
                    make new tab with properties {URL:targetURL}
                end tell
            end if
        end tell
        """
    }

    private func buildEdgeOpenScript(url: String) -> String {
        return """
        tell application "Microsoft Edge"
            activate
            set targetURL to "\(url)"
            if (count of windows) = 0 then
                make new window
                set URL of active tab of front window to targetURL
            else
                tell front window
                    make new tab with properties {URL:targetURL}
                end tell
            end if
        end tell
        """
    }
}
