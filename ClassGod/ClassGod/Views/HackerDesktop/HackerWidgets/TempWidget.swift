//
//  TempWidget.swift
//  ClassGod
//

import SwiftUI

struct TempWidget: View {
    @ObservedObject var monitor = SystemMonitor.shared
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                tempGauge(label: "CPU", value: monitor.thermal.cpuTemp, icon: "cpu")
                tempGauge(label: "GPU", value: monitor.thermal.gpuTemp, icon: "cpu.fill")
            }
        }
        .padding(10)
    }
    
    private func tempGauge(label: String, value: Double, icon: String) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 6)
                
                let ratio = min(value / 100.0, 1.0)
                Circle()
                    .trim(from: 0, to: ratio)
                    .stroke(
                        tempColor(value),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: value)
                
                VStack(spacing: 0) {
                    Text("\(Int(value))°")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text(label)
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .frame(height: 60)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func tempColor(_ value: Double) -> Color {
        if value < 60 { return .green }
        if value < 80 { return .yellow }
        return .red
    }
}
