//
//  DiskWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct DiskWidgetView: View {
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
            VStack(spacing: 4) {
                Text("DISK")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: CGFloat(usedRatio))
                        .stroke(diskColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(Int(usedRatio * 100))%")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                        Text("USED")
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .frame(width: 54, height: 54)
            }
            .padding(8)
        }
    }
    
    private var mediumView: some View {
        ZStack {
            Color.black
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: CGFloat(usedRatio))
                        .stroke(diskColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(Int(usedRatio * 100))%")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                        Text("USED")
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .frame(width: 64, height: 64)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("STORAGE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("\(Int(entry.diskFree))G free")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("/ \(Int(entry.diskTotal))G total")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                }
                
                Spacer()
            }
            .padding(12)
        }
    }
    
    private var usedRatio: Double {
        guard entry.diskTotal > 0 else { return 0 }
        return max(0, min(1, (entry.diskTotal - entry.diskFree) / entry.diskTotal))
    }
    
    private var diskColor: Color {
        if usedRatio > 0.9 { return .red }
        if usedRatio > 0.75 { return .orange }
        return .cyan
    }
}
