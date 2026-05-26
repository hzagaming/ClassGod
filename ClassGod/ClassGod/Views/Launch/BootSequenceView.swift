//
//  BootSequenceView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI
import Combine

struct BootSequenceView: View {
    @State private var phase: BootPhase = .showInitial
    @State private var scrambleTimer: Timer?
    @State private var scrambleChars: [Character] = []
    @State private var settledMask: [Bool] = []
    @State private var productsOpacity: Double = 1.0
    @State private var overallOpacity: Double = 1.0
    @State private var extraROffset: CGFloat = 0
    @State private var extraRAlpha: Double = 1.0
    
    let onComplete: () -> Void
    
    private let sourceWord = Array("Hanazar")
    private let targetWord = Array("Hacker")
    private let scrambleSource = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%&*"
    
    enum BootPhase {
        case showInitial      // Show "Hanazar Products" stable
        case scrambling       // Letters randomize
        case settling         // Letters settle to "Hacker"
        case fadeProducts     // "Products" fades, extra 'r' shrinks
        case showHacker       // "Hacker" alone, brief pause
        case fadeOut          // Everything fades, trigger completion
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Main word: Hanazar / Hacker (with morphing)
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { i in
                        Text(String(displayChar(at: i)))
                            .font(.system(size: 56, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .opacity(settledMask.count > i && settledMask[i] ? 1.0 : 0.7)
                            .offset(x: i == 6 ? extraROffset : 0)
                            .opacity(i == 6 ? extraRAlpha : 1.0)
                            .scaleEffect(i == 6 ? extraRAlpha : 1.0)
                    }
                }
                
                // Subtitle: Products (fades out)
                Text("Products")
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                    .opacity(productsOpacity)
            }
        }
        .opacity(overallOpacity)
        .onAppear {
            startSequence()
        }
        .onDisappear {
            scrambleTimer?.invalidate()
        }
    }
    
    // MARK: - Display Logic
    
    private func displayChar(at index: Int) -> Character {
        guard phase != .showInitial else {
            return sourceWord[index]
        }
        
        // If settled, show target char (or nothing for extra 'r')
        if settledMask.count > index && settledMask[index] {
            if index < targetWord.count {
                return targetWord[index]
            } else {
                return " "
            }
        }
        
        // During scramble, show random char
        if scrambleChars.count > index {
            return scrambleChars[index]
        }
        
        return sourceWord[index]
    }
    
    // MARK: - Animation Sequence
    
    private func startSequence() {
        // Phase 1: Show "Hanazar Products" stable for 400ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard phase == .showInitial else { return }
            phase = .scrambling
            startScramble()
        }
    }
    
    private func startScramble() {
        scrambleChars = sourceWord
        settledMask = Array(repeating: false, count: 7)
        
        // Rapid scramble timer (every 40ms)
        scrambleTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { _ in
            for i in 0..<7 where !settledMask[i] {
                scrambleChars[i] = scrambleSource.randomElement()!
            }
        }
        
        // Settle letters one by one with delay
        // H (0) and a (1) stay same → settle immediately
        // n (2)→c, a (3)→k, z (4)→e, a (5)→r, r (6)→fade out
        let settleDelays: [(index: Int, delay: Double)] = [
            (0, 0.1),   // H → H
            (1, 0.2),   // a → a
            (2, 0.4),   // n → c
            (3, 0.55),  // a → k
            (4, 0.7),   // z → e
            (5, 0.85),  // a → r
            (6, 1.0),   // r → fade
        ]
        
        for (index, delay) in settleDelays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard phase == .scrambling || phase == .settling else { return }
                
                if index == 6 {
                    // Extra 'r' fades and slides away
                    phase = .fadeProducts
                    withAnimation(.easeOut(duration: 0.3)) {
                        extraROffset = 30
                        extraRAlpha = 0
                    }
                } else {
                    settledMask[index] = true
                }
                
                // After last letter settles, fade Products
                if index == 5 {
                    phase = .settling
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            productsOpacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            phase = .showHacker
                            // Brief pause on "Hacker" alone
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                phase = .fadeOut
                                scrambleTimer?.invalidate()
                                withAnimation(.easeOut(duration: 0.3)) {
                                    overallOpacity = 0
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    onComplete()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
