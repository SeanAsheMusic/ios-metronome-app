# Architecture

## Principles

- SwiftUI first, iOS 17+ baseline.
- Shared core domain model with thin app-surface adapters.
- Scene-size-driven layout; no assumptions about a single window, notch, island, or full-screen iPad.
- Audio timing is the source of truth once the audio engine exists.
- Local-first durable data with versioned Codable models before any optional sync.
- No third-party dependencies in v1 unless a concrete problem cannot be solved well with Apple frameworks.

## Modules

| Module | Responsibility |
|---|---|
| `RhythmModel` | Pattern, meter, subdivision, accent, beat generation, setlist ordering, Codable support. |
| `AudioEngine` | Audio scheduling protocol, event contracts, future AVFoundation implementation boundary. |
| `App` | SwiftUI app entry and performance play screen. |
| `PatternEditor` | Future beat/accent/grouping editing views. |
| `Setlists` | Future setlist library and reorder workflows. |
| `Persistence` | Future local store, migration, snapshots, export/import. |
| `SoundLibrary` | Future synthesized click presets and provenance manifests. |
| `Practice` | Future timers, mute trainers, tempo ladders, and local-only analytics. |
| `Accessibility` | Accessibility helpers and audit notes. |
| `DesignSystem` | Semantic spacing, typography, and control conventions. |

## Data Flow

SwiftUI views should read observable app state, mutate domain models through focused actions, and never own audio scheduling details. The audio engine should receive immutable schedule snapshots and publish timestamped beat events for visual pulse and haptic followers.

## Persistence Direction

Patterns, songs, profiles, setlists, attachments, practice sessions, and preferences should be stored locally with explicit schema versions. Export/import should be designed before optional iCloud so users always have account-free recovery.
