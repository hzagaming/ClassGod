import SwiftUI

struct FakeLockView: View {
    @ObservedObject private var service = FakeLockService.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var isRecordingShortcut = false

    var onClose: () -> Void

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    private var accent: Color { prefs.preferences.themeAccent.color }
    private var sessionConfigurationLocked: Bool { service.isSessionActive || service.isWorking }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 12 * zoomScale) {
                        statusCard
                        modeCard
                        browserCard
                        navigationCard
                        shortcutCard
                    }
                    .padding(14 * zoomScale)
                }
                actionBar
            }
        }
        .tint(accent)
        .preferredColorScheme(.dark)
        .overlay(
            RoundedRectangle(cornerRadius: 12 * zoomScale)
                .stroke(Color.white.opacity(0.12), lineWidth: zoomScale)
                .allowsHitTesting(false)
        )
    }

    private var header: some View {
        HStack(spacing: 10 * zoomScale) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10 * zoomScale, weight: .bold))
                    .foregroundStyle(.white.opacity(0.68))
                    .frame(width: 26 * zoomScale, height: 26 * zoomScale)
                    .background(Color(white: 0.09))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("button.close"))

            Image(systemName: "lock.rectangle.stack.fill")
                .font(.system(size: 15 * zoomScale))
                .foregroundStyle(accent)

            VStack(alignment: .leading, spacing: 1 * zoomScale) {
                Text("fake_lock.title")
                    .font(.system(size: 14 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("fake_lock.subtitle")
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            Text(service.isSessionActive ? "fake_lock.session.active" : "fake_lock.session.inactive")
                .font(.system(size: 8 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(service.isSessionActive ? .green : .white.opacity(0.4))
                .padding(.horizontal, 8 * zoomScale)
                .frame(height: 22 * zoomScale)
                .background((service.isSessionActive ? Color.green : Color.white).opacity(0.08))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 14 * zoomScale)
        .padding(.vertical, 10 * zoomScale)
        .background(Color(white: 0.025))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: zoomScale)
        }
    }

    private var statusCard: some View {
        HStack(spacing: 10 * zoomScale) {
            Image(systemName: service.isError ? "exclamationmark.triangle.fill" : "shield.lefthalf.filled")
                .foregroundStyle(service.isError ? .orange : accent)
            VStack(alignment: .leading, spacing: 2 * zoomScale) {
                Text(service.statusMessage)
                    .font(.system(size: 10 * zoomScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.86))
                Text(service.isGuardEnabled ? "fake_lock.guard.enabled" : "fake_lock.guard.disabled")
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            if service.isSessionActive {
                Button(action: service.toggleGuard) {
                    Label(
                        service.isGuardEnabled ? "fake_lock.action.unlock" : "fake_lock.action.enable",
                        systemImage: service.isGuardEnabled ? "lock.open.fill" : "lock.fill"
                    )
                    .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10 * zoomScale)
                    .frame(height: 28 * zoomScale)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12 * zoomScale)
        .background(Color.white.opacity(0.035))
        .overlay(cardBorder)
    }

    private var modeCard: some View {
        card(title: "fake_lock.section.mode", icon: "square.stack.3d.up.fill") {
            Picker("", selection: $service.configuration.mode) {
                ForEach(FakeLockMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityLabel(Text("fake_lock.section.mode"))
            .onChange(of: service.configuration.mode) { oldValue, newValue in
                guard oldValue != newValue else { return }
                SoundEffectManager.shared.playFeatureSwitch()
                HapticManager.shared.generic()
            }

            Text(service.configuration.mode == .mapTestBypass
                ? "fake_lock.mode.maptest.description"
                : "fake_lock.mode.safe_browser.description")
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))
                .fixedSize(horizontal: false, vertical: true)
        }
        .disabled(sessionConfigurationLocked)
        .opacity(sessionConfigurationLocked ? 0.65 : 1)
    }

    private var browserCard: some View {
        card(title: "fake_lock.section.browser", icon: "safari.fill") {
            HStack(spacing: 8 * zoomScale) {
                ForEach(BrowserType.allCases) { browser in
                    Button {
                        guard service.configuration.browser != browser else { return }
                        service.configuration.browser = browser
                        SoundEffectManager.shared.playFeatureSwitch()
                        HapticManager.shared.generic()
                    } label: {
                        HStack(spacing: 6 * zoomScale) {
                            Image(systemName: browser.sfSymbolName)
                            Text(browser.displayName)
                                .lineLimit(1)
                        }
                        .font(.system(size: 9 * zoomScale, weight: .semibold, design: .monospaced))
                        .foregroundStyle(service.configuration.browser == browser ? .black : .white.opacity(browser.isInstalled ? 0.72 : 0.28))
                        .frame(maxWidth: .infinity, minHeight: 30 * zoomScale)
                        .background(service.configuration.browser == browser ? accent : Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                    }
                    .buttonStyle(.plain)
                    .disabled(!browser.isInstalled)
                    .accessibilityAddTraits(service.configuration.browser == browser ? .isSelected : [])
                }
            }

            VStack(alignment: .leading, spacing: 5 * zoomScale) {
                Text("fake_lock.url")
                    .font(.system(size: 9 * zoomScale, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
                TextField("https://example.com", text: $service.configuration.url)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10 * zoomScale)
                    .frame(height: 34 * zoomScale)
                    .background(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6 * zoomScale)
                            .stroke(FakeLockURLPolicy.normalized(service.configuration.url) == nil ? Color.orange.opacity(0.7) : Color.white.opacity(0.1))
                    )
                    .accessibilityLabel(Text("fake_lock.url"))
            }

            SettingsToggleRow(
                icon: "arrow.up.left.and.arrow.down.right",
                title: "fake_lock.fullscreen",
                subtitle: "fake_lock.fullscreen.subtitle",
                isOn: fullScreenBinding
            )
            .disabled(service.configuration.mode == .mapTestBypass)
        }
        .disabled(sessionConfigurationLocked)
        .opacity(sessionConfigurationLocked ? 0.65 : 1)
    }

    private var navigationCard: some View {
        card(title: "fake_lock.section.navigation", icon: "arrow.left.arrow.right") {
            HStack(spacing: 8 * zoomScale) {
                navigationToggle(
                    title: "fake_lock.lock_backward",
                    icon: "arrow.left",
                    isOn: $service.configuration.lockBackward
                )
                navigationToggle(
                    title: "fake_lock.lock_forward",
                    icon: "arrow.right",
                    isOn: $service.configuration.lockForward
                )
            }

            HStack(spacing: 10 * zoomScale) {
                navigationButton("fake_lock.go_backward", icon: "chevron.left.2", direction: .backward)
                navigationButton("fake_lock.go_forward", icon: "chevron.right.2", direction: .forward)
            }
        }
    }

    private var shortcutCard: some View {
        card(title: "fake_lock.section.shortcut", icon: "command") {
            Text("fake_lock.shortcut.description")
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))
            ShortcutPicker(
                key: $service.configuration.shortcutKey,
                modifiers: $service.configuration.shortcutModifiers,
                isRecording: $isRecordingShortcut
            )
            Label(
                service.isShortcutRegistered
                    ? "fake_lock.shortcut.registered"
                    : "fake_lock.shortcut.conflict",
                systemImage: service.isShortcutRegistered
                    ? "checkmark.circle.fill"
                    : "exclamationmark.triangle.fill"
            )
            .font(.system(size: 8 * zoomScale, design: .monospaced))
            .foregroundStyle(service.isShortcutRegistered ? .green : .orange)
        }
    }

    private var fullScreenBinding: Binding<Bool> {
        Binding(
            get: {
                service.configuration.mode == .mapTestBypass
                    || service.configuration.openFullScreen
            },
            set: { service.configuration.openFullScreen = $0 }
        )
    }

    private var actionBar: some View {
        HStack(spacing: 10 * zoomScale) {
            Text("fake_lock.safety_note")
                .font(.system(size: 8 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.32))
                .lineLimit(2)
            Spacer()
            if service.isSessionActive {
                Button("fake_lock.stop", action: service.stopSession)
                    .buttonStyle(.plain)
                    .foregroundStyle(.red.opacity(0.85))
                    .padding(.horizontal, 14 * zoomScale)
                    .frame(height: 32 * zoomScale)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 7 * zoomScale))
            }
            if !service.isSessionActive {
                Button(action: service.startSession) {
                    HStack(spacing: 6 * zoomScale) {
                        if service.isWorking { ProgressView().controlSize(.small) }
                        Image(systemName: "play.fill")
                        Text("fake_lock.start")
                    }
                    .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16 * zoomScale)
                    .frame(height: 32 * zoomScale)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 7 * zoomScale))
                }
                .buttonStyle(.plain)
                .disabled(service.isWorking || FakeLockURLPolicy.normalized(service.configuration.url) == nil)
            }
        }
        .padding(.horizontal, 14 * zoomScale)
        .padding(.vertical, 10 * zoomScale)
        .background(Color(white: 0.025))
        .overlay(alignment: .top) {
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: zoomScale)
        }
    }

    private func card<Content: View>(
        title: LocalizedStringKey,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10 * zoomScale) {
            Label(title, systemImage: icon)
                .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(accent)
            content()
        }
        .padding(12 * zoomScale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.025))
        .overlay(cardBorder)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 9 * zoomScale)
            .stroke(Color.white.opacity(0.08), lineWidth: zoomScale)
            .allowsHitTesting(false)
    }

    private func navigationToggle(
        title: LocalizedStringKey,
        icon: String,
        isOn: Binding<Bool>
    ) -> some View {
        let feedbackBinding = Binding(
            get: { isOn.wrappedValue },
            set: { newValue in
                guard UserInteractionFeedbackPolicy.shouldEmit(
                    currentValue: isOn.wrappedValue,
                    newValue: newValue,
                    isUserInitiated: true
                ) else { return }
                isOn.wrappedValue = newValue
                SoundEffectManager.shared.playButtonClick()
                HapticManager.shared.generic()
            }
        )

        return Toggle(isOn: feedbackBinding) {
            Label(title, systemImage: icon)
                .font(.system(size: 9 * zoomScale, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.72))
        }
        .toggleStyle(.switch)
        .padding(.horizontal, 10 * zoomScale)
        .frame(maxWidth: .infinity, minHeight: 36 * zoomScale)
        .background(Color.white.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 7 * zoomScale))
    }

    private func navigationButton(
        _ title: LocalizedStringKey,
        icon: String,
        direction: FakeLockDirection
    ) -> some View {
        Button {
            service.navigate(direction)
        } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, minHeight: 32 * zoomScale)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
        }
        .buttonStyle(.plain)
        .disabled(!service.isSessionActive)
    }
}
