# Testing

## Current Automated Coverage

The Swift package includes XCTest coverage for:

- BPM validation.
- Meter validation.
- Subdivision validation.
- Default pattern creation.
- Beat generation.
- Accent behavior.
- Setlist ordering.
- Codable round trip.
- Beat interval scheduling.
- Schedule beat wrapping.
- Stub audio event delivery.
- Default persisted library shape.
- JSON library store round trip.
- Pattern selection, duplication, and deletion library operations.
- Persistence validation for empty pattern libraries.
- Pattern rename, meter update, subdivision update, beat accent cycling, and explicit beat accent assignment.
- Pattern deletion and setlist-reference cleanup.
- Setlist item add, select, move, and remove operations.
- Audio settings clamping and persistence.
- Portable library export/import and raw-library recovery import.
- Bounded local snapshots before library overwrites and imports.
- Latest local snapshot restore.
- Settings data export/import UI plumbing.
- Practice timer formatting, duration selection, countdown, and clamping behavior.
- Tempo ladder clamping, bar counting, step-up, step-down, and target-stop behavior.
- Audio route latency-risk classification for wireless, built-in, and unavailable outputs.
- Direct BPM entry uses the same 30-300 validation as button and tap-tempo changes.
- Clave and bossa groove templates, including 16-step scheduling intervals and muted steps.
- Visual pulse respects the Reduce Motion environment setting.
- Full-screen stage pulse follows the same playback pulse state.
- Audio engine one-shot cue events for count-in.
- Audio timing summary and bounded timing measurement recorder behavior.
- Exportable click-render verification WAV fixtures and SHA-256 checksums.

Run with:

```sh
swift test
```

## Current Environment Note

On this machine, `swift test` currently fails before compiling project code because the active developer directory is `/Library/Developer/CommandLineTools`, not a full Xcode install, and the Command Line Tools Swift/PackageDescription setup reports manifest-linking errors. A direct Swift type-check also fails while importing Foundation due to a `SwiftBridging` module redefinition inside the Command Line Tools SDK. Re-run tests after installing/selecting full Xcode:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
swift test
```

The generated Xcode project also includes shared `RhythmModel`, `AudioEngine`, `Persistence`, and `Metronome` schemes. Use the dedicated schemes for module tests once full Xcode is active.

## Current Source Audits

- `Docs/ACCESSIBILITY_AUDIT.md` covers Play, Stage Pulse, Edit, Patterns, Setlist, Settings, Reduce Motion, touch targets, and manual verification gaps.
- The production AV engine observes audio-session interruptions, route changes, and media-service resets, with device validation still required.
- `Docs/DEVICE_VALIDATION_RUNBOOK.md` defines the device pass/fail checks needed for build, playback, timing, routes, interruptions, accessibility, and data recovery.
- `SoundLibrary/RenderedVerification` contains generated WAV fixtures for click listening review and checksum verification.

## Future Test Layers

- Rhythm model property tests for odd meters and grouping.
- Persistence migration tests for every schema version.
- Audio drift and jitter tests on physical devices using the timing recorder plus external observation where possible.
- Route-change tests for speaker, wired headphones, Bluetooth, and AirPlay.
- Interruption tests for phone calls, Siri, Control Center audio, headphones disconnect, and media-service reset.
- SwiftUI snapshot tests for Dynamic Type, RTL, dark mode, and compact iPhone screens.
- Accessibility Inspector and on-device VoiceOver flows using `Docs/ACCESSIBILITY_AUDIT.md` as the checklist.

## Device Buckets

Use representative buckets rather than every SKU: small home-button iPhone, compact notched iPhone, mainstream current iPhone, large ProMotion phone, iPad mini, baseline iPad, Apple Silicon iPad Air, and iPad Pro with external display/Stage Manager.
