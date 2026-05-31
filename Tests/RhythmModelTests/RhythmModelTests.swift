import XCTest
@testable import RhythmModel

final class RhythmModelTests: XCTestCase {
    func testBPMValidationAcceptsBounds() throws {
        XCTAssertNoThrow(try Pattern.validateBPM(30))
        XCTAssertNoThrow(try Pattern.validateBPM(300))
    }

    func testBPMValidationRejectsOutOfRangeValues() {
        XCTAssertThrowsError(try Pattern.validateBPM(29))
        XCTAssertThrowsError(try Pattern.validateBPM(301))
    }

    func testMeterValidationAcceptsCommonMeters() throws {
        let meters = [
            (2, 4), (3, 4), (4, 4), (5, 4),
            (6, 8), (7, 8), (9, 8), (12, 8)
        ]

        for meter in meters {
            XCTAssertNoThrow(try Meter(beatsPerBar: meter.0, beatUnit: meter.1))
        }
    }

    func testMeterValidationRejectsUnsupportedMeters() {
        XCTAssertThrowsError(try Meter(beatsPerBar: 11, beatUnit: 16))
    }

    func testMeterGroupingMustAddUpToBeatCount() {
        XCTAssertThrowsError(try Meter(beatsPerBar: 7, beatUnit: 8, grouping: [2, 2, 2]))
    }

    func testSubdivisionStepCounts() {
        XCTAssertEqual(Subdivision.quarter.stepsPerBeat, 1)
        XCTAssertEqual(Subdivision.eighth.stepsPerBeat, 2)
        XCTAssertEqual(Subdivision.triplet.stepsPerBeat, 3)
        XCTAssertEqual(Subdivision.sixteenth.stepsPerBeat, 4)
    }

    func testDefaultFourFourPattern() {
        let pattern = Pattern.defaultFourFour()

        XCTAssertEqual(pattern.name, "Default 4/4")
        XCTAssertEqual(pattern.bpm, 120)
        XCTAssertEqual(pattern.meter.displayName, "4/4")
        XCTAssertEqual(pattern.subdivision, .quarter)
        XCTAssertEqual(pattern.beats.count, 4)
        XCTAssertEqual(pattern.beats[0].accent, .strong)
    }

    func testDefaultSixEightPatternUsesCompoundGrouping() {
        let pattern = Pattern.defaultSixEight()

        XCTAssertEqual(pattern.meter.grouping, [3, 3])
        XCTAssertEqual(pattern.beats.count, 6)
        XCTAssertEqual(pattern.beats[0].accent, .strong)
        XCTAssertEqual(pattern.beats[3].accent, .normal)
    }

    func testDefaultSevenEightPatternUsesTwoTwoThreeGrouping() {
        let pattern = Pattern.defaultSevenEight()

        XCTAssertEqual(pattern.meter.grouping, [2, 2, 3])
        XCTAssertEqual(pattern.beats.count, 7)
        XCTAssertEqual(pattern.beats[0].accent, .strong)
        XCTAssertEqual(pattern.beats[2].accent, .normal)
        XCTAssertEqual(pattern.beats[4].accent, .normal)
    }

    func testGrooveTemplateCreatesSixteenthStepPattern() {
        let pattern = Pattern.groove(.sonClave32)

        XCTAssertEqual(pattern.name, "Son Clave 3:2")
        XCTAssertEqual(pattern.bpm, 96)
        XCTAssertEqual(pattern.meter, .fourFour)
        XCTAssertEqual(pattern.subdivision, .sixteenth)
        XCTAssertEqual(pattern.beats.count, 16)
        XCTAssertEqual(pattern.grooveTemplate, .sonClave32)
        XCTAssertEqual(pattern.eventIntervalDivisor, 4)
        XCTAssertEqual(
            pattern.beats.filter { $0.soundRole != .muted }.map(\.index),
            [0, 3, 6, 10, 12]
        )
    }

