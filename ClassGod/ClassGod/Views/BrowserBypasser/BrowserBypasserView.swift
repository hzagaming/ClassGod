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
    @State private var detectionTask: Task<Void, Never>?
    @ObservedObject private var prefs = PreferencesManager.shared
    
    var onClose: () -> Void
    
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    private var accent: Color { prefs.preferences.themeAccent.color }
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0 * zoomScale) {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
            AddBypassRuleView(viewModel: viewModel, rule: nil)
        }
        .sheet(item: $editingRule) { rule in
            AddBypassRuleView(viewModel: viewModel, rule: rule)
        }
        .alert(String(localized: "alert.error"), isPresented: $viewModel.showError) {
            Button(String(localized: "button.ok"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? String(localized: "error.unknown"))
        }
        .alert(String(localized: "bypass.delete_title"), isPresented: .init(
            get: { ruleToDelete != nil },
            set: { if !$0 { ruleToDelete = nil } }
        )) {
            Button(String(localized: "button.cancel"), role: .cancel) { ruleToDelete = nil }
            Button(String(localized: "button.delete"), role: .destructive) {
                HapticManager.shared.warning()
                if let rule = ruleToDelete {
                    viewModel.deleteRule(rule)
                }
                ruleToDelete = nil
            }
        } message: {
            Text(String(format: String(localized: "bypass.delete_message"), ruleToDelete?.name ?? ""))
        }
        .overlay(
            toastOverlay,
            alignment: .bottom
        )
        .onDisappear {
            detectionTask?.cancel()
            detectionTask = nil
            viewModel.cancelDetection()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 10 * zoomScale) {
            Button(action: {
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
            .accessibilityLabel(Text("button.close"))
            
            Image(systemName: "lock.open.fill")
                .font(.system(size: 22 * zoomScale))
                .foregroundStyle(.green)
                .symbolRenderingMode(.monochrome)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("BrowserBypasser")
                    .font(.system(size: 16 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                
                Text("bypass.subtitle")
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            
            Spacer()
            
            Button(action: presentAddSheet) {
                HStack(spacing: 5 * zoomScale) {
                    Image(systemName: "plus")
                    Text("button.add")
                }
                .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.black)
                .padding(.horizontal, 9 * zoomScale)
                .frame(height: 26 * zoomScale)
                .background(accent.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("button.add"))
        }
        .padding(.horizontal, 16 * zoomScale)
        .padding(.vertical, 10 * zoomScale)
    }
    
    // MARK: - Active Banner
    
    private var activeBanner: some View {
        HStack(spacing: 8 * zoomScale) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 11 * zoomScale))
                .foregroundStyle(.green)
            
            Text(String(format: String(localized: "bypass.active_banner"), viewModel.activeBypasses.map(\.displayName).joined(separator: ", ")))
                .font(.system(size: 11 * zoomScale, weight: .medium, design: .monospaced))
                .foregroundStyle(.green.opacity(0.9))
            
            Spacer()
            
            Button("bypass.stop") {
                SoundEffectManager.shared.playButtonClick()
                HapticManager.shared.generic()
                viewModel.stopAllBypasses()
            }
            .font(.system(size: 11 * zoomScale, weight: .semibold, design: .monospaced))
            .foregroundStyle(.red)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 6 * zoomScale)
        .background(Color.black)
        .overlay(
            Rectangle()
                .stroke(Color.green.opacity(0.4), lineWidth: 1 * zoomScale)
        
            .allowsHitTesting(false))
    }
    
    // MARK: - Detection Banner
    
    private var detectionBanner: some View {
        HStack(spacing: 8 * zoomScale) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11 * zoomScale))
                .foregroundStyle(.yellow)
            
            VStack(alignment: .leading, spacing: 1 * zoomScale) {
                Text(String(format: String(localized: "bypass.detected"), viewModel.detectedBrowser))
                    .font(.system(size: 10 * zoomScale, weight: .medium, design: .monospaced))
                    .foregroundStyle(.yellow.opacity(0.9))
                Text(viewModel.detectedURL)
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.yellow.opacity(0.6))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12 * zoomScale)
        .padding(.vertical, 6 * zoomScale)
        .background(Color.black)
        .overlay(
            Rectangle()
                .stroke(Color.yellow.opacity(0.4), lineWidth: 1 * zoomScale)
        
            .allowsHitTesting(false))
    }
    
    // MARK: - Rule List
    
    private var ruleList: some View {
        ScrollView {
            VStack(spacing: 0 * zoomScale) {
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
                            .padding(.leading, 48 * zoomScale)
                            .opacity(0.3)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 10 * zoomScale) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 52 * zoomScale, height: 52 * zoomScale)
                
                Image(systemName: "lock.open")
                    .font(.system(size: 24 * zoomScale))
                    .foregroundStyle(.white.opacity(0.7))
                    .symbolRenderingMode(.monochrome)
            }
            
            Text("bypass.empty_title")
                .font(.system(size: 14 * zoomScale, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
            
            Text("bypass.empty_subtitle")
                .font(.system(size: 11 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Button(action: presentAddSheet) {
                Label("button.add_rule", systemImage: "plus")
                    .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12 * zoomScale)
                    .frame(height: 28 * zoomScale)
                    .background(accent.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16 * zoomScale)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        VStack(spacing: 0 * zoomScale) {
            HStack(spacing: 14 * zoomScale) {
                Text("bypass.footer_hint")
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                
                Spacer()
                
                Button(action: {
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                    detectionTask?.cancel()
                    detectionTask = Task {
                        let detected = await viewModel.detectLockedBrowser()
                        guard !Task.isCancelled else { return }
                        if let detected {
                            viewModel.showToast(message: String(format: String(localized: "bypass.toast.detected"), detected.browser))
                        } else {
                            viewModel.showToast(message: String(localized: "bypass.toast.not_detected"))
                        }
                    }
                }) {
                    HStack(spacing: 4 * zoomScale) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 10 * zoomScale))
                        Text("bypass.scan")
                            .font(.system(size: 11 * zoomScale, design: .monospaced))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.6))
                .disabled(viewModel.isDetecting)
                .opacity(viewModel.isDetecting ? 0.55 : 1)
            }
            .padding(.horizontal, 16 * zoomScale)
            .padding(.vertical, 8 * zoomScale)
        }
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

    private func presentAddSheet() {
        SoundEffectManager.shared.playButtonClick()
        HapticManager.shared.generic()
        showAddSheet = true
    }
}

