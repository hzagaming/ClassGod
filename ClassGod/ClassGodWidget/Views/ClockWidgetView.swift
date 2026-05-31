//
//  ClockWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct ClockWidgetView: View {
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
            VStack(spacing: 2) {
                Text(timeString)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                Text(dateString)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(8)
        }
    }
    
    private var mediumView: some View {
        ZStack {
            Color.black
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(timeString)
                        .font(.system(size: 38, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text(dateString)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.45))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayString)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.8))
                    Text(secondsString)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                }
                
                Spacer()
            }
            .padding(12)
        }
    }
    
    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: entry.date)
    }
    
    private var secondsString: String {
        let f = DateFormatter()
        f.dateFormat = ":ss"
        return f.string(from: entry.date)
    }
    
    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: entry.date)
    }
    
    private var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: entry.date).uppercased()
    }
}
