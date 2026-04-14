# TASK-009: Save/Load Manager with Versioned Serialization — Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-009-save-load-manager.md`
> **GDD**: `neil-docs/epics/dungeon-seed/GDD-v2.md`
> **Status**: Planning
> **Created**: 2025-07-19
> **Repo**: `dev-agent-tool` (local — `C:\Users\wrstl\source\dev-agent-tool`)
> **Methodology**: TDD Red-Green-Refactor (mandatory for all phases)
> **Complexity**: 8 points (Moderate) — Fibonacci
> **Estimated Phases**: 7
> **Estimated Checkboxes**: ~68
> **Estimated Tests**: ~46

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents in this order:

1. **This file** (you're reading it) — the phased checklist of what to do, with status
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-009-save-load-manager.md`** — the full technical spec with exact code to implement
3. **`neil-docs/epics/dungeon-seed/GDD-v2.md`** — the Game Design Document for understanding domain context
4. **`neil-docs/epics/dungeon-seed/plans-v2/TASK-001-plan.md`** — the project bootstrap plan (TASK-001, dependency)
5. **`project.godot`** — the engine config (already has autoloads from TASK-001)

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| Engine config | `project.godot` | Exists — has `[autoload]` section from TASK-001 |
| Autoload scripts | `src/autoloads/` | Exists — `event_bus.gd`, `game_manager.gd` (TASK-001) |
| Models | `src/models/` | Exists — `enums.gd` (Enums class_name), `game_config.gd` (GameConfig class_name), `rng.gd` (DeterministicRNG) |
| Services directory | `src/services/` | Exists — has `.gdkeep` from TASK-001; target for `save_service.gd` |
| Test directory | `tests/services/` | **NEW** — must create for `test_save_service.gd` |
| Legacy code | `src/gdscript/utils/save_manager.gd` | **TO DEPRECATE/DELETE** — replaced by SaveService |
| GUT addon | `addons/gut/` | **PRE-INSTALLED** — GUT is available for testing |
| v1 prototype code | `src/gdscript/` | **DO NOT TOUCH** except `save_manager.gd` deprecation |

### Key Concepts (5-minute primer)

- **SaveService**: A `RefCounted` class (NOT autoload) that serializes/deserializes game state to JSON files. Instantiated by GameManager, not added to the scene tree.
- **Save Manifest**: The top-level JSON Dictionary written to disk with metadata (`version`, `timestamp`, `slot`) plus all game state.
- **Atomic Write**: Write to `.tmp` file first, then rename to final `.json`. Prevents corruption on crash/power loss.
- **Migration**: Sequential version-step transformation (v1→v2→v3...) applied on load when save version < CURRENT_VERSION.
- **Structural Validation**: Checking required keys exist and have correct types, NOT semantic value validation.
- **Save Slots**: 3 independent save positions. Each maps to `user://saves/slot_{N}.json`.
- **RefCounted**: Godot base class for garbage-collected objects. No scene tree needed — perfect for testable services.
- **class_name**: GDScript keyword that registers a script as a globally available type. `SaveService` uses this. Autoload scripts (EventBus, GameManager) do NOT use `class_name`.

### Build & Verification Commands

```powershell
# There is no CLI build for GDScript — verification is done in-editor.
# However, you can verify script syntax via headless Godot:

# Open project in editor (manual)
# Press F5 to run — should launch to main_menu.tscn

# Run GUT tests from within the editor:
#   1. Open GUT panel (bottom dock)
#   2. Click "Run All" — all tests must pass green
#   3. Or run specific test: tests/services/test_save_service.gd

# Verify SaveService instantiation in script console:
#   var ss := SaveService.new()
#   print(ss)  # Should print <SaveService>
```

### Regression Gate

Before AND after every phase:
1. `project.godot` must be valid (opens in editor without errors)
2. `src/scenes/main_menu.tscn` must still be the main scene and load correctly
3. All existing test files (TASK-001 and earlier) are unbroken by our changes
4. All new GUT tests pass green (once written)
5. Autoloads (EventBus, GameManager) still function correctly

---

## Current State Analysis

### What Exists Today

| Item | Status | Location |
|------|--------|----------|
| `project.godot` | ✅ Exists | Root — project config with autoloads from TASK-001 |
| `src/services/` | ✅ Exists | Has `.gdkeep` from TASK-001 |
| `src/services/.gdkeep` | ✅ Exists | Placeholder file |
| `src/autoloads/event_bus.gd` | ✅ Exists | EventBus autoload (TASK-001) |
| `src/autoloads/game_manager.gd` | ✅ Exists | GameManager autoload (TASK-001) |
| `src/models/enums.gd` | ✅ Exists | Enums with class_name |
| `src/models/game_config.gd` | ✅ Exists | GameConfig with class_name |
| `src/models/rng.gd` | ✅ Exists | DeterministicRNG |
| `addons/gut/` | ✅ Exists | GUT testing framework installed |
| `src/gdscript/utils/save_manager.gd` | ✅ Exists | Legacy save manager — TO BE DEPRECATED |
| `tests/unit/` | ✅ Exists | Existing test files |

### What's Missing (Gap Analysis)

| Item | Status | Required By |
|------|--------|-------------|
| `tests/services/` directory | ❌ Missing | Test file location |
| `src/services/save_service.gd` | ❌ Missing | FR-001 through FR-053 |
| `tests/services/test_save_service.gd` | ❌ Missing | AC-058, AC-059 |
| Deprecation of `src/gdscript/utils/save_manager.gd` | ❌ Not done | AC-057 |

### What Must NOT Change

- `src/scenes/main_menu.tscn` — existing main scene
- `src/autoloads/event_bus.gd` — TASK-001 autoload (DO NOT add `class_name`)
- `src/autoloads/game_manager.gd` — TASK-001 autoload (DO NOT add `class_name`)
- `project.godot` — no modifications needed for this task
- `src/models/` — existing model files are not modified
- `src/gdscript/` — v1 prototype code (except `save_manager.gd` deprecation)
- Existing test files — must not be broken

---

## Development Methodology: TDD Red-Green-Refactor

**ALL implementation work follows strict TDD.** No exceptions.

### The Cycle

1. **RED**: Write a failing test that describes the desired behavior
   - The test MUST fail initially — if it passes, you don't need the test
   - The test MUST be specific and descriptive: `test_method_name_scenario_expected`
   - Run the test suite — confirm it fails

2. **GREEN**: Write the MINIMUM code to make the test pass
   - Do NOT write more code than needed
   - Do NOT refactor yet
   - Do NOT add features not covered by the failing test
   - Run the test suite — confirm it passes (and nothing else broke)

3. **REFACTOR**: Clean up while keeping tests green
   - Extract methods, rename variables, remove duplication
   - Run the test suite after EVERY refactor step
   - If any test fails → undo the refactor and try again

### Test Naming Convention (GDScript / GUT)

```gdscript
# Single scenarios
func test_save_game_returns_true_on_success() -> void:

# Specific behavior
func test_load_game_round_trip() -> void:

# Error cases
func test_save_game_slot_zero_returns_false() -> void:

# Migration
func test_migrate_v1_to_v2_creates_wallet() -> void:
```

### Test Structure (GUT)

Every test follows Arrange-Act-Assert:
```gdscript
func test_method_scenario_expected() -> void:
    # Arrange — create instance and test data
    var state: Dictionary = _build_valid_state()

    # Act — execute the behavior
    var result: bool = service.save_game(1, state)

    # Assert — verify the outcome
    assert_true(result, "save_game should return true on success")
```

### Coverage Requirements Per Phase

- ✅ **Existence**: Class exists, extends correct base, has `class_name`
- ✅ **Constants**: All constants declared with correct values
- ✅ **Method behavior**: Public methods produce correct results
- ✅ **Edge cases**: Invalid slots, missing files, corrupted JSON
- ✅ **Error handling**: Bad input returns safe defaults (empty dict, false)
- ✅ **Migration**: Version transformation produces correct output
- ✅ **Validation**: Structural integrity checks catch all invalid data

---

## Phase 0: Pre-Flight & Setup

> **Ticket References**: FR-001, AC-052, AC-057, AC-058
> **AC References**: AC-052 (class structure), AC-058 (test file location)
> **Estimated Items**: 8
> **Dependencies**: TASK-001 complete (project bootstrap)
> **Validation Gate**: `src/services/` exists, `tests/services/` exists, legacy file identified, regression baseline established

This phase verifies the TASK-001 dependency, creates the test directory, and establishes the regression baseline.

### 0.1 Verify TASK-001 Dependency

- [ ] **0.1.1** Verify `src/services/` directory exists (created by TASK-001)
  - _Ticket ref: TASK-001 dependency_
- [ ] **0.1.2** Verify `src/autoloads/event_bus.gd` and `src/autoloads/game_manager.gd` exist
  - _Ticket ref: TASK-001 dependency_
- [ ] **0.1.3** Verify `addons/gut/` exists (GUT is installed)
  - _Ticket ref: Assumption #12_

### 0.2 Create Test Directory

- [ ] **0.2.1** Create directory `tests/services/` if it does not exist
  - _Ticket ref: AC-058 (test file location)_

### 0.3 Identify Legacy File

- [ ] **0.3.1** Check if `src/gdscript/utils/save_manager.gd` exists
  - _Ticket ref: AC-057_
  - _Note: Record existence/absence for Phase 6 cleanup_

### 0.4 Establish Regression Baseline

- [ ] **0.4.1** Run existing GUT test suite — record baseline pass/fail count
  - _All existing tests must pass before we begin_
- [ ] **0.4.2** Verify `project.godot` is valid (opens without errors)

### Phase 0 Validation Gate

- [ ] **0.V.1** `src/services/` directory exists
- [ ] **0.V.2** `tests/services/` directory exists
- [ ] **0.V.3** Legacy `save_manager.gd` status documented
- [ ] **0.V.4** Existing tests pass (regression baseline)
- [ ] **0.V.5** Commit: `"Phase 0: TASK-009 pre-flight — verify dependencies, create tests/services/"`

---

## Phase 1: SaveService Skeleton & Constants (TDD)

> **Ticket References**: FR-001, FR-002, FR-003, FR-004, FR-052, FR-053
> **AC References**: AC-052, AC-053, AC-054, AC-055, AC-056
> **Estimated Items**: 10
> **Dependencies**: Phase 0 complete
> **Validation Gate**: SaveService class exists with constants, private helpers, slot validation tests pass

This phase creates the `save_service.gd` skeleton with `class_name SaveService`, all constants, and private helper methods. Tests cover slot validation.

### 1.1 Write Initial Test Stubs (RED)

- [ ] **1.1.1** Create `tests/services/test_save_service.gd` with test file header, helpers (`_build_valid_state`, `_build_v1_state`, `_clean_saves`, `_write_raw_file`), `before_each`/`after_each` lifecycle, and initial slot validation tests
  - _Ticket ref: Section 14.1_
  - _File: `tests/services/test_save_service.gd`_
  - _Initial tests (RED — SaveService does not exist yet):_
    - `test_save_game_slot_zero_returns_false`
    - `test_save_game_slot_four_returns_false`
    - `test_save_game_slot_negative_returns_false`
  - _TDD: RED — tests reference `SaveService` class which does not exist yet_

### 1.2 Implement SaveService Skeleton (GREEN)

- [ ] **1.2.1** Create `src/services/save_service.gd` with class declaration
  - _Ticket ref: FR-001, AC-052_
  - _File: `src/services/save_service.gd`_
  - _Content: `class_name SaveService` + `extends RefCounted`_
  - _NOTE: SaveService uses `class_name` because it is NOT an autoload_
- [ ] **1.2.2** Add `CURRENT_VERSION` constant
  - _Ticket ref: FR-002, AC-056_
  - _Content: `const CURRENT_VERSION: int = 2`_
- [ ] **1.2.3** Add `MAX_SLOTS` constant
  - _Ticket ref: FR-003, AC-056_
  - _Content: `const MAX_SLOTS: int = 3`_
- [ ] **1.2.4** Add `SAVE_DIR` constant
  - _Ticket ref: FR-004, AC-056_
  - _Content: `const SAVE_DIR: String = "user://saves/"`_
- [ ] **1.2.5** Add `MAX_SAVE_SIZE_BYTES` constant
  - _Ticket ref: SEC-004, AC-056_
  - _Content: `const MAX_SAVE_SIZE_BYTES: int = 1_048_576`_
- [ ] **1.2.6** Add `REQUIRED_KEYS` constant (PackedStringArray of 10 keys)
  - _Ticket ref: FR-043, AC-056_
  - _Keys: version, timestamp, slot, seeds, dungeon, adventurers, inventory, wallet, loop_state, settings_
- [ ] **1.2.7** Add private helpers: `_get_slot_path()`, `_get_temp_path()`, `_is_valid_slot()`, `_ensure_save_directory()`, `_remove_file()`, `_file_name_from_path()`
  - _Ticket ref: FR-052, FR-053_
  - _See ticket Section 16.1 for exact implementations_
- [ ] **1.2.8** Add `save_game()` stub that only validates slot and returns `false`
  - _Just enough to make the 3 slot validation tests pass GREEN_

### Phase 1 Validation Gate

- [ ] **1.V.1** `src/services/save_service.gd` exists and is parseable GDScript
- [ ] **1.V.2** File extends `RefCounted` and declares `class_name SaveService`
- [ ] **1.V.3** All 5 constants declared with correct values
- [ ] **1.V.4** All 6 private helpers implemented
- [ ] **1.V.5** Slot validation tests pass green (3 tests)
- [ ] **1.V.6** Existing tests unbroken
- [ ] **1.V.7** Commit: `"Phase 1: SaveService skeleton with constants and slot validation — 3 tests"`

---

## Phase 2: Save Operations (TDD)

> **Ticket References**: FR-005 through FR-015
> **AC References**: AC-001 through AC-014
> **Estimated Items**: 13
> **Dependencies**: Phase 1 complete (skeleton exists)
> **Validation Gate**: save_game() fully implemented with atomic write, 14 tests pass

This phase implements the full `save_game()` method with atomic writes. Tests cover success, file creation, JSON validity, metadata injection, slot rejection, directory creation, overwrite, tmp cleanup, and non-mutation.

### 2.1 Write Save Tests (RED)

- [ ] **2.1.1** Add save operation tests to `tests/services/test_save_service.gd`
  - _Ticket ref: AC-001 through AC-014_
  - _Tests (RED — save_game() is a stub):_
    - `test_save_game_returns_true_on_success` — AC-001
    - `test_save_game_creates_file_on_disk` — AC-001
    - `test_save_game_file_is_valid_json` — AC-007
    - `test_save_game_injects_version` — AC-004
    - `test_save_game_injects_timestamp` — AC-005
    - `test_save_game_injects_slot_number` — AC-006
    - `test_save_game_creates_directory_if_missing` — AC-012
    - `test_save_game_overwrites_existing_save` — AC-013
    - `test_save_game_does_not_mutate_input_beyond_metadata` — AC-014
    - `test_save_game_no_tmp_file_left_on_success` — FR-013
  - _TDD: RED — save_game() only validates slot, doesn't write_

### 2.2 Implement save_game() (GREEN)

- [ ] **2.2.1** Implement full `save_game()` method with metadata injection
  - _Ticket ref: FR-005 through FR-008_
  - _Injects `version`, `timestamp`, `slot` into game_state_
- [ ] **2.2.2** Add directory creation via `_ensure_save_directory()`
  - _Ticket ref: FR-009, AC-012_
- [ ] **2.2.3** Add JSON serialization via `JSON.stringify(data, "\t")`
  - _Ticket ref: FR-010_
- [ ] **2.2.4** Add atomic write: write to `.tmp` then rename to `.json`
  - _Ticket ref: FR-011, FR-012, FR-013, FR-014, FR-015_
  - _See ticket Section 16.1 for exact implementation_

### 2.3 Verify & Refactor

- [ ] **2.3.1** Run all save tests — confirm all 13 pass green (3 slot + 10 new)
  - _If any fail, fix implementation minimally_
- [ ] **2.3.2** Refactor: extract any duplicated logic, improve variable names

### Phase 2 Validation Gate

- [ ] **2.V.1** `save_game()` returns `true` for valid slot and state
- [ ] **2.V.2** Save file created at `user://saves/slot_{N}.json`
- [ ] **2.V.3** Saved JSON contains `version`, `timestamp`, `slot` metadata
- [ ] **2.V.4** Atomic write leaves no `.tmp` file on success
- [ ] **2.V.5** All 13 tests pass green (3 slot validation + 10 save operations)
- [ ] **2.V.6** Existing tests unbroken
- [ ] **2.V.7** Commit: `"Phase 2: Implement save_game() with atomic write — 13 tests"`

---

## Phase 3: Load Operations (TDD)

> **Ticket References**: FR-016 through FR-024
> **AC References**: AC-015 through AC-026
> **Estimated Items**: 11
> **Dependencies**: Phase 2 complete (save_game() works for round-trip testing)
> **Validation Gate**: load_game() fully implemented with file reading, JSON parsing, size guard, 10 new tests pass

This phase implements `load_game()` with file reading, JSON parsing, size guard, and basic structure checks. Migration and validation are stubbed (returning true / pass-through) until Phase 4 and 5.

### 3.1 Write Load Tests (RED)

- [ ] **3.1.1** Add load operation tests to `tests/services/test_save_service.gd`
  - _Ticket ref: AC-015 through AC-026_
  - _Tests (RED — load_game() does not exist yet):_
    - `test_load_game_round_trip` — AC-015
    - `test_load_game_empty_slot_returns_empty_dict` — AC-016
    - `test_load_game_invalid_json_returns_empty_dict` — AC-017
    - `test_load_game_truncated_json_returns_empty_dict` — AC-018
    - `test_load_game_json_array_returns_empty_dict` — AC-019
    - `test_load_game_missing_keys_returns_empty_dict` — AC-020
    - `test_load_game_slot_zero_returns_empty_dict` — AC-021
    - `test_load_game_slot_four_returns_empty_dict` — AC-022
    - `test_load_game_oversized_file_returns_empty_dict` — SEC-004, AC-023

### 3.2 Implement load_game() (GREEN)

- [ ] **3.2.1** Implement `load_game()` with slot validation
  - _Ticket ref: FR-016_
- [ ] **3.2.2** Add file existence check — return `{}` if missing
  - _Ticket ref: FR-017_
- [ ] **3.2.3** Add file size guard — reject files > `MAX_SAVE_SIZE_BYTES`
  - _Ticket ref: SEC-004_
- [ ] **3.2.4** Add JSON parsing — return `{}` if null or not Dictionary
  - _Ticket ref: FR-018, FR-019, FR-020_
- [ ] **3.2.5** Add migration trigger — call `migrate()` if version < CURRENT_VERSION
  - _Ticket ref: FR-021_
  - _Note: migrate() is stubbed as pass-through until Phase 4_
- [ ] **3.2.6** Add validation gate — call `_validate()`, return `{}` on failure
  - _Ticket ref: FR-022, FR-023, FR-024_
  - _Note: _validate() is implemented minimally to pass round-trip test_

### Phase 3 Validation Gate

- [ ] **3.V.1** `load_game()` returns saved data on round-trip (save→load)
- [ ] **3.V.2** `load_game()` returns `{}` for empty slot, invalid JSON, oversized files
- [ ] **3.V.3** `load_game()` returns `{}` for out-of-range slots
- [ ] **3.V.4** All 22 tests pass green (13 prior + 9 new load tests)
- [ ] **3.V.5** Existing tests unbroken
- [ ] **3.V.6** Commit: `"Phase 3: Implement load_game() with JSON parsing and size guard — 22 tests"`

---

## Phase 4: Migration Pipeline (TDD)

> **Ticket References**: FR-034 through FR-042
> **AC References**: AC-027 through AC-036
> **Estimated Items**: 12
> **Dependencies**: Phase 3 complete (load_game() exists for auto-migration test)
> **Validation Gate**: migrate() and _migrate_v1_to_v2() fully implemented, 11 migration tests pass

This phase implements the sequential migration pipeline and the v1→v2 migration function. Tests cover wallet restructuring, auto_harvest, colorblind_mode, text_size, version update, same-version no-op, invalid ranges, idempotency, and auto-migration on load.

### 4.1 Write Migration Tests (RED)

- [ ] **4.1.1** Add migration tests to `tests/services/test_save_service.gd`
  - _Ticket ref: AC-027 through AC-036_
  - _Tests (RED — migrate() is a pass-through stub):_
    - `test_migrate_v1_to_v2_creates_wallet` — FR-037, AC-027
    - `test_migrate_v1_to_v2_adds_auto_harvest` — FR-036, AC-028
    - `test_migrate_v1_to_v2_adds_colorblind_mode` — FR-038, AC-029
    - `test_migrate_v1_to_v2_adds_text_size` — FR-039, AC-030
    - `test_migrate_v1_to_v2_updates_version` — FR-040, AC-031
    - `test_migrate_same_version_returns_unchanged` — FR-041, AC-032
    - `test_migrate_higher_from_returns_unchanged` — FR-041, AC-033
    - `test_migrate_invalid_from_returns_unchanged` — FR-042, AC-034
    - `test_migrate_idempotent_on_v2_data` — NFR-015, AC-035
    - `test_load_game_auto_migrates_v1` — FR-021, AC-036
  - _TDD: RED — migration functions do not exist yet or are stubs_

### 4.2 Implement migrate() (GREEN)

- [ ] **4.2.1** Implement `migrate()` with version range validation
  - _Ticket ref: FR-041, FR-042_
  - _Returns data unchanged for from >= to or invalid range_
  - _Logs push_error for invalid ranges, no log for from >= to_
- [ ] **4.2.2** Implement sequential version-step loop with match statement
  - _Ticket ref: FR-034_
  - _Loops from from_version to to_version, calling step functions_

### 4.3 Implement _migrate_v1_to_v2() (GREEN)

- [ ] **4.3.1** Add `player_gold` → `wallet` restructuring
  - _Ticket ref: FR-037_
  - _wallet = {"gold": player_gold, "gems": 0, "essence": 0, "dust": 0}_
  - _Erase old `player_gold` key_
  - _Guard: only restructure if wallet doesn't already exist as Dictionary_
- [ ] **4.3.2** Add `loop_state.auto_harvest_enabled = false`
  - _Ticket ref: FR-036_
  - _Guard: only add if key doesn't already exist (idempotent)_
- [ ] **4.3.3** Add `settings.colorblind_mode = "none"` and `settings.text_size = "medium"`
  - _Ticket ref: FR-038, FR-039_
  - _Guard: only add if keys don't already exist (idempotent)_
- [ ] **4.3.4** Set `data["version"] = 2`
  - _Ticket ref: FR-040_

### 4.4 Verify & Refactor

- [ ] **4.4.1** Run all tests — confirm all 32 pass green (22 prior + 10 new)
  - _Note: `test_load_game_auto_migrates_v1` exercises the full load→migrate→validate chain_

### Phase 4 Validation Gate

- [ ] **4.V.1** `migrate(v1_data, 1, 2)` produces correct wallet, auto_harvest, colorblind, text_size
- [ ] **4.V.2** `migrate()` returns unchanged for same version or invalid range
- [ ] **4.V.3** Migration is idempotent on v2 data
- [ ] **4.V.4** `load_game()` auto-migrates v1 saves to v2
- [ ] **4.V.5** All 32 tests pass green (22 prior + 10 migration)
- [ ] **4.V.6** Existing tests unbroken
- [ ] **4.V.7** Commit: `"Phase 4: Implement migration pipeline with v1→v2 transform — 32 tests"`

---

## Phase 5: Validation & Slot Management (TDD)

> **Ticket References**: FR-025 through FR-033, FR-043 through FR-051
> **AC References**: AC-037 through AC-051
> **Estimated Items**: 15
> **Dependencies**: Phase 4 complete (migration works for full chain testing)
> **Validation Gate**: _validate(), list_slots(), delete_slot() fully implemented, all new tests pass

This phase implements the `_validate()` structural checker, `list_slots()` metadata query, and `delete_slot()` removal. Tests cover each validation failure mode, slot listing with empty/populated/corrupted states, delete operations, and slot independence.

### 5.1 Write Validation Tests (RED)

- [ ] **5.1.1** Add validation tests to `tests/services/test_save_service.gd`
  - _Ticket ref: AC-037 through AC-042_
  - _Tests (RED — _validate() may be minimal from Phase 3):_
    - `test_validate_valid_data_returns_true` — FR-043
    - `test_validate_missing_version_returns_false` — FR-043, AC-037
    - `test_validate_missing_seeds_returns_false` — FR-043, AC-042
    - `test_validate_seeds_not_array_returns_false` — FR-047, AC-038
    - `test_validate_negative_timestamp_returns_false` — FR-045, AC-039
    - `test_validate_slot_zero_returns_false` — FR-046, AC-040
    - `test_validate_slot_too_high_returns_false` — FR-046
    - `test_validate_inventory_missing_items_returns_false` — FR-050, AC-041
    - `test_validate_version_too_high_returns_false` — FR-044
    - `test_validate_version_zero_returns_false` — FR-044

### 5.2 Implement Full _validate() (GREEN)

- [ ] **5.2.1** Implement complete `_validate()` with all structural checks
  - _Ticket ref: FR-043 through FR-051_
  - _Checks: required keys exist, version in [1, CURRENT_VERSION], timestamp > 0, slot in [1, MAX_SLOTS], seeds is Array, adventurers is Array, dungeon/inventory/wallet/loop_state/settings are Dictionaries, inventory has "items" key_
  - _See ticket Section 16.1 for exact implementation_

### 5.3 Write Slot Management Tests (RED)

- [ ] **5.3.1** Add slot management tests to `tests/services/test_save_service.gd`
  - _Ticket ref: AC-043 through AC-051_
  - _Tests:_
    - `test_list_slots_empty_returns_three_entries` — FR-025, FR-028, AC-043
    - `test_list_slots_with_one_save` — FR-026, FR-027, AC-044
    - `test_list_slots_corrupted_file_shows_not_exists` — FR-028, AC-045
    - `test_delete_slot_removes_file` — FR-030, AC-046
    - `test_delete_slot_idempotent` — FR-032, AC-047
    - `test_delete_slot_out_of_range_returns_false` — FR-029, AC-048
    - `test_delete_slot_removes_tmp_file` — FR-031, AC-049
    - `test_delete_then_list_shows_empty` — AC-050
    - `test_slots_are_independent` — AC-051
    - `test_overwrite_one_slot_does_not_affect_others` — AC-051

### 5.4 Implement list_slots() and delete_slot() (GREEN)

- [ ] **5.4.1** Implement `list_slots()` — returns Array[Dictionary] with 3 entries
  - _Ticket ref: FR-025 through FR-028_
  - _Each entry: {slot: int, timestamp: int, exists: bool}_
  - _Reads file, parses JSON, extracts timestamp for existing slots_
  - _Returns exists: false for missing or corrupted files_
- [ ] **5.4.2** Implement `delete_slot()` — removes .json and .json.tmp files
  - _Ticket ref: FR-029 through FR-033_
  - _Validates slot range, removes both files, idempotent (true if file gone)_

### 5.5 Verify & Refactor

- [ ] **5.5.1** Run all tests — confirm all ~52 pass green (32 prior + 10 validation + 10 slot management)

### Phase 5 Validation Gate

- [ ] **5.V.1** `_validate()` returns `true` for valid complete data
- [ ] **5.V.2** `_validate()` returns `false` for each missing/invalid field
- [ ] **5.V.3** `list_slots()` returns exactly 3 entries
- [ ] **5.V.4** `delete_slot()` removes files and is idempotent
- [ ] **5.V.5** Slots are independent — saving to one doesn't affect others
- [ ] **5.V.6** All ~52 tests pass green
- [ ] **5.V.7** Existing tests unbroken
- [ ] **5.V.8** Commit: `"Phase 5: Implement _validate(), list_slots(), delete_slot() — ~52 tests"`

---

## Phase 6: Legacy Cleanup & Final Validation

> **Ticket References**: AC-052 through AC-059, all NFRs
> **AC References**: AC-052 through AC-059
> **Estimated Items**: 14
> **Dependencies**: ALL prior phases complete
> **Validation Gate**: All tests green, legacy file handled, all NFRs verified, all ACs met

This phase deprecates the old `save_manager.gd`, runs the full test suite, verifies all NFRs, and performs final code quality checks.

### 6.1 Legacy File Cleanup

- [ ] **6.1.1** Deprecate or delete `src/gdscript/utils/save_manager.gd`
  - _Ticket ref: AC-057_
  - _Option A: Delete the file entirely if no other code references it_
  - _Option B: Replace contents with deprecation stub pointing to SaveService (see ticket Section 16.2)_
  - _Check for references: `grep -r "save_manager" src/` and `grep -r "SaveManager" src/`_

### 6.2 Code Quality Verification (NFRs)

- [ ] **6.2.1** `SaveService` extends `RefCounted` (not Node) — no scene tree dependencies (NFR-005, AC-052)
- [ ] **6.2.2** `SaveService` has zero autoload dependencies — does not reference EventBus or GameManager (NFR-006, AC-055)
- [ ] **6.2.3** All public methods have full type hints (parameters and return types) (NFR-007, AC-053)
- [ ] **6.2.4** All public methods have `##` doc comments (NFR-008, AC-054)
- [ ] **6.2.5** SaveService is stateless — no cached file handles, no internal state between calls (NFR-011)
- [ ] **6.2.6** All GDScript follows naming conventions: snake_case variables/functions, PascalCase class, UPPER_SNAKE constants (NFR standard)
- [ ] **6.2.7** `save_game()` does not modify input Dictionary beyond version/timestamp/slot injection (NFR-014)
- [ ] **6.2.8** All file paths use `user://` prefix (NFR standard)
- [ ] **6.2.9** Log messages include slot number and specific error condition (NFR-017)

### 6.3 Full Test Suite Execution

- [ ] **6.3.1** Run complete GUT test suite — ALL tests pass green (AC-059)
  - _Expected: ~46 tests in `test_save_service.gd`, 0 failures, 0 errors_
- [ ] **6.3.2** Verify zero regressions in existing test files
- [ ] **6.3.3** Verify `SaveService.new()` works in Godot editor script console

### 6.4 GUT Configuration

- [ ] **6.4.1** Verify `.gutconfig.json` includes `tests/services/` directory (or uses `res://tests/` which covers it)
  - _Ticket ref: Section 16.3_

### Phase 6 Validation Gate

- [ ] **6.V.1** Legacy `save_manager.gd` deprecated or deleted (AC-057)
- [ ] **6.V.2** All NFRs verified (NFR-001 through NFR-017)
- [ ] **6.V.3** All ~46 tests pass green (AC-059)
- [ ] **6.V.4** Zero regressions in existing tests
- [ ] **6.V.5** Code review checklist: class_name, extends, constants, type hints, doc comments all correct
- [ ] **6.V.6** Commit: `"TASK-009 complete: SaveService with versioned serialization — ~46 tests, all green"`

---

## Phase Dependency Graph

```
Phase 0 (Pre-Flight & Setup)
    │
    ▼
Phase 1 (Skeleton & Constants)
    │
    ▼
Phase 2 (Save Operations)
    │
    ▼
Phase 3 (Load Operations)
    │
    ▼
Phase 4 (Migration Pipeline)
    │
    ▼
Phase 5 (Validation & Slot Management)
    │
    ▼
Phase 6 (Legacy Cleanup & Final Validation)
```

**Parallelism note**: This task is strictly sequential — each phase builds on the previous. Phase 3 needs Phase 2 for round-trip testing, Phase 4 needs Phase 3 for auto-migration testing, Phase 5 needs Phase 4 for full chain validation.

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 0 | Pre-flight & setup | 8 | 0 | 0 | ⬜ Not Started |
| Phase 1 | Skeleton & constants (TDD) | 10 | 0 | 3 | ⬜ Not Started |
| Phase 2 | Save operations (TDD) | 13 | 0 | 13 | ⬜ Not Started |
| Phase 3 | Load operations (TDD) | 11 | 0 | 22 | ⬜ Not Started |
| Phase 4 | Migration pipeline (TDD) | 12 | 0 | 32 | ⬜ Not Started |
| Phase 5 | Validation & slot management (TDD) | 15 | 0 | 52 | ⬜ Not Started |
| Phase 6 | Legacy cleanup & final validation | 14 | 0 | ~46 | ⬜ Not Started |
| **Total** | | **~83** | **0** | **~46** | **⬜ Phase 0 Next** |

---

## File Change Summary

### New Files

| File | Phase | Purpose |
|------|-------|---------|
| `src/services/save_service.gd` | 1-5 | SaveService — RefCounted save/load manager with versioned serialization |
| `tests/services/test_save_service.gd` | 1-5 | GUT tests for SaveService (~46 test methods) |

### Modified Files

| File | Phase | Change |
|------|-------|--------|
| _None_ | — | No existing files are modified |

### Deleted/Deprecated Files

| File | Phase | Change |
|------|-------|--------|
| `src/gdscript/utils/save_manager.gd` | 6 | Deprecated with stub pointing to SaveService, or deleted |

---

## Commit Strategy

| Phase | Commit Message | Tests After |
|-------|----------------|-------------|
| 0 | `"Phase 0: TASK-009 pre-flight — verify dependencies, create tests/services/"` | 0 (baseline) |
| 1 | `"Phase 1: SaveService skeleton with constants and slot validation — 3 tests"` | 3 |
| 2 | `"Phase 2: Implement save_game() with atomic write — 13 tests"` | 13 |
| 3 | `"Phase 3: Implement load_game() with JSON parsing and size guard — 22 tests"` | 22 |
| 4 | `"Phase 4: Implement migration pipeline with v1→v2 transform — 32 tests"` | 32 |
| 5 | `"Phase 5: Implement _validate(), list_slots(), delete_slot() — ~52 tests"` | ~52 |
| 6 | `"TASK-009 complete: SaveService with versioned serialization — ~46 tests, all green"` | ~46 ✅ |

---

## Deviation Tracking

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| _(none yet)_ | | | | | |

> **Note**: The test count may vary slightly from the ticket's estimate of "20+" — the ticket Section 14.1 contains ~46 test methods. The plan follows the ticket's full test suite.

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| `user://saves/` directory not writable in test environment | Low | High | Tests create/clean directory in before_each/after_each; if user:// fails, document as deviation | 2 |
| `class_name SaveService` conflicts with existing code | Low | High | Search codebase for existing `class_name SaveService` before creating (Phase 1) | 1 |
| Legacy `save_manager.gd` referenced by other v1 code | Medium | Low | Check references via grep before deleting; use deprecation stub if references exist | 6 |
| `JSON.parse_string()` returns float for integer values (Godot JSON behavior) | Medium | Medium | `_validate()` accepts both `int` and `float` for numeric fields; migration handles both | 5 |
| `DirAccess.rename()` fails on Windows if target exists | Medium | Medium | Implementation removes target before rename (ticket Section 16.1 handles this) | 2 |
| `FileAccess.file_exists()` returns stale results in rapid save/load cycles | Low | Low | Tests include cleanup in before_each/after_each to prevent stale state | 2-5 |
| GUT test discovery misses `tests/services/` directory | Low | Medium | Verify `.gutconfig.json` includes `res://tests/` path; add if missing | 6 |
| Atomic write temp file left behind after test crash | Low | Low | after_each cleanup removes all files in saves directory including .tmp | 2 |
| `Time.get_unix_time_from_system()` unavailable in headless test mode | Low | Medium | If timestamp is 0, tests adjust assertions to check for numeric type only | 2 |

---

## Handoff State (2025-07-19)

### What's Complete
- Implementation plan written and ready for execution

### What's In Progress
- Nothing — plan is at Phase 0 (not started)

### What's Blocked
- Nothing — TASK-001 dependency is confirmed IMPLEMENTED

### Next Steps
1. Execute Phase 0: Verify dependencies, create `tests/services/` directory
2. Execute Phase 1: Create SaveService skeleton with constants and slot validation tests
3. Execute Phase 2: Implement save_game() with atomic write and full test coverage
4. Execute Phase 3: Implement load_game() with JSON parsing and edge case tests
5. Execute Phase 4: Implement migration pipeline with v1→v2 transform
6. Execute Phase 5: Implement _validate(), list_slots(), delete_slot() with full coverage
7. Execute Phase 6: Deprecate legacy file, final validation, all ~46 tests green

---

## Ticket FR/AC Coverage Matrix

Every Functional Requirement and Acceptance Criterion from the ticket is mapped below.

### Functional Requirements → Phase Items

| FR | Description | Phase | Checkbox |
|----|-------------|-------|----------|
| FR-001 | SaveService extends RefCounted with class_name | 1 | 1.2.1 |
| FR-002 | CURRENT_VERSION = 2 | 1 | 1.2.2 |
| FR-003 | MAX_SLOTS = 3 | 1 | 1.2.3 |
| FR-004 | SAVE_DIR = "user://saves/" | 1 | 1.2.4 |
| FR-005 | save_game() validates slot 1-MAX_SLOTS | 1, 2 | 1.2.8, 2.2.1 |
| FR-006 | save_game() injects version | 2 | 2.2.1 |
| FR-007 | save_game() injects timestamp | 2 | 2.2.1 |
| FR-008 | save_game() injects slot | 2 | 2.2.1 |
| FR-009 | save_game() creates SAVE_DIR if missing | 2 | 2.2.2 |
| FR-010 | JSON.stringify with tab indent | 2 | 2.2.3 |
| FR-011 | Atomic write: write to .tmp first | 2 | 2.2.4 |
| FR-012 | Atomic write: rename .tmp to .json | 2 | 2.2.4 |
| FR-013 | Delete .tmp on failure | 2 | 2.2.4 |
| FR-014 | Return true/false | 2 | 2.2.4 |
| FR-015 | push_error on failure | 2 | 2.2.4 |
| FR-016 | load_game() validates slot | 3 | 3.2.1 |
| FR-017 | Return {} if file missing | 3 | 3.2.2 |
| FR-018 | Read file and parse JSON | 3 | 3.2.4 |
| FR-019 | Return {} if JSON null | 3 | 3.2.4 |
| FR-020 | Return {} if not Dictionary | 3 | 3.2.4 |
| FR-021 | Call migrate() if version < CURRENT | 3, 4 | 3.2.5, 4.2.1 |
| FR-022 | Call _validate() on loaded data | 3 | 3.2.6 |
| FR-023 | Return {} if validation fails | 3 | 3.2.6 |
| FR-024 | push_warning on corruption/validation failure | 3 | 3.2.6 |
| FR-025 | list_slots() returns MAX_SLOTS entries | 5 | 5.4.1 |
| FR-026 | Entries contain slot, timestamp, exists | 5 | 5.4.1 |
| FR-027 | exists=true with timestamp for valid files | 5 | 5.4.1 |
| FR-028 | exists=false, timestamp=0 for missing/corrupted | 5 | 5.4.1 |
| FR-029 | delete_slot() validates slot | 5 | 5.4.2 |
| FR-030 | delete_slot() removes .json | 5 | 5.4.2 |
| FR-031 | delete_slot() removes .json.tmp | 5 | 5.4.2 |
| FR-032 | delete_slot() returns true if file gone | 5 | 5.4.2 |
| FR-033 | delete_slot() returns false only if removal fails | 5 | 5.4.2 |
| FR-034 | migrate() applies sequential steps | 4 | 4.2.2 |
| FR-035 | Dedicated _migrate_v1_to_v2() method | 4 | 4.3.1 |
| FR-036 | v1→v2: auto_harvest_enabled = false | 4 | 4.3.2 |
| FR-037 | v1→v2: player_gold → wallet dict | 4 | 4.3.1 |
| FR-038 | v1→v2: colorblind_mode = "none" | 4 | 4.3.3 |
| FR-039 | v1→v2: text_size = "medium" | 4 | 4.3.3 |
| FR-040 | v1→v2: version = 2 | 4 | 4.3.4 |
| FR-041 | migrate() returns unchanged if from >= to | 4 | 4.2.1 |
| FR-042 | migrate() returns unchanged for invalid range | 4 | 4.2.1 |
| FR-043 | _validate() checks all required keys | 5 | 5.2.1 |
| FR-044 | _validate() checks version range | 5 | 5.2.1 |
| FR-045 | _validate() checks timestamp > 0 | 5 | 5.2.1 |
| FR-046 | _validate() checks slot range | 5 | 5.2.1 |
| FR-047 | _validate() checks seeds is Array | 5 | 5.2.1 |
| FR-048 | _validate() checks adventurers is Array | 5 | 5.2.1 |
| FR-049 | _validate() checks dict types | 5 | 5.2.1 |
| FR-050 | _validate() checks inventory has items key | 5 | 5.2.1 |
| FR-051 | _validate() push_warning on failure | 5 | 5.2.1 |
| FR-052 | _get_slot_path() helper | 1 | 1.2.7 |
| FR-053 | _get_temp_path() helper | 1 | 1.2.7 |

### Acceptance Criteria → Phase Verification

| AC | Description | Phase | Verification |
|----|-------------|-------|--------------|
| AC-001 | save_game(1) returns true, creates file | 2 | 2.V.1, 2.V.2 |
| AC-002 | save_game(2) creates slot_2.json | 2 | test_save_game_creates_file_on_disk |
| AC-003 | save_game(3) creates slot_3.json | 2 | test_slots_are_independent |
| AC-004 | Saved JSON has version: 2 | 2 | test_save_game_injects_version |
| AC-005 | Saved JSON has timestamp > 0 | 2 | test_save_game_injects_timestamp |
| AC-006 | Saved JSON has slot matching arg | 2 | test_save_game_injects_slot_number |
| AC-007 | Saved file is valid JSON | 2 | test_save_game_file_is_valid_json |
| AC-008 | Saved JSON is tab-indented | 6 | 6.2 manual inspection |
| AC-009 | save_game(0) returns false | 1 | test_save_game_slot_zero_returns_false |
| AC-010 | save_game(4) returns false | 1 | test_save_game_slot_four_returns_false |
| AC-011 | save_game(-1) returns false | 1 | test_save_game_slot_negative_returns_false |
| AC-012 | Creates saves/ directory if missing | 2 | test_save_game_creates_directory_if_missing |
| AC-013 | Overwrite replaces file | 2 | test_save_game_overwrites_existing_save |
| AC-014 | save_game() doesn't mutate input | 2 | test_save_game_does_not_mutate_input_beyond_metadata |
| AC-015 | Round-trip save→load | 3 | test_load_game_round_trip |
| AC-016 | Empty slot returns {} | 3 | test_load_game_empty_slot_returns_empty_dict |
| AC-017 | Invalid JSON returns {} | 3 | test_load_game_invalid_json_returns_empty_dict |
| AC-018 | Truncated JSON returns {} | 3 | test_load_game_truncated_json_returns_empty_dict |
| AC-019 | JSON array returns {} | 3 | test_load_game_json_array_returns_empty_dict |
| AC-020 | Missing keys returns {} | 3 | test_load_game_missing_keys_returns_empty_dict |
| AC-021 | load_game(0) returns {} | 3 | test_load_game_slot_zero_returns_empty_dict |
| AC-022 | load_game(4) returns {} | 3 | test_load_game_slot_four_returns_empty_dict |
| AC-023 | Oversized file returns {} | 3 | test_load_game_oversized_file_returns_empty_dict |
| AC-024 | (load_game push_warning) | 3 | 3.2.6 implementation |
| AC-025 | (load_game push_warning) | 3 | 3.2.6 implementation |
| AC-026 | (load_game push_warning) | 3 | 3.2.6 implementation |
| AC-027 | v1→v2 creates wallet from player_gold | 4 | test_migrate_v1_to_v2_creates_wallet |
| AC-028 | v1→v2 adds auto_harvest_enabled | 4 | test_migrate_v1_to_v2_adds_auto_harvest |
| AC-029 | v1→v2 adds colorblind_mode | 4 | test_migrate_v1_to_v2_adds_colorblind_mode |
| AC-030 | v1→v2 adds text_size | 4 | test_migrate_v1_to_v2_adds_text_size |
| AC-031 | v1→v2 updates version to 2 | 4 | test_migrate_v1_to_v2_updates_version |
| AC-032 | Same-version migration = no-op | 4 | test_migrate_same_version_returns_unchanged |
| AC-033 | Higher from_version = no-op | 4 | test_migrate_higher_from_returns_unchanged |
| AC-034 | Invalid from_version = no-op | 4 | test_migrate_invalid_from_returns_unchanged |
| AC-035 | Migration idempotent on v2 data | 4 | test_migrate_idempotent_on_v2_data |
| AC-036 | load_game auto-migrates v1 | 4 | test_load_game_auto_migrates_v1 |
| AC-037 | _validate: missing version → false | 5 | test_validate_missing_version_returns_false |
| AC-038 | _validate: seeds not Array → false | 5 | test_validate_seeds_not_array_returns_false |
| AC-039 | _validate: negative timestamp → false | 5 | test_validate_negative_timestamp_returns_false |
| AC-040 | _validate: slot 0 → false | 5 | test_validate_slot_zero_returns_false |
| AC-041 | _validate: inventory missing items → false | 5 | test_validate_inventory_missing_items_returns_false |
| AC-042 | _validate: any missing key → false | 5 | test_validate_missing_seeds_returns_false |
| AC-043 | list_slots() returns 3 entries when empty | 5 | test_list_slots_empty_returns_three_entries |
| AC-044 | list_slots() shows exists:true with timestamp | 5 | test_list_slots_with_one_save |
| AC-045 | list_slots() shows exists:false for corrupted | 5 | test_list_slots_corrupted_file_shows_not_exists |
| AC-046 | delete_slot(1) removes file | 5 | test_delete_slot_removes_file |
| AC-047 | delete_slot(1) returns true if file missing | 5 | test_delete_slot_idempotent |
| AC-048 | delete_slot(0) returns false | 5 | test_delete_slot_out_of_range_returns_false |
| AC-049 | delete_slot() removes .tmp file | 5 | test_delete_slot_removes_tmp_file |
| AC-050 | After delete, list_slots shows empty | 5 | test_delete_then_list_shows_empty |
| AC-051 | Slot independence | 5 | test_slots_are_independent, test_overwrite_one_slot_does_not_affect_others |
| AC-052 | extends RefCounted, class_name SaveService | 1, 6 | 1.V.2, 6.2.1 |
| AC-053 | Full type hints | 6 | 6.2.3 |
| AC-054 | ## doc comments | 6 | 6.2.4 |
| AC-055 | No autoload dependencies | 6 | 6.2.2 |
| AC-056 | Constants declared correctly | 1 | 1.V.3 |
| AC-057 | Legacy save_manager.gd deprecated/deleted | 6 | 6.1.1 |
| AC-058 | Test file at tests/services/test_save_service.gd | 1 | 1.1.1 |
| AC-059 | All tests pass green | 6 | 6.3.1 |

---

*End of TASK-009 Implementation Plan*
