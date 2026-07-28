import Testing
import Foundation
@testable import ClassGod

@Suite("Fan control routing")
struct FanControlRoutingTests {
    @Test("Direct SMC fan readings only decode the declared fpe2 format")
    func validatesFanRPMDataType() {
        #expect(FanRecognition.supportsSMCRPMDataType("fpe2"))
        #expect(!FanRecognition.supportsSMCRPMDataType("flt "))
        #expect(!FanRecognition.supportsSMCRPMDataType("sp78"))
    }

    @Test("Direct SMC temperatures reject unrelated byte formats")
    func validatesTemperatureDataType() {
        #expect(SMCReadingFormat.supportsTemperature("sp78"))
        #expect(SMCReadingFormat.supportsTemperature("SP7A"))
        #expect(!SMCReadingFormat.supportsTemperature("fpe2"))
        #expect(!SMCReadingFormat.supportsTemperature("flt "))
    }

    @Test("Partial fan sources merge into one complete hardware record")
    func mergesFanRecognitionSources() {
        var helperFan = FanInfo(id: 0, name: "Left Side")
        helperFan.isControllable = true

        var directFan = FanInfo(id: 0, name: "Left Fan")
        directFan.actualRPM = 2_150
        directFan.minimumRPM = 1_200
        directFan.maximumRPM = 6_100
        directFan.targetRPM = 2_200
        directFan.hasLiveRPM = true

        let merged = FanRecognition.merge(primary: [helperFan], supplementary: [directFan])

        #expect(merged.count == 1)
        #expect(merged[0].actualRPM == 2_150)
        #expect(merged[0].minimumRPM == 1_200)
        #expect(merged[0].maximumRPM == 6_100)
        #expect(merged[0].targetRPM == 2_200)
        #expect(merged[0].canControl)
    }

    @Test("A supplementary source never replaces a valid live RPM")
    func preservesPreferredFanReading() {
        var helperFan = FanInfo(id: 1, name: "Right Side")
        helperFan.actualRPM = 2_400
        helperFan.hasLiveRPM = true

        var fallbackFan = FanInfo(id: 1, name: "Fan 2")
        fallbackFan.actualRPM = 2_100
        fallbackFan.minimumRPM = 1_100
        fallbackFan.maximumRPM = 5_900
        fallbackFan.hasLiveRPM = true

        let merged = FanRecognition.merge(primary: [helperFan], supplementary: [fallbackFan])

        #expect(merged[0].actualRPM == 2_400)
        #expect(merged[0].minimumRPM == 1_100)
        #expect(merged[0].maximumRPM == 5_900)
    }

    @Test("A valid supplementary RPM range replaces an invalid primary range")
    func repairsInvalidFanRange() {
        var primary = FanInfo(id: 0, name: "Left", minimumRPM: 9_000, maximumRPM: 5_000)
        primary.isControllable = true
        let supplementary = FanInfo(id: 0, name: "Left", minimumRPM: 1_200, maximumRPM: 6_100)

        let merged = FanRecognition.merge(primary: [primary], supplementary: [supplementary])

        #expect(merged[0].minimumRPM == 1_200)
        #expect(merged[0].maximumRPM == 6_100)
    }

    @Test("Duplicate fan identifiers prefer a plausible live reading")
    func handlesDuplicatePrimaryFanIDs() {
        let detected = FanInfo(id: 0, name: "Detected")
        let live = FanInfo(id: 0, name: "Left", actualRPM: 2_200, hasLiveRPM: true)

        let merged = FanRecognition.merge(primary: [detected, live], supplementary: [])

        #expect(merged.count == 1)
        #expect(merged[0].actualRPM == 2_200)
        #expect(merged[0].hasLiveRPM)
    }

    @Test("IORegistry does not guess units for opaque sensor bytes")
    func rejectsUntypedRegistrySensorBytes() {
        #expect(IORegistrySensorReading.rpm(from: Data([0x00, 0x70])) == nil)
        #expect(IORegistrySensorReading.temperature(from: Data([0x64, 0x00])) == nil)
        #expect(IORegistrySensorReading.rpm(from: NSNumber(value: 2_300)) == 2_300)
        #expect(IORegistrySensorReading.temperature(from: NSNumber(value: 52.5)) == 52.5)
    }

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
