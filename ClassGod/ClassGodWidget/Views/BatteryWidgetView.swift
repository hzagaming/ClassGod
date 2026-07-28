//
//  BatteryWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct BatteryWidgetView: View {
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
                HStack(spacing: 4) {
                    Image(systemName: entry.batteryIsCharging ? "bolt.fill" : "battery.100")
                        .font(.system(size: 10))
                        .foregroundStyle(batteryColor)
                    Text("\(Int(batteryLevel))%")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(batteryColor)
                            .frame(width: geo.size.width * CGFloat(batteryLevel / 100), height: 10)
                    }
                }
                .frame(height: 10)
            }
            .padding(10)
        }
    }
    
    private var mediumView: some View {
        ZStack {
            Color.black
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 36, height: 20)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(batteryColor)
                        .frame(width: 32 * CGFloat(batteryLevel / 100), height: 16)
                        .padding(.horizontal, 2)
                    Text("\(Int(batteryLevel))")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.batteryIsCharging ? String(localized: "CHARGING") : String(localized: "BATTERY"))
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                    Text(String(format: String(localized: "BATTERY_REMAINING"), Int(batteryLevel)))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(12)
        }
    }
    
    private var batteryColor: Color {
        if batteryLevel < 20 { return .red }
        if batteryLevel < 50 { return .orange }
        if entry.batteryIsCharging { return .green }
        return .cyan
    }

    private var batteryLevel: Double {
        min(100, max(0, entry.batteryLevel))
    }
}
