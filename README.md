# Pulsecraft

A native SwiftUI metronome foundation for serious musicians, educators, drummers, guitarists, performers, and students.

The product promise for v1 is simple: launch into a reliable, stage-readable metronome immediately, while laying the model foundation for a deeper rhythm workstation. Core features stay local-first, account-free, ad-free, and subscription-free.

## V1 Focus

- Core metronome pattern model
- BPM validation from 30 to 300
- Tap tempo from recent taps
- Common meters, custom grouping foundation, subdivisions, and accents
- Default 4/4, 6/8, and 7/8 patterns
- Saved pattern switching and duplication
- Protected saved-pattern deletion
- Pattern name, meter, subdivision, and beat accent editing
- Saved patterns and ordered setlists with add, select, reorder, and remove controls
- Tabbed Play, Edit, Patterns, and Setlist app layout
- Settings tab for synthesized click preset, volume, and accent boost
- App privacy manifest declaring no tracking and no collected data
- Large performance SwiftUI play surface wired to playback state
- Visual pulse driven by scheduled beat events
- Synthesized click engine foundation using AVFoundation
- Local JSON persistence for selected pattern, pattern library, and setlists
- Versioned local library export/import support
- XCTest coverage for model and scheduler behavior
- Accessibility-first UI and docs

## Deferred

Tuner, Apple Watch, cloud sync, accounts, subscriptions, ads, teacher/student sharing, AI coaching, MIDI, Ableton Link, and advanced analytics are outside v1. Some are documented as future opportunities only.

## Repository Shape

- `Sources/RhythmModel`: Core domain model for patterns, meters, accents, and setlists.
- `Sources/AudioEngine`: AVFoundation click engine, scheduler, and testable timing contracts.
- `Sources/Persistence`: Versioned JSON library store and saved-pattern operations for local-first data.
- `App`: SwiftUI app skeleton for Xcode integration.
- `Docs`: Product, architecture, audio, privacy, testing, and App Store planning.
- `Tests/RhythmModelTests`: XCTest coverage for the safe model layer.
- `Tests/AudioEngineTests`: XCTest coverage for scheduling and stub event delivery.
- `Tests/PersistenceTests`: XCTest coverage for local library storage.

## Build And Test

The repository includes a generated Xcode project and a Swift package manifest.

```sh
xcodebuild test -project Metronome.xcodeproj -scheme RhythmModel -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -project Metronome.xcodeproj -scheme AudioEngine -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -project Metronome.xcodeproj -scheme Persistence -destination 'platform=iOS Simulator,name=iPhone 16'
```

This environment has Swift but not a full active Xcode installation, so local test execution currently needs Xcode selected. The model package can also be tested with:

```sh
swift test
```