    func testPatternEditingClearsGrooveTemplateMarker() {
        var pattern = Pattern.groove(.bossaClave)

        pattern.updateMeter(.sevenEight)

        XCTAssertNil(pattern.grooveTemplate)
        XCTAssertEqual(pattern.beats.count, 7)
    }

    func testPatternRenameTrimsName() {
        var pattern = Pattern.defaultFourFour()

        pattern.rename(to: "  Verse  ")

        XCTAssertEqual(pattern.name, "Verse")
    }

    func testPatternRenameIgnoresEmptyName() {
        var pattern = Pattern.defaultFourFour()

        pattern.rename(to: "   ")

        XCTAssertEqual(pattern.name, "Default 4/4")
    }

    func testPatternMeterUpdateRegeneratesBeats() {
        var pattern = Pattern.defaultFourFour()

        pattern.updateMeter(.sevenEight)

        XCTAssertEqual(pattern.meter, .sevenEight)
        XCTAssertEqual(pattern.beats.count, 7)
        XCTAssertEqual(pattern.beats[2].accent, .normal)
        XCTAssertEqual(pattern.beats[4].accent, .normal)
    }

    func testPatternSubdivisionUpdate() {
        var pattern = Pattern.defaultFourFour()

        pattern.updateSubdivision(.sixteenth)

        XCTAssertEqual(pattern.subdivision, .sixteenth)
    }

    func testPatternCyclesAccentAndSoundRole() throws {
        var pattern = Pattern.defaultFourFour()

        try pattern.cycleAccent(at: 0)
        XCTAssertEqual(pattern.beats[0].accent, .normal)
        XCTAssertEqual(pattern.beats[0].soundRole, .beat)

        try pattern.cycleAccent(at: 0)
        XCTAssertEqual(pattern.beats[0].accent, .ghost)
        XCTAssertEqual(pattern.beats[0].soundRole, .subdivision)

        try pattern.cycleAccent(at: 0)
        XCTAssertEqual(pattern.beats[0].accent, .muted)
        XCTAssertEqual(pattern.beats[0].soundRole, .muted)

        try pattern.cycleAccent(at: 0)
        XCTAssertEqual(pattern.beats[0].accent, .strong)
        XCTAssertEqual(pattern.beats[0].soundRole, .downbeat)
    }

    func testPatternAccentRejectsInvalidIndex() {
        var pattern = Pattern.defaultFourFour()

        XCTAssertThrowsError(try pattern.cycleAccent(at: 99))
    }

    func testSetlistOrderingAndMove() throws {
        let first = Pattern.defaultFourFour()
        let second = Pattern.defaultSixEight()
        let third = Pattern.defaultSevenEight()
        var setlist = Setlist(name: "Gig")

        setlist.append(pattern: first)
        setlist.append(pattern: second)
        setlist.append(pattern: third)
        try setlist.move(from: 2, to: 0)

        XCTAssertEqual(setlist.items.map(\.patternID), [third.id, first.id, second.id])
        XCTAssertEqual(setlist.items.map(\.position), [0, 1, 2])
    }

    func testSetlistRemoveNormalizesPositions() throws {
        let first = Pattern.defaultFourFour()
        let second = Pattern.defaultSixEight()
        let third = Pattern.defaultSevenEight()
        var setlist = Setlist(name: "Gig")
        setlist.append(pattern: first)
        setlist.append(pattern: second)
        setlist.append(pattern: third)

        try setlist.removeItem(id: setlist.items[1].id)

        XCTAssertEqual(setlist.items.map(\.patternID), [first.id, third.id])
        XCTAssertEqual(setlist.items.map(\.position), [0, 1])
    }

    func testSetlistRemoveRejectsUnknownItem() {
        var setlist = Setlist(name: "Gig")
        setlist.append(pattern: Pattern.defaultFourFour())

        XCTAssertThrowsError(try setlist.removeItem(id: UUID()))
    }

