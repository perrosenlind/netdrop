import XCTest
@testable import NetDrop

final class AppSettingsTests: XCTestCase {

    func testDefaultAppearanceIsSystem() {
        UserDefaults.standard.removeObject(forKey: "appearanceMode")
        let settings = AppSettings()
        XCTAssertEqual(settings.appearanceMode, .system)
        XCTAssertNil(settings.preferredColorScheme)
    }

    func testLightModeReturnsLightScheme() {
        let settings = AppSettings()
        settings.appearanceMode = .light
        XCTAssertNotNil(settings.preferredColorScheme)
    }

    func testDarkModeReturnsDarkScheme() {
        let settings = AppSettings()
        settings.appearanceMode = .dark
        XCTAssertNotNil(settings.preferredColorScheme)
    }

    func testSystemModeReturnsNilScheme() {
        let settings = AppSettings()
        settings.appearanceMode = .system
        XCTAssertNil(settings.preferredColorScheme)
    }

    func testAppearanceModePersists() {
        let settings = AppSettings()
        settings.appearanceMode = .dark

        let raw = UserDefaults.standard.string(forKey: "appearanceMode")
        XCTAssertEqual(raw, "dark")

        // Cleanup
        settings.appearanceMode = .system
    }
}
