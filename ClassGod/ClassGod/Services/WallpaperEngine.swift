//
//  WallpaperEngine.swift
//  ClassGod
//

import SwiftUI
import AVFoundation
import Combine

extension Notification.Name {
    static let wallpaperVideoDidLoop = Notification.Name("com.hanazar.classgod.wallpaperVideoDidLoop")
    static let wallpaperStateDidChange = Notification.Name("com.hanazar.classgod.wallpaperStateDidChange")
}

@MainActor
final class WallpaperEngine: ObservableObject {
    static let shared = WallpaperEngine()
    
    // MARK: - Published State
    @Published var isEnabled: Bool = false
    @Published var showOnDesktop: Bool = false
    @Published var currentWallpaper: WallpaperItem?
    @Published var playlist: [WallpaperItem] = []
    @Published var isPlaying: Bool = true
    @Published var isMuted: Bool = true
    @Published var playbackMode: WallpaperPlaybackMode = .singleLoop
    @Published var volume: Double = 0.3
    
    // MARK: - Storage
    private let playlistKey = "com.hanazar.classgod.wallpaper.playlist"
    private let settingsKey = "com.hanazar.classgod.wallpaper.settings"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var loopObserver: NSObjectProtocol?
    
    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        loadPlaylist()
        loadSettings()
        
