import XCTest
@testable import Persistence
@testable import RhythmModel

final class PersistenceTests: XCTestCase {
    func testDefaultLibraryHasPatternsAndSelectedPattern() {
        let library = MetronomeLibrary.defaultLibrary()

        XCTAssertEqual(library.schemaVersion, MetronomeLibrary.currentSchemaVersion)
        XCTAssertFalse(library.patterns.isEmpty)
        XCTAssertEqual(library.selectedPattern.id, library.selectedPatternID)
        XCTAssertEqual(library.setlists.first?.items.first?.patternID, library.selectedPatternID)
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
