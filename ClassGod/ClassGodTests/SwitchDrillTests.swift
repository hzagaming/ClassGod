import Foundation
import Testing
@testable import ClassGod

@Suite("Switch Drill")
struct SwitchDrillTests {
    @Test("Only registered unique targets can enter the rehearsal catalog")
    func filtersTargets() {
        let first = SwitchDrillTarget(id: UUID(), name: "Study", shortcut: "⌘1", kind: .browser)
        let second = SwitchDrillTarget(id: UUID(), name: "Notes", shortcut: "⌘2", kind: .application)
        #expect(SwitchDrillTarget.available([first, second], registeredIDs: [first.id]) == [first])
        #expect(SwitchDrillTarget.available([first, first], registeredIDs: [first.id]).isEmpty)
    }

    @Test("The cue uses its actual presentation time and separates reaction from switching")
    func measuresActualCue() throws {
        var drill = SwitchDrillSession()
        let target = UUID()
        #expect(drill.start(targetID: target, now: 10, delay: 2) == true)
        drill.tick(now: 11)
        #expect(drill.phase == .waiting)
        drill.tick(now: 14)
        #expect(drill.phase == .ready)
        let pressed = drill.press(targetID: target, now: 14.25)
        let request = try #require(pressed)
        #expect(drill.phase == .switching)
        #expect(drill.complete(requestID: request, success: true, now: 14.75) == true)
        #expect(drill.result?.outcome == .success)
        #expect(drill.result?.reactionSeconds == 0.25)
        #expect(drill.result?.switchSeconds == 0.5)
        #expect(drill.complete(requestID: request, success: true, now: 15) == false)
    }

    @Test("Early and wrong shortcuts do not produce a successful score")
    func rejectsWrongTimingAndTarget() {
        var drill = SwitchDrillSession()
        let target = UUID()
        _ = drill.start(targetID: target, now: 0, delay: 2)
        #expect(drill.press(targetID: target, now: 1) == nil)
        #expect(drill.result?.outcome == .tooSoon)
        _ = drill.start(targetID: target, now: 10, delay: 2)
        drill.tick(now: 12)
        #expect(drill.press(targetID: UUID(), now: 12.2) == nil)
        #expect(drill.result?.outcome == .wrongTarget)
    }

    @Test("Missed cues and missing completion callbacks time out at their boundaries")
    func timesOut() throws {
        var drill = SwitchDrillSession()
        let target = UUID()
        _ = drill.start(targetID: target, now: 0, delay: 2)
        drill.tick(now: 2)
        drill.tick(now: 12)
        #expect(drill.result?.outcome == .timeout)
        _ = drill.start(targetID: target, now: 20, delay: 2)
        drill.tick(now: 22)
        let pressed = drill.press(targetID: target, now: 22.1)
        let request = try #require(pressed)
        drill.tick(now: 37.1)
        #expect(drill.result?.outcome == .switchFailed)
        #expect(drill.complete(requestID: request, success: true, now: 38) == false)
    }

    @Test("Cancelled, replaced, and interrupted runs reject stale success callbacks")
    func rejectsStaleResults() throws {
        var drill = SwitchDrillSession()
        let target = UUID()
        _ = drill.start(targetID: target, now: 0, delay: 2)
        drill.tick(now: 2)
        let firstPress = drill.press(targetID: target, now: 3)
        let old = try #require(firstPress)
        drill.cancel()
        _ = drill.start(targetID: target, now: 4, delay: 2)
        #expect(drill.complete(requestID: old, success: true, now: 5) == false)
        drill.tick(now: 6)
        let nextPress = drill.press(targetID: target, now: 7)
        let current = try #require(nextPress)
        #expect(drill.press(targetID: target, now: 7.1) == nil)
        #expect(drill.result?.outcome == .interrupted)
        #expect(drill.complete(requestID: current, success: true, now: 8) == false)
    }

    @Test("Invalid time values and backwards time cannot produce bogus scores")
    func validatesClock() {
        var drill = SwitchDrillSession()
        let target = UUID()
        #expect(drill.start(targetID: target, now: .nan, delay: 2) == false)
        #expect(drill.start(targetID: target, now: 0, delay: .infinity) == false)
        _ = drill.start(targetID: target, now: 10, delay: 2)
        drill.tick(now: 12)
        #expect(drill.press(targetID: target, now: 11) == nil)
        #expect(drill.phase == .idle)
    }

    @Test("Changing a configured target cancels the active exercise")
    @MainActor
    func cancelsChangedTargets() {
        let target = SwitchDrillTarget(id: UUID(), name: "Study", shortcut: "⌘1", kind: .browser)
        let service = SwitchDrillService(clock: { 10 })
        service.updateTargets([target])
        #expect(service.start(delay: 2))
        service.updateTargets([])
        #expect(!service.session.isActive)
        #expect(service.selectedID == nil)
        service.cancel()
    }

    @Test("Changing a destination under the same name and shortcut invalidates a round")
    @MainActor
    func cancelsChangedDestination() {
        let target = SwitchDrillTarget(id: UUID(), name: "Study", shortcut: "⌘1", kind: .browser, destination: "https://example.com/one")
        let service = SwitchDrillService(clock: { 10 })
        service.updateTargets([target])
        #expect(service.start(delay: 2))
        service.updateTargets([SwitchDrillTarget(id: target.id, name: target.name, shortcut: target.shortcut, kind: .browser, destination: "https://example.com/two")])
        #expect(!service.session.isActive)
        service.cancel()
    }

    @Test("Replacing a finished target clears its score panel without losing recent history")
    @MainActor
    func clearsMismatchedResult() {
        var now: TimeInterval = 10
        let target = SwitchDrillTarget(id: UUID(), name: "Study", shortcut: "⌘1", kind: .browser)
        let service = SwitchDrillService(clock: { now })
        service.updateTargets([target])
        #expect(service.start(delay: 2))
        now = 13
        service.refreshTime()
        now = 13.25
        let request = service.shortcutPressed(targetID: target.id)
        now = 13.5
        service.complete(requestID: request, success: true)
        service.updateTargets([SwitchDrillTarget(id: UUID(), name: "Other", shortcut: "⌘2", kind: .application)])
        #expect(service.session.phase == .idle)
        #expect(service.session.result == nil)
        #expect(service.recentResults.count == 1)
        service.cancel()
    }

    @Test("Service records results once, bounds history, and cancels pending timer work")
    @MainActor
    func recordsBoundedHistory() {
        var now: TimeInterval = 10
        let target = SwitchDrillTarget(id: UUID(), name: "Study", shortcut: "⌘1", kind: .browser)
        let service = SwitchDrillService(clock: { now })
        service.updateTargets([target])
        for _ in 0..<7 {
            #expect(service.start(delay: 2))
            now += 3
            service.refreshTime()
            #expect(service.session.phase == .ready)
            now += 0.25
            let request = service.shortcutPressed(targetID: target.id)
            now += 0.5
            service.complete(requestID: request, success: true)
            service.complete(requestID: request, success: true)
        }
        #expect(service.recentResults.count == 5)
        #expect(service.recentResults.allSatisfy { $0.outcome == .success && $0.reactionSeconds == 0.25 })
        #expect(service.start(delay: 2))
        service.cancel()
        now += 20
        service.refreshTime()
        #expect(service.session.phase == .idle)
        #expect(service.recentResults.count == 5)
    }
}
