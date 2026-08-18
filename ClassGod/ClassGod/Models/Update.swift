import Foundation
import CryptoKit

nonisolated struct AppVersion: Comparable, Sendable {
    private enum Identifier: Equatable, Comparable, Sendable {
        case number(Int)
        case text(String)

        static func < (lhs: Identifier, rhs: Identifier) -> Bool {
            switch (lhs, rhs) {
            case let (.number(lhs), .number(rhs)): lhs < rhs
            case (.number, .text): true
            case (.text, .number): false
            case let (.text(lhs), .text(rhs)): lhs.localizedStandardCompare(rhs) == .orderedAscending
            }
        }
    }

    private let components: [Int]
    private let prerelease: [Identifier]?

    init?(_ rawValue: String) {
        var value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.hasPrefix("v") { value.removeFirst() }
        let sections = value.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        let numbers = sections[0].split(separator: ".", omittingEmptySubsequences: false)
        guard !numbers.isEmpty,
              numbers.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }) else { return nil }
        var parsed = numbers.compactMap { Int($0) }
        guard parsed.count == numbers.count else { return nil }
        while parsed.count > 1, parsed.last == 0 { parsed.removeLast() }
        components = parsed

        if sections.count == 2, !sections[1].isEmpty {
            prerelease = sections[1].split(separator: ".").map { value in
                Int(value).map(Identifier.number) ?? .text(String(value))
            }
        } else {
            prerelease = nil
        }
    }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right }
        }
        switch (lhs.prerelease, rhs.prerelease) {
        case (nil, nil): return false
        case (.some, nil): return true
        case (nil, .some): return false
        case let (.some(left), .some(right)):
            for index in 0..<min(left.count, right.count) where left[index] != right[index] {
                return left[index] < right[index]
            }
            return left.count < right.count
        }
    }
}

nonisolated struct GitHubReleaseAsset: Codable, Equatable, Sendable {
    var name: String
    var downloadURL: URL
    var size: Int64
    var contentType: String
    var digest: String?

    enum CodingKeys: String, CodingKey {
        case name, size, digest
        case downloadURL = "browser_download_url"
        case contentType = "content_type"
    }
}

nonisolated struct GitHubRelease: Codable, Equatable, Sendable {
    var tagName: String
    var name: String
    var body: String
    var htmlURL: URL
    var publishedAt: Date
    var isDraft: Bool
    var isPrerelease: Bool
    var assets: [GitHubReleaseAsset]

    init(
        tagName: String,
        name: String,
        body: String,
        htmlURL: URL,
        publishedAt: Date,
        isDraft: Bool,
        isPrerelease: Bool,
        assets: [GitHubReleaseAsset]
    ) {
        self.tagName = tagName
        self.name = name
        self.body = body
        self.htmlURL = htmlURL
        self.publishedAt = publishedAt
        self.isDraft = isDraft
        self.isPrerelease = isPrerelease
        self.assets = assets
    }

    enum CodingKeys: String, CodingKey {
        case name, body, assets
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case publishedAt = "published_at"
        case isDraft = "draft"
        case isPrerelease = "prerelease"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tagName = try container.decode(String.self, forKey: .tagName)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? tagName
        body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        htmlURL = try container.decode(URL.self, forKey: .htmlURL)
        publishedAt = try container.decode(Date.self, forKey: .publishedAt)
        isDraft = try container.decode(Bool.self, forKey: .isDraft)
        isPrerelease = try container.decode(Bool.self, forKey: .isPrerelease)
        assets = try container.decode([GitHubReleaseAsset].self, forKey: .assets)
    }
}

nonisolated enum UpdateReleasePolicy {
    static let maximumResponseSize = 2 * 1_024 * 1_024
    static let maximumAssetSize: Int64 = 1_024 * 1_024 * 1_024

    static func decode(_ data: Data) throws -> GitHubRelease {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(GitHubRelease.self, from: data)
    }

    static func preferredAsset(in release: GitHubRelease) -> GitHubReleaseAsset? {
        let valid = release.assets.filter {
            $0.size > 0
                && $0.size <= maximumAssetSize
                && $0.downloadURL.scheme?.lowercased() == "https"
                && UpdateDigestPolicy.expectedSHA256(from: $0.digest) != nil
        }
        return valid.first { $0.name.lowercased().hasSuffix(".pkg") }
            ?? valid.first { $0.name.lowercased().hasSuffix(".dmg") }
    }

    static func isUpdateAvailable(release: GitHubRelease, currentVersion: String) -> Bool {
        guard !release.isDraft,
              !release.isPrerelease,
              preferredAsset(in: release) != nil,
              let latest = AppVersion(release.tagName),
              let current = AppVersion(currentVersion) else { return false }
        return latest > current
    }
}

nonisolated enum UpdateDigestPolicy {
    static func expectedSHA256(from digest: String?) -> String? {
        guard let digest else { return nil }
        let parts = digest.lowercased().split(separator: ":", maxSplits: 1)
        guard parts.count == 2,
              parts[0] == "sha256",
              parts[1].count == 64,
              parts[1].allSatisfy({ $0.isHexDigit }) else { return nil }
        return String(parts[1])
    }

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func matches(data: Data, digest: String?) -> Bool {
        guard let expected = expectedSHA256(from: digest) else { return false }
        return sha256Hex(data) == expected
    }

    static func sha256Hex(fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        var hasher = SHA256()
        while true {
            let data = try handle.read(upToCount: 1_048_576) ?? Data()
            if data.isEmpty { break }
            hasher.update(data: data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
