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
    
    private let gridColumns = [
        GridItem(.adaptive(minimum: 96, maximum: 110), spacing: 10)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Hacker title bar
            HStack(spacing: 0) {
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    onClose()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 24, height: 24)
                        .background(Color(white: 0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)
                
                Spacer()
                
                Text("Wallpaper Engine")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Color.clear.frame(width: 36, height: 24)
            }
            .padding(.vertical, 8)
            .background(Color(white: 0.03))
            
            Divider().background(Color.white.opacity(0.1))
            
            // Main content
            ScrollView {
                VStack(spacing: 14) {
                    nowPlayingSection
                    
                    Divider().background(Color.white.opacity(0.06))
                    
                    playlistSection
                }
                .padding(14)
            }
        }
        .background(Color.black)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
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
        .alert("Delete Wallpaper?", isPresented: $showDeleteConfirmation, presenting: itemToDelete) { item in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    engine.removeWallpaper(item)
                }
                SoundEffectManager.shared.playWallpaperDeleted()
            }
        } message: { item in
            Text("Remove '\(item.name)' from your wallpaper library?")
        }
    }
    
    // MARK: - Now Playing
    
    private var nowPlayingSection: some View {
        VStack(spacing: 10) {
            // Preview with animated glow if active
            ZStack {
                // Glow effect when enabled
                if engine.isEnabled {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.cyan.opacity(0.25), lineWidth: 1.5)
                        .blur(radius: engine.isPlaying ? 2 : 0)
                        .frame(height: 130)
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.04))
                        .frame(height: 130)
                    
                    if let current = engine.currentWallpaper, current.fileExists {
                        if current.type == .image, let nsImage = NSImage(contentsOf: current.fileURL!) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 130)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            // Video placeholder with film icon
                            ZStack {
                                Image(systemName: "film.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.white.opacity(0.15))
                                
                                VStack(spacing: 4) {
                                    Spacer()
                                    Text(current.name)
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.6))
                                        .lineLimit(1)
                                        .padding(.horizontal, 8)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "play.rectangle.fill")
                                            .font(.system(size: 8))
                                        Text("VIDEO")
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    }
                                    .foregroundStyle(.cyan.opacity(0.7))
                                    .padding(.bottom, 8)
                                }
                            }
                        }
                        
                        // Status badge
                        VStack {
                            HStack {
                                Spacer()
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(engine.isEnabled && engine.isPlaying ? Color.green : Color.red)
                                        .frame(width: 6, height: 6)
                                    Text(engine.isEnabled && engine.isPlaying ? "LIVE" : "PAUSED")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Capsule())
                                .padding(8)
                            }
                            Spacer()
                        }
                    } else {
                        emptyPreview
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
            
            // Controls
            HStack(spacing: 10) {
                // Prev
                ControlButton(icon: "backward.fill", size: 14) {
                    engine.previousWallpaper()
                    SoundEffectManager.shared.playWallpaperSwitched()
                }
                .disabled(engine.playlist.isEmpty)
                
                // Play/Pause
                Button(action: {
                    SoundEffectManager.shared.playWallpaperPlayPause()
                    engine.togglePlayPause()
                }) {
                    Image(systemName: engine.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(engine.currentWallpaper != nil ? .white : .white.opacity(0.2))
                        .shadow(color: engine.isPlaying ? Color.cyan.opacity(0.3) : Color.clear, radius: 8)
                }
                .buttonStyle(.plain)
                .disabled(engine.currentWallpaper == nil)
                
                // Next
                ControlButton(icon: "forward.fill", size: 14) {
                    engine.nextWallpaper()
                    SoundEffectManager.shared.playWallpaperSwitched()
                }
                .disabled(engine.playlist.isEmpty)
                
                Spacer()
                
                // Mute
                ControlButton(
                    icon: engine.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                    size: 12,
                    color: engine.isMuted ? .white.opacity(0.3) : .white.opacity(0.6)
                ) {
                    SoundEffectManager.shared.playButtonClick()
                    engine.toggleMute()
                }
                
                // Volume
                if engine.currentWallpaper?.type == .video {
                    Slider(value: .init(
                        get: { engine.volume },
                        set: { engine.setVolume($0) }
                    ), in: 0...1)
                    .frame(width: 70)
                    .controlSize(.small)
                }
                
                Spacer()
                
                // Playback mode
                ControlButton(icon: engine.playbackMode.iconName, size: 12, color: .white.opacity(0.5)) {
                    SoundEffectManager.shared.playButtonClick()
                    let modes = WallpaperPlaybackMode.allCases
                    if let idx = modes.firstIndex(of: engine.playbackMode) {
                        engine.playbackMode = modes[(idx + 1) % modes.count]
                    }
                }
                .help(engine.playbackMode.displayName)
                
                // Enable toggle
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
    }
    
    private var emptyPreview: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.15))
            Text("No wallpaper selected")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
        }
    }
    
    // MARK: - Playlist
    
    private var playlistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LIBRARY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(2)
                
                Spacer()
                
                Text("\(engine.playlist.count) item\(engine.playlist.count == 1 ? "" : "s")")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    showImportPanel = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("Import")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.cyan.opacity(0.15))
                    .foregroundStyle(.cyan)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            if engine.playlist.isEmpty {
                dropZone
            } else {
                LazyVGrid(columns: gridColumns, spacing: 10) {
                    ForEach(engine.playlist) { item in
                        wallpaperThumbnail(item: item)
                    }
                }
            }
        }
    }
    
    private var dropZone: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.12))
            Text("Drop images or videos")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.25))
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(Color(white: 0.02))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
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
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    // Thumbnail
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(white: 0.05))
                            .aspectRatio(1, contentMode: .fit)
                        
                        if item.type == .image, let nsImage = NSImage(contentsOf: item.fileURL!) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            ZStack {
                                Image(systemName: item.type.iconName)
                                    .font(.system(size: 22))
                                    .foregroundStyle(.white.opacity(0.15))
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.4))
                                    .offset(y: 14)
                            }
                        }
                        
                        // Type badge
                        Image(systemName: item.type.iconName)
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Circle())
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(4)
                    }
                    
                    // Delete button (on hover or always visible)
                    Button(action: {
                        SoundEffectManager.shared.playButtonClick()
                        itemToDelete = item
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 16, height: 16)
                            .background(Color.red.opacity(0.85))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .offset(x: 4, y: -4)
                    .opacity(isHovered || isSelected ? 1 : 0)
                    .animation(.easeInOut(duration: 0.15), value: isHovered)
                }
                
                Text(item.name)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(isSelected ? .cyan : .white.opacity(0.5))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text(sizeText)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.25))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoverItemID = hovering ? item.id : nil
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.cyan.opacity(0.5) : (isHovered ? Color.white.opacity(0.12) : Color.clear), lineWidth: isSelected ? 1.5 : 1)
                .shadow(color: isSelected ? Color.cyan.opacity(0.2) : Color.clear, radius: 4)
        )
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
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
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
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
    let icon: String
    let size: CGFloat
    var color: Color = .white.opacity(0.7)
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(isHovered ? Color(white: 0.12) : Color.clear)
                .clipShape(Circle())
                .scaleEffect(isPressed ? 0.88 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .pressEvents {
            withAnimation(.easeOut(duration: 0.06)) { isPressed = true }
        } onRelease: {
            withAnimation(.easeOut(duration: 0.1)) { isPressed = false }
        }
    }
}

// MARK: - Preview

#Preview {
    WallpaperBrowserView(onClose: {})
        .frame(width: 520, height: 480)
        .background(Color.black)
}
