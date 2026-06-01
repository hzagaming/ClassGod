//
//  WindowZoomControlBar.swift
//  ClassGod
//

import SwiftUI

struct WindowZoomControlBar: View {
    @ObservedObject var prefs = PreferencesManager.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                prefs.preferences.windowZoomScale = max(0.5, prefs.preferences.windowZoomScale - 0.1)
            }) {
                Image(systemName: "minus")
                    .font(.system(size: 8, weight: .bold))
                    .frame(width: 18, height: 18)
                    .background(Color(white: 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.6))
            .disabled(prefs.preferences.windowZoomScale <= 0.5)
            
            Text("\(Int(prefs.preferences.windowZoomScale * 100))%")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .frame(minWidth: 28)
            
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                prefs.preferences.windowZoomScale = min(2.0, prefs.preferences.windowZoomScale + 0.1)
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 8, weight: .bold))
                    .frame(width: 18, height: 18)
                    .background(Color(white: 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.6))
            .disabled(prefs.preferences.windowZoomScale >= 2.0)
            
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                prefs.preferences.windowZoomScale = 1.0
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 8, weight: .bold))
                    .frame(width: 18, height: 18)
                    .background(Color(white: 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.4))
            .disabled(prefs.preferences.windowZoomScale == 1.0)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(white: 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                
                    .allowsHitTesting(false))
        )
    }
}

#Preview {
    WindowZoomControlBar()
        .padding()
        .background(Color.black)
}
