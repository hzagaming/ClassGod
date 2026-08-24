//
//  MenuBarView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

enum MainPanelFeature: String, CaseIterable, Hashable {
    case preflight
    case destinTab
    case clipo
    case notes
    case todo
    case superSwitch
    case ghostProtocol
    case browserBypasser
    case fakeLock
    case assessPrepHack
    case wallpaper
    case widgets
    case errorHub
    case fanControl
    case activityMonitor
    case permissionCenter

    var icon: String {
        switch self {
        case .preflight: "waveform.path.ecg.rectangle.fill"
        case .destinTab: "link"
        case .clipo: "clipboard.fill"
        case .notes: "note.text"
        case .todo: "checkmark.circle.fill"
        case .superSwitch: "arrow.left.arrow.right"
        case .ghostProtocol: "eye.slash.circle.fill"
        case .browserBypasser: "lock.open.fill"
        case .fakeLock: "lock.rectangle.stack.fill"
        case .assessPrepHack: "bolt.shield.fill"
        case .wallpaper: "photo.on.rectangle.angled"
        case .widgets: "square.grid.2x2"
        case .errorHub: "exclamationmark.triangle.fill"
        case .fanControl: "fanblades"
        case .activityMonitor: "waveform.path.ecg.rectangle"
        case .permissionCenter: "checkmark.shield.fill"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .preflight: "preflight.title"
        case .destinTab: "DestinTab"
        case .clipo: "Clipo"
        case .notes: "notes.title"
        case .todo: "todo.title"
        case .superSwitch: "SuperSwitch"
        case .ghostProtocol: "ghost.title"
        case .browserBypasser: "BrowserBypasser"
        case .fakeLock: "fake_lock.title"
        case .assessPrepHack: "AssessPrepHack"
        case .wallpaper: "wallpaper.title"
        case .widgets: "hackerdesktop.config_title"
        case .errorHub: "error.hub_title"
        case .fanControl: "fan.title"
        case .activityMonitor: "activity.title"
        case .permissionCenter: "permission.center.title"
        }
    }

    var description: LocalizedStringKey {
        switch self {
        case .preflight: "menu.preflight.description"
        case .destinTab: "menu.destintab.description"
        case .clipo: "menu.clipo.description"
        case .notes: "menu.notes.description"
        case .todo: "menu.todo.description"
        case .superSwitch: "menu.superswitch.description"
        case .ghostProtocol: "menu.ghost_protocol.description"
        case .browserBypasser: "menu.browser_bypasser.description"
        case .fakeLock: "menu.fake_lock.description"
        case .assessPrepHack: "menu.assess_prep.description"
        case .wallpaper: "menu.wallpaper.description"
        case .widgets: "menu.hacker_desktop.description"
        case .errorHub: "menu.error_hub.description"
        case .fanControl: "menu.fan_control.description"
        case .activityMonitor: "menu.activity_monitor.description"
        case .permissionCenter: "menu.permission_center.description"
        }
    }
}

enum MainPanelMode: String, CaseIterable, Identifiable {
    case goodStudent
    case badStudent
    case other

    var id: Self { self }

    var features: [MainPanelFeature] {
        switch self {
        case .goodStudent:
            [.clipo, .notes, .todo, .wallpaper, .widgets]
        case .badStudent:
            [.preflight, .destinTab, .superSwitch, .ghostProtocol, .browserBypasser, .fakeLock, .assessPrepHack]
        case .other:
            [.errorHub, .activityMonitor, .fanControl, .permissionCenter]
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .goodStudent: "menu.mode.good_student"
        case .badStudent: "menu.mode.bad_student"
        case .other: "menu.mode.other"
        }
    }

    var icon: String {
        switch self {
        case .goodStudent: "graduationcap.fill"
        case .badStudent: "flame.fill"
        case .other: "desktopcomputer"
        }
    }
}

