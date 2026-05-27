//
//  UptimeWidget.swift
//  ClassGod
//

import SwiftUI
import Combine

struct UptimeWidget: View {
    @ObservedObject var monitor = SystemMonitor.shared
    @State private var timerCancellable: AnyCancellable?
    @State private var tick = 0
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "timer")
                .font(.system(size: 16))
                .foregroundStyle(.cyan.opacity(0.6))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(monitor.uptimeString)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                
                Text("SYSTEM UPTIME")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
            
            Spacer()
            
            // Blinking dot
            Circle()
                .fill(tick % 2 == 0 ? Color.green.opacity(0.6) : Color.green.opacity(0.15))
                .frame(width: 6, height: 6)
                .animation(.easeInOut(duration: 0.5), value: tick)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onAppear {
            timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    tick += 1
                }
        }
        .onDisappear {
            timerCancellable?.cancel()
            timerCancellable = nil
        }
    }
}
