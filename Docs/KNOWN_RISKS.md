# Known Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Audio jitter or drift is not measured yet | App cannot honestly claim professional timing | The audio module includes a timing recorder harness, but real-device measurements are still required before production claims. |
| Xcode project is generated but not built in this environment | Build errors may remain hidden until full Xcode is selected | Open `Metronome.xcodeproj` in Xcode, set a development team, and run the shared schemes. |
| Bluetooth and AirPlay latency | Users may perceive the click as late | Settings labels wireless routes with a latency warning; measure per route before precision claims. |
| Audio interruptions and route changes | Playback can stop or restart unexpectedly during calls, Siri, output changes, or media-service resets | The AV engine observes interruptions, route changes, and media-service resets, but physical-device validation is still required. |
| Over-scoping v1 | Core metronome quality could suffer | Keep tuner, Watch, cloud, MIDI, Link, AI, and analytics deferred. |
| Accessibility gaps in custom rhythm UI | Beat grids can become unusable with assistive tech | Treat beat cells as labeled controls, test VoiceOver and Dynamic Type early. |
| Imported/copied click assets | App Review or rights risk | Synthesize all click sounds and keep `SoundLibrary/PROVENANCE.md` updated with source-controlled parameters. |
| Setlist/library data loss | High musician trust damage | Versioned local persistence, bounded local snapshots, and export/import before optional sync. |
