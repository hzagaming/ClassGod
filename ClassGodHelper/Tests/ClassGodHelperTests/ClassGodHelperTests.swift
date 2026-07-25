import Testing
@testable import ClassGodHelper

@Test("SMC protocol matches the AppleSMC ABI")
func smcProtocolLayout() {
    #expect(MemoryLayout<SMCKeyData>.size == 80)
    #expect(MemoryLayout<SMCKeyData>.offset(of: \.data8) == 42)
    #expect(MemoryLayout<SMCKeyData>.offset(of: \.data32) == 44)
    #expect(MemoryLayout<SMCKeyData>.offset(of: \.bytes) == 48)
    #expect(Array(SMCBytes([1, 2, 3]).array.prefix(4)) == [1, 2, 3, 0])
}

@Test("Helper peer policy prefers an explicit app user")
func explicitHelperPeerUID() {
    #expect(HelperPeerPolicy.allowedUID(
        arguments: ["ClassGodHelper", "--allowed-uid", "501"],
        environment: ["SUDO_UID": "502"]
    ) == 501)
}

@Test("Helper peer policy supports sudo and otherwise fails closed")
func sudoHelperPeerUID() {
    #expect(HelperPeerPolicy.allowedUID(
        arguments: ["ClassGodHelper"],
        environment: ["SUDO_UID": "502"],
        consoleUID: nil
    ) == 502)
    #expect(HelperPeerPolicy.allowedUID(
        arguments: ["ClassGodHelper"],
        environment: [:],
        consoleUID: 503
    ) == 503)
    #expect(HelperPeerPolicy.allowedUID(
        arguments: ["ClassGodHelper"],
        environment: [:],
        consoleUID: nil
    ) == nil)
    #expect(HelperPeerPolicy.allowedUID(
        arguments: ["ClassGodHelper", "--allowed-uid", "invalid"],
        environment: ["SUDO_UID": "502"]
    ) == nil)
}

@Test("Fan keys only accept actual-RPM SMC keys")
func fanKeyParsing() {
    #expect(FanSMCKey("F0Ac")?.index == 0)
    #expect(FanSMCKey("F9Ac")?.index == 9)
    #expect(FanSMCKey("FAAc")?.index == 10)
    #expect(FanSMCKey("F1Mn") == nil)
    #expect(FanSMCKey("FNum") == nil)
    #expect(FanSMCKey("FS! ") == nil)
}

@Test("Fan index maps back to four-character SMC keys")
func fanKeyGeneration() {
    #expect(FanSMCKey.actualRPMKey(for: 0) == "F0Ac")
    #expect(FanSMCKey.actualRPMKey(for: 10) == "FAAc")
    #expect(FanSMCKey.actualRPMKey(for: 15) == "FFAc")
    #expect(FanSMCKey.actualRPMKey(for: 16) == nil)
    #expect(FanSMCKey("FAAc")?.key(suffix: "Tg") == "FATg")
}

@Test("Forced fan mask uses the physical fan ID without changing other fans")
func forcedFanMask() {
    #expect(FanControlForceMask.updated([0x00, 0x01], fanIndex: 3, forced: true) == [0x00, 0x09])
    #expect(FanControlForceMask.updated([0x00, 0x09], fanIndex: 0, forced: false) == [0x00, 0x08])
    #expect(FanControlForceMask.updated([0x00, 0x00], fanIndex: 16, forced: true) == nil)
}

@Test("Fan targets are clamped to the hardware range")
func fanTargetClamping() {
    #expect(FanControlTarget.clamped(500, minimum: 1_200, maximum: 6_000) == 1_200)
    #expect(FanControlTarget.clamped(7_000, minimum: 1_200, maximum: 6_000) == 6_000)
    #expect(FanControlTarget.clamped(3_200, minimum: 1_200, maximum: 6_000) == 3_200)
    #expect(FanControlTarget.clamped(3_200, minimum: 0, maximum: 0) == nil)
}

@Test("Modes without an RPM target release stale forced control")
func safeFanModeTransition() {
    #expect(FanControlModeTransition(mode: "system") == .releaseToSystem)
    #expect(FanControlModeTransition(mode: "autoMax") == .releaseToSystem)
    #expect(FanControlModeTransition(mode: "manual") == .releaseToSystem)
    #expect(FanControlModeTransition(mode: "custom") == .releaseToSystem)
    #expect(FanControlModeTransition(mode: "max") == .forceMaximum)
    #expect(FanControlModeTransition(mode: "invalid") == nil)
}

@Test("No-op capability probes require an exact write-back")
func fanWriteVerification() {
    #expect(FanControlWriteVerification.matches(expected: [0x00, 0x01], actual: [0x00, 0x01]))
    #expect(FanControlWriteVerification.matches(expected: [0x01], actual: [0x01, 0x00]))
    #expect(!FanControlWriteVerification.matches(expected: [0x00, 0x01], actual: [0x00]))
    #expect(!FanControlWriteVerification.matches(expected: [0x00, 0x01], actual: [0x00, 0x02]))
    #expect(!FanControlWriteVerification.matches(expected: [0x00], actual: nil))
}

