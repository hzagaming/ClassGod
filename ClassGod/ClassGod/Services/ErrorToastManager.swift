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

// MARK: - Toast Item
struct ErrorToastItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let severity: ErrorSeverity
    let entry: ErrorEntry?
    let timestamp: Date
}

// MARK: - Error Toast Manager
final class ErrorToastManager: ObservableObject {
    static let shared = ErrorToastManager()
    
    @Published private(set) var toasts: [ErrorToastItem] = []
    private var windows: [UUID: NSWindow] = [:]
    private let queue = DispatchQueue(label: "com.classgod.errorToast", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Show Toast
    func show(title: String, message: String, severity: ErrorSeverity = .high, entry: ErrorEntry? = nil) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let toast = ErrorToastItem(title: title, message: message, severity: severity, entry: entry, timestamp: Date())
            
            DispatchQueue.main.async {
                self.toasts.append(toast)
                self.presentToastWindow(toast)
                
                // Auto dismiss after 8 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
                    self?.dismiss(id: toast.id)
                }
            }
        }
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
        show(title: title, message: message, severity: .high, entry: nil)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            ErrorKnowledgeBase.shared.ensureLoaded()
            let matching = ErrorKnowledgeBase.shared.search(query: "\(nsError.domain) \(nsError.code)")
            guard let entry = matching.first?.entry else { return }
            DispatchQueue.main.async {
                self?.enrichLatestToast(with: entry)
            }
        }
    }
    
    private func enrichLatestToast(with entry: ErrorEntry) {
        guard let lastIndex = toasts.indices.last else { return }
        let last = toasts[lastIndex]
        guard last.entry == nil else { return }
        toasts[lastIndex] = ErrorToastItem(
            title: last.title,
            message: last.message,
            severity: last.severity,
            entry: entry,
            timestamp: last.timestamp
        )
    }
    
    // MARK: - Dismiss
    func dismiss(id: UUID) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.toasts.removeAll { $0.id == id }
            if let window = self.windows[id] {
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.2
                    window.animator().alphaValue = 0
                } completionHandler: {
                    window.orderOut(nil)
                }
                self.windows.removeValue(forKey: id)
            }
        }
    }
    
    // MARK: - Dismiss All
    func dismissAll() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for (_, window) in self.windows {
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.2
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
        
        let view = ErrorToastView(item: toast, onTap: { [weak self] in
            if let entry = toast.entry {
                self?.navigateToEncyclopedia(entry)
            }
            self?.dismiss(id: toast.id)
        }, onDismiss: { [weak self] in
            self?.dismiss(id: toast.id)
        })
        .frame(width: width, height: height)
        
        window.contentView = NSHostingView(rootView: view)
        
        // Position in top-right corner
        if let screen = NSScreen.main {
            let padding: CGFloat = 20
            let x = screen.visibleFrame.maxX - width - padding
            let y = screen.visibleFrame.maxY - height - padding - CGFloat(windows.count * 130)
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        window.alphaValue = 0
        window.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            ctx.timingFunction = .init(name: .easeOut)
            window.animator().alphaValue = 1
        }
        
        windows[toast.id] = window
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
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Severity icon
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
                        Text("Click to open in Encyclopedia →")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#007AFF"))
                    }
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
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
        }
        .buttonStyle(.plain)
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


