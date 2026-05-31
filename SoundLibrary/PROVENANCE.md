# Sound Provenance Manifest

## Policy

Pulsecraft does not ship copied DAW, system, hardware, sample-pack, or third-party click assets. The current click sounds are synthesized at runtime by `AVMetronomeAudioEngine` from source-controlled parameters in `Sources/AudioEngine/MetronomeAudioEngine.swift`.

## Render Contract

| Field | Value |
|---|---|
| Render mode | Runtime synthesis into mono `AVAudioPCMBuffer` |
| Sample rate | 48,000 Hz |
| Channel count | 1 |
| Waveform source | Sine oscillator with exponential decay envelope |
| Envelope | `pow(1.0 - progress, decayPower)` |
| Master gain | User setting, clamped 0.0-1.0 |
| Accent boost | User setting, clamped 0.5-1.5 and applied to downbeat |
| Muted role | Zero-gain buffer |
| External assets | None |

## Preset Parameters

All gains below are pre-master-gain base values. Downbeat gain is additionally multiplied by accent boost and clipped to 1.0.

| Preset | Role | Frequency Hz | Duration seconds | Base gain | Decay power |
|---|---|---:|---:|---:|---:|
| Classic | Downbeat | 1600 | 0.035 | 0.85 | 4.0 |
| Classic | Beat | 1050 | 0.028 | 0.62 | 4.0 |
| Classic | Subdivision | 820 | 0.018 | 0.42 | 4.0 |
| Classic | Cue | 1300 | 0.050 | 0.70 | 4.0 |
| Wood | Downbeat | 720 | 0.032 | 0.80 | 5.0 |
| Wood | Beat | 560 | 0.026 | 0.58 | 5.0 |
| Wood | Subdivision | 440 | 0.018 | 0.36 | 5.0 |
| Wood | Cue | 660 | 0.040 | 0.62 | 5.0 |
| Bell | Downbeat | 2100 | 0.055 | 0.78 | 2.8 |
| Bell | Beat | 1420 | 0.040 | 0.52 | 2.8 |
| Bell | Subdivision | 1080 | 0.024 | 0.34 | 2.8 |
| Bell | Cue | 1800 | 0.060 | 0.64 | 2.8 |
| Mechanical | Downbeat | 1250 | 0.022 | 0.90 | 7.0 |
| Mechanical | Beat | 920 | 0.018 | 0.66 | 7.0 |
| Mechanical | Subdivision | 700 | 0.012 | 0.40 | 7.0 |
| Mechanical | Cue | 1100 | 0.030 | 0.72 | 7.0 |

## Verification Notes

- Any future pre-rendered assets must include generator source, render command, sample rate, bit depth, and hash.
- Any future imported samples must include explicit rights evidence before entering the repository.
- This manifest should be updated in the same commit as any click parameter change.
