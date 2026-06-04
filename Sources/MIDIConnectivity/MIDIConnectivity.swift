import Foundation
import RhythmModel

public struct MIDIEndpoint: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var manufacturer: String?

    public init(id: String, name: String, manufacturer: String? = nil) {
        self.id = id
        self.name = name
        self.manufacturer = manufacturer
    }
}

public enum MIDIConnectionStatus: String, Codable, Equatable, Sendable {
    case unavailable
    case disconnected
    case connected
    case sendingClock
    case followingClock
    case failed
}

public enum MIDITransportCommand: Equatable, Sendable {
    case start
    case stop
    case continueTransport
    case clock
}

public struct MIDIMessage: Equatable, Sendable {
    public var bytes: [UInt8]
    public var timestamp: UInt64

    public init(bytes: [UInt8], timestamp: UInt64 = 0) {
        self.bytes = bytes.map { min($0, 0xFF) }
        self.timestamp = timestamp
    }
}

public protocol MIDIConnector: Sendable {
    func availableInputs() async -> [MIDIEndpoint]
    func availableOutputs() async -> [MIDIEndpoint]
    func connect(inputID: String?, outputID: String?) async throws
    func disconnect() async
    func send(_ message: MIDIMessage) async throws
    func status() async -> MIDIConnectionStatus
}

public protocol MIDIClockService: Sendable {
    func clockMessages(for bpm: Int, beats: Int, startTimestamp: UInt64) throws -> [MIDIMessage]
    mutating func observe(_ message: MIDIMessage) -> Int?
}

public enum MIDIMessageFactory {
    public static func transport(_ command: MIDITransportCommand, timestamp: UInt64 = 0) -> MIDIMessage {
        switch command {
        case .start:
            MIDIMessage(bytes: [0xFA], timestamp: timestamp)
        case .continueTransport:
            MIDIMessage(bytes: [0xFB], timestamp: timestamp)
        case .stop:
            MIDIMessage(bytes: [0xFC], timestamp: timestamp)
        case .clock:
            MIDIMessage(bytes: [0xF8], timestamp: timestamp)
        }
    }

    public static func programChange(channel: UInt8, program: UInt8, timestamp: UInt64 = 0) -> MIDIMessage {
        MIDIMessage(bytes: [0xC0 | zeroBasedChannel(channel), min(program, 127)], timestamp: timestamp)
    }

    public static func controlChange(channel: UInt8, controller: UInt8, value: UInt8, timestamp: UInt64 = 0) -> MIDIMessage {
        MIDIMessage(bytes: [0xB0 | zeroBasedChannel(channel), min(controller, 127), min(value, 127)], timestamp: timestamp)
    }

    public static func noteOn(channel: UInt8, note: UInt8, velocity: UInt8, timestamp: UInt64 = 0) -> MIDIMessage {
        MIDIMessage(bytes: [0x90 | zeroBasedChannel(channel), min(note, 127), min(velocity, 127)], timestamp: timestamp)
    }

    public static func noteOff(channel: UInt8, note: UInt8, timestamp: UInt64 = 0) -> MIDIMessage {
        MIDIMessage(bytes: [0x80 | zeroBasedChannel(channel), min(note, 127), 0], timestamp: timestamp)
    }

    public static func messages(for cue: MIDICue, timestamp: UInt64 = 0) -> [MIDIMessage] {
        switch cue.kind {
        case .start:
            [transport(.start, timestamp: timestamp)]
        case .stop:
            [transport(.stop, timestamp: timestamp)]
        case .continueTransport:
            [transport(.continueTransport, timestamp: timestamp)]
        case .programChange:
            [programChange(channel: cue.channel, program: cue.number, timestamp: timestamp)]
        case .controlChange:
            [controlChange(channel: cue.channel, controller: cue.number, value: cue.value, timestamp: timestamp)]
        case .note:
            [
                noteOn(channel: cue.channel, note: cue.number, velocity: max(cue.value, 1), timestamp: timestamp),
                noteOff(channel: cue.channel, note: cue.number, timestamp: timestamp + 1)
            ]
        }
    }

    private static func zeroBasedChannel(_ channel: UInt8) -> UInt8 {
        min(max(channel, 1), 16) - 1
    }
}

public struct StandardMIDIClockService: MIDIClockService {
    private static let pulsesPerQuarterNote = 24
    private var recentClockTimestamps: [UInt64] = []

    public init() {}

    public func clockMessages(for bpm: Int, beats: Int, startTimestamp: UInt64 = 0) throws -> [MIDIMessage] {
        try Pattern.validateBPM(bpm)

        let pulseCount = max(0, beats) * Self.pulsesPerQuarterNote
        let nanosecondsPerPulse = UInt64((60_000_000_000.0 / Double(bpm) / Double(Self.pulsesPerQuarterNote)).rounded())

        return (0..<pulseCount).map { pulseOffset in
            MIDIMessageFactory.transport(
                .clock,
                timestamp: startTimestamp + UInt64(pulseOffset) * nanosecondsPerPulse
            )
        }
    }

    public mutating func observe(_ message: MIDIMessage) -> Int? {
        guard message.bytes.first == 0xF8 else {
            return nil
        }

        recentClockTimestamps.append(message.timestamp)
        recentClockTimestamps = Array(recentClockTimestamps.suffix(Self.pulsesPerQuarterNote + 1))

        guard recentClockTimestamps.count >= Self.pulsesPerQuarterNote + 1,
              let first = recentClockTimestamps.first,
              let last = recentClockTimestamps.last,
              last > first else {
            return nil
        }

        let elapsedNanoseconds = Double(last - first)
        let quarterNotes = Double(recentClockTimestamps.count - 1) / Double(Self.pulsesPerQuarterNote)
        let secondsPerQuarter = elapsedNanoseconds / 1_000_000_000.0 / quarterNotes
        guard secondsPerQuarter > 0 else {
            return nil
        }

        return min(Pattern.maximumBPM, max(Pattern.minimumBPM, Int((60.0 / secondsPerQuarter).rounded())))
    }
}

