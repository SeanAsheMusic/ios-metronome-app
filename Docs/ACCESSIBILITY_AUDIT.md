# Accessibility Audit

Date: May 31, 2026

## Scope

This is a source-level accessibility audit of the current SwiftUI app surface. It checks whether the main controls expose understandable labels, large touch targets, Dynamic Type-friendly layout choices, dark-mode/high-contrast-compatible system colors, and Reduce Motion behavior.

This audit has not been verified with Accessibility Inspector, VoiceOver running on device, or representative simulator/device layouts because the current machine does not have a full active Xcode installation.

## Summary

| Area | Source status | Notes |
|---|---|---|
| Play | Implemented in source | Pattern, meter, BPM, direct tempo entry, play/stop, tap tempo, count-in, practice timer, visual pulse, and stage pulse entry have explicit labels or semantic SwiftUI controls. |
| Stage Pulse | Implemented in source | Full-screen pulse exposes pattern context, pulse state, and a labeled close button. Motion scaling is disabled when Reduce Motion is enabled. |
| Edit | Implemented in source | Pattern name, meter, subdivision, and beat accent controls are labeled. Beat buttons announce the beat number and current accent level. |
| Patterns | Implemented in source | Saved pattern selection, current selection state, duplication, deletion, and groove template creation have labels. |
| Setlist | Implemented in source | Add, select, reorder, and remove controls have labels that include the affected item title. |
| Settings | Implemented in source | Click preset, volume, accent boost, audio output status, refresh, export, import, latest snapshot restore, and data-result messages have labels. |
| Dynamic Type | Source likely supports core flow | Most controls use SwiftUI text styles, flexible frames, scroll views, and minimum scale factors. Needs simulator/device verification at largest accessibility sizes. |
| Touch targets | Implemented in source | Primary controls, beat cells, pattern actions, groove buttons, practice presets, settings refresh, and setlist reorder/remove controls are at least 44 pt in source. |
| Color and contrast | Source likely supports | System colors and semantic secondary/accent colors are used. Needs high-contrast and dark-mode visual review. |
| Reduce Motion | Implemented in source | Main visual pulse and stage pulse disable scale animation when Reduce Motion is enabled. |

## Screen Notes

### Play

- BPM text announces the value as beats per minute.
- Direct BPM entry has a "Tempo entry" label and the commit button has a "Set tempo" label.
- The primary transport label changes between play, stop, and count-in cancellation states.
- Tap tempo has both a label and a hint.
- Count-in selection is a segmented picker labeled "Count-in length"; remaining count-in beats are announced when visible.
- Practice timer controls expose duration, start/pause, reset, and remaining time.
- Visual pulse exposes active/inactive state and reduced-motion state.

### Stage Pulse

- The full-screen stage view combines pattern name, BPM, and meter into one accessibility element.
- The pulse exposes active/inactive state.
- The close control is icon-only visually but has a "Close stage pulse" label.
- The view currently forces dark appearance for stage readability; high-contrast review is still required.

### Edit

- Pattern name, meter, and subdivision fields use labels.
- Beat cells are fixed-size buttons that announce beat number and accent level.
- Beat controls cycle accent levels. If future gestures add mute, subdivision, or lane editing, labels should include subdivision position, lane, accent level, and muted state.

### Patterns

- Saved patterns announce pattern name and BPM.
- Current pattern state is exposed through the accessibility value "Selected" or "Not selected".
- Duplicate, delete, and groove template creation controls have explicit action labels.

### Setlist

- Setlist items announce item number and title.
- Move earlier, move later, and remove controls include the setlist item title in the label.
- The visual item card uses color to show current-pattern state; source should add a non-color accessibility value if this state becomes operationally important.

### Settings

- Sound preset, master volume, accent boost, audio output status, refresh, export, import, and latest snapshot restore controls are labeled.
- Audio output status combines route name, latency risk, and guidance message for VoiceOver users.
- Import/export result messages are labeled when visible.

## Manual Verification Checklist

Run this checklist before App Store submission once full Xcode and test devices are available:

- Run VoiceOver through Play, Edit, Patterns, Setlist, Settings, and Stage Pulse.
- Confirm control order matches the visual task order.
- Confirm all controls are reachable and actionable with VoiceOver.
- Test Dynamic Type at largest accessibility sizes on compact iPhone, large iPhone, and iPad.
- Test high contrast and dark mode on Play and Stage Pulse.
- Enable Reduce Motion and confirm pulses do not scale or animate.
- Confirm beat, settings, pattern, and setlist controls meet practical touch-target expectations on device.
- Confirm wireless latency messages are understandable without relying on color.

## Residual Risks

- No device or simulator accessibility run has been completed in this environment.
- Touch-target sizing is implemented in source, but practical hit areas still need device verification with SwiftUI button styling and real hand use.
- Horizontal scrolling controls can be awkward with assistive technologies; real VoiceOver flow should determine whether rotor actions or alternate list layouts are needed.
- The app should not claim fully verified accessibility support until this audit is rerun with Accessibility Inspector and physical-device VoiceOver testing.
