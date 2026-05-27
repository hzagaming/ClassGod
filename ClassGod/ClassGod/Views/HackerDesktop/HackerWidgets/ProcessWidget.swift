//
//  ProcessWidget.swift
//  ClassGod
//

import SwiftUI

struct ProcessWidget: View {
    @ObservedObject var monitor = SystemMonitor.shared
    @State private var hoveredPID: Int32?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                Text("PID")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 36, alignment: .leading)
                Text("NAME")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                Spacer()
                Text("CPU")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 36, alignment: .trailing)
                Text("MEM")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 44, alignment: .trailing)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 4)
            
            Divider()
                .background(Color.white.opacity(0.06))
                .padding(.horizontal, 6)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(Array(monitor.processes.enumerated()), id: \.element.id) { idx, proc in
                        HStack(spacing: 0) {
                            Text("\(proc.pid)")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(width: 36, alignment: .leading)
                            Text(proc.name)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.75))
                                .lineLimit(1)
                            Spacer()
                            Text(String(format: "%.1f", proc.cpuPercent))
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(cpuColor(proc.cpuPercent))
                                .frame(width: 36, alignment: .trailing)
                                .contentTransition(.numericText())
                            Text(proc.memoryMB > 0 ? String(format: "%.0f", proc.memoryMB) : "—")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(width: 44, alignment: .trailing)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(rowBackground(idx: idx, pid: proc.pid))
                        .onHover { isHovered in
                            hoveredPID = isHovered ? proc.pid : nil
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
        }
    }
    
    private func rowBackground(idx: Int, pid: Int32) -> Color {
        if hoveredPID == pid {
            return Color.white.opacity(0.04)
        }
        return idx % 2 == 0 ? Color.white.opacity(0.015) : Color.clear
    }
    
    private func cpuColor(_ value: Double) -> Color {
        if value < 5 { return .white.opacity(0.4) }
        if value < 20 { return .green }
        if value < 50 { return .yellow }
        return .red
    }
}
