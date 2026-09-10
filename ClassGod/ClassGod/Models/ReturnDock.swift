import Foundation

nonisolated struct ReturnApplication: Equatable {
    let processID: Int32
    let bundleIdentifier: String
    let launchDate: Date
    let name: String
}

nonisolated struct ReturnTicket: Identifiable, Equatable {
    let id = UUID()
    let application: ReturnApplication
    let createdAt: Date
}

nonisolated enum ReturnDockPolicy {
    static func canCapture(_ application: ReturnApplication, destination: String, ownBundleIdentifier: String) -> Bool {
        application.processID > 0 && application.launchDate.timeIntervalSince1970.isFinite
            && !application.bundleIdentifier.isEmpty && !destination.isEmpty
            && application.bundleIdentifier != ownBundleIdentifier
            && application.bundleIdentifier != destination
    }

    static func matches(_ application: ReturnApplication, current: ReturnApplication?) -> Bool {
        guard let current else { return false }
        return application.processID == current.processID
            && application.bundleIdentifier == current.bundleIdentifier
            && application.launchDate == current.launchDate
    }
}
