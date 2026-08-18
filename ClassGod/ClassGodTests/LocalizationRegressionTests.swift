import Foundation
import Testing
@testable import ClassGod

@Suite("Localization regressions")
struct LocalizationRegressionTests {
    @Test("Context-specific import and navigation labels are correct in English")
    func validatesEnglishActionLabels() {
        let locale = Locale(identifier: "en")

        #expect(String(localized: "wallpaper.import", bundle: .main, locale: locale) == "Import Wallpaper…")
        #expect(String(localized: "destintab.import_tabs", bundle: .main, locale: locale) == "Import Tabs…")
        #expect(String(localized: "destintab.export_tabs", bundle: .main, locale: locale) == "Export Tabs…")
        #expect(String(localized: "button.back", bundle: .main, locale: locale) == "Back")
        #expect(String(localized: "button.cancel", bundle: .main, locale: locale) == "Cancel")
        #expect(ImportFeedback.failure(detail: "No permission", locale: locale) == "Import failed: No permission")
    }

    @Test("English is the app development language and every supported locale is bundled")
    func validatesBundleLanguageConfiguration() {
        #expect(Bundle.main.developmentLocalization == "en")
        #expect(Set(Bundle.main.localizations).isSuperset(of: [
            "en", "zh-Hans", "zh-Hant", "de", "es", "fr", "ja", "ko", "pt", "ru",
        ]))
    }

    @Test("Wallpaper controls and widget states are localized")
    func validatesMediaAndWidgetLabels() throws {
        let english = Locale(identifier: "en")
        let chineseURL = try #require(Bundle.main.url(forResource: "zh-Hans", withExtension: "lproj"))
        let chinese = try #require(Bundle(url: chineseURL))

        #expect(String(localized: "wallpaper.mute", bundle: .main, locale: english) == "Mute Wallpaper Audio")
        #expect(String(localized: "wallpaper.play", bundle: .main, locale: english) == "Play Wallpaper")
        #expect(chinese.localizedString(forKey: "widget.charging", value: nil, table: nil) == "充电中")
        #expect(chinese.localizedString(forKey: "widget.no_process_data", value: nil, table: nil) == "暂无进程数据")
    }

    @Test("Clipo timing values use localized units")
    func validatesClipoTimingFormat() throws {
        let english = Locale(identifier: "en")
        let chineseURL = try #require(Bundle.main.url(forResource: "zh-Hans", withExtension: "lproj"))
        let chinese = try #require(Bundle(url: chineseURL))

        #expect(String(localized: "clipo.seconds_format", bundle: .main, locale: english) == "%.2fs")
        #expect(chinese.localizedString(forKey: "clipo.seconds_format", value: nil, table: nil) == "%.2f 秒")
    }

    @Test("Permission gate and uninstall warnings are localized")
    func validatesPermissionGateAndUninstallLabels() throws {
        let english = Locale(identifier: "en")
        let chineseURL = try #require(Bundle.main.url(forResource: "zh-Hans", withExtension: "lproj"))
        let chinese = try #require(Bundle(url: chineseURL))

        #expect(String(localized: "permission.gate.title", bundle: .main, locale: english) == "Permission Setup")
        #expect(String(localized: "permission.limited", bundle: .main, locale: english) == "Limited Access")
        #expect(String(localized: "permission.privacy.title", bundle: .main, locale: english) == "Local Privacy Promise")
        #expect(String(localized: "uninstall.final.action", bundle: .main, locale: english) == "Uninstall Now")
        #expect(String(localized: "uninstall.cleanup.permissions", bundle: .main, locale: english) == "Reset all ClassGod privacy permissions")
        #expect(chinese.localizedString(forKey: "permission.gate.requirement", value: nil, table: nil) == "可选权限已置于最底部，可随时补充")
        #expect(chinese.localizedString(forKey: "permission.privacy.detail", value: nil, table: nil).contains("不会上传"))
        #expect(chinese.localizedString(forKey: "permission.gate.skip", value: nil, table: nil) == "暂时跳过并使用")
        #expect(chinese.localizedString(forKey: "permission.live_status", value: nil, table: nil) == "实时 · 100ms")
        #expect(chinese.localizedString(forKey: "uninstall.final.title", value: nil, table: nil) == "再次确认，确定要彻底卸载？")
        #expect(chinese.localizedString(forKey: "uninstall.cleanup.data", value: nil, table: nil) == "删除偏好、缓存、历史记录、壁纸与 Widget 数据")
    }

    @Test("Clipo import and todo accessibility messages are localized")
    func validatesNewSafetyAndAccessibilityLabels() throws {
        let english = Locale(identifier: "en")
        let chineseURL = try #require(Bundle.main.url(forResource: "zh-Hans", withExtension: "lproj"))
        let chinese = try #require(Bundle(url: chineseURL))

        #expect(String(localized: "clipo.import_invalid", bundle: .main, locale: english) == "The imported file contains an unsupported clipboard payload.")
        #expect(chinese.localizedString(forKey: "hackerdesktop.mark_done", value: nil, table: nil) == "标记为已完成")
        #expect(chinese.localizedString(forKey: "hackerdesktop.mark_pending", value: nil, table: nil) == "标记为待办")
    }

    @Test("Toast navigation and selection counts are localized")
    func validatesToastAndSelectionLabels() throws {
        let english = Locale(identifier: "en")
        let chineseURL = try #require(Bundle.main.url(forResource: "zh-Hans", withExtension: "lproj"))
        let chinese = try #require(Bundle(url: chineseURL))

        #expect(String(localized: "error.toast.open_encyclopedia", bundle: .main, locale: english) == "Open in Encyclopedia →")
        #expect(chinese.localizedString(forKey: "error.toast.open_encyclopedia", value: nil, table: nil) == "在错误百科中打开 →")
        #expect(chinese.localizedString(forKey: "error.open_in_encyclopedia", value: nil, table: nil) == "在百科中打开")
        #expect(String(format: chinese.localizedString(forKey: "destintab.selected_count", value: nil, table: nil), 3) == "已选择 3 项")
    }

    @Test("DestinTab and panic controls have English accessibility labels")
    func validatesEnglishAccessibilityLabels() {
        let english = Locale(identifier: "en")

        #expect(String(localized: "destintab.bulk_select", bundle: .main, locale: english) == "Select Multiple")
        #expect(String(localized: "destintab.exit_bulk_mode", bundle: .main, locale: english) == "Exit Multi-Select")
        #expect(String(localized: "destintab.all", bundle: .main, locale: english) == "All")
        #expect(String(localized: "panic.enabled", bundle: .main, locale: english) == "Enabled")
        #expect(String(localized: "panic.execute", bundle: .main, locale: english) == "Run")
        #expect(String(localized: "panic.execute_help", bundle: .main, locale: english) == "Run %@")
        #expect(String(localized: "panic.detected", bundle: .main, locale: english) == "Proctoring App Detected")
        #expect(String(localized: "panic.lockdown_browser_window", bundle: .main, locale: english) == "Lockdown Browser (Browser Window)")
        #expect(String(localized: "panic.error.accessibility_required", bundle: .main, locale: english).hasPrefix("Accessibility permission"))
    }

    @Test("Temperature notifications are localized")
    func validatesTemperatureNotificationLabels() throws {
        let english = Locale(identifier: "en")
        let chineseURL = try #require(Bundle.main.url(forResource: "zh-Hans", withExtension: "lproj"))
        let chinese = try #require(Bundle(url: chineseURL))

        #expect(String(localized: "fan.notification.high_temperature.title", bundle: .main, locale: english) == "ClassGod - High Temperature")
        #expect(chinese.localizedString(forKey: "fan.notification.high_temperature.title", value: nil, table: nil) == "ClassGod - 温度过高")
        #expect(String(format: String(localized: "fan.notification.high_temperature.body", bundle: .main, locale: english), "90°C", "85°C") == "Highest temperature reached 90°C (threshold: 85°C)")
    }

    @Test("Update settings are localized")
    func validatesUpdateLabels() throws {
        let english = Locale(identifier: "en")
        let chineseURL = try #require(Bundle.main.url(forResource: "zh-Hans", withExtension: "lproj"))
        let chinese = try #require(Bundle(url: chineseURL))

        #expect(String(localized: "tab.updates", bundle: .main, locale: english) == "Updates")
        #expect(String(localized: "update.status.current", bundle: .main, locale: english) == "ClassGod is up to date")
        #expect(String(localized: "update.download_install", bundle: .main, locale: english) == "Download and Install")
        #expect(chinese.localizedString(forKey: "update.title", value: nil, table: nil) == "软件更新")
        #expect(chinese.localizedString(forKey: "update.status.installer_opened", value: nil, table: nil) == "安装器已打开")
        #expect(chinese.localizedString(forKey: "update.security_notice", value: nil, table: nil).contains("管理员授权"))
    }

    @Test("Settings never expose localization keys in English")
    func validatesSettingsLabels() {
        let english = Locale(identifier: "en")
        let expectations = [
            "section.toast": "Toast Notifications",
            "section.window_behavior": "Window Behavior",
            "switch.always_new_tab": "Always open in new tab",
            "maximize.none": "Disabled",
            "maximize.fill_screen": "Fill Available Screen",
            "maximize.fullscreen_borderless": "Borderless Full Screen",
            "divider.none": "None",
            "divider.thin": "Thin",
            "divider.dashed": "Dashed",
            "lang.system": "Follow System",
        ]

        for (key, expected) in expectations {
            #expect(String(localized: String.LocalizationValue(key), bundle: .main, locale: english) == expected)
        }

        let englishOnlyKeys = [
            "app_icon.calculator", "app_icon.hidden", "app_icon.notes", "app_icon.terminal",
            "automation.subtitle", "button.add_rule", "button.open_console.subtitle",
            "rule.any_matched", "rule.comparison.above", "rule.comparison.below", "rule.hold",
            "rule.hysteresis", "rule.sensor.any_sensor", "rule.sensor.average_cpu",
            "rule.sensor.highest_cpu", "rule.sensor.highest_gpu", "rule.sensor_missing",
            "rule.target.all_fans", "rule.target.left_side", "rule.target.right_side", "rule.to",
            "rule.when", "section.auto_max_rules", "section.auto_max_rules.caption",
            "section.chaos_animation", "section.fan_general", "section.fan_mode",
            "section.notifications", "section.stealth", "section.temperature",
            "setting.alert_threshold", "setting.app_icon", "setting.app_icon.caption",
            "setting.auto_detect.subtitle", "setting.close_on_click_outside",
            "setting.close_on_click_outside.subtitle", "setting.compact_mode.subtitle",
            "setting.confirm_clear.subtitle", "setting.confirm_delete.subtitle",
            "setting.default_fan_mode", "setting.disable_on_sleep", "setting.disable_on_sleep.note",
            "setting.disable_on_sleep.subtitle", "setting.enable_fan_control",
            "setting.enable_fan_control.subtitle", "setting.enable_temp_alerts",
            "setting.enable_temp_alerts.subtitle", "setting.gradual_time", "setting.haptic.subtitle",
            "setting.instant_mode.subtitle", "setting.keep_on_top", "setting.keep_on_top.subtitle",
            "setting.keyboard_nav.subtitle", "setting.maximize_behavior", "setting.minimize_animation",
            "setting.popover_animation", "setting.popover_animation.subtitle",
            "setting.remember_position", "setting.remember_position.subtitle",
            "setting.show_browser_icon.subtitle", "setting.show_fan_in_menu_bar",
            "setting.show_fan_in_menu_bar.subtitle", "setting.show_shortcut_badge.subtitle",
            "setting.show_tab_count.subtitle", "setting.show_url_preview.subtitle",
            "setting.sound_effects.subtitle", "setting.temp_alert_limit", "setting.temperature_unit",
            "setting.toast.subtitle", "setting.update_interval", "setting.window_opacity",
            "setting.window_zoom",
        ]
        for key in englishOnlyKeys {
            let value = String(localized: String.LocalizationValue(key), bundle: .main, locale: english)
            #expect(value.range(of: "\\p{Han}", options: .regularExpression) == nil)
        }
    }

}
