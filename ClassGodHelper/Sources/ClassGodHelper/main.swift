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
    private let lock = NSLock()
    private let discoveryLock = NSLock()
    private var cachedSMCKeys: [(key: String, type: String)]?

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
        lock.lock()
        defer { lock.unlock() }
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
        lock.lock()
        defer { lock.unlock() }
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

    // MARK: - SMC Key Enumeration
    
    /// Enumerates all available SMC keys by reading #KEY and iterating indices.
    /// Returns a map of key 4CC -> type string for keys matching the given prefixes.
    private func discoverSMCKeys() -> [(key: String, type: String)] {
        var results: [(key: String, type: String)] = []
        let keyCountBytes = readBytes(key: "#KEY")
        guard let keyCountBytes, keyCountBytes.count >= 4 else {
            print("[Helper] enumerateSMCKeys: #KEY read failed or too short (count=\(keyCountBytes?.count ?? 0))")
            return results
        }
        let count = Int(UInt32(keyCountBytes[0]) << 24 | UInt32(keyCountBytes[1]) << 16 |
                        UInt32(keyCountBytes[2]) << 8 | UInt32(keyCountBytes[3]))
        print("[Helper] enumerateSMCKeys: #KEY reports \(count) total keys")
        guard count > 0 && count < 10000 else {
            print("[Helper] enumerateSMCKeys: invalid key count \(count)")
            return results
        }
        
        for i in 0..<count {
            guard let indexedKey = readKey(at: i) else { continue }
            let key4cc = indexedKey.key
            let type = indexedKey.type
            let typeLower = type.lowercased()
            guard key4cc.hasPrefix("T") || key4cc.hasPrefix("F") else { continue }
            let validTypes = Set(["sp78", "sp79", "sp7a", "sp5a", "si8c", "fpe2", "ui8 ", "ui16", "ui32", "flag"])
            guard validTypes.contains(typeLower) else { continue }
            results.append((key: key4cc, type: typeLower))
        }
        return results
    }

    private func readKey(at index: Int) -> (key: String, type: String)? {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return nil }
        var input = [UInt8](repeating: 0, count: 56)
        var output = [UInt8](repeating: 0, count: 56)
        input[0] = UInt8((index >> 24) & 0xFF)
        input[1] = UInt8((index >> 16) & 0xFF)
        input[2] = UInt8((index >> 8) & 0xFF)
        input[3] = UInt8(index & 0xFF)
        input[16] = 8
        guard smcCall(input: &input, output: &output) == KERN_SUCCESS, output[14] == 0 else { return nil }
        let key = String(bytes: output[0..<4], encoding: .ascii) ?? ""
        let type = String(bytes: output[4..<8], encoding: .ascii) ?? ""
        return (key, type)
    }

    func enumerateSMCKeys(matchingPrefixes prefixes: [String] = ["T", "F"]) -> [(key: String, type: String)] {
        discoveryLock.lock()
        defer { discoveryLock.unlock() }
        if cachedSMCKeys == nil {
            cachedSMCKeys = discoverSMCKeys()
        }
        return cachedSMCKeys?.filter { entry in
            prefixes.contains { entry.key.hasPrefix($0) }
        } ?? []
    }

    func rescan() {
        discoveryLock.lock()
        cachedSMCKeys = nil
        discoveryLock.unlock()

        lock.lock()
        if conn != 0 {
            IOServiceClose(conn)
            conn = 0
        }
        isConnected = false
        connect()
        lock.unlock()

        refreshPowerMetricsFallback(using: self)
    }

    func readFans() -> [[String: Any]] {
        var indexes = Set<Int>()

        if let numBytes = readBytes(key: "FNum"), numBytes.count >= 1, numBytes[0] > 0 {
            let count = min(Int(numBytes[0]), 16)
            indexes.formUnion(0..<count)
        }

        for entry in enumerateSMCKeys(matchingPrefixes: ["F"]) {
            if let fanKey = FanSMCKey(entry.key) {
                indexes.insert(fanKey.index)
            }
        }

        return indexes.sorted().compactMap { index in
            guard let actualKey = FanSMCKey.actualRPMKey(for: index),
                  let fanKey = FanSMCKey(actualKey),
                  let actualBytes = readBytes(key: actualKey) else { return nil }
            var fan: [String: Any] = [
                "id": index,
                "name": fanName(index),
                "actualRPM": decodeFPE2(actualBytes)
            ]
            if let key = fanKey.key(suffix: "Mn"), let bytes = readBytes(key: key) {
                fan["minimumRPM"] = decodeFPE2(bytes)
            }
            if let key = fanKey.key(suffix: "Mx"), let bytes = readBytes(key: key) {
                fan["maximumRPM"] = decodeFPE2(bytes)
            }
            if let key = fanKey.key(suffix: "Tg"), let bytes = readBytes(key: key) {
                fan["targetRPM"] = decodeFPE2(bytes)
            }
            return fan
        }
    }

    func readTemps() -> [[String: Any]] {
        let keys: [(String, String, Double)] = [
            // Intel & generic
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
            ("Battery 2", "TB1T", 60),
            ("Battery 3", "TB2T", 60),
            ("Memory", "Tm0P", 80),
            ("Palm Rest", "Ts0P", 50),
            ("Trackpad", "Tp0P", 50),
            // Apple Silicon CPU clusters
            ("CPU Cluster 0", "Tp09", 100),
            ("CPU Cluster 1", "Tp0T", 100),
            ("CPU Cluster 2", "Tp01", 100),
            ("CPU Cluster 3", "Tp05", 100),
            ("CPU Cluster 4", "Tp0D", 100),
            ("CPU Cluster 5", "Tp0X", 100),
            ("CPU Cluster 6", "Tp0b", 100),
            ("CPU Performance", "Tp0C", 100),
            ("CPU Efficiency", "Tp0E", 100),
            // Apple Silicon GPU
            ("GPU", "Tg05", 100),
            ("GPU 2", "Tg0D", 100),
            ("GPU 3", "Tg0F", 100),
            ("GPU 4", "Tg0H", 100),
            // Apple Silicon misc
            ("SOC", "Ts0S", 100),
            ("Airflow Top", "TA2P", 80),
            ("SSD", "Ts2S", 80),
        ]
        var out: [[String: Any]] = []
        var seenKeys = Set<String>()
        for (name, key, max) in keys {
            guard let b = readBytes(key: key), b.count >= 2 else { continue }
            let v = decodeSP78(b)
            if v > -50 && v < 150 {
                out.append(["name": name, "key": key, "value": v, "maxValue": max])
                seenKeys.insert(key)
            }
        }

        // Enumerate dynamic T* keys as supplement
        let dynamicTemps = enumerateSMCKeys(matchingPrefixes: ["T"])
        for entry in dynamicTemps {
            let key = entry.key
            guard key.count == 4, key.hasPrefix("T"), !seenKeys.contains(key) else { continue }
            if let b = readBytes(key: key) {
                let v = decodeTemperature(b, type: entry.type)
                if v > -50 && v < 150 {
                    out.append(["name": key, "key": key, "value": v, "maxValue": 100])
                }
            }
        }
        return out
    }

    private func decodeTemperature(_ bytes: [UInt8], type: String) -> Double {
        guard bytes.count >= 2 else { return 0 }
        if type.hasPrefix("sp"), let fractionBits = Int(String(type.suffix(1)), radix: 16) {
            let raw = Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1]))
            return Double(raw) / pow(2, Double(fractionBits))
        }
        return decodeSP78(bytes)
    }

    func readAll() -> [String: Any] {
        let readings = HardwareReadings.merge(
            smcFans: readFans(),
            smcTemps: readTemps(),
            powerMetricsFans: PowerMetricsSampler.shared.fans,
            powerMetricsTemps: PowerMetricsSampler.shared.temps,
            hidTemps: HIDTemperatureReader.shared.readTemperatures()
        )
        return ["fans": readings.fans, "temps": readings.temps, "source": readings.source]
    }

    func setFanMode(_ mode: String, fanIndex: Int) -> Bool {
        guard let actualKey = FanSMCKey.actualRPMKey(for: fanIndex),
              let fanKey = FanSMCKey(actualKey),
              let targetKey = fanKey.key(suffix: "Tg") else { return false }
        switch mode {
        case "system":
            return writeBytes(key: targetKey, bytes: [0, 0])
        case "max":
            guard let maxKey = fanKey.key(suffix: "Mx"),
                  let bytes = readBytes(key: maxKey), bytes.count >= 2 else { return false }
            return writeBytes(key: targetKey, bytes: Array(bytes.prefix(2)))
        case "autoMax", "manual", "custom":
            return true
        default:
            return false
        }
    }

    func setFanRPM(_ rpm: Double, fanIndex: Int) -> Bool {
        guard let actualKey = FanSMCKey.actualRPMKey(for: fanIndex),
              let targetKey = FanSMCKey(actualKey)?.key(suffix: "Tg") else { return false }
        return writeBytes(key: targetKey, bytes: encodeFPE2(rpm))
    }

    private func fanName(_ index: Int) -> String {
        switch index {
        case 0: return "Left Fan"
        case 1: return "Right Fan"
        default: return "Fan \(index + 1)"
        }
    }
}

