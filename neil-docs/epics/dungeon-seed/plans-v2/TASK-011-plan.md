# TASK-011: Loot Table Engine & Drop Resolver — Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-011-loot-table-engine.md`
> **GDD**: `neil-docs/epics/dungeon-seed/GDD-v2.md`
> **Status**: Planning
> **Created**: 2025-01-19
> **Repo**: `dev-agent-tool` (local — `C:\Users\wrstl\source\dev-agent-tool`)
> **Methodology**: TDD Red-Green-Refactor (mandatory for all phases)
> **Complexity**: 8 points (Moderate) — Fibonacci
> **Estimated Phases**: 6
> **Estimated Checkboxes**: ~60

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents in this order:

1. **This file** (you're reading it) — the phased checklist of what to do, with status
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-011-loot-table-engine.md`** — the full technical spec with all FRs, ACs, tests
3. **`neil-docs/epics/dungeon-seed/GDD-v2.md`** — the Game Design Document for domain context (§5 Expedition System, §8 Loot & Economy)
4. **`src/models/enums.gd`** — Enums (RoomType, ItemRarity, Currency) from TASK-003
5. **`src/models/rng.gd`** — DeterministicRNG (seeded random) from TASK-002
6. **`src/models/item_data.gd`** — ItemData model from TASK-007
7. **`src/models/item_database.gd`** — ItemDatabase from TASK-007

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| Enum definitions | `src/models/enums.gd` | **EXISTS** — `class_name Enums`, has RoomType, ItemRarity, Currency |
| RNG utility | `src/models/rng.gd` | **EXISTS** — `class_name DeterministicRNG`, provides seeded random |
| Item model | `src/models/item_data.gd` | **EXISTS** — `class_name ItemData`, has rarity, slot, stat_bonuses |
| Item database | `src/models/item_database.gd` | **EXISTS** — `class_name ItemDatabase`, has get_item(), get_items_by_rarity() |
| Loot service | `src/services/loot_service.gd` | **NEW** — `class_name LootService`, extends RefCounted |
| Loot tables | `src/resources/loot_tables.gd` | **NEW** — static const data, pre-built tables |
| Unit tests | `tests/unit/test_loot_service.gd` | **NEW** — GUT test suite for loot service |
| GUT addon | `addons/gut/` | **EXISTS** — GUT test framework pre-installed |
| v1 prototype code | `src/gdscript/` | **DO NOT TOUCH** — legacy code, out of scope |

### Key Concepts (5-minute primer)

- **LootService**: Pure-logic RefCounted service. Registers loot tables, rolls against them using weighted selection, resolves currency drops.
- **LootTables**: Static const file containing all pre-built loot table definitions (combat_common, treasure_rare, boss_loot, etc.).
- **Loot table entry**: Dictionary with `{ "item_id": String, "weight": int, "min_qty": int, "max_qty": int }`.
- **Weighted selection**: Cumulative weight sum, random value in [0, total), linear scan to find first entry whose cumulative weight exceeds the roll.
- **Deterministic guarantee**: Same RNG state + same table → same drops, always. All randomness flows through DeterministicRNG parameter.
- **Rarity filter**: `roll_with_rarity_filter()` re-rolls up to 100 times until item meets min_rarity threshold. Uses ItemDatabase to check rarity.
- **Currency formula**: `base_gold × difficulty_mult × room_type_mult × variance` — all currency computed via formula, not tables.
- **No scene tree dependency**: Extends RefCounted, no Node, no signals, pure functions.
- **Godot 4.6.1 Rule**: `class_name` on non-autoload scripts is SAFE. This is a service, not an autoload.

### Build & Verification Commands

```powershell
# Godot headless test runner for GUT
& "C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --path "C:\Users\wrstl\source\dev-agent-tool" --headless -s "res://addons/gut/gut_cmdln.gd" -gdir="res://tests/" -ginclude_subdirs

# First run requires --import
& "C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --path "C:\Users\wrstl\source\dev-agent-tool" --headless --import -s "res://addons/gut/gut_cmdln.gd" -gdir="res://tests/" -ginclude_subdirs

# Open in editor to verify scripts parse
# Project > Reload Current Project
# Bottom dock > GUT panel > Run All
```

### Regression Gate

Before AND after every phase:
1. `project.godot` must be valid (opens in editor without errors)
2. Existing models (`enums.gd`, `rng.gd`, `item_data.gd`, `item_database.gd`) are NOT modified
3. All existing tests in `tests/unit/` pass (if any)
4. All new GUT tests pass green (once written)
5. No parse errors in Output console

---

## Current State Analysis

### What Exists Today

| Item | Status | Location |
|------|--------|----------|
| `project.godot` | ✅ Exists | Root — project config with autoloads |
| `src/models/enums.gd` | ✅ Exists | TASK-003 — `class_name Enums`, RoomType, ItemRarity, Currency |
| `src/models/rng.gd` | ✅ Exists | TASK-002 — `class_name DeterministicRNG`, seeded RNG |
| `src/models/item_data.gd` | ✅ Exists | TASK-007 — `class_name ItemData`, item properties |
| `src/models/item_database.gd` | ✅ Exists | TASK-007 — `class_name ItemDatabase`, item registry |
| `src/services/` | ✅ Exists | Directory for services |
| `addons/gut/` | ✅ Exists | GUT test framework installed |
| `tests/unit/` | ✅ Exists | Contains existing test files |

### What's Missing (Gap Analysis)

| Item | Status | Required By |
|------|--------|-------------|
| `src/services/loot_service.gd` | ❌ Missing | All FRs |
| `src/resources/loot_tables.gd` | ❌ Missing | FR-040 through FR-049 |
| `tests/unit/test_loot_service.gd` | ❌ Missing | All tests |

### What Must NOT Change

- `src/models/enums.gd` — TASK-003 output, provides RoomType, ItemRarity, Currency
- `src/models/rng.gd` — TASK-002 output, provides DeterministicRNG
- `src/models/item_data.gd` — TASK-007 output, item model
- `src/models/item_database.gd` — TASK-007 output, item registry
- `src/autoloads/event_bus.gd` — TASK-001 output, central signal bus
- `src/autoloads/game_manager.gd` — TASK-001 output, lifecycle singleton
- `src/gdscript/` — v1 prototype code, explicitly out of scope
- `project.godot` — no changes needed for this task
- Existing test files — must not be broken

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
# Happy path
func test_register_table_valid_entries() -> void:

# Determinism
func test_roll_deterministic_same_seed() -> void:

# Edge cases
func test_roll_empty_table_returns_empty_array() -> void:

# Validation
func test_register_table_warns_on_missing_item_id() -> void:

# Currency formula
func test_roll_currency_combat_room_difficulty_5() -> void:
```

### Test Structure (GUT)

Every test follows Arrange-Act-Assert:
```gdscript
func test_method_scenario_expected() -> void:
    # Arrange — create instance and test data
    var service := LootService.new()
    var table_entries: Array[Dictionary] = [
        { "item_id": "iron_sword", "weight": 100, "min_qty": 1, "max_qty": 1 },
    ]
    service.register_table("test_table", table_entries)
    var rng := DeterministicRNG.new()
    rng.seed_int(42)
    
    # Act — execute the method
    var drops: Array[Dictionary] = service.roll("test_table", rng, 1)
    
    # Assert — verify the outcome
    assert_eq(drops.size(), 1)
    assert_eq(drops[0].item_id, "iron_sword")
    assert_eq(drops[0].qty, 1)
```

### Enterprise Coverage Standards

Every public method must have tests covering:
- ✅ Happy path (normal input → expected output)
- ✅ Edge cases (empty table, unregistered table, count=0, max retries)
- ✅ Determinism (same seed → same output)
- ✅ Validation (warnings on invalid entries, null RNG)
- ✅ Currency formula (all room types, difficulty scaling, variance)

---

## 🔴 CRITICAL GODOT 4.6.1 RULES

**MUST follow these rules to avoid parse errors and test failures:**

1. **NO `class_name` on autoload scripts** — causes parse error. Models use `class_name`, autoloads do NOT.
2. **PowerShell `Set-Content` strips tabs** — ALWAYS use `edit` or `create` tool for GDScript files, NEVER `Set-Content`.
3. **GUT requires `--import` before first test run** — initial test run must include `--import` flag.
4. **GUT auto-tracks `push_error()`** — use `assert_push_error_count()` for expected errors.
5. **Tests must use `preload()` for class_name resolution** — `preload("res://src/models/enums.gd")` ensures Enums is available.
6. **GameConfig and Enums use class_name (NOT autoloads)** — access directly: `Enums.RoomType.COMBAT`, `Enums.ItemRarity.RARE`.

---

## Phase 0: Pre-Flight & Dependency Verification

> **Ticket References**: FR-001 (prerequisites)
> **AC References**: AC-001 through AC-005 (structural prerequisites)
> **Estimated Items**: 7
> **Dependencies**: TASK-002, TASK-003, TASK-007 complete
> **Validation Gate**: All upstream dependencies verified, resources directory ready

This phase verifies that all upstream dependencies are in place and the repository is ready for implementation.

### 0.1 Verify Upstream Task Outputs

- [ ] **0.1.1** Verify `src/models/enums.gd` exists and declares `class_name Enums`
  - _Ticket ref: Assumption A-011_
  - _File: `src/models/enums.gd`_
  - _Check: `Enums.RoomType` has COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS_
  - _Check: `Enums.ItemRarity` has COMMON, UNCOMMON, RARE, EPIC, LEGENDARY_
  - _Check: `Enums.Currency` has GOLD, ESSENCE, FRAGMENTS, ARTIFACTS_

- [ ] **0.1.2** Verify `src/models/rng.gd` exists and declares `class_name DeterministicRNG`
  - _Ticket ref: TASK-002 dependency, Assumption A-006 through A-008_
  - _File: `src/models/rng.gd`_
  - _Check: Has methods `seed_int()`, `randf()`, `randi()`, `randi_range()`, `weighted_pick()`_

- [ ] **0.1.3** Verify `src/models/item_data.gd` exists and declares `class_name ItemData`
  - _Ticket ref: TASK-007 dependency, Assumption A-010_
  - _File: `src/models/item_data.gd`_
  - _Check: Has property `rarity: Enums.ItemRarity`_

- [ ] **0.1.4** Verify `src/models/item_database.gd` exists and declares `class_name ItemDatabase`
  - _Ticket ref: TASK-007 dependency, Assumption A-009_
  - _File: `src/models/item_database.gd`_
  - _Check: Has methods `get_item(id: String) -> ItemData`, `get_items_by_rarity(rarity: Enums.ItemRarity)`_
  - _Check: Has starter items registered (wooden_sword, iron_sword, etc.)_

### 0.2 Verify No Conflicts

- [ ] **0.2.1** Verify `src/resources/` directory exists or create it
  - _Directory: `src/resources/`_

- [ ] **0.2.2** Verify `src/services/loot_service.gd` does NOT already exist (no file collision)
  - _File: `src/services/loot_service.gd`_

- [ ] **0.2.3** Verify `src/resources/loot_tables.gd` does NOT already exist (no file collision)
  - _File: `src/resources/loot_tables.gd`_

- [ ] **0.2.4** Verify no existing `class_name LootService` or `class_name LootTables` in the codebase

- [ ] **0.2.5** Verify `tests/unit/test_loot_service.gd` does NOT already exist

### Phase 0 Validation Gate

- [ ] **0.V.1** All upstream dependencies verified present and contain expected APIs
- [ ] **0.V.2** No file conflicts detected
- [ ] **0.V.3** `src/resources/` directory exists
- [ ] **0.V.4** Existing tests in `tests/` pass (regression baseline)
- [ ] **0.V.5** Commit: `"Phase 0: Verify TASK-011 dependencies — all upstream models present"`

---

## Phase 1: LootService Skeleton & Table Registration (TDD)

> **Ticket References**: FR-001 through FR-007
> **AC References**: AC-010 through AC-025
> **Estimated Items**: 10
> **Dependencies**: Phase 0 complete
> **Validation Gate**: `LootService` class exists, table registration tests pass

### 1.1 Write Table Registration Tests (RED)

- [ ] **1.1.1** Create `tests/unit/test_loot_service.gd` with test class and helpers
  - _Ticket ref: Section 14 — Unit Tests_
  - _File: `tests/unit/test_loot_service.gd`_
  - _Content: `extends GutTest`, helper preloads, test setup/teardown_
  - _Tests: `test_register_table_valid_entries`, `test_register_table_overwrites_existing`, `test_has_table_true_after_registration`, `test_has_table_false_for_unregistered`, `test_get_table_returns_copy`, `test_register_table_warns_on_invalid_weight`, `test_register_table_accepts_empty_array`_
  - _TDD: RED — tests reference `LootService` which does not exist yet_

### 1.2 Implement LootService Skeleton (GREEN)

- [ ] **1.2.1** Create `src/services/loot_service.gd` with class declaration
  - _Ticket ref: FR-001, AC-010_
  - _File: `src/services/loot_service.gd`_
  - _Content: `class_name LootService` + `extends RefCounted` + class doc comment_

- [ ] **1.2.2** Add internal `_tables: Dictionary` storage
  - _Ticket ref: FR-001_
  - _Type: `var _tables: Dictionary = {}`_
  - _Stores: `{ table_id: String -> Array[Dictionary] }`_

- [ ] **1.2.3** Add `register_table(table_id: String, entries: Array[Dictionary]) -> void`
  - _Ticket ref: FR-001, FR-002, FR-003, FR-004, AC-011 through AC-015_
  - _Validation: Check each entry has `item_id`, `weight > 0`, `min_qty >= 1`, `max_qty >= min_qty`_
  - _Stores: Filtered valid entries in `_tables[table_id]`_
  - _Warnings: Print warning for invalid entries, skip them_

- [ ] **1.2.4** Add `get_table(table_id: String) -> Array[Dictionary]`
  - _Ticket ref: FR-005, AC-020_
  - _Returns: Copy of entries array, or empty array if table doesn't exist_

- [ ] **1.2.5** Add `has_table(table_id: String) -> bool`
  - _Ticket ref: FR-006, AC-021_
  - _Returns: true if table_id is registered_

### Phase 1 Validation Gate

- [ ] **1.V.1** `src/services/loot_service.gd` exists and is parseable GDScript
- [ ] **1.V.2** File extends `RefCounted` and declares `class_name LootService`
- [ ] **1.V.3** All table registration methods have `##` doc comments and type hints
- [ ] **1.V.4** All 7 table registration tests pass green
- [ ] **1.V.5** No Node, SceneTree, or signal declarations in file (NFR-005)
- [ ] **1.V.6** Commit: `"Phase 1: Add LootService skeleton & table registration — 7 tests"`

---

## Phase 2: Weighted Rolling & Drop Resolution (TDD)

> **Ticket References**: FR-010 through FR-017
> **AC References**: AC-030 through AC-045
> **Estimated Items**: 12
> **Dependencies**: Phase 1 complete
> **Validation Gate**: Roll tests pass, determinism verified

### 2.1 Write Roll Tests (RED)

- [ ] **2.1.1** Add roll test section to `tests/unit/test_loot_service.gd`
  - _Tests: `test_roll_single_entry_table`, `test_roll_multiple_entries_weighted`, `test_roll_returns_exact_count`, `test_roll_deterministic_same_seed`, `test_roll_deterministic_different_seeds`, `test_roll_empty_table_returns_empty`, `test_roll_unregistered_table_returns_empty`, `test_roll_resolves_quantity_range`, `test_roll_no_mutation_of_table`_
  - _TDD: RED — tests call `roll()` which doesn't exist yet_

### 2.2 Implement Weighted Roll

- [ ] **2.2.1** Add constants for roll configuration
  - _Ticket ref: FR-017, NFR-016_
  - _Constants: `MAX_ROLL_COUNT: int = 100`_

- [ ] **2.2.2** Add `roll(table_id: String, rng: DeterministicRNG, count: int = 1) -> Array[Dictionary]`
  - _Ticket ref: FR-010, FR-011, FR-013, AC-030 through AC-035_
  - _Steps: Validate table exists → Clamp count to [1, MAX_ROLL_COUNT] → For each roll: weighted_pick entry → resolve quantity → append to results_
  - _Returns: `Array[{ "item_id": String, "qty": int }]`_

- [ ] **2.2.3** Add helper `_weighted_pick_entry(entries: Array[Dictionary], rng: DeterministicRNG) -> Dictionary`
  - _Ticket ref: FR-011, AC-036_
  - _Algorithm: Cumulative weight sum, rng.randf() × total, linear scan for first entry exceeding threshold_
  - _Returns: The selected entry dictionary_

- [ ] **2.2.4** Add helper `_resolve_quantity(entry: Dictionary, rng: DeterministicRNG) -> int`
  - _Ticket ref: FR-012, AC-037_
  - _Algorithm: `rng.randi_range(entry.min_qty, entry.max_qty)`_

### 2.3 Error Handling

- [ ] **2.3.1** Add null RNG check in `roll()`
  - _Ticket ref: FR-052_
  - _If rng is null: push_error(), return empty array_

- [ ] **2.3.2** Add warning for unregistered table in `roll()`
  - _Ticket ref: FR-050_
  - _If table not found: push_warning(), return empty array_

### Phase 2 Validation Gate

- [ ] **2.V.1** All roll methods have `##` doc comments
- [ ] **2.V.2** All 9 roll tests pass green
- [ ] **2.V.3** Determinism verified: same RNG seed → same drops
- [ ] **2.V.4** Weighted selection correctly distributes according to weights
- [ ] **2.V.5** Quantity ranges correctly resolved
- [ ] **2.V.6** No table mutation during rolls
- [ ] **2.V.7** Commit: `"Phase 2: Implement weighted roll & drop resolution — 9 tests"`

---

## Phase 3: Rarity-Filtered Rolling (TDD)

> **Ticket References**: FR-020 through FR-025
> **AC References**: AC-050 through AC-062
> **Estimated Items**: 10
> **Dependencies**: Phase 2 complete
> **Validation Gate**: Rarity filter tests pass, retry logic verified

### 3.1 Write Rarity Filter Tests (RED)

- [ ] **3.1.1** Add rarity filter test section to `tests/unit/test_loot_service.gd`
  - _Tests: `test_roll_with_rarity_filter_meets_threshold`, `test_roll_with_rarity_filter_retries_until_found`, `test_roll_with_rarity_filter_returns_empty_after_max_retries`, `test_roll_with_rarity_filter_deterministic`, `test_roll_with_rarity_filter_requires_item_database`_
  - _TDD: RED — tests call `roll_with_rarity_filter()` which doesn't exist yet_

### 3.2 Implement Rarity Filter

- [ ] **3.2.1** Add constant for retry limit
  - _Ticket ref: FR-022, NFR-016_
  - _Constant: `MAX_RARITY_RETRIES: int = 100`_

- [ ] **3.2.2** Add `roll_with_rarity_filter(table_id: String, rng: DeterministicRNG, min_rarity: Enums.ItemRarity, item_db: ItemDatabase) -> Array[Dictionary]`
  - _Ticket ref: FR-020, FR-021, FR-022, FR-023, FR-024, AC-050 through AC-055_
  - _Steps: For up to MAX_RARITY_RETRIES: roll once → get item from item_db → check rarity → if meets threshold, return → else retry_
  - _Returns: `[{ "item_id": String, "qty": int }]` or empty array if no qualifying item found_

- [ ] **3.2.3** Add validation for null item_db parameter
  - _If item_db is null: push_error(), return empty array_

- [ ] **3.2.4** Add validation for item not found in database
  - _If item_db.get_item(item_id) returns null: count as failed retry, continue_

### Phase 3 Validation Gate

- [ ] **3.V.1** All rarity filter methods have `##` doc comments
- [ ] **3.V.2** All 5 rarity filter tests pass green
- [ ] **3.V.3** Retry logic correctly consumes RNG state deterministically
- [ ] **3.V.4** Max retries correctly enforced (returns empty after 100 retries)
- [ ] **3.V.5** Null item_db handled gracefully
- [ ] **3.V.6** Commit: `"Phase 3: Implement rarity-filtered rolling with retry logic — 5 tests"`

---

## Phase 4: Currency Drop Formula (TDD)

> **Ticket References**: FR-030 through FR-038
> **AC References**: AC-070 through AC-085
> **Estimated Items**: 11
> **Dependencies**: Phase 3 complete
> **Validation Gate**: Currency tests pass, formula verified

### 4.1 Write Currency Tests (RED)

- [ ] **4.1.1** Add currency drop test section to `tests/unit/test_loot_service.gd`
  - _Tests: `test_roll_currency_combat_room_difficulty_1`, `test_roll_currency_combat_room_difficulty_10`, `test_roll_currency_treasure_room_multiplier`, `test_roll_currency_boss_room_multiplier`, `test_roll_currency_rest_room_zero`, `test_roll_currency_variance_applied`, `test_roll_currency_deterministic`, `test_roll_currency_returns_integers`, `test_roll_currency_essence_boss_room`, `test_roll_currency_essence_treasure_room`_
  - _TDD: RED — tests call `roll_currency()` which doesn't exist yet_

### 4.2 Implement Currency Formula

- [ ] **4.2.1** Add currency constants
  - _Ticket ref: FR-031, FR-032, FR-033, FR-034, FR-038, NFR-016_
  - _Constants: `BASE_GOLD: int = 10`, `DIFFICULTY_SCALE: float = 0.15`, `VARIANCE_RANGE: float = 0.2`, `ESSENCE_BASE_MULT: float = 0.5`, `BOSS_ESSENCE_MULT: float = 2.0`, `TREASURE_ESSENCE_MULT: float = 1.0`_

- [ ] **4.2.2** Add `ROOM_CURRENCY_MULT: Dictionary` constant
  - _Ticket ref: FR-033, AC-075_
  - _Mapping: `{ Enums.RoomType.COMBAT: 1.0, TREASURE: 2.5, TRAP: 0.3, PUZZLE: 1.5, REST: 0.0, BOSS: 3.0 }`_

- [ ] **4.2.3** Add `roll_currency(room_type: Enums.RoomType, difficulty: int, rng: DeterministicRNG) -> Dictionary`
  - _Ticket ref: FR-030, FR-031, FR-032, FR-035, FR-036, AC-070 through AC-080_
  - _Steps: Clamp difficulty to [1, 10] → Calculate difficulty_mult → Get room_type_mult → Compute base gold → Apply variance → Round to int → Compute essence for BOSS/TREASURE → Return dictionary_
  - _Returns: `{ Enums.Currency.GOLD: int, Enums.Currency.ESSENCE: int }` (essence only for BOSS/TREASURE)_

- [ ] **4.2.4** Add helper `_get_room_currency_mult(room_type: Enums.RoomType) -> float`
  - _Ticket ref: AC-076_
  - _Returns: ROOM_CURRENCY_MULT[room_type] with fallback to 1.0_

### 4.3 REST Room Special Case

- [ ] **4.3.1** Add special case for REST rooms in `roll_currency()`
  - _Ticket ref: FR-037, AC-082_
  - _If room_type == REST: return empty dictionary (no currency)_

### Phase 4 Validation Gate

- [ ] **4.V.1** All currency methods have `##` doc comments
- [ ] **4.V.2** All 10 currency tests pass green
- [ ] **4.V.3** Difficulty scaling formula correct (1.0 + (diff-1) × 0.15)
- [ ] **4.V.4** Room type multipliers correctly applied
- [ ] **4.V.5** Variance applied deterministically (same RNG → same variance)
- [ ] **4.V.6** REST rooms return empty dictionary
- [ ] **4.V.7** Essence only drops from BOSS and TREASURE
- [ ] **4.V.8** Commit: `"Phase 4: Implement currency drop formula — 10 tests"`

---

## Phase 5: Pre-Built Loot Tables (TDD)

> **Ticket References**: FR-040 through FR-049
> **AC References**: AC-100 through AC-115
> **Estimated Items**: 12
> **Dependencies**: Phase 4 complete
> **Validation Gate**: All pre-built tables validated, items exist in ItemDatabase

### 5.1 Write Loot Tables Data File

- [ ] **5.1.1** Create `src/resources/loot_tables.gd` with static const tables
  - _Ticket ref: FR-040 through FR-046, AC-100 through AC-110_
  - _File: `src/resources/loot_tables.gd`_
  - _Content: `class_name LootTables` (NO extends — pure static data class)_
  - _Note: This is a static const data file, not an autoload, so `class_name` is SAFE_

- [ ] **5.1.2** Define `COMBAT_COMMON: Array[Dictionary]` with 8 entries
  - _Ticket ref: FR-040, AC-100_
  - _Items: wooden_sword, iron_sword, cloth_tunic, leather_vest, copper_ring, health potion placeholder, gold_coins placeholder (total weight ~1000)_
  - _All item_ids MUST exist in ItemDatabase starter items_

- [ ] **5.1.3** Define `COMBAT_RARE: Array[Dictionary]` with 6 entries
  - _Ticket ref: FR-041, AC-101_
  - _Items: iron_sword, steel_blade, leather_vest, chainmail, silver_ring (total weight ~600)_

- [ ] **5.1.4** Define `TREASURE_COMMON: Array[Dictionary]` with 8 entries
  - _Ticket ref: FR-042, AC-102_
  - _Items: high gold weight, gems placeholder, potions placeholder (total weight ~1200)_

- [ ] **5.1.5** Define `TREASURE_RARE: Array[Dictionary]` with 6 entries
  - _Ticket ref: FR-043, AC-103_
  - _Items: steel_blade, crystal_saber, chainmail, dragon_plate, ruby_amulet, sapphire_pendant (total weight ~500)_

- [ ] **5.1.6** Define `BOSS_LOOT: Array[Dictionary]` with 7 entries
  - _Ticket ref: FR-044, AC-104_
  - _Items: crystal_saber, dragon_plate, emerald_brooch, obsidian_charm, unique boss drops placeholder (total weight ~400)_

- [ ] **5.1.7** Define `TRAP_CONSOLATION: Array[Dictionary]` with 5 entries
  - _Ticket ref: FR-045, AC-105_
  - _Items: minor potions placeholder, scraps placeholder, small gold (total weight ~800)_

- [ ] **5.1.8** Define `PUZZLE_REWARD: Array[Dictionary]` with 6 entries
  - _Ticket ref: FR-046, AC-106_
  - _Items: utility items placeholder, essences placeholder, silver_ring, arcane_rod (total weight ~700)_

- [ ] **5.1.9** Add `static func get_all_tables() -> Dictionary`
  - _Ticket ref: FR-047, AC-110_
  - _Returns: `{ "combat_common": COMBAT_COMMON, "combat_rare": COMBAT_RARE, ... }`_

### 5.2 Write Pre-Built Table Tests (RED)

- [ ] **5.2.1** Add pre-built table test section to `tests/unit/test_loot_service.gd`
  - _Tests: `test_loot_tables_all_tables_present`, `test_loot_tables_combat_common_valid_items`, `test_loot_tables_boss_loot_valid_items`, `test_loot_tables_all_weights_positive`, `test_loot_tables_all_items_exist_in_database`, `test_register_all_prebuilt_tables`_
  - _TDD: RED — tests reference `LootTables` which exists but tables may be incomplete_

### 5.3 Validate Tables Against ItemDatabase

- [ ] **5.3.1** Iterate through all table entries and verify item_ids exist in ItemDatabase
  - _Ticket ref: FR-048, AC-111_
  - _For each table, for each entry, call `ItemDatabase.new().get_item(entry.item_id)` and assert non-null_
  - _If items are missing, add placeholders with descriptive IDs like `"health_potion_small"` (these will be implemented in TASK-007 expansion)_

### Phase 5 Validation Gate

- [ ] **5.V.1** `src/resources/loot_tables.gd` exists and is parseable GDScript
- [ ] **5.V.2** File declares `class_name LootTables` (NO extends)
- [ ] **5.V.3** All 7 pre-built tables defined as `const Array[Dictionary]`
- [ ] **5.V.4** All 6 pre-built table tests pass green
- [ ] **5.V.5** All item_ids in all tables exist in ItemDatabase (or are documented placeholders)
- [ ] **5.V.6** All weights are positive integers
- [ ] **5.V.7** All qty ranges are valid (min_qty >= 1, max_qty >= min_qty)
- [ ] **5.V.8** Commit: `"Phase 5: Add 7 pre-built loot tables with validation — 6 tests"`

---

## Phase 6: Integration, Documentation, & Final Validation

> **Ticket References**: All FRs, all ACs, all NFRs
> **AC References**: AC-120 through AC-130
> **Estimated Items**: 10
> **Dependencies**: Phase 5 complete
> **Validation Gate**: All tests pass, code documented, performance verified

### 6.1 Integration Testing

- [ ] **6.1.1** Add integration test for full loot pipeline
  - _File: `tests/unit/test_loot_service.gd`_
  - _Test: `test_full_pipeline_register_roll_currency`_
  - _Scenario: Register all pre-built tables → Roll from each table → Roll currency for each room type → Verify all produce valid output_

- [ ] **6.1.2** Add determinism integration test
  - _Test: `test_determinism_1000_rolls_identical`_
  - _Scenario: Seed two RNGs identically → Roll 1000 times from each → Assert all results identical_

- [ ] **6.1.3** Add performance smoke test
  - _Test: `test_performance_10000_rolls_under_1_second`_
  - _Scenario: Roll 10,000 times → Measure elapsed time → Assert < 1 second (NFR-001)_

### 6.2 Code Documentation

- [ ] **6.2.1** Add `##` doc comments to all public methods in `loot_service.gd`
  - _Ticket ref: NFR-008_
  - _Format: Brief description, @param tags, @return tag, example usage_

- [ ] **6.2.2** Add class-level `##` doc comment with usage example
  - _Show how to instantiate, register tables, and call roll() and roll_currency()_

- [ ] **6.2.3** Add `##` doc comments to `loot_tables.gd` constants
  - _Brief description of each table's purpose and typical use case_

### 6.3 Code Quality Checks

- [ ] **6.3.1** Remove all debug `print()` statements
  - _Replace with appropriate `push_warning()` or `push_error()` where needed_

- [ ] **6.3.2** Ensure all methods have type hints on parameters and return types
  - _Ticket ref: NFR-007_

- [ ] **6.3.3** Run all tests and verify 0 errors, 0 warnings in Output console
  - _Check for `push_error()` or `push_warning()` calls that shouldn't be there_

- [ ] **6.3.4** Verify no global RNG usage — all RNG goes through DeterministicRNG parameter
  - _Search for `randi`, `randf`, `RandomNumberGenerator` in service file_

### 6.4 Final Regression & Handoff

- [ ] **6.4.1** Run full test suite: all `test_loot_service.gd` tests
  - _All tests must pass green_

- [ ] **6.4.2** Verify no changes to upstream models (enums, rng, item_data, item_database)
  - _Git diff to confirm_

- [ ] **6.4.3** Open project in Godot editor and verify no parse errors
  - _Output console should be clean_

- [ ] **6.4.4** Manually instantiate `LootService.new()` in editor console and call `roll()`
  - _Smoke test to confirm class is accessible_

### Phase 6 Validation Gate

- [ ] **6.V.1** All public and private methods have `##` doc comments
- [ ] **6.V.2** All methods have complete type hints
- [ ] **6.V.3** No debug prints, no warnings in console
- [ ] **6.V.4** All tests pass (unit + integration)
- [ ] **6.V.5** Performance test passes (10,000 rolls < 1 second)
- [ ] **6.V.6** No modifications to upstream dependencies
- [ ] **6.V.7** Service instantiates cleanly in editor
- [ ] **6.V.8** Commit: `"Phase 6: Documentation & final validation — TASK-011 complete"`

---

## Phase Dependency Graph

```
Phase 0 (Verify Dependencies) ──→ Phase 1 (Skeleton & Table Registration)
                                         │
                                         ↓
                                  Phase 2 (Weighted Rolling)
                                         │
                                         ↓
                                  Phase 3 (Rarity Filter)
                                         │
                                         ↓
                                  Phase 4 (Currency Formula)
                                         │
                                         ↓
                                  Phase 5 (Pre-Built Tables)
                                         │
                                         ↓
                                  Phase 6 (Integration & Docs)
```

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 0 | Verify Dependencies | 7 | 0 | 0 | ⬜ Not Started |
| Phase 1 | Skeleton & Table Registration | 10 | 0 | 7 | ⬜ Not Started |
| Phase 2 | Weighted Rolling | 12 | 0 | 9 | ⬜ Not Started |
| Phase 3 | Rarity Filter | 10 | 0 | 5 | ⬜ Not Started |
| Phase 4 | Currency Formula | 11 | 0 | 10 | ⬜ Not Started |
| Phase 5 | Pre-Built Tables | 12 | 0 | 6 | ⬜ Not Started |
| Phase 6 | Integration & Docs | 10 | 0 | 3 | ⬜ Not Started |
| **Total** | | **72** | **0** | **40** | **⬜ Planning** |

---

## File Change Summary

### New Files
| File | Phase | Purpose |
|------|-------|---------|
| `src/services/loot_service.gd` | 1 | LootService class — loot table registration and rolling |
| `src/resources/loot_tables.gd` | 5 | LootTables static data — 7 pre-built tables |
| `tests/unit/test_loot_service.gd` | 1 | Unit tests for loot service |

### Modified Files
| File | Phase | Change |
|------|-------|--------|
| _(none)_ | — | No existing files modified |

### Deleted Files
| File | Phase | Reason |
|------|-------|--------|
| _(none)_ | — | No files deleted |

---

## Commit Strategy

| Phase | Commit Message | Tests After |
|-------|----------------|-------------|
| 0 | `"Phase 0: Verify TASK-011 dependencies — all upstream models present"` | 0 |
| 1 | `"Phase 1: Add LootService skeleton & table registration — 7 tests"` | 7 |
| 2 | `"Phase 2: Implement weighted roll & drop resolution — 9 tests"` | 16 |
| 3 | `"Phase 3: Implement rarity-filtered rolling with retry logic — 5 tests"` | 21 |
| 4 | `"Phase 4: Implement currency drop formula — 10 tests"` | 31 |
| 5 | `"Phase 5: Add 7 pre-built loot tables with validation — 6 tests"` | 37 |
| 6 | `"Phase 6: Documentation & final validation — TASK-011 complete"` | 40 |

---

## Deviations from Ticket

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| _(none yet)_ | — | — | — | — | — |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| ItemDatabase missing starter items | Medium | Medium | Use placeholders for missing items, document in TASK-007 | 5 |
| Weighted selection bias due to float rounding | Low | Low | Use integer weights and integer arithmetic where possible | 2 |
| Retry loop infinite if all items below threshold | Low | High | Hard cap at 100 retries, return empty array after | 3 |
| Currency formula overflow on high difficulty | Low | Low | Clamp difficulty to [1, 10], use int arithmetic | 4 |
| LootTables mutation at runtime | Low | Medium | Define as `const`, add defensive copy on registration | 1, 5 |

---

## Handoff State (Initial)

### What's Complete
- _(none — task not started)_

### What's In Progress
- _(none)_

### What's Blocked
- _(none)_

### Next Steps
1. Begin Phase 0: Verify all upstream dependencies (TASK-002, TASK-003, TASK-007)
2. Create `src/resources/` directory if it doesn't exist
3. Start Phase 1: Write table registration tests (RED)
4. Implement LootService skeleton (GREEN)

---

*Plan version: 1.0.0 | Created: 2025-01-19 | Task: TASK-011 | Complexity: 8 points*
