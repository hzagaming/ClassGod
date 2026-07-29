//
//  SMCService.swift
//  ClassGod
//

import Foundation
import IOKit

// MARK: - Data Models

nonisolated struct TemperatureSensor: Identifiable, Equatable {
    let name: String
    let key: String
    var value: Double
    var maxValue: Double = 100
    var isEstimated: Bool = false

    var id: String { key }
}

nonisolated enum FanAvailability: Equatable {
    case controllable
    case readOnly
    case detected
}

nonisolated struct FanInfo: Identifiable, Equatable {
    let id: Int
    var name: String
    var actualRPM: Double = 0
    var minimumRPM: Double = 0
    var maximumRPM: Double = 0
    var targetRPM: Double = 0
    var hasLiveRPM: Bool = false
    var isControllable: Bool = false

    var hasPlausibleRPMRange: Bool {
        actualRPM >= 0 && actualRPM <= 20_000
            && minimumRPM >= 0 && maximumRPM > minimumRPM && maximumRPM <= 20_000
    }

    var hasPlausibleLiveRPM: Bool {
        hasLiveRPM && actualRPM >= 0 && actualRPM <= 20_000
    }

    var canControl: Bool {
        hasLiveRPM && isControllable && hasPlausibleRPMRange
    }

    var availability: FanAvailability {
        if canControl { return .controllable }
        return hasPlausibleLiveRPM ? .readOnly : .detected
    }
}

nonisolated enum FanControlRouting {
    static func position(of fanID: Int, in fans: [FanInfo]) -> Int? {
        fans.firstIndex { $0.id == fanID }
    }

    static func controllableIDs(in fans: [FanInfo]) -> [Int] {
        fans.filter(\.canControl).map(\.id)
    }

    static func averageLiveRPM(in fans: [FanInfo]) -> Double? {
        let liveFans = fans.filter(\.hasPlausibleLiveRPM)
        guard !liveFans.isEmpty else { return nil }
        return liveFans.map(\.actualRPM).reduce(0, +) / Double(liveFans.count)
    }

    @MainActor
    static func targetIDs(for target: FanRuleTarget, in fans: [FanInfo]) -> [Int] {
        let controllable = fans.filter(\.canControl)
        switch target {
        case .allFans: return controllable.map(\.id)
        case .leftFan: return controllable.filter { $0.id == 0 }.map(\.id)
        case .rightFan: return controllable.filter { $0.id == 1 }.map(\.id)
        }
    }
}

nonisolated enum FanRecognition {
    private static func isGenericName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == "Detected" || trimmed.hasPrefix("Fan ")
    }

    static func supportsSMCRPMDataType(_ type: String) -> Bool {
        type.lowercased() == "fpe2"
    }

    static func decodeFanCount(_ bytes: [UInt8], dataType: String) -> Int? {
        let expectedCount: Int
        switch dataType.lowercased() {
        case "ui8 ": expectedCount = 1
        case "ui16": expectedCount = 2
        case "ui32": expectedCount = 4
        default: return nil
        }
        guard bytes.count >= expectedCount else { return nil }
        let value = bytes.prefix(expectedCount).reduce(0) { ($0 << 8) | Int($1) }
        return (1...16).contains(value) ? value : nil
    }

    static func needsSupplement(_ fans: [FanInfo]) -> Bool {
        fans.isEmpty || fans.contains { !$0.hasPlausibleLiveRPM || !$0.hasPlausibleRPMRange }
    }

    static func merge(primary: [FanInfo], supplementary: [FanInfo]) -> [FanInfo] {
        var merged: [Int: FanInfo] = [:]
        for candidate in primary + supplementary {
            guard var current = merged[candidate.id] else {
                merged[candidate.id] = candidate
                continue
            }

            if !current.hasPlausibleLiveRPM, candidate.hasPlausibleLiveRPM {
                current.actualRPM = candidate.actualRPM
                current.hasLiveRPM = true
            }
            if !current.hasPlausibleRPMRange, candidate.hasPlausibleRPMRange {
                current.minimumRPM = candidate.minimumRPM
                current.maximumRPM = candidate.maximumRPM
            } else {
                if current.minimumRPM <= 0, candidate.minimumRPM > 0 {
                    current.minimumRPM = candidate.minimumRPM
                }
                if current.maximumRPM <= current.minimumRPM,
                   candidate.maximumRPM > current.minimumRPM {
                    current.maximumRPM = candidate.maximumRPM
                }
            }
            if current.targetRPM <= 0, candidate.targetRPM > 0 {
                current.targetRPM = candidate.targetRPM
            }
            if current.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || (isGenericName(current.name) && !isGenericName(candidate.name)) {
                current.name = candidate.name
            }
            current.isControllable = current.isControllable || candidate.isControllable
            merged[candidate.id] = current
        }

        return merged.values.sorted { $0.id < $1.id }
    }
}

nonisolated enum IORegistrySensorReading {
    static func rpm(from value: Any?) -> Double? {
        numericValue(from: value).flatMap { (0...20_000).contains($0) ? $0 : nil }
    }

    static func temperature(from value: Any?) -> Double? {
        numericValue(from: value).flatMap { (1..<150).contains($0) ? $0 : nil }
    }

    private static func numericValue(from value: Any?) -> Double? {
        if let number = value as? NSNumber { return number.doubleValue }
        if let string = value as? String { return Double(string) }
        return nil
    }
}

nonisolated enum SMCReadingFormat {
    private static let temperatureTypes = Set(["sp78", "sp79", "sp7a", "sp5a", "si8c"])

    static func supportsTemperature(_ type: String) -> Bool {
        temperatureTypes.contains(type.lowercased())
    }
}

nonisolated enum FanControlMode: String, Codable, CaseIterable, Identifiable {
    case system = "system"
    case max = "max"
    case autoMax = "autoMax"
    case manual = "manual"
    case custom = "custom"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return String(localized: "fan.mode.system")
        case .max: return String(localized: "fan.mode.max")
        case .autoMax: return String(localized: "fan.mode.auto_max")
        case .manual: return String(localized: "fan.mode.manual")
        case .custom: return String(localized: "fan.mode.custom")
        }
    }
}