// MARK: - powermetrics fallback

/// Periodically samples `powermetrics --samplers smc` so that machines whose
/// SMC user-client no longer exposes live keys (e.g. Apple Silicon M5) can
/// still report die temperatures and fan RPM.
final class PowerMetricsSampler {
    static let shared = PowerMetricsSampler()
    private let queue = DispatchQueue(label: "com.hanazar.classgod.powermetrics", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var _latest: (temps: [[String: Any]], fans: [[String: Any]], error: String?) = ([], [], nil)
    private let accessQueue = DispatchQueue(label: "com.hanazar.classgod.powermetrics.access")
    private var isSamplerUnsupported = false
    private var needsFans = false
    private var needsTemps = false

    private init() {}

    var temps: [[String: Any]] {
        var value: [[String: Any]] = []
        accessQueue.sync { value = _latest.temps }
        return value
    }
    var fans: [[String: Any]] {
        var value: [[String: Any]] = []
        accessQueue.sync { value = _latest.fans }
        return value
    }
    var error: String? {
        var value: String?
        accessQueue.sync { value = _latest.error }
        return value
    }

    func start(interval: TimeInterval = 0.5, needsFans: Bool, needsTemps: Bool) {
        stop()
        accessQueue.sync {
            _latest = ([], [], nil)
        }
        guard needsFans || needsTemps else { return }
        guard !isSamplerUnsupported else {
            print("[Helper] PowerMetricsSampler skipped: SMC sampler is unsupported on this machine")
            return
        }
        self.needsFans = needsFans
        self.needsTemps = needsTemps
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(Int(interval * 1000)))
        timer.setEventHandler { [weak self] in
            self?.sample()
        }
        timer.resume()
        self.timer = timer
        print("[Helper] PowerMetricsSampler started (interval \(interval)s)")
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func sample() {
        let result = Self.runOnce()
        if let error = result.error,
           error.lowercased().contains("unrecognized sampler") {
            print("[Helper] PowerMetricsSampler: SMC sampler unsupported, stopping")
            self.isSamplerUnsupported = true
            self.stop()
        }
        if result.error == nil,
           !PowerMetricsSamplingPolicy.shouldContinue(
               needsFans: needsFans,
               needsTemps: needsTemps,
               sampledFans: result.fans.count,
               sampledTemps: result.temps.count
           ) {
            print("[Helper] PowerMetricsSampler found no required fallback data, stopping")
            accessQueue.async {
                self._latest = ([], [], nil)
            }
            stop()
            return
        }
        accessQueue.async {
            self._latest = result
        }
    }

    private static func runOnce() -> (temps: [[String: Any]], fans: [[String: Any]], error: String?) {
        let task = Process()
        task.launchPath = "/usr/bin/powermetrics"
        task.arguments = ["-n", "1", "-i", "500", "--samplers", "smc"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe  // powermetrics writes errors to stderr

        do {
            try task.run()
        } catch {
            return ([], [], "powermetrics launch failed: \(error.localizedDescription)")
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        guard task.terminationStatus == 0 else {
            let err = String(data: data, encoding: .utf8) ?? ""
            return ([], [], "powermetrics exited \(task.terminationStatus): \(err.prefix(200))")
        }

        guard let output = String(data: data, encoding: .utf8), !output.isEmpty else {
            return ([], [], "powermetrics produced no output")
        }

        if output.lowercased().contains("unrecognized sampler") {
            return ([], [], "powermetrics SMC sampler unavailable on this machine")
        }

        var temps: [[String: Any]] = []
        var fans: [[String: Any]] = []

        // CPU die temperature
        if let cpu = matchDouble(in: output, pattern: #"CPU die temperature:\s*([\d.]+)\s*C"#) {
            temps.append(["name": "CPU Die", "key": "PMCPU", "value": cpu, "maxValue": 100])
        }
        // GPU die temperature
        if let gpu = matchDouble(in: output, pattern: #"GPU die temperature:\s*([\d.]+)\s*C"#) {
            temps.append(["name": "GPU Die", "key": "PMGPU", "value": gpu, "maxValue": 100])
        }
        // IO die temperature (present on some Apple Silicon machines)
        if let io = matchDouble(in: output, pattern: #"IO die temperature:\s*([\d.]+)\s*C"#) {
            temps.append(["name": "IO Die", "key": "PMIO", "value": io, "maxValue": 100])
        }

        // Fans: there may be multiple "Fan: <rpm> rpm" lines
        let fanRegex = try? NSRegularExpression(pattern: #"Fan:\s*([\d.]+)\s*rpm"#, options: .caseInsensitive)
        let nsRange = NSRange(output.startIndex..., in: output)
        let matches = fanRegex?.matches(in: output, options: [], range: nsRange) ?? []
        for (idx, match) in matches.enumerated() {
            guard let range = Range(match.range(at: 1), in: output) else { continue }
            if let rpm = Double(output[range]) {
                fans.append(["id": idx, "name": "Fan \(idx + 1)", "actualRPM": rpm, "minimumRPM": 0, "maximumRPM": 8000])
            }
        }

        if temps.isEmpty && fans.isEmpty {
            return ([], [], "powermetrics output contained no parseable SMC data")
        }

        return (temps, fans, nil)
    }

    private static func matchDouble(in text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let r = Range(match.range(at: 1), in: text),
              let v = Double(text[r]) else { return nil }
        return v
    }

    private static func matchInt(in text: String, pattern: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let r = Range(match.range(at: 1), in: text),
              let v = Int(text[r]) else { return nil }
        return v
    }
}

// MARK: - HID temperature reader (Apple Silicon PMU sensors)

/// Reads live temperature events from AppleARMPMUTempSensor / AppleEmbeddedNVMeTemperatureSensor
/// services via the private IOHIDEventSystemClient API. This is the most reliable way to get
/// real die temperatures on modern Apple Silicon (M3/M4/M5) where SMC keys are no longer exposed.
final class HIDTemperatureReader {
    static let shared = HIDTemperatureReader()

    private typealias ClientRef = OpaquePointer
    private typealias ServiceRef = OpaquePointer
    private typealias EventRef = OpaquePointer

    private typealias CreateFunc = @convention(c) (CFAllocator?) -> ClientRef?
    private typealias SetMatchingFunc = @convention(c) (ClientRef?, CFDictionary?) -> Void
    private typealias CopyServicesFunc = @convention(c) (ClientRef?) -> Unmanaged<CFArray>?
    private typealias CopyPropertyFunc = @convention(c) (ServiceRef?, CFString?) -> CFTypeRef?
    private typealias CopyEventFunc = @convention(c) (ServiceRef?, Int64, Int32, Int64) -> EventRef?
    private typealias GetFloatValueFunc = @convention(c) (EventRef?, UInt32) -> Double

    private let handle: UnsafeMutableRawPointer?
    private let client: ClientRef?
    private let copyServices: CopyServicesFunc?
    private let copyProperty: CopyPropertyFunc?
    private let copyEvent: CopyEventFunc?
    private let getFloatValue: GetFloatValueFunc?

    private let temperatureEventType: Int64 = 15
    private let temperatureField: UInt32 = 0xF0000

    private init() {
        guard let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) else {
            print("[HID] dlopen IOKit failed")
            self.handle = nil
            self.client = nil
            self.copyServices = nil
            self.copyProperty = nil
            self.copyEvent = nil
            self.getFloatValue = nil
            return
        }
        self.handle = handle

        guard let createSym = dlsym(handle, "IOHIDEventSystemClientCreate"),
              let setMatchingSym = dlsym(handle, "IOHIDEventSystemClientSetMatching"),
              let copyServicesSym = dlsym(handle, "IOHIDEventSystemClientCopyServices"),
              let copyPropertySym = dlsym(handle, "IOHIDServiceClientCopyProperty"),
              let copyEventSym = dlsym(handle, "IOHIDServiceClientCopyEvent"),
              let getFloatValueSym = dlsym(handle, "IOHIDEventGetFloatValue") else {
            print("[HID] dlsym failed")
            self.client = nil
            self.copyServices = nil
            self.copyProperty = nil
            self.copyEvent = nil
            self.getFloatValue = nil
            return
        }

        let create = unsafeBitCast(createSym, to: CreateFunc.self)
        let setMatching = unsafeBitCast(setMatchingSym, to: SetMatchingFunc.self)
        self.copyServices = unsafeBitCast(copyServicesSym, to: CopyServicesFunc.self)
        self.copyProperty = unsafeBitCast(copyPropertySym, to: CopyPropertyFunc.self)
        self.copyEvent = unsafeBitCast(copyEventSym, to: CopyEventFunc.self)
        self.getFloatValue = unsafeBitCast(getFloatValueSym, to: GetFloatValueFunc.self)

        guard let client = create(kCFAllocatorDefault) else {
            print("[HID] Could not create IOHIDEventSystemClient")
            self.client = nil
            return
        }

        let matching = [
            "PrimaryUsage": 5,
            "PrimaryUsagePage": 65280
        ] as CFDictionary
        setMatching(client, matching)
        self.client = client
        print("[HID] IOHIDEventSystemClient initialized")
    }

    deinit {
        // Swift manages Core Foundation objects via ARC; we only need to close the dlopen handle.
        if let handle = handle {
            dlclose(handle)
        }
    }

    func readTemperatures() -> [[String: Any]] {
        guard let client = client,
              let copyServices = copyServices,
              let copyProperty = copyProperty,
              let copyEvent = copyEvent,
              let getFloatValue = getFloatValue else { return [] }

        guard let servicesCF = copyServices(client) else { return [] }
        let cfarray = servicesCF.takeRetainedValue()
        let count = CFArrayGetCount(cfarray)

        // Group values by product name; some products have multiple instances.
        var grouped: [String: [Double]] = [:]

        for i in 0..<count {
            let raw = CFArrayGetValueAtIndex(cfarray, i)
            let service = unsafeBitCast(raw, to: ServiceRef.self)

            guard let productRef = copyProperty(service, "Product" as CFString),
                  CFGetTypeID(productRef) == CFStringGetTypeID(),
                  let product = productRef as? String else { continue }

            let event = copyEvent(service, temperatureEventType, 0, 0)
            guard let event = event else { continue }
            let value = getFloatValue(event, temperatureField)
            // tdev* sensors often return invalid negative placeholders (~-9200).
            guard value > -50 && value < 150 else { continue }

            grouped[product, default: []].append(value)
        }

        var results: [[String: Any]] = []
        for (product, values) in grouped.sorted(by: { $0.key < $1.key }) {
            let avg = values.reduce(0, +) / Double(values.count)
            let key = "HID_" + product.replacingOccurrences(of: " ", with: "_")
            results.append([
                "name": product,
                "key": key,
                "value": avg,
                "maxValue": 100
            ])
        }
        return results
    }
}

private func refreshPowerMetricsFallback(
    using smc: SMCHelper,
    fans discoveredFans: [[String: Any]]? = nil,
    smcTemps discoveredSMCTemps: [[String: Any]]? = nil,
    hidTemps discoveredHIDTemps: [[String: Any]]? = nil
) {
    let fans = discoveredFans ?? smc.readFans()
    let smcTemps = discoveredSMCTemps ?? smc.readTemps()
    let hidTemps = discoveredHIDTemps ?? HIDTemperatureReader.shared.readTemperatures()
    PowerMetricsSampler.shared.start(
        interval: 0.5,
        needsFans: fans.isEmpty,
        needsTemps: smcTemps.isEmpty && hidTemps.isEmpty
    )
}

// MARK: - Socket server

/// Kill any other ClassGodHelper processes so a freshly-built helper can take
/// over the socket even if an older instance is still running.
private func cleanupStaleHelpers() {
    let myPID = getpid()
    let task = Process()
    task.launchPath = "/bin/ps"
    task.arguments = ["-eo", "pid,comm"]
    let pipe = Pipe()
    task.standardOutput = pipe
    do {
        try task.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        guard let output = String(data: data, encoding: .utf8) else { return }
        for line in output.split(separator: "\n") {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 2 else { continue }
            let command = String(parts[1])
            guard command == "ClassGodHelper" || command.hasSuffix("/ClassGodHelper") else { continue }
            guard let pid = pid_t(parts[0]), pid != myPID else { continue }
            print("[Helper] Terminating stale helper pid=\(pid)")
            kill(pid, SIGTERM)
        }
        // Give the old helper a moment to release the socket.
        Thread.sleep(forTimeInterval: 0.5)
    } catch {
        print("[Helper] cleanupStaleHelpers failed: \(error)")
    }
}

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

    // Allow any user to connect to the socket (not just root)
    chmod(path, 0o666)

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
    _ = sendAll(fd: fd, data: payload)
}

private func sendAll(fd: Int32, data: Data) -> Bool {
    data.withUnsafeBytes { bytes in
        guard let baseAddress = bytes.baseAddress else { return false }
        var offset = 0
        while offset < bytes.count {
            let sent = send(fd, baseAddress.advanced(by: offset), bytes.count - offset, 0)
            if sent < 0, errno == EINTR { continue }
            guard sent > 0 else { return false }
            offset += sent
        }
        return true
    }
}

private func handleClient(fd: Int32) {
    defer { close(fd) }

    var noSigPipe: Int32 = 1
    setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int32>.size))

