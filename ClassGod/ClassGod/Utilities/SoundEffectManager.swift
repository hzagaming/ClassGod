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
    
    var systemSoundID: SystemSoundID? {
        switch self {
        case .popoverOpen:      return 1106  // Tock
        case .popoverClose:     return 1105  // Tock
        case .tabSaved:         return 1102  // Glass
        case .tabDeleted:       return 1107  // Tock
        case .switchSuccess:    return 1103  // Basso
        case .switchFailure:    return 1006  // Basso (lower)
        case .shortcutRecorded: return 1104  // Ping
        case .shortcutConflict: return 1005  // Basso
        case .buttonClick:      return 1105  // Tock
        case .settingsChanged:  return 1106  // Tock
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
