import Foundation

struct HardwareReadings {
    let fans: [[String: Any]]
    let temps: [[String: Any]]
    let source: String

    static func merge(
        smcFans: [[String: Any]],
        smcTemps: [[String: Any]],
        powerMetricsFans: [[String: Any]],
        powerMetricsTemps: [[String: Any]],
        hidTemps: [[String: Any]]
    ) -> HardwareReadings {
        let fans = smcFans.isEmpty ? powerMetricsFans : smcFans
        let temps = smcTemps.isEmpty
            ? (powerMetricsTemps.isEmpty ? hidTemps : powerMetricsTemps)
            : smcTemps

        var sources: [String] = []
        if !smcFans.isEmpty || !smcTemps.isEmpty { sources.append("smc") }
        if smcFans.isEmpty && !powerMetricsFans.isEmpty ||
            smcTemps.isEmpty && !powerMetricsTemps.isEmpty {
            sources.append("powermetrics")
        }
        if smcTemps.isEmpty && powerMetricsTemps.isEmpty && !hidTemps.isEmpty {
            sources.append("hid")
        }

        return HardwareReadings(
            fans: fans,
            temps: temps,
            source: sources.isEmpty ? "none" : sources.joined(separator: "+")
        )
    }
}

enum PowerMetricsSamplingPolicy {
    static func shouldContinue(
        needsFans: Bool,
        needsTemps: Bool,
        sampledFans: Int,
        sampledTemps: Int
    ) -> Bool {
        needsFans && sampledFans > 0 || needsTemps && sampledTemps > 0
    }
}
