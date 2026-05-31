# Rendered Verification Clicks

These WAV files are verification fixtures only. The app synthesizes clicks at runtime and does not bundle these files in the app target.

Render command:

```sh
ruby Tools/render_click_verification_assets.rb
```

Render settings:

- Sample rate: 48000 Hz
- Channel count: 1
- Bit depth: 16
- Master gain: 1.0
- Accent boost: 1.0
- Waveform: sine oscillator with exponential decay envelope
- Source parameters: `Tools/render_click_verification_assets.rb` and `Sources/AudioEngine/MetronomeAudioEngine.swift`

Files:

- `bell-beat.wav`
- `bell-cue.wav`
- `bell-downbeat.wav`
- `bell-muted.wav`
- `bell-subdivision.wav`
- `classic-beat.wav`
- `classic-cue.wav`
- `classic-downbeat.wav`
- `classic-muted.wav`
- `classic-subdivision.wav`
- `mechanical-beat.wav`
- `mechanical-cue.wav`
- `mechanical-downbeat.wav`
- `mechanical-muted.wav`
- `mechanical-subdivision.wav`
- `wood-beat.wav`
- `wood-cue.wav`
- `wood-downbeat.wav`
- `wood-muted.wav`
- `wood-subdivision.wav`
