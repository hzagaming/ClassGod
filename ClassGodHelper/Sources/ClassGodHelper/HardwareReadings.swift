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
        var fans = smcFans
        var usesPowerMetricsFans = false
        for fallback in powerMetricsFans {
            guard let id = fallback["id"] as? Int else { continue }
            if let index = fans.firstIndex(where: { $0["id"] as? Int == id }) {
                guard fans[index]["hasLiveRPM"] as? Bool != true else { continue }
                fans[index] = fallback
            } else {
                fans.append(fallback)
            }
            usesPowerMetricsFans = true
        }
        fans.sort { ($0["id"] as? Int ?? .max) < ($1["id"] as? Int ?? .max) }
        let primaryTemps = smcTemps.isEmpty ? powerMetricsTemps : smcTemps
        var seenTemperatureKeys = Set<String>()
        let temps = (primaryTemps + hidTemps).filter { reading in
            let key = reading["key"] as? String ?? reading["name"] as? String ?? ""
            guard !key.isEmpty, seenTemperatureKeys.insert(key).inserted else { return false }
            return true
        }

        var sources: [String] = []
        if !smcFans.isEmpty || !smcTemps.isEmpty { sources.append("smc") }
        if usesPowerMetricsFans || smcTemps.isEmpty && !powerMetricsTemps.isEmpty {
            sources.append("powermetrics")
        }
        if !hidTemps.isEmpty {
            sources.append("hid")
        }

        return HardwareReadings(
            fans: fans,
            temps: temps,
            source: sources.isEmpty ? "none" : sources.joined(separator: "+")
        )
    }
}

enum PowerMetricsSamplerSelection {
    static func shouldUseThermalFallback(error: String?) -> Bool {
        guard let error = error?.lowercased() else { return false }
        return error.contains("unrecognized sampler")
            || error.contains("unknown sampler")
            || error.contains("invalid sampler")
    }
}

enum PowerMetricsSamplingPolicy {
    static let maximumConsecutiveMisses = 6

    static func shouldContinue(
        needsFans: Bool,
        needsTemps: Bool,
        sampledFans: Int,
        sampledTemps: Int,
        consecutiveMisses: Int = 0
    ) -> Bool {
        let hasRequiredFans = !needsFans || sampledFans > 0
        let hasRequiredTemps = !needsTemps || sampledTemps > 0
        return hasRequiredFans && hasRequiredTemps || consecutiveMisses < maximumConsecutiveMisses
    }
}

enum PowerMetricsParser {
    struct Result {
        let temps: [[String: Any]]
        let fans: [[String: Any]]
    }

    static func parse(_ output: String) -> Result {
        var temps: [[String: Any]] = []
        let temperaturePatterns: [(name: String, key: String, pattern: String)] = [
            ("CPU Die", "PMCPU", #"CPU die temperature:\s*([\d.]+)\s*C"#),
            ("GPU Die", "PMGPU", #"GPU die temperature:\s*([\d.]+)\s*C"#),
            ("IO Die", "PMIO", #"IO die temperature:\s*([\d.]+)\s*C"#),
        ]
        for item in temperaturePatterns {
            if let value = matchDouble(in: output, pattern: item.pattern) {
                temps.append(["name": item.name, "key": item.key, "value": value, "maxValue": 100.0])
            }
        }

        let pattern = #"\bFan(?:\s+(\d+))?(?:\s+speed)?\s*:\s*([\d.]+)\s*rpm\b"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(output.startIndex..., in: output)
        let matches = regex?.matches(in: output, range: range) ?? []
        let fans: [[String: Any]] = matches.enumerated().compactMap { fallbackIndex, match in
            guard let rpmRange = Range(match.range(at: 2), in: output),
                  let rpm = Double(output[rpmRange]) else { return nil }
            let displayedNumber = Range(match.range(at: 1), in: output).flatMap { Int(output[$0]) }
            let name = displayedNumber.map { "Fan \($0)" } ?? "Fan \(fallbackIndex + 1)"
            return [
                "id": fallbackIndex,
                "name": name,
                "actualRPM": rpm,
                "minimumRPM": 0.0,
                "maximumRPM": 0.0,
                "targetRPM": 0.0,
                "hasLiveRPM": true,
                "isControllable": false,
            ]
        }

        return Result(temps: temps, fans: fans)
    }

    private static func matchDouble(in text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let valueRange = Range(match.range(at: 1), in: text) else { return nil }
        return Double(text[valueRange])
    }
}
