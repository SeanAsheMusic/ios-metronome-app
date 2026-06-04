# Handoff

## What Exists

- Empty folder was converted into a local Git-ready Swift package and SwiftUI app foundation.
- Research-backed product and architecture docs exist under `Docs`.
- Core rhythm models are implemented in `Sources/RhythmModel`.
- Audio engine protocols and the AVFoundation click engine are in `Sources/AudioEngine`.
- Local JSON persistence, bounded library snapshots, and latest snapshot restore live in `Sources/Persistence`.
- Local musician setup/profile, mic calibration, MIDI settings, and setlist cue fields are included in the versioned library schema.
- `Sources/BeatCoach` contains the first local onset, tempo-estimation, timing-feedback, and calibration contracts.
- `Sources/MIDIConnectivity` contains the first local MIDI endpoint, message, clock, follower-tempo, and cue-generation contracts.
- The generated app target includes the background audio mode.
- XCTest coverage exists for rhythm models, audio scheduling, persistence, and practice timer behavior.
- SwiftUI app UI exists under `App` with Play, Edit, Patterns, Setlist, and Settings tabs.
- `Docs/ACCESSIBILITY_AUDIT.md` records the source-level accessibility pass and the remaining device checklist.
- `Docs/DEVICE_VALIDATION_RUNBOOK.md` records the full device-validation pass/fail matrix.
- `Metronome.xcodeproj` is generated with app, `RhythmModel`, `AudioEngine`, `Persistence`, and test targets.
- Current source has been validated with Swift package tests, click fixture checksums, iPhone 17 simulator Xcode scheme tests, simulator app build, and iPhone 17 simulator screenshot smoke checks for Play, Edit, Patterns, Setlist, Settings, and Stage Pulse.

## Next Engineering Task

Open `Metronome.xcodeproj` in Xcode, set the Apple development team, run the shared schemes on physical hardware, connect real MIDI devices/loopbacks, test Beat Coach with real microphones and instruments, and execute `Docs/DEVICE_VALIDATION_RUNBOOK.md` on real devices.

## Do Not Do Next

Do not start with tuner, accounts, cloud sync, subscriptions, ads, Apple Watch, Ableton Link, or public precision claims. The next valuable work is physical-device validation, MIDI hardware measurement, Beat Coach calibration, accessibility verification, signing setup, and polish on the core performance flows.
