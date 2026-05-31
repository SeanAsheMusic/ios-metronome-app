# Persistence

Local-first JSON storage for the user's metronome library.

The current implementation lives in `Sources/Persistence` and stores:

- Schema version.
- Selected pattern.
- Pattern library.
- Setlists.
- Audio settings.

The app loads the selected pattern on launch, saves tempo changes back to disk, switches between saved patterns, duplicates the active pattern, persists active setlist edits, and persists sound settings.

Future storage work still includes preferences, snapshots, export/import bundles, and migrations.

Rules:

- No account required.
- No cloud dependency in v1.
- Version every stored schema.
- Add migration and Codable round-trip tests for every durable model change.
