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
- Pattern rename, meter update, editable subdivision-step regeneration, beat accent cycling, and explicit beat accent assignment.
- Mixed per-beat subdivision generation and variable scheduler intervals.
- Pattern deletion and setlist-reference cleanup.
- Setlist item add, select, move, and remove operations.
- Song-form setlist section bar counts.
- Audio settings clamping and persistence.
- Rhythm Trainer fixed-bar, random-bar, random-beat, guide-tone, and dropout mute behavior plus Human Feel warning thresholds.
- Portable library export/import and raw-library recovery import.
- Bounded local snapshots before library overwrites and imports.
- Latest local snapshot restore.
- Settings data export/import UI plumbing.
- Practice timer formatting, duration selection, countdown, and clamping behavior.
- Tempo ladder clamping, bar counting, step-up, step-down, and target-stop behavior.
- Audio route latency-risk classification for wireless, built-in, and unavailable outputs.
- Direct BPM entry uses the same 30-300 validation as button and tap-tempo changes.
- Son, rumba, and bossa clave templates, including 16-step scheduling intervals and muted steps.
- Clave Mode mixer presets for clave-only, click-only, clave-plus-click, subdivisions, and odd-meter feel templates.
- Jazz 2 and 4, swing eighth, shuffle, and half-time shuffle templates.
- Flattened polyrhythm templates for primary and cross-pulse hit placement.
- Visual pulse respects the Reduce Motion environment setting.
- Full-screen stage pulse follows the same playback pulse state.
- Audio engine one-shot cue events for count-in.
- Audio timing summary and bounded timing measurement recorder behavior.
- Exportable click-render verification WAV fixtures and SHA-256 checksums.

Run the package suite with:

```sh
swift test
```

## Local Validation Gate

Use the local validation script before pushing release-candidate work:

```sh
Tools/run_local_validation.sh
```

The script verifies the privacy manifest and local-first policy, runs `swift test`, verifies `SoundLibrary/RenderedVerification/SHA256SUMS`, runs the shared `RhythmModel`, `AudioEngine`, `Persistence`, and `MetronomeUITests` Xcode test schemes, rejects Xcode warning output, builds the `Metronome` app for an iPhone simulator and a generic iOS device with code signing disabled, creates an unsigned generic iOS archive containing `Pulsecraft.app`, verifies archived app metadata and privacy manifest contents, installs the simulator build, launches it, captures a first-screen smoke-test screenshot, and terminates it. The UI smoke tests launch Pulsecraft, assert the Play screen and redesigned performance controls are visible, tap through all five primary navigation surfaces, and verify Stage Pulse opens and closes from the Play surface. It defaults to `platform=iOS Simulator,name=iPhone 17`; pass another destination string as the first argument when needed.

Manual fallback commands:

```sh
plutil -lint App/PrivacyInfo.xcprivacy
xcodebuild test -project Metronome.xcodeproj -scheme RhythmModel -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
xcodebuild test -project Metronome.xcodeproj -scheme AudioEngine -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
xcodebuild test -project Metronome.xcodeproj -scheme Persistence -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
xcodebuild test -project Metronome.xcodeproj -scheme MetronomeUITests -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
xcodebuild build -project Metronome.xcodeproj -scheme Metronome -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
xcodebuild build -project Metronome.xcodeproj -scheme Metronome -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
xcodebuild archive -project Metronome.xcodeproj -scheme Metronome -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO SKIP_INSTALL=NO -archivePath /tmp/PulsecraftLocalValidation/Pulsecraft.xcarchive
xcrun simctl install booted /tmp/PulsecraftLocalValidation/Metronome/Build/Products/Debug-iphonesimulator/Pulsecraft.app
xcrun simctl launch booted com.seanashe.metronome
```

Physical-device validation, signing, route checks, interruption handling, and accessibility verification still require full Xcode plus hardware and are tracked in `Docs/DEVICE_VALIDATION_RUNBOOK.md`.

## Current Source Audits

- `Docs/ACCESSIBILITY_AUDIT.md` covers Play, Stage Pulse, Edit, Patterns, Setlist, Settings, Reduce Motion, touch targets, and manual verification gaps.
- The production AV engine observes audio-session interruptions, route changes, and media-service resets, with device validation still required.
- `Docs/DEVICE_VALIDATION_RUNBOOK.md` defines the device pass/fail checks needed for build, playback, timing, routes, interruptions, accessibility, and data recovery.
- `SoundLibrary/RenderedVerification` contains generated WAV fixtures for all 13 click presets for listening review and checksum verification.

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
