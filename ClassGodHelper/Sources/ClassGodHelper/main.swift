//
//  ClassGodHelper
//
//  Privileged helper tool for reading/writing SMC fan & temperature data
//  on Apple Silicon Macs where the main app lacks direct access.
//
//  Run as root, e.g.:
//    sudo /path/to/ClassGodHelper
//
//  Listens on a Unix domain socket and speaks length-prefixed JSON.
//

import Foundation
import IOKit

private let SOCKET_PATH = "/tmp/com.hanazar.classgod.helper.sock"
private let KERNEL_INDEX_SMC: UInt32 = 2
private var listen_fd: Int32 = -1
private var allowedPeerUID: uid_t?

// MARK: - SMC primitives

final class SMCHelper {
    static let shared = SMCHelper()
    private var conn: io_connect_t = 0
    private var isConnected = false

    private init() {
        connect()
    }

    deinit {
        if conn != 0 {
            IOServiceClose(conn)
        }
    }

    private func connect() {
        var service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        if service == 0 {
            service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMCKeysEndpoint"))
        }
        guard service != 0 else {
            print("[Helper] No SMC service found")
            return
        }
        defer { IOObjectRelease(service) }

        var result = IOServiceOpen(service, mach_task_self_, 0, &conn)
        if result != KERN_SUCCESS {
            result = IOServiceOpen(service, mach_task_self_, 1, &conn)
        }
        isConnected = (result == KERN_SUCCESS)
        if isConnected {
            print("[Helper] SMC connected")
        } else {
            print("[Helper] SMC open failed: \(result)")
        }
    }

    private func smcCall(input: inout [UInt8], output: inout [UInt8]) -> kern_return_t {
        let inputSize = input.count
        var outputSize = output.count
        return input.withUnsafeMutableBytes { inputPtr in
            output.withUnsafeMutableBytes { outputPtr in
                guard let iAddr = inputPtr.baseAddress, let oAddr = outputPtr.baseAddress else {
                    return KERN_INVALID_ADDRESS
                }
                return IOConnectCallStructMethod(conn, KERNEL_INDEX_SMC, iAddr, inputSize, oAddr, &outputSize)
            }
        }
    }

    func readBytes(key: String) -> [UInt8]? {
        guard isConnected, key.count == 4 else { return nil }
        let code = fourCC(key)
        var input = [UInt8](repeating: 0, count: 56)
        var output = [UInt8](repeating: 0, count: 56)
        input[0] = UInt8((code >> 24) & 0xFF)
        input[1] = UInt8((code >> 16) & 0xFF)
        input[2] = UInt8((code >> 8) & 0xFF)
        input[3] = UInt8(code & 0xFF)
        for cmd in [5, 6, 10] {
            input[16] = UInt8(cmd)
            let kr = smcCall(input: &input, output: &output)
            if kr == KERN_SUCCESS && output[14] == 0 {
                return Array(output[24..<56])
            }
        }
        return nil
    }

    func writeBytes(key: String, bytes: [UInt8]) -> Bool {
        guard isConnected, key.count == 4 else { return false }
        let code = fourCC(key)
        var input = [UInt8](repeating: 0, count: 56)
        var output = [UInt8](repeating: 0, count: 56)
        input[0] = UInt8((code >> 24) & 0xFF)
        input[1] = UInt8((code >> 16) & 0xFF)
        input[2] = UInt8((code >> 8) & 0xFF)
        input[3] = UInt8(code & 0xFF)
        for (i, b) in bytes.prefix(32).enumerated() {
            input[24 + i] = b
        }
        for cmd in [6, 7, 11] {
            input[16] = UInt8(cmd)
            let kr = smcCall(input: &input, output: &output)
            if kr == KERN_SUCCESS && output[14] == 0 {
                return true
            }
        }
        return false
    }

    private func fourCC(_ s: String) -> UInt32 {
        var r: UInt32 = 0
        let chars = Array(s.utf8)
        for i in 0..<min(4, chars.count) {
            r = (r << 8) | UInt32(chars[i])
        }
        return r
    }

    private func decodeSP78(_ bytes: [UInt8]) -> Double {
        guard bytes.count >= 2 else { return 0 }
        return Double(Int8(bitPattern: bytes[0])) + Double(bytes[1]) / 256.0
    }

