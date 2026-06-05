//
//  AppLauncherWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct AppLauncherWidgetView: View {
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
                    Text("APPS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(entry.appItems.prefix(4)) { app in
                        if let url = URL(string: "classgod://launch?bundle=\(app.bundleID)") {
                            Link(destination: url) {
                                VStack(spacing: 3) {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.cyan.opacity(0.7))
                                    Text(app.name)
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.6))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            .padding(10)
        }
    }
    
    private var mediumView: some View {
        ZStack {
            Color.black
            VStack(spacing: 8) {
                HStack {
                    Text("QUICK LAUNCH")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(entry.appItems.prefix(6)) { app in
                        if let url = URL(string: "classgod://launch?bundle=\(app.bundleID)") {
                            Link(destination: url) {
                                VStack(spacing: 4) {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.cyan.opacity(0.7))
                                    Text(app.name)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.65))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
    }
}
