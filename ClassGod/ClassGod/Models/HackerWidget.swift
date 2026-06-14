//
//  HackerWidget.swift
//  ClassGod
//

import Foundation

enum WidgetType: String, Codable, CaseIterable, Identifiable {
    case cpuGauge = "cpuGauge"
    case memoryBar = "memoryBar"
    case diskGrid = "diskGrid"
    case networkSpeed = "networkSpeed"
    case processList = "processList"
    case uptime = "uptime"
    case clock = "clock"
    case battery = "battery"
    case tempSensors = "tempSensors"
    case systemInfo = "systemInfo"
    case finderFile = "finderFile"
    case fanThermalList = "fanThermalList"
    case fanControlDash = "fanControlDash"
    case taskManager = "taskManager"
    // Desktop tabs (fixed on Finder desktop with title bar)
    case noteTab = "noteTab"
    case todoTab = "todoTab"
    case terminalTab = "terminalTab"
    case cryptoTab = "cryptoTab"
    case quoteTab = "quoteTab"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .cpuGauge:      return String(localized: "widget.cpu_gauge")
        case .memoryBar:     return String(localized: "widget.memory")
        case .diskGrid:      return String(localized: "widget.disk_usage")
        case .networkSpeed:  return String(localized: "widget.network")
        case .processList:   return String(localized: "widget.process_list")
        case .uptime:        return String(localized: "widget.uptime")
        case .clock:         return String(localized: "widget.clock")
        case .battery:       return String(localized: "widget.battery")
        case .tempSensors:   return String(localized: "widget.temperature")
        case .systemInfo:    return String(localized: "widget.system_info")
        case .finderFile:    return String(localized: "widget.file")
        case .fanThermalList:return String(localized: "widget.fan_thermal")
        case .fanControlDash:return String(localized: "widget.fan_dashboard")
        case .taskManager:   return String(localized: "widget.task_manager")
        case .noteTab:       return String(localized: "widget.note_tab")
        case .todoTab:       return String(localized: "widget.todo_tab")
        case .terminalTab:   return String(localized: "widget.terminal_tab")
        case .cryptoTab:     return String(localized: "widget.crypto_tab")
        case .quoteTab:      return String(localized: "widget.quote_tab")
        }
    }
    
    var iconName: String {
        switch self {
        case .cpuGauge:      return "cpu"
        case .memoryBar:     return "memorychip"
        case .diskGrid:      return "internaldrive"
        case .networkSpeed:  return "network"
        case .processList:   return "list.bullet.rectangle"
        case .uptime:        return "timer"
        case .clock:         return "clock.digital"
        case .battery:       return "battery.100"
        case .tempSensors:   return "thermometer.transmission"
        case .systemInfo:    return "info.circle"
        case .finderFile:    return "doc"
        case .fanThermalList:return "fan.desk"
        case .fanControlDash:return "gauge.with.dots.needle.67percent"
        case .taskManager:   return "list.bullet.indent"
        case .noteTab:       return "note.text"
        case .todoTab:       return "checkmark.square"
        case .terminalTab:   return "terminal"
        case .cryptoTab:     return "bitcoinsign.circle"
        case .quoteTab:      return "quote.bubble"
        }
    }
    
    var defaultSize: CGSize {
        switch self {
        case .cpuGauge:      return CGSize(width: 160, height: 160)
        case .memoryBar:     return CGSize(width: 200, height: 100)
        case .diskGrid:      return CGSize(width: 220, height: 140)
        case .networkSpeed:  return CGSize(width: 200, height: 120)
        case .processList:   return CGSize(width: 260, height: 280)
        case .uptime:        return CGSize(width: 180, height: 80)
        case .clock:         return CGSize(width: 200, height: 80)
        case .battery:       return CGSize(width: 160, height: 100)
        case .tempSensors:   return CGSize(width: 180, height: 120)
        case .systemInfo:    return CGSize(width: 220, height: 160)
        case .finderFile:    return CGSize(width: 100, height: 120)
        case .fanThermalList:return CGSize(width: 220, height: 280)
        case .fanControlDash:return CGSize(width: 240, height: 180)
        case .taskManager:   return CGSize(width: 300, height: 340)
        case .noteTab:       return CGSize(width: 240, height: 180)
        case .todoTab:       return CGSize(width: 240, height: 220)
        case .terminalTab:   return CGSize(width: 320, height: 200)
        case .cryptoTab:     return CGSize(width: 220, height: 100)
        case .quoteTab:      return CGSize(width: 260, height: 120)
        }
    }
    
    var minSize: CGSize {
        switch self {
        case .cpuGauge:      return CGSize(width: 120, height: 120)
        case .memoryBar:     return CGSize(width: 140, height: 80)
        case .diskGrid:      return CGSize(width: 160, height: 100)
        case .networkSpeed:  return CGSize(width: 140, height: 100)
        case .processList:   return CGSize(width: 200, height: 180)
        case .uptime:        return CGSize(width: 140, height: 60)
        case .clock:         return CGSize(width: 160, height: 60)
        case .battery:       return CGSize(width: 120, height: 80)
        case .tempSensors:   return CGSize(width: 140, height: 90)
        case .systemInfo:    return CGSize(width: 180, height: 120)
        case .finderFile:    return CGSize(width: 80, height: 100)
        case .fanThermalList:return CGSize(width: 160, height: 180)
        case .fanControlDash:return CGSize(width: 180, height: 140)
        case .taskManager:   return CGSize(width: 220, height: 240)
        case .noteTab:       return CGSize(width: 180, height: 120)
        case .todoTab:       return CGSize(width: 180, height: 140)
        case .terminalTab:   return CGSize(width: 240, height: 120)
        case .cryptoTab:     return CGSize(width: 180, height: 80)
        case .quoteTab:      return CGSize(width: 200, height: 80)
        }
    }
    
    var isDesktopTab: Bool {
        switch self {
        case .noteTab, .todoTab, .terminalTab, .cryptoTab, .quoteTab:
            return true
        default:
            return false
        }
    }
}

struct HackerWidgetItem: Codable, Identifiable, Equatable {
    let id: UUID
    var type: WidgetType
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var title: String
    var refreshInterval: Double
    var isLocked: Bool
    var filePath: String?
    
    init(
        id: UUID = UUID(),
        type: WidgetType,
        x: Double = 20,
        y: Double = 20,
        width: Double? = nil,
        height: Double? = nil,
        title: String? = nil,
        refreshInterval: Double = 1.0,
        isLocked: Bool = false,
        filePath: String? = nil
    ) {
        self.id = id
        self.type = type
        self.x = x
        self.y = y
        let defaultSize = type.defaultSize
        self.width = width ?? defaultSize.width
        self.height = height ?? defaultSize.height
        self.title = title ?? type.displayName
        self.refreshInterval = refreshInterval
        self.isLocked = isLocked
        self.filePath = filePath
    }
}
