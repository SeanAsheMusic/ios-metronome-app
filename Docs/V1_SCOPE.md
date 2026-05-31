# V1 Scope

## Product Promise

V1 should feel like a trustworthy hardware metronome with modern iOS ergonomics: fast to launch, easy to read on stage, precise in intent, and respectful of the musician's data and attention.

## Included

- BPM control from 30 to 300.
- Direct numeric BPM entry.
- Play/stop UI skeleton.
- Tap tempo entry point.
- Audible one- and two-bar count-in.
- Common meters: 2/4, 3/4, 4/4, 5/4, 6/8, 7/8, 9/8, and 12/8.
- Subdivisions: quarter, eighth, triplet, and sixteenth.
- Accent levels: strong, normal, ghost, and muted.
- Explicit per-beat accent and mute editing.
- Full son, rumba, and bossa clave templates backed by a 16-step pattern foundation.
- Clave Mode templates for traditional clave and odd-meter feels, with local mixer presets for clave, metronome click, and subdivisions.
- Pattern defaults for 4/4, 6/8, and 7/8.
- Stable identifiers for patterns, beats, setlists, and setlist items.
- Ordered setlists with move support.
- Local persistence for selected pattern, pattern library, and setlists.
- Bounded local snapshots before library overwrites and imports.
- Latest local snapshot restore.
- Versioned export/import storage support, Settings data controls, and Codable model support.
- Simple local practice timer with preset durations.
- Local tempo ladder practice tool.
- SwiftUI performance play screen foundation.
- Full-screen stage pulse mode.
- Accessibility labels and large touch targets.
- Playable audio engine foundation and scheduling spec.
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

- Independent audio faders for rhythm lanes, subdivision/lane-level pattern gestures, jazz 2 and 4, swing, gap click, random silence, polyrhythm, song forms, optional iCloud, external display, hardware pedals, MIDI, Ableton Link, and Apple Watch remote control.
