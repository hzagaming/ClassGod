//
//  ErrorToastManager.swift
//  ClassGod
//
//  Global Error Toast / Popup Notification System
//  Created by ClassGod on 2026/05/31.
//

import SwiftUI
import AppKit
import Combine

enum ErrorToastLayoutPolicy {
    static func origin(
        index: Int,
        visibleFrame: NSRect,
        size: NSSize,
        padding: CGFloat = 20,
        spacing: CGFloat = 10
    ) -> NSPoint {
        NSPoint(
            x: visibleFrame.maxX - size.width - padding,
            y: visibleFrame.maxY - size.height - padding - CGFloat(index) * (size.height + spacing)
        )
    }
}

// MARK: - Toast Item
struct ErrorToastItem: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let severity: ErrorSeverity
    let entry: ErrorEntry?
    let timestamp: Date

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        severity: ErrorSeverity,
        entry: ErrorEntry?,
        timestamp: Date
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.severity = severity
        self.entry = entry
        self.timestamp = timestamp
    }

    func enriched(with entry: ErrorEntry?) -> ErrorToastItem {
        ErrorToastItem(
            id: id,
            title: title,
            message: message,
            severity: severity,
            entry: entry,
            timestamp: timestamp
        )
    }
}

// MARK: - Error Toast Manager
final class ErrorToastManager: ObservableObject {
    static let shared = ErrorToastManager()
    
    @Published private(set) var toasts: [ErrorToastItem] = []
    private var windows: [UUID: NSWindow] = [:]
    
    private init() {}
    
