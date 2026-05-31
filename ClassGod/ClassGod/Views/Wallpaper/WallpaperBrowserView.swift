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
    
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    var body: some View {
        VStack(spacing: 0 * zoomScale) {
            // Hacker title bar
            HStack(spacing: 0 * zoomScale) {
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
            
            Divider().background(Color.white.opacity(0.1))
            
            // Main content
            ScrollView {
                VStack(spacing: 14 * zoomScale) {
                    nowPlayingSection
                    
                    Divider().background(Color.white.opacity(0.06))
                    
                    playlistSection
                }
                .padding(14 * zoomScale)
            }
        }
        .background(Color.black)
        .overlay(
            RoundedRectangle(cornerRadius: 12 * zoomScale)
                .stroke(Color.white.opacity(0.12), lineWidth: 1 * zoomScale)
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
    
    // MARK: - Now Playing Status

    private var nowPlayingSection: some View {
        VStack(spacing: 10 * zoomScale) {
            // Status bar (no wallpaper preview — wallpaper is desktop-only)
            HStack(spacing: 12 * zoomScale) {
                // Type icon
                Image(systemName: engine.currentWallpaper?.type.iconName ?? "photo")
                    .font(.system(size: 14 * zoomScale))
                    .foregroundStyle(engine.currentWallpaper != nil ? .cyan : .white.opacity(0.2))
                    .frame(width: 32 * zoomScale, height: 32 * zoomScale)
                    .background(Color(white: 0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))

                VStack(alignment: .leading, spacing: 2) {
                    Text(engine.currentWallpaper?.name ?? "No wallpaper selected")
                        .font(.system(size: 12 * zoomScale, weight: .medium, design: .monospaced))
                        .foregroundStyle(engine.currentWallpaper != nil ? .white : .white.opacity(0.3))
                        .lineLimit(1)

                    HStack(spacing: 6 * zoomScale) {
                        // Status dot
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

                Spacer()

                // Desktop badge
                if engine.showOnDesktop && engine.isEnabled {
                    HStack(spacing: 3 * zoomScale) {
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 8 * zoomScale))
                        Text("DESKTOP")
                            .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(.cyan.opacity(0.7))
                    .padding(.horizontal, 8 * zoomScale)
                    .padding(.vertical, 4 * zoomScale)
                    .background(Color.cyan.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.cyan.opacity(0.2), lineWidth: 1 * zoomScale)
                    )
                }
            }
            .padding(.horizontal, 12 * zoomScale)
            .padding(.vertical, 10 * zoomScale)
            .background(Color(white: 0.03))
            .clipShape(RoundedRectangle(cornerRadius: 10 * zoomScale))
            .overlay(
                RoundedRectangle(cornerRadius: 10 * zoomScale)
                    .stroke(engine.isEnabled ? Color.cyan.opacity(0.15) : Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
            )

            // Controls
            HStack(spacing: 10 * zoomScale) {
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
                        .font(.system(size: 32 * zoomScale))
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

                // Volume (always reserve space so layout doesn't jump)
                HStack {
                    if engine.currentWallpaper?.type == .video {
                        Slider(value: .init(
                            get: { engine.volume },
                            set: { engine.setVolume($0) }
                        ), in: 0...1)
                        .controlSize(.small)
                    }
                }
                .frame(width: 70 * zoomScale)

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

                // Show on Desktop toggle
                HStack(spacing: 4 * zoomScale) {
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
                .help("Show wallpaper on macOS Desktop")

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

    private var statusColor: Color {
        guard engine.currentWallpaper != nil else { return .white.opacity(0.25) }
        if engine.isEnabled && engine.isPlaying { return .green }
        if engine.isEnabled { return .orange }
        return .white.opacity(0.3)
    }

    private var statusText: String {
        guard engine.currentWallpaper != nil else { return "IDLE" }
        if engine.isEnabled && engine.isPlaying { return "LIVE" }
        if engine.isEnabled { return "PAUSED" }
        return "OFF"
    }
    
    // MARK: - Playlist
    
    private var playlistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LIBRARY")
                    .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(2)
                
                Spacer()
                
                Text("\(engine.playlist.count) item\(engine.playlist.count == 1 ? "" : "s")")
                    .font(.system(size: 10 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    showImportPanel = true
                }) {
                    HStack(spacing: 4 * zoomScale) {
                        Image(systemName: "plus")
                            .font(.system(size: 10 * zoomScale, weight: .bold))
                        Text("Import")
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
                LazyVGrid(columns: gridColumns, spacing: 10) {
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
        .frame(maxWidth: .infinity, minHeight: 110 * zoomScale)
        .background(Color(white: 0.02))
        .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
        .overlay(
            RoundedRectangle(cornerRadius: 8 * zoomScale)
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
            VStack(spacing: 5 * zoomScale) {
                // Thumbnail container — fixed aspect ratio, clipped
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 6 * zoomScale)
                        .fill(Color(white: 0.05))

                    // Image / placeholder — constrained to fill the square exactly
                    Group {
                        if item.type == .image, let nsImage = NSImage(contentsOf: item.fileURL!) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            ZStack {
                                Image(systemName: item.type.iconName)
                                    .font(.system(size: 22 * zoomScale))
                                    .foregroundStyle(.white.opacity(0.15))
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10 * zoomScale))
                                    .foregroundStyle(.white.opacity(0.4))
                                    .offset(y: 14)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))

                    // Type badge (inside bounds)
                    Image(systemName: item.type.iconName)
                        .font(.system(size: 7 * zoomScale, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(3 * zoomScale)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                        .padding(4 * zoomScale)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                    // Delete button (inside bounds, no offset overflow)
                    Button(action: {
                        SoundEffectManager.shared.playButtonClick()
                        itemToDelete = item
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 7 * zoomScale, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 16 * zoomScale, height: 16 * zoomScale)
                            .background(Color.red.opacity(0.85))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(4 * zoomScale)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .opacity(isHovered || isSelected ? 1 : 0)
                    .animation(.easeInOut(duration: 0.15), value: isHovered)
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))

                // Name + size — fixed height to prevent vertical drift
                VStack(spacing: 2 * zoomScale) {
                    Text(item.name)
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(isSelected ? .cyan : .white.opacity(0.5))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text(sizeText)
                        .font(.system(size: 8 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.25))
                        .lineLimit(1)
                }
                .frame(height: 28, alignment: .top)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoverItemID = hovering ? item.id : nil
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8 * zoomScale)
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
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28 * zoomScale, height: 28 * zoomScale)
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
