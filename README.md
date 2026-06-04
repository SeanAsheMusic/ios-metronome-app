# Click Track

A native SwiftUI click-track, metronome, practice, playlist, and show-control foundation for serious musicians, educators, drummers, guitarists, performers, and students.

The product promise for v1 is simple: launch into a reliable, stage-readable metronome immediately, while laying the model foundation for a deeper rhythm workstation. Core features stay local-first, account-free, ad-free, and subscription-free.

## V1 Focus

- Core metronome pattern model
- BPM validation from 30 to 300
- Direct numeric BPM entry
- Tap tempo from recent taps
- Audible one- and two-bar count-in
- Rhythm Trainer with fixed silent bars, random silent bars, random beat dropout, 2-and-4 guide, and 1-and-3 dropout modes
- Human Feel timing simulation with a high-humanization warning
- Common meters, custom grouping foundation, subdivisions, and accents
- Editable subdivision-step grids for syncopation and beat silencing
- Mixed per-beat subdivisions, including triplets, quintuplets, sixteenths, and septuplets
- Jazz 2 and 4, swing eighth, shuffle, and half-time shuffle templates
- Flattened polyrhythm templates for 3:2, 3:4, 4:3, 5:4, 5:3, and 7:4
- Full son, rumba, bossa, 6/8 bell, 12/8 bell, and odd-meter clave template set
- Clave Mode with clave-only, click-only, clave-plus-click, and subdivision mixer presets
- Default 4/4, 6/8, and 7/8 patterns
- Saved pattern switching, duplication, and groove template creation
- Protected saved-pattern deletion
- Pattern name, meter, subdivision, and explicit per-step accent/mute editing
- Saved patterns and ordered setlists with add, select, reorder, and remove controls
- Song-form setlists with per-section bar counts and auto-advance
- Tabbed Play, Edit, Patterns, Setlist, and Settings app layout
- Simple local practice timer on the Play screen with 5, 10, and 20 minute presets
- Local tempo ladder practice tool with target, step, and bars-per-step controls
- Settings tab for 13 synthesized click presets, volume, accent boost, role-level mixer controls, mixer reset, and Precision mode
- Runtime synthesized click provenance manifest
- Exportable click-render verification WAVs with checksums
- Audio output status with wireless latency warning
- App privacy manifest declaring no tracking and no collected data
- Large performance SwiftUI play surface wired to playback state
- Visual pulse driven by scheduled beat events
- Reduce Motion-aware visual pulse
- Full-screen stage pulse mode
- Synthesized click engine foundation using AVFoundation
- Audio timing measurement harness for device validation
- Settings timing summary and reset controls for device validation runs
- Generated app project includes background audio mode for lock-screen practice/live use
- Local JSON persistence for selected pattern, pattern library, and setlists
- Bounded local library snapshots before overwrites/imports
- Latest local library snapshot restore
- Versioned local library export/import support
- Settings Data controls for library export/import and latest snapshot restore
- XCTest coverage for model, practice ladder, and scheduler behavior
- Accessibility-first UI and docs
- Local Beat Coach foundation for microphone tempo detection and timing feedback, with device calibration required before accuracy claims.
- MIDI connector foundation for master/follower clock and setlist cue workflows.

## Deferred

Tuner, Apple Watch, cloud sync, accounts, subscriptions, ads, teacher/student sharing, AI coaching, Ableton Link, and advanced analytics are outside v1. Some are documented as future opportunities only.

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
Tools/run_local_validation.sh
```

This repository has been validated with privacy/local-first checks, Swift package tests, click fixture checksums, iPhone 17 simulator builds/tests, a warning-clean generic iOS device build and unsigned archive with signing disabled, and simulator screenshot smoke checks for Play, Edit, Patterns, Setlist, Settings, and Stage Pulse. The package tests can also be run directly with:

```sh
swift test
```
