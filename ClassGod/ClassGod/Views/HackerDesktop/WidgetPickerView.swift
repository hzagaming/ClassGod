//
//  WidgetPickerView.swift
//  ClassGod
//

import SwiftUI

struct WidgetPickerView: View {
    var onAdd: (WidgetType) -> Void
    var onClose: () -> Void
    
    let columns = [
        GridItem(.adaptive(minimum: 90, maximum: 100), spacing: 10)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack(spacing: 0) {
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    onClose()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 24, height: 24)
                        .background(Color(white: 0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)
                
                Spacer()
                
                Text("Add Widget")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Color.clear.frame(width: 36, height: 24)
            }
            .padding(.vertical, 8)
            .background(Color(white: 0.03))
            
            Divider().background(Color.white.opacity(0.1))
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(WidgetType.allCases.enumerated()), id: \.element.id) { idx, type in
                        WidgetPickerCell(type: type, index: idx) {
                            SoundEffectManager.shared.playWidgetAdded()
                            HapticManager.shared.success()
                            onAdd(type)
                            onClose()
                        }
                    }
                }
                .padding(12)
            }
        }
        .frame(width: 340, height: 420)
        .background(Color.black)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 30, x: 0, y: 15)
    }
}

private struct WidgetPickerCell: View {
    let type: WidgetType
    let index: Int
    let action: () -> Void
    @State private var isHovered = false
    @State private var appeared = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(white: 0.06))
                        .frame(height: 70)
                    
                    Image(systemName: type.iconName)
                        .font(.system(size: 28))
                        .foregroundStyle(isHovered ? .cyan : .white.opacity(0.25))
                        .animation(.easeInOut(duration: 0.15), value: isHovered)
                }
                
                Text(type.displayName)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(isHovered ? .cyan : .white.opacity(0.6))
                    .animation(.easeInOut(duration: 0.15), value: isHovered)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isHovered ? Color.cyan.opacity(0.4) : Color.white.opacity(0.08),
                    lineWidth: isHovered ? 1.5 : 1
                )
        )
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.cyan.opacity(0.05) : Color.clear)
        )
        .scaleEffect(appeared ? (isHovered ? 1.04 : 1.0) : 0.9)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .animation(.spring(response: 0.35, dampingFraction: 0.7).delay(Double(index) * 0.02), value: appeared)
        .onHover { isHovered = $0 }
        .onAppear {
            appeared = true
        }
    }
}

#Preview {
    WidgetPickerView(onAdd: { _ in }, onClose: {})
        .frame(width: 340, height: 420)
        .background(Color.black)
}
