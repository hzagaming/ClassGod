//
//  LaunchAnimationManager.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Cocoa
import SwiftUI

final class LaunchAnimationManager {
    static let shared = LaunchAnimationManager()
    
    private var glitchWindows: [NSWindow] = []
    private var isAnimating = false
    private var pendingCompletion: (() -> Void)?
    private var closedCount = 0
    private var totalWindows = 0
    
    private init() {}
    
    /// Start the chaos glitch animation sequence.
    /// Main window should already be created below at alpha=0.
    func startChaosAnimation(completion: @escaping () -> Void) {
        guard !isAnimating else {
            completion()
            return
        }
        isAnimating = true
        pendingCompletion = completion
        closedCount = 0
        
        guard let screen = NSScreen.main else {
            finish()
            return
        }
        
        let screenFrame = screen.visibleFrame
        let windows = createDenseGlitchWindows(screenFrame: screenFrame)
        totalWindows = windows.count
        glitchWindows = windows.map { $0.window }
        
        // Show windows with rapid stagger
        for (window, showDelay, _) in windows {
            DispatchQueue.main.asyncAfter(deadline: .now() + showDelay) { [weak self] in
                guard let self = self, self.isAnimating else { return }
                window.alphaValue = 0
                window.orderFront(nil)
                
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.05
                    window.animator().alphaValue = 1.0
                }
                
                self.jitterWindow(window)
            }
        }
        
        // Close windows with stagger
        for (window, _, closeDelay) in windows {
            DispatchQueue.main.asyncAfter(deadline: .now() + closeDelay) { [weak self] in
                guard let self = self else { return }
                
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.08
                    window.animator().alphaValue = 0
                } completionHandler: {
                    window.orderOut(nil)
                    self.closedCount += 1
                    if self.closedCount >= self.totalWindows {
                        self.finish()
                    }
                }
            }
        }
    }
    
    func cancelAnimation() {
        isAnimating = false
        glitchWindows.forEach { $0.orderOut(nil) }
        glitchWindows.removeAll()
        pendingCompletion?()
        pendingCompletion = nil
    }
    
    private func finish() {
        isAnimating = false
        glitchWindows.removeAll()
        pendingCompletion?()
        pendingCompletion = nil
    }
    
    // MARK: - Dense Window Creation
    
    private func createDenseGlitchWindows(screenFrame: NSRect) -> [(window: NSWindow, showDelay: Double, closeDelay: Double)] {
        var result: [(window: NSWindow, showDelay: Double, closeDelay: Double)] = []
        
        let cols = 7
        let rows = 5
        let cellW = screenFrame.width / CGFloat(cols)
        let cellH = screenFrame.height / CGFloat(rows)
        
        var index = 0
        
        // Grid-based placement for uniform coverage
        for row in 0..<rows {
            for col in 0..<cols {
                let w = CGFloat.random(in: cellW * 0.85...cellW * 1.3)
                let h = CGFloat.random(in: cellH * 0.85...cellH * 1.3)
                let baseX = screenFrame.minX + CGFloat(col) * cellW
                let baseY = screenFrame.minY + CGFloat(row) * cellH
                let x = baseX + CGFloat.random(in: -30...cellW * 0.3)
                let y = baseY + CGFloat.random(in: -30...cellH * 0.3)
                
                let window = makeGlitchWindow(frame: NSRect(x: x, y: y, width: w, height: h), index: index)
                let showDelay = Double(index) * Double.random(in: 0.025...0.065)
                let closeDelay = Double(index) * Double.random(in: 0.12...0.35) + 1.2
                result.append((window, showDelay, closeDelay))
                index += 1
            }
        }
        
        // Extra random windows to fill gaps
        let extraCount = Int.random(in: 10...15)
        for _ in 0..<extraCount {
            let w = CGFloat.random(in: 250...450)
            let h = CGFloat.random(in: 160...300)
            let x = screenFrame.minX + CGFloat.random(in: -40...(screenFrame.width - w + 40))
            let y = screenFrame.minY + CGFloat.random(in: -40...(screenFrame.height - h + 40))
            
            let window = makeGlitchWindow(frame: NSRect(x: x, y: y, width: w, height: h), index: index)
            let showDelay = Double.random(in: 0.1...0.8)
            let closeDelay = Double.random(in: 1.5...3.5)
            result.append((window, showDelay, closeDelay))
            index += 1
        }
        
        return result
    }
    
    private func makeGlitchWindow(frame: NSRect, index: Int) -> NSWindow {
        let types = GlitchType.allCases
        let type = types[index % types.count]
        
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.backgroundColor = .black
        window.hasShadow = true
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = false
        window.isOpaque = true
        
        let contentView = type.view(seed: index)
        window.contentView = NSHostingView(rootView: contentView)
        
        return window
    }
    
    private func jitterWindow(_ window: NSWindow) {
        let originalOrigin = window.frame.origin
        let count = Int.random(in: 2...5)
        
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                guard window.isVisible else { return }
                let dx = CGFloat.random(in: -6...6)
                let dy = CGFloat.random(in: -6...6)
                window.setFrameOrigin(NSPoint(x: originalOrigin.x + dx, y: originalOrigin.y + dy))
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(count) * 0.05 + 0.03) {
            guard window.isVisible else { return }
            window.setFrameOrigin(originalOrigin)
        }
    }
}
