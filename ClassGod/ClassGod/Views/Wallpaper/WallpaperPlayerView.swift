//
//  WallpaperPlayerView.swift
//  ClassGod
//

import SwiftUI
import AVFoundation

// MARK: - Main Player View

struct WallpaperPlayerView: View {
    let wallpaper: WallpaperItem
    
    var body: some View {
        Group {
            if let fileURL = wallpaper.fileURL, wallpaper.type == .video {
                VideoWallpaperView(fileURL: fileURL)
            } else if let fileURL = wallpaper.fileURL {
                ImageWallpaperView(fileURL: fileURL)
            } else {
                Color.black
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.animation(Anim.enabled ? .easeInOut(duration: Anim.duration * 2) : nil),
            removal: .opacity.animation(Anim.enabled ? .easeInOut(duration: Anim.duration) : nil)
        ))
    }
}

// MARK: - Image Wallpaper (with GIF support)

struct ImageWallpaperView: View {
    let fileURL: URL
    
    var body: some View {
        GeometryReader { geo in
            if let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
               CGImageSourceGetCount(imageSource) > 1 {
                AnimatedImageView(imageSource: imageSource, identifier: fileURL)
                    .frame(width: geo.size.width, height: geo.size.height)
            } else if let nsImage = NSImage(contentsOf: fileURL) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            } else {
                Color.black
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Animated Image (GIF) NSView

struct AnimatedImageView: NSViewRepresentable {
    let imageSource: CGImageSource
    let identifier: URL
    
    func makeNSView(context: Context) -> AnimatedImageNSView {
        let view = AnimatedImageNSView()
        view.loadAnimatedImage(imageSource, identifier: identifier)
        return view
    }
    
    func updateNSView(_ nsView: AnimatedImageNSView, context: Context) {
        nsView.loadAnimatedImage(imageSource, identifier: identifier)
    }

    static func dismantleNSView(_ nsView: AnimatedImageNSView, coordinator: ()) {
        nsView.stopAnimation()
    }
}

final class AnimatedImageNSView: NSView {
    private var timer: Timer?
    private var images: [NSImage] = []
    private var delays: [Double] = []
    private var currentFrame = 0
    private var imageView: NSImageView?
    private var currentIdentifier: URL?
    
    override func layout() {
        super.layout()
        imageView?.frame = bounds
    }
    
    func loadAnimatedImage(_ source: CGImageSource, identifier: URL) {
        guard currentIdentifier != identifier else { return }
        currentIdentifier = identifier
        
        // Clean up old timer and view
        timer?.invalidate()
        timer = nil
        imageView?.removeFromSuperview()
        imageView = nil
        
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        
        let count = CGImageSourceGetCount(source)
        images = []
        delays = []
        
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let size = NSSize(
                    width: CGFloat(cgImage.width),
                    height: CGFloat(cgImage.height)
                )
                images.append(NSImage(cgImage: cgImage, size: size))
                
                let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any]
                let gifProps = properties?[kCGImagePropertyGIFDictionary as String] as? [String: Any]
                let delay = gifProps?[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double
                    ?? gifProps?[kCGImagePropertyGIFDelayTime as String] as? Double
                    ?? 0.1
                delays.append(delay > 0 ? delay : 0.1)
            }
        }
        
        guard !images.isEmpty else { return }
        
        let iv = NSImageView()
        iv.imageScaling = .scaleAxesIndependently
        iv.frame = bounds
        addSubview(iv)
        imageView = iv
        iv.image = images[0]
        currentFrame = 0
        
        scheduleNextFrame()
    }
    
    private func scheduleNextFrame() {
        guard !images.isEmpty, !delays.isEmpty else { return }
        let delay = delays[currentFrame]
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.advanceFrame()
        }
    }
    
    func advanceFrame() {
        guard !images.isEmpty else { return }
        currentFrame = (currentFrame + 1) % images.count
        imageView?.image = images[currentFrame]
        scheduleNextFrame()
    }

    func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - Video Wallpaper

struct VideoWallpaperView: NSViewRepresentable {
    let fileURL: URL
    
    func makeNSView(context: Context) -> VideoWallpaperNSView {
        let view = VideoWallpaperNSView()
        view.loadVideo(url: fileURL)
        return view
    }
    
    func updateNSView(_ nsView: VideoWallpaperNSView, context: Context) {
        nsView.loadVideo(url: fileURL)
    }

