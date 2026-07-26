import Foundation

struct GhostApplicationDescriptor: Equatable {
    let bundleIdentifier: String?
    let isRegular: Bool
    let isHidden: Bool
    let isTerminated: Bool
    let isFrontmost: Bool
}

struct GhostProtocolPlan: Equatable {
    let bundleIdentifiersToHide: [String]
    let originalFrontmostBundleIdentifier: String?
}

enum GhostProtocolPlanner {
    static func makePlan(
        applications: [GhostApplicationDescriptor],
        targetBundleIdentifier: String,
        ownBundleIdentifier: String
    ) -> GhostProtocolPlan {
        var seen: Set<String> = []
        var bundleIdentifiers: [String] = []
        var originalFrontmost: String?

        for application in applications {
            if application.isFrontmost,
               application.isRegular,
               !application.isHidden,
               !application.isTerminated,
               let bundleIdentifier = application.bundleIdentifier,
               !bundleIdentifier.isEmpty,
               bundleIdentifier != targetBundleIdentifier {
                originalFrontmost = bundleIdentifier
            }

            guard application.isRegular,
                  !application.isHidden,
                  !application.isTerminated,
                  let bundleIdentifier = application.bundleIdentifier,
                  !bundleIdentifier.isEmpty,
                  bundleIdentifier != targetBundleIdentifier,
                  bundleIdentifier != ownBundleIdentifier,
                  seen.insert(bundleIdentifier).inserted else { continue }

            bundleIdentifiers.append(bundleIdentifier)
        }

        return GhostProtocolPlan(
            bundleIdentifiersToHide: bundleIdentifiers,
            originalFrontmostBundleIdentifier: originalFrontmost
        )
    }
}

struct GhostDestination: Identifiable, Equatable {
    var id: String { bundleIdentifier }
    let name: String
    let bundleIdentifier: String
    let iconName: String

    static let builtIns = [
        GhostDestination(name: "Finder", bundleIdentifier: "com.apple.finder", iconName: "folder.fill"),
        GhostDestination(name: "Notes", bundleIdentifier: "com.apple.Notes", iconName: "note.text"),
        GhostDestination(name: "Safari", bundleIdentifier: "com.apple.Safari", iconName: "safari.fill"),
        GhostDestination(name: "Calculator", bundleIdentifier: "com.apple.calculator", iconName: "function")
    ]

    static func merged(with targets: [SwitchTarget]) -> [GhostDestination] {
        var seen: Set<String> = []
        var result: [GhostDestination] = []

        for destination in builtIns {
            seen.insert(destination.bundleIdentifier.lowercased())
            result.append(destination)
        }

        for target in targets {
            let bundleIdentifier = target.bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !bundleIdentifier.isEmpty,
                  seen.insert(bundleIdentifier.lowercased()).inserted else { continue }
            result.append(
                GhostDestination(
                    name: target.name,
                    bundleIdentifier: bundleIdentifier,
                    iconName: target.iconName
                )
            )
        }
        return result
    }
}

struct GhostProtocolSettings: Codable, Equatable {
    var targetBundleIdentifier: String
    var shortcutKey: String
    var shortcutModifiers: UInt
    var hideOtherApplications: Bool

    static let `default` = GhostProtocolSettings(
        targetBundleIdentifier: "com.apple.finder",
        shortcutKey: "F7",
        shortcutModifiers: 0,
        hideOtherApplications: true
    )

    private enum CodingKeys: String, CodingKey {
        case targetBundleIdentifier
        case shortcutKey
        case shortcutModifiers
        case hideOtherApplications
    }

    init(
        targetBundleIdentifier: String,
        shortcutKey: String,
        shortcutModifiers: UInt,
        hideOtherApplications: Bool
    ) {
        self.targetBundleIdentifier = targetBundleIdentifier
        self.shortcutKey = shortcutKey
        self.shortcutModifiers = shortcutModifiers
        self.hideOtherApplications = hideOtherApplications
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self = .default
        targetBundleIdentifier = try container.decodeIfPresent(String.self, forKey: .targetBundleIdentifier) ?? targetBundleIdentifier
        shortcutKey = try container.decodeIfPresent(String.self, forKey: .shortcutKey) ?? shortcutKey
        shortcutModifiers = try container.decodeIfPresent(UInt.self, forKey: .shortcutModifiers) ?? shortcutModifiers
        hideOtherApplications = try container.decodeIfPresent(Bool.self, forKey: .hideOtherApplications) ?? hideOtherApplications
    }
}

struct CarbonShortcut: Hashable {
    let keyCode: UInt32
    let modifiers: UInt32
}

enum GhostShortcutPolicy {
    static func isReserved(_ shortcut: CarbonShortcut, reservedShortcuts: Set<CarbonShortcut>) -> Bool {
        reservedShortcuts.contains(shortcut)
    }
}
