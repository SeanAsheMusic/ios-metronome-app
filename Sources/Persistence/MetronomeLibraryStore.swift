import Foundation
import AudioEngine
import RhythmModel

public struct MetronomeLibrary: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var selectedPatternID: Pattern.ID
    public var patterns: [Pattern]
    public var setlists: [Setlist]
    public var audioSettings: MetronomeAudioSettings

    public init(
        schemaVersion: Int = MetronomeLibrary.currentSchemaVersion,
        selectedPatternID: Pattern.ID,
        patterns: [Pattern],
        setlists: [Setlist],
        audioSettings: MetronomeAudioSettings = MetronomeAudioSettings()
    ) {
        self.schemaVersion = schemaVersion
        self.selectedPatternID = selectedPatternID
        self.patterns = patterns
        self.setlists = setlists
        self.audioSettings = audioSettings
    }

    public var selectedPattern: Pattern {
        patterns.first { $0.id == selectedPatternID } ?? patterns[0]
    }

    public var activeSetlist: Setlist {
        setlists.first ?? Setlist(name: "Practice")
    }

    public mutating func selectPattern(id: Pattern.ID) {
        guard patterns.contains(where: { $0.id == id }) else {
            return
        }
        selectedPatternID = id
    }

    public mutating func updateSelectedPattern(_ pattern: Pattern) {
        selectedPatternID = pattern.id

        if let index = patterns.firstIndex(where: { $0.id == pattern.id }) {
            patterns[index] = pattern
        } else {
            patterns.insert(pattern, at: 0)
        }
    }

    public mutating func appendPattern(_ pattern: Pattern) {
        if let index = patterns.firstIndex(where: { $0.id == pattern.id }) {
            patterns[index] = pattern
        } else {
            patterns.append(pattern)
        }
        selectedPatternID = pattern.id
    }

    public mutating func duplicateSelectedPattern(name: String? = nil) throws -> Pattern {
        let source = selectedPattern
        let duplicate = try Pattern(
            name: name ?? "\(source.name) Copy",
            bpm: source.bpm,
            meter: source.meter,
            subdivision: source.subdivision,
            beats: source.beats.enumerated().map { offset, beat in
                Beat(index: offset, accent: beat.accent, soundRole: beat.soundRole)
            }
        )
        appendPattern(duplicate)
        return duplicate
    }

    public mutating func deletePattern(id: Pattern.ID) throws {
        guard patterns.count > 1 else {
            throw MetronomeLibraryStoreError.emptyPatternLibrary
        }

        patterns.removeAll { $0.id == id }
        for index in setlists.indices {
            setlists[index].removeItems(for: id)
        }
        if selectedPatternID == id || !patterns.contains(where: { $0.id == selectedPatternID }) {
            selectedPatternID = patterns[0].id
        }
    }

    public mutating func appendSelectedPatternToActiveSetlist() {
        ensureActiveSetlist()
        setlists[0].append(pattern: selectedPattern)
    }

    public mutating func removeActiveSetlistItem(id: SetlistItem.ID) throws {
        ensureActiveSetlist()
        try setlists[0].removeItem(id: id)
    }

    public mutating func moveActiveSetlistItem(from source: Int, to destination: Int) throws {
        ensureActiveSetlist()
        try setlists[0].move(from: source, to: destination)
    }

    public mutating func selectPatternFromActiveSetlist(itemID: SetlistItem.ID) {
        guard let item = activeSetlist.items.first(where: { $0.id == itemID }) else {
            return
        }
        selectPattern(id: item.patternID)
    }

    public mutating func updateAudioSettings(_ settings: MetronomeAudioSettings) {
        audioSettings = settings
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
                Pattern.defaultSevenEight(),
                Pattern.groove(.sonClave32),
                Pattern.groove(.bossaClave)
            ],
            setlists: [starterSetlist],
            audioSettings: MetronomeAudioSettings()
        )
    }

    private mutating func ensureActiveSetlist() {
        if setlists.isEmpty {
            setlists = [Setlist(name: "Practice")]
        }
    }
}

