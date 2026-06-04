import Foundation

public struct BeatCoachOnset: Equatable, Sendable {
    public var timestamp: UInt64
    public var amplitude: Double

    public init(timestamp: UInt64, amplitude: Double) {
        self.timestamp = timestamp
        self.amplitude = amplitude
    }
}

public enum BeatTimingGrade: String, Codable, Equatable, Sendable {
    case early
    case onBeat
    case late
}

public struct BeatTimingFeedback: Equatable, Sendable {
    public var grade: BeatTimingGrade
    public var offsetMilliseconds: Double

    public init(grade: BeatTimingGrade, offsetMilliseconds: Double) {
        self.grade = grade
        self.offsetMilliseconds = offsetMilliseconds
    }
}

public protocol BeatCoachService: Sendable {
    func detectOnsets(samples: [Double], sampleRate: Double, startTimestamp: UInt64) -> [BeatCoachOnset]
    func estimateTempo(from onsets: [BeatCoachOnset]) -> Int?
    func timingFeedback(onsetTimestamp: UInt64, scheduledTimestamp: UInt64, calibrationOffsetMilliseconds: Double) -> BeatTimingFeedback
}

public struct BasicBeatCoachService: BeatCoachService {
    private let onsetThreshold: Double
    private let minimumOnsetSpacingSeconds: Double
    private let onBeatWindowMilliseconds: Double

    public init(
        onsetThreshold: Double = 0.62,
        minimumOnsetSpacingSeconds: Double = 0.12,
        onBeatWindowMilliseconds: Double = 35
    ) {
        self.onsetThreshold = onsetThreshold
        self.minimumOnsetSpacingSeconds = minimumOnsetSpacingSeconds
        self.onBeatWindowMilliseconds = onBeatWindowMilliseconds
    }

    public func detectOnsets(samples: [Double], sampleRate: Double, startTimestamp: UInt64 = 0) -> [BeatCoachOnset] {
        guard sampleRate > 0, !samples.isEmpty else {
            return []
        }

        let minimumSpacingSamples = Int((minimumOnsetSpacingSeconds * sampleRate).rounded())
        var lastOnsetIndex = -minimumSpacingSamples
        var onsets: [BeatCoachOnset] = []
        var previousMagnitude = 0.0

        for (index, sample) in samples.enumerated() {
            let magnitude = abs(sample)
            let transient = magnitude - previousMagnitude
            previousMagnitude = max(previousMagnitude * 0.92, magnitude)

            guard magnitude >= onsetThreshold,
                  transient > 0.18,
                  index - lastOnsetIndex >= minimumSpacingSamples else {
                continue
            }

            let timestamp = startTimestamp + UInt64((Double(index) / sampleRate * 1_000_000_000.0).rounded())
            onsets.append(BeatCoachOnset(timestamp: timestamp, amplitude: magnitude))
            lastOnsetIndex = index
        }

        return onsets
    }

    public func estimateTempo(from onsets: [BeatCoachOnset]) -> Int? {
        guard onsets.count >= 4 else {
            return nil
        }

        let intervals = zip(onsets.dropFirst(), onsets).map { current, previous in
            Double(current.timestamp - previous.timestamp) / 1_000_000_000.0
        }
        let filtered = intervals.filter { 0.2...2.0 ~= $0 }
        guard filtered.count >= 3 else {
            return nil
        }

        let average = filtered.reduce(0, +) / Double(filtered.count)
        let variance = filtered
            .map { pow($0 - average, 2) }
            .reduce(0, +) / Double(filtered.count)

        guard sqrt(variance) <= average * 0.18 else {
            return nil
        }

        return min(300, max(30, Int((60.0 / average).rounded())))
    }

    public func timingFeedback(
        onsetTimestamp: UInt64,
        scheduledTimestamp: UInt64,
        calibrationOffsetMilliseconds: Double = 0
    ) -> BeatTimingFeedback {
        let rawOffsetMilliseconds = (Double(onsetTimestamp) - Double(scheduledTimestamp)) / 1_000_000.0
        let correctedOffset = rawOffsetMilliseconds - calibrationOffsetMilliseconds

        let grade: BeatTimingGrade
        if correctedOffset < -onBeatWindowMilliseconds {
            grade = .early
        } else if correctedOffset > onBeatWindowMilliseconds {
            grade = .late
        } else {
            grade = .onBeat
        }

        return BeatTimingFeedback(grade: grade, offsetMilliseconds: correctedOffset)
    }
}

