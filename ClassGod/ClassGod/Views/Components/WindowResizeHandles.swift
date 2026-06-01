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

    private enum Corner: String, CaseIterable {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Allow events to pass through to content below; we only show visual handles
                // DraggableWindow handles actual resize via mouseDown/mouseDragged
                // Top-left
                cornerPath(for: .topLeft, in: geo)
                    .stroke(color, lineWidth: lineWidth)

                // Top-right
                cornerPath(for: .topRight, in: geo)
                    .stroke(color, lineWidth: lineWidth)

                // Bottom-left
                cornerPath(for: .bottomLeft, in: geo)
                    .stroke(color, lineWidth: lineWidth)

                // Bottom-right
                cornerPath(for: .bottomRight, in: geo)
                    .stroke(color, lineWidth: lineWidth)
            }
        }
        .allowsHitTesting(false)
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
