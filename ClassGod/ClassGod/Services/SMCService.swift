//
//  SMCService.swift
//  ClassGod
//

import Foundation
import IOKit

// MARK: - Data Models

struct TemperatureSensor: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let key: String
    var value: Double
    var maxValue: Double = 100
}

struct FanInfo: Identifiable, Equatable {
    let id: Int
    var name: String
    var actualRPM: Double = 0
    var minimumRPM: Double = 0
    var maximumRPM: Double = 0
    var targetRPM: Double = 0
}

enum FanControlMode: String, Codable, CaseIterable, Identifiable {
    case system = "system"
    case max = "max"
    case autoMax = "autoMax"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return "System"
        case .max: return "Max"
        case .autoMax: return "Auto Max"
        }
    }
}

enum TemperatureUnit: String, Codable, CaseIterable, Identifiable {
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

private let KERNEL_INDEX_SMC: UInt32 = 2

final class SMCService {
    static let shared = SMCService()

    private var conn: io_connect_t = 0
    private(set) var isConnected = false
    private(set) var isUsingIORegistryFallback = false

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

    private init() {
        connect()
    }

    deinit {
        if conn != 0 {
            IOServiceClose(conn)
            conn = 0
        }
    }

    // MARK: - Connection

    private func connect() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return }
        defer { IOObjectRelease(service) }
        let result = IOServiceOpen(service, mach_task_self_, 0, &conn)
        isConnected = (result == KERN_SUCCESS)
    }

    // MARK: - Raw SMC Call

    private func smcCall(input: inout [UInt8], output: inout [UInt8]) -> kern_return_t {
        let inputSize = input.count
        var outputSize = output.count
        return input.withUnsafeMutableBytes { inputPtr in
            output.withUnsafeMutableBytes { outputPtr in
                guard let inputAddr = inputPtr.baseAddress, let outputAddr = outputPtr.baseAddress else {
                    return KERN_INVALID_ADDRESS
                }
                return IOConnectCallStructMethod(
                    conn,
                    KERNEL_INDEX_SMC,
                    inputAddr, inputSize,
                    outputAddr, &outputSize
                )
            }
        }
    }

    private func readSMCBytes(key: String) -> [UInt8]? {
        guard isConnected, key.count == 4 else { return nil }
        let keyCode = fourCC(key)

        var input = [UInt8](repeating: 0, count: 56)
        var output = [UInt8](repeating: 0, count: 56)

        // key at offset 0, big-endian
        input[0] = UInt8((keyCode >> 24) & 0xFF)
        input[1] = UInt8((keyCode >> 16) & 0xFF)
        input[2] = UInt8((keyCode >> 8) & 0xFF)
        input[3] = UInt8(keyCode & 0xFF)

        // Try READ_BYTES commands
        let commands: [UInt8] = [5, 6, 10]
        for cmd in commands {
            input[16] = cmd
            let kr = smcCall(input: &input, output: &output)
            if kr == KERN_SUCCESS && output[14] == 0 {
                return Array(output[24..<56])
            }
        }
        return nil
    }

    private func writeSMCBytes(key: String, bytes: [UInt8]) -> Bool {
        guard isConnected, key.count == 4 else { return false }
        let keyCode = fourCC(key)

        var input = [UInt8](repeating: 0, count: 56)
        var output = [UInt8](repeating: 0, count: 56)

        input[0] = UInt8((keyCode >> 24) & 0xFF)
        input[1] = UInt8((keyCode >> 16) & 0xFF)
        input[2] = UInt8((keyCode >> 8) & 0xFF)
        input[3] = UInt8(keyCode & 0xFF)

        for (i, byte) in bytes.prefix(32).enumerated() {
            input[24 + i] = byte
        }

        let commands: [UInt8] = [6, 7, 11]
        for cmd in commands {
            input[16] = cmd
            let kr = smcCall(input: &input, output: &output)
            if kr == KERN_SUCCESS && output[14] == 0 {
                return true
            }
        }
        return false
    }

    private func fourCC(_ string: String) -> UInt32 {
        var result: UInt32 = 0
        let chars = Array(string.utf8)
        for i in 0..<min(4, chars.count) {
            result = (result << 8) | UInt32(chars[i])
        }
        return result
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

    func readTemperatures() -> [TemperatureSensor] {
        var results: [TemperatureSensor] = []

        // Try SMC direct
        for (name, key, max) in sensorKeys {
            if let bytes = readSMCBytes(key: key), bytes.count >= 2 {
                let value = decodeSP78(bytes: bytes)
                if value > -50 && value < 150 {
                    results.append(TemperatureSensor(name: name, key: key, value: value, maxValue: max))
                }
            }
        }

        isUsingIORegistryFallback = false

        // Fallback: IORegistry traversal for Apple Silicon
        if results.isEmpty {
            results = readIORegistryTemperatures()
            isUsingIORegistryFallback = !results.isEmpty
        }

        // Fallback: SystemMonitor estimates
        if results.isEmpty {
            let thermal = SystemMonitor.shared.thermal
            if thermal.cpuTemp > 0 {
                results.append(TemperatureSensor(name: "CPU Estimated", key: "CPU", value: thermal.cpuTemp, maxValue: 100))
            }
            if thermal.gpuTemp > 0 {
                results.append(TemperatureSensor(name: "GPU Estimated", key: "GPU", value: thermal.gpuTemp, maxValue: 100))
            }
        }

        return results.sorted { $0.name < $1.name }
    }

    func readFans() -> [FanInfo] {
        var fans: [FanInfo] = []

        guard let numBytes = readSMCBytes(key: "FNum"), numBytes.count >= 1 else {
            return fans
        }

        let numFans = min(Int(numBytes[0]), 16)

        for i in 0..<numFans {
            let actualKey = "F\(i)Ac"
            let minKey = "F\(i)Mn"
            let maxKey = "F\(i)Mx"
            let targetKey = "F\(i)Tg"

            var info = FanInfo(id: i, name: fanName(for: i))

            if let bytes = readSMCBytes(key: actualKey) {
                info.actualRPM = decodeFPE2(bytes: bytes)
            }
            if let bytes = readSMCBytes(key: minKey) {
                info.minimumRPM = decodeFPE2(bytes: bytes)
            }
            if let bytes = readSMCBytes(key: maxKey) {
                info.maximumRPM = decodeFPE2(bytes: bytes)
            }
            if let bytes = readSMCBytes(key: targetKey) {
                info.targetRPM = decodeFPE2(bytes: bytes)
            }

            fans.append(info)
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
        switch mode {
        case .system:
            return writeSMCBytes(key: "F\(fanIndex)Tg", bytes: [0, 0])
        case .max:
            guard let maxBytes = readSMCBytes(key: "F\(fanIndex)Mx"), maxBytes.count >= 2 else { return false }
            return writeSMCBytes(key: "F\(fanIndex)Tg", bytes: Array(maxBytes.prefix(2)))
        case .autoMax:
            return true // Handled by view model timer
        }
    }

    func setFanRPM(_ rpm: Double, fanIndex: Int = 0) -> Bool {
        let bytes = encodeFPE2(value: rpm)
        return writeSMCBytes(key: "F\(fanIndex)Tg", bytes: bytes)
    }

    // MARK: - IORegistry Fallback

    private func readIORegistryTemperatures() -> [TemperatureSensor] {
        var results: [TemperatureSensor] = []

        // Try AppleARMIODevice
        if let matching = IOServiceMatching("AppleARMIODevice") {
            var iter = io_iterator_t()
            guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == KERN_SUCCESS else {
                return results
            }
            defer { IOObjectRelease(iter) }

            while true {
                let service = IOIteratorNext(iter)
                guard service != 0 else { break }
                defer { IOObjectRelease(service) }

                var propsRef: Unmanaged<CFMutableDictionary>?
                let kr = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
                if kr == KERN_SUCCESS, let props = propsRef?.takeRetainedValue() as? [String: Any] {
                    for (key, value) in props where key.hasPrefix("T") {
                        if let num = value as? NSNumber {
                            let temp = num.doubleValue
                            if temp > 10 && temp < 150 {
                                results.append(TemperatureSensor(name: key, key: key, value: temp, maxValue: 100))
                            }
                        } else if let data = value as? Data, data.count >= 2 {
                            let bytes = [UInt8](data)
                            let temp = decodeSP78(bytes: bytes)
                            if temp > 10 && temp < 150 {
                                results.append(TemperatureSensor(name: key, key: key, value: temp, maxValue: 100))
                            }
                        }
                    }
                }
            }
        }

        // Also try AppleSMC properties in IORegistry
        if let matching = IOServiceMatching("AppleSMC") {
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
                            if let data = value as? Data, data.count >= 2 {
                                let bytes = [UInt8](data)
                                let temp = decodeSP78(bytes: bytes)
                                if temp > 10 && temp < 150 {
                                    results.append(TemperatureSensor(name: key, key: key, value: temp, maxValue: 100))
                                }
                            } else if let num = value as? NSNumber {
                                let temp = num.doubleValue
                                if temp > 10 && temp < 150 {
                                    results.append(TemperatureSensor(name: key, key: key, value: temp, maxValue: 100))
                                }
                            }
                        }
                    }
                }
            }
        }

        return results
    }
}
