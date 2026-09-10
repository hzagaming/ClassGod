import AppKit
import AVFoundation
import SwiftUI
import Testing
@testable import ClassGod

@Suite("Training presentation", .serialized)
@MainActor
struct TrainingPresentationTests {
    @Test("Both student modes and shared tools render the expanded feature grid at supported scales")
    func rendersMainPanelModes() async throws {
        let preferences = PreferencesManager.shared.preferences
        let key = "com.hanazar.classgod.mainPanelMode"
        let storedMode = UserDefaults.standard.object(forKey: key)
        defer {
            PreferencesManager.shared.preferences = preferences
            if let storedMode { UserDefaults.standard.set(storedMode, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        PreferencesManager.shared.preferences.enableSoundEffects = false
        PreferencesManager.shared.preferences.enableHapticFeedback = false
        PreferencesManager.shared.preferences.enableFanControl = false
        for zoom in [1.0, 2.0] {
            PreferencesManager.shared.preferences.windowZoomScale = zoom
            for mode in MainPanelMode.allCases {
                UserDefaults.standard.set(mode.rawValue, forKey: key)
                try await render(MenuBarWindowView(
                    onClose: {}, onOpenPreflight: {}, onOpenDestinTab: {}, onOpenSuperSwitch: {},
                    onOpenGhostProtocol: {}, onOpenBrowserBypasser: {}, onOpenAssessPrepHack: {},
                    onOpenSettings: {}, onOpenWallpaper: {}, onOpenHackerDesktop: {}
                ), name: "main-\(mode.rawValue)-\(Int(zoom * 100))", size: .init(width: 400 * zoom, height: 700))
            }
        }
    }

    @Test("Training windows render their empty, review, and reaction states at supported scales")
    func rendersTrainingStates() async throws {
        #expect(NSImage(systemSymbolName: MainPanelFeature.recallLab.icon, accessibilityDescription: nil) != nil)
        #expect(NSImage(systemSymbolName: MainPanelFeature.switchDrill.icon, accessibilityDescription: nil) != nil)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("ClassGodTrainingRender-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let recall = RecallLabService(directory: directory)
        let original = PreferencesManager.shared.preferences
        defer { PreferencesManager.shared.preferences = original }
        PreferencesManager.shared.preferences.windowZoomScale = 1
        PreferencesManager.shared.preferences.enableSoundEffects = false
        PreferencesManager.shared.preferences.enableHapticFeedback = false

        try await render(RecallLabView(service: recall, onClose: {}), name: "recall-empty", size: NSSize(width: 780, height: 700))
        _ = recall.saveCard(question: "为什么间隔复习能帮助记忆？", answer: "先主动回忆，再核对答案；逐步延长复习间隔。\nActive recall strengthens retrieval. Spacing makes it last.", topic: "学习方法 / Learning")
        try await render(RecallLabView(service: recall, onClose: {}), name: "recall-library", size: NSSize(width: 780, height: 700))
        try await render(RecallLabView(service: recall, onClose: {}), name: "recall-minimum", size: NSSize(width: 520, height: 460))
        try await render(RecallCardEditor(card: recall.cards.first, zoom: 1, accent: .cyan, onSave: { _, _, _ in true }), name: "recall-editor", size: NSSize(width: 480, height: 510))
        #expect(recall.startReview())
        #expect(recall.reveal())
        try await render(RecallLabView(service: recall, onClose: {}), name: "recall-answer", size: NSSize(width: 780, height: 700))
        PreferencesManager.shared.preferences.windowZoomScale = 2
        try await render(RecallLabView(service: recall, onClose: {}), name: "recall-200", size: NSSize(width: 1_040, height: 760))
        try await render(RecallCardEditor(card: recall.cards.first, zoom: 2, accent: .cyan, onSave: { _, _, _ in true }), name: "recall-editor-200", size: NSSize(width: min(960, max(320, (NSScreen.main?.visibleFrame.width ?? 1_000) - 80)), height: min(1_020, max(300, (NSScreen.main?.visibleFrame.height ?? 800) - 100))))
        PreferencesManager.shared.preferences.windowZoomScale = 1
        #expect(recall.grade(.remembered))
        try await render(RecallLabView(service: recall, onClose: {}), name: "recall-complete", size: NSSize(width: 780, height: 700))
        var clock: TimeInterval = 10
        let drill = SwitchDrillService(clock: { clock })
        try await render(SwitchDrillView(service: drill, onClose: {}, onOpenPreflight: {}), name: "drill-empty", size: NSSize(width: 760, height: 720))
        let target = SwitchDrillTarget(id: UUID(), name: "Study / 学习资料", shortcut: "⌘⇧1", kind: .browser)
        try await render(SwitchDrillView(service: drill, onClose: {}, onOpenPreflight: {}), name: "drill-ready", size: NSSize(width: 760, height: 720)) {
            drill.updateTargets([target])
            #expect(drill.start(delay: 2))
            clock = 13
            drill.refreshTime()
            #expect(drill.session.phase == .ready)
        }
        try await render(SwitchDrillView(service: drill, onClose: {}, onOpenPreflight: {}), name: "drill-result", size: NSSize(width: 760, height: 720)) {
            drill.cancel()
            drill.updateTargets([target])
            #expect(drill.start(delay: 2))
            clock = 16
            drill.refreshTime()
            clock = 16.35
            let request = drill.shortcutPressed(targetID: target.id)
            clock = 16.7
            drill.complete(requestID: request, success: true)
            #expect(drill.session.result?.outcome == .success)
        }
        PreferencesManager.shared.preferences.windowZoomScale = 2
        try await render(SwitchDrillView(service: drill, onClose: {}, onOpenPreflight: {}), name: "drill-200", size: NSSize(width: 1_040, height: 760)) {
            drill.cancel()
            drill.updateTargets([target])
            #expect(drill.start(delay: 2))
            clock = 20
            drill.refreshTime()
        }
        recall.flush()
        drill.cancel()
    }

    @Test("Reading and curtain panels render editing, progress, completion, and enlarged states")
    func rendersReadingAndCurtain() async throws {
        #expect(NSImage(systemSymbolName: MainPanelFeature.readingLane.icon, accessibilityDescription: nil) != nil)
        #expect(NSImage(systemSymbolName: MainPanelFeature.screenCurtain.icon, accessibilityDescription: nil) != nil)
        let original = PreferencesManager.shared.preferences
        defer { PreferencesManager.shared.preferences = original }
        PreferencesManager.shared.preferences.windowZoomScale = 1
        let reading = ReadingLaneService()
        try await render(ReadingLaneView(service: reading, onClose: {}), name: "reading-empty", size: .init(width: 780, height: 700))
        reading.updateSource("学习不只是记住答案。试着把复杂概念拆成小块，再用自己的话解释。\n\nRead one passage at a time. Pause, connect it to what you know, and decide when you are ready to continue.")
        #expect(reading.start())
        try await render(ReadingLaneView(service: reading, onClose: {}), name: "reading-active", size: .init(width: 780, height: 700))
        try await render(ReadingLaneView(service: reading, onClose: {}), name: "reading-minimum", size: .init(width: 520, height: 460))
        PreferencesManager.shared.preferences.windowZoomScale = 2
        try await render(ReadingLaneView(service: reading, onClose: {}), name: "reading-200", size: .init(width: 1_040, height: 760))
        PreferencesManager.shared.preferences.windowZoomScale = 1
        reading.advance(); reading.advance()
        try await render(ReadingLaneView(service: reading, onClose: {}), name: "reading-complete", size: .init(width: 780, height: 700))
        try await render(ScreenCurtainView(onClose: {}), name: "curtain-panel", size: .init(width: 720, height: 700))
        PreferencesManager.shared.preferences.windowZoomScale = 2
        try await render(ScreenCurtainView(onClose: {}), name: "curtain-200", size: .init(width: 1_040, height: 760))
        try await render(ScreenCurtainOverlay(deadline: ProcessInfo.processInfo.systemUptime + 30, onDismiss: {}), name: "curtain-overlay", size: .init(width: 960, height: 600))
    }

    @Test("Arithmetic and return panels render setup, answers, results, and unavailable apps at supported scales")
    func rendersNumbersAndReturnDock() async throws {
        for symbol in [MainPanelFeature.numberSprint.icon, MainPanelFeature.returnDock.icon, "plus.forwardslash.minus"] {
            #expect(NSImage(systemSymbolName: symbol, accessibilityDescription: nil) != nil)
        }
        let original = PreferencesManager.shared.preferences
        defer { PreferencesManager.shared.preferences = original }
        PreferencesManager.shared.preferences.windowZoomScale = 1
        PreferencesManager.shared.preferences.enableSoundEffects = false
        PreferencesManager.shared.preferences.enableHapticFeedback = false
        let numbers = NumberSprintService()
        try await render(NumberSprintView(service: numbers, onClose: {}), name: "numbers-setup", size: .init(width: 720, height: 700))
        numbers.difficulty = .challenge
        numbers.start()
        try await render(NumberSprintView(service: numbers, onClose: {}), name: "numbers-active", size: .init(width: 720, height: 700))
        try await render(NumberSprintView(service: numbers, onClose: {}), name: "numbers-minimum", size: .init(width: 520, height: 460))
        PreferencesManager.shared.preferences.windowZoomScale = 2
        try await render(NumberSprintView(service: numbers, onClose: {}), name: "numbers-200", size: .init(width: 1_040, height: 760))
        PreferencesManager.shared.preferences.windowZoomScale = 1
        numbers.reveal()
        try await render(NumberSprintView(service: numbers, onClose: {}), name: "numbers-revealed", size: .init(width: 720, height: 700))
        numbers.advance()
        while let question = numbers.session.currentQuestion {
            #expect(numbers.submit(String(question.answer)) == .correct)
            numbers.advance()
        }
        try await render(NumberSprintView(service: numbers, onClose: {}), name: "numbers-complete", size: .init(width: 720, height: 700))
        var app = ReturnApplication(processID: 100, bundleIdentifier: "example.editor", launchDate: Date(), name: "Study notes / 学习笔记")
        var available = true
        let dock = ReturnDockService(ownBundleIdentifier: "self", frontmost: { app }, activate: { _ in false }, isRunning: { _ in available })
        try await render(ReturnDockView(service: dock, onClose: {}, onOpenDestinTab: {}), name: "return-disabled", size: .init(width: 720, height: 700))
        dock.setEnabled(true)
        try await render(ReturnDockView(service: dock, onClose: {}, onOpenDestinTab: {}), name: "return-enabled", size: .init(width: 720, height: 700))
        dock.complete(request: dock.prepare(destination: "example.browser"), success: true)
        app = ReturnApplication(processID: 200, bundleIdentifier: "example.canvas", launchDate: Date(), name: "Design canvas / 设计画板")
        dock.complete(request: dock.prepare(destination: "example.browser"), success: true)
        try await render(ReturnDockView(service: dock, onClose: {}, onOpenDestinTab: {}), name: "return-tickets", size: .init(width: 720, height: 700))
        try await render(ReturnDockView(service: dock, onClose: {}, onOpenDestinTab: {}), name: "return-minimum", size: .init(width: 520, height: 460))
        available = false
        try await render(ReturnDockView(service: dock, onClose: {}, onOpenDestinTab: {}), name: "return-closed", size: .init(width: 720, height: 700))
        PreferencesManager.shared.preferences.windowZoomScale = 2
        try await render(ReturnDockView(service: dock, onClose: {}, onOpenDestinTab: {}), name: "return-200", size: .init(width: 1_040, height: 760))
    }

    @Test("Teach Back and Quiet Desk render drafts, review, mute, and recovery states")
    func rendersTeachBackAndQuietDesk() async throws {
        #expect(NSImage(systemSymbolName: MainPanelFeature.teachBack.icon, accessibilityDescription: nil) != nil)
        #expect(NSImage(systemSymbolName: MainPanelFeature.quietDesk.icon, accessibilityDescription: nil) != nil)
        let original = PreferencesManager.shared.preferences
        defer { PreferencesManager.shared.preferences = original }
        PreferencesManager.shared.preferences.windowZoomScale = 1
        PreferencesManager.shared.preferences.enableSoundEffects = false
        PreferencesManager.shared.preferences.enableHapticFeedback = false
        let teach = TeachBackService()
        try await render(TeachBackView(service: teach, onClose: {}), name: "teach-topic", size: .init(width: 720, height: 700))
        teach.update(.topic, text: "为什么白天能看到月亮？ / The daytime Moon")
        teach.next()
        teach.update(.explanation, text: "月亮反射太阳光。只要它在地平线之上，与太阳的角距离和天空亮度也合适，白天也能看到它。\nThe Moon reflects sunlight and can be above the horizon during the day.")
        try await render(TeachBackView(service: teach, onClose: {}), name: "teach-explanation", size: .init(width: 720, height: 700))
        try await render(TeachBackView(service: teach, onClose: {}), name: "teach-minimum", size: .init(width: 520, height: 460))
        PreferencesManager.shared.preferences.windowZoomScale = 2
        try await render(TeachBackView(service: teach, onClose: {}), name: "teach-200", size: .init(width: 1_040, height: 760))
        PreferencesManager.shared.preferences.windowZoomScale = 1
        teach.next()
        teach.update(.example, text: "下午有时能看到上弦月。 / A first-quarter Moon can be visible in the afternoon.")
        teach.next(); teach.next()
        try await render(TeachBackView(service: teach, onClose: {}), name: "teach-review", size: .init(width: 720, height: 700))
        var output = QuietDevice(uid: "test.one", name: "Built-in output / 内建输出")
        var states = [output.uid: false]
        var acceptsWrites = true
        let quiet = QuietDeskService(defaultOutput: { output }, readMute: { states[$0.uid] }, writeMute: { device, value in
            guard acceptsWrites else { return false }
            states[device.uid] = value
            return true
        })
        defer { quiet.stopMonitoring() }
        try await render(QuietDeskView(service: quiet, onClose: {}), name: "quiet-ready", size: .init(width: 720, height: 700))
        #expect(quiet.mute())
        try await render(QuietDeskView(service: quiet, onClose: {}), name: "quiet-muted", size: .init(width: 720, height: 700))
        try await render(QuietDeskView(service: quiet, onClose: {}), name: "quiet-minimum", size: .init(width: 520, height: 460))
        output = QuietDevice(uid: "test.two", name: "Headphones / 耳机")
        states[output.uid] = false
        quiet.refresh()
        try await render(QuietDeskView(service: quiet, onClose: {}), name: "quiet-changed", size: .init(width: 720, height: 700))
        acceptsWrites = false
        #expect(!quiet.restore())
        try await render(QuietDeskView(service: quiet, onClose: {}), name: "quiet-failed", size: .init(width: 720, height: 700))
        PreferencesManager.shared.preferences.windowZoomScale = 2
        try await render(QuietDeskView(service: quiet, onClose: {}), name: "quiet-200", size: .init(width: 1_040, height: 760))
        PreferencesManager.shared.preferences.windowZoomScale = 1
        quiet.forget()
        states = [:]
        quiet.refresh()
        try await render(QuietDeskView(service: quiet, onClose: {}), name: "quiet-unsupported", size: .init(width: 720, height: 700))
    }

    @Test("Native curtains cover every connected screen and Escape releases every window")
    func nativeCurtainEscape() async throws {
        let display = NativeScreenCurtainDisplay()
        defer { display.dismiss() }
        let count = display.show(duration: 15) { display.dismiss() }
        #expect(count == NSScreen.screens.count)
        let windows = NSApplication.shared.windows.compactMap { $0 as? ScreenCurtainWindow }.filter(\.isVisible)
        #expect(windows.count == count)
        #expect(windows.allSatisfy { $0.isOpaque && $0.level == .screenSaver })
        #expect(NSScreen.screens.allSatisfy { screen in windows.contains { $0.frame == screen.frame } })
        try await Task.sleep(for: .milliseconds(200))
        if let first = windows.first {
            let escape = try #require(NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
                windowNumber: first.windowNumber, context: nil,
                characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}",
                isARepeat: false, keyCode: 53
            ))
            NSApplication.shared.sendEvent(escape)
        }
        #expect(windows.allSatisfy { !$0.isVisible })
    }

