//
//  WidgetEntry.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

struct WidgetEntry: TimelineEntry {
    let date: Date
    
    // System
    let cpuUsage: Double
    let memoryUsage: Double
    let memoryTotal: Double
    let diskFree: Double
    let diskTotal: Double
    let networkDown: Double
    let networkUp: Double
    let batteryLevel: Double
    let batteryIsCharging: Bool
    let uptimeSeconds: TimeInterval
    
    // Info
    let clockCity: String
    let weatherCity: String
    let weatherTemp: String
    let weatherCondition: String
    
    // Tools
    let todoItems: [TodoItem]
    let noteContent: String
    let filePaths: [FileItem]
    let appItems: [AppLauncherItem]
    
    // Fun
    let cryptoBTC: String
    let cryptoETH: String
    let quoteText: String
    let quoteAuthor: String
    let terminalLogs: [String]
    let asciiArt: String
    
    static var preview: WidgetEntry {
        WidgetEntry(
            date: Date(),
            cpuUsage: 42.5,
            memoryUsage: 8.2,
            memoryTotal: 16.0,
            diskFree: 256.0,
            diskTotal: 512.0,
            networkDown: 12.5,
            networkUp: 3.2,
            batteryLevel: 87.0,
            batteryIsCharging: true,
            uptimeSeconds: 86400 * 3 + 3600 * 5,
            clockCity: "Beijing",
            weatherCity: "Beijing",
            weatherTemp: "24°",
            weatherCondition: "cloud.sun.fill",
            todoItems: [
                TodoItem(id: UUID(), text: "Review code", isDone: true),
                TodoItem(id: UUID(), text: "Deploy update", isDone: false),
                TodoItem(id: UUID(), text: "Write docs", isDone: false)
            ],
            noteContent: "Remember to check system logs before pushing to production.",
            filePaths: [
                FileItem(id: UUID(), path: "/Users/Desktop/project", name: "project"),
                FileItem(id: UUID(), path: "/Users/Desktop/report.pdf", name: "report.pdf")
            ],
            appItems: [
                AppLauncherItem(id: UUID(), bundleID: "com.apple.Terminal", name: "Terminal"),
                AppLauncherItem(id: UUID(), bundleID: "com.apple.Safari", name: "Safari")
            ],
            cryptoBTC: "$64,230 ▲2.4%",
            cryptoETH: "$3,450 ▼0.8%",
            quoteText: "The only truly secure system is one that is powered off.",
            quoteAuthor: "Gene Spafford",
            terminalLogs: [
                "[14:02:01] kernel: system boot",
                "[14:02:05] sshd: accepted key",
                "[14:03:12] cron: daily backup"
            ],
            asciiArt: #"""
  .--.
 /  o \
|   __|
  \_/
"""#
        )
    }
    
    static var placeholder: WidgetEntry {
        WidgetEntry(
            date: Date(),
            cpuUsage: 0,
            memoryUsage: 0,
            memoryTotal: 16,
            diskFree: 0,
            diskTotal: 512,
            networkDown: 0,
            networkUp: 0,
            batteryLevel: 100,
            batteryIsCharging: false,
            uptimeSeconds: 0,
            clockCity: "Local",
            weatherCity: "",
            weatherTemp: "--",
            weatherCondition: "questionmark",
            todoItems: [],
            noteContent: "",
            filePaths: [],
            appItems: [],
            cryptoBTC: "--",
            cryptoETH: "--",
            quoteText: "Loading...",
            quoteAuthor: "",
            terminalLogs: [],
            asciiArt: "..."
        )
    }
}
