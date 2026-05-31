//
//  TodoWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct TodoWidgetView: View {
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
                    Text("TODO")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text("\(entry.todoItems.filter(\.isDone).count)/\(entry.todoItems.count)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.6))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.todoItems.prefix(3)) { item in
                        HStack(spacing: 6) {
                            Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                                .font(.system(size: 10))
                                .foregroundStyle(item.isDone ? .green : .white.opacity(0.4))
                            Text(item.text)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(item.isDone ? .white.opacity(0.3) : .white.opacity(0.8))
                                .strikethrough(item.isDone)
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
                    Text("TODO LIST")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text("\(entry.todoItems.filter(\.isDone).count)/\(entry.todoItems.count) done")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.6))
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(entry.todoItems.prefix(5)) { item in
                        HStack(spacing: 6) {
                            Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                                .font(.system(size: 11))
                                .foregroundStyle(item.isDone ? .green : .white.opacity(0.4))
                            Text(item.text)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(item.isDone ? .white.opacity(0.3) : .white.opacity(0.85))
                                .strikethrough(item.isDone)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(12)
        }
    }
}
