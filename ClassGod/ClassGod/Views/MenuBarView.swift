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
    @State private var isActive = false

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
    var onOpenActivityMonitor: () -> Void
    var onOpenPermissionCenter: () -> Void
    
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
                            description: "menu.destintab.description",
                            action: onOpenDestinTab
                        )
                        
                        FeatureButton(
                            icon: "arrow.left.arrow.right",
                            title: "SuperSwitch",
                            description: "menu.superswitch.description",
                            action: onOpenSuperSwitch
                        )
                        
                        FeatureButton(
                            icon: "lock.open.fill",
                            title: "BrowserBypasser",
                            description: "menu.browser_bypasser.description",
                            action: onOpenBrowserBypasser
                        )
                        
                        FeatureButton(
                            icon: "bolt.shield.fill",
                            title: "AssessPrepHack",
                            description: "menu.assess_prep.description",
                            action: onOpenAssessPrepHack
                        )
                        
                        FeatureButton(
                            icon: "photo.on.rectangle.angled",
                            title: "Wallpaper Engine",
                            description: "menu.wallpaper.description",
                            action: onOpenWallpaper
                        )
                        
                        FeatureButton(
                            icon: "square.grid.2x2",
                            title: "HackerDesktop",
                            description: "menu.hacker_desktop.description",
                            action: onOpenHackerDesktop
                        )
                        
                        FeatureButton(
                            icon: "exclamationmark.triangle.fill",
                            title: "Error Encyclopedia",
                            description: "menu.error_hub.description",
                            action: onOpenErrorHub
                        )
                        
                        FeatureButton(
                            icon: "fanblades",
                            title: "Fan Control",
                            description: "menu.fan_control.description",
                            action: onOpenFanControl,
                            isEnabled: prefs.preferences.enableFanControl
                        )
                        
                        FeatureButton(
                            icon: "waveform.path.ecg.rectangle",
                            title: "Activity Monitor",
                            description: "menu.activity_monitor.description",
                            action: onOpenActivityMonitor
                        )
                        
                        FeatureButton(
                            icon: "checkmark.shield.fill",
                            title: "Permission Center",
                            description: "menu.permission_center.description",
                            action: onOpenPermissionCenter
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
                            HapticManager.shared.generic()
                            onOpenSettings()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 11 * zoomScale))
                            Text("settings.title")
                                .font(.system(size: 11 * zoomScale, design: .monospaced))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.5))
                        
                        Spacer()
                        
                        Button(action: {
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.warning()
                            NSApplication.shared.terminate(nil)
                        }) {
                            Text("menu.quit")
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
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius * zoomScale)
                .stroke(Color.white.opacity(0.12), lineWidth: 1 * zoomScale)
                .allowsHitTesting(false)
        )
        .onReceive(NotificationCenter.default.publisher(for: .mainWindowDidShow)) { _ in
            activate()
        }
        .onReceive(NotificationCenter.default.publisher(for: .mainWindowWillHide)) { _ in
            deactivate()
        }
        .onChange(of: prefs.preferences.enableFanControl) { _, enabled in
            guard isActive else { return }
            if enabled {
                startFanSummaryTimer()
            } else {
                stopFanSummaryTimer()
            }
        }
        .onDisappear {
            deactivate()
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

            VStack(alignment: .leading, spacing: 2 * zoomScale) {
                HStack(spacing: 4 * zoomScale) {
                    Image(systemName: "thermometer")
                        .font(.system(size: 9 * zoomScale))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(prefs.preferences.fanControlTemperatureUnit.formatted(fanSummaryTemp))
                        .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 4 * zoomScale) {
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
                HapticManager.shared.generic()
                onOpenFanControl()
            }) {
                Text("button.open")
                    .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)
                    .padding(.horizontal, 10 * zoomScale)
                    .padding(.vertical, 4 * zoomScale)
                    .background(Color.cyan.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4 * zoomScale)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1 * zoomScale)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.white.opacity(0.02))
        .overlay(
            RoundedRectangle(cornerRadius: 8 * zoomScale)
                .stroke(Color.white.opacity(0.08), lineWidth: 1 * zoomScale)
                .allowsHitTesting(false)
        )
    }

    private func activate() {
        guard !isActive else { return }
        isActive = true

        let willSleep = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { _ in
            stopFanSummaryTimer()
        }
        let didWake = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            guard prefs.preferences.enableFanControl else { return }
            startFanSummaryTimer()
        }
        sleepObserverTokens = [willSleep, didWake]

        if prefs.preferences.enableFanControl {
            startFanSummaryTimer()
        }
    }

    private func deactivate() {
        guard isActive else { return }
        isActive = false
        stopFanSummaryTimer()
        for token in sleepObserverTokens {
            NSWorkspace.shared.notificationCenter.removeObserver(token)
        }
        sleepObserverTokens.removeAll()
    }

    private func startFanSummaryTimer() {
        updateFanSummary()
        fanSummaryTimer?.invalidate()
        fanSummaryTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            updateFanSummary()
        }
    }

    private func stopFanSummaryTimer() {
        fanSummaryTimer?.invalidate()
        fanSummaryTimer = nil
    }

    private func updateFanSummary() {
        Task.detached(priority: .userInitiated) {
            let all = SMCService.shared.readAll()
            // Use only non-estimated sensors for menu-bar highest temp to avoid
            // PMU/thermal-state placeholders inflating the display.
            let realSensors = all.sensors.filter { !$0.isEstimated }
            let temp = realSensors.map(\.value).max() ?? 0
            let rpm = all.fans.isEmpty ? 0 : all.fans.map(\.actualRPM).reduce(0, +) / Double(all.fans.count)
            await MainActor.run {
                self.fanSummaryTemp = temp
                self.fanSummaryRPM = rpm
            }
        }
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
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let action: () -> Void
    var isEnabled: Bool = true
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if isEnabled {
                SoundEffectManager.shared.playButtonClick()
                HapticManager.shared.generic()
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
            let press = {
                isPressed = true
            }
            if Anim.enabled {
                withAnimation(.easeOut(duration: Anim.duration), press)
            } else {
                press()
            }
        } onRelease: {
            let release = {
                isPressed = false
            }
            if Anim.enabled {
                withAnimation(.easeOut(duration: Anim.duration), release)
            } else {
                release()
            }
        }
    }
}

#Preview {
    MenuBarView(onClose: {}, onOpenDestinTab: {}, onOpenSuperSwitch: {}, onOpenBrowserBypasser: {}, onOpenAssessPrepHack: {}, onOpenSettings: {}, onOpenWallpaper: {}, onOpenHackerDesktop: {}, onOpenFanControl: {}, onOpenErrorHub: {}, onOpenActivityMonitor: {}, onOpenPermissionCenter: {})
}
