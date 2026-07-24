import Foundation
import Testing
@testable import ClassGod

@Suite("Fan refresh policy")
struct FanRefreshPolicyTests {
    @Test("Default refreshes twice per second")
    func defaultInterval() {
        #expect(AppPreferences.default.fanControlUpdateInterval == 0.5)
        #expect(FanRefreshPolicy.defaultInterval == 0.5)
    }

    @Test("Refresh interval never falls below the hardware-safe minimum")
    func clampsInterval() {
        #expect(FanRefreshPolicy.normalized(0) == 0.5)
        #expect(FanRefreshPolicy.normalized(0.25) == 0.5)
        #expect(FanRefreshPolicy.normalized(2) == 2)
    }

    @Test("Existing preferences adopt the new realtime default once")
    func migratesExistingDefault() throws {
        let data = Data(#"{"version":3,"fanControlUpdateInterval":1}"#.utf8)
        let preferences = try JSONDecoder().decode(AppPreferences.self, from: data)
        #expect(preferences.fanControlUpdateInterval == 0.5)
        #expect(preferences.version == AppPreferences.default.version)
    }

    @Test("Overlapping refresh ticks are coalesced")
    func coalescesRefreshes() {
        var gate = FanRefreshGate()
        let first = gate.begin()
        let overlapping = gate.begin()
        #expect(first)
        #expect(!overlapping)
        gate.end()
        let next = gate.begin()
        #expect(next)
    }
}
