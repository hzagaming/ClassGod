import Foundation
import Testing
@testable import ClassGod

@Suite("Headphone Guard")
@MainActor
struct HeadphoneGuardTests {
    @Test("Arming records the current output and listens once; disarming stops listening")
    func armsAndDisarms() {
        let hardware = GuardHardwareFake()
        let service = hardware.service()
        #expect(!service.isArmed)
        #expect(service.arm())
        #expect(service.guardedDevice == hardware.phones)
        #expect(service.notice == .armed)
        #expect(hardware.registrations == 1)
        #expect(!service.arm())
        #expect(hardware.registrations == 1)
        service.disarm()
        #expect(!service.isArmed)
        #expect(hardware.removals == 1)
        #expect(service.notice == .disarmed)
        #expect(hardware.writes.isEmpty)
    }

    @Test("Moving audio away from the guarded headphones mutes the new output and verifies it")
    func mutesNewOutput() {
        let hardware = GuardHardwareFake()
        let service = hardware.service()
        #expect(service.arm())
        hardware.route(to: hardware.speakers)
        #expect(hardware.writes.map(\.uid) == ["speakers"])
        #expect(hardware.states["speakers"] == true)
        #expect(service.silenced == [hardware.speakers])
        #expect(service.lastTrip == HeadphoneGuardTrip(device: hardware.speakers, date: hardware.now, outcome: .silenced))
        #expect(service.currentOutput == hardware.speakers)
        #expect(service.currentMuted == true)
        #expect(service.isArmed)
    }

    @Test("Returning to the headphones or reaching an already silent output performs no write")
    func ignoresSafeRoutes() {
        let hardware = GuardHardwareFake()
        let service = hardware.service()
        #expect(service.arm())
        hardware.route(to: hardware.phones)
        #expect(service.lastTrip == nil)
        hardware.states["speakers"] = true
        hardware.route(to: hardware.speakers)
        #expect(hardware.writes.isEmpty)
        #expect(service.lastTrip?.outcome == .alreadySilent)
        #expect(service.silenced.isEmpty)
    }

    @Test("Every new destination is silenced once, including projector outputs")
    func silencesEveryDestination() {
        let hardware = GuardHardwareFake()
        let service = hardware.service()
        #expect(service.arm())
        hardware.route(to: hardware.speakers)
        hardware.route(to: hardware.phones)
        hardware.route(to: hardware.projector)
        hardware.route(to: hardware.speakers)
        #expect(service.silenced == [hardware.speakers, hardware.projector])
        #expect(hardware.writes.map(\.uid) == ["speakers", "projector"])
        #expect(service.lastTrip?.outcome == .alreadySilent)
    }

    @Test("Outputs without mute control or with rejected writes never claim protection")
    func reportsUnprotectedOutputs() {
        let hardware = GuardHardwareFake()
        let service = hardware.service()
        #expect(service.arm())
        hardware.states["projector"] = nil
        hardware.route(to: hardware.projector)
        #expect(service.lastTrip?.outcome == .unsupported)
        #expect(hardware.writes.isEmpty)
        hardware.acceptWrites = false
        hardware.route(to: hardware.speakers)
        #expect(service.lastTrip?.outcome == .failed)
        #expect(service.silenced.isEmpty)
    }

    @Test("An accepted but unconfirmed mute still sends an explicit restoration")
    func restoresUnconfirmedMute() {
        let hardware = GuardHardwareFake()
        let service = hardware.service()
        #expect(service.arm())
        hardware.ignoreWrites = true
        hardware.route(to: hardware.speakers)
        #expect(service.lastTrip?.outcome == .failed)
        #expect(service.silenced == [hardware.speakers])
        hardware.ignoreWrites = false
        #expect(service.restore())
        #expect(hardware.writes.map(\.muted) == [true, false])
        #expect(service.silenced.isEmpty)
    }

