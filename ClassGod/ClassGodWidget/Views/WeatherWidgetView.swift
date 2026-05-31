//
//  WeatherWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct WeatherWidgetView: View {
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
            VStack(spacing: 4) {
                Image(systemName: entry.weatherCondition)
                    .font(.system(size: 28))
                    .foregroundStyle(.cyan)
                Text(entry.weatherTemp)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text(entry.weatherCity)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(8)
        }
    }
    
    private var mediumView: some View {
        ZStack {
            Color.black
            HStack(spacing: 16) {
                Image(systemName: entry.weatherCondition)
                    .font(.system(size: 36))
                    .foregroundStyle(.cyan)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.weatherTemp)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text(entry.weatherCity)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
            }
            .padding(12)
        }
    }
}
