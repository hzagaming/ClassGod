//
//  SuperSwitchView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

struct SuperSwitchView: View {
    @StateObject private var viewModel = SuperSwitchViewModel()
    @State private var showAddSheet = false
    @State private var editingTarget: SwitchTarget?
    @State private var targetToDelete: SwitchTarget?
    @ObservedObject private var prefs = PreferencesManager.shared
    
    var onClose: () -> Void
    
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    var body: some View {
        ZStack {
            VStack(spacing: 0 * zoomScale) {
                header
                
                if viewModel.targets.isEmpty {
                    emptyState
                } else {
                    targetList
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                footer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius)
                .fill(Color.black)
        )
        .overlay(
            RoundedRectangle(cornerRadius: prefs.preferences.panelCornerRadius)
                .stroke(Color.white.opacity(0.15), lineWidth: 1 * zoomScale)
        
            .allowsHitTesting(false))
        .sheet(isPresented: $showAddSheet) {
            AddSwitchTargetView(viewModel: viewModel, target: nil)
        }
        .sheet(item: $editingTarget) { target in
            AddSwitchTargetView(viewModel: viewModel, target: target)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .alert("Delete target?", isPresented: .init(
            get: { targetToDelete != nil },
            set: { if !$0 { targetToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { targetToDelete = nil }
            Button("Delete", role: .destructive) {
                if let target = targetToDelete {
                    viewModel.deleteTarget(target)
                }
                targetToDelete = nil
            }
        } message: {
            Text("Remove \(targetToDelete?.name ?? "") from SuperSwitch?")
        }
        .overlay(
            toastOverlay,
            alignment: .bottom
        )
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
            
            VStack(alignment: .leading, spacing: 0) {
                Text("SuperSwitch")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(.white)
                
                Text("Quick app switcher")
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
        .padding(.horizontal)
        .padding(.vertical, 10 * zoomScale)
    }
    
    // MARK: - Target List
    
    private var targetList: some View {
        ScrollView {
            VStack(spacing: 0 * zoomScale) {
                ForEach(viewModel.targets) { target in
                    TargetRow(
                        target: target,
                        onSwitch: {
                            viewModel.switchToTarget(target)
                        },
                        onEdit: {
                            editingTarget = target
                        },
                        onDelete: {
                            targetToDelete = target
                        }
                    )
                    if target.id != viewModel.targets.last?.id {
                        Divider()
                            .padding(.leading, 48 * zoomScale)
                            .opacity(0.3)
                    }
                }
            }
        }
        .frame(maxHeight: prefs.preferences.panelMaxHeight - 120)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 10 * zoomScale) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 52 * zoomScale, height: 52 * zoomScale)
                
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 24 * zoomScale))
                    .foregroundStyle(.white.opacity(0.7))
                    .symbolRenderingMode(.monochrome)
            }
            
            Text("No targets configured")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
            
            Text("Add apps to switch between them instantly")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120 * zoomScale)
        .padding()
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack(spacing: 14 * zoomScale) {
            Text("Click a target to switch. Set shortcuts for instant access.")
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8 * zoomScale)
    }
    
    // MARK: - Toast Overlay
    
