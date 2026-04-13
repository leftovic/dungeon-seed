Title: Implement Dungeon Seed core systems (RNG, Dungeon Gen, Items, Combat) and Headless Tests

Summary:
This PR bundles the local implementation work for the Dungeon Seed epic: deterministic RNG (xoshiro128-style), deterministic ID helpers, dungeon generator, item & equipment system, combat core, extensive headless unit tests, test runner, CI workflow for Godot headless tests, and supporting tools/docs (HMAC provisioning, fixture generator).

Key changes:
- src/gdscript/utils/rng_wrapper_impl.gd (xoshiro128-style RNG wrapper)
- tools/generate_vectors.py (matching vector generator)
- src/gdscript/dungeon/dungeon_generator.gd (deterministic room+corridor generator)
- src/gdscript/items/item.gd and equipment_manager.gd
- src/gdscript/combat/combat_core.gd
- tests/unit/* (unit and integration tests)
- .github/workflows/godot-headless-tests.yml (CI workflow stub with Godot download & cache)
- ci/HMAC_KEY_PROVISIONING.md, ci/SECURE_ACTIONS_SECRETS.md

Testing steps (local):
1. Ensure Godot executable available. Example run used: C:\\Godot\\Godot_v4.6.1-stable_win64.exe\\Godot_v4.6.1-stable_win64.exe
2. Run headless tests: "C:\\Godot\\Godot_v4.6.1-stable_win64.exe\\Godot_v4.6.1-stable_win64.exe --headless --path . --script 'res://tests/unit/test_runner.gd'"
3. All tests should exit with code 0.

Notes & follow-ups:
- push-impl-branch and PR open must be performed to publish this branch (no remote configured locally).
- CI secrets required: GODOT_CHECKSUM (optional), HMAC_KEY (optional for HMAC mode). See ci/SECURE_ACTIONS_SECRETS.md.
- Consider choosing production PRNG for anti-cheat/security (ChaCha20) if needed for secure tokens (not used for deterministic gameplay RNG).

Checklist:
- [x] Deterministic RNG implemented and fixtures updated
- [x] Dungeon generator implemented
- [x] Item & equipment system implemented
- [x] Combat core implemented
- [x] Headless tests added and pass locally
- [x] CI workflow stub added
- [ ] Branch pushed and PR opened

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>