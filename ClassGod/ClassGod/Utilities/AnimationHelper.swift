//
//  AnimationHelper.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

// MARK: - Animation Helper

enum Anim {
    static var enabled: Bool {
        PreferencesManager.shared.preferences.animationSpeed.isEnabled
    }
    
    static var duration: Double {
        PreferencesManager.shared.preferences.animationSpeed.duration
    }
    
    static func with(_ body: @escaping () -> Void) {
        if enabled {
            withAnimation(.easeOut(duration: duration), body)
        } else {
            body()
        }
    }
}

// MARK: - View Modifiers

struct HoverScaleModifier: ViewModifier {
    @State private var isHovered = false
    let scale: CGFloat
    
    func body(content: Content) -> some View {
        let dur = Anim.duration
        return content
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(dur > 0 ? .easeOut(duration: dur) : .none, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct BounceModifier: ViewModifier {
    @State private var scale: CGFloat = 1.0
    @State private var hasAnimated = false
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        let dur = Anim.duration
        return content
            .scaleEffect(scale)
            .onAppear {
                guard dur > 0, !hasAnimated else { return }
                hasAnimated = true
                withAnimation(.easeOut(duration: dur * 2)) {
                    scale = intensity
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + dur) {
                    guard dur > 0 else { return }
                    withAnimation(.easeOut(duration: dur * 2)) {
                        scale = 1.0
                    }
                }
            }
    }
}

struct ShakeModifier: ViewModifier {
    @State private var offset: CGFloat = 0
    @State private var workItems: [DispatchWorkItem] = []
    let trigger: Bool
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        let dur = Anim.duration
        return content
            .offset(x: offset)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    // Cancel any pending shake animations
                    for item in workItems { item.cancel() }
                    workItems.removeAll()
                    
                    if dur > 0 {
                        let steps: [(CGFloat, Double)] = [
                            (-intensity, dur),
                            (intensity, dur * 2),
                            (-intensity / 2, dur * 3),
                            (intensity / 2, dur * 4),
                            (0, dur * 5)
                        ]
                        for (targetOffset, delay) in steps {
                            let item = DispatchWorkItem {
                                withAnimation(.easeInOut(duration: dur)) {
                                    offset = targetOffset
                                }
                            }
                            workItems.append(item)
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
                        }
                    } else {
                        offset = 0
                    }
                }
            }
    }
}

struct SlideInModifier: ViewModifier {
    let edge: Edge
    let delay: Double
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        let dur = Anim.duration
        let offsetX: CGFloat = edge == .leading ? -20 : (edge == .trailing ? 20 : 0)
        let offsetY: CGFloat = edge == .top ? -15 : (edge == .bottom ? 15 : 0)
        
        return content
            .offset(x: isVisible ? 0 : offsetX, y: isVisible ? 0 : offsetY)
            .opacity(isVisible ? 1 : 0)
            .animation(dur > 0 ? .easeOut(duration: dur).delay(delay * dur * 5) : .none, value: isVisible)
            .onAppear {
                isVisible = true
            }
            .onDisappear {
                isVisible = false
            }
    }
}

// MARK: - View Extensions

extension View {
    func pressScale(_ scale: CGFloat = 0.97) -> some View {
        modifier(HoverScaleModifier(scale: scale))
    }
    
    func bounce(intensity: CGFloat = 1.05) -> some View {
        modifier(BounceModifier(intensity: intensity))
    }
    
    func shake(trigger: Bool, intensity: CGFloat = 8) -> some View {
        modifier(ShakeModifier(trigger: trigger, intensity: intensity))
    }
    
    func slideIn(from edge: Edge, delay: Double = 0) -> some View {
        modifier(SlideInModifier(edge: edge, delay: delay))
    }
}
