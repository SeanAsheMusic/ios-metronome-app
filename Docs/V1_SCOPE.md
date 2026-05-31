# V1 Scope

## Product Promise

V1 should feel like a trustworthy hardware metronome with modern iOS ergonomics: fast to launch, easy to read on stage, precise in intent, and respectful of the musician's data and attention.

## Included

- BPM control from 30 to 300.
- Direct numeric BPM entry.
- Play/stop UI skeleton.
- Tap tempo entry point.
- Audible one- and two-bar count-in.
- Rhythm Trainer with fixed and random silent-bar modes.
- Human Feel timing simulation with a warning for intentionally inaccurate high settings.
- Common meters: 2/4, 3/4, 4/4, 5/4, 5/8, 6/8, 7/8, 9/8, 11/8, and 12/8.
- Subdivisions: quarter, eighth, triplet, quintuplet, sixteenth, and septuplet.
- Editable subdivision-step grids for syncopations and silencing.
- Mixed per-beat subdivision editing.
- Jazz 2 and 4, swing eighth, shuffle, and half-time shuffle templates.
- Flattened polyrhythm templates for 3:2, 3:4, 4:3, 5:4, 5:3, and 7:4.
- Accent levels: strong, normal, ghost, and muted.
- Explicit per-step accent and mute editing.
- Full son, rumba, bossa, 6/8 bell, 12/8 bell, and odd-meter clave templates backed by editable step-pattern foundations.
- Clave Mode templates for traditional clave and odd-meter feels, with local mixer presets for clave, metronome click, and subdivisions.
- Pattern defaults for 4/4, 6/8, and 7/8.
- Stable identifiers for patterns, beats, setlists, and setlist items.
- Ordered setlists with move support.
- Song-form setlist sections with per-item bar counts and auto-advance.
- Local persistence for selected pattern, pattern library, and setlists.
- Bounded local snapshots before library overwrites and imports.
- Latest local snapshot restore.
- Versioned export/import storage support, Settings data controls, and Codable model support.
- Simple local practice timer with preset durations.
- Local tempo ladder practice tool.
- SwiftUI performance play screen foundation.
- Full-screen stage pulse mode.
- Accessibility labels and large touch targets.
- Settings role-level mixer controls for downbeat, beat, subdivision, and count-in cue levels.
- Playable audio engine foundation and scheduling spec.
- Settings timing summary and reset controls for device validation runs.
- Exportable click-render verification fixtures.
- Background audio mode in the generated app target.

## Explicit Non-Goals

- Tuner.
- Apple Watch.
- Cloud sync.
- Accounts.
- Subscriptions.
- Ads.
- Teacher/student sharing.
- AI coaching.
- MIDI.
- Ableton Link.
- Advanced analytics.

## V1.1 Candidates

No active source-level V1.1 candidates remain beyond device/accessibility validation and deeper deferred feature work.

## Later Candidates

- Independent audio faders for rhythm lanes, microphone accuracy checking, subdivision/lane-level pattern gestures, optional iCloud, external display, hardware pedals, MIDI, Ableton Link, and Apple Watch remote control.
