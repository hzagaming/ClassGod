import Combine
import Foundation

@MainActor
final class QuietDeskService: ObservableObject {
    static let shared = QuietDeskService(
        defaultOutput: QuietAudioHardware.defaultOutput,
        readMute: QuietAudioHardware.readMute,
        writeMute: QuietAudioHardware.writeMute
    )

    @Published private(set) var restoreDevice: QuietDevice?
    @Published private(set) var currentOutput: QuietDevice?
    @Published private(set) var currentMuted: Bool?
    @Published private(set) var notice = QuietDeskNotice.ready
    private let defaultOutput: () -> QuietDevice?
    private let readMute: (QuietDevice) -> Bool?
    private let writeMute: (QuietDevice, Bool) -> Bool
    private var muteWasConfirmed = false
    private var timer: Timer?

    init(defaultOutput: @escaping () -> QuietDevice?, readMute: @escaping (QuietDevice) -> Bool?, writeMute: @escaping (QuietDevice, Bool) -> Bool) {
        self.defaultOutput = defaultOutput
        self.readMute = readMute
        self.writeMute = writeMute
        refresh()
    }

    func refresh() {
        currentOutput = defaultOutput()
        currentMuted = currentOutput.flatMap(readMute)
    }

    @discardableResult func mute() -> Bool {
        guard restoreDevice == nil else { return false }
        guard let device = defaultOutput(), let muted = readMute(device) else {
            notice = .unavailable; refresh(); return false
        }
        guard !muted else { notice = .alreadyMuted; refresh(); return false }
        restoreDevice = device
        let accepted = writeMute(device, true)
        let confirmed = readMute(device)
        if !accepted, confirmed == false { restoreDevice = nil }
        let success = accepted && confirmed == true
        muteWasConfirmed = success
        notice = success ? .muted : .muteFailed
        refresh()
        return success
    }

    @discardableResult func restore() -> Bool {
        guard let device = restoreDevice else { return false }
        guard let muted = readMute(device) else { notice = .restoreFailed; refresh(); return false }
        if muted || !muteWasConfirmed, !writeMute(device, false) || readMute(device) != false {
            notice = .restoreFailed; refresh(); return false
        }
        restoreDevice = nil
        muteWasConfirmed = false
        notice = .restored
        refresh()
        return true
    }

    func forget() { restoreDevice = nil; muteWasConfirmed = false; notice = .ready; refresh() }

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
    func shutdown() { stopMonitoring(); _ = restore() }
    deinit { timer?.invalidate() }
}
