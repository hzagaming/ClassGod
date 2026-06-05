//
//  DesktopWidgetManager.swift
//  ClassGod
//
//  Manages borderless overlay widgets on the Finder desktop.
//  Widgets float above desktop icons and persist their layout.
//

import SwiftUI
import AppKit
import Combine

/// Manages a collection of desktop widget overlay windows.
/// Widgets appear above Finder icons on all spaces and support drag-to-move.
@MainActor
final class DesktopWidgetManager: ObservableObject {
    static let shared = DesktopWidgetManager()

    @Published var widgets: [HackerWidgetItem] = []
    @Published var isEditMode: Bool = false
    @Published var isEnabled: Bool = false

    private var windows: [UUID: DesktopWidgetWindow] = [:]
    private var screenObserver: NSObjectProtocol?
    private let storageKey = "com.hanazar.classgod.desktopWidgets"
    private let enabledKey = "com.hanazar.classgod.desktopWidgetsEnabled"

    private init() {
        loadState()
        bindToScreenChanges()
    }

    deinit {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - State Management

    private func loadState() {
        isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([HackerWidgetItem].self, from: data) {
            widgets = saved
        } else {
            // Default widgets on first launch
            widgets = defaultWidgets()
        }
    }

    func saveState() {
        if let data = try? JSONEncoder().encode(widgets) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        UserDefaults.standard.set(isEnabled, forKey: enabledKey)
    }

    private func defaultWidgets() -> [HackerWidgetItem] {
        guard let screen = NSScreen.main else { return [] }
        let frame = screen.visibleFrame
        let margin: CGFloat = 24
        return [
            HackerWidgetItem(type: .clock, x: frame.maxX - 220 - margin, y: frame.maxY - 100 - margin),
            HackerWidgetItem(type: .cpuGauge, x: frame.maxX - 180 - margin, y: frame.maxY - 280 - margin),
            HackerWidgetItem(type: .battery, x: frame.maxX - 180 - margin, y: frame.maxY - 400 - margin)
        ]
    }

    // MARK: - Enable / Disable

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        saveState()
        if enabled {
            SystemMonitor.shared.start(interval: 2.0)
            showAllWidgets()
        } else {
            hideAllWidgets()
            // Only stop SystemMonitor if no other consumers need it
        }
    }

    func toggleEditMode() {
        isEditMode.toggle()
        for (_, window) in windows {
            window.setEditMode(isEditMode)
        }
    }

    // MARK: - Widget CRUD

    func addWidget(_ type: WidgetType, at point: NSPoint? = nil) {
        let location: NSPoint
        if let point = point {
            location = point
        } else if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            location = NSPoint(x: frame.midX - type.defaultSize.width / 2,
                               y: frame.midY - type.defaultSize.height / 2)
        } else {
            location = NSPoint(x: 100, y: 100)
        }

        let widget = HackerWidgetItem(type: type, x: Double(location.x), y: Double(location.y))
        widgets.append(widget)
        saveState()

