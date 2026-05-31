# Handoff

## What Exists

- Empty folder was converted into a local Git-ready Swift package foundation.
- Research-backed product and architecture docs exist under `Docs`.
- Core rhythm models are implemented in `Sources/RhythmModel`.
- Audio engine protocols are in `Sources/AudioEngine`.
- XCTest coverage exists in `Tests/RhythmModelTests`.
- SwiftUI app skeleton exists under `App`.
- `Metronome.xcodeproj` is generated with app, `RhythmModel`, `AudioEngine`, and `RhythmModelTests` targets.

## Next Engineering Task

Open `Metronome.xcodeproj` in Xcode, set the Apple development team, run the `RhythmModelTests` target, and then start the AVFoundation timing prototype with measurement hooks.

## Do Not Do Next

Do not start with tuner, accounts, cloud sync, subscriptions, ads, Apple Watch, Ableton Link, or MIDI. The next valuable work is an AVFoundation prototype with measurement hooks or local persistence for patterns and setlists.
