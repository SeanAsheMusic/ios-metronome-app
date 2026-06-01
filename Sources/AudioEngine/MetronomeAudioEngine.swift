import AVFoundation
import Foundation
import RhythmModel

public typealias MetronomePattern = RhythmModel.Pattern

public struct ScheduledBeatEvent: Equatable, Sendable {
    public let patternID: MetronomePattern.ID
    public let beatIndex: Int
    public let accent: AccentLevel
    public let soundRole: ClickSoundRole
    public let hostTimeNanoseconds: UInt64

    public init(
        patternID: MetronomePattern.ID,
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

public struct AudioTimingSample: Equatable, Sendable {
    public let scheduledHostTimeNanoseconds: UInt64
    public let observedHostTimeNanoseconds: UInt64

    public init(scheduledHostTimeNanoseconds: UInt64, observedHostTimeNanoseconds: UInt64) {
        self.scheduledHostTimeNanoseconds = scheduledHostTimeNanoseconds
        self.observedHostTimeNanoseconds = observedHostTimeNanoseconds
    }

    public var offsetNanoseconds: Int64 {
        Int64(observedHostTimeNanoseconds) - Int64(scheduledHostTimeNanoseconds)
    }
}

public struct AudioTimingSummary: Equatable, Sendable {
    public let sampleCount: Int
    public let minimumOffsetNanoseconds: Int64
    public let maximumOffsetNanoseconds: Int64
    public let averageOffsetNanoseconds: Int64
    public let peakToPeakJitterNanoseconds: UInt64

    public init(samples: [AudioTimingSample]) {
        let offsets = samples.map(\.offsetNanoseconds)
        sampleCount = offsets.count
        minimumOffsetNanoseconds = offsets.min() ?? 0
        maximumOffsetNanoseconds = offsets.max() ?? 0
        let total = offsets.reduce(Int64(0), +)
        averageOffsetNanoseconds = offsets.isEmpty ? 0 : total / Int64(offsets.count)
        peakToPeakJitterNanoseconds = UInt64(maximumOffsetNanoseconds - minimumOffsetNanoseconds)
    }
}

public actor AudioTimingRecorder {
    private let sampleLimit: Int
    private var samples: [AudioTimingSample] = []

    public init(sampleLimit: Int = 720) {
        self.sampleLimit = max(1, sampleLimit)
    }

    public func record(scheduledHostTimeNanoseconds: UInt64, observedHostTimeNanoseconds: UInt64) {
        samples.append(AudioTimingSample(
            scheduledHostTimeNanoseconds: scheduledHostTimeNanoseconds,
            observedHostTimeNanoseconds: observedHostTimeNanoseconds
        ))
        if samples.count > sampleLimit {
            samples.removeFirst(samples.count - sampleLimit)
        }
    }

    public func summary() -> AudioTimingSummary {
        AudioTimingSummary(samples: samples)
    }

    public func reset() {
        samples.removeAll()
    }
}

public enum ClickSoundPreset: String, CaseIterable, Codable, Equatable, Sendable {
    case classic
    case hardClick
    case wood
    case clave
    case rimshot
    case cowbell
    case hiHat
    case shaker
    case clap
    case sine
    case mellow
    case bell
    case mechanical

    public var displayName: String {
        switch self {
        case .classic: "Classic"
        case .hardClick: "Hard Click"
        case .wood: "Wood"
        case .clave: "Clave"
        case .rimshot: "Rimshot"
        case .cowbell: "Cowbell"
        case .hiHat: "Hi-Hat"
        case .shaker: "Shaker"
        case .clap: "Clap"
        case .sine: "Sine"
        case .mellow: "Mellow"
        case .bell: "Bell"
        case .mechanical: "Mechanical"
        }
    }
}

public struct MetronomeAudioSettings: Codable, Equatable, Sendable {
    public var soundPreset: ClickSoundPreset
    public var masterGain: Double
    public var accentBoost: Double
    public var downbeatGain: Double
    public var beatGain: Double
    public var subdivisionGain: Double
    public var cueGain: Double
    public var humanizationAmount: Double
    public var rhythmTrainer: RhythmTrainerSettings

    public init(
        soundPreset: ClickSoundPreset = .classic,
        masterGain: Double = 0.8,
        accentBoost: Double = 1.0,
        downbeatGain: Double = 1.0,
        beatGain: Double = 1.0,
        subdivisionGain: Double = 1.0,
        cueGain: Double = 1.0,
        humanizationAmount: Double = 0.0,
        rhythmTrainer: RhythmTrainerSettings = RhythmTrainerSettings()
    ) {
        self.soundPreset = soundPreset
        self.masterGain = min(1.0, max(0.0, masterGain))
        self.accentBoost = min(1.5, max(0.5, accentBoost))
        self.downbeatGain = Self.clampRoleGain(downbeatGain)
        self.beatGain = Self.clampRoleGain(beatGain)
        self.subdivisionGain = Self.clampRoleGain(subdivisionGain)
        self.cueGain = Self.clampRoleGain(cueGain)
        self.humanizationAmount = min(1.0, max(0.0, humanizationAmount))
        self.rhythmTrainer = rhythmTrainer
    }

    public var humanizationWarning: String? {
        humanizationAmount >= 0.9 ? "High human feel intentionally makes the click inaccurate." : nil
    }

    private enum CodingKeys: String, CodingKey {
        case soundPreset
        case masterGain
        case accentBoost
        case downbeatGain
        case beatGain
        case subdivisionGain
        case cueGain
        case humanizationAmount
        case rhythmTrainer
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            soundPreset: try container.decodeIfPresent(ClickSoundPreset.self, forKey: .soundPreset) ?? .classic,
            masterGain: try container.decodeIfPresent(Double.self, forKey: .masterGain) ?? 0.8,
            accentBoost: try container.decodeIfPresent(Double.self, forKey: .accentBoost) ?? 1.0,
            downbeatGain: try container.decodeIfPresent(Double.self, forKey: .downbeatGain) ?? 1.0,
            beatGain: try container.decodeIfPresent(Double.self, forKey: .beatGain) ?? 1.0,
            subdivisionGain: try container.decodeIfPresent(Double.self, forKey: .subdivisionGain) ?? 1.0,
            cueGain: try container.decodeIfPresent(Double.self, forKey: .cueGain) ?? 1.0,
            humanizationAmount: try container.decodeIfPresent(Double.self, forKey: .humanizationAmount) ?? 0.0,
            rhythmTrainer: try container.decodeIfPresent(RhythmTrainerSettings.self, forKey: .rhythmTrainer) ?? RhythmTrainerSettings()
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(soundPreset, forKey: .soundPreset)
        try container.encode(masterGain, forKey: .masterGain)
        try container.encode(accentBoost, forKey: .accentBoost)
        try container.encode(downbeatGain, forKey: .downbeatGain)
        try container.encode(beatGain, forKey: .beatGain)
        try container.encode(subdivisionGain, forKey: .subdivisionGain)
        try container.encode(cueGain, forKey: .cueGain)
        try container.encode(humanizationAmount, forKey: .humanizationAmount)
        try container.encode(rhythmTrainer, forKey: .rhythmTrainer)
    }

    private static func clampRoleGain(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }

    public mutating func resetRoleMixer() {
        downbeatGain = 1.0
        beatGain = 1.0
        subdivisionGain = 1.0
        cueGain = 1.0
    }

    public mutating func setPrecisionPracticeMode() {
        humanizationAmount = 0.0
        rhythmTrainer = RhythmTrainerSettings(mode: .off)
    }
}

public enum RhythmTrainerMode: String, CaseIterable, Codable, Equatable, Sendable {
    case off
    case fixedBars
    case randomBars
    case randomBeats
    case guideTwoAndFour
    case dropOneAndThree

    public var displayName: String {
        switch self {
        case .off: "Off"
        case .fixedBars: "Fixed Gaps"
        case .randomBars: "Random Gaps"
        case .randomBeats: "Random Beats"
        case .guideTwoAndFour: "2 & 4 Guide"
        case .dropOneAndThree: "Drop 1 & 3"
        }
    }
}

public struct RhythmTrainerSettings: Codable, Equatable, Sendable {
    public static let minimumBars = 1
    public static let maximumBars = 8

    public var mode: RhythmTrainerMode
    public var audibleBars: Int
    public var silentBars: Int
    public var randomSilenceProbability: Double

    public init(
        mode: RhythmTrainerMode = .off,
        audibleBars: Int = 3,
        silentBars: Int = 1,
        randomSilenceProbability: Double = 0.25
    ) {
        self.mode = mode
        self.audibleBars = min(Self.maximumBars, max(Self.minimumBars, audibleBars))
        self.silentBars = min(Self.maximumBars, max(Self.minimumBars, silentBars))
        self.randomSilenceProbability = min(1.0, max(0.0, randomSilenceProbability))
    }

    public var isEnabled: Bool {
        mode != .off
    }

    public var summary: String {
        switch mode {
        case .off:
            "Off"
        case .fixedBars:
            "\(audibleBars) on, \(silentBars) silent"
        case .randomBars:
            "\(Int((randomSilenceProbability * 100).rounded()))% random silent bars"
        case .randomBeats:
            "\(Int((randomSilenceProbability * 100).rounded()))% random beat dropout"
        case .guideTwoAndFour:
            "Only beats 2 and 4"
        case .dropOneAndThree:
            "Mute beats 1 and 3"
        }
    }

    public func soundRole(
        for originalRole: ClickSoundRole,
        patternID: UUID,
        barIndex: Int,
        eventIndexInBar: Int = 0,
        mainBeatIndexInBar: Int? = nil
    ) -> ClickSoundRole {
        guard originalRole != .muted else {
            return originalRole
        }

        switch mode {
        case .off:
            return originalRole
        case .fixedBars:
            let cycleLength = audibleBars + silentBars
            let barInCycle = barIndex % cycleLength
            return barInCycle >= audibleBars ? .muted : originalRole
        case .randomBars:
            return Self.randomUnit(patternID: patternID, barIndex: barIndex) < randomSilenceProbability ? .muted : originalRole
        case .randomBeats:
            return Self.randomUnit(patternID: patternID, barIndex: barIndex, eventIndexInBar: eventIndexInBar) < randomSilenceProbability ? .muted : originalRole
        case .guideTwoAndFour:
            guard Self.isMainPulse(originalRole), let mainBeatIndexInBar else {
                return .muted
            }
            return mainBeatIndexInBar == 1 || mainBeatIndexInBar == 3 ? originalRole : .muted
        case .dropOneAndThree:
            guard Self.isMainPulse(originalRole), let mainBeatIndexInBar else {
                return originalRole
            }
            return mainBeatIndexInBar == 0 || mainBeatIndexInBar == 2 ? .muted : originalRole
        }
    }

    private static func isMainPulse(_ role: ClickSoundRole) -> Bool {
        role == .downbeat || role == .beat
    }

    private static func randomUnit(patternID: UUID, barIndex: Int, eventIndexInBar: Int? = nil) -> Double {
        var hasher = Hasher()
        hasher.combine(patternID)
        hasher.combine(barIndex)
        if let eventIndexInBar {
            hasher.combine(eventIndexInBar)
        }
        let value = abs(hasher.finalize() % 10_000)
        return Double(value) / 10_000.0
    }
}

public enum AudioLatencyRisk: String, Codable, Equatable, Sendable {
    case low
    case elevated
    case unknown

    public var displayName: String {
        switch self {
        case .low: "Low latency"
        case .elevated: "Latency warning"
        case .unknown: "Latency unknown"
        }
    }
}

public enum AudioSessionInterruptionEvent: Equatable, Sendable {
    case began
    case ended(shouldResume: Bool)
}

public struct AudioRouteOutput: Codable, Equatable, Sendable {
    public let portType: String
    public let name: String

    public init(portType: String, name: String) {
        self.portType = portType
        self.name = name
    }
}

public struct AudioRouteStatus: Codable, Equatable, Sendable {
    public let outputName: String
    public let latencyRisk: AudioLatencyRisk
    public let message: String

    public init(outputName: String, latencyRisk: AudioLatencyRisk, message: String) {
        self.outputName = outputName
        self.latencyRisk = latencyRisk
        self.message = message
    }

    public static func status(for outputs: [AudioRouteOutput]) -> AudioRouteStatus {
        guard let primaryOutput = outputs.first else {
            return AudioRouteStatus(
                outputName: "Unknown output",
                latencyRisk: .unknown,
                message: "Audio output is unavailable."
            )
        }

        let portType = primaryOutput.portType.lowercased()
        let outputName = primaryOutput.name.isEmpty ? "Audio output" : primaryOutput.name

        if portType.contains("bluetooth") || portType.contains("airplay") {
            return AudioRouteStatus(
                outputName: outputName,
                latencyRisk: .elevated,
                message: "Wireless routes can feel late for stage timing."
            )
        }

        if portType.contains("headphones")
            || portType.contains("headset")
            || portType.contains("speaker")
            || portType.contains("receiver")
            || portType.contains("lineout") {
            return AudioRouteStatus(
                outputName: outputName,
                latencyRisk: .low,
                message: "Wired or built-in output is best for timing."
            )
        }

        return AudioRouteStatus(
            outputName: outputName,
            latencyRisk: .unknown,
            message: "Latency has not been measured for this route."
        )
    }
}

public struct MetronomeScheduler: Sendable {
    public init() {}

    public func beatIntervalNanoseconds(for bpm: Int) throws -> UInt64 {
        try MetronomePattern.validateBPM(bpm)
        return UInt64((60_000_000_000.0 / Double(bpm)).rounded())
    }

    public func eventIntervalNanoseconds(for pattern: MetronomePattern) throws -> UInt64 {
        try beatIntervalNanoseconds(for: pattern.bpm) / UInt64(pattern.eventIntervalDivisor)
    }

    public func eventIntervalNanoseconds(for pattern: MetronomePattern, eventOffset: Int) throws -> UInt64 {
        let beatInterval = try beatIntervalNanoseconds(for: pattern.bpm)
        let multiplier = pattern.eventDurationInMeterBeats(atEventOffset: eventOffset)
        return UInt64((Double(beatInterval) * multiplier).rounded())
    }

    public func schedule(
        pattern: MetronomePattern,
        startingAt startTimeNanoseconds: UInt64,
        beatCount: Int
    ) throws -> BeatSchedule {
        guard beatCount >= 0 else {
            return BeatSchedule(events: [])
        }

        let firstInterval = try eventIntervalNanoseconds(for: pattern, eventOffset: 0)
        var nextEventTime = startTimeNanoseconds
        let events = (0..<beatCount).map { offset in
            let beat = pattern.beats[offset % pattern.beats.count]
            let event = ScheduledBeatEvent(
                patternID: pattern.id,
                beatIndex: beat.index,
                accent: beat.accent,
                soundRole: beat.soundRole,
                hostTimeNanoseconds: nextEventTime
            )
            let interval = (try? eventIntervalNanoseconds(for: pattern, eventOffset: offset)) ?? firstInterval
            nextEventTime += interval
            return event
        }
        return BeatSchedule(events: events)
    }
}

public protocol MetronomeAudioEngine: Sendable {
    func prepare(pattern: MetronomePattern) async throws
    func start() async throws
    func stop() async
    func playOneShot(pattern: MetronomePattern, soundRole: ClickSoundRole) async throws
    func setEventHandler(_ handler: (@Sendable (ScheduledBeatEvent) async -> Void)?) async
    func updateSettings(_ settings: MetronomeAudioSettings) async throws
    func currentRouteStatus() async -> AudioRouteStatus
    func timingSummary() async -> AudioTimingSummary
    func resetTimingMeasurements() async
}

public actor AudioEngineStub: MetronomeAudioEngine {
    public private(set) var isRunning = false
    private var preparedPattern: MetronomePattern?
    private var eventHandler: (@Sendable (ScheduledBeatEvent) async -> Void)?

    public init() {}

    public func prepare(pattern: MetronomePattern) async throws {
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

    public func playOneShot(pattern: MetronomePattern, soundRole: ClickSoundRole) async throws {
        let event = ScheduledBeatEvent(
            patternID: pattern.id,
            beatIndex: 0,
            accent: soundRole == .downbeat ? .strong : .normal,
            soundRole: soundRole,
            hostTimeNanoseconds: DispatchTime.now().uptimeNanoseconds
        )
        await eventHandler?(event)
    }

    public func setEventHandler(_ handler: (@Sendable (ScheduledBeatEvent) async -> Void)?) async {
        eventHandler = handler
    }

    public func updateSettings(_: MetronomeAudioSettings) async throws {}

    public func currentRouteStatus() async -> AudioRouteStatus {
        AudioRouteStatus.status(for: [
            AudioRouteOutput(portType: "builtInSpeaker", name: "Test speaker")
        ])
    }

    public func timingSummary() async -> AudioTimingSummary {
        AudioTimingSummary(samples: [])
    }

    public func resetTimingMeasurements() async {}
}

public actor AVMetronomeAudioEngine: MetronomeAudioEngine {
    public private(set) var isRunning = false

    private var audioEngine = AVAudioEngine()
    private var player = AVAudioPlayerNode()
    private let scheduler = MetronomeScheduler()
    private var preparedPattern: MetronomePattern?
    private var eventHandler: (@Sendable (ScheduledBeatEvent) async -> Void)?
    private var playbackTask: Task<Void, Never>?
    private var clickBuffers: [ClickSoundRole: AVAudioPCMBuffer] = [:]
    private var isGraphConfigured = false
    private var settings = MetronomeAudioSettings()
    private let timingRecorder = AudioTimingRecorder()
#if os(iOS)
    private var sessionObserverTokens: [NSObjectProtocol] = []
#endif
    private var shouldResumeAfterInterruption = false

    public init() {}

    deinit {
#if os(iOS)
        for token in sessionObserverTokens {
            NotificationCenter.default.removeObserver(token)
        }
#endif
    }

    public func prepare(pattern: MetronomePattern) async throws {
        preparedPattern = pattern
        installSessionObserversIfNeeded()

        if clickBuffers.isEmpty {
            clickBuffers = try makeClickBuffers(settings: settings)
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
            clickBuffers = try makeClickBuffers(settings: settings)
        }

        installSessionObserversIfNeeded()
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
        shouldResumeAfterInterruption = false
        isRunning = false
        playbackTask?.cancel()
        playbackTask = nil
        player.stop()
        audioEngine.pause()
    }

    public func playOneShot(pattern: MetronomePattern, soundRole: ClickSoundRole) async throws {
        preparedPattern = pattern

        if clickBuffers.isEmpty {
            clickBuffers = try makeClickBuffers(settings: settings)
        }

        installSessionObserversIfNeeded()
        if !isGraphConfigured {
            try await prepare(pattern: pattern)
        }

        try configureSession()

        if !audioEngine.isRunning {
            try audioEngine.start()
        }

        if !player.isPlaying {
            player.play()
        }

        let event = ScheduledBeatEvent(
            patternID: pattern.id,
            beatIndex: 0,
            accent: soundRole == .downbeat ? .strong : .normal,
            soundRole: soundRole,
            hostTimeNanoseconds: DispatchTime.now().uptimeNanoseconds
        )
        play(event: event)
        if let eventHandler {
            Task {
                await eventHandler(event)
            }
        }
    }

    public func setEventHandler(_ handler: (@Sendable (ScheduledBeatEvent) async -> Void)?) async {
        eventHandler = handler
    }

    public func updateSettings(_ settings: MetronomeAudioSettings) async throws {
        self.settings = settings
        clickBuffers = try makeClickBuffers(settings: settings)
    }

    public func currentRouteStatus() async -> AudioRouteStatus {
#if os(iOS)
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs.map { output in
            AudioRouteOutput(portType: output.portType.rawValue, name: output.portName)
        }
        return AudioRouteStatus.status(for: outputs)
#else
        return AudioRouteStatus.status(for: [
            AudioRouteOutput(portType: "unknown", name: "Default output")
        ])
#endif
    }

    public func timingSummary() async -> AudioTimingSummary {
        await timingRecorder.summary()
    }

    public func resetTimingMeasurements() async {
        await timingRecorder.reset()
    }

    public static func interruptionEvent(from userInfo: [AnyHashable: Any]) -> AudioSessionInterruptionEvent? {
#if os(iOS)
        guard
            let typeRawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeRawValue)
        else {
            return nil
        }

        switch type {
        case .began:
            return .began
        case .ended:
            let optionsRawValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsRawValue)
            return .ended(shouldResume: options.contains(.shouldResume))
        @unknown default:
            return nil
        }
#else
        return nil
#endif
    }

    private func installSessionObserversIfNeeded() {
#if os(iOS)
        guard sessionObserverTokens.isEmpty else {
            return
        }

        let center = NotificationCenter.default
        let interruptionToken = center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: nil
        ) { [weak self] notification in
            guard
                let event = Self.interruptionEvent(from: notification.userInfo ?? [:])
            else {
                return
            }
            Task {
                await self?.handleInterruption(event)
            }
        }

        let routeChangeToken = center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: nil
        ) { [weak self] _ in
            Task {
                await self?.handleRouteChange()
            }
        }

