# App Store Checklist

## Metadata

- App name: `Pulsecraft`.
- Subtitle ideas: `Precision practice, no account`, `Stage-ready rhythm tools`, `A serious metronome for musicians`.
- Category: Music.
- Age rating: likely 4+ unless future user-generated sharing changes content risk.

## Screenshots

- Large Play screen with BPM and visual pulse.
- Pattern accents/subdivisions.
- Setlist ordering.
- Accessibility-friendly large text or high-contrast example.
- Synthesized sound selection.

## App Preview Ideas

- Launch, press play, change BPM, tap tempo.
- Switch meter/subdivision.
- Reorder setlist.
- Show dark mode performance view.

## Privacy Nutrition Label

V1 target: no data collected, no tracking, no third-party analytics. Confirm before submission based on final dependencies.

The app target includes `PrivacyInfo.xcprivacy` with no tracking, no collected data, no tracking domains, and no required-reason API declarations. Reconfirm this after every dependency or storage change.

## Required URLs

- Support URL.
- Privacy policy URL, even if the policy says no account, no tracking, and local-only data.

## TestFlight

- Smoke test install, cold launch, play screen, pattern defaults, setlist ordering.
- Accessibility pass with VoiceOver, Dynamic Type, Reduce Motion, and high contrast.
- Background audio smoke test with screen locked and app backgrounded.
- Physical-device audio tests before claiming precision, including built-in speaker, wired headphones, Bluetooth, and AirPlay where available.

## Review Notes

Explain that v1 requires no account, uses local data, does not include ads or subscriptions, and warns users that wireless audio routes can feel late. Do not claim timing precision beyond measured evidence.
