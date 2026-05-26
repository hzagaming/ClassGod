//
//  MenuBarView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    var onOpenDestinTab: () -> Void
    var onOpenSuperSwitch: () -> Void
    var onOpenBrowserBypasser: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                
                ScrollView {
                    VStack(spacing: 12) {
                        FeatureButton(
                            icon: "link",
                            title: "DestinTab",
                            description: "Manage & switch browser tabs",
                            action: onOpenDestinTab
                        )
                        
                        FeatureButton(
                            icon: "arrow.left.arrow.right",
                            title: "SuperSwitch",
                            description: "Quick app switcher with shortcuts",
                            action: onOpenSuperSwitch
                        )
                        
                        FeatureButton(
                            icon: "lock.open.fill",
                            title: "BrowserBypasser",
                            description: "Break free from lockdown pages",
                            action: onOpenBrowserBypasser
                        )
                        
                        // Placeholder for future features
                        FeatureButton(
                            icon: "rectangle.grid.2x2",
                            title: "Coming Soon",
                            description: "More features on the way",
                            action: {},
                            isEnabled: false
                        )
                    }
                    .padding()
                }
                
                Spacer()
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                footer
            }
        }
        .frame(width: prefs.preferences.panelWidth)
        .background(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius)
                .fill(Color.black)
        )
        .overlay(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .preferredColorScheme(prefs.preferences.theme.colorScheme)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: prefs.preferences.menuBarIconStyle.systemImageName)
                .font(.title2)
                .foregroundStyle(.white)
                .symbolRenderingMode(.monochrome)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("ClassGod")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(.white)
                
                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.5.0")")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack(spacing: 14) {
            footerButton(title: String(localized: "button.settings"), icon: "gear") {
                SoundEffectManager.shared.playButtonClick()
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            
            Spacer()
            
            footerButton(title: String(localized: "button.quit"), icon: "power") {
                SoundEffectManager.shared.playButtonClick()
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private func footerButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .symbolRenderingMode(.monochrome)
                Text(title)
                    .font(.system(size: 11, design: .monospaced))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.6))
    }
}

// MARK: - Feature Button

struct FeatureButton: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            if isEnabled {
                SoundEffectManager.shared.playButtonClick()
                action()
            }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(isEnabled ? .white : .white.opacity(0.3))
                        .symbolRenderingMode(.monochrome)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(isEnabled ? .white : .white.opacity(0.3))
                    
                    Text(description)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isEnabled ? .white.opacity(0.5) : .white.opacity(0.15))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(white: 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHovered && isEnabled ? Color.white.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if Anim.enabled {
                withAnimation(.easeOut(duration: Anim.duration)) {
                    isHovered = hovering
                }
            } else {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    MenuBarView(onOpenDestinTab: {}, onOpenSuperSwitch: {}, onOpenBrowserBypasser: {})
}