    @Test("Queued video completion cannot advance wallpaper after its player is removed")
    func ignoresRemovedWallpaperPlayer() async throws {
        let engine = WallpaperEngine.shared
        let original = (engine.isEnabled, engine.isPlaying, engine.isMuted, engine.playbackMode, engine.playlist, engine.currentWallpaper)
        defer {
            (engine.isEnabled, engine.isPlaying, engine.isMuted, engine.playbackMode, engine.playlist, engine.currentWallpaper) = original
        }
        let file = try silentMediaFile()
        defer { try? FileManager.default.removeItem(at: file) }
        engine.isEnabled = true
        engine.isPlaying = false
        engine.isMuted = true
        engine.playbackMode = .listLoop
        engine.playlist = ["First", "Second"].map { WallpaperItem(name: $0, filePath: file.path, type: .video) }
        let view = VideoWallpaperNSView()
        defer { view.stopPlayback() }
        func loadPlayer() async throws -> AVPlayer {
            view.loadVideo(url: file, coordinatesPlayback: true)
            var player: AVPlayer?
            for _ in 0..<100 {
                player = view.layer?.sublayers?.compactMap { ($0 as? AVPlayerLayer)?.player }.first
                if player != nil { break }
                try await Task.sleep(for: .milliseconds(20))
            }
            return try #require(player)
        }
        let loadedPlayer = try await loadPlayer()
        let item = try #require(loadedPlayer.currentItem)
        var advances = 0
        let token = NotificationCenter.default.addObserver(forName: .wallpaperVideoDidLoop, object: nil, queue: .main) { _ in
            advances += 1
        }
        defer { NotificationCenter.default.removeObserver(token) }
        engine.isPlaying = true
        NotificationCenter.default.post(name: .AVPlayerItemDidPlayToEndTime, object: item)
        view.stopPlayback()
        try await Task.sleep(for: .milliseconds(100))
        #expect(advances == 0)
        #expect(loadedPlayer.rate == 0)
        #expect(loadedPlayer.currentItem == nil)
        engine.isPlaying = false
        let currentPlayer = try await loadPlayer()
        let currentItem = try #require(currentPlayer.currentItem)
        engine.isPlaying = true
        NotificationCenter.default.post(name: .AVPlayerItemDidPlayToEndTime, object: currentItem)
        try await Task.sleep(for: .milliseconds(100))
        #expect(advances == 1)
    }