@Test("Invalid SMC fan ranges are rejected before fallback selection")
func fanReadingValidity() {
    #expect(FanReadingValidity.isPlausible(actual: 0, minimum: 1_200, maximum: 6_000))
    #expect(FanReadingValidity.isPlausible(actual: 2_400, minimum: 1_200, maximum: 6_000))
    #expect(!FanReadingValidity.isPlausible(actual: 0, minimum: 52, maximum: 36))
    #expect(!FanReadingValidity.isPlausible(actual: 25_000, minimum: 1_200, maximum: 6_000))
}

@Test("Power metrics parses current fan output variants")
func powerMetricsFanParsing() {
    let readings = PowerMetricsParser.parse("""
    CPU die temperature: 54.5 C
    Fan: 2100 rpm
    Fan 1: 2250 rpm
    Fan 2 speed: 2300.5 rpm
    """)
    #expect(readings.temps.count == 1)
    #expect(readings.fans.count == 3)
    #expect(readings.fans[0]["actualRPM"] as? Double == 2_100)
    #expect(readings.fans[1]["id"] as? Int == 1)
    #expect(readings.fans[1]["name"] as? String == "Fan 1")
    #expect(readings.fans[2]["id"] as? Int == 2)
    #expect(readings.fans[2]["name"] as? String == "Fan 2")
    #expect(readings.fans[2]["actualRPM"] as? Double == 2_300.5)
}

@Test("Fallback fans and HID temperatures supplement SMC readings")
func hardwareReadingsMerge() {
    let smcTemps: [[String: Any]] = [["key": "TC0D", "value": 55.0]]
    let detectedFans: [[String: Any]] = [["id": 0, "hasLiveRPM": false]]
    let fallbackFans: [[String: Any]] = [["id": 0, "actualRPM": 2_000.0]]
    let fallbackTemps: [[String: Any]] = [["key": "PMCPU", "value": 60.0]]
    let hidTemps: [[String: Any]] = [["key": "HID_CPU", "value": 58.0]]

    let readings = HardwareReadings.merge(
        smcFans: detectedFans,
        smcTemps: smcTemps,
        powerMetricsFans: fallbackFans,
        powerMetricsTemps: fallbackTemps,
        hidTemps: hidTemps
    )

    #expect(readings.fans.count == 1)
    #expect(readings.temps.count == 2)
    #expect(readings.temps.first?["key"] as? String == "TC0D")
    #expect(readings.temps.last?["key"] as? String == "HID_CPU")
    #expect(readings.source == "smc+powermetrics+hid")
}

@Test("Fallback fills only SMC fans without a live RPM")
func partialFanFallbackMerge() {
    let readings = HardwareReadings.merge(
        smcFans: [
            ["id": 0, "actualRPM": 2_000.0, "hasLiveRPM": true],
            ["id": 1, "hasLiveRPM": false],
        ],
        smcTemps: [],
        powerMetricsFans: [
            ["id": 0, "actualRPM": 2_100.0, "hasLiveRPM": true],
            ["id": 1, "actualRPM": 2_300.0, "hasLiveRPM": true],
        ],
        powerMetricsTemps: [],
        hidTemps: []
    )

    #expect(readings.fans.count == 2)
    #expect(readings.fans[0]["actualRPM"] as? Double == 2_000)
    #expect(readings.fans[1]["actualRPM"] as? Double == 2_300)
    #expect(readings.source == "smc+powermetrics")
}

@Test("Sampler fallback recognizes unsupported sampler errors")
func powerMetricsSamplerFallbackPolicy() {
    #expect(PowerMetricsSamplerSelection.shouldUseThermalFallback(
        error: "powermetrics: unrecognized sampler: smc"
    ))
    #expect(PowerMetricsSamplerSelection.shouldUseThermalFallback(
        error: "powermetrics: unknown sampler smc"
    ))
    #expect(!PowerMetricsSamplerSelection.shouldUseThermalFallback(
        error: "powermetrics must be invoked as the superuser"
    ))
}

@Test("Power metrics only stays active for data that has no independent source")
func powerMetricsSamplingPolicy() {
    #expect(PowerMetricsSamplingPolicy.shouldContinue(
        needsFans: true,
        needsTemps: false,
        sampledFans: 1,
        sampledTemps: 1
    ))
    #expect(PowerMetricsSamplingPolicy.shouldContinue(
        needsFans: true,
        needsTemps: false,
        sampledFans: 0,
        sampledTemps: 1,
        consecutiveMisses: 1
    ))
    #expect(!PowerMetricsSamplingPolicy.shouldContinue(
        needsFans: true,
        needsTemps: false,
        sampledFans: 0,
        sampledTemps: 1,
        consecutiveMisses: PowerMetricsSamplingPolicy.maximumConsecutiveMisses
    ))
    #expect(PowerMetricsSamplingPolicy.shouldContinue(
        needsFans: false,
        needsTemps: true,
        sampledFans: 0,
        sampledTemps: 1
    ))
}
