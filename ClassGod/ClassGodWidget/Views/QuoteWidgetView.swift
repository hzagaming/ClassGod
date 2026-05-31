//
//  QuoteWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct QuoteWidgetView: View {
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
                Text("❝")
                    .font(.system(size: 16))
                    .foregroundStyle(.cyan.opacity(0.4))
                
                Text(entry.quoteText)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text("— \(entry.quoteAuthor)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(10)
        }
    }
    
    private var mediumView: some View {
        ZStack {
            Color.black
            VStack(spacing: 8) {
                Text("❝")
                    .font(.system(size: 20))
                    .foregroundStyle(.cyan.opacity(0.4))
                
                Text(entry.quoteText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                Text("— \(entry.quoteAuthor)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(14)
        }
    }
}
