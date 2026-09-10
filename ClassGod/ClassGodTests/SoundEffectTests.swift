import Combine
import Foundation
import Testing
@testable import ClassGod

@Suite("Sound effect lifecycle")
@MainActor
struct SoundEffectTests {
    @Test("Disabling sound stops active audio and invalidates bursts across re-enabling")
    func disablingCancelsPlayback() {
        let rig = SoundRig()
        let manager = rig.manager()
        manager.play(.tabSaved)
        manager.playGlitchBurst(count: 3)
        manager.playCloseBurst(count: 3)
        rig.pending.removeFirst()()
        #expect(rig.sounds.contains { $0.isPlaying })
        rig.enabled.send(false)
        #expect(rig.sounds.allSatisfy { !$0.isPlaying })
        rig.enabled.send(true)
        let previousPlays = rig.sounds.reduce(0) { $0 + $1.playCount }
        rig.pending.forEach { $0() }
        #expect(rig.sounds.reduce(0) { $0 + $1.playCount } == previousPlays)
        manager.play(.switchSuccess)
        #expect(rig.sounds.filter(\.isPlaying).count == 1)
    }

    @Test("Overlap is capped across every tone and idle channels remain reusable")
    func capsTotalOverlap() {
        let rig = SoundRig()
        let manager = rig.manager()
        for name in ["Basso", "Blow", "Bottle", "Frog", "Funk", "Morse", "Sosumi", "Submarine", "Tink"] {
            manager.playSound(named: name, allowsOverlap: true)
        }
        #expect(rig.sounds.filter(\.isPlaying).count == 4)
        #expect(rig.sounds.allSatisfy { $0.volume <= 0.35 })
        rig.sounds.first?.stop()
        manager.playSound(named: "Basso", allowsOverlap: true)
        #expect(rig.sounds.filter(\.isPlaying).count == 4)
        manager.cancelGlitchSounds()
        #expect(rig.sounds.allSatisfy { !$0.isPlaying })
    }

    @Test("Quiet Desk window actions and disabled feedback never allocate audio")
    func respectsSilentActions() {
        let rig = SoundRig()
        let manager = rig.manager()
        manager.playWindowOpen(feature: "quietdesk")
        manager.playWindowClose(feature: "quietdesk")
        manager.playGlitchBurst(count: -1)
        manager.playCloseBurst(count: 0)
        rig.enabled.send(false)
        manager.play(.buttonClick)
        manager.playGlitchBurst(count: 3)
        #expect(rig.sounds.isEmpty)
        #expect(rig.pending.isEmpty)
    }
}

@MainActor
private final class SoundRig {
    let enabled = CurrentValueSubject<Bool, Never>(true)
    var sounds: [FakeEffectSound] = []
    var pending: [() -> Void] = []

    func manager() -> SoundEffectManager {
        SoundEffectManager(enabled: enabled.eraseToAnyPublisher(), makeSound: { _ in
            let sound = FakeEffectSound()
            self.sounds.append(sound)
            return sound
        }, schedule: { _, action in self.pending.append(action) })
    }
}

@MainActor
private final class FakeEffectSound: EffectSound {
    var isPlaying = false
    var volume: Float = 1
    var playCount = 0
    @discardableResult func play() -> Bool { isPlaying = true; playCount += 1; return true }
    @discardableResult func stop() -> Bool { isPlaying = false; return true }
}
