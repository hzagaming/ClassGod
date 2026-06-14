//
//  SoundEffectManager.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import AppKit
import AudioToolbox

enum SoundEffect: String, CaseIterable {
    case popoverOpen = "PopoverOpen"
    case popoverClose = "PopoverClose"
    case tabSaved = "TabSaved"
    case tabDeleted = "TabDeleted"
    case switchSuccess = "SwitchSuccess"
    case switchFailure = "SwitchFailure"
    case shortcutRecorded = "ShortcutRecorded"
    case shortcutConflict = "ShortcutConflict"
    case buttonClick = "ButtonClick"
    case settingsChanged = "SettingsChanged"
    case wallpaperAdded = "WallpaperAdded"
    case wallpaperDeleted = "WallpaperDeleted"
    case wallpaperSwitched = "WallpaperSwitched"
    case wallpaperPlayPause = "WallpaperPlayPause"
    case widgetAdded = "WidgetAdded"
    case widgetDeleted = "WidgetDeleted"
    case widgetLocked = "WidgetLocked"
    case widgetPickerOpen = "WidgetPickerOpen"
    case layoutReset = "LayoutReset"
    case layoutCleared = "LayoutCleared"
    case gridToggle = "GridToggle"
    case dragStart = "DragStart"
    case resizeStart = "ResizeStart"
    case temperatureWarning = "TemperatureWarning"
    
    var systemSoundID: SystemSoundID? {
        switch self {
        case .popoverOpen:       return 1106  // Tock
        case .popoverClose:      return 1105  // Tock
        case .tabSaved:          return 1102  // Glass
        case .tabDeleted:        return 1107  // Tock
        case .switchSuccess:     return 1103  // Basso
        case .switchFailure:     return 1006  // Basso (lower)
        case .shortcutRecorded:  return 1104  // Ping
        case .shortcutConflict:  return 1005  // Basso
        case .buttonClick:       return 1105  // Tock
        case .settingsChanged:   return 1106  // Tock
        case .wallpaperAdded:    return 1262  // Glass — cinematic add
        case .wallpaperDeleted:  return 1053  // Error — removal
        case .wallpaperSwitched: return 1104  // Ping — quick switch
        case .wallpaperPlayPause: return 1106 // Tock — toggle
        case .widgetAdded:       return 1104  // Ping — tech add
        case .widgetDeleted:     return 1053  // Error — removal
        case .widgetLocked:      return 1106  // Tock — toggle lock
        case .widgetPickerOpen:  return 1103  // Basso — modal open
        case .layoutReset:       return 1104  // Ping — reset confirmation
        case .layoutCleared:     return 1053  // Error — mass removal
        case .gridToggle:        return 1106  // Tock — toggle grid
        case .dragStart:         return 1107  // Tock — light grab
        case .resizeStart:       return 1107  // Tock — light grab
        case .temperatureWarning: return 1005  // Basso — warning alert
        }
    }
}

final class SoundEffectManager {
    static let shared = SoundEffectManager()
    
    private var isEnabled: Bool {
        PreferencesManager.shared.preferences.enableSoundEffects
    }
    
    private init() {}
    
    func play(_ effect: SoundEffect) {
        guard isEnabled else { return }
        if let soundID = effect.systemSoundID {
            AudioServicesPlaySystemSound(soundID)
        }
    }
    
    func playSwitchSuccess() {
        play(.switchSuccess)
    }
    
    func playSwitchFailure() {
        play(.switchFailure)
    }
    
    func playPopoverOpen() {
        play(.popoverOpen)
    }
    
    func playPopoverClose() {
        play(.popoverClose)
    }
    
    func playTabSaved() {
        play(.tabSaved)
    }
    
    func playTabDeleted() {
        play(.tabDeleted)
    }
    
    func playShortcutRecorded() {
        play(.shortcutRecorded)
    }
    
    func playButtonClick() {
        play(.buttonClick)
    }
    
    // MARK: - Glitch SFX (chaos launch animation)
    
