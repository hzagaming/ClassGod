//
//  WallpaperBrowserView.swift
//  ClassGod
//

import SwiftUI
import UniformTypeIdentifiers

struct WallpaperBrowserView: View {
    @ObservedObject var engine = WallpaperEngine.shared
    @State private var showImportPanel = false
    @State private var itemToDelete: WallpaperItem?
    @State private var showDeleteConfirmation = false
    @State private var hoverItemID: UUID?
    var onClose: () -> Void
    
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 100 * zoomScale, maximum: 140 * zoomScale), spacing: 12 * zoomScale)
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider().background(Color.white.opacity(0.1))
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16 * zoomScale) {
                    nowPlayingCard
                    Divider().background(Color.white.opacity(0.06))
                    playlistSection
                }
                .padding(16 * zoomScale)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .background(Color.black)
        .overlay(
            RoundedRectangle(cornerRadius: 12 * zoomScale)
                .stroke(Color.white.opacity(0.12), lineWidth: 1 * zoomScale)
                .allowsHitTesting(false)
        )
        .fileImporter(
            isPresented: $showImportPanel,
            allowedContentTypes: [
                .image,
                .movie,
                UTType(filenameExtension: "mp4")!,
                UTType(filenameExtension: "mov")!,
                UTType(filenameExtension: "mkv")!,
                UTType(filenameExtension: "webm")!
            ],
            allowsMultipleSelection: true
        ) { result in
            handleImport(result: result)
        }
        .alert(String(localized: "wallpaper.delete_title"), isPresented: $showDeleteConfirmation, presenting: itemToDelete) { item in
            Button(String(localized: "button.cancel"), role: .cancel) {}
            Button(String(localized: "button.delete"), role: .destructive) {
                Anim.with {
                    engine.removeWallpaper(item)
                }
                SoundEffectManager.shared.playWallpaperDeleted()
                HapticManager.shared.warning()
            }
        } message: { item in
            Text(String(format: String(localized: "wallpaper.delete_message"), item.name))
        }
    }
    
    // MARK: - Header
    
    private var headerBar: some View {
        HStack(spacing: 0) {
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                onClose()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10 * zoomScale, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                    .background(Color(white: 0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 12 * zoomScale)
            
            Spacer()
            
            Text("Wallpaper Engine")
                .font(.system(size: 13 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            
            Spacer()
            
            Color.clear.frame(width: 36 * zoomScale, height: 24 * zoomScale)
        }
        .padding(.vertical, 8 * zoomScale)
        .background(Color(white: 0.03))
    }
    
    // MARK: - Now Playing
    
    private var nowPlayingCard: some View {
        VStack(spacing: 14 * zoomScale) {
            // Info row
            HStack(spacing: 12 * zoomScale) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10 * zoomScale)
                        .fill(Color(white: 0.06))
                    Image(systemName: engine.currentWallpaper?.type.iconName ?? "photo")
                        .font(.system(size: 22 * zoomScale))
                        .foregroundStyle(engine.currentWallpaper != nil ? .cyan : .white.opacity(0.2))
                }
                .frame(width: 56 * zoomScale, height: 56 * zoomScale)
                
                VStack(alignment: .leading, spacing: 4 * zoomScale) {
                    Text(engine.currentWallpaper?.name ?? String(localized: "wallpaper.none_selected"))
                        .font(.system(size: 13 * zoomScale, weight: .semibold, design: .monospaced))
                        .foregroundStyle(engine.currentWallpaper != nil ? .white : .white.opacity(0.35))
                        .lineLimit(1)
                    
                    HStack(spacing: 6 * zoomScale) {
                        HStack(spacing: 4 * zoomScale) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 5 * zoomScale, height: 5 * zoomScale)
                            Text(statusText)
                                .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(statusColor)
                        
                        if let current = engine.currentWallpaper {
                            Text("·")
                                .font(.system(size: 9 * zoomScale))
                                .foregroundStyle(.white.opacity(0.2))
                            Text(fileSizeString(current.fileURL))
                                .font(.system(size: 9 * zoomScale, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                }
                
                Spacer(minLength: 12 * zoomScale)
                
                if engine.showOnDesktop && engine.isEnabled {
                    HStack(spacing: 3 * zoomScale) {
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 8 * zoomScale))
                        Text("DESKTOP")
                            .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(.cyan.opacity(0.8))
                    .padding(.horizontal, 8 * zoomScale)
                    .padding(.vertical, 4 * zoomScale)
                    .background(Color.cyan.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.cyan.opacity(0.25), lineWidth: 1 * zoomScale)
                    )
                }
            }
            .padding(12 * zoomScale)
            .background(Color(white: 0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12 * zoomScale))
            .overlay(
                RoundedRectangle(cornerRadius: 12 * zoomScale)
                    .stroke(engine.isEnabled ? Color.cyan.opacity(0.15) : Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
            )
            
            // Transport controls pill
            HStack(spacing: 16 * zoomScale) {
                ControlButton(icon: "backward.fill", size: 14) {
                    engine.previousWallpaper()
                    SoundEffectManager.shared.playWallpaperSwitched()
                }
                .disabled(engine.playlist.isEmpty)
                
                Button(action: {
                    SoundEffectManager.shared.playWallpaperPlayPause()
                    engine.togglePlayPause()
                }) {
                    Image(systemName: engine.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 34 * zoomScale))
                        .foregroundStyle(engine.currentWallpaper != nil ? .white : .white.opacity(0.2))
                        .shadow(color: engine.isPlaying ? Color.cyan.opacity(0.35) : Color.clear, radius: 10 * zoomScale)
                }
                .buttonStyle(.plain)
                .disabled(engine.currentWallpaper == nil)
                
                ControlButton(icon: "forward.fill", size: 14) {
                    engine.nextWallpaper()
                    SoundEffectManager.shared.playWallpaperSwitched()
                }
                .disabled(engine.playlist.isEmpty)
            }
            .padding(.horizontal, 18 * zoomScale)
            .padding(.vertical, 8 * zoomScale)
            .background(Color(white: 0.04))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1 * zoomScale)
            )
            
            // Options row (scrolls if not enough room)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14 * zoomScale) {
                    // Volume group
                    HStack(spacing: 6 * zoomScale) {
                        ControlButton(
                            icon: engine.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                            size: 12,
                            color: engine.isMuted ? .white.opacity(0.3) : .white.opacity(0.6)
                        ) {
                            SoundEffectManager.shared.playButtonClick()
                            engine.toggleMute()
                        }
                        
                        Slider(value: .init(
                            get: { engine.volume },
                            set: { engine.setVolume($0) }
                        ), in: 0...1)
                        .controlSize(.mini)
                        .frame(width: 80 * zoomScale)
                        .opacity(engine.currentWallpaper?.type == .video ? 1 : 0.35)
                        .disabled(engine.currentWallpaper?.type != .video)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                        .frame(height: 20 * zoomScale)
                    
                    // Playback mode pill
                    Button(action: {
                        SoundEffectManager.shared.playButtonClick()
                        let modes = WallpaperPlaybackMode.allCases
                        if let idx = modes.firstIndex(of: engine.playbackMode) {
                            engine.playbackMode = modes[(idx + 1) % modes.count]
                        }
                    }) {
                        HStack(spacing: 4 * zoomScale) {
                            Image(systemName: engine.playbackMode.iconName)
                                .font(.system(size: 10 * zoomScale))
                            Text(engine.playbackMode.displayName)
                                .font(.system(size: 9 * zoomScale, design: .monospaced))
                        }
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 10 * zoomScale)
                        .padding(.vertical, 5 * zoomScale)
                        .background(Color(white: 0.08))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1 * zoomScale)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Desktop toggle pill
                    HStack(spacing: 6 * zoomScale) {
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 10 * zoomScale))
                            .foregroundStyle(engine.showOnDesktop ? .cyan : .white.opacity(0.3))
                        Toggle("", isOn: .init(
                            get: { engine.showOnDesktop },
                            set: { _ in
                                SoundEffectManager.shared.playButtonClick()
                                engine.toggleShowOnDesktop()
                            }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    }
                    .disabled(!engine.isEnabled)
                    
                    // Power toggle pill
                    HStack(spacing: 6 * zoomScale) {
                        Text(engine.isEnabled ? "ON" : "OFF")
                            .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                            .foregroundStyle(engine.isEnabled ? .green : .white.opacity(0.25))
                        Toggle("", isOn: .init(
                            get: { engine.isEnabled },
                            set: { _ in
                                SoundEffectManager.shared.playButtonClick()
                                engine.toggleEnabled()
                            }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 4 * zoomScale)
                .padding(.vertical, 2 * zoomScale)
            }
        }
    }
    
    private var statusColor: Color {
        guard engine.currentWallpaper != nil else { return .white.opacity(0.25) }
        if engine.isEnabled && engine.isPlaying { return .green }
        if engine.isEnabled { return .orange }
        return .white.opacity(0.3)
    }
    
    private var statusText: String {
        guard engine.currentWallpaper != nil else { return String(localized: "wallpaper.status.idle") }
        if engine.isEnabled && engine.isPlaying { return String(localized: "wallpaper.status.live") }
        if engine.isEnabled { return String(localized: "wallpaper.status.paused") }
        return String(localized: "wallpaper.status.off")
    }
    
    // MARK: - Playlist
    
    private var playlistSection: some View {
        VStack(alignment: .leading, spacing: 10 * zoomScale) {
            HStack(spacing: 0) {
                Text(String(localized: "wallpaper.library"))
                    .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(2)
                
                Spacer()
                
                Text(String(format: String(localized: "wallpaper.item_count"), engine.playlist.count))
                    .font(.system(size: 10 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    showImportPanel = true
                }) {
                    HStack(spacing: 4 * zoomScale) {
                        Image(systemName: "plus")
                            .font(.system(size: 10 * zoomScale, weight: .bold))
                        Text(String(localized: "button.import"))
                            .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 10 * zoomScale)
                    .padding(.vertical, 5 * zoomScale)
                    .background(Color.cyan.opacity(0.15))
                    .foregroundStyle(.cyan)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1 * zoomScale)
                    )
                }
                .buttonStyle(.plain)
            }
            
            if engine.playlist.isEmpty {
                dropZone
            } else {
                LazyVGrid(columns: gridColumns, spacing: 12 * zoomScale) {
                    ForEach(engine.playlist) { item in
                        wallpaperThumbnail(item: item)
                    }
                }
            }
        }
    }
    
    private var dropZone: some View {
        VStack(spacing: 8 * zoomScale) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 28 * zoomScale))
                .foregroundStyle(.white.opacity(0.12))
            Text("Drop images or videos")
                .font(.system(size: 11 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.25))
        }
        .frame(maxWidth: .infinity, minHeight: 120 * zoomScale)
        .background(Color(white: 0.02))
        .clipShape(RoundedRectangle(cornerRadius: 10 * zoomScale))
        .overlay(
            RoundedRectangle(cornerRadius: 10 * zoomScale)
                .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 1 * zoomScale, dash: [5 * zoomScale, 4 * zoomScale]))
                .allowsHitTesting(false)
        )
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    private func wallpaperThumbnail(item: WallpaperItem) -> some View {
        let isSelected = engine.currentWallpaper?.id == item.id
        let isHovered = hoverItemID == item.id
        let sizeText = fileSizeString(item.fileURL)
        
        return Button(action: {
            SoundEffectManager.shared.playWallpaperSwitched()
            engine.selectWallpaper(item)
        }) {
            VStack(spacing: 6 * zoomScale) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 8 * zoomScale)
                        .fill(Color(white: 0.05))
                    
                    Group {
                        if item.type == .image, let nsImage = NSImage(contentsOf: item.fileURL!) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            ZStack {
                                Image(systemName: item.type.iconName)
                                    .font(.system(size: 24 * zoomScale))
                                    .foregroundStyle(.white.opacity(0.15))
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10 * zoomScale))
                                    .foregroundStyle(.white.opacity(0.4))
                                    .offset(y: 16 * zoomScale)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
                    
                    // Type badge
                    Image(systemName: item.type.iconName)
                        .font(.system(size: 8 * zoomScale, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(3 * zoomScale)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                        .padding(5 * zoomScale)
                    
                    // Delete button
                    Button(action: {
                        SoundEffectManager.shared.playButtonClick()
                        itemToDelete = item
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 7 * zoomScale, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 18 * zoomScale, height: 18 * zoomScale)
                            .background(Color.red.opacity(0.85))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(5 * zoomScale)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .opacity(isHovered || isSelected ? 1 : 0)
                    .animation(Anim.enabled ? .easeInOut(duration: Anim.duration) : nil, value: isHovered)
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
                .overlay(
                    RoundedRectangle(cornerRadius: 8 * zoomScale)
                        .stroke(isSelected ? Color.cyan.opacity(0.6) : (isHovered ? Color.white.opacity(0.12) : Color.clear), lineWidth: isSelected ? 2 : 1)
                        .shadow(color: isSelected ? Color.cyan.opacity(0.25) : Color.clear, radius: 4 * zoomScale)
                        .allowsHitTesting(false)
                )
                .scaleEffect(isHovered ? 1.03 : 1.0)
                .animation(Anim.enabled ? .easeOut(duration: Anim.duration) : nil, value: isHovered)
                
                VStack(spacing: 2 * zoomScale) {
                    Text(item.name)
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(isSelected ? .cyan : .white.opacity(0.6))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text(sizeText)
                        .font(.system(size: 8 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.25))
                        .lineLimit(1)
                }
                .frame(height: 28 * zoomScale, alignment: .top)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoverItemID = hovering ? item.id : nil
        }
    }
    
    private func fileSizeString(_ url: URL?) -> String {
        guard let url = url else { return "" }
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attr[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
        } catch { }
        return ""
    }
    
    // MARK: - Import / Drop
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                engine.addWallpaper(from: url)
            }
            if !urls.isEmpty {
                SoundEffectManager.shared.playWallpaperAdded()
            }
        case .failure(let error):
            print("[WallpaperBrowser] Import failed: \(error)")
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        let group = DispatchGroup()
        var importedURLs: [URL] = []
        let lock = NSLock()
        
        for provider in providers {
            group.enter()
            provider.loadObject(ofClass: NSURL.self) { item, _ in
                if let url = item as? URL, url.isFileURL {
                    lock.lock()
                    importedURLs.append(url)
                    lock.unlock()
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            for url in importedURLs {
                WallpaperEngine.shared.addWallpaper(from: url)
            }
            if !importedURLs.isEmpty {
                SoundEffectManager.shared.playWallpaperAdded()
            }
        }
    }
}

// MARK: - Control Button

struct ControlButton: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    let icon: String
    let size: CGFloat
    var color: Color = .white.opacity(0.7)
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * zoomScale, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28 * zoomScale, height: 28 * zoomScale)
                .background(isHovered ? Color(white: 0.12) : Color.clear)
                .clipShape(Circle())
                .scaleEffect(isPressed ? 0.88 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .pressEvents {
            Anim.with { isPressed = true }
        } onRelease: {
            Anim.with { isPressed = false }
        }
    }
}

// MARK: - Preview

#Preview {
    WallpaperBrowserView(onClose: {})
        .frame(width: 560, height: 560)
        .background(Color.black)
}
