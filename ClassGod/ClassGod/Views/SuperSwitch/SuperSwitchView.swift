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
    @State private var searchText = ""
    @ObservedObject private var prefs = PreferencesManager.shared
    
    var onClose: () -> Void
    
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    private var visibleTargets: [SwitchTarget] {
        SuperSwitchCatalogPolicy.filteredTargets(viewModel.targets, query: searchText)
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0 * zoomScale) {
                header

                Divider()
                    .background(Color.white.opacity(0.1))

                if viewModel.targets.isEmpty {
                    emptyState
                } else {
                    searchBar
                    if visibleTargets.isEmpty {
                        noResultsState
                    } else {
                        targetList
                    }
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
            AddSwitchTargetView(viewModel: viewModel, target: nil)
        }
        .sheet(item: $editingTarget) { target in
            AddSwitchTargetView(viewModel: viewModel, target: target)
        }
        .alert(String(localized: "alert.error"), isPresented: $viewModel.showError) {
            Button(String(localized: "button.ok"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? String(localized: "error.unknown"))
        }
        .alert(String(localized: "superswitch.delete_title"), isPresented: .init(
            get: { targetToDelete != nil },
            set: { if !$0 { targetToDelete = nil } }
        )) {
            Button(String(localized: "button.cancel"), role: .cancel) { targetToDelete = nil }
            Button(String(localized: "button.delete"), role: .destructive) {
                if let target = targetToDelete {
                    viewModel.deleteTarget(target)
                }
                targetToDelete = nil
            }
        } message: {
            Text(String(format: String(localized: "superswitch.delete_message"), targetToDelete?.name ?? ""))
        }
        .overlay(
            toastOverlay,
            alignment: .bottom
        )
        .onAppear {
            viewModel.refreshRunningApplications()
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
            
            VStack(alignment: .leading, spacing: 0) {
                Text("SuperSwitch")
                    .font(.system(size: 16 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                
                Text("superswitch.subtitle")
                    .font(.system(size: 9 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Text("\(viewModel.targets.count)")
                .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(prefs.preferences.themeAccent.color)
                .padding(.horizontal, 6 * zoomScale)
                .padding(.vertical, 2 * zoomScale)
                .background(prefs.preferences.themeAccent.color.opacity(0.1))
                .clipShape(Capsule())
            
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
                .background(prefs.preferences.themeAccent.color.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("button.add"))
        }
        .padding(.horizontal, 16 * zoomScale)
        .padding(.vertical, 10 * zoomScale)
    }
    
    // MARK: - Target List

    private var searchBar: some View {
        HStack(spacing: 6 * zoomScale) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 9 * zoomScale))
                .foregroundStyle(.white.opacity(0.35))
            TextField("superswitch.search_placeholder", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
            if !searchText.isEmpty {
                Button {
                    SoundEffectManager.shared.playButtonClick()
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("button.clear"))
            }
        }
        .padding(.horizontal, 9 * zoomScale)
        .frame(height: 28 * zoomScale)
        .background(Color(white: 0.07))
        .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
        .padding(.horizontal, 10 * zoomScale)
        .padding(.vertical, 7 * zoomScale)
        .background(Color(white: 0.025))
    }
    
    private var targetList: some View {
        ScrollView {
            LazyVStack(spacing: 6 * zoomScale) {
                ForEach(visibleTargets) { target in
                    TargetRow(
                        target: target,
                        isRunning: viewModel.runningBundleIdentifiers.contains(target.bundleIdentifier),
                        onSwitch: {
                            viewModel.switchToTarget(target)
                        },
                        onEdit: {
                            editingTarget = target
                        },
                        onDelete: {
                            SoundEffectManager.shared.playButtonClick()
                            targetToDelete = target
                        }
                    )
                }
            }
            .padding(.horizontal, 8 * zoomScale)
            .padding(.vertical, 7 * zoomScale)
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
                
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 24 * zoomScale))
                    .foregroundStyle(.white.opacity(0.7))
                    .symbolRenderingMode(.monochrome)
            }
            
            Text("superswitch.empty_title")
                .font(.system(size: 14 * zoomScale, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))

            Text("superswitch.empty_subtitle")
                .font(.system(size: 11 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Button(action: presentAddSheet) {
                Label("button.add", systemImage: "plus")
                    .font(.system(size: 10 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12 * zoomScale)
                    .frame(height: 28 * zoomScale)
                    .background(prefs.preferences.themeAccent.color.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16 * zoomScale)
    }

    private var noResultsState: some View {
        VStack(spacing: 8 * zoomScale) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 22 * zoomScale))
                .foregroundStyle(prefs.preferences.themeAccent.color.opacity(0.65))
            Text("superswitch.no_results")
                .font(.system(size: 12 * zoomScale, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
            Text(String(format: String(localized: "superswitch.no_results_subtitle"), searchText))
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20 * zoomScale)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack(spacing: 14 * zoomScale) {
            Text(String(format: String(localized: "superswitch.target_count"), visibleTargets.count))
                .font(.system(size: 9 * zoomScale, design: .monospaced))
                .foregroundStyle(prefs.preferences.themeAccent.color.opacity(0.7))
            
            Spacer()

            Text("superswitch.footer_hint")
                .font(.system(size: 8 * zoomScale, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.horizontal, 16 * zoomScale)
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

    private func presentAddSheet() {
        SoundEffectManager.shared.playButtonClick()
        HapticManager.shared.generic()
        showAddSheet = true
    }
}

// MARK: - Target Row

struct TargetRow: View {
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    let target: SwitchTarget
    let isRunning: Bool
    let onSwitch: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    @State private var pressResetWorkItem: DispatchWorkItem?
    
    var body: some View {
        HStack(spacing: 4 * zoomScale) {
            Button(action: activate) {
                HStack(spacing: 9 * zoomScale) {
                    Image(systemName: target.iconName)
                        .font(.system(size: 17 * zoomScale, weight: .medium))
                        .foregroundStyle(isRunning ? prefs.preferences.themeAccent.color : .white.opacity(0.72))
                        .frame(width: 28 * zoomScale, height: 28 * zoomScale)
                        .background(isRunning ? prefs.preferences.themeAccent.color.opacity(0.1) : Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
                        .symbolRenderingMode(.monochrome)

                    VStack(alignment: .leading, spacing: 3 * zoomScale) {
                        HStack(spacing: 6 * zoomScale) {
                            Text(target.name)
                                .font(.system(size: 12 * zoomScale, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            statusChip
                        }

                        Text(target.bundleIdentifier)
                            .font(.system(size: 8 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.38))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .layoutPriority(1)

                    Spacer(minLength: 4 * zoomScale)

                    if target.isValidShortcut {
                        Text(target.shortcutDisplayString)
                            .font(.system(size: 9 * zoomScale, weight: .bold, design: .monospaced))
                            .foregroundStyle(prefs.preferences.themeAccent.color.opacity(0.85))
                            .padding(.horizontal, 6 * zoomScale)
                            .frame(height: 20 * zoomScale)
                            .background(prefs.preferences.themeAccent.color.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 4 * zoomScale))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(target.name)
            .accessibilityValue(Text(isRunning ? "superswitch.running" : "superswitch.not_running"))
            .accessibilityHint(Text("superswitch.switch_hint"))

            Menu {
                Button(String(localized: "button.edit")) {
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                    onEdit()
                }
                Divider()
                Button(String(localized: "button.delete"), role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 10 * zoomScale, weight: .bold))
                    .foregroundStyle(.white.opacity(isHovered ? 0.8 : 0.45))
                    .frame(width: 26 * zoomScale, height: 28 * zoomScale)
                    .background(Color.white.opacity(isHovered ? 0.08 : 0.035))
                    .clipShape(RoundedRectangle(cornerRadius: 5 * zoomScale))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel(Text("superswitch.more_actions"))
        }
        .padding(.horizontal, 8 * zoomScale)
        .frame(minHeight: 50 * zoomScale)
        .background(RoundedRectangle(cornerRadius: 7 * zoomScale).fill(backgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 7 * zoomScale)
                .stroke(borderColor, lineWidth: 1 * zoomScale)
                .allowsHitTesting(false)
        )
        .scaleEffect(isPressed ? 0.985 : 1.0)
        .contextMenu {
            Button(String(format: String(localized: "superswitch.context_switch"), target.name)) {
                onSwitch()
            }
            Button(String(localized: "button.edit")) {
                SoundEffectManager.shared.playButtonClick()
                HapticManager.shared.generic()
                onEdit()
            }
            Divider()
            Button(String(localized: "button.delete"), role: .destructive) {
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

    private var statusChip: some View {
        HStack(spacing: 3 * zoomScale) {
            Circle()
                .fill(isRunning ? Color.green : Color.white.opacity(0.3))
                .frame(width: 5 * zoomScale, height: 5 * zoomScale)
            Text(isRunning ? "superswitch.running" : "superswitch.not_running")
                .lineLimit(1)
        }
        .font(.system(size: 6.5 * zoomScale, weight: .bold, design: .monospaced))
        .foregroundStyle(isRunning ? .green : .white.opacity(0.35))
    }

    private func activate() {
        Anim.with { isPressed = true }
        pressResetWorkItem?.cancel()
        let item = DispatchWorkItem {
            Anim.with { isPressed = false }
        }
        pressResetWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06, execute: item)
        onSwitch()
    }
    
    private var backgroundColor: Color {
        if isPressed {
            return Color.white.opacity(0.15)
        } else if isHovered {
            return Color.white.opacity(0.1)
        } else if isRunning {
            return prefs.preferences.themeAccent.color.opacity(0.045)
        } else {
            return Color.white.opacity(0.025)
        }
    }
    
    private var borderColor: Color {
        if isHovered {
            return Color.white.opacity(0.25)
        } else if isRunning {
            return prefs.preferences.themeAccent.color.opacity(0.16)
        } else {
            return Color.white.opacity(0.07)
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
    private var sheetScale: CGFloat { min(zoomScale, 1.35) }
    private var draft: SuperSwitchTargetDraft {
        SuperSwitchTargetDraft(name: name, bundleIdentifier: bundleIdentifier)
    }
    private var runningAppSelection: Binding<Int> {
        Binding(
            get: { selectedAppIndex },
            set: { selectRunningApp(at: $0, isUserInitiated: true) }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10 * sheetScale) {
                Image(systemName: target == nil ? "plus.app.fill" : "slider.horizontal.3")
                    .font(.system(size: 17 * sheetScale, weight: .semibold))
                    .foregroundStyle(prefs.preferences.themeAccent.color)
                    .frame(width: 32 * sheetScale, height: 32 * sheetScale)
                    .background(prefs.preferences.themeAccent.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 7 * sheetScale))

                VStack(alignment: .leading, spacing: 1 * sheetScale) {
                    Text(target == nil ? String(localized: "superswitch.add_title") : String(localized: "superswitch.edit_title"))
                        .font(.system(size: 15 * sheetScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("superswitch.form_subtitle")
                        .font(.system(size: 8 * sheetScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Button {
                    SoundEffectManager.shared.playButtonClick()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10 * sheetScale, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(width: 26 * sheetScale, height: 26 * sheetScale)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("button.close"))
            }
            .padding(14 * sheetScale)

            Divider().background(Color.white.opacity(0.1))

            ScrollView {
                VStack(spacing: 12 * sheetScale) {
                    formSection(title: "superswitch.running_app", icon: "app.badge") {
                        HStack(spacing: 6 * sheetScale) {
                            Picker("", selection: runningAppSelection) {
                                Text("superswitch.custom").tag(-1)
                                ForEach(0..<runningApps.count, id: \.self) { index in
                                    Text(runningApps[index].name).tag(index)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)

                            Button {
                                loadRunningApps()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 10 * sheetScale, weight: .semibold))
                                    .frame(width: 28 * sheetScale, height: 28 * sheetScale)
                                    .background(Color.white.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 5 * sheetScale))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("superswitch.refresh_apps"))
                        }
                    }

                    formSection(title: "superswitch.details", icon: "text.alignleft") {
                        VStack(spacing: 8 * sheetScale) {
                            labeledField(label: "field.name", placeholder: "superswitch.name_placeholder", text: $name)
                            labeledField(label: "field.bundle_identifier", placeholder: "superswitch.bundle_placeholder", text: $bundleIdentifier)
                        }
                    }

                    formSection(title: "field.icon", icon: "square.grid.3x3") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 7 * sheetScale) {
                                ForEach(iconOptions, id: \.self) { icon in
                                    Button {
                                        SoundEffectManager.shared.playButtonClick()
                                        HapticManager.shared.generic()
                                        iconName = icon
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.system(size: 16 * sheetScale))
                                            .foregroundStyle(iconName == icon ? .black : .white.opacity(0.6))
                                            .frame(width: 34 * sheetScale, height: 34 * sheetScale)
                                            .background(iconName == icon ? prefs.preferences.themeAccent.color.opacity(0.88) : Color.white.opacity(0.04))
                                            .clipShape(RoundedRectangle(cornerRadius: 6 * sheetScale))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6 * sheetScale)
                                                    .stroke(Color.white.opacity(iconName == icon ? 0 : 0.08), lineWidth: 1 * sheetScale)
                                                    .allowsHitTesting(false)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(Text(String(format: String(localized: "accessibility.select_icon_format"), icon)))
                                }
                            }
                        }
                    }

                    formSection(title: "superswitch.shortcut_optional", icon: "command") {
                        ShortcutPicker(key: $shortcutKey, modifiers: $shortcutModifiers, isRecording: $isRecordingShortcut)
                    }
                }
                .padding(12 * sheetScale)
            }

            Divider().background(Color.white.opacity(0.1))

            HStack(spacing: 10 * sheetScale) {
                Button(String(localized: "button.cancel")) {
                    SoundEffectManager.shared.playButtonClick()
                    HapticManager.shared.generic()
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(target == nil ? String(localized: "button.add") : String(localized: "button.save")) {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .tint(prefs.preferences.themeAccent.color)
                .disabled(!draft.canSave)
            }
            .padding(12 * sheetScale)
        }
        .frame(width: 380 * sheetScale, height: 520 * sheetScale)
        .background(Color(white: 0.025))
        .overlay(
            RoundedRectangle(cornerRadius: 10 * sheetScale)
                .stroke(Color.white.opacity(0.12), lineWidth: 1 * sheetScale)
                .allowsHitTesting(false)
        )
        .preferredColorScheme(.dark)
        .onAppear {
            loadRunningApps(playFeedback: false)
            if let target = target {
                name = target.name
                bundleIdentifier = target.bundleIdentifier
                iconName = target.iconName
                shortcutKey = target.shortcutKey
                shortcutModifiers = target.shortcutModifiers
                if let index = runningApps.firstIndex(where: { $0.bundleID == target.bundleIdentifier }) {
                    selectedAppIndex = index
                }
            }
        }
    }

    private func formSection<Content: View>(
        title: LocalizedStringKey,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8 * sheetScale) {
            Label(title, systemImage: icon)
                .font(.system(size: 9 * sheetScale, weight: .bold, design: .monospaced))
                .foregroundStyle(prefs.preferences.themeAccent.color.opacity(0.8))
            content()
        }
        .padding(10 * sheetScale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 8 * sheetScale))
        .overlay(
            RoundedRectangle(cornerRadius: 8 * sheetScale)
                .stroke(Color.white.opacity(0.07), lineWidth: 1 * sheetScale)
                .allowsHitTesting(false)
        )
    }

    private func labeledField(
        label: LocalizedStringKey,
        placeholder: LocalizedStringKey,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4 * sheetScale) {
            Text(label)
                .font(.system(size: 8 * sheetScale, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 10 * sheetScale, design: .monospaced))
                .padding(.horizontal, 8 * sheetScale)
                .frame(height: 30 * sheetScale)
                .background(Color.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 5 * sheetScale))
                .overlay(
                    RoundedRectangle(cornerRadius: 5 * sheetScale)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1 * sheetScale)
                        .allowsHitTesting(false)
                )
        }
    }

    private func loadRunningApps(playFeedback: Bool = true) {
        if playFeedback {
            SoundEffectManager.shared.playButtonClick()
            HapticManager.shared.generic()
        }
        let selectedBundleIdentifier = runningApps.indices.contains(selectedAppIndex)
            ? runningApps[selectedAppIndex].bundleID
            : bundleIdentifier
        runningApps = viewModel.getRunningApps()
        selectedAppIndex = runningApps.firstIndex { $0.bundleID == selectedBundleIdentifier } ?? -1
    }

    private func selectRunningApp(at index: Int, isUserInitiated: Bool) {
        let shouldEmitFeedback = UserInteractionFeedbackPolicy.shouldEmit(
            currentValue: selectedAppIndex,
            newValue: index,
            isUserInitiated: isUserInitiated
        )
        selectedAppIndex = index
        if shouldEmitFeedback {
            SoundEffectManager.shared.playButtonClick()
            HapticManager.shared.generic()
        }
        guard runningApps.indices.contains(index) else { return }
        name = runningApps[index].name
        bundleIdentifier = runningApps[index].bundleID
    }
    
    private func save() {
        SoundEffectManager.shared.playButtonClick()
        HapticManager.shared.success()
        let draft = draft
        guard draft.canSave else { return }
        if let existing = target {
            let updated = SwitchTarget(
                id: existing.id,
                name: draft.name,
                bundleIdentifier: draft.bundleIdentifier,
                iconName: iconName,
                shortcutKey: shortcutKey,
                shortcutModifiers: shortcutModifiers,
                createdAt: existing.createdAt
            )
            viewModel.updateTarget(updated)
        } else {
            let new = SwitchTarget(
                name: draft.name,
                bundleIdentifier: draft.bundleIdentifier,
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
