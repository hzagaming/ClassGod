//
//  NotesWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct NotesWidgetView: View {
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
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 9))
                        .foregroundStyle(.cyan.opacity(0.6))
                    Text("NOTE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                }
                
                if entry.noteContent.isEmpty {
                    WidgetEmptyState(icon: "note.text", title: "WIDGET_EMPTY_NOTES")
                } else {
                    Text(entry.noteContent)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .padding(10)
        }
    }
    
    private var mediumView: some View {
        ZStack {
            Color.black
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 10))
                        .foregroundStyle(.cyan.opacity(0.6))
                    Text("NOTES")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                }
                
                if entry.noteContent.isEmpty {
                    WidgetEmptyState(icon: "note.text", title: "WIDGET_EMPTY_NOTES")
                } else {
                    Text(entry.noteContent)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .padding(12)
        }
    }
}
