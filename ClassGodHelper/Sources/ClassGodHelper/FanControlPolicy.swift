import Foundation

enum FanControlModeTransition: Equatable {
    case releaseToSystem
    case forceMaximum

    init?(mode: String) {
        switch mode {
        case "system", "autoMax", "manual", "custom":
            self = .releaseToSystem
        case "max":
            self = .forceMaximum
        default:
            return nil
        }
    }
}

enum FanControlWriteVerification {
    static func matches(expected: [UInt8], actual: [UInt8]?) -> Bool {
        guard let actual, actual.count >= expected.count else { return false }
        return actual.prefix(expected.count).elementsEqual(expected)
    }
}

enum FanControlForceMask {
    static func updated(_ bytes: [UInt8], fanIndex: Int, forced: Bool) -> [UInt8]? {
        guard bytes.count >= 2, (0...15).contains(fanIndex) else { return nil }
        var mask = UInt16(bytes[0]) << 8 | UInt16(bytes[1])
        let bit = UInt16(1) << UInt16(fanIndex)
        if forced {
            mask |= bit
        } else {
            mask &= ~bit
        }
        return [UInt8(mask >> 8), UInt8(mask & 0xFF)]
    }
}

enum FanControlTarget {
    static func clamped(_ rpm: Double, minimum: Double, maximum: Double) -> Double? {
        guard minimum >= 0, maximum > minimum else { return nil }
        return min(maximum, max(minimum, rpm))
    }
}

enum FanReadingValidity {
    static func isPlausible(actual: Double, minimum: Double, maximum: Double) -> Bool {
        actual >= 0 && actual <= 20_000
            && minimum >= 0 && maximum > minimum && maximum <= 20_000
    }
}
