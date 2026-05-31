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
        MeterKey(beatsPerBar: 6, beatUnit: 8),
        MeterKey(beatsPerBar: 7, beatUnit: 8),
        MeterKey(beatsPerBar: 7, beatUnit: 4),
        MeterKey(beatsPerBar: 9, beatUnit: 8),
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

    public init(
        id: UUID = UUID(),
        name: String,
        bpm: Int,
        meter: Meter,
        subdivision: Subdivision,
        beats: [Beat]? = nil
    ) throws {
        try Pattern.validateBPM(bpm)

        self.id = id
        self.name = name
        self.bpm = bpm
        self.meter = meter
        self.subdivision = subdivision
        self.beats = beats ?? Pattern.generateBeats(for: meter)
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
    }

    public mutating func updateSubdivision(_ subdivision: Subdivision) {
        self.subdivision = subdivision
    }

    public mutating func cycleAccent(at index: Int) throws {
        guard beats.indices.contains(index) else {
            throw MetronomeValidationError.invalidBeatIndex(index)
        }

        beats[index].accent = beats[index].accent.next
        beats[index].soundRole = Pattern.soundRole(for: beats[index].accent, index: index)
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
