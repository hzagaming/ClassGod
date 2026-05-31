//
//  UptimeWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct UptimeWidgetView: View {
    var entry: WidgetEntry
    
    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 2) {
                Text("UPTIME")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(days)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan)
                    Text("d")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                    Text(String(format: "%02d", hours))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("h")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                    Text(String(format: "%02d", minutes))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("m")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(10)
        }
    }
    
    private var days: Int { Int(entry.uptimeSeconds) / 86400 }
    private var hours: Int { (Int(entry.uptimeSeconds) % 86400) / 3600 }
    private var minutes: Int { (Int(entry.uptimeSeconds) % 3600) / 60 }
}
