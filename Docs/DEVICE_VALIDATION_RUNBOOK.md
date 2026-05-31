# Device Validation Runbook

Use this runbook before App Store submission and before any claim about production timing precision. Record device model, iOS version, app commit, output route, observed result, and pass/fail for every run.

## Setup

- Open `Metronome.xcodeproj` in full Xcode.
- Set the development team and signing for the `Metronome` target.
- Run the shared `RhythmModel`, `AudioEngine`, and `Persistence` test schemes.
- Install on at least one compact iPhone, one current mainstream iPhone, one large iPhone, and one iPad.
- Keep the tested commit hash with the notes.

## Build And Launch

| Check | Pass Criteria | Evidence |
|---|---|---|
| Clean build | `Metronome` builds without warnings that affect runtime, privacy, signing, or assets. | Xcode build log or archive result. |
| Cold launch | App opens directly to Play without account, network, or onboarding blockers. | Device note plus screenshot. |
| Default library | Default 4/4, 6/8, 7/8, son clave, and bossa patterns appear. | Screenshot or tester note. |
| Persistence | Tempo/pattern/setlist/audio settings survive force quit and relaunch. | Before/after notes. |

## Core Playback

| Check | Pass Criteria | Evidence |
|---|---|---|
| Start/stop | Play starts audible clicks; Stop stops immediately. | Device note. |
| Direct BPM | Enter valid BPM values from 30 to 300; invalid values are rejected with clear text. | Device note. |
| Tap tempo | Recent taps update tempo and stay inside 30 to 300 BPM. | Device note. |
| Meter/subdivision | Meter and subdivision edits audibly change the click pattern after playback restart or prepare. | Device note. |
| Beat accents | Strong, normal, ghost, and muted steps are audible or silent as expected. | Device note. |
| Count-in | One-bar and two-bar count-ins play cue clicks, show remaining beats, then start continuous playback. | Device note. |
| Tempo ladder | Ladder starts from the current tempo, changes BPM after the configured number of bars, and stops at the target without overshooting. | Device note. |
| Stage pulse | Full-screen pulse opens, follows scheduled beat events, and closes reliably. | Screenshot plus device note. |
| Click fixtures | `SoundLibrary/RenderedVerification` WAVs match `SHA256SUMS` and are useful for preset listening review. | Checksum output plus notes. |

## Audio Timing

Do not claim precise or stage-safe timing unless these runs produce acceptable measured results and the acceptance threshold is written down with the release notes.

| Check | Pass Criteria | Evidence |
|---|---|---|
| Ten-minute drift at 40 BPM | Captured timing summary is reviewed and does not show unexplained runaway drift. | Timing summary values. |
| Ten-minute drift at 120 BPM | Captured timing summary is reviewed and does not show unexplained runaway drift. | Timing summary values. |
| Ten-minute drift at 240 BPM | Captured timing summary is reviewed and does not show unexplained runaway drift. | Timing summary values. |
| Start latency | First click starts consistently enough for the intended v1 claim. | Timing notes. |
| Tempo transition | Changing tempo while stopped and restarting uses the new interval. | Device note. |

## Output Routes

| Route | Pass Criteria | Evidence |
|---|---|---|
| Built-in speaker | Settings reports low-latency guidance and playback is stable. | Screenshot plus note. |
| Wired headphones | Settings reports low-latency guidance and playback is stable. | Screenshot plus note. |
| Bluetooth | Settings shows a latency warning and playback remains usable for practice. | Screenshot plus note. |
| AirPlay, if available | Settings shows a latency warning or unknown-latency message; no precision claim is made. | Screenshot plus note. |

## Background And Interruptions

| Check | Pass Criteria | Evidence |
|---|---|---|
| Screen lock | Playback continues with the screen locked. | Device note. |
| App background | Playback continues when the app is backgrounded. | Device note. |
| Headphones disconnect | App stops or recovers predictably without stuck playback state. | Device note. |
| Phone call or Siri | Interruption pauses playback and resumes only when iOS marks the session resumable. | Device note. |
| Route change while playing | Engine refreshes the audio session and playback state remains coherent. | Device note. |
| Media services reset, if reproducible | Audio graph rebuilds and resumes only if playback was active. | Device note. |

## Accessibility

Use `Docs/ACCESSIBILITY_AUDIT.md` as the screen-by-screen checklist.

| Check | Pass Criteria | Evidence |
|---|---|---|
| VoiceOver order | Play, Edit, Patterns, Setlist, Settings, and Stage Pulse read in a useful task order. | Tester notes. |
| VoiceOver labels | Every actionable control has a clear label and state where needed. | Tester notes. |
| Dynamic Type | Largest accessibility sizes do not block core Play, Settings, or restore/export/import flows. | Screenshots. |
| Reduce Motion | Main and stage pulses do not scale or animate when Reduce Motion is enabled. | Tester note. |
| High contrast | Core controls remain legible in high contrast and dark mode. | Screenshots. |
| Touch targets | Beat, setlist, settings, restore, import, and export controls are practical on device. | Tester note. |

## Data Recovery

| Check | Pass Criteria | Evidence |
|---|---|---|
| Export | Settings exports a readable JSON library file. | File saved plus note. |
| Import | Exported JSON imports and replaces the local library. | Before/after note. |
| Latest snapshot restore | After an overwrite/import, Restore Latest Snapshot confirms first, restores the previous library, and snapshots the current library before replacement. | Before/after note. |
| Privacy posture | No account, network prompt, tracking prompt, analytics SDK, or cloud dependency appears. | Tester note. |

## Release Decision

Before submission, attach or preserve:

- Commit hash.
- Xcode version.
- Device and iOS version matrix.
- Test scheme results.
- Timing summary values.
- Accessibility notes and screenshots.
- Background/interruption notes.
- Privacy manifest confirmation.

If any item above fails, either fix it before submission or document the limitation in release notes and remove any claim the failed item would make misleading.
