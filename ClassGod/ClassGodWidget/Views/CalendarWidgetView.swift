//
//  CalendarWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct CalendarWidgetView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family
    
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
                HStack {
                    Text(monthYearString)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                }
                
                // Day headers
                HStack(spacing: 0) {
                    ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                        Text(d)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.3))
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Calendar grid
                let days = daysInMonth()
                let today = Calendar.current.component(.day, from: entry.date)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                    ForEach(days, id: \.self) { day in
                        if day > 0 {
                            Text("\(day)")
                                .font(.system(size: 9, weight: day == today ? .bold : .medium, design: .monospaced))
                                .foregroundStyle(day == today ? .black : .white.opacity(0.7))
                                .frame(width: 18, height: 18)
                                .background(day == today ? Color.cyan : Color.clear)
                                .clipShape(Circle())
                        } else {
                            Color.clear.frame(width: 18, height: 18)
                        }
                    }
                }
            }
            .padding(10)
        }
    }
    
    private var largeView: some View {
        mediumView // Same layout, more space
    }
    
    private var monthYearString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: entry.date).uppercased()
    }
    
    private func daysInMonth() -> [Int] {
        let cal = Calendar.current
        let date = entry.date
        guard let range = cal.range(of: .day, in: .month, for: date),
              let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: date)) else {
            return []
        }
        let weekday = cal.component(.weekday, from: firstDay)
        var days = Array(repeating: 0, count: weekday - 1)
        days.append(contentsOf: Array(range))
        while days.count % 7 != 0 {
            days.append(0)
        }
        return days
    }
}
