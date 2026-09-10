import Foundation
import Testing
@testable import ClassGod

@Suite("Return Dock")
@MainActor
struct ReturnDockTests {
    private func source(_ pid: Int32 = 100) -> ReturnApplication {
        ReturnApplication(processID: pid, bundleIdentifier: "example.source", launchDate: Date(timeIntervalSince1970: 100), name: "Source")
    }

    @Test("Tracking is opt-in and skips same-app switches and ClassGod itself")
    func optsIn() {
        var app = source()
        let service = ReturnDockService(ownBundleIdentifier: "example.classgod", frontmost: { app }, activate: { _ in true })
        #expect(service.prepare(destination: "example.target") == nil)
        service.setEnabled(true)
        #expect(service.prepare(destination: app.bundleIdentifier) == nil)
        app = ReturnApplication(processID: 200, bundleIdentifier: "example.classgod", launchDate: Date(), name: "ClassGod")
        #expect(service.prepare(destination: "example.target") == nil)
        #expect(service.tickets.isEmpty)
    }

    @Test("Only the latest successful switch creates one return ticket")
    func rejectsStaleCompletions() {
        let app = source()
        let service = ReturnDockService(ownBundleIdentifier: "self", frontmost: { app }, activate: { _ in true })
        service.setEnabled(true)
        let old = service.prepare(destination: "one")
        let latest = service.prepare(destination: "two")
        service.complete(request: old, success: true)
        #expect(service.tickets.isEmpty)
        service.complete(request: latest, success: true)
        service.complete(request: latest, success: true)
        #expect(service.tickets.count == 1)
        let failed = service.prepare(destination: "three")
        service.complete(request: failed, success: false)
        #expect(service.tickets.count == 1)
    }

    @Test("Tickets are bounded, refreshed for the same process, and cleared when disabled")
    func boundsHistory() {
        var app = source()
        let service = ReturnDockService(ownBundleIdentifier: "self", frontmost: { app }, activate: { _ in true })
        service.setEnabled(true)
        for pid in 100..<107 {
            app = source(Int32(pid))
            let request = service.prepare(destination: "target")
            service.complete(request: request, success: true)
        }
        #expect(service.tickets.count == 5)
        let latest = service.prepare(destination: "target")
        service.complete(request: latest, success: true)
        #expect(service.tickets.count == 5)
        #expect(service.tickets.first?.application.processID == 106)
        let pending = service.prepare(destination: "target")
        service.setEnabled(false)
        service.complete(request: pending, success: true)
        #expect(service.tickets.isEmpty)
    }

    @Test("A failed return keeps its ticket; a successful return consumes it")
    func handlesReturnFailure() throws {
        let app = source()
        var activated = false
        let service = ReturnDockService(ownBundleIdentifier: "self", frontmost: { app }, activate: { $0 == app && activated })
        service.setEnabled(true)
        service.complete(request: service.prepare(destination: "target"), success: true)
        let ticket = try #require(service.tickets.first)
        #expect(!service.returnTo(ticket.id))
        #expect(service.returnFailed)
        #expect(service.tickets.count == 1)
        activated = true
        #expect(service.returnTo(ticket.id))
        #expect(service.tickets.isEmpty)
        #expect(!service.returnFailed)
    }

    @Test("Process identity includes launch time, preventing returns to a reused PID")
    func identifiesExactProcess() {
        let original = source()
        let replacement = ReturnApplication(processID: original.processID, bundleIdentifier: original.bundleIdentifier, launchDate: Date(timeIntervalSince1970: 200), name: "Source")
        #expect(!ReturnDockPolicy.matches(original, current: replacement))
        #expect(!ReturnDockPolicy.matches(original, current: nil))
        #expect(ReturnDockPolicy.matches(original, current: original))
    }

    @Test("A closed source app is never activated or consumed")
    func rejectsClosedApps() throws {
        let app = source()
        var activationCount = 0
        let service = ReturnDockService(ownBundleIdentifier: "self", frontmost: { app }, activate: { _ in activationCount += 1; return true }, isRunning: { _ in false })
        service.setEnabled(true)
        service.complete(request: service.prepare(destination: "target"), success: true)
        let ticket = try #require(service.tickets.first)
        #expect(!service.isAvailable(ticket))
        #expect(!service.returnTo(ticket.id))
        #expect(activationCount == 0)
        #expect(service.tickets.count == 1)
        #expect(service.returnFailed)
    }

    @Test("Clearing the dock invalidates pending capture callbacks")
    func clearsPendingCapture() {
        let app = source()
        let service = ReturnDockService(ownBundleIdentifier: "self", frontmost: { app }, activate: { _ in true })
        service.setEnabled(true)
        let request = service.prepare(destination: "target")
        service.clear()
        service.complete(request: request, success: true)
        #expect(service.tickets.isEmpty)
    }
}
