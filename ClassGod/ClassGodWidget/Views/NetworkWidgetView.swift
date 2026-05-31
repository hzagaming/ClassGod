//
//  NetworkWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct NetworkWidgetView: View {
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
                Text("NET")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                
                HStack(spacing: 12) {
                    VStack(spacing: 2) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 10))
                            .foregroundStyle(.cyan)
                        Text(formatSpeed(entry.networkDown))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    VStack(spacing: 2) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                        Text(formatSpeed(entry.networkUp))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(10)
        }
    }
    
    private var mediumView: some View {
        ZStack {
            Color.black
            VStack(spacing: 8) {
                HStack {
                    Text("NETWORK")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.cyan)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("DOWN")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                            Text(formatSpeed(entry.networkDown))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("UP")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                            Text(formatSpeed(entry.networkUp))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .padding(12)
        }
    }
    
    private func formatSpeed(_ mbps: Double) -> String {
        if mbps >= 1000 {
            return String(format: "%.1fG", mbps / 1000)
        }
        if mbps >= 1 {
            return String(format: "%.1fM", mbps)
        }
        return String(format: "%.0fK", mbps * 1000)
    }
}
