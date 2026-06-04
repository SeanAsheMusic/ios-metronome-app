import XCTest
@testable import BeatCoach

final class BeatCoachTests: XCTestCase {
    func testDetectOnsetsFindsSeparatedTransients() {
        let service = BasicBeatCoachService(onsetThreshold: 0.6, minimumOnsetSpacingSeconds: 0.1)
        var samples = Array(repeating: 0.02, count: 2_000)
        samples[100] = 0.9
        samples[700] = 0.85
        samples[1_300] = 0.88

        let onsets = service.detectOnsets(samples: samples, sampleRate: 1_000, startTimestamp: 10_000)

        XCTAssertEqual(onsets.count, 3)
        XCTAssertEqual(onsets.map(\.timestamp), [100_010_000, 700_010_000, 1_300_010_000])
    }

    func testTempoEstimateRejectsUnstableInput() {
        let service = BasicBeatCoachService()
        let unstable = [
            BeatCoachOnset(timestamp: 0, amplitude: 1),
            BeatCoachOnset(timestamp: 400_000_000, amplitude: 1),
            BeatCoachOnset(timestamp: 1_300_000_000, amplitude: 1),
            BeatCoachOnset(timestamp: 1_700_000_000, amplitude: 1)
        ]

        XCTAssertNil(service.estimateTempo(from: unstable))
    }

    func testTempoEstimateAcceptsStablePulse() {
        let service = BasicBeatCoachService()
        let onsets = (0..<5).map {
            BeatCoachOnset(timestamp: UInt64($0) * 500_000_000, amplitude: 1)
        }

        XCTAssertEqual(service.estimateTempo(from: onsets), 120)
    }

    func testTimingFeedbackAppliesCalibrationOffset() {
        let service = BasicBeatCoachService(onBeatWindowMilliseconds: 20)

        let feedback = service.timingFeedback(
            onsetTimestamp: 1_055_000_000,
            scheduledTimestamp: 1_000_000_000,
            calibrationOffsetMilliseconds: 30
        )

        XCTAssertEqual(feedback.grade, .late)
        XCTAssertEqual(feedback.offsetMilliseconds, 25, accuracy: 0.001)
    }
}

