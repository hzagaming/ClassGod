//
//  AddPanicAppView.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import SwiftUI

struct AddPanicAppView: View {
    @ObservedObject var viewModel: AssessPrepHackViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }
    
    let app: PanicApp?
    
    @State private var name: String = ""
    @State private var bundleIdentifier: String = ""
    @State private var selectedIcon: String = "app.fill"
    @State private var selectedTechnique: AssessPrepBypassTechnique = .panicSwitch
    @State private var isEnabled: Bool = true
    
    private let icons = [
        "app.fill", "safari.fill", "note.text", "function", "terminal.fill",
        "doc.text", "eye", "calendar", "message.fill", "mail.fill",
        "folder.fill", "book.fill", "graduationcap.fill", "paperplane.fill",
        "command", "keyboard.fill", "display", "globe", "link",
        "bolt.fill", "shield.fill", "lock.open.fill", "key.fill"
    ]
    
    private var isEditing: Bool { app != nil }
    
    var body: some View {
        VStack(spacing: 0 * zoomScale) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10 * zoomScale, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                        .background(Color(white: 0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(isEditing ? String(localized: "panic.edit_title") : String(localized: "panic.add_title"))
                    .font(.system(size: 16 * zoomScale, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button(action: save) {
                    Text(isEditing ? String(localized: "button.save") : String(localized: "button.add"))
                        .font(.system(size: 12 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(isValid ? .white : .white.opacity(0.3))
                        .padding(.horizontal, 12 * zoomScale)
                        .padding(.vertical, 4 * zoomScale)
                        .background(isValid ? Color.red.opacity(0.2) : Color(white: 0.08))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .disabled(!isValid)
            }
            .padding()
            .background(Color(white: 0.03))
            
            Divider().background(Color.white.opacity(0.1))
            
            // Form
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16 * zoomScale) {
                    // Name
                    formField(title: "Name") {
                        TextField("", text: $name)
                            .font(.system(size: 13 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(8 * zoomScale)
                            .background(Color(white: 0.06))
                            .cornerRadius(6 * zoomScale)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6 * zoomScale)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1 * zoomScale)
                            
                                .allowsHitTesting(false))
                    }
                    
                    // Bundle ID
                    formField(title: "Bundle Identifier") {
                        TextField("", text: $bundleIdentifier)
                            .font(.system(size: 13 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(8 * zoomScale)
                            .background(Color(white: 0.06))
                            .cornerRadius(6 * zoomScale)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6 * zoomScale)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1 * zoomScale)
                            
                                .allowsHitTesting(false))
                    }
                    
                    // Technique picker
                    formField(title: "Bypass Technique") {
                        VStack(spacing: 4 * zoomScale) {
                            ForEach(AssessPrepBypassTechnique.allCases) { technique in
                                Button(action: {
                                    SoundEffectManager.shared.playButtonClick()
                                    HapticManager.shared.generic()
                                    selectedTechnique = technique
                                }) {
                                    HStack(spacing: 8 * zoomScale) {
                                        Image(systemName: technique.iconName)
                                            .font(.system(size: 14 * zoomScale))
                                            .foregroundStyle(selectedTechnique == technique ? .red : .white.opacity(0.4))
                                            .frame(width: 20 * zoomScale)
                                        
                                        VStack(alignment: .leading, spacing: 1 * zoomScale) {
                                            Text(technique.displayName)
                                                .font(.system(size: 12 * zoomScale, weight: .medium, design: .monospaced))
                                                .foregroundStyle(selectedTechnique == technique ? .white : .white.opacity(0.5))
                                            Text(technique.description)
                                                .font(.system(size: 9 * zoomScale, design: .monospaced))
                                                .foregroundStyle(.white.opacity(0.3))
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedTechnique == technique {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10 * zoomScale, weight: .bold))
                                                .foregroundStyle(.red)
                                        }
                                    }
                                    .padding(.horizontal, 10 * zoomScale)
                                    .padding(.vertical, 8 * zoomScale)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6 * zoomScale)
                                            .fill(selectedTechnique == technique ? Color.red.opacity(0.08) : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6 * zoomScale)
                                            .stroke(selectedTechnique == technique ? Color.red.opacity(0.2) : Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
                                    
                                        .allowsHitTesting(false))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Icon picker
                    formField(title: "Icon") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 36 * zoomScale))], spacing: 8 * zoomScale) {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: {
                                    SoundEffectManager.shared.playButtonClick()
                                    HapticManager.shared.generic()
                                    selectedIcon = icon
                                }) {
                                    Image(systemName: icon)
                                        .font(.system(size: 16 * zoomScale))
                                        .foregroundStyle(selectedIcon == icon ? .red : .white.opacity(0.4))
                                        .frame(width: 36 * zoomScale, height: 36 * zoomScale)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6 * zoomScale)
                                                .fill(selectedIcon == icon ? Color.red.opacity(0.1) : Color(white: 0.06))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6 * zoomScale)
                                                .stroke(selectedIcon == icon ? Color.red.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1 * zoomScale)
                                        
                                            .allowsHitTesting(false))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Enabled toggle
                    HStack {
                        Text(String(localized: "panic.enabled"))
                            .font(.system(size: 11 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Toggle("", isOn: $isEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                    }
                }
                .padding()
            }
        }
        .frame(width: 340 * zoomScale, height: 500 * zoomScale)
        .background(Color.black)
        .onAppear {
            if let app = app {
                name = app.name
                bundleIdentifier = app.bundleIdentifier
                selectedIcon = app.iconName
                selectedTechnique = app.bypassTechnique
                isEnabled = app.isEnabled
            }
        }
    }
    
    private func formField<Content: View>(title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6 * zoomScale) {
            Text(title)
                .font(.system(size: 10 * zoomScale, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
            
            content()
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !bundleIdentifier.isEmpty
    }
    
    private func save() {
        guard isValid else { return }
        
        if let existing = app {
            var updated = existing
            updated.name = name
            updated.bundleIdentifier = bundleIdentifier
            updated.iconName = selectedIcon
            updated.bypassTechnique = selectedTechnique
            updated.isEnabled = isEnabled
            viewModel.updateApp(updated)
        } else {
            let newApp = PanicApp(
                name: name,
                bundleIdentifier: bundleIdentifier,
                iconName: selectedIcon,
                bypassTechnique: selectedTechnique,
                isEnabled: isEnabled
            )
            viewModel.addApp(newApp)
        }
        
        dismiss()
    }
}