nonisolated enum TemperatureUnit: String, Codable, CaseIterable, Identifiable {
    case celsius = "celsius"
    case fahrenheit = "fahrenheit"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }

    func convert(_ celsius: Double) -> Double {
        switch self {
        case .celsius: return celsius
        case .fahrenheit: return celsius * 9.0 / 5.0 + 32.0
        }
    }

    func formatted(_ celsius: Double) -> String {
        let value = convert(celsius)
        switch self {
        case .celsius: return String(format: "%.0f°C", value)
        case .fahrenheit: return String(format: "%.0f°F", value)
        }
    }
}

// MARK: - SMC Service

nonisolated final class SMCService: @unchecked Sendable {
    static let shared = SMCService()

    private var conn: io_connect_t = 0
    private(set) var isConnected = false
    private(set) var isUsingIORegistryFallback = false
    private(set) var fanAccessReason: String?
    private var cachedDirectTemperatureKeys: [(key: String, type: String)]?
    private var cachedDirectFanControlCapabilities: [Int: Bool] = [:]
    private var previousCPUInfo: host_cpu_load_info? = nil

    // Short-term cache shared across readTemperatures/readFans consumers
    private var lastReadAll: (fans: [FanInfo], sensors: [TemperatureSensor])?
    private var lastReadAllTime: Date?
    private let readAllLock = NSLock()
    private var controlledFanIDs = Set<Int>()
    private let controlLock = NSLock()

    // Known sensor key mappings
    private let sensorKeys: [(name: String, key: String, max: Double)] = [
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

    let isAppleSilicon: Bool

    private init() {
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 256) { String(cString: $0) }
        }
        isAppleSilicon = machine == "arm64" || machine.hasPrefix("Apple")
        connect()
        updateFanAccessReason()
    }
    
    /// Re-scan hardware connections and clear caches. Call this when user wants to re-detect sensors/fans.
    func rescan() {
        readAllLock.lock()
        defer { readAllLock.unlock() }

        // Close existing connection
        if conn != 0 {
            IOServiceClose(conn)
            conn = 0
        }
        isConnected = false
        isUsingIORegistryFallback = false
        fanAccessReason = nil
        cachedDirectTemperatureKeys = nil
        cachedDirectFanControlCapabilities.removeAll()
        lastReadAll = nil
        lastReadAllTime = nil
        SMCHelperClient.shared.rescan()
        
        // Reconnect
        connect()
        updateFanAccessReason()
    }
    
    var isHelperAvailable: Bool {
        SMCHelperClient.shared.isHelperAvailable
    }

    private func updateFanAccessReason() {
        if isHelperAvailable {
            fanAccessReason = String(localized: "fan.access.helper_present")
            return
        }
        if isConnected {
            if isAppleSilicon {
                fanAccessReason = String(localized: "fan.access.apple_silicon_restricted")
            } else {
                fanAccessReason = String(localized: "fan.access.no_fans")
            }
        } else {
            if isAppleSilicon {
                fanAccessReason = String(localized: "fan.access.apple_silicon_restricted")
            } else {
                fanAccessReason = String(localized: "fan.access.smc_unavailable")
            }
        }
    }
    
    deinit {
        if conn != 0 {
            IOServiceClose(conn)
            conn = 0
        }
    }

    // MARK: - Connection

    private func connect() {
        // Try Intel-style AppleSMC first
        var service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        
        // If not found, try Apple Silicon AppleSMCKeysEndpoint
        if service == 0 {
            service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMCKeysEndpoint"))
        }
        
        guard service != 0 else {
            print("[SMCService] No SMC service found (AppleSMC or AppleSMCKeysEndpoint)")
            return
        }
        defer { IOObjectRelease(service) }
        
        // Try standard connection type first
        var result = IOServiceOpen(service, mach_task_self_, 0, &conn)
        if result != KERN_SUCCESS {
            // Some Apple Silicon systems may use a different connection type
            conn = 0
            result = IOServiceOpen(service, mach_task_self_, 1, &conn)
        }
        
        isConnected = (result == KERN_SUCCESS)
        if isConnected {
            print("[SMCService] SMC connected successfully")
        } else {
            print("[SMCService] Failed to open SMC connection: \(result)")
        }
    }

    // MARK: - Raw SMC Call

    private func smcCall(input: inout SMCKeyData, output: inout SMCKeyData) -> kern_return_t {
        var outputSize = MemoryLayout<SMCKeyData>.size
        return IOConnectCallStructMethod(
            conn,
            2,
            &input,
            MemoryLayout<SMCKeyData>.size,
            &output,
            &outputSize
        )
    }

    private func readSMCBytes(key: String) -> [UInt8]? {
        guard isConnected, key.count == 4 else { return nil }
        let keyCode = fourCC(key)
        guard let keyInfo = readSMCKeyInfo(code: keyCode) else { return nil }
        let size = Int(keyInfo.dataSize)
        guard (1...32).contains(size) else { return nil }

        var input = SMCKeyData()
        var output = SMCKeyData()
        input.key = keyCode
        input.keyInfo.dataSize = keyInfo.dataSize
        input.data8 = SMCCommand.readBytes.rawValue
        guard smcCall(input: &input, output: &output) == KERN_SUCCESS,
              output.result == 0 else { return nil }
        return Array(output.bytes.array.prefix(size))
    }

    private func readSMCKeyInfo(code: UInt32) -> SMCKeyInfo? {
        var input = SMCKeyData()
        var output = SMCKeyData()
        input.key = code
        input.data8 = SMCCommand.readKeyInfo.rawValue
        guard smcCall(input: &input, output: &output) == KERN_SUCCESS,
              output.result == 0 else { return nil }
        return output.keyInfo
    }
    
    /// Enumerates all SMC keys and returns temperature keys (type sp78/sp79/sp7a/sp5a/si8c)
    /// that are not already in the hardcoded list.
    private func enumerateSMCTemperatureKeys() -> [(key: String, type: String)] {
        if let cachedDirectTemperatureKeys { return cachedDirectTemperatureKeys }
        guard isConnected else { return [] }
        guard let keyCountBytes = readSMCBytes(key: "#KEY"), keyCountBytes.count >= 4 else { return [] }
        let count = Int(UInt32(keyCountBytes[0]) << 24 | UInt32(keyCountBytes[1]) << 16 |
                        UInt32(keyCountBytes[2]) << 8 | UInt32(keyCountBytes[3]))
        guard count > 0 && count < 10000 else { return [] }
        
        var results: [(key: String, type: String)] = []
        
        for i in 0..<count {
            var input = SMCKeyData()
            var output = SMCKeyData()
            input.data32 = UInt32(i)
            input.data8 = SMCCommand.readIndex.rawValue
            let kr = smcCall(input: &input, output: &output)
            guard kr == KERN_SUCCESS, output.result == 0,
                  let keyInfo = readSMCKeyInfo(code: output.key) else { continue }
            let key4cc = fourCCString(output.key)
            let type = fourCCString(keyInfo.dataType)
            let typeLower = type.lowercased()
            guard key4cc.hasPrefix("T"), SMCReadingFormat.supportsTemperature(typeLower) else { continue }
            results.append((key: key4cc, type: typeLower))
        }
        cachedDirectTemperatureKeys = results
        return results
    }

    private func writeSMCBytes(key: String, bytes: [UInt8]) -> Bool {
        guard isConnected, key.count == 4 else { return false }
        let keyCode = fourCC(key)
        guard let keyInfo = readSMCKeyInfo(code: keyCode),
              (1...32).contains(Int(keyInfo.dataSize)),
              bytes.count >= Int(keyInfo.dataSize) else { return false }

        var input = SMCKeyData()
        var output = SMCKeyData()
        input.key = keyCode
        input.keyInfo.dataSize = keyInfo.dataSize
        input.bytes = SMCBytes(Array(bytes.prefix(Int(keyInfo.dataSize))))
        input.data8 = SMCCommand.writeBytes.rawValue
        return smcCall(input: &input, output: &output) == KERN_SUCCESS && output.result == 0
    }

    private func fourCC(_ string: String) -> UInt32 {
        var result: UInt32 = 0
        let chars = Array(string.utf8)
        for i in 0..<min(4, chars.count) {
            result = (result << 8) | UInt32(chars[i])
        }
        return result
    }

    private func fourCCString(_ value: UInt32) -> String {
        String(bytes: [
            UInt8((value >> 24) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF),
        ], encoding: .ascii) ?? ""
    }

    // MARK: - Decoding

    private func decodeSP78(bytes: [UInt8]) -> Double {
        guard bytes.count >= 2 else { return 0 }
        let intPart = Int8(bitPattern: bytes[0])
        let fracPart = Double(bytes[1]) / 256.0
        return Double(intPart) + fracPart
    }

    private func decodeFPE2(bytes: [UInt8]) -> Double {
        guard bytes.count >= 2 else { return 0 }
        return Double(UInt16(bytes[0]) * 256 + UInt16(bytes[1])) / 4.0
    }

    private func encodeFPE2(value: Double) -> [UInt8] {
        let raw = UInt32(max(0, value) * 4.0)
        return [UInt8((raw >> 8) & 0xFF), UInt8(raw & 0xFF)]
    }

    // MARK: - Public API

    // MARK: - Public API

    private func temperaturesFromHelper(_ dicts: [[String: Any]]) -> [TemperatureSensor] {
        dicts.compactMap { dict in
            guard let name = dict["name"] as? String,
                  let key = dict["key"] as? String else { return nil }
            let value = dict["value"] as? Double ?? 0
            let max = dict["maxValue"] as? Double ?? 100
            return TemperatureSensor(name: name, key: key, value: value, maxValue: max)
        }
    }

    private func fansFromHelper(_ dicts: [[String: Any]]) -> [FanInfo] {
        dicts.compactMap { dict in
            guard let id = dict["id"] as? Int else { return nil }
            var info = FanInfo(id: id, name: (dict["name"] as? String) ?? fanName(for: id))
            if let v = dict["actualRPM"] as? Double { info.actualRPM = v }
            if let v = dict["minimumRPM"] as? Double { info.minimumRPM = v }
            if let v = dict["maximumRPM"] as? Double { info.maximumRPM = v }
            if let v = dict["targetRPM"] as? Double { info.targetRPM = v }
            info.hasLiveRPM = dict["hasLiveRPM"] as? Bool ?? (dict["actualRPM"] != nil)
            if let v = dict["isControllable"] as? Bool { info.isControllable = v }
            return info
        }
    }

    /// Reads both fans and temperatures in a single shot, with a 250 ms TTL cache
    /// so multiple UI surfaces can share the same snapshot without re-hitting SMC.
    func readAll() -> (fans: [FanInfo], sensors: [TemperatureSensor]) {
        readAllLock.lock()
        defer { readAllLock.unlock() }

        let now = Date()
        if let cached = lastReadAll,
           let cachedTime = lastReadAllTime,
           now.timeIntervalSince(cachedTime) < 0.25 {
            return cached
        }

        var sensors: [TemperatureSensor] = []
        var fans: [FanInfo] = []
        var helperResponded = false
        var helperReturnedNoData = false
        // 1. Privileged helper: one socket round-trip returns both fans and temps.
        if let all = SMCHelperClient.shared.readAll() {
            helperResponded = true
            fans = fansFromHelper(all.fans)
            sensors = temperaturesFromHelper(all.temps)
            if fans.isEmpty && sensors.isEmpty {
                helperReturnedNoData = true
                fanAccessReason = String(localized: "fan.access.helper_no_data")
            }
        }

        // 2. Direct SMC fallback (Intel Macs / unlocked Apple Silicon).
        // Supplement a partial Helper response instead of treating any sensor as complete coverage.
        if isConnected {
            var seenKeys = Set(sensors.map(\.key))
            for (name, key, max) in sensorKeys where !seenKeys.contains(key) {
                if let value = readDirectTemperature(key: key), value > 1 && value < 150 {
                    sensors.append(TemperatureSensor(name: name, key: key, value: value, maxValue: max))
                    seenKeys.insert(key)
                }
            }

            let dynamicTemps = enumerateSMCTemperatureKeys()
            for (key, type) in dynamicTemps where !seenKeys.contains(key) {
                if let bytes = readSMCBytes(key: key), bytes.count >= 2 {
                    let value = decodeTemperature(bytes: bytes, type: type)
                    if value > 1 && value < 150 {
                        sensors.append(TemperatureSensor(name: key, key: key, value: value, maxValue: 100))
                        seenKeys.insert(key)
                    }
                }
            }

            if FanRecognition.needsSupplement(fans) {
                fans = FanRecognition.merge(primary: fans, supplementary: readDirectSMCFans())
            }
        }

        if FanRecognition.needsSupplement(fans) {
            fans = FanRecognition.merge(primary: fans, supplementary: readIORegistryFans())
        }

        // 3. IORegistry temperature fallback (re-read each call so live values stay current)
        let ioRegistryTemps = readIORegistryTemperatures()
        let currentThermalBase = thermalStateBaseTemp()
        let refreshedIORegistry = ioRegistryTemps.map { sensor -> TemperatureSensor in
            guard sensor.isEstimated else { return sensor }
            var updated = sensor
            updated.value = currentThermalBase
            return updated
        }
        sensors.append(contentsOf: refreshedIORegistry)
        // Only report that we are in IORegistry fallback if no real hardware sensors
        // have been produced by helper/direct SMC/HID so far.
        // 4. HID temperature fallback (Apple Silicon PMU/NVMe sensors).
        // Uses the private IOHIDEventSystemClient API to read live temperature events
        // from AppleARMPMUTempSensor and AppleEmbeddedNVMeTemperatureSensor services.
        let hidTemps = hidReader.readTemperatures()
        if !hidTemps.isEmpty {
            // Drop only estimated PMU/NVMe placeholders for which HID now provides a
            // real value. This keeps placeholders visible if HID failed to discover
            // a specific sensor (e.g. NAND on some configs).
            sensors.removeAll { sensor in
                guard sensor.isEstimated else { return false }
                guard sensor.name.hasPrefix("PMU") || sensor.name.hasPrefix("NAND") || sensor.name.contains("gas gauge") else { return false }
                return hidTemps.contains { sensor.name.hasPrefix($0.name) || sensor.key == $0.key }
            }
            sensors.append(contentsOf: hidTemps)
        }
        isUsingIORegistryFallback = !sensors.contains { !$0.isEstimated }
            && !ioRegistryTemps.isEmpty

        // 5. ProcessInfo thermal state (official API, always available)
        let thermalStateTemps = readThermalStateTemperatures()
        if !thermalStateTemps.isEmpty {
            sensors.append(contentsOf: thermalStateTemps)
        }

        // 5. Final fallback: SystemMonitor estimates based on CPU load.
        // Always provide a CPU/GPU estimate if we don't have any real hardware readings
        // for those categories, so the UI isn't left with only coarse thermal-state sensors.
        let hasRealCPU = sensors.contains { !$0.isEstimated && ($0.name.contains("CPU") || $0.name.contains("Cluster")) }
        let hasRealGPU = sensors.contains { !$0.isEstimated && $0.name.contains("GPU") }
        let est = estimatedTemperatures()
        if !hasRealCPU, est.cpu > 0 {
            sensors.append(TemperatureSensor(name: "CPU Estimated", key: "CPU", value: est.cpu, maxValue: 100, isEstimated: true))
        }
        if !hasRealGPU, est.gpu > 0 {
            sensors.append(TemperatureSensor(name: "GPU Estimated", key: "GPU", value: est.gpu, maxValue: 100, isEstimated: true))
        }

        // 6. Deduplicate after every fallback so stable sensor IDs remain unique.
        var seenKeys = Set<String>()
        sensors = sensors.filter { seenKeys.insert($0.key).inserted }

        if fans.contains(where: { $0.availability == .controllable }) {
            fanAccessReason = nil
        } else if fans.contains(where: { $0.availability == .readOnly }) {
            fanAccessReason = String(localized: helperResponded
                ? "fan.access.hardware_read_only"
                : "fan.access.read_only")
        } else if !fans.isEmpty {
            fanAccessReason = String(localized: helperResponded
                ? "fan.access.helper_detected_no_rpm"
                : "fan.access.detected_no_rpm")
        } else if helperReturnedNoData {
            // Preserve the specific Helper diagnostic.
        } else if helperResponded {
            fanAccessReason = String(localized: "fan.access.no_fans")
        } else {
            // Preserve the specific Helper diagnostic; refresh every generic reason.
            updateFanAccessReason()
        }

        let result = (fans: fans, sensors: sensors.sorted { $0.name < $1.name })
        lastReadAll = result
        lastReadAllTime = now
        return result
    }

    func readTemperatures() -> [TemperatureSensor] {
        return readAll().sensors
    }

    func readFans() -> [FanInfo] {
        return readAll().fans
    }

    private func decodeTemperature(bytes: [UInt8], type: String) -> Double {
        guard bytes.count >= 2 else { return 0 }
        if type.hasPrefix("sp"), let fractionBits = Int(String(type.suffix(1)), radix: 16) {
            let raw = Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1]))
            return Double(raw) / pow(2, Double(fractionBits))
        }
        return decodeSP78(bytes: bytes)
    }

    private func fanSMCKey(index: Int, suffix: String) -> String? {
        guard (0...15).contains(index), suffix.utf8.count == 2 else { return nil }
        return "F\(String(index, radix: 16, uppercase: true))\(suffix)"
    }

    private func readDirectSMCFans() -> [FanInfo] {
        guard let keyInfo = readSMCKeyInfo(code: fourCC("FNum")),
              let countBytes = readSMCBytes(key: "FNum"),
              let fanCount = FanRecognition.decodeFanCount(
                countBytes,
                dataType: fourCCString(keyInfo.dataType)
              ) else { return [] }

        return (0..<min(fanCount, 16)).map { index in
            var info = FanInfo(id: index, name: fanName(for: index))
            if let key = fanSMCKey(index: index, suffix: "Ac"),
               let rpm = readDirectFanRPM(key: key) {
                info.actualRPM = rpm
                info.hasLiveRPM = true
            }
            if let key = fanSMCKey(index: index, suffix: "Mn"),
               let rpm = readDirectFanRPM(key: key) {
                info.minimumRPM = rpm
            }
            if let key = fanSMCKey(index: index, suffix: "Mx"),
               let rpm = readDirectFanRPM(key: key) {
                info.maximumRPM = rpm
            }
            if let key = fanSMCKey(index: index, suffix: "Tg"),
               let rpm = readDirectFanRPM(key: key) {
                info.targetRPM = rpm
            }
            info.isControllable = !isAppleSilicon && supportsDirectFanControl(fanIndex: index)
            return info
        }
    }

    private func readDirectFanRPM(key: String) -> Double? {
        guard let keyInfo = readSMCKeyInfo(code: fourCC(key)),
              FanRecognition.supportsSMCRPMDataType(fourCCString(keyInfo.dataType)),
              let bytes = readSMCBytes(key: key) else { return nil }
        let rpm = decodeFPE2(bytes: bytes)
        return (0...20_000).contains(rpm) ? rpm : nil
    }

    private func readDirectTemperature(key: String) -> Double? {
        guard let keyInfo = readSMCKeyInfo(code: fourCC(key)) else { return nil }
        let type = fourCCString(keyInfo.dataType).lowercased()
        guard SMCReadingFormat.supportsTemperature(type),
              let bytes = readSMCBytes(key: key) else { return nil }
        return decodeTemperature(bytes: bytes, type: type)
    }

    private func decodeRegistryRPM(_ value: Any?) -> Double? {
        IORegistrySensorReading.rpm(from: value)
    }

    private func decodeRegistryFanCount(_ value: Any?) -> Int? {
        if let number = value as? NSNumber { return min(number.intValue, 16) }
        if let data = value as? Data, let byte = data.last { return min(Int(byte), 16) }
        if let bytes = value as? [UInt8], let byte = bytes.last { return min(Int(byte), 16) }
        if let string = value as? String, let count = Int(string) { return min(count, 16) }
        return nil
    }
    
    private func readIORegistryFans() -> [FanInfo] {
        var fans: [FanInfo] = []
        
        // Try AppleSMC / AppleSMCKeysEndpoint properties for fan data
        for serviceName in ["AppleSMC", "AppleSMCKeysEndpoint"] {
            if let matching = IOServiceMatching(serviceName) {
                var iter = io_iterator_t()
                if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS {
                    defer { IOObjectRelease(iter) }
                    while true {
                        let service = IOIteratorNext(iter)
                        guard service != 0 else { break }
                        defer { IOObjectRelease(service) }

                        var propsRef: Unmanaged<CFMutableDictionary>?
                        let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                        if kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] {
                            // Look for fan count keys
                            if let count = decodeRegistryFanCount(props["FNum"] ?? props["FanNumber"]), count > 0 {
                                for i in 0..<count {
                                    var info = FanInfo(id: i, name: fanName(for: i))
                                    let prefix = "F\(String(i, radix: 16, uppercase: true))"
                                    if let rpm = decodeRegistryRPM(props["\(prefix)Ac"]) {
                                        info.actualRPM = rpm
                                        info.hasLiveRPM = true
                                    }
                                    if let rpm = decodeRegistryRPM(props["\(prefix)Mn"]) {
                                        info.minimumRPM = rpm
                                    }
                                    if let rpm = decodeRegistryRPM(props["\(prefix)Mx"]) {
                                        info.maximumRPM = rpm
                                    }
                                    if let rpm = decodeRegistryRPM(props["\(prefix)Tg"]) {
                                        info.targetRPM = rpm
                                    }
                                    fans.append(info)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Try IOHIDEventService for fan-related HID sensors
        if fans.isEmpty {
            if let matching = IOServiceMatching("IOHIDEventService") {
                var iter = io_iterator_t()
                if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS {
                    defer { IOObjectRelease(iter) }
                    var fanIndex = 0
                    while true {
                        let service = IOIteratorNext(iter)
                        guard service != 0 else { break }
                        defer { IOObjectRelease(service) }

                        var propsRef: Unmanaged<CFMutableDictionary>?
                        let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                        if kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] {
                            let product = props["Product"] as? String ?? ""
                            if product.lowercased().contains("fan") || product.lowercased().contains("tach") {
                                var info = FanInfo(id: fanIndex, name: product)
                                if let rpm = decodeRegistryRPM(props["RPM"] ?? props["Value"]) {
                                    info.actualRPM = rpm
                                    info.hasLiveRPM = true
                                }
                                fans.append(info)
                                fanIndex += 1
                            }
                        }
                    }
                }
            }
        }
        
        return fans
    }

    private func fanName(for index: Int) -> String {
        switch index {
        case 0: return "Left Side"
        case 1: return "Right Side"
        default: return "Fan \(index + 1)"
        }
    }

    func setFanMode(_ mode: FanControlMode, fanIndex: Int = 0) -> Bool {
        let modeString = mode.rawValue
        let success: Bool
        if SMCHelperClient.shared.isHelperAvailable {
            success = SMCHelperClient.shared.setFanMode(modeString, fanIndex: fanIndex)
        } else {
            readAllLock.lock()
            defer { readAllLock.unlock() }
            success = setDirectFanMode(mode, fanIndex: fanIndex)
        }
        updateControlledFan(fanIndex, mode: mode, success: success)
        if success { invalidateReadCache() }
        return success
    }

    func setFanRPM(_ rpm: Double, fanIndex: Int = 0) -> Bool {
        let success: Bool
        if SMCHelperClient.shared.isHelperAvailable {
            success = SMCHelperClient.shared.setFanRPM(rpm, fanIndex: fanIndex)
        } else {
            readAllLock.lock()
            defer { readAllLock.unlock() }
            guard let minimumKey = fanSMCKey(index: fanIndex, suffix: "Mn"),
                  let maximumKey = fanSMCKey(index: fanIndex, suffix: "Mx"),
                  let targetKey = fanSMCKey(index: fanIndex, suffix: "Tg"),
                  let minimum = readDirectFanRPM(key: minimumKey),
                  let maximum = readDirectFanRPM(key: maximumKey),
                  supportsDirectFanRPMKey(targetKey) else { return false }
            guard maximum > minimum else { return false }
            let target = min(maximum, max(minimum, rpm))
            success = writeSMCBytes(key: targetKey, bytes: encodeFPE2(value: target))
                && readDirectFanRPM(key: targetKey).map { abs($0 - target) <= 1 } == true
                && setDirectForcedControl(true, fanIndex: fanIndex)
            if !success { releaseDirectAfterFailedTarget(fanIndex: fanIndex) }
        }
        if success {
            _ = controlLock.withLock { controlledFanIDs.insert(fanIndex) }
            invalidateReadCache()
        }
        return success
    }

    func restoreSystemFanControl() {
        let fanIDs = controlLock.withLock { Array(controlledFanIDs) }
        for fanID in fanIDs {
            _ = setFanMode(.system, fanIndex: fanID)
        }
    }

    private func setDirectFanMode(_ mode: FanControlMode, fanIndex: Int) -> Bool {
        switch mode {
        case .system, .autoMax, .manual, .custom:
            return setDirectForcedControl(false, fanIndex: fanIndex)
        case .max:
            guard let targetKey = fanSMCKey(index: fanIndex, suffix: "Tg"),
                  let maximumKey = fanSMCKey(index: fanIndex, suffix: "Mx"),
                  let maximum = readDirectFanRPM(key: maximumKey),
                  supportsDirectFanRPMKey(targetKey) else { return false }
            let success = writeSMCBytes(key: targetKey, bytes: encodeFPE2(value: maximum))
                && readDirectFanRPM(key: targetKey).map { abs($0 - maximum) <= 1 } == true
                && setDirectForcedControl(true, fanIndex: fanIndex)
            if !success { releaseDirectAfterFailedTarget(fanIndex: fanIndex) }
            return success
        }
    }

    private func supportsDirectFanControl(fanIndex: Int) -> Bool {
        if let cached = cachedDirectFanControlCapabilities[fanIndex] { return cached }
        guard let targetKey = fanSMCKey(index: fanIndex, suffix: "Tg"),
              let modeKey = fanSMCKey(index: fanIndex, suffix: "Md") else { return false }
        let supported = supportsDirectFanRPMKey(targetKey)
            && canWriteCurrentSMCValue(key: targetKey)
            && (canWriteCurrentSMCValue(key: modeKey) || canWriteCurrentSMCValue(key: "FS! "))
        cachedDirectFanControlCapabilities[fanIndex] = supported
        return supported
    }

    private func supportsDirectFanRPMKey(_ key: String) -> Bool {
        guard let keyInfo = readSMCKeyInfo(code: fourCC(key)) else { return false }
        return FanRecognition.supportsSMCRPMDataType(fourCCString(keyInfo.dataType))
    }

    private func canWriteCurrentSMCValue(key: String) -> Bool {
        guard let current = readSMCBytes(key: key), !current.isEmpty,
              writeSMCBytes(key: key, bytes: current),
              let confirmed = readSMCBytes(key: key), confirmed.count >= current.count else { return false }
        return confirmed.prefix(current.count).elementsEqual(current)
    }

    private func setDirectForcedControl(_ forced: Bool, fanIndex: Int) -> Bool {
        guard let modeKey = fanSMCKey(index: fanIndex, suffix: "Md") else { return false }
        let expectedMode: UInt8 = forced ? 1 : 0
        if readSMCBytes(key: modeKey) != nil,
           writeSMCBytes(key: modeKey, bytes: [expectedMode]),
           readSMCBytes(key: modeKey)?.first == expectedMode {
            return true
        }
        guard let bytes = readSMCBytes(key: "FS! "), bytes.count >= 2 else { return false }
        var mask = UInt16(bytes[0]) << 8 | UInt16(bytes[1])
        let bit = UInt16(1) << UInt16(fanIndex)
        mask = forced ? mask | bit : mask & ~bit
        guard writeSMCBytes(key: "FS! ", bytes: [UInt8(mask >> 8), UInt8(mask & 0xFF)]),
              let confirmed = readSMCBytes(key: "FS! "), confirmed.count >= 2 else { return false }
        let confirmedMask = UInt16(confirmed[0]) << 8 | UInt16(confirmed[1])
        return (confirmedMask & bit != 0) == forced
    }

    private func releaseDirectAfterFailedTarget(fanIndex: Int) {
        if setDirectForcedControl(false, fanIndex: fanIndex) {
            controlLock.withLock { _ = controlledFanIDs.remove(fanIndex) }
        }
    }

    private func updateControlledFan(_ fanID: Int, mode: FanControlMode, success: Bool) {
        guard success else { return }
        controlLock.withLock {
            if mode == .max {
                controlledFanIDs.insert(fanID)
            } else {
                controlledFanIDs.remove(fanID)
            }
        }
    }

    private func invalidateReadCache() {
        readAllLock.withLock {
            lastReadAll = nil
            lastReadAllTime = nil
        }
    }

    // MARK: - Thermal State Temperatures
    
    private func readThermalStateTemperatures() -> [TemperatureSensor] {
        var results: [TemperatureSensor] = []
        let state = ProcessInfo.processInfo.thermalState
        
        // Map thermal state to approximate temperatures based on Apple's documentation
        let baseTemp: Double
        let stateName: String
        switch state {
        case .nominal:
            baseTemp = 35.0
            stateName = "Nominal"
        case .fair:
            baseTemp = 50.0
            stateName = "Fair"
        case .serious:
            baseTemp = 70.0
            stateName = "Serious"
        case .critical:
            baseTemp = 90.0
            stateName = "Critical"
        @unknown default:
            baseTemp = 40.0
            stateName = "Unknown"
        }
        
        // Add CPU thermal state sensor — mark as estimated so Auto Max rules ignore it.
        results.append(TemperatureSensor(
            name: "CPU Thermal State (\(stateName))",
            key: "THCPU",
            value: baseTemp,
            maxValue: 100,
            isEstimated: true
        ))
        
        // Add GPU thermal state sensor (typically slightly higher)
        results.append(TemperatureSensor(
            name: "GPU Thermal State (\(stateName))",
            key: "THGPU",
            value: baseTemp + 3.0,
            maxValue: 100,
            isEstimated: true
        ))
        
        return results
    }

    // MARK: - IORegistry Fallback

    private func readIORegistryTemperatures() -> [TemperatureSensor] {
        var results: [TemperatureSensor] = []

        // 1. Try AppleARMIODevice for Apple Silicon specific sensors
        if let matching = IOServiceMatching("AppleARMIODevice") {
            var iter = io_iterator_t()
            if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS {
                defer { IOObjectRelease(iter) }
                while true {
                    let service = IOIteratorNext(iter)
                    guard service != 0 else { break }
                    defer { IOObjectRelease(service) }

                    var propsRef: Unmanaged<CFMutableDictionary>?
                    let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                    if kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] {
                        // Scan known temperature key prefixes
                        let tempPrefixes = ["T", "PMU", "ANE", "ISP"]
                        for (key, value) in props where tempPrefixes.contains(where: { key.hasPrefix($0) }) {
                            if let temp = IORegistrySensorReading.temperature(from: value), temp > 10 {
                                results.append(TemperatureSensor(name: key, key: key, value: temp, maxValue: 100))
                            }
                        }
                        // Some devices expose temperature via location strings like "Txxx"
                        if let location = props["location"] as? String, location.hasPrefix("T"),
                           let num = props["value"] as? NSNumber ?? props["temperature"] as? NSNumber {
                            let temp = num.doubleValue
                            if temp > 10 && temp < 150 {
                                results.append(TemperatureSensor(name: location, key: location, value: temp, maxValue: 100))
                            }
                        }
                    }
                }
            }
        }

        // 2. Try AppleSMC / AppleSMCKeysEndpoint properties in IORegistry
        for serviceName in ["AppleSMC", "AppleSMCKeysEndpoint"] {
            if let matching = IOServiceMatching(serviceName) {
                var iter = io_iterator_t()
                if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS {
                    defer { IOObjectRelease(iter) }
                    while true {
                        let service = IOIteratorNext(iter)
                        guard service != 0 else { break }
                        defer { IOObjectRelease(service) }

                        var propsRef: Unmanaged<CFMutableDictionary>?
                        let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                        if kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] {
                            for (key, value) in props where key.hasPrefix("T") {
                                if let temp = IORegistrySensorReading.temperature(from: value), temp > 10 {
                                    results.append(TemperatureSensor(name: key, key: key, value: temp, maxValue: 100))
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3. Try AppleSmartBattery for battery temperature (real hardware data)
        if let matching = IOServiceMatching("AppleSmartBattery") {
            var iter = io_iterator_t()
            if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS {
                defer { IOObjectRelease(iter) }
                while true {
                    let service = IOIteratorNext(iter)
                    guard service != 0 else { break }
                    defer { IOObjectRelease(service) }
                    
                    var propsRef: Unmanaged<CFMutableDictionary>?
                    let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                    if kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] {
                        if let tempValue = props["Temperature"] as? NSNumber {
                            let temp = tempValue.doubleValue / 100.0
                            if temp > 0 && temp < 150 {
                                results.append(TemperatureSensor(name: "Battery", key: "BAT0", value: temp, maxValue: 60))
                            }
                        }
                        if let virtualTemp = props["VirtualTemperature"] as? NSNumber {
                            let temp = virtualTemp.doubleValue / 100.0
                            if temp > 0 && temp < 150 {
                                results.append(TemperatureSensor(name: "Battery Virtual", key: "BATV", value: temp, maxValue: 60))
                            }
                        }
                    }
                }
            }
        }

        // 4. Try IOPMPowerSource for additional power-related temperatures
        if let matching = IOServiceMatching("IOPMPowerSource") {
            var iter = io_iterator_t()
            if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS {
                defer { IOObjectRelease(iter) }
                while true {
                    let service = IOIteratorNext(iter)
                    guard service != 0 else { break }
                    defer { IOObjectRelease(service) }
                    
                    var propsRef: Unmanaged<CFMutableDictionary>?
                    let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                    if kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] {
                        if let tempValue = props["Temperature"] as? NSNumber {
                            let temp = tempValue.doubleValue > 1000 ? tempValue.doubleValue / 100.0 : tempValue.doubleValue
                            if temp > 0 && temp < 150 {
                                let name = props["IORegistryEntryName"] as? String ?? "PowerSource"
                                results.append(TemperatureSensor(name: "\(name) Temperature", key: "PS_\(name)", value: temp, maxValue: 100))
                            }
                        }
                    }
                }
            }
        }

        // 5. Discover AppleARMPMUTempSensor devices (Apple Silicon).
        // These sensors exist in IORegistry but their live values are not exposed to user-space
        // on modern macOS without a privileged system extension. We list them as discovered
        // hardware with an estimated placeholder so the user can see what is present.
        results.append(contentsOf: readARMPMUTemperatures())

        // 6. Discover AppleEmbeddedNVMeTemperatureSensor if available (SSD temps).
        results.append(contentsOf: readNVMETemperatures())

        return results
    }

    private func readARMPMUTemperatures() -> [TemperatureSensor] {
        var results: [TemperatureSensor] = []
        guard let matching = IOServiceMatching("AppleARMPMUTempSensor") else { return results }

        var iter = io_iterator_t()
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS else { return results }
        defer { IOObjectRelease(iter) }

        var seen = Set<String>()
        let estimatedBase = thermalStateBaseTemp()

        while true {
            let service = IOIteratorNext(iter)
            guard service != 0 else { break }
            defer { IOObjectRelease(service) }

            var propsRef: Unmanaged<CFMutableDictionary>?
            let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
            guard kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] else { continue }

            let product = props["Product"] as? String ?? "PMU Sensor"
            let locationID = props["LocationID"] as? NSNumber ?? 0
            let key = "PMU_\(product)_\(locationID.uint32Value)"

            guard !seen.contains(key) else { continue }
            seen.insert(key)

            // Try to read a real value from properties; usually unavailable.
            let realValue: Double? = {
                if let num = props["Temperature"] as? NSNumber { return num.doubleValue }
                if let num = props["Value"] as? NSNumber { return num.doubleValue }
                return nil
            }()

            if let value = realValue, value > -50 && value < 150 {
                results.append(TemperatureSensor(name: "\(product) (loc \(locationID.uint32Value))", key: key, value: value, maxValue: 100, isEstimated: false))
            } else {
                // Placeholder so the sensor appears in the discovered list.
                results.append(TemperatureSensor(name: "\(product) (loc \(locationID.uint32Value))", key: key, value: estimatedBase, maxValue: 100, isEstimated: true))
            }
        }

        return results
    }

    private func readNVMETemperatures() -> [TemperatureSensor] {
        var results: [TemperatureSensor] = []

        for serviceName in ["AppleEmbeddedNVMeTemperatureSensor", "AppleNVMeTemperatureSensor"] {
            guard let matching = IOServiceMatching(serviceName) else { continue }
            var iter = io_iterator_t()
            guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS else { continue }
            defer { IOObjectRelease(iter) }

            var count = 0
            while true {
                let service = IOIteratorNext(iter)
                guard service != 0 else { break }
                defer { IOObjectRelease(service) }

                var propsRef: Unmanaged<CFMutableDictionary>?
                let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                guard kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] else { continue }

                let product = props["Product"] as? String ?? "NVMe Sensor"
                let key = "NVMe_\(serviceName)_\(count)"
                count += 1

                if let num = props["Temperature"] as? NSNumber {
                    let temp = num.doubleValue > 1000 ? num.doubleValue / 100.0 : num.doubleValue
                    if temp > -50 && temp < 150 {
                        results.append(TemperatureSensor(name: product, key: key, value: temp, maxValue: 100, isEstimated: false))
                        continue
                    }
                }
                if let num = props["Value"] as? NSNumber {
                    let temp = num.doubleValue
                    if temp > -50 && temp < 150 {
                        results.append(TemperatureSensor(name: product, key: key, value: temp, maxValue: 100, isEstimated: false))
                        continue
                    }
                }
            }
        }

        return results
    }

    /// Reads current CPU load directly so SMCService can provide a dynamic
    /// temperature estimate even when SystemMonitor hasn't been started.
    private func currentCPULoad() -> Double {
        var cpuInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        
        let total = Double(cpuInfo.cpu_ticks.0 + cpuInfo.cpu_ticks.1 + cpuInfo.cpu_ticks.2 + cpuInfo.cpu_ticks.3)
        guard let prev = previousCPUInfo else {
            previousCPUInfo = cpuInfo
            return 0
        }
        let prevTotal = Double(prev.cpu_ticks.0 + prev.cpu_ticks.1 + prev.cpu_ticks.2 + prev.cpu_ticks.3)
        let totalDelta = total - prevTotal
        guard totalDelta > 0 else { return 0 }
        let idleDelta = Double(cpuInfo.cpu_ticks.2 - prev.cpu_ticks.2)
        previousCPUInfo = cpuInfo
        return max(0, min(100, 100.0 * (1.0 - idleDelta / totalDelta)))
    }

    /// Returns CPU/GPU temperature estimates based on thermal state and current CPU load.
    private func estimatedTemperatures() -> (cpu: Double, gpu: Double) {
        let baseTemp = thermalStateBaseTemp()
        let load = currentCPULoad()
        let cpuTemp = baseTemp + (load * 0.25)
        return (cpu: cpuTemp, gpu: cpuTemp + 3.0)
    }

    private let hidReader = HIDTemperatureReader()

    /// Reads live temperature events from Apple Silicon PMU/NVMe HID services.
    /// Uses the private IOHIDEventSystemClient API (same path as iStat/TG Pro).
    private final class HIDTemperatureReader {
        typealias ClientRef = OpaquePointer
        typealias ServiceRef = OpaquePointer
        typealias EventRef = OpaquePointer

        typealias CreateFunc = @convention(c) (CFAllocator?) -> ClientRef?
        typealias SetMatchingFunc = @convention(c) (ClientRef?, CFDictionary?) -> Void
        typealias CopyServicesFunc = @convention(c) (ClientRef?) -> Unmanaged<CFArray>?
        typealias CopyPropertyFunc = @convention(c) (ServiceRef?, CFString?) -> CFTypeRef?
        typealias CopyEventFunc = @convention(c) (ServiceRef?, Int64, Int32, Int64) -> EventRef?
        typealias GetFloatValueFunc = @convention(c) (EventRef?, UInt32) -> Double

        private let handle: UnsafeMutableRawPointer?
        private let client: ClientRef?
        private let copyServices: CopyServicesFunc?
        private let copyProperty: CopyPropertyFunc?
        private let copyEvent: CopyEventFunc?
        private let getFloatValue: GetFloatValueFunc?

        init() {
            guard let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) else {
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
                self.client = nil
                return
            }
            let matching = ["PrimaryUsage": 5, "PrimaryUsagePage": 65280] as CFDictionary
            setMatching(client, matching)
            self.client = client
        }

        deinit {
            // Swift manages Core Foundation objects via ARC; we only need to close the dlopen handle.
            if let handle = handle {
                dlclose(handle)
            }
        }

        func readTemperatures() -> [TemperatureSensor] {
            guard let client = client,
                  let copyServices = copyServices,
                  let copyProperty = copyProperty,
                  let copyEvent = copyEvent,
                  let getFloatValue = getFloatValue else { return [] }

            guard let servicesCF = copyServices(client) else { return [] }
            let cfarray = servicesCF.takeRetainedValue()
            let count = CFArrayGetCount(cfarray)

            // Group by product name and average multiple instances.
            var grouped: [String: [Double]] = [:]
            for i in 0..<count {
                let raw = CFArrayGetValueAtIndex(cfarray, i)
                let service = unsafeBitCast(raw, to: ServiceRef.self)

                guard let productRef = copyProperty(service, "Product" as CFString),
                      CFGetTypeID(productRef) == CFStringGetTypeID(),
                      let product = productRef as? String else { continue }

                let event = copyEvent(service, 15, 0, 0)
                guard let event = event else { continue }
                let value = getFloatValue(event, 0xF0000)
                // tdev* often returns invalid placeholders around -9200 °C.
                guard value > -50 && value < 150 else { continue }

                grouped[product, default: []].append(value)
            }

            return grouped.sorted { $0.key < $1.key }.map { (product, values) in
                let avg = values.reduce(0, +) / Double(values.count)
                let key = "HID_" + product.replacingOccurrences(of: " ", with: "_")
                return TemperatureSensor(name: product, key: key, value: avg, maxValue: 100, isEstimated: false)
            }
        }
    }

    private func thermalStateBaseTemp() -> Double {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return 35.0
        case .fair: return 50.0
        case .serious: return 70.0
        case .critical: return 90.0
        @unknown default: return 40.0
        }
    }
}
