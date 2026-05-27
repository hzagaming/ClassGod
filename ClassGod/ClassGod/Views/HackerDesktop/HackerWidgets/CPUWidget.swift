//
//  CPUWidget.swift
//  ClassGod
//

import SwiftUI

struct CPUWidget: View {
    @ObservedObject var monitor = SystemMonitor.shared
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 8)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: min(monitor.cpu.total / 100.0, 1.0))
                    .stroke(
                        cpuColor(monitor.cpu.total),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: monitor.cpu.total)
                
                VStack(spacing: 2) {
                    Text("\(Int(monitor.cpu.total))")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    
                    Text("%")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .offset(y: -2)
                }
            }
            
            HStack(spacing: 12) {
                miniBar(label: "USR", value: monitor.cpu.user, color: .cyan)
                miniBar(label: "SYS", value: monitor.cpu.system, color: .orange)
            }
        }
        .padding(10)
    }
    
    private func cpuColor(_ value: Double) -> Color {
        if value < 50 { return .green }
        if value < 80 { return .yellow }
        return .red
    }
    
    private func miniBar(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * min(value / 100, 1), height: 4)
                        .animation(.linear(duration: 0.3), value: value)
                }
            }
            .frame(height: 4)
            
            Text("\(Int(value))%")
                .font(.system(size: 7, design: .monospaced))
                .foregroundStyle(color.opacity(0.8))
                .contentTransition(.numericText())
        }
    }
}