        let mediaServicesResetToken = center.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: AVAudioSession.sharedInstance(),
            queue: nil
        ) { [weak self] _ in
            Task {
                await self?.handleMediaServicesReset()
            }
        }

        sessionObserverTokens = [interruptionToken, routeChangeToken, mediaServicesResetToken]
#endif
    }

    private func handleInterruption(_ event: AudioSessionInterruptionEvent) async {
        switch event {
        case .began:
            shouldResumeAfterInterruption = isRunning
            isRunning = false
            playbackTask?.cancel()
            playbackTask = nil
            player.stop()
            audioEngine.pause()
        case let .ended(shouldResume):
            guard shouldResumeAfterInterruption else {
                return
            }
            shouldResumeAfterInterruption = false
            guard shouldResume else {
                return
            }
            try? await start()
        }
    }

    private func handleRouteChange() async {
        guard isRunning else {
            return
        }

        do {
            try configureSession()
            if !audioEngine.isRunning {
                try audioEngine.start()
            }
            if !player.isPlaying {
                player.play()
            }
        } catch {
            await stop()
        }
    }

    private func handleMediaServicesReset() async {
        let wasRunning = isRunning
        isRunning = false
        playbackTask?.cancel()
        playbackTask = nil
        player.stop()
        audioEngine.stop()
        audioEngine.reset()
        audioEngine = AVAudioEngine()
        player = AVAudioPlayerNode()
        clickBuffers = [:]
        isGraphConfigured = false

        guard let preparedPattern else {
            return
        }

        do {
            try await prepare(pattern: preparedPattern)
            if wasRunning {
                try await start()
            }
        } catch {
            shouldResumeAfterInterruption = false
        }
    }

    private func runPlaybackLoop() async {
        var beatOffset = 0
        var nextBeatTime = DispatchTime.now().uptimeNanoseconds

        while !Task.isCancelled {
            guard isRunning, let pattern = preparedPattern else {
                break
            }

            let now = DispatchTime.now().uptimeNanoseconds
            let humanizedBeatTime = humanizedHostTime(nextBeatTime, pattern: pattern, eventOffset: beatOffset)
            if humanizedBeatTime > now {
                try? await Task.sleep(nanoseconds: humanizedBeatTime - now)
            }

            guard !Task.isCancelled, isRunning else {
                break
            }

            let eventIndexInBar = beatOffset % pattern.beats.count
            let beat = pattern.beats[eventIndexInBar]
            let barIndex = beatOffset / max(1, pattern.beats.count)
            let soundRole = settings.rhythmTrainer.soundRole(
                for: beat.soundRole,
                patternID: pattern.id,
                barIndex: barIndex,
                eventIndexInBar: eventIndexInBar,
                mainBeatIndexInBar: mainBeatIndex(in: pattern, eventIndexInBar: eventIndexInBar)
            )
            let event = ScheduledBeatEvent(
                patternID: pattern.id,
                beatIndex: beat.index,
                accent: beat.accent,
                soundRole: soundRole,
                hostTimeNanoseconds: humanizedBeatTime
            )
            await timingRecorder.record(
                scheduledHostTimeNanoseconds: event.hostTimeNanoseconds,
                observedHostTimeNanoseconds: DispatchTime.now().uptimeNanoseconds
            )
            play(event: event)
            if let eventHandler {
                Task {
                    await eventHandler(event)
                }
            }

            let interval: UInt64
            do {
                interval = try scheduler.eventIntervalNanoseconds(for: pattern, eventOffset: beatOffset)
            } catch {
                await stop()
                break
            }
            beatOffset += 1
            nextBeatTime += interval
        }
    }

    private func humanizedHostTime(_ hostTime: UInt64, pattern: MetronomePattern, eventOffset: Int) -> UInt64 {
        guard settings.humanizationAmount > 0 else {
            return hostTime
        }

        let interval = (try? scheduler.eventIntervalNanoseconds(for: pattern, eventOffset: eventOffset)) ?? 0
        guard interval > 0 else {
            return hostTime
        }

        let maximumOffset = Double(interval) * 0.25 * settings.humanizationAmount
        let randomOffset = Swift.Double.random(in: (-maximumOffset)...maximumOffset)
        if randomOffset < 0 {
            return hostTime - min(hostTime, UInt64(abs(randomOffset).rounded()))
        }
        return hostTime + UInt64(randomOffset.rounded())
    }

    private func mainBeatIndex(in pattern: MetronomePattern, eventIndexInBar: Int) -> Int? {
        guard eventIndexInBar >= 0, eventIndexInBar < pattern.beats.count else {
            return nil
        }

        let role = pattern.beats[eventIndexInBar].soundRole
        guard role == .downbeat || role == .beat else {
            return nil
        }

        let mainPulseCount = pattern.beats.prefix(eventIndexInBar + 1).filter { beat in
            beat.soundRole == .downbeat || beat.soundRole == .beat
        }.count
        return mainPulseCount - 1
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

    private func makeClickBuffers(settings: MetronomeAudioSettings) throws -> [ClickSoundRole: AVAudioPCMBuffer] {
        let sampleRate = 48_000.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let profile = ClickProfile.profile(for: settings.soundPreset)
        let masterGain = Float(settings.masterGain)
        let accentBoost = Float(settings.accentBoost)
        let downbeatGain = Float(settings.downbeatGain)
        let beatGain = Float(settings.beatGain)
        let subdivisionGain = Float(settings.subdivisionGain)
        let cueGain = Float(settings.cueGain)

        return [
            .downbeat: try makeClickBuffer(format: format, frequency: profile.downbeatFrequency, duration: profile.downbeatDuration, gain: min(1.0, profile.downbeatGain * masterGain * accentBoost * downbeatGain), decayPower: profile.decayPower, noiseMix: profile.noiseMix),
            .beat: try makeClickBuffer(format: format, frequency: profile.beatFrequency, duration: profile.beatDuration, gain: profile.beatGain * masterGain * beatGain, decayPower: profile.decayPower, noiseMix: profile.noiseMix),
            .subdivision: try makeClickBuffer(format: format, frequency: profile.subdivisionFrequency, duration: profile.subdivisionDuration, gain: profile.subdivisionGain * masterGain * subdivisionGain, decayPower: profile.decayPower, noiseMix: profile.noiseMix),
            .cue: try makeClickBuffer(format: format, frequency: profile.cueFrequency, duration: profile.cueDuration, gain: profile.cueGain * masterGain * cueGain, decayPower: profile.decayPower, noiseMix: profile.noiseMix),
            .muted: try makeClickBuffer(format: format, frequency: 200, duration: 0.004, gain: 0.0)
        ]
    }

    private func makeClickBuffer(
        format: AVAudioFormat,
        frequency: Double,
        duration: Double,
        gain: Float,
        decayPower: Double = 4.0,
        noiseMix: Double = 0.0
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
            let envelope = Float(pow(1.0 - progress, decayPower))
            let sine = sin((Double(frame) / format.sampleRate) * frequency * 2.0 * Double.pi)
            let noise = deterministicNoise(frame: frame)
            let clampedNoiseMix = min(1.0, max(0.0, noiseMix))
            let sample = (sine * (1.0 - clampedNoiseMix)) + (noise * clampedNoiseMix)
            channel[frame] = Float(sample) * gain * envelope
        }

        return buffer
    }

    private func deterministicNoise(frame: Int) -> Double {
        var value = UInt64(frame + 1) &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        value ^= value >> 33
        return (Double(value % 20_001) / 10_000.0) - 1.0
    }
}

