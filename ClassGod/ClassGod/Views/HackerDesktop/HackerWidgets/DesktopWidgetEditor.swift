//
//  DesktopWidgetEditor.swift
//  ClassGod
//
//  UI for managing desktop overlay widgets inside HackerDesktopView.
//

import SwiftUI
import UniformTypeIdentifiers

struct DesktopWidgetEditor: View {
    @ObservedObject private var manager = DesktopWidgetManager.shared
    @ObservedObject private var prefs = PreferencesManager.shared
    @State private var showingFilePicker = false
    @State private var selectedFileType: WidgetType?

    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        VStack(spacing: 14 * zoomScale) {
            // Toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable Desktop Widgets")
                        .font(.system(size: 12 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("Show overlay widgets on Finder desktop")
                        .font(.system(size: 10 * zoomScale, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { manager.isEnabled },
                    set: { manager.setEnabled($0) }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .cyan))
            }
            .padding(12 * zoomScale)
            .background(Color(white: 0.03))
            .clipShape(RoundedRectangle(cornerRadius: 10 * zoomScale))
            .overlay(
                RoundedRectangle(cornerRadius: 10 * zoomScale)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
            )

            if manager.isEnabled {
                // Edit mode toggle
                HStack {
                    Button(action: {
                        SoundEffectManager.shared.playButtonClick()
                        manager.toggleEditMode()
                    }) {
                        HStack(spacing: 4 * zoomScale) {
                            Image(systemName: manager.isEditMode ? "checkmark" : "pencil")
                                .font(.system(size: 10 * zoomScale))
                            Text(manager.isEditMode ? "Done" : "Edit Layout")
                                .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12 * zoomScale)
                        .padding(.vertical, 6 * zoomScale)
                        .background(manager.isEditMode ? Color.green.opacity(0.2) : Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6 * zoomScale)
                                .stroke(manager.isEditMode ? Color.green.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: {
                        SoundEffectManager.shared.playButtonClick()
                        manager.resetToDefaults()
                    }) {
                        HStack(spacing: 4 * zoomScale) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10 * zoomScale))
                            Text("Reset")
                                .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 12 * zoomScale)
                        .padding(.vertical, 6 * zoomScale)
                        .background(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6 * zoomScale)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Active items grid
                VStack(alignment: .leading, spacing: 12 * zoomScale) {
                    let regularWidgets = manager.widgets.filter { !$0.type.isDesktopTab }
                    let desktopTabs = manager.widgets.filter { $0.type.isDesktopTab }
                    
                    if !regularWidgets.isEmpty {
                        VStack(alignment: .leading, spacing: 8 * zoomScale) {
                            Text("Active Widgets (\(regularWidgets.count))")
                                .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.6))
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120 * zoomScale))], spacing: 8 * zoomScale) {
                                ForEach(regularWidgets) { widget in
                                    WidgetListCard(widget: widget) {
                                        manager.removeWidget(id: widget.id)
                                    }
                                }
                            }
                        }
                    }
                    
                    if !desktopTabs.isEmpty {
                        VStack(alignment: .leading, spacing: 8 * zoomScale) {
                            Text("Desktop Tabs (\(desktopTabs.count))")
                                .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.6))
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120 * zoomScale))], spacing: 8 * zoomScale) {
                                ForEach(desktopTabs) { widget in
                                    WidgetListCard(widget: widget) {
                                        manager.removeWidget(id: widget.id)
                                    }
                                }
                            }
                        }
                    }
                    
                    if manager.widgets.isEmpty {
                        Text("No widgets or tabs. Add one below.")
                            .font(.system(size: 10 * zoomScale, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.3))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    }
                }
                .padding(12 * zoomScale)
                .background(Color(white: 0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10 * zoomScale))
                .overlay(
                    RoundedRectangle(cornerRadius: 10 * zoomScale)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
                )

                // Add widget section
                VStack(alignment: .leading, spacing: 10 * zoomScale) {
                    Text("Add Widget")
                        .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90 * zoomScale))], spacing: 8 * zoomScale) {
                        ForEach(WidgetType.allCases.filter { !$0.isDesktopTab }) { type in
                            AddWidgetButton(type: type) {
                                if type == .finderFile {
                                    selectedFileType = type
                                    showingFilePicker = true
                                } else {
                                    manager.addWidget(type)
                                }
                            }
                        }
                    }
                }
                .padding(12 * zoomScale)
                .background(Color(white: 0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10 * zoomScale))
                .overlay(
                    RoundedRectangle(cornerRadius: 10 * zoomScale)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
                )
                
                // Add desktop tab section
                VStack(alignment: .leading, spacing: 10 * zoomScale) {
                    Text("Add Desktop Tab")
                        .font(.system(size: 11 * zoomScale, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90 * zoomScale))], spacing: 8 * zoomScale) {
                        ForEach(WidgetType.allCases.filter(\.isDesktopTab)) { type in
                            AddWidgetButton(type: type) {
                                manager.addWidget(type)
                            }
                        }
                    }
                }
                .padding(12 * zoomScale)
                .background(Color(white: 0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10 * zoomScale))
                .overlay(
                    RoundedRectangle(cornerRadius: 10 * zoomScale)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1 * zoomScale)
                )
            }

            Spacer()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            guard let type = selectedFileType else { return }
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    let path = url.path
                    var widget = HackerWidgetItem(type: type)
                    widget.filePath = path
                    manager.widgets.append(widget)
                    manager.saveState()
                    if manager.isEnabled {
                        manager.showAllWidgets()
                    }
                }
            case .failure:
                break
            }
        }
    }
}

// MARK: - Subviews

private struct WidgetListCard: View {
    let widget: HackerWidgetItem
    let onDelete: () -> Void

    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        HStack(spacing: 6 * zoomScale) {
            Image(systemName: widget.type.iconName)
                .font(.system(size: 12 * zoomScale))
                .foregroundStyle(.cyan)
                .frame(width: 24 * zoomScale, height: 24 * zoomScale)
                .background(Color.cyan.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4 * zoomScale))

            VStack(alignment: .leading, spacing: 1) {
                Text(widget.type.displayName)
                    .font(.system(size: 10 * zoomScale, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                Text("\(Int(widget.width))×\(Int(widget.height))")
                    .font(.system(size: 8 * zoomScale, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            if widget.type.isDesktopTab {
                Image(systemName: widget.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 10 * zoomScale))
                    .foregroundStyle(widget.isLocked ? .orange : .white.opacity(0.3))
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 10 * zoomScale))
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(8 * zoomScale)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 6 * zoomScale))
        .overlay(
            RoundedRectangle(cornerRadius: 6 * zoomScale)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct AddWidgetButton: View {
    let type: WidgetType
    let action: () -> Void

    @ObservedObject private var prefs = PreferencesManager.shared
    private var zoomScale: CGFloat { CGFloat(prefs.preferences.windowZoomScale) }

    var body: some View {
        Button(action: {
            SoundEffectManager.shared.playButtonClick()
            action()
        }) {
            VStack(spacing: 4 * zoomScale) {
                Image(systemName: type.iconName)
                    .font(.system(size: 16 * zoomScale))
                    .foregroundStyle(.cyan.opacity(0.8))
                Text(type.displayName)
                    .font(.system(size: 9 * zoomScale, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10 * zoomScale)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8 * zoomScale))
            .overlay(
                RoundedRectangle(cornerRadius: 8 * zoomScale)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
