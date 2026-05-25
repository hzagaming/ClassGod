//
//  AddTabView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI
import AppKit

struct AddTabView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TabListViewModel

    let tab: BrowserTab?

    @State private var title: String
    @State private var url: String
    @State private var browser: BrowserType
    @State private var shortcutKey: String
    @State private var shortcutModifiers: UInt
    @State private var isRecording = false
    @State private var showConflictAlert = false
    @State private var shakeTrigger = false
    @State private var formOffset: CGFloat = 15
    @State private var formOpacity: Double = 0
    @State private var saveButtonScale: CGFloat = 1.0

    init(viewModel: TabListViewModel, tab: BrowserTab?) {
        self.viewModel = viewModel
        self.tab = tab
        _title = State(initialValue: tab?.title ?? "")
        _url = State(initialValue: tab?.url ?? "")
        _browser = State(initialValue: tab?.browser ?? Self.defaultBrowserForNewTab())
        _shortcutKey = State(initialValue: tab?.shortcutKey ?? "")
        _shortcutModifiers = State(initialValue: tab?.shortcutModifiers ?? 0)
    }

    var isEditing: Bool { tab != nil }

    var hasConflict: Bool {
        guard !shortcutKey.isEmpty && (shortcutModifiers != 0 || shortcutKey.uppercased().hasPrefix("F")) else {
            return false
        }
        return viewModel.hasShortcutConflict(
            excluding: tab?.id,
            key: shortcutKey,
            modifiers: shortcutModifiers
        )
    }

    var body: some View {
        VStack(spacing: 14) {
            header

            formContent
                .offset(y: formOffset)
                .opacity(formOpacity)

            actionButtons
                .offset(y: formOffset)
                .opacity(formOpacity)
        }
        .padding()
        .frame(width: 420, height: 340)
        .background(Color.black)
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .alert(String(localized: "shortcut.conflict.title"), isPresented: $showConflictAlert) {
            Button("覆盖", role: .destructive) {
                SoundEffectManager.shared.playButtonClick()
                performSave()
            }
            Button("算了", role: .cancel) {
                SoundEffectManager.shared.playButtonClick()
            }
        } message: {
            Text(String(localized: "shortcut.conflict.message"))
        }
        .onAppear {
            Anim.with {
                formOffset = 0
                formOpacity = 1
            }
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: isEditing ? "pencil.circle.fill" : "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .symbolRenderingMode(.monochrome)

            Text(isEditing ? String(localized: "edit_tab.title") : String(localized: "add_tab.title"))
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Spacer()
        }
    }

    private var formContent: some View {
        Form {
            Section {
                TextField(String(localized: "field.title"), text: $title)
                    .textFieldStyle(.plain)
                    .padding(6)
                    .background(Color(white: 0.1))
                    .overlay(Rectangle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .foregroundStyle(.white)

                TextField(String(localized: "field.url"), text: $url)
                    .textFieldStyle(.plain)
                    .padding(6)
                    .background(Color(white: 0.1))
                    .overlay(Rectangle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .foregroundStyle(.white)

                Picker(String(localized: "field.browser"), selection: $browser) {
                    ForEach(BrowserType.allCases) { b in
                        HStack {
                            Image(systemName: b == .safari ? "safari" : b == .chrome ? "globe" : "wave.3.forward")
                                .foregroundStyle(.white)
                            Text(b.displayName)
                                .foregroundStyle(.white)
                        }
                        .tag(b)
                    }
                }
                .pickerStyle(.segmented)
                .colorMultiply(.white)
            }

            Section(String(localized: "section.shortcut")) {
                ShortcutPicker(
                    key: $shortcutKey,
                    modifiers: $shortcutModifiers,
                    isRecording: $isRecording
                )
                .shake(trigger: shakeTrigger, intensity: 5)

                if hasConflict {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(String(localized: "shortcut.conflict.warning"))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.red)
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .background(Color.red.opacity(0.08))
                    .overlay(Rectangle().stroke(Color.red.opacity(0.3), lineWidth: 1))
                    .transition(.opacity)
                }
            }
        }
        .formStyle(.grouped)
        .foregroundStyle(.white)
    }

    private var actionButtons: some View {
        HStack {
            Button(String(localized: "button.cancel")) {
                SoundEffectManager.shared.playButtonClick()
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
            .foregroundStyle(.white.opacity(0.7))

            Spacer()

            Button(isEditing ? String(localized: "button.save_changes") : String(localized: "button.add_tab")) {
                SoundEffectManager.shared.playButtonClick()
                if hasConflict {
                    shakeTrigger.toggle()
                    SoundEffectManager.shared.play(.shortcutConflict)
                    HapticManager.shared.warning()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        showConflictAlert = true
                    }
                } else {
                    performSave()
                }
            }
            .keyboardShortcut(.return, modifiers: [])
            .disabled(title.isEmpty || url.isEmpty)
            .foregroundStyle(title.isEmpty || url.isEmpty ? .white.opacity(0.3) : .white)
        }
        .padding(.horizontal)
    }

    private func performSave() {
        let normalizedURL = normalizeURL(url)
        let newTab = BrowserTab(
            id: tab?.id ?? UUID(),
            title: title,
            url: normalizedURL,
            browser: browser,
            shortcutKey: shortcutKey,
            shortcutModifiers: shortcutModifiers,
            createdAt: tab?.createdAt ?? Date()
        )

        if isEditing {
            viewModel.updateTab(newTab)
        } else {
            viewModel.addTab(newTab)
        }

        SoundEffectManager.shared.playTabSaved()
        HapticManager.shared.success()
        dismiss()
    }

    private func normalizeURL(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return trimmed }
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return trimmed
        }
        return "https://" + trimmed
    }

    private static func defaultBrowserForNewTab() -> BrowserType {
        if let preferred = PreferencesManager.shared.preferences.defaultBrowser {
            return preferred
        }

        let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        return BrowserType.allCases.first { $0.bundleIdentifier == bundleID } ?? .safari
    }
}

#Preview {
    AddTabView(viewModel: TabListViewModel(), tab: nil)
}
