import AppKit
import Combine
import Foundation

nonisolated enum UpdatePhase: Equatable, Sendable {
    case idle
    case checking
    case upToDate
    case updateAvailable
    case installerUnavailable
    case downloading
    case installerOpened
    case failed
}

nonisolated enum UpdateError: LocalizedError, Sendable {
    case invalidResponse
    case responseTooLarge
    case missingInstaller
    case invalidDownload
    case digestMismatch
    case installerOpenFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse: String(localized: "update.error.invalid_response")
        case .responseTooLarge: String(localized: "update.error.response_too_large")
        case .missingInstaller: String(localized: "update.error.missing_installer")
        case .invalidDownload: String(localized: "update.error.invalid_download")
        case .digestMismatch: String(localized: "update.error.digest_mismatch")
        case .installerOpenFailed: String(localized: "update.error.open_installer")
        }
    }
}

@MainActor
final class UpdateService: ObservableObject {
    static let shared = UpdateService()

    @Published private(set) var phase: UpdatePhase = .idle
    @Published private(set) var latestRelease: GitHubRelease?
    @Published private(set) var downloadProgress = 0.0
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastCheckedAt: Date?

    private static let releaseAPI = URL(
        string: "https://api.github.com/repos/hzagaming/ClassGod/releases/latest"
    )!
    private static let automaticCheckInterval: TimeInterval = 6 * 60 * 60
    private var checkTask: Task<Void, Never>?
    private var downloadTask: URLSessionDownloadTask?
    private var progressTask: Task<Void, Never>?
    private var validationTask: Task<Void, Never>?
    private var automaticCheckTimer: Timer?
    private var checkSession = UpdateOperationSession()
    private var downloadSession = UpdateOperationSession()
    private var isStarted = false

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    var currentBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    var preferredAsset: GitHubReleaseAsset? {
        latestRelease.flatMap(UpdateReleasePolicy.preferredAsset)
    }

    private init() {}

