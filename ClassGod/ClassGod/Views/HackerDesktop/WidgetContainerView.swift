//
//  WidgetContainerView.swift
//  ClassGod
//

import SwiftUI

struct WidgetContainerView: View {
    @Binding var widget: HackerWidgetItem
    let onDelete: () -> Void
    let onBringToFront: () -> Void
    let onChange: () -> Void
    let canvasSize: CGSize
    let showGrid: Bool
    let gridSize: CGFloat
    
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var dragStart: CGPoint?
    @State private var resizeStart: CGSize?
    @State private var showControls = false
    @State private var isHovering = false
    @State private var appeared = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Main widget card
            VStack(spacing: 0) {
                // Title bar
                HStack(spacing: 6) {
                    Image(systemName: widget.type.iconName)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.4))
                    
                    Text(widget.title)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Spacer()
                    
                    if widget.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(white: 0.03))
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 0.5)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                )
                
                // Content
                widgetContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                borderColor,
                                lineWidth: isDragging || isResizing ? 1.5 : 1
                            )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? Color.white.opacity(0.015) : Color.clear)
            )
            
            // Hover controls overlay
            if showControls && !widget.isLocked {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            // Lock button
                            Button(action: {
                                SoundEffectManager.shared.playWidgetLocked()
                                HapticManager.shared.generic()
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    widget.isLocked.toggle()
                                }
                                onChange()
                            }) {
                                Image(systemName: widget.isLocked ? "lock.fill" : "lock.open")
                                    .font(.system(size: 8))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(5)
                            .background(Color(white: 0.06))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                            
                            // Delete button
                            Button(action: {
                                SoundEffectManager.shared.playWidgetDeleted()
                                HapticManager.shared.warning()
                                onDelete()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.red.opacity(0.9))
                            .padding(5)
                            .background(Color(white: 0.06))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.red.opacity(0.2), lineWidth: 0.5))
                        }
                        .padding(.top, 3)
                        .padding(.trailing, 4)
                    }
                    Spacer()
                }
                .allowsHitTesting(true)
                
                // Resize handle
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(isResizing ? 0.7 : 0.3))
                            .padding(6)
                            .contentShape(Rectangle().size(width: 24, height: 24))
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if !isResizing {
                                            isResizing = true
                                            SoundEffectManager.shared.playResizeStart()
                                            HapticManager.shared.generic()
                                        }
                                        if resizeStart == nil {
                                            resizeStart = CGSize(width: widget.width, height: widget.height)
                                        }
                                        let newW = max(widget.type.minSize.width, resizeStart!.width + value.translation.width)
                                        let newH = max(widget.type.minSize.height, resizeStart!.height + value.translation.height)
                                        widget.width = min(newW, canvasSize.width - widget.x)
                                        widget.height = min(newH, canvasSize.height - widget.y)
                                    }
                                    .onEnded { _ in
                                        isResizing = false
                                        resizeStart = nil
                                        snapToGridIfNeeded()
                                        onChange()
                                    }
                            )
                    }
                }
                .allowsHitTesting(true)
            }
        }
        .frame(width: widget.width, height: widget.height)
        .position(x: widget.x + widget.width / 2, y: widget.y + widget.height / 2)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? (isDragging || isResizing ? 1.02 : 1.0) : 0.85)
        .onHover { hovering in
            isHovering = hovering
            showControls = hovering
        }
        .gesture(
            DragGesture(minimumDistance: widget.isLocked ? 0 : 1)
                .onChanged { value in
                    if widget.isLocked {
                        onBringToFront()
                        return
                    }
                    if !isDragging {
                        isDragging = true
                        SoundEffectManager.shared.playDragStart()
                        HapticManager.shared.generic()
                        onBringToFront()
                    }
                    if dragStart == nil {
                        dragStart = CGPoint(x: widget.x, y: widget.y)
                    }
                    let newX = max(0, min(dragStart!.x + value.translation.width, canvasSize.width - widget.width))
                    let newY = max(0, min(dragStart!.y + value.translation.height, canvasSize.height - widget.height))
                    widget.x = newX
                    widget.y = newY
                }
                .onEnded { _ in
                    if widget.isLocked { return }
                    isDragging = false
                    dragStart = nil
                    snapToGridIfNeeded()
                    onChange()
                }
        )
        .shadow(
            color: shadowColor,
            radius: isDragging || isResizing ? 16 : (isHovering ? 8 : 0),
            x: 0, y: isDragging || isResizing ? 6 : (isHovering ? 3 : 0)
        )
        .animation(.easeOut(duration: 0.15), value: isDragging || isResizing)
        .animation(.easeOut(duration: 0.2), value: appeared)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .contextMenu {
            Button {
                SoundEffectManager.shared.playWidgetLocked()
                withAnimation(.easeInOut(duration: 0.15)) {
                    widget.isLocked.toggle()
                }
                onChange()
            } label: {
                Label(widget.isLocked ? "Unlock" : "Lock", systemImage: widget.isLocked ? "lock.open" : "lock")
            }
            
            Button {
                SoundEffectManager.shared.playWidgetDeleted()
                HapticManager.shared.warning()
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            if widget.type == .finderFile {
                Button {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = true
                    if panel.runModal() == .OK, let url = panel.url {
                        widget.filePath = url.path
                        onChange()
                    }
                } label: {
                    Label("Choose File...", systemImage: "doc.badge.plus")
                }
                
                Divider()
            }
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    widget.width = widget.type.defaultSize.width
                    widget.height = widget.type.defaultSize.height
                }
                onChange()
            } label: {
                Label("Reset Size", systemImage: "arrow.counterclockwise")
            }
            
            Button {
                onBringToFront()
                onChange()
            } label: {
                Label("Bring to Front", systemImage: "arrow.up")
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
    
    private var borderColor: Color {
        if isDragging || isResizing {
            return Color.cyan.opacity(0.4)
        }
        if isHovering {
            return Color.white.opacity(0.15)
        }
        return Color.white.opacity(0.08)
    }
    
    private var shadowColor: Color {
        if isDragging || isResizing {
            return Color.cyan.opacity(0.25)
        }
        if isHovering {
            return Color.black.opacity(0.4)
        }
        return Color.clear
    }
    
    private func snapToGridIfNeeded() {
        guard showGrid else { return }
        let threshold: CGFloat = 10
        let snapX = round(widget.x / gridSize) * gridSize
        let snapY = round(widget.y / gridSize) * gridSize
        if abs(widget.x - snapX) < threshold {
            widget.x = max(0, snapX)
        }
        if abs(widget.y - snapY) < threshold {
            widget.y = max(0, snapY)
        }
    }
    
    @ViewBuilder
    private var widgetContent: some View {
        switch widget.type {
        case .cpuGauge:
            CPUWidget()
        case .memoryBar:
            MemoryWidget()
        case .diskGrid:
            DiskWidget()
        case .networkSpeed:
            NetworkWidget()
        case .processList:
            ProcessWidget()
        case .uptime:
            UptimeWidget()
        case .clock:
            ClockWidget()
        case .battery:
            BatteryWidget()
        case .tempSensors:
            TempWidget()
        case .systemInfo:
            SystemInfoWidget()
        case .finderFile:
            FinderFileWidget(filePath: widget.filePath) { url in
                widget.filePath = url.path
            }
        }
    }
}
