//
//  GlitchWindowViews.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

// MARK: - Static Terminal View

struct TerminalGlitchView: View {
    let seed: Int
    
    private var lines: [String] {
        let prefixes = ["0x", "ADDR", "MEM", "ERR", "SYS", "BLCK", "NULL", "OVFL", "CORE", "DUMP", "WARN", "CRIT"]
        let suffixes = ["", " !", " ?", " ...", " >>", " <<", " [FAULT]", " [WARN]", " [CRIT]", " [OK]", " [FAIL]", " [DONE]"]
        return (0..<16).map { i in
            let prefix = prefixes[(seed + i) % prefixes.count]
            let hex = (0..<8).map { _ in String(format: "%02X", Int.random(in: 0...255)) }.joined()
            let suffix = suffixes[(seed + i + 3) % suffixes.count]
            return "\(prefix) \(hex)\(suffix)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.green.opacity(0.85))
                    .lineLimit(1)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

// MARK: - Static Error View

struct ErrorGlitchView: View {
    let seed: Int
    
    private var title: String {
        ["System Failure", "Access Denied", "Kernel Panic", "Stack Overflow",
         "Segmentation Fault", "Permission Error", "Connection Lost",
         "Fatal Exception", "Heap Corruption", "Bus Error"][seed % 10]
    }
    
    private var message: String {
        ["0xDEADBEEF at 0x0040A3F2. Thread terminated unexpectedly.",
         "Unauthorized access attempt detected. Intrusion alert triggered.",
         "Critical process crashed. Dumping memory at 0x7FFF...",
         "Recursion limit exceeded. Call stack depth: 9999+",
         "Null pointer dereference. Address 0x00000000 inaccessible.",
         "Required entitlement missing. Sandbox violation detected.",
         "Network timeout. Connection to host failed after 3 retries.",
         "Unhandled exception in main loop. Error code: 0xC0000005",
         "Heap buffer overflow detected. Aborting immediately.",
         "Bus error: misaligned memory access at 0xBAD00000"][seed % 10]
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.red)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(4)
            }
            
            Spacer()
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.06))
        .overlay(Rectangle().stroke(Color.red.opacity(0.5), lineWidth: 1))
    }
}

// MARK: - Yellow Warning View

struct WarningGlitchView: View {
    let seed: Int
    
