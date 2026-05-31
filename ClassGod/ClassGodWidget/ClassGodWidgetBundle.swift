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
        
        // Info
        ClockWidgetConfig()
        WorldClockWidgetConfig()
        CalendarWidgetConfig()
        WeatherWidgetConfig()
        SystemInfoWidgetConfig()
        
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
    let kind: String = "CPUWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            CPUWidgetView(entry: entry)
        }
        .configurationDisplayName("CPU Monitor")
        .description("Real-time CPU usage with hacker-style gauge.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MemoryWidgetConfig: Widget {
    let kind: String = "MemoryWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            MemoryWidgetView(entry: entry)
        }
        .configurationDisplayName("Memory")
        .description("RAM usage bar with color thresholds.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DiskWidgetConfig: Widget {
    let kind: String = "DiskWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            DiskWidgetView(entry: entry)
        }
        .configurationDisplayName("Disk Usage")
        .description("Storage ring chart with free space.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NetworkWidgetConfig: Widget {
    let kind: String = "NetworkWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            NetworkWidgetView(entry: entry)
        }
        .configurationDisplayName("Network")
        .description("Upload / download speed monitor.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct BatteryWidgetConfig: Widget {
    let kind: String = "BatteryWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            BatteryWidgetView(entry: entry)
        }
        .configurationDisplayName("Battery")
        .description("Battery level and charging status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct UptimeWidgetConfig: Widget {
    let kind: String = "UptimeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            UptimeWidgetView(entry: entry)
        }
        .configurationDisplayName("Uptime")
        .description("System uptime in hacker monospace.")
        .supportedFamilies([.systemSmall])
    }
}

// --- Info ---

struct ClockWidgetConfig: Widget {
    let kind: String = "ClockWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            ClockWidgetView(entry: entry)
        }
        .configurationDisplayName("Clock")
        .description("Digital clock with date.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WorldClockWidgetConfig: Widget {
    let kind: String = "WorldClockWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            WorldClockWidgetView(entry: entry)
        }
        .configurationDisplayName("World Clock")
        .description("Multi-city time zones.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct CalendarWidgetConfig: Widget {
    let kind: String = "CalendarWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("Calendar")
        .description("Monthly calendar with today highlighted.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct WeatherWidgetConfig: Widget {
    let kind: String = "WeatherWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            WeatherWidgetView(entry: entry)
        }
        .configurationDisplayName("Weather")
        .description("Temperature and condition icon.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SystemInfoWidgetConfig: Widget {
    let kind: String = "SystemInfoWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            SystemInfoWidgetView(entry: entry)
        }
        .configurationDisplayName("System Info")
        .description("macOS version and hostname.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// --- Tools ---

struct TodoWidgetConfig: Widget {
    let kind: String = "TodoWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            TodoWidgetView(entry: entry)
        }
        .configurationDisplayName("Todo List")
        .description("Checklist with hacker checkbox style.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NotesWidgetConfig: Widget {
    let kind: String = "NotesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            NotesWidgetView(entry: entry)
        }
        .configurationDisplayName("Notes")
        .description("Quick note preview.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct FileWidgetConfig: Widget {
    let kind: String = "FileWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            FileWidgetView(entry: entry)
        }
        .configurationDisplayName("Recent Files")
        .description("Recently accessed files.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct AppLauncherWidgetConfig: Widget {
    let kind: String = "AppLauncherWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            AppLauncherWidgetView(entry: entry)
        }
        .configurationDisplayName("App Launcher")
        .description("Launch apps directly from desktop.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// --- Fun / Hacker ---

struct TerminalLogWidgetConfig: Widget {
    let kind: String = "TerminalLogWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            TerminalLogWidgetView(entry: entry)
        }
        .configurationDisplayName("Terminal Log")
        .description("Hacker-style system log stream.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct AsciiArtWidgetConfig: Widget {
    let kind: String = "AsciiArtWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            AsciiArtWidgetView(entry: entry)
        }
        .configurationDisplayName("ASCII Art")
        .description("Random hacker ASCII art.")
        .supportedFamilies([.systemSmall])
    }
}

struct CryptoWidgetConfig: Widget {
    let kind: String = "CryptoWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            CryptoWidgetView(entry: entry)
        }
        .configurationDisplayName("Crypto")
        .description("BTC / ETH prices with trend arrows.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct QuoteWidgetConfig: Widget {
    let kind: String = "QuoteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            QuoteWidgetView(entry: entry)
        }
        .configurationDisplayName("Hacker Quote")
        .description("Daily hacker / tech quote.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