        if isEnabled {
            createWindow(for: widget)
        }
    }

    func removeWidget(id: UUID) {
        widgets.removeAll { $0.id == id }
        saveState()
        destroyWindow(id: id)
    }

    func updateWidget(_ widget: HackerWidgetItem) {
        if let index = widgets.firstIndex(where: { $0.id == widget.id }) {
            widgets[index] = widget
            saveState()
        }
    }

    func updateWidgetFrame(id: UUID, frame: NSRect) {
        if let index = widgets.firstIndex(where: { $0.id == id }) {
            widgets[index].x = Double(frame.origin.x)
            widgets[index].y = Double(frame.origin.y)
            widgets[index].width = Double(frame.size.width)
            widgets[index].height = Double(frame.size.height)
            saveState()
        }
    }

    func resetToDefaults() {
        hideAllWidgets()
        widgets = defaultWidgets()
        saveState()
        if isEnabled {
            showAllWidgets()
        }
    }

    // MARK: - Window Management

    func showAllWidgets() {
        // Remove stale windows
        let activeIDs = Set(widgets.map(\.id))
        for (id, _) in windows where !activeIDs.contains(id) {
            destroyWindow(id: id)
        }
        // Create/update windows
        for widget in widgets {
            if let existing = windows[widget.id] {
                existing.updateWidget(widget)
                existing.setEditMode(isEditMode)
            } else {
                createWindow(for: widget)
            }
        }
    }

    func hideAllWidgets() {
        for (_, window) in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
    }

    private func createWindow(for widget: HackerWidgetItem) {
        let window = DesktopWidgetWindow(widget: widget, manager: self)
        windows[widget.id] = window
        window.setEditMode(isEditMode)
        window.orderFront(nil)
    }

    private func destroyWindow(id: UUID) {
        windows[id]?.orderOut(nil)
        windows.removeValue(forKey: id)
    }

    // MARK: - Screen Changes

    private func bindToScreenChanges() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.screenParametersDidChange()
            }
        }
    }

    private func screenParametersDidChange() {
        guard isEnabled else { return }
        // Reposition off-screen widgets back onto visible area
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.clampWidgetsToScreens()
        }
    }

    private func clampWidgetsToScreens() {
        let unionFrame = NSScreen.screens.map(\.frame).reduce(CGRect.null) { $0.union($1) }
        var changed = false
        for i in widgets.indices {
            let w = widgets[i]
            let rect = CGRect(x: w.x, y: w.y, width: w.width, height: w.height)
            if !unionFrame.intersects(rect) {
                // Move to primary screen center
                if let screen = NSScreen.main {
                    let sf = screen.visibleFrame
                    widgets[i].x = Double(sf.midX - w.width / 2)
                    widgets[i].y = Double(sf.midY - w.height / 2)
                    changed = true
                }
            }
        }
        if changed {
            saveState()
            for widget in widgets {
                windows[widget.id]?.updateWidget(widget)
            }
        }
    }
}

// MARK: - Desktop Widget Window

/// A borderless window that lives on the desktop, above Finder icons.
final class DesktopWidgetWindow: NSWindow {
    private let widgetID: UUID
    private weak var manager: DesktopWidgetManager?
    private var trackingArea: NSTrackingArea?
    private var isDragging = false
    private var dragStartLocation: NSPoint?
    private var dragStartFrame: NSRect?
    private var editMode = false

    init(widget: HackerWidgetItem, manager: DesktopWidgetManager) {
        self.widgetID = widget.id
        self.manager = manager

        let rect = NSRect(x: widget.x, y: widget.y, width: widget.width, height: widget.height)
        super.init(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)

        // Desktop level: just above Finder icons, below normal windows
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 20)
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.isReleasedWhenClosed = false
        self.ignoresMouseEvents = false
        self.animationBehavior = .none
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]

        setupContent(widget: widget)
    }

    func updateWidget(_ widget: HackerWidgetItem) {
        setFrame(NSRect(x: widget.x, y: widget.y, width: widget.width, height: widget.height), display: true)
        refreshContent()
    }

    func setEditMode(_ enabled: Bool) {
        editMode = enabled
        refreshContent()
    }

    func refreshContent() {
        guard let widget = manager?.widgets.first(where: { $0.id == widgetID }) else { return }
        setupContent(widget: widget)
    }

    // MARK: - Content

    private func setupContent(widget: HackerWidgetItem) {
        let rootView = DesktopWidgetContainer(
            widget: widget,
            isEditMode: editMode,
            onDelete: { [weak self] in
                guard let self else { return }
                self.manager?.removeWidget(id: self.widgetID)
            }
        )
        .frame(width: widget.width, height: widget.height)

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        contentView = hostingView
    }

    // MARK: - Mouse Dragging (entire window is draggable in edit mode)

    override func mouseDown(with event: NSEvent) {
        guard editMode else {
            super.mouseDown(with: event)
            return
        }
        isDragging = true
        dragStartLocation = NSEvent.mouseLocation
        dragStartFrame = self.frame
    }

    override func mouseDragged(with event: NSEvent) {
        guard editMode, isDragging,
              let startLoc = dragStartLocation,
              let startFrame = dragStartFrame else {
            super.mouseDragged(with: event)
            return
        }
        let currentLoc = NSEvent.mouseLocation
        let deltaX = currentLoc.x - startLoc.x
        let deltaY = currentLoc.y - startLoc.y
        let newOrigin = NSPoint(x: startFrame.origin.x + deltaX, y: startFrame.origin.y + deltaY)
        setFrameOrigin(newOrigin)
    }

    override func mouseUp(with event: NSEvent) {
        if isDragging {
            // Save new position
            let newFrame = self.frame
            manager?.updateWidgetFrame(id: widgetID, frame: newFrame)
        }
        isDragging = false
        dragStartLocation = nil
        dragStartFrame = nil
        super.mouseUp(with: event)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
