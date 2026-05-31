import Foundation
import RhythmModel

public struct MetronomeLibrary: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var selectedPatternID: Pattern.ID
    public var patterns: [Pattern]
    public var setlists: [Setlist]

    public init(
        schemaVersion: Int = MetronomeLibrary.currentSchemaVersion,
        selectedPatternID: Pattern.ID,
        patterns: [Pattern],
        setlists: [Setlist]
    ) {
        self.schemaVersion = schemaVersion
        self.selectedPatternID = selectedPatternID
        self.patterns = patterns
        self.setlists = setlists
    }

    public var selectedPattern: Pattern {
        patterns.first { $0.id == selectedPatternID } ?? patterns[0]
    }

    public mutating func updateSelectedPattern(_ pattern: Pattern) {
        selectedPatternID = pattern.id

        if let index = patterns.firstIndex(where: { $0.id == pattern.id }) {
            patterns[index] = pattern
        } else {
            patterns.insert(pattern, at: 0)
        }
    }

    public static func defaultLibrary() -> MetronomeLibrary {
        let defaultPattern = Pattern.defaultFourFour()
        var starterSetlist = Setlist(name: "Practice")
        starterSetlist.append(pattern: defaultPattern)

        return MetronomeLibrary(
            selectedPatternID: defaultPattern.id,
            patterns: [
                defaultPattern,
                Pattern.defaultSixEight(),
                Pattern.defaultSevenEight()
            ],
            setlists: [starterSetlist]
        )
    }
}

public enum MetronomeLibraryStoreError: Error, Equatable {
    case emptyPatternLibrary
    case unsupportedSchemaVersion(Int)
}

public actor MetronomeLibraryStore {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL) {
        self.fileURL = fileURL

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        self.decoder = JSONDecoder()
    }

    public static func live(filename: String = "MetronomeLibrary.json") throws -> MetronomeLibraryStore {
        let directory = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return MetronomeLibraryStore(fileURL: directory.appendingPathComponent(filename))
    }

    public func load() throws -> MetronomeLibrary {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let library = MetronomeLibrary.defaultLibrary()
            try save(library)
            return library
        }

        let data = try Data(contentsOf: fileURL)
        let library = try decoder.decode(MetronomeLibrary.self, from: data)
        try validate(library)
        return library
    }

    public func save(_ library: MetronomeLibrary) throws {
        try validate(library)

        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let data = try encoder.encode(library)
        try data.write(to: fileURL, options: [.atomic])
    }

    public func replaceSelectedPattern(_ pattern: Pattern) throws -> MetronomeLibrary {
        var library = try load()
        library.updateSelectedPattern(pattern)
        try save(library)
        return library
    }

    private func validate(_ library: MetronomeLibrary) throws {
        guard library.schemaVersion == MetronomeLibrary.currentSchemaVersion else {
            throw MetronomeLibraryStoreError.unsupportedSchemaVersion(library.schemaVersion)
        }
        guard !library.patterns.isEmpty else {
            throw MetronomeLibraryStoreError.emptyPatternLibrary
        }
    }
}