enum MainPanelLayoutPolicy {
    static func columnCount(availableWidth: CGFloat, zoomScale: CGFloat) -> Int {
        let scale = max(0.5, zoomScale)
        let minimumCardWidth = 280 * scale
        let spacing = 10 * scale
        let count = Int((max(0, availableWidth) + spacing) / (minimumCardWidth + spacing))
        return min(3, max(1, count))
    }
}

private struct MainPanelPalette {
    let background: Color
    let backgroundHighlight: Color
    let header: Color
    let surface: Color
    let surfaceHover: Color
    let accent: Color
    let primaryText: Color
    let secondaryText: Color
    let border: Color
}

private extension MainPanelMode {
    var palette: MainPanelPalette {
        switch self {
        case .goodStudent:
            MainPanelPalette(
                background: Color(red: 0.025, green: 0.075, blue: 0.12),
                backgroundHighlight: Color(red: 0.055, green: 0.16, blue: 0.24),
                header: Color(red: 0.025, green: 0.10, blue: 0.16),
                surface: Color(red: 0.055, green: 0.15, blue: 0.22),
                surfaceHover: Color(red: 0.075, green: 0.22, blue: 0.32),
                accent: Color(red: 0.35, green: 0.78, blue: 1),
                primaryText: .white,
                secondaryText: Color.white.opacity(0.62),
                border: Color(red: 0.35, green: 0.78, blue: 1).opacity(0.28)
            )
        case .badStudent:
            MainPanelPalette(
                background: Color(red: 0.12, green: 0.015, blue: 0.045),
                backgroundHighlight: Color(red: 0.26, green: 0.025, blue: 0.085),
                header: Color(red: 0.16, green: 0.018, blue: 0.055),
                surface: Color(red: 0.22, green: 0.025, blue: 0.075),
                surfaceHover: Color(red: 0.34, green: 0.035, blue: 0.11),
                accent: Color(red: 1, green: 0.28, blue: 0.48),
                primaryText: Color(red: 1, green: 0.92, blue: 0.95),
                secondaryText: Color(red: 1, green: 0.68, blue: 0.78),
                border: Color(red: 1, green: 0.28, blue: 0.48).opacity(0.32)
            )
        case .other:
            MainPanelPalette(
                background: Color(white: 0.015),
                backgroundHighlight: Color(white: 0.10),
                header: Color(white: 0.035),
                surface: Color(white: 0.075),
                surfaceHover: Color(white: 0.14),
                accent: .white,
                primaryText: .white,
                secondaryText: Color.white.opacity(0.58),
                border: Color.white.opacity(0.22)
            )
        }
    }
}

