# iOS Metronome App

A native SwiftUI metronome foundation for serious musicians, educators, drummers, guitarists, performers, and students.

The product promise for v1 is simple: launch into a reliable, stage-readable metronome immediately, while laying the model foundation for a deeper rhythm workstation. Core features stay local-first, account-free, ad-free, and subscription-free.

## V1 Focus

- Core metronome pattern model
- BPM validation from 30 to 300
- Tap tempo placeholder
- Common meters, custom grouping foundation, subdivisions, and accents
- Default 4/4, 6/8, and 7/8 patterns
- Saved patterns and ordered setlists
- Large performance SwiftUI play surface
- Visual pulse placeholder
- Sound role foundation for synthesized click families
- Local persistence planning
- XCTest coverage for model behavior
- Accessibility-first UI and docs

## Deferred

Tuner, Apple Watch, cloud sync, accounts, subscriptions, ads, teacher/student sharing, AI coaching, MIDI, Ableton Link, and advanced analytics are outside v1. Some are documented as future opportunities only.

## Repository Shape

- `Sources/RhythmModel`: Compile-tested core domain model.
- `Sources/AudioEngine`: Protocol stubs and timing contracts. No production audio claims yet.
- `App`: SwiftUI app skeleton for Xcode integration.
- `Docs`: Product, architecture, audio, privacy, testing, and App Store planning.
- `Tests/RhythmModelTests`: XCTest coverage for the safe model layer.

## Build And Test

This environment has Swift but not a full active Xcode installation. The compile-tested layer is a Swift package:

```sh
swift test
```

To turn the `App` folder into a runnable iOS target, open the folder in Xcode, create a SwiftUI iOS app target, add the files under `App`, and link the local `RhythmModel` and `AudioEngine` package targets.
