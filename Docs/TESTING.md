# Testing

## Current Coverage

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

## Future Test Layers

- Rhythm model property tests for odd meters and grouping.
- Persistence migration tests for every schema version.
- Audio drift and jitter tests on physical devices.
- Route-change tests for speaker, wired headphones, Bluetooth, and AirPlay.
- SwiftUI snapshot tests for Dynamic Type, RTL, dark mode, and compact iPhone screens.
- Accessibility Inspector and on-device VoiceOver flows.

## Device Buckets

Use representative buckets rather than every SKU: small home-button iPhone, compact notched iPhone, mainstream current iPhone, large ProMotion phone, iPad mini, baseline iPad, Apple Silicon iPad Air, and iPad Pro with external display/Stage Manager.