    @Test("Restoration unmutes only guard-muted outputs and keeps failures for retry")
    func restoresOwnMutes() {
        let hardware = GuardHardwareFake()
        let service = hardware.service()
        #expect(!service.restore())
        #expect(service.arm())
        hardware.route(to: hardware.speakers)
        hardware.connected = false
        #expect(!service.restore())
        #expect(service.notice == .restoreFailed)
        #expect(service.silenced == [hardware.speakers])
        hardware.connected = true
        #expect(service.restore())
        #expect(hardware.states["speakers"] == false)
        #expect(hardware.states["phones"] == false)
        #expect(service.notice == .restored)
        #expect(service.silenced.isEmpty)
    }

    @Test("External unmuting is respected without another hardware write")
    func respectsExternalUnmute() {
        let hardware = GuardHardwareFake()
        let service = hardware.service()
        #expect(service.arm())
        hardware.route(to: hardware.speakers)
        hardware.states["speakers"] = false
        #expect(service.restore())
        #expect(hardware.writes.count == 1)
    }

    @Test("Disarming keeps protective mutes; shutdown disarms and restores them")
    func shutsDown() {
        let hardware = GuardHardwareFake()
        let service = hardware.service()
        #expect(service.arm())
        hardware.route(to: hardware.speakers)
        service.disarm()
        #expect(hardware.states["speakers"] == true)
        #expect(service.silenced == [hardware.speakers])
        #expect(service.arm())
        service.shutdown()
        #expect(!service.isArmed)
        #expect(hardware.removals == 2)
        #expect(hardware.states["speakers"] == false)
    }

    @Test("Arming fails safely without an output or a route listener")
    func refusesUnavailableArming() {
        let hardware = GuardHardwareFake()
        hardware.output = nil
        let service = hardware.service()
        #expect(!service.arm())
        #expect(service.notice == .unavailable)
        hardware.output = hardware.phones
        hardware.listenerAvailable = false
        #expect(!service.arm())
        #expect(service.notice == .unavailable)
        #expect(!service.isArmed)
        #expect(hardware.registrations == 0)
    }

    @Test("Late route callbacks after disarming are ignored")
    func ignoresStaleCallbacks() {
        let hardware = GuardHardwareFake()
        let service = hardware.service()
        #expect(service.arm())
        let stale = hardware.handler
        service.disarm()
        hardware.output = hardware.speakers
        stale?()
        #expect(hardware.writes.isEmpty)
        #expect(service.lastTrip == nil)
    }

    @Test("The Core Audio route listener registers and unregisters cleanly")
    func registersSystemListener() {
        let cancel = HeadphoneGuardHardware.observeDefaultOutput {}
        #expect(cancel != nil)
        cancel?()
    }
}

@MainActor
private final class GuardHardwareFake {
    let phones = QuietDevice(uid: "phones", name: "Headphones / 耳机")
    let speakers = QuietDevice(uid: "speakers", name: "Built-in speakers / 扬声器")
    let projector = QuietDevice(uid: "projector", name: "Classroom projector / 投影仪")
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    lazy var output: QuietDevice? = phones
    var states: [String: Bool] = ["phones": false, "speakers": false, "projector": false]
    var connected = true
    var acceptWrites = true
    var ignoreWrites = false
    var listenerAvailable = true
    var writes: [(uid: String, muted: Bool)] = []
    var registrations = 0
    var removals = 0
    var handler: (@MainActor () -> Void)?

    func service() -> HeadphoneGuardService {
        HeadphoneGuardService(
            defaultOutput: { self.output },
            readMute: { self.connected ? self.states[$0.uid] : nil },
            writeMute: { device, value in
                self.writes.append((device.uid, value))
                guard self.connected, self.acceptWrites, self.states[device.uid] != nil else { return false }
                if !self.ignoreWrites { self.states[device.uid] = value }
                return true
            },
            observeOutput: { handler in
                guard self.listenerAvailable else { return nil }
                self.registrations += 1
                self.handler = handler
                return { self.removals += 1; self.handler = nil }
            },
            clock: { self.now }
        )
    }

    func route(to device: QuietDevice) {
        output = device
        handler?()
    }
}
