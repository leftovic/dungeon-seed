# TASK-014: Equipment System (Equip/Unequip/Stat Calc) — Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-014-equipment-system.md`
> **Status**: Planning
> **Created**: 2025-01-18
> **Branch**: `users/wrstl/task-014-equipment-system`
> **Repo**: `dev-agent-tool` (local — `C:\Users\wrstl\source\dev-agent-tool`)
> **Methodology**: TDD Red-Green-Refactor (mandatory for all phases)
> **Complexity**: 5 points (Moderate)
> **Estimated Phases**: 5
> **Estimated Checkboxes**: ~55

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents in this order:

1. **This file** (you're reading it) — the phased checklist of what to do, with status
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-014-equipment-system.md`** — the full technical spec (39.5 KB)
3. **`src/models/adventurer_data.gd`** — AdventurerData model (has equipment slots)
4. **`src/models/item_data.gd`** — ItemData model (has stat_bonuses, slot, is_equippable)
5. **`src/models/enums.gd`** — Enums (EquipSlot, AdventurerClass, ItemRarity)
6. **`src/models/game_config.gd`** — GameConfig constants

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| **Equipment service** | `src/services/equipment_manager.gd` | **NEW** — `class_name EquipmentManager`, extends RefCounted |
| **AdventurerData model** | `src/models/adventurer_data.gd` | **EXISTS** — has `equipment` dict, needs `get_effective_stats()` updated |
| **ItemData model** | `src/models/item_data.gd` | **EXISTS** — has `slot`, `stat_bonuses`, `get_stat_bonus()` |
| **ItemDatabase** | `src/models/item_database.gd` | **EXISTS** — pre-populated with starter items |
| **Enums** | `src/models/enums.gd` | **EXISTS** — EquipSlot, AdventurerClass |
| **EventBus** | `src/autoloads/event_bus.gd` | **EXISTS** — needs `equipment_changed` signal added |
| **Unit tests** | `tests/unit/test_equipment_manager.gd` | **NEW** — GUT test suite for equipment service |

### Key Concepts (5-minute primer)

- **EquipmentManager**: RefCounted service that handles equip/unequip operations and stat recalculation. No instance state — operates on AdventurerData.
- **3 Equipment Slots**: WEAPON (ATK bonuses), ARMOR (DEF/HP bonuses), ACCESSORY (utility: SPD/PER/MP).
- **Stat Calculation**: `effective_stat = (base_stat + sum(equipment_bonuses)) × condition_modifier`
- **Condition Modifiers**: HEALTHY = ×1.0, FATIGUED = ×0.9, INJURED = ×0.75, EXHAUSTED = ×0.6
- **Slot Validation**: Weapons must match class (Warrior uses swords/axes, Mage uses staves/wands). Armor types: Heavy/Medium/Light.
- **Equipment Storage**: AdventurerData stores item IDs (StringName), not item objects. IDs reference ItemDatabase.
- **Recalculation**: Eager (not lazy). Every equip/unequip immediately recalculates `effective_stats`.
- **ItemDatabase**: Pre-populated with 20 starter items (TASK-007). Weapons, armor, accessories across all rarity tiers.

### Build & Test Commands

```powershell
# Run GUT tests (headless)
& "C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --path "C:\Users\wrstl\source\dev-agent-tool" --headless -s "res://addons/gut/gut_cmdln.gd" -gdir="res://tests/" -ginclude_subdirs

# Run specific test file
& "C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --path "C:\Users\wrstl\source\dev-agent-tool" --headless -s "res://addons/gut/gut_cmdln.gd" -gtest="res://tests/unit/test_equipment_manager.gd"

# Open project in editor (for manual testing)
& "C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --editor --path "C:\Users\wrstl\source\dev-agent-tool"
```

### Regression Gate

Before AND after every phase:
1. All existing tests in `tests/unit/` pass green
2. `src/models/adventurer_data.gd` — only `get_effective_stats()` is modified
3. `src/models/item_data.gd` is unchanged (TASK-007 output)
4. `src/models/item_database.gd` is unchanged
5. All new tests written in this task pass green

---

## Current State Analysis

### What Exists Today

| Item | Status | Location |
|------|--------|----------|
| `AdventurerData` model | ✅ Exists | `src/models/adventurer_data.gd` — has `equipment` dict with "weapon"/"armor"/"accessory" keys |
| `ItemData` model | ✅ Exists | `src/models/item_data.gd` — has `slot`, `stat_bonuses`, `get_stat_bonus()` |
| `ItemDatabase` | ✅ Exists | `src/models/item_database.gd` — pre-populated with ~20 starter items |
| `Enums.EquipSlot` | ✅ Exists | `src/models/enums.gd` — NONE, WEAPON, ARMOR, ACCESSORY |
| `Enums.AdventurerClass` | ✅ Exists | `src/models/enums.gd` — WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL |
| `GameConfig.BASE_STATS` | ✅ Exists | `src/models/game_config.gd` — stat blocks per class |
| `EventBus` autoload | ✅ Exists | `src/autoloads/event_bus.gd` — central signal hub |
| GUT test framework | ✅ Exists | `addons/gut/` — installed and configured |

### What's Missing (Gap Analysis)

| Item | Status | Required By |
|------|--------|-------------|
| `EquipmentManager` service | ❌ Missing | FR-001 through FR-021 |
| `EventBus.equipment_changed` signal | ❌ Missing | FR-018, FR-019, FR-020 |
| `AdventurerData.get_effective_stats()` implementation | ❌ Placeholder | FR-010 through FR-014 (currently returns base stats only) |
| `test_equipment_manager.gd` | ❌ Missing | Section 14, all ACs |

### What Must NOT Change

- `src/models/item_data.gd` — TASK-007 output, provides ItemData class
- `src/models/item_database.gd` — TASK-007 output, provides starter items
- `src/models/enums.gd` — all enums already defined, no new enums needed
- `src/models/game_config.gd` — all constants already defined

### What CAN Change (with care)

- `src/models/adventurer_data.gd` — ONLY `get_effective_stats()` method. Must remain backward compatible.

---

## Development Methodology: TDD Red-Green-Refactor

**ALL implementation work follows strict TDD.** No exceptions.

### The Cycle

1. **RED**: Write a failing test that describes the desired behavior
   - The test MUST fail initially — if it passes, you don't need the test
   - The test MUST be specific and descriptive: `test_method_scenario_expected`
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

### Test Naming Convention (GUT)

```gdscript
func test_equip_valid_weapon_returns_ok() -> void:
func test_equip_sets_equipped_slot() -> void:
func test_unequip_clears_slot() -> void:
func test_recalculate_stats_adds_equipment_bonuses() -> void:
func test_condition_modifier_fatigued() -> void:
```

### Test Structure

Every test follows Arrange-Act-Assert:
```gdscript
func test_method_scenario_expected() -> void:
	# Arrange — set up test data
	var eq_mgr := EquipmentManager.new()
	var warrior := _create_test_warrior()
	var sword := _create_test_sword()
	
	# Act — execute the method
	var result := eq_mgr.equip_item(warrior, sword, Enums.EquipSlot.WEAPON)
	
	# Assert — verify the outcome
	assert_eq(result, OK, "Equip valid weapon must return OK")
	assert_eq(warrior.equipment["weapon"], sword.id, "Weapon slot must be set")
```

### Enterprise Coverage Standards

Every public method must have tests covering:
- ✅ Happy path (normal input → expected output)
- ✅ Edge cases (empty, null, boundary values)
- ✅ Error cases (invalid input → graceful handling)
- ✅ Integration (methods working together)

Minimum coverage per phase:
- **Pass**: Normal inputs produce correct outputs
- **Fail**: Error inputs produce correct errors
- **Invalid**: Slot type mismatch, class restrictions
- **Boundary**: All 6 classes, all 3 slots, all 4 conditions

---

## Phase 1: EquipmentManager Core Structure & Validation

> **Ticket References**: FR-001, FR-006 through FR-009
> **AC References**: AC-001, AC-021 through AC-028
> **Estimated Items**: 12
> **Dependencies**: None (first implementation phase)
> **Validation Gate**: EquipmentManager class exists, validation logic works for all equipment types

### 1.1 Create EquipmentManager Class File

- [ ] **1.1.1** Create `src/services/equipment_manager.gd`
  - _Ticket ref: FR-001_
  - _File: `src/services/equipment_manager.gd`_
  - _TDD: N/A (file creation)_

- [ ] **1.1.2** Add `class_name EquipmentManager` declaration
  - _Ticket ref: FR-001_
  - _File: `src/services/equipment_manager.gd`_
  - _Note: Safe to use `class_name` — this is NOT an autoload_

- [ ] **1.1.3** Add `extends RefCounted` declaration
  - _Ticket ref: FR-001_
  - _File: `src/services/equipment_manager.gd`_

### 1.2 Create Test File

- [ ] **1.2.1** Create `tests/unit/test_equipment_manager.gd`
  - _Ticket ref: Section 14_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _Extends `GutTest`_

- [ ] **1.2.2** Add helper methods: `_create_test_warrior()`, `_create_test_sword()`, `_create_test_armor()`
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _Creates test AdventurerData and ItemData instances_

- [ ] **1.2.3** Write test: `test_equipment_manager_instantiates()`
  - _Ticket ref: AC-001_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _TDD: RED test_

### 1.3 Implement Slot Validation

- [ ] **1.3.1** Write test: `test_validate_equipment_weapon_to_weapon_slot_returns_ok()`
  - _Ticket ref: AC-021_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _TDD: RED test_

- [ ] **1.3.2** Implement `validate_equipment(adventurer, item, slot) -> Error`
  - _Ticket ref: FR-006_
  - _File: `src/services/equipment_manager.gd`_
  - _Check: item.slot == slot_

- [ ] **1.3.3** Write test: `test_validate_equipment_armor_to_weapon_slot_returns_invalid_parameter()`
  - _Ticket ref: AC-028_
  - _File: `tests/unit/test_equipment_manager.gd`_

- [ ] **1.3.4** Write test: `test_validate_equipment_warrior_can_equip_sword()`
  - _Ticket ref: AC-021_
  - _File: `tests/unit/test_equipment_manager.gd`_

- [ ] **1.3.5** Write test: `test_validate_equipment_warrior_cannot_equip_bow()`
  - _Ticket ref: AC-022_
  - _File: `tests/unit/test_equipment_manager.gd`_

- [ ] **1.3.6** Write test: `test_validate_equipment_mage_can_equip_staff()`
  - _Ticket ref: AC-023_
  - _File: `tests/unit/test_equipment_manager.gd`_

- [ ] **1.3.7** Write test: `test_validate_equipment_mage_cannot_equip_axe()`
  - _Ticket ref: AC-024_
  - _File: `tests/unit/test_equipment_manager.gd`_

- [ ] **1.3.8** Write test: `test_validate_equipment_all_classes_can_equip_accessory()`
  - _Ticket ref: AC-027_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _Test all 6 classes with an accessory_

### Phase 1 Validation Gate

- [ ] **1.V.1** All tests pass (9+ new tests)
- [ ] **1.V.2** EquipmentManager can be instantiated: `var em = EquipmentManager.new()`
- [ ] **1.V.3** Validation correctly accepts/rejects weapon types per class
- [ ] **1.V.4** Validation correctly rejects slot type mismatches
- [ ] **1.V.5** Commit: `"Phase 1: EquipmentManager validation logic — 9 tests pass"`

---

## Phase 2: Equip & Unequip Implementation

> **Ticket References**: FR-002, FR-003, FR-004, FR-005, FR-019, FR-020
> **AC References**: AC-002 through AC-009, AC-010 through AC-014
> **Estimated Items**: 16
> **Dependencies**: Phase 1 complete
> **Validation Gate**: Can equip/unequip items, slots are updated, EventBus signals emit

### 2.1 Implement equip_item()

- [ ] **2.1.1** Write test: `test_equip_valid_weapon_returns_ok()`
  - _Ticket ref: AC-002_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _TDD: RED test_

- [ ] **2.1.2** Implement `equip_item(adventurer, item, slot) -> Error`
  - _Ticket ref: FR-002_
  - _File: `src/services/equipment_manager.gd`_
  - _Validate, unequip current if needed, set slot, emit signal_

- [ ] **2.1.3** Write test: `test_equip_sets_equipped_slot()`
  - _Ticket ref: AC-003_
  - _File: `tests/unit/test_equipment_manager.gd`_

- [ ] **2.1.4** Write test: `test_equip_invalid_weapon_returns_unavailable()`
  - _Ticket ref: AC-006_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _Warrior trying to equip a Bow_

- [ ] **2.1.5** Write test: `test_equip_wrong_slot_returns_invalid_parameter()`
  - _Ticket ref: AC-007_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _Armor item to WEAPON slot_

- [ ] **2.1.6** Write test: `test_equip_replaces_current_item()`
  - _Ticket ref: AC-005_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _Equip sword1, then equip sword2, verify sword1 is unequipped_

### 2.2 Implement unequip_slot()

- [ ] **2.2.1** Write test: `test_unequip_clears_slot()`
  - _Ticket ref: AC-011_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _TDD: RED test_

- [ ] **2.2.2** Implement `unequip_slot(adventurer, slot) -> ItemData`
  - _Ticket ref: FR-003_
  - _File: `src/services/equipment_manager.gd`_
  - _Get item ID, clear slot, emit signal, return ItemData (or null)_

- [ ] **2.2.3** Write test: `test_unequip_returns_item_data()`
  - _Ticket ref: AC-010_
  - _File: `tests/unit/test_equipment_manager.gd`_

- [ ] **2.2.4** Write test: `test_unequip_empty_slot_returns_null()`
  - _Ticket ref: AC-013_
  - _File: `tests/unit/test_equipment_manager.gd`_

### 2.3 EventBus Integration

- [ ] **2.3.1** Add signal to EventBus: `signal equipment_changed(adventurer_id: String, slot: Enums.EquipSlot)`
  - _Ticket ref: FR-018_
  - _File: `src/autoloads/event_bus.gd`_

- [ ] **2.3.2** Write test: `test_equip_emits_equipment_changed_signal()`
  - _Ticket ref: AC-008_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _Use `watch_signals(EventBus)`, `assert_signal_emitted`_

- [ ] **2.3.3** Emit signal in `equip_item()` on success
  - _Ticket ref: FR-019_
  - _File: `src/services/equipment_manager.gd`_
  - _`EventBus.equipment_changed.emit(adventurer.id, slot)`_

- [ ] **2.3.4** Write test: `test_equip_does_not_emit_signal_on_failure()`
  - _Ticket ref: AC-009_
  - _File: `tests/unit/test_equipment_manager.gd`_

- [ ] **2.3.5** Write test: `test_unequip_emits_equipment_changed_signal()`
  - _Ticket ref: AC-014_
  - _File: `tests/unit/test_equipment_manager.gd`_

- [ ] **2.3.6** Emit signal in `unequip_slot()` after clearing slot
  - _Ticket ref: FR-020_
  - _File: `src/services/equipment_manager.gd`_

### Phase 2 Validation Gate

- [ ] **2.V.1** All tests pass (12+ new tests)
- [ ] **2.V.2** Can equip a weapon: `em.equip_item(warrior, sword, WEAPON)` returns OK
- [ ] **2.V.3** Equipped slot is set: `warrior.equipment["weapon"] == sword.id`
- [ ] **2.V.4** Can unequip: `em.unequip_slot(warrior, WEAPON)` returns ItemData
- [ ] **2.V.5** EventBus signal emits on equip and unequip
- [ ] **2.V.6** Commit: `"Phase 2: Equip/unequip with EventBus signals — 12 tests pass"`

---

## Phase 3: Stat Recalculation & Condition Modifiers

> **Ticket References**: FR-010 through FR-014
> **AC References**: AC-004, AC-012, AC-015 through AC-020
> **Estimated Items**: 14
> **Dependencies**: Phase 2 complete
> **Validation Gate**: Stat recalculation works, equipment bonuses apply, condition modifiers apply

### 3.1 Implement recalculate_stats()

- [ ] **3.1.1** Write test: `test_recalculate_stats_warrior_no_equipment()`
  - _Ticket ref: FR-014_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _TDD: RED test — effective_stats == base_stats_

- [ ] **3.1.2** Implement `recalculate_stats(adventurer) -> void`
  - _Ticket ref: FR-010_
  - _File: `src/services/equipment_manager.gd`_
  - _Start with base stats, add equipment bonuses, apply condition modifier_

- [ ] **3.1.3** Write test: `test_recalculate_stats_warrior_with_sword_healthy()`
  - _Ticket ref: AC-015_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _Level 1 Warrior (ATK=15) + Sword (ATK+10) = effective ATK=25_

- [ ] **3.1.4** Update `AdventurerData.get_effective_stats()` to call `recalculate_stats()`
  - _Ticket ref: FR-010_
  - _File: `src/models/adventurer_data.gd`_
  - _Note: This is the ONLY change to AdventurerData_

- [ ] **3.1.5** Write test: `test_equip_triggers_stat_recalculation()`
  - _Ticket ref: AC-004_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _Equip sword, verify effective_stats.attack increased_

- [ ] **3.1.6** Call `recalculate_stats()` in `equip_item()` after setting slot
  - _Ticket ref: FR-002_
  - _File: `src/services/equipment_manager.gd`_

- [ ] **3.1.7** Write test: `test_unequip_triggers_stat_recalculation()`
  - _Ticket ref: AC-012_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _Unequip sword, verify effective_stats.attack decreased_

- [ ] **3.1.8** Call `recalculate_stats()` in `unequip_slot()` after clearing slot
  - _Ticket ref: FR-003_
  - _File: `src/services/equipment_manager.gd`_

### 3.2 Implement Equipment Bonus Aggregation

- [ ] **3.2.1** Write test: `test_recalculate_stats_armor_adds_hp_and_defense()`
  - _Ticket ref: AC-018_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _Equip armor with HP+25, DEF+10_

- [ ] **3.2.2** Write test: `test_recalculate_stats_accessory_adds_speed()`
  - _Ticket ref: AC-019_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _Equip accessory with SPD+5_

- [ ] **3.2.3** Write test: `test_recalculate_stats_three_items_cumulative()`
  - _Ticket ref: AC-020_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _Equip weapon + armor + accessory, verify all bonuses apply_

- [ ] **3.2.4** Implement bonus aggregation in `recalculate_stats()`
  - _Ticket ref: FR-010_
  - _File: `src/services/equipment_manager.gd`_
  - _Loop through "weapon", "armor", "accessory" slots, sum stat_bonuses_

### 3.3 Implement Condition Modifiers

- [ ] **3.3.1** Write test: `test_condition_modifier_fatigued()`
  - _Ticket ref: AC-016_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _(15 + 10) × 0.9 = 22.5 (or 22 if int)_

- [ ] **3.3.2** Write test: `test_condition_modifier_injured()`
  - _Ticket ref: AC-017_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _(15 + 10) × 0.75 = 18.75 (or 18 if int)_

- [ ] **3.3.3** Implement `_get_condition_modifier(condition) -> float`
  - _Ticket ref: FR-010_
  - _File: `src/services/equipment_manager.gd`_
  - _HEALTHY=1.0, FATIGUED=0.9, INJURED=0.75, EXHAUSTED=0.6_

- [ ] **3.3.4** Apply condition modifier in `recalculate_stats()`
  - _Ticket ref: FR-010_
  - _File: `src/services/equipment_manager.gd`_
  - _Multiply all stats by modifier after adding equipment bonuses_

### Phase 3 Validation Gate

- [ ] **3.V.1** All tests pass (13+ new tests)
- [ ] **3.V.2** Stat recalculation works: base + equipment bonuses
- [ ] **3.V.3** Condition modifiers apply: FATIGUED = ×0.9, INJURED = ×0.75
- [ ] **3.V.4** Multiple items stack correctly (weapon + armor + accessory)
- [ ] **3.V.5** Commit: `"Phase 3: Stat recalculation with condition modifiers — 13 tests pass"`

---

## Phase 4: Helper Methods & Query Operations

> **Ticket References**: FR-004, FR-005
> **AC References**: None (utility methods)
> **Estimated Items**: 8
> **Dependencies**: Phase 3 complete
> **Validation Gate**: Helper methods work for querying equipped items

### 4.1 Implement get_equipped_item()

- [ ] **4.1.1** Write test: `test_get_equipped_item_returns_item_data()`
  - _Ticket ref: FR-004_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _TDD: RED test_

- [ ] **4.1.2** Implement `get_equipped_item(adventurer, slot) -> ItemData`
  - _Ticket ref: FR-004_
  - _File: `src/services/equipment_manager.gd`_
  - _Get item ID from slot, look up in ItemDatabase, return ItemData_

- [ ] **4.1.3** Write test: `test_get_equipped_item_empty_slot_returns_null()`
  - _Ticket ref: FR-004_
  - _File: `tests/unit/test_equipment_manager.gd`_

### 4.2 Implement get_all_equipped()

- [ ] **4.2.1** Write test: `test_get_all_equipped_returns_dictionary()`
  - _Ticket ref: FR-005_
  - _File: `tests/unit/test_equipment_manager.gd`_

- [ ] **4.2.2** Implement `get_all_equipped(adventurer) -> Dictionary`
  - _Ticket ref: FR-005_
  - _File: `src/services/equipment_manager.gd`_
  - _Return `{WEAPON: item_data, ARMOR: item_data, ACCESSORY: item_data}`_

- [ ] **4.2.3** Write test: `test_get_all_equipped_empty_slots_are_null()`
  - _Ticket ref: FR-005_
  - _File: `tests/unit/test_equipment_manager.gd`_

### 4.3 Add Helper Methods for Slot Access

- [ ] **4.3.1** Implement `_get_slot_value(adventurer, slot) -> String`
  - _Ticket ref: Implementation detail_
  - _File: `src/services/equipment_manager.gd`_
  - _Returns `adventurer.equipment["weapon"]`, etc._

- [ ] **4.3.2** Implement `_set_slot_value(adventurer, slot, value: String) -> void`
  - _Ticket ref: Implementation detail_
  - _File: `src/services/equipment_manager.gd`_
  - _Sets `adventurer.equipment["weapon"] = value`_

### Phase 4 Validation Gate

- [ ] **4.V.1** All tests pass (5+ new tests)
- [ ] **4.V.2** Can query equipped item: `em.get_equipped_item(warrior, WEAPON)` returns ItemData
- [ ] **4.V.3** Can get all equipped: `em.get_all_equipped(warrior)` returns dict
- [ ] **4.V.4** Empty slots return null
- [ ] **4.V.5** Commit: `"Phase 4: Helper methods for querying equipment — 5 tests pass"`

---

## Phase 5: Armor/Weapon Type Validation & Final Integration

> **Ticket References**: FR-007, FR-008, FR-009
> **AC References**: AC-025, AC-026, PAC-001 through PAC-005
> **Estimated Items**: 12
> **Dependencies**: Phase 4 complete
> **Validation Gate**: Armor type restrictions work, all PACs pass

### 5.1 Implement Armor Type Validation

- [ ] **5.1.1** Write test: `test_validate_equipment_warrior_can_equip_heavy_armor()`
  - _Ticket ref: AC-025_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _TDD: RED test_

- [ ] **5.1.2** Implement `_can_equip_armor_type(class_type, armor_type) -> bool`
  - _Ticket ref: FR-008_
  - _File: `src/services/equipment_manager.gd`_
  - _Warrior/Sentinel: HEAVY, Ranger/Alchemist: MEDIUM, Mage/Rogue: LIGHT_

- [ ] **5.1.3** Write test: `test_validate_equipment_mage_cannot_equip_heavy_armor()`
  - _Ticket ref: AC-026_
  - _File: `tests/unit/test_equipment_manager.gd`_

- [ ] **5.1.4** Add armor type check in `validate_equipment()`
  - _Ticket ref: FR-006_
  - _File: `src/services/equipment_manager.gd`_
  - _If item is armor, check `_can_equip_armor_type()`_

### 5.2 Implement Weapon Type Validation (if not done in Phase 1)

- [ ] **5.2.1** Verify all 6 classes have weapon type restrictions tested
  - _Ticket ref: FR-007_
  - _File: `tests/unit/test_equipment_manager.gd`_
  - _Warrior: swords/axes/hammers, Mage: staves/wands/tomes, etc._

- [ ] **5.2.2** Implement `_can_equip_weapon_type(class_type, weapon_type) -> bool` if not done
  - _Ticket ref: FR-007_
  - _File: `src/services/equipment_manager.gd`_

### 5.3 ItemDatabase Integration

- [ ] **5.3.1** Add helper: `_get_item_from_database(item_id: String) -> ItemData`
  - _File: `src/services/equipment_manager.gd`_
  - _Look up item in ItemDatabase (future: global registry)_

- [ ] **5.3.2** Update `get_equipped_item()` to use ItemDatabase lookup
  - _Ticket ref: FR-004_
  - _File: `src/services/equipment_manager.gd`_

- [ ] **5.3.3** Update `unequip_slot()` to return actual ItemData from database
  - _Ticket ref: FR-003_
  - _File: `src/services/equipment_manager.gd`_

### 5.4 Playtesting Acceptance Criteria (PACs)

- [ ] **5.4.1** Manual PAC: Equip a Rare Sword to Warrior, verify ATK increases
  - _Ticket ref: PAC-001_
  - _Action: Run in editor console_

- [ ] **5.4.2** Manual PAC: Unequip the Sword, verify ATK returns to base
  - _Ticket ref: PAC-002_

- [ ] **5.4.3** Manual PAC: Equip weapon + armor + accessory, verify all bonuses apply
  - _Ticket ref: PAC-003_

- [ ] **5.4.4** Manual PAC: Try to equip Bow to Warrior, verify error message
  - _Ticket ref: PAC-004_

- [ ] **5.4.5** Manual PAC: Save with equipped items, reload, verify equipment preserved
  - _Ticket ref: PAC-005_
  - _Note: Requires save/load system from TASK-009_

### 5.5 Final Validation

- [ ] **5.5.1** Run full test suite: all 45+ tests pass
- [ ] **5.5.2** Verify EventBus signal exists and emits
- [ ] **5.5.3** Verify no regressions in existing AdventurerData tests
- [ ] **5.5.4** Verify ItemDatabase still returns starter items

### Phase 5 Validation Gate

- [ ] **5.V.1** All tests pass (full suite: 45+ tests)
- [ ] **5.V.2** Armor type restrictions work correctly
- [ ] **5.V.3** All 5 PACs pass via manual testing
- [ ] **5.V.4** ItemDatabase integration works
- [ ] **5.V.5** No regressions in existing code
- [ ] **5.V.6** Commit: `"Phase 5: Armor type validation and final integration — 45+ tests pass"`

---

## Phase Dependency Graph

```
Phase 1 (Validation Logic)
   ↓
Phase 2 (Equip/Unequip)
   ↓
Phase 3 (Stat Recalculation)
   ↓
Phase 4 (Helper Methods)
   ↓
Phase 5 (Final Validation & Integration)
```

All phases are sequential — each depends on the previous phase completing.

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 1 | Validation Logic | 12 | 0 | 9 | ⬜ Not Started |
| Phase 2 | Equip/Unequip | 16 | 0 | 12 | ⬜ Not Started |
| Phase 3 | Stat Recalculation | 14 | 0 | 13 | ⬜ Not Started |
| Phase 4 | Helper Methods | 8 | 0 | 5 | ⬜ Not Started |
| Phase 5 | Final Integration | 12 | 0 | 6 | ⬜ Not Started |
| **Total** | | **62** | **0** | **45** | **⬜ Planning** |

---

## File Change Summary

### New Files
| File | Phase | Purpose |
|------|-------|---------|
| `src/services/equipment_manager.gd` | 1 | EquipmentManager service class |
| `tests/unit/test_equipment_manager.gd` | 1 | Unit tests for EquipmentManager |

### Modified Files
| File | Phase | Change |
|------|-------|--------|
| `src/autoloads/event_bus.gd` | 2 | Add `equipment_changed` signal |
| `src/models/adventurer_data.gd` | 3 | Update `get_effective_stats()` to call EquipmentManager.recalculate_stats() |

### No Changes
- `src/models/item_data.gd` — unchanged
- `src/models/item_database.gd` — unchanged
- `src/models/enums.gd` — unchanged
- `src/models/game_config.gd` — unchanged
- All other existing files — unchanged

---

## Commit Strategy

| Phase | Commit Message | Tests After |
|-------|----------------|-------------|
| 1 | `"Phase 1: EquipmentManager validation logic — 9 tests pass"` | 9 |
| 2 | `"Phase 2: Equip/unequip with EventBus signals — 12 tests pass"` | 21 |
| 3 | `"Phase 3: Stat recalculation with condition modifiers — 13 tests pass"` | 34 |
| 4 | `"Phase 4: Helper methods for querying equipment — 5 tests pass"` | 39 |
| 5 | `"Phase 5: Armor type validation and final integration — 45+ tests pass"` | 45 |

---

## Deviation Tracking

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| _No deviations yet_ | | | | | |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| ItemData missing properties | Low | High | Verify TASK-007 output before starting Phase 1 | 1 |
| AdventurerData.get_effective_stats() changes break existing code | Medium | High | Run full test suite before/after Phase 3 | 3 |
| EventBus signal not wired correctly | Low | Medium | Test signal emissions in Phase 2 | 2 |
| Condition modifier rounding causes stat drift | Low | Low | Use int() consistently in stat calculation | 3 |
| ItemDatabase lookup returns null | Low | Medium | Add null checks in Phase 5 | 5 |

---

## Handoff State

### What's Complete
- Planning phase complete, all sections reviewed

### What's In Progress
- None (planning only)

### What's Blocked
- None

### Next Steps
1. Verify TASK-006 (AdventurerData) is complete
2. Verify TASK-007 (ItemData, ItemDatabase) is complete
3. Verify all dependencies exist (Enums, GameConfig, EventBus)
4. Start Phase 1: Create EquipmentManager class file
5. Write first validation tests, begin TDD cycle

---

*Implementation plan version: 1.0.0 | Created: 2025-01-18 | Task: TASK-014*
