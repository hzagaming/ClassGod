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
        #expect(WallpaperLoopPolicy.action(
            mode: .listLoop,
            isEnabled: true,
            isPlaying: true,
            coordinatesPlayback: false
        ) == .stop)
        #expect(WallpaperLoopPolicy.action(mode: .random, isEnabled: false, isPlaying: true) == .stop)
        #expect(WallpaperLoopPolicy.action(mode: .singleLoop, isEnabled: true, isPlaying: false) == .stop)
        #expect(WallpaperLoopPolicy.action(
            mode: .listLoop,
            isEnabled: true,
            isPlaying: true,
            hasAlternative: false
        ) == .restart)
    }

    @Test("Manual wallpaper navigation advances in every loop mode")
    func resolvesManualWallpaperNavigation() {
        #expect(WallpaperSelectionPolicy.candidateIndices(
            count: 3,
            currentIndex: 1,
            direction: .next,
            mode: .singleLoop
        ) == [2])
        #expect(WallpaperSelectionPolicy.candidateIndices(
            count: 3,
            currentIndex: 0,
            direction: .previous,
            mode: .listLoop
        ) == [2])
        #expect(WallpaperSelectionPolicy.candidateIndices(
            count: 3,
            currentIndex: 1,
            direction: .next,
            mode: .random
        ) == [0, 2])
        #expect(WallpaperSelectionPolicy.candidateIndices(
            count: 1,
            currentIndex: 0,
            direction: .next,
            mode: .random
        ) == [0])
        #expect(WallpaperSelectionPolicy.candidateIndices(
            count: 0,
            currentIndex: nil,
            direction: .next,
            mode: .listLoop
        ).isEmpty)
    }

    @MainActor
    @Test("Changing playback mode synchronizes active wallpaper players")
    func broadcastsPlaybackModeChanges() async {
        let engine = WallpaperEngine.shared
        let originalMode = engine.playbackMode

        await confirmation { confirmed in
            let token = NotificationCenter.default.addObserver(
                forName: .wallpaperStateDidChange,
                object: nil,
                queue: .main
            ) { _ in
                confirmed()
            }
            engine.cyclePlaybackMode()
            NotificationCenter.default.removeObserver(token)
        }

        while engine.playbackMode != originalMode {
            engine.cyclePlaybackMode()
        }
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
        #expect(!WallpaperAudioPolicy.shouldMute(userMuted: false, allowsAudio: true))
        #expect(WallpaperAudioPolicy.shouldMute(userMuted: false, allowsAudio: false))
        #expect(WallpaperAudioPolicy.shouldMute(userMuted: true, allowsAudio: true))
    }

    @Test("Wallpaper volume always remains finite and in range")
    func normalizesWallpaperVolume() {
        #expect(WallpaperVolumePolicy.normalized(-1) == 0)
        #expect(WallpaperVolumePolicy.normalized(0.4) == 0.4)
        #expect(WallpaperVolumePolicy.normalized(2) == 1)
        #expect(WallpaperVolumePolicy.normalized(.nan) == 0)
        #expect(WallpaperVolumePolicy.normalized(.infinity) == 0)
        #expect(!WallpaperVolumePolicy.shouldUpdate(current: 0.4, newValue: 0.4))
        #expect(!WallpaperVolumePolicy.shouldUpdate(current: 0, newValue: -1))
        #expect(WallpaperVolumePolicy.shouldUpdate(current: 0.4, newValue: 0.5))
    }

    @Test("Managed wallpaper deletion stays inside its exact directory")
    func validatesManagedWallpaperPaths() {
        let directory = URL(fileURLWithPath: "/tmp/ClassGod/Wallpapers", isDirectory: true)

        #expect(WallpaperFilePolicy.isManaged(URL(fileURLWithPath: "/tmp/ClassGod/Wallpapers/item.mov"), in: directory))
        #expect(!WallpaperFilePolicy.isManaged(URL(fileURLWithPath: "/tmp/ClassGod/WallpapersBackup/item.mov"), in: directory))
        #expect(!WallpaperFilePolicy.isManaged(directory, in: directory))
    }

    @Test("Wallpaper imports accept only supported media types")
    func validatesWallpaperImportTypes() {
        #expect(WallpaperImportPolicy.type(forExtension: "MP4") == .video)
        #expect(WallpaperImportPolicy.type(forExtension: "jpg") == .image)
        #expect(WallpaperImportPolicy.type(forExtension: "txt") == nil)
    }

    @Test("Wallpaper import feedback distinguishes failures from cancellation")
    func resolvesWallpaperImportFeedback() {
        #expect(WallpaperImportSummary(total: 3, imported: 3).failed == 0)
        #expect(!WallpaperImportSummary(total: 3, imported: 3).shouldReportFailure)
        #expect(WallpaperImportSummary(total: 3, imported: 1).failed == 2)
        #expect(WallpaperImportSummary(total: 3, imported: 1).shouldReportFailure)

        let cancellation = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)
        let unrelated = NSError(domain: "WallpaperImport", code: NSUserCancelledError)
        #expect(WallpaperImportPolicy.isUserCancellation(cancellation))
        #expect(!WallpaperImportPolicy.isUserCancellation(unrelated))
    }

    @Test("Stale video loads are rejected even when the URL is reused")
    func rejectsStaleVideoLoads() {
        let url = URL(fileURLWithPath: "/tmp/wallpaper.mov")
        let staleRequest = UUID()
        let currentRequest = UUID()

        #expect(!WallpaperMediaLoadPolicy.shouldAccept(
            requestURL: url,
            requestID: staleRequest,
            currentURL: url,
            currentRequestID: currentRequest
        ))
        #expect(WallpaperMediaLoadPolicy.shouldAccept(
            requestURL: url,
            requestID: currentRequest,
            currentURL: url,
            currentRequestID: currentRequest
        ))
    }

    @Test("Desktop wallpaper windows reconcile stable display identifiers")
    func reconcilesDesktopDisplays() {
        #expect(WallpaperDisplayPolicy.disconnectedIDs(
            existing: [1, 2],
            connected: [2, 3]
        ) == [1])
        #expect(WallpaperDisplayPolicy.disconnectedIDs(
            existing: [1],
            connected: [1]
        ).isEmpty)
        #expect(!WallpaperDisplayPolicy.shouldRefreshContent(
            previousCoordinatesPlayback: true,
            currentCoordinatesPlayback: true
        ))
        #expect(WallpaperDisplayPolicy.shouldRefreshContent(
            previousCoordinatesPlayback: false,
            currentCoordinatesPlayback: true
        ))
    }

    @Test("Desktop wallpaper presentation refreshes only for visible content changes")
    func reconcilesDesktopPresentation() {
        let firstID = UUID()
        let secondID = UUID()
        let hidden = WallpaperPresentationState(
            isEnabled: false,
            showOnDesktop: false,
            wallpaperID: nil
        )
        let first = WallpaperPresentationState(
            isEnabled: true,
            showOnDesktop: true,
            wallpaperID: firstID
        )
        let second = WallpaperPresentationState(
            isEnabled: true,
            showOnDesktop: true,
            wallpaperID: secondID
        )

        #expect(WallpaperPresentationPolicy.action(previous: hidden, current: first) == .show)
        #expect(WallpaperPresentationPolicy.action(previous: first, current: first) == .none)
        #expect(WallpaperPresentationPolicy.action(previous: first, current: second) == .refreshContent)
        #expect(WallpaperPresentationPolicy.action(previous: second, current: hidden) == .hide)
    }

    @Test("Animated wallpapers preserve aspect ratio while filling the desktop")
    func resolvesAnimatedWallpaperLayout() {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)

        #expect(WallpaperImageLayoutPolicy.aspectFillRect(
            imageSize: CGSize(width: 200, height: 100),
            in: bounds
        ) == CGRect(x: -50, y: 0, width: 200, height: 100))
        #expect(WallpaperImageLayoutPolicy.aspectFillRect(
            imageSize: CGSize(width: 100, height: 200),
            in: bounds
        ) == CGRect(x: 0, y: -50, width: 100, height: 200))
        #expect(WallpaperImageLayoutPolicy.aspectFillRect(
            imageSize: .zero,
            in: bounds
        ) == nil)
    }
}
