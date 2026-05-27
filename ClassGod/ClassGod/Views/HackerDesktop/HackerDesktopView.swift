//
//  HackerDesktopView.swift
//  ClassGod
//

import SwiftUI

struct HackerDesktopView: View {
    @State private var widgets: [HackerWidgetItem] = []
    @State private var showPicker = false
    @State private var showGrid = false
    var onClose: () -> Void
    
    private let gridSpacing: CGFloat = 40
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                hackerBackground(size: geo.size)
                
                // Widgets
                ForEach($widgets) { $widget in
                    WidgetContainerView(
                        widget: $widget,
                        onDelete: { deleteWidget(widget) },
                        onBringToFront: { bringToFront(widget) },
                        onChange: { saveWidgets() },
                        canvasSize: geo.size,
                        showGrid: showGrid,
                        gridSize: gridSpacing
                    )
                }
                
                // Empty state
                if widgets.isEmpty {
                    emptyStateView
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        ))
                }
                
                // Toolbar
                VStack {
                    Spacer()
                    toolbar(canvasSize: geo.size)
                        .padding(.bottom, 16)
                }
                
                // Widget picker sheet
                if showPicker {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            SoundEffectManager.shared.playButtonClick()
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showPicker = false
                            }
                        }
                    
                    WidgetPickerView(
                        onAdd: { type in
                            addWidget(type: type, canvasSize: geo.size)
                        },
                        onClose: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showPicker = false
                            }
                        }
                    )
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                }
            }
            .onAppear {
                SystemMonitor.shared.start(interval: 1.0)
                loadWidgets(canvasSize: geo.size)
            }
            .onDisappear {
                SystemMonitor.shared.stop()
                saveWidgets()
            }

        }
    }
    
    // MARK: - Background
    
    private func hackerBackground(size: CGSize) -> some View {
        ZStack {
            Color.black
            
            // Subtle scanline effect
            scanlines(size: size)
            
            // Grid lines
            gridLines(size: size)
                .opacity(showGrid ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: showGrid)
            
            // Corner accents
            VStack {
                HStack {
                    cornerAccent
                    Spacer()
                    cornerAccent.rotationEffect(.degrees(90))
                }
                Spacer()
                HStack {
                    cornerAccent.rotationEffect(.degrees(-90))
                    Spacer()
                    cornerAccent.rotationEffect(.degrees(180))
                }
            }
            .padding(12)
        }
    }
    
    private func scanlines(size: CGSize) -> some View {
        Canvas { context, size in
            let lineHeight: CGFloat = 2
            let gapHeight: CGFloat = 3
            let lineColor = Color.white.opacity(0.006)
            
            for y in stride(from: 0, to: size.height, by: lineHeight + gapHeight) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: lineHeight)
            }
        }
    }
    
    private func gridLines(size: CGSize) -> some View {
        Canvas { context, size in
            let lineColor = Color.white.opacity(0.035)
            
            for x in stride(from: 0, to: size.width, by: gridSpacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
            }
            
            for y in stride(from: 0, to: size.height, by: gridSpacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
            }
        }
    }
    
    private var cornerAccent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Rectangle()
                .fill(Color.cyan.opacity(0.4))
                .frame(width: 24, height: 1.5)
            Rectangle()
                .fill(Color.cyan.opacity(0.4))
                .frame(width: 1.5, height: 24)
        }
    }
    
    // MARK: - Toolbar
    
    private func toolbar(canvasSize: CGSize) -> some View {
        HStack(spacing: 12) {
            ToolbarButton(
                icon: "plus",
                label: "Add Widget",
                isPrimary: true,
                action: {
                    SoundEffectManager.shared.playWidgetPickerOpen()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showPicker = true
                    }
                }
            )
            
            ToolbarButton(
                icon: showGrid ? "grid" : "grid.circle",
                label: showGrid ? "Hide Grid" : "Show Grid",
                isActive: showGrid,
                action: {
                    SoundEffectManager.shared.playGridToggle()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showGrid.toggle()
                    }
                }
            )
            
            ToolbarButton(
                icon: "arrow.counterclockwise",
                label: "Reset Layout",
                isDisabled: widgets.isEmpty,
                action: {
                    SoundEffectManager.shared.playLayoutReset()
                    HapticManager.shared.success()
                    resetLayout(canvasSize: canvasSize)
                }
            )
            
            ToolbarButton(
                icon: "trash",
                label: "Clear All",
                isDestructive: true,
                isDisabled: widgets.isEmpty,
                action: {
                    SoundEffectManager.shared.playLayoutCleared()
                    HapticManager.shared.warning()
                    clearAllWidgets()
                }
            )
            
            Spacer()
            
            Text("\(widgets.count) widget\(widgets.count == 1 ? "" : "s")")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
            
            ToolbarButton(
                icon: "xmark",
                label: "Close",
                action: {
                    SoundEffectManager.shared.playButtonClick()
                    onClose()
                }
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
                .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.cyan.opacity(0.12), lineWidth: 1)
                    .frame(width: 88, height: 88)
                
                Circle()
                    .stroke(Color.cyan.opacity(0.06), lineWidth: 0.5)
                    .frame(width: 72, height: 72)
                
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.cyan.opacity(0.35))
            }
            
            VStack(spacing: 8) {
                Text("HACKER DESKTOP")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .tracking(4)
                
                Text("Add widgets to build your system dashboard")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                SoundEffectManager.shared.playWidgetPickerOpen()
                withAnimation(.easeInOut(duration: 0.2)) {
                    showPicker = true
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Add First Widget")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(Color.cyan.opacity(0.12))
                .foregroundStyle(.cyan)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.cyan.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(36)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.cyan.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Widget Management
    
    private func addWidget(type: WidgetType, canvasSize: CGSize) {
        let x = min(40 + Double(widgets.count % 5) * 30, canvasSize.width - type.defaultSize.width - 20)
        let y = min(40 + Double(widgets.count / 5) * 30, canvasSize.height - type.defaultSize.height - 80)
        let widget = HackerWidgetItem(type: type, x: x, y: y)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            widgets.append(widget)
        }
        SoundEffectManager.shared.playWidgetAdded()
        HapticManager.shared.success()
        saveWidgets()
    }
    
    private func deleteWidget(_ widget: HackerWidgetItem) {
        withAnimation(.easeInOut(duration: 0.18)) {
            widgets.removeAll { $0.id == widget.id }
        }
        saveWidgets()
    }
    
    private func clearAllWidgets() {
        withAnimation(.easeInOut(duration: 0.25)) {
            widgets.removeAll()
        }
        saveWidgets()
    }
    
    private func bringToFront(_ widget: HackerWidgetItem) {
        guard let idx = widgets.firstIndex(where: { $0.id == widget.id }) else { return }
        let item = widgets.remove(at: idx)
        widgets.append(item)
    }
    
    private func resetLayout(canvasSize: CGSize) {
        withAnimation(.easeInOut(duration: 0.3)) {
            for i in widgets.indices {
                let type = widgets[i].type
                let x = min(20 + Double(i % 4) * 30, canvasSize.width - type.defaultSize.width - 20)
                let y = min(20 + Double(i / 4) * 30, canvasSize.height - type.defaultSize.height - 80)
                widgets[i].x = x
                widgets[i].y = y
                widgets[i].width = type.defaultSize.width
                widgets[i].height = type.defaultSize.height
            }
        }
        saveWidgets()
    }
    
    private func saveWidgets() {
        do {
            let data = try JSONEncoder().encode(widgets)
            UserDefaults.standard.set(data, forKey: "com.hanazar.classgod.hackerdesktop.widgets")
        } catch {
            print("[HackerDesktop] Failed to save widgets: \(error)")
        }
    }
    
    private func loadWidgets(canvasSize: CGSize) {
        guard let data = UserDefaults.standard.data(forKey: "com.hanazar.classgod.hackerdesktop.widgets") else { return }
        do {
            var loaded = try JSONDecoder().decode([HackerWidgetItem].self, from: data)
            for i in loaded.indices {
                let type = loaded[i].type
                loaded[i].x = max(0, min(loaded[i].x, canvasSize.width - type.minSize.width))
                loaded[i].y = max(0, min(loaded[i].y, canvasSize.height - type.minSize.height - 60))
                loaded[i].width = max(type.minSize.width, min(loaded[i].width, canvasSize.width - loaded[i].x))
                loaded[i].height = max(type.minSize.height, min(loaded[i].height, canvasSize.height - loaded[i].y - 60))
            }
            widgets = loaded
        } catch {
            print("[HackerDesktop] Failed to load widgets: \(error)")
        }
    }
}

