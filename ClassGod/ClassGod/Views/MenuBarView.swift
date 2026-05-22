//
//  MenuBarView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

struct MenuBarView: View {
    @StateObject private var viewModel = TabListViewModel()
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var showAddSheet = false
    @State private var editingTab: BrowserTab?
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var toastOffset: CGFloat = 20
    @State private var tabToDelete: BrowserTab?
    @State private var headerScale: CGFloat = 0.98
    @State private var headerOpacity: Double = 0
    @State private var toastWorkItem: DispatchWorkItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .scaleEffect(headerScale)
                .opacity(headerOpacity)
            
            Divider()
                .opacity(headerOpacity)
            
            tabList
            
            Divider()
                .opacity(headerOpacity)
            
            footer
                .opacity(headerOpacity)
        }
        .frame(width: prefs.preferences.panelWidth)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
        )
        .sheet(isPresented: $showAddSheet) {
            AddTabView(viewModel: viewModel, tab: nil)
        }
        .sheet(item: $editingTab) { tab in
            AddTabView(viewModel: viewModel, tab: tab)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .alert("Accessibility Permission Required", isPresented: $viewModel.showPermissionAlert) {
            Button("Open Settings") {
                openAccessibilitySettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("ClassGod needs Accessibility permission to detect and switch browser tabs. Please enable it in System Settings > Privacy & Security > Accessibility.")
        }
        .alert("Delete Tab?", isPresented: .init(
            get: { tabToDelete != nil },
            set: { if !$0 { tabToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { tabToDelete = nil }
            Button("Delete", role: .destructive) {
                if let tab = tabToDelete {
                    Anim.with {
                        viewModel.deleteTab(tab)
                    }
                    SoundEffectManager.shared.playTabDeleted()
                    HapticManager.shared.warning()
                }
                tabToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete \"\(tabToDelete?.title ?? "")\"?")
        }
        .overlay(
            toastOverlay,
            alignment: .bottom
        )
        .onAppear {
            viewModel.onShowToast = { [weak viewModel] msg in
                guard viewModel != nil else { return }
                guard prefs.preferences.showToastNotifications else { return }
                showToast(message: msg)
            }
            
            Anim.with {
                headerScale = 1.0
                headerOpacity = 1.0
            }
            SoundEffectManager.shared.playPopoverOpen()
        }
        .onDisappear {
            toastWorkItem?.cancel()
            toastWorkItem = nil
        }
    }
    
    // MARK: - Toast Overlay
    
    private var toastOverlay: some View {
        Group {
            if showToast, let message = toastMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(message)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.green.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                .padding(.bottom, 10)
                .offset(y: toastOffset)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private func showToast(message: String) {
        toastWorkItem?.cancel()
        toastMessage = message
        toastOffset = 20
        showToast = true
        
        Anim.with {
            toastOffset = 0
        }
        
        let item = DispatchWorkItem {
            Anim.with {
                toastOffset = 20
                showToast = false
            }
        }
        toastWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + prefs.preferences.toastDuration, execute: item)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: prefs.preferences.menuBarIconStyle.systemImageName)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .symbolRenderingMode(.hierarchical)
                .bounce(intensity: 1.05)
            
            Text("ClassGod")
                .font(prefs.preferences.useCompactMode ? .subheadline : .headline)
            
            Spacer()
            
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                _ = viewModel.checkAccessibilityPermission()
            }) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.green)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .pressScale(0.85)
            .accessibilityLabel("Accessibility permission status")
            .help("Accessibility permission status")
        }
        .padding(.horizontal)
        .padding(.vertical, prefs.preferences.useCompactMode ? 6 : 10)
    }
    
    // MARK: - Tab List
    
    private var tabList: some View {
        ScrollView {
            if viewModel.tabs.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    let visibleTabs = Array(viewModel.tabs.prefix(prefs.preferences.maxTabsInPopover))
                    ForEach(visibleTabs) { tab in
                        TabRow(tab: tab) {
                            viewModel.switchToTab(tab)
                        } onEdit: {
                            editingTab = tab
                        } onDelete: {
                            if prefs.preferences.confirmBeforeDelete {
                                tabToDelete = tab
                            } else {
                                Anim.with {
                                    viewModel.deleteTab(tab)
                                }
                                SoundEffectManager.shared.playTabDeleted()
                                HapticManager.shared.warning()
                            }
                        }
                        .contextMenu {
                            Button("Open") {
                                viewModel.switchToTab(tab)
                            }
                            Button("Edit") {
                                editingTab = tab
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                if prefs.preferences.confirmBeforeDelete {
                                    tabToDelete = tab
                                } else {
                                    Anim.with {
                                        viewModel.deleteTab(tab)
                                    }
                                    SoundEffectManager.shared.playTabDeleted()
                                    HapticManager.shared.warning()
                                }
                            }
                        }
                        .transition(.opacity)
                        if tab.id != visibleTabs.last?.id {
                            Divider()
                                .padding(.leading, prefs.preferences.showBrowserIcon ? 40 : 16)
                                .opacity(0.5)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: prefs.preferences.panelMaxHeight)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 52, height: 52)
                
                Image(systemName: "link.badge.plus")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.accentColor)
                    .symbolRenderingMode(.hierarchical)
            }
            .bounce(intensity: 1.03)
            
            Text("No saved tabs yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Click \"Add Current Tab\" to save a browser tab")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: prefs.preferences.useCompactMode ? 80 : 120)
        .padding()
        .slideIn(from: .bottom, delay: 0.05)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        VStack(spacing: 0) {
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                Anim.with {
                    viewModel.detectAndAddCurrentTab()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add Current Tab")
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.1), Color.accentColor.opacity(0.04)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .pressScale(0.97)
            
            Divider()
            
            HStack(spacing: 12) {
                Button("Settings...") {
                    SoundEffectManager.shared.playButtonClick()
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .pressScale(0.9)
                
                Button("Automation...") {
                    SoundEffectManager.shared.playButtonClick()
                    openAutomationSettings()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .pressScale(0.9)
                
                Spacer()
                
                Button("Quit") {
                    SoundEffectManager.shared.playButtonClick()
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .pressScale(0.9)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }
    
    private func openAutomationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") else { return }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - TabRow

struct TabRow: View {
    let tab: BrowserTab
    let onOpen: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    @ObservedObject private var prefs = PreferencesManager.shared
    
    var body: some View {
        Button(action: {
            SoundEffectManager.shared.playButtonClick()
            Anim.with {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                Anim.with {
                    isPressed = false
                }
            }
            onOpen()
        }) {
            HStack(spacing: 10) {
                if prefs.preferences.showBrowserIcon {
                    browserIcon
                }
                
                VStack(alignment: .leading, spacing: prefs.preferences.useCompactMode ? 0 : 2) {
                    Text(tab.title)
                        .font(.system(size: prefs.preferences.useCompactMode ? 12 : 13, weight: .medium))
                        .lineLimit(1)
                    
                    if prefs.preferences.showURLPreview {
                        Text(tab.url)
                            .font(.system(size: prefs.preferences.useCompactMode ? 9 : 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if prefs.preferences.showShortcutBadge && tab.isValidShortcut {
                    Text(tab.shortcutDisplayString)
                        .font(.system(size: prefs.preferences.useCompactMode ? 10 : 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.secondary.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .stroke(Color.secondary.opacity(0.12), lineWidth: 0.5)
                                )
                        )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, prefs.preferences.useCompactMode ? 4 : 8)
            .frame(minHeight: prefs.preferences.rowHeight)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovered ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .help(tab.url)
        .onHover { hovering in
            if Anim.enabled {
                withAnimation(.easeOut(duration: Anim.duration)) {
                    isHovered = hovering
                }
            } else {
                isHovered = hovering
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
    }
    
    private var browserIcon: some View {
        Group {
            switch tab.browser {
            case .safari:
                Image(systemName: "safari")
                    .foregroundStyle(.blue)
            case .chrome:
                Image(systemName: "globe")
                    .foregroundStyle(.green)
            case .edge:
                Image(systemName: "wave.3.forward")
                    .foregroundStyle(.cyan)
            }
        }
        .font(.system(size: prefs.preferences.useCompactMode ? 14 : 16, weight: .medium))
        .frame(width: 20)
        .symbolRenderingMode(.hierarchical)
    }
}

#Preview {
    MenuBarView()
}
