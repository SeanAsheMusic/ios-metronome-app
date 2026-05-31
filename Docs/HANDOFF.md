# Handoff

## What Exists

- Empty folder was converted into a local Git-ready Swift package and SwiftUI app foundation.
- Research-backed product and architecture docs exist under `Docs`.
- Core rhythm models are implemented in `Sources/RhythmModel`.
- Audio engine protocols and the AVFoundation click engine are in `Sources/AudioEngine`.
- Local JSON persistence and bounded library snapshots live in `Sources/Persistence`.
- The generated app target includes the background audio mode.
- XCTest coverage exists for rhythm models, audio scheduling, persistence, and practice timer behavior.
- SwiftUI app UI exists under `App` with Play, Edit, Patterns, Setlist, and Settings tabs.
- `Docs/ACCESSIBILITY_AUDIT.md` records the source-level accessibility pass and the remaining device checklist.
- `Metronome.xcodeproj` is generated with app, `RhythmModel`, `AudioEngine`, `Persistence`, and test targets.

## Next Engineering Task

Open `Metronome.xcodeproj` in Xcode, set the Apple development team, run the shared schemes, and test playback plus the accessibility checklist on a real device and representative simulators.

## Do Not Do Next

Do not start with tuner, accounts, cloud sync, subscriptions, ads, Apple Watch, Ableton Link, or MIDI. The next valuable work is full Xcode/device validation, timing measurement, accessibility verification, and polish on the core metronome flows.
