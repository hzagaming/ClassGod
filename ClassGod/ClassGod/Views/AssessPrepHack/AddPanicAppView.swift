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
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 24, height: 24)
                        .background(Color(white: 0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(isEditing ? "Edit Panic App" : "Add Panic App")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button(action: save) {
                    Text(isEditing ? "Save" : "Add")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(isValid ? .white : .white.opacity(0.3))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
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
                VStack(spacing: 16) {
                    // Name
                    formField(title: "Name") {
                        TextField("", text: $name)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(8)
                            .background(Color(white: 0.06))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // Bundle ID
                    formField(title: "Bundle Identifier") {
                        TextField("", text: $bundleIdentifier)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(8)
                            .background(Color(white: 0.06))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // Technique picker
                    formField(title: "Bypass Technique") {
                        VStack(spacing: 4) {
                            ForEach(AssessPrepBypassTechnique.allCases) { technique in
                                Button(action: {
                                    selectedTechnique = technique
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: technique.iconName)
                                            .font(.system(size: 14))
                                            .foregroundStyle(selectedTechnique == technique ? .red : .white.opacity(0.4))
                                            .frame(width: 20)
                                        
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(technique.displayName)
                                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                                .foregroundStyle(selectedTechnique == technique ? .white : .white.opacity(0.5))
                                            Text(technique.description)
                                                .font(.system(size: 9, design: .monospaced))
                                                .foregroundStyle(.white.opacity(0.3))
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedTechnique == technique {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.red)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(selectedTechnique == technique ? Color.red.opacity(0.08) : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(selectedTechnique == technique ? Color.red.opacity(0.2) : Color.white.opacity(0.06), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Icon picker
                    formField(title: "Icon") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 36))], spacing: 8) {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                }) {
                                    Image(systemName: icon)
                                        .font(.system(size: 16))
                                        .foregroundStyle(selectedIcon == icon ? .red : .white.opacity(0.4))
                                        .frame(width: 36, height: 36)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(selectedIcon == icon ? Color.red.opacity(0.1) : Color(white: 0.06))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(selectedIcon == icon ? Color.red.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Enabled toggle
                    HStack {
                        Text("Enabled")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Toggle("", isOn: $isEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                    }
                }
                .padding()
            }
        }
        .frame(width: 340, height: 500)
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
    
    private func formField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
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
