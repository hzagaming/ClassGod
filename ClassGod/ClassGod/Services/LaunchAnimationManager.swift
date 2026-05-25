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
    private weak var mainWindow: NSWindow?
    
    private init() {}
    
    /// Start the chaos glitch animation sequence.
    /// - mainWindow: the main UI window, already created at alpha=0, bottom layer
    /// - completion: called when all glitch windows close and main window is fully revealed
    func startChaosAnimation(mainWindow: NSWindow, completion: @escaping () -> Void) {
        guard !isAnimating else {
            completion()
            return
        }
        isAnimating = true
        self.mainWindow = mainWindow
        pendingCompletion = completion
        closedCount = 0
        totalWindows = 50
        
        guard let screen = NSScreen.main else {
            finish()
            return
        }
        
        let screenFrame = screen.visibleFrame
        let windows = createDenseGlitchWindows(screenFrame: screenFrame, count: totalWindows)
        glitchWindows = windows
        
        // Play initial glitch burst SFX
        SoundEffectManager.shared.playGlitchBurst(count: 5)
        
        // Show windows with rapid stagger + reveal main window around #3-4
        for (i, window) in windows.enumerated() {
            let showDelay = Double(i) * Double.random(in: 0.02...0.06)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + showDelay) { [weak self] in
                guard let self = self, self.isAnimating else { return }
                
                window.alphaValue = 0
                window.makeKeyAndOrderFront(nil)
                
                // Fade in glitch window
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.04
                    window.animator().alphaValue = 1.0
                }
                
                // Jitter effect
                self.jitterWindow(window)
                
                // Reveal main window starting at window #3, blend in with the chaos
                if i == 3 {
                    NSAnimationContext.runAnimationGroup { ctx in
                        ctx.duration = 0.8
                        mainWindow.animator().alphaValue = 0.45
                    }
                } else if i == 8 {
                    NSAnimationContext.runAnimationGroup { ctx in
                        ctx.duration = 1.2
                        mainWindow.animator().alphaValue = 0.65
                    }
                }
                
                // Play random glitch SFX on some windows
                if i % 4 == 0 {
                    SoundEffectManager.shared.playGlitchSound()
                }
            }
        }
        
        // Close windows with stagger, reveal main window fully at the end
        for (i, window) in windows.enumerated() {
            let closeDelay = 2.0 + Double(i) * Double.random(in: 0.08...0.25)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + closeDelay) { [weak self] in
                guard let self = self else { return }
                
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.06
                    window.animator().alphaValue = 0
                } completionHandler: {
                    window.orderOut(nil)
                    self.closedCount += 1
                    
                    // Gradually reveal main window as glitch windows close
                    let progress = Double(self.closedCount) / Double(self.totalWindows)
                    let targetAlpha = 0.65 + (progress * 0.35)
                    mainWindow.alphaValue = targetAlpha
                    
                    if self.closedCount >= self.totalWindows {
                        // Final reveal
                        NSAnimationContext.runAnimationGroup { ctx in
                            ctx.duration = 0.3
                            mainWindow.animator().alphaValue = 1.0
                        } completionHandler: {
                            self.finish()
                        }
                    }
                }
            }
        }
    }
    
    func cancelAnimation() {
        isAnimating = false
        glitchWindows.forEach { $0.orderOut(nil) }
        glitchWindows.removeAll()
        mainWindow?.alphaValue = 1.0
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
    
    private func createDenseGlitchWindows(screenFrame: NSRect, count: Int) -> [NSWindow] {
        var result: [NSWindow] = []
        
        let cols = 8
        let rows = 6
        let cellW = screenFrame.width / CGFloat(cols)
        let cellH = screenFrame.height / CGFloat(rows)
        
        var index = 0
        
        // Grid-based placement for uniform coverage (48 slots)
        for row in 0..<rows {
            for col in 0..<cols {
                guard index < count else { break }
                let w = CGFloat.random(in: cellW * 0.8...cellW * 1.35)
                let h = CGFloat.random(in: cellH * 0.8...cellH * 1.35)
                let baseX = screenFrame.minX + CGFloat(col) * cellW
                let baseY = screenFrame.minY + CGFloat(row) * cellH
                let x = baseX + CGFloat.random(in: -40...(cellW * 0.4))
                let y = baseY + CGFloat.random(in: -40...(cellH * 0.4))
                
                let window = makeGlitchWindow(frame: NSRect(x: x, y: y, width: w, height: h), index: index)
                result.append(window)
                index += 1
            }
            guard index < count else { break }
        }
        
        // Extra random windows to fill remaining count
        while index < count {
            let w = CGFloat.random(in: 220...420)
            let h = CGFloat.random(in: 140...280)
            let x = screenFrame.minX + CGFloat.random(in: -60...(screenFrame.width - w + 60))
            let y = screenFrame.minY + CGFloat.random(in: -60...(screenFrame.height - h + 60))
            
            let window = makeGlitchWindow(frame: NSRect(x: x, y: y, width: w, height: h), index: index)
            result.append(window)
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
        let count = Int.random(in: 3...6)
        
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                guard window.isVisible else { return }
                let dx = CGFloat.random(in: -8...8)
                let dy = CGFloat.random(in: -8...8)
                window.setFrameOrigin(NSPoint(x: originalOrigin.x + dx, y: originalOrigin.y + dy))
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(count) * 0.04 + 0.02) {
            guard window.isVisible else { return }
            window.setFrameOrigin(originalOrigin)
        }
    }
}
