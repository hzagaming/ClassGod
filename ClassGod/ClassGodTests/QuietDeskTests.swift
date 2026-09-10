import Testing
@testable import ClassGod

@Suite("Quiet Desk")
@MainActor
struct QuietDeskTests {
    @Test("Muting is explicit and repeated clicks cannot overwrite the restoration device")
    func mutesOnce() {
        let hardware = QuietHardwareFake()
        let service = hardware.service()
        #expect(hardware.writes.isEmpty)
        #expect(service.mute() == true)
        #expect(service.restoreDevice?.uid == "one")
        #expect(service.mute() == false)
        #expect(hardware.writes.count == 1)
        #expect(service.restore() == true)
        #expect(hardware.states["one"] == false)
        #expect(service.restoreDevice == nil)
    }

    @Test("An already muted device never creates a restoration that could unmute it")
    func preservesExistingMute() {
        let hardware = QuietHardwareFake()
        hardware.states["one"] = true
        let service = hardware.service()
        #expect(service.mute() == false)
        #expect(service.notice == .alreadyMuted)
        #expect(service.restoreDevice == nil)
        #expect(hardware.writes.isEmpty)
    }

    @Test("Restoration resolves the original UID even when the default output changes")
    func restoresOriginalDevice() {
        let hardware = QuietHardwareFake()
        let service = hardware.service()
        #expect(service.mute() == true)
        hardware.output = QuietDevice(uid: "two", name: "Other output")
        hardware.states["two"] = true
        #expect(service.restore() == true)
        #expect(hardware.states["one"] == false)
        #expect(hardware.states["two"] == true)
    }

    @Test("A disconnected device keeps its restoration until a retry succeeds")
    func retriesDisconnectedDevice() {
        let hardware = QuietHardwareFake()
        let service = hardware.service()
        #expect(service.mute() == true)
        hardware.connected = false
        #expect(service.restore() == false)
        #expect(service.notice == .restoreFailed)
        #expect(service.restoreDevice != nil)
        hardware.connected = true
        #expect(service.restore() == true)
    }

    @Test("External unmuting is preserved without another hardware write")
    func preservesExternalChange() {
        let hardware = QuietHardwareFake()
        let service = hardware.service()
        #expect(service.mute() == true)
        hardware.states["one"] = false
        #expect(service.restore() == true)
        #expect(hardware.writes.count == 1)
    }

    @Test("Unsupported devices and rejected writes report failure without claiming success")
    func reportsFailures() {
        let hardware = QuietHardwareFake()
        hardware.states = [:]
        let service = hardware.service()
        #expect(service.mute() == false)
        #expect(service.notice == .unavailable)
        hardware.states["one"] = false
        hardware.acceptWrites = false
        #expect(service.mute() == false)
        #expect(service.notice == .muteFailed)
        #expect(service.restoreDevice == nil)
    }

    @Test("Restoring an unconfirmed mute sends an explicit cancellation to the original device")
    func cancelsUnconfirmedMute() {
        let device = QuietDevice(uid: "one", name: "Output")
        var writes: [Bool] = []
        let service = QuietDeskService(defaultOutput: { device }, readMute: { _ in false }, writeMute: { _, value in
            writes.append(value)
            return true
        })
        #expect(service.mute() == false)
        #expect(service.notice == .muteFailed)
        #expect(service.restoreDevice != nil)
        #expect(service.restore() == true)
        #expect(writes == [true, false])
    }

    @Test("Failed restoration keeps recovery available, and forgetting performs no write")
    func keepsRecoveryOnFailure() {
        let hardware = QuietHardwareFake()
        let service = hardware.service()
        #expect(service.mute() == true)
        hardware.acceptWrites = false
        #expect(service.restore() == false)
        #expect(service.restoreDevice != nil)
        let count = hardware.writes.count
        service.forget()
        #expect(service.restoreDevice == nil)
        #expect(hardware.writes.count == count)
        #expect(hardware.states["one"] == true)
    }
}

@MainActor
private final class QuietHardwareFake {
    var output = QuietDevice(uid: "one", name: "Test output")
    var connected = true
    var acceptWrites = true
    var states: [String: Bool] = ["one": false]
    var writes: [(String, Bool)] = []

    func service() -> QuietDeskService {
        QuietDeskService(
            defaultOutput: { self.output },
            readMute: { self.connected ? self.states[$0.uid] : nil },
            writeMute: { device, value in
                self.writes.append((device.uid, value))
                guard self.connected, self.acceptWrites else { return false }
                self.states[device.uid] = value
                return true
            }
        )
    }
}
