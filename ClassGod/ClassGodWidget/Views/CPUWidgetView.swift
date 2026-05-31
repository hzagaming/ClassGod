//
//  CPUWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct CPUWidgetView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }
    
    private var smallView: some View {
        ZStack {
            Color.black
            VStack(spacing: 4) {
                Text("CPU")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: min(entry.cpuUsage / 100, 1))
                        .stroke(cpuColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(entry.cpuUsage))%")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .frame(width: 56, height: 56)
            }
            .padding(8)
        }
    }
    
    private var mediumView: some View {
        ZStack {
            Color.black
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: min(entry.cpuUsage / 100, 1))
                        .stroke(cpuColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(entry.cpuUsage))%")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .frame(width: 72, height: 72)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("CPU LOAD")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                    
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(cpuColor)
                            .frame(width: 8, height: 8)
                        Text(statusText)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    Text("cores: \(ProcessInfo.processInfo.processorCount)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                }
                
                Spacer()
            }
            .padding(12)
        }
    }
    
    private var cpuColor: Color {
        if entry.cpuUsage > 80 { return .red }
        if entry.cpuUsage > 50 { return .orange }
        return .cyan
    }
    
    private var statusText: String {
        if entry.cpuUsage > 80 { return "CRITICAL" }
        if entry.cpuUsage > 50 { return "HEAVY" }
        return "NORMAL"
    }
}
