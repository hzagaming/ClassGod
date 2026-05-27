//
//  ClockWidget.swift
//  ClassGod
//

import SwiftUI
import Combine

struct ClockWidget: View {
    @State private var now = Date()
    @State private var timerCancellable: AnyCancellable?
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 0) {
                Text(timeString)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                
                Text(dateString)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(dayString)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan.opacity(0.7))
                Text(secondsString)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onAppear {
            timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    now = Date()
                }
        }
        .onDisappear {
            timerCancellable?.cancel()
            timerCancellable = nil
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: now)
    }
    
    private var secondsString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = ":ss"
        return formatter.string(from: now)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: now)
    }
    
    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: now).uppercased()
    }
}
