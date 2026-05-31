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
        XCTAssertEqual(library.patterns.count, 6)
    }

    func testLibraryDuplicatesMixedSubdivisionPattern() throws {
        var library = MetronomeLibrary.defaultLibrary()
        let source = Pattern.mixedSubdivision(subdivisions: [.sixteenth, .quintuplet, .triplet, .eighth])
        library.appendPattern(source)

        let duplicate = try library.duplicateSelectedPattern(name: "Mixed Copy")

        XCTAssertEqual(duplicate.perBeatSubdivisions, source.perBeatSubdivisions)
        XCTAssertEqual(duplicate.stepDurationsInMeterBeats, source.stepDurationsInMeterBeats)
        XCTAssertEqual(duplicate.beats.count, source.beats.count)
    }

    func testLibraryDeletesPatternAndMovesSelection() throws {
        var library = MetronomeLibrary.defaultLibrary()
        let deletedID = library.selectedPatternID

        try library.deletePattern(id: deletedID)

        XCTAssertFalse(library.patterns.contains { $0.id == deletedID })
        XCTAssertNotEqual(library.selectedPatternID, deletedID)
        XCTAssertEqual(library.patterns.count, 4)
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

    func testStoreCreatesSnapshotBeforeOverwritingExistingLibrary() async throws {
        let fileURL = temporaryFileURL()
        let store = MetronomeLibraryStore(fileURL: fileURL)
        let originalLibrary = MetronomeLibrary.defaultLibrary()
        var updatedLibrary = originalLibrary
        var selectedPattern = updatedLibrary.selectedPattern
        selectedPattern.bpm = 88
        updatedLibrary.updateSelectedPattern(selectedPattern)

        try await store.save(originalLibrary)
        try await store.save(updatedLibrary)

        let snapshots = try await store.snapshotFileURLs()
        XCTAssertEqual(snapshots.count, 1)

        let snapshotData = try Data(contentsOf: snapshots[0])
        let snapshotLibrary = try JSONDecoder().decode(MetronomeLibrary.self, from: snapshotData)
        XCTAssertEqual(snapshotLibrary.selectedPattern.bpm, originalLibrary.selectedPattern.bpm)
    }

    func testStorePrunesOldSnapshots() async throws {
        let fileURL = temporaryFileURL()
        let store = MetronomeLibraryStore(fileURL: fileURL, snapshotLimit: 2)
        var library = MetronomeLibrary.defaultLibrary()
        try await store.save(library)

        for bpm in [88, 92, 96] {
            var selectedPattern = library.selectedPattern
            selectedPattern.bpm = bpm
            library.updateSelectedPattern(selectedPattern)
            try await store.save(library)
        }

        let snapshots = try await store.snapshotFileURLs()
        XCTAssertEqual(snapshots.count, 2)
    }

    func testStoreRestoreLatestSnapshotReplacesCurrentLibrary() async throws {
        let fileURL = temporaryFileURL()
        let store = MetronomeLibraryStore(fileURL: fileURL)
        var originalLibrary = MetronomeLibrary.defaultLibrary()
        var originalPattern = originalLibrary.selectedPattern
        originalPattern.bpm = 72
        originalLibrary.updateSelectedPattern(originalPattern)

        var updatedLibrary = originalLibrary
        var updatedPattern = updatedLibrary.selectedPattern
        updatedPattern.bpm = 180
        updatedLibrary.updateSelectedPattern(updatedPattern)

        try await store.save(originalLibrary)
        try await store.save(updatedLibrary)

        let restoredLibrary = try await store.restoreLatestSnapshot()

        XCTAssertEqual(restoredLibrary?.selectedPattern.bpm, 72)
        XCTAssertEqual(try await store.load().selectedPattern.bpm, 72)
    }

    func testStoreRestoreLatestSnapshotReturnsNilWhenMissing() async throws {
        let fileURL = temporaryFileURL()
        let store = MetronomeLibraryStore(fileURL: fileURL)

        let restoredLibrary = try await store.restoreLatestSnapshot()

        XCTAssertNil(restoredLibrary)
    }

    func testStoreExportsPortableLibraryDocument() async throws {
        let fileURL = temporaryFileURL()
        let store = MetronomeLibraryStore(fileURL: fileURL)
        let exportedAt = Date(timeIntervalSince1970: 1_800_000_000)

        _ = try await store.load()
        let data = try await store.exportLibrary(exportedAt: exportedAt)
        let exported = try JSONDecoder().decode(MetronomeLibraryExport.self, from: data)

        XCTAssertEqual(exported.formatVersion, MetronomeLibraryExport.currentFormatVersion)
        XCTAssertEqual(exported.exportedAt, exportedAt)
        XCTAssertEqual(exported.appName, "Pulsecraft")
        XCTAssertEqual(exported.library.selectedPattern.name, "Default 4/4")
    }

    func testStoreImportsPortableLibraryDocument() async throws {
        let fileURL = temporaryFileURL()
        let store = MetronomeLibraryStore(fileURL: fileURL)
        var library = MetronomeLibrary.defaultLibrary()
        var selectedPattern = library.selectedPattern
        selectedPattern.rename(to: "Imported")
        library.updateSelectedPattern(selectedPattern)
        let exported = MetronomeLibraryExport(
            exportedAt: Date(timeIntervalSince1970: 1_800_000_000),
            library: library
        )
        let data = try JSONEncoder().encode(exported)

        let imported = try await store.importLibrary(from: data)

        XCTAssertEqual(imported.selectedPattern.name, "Imported")
        XCTAssertEqual(try await store.load(), imported)
    }

    func testStoreSnapshotsExistingLibraryBeforeImport() async throws {
        let fileURL = temporaryFileURL()
        let store = MetronomeLibraryStore(fileURL: fileURL)
        let originalLibrary = MetronomeLibrary.defaultLibrary()
        var importedLibrary = originalLibrary
        var selectedPattern = importedLibrary.selectedPattern
        selectedPattern.rename(to: "Imported")
        importedLibrary.updateSelectedPattern(selectedPattern)
        let exported = MetronomeLibraryExport(library: importedLibrary)
        let data = try JSONEncoder().encode(exported)

        try await store.save(originalLibrary)
        _ = try await store.importLibrary(from: data)

        let snapshots = try await store.snapshotFileURLs()
        XCTAssertEqual(snapshots.count, 1)

        let snapshotData = try Data(contentsOf: snapshots[0])
        let snapshotLibrary = try JSONDecoder().decode(MetronomeLibrary.self, from: snapshotData)
        XCTAssertEqual(snapshotLibrary.selectedPattern.name, originalLibrary.selectedPattern.name)
    }

    func testStoreImportsRawLibraryForRecovery() async throws {
        let fileURL = temporaryFileURL()
        let store = MetronomeLibraryStore(fileURL: fileURL)
        var library = MetronomeLibrary.defaultLibrary()
        var selectedPattern = library.selectedPattern
        selectedPattern.bpm = 72
        library.updateSelectedPattern(selectedPattern)
        let data = try JSONEncoder().encode(library)

        let imported = try await store.importLibrary(from: data)

        XCTAssertEqual(imported.selectedPattern.bpm, 72)
    }

    func testStoreRejectsUnsupportedExportVersion() async {
        let fileURL = temporaryFileURL()
        let store = MetronomeLibraryStore(fileURL: fileURL)
        let exported = MetronomeLibraryExport(
            formatVersion: 999,
            exportedAt: Date(timeIntervalSince1970: 1_800_000_000),
            library: MetronomeLibrary.defaultLibrary()
        )
        let data = try! JSONEncoder().encode(exported)

        do {
            _ = try await store.importLibrary(from: data)
            XCTFail("Expected unsupported export version to be rejected.")
        } catch MetronomeLibraryStoreError.unsupportedExportVersion(999) {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
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
