//
//  WallpaperPlaybackMode.swift
//  ClassGod
//

import Foundation

enum WallpaperPlaybackMode: String, Codable, CaseIterable, Identifiable {
    case singleLoop = "singleLoop"
    case listLoop = "listLoop"
    case random = "random"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .singleLoop: return String(localized: "wallpaper.mode.single_loop")
        case .listLoop: return String(localized: "wallpaper.mode.playlist_loop")
        case .random: return String(localized: "wallpaper.mode.shuffle")
        }
    }
    
    var iconName: String {
        switch self {
        case .singleLoop: return "repeat.1"
        case .listLoop: return "repeat"
        case .random: return "shuffle"
        }
    }
}
