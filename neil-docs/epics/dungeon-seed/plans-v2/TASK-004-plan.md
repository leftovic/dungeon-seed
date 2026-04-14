# TASK-004: Seed Data Model & Maturation State Machine — Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-004-seed-data-model.md`
> **GDD**: `neil-docs/epics/dungeon-seed/GDD-v2.md`
> **Status**: Planning
> **Created**: 2025-07-19
> **Repo**: `dev-agent-tool` (local — `C:\Users\wrstl\source\dev-agent-tool`)
> **Methodology**: TDD Red-Green-Refactor (mandatory for all phases)
> **Complexity**: 8 points (Moderate) — Fibonacci
> **Estimated Phases**: 7
> **Estimated Checkboxes**: ~65

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents in this order:

1. **This file** (you're reading it) — the phased checklist of what to do, with status
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-004-seed-data-model.md`** — the full technical spec with exact code to implement
3. **`neil-docs/epics/dungeon-seed/GDD-v2.md`** — the Game Design Document for understanding domain context
4. **`src/models/enums.gd`** — Enums (SeedRarity, Element, SeedPhase) from TASK-003
5. **`src/models/game_config.gd`** — GameConfig constants (BASE_GROWTH_SECONDS, MUTATION_SLOTS, PHASE_GROWTH_MULTIPLIERS) from TASK-003

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| Enum definitions | `src/models/enums.gd` | **EXISTS** — `class_name Enums`, has SeedRarity, Element, SeedPhase |
| Game constants | `src/models/game_config.gd` | **EXISTS** — `class_name GameConfig`, has BASE_GROWTH_SECONDS, MUTATION_SLOTS, PHASE_GROWTH_MULTIPLIERS |
| Seed data model | `src/models/seed_data.gd` | **NEW** — `class_name SeedData`, extends RefCounted |
| Mutation slot model | `src/models/mutation_slot.gd` | **NEW** — `class_name MutationSlot`, extends RefCounted |
| Unit tests | `tests/unit/test_seed_data.gd` | **NEW** — GUT test suite covering both SeedData and MutationSlot |
| Autoloads | `src/autoloads/event_bus.gd`, `src/autoloads/game_manager.gd` | **EXISTS** — from TASK-001, DO NOT TOUCH |
| RNG utility | `src/models/rng.gd` | **EXISTS** — from TASK-002, not directly used by this task |
| GUT addon | `addons/gut/` | **EXISTS** — GUT test framework pre-installed |
| v1 prototype code | `src/gdscript/` | **DO NOT TOUCH** — legacy code, not part of this task |

### Key Concepts (5-minute primer)

- **SeedData**: The primary data model for a plantable seed. Extends `RefCounted`. Contains all GDD §4.1 attributes and a pull-based maturation state machine.
- **MutationSlot**: A lightweight data class representing a single reagent slot on a seed. Each slot has an index, optional reagent ID, and effect dictionary.
- **Maturation State Machine**: Four-phase progression (SPORE → SPROUT → BUD → BLOOM). Advanced externally via `advance_growth(delta_seconds)`. At most one phase per call.
- **BLOOM is terminal**: Once reached, `advance_growth()` is a no-op. Growth stops.
- **Pull-based**: The model does not use timers or signals internally. The caller (Seed Grove Manager) drives the state machine.
- **RefCounted**: Godot base class for garbage-collected objects. No scene tree dependency. Ideal for pure data models.
- **Factory method**: `SeedData.create_seed()` is the canonical constructor. Derives growth_rate, mutation_slots, dungeon_traits from rarity.
- **Serialization round-trip**: `SeedData.from_dict(seed.to_dict())` must produce a logically identical instance.
- **`class_name`**: GDScript keyword that registers a script as a globally available type. Both `seed_data.gd` and `mutation_slot.gd` use it (they are NOT autoloads — safe for `class_name`).
- **Godot 4.6.1 Rule**: DO NOT use `class_name` on autoload scripts (causes parse error). Non-autoload scripts CAN and SHOULD use `class_name`.

### Build & Verification Commands

```powershell
# There is no CLI build for GDScript — verification is done in-editor.
# However, you can verify script syntax via headless Godot:

# Open project in editor (manual)
# Press F5 to run — should launch to main_menu.tscn

# Run GUT tests from within the editor:
#   1. Open GUT panel (bottom dock)
#   2. Click "Run All" — all tests must pass green

# Verify models can be instantiated:
#   1. Open GDScript REPL or debug console
#   2. var seed = SeedData.create_seed(Enums.SeedRarity.COMMON, Enums.Element.TERRA)
#   3. print(seed.to_dict())
```

### Regression Gate

Before AND after every phase:
1. `project.godot` must be valid (opens in editor without errors)
2. Existing test files in `tests/unit/` are not broken by our changes
3. `src/models/enums.gd` and `src/models/game_config.gd` are unchanged (TASK-003 outputs)
4. `src/autoloads/event_bus.gd` and `src/autoloads/game_manager.gd` are unchanged (TASK-001 outputs)
5. All new GUT tests pass green (once written)

---

## Current State Analysis

### What Exists Today

| Item | Status | Location |
|------|--------|----------|
| `project.godot` | ✅ Exists | Root — project config with autoloads |
| `src/models/enums.gd` | ✅ Exists | TASK-003 — `class_name Enums`, SeedRarity, Element, SeedPhase, etc. |
| `src/models/game_config.gd` | ✅ Exists | TASK-003 — `class_name GameConfig`, BASE_GROWTH_SECONDS, MUTATION_SLOTS, PHASE_GROWTH_MULTIPLIERS |
| `src/autoloads/event_bus.gd` | ✅ Exists | TASK-001 — EventBus autoload |
| `src/autoloads/game_manager.gd` | ✅ Exists | TASK-001 — GameManager autoload |
| `src/models/rng.gd` | ✅ Exists | TASK-002 — RNG utility (in progress, not needed by TASK-004) |
| `addons/gut/` | ✅ Exists | GUT test framework installed |
| `tests/unit/` | ✅ Exists | Contains existing test files |
| `src/gdscript/` | ✅ Exists | v1 prototype code (DO NOT TOUCH) |

### What's Missing (Gap Analysis)

| Item | Status | Required By |
|------|--------|-------------|
| `src/models/mutation_slot.gd` | ❌ Missing | FR-014 through FR-019 |
| `src/models/seed_data.gd` | ❌ Missing | FR-001 through FR-013, FR-020 through FR-053 |
| `tests/unit/test_seed_data.gd` | ❌ Missing | Section 14 — all test functions |

### What Must NOT Change

- `src/models/enums.gd` — TASK-003 output, provides SeedRarity, Element, SeedPhase
- `src/models/game_config.gd` — TASK-003 output, provides BASE_GROWTH_SECONDS, MUTATION_SLOTS, PHASE_GROWTH_MULTIPLIERS
- `src/autoloads/event_bus.gd` — TASK-001 output, central signal bus
- `src/autoloads/game_manager.gd` — TASK-001 output, lifecycle singleton
- `src/gdscript/` — v1 prototype code, explicitly out of scope
- `project.godot` — no changes needed for this task
- Existing test files in `tests/unit/` — must not be broken

---

## Development Methodology: TDD Red-Green-Refactor

**ALL implementation work follows strict TDD.** No exceptions.

### The Cycle

1. **RED**: Write a failing test that describes the desired behavior
   - The test MUST fail initially — if it passes, you don't need the test
   - The test MUST be specific and descriptive
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
# Property defaults
func test_mutation_slot_defaults() -> void:

# Boolean methods
func test_mutation_slot_is_empty_true() -> void:

# State machine transitions
func test_spore_to_sprout_transition_common() -> void:

# Edge cases
func test_advance_growth_negative_delta_noop() -> void:

# Round-trips
func test_from_dict_round_trip_basic() -> void:
```

### Test Structure (GUT)

Every test follows Arrange-Act-Assert:
```gdscript
func test_method_scenario_expected() -> void:
    # Arrange — create instance and test data
    var seed: SeedData = SeedData.create_seed(Enums.SeedRarity.COMMON, Enums.Element.TERRA, "test_id")

    # Act — execute the behavior
    seed.plant(1000.0)
    var result: Enums.SeedPhase = seed.advance_growth(60.0)

    # Assert — verify the outcome
    assert_eq(result, Enums.SeedPhase.SPROUT)
    assert_almost_eq(seed.growth_progress, 0.0, 0.001)
```

### Coverage Requirements Per Phase

- ✅ **Existence**: Class exists, extends `RefCounted`, has `class_name`
- ✅ **Properties**: All typed properties initialized to correct defaults
- ✅ **Factory method**: `create_seed()` initializes all derived fields correctly
- ✅ **State machine**: Phase transitions, guards, single-phase-per-tick invariant
- ✅ **Planting**: Guards for already-planted, invalid timestamp
- ✅ **Serialization**: Round-trip fidelity, defensive deserialization
- ✅ **Helpers**: Duration calculations, progress tracking, slot access
- ✅ **Edge cases**: Negative delta, zero delta, huge delta, out-of-bounds index

---

## Phase 0: Pre-Flight & Dependency Verification

> **Ticket References**: FR-001, FR-014 (prerequisites)
> **AC References**: AC-001 through AC-009 (structural prerequisites)
> **Estimated Items**: 6
> **Dependencies**: TASK-003 complete (enums.gd, game_config.gd exist)
> **Validation Gate**: All TASK-003 dependencies verified, models directory ready

This phase verifies that all upstream dependencies from TASK-003 are in place and the repository is ready for implementation.

### 0.1 Verify TASK-003 Outputs

- [ ] **0.1.1** Verify `src/models/enums.gd` exists and declares `class_name Enums`
  - _Ticket ref: Assumption #1_
  - _File: `src/models/enums.gd`_
  - _Check: `Enums.SeedRarity` has COMMON, UNCOMMON, RARE, EPIC, LEGENDARY_
  - _Check: `Enums.Element` has TERRA, FLAME, FROST, ARCANE, SHADOW_
  - _Check: `Enums.SeedPhase` has SPORE, SPROUT, BUD, BLOOM_

- [ ] **0.1.2** Verify `src/models/game_config.gd` exists and declares `class_name GameConfig`
  - _Ticket ref: Assumption #1_
  - _File: `src/models/game_config.gd`_
  - _Check: `GameConfig.BASE_GROWTH_SECONDS` has entries for all 5 rarities_
  - _Check: `GameConfig.MUTATION_SLOTS` has entries for all 5 rarities_
  - _Check: `GameConfig.PHASE_GROWTH_MULTIPLIERS` has entries for SPORE, SPROUT, BUD_

- [ ] **0.1.3** Verify `addons/gut/` is installed and contains `plugin.cfg`
  - _Ticket ref: Pre-requisite for tests_

### 0.2 Verify No Conflicts

- [ ] **0.2.1** Verify `src/models/seed_data.gd` does NOT already exist (no file collision)
  - _File: `src/models/seed_data.gd`_

- [ ] **0.2.2** Verify `src/models/mutation_slot.gd` does NOT already exist (no file collision)
  - _File: `src/models/mutation_slot.gd`_

- [ ] **0.2.3** Verify no existing `class_name SeedData` or `class_name MutationSlot` in the codebase (search `src/` for conflicts)

### Phase 0 Validation Gate

- [ ] **0.V.1** All TASK-003 outputs verified present and contain expected constants
- [ ] **0.V.2** No file conflicts detected
- [ ] **0.V.3** GUT addon installed and available
- [ ] **0.V.4** Existing tests in `tests/unit/` pass (regression baseline)

---

## Phase 1: MutationSlot Model (TDD)

> **Ticket References**: FR-014 through FR-019
> **AC References**: AC-002, AC-004, AC-008, AC-009, AC-021, AC-022, AC-023, AC-067, AC-068, AC-069, AC-070
> **Estimated Items**: 8
> **Dependencies**: Phase 0 complete (dependencies verified)
> **Validation Gate**: `mutation_slot.gd` exists, extends RefCounted, has class_name, all MutationSlot tests pass

### 1.1 Write MutationSlot Tests (RED)

- [ ] **1.1.1** Create `tests/unit/test_seed_data.gd` with test helpers and MutationSlot test section
  - _Ticket ref: Section 14_
  - _File: `tests/unit/test_seed_data.gd`_
  - _Tests: `test_mutation_slot_defaults`, `test_mutation_slot_is_empty_true`, `test_mutation_slot_is_empty_false`, `test_mutation_slot_to_dict`, `test_mutation_slot_from_dict`, `test_mutation_slot_round_trip`_
  - _TDD: RED — tests reference `MutationSlot` class which does not exist yet_
  - _Note: Write the full test file header (extends GutTest, helpers) and MutationSlot section only. Remaining test sections added in later phases._

### 1.2 Implement MutationSlot (GREEN)

- [ ] **1.2.1** Create `src/models/mutation_slot.gd` with class declaration
  - _Ticket ref: FR-014_
  - _File: `src/models/mutation_slot.gd`_
  - _Content: `class_name MutationSlot` + `extends RefCounted` + class doc comment_

- [ ] **1.2.2** Add `slot_index: int`, `reagent_id: String`, `effect: Dictionary` properties with defaults
  - _Ticket ref: FR-015, FR-016, FR-017, AC-021, AC-022, AC-023_
  - _Properties: `slot_index = 0`, `reagent_id = ""`, `effect = {}`_

- [ ] **1.2.3** Add `is_empty() -> bool` method returning `reagent_id == ""`
  - _Ticket ref: FR-018, AC-067, AC-068_

- [ ] **1.2.4** Add `to_dict() -> Dictionary` serialization method
  - _Ticket ref: FR-019, AC-069_

- [ ] **1.2.5** Add `static from_dict(data: Dictionary) -> MutationSlot` deserialization method
  - _Ticket ref: FR-019, AC-070_
  - _Uses defensive `data.get()` with defaults for all fields_

> **Implementation source**: Ticket Section 16 has the complete, copy-pasteable `mutation_slot.gd`.

### Phase 1 Validation Gate

- [ ] **1.V.1** `src/models/mutation_slot.gd` exists and is parseable GDScript
- [ ] **1.V.2** File extends `RefCounted` and declares `class_name MutationSlot`
- [ ] **1.V.3** All 3 properties have type hints and default values
- [ ] **1.V.4** `is_empty()`, `to_dict()`, `from_dict()` all have `##` doc comments
- [ ] **1.V.5** All 6 MutationSlot tests pass green
- [ ] **1.V.6** No Node, SceneTree, Timer, or signal declarations in file (NFR-008, NFR-010, AC-009)
- [ ] **1.V.7** Commit: `"Phase 1: Add MutationSlot model with serialization — 6 tests"`

---

## Phase 2: SeedData Properties & Factory Method (TDD)

> **Ticket References**: FR-001 through FR-013, FR-031 through FR-036, FR-047
> **AC References**: AC-001, AC-003, AC-006, AC-007, AC-010 through AC-020, AC-036 through AC-039
> **Estimated Items**: 12
> **Dependencies**: Phase 1 complete (MutationSlot available for mutation_slots property)
> **Validation Gate**: `seed_data.gd` exists with all properties and `create_seed()` factory; construction and factory tests pass

### 2.1 Write Construction & Factory Tests (RED)

- [ ] **2.1.1** Add SeedData property test section to `tests/unit/test_seed_data.gd`
  - _Ticket ref: Section 14 — SeedData Property Tests_
  - _File: `tests/unit/test_seed_data.gd`_
  - _Tests: `test_create_seed_common_terra_properties`, `test_create_seed_common_growth_rate`, `test_create_seed_legendary_growth_rate`, `test_create_seed_common_mutation_slots_count`, `test_create_seed_legendary_mutation_slots_count`, `test_create_seed_mutation_slots_sequential_indices`, `test_create_seed_mutation_slots_initially_empty`, `test_create_seed_mutation_potential_by_rarity`, `test_create_seed_dungeon_traits_keys`, `test_create_seed_dungeon_traits_scale_with_rarity`, `test_create_seed_unique_ids`, `test_create_seed_custom_id`_
  - _TDD: RED — tests reference `SeedData` class which does not exist yet_

### 2.2 Implement SeedData Properties & Factory (GREEN)

- [ ] **2.2.1** Create `src/models/seed_data.gd` with class declaration and constants
  - _Ticket ref: FR-001, AC-001, AC-003_
  - _File: `src/models/seed_data.gd`_
  - _Content: `class_name SeedData` + `extends RefCounted` + class doc comment_
  - _Constants: `TRAIT_ROOM_VARIETY`, `TRAIT_HAZARD_FREQUENCY`, `TRAIT_LOOT_BIAS`, `MUTATION_POTENTIAL_BY_RARITY`, `LOOT_BIAS_BY_RARITY`_

- [ ] **2.2.2** Add all core properties with type hints and defaults
  - _Ticket ref: FR-002 through FR-013, AC-010 through AC-020_
  - _Properties: `id: String`, `rarity: Enums.SeedRarity`, `element: Enums.Element`, `phase: Enums.SeedPhase`, `growth_progress: float`, `growth_rate: float`, `mutation_slots: Array[MutationSlot]`, `mutation_potential: float`, `dungeon_traits: Dictionary`, `planted_at: float`, `is_planted: bool`_
  - _All properties initialized to correct defaults (phase=SPORE, growth_progress=0.0, etc.)_

- [ ] **2.2.3** Add `static generate_id() -> String` method
  - _Ticket ref: FR-047, FR-032_
  - _Uses incrementing counter + timestamp hash for uniqueness_

- [ ] **2.2.4** Add `static create_seed(p_rarity, p_element, custom_id) -> SeedData` factory method
  - _Ticket ref: FR-031 through FR-036, AC-036 through AC-039_
  - _Sets `id` from custom_id or generate_id()_
  - _Sets `growth_rate` from `GameConfig.BASE_GROWTH_SECONDS[p_rarity]`_
  - _Creates `mutation_slots` array with `GameConfig.MUTATION_SLOTS[p_rarity]` entries_
  - _Sets `mutation_potential` from `MUTATION_POTENTIAL_BY_RARITY`_
  - _Sets `dungeon_traits` with rarity-scaled values_
  - _Initializes `phase=SPORE`, `growth_progress=0.0`, `is_planted=false`_

> **Implementation source**: Ticket Section 16 has the complete `create_seed()` method.

### Phase 2 Validation Gate

- [ ] **2.V.1** `src/models/seed_data.gd` exists and is parseable GDScript
- [ ] **2.V.2** File extends `RefCounted` and declares `class_name SeedData`
- [ ] **2.V.3** All 11 properties have type hints and correct defaults
- [ ] **2.V.4** `generate_id()` returns unique non-empty strings
- [ ] **2.V.5** `create_seed()` correctly initializes all fields for all 5 rarities
- [ ] **2.V.6** All 12 construction/factory tests pass green
- [ ] **2.V.7** Commit: `"Phase 2: Add SeedData properties & create_seed() factory — 12 tests"`

---

## Phase 3: Maturation State Machine (TDD)

> **Ticket References**: FR-020 through FR-030
> **AC References**: AC-024 through AC-035
> **Estimated Items**: 10
> **Dependencies**: Phase 2 complete (SeedData exists with properties and factory)
> **Validation Gate**: `advance_growth()` implements full state machine; all state machine tests pass

### 3.1 Write State Machine Tests (RED)

- [ ] **3.1.1** Add state machine test section to `tests/unit/test_seed_data.gd`
  - _Ticket ref: Section 14 — State Machine Tests_
  - _File: `tests/unit/test_seed_data.gd`_
  - _Tests: `test_advance_growth_unplanted_noop`, `test_advance_growth_bloom_noop`, `test_advance_growth_negative_delta_noop`, `test_advance_growth_zero_delta_noop`, `test_spore_to_sprout_transition_common`, `test_sprout_to_bud_transition_common`, `test_bud_to_bloom_transition_common`, `test_full_lifecycle_common`, `test_advance_growth_at_most_one_phase_per_call`, `test_growth_progress_increments_correctly`, `test_growth_progress_resets_on_transition`, `test_many_small_deltas_sum_to_transition`, `test_legendary_spore_duration`, `test_bloom_is_truly_terminal`, `test_all_rarities_phase_durations`_
  - _TDD: RED — tests reference `advance_growth()` method which does not exist yet_

### 3.2 Implement State Machine (GREEN)

- [ ] **3.2.1** Add `advance_growth(delta_seconds: float) -> Enums.SeedPhase` method
  - _Ticket ref: FR-020 through FR-030, AC-024 through AC-035_
  - _File: `src/models/seed_data.gd`_
  - _Guard: Return phase unchanged if `is_planted == false` (FR-021, AC-024)_
  - _Guard: Return BLOOM if `phase == BLOOM` (FR-022, AC-025)_
  - _Guard: Return phase unchanged if `delta_seconds <= 0.0` (FR-029, AC-032, AC-033)_
  - _Calculate phase_duration = `growth_rate * PHASE_GROWTH_MULTIPLIERS[phase]` (FR-023)_
  - _Increment progress by `delta_seconds / phase_duration` (FR-024)_
  - _On `growth_progress >= 1.0`: transition to next phase, reset progress to 0.0 (FR-025, FR-026, AC-030)_
  - _At most one phase per call (FR-027, AC-031)_
  - _Clamp phase to not exceed BLOOM (FR-028)_

- [ ] **3.2.2** Add private helper `_next_phase(current: Enums.SeedPhase) -> Enums.SeedPhase`
  - _Ticket ref: FR-030_
  - _Returns `int(current) + 1` clamped to BLOOM_

- [ ] **3.2.3** Add private helper `_get_current_phase_duration() -> float`
  - _Returns `0.0` for BLOOM, otherwise `growth_rate * GameConfig.PHASE_GROWTH_MULTIPLIERS[phase]`_

> **Implementation source**: Ticket Section 16 has the complete `advance_growth()` implementation.

### Phase 3 Validation Gate

- [ ] **3.V.1** `advance_growth()` returns current phase for unplanted seeds
- [ ] **3.V.2** `advance_growth()` is a no-op for BLOOM phase
- [ ] **3.V.3** Phase transitions occur at correct durations for all rarities
- [ ] **3.V.4** Single-phase-per-tick invariant holds even with huge delta
- [ ] **3.V.5** Growth progress resets to 0.0 on transition
- [ ] **3.V.6** All 15 state machine tests pass green
- [ ] **3.V.7** Commit: `"Phase 3: Implement maturation state machine (SPORE→SPROUT→BUD→BLOOM) — 15 tests"`

---

## Phase 4: Planting & Helper Methods (TDD)

> **Ticket References**: FR-037 through FR-039, FR-048 through FR-053
> **AC References**: AC-040 through AC-043, AC-053 through AC-066
> **Estimated Items**: 10
> **Dependencies**: Phase 3 complete (state machine works for helper calculations)
> **Validation Gate**: `plant()` and all helper methods work correctly; all planting and helper tests pass

### 4.1 Write Planting Tests (RED)

- [ ] **4.1.1** Add planting test section to `tests/unit/test_seed_data.gd`
  - _Ticket ref: Section 14 — Planting Tests_
  - _File: `tests/unit/test_seed_data.gd`_
  - _Tests: `test_plant_sets_planted_state`, `test_plant_already_planted_is_noop`, `test_plant_zero_timestamp_is_noop`, `test_plant_negative_timestamp_is_noop`_
  - _TDD: RED — tests reference `plant()` method which does not exist yet_

### 4.2 Implement plant() Method (GREEN)

- [ ] **4.2.1** Add `plant(timestamp: float) -> void` method
  - _Ticket ref: FR-037 through FR-039, AC-040 through AC-043_
  - _File: `src/models/seed_data.gd`_
  - _Guard: Return if `is_planted == true` (FR-038, AC-041)_
  - _Guard: Return if `timestamp <= 0.0` (FR-039, AC-042, AC-043)_
  - _Sets `is_planted = true` and `planted_at = timestamp` (FR-037, AC-040)_

### 4.3 Write Helper Method Tests (RED)

- [ ] **4.3.1** Add helper method test section to `tests/unit/test_seed_data.gd`
  - _Ticket ref: Section 14 — Helper Method Tests_
  - _File: `tests/unit/test_seed_data.gd`_
  - _Tests: `test_get_phase_duration_spore_common`, `test_get_phase_duration_bloom_returns_zero`, `test_get_total_growth_time_common`, `test_get_remaining_time_fresh_spore`, `test_get_remaining_time_bloom`, `test_get_remaining_time_mid_growth`, `test_get_overall_progress_fresh_spore`, `test_get_overall_progress_bloom`, `test_get_overall_progress_midpoint`, `test_get_filled_slot_count_none_filled`, `test_get_filled_slot_count_some_filled`, `test_get_slot_valid_index`, `test_get_slot_negative_index_returns_null`, `test_get_slot_out_of_bounds_returns_null`, `test_generate_id_returns_nonempty_string`, `test_generate_id_unique`_
  - _TDD: RED — tests reference helper methods which do not exist yet_

### 4.4 Implement Helper Methods (GREEN)

- [ ] **4.4.1** Add `get_phase_duration() -> float` method
  - _Ticket ref: FR-048, AC-053, AC-054_
  - _Returns `_get_current_phase_duration()` (delegates to private helper)_
  - _Returns `0.0` for BLOOM phase_

- [ ] **4.4.2** Add `get_total_growth_time() -> float` method
  - _Ticket ref: FR-049, AC-055, AC-056_
  - _Sums `growth_rate * PHASE_GROWTH_MULTIPLIERS[p]` for SPORE, SPROUT, BUD_

- [ ] **4.4.3** Add `get_remaining_time() -> float` method
  - _Ticket ref: FR-050, AC-057, AC-058_
  - _Returns `0.0` for BLOOM_
  - _Calculates remaining in current phase + full durations of subsequent phases_

- [ ] **4.4.4** Add `get_overall_progress() -> float` method
  - _Ticket ref: FR-051, AC-059, AC-060, AC-061_
  - _Returns `1.0` for BLOOM, `0.0` for fresh SPORE_
  - _Calculates elapsed time / total time for mid-growth seeds_

- [ ] **4.4.5** Add `get_filled_slot_count() -> int` method
  - _Ticket ref: FR-052, AC-062, AC-063_
  - _Counts mutation slots where `is_empty() == false`_

- [ ] **4.4.6** Add `get_slot(index: int) -> MutationSlot` method
  - _Ticket ref: FR-053, AC-064, AC-065, AC-066_
  - _Returns `null` for out-of-bounds or negative indices_

> **Implementation source**: Ticket Section 16 has all helper method implementations.

### Phase 4 Validation Gate

- [ ] **4.V.1** `plant()` correctly guards against double-plant and invalid timestamps
- [ ] **4.V.2** `get_phase_duration()` returns correct values for all phases including BLOOM
- [ ] **4.V.3** `get_total_growth_time()` matches manual calculation for Common seed
- [ ] **4.V.4** `get_remaining_time()` returns `0.0` for BLOOM and correct values mid-growth
- [ ] **4.V.5** `get_overall_progress()` returns `0.0` at start, `1.0` at BLOOM, `~0.5` at midpoint
- [ ] **4.V.6** `get_slot()` returns `null` for invalid indices
- [ ] **4.V.7** All 20 planting + helper tests pass green
- [ ] **4.V.8** Commit: `"Phase 4: Add plant() method & helper methods — 20 tests"`

---

## Phase 5: Serialization (TDD)

> **Ticket References**: FR-040 through FR-046
> **AC References**: AC-044 through AC-052
> **Estimated Items**: 8
> **Dependencies**: Phase 4 complete (all properties and methods exist for serialization)
> **Validation Gate**: `to_dict()` and `from_dict()` produce perfect round-trips; all serialization tests pass

### 5.1 Write Serialization Tests (RED)

- [ ] **5.1.1** Add serialization test section to `tests/unit/test_seed_data.gd`
  - _Ticket ref: Section 14 — Serialization Tests_
  - _File: `tests/unit/test_seed_data.gd`_
  - _Tests: `test_to_dict_contains_all_keys`, `test_to_dict_enum_as_int`, `test_to_dict_mutation_slots_as_array`, `test_from_dict_round_trip_basic`, `test_from_dict_round_trip_dungeon_traits`, `test_from_dict_round_trip_mutation_slots`, `test_from_dict_round_trip_mid_growth`, `test_from_dict_missing_optional_keys`, `test_from_dict_invalid_phase_clamps`, `test_from_dict_excess_mutation_slots_truncated`_
  - _TDD: RED — tests reference `to_dict()` and `from_dict()` methods which do not exist yet_

### 5.2 Implement Serialization (GREEN)

- [ ] **5.2.1** Add `to_dict() -> Dictionary` method to SeedData
  - _Ticket ref: FR-040, FR-041, FR-042, AC-044, AC-045, AC-046_
  - _File: `src/models/seed_data.gd`_
  - _Serializes all 11 properties to a plain Dictionary_
  - _Enums stored as integers via `int()` cast_
  - _mutation_slots serialized as Array of `slot.to_dict()` results_
  - _dungeon_traits duplicated to prevent reference sharing_

- [ ] **5.2.2** Add `static from_dict(data: Dictionary) -> SeedData` method to SeedData
  - _Ticket ref: FR-043, FR-044, FR-045, FR-046, AC-047 through AC-052_
  - _File: `src/models/seed_data.gd`_
  - _Uses defensive `data.get("key", default)` for all fields (NFR-014)_
  - _Enum integers clamped to valid ranges before cast_
  - _growth_progress clamped to [0.0, 1.0]_
  - _mutation_slots truncated to `GameConfig.MUTATION_SLOTS[rarity]` if excess (AC-052)_
  - _mutation_slots padded with empty slots if fewer than allowed_
  - _dungeon_traits restored with required key fallbacks_
  - _Invalid phase integer clamped to valid SeedPhase range (AC-051)_

> **Implementation source**: Ticket Section 16 has the complete `to_dict()` and `from_dict()` implementations.

### Phase 5 Validation Gate

- [ ] **5.V.1** `to_dict()` returns Dictionary with all 11 expected keys
- [ ] **5.V.2** Enum values serialized as integers, not strings
- [ ] **5.V.3** Round-trip `from_dict(to_dict())` preserves all fields exactly
- [ ] **5.V.4** `from_dict()` handles missing optional keys with defaults
- [ ] **5.V.5** `from_dict()` clamps invalid phase integers to valid range
- [ ] **5.V.6** `from_dict()` truncates excess mutation slots to rarity limit
- [ ] **5.V.7** All 10 serialization tests pass green
- [ ] **5.V.8** Commit: `"Phase 5: Add to_dict()/from_dict() serialization with round-trip guarantee — 10 tests"`

---

## Phase 6: Final Validation & Cleanup

> **Ticket References**: All FRs, all ACs, NFR-001 through NFR-017
> **Estimated Items**: 12
> **Dependencies**: ALL prior phases complete
> **Validation Gate**: All ~63 tests pass, all NFRs verified, code quality clean

### 6.1 Full Test Run

- [ ] **6.1.1** Run complete GUT test suite for `tests/unit/test_seed_data.gd` — verify all ~63 tests pass
  - _Expected: ~63 pass, 0 fail, 0 error_
  - _Breakdown: ~6 MutationSlot + ~12 construction + ~15 state machine + ~20 planting/helpers + ~10 serialization_

- [ ] **6.1.2** Run all existing tests in `tests/unit/` — verify zero regressions
  - _Expected: All pre-existing tests still pass_

### 6.2 Code Quality Verification (NFRs)

- [ ] **6.2.1** All public methods in `seed_data.gd` and `mutation_slot.gd` have static type hints on parameters and return values (NFR-006, AC-006, AC-008)
- [ ] **6.2.2** All public methods have `##` doc comments describing purpose, parameters, and return value (NFR-007, AC-007)
- [ ] **6.2.3** No `Node`, `SceneTree`, `Timer`, or `signal` declarations in either model file (NFR-008, NFR-010, AC-009)
- [ ] **6.2.4** No magic numbers — all values reference `GameConfig` constants (NFR-011)
- [ ] **6.2.5** File names are snake_case: `seed_data.gd`, `mutation_slot.gd` (NFR-012)
- [ ] **6.2.6** `to_dict()` output is JSON-serializable — no Godot-specific types (NFR-013)
- [ ] **6.2.7** `from_dict()` handles missing optional keys with defaults (NFR-014)
- [ ] **6.2.8** State machine is deterministic — same input always produces same output (NFR-015)
- [ ] **6.2.9** Both files use `class_name` (safe — not autoloads)

### 6.3 Performance Spot Checks

- [ ] **6.3.1** Verify `create_seed()` completes quickly (no blocking operations) (NFR-001)
- [ ] **6.3.2** Verify `advance_growth()` has no allocations in hot path (NFR-002)
- [ ] **6.3.3** Verify single `SeedData` instance is lightweight (properties + slots only) (NFR-005)

### Phase 6 Validation Gate

- [ ] **6.V.1** All ~63 tests pass green across all sections
- [ ] **6.V.2** Zero existing tests broken
- [ ] **6.V.3** All NFRs verified
- [ ] **6.V.4** All ACs verified
- [ ] **6.V.5** Commit: `"TASK-004 complete: Seed Data Model & Maturation State Machine — ~63 tests, all green"`

---

## Phase Dependency Graph

```
Phase 0 (Pre-flight & verification)
  │
  ▼
Phase 1 (MutationSlot model — TDD)
  │
  ▼
Phase 2 (SeedData properties & factory — TDD)
  │
  ▼
Phase 3 (Maturation state machine — TDD)
  │
  ▼
Phase 4 (Planting & helper methods — TDD)
  │
  ▼
Phase 5 (Serialization — TDD)
  │
  ▼
Phase 6 (Final validation & cleanup)
```

**Parallelism note**: This task is strictly sequential. Each phase depends on the previous phase's output. MutationSlot must exist before SeedData (which references it). The state machine must exist before helpers (which depend on phase logic). Serialization must come last (it serializes all fields).

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 0 | Pre-flight & dependency verification | 6 | 0 | 0 | ⬜ Not Started |
| Phase 1 | MutationSlot model (TDD) | 8 | 0 | 6 | ⬜ Not Started |
| Phase 2 | SeedData properties & factory (TDD) | 12 | 0 | 12 | ⬜ Not Started |
| Phase 3 | Maturation state machine (TDD) | 10 | 0 | 15 | ⬜ Not Started |
| Phase 4 | Planting & helper methods (TDD) | 10 | 0 | 20 | ⬜ Not Started |
| Phase 5 | Serialization (TDD) | 8 | 0 | 10 | ⬜ Not Started |
| Phase 6 | Final validation & cleanup | 12 | 0 | ~63 | ⬜ Not Started |
| **Total** | | **~66** | **0** | **~63** | **⬜ Phase 0 Next** |

---

## File Change Summary

### New Files

| File | Phase | Purpose |
|------|-------|---------|
| `src/models/mutation_slot.gd` | 1 | MutationSlot data class — reagent slot model |
| `src/models/seed_data.gd` | 2–5 | SeedData primary model — seed properties, state machine, factory, serialization |
| `tests/unit/test_seed_data.gd` | 1–5 | ~63 unit tests covering MutationSlot and SeedData |

### Modified Files

None — this task is purely additive.

### Deleted Files

None — this task is additive only.

---

## Commit Strategy

| Phase | Commit Message | Tests After |
|-------|----------------|-------------|
| 0 | _(no commit — verification only)_ | 0 (baseline check) |
| 1 | `"Phase 1: Add MutationSlot model with serialization — 6 tests"` | 6 |
| 2 | `"Phase 2: Add SeedData properties & create_seed() factory — 12 tests"` | 18 |
| 3 | `"Phase 3: Implement maturation state machine (SPORE→SPROUT→BUD→BLOOM) — 15 tests"` | 33 |
| 4 | `"Phase 4: Add plant() method & helper methods — 20 tests"` | 53 |
| 5 | `"Phase 5: Add to_dict()/from_dict() serialization with round-trip guarantee — 10 tests"` | 63 |
| 6 | `"TASK-004 complete: Seed Data Model & Maturation State Machine — ~63 tests, all green"` | ~63 ✅ |

---

## Deviation Tracking

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| DEV-001 | All | PHASE_GROWTH_MULTIPLIERS values differ from ticket Section 8.1 narrative | Section 8.1 vs actual `game_config.gd` | Ticket narrative describes multipliers as `{SPORE:1.0, SPROUT:1.2, BUD:1.5}` but actual `game_config.gd` from TASK-003 has `{SPORE:1.0, SPROUT:0.9, BUD:0.75, BLOOM:0.5}`. The test code dynamically reads from `GameConfig`, so tests still pass — but the assertion MESSAGE strings (e.g., "60*(1.0+1.2+1.5)=222.0") may be misleading. The math is correct because tests use `GameConfig.PHASE_GROWTH_MULTIPLIERS[phase]` in assertions, not hardcoded values. | Low — tests pass correctly. Documentation/comments referencing specific multiplier values (1.2, 1.5) should note they reflect designer intent, not actual config. Actual values are read from `GameConfig` at runtime. |

> **Note**: The existing `src/gdscript/seeds/seed.gd` (`class_name Seed`) from the v1 prototype is superseded by `SeedData`. No migration needed — the old class has no persistent save data (Assumption #10 in ticket).

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| TASK-003 not merged — `Enums` or `GameConfig` missing | Low | Critical | Phase 0 verifies all TASK-003 outputs exist before writing any code. Block until resolved. | 0 |
| `GameConfig.PHASE_GROWTH_MULTIPLIERS` keys don't match expected SeedPhase enum values | Low | High | Phase 0 verifies key presence. Test code uses dynamic config reads, not hardcoded values. | 0 |
| `class_name SeedData` conflicts with existing v1 `class_name Seed` in `src/gdscript/` | Low | Medium | Verify no `class_name SeedData` exists in codebase before creating. `SeedData` is a different name from `Seed`. | 0 |
| Existing test file `tests/unit/test_seed_data.gd` already exists (name collision) | Low | Low | Phase 0 verifies file does not exist. If it does, rename existing or use alternate name. | 0 |
| `Array[MutationSlot]` typed array not supported in Godot 4.6.1 | Very Low | Medium | If unsupported, fall back to untyped `Array` with manual validation. Document as deviation. | 1 |
| Floating-point precision causes phase transitions to fire slightly early/late | Low | Low | Use `clampf()` for growth_progress. Tests use `assert_almost_eq` with tolerance. IEEE 754 float64 is sufficient. | 3 |
| `from_dict()` crashes on unexpected data types in save files | Medium | Medium | Defensive `data.get()` with defaults. Type casts with `as`. Tested with missing/invalid keys in Phase 5. | 5 |
| PHASE_GROWTH_MULTIPLIERS deviation causes test assertion message confusion | High | Low | Document in DEV-001. Tests use dynamic reads from GameConfig — assertions are correct, only message strings may be misleading. | All |

---

## Handoff State (2025-07-19)

### What's Complete
- Implementation plan written and ready for execution

### What's In Progress
- Nothing — plan is at Phase 0 (not started)

### What's Blocked
- Nothing — TASK-003 (Enums & Constants) is complete. TASK-002 (RNG) is in progress but not needed by this task.

### Next Steps
1. Execute Phase 0: Verify TASK-003 dependencies (enums.gd, game_config.gd, GUT)
2. Execute Phase 1: Write MutationSlot tests (RED), then implement MutationSlot (GREEN)
3. Execute Phase 2: Write SeedData property/factory tests (RED), then implement SeedData core (GREEN)
4. Execute Phase 3: Write state machine tests (RED), implement advance_growth() (GREEN)
5. Execute Phase 4: Write planting/helper tests (RED), implement plant() and helpers (GREEN)
6. Execute Phase 5: Write serialization tests (RED), implement to_dict()/from_dict() (GREEN)
7. Execute Phase 6: Full validation, NFR checks, final commit

---

## Ticket FR/AC Coverage Matrix

Every Functional Requirement and Acceptance Criterion from the ticket is mapped below.

### Functional Requirements → Phase Items

| FR | Description | Phase | Checkbox |
|----|-------------|-------|----------|
| FR-001 | SeedData class_name + extends RefCounted | 2 | 2.2.1 |
| FR-002 | id: String property | 2 | 2.2.2 |
| FR-003 | rarity: Enums.SeedRarity property | 2 | 2.2.2 |
| FR-004 | element: Enums.Element property | 2 | 2.2.2 |
| FR-005 | phase: Enums.SeedPhase = SPORE | 2 | 2.2.2 |
| FR-006 | growth_progress: float = 0.0 | 2 | 2.2.2 |
| FR-007 | growth_rate: float property | 2 | 2.2.2 |
| FR-008 | growth_rate from GameConfig.BASE_GROWTH_SECONDS | 2 | 2.2.4 |
| FR-009 | mutation_slots: Array[MutationSlot] | 2 | 2.2.4 |
| FR-010 | mutation_potential: float | 2 | 2.2.2 |
| FR-011 | dungeon_traits: Dictionary | 2 | 2.2.4 |
| FR-012 | planted_at: float = 0.0 | 2 | 2.2.2 |
| FR-013 | is_planted: bool = false | 2 | 2.2.2 |
| FR-014 | MutationSlot class_name + extends RefCounted | 1 | 1.2.1 |
| FR-015 | slot_index: int property | 1 | 1.2.2 |
| FR-016 | reagent_id: String = "" | 1 | 1.2.2 |
| FR-017 | effect: Dictionary = {} | 1 | 1.2.2 |
| FR-018 | is_empty() -> bool | 1 | 1.2.3 |
| FR-019 | to_dict()/from_dict() on MutationSlot | 1 | 1.2.4, 1.2.5 |
| FR-020 | advance_growth() method | 3 | 3.2.1 |
| FR-021 | Guard: unplanted returns phase | 3 | 3.2.1 |
| FR-022 | Guard: BLOOM returns BLOOM | 3 | 3.2.1 |
| FR-023 | Phase duration = growth_rate * multiplier | 3 | 3.2.1 |
| FR-024 | Increment progress by delta/duration | 3 | 3.2.1 |
| FR-025 | Phase transition on progress >= 1.0 | 3 | 3.2.1 |
| FR-026 | Reset progress on transition | 3 | 3.2.1 |
| FR-027 | At most one phase per call | 3 | 3.2.1 |
| FR-028 | Phase clamped to BLOOM max | 3 | 3.2.1 |
| FR-029 | Guard: negative delta is no-op | 3 | 3.2.1 |
| FR-030 | Phase order: SPORE→SPROUT→BUD→BLOOM | 3 | 3.2.2 |
| FR-031 | create_seed() static factory | 2 | 2.2.4 |
| FR-032 | generate_id() for auto ID | 2 | 2.2.3, 2.2.4 |
| FR-033 | growth_rate from GameConfig | 2 | 2.2.4 |
| FR-034 | Mutation slot count from GameConfig | 2 | 2.2.4 |
| FR-035 | dungeon_traits scaled by rarity | 2 | 2.2.4 |
| FR-036 | mutation_potential scaled by rarity | 2 | 2.2.4 |
| FR-037 | plant() sets is_planted and planted_at | 4 | 4.2.1 |
| FR-038 | plant() no-op if already planted | 4 | 4.2.1 |
| FR-039 | plant() no-op if invalid timestamp | 4 | 4.2.1 |
| FR-040 | to_dict() on SeedData | 5 | 5.2.1 |
| FR-041 | Enums as integers in to_dict() | 5 | 5.2.1 |
| FR-042 | mutation_slots as Array in to_dict() | 5 | 5.2.1 |
| FR-043 | from_dict() on SeedData | 5 | 5.2.2 |
| FR-044 | Restore enums from integers | 5 | 5.2.2 |
| FR-045 | Restore mutation_slots from array | 5 | 5.2.2 |
| FR-046 | Round-trip guarantee | 5 | 5.2.1, 5.2.2 |
| FR-047 | generate_id() static method | 2 | 2.2.3 |
| FR-048 | get_phase_duration() | 4 | 4.4.1 |
| FR-049 | get_total_growth_time() | 4 | 4.4.2 |
| FR-050 | get_remaining_time() | 4 | 4.4.3 |
| FR-051 | get_overall_progress() | 4 | 4.4.4 |
| FR-052 | get_filled_slot_count() | 4 | 4.4.5 |
| FR-053 | get_slot(index) | 4 | 4.4.6 |

### Acceptance Criteria → Validation Gates

| AC | Description | Phase | Verification |
|----|-------------|-------|--------------|
| AC-001 | seed_data.gd exists, class_name SeedData | 2 | 2.V.1, 2.V.2 |
| AC-002 | mutation_slot.gd exists, class_name MutationSlot | 1 | 1.V.1, 1.V.2 |
| AC-003 | SeedData extends RefCounted | 2 | 2.V.2 |
| AC-004 | MutationSlot extends RefCounted | 1 | 1.V.2 |
| AC-005 | test_seed_data.gd exists, extends GutTest | 1 | 1.1.1 |
| AC-006 | All SeedData public methods have type hints | 6 | 6.2.1 |
| AC-007 | All SeedData public methods have doc comments | 6 | 6.2.2 |
| AC-008 | All MutationSlot public methods have type hints | 6 | 6.2.1 |
| AC-009 | No Node/SceneTree/Timer/signal in models | 6 | 6.2.3 |
| AC-010 | id is String | 2 | Unit test |
| AC-011 | rarity is Enums.SeedRarity | 2 | Unit test |
| AC-012 | element is Enums.Element | 2 | Unit test |
| AC-013 | phase is Enums.SeedPhase, defaults SPORE | 2 | Unit test |
| AC-014 | growth_progress defaults 0.0 | 2 | Unit test |
| AC-015 | growth_rate from GameConfig | 2 | Unit test |
| AC-016 | mutation_slots correct count | 2 | Unit test |
| AC-017 | mutation_potential in [0.0, 1.0] | 2 | Unit test |
| AC-018 | dungeon_traits has 3 required keys | 2 | Unit test |
| AC-019 | planted_at defaults 0.0 | 2 | Unit test |
| AC-020 | is_planted defaults false | 2 | Unit test |
| AC-021 | slot_index is int | 1 | Unit test |
| AC-022 | reagent_id defaults "" | 1 | Unit test |
| AC-023 | effect defaults {} | 1 | Unit test |
| AC-024 | advance_growth unplanted no-op | 3 | 3.V.1, Unit test |
| AC-025 | advance_growth BLOOM no-op | 3 | 3.V.2, Unit test |
| AC-026 | SPORE→SPROUT at correct duration | 3 | Unit test |
| AC-027 | SPROUT→BUD at correct duration | 3 | Unit test |
| AC-028 | BUD→BLOOM at correct duration | 3 | Unit test |
| AC-029 | BLOOM is terminal | 3 | Unit test |
| AC-030 | Progress resets on transition | 3 | 3.V.5, Unit test |
| AC-031 | At most one phase per call | 3 | 3.V.4, Unit test |
| AC-032 | Negative delta no-op | 3 | Unit test |
| AC-033 | Zero delta no-op | 3 | Unit test |
| AC-034 | Many small deltas sum to transition | 3 | Unit test |
| AC-035 | Legendary phase durations correct | 3 | Unit test |
| AC-036 | create_seed COMMON TERRA properties | 2 | Unit test |
| AC-037 | create_seed LEGENDARY 5 slots, 1200.0 rate | 2 | Unit test |
| AC-038 | Unique auto-generated IDs | 2 | Unit test |
| AC-039 | Custom ID respected | 2 | Unit test |
| AC-040 | plant() sets state | 4 | Unit test |
| AC-041 | Double plant no-op | 4 | Unit test |
| AC-042 | plant(0.0) no-op | 4 | Unit test |
| AC-043 | plant(-5.0) no-op | 4 | Unit test |
| AC-044 | to_dict contains all keys | 5 | Unit test |
| AC-045 | Enums as integers | 5 | Unit test |
| AC-046 | mutation_slots as Array | 5 | Unit test |
| AC-047 | Round-trip basic fields | 5 | Unit test |
| AC-048 | Round-trip dungeon_traits | 5 | Unit test |
| AC-049 | Round-trip mutation_slots | 5 | Unit test |
| AC-050 | Missing optional keys use defaults | 5 | Unit test |
| AC-051 | Invalid phase clamped | 5 | Unit test |
| AC-052 | Excess mutation slots truncated | 5 | Unit test |
| AC-053 | get_phase_duration non-BLOOM | 4 | Unit test |
| AC-054 | get_phase_duration BLOOM = 0.0 | 4 | Unit test |
| AC-055 | get_total_growth_time formula | 4 | Unit test |
| AC-056 | get_total_growth_time Common value | 4 | Unit test |
| AC-057 | get_remaining_time fresh SPORE | 4 | Unit test |
| AC-058 | get_remaining_time BLOOM = 0.0 | 4 | Unit test |
| AC-059 | get_overall_progress fresh = 0.0 | 4 | Unit test |
| AC-060 | get_overall_progress BLOOM = 1.0 | 4 | Unit test |
| AC-061 | get_overall_progress midpoint ~0.5 | 4 | Unit test |
| AC-062 | get_filled_slot_count empty = 0 | 4 | Unit test |
| AC-063 | get_filled_slot_count correct after fill | 4 | Unit test |
| AC-064 | get_slot(0) valid | 4 | Unit test |
| AC-065 | get_slot(-1) null | 4 | Unit test |
| AC-066 | get_slot(999) null | 4 | Unit test |
| AC-067 | is_empty() true when no reagent | 1 | Unit test |
| AC-068 | is_empty() false with reagent | 1 | Unit test |
| AC-069 | MutationSlot to_dict format | 1 | Unit test |
| AC-070 | MutationSlot round-trip | 1 | Unit test |

---

*End of TASK-004 Implementation Plan*
