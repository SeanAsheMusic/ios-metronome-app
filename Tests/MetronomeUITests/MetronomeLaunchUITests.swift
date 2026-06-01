import XCTest

final class MetronomeLaunchUITests: XCTestCase {
    func testLaunchShowsPlaySurface() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Pattern Default 4/4"].waitForExistence(timeout: 8), "The main pattern header should be visible after launch.")
        XCTAssertTrue(app.staticTexts["120 beats per minute"].exists, "The default tempo readout should be visible after launch.")
        XCTAssertTrue(app.buttons["Play metronome"].exists, "The primary transport control should be visible after launch.")
    }
}
