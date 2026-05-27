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
    private var flashWindow: NSWindow?
    
    private init() {}
    
    func startChaosAnimation(mainWindow: NSWindow, completion: @escaping () -> Void) {
        guard !isAnimating else {
            completion()
            return
        }
        isAnimating = true
        self.mainWindow = mainWindow
        pendingCompletion = completion
        closedCount = 0
        totalWindows = PreferencesManager.shared.preferences.chaosParticleCount
        
        guard let screen = NSScreen.main else {
            finish()
            return
        }
        
        let screenFrame = screen.frame
        let screenCenter = CGPoint(x: screenFrame.midX, y: screenFrame.midY)
        
        // Create windows
        let windows = createDenseGlitchWindows(screenFrame: screenFrame, count: totalWindows)
        glitchWindows = windows
        
        // Sort by distance from center: closer first (wave outward)
        let windowsByDistance = windows.enumerated().sorted { a, b in
            let distA = hypot(a.1.frame.midX - screenCenter.x, a.1.frame.midY - screenCenter.y)
            let distB = hypot(b.1.frame.midX - screenCenter.x, b.1.frame.midY - screenCenter.y)
            return distA < distB
        }
        
        // Initial SFX burst (more intense)
        SoundEffectManager.shared.playGlitchBurst(count: 10)
        
        // Screen flash effect (white flash)
        performScreenFlash(screenFrame: screenFrame)
        SoundEffectManager.shared.playScreenFlashSound()
        
        // MARK: - Show Phase: center outward wave (slower)
        for (showOrder, (_, window)) in windowsByDistance.enumerated() {
            let showDelay = Double(showOrder) * Double.random(in: 0.015...0.03)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + showDelay) { [weak self] in
                guard let self = self, self.isAnimating else { return }
                
                window.alphaValue = 0
                window.makeKeyAndOrderFront(nil)
                
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.08
                    window.animator().alphaValue = 1.0
                }
                
                self.jitterWindow(window)
                
                // Reveal main window gradually as wave expands
                if showOrder == 30 {
                    NSAnimationContext.runAnimationGroup { ctx in
                        ctx.duration = 0.8
                        mainWindow.animator().alphaValue = 0.4
                    }
                } else if showOrder == 80 {
                    NSAnimationContext.runAnimationGroup { ctx in
                        ctx.duration = 1.2
                        mainWindow.animator().alphaValue = 0.6
                    }
                }
                
                // SFX: dense sound during spawn
                if showOrder % 8 == 0 && showOrder > 0 {
                    SoundEffectManager.shared.playGlitchSound()
                }
                // Occasional burst
                if showOrder == 25 || showOrder == 60 || showOrder == 110 || showOrder == 160 {
                    SoundEffectManager.shared.playGlitchBurst(count: 4)
                }
                
                // Occasional screen flash with sound
                if showOrder == 40 || showOrder == 100 || showOrder == 160 {
                    self.performScreenFlash(screenFrame: screenFrame, color: .red)
                    SoundEffectManager.shared.playScreenFlashSound()
                }
                
                // Random chaos: flash window alpha
                self.flashGlitchWindow(window)
            }
        }
        
        // MARK: - Close Phase: outer inward (faster)
        let windowsByDistanceReversed = Array(windowsByDistance.reversed())
        for (closeOrder, (_, window)) in windowsByDistanceReversed.enumerated() {
            let closeDelay = 3.5 + Double(closeOrder) * Double.random(in: 0.012...0.022)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + closeDelay) { [weak self] in
                guard let self = self else { return }
                
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.035
                    window.animator().alphaValue = 0
                } completionHandler: {
                    window.orderOut(nil)
                    self.closedCount += 1
                    
                    let progress = Double(self.closedCount) / Double(self.totalWindows)
                    let targetAlpha = 0.6 + (progress * 0.4)
                    mainWindow.alphaValue = targetAlpha
                    
                    // SFX during close phase
                    if closeOrder == 20 || closeOrder == 80 || closeOrder == 150 {
                        SoundEffectManager.shared.playCloseBurst(count: 4)
                    }
                    
                    if self.closedCount >= self.totalWindows {
                        SoundEffectManager.shared.playHackerRevealSound()
                        NSAnimationContext.runAnimationGroup { ctx in
                            ctx.duration = 0.25
                            mainWindow.animator().alphaValue = 1.0
                        } completionHandler: {
                            self.finish()
                        }
                    }
                }
            }
        }
        
        // Safety timeout: force cleanup after 10s regardless of state
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { [weak self] in
            guard let self = self, self.isAnimating else { return }
            self.finish()
        }
    }
    
    func cancelAnimation() {
        isAnimating = false
        // Force-close every window, including any stragglers
        for window in glitchWindows {
            window.alphaValue = 0
            window.orderOut(nil)
        }
        glitchWindows.removeAll()
        flashWindow?.orderOut(nil)
        flashWindow = nil
        mainWindow?.alphaValue = 1.0
        pendingCompletion?()
        pendingCompletion = nil
    }
    
    private func finish() {
        isAnimating = false
        // Force-close any windows that might still be visible
        for window in glitchWindows {
            window.alphaValue = 0
            window.orderOut(nil)
        }
        glitchWindows.removeAll()
        flashWindow?.orderOut(nil)
        flashWindow = nil
        pendingCompletion?()
        pendingCompletion = nil
    }
    
    // MARK: - Screen Flash
    
    private func performScreenFlash(screenFrame: NSRect, color: NSColor = .white) {
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .statusBar
        window.backgroundColor = color
        window.isOpaque = true
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        flashWindow = window
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.03
            window.animator().alphaValue = 0.25
        } completionHandler: {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.08
                window.animator().alphaValue = 0
            } completionHandler: {
                window.orderOut(nil)
                if self.flashWindow === window {
                    self.flashWindow = nil
                }
            }
        }
    }
    
    // MARK: - Dense Window Creation
    
    private func createDenseGlitchWindows(screenFrame: NSRect, count: Int) -> [NSWindow] {
        var result: [NSWindow] = []
        
        // Sparse grid: 8x8 = 64, windows can overflow grid boundaries
        let cols = 8
        let rows = 8
        let cellW = screenFrame.width / CGFloat(cols)
        let cellH = screenFrame.height / CGFloat(rows)
        
        var index = 0
        let hackerIndex = 28  // Slightly off-center of 8x8 grid
        
        for row in 0..<rows {
            for col in 0..<cols {
                guard index < count else { break }
                
                let baseX = screenFrame.minX + CGFloat(col) * cellW
                let baseY = screenFrame.minY + CGFloat(row) * cellH
                
                if index == hackerIndex {
                    let w: CGFloat = 320
                    let h: CGFloat = 150
                    let x = baseX + (cellW - w) / 2
                    let y = baseY + (cellH - h) / 2
                    let window = makeHackerWindow(frame: NSRect(x: x, y: y, width: w, height: h))
                    result.append(window)
                } else {
                    // Extreme size diversity: tiny to massive, overflowing grid
                    let sizeRoll = Int.random(in: 0...19)
                    let (w, h): (CGFloat, CGFloat)
                    switch sizeRoll {
                    case 0: // tiny
                        w = CGFloat.random(in: cellW * 0.15...cellW * 0.3)
                        h = CGFloat.random(in: cellH * 0.15...cellH * 0.3)
                    case 1...3: // small
                        w = CGFloat.random(in: cellW * 0.3...cellW * 0.7)
                        h = CGFloat.random(in: cellH * 0.3...cellH * 0.7)
                    case 4...8: // medium
                        w = CGFloat.random(in: cellW * 0.7...cellW * 1.5)
                        h = CGFloat.random(in: cellH * 0.7...cellH * 1.5)
                    case 9...14: // large (overflow grid)
                        w = CGFloat.random(in: cellW * 1.2...cellW * 3.0)
                        h = CGFloat.random(in: cellH * 1.2...cellH * 3.0)
                    default: // massive (cover multiple cells)
                        w = CGFloat.random(in: cellW * 2.5...cellW * 5.0)
                        h = CGFloat.random(in: cellH * 2.5...cellH * 5.0)
                    }
                    
                    // Allow overflow beyond grid and screen edges
                    let x = baseX + CGFloat.random(in: -cellW * 1.5...(cellW * 0.5))
                    let y = baseY + CGFloat.random(in: -cellH * 1.5...(cellH * 0.5))
                    let window = makeGlitchWindow(frame: NSRect(x: x, y: y, width: w, height: h), index: index)
                    result.append(window)
                }
                index += 1
            }
            guard index < count else { break }
        }
        
        // Scatter: aggressive full-screen coverage including way off-screen
        while index < count {
            let sizeRoll = Int.random(in: 0...19)
            let (w, h): (CGFloat, CGFloat)
            switch sizeRoll {
            case 0: // tiny speck
                w = CGFloat.random(in: 20...60)
                h = CGFloat.random(in: 15...45)
            case 1...3: // small
                w = CGFloat.random(in: 60...140)
                h = CGFloat.random(in: 45...110)
            case 4...8: // medium
                w = CGFloat.random(in: 140...350)
                h = CGFloat.random(in: 110...280)
            case 9...14: // large
                w = CGFloat.random(in: 350...700)
                h = CGFloat.random(in: 280...550)
            default: // massive (can cover quarter screen)
                w = CGFloat.random(in: 700...1500)
                h = CGFloat.random(in: 550...1200)
            }
            
            // Cover full screen + significant overflow beyond edges
            let x = screenFrame.minX + CGFloat.random(in: -400...(screenFrame.width - w + 400))
            let y = screenFrame.minY + CGFloat.random(in: -400...(screenFrame.height - h + 400))
            
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
    
    private func makeHackerWindow(frame: NSRect) -> NSWindow {
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
        
        window.contentView = NSHostingView(rootView:
            HackerRevealView()
                .overlay(
                    Rectangle()
                        .stroke(Color.green.opacity(0.4), lineWidth: 1)
                )
        )
        
        return window
    }
    
    private func jitterWindow(_ window: NSWindow) {
        let originalOrigin = window.frame.origin
        let originalSize = window.frame.size
        let count = Int.random(in: 5...12)
        
        // Chaotic jitter: position, size, and alpha all fluctuating
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.03) {
                guard window.isVisible else { return }
                let dx = CGFloat.random(in: -25...25)
                let dy = CGFloat.random(in: -25...25)
                let dw = CGFloat.random(in: -20...20)
                let dh = CGFloat.random(in: -15...15)
                let dAlpha = CGFloat.random(in: -0.3...0.3)
                
                window.setFrameOrigin(NSPoint(x: originalOrigin.x + dx, y: originalOrigin.y + dy))
                window.setContentSize(NSSize(width: max(20, originalSize.width + dw), height: max(15, originalSize.height + dh)))
                window.alphaValue = max(0.3, min(1.0, window.alphaValue + dAlpha))
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(count) * 0.03 + 0.02) {
            guard window.isVisible else { return }
            window.setFrameOrigin(originalOrigin)
            window.setContentSize(originalSize)
            window.alphaValue = 1.0
        }
    }
    
    private func flashGlitchWindow(_ window: NSWindow) {
        // Random alpha flicker after window appears
        let flashCount = Int.random(in: 2...5)
        for i in 0..<flashCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08 + Double.random(in: 0.1...0.5)) {
                guard window.isVisible else { return }
                let targetAlpha = CGFloat.random(in: 0.2...0.9)
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.02
                    window.animator().alphaValue = targetAlpha
                }
            }
        }
    }
}
