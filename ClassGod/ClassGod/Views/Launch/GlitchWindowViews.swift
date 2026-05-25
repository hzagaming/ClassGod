//
//  GlitchWindowViews.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI
import Combine

// MARK: - Terminal Glitch View

struct TerminalGlitchView: View {
    @State private var lines: [String] = []
    @State private var timer: Timer?
    private let maxLines = 12
    
    let seed: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.green.opacity(0.85))
                    .lineLimit(1)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
        .onAppear {
            startGlitch()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startGlitch() {
        // Initial burst
        for _ in 0..<maxLines {
            lines.append(randomHexLine())
        }
        
        // Continuous update
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if lines.count >= maxLines {
                lines.removeFirst()
            }
            lines.append(randomHexLine())
        }
    }
    
    private func randomHexLine() -> String {
        let prefixes = ["0x", "ADDR", "MEM", "ERR", "SYS", "BLCK", "NULL", "OVFL"]
        let prefix = prefixes[(seed + lines.count) % prefixes.count]
        let hex = (0..<8).map { _ in String(format: "%02X", Int.random(in: 0...255)) }.joined()
        let suffixes = ["", " !", " ?", " ...", " >>", " <<", " [FAULT]", " [WARN]"]
        let suffix = suffixes.randomElement()!
        return "\(prefix) \(hex)\(suffix)"
    }
}

// MARK: - Error Glitch View

struct ErrorGlitchView: View {
    @State private var shakeOffset: CGFloat = 0
    let seed: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.red)
                .offset(x: shakeOffset)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(errorTitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(errorMessage)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.08))
        .overlay(
            Rectangle()
                .stroke(Color.red.opacity(0.5), lineWidth: 1)
        )
        .onAppear {
            startShake()
        }
    }
    
    private func startShake() {
        let steps: [CGFloat] = [-3, 3, -2, 2, -1, 1, 0]
        for (i, offset) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                shakeOffset = offset
            }
        }
    }
    
    private var errorTitle: String {
        let titles = [
            "System Failure",
            "Access Denied",
            "Kernel Panic",
            "Stack Overflow",
            "Segmentation Fault",
            "Permission Error",
            "Connection Lost",
            "Fatal Exception"
        ]
        return titles[seed % titles.count]
    }
    
    private var errorMessage: String {
        let msgs = [
            "0xDEADBEEF at 0x0040A3F2. Thread terminated unexpectedly.",
            "Unauthorized access attempt detected. Intrusion alert triggered.",
            "Critical process crashed. Dumping memory at 0x7FFF...",
            "Recursion limit exceeded. Call stack depth: 9999+",
            "Null pointer dereference. Address 0x00000000 inaccessible.",
            "Required entitlement missing. Sandbox violation detected.",
            "Network timeout. Connection to host failed after 3 retries.",
            "Unhandled exception in main loop. Error code: 0xC0000005"
        ]
        return msgs[seed % msgs.count]
    }
}

// MARK: - Crash Report Glitch View

struct CrashGlitchView: View {
    let seed: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Process: ClassGod [\(1000 + seed)]")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            
            Text("Crashed Thread: \(seed % 8)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            ForEach(0..<6) { i in
                Text("\(i + 1). \(randomFrame())")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.06))
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }
    
    private func randomFrame() -> String {
        let libs = ["libsystem_kernel.dylib", "CoreFoundation", "libobjc.A.dylib", "AppKit", "ClassGod", "libdispatch.dylib"]
        let lib = libs[(seed + Int.random(in: 0...100)) % libs.count]
        let addr = String(format: "%p", Int.random(in: 0x100000000...0x7FFFFFFFFFFF))
        return "\(lib)\t\(addr) \t\(lib)_frame_\(Int.random(in: 1...999)) + \(Int.random(in: 1...9999))"
    }
}

// MARK: - Matrix Rain Glitch View

struct MatrixRainGlitchView: View {
    @State private var drops: [MatrixDrop] = []
    private let columns = 15
    private let timer = Timer.publish(every: 0.06, on: .main, in: .common).autoconnect()
    
    struct MatrixDrop: Identifiable {
        let id = UUID()
        var column: Int
        var row: Int
        var chars: [Character]
        var brightness: Double
    }
    
    var body: some View {
        GeometryReader { geo in
            let colWidth = geo.size.width / CGFloat(columns)
            ZStack {
                Color.black
                ForEach(drops) { drop in
                    VStack(spacing: 0) {
                        ForEach(0..<drop.chars.count, id: \.self) { i in
                            Text(String(drop.chars[i]))
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.green.opacity(i == drop.chars.count - 1 ? 1.0 : 0.5))
                                .frame(width: colWidth, height: 12)
                        }
                    }
                    .position(
                        x: CGFloat(drop.column) * colWidth + colWidth / 2,
                        y: CGFloat(drop.row) * 12
                    )
                }
            }
            .onReceive(timer) { _ in
                updateDrops()
            }
            .onAppear {
                for _ in 0..<8 {
                    drops.append(createDrop())
                }
            }
        }
    }
    
    private func createDrop() -> MatrixDrop {
        let chars = "ABCDEF0123456789!@#$%^&*()"
        let length = Int.random(in: 3...8)
        return MatrixDrop(
            column: Int.random(in: 0..<columns),
            row: Int.random(in: 0...20),
            chars: (0..<length).map { _ in chars.randomElement()! },
            brightness: Double.random(in: 0.3...1.0)
        )
    }
    
    private func updateDrops() {
        for i in drops.indices {
            drops[i].row += 1
            if drops[i].row > 25 {
                drops[i] = createDrop()
            }
        }
    }
}

// MARK: - Glitch Window Type

enum GlitchType {
    case terminal, error, crashReport, matrixRain
    
    @ViewBuilder
    func view(seed: Int) -> some View {
        switch self {
        case .terminal:
            TerminalGlitchView(seed: seed)
        case .error:
            ErrorGlitchView(seed: seed)
        case .crashReport:
            CrashGlitchView(seed: seed)
        case .matrixRain:
            MatrixRainGlitchView()
        }
    }
}
