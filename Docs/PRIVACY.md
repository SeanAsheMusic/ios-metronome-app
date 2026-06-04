# Privacy

## V1 Posture

- No account.
- No ads.
- No tracking.
- No third-party analytics.
- Local-first saved patterns and setlists.
- Local-only musician profile, mic calibration, MIDI settings, and setlist cues.
- No cloud sync in v1.
- No crash reporting unless explicitly selected later.
- Microphone access only when Beat Coach is enabled; no recording storage or upload.

## Future Considerations

Optional iCloud sync may be considered later, but it must be additive. The app should remain useful with sync disabled and should keep export/import available.

## Data Handling

Patterns, setlists, musician profile, mic calibration, MIDI settings, setlist cues, preferences, and future practice logs should remain on device by default. If export/import is implemented, exported files should be user-initiated and human-recoverable where practical.

## Current Storage

The current app stores the local library as `MetronomeLibrary.json` in the app documents directory. It also keeps bounded local JSON snapshots in `MetronomeLibrarySnapshots` before overwrites and imports, and Settings can restore the latest local snapshot. These files contain saved patterns, setlists, selected pattern ID, audio settings, user profile, mic calibration, MIDI settings, and setlist MIDI cues. No app network transfer is implemented.

## Privacy Manifest

The app target includes `App/PrivacyInfo.xcprivacy` declaring no tracking, no collected data types, no tracking domains, and no required-reason API usage. `Tools/run_local_validation.sh` verifies those manifest values, confirms `Package.swift` has no external dependencies, and scans Swift source for account, tracking, analytics, network, cloud, ad, or subscription surfaces. Re-check this manifest before any dependency, analytics, crash reporting, networking, or export/import feature is added.
