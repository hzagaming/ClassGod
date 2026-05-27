//
//  AssessPrepHackView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

struct AssessPrepHackView: View {
    @StateObject private var viewModel = AssessPrepHackViewModel()
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var showAddSheet = false
    @State private var editingApp: PanicApp?
    @State private var appToDelete: PanicApp?
    
    var onClose: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
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
        .frame(width: prefs.preferences.panelWidth)
        .background(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius)
                .fill(Color.black)
        )
        .overlay(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .sheet(isPresented: $showAddSheet) {
            AddPanicAppView(viewModel: viewModel, app: nil)
        }
        .sheet(item: $editingApp) { app in
            AddPanicAppView(viewModel: viewModel, app: app)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .alert("Delete app?", isPresented: .init(
            get: { appToDelete != nil },
            set: { if !$0 { appToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { appToDelete = nil }
            Button("Delete", role: .destructive) {
                if let app = appToDelete {
                    viewModel.deleteApp(app)
                }
                appToDelete = nil
            }
        } message: {
            Text("Remove panic app \"\(appToDelete?.name ?? "")\"?")
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
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 10) {
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                onClose()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 24, height: 24)
                    .background(Color(white: 0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Image(systemName: "bolt.shield.fill")
                .font(.title2)
                .foregroundStyle(.red)
                .symbolRenderingMode(.monochrome)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("AssessPrepHack")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(.white)
                
                Text("Break free from proctoring")
                    .font(.system(size: 9, design: .monospaced))
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
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("AssessPrep Detected")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.yellow)
                Text(viewModel.assessPrepProcessName)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                viewModel.scanForAssessPrep()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.yellow.opacity(0.08))
        .overlay(
            Rectangle()
                .fill(Color.yellow.opacity(0.3))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Active Bypass Banner
    
    private var activeBypassBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.fill")
                .foregroundStyle(.green)
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Bypass Active")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.green)
                Text(viewModel.activeTechniques.map(\.displayName).joined(separator: ", "))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                viewModel.stopAllBypasses()
            }) {
                Text("Stop")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.green.opacity(0.08))
        .overlay(
            Rectangle()
                .fill(Color.green.opacity(0.3))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - App List
    
    private var appList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.panicApps) { app in
                    PanicAppRow(
                        app: app,
                        onExecute: {
                            viewModel.executeBypass(for: app)
                        },
                        onToggle: {
                            viewModel.toggleApp(app)
                        },
                        onEdit: {
                            editingApp = app
                        },
                        onDelete: {
                            appToDelete = app
                        }
                    )
                    .contextMenu {
                        Button("Execute Bypass") {
                            viewModel.executeBypass(for: app)
                        }
                        Button("Edit") {
                            editingApp = app
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            appToDelete = app
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "bolt.shield")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.15))
            
            Text("No panic apps configured")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
            
            Text("Add apps to bypass AssessPrep lockdown")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.25))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack(spacing: 12) {
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                viewModel.scanForAssessPrep()
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                Text("Scan")
                    .font(.system(size: 11, design: .monospaced))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.5))
            
            Spacer()
            
            if viewModel.isBypassActive {
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    viewModel.stopAllBypasses()
                }) {
                    Text("Stop All")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                showAddSheet = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 11))
                Text("Add App")
                    .font(.system(size: 11, design: .monospaced))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    // MARK: - Toast Overlay
    
    private var toastOverlay: some View {
        Group {
            if viewModel.showToast, let message = viewModel.toastMessage {
                Text(message)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(white: 0.12))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Panic App Row

struct PanicAppRow: View {
    let app: PanicApp
    let onExecute: () -> Void
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Execute button
            Button(action: onExecute) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(app.isEnabled ? Color.red.opacity(0.15) : Color(white: 0.06))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: app.bypassTechnique.iconName)
                        .font(.system(size: 16))
                        .foregroundStyle(app.isEnabled ? .red : .white.opacity(0.2))
                }
            }
            .buttonStyle(.plain)
            .help("Execute \(app.bypassTechnique.displayName)")
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(app.isEnabled ? .white : .white.opacity(0.3))
                
                Text(app.bypassTechnique.displayName)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
            
            Spacer()
            
            // Toggle
            Button(action: onToggle) {
                Image(systemName: app.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(app.isEnabled ? .green : .white.opacity(0.15))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color(white: 0.06) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isHovered ? Color.white.opacity(0.1) : Color.clear, lineWidth: 1)
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    AssessPrepHackView(onClose: {})
}
