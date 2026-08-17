import SwiftUI

struct PreflightView: View {
    @StateObject private var viewModel = PreflightViewModel()
    @ObservedObject private var prefs = PreferencesManager.shared

    var onClose: () -> Void
    var onOpenDestinTab: () -> Void
    var onOpenSuperSwitch: () -> Void
    var onOpenPermissionCenter: () -> Void

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    private var accentColor: Color { prefs.preferences.themeAccent.color }

    var body: some View {
        ZStack {
            Color(white: 0.018).ignoresSafeArea().allowsHitTesting(false)

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14 * zoomScale) {
                        readinessSummary
                        checkGrid
                        repairActions
                    }
                    .padding(16 * zoomScale)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius * zoomScale)
                .stroke(Color.white.opacity(0.12), lineWidth: 1 * zoomScale)
                .allowsHitTesting(false)
        )
    }

    private var header: some View {
        HStack(spacing: 10 * zoomScale) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10 * zoomScale, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                    .background(Color(white: 0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("button.close"))

            Image(systemName: "waveform.path.ecg.rectangle.fill")
                .font(.system(size: 16 * zoomScale))
                .foregroundStyle(accentColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1 * zoomScale) {
                Text("preflight.title")
                    .font(.system(size: 14 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("preflight.subtitle")
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.42))
            }

            Spacer()
            WindowZoomControlBar()

            Button(action: refresh) {
                Group {
                    if viewModel.isRefreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10 * zoomScale, weight: .bold))
                    }
                }
                .frame(width: 26 * zoomScale, height: 26 * zoomScale)
                .foregroundStyle(accentColor)
                .background(accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isRefreshing)
            .accessibilityLabel(Text("button.refresh"))
            .accessibilityHint(Text("preflight.refresh.hint"))
        }
        .padding(.horizontal, 14 * zoomScale)
        .padding(.vertical, 10 * zoomScale)
        .background(Color(white: 0.04))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1 * zoomScale)
                .allowsHitTesting(false)
        }
    }

    private var readinessSummary: some View {
        let status = viewModel.report.status
        let readyCount = PreflightCheckKind.allCases.count { viewModel.report[$0] == .ready }
        let readyCountText = String(
            format: String(localized: "preflight.summary.count"),
            readyCount,
            PreflightCheckKind.allCases.count
        )
        return HStack(spacing: 16 * zoomScale) {
            ZStack {
                Circle()
                    .stroke(status.color.opacity(0.16), lineWidth: 7 * zoomScale)
                Circle()
                    .trim(from: 0, to: CGFloat(readyCount) / CGFloat(PreflightCheckKind.allCases.count))
                    .stroke(status.color, style: StrokeStyle(lineWidth: 7 * zoomScale, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: status.summaryIcon)
                    .font(.system(size: 24 * zoomScale, weight: .bold))
                    .foregroundStyle(status.color)
            }
            .frame(width: 74 * zoomScale, height: 74 * zoomScale)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5 * zoomScale) {
                Text(status.headlineKey)
                    .font(.system(size: 18 * zoomScale, weight: .black, design: .monospaced))
                    .foregroundStyle(status.color)
                Text(status.summaryKey)
                    .font(.system(size: 10 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
                Text(String(
                    format: String(localized: "preflight.summary.count"),
                    readyCount,
                    PreflightCheckKind.allCases.count
                ))
                    .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.42))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3 * zoomScale) {
                Text("preflight.last_checked")
                    .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.32))
                Text(lastCheckedText)
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(18 * zoomScale)
        .background(status.color.opacity(0.055))
        .overlay(
            RoundedRectangle(cornerRadius: 10 * zoomScale)
                .stroke(status.color.opacity(0.28), lineWidth: 1 * zoomScale)
                .allowsHitTesting(false)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("preflight.summary.accessibility"))
        .accessibilityValue(
            status.accessibilityLabel
                + Text(verbatim: ". \(readyCountText)")
        )
    }

    private var checkGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 280 * zoomScale), spacing: 10 * zoomScale)],
            spacing: 10 * zoomScale
        ) {
            ForEach(PreflightCheckKind.allCases) { kind in
                checkCard(kind)
            }
        }
    }

    private func checkCard(_ kind: PreflightCheckKind) -> some View {
        let status = viewModel.report[kind]
        return HStack(alignment: .top, spacing: 11 * zoomScale) {
            Image(systemName: kind.iconName)
                .font(.system(size: 15 * zoomScale, weight: .semibold))
                .foregroundStyle(status.color)
                .frame(width: 32 * zoomScale, height: 32 * zoomScale)
                .background(status.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 7 * zoomScale))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4 * zoomScale) {
                HStack(spacing: 5 * zoomScale) {
                    Text(kind.titleKey)
                        .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Spacer(minLength: 4 * zoomScale)
                    Text(status.badgeKey)
                        .font(.system(size: 7 * zoomScale, weight: .black, design: .monospaced))
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 5 * zoomScale)
                        .padding(.vertical, 2 * zoomScale)
                        .background(status.color.opacity(0.1))
                        .clipShape(Capsule())
                }
                Text(detail(for: kind))
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 58 * zoomScale, alignment: .topLeading)
        .padding(12 * zoomScale)
        .background(Color.white.opacity(0.025))
        .overlay(
            RoundedRectangle(cornerRadius: 8 * zoomScale)
                .stroke(status.color.opacity(0.18), lineWidth: 1 * zoomScale)
                .allowsHitTesting(false)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(kind.accessibilityLabel)
        .accessibilityValue(
            status.accessibilityLabel + Text(verbatim: ". \(detail(for: kind))")
        )
    }

    private var repairActions: some View {
        VStack(alignment: .leading, spacing: 8 * zoomScale) {
            Text("preflight.repair.title")
                .font(.system(size: 9 * zoomScale, weight: .black, design: .monospaced))
                .foregroundStyle(.white.opacity(0.42))

            HStack(spacing: 8 * zoomScale) {
                repairButton(
                    title: "preflight.action.permissions",
                    icon: "lock.shield",
                    action: onOpenPermissionCenter
                )
                repairButton(
                    title: "preflight.action.destintab",
                    icon: "link",
                    action: onOpenDestinTab
                )
                repairButton(
                    title: "preflight.action.superswitch",
                    icon: "arrow.left.arrow.right",
                    action: onOpenSuperSwitch
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func repairButton(
        title: LocalizedStringKey,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticManager.shared.generic()
            action()
        } label: {
            HStack(spacing: 5 * zoomScale) {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(1)
            }
            .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
            .foregroundStyle(accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8 * zoomScale)
            .background(accentColor.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 6 * zoomScale)
                    .stroke(accentColor.opacity(0.22), lineWidth: 1 * zoomScale)
                    .allowsHitTesting(false)
            )
        }
        .buttonStyle(.plain)
    }

    private func refresh() {
        SoundEffectManager.shared.playButtonClick()
        HapticManager.shared.generic()
        viewModel.refresh()
    }

    private var lastCheckedText: String {
        guard let date = viewModel.lastCheckedAt else {
            return String(localized: "preflight.not_checked")
        }
        return date.formatted(date: .omitted, time: .shortened)
    }

    private func detail(for kind: PreflightCheckKind) -> String {
        let metrics = viewModel.report.metrics
        switch kind {
        case .accessibility:
            return String(localized: viewModel.report[kind] == .ready
                ? "preflight.check.accessibility.ready"
                : "preflight.check.accessibility.blocked")
        case .appleEvents:
            return String(localized: viewModel.report[kind] == .ready
                ? "preflight.check.apple_events.ready"
                : "preflight.check.apple_events.blocked")
        case .destinations:
            return metrics.destinationCount == 0
                ? String(localized: "preflight.check.destinations.blocked")
                : String(format: String(localized: "preflight.check.destinations.count"), metrics.destinationCount)
        case .applications:
            return metrics.unavailableApplicationCount == 0
                ? String(localized: "preflight.check.applications.ready")
                : String(format: String(localized: "preflight.check.applications.unavailable"), metrics.unavailableApplicationCount)
        case .urls:
            return metrics.invalidURLCount == 0
                ? String(localized: "preflight.check.urls.ready")
                : String(format: String(localized: "preflight.check.urls.invalid"), metrics.invalidURLCount)
        case .shortcuts:
            guard metrics.configuredShortcutCount > 0 else {
                return String(localized: "preflight.check.shortcuts.none")
            }
            return String(
                format: String(localized: "preflight.check.shortcuts.summary"),
                metrics.registeredShortcutCount,
                metrics.configuredShortcutCount,
                metrics.conflictingShortcutCount,
                metrics.failedShortcutCount
            )
        }
    }
}

private extension PreflightStatus {
    var color: Color {
        switch self {
        case .ready: .green
        case .attention: .orange
        case .blocked: .red
        }
    }

    var summaryIcon: String {
        switch self {
        case .ready: "checkmark.shield.fill"
        case .attention: "exclamationmark.shield.fill"
        case .blocked: "xmark.shield.fill"
        }
    }

    var headlineKey: LocalizedStringKey {
        switch self {
        case .ready: "preflight.status.ready"
        case .attention: "preflight.status.attention"
        case .blocked: "preflight.status.blocked"
        }
    }

    var summaryKey: LocalizedStringKey {
        switch self {
        case .ready: "preflight.summary.ready"
        case .attention: "preflight.summary.attention"
        case .blocked: "preflight.summary.blocked"
        }
    }

    var badgeKey: LocalizedStringKey {
        switch self {
        case .ready: "preflight.badge.ready"
        case .attention: "preflight.badge.attention"
        case .blocked: "preflight.badge.blocked"
        }
    }

    var accessibilityLabel: Text {
        Text(badgeKey)
    }
}

private extension PreflightCheckKind {
    var iconName: String {
        switch self {
        case .accessibility: "figure.stand"
        case .appleEvents: "applescript"
        case .destinations: "scope"
        case .applications: "app.badge.checkmark"
        case .urls: "link.badge.plus"
        case .shortcuts: "keyboard.badge.ellipsis"
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .accessibility: "preflight.check.accessibility.title"
        case .appleEvents: "preflight.check.apple_events.title"
        case .destinations: "preflight.check.destinations.title"
        case .applications: "preflight.check.applications.title"
        case .urls: "preflight.check.urls.title"
        case .shortcuts: "preflight.check.shortcuts.title"
        }
    }

    var accessibilityLabel: Text { Text(titleKey) }
}
