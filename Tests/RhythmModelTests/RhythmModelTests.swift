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
            (5, 8), (6, 8), (7, 8), (9, 8), (11, 8), (12, 8)
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
        XCTAssertEqual(Subdivision.quintuplet.stepsPerBeat, 5)
        XCTAssertEqual(Subdivision.sixteenth.stepsPerBeat, 4)
        XCTAssertEqual(Subdivision.septuplet.stepsPerBeat, 7)
        XCTAssertEqual(Subdivision.eighth.stepsPerMeterBeat(beatUnit: 4), 2)
        XCTAssertEqual(Subdivision.eighth.stepsPerMeterBeat(beatUnit: 8), 1)
        XCTAssertEqual(Subdivision.sixteenth.stepsPerMeterBeat(beatUnit: 8), 2)
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
        XCTAssertEqual(pattern.subdivision, .eighth)
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

    func testClaveTemplatesCoverDirectionsAndFamilies() {
        let expectedSteps: [GrooveTemplate: [Int]] = [
            .sonClave32: [0, 3, 6, 10, 12],
            .sonClave23: [0, 2, 6, 9, 12],
            .rumbaClave32: [0, 3, 7, 10, 12],
            .rumbaClave23: [0, 2, 6, 9, 13],
            .bossaClave: [0, 3, 6, 10, 13],
            .bossaClave23: [0, 3, 7, 10, 13]
        ]

        XCTAssertEqual(GrooveTemplate.allCases.count, expectedSteps.count)
        for (template, steps) in expectedSteps {
            XCTAssertEqual(Pattern.groove(template).beats.filter { $0.soundRole != .muted }.map(\.index), steps)
        }
    }

    func testClaveModeTemplateCreatesClaveWithMetronomePattern() {
        let pattern = Pattern.claveMode(.sonClave32, mixerPreset: .claveWithMetronome)

        XCTAssertEqual(pattern.name, "Son 3:2 Clave + Click")
        XCTAssertEqual(pattern.meter, .fourFour)
        XCTAssertEqual(pattern.subdivision, .sixteenth)
        XCTAssertEqual(pattern.beats.count, 16)
        XCTAssertEqual(pattern.claveModeTemplate, .sonClave32)
        XCTAssertEqual(pattern.grooveMixerPreset, .claveWithMetronome)
        XCTAssertEqual(pattern.eventIntervalDivisor, 4)
        XCTAssertEqual(pattern.beats.filter { $0.soundRole != .muted }.map(\.index), [0, 3, 4, 6, 8, 10, 12])
    }

    func testClaveModeMixerCanRenderClaveOnly() {
        let pattern = Pattern.claveMode(.rumbaClave23, mixerPreset: .claveOnly)

        XCTAssertEqual(pattern.beats.filter { $0.soundRole != .muted }.map(\.index), [0, 2, 6, 9, 13])
    }

    func testClaveModeMixerCanRenderClickOnly() {
        let pattern = Pattern.claveMode(.sevenEightTwoTwoThree, mixerPreset: .metronomeOnly)

        XCTAssertEqual(pattern.meter.grouping, [2, 2, 3])
        XCTAssertEqual(pattern.beats.count, 14)
        XCTAssertEqual(pattern.beats.filter { $0.soundRole != .muted }.map(\.index), [0, 2, 4, 6, 8, 10, 12])
    }

    func testClaveModeMixerCanRenderSubdivisions() {
        let pattern = Pattern.claveMode(.fiveEightTwoThree, mixerPreset: .claveMetronomeSubdivisions)

        XCTAssertEqual(pattern.beats.count, 10)
        XCTAssertTrue(pattern.beats.contains { $0.soundRole == .subdivision })
        XCTAssertFalse(pattern.beats.contains { $0.soundRole == .muted })
    }

    func testClaveModeTemplatesCoverTraditionalAndOddFeels() {
        XCTAssertEqual(ClaveModeTemplate.allCases.count, 13)
        XCTAssertEqual(Pattern.claveMode(.bembeBell68).beats.filter { $0.soundRole == .beat }.map(\.index), [2, 3, 4, 5, 6, 7, 8, 10])
        XCTAssertEqual(Pattern.claveMode(.elevenEightThreeThreeTwoThree, mixerPreset: .claveOnly).beats.filter { $0.soundRole != .muted }.map(\.index), [0, 3, 6, 10, 13, 16, 19])
    }

    func testSwingTemplatesCoverJazzFeels() {
        XCTAssertEqual(SwingTemplate.allCases.count, 4)
        XCTAssertEqual(Pattern.swing(.jazzTwoAndFour).beats.filter { $0.soundRole != .muted }.map(\.index), [1, 3])
        let swingDurations = Pattern.swing(.swingEighths).stepDurationsInMeterBeats ?? []
        XCTAssertEqual(Array(swingDurations.prefix(4)).map { ($0 * 100).rounded() / 100 }, [0.67, 0.33, 0.67, 0.33])
        XCTAssertEqual(Pattern.swing(.halfTimeShuffle).beats.filter { $0.soundRole != .muted }.map(\.index), [0, 2, 5, 6, 8, 11])
    }

    func testPolyrhythmTemplatesFlattenPrimaryAndCrossPulses() {
        XCTAssertEqual(PolyrhythmTemplate.allCases.count, 6)

        let threeOverTwo = Pattern.polyrhythm(.threeOverTwo)
        XCTAssertEqual(threeOverTwo.beats.count, 6)
        XCTAssertEqual(threeOverTwo.polyrhythmTemplate, .threeOverTwo)
        XCTAssertEqual(threeOverTwo.stepDurationsInMeterBeats, Array(repeating: 1.0 / 3.0, count: 6))
        XCTAssertEqual(threeOverTwo.beats.filter { $0.soundRole == .beat }.map(\.index), [3])
        XCTAssertEqual(threeOverTwo.beats.filter { $0.soundRole == .subdivision }.map(\.index), [2, 4])

        let fiveOverFour = Pattern.polyrhythm(.fiveOverFour)
        XCTAssertEqual(fiveOverFour.beats.count, 20)
        XCTAssertEqual(fiveOverFour.beats.filter { $0.soundRole == .beat }.map(\.index), [5, 10, 15])
        XCTAssertEqual(fiveOverFour.beats.filter { $0.soundRole == .subdivision }.map(\.index), [4, 8, 12, 16])
    }

    func testPatternEditingClearsGrooveTemplateMarker() {
        var pattern = Pattern.groove(.bossaClave)

        pattern.updateMeter(.sevenEight)

        XCTAssertNil(pattern.grooveTemplate)
        XCTAssertNil(pattern.claveModeTemplate)
        XCTAssertNil(pattern.grooveMixerPreset)
        XCTAssertNil(pattern.swingTemplate)
        XCTAssertNil(pattern.polyrhythmTemplate)
        XCTAssertEqual(pattern.subdivision, .sixteenth)
        XCTAssertEqual(pattern.beats.count, 14)
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
        XCTAssertEqual(pattern.beats.count, 16)
        XCTAssertEqual(pattern.eventIntervalDivisor, 4)
        XCTAssertEqual(Array(pattern.beats.map(\.soundRole).prefix(5)), [.downbeat, .subdivision, .subdivision, .subdivision, .beat])
    }

    func testPatternTripletSubdivisionCreatesEditableSteps() {
        var pattern = Pattern.defaultFourFour()

        pattern.updateSubdivision(.triplet)

        XCTAssertEqual(pattern.beats.count, 12)
        XCTAssertEqual(pattern.eventIntervalDivisor, 3)
        XCTAssertEqual(Array(pattern.beats.map(\.soundRole).prefix(4)), [.downbeat, .subdivision, .subdivision, .beat])
    }

    func testCompoundMeterEighthSubdivisionStaysOnMeterBeats() throws {
        let pattern = try Pattern(
            name: "Five eight",
            bpm: 108,
            meter: Meter(beatsPerBar: 5, beatUnit: 8, grouping: [2, 3]),
            subdivision: .eighth
        )

        XCTAssertEqual(pattern.beats.count, 5)
        XCTAssertEqual(pattern.eventIntervalDivisor, 1)
        XCTAssertEqual(pattern.beats.map(\.soundRole), [.downbeat, .beat, .beat, .beat, .beat])
    }

    func testMixedPerBeatSubdivisionsCreateVariableStepDurations() throws {
        let pattern = Pattern.mixedSubdivision(
            subdivisions: [.sixteenth, .quintuplet, .triplet, .eighth]
        )

        XCTAssertEqual(pattern.beats.count, 14)
        XCTAssertEqual(pattern.perBeatSubdivisions, [.sixteenth, .quintuplet, .triplet, .eighth])
        XCTAssertEqual(pattern.eventIntervalDivisor, 1)
        XCTAssertEqual(pattern.stepDurationsInMeterBeats?.prefix(6).map { ($0 * 100).rounded() / 100 }, [0.25, 0.25, 0.25, 0.25, 0.2, 0.2])
        XCTAssertEqual(pattern.subdivisionSummary, "1: Sixteenth, 2: Quintuplet, 3: Triplet, 4: Eighth")
    }

    func testPatternCanUpdateOneBeatSubdivision() throws {
        var pattern = Pattern.defaultFourFour()

        try pattern.updateBeatSubdivision(.quintuplet, at: 1)

        XCTAssertEqual(pattern.beats.count, 8)
        XCTAssertEqual(pattern.perBeatSubdivisions, [.quarter, .quintuplet, .quarter, .quarter])
        XCTAssertEqual(pattern.stepDurationsInMeterBeats, [1.0, 0.2, 0.2, 0.2, 0.2, 0.2, 1.0, 1.0])
        XCTAssertNil(pattern.grooveTemplate)
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

    func testPatternSetsExplicitAccentAndSoundRole() throws {
        var pattern = Pattern.defaultFourFour()

        try pattern.setAccent(.muted, at: 0)
        try pattern.setAccent(.strong, at: 1)
        try pattern.setAccent(.ghost, at: 2)

        XCTAssertEqual(pattern.beats[0].accent, .muted)
        XCTAssertEqual(pattern.beats[0].soundRole, .muted)
        XCTAssertEqual(pattern.beats[1].accent, .strong)
        XCTAssertEqual(pattern.beats[1].soundRole, .beat)
        XCTAssertEqual(pattern.beats[2].accent, .ghost)
        XCTAssertEqual(pattern.beats[2].soundRole, .subdivision)
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

    func testSetlistItemBarCountClampsForSongForms() throws {
        let pattern = Pattern.defaultFourFour()
        var setlist = Setlist(name: "Song")
        setlist.append(pattern: pattern)

        let itemID = setlist.items[0].id
        try setlist.updateBarCount(for: itemID, barCount: 0)
        XCTAssertEqual(setlist.items[0].resolvedBarCount, SetlistItem.minimumBarCount)

        try setlist.updateBarCount(for: itemID, barCount: 999)
        XCTAssertEqual(setlist.items[0].resolvedBarCount, SetlistItem.maximumBarCount)
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

    func testMixedSubdivisionCodableRoundTrip() throws {
        let pattern = Pattern.mixedSubdivision(subdivisions: [.sixteenth, .quintuplet, .triplet, .eighth])
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
