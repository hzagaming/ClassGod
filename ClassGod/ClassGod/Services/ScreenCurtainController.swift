import AppKit
import Combine
import SwiftUI

@MainActor
protocol ScreenCurtainDisplay: AnyObject {
    func show(duration: TimeInterval, onDismiss: @escaping () -> Void) -> Int
    func dismiss()
}

@MainActor
final class ScreenCurtainController: ObservableObject {
    static let shared = ScreenCurtainController(display: NativeScreenCurtainDisplay())
    @Published private(set) var session = ScreenCurtainSession()
    @Published private(set) var screenCount = 0
    @Published private(set) var presentationFailed = false
    private let display: ScreenCurtainDisplay
    private let clock: () -> TimeInterval
    private var timerTask: Task<Void, Never>?
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []

    init(display: ScreenCurtainDisplay, clock: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.display = display
        self.clock = clock
    }

    deinit {
        timerTask?.cancel()
        for (center, token) in observers { center.removeObserver(token) }
    }

    @discardableResult
    func show(duration: TimeInterval) -> Bool {
        guard session.start(now: clock(), duration: duration) else { return false }
        presentationFailed = false
        let generation = session.id
        screenCount = display.show(duration: TimeInterval(session.remainingSeconds)) { [weak self] in
            guard self?.session.id == generation else { return }
            self?.hide()
        }
        guard screenCount > 0 else {
            display.dismiss()
            session.cancel()
            presentationFailed = true
            return false
        }
        observe(.default, NSApplication.didResignActiveNotification)
        observe(.default, NSApplication.didChangeScreenParametersNotification)
        observe(NSWorkspace.shared.notificationCenter, NSWorkspace.willSleepNotification)
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled, let self, self.session.id == generation else { return }
                self.refreshTime()
                if !self.session.isActive { return }
            }
        }
        return true
    }

    func hide() {
        guard session.isActive || screenCount > 0 else { return }
        timerTask?.cancel()
        timerTask = nil
        for (center, token) in observers { center.removeObserver(token) }
        observers = []
        session.cancel()
        screenCount = 0
        display.dismiss()
    }

    func refreshTime() {
        var next = session
        next.tick(now: clock())
        if !next.isActive { hide() }
        else { session = next }
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name) {
        let generation = session.id
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard self?.session.id == generation else { return }
                self?.hide()
            }
        }
        observers.append((center, token))
    }
}

@MainActor
final class ScreenCurtainWindow: NSWindow {
    var onDismiss: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func cancelOperation(_ sender: Any?) { onDismiss?() }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onDismiss?() } else { super.keyDown(with: event) }
    }
}

@MainActor
final class NativeScreenCurtainDisplay: ScreenCurtainDisplay {
    private var windows: [ScreenCurtainWindow] = []
    private weak var previousKeyWindow: NSWindow?

    func show(duration: TimeInterval, onDismiss: @escaping () -> Void) -> Int {
        guard windows.isEmpty else { return windows.count }
        previousKeyWindow = NSApplication.shared.keyWindow
        for screen in NSScreen.screens {
            let window = ScreenCurtainWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.backgroundColor = .black
            window.isOpaque = true
            window.hasShadow = false
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.onDismiss = onDismiss
            window.contentView = NSHostingView(rootView: ScreenCurtainOverlay(deadline: ProcessInfo.processInfo.systemUptime + duration, onDismiss: onDismiss))
            window.setFrame(screen.frame, display: false)
            windows.append(window)
        }
        guard !windows.isEmpty else { return 0 }
        NSApplication.shared.activate(ignoringOtherApps: true)
        for window in windows { window.orderFrontRegardless() }
        windows.first?.makeKey()
        return windows.count
    }

    func dismiss() {
        let visible = windows
        windows = []
        for window in visible { window.onDismiss = nil; window.close() }
        if NSApplication.shared.isActive { previousKeyWindow?.makeKeyAndOrderFront(nil) }
        previousKeyWindow = nil
    }
}
