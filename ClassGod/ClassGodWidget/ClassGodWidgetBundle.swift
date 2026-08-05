//
//  ClassGodWidgetBundle.swift
//  ClassGodWidget
//

import WidgetKit
import SwiftUI

@main
struct ClassGodWidgetBundle: WidgetBundle {
    var body: some Widget {
        // System
        CPUWidgetConfig()
        MemoryWidgetConfig()
        DiskWidgetConfig()
        NetworkWidgetConfig()
        BatteryWidgetConfig()
        UptimeWidgetConfig()
        SystemInfoWidgetConfig()
        
        // Info
        ClockWidgetConfig()
        WorldClockWidgetConfig()
        CalendarWidgetConfig()
        WeatherWidgetConfig()
        
        // Tools
        TodoWidgetConfig()
        NotesWidgetConfig()
        FileWidgetConfig()
        AppLauncherWidgetConfig()
        
        // Fun / Hacker
        TerminalLogWidgetConfig()
        AsciiArtWidgetConfig()
        CryptoWidgetConfig()
        QuoteWidgetConfig()
    }
}

// MARK: - Widget Configurations

// --- System ---

struct CPUWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.cpu.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            CPUWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("CPU Monitor")
        .description("Real-time CPU usage with hacker-style gauge.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MemoryWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.memory.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            MemoryWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("Memory")
        .description("RAM usage bar with color thresholds.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DiskWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.disk.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            DiskWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("Disk Usage")
        .description("Storage ring chart with free space.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NetworkWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.network.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            NetworkWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("Network")
        .description("Upload / download speed monitor.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct BatteryWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.battery.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            BatteryWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("Battery")
        .description("Battery level and charging status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct UptimeWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.uptime.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            UptimeWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("Uptime")
        .description("System uptime in hacker monospace.")
        .supportedFamilies([.systemSmall])
    }
}

// --- Info ---

struct ClockWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.clock.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            ClockWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("Clock")
        .description("Digital clock with date.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WorldClockWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.worldClock.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            WorldClockWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("World Clock")
        .description("Multi-city time zones.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct CalendarWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.calendar.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            CalendarWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("Calendar")
        .description("Monthly calendar with today highlighted.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct WeatherWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.weather.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            WeatherWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("Weather")
        .description("Temperature and condition icon.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SystemInfoWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.systemInfo.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            SystemInfoWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("System Info")
        .description("macOS version and hostname.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// --- Tools ---

struct TodoWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.todo.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            TodoWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("Todo List")
        .description("Checklist with hacker checkbox style.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NotesWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.notes.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            NotesWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("Notes")
        .description("Quick note preview.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct FileWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.files.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            FileWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("Recent Files")
        .description("Recently accessed files.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct AppLauncherWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.appLauncher.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            AppLauncherWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("App Launcher")
        .description("Launch apps directly from desktop.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// --- Fun / Hacker ---

struct TerminalLogWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.terminal.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            TerminalLogWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("Terminal Log")
        .description("Hacker-style system log stream.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct AsciiArtWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.asciiArt.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            AsciiArtWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("ASCII Art")
        .description("Random hacker ASCII art.")
        .supportedFamilies([.systemSmall])
    }
}

struct CryptoWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.crypto.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            CryptoWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("Crypto")
        .description("BTC / ETH prices with trend arrows.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct QuoteWidgetConfig: Widget {
    let kind = ClassGodWidgetKind.quote.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            QuoteWidgetView(entry: entry).classGodWidgetBackground()
        }
        .configurationDisplayName("Hacker Quote")
        .description("Daily hacker / tech quote.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private extension View {
    func classGodWidgetBackground() -> some View {
        containerBackground(for: .widget) {
            Color.black
        }
    }
}
