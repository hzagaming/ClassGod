//
//  BrowserDetector.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import AppKit

enum BrowserDetectionError: Error, LocalizedError {
    case noFrontmostBrowser
    case appleScriptFailed(String)
    case invalidResponse
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .noFrontmostBrowser:
            return String(localized: "error.no_frontmost_browser")
        case .appleScriptFailed(let msg):
            return String(format: String(localized: "error.applescript_failed"), msg)
        case .invalidResponse:
            return String(localized: "error.invalid_response")
        case .timeout:
            return String(localized: "error.timeout")
        }
    }
}

struct DetectedTab {
    let title: String
    let url: String
    let browser: BrowserType
}

final class BrowserDetector {
    static let shared = BrowserDetector()
    
    private let supportedBundleIDs: Set<String> = [
        BrowserType.safari.bundleIdentifier,
        BrowserType.chrome.bundleIdentifier,
        BrowserType.edge.bundleIdentifier
    ]
    
    // Use ASCII Record Separator to avoid conflicts with page titles
    private let delimiter = "\u{001E}"
    
    private init() {}
    
    func detectFrontmostTab(completion: @escaping (Result<DetectedTab, BrowserDetectionError>) -> Void) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            completion(.failure(.noFrontmostBrowser))
            return
        }
        
        let bundleID = frontApp.bundleIdentifier ?? ""
        guard supportedBundleIDs.contains(bundleID) else {
            completion(.failure(.noFrontmostBrowser))
            return
        }
        
        guard let browser = BrowserType.allCases.first(where: { $0.bundleIdentifier == bundleID }) else {
            completion(.failure(.noFrontmostBrowser))
            return
        }
        
        guard browser.isInstalled else {
            completion(.failure(.noFrontmostBrowser))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.runAppleScript(for: browser)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    private func runAppleScript(for browser: BrowserType) -> Result<DetectedTab, BrowserDetectionError> {
        let scriptSource: String
        let delim = self.delimiter
        
        switch browser {
        case .safari:
            scriptSource = """
            tell application "Safari"
                if (count of windows) = 0 then
                    return "NO_TAB"
                end if
                set currentTab to current tab of front window
                return (name of currentTab) & "\(delim)" & (URL of currentTab)
            end tell
            """
            
        case .chrome:
            scriptSource = """
            tell application "Google Chrome"
                if (count of windows) = 0 then
                    return "NO_TAB"
                end if
                set currentTab to active tab of front window
                return (title of currentTab) & "\(delim)" & (URL of currentTab)
            end tell
            """
            
        case .edge:
            scriptSource = """
            tell application "Microsoft Edge"
                if (count of windows) = 0 then
                    return "NO_TAB"
                end if
                set currentTab to active tab of front window
                return (title of currentTab) & "\(delim)" & (URL of currentTab)
            end tell
            """
        }
        
        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: scriptSource) else {
            return .failure(.appleScriptFailed(String(localized: "error.create_applescript")))
        }
        
        let result = appleScript.executeAndReturnError(&errorInfo)
        
        if let error = errorInfo {
            let msg = error["NSAppleScriptErrorMessage"] as? String ?? String(localized: "error.unknown")
            return .failure(.appleScriptFailed(msg))
        }
        
        let output = result.stringValue ?? ""
        guard output != "NO_TAB" else {
            return .failure(.invalidResponse)
        }
        
        let parts = output.components(separatedBy: delimiter)
        guard parts.count >= 2 else {
            return .failure(.invalidResponse)
        }
        
        let title = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let url = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        
        return .success(DetectedTab(title: title, url: url, browser: browser))
    }
}
