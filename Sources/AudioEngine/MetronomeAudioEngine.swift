import Foundation
import RhythmModel

public struct ScheduledBeatEvent: Equatable, Sendable {
    public let patternID: Pattern.ID
    public let beatIndex: Int
    public let accent: AccentLevel
    public let soundRole: ClickSoundRole
    public let hostTimeNanoseconds: UInt64

    public init(
        patternID: Pattern.ID,
        beatIndex: Int,
        accent: AccentLevel,
        soundRole: ClickSoundRole,
        hostTimeNanoseconds: UInt64
    ) {
        self.patternID = patternID
        self.beatIndex = beatIndex
        self.accent = accent
        self.soundRole = soundRole
        self.hostTimeNanoseconds = hostTimeNanoseconds
    }
}

public protocol MetronomeAudioEngine: Sendable {
    var isRunning: Bool { get }

    func prepare(pattern: Pattern) async throws
    func start() async throws
    func stop() async
}

public actor AudioEngineStub: MetronomeAudioEngine {
    public private(set) var isRunning = false
    private var preparedPattern: Pattern?

    public init() {}

    public func prepare(pattern: Pattern) async throws {
        preparedPattern = pattern
    }

    public func start() async throws {
        guard preparedPattern != nil else {
            return
        }
        isRunning = true
    }

    public func stop() async {
        isRunning = false
    }
}
