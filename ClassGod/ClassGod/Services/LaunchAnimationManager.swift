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
    private var completion: (() -> Void)?
    
    private init() {}
    
    /// Start the chaos glitch animation sequence.
    /// Creates many large windows covering almost the entire screen,
    /// pops them up with stagger, shakes them, then closes one by one.
    /// The main window should already be created below (alpha=0).
    func startChaosAnimation(completion: @escaping () -> Void) {
        guard !isAnimating else {
            completion()
            return
        }
        isAnimating = true
        self.completion = completion
        
        guard let screen = NSScreen.main else {
            finishAnimation()
            return
        }
        
        let screenFrame = screen.visibleFrame
        
        // Create 28-36 glitch windows for dense screen coverage
        let count = Int.random(in: 28...36)
        var windows: [(window: NSWindow, showDelay: Double, closeDelay: Double)] = []
        
        for i in 0..<count {
            let window = createGlitchWindow(screenFrame: screenFrame, index: i, total: count)
            // Rapid-fire show: 0.03-0.08s stagger
            let showDelay = Double(i) * Double.random(in: 0.03...0.08)
            // Close after all shown + random stagger
            let closeDelay = Double(count) * 0.07 + 0.8 + Double(i) * Double.random(in: 0.15...0.45)
            windows.append((window, showDelay, closeDelay))
            glitchWindows.append(window)
        }
        
        // Batch-show windows with rapid stagger
        for (window, showDelay, _) in windows {
            DispatchQueue.main.asyncAfter(deadline: .now() + showDelay) { [weak self] in
                guard let self = self, self.isAnimating else { return }
                
                window.alphaValue = 0
                window.makeKeyAndOrderFront(nil)
                
                // Fast fade-in
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.06
                    context.timingFunction = .init(name: .easeOut)
                    window.animator().alphaValue = 1.0
                }
                
                // Jitter once
                self.jitterWindow(window)
            }
        }
        
        // Batch-close windows with stagger
        var closedCount = 0
        let totalWindows = windows.count
        
        for (window, _, closeDelay) in windows {
            DispatchQueue.main.asyncAfter(deadline: .now() + closeDelay) { [weak self] in
                guard let self = self else { return }
                
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.08
                    window.animator().alphaValue = 0
                } completionHandler: {
                    window.orderOut(nil)
                    closedCount += 1
                    if closedCount >= totalWindows {
                        self.finishAnimation()
                    }
                }
            }
        }
    }
    
    func cancelAnimation() {
        glitchWindows.forEach { $0.orderOut(nil) }
        glitchWindows.removeAll()
        isAnimating = false
        completion?()
        completion = nil
    }
    
    private func finishAnimation() {
        glitchWindows.removeAll()
        isAnimating = false
        completion?()
        completion = nil
    }
    
    // MARK: - Private
    
    private func createGlitchWindow(screenFrame: NSRect, index: Int, total: Int) -> NSWindow {
        // Larger windows for better coverage
        let width = CGFloat.random(in: 320...520)
        let height = CGFloat.random(in: 200...360)
        
        // Dense distribution: allow overlap and partial off-screen
        let minX = screenFrame.minX - 60
        let maxX = screenFrame.maxX + 60 - width
        let minY = screenFrame.minY - 40
        let maxY = screenFrame.maxY + 40 - height
        
        let x = CGFloat.random(in: minX...maxX)
        let y = CGFloat.random(in: minY...maxY)
        
        let types: [GlitchType] = [.terminal, .error, .crashReport, .matrixRain]
        let glitchType = types[index % types.count]
        
        let window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = randomWindowTitle(index: index)
        // Higher level than main window (.normal), lower than splash (.popUpMenu)
        window.level = .floating
        window.backgroundColor = .black
        window.hasShadow = true
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        
        let contentView = glitchType.view(seed: index)
        window.contentView = NSHostingView(rootView: contentView)
        
        return window
    }
    
    private func jitterWindow(_ window: NSWindow) {
        let originalFrame = window.frame
        let jitterCount = Int.random(in: 2...5)
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.05)
        
        for i in 0..<jitterCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                guard window.isVisible else { return }
                let dx = CGFloat.random(in: -8...8)
                let dy = CGFloat.random(in: -8...8)
                window.setFrameOrigin(NSPoint(
                    x: originalFrame.origin.x + dx,
                    y: originalFrame.origin.y + dy
                ))
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(jitterCount) * 0.06 + 0.03) {
            guard window.isVisible else { return }
            window.setFrameOrigin(originalFrame.origin)
        }
        
        CATransaction.commit()
    }
    
    private func randomWindowTitle(index: Int) -> String {
        let titles = [
            "kernel_task", "launchd", "WindowServer", "syslogd",
            "bluetoothd", "coreaudiod", "securityd", "mdworker",
            "distnoted", "cfprefsd", "kextd", "watchdogd",
            "thermald", "powerd", "autofsd", "logd",
            "usermanagementd", "authd", "ocspd", "biomed",
            " rapportd", "cloudd", "fileproviderd", "imageiopd"
        ]
        let pid = Int.random(in: 100...99999)
        let base = titles[index % titles.count]
        let variants = [" [FAULT]", " [PANIC]", " [SEGV]", " [HANG]", " [KILL]", " [CORRUPT]"]
        return "\(base)\(variants[index % variants.count]) — pid \(pid)"
    }
}
