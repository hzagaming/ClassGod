//
//  WallpaperItem.swift
//  ClassGod
//

import Foundation

enum WallpaperType: String, Codable, CaseIterable, Identifiable {
    case image = "image"
    case video = "video"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .image: return "Image"
        case .video: return "Video"
        }
    }
    
    var iconName: String {
        switch self {
        case .image: return "photo"
        case .video: return "film"
        }
    }
}

struct WallpaperItem: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var filePath: String
    var type: WallpaperType
    var dateAdded: Date
    var isBuiltIn: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        filePath: String,
        type: WallpaperType,
        dateAdded: Date = Date(),
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.filePath = filePath
        self.type = type
        self.dateAdded = dateAdded
        self.isBuiltIn = isBuiltIn
    }
    
    var fileURL: URL? {
        URL(fileURLWithPath: filePath)
    }
    
    var fileExists: Bool {
        guard let url = fileURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}
