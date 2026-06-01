# Accessibility Audit

Date: June 1, 2026

## Scope

This is a source-level accessibility audit of the current SwiftUI app surface. It checks whether the main controls expose understandable labels, large touch targets, Dynamic Type-friendly layout choices, dark-mode/high-contrast-compatible system colors, and Reduce Motion behavior.

This audit has not been verified with Accessibility Inspector or VoiceOver running on device. The local validation gate now launches the app on the iPhone 17 simulator, runs a largest-accessibility-text Play surface smoke test, and captures a first-screen screenshot, but the full accessibility checklist still requires physical-device review at representative sizes and settings.

## Summary

| Area | Source status | Notes |
|---|---|---|
| Play | Implemented in source | Pattern, meter, BPM, tempo marking, beat visualizer, direct tempo entry, play/stop, tap tempo, count-in, practice timer, tempo ladder, rhythm trainer, and stage pulse entry have explicit labels or semantic SwiftUI controls. |
| Stage Pulse | Implemented in source | Full-screen pulse exposes pattern context, pulse state, and a labeled close button. Motion scaling is disabled when Reduce Motion is enabled. |
| Edit | Implemented in source | Pattern name, meter, global subdivision, visual rhythm-grid beat groups, per-beat subdivision selectors, an Accent/Hit/Soft/Rest paint palette, and explicit step controls are labeled. Grid steps announce the step number and current accent level. |
| Patterns | Implemented in source | Saved pattern selection, current selection state, duplication, deletion, groove template creation, Clave Mode creation, Swing template creation, and Polyrhythm template creation have labels. |
| Setlist | Implemented in source | Add, select, reorder, bar-count, auto-advance, and remove controls have labels that include the affected item title. |
| Settings | Implemented in source | Click preset, volume, accent boost, role mixer, mixer reset, Precision mode, Human Feel, timing summary/reset, audio output status, refresh, export, import, latest snapshot restore, and data-result messages have labels. |
| Dynamic Type | Partly verified | The UI smoke suite launches the Play surface at the largest accessibility text size and verifies the primary above-the-fold performance controls remain reachable. Full app-wide device verification is still required. |
| Touch targets | Implemented in source | Primary controls, tab controls, beat cells, pattern actions, groove buttons, practice presets, settings refresh, and setlist reorder/remove controls are at least 44 pt in source. |
| Color and contrast | Source likely supports | System colors and semantic secondary/accent colors are used. Needs high-contrast and dark-mode visual review. |
| Reduce Motion | Implemented in source | Main visual pulse and stage pulse disable scale animation when Reduce Motion is enabled. |

## Screen Notes

### Play

- BPM text announces the value as beats per minute.
- The tempo marking under the BPM is exposed through a stable accessibility identifier for UI validation.
- The beat visualizer exposes a "Beat visualizer" label and a stopped/current-beat value.
- Direct BPM entry has a "Tempo entry" label and the commit button has a "Set tempo" label.
- The primary transport label changes between play, stop, and count-in cancellation states.
- Tap tempo has both a label and a hint.
- Count-in uses decrement/increment controls labeled "Decrease count-in" and "Increase count-in"; the row is labeled "Count-in length" and remaining count-in beats are announced when visible.
- Practice timer controls expose duration, start/pause, reset, and remaining time.
- Tempo ladder controls expose target BPM, step size, bars per step, and start/stop state.
- Rhythm Trainer exposes mode, fixed bar counts, random silent-bar chance, random beat-dropout chance, and guide-tone/dropout modes.
- The beat visualizer exposes stopped/current-beat state; the full-screen Stage Pulse exposes active/inactive pulse state and reduced-motion state.

### Bottom Navigation

- The custom bottom navigation keeps Play, Edit, Patterns, Setlist, and Settings reachable without relying on a native filled active tab highlight.
- Each tab control has a clear accessibility label and selected/not-selected value.
- The launch UI tests now tap through all five primary surfaces and verify that screen-specific controls appear after each selection.

### Stage Pulse

- The full-screen stage view combines pattern name, BPM, and meter into one accessibility element.
- The pulse exposes active/inactive state.
- The close control is icon-only visually but has a "Close stage pulse" label.
- The view currently forces dark appearance for stage readability; high-contrast review is still required.

### Edit

- Pattern name, meter, and subdivision fields use labels.
- The rhythm grid groups editable steps under each meter beat so VoiceOver users hear step numbers in musical context.
- The rhythm-grid paint palette exposes Accent, Hit, Soft, and Rest states; tapping a grid step applies the selected state.
- The context menu also exposes explicit Accent, Hit, Soft, and Rest choices for direct VoiceOver/action-menu access.
- Per-beat subdivision menus sit inside the beat group and include the beat number and selected subdivision.
- If future gestures add lane editing, labels should include lane, accent level, and muted state.

### Patterns

- Saved patterns announce pattern name and BPM.
- Current pattern state is exposed through the accessibility value "Selected" or "Not selected".
- Duplicate, delete, groove template creation, Clave Mode mixer, Clave Mode template, Swing template, and Polyrhythm template controls have explicit labels.

### Setlist

- Setlist items announce item number, title, and section bar count.
- Song-form auto-advance exposes on/off state.
- Move earlier, move later, and remove controls include the setlist item title in the label.
- The visual item card uses color to show current-pattern state; source should add a non-color accessibility value if this state becomes operationally important.

### Settings

- Sound preset, master volume, accent boost, role mixer, mixer reset, Precision mode, Human Feel, timing summary/reset, audio output status, refresh, export, import, and latest snapshot restore controls are labeled.
- Audio output status combines route name, latency risk, and guidance message for VoiceOver users.
- Import/export result messages are labeled when visible.

## Manual Verification Checklist

Run this checklist before App Store submission once test devices are available:

- Run VoiceOver through Play, Edit, Patterns, Setlist, Settings, and Stage Pulse.
- Confirm control order matches the visual task order.
- Confirm the custom bottom navigation is reachable and reports selected state correctly.
- Confirm all controls are reachable and actionable with VoiceOver.
- Test Dynamic Type at largest accessibility sizes on compact iPhone, large iPhone, and iPad. The simulator smoke test covers the primary Play surface controls only.
- Test high contrast and dark mode on Play and Stage Pulse.
- Enable Reduce Motion and confirm pulses do not scale or animate.
- Confirm beat, settings, pattern, and setlist controls meet practical touch-target expectations on device.
- Confirm wireless latency messages are understandable without relying on color.

## Residual Risks

- No Accessibility Inspector or VoiceOver run has been completed in this environment.
- Touch-target sizing is implemented in source, but practical hit areas still need device verification with SwiftUI button styling and real hand use.
- Horizontal scrolling controls can be awkward with assistive technologies; real VoiceOver flow should determine whether rotor actions or alternate list layouts are needed.
- The app should not claim fully verified accessibility support until this audit is rerun with Accessibility Inspector and physical-device VoiceOver testing.
