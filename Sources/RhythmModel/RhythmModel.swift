import Foundation

public enum MetronomeValidationError: Error, Equatable {
    case bpmOutOfRange(Int)
    case unsupportedMeter(Int, Int)
    case invalidGrouping
    case invalidBeatIndex(Int)
    case emptySetlist
    case invalidSetlistMove
    case invalidSetlistItem
}

public struct Meter: Codable, Hashable, Sendable {
    public let beatsPerBar: Int
    public let beatUnit: Int
    public let grouping: [Int]

    public init(beatsPerBar: Int, beatUnit: Int, grouping: [Int]? = nil) throws {
        let resolvedGrouping = grouping ?? [beatsPerBar]
        guard Meter.supportedMeters.contains(MeterKey(beatsPerBar: beatsPerBar, beatUnit: beatUnit)) else {
            throw MetronomeValidationError.unsupportedMeter(beatsPerBar, beatUnit)
        }
        guard resolvedGrouping.reduce(0, +) == beatsPerBar, resolvedGrouping.allSatisfy({ $0 > 0 }) else {
            throw MetronomeValidationError.invalidGrouping
        }

        self.beatsPerBar = beatsPerBar
        self.beatUnit = beatUnit
        self.grouping = resolvedGrouping
    }

    public var displayName: String {
        "\(beatsPerBar)/\(beatUnit)"
    }

    public static let supportedMeters: Set<MeterKey> = [
        MeterKey(beatsPerBar: 2, beatUnit: 4),
        MeterKey(beatsPerBar: 3, beatUnit: 4),
        MeterKey(beatsPerBar: 4, beatUnit: 4),
        MeterKey(beatsPerBar: 5, beatUnit: 4),
        MeterKey(beatsPerBar: 5, beatUnit: 8),
        MeterKey(beatsPerBar: 6, beatUnit: 8),
        MeterKey(beatsPerBar: 7, beatUnit: 8),
        MeterKey(beatsPerBar: 7, beatUnit: 4),
        MeterKey(beatsPerBar: 9, beatUnit: 8),
        MeterKey(beatsPerBar: 11, beatUnit: 8),
        MeterKey(beatsPerBar: 12, beatUnit: 8)
    ]

    public static let fourFour = try! Meter(beatsPerBar: 4, beatUnit: 4)
    public static let sixEight = try! Meter(beatsPerBar: 6, beatUnit: 8, grouping: [3, 3])
    public static let sevenEight = try! Meter(beatsPerBar: 7, beatUnit: 8, grouping: [2, 2, 3])
}

public struct MeterKey: Codable, Hashable, Sendable {
    public let beatsPerBar: Int
    public let beatUnit: Int

    public init(beatsPerBar: Int, beatUnit: Int) {
        self.beatsPerBar = beatsPerBar
        self.beatUnit = beatUnit
    }
}

public enum Subdivision: String, CaseIterable, Codable, Hashable, Sendable {
    case quarter
    case eighth
    case triplet
    case sixteenth

    public var stepsPerBeat: Int {
        switch self {
        case .quarter: 1
        case .eighth: 2
        case .triplet: 3
        case .sixteenth: 4
        }
    }

    public var displayName: String {
        switch self {
        case .quarter: "Quarter"
        case .eighth: "Eighth"
        case .triplet: "Triplet"
        case .sixteenth: "Sixteenth"
        }
    }
}

public enum AccentLevel: String, CaseIterable, Codable, Hashable, Sendable {
    case strong
    case normal
    case ghost
    case muted

    public var next: AccentLevel {
        switch self {
        case .strong: .normal
        case .normal: .ghost
        case .ghost: .muted
        case .muted: .strong
        }
    }
}

public enum ClickSoundRole: String, CaseIterable, Codable, Hashable, Sendable {
    case downbeat
    case beat
    case subdivision
    case cue
    case muted
}

public enum GrooveTemplate: String, CaseIterable, Codable, Hashable, Sendable {
    case sonClave32
    case sonClave23
    case rumbaClave32
    case rumbaClave23
    case bossaClave
    case bossaClave23