    private func decodeFPE2(_ bytes: [UInt8]) -> Double {
        guard bytes.count >= 2 else { return 0 }
        return Double(UInt16(bytes[0]) * 256 + UInt16(bytes[1])) / 4.0
    }

    private func encodeFPE2(_ value: Double) -> [UInt8] {
        let raw = UInt32(max(0, value) * 4.0)
        return [UInt8((raw >> 8) & 0xFF), UInt8(raw & 0xFF)]
    }

    // MARK: - Higher-level API

    func readFans() -> [[String: Any]] {
        var out: [[String: Any]] = []
        guard let numBytes = readBytes(key: "FNum"), numBytes.count >= 1, numBytes[0] > 0 else { return out }
        let count = min(Int(numBytes[0]), 16)
        for i in 0..<count {
            var dict: [String: Any] = ["id": i, "name": fanName(i)]
            if let b = readBytes(key: "F\(i)Ac") { dict["actualRPM"] = decodeFPE2(b) }
            if let b = readBytes(key: "F\(i)Mn") { dict["minimumRPM"] = decodeFPE2(b) }
            if let b = readBytes(key: "F\(i)Mx") { dict["maximumRPM"] = decodeFPE2(b) }
            if let b = readBytes(key: "F\(i)Tg") { dict["targetRPM"] = decodeFPE2(b) }
            out.append(dict)
        }
        return out
    }

    func readTemps() -> [[String: Any]] {
        let keys: [(String, String, Double)] = [
            ("CPU Core", "TC0D", 100),
            ("CPU Proximity", "TC0P", 100),
            ("CPU Heatsink", "TC0H", 100),
            ("CPU Package", "TCAD", 100),
            ("GPU Core", "TG0D", 100),
            ("GPU Proximity", "TG0P", 100),
            ("GPU Heatsink", "TG0H", 100),
            ("Airflow Left", "TA0P", 80),
            ("Airflow Right", "TA1P", 80),
            ("Battery", "TB0T", 60),
            ("Memory", "Tm0P", 80),
            ("Palm Rest", "Ts0P", 50),
            ("Trackpad", "Tp0P", 50),
            ("CPU Performance", "Tp0C", 100),
            ("CPU Efficiency", "Tp0E", 100),
            ("GPU", "Tg05", 100),
            ("SOC", "Ts0S", 100),
            ("SSD", "Ts2S", 80),
        ]
        var out: [[String: Any]] = []
        for (name, key, max) in keys {
            guard let b = readBytes(key: key), b.count >= 2 else { continue }
            let v = decodeSP78(b)
            if v > -50 && v < 150 {
                out.append(["name": name, "key": key, "value": v, "maxValue": max])
            }
        }
        return out
    }

    func setFanMode(_ mode: String, fanIndex: Int) -> Bool {
        switch mode {
        case "system":
            return writeBytes(key: "F\(fanIndex)Tg", bytes: [0, 0])
        case "max":
            guard let b = readBytes(key: "F\(fanIndex)Mx"), b.count >= 2 else { return false }
            return writeBytes(key: "F\(fanIndex)Tg", bytes: Array(b.prefix(2)))
        case "autoMax", "manual", "custom":
            return true
        default:
            return false
        }
    }

    func setFanRPM(_ rpm: Double, fanIndex: Int) -> Bool {
        return writeBytes(key: "F\(fanIndex)Tg", bytes: encodeFPE2(rpm))
    }

    private func fanName(_ index: Int) -> String {
        switch index {
        case 0: return "Left Fan"
        case 1: return "Right Fan"
        default: return "Fan \(index + 1)"
        }
    }
}

// MARK: - Socket server

