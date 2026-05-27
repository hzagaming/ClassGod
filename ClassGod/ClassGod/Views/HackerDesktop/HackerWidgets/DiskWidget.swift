//
//  DiskWidget.swift
//  ClassGod
//

import SwiftUI

struct DiskWidget: View {
    @ObservedObject var monitor = SystemMonitor.shared
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(monitor.disks.prefix(3)) { disk in
                HStack(spacing: 6) {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 14)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(disk.name)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(disk.usedPercent * 100))%")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(diskColor(disk.usedPercent))
                                .contentTransition(.numericText())
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.06))
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(diskColor(disk.usedPercent))
                                    .frame(width: geo.size.width * disk.usedPercent, height: 4)
                                    .animation(.linear(duration: 0.5), value: disk.usedPercent)
                            }
                        }
                        .frame(height: 4)
                        
                        HStack {
                            Text(formatBytes(disk.used))
                                .font(.system(size: 7, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.35))
                            Spacer()
                            Text(formatBytes(disk.total))
                                .font(.system(size: 7, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                    }
                }
            }
        }
        .padding(10)
    }
    
    private func diskColor(_ percent: Double) -> Color {
        if percent < 0.6 { return .cyan }
        if percent < 0.85 { return .yellow }
        return .red
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb >= 1000 {
            return String(format: "%.1f TB", gb / 1024)
        }
        return String(format: "%.0f GB", gb)
    }
}
