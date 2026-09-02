import Testing
@testable import ClassGod

@Suite("System monitor policies")
struct SystemMonitorPolicyTests {
    @Test("CPU tick sampling handles large counters without overflow")
    func handlesLargeCPUTickCounters() throws {
        let previous = CPUTickSnapshot(
            user: .max - 100,
            system: .max - 200,
            idle: .max - 300,
            nice: .max - 400
        )
        let current = CPUTickSnapshot(
            user: .max - 90,
            system: .max - 180,
            idle: .max - 270,
            nice: .max - 360
        )

        let usage = try #require(CPUTickLoadPolicy.usage(current: current, previous: previous))

        #expect(usage.total == 70)
        #expect(usage.user == 10)
        #expect(usage.system == 20)
        #expect(usage.idle == 30)
    }

    @Test("CPU tick sampling preserves deltas across counter wraparound")
    func handlesCPUTickWraparound() throws {
        let previous = CPUTickSnapshot(user: .max - 2, system: 10, idle: .max, nice: 20)
        let current = CPUTickSnapshot(user: 1, system: 12, idle: 2, nice: 21)

        let usage = try #require(CPUTickLoadPolicy.usage(current: current, previous: previous))

        #expect(usage.total.isFinite)
        #expect(abs(usage.total - 70) < 0.000_001)
        #expect(abs(usage.idle - 30) < 0.000_001)
    }
}
