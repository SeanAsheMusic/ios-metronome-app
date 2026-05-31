# Agent Instructions

Future Codex sessions must read `README.md`, `Docs/V1_SCOPE.md`, `Docs/ARCHITECTURE.md`, `Docs/AUDIO_ENGINE_SPEC.md`, `Docs/KNOWN_RISKS.md`, and `Docs/DECISIONS.md` before changing product or architecture.

Project rules:

- Preserve the local-first architecture.
- Do not add ads, accounts, subscriptions, tracking, analytics, or cloud sync to v1.
- Avoid unnecessary third-party dependencies.
- Prioritize timing accuracy over feature count.
- Do not claim production audio precision until measured on real devices.
- Keep audio as the timing source of truth; visuals and haptics should follow scheduled audio timestamps.
- Prioritize VoiceOver, Dynamic Type, high contrast, Reduce Motion, large touch targets, and dark mode.
- Add tests for model, persistence, setlist, and serialization changes.
- Keep commits focused and explain risks and decisions in docs when behavior changes.
- Treat vendor DAW metronome sounds as references only. Do not bundle copied click assets without explicit written permission.
