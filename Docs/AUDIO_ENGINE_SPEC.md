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

Research recommends synthesized or pre-rendered in-repo click assets. Vendor DAW and system sounds are references only. Every shipped asset should have a provenance manifest with generator commit, parameters, sample rate, bit depth, render mode, and hash.

Initial click families should be classic, dry click, wood, pitched bell, and mechanical. Accent sounds should be generated from explicit parameter changes, not copied from vendor files.

## Jitter And Drift Risks

- UI timers are not acceptable as the timing source.
- Bluetooth and AirPlay can add latency that is not the same as engine jitter.
- Backgrounding, interruptions, route changes, and low-power states can affect scheduling.
- Visual pulse can appear late if it follows display refresh rather than published audio timestamps.

## Interruption Handling

Handle phone calls, Siri, route changes, media-service resets, headphones disconnecting, and app lifecycle changes. Preserve transport intent separately from active audio state so recovery is predictable.

## Bluetooth And AirPlay

Bluetooth output may be usable for practice but not guaranteed for stage-critical timing. AirPlay-class routes may introduce large latency. The app should warn or label high-latency routes once route detection exists.

## Background And Lock Screen

Background audio is a future implementation requirement for live use. It must be backed by the correct app capability and tested on hardware before release claims.

## Haptic And Visual Sync

Haptics and visuals are follower channels. They should subscribe to scheduled beat timestamps and compensate for known display/haptic latency where measurable.

## Measurement Plan

- Ten-minute drift tests at 40, 120, and 240 BPM.
- Tempo-change transition tests.
- Start-to-first-click latency tests.
- Route-change tests for speaker, wired headphones, Bluetooth, and AirPlay if supported.
- CPU and thermal tests on oldest supported devices.
