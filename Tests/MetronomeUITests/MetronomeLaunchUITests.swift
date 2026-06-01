import XCTest

final class MetronomeLaunchUITests: XCTestCase {
    func testLaunchShowsPlaySurface() {
        let app = launchApp()

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

    func testBottomNavigationReachesEveryPrimarySurface() {
        let app = launchApp()

        XCTAssertTrue(app.buttons["Play tab"].waitForExistence(timeout: 8))
        XCTAssertEqual(app.buttons["Play tab"].value as? String, "Selected")

        app.buttons["Edit tab"].tap()
        XCTAssertTrue(app.textFields["Pattern name"].waitForExistence(timeout: 2), "Edit should expose pattern editing after selecting the Edit tab.")
        XCTAssertEqual(app.buttons["Edit tab"].value as? String, "Selected")

        app.buttons["Patterns tab"].tap()
        XCTAssertTrue(app.buttons["Duplicate current pattern"].waitForExistence(timeout: 2), "Patterns should expose library actions after selecting the Patterns tab.")
        XCTAssertEqual(app.buttons["Patterns tab"].value as? String, "Selected")

        app.buttons["Setlist tab"].tap()
        XCTAssertTrue(app.buttons["Add current pattern to setlist"].waitForExistence(timeout: 2), "Setlist should expose setlist actions after selecting the Setlist tab.")
        XCTAssertEqual(app.buttons["Setlist tab"].value as? String, "Selected")

        app.buttons["Settings tab"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["Click sound"].waitForExistence(timeout: 2), "Settings should expose click sound settings after selecting the Settings tab.")
        XCTAssertEqual(app.buttons["Settings tab"].value as? String, "Selected")

        app.buttons["Play tab"].tap()
        XCTAssertTrue(app.buttons["Play metronome"].waitForExistence(timeout: 2), "Play should remain reachable after visiting the other primary surfaces.")
        XCTAssertEqual(app.buttons["Play tab"].value as? String, "Selected")
    }

    func testStagePulseOpensAndClosesFromPlaySurface() {
        let app = launchApp()

        XCTAssertTrue(app.buttons["Play metronome"].waitForExistence(timeout: 8))
        scrollToElement(app.buttons["Open stage pulse"], in: app)

        app.buttons["Open stage pulse"].tap()
        XCTAssertTrue(app.buttons["Close stage pulse"].waitForExistence(timeout: 2), "Stage Pulse should open from the Play surface.")
        XCTAssertTrue(app.descendants(matching: .any)["Stage visual pulse"].exists, "Stage Pulse should expose the full-screen pulse element.")
        XCTAssertTrue(app.descendants(matching: .any)["Pattern Default 4/4, 120 beats per minute, meter 4/4"].exists, "Stage Pulse should expose the current pattern context.")

        app.buttons["Close stage pulse"].tap()
        XCTAssertTrue(app.buttons["Play metronome"].waitForExistence(timeout: 2), "Closing Stage Pulse should return to the Play surface.")
    }

    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication, attempts: Int = 5) {
        for _ in 0..<attempts where !element.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable, "Expected \(element) to become reachable after scrolling.")
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-PulsecraftUITestingInMemoryLibrary"]
        app.launch()
        return app
    }
}
