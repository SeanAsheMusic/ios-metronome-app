import XCTest

final class MetronomeLaunchUITests: XCTestCase {
    func testLaunchShowsPlaySurface() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Pattern Default 4/4"].waitForExistence(timeout: 8), "The main pattern header should be visible after launch.")
        XCTAssertTrue(app.staticTexts["120 beats per minute"].exists, "The default tempo readout should be visible after launch.")
        XCTAssertTrue(app.descendants(matching: .any)["tempo-marking"].exists, "The tempo marking should be visible under the BPM readout.")
        XCTAssertTrue(app.buttons["Play metronome"].exists, "The primary transport control should be visible after launch.")
        XCTAssertTrue(app.buttons["Tap tempo"].exists, "The secondary tap-tempo tool should be available without competing with Play.")

        let beatVisualizer = app.descendants(matching: .any)["Beat visualizer"]
        XCTAssertTrue(beatVisualizer.exists, "The beat visualizer should be present beside the BPM readout.")
        XCTAssertEqual(beatVisualizer.value as? String, "Stopped", "The beat visualizer should start in the stopped state.")

        XCTAssertTrue(app.buttons["Decrease tempo by 5"].exists)
        XCTAssertTrue(app.buttons["Decrease tempo by 1"].exists)
        XCTAssertTrue(app.buttons["Increase tempo by 1"].exists)
        XCTAssertTrue(app.buttons["Increase tempo by 5"].exists)

        XCTAssertTrue(app.buttons["Decrease count-in"].exists)
        XCTAssertFalse(app.buttons["Decrease count-in"].isEnabled, "Count-in cannot go below Off.")
        XCTAssertTrue(app.buttons["Increase count-in"].isEnabled)

        XCTAssertTrue(app.descendants(matching: .any)["Practice timer 10:00"].exists, "The flattened practice timer should be visible on the main surface.")
        XCTAssertTrue(app.buttons["Start practice timer"].exists)
        XCTAssertTrue(app.buttons["Reset practice timer"].exists)
        XCTAssertTrue(app.buttons["Start tempo ladder"].exists, "Tempo Ladder should use the app accent treatment, not a separate blue action.")
    }
}
