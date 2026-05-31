import SwiftUI
import RhythmModel

struct MainMetronomeView: View {
    @State private var pattern = Pattern.defaultFourFour()
    @State private var isPlaying = false
    @State private var pulseIsActive = false

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
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(pattern.name)
                .font(.title3.weight(.semibold))
                .accessibilityLabel("Pattern \(pattern.name)")

            Text("\(pattern.meter.displayName) · \(pattern.subdivision.displayName)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Meter \(pattern.meter.displayName), subdivision \(pattern.subdivision.displayName)")
        }
    }

    private var bpmDisplay: some View {
        VStack(spacing: 4) {
            Text("\(pattern.bpm)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.65)
                .accessibilityLabel("\(pattern.bpm) beats per minute")

            Text("BPM")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var transportControls: some View {
        HStack(spacing: 16) {
            Button {
                isPlaying.toggle()
                pulseIsActive = isPlaying
            } label: {
                Label(isPlaying ? "Stop" : "Play", systemImage: isPlaying ? "stop.fill" : "play.fill")
                    .frame(maxWidth: .infinity, minHeight: 64)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel(isPlaying ? "Stop metronome" : "Play metronome")

            Button {
            } label: {
                Label("Tap", systemImage: "hand.tap.fill")
                    .frame(maxWidth: .infinity, minHeight: 64)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityLabel("Tap tempo")
            .accessibilityHint("Tap tempo is a placeholder in this foundation.")
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
            updateBPM(by: delta)
        }
        .font(.title3.weight(.semibold))
        .frame(minWidth: 64, minHeight: 56)
        .buttonStyle(.bordered)
        .accessibilityLabel(delta > 0 ? "Increase tempo by \(delta)" : "Decrease tempo by \(abs(delta))")
    }

    private var patternSummary: some View {
        HStack(spacing: 12) {
            summaryPill(title: "Meter", value: pattern.meter.displayName)
            summaryPill(title: "Subdivision", value: pattern.subdivision.displayName)
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
            .fill(pulseIsActive ? Color.accentColor : Color.secondary.opacity(0.3))
            .frame(width: 112, height: 112)
            .scaleEffect(pulseIsActive ? 1.0 : 0.82)
            .animation(.snappy(duration: 0.18), value: pulseIsActive)
            .accessibilityLabel("Visual pulse")
            .accessibilityValue(pulseIsActive ? "Active" : "Inactive")
    }

    private func updateBPM(by delta: Int) {
        let newValue = min(Pattern.maximumBPM, max(Pattern.minimumBPM, pattern.bpm + delta))
        pattern.bpm = newValue
    }
}

#Preview {
    MainMetronomeView()
}
