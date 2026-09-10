import AppKit
import Testing
@testable import ClassGod

@Suite("Screen Curtain")
struct ScreenCurtainTests {
    @Test("Curtains have bounded lifetimes and expire at the exact deadline")
    func expires() {
        var session = ScreenCurtainSession()
        #expect(session.start(now: 10, duration: 30) == true)
        #expect(session.start(now: 11, duration: 30) == false)
        session.tick(now: 39.1)
        #expect(session.remainingSeconds == 1)
        session.tick(now: 40)
        #expect(!session.isActive)
        #expect(session.start(now: 50, duration: 9_999) == true)
        #expect(session.remainingSeconds == 120)
    }

    @Test("Invalid or reversed clock values release the curtain")
    func rejectsInvalidClock() {
        var session = ScreenCurtainSession()
        #expect(session.start(now: .nan, duration: 30) == false)
        #expect(session.start(now: 10, duration: .infinity) == false)
        #expect(session.start(now: 10, duration: 30) == true)
        session.tick(now: 9)
        #expect(!session.isActive)
    }

    @Test("Unavailable screens do not leave an active curtain or pending timer")
    @MainActor
    func handlesNoDisplays() {
        let display = FakeCurtainDisplay()
        display.count = 0
        let service = ScreenCurtainController(display: display, clock: { 10 })
        #expect(!service.show(duration: 30))
        #expect(!service.session.isActive)
        #expect(service.presentationFailed)
        #expect(display.dismissals == 1)
    }

    @Test("Dismiss and timeout release every overlay; stale close actions cannot stop a new curtain")
    @MainActor
    func releasesAndRejectsStaleCallbacks() {
        var now: TimeInterval = 10
        let display = FakeCurtainDisplay()
        let service = ScreenCurtainController(display: display, clock: { now })
        #expect(service.show(duration: 30))
        #expect(service.screenCount == 2)
        let oldClose = display.close
        service.hide()
        #expect(display.dismissals == 1)
        #expect(service.show(duration: 30))
        oldClose?()
        #expect(service.session.isActive)
        now = 40
        service.refreshTime()
        #expect(!service.session.isActive)
        #expect(display.dismissals == 2)
        service.hide()
        #expect(display.dismissals == 2)
    }

    @Test("Deactivation, sleep, and display changes remove overlays and pending observers")
    @MainActor
    func dismissesEnvironmentChanges() async throws {
        for (center, name) in [
            (NotificationCenter.default, NSApplication.didResignActiveNotification),
            (NotificationCenter.default, NSApplication.didChangeScreenParametersNotification),
            (NSWorkspace.shared.notificationCenter, NSWorkspace.willSleepNotification),
        ] {
            let display = FakeCurtainDisplay()
            let service = ScreenCurtainController(display: display, clock: { 10 })
            #expect(service.show(duration: 30))
            center.post(name: name, object: nil)
            for _ in 0..<100 {
                if !service.session.isActive { break }
                try await Task.sleep(for: .milliseconds(10))
            }
            #expect(!service.session.isActive)
            #expect(display.dismissals == 1)
            service.hide()
        }
    }

    @Test("Escape is handled by the borderless curtain window")
    @MainActor
    func escapeClosesCurtain() {
        let window = ScreenCurtainWindow(contentRect: .init(x: 0, y: 0, width: 300, height: 200), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        var dismissed = false
        window.onDismiss = { dismissed = true }
        #expect(window.canBecomeKey)
        window.cancelOperation(nil)
        #expect(dismissed)
        window.close()
    }
}

@MainActor
private final class FakeCurtainDisplay: ScreenCurtainDisplay {
    var count = 2
    var dismissals = 0
    var close: (() -> Void)?
    func show(duration: TimeInterval, onDismiss: @escaping () -> Void) -> Int {
        close = onDismiss
        return count
    }
    func dismiss() { dismissals += 1 }
}
