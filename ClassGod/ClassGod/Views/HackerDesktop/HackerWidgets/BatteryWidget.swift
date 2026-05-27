//
//  BatteryWidget.swift
//  ClassGod
//

import SwiftUI

struct BatteryWidget: View {
    @ObservedObject var monitor = SystemMonitor.shared
    @State private var chargePulse = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Image(systemName: batteryIcon)
                        .font(.system(size: 24))
                        .foregroundStyle(batteryColor)
                    
                    if monitor.battery.isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .offset(x: 0, y: 0)
                            .opacity(chargePulse ? 1 : 0.5)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: chargePulse)
                            .onAppear { chargePulse = true }
                            .onDisappear { chargePulse = false }
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(monitor.battery.level * 100))%")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(monitor.battery.isCharging ? Color.green : Color.white.opacity(0.3))
                            .frame(width: 5, height: 5)
                        Text(monitor.battery.isCharging ? "CHARGING" : "ON BATTERY")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
                
                Spacer()
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.06))
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(batteryColor)
                        .frame(width: geo.size.width * monitor.battery.level)
                        .animation(.linear(duration: 0.5), value: monitor.battery.level)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: monitor.battery.isCharging ? geo.size.width * monitor.battery.level : 0)
                                .opacity(chargePulse ? 0.6 : 0.2)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: chargePulse)
                        )
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("CYCLES: \(monitor.battery.cycleCount)")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                Spacer()
                if monitor.battery.timeRemaining > 0 {
                    Text("\(monitor.battery.timeRemaining) MIN")
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .padding(10)
    }
    
    private var batteryIcon: String {
        let level = monitor.battery.level
        if monitor.battery.isCharging { return "battery.100.bolt" }
        if level > 0.75 { return "battery.100" }
        if level > 0.5 { return "battery.75" }
        if level > 0.25 { return "battery.50" }
        if level > 0.1 { return "battery.25" }
        return "battery.0"
    }
    
    private var batteryColor: Color {
        let level = monitor.battery.level
        if monitor.battery.isCharging { return .green }
        if level > 0.5 { return .cyan }
        if level > 0.2 { return .yellow }
        return .red
    }
}
