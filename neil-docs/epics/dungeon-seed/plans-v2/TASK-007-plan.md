# TASK-007: Item, Equipment & Inventory Data Models — Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-007-item-equipment-models.md`
> **GDD**: `neil-docs/epics/dungeon-seed/GDD-v2.md`
> **Status**: Planning
> **Created**: 2025-07-22
> **Repo**: `dev-agent-tool` (local — `C:\Users\wrstl\source\dev-agent-tool`)
> **Methodology**: TDD Red-Green-Refactor (mandatory for all phases)
> **Complexity**: 5 points (Moderate) — Fibonacci
> **Estimated Phases**: 6 (Phase 0–5)
> **Estimated Checkboxes**: ~85

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents in this order:

1. **This file** (you're reading it) — the phased checklist of what to do, with status
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-007-item-equipment-models.md`** — the full technical spec with exact code, test files, and all 20 starter items
3. **`neil-docs/epics/dungeon-seed/GDD-v2.md`** — the Game Design Document for understanding domain context
4. **`src/models/enums.gd`** — TASK-003 dependency: `Enums.ItemRarity`, `Enums.EquipSlot`, `Enums.Currency`
5. **`src/models/game_config.gd`** — TASK-003 dependency: `GameConfig.RARITY_COLORS`

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| Engine config | `project.godot` | **EXISTS** — DO NOT MODIFY |
| Autoload scripts | `src/autoloads/` | **EXISTS** — `event_bus.gd`, `game_manager.gd` (TASK-001) — DO NOT MODIFY |
| Enum definitions | `src/models/enums.gd` | **EXISTS** — `class_name Enums` with ItemRarity, EquipSlot, Currency (TASK-003) |
| Game config | `src/models/game_config.gd` | **EXISTS** — `class_name GameConfig` with RARITY_COLORS (TASK-003) |
| Deterministic RNG | `src/models/rng.gd` | **EXISTS** — `class_name DeterministicRNG` (TASK-002) — DO NOT MODIFY |
| Item data model | `src/models/item_data.gd` | **NEW** — Single item definition |
| Item database | `src/models/item_database.gd` | **NEW** — Static registry of all items |
| Inventory data | `src/models/inventory_data.gd` | **NEW** — Player inventory with quantity tracking |
| ItemData tests | `tests/models/test_item_data.gd` | **NEW** — ~20 GUT tests |
| ItemDatabase tests | `tests/models/test_item_database.gd` | **NEW** — ~25 GUT tests |
| InventoryData tests | `tests/models/test_inventory_data.gd` | **NEW** — ~30 GUT tests |
| Existing model tests | `tests/models/test_enums_and_config.gd`, `tests/models/test_rng.gd` | **EXISTS** — must not break |
| GUT addon | `addons/gut/` | **EXISTS** — pre-installed |
| v1 prototype code | `src/gdscript/` | **DO NOT TOUCH** — legacy code |

### Key Concepts (5-minute primer)

- **RefCounted**: Godot base class for garbage-collected objects. Used for pure data models — no Node, no SceneTree, no process callbacks.
- **class_name**: GDScript keyword that registers a script globally. `ItemData.new()` works without `preload()`.
- **ItemData**: Immutable definition of a single item — stats, rarity, slot, sell value. Constructed once, never mutated.
- **ItemDatabase**: Registry that indexes all `ItemData` instances by id. Pre-populated with ~20 starter items. Supports filtered queries.
- **InventoryData**: Mutable container mapping item id strings to integer quantities. The runtime "player bag."
- **Enums**: Global enum class from TASK-003. Contains `ItemRarity`, `EquipSlot`, `Currency`.
- **GameConfig**: Constants class from TASK-003. Contains `RARITY_COLORS` dictionary.
- **Serialization**: `to_dict()` / `from_dict()` pattern for JSON-compatible persistence. Enum values stored as integers.
- **GUT**: Godot Unit Test framework. Tests extend `GutTest` and use `assert_*` methods.
- **DO NOT use `class_name` on autoload scripts.** Non-autoload scripts (like these models) CAN and SHOULD use `class_name`.

### Build & Verification Commands

```powershell
# There is no CLI build for GDScript — verification is done in-editor.
# However, you can verify script syntax via headless Godot:

# Open project in editor (manual)
# Press F5 to run — should launch to main_menu.tscn

# Run GUT tests from within the editor:
#   1. Open GUT panel (bottom dock)
#   2. Click "Run All" — all tests must pass green
#   3. Or run specific test directory: tests/models/
```

### Regression Gate

Before AND after every phase:
1. `project.godot` must be unchanged (we do NOT modify it in this task)
2. Existing model files (`enums.gd`, `game_config.gd`, `rng.gd`) must not be modified
3. Existing test files (`test_enums_and_config.gd`, `test_rng.gd`) must not break
4. All new GUT tests pass green (once written)
5. No `class_name` conflicts with existing project classes

---

## Current State Analysis

### What Exists Today

| Item | Status | Location |
|------|--------|----------|
| `project.godot` | ✅ Exists | Root — Godot 4.6.1 project config |
| `src/autoloads/event_bus.gd` | ✅ Exists | EventBus autoload (TASK-001) |
| `src/autoloads/game_manager.gd` | ✅ Exists | GameManager autoload (TASK-001) |
| `src/models/enums.gd` | ✅ Exists | `class_name Enums` — ItemRarity, EquipSlot, Currency (TASK-003) |
| `src/models/game_config.gd` | ✅ Exists | `class_name GameConfig` — RARITY_COLORS (TASK-003) |
| `src/models/rng.gd` | ✅ Exists | `class_name DeterministicRNG` (TASK-002) |
| `tests/models/test_enums_and_config.gd` | ✅ Exists | GUT tests for enums and config |
| `tests/models/test_rng.gd` | ✅ Exists | GUT tests for DeterministicRNG |
| `addons/gut/` | ✅ Exists | GUT addon pre-installed |

### What's Missing (Gap Analysis)

| Item | Status | Required By |
|------|--------|-------------|
| `src/models/item_data.gd` | ❌ Missing | FR-001 through FR-016 |
| `src/models/item_database.gd` | ❌ Missing | FR-017 through FR-030 |
| `src/models/inventory_data.gd` | ❌ Missing | FR-031 through FR-050 |
| `tests/models/test_item_data.gd` | ❌ Missing | Section 14.1 (~20 tests) |
| `tests/models/test_item_database.gd` | ❌ Missing | Section 14.2 (~25 tests) |
| `tests/models/test_inventory_data.gd` | ❌ Missing | Section 14.3 (~30 tests) |

### What Must NOT Change

- `project.godot` — no modifications needed for this task
- `src/autoloads/event_bus.gd` — TASK-001 autoload
- `src/autoloads/game_manager.gd` — TASK-001 autoload
- `src/models/enums.gd` — TASK-003 dependency, read-only
- `src/models/game_config.gd` — TASK-003 dependency, read-only
- `src/models/rng.gd` — TASK-002 dependency, read-only
- `tests/models/test_enums_and_config.gd` — existing tests must pass
- `tests/models/test_rng.gd` — existing tests must pass
- `src/gdscript/` — v1 prototype code, explicitly out of scope

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
# Construction / existence
func test_construction_sets_all_fields() -> void:

# Specific behavior
func test_get_stat_bonus_existing_stat() -> void:

# Edge cases
func test_from_dict_missing_optional_keys_uses_defaults() -> void:

# Serialization round-trips
func test_from_dict_round_trip_identity() -> void:
```

### Test Structure (GUT)

Every test follows Arrange-Act-Assert:
```gdscript
func test_method_scenario_expected() -> void:
    # Arrange — create instance and test data
    var item: ItemData = ItemData.new(_make_sword_data())

    # Act — execute the behavior
    var bonus: int = item.get_stat_bonus("attack")

    # Assert — verify the outcome
    assert_eq(bonus, 5)
```

### Coverage Requirements Per Phase

- ✅ **Existence**: Class exists, extends `RefCounted`, has `class_name`
- ✅ **Construction**: Constructor sets all fields from Dictionary
- ✅ **Accessor behavior**: Public methods return correct results
- ✅ **Edge cases**: Missing keys, empty dictionaries, nonexistent items, zero quantities
- ✅ **Serialization**: `to_dict()` produces correct format, `from_dict()` round-trips
- ✅ **Error handling**: Insufficient quantity returns `false`, unknown id returns `null`

---

## Phase 0: Pre-Flight & Baseline Verification

> **Ticket References**: Dependency verification, Assumptions #1, #2, #3
> **AC References**: (pre-condition check)
> **Estimated Items**: 8
> **Dependencies**: TASK-003 complete (Enums & GameConfig exist)
> **Validation Gate**: All dependencies confirmed, existing tests green, no class_name conflicts

This phase verifies that all prerequisites are in place before writing any code.

### 0.1 Verify TASK-003 Dependency

- [ ] **0.1.1** Verify `src/models/enums.gd` exists and contains `class_name Enums`
  - _Dependency: TASK-003_
  - _Must have: `enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }`_
  - _Must have: `enum EquipSlot { NONE = -1, WEAPON = 0, ARMOR = 1, ACCESSORY = 2 }`_
  - _Must have: `enum Currency { GOLD, ESSENCE, FRAGMENTS, ARTIFACTS, TOKENS }`_

- [ ] **0.1.2** Verify `src/models/game_config.gd` exists and contains `class_name GameConfig`
  - _Dependency: TASK-003_
  - _Must have: `RARITY_COLORS` dictionary mapping `Enums.ItemRarity` → `Color`_

### 0.2 Verify No Class Name Conflicts

- [ ] **0.2.1** Search codebase for existing `class_name ItemData` — must not exist
  - _AC-068: No class_name conflicts_

- [ ] **0.2.2** Search codebase for existing `class_name ItemDatabase` — must not exist
  - _AC-068: No class_name conflicts_

- [ ] **0.2.3** Search codebase for existing `class_name InventoryData` — must not exist
  - _AC-068: No class_name conflicts_

### 0.3 Verify Existing Tests Pass

- [ ] **0.3.1** Run existing GUT tests in `tests/models/` — all must pass green
  - _Regression gate: `test_enums_and_config.gd`, `test_rng.gd` must pass_

### 0.4 Verify Target Paths Are Clear

- [ ] **0.4.1** Confirm `src/models/item_data.gd` does NOT already exist
- [ ] **0.4.2** Confirm `src/models/item_database.gd` does NOT already exist
- [ ] **0.4.3** Confirm `src/models/inventory_data.gd` does NOT already exist

### Phase 0 Validation Gate

- [ ] **0.V.1** All three TASK-003 enums confirmed present (ItemRarity, EquipSlot, Currency)
- [ ] **0.V.2** `GameConfig.RARITY_COLORS` confirmed present with 5 entries
- [ ] **0.V.3** No `class_name` conflicts found
- [ ] **0.V.4** All existing `tests/models/` tests pass green
- [ ] **0.V.5** All three target file paths are clear for creation

---

## Phase 1: ItemData Model (TDD)

> **Ticket References**: FR-001 through FR-016
> **AC References**: AC-001 through AC-020
> **Estimated Items**: 12
> **Dependencies**: Phase 0 complete
> **Validation Gate**: `item_data.gd` exists with all fields/methods, `test_item_data.gd` passes ~20 tests

### 1.1 Write Test File (RED)

- [ ] **1.1.1** Create `tests/models/test_item_data.gd` with all test functions from ticket Section 14.1
  - _Ticket ref: Section 14.1_
  - _File: `tests/models/test_item_data.gd`_
  - _Class: `extends GutTest`, `class_name TestItemData`_
  - _Helpers: `_make_sword_data()`, `_make_ring_data()`, `_make_quest_item_data()`_
  - _Tests (~20):_
    - Construction: `test_construction_sets_all_fields`, `test_is_equippable_true_for_weapon`, `test_is_equippable_true_for_accessory`, `test_is_equippable_false_for_none_slot`
    - Stat bonuses: `test_get_stat_bonus_existing_stat`, `test_get_stat_bonus_missing_stat_returns_zero`, `test_get_stat_bonus_empty_bonuses`
    - Sell values: `test_get_sell_value_existing_currency`, `test_get_sell_value_missing_currency_returns_zero`, `test_get_sell_value_empty_sell_dict`
    - Rarity colors: `test_get_rarity_color_common`, `test_get_rarity_color_uncommon`
    - Serialization: `test_to_dict_contains_all_fields`, `test_to_dict_stores_enums_as_ints`, `test_to_dict_sell_value_keys_are_ints`, `test_from_dict_reconstructs_item`, `test_from_dict_round_trip_identity`, `test_from_dict_missing_optional_keys_uses_defaults`, `test_from_dict_quest_item_round_trip`
  - _TDD: RED — tests reference `ItemData` class which does not exist yet_

### 1.2 Implement ItemData (GREEN)

- [ ] **1.2.1** Create `src/models/item_data.gd` with class declaration
  - _Ticket ref: FR-001, AC-001, AC-002_
  - _File: `src/models/item_data.gd`_
  - _Content: `class_name ItemData` + `extends RefCounted`_

- [ ] **1.2.2** Add all fields with type hints and defaults
  - _Ticket ref: FR-002 through FR-009, AC-003 through AC-010_
  - _Fields: `id: String`, `display_name: String`, `rarity: Enums.ItemRarity`, `slot: Enums.EquipSlot`, `is_equippable: bool`, `stat_bonuses: Dictionary`, `sell_value: Dictionary`, `description: String`_

- [ ] **1.2.3** Add `_init(data: Dictionary = {})` constructor that populates all fields from dict
  - _Ticket ref: FR-001_
  - _Logic: Use `data.get("key", default)` for all reads; compute `is_equippable` from slot_
  - _Note: `is_equippable = slot != Enums.EquipSlot.NONE` (FR-006, AC-007)_

- [ ] **1.2.4** Add `get_stat_bonus(stat_name: String) -> int` method
  - _Ticket ref: FR-010, AC-011, AC-012_
  - _Logic: `return int(stat_bonuses.get(stat_name, 0))`_

- [ ] **1.2.5** Add `get_sell_value(currency: Enums.Currency) -> int` method
  - _Ticket ref: FR-011, AC-013, AC-014_
  - _Logic: `return int(sell_value.get(currency, 0))`_

- [ ] **1.2.6** Add `get_rarity_color() -> Color` method
  - _Ticket ref: FR-012, AC-015_
  - _Logic: `return GameConfig.RARITY_COLORS.get(rarity, Color.WHITE)`_

- [ ] **1.2.7** Add `to_dict() -> Dictionary` serialization method
  - _Ticket ref: FR-013, FR-014, AC-016, AC-017_
  - _Logic: Convert rarity/slot to `int()`, convert sell_value keys to `int()`_

- [ ] **1.2.8** Add `static func from_dict(data: Dictionary) -> ItemData` factory method
  - _Ticket ref: FR-015, FR-016, AC-018, AC-019, AC-020_
  - _Logic: `return ItemData.new(data)` — delegates to constructor_

- [ ] **1.2.9** Add `_parse_dict(input: Variant) -> Dictionary` internal helper
  - _Logic: Safe duplicate of Dictionary input, returns empty dict for non-Dictionary input_

> **Implementation source**: Ticket Section 16.1 has the complete, copy-pasteable `item_data.gd`.

### 1.3 Refactor (if needed)

- [ ] **1.3.1** Review `item_data.gd` for code quality: type hints, doc comments, naming conventions
  - _AC-065: All public methods have complete type hints_
  - _AC-069: No hardcoded magic numbers_
  - _AC-070: snake_case naming throughout_
  - _Run all tests after any refactor_

### Phase 1 Validation Gate

- [ ] **1.V.1** `src/models/item_data.gd` exists and is parseable GDScript
- [ ] **1.V.2** File extends `RefCounted` and declares `class_name ItemData`
- [ ] **1.V.3** All 8 fields have GDScript type hints (AC-003–AC-010)
- [ ] **1.V.4** `get_stat_bonus()` returns correct value or 0 for missing stats
- [ ] **1.V.5** `get_sell_value()` returns correct value or 0 for missing currencies
- [ ] **1.V.6** `get_rarity_color()` returns color from `GameConfig.RARITY_COLORS`
- [ ] **1.V.7** `to_dict()` stores enums as integers (AC-017)
- [ ] **1.V.8** `from_dict()` round-trip produces identical field values (AC-020)
- [ ] **1.V.9** All `##` doc comments on public methods
- [ ] **1.V.10** All ~20 ItemData tests pass green
- [ ] **1.V.11** Existing `tests/models/` tests still pass (regression check)
- [ ] **1.V.12** Commit: `"Phase 1: Add ItemData model with construction, accessors, and serialization — ~20 tests"`

---

## Phase 2: ItemDatabase Model (TDD)

> **Ticket References**: FR-017 through FR-030
> **AC References**: AC-021 through AC-040
> **Estimated Items**: 14
> **Dependencies**: Phase 1 complete (ItemData class exists)
> **Validation Gate**: `item_database.gd` exists with 20 starter items and all query methods, `test_item_database.gd` passes ~25 tests

### 2.1 Write Test File (RED)

- [ ] **2.1.1** Create `tests/models/test_item_database.gd` with all test functions from ticket Section 14.2
  - _Ticket ref: Section 14.2_
  - _File: `tests/models/test_item_database.gd`_
  - _Class: `extends GutTest`, `class_name TestItemDatabase`_
  - _Setup: `var db: ItemDatabase` + `before_each()` creates fresh `ItemDatabase.new()`_
  - _Tests (~25):_
    - Population: `test_database_has_at_least_20_items`, `test_database_has_items_in_all_rarity_tiers`, `test_database_has_at_least_3_weapons`, `test_database_has_at_least_3_armors`, `test_database_has_at_least_3_accessories`
    - Lookup: `test_get_item_returns_correct_item`, `test_get_item_nonexistent_returns_null`, `test_has_item_existing`, `test_has_item_nonexistent`
    - Filters: `test_get_items_by_rarity_common`, `test_get_items_by_rarity_legendary`, `test_get_items_by_slot_weapon`, `test_get_items_by_slot_armor`, `test_get_items_by_slot_accessory`, `test_get_equippable_items_excludes_none_slot`, `test_get_all_items_count_matches`
    - Registration: `test_register_new_item`, `test_register_item_overwrites_existing`
    - Validation: `test_all_starter_items_have_nonempty_id`, `test_all_starter_items_have_nonempty_display_name`, `test_all_equippable_items_have_stat_bonuses`, `test_all_starter_items_have_valid_rarity`
  - _TDD: RED — tests reference `ItemDatabase` class which does not exist yet_

### 2.2 Implement ItemDatabase (GREEN)

- [ ] **2.2.1** Create `src/models/item_database.gd` with class declaration
  - _Ticket ref: FR-017, AC-021, AC-022_
  - _File: `src/models/item_database.gd`_
  - _Content: `class_name ItemDatabase` + `extends RefCounted`_

- [ ] **2.2.2** Add `_items: Dictionary = {}` internal storage
  - _Ticket ref: FR-018_

- [ ] **2.2.3** Add `_init()` constructor that calls `_build_starter_items()`
  - _Ticket ref: FR-019_

- [ ] **2.2.4** Add `get_item(id: String) -> ItemData` lookup method
  - _Ticket ref: FR-022, AC-028, AC-029_
  - _Logic: `return _items.get(id, null)` — O(1) via Dictionary (NFR-001)_

- [ ] **2.2.5** Add `has_item(id: String) -> bool` existence check
  - _Ticket ref: FR-023, AC-030, AC-031_

- [ ] **2.2.6** Add `get_items_by_rarity(rarity: Enums.ItemRarity) -> Array[ItemData]` filter
  - _Ticket ref: FR-024, AC-032, AC-033_
  - _Logic: Linear scan over `_items.values()` — O(n) acceptable (NFR-002)_

- [ ] **2.2.7** Add `get_items_by_slot(slot: Enums.EquipSlot) -> Array[ItemData]` filter
  - _Ticket ref: FR-025, AC-034, AC-035_

- [ ] **2.2.8** Add `get_equippable_items() -> Array[ItemData]` filter
  - _Ticket ref: FR-026, AC-036_

- [ ] **2.2.9** Add `get_all_items() -> Array[ItemData]` accessor
  - _Ticket ref: FR-027, AC-037_

- [ ] **2.2.10** Add `get_item_count() -> int` accessor
  - _Ticket ref: FR-028, AC-038_

- [ ] **2.2.11** Add `register_item(item: ItemData) -> void` runtime registration
  - _Ticket ref: FR-029, AC-039, AC-040_
  - _Logic: Overwrites existing id with `push_warning()` (NFR-014)_

- [ ] **2.2.12** Add `load_from_dict(data: Dictionary) -> void` bulk loader
  - _Ticket ref: FR-030_

- [ ] **2.2.13** Add `_register_from_raw(data: Dictionary) -> void` internal helper

- [ ] **2.2.14** Add `_build_starter_items()` with all 20 starter items
  - _Ticket ref: FR-019, FR-020, FR-021, AC-023 through AC-027_
  - _7 Weapons: wooden_sword (C), iron_sword (U), steel_blade (R), crystal_saber (E), wooden_staff (C), iron_staff (U), arcane_rod (R)_
  - _7 Armor: cloth_tunic (C), leather_vest (U), chainmail (R), dragon_plate (E), cloth_robe (C), silk_robe (U), enchanted_mail (R)_
  - _6 Accessories: copper_ring (C), silver_ring (U), ruby_amulet (R), sapphire_pendant (R), emerald_brooch (E), obsidian_charm (L)_
  - _Rarity coverage: Common ×5, Uncommon ×4, Rare ×5, Epic ×3, Legendary ×1 — all 5 tiers present_

> **Implementation source**: Ticket Section 16.2 has the complete, copy-pasteable `item_database.gd`.

### 2.3 Refactor (if needed)

- [ ] **2.3.1** Review `item_database.gd` for code quality: type hints, doc comments, naming conventions
  - _Run all tests after any refactor_

### Phase 2 Validation Gate

- [ ] **2.V.1** `src/models/item_database.gd` exists and is parseable GDScript
- [ ] **2.V.2** File extends `RefCounted` and declares `class_name ItemDatabase`
- [ ] **2.V.3** Constructor pre-populates with >= 20 items (AC-023)
- [ ] **2.V.4** At least 3 weapons, 3 armors, 3 accessories (AC-024, AC-025, AC-026)
- [ ] **2.V.5** All 5 rarity tiers covered (AC-027)
- [ ] **2.V.6** `get_item("iron_sword")` returns correct ItemData (AC-028)
- [ ] **2.V.7** `get_item("nonexistent_item_xyz")` returns null (AC-029)
- [ ] **2.V.8** All filter methods return correctly typed arrays
- [ ] **2.V.9** `register_item()` adds/overwrites items (AC-039, AC-040)
- [ ] **2.V.10** All ~25 ItemDatabase tests pass green
- [ ] **2.V.11** All ~20 Phase 1 ItemData tests still pass (regression check)
- [ ] **2.V.12** Commit: `"Phase 2: Add ItemDatabase with 20 starter items and query API — ~25 tests"`

---

## Phase 3: InventoryData Model (TDD)

> **Ticket References**: FR-031 through FR-050
> **AC References**: AC-041 through AC-064
> **Estimated Items**: 16
> **Dependencies**: Phase 0 complete (no dependency on Phase 1/2 — InventoryData only uses item id strings)
> **Validation Gate**: `inventory_data.gd` exists with all operations, `test_inventory_data.gd` passes ~30 tests

### 3.1 Write Test File (RED)

- [ ] **3.1.1** Create `tests/models/test_inventory_data.gd` with all test functions from ticket Section 14.3
  - _Ticket ref: Section 14.3_
  - _File: `tests/models/test_inventory_data.gd`_
  - _Class: `extends GutTest`, `class_name TestInventoryData`_
  - _Setup: `var inv: InventoryData` + `before_each()` creates fresh `InventoryData.new()`_
  - _Tests (~30):_
    - Add item: `test_add_item_creates_entry`, `test_add_item_stacks_quantity`, `test_add_item_multiple_different_items`
    - Remove item: `test_remove_item_success`, `test_remove_item_insufficient_returns_false`, `test_remove_item_nonexistent_returns_false`, `test_remove_item_exact_quantity_erases_key`, `test_remove_item_zero_quantity_not_in_list`
    - Has item: `test_has_item_sufficient`, `test_has_item_insufficient`, `test_has_item_nonexistent`
    - Get quantity: `test_get_quantity_existing_item`, `test_get_quantity_nonexistent_returns_zero`
    - List all: `test_list_all_empty_inventory`, `test_list_all_returns_correct_entries`
    - Counts: `test_get_unique_item_count`, `test_get_total_item_count`, `test_get_unique_item_count_empty`, `test_get_total_item_count_empty`
    - Clear: `test_clear_empties_inventory`
    - Serialization: `test_to_dict_format`, `test_from_dict_restores_state`, `test_from_dict_clears_existing`, `test_from_dict_missing_items_key_empties_inventory`, `test_serialization_round_trip`, `test_serialization_empty_inventory_round_trip`
    - Merge: `test_merge_combines_inventories`, `test_merge_does_not_modify_source`, `test_merge_empty_into_populated`, `test_merge_populated_into_empty`
  - _TDD: RED — tests reference `InventoryData` class which does not exist yet_

### 3.2 Implement InventoryData (GREEN)

- [ ] **3.2.1** Create `src/models/inventory_data.gd` with class declaration
  - _Ticket ref: FR-031, AC-041, AC-042_
  - _File: `src/models/inventory_data.gd`_
  - _Content: `class_name InventoryData` + `extends RefCounted`_

- [ ] **3.2.2** Add `items: Dictionary = {}` field
  - _Ticket ref: FR-032_

- [ ] **3.2.3** Add `add_item(item_id: String, qty: int) -> void` method
  - _Ticket ref: FR-033, FR-034, AC-043, AC-044_
  - _Logic: Assert `qty > 0`, create or increment entry_

- [ ] **3.2.4** Add `remove_item(item_id: String, qty: int) -> bool` method
  - _Ticket ref: FR-035, FR-036, FR-037, AC-045, AC-046, AC-047_
  - _Logic: Return `false` if insufficient, erase key at zero (NFR-015, NFR-016)_

- [ ] **3.2.5** Add `has_item(item_id: String, qty: int) -> bool` method
  - _Ticket ref: FR-038, AC-048, AC-049, AC-050_

- [ ] **3.2.6** Add `get_quantity(item_id: String) -> int` method
  - _Ticket ref: FR-039, AC-051, AC-052_

- [ ] **3.2.7** Add `list_all() -> Array[Dictionary]` method
  - _Ticket ref: FR-040, AC-053_
  - _Returns: `[{ "item_id": id, "qty": n }, ...]`_

- [ ] **3.2.8** Add `get_unique_item_count() -> int` method
  - _Ticket ref: FR-041, AC-054_

- [ ] **3.2.9** Add `get_total_item_count() -> int` method
  - _Ticket ref: FR-042, AC-055_

- [ ] **3.2.10** Add `clear() -> void` method
  - _Ticket ref: FR-043, AC-056_

- [ ] **3.2.11** Add `to_dict() -> Dictionary` serialization method
  - _Ticket ref: FR-044, AC-057_
  - _Returns: `{ "items": items.duplicate() }`_

- [ ] **3.2.12** Add `from_dict(data: Dictionary) -> void` deserialization method
  - _Ticket ref: FR-045, FR-046, AC-058, AC-059, AC-060, AC-061_
  - _Logic: Clear first, read `data.get("items", {})`, skip non-positive quantities_

- [ ] **3.2.13** Add `merge(other: InventoryData) -> void` method
  - _Ticket ref: FR-048, FR-049, FR-050, AC-062, AC-063, AC-064_
  - _Logic: Iterate `other.items`, call `add_item()` for each_

> **Implementation source**: Ticket Section 16.3 has the complete, copy-pasteable `inventory_data.gd`.

### 3.3 Refactor (if needed)

- [ ] **3.3.1** Review `inventory_data.gd` for code quality: type hints, doc comments, naming conventions
  - _Run all tests after any refactor_

### Phase 3 Validation Gate

- [ ] **3.V.1** `src/models/inventory_data.gd` exists and is parseable GDScript
- [ ] **3.V.2** File extends `RefCounted` and declares `class_name InventoryData`
- [ ] **3.V.3** `add_item()` creates/increments entries, asserts `qty > 0`
- [ ] **3.V.4** `remove_item()` is atomic — returns `false` without state change on insufficient qty
- [ ] **3.V.5** `remove_item()` erases key when quantity reaches zero (AC-047)
- [ ] **3.V.6** `to_dict()` / `from_dict()` round-trip preserves all data (AC-061)
- [ ] **3.V.7** `from_dict()` clears existing state before restoring (AC-060)
- [ ] **3.V.8** `merge()` is additive and does not modify source (AC-063)
- [ ] **3.V.9** All ~30 InventoryData tests pass green
- [ ] **3.V.10** All Phase 1 and Phase 2 tests still pass (regression check)
- [ ] **3.V.11** Commit: `"Phase 3: Add InventoryData with add/remove/query/serialize/merge — ~30 tests"`

---

## Phase 4: Cross-Model Integration & Validation

> **Ticket References**: FR-047 (round-trip), NFR-007 (testability), NFR-011 (serialization)
> **AC References**: AC-065 through AC-070
> **Estimated Items**: 10
> **Dependencies**: Phases 1–3 all complete
> **Validation Gate**: All ~75 tests pass together, no cross-class conflicts, code quality verified

This phase verifies that all three models work together correctly and meet cross-cutting quality criteria.

### 4.1 Run Full Test Suite

- [ ] **4.1.1** Run all tests in `tests/models/test_item_data.gd` — verify all pass
  - _Expected: ~20 pass, 0 fail, 0 error_

- [ ] **4.1.2** Run all tests in `tests/models/test_item_database.gd` — verify all pass
  - _Expected: ~25 pass, 0 fail, 0 error_

- [ ] **4.1.3** Run all tests in `tests/models/test_inventory_data.gd` — verify all pass
  - _Expected: ~30 pass, 0 fail, 0 error_

- [ ] **4.1.4** Run existing tests `test_enums_and_config.gd` and `test_rng.gd` — verify no regressions
  - _Expected: All existing tests still pass_

### 4.2 Cross-Model Verification

- [ ] **4.2.1** Verify ItemDatabase's starter items have valid ItemData fields
  - _Every item: non-empty id, non-empty display_name, valid rarity, valid slot_
  - _Equippable items: non-empty stat_bonuses_
  - _These are covered by `test_all_starter_items_*` tests in Phase 2_

- [ ] **4.2.2** Verify ItemData serialization round-trip works for all starter items
  - _Manual spot check: pick 3 starter items, call `to_dict()` → `from_dict()`, compare_

### 4.3 Code Quality Audit

- [ ] **4.3.1** All public methods in all 3 files have complete type hints (AC-065)
  - _Check: parameters, return types, variables_

- [ ] **4.3.2** All 3 files pass GDScript static analysis with zero errors (AC-066)

- [ ] **4.3.3** No hardcoded magic numbers — all constants named or derived from enums (AC-069)

- [ ] **4.3.4** All files follow snake_case naming convention throughout (AC-070)

### Phase 4 Validation Gate

- [ ] **4.V.1** All ~75 tests across all 3 test files pass green (AC-067)
- [ ] **4.V.2** All existing `tests/models/` tests pass (regression gate)
- [ ] **4.V.3** All code quality criteria met (AC-065–AC-070)
- [ ] **4.V.4** Commit: `"Phase 4: Cross-model integration verified — all ~75 tests green, code quality audit passed"`

---

## Phase 5: Final Validation & Cleanup

> **Ticket References**: All NFRs, playtesting verification (Section 15)
> **AC References**: AC-001 through AC-070 (final check)
> **Estimated Items**: 12
> **Dependencies**: ALL prior phases complete
> **Validation Gate**: Complete GUT suite green, all NFRs verified, task ready for dependents

### 5.1 Full GUT Test Suite

- [ ] **5.1.1** Run the complete GUT test suite across the entire project — all tests pass
  - _This includes tests from other tasks (TASK-001, TASK-002, TASK-003) if present_
  - _Zero regressions_

### 5.2 NFR Verification

- [ ] **5.2.1** NFR-001: `ItemDatabase.get_item()` is O(1) via Dictionary lookup ✓ (by implementation)
- [ ] **5.2.2** NFR-003: `InventoryData.add_item()` and `get_quantity()` are O(1) ✓ (by implementation)
- [ ] **5.2.3** NFR-007: All three classes testable in isolation — no Node, no SceneTree, no autoloads
- [ ] **5.2.4** NFR-010: All public methods have complete GDScript type hints
- [ ] **5.2.5** NFR-011: `to_dict()` output contains only JSON-compatible primitives
- [ ] **5.2.6** NFR-012: `from_dict()` does not crash on malformed input
- [ ] **5.2.7** NFR-015: `InventoryData` never produces negative quantities
- [ ] **5.2.8** NFR-016: `remove_item()` is atomic — all-or-nothing
- [ ] **5.2.9** NFR-017: All classes compatible with Godot 4.6.1 GDScript, no C# or GDExtension
- [ ] **5.2.10** NFR-018: All files pass GDScript static analysis with zero warnings

### 5.3 Documentation Verification

- [ ] **5.3.1** All public methods in all 3 source files have `##` doc comments
- [ ] **5.3.2** All 3 source files have a top-level `##` class doc comment

### Phase 5 Validation Gate

- [ ] **5.V.1** Complete GUT suite passes (all ~75 TASK-007 tests + all existing tests)
- [ ] **5.V.2** All NFRs verified
- [ ] **5.V.3** All ACs (AC-001 through AC-070) satisfied
- [ ] **5.V.4** Commit: `"TASK-007 complete: Item, Equipment & Inventory data models — ~75 tests, all green"`

---

## Phase Dependency Graph

```
Phase 0 (Pre-Flight) ──→ Phase 1 (ItemData)    ──→ Phase 2 (ItemDatabase) ──┐
                    ╲                                                         ├──→ Phase 4 (Integration)
                     ──→ Phase 3 (InventoryData) ────────────────────────────┘           │
                                                                                          ▼
                                                                                   Phase 5 (Final)
```

**Parallelism note**: Phases 1 and 3 can be executed in parallel — InventoryData does not depend on ItemData (it uses string item ids, not ItemData references). Phase 2 depends on Phase 1 (ItemDatabase instantiates ItemData objects). Phase 4 depends on all three implementation phases.

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 0 | Pre-flight & baseline verification | 8 | 0 | 0 | ⬜ Not Started |
| Phase 1 | ItemData model (TDD) | 12 | 0 | ~20 | ⬜ Not Started |
| Phase 2 | ItemDatabase model (TDD) | 14 | 0 | ~25 | ⬜ Not Started |
| Phase 3 | InventoryData model (TDD) | 16 | 0 | ~30 | ⬜ Not Started |
| Phase 4 | Cross-model integration | 10 | 0 | ~75 | ⬜ Not Started |
| Phase 5 | Final validation & cleanup | 12 | 0 | ~75 | ⬜ Not Started |
| **Total** | | **~72** | **0** | **~75** | **⬜ Phase 0 Next** |

---

## File Change Summary

### New Files

| File | Phase | Purpose |
|------|-------|---------|
| `src/models/item_data.gd` | 1 | ItemData — single item definition (class_name ItemData, extends RefCounted) |
| `src/models/item_database.gd` | 2 | ItemDatabase — static registry with 20 starter items (class_name ItemDatabase, extends RefCounted) |
| `src/models/inventory_data.gd` | 3 | InventoryData — player inventory with quantity tracking (class_name InventoryData, extends RefCounted) |
| `tests/models/test_item_data.gd` | 1 | ~20 GUT tests for ItemData |
| `tests/models/test_item_database.gd` | 2 | ~25 GUT tests for ItemDatabase |
| `tests/models/test_inventory_data.gd` | 3 | ~30 GUT tests for InventoryData |

### Modified Files

None — this task is purely additive. No existing files are modified.

### Deleted Files

None — this task is additive only.

---

## Commit Strategy

| Phase | Commit Message | Tests After |
|-------|----------------|-------------|
| 0 | _(no commit — verification only)_ | 0 (baseline check) |
| 1 | `"Phase 1: Add ItemData model with construction, accessors, and serialization — ~20 tests"` | ~20 ✅ |
| 2 | `"Phase 2: Add ItemDatabase with 20 starter items and query API — ~25 tests"` | ~45 ✅ |
| 3 | `"Phase 3: Add InventoryData with add/remove/query/serialize/merge — ~30 tests"` | ~75 ✅ |
| 4 | `"Phase 4: Cross-model integration verified — all ~75 tests green, code quality audit passed"` | ~75 ✅ |
| 5 | `"TASK-007 complete: Item, Equipment & Inventory data models — ~75 tests, all green"` | ~75 ✅ |

---

## Deviation Tracking

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| _(none yet)_ | | | | | |

> **Note**: The ticket Section 14.2 contains duplicate test functions (the test block appears twice in the ticket source). The implementation should include each unique test function only once. If duplicates are detected, record as a deviation.

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| TASK-003 enums missing or different from expected | Low | High | Verify in Phase 0; adapt enum references if names differ | 0 |
| `class_name ItemData` conflicts with existing v1 code | Low | High | Search codebase for conflicts in Phase 0 before creating | 0 |
| `GameConfig.RARITY_COLORS` missing or has different structure | Low | Medium | Verify in Phase 0; use `Color.WHITE` fallback in `get_rarity_color()` | 0, 1 |
| Godot 4.6.1 typed array syntax `Array[ItemData]` issues | Low | Medium | If unsupported, fall back to untyped `Array` and document deviation | 2 |
| GUT `assert_has` for typed arrays behaves differently | Low | Low | Use `assert_true(arr.has(item))` as fallback if needed | 1, 2, 3 |
| Starter item stat balance issues discovered during testing | Low | Low | This is a data concern, not a code bug — note and proceed | 2 |
| `from_dict()` sell_value keys deserialize as floats from JSON | Medium | Medium | Explicitly cast to `int()` in constructor — already handled by implementation | 1 |
| Existing test files in `tests/models/` have naming conflicts | Low | Low | Verified: no `test_item_data.gd`, `test_item_database.gd`, or `test_inventory_data.gd` exist | 0 |

---

## Handoff State (2025-07-22)

### What's Complete
- Implementation plan written and ready for execution

### What's In Progress
- Nothing — plan is at Phase 0 (not started)

### What's Blocked
- Nothing — TASK-003 dependency (Enums & GameConfig) is already implemented

### Next Steps
1. Execute Phase 0: Verify TASK-003 dependency, check for conflicts
2. Execute Phase 1: Write `test_item_data.gd` (RED), implement `item_data.gd` (GREEN), refactor
3. Execute Phase 2: Write `test_item_database.gd` (RED), implement `item_database.gd` with 20 items (GREEN), refactor
4. Execute Phase 3: Write `test_inventory_data.gd` (RED), implement `inventory_data.gd` (GREEN), refactor
5. Execute Phase 4: Run all tests together, verify cross-model integration, audit code quality
6. Execute Phase 5: Full GUT suite, verify NFRs, final commit

### Downstream Dependents
- **TASK-011 (Loot Table Engine)**: Will consume `ItemDatabase.get_items_by_rarity()` for weighted drop rolls
- **TASK-014 (Equipment System)**: Will consume `ItemData.stat_bonuses`, `ItemData.slot`, `ItemData.is_equippable`

---

## Ticket FR/AC Coverage Matrix

Every Functional Requirement and Acceptance Criterion from the ticket is mapped below.

### Functional Requirements → Phase Items

| FR | Description | Phase | Checkbox |
|----|-------------|-------|----------|
| FR-001 | ItemData extends RefCounted, class_name ItemData | 1 | 1.2.1 |
| FR-002 | ItemData.id is non-empty String | 1 | 1.2.2 |
| FR-003 | ItemData.display_name is non-empty String | 1 | 1.2.2 |
| FR-004 | ItemData.rarity is Enums.ItemRarity | 1 | 1.2.2 |
| FR-005 | ItemData.slot is Enums.EquipSlot, default NONE | 1 | 1.2.2 |
| FR-006 | ItemData.is_equippable = slot != NONE | 1 | 1.2.3 |
| FR-007 | ItemData.stat_bonuses is Dictionary { String → int } | 1 | 1.2.2 |
| FR-008 | ItemData.sell_value is Dictionary { Currency → int } | 1 | 1.2.2 |
| FR-009 | ItemData.description is String | 1 | 1.2.2 |
| FR-010 | get_stat_bonus() returns bonus or 0 | 1 | 1.2.4 |
| FR-011 | get_sell_value() returns value or 0 | 1 | 1.2.5 |
| FR-012 | get_rarity_color() returns from RARITY_COLORS | 1 | 1.2.6 |
| FR-013 | to_dict() serializes all fields | 1 | 1.2.7 |
| FR-014 | to_dict() converts enums to int | 1 | 1.2.7 |
| FR-015 | from_dict() static factory | 1 | 1.2.8 |
| FR-016 | from_dict() handles missing keys with defaults | 1 | 1.2.8 |
| FR-017 | ItemDatabase extends RefCounted, class_name ItemDatabase | 2 | 2.2.1 |
| FR-018 | ItemDatabase stores items in Dictionary by id | 2 | 2.2.2 |
| FR-019 | Constructor pre-populates ~20 starter items | 2 | 2.2.3, 2.2.14 |
| FR-020 | Starter items span all 5 rarity tiers | 2 | 2.2.14 |
| FR-021 | Starter items include ≥3 per slot (weapon/armor/accessory) | 2 | 2.2.14 |
| FR-022 | get_item() returns item or null | 2 | 2.2.4 |
| FR-023 | has_item() existence check | 2 | 2.2.5 |
| FR-024 | get_items_by_rarity() filter | 2 | 2.2.6 |
| FR-025 | get_items_by_slot() filter | 2 | 2.2.7 |
| FR-026 | get_equippable_items() filter | 2 | 2.2.8 |
| FR-027 | get_all_items() accessor | 2 | 2.2.9 |
| FR-028 | get_item_count() accessor | 2 | 2.2.10 |
| FR-029 | register_item() runtime registration | 2 | 2.2.11 |
| FR-030 | load_from_dict() bulk loader | 2 | 2.2.12 |
| FR-031 | InventoryData extends RefCounted, class_name InventoryData | 3 | 3.2.1 |
| FR-032 | InventoryData.items is Dictionary { String → int } | 3 | 3.2.2 |
| FR-033 | add_item() creates/increments entry | 3 | 3.2.3 |
| FR-034 | add_item() asserts qty > 0 | 3 | 3.2.3 |
| FR-035 | remove_item() decreases quantity, returns true | 3 | 3.2.4 |
| FR-036 | remove_item() returns false if insufficient | 3 | 3.2.4 |
| FR-037 | remove_item() erases key at zero | 3 | 3.2.4 |
| FR-038 | has_item() checks quantity >= requested | 3 | 3.2.5 |
| FR-039 | get_quantity() returns qty or 0 | 3 | 3.2.6 |
| FR-040 | list_all() returns array of { item_id, qty } | 3 | 3.2.7 |
| FR-041 | get_unique_item_count() | 3 | 3.2.8 |
| FR-042 | get_total_item_count() | 3 | 3.2.9 |
| FR-043 | clear() removes all items | 3 | 3.2.10 |
| FR-044 | to_dict() returns { "items": { id: qty } } | 3 | 3.2.11 |
| FR-045 | from_dict() clears then restores | 3 | 3.2.12 |
| FR-046 | from_dict() handles missing "items" key | 3 | 3.2.12 |
| FR-047 | Serialization round-trip preserves all data | 3, 4 | 3.2.12, 4.2.2 |
| FR-048 | merge() adds all items from other | 3 | 3.2.13 |
| FR-049 | merge() does not modify source | 3 | 3.2.13 |
| FR-050 | merge() sums quantities correctly | 3 | 3.2.13 |

### Acceptance Criteria → Validation Gates

| AC | Description | Phase | Verification |
|----|-------------|-------|--------------|
| AC-001 | item_data.gd exists at src/models/ | 1 | 1.V.1 |
| AC-002 | ItemData extends RefCounted, class_name | 1 | 1.V.2 |
| AC-003 | id typed as String, non-empty | 1 | 1.V.3 |
| AC-004 | display_name typed as String, non-empty | 1 | 1.V.3 |
| AC-005 | rarity typed as Enums.ItemRarity | 1 | 1.V.3 |
| AC-006 | slot typed as Enums.EquipSlot, default NONE | 1 | 1.V.3 |
| AC-007 | is_equippable true when slot != NONE | 1 | 1.1.1 (tests) |
| AC-008 | stat_bonuses Dictionary, String → int | 1 | 1.1.1 (tests) |
| AC-009 | sell_value Dictionary, Currency → int | 1 | 1.1.1 (tests) |
| AC-010 | description typed as String | 1 | 1.V.3 |
| AC-011 | get_stat_bonus("attack") correct | 1 | 1.1.1 (tests) |
| AC-012 | get_stat_bonus("nonexistent") returns 0 | 1 | 1.1.1 (tests) |
| AC-013 | get_sell_value(GOLD) correct | 1 | 1.1.1 (tests) |
| AC-014 | get_sell_value() missing currency returns 0 | 1 | 1.1.1 (tests) |
| AC-015 | get_rarity_color() returns correct color | 1 | 1.1.1 (tests) |
| AC-016 | to_dict() returns all fields | 1 | 1.1.1 (tests) |
| AC-017 | to_dict() stores enums as ints | 1 | 1.1.1 (tests) |
| AC-018 | from_dict() reconstructs equivalent ItemData | 1 | 1.1.1 (tests) |
| AC-019 | from_dict() missing keys → defaults | 1 | 1.1.1 (tests) |
| AC-020 | Round-trip from_dict(to_dict()) identity | 1 | 1.1.1 (tests) |
| AC-021 | item_database.gd exists at src/models/ | 2 | 2.V.1 |
| AC-022 | ItemDatabase extends RefCounted, class_name | 2 | 2.V.2 |
| AC-023 | Constructor pre-populates ≥20 items | 2 | 2.V.3 |
| AC-024 | At least 3 weapons | 2 | 2.V.4 |
| AC-025 | At least 3 armors | 2 | 2.V.4 |
| AC-026 | At least 3 accessories | 2 | 2.V.4 |
| AC-027 | All 5 rarity tiers present | 2 | 2.V.5 |
| AC-028 | get_item("iron_sword") returns correct data | 2 | 2.1.1 (tests) |
| AC-029 | get_item("nonexistent") returns null | 2 | 2.1.1 (tests) |
| AC-030 | has_item("iron_sword") returns true | 2 | 2.1.1 (tests) |
| AC-031 | has_item("nonexistent") returns false | 2 | 2.1.1 (tests) |
| AC-032 | get_items_by_rarity(COMMON) returns only Common | 2 | 2.1.1 (tests) |
| AC-033 | get_items_by_rarity(LEGENDARY) returns only Legendary | 2 | 2.1.1 (tests) |
| AC-034 | get_items_by_slot(WEAPON) returns only weapons | 2 | 2.1.1 (tests) |
| AC-035 | get_items_by_slot(ACCESSORY) returns only accessories | 2 | 2.1.1 (tests) |
| AC-036 | get_equippable_items() excludes NONE slot | 2 | 2.1.1 (tests) |
| AC-037 | get_all_items() returns all items | 2 | 2.1.1 (tests) |
| AC-038 | get_item_count() matches registered count | 2 | 2.1.1 (tests) |
| AC-039 | register_item() adds new item | 2 | 2.1.1 (tests) |
| AC-040 | register_item() overwrites existing | 2 | 2.1.1 (tests) |
| AC-041 | inventory_data.gd exists at src/models/ | 3 | 3.V.1 |
| AC-042 | InventoryData extends RefCounted, class_name | 3 | 3.V.2 |
| AC-043 | add_item creates entry with qty 1 | 3 | 3.1.1 (tests) |
| AC-044 | add_item stacks to qty 4 | 3 | 3.1.1 (tests) |
| AC-045 | remove_item success reduces qty | 3 | 3.1.1 (tests) |
| AC-046 | remove_item insufficient returns false | 3 | 3.1.1 (tests) |
| AC-047 | remove_item erases at zero | 3 | 3.1.1 (tests) |
| AC-048 | has_item true when sufficient | 3 | 3.1.1 (tests) |
| AC-049 | has_item false when insufficient | 3 | 3.1.1 (tests) |
| AC-050 | has_item false for nonexistent | 3 | 3.1.1 (tests) |
| AC-051 | get_quantity returns current qty | 3 | 3.1.1 (tests) |
| AC-052 | get_quantity returns 0 for nonexistent | 3 | 3.1.1 (tests) |
| AC-053 | list_all returns correct entries | 3 | 3.1.1 (tests) |
| AC-054 | get_unique_item_count correct | 3 | 3.1.1 (tests) |
| AC-055 | get_total_item_count correct | 3 | 3.1.1 (tests) |
| AC-056 | clear empties inventory | 3 | 3.1.1 (tests) |
| AC-057 | to_dict format correct | 3 | 3.1.1 (tests) |
| AC-058 | from_dict restores state | 3 | 3.1.1 (tests) |
| AC-059 | from_dict missing items key → empty | 3 | 3.1.1 (tests) |
| AC-060 | from_dict clears existing | 3 | 3.1.1 (tests) |
| AC-061 | Serialization round-trip preserves data | 3 | 3.1.1 (tests) |
| AC-062 | merge combines inventories | 3 | 3.1.1 (tests) |
| AC-063 | merge does not modify source | 3 | 3.1.1 (tests) |
| AC-064 | merge sums overlapping items | 3 | 3.1.1 (tests) |
| AC-065 | All methods have type hints | 4 | 4.3.1 |
| AC-066 | All files pass static analysis | 4 | 4.3.2 |
| AC-067 | All test files pass with zero failures | 4 | 4.1.1–4.1.3 |
| AC-068 | No class_name conflicts | 0 | 0.2.1–0.2.3 |
| AC-069 | No hardcoded magic numbers | 4 | 4.3.3 |
| AC-070 | snake_case naming throughout | 4 | 4.3.4 |

---

*End of TASK-007 Implementation Plan*
