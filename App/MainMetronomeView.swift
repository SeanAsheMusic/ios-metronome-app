import SwiftUI
import UniformTypeIdentifiers
import AudioEngine
import Persistence
import RhythmModel

struct MainMetronomeView: View {
    @StateObject private var viewModel: MainMetronomeViewModel
    @State private var selectedTab: InstrumentTab = .play
    @State private var exportDocument = LibraryExportDocument(data: Data())
    @State private var isExportingLibrary = false
    @State private var isImportingLibrary = false
    @State private var isShowingStagePulse = false
    @State private var isConfirmingSnapshotRestore = false
    private let bottomTabBarContentPadding: CGFloat = 78

    private enum InstrumentTab: String, CaseIterable, Identifiable {
        case play
        case edit
        case patterns
        case setlist
        case settings

        var id: Self { self }

        var title: String {
            switch self {
            case .play:
                "Play"
            case .edit:
                "Edit"
            case .patterns:
                "Patterns"
            case .setlist:
                "Setlist"
            case .settings:
                "Settings"
            }
        }

        var systemImage: String {
            switch self {
            case .play:
                "metronome"
            case .edit:
                "slider.horizontal.3"
            case .patterns:
                "music.note.list"
            case .setlist:
                "list.bullet.rectangle"
            case .settings:
                "gearshape"
            }
        }
    }

    private enum InstrumentTheme {
        static let background = Color(red: 0.039, green: 0.039, blue: 0.039)
        static let surface = Color(red: 0.078, green: 0.078, blue: 0.078)
        static let raisedSurface = Color(red: 0.118, green: 0.118, blue: 0.118)
        static let primaryText = Color(red: 0.910, green: 0.910, blue: 0.886)
        static let secondaryText = Color(red: 0.420, green: 0.420, blue: 0.420)
        static let accent = Color(red: 0.180, green: 0.710, blue: 0.376)
        static let hairline = Color.white.opacity(0.12)
    }

    init() {
        _viewModel = StateObject(wrappedValue: MainMetronomeViewModel())
    }

