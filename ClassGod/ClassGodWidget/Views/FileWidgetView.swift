//
//  FileWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct FileWidgetView: View {
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
                    Text("FILES")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(entry.filePaths.prefix(3)) { file in
                        HStack(spacing: 6) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.cyan.opacity(0.6))
                            Text(file.name)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.75))
                                .lineLimit(1)
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
            VStack(spacing: 6) {
                HStack {
                    Text("RECENT FILES")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.filePaths.prefix(5)) { file in
                        HStack(spacing: 8) {
                            Image(systemName: iconForFile(file.name))
                                .font(.system(size: 12))
                                .foregroundStyle(.cyan.opacity(0.6))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(file.name)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .lineLimit(1)
                                Text(file.path)
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.3))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
    }
    
    private func iconForFile(_ name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.text.fill"
        case "jpg", "jpeg", "png", "gif": return "photo.fill"
        case "mp4", "mov", "avi": return "film.fill"
        case "zip", "rar", "7z": return "archivebox.fill"
        case "txt", "md", "rtf": return "doc.plaintext.fill"
        default: return "doc.fill"
        }
    }
}
