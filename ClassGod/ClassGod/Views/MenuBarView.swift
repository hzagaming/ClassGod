//
//  MenuBarView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct MenuBarView: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    @ObservedObject private var wallpaperEngine = WallpaperEngine.shared
    var onClose: () -> Void
    var onOpenDestinTab: () -> Void
    var onOpenSuperSwitch: () -> Void
    var onOpenBrowserBypasser: () -> Void
    var onOpenAssessPrepHack: () -> Void
    var onOpenSettings: () -> Void
    var onOpenWallpaper: () -> Void
    var onOpenHackerDesktop: () -> Void
    
    var body: some View {
        ZStack {
            // Wallpaper layer (bottom)
            if wallpaperEngine.isEnabled,
               let wallpaper = wallpaperEngine.currentWallpaper,
               wallpaper.fileExists {
                WallpaperPlayerView(wallpaper: wallpaper)
                    .id(wallpaper.id)
                    .ignoresSafeArea()
                
                WallpaperOverlayView()
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                titleBar
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        FeatureButton(
                            icon: "link",
                            title: "DestinTab",
                            description: "Manage & switch browser tabs",
                            action: onOpenDestinTab
                        )
                        
                        FeatureButton(
                            icon: "arrow.left.arrow.right",
                            title: "SuperSwitch",
                            description: "Quick app switcher with shortcuts",
                            action: onOpenSuperSwitch
                        )
                        
                        FeatureButton(
                            icon: "lock.open.fill",
                            title: "BrowserBypasser",
                            description: "Break free from lockdown pages",
                            action: onOpenBrowserBypasser
                        )
                        
                        FeatureButton(
                            icon: "bolt.shield.fill",
                            title: "AssessPrepHack",
                            description: "Break free from proctoring",
                            action: onOpenAssessPrepHack
                        )
                        
                        FeatureButton(
                            icon: "photo.on.rectangle.angled",
                            title: "Wallpaper Engine",
                            description: "Custom wallpapers & live video",
                            action: onOpenWallpaper
                        )
                        
                        FeatureButton(
                            icon: "square.grid.2x2",
                            title: "HackerDesktop",
                            description: "System monitor widgets dashboard",
                            action: onOpenHackerDesktop
                        )
                    }
                    .padding()
                }
                
                Spacer(minLength: 0)
                
                VStack(spacing: 0) {
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            onOpenSettings()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 11))
                            Text("Settings")
                                .font(.system(size: 11, design: .monospaced))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.5))
                        
                        Spacer()
                        
                        // Quick wallpaper access bar (appears on hover)
                        if wallpaperEngine.isEnabled {
                            WallpaperQuickAccessBar()
                                .padding(.trailing, 4)
                        }
                        
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            NSApplication.shared.terminate(nil)
                        }) {
                            Text("PeaceOut")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleWallpaperDrop(providers: providers)
            return true
        }
        .frame(width: prefs.preferences.panelWidth, height: prefs.preferences.panelMaxHeight)
        .overlay(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Title Bar with Close Button
    
    private var titleBar: some View {
        HStack(spacing: 0) {
            // Close button
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                onClose()
            }) {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 24, height: 24)
                    .background(Color(white: 0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 12)
            
            Spacer()
            
            VStack(spacing: 0) {
                Text("ClassGod")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.6.0")")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
            
            Spacer()
            
            // Spacer to balance close button width
            Color.clear.frame(width: 36, height: 24)
        }
        .padding(.vertical, 8)
        .background(Color(white: 0.03))
    }
    
    private func handleWallpaperDrop(providers: [NSItemProvider]) {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    DispatchQueue.main.async {
                        WallpaperEngine.shared.addWallpaper(from: url)
                        SoundEffectManager.shared.playWallpaperAdded()
                    }
                }
            }
        }
    }
}

// MARK: - Feature Button

struct FeatureButton: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if isEnabled {
                SoundEffectManager.shared.playButtonClick()
                action()
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered && isEnabled ? Color(white: 0.12) : Color(white: 0.08))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isEnabled ? .white : .white.opacity(0.3))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(isEnabled ? .white : .white.opacity(0.3))
                    
                    Text(description)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isEnabled ? .white.opacity(0.4) : .white.opacity(0.1))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered && isEnabled ? Color(white: 0.06) : Color(white: 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered && isEnabled ? Color.white.opacity(0.25) : Color.white.opacity(0.06), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .pressEvents {
            withAnimation(.easeOut(duration: 0.08)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeOut(duration: 0.12)) {
                isPressed = false
            }
        }
    }
}

#Preview {
    MenuBarView(onClose: {}, onOpenDestinTab: {}, onOpenSuperSwitch: {}, onOpenBrowserBypasser: {}, onOpenAssessPrepHack: {}, onOpenSettings: {}, onOpenWallpaper: {}, onOpenHackerDesktop: {})
}
