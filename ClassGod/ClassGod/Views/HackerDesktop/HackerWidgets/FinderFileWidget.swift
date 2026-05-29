//
//  FinderFileWidget.swift
//  ClassGod
//

import SwiftUI

struct FinderFileWidget: View {
    let filePath: String?
    var onDrop: ((URL) -> Void)? = nil
    @State private var isHovered = false
    @State private var isTargeted = false
    
    private var resolvedURL: URL? {
        guard let path = filePath else { return nil }
        let url = URL(fileURLWithPath: path)
        return FileManager.default.fileExists(atPath: path) ? url : nil
    }
    
    private var displayName: String {
        guard let url = resolvedURL else { return "Drop File" }
        return url.deletingPathExtension().lastPathComponent
    }
    
    private var fileIcon: NSImage {
        guard let url = resolvedURL else {
            return NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil) ?? NSImage()
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Image(nsImage: fileIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
            
            Text(displayName)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(resolvedURL != nil ? .white : .white.opacity(0.4))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 80)
                .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            guard let url = resolvedURL else { return }
            SoundEffectManager.shared.playButtonClick()
            NSWorkspace.shared.open(url)
        }
        .onHover { isHovered = $0 }
        .scaleEffect(isHovered && resolvedURL != nil ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .dropDestination(for: URL.self) { urls, location in
            guard let first = urls.first else { return false }
            SoundEffectManager.shared.playWidgetAdded()
            HapticManager.shared.success()
            onDrop?(first)
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isTargeted ? Color.cyan.opacity(0.6) : Color.clear, lineWidth: 1.5)
                .animation(.easeInOut(duration: 0.15), value: isTargeted)
        )
    }
}

#Preview {
    FinderFileWidget(filePath: "/Applications/Safari.app")
        .frame(width: 100, height: 120)
        .background(Color(white: 0.04))
}