// MARK: - Rule Row

struct RuleRow: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    let rule: BypassRule
    let onToggle: () -> Void
    let onRun: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    @State private var pressResetWorkItem: DispatchWorkItem?
    
    var body: some View {
        HStack(spacing: 8 * zoomScale) {
            Button(action: activate) {
                HStack(spacing: 10 * zoomScale) {
                    Image(systemName: rule.bypassType.iconName)
                        .font(.system(size: 18 * zoomScale, weight: .medium))
                        .foregroundStyle(rule.isEnabled ? .green : .white.opacity(0.3))
                        .frame(width: 24 * zoomScale)
                        .symbolRenderingMode(.monochrome)
                    
                    VStack(alignment: .leading, spacing: 2 * zoomScale) {
                        Text(rule.name)
                            .font(.system(size: 13 * zoomScale, weight: .medium, design: .monospaced))
                            .foregroundStyle(rule.isEnabled ? .white : .white.opacity(0.4))
                            .lineLimit(1)

                        Text(rule.bypassType.displayName)
                            .font(.system(size: 9 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!rule.isEnabled)
            .accessibilityLabel(Text(rule.name))
            .accessibilityHint(Text(String(format: String(localized: "bypass.context.run"), rule.bypassType.displayName)))

            Toggle("", isOn: .init(
                get: { rule.isEnabled },
                set: { _ in
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                    onToggle()
                }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .scaleEffect(0.7 * zoomScale)
            .accessibilityLabel(Text("bypass.enable_immediately"))
        }
        .padding(.horizontal, 16 * zoomScale)
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
                .allowsHitTesting(false)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .contextMenu {
            Button(String(format: String(localized: "bypass.context.run"), rule.bypassType.displayName)) {
                HapticManager.shared.generic()
                onRun()
            }
            .disabled(!rule.isEnabled)
            Button(String(localized: "button.edit")) {
                SoundEffectManager.shared.playButtonClick()
                HapticManager.shared.generic()
                onEdit()
            }
            Divider()
            Button(String(localized: "button.delete"), role: .destructive) {
                SoundEffectManager.shared.playButtonClick()
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
        .onDisappear {
            pressResetWorkItem?.cancel()
            pressResetWorkItem = nil
            isPressed = false
        }
    }

    private func activate() {
        Anim.with { isPressed = true }
        pressResetWorkItem?.cancel()
        let item = DispatchWorkItem {
            Anim.with { isPressed = false }
        }
        pressResetWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06, execute: item)
        onRun()
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
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    @ObservedObject var viewModel: BrowserBypasserViewModel
    var rule: BypassRule?
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var targetURLPattern: String = ""
    @State private var bypassType: BypassType = .exitFullscreen
    @State private var isEnabled: Bool = true

    private var draft: BrowserBypassRuleDraft {
        BrowserBypassRuleDraft(name: name, targetURLPattern: targetURLPattern)
    }

    private var bypassTypeBinding: Binding<BypassType> {
        Binding(
            get: { bypassType },
            set: { newValue in
                guard UserInteractionFeedbackPolicy.shouldEmit(
                    currentValue: bypassType,
                    newValue: newValue,
                    isUserInitiated: true
                ) else { return }
                bypassType = newValue
                SoundEffectManager.shared.playButtonClick()
                HapticManager.shared.generic()
            }
        )
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { isEnabled },
            set: { newValue in
                guard UserInteractionFeedbackPolicy.shouldEmit(
                    currentValue: isEnabled,
                    newValue: newValue,
                    isUserInitiated: true
                ) else { return }
                isEnabled = newValue
                SoundEffectManager.shared.playButtonClick()
                HapticManager.shared.generic()
            }
        )
    }
    
    var body: some View {
        VStack(spacing: 16 * zoomScale) {
            Text(rule == nil ? String(localized: "bypass.add_title") : String(localized: "bypass.edit_title"))
                .font(.system(size: 18 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            
            // Name
            VStack(alignment: .leading, spacing: 6 * zoomScale) {
                Text("field.name")
                    .font(.system(size: 11 * zoomScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                TextField("bypass.name_placeholder", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            // URL Pattern
            VStack(alignment: .leading, spacing: 6 * zoomScale) {
                Text("field.url_pattern")
                    .font(.system(size: 11 * zoomScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                TextField("bypass.url_placeholder", text: $targetURLPattern)
                    .textFieldStyle(.roundedBorder)
                
                // Common patterns
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6 * zoomScale) {
                        ForEach(viewModel.commonPatterns, id: \.pattern) { item in
                            Button(action: {
                                SoundEffectManager.shared.playButtonClick()
                                HapticManager.shared.generic()
                                name = item.name
                                targetURLPattern = item.pattern
                            }) {
                                Text(item.name)
                                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(.horizontal, 8 * zoomScale)
                                    .padding(.vertical, 4 * zoomScale)
                                    .background(Color(white: 0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4 * zoomScale)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1 * zoomScale)
                                    
                                        .allowsHitTesting(false))
                                    .cornerRadius(4 * zoomScale)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Bypass Type
            VStack(alignment: .leading, spacing: 6 * zoomScale) {
                Text("bypass.method")
                    .font(.system(size: 11 * zoomScale, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                
                Picker("", selection: bypassTypeBinding) {
                    ForEach(BypassType.allCases, id: \.self) { type in
                        HStack(spacing: 6 * zoomScale) {
                            Image(systemName: type.iconName)
                            VStack(alignment: .leading, spacing: 1 * zoomScale) {
                                Text(type.displayName)
                                    .font(.system(size: 12 * zoomScale, weight: .medium))
                                Text(type.description)
                                    .font(.system(size: 9 * zoomScale))
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
            Toggle("bypass.enable_immediately", isOn: enabledBinding)
                .font(.system(size: 11 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
            
            Spacer()
            
            HStack(spacing: 12 * zoomScale) {
                Button(String(localized: "button.cancel")) {
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(rule == nil ? String(localized: "button.add") : String(localized: "button.save")) {
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                    save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!draft.canSave)
            }
        }
        .padding(16 * zoomScale)
        .frame(width: 380 * zoomScale, height: 480 * zoomScale)
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
        let draft = draft
        guard draft.canSave else { return }
        if let existing = rule {
            let updated = BypassRule(
                id: existing.id,
                name: draft.name,
                targetURLPattern: draft.targetURLPattern,
                bypassType: bypassType,
                isEnabled: isEnabled,
                createdAt: existing.createdAt
            )
            viewModel.updateRule(updated)
        } else {
            let new = BypassRule(
                name: draft.name,
                targetURLPattern: draft.targetURLPattern,
                bypassType: bypassType,
                isEnabled: isEnabled
            )
            viewModel.addRule(new)
        }
        dismiss()
    }
}

#Preview {
    BrowserBypasserView(onClose: {})
}