    private let glitchSoundIDs: [SystemSoundID] = [
        1005,  // Basso (short error)
        1006,  // Basso (error)
        1050,  // Error
        1051,  // Error
        1052,  // Error
        1053,  // Error
        1107,  // Tock
        1256,  // Basso
        1257,  // Funk
        1262,  // Glass
        1306,  // Error
        1328,  // Sosumi
        1330,  // System
        1331,  // System
        1332,  // System
        1333,  // System
        1334,  // System
        1335,  // System
        1336,  // System
    ]
    
    func playGlitchSound() {
        guard isEnabled else { return }
        guard let soundID = glitchSoundIDs.randomElement() else { return }
        AudioServicesPlaySystemSound(soundID)
    }
    
    func playGlitchBurst(count: Int) {
        guard isEnabled else { return }
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                self.playGlitchSound()
            }
        }
    }
    
    func playCloseBurst(count: Int) {
        guard isEnabled else { return }
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                self.playGlitchSound()
            }
        }
    }
    
    func playHackerRevealSound() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1262)  // Glass — decrypt complete
    }
    
    func playScreenFlashSound() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1306)  // Error — flash impact
    }
    
    // MARK: - Window Switch SFX
    
    func playWindowOpen(feature: String = "") {
        guard isEnabled else { return }
        switch feature {
        case "destintab":
            AudioServicesPlaySystemSound(1103)  // Basso — deep open
        case "superswitch":
            AudioServicesPlaySystemSound(1104)  // Ping — snappy open
        case "browserbypasser":
            AudioServicesPlaySystemSound(1328)  // Sosumi — tech open
        case "assessprephack":
            AudioServicesPlaySystemSound(1257)  // Funk — edgy open
        case "hackerdesktop":
            AudioServicesPlaySystemSound(1328)  // Sosumi — tech dashboard open
        case "fancontrol":
            AudioServicesPlaySystemSound(1104)  // Ping — cool/tech open
        case "activitymonitor":
            AudioServicesPlaySystemSound(1106)  // Tock — system open
        case "permissioncenter":
            AudioServicesPlaySystemSound(1262)  // Glass — security open
        case "errorhub":
            AudioServicesPlaySystemSound(1053)  // Error — error encyclopedia open
        default:
            playPopoverOpen()
        }
    }
    
    func playWindowClose(feature: String = "") {
        guard isEnabled else { return }
        switch feature {
        case "destintab", "superswitch", "browserbypasser", "assessprephack", "hackerdesktop",
             "fancontrol", "activitymonitor", "permissioncenter", "errorhub":
            AudioServicesPlaySystemSound(1107)  // Tock — tight close
        default:
            playPopoverClose()
        }
    }
    
    func playFeatureSwitch() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1106)  // Tock — quick switch
    }
    
    // MARK: - Wallpaper SFX
    
    func playWallpaperAdded() {
        play(.wallpaperAdded)
    }
    
    func playWallpaperDeleted() {
        play(.wallpaperDeleted)
    }
    
    func playWallpaperSwitched() {
        play(.wallpaperSwitched)
    }
    
    func playWallpaperPlayPause() {
        play(.wallpaperPlayPause)
    }
    
    // MARK: - Widget SFX
    
    func playWidgetAdded() {
        play(.widgetAdded)
    }
    
    func playWidgetDeleted() {
        play(.widgetDeleted)
    }
    
    func playWidgetLocked() {
        play(.widgetLocked)
    }
    
    func playWidgetPickerOpen() {
        play(.widgetPickerOpen)
    }
    
    func playLayoutReset() {
        play(.layoutReset)
    }
    
    func playLayoutCleared() {
        play(.layoutCleared)
    }
    
    func playGridToggle() {
        play(.gridToggle)
    }
    
    func playDragStart() {
        play(.dragStart)
    }
    
    func playResizeStart() {
        play(.resizeStart)
    }
    
    func playTemperatureWarning() {
        play(.temperatureWarning)
    }
}

// MARK: - Haptic Feedback

final class HapticManager {
    static let shared = HapticManager()
    
    private var isEnabled: Bool {
        PreferencesManager.shared.preferences.enableHapticFeedback
    }
    
    private init() {}
    
    func play(_ pattern: NSHapticFeedbackManager.FeedbackPattern) {
        guard isEnabled else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .default)
    }
    
    func success() {
        play(.alignment)
    }
    
    func warning() {
        play(.levelChange)
    }
    
    func generic() {
        play(.generic)
    }
}
