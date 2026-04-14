# TASK-001: Project Bootstrap & Autoload Skeleton — Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-001-project-bootstrap.md`
> **GDD**: `neil-docs/epics/dungeon-seed/GDD-v2.md`
> **Status**: Planning
> **Created**: 2025-07-18
> **Repo**: `dev-agent-tool` (local — `C:\Users\wrstl\source\dev-agent-tool`)
> **Methodology**: TDD Red-Green-Refactor (mandatory for all phases)
> **Complexity**: 3 points (Trivial) — Fibonacci
> **Estimated Phases**: 5
> **Estimated Checkboxes**: ~45

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents in this order:

1. **This file** (you're reading it) — the phased checklist of what to do, with status
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-001-project-bootstrap.md`** — the full technical spec with exact code to implement
3. **`neil-docs/epics/dungeon-seed/GDD-v2.md`** — the Game Design Document for understanding domain context
4. **`project.godot`** — the existing engine config (the only file we modify)
5. **`src/scenes/main_menu.tscn`** — the existing main menu scene (already created, we do NOT touch it)

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| Engine config | `project.godot` | **Modified** — add `[autoload]` section |
| Autoload scripts | `src/autoloads/` | **NEW** — `event_bus.gd`, `game_manager.gd` |
| Utility scripts | `src/utils/` | **NEW** — `scene_router.gd` |
| Placeholder dirs | `src/models/`, `src/services/`, `src/managers/`, `src/ui/`, `src/resources/`, `src/shaders/` | **NEW** — empty with `.gdkeep` |
| Existing scenes | `src/scenes/` | **EXISTS** — `main_menu.tscn` already present |
| Unit tests | `tests/unit/` | **EXISTS** — add 3 new test files |
| Integration tests | `tests/integration/` | **EXISTS** — empty, no changes needed |
| v1 prototype code | `src/gdscript/` | **DO NOT TOUCH** — legacy code, not part of this task |
| GUT addon | `addons/gut/` | **PRE-REQUISITE** — GUT is NOT installed yet. Must install before Phase 4. |

### Key Concepts (5-minute primer)

- **Autoload**: A Godot singleton Node that persists across scene changes. Registered in `project.godot` under `[autoload]`.
- **EventBus**: A central signal hub. All cross-system communication goes through typed signals here instead of direct references.
- **GameManager**: A lifecycle singleton. Holds references to domain services (SeedGrove, Roster, etc.) and provides `initialize()`/`shutdown()`.
- **SceneRouter**: A utility (NOT autoload) that wraps `get_tree().change_scene_to_file()` with path validation and signals.
- **Typed Signals**: Godot 4 signals declared with explicit parameter types (e.g., `signal seed_planted(seed_id: StringName, slot_index: int)`).
- **RefCounted**: Godot base class for garbage-collected objects. Used for data models and services that don't need the scene tree.
- **GUT**: Godot Unit Test framework. Tests extend `GutTest` and use `assert_*` methods.
- **`.gdkeep`**: Empty placeholder file so git tracks otherwise-empty directories.
- **`class_name`**: GDScript keyword that registers a script as a globally available type — no `preload()` needed.

### Build & Verification Commands

```powershell
# There is no CLI build for GDScript — verification is done in-editor.
# However, you can verify script syntax via headless Godot:

# Open project in editor (manual)
# Press F5 to run — should launch to main_menu.tscn

# Run GUT tests from within the editor:
#   1. Open GUT panel (bottom dock)
#   2. Click "Run All" — all tests must pass green

# Verify autoloads in Remote scene tree:
#   1. F5 to run
#   2. Switch to "Remote" tab in Scene dock
#   3. Expand root — EventBus and GameManager should be visible
```

### Regression Gate

Before AND after every phase:
1. `project.godot` must be valid (opens in editor without errors)
2. `src/scenes/main_menu.tscn` must still be the main scene and load correctly
3. No existing test files in `tests/unit/` are broken by our changes
4. All new GUT tests pass green (once written in Phase 4)

---

## Current State Analysis

### What Exists Today

| Item | Status | Location |
|------|--------|----------|
| `project.godot` | ✅ Exists | Root — names project "Dungeon Seed", points to `main_menu.tscn` |
| `src/scenes/main_menu.tscn` | ✅ Exists | Full main menu scene with Title, NewGame, Settings, Quit buttons |
| `src/scenes/main_menu.gd` | ✅ Exists | Script attached to main menu scene |
| `tests/unit/` | ✅ Exists | Contains ~30+ existing test files (v1 prototype) |
| `tests/integration/` | ✅ Exists | Empty directory |
| `src/gdscript/` | ✅ Exists | v1 prototype code (DO NOT TOUCH) |
| `src/core/`, `src/Gateway/`, `src/Generators/` | ✅ Exists | Non-GDScript project code (DO NOT TOUCH) |

### What's Missing (Gap Analysis)

| Item | Status | Required By |
|------|--------|-------------|
| `src/autoloads/` directory | ❌ Missing | FR-001 |
| `src/autoloads/event_bus.gd` | ❌ Missing | FR-005 through FR-012 |
| `src/autoloads/game_manager.gd` | ❌ Missing | FR-013 through FR-018 |
| `src/utils/` directory | ❌ Missing | FR-003 |
| `src/utils/scene_router.gd` | ❌ Missing | FR-019 through FR-021 |
| `src/models/` directory | ❌ Missing | FR-002 |
| `src/services/` directory | ❌ Missing | FR-002 |
| `src/managers/` directory | ❌ Missing | FR-002 |
| `src/ui/` directory | ❌ Missing | FR-002 |
| `src/resources/` directory | ❌ Missing | FR-002 |
| `src/shaders/` directory | ❌ Missing | FR-002 |
| `[autoload]` section in `project.godot` | ❌ Missing | FR-022 through FR-024 |
| GUT addon (`addons/gut/`) | ❌ Missing | Pre-requisite for tests |
| Test files for new code | ❌ Missing | Section 14 |

### What Must NOT Change

- `src/scenes/main_menu.tscn` — existing scene, referenced by `project.godot`
- `src/scenes/main_menu.gd` — script attached to the main menu
- `src/gdscript/` — v1 prototype code, explicitly out of scope
- `src/core/`, `src/Gateway/`, `src/Generators/` — non-GDScript project infrastructure
- Existing test files in `tests/unit/` — must not be broken
- `[application]` and `[rendering]` sections of `project.godot` — only add `[autoload]`

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
func test_event_bus_is_node() -> void:

# Specific behavior
func test_initialize_sets_flag() -> void:

# Error cases
func test_scene_router_rejects_nonexistent_path() -> void:
```

### Test Structure (GUT)

Every test follows Arrange-Act-Assert:
```gdscript
func test_method_scenario_expected() -> void:
    # Arrange — create instance and test data
    var bus := EventBus.new()
    add_child(bus)
    watch_signals(bus)

    # Act — execute the behavior
    bus.seed_planted.emit(&"oak_seed", 0)

    # Assert — verify the outcome
    assert_signal_emitted(bus, "seed_planted")

    # Cleanup
    bus.queue_free()
```

### Coverage Requirements Per Phase

- ✅ **Existence**: Class exists, extends correct base, has `class_name`
- ✅ **Signal declaration**: All signals exist with correct names
- ✅ **Signal emission**: Signals can be emitted with typed parameters
- ✅ **Method behavior**: Public methods produce correct results
- ✅ **Edge cases**: Double-init, shutdown-without-init, invalid paths
- ✅ **Error handling**: Bad input returns correct error codes

---

## Phase 0: Pre-Flight & Directory Skeleton

> **Ticket References**: FR-001, FR-002, FR-003, FR-004
> **AC References**: AC-001 through AC-011
> **Estimated Items**: 12
> **Dependencies**: None
> **Validation Gate**: All 11 directories exist; `project.godot` unchanged; existing tests unbroken

This phase creates the canonical folder structure with `.gdkeep` placeholders. No code is written yet.

### 0.1 Create Directory Structure

- [ ] **0.1.1** Create directory `src/autoloads/`
  - _Ticket ref: FR-001_
- [ ] **0.1.2** Create directory `src/models/`
  - _Ticket ref: FR-002_
- [ ] **0.1.3** Create directory `src/services/`
  - _Ticket ref: FR-002_
- [ ] **0.1.4** Create directory `src/managers/`
  - _Ticket ref: FR-002_
- [ ] **0.1.5** Create directory `src/ui/`
  - _Ticket ref: FR-002_
- [ ] **0.1.6** Create directory `src/resources/`
  - _Ticket ref: FR-002_
- [ ] **0.1.7** Create directory `src/shaders/`
  - _Ticket ref: FR-002_
- [ ] **0.1.8** Create directory `src/utils/`
  - _Ticket ref: FR-003_

> **Note**: `src/scenes/`, `tests/unit/`, and `tests/integration/` already exist — no action needed (AC-006, AC-010, AC-011 already satisfied).

### 0.2 Create `.gdkeep` Placeholders

- [ ] **0.2.1** Create `src/models/.gdkeep` (empty file)
  - _Ticket ref: FR-002, AC-002_
- [ ] **0.2.2** Create `src/services/.gdkeep` (empty file)
  - _Ticket ref: FR-002, AC-003_
- [ ] **0.2.3** Create `src/managers/.gdkeep` (empty file)
  - _Ticket ref: FR-002, AC-004_
- [ ] **0.2.4** Create `src/ui/.gdkeep` (empty file)
  - _Ticket ref: FR-002, AC-005_
- [ ] **0.2.5** Create `src/resources/.gdkeep` (empty file)
  - _Ticket ref: FR-002, AC-007_
- [ ] **0.2.6** Create `src/shaders/.gdkeep` (empty file)
  - _Ticket ref: FR-002, AC-008_

### Phase 0 Validation Gate

- [ ] **0.V.1** Verify all 11 directories exist (run `ls -R src/` and `ls -R tests/`)
- [ ] **0.V.2** Verify `project.godot` is unchanged (no edits in this phase)
- [ ] **0.V.3** Verify existing `src/scenes/main_menu.tscn` still references correctly
- [ ] **0.V.4** Commit: `"Phase 0: Create canonical folder structure with .gdkeep placeholders"`

---

## Phase 1: EventBus Autoload (TDD)

> **Ticket References**: FR-005 through FR-012
> **AC References**: AC-012, AC-013, AC-014
> **Estimated Items**: 8
> **Dependencies**: Phase 0 complete (directory exists)
> **Validation Gate**: `event_bus.gd` exists, extends Node, has class_name, declares 6 typed signals with doc comments

### 1.1 Write Test File (RED)

- [ ] **1.1.1** Create `tests/unit/test_event_bus.gd` with all 13 test functions from ticket Section 14.1
  - _Ticket ref: Section 14.1_
  - _File: `tests/unit/test_event_bus.gd`_
  - _Tests: `test_event_bus_is_node`, `test_seed_planted_signal_exists`, `test_seed_matured_signal_exists`, `test_expedition_started_signal_exists`, `test_expedition_completed_signal_exists`, `test_loot_gained_signal_exists`, `test_adventurer_recruited_signal_exists`, `test_seed_planted_emission`, `test_seed_matured_emission`, `test_expedition_started_emission`, `test_expedition_completed_emission`, `test_loot_gained_emission`, `test_adventurer_recruited_emission`_
  - _TDD: RED — tests reference `EventBus` class which does not exist yet_

### 1.2 Implement EventBus (GREEN)

- [ ] **1.2.1** Create `src/autoloads/event_bus.gd` with class declaration
  - _Ticket ref: FR-005, FR-006_
  - _File: `src/autoloads/event_bus.gd`_
  - _Content: `class_name EventBus` + `extends Node`_
- [ ] **1.2.2** Add `seed_planted` signal with typed parameters and doc comment
  - _Ticket ref: FR-007, AC-013, AC-014_
  - _Signal: `signal seed_planted(seed_id: StringName, slot_index: int)`_
- [ ] **1.2.3** Add `seed_matured` signal with typed parameters and doc comment
  - _Ticket ref: FR-008, AC-013, AC-014_
  - _Signal: `signal seed_matured(seed_id: StringName, slot_index: int)`_
- [ ] **1.2.4** Add `expedition_started` signal with typed parameters and doc comment
  - _Ticket ref: FR-009, AC-013, AC-014_
  - _Signal: `signal expedition_started(dungeon_id: StringName, party_ids: Array[StringName])`_
- [ ] **1.2.5** Add `expedition_completed` signal with typed parameters and doc comment
  - _Ticket ref: FR-010, AC-013, AC-014_
  - _Signal: `signal expedition_completed(dungeon_id: StringName, success: bool, turns_taken: int)`_
- [ ] **1.2.6** Add `loot_gained` signal with typed parameters and doc comment
  - _Ticket ref: FR-011, AC-013, AC-014_
  - _Signal: `signal loot_gained(item_id: StringName, quantity: int, source: StringName)`_
- [ ] **1.2.7** Add `adventurer_recruited` signal with typed parameters and doc comment
  - _Ticket ref: FR-012, AC-013, AC-014_
  - _Signal: `signal adventurer_recruited(adventurer_id: StringName, class_type: StringName)`_

> **Implementation source**: Ticket Section 16.1 has the complete, copy-pasteable `event_bus.gd`.

### Phase 1 Validation Gate

- [ ] **1.V.1** `src/autoloads/event_bus.gd` exists and is parseable GDScript
- [ ] **1.V.2** File extends `Node` and declares `class_name EventBus`
- [ ] **1.V.3** All 6 signals declared with full type annotations
- [ ] **1.V.4** All 6 signals have `##` doc comments
- [ ] **1.V.5** File is under 150 lines (NFR-005)
- [ ] **1.V.6** All 13 EventBus tests pass green (once GUT is available)
- [ ] **1.V.7** Commit: `"Phase 1: Add EventBus autoload with 6 typed core-loop signals — 13 tests"`

---

## Phase 2: GameManager Autoload (TDD)

> **Ticket References**: FR-013 through FR-018
> **AC References**: AC-015 through AC-020
> **Estimated Items**: 7
> **Dependencies**: Phase 0 complete (directory exists)
> **Validation Gate**: `game_manager.gd` exists, extends Node, has lifecycle methods, service placeholders default to null

### 2.1 Write Test File (RED)

- [ ] **2.1.1** Create `tests/unit/test_game_manager.gd` with all 9 test functions from ticket Section 14.2
  - _Ticket ref: Section 14.2_
  - _File: `tests/unit/test_game_manager.gd`_
  - _Tests: `test_game_manager_is_node`, `test_not_initialized_by_default`, `test_initialize_sets_flag`, `test_initialize_emits_signal`, `test_shutdown_clears_flag`, `test_shutdown_emits_signal`, `test_service_properties_default_to_null`, `test_double_initialize_is_safe`, `test_shutdown_without_initialize_is_safe`_
  - _TDD: RED — tests reference `GameManager` class which does not exist yet_

### 2.2 Implement GameManager (GREEN)

- [ ] **2.2.1** Create `src/autoloads/game_manager.gd` with class declaration and signals
  - _Ticket ref: FR-013, FR-014_
  - _File: `src/autoloads/game_manager.gd`_
  - _Content: `class_name GameManager` + `extends Node` + signals `game_initialized`, `game_shutdown`_
- [ ] **2.2.2** Add service reference properties (all `RefCounted`, default `null`)
  - _Ticket ref: FR-017, AC-019_
  - _Properties: `seed_grove`, `roster`, `wallet`, `loop_controller`_
- [ ] **2.2.3** Add `_initialized: bool = false` private state variable
  - _Ticket ref: FR-015_
- [ ] **2.2.4** Add `is_initialized() -> bool` getter method with doc comment
  - _Ticket ref: AC-018, NFR-007_
- [ ] **2.2.5** Add `initialize() -> void` method (sets flag, emits signal, guards double-init)
  - _Ticket ref: FR-015, AC-016_
- [ ] **2.2.6** Add `shutdown() -> void` method (clears flag, emits signal, guards pre-init shutdown)
  - _Ticket ref: FR-016, AC-017_

> **CRITICAL**: Verify `_ready()` does NOT call `initialize()` (FR-018, AC-020). The ticket implementation in Section 16.2 does not include a `_ready()` method at all — this is correct.

> **Implementation source**: Ticket Section 16.2 has the complete, copy-pasteable `game_manager.gd`.

### Phase 2 Validation Gate

- [ ] **2.V.1** `src/autoloads/game_manager.gd` exists and is parseable GDScript
- [ ] **2.V.2** File extends `Node` and declares `class_name GameManager`
- [ ] **2.V.3** `initialize()` sets `_initialized = true` and emits `game_initialized`
- [ ] **2.V.4** `shutdown()` sets `_initialized = false` and emits `game_shutdown`
- [ ] **2.V.5** All 4 service properties default to `null`
- [ ] **2.V.6** No `_ready()` calls `initialize()` (FR-018)
- [ ] **2.V.7** File is under 150 lines (NFR-005)
- [ ] **2.V.8** All 9 GameManager tests pass green (once GUT is available)
- [ ] **2.V.9** Commit: `"Phase 2: Add GameManager autoload with lifecycle methods — 9 tests"`

---

## Phase 3: SceneRouter Utility + project.godot Wiring

> **Ticket References**: FR-019 through FR-024
> **AC References**: AC-021 through AC-027
> **Estimated Items**: 8
> **Dependencies**: Phase 0 (directory), Phase 1 & 2 (autoloads exist for project.godot registration)
> **Validation Gate**: SceneRouter validates paths, project.godot has autoloads in correct order

### 3.1 Write Test File (RED)

- [ ] **3.1.1** Create `tests/unit/test_scene_router.gd` with all 5 test functions from ticket Section 14.3
  - _Ticket ref: Section 14.3_
  - _File: `tests/unit/test_scene_router.gd`_
  - _Tests: `test_scene_router_has_change_scene_method`, `test_scene_router_rejects_nonexistent_path`, `test_scene_router_rejects_invalid_prefix`, `test_scene_router_has_started_signal`, `test_scene_router_has_completed_signal`_
  - _TDD: RED — tests reference SceneRouter which does not exist yet_

> **Note**: The test file uses `const SceneRouterClass := preload("res://src/utils/scene_router.gd")` because SceneRouter is NOT an autoload — it must be preloaded explicitly.

### 3.2 Implement SceneRouter (GREEN)

- [ ] **3.2.1** Create `src/utils/scene_router.gd` with class declaration
  - _Ticket ref: FR-019_
  - _File: `src/utils/scene_router.gd`_
  - _Content: `class_name SceneRouter` + `extends Node`_
- [ ] **3.2.2** Add `SCENE_PATH_PREFIX` constant
  - _Content: `const SCENE_PATH_PREFIX: String = "res://src/scenes/"`_
- [ ] **3.2.3** Add `scene_change_started` and `scene_change_completed` signals
  - _Ticket ref: FR-021, AC-024_
- [ ] **3.2.4** Add `change_scene(scene_path: String) -> Error` method with path validation
  - _Ticket ref: FR-019, FR-020, AC-021, AC-022, AC-023_
  - _Logic: prefix check → `ResourceLoader.exists()` check → emit started → `change_scene_to_file()` → emit completed_
  - _Returns: `ERR_INVALID_PARAMETER` for bad prefix, `ERR_FILE_NOT_FOUND` for missing file_

> **Implementation source**: Ticket Section 16.3 has the complete, copy-pasteable `scene_router.gd`.

### 3.3 Wire project.godot Autoloads

- [ ] **3.3.1** Add `[autoload]` section to `project.godot` with EventBus FIRST, GameManager SECOND
  - _Ticket ref: FR-022, FR-023, FR-024, AC-025, AC-026, AC-027_
  - _File: `project.godot`_
  - _Add between `[application]` and `[rendering]`:_
    ```ini
    [autoload]

    EventBus="*res://src/autoloads/event_bus.gd"
    GameManager="*res://src/autoloads/game_manager.gd"
    ```
- [ ] **3.3.2** Verify autoload order: `EventBus` line appears BEFORE `GameManager` line
  - _Ticket ref: FR-024, AC-027_

### Phase 3 Validation Gate

- [ ] **3.V.1** `src/utils/scene_router.gd` exists and is parseable GDScript
- [ ] **3.V.2** `change_scene()` rejects paths not starting with `"res://src/scenes/"`
- [ ] **3.V.3** `change_scene()` returns `ERR_FILE_NOT_FOUND` for non-existent scenes
- [ ] **3.V.4** `project.godot` contains `[autoload]` section with both entries
- [ ] **3.V.5** EventBus line appears before GameManager line in `[autoload]`
- [ ] **3.V.6** All 5 SceneRouter tests pass green (once GUT is available)
- [ ] **3.V.7** Commit: `"Phase 3: Add SceneRouter utility + wire autoloads in project.godot — 5 tests"`

---

## Phase 4: GUT Installation & Test Execution

> **Ticket References**: Section 14 (all test files), NFR-011
> **AC References**: PAC-004
> **Estimated Items**: 5
> **Dependencies**: Phases 1-3 complete (all code + test files written)
> **Validation Gate**: GUT installed, all 27 tests pass green

### 4.1 Install GUT Addon

- [ ] **4.1.1** Verify GUT addon is present at `addons/gut/`; if not, install GUT v9.x+
  - _Method: Download from Godot Asset Library or clone from `https://github.com/bitwes/Gut`_
  - _Place in: `addons/gut/`_
  - _Ticket ref: Assumption #3 — "GUT is assumed pre-installed"_
  - _Note: GUT is the ONLY third-party addon allowed (NFR-011)_
- [ ] **4.1.2** Enable GUT plugin in Project Settings → Plugins
  - _Verify `addons/gut/plugin.cfg` exists and plugin status is "active"_

### 4.2 Run All Tests (GREEN confirmation)

- [ ] **4.2.1** Run `tests/unit/test_event_bus.gd` — verify all 13 tests pass
  - _Expected: 13 pass, 0 fail, 0 error_
- [ ] **4.2.2** Run `tests/unit/test_game_manager.gd` — verify all 9 tests pass
  - _Expected: 9 pass, 0 fail, 0 error_
- [ ] **4.2.3** Run `tests/unit/test_scene_router.gd` — verify all 5 tests pass
  - _Expected: 5 pass, 0 fail, 0 error_
  - _Note: `test_scene_router_rejects_nonexistent_path` will pass because `res://src/scenes/does_not_exist.tscn` does not exist_
  - _Note: `test_scene_router_rejects_invalid_prefix` will pass because `res://some/other/path.tscn` doesn't start with `res://src/scenes/`_

### Phase 4 Validation Gate

- [ ] **4.V.1** GUT addon installed and active
- [ ] **4.V.2** All 27 tests across 3 test files pass green
- [ ] **4.V.3** Zero existing tests in `tests/unit/` broken by our changes
- [ ] **4.V.4** Commit: `"Phase 4: Install GUT, verify all 27 TASK-001 tests pass green"`

---

## Phase 5: End-to-End Validation & Cleanup

> **Ticket References**: All PACs, NFR-001 through NFR-016
> **AC References**: PAC-001 through PAC-004, PV-01 through PV-08
> **Estimated Items**: 11
> **Dependencies**: ALL prior phases complete
> **Validation Gate**: Project opens clean, runs to main menu, autoloads visible, all tests green

### 5.1 Editor Verification (PACs)

- [ ] **5.1.1** Open project in Godot 4.5+ editor — zero errors in Output panel (PAC-001, PV-01)
- [ ] **5.1.2** Press F5 — game window appears, shows main menu, no crash (PAC-002, PV-02)
- [ ] **5.1.3** In Remote scene tree, verify `EventBus` and `GameManager` visible as autoload nodes (PAC-003, PV-03)
- [ ] **5.1.4** Verify EventBus node appears BEFORE GameManager node (FR-024)

### 5.2 Code Quality Verification (NFRs)

- [ ] **5.2.1** All GDScript files have static type hints on every variable, parameter, and return type (NFR-003)
- [ ] **5.2.2** All files follow GDScript style guide: snake_case variables/functions, PascalCase classes, UPPER_SNAKE constants (NFR-004)
- [ ] **5.2.3** No autoload script exceeds 150 lines (excluding comments/blanks) (NFR-005)
- [ ] **5.2.4** All public methods have `##` doc comments (NFR-007)
- [ ] **5.2.5** All file paths use `res://` prefix and forward slashes (NFR-010)
- [ ] **5.2.6** All scripts parseable with zero GDScript parser warnings (NFR-015)

### 5.3 Final Test Run

- [ ] **5.3.1** Run complete GUT test suite — all 27 tests pass green (PAC-004, PV-07)

### Phase 5 Validation Gate

- [ ] **5.V.1** All PACs (PAC-001 through PAC-004) pass
- [ ] **5.V.2** All PVs (PV-01 through PV-08) pass
- [ ] **5.V.3** All NFRs verified
- [ ] **5.V.4** Total disk footprint of new files under 50 KB (NFR-016)
- [ ] **5.V.5** Commit: `"TASK-001 complete: Project bootstrap & autoload skeleton — 27 tests, all green"`

---

## Phase Dependency Graph

```
Phase 0 (Directories) ──→ Phase 1 (EventBus)   ──┐
                      ╲                            ├──→ Phase 3 (SceneRouter + project.godot wiring)
                       ──→ Phase 2 (GameManager) ──┘
                                                         │
                                                         ▼
                                                   Phase 4 (GUT install + test run)
                                                         │
                                                         ▼
                                                   Phase 5 (E2E validation + cleanup)
```

**Parallelism note**: Phases 1 and 2 can be executed in parallel since they have no mutual dependencies — both only depend on Phase 0 (directories existing).

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 0 | Directory skeleton & .gdkeep | 12 | 0 | 0 | ⬜ Not Started |
| Phase 1 | EventBus autoload (TDD) | 8 | 0 | 13 | ⬜ Not Started |
| Phase 2 | GameManager autoload (TDD) | 7 | 0 | 9 | ⬜ Not Started |
| Phase 3 | SceneRouter + project.godot | 8 | 0 | 5 | ⬜ Not Started |
| Phase 4 | GUT install + test execution | 5 | 0 | 27 | ⬜ Not Started |
| Phase 5 | E2E validation & cleanup | 11 | 0 | 27 | ⬜ Not Started |
| **Total** | | **51** | **0** | **27** | **⬜ Phase 0 Next** |

---

## File Change Summary

### New Files

| File | Phase | Purpose |
|------|-------|---------|
| `src/autoloads/event_bus.gd` | 1 | EventBus autoload — central signal bus |
| `src/autoloads/game_manager.gd` | 2 | GameManager autoload — lifecycle singleton |
| `src/utils/scene_router.gd` | 3 | Scene transition utility with validation |
| `src/models/.gdkeep` | 0 | Git placeholder for empty directory |
| `src/services/.gdkeep` | 0 | Git placeholder for empty directory |
| `src/managers/.gdkeep` | 0 | Git placeholder for empty directory |
| `src/ui/.gdkeep` | 0 | Git placeholder for empty directory |
| `src/resources/.gdkeep` | 0 | Git placeholder for empty directory |
| `src/shaders/.gdkeep` | 0 | Git placeholder for empty directory |
| `tests/unit/test_event_bus.gd` | 1 | 13 unit tests for EventBus |
| `tests/unit/test_game_manager.gd` | 2 | 9 unit tests for GameManager |
| `tests/unit/test_scene_router.gd` | 3 | 5 unit tests for SceneRouter |

### Modified Files

| File | Phase | Change |
|------|-------|--------|
| `project.godot` | 3 | Add `[autoload]` section with EventBus + GameManager |

### Deleted Files

None — this task is additive only.

---

## Commit Strategy

| Phase | Commit Message | Tests After |
|-------|----------------|-------------|
| 0 | `"Phase 0: Create canonical folder structure with .gdkeep placeholders"` | 0 (no tests yet) |
| 1 | `"Phase 1: Add EventBus autoload with 6 typed core-loop signals — 13 tests"` | 13 (pending GUT) |
| 2 | `"Phase 2: Add GameManager autoload with lifecycle methods — 9 tests"` | 22 (pending GUT) |
| 3 | `"Phase 3: Add SceneRouter utility + wire autoloads in project.godot — 5 tests"` | 27 (pending GUT) |
| 4 | `"Phase 4: Install GUT, verify all 27 TASK-001 tests pass green"` | 27 ✅ |
| 5 | `"TASK-001 complete: Project bootstrap & autoload skeleton — 27 tests, all green"` | 27 ✅ |

---

## Deviation Tracking

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| _(none yet)_ | | | | | |

> **Note**: The existing `tests/unit/` directory already contains ~30+ test files from v1 prototype. These existing test file names (e.g., `test_game_manager.gd` — which already exists!) may collide with our new test files. If `tests/unit/test_game_manager.gd` already exists, the new file from this task MUST replace it or be named differently. Record any such collision as a deviation.

**⚠️ COLLISION WARNING**: The following test file already exists in `tests/unit/`:
- `test_game_manager.gd` — **POTENTIAL COLLISION** with our Phase 2 test file

**Resolution**: Before writing Phase 2 tests, check the contents of the existing `tests/unit/test_game_manager.gd`. If it tests the old v1 GameManager, rename the existing file to `test_game_manager_v1.gd` or name our new file `test_game_manager_bootstrap.gd`. Record the decision as DEV-001.

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| GUT addon not installed / incompatible with Godot 4.5+ | Medium | High | Install GUT v9.x+ from Asset Library; verify compatibility in Phase 4 | 4 |
| Existing `test_game_manager.gd` file name collision | High | Low | Check file contents first; rename existing or use alternate name | 2 |
| `class_name EventBus` conflicts with existing code in `src/gdscript/` | Low | High | Search codebase for existing `class_name EventBus` before creating | 1 |
| Godot 4.5 typed signal array syntax (`Array[StringName]`) not supported | Low | Medium | If unsupported, fall back to `Array` and document as deviation | 1 |
| `project.godot` autoload paths break if v1 code has its own autoloads | Low | Medium | Check existing `project.godot` for `[autoload]` section first | 3 |
| Existing main_menu.tscn script references v1 code that breaks with new autoloads | Low | Medium | Test F5 run after wiring autoloads; revert if crash | 5 |

---

## Handoff State (2025-07-18)

### What's Complete
- Implementation plan written and ready for execution

### What's In Progress
- Nothing — plan is at Phase 0 (not started)

### What's Blocked
- Nothing — TASK-001 has no upstream dependencies

### Next Steps
1. Execute Phase 0: Create directory skeleton
2. Execute Phase 1: Write EventBus test file (RED), then implement EventBus (GREEN)
3. Execute Phase 2: Write GameManager test file (RED), then implement GameManager (GREEN)
4. Execute Phase 3: Write SceneRouter test file (RED), implement SceneRouter, wire project.godot
5. Execute Phase 4: Install GUT, run all 27 tests
6. Execute Phase 5: Full end-to-end validation

---

## Ticket FR/AC Coverage Matrix

Every Functional Requirement and Acceptance Criterion from the ticket is mapped below.

### Functional Requirements → Phase Items

| FR | Description | Phase | Checkbox |
|----|-------------|-------|----------|
| FR-001 | `src/autoloads/` dir with event_bus.gd and game_manager.gd | 0, 1, 2 | 0.1.1, 1.2.1, 2.2.1 |
| FR-002 | Empty dirs: models, services, managers, ui, scenes, resources, shaders | 0 | 0.1.2–0.1.7 |
| FR-003 | `src/utils/` with scene_router.gd | 0, 3 | 0.1.8, 3.2.1 |
| FR-004 | `tests/unit/` and `tests/integration/` | 0 | Already exist |
| FR-005 | EventBus extends Node | 1 | 1.2.1 |
| FR-006 | EventBus declares class_name | 1 | 1.2.1 |
| FR-007 | seed_planted signal | 1 | 1.2.2 |
| FR-008 | seed_matured signal | 1 | 1.2.3 |
| FR-009 | expedition_started signal | 1 | 1.2.4 |
| FR-010 | expedition_completed signal | 1 | 1.2.5 |
| FR-011 | loot_gained signal | 1 | 1.2.6 |
| FR-012 | adventurer_recruited signal | 1 | 1.2.7 |
| FR-013 | GameManager extends Node | 2 | 2.2.1 |
| FR-014 | GameManager declares class_name | 2 | 2.2.1 |
| FR-015 | initialize() sets flag and emits signal | 2 | 2.2.5 |
| FR-016 | shutdown() clears flag and emits signal | 2 | 2.2.6 |
| FR-017 | Nullable service properties | 2 | 2.2.2 |
| FR-018 | _ready() does NOT call initialize() | 2 | 2.2.1 (no _ready) |
| FR-019 | change_scene() method with validation | 3 | 3.2.4 |
| FR-020 | ERR_FILE_NOT_FOUND for missing scene | 3 | 3.2.4 |
| FR-021 | scene_change_started/completed signals | 3 | 3.2.3 |
| FR-022 | EventBus in project.godot autoload | 3 | 3.3.1 |
| FR-023 | GameManager in project.godot autoload | 3 | 3.3.1 |
| FR-024 | EventBus before GameManager in autoload order | 3 | 3.3.2 |

### Acceptance Criteria → Validation Gates

| AC | Description | Phase | Verification |
|----|-------------|-------|--------------|
| AC-001 | autoloads dir with files | 1, 2 | 1.V.1, 2.V.1 |
| AC-002–008 | Empty dirs exist | 0 | 0.V.1 |
| AC-009 | utils dir with scene_router.gd | 3 | 3.V.1 |
| AC-010–011 | test dirs exist | 0 | Already exist |
| AC-012 | EventBus extends Node, class_name | 1 | 1.V.2 |
| AC-013 | 6 typed signals | 1 | 1.V.3 |
| AC-014 | Doc comments on signals | 1 | 1.V.4 |
| AC-015 | GameManager extends Node, class_name | 2 | 2.V.2 |
| AC-016 | initialize() | 2 | 2.V.3 |
| AC-017 | shutdown() | 2 | 2.V.4 |
| AC-018 | is_initialized() | 2 | 2.V.3 |
| AC-019 | Service properties default null | 2 | 2.V.5 |
| AC-020 | No auto-initialize in _ready() | 2 | 2.V.6 |
| AC-021 | change_scene() method | 3 | 3.V.1 |
| AC-022 | ERR_FILE_NOT_FOUND | 3 | 3.V.3 |
| AC-023 | Path prefix validation | 3 | 3.V.2 |
| AC-024 | Signals on SceneRouter | 3 | 3.V.1 |
| AC-025 | EventBus in project.godot | 3 | 3.V.4 |
| AC-026 | GameManager in project.godot | 3 | 3.V.4 |
| AC-027 | Autoload order | 3 | 3.V.5 |
| PAC-001 | Zero errors on open | 5 | 5.1.1 |
| PAC-002 | F5 runs to main menu | 5 | 5.1.2 |
| PAC-003 | Autoloads visible in Remote tree | 5 | 5.1.3 |
| PAC-004 | All GUT tests green | 4, 5 | 4.V.2, 5.3.1 |

---

*End of TASK-001 Implementation Plan*
