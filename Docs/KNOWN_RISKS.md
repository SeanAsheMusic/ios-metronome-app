# Known Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Audio jitter or drift is not measured yet | App cannot honestly claim professional timing | Current AVFoundation engine is a playable slice only; add real-device measurement before production claims. |
| Xcode project is generated but not built in this environment | Build errors may remain hidden until full Xcode is selected | Open `Metronome.xcodeproj` in Xcode, set a development team, and run the shared schemes. |
| Bluetooth and AirPlay latency | Users may perceive the click as late | Settings labels wireless routes with a latency warning; measure per route before precision claims. |
| Over-scoping v1 | Core metronome quality could suffer | Keep tuner, Watch, cloud, MIDI, Link, AI, and analytics deferred. |
| Accessibility gaps in custom rhythm UI | Beat grids can become unusable with assistive tech | Treat beat cells as labeled controls, test VoiceOver and Dynamic Type early. |
| Imported/copied click assets | App Review or rights risk | Synthesize all click sounds and keep provenance records. |
| Setlist/library data loss | High musician trust damage | Versioned local persistence, snapshots, export/import before optional sync. |
