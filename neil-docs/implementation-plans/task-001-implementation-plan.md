# Task 001 — Set up Godot project with basic scenes
Short description
- Bootstrap Godot 4.x project with main scene, folder structure, input map, export templates, and CI headless harness.

Acceptance criteria (testable)
- [ ] Repo contains `project.godot` in `game/` and `scenes/Main.tscn`
- [ ] Headless CI job loads the project and runs a smoke test returning exit 0
- [ ] Input actions defined: ui_accept, ui_cancel, action_plant, action_dispatch
- [ ] Export templates for Windows/Linux/macOS validated locally

Phased implementation
- Phase 0: Repo & CI bootstrap
  - [ ] Create branch `users/impl-plan-builder/dungeon-seed-regen/task-001`
  - [ ] Add .gitignore entries for Godot (import, .mono, .import)
  - [ ] Add CI job YAML `ci/godot-headless.yml` with headless Godot runner
  - Tests: CI job runs `godot --headless --script res://tests/startup_test.gd`
- Phase 1: Project skeleton
  - [ ] Create `game/project.godot`, `game/scenes/Main.tscn`, `game/scripts/SceneManager.gd`
  - [ ] Create scene placeholders: SeedGrove.tscn, DungeonDashboard.tscn, AdventurerHall.tscn, Vault.tscn
  - [ ] Implement SceneManager API: load_scene(scene_path:String)
  - Tests: `Startup_LoadsMainScene` (headless)
- Phase 2: Input & settings
  - [ ] Configure `project.godot` input map for required actions
  - [ ] Add `game/configs/default_settings.cfg` (camera, resolution, quality tiers)
  - Tests: `InputMap_HasRequiredActions`
- Phase 3: Export template validation & developer docs
  - [ ] Document build commands in README: run headless tests, start editor, export
  - CI check: artifact signed export (dev build)

Dependencies
- None

Deliverables & artifacts
- Files to create:
  - game/project.godot
  - game/scenes/Main.tscn
  - game/scenes/SeedGrove.tscn, DungeonDashboard.tscn, AdventurerHall.tscn, Vault.tscn
  - game/scripts/SceneManager.gd
  - ci/godot-headless.yml
  - docs/dev-setup.md
- Manifests:
  - Update neil-docs/implementation-plans/index (if exists)

Estimated complexity & risks
- Complexity: 5 points
- Risks: Engine version mismatch (mitigate: pin Godot 4.x version in docs), CI runner lacking required libs (mitigate: provide container / GitHub Actions runner image).

Deterministic ID & RNG guidance (Task-level)
- Deterministic IDs: include `tools/DetId` helper library stub and unit tests. Provide a UUIDv5/HMAC placeholder test to be replaced with real key in CI.
- RNG test vectors: not applicable to this task but CI harness must include RNG wrapper tests (see MASTER).

TODOs for Game Code Executor
- Implement minimal SceneManager.gd with load/unload API
- Provide headless test runner script `res://tests/startup_test.gd` that loads Main.tscn and exits 0 on success
- Expected outputs:
  - `godot --headless --script res://tests/startup_test.gd` -> exit 0
  - JSON test report written to `artifacts/test-report-task-001.json`

Unit test examples (TDD)
- Test: Startup_LoadsMainScene_FailsIfMissing
- Test: InputMap_Has_Action_Plant

CI checks
- Headless Godot test PASS
- Secret scan (no secrets in project.godot)
- Lint: GDScript linter

Notes
- Keep scene node structure minimal and deterministic for later automated tests.
