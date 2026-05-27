//
//  MemoryWidget.swift
//  ClassGod
//

import SwiftUI

struct MemoryWidget: View {
    @ObservedObject var monitor = SystemMonitor.shared
    
    private var usedGB: Double { Double(monitor.memory.used) / 1_073_741_824 }
    private var totalGB: Double { Double(monitor.memory.total) / 1_073_741_824 }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(String(format: "%.1f", usedGB)) / \(String(format: "%.1f", totalGB)) GB")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(monitor.memory.usedPercent * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(memColor)
                    .contentTransition(.numericText())
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.06))
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(memColor)
                        .frame(width: geo.size.width * monitor.memory.usedPercent)
                        .animation(.linear(duration: 0.4), value: monitor.memory.usedPercent)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 2)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .opacity(monitor.memory.usedPercent > 0.9 ? 1 : 0)
                        )
                }
            }
            .frame(height: 12)
            
            HStack(spacing: 8) {
                memDetail(label: "WIRED", value: monitor.memory.wired)
                memDetail(label: "CMPRS", value: monitor.memory.compressed)
                memDetail(label: "FREE", value: monitor.memory.free)
            }
        }
        .padding(10)
    }
    
    private var memColor: Color {
        let p = monitor.memory.usedPercent
        if p < 0.6 { return .green }
        if p < 0.85 { return .yellow }
        return .red
    }
    
    private func memDetail(label: String, value: UInt64) -> some View {
        let gb = Double(value) / 1_073_741_824
        return VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
            Text(String(format: "%.1fG", gb))
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
    }
}
