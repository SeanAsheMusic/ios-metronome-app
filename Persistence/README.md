# Persistence

Local-first JSON storage for the user's metronome library.

The current implementation lives in `Sources/Persistence` and stores:

- Schema version.
- Selected pattern.
- Pattern library.
- Setlists.

The play screen loads the selected pattern on launch and saves tempo changes back to disk.

Future storage work still includes preferences, snapshots, export/import bundles, and migrations.

Rules:

- No account required.
- No cloud dependency in v1.
- Version every stored schema.
- Add migration and Codable round-trip tests for every durable model change.
