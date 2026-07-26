import Foundation
import Testing

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
}