struct MenuBarView: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    @AppStorage("com.hanazar.classgod.mainPanelMode") private var selectedMode: MainPanelMode = .goodStudent
    @State private var fanSummaryTemp: Double = 0
    @State private var fanSummaryRPM: Double = 0
    @State private var hasFanSummaryTemp = false
    @State private var hasFanSummaryRPM = false
    @State private var fanSummaryTimer: Timer?
    @State private var sleepObserverTokens: [any NSObjectProtocol] = []
    @State private var isActive = false
    @State private var refreshGate = FanRefreshGate()

    var onClose: () -> Void
    var onOpenPreflight: () -> Void
    var onOpenDestinTab: () -> Void
    var onOpenSuperSwitch: () -> Void
    var onOpenGhostProtocol: () -> Void
    var onOpenBrowserBypasser: () -> Void
    var onOpenAssessPrepHack: () -> Void
    var onOpenSettings: () -> Void
    var onOpenWallpaper: () -> Void
    var onOpenHackerDesktop: () -> Void
    var onOpenClipo: () -> Void
    var onOpenNotes: () -> Void
    var onOpenTodo: () -> Void
    var onOpenFanControl: () -> Void
    var onOpenErrorHub: () -> Void
    var onOpenActivityMonitor: () -> Void
    var onOpenPermissionCenter: () -> Void
    var onOpenFakeLock: () -> Void
    
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    private var palette: MainPanelPalette { selectedMode.palette }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [palette.backgroundHighlight, palette.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0 * zoomScale) {
                titleBar
                modeSelector
                featureGrid
                footer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius * zoomScale)
                .stroke(palette.border, lineWidth: 1 * zoomScale)
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
            if enabled && selectedMode == .other {
                startFanSummaryTimer()
            } else {
                stopFanSummaryTimer()
            }
        }
        .onChange(of: selectedMode) { _, mode in
            guard isActive else { return }
            if mode == .other && prefs.preferences.enableFanControl {
                startFanSummaryTimer()
            } else {
                stopFanSummaryTimer()
            }
        }
        .onChange(of: prefs.preferences.fanControlUpdateInterval) { _, _ in
            guard isActive, selectedMode == .other, prefs.preferences.enableFanControl else { return }
            startFanSummaryTimer()
        }
        .onDisappear {
            deactivate()
        }
    }

    private var modeSelector: some View {
        HStack(spacing: 6 * zoomScale) {
            ForEach(MainPanelMode.allCases) { mode in
                let modePalette = mode.palette
                let isSelected = selectedMode == mode

                Button {
                    guard !isSelected else { return }
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                    Anim.with { selectedMode = mode }
                } label: {
                    HStack(spacing: 5 * zoomScale) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 10 * zoomScale, weight: .semibold))
                            .foregroundStyle(isSelected ? modePalette.accent : palette.secondaryText)
                        Text(mode.title)
                            .font(.system(size: 10 * zoomScale, weight: .semibold, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7 * zoomScale)
                    .foregroundStyle(isSelected ? palette.primaryText : palette.secondaryText)
                    .background(
                        RoundedRectangle(cornerRadius: 7 * zoomScale)
                            .fill(isSelected ? modePalette.accent.opacity(0.18) : palette.surface.opacity(0.45))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7 * zoomScale)
                            .stroke(isSelected ? modePalette.accent.opacity(0.55) : palette.border.opacity(0.45), lineWidth: 1 * zoomScale)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.bottom, 9 * zoomScale)
        .background(palette.header)
    }

    private var featureGrid: some View {
        GeometryReader { geometry in
            let contentWidth = max(0, geometry.size.width - 32 * zoomScale)
            let columnCount = MainPanelLayoutPolicy.columnCount(
                availableWidth: contentWidth,
                zoomScale: zoomScale
            )
            let columns = Array(
                repeating: GridItem(.flexible(minimum: 220 * zoomScale), spacing: 10 * zoomScale),
                count: columnCount
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10 * zoomScale) {
                    if selectedMode == .other && prefs.preferences.enableFanControl {
                        fanSummaryCard
                    }

                    LazyVGrid(columns: columns, alignment: .leading, spacing: 10 * zoomScale) {
                        ForEach(selectedMode.features, id: \.self) { feature in
                            featureButton(for: feature)
                        }
                    }
                }
                .padding(16 * zoomScale)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider().background(palette.border)

            HStack(spacing: 12 * zoomScale) {
                Button(action: {
                    HapticManager.shared.generic()
                    onOpenSettings()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11 * zoomScale))
                    Text("settings.title")
                        .font(.system(size: 11 * zoomScale, design: .monospaced))
                }
                .buttonStyle(.plain)
                .foregroundStyle(palette.secondaryText)

                Spacer()

                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.warning()
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("menu.quit")
                        .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(palette.accent.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16 * zoomScale)
            .padding(.vertical, 10 * zoomScale)
        }
        .background(palette.header)
    }

    private func featureButton(for feature: MainPanelFeature) -> some View {
        FeatureButton(
            icon: feature.icon,
            title: feature.title,
            description: feature.description,
            mode: selectedMode,
            action: action(for: feature),
            isEnabled: feature != .fanControl || prefs.preferences.enableFanControl
        )
    }

    private func action(for feature: MainPanelFeature) -> () -> Void {
        switch feature {
        case .preflight: onOpenPreflight
        case .destinTab: onOpenDestinTab
        case .clipo: onOpenClipo
        case .notes: onOpenNotes
        case .todo: onOpenTodo
        case .superSwitch: onOpenSuperSwitch
        case .ghostProtocol: onOpenGhostProtocol
        case .browserBypasser: onOpenBrowserBypasser
        case .fakeLock: onOpenFakeLock
        case .assessPrepHack: onOpenAssessPrepHack
        case .wallpaper: onOpenWallpaper
        case .widgets: onOpenHackerDesktop
        case .errorHub: onOpenErrorHub
        case .fanControl: onOpenFanControl
        case .activityMonitor: onOpenActivityMonitor
        case .permissionCenter: onOpenPermissionCenter
        }
    }
    
    // MARK: - Fan Summary Card

    private var fanSummaryCard: some View {
        HStack(spacing: 10 * zoomScale) {
            Image(systemName: "fanblades")
                .font(.system(size: 16 * zoomScale))
                .foregroundStyle(palette.accent)
                .frame(width: 32 * zoomScale, height: 32 * zoomScale)
                .background(palette.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))

            VStack(alignment: .leading, spacing: 2 * zoomScale) {
                HStack(spacing: 4 * zoomScale) {
                    Image(systemName: "thermometer")
                        .font(.system(size: 9 * zoomScale))
                        .foregroundStyle(palette.secondaryText)
                    Text(hasFanSummaryTemp ? prefs.preferences.fanControlTemperatureUnit.formatted(fanSummaryTemp) : "--")
                        .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(palette.primaryText)
                }

                HStack(spacing: 4 * zoomScale) {
                    Image(systemName: "fanblades")
                        .font(.system(size: 9 * zoomScale))
                        .foregroundStyle(palette.secondaryText)
                    Text(hasFanSummaryRPM ? "\(Int(fanSummaryRPM)) RPM" : "-- RPM")
                        .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(palette.primaryText)
                }
            }

            Spacer()

            Button(action: openFanControl) {
                Text("button.open")
                    .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.accent)
                    .padding(.horizontal, 10 * zoomScale)
                    .padding(.vertical, 4 * zoomScale)
                    .background(palette.accent.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4 * zoomScale)
                            .stroke(palette.accent.opacity(0.35), lineWidth: 1 * zoomScale)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("fan.title"))
        }
        .padding(16 * zoomScale)
        .background(palette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8 * zoomScale)
                .stroke(palette.border, lineWidth: 1 * zoomScale)
                .allowsHitTesting(false)
        )
    }

    private func openFanControl() {
        HapticManager.shared.generic()
        onOpenFanControl()
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
            guard selectedMode == .other, prefs.preferences.enableFanControl else { return }
            startFanSummaryTimer()
        }
        sleepObserverTokens = [willSleep, didWake]

        if selectedMode == .other && prefs.preferences.enableFanControl {
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
        let interval = FanRefreshPolicy.normalized(prefs.preferences.fanControlUpdateInterval)
        fanSummaryTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            updateFanSummary()
        }
    }

    private func stopFanSummaryTimer() {
        fanSummaryTimer?.invalidate()
        fanSummaryTimer = nil
    }

    private func updateFanSummary() {
        guard refreshGate.begin() else { return }
        Task.detached(priority: .userInitiated) {
            let all = SMCService.shared.readAll()
            // Use only non-estimated sensors for menu-bar highest temp to avoid
            // PMU/thermal-state placeholders inflating the display.
            let realSensors = all.sensors.filter { !$0.isEstimated }
            let temp = realSensors.map(\.value).max() ?? 0
            let liveRPM = FanControlRouting.averageLiveRPM(in: all.fans)
            await MainActor.run {
                defer { self.refreshGate.end() }
                guard self.isActive else { return }
                self.fanSummaryTemp = temp
                self.fanSummaryRPM = liveRPM ?? 0
                self.hasFanSummaryTemp = !realSensors.isEmpty
                self.hasFanSummaryRPM = liveRPM != nil
            }
        }
    }

    // MARK: - Title Bar with Close Button

    private var titleBar: some View {
        HStack(spacing: 0 * zoomScale) {
            Button(action: close) {
                Image(systemName: "minus")
                    .font(.system(size: 12 * zoomScale, weight: .bold))
                    .foregroundStyle(palette.secondaryText)
                    .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                    .background(palette.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("button.close"))
            .padding(.leading, 12 * zoomScale)
            
            Spacer()
            
            VStack(spacing: 0 * zoomScale) {
                Text("ClassGod")
                    .font(.system(size: 13 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.primaryText)
                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")")
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(palette.secondaryText.opacity(0.58))
            }
            
            Spacer()
            
            Color.clear.frame(width: 36 * zoomScale, height: 24 * zoomScale)
        }
        .padding(.vertical, 8 * zoomScale)
        .background(palette.header)
    }

    private func close() {
        onClose()
    }
}