public struct MetronomeLibraryExport: Codable, Equatable, Sendable {
    public static let currentFormatVersion = 1

    public var formatVersion: Int
    public var exportedAt: Date
    public var appName: String
    public var library: MetronomeLibrary

    public init(
        formatVersion: Int = MetronomeLibraryExport.currentFormatVersion,
        exportedAt: Date = Date(),
        appName: String = "Pulsecraft",
        library: MetronomeLibrary
    ) {
        self.formatVersion = formatVersion
        self.exportedAt = exportedAt
        self.appName = appName
        self.library = library
    }
}

public enum MetronomeLibraryStoreError: Error, Equatable {
    case emptyPatternLibrary
    case unsupportedSchemaVersion(Int)
    case unsupportedExportVersion(Int)
}

public actor MetronomeLibraryStore {
    private let fileURL: URL
    private let snapshotDirectoryURL: URL
    private let snapshotLimit: Int
    private let dateProvider: @Sendable () -> Date
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        fileURL: URL,
        snapshotLimit: Int = 5,
        dateProvider: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.fileURL = fileURL
        self.snapshotDirectoryURL = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("MetronomeLibrarySnapshots", isDirectory: true)
        self.snapshotLimit = max(0, snapshotLimit)
        self.dateProvider = dateProvider

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
        try createSnapshotIfNeeded()

        let data = try encoder.encode(library)
        try data.write(to: fileURL, options: [.atomic])
    }

    public func replaceSelectedPattern(_ pattern: Pattern) throws -> MetronomeLibrary {
        var library = try load()
        library.updateSelectedPattern(pattern)
        try save(library)
        return library
    }

    public func exportLibrary(exportedAt: Date = Date()) throws -> Data {
        let library = try load()
        let export = MetronomeLibraryExport(exportedAt: exportedAt, library: library)
        return try encoder.encode(export)
    }

    public func importLibrary(from data: Data) throws -> MetronomeLibrary {
        let library: MetronomeLibrary

        if let export = try? decoder.decode(MetronomeLibraryExport.self, from: data) {
            guard export.formatVersion == MetronomeLibraryExport.currentFormatVersion else {
                throw MetronomeLibraryStoreError.unsupportedExportVersion(export.formatVersion)
            }
            library = export.library
        } else {
            library = try decoder.decode(MetronomeLibrary.self, from: data)
        }

        try validate(library)
        try save(library)
        return library
    }

    public func snapshotFileURLs() throws -> [URL] {
        guard FileManager.default.fileExists(atPath: snapshotDirectoryURL.path) else {
            return []
        }

        return try FileManager.default.contentsOfDirectory(
            at: snapshotDirectoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension == "json" }
        .sorted { first, second in
            first.lastPathComponent > second.lastPathComponent
        }
    }

    private func validate(_ library: MetronomeLibrary) throws {
        guard library.schemaVersion == MetronomeLibrary.currentSchemaVersion else {
            throw MetronomeLibraryStoreError.unsupportedSchemaVersion(library.schemaVersion)
        }
        guard !library.patterns.isEmpty else {
            throw MetronomeLibraryStoreError.emptyPatternLibrary
        }
    }

    private func createSnapshotIfNeeded() throws {
        guard snapshotLimit > 0, FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        try FileManager.default.createDirectory(
            at: snapshotDirectoryURL,
            withIntermediateDirectories: true
        )

        let milliseconds = Int(dateProvider().timeIntervalSince1970 * 1_000)
        let snapshotURL = snapshotDirectoryURL
            .appendingPathComponent("MetronomeLibrary-\(milliseconds)-\(UUID().uuidString).json")
        try FileManager.default.copyItem(at: fileURL, to: snapshotURL)
        try pruneSnapshots()
    }

    private func pruneSnapshots() throws {
        let snapshots = try snapshotFileURLs()
        guard snapshots.count > snapshotLimit else {
            return
        }

        for snapshot in snapshots.dropFirst(snapshotLimit) {
            try FileManager.default.removeItem(at: snapshot)
        }
    }

}
