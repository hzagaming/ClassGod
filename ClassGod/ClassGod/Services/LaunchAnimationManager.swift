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
        totalWindows = 200
        
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
                
                // Reveal main window starting at wave position 15
                if showOrder == 15 {
                    NSAnimationContext.runAnimationGroup { ctx in
                        ctx.duration = 0.8
                        mainWindow.animator().alphaValue = 0.4
                    }
                } else if showOrder == 40 {
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
                    SoundEffectManager.shared.playGlitchBurst(count: 3)
                }
                
                // Occasional screen flash with sound
                if showOrder == 40 || showOrder == 100 || showOrder == 160 {
                    self.performScreenFlash(screenFrame: screenFrame, color: .red)
                    SoundEffectManager.shared.playScreenFlashSound()
                }
            }
        }
        
        // MARK: - Close Phase: outer inward (faster)
        let windowsByDistanceReversed = Array(windowsByDistance.reversed())
        for (closeOrder, (_, window)) in windowsByDistanceReversed.enumerated() {
            let closeDelay = 2.5 + Double(closeOrder) * Double.random(in: 0.012...0.022)
            
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
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
        
        let cols = 14
        let rows = 14
        let cellW = screenFrame.width / CGFloat(cols)
        let cellH = screenFrame.height / CGFloat(rows)
        
        var index = 0
        let hackerIndex = 104  // Center of 14x14 grid: row 7, col 7 = 7*14+7 = 105, use 104 for slightly off-center
        
        for row in 0..<rows {
            for col in 0..<cols {
                guard index < count else { break }
                
                let window: NSWindow
                let baseX = screenFrame.minX + CGFloat(col) * cellW
                let baseY = screenFrame.minY + CGFloat(row) * cellH
                
                if index == hackerIndex {
                    let w: CGFloat = 280
                    let h: CGFloat = 130
                    let x = baseX + (cellW - w) / 2
                    let y = baseY + (cellH - h) / 2
                    window = makeHackerWindow(frame: NSRect(x: x, y: y, width: w, height: h))
                } else {
                    // Size diversity: more medium + large
                    let sizeRoll = Int.random(in: 0...19)
                    let (w, h): (CGFloat, CGFloat)
                    switch sizeRoll {
                    case 0: // tiny 5%
                        w = CGFloat.random(in: cellW * 0.18...cellW * 0.35)
                        h = CGFloat.random(in: cellH * 0.18...cellH * 0.35)
                    case 1...2: // small 10%
                        w = CGFloat.random(in: cellW * 0.35...cellW * 0.6)
                        h = CGFloat.random(in: cellH * 0.35...cellH * 0.6)
                    case 3...9: // medium 35%
                        w = CGFloat.random(in: cellW * 0.6...cellW * 1.1)
                        h = CGFloat.random(in: cellH * 0.6...cellH * 1.1)
                    case 10...15: // large 30%
                        w = CGFloat.random(in: cellW * 1.1...cellW * 1.8)
                        h = CGFloat.random(in: cellH * 1.1...cellH * 1.8)
                    default: // huge 20%
                        w = CGFloat.random(in: cellW * 1.8...cellW * 3.2)
                        h = CGFloat.random(in: cellH * 1.8...cellH * 3.2)
                    }
                    
                    let x = baseX + CGFloat.random(in: -60...(cellW * 0.35))
                    let y = baseY + CGFloat.random(in: -60...(cellH * 0.35))
                    window = makeGlitchWindow(frame: NSRect(x: x, y: y, width: w, height: h), index: index)
                }
                result.append(window)
                index += 1
            }
            guard index < count else { break }
        }
        
        // Fill remaining with random scatter (diverse sizes, more medium/large)
        while index < count {
            let sizeRoll = Int.random(in: 0...19)
            let (w, h): (CGFloat, CGFloat)
            switch sizeRoll {
            case 0: // tiny
                w = CGFloat.random(in: 50...100)
                h = CGFloat.random(in: 40...80)
            case 1...2: // small
                w = CGFloat.random(in: 100...180)
                h = CGFloat.random(in: 80...140)
            case 3...9: // medium
                w = CGFloat.random(in: 180...300)
                h = CGFloat.random(in: 140...220)
            case 10...15: // large
                w = CGFloat.random(in: 300...480)
                h = CGFloat.random(in: 220...360)
            default: // huge
                w = CGFloat.random(in: 480...800)
                h = CGFloat.random(in: 360...600)
            }
            
            let x = screenFrame.minX + CGFloat.random(in: -100...(screenFrame.width - w + 100))
            let y = screenFrame.minY + CGFloat.random(in: -100...(screenFrame.height - h + 100))
            
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
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.backgroundColor = .black
        window.hasShadow = true
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = false
        window.isOpaque = true
        
        let titles = [
            "System", "Security", "Finder", "Kernel", "Terminal",
            "Console", "Alert", "Warning", "Error", "Process",
            "Daemon", "Network", "Memory", "Disk", "CPU",
            "Thread", "Module", "Service", "Handler", "Manager"
        ]
        window.title = titles[index % titles.count]
        
        let contentView = type.view(seed: index)
        window.contentView = NSHostingView(rootView: contentView)
        
        return window
    }
    
    private func makeHackerWindow(frame: NSRect) -> NSWindow {
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.backgroundColor = .black
        window.hasShadow = true
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = false
        window.isOpaque = true
        window.title = "ClassGod"
        
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
