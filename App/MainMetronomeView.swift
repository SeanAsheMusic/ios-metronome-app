import SwiftUI
import UniformTypeIdentifiers
import AudioEngine
import Persistence
import RhythmModel

struct MainMetronomeView: View {
    @StateObject private var viewModel = MainMetronomeViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var exportDocument = LibraryExportDocument(data: Data())
    @State private var isExportingLibrary = false
    @State private var isImportingLibrary = false
    @State private var isShowingStagePulse = false
    @State private var isConfirmingSnapshotRestore = false

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
        .fullScreenCover(isPresented: $isShowingStagePulse) {
            StagePulseView(viewModel: viewModel)
        }
        .alert("Restore Latest Snapshot", isPresented: $isConfirmingSnapshotRestore) {
            Button("Restore", role: .destructive) {
                Task {
                    await viewModel.restoreLatestLibrarySnapshot()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This replaces the current library with the most recent local snapshot. The current library is snapshotted first.")
        }
    }

    private var playTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                bpmDisplay
                transportControls
                countInPanel
                tempoControls
                patternSummary
                practicePanel
                visualPulse
                stagePulseButton
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

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mixer")
                            .font(.subheadline.weight(.semibold))

                        mixerSlider(
                            title: "Downbeat",
                            value: viewModel.audioSettings.downbeatGain,
                            accessibilityLabel: "Downbeat level"
                        ) { value in
                            await viewModel.updateDownbeatGain(value)
                        }

                        mixerSlider(
                            title: "Beat",
                            value: viewModel.audioSettings.beatGain,
                            accessibilityLabel: "Beat level"
                        ) { value in
                            await viewModel.updateBeatGain(value)
                        }

                        mixerSlider(
                            title: "Subdivision",
                            value: viewModel.audioSettings.subdivisionGain,
                            accessibilityLabel: "Subdivision level"
                        ) { value in
                            await viewModel.updateSubdivisionGain(value)
                        }

                        mixerSlider(
                            title: "Count-in",
                            value: viewModel.audioSettings.cueGain,
                            accessibilityLabel: "Count-in cue level"
                        ) { value in
                            await viewModel.updateCueGain(value)
                        }

                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    await viewModel.resetRoleMixer()
                                }
                            } label: {
                                Label("Reset Mixer", systemImage: "arrow.counterclockwise")
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Reset mixer levels")

                            Button {
                                Task {
                                    await viewModel.enablePrecisionPracticeMode()
                                }
                            } label: {
                                Label("Precision", systemImage: "scope")
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Enable precision practice mode")
                            .accessibilityHint("Turns off Human Feel and Rhythm Trainer for timing validation.")
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Human Feel")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(viewModel.humanizationPercent)%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: Binding(
                            get: { viewModel.audioSettings.humanizationAmount },
                            set: { value in
                                Task {
                                    await viewModel.updateHumanizationAmount(value)
                                }
                            }
                        ), in: 0...1)
                        .accessibilityLabel("Human feel")
                        .accessibilityValue("\(viewModel.humanizationPercent) percent")

                        if let warning = viewModel.audioSettings.humanizationWarning {
                            Text(warning)
                                .font(.caption)
                                .foregroundStyle(.yellow)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityLabel(warning)
                        }
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
                                    .frame(width: 44, height: 44)
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
                    Text("Timing")
                        .font(.headline)

                    HStack(spacing: 10) {
                        timingMetric(title: "Samples", value: "\(viewModel.timingSummary.sampleCount)")
                        timingMetric(title: "Avg Offset", value: viewModel.averageTimingOffsetText)
                        timingMetric(title: "Jitter", value: viewModel.peakToPeakJitterText)
                    }

                    HStack(spacing: 12) {
                        Button {
                            Task {
                                await viewModel.refreshTimingSummary()
                            }
                        } label: {
                            Label("Refresh", systemImage: "waveform.path.ecg")
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Refresh timing summary")

                        Button {
                            Task {
                                await viewModel.resetTimingMeasurements()
                            }
                        } label: {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Reset timing measurements")
                    }

                    Text("Use this only as a device-validation aid. Precision claims still require real-device runs with Human Feel at 0%.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Timing validation note. Use this only as a device-validation aid. Precision claims still require real-device runs with Human Feel at 0 percent.")
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

                    Button {
                        isConfirmingSnapshotRestore = true
                    } label: {
                        Label("Restore Latest Snapshot", systemImage: "arrow.uturn.backward")
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Restore latest local library snapshot")

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

            Text("\(viewModel.pattern.meter.displayName) · \(viewModel.pattern.subdivisionSummary)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Meter \(viewModel.pattern.meter.displayName), subdivision \(viewModel.pattern.subdivisionSummary)")
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

            HStack(spacing: 10) {
                TextField("BPM", text: $viewModel.bpmEntryDraft)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .frame(width: 96)
                    .accessibilityLabel("Tempo entry")

                Button {
                    Task {
                        await viewModel.commitBPMEntry()
                    }
                } label: {
                    Label("Set", systemImage: "checkmark")
                        .frame(minWidth: 72, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Set tempo")
            }

            if let message = viewModel.bpmEntryMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(message)
            }
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
                Label(viewModel.primaryTransportTitle, systemImage: viewModel.primaryTransportSystemImage)
                    .frame(maxWidth: .infinity, minHeight: 64)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel(viewModel.primaryTransportAccessibilityLabel)

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

    private var countInPanel: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Count-in")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if let remaining = viewModel.countInRemainingBeats {
                    Text("\(remaining)")
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                        .accessibilityLabel("\(remaining) count-in beats remaining")
                }
            }

            Picker("Count-in", selection: Binding(
                get: { viewModel.countInBars },
                set: { viewModel.setCountInBars($0) }
            )) {
                Text("Off").tag(0)
                Text("1 bar").tag(1)
                Text("2 bars").tag(2)
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isPlaying || viewModel.isCountingIn)
            .accessibilityLabel("Count-in length")
        }
        .padding(12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
            summaryPill(title: "Subdivision", value: viewModel.pattern.subdivisionSummary)
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
                .lineLimit(2)
                .minimumScaleFactor(0.65)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func mixerSlider(
        title: String,
        value: Double,
        accessibilityLabel: String,
        update: @escaping (Double) async -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int((value * 100).rounded()))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Slider(value: Binding(
                get: { value },
                set: { newValue in
                    Task {
                        await update(newValue)
                    }
                }
            ), in: 0...1)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue("\(Int((value * 100).rounded())) percent")
        }
    }

    private func timingMetric(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
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

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tempo Ladder")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(viewModel.tempoLadderSummary)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Tempo ladder \(viewModel.tempoLadderAccessibilitySummary)")

                    Button {
                        viewModel.toggleTempoLadder()
                    } label: {
                        Label(viewModel.tempoLadder.isEnabled ? "Stop" : "Start", systemImage: viewModel.tempoLadder.isEnabled ? "pause.fill" : "arrow.up.forward")
                            .frame(minWidth: 86, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .tint(viewModel.tempoLadder.isEnabled ? .accentColor : .blue)
                    .accessibilityLabel(viewModel.tempoLadder.isEnabled ? "Stop tempo ladder" : "Start tempo ladder")
                }

                VStack(spacing: 8) {
                    ladderStepper(title: "Target", value: "\(viewModel.tempoLadder.targetBPM)", decrementLabel: "Decrease target tempo", incrementLabel: "Increase target tempo") {
                        viewModel.updateTempoLadderTarget(by: -5)
                    } increment: {
                        viewModel.updateTempoLadderTarget(by: 5)
                    }

                    ladderStepper(title: "Step", value: "\(viewModel.tempoLadder.stepBPM)", decrementLabel: "Decrease ladder step", incrementLabel: "Increase ladder step") {
                        viewModel.updateTempoLadderStep(by: -1)
                    } increment: {
                        viewModel.updateTempoLadderStep(by: 1)
                    }

                    ladderStepper(title: "Bars", value: "\(viewModel.tempoLadder.barsPerStep)", decrementLabel: "Decrease ladder bars", incrementLabel: "Increase ladder bars") {
                        viewModel.updateTempoLadderBars(by: -1)
                    } increment: {
                        viewModel.updateTempoLadderBars(by: 1)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rhythm Trainer")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(viewModel.audioSettings.rhythmTrainer.summary)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Rhythm trainer \(viewModel.audioSettings.rhythmTrainer.summary)")

                    Picker("Rhythm trainer", selection: Binding(
                        get: { viewModel.audioSettings.rhythmTrainer.mode },
                        set: { mode in
                            Task {
                                await viewModel.updateRhythmTrainerMode(mode)
                            }
                        }
                    )) {
                        ForEach(RhythmTrainerMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Rhythm trainer mode")
                }

                if viewModel.audioSettings.rhythmTrainer.mode == .fixedBars {
                    ladderStepper(title: "Audible", value: "\(viewModel.audioSettings.rhythmTrainer.audibleBars)", decrementLabel: "Decrease audible bars", incrementLabel: "Increase audible bars") {
                        Task { await viewModel.updateRhythmTrainerAudibleBars(by: -1) }
                    } increment: {
                        Task { await viewModel.updateRhythmTrainerAudibleBars(by: 1) }
                    }

                    ladderStepper(title: "Silent", value: "\(viewModel.audioSettings.rhythmTrainer.silentBars)", decrementLabel: "Decrease silent bars", incrementLabel: "Increase silent bars") {
                        Task { await viewModel.updateRhythmTrainerSilentBars(by: -1) }
                    } increment: {
                        Task { await viewModel.updateRhythmTrainerSilentBars(by: 1) }
                    }
                } else if viewModel.audioSettings.rhythmTrainer.mode == .randomBars
                    || viewModel.audioSettings.rhythmTrainer.mode == .randomBeats {
                    let usesBeatDropout = viewModel.audioSettings.rhythmTrainer.mode == .randomBeats
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(usesBeatDropout ? "Beat Dropout" : "Silent Chance")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(viewModel.rhythmTrainerRandomPercent)%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(
                            get: { viewModel.audioSettings.rhythmTrainer.randomSilenceProbability },
                            set: { value in
                                Task {
                                    await viewModel.updateRhythmTrainerRandomSilence(value)
                                }
                            }
                        ), in: 0...1)
                        .accessibilityLabel(usesBeatDropout ? "Random beat dropout chance" : "Random silent bar chance")
                        .accessibilityValue("\(viewModel.rhythmTrainerRandomPercent) percent")
                    }
                }
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
        .frame(maxWidth: .infinity, minHeight: 44)
        .buttonStyle(.bordered)
        .accessibilityLabel("Set practice timer to \(minutes) minutes")
    }

    private func ladderStepper(
        title: String,
        value: String,
        decrementLabel: String,
        incrementLabel: String,
        decrement: @escaping () -> Void,
        increment: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                decrement()
            } label: {
                Label(decrementLabel, systemImage: "minus")
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(decrementLabel)

            Text(value)
                .font(.headline.monospacedDigit())
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)

            Button {
                increment()
            } label: {
                Label(incrementLabel, systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(incrementLabel)
        }
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
                        Menu {
                            ForEach(AccentLevel.allCases, id: \.self) { accent in
                                Button {
                                    Task {
                                        await viewModel.setAccent(accent, at: beat.index)
                                    }
                                } label: {
                                    Label(viewModel.menuLabel(for: accent), systemImage: viewModel.systemImage(for: accent))
                                }
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
                        .accessibilityLabel("Step \(beat.index + 1), \(viewModel.accessibilityLabel(for: beat.accent))")
                        .accessibilityHint("Opens accent and mute choices")
                    }
                }
            }

            perBeatSubdivisionEditor
        }
        .frame(maxWidth: .infinity)
    }

    private var perBeatSubdivisionEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Per-beat subdivisions")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<viewModel.pattern.meter.beatsPerBar, id: \.self) { beatIndex in
                        Menu {
                            ForEach(Subdivision.allCases, id: \.self) { subdivision in
                                Button {
                                    Task {
                                        await viewModel.updateBeatSubdivision(subdivision, at: beatIndex)
                                    }
                                } label: {
                                    Text(subdivision.displayName)
                                }
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(beatIndex + 1)")
                                    .font(.caption.weight(.bold))
                                Text(viewModel.beatSubdivisionLabel(at: beatIndex))
                                    .font(.caption2.weight(.semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .frame(width: 86, height: 46)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Beat \(beatIndex + 1) subdivision \(viewModel.beatSubdivisionAccessibilityLabel(at: beatIndex))")
                    }
                }
            }
        }
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

            VStack(alignment: .leading, spacing: 8) {
                Text("Grooves")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(GrooveTemplate.allCases, id: \.self) { template in
                            Button {
                                Task {
                                    await viewModel.addGrooveTemplate(template)
                                }
                            } label: {
                                Text(template.displayName)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                    .frame(width: 126, height: 44)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Add \(template.displayName) groove")
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Clave Mode")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Picker("Clave mixer", selection: $viewModel.selectedGrooveMixerPreset) {
                        ForEach(GrooveMixerPreset.allCases, id: \.self) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Clave mixer")
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ClaveModeTemplate.allCases, id: \.self) { template in
                            Button {
                                Task {
                                    await viewModel.addClaveModeTemplate(template)
                                }
                            } label: {
                                Text(template.displayName)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                    .frame(width: 134, height: 44)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Add \(template.displayName), \(viewModel.selectedGrooveMixerPreset.displayName)")
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Swing")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SwingTemplate.allCases, id: \.self) { template in
                            Button {
                                Task {
                                    await viewModel.addSwingTemplate(template)
                                }
                            } label: {
                                Text(template.displayName)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                    .frame(width: 138, height: 44)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Add \(template.displayName) swing pattern")
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Polyrhythm")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PolyrhythmTemplate.allCases, id: \.self) { template in
                            Button {
                                Task {
                                    await viewModel.addPolyrhythmTemplate(template)
                                }
                            } label: {
                                Text(template.displayName)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                    .frame(width: 118, height: 44)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Add \(template.displayName) polyrhythm pattern")
                        }
                    }
                }
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
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.activeSetlist.name)
                        .font(.headline)
                    Text(viewModel.songFormSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Setlist \(viewModel.activeSetlist.name), \(viewModel.songFormAccessibilitySummary)")

                Spacer()

                Toggle("Auto", isOn: Binding(
                    get: { viewModel.isSongFormAutoAdvanceEnabled },
                    set: { enabled in
                        viewModel.setSongFormAutoAdvance(enabled)
                    }
                ))
                .labelsHidden()
                .accessibilityLabel("Song form auto advance")
                .accessibilityValue(viewModel.isSongFormAutoAdvanceEnabled ? "On" : "Off")

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
                    Text("\(item.resolvedBarCount) bars")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(width: 176, height: 66, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Setlist item \(offset + 1), \(item.title), \(item.resolvedBarCount) bars")

            HStack(spacing: 6) {
                Button {
                    Task {
                        await viewModel.updateSetlistItemBarCount(id: item.id, by: -1)
                    }
                } label: {
                    Label("Fewer bars", systemImage: "minus")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Decrease bars for \(item.title)")

                Text("\(item.resolvedBarCount)")
                    .font(.headline.monospacedDigit())
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)

                Button {
                    Task {
                        await viewModel.updateSetlistItemBarCount(id: item.id, by: 1)
                    }
                } label: {
                    Label("More bars", systemImage: "plus")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Increase bars for \(item.title)")
            }

            HStack(spacing: 6) {
                Button {
                    Task {
                        await viewModel.moveSetlistItem(from: offset, to: max(0, offset - 1))
                    }
                } label: {
                    Label("Earlier", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
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
                        .frame(width: 44, height: 44)
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
                        .frame(width: 44, height: 44)
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
            .scaleEffect(reduceMotion ? 1.0 : (viewModel.pulseIsActive ? 1.0 : 0.82))
            .animation(reduceMotion ? nil : .snappy(duration: 0.18), value: viewModel.pulseIsActive)
            .accessibilityLabel("Visual pulse")
            .accessibilityValue(viewModel.pulseIsActive ? "Active" : (reduceMotion ? "Inactive, reduced motion" : "Inactive"))
    }

    private var stagePulseButton: some View {
        Button {
            isShowingStagePulse = true
        } label: {
            Label("Stage", systemImage: "rectangle.expand.vertical")
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("Open stage pulse")
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
            if let grouping, grouping.count > 1 {
                return "\(beatsPerBar)/\(beatUnit) \(grouping.map(String.init).joined(separator: "-"))"
            }
            return "\(beatsPerBar)/\(beatUnit)"
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
        MeterOption(beatsPerBar: 5, beatUnit: 8, grouping: [2, 3]),
        MeterOption(beatsPerBar: 5, beatUnit: 8, grouping: [3, 2]),
        MeterOption(beatsPerBar: 6, beatUnit: 8, grouping: [3, 3]),
        MeterOption(beatsPerBar: 7, beatUnit: 8, grouping: [2, 2, 3]),
        MeterOption(beatsPerBar: 7, beatUnit: 8, grouping: [3, 2, 2]),
        MeterOption(beatsPerBar: 9, beatUnit: 8, grouping: [3, 3, 3]),
        MeterOption(beatsPerBar: 9, beatUnit: 8, grouping: [2, 2, 2, 3]),
        MeterOption(beatsPerBar: 11, beatUnit: 8, grouping: [3, 3, 2, 3]),
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
    @Published var timingSummary = AudioTimingSummary(samples: [])
    @Published var bpmEntryDraft = "\(Pattern.defaultFourFour().bpm)"
    @Published var bpmEntryMessage: String?
    @Published var countInBars = 0
    @Published var isCountingIn = false
    @Published var countInRemainingBeats: Int?
    @Published var tempoLadder = TempoLadder()
    @Published var selectedGrooveMixerPreset = GrooveMixerPreset.claveWithMetronome
    @Published var isSongFormAutoAdvanceEnabled = false
    @Published var songFormCompletedBars = 0

    private let audioEngine: any MetronomeAudioEngine
    private let libraryStore: MetronomeLibraryStore?
    private var library = MetronomeLibrary.defaultLibrary()
    private var tapTimes: [Date] = []
    private var pulseResetTask: Task<Void, Never>?
    private var practiceTickerTask: Task<Void, Never>?
    private var countInTask: Task<Void, Never>?
    private var songFormActiveItemID: SetlistItem.ID?
    private var songFormHasSeenFirstDownbeat = false

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
        if isPlaying || isCountingIn {
            await stopTransport()
            return
        }

        if countInBars > 0 {
            startCountIn()
            return
        }

        await startPlayback()
    }

    private func startPlayback() async {
        do {
            resetSongFormProgress(keepActiveItem: songFormActiveItemID != nil)
            try await audioEngine.prepare(pattern: pattern)
            try await audioEngine.start()
            audioRouteStatus = await audioEngine.currentRouteStatus()
            isPlaying = true
        } catch {
            isPlaying = false
            pulseIsActive = false
        }
    }

    private func stopTransport() async {
        countInTask?.cancel()
        countInTask = nil
        isCountingIn = false
        countInRemainingBeats = nil
        await audioEngine.stop()
        pulseResetTask?.cancel()
        pulseIsActive = false
        isPlaying = false
        resetSongFormProgress(keepActiveItem: songFormActiveItemID != nil)
    }

    private func startCountIn() {
        countInTask?.cancel()
        isCountingIn = true
        countInRemainingBeats = max(1, countInBars * pattern.meter.beatsPerBar)

        let countInPattern = pattern
        let totalBeats = countInRemainingBeats ?? 0
        let intervalNanoseconds = UInt64((60_000_000_000.0 / Double(pattern.bpm)).rounded())

        countInTask = Task { [weak self] in
            for offset in 0..<totalBeats {
                if Task.isCancelled {
                    return
                }

                let remaining = totalBeats - offset
                await MainActor.run {
                    self?.countInRemainingBeats = remaining
                }

                let role: ClickSoundRole = offset == 0 ? .downbeat : .cue
                try? await self?.audioEngine.playOneShot(pattern: countInPattern, soundRole: role)
                try? await Task.sleep(nanoseconds: intervalNanoseconds)
            }

            if Task.isCancelled {
                return
            }

            await MainActor.run {
                self?.isCountingIn = false
                self?.countInRemainingBeats = nil
            }
            await self?.startPlayback()
        }
    }

    func setCountInBars(_ bars: Int) {
        guard !isPlaying, !isCountingIn else {
            return
        }
        countInBars = min(2, max(0, bars))
    }

    var primaryTransportTitle: String {
        if isPlaying {
            return "Stop"
        }
        if isCountingIn {
            return "Cancel"
        }
        return "Play"
    }

    var primaryTransportSystemImage: String {
        if isPlaying || isCountingIn {
            return "stop.fill"
        }
        return "play.fill"
    }

    var primaryTransportAccessibilityLabel: String {
        if isPlaying {
            return "Stop metronome"
        }
        if isCountingIn {
            return "Cancel count-in"
        }
        return "Play metronome"
    }

    func updateBPM(by delta: Int) async {
        let newValue = min(Pattern.maximumBPM, max(Pattern.minimumBPM, pattern.bpm + delta))
        pattern.bpm = newValue
        bpmEntryMessage = nil
        saveSelectedPattern()
        try? await audioEngine.prepare(pattern: pattern)
    }

    func commitBPMEntry() async {
        let trimmedValue = bpmEntryDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let bpm = Int(trimmedValue) else {
            bpmEntryDraft = "\(pattern.bpm)"
            bpmEntryMessage = "Enter a whole number from \(Pattern.minimumBPM) to \(Pattern.maximumBPM)."
            return
        }

        guard Pattern.minimumBPM...Pattern.maximumBPM ~= bpm else {
            bpmEntryDraft = "\(pattern.bpm)"
            bpmEntryMessage = "Tempo must be \(Pattern.minimumBPM)-\(Pattern.maximumBPM) BPM."
            return
        }

        pattern.bpm = bpm
        bpmEntryDraft = "\(pattern.bpm)"
        bpmEntryMessage = "Tempo set to \(pattern.bpm) BPM."
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
        bpmEntryMessage = nil
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
            bpmEntryDraft = "\(pattern.bpm)"
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
            bpmEntryDraft = "\(pattern.bpm)"
            patterns = loadedLibrary.patterns
            activeSetlist = loadedLibrary.activeSetlist
            audioSettings = loadedLibrary.audioSettings
        } catch {
            library = MetronomeLibrary.defaultLibrary()
            pattern = library.selectedPattern
            patternNameDraft = pattern.name
            bpmEntryDraft = "\(pattern.bpm)"
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
        bpmEntryDraft = "\(pattern.bpm)"
        bpmEntryMessage = nil
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
        bpmEntryDraft = "\(pattern.bpm)"
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
        bpmEntryDraft = "\(pattern.bpm)"
        bpmEntryMessage = nil
        patterns = library.patterns
        activeSetlist = library.activeSetlist
        tapTimes.removeAll()
        resetSongFormProgress()
        try? await audioEngine.prepare(pattern: pattern)
        await saveLibrarySnapshot()
    }

    func duplicateCurrentPattern() async {
        do {
            let duplicate = try library.duplicateSelectedPattern()
            pattern = duplicate
            patternNameDraft = pattern.name
            bpmEntryDraft = "\(pattern.bpm)"
            bpmEntryMessage = nil
            patterns = library.patterns
            activeSetlist = library.activeSetlist
            tapTimes.removeAll()
            resetSongFormProgress()
            try await audioEngine.prepare(pattern: pattern)
            await saveLibrarySnapshot()
        } catch {
        }
    }

    func addGrooveTemplate(_ template: GrooveTemplate) async {
        let groove = Pattern.groove(template)
        library.appendPattern(groove)
        pattern = groove
        patternNameDraft = pattern.name
        bpmEntryDraft = "\(pattern.bpm)"
        bpmEntryMessage = nil
        patterns = library.patterns
        activeSetlist = library.activeSetlist
        tapTimes.removeAll()
        resetSongFormProgress()
        try? await audioEngine.prepare(pattern: pattern)
        await saveLibrarySnapshot()
    }

    func addClaveModeTemplate(_ template: ClaveModeTemplate) async {
        let groove = Pattern.claveMode(template, mixerPreset: selectedGrooveMixerPreset)
        library.appendPattern(groove)
        pattern = groove
        patternNameDraft = pattern.name
        bpmEntryDraft = "\(pattern.bpm)"
        bpmEntryMessage = nil
        patterns = library.patterns
        activeSetlist = library.activeSetlist
        tapTimes.removeAll()
        resetSongFormProgress()
        try? await audioEngine.prepare(pattern: pattern)
        await saveLibrarySnapshot()
    }

    func addSwingTemplate(_ template: SwingTemplate) async {
        let swingPattern = Pattern.swing(template)
        library.appendPattern(swingPattern)
        pattern = swingPattern
        patternNameDraft = pattern.name
        bpmEntryDraft = "\(pattern.bpm)"
        bpmEntryMessage = nil
        patterns = library.patterns
        activeSetlist = library.activeSetlist
        tapTimes.removeAll()
        resetSongFormProgress()
        try? await audioEngine.prepare(pattern: pattern)
        await saveLibrarySnapshot()
    }

    func addPolyrhythmTemplate(_ template: PolyrhythmTemplate) async {
        let polyrhythmPattern = Pattern.polyrhythm(template)
        library.appendPattern(polyrhythmPattern)
        pattern = polyrhythmPattern
        patternNameDraft = pattern.name
        bpmEntryDraft = "\(pattern.bpm)"
        bpmEntryMessage = nil
        patterns = library.patterns
        activeSetlist = library.activeSetlist
        tapTimes.removeAll()
        resetSongFormProgress()
        try? await audioEngine.prepare(pattern: pattern)
        await saveLibrarySnapshot()
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
            bpmEntryDraft = "\(pattern.bpm)"
            bpmEntryMessage = nil
            patterns = library.patterns
            activeSetlist = library.activeSetlist
            tapTimes.removeAll()
            resetSongFormProgress()
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
        songFormActiveItemID = id
        resetSongFormProgress(keepActiveItem: true)
        patternNameDraft = pattern.name
        bpmEntryDraft = "\(pattern.bpm)"
        bpmEntryMessage = nil
        patterns = library.patterns
        activeSetlist = library.activeSetlist
        try? await audioEngine.prepare(pattern: pattern)
        await saveLibrarySnapshot()
    }

    func moveSetlistItem(from source: Int, to destination: Int) async {
        do {
            try library.moveActiveSetlistItem(from: source, to: destination)
            activeSetlist = library.activeSetlist
            resetSongFormProgress()
            await saveLibrarySnapshot()
        } catch {
        }
    }

    func removeSetlistItem(id: SetlistItem.ID) async {
        do {
            try library.removeActiveSetlistItem(id: id)
            activeSetlist = library.activeSetlist
            if songFormActiveItemID == id {
                songFormActiveItemID = nil
            }
            resetSongFormProgress(keepActiveItem: songFormActiveItemID != nil)
            await saveLibrarySnapshot()
        } catch {
        }
    }

    func updateSetlistItemBarCount(id: SetlistItem.ID, by delta: Int) async {
        guard let item = activeSetlist.items.first(where: { $0.id == id }) else {
            return
        }

        do {
            try library.updateActiveSetlistItemBarCount(id: id, barCount: item.resolvedBarCount + delta)
            activeSetlist = library.activeSetlist
            resetSongFormProgress(keepActiveItem: true)
            await saveLibrarySnapshot()
        } catch {
        }
    }

    func setSongFormAutoAdvance(_ enabled: Bool) {
        isSongFormAutoAdvanceEnabled = enabled
        resetSongFormProgress(keepActiveItem: songFormActiveItemID != nil)
    }

    var songFormSummary: String {
        let state = isSongFormAutoAdvanceEnabled ? "Auto on" : "Auto off"
        guard let item = activeSongFormItem else {
            return state
        }
        return "\(state) · \(songFormCompletedBars)/\(item.resolvedBarCount) bars"
    }

    var songFormAccessibilitySummary: String {
        let state = isSongFormAutoAdvanceEnabled ? "auto advance on" : "auto advance off"
        guard let item = activeSongFormItem else {
            return state
        }
        return "\(state), \(songFormCompletedBars) of \(item.resolvedBarCount) bars completed"
    }

    private var activeSongFormItem: SetlistItem? {
        if let songFormActiveItemID,
           let item = activeSetlist.items.first(where: { $0.id == songFormActiveItemID }) {
            return item
        }
        return activeSetlist.items.first { $0.patternID == pattern.id }
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

    var tempoLadderSummary: String {
        let direction = tempoLadder.targetBPM >= pattern.bpm ? "up" : "down"
        let state = tempoLadder.isEnabled ? "On" : "Off"
        return "\(state) · \(direction) to \(tempoLadder.targetBPM) · \(tempoLadder.stepBPM) BPM every \(tempoLadder.barsPerStep) bars"
    }

    var tempoLadderAccessibilitySummary: String {
        let state = tempoLadder.isEnabled ? "enabled" : "disabled"
        return "\(state), target \(tempoLadder.targetBPM) beats per minute, step \(tempoLadder.stepBPM) beats per minute every \(tempoLadder.barsPerStep) bars"
    }

    func toggleTempoLadder() {
        tempoLadder.setEnabled(!tempoLadder.isEnabled, currentBPM: pattern.bpm)
    }

    func updateTempoLadderTarget(by delta: Int) {
        tempoLadder.setTargetBPM(tempoLadder.targetBPM + delta)
    }

    func updateTempoLadderStep(by delta: Int) {
        tempoLadder.setStepBPM(tempoLadder.stepBPM + delta)
    }

    func updateTempoLadderBars(by delta: Int) {
        tempoLadder.setBarsPerStep(tempoLadder.barsPerStep + delta)
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
        await updateAudioSettings(settings)
    }

    func updateAccentBoost(_ value: Double) async {
        var settings = audioSettings
        settings.accentBoost = value
        await updateAudioSettings(settings)
    }

    func updateDownbeatGain(_ value: Double) async {
        var settings = audioSettings
        settings.downbeatGain = value
        await updateAudioSettings(settings)
    }

    func updateBeatGain(_ value: Double) async {
        var settings = audioSettings
        settings.beatGain = value
        await updateAudioSettings(settings)
    }

    func updateSubdivisionGain(_ value: Double) async {
        var settings = audioSettings
        settings.subdivisionGain = value
        await updateAudioSettings(settings)
    }

    func updateCueGain(_ value: Double) async {
        var settings = audioSettings
        settings.cueGain = value
        await updateAudioSettings(settings)
    }

    func resetRoleMixer() async {
        var settings = audioSettings
        settings.resetRoleMixer()
        await updateAudioSettings(settings)
    }

    func enablePrecisionPracticeMode() async {
        var settings = audioSettings
        settings.setPrecisionPracticeMode()
        await updateAudioSettings(settings)
        await audioEngine.resetTimingMeasurements()
        timingSummary = await audioEngine.timingSummary()
    }

    func updateHumanizationAmount(_ value: Double) async {
        var settings = audioSettings
        settings.humanizationAmount = min(1.0, max(0.0, value))
        await updateAudioSettings(settings)
    }

    var humanizationPercent: Int {
        Int((audioSettings.humanizationAmount * 100).rounded())
    }

    var rhythmTrainerRandomPercent: Int {
        Int((audioSettings.rhythmTrainer.randomSilenceProbability * 100).rounded())
    }

    func updateRhythmTrainerMode(_ mode: RhythmTrainerMode) async {
        var settings = audioSettings
        settings.rhythmTrainer.mode = mode
        await updateAudioSettings(settings)
    }

    func updateRhythmTrainerAudibleBars(by delta: Int) async {
        var settings = audioSettings
        settings.rhythmTrainer = RhythmTrainerSettings(
            mode: settings.rhythmTrainer.mode,
            audibleBars: settings.rhythmTrainer.audibleBars + delta,
            silentBars: settings.rhythmTrainer.silentBars,
            randomSilenceProbability: settings.rhythmTrainer.randomSilenceProbability
        )
        await updateAudioSettings(settings)
    }

    func updateRhythmTrainerSilentBars(by delta: Int) async {
        var settings = audioSettings
        settings.rhythmTrainer = RhythmTrainerSettings(
            mode: settings.rhythmTrainer.mode,
            audibleBars: settings.rhythmTrainer.audibleBars,
            silentBars: settings.rhythmTrainer.silentBars + delta,
            randomSilenceProbability: settings.rhythmTrainer.randomSilenceProbability
        )
        await updateAudioSettings(settings)
    }

    func updateRhythmTrainerRandomSilence(_ value: Double) async {
        var settings = audioSettings
        settings.rhythmTrainer = RhythmTrainerSettings(
            mode: settings.rhythmTrainer.mode,
            audibleBars: settings.rhythmTrainer.audibleBars,
            silentBars: settings.rhythmTrainer.silentBars,
            randomSilenceProbability: value
        )
        await updateAudioSettings(settings)
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

    func refreshTimingSummary() async {
        timingSummary = await audioEngine.timingSummary()
    }

    func resetTimingMeasurements() async {
        await audioEngine.resetTimingMeasurements()
        timingSummary = await audioEngine.timingSummary()
    }

    var averageTimingOffsetText: String {
        formatNanoseconds(timingSummary.averageOffsetNanoseconds)
    }

    var peakToPeakJitterText: String {
        formatNanoseconds(Int64(timingSummary.peakToPeakJitterNanoseconds))
    }

    private func formatNanoseconds(_ value: Int64) -> String {
        let milliseconds = Double(value) / 1_000_000.0
        return String(format: "%.2f ms", milliseconds)
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

    func updateBeatSubdivision(_ subdivision: Subdivision, at meterBeatIndex: Int) async {
        do {
            try pattern.updateBeatSubdivision(subdivision, at: meterBeatIndex)
            saveSelectedPattern()
            try await audioEngine.prepare(pattern: pattern)
        } catch {
        }
    }

    func beatSubdivisionLabel(at meterBeatIndex: Int) -> String {
        beatSubdivision(at: meterBeatIndex).displayName
    }

    func beatSubdivisionAccessibilityLabel(at meterBeatIndex: Int) -> String {
        beatSubdivision(at: meterBeatIndex).displayName.lowercased()
    }

    private func beatSubdivision(at meterBeatIndex: Int) -> Subdivision {
        guard let perBeatSubdivisions = pattern.perBeatSubdivisions,
              perBeatSubdivisions.indices.contains(meterBeatIndex) else {
            return pattern.subdivision
        }
        return perBeatSubdivisions[meterBeatIndex]
    }

    func cycleAccent(at index: Int) async {
        do {
            try pattern.cycleAccent(at: index)
            saveSelectedPattern()
            try await audioEngine.prepare(pattern: pattern)
        } catch {
        }
    }

    func setAccent(_ accent: AccentLevel, at index: Int) async {
        do {
            try pattern.setAccent(accent, at: index)
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

    func menuLabel(for accent: AccentLevel) -> String {
        switch accent {
        case .strong: "Strong"
        case .normal: "Normal"
        case .ghost: "Ghost"
        case .muted: "Mute"
        }
    }

    func systemImage(for accent: AccentLevel) -> String {
        switch accent {
        case .strong: "largecircle.fill.circle"
        case .normal: "circle.fill"
        case .ghost: "circle"
        case .muted: "speaker.slash"
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

    func restoreLatestLibrarySnapshot() async {
        guard let libraryStore else {
            dataTransferMessage = "No local snapshots available."
            return
        }

        do {
            guard let restoredLibrary = try await libraryStore.restoreLatestSnapshot() else {
                dataTransferMessage = "No local snapshots available."
                return
            }

            await stopTransport()
            await applyLibrary(restoredLibrary)
            dataTransferMessage = "Latest local snapshot restored."
        } catch {
            dataTransferMessage = "Snapshot restore failed."
        }
    }

    private func handleBeat(_ event: ScheduledBeatEvent) {
        applyTempoLadderIfNeeded(for: event)
        applySongFormIfNeeded(for: event)

        guard event.soundRole != .muted else {
            return
        }

        pulseResetTask?.cancel()
        pulseIsActive = true

        pulseResetTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 120_000_000)
            await MainActor.run {
                self?.pulseIsActive = false
            }
        }
    }

    private func applySongFormIfNeeded(for event: ScheduledBeatEvent) {
        guard isSongFormAutoAdvanceEnabled,
              isPlaying,
              event.patternID == pattern.id,
              event.beatIndex == 0,
              !activeSetlist.items.isEmpty,
              let currentIndex = songFormCurrentItemIndex(for: event.patternID) else {
            return
        }

        let currentItem = activeSetlist.items[currentIndex]
        if songFormActiveItemID == nil {
            songFormActiveItemID = currentItem.id
        }

        guard songFormHasSeenFirstDownbeat else {
            songFormHasSeenFirstDownbeat = true
            return
        }

        songFormCompletedBars += 1
        guard songFormCompletedBars >= currentItem.resolvedBarCount else {
            return
        }

        let nextIndex = (currentIndex + 1) % activeSetlist.items.count
        let nextItem = activeSetlist.items[nextIndex]
        Task {
            await advanceSongForm(to: nextItem.id)
        }
    }

    private func songFormCurrentItemIndex(for patternID: Pattern.ID) -> Int? {
        if let songFormActiveItemID,
           let activeIndex = activeSetlist.items.firstIndex(where: { $0.id == songFormActiveItemID }),
           activeSetlist.items[activeIndex].patternID == patternID {
            return activeIndex
        }

        return activeSetlist.items.firstIndex { $0.patternID == patternID }
    }

    private func advanceSongForm(to itemID: SetlistItem.ID) async {
        library.selectPatternFromActiveSetlist(itemID: itemID)
        pattern = library.selectedPattern
        songFormActiveItemID = itemID
        resetSongFormProgress(keepActiveItem: true)
        patternNameDraft = pattern.name
        bpmEntryDraft = "\(pattern.bpm)"
        bpmEntryMessage = nil
        patterns = library.patterns
        activeSetlist = library.activeSetlist
        tapTimes.removeAll()
        try? await audioEngine.prepare(pattern: pattern)
        await saveLibrarySnapshot()
    }

    private func resetSongFormProgress(keepActiveItem: Bool = false) {
        songFormCompletedBars = 0
        songFormHasSeenFirstDownbeat = false
        if !keepActiveItem {
            songFormActiveItemID = nil
        }
    }

    private func applyTempoLadderIfNeeded(for event: ScheduledBeatEvent) {
        guard isPlaying, event.patternID == pattern.id, event.beatIndex == 0 else {
            return
        }

        guard let nextBPM = tempoLadder.recordCompletedBar(currentBPM: pattern.bpm) else {
            return
        }

        pattern.bpm = nextBPM
        bpmEntryMessage = "Tempo ladder set \(nextBPM) BPM."
        saveSelectedPattern()
        Task {
            try? await audioEngine.prepare(pattern: pattern)
        }
    }
}

#Preview {
    MainMetronomeView()
}

struct StagePulseView: View {
    @ObservedObject var viewModel: MainMetronomeViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(max(min(proxy.size.width, proxy.size.height) * 0.58, 180), 520)

            ZStack(alignment: .topTrailing) {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer(minLength: 24)

                    VStack(spacing: 8) {
                        Text(viewModel.pattern.name)
                            .font(.title2.weight(.semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.75)

                        Text("\(viewModel.pattern.bpm) BPM · \(viewModel.pattern.meter.displayName)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Pattern \(viewModel.pattern.name), \(viewModel.pattern.bpm) beats per minute, meter \(viewModel.pattern.meter.displayName)")

                    Circle()
                        .fill(viewModel.pulseIsActive ? Color.accentColor : Color.secondary.opacity(0.24))
                        .frame(width: diameter, height: diameter)
                        .scaleEffect(reduceMotion ? 1.0 : (viewModel.pulseIsActive ? 1.0 : 0.72))
                        .animation(reduceMotion ? nil : .snappy(duration: 0.18), value: viewModel.pulseIsActive)
                        .accessibilityLabel("Stage visual pulse")
                        .accessibilityValue(viewModel.pulseIsActive ? "Active" : (reduceMotion ? "Inactive, reduced motion" : "Inactive"))

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button {
                    dismiss()
                } label: {
                    Label("Close", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.bordered)
                .padding(20)
                .accessibilityLabel("Close stage pulse")
            }
        }
        .preferredColorScheme(.dark)
    }
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
