import Testing
@testable import ClassGod

@Suite("Fan control routing")
struct FanControlRoutingTests {
    @Test("App SMC protocol matches the AppleSMC ABI")
    func smcProtocolLayout() {
        #expect(MemoryLayout<SMCKeyData>.size == 80)
        #expect(MemoryLayout<SMCKeyData>.offset(of: \.data8) == 42)
        #expect(MemoryLayout<SMCKeyData>.offset(of: \.data32) == 44)
        #expect(MemoryLayout<SMCKeyData>.offset(of: \.bytes) == 48)
    }

    @Test("Control commands use physical fan IDs")
    func physicalFanIDs() {
        let fans = [
            FanInfo(id: 0, name: "Left", isControllable: false),
            FanInfo(id: 10, name: "Right", minimumRPM: 1_200, maximumRPM: 6_000, hasLiveRPM: true, isControllable: true)
        ]

        #expect(FanControlRouting.position(of: 10, in: fans) == 1)
        #expect(FanControlRouting.controllableIDs(in: fans) == [10])
    }

    @Test("A fan needs both write support and a valid RPM range")
    func controlAvailability() {
        #expect(!FanInfo(id: 1, name: "Read only", minimumRPM: 0, maximumRPM: 8_000).canControl)
        #expect(!FanInfo(id: 2, name: "No range", isControllable: true).canControl)
        #expect(FanInfo(id: 3, name: "Writable", minimumRPM: 1_000, maximumRPM: 5_000, hasLiveRPM: true, isControllable: true).canControl)
        #expect(!FanInfo(id: 4, name: "Invalid", minimumRPM: 52, maximumRPM: 36, hasLiveRPM: true, isControllable: true).canControl)
    }

    @Test("Fan availability never labels missing RPM as realtime")
    func fanAvailability() {
        #expect(FanInfo(id: 0, name: "Detected").availability == .detected)
        #expect(FanInfo(id: 1, name: "Read only", actualRPM: 2_000, hasLiveRPM: true).availability == .readOnly)
        #expect(FanInfo(
            id: 2,
            name: "Writable",
            actualRPM: 2_000,
            minimumRPM: 1_000,
            maximumRPM: 5_000,
            hasLiveRPM: true,
            isControllable: true
        ).availability == .controllable)
    }

    @Test("Average RPM ignores fans without a live reading")
    func liveAverageRPM() {
        let fans = [
            FanInfo(id: 0, name: "Live", actualRPM: 2_400, hasLiveRPM: true),
            FanInfo(id: 1, name: "Detected"),
        ]

        #expect(FanControlRouting.averageLiveRPM(in: fans) == 2_400)
        #expect(FanControlRouting.averageLiveRPM(in: [fans[1]]) == nil)
    }

    @Test("Left and right rules route by physical fan ID")
    func ruleTargetsUsePhysicalIDs() {
        let fans = [
            FanInfo(id: 1, name: "Right", minimumRPM: 1_000, maximumRPM: 5_000, hasLiveRPM: true, isControllable: true),
            FanInfo(id: 0, name: "Left", minimumRPM: 1_000, maximumRPM: 5_000, hasLiveRPM: true, isControllable: true),
        ]

        #expect(FanControlRouting.targetIDs(for: .leftFan, in: fans) == [0])
        #expect(FanControlRouting.targetIDs(for: .rightFan, in: fans) == [1])
        #expect(FanControlRouting.targetIDs(for: .allFans, in: fans) == [1, 0])
    }

    @Test("Missing or estimated sensors cannot trigger rules")
    func missingRuleSensors() {
        let sensors = [
            TemperatureSensor(name: "CPU Die", key: "CPU0", value: 65),
            TemperatureSensor(name: "CPU Estimated", key: "CPU_EST", value: 80, isEstimated: true),
        ]

        #expect(FanRuleSensorResolver.value(for: .highestCPU, specificKey: "missing", sensors: sensors) == nil)
        #expect(FanRuleSensorResolver.value(for: .highestCPU, specificKey: "CPU_EST", sensors: sensors) == nil)
        #expect(FanRuleSensorResolver.value(for: .highestCPU, sensors: sensors) == 65)
        #expect(FanRuleSensorResolver.value(for: .highestGPU, sensors: sensors) == nil)
    }
}