private func setupSocket() -> Int32 {
    var addr = sockaddr_un()
    addr.sun_family = sa_family_t(AF_UNIX)
    let path = SOCKET_PATH
    strncpy(&addr.sun_path.0, path, MemoryLayout.size(ofValue: addr.sun_path) - 1)

    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    guard fd >= 0 else {
        print("[Helper] socket() failed")
        return -1
    }
    var on: Int32 = 1
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int32>.size))

    unlink(path)

    let size = socklen_t(MemoryLayout<sockaddr_un>.stride)
    let result = withUnsafePointer(to: &addr) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            bind(fd, $0, size)
        }
    }
    guard result == 0 else {
        print("[Helper] bind() failed: \(errno)")
        close(fd)
        return -1
    }

    guard listen(fd, 5) == 0 else {
        print("[Helper] listen() failed: \(errno)")
        close(fd)
        return -1
    }

    print("[Helper] Listening on \(path)")
    return fd
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

private func sendJSON(fd: Int32, _ obj: [String: Any]) {
    guard let data = try? JSONSerialization.data(withJSONObject: obj, options: []) else { return }
    var header = UInt32(data.count).bigEndian
    var payload = Data()
    payload.append(contentsOf: withUnsafeBytes(of: &header) { Array($0) })
    payload.append(data)
    payload.withUnsafeBytes { ptr in
        _ = send(fd, ptr.baseAddress, payload.count, 0)
    }
}

private func handleClient(fd: Int32) {
    defer { close(fd) }

    // Authenticate peer
    var peerUID: uid_t = 0, peerGID: gid_t = 0
    if getpeereid(fd, &peerUID, &peerGID) == 0 {
        if let allowed = allowedPeerUID, peerUID != allowed {
            print("[Helper] Rejected peer uid=\(peerUID), allowed=\(allowed)")
            sendJSON(fd: fd, ["success": false, "error": "unauthorized peer uid"])
            return
        }
    }

    while true {
        guard let header = readN(fd: fd, n: 4),
              header.count == 4 else { break }
        let length = header.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        guard length > 0, length < 1024 * 1024,
              let payload = readN(fd: fd, n: Int(length)),
              payload.count == Int(length),
              let json = try? JSONSerialization.jsonObject(with: payload),
              let req = json as? [String: Any],
              let cmd = req["cmd"] as? String else {
            sendJSON(fd: fd, ["success": false, "error": "invalid request"])
            continue
        }

        let smc = SMCHelper.shared
        switch cmd {
        case "readFans":
            sendJSON(fd: fd, ["success": true, "data": smc.readFans()])
        case "readTemps":
            sendJSON(fd: fd, ["success": true, "data": smc.readTemps()])
        case "setFanMode":
            let mode = req["mode"] as? String ?? ""
            let idx = req["fanIndex"] as? Int ?? 0
            sendJSON(fd: fd, ["success": smc.setFanMode(mode, fanIndex: idx)])
        case "setFanRPM":
            let rpm = req["rpm"] as? Double ?? 0
            let idx = req["fanIndex"] as? Int ?? 0
            sendJSON(fd: fd, ["success": smc.setFanRPM(rpm, fanIndex: idx)])
        default:
            sendJSON(fd: fd, ["success": false, "error": "unknown cmd: \(cmd)"])
        }
    }
}

private func cleanupSocket() {
    unlink(SOCKET_PATH)
    if listen_fd >= 0 { close(listen_fd) }
}

private func signalHandler(_ sig: Int32) {
    cleanupSocket()
    exit(0)
}

// MARK: - Entry

signal(SIGINT) { _ in signalHandler(SIGINT) }
signal(SIGTERM) { _ in signalHandler(SIGTERM) }

// Determine allowed peer UID. If run via sudo, restrict to the original user.
if let sudoUIDString = getenv("SUDO_UID"),
   let sudoUIDStr = String(cString: sudoUIDString).trimmingCharacters(in: .whitespacesAndNewlines) as String?,
   let sudoUID = uid_t(sudoUIDStr) {
    allowedPeerUID = sudoUID
    print("[Helper] Allowed peer UID (SUDO_UID): \(sudoUID)")
} else {
    print("[Helper] No SUDO_UID; allowing any peer (not recommended for production)")
}

listen_fd = setupSocket()
guard listen_fd >= 0 else {
    exit(1)
}

DispatchQueue.global(qos: .background).async {
    while true {
        let client = accept(listen_fd, nil, nil)
        guard client >= 0 else { continue }
        DispatchQueue.global(qos: .utility).async {
            handleClient(fd: client)
        }
    }
}

// Keep running
dispatchMain()
