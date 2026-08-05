import Foundation
import Testing
import UserNotifications
@testable import ClassGod

@Suite("Fan refresh policy")
struct FanRefreshPolicyTests {
    @Test("Default refreshes twice per second")
    func defaultInterval() {
        #expect(AppPreferences.default.fanControlUpdateInterval == 0.5)
        #expect(FanRefreshPolicy.defaultInterval == 0.5)
    }

    @Test("Refresh interval never falls below the hardware-safe minimum")
    func clampsInterval() {
        #expect(FanRefreshPolicy.normalized(0) == 0.5)
        #expect(FanRefreshPolicy.normalized(0.25) == 0.5)
        #expect(FanRefreshPolicy.normalized(2) == 2)
    }

    @Test("Existing preferences adopt the new realtime default once")
    func migratesExistingDefault() throws {
        let data = Data(#"{"version":3,"fanControlUpdateInterval":1}"#.utf8)
        let preferences = try JSONDecoder().decode(AppPreferences.self, from: data)
        #expect(preferences.fanControlUpdateInterval == 0.5)
        #expect(preferences.version == AppPreferences.default.version)
    }

    @Test("Overlapping refresh ticks are coalesced")
    func coalescesRefreshes() {
        var gate = FanRefreshGate()
        let first = gate.begin()
        let overlapping = gate.begin()
        #expect(first)
        #expect(!overlapping)
        gate.end()
        let next = gate.begin()
        #expect(next)
    }

    @Test("Shared monitoring honors the fastest active client")
    func resolvesSharedMonitorInterval() {
        var requests: [SystemMonitorClient: TimeInterval] = [
            .widgetHost: WidgetRefreshPolicy.hostSnapshotInterval,
            .hackerDesktop: 2,
            .activityMonitor: 1,
        ]

        #expect(SystemMonitorIntervalPolicy.effectiveInterval(for: requests) == 1)
        requests[.hackerDesktop] = 0.05
        #expect(SystemMonitorIntervalPolicy.effectiveInterval(for: requests) == 0.1)
        requests.removeValue(forKey: .hackerDesktop)
        #expect(SystemMonitorIntervalPolicy.effectiveInterval(for: requests) == 1)
        requests.removeValue(forKey: .activityMonitor)
        #expect(SystemMonitorIntervalPolicy.effectiveInterval(for: requests) == WidgetRefreshPolicy.hostSnapshotInterval)
    }

    @Test("The first network sample never reports a launch spike")
    func suppressesInitialNetworkDelta() {
        #expect(MonotonicCounterPolicy.delta(current: 1_000, previous: nil) == 0)
        #expect(MonotonicCounterPolicy.delta(current: 1_250, previous: 1_000) == 250)
        #expect(MonotonicCounterPolicy.delta(current: 20, previous: 1_000) == 0)
        #expect(MonotonicCounterPolicy.rate(current: 1_300, previous: 1_000, interval: 2) == 150)
    }

    @Test("Fan alerts require authorization already granted in Permission Center")
    func notificationDeliveryRequiresExistingAuthorization() {
        #expect(FanNotificationPolicy.canDeliver(
            isEnabled: true,
            authorizationStatus: .authorized,
            currentTemperature: 85,
            threshold: 85
        ))
        #expect(FanNotificationPolicy.canDeliver(
            isEnabled: true,
            authorizationStatus: .provisional,
            currentTemperature: 90,
            threshold: 85
        ))
        #expect(!FanNotificationPolicy.canDeliver(
            isEnabled: true,
            authorizationStatus: .authorized,
            currentTemperature: 84.9,
            threshold: 85
        ))
        #expect(!FanNotificationPolicy.canDeliver(
            isEnabled: true,
            authorizationStatus: .notDetermined,
            currentTemperature: 90,
            threshold: 85
        ))
        #expect(!FanNotificationPolicy.canDeliver(
            isEnabled: true,
            authorizationStatus: .denied,
            currentTemperature: 90,
            threshold: 85
        ))
        #expect(!FanNotificationPolicy.canDeliver(
            isEnabled: false,
            authorizationStatus: .authorized,
            currentTemperature: 90,
            threshold: 85
        ))
    }
}
