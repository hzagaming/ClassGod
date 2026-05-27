//
//  MenuBarView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

struct DestinTabView: View {
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
    
    var onClose: () -> Void

    var body: some View {
        ZStack {
            // Base content
            VStack(alignment: .leading, spacing: 0) {
                header
                    .scaleEffect(headerScale)
                    .opacity(headerOpacity)

                headerDivider
                    .opacity(headerOpacity)

                tabList

                Divider()
                    .opacity(headerOpacity)

                footer
                    .opacity(headerOpacity)
            }
            
            // Scanline overlay
            scanlineOverlay
                .allowsHitTesting(false)
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

            if prefs.preferences.autoDetectOnShow {
                viewModel.detectCurrentTabOnShowIfNeeded()
            }

            Anim.with {
                headerScale = 1.0
                headerOpacity = 1.0
            }
            
            // Permission check is now user-initiated only — no blocking on open
        }
        .onDisappear {
            toastWorkItem?.cancel()
            toastWorkItem = nil
            showToast = false
            headerScale = 0.98
            headerOpacity = 0
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

    // MARK: - Permission Banner

    private var permissionBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.red)

            Text(String(localized: "permission.banner.message"))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.red.opacity(0.9))

            Spacer()

            Button(String(localized: "permission.banner.button")) {
                SoundEffectManager.shared.playButtonClick()
                openAccessibilitySettings()
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
                .stroke(Color.red.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Scanline Overlay
    
    private var scanlineOverlay: some View {
        GeometryReader { geo in
            VStack(spacing: 2) {
                ForEach(0..<Int(geo.size.height / 4), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.015))
                        .frame(height: 1)
                    Spacer()
                        .frame(height: 3)
                }
            }
        }
    }
    
    private var headerDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.clear, Color.white.opacity(0.15), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            // Close button
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

            VStack(alignment: .leading, spacing: 0) {
                Text("DestinTab")
                    .font(.system(prefs.preferences.useCompactMode ? .subheadline : .headline, design: .monospaced))
                    .foregroundStyle(.white)
                
                Text("Manage & switch browser tabs")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }

            if prefs.preferences.showTabCountBadge {
                Text("\(viewModel.tabs.count)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(white: 0.14))
                    .overlay(
                        Rectangle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
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
            .accessibilityLabel(String(localized: "button.add_tab"))
            .help(String(localized: "button.add_tab"))

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
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 52, height: 52)

                Image(systemName: "link.badge.plus")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.7))
                    .symbolRenderingMode(.monochrome)
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
                        .symbolRenderingMode(.monochrome)
                    Text(String(localized: "button.save_current_tab"))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color(white: 0.06), Color(white: 0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Rectangle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                if Anim.enabled {
                    withAnimation(.easeOut(duration: Anim.duration)) {
                        // Handled by overlay
                    }
                }
            }

            Divider()

            HStack(spacing: 14) {
                footerButton(title: String(localized: "button.settings"), icon: "gear") {
                    SoundEffectManager.shared.playButtonClick()
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                
                footerButton(title: String(localized: "button.automation"), icon: "lock.shield") {
                    SoundEffectManager.shared.playButtonClick()
                    openAutomationSettings()
                }

                Spacer()


            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
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
        .onHover { hovering in
            if Anim.enabled {
                withAnimation(.easeOut(duration: Anim.duration)) {
                    // Visual feedback handled by SwiftUI hover
                }
            }
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
    @FocusState private var isFocused: Bool
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
                    .fill(backgroundColor)
            )
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .focusable(prefs.preferences.enableKeyboardNavigation)
        .focused($isFocused)
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

    private var backgroundColor: Color {
        if isPressed {
            return Color.white.opacity(0.15)
        } else if isHovered {
            return Color.white.opacity(0.1)
        } else if isFocused {
            return Color.white.opacity(0.18)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isHovered || isFocused {
            return Color.white.opacity(0.25)
        } else {
            return Color.clear
        }
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
    DestinTabView(onClose: {})
}