    private var toastOverlay: some View {
        Group {
            if viewModel.showToast, let message = viewModel.toastMessage {
                HStack(spacing: 6 * zoomScale) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                    Text(message)
                        .font(.system(size: 12 * zoomScale, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12 * zoomScale)
                .padding(.vertical, 7 * zoomScale)
                .background(Color(white: 0.12))
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1 * zoomScale)
                
                    .allowsHitTesting(false))
                .padding(.bottom, 10 * zoomScale)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Target Row

struct TargetRow: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    let target: SwitchTarget
    let onSwitch: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            SoundEffectManager.shared.playButtonClick()
            withAnimation(.easeOut(duration: 0.06)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                withAnimation(.easeOut(duration: 0.06)) {
                    isPressed = false
                }
            }
            onSwitch()
        }) {
            HStack(spacing: 10 * zoomScale) {
                Image(systemName: target.iconName)
                    .font(.system(size: 18 * zoomScale, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 24 * zoomScale)
                    .symbolRenderingMode(.monochrome)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(target.name)
                        .font(.system(size: 13 * zoomScale, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text(target.bundleIdentifier)
                        .font(.system(size: 9 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }
                
                Spacer()
                
                if target.isValidShortcut {
                    Text(target.shortcutDisplayString)
                        .font(.system(size: 11 * zoomScale, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 7 * zoomScale)
                        .padding(.vertical, 2 * zoomScale)
                        .background(Color(white: 0.15))
                        .overlay(
                            Rectangle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5 * zoomScale)
                        
                            .allowsHitTesting(false))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8 * zoomScale)
            .frame(minHeight: 44 * zoomScale)
            .contentShape(Rectangle())
            .background(
                Rectangle()
                    .fill(backgroundColor)
            )
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: 1 * zoomScale)
            .allowsHitTesting(false)            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Switch to \(target.name)") {
                onSwitch()
            }
            Button("Edit") {
                onEdit()
            }
            Divider()
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
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
    
    private var backgroundColor: Color {
        if isPressed {
            return Color.white.opacity(0.15)
        } else if isHovered {
            return Color.white.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isHovered {
            return Color.white.opacity(0.25)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Add Switch Target View

struct AddSwitchTargetView: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    @ObservedObject var viewModel: SuperSwitchViewModel
    var target: SwitchTarget?
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var bundleIdentifier: String = ""
    @State private var iconName: String = "app.fill"
    @State private var shortcutKey: String = ""
    @State private var shortcutModifiers: UInt = 0
    @State private var isRecordingShortcut: Bool = false
    @State private var runningApps: [(name: String, bundleID: String)] = []
    @State private var selectedAppIndex: Int = -1
    
    private let iconOptions = ["app.fill", "safari", "terminal", "doc.text", "folder", "gearshape.fill", "message.fill", "music.note", "photo", "video.fill", "gamecontroller", "creditcard"]
    
    var body: some View {
        VStack(spacing: 16 * zoomScale) {
            Text(target == nil ? "Add Switch Target" : "Edit Switch Target")
                .font(.system(size: 18 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            
            // Running apps picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Running Application")
                    .font(.system(size: 11 * zoomScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                
                Picker("", selection: $selectedAppIndex) {
                    Text("Custom...").tag(-1)
                    ForEach(0..<runningApps.count, id: \.self) { index in
                        Text(runningApps[index].name).tag(index)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedAppIndex) { _, newValue in
                    if newValue >= 0 && newValue < runningApps.count {
                        name = runningApps[newValue].name
                        bundleIdentifier = runningApps[newValue].bundleID
                    }
                }
            }
            
            // Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.system(size: 11 * zoomScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                TextField("App Name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Bundle ID
            VStack(alignment: .leading, spacing: 6) {
                Text("Bundle Identifier")
                    .font(.system(size: 11 * zoomScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                TextField("com.company.app", text: $bundleIdentifier)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Icon picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Icon")
                    .font(.system(size: 11 * zoomScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8 * zoomScale) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button(action: {
                                iconName = icon
                            }) {
                                Image(systemName: icon)
                                    .font(.system(size: 18 * zoomScale))
                                    .foregroundStyle(iconName == icon ? .green : .white.opacity(0.6))
                                    .frame(width: 36 * zoomScale, height: 36 * zoomScale)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6 * zoomScale)
                                            .fill(iconName == icon ? Color.white.opacity(0.15) : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6 * zoomScale)
                                            .stroke(iconName == icon ? Color.white.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1 * zoomScale)
                                    
                                        .allowsHitTesting(false))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Shortcut
            VStack(alignment: .leading, spacing: 6) {
                Text("Shortcut (optional)")
                    .font(.system(size: 11 * zoomScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                
                HStack(spacing: 8 * zoomScale) {
                    ShortcutPicker(key: $shortcutKey, modifiers: $shortcutModifiers, isRecording: $isRecordingShortcut)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12 * zoomScale) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(target == nil ? "Add" : "Save") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || bundleIdentifier.isEmpty)
            }
        }
        .padding()
        .frame(width: 340 * zoomScale, height: 480 * zoomScale)
        .background(Color.black)
        .onAppear {
            runningApps = viewModel.getRunningApps()
            if let target = target {
                name = target.name
                bundleIdentifier = target.bundleIdentifier
                iconName = target.iconName
                shortcutKey = target.shortcutKey
                shortcutModifiers = target.shortcutModifiers
                // Try to find matching app
                if let index = runningApps.firstIndex(where: { $0.bundleID == target.bundleIdentifier }) {
                    selectedAppIndex = index
                }
            }
        }
    }
    
    private func save() {
        SoundEffectManager.shared.playButtonClick()
        if let existing = target {
            let updated = SwitchTarget(
                id: existing.id,
                name: name,
                bundleIdentifier: bundleIdentifier,
                iconName: iconName,
                shortcutKey: shortcutKey,
                shortcutModifiers: shortcutModifiers,
                createdAt: existing.createdAt
            )
            viewModel.updateTarget(updated)
        } else {
            let new = SwitchTarget(
                name: name,
                bundleIdentifier: bundleIdentifier,
                iconName: iconName,
                shortcutKey: shortcutKey,
                shortcutModifiers: shortcutModifiers
            )
            viewModel.addTarget(new)
        }
        dismiss()
    }
}

#Preview {
    SuperSwitchView(onClose: {})
}
