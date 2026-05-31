# Known Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Audio jitter or drift is not measured yet | App cannot honestly claim professional timing | Keep engine behind protocols, implement measurement before production claims. |
| Swift package is not a full Xcode iOS project yet | App cannot be run as an installed iOS app from this folder alone | Add Xcode project or use Xcode to create app target linking package targets. |
| Bluetooth and AirPlay latency | Users may perceive the click as late | Detect route, label risk, measure per route before claims. |
| Over-scoping v1 | Core metronome quality could suffer | Keep tuner, Watch, cloud, MIDI, Link, AI, and analytics deferred. |
| Accessibility gaps in custom rhythm UI | Beat grids can become unusable with assistive tech | Treat beat cells as labeled controls, test VoiceOver and Dynamic Type early. |
| Imported/copied click assets | App Review or rights risk | Synthesize all click sounds and keep provenance records. |
| Setlist/library data loss | High musician trust damage | Versioned local persistence, snapshots, export/import before optional sync. |
