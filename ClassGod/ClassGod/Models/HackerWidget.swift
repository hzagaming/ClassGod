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
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .cpuGauge:      return "CPU Gauge"
        case .memoryBar:     return "Memory"
        case .diskGrid:      return "Disk Usage"
        case .networkSpeed:  return "Network"
        case .processList:   return "Process List"
        case .uptime:        return "Uptime"
        case .clock:         return "Clock"
        case .battery:       return "Battery"
        case .tempSensors:   return "Temperature"
        case .systemInfo:    return "System Info"
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
    
    init(
        id: UUID = UUID(),
        type: WidgetType,
        x: Double = 20,
        y: Double = 20,
        width: Double? = nil,
        height: Double? = nil,
        title: String? = nil,
        refreshInterval: Double = 1.0,
        isLocked: Bool = false
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
    }
}
