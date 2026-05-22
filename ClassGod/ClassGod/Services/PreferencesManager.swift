//
//  PreferencesManager.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import Combine

final class PreferencesManager: ObservableObject {
    static let shared = PreferencesManager()
    
    @Published var preferences: AppPreferences {
        didSet {
            if oldValue != preferences {
                save()
                onPreferencesChanged?(preferences)
            }
        }
    }
    
    private let key = "com.hanazar.classgod.preferences"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    var onPreferencesChanged: ((AppPreferences) -> Void)?
    
    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        preferences = PreferencesManager.loadPreferences()
    }
    
    private static func loadPreferences() -> AppPreferences {
        guard let data = UserDefaults.standard.data(forKey: "com.hanazar.classgod.preferences") else {
            return .default
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(AppPreferences.self, from: data)
        } catch {
            print("[PreferencesManager] Failed to decode preferences: \(error). Resetting to defaults.")
            return .default
        }
    }
    
    private func save() {
        do {
            let data = try encoder.encode(preferences)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("[PreferencesManager] Failed to save preferences: \(error)")
        }
    }
    
    func resetToDefaults() {
        preferences = .default
    }
    
    func exportToFile() -> URL? {
        do {
            let data = try encoder.encode(preferences)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate, .withTime]
            let dateString = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("ClassGod-Preferences-\(dateString).json")
            try data.write(to: url)
            return url
        } catch {
            print("[PreferencesManager] Export failed: \(error)")
            return nil
        }
    }
    
    func importFromFile(url: URL) -> Bool {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? Int, size > 10_000_000 {
                print("[PreferencesManager] Import file too large: \(size) bytes")
                return false
            }
            let data = try Data(contentsOf: url)
            let imported = try decoder.decode(AppPreferences.self, from: data)
            preferences = imported
            return true
        } catch {
            print("[PreferencesManager] Import failed: \(error)")
            return false
        }
    }
}
