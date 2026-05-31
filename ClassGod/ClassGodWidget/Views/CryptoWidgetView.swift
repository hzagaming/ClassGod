//
//  CryptoWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct CryptoWidgetView: View {
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
                HStack {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                    Text("BTC")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                }
                
                Text(entry.cryptoBTC)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Divider().background(Color.white.opacity(0.06))
                
                HStack {
                    Image(systemName: "diamond.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.cyan)
                    Text("ETH")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                }
                
                Text(entry.cryptoETH)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(10)
        }
    }
    
    private var mediumView: some View {
        ZStack {
            Color.black
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.orange)
                        Text("BTC")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Text(entry.cryptoBTC)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.cyan)
                        Text("ETH")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Text(entry.cryptoETH)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                
                Spacer()
            }
            .padding(12)
        }
    }
}