    func testSetlistRemovePatternItemsNormalizesPositions() {
        let first = Pattern.defaultFourFour()
        let second = Pattern.defaultSixEight()
        var setlist = Setlist(name: "Gig")
        setlist.append(pattern: first)
        setlist.append(pattern: second)
        setlist.append(pattern: first)

        setlist.removeItems(for: first.id)

        XCTAssertEqual(setlist.items.map(\.patternID), [second.id])
        XCTAssertEqual(setlist.items.map(\.position), [0])
    }

    func testCodableRoundTrip() throws {
        let pattern = Pattern.defaultSevenEight()
        let data = try JSONEncoder().encode(pattern)
        let decoded = try JSONDecoder().decode(Pattern.self, from: data)

        XCTAssertEqual(decoded, pattern)
    }

    func testPracticeTimerFormatsRemainingTime() {
        let timer = PracticeTimer(durationSeconds: 600, remainingSeconds: 65)

        XCTAssertEqual(timer.formattedRemaining, "01:05")
    }

    func testPracticeTimerRunsDownAndStopsAtZero() {
        var timer = PracticeTimer(durationSeconds: 60, remainingSeconds: 2)

        timer.start()
        timer.tick()
        XCTAssertEqual(timer.remainingSeconds, 1)
        XCTAssertTrue(timer.isRunning)

        timer.tick()
        XCTAssertEqual(timer.remainingSeconds, 0)
        XCTAssertFalse(timer.isRunning)
    }

    func testPracticeTimerSelectDurationResetsAndPauses() {
        var timer = PracticeTimer(durationSeconds: 600, remainingSeconds: 120, isRunning: true)

        timer.selectDuration(seconds: 300)

        XCTAssertEqual(timer.durationSeconds, 300)
        XCTAssertEqual(timer.remainingSeconds, 300)
        XCTAssertFalse(timer.isRunning)
    }

    func testPracticeTimerClampsDuration() {
        let shortTimer = PracticeTimer(durationSeconds: 5)
        let longTimer = PracticeTimer(durationSeconds: 7_200)

        XCTAssertEqual(shortTimer.durationSeconds, PracticeTimer.minimumDurationSeconds)
        XCTAssertEqual(longTimer.durationSeconds, PracticeTimer.maximumDurationSeconds)
    }

    func testTempoLadderStepsAfterConfiguredBars() {
        var ladder = TempoLadder(targetBPM: 132, stepBPM: 4, barsPerStep: 2)

        ladder.setEnabled(true, currentBPM: 120)

        XCTAssertNil(ladder.recordCompletedBar(currentBPM: 120))
        XCTAssertEqual(ladder.recordCompletedBar(currentBPM: 120), 124)
    }

    func testTempoLadderDoesNotOvershootTarget() {
        var ladder = TempoLadder(targetBPM: 125, stepBPM: 10, barsPerStep: 1)

        ladder.setEnabled(true, currentBPM: 120)

        XCTAssertEqual(ladder.recordCompletedBar(currentBPM: 120), 125)
        XCTAssertFalse(ladder.isEnabled)
    }

    func testTempoLadderCanStepDown() {
        var ladder = TempoLadder(targetBPM: 100, stepBPM: 6, barsPerStep: 1)

        ladder.setEnabled(true, currentBPM: 112)

        XCTAssertEqual(ladder.recordCompletedBar(currentBPM: 112), 106)
    }

    func testTempoLadderClampsSettings() {
        let ladder = TempoLadder(targetBPM: 999, stepBPM: 99, barsPerStep: 99)

        XCTAssertEqual(ladder.targetBPM, Pattern.maximumBPM)
        XCTAssertEqual(ladder.stepBPM, TempoLadder.maximumStepBPM)
        XCTAssertEqual(ladder.barsPerStep, TempoLadder.maximumBarsPerStep)
    }
}
