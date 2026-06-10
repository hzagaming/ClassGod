//
//  SMCHelperClient.swift
//  ClassGod
//
//  Client for the privileged ClassGodHelper tool (Unix domain socket).
//  Keeps a persistent connection to avoid connect/teardown overhead on
//  every read/write and supports a single "readAll" call that returns
//  both fan and temperature data in one round-trip.
//

import Foundation

final class SMCHelperClient {
    static let shared = SMCHelperClient()
    static let socketPath = "/tmp/com.hanazar.classgod.helper.sock"

    var isHelperAvailable: Bool {
        FileManager.default.fileExists(atPath: Self.socketPath)
    }

    private var fd: Int32 = -1
    private let lock = NSLock()

    private init() {}

    // MARK: - Public API

    func readFans() -> [[String: Any]]? {
        guard isHelperAvailable else { return nil }
        let res = sendCommand(["cmd": "readFans"])
        return res?["data"] as? [[String: Any]]
    }

    func readTemps() -> [[String: Any]]? {
        guard isHelperAvailable else { return nil }
        let res = sendCommand(["cmd": "readTemps"])
        return res?["data"] as? [[String: Any]]
    }

    /// Combined read: returns both fans and temps from a single helper round-trip.
    func readAll() -> (fans: [[String: Any]], temps: [[String: Any]])? {
        guard isHelperAvailable else { return nil }
        guard let res = sendCommand(["cmd": "readAll"]) else { return nil }
        let fans = res["fans"] as? [[String: Any]] ?? []
        let temps = res["temps"] as? [[String: Any]] ?? []
        return (fans: fans, temps: temps)
    }

    func setFanMode(_ mode: String, fanIndex: Int) -> Bool {
        guard isHelperAvailable else { return false }
        let res = sendCommand(["cmd": "setFanMode", "mode": mode, "fanIndex": fanIndex])
        return res?["success"] as? Bool == true
    }

    func setFanRPM(_ rpm: Double, fanIndex: Int) -> Bool {
        guard isHelperAvailable else { return false }
        let res = sendCommand(["cmd": "setFanRPM", "rpm": rpm, "fanIndex": fanIndex])
        return res?["success"] as? Bool == true
    }

    func disconnect() {
        lock.lock()
        defer { lock.unlock() }
        if fd >= 0 {
            close(fd)
            fd = -1
        }
    }

    // MARK: - Transport

    private func sendCommand(_ cmd: [String: Any]) -> [String: Any]? {
        lock.lock()
        defer { lock.unlock() }

        guard ensureConnected() else { return nil }

        guard let request = try? JSONSerialization.data(withJSONObject: cmd) else { return nil }

        var header = UInt32(request.count).bigEndian
        var payload = Data()
        payload.append(contentsOf: withUnsafeBytes(of: &header) { Array($0) })
        payload.append(request)

        let sent = payload.withUnsafeBytes { ptr in
            send(fd, ptr.baseAddress, payload.count, 0)
        }
        guard sent == payload.count else {
            disconnectLocked()
            return nil
        }

        guard let respHeader = readN(fd: fd, n: 4), respHeader.count == 4 else {
            disconnectLocked()
            return nil
        }
        let length = respHeader.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        guard length > 0, length < 1024 * 1024,
              let respBody = readN(fd: fd, n: Int(length)),
              respBody.count == Int(length),
              let json = try? JSONSerialization.jsonObject(with: respBody),
              let dict = json as? [String: Any] else {
            disconnectLocked()
            return nil
        }
        return dict
    }

    private func ensureConnected() -> Bool {
        if fd >= 0 { return true }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let path = SMCHelperClient.socketPath
        strncpy(&addr.sun_path.0, path, MemoryLayout.size(ofValue: addr.sun_path) - 1)

        let newFd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard newFd >= 0 else { return false }

        let size = socklen_t(MemoryLayout<sockaddr_un>.stride)
        let result = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(newFd, $0, size)
            }
        }
        guard result == 0 else {
            close(newFd)
            return false
        }

        // Short timeout so a dead helper fails fast instead of blocking the UI.
        var tv = timeval(tv_sec: 1, tv_usec: 0)
        setsockopt(newFd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(newFd, SOL_SOCKET, SO_SNDTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

        fd = newFd
        return true
    }

    private func disconnectLocked() {
        if fd >= 0 {
            close(fd)
            fd = -1
        }
    }

    private func readN(fd: Int32, n: Int) -> Data? {
        var buffer = Data()
        buffer.reserveCapacity(n)
        while buffer.count < n {
            var chunk = [UInt8](repeating: 0, count: n - buffer.count)
            let rc = recv(fd, &chunk, chunk.count, 0)
            if rc <= 0 { return nil }
            buffer.append(contentsOf: chunk.prefix(Int(rc)))
        }
        return buffer
    }
}
