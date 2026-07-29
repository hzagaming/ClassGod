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

    @Test("Clipo import and todo accessibility messages are localized")
    func validatesNewSafetyAndAccessibilityLabels() throws {
        let english = Locale(identifier: "en")
        let chineseURL = try #require(Bundle.main.url(forResource: "zh-Hans", withExtension: "lproj"))
        let chinese = try #require(Bundle(url: chineseURL))

        #expect(String(localized: "clipo.import_invalid", bundle: .main, locale: english) == "The imported file contains an unsupported clipboard payload.")
        #expect(chinese.localizedString(forKey: "hackerdesktop.mark_done", value: nil, table: nil) == "标记为已完成")
        #expect(chinese.localizedString(forKey: "hackerdesktop.mark_pending", value: nil, table: nil) == "标记为待办")
    }

}
