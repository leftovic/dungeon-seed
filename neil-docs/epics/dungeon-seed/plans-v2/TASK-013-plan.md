# TASK-013: Adventurer Roster & Party Builder — Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-013-adventurer-roster.md`
> **Status**: Planning
> **Created**: 2025-01-18
> **Branch**: `users/wrstl/task-013-adventurer-roster`
> **Repo**: `dev-agent-tool` (local — `C:\Users\wrstl\source\dev-agent-tool`)
> **Methodology**: TDD Red-Green-Refactor (mandatory for all phases)
> **Complexity**: 5 points (Moderate)
> **Estimated Phases**: 6
> **Estimated Checkboxes**: ~75

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents in this order:

1. **This file** (you're reading it) — the phased checklist of what to do, with status
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-013-adventurer-roster.md`** — the full technical spec (95.5 KB)
3. **`src/models/adventurer_data.gd`** — AdventurerData model (from TASK-006)
4. **`src/models/enums.gd`** — Enums (AdventurerClass, LevelTier, AdventurerCondition)
5. **`src/models/game_config.gd`** — GameConfig constants (BASE_STATS, XP_CURVE, STAT_KEYS)

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| **Roster service** | `src/services/adventurer_roster.gd` | **NEW** — `class_name AdventurerRoster`, extends RefCounted |
| **AdventurerData model** | `src/models/adventurer_data.gd` | **EXISTS** — from TASK-006, has class/level/stats/equipment |
| **Enums** | `src/models/enums.gd` | **EXISTS** — AdventurerClass, LevelTier, AdventurerCondition, EquipSlot |
| **GameConfig** | `src/models/game_config.gd` | **EXISTS** — BASE_STATS, XP_CURVE, STAT_KEYS, EQUIP_SLOT_KEYS |
| **EventBus** | `src/autoloads/event_bus.gd` | **EXISTS** — needs new signals added |
| **GameManager** | `src/autoloads/game_manager.gd` | **EXISTS** — needs `roster` property added |
| **Unit tests** | `tests/unit/test_adventurer_roster.gd` | **NEW** — GUT test suite for roster service |

### Key Concepts (5-minute primer)

- **Roster**: Global collection of all recruited adventurers. Stored in `Dictionary[StringName, AdventurerData]`. Managed by `AdventurerRoster` service.
- **Party**: A subset of 1–4 adventurers selected from the roster for an expedition. Stored as `Array[StringName]` (IDs, not data).
- **Recruitment**: Creates a new adventurer with procedurally generated name, random affinity, class-based stats, and adds to roster.
- **Party Validation**: Ensures party composition meets rules: size 1–4, all adventurers exist, no duplicates, all deployable (Healthy/Fatigued only).
- **Deployable**: Only Healthy or Fatigued adventurers can be in a party. Injured/Exhausted are locked until recovery.
- **RefCounted**: AdventurerRoster extends RefCounted (not Node). No scene tree dependency. Pure service layer.
- **StringName**: All IDs are StringName (e.g., `&"adv_war_001"`). O(1) equality comparison, faster Dictionary lookups.
- **Procedural Names**: Each class has a name table (8 names). If duplicate name, append suffix: "Kira", "Kira II", "Kira III".
- **Stat Scaling**: Initial stats = base stats + (level × growth rate). Formula from GDD §6.4.

### Build & Test Commands

```powershell
# Run GUT tests (headless)
& "C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --path "C:\Users\wrstl\source\dev-agent-tool" --headless -s "res://addons/gut/gut_cmdln.gd" -gdir="res://tests/" -ginclude_subdirs

# Run specific test file
& "C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --path "C:\Users\wrstl\source\dev-agent-tool" --headless -s "res://addons/gut/gut_cmdln.gd" -gtest="res://tests/unit/test_adventurer_roster.gd"

# Open project in editor (for manual testing)
& "C:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe" --editor --path "C:\Users\wrstl\source\dev-agent-tool"
```

### Regression Gate

Before AND after every phase:
1. All existing tests in `tests/unit/` pass green
2. `src/models/adventurer_data.gd` is unchanged (TASK-006 output)
3. `src/models/enums.gd` is unchanged (no new enums added)
4. `src/models/game_config.gd` is unchanged (no new constants added)
5. All new tests written in this task pass green

---

## Current State Analysis

### What Exists Today

| Item | Status | Location |
|------|--------|----------|
| `AdventurerData` model | ✅ Exists | `src/models/adventurer_data.gd` — has id, class, level, xp, stats, equipment, is_available |
| `Enums.AdventurerClass` | ✅ Exists | `src/models/enums.gd` — WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL |
| `Enums.LevelTier` | ✅ Exists | `src/models/enums.gd` — NOVICE, SKILLED, VETERAN, ELITE |
| `Enums.EquipSlot` | ✅ Exists | `src/models/enums.gd` — NONE, WEAPON, ARMOR, ACCESSORY |
| `GameConfig.BASE_STATS` | ✅ Exists | `src/models/game_config.gd` — stat blocks per class |
| `GameConfig.XP_CURVE` | ✅ Exists | `src/models/game_config.gd` — BASE_XP, GROWTH_RATE |
| `GameConfig.STAT_KEYS` | ✅ Exists | `src/models/game_config.gd` — ["health", "attack", "defense", "speed", "utility"] |
| `GameConfig.EQUIP_SLOT_KEYS` | ✅ Exists | `src/models/game_config.gd` — ["weapon", "armor", "accessory"] |
| `EventBus` autoload | ✅ Exists | `src/autoloads/event_bus.gd` — central signal hub |
| `GameManager` autoload | ✅ Exists | `src/autoloads/game_manager.gd` — lifecycle singleton |
| GUT test framework | ✅ Exists | `addons/gut/` — installed and configured |

### What's Missing (Gap Analysis)

| Item | Status | Required By |
|------|--------|-------------|
| `AdventurerRoster` service | ❌ Missing | FR-001 through FR-030 |
| EventBus signals | ❌ Missing | FR-004, FR-013, FR-015 (needs `adventurer_recruited`, `party_assembled`, `party_cleared`) |
| GameManager.roster property | ❌ Missing | AC-063 through AC-065 |
| `test_adventurer_roster.gd` | ❌ Missing | All ACs, Section 14 |

### What Must NOT Change

- `src/models/adventurer_data.gd` — TASK-006 output, provides AdventurerData class
- `src/models/enums.gd` — no new enums needed, all enums already defined
- `src/models/game_config.gd` — no new constants needed, all constants already defined
- `src/models/item_data.gd` — not touched by this task
- `src/models/item_database.gd` — not touched by this task
- `src/models/inventory_data.gd` — not touched by this task

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
func test_recruit_warrior_returns_valid_id() -> void:
func test_warrior_level_1_has_correct_base_stats() -> void:
func test_set_party_valid_party_returns_ok() -> void:
func test_validate_party_empty_array_returns_invalid_parameter() -> void:
func test_from_dict_round_trip_preserves_all_data() -> void:
```

### Test Structure

Every test follows Arrange-Act-Assert:
```gdscript
func test_method_scenario_expected() -> void:
	# Arrange — set up test data
	var roster := AdventurerRoster.new()
	
	# Act — execute the method
	var id := roster.recruit_adventurer(Enums.AdventurerClass.WARRIOR, 1)
	
	# Assert — verify the outcome
	assert_ne(id, &"", "Recruit must return non-empty ID")
	assert_true(roster.has_adventurer(id), "Adventurer must exist in roster")
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
- **Invalid**: Malformed/corrupt inputs handled gracefully
- **Null**: Null inputs don't crash
- **Empty**: Empty collections/strings handled correctly
- **Boundary**: Max/min values, off-by-one, edge of ranges

---

## Phase 1: Roster Core Structure & Properties

> **Ticket References**: FR-001, FR-002, FR-009
> **AC References**: AC-001, AC-002
> **Estimated Items**: 10
> **Dependencies**: None (first implementation phase)
> **Validation Gate**: AdventurerRoster class exists, has all required properties, instantiates without errors

### 1.1 Create AdventurerRoster Class File

- [ ] **1.1.1** Create `src/services/adventurer_roster.gd`
  - _Ticket ref: FR-001_
  - _File: `src/services/adventurer_roster.gd`_
  - _TDD: N/A (file creation)_
  
- [ ] **1.1.2** Add `class_name AdventurerRoster` declaration
  - _Ticket ref: FR-001_
  - _File: `src/services/adventurer_roster.gd`_
  - _Note: Safe to use `class_name` — this is NOT an autoload_

- [ ] **1.1.3** Add `extends RefCounted` declaration
  - _Ticket ref: FR-001_
  - _File: `src/services/adventurer_roster.gd`_

### 1.2 Add Core Properties

- [ ] **1.2.1** Add `adventurers: Dictionary = {}` property with comment
  - _Ticket ref: FR-002_
  - _File: `src/services/adventurer_roster.gd`_
  - _Comment: `## Dictionary[StringName, AdventurerData] — all recruited adventurers`_

- [ ] **1.2.2** Add `current_party: Array[StringName] = []` property
  - _Ticket ref: FR-011_
  - _File: `src/services/adventurer_roster.gd`_
  - _Comment: `## Array of adventurer IDs (max 4) for current expedition party`_

- [ ] **1.2.3** Add `max_roster_size: int = 12` property
  - _Ticket ref: FR-009_
  - _File: `src/services/adventurer_roster.gd`_
  - _Comment: `## Maximum number of adventurers that can be recruited`_

- [ ] **1.2.4** Add `_next_adventurer_counter: int = 1` property
  - _Ticket ref: FR-024 (serialization needs this)_
  - _File: `src/services/adventurer_roster.gd`_
  - _Comment: `## Counter for generating unique adventurer IDs`_

### 1.3 Create Test File

- [ ] **1.3.1** Create `tests/unit/test_adventurer_roster.gd`
  - _Ticket ref: Section 14_
  - _File: `tests/unit/test_adventurer_roster.gd`_
  - _TDD: RED test `test_roster_instantiates`_

- [ ] **1.3.2** Write test: `test_roster_instantiates()`
  - _Ticket ref: AC-001_
  - _File: `tests/unit/test_adventurer_roster.gd`_
  - _Test creates AdventurerRoster, asserts not null_

- [ ] **1.3.3** Write test: `test_roster_has_empty_adventurers_dict()`
  - _Ticket ref: FR-002_
  - _File: `tests/unit/test_adventurer_roster.gd`_
  - _Test asserts `roster.adventurers.is_empty() == true`_

### Phase 1 Validation Gate

- [ ] **1.V.1** All tests pass: `test_roster_instantiates()`, `test_roster_has_empty_adventurers_dict()`
- [ ] **1.V.2** AdventurerRoster can be instantiated: `var r = AdventurerRoster.new()` in console
- [ ] **1.V.3** No errors in Godot editor Output panel
- [ ] **1.V.4** Commit: `"Phase 1: AdventurerRoster core structure — 2 tests pass"`

---

## Phase 2: Recruitment System & Procedural Name Generation

> **Ticket References**: FR-003, FR-004, FR-009, FR-010, FR-021, FR-022, FR-023, FR-028, FR-029, FR-030
> **AC References**: AC-003 through AC-010, AC-042 through AC-045
> **Estimated Items**: 18
> **Dependencies**: Phase 1 complete
> **Validation Gate**: Recruitment works, names are procedural, stats calculated correctly, EventBus signal emits

### 2.1 Implement Procedural Name Generation

- [ ] **2.1.1** Add `const NAME_TABLES: Dictionary` with 6 class name arrays
  - _Ticket ref: FR-021_
  - _File: `src/services/adventurer_roster.gd`_
  - _Warrior: ["Kira", "Thane", "Bjorn", "Asha", "Rorik", "Freya", "Magnus", "Elara"]_
  - _Ranger: ["Sylvan", "Talon", "Mira", "Fenris", "Lyra", "Hawk", "Vesper", "Ashen"]_
  - _Mage: ["Alden", "Seraphine", "Lucian", "Nyx", "Cassian", "Vespera", "Theron", "Isolde"]_
  - _Rogue: ["Shade", "Vex", "Sable", "Rook", "Whisper", "Ember", "Sly", "Onyx"]_
  - _Alchemist: ["Caelum", "Briar", "Sage", "Orion", "Ivy", "Flint", "Willow", "Cinder"]_
  - _Sentinel: ["Valorin", "Bastian", "Aegis", "Serena", "Ward", "Fortuna", "Citadel", "Haven"]_

- [ ] **2.1.2** Write test: `test_generate_name_returns_warrior_name()`
  - _Ticket ref: FR-021_
  - _File: `tests/unit/test_adventurer_roster.gd`_
  - _TDD: RED test → GREEN implementation_

- [ ] **2.1.3** Implement `_generate_name(class_type: Enums.AdventurerClass) -> String`
  - _Ticket ref: FR-021_
  - _File: `src/services/adventurer_roster.gd`_
  - _Uses `Time.get_ticks_msec()` for RNG seed, picks random from NAME_TABLES[class_type]_

- [ ] **2.1.4** Write test: `test_generate_name_duplicate_adds_suffix()`
  - _Ticket ref: FR-022_
  - _File: `tests/unit/test_adventurer_roster.gd`_
  - _Test recruits 2 warriors, mocks same name, verifies suffix " II"_

- [ ] **2.1.5** Implement name deduplication logic with Roman numeral suffix
  - _Ticket ref: FR-022_
  - _File: `src/services/adventurer_roster.gd`_
  - _If name exists, append " II", " III", etc._

### 2.2 Implement Stat Calculation

- [ ] **2.2.1** Write test: `test_calculate_starting_stats_warrior_level_1()`
  - _Ticket ref: FR-028, AC-004_
  - _File: `tests/unit/test_adventurer_roster.gd`_
  - _Test level 1 Warrior: HP=100, MP=20, ATK=15, DEF=12, SPD=8, PER=6_

- [ ] **2.2.2** Implement `_calculate_starting_stats(class_type, level) -> Dictionary`
  - _Ticket ref: FR-028_
  - _File: `src/services/adventurer_roster.gd`_
  - _Formula: base_stat + (level - 1) × growth_rate_

- [ ] **2.2.3** Write test: `test_calculate_starting_stats_mage_level_5()`
  - _Ticket ref: AC-005_
  - _File: `tests/unit/test_adventurer_roster.gd`_
  - _Test level 5 Mage: HP=90 (60 + 5×6), MP=90, ATK=25_

- [ ] **2.2.4** Write test: `test_calculate_starting_stats_ranger_level_10()`
  - _Ticket ref: AC-006_
  - _File: `tests/unit/test_adventurer_roster.gd`_
  - _Test level 10 Ranger: SPD=44 (14 + 10×3)_

### 2.3 Implement Recruitment

- [ ] **2.3.1** Write test: `test_recruit_warrior_returns_valid_id()`
  - _Ticket ref: AC-003_
  - _File: `tests/unit/test_adventurer_roster.gd`_
  - _TDD: RED test_

- [ ] **2.3.2** Implement `recruit_adventurer(class_type, starting_level) -> StringName`
  - _Ticket ref: FR-003_
  - _File: `src/services/adventurer_roster.gd`_
  - _Generate ID: `&"adv_<class_short>_<counter:03d>"`_
  - _Create AdventurerData, set name, affinity, stats, condition, morale_

- [ ] **2.3.3** Write test: `test_recruited_adventurer_exists_in_roster()`
  - _Ticket ref: AC-011_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **2.3.4** Write test: `test_recruited_adventurer_has_random_affinity()`
  - _Ticket ref: AC-009_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **2.3.5** Write test: `test_recruited_adventurer_has_healthy_condition()`
  - _Ticket ref: AC-007_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **2.3.6** Write test: `test_recruited_adventurer_has_default_morale()`
  - _Ticket ref: AC-008_
  - _File: `tests/unit/test_adventurer_roster.gd`_

### 2.4 Implement EventBus Integration

- [ ] **2.4.1** Add signal to EventBus: `signal adventurer_recruited(adventurer_id: StringName, class_type: Enums.AdventurerClass)`
  - _Ticket ref: FR-004, AC-057_
  - _File: `src/autoloads/event_bus.gd`_

- [ ] **2.4.2** Write test: `test_recruit_emits_adventurer_recruited_signal()`
  - _Ticket ref: AC-010, AC-060_
  - _File: `tests/unit/test_adventurer_roster.gd`_
  - _Use `watch_signals(EventBus)`, `assert_signal_emitted`_

- [ ] **2.4.3** Emit signal in `recruit_adventurer()` after adding to roster
  - _Ticket ref: FR-004_
  - _File: `src/services/adventurer_roster.gd`_
  - _`EventBus.adventurer_recruited.emit(adventurer_id, class_type)`_

### 2.5 Implement Roster Full Guard

- [ ] **2.5.1** Write test: `test_roster_full_returns_empty_id()`
  - _Ticket ref: AC-017_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **2.5.2** Add guard in `recruit_adventurer()` for roster full
  - _Ticket ref: FR-009, FR-010_
  - _File: `src/services/adventurer_roster.gd`_
  - _If `adventurers.size() >= max_roster_size`, return `&""`_

### Phase 2 Validation Gate

- [ ] **2.V.1** All tests pass (10+ new tests)
- [ ] **2.V.2** Can recruit a Warrior: `var id = roster.recruit_adventurer(Enums.AdventurerClass.WARRIOR, 1)` → valid ID returned
- [ ] **2.V.3** Recruited adventurer has correct stats: HP=100, ATK=15, etc.
- [ ] **2.V.4** Recruiting 13th adventurer when roster full returns `&""`
- [ ] **2.V.5** EventBus signal emits on recruitment
- [ ] **2.V.6** Commit: `"Phase 2: Recruitment system with procedural names — 10 tests pass"`

---

## Phase 3: Roster Query Methods

> **Ticket References**: FR-005, FR-006, FR-007, FR-008
> **AC References**: AC-011 through AC-016
> **Estimated Items**: 12
> **Dependencies**: Phase 2 complete
> **Validation Gate**: All roster query methods work correctly, edge cases handled

### 3.1 Implement get_adventurer()

- [ ] **3.1.1** Write test: `test_get_adventurer_returns_correct_data()`
  - _Ticket ref: AC-011_
  - _File: `tests/unit/test_adventurer_roster.gd`_
  - _TDD: RED test_

- [ ] **3.1.2** Implement `get_adventurer(id: StringName) -> AdventurerData`
  - _Ticket ref: FR-005_
  - _File: `src/services/adventurer_roster.gd`_
  - _Return `adventurers.get(id, null)`_

- [ ] **3.1.3** Write test: `test_get_adventurer_invalid_id_returns_null()`
  - _Ticket ref: AC-012_
  - _File: `tests/unit/test_adventurer_roster.gd`_

### 3.2 Implement has_adventurer()

- [ ] **3.2.1** Write test: `test_has_adventurer_true_for_existing()`
  - _Ticket ref: AC-013_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **3.2.2** Implement `has_adventurer(id: StringName) -> bool`
  - _Ticket ref: FR-007_
  - _File: `src/services/adventurer_roster.gd`_
  - _Return `adventurers.has(id)`_

- [ ] **3.2.3** Write test: `test_has_adventurer_false_for_nonexistent()`
  - _Ticket ref: AC-013_
  - _File: `tests/unit/test_adventurer_roster.gd`_

### 3.3 Implement get_all_adventurers()

- [ ] **3.3.1** Write test: `test_get_all_adventurers_returns_array()`
  - _Ticket ref: AC-014_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **3.3.2** Implement `get_all_adventurers() -> Array[AdventurerData]`
  - _Ticket ref: FR-006_
  - _File: `src/services/adventurer_roster.gd`_
  - _Return `adventurers.values()` as typed array_

- [ ] **3.3.3** Write test: `test_get_all_adventurers_empty_roster_returns_empty_array()`
  - _Ticket ref: FR-006_
  - _File: `tests/unit/test_adventurer_roster.gd`_

### 3.4 Implement remove_adventurer()

- [ ] **3.4.1** Write test: `test_remove_adventurer_deletes_from_roster()`
  - _Ticket ref: AC-015_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **3.4.2** Implement `remove_adventurer(id: StringName) -> bool`
  - _Ticket ref: FR-008_
  - _File: `src/services/adventurer_roster.gd`_
  - _Remove from `adventurers`, remove from `current_party` if present, return true/false_

- [ ] **3.4.3** Write test: `test_remove_adventurer_invalid_id_returns_false()`
  - _Ticket ref: AC-016_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **3.4.4** Write test: `test_remove_adventurer_removes_from_party()`
  - _Ticket ref: FR-008_
  - _File: `tests/unit/test_adventurer_roster.gd`_

### Phase 3 Validation Gate

- [ ] **3.V.1** All tests pass (9+ new tests)
- [ ] **3.V.2** Can retrieve adventurer by ID: `roster.get_adventurer(id)` returns AdventurerData
- [ ] **3.V.3** Can query existence: `roster.has_adventurer(id)` returns bool
- [ ] **3.V.4** Can get all adventurers: `roster.get_all_adventurers()` returns array
- [ ] **3.V.5** Can remove adventurer: `roster.remove_adventurer(id)` removes from roster and party
- [ ] **3.V.6** Commit: `"Phase 3: Roster query methods — 9 tests pass"`

---

## Phase 4: Party Composition & Validation

> **Ticket References**: FR-011 through FR-020
> **AC References**: AC-018 through AC-041
> **Estimated Items**: 22
> **Dependencies**: Phase 3 complete
> **Validation Gate**: Party composition works, validation enforces all rules, signals emit

### 4.1 Implement Party Validation

- [ ] **4.1.1** Write test: `test_validate_party_single_healthy_returns_ok()`
  - _Ticket ref: AC-033_
  - _File: `tests/unit/test_adventurer_roster.gd`_
  - _TDD: RED test_

- [ ] **4.1.2** Implement `validate_party(adventurer_ids: Array[StringName]) -> Error`
  - _Ticket ref: FR-017_
  - _File: `src/services/adventurer_roster.gd`_
  - _Check: size > 0, size <= 4, all exist, no duplicates, all deployable_

- [ ] **4.1.3** Write test: `test_validate_party_four_healthy_returns_ok()`
  - _Ticket ref: AC-034_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **4.1.4** Write test: `test_validate_party_empty_array_returns_invalid_parameter()`
  - _Ticket ref: AC-035_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **4.1.5** Write test: `test_validate_party_five_adventurers_returns_invalid_parameter()`
  - _Ticket ref: AC-036_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **4.1.6** Write test: `test_validate_party_invalid_id_returns_does_not_exist()`
  - _Ticket ref: AC-037_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **4.1.7** Write test: `test_validate_party_duplicate_returns_already_exists()`
  - _Ticket ref: AC-038_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **4.1.8** Write test: `test_validate_party_injured_returns_unavailable()`
  - _Ticket ref: AC-039_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **4.1.9** Write test: `test_validate_party_exhausted_returns_unavailable()`
  - _Ticket ref: AC-040_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **4.1.10** Write test: `test_validate_party_fatigued_returns_ok()`
  - _Ticket ref: AC-041_
  - _File: `tests/unit/test_adventurer_roster.gd`_

### 4.2 Implement set_party()

- [ ] **4.2.1** Write test: `test_set_party_valid_party_returns_ok()`
  - _Ticket ref: AC-018_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **4.2.2** Implement `set_party(adventurer_ids: Array[StringName]) -> Error`
  - _Ticket ref: FR-012_
  - _File: `src/services/adventurer_roster.gd`_
  - _Validate first, set `current_party` only if OK, emit signal_

- [ ] **4.2.3** Write test: `test_set_party_invalid_does_not_modify_current_party()`
  - _Ticket ref: AC-027_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **4.2.4** Add signal to EventBus: `signal party_assembled(party_ids: Array[StringName])`
  - _Ticket ref: FR-013, AC-058_
  - _File: `src/autoloads/event_bus.gd`_

- [ ] **4.2.5** Write test: `test_set_party_emits_party_assembled_signal()`
  - _Ticket ref: AC-028, AC-061_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **4.2.6** Emit `party_assembled` signal in `set_party()` on success
  - _Ticket ref: FR-013_
  - _File: `src/services/adventurer_roster.gd`_

### 4.3 Implement get_party()

- [ ] **4.3.1** Write test: `test_get_party_returns_adventurer_data_array()`
  - _Ticket ref: AC-029_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **4.3.2** Implement `get_party() -> Array[AdventurerData]`
  - _Ticket ref: FR-014_
  - _File: `src/services/adventurer_roster.gd`_
  - _Dereference each ID in `current_party` to AdventurerData, filter out missing_

- [ ] **4.3.3** Write test: `test_get_party_empty_party_returns_empty_array()`
  - _Ticket ref: AC-030_
  - _File: `tests/unit/test_adventurer_roster.gd`_

### 4.4 Implement get_party_ids()

- [ ] **4.4.1** Write test: `test_get_party_ids_returns_copy()`
  - _Ticket ref: AC-031_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **4.4.2** Implement `get_party_ids() -> Array[StringName]`
  - _Ticket ref: FR-016_
  - _File: `src/services/adventurer_roster.gd`_
  - _Return `current_party.duplicate()`_

### 4.5 Implement clear_party()

- [ ] **4.5.1** Write test: `test_clear_party_sets_empty_array()`
  - _Ticket ref: AC-032_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **4.5.2** Add signal to EventBus: `signal party_cleared()`
  - _Ticket ref: FR-015, AC-059_
  - _File: `src/autoloads/event_bus.gd`_

- [ ] **4.5.3** Implement `clear_party() -> void`
  - _Ticket ref: FR-015_
  - _File: `src/services/adventurer_roster.gd`_
  - _Set `current_party = []`, emit `party_cleared`_

- [ ] **4.5.4** Write test: `test_clear_party_emits_party_cleared_signal()`
  - _Ticket ref: AC-062_
  - _File: `tests/unit/test_adventurer_roster.gd`_

### Phase 4 Validation Gate

- [ ] **4.V.1** All tests pass (18+ new tests)
- [ ] **4.V.2** Can set valid party: `roster.set_party([id1, id2])` returns OK
- [ ] **4.V.3** Invalid party rejected: `roster.set_party([id1, id1])` returns ERR_ALREADY_EXISTS
- [ ] **4.V.4** Injured adventurer rejected: `roster.set_party([injured_id])` returns ERR_UNAVAILABLE
- [ ] **4.V.5** Party signals emit correctly
- [ ] **4.V.6** Commit: `"Phase 4: Party composition and validation — 18 tests pass"`

---

## Phase 5: Serialization & Deserialization

> **Ticket References**: FR-024 through FR-027
> **AC References**: AC-046 through AC-056
> **Estimated Items**: 14
> **Dependencies**: Phase 4 complete
> **Validation Gate**: Round-trip serialization preserves all data, defensive deserialization handles corrupt data

### 5.1 Implement to_dict()

- [ ] **5.1.1** Write test: `test_to_dict_has_required_keys()`
  - _Ticket ref: AC-046_
  - _File: `tests/unit/test_adventurer_roster.gd`_
  - _TDD: RED test_

- [ ] **5.1.2** Implement `to_dict() -> Dictionary`
  - _Ticket ref: FR-024_
  - _File: `src/services/adventurer_roster.gd`_
  - _Return dict with "adventurers", "current_party", "max_roster_size", "next_adventurer_counter"_

- [ ] **5.1.3** Write test: `test_to_dict_adventurers_contains_all_adventurers()`
  - _Ticket ref: AC-047_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **5.1.4** Write test: `test_to_dict_current_party_is_array_of_strings()`
  - _Ticket ref: AC-048_
  - _File: `tests/unit/test_adventurer_roster.gd`_

### 5.2 Implement from_dict()

- [ ] **5.2.1** Write test: `test_from_dict_round_trip_preserves_all_data()`
  - _Ticket ref: AC-049_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **5.2.2** Implement `from_dict(data: Dictionary) -> void`
  - _Ticket ref: FR-025_
  - _File: `src/services/adventurer_roster.gd`_
  - _Clear existing state, restore from data dict_

- [ ] **5.2.3** Write test: `test_from_dict_round_trip_preserves_adventurer_ids()`
  - _Ticket ref: AC-050_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **5.2.4** Write test: `test_from_dict_round_trip_preserves_party_composition()`
  - _Ticket ref: AC-051_
  - _File: `tests/unit/test_adventurer_roster.gd`_

### 5.3 Defensive Deserialization

- [ ] **5.3.1** Write test: `test_from_dict_missing_adventurers_key_defaults_empty()`
  - _Ticket ref: AC-052_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **5.3.2** Write test: `test_from_dict_corrupt_adventurer_skips_and_warns()`
  - _Ticket ref: AC-053_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **5.3.3** Add defensive guards in `from_dict()` for missing/invalid keys
  - _Ticket ref: FR-027_
  - _File: `src/services/adventurer_roster.gd`_
  - _Use `.get(key, default)`, clamp values, log warnings_

- [ ] **5.3.4** Write test: `test_from_dict_clamps_max_roster_size()`
  - _Ticket ref: AC-054_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **5.3.5** Write test: `test_from_dict_clamps_adventurer_level()`
  - _Ticket ref: AC-055_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **5.3.6** Write test: `test_from_dict_clamps_adventurer_morale()`
  - _Ticket ref: AC-056_
  - _File: `tests/unit/test_adventurer_roster.gd`_

### Phase 5 Validation Gate

- [ ] **5.V.1** All tests pass (11+ new tests)
- [ ] **5.V.2** Round-trip serialization works: `roster2.from_dict(roster1.to_dict())` → identical state
- [ ] **5.V.3** Corrupt data handled: missing keys, invalid values do not crash
- [ ] **5.V.4** Values clamped: level [1, 50], morale [0, 100], max_roster_size [4, 100]
- [ ] **5.V.5** Commit: `"Phase 5: Serialization with defensive deserialization — 11 tests pass"`

---

## Phase 6: GameManager Integration & Final Validation

> **Ticket References**: FR-004, FR-013, FR-015 (EventBus), GameManager integration
> **AC References**: AC-057 through AC-065, PAC-001 through PAC-008, BAC-001 through BAC-005
> **Estimated Items**: 12
> **Dependencies**: Phase 5 complete
> **Validation Gate**: GameManager has roster, all EventBus signals work, all PACs and BACs pass

### 6.1 GameManager Integration

- [ ] **6.1.1** Add `roster: AdventurerRoster` property to GameManager
  - _Ticket ref: AC-063_
  - _File: `src/autoloads/game_manager.gd`_

- [ ] **6.1.2** Initialize roster in `GameManager._ready()` or `initialize()`
  - _Ticket ref: AC-064_
  - _File: `src/autoloads/game_manager.gd`_
  - _`roster = AdventurerRoster.new()`_

- [ ] **6.1.3** Write test: `test_game_manager_has_roster_property()`
  - _Ticket ref: AC-064_
  - _File: `tests/unit/test_adventurer_roster.gd` OR new integration test_

- [ ] **6.1.4** Write test: `test_game_manager_roster_can_recruit()`
  - _Ticket ref: AC-065_
  - _File: `tests/unit/test_adventurer_roster.gd` OR integration test_

### 6.2 EventBus Signal Verification

- [ ] **6.2.1** Verify all 3 signals exist in EventBus
  - _Ticket ref: AC-057, AC-058, AC-059_
  - _File: `src/autoloads/event_bus.gd`_
  - _`adventurer_recruited`, `party_assembled`, `party_cleared`_

- [ ] **6.2.2** Write test: `test_eventbus_has_adventurer_recruited_signal()`
  - _Ticket ref: AC-057_
  - _File: `tests/unit/test_event_bus.gd` OR integration test_

### 6.3 Playtesting Acceptance Criteria (PACs)

- [ ] **6.3.1** Manual PAC: Recruit 1 Warrior, verify name from Warrior table
  - _Ticket ref: PAC-001_
  - _Action: Start project, run script in console_

- [ ] **6.3.2** Manual PAC: Recruit 4 more adventurers, verify 5 in roster
  - _Ticket ref: PAC-002_

- [ ] **6.3.3** Manual PAC: Set party to [Warrior, Mage, Rogue], verify get_party() returns 3
  - _Ticket ref: PAC-003_

- [ ] **6.3.4** Manual PAC: Try to set party with 5 adventurers, verify fails
  - _Ticket ref: PAC-004_

- [ ] **6.3.5** Manual PAC: Set adventurer to Injured, verify party validation fails
  - _Ticket ref: PAC-005_

- [ ] **6.3.6** Manual PAC: Save/reload with 5 adventurers and 3-person party, verify preserved
  - _Ticket ref: PAC-006_

- [ ] **6.3.7** Manual PAC: Recruit until roster full (12), verify 13th fails
  - _Ticket ref: PAC-007_

- [ ] **6.3.8** Manual PAC: Remove adventurer, verify removed from roster and get_all_adventurers()
  - _Ticket ref: PAC-008_

### 6.4 Balance Acceptance Criteria (BACs)

- [ ] **6.4.1** Write test: `test_level_1_warrior_higher_hp_than_mage()`
  - _Ticket ref: BAC-001_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **6.4.2** Write test: `test_level_1_mage_higher_mp_than_warrior()`
  - _Ticket ref: BAC-002_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **6.4.3** Write test: `test_level_10_ranger_higher_spd_than_warrior()`
  - _Ticket ref: BAC-003_
  - _File: `tests/unit/test_adventurer_roster.gd`_

- [ ] **6.4.4** Write test: `test_all_classes_level_1_match_gdd_base_stats()`
  - _Ticket ref: BAC-005_
  - _File: `tests/unit/test_adventurer_roster.gd`_

### Phase 6 Validation Gate

- [ ] **6.V.1** All tests pass (full suite: 60+ tests)
- [ ] **6.V.2** GameManager.roster exists and can recruit adventurers
- [ ] **6.V.3** All 3 EventBus signals exist and emit correctly
- [ ] **6.V.4** All 8 PACs pass via manual testing
- [ ] **6.V.5** All 5 BACs pass via automated tests
- [ ] **6.V.6** Commit: `"Phase 6: GameManager integration and final validation — 60+ tests pass"`

---

## Phase Dependency Graph

```
Phase 1 (Core Structure)
   ↓
Phase 2 (Recruitment)
   ↓
Phase 3 (Query Methods)
   ↓
Phase 4 (Party Composition)
   ↓
Phase 5 (Serialization)
   ↓
Phase 6 (Integration & Validation)
```

All phases are sequential — each depends on the previous phase completing.

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 0 | Pre-Flight | 0 | 0 | 0 | ⬜ Not Started |
| Phase 1 | Core Structure | 10 | 0 | 2 | ⬜ Not Started |
| Phase 2 | Recruitment | 18 | 0 | 10 | ⬜ Not Started |
| Phase 3 | Query Methods | 12 | 0 | 9 | ⬜ Not Started |
| Phase 4 | Party & Validation | 22 | 0 | 18 | ⬜ Not Started |
| Phase 5 | Serialization | 14 | 0 | 11 | ⬜ Not Started |
| Phase 6 | Integration | 12 | 0 | 10 | ⬜ Not Started |
| **Total** | | **88** | **0** | **60** | **⬜ Planning** |

---

## File Change Summary

### New Files
| File | Phase | Purpose |
|------|-------|---------|
| `src/services/adventurer_roster.gd` | 1 | AdventurerRoster service class |
| `tests/unit/test_adventurer_roster.gd` | 1 | Unit tests for AdventurerRoster |

### Modified Files
| File | Phase | Change |
|------|-------|--------|
| `src/autoloads/event_bus.gd` | 2, 4 | Add 3 new signals: adventurer_recruited, party_assembled, party_cleared |
| `src/autoloads/game_manager.gd` | 6 | Add `roster: AdventurerRoster` property, initialize in _ready() |

### No Changes
- `src/models/adventurer_data.gd` — unchanged
- `src/models/enums.gd` — unchanged
- `src/models/game_config.gd` — unchanged
- All other existing files — unchanged

---

## Commit Strategy

| Phase | Commit Message | Tests After |
|-------|----------------|-------------|
| 1 | `"Phase 1: AdventurerRoster core structure — 2 tests pass"` | 2 |
| 2 | `"Phase 2: Recruitment system with procedural names — 10 tests pass"` | 12 |
| 3 | `"Phase 3: Roster query methods — 9 tests pass"` | 21 |
| 4 | `"Phase 4: Party composition and validation — 18 tests pass"` | 39 |
| 5 | `"Phase 5: Serialization with defensive deserialization — 11 tests pass"` | 50 |
| 6 | `"Phase 6: GameManager integration and final validation — 60+ tests pass"` | 60 |

---

## Deviation Tracking

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| _No deviations yet_ | | | | | |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| AdventurerData missing properties | Low | High | Verify TASK-006 output before starting Phase 1 | 1 |
| Name collision causes infinite loop | Low | Medium | Add max iteration guard to suffix logic (100 iterations) | 2 |
| Serialization round-trip loses data | Medium | High | Extensive round-trip tests in Phase 5 | 5 |
| EventBus signals not wired correctly | Low | Medium | Test signal emissions in Phases 2, 4 | 2, 4 |
| GameManager integration breaks existing tests | Low | Medium | Run full test suite before/after Phase 6 | 6 |

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
2. Verify all dependencies exist (Enums, GameConfig, EventBus, GameManager)
3. Start Phase 1: Create AdventurerRoster class file
4. Write first tests, begin TDD cycle

---

*Implementation plan version: 1.0.0 | Created: 2025-01-18 | Task: TASK-013*
