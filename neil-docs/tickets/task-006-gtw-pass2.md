# Title: Implement persistence and state serialization

ID: task-006-gtw-pass2

## Objective
Implement a versioned, resilient save/load subsystem that persists seeds, dungeons, adventurer rosters, inventories, and progression. Provide migration utilities and corruption recovery strategies.

## Background
Save fidelity is a high-risk area per the Decomposition (R-003). The subsystem must handle schema evolution, support HMAC/integrity checks, and provide deterministic restore for active dungeons and scheduled growth.

## Detailed Requirements
- Implement persistent SaveManager autoload with methods: save_game(path), load_game(path), quick_save(), migrate_save(src_version).
- Use `schema_version` and atomic write (write to temp, rename) to avoid partial saves.
- Integrate simple checksum (HMAC-SHA256) to detect tampering.
- Provide unit tests for corrupted-file detection and migration scenarios.
- Provide docs for save format and migration steps.

## Acceptance Criteria
- [ ] SaveManager implemented and autoloaded.
- [ ] Corruption detection test capped and returns recoverable error.
- [ ] Migration tool can upgrade v0→v1 sample save.

## Security considerations
- Save files must include integrity checks (HMAC) to detect tampering; do not rely on client trust for multiplayer.
- Sensitive spend operations should be validated server-side (if multiplayer implemented later).

## Performance targets
- Save serialization should complete <200ms; incremental saves should be supported for large states.
- Loading a typical save should complete <500ms on reference PC.

## UX notes
- Provide clear 'Saving...' and 'Saved' indicators; warn before overriding cloud or remote saves.
- Provide an undo or last-good-restore option in case of migration failures.

## Edge cases
- Interrupted write (power loss): use atomic rename to prevent corrupted files.
- Large inventory blowups: provide truncation or chunked save options.

## Data Contracts
- Save schema location: res://config/schemas/save_profile.schema.json
- Migration scripts placed under res://tools/save_migrations/

## Integration points
- GameLoopManager will call SaveManager at key checkpoints.
- CI/QA scripts will exercise migration tools with sample saves.

## QA test plan
- Automated tests for save integrity, migration, and corrupted-file handling.
- Manual QA: load saves from previous schema versions and verify state.

## Metrics
- Save/load success rate in automated nightly tests.
- Mean time to recover from corrupted save scenario.

## Rollback criteria
- If persistence changes corrupt user data or block loading, roll back the SaveManager to last stable commit and open an emergency migration patch.

## Dependencies
- Depends on Tasks 1 and 2; consumers: Task 10.

## Complexity estimate
- Fibonacci: 8 pts (Moderate)

