import AppKit
import Combine

@MainActor
final class ReturnDockService: ObservableObject {
    static let shared = ReturnDockService(
        ownBundleIdentifier: Bundle.main.bundleIdentifier ?? "com.hanazar.classgod",
        frontmost: { ReturnDockWorkspace.descriptor(NSWorkspace.shared.frontmostApplication) },
        activate: ReturnDockWorkspace.activate,
        isRunning: ReturnDockWorkspace.isRunning
    )
    @Published private(set) var isEnabled = false
    @Published private(set) var tickets: [ReturnTicket] = []
    @Published private(set) var returnFailed = false
    private let ownBundleIdentifier: String
    private let frontmost: () -> ReturnApplication?
    private let activate: (ReturnApplication) -> Bool
    private let isRunning: (ReturnApplication) -> Bool
    private var pending: (id: UUID, application: ReturnApplication)?

    init(ownBundleIdentifier: String, frontmost: @escaping () -> ReturnApplication?, activate: @escaping (ReturnApplication) -> Bool, isRunning: @escaping (ReturnApplication) -> Bool = { _ in true }) {
        self.ownBundleIdentifier = ownBundleIdentifier
        self.frontmost = frontmost
        self.activate = activate
        self.isRunning = isRunning
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled { clear() }
    }

    func prepare(destination: String) -> UUID? {
        pending = nil
        guard isEnabled, let application = frontmost(),
              ReturnDockPolicy.canCapture(application, destination: destination, ownBundleIdentifier: ownBundleIdentifier) else { return nil }
        let id = UUID()
        pending = (id, application)
        return id
    }

    func complete(request: UUID?, success: Bool) {
        guard isEnabled, let request, let pending, pending.id == request else { return }
        self.pending = nil
        guard success else { return }
        tickets.removeAll { ReturnDockPolicy.matches($0.application, current: pending.application) }
        tickets.insert(ReturnTicket(application: pending.application, createdAt: Date()), at: 0)
        tickets = Array(tickets.prefix(5))
    }

    func isAvailable(_ ticket: ReturnTicket) -> Bool { isRunning(ticket.application) }

    @discardableResult
    func returnTo(_ id: UUID) -> Bool {
        guard let ticket = tickets.first(where: { $0.id == id }) else { return false }
        pending = nil
        guard isRunning(ticket.application), activate(ticket.application) else {
            returnFailed = true
            return false
        }
        returnFailed = false
        tickets.removeAll { $0.id == id }
        return true
    }

    func remove(_ id: UUID) { tickets.removeAll { $0.id == id }; returnFailed = false }
    func clear() { pending = nil; tickets = []; returnFailed = false }
}

@MainActor
enum ReturnDockWorkspace {
    static func descriptor(_ application: NSRunningApplication?) -> ReturnApplication? {
        guard let application, !application.isTerminated, application.activationPolicy == .regular,
              application.processIdentifier > 0, let bundleIdentifier = application.bundleIdentifier,
              let launchDate = application.launchDate else { return nil }
        return ReturnApplication(
            processID: application.processIdentifier, bundleIdentifier: bundleIdentifier,
            launchDate: launchDate, name: String((application.localizedName ?? bundleIdentifier).prefix(120))
        )
    }

    static func isRunning(_ application: ReturnApplication) -> Bool {
        ReturnDockPolicy.matches(application, current: descriptor(NSRunningApplication(processIdentifier: application.processID)))
    }

    static func activate(_ application: ReturnApplication) -> Bool {
        let running = NSRunningApplication(processIdentifier: application.processID)
        guard ReturnDockPolicy.matches(application, current: descriptor(running)) else { return false }
        return running?.activate(options: [.activateAllWindows]) == true
    }
}
