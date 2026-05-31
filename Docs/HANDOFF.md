# Handoff

## What Exists

- Empty folder was converted into a local Git-ready Swift package foundation.
- Research-backed product and architecture docs exist under `Docs`.
- Core rhythm models are implemented in `Sources/RhythmModel`.
- Audio engine protocols are in `Sources/AudioEngine`.
- XCTest coverage exists in `Tests/RhythmModelTests`.
- SwiftUI app skeleton exists under `App` and is ready to add to an Xcode iOS target.

## Next Engineering Task

Create a real Xcode iOS app target that links `RhythmModel` and `AudioEngine`, adds the files under `App`, configures iOS 17+ deployment, and enables background audio only when the AVFoundation implementation is ready.

## Do Not Do Next

Do not start with tuner, accounts, cloud sync, subscriptions, ads, Apple Watch, Ableton Link, or MIDI. The next valuable work is an AVFoundation prototype with measurement hooks or local persistence for patterns and setlists.