    public var displayName: String {
        switch self {
        case .sonClave32: "Son Clave 3:2"
        case .sonClave23: "Son Clave 2:3"
        case .rumbaClave32: "Rumba Clave 3:2"
        case .rumbaClave23: "Rumba Clave 2:3"
        case .bossaClave: "Bossa Clave 3:2"
        case .bossaClave23: "Bossa Clave 2:3"
        }
    }

    public var defaultBPM: Int {
        switch self {
        case .sonClave32, .sonClave23, .rumbaClave32, .rumbaClave23: 96
        case .bossaClave, .bossaClave23: 132
        }
    }

    public var stepCount: Int {
        16
    }

    public var activeStepIndexes: Set<Int> {
        switch self {
        case .sonClave32: [0, 3, 6, 10, 12]
        case .sonClave23: [0, 2, 6, 9, 12]
        case .rumbaClave32: [0, 3, 7, 10, 12]
        case .rumbaClave23: [0, 2, 6, 9, 13]
        case .bossaClave: [0, 3, 6, 10, 13]
        case .bossaClave23: [0, 3, 7, 10, 13]
        }
    }
}

public enum GrooveMixerPreset: String, CaseIterable, Codable, Hashable, Sendable {
    case claveWithMetronome
    case claveOnly
    case metronomeOnly
    case claveMetronomeSubdivisions

    public var displayName: String {
        switch self {
        case .claveWithMetronome: "Clave + Click"
        case .claveOnly: "Clave Only"
        case .metronomeOnly: "Click Only"
        case .claveMetronomeSubdivisions: "Clave + Click + Subdivisions"
        }
    }

    public var includesClave: Bool {
        self != .metronomeOnly
    }

    public var includesMetronome: Bool {
        self != .claveOnly
    }

    public var includesSubdivisions: Bool {
        self == .claveMetronomeSubdivisions
    }
}

public enum ClaveModeTemplate: String, CaseIterable, Codable, Hashable, Sendable {
    case sonClave32
    case sonClave23
    case rumbaClave32
    case rumbaClave23
    case bossaClave32
    case bossaClave23
    case bembeBell68
    case fiveEightTwoThree
    case fiveEightThreeTwo
    case sevenEightTwoTwoThree
    case sevenEightThreeTwoTwo
    case nineEightTwoTwoTwoThree
    case elevenEightThreeThreeTwoThree

    public var displayName: String {
        switch self {
        case .sonClave32: "Son 3:2"
        case .sonClave23: "Son 2:3"
        case .rumbaClave32: "Rumba 3:2"
        case .rumbaClave23: "Rumba 2:3"
        case .bossaClave32: "Bossa 3:2"
        case .bossaClave23: "Bossa 2:3"
        case .bembeBell68: "Bembe 6/8"
        case .fiveEightTwoThree: "5/8 2-3"
        case .fiveEightThreeTwo: "5/8 3-2"
        case .sevenEightTwoTwoThree: "7/8 2-2-3"
        case .sevenEightThreeTwoTwo: "7/8 3-2-2"
        case .nineEightTwoTwoTwoThree: "9/8 2-2-2-3"
        case .elevenEightThreeThreeTwoThree: "11/8 3-3-2-3"
        }
    }

    public var defaultBPM: Int {
        switch self {
        case .bossaClave32, .bossaClave23: 132
        case .fiveEightTwoThree, .fiveEightThreeTwo, .sevenEightTwoTwoThree, .sevenEightThreeTwoTwo, .nineEightTwoTwoTwoThree, .elevenEightThreeThreeTwoThree: 108
        default: 96
        }
    }