// MARK: - Toolbar Button

private struct ToolbarButton: View {
    let icon: String
    var label: String? = nil
    var isPrimary: Bool = false
    var isActive: Bool = false
    var isDestructive: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: isPrimary ? 11 : 12, weight: isPrimary ? .bold : .medium))
                if let label = label, isPrimary {
                    Text(label)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, isPrimary ? 12 : 8)
        .padding(.vertical, isPrimary ? 6 : 5)
        .background(backgroundColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(strokeColor, lineWidth: isPrimary ? 1 : (isHovered ? 1 : 0.5))
        )
        .opacity(isDisabled ? 0.35 : 1)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: isActive)
        .disabled(isDisabled)
    }
    
    private var foregroundColor: Color {
        if isPrimary { return .cyan }
        if isDestructive { return .red.opacity(0.8) }
        if isActive { return .cyan }
        return .white.opacity(0.6)
    }
    
    private var backgroundColor: Color {
        if isPrimary { return Color.cyan.opacity(0.1) }
        if isHovered { return Color.white.opacity(0.06) }
        return Color.clear
    }
    
    private var strokeColor: Color {
        if isPrimary { return Color.cyan.opacity(0.3) }
        if isActive { return Color.cyan.opacity(0.4) }
        if isDestructive && isHovered { return Color.red.opacity(0.3) }
        return Color.white.opacity(0.1)
    }
}

#Preview {
    HackerDesktopView(onClose: {})
        .frame(width: 800, height: 600)
        .background(Color.black)
}
