//
//  DraggableWindow.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Cocoa

/// A borderless window that can be dragged from anywhere in its content area.
class DraggableWindow: NSWindow {
    private var initialMouseLocation: NSPoint?
    private var initialWindowOrigin: NSPoint?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func mouseDown(with event: NSEvent) {
        initialMouseLocation = NSEvent.mouseLocation
        initialWindowOrigin = self.frame.origin
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let initialMouse = initialMouseLocation,
              let initialOrigin = initialWindowOrigin else {
            super.mouseDragged(with: event)
            return
        }

        let currentMouse = NSEvent.mouseLocation
        let deltaX = currentMouse.x - initialMouse.x
        let deltaY = currentMouse.y - initialMouse.y

        let newOrigin = NSPoint(
            x: initialOrigin.x + deltaX,
            y: initialOrigin.y + deltaY
        )
        setFrameOrigin(newOrigin)
    }

    override func mouseUp(with event: NSEvent) {
        initialMouseLocation = nil
        initialWindowOrigin = nil
        super.mouseUp(with: event)
        
        NotificationCenter.default.post(
            name: .draggableWindowDidMove,
            object: self,
            userInfo: ["origin": self.frame.origin]
        )
    }
}
