import AppKit
import Combine
import Foundation

nonisolated enum UpdatePhase: Equatable, Sendable {
    case idle
    case checking
    case upToDate
    case updateAvailable
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
    private var automaticCheckTimer: Timer?
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
        ) { [weak self] _ in
            Task { @MainActor in self?.checkForUpdates() }
        }
        automaticCheckTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stop() {
        automaticCheckTimer?.invalidate()
        automaticCheckTimer = nil
        checkTask?.cancel()
        checkTask = nil
        progressTask?.cancel()
        progressTask = nil
        downloadTask?.cancel()
        downloadTask = nil
        isStarted = false
    }

    func checkForUpdates() {
        guard phase != .checking, phase != .downloading else { return }
        checkTask?.cancel()
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
                guard !Task.isCancelled else { return }
                guard let response = response as? HTTPURLResponse,
                      (200..<300).contains(response.statusCode) else { throw UpdateError.invalidResponse }
                guard data.count <= UpdateReleasePolicy.maximumResponseSize else {
                    throw UpdateError.responseTooLarge
                }
                let release = try UpdateReleasePolicy.decode(data)
                latestRelease = release
                lastCheckedAt = Date()
                phase = UpdateReleasePolicy.isUpdateAvailable(
                    release: release,
                    currentVersion: currentVersion
                ) ? .updateAvailable : .upToDate
                checkTask = nil
            } catch is CancellationError {
                checkTask = nil
            } catch {
                guard !Task.isCancelled else { return }
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
        guard asset.downloadURL.scheme?.lowercased() == "https" else {
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

        let task = URLSession.shared.downloadTask(with: request) { [weak self] temporaryURL, response, error in
            if let error {
                Task { @MainActor in self?.finishDownload(errorMessage: error.localizedDescription) }
                return
            }
            do {
                guard let response = response as? HTTPURLResponse,
                      (200..<300).contains(response.statusCode),
                      let temporaryURL else { throw UpdateError.invalidDownload }
                let destination = try Self.persistDownloadedFile(from: temporaryURL, asset: asset)
                Task { @MainActor in self?.finishDownload(fileURL: destination) }
            } catch {
                Task { @MainActor in self?.finishDownload(errorMessage: error.localizedDescription) }
            }
        }
        downloadTask = task
        trackProgress(of: task)
        task.resume()
    }

    func openReleasePage() {
        guard let url = latestRelease?.htmlURL else { return }
        NSWorkspace.shared.open(url)
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

    private func finishDownload(fileURL: URL) {
        progressTask?.cancel()
        progressTask = nil
        downloadTask = nil
        downloadProgress = 1
        if NSWorkspace.shared.open(fileURL) {
            phase = .installerOpened
        } else {
            fail(UpdateError.installerOpenFailed.localizedDescription)
        }
    }

    private func finishDownload(errorMessage: String) {
        progressTask?.cancel()
        progressTask = nil
        downloadTask = nil
        fail(errorMessage)
    }

    private func fail(_ message: String) {
        errorMessage = message
        phase = .failed
    }

    nonisolated private static func persistDownloadedFile(
        from temporaryURL: URL,
        asset: GitHubReleaseAsset
    ) throws -> URL {
        let safeName = URL(fileURLWithPath: asset.name).lastPathComponent
        guard safeName == asset.name,
              safeName.lowercased().hasSuffix(".pkg") || safeName.lowercased().hasSuffix(".dmg") else {
            throw UpdateError.invalidDownload
        }
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = root.appendingPathComponent("ClassGod/Updates", isDirectory: true)
        let destination = directory.appendingPathComponent(safeName)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: temporaryURL, to: destination)

        let size = try destination.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init) ?? 0
        guard size == asset.size, size > 0, size <= UpdateReleasePolicy.maximumAssetSize else {
            try? FileManager.default.removeItem(at: destination)
            throw UpdateError.invalidDownload
        }
        guard let expected = UpdateDigestPolicy.expectedSHA256(from: asset.digest) else {
            try? FileManager.default.removeItem(at: destination)
            throw UpdateError.digestMismatch
        }
        if try UpdateDigestPolicy.sha256Hex(fileURL: destination) != expected {
            try? FileManager.default.removeItem(at: destination)
            throw UpdateError.digestMismatch
        }
        return destination
    }
}
