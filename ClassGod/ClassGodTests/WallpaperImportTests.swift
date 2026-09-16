import AppKit
import AVFoundation
import Testing
@testable import ClassGod

@Suite("Wallpaper media validation")
@MainActor
struct WallpaperImportTests {
    @Test("Deleting the current wallpaper preserves disabled playback, including missing fallback files", arguments: [false, true])
    func deletionPreservesDisabledState(missingFallback: Bool) throws {
        let rig = try ImportRig()
        defer { rig.cleanUp() }
        let first = try rig.wallpaper("first")
        let missing = try rig.wallpaper("missing")
        let next = try rig.wallpaper("next")
        rig.engine.playlist = missingFallback ? [first, missing, next] : [first, next]
        #expect(rig.engine.selectWallpaper(first))
        #expect(rig.engine.setEnabled(false))
        rig.engine.isMuted = false
        rig.engine.volume = 0.6
        if missingFallback { try FileManager.default.removeItem(at: #require(missing.fileURL)) }
        rig.engine.removeWallpaper(first)
        #expect(rig.engine.currentWallpaper?.id == next.id)
        #expect(!rig.engine.isEnabled)
        #expect(rig.engine.isPlaying)
        #expect(!rig.engine.isMuted)
        #expect(rig.engine.volume == 0.6)
        let restored = WallpaperEngine(defaults: rig.defaults, directory: rig.root.appendingPathComponent("imports"))
        #expect(!restored.isEnabled)
        #expect(restored.currentWallpaper?.id == next.id)
    }

    @Test("Selecting the current disabled wallpaper enables it without resetting pause or mute")
    func reselectsDisabledWallpaper() throws {
        let rig = try ImportRig()
        defer { rig.cleanUp() }
        let item = try rig.wallpaper("current")
        rig.engine.playlist = [item]
        #expect(rig.engine.selectWallpaper(item))
        #expect(rig.engine.togglePlayPause())
        #expect(rig.engine.setEnabled(false))
        #expect(rig.engine.selectWallpaper(item))
        #expect(rig.engine.isEnabled)
        #expect(!rig.engine.isPlaying)
        #expect(rig.engine.isMuted)
        #expect(!rig.engine.selectWallpaper(item))
    }

    @Test("Removing an active wallpaper preserves transport until the playlist becomes empty", arguments: [false, true])
    func deletionPreservesActiveTransport(paused: Bool) throws {
        let rig = try ImportRig()
        defer { rig.cleanUp() }
        let first = try rig.wallpaper("first")
        let next = try rig.wallpaper("next")
        rig.engine.playlist = [first, next]
        #expect(rig.engine.selectWallpaper(first))
        if paused { #expect(rig.engine.togglePlayPause()) }
        rig.engine.removeWallpaper(first)
        #expect(rig.engine.isEnabled)
        #expect(rig.engine.isPlaying == !paused)
        #expect(rig.engine.currentWallpaper?.id == next.id)
        rig.engine.removeWallpaper(next)
        #expect(!rig.engine.isEnabled)
        #expect(rig.engine.currentWallpaper == nil)
    }

    @Test("Corrupt images, corrupt movies, and directories cannot become wallpapers", arguments: ["png", "mov", "directory.png"])
    func rejectsInvalidMedia(_ name: String) async throws {
        let rig = try ImportRig()
        defer { rig.cleanUp() }
        let file = rig.root.appendingPathComponent("invalid." + name)
        if name.hasPrefix("directory") {
            try FileManager.default.createDirectory(at: file, withIntermediateDirectories: true)
        } else {
            try Data("not media".utf8).write(to: file)
        }
        #expect(await !rig.engine.addWallpaper(from: file))
        #expect(rig.engine.playlist.isEmpty)
        #expect(rig.engine.currentWallpaper == nil)
        #expect(!rig.engine.isEnabled)
        #expect(rig.importedFiles.isEmpty)
        #expect(FileManager.default.fileExists(atPath: file.path))
    }

    @Test("Image imports preserve source bytes and cancelled imports leave no copied files")
    func importsImageAndHonorsCancellation() async throws {
        let rig = try ImportRig()
        defer { rig.cleanUp() }
        let image = try #require(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2,
                                                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                                isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        let data = try #require(image.representation(using: .png, properties: [:]))
        let file = rig.root.appendingPathComponent("valid.png")
        try data.write(to: file)
        #expect(await rig.engine.addWallpaper(from: file))
        let copied = try #require(rig.engine.currentWallpaper?.fileURL)
        #expect(copied != file)
        #expect(try Data(contentsOf: copied) == data)
        #expect(rig.engine.playlist.count == 1)
        let task = Task { await rig.engine.addWallpaper(from: file) }
        task.cancel()
        #expect(await !task.value)
        #expect(rig.engine.playlist.count == 1)
        #expect(rig.importedFiles.count == 1)
    }

    @Test("A playable audio-only movie cannot create a black wallpaper")
    func rejectsAudioOnlyMedia() async throws {
        let rig = try ImportRig()
        defer { rig.cleanUp() }
        let source = rig.root.appendingPathComponent("silent.wav")
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 8_000, channels: 1))
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 800))
        buffer.frameLength = 800
        try #require(buffer.floatChannelData).pointee.update(repeating: 0, count: 800)
        do {
            let audio = try AVAudioFile(forWriting: source, settings: format.settings)
            try audio.write(from: buffer)
        }
        let file = rig.root.appendingPathComponent("audio.mov")
        let export = try #require(AVAssetExportSession(asset: AVURLAsset(url: source), presetName: AVAssetExportPresetPassthrough))
        export.outputURL = file
        export.outputFileType = .mov
        await export.export()
        try #require(export.status == .completed)
        #expect(try await AVURLAsset(url: file).load(.isPlayable))
        #expect(await !rig.engine.addWallpaper(from: file))
        #expect(rig.engine.playlist.isEmpty)
        #expect(rig.importedFiles.isEmpty)
    }

    @Test("A real encoded video imports and restores from isolated storage")
    func importsVideo() async throws {
        let rig = try ImportRig()
        defer { rig.cleanUp() }
        let file = rig.root.appendingPathComponent("video.mov")
        let writer = try AVAssetWriter(outputURL: file, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 64, AVVideoHeightKey: 64,
        ])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: 64, kCVPixelBufferHeightKey as String: 64,
        ])
        writer.add(input)
        try #require(writer.startWriting())
        writer.startSession(atSourceTime: .zero)
        let pool = try #require(adaptor.pixelBufferPool)
        var pixelBuffer: CVPixelBuffer?
        try #require(CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer) == kCVReturnSuccess)
        let pixels = try #require(pixelBuffer)
        CVPixelBufferLockBaseAddress(pixels, [])
        memset(CVPixelBufferGetBaseAddress(pixels), 0, CVPixelBufferGetDataSize(pixels))
        CVPixelBufferUnlockBaseAddress(pixels, [])
        for _ in 0..<100 where !input.isReadyForMoreMediaData {
            try await Task.sleep(for: .milliseconds(10))
        }
        try #require(input.isReadyForMoreMediaData)
        try #require(adaptor.append(pixels, withPresentationTime: .zero))
        writer.endSession(atSourceTime: CMTime(value: 1, timescale: 1))
        input.markAsFinished()
        await writer.finishWriting()
        try #require(writer.status == .completed)
        #expect(await rig.engine.addWallpaper(from: file))
        #expect(rig.engine.currentWallpaper?.type == .video)
        #expect(rig.importedFiles.count == 1)
        let restored = WallpaperEngine(defaults: rig.defaults, directory: rig.root.appendingPathComponent("imports"))
        #expect(restored.currentWallpaper?.id == rig.engine.currentWallpaper?.id)
        #expect(restored.currentWallpaper?.filePath == rig.engine.currentWallpaper?.filePath)
        #expect(restored.playlist.map(\.id) == rig.engine.playlist.map(\.id))
    }
}

@MainActor
private final class ImportRig {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("ClassGodImport-\(UUID())", isDirectory: true)
    let suite = "ClassGodImportTests.\(UUID())"
    let defaults: UserDefaults
    let engine: WallpaperEngine
    var importedFiles: [URL] {
        (try? FileManager.default.contentsOfDirectory(at: root.appendingPathComponent("imports"), includingPropertiesForKeys: nil)) ?? []
    }

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suite))
        engine = WallpaperEngine(defaults: defaults, directory: root.appendingPathComponent("imports"))
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func cleanUp() {
        defaults.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: root)
    }

    func wallpaper(_ name: String) throws -> WallpaperItem {
        let file = root.appendingPathComponent(name + ".png")
        try Data().write(to: file)
        return WallpaperItem(name: name, filePath: file.path, type: .image)
    }
}
