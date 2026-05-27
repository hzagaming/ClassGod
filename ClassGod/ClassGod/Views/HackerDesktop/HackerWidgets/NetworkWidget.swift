//
//  NetworkWidget.swift
//  ClassGod
//

import SwiftUI

struct NetworkWidget: View {
    @ObservedObject var monitor = SystemMonitor.shared
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                netStat(icon: "arrow.down.circle.fill", label: "DOWN", speed: monitor.network.downloadSpeedKBs, color: .green)
                netStat(icon: "arrow.up.circle.fill", label: "UP", speed: monitor.network.uploadSpeedKBs, color: .orange)
            }
            
            HStack(spacing: 4) {
                Text("TOTAL IN:")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                Text(formatBytes(monitor.network.bytesIn))
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text("TOTAL OUT:")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                Text(formatBytes(monitor.network.bytesOut))
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(10)
    }
    
    private func netStat(icon: String, label: String, speed: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                    .symbolEffect(.pulse, options: .repeating, value: speed > 1)
                VStack(alignment: .leading, spacing: 0) {
                    Text(label)
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                    Text(formatSpeed(speed))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatSpeed(_ kbs: Double) -> String {
        if kbs > 1024 {
            return String(format: "%.1f MB/s", kbs / 1024)
        }
        if kbs < 1 {
            return "0 KB/s"
        }
        return String(format: "%.0f KB/s", kbs)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb >= 1000 { return String(format: "%.1f TB", gb / 1024) }
        if gb >= 1 { return String(format: "%.1f GB", gb) }
        return String(format: "%.0f MB", gb * 1024)
    }
}
