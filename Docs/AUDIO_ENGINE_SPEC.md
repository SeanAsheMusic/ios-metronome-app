# Audio Engine Spec

## Status

V1 includes protocol boundaries only. No production-grade timing precision is claimed until real-device measurement exists.

## Timing Strategy

The audio engine should own transport time. UI state, visual pulse, haptics, and lock-screen state should follow timestamped audio events rather than driving the click from animation timers.

## Scheduling Strategy

- Use `AVAudioSession` with playback category for audible metronome operation.
- Request 48 kHz sample rate and low I/O buffer duration before activation, then read back the actual granted values.
- Generate events several beats ahead of playback.
- Prefer `AVAudioPlayerNode` with pre-rendered buffers or `AVAudioSourceNode` with carefully bounded render work.
- Never allocate, block, log heavily, or perform file I/O inside a real-time render callback.

## Click Sound Architecture

Research recommends synthesized or pre-rendered in-repo click assets. Vendor DAW and system sounds are references only. Every shipped asset should have a provenance manifest with generator commit, parameters, sample rate, bit depth, render mode, and hash. The current runtime synthesis manifest lives in `SoundLibrary/PROVENANCE.md`.

Initial click families include classic, wood, bell, and mechanical synthesized presets. Accent sounds are generated from explicit parameter changes, not copied from vendor files.

Count-in uses one-shot downbeat and cue roles before continuous playback starts.

## Jitter And Drift Risks

- UI timers are not acceptable as the timing source.
- Bluetooth and AirPlay can add latency that is not the same as engine jitter.
- Backgrounding, interruptions, route changes, and low-power states can affect scheduling.
- Visual pulse can appear late if it follows display refresh rather than published audio timestamps.

## Interruption Handling

The AVFoundation engine observes audio-session interruptions and route changes. On interruption start it stops playback work while preserving whether the transport was running. On interruption end it resumes only when iOS marks the session resumable. On route change it refreshes the audio session and restarts the engine/player if playback was active.

Phone calls, Siri, headphones disconnecting, and route changes still need physical-device validation before release claims. Media-service reset handling remains a follow-up.

## Bluetooth And AirPlay

Bluetooth output may be usable for practice but not guaranteed for stage-critical timing. AirPlay-class routes may introduce large latency. The app should warn or label high-latency routes once route detection exists.

## Background And Lock Screen

The generated app target includes the `audio` background mode for lock-screen practice and live use. This still needs full Xcode and physical-device validation before release claims.

## Haptic And Visual Sync

Haptics and visuals are follower channels. They should subscribe to scheduled beat timestamps and compensate for known display/haptic latency where measurable.

## Measurement Plan

The audio module includes `AudioTimingRecorder` and `AudioTimingSummary` so device runs can capture scheduled-vs-observed host-time offset and peak-to-peak jitter while playback is running.

- Ten-minute drift tests at 40, 120, and 240 BPM.
- Tempo-change transition tests.
- Start-to-first-click latency tests.
- Route-change tests for speaker, wired headphones, Bluetooth, and AirPlay if supported.
- CPU and thermal tests on oldest supported devices.