    // Authenticate peer — fail closed if credentials cannot be retrieved.
    var peerUID: uid_t = 0, peerGID: gid_t = 0
    guard getpeereid(fd, &peerUID, &peerGID) == 0 else {
        print("[Helper] getpeereid failed; rejecting connection")
        sendJSON(fd: fd, ["success": false, "error": "peer authentication failed"])
        return
    }
    guard let allowed = allowedPeerUID, peerUID == allowed else {
        print("[Helper] Rejected peer uid=\(peerUID), allowed=\(allowedPeerUID.map(String.init) ?? "unset")")
        sendJSON(fd: fd, ["success": false, "error": "unauthorized peer uid"])
        return
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
        case "readAll":
            let all = smc.readAll()
            sendJSON(fd: fd, ["success": true, "fans": all["fans"] ?? [], "temps": all["temps"] ?? []])
        case "rescan":
            smc.rescan()
            sendJSON(fd: fd, ["success": true])
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

guard let peerUID = HelperPeerPolicy.allowedUID(
    arguments: CommandLine.arguments,
    environment: ProcessInfo.processInfo.environment
) else {
    print("[Helper] Missing or invalid allowed peer UID; refusing to start")
    exit(1)
}
allowedPeerUID = peerUID
print("[Helper] Allowed peer UID: \(peerUID)")

// Clean up stale helpers first, before doing any expensive work, so we can
// take over the socket as soon as possible.
cleanupStaleHelpers()

// Pre-flight sensor discovery so user can see what this machine exposes.
let smc = SMCHelper.shared
let discoveredTemps = smc.readTemps()
let discoveredFans = smc.readFans()
print("[Helper] Discovered \(discoveredTemps.count) SMC temperature sensors, \(discoveredFans.count) fans")
for t in discoveredTemps.prefix(10) {
    print("[Helper]   SMC Temp: \(t["name"] ?? "?") [\(t["key"] ?? "?")] = \(t["value"] ?? 0)")
}
if discoveredTemps.count > 10 {
    print("[Helper]   ... and \(discoveredTemps.count - 10) more")
}

// Probe HID temperature sensors (Apple Silicon PMU/NVMe).
let hidTemps = HIDTemperatureReader.shared.readTemperatures()
print("[Helper] Discovered \(hidTemps.count) HID temperature sensors")
for t in hidTemps.prefix(15) {
    print("[Helper]   HID Temp: \(t["name"] ?? "?") = \(t["value"] ?? 0)")
}
if hidTemps.count > 15 {
    print("[Helper]   ... and \(hidTemps.count - 15) more")
}

// Start powermetrics sampler in parallel. It runs independent of SMC reads
// and provides a fallback data path on modern Apple Silicon.
refreshPowerMetricsFallback(
    using: smc,
    fans: discoveredFans,
    smcTemps: discoveredTemps,
    hidTemps: hidTemps
)

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
