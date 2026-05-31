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
            Text(entry.asciiArt)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.cyan.opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(10)
        }
    }
}
