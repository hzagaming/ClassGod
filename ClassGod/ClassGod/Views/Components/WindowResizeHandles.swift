//
//  WindowResizeHandles.swift
//  ClassGod
//

import SwiftUI

/// Visual L-shaped corner handles indicating a window can be resized.
/// Place as an overlay on the window's root view.
struct WindowResizeHandles: View {
    var handleSize: CGFloat = 14
    var lineWidth: CGFloat = 1.5
    var color: Color = Color.white.opacity(0.25)
    var hoverColor: Color = Color.cyan.opacity(0.5)

    @State private var hoverCorner: Corner? = nil

    private enum Corner: String, CaseIterable {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Top-left
                cornerPath(for: .topLeft, in: geo)
                    .stroke(hoverCorner == .topLeft ? hoverColor : color, lineWidth: lineWidth)
                    .contentShape(Rectangle())
                    .onHover { hoverCorner = $0 ? .topLeft : nil }

                // Top-right
                cornerPath(for: .topRight, in: geo)
                    .stroke(hoverCorner == .topRight ? hoverColor : color, lineWidth: lineWidth)
                    .contentShape(Rectangle())
                    .onHover { hoverCorner = $0 ? .topRight : nil }

                // Bottom-left
                cornerPath(for: .bottomLeft, in: geo)
                    .stroke(hoverCorner == .bottomLeft ? hoverColor : color, lineWidth: lineWidth)
                    .contentShape(Rectangle())
                    .onHover { hoverCorner = $0 ? .bottomLeft : nil }

                // Bottom-right
                cornerPath(for: .bottomRight, in: geo)
                    .stroke(hoverCorner == .bottomRight ? hoverColor : color, lineWidth: lineWidth)
                    .contentShape(Rectangle())
                    .onHover { hoverCorner = $0 ? .bottomRight : nil }
            }
        }
    }

    private func cornerPath(for corner: Corner, in geo: GeometryProxy) -> Path {
        let w = geo.size.width
        let h = geo.size.height
        let s = handleSize

        var path = Path()
        switch corner {
        case .topLeft:
            path.move(to: CGPoint(x: 0, y: s))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: s, y: 0))
        case .topRight:
            path.move(to: CGPoint(x: w - s, y: 0))
            path.addLine(to: CGPoint(x: w, y: 0))
            path.addLine(to: CGPoint(x: w, y: s))
        case .bottomLeft:
            path.move(to: CGPoint(x: 0, y: h - s))
            path.addLine(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: s, y: h))
        case .bottomRight:
            path.move(to: CGPoint(x: w - s, y: h))
            path.addLine(to: CGPoint(x: w, y: h))
            path.addLine(to: CGPoint(x: w, y: h - s))
        }
        return path
    }
}

#Preview {
    ZStack {
        Color.black
        WindowResizeHandles()
    }
    .frame(width: 300, height: 200)
}
