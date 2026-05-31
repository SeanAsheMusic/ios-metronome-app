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
| `RhythmModel` | Pattern, meter, subdivision-step generation, accent, beat generation, setlist ordering, Codable support. |
| `AudioEngine` | Audio scheduling protocol, event contracts, future AVFoundation implementation boundary. |
| `App` | SwiftUI app entry and performance play screen. |
| `PatternEditor` | Future beat/accent/grouping editing views. |
| `Setlists` | Ordered setlist library, section bar counts, reorder workflows, and song-form auto-advance. |
| `Persistence` | Local store, migration boundary, snapshots, latest snapshot restore, and export/import. |
| `SoundLibrary` | Synthesized click preset notes and provenance manifest. |
| `Practice` | Practice timers, tempo ladders, rhythm-trainer gap modes, and local-only analytics. |
| `RhythmModel.GrooveTemplate` | Built-in 16-step son, rumba, and bossa clave templates. |
| `RhythmModel.ClaveModeTemplate` | Traditional clave, 6/8 and 12/8 bell patterns, odd-meter clave-feel templates, and flattened local mixer presets for clave, metronome click, and subdivisions. |
| `RhythmModel.SwingTemplate` | Jazz 2 and 4, swing eighth, shuffle, and half-time shuffle patterns backed by variable step durations. |
| `RhythmModel.PolyrhythmTemplate` | Flattened single-pattern polyrhythms for common cross-rhythm practice without independent lane faders. |
| `Accessibility` | Accessibility helpers and audit notes. |
| `DesignSystem` | Semantic spacing, typography, and control conventions. |

## Data Flow

SwiftUI views should read observable app state, mutate domain models through focused actions, and never own audio scheduling details. The audio engine should receive immutable schedule snapshots and publish timestamped beat events for visual pulse and haptic followers.

Pattern subdivision changes regenerate editable step grids in the domain model. For simple meters, eighth, triplet, quintuplet, sixteenth, and septuplet subdivisions expand each meter beat. For compound eighth-note meters, eighth remains the meter beat and sixteenth creates two steps per meter beat. Mixed per-beat subdivision patterns carry per-step duration metadata so the audio scheduler can handle non-uniform beat divisions without forcing everything onto a fake uniform grid.

Rhythm Trainer, Human Feel, and role-level mixer controls live in audio settings so playback can mute, nudge, or rebalance scheduled events without rewriting the user's saved pattern. Human Feel must remain at zero for measurement and precision claims.

Microphone accuracy checking is architecturally possible with an input tap, onset detector, and scheduled-click comparison window, but it should not ship until the app has microphone permission text, input-latency calibration, false-positive handling, and device validation.

Clave Mode currently renders mixer choices into a single playable pattern so the existing audio source of truth remains intact. Independent per-lane audio faders should be added only after the audio engine supports simultaneous lane events without compromising timing.

Polyrhythm templates follow the same v1 approach: they flatten primary and cross pulses into one scheduled pattern, with primary pulse hits mapped to beat sounds and cross-pulse-only hits mapped to subdivision sounds. Role-level mixer controls can rebalance downbeat, beat, subdivision, and count-in cue sounds; true lane-specific volume and sound selection remains a later audio-engine feature.

Song-form auto-advance uses setlist item bar counts and scheduled audio beat events. Bar-based practice features must run even when the audible downbeat is muted, so state progression happens before muted events are ignored by visual pulse handling.

## Persistence Direction

Patterns, songs, profiles, setlists, attachments, practice sessions, and preferences should be stored locally with explicit schema versions. Latest snapshot restore and export/import should exist before optional iCloud so users always have account-free recovery.
