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
        case .singleLoop: return "Single Loop"
        case .listLoop: return "Playlist Loop"
        case .random: return "Shuffle"
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
