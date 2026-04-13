CHANGELOG - Implementation artifacts for Dungeon Seed epic

- Populated deterministic ID generator (GDScript)
- Seeded RNG wrapper (GDScript)
- Unit test placeholders that exit the headless runner
- CI workflow stub added (ci/godot-headless-tests.yml)
- Migration placeholders for HMAC and ID migration

Manual steps required:
- Add HMAC keys to CI secret manager (do NOT commit keys)
- Implement full reachability harness and add canonical RNG vectors