    private var lines: [String] {
        [
            "⚠ WARNING: Unauthorized system modification detected",
            "⚠ WARNING: Kernel integrity check failed at 0x\(String(format: "%08x", seed * 0x1000))",
            "⚠ WARNING: Memory leak detected in process ClassGod [\(seed)]",
            "⚠ WARNING: Stack canary corrupted, possible buffer overflow",
            "⚠ WARNING: ASLR disabled, system vulnerable to ROP attacks",
            "⚠ WARNING: DEP bypass attempt detected in thread \(seed % 8)",
            "⚠ WARNING: Syscall interception active, tracer detected",
            "⚠ WARNING: Code signature invalid for module \(seed % 16)",
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(0..<min(lines.count, 6), id: \.self) { i in
                Text(lines[(seed + i) % lines.count])
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color.yellow.opacity(0.85))
                    .lineLimit(1)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
        .overlay(Rectangle().stroke(Color.yellow.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Purple System Log View

struct SyslogGlitchView: View {
    let seed: Int
    
    private var lines: [String] {
        let levels = ["[INFO]", "[DEBUG]", "[WARN]", "[ERROR]", "[FATAL]", "[TRACE]"]
        let modules = ["kernel", "launchd", "WindowServer", "syslogd", "securityd", "ClassGod"]
        return (0..<12).map { i in
            let level = levels[(seed + i) % levels.count]
            let module = modules[(seed + i) % modules.count]
            let msg = "Process \(module) pid=\(Int.random(in: 100...99999)) exited with code \(Int.random(in: -9...139))"
            return "\(level) \(msg)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color.purple.opacity(0.85))
                    .lineLimit(1)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

// MARK: - Static Crash Report View

struct CrashGlitchView: View {
    let seed: Int
    
    private var frames: [String] {
        let libs = ["libsystem_kernel.dylib", "CoreFoundation", "libobjc.A.dylib",
                    "AppKit", "ClassGod", "libdispatch.dylib", "SwiftUI", "ViewBridge"]
        return (0..<7).map { i in
            let lib = libs[(seed + i) % libs.count]
            let addr = String(format: "%p", Int.random(in: 0x100000000...0x7FFFFFFFFFFF))
            return "\(i+1). \(lib) \(addr) \(lib)_frame_\(Int.random(in: 1...999)) + \(Int.random(in: 1...9999))"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Process: ClassGod [\(1000 + seed)]")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text("Crashed Thread: \(seed % 8)")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
            Divider().background(Color.white.opacity(0.2))
            ForEach(frames, id: \.self) { frame in
                Text(frame)
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.04))
        .overlay(Rectangle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
    }
}

// MARK: - Static Matrix Block View

struct MatrixBlockView: View {
    let seed: Int
    
    private var grid: [[String]] {
        let chars = "ABCDEF0123456789!@#$%&*"
        let rows = 12
        let cols = 14
        return (0..<rows).map { _ in
            (0..<cols).map { _ in
                String(chars.randomElement()!)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<grid.count, id: \.self) { r in
                HStack(spacing: 2) {
                    ForEach(0..<grid[r].count, id: \.self) { c in
                        Text(grid[r][c])
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.green.opacity(Double.random(in: 0.3...1.0)))
                    }
                }
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Blue Screen View

struct BlueScreenView: View {
    let seed: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(":(")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.white)
            
            Text("Your PC ran into a problem and needs to restart.")
                .font(.system(size: 10))
                .foregroundStyle(.white)
            
            Text("STOP CODE: \(stopCode)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
            
            Text("0% complete")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.0, green: 0.35, blue: 0.65))
    }
    
    private var stopCode: String {
        ["CRITICAL_PROCESS_DIED", "IRQL_NOT_LESS_OR_EQUAL",
         "PAGE_FAULT_IN_NONPAGED_AREA", "SYSTEM_THREAD_EXCEPTION_NOT_HANDLED",
         "KERNEL_SECURITY_CHECK_FAILURE", "DRIVER_IRQL_NOT_LESS_OR_EQUAL"][seed % 6]
    }
}

// MARK: - Hex Dump View

struct HexDumpView: View {
    let seed: Int
    
    private var lines: [String] {
        return (0..<14).map { i in
            let addr = String(format: "%08x", (seed * 0x1000) + (i * 16))
            let bytes = (0..<8).map { _ in String(format: "%02x", Int.random(in: 0...255)) }.joined(separator: " ")
            return "\(addr)  \(bytes)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.cyan.opacity(0.85))
                    .lineLimit(1)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

// MARK: - JSON Error View

struct JSONErrorView: View {
    let seed: Int
    
    private var json: String {
        """
        {
          "error": true,
          "code": \(Int.random(in: 400...599)),
          "message": "\(["Internal Server Error", "Bad Gateway", "Service Unavailable", "Gateway Timeout"][seed % 4])",
          "trace_id": "\(UUID().uuidString.prefix(8))",
          "timestamp": "\(Int.random(in: 1600000000...1700000000))",
          "module": "\(["api", "auth", "db", "cache"][seed % 4])",
          "fatal": true
        }
        """
    }
    
    var body: some View {
        Text(json)
            .font(.system(size: 8, design: .monospaced))
            .foregroundStyle(Color.orange.opacity(0.85))
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.black)
            .overlay(Rectangle().stroke(Color.orange.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Compile Error View

struct CompileErrorView: View {
    let seed: Int
    
    private var lines: [String] {
        let files = ["main.swift", "MenuBarView.swift", "BrowserSwitcher.swift", "TabListViewModel.swift"]
        let errors = [
            "error: cannot find 'foo' in scope",
            "error: value of optional type must be unwrapped",
            "error: ambiguous use of 'init'",
            "error: type 'NSWindow' has no member 'alpha'",
            "error: unable to infer closure type",
            "error: escaping closure captures mutating self parameter",
            "warning: result of call is unused",
            "error: protocol 'View' requires 'body' to be available",
        ]
        return (0..<8).map { i in
            let file = files[(seed + i) % files.count]
            let line = Int.random(in: 1...500)
            let err = errors[(seed + i) % errors.count]
            return "\(file):\(line): \(err)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(line.contains("error:") ? Color.red.opacity(0.8) : Color.yellow.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

// MARK: - Glitch Window Type

enum GlitchType: CaseIterable {
    case terminal, error, warning, syslog, crashReport, matrixBlock, blueScreen, hexDump, jsonError, compileError
    
    @ViewBuilder
    func view(seed: Int) -> some View {
        switch self {
        case .terminal:
            TerminalGlitchView(seed: seed)
        case .error:
            ErrorGlitchView(seed: seed)
        case .warning:
            WarningGlitchView(seed: seed)
        case .syslog:
            SyslogGlitchView(seed: seed)
        case .crashReport:
            CrashGlitchView(seed: seed)
        case .matrixBlock:
            MatrixBlockView(seed: seed)
        case .blueScreen:
            BlueScreenView(seed: seed)
        case .hexDump:
            HexDumpView(seed: seed)
        case .jsonError:
            JSONErrorView(seed: seed)
        case .compileError:
            CompileErrorView(seed: seed)
        }
    }
}
