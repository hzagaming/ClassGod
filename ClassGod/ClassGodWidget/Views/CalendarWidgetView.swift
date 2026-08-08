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
                
                HStack(spacing: 0) {
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.3))
                            .frame(maxWidth: .infinity)
                    }
                }
                
                let days = daysInMonth()
                let today = calendar.component(.day, from: entry.date)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                    ForEach(days, id: \.self) { day in
                        if day > 0 {
                            Text("\(day)")
                                .font(.system(size: 9, weight: day == today ? .bold : .medium, design: .monospaced))
                                .foregroundStyle(day == today ? .black : .white.opacity(0.7))
                                .frame(width: 18, height: 18)
                                .background(day == today ? entry.accentColor : Color.clear)
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
        mediumView
    }

    private var calendar: Calendar { .autoupdatingCurrent }

    private var weekdaySymbols: [String] {
        WidgetCalendarLayout.orderedWeekdaySymbols(
            calendar.veryShortStandaloneWeekdaySymbols,
            firstWeekday: calendar.firstWeekday
        )
    }
    
    private var monthYearString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: entry.date).uppercased()
    }
    
    private func daysInMonth() -> [Int] {
        let cal = calendar
        let date = entry.date
        guard let range = cal.range(of: .day, in: .month, for: date),
              let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: date)) else {
            return []
        }
        let weekday = cal.component(.weekday, from: firstDay)
        let leadingCount = WidgetCalendarLayout.leadingPlaceholderCount(
            weekday: weekday,
            firstWeekday: cal.firstWeekday
        )
        var days = Array(repeating: 0, count: leadingCount)
        days.append(contentsOf: Array(range))
        while days.count % 7 != 0 {
            days.append(0)
        }
        return days
    }
}
