import XCTest
@testable import MIDIConnectivity
@testable import RhythmModel

final class MIDIConnectivityTests: XCTestCase {
    func testTransportMessagesUseRealtimeStatusBytes() {
        XCTAssertEqual(MIDIMessageFactory.transport(.clock).bytes, [0xF8])
        XCTAssertEqual(MIDIMessageFactory.transport(.start).bytes, [0xFA])
        XCTAssertEqual(MIDIMessageFactory.transport(.continueTransport).bytes, [0xFB])
        XCTAssertEqual(MIDIMessageFactory.transport(.stop).bytes, [0xFC])
    }

    func testChannelMessagesClampToMidiRange() {
        XCTAssertEqual(MIDIMessageFactory.programChange(channel: 17, program: 140).bytes, [0xCF, 127])
        XCTAssertEqual(MIDIMessageFactory.controlChange(channel: 0, controller: 130, value: 200).bytes, [0xB0, 127, 127])
        XCTAssertEqual(MIDIMessageFactory.noteOn(channel: 3, note: 64, velocity: 100).bytes, [0x92, 64, 100])
        XCTAssertEqual(MIDIMessageFactory.noteOff(channel: 3, note: 64).bytes, [0x82, 64, 0])
    }

    func testCueMessagesMapToExpectedMidiMessages() {
        let programCue = MIDICue(kind: .programChange, channel: 2, number: 10)
        let controlCue = MIDICue(kind: .controlChange, channel: 2, number: 74, value: 96)
        let noteCue = MIDICue(kind: .note, channel: 1, number: 60, value: 110)

        XCTAssertEqual(MIDIMessageFactory.messages(for: programCue).map(\.bytes), [[0xC1, 10]])
        XCTAssertEqual(MIDIMessageFactory.messages(for: controlCue).map(\.bytes), [[0xB1, 74, 96]])
        XCTAssertEqual(MIDIMessageFactory.messages(for: noteCue).map(\.bytes), [[0x90, 60, 110], [0x80, 60, 0]])
    }

    func testClockMessagesGenerateTwentyFourPulsesPerBeat() throws {
        let service = StandardMIDIClockService()
        let messages = try service.clockMessages(for: 120, beats: 2, startTimestamp: 1_000)

        XCTAssertEqual(messages.count, 48)
        XCTAssertTrue(messages.allSatisfy { $0.bytes == [0xF8] })
        XCTAssertEqual(messages[1].timestamp - messages[0].timestamp, 20_833_333)
    }

    func testClockFollowerEstimatesTempoFromIncomingClock() {
        var service = StandardMIDIClockService()
        var bpm: Int?
        let pulseInterval = UInt64(60_000_000_000.0 / 120.0 / 24.0)

        for index in 0...24 {
            bpm = service.observe(MIDIMessage(bytes: [0xF8], timestamp: UInt64(index) * pulseInterval))
        }

        XCTAssertEqual(bpm, 120)
    }
}

