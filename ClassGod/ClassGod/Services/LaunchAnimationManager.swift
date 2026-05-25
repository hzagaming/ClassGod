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
    
    private init() {}
    
    /// Start the chaos glitch animation sequence.
    /// Windows pop up one by one, shake around, then close one by one.
    /// Completion is called when the last window closes.
    func startChaosAnimation(completion: @escaping () -> Void) {
        guard !isAnimating else {
            completion()
            return
        }
        isAnimating = true
        
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        
        // Create 16-22 glitch windows
        let count = Int.random(in: 16...22)
        var windows: [(window: NSWindow, showDelay: Double, closeDelay: Double)] = []
        
        for i in 0..<count {
            let window = createGlitchWindow(screenFrame: screenFrame, index: i)
            let showDelay = Double(i) * Double.random(in: 0.04...0.12)
            let closeDelay = Double(count) * 0.1 + 1.0 + Double(i) * Double.random(in: 0.25...0.7)
            windows.append((window, showDelay, closeDelay))
            glitchWindows.append(window)
        }
        
        // Show windows with stagger
        for (window, showDelay, _) in windows {
            DispatchQueue.main.asyncAfter(deadline: .now() + showDelay) { [weak self] in
                guard let self = self else { return }
                window.alphaValue = 0
                window.makeKeyAndOrderFront(nil)
                
                // Fade in + scale pop
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.08
                    context.timingFunction = .init(name: .easeOut)
                    window.animator().alphaValue = 1.0
                }
                
                // Start jitter
                self.startWindowJitter(window)
            }
        }
        
        // Close windows with stagger
        for (window, _, closeDelay) in windows {
            DispatchQueue.main.asyncAfter(deadline: .now() + closeDelay) {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.1
                    window.animator().alphaValue = 0
                } completionHandler: {
                    window.orderOut(nil)
                }
            }
        }
        
        // Completion after last window closes
        let lastCloseDelay = windows.map { $0.closeDelay }.max() ?? 5.0
        DispatchQueue.main.asyncAfter(deadline: .now() + lastCloseDelay + 0.3) { [weak self] in
            self?.glitchWindows.removeAll()
            self?.isAnimating = false
            completion()
        }
    }
    
    func cancelAnimation() {
        glitchWindows.forEach { $0.orderOut(nil) }
        glitchWindows.removeAll()
        isAnimating = false
    }
    
    // MARK: - Private
    
    private func createGlitchWindow(screenFrame: NSRect, index: Int) -> NSWindow {
        let width = CGFloat.random(in: 220...360)
        let height = CGFloat.random(in: 130...240)
        
        // Random position within screen bounds with padding
        let padding: CGFloat = 40
        let x = CGFloat.random(in: screenFrame.minX + padding ... screenFrame.maxX - width - padding)
        let y = CGFloat.random(in: screenFrame.minY + padding ... screenFrame.maxY - height - padding)
        
        let types: [GlitchType] = [.terminal, .error, .crashReport, .matrixRain]
        let glitchType = types[index % types.count]
        
        let window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = randomWindowTitle(index: index)
        window.level = .floating
        window.backgroundColor = .black
        window.hasShadow = true
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        
        // Custom titlebar appearance
        window.titlebarAppearsTransparent = false
        
        let contentView = glitchType.view(seed: index)
        window.contentView = NSHostingView(rootView: contentView)
        
        return window
    }
    
    private func startWindowJitter(_ window: NSWindow) {
        guard glitchWindows.contains(where: { $0 === window }) else { return }
        
        let originalFrame = window.frame
        let jitterCount = Int.random(in: 3...8)
        
        for i in 0..<jitterCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                guard window.isVisible else { return }
                let dx = CGFloat.random(in: -6...6)
                let dy = CGFloat.random(in: -6...6)
                window.setFrameOrigin(NSPoint(
                    x: originalFrame.origin.x + dx,
                    y: originalFrame.origin.y + dy
                ))
            }
        }
        
        // Return to original position
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(jitterCount) * 0.08 + 0.05) {
            guard window.isVisible else { return }
            window.setFrameOrigin(originalFrame.origin)
        }
    }
    
    private func randomWindowTitle(index: Int) -> String {
        let titles = [
            "kernel_task",
            "launchd",
            "WindowServer",
            "syslogd",
            "bluetoothd",
            "coreaudiod",
            "securityd",
            "mdworker",
            "distnoted",
            "cfprefsd",
            "kextd",
            "watchdogd",
            "thermald",
            "powerd",
            "autofsd"
        ]
        let pid = Int.random(in: 100...99999)
        let base = titles[index % titles.count]
        let variants = ["", " [FAULT]", " [PANIC]", " [SEGV]", " [HANG]", " [KILL]"]
        return "\(base)\(variants[index % variants.count]) — pid \(pid)"
    }
}