public enum AudioEngineError: Error, Equatable {
    case bufferCreationFailed
}

private struct ClickProfile {
    let downbeatFrequency: Double
    let beatFrequency: Double
    let subdivisionFrequency: Double
    let cueFrequency: Double
    let downbeatDuration: Double
    let beatDuration: Double
    let subdivisionDuration: Double
    let cueDuration: Double
    let downbeatGain: Float
    let beatGain: Float
    let subdivisionGain: Float
    let cueGain: Float
    let decayPower: Double
    let noiseMix: Double

    static func profile(for preset: ClickSoundPreset) -> ClickProfile {
        switch preset {
        case .classic:
            ClickProfile(
                downbeatFrequency: 1_600,
                beatFrequency: 1_050,
                subdivisionFrequency: 820,
                cueFrequency: 1_300,
                downbeatDuration: 0.035,
                beatDuration: 0.028,
                subdivisionDuration: 0.018,
                cueDuration: 0.05,
                downbeatGain: 0.85,
                beatGain: 0.62,
                subdivisionGain: 0.42,
                cueGain: 0.7,
                decayPower: 4.0,
                noiseMix: 0.0
            )
        case .hardClick:
            ClickProfile(
                downbeatFrequency: 2_600,
                beatFrequency: 2_100,
                subdivisionFrequency: 1_700,
                cueFrequency: 2_350,
                downbeatDuration: 0.018,
                beatDuration: 0.014,
                subdivisionDuration: 0.010,
                cueDuration: 0.024,
                downbeatGain: 0.88,
                beatGain: 0.66,
                subdivisionGain: 0.44,
                cueGain: 0.72,
                decayPower: 8.0,
                noiseMix: 0.18
            )
        case .wood:
            ClickProfile(
                downbeatFrequency: 720,
                beatFrequency: 560,
                subdivisionFrequency: 440,
                cueFrequency: 660,
                downbeatDuration: 0.032,
                beatDuration: 0.026,
                subdivisionDuration: 0.018,
                cueDuration: 0.04,
                downbeatGain: 0.8,
                beatGain: 0.58,
                subdivisionGain: 0.36,
                cueGain: 0.62,
                decayPower: 5.0,
                noiseMix: 0.04
            )
        case .clave:
            ClickProfile(
                downbeatFrequency: 1_450,
                beatFrequency: 1_120,
                subdivisionFrequency: 860,
                cueFrequency: 1_300,
                downbeatDuration: 0.034,
                beatDuration: 0.028,
                subdivisionDuration: 0.016,
                cueDuration: 0.040,
                downbeatGain: 0.82,
                beatGain: 0.60,
                subdivisionGain: 0.34,
                cueGain: 0.66,
                decayPower: 5.8,
                noiseMix: 0.10
            )
        case .rimshot:
            ClickProfile(
                downbeatFrequency: 2_900,
                beatFrequency: 2_400,
                subdivisionFrequency: 1_700,
                cueFrequency: 2_700,
                downbeatDuration: 0.026,
                beatDuration: 0.020,
                subdivisionDuration: 0.012,
                cueDuration: 0.032,
                downbeatGain: 0.86,
                beatGain: 0.64,
                subdivisionGain: 0.40,
                cueGain: 0.70,
                decayPower: 6.8,
                noiseMix: 0.34
            )
        case .cowbell:
            ClickProfile(
                downbeatFrequency: 1_900,
                beatFrequency: 1_540,
                subdivisionFrequency: 1_160,
                cueFrequency: 1_740,
                downbeatDuration: 0.065,
                beatDuration: 0.048,
                subdivisionDuration: 0.026,
                cueDuration: 0.060,
                downbeatGain: 0.78,
                beatGain: 0.56,
                subdivisionGain: 0.34,
                cueGain: 0.62,
                decayPower: 2.4,
                noiseMix: 0.06
            )
        case .hiHat:
            ClickProfile(
                downbeatFrequency: 6_800,
                beatFrequency: 5_600,
                subdivisionFrequency: 4_800,
                cueFrequency: 6_200,
                downbeatDuration: 0.030,
                beatDuration: 0.022,
                subdivisionDuration: 0.014,
                cueDuration: 0.032,
                downbeatGain: 0.62,
                beatGain: 0.48,
                subdivisionGain: 0.34,
                cueGain: 0.54,
                decayPower: 5.6,
                noiseMix: 0.82
            )
        case .shaker:
            ClickProfile(
                downbeatFrequency: 4_900,
                beatFrequency: 4_200,
                subdivisionFrequency: 3_800,
                cueFrequency: 4_600,
                downbeatDuration: 0.046,
                beatDuration: 0.036,
                subdivisionDuration: 0.024,
                cueDuration: 0.048,
                downbeatGain: 0.50,
                beatGain: 0.40,
                subdivisionGain: 0.30,
                cueGain: 0.46,
                decayPower: 4.6,
                noiseMix: 0.92
            )
        case .clap:
            ClickProfile(
                downbeatFrequency: 2_200,
                beatFrequency: 1_800,
                subdivisionFrequency: 1_400,
                cueFrequency: 2_000,
                downbeatDuration: 0.060,
                beatDuration: 0.045,
                subdivisionDuration: 0.026,
                cueDuration: 0.058,
                downbeatGain: 0.72,
                beatGain: 0.52,
                subdivisionGain: 0.30,
                cueGain: 0.60,
                decayPower: 3.2,
                noiseMix: 0.72
            )
        case .sine:
            ClickProfile(
                downbeatFrequency: 1_000,
                beatFrequency: 750,
                subdivisionFrequency: 500,
                cueFrequency: 900,
                downbeatDuration: 0.075,
                beatDuration: 0.055,
                subdivisionDuration: 0.032,
                cueDuration: 0.070,
                downbeatGain: 0.68,
                beatGain: 0.50,
                subdivisionGain: 0.32,
                cueGain: 0.56,
                decayPower: 2.2,
                noiseMix: 0.0
            )
        case .mellow:
            ClickProfile(
                downbeatFrequency: 880,
                beatFrequency: 660,
                subdivisionFrequency: 520,
                cueFrequency: 780,
                downbeatDuration: 0.060,
                beatDuration: 0.044,
                subdivisionDuration: 0.026,
                cueDuration: 0.058,
                downbeatGain: 0.58,
                beatGain: 0.44,
                subdivisionGain: 0.28,
                cueGain: 0.50,
                decayPower: 3.0,
                noiseMix: 0.02
            )
        case .bell:
            ClickProfile(
                downbeatFrequency: 2_100,
                beatFrequency: 1_420,
                subdivisionFrequency: 1_080,
                cueFrequency: 1_800,
                downbeatDuration: 0.055,
                beatDuration: 0.04,
                subdivisionDuration: 0.024,
                cueDuration: 0.06,
                downbeatGain: 0.78,
                beatGain: 0.52,
                subdivisionGain: 0.34,
                cueGain: 0.64,
                decayPower: 2.8,
                noiseMix: 0.0
            )
        case .mechanical:
            ClickProfile(
                downbeatFrequency: 1_250,
                beatFrequency: 920,
                subdivisionFrequency: 700,
                cueFrequency: 1_100,
                downbeatDuration: 0.022,
                beatDuration: 0.018,
                subdivisionDuration: 0.012,
                cueDuration: 0.03,
                downbeatGain: 0.9,
                beatGain: 0.66,
                subdivisionGain: 0.4,
                cueGain: 0.72,
                decayPower: 7.0,
                noiseMix: 0.12
            )
        }
    }
}