    public var meter: Meter {
        switch self {
        case .sonClave32, .sonClave23, .rumbaClave32, .rumbaClave23, .bossaClave32, .bossaClave23:
            .fourFour
        case .bembeBell68:
            .sixEight
        case .fiveEightTwoThree:
            try! Meter(beatsPerBar: 5, beatUnit: 8, grouping: [2, 3])
        case .fiveEightThreeTwo:
            try! Meter(beatsPerBar: 5, beatUnit: 8, grouping: [3, 2])
        case .sevenEightTwoTwoThree:
            .sevenEight
        case .sevenEightThreeTwoTwo:
            try! Meter(beatsPerBar: 7, beatUnit: 8, grouping: [3, 2, 2])
        case .nineEightTwoTwoTwoThree:
            try! Meter(beatsPerBar: 9, beatUnit: 8, grouping: [2, 2, 2, 3])
        case .elevenEightThreeThreeTwoThree:
            try! Meter(beatsPerBar: 11, beatUnit: 8, grouping: [3, 3, 2, 3])
        }
    }

    public var subdivision: Subdivision {
        .sixteenth
    }

    public var stepCount: Int {
        switch meter.beatUnit {
        case 4: meter.beatsPerBar * 4
        default: meter.beatsPerBar * 2
        }
    }

    public var claveStepIndexes: Set<Int> {
        switch self {
        case .sonClave32: [0, 3, 6, 10, 12]
        case .sonClave23: [0, 2, 6, 9, 12]
        case .rumbaClave32: [0, 3, 7, 10, 12]
        case .rumbaClave23: [0, 2, 6, 9, 13]
        case .bossaClave32: [0, 3, 6, 10, 13]
        case .bossaClave23: [0, 3, 7, 10, 13]
        case .bembeBell68: [0, 3, 5, 7, 10]
        case .fiveEightTwoThree: [0, 3, 6, 8]
        case .fiveEightThreeTwo: [0, 3, 5, 8]
        case .sevenEightTwoTwoThree: [0, 3, 6, 8, 11]
        case .sevenEightThreeTwoTwo: [0, 3, 5, 8, 11]
        case .nineEightTwoTwoTwoThree: [0, 3, 6, 9, 12, 15]
        case .elevenEightThreeThreeTwoThree: [0, 3, 6, 10, 13, 16, 19]
        }
    }
}

public struct Beat: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let index: Int
    public var accent: AccentLevel
    public var soundRole: ClickSoundRole

    public init(
        id: UUID = UUID(),
        index: Int,
        accent: AccentLevel,
        soundRole: ClickSoundRole
    ) {
        self.id = id
        self.index = index
        self.accent = accent
        self.soundRole = soundRole
    }
}

public struct Pattern: Identifiable, Codable, Equatable, Sendable {
    public static let minimumBPM = 30
    public static let maximumBPM = 300

    public let id: UUID
    public var name: String
    public var bpm: Int
    public var meter: Meter
    public var subdivision: Subdivision
    public var beats: [Beat]
    public var grooveTemplate: GrooveTemplate?
    public var claveModeTemplate: ClaveModeTemplate?
    public var grooveMixerPreset: GrooveMixerPreset?

    public init(
        id: UUID = UUID(),
        name: String,
        bpm: Int,
        meter: Meter,
        subdivision: Subdivision,
        beats: [Beat]? = nil,
        grooveTemplate: GrooveTemplate? = nil,
        claveModeTemplate: ClaveModeTemplate? = nil,
        grooveMixerPreset: GrooveMixerPreset? = nil
    ) throws {
        try Pattern.validateBPM(bpm)

        self.id = id
        self.name = name
        self.bpm = bpm
        self.meter = meter
        self.subdivision = subdivision
        self.beats = beats ?? Pattern.generateBeats(for: meter)
        self.grooveTemplate = grooveTemplate
        self.claveModeTemplate = claveModeTemplate
        self.grooveMixerPreset = grooveMixerPreset
    }

    public static func validateBPM(_ bpm: Int) throws {
        guard minimumBPM...maximumBPM ~= bpm else {
            throw MetronomeValidationError.bpmOutOfRange(bpm)
        }
    }

