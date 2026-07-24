//
//  SystemInfoWidgetView.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct SystemInfoWidgetView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall: smallView
        case .systemMedium: mediumView
        default: smallView
        }
    }
    
    private var smallView: some View {
        ZStack {
            Color.black
            VStack(alignment: .leading, spacing: 4) {
                Text("SYS_INFO")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan.opacity(0.6))
                Text(hostName)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
                Text(osVersion)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                Text("CPU: \(ProcessInfo.processInfo.processorCount) cores")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(10)
        }
    }
    
    private var mediumView: some View {
        ZStack {
            Color.black
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("SYSTEM INFORMATION")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.6))
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 3) {
                        infoRow(label: "HOST", value: hostName)
                        infoRow(label: "OS", value: osVersion)
                        infoRow(label: "CPU", value: "\(ProcessInfo.processInfo.processorCount) cores")
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        infoRow(label: "ARCH", value: ProcessInfo.processInfo.machineHardwareName)
                        infoRow(label: "MEM", value: "\(Int(entry.memoryTotal)) GB")
                        infoRow(label: "UPTIME", value: uptimeString)
                    }
                }
            }
            .padding(12)
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label + ":")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
            Text(value)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
        }
    }
    
    private var hostName: String {
        ProcessInfo.processInfo.hostName
    }
    
    private var osVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }
    
    private var uptimeString: String {
        let d = Int(entry.uptimeSeconds) / 86400
        let h = (Int(entry.uptimeSeconds) % 86400) / 3600
        return "\(d)d \(h)h"
    }
}

private extension ProcessInfo {
    var machineHardwareName: String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return withUnsafePointer(to: &sysinfo.machine) { ptr in
            String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }
    }
}
