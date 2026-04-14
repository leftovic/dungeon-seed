# TASK-005: Dungeon Room Graph Data Structure — Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-005-dungeon-room-graph.md`
> **GDD**: `neil-docs/epics/dungeon-seed/GDD-v2.md`
> **Status**: Planning
> **Created**: 2025-01-29
> **Repo**: `dev-agent-tool` (local — `C:\Users\wrstl\source\dev-agent-tool`)
> **Methodology**: TDD Red-Green-Refactor (mandatory for all phases)
> **Complexity**: 8 points (Moderate) — Fibonacci
> **Estimated Phases**: 7
> **Estimated Checkboxes**: ~75

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents in this order:

1. **This file** (you're reading it) — the phased checklist of what to do, with status
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-005-dungeon-room-graph.md`** — the full technical spec with exact code to implement
3. **`neil-docs/epics/dungeon-seed/GDD-v2.md`** — the Game Design Document for understanding domain context
4. **`src/models/enums.gd`** — Enums (RoomType, Element, Currency) from TASK-003
5. **`src/models/game_config.gd`** — GameConfig constants from TASK-003

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| Enum definitions | `src/models/enums.gd` | **EXISTS** — `class_name Enums`, has RoomType, Element, Currency |
| Game constants | `src/models/game_config.gd` | **EXISTS** — `class_name GameConfig` |
| Room data model | `src/models/room_data.gd` | **NEW** — `class_name RoomData`, extends RefCounted |
| Dungeon data model | `src/models/dungeon_data.gd` | **NEW** — `class_name DungeonData`, extends RefCounted |
| Room unit tests | `tests/models/test_room_data.gd` | **NEW** — GUT test suite for RoomData (~28 tests) |
| Dungeon unit tests | `tests/models/test_dungeon_data.gd` | **NEW** — GUT test suite for DungeonData (~50 tests) |
| Autoloads | `src/autoloads/event_bus.gd`, `src/autoloads/game_manager.gd` | **EXISTS** — from TASK-001, DO NOT TOUCH |
| GUT addon | `addons/gut/` | **EXISTS** — GUT test framework pre-installed |
| v1 prototype code | `src/gdscript/` | **DO NOT TOUCH** — legacy code, not part of this task |

### Key Concepts (5-minute primer)

- **RoomData**: Individual room node in the dungeon graph. Contains index, type, position, size, difficulty, loot_bias, is_cleared, and metadata.
- **DungeonData**: Complete dungeon graph model. Contains rooms array, edges array, entry/boss indices, element, difficulty, and seed_id.
- **Edge List Graph**: Undirected edges stored as `Array[Vector2i]` with canonical ordering (a < b).
- **Canonical Edge Ordering**: For every edge `Vector2i(a, b)`, `a < b`. Prevents duplicate edges and enables fast validation.
- **BFS Pathfinding**: `get_path_to_boss()` uses breadth-first search to find shortest path in unweighted graph.
- **Graph Validation**: `validate()` checks connectivity, canonical ordering, bounds, no duplicates, no self-loops.
- **JSON-Compatible Serialization**: `to_dict()` / `from_dict()` uses plain Dictionary representation for save/load.
- **RefCounted**: Godot base class for garbage-collected objects. No scene tree dependency. Ideal for pure data models.
- **`class_name`**: GDScript keyword that registers a script as a globally available type. Both room_data.gd and dungeon_data.gd use it.
- **Tests Directory**: Tests are in `tests/models/` NOT `tests/unit/` per ticket specification.

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
#   2. var room = RoomData.new()
#   3. var dungeon = DungeonData.new()
#   4. print(room.to_dict())
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
| `src/models/enums.gd` | ✅ Exists | TASK-003 — `class_name Enums`, RoomType, Element, Currency, etc. |
| `src/models/game_config.gd` | ✅ Exists | TASK-003 — `class_name GameConfig` |
| `src/autoloads/event_bus.gd` | ✅ Exists | TASK-001 — EventBus autoload |
| `src/autoloads/game_manager.gd` | ✅ Exists | TASK-001 — GameManager autoload |
| `addons/gut/` | ✅ Exists | GUT test framework installed |
| `tests/unit/` | ✅ Exists | Contains existing test files |
| `tests/models/` directory | ❓ Unknown | May need creation for test files |
| `src/gdscript/` | ✅ Exists | v1 prototype code (DO NOT TOUCH) |

### What's Missing (Gap Analysis)

| Item | Status | Required By |
|------|--------|-------------|
| `tests/models/` directory | ❌ Missing | FR-010, FR-044 (test file location) |
| `src/models/room_data.gd` | ❌ Missing | FR-001 through FR-014 |
| `src/models/dungeon_data.gd` | ❌ Missing | FR-015 through FR-049 |
| `tests/models/test_room_data.gd` | ❌ Missing | Section 14.1 — all test functions |
| `tests/models/test_dungeon_data.gd` | ❌ Missing | Section 14.2 — all test functions |

### What Must NOT Change

- `src/models/enums.gd` — TASK-003 output, provides RoomType, Element, Currency
- `src/models/game_config.gd` — TASK-003 output, provides configuration constants
- `src/autoloads/event_bus.gd` — TASK-001 output, central signal bus
- `src/autoloads/game_manager.gd` — TASK-001 output, lifecycle singleton
- `src/gdscript/` — v1 prototype code, explicitly out of scope
- `project.godot` — no changes needed for this task
- Existing test files in `tests/unit/` — must not be broken

### CRITICAL: Enum Validation

**✅ RESOLVED**: The ticket references `Enums.Element.NONE` as the default for DungeonData.element. This DOES exist in `src/models/enums.gd` line 21, so no deviation handling needed.

**⚠️ DEVIATION**: The ticket's test helpers use incorrect enum names:
- Uses `Enums.Element.FIRE` — should be `Enums.Element.FLAME`
- Uses `Enums.Element.WATER` — should be `Enums.Element.FROST`
- Uses `Enums.Element.EARTH` — should be `Enums.Element.TERRA`
- Uses `Enums.Currency.DUST` — should be `Enums.Currency.ESSENCE`
- Uses `Enums.Currency.GEMS` — should be `Enums.Currency.ARTIFACTS`

Tests must use actual enum names from existing enums.gd.

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
func test_room_data_defaults() -> void:

# Boolean methods
func test_is_combat_true() -> void:

# Graph operations
func test_get_adjacent_linear_start() -> void:

# Edge cases
func test_validate_empty_rooms_false() -> void:

# Round-trips
func test_round_trip_default() -> void:
```

### Test Structure (GUT)

Every test follows Arrange-Act-Assert:
```gdscript
func test_method_scenario_expected() -> void:
    # Arrange — create instance and test data
    var room: RoomData = RoomData.new()
    room.type = Enums.RoomType.BOSS

    # Act — execute the behavior
    var result: bool = room.is_boss()

    # Assert — verify the outcome
    assert_true(result)
```

### Coverage Requirements Per Phase

- ✅ **Existence**: Class exists, extends `RefCounted`, has `class_name`
- ✅ **Properties**: All typed properties initialized to correct defaults
- ✅ **Convenience Methods**: Boolean helpers for room type checking
- ✅ **Graph Operations**: Adjacency, pathfinding, query methods
- ✅ **Validation**: Connectivity checks, canonical ordering, bounds validation
- ✅ **Serialization**: Round-trip fidelity, defensive deserialization
- ✅ **Edge Cases**: Empty inputs, out-of-bounds, malformed data

---

## Phase 0: Pre-Flight & Dependency Verification

> **Ticket References**: FR-001, FR-015 (prerequisites)
> **AC References**: AC-001 through AC-013 (structural prerequisites)
> **Estimated Items**: 5
> **Dependencies**: TASK-003 complete (enums.gd exists)
> **Validation Gate**: All TASK-003 dependencies verified, tests/models/ directory created

This phase verifies that all upstream dependencies from TASK-003 are in place and the repository is ready for implementation.

### 0.1 Verify TASK-003 Outputs

- [ ] **0.1.1** Verify `src/models/enums.gd` exists and has RoomType, Element, Currency enums
  - _Ticket ref: FR-001, FR-015_
  - _File: `src/models/enums.gd`_
- [ ] **0.1.2** Verify `src/models/game_config.gd` exists 
  - _Ticket ref: Prerequisites_
  - _File: `src/models/game_config.gd`_

### 0.2 Create Test Directory Structure

- [ ] **0.2.1** Create directory `tests/models/` if it doesn't exist
  - _Ticket ref: Section 14 test file locations_
- [ ] **0.2.2** Verify `addons/gut/` exists (GUT framework)
  - _Prerequisites for test execution_

### Phase 0 Validation Gate

- [ ] **0.V.1** Verify `src/models/enums.gd` contains required enums (RoomType, Element, Currency)
- [ ] **0.V.2** Verify `tests/models/` directory exists and is writable
- [ ] **0.V.3** Verify existing autoloads and models are unchanged
- [ ] **0.V.4** Commit: `"Phase 0: Pre-flight verification and test directory setup"`

---

## Phase 1: RoomData Model Implementation (TDD)

> **Ticket References**: FR-001 through FR-014
> **AC References**: AC-001 through AC-021
> **Estimated Items**: 10
> **Dependencies**: Phase 0 complete (directory structure ready)
> **Validation Gate**: RoomData exists with properties, convenience methods, and serialization

### 1.1 Write RoomData Test File (RED)

- [ ] **1.1.1** Create `tests/models/test_room_data.gd` with all test functions from ticket Section 14.1
  - _Ticket ref: Section 14.1_
  - _File: `tests/models/test_room_data.gd`_
  - _Tests: 28 total covering defaults, properties, convenience methods, serialization_
  - _TDD: RED — tests reference `RoomData` class which does not exist yet_

### 1.2 Implement RoomData Class Declaration (GREEN)

- [ ] **1.2.1** Create `src/models/room_data.gd` with class declaration
  - _Ticket ref: FR-001_
  - _File: `src/models/room_data.gd`_
  - _Content: `class_name RoomData` + `extends RefCounted`_
- [ ] **1.2.2** Add all 8 properties with correct types and defaults
  - _Ticket ref: FR-002 through FR-009_
  - _Properties: index:int=0, type:RoomType=COMBAT, position:Vector2=ZERO, size:Vector2(1,1), difficulty:int=1, loot_bias:Currency=GOLD, is_cleared:bool=false, metadata:Dictionary={}_

### 1.3 Implement Convenience Methods (GREEN)

- [ ] **1.3.1** Add `is_combat() -> bool` method
  - _Ticket ref: FR-012_
  - _Implementation: return type == Enums.RoomType.COMBAT_
- [ ] **1.3.2** Add `is_boss() -> bool` method
  - _Ticket ref: FR-013_
  - _Implementation: return type == Enums.RoomType.BOSS_
- [ ] **1.3.3** Add `is_rest() -> bool` method
  - _Ticket ref: FR-014_
  - _Implementation: return type == Enums.RoomType.REST_

### 1.4 Implement Serialization Methods (GREEN)

- [ ] **1.4.1** Add `to_dict() -> Dictionary` method
  - _Ticket ref: FR-010_
  - _Converts Vector2 to Dict, enums to int, duplicates metadata_
- [ ] **1.4.2** Add `static from_dict(data: Dictionary) -> RoomData` method
  - _Ticket ref: FR-011_
  - _Defensive: uses .get() with defaults, validates types_

### Phase 1 Validation Gate

- [ ] **1.V.1** `src/models/room_data.gd` exists and is parseable GDScript
- [ ] **1.V.2** File extends `RefCounted` and declares `class_name RoomData`
- [ ] **1.V.3** All 8 properties declared with correct types and defaults
- [ ] **1.V.4** All 3 convenience methods implemented correctly
- [ ] **1.V.5** Both serialization methods implemented with proper type handling
- [ ] **1.V.6** All ~28 RoomData tests pass green
- [ ] **1.V.7** Commit: `"Phase 1: Implement RoomData model with properties, convenience methods, and serialization"`

---

## Phase 2: DungeonData Properties & Basic Accessors (TDD)

> **Ticket References**: FR-015 through FR-033
> **AC References**: AC-022 through AC-028
> **Estimated Items**: 9
> **Dependencies**: Phase 1 complete (RoomData exists)
> **Validation Gate**: DungeonData exists with properties and basic accessor methods

### 2.1 Write DungeonData Test File - Part 1 (RED)

- [ ] **2.1.1** Create `tests/models/test_dungeon_data.gd` with first section of tests
  - _Ticket ref: Section 14.2_
  - _File: `tests/models/test_dungeon_data.gd`_
  - _Tests: Default construction, basic accessors (get_room_count, get_edge_count, get_room, has_boss_room)_
  - _TDD: RED — tests reference `DungeonData` class which does not exist yet_

### 2.2 Implement DungeonData Class Declaration (GREEN)

- [ ] **2.2.1** Create `src/models/dungeon_data.gd` with class declaration
  - _Ticket ref: FR-015_
  - _File: `src/models/dungeon_data.gd`_
  - _Content: `class_name DungeonData` + `extends RefCounted`_
- [ ] **2.2.2** Add all 7 properties with correct types and defaults
  - _Ticket ref: FR-016 through FR-022_
  - _Properties: seed_id:String="", rooms:Array[RoomData]=[], edges:Array[Vector2i]=[], entry_room_index:int=0, boss_room_index:int=-1, element:Element=NONE, difficulty:int=1_
- [ ] **2.2.3** Add MAX_ROOM_COUNT and MAX_EDGE_COUNT constants
  - _Ticket ref: FR-044 (serialization limits)_
  - _Constants: MAX_ROOM_COUNT=100, MAX_EDGE_COUNT=500_

### 2.3 Implement Basic Accessor Methods (GREEN)

- [ ] **2.3.1** Add `get_room_count() -> int` method
  - _Ticket ref: FR-031_
  - _Implementation: return rooms.size()_
- [ ] **2.3.2** Add `get_edge_count() -> int` method
  - _Ticket ref: FR-032_
  - _Implementation: return edges.size()_
- [ ] **2.3.3** Add `get_room(index: int) -> RoomData` method
  - _Ticket ref: FR-030_
  - _Implementation: bounds check, return rooms[index] or null_
- [ ] **2.3.4** Add `has_boss_room() -> bool` method
  - _Ticket ref: FR-033_
  - _Implementation: return boss_room_index >= 0 and boss_room_index < rooms.size()_

### Phase 2 Validation Gate

- [ ] **2.V.1** `src/models/dungeon_data.gd` exists and is parseable GDScript
- [ ] **2.V.2** File extends `RefCounted` and declares `class_name DungeonData`
- [ ] **2.V.3** All 7 properties declared with correct types and defaults
- [ ] **2.V.4** All 4 basic accessor methods implemented correctly
- [ ] **2.V.5** All Phase 2 DungeonData tests pass green
- [ ] **2.V.6** Commit: `"Phase 2: Implement DungeonData properties and basic accessor methods"`

---

## Phase 3: Graph Operations (TDD)

> **Ticket References**: FR-023 through FR-029
> **AC References**: AC-029 through AC-048
> **Estimated Items**: 8
> **Dependencies**: Phase 2 complete (DungeonData properties exist)
> **Validation Gate**: Graph traversal operations implemented and tested

### 3.1 Add Graph Operation Tests (RED)

- [ ] **3.1.1** Add `get_adjacent()` tests to test_dungeon_data.gd
  - _Ticket ref: FR-023, FR-024_
  - _Tests: Linear chain adjacency, branching adjacency, out-of-bounds handling_
  - _TDD: RED — tests call methods that don't exist yet_

### 3.2 Implement get_adjacent Method (GREEN)

- [ ] **3.2.1** Add `get_adjacent(room_index: int) -> Array[int]` method
  - _Ticket ref: FR-023_
  - _Implementation: O(E) scan of edges, return connected room indices_
  - _Edge case: return empty array if room_index out of bounds (FR-024)_

### 3.3 Add BFS Pathfinding Tests (RED)

- [ ] **3.3.1** Add `get_path_to_boss()` tests to test_dungeon_data.gd
  - _Ticket ref: FR-025, FR-026, FR-027_
  - _Tests: Linear path, branching shortest path, no boss, unreachable boss_
  - _TDD: RED — tests call methods that don't exist yet_

### 3.4 Implement BFS Pathfinding (GREEN)

- [ ] **3.4.1** Add `get_path_to_boss() -> Array[int]` method
  - _Ticket ref: FR-025_
  - _Implementation: BFS from entry_room_index to boss_room_index, reconstruct path_
  - _Edge cases: empty array if no boss (FR-26) or unreachable (FR-027)_

### 3.5 Add Room Query Tests (RED)

- [ ] **3.5.1** Add `get_uncleared_rooms()` and `is_fully_cleared()` tests
  - _Ticket ref: FR-028, FR-029_
  - _Tests: Partial clearing, full clearing, empty dungeon_
  - _TDD: RED — tests call methods that don't exist yet_

### 3.6 Implement Room Query Methods (GREEN)

- [ ] **3.6.1** Add `get_uncleared_rooms() -> Array[int]` method
  - _Ticket ref: FR-028_
  - _Implementation: iterate rooms, return indices where is_cleared == false_
- [ ] **3.6.2** Add `is_fully_cleared() -> bool` method
  - _Ticket ref: FR-029_
  - _Implementation: return true only if ALL rooms have is_cleared == true_

### Phase 3 Validation Gate

- [ ] **3.V.1** `get_adjacent()` implemented with O(E) performance and bounds checking
- [ ] **3.V.2** `get_path_to_boss()` implemented with BFS algorithm and edge case handling
- [ ] **3.V.3** `get_uncleared_rooms()` and `is_fully_cleared()` implemented correctly
- [ ] **3.V.4** All graph operation tests pass green
- [ ] **3.V.5** Commit: `"Phase 3: Implement graph operations - adjacency, BFS pathfinding, room queries"`

---

## Phase 4: Validation System (TDD)

> **Ticket References**: FR-034 through FR-042
> **AC References**: AC-049 through AC-059
> **Estimated Items**: 10
> **Dependencies**: Phase 3 complete (graph operations exist)
> **Validation Gate**: Complete graph validation with connectivity checks

### 4.1 Add Validation Tests - Basic Checks (RED)

- [ ] **4.1.1** Add basic validation tests to test_dungeon_data.gd
  - _Ticket ref: FR-034, FR-035, FR-036_
  - _Tests: Empty rooms (false), valid entry index, valid boss index, invalid indices_
  - _TDD: RED — tests call validate() which doesn't exist yet_

### 4.2 Add Validation Tests - Edge Checks (RED)

- [ ] **4.2.1** Add edge validation tests to test_dungeon_data.gd
  - _Ticket ref: FR-037, FR-038, FR-039, FR-040_
  - _Tests: Out-of-bounds edges, non-canonical ordering, duplicates, self-loops_
  - _TDD: RED — tests call validate() which doesn't exist yet_

### 4.3 Add Connectivity Validation Tests (RED)

- [ ] **4.3.1** Add connectivity tests to test_dungeon_data.gd
  - _Ticket ref: FR-041, FR-042_
  - _Tests: Disconnected graphs, boss unreachability, valid connected cases_
  - _TDD: RED — tests call validate() which doesn't exist yet_

### 4.4 Implement validate() Method (GREEN)

- [ ] **4.4.1** Add `validate() -> bool` method skeleton
  - _Ticket ref: FR-034 through FR-042_
  - _File: `src/models/dungeon_data.gd`_
- [ ] **4.4.2** Implement basic checks (rooms count, entry/boss index bounds)
  - _Covers: FR-034, FR-035, FR-036_
- [ ] **4.4.3** Implement edge validation (bounds, canonical ordering, duplicates, self-loops)
  - _Covers: FR-037, FR-038, FR-039, FR-040_
- [ ] **4.4.4** Implement connectivity check using BFS
  - _Covers: FR-041, FR-042_
  - _Algorithm: BFS from entry_room_index must reach all rooms_

### Phase 4 Validation Gate

- [ ] **4.V.1** `validate()` method implemented with all required checks
- [ ] **4.V.2** Basic validation (room count, indices) working correctly
- [ ] **4.V.3** Edge validation (canonical ordering, duplicates, self-loops) working correctly
- [ ] **4.V.4** Connectivity validation using BFS working correctly
- [ ] **4.V.5** All validation tests pass green
- [ ] **4.V.6** Commit: `"Phase 4: Implement complete graph validation with connectivity checks"`

---

## Phase 5: DungeonData Serialization (TDD)

> **Ticket References**: FR-043 through FR-046
> **AC References**: AC-060 through AC-070
> **Estimated Items**: 8
> **Dependencies**: Phase 4 complete (validation exists)
> **Validation Gate**: Complete serialization with round-trip stability

### 5.1 Add Serialization Tests (RED)

- [ ] **5.1.1** Add `to_dict()` tests to test_dungeon_data.gd
  - _Ticket ref: FR-043_
  - _Tests: Dictionary structure, rooms as array, edges as [[a,b],...], enum as int_
  - _TDD: RED — tests call to_dict() which doesn't exist yet_

### 5.2 Add Round-Trip Tests (RED)

- [ ] **5.2.1** Add `from_dict()` and round-trip tests to test_dungeon_data.gd
  - _Ticket ref: FR-044, FR-045, FR-046_
  - _Tests: Basic round-trip, malformed data handling, missing keys, room count cap_
  - _TDD: RED — tests call from_dict() which doesn't exist yet_

### 5.3 Implement to_dict() Method (GREEN)

- [ ] **5.3.1** Add `to_dict() -> Dictionary` method
  - _Ticket ref: FR-043_
  - _Implementation: Serialize all properties, rooms as room.to_dict() array, edges as [x,y] arrays_
- [ ] **5.3.2** Ensure enum serialization as integers
  - _Element as int(element), room types and currency in room dictionaries_

### 5.4 Implement from_dict() Method (GREEN)

- [ ] **5.4.1** Add `static from_dict(data: Dictionary) -> DungeonData` method skeleton
  - _Ticket ref: FR-044_
  - _Implementation: Defensive deserialization with .get() defaults_
- [ ] **5.4.2** Implement rooms deserialization with cap
  - _Ticket ref: FR-046 (room count cap)_
  - _Cap at MAX_ROOM_COUNT=100 to prevent memory abuse_
- [ ] **5.4.3** Implement edges deserialization with cap
  - _Cap at MAX_EDGE_COUNT=500 to prevent memory abuse_
- [ ] **5.4.4** Add missing keys handling
  - _Ticket ref: FR-046_
  - _Use defaults for missing dictionary keys_

### Phase 5 Validation Gate

- [ ] **5.V.1** `to_dict()` method serializes all properties correctly
- [ ] **5.V.2** Dictionary output is JSON-compatible (no Godot-only types)
- [ ] **5.V.3** `from_dict()` method handles valid data correctly
- [ ] **5.V.4** `from_dict()` handles malformed data gracefully (doesn't crash)
- [ ] **5.V.5** Round-trip stability: from_dict(to_dict(x)) ≈ x
- [ ] **5.V.6** Room and edge count caps enforced
- [ ] **5.V.7** All serialization tests pass green
- [ ] **5.V.8** Commit: `"Phase 5: Implement DungeonData serialization with round-trip stability"`

---

## Phase 6: Edge Cases & Stress Tests (TDD)

> **Ticket References**: AC-071 through AC-075
> **Estimated Items**: 7
> **Dependencies**: Phase 5 complete (serialization working)
> **Validation Gate**: Edge cases handled robustly, stress tests pass

### 6.1 Add Edge Case Tests (RED)

- [ ] **6.1.1** Add single-room dungeon tests
  - _Ticket ref: AC-071_
  - _Tests: Single room, no edges, entry = boss, validate passes_
  - _TDD: RED — test edge case scenarios_

### 6.2 Add Topology Tests (RED)

- [ ] **6.2.1** Add fully-connected graph tests
  - _Ticket ref: AC-072_
  - _Tests: All rooms connected to all others, performance validation_
- [ ] **6.2.2** Add star topology tests
  - _Ticket ref: AC-073_
  - _Tests: Central hub room connected to all others, pathfinding validation_

### 6.3 Add Stress Tests (RED)

- [ ] **6.3.1** Add large dungeon stress tests
  - _Ticket ref: AC-074_
  - _Tests: 25-room linear chain, performance within limits_
- [ ] **6.3.2** Add clearing state independence tests
  - _Ticket ref: AC-075_
  - _Tests: Changing is_cleared doesn't affect graph operations_

### 6.4 Implement Helper Functions for Tests (GREEN)

- [ ] **6.4.1** Add test helper functions to test_dungeon_data.gd
  - _Helpers: _make_single_room(), _make_star_dungeon(), _make_large_dungeon()_
- [ ] **6.4.2** Ensure all edge case tests pass with existing implementation

### Phase 6 Validation Gate

- [ ] **6.V.1** Single-room dungeon edge case handled correctly
- [ ] **6.V.2** Fully-connected and star topology tests pass
- [ ] **6.V.3** 25-room stress test completes within performance limits
- [ ] **6.V.4** Clearing state changes don't break graph operations
- [ ] **6.V.5** All edge case and stress tests pass green
- [ ] **6.V.6** Commit: `"Phase 6: Add edge case and stress test coverage"`

---

## Phase 7: Final Validation & Cleanup

> **Ticket References**: NFR-008 through NFR-018
> **Estimated Items**: 6
> **Dependencies**: Phase 6 complete (all functionality implemented)
> **Validation Gate**: Code quality standards met, full test suite passes

### 7.1 Code Quality Review

- [ ] **7.1.1** Verify type hints on all methods and properties
  - _Ticket ref: NFR-008_
  - _Check: All parameters, return values, and properties have explicit types_
- [ ] **7.1.2** Verify GDScript style compliance
  - _Ticket ref: NFR-009_
  - _Check: snake_case variables/methods, PascalCase class names_
- [ ] **7.1.3** Add doc comments to all public methods
  - _Ticket ref: NFR-010_
  - _Check: ## doc comments on every exported property and public method_

### 7.2 Performance & Memory Validation

- [ ] **7.2.1** Verify algorithmic complexity requirements
  - _Ticket ref: NFR-001 through NFR-006_
  - _Check: get_adjacent O(E), get_path_to_boss O(V+E), validate O(V+E)_
- [ ] **7.2.2** Verify memory footprint for 25-room dungeon
  - _Ticket ref: NFR-007_
  - _Check: Dictionary representation under 10KB_

### 7.3 Final Test Run

- [ ] **7.3.1** Run complete test suite
  - _All ~78 tests in test_room_data.gd and test_dungeon_data.gd must pass green_
- [ ] **7.3.2** Verify no existing tests are broken
  - _Regression check: all pre-existing tests in tests/unit/ still pass_

### Phase 7 Validation Gate

- [ ] **7.V.1** All type hints in place and correct
- [ ] **7.V.2** All style guidelines followed
- [ ] **7.V.3** All public methods and properties have doc comments
- [ ] **7.V.4** Performance requirements met for algorithmic complexity
- [ ] **7.V.5** Memory requirements met for serialization
- [ ] **7.V.6** Complete test suite passes (100% green)
- [ ] **7.V.7** No regression in existing functionality
- [ ] **7.V.8** Commit: `"Phase 7: Final cleanup, documentation, and validation complete"`

---

## Phase Dependency Graph

```
Phase 0: Pre-Flight
    ↓
Phase 1: RoomData ←─┐
    ↓              │
Phase 2: DungeonData Properties
    ↓              │
Phase 3: Graph Operations
    ↓              │  
Phase 4: Validation│
    ↓              │
Phase 5: Serialization (needs RoomData.to_dict/from_dict)
    ↓
Phase 6: Edge Cases
    ↓
Phase 7: Final Validation
```

**Critical Path**: All phases are sequential. RoomData must be complete before DungeonData implementation begins, as DungeonData.serialization depends on RoomData.to_dict().

---

## Progress Summary Table

| Phase | Items | Tests | Status | Notes |
|-------|-------|-------|--------|-------|
| **Phase 0** | 5 | 0 | ⏳ Not Started | Pre-flight checks |
| **Phase 1** | 10 | ~28 | ⏳ Not Started | RoomData model |
| **Phase 2** | 9 | ~15 | ⏳ Not Started | DungeonData properties |
| **Phase 3** | 8 | ~20 | ⏳ Not Started | Graph operations |
| **Phase 4** | 10 | ~15 | ⏳ Not Started | Validation system |
| **Phase 5** | 8 | ~10 | ⏳ Not Started | Serialization |
| **Phase 6** | 7 | ~8 | ⏳ Not Started | Edge cases |
| **Phase 7** | 6 | 0 | ⏳ Not Started | Final validation |
| **TOTAL** | **63** | **~96** | **0% Complete** | |

---

## File Change Summary

| File | Type | Purpose | Lines (Est.) |
|------|------|---------|--------------|
| `src/models/room_data.gd` | NEW | Room node data model | ~120 |
| `src/models/dungeon_data.gd` | NEW | Dungeon graph data model | ~250 |
| `tests/models/test_room_data.gd` | NEW | RoomData unit tests | ~200 |
| `tests/models/test_dungeon_data.gd` | NEW | DungeonData unit tests | ~400 |
| `tests/models/` | NEW | Test directory | - |

**Total New Code**: ~970 lines  
**Files Modified**: 0  
**Files Deleted**: 0

---

## Commit Strategy

| Phase | Commit Message |
|-------|----------------|
| **Phase 0** | `Phase 0: Pre-flight verification and test directory setup` |
| **Phase 1** | `Phase 1: Implement RoomData model with properties, convenience methods, and serialization` |
| **Phase 2** | `Phase 2: Implement DungeonData properties and basic accessor methods` |
| **Phase 3** | `Phase 3: Implement graph operations - adjacency, BFS pathfinding, room queries` |
| **Phase 4** | `Phase 4: Implement complete graph validation with connectivity checks` |
| **Phase 5** | `Phase 5: Implement DungeonData serialization with round-trip stability` |
| **Phase 6** | `Phase 6: Add edge case and stress test coverage` |
| **Phase 7** | `Phase 7: Final cleanup, documentation, and validation complete` |

Each commit message will include the standard co-author trailer:
```
Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

---

## Deviation Tracking

| ID | Description | Impact | Resolution |
|----|-------------|---------|------------|
| DEV-001 | ✅ RESOLVED: Ticket assumed `Enums.Element.NONE` might not exist | LOW | Verified NONE exists in enums.gd line 21 |
| DEV-002 | Ticket test helpers use wrong Element names (FIRE→FLAME, WATER→FROST, EARTH→TERRA) | MEDIUM | Use actual enum names in test implementation |
| DEV-003 | Ticket test helpers use wrong Currency names (DUST→ESSENCE, GEMS→ARTIFACTS) | MEDIUM | Use actual enum names in test implementation |

**Resolution Strategy**: Use actual enum names from existing `src/models/enums.gd` instead of the incorrect names shown in ticket examples.

---

## Risk Register

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Graph algorithms incorrectly implemented | Medium | High | Use well-documented BFS, validate with multiple test cases |
| Serialization round-trip failures | Medium | High | Extensive round-trip tests with edge cases |
| Performance degradation on large dungeons | Low | Medium | Validate O(E) and O(V+E) complexity requirements |
| Enum name mismatches break tests | High | Low | Verify actual enum names in existing enums.gd |
| Test file location causes GUT issues | Low | Medium | Follow existing test directory patterns |
| Memory usage exceeds 10KB limit | Low | Medium | Test with 25-room dungeon serialization |

---

## Handoff State

**Current Status**: Not started — ready for Phase 0 execution

### What's Ready
- All dependencies from TASK-003 verified to exist
- Test methodology defined and documented
- Phased implementation plan with clear gates
- Complete AC/FR coverage mapping

### What's Needed Next
1. Execute Phase 0: Create tests/models/ directory and verify dependencies
2. Execute Phase 1: Implement RoomData with TDD approach
3. Continue through phases sequentially with validation gates

### Key Implementation Notes for Next Agent
- Follow strict TDD: RED test → GREEN implementation → REFACTOR
- Use actual enum names from enums.gd, not the incorrect ones in ticket examples
- Tests go in `tests/models/` NOT `tests/unit/`
- Both classes use `class_name` (they're not autoloads)
- Canonical edge ordering (a < b) is critical for validation
- BFS pathfinding must handle disconnected graphs gracefully

---

*End of TASK-005 Implementation Plan*

| Item | Status | Required By |
|------|--------|-------------|
| `Enums.Element.NONE` value | ❌ Missing | FR-021 — DungeonData.element default |
| `tests/models/` directory | ❌ Missing | Section 14 — test file locations |
| `src/models/room_data.gd` | ❌ Missing | FR-001 through FR-014 |
| `src/models/dungeon_data.gd` | ❌ Missing | FR-015 through FR-046 |
| `tests/models/test_room_data.gd` | ❌ Missing | Section 14 — RoomData tests |
| `tests/models/test_dungeon_data.gd` | ❌ Missing | Section 14 — DungeonData tests |

### What Must NOT Change

- `src/autoloads/event_bus.gd` — TASK-001 output, central signal bus
- `src/autoloads/game_manager.gd` — TASK-001 output, lifecycle singleton
- `src/models/game_config.gd` — TASK-003 output, game constants
- `src/gdscript/` — v1 prototype code, explicitly out of scope
- `project.godot` — no changes needed for this task
- Existing test files in `tests/unit/` — must not be broken

### CRITICAL: Enum Deviations from Ticket

The ticket makes three incorrect assumptions about `enums.gd` values. These are documented as DEV-001, DEV-002, and DEV-003 in the Deviation Tracking section.

1. **Element.NONE does not exist** — Ticket references `Enums.Element.NONE` but actual enum only has `{TERRA, FLAME, FROST, ARCANE, SHADOW}`. We must add `NONE` to `enums.gd` (see Phase 0).
2. **Element names are wrong in ticket test helpers** — Ticket uses `Element.FIRE`, `Element.WATER`, `Element.EARTH`. Actual names are `FLAME`, `FROST`, `TERRA`. Tests must use actual names.
3. **Currency names are wrong in ticket tests** — Ticket uses `Currency.DUST`, `Currency.GEMS`. Actual values are `GOLD`, `ESSENCE`, `FRAGMENTS`, `ARTIFACTS`. Tests must use actual names.

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
# Default construction
func test_default_index() -> void:

# Property assignment
func test_set_type() -> void:

# Convenience methods
func test_is_boss_true() -> void:

# Graph operations
func test_adjacent_linear_start() -> void:

# Validation
func test_validate_disconnected_graph() -> void:

# Serialization round-trips
func test_round_trip_linear() -> void:

# Edge cases
func test_large_dungeon_25_rooms() -> void:
```

### Test Structure (GUT)

Every test follows Arrange-Act-Assert:
```gdscript
func test_method_scenario_expected() -> void:
    # Arrange — create test dungeon
    var dungeon := _make_linear_dungeon(3, 2)

    # Act — execute the behavior
    var path: Array[int] = dungeon.get_path_to_boss()

    # Assert — verify the outcome
    assert_eq(path, [0, 1, 2])
```

### Coverage Requirements Per Phase

- ✅ **Existence**: Class exists, extends `RefCounted`, has `class_name`
- ✅ **Properties**: All typed properties initialized to correct defaults
- ✅ **Convenience methods**: `is_combat()`, `is_boss()`, `is_rest()` return correct values
- ✅ **Graph operations**: Adjacency, BFS pathfinding, uncleared tracking
- ✅ **Validation**: Connectivity, canonical edges, bounds checking
- ✅ **Serialization**: Round-trip fidelity, defensive deserialization
- ✅ **Edge cases**: Single-room, fully-connected, star topology, 25-room stress

---

## Phase 0: Pre-Flight & Dependency Verification

> **Ticket References**: FR-001, FR-015, FR-021 (prerequisites)
> **AC References**: AC-001 through AC-008, AC-022 through AC-028 (structural prerequisites)
> **Estimated Items**: 8
> **Dependencies**: TASK-003 complete (enums.gd, game_config.gd exist)
> **Validation Gate**: All TASK-003 dependencies verified, tests/models/ directory ready, Element.NONE added

This phase verifies upstream dependencies, creates the `tests/models/` directory, and resolves the critical Element.NONE deviation.

### 0.1 Verify TASK-003 Outputs

- [ ] **0.1.1** Verify `src/models/enums.gd` exists and declares `class_name Enums`
  - _Ticket ref: Assumption #1_
  - _File: `src/models/enums.gd`_
  - _Check: `Enums.RoomType` has COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS_
  - _Check: `Enums.Element` has TERRA, FLAME, FROST, ARCANE, SHADOW_
  - _Check: `Enums.Currency` has GOLD, ESSENCE, FRAGMENTS, ARTIFACTS_

- [ ] **0.1.2** Verify `src/models/game_config.gd` exists and declares `class_name GameConfig`
  - _Ticket ref: Assumption #1_
  - _File: `src/models/game_config.gd`_
  - _Check: `GameConfig.ROOM_DIFFICULTY_SCALE` exists_

- [ ] **0.1.3** Verify `addons/gut/` is installed and contains `plugin.cfg`
  - _Ticket ref: Pre-requisite for tests_

### 0.2 Resolve Element.NONE Deviation (DEV-001)

- [ ] **0.2.1** Add `NONE` value to `Enums.Element` enum in `src/models/enums.gd`
  - _Ticket ref: FR-021, AC-027_
  - _File: `src/models/enums.gd`_
  - _RECOMMENDED: Append `NONE` at the end of the Element enum to avoid shifting existing int values_
  - _Alternatively: Insert `NONE = 0` as first value and shift existing — but this may break TASK-004 serialized data_
  - _Decision: Append `NONE` at end is safest for backwards compatibility_
  - _DEV-001: Document this modification as a necessary deviation from TASK-003 output_

### 0.3 Create Test Directory

- [ ] **0.3.1** Create directory `tests/models/` if it does not exist
  - _Ticket ref: Section 14 — test files live in `tests/models/`, not `tests/unit/`_

### 0.4 Verify No Conflicts

- [ ] **0.4.1** Verify `src/models/room_data.gd` does NOT already exist (no file collision)
  - _File: `src/models/room_data.gd`_

- [ ] **0.4.2** Verify `src/models/dungeon_data.gd` does NOT already exist (no file collision)
  - _File: `src/models/dungeon_data.gd`_

- [ ] **0.4.3** Verify no existing `class_name RoomData` or `class_name DungeonData` in the codebase (search `src/` for conflicts)

### Phase 0 Validation Gate

- [ ] **0.V.1** All TASK-003 outputs verified present and contain expected enums/constants
- [ ] **0.V.2** `Enums.Element.NONE` exists in `enums.gd` (DEV-001 resolved)
- [ ] **0.V.3** `tests/models/` directory exists
- [ ] **0.V.4** No file conflicts detected for room_data.gd or dungeon_data.gd
- [ ] **0.V.5** GUT addon installed and available
- [ ] **0.V.6** Existing tests in `tests/unit/` pass (regression baseline)
- [ ] **0.V.7** Commit: `"Phase 0: Add Element.NONE to enums, create tests/models/ directory"`

---

## Phase 1: RoomData Model (TDD)

> **Ticket References**: FR-001 through FR-014
> **AC References**: AC-001 through AC-021
> **Estimated Items**: 10
> **Dependencies**: Phase 0 complete (enums verified, directories ready)
> **Validation Gate**: `room_data.gd` exists, extends RefCounted, has class_name, all ~28 RoomData tests pass

### 1.1 Write RoomData Tests (RED)

- [ ] **1.1.1** Create `tests/models/test_room_data.gd` with all test functions from ticket Section 14
  - _Ticket ref: Section 14 — File: `tests/models/test_room_data.gd`_
  - _File: `tests/models/test_room_data.gd`_
  - _Tests — Default Construction (~8 tests): `test_default_index`, `test_default_type`, `test_default_position`, `test_default_size`, `test_default_difficulty`, `test_default_loot_bias`, `test_default_is_cleared`, `test_default_metadata`_
  - _Tests — Property Assignment (~8 tests): `test_set_index`, `test_set_type`, `test_set_position`, `test_set_size`, `test_set_difficulty`, `test_set_loot_bias`, `test_set_is_cleared`, `test_set_metadata`_
  - _Tests — Convenience Methods (~6 tests): `test_is_combat_true`, `test_is_combat_false_for_boss`, `test_is_boss_true`, `test_is_boss_false_for_combat`, `test_is_rest_true`, `test_is_rest_false_for_trap`_
  - _Tests — Serialization (~6 tests): `test_to_dict_has_all_keys`, `test_to_dict_type_is_int`, `test_to_dict_position_is_dict`, `test_to_dict_size_is_dict`, `test_to_dict_loot_bias_is_int`, `test_to_dict_metadata_preserved`, `test_round_trip_default`, `test_round_trip_custom`, `test_from_dict_empty_dict`_
  - _TDD: RED — tests reference `RoomData` class which does not exist yet_
  - _CRITICAL DEV-002/DEV-003: The ticket test code uses wrong enum names (`Currency.DUST`, `Currency.GEMS`). Replace with actual names (`Enums.Currency.ESSENCE`, `Enums.Currency.FRAGMENTS`, etc.) when writing tests_

### 1.2 Implement RoomData (GREEN)

- [ ] **1.2.1** Create `src/models/room_data.gd` with class declaration
  - _Ticket ref: FR-001, AC-001_
  - _File: `src/models/room_data.gd`_
  - _Content: `class_name RoomData` + `extends RefCounted` + class doc comment_

- [ ] **1.2.2** Add all 8 properties with type hints and defaults
  - _Ticket ref: FR-002 through FR-009, AC-001 through AC-008_
  - _Properties: `index: int = 0`, `type: Enums.RoomType = Enums.RoomType.COMBAT`, `position: Vector2 = Vector2.ZERO`, `size: Vector2 = Vector2(1.0, 1.0)`, `difficulty: int = 1`, `loot_bias: Enums.Currency = Enums.Currency.GOLD`, `is_cleared: bool = false`, `metadata: Dictionary = {}`_
  - _All properties must have `##` doc comments_

- [ ] **1.2.3** Add convenience methods `is_combat()`, `is_boss()`, `is_rest()`
  - _Ticket ref: FR-012, FR-013, FR-014, AC-010 through AC-013_
  - _`is_combat() -> bool`: returns `type == Enums.RoomType.COMBAT`_
  - _`is_boss() -> bool`: returns `type == Enums.RoomType.BOSS`_
  - _`is_rest() -> bool`: returns `type == Enums.RoomType.REST`_

- [ ] **1.2.4** Add `to_dict() -> Dictionary` serialization method
  - _Ticket ref: FR-010, AC-014 through AC-018_
  - _File: `src/models/room_data.gd`_
  - _Enums stored as integers via `int()` cast_
  - _`position` stored as `{"x": position.x, "y": position.y}` (NFR-018)_
  - _`size` stored as `{"x": size.x, "y": size.y}` (NFR-018)_
  - _`metadata` duplicated to prevent reference sharing_

- [ ] **1.2.5** Add `static from_dict(data: Dictionary) -> RoomData` deserialization method
  - _Ticket ref: FR-011, AC-019 through AC-021_
  - _File: `src/models/room_data.gd`_
  - _Uses defensive `data.get("key", default)` for all fields (NFR-012)_
  - _Restores Vector2 from `{"x": float, "y": float}` dicts_
  - _Restores enums from integer values_
  - _Must NOT crash on empty dict — returns default-initialized RoomData (AC-020)_

### Phase 1 Validation Gate

- [ ] **1.V.1** `src/models/room_data.gd` exists and is parseable GDScript
- [ ] **1.V.2** File extends `RefCounted` and declares `class_name RoomData`
- [ ] **1.V.3** All 8 properties have type hints and default values
- [ ] **1.V.4** `is_combat()`, `is_boss()`, `is_rest()`, `to_dict()`, `from_dict()` all have `##` doc comments
- [ ] **1.V.5** All ~28 RoomData tests pass green
- [ ] **1.V.6** No Node, SceneTree, Timer, or signal declarations in file (NFR-013)
- [ ] **1.V.7** `to_dict()` output is JSON-serializable — no Godot-specific types (NFR-016)
- [ ] **1.V.8** Commit: `"Phase 1: Add RoomData model with serialization — ~28 tests"`

---

## Phase 2: DungeonData Properties & Basic Accessors (TDD)

> **Ticket References**: FR-015 through FR-022, FR-030 through FR-033
> **AC References**: AC-022 through AC-028, AC-042 through AC-048
> **Estimated Items**: 10
> **Dependencies**: Phase 1 complete (RoomData available for rooms property)
> **Validation Gate**: `dungeon_data.gd` exists with all properties and basic accessors; construction and accessor tests pass

### 2.1 Write DungeonData Construction & Accessor Tests (RED)

- [ ] **2.1.1** Create `tests/models/test_dungeon_data.gd` with test helpers and default construction + accessor tests
  - _Ticket ref: Section 14 — File: `tests/models/test_dungeon_data.gd`_
  - _File: `tests/models/test_dungeon_data.gd`_
  - _Write full test file header (extends GutTest, helper methods: `_make_room`, `_make_linear_dungeon`, `_make_branching_dungeon`, `_make_star_dungeon`, `_make_single_room_dungeon`, `_make_large_dungeon`)_
  - _CRITICAL DEV-002: Helper `_make_linear_dungeon` uses `Enums.Element.FIRE` in ticket — replace with `Enums.Element.FLAME`_
  - _CRITICAL DEV-002: Helper `_make_branching_dungeon` uses `Enums.Element.WATER` — replace with `Enums.Element.FROST`_
  - _CRITICAL DEV-002: Helper `_make_star_dungeon` uses `Enums.Element.EARTH` — replace with `Enums.Element.TERRA`_
  - _Tests — Default Construction (~7 tests): `test_default_seed_id`, `test_default_rooms`, `test_default_edges`, `test_default_entry_room_index`, `test_default_boss_room_index`, `test_default_element`, `test_default_difficulty`_
  - _Tests — Basic Accessors (~7 tests): `test_get_room_valid`, `test_get_room_out_of_bounds_negative`, `test_get_room_out_of_bounds_large`, `test_get_room_count`, `test_get_edge_count`, `test_has_boss_room_true`, `test_has_boss_room_false`_
  - _TDD: RED — tests reference `DungeonData` class which does not exist yet_

### 2.2 Implement DungeonData Properties & Accessors (GREEN)

- [ ] **2.2.1** Create `src/models/dungeon_data.gd` with class declaration
  - _Ticket ref: FR-015, AC-022_
  - _File: `src/models/dungeon_data.gd`_
  - _Content: `class_name DungeonData` + `extends RefCounted` + class doc comment_

- [ ] **2.2.2** Add all 7 properties with type hints and defaults
  - _Ticket ref: FR-016 through FR-022, AC-022 through AC-028_
  - _Properties: `seed_id: String = ""`, `rooms: Array[RoomData] = []`, `edges: Array[Vector2i] = []`, `entry_room_index: int = 0`, `boss_room_index: int = -1`, `element: Enums.Element = Enums.Element.NONE`, `difficulty: int = 1`_
  - _All properties must have `##` doc comments_
  - _Note: `element` default requires `Enums.Element.NONE` — added in Phase 0 (DEV-001)_

- [ ] **2.2.3** Add `get_room(index: int) -> RoomData` method
  - _Ticket ref: FR-030, AC-042 through AC-044_
  - _Returns `null` for out-of-bounds or negative indices_
  - _Returns `rooms[index]` for valid indices_

- [ ] **2.2.4** Add `get_room_count() -> int` method
  - _Ticket ref: FR-031, AC-045_
  - _Returns `rooms.size()`_

- [ ] **2.2.5** Add `get_edge_count() -> int` method
  - _Ticket ref: FR-032, AC-046_
  - _Returns `edges.size()`_

- [ ] **2.2.6** Add `has_boss_room() -> bool` method
  - _Ticket ref: FR-033, AC-047, AC-048_
  - _Returns `boss_room_index >= 0 and boss_room_index < rooms.size()`_

### Phase 2 Validation Gate

- [ ] **2.V.1** `src/models/dungeon_data.gd` exists and is parseable GDScript
- [ ] **2.V.2** File extends `RefCounted` and declares `class_name DungeonData`
- [ ] **2.V.3** All 7 properties have type hints and correct defaults
- [ ] **2.V.4** `get_room()` returns `null` for invalid indices
- [ ] **2.V.5** `has_boss_room()` correctly handles -1 sentinel
- [ ] **2.V.6** All ~14 construction + accessor tests pass green
- [ ] **2.V.7** Commit: `"Phase 2: Add DungeonData properties & basic accessors — ~14 tests"`

---

## Phase 3: Graph Operations (TDD)

> **Ticket References**: FR-023 through FR-029
> **AC References**: AC-029 through AC-041
> **Estimated Items**: 10
> **Dependencies**: Phase 2 complete (DungeonData exists with properties)
> **Validation Gate**: `get_adjacent()`, `get_path_to_boss()`, `get_uncleared_rooms()`, `is_fully_cleared()` all work correctly

### 3.1 Write Graph Operation Tests (RED)

- [ ] **3.1.1** Add `get_adjacent()` test section to `tests/models/test_dungeon_data.gd`
  - _Ticket ref: Section 14 — get_adjacent tests_
  - _File: `tests/models/test_dungeon_data.gd`_
  - _Tests (~8 tests): `test_adjacent_linear_start`, `test_adjacent_linear_middle`, `test_adjacent_linear_end`, `test_adjacent_star_center`, `test_adjacent_star_leaf`, `test_adjacent_out_of_bounds_negative`, `test_adjacent_out_of_bounds_large`, `test_adjacent_single_room`_
  - _TDD: RED — tests reference `get_adjacent()` method which does not exist yet_

- [ ] **3.1.2** Add `get_path_to_boss()` test section to `tests/models/test_dungeon_data.gd`
  - _Ticket ref: Section 14 — get_path_to_boss tests_
  - _File: `tests/models/test_dungeon_data.gd`_
  - _Tests (~6 tests): `test_path_to_boss_linear`, `test_path_to_boss_star_direct`, `test_path_to_boss_branching_shortest`, `test_path_to_boss_no_boss`, `test_path_to_boss_single_room_boss`, `test_path_to_boss_five_room_chain`_
  - _TDD: RED — tests reference `get_path_to_boss()` method which does not exist yet_

- [ ] **3.1.3** Add `get_uncleared_rooms()` / `is_fully_cleared()` test section to `tests/models/test_dungeon_data.gd`
  - _Ticket ref: Section 14 — uncleared/cleared tests_
  - _File: `tests/models/test_dungeon_data.gd`_
  - _Tests (~7 tests): `test_uncleared_all_rooms_initially`, `test_uncleared_after_partial_clear`, `test_uncleared_all_cleared`, `test_is_fully_cleared_false`, `test_is_fully_cleared_partial`, `test_is_fully_cleared_true`, `test_is_fully_cleared_single_room`_
  - _TDD: RED — tests reference methods which do not exist yet_

### 3.2 Implement Graph Operations (GREEN)

- [ ] **3.2.1** Add `get_adjacent(room_index: int) -> Array[int]` method
  - _Ticket ref: FR-023, FR-024, AC-029 through AC-033_
  - _File: `src/models/dungeon_data.gd`_
  - _Guard: Return empty array if `room_index < 0 or room_index >= rooms.size()` (FR-024)_
  - _Iterate edges: if `edge.x == room_index`, add `edge.y`; if `edge.y == room_index`, add `edge.x` (undirected)_
  - _O(E) time complexity (NFR-001)_

- [ ] **3.2.2** Add `get_path_to_boss() -> Array[int]` method using BFS
  - _Ticket ref: FR-025, FR-026, FR-027, AC-034 through AC-036_
  - _File: `src/models/dungeon_data.gd`_
  - _Guard: Return `[]` if `boss_room_index < 0` (FR-026)_
  - _Guard: Return `[]` if `boss_room_index >= rooms.size()`_
  - _BFS from `entry_room_index` to `boss_room_index`_
  - _Reconstruct path from parent map_
  - _Return `[]` if boss unreachable (FR-027)_
  - _O(V + E) time complexity (NFR-002)_

- [ ] **3.2.3** Add `get_uncleared_rooms() -> Array[int]` method
  - _Ticket ref: FR-028, AC-037 through AC-039_
  - _File: `src/models/dungeon_data.gd`_
  - _Iterate rooms, collect indices where `is_cleared == false`_
  - _O(V) time complexity_

- [ ] **3.2.4** Add `is_fully_cleared() -> bool` method
  - _Ticket ref: FR-029, AC-040, AC-041_
  - _File: `src/models/dungeon_data.gd`_
  - _Returns `true` only when every room's `is_cleared` is `true`_
  - _O(V) time complexity (NFR-004)_

### Phase 3 Validation Gate

- [ ] **3.V.1** `get_adjacent()` returns correct neighbors for linear, star, and branching graphs
- [ ] **3.V.2** `get_adjacent()` returns empty array for out-of-bounds indices
- [ ] **3.V.3** `get_path_to_boss()` finds shortest path via BFS
- [ ] **3.V.4** `get_path_to_boss()` returns `[]` for no-boss and unreachable-boss cases
- [ ] **3.V.5** `get_uncleared_rooms()` tracks room clearance correctly
- [ ] **3.V.6** `is_fully_cleared()` returns `true` only when all rooms cleared
- [ ] **3.V.7** All ~21 graph operation tests pass green
- [ ] **3.V.8** Commit: `"Phase 3: Add graph operations (get_adjacent, BFS path, uncleared rooms) — ~21 tests"`

---

## Phase 4: Validation (TDD)

> **Ticket References**: FR-034 through FR-042
> **AC References**: AC-049 through AC-059
> **Estimated Items**: 8
> **Dependencies**: Phase 3 complete (graph operations exist for validation BFS)
> **Validation Gate**: `validate()` correctly checks all graph invariants

### 4.1 Write Validation Tests (RED)

- [ ] **4.1.1** Add validation positive-case tests to `tests/models/test_dungeon_data.gd`
  - _Ticket ref: Section 14 — validate positive tests_
  - _File: `tests/models/test_dungeon_data.gd`_
  - _Tests (~5 tests): `test_validate_linear_dungeon`, `test_validate_branching_dungeon`, `test_validate_star_dungeon`, `test_validate_single_room`, `test_validate_no_boss`_
  - _TDD: RED — tests reference `validate()` method which does not exist yet_

- [ ] **4.1.2** Add validation negative-case tests to `tests/models/test_dungeon_data.gd`
  - _Ticket ref: Section 14 — validate negative tests_
  - _File: `tests/models/test_dungeon_data.gd`_
  - _Tests (~8 tests): `test_validate_empty_rooms`, `test_validate_entry_out_of_bounds`, `test_validate_boss_out_of_bounds`, `test_validate_edge_out_of_bounds`, `test_validate_non_canonical_edge`, `test_validate_duplicate_edge`, `test_validate_self_loop`, `test_validate_disconnected_graph`_
  - _TDD: RED — tests reference `validate()` method which does not exist yet_

### 4.2 Implement validate() Method (GREEN)

- [ ] **4.2.1** Add `validate() -> bool` method
  - _Ticket ref: FR-034 through FR-042, AC-049 through AC-059_
  - _File: `src/models/dungeon_data.gd`_
  - _Check: `rooms.size() >= 1` (FR-034, AC-049)_
  - _Check: `entry_room_index >= 0 and entry_room_index < rooms.size()` (FR-035, AC-050)_
  - _Check: `boss_room_index == -1 or (boss_room_index >= 0 and boss_room_index < rooms.size())` (FR-036, AC-051)_
  - _Check all edges: `edge.x >= 0 and edge.y < rooms.size()` (FR-037, AC-052)_
  - _Check canonical ordering: `edge.x < edge.y` for all edges (FR-038, AC-053)_
  - _Check no self-loops: `edge.x != edge.y` for all edges (FR-040, AC-055)_
  - _Check no duplicate edges (FR-039, AC-054)_
  - _BFS connectivity check from `entry_room_index` — all rooms must be reachable (FR-041, AC-056)_
  - _If `boss_room_index >= 0`, verify boss is in BFS visited set (FR-042)_
  - _O(V + E) time complexity (NFR-003)_

### Phase 4 Validation Gate

- [ ] **4.V.1** `validate()` returns `true` for valid linear, branching, star, and single-room dungeons
- [ ] **4.V.2** `validate()` returns `false` for empty rooms
- [ ] **4.V.3** `validate()` returns `false` for out-of-bounds entry/boss/edge indices
- [ ] **4.V.4** `validate()` returns `false` for non-canonical, duplicate, and self-loop edges
- [ ] **4.V.5** `validate()` returns `false` for disconnected graphs
- [ ] **4.V.6** All ~13 validation tests pass green
- [ ] **4.V.7** Commit: `"Phase 4: Add validate() with BFS connectivity check — ~13 tests"`

---

## Phase 5: DungeonData Serialization (TDD)

> **Ticket References**: FR-043 through FR-046
> **AC References**: AC-060 through AC-070
> **Estimated Items**: 8
> **Dependencies**: Phase 4 complete (validate() available for round-trip verification)
> **Validation Gate**: `to_dict()` and `from_dict()` produce perfect round-trips; room_count cap enforced

### 5.1 Write Serialization Tests (RED)

- [ ] **5.1.1** Add DungeonData serialization tests to `tests/models/test_dungeon_data.gd`
  - _Ticket ref: Section 14 — DungeonData serialization tests_
  - _File: `tests/models/test_dungeon_data.gd`_
  - _Tests (~11 tests): `test_to_dict_has_all_keys`, `test_to_dict_rooms_is_array`, `test_to_dict_edges_format`, `test_to_dict_element_is_int`, `test_round_trip_linear`, `test_round_trip_preserves_room_data`, `test_round_trip_preserves_edges`, `test_round_trip_preserves_positions`, `test_from_dict_empty`, `test_from_dict_caps_room_count`_
  - _TDD: RED — tests reference `to_dict()` and `from_dict()` methods which do not exist yet_

### 5.2 Implement DungeonData Serialization (GREEN)

- [ ] **5.2.1** Add `to_dict() -> Dictionary` method to DungeonData
  - _Ticket ref: FR-043, AC-060 through AC-063_
  - _File: `src/models/dungeon_data.gd`_
  - _Serializes `seed_id`, `entry_room_index`, `boss_room_index`, `difficulty` directly_
  - _`element` stored as integer via `int()` cast_
  - _`rooms` serialized as Array of `room.to_dict()` results_
  - _`edges` serialized as Array of `[edge.x, edge.y]` two-element arrays (NFR-017)_
  - _O(V + E) time complexity (NFR-005)_

- [ ] **5.2.2** Add `static from_dict(data: Dictionary) -> DungeonData` method to DungeonData
  - _Ticket ref: FR-044, FR-045, FR-046, AC-064 through AC-070_
  - _File: `src/models/dungeon_data.gd`_
  - _Uses defensive `data.get("key", default)` for all fields (NFR-012)_
  - _`element` integer clamped to valid enum range before cast_
  - _`rooms` restored via `RoomData.from_dict()` for each room dict_
  - _Room count capped at 100 — discard excess (AC-070, THREAT-005)_
  - _`edges` restored from `[a, b]` arrays to `Vector2i(a, b)`_
  - _Must NOT crash on empty dict — returns default-initialized DungeonData (AC-069)_
  - _O(V + E) time complexity (NFR-006)_

### Phase 5 Validation Gate

- [ ] **5.V.1** `to_dict()` returns Dictionary with all 7 expected keys
- [ ] **5.V.2** Edges serialized as `[[a, b], ...]` format, not Vector2i strings
- [ ] **5.V.3** Enum values serialized as integers, not strings
- [ ] **5.V.4** Round-trip `from_dict(to_dict())` preserves all fields including room metadata
- [ ] **5.V.5** `from_dict({})` returns default DungeonData without crashing
- [ ] **5.V.6** `from_dict()` caps room count at 100
- [ ] **5.V.7** All ~11 serialization tests pass green
- [ ] **5.V.8** Commit: `"Phase 5: Add DungeonData to_dict()/from_dict() serialization with round-trip guarantee — ~11 tests"`

---

## Phase 6: Edge Cases & Stress Tests (TDD)

> **Ticket References**: AC-071 through AC-075
> **AC References**: AC-071 through AC-075
> **Estimated Items**: 6
> **Dependencies**: Phase 5 complete (all methods exist for edge case testing)
> **Validation Gate**: All edge case and stress tests pass

### 6.1 Write Edge Case Tests (RED → GREEN)

- [ ] **6.1.1** Add single-room boss dungeon test
  - _Ticket ref: AC-072_
  - _File: `tests/models/test_dungeon_data.gd`_
  - _Test: `test_single_room_boss_dungeon` — 1 room (BOSS type), entry=0, boss=0, validate passes, `get_path_to_boss()` returns `[0]`_
  - _TDD: RED test → GREEN — should pass with existing implementation_

- [ ] **6.1.2** Add fully-connected 4-room graph test
  - _Ticket ref: AC-073_
  - _File: `tests/models/test_dungeon_data.gd`_
  - _Test: `test_fully_connected_four_rooms` — 4 rooms, 6 edges (complete graph), `get_adjacent(0)` returns 3 neighbors, BFS path to boss is direct `[0, 3]`_
  - _TDD: RED test → GREEN — should pass with existing implementation_

- [ ] **6.1.3** Add star topology test (already covered by helpers, but explicit AC)
  - _Ticket ref: AC-074_
  - _File: `tests/models/test_dungeon_data.gd`_
  - _Verified by existing `test_path_to_boss_star_direct` — `[0, 4]` direct path_

- [ ] **6.1.4** Add 25-room stress test
  - _Ticket ref: AC-075_
  - _File: `tests/models/test_dungeon_data.gd`_
  - _Test: `test_large_dungeon_25_rooms` — 25 rooms, 24 edges (chain), validate passes, all operations complete without error_
  - _TDD: RED test → GREEN — should pass with existing implementation_

- [ ] **6.1.5** Add clearing-does-not-affect-graph test
  - _Ticket ref: AC-071 (implied), general edge case_
  - _File: `tests/models/test_dungeon_data.gd`_
  - _Test: `test_clearing_rooms_does_not_affect_graph` — clear all rooms, verify validate still passes, adjacency unchanged, path unchanged_
  - _TDD: RED test → GREEN — should pass with existing implementation_

### Phase 6 Validation Gate

- [ ] **6.V.1** Single-room boss dungeon works correctly
- [ ] **6.V.2** Fully-connected graph operations work correctly
- [ ] **6.V.3** 25-room stress test completes without error
- [ ] **6.V.4** Clearing rooms does not affect graph structure or validation
- [ ] **6.V.5** All ~5 edge case tests pass green
- [ ] **6.V.6** Commit: `"Phase 6: Add edge case & stress tests (single-room, fully-connected, 25-room) — ~5 tests"`

---

## Phase 7: Final Validation & Cleanup

> **Ticket References**: All FRs, all ACs, NFR-001 through NFR-018
> **Estimated Items**: 12
> **Dependencies**: ALL prior phases complete
> **Validation Gate**: All ~78 tests pass, all NFRs verified, code quality clean

### 7.1 Full Test Run

- [ ] **7.1.1** Run complete GUT test suite for `tests/models/test_room_data.gd` — verify all ~28 tests pass
  - _Expected: ~28 pass, 0 fail, 0 error_
  - _Breakdown: ~8 defaults + ~8 property assignment + ~6 convenience + ~6 serialization_

- [ ] **7.1.2** Run complete GUT test suite for `tests/models/test_dungeon_data.gd` — verify all ~50 tests pass
  - _Expected: ~50 pass, 0 fail, 0 error_
  - _Breakdown: ~7 defaults + ~7 accessors + ~21 graph ops + ~13 validation + ~11 serialization + ~5 edge cases_

- [ ] **7.1.3** Run all existing tests in `tests/unit/` — verify zero regressions
  - _Expected: All pre-existing tests still pass_

### 7.2 Code Quality Verification (NFRs)

- [ ] **7.2.1** All public methods in `room_data.gd` and `dungeon_data.gd` have static type hints on parameters and return values (NFR-008)
- [ ] **7.2.2** All public methods have `##` doc comments describing purpose, parameters, and return value (NFR-010)
- [ ] **7.2.3** No `Node`, `SceneTree`, `Timer`, or `signal` declarations in either model file (NFR-013)
- [ ] **7.2.4** No `print()` or `push_warning()` calls in production code paths (NFR-011)
- [ ] **7.2.5** File names are snake_case: `room_data.gd`, `dungeon_data.gd` (NFR-009)
- [ ] **7.2.6** `to_dict()` output is JSON-serializable — no Godot-specific types like Vector2 or Vector2i (NFR-016, NFR-017, NFR-018)
- [ ] **7.2.7** `from_dict()` handles missing optional keys with defaults (NFR-012)
- [ ] **7.2.8** `RoomData` does NOT reference `DungeonData` — no cyclic dependencies (NFR-013)
- [ ] **7.2.9** Both files use `class_name` (safe — not autoloads)

### 7.3 Performance Spot Checks

- [ ] **7.3.1** Verify `get_adjacent()` is O(E) — no nested edge iteration (NFR-001)
- [ ] **7.3.2** Verify `get_path_to_boss()` is O(V + E) — single BFS pass (NFR-002)
- [ ] **7.3.3** Verify `validate()` is O(V + E) — single BFS plus single edge scan (NFR-003)

### Phase 7 Validation Gate

- [ ] **7.V.1** All ~78 tests pass green across both test files
- [ ] **7.V.2** Zero existing tests broken
- [ ] **7.V.3** All NFRs verified
- [ ] **7.V.4** All ACs verified
- [ ] **7.V.5** Commit: `"TASK-005 complete: Dungeon Room Graph Data Structure — ~78 tests, all green"`

---

## Phase Dependency Graph

```
Phase 0 (Pre-flight & Element.NONE fix)
  │
  ▼
Phase 1 (RoomData model — TDD)
  │
  ▼
Phase 2 (DungeonData properties & accessors — TDD)
  │
  ▼
Phase 3 (Graph operations — TDD)
  │
  ▼
Phase 4 (Validation — TDD)
  │
  ▼
Phase 5 (DungeonData serialization — TDD)
  │
  ▼
Phase 6 (Edge cases & stress tests — TDD)
  │
  ▼
Phase 7 (Final validation & cleanup)
```

**Parallelism note**: This task is strictly sequential. Each phase depends on the previous phase's output. RoomData must exist before DungeonData (which contains it). Graph operations must exist before validation (which uses BFS internally). Serialization must come after validation (round-trip tests call validate). Edge cases test the complete API surface.

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 0 | Pre-flight & Element.NONE fix | 8 | 0 | 0 | ⬜ Not Started |
| Phase 1 | RoomData model (TDD) | 10 | 0 | ~28 | ⬜ Not Started |
| Phase 2 | DungeonData properties & accessors (TDD) | 10 | 0 | ~14 | ⬜ Not Started |
| Phase 3 | Graph operations (TDD) | 10 | 0 | ~21 | ⬜ Not Started |
| Phase 4 | Validation (TDD) | 8 | 0 | ~13 | ⬜ Not Started |
| Phase 5 | DungeonData serialization (TDD) | 8 | 0 | ~11 | ⬜ Not Started |
| Phase 6 | Edge cases & stress tests (TDD) | 6 | 0 | ~5 | ⬜ Not Started |
| Phase 7 | Final validation & cleanup | 12 | 0 | ~78 | ⬜ Not Started |
| **Total** | | **~72** | **0** | **~78** | **⬜ Phase 0 Next** |

---

## File Change Summary

### New Files

| File | Phase | Purpose |
|------|-------|---------|
| `src/models/room_data.gd` | 1 | RoomData data class — single dungeon room node |
| `src/models/dungeon_data.gd` | 2–5 | DungeonData graph model — rooms, edges, graph operations, validation, serialization |
| `tests/models/test_room_data.gd` | 1 | ~28 unit tests covering RoomData defaults, properties, convenience, serialization |
| `tests/models/test_dungeon_data.gd` | 2–6 | ~50 unit tests covering DungeonData construction, graph ops, validation, serialization, edge cases |

### Modified Files

| File | Phase | Purpose |
|------|-------|---------|
| `src/models/enums.gd` | 0 | Add `NONE` to `Enums.Element` enum (DEV-001) |

### Deleted Files

None — this task is additive only (except the minor enum modification).

---

## Commit Strategy

| Phase | Commit Message | Tests After |
|-------|----------------|-------------|
| 0 | `"Phase 0: Add Element.NONE to enums, create tests/models/ directory"` | 0 (baseline check) |
| 1 | `"Phase 1: Add RoomData model with serialization — ~28 tests"` | ~28 |
| 2 | `"Phase 2: Add DungeonData properties & basic accessors — ~14 tests"` | ~42 |
| 3 | `"Phase 3: Add graph operations (get_adjacent, BFS path, uncleared rooms) — ~21 tests"` | ~63 |
| 4 | `"Phase 4: Add validate() with BFS connectivity check — ~13 tests"` | ~76 |
| 5 | `"Phase 5: Add DungeonData to_dict()/from_dict() serialization — ~11 tests"` | ~87 |
| 6 | `"Phase 6: Add edge case & stress tests — ~5 tests"` | ~92 |
| 7 | `"TASK-005 complete: Dungeon Room Graph Data Structure — ~78 tests, all green"` | ~78 ✅ |

> **Note**: Test counts in Phases 2–6 are cumulative in the `Tests After` column. The Phase 7 total is ~78 unique tests across both files (~28 in test_room_data.gd + ~50 in test_dungeon_data.gd).

---

## Deviation Tracking

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| DEV-001 | 0 | `Enums.Element.NONE` does not exist — must be added to `enums.gd` | FR-021, AC-027 | Ticket assumes `Element.NONE` exists as the default for `DungeonData.element`, but TASK-003's `enums.gd` only defines `{TERRA, FLAME, FROST, ARCANE, SHADOW}`. **Resolution**: Append `NONE` at the end of the Element enum. This preserves existing integer values for TERRA=0, FLAME=1, etc. and adds NONE=5. Alternatively, insert NONE=0 and shift all others, but this risks breaking TASK-004 serialized SeedData that stores Element as int. **RECOMMENDED: Append NONE at end.** | Medium — requires modifying TASK-003 output file. Must verify TASK-004 tests still pass after modification. |
| DEV-002 | 1, 2 | Ticket test helpers use wrong Element names: `FIRE`, `WATER`, `EARTH` | Section 14 test code | Actual `Enums.Element` values are `FLAME`, `FROST`, `TERRA` — not `FIRE`, `WATER`, `EARTH`. The ticket's test helpers (`_make_linear_dungeon`, `_make_branching_dungeon`, `_make_star_dungeon`) reference non-existent enum values. **Resolution**: Replace all occurrences: `Element.FIRE` → `Element.FLAME`, `Element.WATER` → `Element.FROST`, `Element.EARTH` → `Element.TERRA` when writing test files. | Low — test code only. No production impact. |
| DEV-003 | 1 | Ticket test helpers use wrong Currency names: `DUST`, `GEMS` | Section 14 test code | Actual `Enums.Currency` values are `GOLD, ESSENCE, FRAGMENTS, ARTIFACTS` — not `GOLD, DUST, GEMS`. The ticket's test code (`test_set_loot_bias`, `test_to_dict_loot_bias_is_int`, `test_to_dict_metadata_preserved`, `test_round_trip_custom`) references `Currency.DUST` and `Currency.GEMS`. **Resolution**: Replace `Currency.DUST` → `Currency.ESSENCE`, `Currency.GEMS` → `Currency.FRAGMENTS` when writing test files. | Low — test code only. No production impact. |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| TASK-003 not merged — `Enums` or `GameConfig` missing | Low | Critical | Phase 0 verifies all TASK-003 outputs exist before writing any code. Block until resolved. | 0 |
| Adding `Element.NONE` breaks TASK-004 SeedData serialization (if NONE=0 shifts existing values) | Medium | High | Append NONE at end of enum (NONE=5) instead of inserting at position 0. Run TASK-004 tests after modification. | 0 |
| `class_name RoomData` or `class_name DungeonData` conflicts with v1 prototype | Low | Medium | Phase 0 searches entire `src/` for naming conflicts. `RoomData` and `DungeonData` are not used in v1 prototype. | 0 |
| `Array[RoomData]` typed array not supported in Godot 4.6.1 | Very Low | Medium | If unsupported, fall back to untyped `Array` with manual validation. Document as deviation. | 2 |
| `Array[Vector2i]` typed array not supported in Godot 4.6.1 | Very Low | Medium | If unsupported, fall back to untyped `Array`. Edge validation in `validate()` already checks types. | 2 |
| BFS in `get_path_to_boss()` does not find shortest path due to implementation bug | Low | High | Test with branching dungeon where two equal-length paths exist. BFS guarantees shortest path in unweighted graph by definition. | 3 |
| `validate()` false positives — rejects valid graphs | Medium | Medium | Extensive positive-case tests (linear, branching, star, single-room, no-boss). Test every graph topology from the ticket. | 4 |
| `from_dict()` crashes on unexpected data types in save files | Medium | Medium | Defensive `data.get()` with defaults. Type casts with `int()`. Room count cap at 100. Tested with empty dict in Phase 5. | 5 |
| Ticket test code references `Currency.DUST`/`Currency.GEMS` — copy-paste error causes test failures | High | Low | DEV-003 documents the fix. Replace with actual Currency names when writing tests. Do NOT copy ticket test code verbatim. | 1, 2 |
| `tests/models/` directory not recognized by GUT runner | Low | Medium | Verify GUT config includes `tests/models/` in test search paths. May need to update `.gutconfig.json` or GUT panel settings. | 0 |

---

## Handoff State (2025-07-19)

### What's Complete
- Implementation plan written and ready for execution

### What's In Progress
- Nothing — plan is at Phase 0 (not started)

### What's Blocked
- Nothing — TASK-003 (Enums & Constants) is complete. TASK-001 (Project Bootstrap) is complete.

### Next Steps
1. Execute Phase 0: Verify TASK-003 dependencies, add Element.NONE to enums.gd, create tests/models/ directory
2. Execute Phase 1: Write RoomData tests (RED), then implement room_data.gd (GREEN)
3. Execute Phase 2: Write DungeonData construction/accessor tests (RED), implement dungeon_data.gd core (GREEN)
4. Execute Phase 3: Write graph operation tests (RED), implement get_adjacent, get_path_to_boss, get_uncleared_rooms, is_fully_cleared (GREEN)
5. Execute Phase 4: Write validation tests (RED), implement validate() with BFS connectivity (GREEN)
6. Execute Phase 5: Write serialization tests (RED), implement to_dict()/from_dict() (GREEN)
7. Execute Phase 6: Write edge case tests (RED → GREEN) for single-room, fully-connected, 25-room stress
8. Execute Phase 7: Full validation, NFR checks, final commit

---

## Ticket FR/AC Coverage Matrix

Every Functional Requirement and Acceptance Criterion from the ticket is mapped below.

### Functional Requirements → Phase Items

| FR | Description | Phase | Checkbox |
|----|-------------|-------|----------|
| FR-001 | RoomData class_name + extends RefCounted | 1 | 1.2.1 |
| FR-002 | index: int = 0 | 1 | 1.2.2 |
| FR-003 | type: Enums.RoomType = COMBAT | 1 | 1.2.2 |
| FR-004 | position: Vector2 = ZERO | 1 | 1.2.2 |
| FR-005 | size: Vector2 = (1,1) | 1 | 1.2.2 |
| FR-006 | difficulty: int = 1 | 1 | 1.2.2 |
| FR-007 | loot_bias: Currency = GOLD | 1 | 1.2.2 |
| FR-008 | is_cleared: bool = false | 1 | 1.2.2 |
| FR-009 | metadata: Dictionary = {} | 1 | 1.2.2 |
| FR-010 | RoomData.to_dict() | 1 | 1.2.4 |
| FR-011 | RoomData.from_dict() | 1 | 1.2.5 |
| FR-012 | is_combat() → bool | 1 | 1.2.3 |
| FR-013 | is_boss() → bool | 1 | 1.2.3 |
| FR-014 | is_rest() → bool | 1 | 1.2.3 |
| FR-015 | DungeonData class_name + extends RefCounted | 2 | 2.2.1 |
| FR-016 | seed_id: String = "" | 2 | 2.2.2 |
| FR-017 | rooms: Array[RoomData] = [] | 2 | 2.2.2 |
| FR-018 | edges: Array[Vector2i] = [] | 2 | 2.2.2 |
| FR-019 | entry_room_index: int = 0 | 2 | 2.2.2 |
| FR-020 | boss_room_index: int = -1 | 2 | 2.2.2 |
| FR-021 | element: Element = NONE | 2 | 2.2.2 |
| FR-022 | difficulty: int = 1 | 2 | 2.2.2 |
| FR-023 | get_adjacent() returns connected rooms | 3 | 3.2.1 |
| FR-024 | get_adjacent() returns [] for out-of-bounds | 3 | 3.2.1 |
| FR-025 | get_path_to_boss() BFS shortest path | 3 | 3.2.2 |
| FR-026 | get_path_to_boss() returns [] if no boss | 3 | 3.2.2 |
| FR-027 | get_path_to_boss() returns [] if unreachable | 3 | 3.2.2 |
| FR-028 | get_uncleared_rooms() | 3 | 3.2.3 |
| FR-029 | is_fully_cleared() | 3 | 3.2.4 |
| FR-030 | get_room() with null for out-of-bounds | 2 | 2.2.3 |
| FR-031 | get_room_count() | 2 | 2.2.4 |
| FR-032 | get_edge_count() | 2 | 2.2.5 |
| FR-033 | has_boss_room() | 2 | 2.2.6 |
| FR-034 | validate() — rooms.size() >= 1 | 4 | 4.2.1 |
| FR-035 | validate() — entry_room_index valid | 4 | 4.2.1 |
| FR-036 | validate() — boss_room_index valid or -1 | 4 | 4.2.1 |
| FR-037 | validate() — edge indices valid | 4 | 4.2.1 |
| FR-038 | validate() — canonical edge ordering | 4 | 4.2.1 |
| FR-039 | validate() — no duplicate edges | 4 | 4.2.1 |
| FR-040 | validate() — no self-loops | 4 | 4.2.1 |
| FR-041 | validate() — graph connected via BFS | 4 | 4.2.1 |
| FR-042 | validate() — boss reachable if exists | 4 | 4.2.1 |
| FR-043 | DungeonData.to_dict() | 5 | 5.2.1 |
| FR-044 | DungeonData.from_dict() | 5 | 5.2.2 |
| FR-045 | Round-trip stability | 5 | 5.2.1, 5.2.2 |
| FR-046 | from_dict() handles missing keys | 5 | 5.2.2 |

### Acceptance Criteria → Validation Gates

| AC | Description | Phase | Verification |
|----|-------------|-------|--------------|
| AC-001 | RoomData default index == 0 | 1 | Unit test |
| AC-002 | RoomData default type == COMBAT | 1 | Unit test |
| AC-003 | RoomData default position == ZERO | 1 | Unit test |
| AC-004 | RoomData default size == (1,1) | 1 | Unit test |
| AC-005 | RoomData default difficulty == 1 | 1 | Unit test |
| AC-006 | RoomData default loot_bias == GOLD | 1 | Unit test |
| AC-007 | RoomData default is_cleared == false | 1 | Unit test |
| AC-008 | RoomData default metadata == {} | 1 | Unit test |
| AC-009 | Property assignment works | 1 | Unit test |
| AC-010 | is_boss() true for BOSS type | 1 | Unit test |
| AC-011 | is_combat() true for COMBAT type | 1 | Unit test |
| AC-012 | is_rest() true for REST type | 1 | Unit test |
| AC-013 | is_boss() false for non-BOSS | 1 | Unit test |
| AC-014 | to_dict() has all keys | 1 | Unit test |
| AC-015 | to_dict() type is int | 1 | Unit test |
| AC-016 | to_dict() position is dict | 1 | Unit test |
| AC-017 | to_dict() size is dict | 1 | Unit test |
| AC-018 | to_dict() loot_bias is int | 1 | Unit test |
| AC-019 | Round-trip produces identical RoomData | 1 | Unit test |
| AC-020 | from_dict({}) returns defaults | 1 | Unit test |
| AC-021 | Round-trip preserves nested metadata | 1 | Unit test |
| AC-022 | DungeonData default seed_id == "" | 2 | Unit test |
| AC-023 | DungeonData default rooms empty | 2 | Unit test |
| AC-024 | DungeonData default edges empty | 2 | Unit test |
| AC-025 | DungeonData default entry == 0 | 2 | Unit test |
| AC-026 | DungeonData default boss == -1 | 2 | Unit test |
| AC-027 | DungeonData default element == NONE | 2 | Unit test |
| AC-028 | DungeonData default difficulty == 1 | 2 | Unit test |
| AC-029 | get_adjacent(0) on linear returns [1] | 3 | Unit test |
| AC-030 | get_adjacent(1) on linear returns [0,2] | 3 | Unit test |
| AC-031 | get_adjacent(2) on linear returns [1] | 3 | Unit test |
| AC-032 | get_adjacent(-1) returns [] | 3 | Unit test |
| AC-033 | get_adjacent(99) returns [] | 3 | Unit test |
| AC-034 | Path to boss on linear is [0,1,2] | 3 | Unit test |
| AC-035 | Branching path is shortest | 3 | Unit test |
| AC-036 | Path returns [] when no boss | 3 | Unit test |
| AC-037 | Uncleared returns all initially | 3 | Unit test |
| AC-038 | Uncleared returns [] when all cleared | 3 | Unit test |
| AC-039 | Uncleared returns only uncleared after partial | 3 | Unit test |
| AC-040 | is_fully_cleared false when uncleared | 3 | Unit test |
| AC-041 | is_fully_cleared true when all cleared | 3 | Unit test |
| AC-042 | get_room(0) returns first room | 2 | Unit test |
| AC-043 | get_room(-1) returns null | 2 | Unit test |
| AC-044 | get_room(size) returns null | 2 | Unit test |
| AC-045 | get_room_count() returns rooms.size() | 2 | Unit test |
| AC-046 | get_edge_count() returns edges.size() | 2 | Unit test |
| AC-047 | has_boss_room() true when valid index | 2 | Unit test |
| AC-048 | has_boss_room() false when -1 | 2 | Unit test |
| AC-049 | validate() false for empty rooms | 4 | Unit test |
| AC-050 | validate() false for OOB entry | 4 | Unit test |
| AC-051 | validate() false for OOB boss | 4 | Unit test |
| AC-052 | validate() false for OOB edge | 4 | Unit test |
| AC-053 | validate() false for non-canonical edge | 4 | Unit test |
| AC-054 | validate() false for duplicate edge | 4 | Unit test |
| AC-055 | validate() false for self-loop | 4 | Unit test |
| AC-056 | validate() false for disconnected | 4 | Unit test |
| AC-057 | validate() true for valid graph + boss | 4 | Unit test |
| AC-058 | validate() true for single room | 4 | Unit test |
| AC-059 | validate() true for no-boss dungeon | 4 | Unit test |
| AC-060 | to_dict() has all DungeonData keys | 5 | Unit test |
| AC-061 | to_dict() rooms is array of dicts | 5 | Unit test |
| AC-062 | to_dict() edges is [[a,b],...] | 5 | Unit test |
| AC-063 | to_dict() element is int | 5 | Unit test |
| AC-064 | Round-trip passes validate | 5 | Unit test |
| AC-065 | Round-trip preserves seed_id | 5 | Unit test |
| AC-066 | Round-trip preserves room properties | 5 | Unit test |
| AC-067 | Round-trip preserves edges | 5 | Unit test |
| AC-068 | Round-trip preserves entry/boss indices | 5 | Unit test |
| AC-069 | from_dict({}) returns default, no crash | 5 | Unit test |
| AC-070 | from_dict() caps rooms at 100 | 5 | Unit test |
| AC-071 | Single-room dungeon works | 6 | Unit test |
| AC-072 | Single-room boss dungeon works | 6 | Unit test |
| AC-073 | Fully-connected 4-room graph works | 6 | Unit test |
| AC-074 | Star topology path is direct | 6 | Unit test |
| AC-075 | 25-room stress test passes | 6 | Unit test |

---

*End of TASK-005 Implementation Plan*
