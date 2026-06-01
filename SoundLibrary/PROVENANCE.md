# Sound Provenance Manifest

## Policy

Pulsecraft does not ship copied DAW, system, hardware, sample-pack, or third-party click assets. The current click sounds are synthesized at runtime by `AVMetronomeAudioEngine` from source-controlled parameters in `Sources/AudioEngine/MetronomeAudioEngine.swift`.

## Render Contract

| Field | Value |
|---|---|
| Render mode | Runtime synthesis into mono `AVAudioPCMBuffer` |
| Sample rate | 48,000 Hz |
| Channel count | 1 |
| Waveform source | Sine oscillator plus deterministic noise blend with exponential decay envelope |
| Envelope | `pow(1.0 - progress, decayPower)` |
| Noise source | Deterministic frame-index hash, blended per preset |
| Master gain | User setting, clamped 0.0-1.0 |
| Accent boost | User setting, clamped 0.5-1.5 and applied to downbeat |
| Muted role | Zero-gain buffer |
| External assets | None |

## Verification Fixtures

`Tools/render_click_verification_assets.rb` renders exportable WAV fixtures under `SoundLibrary/RenderedVerification` using the same source-controlled preset parameters. These files are for listening review, waveform inspection, and checksum-based verification only. They are not bundled by the app target.

## Preset Parameters

All gains below are pre-master-gain base values. Downbeat gain is additionally multiplied by accent boost and clipped to 1.0.

| Preset | Role | Frequency Hz | Duration seconds | Base gain | Decay power | Noise mix |
|---|---|---:|---:|---:|---:|---:|
| Classic | Downbeat | 1600 | 0.035 | 0.85 | 4.0 | 0.00 |
| Classic | Beat | 1050 | 0.028 | 0.62 | 4.0 | 0.00 |
| Classic | Subdivision | 820 | 0.018 | 0.42 | 4.0 | 0.00 |
| Classic | Cue | 1300 | 0.050 | 0.70 | 4.0 | 0.00 |
| Hard Click | Downbeat | 2600 | 0.018 | 0.88 | 8.0 | 0.18 |
| Hard Click | Beat | 2100 | 0.014 | 0.66 | 8.0 | 0.18 |
| Hard Click | Subdivision | 1700 | 0.010 | 0.44 | 8.0 | 0.18 |
| Hard Click | Cue | 2350 | 0.024 | 0.72 | 8.0 | 0.18 |
| Wood | Downbeat | 720 | 0.032 | 0.80 | 5.0 | 0.04 |
| Wood | Beat | 560 | 0.026 | 0.58 | 5.0 | 0.04 |
| Wood | Subdivision | 440 | 0.018 | 0.36 | 5.0 | 0.04 |
| Wood | Cue | 660 | 0.040 | 0.62 | 5.0 | 0.04 |
| Clave | Downbeat | 1450 | 0.034 | 0.82 | 5.8 | 0.10 |
| Clave | Beat | 1120 | 0.028 | 0.60 | 5.8 | 0.10 |
| Clave | Subdivision | 860 | 0.016 | 0.34 | 5.8 | 0.10 |
| Clave | Cue | 1300 | 0.040 | 0.66 | 5.8 | 0.10 |
| Rimshot | Downbeat | 2900 | 0.026 | 0.86 | 6.8 | 0.34 |
| Rimshot | Beat | 2400 | 0.020 | 0.64 | 6.8 | 0.34 |
| Rimshot | Subdivision | 1700 | 0.012 | 0.40 | 6.8 | 0.34 |
| Rimshot | Cue | 2700 | 0.032 | 0.70 | 6.8 | 0.34 |
| Cowbell | Downbeat | 1900 | 0.065 | 0.78 | 2.4 | 0.06 |
| Cowbell | Beat | 1540 | 0.048 | 0.56 | 2.4 | 0.06 |
| Cowbell | Subdivision | 1160 | 0.026 | 0.34 | 2.4 | 0.06 |
| Cowbell | Cue | 1740 | 0.060 | 0.62 | 2.4 | 0.06 |
| Hi-Hat | Downbeat | 6800 | 0.030 | 0.62 | 5.6 | 0.82 |
| Hi-Hat | Beat | 5600 | 0.022 | 0.48 | 5.6 | 0.82 |
| Hi-Hat | Subdivision | 4800 | 0.014 | 0.34 | 5.6 | 0.82 |
| Hi-Hat | Cue | 6200 | 0.032 | 0.54 | 5.6 | 0.82 |
| Shaker | Downbeat | 4900 | 0.046 | 0.50 | 4.6 | 0.92 |
| Shaker | Beat | 4200 | 0.036 | 0.40 | 4.6 | 0.92 |
| Shaker | Subdivision | 3800 | 0.024 | 0.30 | 4.6 | 0.92 |
| Shaker | Cue | 4600 | 0.048 | 0.46 | 4.6 | 0.92 |
| Clap | Downbeat | 2200 | 0.060 | 0.72 | 3.2 | 0.72 |
| Clap | Beat | 1800 | 0.045 | 0.52 | 3.2 | 0.72 |
| Clap | Subdivision | 1400 | 0.026 | 0.30 | 3.2 | 0.72 |
| Clap | Cue | 2000 | 0.058 | 0.60 | 3.2 | 0.72 |
| Sine | Downbeat | 1000 | 0.075 | 0.68 | 2.2 | 0.00 |
| Sine | Beat | 750 | 0.055 | 0.50 | 2.2 | 0.00 |
| Sine | Subdivision | 500 | 0.032 | 0.32 | 2.2 | 0.00 |
| Sine | Cue | 900 | 0.070 | 0.56 | 2.2 | 0.00 |
| Mellow | Downbeat | 880 | 0.060 | 0.58 | 3.0 | 0.02 |
| Mellow | Beat | 660 | 0.044 | 0.44 | 3.0 | 0.02 |
| Mellow | Subdivision | 520 | 0.026 | 0.28 | 3.0 | 0.02 |
| Mellow | Cue | 780 | 0.058 | 0.50 | 3.0 | 0.02 |
| Bell | Downbeat | 2100 | 0.055 | 0.78 | 2.8 | 0.00 |
| Bell | Beat | 1420 | 0.040 | 0.52 | 2.8 | 0.00 |
| Bell | Subdivision | 1080 | 0.024 | 0.34 | 2.8 | 0.00 |
| Bell | Cue | 1800 | 0.060 | 0.64 | 2.8 | 0.00 |
| Mechanical | Downbeat | 1250 | 0.022 | 0.90 | 7.0 | 0.12 |
| Mechanical | Beat | 920 | 0.018 | 0.66 | 7.0 | 0.12 |
| Mechanical | Subdivision | 700 | 0.012 | 0.40 | 7.0 | 0.12 |
| Mechanical | Cue | 1100 | 0.030 | 0.72 | 7.0 | 0.12 |

## Verification Notes

- Any future pre-rendered shipped assets must include generator source, render command, sample rate, bit depth, and hash.
- Any future imported samples must include explicit rights evidence before entering the repository.
- This manifest should be updated in the same commit as any click parameter change.