    @Test("Queued wallpaper navigation respects pause, disable, and manual selection")
    func cancelsQueuedWallpaperNavigation() async throws {
        let engine = WallpaperEngine.shared
        let original = (engine.isEnabled, engine.isPlaying, engine.playbackMode, engine.playlist, engine.currentWallpaper)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("ClassGodLoop-\(UUID()).mov")
        try Data().write(to: file)
        defer {
            (engine.isEnabled, engine.isPlaying, engine.playbackMode, engine.playlist, engine.currentWallpaper) = original
            try? FileManager.default.removeItem(at: file)
        }
        let items = ["First", "Second", "Third"].map { WallpaperItem(name: $0, filePath: file.path, type: .video) }
        engine.playlist = items
        engine.playbackMode = .listLoop
        for action in ["pause", "disable", "select", "resume", "reenable", "reselect", "normal"] {
            engine.isEnabled = true
            engine.isPlaying = true
            engine.currentWallpaper = items[0]
            NotificationCenter.default.post(name: .wallpaperVideoDidLoop, object: nil)
            switch action {
            case "pause": _ = engine.togglePlayPause()
            case "disable": _ = engine.setEnabled(false)
            case "select": _ = engine.selectWallpaper(items[2])
            case "resume": _ = engine.togglePlayPause(); _ = engine.togglePlayPause()
            case "reenable": _ = engine.setEnabled(false); _ = engine.setEnabled(true)
            case "reselect": _ = engine.selectWallpaper(items[2]); _ = engine.selectWallpaper(items[0])
            default: break
            }
            try await Task.sleep(for: .milliseconds(100))
            let expected = action == "normal" ? items[1] : action == "select" ? items[2] : items[0]
            #expect(engine.currentWallpaper?.id == expected.id)
            if action == "disable" { #expect(!engine.isEnabled) }
        }
    }

    @Test("Hiding desktop wallpaper stops retained native players immediately")
    func releasesHiddenDesktopPlayback() async throws {
        let engine = WallpaperEngine.shared
        let desktop = DesktopWallpaperController.shared
        let original = (engine.isEnabled, engine.showOnDesktop, engine.isPlaying, engine.isMuted, engine.playbackMode, engine.currentWallpaper)
        let file = try silentMediaFile()
        var videos: [VideoWallpaperNSView] = []
        defer {
            videos.forEach { $0.stopPlayback() }
            desktop.hideWallpapers()
            (engine.isEnabled, engine.showOnDesktop, engine.isPlaying, engine.isMuted, engine.playbackMode, engine.currentWallpaper) = original
            desktop.refreshWindows()
            try? FileManager.default.removeItem(at: file)
        }
        engine.isEnabled = true
        engine.showOnDesktop = true
        engine.isPlaying = true
        engine.isMuted = true
        engine.playbackMode = .singleLoop
        engine.currentWallpaper = WallpaperItem(name: "Silent fixture", filePath: file.path, type: .video)
        desktop.refreshWindows()
        func videoViews(_ view: NSView) -> [VideoWallpaperNSView] {
            (view as? VideoWallpaperNSView).map { [$0] } ?? view.subviews.flatMap(videoViews)
        }
        var players: [AVPlayer] = []
        for _ in 0..<100 {
            videos = NSApplication.shared.windows.compactMap(\.contentView).flatMap(videoViews)
            players = videos.flatMap { $0.layer?.sublayers?.compactMap { ($0 as? AVPlayerLayer)?.player } ?? [] }
            if players.count == NSScreen.screens.count, players.allSatisfy({ $0.rate > 0 }) { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(players.count == NSScreen.screens.count)
        #expect(players.allSatisfy { $0.rate > 0 })
        let windows = videos.compactMap(\.window)
        desktop.hideWallpapers()
        #expect(windows.allSatisfy { !$0.isVisible })
        #expect(players.allSatisfy { $0.rate == 0 && $0.currentItem == nil })
        desktop.refreshWindows()
        var reopened: [VideoWallpaperNSView] = []
        var reopenedPlayers: [AVPlayer] = []
        for _ in 0..<100 {
            reopened = NSApplication.shared.windows.compactMap(\.contentView).flatMap(videoViews)
            reopenedPlayers = reopened.flatMap { $0.layer?.sublayers?.compactMap { ($0 as? AVPlayerLayer)?.player } ?? [] }
            if reopenedPlayers.count == NSScreen.screens.count, reopenedPlayers.allSatisfy({ $0.rate > 0 }) { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        videos += reopened
        #expect(reopenedPlayers.count == NSScreen.screens.count)
        #expect(reopenedPlayers.allSatisfy { $0.rate > 0 })
        #expect(reopened.allSatisfy { $0.window?.isVisible == true })
        desktop.refreshContent()
        #expect(reopenedPlayers.allSatisfy { $0.rate == 0 && $0.currentItem == nil })
    }

    @Test("Training actions scale with zoom and preserve keyboard activation and disabled behavior")
    func scalesTrainingActions() async throws {
        func size(zoom: CGFloat) -> NSSize {
            let host = NSHostingView(rootView: Button("quiet.restore") {}
                .buttonStyle(TrainingButtonStyle(accent: .pink, zoom: zoom, prominent: true)))
            return host.fittingSize
        }
        let standard = size(zoom: 1)
        let enlarged = size(zoom: 2)
        #expect(standard.height >= 30)
        #expect(enlarged.height >= standard.height * 1.8)
        #expect(enlarged.width >= standard.width * 1.8)
        var activations = 0
        let window = NSWindow(contentRect: .init(x: 0, y: 0, width: 320, height: 100), styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        for enabled in [true, false] {
            window.contentView = NSHostingView(rootView: Button("button.save") { activations += 1 }
                .buttonStyle(TrainingButtonStyle(accent: .cyan, zoom: 2, prominent: true))
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!enabled))
            window.makeKeyAndOrderFront(nil)
            try await Task.sleep(for: .milliseconds(100))
            let event = try #require(NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0,
                windowNumber: window.windowNumber, context: nil, characters: "s", charactersIgnoringModifiers: "s", isARepeat: false, keyCode: 1
            ))
            _ = window.performKeyEquivalent(with: event)
            #expect(activations == 1)
        }
    }

    private func silentMediaFile() throws -> URL {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("ClassGodSilent-\(UUID()).wav")
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            var littleEndian = value.littleEndian
            withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
        }
        data.append(contentsOf: "RIFF".utf8); append(UInt32(16_036))
        data.append(contentsOf: "WAVEfmt ".utf8); append(UInt32(16))
        append(UInt16(1)); append(UInt16(1)); append(UInt32(8_000)); append(UInt32(16_000))
        append(UInt16(2)); append(UInt16(16))
        data.append(contentsOf: "data".utf8); append(UInt32(16_000))
        data.append(Data(count: 16_000))
        try data.write(to: file)
        return file
    }

    private func render<Content: View>(_ content: Content, name: String, size: NSSize, prepare: () -> Void = {}) async throws {
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let host = NSHostingView(rootView: content)
        window.contentView = host
        host.frame = NSRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(150))
        prepare()
        try await Task.sleep(for: .milliseconds(100))
        host.layoutSubtreeIfNeeded()
        let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        #expect(bitmap.pixelsWide > 0 && bitmap.pixelsHigh > 0)
        if let output = ProcessInfo.processInfo.environment["CLASSGOD_TRAINING_SNAPSHOTS"] {
            let directory = URL(fileURLWithPath: output, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let png = try #require(bitmap.representation(using: .png, properties: [:]))
            try png.write(to: directory.appendingPathComponent(name + ".png"), options: .atomic)
        }
        window.close()
    }
}
