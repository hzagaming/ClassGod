//
//  WorldClockWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct WorldClockWidgetView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family
    
    private let cities = [
        ("NYC", "America/New_York"),
        ("LON", "Europe/London"),
        ("TKY", "Asia/Tokyo"),
        ("BJS", "Asia/Shanghai")
    ]
    
    var body: some View {
        switch family {
        case .systemMedium: mediumView
        case .systemLarge: largeView
        default: mediumView
        }
    }
    
    private var mediumView: some View {
        ZStack {
            Color.black
            VStack(spacing: 6) {
                Text("WORLD CLOCK")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(cities.prefix(3), id: \.0) { city in
                    HStack {
                        Text(city.0)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.cyan.opacity(0.7))
                            .frame(width: 32, alignment: .leading)
                        Text(timeInZone(city.1))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                }
            }
            .padding(10)
        }
    }
    
    private var largeView: some View {
        ZStack {
            Color.black
            VStack(spacing: 8) {
                Text("WORLD CLOCK")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(cities, id: \.0) { city in
                    HStack {
                        Text(city.0)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.cyan.opacity(0.7))
                            .frame(width: 36, alignment: .leading)
                        Text(timeInZone(city.1))
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(offsetInZone(city.1))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
            }
            .padding(14)
        }
    }
    
    private func timeInZone(_ id: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: id)
        return f.string(from: entry.date)
    }
    
    private func offsetInZone(_ id: String) -> String {
        guard let tz = TimeZone(identifier: id) else { return "" }
        let offset = tz.secondsFromGMT() / 3600
        return "GMT\(offset >= 0 ? "+" : "")\(offset)"
    }
}
