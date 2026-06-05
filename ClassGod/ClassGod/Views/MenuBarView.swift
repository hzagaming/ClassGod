//
//  MenuBarView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var fanSummaryTemp: Double = 0
    @State private var fanSummaryRPM: Double = 0
    @State private var fanSummaryTimer: Timer?
    @State private var sleepObserverTokens: [any NSObjectProtocol] = []

    var onClose: () -> Void
    var onOpenDestinTab: () -> Void
    var onOpenSuperSwitch: () -> Void
    var onOpenBrowserBypasser: () -> Void
    var onOpenAssessPrepHack: () -> Void
    var onOpenSettings: () -> Void
    var onOpenWallpaper: () -> Void
    var onOpenHackerDesktop: () -> Void
    var onOpenFanControl: () -> Void
    var onOpenErrorHub: () -> Void
    
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea().allowsHitTesting(false)
            
            VStack(spacing: 0 * zoomScale) {
                titleBar
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10 * zoomScale) {
                        if prefs.preferences.enableFanControl {
                            fanSummaryCard
                        }

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
                        
                        FeatureButton(
                            icon: "exclamationmark.triangle.fill",
                            title: "Error Encyclopedia",
                            description: "Search & solve all Swift/macOS errors",
                            action: onOpenErrorHub
                        )
                        
                        FeatureButton(
                            icon: "fanblades",
                            title: "Fan Control",
                            description: "Monitor temps & control fan speeds",
                            action: onOpenFanControl,
                            isEnabled: prefs.preferences.enableFanControl
                        )
                    }
                    .padding()
                }
                
                Spacer(minLength: 0)
                
                VStack(spacing: 0 * zoomScale) {
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack(spacing: 12 * zoomScale) {
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            onOpenSettings()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 11 * zoomScale))
                            Text("Settings")
                                .font(.system(size: 11 * zoomScale, design: .monospaced))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.5))
                        
                        Spacer()
                        
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            NSApplication.shared.terminate(nil)
                        }) {
                            Text("PeaceOut")
                                .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                                .foregroundStyle(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10 * zoomScale)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius)
                .stroke(Color.white.opacity(0.12), lineWidth: 1 * zoomScale)
                .allowsHitTesting(false)
        )
        .onAppear {
            let willSleep = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { _ in
                fanSummaryTimer?.invalidate()
                fanSummaryTimer = nil
            }
            let didWake = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { _ in
                guard prefs.preferences.enableFanControl else { return }
                updateFanSummary()
                fanSummaryTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                    updateFanSummary()
                }
            }
            sleepObserverTokens = [willSleep, didWake]
        }
        .onDisappear {
            fanSummaryTimer?.invalidate()
            fanSummaryTimer = nil
            for token in sleepObserverTokens {
                NSWorkspace.shared.notificationCenter.removeObserver(token)
            }
            sleepObserverTokens.removeAll()
        }
    }
    
    // MARK: - Fan Summary Card

    private var fanSummaryCard: some View {
        HStack(spacing: 10 * zoomScale) {
            Image(systemName: "fanblades")
                .font(.system(size: 16 * zoomScale))
                .foregroundStyle(.cyan)
                .frame(width: 32 * zoomScale, height: 32 * zoomScale)
                .background(Color.cyan.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "thermometer")
                        .font(.system(size: 9 * zoomScale))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(prefs.preferences.fanControlTemperatureUnit.formatted(fanSummaryTemp))
                        .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 4) {
                    Image(systemName: "fanblades")
                        .font(.system(size: 9 * zoomScale))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("\(Int(fanSummaryRPM)) RPM")
                        .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
            }

            Spacer()

            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                onOpenFanControl()
            }) {
                Text("Open")
                    .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)
                    .padding(.horizontal, 10 * zoomScale)
                    .padding(.vertical, 4 * zoomScale)
                    .background(Color.cyan.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4 * zoomScale)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.white.opacity(0.02))
        .overlay(
            RoundedRectangle(cornerRadius: 8 * zoomScale)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .allowsHitTesting(false)
        )
        .onAppear {
            updateFanSummary()
            fanSummaryTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                updateFanSummary()
            }
        }
        .onDisappear {
            fanSummaryTimer?.invalidate()
            fanSummaryTimer = nil
        }
    }

    private func updateFanSummary() {
        let sensors = SMCService.shared.readTemperatures()
        let fans = SMCService.shared.readFans()
        fanSummaryTemp = sensors.map(\.value).max() ?? 0
        fanSummaryRPM = fans.isEmpty ? 0 : fans.map(\.actualRPM).reduce(0, +) / Double(fans.count)
    }

    // MARK: - Title Bar with Close Button

    private var titleBar: some View {
        HStack(spacing: 0 * zoomScale) {
            // Close button
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                onClose()
            }) {
                Image(systemName: "minus")
                    .font(.system(size: 12 * zoomScale, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                    .background(Color(white: 0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 12 * zoomScale)
            
            Spacer()
            
            VStack(spacing: 0 * zoomScale) {
                Text("ClassGod")
                    .font(.system(size: 13 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.6.0")")
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
            
            Spacer()
            
            // Spacer to balance close button width
            Color.clear.frame(width: 36 * zoomScale, height: 24 * zoomScale)
        }
        .padding(.vertical, 8 * zoomScale)
        .background(Color(white: 0.03))
    }
}

// MARK: - Feature Button

struct FeatureButton: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
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
            HStack(spacing: 12 * zoomScale) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8 * zoomScale)
                        .fill(isHovered && isEnabled ? Color(white: 0.12) : Color(white: 0.08))
                        .frame(width: 44 * zoomScale, height: 44 * zoomScale)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20 * zoomScale, weight: .medium))
                        .foregroundStyle(isEnabled ? .white : .white.opacity(0.3))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(isEnabled ? .white : .white.opacity(0.3))
                    
                    Text(description)
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10 * zoomScale, weight: .medium))
                    .foregroundStyle(isEnabled ? .white.opacity(0.4) : .white.opacity(0.1))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8 * zoomScale)
                    .fill(isHovered && isEnabled ? Color(white: 0.06) : Color(white: 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8 * zoomScale)
                    .stroke(isHovered && isEnabled ? Color.white.opacity(0.25) : Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
                    .allowsHitTesting(false)
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
    MenuBarView(onClose: {}, onOpenDestinTab: {}, onOpenSuperSwitch: {}, onOpenBrowserBypasser: {}, onOpenAssessPrepHack: {}, onOpenSettings: {}, onOpenWallpaper: {}, onOpenHackerDesktop: {}, onOpenFanControl: {}, onOpenErrorHub: {})
}
