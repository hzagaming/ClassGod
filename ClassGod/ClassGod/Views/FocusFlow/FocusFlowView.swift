import AppKit
import SwiftUI

private extension FocusFlowPhase {
    var title: LocalizedStringKey {
        switch self {
        case .focus: "focus.phase.focus"
        case .shortBreak: "focus.phase.short_break"
        case .longBreak: "focus.phase.long_break"
        }
    }

    var hint: LocalizedStringKey {
        switch self {
        case .focus: "focus.hint.focus"
        case .shortBreak: "focus.hint.short_break"
        case .longBreak: "focus.hint.long_break"
        }
    }

    var icon: String {
        switch self {
        case .focus: "scope"
        case .shortBreak: "cup.and.saucer.fill"
        case .longBreak: "sparkles"
        }
    }
}

private extension FocusFlowRunState {
    var title: LocalizedStringKey {
        switch self {
        case .idle: "focus.state.idle"
        case .running: "focus.state.running"
        case .paused: "focus.state.paused"
        }
    }
}

private extension FocusFlowPreset {
    var title: LocalizedStringKey {
        switch self {
        case .quick: "focus.preset.quick"
        case .classic: "focus.preset.classic"
        case .deep: "focus.preset.deep"
        }
    }
}

struct FocusFlowView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var service = FocusFlowService.shared
    @ObservedObject private var prefs = PreferencesManager.shared

    let onClose: () -> Void

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    private var accent: Color { prefs.preferences.themeAccent.color }
    private var phaseColor: Color {
        switch service.phase {
        case .focus: accent
        case .shortBreak: Color(red: 0.3, green: 0.9, blue: 0.72)
        case .longBreak: Color(red: 0.48, green: 0.72, blue: 1)
        }
    }
    private var motionAnimation: Animation? {
        guard !reduceMotion, Anim.enabled else { return nil }
        return .easeOut(duration: Anim.duration)
    }
    private var canReset: Bool {
        service.runState != .idle || service.phase != .focus
            || service.remainingSeconds != service.phaseDurationSeconds
    }
    private var cycleStatusText: String {
        guard let remaining = service.sessionsUntilLongBreak else {
            return String(localized: "focus.long_break_active")
        }
        return String(format: String(localized: "focus.long_break_in"), remaining)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.white.opacity(0.1))
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18 * zoomScale) {
                    sessionWorkspace
                    presetPicker
                    statistics
                    persistenceHint
                }
                .padding(22 * zoomScale)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.11, blue: 0.16), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .preferredColorScheme(.dark)
        .tint(phaseColor)
        .animation(motionAnimation, value: service.phase)
        .overlay(
            RoundedRectangle(cornerRadius: 12 * zoomScale)
                .stroke(phaseColor.opacity(0.22), lineWidth: zoomScale)
                .allowsHitTesting(false)
        )
        .onAppear { service.refreshDailyStats() }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            service.refreshDailyStats()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            service.refreshDailyStats()
        }
        .onExitCommand(perform: onClose)
    }

    private var header: some View {
        HStack(spacing: 10 * zoomScale) {
            Button(action: onClose) {
                Image(systemName: "minus")
                    .font(.system(size: 11 * zoomScale, weight: .bold))
                    .frame(width: 26 * zoomScale, height: 26 * zoomScale)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.68))
            .accessibilityLabel(Text("button.close"))

            Image(systemName: "timer.circle.fill")
                .font(.system(size: 16 * zoomScale, weight: .semibold))
                .foregroundStyle(phaseColor)

            VStack(alignment: .leading, spacing: 1 * zoomScale) {
                Text("focus.title")
                    .font(.system(size: 14 * zoomScale, weight: .bold, design: .rounded))
                Text("focus.subtitle")
                    .font(.system(size: 8 * zoomScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.38))
            }

            Spacer()

            HStack(spacing: 6 * zoomScale) {
                Circle()
                    .fill(service.runState == .running ? phaseColor : Color.white.opacity(0.25))
                    .frame(width: 6 * zoomScale, height: 6 * zoomScale)
                Text(service.runState.title)
                    .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(service.runState == .running ? phaseColor : .white.opacity(0.55))
            .padding(.horizontal, 10 * zoomScale)
            .padding(.vertical, 5 * zoomScale)
            .background(Color.white.opacity(0.045))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16 * zoomScale)
        .padding(.vertical, 12 * zoomScale)
        .background(Color.black.opacity(0.42))
    }

    private var sessionWorkspace: some View {
        HStack(spacing: 28 * zoomScale) {
            timerRing
                .frame(maxWidth: .infinity)
            sessionControls
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18 * zoomScale)
        .background(
            RoundedRectangle(cornerRadius: 14 * zoomScale)
                .fill(Color.white.opacity(0.035))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14 * zoomScale)
                .stroke(phaseColor.opacity(0.2), lineWidth: zoomScale)
        )
    }

    private var timerRing: some View {
        let size = 220 * zoomScale
        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 12 * zoomScale)

            Circle()
                .trim(from: 0, to: service.progress)
                .stroke(
                    AngularGradient(
                        colors: [phaseColor.opacity(0.35), phaseColor, .white, phaseColor],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12 * zoomScale, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: phaseColor.opacity(0.4), radius: 10 * zoomScale)
                .animation(motionAnimation, value: service.remainingSeconds)

            VStack(spacing: 7 * zoomScale) {
                Image(systemName: service.phase.icon)
                    .font(.system(size: 18 * zoomScale, weight: .semibold))
                    .foregroundStyle(phaseColor)
                Text(service.clockText)
                    .font(.system(size: 40 * zoomScale, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(motionAnimation, value: service.remainingSeconds)
                Text(service.phase.title)
                    .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.52))
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(service.phase.title))
        .accessibilityValue(service.clockText)
    }

    private var sessionControls: some View {
        VStack(alignment: .leading, spacing: 14 * zoomScale) {
            VStack(alignment: .leading, spacing: 5 * zoomScale) {
                Text(service.phase.title)
                    .font(.system(size: 20 * zoomScale, weight: .bold, design: .rounded))
                    .foregroundStyle(phaseColor)
                Text(service.phase.hint)
                    .font(.system(size: 10 * zoomScale, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8 * zoomScale) {
                primaryActionButton
                compactActionButton(
                    title: "focus.skip",
                    icon: "forward.end.fill",
                    enabled: service.runState != .idle,
                    action: skip
                )
                compactActionButton(
                    title: "focus.reset",
                    icon: "arrow.counterclockwise",
                    enabled: canReset,
                    action: reset
                )
            }

            VStack(alignment: .leading, spacing: 8 * zoomScale) {
                HStack {
                    Text("focus.cycle")
                        .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                    Spacer()
                    Text(cycleStatusText)
                        .font(.system(size: 8 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.42))
                }

                HStack(spacing: 7 * zoomScale) {
                    ForEach(0..<FocusFlowPolicy.focusSessionsBeforeLongBreak, id: \.self) { index in
                        Capsule()
                            .fill(index < service.completedSessionsInCycle ? phaseColor : Color.white.opacity(0.08))
                            .frame(height: 5 * zoomScale)
                    }
                }
                .animation(motionAnimation, value: service.completedSessionsInCycle)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("focus.cycle"))
            .accessibilityValue(cycleStatusText)
        }
    }

    private var primaryActionButton: some View {
        let running = service.runState == .running
        let title: LocalizedStringKey = running
            ? "focus.pause"
            : service.runState == .paused ? "focus.resume" : "focus.start"
        return Button(action: toggleRunning) {
            Label(title, systemImage: running ? "pause.fill" : "play.fill")
                .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10 * zoomScale)
                .foregroundStyle(.black)
                .background(phaseColor)
                .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }

    private func compactActionButton(
        title: LocalizedStringKey,
        icon: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11 * zoomScale, weight: .semibold))
                .frame(width: 34 * zoomScale, height: 34 * zoomScale)
                .background(Color.white.opacity(enabled ? 0.07 : 0.025))
                .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .foregroundStyle(.white.opacity(enabled ? 0.7 : 0.2))
        .accessibilityLabel(Text(title))
    }

    private var presetPicker: some View {
        VStack(alignment: .leading, spacing: 10 * zoomScale) {
            Text("focus.rhythm")
                .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.38))

            HStack(spacing: 9 * zoomScale) {
                ForEach(FocusFlowPreset.allCases) { preset in
                    presetButton(preset)
                }
            }
        }
    }

    private func presetButton(_ preset: FocusFlowPreset) -> some View {
        let selected = service.preset == preset
        return Button {
            guard service.selectPreset(preset) else { return }
            SoundEffectManager.shared.play(.settingsChanged)
            HapticManager.shared.generic()
        } label: {
            VStack(spacing: 4 * zoomScale) {
                Text(preset.title)
                    .font(.system(size: 10 * zoomScale, weight: .bold, design: .rounded))
                Text(String(format: String(localized: "focus.preset_value"), preset.focusMinutes, preset.shortBreakMinutes))
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(selected ? phaseColor.opacity(0.8) : .white.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10 * zoomScale)
            .background(selected ? phaseColor.opacity(0.12) : Color.white.opacity(0.035))
            .overlay(
                RoundedRectangle(cornerRadius: 9 * zoomScale)
                    .stroke(selected ? phaseColor.opacity(0.55) : Color.white.opacity(0.07), lineWidth: zoomScale)
            )
            .clipShape(RoundedRectangle(cornerRadius: 9 * zoomScale))
        }
        .buttonStyle(.plain)
        .disabled(service.runState != .idle)
        .foregroundStyle(selected ? .white : .white.opacity(0.55))
        .accessibilityLabel(Text(preset.title))
        .accessibilityValue(
            String(
                format: String(localized: "focus.preset_value"),
                preset.focusMinutes,
                preset.shortBreakMinutes
            )
        )
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var statistics: some View {
        HStack(spacing: 10 * zoomScale) {
            statisticCard(
                icon: "checkmark.circle.fill",
                title: "focus.sessions_today",
                value: String(format: String(localized: "focus.sessions_value"), service.dailyStats.completedSessions)
            )
            statisticCard(
                icon: "hourglass.bottomhalf.filled",
                title: "focus.focused_today",
                value: String(
                    format: String(localized: "focus.minutes_value"),
                    service.dailyStats.focusedSeconds / 60
                )
            )
            statisticCard(
                icon: "waveform.path.ecg",
                title: "focus.current_rhythm",
                value: String(
                    format: String(localized: "focus.preset_value"),
                    service.preset.focusMinutes,
                    service.preset.shortBreakMinutes
                )
            )
        }
    }

    private func statisticCard(
        icon: String,
        title: LocalizedStringKey,
        value: String
    ) -> some View {
        HStack(spacing: 9 * zoomScale) {
            Image(systemName: icon)
                .font(.system(size: 13 * zoomScale, weight: .semibold))
                .foregroundStyle(phaseColor)
            VStack(alignment: .leading, spacing: 2 * zoomScale) {
                Text(title)
                    .font(.system(size: 7 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                Text(value)
                    .font(.system(size: 11 * zoomScale, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(11 * zoomScale)
        .background(Color.white.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 9 * zoomScale))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(value)
    }

    private var persistenceHint: some View {
        Label("focus.background_hint", systemImage: "eye.slash")
            .font(.system(size: 8 * zoomScale, design: .monospaced))
            .foregroundStyle(.white.opacity(0.3))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggleRunning() {
        let changed = service.runState == .running ? service.pause() : service.startOrResume()
        guard changed else { return }
        SoundEffectManager.shared.playButtonClick()
        HapticManager.shared.generic()
    }

    private func skip() {
        guard service.skipPhase() else { return }
        SoundEffectManager.shared.playButtonClick()
        HapticManager.shared.generic()
    }

    private func reset() {
        guard service.reset() else { return }
        SoundEffectManager.shared.playButtonClick()
        HapticManager.shared.generic()
    }
}

struct FocusFlowWindowView: View {
    let onClose: () -> Void

    var body: some View {
        FocusFlowView(onClose: onClose)
    }
}

#Preview {
    FocusFlowView(onClose: {})
        .frame(width: 760, height: 560)
}