        loopObserver = NotificationCenter.default.addObserver(
            forName: .wallpaperVideoDidLoop,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleVideoLoop()
            }
        }
    }
    
    deinit {
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Playlist Management
    
    func addWallpaper(from url: URL) {
        let type: WallpaperType
        let ext = url.pathExtension.lowercased()
        if ["mp4", "mov", "m4v", "avi", "mkv", "webm"].contains(ext) {
            type = .video
        } else if ["jpg", "jpeg", "png", "heic", "heif", "bmp", "tiff", "gif", "webp"].contains(ext) {
            type = .image
        } else {
            return
        }
        
        let filePath: String
        if let copiedURL = copyWallpaperToAppSupport(original: url) {
            filePath = copiedURL.path
        } else {
            filePath = url.path
        }
        
        let item = WallpaperItem(
            name: url.deletingPathExtension().lastPathComponent,
            filePath: filePath,
            type: type
        )
        playlist.append(item)
        savePlaylist()
        
        if currentWallpaper == nil {
            selectWallpaper(item)
        }
    }
    
    func removeWallpaper(_ item: WallpaperItem) {
        let removedCurrent = currentWallpaper?.id == item.id
        playlist.removeAll { $0.id == item.id }
        deleteWallpaperFileIfManaged(path: item.filePath)
        if removedCurrent {
            currentWallpaper = nil
            if let next = playlist.first {
                selectWallpaper(next)
            } else {
                isEnabled = false
                saveSettings()
                NotificationCenter.default.post(name: .wallpaperStateDidChange, object: nil)
            }
        }
        savePlaylist()
    }
    
    private func wallpapersDirectory() -> URL? {
        guard let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let dir = supportDir.appendingPathComponent("com.hanazar.classgod/Wallpapers", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        return dir
    }
    
    private func copyWallpaperToAppSupport(original: URL) -> URL? {
        guard let dir = wallpapersDirectory() else { return nil }
        let uniqueName = "\(UUID().uuidString)_\(original.lastPathComponent)"
        let dest = dir.appendingPathComponent(uniqueName)
        do {
            try FileManager.default.copyItem(at: original, to: dest)
            return dest
        } catch {
            print("[WallpaperEngine] Failed to copy wallpaper to app support: \(error)")
            return nil
        }
    }
    
    private func deleteWallpaperFileIfManaged(path: String) {
        guard let dir = wallpapersDirectory()?.path else { return }
        if path.hasPrefix(dir) {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
    
    func selectWallpaper(_ item: WallpaperItem) {
        guard item.fileExists else {
            playlist.removeAll { $0.id == item.id }
            savePlaylist()
            if let next = playlist.first {
                selectWallpaper(next)
            } else {
                currentWallpaper = nil
                isEnabled = false
                saveSettings()
                NotificationCenter.default.post(name: .wallpaperStateDidChange, object: nil)
            }
            return
        }
        
        currentWallpaper = item
        isEnabled = true
        saveSettings()
        NotificationCenter.default.post(name: .wallpaperStateDidChange, object: nil)
    }
    
    func toggleEnabled() {
        isEnabled.toggle()
        if isEnabled {
            if let current = currentWallpaper {
                selectWallpaper(current)
            } else if let first = playlist.first {
                selectWallpaper(first)
            } else {
                isEnabled = false
            }
        }
        saveSettings()
        NotificationCenter.default.post(name: .wallpaperStateDidChange, object: nil)
    }
    
    func toggleShowOnDesktop() {
        showOnDesktop.toggle()
        if showOnDesktop && !isEnabled {
            isEnabled = true
            if let current = currentWallpaper {
                selectWallpaper(current)
            } else if let first = playlist.first {
                selectWallpaper(first)
            } else {
                isEnabled = false
            }
        }
        saveSettings()
        NotificationCenter.default.post(name: .wallpaperStateDidChange, object: nil)
    }
    
    func togglePlayPause() {
        isPlaying.toggle()
        saveSettings()
        NotificationCenter.default.post(name: .wallpaperStateDidChange, object: nil)
    }
    
    func toggleMute() {
        isMuted.toggle()
        saveSettings()
        NotificationCenter.default.post(name: .wallpaperStateDidChange, object: nil)
    }
    
    func setVolume(_ value: Double) {
        volume = max(0, min(1, value))
        saveSettings()
        NotificationCenter.default.post(name: .wallpaperStateDidChange, object: nil)
    }

    func cyclePlaybackMode() {
        let modes = WallpaperPlaybackMode.allCases
        guard let index = modes.firstIndex(of: playbackMode) else { return }
        playbackMode = modes[(index + 1) % modes.count]
        saveSettings()
    }
    
    func nextWallpaper() {
        guard !playlist.isEmpty else { return }
        
        let next: WallpaperItem
        switch playbackMode {
        case .singleLoop:
            if let current = currentWallpaper {
                selectWallpaper(current)
                return
            }
            next = playlist[0]
        case .listLoop:
            if let current = currentWallpaper,
               let idx = playlist.firstIndex(where: { $0.id == current.id }) {
                let nextIdx = (idx + 1) % playlist.count
                next = playlist[nextIdx]
            } else {
                next = playlist[0]
            }
        case .random:
            next = playlist.randomElement() ?? playlist[0]
        }
        selectWallpaper(next)
    }
    
    func previousWallpaper() {
        guard !playlist.isEmpty else { return }
        
        let prev: WallpaperItem
        switch playbackMode {
        case .singleLoop:
            if let current = currentWallpaper {
                selectWallpaper(current)
                return
            }
            prev = playlist[0]
        case .listLoop:
            if let current = currentWallpaper,
               let idx = playlist.firstIndex(where: { $0.id == current.id }) {
                let prevIdx = (idx - 1 + playlist.count) % playlist.count
                prev = playlist[prevIdx]
            } else {
                prev = playlist[0]
            }
        case .random:
            prev = playlist.randomElement() ?? playlist[0]
        }
        selectWallpaper(prev)
    }
    
    private func handleVideoLoop() {
        guard playbackMode != .singleLoop else { return }
        nextWallpaper()
    }
    
    // MARK: - Persistence
    
    private func loadPlaylist() {
        guard let data = UserDefaults.standard.data(forKey: playlistKey) else { return }
        do {
            playlist = try decoder.decode([WallpaperItem].self, from: data)
        } catch {
            print("[WallpaperEngine] Failed to load playlist: \(error)")
        }
    }
    
    private func savePlaylist() {
        do {
            let data = try encoder.encode(playlist)
            UserDefaults.standard.set(data, forKey: playlistKey)
        } catch {
            print("[WallpaperEngine] Failed to save playlist: \(error)")
        }
    }
    
    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: settingsKey) else { return }
        do {
            let settings = try decoder.decode(WallpaperSettings.self, from: data)
            isEnabled = settings.isEnabled
            showOnDesktop = settings.showOnDesktop
            isPlaying = settings.isPlaying
            isMuted = settings.isMuted
            playbackMode = settings.playbackMode
            volume = max(0, min(1, settings.volume))
            if let currentId = settings.currentWallpaperId,
               let item = playlist.first(where: { $0.id == currentId }) {
                currentWallpaper = item
            } else if isEnabled {
                currentWallpaper = playlist.first
                isEnabled = currentWallpaper != nil
            }
        } catch {
            print("[WallpaperEngine] Failed to load settings: \(error)")
        }
    }
    
    private func saveSettings() {
        let settings = WallpaperSettings(
            isEnabled: isEnabled,
            showOnDesktop: showOnDesktop,
            isPlaying: isPlaying,
            isMuted: isMuted,
            playbackMode: playbackMode,
            volume: volume,
            currentWallpaperId: currentWallpaper?.id
        )
        do {
            let data = try encoder.encode(settings)
            UserDefaults.standard.set(data, forKey: settingsKey)
        } catch {
            print("[WallpaperEngine] Failed to save settings: \(error)")
        }
    }
}

// MARK: - Settings Codable

struct WallpaperSettings: Codable {
    var isEnabled: Bool
    var showOnDesktop: Bool
    var isPlaying: Bool
    var isMuted: Bool
    var playbackMode: WallpaperPlaybackMode
    var volume: Double
    var currentWallpaperId: UUID?

    init(
        isEnabled: Bool,
        showOnDesktop: Bool,
        isPlaying: Bool,
        isMuted: Bool,
        playbackMode: WallpaperPlaybackMode,
        volume: Double,
        currentWallpaperId: UUID?
    ) {
        self.isEnabled = isEnabled
        self.showOnDesktop = showOnDesktop
        self.isPlaying = isPlaying
        self.isMuted = isMuted
        self.playbackMode = playbackMode
        self.volume = volume
        self.currentWallpaperId = currentWallpaperId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        showOnDesktop = try container.decode(Bool.self, forKey: .showOnDesktop)
        isPlaying = try container.decodeIfPresent(Bool.self, forKey: .isPlaying) ?? true
        isMuted = try container.decode(Bool.self, forKey: .isMuted)
        playbackMode = try container.decode(WallpaperPlaybackMode.self, forKey: .playbackMode)
        volume = try container.decode(Double.self, forKey: .volume)
        currentWallpaperId = try container.decodeIfPresent(UUID.self, forKey: .currentWallpaperId)
    }
}
