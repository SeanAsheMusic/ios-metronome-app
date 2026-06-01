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
- Waveform: sine oscillator plus deterministic noise blend with exponential decay envelope
- Source parameters: `Tools/render_click_verification_assets.rb` and `Sources/AudioEngine/MetronomeAudioEngine.swift`

Files:

- `bell-beat.wav`
- `bell-cue.wav`
- `bell-downbeat.wav`
- `bell-muted.wav`
- `bell-subdivision.wav`
- `clap-beat.wav`
- `clap-cue.wav`
- `clap-downbeat.wav`
- `clap-muted.wav`
- `clap-subdivision.wav`
- `classic-beat.wav`
- `classic-cue.wav`
- `classic-downbeat.wav`
- `classic-muted.wav`
- `classic-subdivision.wav`
- `clave-beat.wav`
- `clave-cue.wav`
- `clave-downbeat.wav`
- `clave-muted.wav`
- `clave-subdivision.wav`
- `cowbell-beat.wav`
- `cowbell-cue.wav`
- `cowbell-downbeat.wav`
- `cowbell-muted.wav`
- `cowbell-subdivision.wav`
- `hard_click-beat.wav`
- `hard_click-cue.wav`
- `hard_click-downbeat.wav`
- `hard_click-muted.wav`
- `hard_click-subdivision.wav`
- `hi_hat-beat.wav`
- `hi_hat-cue.wav`
- `hi_hat-downbeat.wav`
- `hi_hat-muted.wav`
- `hi_hat-subdivision.wav`
- `mechanical-beat.wav`
- `mechanical-cue.wav`
- `mechanical-downbeat.wav`
- `mechanical-muted.wav`
- `mechanical-subdivision.wav`
- `mellow-beat.wav`
- `mellow-cue.wav`
- `mellow-downbeat.wav`
- `mellow-muted.wav`
- `mellow-subdivision.wav`
- `rimshot-beat.wav`
- `rimshot-cue.wav`
- `rimshot-downbeat.wav`
- `rimshot-muted.wav`
- `rimshot-subdivision.wav`
- `shaker-beat.wav`
- `shaker-cue.wav`
- `shaker-downbeat.wav`
- `shaker-muted.wav`
- `shaker-subdivision.wav`
- `sine-beat.wav`
- `sine-cue.wav`
- `sine-downbeat.wav`
- `sine-muted.wav`
- `sine-subdivision.wav`
- `wood-beat.wav`
- `wood-cue.wav`
- `wood-downbeat.wav`
- `wood-muted.wav`
- `wood-subdivision.wav`
