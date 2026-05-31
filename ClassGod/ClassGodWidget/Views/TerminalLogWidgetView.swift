//
//  TerminalLogWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct TerminalLogWidgetView: View {
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
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("$")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.green)
                    Text("tail -f /var/log")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(entry.terminalLogs.prefix(3), id: \.self) { line in
                        Text(line)
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(logColor(for: line))
                            .lineLimit(1)
                    }
                }
            }
            .padding(10)
        }
    }
    
    private var mediumView: some View {
        ZStack {
            Color.black
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("$")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.green)
                    Text("tail -f /var/log/system.log")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(entry.terminalLogs.prefix(5), id: \.self) { line in
                        Text(line)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(logColor(for: line))
                            .lineLimit(1)
                    }
                }
            }
            .padding(12)
        }
    }
    
    private func logColor(for line: String) -> Color {
        if line.contains("error") || line.contains("fail") { return .red.opacity(0.8) }
        if line.contains("warn") { return .orange.opacity(0.8) }
        if line.contains("success") || line.contains("accepted") { return .green.opacity(0.7) }
        return .white.opacity(0.65)
    }
}
