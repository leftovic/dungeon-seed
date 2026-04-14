# TASK-003: Enums, Constants & Data Dictionary — Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-003-enums-constants.md`
> **GDD**: `neil-docs/epics/dungeon-seed/GDD-v2.md`
> **Status**: Planning
> **Created**: 2025-07-18
> **Repo**: `dev-agent-tool` (local — `C:\Users\wrstl\source\dev-agent-tool`)
> **Methodology**: TDD Red-Green-Refactor (mandatory for all phases)
> **Complexity**: 3 points (Trivial) — Fibonacci
> **Estimated Phases**: 5 (Phase 0–4)
> **Estimated Checkboxes**: ~55
> **⚠️ CRITICAL PATH**: 5 Wave 2 tasks (TASK-004 through TASK-008) are **blocked** until this task merges.

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents in this order:

1. **This file** (you're reading it) — the phased checklist of what to do, with status
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-003-enums-constants.md`** — the full technical spec with exact code to implement
3. **`neil-docs/epics/dungeon-seed/GDD-v2.md`** — the Game Design Document for understanding domain context
4. **`src/models/enums.gd`** — target file #1 (does NOT exist yet — you will create it)
5. **`src/models/game_config.gd`** — target file #2 (does NOT exist yet — you will create it)

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| Target source file #1 | `src/models/enums.gd` | **NEW** — `Enums` class (10 enums + 5 helper methods) |
| Target source file #2 | `src/models/game_config.gd` | **NEW** — `GameConfig` class (9 const dictionaries + 7 helper methods) |
| Test file | `tests/models/test_enums_and_config.gd` | **NEW** — 51 GUT test functions |
| Models directory | `src/models/` | **SHOULD EXIST** from TASK-001 |
| Test models directory | `tests/models/` | **MAY EXIST** from TASK-002 |
| GUT addon | `addons/gut/` | **PRE-REQUISITE** — GUT must be available for test execution |

### Key Concepts (5-minute primer)

- **enum**: GDScript enumeration — `enum Foo { A, B, C }` assigns A=0, B=1, C=2. Provides type safety and IDE autocomplete.
- **const**: GDScript compile-time constant. Cannot be reassigned at runtime. Dictionaries declared `const` have immutable structure.
- **class_name**: GDScript directive that registers a script as a globally accessible type. `class_name Enums` allows any script to reference `Enums.SeedRarity` without `preload()`.
- **RefCounted**: Godot's default base class for scripts without `extends`. Reference-counted, garbage-collected. Both files implicitly extend this.
- **Dictionary keyed by enum**: `const FOO: Dictionary = { Enums.Bar.A: 10 }` — type-safe lookup, no string comparison overhead.
- **Color**: Godot's built-in color type. Constructed via `Color(r, g, b)` with floats 0.0–1.0.
- **GUT**: Godot Unit Testing framework. Tests extend `GutTest` and use `assert_*` methods.
- **Critical path**: TASK-003 blocks 5 downstream tasks. Every day this is delayed, 5 Wave 2 tasks cannot begin.

### Build & Verification Commands

```powershell
# There is no CLI build for GDScript — verification is done in-editor.
# However, you can verify script syntax via headless Godot:

# Open project in editor (manual)
# Press F5 to run — should launch to main_menu.tscn

# Run GUT tests from within the editor:
#   1. Open GUT panel (bottom dock)
#   2. Click "Run All" — all tests must pass green

# Alternatively, run tests via command line (if Godot is on PATH):
# godot --headless -s addons/gut/gut_cmdln.gd -gdir=tests/models/ -gexit
```

### Regression Gate

Before AND after every phase:
1. `project.godot` must remain unchanged (this task does NOT modify it)
2. `src/scenes/main_menu.tscn` must still load correctly
3. No existing test files are broken by our changes
4. All new GUT tests pass green (once written and implementation complete)
5. No `class_name` conflicts with existing code

---

## Current State Analysis

### What Exists Today

| Item | Status | Location |
|------|--------|----------|
| `src/models/` directory | ✅ Should exist | Created by TASK-001 with `.gdkeep` |
| `tests/models/` directory | ✅ Should exist | Created by TASK-002 |
| `project.godot` | ✅ Exists | Engine config — NOT modified by this task |
| `tests/unit/` | ✅ Exists | v1 test directory — not used by this task |
| `addons/gut/` | ✅ Should exist | GUT addon — pre-requisite for testing |

### What's Missing (Gap Analysis)

| Item | Status | Required By |
|------|--------|-------------|
| `src/models/enums.gd` | ❌ Missing | FR-001 through FR-012, FR-023 |
| `src/models/game_config.gd` | ❌ Missing | FR-013 through FR-022, FR-024, FR-025 |
| `tests/models/test_enums_and_config.gd` | ❌ Missing | Section 14 — 51 test functions |

### What Must NOT Change

- `project.godot` — no modifications needed for this task (no autoload)
- `src/scenes/main_menu.tscn` — existing main menu scene
- `src/gdscript/` — v1 prototype code, explicitly out of scope
- `src/core/`, `src/Gateway/`, `src/Generators/` — non-GDScript project infrastructure
- Any existing files in `tests/unit/` — must not be broken
- Any files created by TASK-001 or TASK-002 (autoloads, rng.gd, etc.)

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
# Enum value checks
func test_seed_rarity_values() -> void:

# Enum count checks
func test_seed_rarity_count() -> void:

# Dictionary completeness
func test_base_growth_seconds_completeness() -> void:

# Dictionary value correctness
func test_base_growth_seconds_values() -> void:

# Helper method behavior
func test_seed_rarity_name_common() -> void:
```

### Test Structure (GUT)

Every test follows Arrange-Act-Assert:
```gdscript
func test_base_growth_seconds_values() -> void:
    # Act + Assert — verify const dictionary values directly
    assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.COMMON], 60)
    assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.UNCOMMON], 120)
    assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.RARE], 300)
    assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.EPIC], 600)
    assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.LEGENDARY], 1200)
```

### Coverage Requirements Per Phase

- ✅ **Enum existence**: All 10 enums declared with correct names
- ✅ **Enum values**: Every enum value has the expected integer assignment (0-based sequential)
- ✅ **Enum counts**: Each enum has the expected number of values
- ✅ **Dictionary completeness**: Every dictionary has an entry for every value of its keying enum
- ✅ **Dictionary correctness**: Specific values match GDD
- ✅ **Dictionary constraints**: Positive/non-negative/monotonic where required
- ✅ **Helper methods**: Return correct values for all inputs

---

## Phase 0: Pre-Flight & Directory Verification

> **Ticket References**: NFR-008 (file size), NFR-016 (no circular dependencies)
> **AC References**: AC-001, AC-012
> **Estimated Items**: 6
> **Dependencies**: TASK-001 complete (directory skeleton exists)
> **Validation Gate**: All prerequisite directories exist; no `class_name` conflicts; GUT available

This phase verifies prerequisites and creates any missing directories. No code is written yet.

### 0.1 Verify Prerequisites

- [ ] **0.1.1** Verify `src/models/` directory exists (created by TASK-001)
  - _Ticket ref: AC-001 (target directory for enums.gd)_
  - _If missing: create `src/models/` directory_
- [ ] **0.1.2** Verify `tests/models/` directory exists (may have been created by TASK-002)
  - _Ticket ref: Section 14 (test file location)_
  - _If missing: create `tests/models/` directory_
- [ ] **0.1.3** Search codebase for existing `class_name Enums` — must find zero results
  - _Ticket ref: FR-001, NFR-016 (no conflicts)_
  - _Command: `grep -r "class_name Enums" src/`_
- [ ] **0.1.4** Search codebase for existing `class_name GameConfig` — must find zero results
  - _Ticket ref: FR-013, NFR-016 (no conflicts)_
  - _Command: `grep -r "class_name GameConfig" src/`_
- [ ] **0.1.5** Verify GUT addon is available at `addons/gut/`
  - _Ticket ref: Assumption 15_
  - _If missing: note as blocker for test execution phases_
- [ ] **0.1.6** Verify no existing `tests/models/test_enums_and_config.gd` file that would be overwritten
  - _Ticket ref: Section 14_

### Phase 0 Validation Gate

- [ ] **0.V.1** `src/models/` directory exists
- [ ] **0.V.2** `tests/models/` directory exists
- [ ] **0.V.3** No `class_name Enums` conflict found in codebase
- [ ] **0.V.4** No `class_name GameConfig` conflict found in codebase
- [ ] **0.V.5** `project.godot` is unchanged (no edits in this phase)
- [ ] **0.V.6** Commit: `"Phase 0: Verify prerequisites for TASK-003 enums and config"`

---

## Phase 1: Test File (RED)

> **Ticket References**: Section 14 (all 51 test functions), FR-001 through FR-025
> **AC References**: AC-001 through AC-025 (tests cover all ACs)
> **Estimated Items**: 5
> **Dependencies**: Phase 0 complete (directories exist)
> **Validation Gate**: `tests/models/test_enums_and_config.gd` exists with 51 test functions; tests reference `Enums` and `GameConfig` which do not exist = RED

This phase writes the complete test file. All tests will fail because `Enums` and `GameConfig` do not exist yet.

### 1.1 Create Test File

- [ ] **1.1.1** Create `tests/models/test_enums_and_config.gd` with file header and `extends GutTest`
  - _Ticket ref: Section 14 — file header_
  - _File: `tests/models/test_enums_and_config.gd`_
  - _TDD: RED — file references `Enums` and `GameConfig` which do not exist_

- [ ] **1.1.2** Add Section A tests: enum existence and value tests (20 tests)
  - _Ticket ref: FR-001 through FR-012, AC-001 through AC-011_
  - _File: `tests/models/test_enums_and_config.gd`_
  - _Tests: `test_seed_rarity_values`, `test_seed_rarity_count`, `test_element_values`, `test_element_count`, `test_seed_phase_values`, `test_seed_phase_count`, `test_room_type_values`, `test_room_type_count`, `test_adventurer_class_values`, `test_adventurer_class_count`, `test_level_tier_values`, `test_level_tier_count`, `test_item_rarity_values`, `test_item_rarity_count`, `test_equip_slot_values`, `test_equip_slot_count`, `test_currency_values`, `test_currency_count`, `test_expedition_status_values`, `test_expedition_status_count`_
  - _Tests verify: all 10 enum types have correct values, correct counts_

- [ ] **1.1.3** Add Section B tests: GameConfig dictionary completeness and value tests (24 tests)
  - _Ticket ref: FR-013 through FR-022, FR-025, AC-012 through AC-021_
  - _File: `tests/models/test_enums_and_config.gd`_
  - _Tests: `test_base_growth_seconds_completeness`, `test_base_growth_seconds_values`, `test_base_growth_seconds_positive`, `test_base_growth_seconds_monotonically_increasing`, `test_xp_per_tier_completeness`, `test_xp_per_tier_values`, `test_xp_per_tier_monotonically_increasing`, `test_base_stats_completeness`, `test_base_stats_required_keys`, `test_base_stats_all_positive`, `test_base_stats_exactly_five_keys`, `test_mutation_slots_completeness`, `test_mutation_slots_values`, `test_mutation_slots_monotonically_increasing`, `test_currency_earn_rates_completeness`, `test_currency_earn_rates_non_negative`, `test_room_difficulty_scale_completeness`, `test_room_difficulty_scale_positive`, `test_phase_growth_multipliers_completeness`, `test_phase_growth_multipliers_positive`, `test_element_names_completeness`, `test_element_names_non_empty`, `test_rarity_colors_completeness`, `test_rarity_colors_are_color_type`_
  - _Tests verify: all 9 dictionaries have complete entries with correct values and constraints_

- [ ] **1.1.4** Add Section C tests: helper method tests (7 tests)
  - _Ticket ref: FR-023, FR-024, AC-022 through AC-024_
  - _File: `tests/models/test_enums_and_config.gd`_
  - _Tests: `test_seed_rarity_name_common`, `test_seed_rarity_name_uncommon`, `test_seed_rarity_name_rare`, `test_seed_rarity_name_epic`, `test_seed_rarity_name_legendary`, `test_get_base_stats_warrior`, `test_get_base_stats_all_classes`_
  - _Tests verify: Enums helper methods and GameConfig helper methods return correct values_

> **Implementation source**: Ticket Section 14 has the complete, copy-pasteable test file with all 51 functions.

### Phase 1 Validation Gate

- [ ] **1.V.1** `tests/models/test_enums_and_config.gd` exists and is parseable GDScript (ignoring unresolved `Enums`/`GameConfig` references)
- [ ] **1.V.2** File contains exactly 51 test functions (20 Section A + 24 Section B + 7 Section C)
- [ ] **1.V.3** All tests reference `Enums` and/or `GameConfig` — confirm RED state (classes do not exist)
- [ ] **1.V.4** Commit: `"Phase 1: Add 51 GUT tests for Enums and GameConfig — RED (classes not yet implemented)"`

---

## Phase 2: Enums Implementation (GREEN — partial)

> **Ticket References**: FR-001 through FR-012, FR-023
> **AC References**: AC-001 through AC-011, AC-022, AC-023
> **Estimated Items**: 14
> **Dependencies**: Phase 1 complete (test file exists)
> **Validation Gate**: `enums.gd` exists with 10 enums and 5 helper methods; Section A + Section C (rarity name) tests pass = 25 of 51 tests green
> **⚠️ CREATION ORDER**: `enums.gd` MUST be created before `game_config.gd` because `game_config.gd` references `Enums.*` constants.

### 2.1 Create Class Shell

- [ ] **2.1.1** Create `src/models/enums.gd` with `class_name Enums` and file-level doc comment
  - _Ticket ref: FR-001, AC-001_
  - _File: `src/models/enums.gd`_
  - _Content: `class_name Enums` + `##` doc comment block explaining purpose_
  - _No `extends` statement — implicitly extends `RefCounted`_

### 2.2 Add Seed System Enums (§4.1)

- [ ] **2.2.1** Add `enum SeedRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }` with doc comment
  - _Ticket ref: FR-002, AC-002_
  - _File: `src/models/enums.gd`_
  - _Values: COMMON=0, UNCOMMON=1, RARE=2, EPIC=3, LEGENDARY=4_

- [ ] **2.2.2** Add `enum Element { TERRA, FLAME, FROST, ARCANE, SHADOW }` with doc comment
  - _Ticket ref: FR-003, AC-003_
  - _File: `src/models/enums.gd`_
  - _Values: TERRA=0, FLAME=1, FROST=2, ARCANE=3, SHADOW=4_

- [ ] **2.2.3** Add `enum SeedPhase { SPORE, SPROUT, BUD, BLOOM }` with doc comment
  - _Ticket ref: FR-004, AC-004_
  - _File: `src/models/enums.gd`_
  - _Values: SPORE=0, SPROUT=1, BUD=2, BLOOM=3_

### 2.3 Add Dungeon System Enums (§4.2)

- [ ] **2.3.1** Add `enum RoomType { COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS }` with doc comment
  - _Ticket ref: FR-005, AC-005_
  - _File: `src/models/enums.gd`_
  - _Values: COMBAT=0, TREASURE=1, TRAP=2, PUZZLE=3, REST=4, BOSS=5_

- [ ] **2.3.2** Add `enum ExpeditionStatus { PREPARING, IN_PROGRESS, COMPLETED, FAILED }` with doc comment
  - _Ticket ref: FR-011, AC-011_
  - _File: `src/models/enums.gd`_
  - _Values: PREPARING=0, IN_PROGRESS=1, COMPLETED=2, FAILED=3_

### 2.4 Add Adventurer System Enums (§4.3)

- [ ] **2.4.1** Add `enum AdventurerClass { WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL }` with doc comment
  - _Ticket ref: FR-006, AC-006_
  - _File: `src/models/enums.gd`_
  - _Values: WARRIOR=0, RANGER=1, MAGE=2, ROGUE=3, ALCHEMIST=4, SENTINEL=5_

- [ ] **2.4.2** Add `enum LevelTier { NOVICE, SKILLED, VETERAN, ELITE }` with doc comment
  - _Ticket ref: FR-007, AC-007_
  - _File: `src/models/enums.gd`_
  - _Values: NOVICE=0, SKILLED=1, VETERAN=2, ELITE=3_

- [ ] **2.4.3** Add `enum EquipSlot { WEAPON, ARMOR, ACCESSORY }` with doc comment
  - _Ticket ref: FR-009, AC-009_
  - _File: `src/models/enums.gd`_
  - _Values: WEAPON=0, ARMOR=1, ACCESSORY=2_

### 2.5 Add Loot & Economy Enums (§4.4)

- [ ] **2.5.1** Add `enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }` with doc comment
  - _Ticket ref: FR-008, AC-008_
  - _File: `src/models/enums.gd`_
  - _Values: COMMON=0, UNCOMMON=1, RARE=2, EPIC=3, LEGENDARY=4_

- [ ] **2.5.2** Add `enum Currency { GOLD, ESSENCE, FRAGMENTS, ARTIFACTS }` with doc comment
  - _Ticket ref: FR-010, AC-010_
  - _File: `src/models/enums.gd`_
  - _Values: GOLD=0, ESSENCE=1, FRAGMENTS=2, ARTIFACTS=3_

### 2.6 Add Helper Methods

- [ ] **2.6.1** Add `static func seed_rarity_name(rarity: SeedRarity) -> String` with match statement and `##` doc comment
  - _Ticket ref: FR-023, AC-022, AC-023_
  - _File: `src/models/enums.gd`_
  - _Returns: "Common", "Uncommon", "Rare", "Epic", "Legendary" — or "Unknown" with push_warning for invalid input_

- [ ] **2.6.2** Add remaining helper methods: `item_rarity_name()`, `adventurer_class_name()`, `element_name()`, `equip_slot_name()`
  - _Ticket ref: FR-012 (no name collision between enums — helpers disambiguate), NFR-005_
  - _File: `src/models/enums.gd`_
  - _Each with `##` doc comment and `_` wildcard branch with push_warning_

> **Implementation source**: Ticket Section 16.1 has the complete, copy-pasteable `enums.gd`.

### Phase 2 Validation Gate

- [ ] **2.V.1** `src/models/enums.gd` exists and is parseable GDScript
- [ ] **2.V.2** File declares `class_name Enums` (no `extends` statement)
- [ ] **2.V.3** All 10 enums declared with correct names, correct value counts, correct integer assignments (FR-002 through FR-011)
- [ ] **2.V.4** All 5 helper methods have `##` doc comments (NFR-005)
- [ ] **2.V.5** All 5 helper methods include `_` wildcard with `push_warning()` for invalid input
- [ ] **2.V.6** Section A tests (20 tests) pass green — enum values and counts verified (AC-002 through AC-011)
- [ ] **2.V.7** Section C rarity name tests (5 tests) pass green — `seed_rarity_name()` returns correct values (AC-022, AC-023)
- [ ] **2.V.8** File is under 200 lines (NFR-008)
- [ ] **2.V.9** Commit: `"Phase 2: Add Enums class with 10 enums and 5 helper methods — 25/51 tests green"`

---

## Phase 3: GameConfig Implementation (GREEN — complete)

> **Ticket References**: FR-013 through FR-022, FR-024, FR-025
> **AC References**: AC-012 through AC-021, AC-024
> **Estimated Items**: 13
> **Dependencies**: Phase 2 complete (enums.gd exists — game_config.gd references `Enums.*`)
> **Validation Gate**: ALL 51 tests pass green; all 9 dictionaries and 7 helper methods present
> **⚠️ DEPENDENCY**: `game_config.gd` imports `Enums.*` — enums.gd MUST exist first (Phase 2).

### 3.1 Create Class Shell

- [ ] **3.1.1** Create `src/models/game_config.gd` with `class_name GameConfig` and file-level doc comment
  - _Ticket ref: FR-013, AC-012_
  - _File: `src/models/game_config.gd`_
  - _Content: `class_name GameConfig` + `##` doc comment block explaining purpose_
  - _No `extends` statement — implicitly extends `RefCounted`_

### 3.2 Add Seed System Constants (§4.1)

- [ ] **3.2.1** Add `const BASE_GROWTH_SECONDS: Dictionary` with all 5 SeedRarity entries and doc comment
  - _Ticket ref: FR-014, AC-013, FR-025_
  - _File: `src/models/game_config.gd`_
  - _Values: COMMON=60, UNCOMMON=120, RARE=300, EPIC=600, LEGENDARY=1200_

- [ ] **3.2.2** Add `const MUTATION_SLOTS: Dictionary` with all 5 SeedRarity entries and doc comment
  - _Ticket ref: FR-017, AC-016, FR-025_
  - _File: `src/models/game_config.gd`_
  - _Values: COMMON=1, UNCOMMON=2, RARE=3, EPIC=4, LEGENDARY=5_

- [ ] **3.2.3** Add `const PHASE_GROWTH_MULTIPLIERS: Dictionary` with all 4 SeedPhase entries and doc comment
  - _Ticket ref: FR-020, AC-019, FR-025_
  - _File: `src/models/game_config.gd`_
  - _Values: SPORE=1.0, SPROUT=0.9, BUD=0.75, BLOOM=0.5_

- [ ] **3.2.4** Add `const ELEMENT_NAMES: Dictionary` with all 5 Element entries and doc comment
  - _Ticket ref: FR-021, AC-020, FR-025_
  - _File: `src/models/game_config.gd`_
  - _Values: TERRA="Terra", FLAME="Flame", FROST="Frost", ARCANE="Arcane", SHADOW="Shadow"_

### 3.3 Add Dungeon System Constants (§4.2)

- [ ] **3.3.1** Add `const ROOM_DIFFICULTY_SCALE: Dictionary` with all 6 RoomType entries and doc comment
  - _Ticket ref: FR-019, AC-018, FR-025_
  - _File: `src/models/game_config.gd`_
  - _Values: COMBAT=1.0, TREASURE=0.5, TRAP=1.2, PUZZLE=0.8, REST=0.0, BOSS=2.0_

### 3.4 Add Adventurer System Constants (§4.3)

- [ ] **3.4.1** Add `const XP_PER_TIER: Dictionary` with all 4 LevelTier entries and doc comment
  - _Ticket ref: FR-015, AC-014, FR-025_
  - _File: `src/models/game_config.gd`_
  - _Values: NOVICE=0, SKILLED=100, VETERAN=350, ELITE=750_

- [ ] **3.4.2** Add `const BASE_STATS: Dictionary` with all 6 AdventurerClass entries, each containing 5 stat keys, and doc comment
  - _Ticket ref: FR-016, AC-015, FR-025_
  - _File: `src/models/game_config.gd`_
  - _Keys per class: "health", "attack", "defense", "speed", "utility" — all positive integers_

### 3.5 Add Loot & Economy Constants (§4.4)

- [ ] **3.5.1** Add `const CURRENCY_EARN_RATES: Dictionary` with all 4 Currency entries and doc comment
  - _Ticket ref: FR-018, AC-017, FR-025_
  - _File: `src/models/game_config.gd`_
  - _Values: GOLD=10, ESSENCE=2, FRAGMENTS=1, ARTIFACTS=0_

- [ ] **3.5.2** Add `const RARITY_COLORS: Dictionary` with all 5 SeedRarity entries and doc comment
  - _Ticket ref: FR-022, AC-021, FR-025_
  - _File: `src/models/game_config.gd`_
  - _Values: COMMON=Color(0.66,0.66,0.66), UNCOMMON=Color(0.18,0.80,0.25), RARE=Color(0.26,0.52,0.96), EPIC=Color(0.64,0.21,0.93), LEGENDARY=Color(1.00,0.78,0.06)_

### 3.6 Add Helper Methods

- [ ] **3.6.1** Add `static func get_base_stats(cls: Enums.AdventurerClass) -> Dictionary` with doc comment
  - _Ticket ref: FR-024, AC-024_
  - _File: `src/models/game_config.gd`_
  - _Returns `BASE_STATS[cls].duplicate()` — copy to prevent mutation of const source_
  - _Fallback: `push_warning()` + return `{}` for unknown class_

- [ ] **3.6.2** Add remaining 6 helper methods: `get_growth_seconds()`, `get_mutation_slots()`, `get_xp_for_tier()`, `get_rarity_color()`, `get_room_difficulty()`, `get_phase_multiplier()`
  - _Ticket ref: NFR-005, NFR-009_
  - _File: `src/models/game_config.gd`_
  - _Each with `##` doc comment, key-existence check, `push_warning()` fallback_

> **Implementation source**: Ticket Section 16.2 has the complete, copy-pasteable `game_config.gd`.

### Phase 3 Validation Gate

- [ ] **3.V.1** `src/models/game_config.gd` exists and is parseable GDScript
- [ ] **3.V.2** File declares `class_name GameConfig` (no `extends` statement)
- [ ] **3.V.3** All 9 const dictionaries declared with correct keys and values (FR-014 through FR-022)
- [ ] **3.V.4** All 9 dictionaries have entries for every value of their corresponding enum — no missing keys (FR-025)
- [ ] **3.V.5** All 7 helper methods have `##` doc comments (NFR-005)
- [ ] **3.V.6** `get_base_stats()` returns `.duplicate()` — not a reference to the const (Section 16.3 note 4)
- [ ] **3.V.7** Section B tests (24 tests) pass green — dictionary completeness, values, and constraints verified (AC-013 through AC-021)
- [ ] **3.V.8** Section C tests (remaining 2 helper tests) pass green — `get_base_stats()` verified (AC-024)
- [ ] **3.V.9** ALL 51 tests pass green
- [ ] **3.V.10** File is under 200 lines (NFR-008)
- [ ] **3.V.11** Commit: `"Phase 3: Add GameConfig class with 9 const dictionaries and 7 helper methods — ALL 51 tests green"`

---

## Phase 4: End-to-End Validation & Cleanup

> **Ticket References**: All FRs, all NFRs, all ACs
> **AC References**: AC-001 through AC-025, NFR-001 through NFR-018
> **Estimated Items**: 17
> **Dependencies**: ALL prior phases complete (all 51 tests green)
> **Validation Gate**: Full code quality pass, all NFRs verified, critical path readiness confirmed, final commit

### 4.1 Full Test Suite Run

- [ ] **4.1.1** Run complete GUT test suite for `tests/models/test_enums_and_config.gd` — all 51 tests pass green
  - _Ticket ref: Section 14, NFR-013, NFR-014_
  - _Expected: 51 pass, 0 fail, 0 error_
- [ ] **4.1.2** Verify no existing tests in `tests/unit/` or `tests/models/` are broken by our changes
  - _Ticket ref: Regression gate_
- [ ] **4.1.3** Verify test suite runs in under 500 ms total (NFR-014)
  - _Ticket ref: NFR-014_

### 4.2 Code Quality Verification — enums.gd (NFRs)

- [ ] **4.2.1** Verify file implicitly extends `RefCounted`, NOT `Node` — no `extends` statement (NFR-012)
  - _Inspect: no `extends` keyword in file_
- [ ] **4.2.2** Verify all parameters, return types use explicit type annotations (NFR-009)
  - _Inspect: every `func` has `: Type` parameter annotations and `-> Type` return_
- [ ] **4.2.3** Verify every enum has a `##` doc comment (NFR-005)
  - _Inspect: 10 `##` comments above 10 enum declarations_
- [ ] **4.2.4** Verify zero runtime state — no `var` declarations in file (NFR-001, NFR-017)
  - _Inspect: only `enum`, `static func`, `const`, `class_name` — no `var`_
- [ ] **4.2.5** Verify file is under 200 lines (NFR-008)
- [ ] **4.2.6** Verify no `print()`, `push_error()` in production code — only `push_warning()` in wildcard branches (NFR-011 equivalent)

### 4.3 Code Quality Verification — game_config.gd (NFRs)

- [ ] **4.3.1** Verify file implicitly extends `RefCounted`, NOT `Node` — no `extends` statement (NFR-012)
  - _Inspect: no `extends` keyword in file_
- [ ] **4.3.2** Verify all values declared `const` — no `var` declarations (NFR-001, NFR-017)
  - _Inspect: every dictionary uses `const` keyword_
- [ ] **4.3.3** Verify all parameters, return types use explicit type annotations (NFR-009)
- [ ] **4.3.4** Verify every dictionary and helper method has a `##` doc comment (NFR-005)
- [ ] **4.3.5** Verify no circular dependencies — `game_config.gd` references only `Enums.*`, `enums.gd` references nothing (NFR-016)
- [ ] **4.3.6** Verify Color values use Godot's `Color()` constructor with float args 0.0–1.0 (NFR-018)
- [ ] **4.3.7** Verify file is under 200 lines (NFR-008)

### 4.4 Critical Path Readiness

- [ ] **4.4.1** Verify TASK-004 can reference: `Enums.SeedRarity`, `Enums.Element`, `Enums.SeedPhase`, `GameConfig.BASE_GROWTH_SECONDS`, `GameConfig.MUTATION_SLOTS`, `GameConfig.PHASE_GROWTH_MULTIPLIERS`
  - _Ticket ref: Section 2.5 — Downstream Dependency Map_
- [ ] **4.4.2** Verify TASK-005 can reference: `Enums.RoomType`, `GameConfig.ROOM_DIFFICULTY_SCALE`
- [ ] **4.4.3** Verify TASK-006 can reference: `Enums.AdventurerClass`, `Enums.LevelTier`, `GameConfig.BASE_STATS`, `GameConfig.XP_PER_TIER`
- [ ] **4.4.4** Verify TASK-007 can reference: `Enums.ItemRarity`, `Enums.EquipSlot`, `GameConfig.RARITY_COLORS`
- [ ] **4.4.5** Verify TASK-008 can reference: `Enums.Currency`, `GameConfig.CURRENCY_EARN_RATES`

> **Note**: "Verify can reference" means confirming that `class_name Enums` and `class_name GameConfig` are registered, so downstream scripts can use `Enums.SeedRarity.COMMON` and `GameConfig.BASE_GROWTH_SECONDS` without `preload()`.

### Phase 4 Validation Gate

- [ ] **4.V.1** All 51 tests pass green (AC-001 through AC-024 verified)
- [ ] **4.V.2** Both files compile without errors or warnings in Godot 4.5 strict mode (AC-025, NFR-011)
- [ ] **4.V.3** All NFRs (NFR-001 through NFR-018) verified
- [ ] **4.V.4** `project.godot` unchanged from pre-task state
- [ ] **4.V.5** All 5 downstream tasks (TASK-004 through TASK-008) unblocked — critical path cleared
- [ ] **4.V.6** Commit: `"TASK-003 complete: Enums, Constants & Data Dictionary — 51 tests, all green, 5 Wave 2 tasks unblocked"`

---

## Phase Dependency Graph

```
Phase 0 (Pre-Flight) ──→ Phase 1 (Test File — RED) ──→ Phase 2 (Enums — GREEN partial)
                                                              │
                                                              ▼
                                                        Phase 3 (GameConfig — GREEN complete)
                                                              │
                                                              ▼
                                                        Phase 4 (E2E Validation + Cleanup)
```

**Parallelism note**: This task is strictly sequential — each phase builds on the previous one. Phase 2 cannot begin until Phase 1's test file exists. Phase 3 CANNOT begin until Phase 2's `enums.gd` exists (because `game_config.gd` references `Enums.*`). This is the critical ordering constraint.

**⚠️ CRITICAL ORDERING**: `enums.gd` (Phase 2) MUST be created before `game_config.gd` (Phase 3). The `game_config.gd` file uses `Enums.SeedRarity`, `Enums.Element`, `Enums.SeedPhase`, `Enums.RoomType`, `Enums.AdventurerClass`, `Enums.LevelTier`, and `Enums.Currency` as dictionary keys. If `enums.gd` does not exist, `game_config.gd` will fail to parse.

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 0 | Pre-flight & directory verification | 6 | 0 | 0 | ⬜ Not Started |
| Phase 1 | Test file — RED | 5 | 0 | 51 (RED) | ⬜ Not Started |
| Phase 2 | Enums implementation — GREEN partial | 14 | 0 | 25 | ⬜ Not Started |
| Phase 3 | GameConfig implementation — GREEN complete | 13 | 0 | 26 | ⬜ Not Started |
| Phase 4 | E2E validation & cleanup | 17 | 0 | 51 | ⬜ Not Started |
| **Total** | | **55** | **0** | **51** | **⬜ Phase 0 Next** |

---

## File Change Summary

### New Files

| File | Phase | Purpose |
|------|-------|---------|
| `src/models/enums.gd` | 2 | `Enums` class — 10 game-wide enumerations + 5 helper methods |
| `src/models/game_config.gd` | 3 | `GameConfig` class — 9 const balance dictionaries + 7 helper methods |
| `tests/models/test_enums_and_config.gd` | 1 | 51 GUT unit tests covering all enums, dictionaries, and helpers |

### Modified Files

None — this task creates new files only and does not modify `project.godot` or any existing code.

### Deleted Files

None — this task is additive only.

### Directories Created (if missing)

| Directory | Phase | Purpose |
|-----------|-------|---------|
| `tests/models/` | 0 | Test file location (may already exist from TASK-002) |

---

## Commit Strategy

| Phase | Commit Message | Tests After |
|-------|----------------|-------------|
| 0 | `"Phase 0: Verify prerequisites for TASK-003 enums and config"` | 0 (no tests yet) |
| 1 | `"Phase 1: Add 51 GUT tests for Enums and GameConfig — RED (classes not yet implemented)"` | 51 (RED) |
| 2 | `"Phase 2: Add Enums class with 10 enums and 5 helper methods — 25/51 tests green"` | 25 ✅ / 26 ❌ |
| 3 | `"Phase 3: Add GameConfig class with 9 const dictionaries and 7 helper methods — ALL 51 tests green"` | 51 ✅ |
| 4 | `"TASK-003 complete: Enums, Constants & Data Dictionary — 51 tests, all green, 5 Wave 2 tasks unblocked"` | 51 ✅ |

---

## Deviation Tracking

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| _(none yet)_ | | | | | |

> **Note**: The ticket specifies `ROOM_DIFFICULTY_SCALE[REST] = 0.0`. This is a positive-float dictionary per FR-019, but the REST room has difficulty scale `0.0`. The test `test_room_difficulty_scale_positive` asserts `> 0.0` for all entries. If the test fails on REST, this is a ticket inconsistency — the REST room legitimately has zero difficulty (it's a rest room). Record as a deviation if encountered.

> **Resolution**: If the test `test_room_difficulty_scale_positive` fails for `REST = 0.0`, either:
> 1. Change the test to `assert_true(val >= 0.0)` instead of `assert_gt(val, 0.0)` for REST only, or
> 2. Accept the value as-is and note that FR-019's "positive float" language is approximate.
> The ticket's Section 14 test code uses `assert_gt` for this check. The Section 16 implementation has `REST: 0.0`. If these conflict, the implementation code (Section 16) takes precedence — it matches the GDD design intent (rest rooms have no combat difficulty). Record as DEV-001.

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| `src/models/` directory doesn't exist (TASK-001 not yet run) | Medium | Low | Create directory in Phase 0 if missing | 0 |
| `tests/models/` directory doesn't exist | Medium | Low | Create directory in Phase 0 if missing | 0 |
| `class_name Enums` conflicts with existing v1 code | Low | High | Search codebase in Phase 0; rename if conflict found | 0 |
| `class_name GameConfig` conflicts with existing code | Low | High | Search codebase in Phase 0; rename if conflict found | 0 |
| GUT addon not installed / incompatible with Godot 4.5+ | Medium | High | Verify in Phase 0; install GUT v9.x+ if missing | 0 |
| `game_config.gd` created before `enums.gd` → parse error | Medium | Critical | **Strict phase ordering enforced**: Phase 2 (enums) before Phase 3 (config) | 2, 3 |
| REST room `ROOM_DIFFICULTY_SCALE = 0.0` conflicts with "positive float" assertion | High | Low | See Deviation Tracking above — implementation takes precedence over FR wording | 3 |
| `Array[float]` typed array syntax not supported in some test contexts | Low | Low | Fall back to untyped `Array` if needed; document as deviation | 1 |
| Downstream tasks start before TASK-003 merges, causing merge conflicts | Low | High | Enforce Wave 2 gating — no downstream work until critical path cleared | 4 |

---

## Handoff State (2025-07-18)

### What's Complete
- Implementation plan written and ready for execution

### What's In Progress
- Nothing — plan is at Phase 0 (not started)

### What's Blocked
- Nothing — TASK-003 has no upstream dependencies (Wave 1)
- **However**: 5 Wave 2 tasks (TASK-004, TASK-005, TASK-006, TASK-007, TASK-008) are blocked BY this task

### Next Steps
1. Execute Phase 0: Verify prerequisites, create directories if missing
2. Execute Phase 1: Write complete test file with 51 functions (RED)
3. Execute Phase 2: Implement `enums.gd` with 10 enums + 5 helpers (GREEN partial — 25/51)
4. Execute Phase 3: Implement `game_config.gd` with 9 dictionaries + 7 helpers (GREEN complete — 51/51)
5. Execute Phase 4: Full end-to-end validation, NFR audit, critical path confirmation, final commit
6. **Unblock Wave 2**: TASK-004 through TASK-008 can begin immediately after merge

---

## Ticket FR/AC Coverage Matrix

Every Functional Requirement and Acceptance Criterion from the ticket is mapped below.

### Functional Requirements → Phase Items

| FR | Description | Phase | Checkbox |
|----|-------------|-------|----------|
| FR-001 | `enums.gd` declares `class_name Enums` | 2 | 2.1.1 |
| FR-002 | `enum SeedRarity` with 5 values (COMMON through LEGENDARY) | 2 | 2.2.1 |
| FR-003 | `enum Element` with 5 values (TERRA through SHADOW) | 2 | 2.2.2 |
| FR-004 | `enum SeedPhase` with 4 values (SPORE through BLOOM) | 2 | 2.2.3 |
| FR-005 | `enum RoomType` with 6 values (COMBAT through BOSS) | 2 | 2.3.1 |
| FR-006 | `enum AdventurerClass` with 6 values (WARRIOR through SENTINEL) | 2 | 2.4.1 |
| FR-007 | `enum LevelTier` with 4 values (NOVICE through ELITE) | 2 | 2.4.2 |
| FR-008 | `enum ItemRarity` with 5 values (COMMON through LEGENDARY) | 2 | 2.5.1 |
| FR-009 | `enum EquipSlot` with 3 values (WEAPON through ACCESSORY) | 2 | 2.4.3 |
| FR-010 | `enum Currency` with 4 values (GOLD through ARTIFACTS) | 2 | 2.5.2 |
| FR-011 | `enum ExpeditionStatus` with 4 values (PREPARING through FAILED) | 2 | 2.3.2 |
| FR-012 | No two enums share the same name (no compilation ambiguity) | 2 | 2.6.2 |
| FR-013 | `game_config.gd` declares `class_name GameConfig` | 3 | 3.1.1 |
| FR-014 | `const BASE_GROWTH_SECONDS` maps every SeedRarity to positive int | 3 | 3.2.1 |
| FR-015 | `const XP_PER_TIER` maps every LevelTier to non-negative int (monotonic) | 3 | 3.4.1 |
| FR-016 | `const BASE_STATS` maps every AdventurerClass to 5-key stat dict | 3 | 3.4.2 |
| FR-017 | `const MUTATION_SLOTS` maps every SeedRarity to positive int | 3 | 3.2.2 |
| FR-018 | `const CURRENCY_EARN_RATES` maps every Currency to non-negative value | 3 | 3.5.1 |
| FR-019 | `const ROOM_DIFFICULTY_SCALE` maps every RoomType to positive float | 3 | 3.3.1 |
| FR-020 | `const PHASE_GROWTH_MULTIPLIERS` maps every SeedPhase to positive float | 3 | 3.2.3 |
| FR-021 | `const ELEMENT_NAMES` maps every Element to non-empty String | 3 | 3.2.4 |
| FR-022 | `const RARITY_COLORS` maps every SeedRarity to Color value | 3 | 3.5.2 |
| FR-023 | `Enums.seed_rarity_name()` static helper returns human-readable name | 2 | 2.6.1 |
| FR-024 | `GameConfig.get_base_stats()` static helper returns stat dictionary | 3 | 3.6.1 |
| FR-025 | All const dictionaries have entries for every value of their enum | 3 | 3.2.1–3.5.2 (all dict checkboxes) |

### Acceptance Criteria → Validation Gates

| AC | Description | Phase | Verification |
|----|-------------|-------|--------------|
| AC-001 | `src/models/enums.gd` exists with `class_name Enums` | 2 | 2.V.1, 2.V.2 |
| AC-002 | `Enums.SeedRarity` has 5 values: COMMON=0 through LEGENDARY=4 | 2 | 2.V.3, 2.V.6 |
| AC-003 | `Enums.Element` has 5 values: TERRA=0 through SHADOW=4 | 2 | 2.V.3, 2.V.6 |
| AC-004 | `Enums.SeedPhase` has 4 values: SPORE=0 through BLOOM=3 | 2 | 2.V.3, 2.V.6 |
| AC-005 | `Enums.RoomType` has 6 values: COMBAT=0 through BOSS=5 | 2 | 2.V.3, 2.V.6 |
| AC-006 | `Enums.AdventurerClass` has 6 values: WARRIOR=0 through SENTINEL=5 | 2 | 2.V.3, 2.V.6 |
| AC-007 | `Enums.LevelTier` has 4 values: NOVICE=0 through ELITE=3 | 2 | 2.V.3, 2.V.6 |
| AC-008 | `Enums.ItemRarity` has 5 values: COMMON=0 through LEGENDARY=4 | 2 | 2.V.3, 2.V.6 |
| AC-009 | `Enums.EquipSlot` has 3 values: WEAPON=0 through ACCESSORY=2 | 2 | 2.V.3, 2.V.6 |
| AC-010 | `Enums.Currency` has 4 values: GOLD=0 through ARTIFACTS=3 | 2 | 2.V.3, 2.V.6 |
| AC-011 | `Enums.ExpeditionStatus` has 4 values: PREPARING=0 through FAILED=3 | 2 | 2.V.3, 2.V.6 |
| AC-012 | `src/models/game_config.gd` exists with `class_name GameConfig` | 3 | 3.V.1, 3.V.2 |
| AC-013 | `BASE_GROWTH_SECONDS` has 5 entries, positive, values match GDD | 3 | 3.V.3, 3.V.7 |
| AC-014 | `XP_PER_TIER` has 4 entries, monotonically increasing | 3 | 3.V.3, 3.V.7 |
| AC-015 | `BASE_STATS` has 6 entries, each with 5 keys, all positive | 3 | 3.V.3, 3.V.7 |
| AC-016 | `MUTATION_SLOTS` has 5 entries, positive, monotonically increasing | 3 | 3.V.3, 3.V.7 |
| AC-017 | `CURRENCY_EARN_RATES` has 4 entries, all non-negative | 3 | 3.V.3, 3.V.7 |
| AC-018 | `ROOM_DIFFICULTY_SCALE` has 6 entries, all positive floats | 3 | 3.V.3, 3.V.7 |
| AC-019 | `PHASE_GROWTH_MULTIPLIERS` has 4 entries, all positive floats | 3 | 3.V.3, 3.V.7 |
| AC-020 | `ELEMENT_NAMES` has 5 entries, all non-empty Strings | 3 | 3.V.3, 3.V.7 |
| AC-021 | `RARITY_COLORS` has 5 entries, all valid Color objects | 3 | 3.V.3, 3.V.7 |
| AC-022 | `Enums.seed_rarity_name(COMMON)` returns "Common" | 2 | 2.V.7 |
| AC-023 | `seed_rarity_name()` returns correct names for all 5 values | 2 | 2.V.7 |
| AC-024 | `GameConfig.get_base_stats(WARRIOR)` returns dict with 5 stat keys | 3 | 3.V.8 |
| AC-025 | Both files compile without errors/warnings in Godot 4.5 strict mode | 4 | 4.V.2 |

### Non-Functional Requirements → Verification

| NFR | Description | Phase | Verification |
|-----|-------------|-------|--------------|
| NFR-001 | Zero runtime heap allocations — all data is `const` | 4 | 4.2.4, 4.3.2 |
| NFR-002 | Total memory footprint under 8 KB | 4 | 4.V.3 (file size inspection) |
| NFR-003 | Script parse/load under 1 ms | 4 | 4.V.3 (implicit — trivial files) |
| NFR-004 | Dictionary lookups are O(1) hash-map | 4 | 4.V.3 (Godot Dictionary is hash-map by design) |
| NFR-005 | Every enum and dict has `##` doc comment | 2, 3, 4 | 2.V.4, 3.V.5, 4.2.3, 4.3.4 |
| NFR-006 | Adding enum value = edit 1 file + update GameConfig | 4 | 4.V.3 (architecture review) |
| NFR-007 | Adding GameConfig dict = edit 1 file | 4 | 4.V.3 (architecture review) |
| NFR-008 | Both files under 200 lines each | 2, 3, 4 | 2.V.8, 3.V.10, 4.2.5, 4.3.7 |
| NFR-009 | Explicit type hints on all variables, params, returns | 4 | 4.2.2, 4.3.3 |
| NFR-010 | Enum values accessed via qualified name, never raw ints | 4 | 4.V.3 (code inspection) |
| NFR-011 | Both files compile without warnings in strict mode | 4 | 4.V.2 |
| NFR-012 | Both files usable via `class_name` without autoload | 2, 3 | 2.V.2, 3.V.2 |
| NFR-013 | 100% test coverage of all enum values and dict entries | 4 | 4.1.1 |
| NFR-014 | Test suite runs under 500 ms | 4 | 4.1.3 |
| NFR-015 | Both files pass GDScript linter with zero warnings | 4 | 4.V.2 |
| NFR-016 | No circular dependencies — enums depends on nothing; config depends only on enums | 4 | 4.3.5 |
| NFR-017 | All values deterministic — no randf(), no Time, no external sources | 4 | 4.2.4, 4.3.2 |
| NFR-018 | Color values use cross-platform `Color()` constructor | 4 | 4.3.6 |

---

*End of TASK-003 Implementation Plan*
