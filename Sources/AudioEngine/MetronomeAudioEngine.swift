import AVFoundation
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

public struct BeatSchedule: Equatable, Sendable {
    public let events: [ScheduledBeatEvent]

    public init(events: [ScheduledBeatEvent]) {
        self.events = events
    }
}

public struct MetronomeScheduler: Sendable {
    public init() {}

    public func beatIntervalNanoseconds(for bpm: Int) throws -> UInt64 {
        try Pattern.validateBPM(bpm)
        return UInt64((60_000_000_000.0 / Double(bpm)).rounded())
    }

    public func schedule(
        pattern: Pattern,
        startingAt startTimeNanoseconds: UInt64,
        beatCount: Int
    ) throws -> BeatSchedule {
        guard beatCount >= 0 else {
            return BeatSchedule(events: [])
        }

        let interval = try beatIntervalNanoseconds(for: pattern.bpm)
        let events = (0..<beatCount).map { offset in
            let beat = pattern.beats[offset % pattern.beats.count]
            return ScheduledBeatEvent(
                patternID: pattern.id,
                beatIndex: beat.index,
                accent: beat.accent,
                soundRole: beat.soundRole,
                hostTimeNanoseconds: startTimeNanoseconds + (UInt64(offset) * interval)
            )
        }
        return BeatSchedule(events: events)
    }
}

public protocol MetronomeAudioEngine: Sendable {
    func prepare(pattern: Pattern) async throws
    func start() async throws
    func stop() async
    func setEventHandler(_ handler: (@Sendable (ScheduledBeatEvent) async -> Void)?) async
}

public actor AudioEngineStub: MetronomeAudioEngine {
    public private(set) var isRunning = false
    private var preparedPattern: Pattern?
    private var eventHandler: (@Sendable (ScheduledBeatEvent) async -> Void)?

    public init() {}

    public func prepare(pattern: Pattern) async throws {
        preparedPattern = pattern
    }

    public func start() async throws {
        guard let preparedPattern else {
            return
        }
        isRunning = true
        let event = ScheduledBeatEvent(
            patternID: preparedPattern.id,
            beatIndex: preparedPattern.beats[0].index,
            accent: preparedPattern.beats[0].accent,
            soundRole: preparedPattern.beats[0].soundRole,
            hostTimeNanoseconds: DispatchTime.now().uptimeNanoseconds
        )
        await eventHandler?(event)
    }

    public func stop() async {
        isRunning = false
    }

    public func setEventHandler(_ handler: (@Sendable (ScheduledBeatEvent) async -> Void)?) async {
        eventHandler = handler
    }
}

public actor AVMetronomeAudioEngine: MetronomeAudioEngine {
    public private(set) var isRunning = false

    private let audioEngine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let scheduler = MetronomeScheduler()
    private var preparedPattern: Pattern?
    private var eventHandler: (@Sendable (ScheduledBeatEvent) async -> Void)?
    private var playbackTask: Task<Void, Never>?
    private var clickBuffers: [ClickSoundRole: AVAudioPCMBuffer] = [:]
    private var isGraphConfigured = false

    public init() {}

    public func prepare(pattern: Pattern) async throws {
        preparedPattern = pattern

        if clickBuffers.isEmpty {
            clickBuffers = try makeClickBuffers()
        }

        if !isGraphConfigured {
            audioEngine.attach(player)
            let format = clickBuffers[.beat]?.format ?? AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
            audioEngine.connect(player, to: audioEngine.mainMixerNode, format: format)
            isGraphConfigured = true
        }
    }

    public func start() async throws {
        guard preparedPattern != nil else {
            return
        }

        if clickBuffers.isEmpty {
            clickBuffers = try makeClickBuffers()
        }

        try configureSession()

        if !audioEngine.isRunning {
            try audioEngine.start()
        }

        if !player.isPlaying {
            player.play()
        }

        isRunning = true
        playbackTask?.cancel()
        playbackTask = Task { [weak self] in
            await self?.runPlaybackLoop()
        }
    }

    public func stop() async {
        isRunning = false
        playbackTask?.cancel()
        playbackTask = nil
        player.stop()
        audioEngine.pause()
    }

    public func setEventHandler(_ handler: (@Sendable (ScheduledBeatEvent) async -> Void)?) async {
        eventHandler = handler
    }

    private func runPlaybackLoop() async {
        var beatOffset = 0
        var nextBeatTime = DispatchTime.now().uptimeNanoseconds

        while !Task.isCancelled {
            guard isRunning, let pattern = preparedPattern else {
                break
            }

            let interval: UInt64
            do {
                interval = try scheduler.beatIntervalNanoseconds(for: pattern.bpm)
            } catch {
                await stop()
                break
            }

            let now = DispatchTime.now().uptimeNanoseconds
            if nextBeatTime > now {
                try? await Task.sleep(nanoseconds: nextBeatTime - now)
            }

            guard !Task.isCancelled, isRunning else {
                break
            }

            let beat = pattern.beats[beatOffset % pattern.beats.count]
            let event = ScheduledBeatEvent(
                patternID: pattern.id,
                beatIndex: beat.index,
                accent: beat.accent,
                soundRole: beat.soundRole,
                hostTimeNanoseconds: nextBeatTime
            )
            play(event: event)
            if let eventHandler {
                Task {
                    await eventHandler(event)
                }
            }

            beatOffset += 1
            nextBeatTime += interval
        }
    }

    private func play(event: ScheduledBeatEvent) {
        let buffer = clickBuffers[event.soundRole] ?? clickBuffers[.beat]
        guard let buffer else {
            return
        }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    private func configureSession() throws {
#if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setPreferredSampleRate(48_000)
        try session.setPreferredIOBufferDuration(0.005)
        try session.setActive(true)
#endif
    }

    private func makeClickBuffers() throws -> [ClickSoundRole: AVAudioPCMBuffer] {
        let sampleRate = 48_000.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        return [
            .downbeat: try makeClickBuffer(format: format, frequency: 1_600, duration: 0.035, gain: 0.85),
            .beat: try makeClickBuffer(format: format, frequency: 1_050, duration: 0.028, gain: 0.62),
            .subdivision: try makeClickBuffer(format: format, frequency: 820, duration: 0.018, gain: 0.42),
            .cue: try makeClickBuffer(format: format, frequency: 1_300, duration: 0.05, gain: 0.7),
            .muted: try makeClickBuffer(format: format, frequency: 200, duration: 0.004, gain: 0.0)
        ]
    }

    private func makeClickBuffer(
        format: AVAudioFormat,
        frequency: Double,
        duration: Double,
        gain: Float
    ) throws -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioEngineError.bufferCreationFailed
        }
        buffer.frameLength = frameCount

        guard let channel = buffer.floatChannelData?[0] else {
            throw AudioEngineError.bufferCreationFailed
        }

        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / Double(frameCount)
            let envelope = Float(pow(1.0 - progress, 4.0))
            let sample = sin((Double(frame) / format.sampleRate) * frequency * 2.0 * Double.pi)
            channel[frame] = Float(sample) * gain * envelope
        }

        return buffer
    }
}

public enum AudioEngineError: Error, Equatable {
    case bufferCreationFailed
}
