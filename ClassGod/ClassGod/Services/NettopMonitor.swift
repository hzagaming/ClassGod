//
//  NettopMonitor.swift
//  ClassGod
//
//  Real per-process network I/O via the system nettop(1) utility.
//  Spawns nettop in CSV logging/delta mode and parses per-process
//  bytes_in / bytes_out so Activity Monitor shows actual rates instead
//  of a CPU-proportional estimate.
//

import Foundation

// Mutable state is confined to queue; currentDeltas() returns a synchronized snapshot.
nonisolated final class NettopMonitor: @unchecked Sendable {
    static let shared = NettopMonitor()

    /// Latest per-process delta bytes/sec (already computed by nettop -d).
    private var deltaBytesPerSecond: [Int32: (deltaIn: UInt64, deltaOut: UInt64)] = [:]

    private var process: Process?
    private var pipe: Pipe?
    private let queue = DispatchQueue(label: "com.classgod.nettop", qos: .utility)
    private var parser: NettopCSVParser?
    private var shouldBeRunning = false

    private init() {}

    func start() {
        queue.async { [weak self] in
            guard let self else { return }
            self.shouldBeRunning = true
            self._startUnsafe()
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            self.shouldBeRunning = false
            self._stopUnsafe()
        }
    }

    /// Synchronous read of the latest deltas. Safe to call from any thread.
    func currentDeltas() -> [Int32: (deltaIn: UInt64, deltaOut: UInt64)] {
        queue.sync { deltaBytesPerSecond }
    }

    // MARK: - Private

    private func _startUnsafe() {
        guard shouldBeRunning else { return }
        guard process?.isRunning != true else { return }

        // Clean up any stale references from a previous failed launch.
        _cleanupReferences()

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/nettop")
        // -P   per-process summary
        // -d   delta mode (per-sample change rather than cumulative totals)
        // -x   extended numeric bytes
        // -J   include only bytes_in and bytes_out
        // -L 0 CSV logging, infinite samples
        // -s 1 1-second refresh
        task.arguments = [
            "-P", "-d", "-x",
            "-J", "bytes_in,bytes_out",
            "-L", "0",
            "-s", "1"
        ]

        let outPipe = Pipe()
        task.standardOutput = outPipe
        task.standardError = FileHandle.nullDevice
        task.terminationHandler = { [weak self] terminatedTask in
            self?.queue.async { [weak self] in
                guard let self, self.process === terminatedTask else { return }
                self.deltaBytesPerSecond.removeAll()
                self.queue.asyncAfter(deadline: .now() + 1) { [weak self] in
                    guard let self, self.process === terminatedTask else { return }
                    self._startUnsafe()
                }
            }
        }

        self.process = task
        self.pipe = outPipe
        self.parser = NettopCSVParser { [weak self] snapshot in
            self?.deltaBytesPerSecond = snapshot.processes
        }

        outPipe.fileHandleForReading.readabilityHandler = { [weak self, weak task] handle in
            let data = handle.availableData
            if data.isEmpty { handle.readabilityHandler = nil }
            guard let self, let task else { return }
            self.queue.async { [weak self] in
                guard let self, self.process === task else { return }
                if data.isEmpty {
                    self.deltaBytesPerSecond.removeAll()
                } else if task.isRunning {
                    self.parser?.feed(data)
                }
            }
        }

        do {
            try task.run()
        } catch {
            print("[NettopMonitor] Failed to start nettop: \(error)")
            _cleanupReferences()
        }
    }

    private func _stopUnsafe() {
        // Prevent the termination handler from restarting the process.
        process?.terminationHandler = nil
        process?.terminate()
        _cleanupReferences()
    }

    private func _cleanupReferences() {
        pipe?.fileHandleForReading.readabilityHandler = nil
        process?.terminationHandler = nil
        process = nil
        pipe = nil
        parser = nil
        deltaBytesPerSecond.removeAll()
    }
}

// MARK: - CSV Parser

nonisolated struct NettopSnapshot: Sendable {
    var processes: [Int32: (deltaIn: UInt64, deltaOut: UInt64)]
}

nonisolated final class NettopCSVParser {
    private enum SamplePhase { case awaitingHeader, cumulative, delta }
    private var buffer = Data()
    private var phase = SamplePhase.awaitingHeader
    private var currentSample = NettopSnapshot(processes: [:])
    private let onSnapshot: (NettopSnapshot) -> Void

    init(onSnapshot: @escaping (NettopSnapshot) -> Void) {
        self.onSnapshot = onSnapshot
    }

    func feed(_ data: Data) {
        var searchStart = buffer.endIndex
        buffer.append(data)
        var lineStart = buffer.startIndex
        // Decode complete lines so a pipe read may end anywhere within a UTF-8 character.
        while let newline = buffer[searchStart...].firstIndex(of: 10) {
            if let line = String(data: buffer[lineStart..<newline], encoding: .utf8) {
                handle(line: line)
            }
            lineStart = buffer.index(after: newline)
            searchStart = lineStart
        }
        if lineStart != buffer.startIndex { buffer.removeSubrange(..<lineStart) }
    }

    private func handle(line: String) {
        // Strip leading control bytes that may leak through on the first header.
        var cleaned = line
        let prefixes: [Character] = ["\u{04}", "\u{08}", " "]
        while let first = cleaned.first, prefixes.contains(first) {
            cleaned.removeFirst()
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return }

        // A new sample starts with the header row. Flush the previous sample.
        if cleaned.hasPrefix("time") {
            flushCurrentSample()
            return
        }

        if phase != .awaitingHeader, let entry = parse(line: cleaned) {
            currentSample.processes[entry.pid] = (deltaIn: entry.bytesIn, deltaOut: entry.bytesOut)
        }
    }

    private func flushCurrentSample() {
        // A header closes the preceding sample; the first sample contains cumulative totals.
        if phase == .delta { onSnapshot(currentSample) }
        phase = phase == .awaitingHeader ? .cumulative : .delta
        currentSample.processes.removeAll()
    }

    private func parse(line: String) -> (pid: Int32, bytesIn: UInt64, bytesOut: UInt64)? {
        // CSV layout (with -J bytes_in,bytes_out):
        // time, , bytes_in, bytes_out,
        // <timestamp>,<name.pid>,<bytes_in>,<bytes_out>,
        let parts = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count >= 4 else { return nil }

        // parts[1] = "name.pid" (name may contain spaces or dots)
        let namePid = parts[1]
        guard let dotIndex = namePid.lastIndex(of: ".") else { return nil }
        let pidString = String(namePid[ namePid.index(after: dotIndex)... ])
        guard let pid = Int32(pidString) else { return nil }

        guard let bytesIn = UInt64(parts[2]), let bytesOut = UInt64(parts[3]) else { return nil }
        return (pid: pid, bytesIn: bytesIn, bytesOut: bytesOut)
    }
}
