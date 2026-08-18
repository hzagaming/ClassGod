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
              "browser_download_url": "https://example.com/ClassGod.dmg",
              "size": 600,
              "content_type": "application/x-apple-diskimage",
              "digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            },
            {
              "name": "ClassGod-v1.5.40.pkg",
              "browser_download_url": "https://example.com/ClassGod.pkg",
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

    @Test("Drafts, prereleases, old versions, and assetless releases are rejected")
    func rejectsUnsupportedReleases() {
        let asset = GitHubReleaseAsset(
            name: "ClassGod.pkg",
            downloadURL: URL(string: "https://example.com/ClassGod.pkg")!,
            size: 100,
            contentType: "application/octet-stream",
            digest: "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        )
        let stable = GitHubRelease(
            tagName: "v1.5.40",
            name: "ClassGod",
            body: "",
            htmlURL: URL(string: "https://example.com/release")!,
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
}