    public static func generateBeats(for meter: Meter) -> [Beat] {
        var groupStarts: Set<Int> = [0]
        var cursor = 0
        for group in meter.grouping.dropLast() {
            cursor += group
            groupStarts.insert(cursor)
        }

        return (0..<meter.beatsPerBar).map { index in
            let isDownbeat = index == 0
            let isGroupStart = groupStarts.contains(index)
            let accent: AccentLevel = isDownbeat ? .strong : (isGroupStart ? .normal : .ghost)
            let role: ClickSoundRole = isDownbeat ? .downbeat : .beat
            return Beat(index: index, accent: accent, soundRole: role)
        }
    }

    public static func defaultFourFour(id: UUID = UUID()) -> Pattern {
        try! Pattern(id: id, name: "Default 4/4", bpm: 120, meter: .fourFour, subdivision: .quarter)
    }

    public static func defaultSixEight(id: UUID = UUID()) -> Pattern {
        try! Pattern(id: id, name: "Default 6/8", bpm: 96, meter: .sixEight, subdivision: .eighth)
    }

    public static func defaultSevenEight(id: UUID = UUID()) -> Pattern {
        try! Pattern(id: id, name: "Default 7/8", bpm: 110, meter: .sevenEight, subdivision: .eighth)
    }

    public static func groove(_ template: GrooveTemplate, id: UUID = UUID()) -> Pattern {
        try! Pattern(
            id: id,
            name: template.displayName,
            bpm: template.defaultBPM,
            meter: .fourFour,
            subdivision: .sixteenth,
            beats: Pattern.generateGrooveBeats(for: template),
            grooveTemplate: template
        )
    }

    public static func claveMode(
        _ template: ClaveModeTemplate,
        mixerPreset: GrooveMixerPreset = .claveWithMetronome,
        id: UUID = UUID()
    ) -> Pattern {
        try! Pattern(
            id: id,
            name: "\(template.displayName) \(mixerPreset.displayName)",
            bpm: template.defaultBPM,
            meter: template.meter,
            subdivision: template.subdivision,
            beats: Pattern.generateClaveModeBeats(for: template, mixerPreset: mixerPreset),
            claveModeTemplate: template,
            grooveMixerPreset: mixerPreset
        )
    }

    public static func generateGrooveBeats(for template: GrooveTemplate) -> [Beat] {
        (0..<template.stepCount).map { index in
            let isActive = template.activeStepIndexes.contains(index)
            let accent: AccentLevel = index == 0 ? .strong : (isActive ? .normal : .muted)
            let role: ClickSoundRole = index == 0 ? .downbeat : (isActive ? .beat : .muted)
            return Beat(index: index, accent: accent, soundRole: role)
        }
    }

    public static func generateClaveModeBeats(
        for template: ClaveModeTemplate,
        mixerPreset: GrooveMixerPreset
    ) -> [Beat] {
        let meter = template.meter
        let stepsPerBeat = template.stepCount / meter.beatsPerBar
        let metronomeStepIndexes = metronomeSteps(for: meter, stepsPerBeat: stepsPerBeat)

        return (0..<template.stepCount).map { index in
            let hasClave = mixerPreset.includesClave && template.claveStepIndexes.contains(index)
            let hasMetronome = mixerPreset.includesMetronome && metronomeStepIndexes.contains(index)
            let hasSubdivision = mixerPreset.includesSubdivisions

            let accent: AccentLevel
            let role: ClickSoundRole
            if (hasMetronome || hasClave) && index == 0 {
                accent = .strong
                role = .downbeat
            } else if hasClave || hasMetronome {
                accent = .normal
                role = .beat
            } else if hasSubdivision {
                accent = .ghost
                role = .subdivision
            } else {
                accent = .muted
                role = .muted
            }

            return Beat(index: index, accent: accent, soundRole: role)
        }
    }

    private static func metronomeSteps(for meter: Meter, stepsPerBeat: Int) -> Set<Int> {
        Set((0..<meter.beatsPerBar).map { $0 * stepsPerBeat })
    }