    func start() {
        guard !isStarted else { return }
        isStarted = true
        checkForUpdates()
        let timer = Timer(
            fire: Date().addingTimeInterval(Self.automaticCheckInterval),
            interval: Self.automaticCheckInterval,
            repeats: true
        ) { _ in
            Task { @MainActor in UpdateService.shared.checkForUpdates() }
        }
        automaticCheckTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stop() {
        automaticCheckTimer?.invalidate()
        automaticCheckTimer = nil
        checkSession.cancel()
        downloadSession.cancel()
        checkTask?.cancel()
        checkTask = nil
        progressTask?.cancel()
        progressTask = nil
        validationTask?.cancel()
        validationTask = nil
        downloadTask?.cancel()
        downloadTask = nil
        if phase == .checking || phase == .downloading { phase = .idle }
        isStarted = false
    }

    func checkForUpdates() {
        guard phase != .checking, phase != .downloading else { return }
        checkTask?.cancel()
        let requestID = checkSession.begin()
        phase = .checking
        errorMessage = nil
        checkTask = Task { [weak self] in
            guard let self else { return }
            do {
                var request = URLRequest(url: Self.releaseAPI)
                request.timeoutInterval = 20
                request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
                request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
                request.setValue("ClassGod-Updater/\(currentVersion)", forHTTPHeaderField: "User-Agent")
                let (data, response) = try await URLSession.shared.data(for: request)
                try Task.checkCancellation()
                guard checkSession.isCurrent(requestID) else { return }
                guard let response = response as? HTTPURLResponse,
                      (200..<300).contains(response.statusCode) else { throw UpdateError.invalidResponse }
                guard data.count <= UpdateReleasePolicy.maximumResponseSize else {
                    throw UpdateError.responseTooLarge
                }
                let release = try UpdateReleasePolicy.decode(data)
                guard let assessment = UpdateReleasePolicy.assessment(
                    release: release,
                    currentVersion: currentVersion
                ) else { throw UpdateError.invalidResponse }
                guard checkSession.complete(requestID) else { return }
                latestRelease = release
                lastCheckedAt = Date()
                phase = switch assessment {
                case .upToDate: .upToDate
                case .updateAvailable: .updateAvailable
                case .installerUnavailable: .installerUnavailable
                }
                checkTask = nil
            } catch is CancellationError {
                if checkSession.complete(requestID) {
                    checkTask = nil
                    if phase == .checking { phase = .idle }
                }
            } catch {
                guard !Task.isCancelled, checkSession.complete(requestID) else { return }
                errorMessage = error.localizedDescription
                lastCheckedAt = Date()
                phase = .failed
                checkTask = nil
            }
        }
    }

    func downloadAndInstall() {
        guard phase == .updateAvailable,
              let asset = preferredAsset else {
            fail(UpdateError.missingInstaller.localizedDescription)
            return
        }
        guard UpdateReleasePolicy.isTrustedDownloadURL(asset.downloadURL) else {
            fail(UpdateError.invalidDownload.localizedDescription)
            return
        }

        var request = URLRequest(url: asset.downloadURL)
        request.timeoutInterval = 120
        request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
        request.setValue("ClassGod-Updater/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        phase = .downloading
        downloadProgress = 0
        errorMessage = nil
        let requestID = downloadSession.begin()

        let task = URLSession.shared.downloadTask(with: request) { temporaryURL, response, error in
            if let error {
                Task { @MainActor in
                    UpdateService.shared.finishDownload(
                        errorMessage: error.localizedDescription,
                        requestID: requestID
                    )
                }
                return
            }
            do {
                guard let response = response as? HTTPURLResponse,
                      (200..<300).contains(response.statusCode),
                      response.url.map(UpdateReleasePolicy.isTrustedDownloadResponseURL) == true,
                      let temporaryURL else { throw UpdateError.invalidDownload }
                let stagedURL = try Self.stageDownloadedFile(from: temporaryURL, asset: asset)
                Task { @MainActor in
                    UpdateService.shared.beginValidation(
                        stagedURL: stagedURL,
                        asset: asset,
                        requestID: requestID
                    )
                }
            } catch {
                Task { @MainActor in
                    UpdateService.shared.finishDownload(
                        errorMessage: error.localizedDescription,
                        requestID: requestID
                    )
                }
            }
        }
        downloadTask = task
        trackProgress(of: task)
        task.resume()
    }

    func cancelDownload() {
        guard phase == .downloading else { return }
        downloadSession.cancel()
        progressTask?.cancel()
        progressTask = nil
        validationTask?.cancel()
        validationTask = nil
        downloadTask?.cancel()
        downloadTask = nil
        downloadProgress = 0
        errorMessage = nil
        phase = .updateAvailable
    }

    func openReleasePage() {
        guard let url = latestRelease?.htmlURL else { return }
        NSWorkspace.shared.open(url)
    }

    private func beginValidation(
        stagedURL: URL,
        asset: GitHubReleaseAsset,
        requestID: UInt
    ) {
        guard downloadSession.isCurrent(requestID) else {
            try? FileManager.default.removeItem(at: stagedURL)
            return
        }
        validationTask?.cancel()
        validationTask = Task.detached(priority: .utility) {
            do {
                try Self.validateDownloadedFile(at: stagedURL, asset: asset)
                try Task.checkCancellation()
                await UpdateService.shared.finishDownload(
                    stagedURL: stagedURL,
                    asset: asset,
                    requestID: requestID
                )
            } catch is CancellationError {
                try? FileManager.default.removeItem(at: stagedURL)
            } catch {
                try? FileManager.default.removeItem(at: stagedURL)
                await UpdateService.shared.finishDownload(
                    errorMessage: error.localizedDescription,
                    requestID: requestID
                )
            }
        }
    }

    private func trackProgress(of task: URLSessionDownloadTask) {
        progressTask?.cancel()
        progressTask = Task { [weak self, weak task] in
            while let self, let task, !Task.isCancelled, task.state == .running {
                let progress = task.progress
                if progress.totalUnitCount > 0 {
                    downloadProgress = min(max(progress.fractionCompleted, 0), 1)
                }
                try? await Task.sleep(for: .milliseconds(150))
            }
        }
    }

    private func finishDownload(
        stagedURL: URL,
        asset: GitHubReleaseAsset,
        requestID: UInt
    ) {
        guard downloadSession.isCurrent(requestID) else {
            try? FileManager.default.removeItem(at: stagedURL)
            return
        }
        do {
            let fileURL = try Self.promoteDownloadedFile(at: stagedURL, asset: asset)
            finishDownload(fileURL: fileURL, requestID: requestID)
        } catch {
            try? FileManager.default.removeItem(at: stagedURL)
            finishDownload(errorMessage: error.localizedDescription, requestID: requestID)
        }
    }

    private func finishDownload(fileURL: URL, requestID: UInt) {
        guard downloadSession.complete(requestID) else { return }
        progressTask?.cancel()
        progressTask = nil
        validationTask = nil
        downloadTask = nil
        downloadProgress = 1
        if NSWorkspace.shared.open(fileURL) {
            phase = .installerOpened
        } else {
            fail(UpdateError.installerOpenFailed.localizedDescription)
        }
    }

    private func finishDownload(errorMessage: String, requestID: UInt) {
        guard downloadSession.complete(requestID) else { return }
        progressTask?.cancel()
        progressTask = nil
        validationTask = nil
        downloadTask = nil
        fail(errorMessage)
    }

    private func fail(_ message: String) {
        errorMessage = message
        phase = .failed
    }

    nonisolated private static func stageDownloadedFile(
        from temporaryURL: URL,
        asset: GitHubReleaseAsset
    ) throws -> URL {
        let safeName = try safeInstallerName(asset.name)
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClassGod/Updates", isDirectory: true)
        let stagedURL = directory.appendingPathComponent("\(UUID().uuidString)-\(safeName)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: temporaryURL, to: stagedURL)
        return stagedURL
    }

    nonisolated private static func validateDownloadedFile(
        at stagedURL: URL,
        asset: GitHubReleaseAsset
    ) throws {
        let size = try stagedURL.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init) ?? 0
        guard size == asset.size, size > 0, size <= UpdateReleasePolicy.maximumAssetSize else {
            throw UpdateError.invalidDownload
        }
        guard let expected = UpdateDigestPolicy.expectedSHA256(from: asset.digest) else {
            throw UpdateError.digestMismatch
        }
        let actual = try UpdateDigestPolicy.sha256Hex(fileURL: stagedURL) {
            Task<Never, Never>.isCancelled
        }
        guard actual == expected else { throw UpdateError.digestMismatch }
    }

    nonisolated private static func promoteDownloadedFile(
        at stagedURL: URL,
        asset: GitHubReleaseAsset
    ) throws -> URL {
        let safeName = try safeInstallerName(asset.name)
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = root.appendingPathComponent("ClassGod/Updates", isDirectory: true)
        let destination = directory.appendingPathComponent(safeName)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: destination.path) {
            _ = try FileManager.default.replaceItemAt(destination, withItemAt: stagedURL)
        } else {
            try FileManager.default.moveItem(at: stagedURL, to: destination)
        }
        if let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) {
            for staleURL in UpdateCachePolicy.staleInstallers(in: contents, keeping: destination) {
                try? FileManager.default.removeItem(at: staleURL)
            }
        }
        return destination
    }

    nonisolated private static func safeInstallerName(_ name: String) throws -> String {
        let safeName = URL(fileURLWithPath: name).lastPathComponent
        guard safeName == name,
              safeName.lowercased().hasSuffix(".pkg") || safeName.lowercased().hasSuffix(".dmg") else {
            throw UpdateError.invalidDownload
        }
        return safeName
    }
}
