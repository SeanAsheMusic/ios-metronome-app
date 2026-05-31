import XCTest
@testable import AudioEngine
@testable import RhythmModel

final class AudioEngineTests: XCTestCase {
    func testBeatIntervalUsesTempo() throws {
        let scheduler = MetronomeScheduler()

        XCTAssertEqual(try scheduler.beatIntervalNanoseconds(for: 60), 1_000_000_000)
        XCTAssertEqual(try scheduler.beatIntervalNanoseconds(for: 120), 500_000_000)
        XCTAssertEqual(try scheduler.beatIntervalNanoseconds(for: 240), 250_000_000)
    }

    func testBeatIntervalRejectsInvalidTempo() {
        let scheduler = MetronomeScheduler()

        XCTAssertThrowsError(try scheduler.beatIntervalNanoseconds(for: 29))
        XCTAssertThrowsError(try scheduler.beatIntervalNanoseconds(for: 301))
    }

    func testAudioSettingsClampValues() {
        let settings = MetronomeAudioSettings(masterGain: 2.0, accentBoost: 0.1)

        XCTAssertEqual(settings.masterGain, 1.0)
        XCTAssertEqual(settings.accentBoost, 0.5)
    }

    func testClickSoundPresetDisplayNames() {
        XCTAssertEqual(ClickSoundPreset.classic.displayName, "Classic")
        XCTAssertEqual(ClickSoundPreset.wood.displayName, "Wood")
        XCTAssertEqual(ClickSoundPreset.bell.displayName, "Bell")
        XCTAssertEqual(ClickSoundPreset.mechanical.displayName, "Mechanical")
    }

    func testAudioRouteStatusWarnsForBluetooth() {
        let status = AudioRouteStatus.status(for: [
            AudioRouteOutput(portType: "BluetoothA2DPOutput", name: "AirPods")
        ])

        XCTAssertEqual(status.outputName, "AirPods")
        XCTAssertEqual(status.latencyRisk, .elevated)
        XCTAssertEqual(status.message, "Wireless routes can feel late for stage timing.")
    }

    func testAudioRouteStatusTreatsBuiltInSpeakerAsLowRisk() {
        let status = AudioRouteStatus.status(for: [
            AudioRouteOutput(portType: "Speaker", name: "iPhone Speaker")
        ])

        XCTAssertEqual(status.outputName, "iPhone Speaker")
        XCTAssertEqual(status.latencyRisk, .low)
        XCTAssertEqual(status.message, "Wired or built-in output is best for timing.")
    }

    func testAudioRouteStatusHandlesUnknownOutput() {
        let status = AudioRouteStatus.status(for: [])

        XCTAssertEqual(status.outputName, "Unknown output")
        XCTAssertEqual(status.latencyRisk, .unknown)
        XCTAssertEqual(status.message, "Audio output is unavailable.")
    }

    func testScheduleWrapsPatternBeats() throws {
        let pattern = Pattern.defaultSevenEight(id: UUID(uuidString: "A87F4C4B-806A-4B6C-B371-7F0D1C1D7D7F")!)
        let scheduler = MetronomeScheduler()

        let schedule = try scheduler.schedule(pattern: pattern, startingAt: 1_000, beatCount: 9)

        XCTAssertEqual(schedule.events.map(\.beatIndex), [0, 1, 2, 3, 4, 5, 6, 0, 1])
        XCTAssertEqual(schedule.events[0].accent, .strong)
        XCTAssertEqual(schedule.events[2].accent, .normal)
        XCTAssertEqual(schedule.events[4].accent, .normal)
        XCTAssertEqual(schedule.events[7].hostTimeNanoseconds, 1_000 + (7 * 545_454_545))
    }

    func testStubPublishesInitialBeatEvent() async throws {
        let pattern = Pattern.defaultFourFour()
        let engine = AudioEngineStub()
        let recorder = BeatEventRecorder()

        await engine.setEventHandler { event in
            await recorder.record(event)
        }

        try await engine.prepare(pattern: pattern)
        try await engine.start()

        let event = await recorder.firstEvent()
        XCTAssertEqual(event?.patternID, pattern.id)
        XCTAssertEqual(event?.beatIndex, 0)
        XCTAssertEqual(event?.accent, .strong)
    }
}

private actor BeatEventRecorder {
    private var events: [ScheduledBeatEvent] = []

    func record(_ event: ScheduledBeatEvent) {
        events.append(event)
    }

    func firstEvent() -> ScheduledBeatEvent? {
        events.first
    }
}