    public var eventIntervalDivisor: Int {
        guard beats.count > meter.beatsPerBar, beats.count.isMultiple(of: meter.beatsPerBar) else {
            return 1
        }
        return beats.count / meter.beatsPerBar
    }

    public mutating func rename(to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }
        self.name = trimmedName
    }

    public mutating func updateMeter(_ meter: Meter) {
        self.meter = meter
        beats = Pattern.generateBeats(for: meter)
        grooveTemplate = nil
        claveModeTemplate = nil
        grooveMixerPreset = nil
    }

    public mutating func updateSubdivision(_ subdivision: Subdivision) {
        self.subdivision = subdivision
        grooveTemplate = nil
        claveModeTemplate = nil
        grooveMixerPreset = nil
    }

    public mutating func cycleAccent(at index: Int) throws {
        guard beats.indices.contains(index) else {
            throw MetronomeValidationError.invalidBeatIndex(index)
        }

        beats[index].accent = beats[index].accent.next
        beats[index].soundRole = Pattern.soundRole(for: beats[index].accent, index: index)
    }

    public mutating func setAccent(_ accent: AccentLevel, at index: Int) throws {
        guard beats.indices.contains(index) else {
            throw MetronomeValidationError.invalidBeatIndex(index)
        }

        beats[index].accent = accent
        beats[index].soundRole = Pattern.soundRole(for: accent, index: index)
    }

    private static func soundRole(for accent: AccentLevel, index: Int) -> ClickSoundRole {
        switch accent {
        case .strong:
            index == 0 ? .downbeat : .beat
        case .normal:
            .beat
        case .ghost:
            .subdivision
        case .muted:
            .muted
        }
    }
}

public struct SetlistItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var patternID: Pattern.ID
    public var title: String
    public var position: Int

    public init(id: UUID = UUID(), patternID: Pattern.ID, title: String, position: Int) {
        self.id = id
        self.patternID = patternID
        self.title = title
        self.position = position
    }
}

public struct Setlist: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public private(set) var items: [SetlistItem]

    public init(id: UUID = UUID(), name: String, items: [SetlistItem] = []) {
        self.id = id
        self.name = name
        self.items = Setlist.normalize(items)
    }

    public mutating func append(pattern: Pattern, title: String? = nil) {
        let nextPosition = items.count
        items.append(SetlistItem(patternID: pattern.id, title: title ?? pattern.name, position: nextPosition))
    }

    public mutating func removeItem(id: SetlistItem.ID) throws {
        guard items.contains(where: { $0.id == id }) else {
            throw MetronomeValidationError.invalidSetlistItem
        }

        items.removeAll { $0.id == id }
        items = Setlist.normalize(items)
    }

    public mutating func removeItems(for patternID: Pattern.ID) {
        items.removeAll { $0.patternID == patternID }
        items = Setlist.normalize(items)
    }

    public mutating func move(from source: Int, to destination: Int) throws {
        guard items.indices.contains(source), destination >= 0, destination <= items.count else {
            throw MetronomeValidationError.invalidSetlistMove
        }
        var mutableItems = items
        let item = mutableItems.remove(at: source)
        let adjustedDestination = destination > source ? destination - 1 : destination
        mutableItems.insert(item, at: adjustedDestination)
        items = Setlist.normalize(mutableItems)
    }

    private static func normalize(_ items: [SetlistItem]) -> [SetlistItem] {
        items
            .enumerated()
            .map { offset, item in
                var updated = item
                updated.position = offset
                return updated
            }
    }
}

public struct PracticeTimer: Codable, Equatable, Sendable {
    public static let minimumDurationSeconds = 60
    public static let maximumDurationSeconds = 3_600

    public private(set) var durationSeconds: Int
    public private(set) var remainingSeconds: Int
    public private(set) var isRunning: Bool

