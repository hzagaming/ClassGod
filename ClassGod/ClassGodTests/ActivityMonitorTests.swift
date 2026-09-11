import Testing
@testable import ClassGod

@Suite("Activity monitor sorting")
@MainActor
struct ActivityMonitorTests {
    @Test("User sorting resolves each distinct UID at most once", arguments: [true, false])
    func boundsUserLookups(ascending: Bool) {
        let processes = (0..<1_000).map { process(pid: Int32($0 + 1), uid: UInt32($0 % 3)) }
        var calls: [UInt32: Int] = [:]
        let sorted = ActivityUserSort.sorted(processes, ascending: ascending) { uid in
            calls[uid, default: 0] += 1
            return [0: "root", 1: "student", 2: "_service"][uid]!
        }
        #expect(sorted.count == processes.count)
        #expect(calls == [0: 1, 1: 1, 2: 1])
        #expect(Set(sorted.map(\.pid)) == Set(processes.map(\.pid)))
    }

    @Test("User names determine ascending and descending order while ties retain input order")
    func preservesUserOrdering() {
        let processes = [process(pid: 1, uid: 20), process(pid: 2, uid: 10), process(pid: 3, uid: 30), process(pid: 4, uid: 10)]
        let name = { (uid: UInt32) in uid == 20 ? "zebra" : "alpha" }
        #expect(ActivityUserSort.sorted(processes, ascending: true, userName: name).map(\.pid) == [2, 3, 4, 1])
        #expect(ActivityUserSort.sorted(processes, ascending: false, userName: name).map(\.pid) == [1, 2, 3, 4])
    }

    @Test("User name results are refreshed for each sort, including previous numeric fallbacks")
    func refreshesUserNames() {
        let processes = [process(pid: 1, uid: 20), process(pid: 2, uid: 10)]
        #expect(ActivityUserSort.sorted(processes, ascending: true, userName: { String($0) }).map(\.pid) == [2, 1])
        #expect(ActivityUserSort.sorted(processes, ascending: true, userName: { $0 == 20 ? "alpha" : "zebra" }).map(\.pid) == [1, 2])
    }

    @Test("Empty and single-process lists do not query the user directory")
    func skipsEmptyInput() {
        let lookup: (UInt32) -> String = { _ in
            Issue.record("No user lookup is needed without comparisons")
            return ""
        }
        #expect(ActivityUserSort.sorted([], ascending: true, userName: lookup).isEmpty)
        let single = [process(pid: 1, uid: 0)]
        #expect(ActivityUserSort.sorted(single, ascending: true, userName: lookup) == single)
    }

    private func process(pid: Int32, uid: UInt32) -> ProcessMonitorInfo {
        ProcessMonitorInfo(pid: pid, name: "Process \(pid)", cpuPercent: 0, memoryMB: 0, uid: uid)
    }
}