    init(viewModel: MainMetronomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            selectedTabContent
            instrumentTabBar
        }
        .preferredColorScheme(.dark)
        .tint(InstrumentTheme.accent)
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

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .play:
            playTab
        case .edit:
            editTab
        case .patterns:
            libraryTab
        case .setlist:
            setlistTab
        case .settings:
            settingsTab
        }
    }

    private var instrumentTabBar: some View {
        HStack(spacing: 0) {
            ForEach(InstrumentTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 17, weight: .semibold))
                            .frame(height: 19)

                        Text(tab.title)
                            .font(.system(size: 9, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(isSelected ? InstrumentTheme.accent : Color(red: 0.290, green: 0.290, blue: 0.290))
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(tab.title) tab")
                .accessibilityValue(isSelected ? "Selected" : "Not selected")
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 5)
        .padding(.bottom, 5)
        .background(InstrumentTheme.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(InstrumentTheme.hairline)
                .frame(height: 1)
        }
    }

    private var playTab: some View {
        ScrollView {
            VStack(spacing: 8) {
                header
                bpmDisplay
                transportControls
                countInPanel
                tempoControls
                patternSummary
                practicePanel
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, bottomTabBarContentPadding)
            .frame(maxWidth: .infinity)
        }
        .background(InstrumentTheme.background)
    }

    private var editTab: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                patternEditor
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, bottomTabBarContentPadding)
            .frame(maxWidth: .infinity)
        }
        .background(InstrumentTheme.background)
    }

    private var libraryTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                patternLibrary
            }
            .padding(24)
            .padding(.bottom, bottomTabBarContentPadding)
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
            .padding(.bottom, bottomTabBarContentPadding)
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
            .padding(.bottom, bottomTabBarContentPadding)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.pattern.name)
                    .font(.subheadline.monospaced().weight(.semibold))
                    .foregroundStyle(InstrumentTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .accessibilityLabel("Pattern \(viewModel.pattern.name)")

                Text("\(viewModel.pattern.meter.displayName) · \(viewModel.pattern.subdivisionSummary)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(InstrumentTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Meter \(viewModel.pattern.meter.displayName), subdivision \(viewModel.pattern.subdivisionSummary)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            stagePulseButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bpmDisplay: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.pattern.bpm)")
                    .font(.system(size: 98, weight: .black, design: .monospaced))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                    .foregroundStyle(InstrumentTheme.primaryText)
                    .accessibilityLabel("\(viewModel.pattern.bpm) beats per minute")

                HStack(spacing: 14) {
                    Text(viewModel.tempoMarking)
                        .font(.caption.monospaced().weight(.bold))
                        .foregroundStyle(InstrumentTheme.secondaryText)
                        .textCase(.uppercase)
                        .kerning(1.2)
                        .accessibilityIdentifier("tempo-marking")
                        .accessibilityLabel("Tempo marking \(viewModel.tempoMarking)")

                    beatVisualizer
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("BPM")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(InstrumentTheme.secondaryText)
                    .textCase(.uppercase)
                    .kerning(1.2)

                HStack(spacing: 8) {
                    TextField("BPM", text: $viewModel.bpmEntryDraft)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .font(.title3.monospacedDigit())
                        .frame(width: 82)
                        .accessibilityLabel("Tempo entry")

                    Button {
                        Task {
                            await viewModel.commitBPMEntry()
                        }
                    } label: {
                        Label("Set", systemImage: "checkmark")
                            .frame(minWidth: 66, minHeight: 40)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(InstrumentTheme.accent)
                    .background(InstrumentTheme.raisedSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(InstrumentTheme.hairline, lineWidth: 1)
                    )
                    .accessibilityLabel("Set tempo")
                }

                if let message = viewModel.bpmEntryMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(InstrumentTheme.secondaryText)
                        .accessibilityLabel(message)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var transportControls: some View {
        HStack(alignment: .center, spacing: 14) {
            Spacer(minLength: 0)

            Button {
                Task {
                    await viewModel.togglePlayback()
                }
            } label: {
                Image(systemName: viewModel.primaryTransportSystemImage)
                    .font(.system(size: 40, weight: .black))
                    .frame(width: 108, height: 108)
            }
            .buttonStyle(InstrumentCircleButtonStyle(
                fill: viewModel.isPlaying || viewModel.isCountingIn ? InstrumentTheme.raisedSurface : InstrumentTheme.accent,
                foreground: viewModel.isPlaying || viewModel.isCountingIn ? InstrumentTheme.accent : InstrumentTheme.background
            ))
            .accessibilityLabel(viewModel.primaryTransportAccessibilityLabel)

            Spacer(minLength: 0)

            Button {
                viewModel.registerTapTempo()
            } label: {
                Image(systemName: "hand.tap.fill")
                    .font(.title3.weight(.semibold))
                    .frame(width: 62, height: 62)
            }
            .buttonStyle(InstrumentOutlineButtonStyle(foreground: InstrumentTheme.accent))
            .accessibilityLabel("Tap tempo")
            .accessibilityHint("Sets tempo from recent taps.")
        }
    }

    private var beatVisualizer: some View {
        HStack(alignment: .center, spacing: 7) {
            ForEach(0..<viewModel.beatIndicatorCount, id: \.self) { index in
                let isActive = viewModel.isPlaying && viewModel.currentBeatIndex == index
                Capsule()
                    .fill(isActive ? InstrumentTheme.accent : InstrumentTheme.raisedSurface)
                    .frame(width: index == 0 ? 18 : 13, height: index == 0 ? 6 : 5)
                    .opacity(isActive ? 1.0 : 0.7)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Beat visualizer")
        .accessibilityValue(viewModel.currentBeatIndex.map { "Beat \($0 + 1)" } ?? "Stopped")
    }

    private var countInPanel: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                sectionLabel("Count-in")

                if let remaining = viewModel.countInRemainingBeats {
                    Text("\(remaining)")
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(InstrumentTheme.primaryText)
                        .accessibilityLabel("\(remaining) count-in beats remaining")
                } else {
                    Text(viewModel.countInBars == 0 ? "Off" : "\(viewModel.countInBars) bar\(viewModel.countInBars == 1 ? "" : "s")")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(InstrumentTheme.primaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button {
                    viewModel.setCountInBars(max(0, viewModel.countInBars - 1))
                } label: {
                    Label("Decrease count-in", systemImage: "minus")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(InstrumentOutlineButtonStyle(foreground: InstrumentTheme.accent))
                .disabled(viewModel.countInBars == 0 || viewModel.isPlaying || viewModel.isCountingIn)
                .accessibilityLabel("Decrease count-in")

                Button {
                    viewModel.setCountInBars(min(2, viewModel.countInBars + 1))
                } label: {
                    Label("Increase count-in", systemImage: "plus")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(InstrumentOutlineButtonStyle(foreground: InstrumentTheme.accent))
                .disabled(viewModel.countInBars == 2 || viewModel.isPlaying || viewModel.isCountingIn)
                .accessibilityLabel("Increase count-in")
            }
        }
        .padding(.vertical, 6)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(InstrumentTheme.hairline)
                .frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(InstrumentTheme.hairline)
                .frame(height: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Count-in length")
    }

    private var tempoControls: some View {
        HStack(spacing: 12) {
                tempoButton(label: "-5", delta: -5)
                tempoButton(label: "-1", delta: -1)
                tempoButton(label: "+1", delta: 1)
                tempoButton(label: "+5", delta: 5)
        }
    }

    private func tempoButton(label: String, delta: Int) -> some View {
        Button(label) {
            Task {
                await viewModel.updateBPM(by: delta)
            }
        }
        .font(.title3.monospaced().weight(.bold))
        .frame(maxWidth: .infinity, minHeight: 38)
        .buttonStyle(InstrumentTrimButtonStyle(foreground: InstrumentTheme.accent))
        .accessibilityLabel(delta > 0 ? "Increase tempo by \(delta)" : "Decrease tempo by \(abs(delta))")
    }

    private var patternSummary: some View {
        Text("\(viewModel.pattern.meter.displayName) · \(viewModel.pattern.subdivisionSummary) · \(viewModel.patterns.count) saved · Setlist \(viewModel.activeSetlist.items.count)")
            .font(.caption.monospaced().weight(.semibold))
            .foregroundStyle(InstrumentTheme.secondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("Meter \(viewModel.pattern.meter.displayName), subdivision \(viewModel.pattern.subdivisionSummary), \(viewModel.patterns.count) saved patterns, \(viewModel.activeSetlist.items.count) setlist items")
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(InstrumentTheme.secondaryText)
            .textCase(.uppercase)
            .kerning(1.2)
    }

    private func hairline() -> some View {
        Rectangle()
            .fill(InstrumentTheme.hairline)
            .frame(height: 1)
    }

    private func textOnlyPracticeDurationButton(minutes: Int) -> some View {
        Button {
            viewModel.setPracticeDuration(minutes: minutes)
        } label: {
            let isActive = viewModel.practiceTimer.durationSeconds == minutes * 60
            VStack(spacing: 4) {
                Text("\(minutes)m")
                    .font(.subheadline.monospaced().weight(.bold))
                Rectangle()
                    .fill(isActive ? InstrumentTheme.accent : Color.clear)
                    .frame(height: 2)
            }
            .foregroundStyle(isActive ? InstrumentTheme.accent : InstrumentTheme.secondaryText)
            .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Set practice timer to \(minutes) minutes")
    }

    private func summaryPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(InstrumentTheme.secondaryText)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(InstrumentTheme.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(InstrumentTheme.surface, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(InstrumentTheme.hairline, lineWidth: 1)
        )
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
        VStack(spacing: 8) {
            hairline()

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    sectionLabel("Practice")
                    Text(viewModel.practiceTimer.formattedRemaining)
                        .font(.system(size: 40, weight: .black, design: .monospaced))
                        .monospacedDigit()
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(InstrumentTheme.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Practice timer \(viewModel.practiceTimer.formattedRemaining)")

                Button {
                    viewModel.togglePracticeTimer()
                } label: {
                    Label(viewModel.practiceTimer.isRunning ? "Pause" : "Start", systemImage: viewModel.practiceTimer.isRunning ? "pause.fill" : "play.fill")
                        .labelStyle(.iconOnly)
                        .frame(width: 52, height: 52)
                }
                .buttonStyle(InstrumentCircleButtonStyle(fill: InstrumentTheme.accent, foreground: InstrumentTheme.background))
                .accessibilityLabel(viewModel.practiceTimer.isRunning ? "Pause practice timer" : "Start practice timer")

                Button {
                    viewModel.resetPracticeTimer()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .labelStyle(.iconOnly)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(InstrumentOutlineButtonStyle(foreground: InstrumentTheme.accent))
                .accessibilityLabel("Reset practice timer")
            }

            HStack(spacing: 8) {
                textOnlyPracticeDurationButton(minutes: 5)
                textOnlyPracticeDurationButton(minutes: 10)
                textOnlyPracticeDurationButton(minutes: 20)
            }

            hairline()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        sectionLabel("Tempo Ladder")
                        Text(viewModel.tempoLadderSummary)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(InstrumentTheme.primaryText)
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
                    .buttonStyle(InstrumentOutlineButtonStyle(foreground: InstrumentTheme.accent))
                    .accessibilityLabel(viewModel.tempoLadder.isEnabled ? "Stop tempo ladder" : "Start tempo ladder")
                }

                if viewModel.tempoLadder.isEnabled {
                    HStack(spacing: 8) {
                        compactLadderStepper(title: "Target", value: "\(viewModel.tempoLadder.targetBPM)", decrementLabel: "Decrease target tempo", incrementLabel: "Increase target tempo") {
                            viewModel.updateTempoLadderTarget(by: -5)
                        } increment: {
                            viewModel.updateTempoLadderTarget(by: 5)
                        }

                        compactLadderStepper(title: "Step", value: "\(viewModel.tempoLadder.stepBPM)", decrementLabel: "Decrease ladder step", incrementLabel: "Increase ladder step") {
                            viewModel.updateTempoLadderStep(by: -1)
                        } increment: {
                            viewModel.updateTempoLadderStep(by: 1)
                        }

                        compactLadderStepper(title: "Bars", value: "\(viewModel.tempoLadder.barsPerStep)", decrementLabel: "Decrease ladder bars", incrementLabel: "Increase ladder bars") {
                            viewModel.updateTempoLadderBars(by: -1)
                        } increment: {
                            viewModel.updateTempoLadderBars(by: 1)
                        }
                    }
                }
            }

            hairline()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        sectionLabel("Rhythm Trainer")
                        Text(viewModel.audioSettings.rhythmTrainer.summary)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(InstrumentTheme.primaryText)
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
        .padding(.top, 2)
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

    private func compactLadderStepper(
        title: String,
        value: String,
        decrementLabel: String,
        incrementLabel: String,
        decrement: @escaping () -> Void,
        increment: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            HStack(spacing: 2) {
                Button {
                    decrement()
                } label: {
                    Label(decrementLabel, systemImage: "minus")
                        .labelStyle(.iconOnly)
                        .frame(width: 34, height: 38)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(decrementLabel)

                Text(value)
                    .font(.headline.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .accessibilityHidden(true)

                Button {
                    increment()
                } label: {
                    Label(incrementLabel, systemImage: "plus")
                        .labelStyle(.iconOnly)
                        .frame(width: 34, height: 38)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(incrementLabel)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var patternEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Pattern")

            TextField("Pattern name", text: $viewModel.patternNameDraft)
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .font(.headline.monospaced().weight(.semibold))
                .foregroundStyle(InstrumentTheme.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(InstrumentTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(InstrumentTheme.hairline, lineWidth: 1)
                )
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
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(InstrumentTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(InstrumentTheme.hairline, lineWidth: 1)
                )
                .tint(InstrumentTheme.accent)
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
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(InstrumentTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(InstrumentTheme.hairline, lineWidth: 1)
                )
                .tint(InstrumentTheme.accent)
                .accessibilityLabel("Subdivision")
            }

            rhythmGridEditor
        }
        .frame(maxWidth: .infinity)
    }

    private var rhythmGridEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    sectionLabel("Rhythm Grid")
                    Text("Tap steps to choose the groove: accent, hit, soft, or rest.")
                        .font(.caption)
                        .foregroundStyle(InstrumentTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                rhythmLegend
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(viewModel.rhythmGridBeats) { beatGroup in
                        VStack(spacing: 8) {
                            HStack(spacing: 7) {
                                Text("\(beatGroup.beatNumber)")
                                    .font(.caption.monospaced().weight(.bold))
                                    .foregroundStyle(InstrumentTheme.primaryText)

                                Menu {
                                    ForEach(Subdivision.allCases, id: \.self) { subdivision in
                                        Button {
                                            Task {
                                                await viewModel.updateBeatSubdivision(subdivision, at: beatGroup.index)
                                            }
                                        } label: {
                                            Text(subdivision.displayName)
                                        }
                                    }
                                } label: {
                                    Text(viewModel.compactSubdivisionLabel(for: beatGroup.subdivision))
                                        .font(.caption2.monospaced().weight(.bold))
                                        .foregroundStyle(InstrumentTheme.secondaryText)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 4)
                                        .background(InstrumentTheme.surface, in: Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(InstrumentTheme.hairline, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Beat \(beatGroup.beatNumber) subdivision \(viewModel.beatSubdivisionAccessibilityLabel(at: beatGroup.index))")
                            }
                            .frame(maxWidth: .infinity)

                            HStack(alignment: .center, spacing: 6) {
                                ForEach(beatGroup.steps) { beat in
                                    rhythmStepButton(beat: beat)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 10)
                            .background(InstrumentTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(InstrumentTheme.hairline, lineWidth: 1)
                            )
                        }
                        .frame(minWidth: max(76, CGFloat(beatGroup.steps.count) * 30 + 22))
                        .accessibilityElement(children: .contain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("Rhythm Grid")
    }

    private var rhythmLegend: some View {
        HStack(spacing: 8) {
            rhythmLegendItem(accent: .strong, label: "Accent")
            rhythmLegendItem(accent: .normal, label: "Hit")
            rhythmLegendItem(accent: .ghost, label: "Soft")
            rhythmLegendItem(accent: .muted, label: "Rest")
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private func rhythmLegendItem(accent: AccentLevel, label: String) -> some View {
        HStack(spacing: 4) {
            rhythmStepGlyph(for: accent)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(InstrumentTheme.secondaryText)
        }
    }

    private func rhythmStepButton(beat: Beat) -> some View {
        Button {
            Task {
                await viewModel.cycleAccent(at: beat.index)
            }
        } label: {
            rhythmStepGlyph(for: beat.accent)
                .frame(width: 24, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Step \(beat.index + 1), \(viewModel.accessibilityLabel(for: beat.accent))")
        .accessibilityHint("Cycles between accent, hit, soft, and rest.")
        .contextMenu {
            ForEach(AccentLevel.allCases, id: \.self) { accent in
                Button {
                    Task {
                        await viewModel.setAccent(accent, at: beat.index)
                    }
                } label: {
                    Label(viewModel.menuLabel(for: accent), systemImage: viewModel.systemImage(for: accent))
                }
            }
        }
    }

    @ViewBuilder
    private func rhythmStepGlyph(for accent: AccentLevel) -> some View {
        switch accent {
        case .strong:
            Circle()
                .fill(InstrumentTheme.accent)
                .overlay(
                    Circle()
                        .stroke(InstrumentTheme.primaryText.opacity(0.9), lineWidth: 2)
                )
        case .normal:
            Circle()
                .fill(InstrumentTheme.accent)
                .scaleEffect(0.78)
        case .ghost:
            Circle()
                .stroke(InstrumentTheme.secondaryText, lineWidth: 2)
                .scaleEffect(0.72)
        case .muted:
            Capsule()
                .fill(InstrumentTheme.secondaryText.opacity(0.45))
                .frame(height: 3)
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

    private var stagePulseButton: some View {
        Button {
            isShowingStagePulse = true
        } label: {
            Label("Stage", systemImage: "rectangle.expand.vertical")
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(InstrumentOutlineButtonStyle(foreground: InstrumentTheme.accent))
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

    struct RhythmGridBeat: Identifiable {
        let index: Int
        let beatNumber: Int
        let subdivision: Subdivision
        let steps: [Beat]

        var id: Int { index }
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
    @Published var currentBeatIndex: Int?
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
    private var hasPrepared = false

    init(
        audioEngine: any MetronomeAudioEngine = AVMetronomeAudioEngine(),
        libraryStore: MetronomeLibraryStore? = try? MetronomeLibraryStore.live()
    ) {
        self.audioEngine = audioEngine
        self.libraryStore = libraryStore
    }

    func prepare() async {
        guard !hasPrepared else {
            return
        }
        hasPrepared = true

        await loadLibrary()

        await audioEngine.setEventHandler { [weak self] event in
            await self?.handleBeat(event)
        }
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
        currentBeatIndex = nil
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

    var beatIndicatorCount: Int {
        min(max(pattern.meter.beatsPerBar, 1), 12)
    }

    var tempoMarking: String {
        switch pattern.bpm {
        case ..<40: "Grave"
        case 40..<60: "Largo"
        case 60..<76: "Adagio"
        case 76..<108: "Andante"
        case 108...120: "Moderato"
        case 121..<156: "Allegro"
        case 156..<176: "Vivace"
        default: "Presto"
        }
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

    var rhythmGridBeats: [RhythmGridBeat] {
        var beatGroups: [RhythmGridBeat] = []
        var stepCursor = 0

        for meterBeatIndex in 0..<pattern.meter.beatsPerBar {
            let subdivision = beatSubdivision(at: meterBeatIndex)
            let stepCount = subdivision.stepsPerMeterBeat(beatUnit: pattern.meter.beatUnit)
            let steps = Array(pattern.beats.dropFirst(stepCursor).prefix(stepCount))

            beatGroups.append(RhythmGridBeat(
                index: meterBeatIndex,
                beatNumber: meterBeatIndex + 1,
                subdivision: subdivision,
                steps: steps
            ))

            stepCursor += stepCount
        }

        if stepCursor < pattern.beats.count {
            let remainingSteps = Array(pattern.beats.dropFirst(stepCursor))
            if !remainingSteps.isEmpty {
                beatGroups.append(RhythmGridBeat(
                    index: beatGroups.count,
                    beatNumber: beatGroups.count + 1,
                    subdivision: pattern.subdivision,
                    steps: remainingSteps
                ))
            }
        }

        return beatGroups
    }

    func compactSubdivisionLabel(for subdivision: Subdivision) -> String {
        switch subdivision {
        case .quarter: "1"
        case .eighth: "2"
        case .triplet: "3"
        case .quintuplet: "5"
        case .sixteenth: "4"
        case .septuplet: "7"
        }
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
        case .strong: "A"
        case .normal: "H"
        case .ghost: "S"
        case .muted: "R"
        }
    }

    func menuLabel(for accent: AccentLevel) -> String {
        switch accent {
        case .strong: "Accent"
        case .normal: "Hit"
        case .ghost: "Soft"
        case .muted: "Rest"
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
        case .normal: .accentColor
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
        currentBeatIndex = event.beatIndex % beatIndicatorCount

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

private struct InstrumentCircleButtonStyle: ButtonStyle {
    let fill: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background(
                Circle()
                    .fill(fill)
                    .shadow(color: .black.opacity(configuration.isPressed ? 0.25 : 0.55), radius: configuration.isPressed ? 2 : 8, x: 0, y: configuration.isPressed ? 1 : 6)
                    .shadow(color: .white.opacity(configuration.isPressed ? 0.03 : 0.08), radius: 1, x: 0, y: configuration.isPressed ? 0 : -1)
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.06 : 0.12), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

private struct InstrumentOutlineButtonStyle: ButtonStyle {
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.35 : 0.12), lineWidth: 1)
            )
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

private struct InstrumentTrimButtonStyle: ButtonStyle {
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(red: 0.118, green: 0.118, blue: 0.118))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.35 : 0.12), lineWidth: 1)
            )
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
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
