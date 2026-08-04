import Testing
@testable import ClassGod

@Suite("Animation duration policy")
struct AnimationPolicyTests {
    @Test("Instant mode and reduced motion disable transitions")
    func disablesTransitionsWhenRequested() {
        #expect(AnimationDurationPolicy.duration(preferred: 0.2, useInstant: true, reduceMotion: false) == 0)
        #expect(AnimationDurationPolicy.duration(preferred: 0.2, useInstant: false, reduceMotion: true) == 0)
        #expect(AnimationDurationPolicy.duration(preferred: 0.2, useInstant: false, reduceMotion: false) == 0.2)
        #expect(!AnimationDurationPolicy.shouldRunLaunchEffects(duration: 0))
        #expect(AnimationDurationPolicy.shouldRunLaunchEffects(duration: 0.2))
    }

    @Test("Instant animation mode also removes the splash wait")
    func resolvesLaunchDelay() {
        #expect(AnimationDurationPolicy.launchDelay(preferred: 2, duration: 0) == 0)
        #expect(AnimationDurationPolicy.launchDelay(preferred: 2, duration: 0.2) == 2)
    }

    @Test("Launch presentation respects the show-on-launch preference")
    func resolvesInitialWindowPresentation() {
        #expect(LaunchWindowPresentationPolicy.shouldShowMainWindow(showOnLaunch: true))
        #expect(!LaunchWindowPresentationPolicy.shouldShowMainWindow(showOnLaunch: false))
    }

    @Test("Overlapping sounds reuse idle channels and stay bounded")
    func selectsSoundChannels() {
        #expect(SoundPlaybackPolicy.channelIndex(isPlaying: [true, false], limit: 4) == 1)
        #expect(SoundPlaybackPolicy.channelIndex(isPlaying: [true, true], limit: 4) == 2)
        #expect(SoundPlaybackPolicy.channelIndex(isPlaying: [true, true, true, true], limit: 4) == nil)
        #expect(SoundPlaybackPolicy.channelIndex(isPlaying: [false], limit: 0) == nil)
    }

    @Test("Window transitions ignore duplicates and stale completions")
    func tracksLatestWindowTransition() {
        var tracker = WindowTransitionTracker<String>()

        let show = tracker.begin(for: "permission", targetVisible: true, currentVisible: false)
        #expect(show == 1)
        #expect(tracker.begin(for: "permission", targetVisible: true, currentVisible: true) == nil)

        let hide = tracker.begin(for: "permission", targetVisible: false, currentVisible: true)
        #expect(hide == 2)
        #expect(tracker.isCurrent(hide!, for: "permission", targetVisible: false))
        #expect(!tracker.targetVisibility(for: "permission", currentVisible: true))

        let reopen = tracker.begin(for: "permission", targetVisible: true, currentVisible: false)
        #expect(reopen == 3)
        #expect(!tracker.isCurrent(hide!, for: "permission", targetVisible: false))
        #expect(tracker.isCurrent(reopen!, for: "permission", targetVisible: true))
        #expect(tracker.targetVisibility(for: "permission", currentVisible: false))
    }
}
