import AppKit
import SwiftUI

struct SwitchDrillView: View {
    @ObservedObject var service = SwitchDrillService.shared
    @ObservedObject private var catalog = ShortcutCatalogCoordinator.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    let onClose: () -> Void
    let onOpenPreflight: () -> Void

    private let accent = Color(red: 1, green: 0.28, blue: 0.48)
    private var zoom: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    private var phaseColor: Color {
        service.session.phase == .ready ? .green : accent
    }
    private var successfulResults: [SwitchDrillResult] {
        service.recentResults.filter { $0.outcome == .success }
    }

    var body: some View {
        ScrollViewReader { scroll in
            TrainingPanel(title: "drill.title", subtitle: "drill.subtitle", icon: "bolt.horizontal.circle.fill", accent: accent, onClose: onClose) {
                VStack(alignment: .leading, spacing: 20 * zoom) {
                    Text("drill.intro")
                        .font(.system(size: 23 * zoom, weight: .bold, design: .rounded))
                    Text("drill.real_switch_notice")
                        .foregroundStyle(.white.opacity(0.65))
                    targetPicker
                    signalCard.id("drill.signal")
                    controls
                    results
                    Text("drill.session_hint")
                        .font(.system(size: 10 * zoom))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .font(.system(size: 12 * zoom))
            }
            .onChange(of: service.session.isActive) { _, _ in
                scroll.scrollTo("drill.signal", anchor: .top)
            }
            .onAppear(perform: refreshTargets)
            .onReceive(catalog.$state) { state in refreshTargets(state: state) }
            .onReceive(NotificationCenter.default.publisher(for: .classGodTabsDidChange)) { _ in refreshTargets() }
            .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.willSleepNotification)) { _ in service.cancel() }
            .onDisappear { service.cancel() }
            .onChange(of: service.session.phase) { _, phase in
                if phase == .ready {
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                    NSAccessibility.post(element: NSApplication.shared, notification: .announcementRequested, userInfo: [
                        .announcement: String(localized: "drill.phase.ready"),
                        .priority: NSAccessibilityPriorityLevel.high.rawValue,
                    ])
                }
            }
        }
    }

    private var targetPicker: some View {
        VStack(alignment: .leading, spacing: 10 * zoom) {
            if let target = service.selectedTarget {
                Picker("drill.target", selection: Binding(
                    get: { service.selectedTarget?.id ?? target.id },
                    set: service.select
                )) {
                    ForEach(service.targets) { target in
                        Text(verbatim: "\(target.name) · \(target.shortcut)").tag(target.id)
                    }
                }
                .disabled(service.session.isActive)
                Label(LocalizedStringKey(target.kind == .browser ? "drill.browser_target" : "drill.app_target"), systemImage: target.kind == .browser ? "globe" : "app")
                    .font(.system(size: 10 * zoom)).foregroundStyle(.white.opacity(0.55))
            } else {
                Label("drill.no_targets", systemImage: "keyboard.badge.ellipsis")
                    .foregroundStyle(.orange)
                Button("drill.open_preflight", action: onOpenPreflight).buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16 * zoom)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12 * zoom))
    }

    private var signalCard: some View {
        VStack(spacing: 18 * zoom) {
            Image(systemName: phaseIcon)
                .font(.system(size: 48 * zoom, weight: .light))
                .foregroundStyle(phaseColor)
            Text(phaseTitle)
                .font(.system(size: 26 * zoom, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            if let target = service.selectedTarget {
                Text(verbatim: target.shortcut)
                    .font(.system(size: 30 * zoom, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 22 * zoom)
                    .padding(.vertical, 10 * zoom)
                    .background(phaseColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12 * zoom))
                    .accessibilityLabel(Text("drill.shortcut"))
                    .accessibilityValue(target.shortcut)
            }
            Text(phaseHint).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.65))
            if let result = service.session.result, let reaction = result.reactionSeconds {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 22 * zoom) { timingMetrics(reaction: reaction, switching: result.switchSeconds) }
                    VStack(spacing: 12 * zoom) { timingMetrics(reaction: reaction, switching: result.switchSeconds) }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220 * zoom)
        .padding(24 * zoom)
        .background(phaseColor.opacity(0.055), in: RoundedRectangle(cornerRadius: 18 * zoom))
        .overlay(RoundedRectangle(cornerRadius: 18 * zoom).stroke(phaseColor.opacity(0.4), lineWidth: zoom))
    }

    @ViewBuilder private func timingMetrics(reaction: TimeInterval, switching: TimeInterval?) -> some View {
        timingMetric("drill.reaction", seconds: reaction)
        if let switching { timingMetric("drill.switch_time", seconds: switching) }
    }

    private func timingMetric(_ label: LocalizedStringKey, seconds: TimeInterval) -> some View {
        VStack(spacing: 5 * zoom) {
            Text(verbatim: milliseconds(seconds))
                .font(.system(size: 22 * zoom, weight: .bold, design: .monospaced))
            Text(label).font(.system(size: 10 * zoom)).foregroundStyle(.white.opacity(0.6))
        }
        .accessibilityElement(children: .combine)
    }

    private var controls: some View {
        HStack {
            if service.session.isActive {
                Button("drill.cancel") { service.cancel() }
                    .buttonStyle(.bordered)
            } else {
                Button {
                    refreshTargets()
                    if service.start() {
                        SoundEffectManager.shared.playButtonClick()
                        HapticManager.shared.generic()
                    }
                } label: {
                    Label("drill.start", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(service.selectedTarget == nil)
                Button("drill.open_preflight", action: onOpenPreflight).buttonStyle(.bordered)
            }
            Spacer(minLength: 0)
        }
    }

    private var results: some View {
        VStack(alignment: .leading, spacing: 12 * zoom) {
            HStack {
                Text("drill.recent").fontWeight(.semibold)
                Spacer()
                if let best = successfulResults.compactMap(\.reactionSeconds).min() {
                    Text(String(format: String(localized: "drill.best_format"), milliseconds(best)))
                        .foregroundStyle(accent)
                }
            }
            if service.recentResults.isEmpty {
                Text("drill.no_results").foregroundStyle(.white.opacity(0.5))
            } else {
                ForEach(service.recentResults) { result in
                    HStack {
                        Image(systemName: result.outcome == .success ? "checkmark.circle.fill" : "exclamationmark.circle")
                            .foregroundStyle(result.outcome == .success ? .green : .orange)
                        Text(result.outcome.title)
                        Spacer()
                        if let seconds = result.reactionSeconds {
                            Text(verbatim: milliseconds(seconds)).monospacedDigit()
                        }
                    }
                    .padding(10 * zoom)
                    .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 8 * zoom))
                }
            }
        }
    }

    private var phaseTitle: LocalizedStringKey {
        switch service.session.phase {
        case .idle: "drill.phase.idle"
        case .waiting: "drill.phase.waiting"
        case .ready: "drill.phase.ready"
        case .switching: "drill.phase.switching"
        case .finished: service.session.result?.outcome.title ?? "drill.phase.idle"
        }
    }

    private var phaseHint: LocalizedStringKey {
        switch service.session.phase {
        case .idle: "drill.hint.idle"
        case .waiting: "drill.hint.waiting"
        case .ready: "drill.hint.ready"
        case .switching: "drill.hint.switching"
        case .finished: service.session.result?.outcome.hint ?? "drill.hint.idle"
        }
    }

    private var phaseIcon: String {
        switch service.session.phase {
        case .idle: "scope"
        case .waiting: "hourglass"
        case .ready: "bolt.fill"
        case .switching: "arrow.up.forward.app"
        case .finished: service.session.result?.outcome == .success ? "checkmark.seal.fill" : "arrow.counterclockwise"
        }
    }

    private func milliseconds(_ value: TimeInterval) -> String {
        String(format: String(localized: "drill.milliseconds_format"), value * 1_000)
    }

    private func refreshTargets() { refreshTargets(state: catalog.state) }

    private func refreshTargets(state: ShortcutCatalogState) {
        let tabs = StorageManager.shared.loadTabs().map {
            SwitchDrillTarget(id: $0.id, name: $0.title, shortcut: $0.shortcutDisplayString, kind: .browser, destination: $0.browser.rawValue + ":" + $0.url)
        }
        let apps = StorageManager.shared.loadSwitchTargets().map {
            SwitchDrillTarget(id: $0.id, name: $0.name, shortcut: $0.shortcutDisplayString, kind: .application, destination: $0.bundleIdentifier)
        }
        service.updateTargets(SwitchDrillTarget.available(tabs + apps, registeredIDs: state.registeredIDs))
    }
}

private extension SwitchDrillOutcome {
    var title: LocalizedStringKey {
        switch self {
        case .success: "drill.result.success"
        case .tooSoon: "drill.result.too_soon"
        case .wrongTarget: "drill.result.wrong_target"
        case .timeout: "drill.result.timeout"
        case .switchFailed: "drill.result.failed"
        case .interrupted: "drill.result.interrupted"
        }
    }

    var hint: LocalizedStringKey {
        switch self {
        case .success: "drill.hint.success"
        case .tooSoon: "drill.hint.too_soon"
        case .wrongTarget: "drill.hint.wrong_target"
        case .timeout: "drill.hint.timeout"
        case .switchFailed: "drill.hint.failed"
        case .interrupted: "drill.hint.interrupted"
        }
    }
}
