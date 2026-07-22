//
//  StorageManager.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation

final class StorageManager {
    static let shared = StorageManager()
    
    private let tabsKey = "com.hanazar.classgod.savedTabs"
    private let switchTargetsKey = "com.hanazar.classgod.switchTargets"
    private let bypassRulesKey = "com.hanazar.classgod.bypassRules"
    private let panicAppsKey = "com.hanazar.classgod.panicApps"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    func saveTabs(_ tabs: [BrowserTab]) {
        do {
            let data = try encoder.encode(tabs)
            UserDefaults.standard.set(data, forKey: tabsKey)
        } catch {
            print("[StorageManager] Failed to save tabs: \(error)")
        }
    }
    
    func loadTabs() -> [BrowserTab] {
        guard let data = UserDefaults.standard.data(forKey: tabsKey) else {
            return []
        }
        do {
            return try decoder.decode([BrowserTab].self, from: data)
        } catch {
            print("[StorageManager] Failed to load tabs: \(error)")
            return []
        }
    }
    
    func addTab(_ tab: BrowserTab) {
        var tabs = loadTabs()
        tabs.append(tab)
        saveTabs(tabs)
    }
    
    func updateTab(_ tab: BrowserTab) {
        var tabs = loadTabs()
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs[index] = tab
            saveTabs(tabs)
        }
    }
    
    func removeTab(_ tab: BrowserTab) {
        var tabs = loadTabs()
        tabs.removeAll { $0.id == tab.id }
        saveTabs(tabs)
    }
    
    func removeTab(byID id: UUID) {
        var tabs = loadTabs()
        tabs.removeAll { $0.id == id }
        saveTabs(tabs)
    }
    
    // MARK: - Switch Targets
    
    func saveSwitchTargets(_ targets: [SwitchTarget]) {
        do {
            let data = try encoder.encode(targets)
            UserDefaults.standard.set(data, forKey: switchTargetsKey)
        } catch {
            print("[StorageManager] Failed to save switch targets: \(error)")
        }
    }
    
    func loadSwitchTargets() -> [SwitchTarget] {
        guard let data = UserDefaults.standard.data(forKey: switchTargetsKey) else {
            return []
        }
        do {
            return try decoder.decode([SwitchTarget].self, from: data)
        } catch {
            print("[StorageManager] Failed to load switch targets: \(error)")
            return []
        }
    }
    
    // MARK: - Bypass Rules
    
    func saveBypassRules(_ rules: [BypassRule]) {
        do {
            let data = try encoder.encode(rules)
            UserDefaults.standard.set(data, forKey: bypassRulesKey)
        } catch {
            print("[StorageManager] Failed to save bypass rules: \(error)")
        }
    }
    
    func loadBypassRules() -> [BypassRule] {
        guard let data = UserDefaults.standard.data(forKey: bypassRulesKey) else {
            return []
        }
        do {
            return try decoder.decode([BypassRule].self, from: data)
        } catch {
            print("[StorageManager] Failed to load bypass rules: \(error)")
            return []
        }
    }
    
    // MARK: - Panic Apps
    
    func savePanicApps(_ apps: [PanicApp]) {
        do {
            let data = try encoder.encode(apps)
            UserDefaults.standard.set(data, forKey: panicAppsKey)
        } catch {
            print("[StorageManager] Failed to save panic apps: \(error)")
        }
    }
    
    func loadPanicApps() -> [PanicApp] {
        guard let data = UserDefaults.standard.data(forKey: panicAppsKey) else {
            return []
        }
        do {
            return try decoder.decode([PanicApp].self, from: data)
        } catch {
            print("[StorageManager] Failed to load panic apps: \(error)")
            return []
        }
    }
}

extension Notification.Name {
    static let classGodTabsDidChange = Notification.Name("classGodTabsDidChange")
    static let draggableWindowDidMove = Notification.Name("draggableWindowDidMove")
    static let classGodShowErrorHubEntry = Notification.Name("classGodShowErrorHubEntry")
    static let fanControlWindowWillHide = Notification.Name("fanControlWindowWillHide")
    static let mainWindowDidShow = Notification.Name("mainWindowDidShow")
    static let mainWindowWillHide = Notification.Name("mainWindowWillHide")
    static let hackerDesktopWindowDidShow = Notification.Name("hackerDesktopWindowDidShow")
    static let hackerDesktopWindowWillHide = Notification.Name("hackerDesktopWindowWillHide")
    static let activityMonitorWindowDidShow = Notification.Name("activityMonitorWindowDidShow")
    static let activityMonitorWindowWillHide = Notification.Name("activityMonitorWindowWillHide")
    static let assessPrepHackWindowDidShow = Notification.Name("assessPrepHackWindowDidShow")
    static let assessPrepHackWindowWillHide = Notification.Name("assessPrepHackWindowWillHide")
}
