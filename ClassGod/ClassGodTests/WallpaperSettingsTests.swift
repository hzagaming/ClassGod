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

    @Test("Wallpaper deletion confirmation is localized")
    func localizesDeletionConfirmation() {
        let value = String(
            localized: "wallpaper.delete_message",
            bundle: .main,
            locale: Locale(identifier: "en")
        )

        #expect(value != "wallpaper.delete_message")
        #expect(value.contains("%@"))
    }

    @Test("Video loop respects playback state and mode")
    func resolvesVideoLoopAction() {
        #expect(WallpaperLoopPolicy.action(mode: .singleLoop, isEnabled: true, isPlaying: true) == .restart)
        #expect(WallpaperLoopPolicy.action(mode: .listLoop, isEnabled: true, isPlaying: true) == .advance)
        #expect(WallpaperLoopPolicy.action(mode: .random, isEnabled: false, isPlaying: true) == .stop)
        #expect(WallpaperLoopPolicy.action(mode: .singleLoop, isEnabled: true, isPlaying: false) == .stop)
    }

    @Test("Animated images respect playback state and safe frame timing")
    func resolvesAnimatedImagePlayback() {
        #expect(AnimatedImagePlaybackPolicy.shouldAnimate(isEnabled: true, isPlaying: true))
        #expect(!AnimatedImagePlaybackPolicy.shouldAnimate(isEnabled: false, isPlaying: true))
        #expect(!AnimatedImagePlaybackPolicy.shouldAnimate(isEnabled: true, isPlaying: false))
        #expect(AnimatedImagePlaybackPolicy.frameDelay(nil) == 0.1)
        #expect(AnimatedImagePlaybackPolicy.frameDelay(0.001) == 0.02)
        #expect(AnimatedImagePlaybackPolicy.frameDelay(0.08) == 0.08)
    }

    @Test("Wallpaper audio controls are available only for video")
    func resolvesWallpaperAudioAvailability() {
        #expect(WallpaperAudioPolicy.isAvailable(for: .video))
        #expect(!WallpaperAudioPolicy.isAvailable(for: .image))
        #expect(!WallpaperAudioPolicy.isAvailable(for: nil))
    }

    @Test("Managed wallpaper deletion stays inside its exact directory")
    func validatesManagedWallpaperPaths() {
        let directory = URL(fileURLWithPath: "/tmp/ClassGod/Wallpapers", isDirectory: true)

        #expect(WallpaperFilePolicy.isManaged(URL(fileURLWithPath: "/tmp/ClassGod/Wallpapers/item.mov"), in: directory))
        #expect(!WallpaperFilePolicy.isManaged(URL(fileURLWithPath: "/tmp/ClassGod/WallpapersBackup/item.mov"), in: directory))
        #expect(!WallpaperFilePolicy.isManaged(directory, in: directory))
    }
}