// MARK: - Feature Button

struct FeatureButton: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let mode: MainPanelMode
    let action: () -> Void
    var isEnabled: Bool = true
    
    @State private var isHovered = false
    @State private var isPressed = false
    private var palette: MainPanelPalette { mode.palette }
    
    var body: some View {
        Button(action: performAction) {
            HStack(spacing: 12 * zoomScale) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8 * zoomScale)
                        .fill(palette.accent.opacity(isHovered && isEnabled ? 0.2 : 0.1))
                        .frame(width: 44 * zoomScale, height: 44 * zoomScale)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20 * zoomScale, weight: .medium))
                        .foregroundStyle(isEnabled ? palette.accent : palette.secondaryText.opacity(0.35))
                }
                
                VStack(alignment: .leading, spacing: 2 * zoomScale) {
                    Text(title)
                        .font(.system(size: 13 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(isEnabled ? palette.primaryText : palette.secondaryText.opacity(0.4))
                    
                    Text(description)
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(palette.secondaryText.opacity(isEnabled ? 1 : 0.42))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10 * zoomScale, weight: .medium))
                    .foregroundStyle(isEnabled ? palette.accent.opacity(0.55) : palette.secondaryText.opacity(0.18))
            }
            .frame(maxWidth: .infinity, minHeight: 44 * zoomScale, alignment: .leading)
            .padding(16 * zoomScale)
            .background(
                RoundedRectangle(cornerRadius: 8 * zoomScale)
                    .fill(isHovered && isEnabled ? palette.surfaceHover : palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8 * zoomScale)
                    .stroke(isHovered && isEnabled ? palette.accent.opacity(0.55) : palette.border, lineWidth: 1 * zoomScale)
                    .allowsHitTesting(false)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(title)
        .accessibilityHint(description)
        .onHover { hovering in
            isHovered = hovering && isEnabled
        }
        .pressEvents {
            guard isEnabled else { return }
            let press = {
                isPressed = true
            }
            if Anim.enabled {
                withAnimation(.easeOut(duration: Anim.duration), press)
            } else {
                press()
            }
        } onRelease: {
            guard isEnabled else { return }
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

    private func performAction() {
        guard isEnabled else { return }
        HapticManager.shared.generic()
        action()
    }
}

#Preview {
    MenuBarView(onClose: {}, onOpenPreflight: {}, onOpenDestinTab: {}, onOpenSuperSwitch: {}, onOpenGhostProtocol: {}, onOpenBrowserBypasser: {}, onOpenAssessPrepHack: {}, onOpenSettings: {}, onOpenWallpaper: {}, onOpenHackerDesktop: {}, onOpenClipo: {}, onOpenNotes: {}, onOpenTodo: {}, onOpenFanControl: {}, onOpenErrorHub: {}, onOpenActivityMonitor: {}, onOpenPermissionCenter: {}, onOpenFakeLock: {})
}
