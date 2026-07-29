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
}
