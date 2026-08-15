import AppKit
import Combine
import Foundation

@MainActor
final class FakeLockService: ObservableObject {
    static let shared = FakeLockService()

    @Published var configuration: FakeLockConfiguration {
        didSet {
            persistConfiguration()
            if oldValue.shortcutKey != configuration.shortcutKey
                || oldValue.shortcutModifiers != configuration.shortcutModifiers {
                registerShortcut()
            }
        }
    }
    @Published private(set) var isSessionActive = false
    @Published private(set) var isGuardEnabled = false
    @Published private(set) var isWorking = false
    @Published private(set) var isShortcutRegistered = false
    @Published private(set) var statusMessage = String(localized: "fake_lock.status.ready")
    @Published private(set) var isError = false

    private let storageKey = "com.hanazar.classgod.fakeLock.configuration"
    private var hotKeyID: UInt32?
    private var operationSession = FakeLockOperationSession()

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(FakeLockConfiguration.self, from: data) {
            configuration = decoded
        } else {
            configuration = .default
        }
    }

    func start() {
        registerShortcut()
    }

    func stop() {
        if let hotKeyID {
            ShortcutManager.shared.unregisterCustomHotKey(id: hotKeyID)
        }
        hotKeyID = nil
        isShortcutRegistered = false
        operationSession.cancel()
        isWorking = false
        isSessionActive = false
        isGuardEnabled = false
    }

    func startSession() {
        guard !isWorking else { return }
        guard let url = FakeLockURLPolicy.normalized(configuration.url) else {
            reportFailure(String(localized: "fake_lock.error.invalid_url"))
            return
        }
        guard configuration.browser.isInstalled else {
            reportFailure(String(localized: "fake_lock.error.browser_missing"))
            return
        }

        let request = operationSession.begin()
        isWorking = true
        let browser = configuration.browser
        let fullScreen = FakeLockSessionPolicy.shouldOpenFullScreen(
            mode: configuration.mode,
            requested: configuration.openFullScreen
        )
        let openSource = Self.openScript(browser: browser, url: url)
        let fullScreenSource = Self.fullScreenScript(browser: browser)
        Task {
            let result = await Self.executeInBackground(openSource)
            guard operationSession.isCurrent(request) else { return }
            isWorking = false
            guard result.success else {
                _ = operationSession.complete(request)
                reportFailure(result.message)
                return
            }
            isSessionActive = true
            isGuardEnabled = true
            setStatus(String(localized: "fake_lock.status.active"), isError: false)
            SoundEffectManager.shared.playFeatureSwitch()
            HapticManager.shared.success()

            guard fullScreen else {
                _ = operationSession.complete(request)
                return
            }
            try? await Task.sleep(for: .milliseconds(450))
            guard operationSession.isCurrent(request) else { return }
            let fullScreenResult = await Self.executeInBackground(fullScreenSource)
            guard operationSession.complete(request) else { return }
            guard !fullScreenResult.success else { return }
            setStatus(String(localized: "fake_lock.warning.fullscreen_permission"), isError: false)
        }
    }

    func stopSession() {
        operationSession.cancel()
        isWorking = false
        isSessionActive = false
        isGuardEnabled = false
        setStatus(String(localized: "fake_lock.status.stopped"), isError: false)
        SoundEffectManager.shared.playFeatureSwitch()
    }

    func toggleGuard() {
        guard isSessionActive else {
            startSession()
            return
        }
        isGuardEnabled.toggle()
        setStatus(
            String(localized: isGuardEnabled ? "fake_lock.status.active" : "fake_lock.status.unlocked"),
            isError: false
        )
        SoundEffectManager.shared.playFeatureSwitch()
        HapticManager.shared.generic()
    }

    func navigate(_ direction: FakeLockDirection) {
        guard isSessionActive else {
            reportFailure(String(localized: "fake_lock.error.not_active"))
            return
        }
        let decision = isGuardEnabled
            ? FakeLockNavigationPolicy.decision(
                for: direction,
                lockBackward: configuration.lockBackward,
                lockForward: configuration.lockForward
            )
            : .allowed
        guard decision == .allowed else {
            reportFailure(String(localized: "fake_lock.status.direction_locked"))
            return
        }

        let browser = configuration.browser
        let source = Self.navigationScript(browser: browser, direction: direction)
        Task {
            let result = await Self.executeInBackground(source)
            if result.success {
                setStatus(String(localized: "fake_lock.status.navigation_sent"), isError: false)
                SoundEffectManager.shared.playFeatureSwitch()
                HapticManager.shared.generic()
            } else {
                reportFailure(result.message)
            }
        }
    }

    private func registerShortcut() {
        if let hotKeyID {
            ShortcutManager.shared.unregisterCustomHotKey(id: hotKeyID)
        }
        hotKeyID = nil
        isShortcutRegistered = false
        guard let keyCode = ShortcutManager.shared.keyCode(for: configuration.shortcutKey),
              !configuration.shortcutKey.isEmpty else { return }
        hotKeyID = ShortcutManager.shared.registerCustomHotKey(
            keyCode: keyCode,
            cocoaModifiers: UInt32(configuration.shortcutModifiers)
        ) { [weak self] in
            self?.toggleGuard()
        }
        isShortcutRegistered = hotKeyID != nil
    }

    private func persistConfiguration() {
        guard let data = try? JSONEncoder().encode(configuration) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func setStatus(_ message: String, isError: Bool) {
        statusMessage = message
        self.isError = isError
    }

    private func reportFailure(_ message: String) {
        setStatus(message, isError: true)
        SoundEffectManager.shared.playSwitchFailure()
        HapticManager.shared.warning()
    }

    private nonisolated static func openScript(browser: BrowserType, url: URL) -> String {
        let bundleID = AppleScriptLiteral.escaped(bundleIdentifier(for: browser))
        let safeURL = AppleScriptLiteral.escaped(url.absoluteString)
        switch browser {
        case .safari:
            return """
            tell application id "\(bundleID)"
                activate
                if (count of windows) is 0 then
                    make new document with properties {URL:"\(safeURL)"}
                else
                    set URL of current tab of front window to "\(safeURL)"
                end if
            end tell
            """
        case .chrome, .edge:
            return """
            tell application id "\(bundleID)"
                activate
                if (count of windows) is 0 then make new window
                set URL of active tab of front window to "\(safeURL)"
            end tell
            """
        }
    }

    private nonisolated static func fullScreenScript(browser: BrowserType) -> String {
        let bundleID = AppleScriptLiteral.escaped(bundleIdentifier(for: browser))
        return """
        tell application id "\(bundleID)" to activate
        tell application "System Events" to key code 3 using {control down, command down}
        """
    }

    private nonisolated static func navigationScript(
        browser: BrowserType,
        direction: FakeLockDirection
    ) -> String {
        let bundleID = AppleScriptLiteral.escaped(bundleIdentifier(for: browser))
        let keyCode = direction == .backward ? 33 : 30
        return """
        tell application id "\(bundleID)" to activate
        tell application "System Events" to key code \(keyCode) using {command down}
        """
    }

    private nonisolated static func bundleIdentifier(for browser: BrowserType) -> String {
        switch browser {
        case .safari: "com.apple.Safari"
        case .chrome: "com.google.Chrome"
        case .edge: "com.microsoft.edgemac"
        }
    }

    private nonisolated static func execute(_ source: String) -> (success: Bool, message: String) {
        guard let script = NSAppleScript(source: source) else {
            return (false, String(localized: "fake_lock.error.script_create"))
        }
        var errorInfo: NSDictionary?
        _ = script.executeAndReturnError(&errorInfo)
        guard let errorInfo else { return (true, "") }
        let message = errorInfo[NSAppleScript.errorMessage] as? String
            ?? String(localized: "fake_lock.error.script_failed")
        return (false, message)
    }

    private static func executeInBackground(_ source: String) async -> (success: Bool, message: String) {
        await Task.detached(priority: .userInitiated) {
            execute(source)
        }.value
    }
}
