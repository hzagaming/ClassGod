import Testing
@testable import ClassGodHelper

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
        environment: ["SUDO_UID": "502"]
    ) == 502)
    #expect(HelperPeerPolicy.allowedUID(arguments: ["ClassGodHelper"], environment: [:]) == nil)
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

@Test("Missing SMC fan data is filled without replacing SMC temperatures")
func hardwareReadingsMerge() {
    let smcTemps: [[String: Any]] = [["key": "TC0D", "value": 55.0]]
    let fallbackFans: [[String: Any]] = [["id": 0, "actualRPM": 2_000.0]]
    let fallbackTemps: [[String: Any]] = [["key": "PMCPU", "value": 60.0]]
    let hidTemps: [[String: Any]] = [["key": "HID_CPU", "value": 58.0]]

    let readings = HardwareReadings.merge(
        smcFans: [],
        smcTemps: smcTemps,
        powerMetricsFans: fallbackFans,
        powerMetricsTemps: fallbackTemps,
        hidTemps: hidTemps
    )

    #expect(readings.fans.count == 1)
    #expect(readings.temps.count == 1)
    #expect(readings.temps.first?["key"] as? String == "TC0D")
    #expect(readings.source == "smc+powermetrics")
}

@Test("Power metrics only stays active for data that has no independent source")
func powerMetricsSamplingPolicy() {
    #expect(PowerMetricsSamplingPolicy.shouldContinue(
        needsFans: true,
        needsTemps: false,
        sampledFans: 1,
        sampledTemps: 1
    ))
    #expect(!PowerMetricsSamplingPolicy.shouldContinue(
        needsFans: true,
        needsTemps: false,
        sampledFans: 0,
        sampledTemps: 1
    ))
    #expect(PowerMetricsSamplingPolicy.shouldContinue(
        needsFans: false,
        needsTemps: true,
        sampledFans: 0,
        sampledTemps: 1
    ))
}
