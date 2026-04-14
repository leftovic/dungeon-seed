# TASK-012: Seed Grove Manager — Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-012-seed-grove-manager.md`
> **GDD**: `neil-docs/epics/dungeon-seed/GDD-v2.md`
> **Status**: Planning
> **Created**: 2025-01-20
> **Repo**: `dev-agent-tool` (local — `C:\Users\wrstl\source\dev-agent-tool`)
> **Methodology**: TDD Red-Green-Refactor (mandatory for all phases)
> **Complexity**: 8 points (Moderate) — Fibonacci
> **Estimated Phases**: 8
> **Estimated Checkboxes**: ~85

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents in this order:

1. **This file** (you're reading it) — the phased checklist of what to do, with status
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-012-seed-grove-manager.md`** — the full technical spec with exact code to implement
3. **`neil-docs/epics/dungeon-seed/GDD-v2.md`** — the Game Design Document for understanding domain context
4. **`src/models/seed_data.gd`** — SeedData model (TASK-004)
5. **`src/models/mutation_slot.gd`** — MutationSlot model (TASK-004)
6. **`src/models/enums.gd`** — Enums (SeedRarity, Element, SeedPhase) from TASK-003
7. **`src/models/game_config.gd`** — GameConfig constants from TASK-003
8. **`src/autoloads/event_bus.gd`** — EventBus signal definitions from TASK-001

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| Seed Grove Manager | `src/managers/seed_grove.gd` | **NEW** — `class_name SeedGrove`, extends `Node` |
| Test suite | `tests/managers/test_seed_grove.gd` | **NEW** — GUT test suite |
| SeedData model | `src/models/seed_data.gd` | **EXISTS** — TASK-004, `class_name SeedData` |
| MutationSlot model | `src/models/mutation_slot.gd` | **EXISTS** — TASK-004, `class_name MutationSlot` |
| Enum definitions | `src/models/enums.gd` | **EXISTS** — TASK-003, `class_name Enums` |
| Game constants | `src/models/game_config.gd` | **EXISTS** — TASK-003, `class_name GameConfig` |
| EventBus | `src/autoloads/event_bus.gd` | **EXISTS** — TASK-001, autoload (NO class_name) |
| RNG utility | `src/models/rng.gd` | **EXISTS** — TASK-002, `class_name DeterministicRNG` |
| Managers directory | `src/managers/` | **MAY NOT EXIST** — create if needed |
| Tests/managers directory | `tests/managers/` | **MAY NOT EXIST** — create if needed |

### Key Concepts (5-minute primer)

- **SeedGrove**: The single source of truth for all seed state. Manages planting, growth, mutation, and queries. Extends `Node` (not RefCounted) for scene tree integration.
- **Planted vs Unplanted**: Seeds in `seeds` array are either planted (actively growing) or unplanted (inventory). Only planted seeds grow during `tick()`.
- **Grove Slots**: Limited number of concurrent planted seeds (`max_grove_slots`, default 3). Full grove blocks new planting.
- **Growth Tick**: `tick(delta)` advances all planted seeds by delta seconds, triggers phase transitions, performs mutation rolls, emits signals.
- **Phase Transitions**: SPORE → SPROUT → BUD → BLOOM. Each transition triggers mutation roll and signal emission.
- **Mutation Roll**: On phase change, roll `rng.randf() < seed.mutation_potential`. Success modifies `dungeon_traits`.
- **Reagent Application**: Fills first empty MutationSlot with reagent ID and applies effect Dictionary to `dungeon_traits`.
- **Expedition Readiness**: Seeds at SPROUT, BUD, or BLOOM can be sent on expeditions. SPORE cannot.
- **Offline Growth**: Large `delta` (e.g., 28800s = 8 hours) processes all missed growth in one `tick()` call.
- **Determinism**: ALL randomness uses `DeterministicRNG`. No global `randf()` or `randi()`.
- **Signal-Only Communication**: SeedGrove emits EventBus signals for state changes. Never calls UI/audio directly.
- **Uproot Penalty**: Uprooting resets seed to SPORE with 0% progress. Seed remains in grove inventory.
- **Serialization**: `serialize()` → Dictionary for save, `deserialize()` restores state with validation.

### Build & Verification Commands

```powershell
# Run GUT tests (headless CLI)
& "C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --path "C:\Users\wrstl\source\dev-agent-tool" --headless -s "res://addons/gut/gut_cmdln.gd" -gdir="res://tests/" -ginclude_subdirs

# Run tests for this specific file only
& "C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --path "C:\Users\wrstl\source\dev-agent-tool" --headless -s "res://addons/gut/gut_cmdln.gd" -gfile="res://tests/managers/test_seed_grove.gd"

# Open in editor to verify script parsing
# (Manual step — open project in Godot editor, check for parse errors)
```

### Regression Gate

Before AND after every phase:
1. `project.godot` must be valid (opens in editor without errors)
2. Existing test files in `tests/` are not broken by our changes
3. `src/models/seed_data.gd` is unchanged (TASK-004 output)
4. `src/models/mutation_slot.gd` is unchanged (TASK-004 output)
5. `src/models/enums.gd` is unchanged (TASK-003 output)
6. `src/models/game_config.gd` is unchanged (TASK-003 output)
7. `src/autoloads/event_bus.gd` is unchanged (TASK-001 output)
8. All new GUT tests pass green (once written)

---

## Current State Analysis

### What Exists Today

| Item | Status | Location |
|------|--------|----------|
| `project.godot` | ✅ Exists | Root — project config with autoloads |
| `src/models/seed_data.gd` | ✅ Exists | TASK-004 — `class_name SeedData`, state machine, serialization |
| `src/models/mutation_slot.gd` | ✅ Exists | TASK-004 — `class_name MutationSlot` |
| `src/models/enums.gd` | ✅ Exists | TASK-003 — `class_name Enums`, SeedRarity, Element, SeedPhase |
| `src/models/game_config.gd` | ✅ Exists | TASK-003 — GameConfig constants |
| `src/autoloads/event_bus.gd` | ✅ Exists | TASK-001 — EventBus autoload with signals |
| `src/models/rng.gd` | ✅ Exists | TASK-002 — `class_name DeterministicRNG` |
| `addons/gut/` | ✅ Exists | GUT test framework installed |
| `tests/` | ✅ Exists | Tests directory |

### What's Missing (Gap Analysis)

| Item | Status | Required By |
|------|--------|-------------|
| `src/managers/` directory | ❓ May not exist | Phase 0 |
| `tests/managers/` directory | ❓ May not exist | Phase 0 |
| `src/managers/seed_grove.gd` | ❌ Missing | FR-001 through FR-086 |
| `tests/managers/test_seed_grove.gd` | ❌ Missing | Section 14 — all test functions |

### What Must NOT Change

- `src/models/seed_data.gd` — TASK-004 output, provides SeedData model
- `src/models/mutation_slot.gd` — TASK-004 output, provides MutationSlot model
- `src/models/enums.gd` — TASK-003 output, provides enums
- `src/models/game_config.gd` — TASK-003 output, provides config constants
- `src/autoloads/event_bus.gd` — TASK-001 output, central signal bus
- `src/models/rng.gd` — TASK-002 output, RNG utility
- `project.godot` — no changes needed for this task
- Existing test files in `tests/` — must not be broken

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
# Success path
func test_plant_seed_success() -> void:

# Failure/error path
func test_plant_seed_full_grove_returns_false() -> void:

# State verification
func test_tick_advances_planted_seeds() -> void:

# Signal emission
func test_plant_seed_emits_signal() -> void:
```

### Test Structure (GUT)

Every test follows Arrange-Act-Assert:

```gdscript
func test_plant_seed_success() -> void:
	# Arrange — set up test data
	var seed := _make_seed("plant-ok")
	grove.add_seed(seed)
	
	# Act — execute the method being tested
	var result := grove.plant_seed(seed)
	
	# Assert — verify the outcome
	assert_true(result, "plant_seed should return true on success")
	assert_true(seed.is_planted, "Seed should be marked as planted")
	assert_eq(grove.planted_count, 1, "Planted count should be 1")
```

### Enterprise Coverage Standards

Every public method must have tests covering:
- ✅ Happy path (normal input → expected output)
- ✅ Edge cases (empty, boundary values)
- ✅ Error cases (invalid input → graceful handling)
- ✅ Integration (methods working together)

Minimum coverage per method:
- **Happy path**: Normal inputs produce correct outputs
- **Null/Invalid**: Bad inputs return safe defaults (null, false, empty)
- **Boundary**: Full grove, empty grove, zero delta, large delta
- **State consistency**: Planted count matches array filter, etc.

---

## Phase 0: Setup and Scaffolding

> **Ticket References**: Infrastructure setup, no direct FR mapping
> **Estimated Items**: 8
> **Dependencies**: None
> **Validation Gate**: Directories exist, empty files compile

### 0.1 Create Directory Structure

- [ ] **0.1.1** Create `src/managers/` directory if it doesn't exist
  - _File: Create directory via tool or manually_
- [ ] **0.1.2** Create `tests/managers/` directory if it doesn't exist
  - _File: Create directory via tool or manually_

### 0.2 Create Stub Files

- [ ] **0.2.1** Create `src/managers/seed_grove.gd` with minimal stub (extends Node, class_name SeedGrove)
  - _File: `src/managers/seed_grove.gd`_
  - _Content: Basic file header, class_name, extends Node_
- [ ] **0.2.2** Create `tests/managers/test_seed_grove.gd` with minimal stub (extends GutTest)
  - _File: `tests/managers/test_seed_grove.gd`_
  - _Content: File header, extends GutTest, empty before_each()_

### 0.3 Verify Compilation

- [ ] **0.3.1** Open project in Godot editor — verify no parse errors
  - _Validation: Project loads without errors_
- [ ] **0.3.2** Run GUT test suite — verify new test file is discovered
  - _Command: Full test run_
  - _Expected: 0 tests in test_seed_grove.gd, no errors_

### Phase 0 Validation Gate

- [ ] **0.V.1** `src/managers/seed_grove.gd` exists and compiles
- [ ] **0.V.2** `tests/managers/test_seed_grove.gd` exists and is discovered by GUT
- [ ] **0.V.3** No new errors in project
- [ ] **0.V.4** Commit: `"Phase 0: Setup TASK-012 directories and stub files — 0 tests pass"`

---

## Phase 1: Core Properties and Inventory Management

> **Ticket References**: FR-001 through FR-006 (Inventory), AC file structure
> **Estimated Items**: 16
> **Dependencies**: Phase 0 complete
> **Validation Gate**: Inventory tests pass, properties exist

### 1.1 Properties Declaration

- [ ] **1.1.1** Add `seeds: Array[SeedData]` property with `= []` initialization
  - _Ticket ref: FR-001_
  - _File: `src/managers/seed_grove.gd`_
  - _TDD: Will be validated by inventory tests_
- [ ] **1.1.2** Add `max_grove_slots: int = 3` property
  - _Ticket ref: FR-001, Section 8.3_
  - _File: `src/managers/seed_grove.gd`_
- [ ] **1.1.3** Add `rng: DeterministicRNG` property (no default — dependency injection)
  - _Ticket ref: FR-070, NFR-007, NFR-011_
  - _File: `src/managers/seed_grove.gd`_

### 1.2 Computed Property: planted_count

- [ ] **1.2.1** RED: Write test `test_planted_count_zero_initially()`
  - _Ticket ref: FR-022_
  - _File: `tests/managers/test_seed_grove.gd`_
  - _Expected failure: planted_count property doesn't exist_
- [ ] **1.2.2** GREEN: Implement `planted_count` computed property using `get()` accessor
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: `return get_planted_seeds().size()`_
- [ ] **1.2.3** Run tests — verify `test_planted_count_zero_initially()` passes

### 1.3 Test Helper: _make_seed()

- [ ] **1.3.1** Add `_make_seed()` helper function to test file
  - _Ticket ref: Section 14.1 test helper code_
  - _File: `tests/managers/test_seed_grove.gd`_
  - _Purpose: Create test seeds without calling SeedData.create_seed()_

### 1.4 Inventory: add_seed()

- [ ] **1.4.1** RED: Write test `test_add_seed_increases_count()`
  - _Ticket ref: FR-002, FR-005_
  - _File: `tests/managers/test_seed_grove.gd`_
  - _Expected failure: add_seed() method doesn't exist_
- [ ] **1.4.2** RED: Write test `test_add_multiple_seeds()`
  - _Ticket ref: FR-002_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **1.4.3** GREEN: Implement `add_seed(seed: SeedData) -> void`
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: `seeds.append(seed)`_
- [ ] **1.4.4** Run tests — verify add_seed tests pass

### 1.5 Inventory: get_seed_by_id()

- [ ] **1.5.1** RED: Write test `test_get_seed_by_id_found()`
  - _Ticket ref: FR-004_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **1.5.2** RED: Write test `test_get_seed_by_id_not_found()`
  - _Ticket ref: FR-004, NFR-014_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **1.5.3** GREEN: Implement `get_seed_by_id(seed_id: String) -> SeedData`
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Loop through seeds, return match or null_
- [ ] **1.5.4** Run tests — verify get_seed_by_id tests pass

### 1.6 Inventory: remove_seed()

- [ ] **1.6.1** RED: Write test `test_remove_seed_returns_seed()`
  - _Ticket ref: FR-003_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **1.6.2** RED: Write test `test_remove_seed_not_found_returns_null()`
  - _Ticket ref: FR-003, NFR-014_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **1.6.3** GREEN: Implement `remove_seed(seed_id: String) -> SeedData` (stub — no uproot yet)
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Find seed, erase from array, return seed or null_
  - _Note: Uproot behavior added in Phase 2_
- [ ] **1.6.4** Run tests — verify remove_seed tests pass

### 1.7 Inventory: get_seed_count()

- [ ] **1.7.1** RED: Write test for `get_seed_count()` (implicit in add/remove tests)
  - _Ticket ref: FR-005_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **1.7.2** GREEN: Implement `get_seed_count() -> int`
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: `return seeds.size()`_

### Phase 1 Validation Gate

- [ ] **1.V.1** All inventory tests pass (add, remove, get_by_id, get_count)
- [ ] **1.V.2** Build succeeds: project opens in editor without errors
- [ ] **1.V.3** `planted_count` property exists and returns 0 initially
- [ ] **1.V.4** Commit: `"Phase 1: SeedGrove inventory management — 8 tests pass"`

---

## Phase 2: Planting and Uprooting

> **Ticket References**: FR-010 through FR-023 (Planting/Uprooting), AC 13.3, AC 13.4
> **Estimated Items**: 20
> **Dependencies**: Phase 1 complete
> **Validation Gate**: All planting/uprooting tests pass, signals emitted

### 2.1 Query: get_planted_seeds()

- [ ] **2.1.1** RED: Write test `test_get_planted_seeds()`
  - _Ticket ref: FR-021_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **2.1.2** GREEN: Implement `get_planted_seeds() -> Array[SeedData]`
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Filter seeds where `is_planted == true`_
- [ ] **2.1.3** Run test — verify get_planted_seeds test passes

### 2.2 Query: get_unplanted_seeds()

- [ ] **2.2.1** RED: Write test `test_get_unplanted_seeds()`
  - _Ticket ref: FR-006_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **2.2.2** GREEN: Implement `get_unplanted_seeds() -> Array[SeedData]`
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Filter seeds where `is_planted == false`_
- [ ] **2.2.3** Run test — verify get_unplanted_seeds test passes

### 2.3 Query: get_available_slots()

- [ ] **2.3.1** RED: Write test `test_get_available_slots()`
  - _Ticket ref: FR-023_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **2.3.2** GREEN: Implement `get_available_slots() -> int`
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: `return max_grove_slots - planted_count`_
- [ ] **2.3.3** Run test — verify get_available_slots test passes

### 2.4 Planting: plant_seed() — Success Path

- [ ] **2.4.1** RED: Write test `test_plant_seed_success()`
  - _Ticket ref: FR-013, FR-016_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **2.4.2** RED: Write test `test_plant_seed_sets_phase_to_spore()`
  - _Ticket ref: FR-014_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **2.4.3** GREEN: Implement `plant_seed(seed: SeedData) -> bool` (success path only)
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Set is_planted, planted_at, phase=SPORE, return true_
  - _Note: Guard clauses added in next steps_
- [ ] **2.4.4** Run tests — verify success path tests pass

### 2.5 Planting: plant_seed() — Guard Clauses

- [ ] **2.5.1** RED: Write test `test_plant_seed_full_grove_returns_false()`
  - _Ticket ref: FR-010_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **2.5.2** RED: Write test `test_plant_already_planted_returns_false()`
  - _Ticket ref: FR-011_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **2.5.3** RED: Write test `test_plant_foreign_seed_returns_false()`
  - _Ticket ref: FR-012_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **2.5.4** GREEN: Add guard clauses to `plant_seed()`
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Check slots full, already planted, not in grove array_
- [ ] **2.5.5** Run tests — verify all guard clause tests pass

### 2.6 Planting: Signal Emission

- [ ] **2.6.1** RED: Write test `test_plant_seed_emits_signal()`
  - _Ticket ref: FR-015_
  - _File: `tests/managers/test_seed_grove.gd`_
  - _GUT: Use `watch_signals(EventBus)` and `assert_signal_emitted()`_
- [ ] **2.6.2** GREEN: Add `EventBus.seed_planted.emit(seed.id, slot_index)` to plant_seed()
  - _File: `src/managers/seed_grove.gd`_
  - _Note: slot_index = current planted_count (0-indexed before increment)_
- [ ] **2.6.3** Run test — verify signal emission test passes

### 2.7 Uprooting: uproot_seed() — Core Logic

- [ ] **2.7.1** RED: Write test `test_uproot_seed_success()`
  - _Ticket ref: FR-017, FR-018, FR-019_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **2.7.2** RED: Write test `test_uproot_seed_not_found()`
  - _Ticket ref: FR-019, NFR-014_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **2.7.3** RED: Write test `test_uproot_unplanted_seed_returns_null()`
  - _Ticket ref: FR-020_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **2.7.4** GREEN: Implement `uproot_seed(seed_id: String) -> SeedData`
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Find seed, check planted, reset is_planted/phase/progress, return seed_
- [ ] **2.7.5** Run tests — verify uproot tests pass

### 2.8 Uprooting: State Consistency

- [ ] **2.8.1** RED: Write test `test_uproot_decrements_planted_count()`
  - _Ticket ref: FR-022_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **2.8.2** RED: Write test `test_uproot_seed_remains_in_grove()`
  - _Ticket ref: AC 13.4 item 9_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **2.8.3** GREEN: Verify uproot logic maintains state consistency
  - _File: `src/managers/seed_grove.gd`_
  - _No code change needed — tests validate existing implementation_
- [ ] **2.8.4** Run tests — verify state consistency tests pass

### 2.9 Integration: remove_seed() Uproots First

- [ ] **2.9.1** RED: Write test `test_remove_planted_seed_uproots_first()`
  - _Ticket ref: FR-007_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **2.9.2** GREEN: Update `remove_seed()` to call uproot_seed() if seed is planted
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Check is_planted, call uproot_seed(), then erase_
- [ ] **2.9.3** Run test — verify remove uproots first

### Phase 2 Validation Gate

- [ ] **2.V.1** All planting tests pass (success, guards, signal emission)
- [ ] **2.V.2** All uprooting tests pass (core logic, state consistency)
- [ ] **2.V.3** `planted_count` correctly reflects planted state
- [ ] **2.V.4** EventBus.seed_planted signal emits correctly
- [ ] **2.V.5** Commit: `"Phase 2: SeedGrove planting and uprooting — 20 tests pass"`

---

## Phase 3: Growth Tick — Core Loop

> **Ticket References**: FR-030 through FR-041 (Growth Tick), AC 13.5
> **Estimated Items**: 18
> **Dependencies**: Phase 2 complete
> **Validation Gate**: Tick advances seeds, phase transitions work, events returned

### 3.1 Tick: Basic Growth Advancement

- [ ] **3.1.1** RED: Write test `test_tick_advances_planted_seeds()`
  - _Ticket ref: FR-030_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **3.1.2** RED: Write test `test_tick_does_not_advance_unplanted()`
  - _Ticket ref: FR-031_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **3.1.3** RED: Write test `test_tick_does_not_advance_bloom()`
  - _Ticket ref: FR-032_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **3.1.4** GREEN: Implement `tick(delta: float) -> Array[Dictionary]` (basic loop)
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Loop planted seeds, call advance_growth(delta), collect events_
  - _Return empty array for now_
- [ ] **3.1.5** Run tests — verify basic tick tests pass

### 3.2 Tick: Phase Transition Detection

- [ ] **3.2.1** RED: Write test `test_tick_returns_phase_changed_event()`
  - _Ticket ref: FR-033, FR-037, FR-038, FR-039_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **3.2.2** RED: Write test `test_tick_event_has_required_keys()`
  - _Ticket ref: FR-038_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **3.2.3** GREEN: Add phase transition detection to tick()
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Store old_phase, call advance_growth(), compare, create event dict_
  - _Event format: `{"seed_id": seed.id, "event": "phase_changed", "data": {"old": old_phase, "new": new_phase}}`_
- [ ] **3.2.4** Run tests — verify phase transition detection works

### 3.3 Tick: Bloom Detection

- [ ] **3.3.1** RED: Write test `test_tick_returns_bloom_reached_event()`
  - _Ticket ref: FR-036, FR-039_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **3.3.2** GREEN: Add BLOOM detection to tick()
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: If new_phase == BLOOM, add "bloom_reached" event_
- [ ] **3.3.3** Run test — verify bloom event is created

### 3.4 Tick: Signal Emission

- [ ] **3.4.1** RED: Write test `test_tick_emits_seed_phase_changed_signal()`
  - _Ticket ref: FR-033_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **3.4.2** RED: Write test `test_tick_emits_seed_matured_signal()`
  - _Ticket ref: FR-036_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **3.4.3** GREEN: Add signal emissions to tick()
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: On phase change, emit seed_phase_changed; on BLOOM, emit seed_matured_
- [ ] **3.4.4** Run tests — verify signal emission tests pass

### 3.5 Tick: Edge Cases

- [ ] **3.5.1** RED: Write test `test_tick_zero_delta_no_events()`
  - _Ticket ref: FR-040, NFR-014_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **3.5.2** RED: Write test `test_tick_large_delta_multi_phase()`
  - _Ticket ref: FR-040, FR-041_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **3.5.3** GREEN: Verify tick() handles edge cases correctly
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: advance_growth() already handles edge cases; tick() just loops_
  - _Note: Multiple transitions in one tick requires loop until no phase change_
- [ ] **3.5.4** Run tests — verify edge case tests pass

### 3.6 Tick: Multi-Phase Transitions

- [ ] **3.6.1** Update tick() to handle multiple phase transitions in one call
  - _Ticket ref: FR-041_
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: For large delta, call advance_growth() in loop until phase stops changing_
  - _Alternative: SeedData.advance_growth() may already handle this — verify first_
- [ ] **3.6.2** Run test `test_tick_large_delta_multi_phase()` — verify multi-phase works

### Phase 3 Validation Gate

- [ ] **3.V.1** All tick tests pass (advancement, phase detection, signals)
- [ ] **3.V.2** Edge cases handled (zero delta, large delta)
- [ ] **3.V.3** Events array returned with correct structure
- [ ] **3.V.4** Signals emitted for phase changes and bloom
- [ ] **3.V.5** Commit: `"Phase 3: SeedGrove tick() growth loop — 26 tests pass"`

---

## Phase 4: Mutation and Reagent Application

> **Ticket References**: FR-050 through FR-058 (Mutation/Reagent), AC 13.6
> **Estimated Items**: 14
> **Dependencies**: Phase 3 complete
> **Validation Gate**: Reagent application works, spontaneous mutations roll correctly

### 4.1 Reagent Application: apply_reagent() — Success Path

- [ ] **4.1.1** RED: Write test `test_apply_reagent_success()`
  - _Ticket ref: FR-052, FR-054_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **4.1.2** GREEN: Implement `apply_reagent(seed_id: String, reagent_id: String) -> bool` (success only)
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Find seed, find first empty slot, set reagent_id, return true_
  - _Note: Effect application added next_
- [ ] **4.1.3** Run test — verify reagent fills slot

### 4.2 Reagent Application: Error Cases

- [ ] **4.2.1** RED: Write test `test_apply_reagent_not_found()`
  - _Ticket ref: FR-050, NFR-014_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **4.2.2** RED: Write test `test_apply_reagent_no_empty_slots()`
  - _Ticket ref: FR-051_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **4.2.3** GREEN: Add guard clauses to apply_reagent()
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Return false if seed not found or no empty slots_
- [ ] **4.2.4** Run tests — verify error cases handled

### 4.3 Reagent Application: Trait Modification

- [ ] **4.3.1** RED: Write test `test_apply_reagent_modifies_dungeon_traits()`
  - _Ticket ref: FR-053, FR-055_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **4.3.2** GREEN: Add trait modification to apply_reagent()
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: For now, stub with simple modifier (e.g., +0.1 to hazard_frequency)_
  - _Note: Ticket says effect Dictionary passed by caller — need to define interface_
  - _Decision: Reagent effects are passed as Dictionary parameter (defer to future task)_
  - _Stub: Hardcode a simple effect for testing purposes_
- [ ] **4.3.3** Run test — verify traits are modified

### 4.4 Spontaneous Mutation: Roll on Phase Change

- [ ] **4.4.1** RED: Write test `test_spontaneous_mutation_on_phase_change()`
  - _Ticket ref: FR-034, FR-035, FR-056_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **4.4.2** RED: Write test `test_no_mutation_with_zero_potential()`
  - _Ticket ref: FR-058_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **4.4.3** GREEN: Add mutation roll to tick() after phase transition
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: if rng.randf() < seed.mutation_potential: apply_random_trait_modifier()_
- [ ] **4.4.4** Run tests — verify mutation roll works

### 4.5 Spontaneous Mutation: Trait Modification

- [ ] **4.5.1** Implement helper `_apply_random_mutation(seed: SeedData) -> void`
  - _Ticket ref: FR-057_
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Select random trait key, apply random modifier (+/- 0.1 to 0.3)_
- [ ] **4.5.2** Add "mutated" event to tick() when mutation succeeds
  - _Ticket ref: FR-039_
  - _File: `src/managers/seed_grove.gd`_
  - _Event format: `{"seed_id": seed.id, "event": "mutated", "data": {"trait": key, "modifier": value}}`_
- [ ] **4.5.3** Run mutation tests — verify mutations work

### Phase 4 Validation Gate

- [ ] **4.V.1** All reagent application tests pass
- [ ] **4.V.2** Mutation rolls work with deterministic RNG
- [ ] **4.V.3** Mutation events are created correctly
- [ ] **4.V.4** Zero mutation potential = no mutations
- [ ] **4.V.5** Commit: `"Phase 4: SeedGrove mutation and reagent application — 32 tests pass"`

---

## Phase 5: Query Methods

> **Ticket References**: FR-060 through FR-063 (Query/Readiness), AC 13.7
> **Estimated Items**: 12
> **Dependencies**: Phase 4 complete
> **Validation Gate**: All query methods return correct results

### 5.1 Query: get_matured_seeds()

- [ ] **5.1.1** RED: Write test `test_get_matured_seeds()`
  - _Ticket ref: FR-060_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **5.1.2** GREEN: Implement `get_matured_seeds() -> Array[SeedData]`
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Filter seeds where `phase == Enums.SeedPhase.BLOOM`_
- [ ] **5.1.3** Run test — verify get_matured_seeds test passes

### 5.2 Expedition Readiness: is_ready_for_expedition()

- [ ] **5.2.1** RED: Write test `test_is_ready_for_expedition_sprout()`
  - _Ticket ref: FR-061_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **5.2.2** RED: Write test `test_is_ready_for_expedition_bud()`
  - _Ticket ref: FR-061_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **5.2.3** RED: Write test `test_is_ready_for_expedition_bloom()`
  - _Ticket ref: FR-061_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **5.2.4** RED: Write test `test_is_ready_for_expedition_spore()`
  - _Ticket ref: FR-062_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **5.2.5** RED: Write test `test_is_ready_for_expedition_unknown_id()`
  - _Ticket ref: FR-063, NFR-014_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **5.2.6** GREEN: Implement `is_ready_for_expedition(seed_id: String) -> bool`
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Find seed, return false if not found or SPORE, true otherwise_
- [ ] **5.2.7** Run tests — verify all expedition readiness tests pass

### Phase 5 Validation Gate

- [ ] **5.V.1** All query method tests pass
- [ ] **5.V.2** Expedition readiness logic correct for all phases
- [ ] **5.V.3** Invalid inputs return safe defaults (false, empty array)
- [ ] **5.V.4** Commit: `"Phase 5: SeedGrove query methods — 38 tests pass"`

---

## Phase 6: Seed Factory

> **Ticket References**: FR-070 through FR-076 (Seed Factory), AC 13.8
> **Estimated Items**: 12
> **Dependencies**: Phase 5 complete
> **Validation Gate**: create_seed() produces valid seeds with correct properties

### 6.1 Factory: create_seed() — Basic Creation

- [ ] **6.1.1** RED: Write test `test_create_seed_returns_valid_seed()`
  - _Ticket ref: FR-071, FR-072, FR-073, FR-074_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **6.1.2** RED: Write test `test_create_seed_unique_ids()`
  - _Ticket ref: FR-070_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **6.1.3** GREEN: Implement `create_seed(rarity: Enums.SeedRarity, element: Enums.Element, p_rng: DeterministicRNG) -> SeedData`
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Call SeedData.create_seed() or create manually with all properties_
  - _Note: Use RNG for ID generation_
- [ ] **6.1.4** Run tests — verify create_seed basic tests pass

### 6.2 Factory: Slot Count Validation

- [ ] **6.2.1** RED: Write test `test_create_seed_correct_slot_count()`
  - _Ticket ref: FR-073_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **6.2.2** GREEN: Verify create_seed() sets correct slot count from GameConfig
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Already handled by SeedData.create_seed() — test validates_
- [ ] **6.2.3** Run test — verify slot count test passes

### 6.3 Factory: Not Auto-Added

- [ ] **6.3.1** RED: Write test `test_create_seed_not_auto_added()`
  - _Ticket ref: FR-076_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **6.3.2** GREEN: Verify create_seed() does not call add_seed()
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Just return created seed, don't add to array_
- [ ] **6.3.3** Run test — verify not auto-added test passes

### 6.4 Factory: Growth Rate by Rarity

- [ ] **6.4.1** RED: Write test `test_create_seed_growth_rate_by_rarity()`
  - _Ticket ref: FR-072_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **6.4.2** GREEN: Verify growth_rate is set correctly based on rarity
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Already handled by SeedData.create_seed() — test validates_
- [ ] **6.4.3** Run test — verify growth rate test passes

### Phase 6 Validation Gate

- [ ] **6.V.1** All create_seed tests pass
- [ ] **6.V.2** Created seeds have unique IDs
- [ ] **6.V.3** Created seeds have correct slot count and growth rate
- [ ] **6.V.4** Created seeds are NOT auto-added to grove
- [ ] **6.V.5** Commit: `"Phase 6: SeedGrove seed factory — 42 tests pass"`

---

## Phase 7: Serialization

> **Ticket References**: FR-080 through FR-086 (Serialization), AC 13.10
> **Estimated Items**: 14
> **Dependencies**: Phase 6 complete
> **Validation Gate**: Round-trip serialization preserves all state, validation works

### 7.1 Serialization: serialize()

- [ ] **7.1.1** RED: Write test `test_serialize_returns_dictionary()`
  - _Ticket ref: FR-080, FR-081, NFR-008_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **7.1.2** GREEN: Implement `serialize() -> Dictionary`
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Collect seeds as array of to_dict(), include max_grove_slots, rng state_
  - _Format: `{"seeds": [...], "max_grove_slots": 3, "rng_state": rng.get_state()}`_
- [ ] **7.1.3** Run test — verify serialize test passes

### 7.2 Deserialization: deserialize() — Basic Restore

- [ ] **7.2.1** RED: Write test `test_serialize_deserialize_round_trip()`
  - _Ticket ref: FR-082, FR-084, NFR-009_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **7.2.2** GREEN: Implement `deserialize(data: Dictionary) -> void`
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Clear seeds array, rebuild from data["seeds"], restore max_grove_slots, restore rng_
- [ ] **7.2.3** Run test — verify round-trip test passes

### 7.3 Deserialization: Missing Keys

- [ ] **7.3.1** RED: Write test `test_deserialize_handles_missing_keys()`
  - _Ticket ref: FR-083_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **7.3.2** GREEN: Add defensive get() with defaults in deserialize()
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Use `data.get("seeds", [])`, `data.get("max_grove_slots", 3)`, etc._
- [ ] **7.3.3** Run test — verify missing keys test passes

### 7.4 Deserialization: Validation — Duplicate IDs

- [ ] **7.4.1** RED: Write test `test_deserialize_rejects_duplicate_ids()`
  - _Ticket ref: Section 10 validation rule 7_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **7.4.2** GREEN: Add duplicate ID check to deserialize()
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Track seen IDs in Set, skip duplicates with warning_
- [ ] **7.4.3** Run test — verify duplicate rejection test passes

### 7.5 Deserialization: Validation — Phase Range

- [ ] **7.5.1** RED: Write test `test_deserialize_validates_phase_range()`
  - _Ticket ref: Section 10 validation rule 1_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **7.5.2** GREEN: Add phase validation to deserialize()
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Clamp phase to [SPORE, BLOOM] or use SeedData.from_dict() which already validates_
- [ ] **7.5.3** Run test — verify phase validation test passes

### 7.6 Deserialization: Validation — Grove Slots

- [ ] **7.6.1** RED: Write test `test_deserialize_clamps_grove_slots()`
  - _Ticket ref: Section 10 validation rule 6_
  - _File: `tests/managers/test_seed_grove.gd`_
- [ ] **7.6.2** GREEN: Add grove slot clamping to deserialize()
  - _File: `src/managers/seed_grove.gd`_
  - _Logic: Clamp max_grove_slots to [1, 20]_
- [ ] **7.6.3** Run test — verify slot clamping test passes

### Phase 7 Validation Gate

- [ ] **7.V.1** All serialization tests pass
- [ ] **7.V.2** Round-trip serialize → deserialize preserves all state
- [ ] **7.V.3** Missing keys handled with defaults
- [ ] **7.V.4** Validation rules applied (duplicate IDs, phase range, slots)
- [ ] **7.V.5** Commit: `"Phase 7: SeedGrove serialization with validation — 48 tests pass"`

---

## Phase 8: Documentation and Polish

> **Ticket References**: NFR-012 (doc comments), AC 13.11 (code quality), Section 8 (designer's manual)
> **Estimated Items**: 8
> **Dependencies**: Phase 7 complete
> **Validation Gate**: All doc comments present, code quality checks pass

### 8.1 Doc Comments: Public Methods

- [ ] **8.1.1** Add `##` doc comments to all public methods
  - _Ticket ref: NFR-012_
  - _File: `src/managers/seed_grove.gd`_
  - _Format: Brief description, @param tags, @return tag, side effects note_
- [ ] **8.1.2** Add file header doc comment
  - _File: `src/managers/seed_grove.gd`_
  - _Content: @file, @brief, @task TASK-012, usage example_

### 8.2 Type Annotations: Verify All Methods

- [ ] **8.2.1** Audit all method signatures for type hints
  - _Ticket ref: NFR-013_
  - _File: `src/managers/seed_grove.gd`_
  - _Check: Every parameter and return value has explicit type_
- [ ] **8.2.2** Audit all variable declarations for type hints
  - _File: `src/managers/seed_grove.gd`_
  - _Check: Every `var` has `: Type` annotation_

### 8.3 Code Review: Best Practices

- [ ] **8.3.1** Review tick() for allocation-light implementation
  - _Ticket ref: NFR-001, BP-5_
  - _File: `src/managers/seed_grove.gd`_
  - _Check: Events array pre-allocated if possible_
- [ ] **8.3.2** Review all methods for early returns / guard clauses
  - _Ticket ref: BP-9_
  - _File: `src/managers/seed_grove.gd`_
  - _Check: Guard clauses at top, reduce nesting_

### 8.4 Final Test Run

- [ ] **8.4.1** Run full GUT test suite — verify all tests pass
  - _Command: Full headless test run_
  - _Expected: All test_seed_grove.gd tests pass, no regressions in other tests_
- [ ] **8.4.2** Run regression gate checks
  - _Check: TASK-001, TASK-002, TASK-003, TASK-004 files unchanged_
  - _Check: Project opens in editor without errors_

### Phase 8 Validation Gate

- [ ] **8.V.1** All public methods have doc comments
- [ ] **8.V.2** All type annotations present (100% typed)
- [ ] **8.V.3** Code follows best practices from Section 11
- [ ] **8.V.4** Full test suite passes (48+ tests)
- [ ] **8.V.5** Commit: `"Phase 8: SeedGrove documentation and polish — COMPLETE"`

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 0 | Setup | 8 | 0 | 0 | ⬜ Not Started |
| Phase 1 | Inventory | 16 | 0 | 8 | ⬜ Not Started |
| Phase 2 | Planting/Uprooting | 20 | 0 | 20 | ⬜ Not Started |
| Phase 3 | Growth Tick | 18 | 0 | 26 | ⬜ Not Started |
| Phase 4 | Mutation | 14 | 0 | 32 | ⬜ Not Started |
| Phase 5 | Queries | 12 | 0 | 38 | ⬜ Not Started |
| Phase 6 | Factory | 12 | 0 | 42 | ⬜ Not Started |
| Phase 7 | Serialization | 14 | 0 | 48 | ⬜ Not Started |
| Phase 8 | Documentation | 8 | 0 | 48 | ⬜ Not Started |
| **Total** | | **122** | **0** | **48** | **🔄 Phase 0 Next** |

---

## File Change Summary

### New Files
| File | Phase | Purpose |
|------|-------|---------|
| `src/managers/seed_grove.gd` | 0 | SeedGrove manager class |
| `tests/managers/test_seed_grove.gd` | 0 | GUT test suite |

### Modified Files
None — this task creates new files only.

### Deleted Files
None.

---

## Commit Strategy

| Phase | Commit Message | Tests After |
|-------|----------------|-------------|
| 0 | `"Phase 0: Setup TASK-012 directories and stub files — 0 tests pass"` | 0 |
| 1 | `"Phase 1: SeedGrove inventory management — 8 tests pass"` | 8 |
| 2 | `"Phase 2: SeedGrove planting and uprooting — 20 tests pass"` | 20 |
| 3 | `"Phase 3: SeedGrove tick() growth loop — 26 tests pass"` | 26 |
| 4 | `"Phase 4: SeedGrove mutation and reagent application — 32 tests pass"` | 32 |
| 5 | `"Phase 5: SeedGrove query methods — 38 tests pass"` | 38 |
| 6 | `"Phase 6: SeedGrove seed factory — 42 tests pass"` | 42 |
| 7 | `"Phase 7: SeedGrove serialization with validation — 48 tests pass"` | 48 |
| 8 | `"Phase 8: SeedGrove documentation and polish — COMPLETE"` | 48 |

---

## Deviation Tracking

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| — | — | No deviations yet | — | — | — |

_(Deviations will be logged here as they occur during implementation)_

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| EventBus signals fail silently in headless tests | Low | Medium | Add signal watcher assertions in tests; verify signals exist on EventBus | 2, 3 |
| Large delta tick() causes timeout in tests | Low | Medium | Use small growth_rate values in tests to speed up phase transitions | 3 |
| Mutation randomness breaks determinism | Medium | High | Always use injected RNG, never global randf(); seed RNG in tests | 4 |
| SeedData.advance_growth() doesn't support multi-phase in one call | Medium | Medium | Verify behavior in Phase 3; add loop in tick() if needed | 3 |
| Reagent effect format undefined | High | Medium | Stub with simple Dictionary for now; defer full system to future task | 4 |
| Serialization breaks on version changes | Low | High | Add version field to serialized data; document migration strategy | 7 |

---

## Handoff State (2025-01-20)

### What's Complete
- Planning phase complete
- Implementation plan written and validated

### What's In Progress
- Nothing — ready to start Phase 0

### What's Blocked
- Nothing

### Next Steps
1. Create `src/managers/` and `tests/managers/` directories
2. Create stub files for seed_grove.gd and test_seed_grove.gd
3. Verify compilation and test discovery
4. Start Phase 1: Inventory Management

---

*Implementation Plan for TASK-012 | Version 1.0 | Created 2025-01-20*