    public init(durationSeconds: Int = 600, remainingSeconds: Int? = nil, isRunning: Bool = false) {
        let resolvedDuration = PracticeTimer.clampedDuration(durationSeconds)
        let resolvedRemaining = remainingSeconds ?? resolvedDuration

        self.durationSeconds = resolvedDuration
        self.remainingSeconds = min(resolvedDuration, max(0, resolvedRemaining))
        self.isRunning = isRunning && self.remainingSeconds > 0
    }

    public var formattedRemaining: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    public mutating func start() {
        if remainingSeconds == 0 {
            remainingSeconds = durationSeconds
        }
        isRunning = true
    }

    public mutating func pause() {
        isRunning = false
    }

    public mutating func reset() {
        remainingSeconds = durationSeconds
        isRunning = false
    }

    public mutating func selectDuration(seconds: Int) {
        durationSeconds = PracticeTimer.clampedDuration(seconds)
        remainingSeconds = durationSeconds
        isRunning = false
    }

    public mutating func tick(seconds: Int = 1) {
        guard isRunning, seconds > 0 else {
            return
        }

        remainingSeconds = max(0, remainingSeconds - seconds)
        if remainingSeconds == 0 {
            isRunning = false
        }
    }

    private static func clampedDuration(_ seconds: Int) -> Int {
        min(maximumDurationSeconds, max(minimumDurationSeconds, seconds))
    }
}

public struct TempoLadder: Codable, Equatable, Sendable {
    public static let minimumStepBPM = 1
    public static let maximumStepBPM = 20
    public static let minimumBarsPerStep = 1
    public static let maximumBarsPerStep = 16

    public private(set) var targetBPM: Int
    public private(set) var stepBPM: Int
    public private(set) var barsPerStep: Int
    public private(set) var barsCompleted: Int
    public private(set) var isEnabled: Bool

    public init(
        targetBPM: Int = 140,
        stepBPM: Int = 4,
        barsPerStep: Int = 4,
        barsCompleted: Int = 0,
        isEnabled: Bool = false
    ) {
        self.targetBPM = TempoLadder.clampedBPM(targetBPM)
        self.stepBPM = min(Self.maximumStepBPM, max(Self.minimumStepBPM, stepBPM))
        self.barsPerStep = min(Self.maximumBarsPerStep, max(Self.minimumBarsPerStep, barsPerStep))
        self.barsCompleted = min(self.barsPerStep, max(0, barsCompleted))
        self.isEnabled = isEnabled
    }

    public mutating func setTargetBPM(_ bpm: Int) {
        targetBPM = TempoLadder.clampedBPM(bpm)
        barsCompleted = 0
    }

    public mutating func setStepBPM(_ bpm: Int) {
        stepBPM = min(Self.maximumStepBPM, max(Self.minimumStepBPM, bpm))
        barsCompleted = 0
    }

    public mutating func setBarsPerStep(_ bars: Int) {
        barsPerStep = min(Self.maximumBarsPerStep, max(Self.minimumBarsPerStep, bars))
        barsCompleted = 0
    }

    public mutating func setEnabled(_ enabled: Bool, currentBPM: Int) {
        isEnabled = enabled && targetBPM != currentBPM
        barsCompleted = 0
    }

    public mutating func recordCompletedBar(currentBPM: Int) -> Int? {
        guard isEnabled else {
            return nil
        }

        guard currentBPM != targetBPM else {
            isEnabled = false
            barsCompleted = 0
            return nil
        }

        barsCompleted += 1
        guard barsCompleted >= barsPerStep else {
            return nil
        }

        barsCompleted = 0
        let direction = targetBPM > currentBPM ? 1 : -1
        let proposedBPM = currentBPM + (direction * stepBPM)
        let nextBPM = direction > 0 ? min(proposedBPM, targetBPM) : max(proposedBPM, targetBPM)

        if nextBPM == targetBPM {
            isEnabled = false
        }

        return nextBPM
    }

    private static func clampedBPM(_ bpm: Int) -> Int {
        min(Pattern.maximumBPM, max(Pattern.minimumBPM, bpm))
    }
}
