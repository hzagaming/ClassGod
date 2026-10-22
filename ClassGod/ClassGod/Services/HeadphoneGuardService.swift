import Combine
import CoreAudio
import Foundation

@MainActor
final class HeadphoneGuardService: ObservableObject {
    static let shared = HeadphoneGuardService(
        defaultOutput: QuietAudioHardware.defaultOutput,
        readMute: QuietAudioHardware.readMute,
        writeMute: QuietAudioHardware.writeMute,
        observeOutput: HeadphoneGuardHardware.observeDefaultOutput
    )

    @Published private(set) var guardedDevice: QuietDevice?
    @Published private(set) var currentOutput: QuietDevice?
    @Published private(set) var currentMuted: Bool?
    @Published private(set) var silenced: [QuietDevice] = []
    @Published private(set) var lastTrip: HeadphoneGuardTrip?
    @Published private(set) var notice = HeadphoneGuardNotice.ready
    private let defaultOutput: () -> QuietDevice?
    private let readMute: (QuietDevice) -> Bool?
    private let writeMute: (QuietDevice, Bool) -> Bool
    private let observeOutput: (@escaping @MainActor () -> Void) -> (() -> Void)?
    private let clock: () -> Date
    private var unconfirmed: Set<String> = []
    private var stopObserving: (() -> Void)?
    private var timer: Timer?

    var isArmed: Bool { guardedDevice != nil }

    init(
        defaultOutput: @escaping () -> QuietDevice?,
        readMute: @escaping (QuietDevice) -> Bool?,
        writeMute: @escaping (QuietDevice, Bool) -> Bool,
        observeOutput: @escaping (@escaping @MainActor () -> Void) -> (() -> Void)?,
        clock: @escaping () -> Date = Date.init
    ) {
        self.defaultOutput = defaultOutput
        self.readMute = readMute
        self.writeMute = writeMute
        self.observeOutput = observeOutput
        self.clock = clock
        refresh()
    }

    deinit {
        timer?.invalidate()
        stopObserving?()
    }

    func refresh() {
        currentOutput = defaultOutput()
        currentMuted = currentOutput.flatMap(readMute)
    }

    @discardableResult func arm() -> Bool {
        guard stopObserving == nil else { return false }
        refresh()
        guard let device = currentOutput,
              let cancel = observeOutput({ [weak self] in self?.outputChanged() }) else {
            notice = .unavailable
            return false
        }
        stopObserving = cancel
        guardedDevice = device
        lastTrip = nil
        notice = .armed
        return true
    }

    func disarm() {
        guard let cancel = stopObserving else { return }
        cancel()
        stopObserving = nil
        guardedDevice = nil
        notice = .disarmed
    }

    @discardableResult func restore() -> Bool {
        guard !silenced.isEmpty else { return false }
        var remaining: [QuietDevice] = []
        for device in silenced {
            guard let muted = readMute(device) else { remaining.append(device); continue }
            if muted || unconfirmed.contains(device.uid) {
                guard writeMute(device, false), readMute(device) == false else { remaining.append(device); continue }
            }
            unconfirmed.remove(device.uid)
        }
        silenced = remaining
        notice = remaining.isEmpty ? .restored : .restoreFailed
        refresh()
        return remaining.isEmpty
    }

    func startMonitoring() {
        refresh()
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stopMonitoring() { timer?.invalidate(); timer = nil }

    func shutdown() {
        stopMonitoring()
        disarm()
        _ = restore()
    }

    private func outputChanged() {
        guard let guarded = guardedDevice else { return }
        refresh()
        guard let device = currentOutput, device.uid != guarded.uid else { return }
        let outcome: HeadphoneGuardOutcome
        if let muted = readMute(device) {
            if muted {
                outcome = .alreadySilent
            } else {
                let accepted = writeMute(device, true)
                let confirmed = readMute(device) == true
                if accepted || confirmed {
                    if !silenced.contains(where: { $0.uid == device.uid }) { silenced.append(device) }
                    if confirmed { unconfirmed.remove(device.uid) } else { unconfirmed.insert(device.uid) }
                }
                outcome = confirmed ? .silenced : .failed
            }
        } else {
            outcome = .unsupported
        }
        lastTrip = .init(device: device, date: clock(), outcome: outcome)
        refresh()
    }
}

nonisolated enum HeadphoneGuardHardware {
    static func observeDefaultOutput(_ handler: @escaping @MainActor () -> Void) -> (() -> Void)? {
        let system = AudioObjectID(kAudioObjectSystemObject)
        let target = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        // The listener is delivered on the main queue, so the handler runs on the main actor.
        let block: AudioObjectPropertyListenerBlock = { _, _ in MainActor.assumeIsolated { handler() } }
        var address = target
        guard AudioObjectAddPropertyListenerBlock(system, &address, .main, block) == noErr else { return nil }
        return {
            var address = target
            AudioObjectRemovePropertyListenerBlock(system, &address, .main, block)
        }
    }
}
