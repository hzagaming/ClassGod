//
//  AsciiArtWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct AsciiArtWidgetView: View {
    var entry: WidgetEntry
    
    var body: some View {
        ZStack {
            Color.black
            if entry.asciiArt.isEmpty {
                WidgetEmptyState(icon: "textformat", title: "WIDGET_EMPTY_ASCII", accentColor: entry.accentColor)
                    .padding(10)
            } else {
                Text(entry.asciiArt)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(entry.accentColor.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(8)
                    .minimumScaleFactor(0.65)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(10)
            }
        }
    }
}
