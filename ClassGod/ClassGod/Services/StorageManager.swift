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
}