    // MARK: - Show Toast
    @discardableResult
    func show(title: String, message: String, severity: ErrorSeverity = .high, entry: ErrorEntry? = nil) -> UUID {
        let toast = ErrorToastItem(title: title, message: message, severity: severity, entry: entry, timestamp: Date())
        toasts.append(toast)
        presentToastWindow(toast)
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
            self?.dismiss(id: toast.id)
        }
        return toast.id
    }
    
    // MARK: - Show from Error Entry
    func show(entry: ErrorEntry) {
        show(title: entry.title, message: entry.description, severity: entry.severity, entry: entry)
    }
    
    // MARK: - Show from NSError
    func show(error: Error) {
        let nsError = error as NSError
        let title = nsError.localizedDescription
        let message = "Domain: \(nsError.domain) | Code: \(nsError.code)"
        
        // Present toast immediately, then enrich with knowledge-base match on background
        let toastID = show(title: title, message: message, severity: .high, entry: nil)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            ErrorKnowledgeBase.shared.ensureLoaded()
            let matching = ErrorKnowledgeBase.shared.search(query: "\(nsError.domain) \(nsError.code)")
            guard let entry = matching.first?.entry else { return }
            DispatchQueue.main.async {
                self?.enrichToast(id: toastID, with: entry)
            }
        }
    }
    
    private func enrichToast(id: UUID, with entry: ErrorEntry) {
        guard let index = toasts.firstIndex(where: { $0.id == id && $0.entry == nil }) else { return }
        let enriched = toasts[index].enriched(with: entry)
        toasts[index] = enriched
        if let window = windows[id] {
            window.contentView = NSHostingView(
                rootView: toastView(for: enriched)
                    .frame(width: window.frame.width, height: window.frame.height)
            )
        }
    }
    
    // MARK: - Dismiss
    func dismiss(id: UUID) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.toasts.removeAll { $0.id == id }
            if let window = self.windows[id] {
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = Anim.duration
                    window.animator().alphaValue = 0
                } completionHandler: {
                    window.orderOut(nil)
                }
                self.windows.removeValue(forKey: id)
                self.relayoutWindows(animated: true)
            }
        }
    }
    
    // MARK: - Dismiss All
    func dismissAll() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for (_, window) in self.windows {
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = Anim.duration
                    window.animator().alphaValue = 0
                } completionHandler: {
                    window.orderOut(nil)
                }
            }
            self.windows.removeAll()
            self.toasts.removeAll()
        }
    }
    
    // MARK: - Present Toast Window
    private func presentToastWindow(_ toast: ErrorToastItem) {
        let width: CGFloat = 380
        let height: CGFloat = 120
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .popUpMenu
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.isReleasedWhenClosed = false
        
        let view = toastView(for: toast)
            .frame(width: width, height: height)

        window.contentView = NSHostingView(rootView: view)

        if let screen = NSScreen.main {
            let index = toasts.firstIndex(where: { $0.id == toast.id }) ?? windows.count
            window.setFrameOrigin(ErrorToastLayoutPolicy.origin(
                index: index,
                visibleFrame: screen.visibleFrame,
                size: NSSize(width: width, height: height)
            ))
        }

        window.alphaValue = 0
        window.orderFront(nil)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = Anim.duration
            ctx.timingFunction = .init(name: .easeOut)
            window.animator().alphaValue = 1
        }

        windows[toast.id] = window
    }

    private func relayoutWindows(animated: Bool) {
        guard let visibleFrame = NSScreen.main?.visibleFrame else { return }
        let updates = toasts.enumerated().compactMap { index, toast -> (NSWindow, NSPoint)? in
            guard let window = windows[toast.id] else { return nil }
            return (window, ErrorToastLayoutPolicy.origin(
                index: index,
                visibleFrame: visibleFrame,
                size: window.frame.size
            ))
        }
        guard animated else {
            updates.forEach { $0.0.setFrameOrigin($0.1) }
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Anim.duration
            updates.forEach { $0.0.animator().setFrameOrigin($0.1) }
        }
    }

    private func toastView(for toast: ErrorToastItem) -> ErrorToastView {
        ErrorToastView(item: toast, onTap: { [weak self] in
            if let entry = toast.entry {
                self?.navigateToEncyclopedia(entry)
            }
            self?.dismiss(id: toast.id)
        }, onDismiss: { [weak self] in
            self?.dismiss(id: toast.id)
        })
    }
    
    // MARK: - Show Detail Window
    func showDetailWindow(_ entry: ErrorEntry) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = entry.title
        window.center()
        
        let view = ErrorDetailView(entry: entry, onDismiss: {
            window.close()
        })
        
        window.contentView = NSHostingView(rootView: view)
        window.makeKeyAndOrderFront(nil)
    }
    
    // MARK: - Navigate to Encyclopedia
    func navigateToEncyclopedia(_ entry: ErrorEntry) {
        ErrorHubNavigationState.shared.navigateToEntry(id: entry.id)
    }
}

// MARK: - Error Toast View
struct ErrorToastView: View {
    let item: ErrorToastItem
    let onTap: () -> Void
    let onDismiss: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: item.severity.colorHex).opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: item.severity.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color(hex: item.severity.colorHex))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Text(item.message)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(2)

                        if item.entry != nil {
                            Text("error.toast.open_encyclopedia")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(hex: "#007AFF"))
                        }
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("button.close"))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: item.severity.colorHex).opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - View Extension for Error Handling
extension View {
    func withErrorToast() -> some View {
        self.modifier(ErrorToastModifier())
    }
}

struct ErrorToastModifier: ViewModifier {
    @ObservedObject private var manager = ErrorToastManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ErrorToastOverlay()
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 20)
                    .padding(.trailing, 20)
            )
    }
}

struct ErrorToastOverlay: View {
    @ObservedObject private var manager = ErrorToastManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(manager.toasts) { toast in
                ErrorToastView(item: toast, onTap: {
                    if let entry = toast.entry {
                        ErrorToastManager.shared.navigateToEncyclopedia(entry)
                    }
                    ErrorToastManager.shared.dismiss(id: toast.id)
                }, onDismiss: {
                    ErrorToastManager.shared.dismiss(id: toast.id)
                })
                .frame(width: 380)
            }
        }
    }
}
