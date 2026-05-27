//
//  SystemInfoWidget.swift
//  ClassGod
//

import SwiftUI

struct SystemInfoWidget: View {
    @ObservedObject var monitor = SystemMonitor.shared
    @State private var copiedLabel: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            infoRow(icon: "desktopcomputer", label: "HOST", value: monitor.system.hostname)
            infoRow(icon: "cpu", label: "MODEL", value: monitor.system.model)
            infoRow(icon: "memorychip", label: "ARCH", value: monitor.system.architecture)
            infoRow(icon: "number", label: "KERNEL", value: monitor.system.kernelVersion)
            infoRow(icon: "apple.logo", label: "macOS", value: monitor.system.osVersion)
        }
        .padding(10)
    }
    
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.25))
                .frame(width: 14)
            
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
                .frame(width: 44, alignment: .leading)
            
            Text(value)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(1)
            
            Spacer()
            
            if copiedLabel == label {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(value, forType: .string)
            withAnimation(.easeInOut(duration: 0.2)) {
                copiedLabel = label
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if copiedLabel == label {
                        copiedLabel = nil
                    }
                }
            }
        }
    }
}
