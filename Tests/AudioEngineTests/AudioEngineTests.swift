import Foundation
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

    func testGroovePatternUsesSixteenthStepInterval() throws {
        let scheduler = MetronomeScheduler()
        let pattern = Pattern.groove(.sonClave32)

        XCTAssertEqual(try scheduler.eventIntervalNanoseconds(for: pattern), 156_250_000)
    }

    func testBeatIntervalRejectsInvalidTempo() {
        let scheduler = MetronomeScheduler()

        XCTAssertThrowsError(try scheduler.beatIntervalNanoseconds(for: 29))
        XCTAssertThrowsError(try scheduler.beatIntervalNanoseconds(for: 301))
    }

    func testAudioSettingsClampValues() {
        let settings = MetronomeAudioSettings(
            masterGain: 2.0,
            accentBoost: 0.1,
            downbeatGain: 2.0,
            beatGain: -1.0,
            subdivisionGain: 1.4,
            cueGain: -0.2,
            humanizationAmount: 2.0
        )

        XCTAssertEqual(settings.masterGain, 1.0)
        XCTAssertEqual(settings.accentBoost, 0.5)
        XCTAssertEqual(settings.downbeatGain, 1.0)
        XCTAssertEqual(settings.beatGain, 0.0)
        XCTAssertEqual(settings.subdivisionGain, 1.0)
        XCTAssertEqual(settings.cueGain, 0.0)
        XCTAssertEqual(settings.humanizationAmount, 1.0)
        XCTAssertEqual(settings.humanizationWarning, "High human feel intentionally makes the click inaccurate.")
    }

    func testAudioSettingsDecodeOlderPayloadDefaultsNewFields() throws {
        let data = Data("""
        {"soundPreset":"wood","masterGain":0.5,"accentBoost":1.1}
        """.utf8)

        let settings = try JSONDecoder().decode(MetronomeAudioSettings.self, from: data)

        XCTAssertEqual(settings.soundPreset, .wood)
        XCTAssertEqual(settings.masterGain, 0.5)
        XCTAssertEqual(settings.accentBoost, 1.1)
        XCTAssertEqual(settings.downbeatGain, 1.0)
        XCTAssertEqual(settings.beatGain, 1.0)
        XCTAssertEqual(settings.subdivisionGain, 1.0)
        XCTAssertEqual(settings.cueGain, 1.0)
        XCTAssertEqual(settings.humanizationAmount, 0.0)
        XCTAssertEqual(settings.rhythmTrainer, RhythmTrainerSettings())
    }

    func testAudioSettingsEncodeRoleMixerLevels() throws {
        let settings = MetronomeAudioSettings(
            downbeatGain: 0.9,
            beatGain: 0.7,
            subdivisionGain: 0.4,
            cueGain: 0.6
        )

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(MetronomeAudioSettings.self, from: data)

        XCTAssertEqual(decoded.downbeatGain, 0.9)
        XCTAssertEqual(decoded.beatGain, 0.7)
        XCTAssertEqual(decoded.subdivisionGain, 0.4)
        XCTAssertEqual(decoded.cueGain, 0.6)
    }

    func testAudioSettingsResetRoleMixerKeepsOtherSettings() {
        var settings = MetronomeAudioSettings(
            soundPreset: .bell,
            masterGain: 0.5,
            accentBoost: 1.2,
            downbeatGain: 0.2,
            beatGain: 0.3,
            subdivisionGain: 0.4,
            cueGain: 0.5,
            humanizationAmount: 0.75,
            rhythmTrainer: RhythmTrainerSettings(mode: .fixedBars, audibleBars: 1, silentBars: 2)
        )

        settings.resetRoleMixer()

        XCTAssertEqual(settings.soundPreset, .bell)
        XCTAssertEqual(settings.masterGain, 0.5)
        XCTAssertEqual(settings.accentBoost, 1.2)
        XCTAssertEqual(settings.downbeatGain, 1.0)
        XCTAssertEqual(settings.beatGain, 1.0)
        XCTAssertEqual(settings.subdivisionGain, 1.0)
        XCTAssertEqual(settings.cueGain, 1.0)
        XCTAssertEqual(settings.humanizationAmount, 0.75)
        XCTAssertEqual(settings.rhythmTrainer.mode, .fixedBars)
    }

    func testAudioSettingsPrecisionPracticeModeDisablesTimingAlterations() {
        var settings = MetronomeAudioSettings(
            soundPreset: .wood,
            downbeatGain: 0.6,
            beatGain: 0.7,
            subdivisionGain: 0.8,
            cueGain: 0.9,
            humanizationAmount: 0.95,
            rhythmTrainer: RhythmTrainerSettings(mode: .randomBars, randomSilenceProbability: 0.8)
        )

        settings.setPrecisionPracticeMode()

        XCTAssertEqual(settings.soundPreset, .wood)
        XCTAssertEqual(settings.downbeatGain, 0.6)
        XCTAssertEqual(settings.beatGain, 0.7)
        XCTAssertEqual(settings.subdivisionGain, 0.8)
        XCTAssertEqual(settings.cueGain, 0.9)
        XCTAssertEqual(settings.humanizationAmount, 0.0)
        XCTAssertEqual(settings.rhythmTrainer.mode, .off)
    }

    func testRhythmTrainerFixedBarsMutesSilentCycle() {
        let settings = RhythmTrainerSettings(mode: .fixedBars, audibleBars: 2, silentBars: 1)
        let patternID = UUID(uuidString: "34A78AE2-EDFC-445B-8E44-4C63C1E347A8")!

        XCTAssertEqual(settings.soundRole(for: .beat, patternID: patternID, barIndex: 0), .beat)
        XCTAssertEqual(settings.soundRole(for: .beat, patternID: patternID, barIndex: 1), .beat)
        XCTAssertEqual(settings.soundRole(for: .beat, patternID: patternID, barIndex: 2), .muted)
    }

    func testRhythmTrainerRandomBarsCanMuteAllOrNone() {
        let patternID = UUID(uuidString: "34A78AE2-EDFC-445B-8E44-4C63C1E347A8")!
        let allSilent = RhythmTrainerSettings(mode: .randomBars, randomSilenceProbability: 1.0)
        let noneSilent = RhythmTrainerSettings(mode: .randomBars, randomSilenceProbability: 0.0)

        XCTAssertEqual(allSilent.soundRole(for: .beat, patternID: patternID, barIndex: 0), .muted)
        XCTAssertEqual(noneSilent.soundRole(for: .beat, patternID: patternID, barIndex: 0), .beat)
    }

    func testClickSoundPresetDisplayNames() {
        XCTAssertEqual(ClickSoundPreset.classic.displayName, "Classic")
        XCTAssertEqual(ClickSoundPreset.wood.displayName, "Wood")
        XCTAssertEqual(ClickSoundPreset.bell.displayName, "Bell")
        XCTAssertEqual(ClickSoundPreset.mechanical.displayName, "Mechanical")
    }

    func testAudioTimingSummaryCalculatesOffsetAndJitter() {
        let samples = [
            AudioTimingSample(scheduledHostTimeNanoseconds: 1_000, observedHostTimeNanoseconds: 1_100),
            AudioTimingSample(scheduledHostTimeNanoseconds: 2_000, observedHostTimeNanoseconds: 2_250),
            AudioTimingSample(scheduledHostTimeNanoseconds: 3_000, observedHostTimeNanoseconds: 3_050)
        ]

        let summary = AudioTimingSummary(samples: samples)

        XCTAssertEqual(summary.sampleCount, 3)
        XCTAssertEqual(summary.minimumOffsetNanoseconds, 50)
        XCTAssertEqual(summary.maximumOffsetNanoseconds, 250)
        XCTAssertEqual(summary.averageOffsetNanoseconds, 133)
        XCTAssertEqual(summary.peakToPeakJitterNanoseconds, 200)
    }

    func testAudioTimingRecorderPrunesOldSamples() async {
        let recorder = AudioTimingRecorder(sampleLimit: 2)

        await recorder.record(scheduledHostTimeNanoseconds: 1_000, observedHostTimeNanoseconds: 1_100)
        await recorder.record(scheduledHostTimeNanoseconds: 2_000, observedHostTimeNanoseconds: 2_100)
        await recorder.record(scheduledHostTimeNanoseconds: 3_000, observedHostTimeNanoseconds: 3_300)

        let summary = await recorder.summary()
        XCTAssertEqual(summary.sampleCount, 2)
        XCTAssertEqual(summary.maximumOffsetNanoseconds, 300)
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

    func testScheduleIncludesMutedGrooveSteps() throws {
        let pattern = Pattern.groove(.sonClave32, id: UUID(uuidString: "3D7041AE-7309-4289-94C4-FA10B53E5D00")!)
        let scheduler = MetronomeScheduler()

        let schedule = try scheduler.schedule(pattern: pattern, startingAt: 1_000, beatCount: 5)

        XCTAssertEqual(schedule.events.map(\.beatIndex), [0, 1, 2, 3, 4])
        XCTAssertEqual(schedule.events.map(\.soundRole), [.downbeat, .muted, .muted, .beat, .muted])
        XCTAssertEqual(schedule.events[4].hostTimeNanoseconds, 1_000 + (4 * 156_250_000))
    }

    func testScheduleSupportsMixedPerBeatSubdivisions() throws {
        let scheduler = MetronomeScheduler()
        let pattern = Pattern.mixedSubdivision(
            bpm: 60,
            subdivisions: [.sixteenth, .quintuplet, .triplet, .eighth],
            id: UUID(uuidString: "B2193D8E-C2B6-4F2F-AB8E-8BE0DC1528D7")!
        )

        let schedule = try scheduler.schedule(pattern: pattern, startingAt: 1_000, beatCount: 7)

        XCTAssertEqual(schedule.events.map(\.beatIndex), [0, 1, 2, 3, 4, 5, 6])
        XCTAssertEqual(schedule.events.map(\.hostTimeNanoseconds), [1_000, 250_001_000, 500_001_000, 750_001_000, 1_000_001_000, 1_200_001_000, 1_400_001_000])
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

    func testStubPublishesOneShotCueEvent() async throws {
        let pattern = Pattern.defaultFourFour()
        let engine = AudioEngineStub()
        let recorder = BeatEventRecorder()

        await engine.setEventHandler { event in
            await recorder.record(event)
        }

        try await engine.playOneShot(pattern: pattern, soundRole: .cue)

        let event = await recorder.firstEvent()
        XCTAssertEqual(event?.patternID, pattern.id)
        XCTAssertEqual(event?.soundRole, .cue)
        XCTAssertEqual(event?.accent, .normal)
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
