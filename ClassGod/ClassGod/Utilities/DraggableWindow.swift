//
//  DraggableWindow.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Cocoa

/// A borderless window that can be dragged from anywhere in its content area,
/// and resized from any corner or edge.
class DraggableWindow: NSWindow {

    // MARK: - Resize Configuration

    private let resizeMargin: CGFloat = 12
    private let minWindowSize = NSSize(width: 200, height: 120)

    private enum ResizeEdge {
        case none
        case top, bottom, left, right
        case topLeft, topRight, bottomLeft, bottomRight
    }

    // MARK: - State

    private var initialMouseLocation: NSPoint?
    private var initialWindowOrigin: NSPoint?
    private var initialWindowFrame: NSRect?
    private var currentResizeEdge: ResizeEdge = .none
    private var trackingArea: NSTrackingArea?
    private var isDraggingWindow: Bool = false
    private static let dragThreshold: CGFloat = 4

    // MARK: - Overrides

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func becomeKey() {
        super.becomeKey()
        setupTrackingArea()
    }

    override func resignKey() {
        super.resignKey()
        // Keep tracking area active so resize cursors work even when window is not key
    }

    // MARK: - Tracking Area

    private func setupTrackingArea() {
        removeTrackingAreaIfNeeded()
        guard let contentView = self.contentView else { return }

        let area = NSTrackingArea(
            rect: contentView.bounds,
            options: [.activeAlways, .mouseMoved, .cursorUpdate, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        contentView.addTrackingArea(area)
        trackingArea = area
    }

    override var contentView: NSView? {
        didSet {
            if contentView !== oldValue {
                setupTrackingArea()
            }
        }
    }

    private func removeTrackingAreaIfNeeded() {
        if let area = trackingArea, let contentView = self.contentView {
            contentView.removeTrackingArea(area)
            trackingArea = nil
        }
    }

    // MARK: - Mouse Events

    override func mouseMoved(with event: NSEvent) {
        updateCursor(for: event.locationInWindow)
    }

    override func cursorUpdate(with event: NSEvent) {
        updateCursor(for: event.locationInWindow)
    }

    override func mouseDown(with event: NSEvent) {
        let edge = resizeEdge(at: event.locationInWindow)
        currentResizeEdge = edge
        isDraggingWindow = false

        if edge != .none {
            initialMouseLocation = NSEvent.mouseLocation
            initialWindowFrame = self.frame
        } else {
            initialMouseLocation = NSEvent.mouseLocation
            initialWindowOrigin = self.frame.origin
        }
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let initialMouse = initialMouseLocation else {
            super.mouseDragged(with: event)
            return
        }

        let currentMouse = NSEvent.mouseLocation
        let deltaX = currentMouse.x - initialMouse.x
        let deltaY = currentMouse.y - initialMouse.y

        if currentResizeEdge != .none,
           let initialFrame = initialWindowFrame {
            performResize(initialFrame: initialFrame, deltaX: deltaX, deltaY: deltaY)
            return
        }

        // For content-area drags: pass events to SwiftUI until threshold is exceeded
        // This allows buttons to receive clicks and ScrollViews to scroll
        if !isDraggingWindow {
            let distance = hypot(deltaX, deltaY)
            if distance < Self.dragThreshold {
                super.mouseDragged(with: event)
                return
            }
            isDraggingWindow = true
        }

        if let initialOrigin = initialWindowOrigin {
            let newOrigin = NSPoint(
                x: initialOrigin.x + deltaX,
                y: initialOrigin.y + deltaY
            )
            setFrameOrigin(newOrigin)
        }
    }

    override func mouseUp(with event: NSEvent) {
        initialMouseLocation = nil
        initialWindowOrigin = nil
        initialWindowFrame = nil
        currentResizeEdge = .none
        isDraggingWindow = false
        super.mouseUp(with: event)

        NotificationCenter.default.post(
            name: .draggableWindowDidMove,
            object: self,
            userInfo: ["origin": self.frame.origin]
        )
    }

    // MARK: - Resize Logic

    private func resizeEdge(at point: NSPoint) -> ResizeEdge {
        let w = self.frame.size.width
        let h = self.frame.size.height

        let onLeft   = point.x <= resizeMargin
        let onRight  = point.x >= w - resizeMargin
        let onBottom = point.y <= resizeMargin
        let onTop    = point.y >= h - resizeMargin

        if onTop    && onLeft  { return .topLeft }
        if onTop    && onRight { return .topRight }
        if onBottom && onLeft  { return .bottomLeft }
        if onBottom && onRight { return .bottomRight }
        if onTop    { return .top }
        if onBottom { return .bottom }
        if onLeft   { return .left }
        if onRight  { return .right }
        return .none
    }

    private func updateCursor(for point: NSPoint) {
        switch resizeEdge(at: point) {
        case .topLeft, .bottomRight:
            NSCursor.resizeUpDown.set() // Actually should be diagonal; macOS doesn't have public diagonal cursors
        case .topRight, .bottomLeft:
            NSCursor.resizeLeftRight.set() // Fallback
        case .left, .right:
            NSCursor.resizeLeftRight.set()
        case .top, .bottom:
            NSCursor.resizeUpDown.set()
        case .none:
            NSCursor.arrow.set()
        }
    }

    private func performResize(initialFrame: NSRect, deltaX: CGFloat, deltaY: CGFloat) {
        var newFrame = initialFrame

        switch currentResizeEdge {
        case .right:
            newFrame.size.width = max(minWindowSize.width, initialFrame.size.width + deltaX)

        case .left:
            let newWidth = max(minWindowSize.width, initialFrame.size.width - deltaX)
            newFrame.origin.x = initialFrame.origin.x + initialFrame.size.width - newWidth
            newFrame.size.width = newWidth

        case .top:
            newFrame.size.height = max(minWindowSize.height, initialFrame.size.height + deltaY)

        case .bottom:
            let newHeight = max(minWindowSize.height, initialFrame.size.height - deltaY)
            newFrame.origin.y = initialFrame.origin.y + initialFrame.size.height - newHeight
            newFrame.size.height = newHeight

        case .topRight:
            newFrame.size.width  = max(minWindowSize.width,  initialFrame.size.width + deltaX)
            newFrame.size.height = max(minWindowSize.height, initialFrame.size.height + deltaY)

        case .topLeft:
            let newWidth = max(minWindowSize.width, initialFrame.size.width - deltaX)
            newFrame.origin.x = initialFrame.origin.x + initialFrame.size.width - newWidth
            newFrame.size.width = newWidth
            newFrame.size.height = max(minWindowSize.height, initialFrame.size.height + deltaY)

        case .bottomRight:
            newFrame.size.width = max(minWindowSize.width, initialFrame.size.width + deltaX)
            let newHeight = max(minWindowSize.height, initialFrame.size.height - deltaY)
            newFrame.origin.y = initialFrame.origin.y + initialFrame.size.height - newHeight
            newFrame.size.height = newHeight

        case .bottomLeft:
            let newWidth = max(minWindowSize.width, initialFrame.size.width - deltaX)
            newFrame.origin.x = initialFrame.origin.x + initialFrame.size.width - newWidth
            newFrame.size.width = newWidth
            let newHeight = max(minWindowSize.height, initialFrame.size.height - deltaY)
            newFrame.origin.y = initialFrame.origin.y + initialFrame.size.height - newHeight
            newFrame.size.height = newHeight

        case .none:
            break
        }

        setFrame(newFrame, display: true)
    }
}
