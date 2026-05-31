//
//  MemoryWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct MemoryWidgetView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall: smallView
        case .systemMedium: mediumView
        default: smallView
        }
    }
    
    private var smallView: some View {
        ZStack {
            Color.black
            VStack(spacing: 6) {
                HStack {
                    Text("RAM")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text("\(Int(usedGB))G")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(memColor)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(memColor)
                            .frame(width: geo.size.width * CGFloat(min(usageRatio, 1)), height: 8)
                    }
                }
                .frame(height: 8)
                
                Text("/ \(Int(entry.memoryTotal)) GB")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(10)
        }
    }
    
    private var mediumView: some View {
        ZStack {
            Color.black
            VStack(spacing: 8) {
                HStack {
                    Text("MEMORY")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text("\(Int(usedGB)) / \(Int(entry.memoryTotal)) GB")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(memColor)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(memColor)
                            .frame(width: geo.size.width * CGFloat(min(usageRatio, 1)), height: 10)
                    }
                }
                .frame(height: 10)
                
                HStack(spacing: 12) {
                    Label("Used: \(Int(usedGB))G", systemImage: "memorychip")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.45))
                    Label("Free: \(Int(freeGB))G", systemImage: "memorychip.fill")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .padding(12)
        }
    }
    
    private var usedGB: Double { entry.memoryUsage }
    private var freeGB: Double { max(0, entry.memoryTotal - entry.memoryUsage) }
    private var usageRatio: Double {
        guard entry.memoryTotal > 0 else { return 0 }
        return entry.memoryUsage / entry.memoryTotal
    }
    
    private var memColor: Color {
        if usageRatio > 0.85 { return .red }
        if usageRatio > 0.6 { return .orange }
        return .cyan
    }
}
