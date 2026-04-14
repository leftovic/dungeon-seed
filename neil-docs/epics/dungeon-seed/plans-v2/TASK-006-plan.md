# TASK-006: Adventurer Data Model & Class Definitions — Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-006-adventurer-model.md`
> **GDD**: `neil-docs/epics/dungeon-seed/GDD-v2.md`
> **Status**: Planning
> **Created**: 2025-07-15
> **Repo**: `dev-agent-tool` (local — `C:\Users\wrstl\source\dev-agent-tool`)
> **Methodology**: TDD Red-Green-Refactor (mandatory for all phases)
> **Complexity**: 5 points (Moderate) — Fibonacci
> **Estimated Phases**: 6 (Phase 0–5)
> **Estimated Checkboxes**: ~58

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents in this order:

1. **This file** (you're reading it) — the phased checklist of what to do, with status
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-006-adventurer-model.md`** — the full technical spec with exact code to implement
3. **`neil-docs/epics/dungeon-seed/GDD-v2.md`** — the Game Design Document for understanding domain context
4. **`src/models/enums.gd`** — Enums (AdventurerClass, LevelTier, EquipSlot) from TASK-003
5. **`src/models/game_config.gd`** — GameConfig constants (BASE_STATS, XP_PER_TIER) from TASK-003
6. **`src/models/seed_data.gd`** — Reference for RefCounted model pattern (to_dict/from_dict, factory method, class_name)
7. **`src/models/room_data.gd`** — Reference for simpler RefCounted model pattern

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| Enum definitions | `src/models/enums.gd` | **EXISTS** — `class_name Enums`, has AdventurerClass, LevelTier, EquipSlot |
| Game constants | `src/models/game_config.gd` | **EXISTS** — `class_name GameConfig`, has BASE_STATS, XP_PER_TIER. **Needs additions**: XP_CURVE, STAT_KEYS, EQUIP_SLOT_KEYS |
| Adventurer data model | `src/models/adventurer_data.gd` | **NEW** — `class_name AdventurerData`, extends RefCounted |
| Unit tests | `tests/models/test_adventurer_data.gd` | **NEW** — GUT test suite covering all AdventurerData behavior |
| Existing model tests | `tests/models/test_enums_and_config.gd` | **EXISTS** — TASK-003 tests, MUST NOT break |
| Existing model tests | `tests/models/test_room_data.gd` | **EXISTS** — TASK-005 tests, MUST NOT break |
| Existing model tests | `tests/models/test_dungeon_data.gd` | **EXISTS** — TASK-005 tests, MUST NOT break |
| Autoloads | `src/autoloads/event_bus.gd`, `src/autoloads/game_manager.gd` | **EXISTS** — from TASK-001, DO NOT TOUCH |
| GUT addon | `addons/gut/` | **EXISTS** — GUT test framework pre-installed |
| v1 prototype code | `src/gdscript/` | **DO NOT TOUCH** — legacy code, not part of this task |

### Key Concepts (5-minute primer)

- **AdventurerData**: A pure data container for one adventurer. Extends `RefCounted`. No scene tree dependency, no signals, no UI. Downstream tasks (TASK-013 Roster, TASK-014 Equipment, TASK-015 Expedition) consume its public API.
- **Six adventurer classes**: WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL — each with a unique 5-stat base distribution (`health`, `attack`, `defense`, `speed`, `utility`).
- **XP & leveling**: Exponential XP curve (`100 * 1.15^(level-1)`). `gain_xp()` supports multi-level-up in a single call via a while loop.
- **Level tiers**: NOVICE (1–5), SKILLED (6–10), VETERAN (11–15), ELITE (16+). Derived from level, not stored.
- **Equipment**: Dictionary with string keys `"weapon"`, `"armor"`, `"accessory"` — all `null` initially. TASK-014 implements actual equipment items.
- **`get_effective_stats()`**: Placeholder that returns a deep copy of base stats. TASK-014 will add equipment bonuses.
- **Serialization round-trip**: `AdventurerData.from_dict(adv.to_dict()).to_dict() == adv.to_dict()` — lossless.
- **`class_name`**: GDScript keyword that registers a globally available type. `adventurer_data.gd` uses it (safe — NOT an autoload).
- **GameConfig is NOT an autoload** — it uses `class_name`. Tests access it directly as `GameConfig.CONSTANT`.
- **Godot 4.6.1 Rules**:
  - `class_name` on autoload scripts causes "Class X hides autoload" error — models use `class_name`, autoloads do NOT.
  - PowerShell `Set-Content` strips GDScript tabs — **ALWAYS use edit/create tool** for `.gd` files.
  - GUT requires `--import` before first test run.
  - GUT auto-tracks `push_error()` — use `assert_push_error_count()` for expected errors.
  - Typed arrays are strict: `Array[float]` rejects untyped `[]`.
  - Tests must use `preload()` for `class_name` resolution.

### Build & Verification Commands

```powershell
# Full regression test (run before AND after every phase):
& "C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --path "C:\Users\wrstl\source\dev-agent-tool" --headless -s "res://addons/gut/gut_cmdln.gd" -gdir="res://tests/" -ginclude_subdirs

# IMPORTANT: First test run after project changes may require --import:
& "C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --path "C:\Users\wrstl\source\dev-agent-tool" --headless --import
```

### Regression Gate

Before AND after every phase:
1. `project.godot` must be valid (opens in editor without errors)
2. Existing test files in `tests/models/` and `tests/unit/` are not broken by our changes
3. `src/models/enums.gd` is unchanged (TASK-003 output)
4. `src/autoloads/event_bus.gd` and `src/autoloads/game_manager.gd` are unchanged (TASK-001 outputs)
5. All new GUT tests pass green (once written)
6. `src/models/game_config.gd` is only modified by **adding** new constants; existing constants are only changed as documented in Deviations

---

## Current State Analysis

### What Exists Today

| Item | Status | Location |
|------|--------|----------|
| `project.godot` | ✅ Exists | Root — project config |
| `src/models/enums.gd` | ✅ Exists | TASK-003 — `class_name Enums`, AdventurerClass (6 values), LevelTier (4 values), EquipSlot (3 values) |
| `src/models/game_config.gd` | ✅ Exists | TASK-003 — `class_name GameConfig`, BASE_STATS (6 classes), XP_PER_TIER (4 tiers), plus seed/dungeon constants |
| `src/models/seed_data.gd` | ✅ Exists | TASK-004 — `class_name SeedData`, extends RefCounted (pattern reference) |
| `src/models/room_data.gd` | ✅ Exists | TASK-005 — `class_name RoomData`, extends RefCounted (pattern reference) |
| `tests/models/test_enums_and_config.gd` | ✅ Exists | TASK-003 tests (must pass as regression gate) |
| `addons/gut/` | ✅ Exists | GUT test framework installed |

### What's Missing (Gap Analysis)

| Item | Status | Required By |
|------|--------|-------------|
| `src/models/adventurer_data.gd` | ❌ Missing | FR-001 through FR-048 |
| `tests/models/test_adventurer_data.gd` | ❌ Missing | Section 14 — all test functions |
| `GameConfig.XP_CURVE` constant | ❌ Missing | FR-028 — `{ "BASE_XP": 100, "GROWTH_RATE": 1.15 }` |
| `GameConfig.STAT_KEYS` constant | ❌ Missing | Used by `from_dict()` stat validation |
| `GameConfig.EQUIP_SLOT_KEYS` constant | ❌ Missing | Used by `from_dict()` equipment validation |

### What Must NOT Change (unless documented in Deviations)

- `src/models/enums.gd` — TASK-003 output, provides AdventurerClass, LevelTier, EquipSlot
- `src/autoloads/event_bus.gd` — TASK-001 output
- `src/autoloads/game_manager.gd` — TASK-001 output
- `src/gdscript/` — v1 prototype code, explicitly out of scope
- `project.godot` — no changes needed for this task
- Existing test files in `tests/` — must not be broken

### ⚠️ Critical Discovery: BASE_STATS Value Mismatch

The existing `GameConfig.BASE_STATS` (from TASK-003) has **different stat values** from what the TASK-006 ticket specifies. This is the most important finding:

| Class | Stat | Existing (TASK-003) | Ticket (TASK-006) | Changed? |
|-------|------|--------------------|--------------------|----------|
| WARRIOR | health/atk/def/spd/util | 120/18/15/8/5 | 120/18/15/8/5 | ✅ Same |
| RANGER | health/atk/def/spd/util | 90/15/10/16/10 | 85/14/8/18/10 | ⚠️ **DIFFERS** |
| MAGE | health/atk/def/spd/util | 70/12/6/10/20 | 70/12/6/10/20 | ✅ Same |
| ROGUE | health/atk/def/spd/util | 80/20/8/18/8 | 80/15/7/16/14 | ⚠️ **DIFFERS** |
| ALCHEMIST | health/atk/def/spd/util | 85/10/9/11/22 | 90/10/10/12/18 | ⚠️ **DIFFERS** |
| SENTINEL | health/atk/def/spd/util | 130/10/20/6/7 | 140/8/20/5/8 | ⚠️ **DIFFERS** |

**Decision**: The TASK-006 ticket is the **authoritative spec** for adventurer stats (it is the adventurer-focused task). The TASK-003 values were placeholders. We will **update** the four differing classes to match the TASK-006 spec. This is tracked as **DEV-001** in the Deviations section.

**Regression safety**: Existing `test_enums_and_config.gd` tests for BASE_STATS only check *structure* (completeness, 5 keys, positive values) — they do NOT assert specific stat values for non-Warrior classes. Updating the values will not break any existing tests.

### ⚠️ Critical Discovery: GameConfig Path Mismatch

The ticket (Section 16.1) references `src/config/game_config.gd`. The actual file lives at `src/models/game_config.gd`. We use the **existing actual path**. Tracked as **DEV-002**.

### ⚠️ Critical Discovery: GameConfig is NOT an Autoload

The ticket (Section 16.1, Glossary #15) refers to GameConfig as "autoload." In the actual codebase, GameConfig uses `class_name GameConfig` (no `extends Node`, no autoload registration). Per Godot 4.6.1 rules, `class_name` on autoload scripts causes errors. We keep the existing pattern: `class_name GameConfig` with no autoload. Tracked as **DEV-003**.

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
func test_default_id_is_empty_string() -> void:

# Class-specific behavior
func test_warrior_base_stats() -> void:

# XP/leveling
func test_gain_xp_exact_levelup() -> void:

# Level tier boundary
func test_tier_skilled_level_6() -> void:

# Serialization round-trip
func test_round_trip_all_classes() -> void:

# Edge cases
func test_gain_xp_negative_returns_false() -> void:
```

### Test Structure (GUT)

Every test follows Arrange-Act-Assert:
```gdscript
func test_method_scenario_expected() -> void:
    # Arrange — create instance and test data
    var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.WARRIOR)

    # Act — execute the behavior
    var leveled: bool = adv.gain_xp(100)

    # Assert — verify the outcome
    assert_true(leveled)
    assert_eq(adv.level, 2)
    assert_eq(adv.xp, 0)
```

### Coverage Requirements Per Phase

- ✅ **Existence**: Class exists, extends `RefCounted`, has `class_name`
- ✅ **Properties**: All typed properties initialized to correct defaults
- ✅ **Initialization**: `initialize_base_stats()` copies correct stats per class
- ✅ **XP curve**: `xp_to_next_level()` returns correct exponential values
- ✅ **Leveling**: `gain_xp()` handles single, multi, zero, negative, accumulation
- ✅ **Tier boundaries**: Level 1, 5, 6, 10, 11, 15, 16, 99
- ✅ **Effective stats**: Deep copy, matches base stats, 5 keys
- ✅ **Serialization**: Round-trip fidelity, defensive deserialization, JSON compatibility
- ✅ **Edge cases**: Large XP, many small XP gains, high-level adventurer, equipment persistence

---

## Phase 0: Pre-Flight & Dependency Verification

> **Ticket References**: Assumptions 1–5, 14
> **Estimated Items**: 7
> **Dependencies**: TASK-003 complete (enums.gd, game_config.gd exist)
> **Validation Gate**: All TASK-003 dependencies verified, no file conflicts

### 0.1 Verify TASK-003 Outputs

- [ ] **0.1.1** Verify `src/models/enums.gd` exists and declares `class_name Enums`
  - _Ticket ref: Assumption #1, #2, #3_
  - _File: `src/models/enums.gd`_
  - _Check: `Enums.AdventurerClass` has WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL (6 values)_
  - _Check: `Enums.LevelTier` has NOVICE, SKILLED, VETERAN, ELITE (4 values)_
  - _Check: `Enums.EquipSlot` has WEAPON, ARMOR, ACCESSORY (3 values)_

- [ ] **0.1.2** Verify `src/models/game_config.gd` exists and declares `class_name GameConfig`
  - _Ticket ref: Assumption #4_
  - _File: `src/models/game_config.gd`_
  - _Check: `GameConfig.BASE_STATS` has entries for all 6 AdventurerClass values_
  - _Check: `GameConfig.XP_PER_TIER` has entries for all 4 LevelTier values_

- [ ] **0.1.3** Verify `addons/gut/` is installed and contains `plugin.cfg`
  - _Ticket ref: Assumption #14_

### 0.2 Verify No Conflicts

- [ ] **0.2.1** Verify `src/models/adventurer_data.gd` does NOT already exist
  - _File: `src/models/adventurer_data.gd`_

- [ ] **0.2.2** Verify `tests/models/test_adventurer_data.gd` does NOT already exist
  - _File: `tests/models/test_adventurer_data.gd`_

- [ ] **0.2.3** Verify no existing `class_name AdventurerData` anywhere in the codebase

### 0.3 Document BASE_STATS Mismatch

- [ ] **0.3.1** Confirm existing BASE_STATS values for all 6 classes and record mismatch table (see Current State Analysis above). Record as DEV-001 in Deviations section.

### Phase 0 Validation Gate

- [ ] **0.V.1** All TASK-003 outputs verified present with expected enums/constants
- [ ] **0.V.2** No file conflicts detected for `adventurer_data.gd` or `test_adventurer_data.gd`
- [ ] **0.V.3** GUT addon installed and available
- [ ] **0.V.4** Existing tests in `tests/models/` pass (regression baseline)

---

## Phase 1: GameConfig Additions (TDD)

> **Ticket References**: FR-012, FR-013–FR-020, FR-028, FR-036, AC-049, AC-050, AC-051
> **Estimated Items**: 8
> **Dependencies**: Phase 0 complete
> **Validation Gate**: `GameConfig.XP_CURVE`, `GameConfig.STAT_KEYS`, `GameConfig.EQUIP_SLOT_KEYS` exist; BASE_STATS updated to ticket spec; all existing tests still pass

This phase modifies the existing `game_config.gd` to add three new constants and update `BASE_STATS` values to match the TASK-006 ticket spec.

### 1.1 Update BASE_STATS Values

- [ ] **1.1.1** Update `GameConfig.BASE_STATS` Ranger entry to `{ "health": 85, "attack": 14, "defense": 8, "speed": 18, "utility": 10 }`
  - _Ticket ref: FR-014, AC-015_
  - _File: `src/models/game_config.gd`_
  - _DEV-001: Changing from TASK-003 values (90/15/10/16/10) to TASK-006 spec (85/14/8/18/10)_

- [ ] **1.1.2** Update `GameConfig.BASE_STATS` Rogue entry to `{ "health": 80, "attack": 15, "defense": 7, "speed": 16, "utility": 14 }`
  - _Ticket ref: FR-016, AC-017_
  - _File: `src/models/game_config.gd`_
  - _DEV-001: Changing from TASK-003 values (80/20/8/18/8) to TASK-006 spec (80/15/7/16/14)_

- [ ] **1.1.3** Update `GameConfig.BASE_STATS` Alchemist entry to `{ "health": 90, "attack": 10, "defense": 10, "speed": 12, "utility": 18 }`
  - _Ticket ref: FR-017, AC-018_
  - _File: `src/models/game_config.gd`_
  - _DEV-001: Changing from TASK-003 values (85/10/9/11/22) to TASK-006 spec (90/10/10/12/18)_

- [ ] **1.1.4** Update `GameConfig.BASE_STATS` Sentinel entry to `{ "health": 140, "attack": 8, "defense": 20, "speed": 5, "utility": 8 }`
  - _Ticket ref: FR-018, AC-019_
  - _File: `src/models/game_config.gd`_
  - _DEV-001: Changing from TASK-003 values (130/10/20/6/7) to TASK-006 spec (140/8/20/5/8)_

### 1.2 Add New Constants

- [ ] **1.2.1** Add `XP_CURVE` constant to `game_config.gd`: `{ "BASE_XP": 100, "GROWTH_RATE": 1.15 }`
  - _Ticket ref: FR-028, AC-050_
  - _File: `src/models/game_config.gd`_
  - _Location: After the `XP_PER_TIER` block in the §4.3 section_

- [ ] **1.2.2** Add `STAT_KEYS` constant to `game_config.gd`: `["health", "attack", "defense", "speed", "utility"]`
  - _Ticket ref: Section 16.1 (used by from_dict stat validation)_
  - _File: `src/models/game_config.gd`_
  - _Type: `const STAT_KEYS: Array[String]`_

- [ ] **1.2.3** Add `EQUIP_SLOT_KEYS` constant to `game_config.gd`: `["weapon", "armor", "accessory"]`
  - _Ticket ref: Section 16.1 (used by from_dict equipment validation)_
  - _File: `src/models/game_config.gd`_
  - _Type: `const EQUIP_SLOT_KEYS: Array[String]`_

### 1.3 Verify Existing Tests Still Pass

- [ ] **1.3.1** Run existing test suite to confirm no regressions from BASE_STATS value changes
  - _Run: Full regression test command (see Build & Verification Commands)_
  - _Expected: All existing tests pass. TASK-003 tests only check structure, not specific non-Warrior values._

### Phase 1 Validation Gate

- [ ] **1.V.1** `GameConfig.XP_CURVE` exists with `BASE_XP = 100` and `GROWTH_RATE = 1.15`
- [ ] **1.V.2** `GameConfig.STAT_KEYS` exists as `Array[String]` with 5 entries
- [ ] **1.V.3** `GameConfig.EQUIP_SLOT_KEYS` exists as `Array[String]` with 3 entries
- [ ] **1.V.4** `GameConfig.BASE_STATS` has updated values matching TASK-006 ticket for all 6 classes
- [ ] **1.V.5** All existing tests still pass (regression gate)
- [ ] **1.V.6** Commit: `"Phase 1: Add XP_CURVE, STAT_KEYS, EQUIP_SLOT_KEYS to GameConfig; update BASE_STATS to TASK-006 spec"`

---

## Phase 2: AdventurerData Scaffold + Property Defaults + Base Stats Init (TDD)

> **Ticket References**: FR-001–FR-011, FR-013–FR-020, AC-001–AC-021
> **Estimated Items**: 12
> **Dependencies**: Phase 1 complete (GameConfig has all needed constants)
> **Validation Gate**: `adventurer_data.gd` exists with class declaration + 8 properties + `initialize_base_stats()`; test Sections A & B pass

### 2.1 Write Property Default Tests (RED)

- [ ] **2.1.1** Create `tests/models/test_adventurer_data.gd` with file header (`extends GutTest`) and helper functions `_create_adventurer()`, `_all_classes()`, `_expected_base_stats()`
  - _Ticket ref: Section 14.2 — helpers block_
  - _File: `tests/models/test_adventurer_data.gd`_
  - _⚠️ Use edit/create tool, NEVER PowerShell Set-Content (strips tabs)_

- [ ] **2.1.2** Add Section A tests: property default assertions
  - _Ticket ref: AC-004 through AC-012_
  - _Tests (9 functions):_
    - `test_new_instance_is_not_null` — `assert_not_null(AdventurerData.new())` — AC-004
    - `test_default_id_is_empty_string` — `assert_eq(adv.id, "")` — AC-005
    - `test_default_display_name_is_empty_string` — `assert_eq(adv.display_name, "")` — AC-006
    - `test_default_adventurer_class_is_warrior` — `assert_eq(adv.adventurer_class, Enums.AdventurerClass.WARRIOR)` — AC-007
    - `test_default_level_is_one` — `assert_eq(adv.level, 1)` — AC-008
    - `test_default_xp_is_zero` — `assert_eq(adv.xp, 0)` — AC-009
    - `test_default_is_available_is_true` — `assert_true(adv.is_available)` — AC-012
    - `test_default_equipment_has_three_null_slots` — `assert_eq(adv.equipment.size(), 3)` + null checks — AC-011
    - `test_default_stats_is_empty_dict` — `assert_eq(adv.stats, {})` — AC-010
  - _TDD: RED — tests reference `AdventurerData` which does not exist yet_

- [ ] **2.1.3** Add Section B tests: per-class base stat assertions
  - _Ticket ref: AC-013 through AC-021_
  - _Tests (11 functions):_
    - `test_warrior_base_stats` — verifies `{ health:120, attack:18, defense:15, speed:8, utility:5 }` — AC-014
    - `test_ranger_base_stats` — verifies `{ health:85, attack:14, defense:8, speed:18, utility:10 }` — AC-015
    - `test_mage_base_stats` — verifies `{ health:70, attack:12, defense:6, speed:10, utility:20 }` — AC-016
    - `test_rogue_base_stats` — verifies `{ health:80, attack:15, defense:7, speed:16, utility:14 }` — AC-017
    - `test_alchemist_base_stats` — verifies `{ health:90, attack:10, defense:10, speed:12, utility:18 }` — AC-018
    - `test_sentinel_base_stats` — verifies `{ health:140, attack:8, defense:20, speed:5, utility:8 }` — AC-019
    - `test_all_classes_have_five_stat_keys` — iterates all classes, asserts 5 keys — AC-013, FR-019
    - `test_all_classes_have_positive_stat_values` — iterates all classes, asserts all > 0 — AC-020, FR-020
    - `test_each_class_has_distinct_stat_distribution` — no two classes share identical stats
    - `test_game_config_base_stats_has_six_entries` — `assert_eq(GameConfig.BASE_STATS.size(), 6)` — AC-021
    - `test_initialize_base_stats_without_class_set_uses_warrior` — verifies default fallback
  - _TDD: RED — `AdventurerData` class does not exist yet_

### 2.2 Implement AdventurerData Scaffold (GREEN)

- [ ] **2.2.1** Create `src/models/adventurer_data.gd` with class declaration
  - _Ticket ref: FR-001, FR-002, AC-001, AC-002, AC-003_
  - _File: `src/models/adventurer_data.gd`_
  - _Content: `class_name AdventurerData` + `extends RefCounted` + class doc comment_
  - _⚠️ Use create tool, NEVER PowerShell Set-Content_

- [ ] **2.2.2** Add all 8 properties with typed declarations and defaults
  - _Ticket ref: FR-003 through FR-010_
  - _Properties:_
    - `var id: String = ""`
    - `var display_name: String = ""`
    - `var adventurer_class: Enums.AdventurerClass = Enums.AdventurerClass.WARRIOR`
    - `var level: int = 1`
    - `var xp: int = 0`
    - `var stats: Dictionary = {}`
    - `var equipment: Dictionary = { "weapon": null, "armor": null, "accessory": null }`
    - `var is_available: bool = true`

- [ ] **2.2.3** Add `initialize_base_stats() -> void` method
  - _Ticket ref: FR-011, AC-013_
  - _Behavior: Copies from `GameConfig.BASE_STATS[adventurer_class]` using `.duplicate(true)`_
  - _Fallback: If unknown class, `push_error()` and fall back to WARRIOR stats_

### 2.3 Run Tests (GREEN Verification)

- [ ] **2.3.1** Run GUT test suite — all Section A and Section B tests must pass
  - _Expected: ~21 tests pass (9 Section A + 11 Section B + helper functions)_
  - _Note: GUT auto-tracks `push_error()` — the fallback test that triggers `push_error()` needs `assert_push_error_count(1)` or ignore_count logic_

### Phase 2 Validation Gate

- [ ] **2.V.1** `src/models/adventurer_data.gd` exists and is parseable GDScript
- [ ] **2.V.2** File extends `RefCounted` and declares `class_name AdventurerData`
- [ ] **2.V.3** All 8 properties declared with correct types and defaults
- [ ] **2.V.4** `initialize_base_stats()` populates `stats` correctly for all 6 classes
- [ ] **2.V.5** All Section A + B tests pass green
- [ ] **2.V.6** Existing tests in `tests/models/test_enums_and_config.gd` still pass
- [ ] **2.V.7** Commit: `"Phase 2: AdventurerData scaffold — 8 properties, initialize_base_stats, 20 tests pass"`

---

## Phase 3: XP, Leveling & Level Tiers (TDD)

> **Ticket References**: FR-021–FR-036, AC-022–AC-038
> **Estimated Items**: 10
> **Dependencies**: Phase 2 complete (AdventurerData exists with properties)
> **Validation Gate**: `xp_to_next_level()`, `gain_xp()`, `get_level_tier()` all implemented and tested

### 3.1 Write XP & Leveling Tests (RED)

- [ ] **3.1.1** Add Section C tests to `test_adventurer_data.gd`: XP-to-next-level calculation
  - _Ticket ref: FR-026, FR-027, AC-022, AC-023_
  - _Tests (7 functions):_
    - `test_xp_to_next_level_at_level_1` — asserts 100 — AC-022
    - `test_xp_to_next_level_at_level_2` — asserts 115 — AC-023
    - `test_xp_to_next_level_at_level_5` — asserts `int(100 * pow(1.15, 4))` — FR-027
    - `test_xp_to_next_level_at_level_10` — asserts `int(100 * pow(1.15, 9))` — FR-027
    - `test_xp_to_next_level_at_level_15` — asserts `int(100 * pow(1.15, 14))` — FR-027
    - `test_xp_to_next_level_always_positive` — loop levels 1–49, all > 0 — FR-027
    - `test_xp_to_next_level_increases_with_level` — monotonically increasing through 29 levels — FR-027
  - _TDD: RED — `xp_to_next_level()` method does not exist yet_

- [ ] **3.1.2** Add Section D tests to `test_adventurer_data.gd`: gain_xp & level-up
  - _Ticket ref: FR-021–FR-025, FR-029, FR-030, AC-024–AC-030_
  - _Tests (10 functions):_
    - `test_gain_xp_no_levelup` — 50 XP on L1 → xp=50, level=1, returns false — AC-024
    - `test_gain_xp_exact_levelup` — 100 XP on L1 → level=2, xp=0, returns true — AC-025
    - `test_gain_xp_with_remainder` — 130 XP on L1 → level=2, xp=30, returns true — FR-029
    - `test_gain_xp_multi_levelup` — 250 XP on L1 → level=3, xp=35, returns true — AC-026, FR-024
    - `test_gain_xp_zero_returns_false` — 0 XP → no change, returns false — AC-027, FR-025
    - `test_gain_xp_negative_returns_false` — -10 XP → no change, returns false — AC-028, FR-025
    - `test_gain_xp_large_amount_many_levels` — 5000 XP → level>10, xp in valid range — FR-024
    - `test_gain_xp_accumulates_across_calls` — two 50 XP calls → level 2 — FR-022
    - `test_level_never_decreases` — 20 random gain_xp calls, level monotonic — AC-030, FR-030
    - `test_xp_remainder_always_valid_after_gain` — 50 random calls, 0 ≤ xp < threshold — AC-029

- [ ] **3.1.3** Add Section E tests to `test_adventurer_data.gd`: level tier boundaries
  - _Ticket ref: FR-031–FR-035, AC-031–AC-038_
  - _Tests (9 functions):_
    - `test_tier_novice_level_1` — NOVICE — AC-031
    - `test_tier_novice_level_5` — NOVICE — AC-032
    - `test_tier_skilled_level_6` — SKILLED — AC-033
    - `test_tier_skilled_level_10` — SKILLED — AC-034
    - `test_tier_veteran_level_11` — VETERAN — AC-035
    - `test_tier_veteran_level_15` — VETERAN — AC-036
    - `test_tier_elite_level_16` — ELITE — AC-037
    - `test_tier_elite_level_99` — ELITE — AC-038
    - `test_tier_transitions_through_levelup` — verifies all 4 tiers in sequence — FR-031

### 3.2 Implement XP, Leveling & Tier Methods (GREEN)

- [ ] **3.2.1** Add `xp_to_next_level() -> int` method to `adventurer_data.gd`
  - _Ticket ref: FR-026, FR-027_
  - _Formula: `int(GameConfig.XP_CURVE["BASE_XP"] * pow(GameConfig.XP_CURVE["GROWTH_RATE"], level - 1))`_
  - _File: `src/models/adventurer_data.gd`_

- [ ] **3.2.2** Add `gain_xp(amount: int) -> bool` method to `adventurer_data.gd`
  - _Ticket ref: FR-021–FR-025, FR-029_
  - _Guard: `if amount <= 0: return false`_
  - _While loop: `while xp >= xp_to_next_level(): xp -= xp_to_next_level(); level += 1; leveled_up = true`_
  - _File: `src/models/adventurer_data.gd`_

- [ ] **3.2.3** Add `get_level_tier() -> Enums.LevelTier` method to `adventurer_data.gd`
  - _Ticket ref: FR-031–FR-035_
  - _Cascading if-elif: `>= 16` → ELITE, `>= 11` → VETERAN, `>= 6` → SKILLED, else NOVICE_
  - _File: `src/models/adventurer_data.gd`_

### 3.3 Run Tests (GREEN Verification)

- [ ] **3.3.1** Run GUT test suite — all Section C, D, E tests must pass
  - _Expected: ~26 new tests pass (7 + 10 + 9), plus prior phases_

### Phase 3 Validation Gate

- [ ] **3.V.1** `xp_to_next_level()` returns correct values at levels 1, 2, 5, 10, 15
- [ ] **3.V.2** `gain_xp()` handles zero, negative, single, multi-level-up, large amount
- [ ] **3.V.3** `get_level_tier()` returns correct tier at boundaries 1, 5, 6, 10, 11, 15, 16, 99
- [ ] **3.V.4** All Section C + D + E tests pass green
- [ ] **3.V.5** All prior phase tests still pass
- [ ] **3.V.6** Commit: `"Phase 3: XP curve, gain_xp, level tiers — 26 new tests pass"`

---

## Phase 4: Effective Stats + Serialization (TDD)

> **Ticket References**: FR-037–FR-048, AC-039–AC-051
> **Estimated Items**: 12
> **Dependencies**: Phase 3 complete (all core logic methods exist)
> **Validation Gate**: `get_effective_stats()`, `to_dict()`, `from_dict()` all implemented and tested

### 4.1 Write Effective Stats Tests (RED)

- [ ] **4.1.1** Add Section F tests to `test_adventurer_data.gd`: effective stats
  - _Ticket ref: FR-037–FR-040, AC-039–AC-041_
  - _Tests (3 functions):_
    - `test_effective_stats_returns_dictionary_with_five_keys` — 5 keys present — AC-039
    - `test_effective_stats_equals_base_stats_without_equipment` — all classes match base — AC-041, FR-039
    - `test_effective_stats_returns_deep_copy` — mutate returned dict, base unchanged — AC-040, FR-038

### 4.2 Implement Effective Stats (GREEN)

- [ ] **4.2.1** Add `get_effective_stats() -> Dictionary` method to `adventurer_data.gd`
  - _Ticket ref: FR-037–FR-040_
  - _Returns `stats.duplicate(true)` — placeholder for TASK-014 equipment bonuses_
  - _File: `src/models/adventurer_data.gd`_

### 4.3 Write Serialization Tests (RED)

- [ ] **4.3.1** Add Section G tests to `test_adventurer_data.gd`: to_dict()
  - _Ticket ref: FR-041–FR-043, FR-048, AC-042, AC-043, AC-047_
  - _Tests (5 functions):_
    - `test_to_dict_contains_all_keys` — 8 keys present — AC-042
    - `test_to_dict_serializes_class_as_int` — `typeof == TYPE_INT` — AC-043, FR-042
    - `test_to_dict_preserves_all_values` — Rogue at level 7, xp 55, unavailable — FR-041
    - `test_to_dict_equipment_uses_string_keys` — "weapon", "armor", "accessory" — FR-043
    - `test_to_dict_is_json_compatible` — `JSON.stringify()` + `JSON.parse_string()` — AC-047, FR-048

- [ ] **4.3.2** Add Section H tests to `test_adventurer_data.gd`: from_dict() round-trip
  - _Ticket ref: FR-044–FR-047, AC-044–AC-048_
  - _Tests (7 functions):_
    - `test_round_trip_all_classes` — all 6 classes at level 8, xp 42, unavailable — AC-044, FR-046
    - `test_from_dict_restores_correct_types` — Alchemist at level 12, xp 200, type checks — FR-045
    - `test_from_dict_missing_keys_uses_defaults` — partial dict `{ "id": "partial-hero" }` — AC-045, FR-047
    - `test_from_dict_empty_dict_no_crash` — `from_dict({})` returns valid instance — FR-047
    - `test_from_dict_invalid_class_defaults_to_warrior` — class=99 → WARRIOR — AC-046
    - `test_from_dict_extra_keys_are_ignored` — extra keys not in output — AC-048
    - `test_from_dict_json_round_trip` — Sentinel L16 through JSON.stringify → parse_string → from_dict — FR-048

- [ ] **4.3.3** Add Section I tests to `test_adventurer_data.gd`: GameConfig constants
  - _Ticket ref: AC-049, AC-050, AC-051_
  - _Tests (3 functions):_
    - `test_game_config_base_stats_exists` — not null, is Dictionary — AC-049
    - `test_game_config_xp_curve_exists` — BASE_XP=100, GROWTH_RATE=1.15 — AC-050
    - `test_game_config_xp_per_tier_exists` — NOVICE:0, SKILLED:100, VETERAN:350, ELITE:750 — AC-051

### 4.4 Implement Serialization (GREEN)

- [ ] **4.4.1** Add `to_dict() -> Dictionary` method to `adventurer_data.gd`
  - _Ticket ref: FR-041–FR-043, FR-048_
  - _Serializes: id, display_name, int(adventurer_class), level, xp, stats.duplicate(true), equipment.duplicate(true), is_available_
  - _File: `src/models/adventurer_data.gd`_

- [ ] **4.4.2** Add `static from_dict(data: Dictionary) -> AdventurerData` method to `adventurer_data.gd`
  - _Ticket ref: FR-044–FR-047_
  - _Defensive: All fields via `data.get(key, default)`. All numerics cast to `int()`._
  - _Validation: adventurer_class range check → default WARRIOR + push_error. Level clamped ≥ 1. XP clamped ≥ 0._
  - _Stats validation: Iterates `GameConfig.STAT_KEYS`, uses base value for missing keys._
  - _Equipment: Only reads `GameConfig.EQUIP_SLOT_KEYS`. Extra keys silently dropped._
  - _File: `src/models/adventurer_data.gd`_
  - _⚠️ `from_dict()` calls `push_error()` for invalid class — test must account for GUT's auto-tracking via `assert_push_error_count()` or wrapped in `push_error` counting_

### 4.5 Run Tests (GREEN Verification)

- [ ] **4.5.1** Run GUT test suite — all Section F, G, H, I tests must pass
  - _Expected: ~18 new tests pass (3 + 5 + 7 + 3), plus all prior phases_

### Phase 4 Validation Gate

- [ ] **4.V.1** `get_effective_stats()` returns deep copy matching base stats for all 6 classes
- [ ] **4.V.2** `to_dict()` produces correct dictionary with 8 keys, class as int, string equipment keys
- [ ] **4.V.3** `from_dict(to_dict(x)).to_dict() == x.to_dict()` for all 6 classes
- [ ] **4.V.4** `from_dict({})` does not crash, returns valid defaults
- [ ] **4.V.5** `from_dict()` with invalid class defaults to WARRIOR
- [ ] **4.V.6** `to_dict()` output is JSON-serializable
- [ ] **4.V.7** All Section F + G + H + I tests pass green
- [ ] **4.V.8** All prior phase tests still pass
- [ ] **4.V.9** Commit: `"Phase 4: Effective stats + serialization round-trip — 18 new tests pass"`

---

## Phase 5: Edge Cases, Stress Tests & Final Validation (TDD)

> **Ticket References**: Section 14.2 Sections J, plus cross-cutting ACs
> **Estimated Items**: 9
> **Dependencies**: Phase 4 complete (all methods implemented)
> **Validation Gate**: ALL tests pass, full regression green, code quality checks

### 5.1 Write Edge Case & Stress Tests (RED → GREEN)

- [ ] **5.1.1** Add Section J tests to `test_adventurer_data.gd`: edge cases & stress
  - _Ticket ref: Section 14.2 Section J, Threat 1–4 from Section 10_
  - _Tests (6 functions):_
    - `test_gain_xp_from_high_level` — L50 + exact threshold → L51, xp=0 — Stress
    - `test_many_small_xp_gains` — 100 × gain_xp(1) → L2, xp=0 — Stress, FR-022
    - `test_availability_toggle` — true → false → true — FR-010
    - `test_equipment_slot_assignment` — set weapon/armor/accessory to strings — FR-009
    - `test_equipment_survives_serialization` — set weapon, round-trip, verify — FR-046
    - `test_from_dict_json_round_trip_is_covered_in_phase_4` — (verify it exists; if not, add)

### 5.2 Code Quality Verification

- [ ] **5.2.1** Verify `adventurer_data.gd` has no `@onready`, `@export`, or `signal` declarations
  - _Ticket ref: AC-055, NFR-014_
  - _Method: Search file for these keywords_

- [ ] **5.2.2** Verify all properties have explicit type hints
  - _Ticket ref: AC-052_

- [ ] **5.2.3** Verify all method parameters and return types have explicit type hints
  - _Ticket ref: AC-053, AC-054_

- [ ] **5.2.4** Verify no magic numbers — all constants reference `GameConfig`
  - _Ticket ref: AC-056, NFR-017_
  - _Check: No hardcoded `100`, `1.15`, `16`, `11`, `6` in the model file (tier boundaries 16/11/6 are the one exception — the ticket explicitly uses literals in `get_level_tier()` per Section 8.5)_

- [ ] **5.2.5** Verify file is under 200 LOC (excluding blank lines and comments)
  - _Ticket ref: AC-057, NFR-018_

### 5.3 Full Regression Test

- [ ] **5.3.1** Run the complete GUT test suite including ALL test directories
  - _Command:_
    ```
    & "C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --path "C:\Users\wrstl\source\dev-agent-tool" --headless -s "res://addons/gut/gut_cmdln.gd" -gdir="res://tests/" -ginclude_subdirs
    ```
  - _Expected: ALL tests pass — new and existing_
  - _Note: May need `--import` first if Godot hasn't indexed new files_

### Phase 5 Validation Gate

- [ ] **5.V.1** All Section J edge case tests pass green
- [ ] **5.V.2** Code quality checks pass (type hints, no magic numbers, no @export/@onready/signal)
- [ ] **5.V.3** File is under 200 LOC
- [ ] **5.V.4** Full regression suite passes (all test directories)
- [ ] **5.V.5** Commit: `"Phase 5: Edge cases, code quality verified — ALL tests pass"`

---

## Phase Dependency Graph

```
Phase 0 (Pre-flight)
   │
   ▼
Phase 1 (GameConfig additions + BASE_STATS update)
   │
   ▼
Phase 2 (AdventurerData scaffold + properties + initialize_base_stats)
   │
   ▼
Phase 3 (XP curve + gain_xp + level tiers)
   │
   ▼
Phase 4 (Effective stats + to_dict + from_dict)
   │
   ▼
Phase 5 (Edge cases + code quality + full regression)
```

All phases are **strictly sequential** — each depends on the previous. No parallelism possible because the model builds incrementally and tests reference all prior methods.

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 0 | Pre-Flight Verification | 7 | 0 | 0 | ⬜ Not Started |
| Phase 1 | GameConfig Additions | 8 | 0 | 0 | ⬜ Not Started |
| Phase 2 | AdventurerData Scaffold + Base Stats | 12 | 0 | ~21 | ⬜ Not Started |
| Phase 3 | XP, Leveling & Level Tiers | 10 | 0 | ~26 | ⬜ Not Started |
| Phase 4 | Effective Stats + Serialization | 12 | 0 | ~18 | ⬜ Not Started |
| Phase 5 | Edge Cases & Final Validation | 9 | 0 | ~6 | ⬜ Not Started |
| **Total** | | **58** | **0** | **~71** | **⬜ Phase 0 Next** |

---

## File Change Summary

### New Files

| File | Phase | Purpose |
|------|-------|---------|
| `src/models/adventurer_data.gd` | 2 | AdventurerData class — RefCounted model with 8 properties, init, XP, tier, stats, serialization |
| `tests/models/test_adventurer_data.gd` | 2–5 | GUT test suite — ~71 tests across 10 sections (A through J) |

### Modified Files

| File | Phase | Change |
|------|-------|--------|
| `src/models/game_config.gd` | 1 | Update BASE_STATS for 4 classes (Ranger, Rogue, Alchemist, Sentinel); add XP_CURVE, STAT_KEYS, EQUIP_SLOT_KEYS constants |

### Deleted Files

None.

---

## Commit Strategy

| Phase | Commit Message | Cumulative Tests |
|-------|----------------|------------------|
| 0 | _(no code changes — verification only)_ | Existing baseline |
| 1 | `"Phase 1: Add XP_CURVE, STAT_KEYS, EQUIP_SLOT_KEYS to GameConfig; update BASE_STATS to TASK-006 spec"` | Existing baseline |
| 2 | `"Phase 2: AdventurerData scaffold — 8 properties, initialize_base_stats, ~21 tests"` | ~21 new |
| 3 | `"Phase 3: XP curve, gain_xp, level tiers — ~26 new tests"` | ~47 cumulative |
| 4 | `"Phase 4: Effective stats + serialization round-trip — ~18 new tests"` | ~65 cumulative |
| 5 | `"Phase 5: Edge cases, code quality verified — ~71 total tests, ALL pass"` | ~71 total |

---

## Deviations from Ticket

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| DEV-001 | 1 | Update existing `BASE_STATS` in `game_config.gd` to match TASK-006 spec — Ranger, Rogue, Alchemist, Sentinel values differ from TASK-003 originals | FR-014–FR-018, Section 2.5 | TASK-006 is the authoritative adventurer spec. TASK-003 values were placeholder. Existing tests only check structure, not specific values for these classes. | **Low** — No existing tests assert specific stat values for non-Warrior classes. TASK-004/005 models don't use BASE_STATS. |
| DEV-002 | 1 | GameConfig file is at `src/models/game_config.gd`, NOT `src/config/game_config.gd` as ticket Section 16.1 states | Section 16.1 | Ticket assumed a different project layout. The file was created by TASK-003 at the actual path. | **None** — We use the actual path. |
| DEV-003 | All | GameConfig is NOT an autoload — it uses `class_name GameConfig` (no `extends Node`) | Section 16.1, Glossary #15 | Godot 4.6.1: `class_name` on autoload scripts causes "Class X hides autoload" error. The existing pattern avoids this. Tests access it directly as `GameConfig.CONSTANT`. | **None** — Functionally identical. `class_name` gives global access without autoload. |
| DEV-004 | 2 | `stats` default is `{}` (empty Dictionary), not class-specific stats | FR-008, AC-010 | The ticket specifies default is empty dict; `initialize_base_stats()` must be called to populate. This matches the ticket's UC-01 flow. | **None** — Matches ticket intent. |
| DEV-005 | 3 | `get_level_tier()` uses hardcoded boundary literals (16, 11, 6) instead of GameConfig lookups | FR-031, Section 8.5, AC-056 | The ticket explicitly designs this as a cascading if-elif with literal values (Section 8.5). This is an intentional exception to the "no magic numbers" rule. | **None** — Ticket explicitly chose this approach. |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| BASE_STATS update breaks downstream tests | Low | Medium | Verified: existing TASK-003 tests only check structure, not specific stat values. Run full regression after Phase 1. | 1 |
| `from_dict()` push_error triggers GUT auto-tracking failure | Medium | Low | Use `assert_push_error_count()` in tests that intentionally trigger errors (invalid class test). | 4 |
| JSON float-to-int conversion breaks round-trip | Medium | Medium | `from_dict()` casts all numeric fields to `int()` explicitly. Round-trip test verifies through JSON.stringify → parse_string → from_dict. | 4 |
| PowerShell Set-Content strips GDScript tabs | High | High | NEVER use PowerShell Set-Content for .gd files. Always use edit/create tool. | All |
| GUT requires --import for new files | Medium | Low | Run `--import` before first test run after creating new .gd files. | 2 |
| `xp_to_next_level()` int truncation at very high levels | Low | Low | Acceptable for gameplay. Level 50 threshold is ~86K, well within int range. Tested in edge case phase. | 3, 5 |

---

## Handoff State (Initial)

### What's Complete
- Nothing yet — plan created, ready for Phase 0.

### What's In Progress
- Nothing.

### What's Blocked
- Nothing.

### Next Steps
1. Begin Phase 0: Pre-flight verification
2. Verify all TASK-003 dependencies are present
3. Confirm BASE_STATS mismatch findings
4. Proceed to Phase 1: GameConfig additions

---

## Test Function Reference (All ~71 Tests)

Complete listing of every test function that will exist in `tests/models/test_adventurer_data.gd`, organized by section:

### Section A: Construction & Default Values (9 tests)
| # | Function | Asserts | AC/FR |
|---|----------|---------|-------|
| 1 | `test_new_instance_is_not_null` | `assert_not_null(AdventurerData.new())` | AC-004 |
| 2 | `test_default_id_is_empty_string` | `assert_eq(adv.id, "")` | AC-005 |
| 3 | `test_default_display_name_is_empty_string` | `assert_eq(adv.display_name, "")` | AC-006 |
| 4 | `test_default_adventurer_class_is_warrior` | `assert_eq(adv.adventurer_class, Enums.AdventurerClass.WARRIOR)` | AC-007 |
| 5 | `test_default_level_is_one` | `assert_eq(adv.level, 1)` | AC-008 |
| 6 | `test_default_xp_is_zero` | `assert_eq(adv.xp, 0)` | AC-009 |
| 7 | `test_default_is_available_is_true` | `assert_true(adv.is_available)` | AC-012 |
| 8 | `test_default_equipment_has_three_null_slots` | `assert_eq(size, 3)` + 3 null checks | AC-011 |
| 9 | `test_default_stats_is_empty_dict` | `assert_eq(adv.stats, {})` | AC-010 |

### Section B: Base Stats Initialization (11 tests)
| # | Function | Asserts | AC/FR |
|---|----------|---------|-------|
| 10 | `test_warrior_base_stats` | Full stat dict equality | AC-014 |
| 11 | `test_ranger_base_stats` | Full stat dict equality | AC-015 |
| 12 | `test_mage_base_stats` | Full stat dict equality | AC-016 |
| 13 | `test_rogue_base_stats` | Full stat dict equality | AC-017 |
| 14 | `test_alchemist_base_stats` | Full stat dict equality | AC-018 |
| 15 | `test_sentinel_base_stats` | Full stat dict equality | AC-019 |
| 16 | `test_all_classes_have_five_stat_keys` | Loop 6 classes × 5 key checks | AC-013, FR-019 |
| 17 | `test_all_classes_have_positive_stat_values` | Loop 6 classes × 5 asserts | AC-020, FR-020 |
| 18 | `test_each_class_has_distinct_stat_distribution` | No two stats dicts equal | — |
| 19 | `test_game_config_base_stats_has_six_entries` | `assert_eq(size, 6)` | AC-021 |
| 20 | `test_initialize_base_stats_without_class_set_uses_warrior` | Default class → WARRIOR stats | UC-01 |

### Section C: XP-to-Next-Level Calculation (7 tests)
| # | Function | Asserts | AC/FR |
|---|----------|---------|-------|
| 21 | `test_xp_to_next_level_at_level_1` | `assert_eq(result, 100)` | AC-022 |
| 22 | `test_xp_to_next_level_at_level_2` | `assert_eq(result, 115)` | AC-023 |
| 23 | `test_xp_to_next_level_at_level_5` | `assert_eq(result, int(100*pow(1.15,4)))` | FR-027 |
| 24 | `test_xp_to_next_level_at_level_10` | `assert_eq(result, int(100*pow(1.15,9)))` | FR-027 |
| 25 | `test_xp_to_next_level_at_level_15` | `assert_eq(result, int(100*pow(1.15,14)))` | FR-027 |
| 26 | `test_xp_to_next_level_always_positive` | Loop 1–49, all > 0 | FR-027 |
| 27 | `test_xp_to_next_level_increases_with_level` | Monotonic through 29 levels | FR-027 |

### Section D: Gain XP & Level-Up (10 tests)
| # | Function | Asserts | AC/FR |
|---|----------|---------|-------|
| 28 | `test_gain_xp_no_levelup` | xp=50, level=1, returns false | AC-024 |
| 29 | `test_gain_xp_exact_levelup` | level=2, xp=0, returns true | AC-025 |
| 30 | `test_gain_xp_with_remainder` | level=2, xp=30 | FR-029 |
| 31 | `test_gain_xp_multi_levelup` | level=3, xp=35 | AC-026 |
| 32 | `test_gain_xp_zero_returns_false` | No change | AC-027 |
| 33 | `test_gain_xp_negative_returns_false` | No change | AC-028 |
| 34 | `test_gain_xp_large_amount_many_levels` | level>10, valid xp range | FR-024 |
| 35 | `test_gain_xp_accumulates_across_calls` | Two 50s → level 2 | FR-022 |
| 36 | `test_level_never_decreases` | 20 random calls, monotonic | AC-030 |
| 37 | `test_xp_remainder_always_valid_after_gain` | 50 random calls, valid range | AC-029 |

### Section E: Level Tier (9 tests)
| # | Function | Asserts | AC/FR |
|---|----------|---------|-------|
| 38 | `test_tier_novice_level_1` | NOVICE | AC-031 |
| 39 | `test_tier_novice_level_5` | NOVICE | AC-032 |
| 40 | `test_tier_skilled_level_6` | SKILLED | AC-033 |
| 41 | `test_tier_skilled_level_10` | SKILLED | AC-034 |
| 42 | `test_tier_veteran_level_11` | VETERAN | AC-035 |
| 43 | `test_tier_veteran_level_15` | VETERAN | AC-036 |
| 44 | `test_tier_elite_level_16` | ELITE | AC-037 |
| 45 | `test_tier_elite_level_99` | ELITE | AC-038 |
| 46 | `test_tier_transitions_through_levelup` | All 4 tiers in sequence | FR-031 |

### Section F: Effective Stats (3 tests)
| # | Function | Asserts | AC/FR |
|---|----------|---------|-------|
| 47 | `test_effective_stats_returns_dictionary_with_five_keys` | 5 keys present | AC-039 |
| 48 | `test_effective_stats_equals_base_stats_without_equipment` | All classes match base | AC-041 |
| 49 | `test_effective_stats_returns_deep_copy` | Mutate copy, base unchanged | AC-040 |

### Section G: Serialization — to_dict() (5 tests)
| # | Function | Asserts | AC/FR |
|---|----------|---------|-------|
| 50 | `test_to_dict_contains_all_keys` | 8 keys present | AC-042 |
| 51 | `test_to_dict_serializes_class_as_int` | TYPE_INT check | AC-043 |
| 52 | `test_to_dict_preserves_all_values` | Rogue L7 xp55 values | FR-041 |
| 53 | `test_to_dict_equipment_uses_string_keys` | "weapon"/"armor"/"accessory" | FR-043 |
| 54 | `test_to_dict_is_json_compatible` | stringify + parse succeeds | AC-047 |

### Section H: Serialization — from_dict() Round-Trip (7 tests)
| # | Function | Asserts | AC/FR |
|---|----------|---------|-------|
| 55 | `test_round_trip_all_classes` | 6 classes lossless | AC-044 |
| 56 | `test_from_dict_restores_correct_types` | Alchemist L12, type checks | FR-045 |
| 57 | `test_from_dict_missing_keys_uses_defaults` | Partial dict defaults | AC-045 |
| 58 | `test_from_dict_empty_dict_no_crash` | `from_dict({})` works | FR-047 |
| 59 | `test_from_dict_invalid_class_defaults_to_warrior` | class=99 → WARRIOR | AC-046 |
| 60 | `test_from_dict_extra_keys_are_ignored` | Extra keys stripped | AC-048 |
| 61 | `test_from_dict_json_round_trip` | Sentinel L16 full JSON cycle | FR-048 |

### Section I: GameConfig Constants (3 tests)
| # | Function | Asserts | AC/FR |
|---|----------|---------|-------|
| 62 | `test_game_config_base_stats_exists` | Not null, is Dictionary | AC-049 |
| 63 | `test_game_config_xp_curve_exists` | BASE_XP=100, GROWTH_RATE=1.15 | AC-050 |
| 64 | `test_game_config_xp_per_tier_exists` | All 4 tier values | AC-051 |

### Section J: Edge Cases & Stress (6 tests)
| # | Function | Asserts | AC/FR |
|---|----------|---------|-------|
| 65 | `test_gain_xp_from_high_level` | L50→L51, xp=0 | Stress |
| 66 | `test_many_small_xp_gains` | 100×1 → L2, xp=0 | FR-022 |
| 67 | `test_availability_toggle` | true→false→true | FR-010 |
| 68 | `test_equipment_slot_assignment` | Set 3 slots, verify | FR-009 |
| 69 | `test_equipment_survives_serialization` | Round-trip with equipment | FR-046 |

**Total: 69 tests** (+ 2 helper functions that aren't tests)

---

## Full Regression Test Command

Run this **before Phase 0** (baseline) and **after every phase**:

```powershell
& "C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --path "C:\Users\wrstl\source\dev-agent-tool" --headless -s "res://addons/gut/gut_cmdln.gd" -gdir="res://tests/" -ginclude_subdirs
```

If Godot reports errors about unknown classes after creating new files, run import first:

```powershell
& "C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --path "C:\Users\wrstl\source\dev-agent-tool" --headless --import
```

---

*End of TASK-006 Implementation Plan*
