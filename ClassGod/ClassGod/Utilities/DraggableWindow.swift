//
//  DraggableWindow.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Cocoa

/// A borderless window that can be dragged from anywhere in its content area.
class DraggableWindow: NSWindow {
    private var initialLocation: NSPoint?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func mouseDown(with event: NSEvent) {
        initialLocation = event.locationInWindow
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let initial = initialLocation else {
            super.mouseDragged(with: event)
            return
        }

        let current = event.locationInWindow
        let deltaX = current.x - initial.x
        let deltaY = current.y - initial.y

        var frame = self.frame
        frame.origin.x += deltaX
        frame.origin.y += deltaY
        setFrameOrigin(frame.origin)
    }

    override func mouseUp(with event: NSEvent) {
        initialLocation = nil
        super.mouseUp(with: event)
    }
}
