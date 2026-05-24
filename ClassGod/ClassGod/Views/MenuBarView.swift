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
        .background(Color.black)
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .sheet(isPresented: $showAddSheet) {
            AddTabView(viewModel: viewModel, tab: nil)
        }
        .sheet(item: $editingTab) { tab in
            AddTabView(viewModel: viewModel, tab: tab)
        }
        .alert(String(localized: "error.title"), isPresented: $viewModel.showError) {
            Button(String(localized: "button.ok"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? String(localized: "error.unknown"))
        }
        .alert(String(localized: "permission.required.title"), isPresented: $viewModel.showPermissionAlert) {
            Button(String(localized: "button.open_settings")) {
                openAccessibilitySettings()
            }
            Button(String(localized: "button.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "permission.required.message"))
        }
        .alert(String(localized: "delete.confirm.title"), isPresented: .init(
            get: { tabToDelete != nil },
            set: { if !$0 { tabToDelete = nil } }
        )) {
            Button(String(localized: "button.cancel"), role: .cancel) { tabToDelete = nil }
            Button(String(localized: "button.delete"), role: .destructive) {
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
            Text(String(format: String(localized: "delete.confirm.message"), tabToDelete?.title ?? ""))
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
            
            viewModel.checkPermissionOnShow()
            
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
                .offset(y: toastOffset)
                .transition(.opacity)
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
                .foregroundStyle(.white)
                .symbolRenderingMode(.monochrome)
            
            Text("ClassGod")
                .font(.system(prefs.preferences.useCompactMode ? .subheadline : .headline, design: .monospaced))
                .foregroundStyle(.white)
            
            Spacer()
            
            Button(action: {
                SoundEffectManager.shared.playButtonClick()
                _ = viewModel.checkAccessibilityPermission()
            }) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(viewModel.isAccessibilityTrusted ? .white : .red)
                    .symbolRenderingMode(.monochrome)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "accessibility.check_permission"))
            .help(String(localized: "accessibility.check_permission"))
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
                            Button(String(localized: "context.open")) {
                                viewModel.switchToTab(tab)
                            }
                            Button(String(localized: "context.edit")) {
                                editingTab = tab
                            }
                            Divider()
                            Button(String(localized: "button.delete"), role: .destructive) {
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
            
            Text(String(localized: "empty.title"))
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
            
            Text(String(localized: "empty.subtitle"))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
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
                    Text(String(localized: "button.save_current_tab"))
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(white: 0.08))
            .overlay(
                Rectangle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            Divider()
            
            HStack(spacing: 12) {
                Button(String(localized: "button.settings")) {
                    SoundEffectManager.shared.playButtonClick()
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.7))
                
                Button(String(localized: "button.automation")) {
                    SoundEffectManager.shared.playButtonClick()
                    openAutomationSettings()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.7))
                
                Spacer()
                
                Button(String(localized: "button.quit")) {
                    SoundEffectManager.shared.playButtonClick()
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.7))
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
                        .font(.system(size: prefs.preferences.useCompactMode ? 12 : 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    if prefs.preferences.showURLPreview {
                        Text(tab.url)
                            .font(.system(size: prefs.preferences.useCompactMode ? 9 : 10, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if prefs.preferences.showShortcutBadge && tab.isValidShortcut {
                    Text(tab.shortcutDisplayString)
                        .font(.system(size: prefs.preferences.useCompactMode ? 10 : 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color(white: 0.15))
                        .overlay(
                            Rectangle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, prefs.preferences.useCompactMode ? 4 : 8)
            .frame(minHeight: prefs.preferences.rowHeight)
            .contentShape(Rectangle())
            .background(
                Rectangle()
                    .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
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
                    .foregroundStyle(.white.opacity(0.8))
            case .chrome:
                Image(systemName: "globe")
                    .foregroundStyle(.white.opacity(0.8))
            case .edge:
                Image(systemName: "wave.3.forward")
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .font(.system(size: prefs.preferences.useCompactMode ? 14 : 16, weight: .medium))
        .frame(width: 20)
        .symbolRenderingMode(.monochrome)
    }
}

#Preview {
    MenuBarView()
}