    static func dismantleNSView(_ nsView: VideoWallpaperNSView, coordinator: ()) {
        nsView.stopPlayback()
    }
}

final class VideoWallpaperNSView: NSView {
    private var playerLayer: AVPlayerLayer?
    private var currentURL: URL?
    private var endObserverToken: NSObjectProtocol?
    private var stateObserverToken: NSObjectProtocol?
    
    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }
    
    func loadVideo(url: URL) {
        guard currentURL != url else {
            syncPlaybackState()
            return
        }
        currentURL = url
        
        // Full cleanup of old player
        cleanupPlayer()
        
        // Setup layer if needed
        if playerLayer == nil {
            wantsLayer = true
            layer?.backgroundColor = NSColor.black.cgColor
            
            let newLayer = AVPlayerLayer()
            newLayer.videoGravity = .resizeAspectFill
            newLayer.frame = bounds
            layer?.addSublayer(newLayer)
            playerLayer = newLayer
        }
        
        // Check playability asynchronously
        let asset = AVAsset(url: url)
        Task { @MainActor in
            do {
                let isPlayable = try await asset.load(.isPlayable)
                guard isPlayable else {
                    print("[VideoWallpaper] Asset not playable: \(url.lastPathComponent)")
                    return
                }
                self.setupPlayer(with: asset, url: url)
            } catch {
                print("[VideoWallpaper] Failed to load asset: \(error)")
            }
        }
    }
    
    private func setupPlayer(with asset: AVAsset, url: URL) {
        guard currentURL == url else { return } // Aborted if switched already
        
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        player.actionAtItemEnd = .none
        
        // Loop notification
        endObserverToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
            Task { @MainActor in
                if WallpaperEngine.shared.playbackMode != .singleLoop {
                    NotificationCenter.default.post(name: .wallpaperVideoDidLoop, object: nil)
                }
            }
        }
        
        // Observe engine state changes for reactive sync
        stateObserverToken = NotificationCenter.default.addObserver(
            forName: .wallpaperStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncPlaybackState()
        }
        
        playerLayer?.player = player
        syncPlaybackState()
    }
    
    func syncPlaybackState() {
        guard let player = playerLayer?.player else { return }
        let engine = WallpaperEngine.shared
        player.isMuted = engine.isMuted
        player.volume = Float(engine.volume)
        if engine.isEnabled && engine.isPlaying {
            player.play()
        } else {
            player.pause()
        }
    }
    
    private func cleanupPlayer() {
        if let token = endObserverToken {
            NotificationCenter.default.removeObserver(token)
            endObserverToken = nil
        }
        if let token = stateObserverToken {
            NotificationCenter.default.removeObserver(token)
            stateObserverToken = nil
        }
        if let player = playerLayer?.player {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
        playerLayer?.player = nil
    }

    func stopPlayback() {
        currentURL = nil
        cleanupPlayer()
    }
    
    deinit {
        cleanupPlayer()
    }
}

// MARK: - Wallpaper Overlay (dim gradient)

struct WallpaperOverlayView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.20),
                Color.black.opacity(0.50),
                Color.black.opacity(0.78)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}

// MARK: - Quick Access Bar (hover controls on main window)

struct WallpaperQuickAccessBar: View {
    @ObservedObject var engine = WallpaperEngine.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10 * zoomScale) {
            Button(action: {
                SoundEffectManager.shared.playWallpaperSwitched()
                engine.previousWallpaper()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 10 * zoomScale))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.7))
            .disabled(engine.playlist.isEmpty)
            
            Button(action: {
                SoundEffectManager.shared.playWallpaperPlayPause()
                engine.togglePlayPause()
            }) {
                Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 12 * zoomScale))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .disabled(engine.currentWallpaper == nil)
            
            Button(action: {
                SoundEffectManager.shared.playWallpaperSwitched()
                engine.nextWallpaper()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 10 * zoomScale))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.7))
            .disabled(engine.playlist.isEmpty)
            
            Divider()
                .background(Color.white.opacity(0.15))
                .frame(height: 14 * zoomScale)
            
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                engine.toggleMute()
            }) {
                Image(systemName: engine.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 9 * zoomScale))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.5))
            
            Text(engine.currentWallpaper?.name ?? String(localized: "wallpaper.none"))
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .lineLimit(1)
                .frame(maxWidth: 100 * zoomScale)
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 6 * zoomScale)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1 * zoomScale)
                )
        )
        .opacity(isHovered ? 1 : 0)
        .animation(Anim.enabled ? .easeInOut(duration: Anim.duration) : nil, value: isHovered)
        .onHover { isHovered = $0 }
    }
}
