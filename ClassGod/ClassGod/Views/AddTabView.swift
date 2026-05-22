//
//  AddTabView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

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
        _browser = State(initialValue: tab?.browser ?? .safari)
        _shortcutKey = State(initialValue: tab?.shortcutKey ?? "")
        _shortcutModifiers = State(initialValue: tab?.shortcutModifiers ?? 0)
    }
    
    var isEditing: Bool { tab != nil }
    
    var hasConflict: Bool {
        guard !shortcutKey.isEmpty && shortcutModifiers != 0 else { return false }
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
        .background(Color(NSColor.controlBackgroundColor))
        .alert("Shortcut Conflict", isPresented: $showConflictAlert) {
            Button("Overwrite", role: .destructive) {
                SoundEffectManager.shared.playButtonClick()
                performSave()
            }
            Button("Cancel", role: .cancel) {
                SoundEffectManager.shared.playButtonClick()
            }
        } message: {
            Text("Another tab is already using this shortcut. Overwrite?")
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
                .foregroundStyle(Color.accentColor)
                .symbolRenderingMode(.hierarchical)
                .bounce(intensity: 1.08)
            
            Text(isEditing ? "Edit Tab" : "Add Tab")
                .font(.title3)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
    
    private var formContent: some View {
        Form {
            Section {
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                
                TextField("URL", text: $url)
                    .textFieldStyle(.roundedBorder)
                
                Picker("Browser", selection: $browser) {
                    ForEach(BrowserType.allCases) { b in
                        HStack {
                            Image(systemName: b == .safari ? "safari" : b == .chrome ? "globe" : "wave.3.forward")
                            Text(b.displayName)
                        }
                        .tag(b)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("Shortcut") {
                ShortcutPicker(
                    key: $shortcutKey,
                    modifiers: $shortcutModifiers,
                    isRecording: $isRecording
                )
                .shake(trigger: shakeTrigger, intensity: 5)
                
                if hasConflict {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("This shortcut is already used by another tab.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .transition(.opacity)
                }
            }
        }
        .formStyle(.grouped)
    }
    
    private var actionButtons: some View {
        HStack {
            Button("Cancel") {
                SoundEffectManager.shared.playButtonClick()
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
            .pressScale(0.92)
            
            Spacer()
            
            Button(isEditing ? "Save Changes" : "Add Tab") {
                SoundEffectManager.shared.playButtonClick()
                if hasConflict {
                    shakeTrigger.toggle()
                    SoundEffectManager.shared.play(.shortcutConflict)
                    HapticManager.shared.warning()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        showConflictAlert = true
                    }
                } else {
                    Anim.with {
                        saveButtonScale = 0.95
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                        Anim.with {
                            saveButtonScale = 1.0
                        }
                    }
                    performSave()
                }
            }
            .keyboardShortcut(.return, modifiers: [])
            .disabled(title.isEmpty || url.isEmpty)
            .scaleEffect(saveButtonScale)
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
}

#Preview {
    AddTabView(viewModel: TabListViewModel(), tab: nil)
}
