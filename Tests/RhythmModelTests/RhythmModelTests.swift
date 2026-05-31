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
}
