//
//  AutoMaxRule.swift
//  ClassGod
//

import Foundation

enum FanRuleTarget: String, Codable, CaseIterable, Identifiable {
    case allFans = "allFans"
    case leftFan = "leftFan"
    case rightFan = "rightFan"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .allFans: return String(localized: "rule.target.all_fans")
        case .leftFan: return String(localized: "rule.target.left_side")
        case .rightFan: return String(localized: "rule.target.right_side")
        }
    }
}

enum RuleComparison: String, Codable, CaseIterable, Identifiable {
    case above = "above"
    case below = "below"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .above: return String(localized: "rule.comparison.above")
        case .below: return String(localized: "rule.comparison.below")
        }
    }
}

enum RuleSensor: String, Codable, CaseIterable, Identifiable {
    case highestCPU = "highestCPU"
    case averageCPU = "averageCPU"
    case highestGPU = "highestGPU"
    case anySensor = "anySensor"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .highestCPU: return String(localized: "rule.sensor.highest_cpu")
        case .averageCPU: return String(localized: "rule.sensor.average_cpu")
        case .highestGPU: return String(localized: "rule.sensor.highest_gpu")
        case .anySensor: return String(localized: "rule.sensor.any_sensor")
        }
    }
}

enum RuleTargetMode: String, Codable, CaseIterable, Identifiable {
    case percentage = "percentage"
    case rpm = "rpm"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .percentage: return "%"
        case .rpm: return "RPM"
        }
    }
}

struct AutoMaxRule: Codable, Identifiable, Equatable {
    let id: UUID
    var fanTarget: FanRuleTarget
    var sensor: RuleSensor
    var comparison: RuleComparison
    var threshold: Double
    var hysteresis: Double
    var durationSeconds: Double
    var isEnabled: Bool

    // Target: either a percentage of the fan range or an absolute RPM.
    var targetMode: RuleTargetMode
    var targetPercentage: Double
    var targetRPM: Double

    // When non-nil, overrides `sensor` with a specific discovered sensor key.
    var specificSensorKey: String?

    init(
        id: UUID = UUID(),
        fanTarget: FanRuleTarget = .allFans,
        sensor: RuleSensor = .highestCPU,
        comparison: RuleComparison = .above,
        threshold: Double = 70,
        hysteresis: Double = 5,
        durationSeconds: Double = 3,
        isEnabled: Bool = true,
        targetMode: RuleTargetMode = .percentage,
        targetPercentage: Double = 100,
        targetRPM: Double = 5000,
        specificSensorKey: String? = nil
    ) {
        self.id = id
        self.fanTarget = fanTarget
        self.sensor = sensor
        self.comparison = comparison
        self.threshold = threshold
        self.hysteresis = hysteresis
        self.durationSeconds = durationSeconds
        self.isEnabled = isEnabled
        self.targetMode = targetMode
        self.targetPercentage = targetPercentage
        self.targetRPM = targetRPM
        self.specificSensorKey = specificSensorKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.fanTarget = try container.decode(FanRuleTarget.self, forKey: .fanTarget)
        self.sensor = try container.decode(RuleSensor.self, forKey: .sensor)
        self.comparison = try container.decode(RuleComparison.self, forKey: .comparison)
        self.threshold = try container.decode(Double.self, forKey: .threshold)
        self.hysteresis = try container.decodeIfPresent(Double.self, forKey: .hysteresis) ?? 5
        self.durationSeconds = try container.decodeIfPresent(Double.self, forKey: .durationSeconds) ?? 3
        self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        self.targetMode = try container.decodeIfPresent(RuleTargetMode.self, forKey: .targetMode) ?? .percentage
        self.targetPercentage = try container.decodeIfPresent(Double.self, forKey: .targetPercentage) ?? 100
        self.targetRPM = try container.decodeIfPresent(Double.self, forKey: .targetRPM) ?? 5000
        self.specificSensorKey = try container.decodeIfPresent(String.self, forKey: .specificSensorKey)
    }

    private enum CodingKeys: String, CodingKey {
        case id, fanTarget, sensor, comparison, threshold, hysteresis, durationSeconds, isEnabled
        case targetMode, targetPercentage, targetRPM, specificSensorKey
    }
}
