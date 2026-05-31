import SwiftUI
import AudioEngine
import Persistence
import RhythmModel

struct MainMetronomeView: View {
    @StateObject private var viewModel = MainMetronomeViewModel()

    var body: some View {
        VStack(spacing: 24) {
            header
            bpmDisplay
            transportControls
            tempoControls
            patternSummary
            visualPulse
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .preferredColorScheme(.dark)
        .task {
            await viewModel.prepare()
        }
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
    @Published var pattern = Pattern.defaultFourFour()
    @Published var isPlaying = false
    @Published var pulseIsActive = false

    private let audioEngine: any MetronomeAudioEngine
    private let libraryStore: MetronomeLibraryStore?
    private var library = MetronomeLibrary.defaultLibrary()
    private var tapTimes: [Date] = []
    private var pulseResetTask: Task<Void, Never>?

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
            return
        }

        do {
            let loadedLibrary = try await libraryStore.load()
            library = loadedLibrary
            pattern = loadedLibrary.selectedPattern
        } catch {
            library = MetronomeLibrary.defaultLibrary()
            pattern = library.selectedPattern
            try? await libraryStore.save(library)
        }
    }

    private func saveSelectedPattern() {
        library.updateSelectedPattern(pattern)
        guard let libraryStore else {
            return
        }

        let snapshot = library
        Task {
            try? await libraryStore.save(snapshot)
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
