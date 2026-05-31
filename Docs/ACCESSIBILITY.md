# Accessibility

## Requirements

- VoiceOver labels for BPM, play/stop, BPM increment controls, tap tempo, meter, subdivision, pattern name, and visual pulse.
- Dynamic Type support without clipping in the primary play flow.
- Large touch targets of at least 44 x 44 pt.
- High contrast and dark mode.
- Reduce Motion support for pulse animation; the visual pulse no longer scales or animates when Reduce Motion is enabled.
- Beat grid controls must expose beat number, accent level, and muted state. Future subdivision or lane editing should also expose subdivision position and lane.

## Current Audit

The current source-level audit lives in `Docs/ACCESSIBILITY_AUDIT.md`. It records implemented accessibility labels and source-level layout support while separating that work from the remaining Accessibility Inspector, VoiceOver, Dynamic Type, high-contrast, and physical-device verification.

## Product Position

Accessibility is a differentiator. Several competitors either do not declare accessibility features or expose uneven support. This app should let musicians operate the core metronome without visual precision or tiny controls.
