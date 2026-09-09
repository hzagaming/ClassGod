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

    @Test("Disabled animation modes remove transient spatial scaling")
    func resolvesInteractiveScale() {
        #expect(InteractiveMotionPolicy.scale(
            active: true,
            requestedScale: 0.9,
            animationsEnabled: true
        ) == 0.9)
        #expect(InteractiveMotionPolicy.scale(
            active: true,
            requestedScale: 0.9,
            animationsEnabled: false
        ) == 1)
        #expect(InteractiveMotionPolicy.scale(
            active: false,
            requestedScale: 0.9,
            animationsEnabled: true
        ) == 1)
        #expect(InteractiveMotionPolicy.scale(
            active: true,
            requestedScale: .nan,
            animationsEnabled: true
        ) == 1)
    }

    @Test("Disabled controls never activate hover feedback")
    func resolvesHoverInteraction() {
        #expect(HoverInteractionPolicy.isActive(isHovered: true, isEnabled: true))
        #expect(!HoverInteractionPolicy.isActive(isHovered: true, isEnabled: false))
        #expect(!HoverInteractionPolicy.isActive(isHovered: false, isEnabled: true))
    }

    @Test("Disabled entrance motion presents content on the first frame")
    func resolvesEntrancePresentation() {
        #expect(EntranceMotionPolicy.isPresented(state: false, animationsEnabled: false))
        #expect(EntranceMotionPolicy.isPresented(state: true, animationsEnabled: false))
        #expect(!EntranceMotionPolicy.isPresented(state: false, animationsEnabled: true))
        #expect(EntranceMotionPolicy.isPresented(state: true, animationsEnabled: true))
    }

    @Test("Shortcut recording pulse stops for instant and reduced motion modes")
    func resolvesShortcutRecordingPulse() {
        #expect(ShortcutRecordingMotionPolicy.shouldPulse(
            isRecording: true,
            animationsEnabled: true,
            reduceMotion: false
        ))
        #expect(!ShortcutRecordingMotionPolicy.shouldPulse(
            isRecording: false,
            animationsEnabled: true,
            reduceMotion: false
        ))
        #expect(!ShortcutRecordingMotionPolicy.shouldPulse(
            isRecording: true,
            animationsEnabled: false,
            reduceMotion: false
        ))
        #expect(!ShortcutRecordingMotionPolicy.shouldPulse(
            isRecording: true,
            animationsEnabled: true,
            reduceMotion: true
        ))
    }

    @Test("The ClassGod splash remains visible in instant mode")
    func resolvesLaunchDelay() {
        #expect(LaunchWindowPresentationPolicy.splashDelay(preferred: 2, animationDuration: 0) == 1)
        #expect(LaunchWindowPresentationPolicy.splashDelay(preferred: 2, animationDuration: 0.2) == 2)
    }

    @Test("Launch presentation routes through the permission gate")
    func resolvesInitialWindowPresentation() {
        #expect(LaunchWindowPresentationPolicy.destination(isPermissionGateUnlocked: true) == .mainPanel)
        #expect(LaunchWindowPresentationPolicy.destination(isPermissionGateUnlocked: false) == .permissionGate)
        #expect(LaunchWindowPresentationPolicy.shouldResetBeforeInitialShow(isVisible: true, isKeyWindow: false))
        #expect(!LaunchWindowPresentationPolicy.shouldResetBeforeInitialShow(isVisible: false, isKeyWindow: false))
        #expect(!LaunchWindowPresentationPolicy.shouldResetBeforeInitialShow(isVisible: true, isKeyWindow: true))

        var tracker = LaunchDestinationTracker()
        let firstGate = tracker.transition(to: .permissionGate)
        let repeatedGate = tracker.transition(to: .permissionGate)
        let firstPanel = tracker.transition(to: .mainPanel)
        let repeatedPanel = tracker.transition(to: .mainPanel)
        #expect(firstGate)
        #expect(!repeatedGate)
        #expect(firstPanel)
        #expect(!repeatedPanel)
    }

    @Test("Chaos completion advances without animation callbacks")
    func completesChaosWindowsDeterministically() {
        var progress = LaunchChaosProgress(totalWindows: 2)

        let first = progress.recordClosedWindow()
        let second = progress.recordClosedWindow()
        let third = progress.recordClosedWindow()

        #expect(!first)
        #expect(second)
        #expect(third)
    }

    @Test("Overlapping sounds reuse idle channels and stay bounded")
    func selectsSoundChannels() {
        #expect(SoundPlaybackPolicy.channelIndex(isPlaying: [true, false], limit: 4) == 1)
        #expect(SoundPlaybackPolicy.channelIndex(isPlaying: [true, true], limit: 4) == 2)
        #expect(SoundPlaybackPolicy.channelIndex(isPlaying: [true, true, true, true], limit: 4) == nil)
        #expect(SoundPlaybackPolicy.channelIndex(isPlaying: [false], limit: 0) == nil)
        #expect(!SoundPlaybackPolicy.shouldPlay(
            name: "Tink",
            previousName: "Tink",
            elapsed: 0.01,
            minimumInterval: 0.04,
            allowsOverlap: false
        ))
        #expect(SoundPlaybackPolicy.shouldPlay(
            name: "Tink",
            previousName: "Tink",
            elapsed: 0.01,
            minimumInterval: 0.04,
            allowsOverlap: true
        ))
        #expect(SoundPlaybackPolicy.shouldPlay(
            name: "Ping",
            previousName: "Tink",
            elapsed: 0.01,
            minimumInterval: 0.04,
            allowsOverlap: false
        ))
    }

    @Test("Feature windows use complete semantic sound routes")
    func resolvesFeatureWindowSounds() {
        let features = [
            "preflight", "destintab", "superswitch", "browserbypasser", "assessprephack",
            "hackerdesktop", "fancontrol", "activitymonitor", "permissioncenter", "errorhub",
            "ghostprotocol", "clipo", "notes", "todo", "schedule", "focusflow", "settings",
            "wallpaper", "fakelock",
        ]
        for feature in features {
            #expect(WindowSoundPolicy.openSoundName(feature: feature) != nil)
            #expect(WindowSoundPolicy.closeSoundName(feature: feature) != nil)
        }
        #expect(WindowSoundPolicy.openSoundName(feature: "preflight") == "Morse")
        #expect(WindowSoundPolicy.openSoundName(feature: "notes") == "Glass")
        #expect(WindowSoundPolicy.openSoundName(feature: "todo") == "Ping")
        #expect(WindowSoundPolicy.openSoundName(feature: "schedule") == "Morse")
        #expect(WindowSoundPolicy.openSoundName(feature: "focusflow") == "Bottle")
        #expect(WindowSoundPolicy.openSoundName(feature: "settings") == "Glass")
        #expect(WindowSoundPolicy.openSoundName(feature: "wallpaper") == "Blow")
        #expect(SoundEffect.focusCompleted.systemSoundName == "Glass")
        #expect(SoundEffect.breakCompleted.systemSoundName == "Ping")
        #expect(WindowSoundPolicy.closeSoundName(feature: "notes") == "Tink")
        #expect(WindowSoundPolicy.closeSoundName(feature: "todo") == "Tink")
        #expect(WindowSoundPolicy.closeSoundName(feature: "schedule") == "Tink")
        #expect(WindowSoundPolicy.openSoundName(feature: "unknown") == nil)
        #expect(WindowSoundPolicy.closeSoundName(feature: "unknown") == nil)
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
