//
//  SoundEffectManager.swift
//  ClassGod
//
//  Created by Charlie Zhong on 22/5/26.
//

import Foundation
import AppKit

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
    
    var systemSoundName: String {
        switch self {
        case .popoverOpen:        return "Pop"
        case .popoverClose:       return "Tink"
        case .tabSaved:           return "Glass"
        case .tabDeleted:         return "Basso"
        case .switchSuccess:      return "Ping"
        case .switchFailure:      return "Basso"
        case .shortcutRecorded:   return "Ping"
        case .shortcutConflict:   return "Basso"
        case .buttonClick:        return "Tink"
        case .settingsChanged:    return "Tink"
        case .wallpaperAdded:     return "Glass"
        case .wallpaperDeleted:   return "Basso"
        case .wallpaperSwitched:  return "Ping"
        case .wallpaperPlayPause: return "Tink"
        case .widgetAdded:        return "Ping"
        case .widgetDeleted:      return "Basso"
        case .widgetLocked:       return "Tink"
        case .widgetPickerOpen:   return "Funk"
        case .layoutReset:        return "Ping"
        case .layoutCleared:      return "Basso"
        case .gridToggle:         return "Tink"
        case .dragStart:          return "Pop"
        case .resizeStart:        return "Pop"
        case .temperatureWarning: return "Basso"
        }
    }
}

final class SoundEffectManager {
    static let shared = SoundEffectManager()
    
    private var isEnabled: Bool {
        PreferencesManager.shared.preferences.enableSoundEffects
    }

    private var sounds: [String: NSSound] = [:]
    
    private init() {}

    func play(_ effect: SoundEffect) {
        guard isEnabled else { return }
        playSound(named: effect.systemSoundName)
    }

    private func playSound(named name: String) {
        let sound: NSSound
        if let cached = sounds[name] {
            sound = cached
        } else if let created = NSSound(data: makeToneData(named: name)) {
            sounds[name] = created
            sound = created
        } else {
            NSSound.beep()
            return
        }
        sound.stop()
        sound.play()
    }

    private func makeToneData(named name: String) -> Data {
        let parameters: (frequency: Double, duration: Double) = switch name {
        case "Basso":     (220, 0.14)
        case "Blow":      (170, 0.10)
        case "Bottle":    (660, 0.09)
        case "Frog":      (330, 0.11)
        case "Funk":      (520, 0.10)
        case "Glass":     (1_040, 0.12)
        case "Morse":     (880, 0.06)
        case "Ping":      (880, 0.09)
        case "Pop":       (720, 0.05)
        case "Sosumi":    (440, 0.15)
        case "Submarine": (140, 0.18)
        case "Tink":      (1_200, 0.06)
        default:           (640, 0.08)
        }

        let sampleRate = 44_100
        let sampleCount = max(1, Int(Double(sampleRate) * parameters.duration))
        let dataByteCount = UInt32(sampleCount * MemoryLayout<Int16>.size)
        var data = Data()
        data.reserveCapacity(44 + Int(dataByteCount))

        data.append(contentsOf: "RIFF".utf8)
        appendLittleEndian(UInt32(36) + dataByteCount, to: &data)
        data.append(contentsOf: "WAVEfmt ".utf8)
        appendLittleEndian(UInt32(16), to: &data)
        appendLittleEndian(UInt16(1), to: &data)
        appendLittleEndian(UInt16(1), to: &data)
        appendLittleEndian(UInt32(sampleRate), to: &data)
        appendLittleEndian(UInt32(sampleRate * MemoryLayout<Int16>.size), to: &data)
        appendLittleEndian(UInt16(MemoryLayout<Int16>.size), to: &data)
        appendLittleEndian(UInt16(16), to: &data)
        data.append(contentsOf: "data".utf8)
        appendLittleEndian(dataByteCount, to: &data)

        for index in 0..<sampleCount {
            let time = Double(index) / Double(sampleRate)
            let attack = min(1, time / 0.006)
            let release = max(0, 1 - time / parameters.duration)
            let envelope = attack * release * release
            let fundamental = sin(2 * .pi * parameters.frequency * time)
            let harmonic = 0.22 * sin(2 * .pi * parameters.frequency * 2 * time)
            let value = max(-1, min(1, (fundamental + harmonic) * envelope * 0.32))
            appendLittleEndian(Int16(value * Double(Int16.max)), to: &data)
        }
        return data
    }

    private func appendLittleEndian<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var littleEndian = value.littleEndian
        withUnsafeBytes(of: &littleEndian) { bytes in
            data.append(contentsOf: bytes)
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
    
    private let glitchSoundNames: [String] = [
        "Basso",
        "Blow",
        "Bottle",
        "Frog",
        "Funk",
        "Morse",
        "Sosumi",
        "Submarine",
        "Tink",
    ]
    
    func playGlitchSound() {
        guard isEnabled else { return }
        guard let soundName = glitchSoundNames.randomElement() else { return }
        playSound(named: soundName)
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
        playSound(named: "Glass")
    }
    
    func playScreenFlashSound() {
        guard isEnabled else { return }
        playSound(named: "Basso")
    }
    
    // MARK: - Window Switch SFX
    
    func playWindowOpen(feature: String = "") {
        guard isEnabled else { return }
        switch feature {
        case "destintab":
            playSound(named: "Basso")
        case "superswitch":
            playSound(named: "Ping")
        case "browserbypasser":
            playSound(named: "Sosumi")
        case "assessprephack":
            playSound(named: "Funk")
        case "hackerdesktop":
            playSound(named: "Sosumi")
        case "fancontrol":
            playSound(named: "Ping")
        case "activitymonitor":
            playSound(named: "Tink")
        case "permissioncenter":
            playSound(named: "Glass")
        case "errorhub":
            playSound(named: "Basso")
        default:
            playPopoverOpen()
        }
    }
    
    func playWindowClose(feature: String = "") {
        guard isEnabled else { return }
        switch feature {
        case "destintab", "superswitch", "browserbypasser", "assessprephack", "hackerdesktop",
             "fancontrol", "activitymonitor", "permissioncenter", "errorhub":
            playSound(named: "Tink")
        default:
            playPopoverClose()
        }
    }
    
    func playFeatureSwitch() {
        guard isEnabled else { return }
        playSound(named: "Tink")
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
