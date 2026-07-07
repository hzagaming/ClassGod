//
//  AssessPrepHackView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

struct AssessPrepHackView: View {
    @StateObject private var viewModel = AssessPrepHackViewModel.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var showAddSheet = false
    @State private var editingApp: PanicApp?
    @State private var appToDelete: PanicApp?
    
    var onClose: () -> Void
    
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    var body: some View {
        ZStack {
            VStack(spacing: 0 * zoomScale) {
                header
                
                if viewModel.assessPrepDetected {
                    detectionBanner
                }
                
                if viewModel.isBypassActive {
                    activeBypassBanner
                }
                
                if viewModel.panicApps.isEmpty {
                    emptyState
                } else {
                    appList
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                footer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius * zoomScale)
                .fill(Color.black)
        )
        .overlay(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius * zoomScale)
                .stroke(Color.white.opacity(0.15), lineWidth: 1 * zoomScale)
        
            .allowsHitTesting(false))
        .sheet(isPresented: $showAddSheet) {
            AddPanicAppView(viewModel: viewModel, app: nil)
        }
        .sheet(item: $editingApp) { app in
            AddPanicAppView(viewModel: viewModel, app: app)
        }
        .alert(String(localized: "alert.error"), isPresented: $viewModel.showError) {
            Button(String(localized: "button.ok"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? String(localized: "error.unknown"))
        }
        .alert(String(localized: "panic.delete_title"), isPresented: .init(
            get: { appToDelete != nil },
            set: { if !$0 { appToDelete = nil } }
        )) {
            Button(String(localized: "button.cancel"), role: .cancel) { appToDelete = nil }
            Button(String(localized: "button.delete"), role: .destructive) {
                SoundEffectManager.shared.playTabDeleted()
                HapticManager.shared.warning()
                if let app = appToDelete {
                    viewModel.deleteApp(app)
                }
                appToDelete = nil
            }
        } message: {
            Text(String(format: String(localized: "panic.delete_message"), appToDelete?.name ?? ""))
        }
        .overlay(
            toastOverlay,
            alignment: .bottom
        )
        .onAppear {
            viewModel.startDetectionTimer()
        }
        .onDisappear {
            viewModel.stopDetectionTimer()
            if viewModel.isBypassActive {
                viewModel.stopAllBypasses()
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 10 * zoomScale) {
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                onClose()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10 * zoomScale, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                    .background(Color(white: 0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 22 * zoomScale))
                .foregroundStyle(.red)
                .symbolRenderingMode(.monochrome)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("AssessPrepHack")
                    .font(.system(size: 16 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                
                Text("panic.subtitle")
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            
            Spacer()
            
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                showAddSheet = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.monochrome)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(white: 0.03))
    }
    
    // MARK: - Detection Banner
    
    private var detectionBanner: some View {
        HStack(spacing: 8 * zoomScale) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .font(.system(size: 14 * zoomScale))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("panic.detected")
                    .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.yellow)
                Text(viewModel.assessPrepProcessName)
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                viewModel.scanForAssessPrep()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11 * zoomScale))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 8 * zoomScale)
        .background(Color.yellow.opacity(0.08))
        .overlay(
            Rectangle()
                .fill(Color.yellow.opacity(0.3))
                .frame(height: 1 * zoomScale),
            alignment: .bottom
        )
    }
    
    // MARK: - Active Bypass Banner
    
    private var activeBypassBanner: some View {
        HStack(spacing: 8 * zoomScale) {
            Image(systemName: "shield.fill")
                .foregroundStyle(.green)
                .font(.system(size: 14 * zoomScale))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("panic.active")
                    .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.green)
                Text(viewModel.activeTechniques.map(\.displayName).joined(separator: ", "))
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                viewModel.stopAllBypasses()
            }) {
                Text("bypass.stop")
                    .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 10 * zoomScale)
                    .padding(.vertical, 4 * zoomScale)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4 * zoomScale)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 8 * zoomScale)
        .background(Color.green.opacity(0.08))
        .overlay(
            Rectangle()
                .fill(Color.green.opacity(0.3))
                .frame(height: 1 * zoomScale),
            alignment: .bottom
        )
    }
    
    // MARK: - App List
    
    private var appList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0 * zoomScale) {
                ForEach(viewModel.panicApps) { app in
                    PanicAppRow(
                        app: app,
                        onExecute: {
                            viewModel.executeBypass(for: app)
                        },
                        onToggle: {
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                            viewModel.toggleApp(app)
                        },
                        onEdit: {
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                            editingApp = app
                        },
                        onDelete: {
                            SoundEffectManager.shared.playButtonClick()
                            appToDelete = app
                        }
                    )
                    .contextMenu {
                        Button(String(localized: "panic.execute")) {
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                            viewModel.executeBypass(for: app)
                        }
                        Button(String(localized: "button.edit")) {
                            SoundEffectManager.shared.playButtonClick()
                            HapticManager.shared.generic()
                            editingApp = app
                        }
                        Divider()
                        Button(String(localized: "button.delete"), role: .destructive) {
                            SoundEffectManager.shared.playButtonClick()
                            appToDelete = app
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12 * zoomScale) {
            Spacer()
            Image(systemName: "bolt.shield")
                .font(.system(size: 40 * zoomScale))
                .foregroundStyle(.white.opacity(0.15))
            
            Text("panic.empty_title")
                .font(.system(size: 13 * zoomScale, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
            
            Text("panic.empty_subtitle")
                .font(.system(size: 10 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.25))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack(spacing: 12 * zoomScale) {
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                viewModel.scanForAssessPrep()
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11 * zoomScale))
                Text("panic.scan")
                    .font(.system(size: 11 * zoomScale, design: .monospaced))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.5))
            
            Spacer()
            
            if viewModel.isBypassActive {
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    viewModel.stopAllBypasses()
                }) {
                    Text("panic.stop_all")
                        .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                showAddSheet = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 11 * zoomScale))
                Text("panic.add_app")
                    .font(.system(size: 11 * zoomScale, design: .monospaced))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal)
        .padding(.vertical, 10 * zoomScale)
    }
    
    // MARK: - Toast Overlay
    
    private var toastOverlay: some View {
        Group {
            if viewModel.showToast, let message = viewModel.toastMessage {
                Text(message)
                    .font(.system(size: 11 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16 * zoomScale)
                    .padding(.vertical, 8 * zoomScale)
                    .background(
                        Capsule()
                            .fill(Color(white: 0.12))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1 * zoomScale)
                            )
                    )
                    .padding(.bottom, 16 * zoomScale)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Panic App Row

struct PanicAppRow: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    let app: PanicApp
    let onExecute: () -> Void
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10 * zoomScale) {
            // Execute button
            Button(action: onExecute) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6 * zoomScale)
                        .fill(app.isEnabled ? Color.red.opacity(0.15) : Color(white: 0.06))
                        .frame(width: 36 * zoomScale, height: 36 * zoomScale)
                    
                    Image(systemName: app.bypassTechnique.iconName)
                        .font(.system(size: 16 * zoomScale))
                        .foregroundStyle(app.isEnabled ? .red : .white.opacity(0.2))
                }
            }
            .buttonStyle(.plain)
            .help(String(format: String(localized: "panic.execute_help"), app.bypassTechnique.displayName))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 12 * zoomScale, weight: .medium, design: .monospaced))
                    .foregroundStyle(app.isEnabled ? .white : .white.opacity(0.3))
                
                Text(app.bypassTechnique.displayName)
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
            
            Spacer()
            
            // Toggle
            Button(action: onToggle) {
                Image(systemName: app.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14 * zoomScale))
                    .foregroundStyle(app.isEnabled ? .green : .white.opacity(0.15))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 8 * zoomScale)
        .background(
            RoundedRectangle(cornerRadius: 6 * zoomScale)
                .fill(isHovered ? Color(white: 0.06) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6 * zoomScale)
                .stroke(isHovered ? Color.white.opacity(0.1) : Color.clear, lineWidth: 1 * zoomScale)
        
            .allowsHitTesting(false))
        .padding(.horizontal, 8 * zoomScale)
        .padding(.vertical, 2 * zoomScale)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    AssessPrepHackView(onClose: {})
}
