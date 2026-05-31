import SwiftUI
import UniformTypeIdentifiers
import AudioEngine
import Persistence
import RhythmModel

struct MainMetronomeView: View {
    @StateObject private var viewModel = MainMetronomeViewModel()
    @State private var exportDocument = LibraryExportDocument(data: Data())
    @State private var isExportingLibrary = false
    @State private var isImportingLibrary = false

    var body: some View {
        TabView {
            playTab
                .tabItem {
                    Label("Play", systemImage: "metronome")
                }

            editTab
                .tabItem {
                    Label("Edit", systemImage: "slider.horizontal.3")
                }

            libraryTab
                .tabItem {
                    Label("Patterns", systemImage: "music.note.list")
                }

            setlistTab
                .tabItem {
                    Label("Setlist", systemImage: "list.bullet.rectangle")
                }

            settingsTab
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.prepare()
        }
        .fileExporter(
            isPresented: $isExportingLibrary,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "Pulsecraft-Library.json"
        ) { result in
            viewModel.handleExportResult(result)
        }
        .fileImporter(
            isPresented: $isImportingLibrary,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            Task {
                await viewModel.handleImportResult(result)
            }
        }
    }

    private var playTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                bpmDisplay
                transportControls
                tempoControls
                patternSummary
                practicePanel
                visualPulse
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground))
    }

    private var editTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                patternEditor
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground))
    }

    private var libraryTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                patternLibrary
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground))
    }

    private var setlistTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                setlistPanel
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground))
    }

    private var settingsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                VStack(alignment: .leading, spacing: 14) {
                    Text("Sound")
                        .font(.headline)

                    Picker("Click Sound", selection: Binding(
                        get: { viewModel.audioSettings.soundPreset },
                        set: { preset in
                            Task {
                                await viewModel.updateSoundPreset(preset)
                            }
                        }
                    )) {
                        ForEach(ClickSoundPreset.allCases, id: \.self) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Click sound")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Volume")
                            .font(.subheadline.weight(.semibold))
                        Slider(value: Binding(
                            get: { viewModel.audioSettings.masterGain },
                            set: { value in
                                Task {
                                    await viewModel.updateMasterGain(value)
                                }
                            }
                        ), in: 0...1)
                        .accessibilityLabel("Master volume")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accent")
                            .font(.subheadline.weight(.semibold))
                        Slider(value: Binding(
                            get: { viewModel.audioSettings.accentBoost },
                            set: { value in
                                Task {
                                    await viewModel.updateAccentBoost(value)
                                }
                            }
                        ), in: 0.5...1.5)
                        .accessibilityLabel("Accent boost")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Output")
                            .font(.subheadline.weight(.semibold))

                        HStack(spacing: 10) {
                            Image(systemName: viewModel.audioRouteSymbolName)
                                .font(.headline)
                                .frame(width: 28, height: 28)
                                .foregroundStyle(viewModel.audioRouteTint)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.audioRouteStatus.outputName)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Text(viewModel.audioRouteStatus.message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                Task {
                                    await viewModel.refreshAudioRouteStatus()
                                }
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                                    .labelStyle(.iconOnly)
                                    .frame(width: 40, height: 40)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Refresh audio output")
                        }
                        .padding(10)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Audio output \(viewModel.audioRouteStatus.outputName), \(viewModel.audioRouteStatus.latencyRisk.displayName), \(viewModel.audioRouteStatus.message)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Data")
                        .font(.headline)

                    HStack(spacing: 12) {
                        Button {
                            Task {
                                if let data = await viewModel.makeLibraryExportData() {
                                    exportDocument = LibraryExportDocument(data: data)
                                    isExportingLibrary = true
                                }
                            }
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Export library")

                        Button {
                            isImportingLibrary = true
                        } label: {
                            Label("Import", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Import library")
                    }

                    if let message = viewModel.dataTransferMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel(message)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground))
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(viewModel.pattern.name)
                .font(.title3.weight(.semibold))
                .accessibilityLabel("Pattern \(viewModel.pattern.name)")

            Text("\(viewModel.pattern.meter.displayName) · \(viewModel.pattern.subdivision.displayName)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Meter \(viewModel.pattern.meter.displayName), subdivision \(viewModel.pattern.subdivision.displayName)")
        }
    }

    private var bpmDisplay: some View {
        VStack(spacing: 4) {
            Text("\(viewModel.pattern.bpm)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.65)
                .accessibilityLabel("\(viewModel.pattern.bpm) beats per minute")

            Text("BPM")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var transportControls: some View {
        HStack(spacing: 16) {
            Button {
                Task {
                    await viewModel.togglePlayback()
                }
            } label: {
                Label(viewModel.isPlaying ? "Stop" : "Play", systemImage: viewModel.isPlaying ? "stop.fill" : "play.fill")
                    .frame(maxWidth: .infinity, minHeight: 64)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel(viewModel.isPlaying ? "Stop metronome" : "Play metronome")

            Button {
                viewModel.registerTapTempo()
            } label: {
                Label("Tap", systemImage: "hand.tap.fill")
                    .frame(maxWidth: .infinity, minHeight: 64)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityLabel("Tap tempo")
            .accessibilityHint("Sets tempo from recent taps.")
        }
    }

    private var tempoControls: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                tempoButton(label: "-5", delta: -5)
                tempoButton(label: "-1", delta: -1)
                tempoButton(label: "+1", delta: 1)
                tempoButton(label: "+5", delta: 5)
            }
        }
    }

    private func tempoButton(label: String, delta: Int) -> some View {
        Button(label) {
            Task {
                await viewModel.updateBPM(by: delta)
            }
        }
        .font(.title3.weight(.semibold))
        .frame(minWidth: 64, minHeight: 56)
        .buttonStyle(.bordered)
        .accessibilityLabel(delta > 0 ? "Increase tempo by \(delta)" : "Decrease tempo by \(abs(delta))")
    }

    private var patternSummary: some View {
        HStack(spacing: 12) {
            summaryPill(title: "Meter", value: viewModel.pattern.meter.displayName)
            summaryPill(title: "Subdivision", value: viewModel.pattern.subdivision.displayName)
            summaryPill(title: "Saved", value: "\(viewModel.patterns.count)")
            summaryPill(title: "Setlist", value: "\(viewModel.activeSetlist.items.count)")
        }
    }

    private func summaryPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var practicePanel: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Practice")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(viewModel.practiceTimer.formattedRemaining)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Practice timer \(viewModel.practiceTimer.formattedRemaining)")

                Button {
                    viewModel.togglePracticeTimer()
                } label: {
                    Label(viewModel.practiceTimer.isRunning ? "Pause" : "Start", systemImage: viewModel.practiceTimer.isRunning ? "pause.fill" : "play.fill")
                        .labelStyle(.iconOnly)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(viewModel.practiceTimer.isRunning ? "Pause practice timer" : "Start practice timer")

                Button {
                    viewModel.resetPracticeTimer()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .labelStyle(.iconOnly)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Reset practice timer")
            }

            HStack(spacing: 8) {
                practiceDurationButton(minutes: 5)
                practiceDurationButton(minutes: 10)
                practiceDurationButton(minutes: 20)
            }
        }
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func practiceDurationButton(minutes: Int) -> some View {
        Button("\(minutes)m") {
            viewModel.setPracticeDuration(minutes: minutes)
        }
        .font(.subheadline.weight(.semibold))
        .frame(maxWidth: .infinity, minHeight: 40)
        .buttonStyle(.bordered)
        .accessibilityLabel("Set practice timer to \(minutes) minutes")
    }

    private var patternEditor: some View {
        VStack(spacing: 12) {
            TextField("Pattern name", text: $viewModel.patternNameDraft)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit {
                    Task {
                        await viewModel.commitPatternName()
                    }
                }
                .accessibilityLabel("Pattern name")

            HStack(spacing: 12) {
                Picker("Meter", selection: Binding(
                    get: { viewModel.selectedMeterOption },
                    set: { option in
                        Task {
                            await viewModel.updateMeter(option)
                        }
                    }
                )) {
                    ForEach(MainMetronomeViewModel.meterOptions) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Meter")

                Picker("Subdivision", selection: Binding(
                    get: { viewModel.pattern.subdivision },
                    set: { subdivision in
                        Task {
                            await viewModel.updateSubdivision(subdivision)
                        }
                    }
                )) {
                    ForEach(Subdivision.allCases, id: \.self) { subdivision in
                        Text(subdivision.displayName).tag(subdivision)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Subdivision")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.pattern.beats) { beat in
                        Button {
                            Task {
                                await viewModel.cycleAccent(at: beat.index)
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(beat.index + 1)")
                                    .font(.caption.weight(.bold))
                                Text(viewModel.shortLabel(for: beat.accent))
                                    .font(.caption2.weight(.semibold))
                            }
                            .frame(width: 44, height: 46)
                        }
                        .buttonStyle(.bordered)
                        .tint(viewModel.tint(for: beat.accent))
                        .accessibilityLabel("Beat \(beat.index + 1), \(viewModel.accessibilityLabel(for: beat.accent))")
                        .accessibilityHint("Cycles accent level")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var patternLibrary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Patterns")
                    .font(.headline)
                Spacer()
                Button {
                    Task {
                        await viewModel.deleteCurrentPattern()
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!viewModel.canDeleteCurrentPattern)
                .accessibilityLabel("Delete current pattern")

                Button {
                    Task {
                        await viewModel.duplicateCurrentPattern()
                    }
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Duplicate current pattern")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.patterns) { pattern in
                        Button {
                            Task {
                                await viewModel.selectPattern(id: pattern.id)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pattern.name)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Text("\(pattern.bpm) BPM · \(pattern.meter.displayName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 148, height: 58, alignment: .leading)
                            .padding(.horizontal, 12)
                            .background(
                                pattern.id == viewModel.pattern.id ? Color.accentColor.opacity(0.22) : Color.secondary.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(pattern.name), \(pattern.bpm) beats per minute")
                        .accessibilityValue(pattern.id == viewModel.pattern.id ? "Selected" : "Not selected")
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var setlistPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(viewModel.activeSetlist.name)
                    .font(.headline)
                Spacer()
                Button {
                    Task {
                        await viewModel.addCurrentPatternToSetlist()
                    }
                } label: {
                    Label("Add", systemImage: "text.badge.plus")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Add current pattern to setlist")
            }

            if viewModel.activeSetlist.items.isEmpty {
                Text("No setlist items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(viewModel.activeSetlist.items.enumerated()), id: \.element.id) { offset, item in
                            setlistItemButton(item: item, offset: offset)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func setlistItemButton(item: SetlistItem, offset: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Task {
                    await viewModel.selectSetlistItem(id: item.id)
                }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(offset + 1). \(item.title)")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(viewModel.patternSummary(for: item.patternID))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(width: 176, height: 52, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Setlist item \(offset + 1), \(item.title)")

            HStack(spacing: 6) {
                Button {
                    Task {
                        await viewModel.moveSetlistItem(from: offset, to: max(0, offset - 1))
                    }
                } label: {
                    Label("Earlier", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .disabled(offset == 0)
                .accessibilityLabel("Move \(item.title) earlier")

                Button {
                    Task {
                        await viewModel.moveSetlistItem(from: offset, to: min(viewModel.activeSetlist.items.count, offset + 2))
                    }
                } label: {
                    Label("Later", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .disabled(offset == viewModel.activeSetlist.items.count - 1)
                .accessibilityLabel("Move \(item.title) later")

                Button {
                    Task {
                        await viewModel.removeSetlistItem(id: item.id)
                    }
                } label: {
                    Label("Remove", systemImage: "trash")
                        .labelStyle(.iconOnly)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .accessibilityLabel("Remove \(item.title) from setlist")
            }
        }
        .padding(10)
        .background(
            item.patternID == viewModel.pattern.id ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.1),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private var visualPulse: some View {
        Circle()
            .fill(viewModel.pulseIsActive ? Color.accentColor : Color.secondary.opacity(0.3))
            .frame(width: 112, height: 112)
            .scaleEffect(viewModel.pulseIsActive ? 1.0 : 0.82)
            .animation(.snappy(duration: 0.18), value: viewModel.pulseIsActive)
            .accessibilityLabel("Visual pulse")
            .accessibilityValue(viewModel.pulseIsActive ? "Active" : "Inactive")
    }
}

@MainActor
final class MainMetronomeViewModel: ObservableObject {
    struct MeterOption: Identifiable, Hashable {
        let beatsPerBar: Int
        let beatUnit: Int
        let grouping: [Int]?

        var id: String {
            "\(beatsPerBar)/\(beatUnit)-\(grouping?.map(String.init).joined(separator: "-") ?? "default")"
        }

        var label: String {
            "\(beatsPerBar)/\(beatUnit)"
        }

        var meter: Meter {
            try! Meter(beatsPerBar: beatsPerBar, beatUnit: beatUnit, grouping: grouping)
        }
    }

    static let meterOptions: [MeterOption] = [
        MeterOption(beatsPerBar: 2, beatUnit: 4, grouping: nil),
        MeterOption(beatsPerBar: 3, beatUnit: 4, grouping: nil),
        MeterOption(beatsPerBar: 4, beatUnit: 4, grouping: nil),
        MeterOption(beatsPerBar: 5, beatUnit: 4, grouping: nil),
        MeterOption(beatsPerBar: 6, beatUnit: 8, grouping: [3, 3]),
        MeterOption(beatsPerBar: 7, beatUnit: 8, grouping: [2, 2, 3]),
        MeterOption(beatsPerBar: 9, beatUnit: 8, grouping: [3, 3, 3]),
        MeterOption(beatsPerBar: 12, beatUnit: 8, grouping: [3, 3, 3, 3])
    ]

    @Published var pattern = Pattern.defaultFourFour()
    @Published var patternNameDraft = Pattern.defaultFourFour().name
    @Published var patterns: [Pattern] = MetronomeLibrary.defaultLibrary().patterns
    @Published var activeSetlist = MetronomeLibrary.defaultLibrary().activeSetlist
    @Published var audioSettings = MetronomeAudioSettings()
    @Published var isPlaying = false
    @Published var pulseIsActive = false
    @Published var dataTransferMessage: String?
    @Published var practiceTimer = PracticeTimer(durationSeconds: 600)
    @Published var audioRouteStatus = AudioRouteStatus.status(for: [])

    private let audioEngine: any MetronomeAudioEngine
    private let libraryStore: MetronomeLibraryStore?
    private var library = MetronomeLibrary.defaultLibrary()
    private var tapTimes: [Date] = []
    private var pulseResetTask: Task<Void, Never>?
    private var practiceTickerTask: Task<Void, Never>?

    init(
        audioEngine: any MetronomeAudioEngine = AVMetronomeAudioEngine(),
        libraryStore: MetronomeLibraryStore? = try? MetronomeLibraryStore.live()
    ) {
        self.audioEngine = audioEngine
        self.libraryStore = libraryStore
    }

    func prepare() async {
        await loadLibrary()

        await audioEngine.setEventHandler { [weak self] event in
            await MainActor.run {
                self?.handleBeat(event)
            }
        }
        try? await audioEngine.prepare(pattern: pattern)
    }

    func togglePlayback() async {
        if isPlaying {
            await audioEngine.stop()
            pulseResetTask?.cancel()
            pulseIsActive = false
            isPlaying = false
            return
        }

        do {
            try await audioEngine.prepare(pattern: pattern)
            try await audioEngine.start()
            audioRouteStatus = await audioEngine.currentRouteStatus()
            isPlaying = true
        } catch {
            isPlaying = false
            pulseIsActive = false
        }
    }

    func updateBPM(by delta: Int) async {
        let newValue = min(Pattern.maximumBPM, max(Pattern.minimumBPM, pattern.bpm + delta))
        pattern.bpm = newValue
        saveSelectedPattern()
        try? await audioEngine.prepare(pattern: pattern)
    }

    func registerTapTempo() {
        let now = Date()
        tapTimes.append(now)
        tapTimes = tapTimes.filter { now.timeIntervalSince($0) <= 3.0 }

        guard tapTimes.count >= 2 else {
            return
        }

        let intervals = zip(tapTimes.dropFirst(), tapTimes).map { current, previous in
            current.timeIntervalSince(previous)
        }
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        guard averageInterval > 0 else {
            return
        }

        let tappedBPM = Int((60.0 / averageInterval).rounded())
        pattern.bpm = min(Pattern.maximumBPM, max(Pattern.minimumBPM, tappedBPM))
        saveSelectedPattern()
        Task {
            try? await audioEngine.prepare(pattern: pattern)
        }
    }

    private func loadLibrary() async {
        guard let libraryStore else {
            library = MetronomeLibrary.defaultLibrary()
            pattern = library.selectedPattern
            patternNameDraft = pattern.name
            patterns = library.patterns
            activeSetlist = library.activeSetlist
            audioSettings = library.audioSettings
            return
        }

        do {
            let loadedLibrary = try await libraryStore.load()
            library = loadedLibrary
            pattern = loadedLibrary.selectedPattern
            patternNameDraft = pattern.name
            patterns = loadedLibrary.patterns
            activeSetlist = loadedLibrary.activeSetlist
            audioSettings = loadedLibrary.audioSettings
        } catch {
            library = MetronomeLibrary.defaultLibrary()
            pattern = library.selectedPattern
            patternNameDraft = pattern.name
            patterns = library.patterns
            activeSetlist = library.activeSetlist
            audioSettings = library.audioSettings
            try? await libraryStore.save(library)
        }
        try? await audioEngine.updateSettings(audioSettings)
        audioRouteStatus = await audioEngine.currentRouteStatus()
    }

    private func applyLibrary(_ library: MetronomeLibrary) async {
        self.library = library
        pattern = library.selectedPattern
        patternNameDraft = pattern.name
        patterns = library.patterns
        activeSetlist = library.activeSetlist
        audioSettings = library.audioSettings
        tapTimes.removeAll()
        try? await audioEngine.updateSettings(audioSettings)
        try? await audioEngine.prepare(pattern: pattern)
        audioRouteStatus = await audioEngine.currentRouteStatus()
    }

    private func saveSelectedPattern() {
        library.updateSelectedPattern(pattern)
        patterns = library.patterns
        activeSetlist = library.activeSetlist
        guard let libraryStore else {
            return
        }

        let snapshot = library
        Task {
            try? await libraryStore.save(snapshot)
        }
    }

    func selectPattern(id: Pattern.ID) async {
        library.selectPattern(id: id)
        pattern = library.selectedPattern
        patternNameDraft = pattern.name
        patterns = library.patterns
        activeSetlist = library.activeSetlist
        tapTimes.removeAll()
        try? await audioEngine.prepare(pattern: pattern)
        await saveLibrarySnapshot()
    }

    func duplicateCurrentPattern() async {
        do {
            let duplicate = try library.duplicateSelectedPattern()
            pattern = duplicate
            patternNameDraft = pattern.name
            patterns = library.patterns
            activeSetlist = library.activeSetlist
            tapTimes.removeAll()
            try await audioEngine.prepare(pattern: pattern)
            await saveLibrarySnapshot()
        } catch {
        }
    }

    var canDeleteCurrentPattern: Bool {
        patterns.count > 1
    }

    func deleteCurrentPattern() async {
        guard canDeleteCurrentPattern else {
            return
        }

        do {
            try library.deletePattern(id: pattern.id)
            pattern = library.selectedPattern
            patternNameDraft = pattern.name
            patterns = library.patterns
            activeSetlist = library.activeSetlist
            tapTimes.removeAll()
            try await audioEngine.prepare(pattern: pattern)
            await saveLibrarySnapshot()
        } catch {
        }
    }

    func addCurrentPatternToSetlist() async {
        library.appendSelectedPatternToActiveSetlist()
        activeSetlist = library.activeSetlist
        await saveLibrarySnapshot()
    }

    func selectSetlistItem(id: SetlistItem.ID) async {
        library.selectPatternFromActiveSetlist(itemID: id)
        pattern = library.selectedPattern
        patternNameDraft = pattern.name
        patterns = library.patterns
        activeSetlist = library.activeSetlist
        try? await audioEngine.prepare(pattern: pattern)
        await saveLibrarySnapshot()
    }

    func moveSetlistItem(from source: Int, to destination: Int) async {
        do {
            try library.moveActiveSetlistItem(from: source, to: destination)
            activeSetlist = library.activeSetlist
            await saveLibrarySnapshot()
        } catch {
        }
    }

    func removeSetlistItem(id: SetlistItem.ID) async {
        do {
            try library.removeActiveSetlistItem(id: id)
            activeSetlist = library.activeSetlist
            await saveLibrarySnapshot()
        } catch {
        }
    }

    func togglePracticeTimer() {
        if practiceTimer.isRunning {
            practiceTimer.pause()
            practiceTickerTask?.cancel()
            practiceTickerTask = nil
            return
        }

        practiceTimer.start()
        startPracticeTicker()
    }

    func resetPracticeTimer() {
        practiceTickerTask?.cancel()
        practiceTickerTask = nil
        practiceTimer.reset()
    }

    func setPracticeDuration(minutes: Int) {
        practiceTickerTask?.cancel()
        practiceTickerTask = nil
        practiceTimer.selectDuration(seconds: minutes * 60)
    }

    private func startPracticeTicker() {
        practiceTickerTask?.cancel()
        practiceTickerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled {
                    return
                }

                await MainActor.run {
                    self?.practiceTimer.tick()
                    if self?.practiceTimer.isRunning == false {
                        self?.practiceTickerTask?.cancel()
                        self?.practiceTickerTask = nil
                    }
                }
            }
        }
    }

    func patternSummary(for id: Pattern.ID) -> String {
        guard let pattern = patterns.first(where: { $0.id == id }) else {
            return "Missing pattern"
        }
        return "\(pattern.bpm) BPM · \(pattern.meter.displayName)"
    }

    func updateSoundPreset(_ preset: ClickSoundPreset) async {
        var settings = audioSettings
        settings.soundPreset = preset
        await updateAudioSettings(settings)
    }

    func updateMasterGain(_ value: Double) async {
        var settings = audioSettings
        settings.masterGain = value
        await updateAudioSettings(MetronomeAudioSettings(
            soundPreset: settings.soundPreset,
            masterGain: settings.masterGain,
            accentBoost: settings.accentBoost
        ))
    }

    func updateAccentBoost(_ value: Double) async {
        var settings = audioSettings
        settings.accentBoost = value
        await updateAudioSettings(MetronomeAudioSettings(
            soundPreset: settings.soundPreset,
            masterGain: settings.masterGain,
            accentBoost: settings.accentBoost
        ))
    }

    private func updateAudioSettings(_ settings: MetronomeAudioSettings) async {
        audioSettings = settings
        library.updateAudioSettings(settings)
        try? await audioEngine.updateSettings(settings)
        audioRouteStatus = await audioEngine.currentRouteStatus()
        await saveLibrarySnapshot()
    }

    func refreshAudioRouteStatus() async {
        audioRouteStatus = await audioEngine.currentRouteStatus()
    }

    var audioRouteSymbolName: String {
        switch audioRouteStatus.latencyRisk {
        case .low: "speaker.wave.2.fill"
        case .elevated: "exclamationmark.triangle.fill"
        case .unknown: "questionmark.circle.fill"
        }
    }

    var audioRouteTint: Color {
        switch audioRouteStatus.latencyRisk {
        case .low: .green
        case .elevated: .yellow
        case .unknown: .secondary
        }
    }

    var selectedMeterOption: MeterOption {
        Self.meterOptions.first { option in
            option.meter == pattern.meter
        } ?? Self.meterOptions[0]
    }

    func commitPatternName() async {
        pattern.rename(to: patternNameDraft)
        patternNameDraft = pattern.name
        saveSelectedPattern()
        try? await audioEngine.prepare(pattern: pattern)
    }

    func updateMeter(_ option: MeterOption) async {
        pattern.updateMeter(option.meter)
        saveSelectedPattern()
        try? await audioEngine.prepare(pattern: pattern)
    }

    func updateSubdivision(_ subdivision: Subdivision) async {
        pattern.updateSubdivision(subdivision)
        saveSelectedPattern()
        try? await audioEngine.prepare(pattern: pattern)
    }

    func cycleAccent(at index: Int) async {
        do {
            try pattern.cycleAccent(at: index)
            saveSelectedPattern()
            try await audioEngine.prepare(pattern: pattern)
        } catch {
        }
    }

    func shortLabel(for accent: AccentLevel) -> String {
        switch accent {
        case .strong: "S"
        case .normal: "N"
        case .ghost: "G"
        case .muted: "M"
        }
    }

    func accessibilityLabel(for accent: AccentLevel) -> String {
        switch accent {
        case .strong: "strong accent"
        case .normal: "normal accent"
        case .ghost: "ghost accent"
        case .muted: "muted"
        }
    }

    func tint(for accent: AccentLevel) -> Color {
        switch accent {
        case .strong: .accentColor
        case .normal: .blue
        case .ghost: .secondary
        case .muted: .gray
        }
    }

    private func saveLibrarySnapshot() async {
        guard let libraryStore else {
            return
        }
        try? await libraryStore.save(library)
    }

    func makeLibraryExportData() async -> Data? {
        do {
            let data: Data
            if let libraryStore {
                data = try await libraryStore.exportLibrary()
            } else {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                data = try encoder.encode(MetronomeLibraryExport(library: library))
            }
            dataTransferMessage = "Library export ready."
            return data
        } catch {
            dataTransferMessage = "Export failed."
            return nil
        }
    }

    func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            dataTransferMessage = "Library exported."
        case .failure:
            dataTransferMessage = "Export canceled or failed."
        }
    }

    func handleImportResult(_ result: Result<[URL], Error>) async {
        do {
            guard let url = try result.get().first else {
                dataTransferMessage = "No import file selected."
                return
            }

            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let importedLibrary: MetronomeLibrary
            if let libraryStore {
                importedLibrary = try await libraryStore.importLibrary(from: data)
            } else {
                let decoder = JSONDecoder()
                if let exported = try? decoder.decode(MetronomeLibraryExport.self, from: data) {
                    importedLibrary = exported.library
                } else {
                    importedLibrary = try decoder.decode(MetronomeLibrary.self, from: data)
                }
            }

            await applyLibrary(importedLibrary)
            dataTransferMessage = "Library imported."
        } catch {
            dataTransferMessage = "Import failed."
        }
    }

    private func handleBeat(_: ScheduledBeatEvent) {
        pulseResetTask?.cancel()
        pulseIsActive = true

        pulseResetTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 120_000_000)
            await MainActor.run {
                self?.pulseIsActive = false
            }
        }
    }
}

#Preview {
    MainMetronomeView()
}

struct LibraryExportDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.json]
    }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
