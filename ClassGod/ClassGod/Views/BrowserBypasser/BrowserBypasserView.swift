//
//  BrowserBypasserView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

struct BrowserBypasserView: View {
    @StateObject private var viewModel = BrowserBypasserViewModel()
    @State private var showAddSheet = false
    @State private var editingRule: BypassRule?
    @State private var ruleToDelete: BypassRule?
    @ObservedObject private var prefs = PreferencesManager.shared
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                
                if viewModel.isBypassActive {
                    activeBanner
                }
                
                if viewModel.detectedBrowser.isEmpty == false {
                    detectionBanner
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                if viewModel.rules.isEmpty {
                    emptyState
                } else {
                    ruleList
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
            AddBypassRuleView(viewModel: viewModel, rule: nil)
        }
        .sheet(item: $editingRule) { rule in
            AddBypassRuleView(viewModel: viewModel, rule: rule)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .alert("Delete rule?", isPresented: .init(
            get: { ruleToDelete != nil },
            set: { if !$0 { ruleToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { ruleToDelete = nil }
            Button("Delete", role: .destructive) {
                if let rule = ruleToDelete {
                    viewModel.deleteRule(rule)
                }
                ruleToDelete = nil
            }
        } message: {
            Text("Remove bypass rule \"\(ruleToDelete?.name ?? "")\"?")
        }
        .overlay(
            toastOverlay,
            alignment: .bottom
        )
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.open.fill")
                .font(.title2)
                .foregroundStyle(.green)
                .symbolRenderingMode(.monochrome)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("BrowserBypasser")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(.white)
                
                Text("Break free from lockdown pages")
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
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    // MARK: - Active Banner
    
    private var activeBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 11))
                .foregroundStyle(.green)
            
            Text("Bypass Active: \(viewModel.activeBypasses.map(\.displayName).joined(separator: ", "))")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.green.opacity(0.9))
            
            Spacer()
            
            Button("Stop") {
                SoundEffectManager.shared.playButtonClick()
                viewModel.stopAllBypasses()
            }
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(.red)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black)
        .overlay(
            Rectangle()
                .stroke(Color.green.opacity(0.4), lineWidth: 1)
        )
    }
    
    // MARK: - Detection Banner
    
    private var detectionBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.yellow)
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Detected: \(viewModel.detectedBrowser)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.yellow.opacity(0.9))
                Text(viewModel.detectedURL)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.yellow.opacity(0.6))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black)
        .overlay(
            Rectangle()
                .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
        )
    }
    
    // MARK: - Rule List
    
    private var ruleList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(viewModel.rules) { rule in
                    RuleRow(
                        rule: rule,
                        onToggle: {
                            viewModel.toggleRule(rule)
                        },
                        onRun: {
                            viewModel.runBypass(for: rule.bypassType)
                        },
                        onEdit: {
                            editingRule = rule
                        },
                        onDelete: {
                            ruleToDelete = rule
                        }
                    )
                    if rule.id != viewModel.rules.last?.id {
                        Divider()
                            .padding(.leading, 48)
                            .opacity(0.3)
                    }
                }
            }
        }
        .frame(maxHeight: prefs.preferences.panelMaxHeight - 200)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 52, height: 52)
                
                Image(systemName: "lock.open")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.7))
                    .symbolRenderingMode(.monochrome)
            }
            
            Text("No bypass rules")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
            
            Text("Add rules to bypass browser lockdowns")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding()
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Text("Select a rule to activate bypass")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                
                Spacer()
                
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    if let detected = viewModel.detectLockedBrowser() {
                        viewModel.showToast(message: "Detected: \(detected.browser)")
                    } else {
                        viewModel.showToast(message: "No lockdown browser detected")
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 10))
                        Text("Scan")
                            .font(.system(size: 11, design: .monospaced))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Toast Overlay
    
    private var toastOverlay: some View {
        Group {
            if viewModel.showToast, let message = viewModel.toastMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                    Text(message)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(white: 0.12))
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .padding(.bottom, 10)
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Rule Row

struct RuleRow: View {
    let rule: BypassRule
    let onToggle: () -> Void
    let onRun: () -> Void
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
            onRun()
        }) {
            HStack(spacing: 10) {
                Image(systemName: rule.bypassType.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(rule.isEnabled ? .green : .white.opacity(0.3))
                    .frame(width: 24)
                    .symbolRenderingMode(.monochrome)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(rule.name)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(rule.isEnabled ? .white : .white.opacity(0.4))
                        .lineLimit(1)
                    
                    Text(rule.bypassType.displayName)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Toggle("", isOn: .init(
                    get: { rule.isEnabled },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(.switch)
                .scaleEffect(0.7)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .background(
                Rectangle()
                    .fill(backgroundColor)
            )
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Run \(rule.bypassType.displayName)") {
                onRun()
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

// MARK: - Add Bypass Rule View

struct AddBypassRuleView: View {
    @ObservedObject var viewModel: BrowserBypasserViewModel
    var rule: BypassRule?
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var targetURLPattern: String = ""
    @State private var bypassType: BypassType = .exitFullscreen
    @State private var isEnabled: Bool = true
    
    var body: some View {
        VStack(spacing: 16) {
            Text(rule == nil ? "Add Bypass Rule" : "Edit Bypass Rule")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            
            // Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                TextField("e.g. Canvas Quiz Bypass", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            // URL Pattern
            VStack(alignment: .leading, spacing: 6) {
                Text("URL Pattern")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                TextField("e.g. canvas.*quiz", text: $targetURLPattern)
                    .textFieldStyle(.roundedBorder)
                
                // Common patterns
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(viewModel.commonPatterns, id: \.pattern) { item in
                            Button(action: {
                                name = item.name
                                targetURLPattern = item.pattern
                            }) {
                                Text(item.name)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(white: 0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Bypass Type
            VStack(alignment: .leading, spacing: 6) {
                Text("Bypass Method")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                
                Picker("", selection: $bypassType) {
                    ForEach(BypassType.allCases, id: \.self) { type in
                        HStack(spacing: 6) {
                            Image(systemName: type.iconName)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(type.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                Text(type.description)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tag(type)
                    }
                }
                .pickerStyle(.radioGroup)
                .foregroundStyle(.white)
            }
            
            // Enabled toggle
            Toggle("Enable immediately", isOn: $isEnabled)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(rule == nil ? "Add" : "Save") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || targetURLPattern.isEmpty)
            }
        }
        .padding()
        .frame(width: 380, height: 480)
        .background(Color.black)
        .onAppear {
            if let rule = rule {
                name = rule.name
                targetURLPattern = rule.targetURLPattern
                bypassType = rule.bypassType
                isEnabled = rule.isEnabled
            }
        }
    }
    
    private func save() {
        SoundEffectManager.shared.playButtonClick()
        if let existing = rule {
            let updated = BypassRule(
                id: existing.id,
                name: name,
                targetURLPattern: targetURLPattern,
                bypassType: bypassType,
                isEnabled: isEnabled,
                createdAt: existing.createdAt
            )
            viewModel.updateRule(updated)
        } else {
            let new = BypassRule(
                name: name,
                targetURLPattern: targetURLPattern,
                bypassType: bypassType,
                isEnabled: isEnabled
            )
            viewModel.addRule(new)
        }
        dismiss()
    }
}

#Preview {
    BrowserBypasserView()
}
