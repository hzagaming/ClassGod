import Foundation
import Testing
@testable import ClassGod

@Suite("Updates")
struct UpdateTests {
    @Test("Semantic versions compare numeric components and prereleases")
    func comparesVersions() {
        #expect(AppVersion("v1.6")! > AppVersion("1.5.39")!)
        #expect(AppVersion("1.5.40")! > AppVersion("1.5.39")!)
        #expect(AppVersion("1.5.39-beta.1")! < AppVersion("1.5.39")!)
        #expect(AppVersion("1.5.39")! == AppVersion("v1.5.39")!)
        #expect(AppVersion("release") == nil)
        #expect(AppVersion("1.5.39-") == nil)
        #expect(AppVersion("1.5.39-beta..1") == nil)
    }

    @Test("Release decoding selects PKG before DMG")
    func decodesAndSelectsInstaller() throws {
        let data = try #require(#"""
        {
          "tag_name": "v1.5.40",
          "name": "ClassGod v1.5.40",
          "body": "Notes and updates",
          "html_url": "https://github.com/hzagaming/ClassGod/releases/tag/v1.5.40",
          "published_at": "2026-08-18T12:00:00Z",
          "draft": false,
          "prerelease": false,
          "assets": [
            {
              "name": "ClassGod-v1.5.40.dmg",
              "browser_download_url": "https://github.com/hzagaming/ClassGod/releases/download/v1.5.40/ClassGod.dmg",
              "size": 600,
              "content_type": "application/x-apple-diskimage",
              "digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            },
            {
              "name": "ClassGod-v1.5.40.pkg",
              "browser_download_url": "https://github.com/hzagaming/ClassGod/releases/download/v1.5.40/ClassGod.pkg",
              "size": 500,
              "content_type": "application/octet-stream",
              "digest": "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
            }
          ]
        }
        """#.data(using: .utf8))

        let release = try UpdateReleasePolicy.decode(data)

        #expect(release.tagName == "v1.5.40")
        #expect(UpdateReleasePolicy.preferredAsset(in: release)?.name.hasSuffix(".pkg") == true)
        #expect(UpdateReleasePolicy.isUpdateAvailable(release: release, currentVersion: "1.5.39"))
    }

    @Test("Release installers must come from this repository's GitHub download path")
    func validatesTrustedInstallerURLs() {
        let trusted = URL(
            string: "https://github.com/hzagaming/ClassGod/releases/download/v1.5.40/ClassGod.pkg"
        )!

        #expect(UpdateReleasePolicy.isTrustedDownloadURL(trusted))
        #expect(!UpdateReleasePolicy.isTrustedDownloadURL(URL(string: "http://github.com/hzagaming/ClassGod/releases/download/v1.5.40/ClassGod.pkg")!))
        #expect(!UpdateReleasePolicy.isTrustedDownloadURL(URL(string: "https://github.com.evil.example/hzagaming/ClassGod/releases/download/v1.5.40/ClassGod.pkg")!))
        #expect(!UpdateReleasePolicy.isTrustedDownloadURL(URL(string: "https://github.com/another/ClassGod/releases/download/v1.5.40/ClassGod.pkg")!))
        #expect(!UpdateReleasePolicy.isTrustedDownloadURL(URL(string: "https://example.com/ClassGod.pkg")!))
        #expect(!UpdateReleasePolicy.isTrustedDownloadURL(URL(string: "https://user@github.com/hzagaming/ClassGod/releases/download/v1.5.40/ClassGod.pkg")!))
        #expect(!UpdateReleasePolicy.isTrustedDownloadURL(URL(string: "https://github.com:443/hzagaming/ClassGod/releases/download/v1.5.40/ClassGod.pkg")!))
        #expect(!UpdateReleasePolicy.isTrustedDownloadURL(URL(string: "https://github.com/hzagaming/ClassGod/releases/download/v1.5.40/ClassGod.pkg?token=1")!))
        #expect(!UpdateReleasePolicy.isTrustedDownloadURL(URL(string: "https://github.com/hzagaming/ClassGod/releases/download/v1.5.40/ClassGod.pkg#fragment")!))
        #expect(UpdateReleasePolicy.isTrustedDownloadResponseURL(URL(string: "https://release-assets.githubusercontent.com/file.pkg")!))
        #expect(!UpdateReleasePolicy.isTrustedDownloadResponseURL(URL(string: "https://user@release-assets.githubusercontent.com/file.pkg")!))
        #expect(!UpdateReleasePolicy.isTrustedDownloadResponseURL(URL(string: "https://release-assets.githubusercontent.com:443/file.pkg")!))
        #expect(!UpdateReleasePolicy.isTrustedDownloadResponseURL(URL(string: "https://release-assets.githubusercontent.com.evil.example/file.pkg")!))
    }

    @Test("Release metadata and pages stay on this repository's trusted endpoints")
    func validatesTrustedReleaseURLs() {
        #expect(UpdateReleasePolicy.isTrustedReleaseAPIURL(URL(
            string: "https://api.github.com/repos/hzagaming/ClassGod/releases/latest"
        )!))
        #expect(!UpdateReleasePolicy.isTrustedReleaseAPIURL(URL(
            string: "https://api.github.com/repos/another/ClassGod/releases/latest"
        )!))
        #expect(!UpdateReleasePolicy.isTrustedReleaseAPIURL(URL(
            string: "https://api.github.com/repos/hzagaming/ClassGod/releases/latest?redirect=1"
        )!))

        #expect(UpdateReleasePolicy.isTrustedReleasePageURL(URL(
            string: "https://github.com/hzagaming/ClassGod/releases/tag/v1.5.42"
        )!))
        #expect(!UpdateReleasePolicy.isTrustedReleasePageURL(URL(
            string: "https://example.com/hzagaming/ClassGod/releases/tag/v1.5.42"
        )!))
        #expect(!UpdateReleasePolicy.isTrustedReleasePageURL(URL(
            string: "https://github.com/hzagaming/ClassGod/releases/tag/v1.5.42?next=evil"
        )!))
    }

    @Test("Drafts, prereleases, old versions, and assetless releases are rejected")
    func rejectsUnsupportedReleases() {
        let asset = GitHubReleaseAsset(
            name: "ClassGod.pkg",
            downloadURL: URL(string: "https://github.com/hzagaming/ClassGod/releases/download/v1.5.40/ClassGod.pkg")!,
            size: 100,
            contentType: "application/octet-stream",
            digest: "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        )
        let stable = GitHubRelease(
            tagName: "v1.5.40",
            name: "ClassGod",
            body: "",
            htmlURL: URL(string: "https://github.com/hzagaming/ClassGod/releases/tag/v1.5.40")!,
            publishedAt: Date(),
            isDraft: false,
            isPrerelease: false,
            assets: [asset]
        )
        var unsupported = stable

        #expect(!UpdateReleasePolicy.isUpdateAvailable(release: stable, currentVersion: "1.5.40"))
        unsupported.isPrerelease = true
        #expect(!UpdateReleasePolicy.isUpdateAvailable(release: unsupported, currentVersion: "1.5.39"))
        unsupported = stable
        unsupported.isDraft = true
        #expect(!UpdateReleasePolicy.isUpdateAvailable(release: unsupported, currentVersion: "1.5.39"))
        unsupported = stable
        unsupported.assets = []
        #expect(!UpdateReleasePolicy.isUpdateAvailable(release: unsupported, currentVersion: "1.5.39"))
        unsupported = stable
        unsupported.assets[0].digest = nil
        #expect(!UpdateReleasePolicy.isUpdateAvailable(release: unsupported, currentVersion: "1.5.39"))
        unsupported.assets[0].digest = "sha256:invalid"
        #expect(!UpdateReleasePolicy.isUpdateAvailable(release: unsupported, currentVersion: "1.5.39"))
    }

    @Test("New releases without a trusted installer are not reported as current")
    func distinguishesUnavailableInstallers() {
        let release = GitHubRelease(
            tagName: "v1.5.40",
            name: "ClassGod",
            body: "",
            htmlURL: URL(string: "https://github.com/hzagaming/ClassGod/releases/tag/v1.5.40")!,
            publishedAt: Date(),
            isDraft: false,
            isPrerelease: false,
            assets: []
        )

        #expect(UpdateReleasePolicy.assessment(release: release, currentVersion: "1.5.39") == .installerUnavailable)
        #expect(UpdateReleasePolicy.assessment(release: release, currentVersion: "1.5.40") == .upToDate)

        var invalid = release
        invalid.tagName = "release"
        #expect(UpdateReleasePolicy.assessment(release: invalid, currentVersion: "1.5.39") == nil)
    }

    @Test("Cancelled update operations reject stale callbacks")
    func rejectsStaleUpdateCallbacks() {
        var session = UpdateOperationSession()
        let first = session.begin()
        session.cancel()
        let second = session.begin()

        #expect(!session.isCurrent(first))
        #expect(session.isCurrent(second))
        let staleCompletion = session.complete(first)
        let currentCompletion = session.complete(second)
        #expect(!staleCompletion)
        #expect(currentCompletion)
        #expect(!session.isCurrent(second))
    }

    @Test("Update cache cleanup targets only stale installer artifacts")
    func identifiesStaleInstallerArtifacts() {
        let directory = URL(fileURLWithPath: "/tmp/ClassGod/Updates", isDirectory: true)
        let current = directory.appendingPathComponent("ClassGod-v1.5.40.pkg")
        let stalePKG = directory.appendingPathComponent("ClassGod-v1.5.39.pkg")
        let staleDMG = directory.appendingPathComponent("ClassGod-v1.5.39.dmg")
        let unrelated = directory.appendingPathComponent("notes.txt")

        #expect(Set(UpdateCachePolicy.staleInstallers(
            in: [current, stalePKG, staleDMG, unrelated],
            keeping: current
        )) == [stalePKG, staleDMG])
    }

    @Test("GitHub SHA-256 digests are parsed and verified")
    func verifiesDigests() {
        let data = Data("ClassGod".utf8)
        let digest = UpdateDigestPolicy.sha256Hex(data)

        #expect(UpdateDigestPolicy.expectedSHA256(from: "sha256:\(digest)") == digest)
        #expect(UpdateDigestPolicy.matches(data: data, digest: "sha256:\(digest)"))
        #expect(!UpdateDigestPolicy.matches(data: data, digest: "sha256:deadbeef"))
        #expect(!UpdateDigestPolicy.matches(data: data, digest: nil))
        #expect(UpdateDigestPolicy.expectedSHA256(from: "md5:abc") == nil)
    }

    @Test("Installer hashing stops when its update session is cancelled")
    func cancelsInstallerHashing() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClassGod-update-test-\(UUID().uuidString)")
        try Data("installer".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        #expect(throws: CancellationError.self) {
            try UpdateDigestPolicy.sha256Hex(fileURL: fileURL, shouldCancel: { true })
        }
    }
}
