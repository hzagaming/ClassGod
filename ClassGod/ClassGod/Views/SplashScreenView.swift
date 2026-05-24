//
//  SplashScreenView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var opacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Text(String(localized: "splash.title"))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(opacity)
                
                Text(String(localized: "splash.subtitle"))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .opacity(subtitleOpacity)
                
                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.3.0")")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .opacity(subtitleOpacity)
                    .padding(.top, 8)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                opacity = 1
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                subtitleOpacity = 1
            }
        }
    }
}
