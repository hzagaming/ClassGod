//
//  AnimationHelper.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI
import AppKit

// MARK: - Animation Helper

nonisolated enum AnimationDurationPolicy {
    static func duration(preferred: Double, useInstant: Bool, reduceMotion: Bool) -> Double {
        useInstant || reduceMotion ? 0 : preferred
    }

    static func shouldRunLaunchEffects(duration: Double) -> Bool {
        duration > 0
    }

}

nonisolated enum InteractiveMotionPolicy {
    static func scale(
        active: Bool,
        requestedScale: CGFloat,
        animationsEnabled: Bool
    ) -> CGFloat {
        guard active,
              animationsEnabled,
              requestedScale.isFinite,
              requestedScale > 0 else { return 1 }
        return requestedScale
    }
}

nonisolated enum HoverInteractionPolicy {
    static func isActive(isHovered: Bool, isEnabled: Bool) -> Bool {
        isHovered && isEnabled
    }
}

nonisolated enum EntranceMotionPolicy {
    static func isPresented(state: Bool, animationsEnabled: Bool) -> Bool {
        state || !animationsEnabled
    }
}

enum Anim {
    static var enabled: Bool {
        duration > 0
    }
    
    static var duration: Double {
        let prefs = PreferencesManager.shared.preferences
        return AnimationDurationPolicy.duration(
            preferred: prefs.animationSpeed.duration,
            useInstant: prefs.useInstantAnimations,
            reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        )
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
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    let scale: CGFloat

    func body(content: Content) -> some View {
        let dur = Anim.duration
        return content
            .scaleEffect(InteractiveMotionPolicy.scale(
                active: HoverInteractionPolicy.isActive(
                    isHovered: isHovered,
                    isEnabled: isEnabled
                ),
                requestedScale: scale,
                animationsEnabled: dur > 0
            ))
            .animation(dur > 0 ? .easeOut(duration: dur) : .none, value: isHovered)
            .onHover { hovering in
                isHovered = hovering && isEnabled
            }
            .onChange(of: isEnabled) { _, enabled in
                if !enabled { isHovered = false }
            }
    }
}

struct BounceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var scale: CGFloat = 1.0
    @State private var hasAnimated = false
    @State private var resetWorkItem: DispatchWorkItem?
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        let dur = AnimationDurationPolicy.duration(
            preferred: preferences.preferences.animationSpeed.duration,
            useInstant: preferences.preferences.useInstantAnimations,
            reduceMotion: reduceMotion
        )
        return content
            .scaleEffect(dur > 0 ? scale : 1)
            .transaction { transaction in
                if dur == 0 {
                    transaction.animation = .linear(duration: 0)
                    transaction.disablesAnimations = true
                }
            }
            .onAppear {
                guard dur > 0, !hasAnimated else { return }
                hasAnimated = true
                withAnimation(.easeOut(duration: dur * 2)) {
                    scale = intensity
                }
                let item = DispatchWorkItem {
                    withAnimation(.easeOut(duration: dur * 2)) {
                        scale = 1.0
                    }
                }
                resetWorkItem = item
                DispatchQueue.main.asyncAfter(deadline: .now() + dur * 2, execute: item)
            }
            .onChange(of: dur) { _, _ in reset() }
            .onDisappear(perform: reset)
    }

    private func reset() {
        resetWorkItem?.cancel()
        resetWorkItem = nil
        withTransaction(Transaction(animation: .linear(duration: 0))) { scale = 1 }
    }
}

struct ShakeModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var offset: CGFloat = 0
    @State private var workItems: [DispatchWorkItem] = []
    let trigger: Bool
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        let dur = AnimationDurationPolicy.duration(
            preferred: preferences.preferences.animationSpeed.duration,
            useInstant: preferences.preferences.useInstantAnimations,
            reduceMotion: reduceMotion
        )
        return content
            .offset(x: dur > 0 ? offset : 0)
            .transaction { transaction in
                if dur == 0 {
                    transaction.animation = .linear(duration: 0)
                    transaction.disablesAnimations = true
                }
            }
            .onChange(of: trigger) { _, _ in
                reset()
                guard dur > 0 else { return }
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
            }
            .onChange(of: dur) { _, _ in reset() }
            .onDisappear(perform: reset)
    }

    private func reset() {
        for item in workItems { item.cancel() }
        workItems.removeAll()
        withTransaction(Transaction(animation: .linear(duration: 0))) { offset = 0 }
    }
}

struct SlideInModifier: ViewModifier {
    let edge: Edge
    let delay: Double
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        let dur = Anim.duration
        let isPresented = EntranceMotionPolicy.isPresented(
            state: isVisible,
            animationsEnabled: dur > 0
        )
        let offsetX: CGFloat = edge == .leading ? -20 : (edge == .trailing ? 20 : 0)
        let offsetY: CGFloat = edge == .top ? -15 : (edge == .bottom ? 15 : 0)
        
        return content
            .offset(x: isPresented ? 0 : offsetX, y: isPresented ? 0 : offsetY)
            .opacity(isPresented ? 1 : 0)
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
    
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Press Events Modifier

struct PressEventsModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}
