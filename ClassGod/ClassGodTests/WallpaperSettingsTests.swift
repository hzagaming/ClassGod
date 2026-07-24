import Foundation
import Testing
@testable import ClassGod

@Suite("Wallpaper playback settings")
struct WallpaperSettingsTests {
    @Test("Existing settings default to playing")
    func migratesExistingSettings() throws {
        let data = Data(#"{"isEnabled":true,"showOnDesktop":false,"isMuted":true,"playbackMode":"singleLoop","volume":0.3}"#.utf8)
        let settings = try JSONDecoder().decode(WallpaperSettings.self, from: data)
        #expect(settings.isPlaying)
    }

    @Test("Paused state survives a settings round trip")
    func persistsPausedState() throws {
        let original = WallpaperSettings(
            isEnabled: true,
            showOnDesktop: true,
            isPlaying: false,
            isMuted: false,
            playbackMode: .listLoop,
            volume: 0.6,
            currentWallpaperId: UUID()
        )
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(WallpaperSettings.self, from: data)
        #expect(!restored.isPlaying)
        #expect(restored.currentWallpaperId == original.currentWallpaperId)
    }
}
