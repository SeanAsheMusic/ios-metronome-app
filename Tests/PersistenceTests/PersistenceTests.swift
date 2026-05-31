import XCTest
@testable import AudioEngine
@testable import Persistence
@testable import RhythmModel

final class PersistenceTests: XCTestCase {
    func testDefaultLibraryHasPatternsAndSelectedPattern() {
        let library = MetronomeLibrary.defaultLibrary()

        XCTAssertEqual(library.schemaVersion, MetronomeLibrary.currentSchemaVersion)
        XCTAssertFalse(library.patterns.isEmpty)
        XCTAssertEqual(library.selectedPattern.id, library.selectedPatternID)
        XCTAssertEqual(library.setlists.first?.items.first?.patternID, library.selectedPatternID)
        XCTAssertEqual(library.audioSettings, MetronomeAudioSettings())
    }

    func testLibraryUpdatesSelectedPatternInPlace() {
        var library = MetronomeLibrary.defaultLibrary()
        var selectedPattern = library.selectedPattern

        selectedPattern.bpm = 144
        library.updateSelectedPattern(selectedPattern)

        XCTAssertEqual(library.selectedPatternID, selectedPattern.id)
        XCTAssertEqual(library.selectedPattern.bpm, 144)
        XCTAssertEqual(library.patterns.filter { $0.id == selectedPattern.id }.count, 1)
    }

    func testLibrarySelectsExistingPattern() {
        var library = MetronomeLibrary.defaultLibrary()
        let nextPattern = library.patterns[1]

        library.selectPattern(id: nextPattern.id)

        XCTAssertEqual(library.selectedPatternID, nextPattern.id)
        XCTAssertEqual(library.selectedPattern, nextPattern)
    }

    func testLibraryIgnoresUnknownSelection() {
        var library = MetronomeLibrary.defaultLibrary()
        let originalSelection = library.selectedPatternID

        library.selectPattern(id: UUID())

        XCTAssertEqual(library.selectedPatternID, originalSelection)
    }

    func testLibraryDuplicatesSelectedPattern() throws {
        var library = MetronomeLibrary.defaultLibrary()
        let source = library.selectedPattern

        let duplicate = try library.duplicateSelectedPattern(name: "Stage Copy")

        XCTAssertEqual(duplicate.name, "Stage Copy")
        XCTAssertEqual(duplicate.bpm, source.bpm)
        XCTAssertEqual(duplicate.meter, source.meter)
        XCTAssertEqual(duplicate.subdivision, source.subdivision)
        XCTAssertNotEqual(duplicate.id, source.id)
        XCTAssertEqual(library.selectedPatternID, duplicate.id)
        XCTAssertEqual(library.patterns.count, 4)
    }

    func testLibraryDeletesPatternAndMovesSelection() throws {
        var library = MetronomeLibrary.defaultLibrary()
        let deletedID = library.selectedPatternID

        try library.deletePattern(id: deletedID)

        XCTAssertFalse(library.patterns.contains { $0.id == deletedID })
        XCTAssertNotEqual(library.selectedPatternID, deletedID)
        XCTAssertEqual(library.patterns.count, 2)
    }

    func testLibraryDeletePatternRemovesSetlistReferences() throws {
        var library = MetronomeLibrary.defaultLibrary()
        let deletedID = library.selectedPatternID
        library.appendSelectedPatternToActiveSetlist()

        try library.deletePattern(id: deletedID)

        XCTAssertFalse(library.activeSetlist.items.contains { $0.patternID == deletedID })
    }

    func testLibraryDoesNotDeleteLastPattern() throws {
        var library = MetronomeLibrary.defaultLibrary()
        for pattern in library.patterns.dropFirst() {
            try library.deletePattern(id: pattern.id)
        }

        XCTAssertThrowsError(try library.deletePattern(id: library.selectedPatternID))
    }

    func testLibraryAppendsSelectedPatternToActiveSetlist() {
        var library = MetronomeLibrary.defaultLibrary()
        let initialCount = library.activeSetlist.items.count

        library.appendSelectedPatternToActiveSetlist()

        XCTAssertEqual(library.activeSetlist.items.count, initialCount + 1)
        XCTAssertEqual(library.activeSetlist.items.last?.patternID, library.selectedPatternID)
    }

    func testLibraryMovesActiveSetlistItem() throws {
        var library = MetronomeLibrary.defaultLibrary()
        library.selectPattern(id: library.patterns[1].id)
        library.appendSelectedPatternToActiveSetlist()
        library.selectPattern(id: library.patterns[2].id)
        library.appendSelectedPatternToActiveSetlist()

        try library.moveActiveSetlistItem(from: 2, to: 0)

        XCTAssertEqual(library.activeSetlist.items.map(\.patternID), [
            library.patterns[2].id,
            library.patterns[0].id,
            library.patterns[1].id
        ])
        XCTAssertEqual(library.activeSetlist.items.map(\.position), [0, 1, 2])
    }

    func testLibraryRemovesActiveSetlistItem() throws {
        var library = MetronomeLibrary.defaultLibrary()
        let itemID = library.activeSetlist.items[0].id

        try library.removeActiveSetlistItem(id: itemID)

        XCTAssertTrue(library.activeSetlist.items.isEmpty)
    }

    func testLibrarySelectsPatternFromActiveSetlistItem() {
        var library = MetronomeLibrary.defaultLibrary()
        let nextPattern = library.patterns[1]
        library.selectPattern(id: nextPattern.id)
        library.appendSelectedPatternToActiveSetlist()
        let itemID = library.activeSetlist.items.last!.id
        library.selectPattern(id: library.patterns[0].id)

        library.selectPatternFromActiveSetlist(itemID: itemID)

        XCTAssertEqual(library.selectedPatternID, nextPattern.id)
    }

    func testLibraryUpdatesAudioSettings() {
        var library = MetronomeLibrary.defaultLibrary()
        let settings = MetronomeAudioSettings(soundPreset: .wood, masterGain: 0.35, accentBoost: 1.25)

        library.updateAudioSettings(settings)

        XCTAssertEqual(library.audioSettings, settings)
    }

    func testStoreCreatesDefaultLibraryWhenFileIsMissing() async throws {
        let fileURL = temporaryFileURL()
        let store = MetronomeLibraryStore(fileURL: fileURL)

        let library = try await store.load()

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(library.selectedPattern.name, "Default 4/4")
    }

    func testStoreRoundTripsLibrary() async throws {
        let fileURL = temporaryFileURL()
        let store = MetronomeLibraryStore(fileURL: fileURL)
        var library = MetronomeLibrary.defaultLibrary()
        var selectedPattern = library.selectedPattern
        selectedPattern.bpm = 88
        library.updateSelectedPattern(selectedPattern)

        try await store.save(library)
        let loadedLibrary = try await store.load()

        XCTAssertEqual(loadedLibrary, library)
        XCTAssertEqual(loadedLibrary.selectedPattern.bpm, 88)
    }

    func testStoreRejectsEmptyPatternLibrary() async {
        let fileURL = temporaryFileURL()
        let store = MetronomeLibraryStore(fileURL: fileURL)
        let library = MetronomeLibrary(
            selectedPatternID: UUID(),
            patterns: [],
            setlists: []
        )

        do {
            try await store.save(library)
            XCTFail("Expected empty pattern library to be rejected.")
        } catch MetronomeLibraryStoreError.emptyPatternLibrary {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("MetronomeLibrary.json")
    }
}
