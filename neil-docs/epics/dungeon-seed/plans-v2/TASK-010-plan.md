# TASK-010: Procedural Dungeon Generator — Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-010-dungeon-generator.md`
> **GDD**: `neil-docs/epics/dungeon-seed/GDD-v2.md`
> **Status**: Planning
> **Created**: 2025-01-19
> **Repo**: `dev-agent-tool` (local — `C:\Users\wrstl\source\dev-agent-tool`)
> **Methodology**: TDD Red-Green-Refactor (mandatory for all phases)
> **Complexity**: 13 points (Complex) — Fibonacci
> **Estimated Phases**: 8
> **Estimated Checkboxes**: ~85

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents in this order:

1. **This file** (you're reading it) — the phased checklist of what to do, with status
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-010-dungeon-generator.md`** — the full technical spec with all FRs, ACs, tests
3. **`neil-docs/epics/dungeon-seed/GDD-v2.md`** — the Game Design Document for domain context (§5.2–§5.10 dungeon generation)
4. **`src/models/enums.gd`** — Enums (RoomType, Element, SeedRarity, SeedPhase, Currency) from TASK-003
5. **`src/models/game_config.gd`** — GameConfig constants from TASK-003
6. **`src/models/rng.gd`** — DeterministicRNG (seeded random) from TASK-002
7. **`src/models/dungeon_data.gd`** — DungeonData model from TASK-005
8. **`src/models/room_data.gd`** — RoomData model from TASK-005
9. **`src/models/seed_data.gd`** — SeedData model from TASK-004

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| Enum definitions | `src/models/enums.gd` | **EXISTS** — `class_name Enums`, has RoomType, Element, SeedRarity, SeedPhase, Currency |
| Game constants | `src/models/game_config.gd` | **EXISTS** — `class_name GameConfig`, has ROOM_DIFFICULTY_SCALE |
| RNG utility | `src/models/rng.gd` | **EXISTS** — `class_name DeterministicRNG`, provides seeded random |
| Dungeon model | `src/models/dungeon_data.gd` | **EXISTS** — `class_name DungeonData`, has rooms[], edges[], validate() |
| Room model | `src/models/room_data.gd` | **EXISTS** — `class_name RoomData`, has type, difficulty, loot_bias, is_cleared |
| Seed model | `src/models/seed_data.gd` | **EXISTS** — `class_name SeedData`, has rarity, element, phase, vigor, traits |
| Dungeon generator | `src/services/dungeon_generator.gd` | **NEW** — `class_name DungeonGeneratorService`, extends RefCounted |
| Unit tests | `tests/unit/test_dungeon_generator.gd` | **NEW** — GUT test suite for generator unit tests |
| Integration tests | `tests/integration/test_dungeon_generation_pipeline.gd` | **NEW** — GUT test suite for full pipeline tests |
| GUT addon | `addons/gut/` | **EXISTS** — GUT test framework pre-installed |
| v1 prototype code | `src/gdscript/dungeon/` | **DO NOT TOUCH** — legacy code, out of scope |

### Key Concepts (10-minute primer)

- **DungeonGeneratorService**: Pure-logic RefCounted service. Takes `SeedData` → produces `DungeonData`. No scene tree, no signals, no state.
- **Seven-stage pipeline**: Parse seed → Calc params → Gen graph → Assign types → Assign difficulty → Assign loot → Validate.
- **Deterministic guarantee**: Same seed input → same dungeon output, always. All RNG seeded from `seed_id + phase`.
- **Room graph**: Abstract node-and-edge graph. Not spatial tilemap. Rooms have abstract positions for UI layout only.
- **MST + shortcuts**: Minimum Spanning Tree (Prim's algorithm) ensures connectivity, then shortcut edges add branching paths.
- **Vigor-scaled params**: Room count, branching factor, difficulty all interpolate based on seed vigor (1–100).
- **Element bias**: FLAME → more COMBAT, FROST → more TRAP, etc. Multiplicative weight modifiers.
- **Critical path**: Shortest path from ENTRANCE (room 0) to BOSS (last room). Guaranteed reachable by validation.
- **SECRET rooms**: Only on branch paths, never on critical path. Reward exploration.
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
2. Existing models (`enums.gd`, `game_config.gd`, `rng.gd`, `dungeon_data.gd`, `room_data.gd`, `seed_data.gd`) are NOT modified
3. All existing tests in `tests/unit/` and `tests/integration/` pass (if any)
4. All new GUT tests pass green (once written)
5. No parse errors in Output console

---

## Current State Analysis

### What Exists Today

| Item | Status | Location |
|------|--------|----------|
| `project.godot` | ✅ Exists | Root — project config with autoloads |
| `src/models/enums.gd` | ✅ Exists | TASK-003 — `class_name Enums`, RoomType, Element, etc. |
| `src/models/game_config.gd` | ✅ Exists | TASK-003 — `class_name GameConfig`, ROOM_DIFFICULTY_SCALE |
| `src/models/rng.gd` | ✅ Exists | TASK-002 — `class_name DeterministicRNG`, seeded RNG |
| `src/models/dungeon_data.gd` | ✅ Exists | TASK-005 — `class_name DungeonData`, graph structure |
| `src/models/room_data.gd` | ✅ Exists | TASK-005 — `class_name RoomData`, room properties |
| `src/models/seed_data.gd` | ✅ Exists | TASK-004 — `class_name SeedData`, seed properties |
| `addons/gut/` | ✅ Exists | GUT test framework installed |
| `tests/unit/` | ✅ Exists | Contains existing test files |
| `tests/integration/` | ✅ Exists | Contains existing test files |
| `src/gdscript/dungeon/` | ✅ Exists | v1 prototype (DO NOT TOUCH) |

### What's Missing (Gap Analysis)

| Item | Status | Required By |
|------|--------|-------------|
| `src/services/dungeon_generator.gd` | ❌ Missing | All FRs |
| `tests/unit/test_dungeon_generator.gd` | ❌ Missing | All unit tests |
| `tests/integration/test_dungeon_generation_pipeline.gd` | ❌ Missing | Integration tests |

### What Must NOT Change

- `src/models/enums.gd` — TASK-003 output, provides RoomType, Element, SeedRarity, etc.
- `src/models/game_config.gd` — TASK-003 output, provides ROOM_DIFFICULTY_SCALE
- `src/models/rng.gd` — TASK-002 output, provides DeterministicRNG
- `src/models/dungeon_data.gd` — TASK-005 output, dungeon graph model
- `src/models/room_data.gd` — TASK-005 output, room data model
- `src/models/seed_data.gd` — TASK-004 output, seed data model
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
func test_generate_from_params_minimal_3_rooms() -> void:

# Determinism
func test_generate_deterministic_same_seed_identical_output() -> void:

# Validation
func test_generate_validates_boss_reachable() -> void:

# Edge cases
func test_generate_vigor_1_produces_minimal_dungeon() -> void:

# Element bias
func test_generate_flame_element_increases_combat_weight() -> void:
```

### Test Structure (GUT)

Every test follows Arrange-Act-Assert:
```gdscript
func test_method_scenario_expected() -> void:
    # Arrange — create instance and test data
    var generator := DungeonGeneratorService.new()
    var rng := DeterministicRNG.new()
    rng.seed_string("test-seed")
    
    # Act — execute the method
    var dungeon: DungeonData = generator.generate_from_params(3, 0.0, Enums.Element.TERRA, 1, {}, rng)
    
    # Assert — verify the outcome
    assert_eq(dungeon.get_room_count(), 3)
    assert_eq(dungeon.rooms[0].type, Enums.RoomType.COMBAT)
    assert_eq(dungeon.rooms[2].type, Enums.RoomType.BOSS)
    assert_true(dungeon.validate())
```

### Enterprise Coverage Standards

Every public method must have tests covering:
- ✅ Happy path (normal input → expected output)
- ✅ Edge cases (minimal/maximal vigor, phase=SPORE, phase=BLOOM)
- ✅ Determinism (same seed → same output)
- ✅ Validation (critical path reachable, no orphan rooms)
- ✅ Element bias (FLAME vs FROST vs TERRA room type distribution)
- ✅ Trait modulation (room_variety, loot_bias, hazard_frequency)

---

## 🔴 CRITICAL GODOT 4.6.1 RULES

**MUST follow these rules to avoid parse errors and test failures:**

1. **NO `class_name` on autoload scripts** — causes parse error. Models use `class_name`, autoloads do NOT.
2. **PowerShell `Set-Content` strips tabs** — ALWAYS use `edit` or `create` tool for GDScript files, NEVER `Set-Content`.
3. **GUT requires `--import` before first test run** — initial test run must include `--import` flag.
4. **GUT auto-tracks `push_error()`** — use `assert_push_error_count()` for expected errors.
5. **Tests must use `preload()` for class_name resolution** — `preload("res://src/models/enums.gd")` ensures Enums is available.
6. **GameConfig and Enums use class_name (NOT autoloads)** — access directly: `Enums.RoomType.COMBAT`, `GameConfig.ROOM_DIFFICULTY_SCALE[room_type]`.

---

## Phase 0: Pre-Flight & Dependency Verification

> **Ticket References**: FR-001 (prerequisites)
> **AC References**: AC-001 through AC-010 (structural prerequisites)
> **Estimated Items**: 8
> **Dependencies**: TASK-002, TASK-003, TASK-004, TASK-005 complete
> **Validation Gate**: All upstream dependencies verified, services directory ready

This phase verifies that all upstream dependencies are in place and the repository is ready for implementation.

### 0.1 Verify Upstream Task Outputs

- [ ] **0.1.1** Verify `src/models/enums.gd` exists and declares `class_name Enums`
  - _Ticket ref: Assumption #1_
  - _File: `src/models/enums.gd`_
  - _Check: `Enums.RoomType` has COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS_
  - _Check: `Enums.Element` has TERRA, FLAME, FROST, ARCANE, SHADOW, NONE_
  - _Check: `Enums.SeedRarity` has all 5 tiers_
  - _Check: `Enums.SeedPhase` has SPORE, SPROUT, BUD, BLOOM_
  - _Check: `Enums.Currency` has GOLD, ESSENCE, FRAGMENTS, ARTIFACTS_

- [ ] **0.1.2** Verify `src/models/game_config.gd` exists and declares `class_name GameConfig`
  - _Ticket ref: Assumption #1_
  - _File: `src/models/game_config.gd`_
  - _Check: `GameConfig.ROOM_DIFFICULTY_SCALE` has entries for all RoomType values_

- [ ] **0.1.3** Verify `src/models/rng.gd` exists and declares `class_name DeterministicRNG`
  - _Ticket ref: TASK-002 dependency_
  - _File: `src/models/rng.gd`_
  - _Check: Has methods `seed_string()`, `randf()`, `randi()`, `randi_range()`, `shuffle()`, `pick()`, `weighted_pick()`_

- [ ] **0.1.4** Verify `src/models/dungeon_data.gd` exists and declares `class_name DungeonData`
  - _Ticket ref: TASK-005 dependency_
  - _File: `src/models/dungeon_data.gd`_
  - _Check: Has properties `rooms: Array[RoomData]`, `edges: Array[Vector2i]`, `entry_room_index`, `boss_room_index`_
  - _Check: Has methods `validate()`, `get_adjacent()`, `get_path_to_boss()`_

- [ ] **0.1.5** Verify `src/models/room_data.gd` exists and declares `class_name RoomData`
  - _Ticket ref: TASK-005 dependency_
  - _File: `src/models/room_data.gd`_
  - _Check: Has properties `type: Enums.RoomType`, `difficulty: int`, `loot_bias: Enums.Currency`, `is_cleared: bool`_

- [ ] **0.1.6** Verify `src/models/seed_data.gd` exists and declares `class_name SeedData`
  - _Ticket ref: TASK-004 dependency_
  - _File: `src/models/seed_data.gd`_
  - _Check: Has properties `id`, `rarity`, `element`, `phase`, `vigor`, `dungeon_traits`_

### 0.2 Verify No Conflicts

- [ ] **0.2.1** Verify `src/services/` directory exists or create it
  - _Directory: `src/services/`_

- [ ] **0.2.2** Verify `src/services/dungeon_generator.gd` does NOT already exist (no file collision)
  - _File: `src/services/dungeon_generator.gd`_

- [ ] **0.2.3** Verify no existing `class_name DungeonGeneratorService` in the codebase

- [ ] **0.2.4** Verify `tests/unit/test_dungeon_generator.gd` does NOT already exist

- [ ] **0.2.5** Verify `tests/integration/test_dungeon_generation_pipeline.gd` does NOT already exist

### Phase 0 Validation Gate

- [ ] **0.V.1** All upstream dependencies verified present and contain expected APIs
- [ ] **0.V.2** No file conflicts detected
- [ ] **0.V.3** `src/services/` directory exists
- [ ] **0.V.4** Existing tests in `tests/` pass (regression baseline)
- [ ] **0.V.5** Commit: `"Phase 0: Verify TASK-010 dependencies — all upstream models present"`

---

## Phase 1: Service Skeleton & Parameter Calculation (TDD)

> **Ticket References**: FR-001 through FR-020, FR-100 through FR-105
> **AC References**: AC-001 through AC-015
> **Estimated Items**: 12
> **Dependencies**: Phase 0 complete
> **Validation Gate**: `DungeonGeneratorService` class exists, parameter calculation tests pass

### 1.1 Write Parameter Calculation Tests (RED)

- [ ] **1.1.1** Create `tests/unit/test_dungeon_generator.gd` with test class and helpers
  - _Ticket ref: Section 14 — Unit Tests_
  - _File: `tests/unit/test_dungeon_generator.gd`_
  - _Content: `extends GutTest`, helper preloads, test setup/teardown_
  - _Tests: `test_calc_room_count_spore_common`, `test_calc_room_count_bloom_legendary`, `test_calc_branching_factor_vigor_1`, `test_calc_branching_factor_vigor_100`, `test_calc_difficulty_vigor_50`, `test_calc_difficulty_vigor_100`_
  - _TDD: RED — tests reference `DungeonGeneratorService` which does not exist yet_

### 1.2 Implement Service Skeleton (GREEN)

- [ ] **1.2.1** Create `src/services/dungeon_generator.gd` with class declaration
  - _Ticket ref: FR-001, AC-001_
  - _File: `src/services/dungeon_generator.gd`_
  - _Content: `class_name DungeonGeneratorService` + `extends RefCounted` + class doc comment_

- [ ] **1.2.2** Add constants for vigor scaling tables
  - _Ticket ref: FR-010 through FR-020_
  - _Constants: `ROOM_COUNT_BASE_BY_PHASE`, `ROOM_COUNT_BONUS_BY_RARITY`, `BRANCHING_FACTOR_BY_VIGOR`, `DIFFICULTY_BY_VIGOR`, `ELEMENT_BIASES`_

- [ ] **1.2.3** Add `_calc_room_count(phase: Enums.SeedPhase, rarity: Enums.SeedRarity, vigor: int) -> int`
  - _Ticket ref: FR-010, FR-011, AC-010_
  - _Formula: base[phase] + bonus[rarity] + vigor_modifier_

- [ ] **1.2.4** Add `_calc_branching_factor(vigor: int) -> float`
  - _Ticket ref: FR-012, FR-013, AC-011_
  - _Formula: linear interpolation from vigor 1→100 maps to 0.0→0.5_

- [ ] **1.2.5** Add `_calc_base_difficulty(vigor: int, element: Enums.Element) -> float`
  - _Ticket ref: FR-014, FR-015, AC-012_
  - _Formula: (vigor / 100.0) × element_multiplier_

- [ ] **1.2.6** Add `generate_from_params(room_count, branching, element, difficulty, traits, rng) -> DungeonData` stub
  - _Ticket ref: FR-100, AC-002_
  - _Returns: Empty DungeonData for now (filled in Phase 2)_

### Phase 1 Validation Gate

- [ ] **1.V.1** `src/services/dungeon_generator.gd` exists and is parseable GDScript
- [ ] **1.V.2** File extends `RefCounted` and declares `class_name DungeonGeneratorService`
- [ ] **1.V.3** All calculation methods have `##` doc comments and type hints
- [ ] **1.V.4** All 6 parameter calculation tests pass green
- [ ] **1.V.5** No Node, SceneTree, or signal declarations in file (NFR-007)
- [ ] **1.V.6** `generate_from_params()` stub exists and returns DungeonData
- [ ] **1.V.7** Commit: `"Phase 1: Add DungeonGeneratorService skeleton & parameter calculation — 6 tests"`

---

## Phase 2: Room Graph Generation — MST + Shortcuts (TDD)

> **Ticket References**: FR-030 through FR-050
> **AC References**: AC-020 through AC-030
> **Estimated Items**: 14
> **Dependencies**: Phase 1 complete
> **Validation Gate**: Graph generation tests pass, MST connectivity verified

### 2.1 Write Graph Generation Tests (RED)

- [ ] **2.1.1** Add graph generation test section to `tests/unit/test_dungeon_generator.gd`
  - _Tests: `test_place_rooms_on_grid`, `test_build_mst_prim_3_rooms`, `test_build_mst_prim_10_rooms`, `test_add_shortcuts_zero_branching`, `test_add_shortcuts_half_branching`, `test_graph_connectivity_all_rooms_reachable`, `test_graph_no_self_loops`, `test_graph_canonical_edge_ordering`_
  - _TDD: RED — tests call graph generation methods that don't exist yet_

### 2.2 Implement Room Placement

- [ ] **2.2.1** Add `_place_rooms_on_grid(room_count: int, rng: DeterministicRNG) -> Array[Vector2]`
  - _Ticket ref: FR-030, FR-031, AC-020_
  - _Algorithm: Abstract 2D grid, place rooms at random non-overlapping cells_

### 2.3 Implement MST Construction

- [ ] **2.3.1** Add `_build_mst_prim(positions: Array[Vector2], rng: DeterministicRNG) -> Array[Vector2i]`
  - _Ticket ref: FR-032, FR-033, AC-021, AC-022_
  - _Algorithm: Prim's MST with Euclidean distance weights, deterministic tie-breaking_
  - _Returns: Canonical edge pairs (a < b)_

- [ ] **2.3.2** Add helper `_euclidean_distance(a: Vector2, b: Vector2) -> float`
  - _Used by MST weight calculation_

### 2.4 Implement Shortcut Edges

- [ ] **2.4.1** Add `_add_shortcut_edges(mst_edges: Array[Vector2i], positions: Array[Vector2], branching_factor: float, rng: DeterministicRNG) -> Array[Vector2i]`
  - _Ticket ref: FR-034, FR-035, AC-023, AC-024_
  - _Algorithm: Randomly add edges not in MST, up to max_shortcuts = floor(branching_factor × room_count)_
  - _Returns: Combined MST + shortcut edges_

- [ ] **2.4.2** Add helper `_edge_exists(edges: Array[Vector2i], a: int, b: int) -> bool`
  - _Check if edge already exists (either direction)_

- [ ] **2.4.3** Add helper `_canonical_edge(a: int, b: int) -> Vector2i`
  - _Returns Vector2i(min(a, b), max(a, b))_

### 2.5 Update `generate_from_params()` to Build Graph

- [ ] **2.5.1** Update `generate_from_params()` to call graph generation methods
  - _Ticket ref: FR-040, AC-025_
  - _Steps: Place rooms → Build MST → Add shortcuts → Populate DungeonData.rooms and edges_

- [ ] **2.5.2** Set `entry_room_index = 0` and `boss_room_index = room_count - 1`
  - _Ticket ref: FR-041, AC-026_

### Phase 2 Validation Gate

- [ ] **2.V.1** All graph generation helper methods have `##` doc comments
- [ ] **2.V.2** All 8 graph generation tests pass green
- [ ] **2.V.3** MST guarantees connectivity (BFS from entry reaches all rooms)
- [ ] **2.V.4** Shortcut edges are capped correctly by branching_factor
- [ ] **2.V.5** All edges are canonical (a < b)
- [ ] **2.V.6** No self-loops (edge.x != edge.y)
- [ ] **2.V.7** Commit: `"Phase 2: Implement graph generation (MST + shortcuts) — 8 tests"`

---

## Phase 3: Room Type Assignment (TDD)

> **Ticket References**: FR-060 through FR-075
> **AC References**: AC-040 through AC-052
> **Estimated Items**: 11
> **Dependencies**: Phase 2 complete
> **Validation Gate**: Room type assignment tests pass, element bias verified

### 3.1 Write Room Type Assignment Tests (RED)

- [ ] **3.1.1** Add room type assignment test section to `tests/unit/test_dungeon_generator.gd`
  - _Tests: `test_assign_types_entry_room_index_0`, `test_assign_types_boss_room_last_index`, `test_assign_types_no_entrance_or_boss_in_middle`, `test_assign_types_flame_element_combat_bias`, `test_assign_types_frost_element_trap_bias`, `test_assign_types_room_variety_high`, `test_assign_types_room_variety_low`, `test_assign_types_secret_rooms_only_on_branches`_
  - _TDD: RED — tests call room type assignment methods that don't exist yet_

### 3.2 Implement Room Type Assignment

- [ ] **3.2.1** Add `_assign_room_types(dungeon: DungeonData, element: Enums.Element, traits: Dictionary, rng: DeterministicRNG) -> void`
  - _Ticket ref: FR-060, AC-040_
  - _Steps: Set entry room type → Assign middle room types → Set boss room type_

- [ ] **3.2.2** Add `_get_room_type_weights(element: Enums.Element, room_variety: float) -> Dictionary`
  - _Ticket ref: FR-061, FR-062, AC-041, AC-042_
  - _Returns: `{ Enums.RoomType: float weight }`_
  - _Element bias multipliers: FLAME increases COMBAT, FROST increases TRAP, etc._
  - _Room variety modulates weight spread_

- [ ] **3.2.3** Add `_is_on_critical_path(room_index: int, dungeon: DungeonData) -> bool`
  - _Ticket ref: FR-070, AC-048_
  - _Uses DungeonData.get_path_to_boss() to check if room_index is on shortest path_

- [ ] **3.2.4** Add `_is_branch_room(room_index: int, dungeon: DungeonData) -> bool`
  - _Ticket ref: FR-071, AC-049_
  - _Returns: true if room has degree > 2 OR is a leaf node not on critical path_

- [ ] **3.2.5** Update `generate_from_params()` to call `_assign_room_types()`
  - _After graph generation, before difficulty assignment_

### Phase 3 Validation Gate

- [ ] **3.V.1** All room type assignment methods have `##` doc comments
- [ ] **3.V.2** All 8 room type assignment tests pass green
- [ ] **3.V.3** Entry room is always COMBAT, boss room is always BOSS
- [ ] **3.V.4** Element bias correctly shifts room type probabilities
- [ ] **3.V.5** SECRET rooms only appear on branch paths, never on critical path
- [ ] **3.V.6** Room variety trait modulates type distribution
- [ ] **3.V.7** Commit: `"Phase 3: Implement room type assignment with element bias — 8 tests"`

---

## Phase 4: Difficulty Assignment (TDD)

> **Ticket References**: FR-080 through FR-095
> **AC References**: AC-060 through AC-070
> **Estimated Items**: 10
> **Dependencies**: Phase 3 complete
> **Validation Gate**: Difficulty assignment tests pass, scaling verified

### 4.1 Write Difficulty Assignment Tests (RED)

- [ ] **4.1.1** Add difficulty assignment test section to `tests/unit/test_dungeon_generator.gd`
  - _Tests: `test_assign_difficulty_vigor_50_baseline`, `test_assign_difficulty_vigor_100_max`, `test_assign_difficulty_boss_room_highest`, `test_assign_difficulty_rest_room_zero`, `test_assign_difficulty_depth_scaling`, `test_assign_difficulty_element_multiplier`_
  - _TDD: RED — tests call difficulty assignment methods that don't exist yet_

### 4.2 Implement Difficulty Assignment

- [ ] **4.2.1** Add `_assign_difficulty(dungeon: DungeonData, base_difficulty: float, element: Enums.Element, rng: DeterministicRNG) -> void`
  - _Ticket ref: FR-080, AC-060_
  - _Steps: Calculate per-room difficulty based on depth, room type, element multiplier_

- [ ] **4.2.2** Add `_get_room_depth(room_index: int, dungeon: DungeonData) -> int`
  - _Ticket ref: FR-081, AC-061_
  - _BFS from entry_room_index, returns depth (0 = entry, N = boss)_

- [ ] **4.2.3** Add `_get_element_difficulty_multiplier(element: Enums.Element) -> float`
  - _Ticket ref: FR-082, AC-062_
  - _Returns: SHADOW=1.3, ARCANE=1.2, FLAME=1.15, FROST=1.1, TERRA=1.0_

- [ ] **4.2.4** Add `_get_room_type_difficulty_modifier(room_type: Enums.RoomType) -> float`
  - _Ticket ref: FR-083, AC-063_
  - _Returns: GameConfig.ROOM_DIFFICULTY_SCALE[room_type]_

- [ ] **4.2.5** Update `generate_from_params()` to call `_assign_difficulty()`
  - _After room type assignment, before loot bias assignment_

### Phase 4 Validation Gate

- [ ] **4.V.1** All difficulty assignment methods have `##` doc comments
- [ ] **4.V.2** All 6 difficulty assignment tests pass green
- [ ] **4.V.3** Boss room has highest difficulty in dungeon
- [ ] **4.V.4** REST rooms have difficulty = 0
- [ ] **4.V.5** Difficulty scales with depth along critical path
- [ ] **4.V.6** Element multiplier correctly applied
- [ ] **4.V.7** Commit: `"Phase 4: Implement difficulty assignment with depth scaling — 6 tests"`

---

## Phase 5: Loot Bias Assignment (TDD)

> **Ticket References**: FR-110 through FR-125
> **AC References**: AC-080 through AC-090
> **Estimated Items**: 9
> **Dependencies**: Phase 4 complete
> **Validation Gate**: Loot bias assignment tests pass, currency weighting verified

### 5.1 Write Loot Bias Tests (RED)

- [ ] **5.1.1** Add loot bias test section to `tests/unit/test_dungeon_generator.gd`
  - _Tests: `test_assign_loot_bias_treasure_room_gold`, `test_assign_loot_bias_boss_room_artifacts`, `test_assign_loot_bias_trap_room_fragments`, `test_assign_loot_bias_rest_room_none`, `test_assign_loot_bias_seed_loot_bias_trait`_
  - _TDD: RED — tests call loot bias assignment methods that don't exist yet_

### 5.2 Implement Loot Bias Assignment

- [ ] **5.2.1** Add `_assign_loot_bias(dungeon: DungeonData, traits: Dictionary) -> void`
  - _Ticket ref: FR-110, AC-080_
  - _Steps: For each room, assign loot_bias based on room type + seed loot_bias trait_

- [ ] **5.2.2** Add `_get_default_loot_bias(room_type: Enums.RoomType) -> Enums.Currency`
  - _Ticket ref: FR-111, AC-081_
  - _Returns: TREASURE→GOLD, BOSS→ARTIFACTS, TRAP→FRAGMENTS, REST→none, COMBAT→GOLD_

- [ ] **5.2.3** Update `generate_from_params()` to call `_assign_loot_bias()`
  - _After difficulty assignment, before validation_

### Phase 5 Validation Gate

- [ ] **5.V.1** All loot bias methods have `##` doc comments
- [ ] **5.V.2** All 5 loot bias tests pass green
- [ ] **5.V.3** TREASURE rooms bias toward GOLD
- [ ] **5.V.4** BOSS rooms bias toward ARTIFACTS
- [ ] **5.V.5** Seed `loot_bias` trait correctly shifts room biases
- [ ] **5.V.6** Commit: `"Phase 5: Implement loot bias assignment — 5 tests"`

---

## Phase 6: Validation & `generate()` Public API (TDD)

> **Ticket References**: FR-130 through FR-145, FR-150
> **AC References**: AC-100 through AC-115
> **Estimated Items**: 12
> **Dependencies**: Phase 5 complete
> **Validation Gate**: Validation tests pass, `generate()` API works end-to-end

### 6.1 Write Validation Tests (RED)

- [ ] **6.1.1** Add validation test section to `tests/unit/test_dungeon_generator.gd`
  - _Tests: `test_validate_boss_reachable`, `test_validate_all_rooms_connected`, `test_validate_no_orphan_rooms`, `test_validate_canonical_edges`, `test_validate_no_self_loops`, `test_validate_entry_boss_indices_valid`_
  - _TDD: RED — tests call validation methods that don't exist yet_

### 6.2 Implement Validation

- [ ] **6.2.1** Add `_validate_dungeon(dungeon: DungeonData) -> bool`
  - _Ticket ref: FR-130, AC-100_
  - _Calls DungeonData.validate() and checks custom invariants_

- [ ] **6.2.2** Update `generate_from_params()` to call `_validate_dungeon()` before returning
  - _If validation fails, push_error() and return empty DungeonData_

### 6.3 Write `generate()` API Tests (RED)

- [ ] **6.3.1** Add `generate()` API test section to `tests/unit/test_dungeon_generator.gd`
  - _Tests: `test_generate_from_seed_data_common_spore`, `test_generate_from_seed_data_legendary_bloom`, `test_generate_deterministic_same_seed`, `test_generate_deterministic_different_seeds`, `test_generate_sets_seed_id_element_difficulty`_
  - _TDD: RED — tests call `generate(seed_data)` which doesn't exist yet_

### 6.4 Implement `generate()` Public API

- [ ] **6.4.1** Add `generate(seed_data: SeedData) -> DungeonData`
  - _Ticket ref: FR-150, AC-110_
  - _Steps: Create RNG seeded from seed_id + phase → Extract params from seed_data → Call generate_from_params()_

- [ ] **6.4.2** Ensure RNG seeding uses `seed_id + "_" + phase_name`
  - _Ticket ref: FR-151, AC-111_
  - _Guarantees different phases produce different dungeons_

### Phase 6 Validation Gate

- [ ] **6.V.1** All validation methods have `##` doc comments
- [ ] **6.V.2** All 11 validation + API tests pass green
- [ ] **6.V.3** `generate()` API produces valid DungeonData from SeedData
- [ ] **6.V.4** Determinism verified: same seed → same dungeon
- [ ] **6.V.5** Boss room is always reachable from entry
- [ ] **6.V.6** All rooms are connected (no orphans)
- [ ] **6.V.7** Commit: `"Phase 6: Implement validation & generate() public API — 11 tests"`

---

## Phase 7: Integration Tests & Edge Cases (TDD)

> **Ticket References**: All FRs, all ACs
> **AC References**: AC-120 through AC-130
> **Estimated Items**: 10
> **Dependencies**: Phase 6 complete
> **Validation Gate**: Integration tests pass, edge cases covered

### 7.1 Write Integration Tests (RED)

- [ ] **7.1.1** Create `tests/integration/test_dungeon_generation_pipeline.gd`
  - _Ticket ref: Section 14 — Integration Tests_
  - _File: `tests/integration/test_dungeon_generation_pipeline.gd`_
  - _Tests: `test_full_pipeline_minimal_dungeon`, `test_full_pipeline_large_dungeon`, `test_full_pipeline_all_elements`, `test_full_pipeline_all_phases`, `test_full_pipeline_1000_seeds_all_valid`_
  - _TDD: RED — full pipeline tests for real-world scenarios_

### 7.2 Write Edge Case Tests (RED)

- [ ] **7.2.1** Add edge case test section to `tests/unit/test_dungeon_generator.gd`
  - _Tests: `test_generate_vigor_1_minimal`, `test_generate_vigor_100_maximal`, `test_generate_phase_spore_3_rooms`, `test_generate_phase_bloom_28_rooms`, `test_generate_rarity_common_no_bonus_rooms`, `test_generate_rarity_legendary_max_bonus_rooms`_

### 7.3 Fix Any Failures & Refactor

- [ ] **7.3.1** Run integration tests and fix any failures
  - _Iterate on implementation until all integration tests pass_

- [ ] **7.3.2** Run edge case tests and fix any failures
  - _Handle vigor=1, vigor=100, phase=SPORE, phase=BLOOM, rarity=COMMON, rarity=LEGENDARY_

- [ ] **7.3.3** Refactor for clarity while keeping tests green
  - _Extract magic numbers to constants_
  - _Add inline comments for complex algorithms_
  - _Improve method names if needed_

### Phase 7 Validation Gate

- [ ] **7.V.1** All 5 integration tests pass green
- [ ] **7.V.2** All 6 edge case tests pass green
- [ ] **7.V.3** 1000 random seeds all produce valid dungeons
- [ ] **7.V.4** Minimal dungeon (3 rooms, vigor=1, phase=SPORE) validates
- [ ] **7.V.5** Maximal dungeon (28 rooms, vigor=100, phase=BLOOM, rarity=LEGENDARY) validates
- [ ] **7.V.6** All tests run in < 5 seconds (performance sanity check)
- [ ] **7.V.7** Commit: `"Phase 7: Add integration & edge case tests — all tests green"`

---

## Phase 8: Documentation, Cleanup, & Final Validation

> **Ticket References**: All FRs, all ACs, all NFRs
> **AC References**: AC-140 through AC-150
> **Estimated Items**: 8
> **Dependencies**: Phase 7 complete
> **Validation Gate**: All tests pass, code documented, no warnings

### 8.1 Code Documentation

- [ ] **8.1.1** Add `##` doc comments to all public methods in `dungeon_generator.gd`
  - _Ticket ref: NFR-010_
  - _Format: Brief description, @param tags, @return tag, example usage_

- [ ] **8.1.2** Add `##` doc comments to all private methods
  - _Explain algorithm, preconditions, postconditions_

- [ ] **8.1.3** Add class-level `##` doc comment with usage example
  - _Show how to instantiate and call `generate()`_

### 8.2 Code Quality Checks

- [ ] **8.2.1** Remove all debug `print()` statements
  - _Replace with appropriate `push_warning()` or `push_error()` where needed_

- [ ] **8.2.2** Ensure all methods have type hints on parameters and return types
  - _Ticket ref: NFR-011_

- [ ] **8.2.3** Run all tests and verify 0 errors, 0 warnings in Output console
  - _Check for `push_error()` or `push_warning()` calls that shouldn't be there_

- [ ] **8.2.4** Verify no use of global RNG (`randi()`, `randf()`) — all RNG goes through DeterministicRNG
  - _Search for `randi`, `randf`, `RandomNumberGenerator` in service file_

### 8.3 Final Regression & Handoff

- [ ] **8.3.1** Run full test suite: `tests/unit/` + `tests/integration/`
  - _All tests must pass green_

- [ ] **8.3.2** Verify no changes to upstream models (enums, game_config, rng, dungeon_data, room_data, seed_data)
  - _Git diff to confirm_

- [ ] **8.3.3** Open project in Godot editor and verify no parse errors
  - _Output console should be clean_

- [ ] **8.3.4** Manually instantiate `DungeonGeneratorService.new()` in editor console and call `generate()`
  - _Smoke test to confirm class is accessible_

### Phase 8 Validation Gate

- [ ] **8.V.1** All public and private methods have `##` doc comments
- [ ] **8.V.2** All methods have complete type hints
- [ ] **8.V.3** No debug prints, no warnings in console
- [ ] **8.V.4** All tests pass (unit + integration)
- [ ] **8.V.5** No modifications to upstream dependencies
- [ ] **8.V.6** Service instantiates cleanly in editor
- [ ] **8.V.7** Commit: `"Phase 8: Documentation & cleanup — TASK-010 complete"`

---

## Phase Dependency Graph

```
Phase 0 (Verify Dependencies) ──→ Phase 1 (Skeleton & Params) ──→ Phase 2 (Graph Generation)
                                                                         │
                                                                         ↓
Phase 3 (Room Types) ←──────────────────────────────────────────────────┘
      │
      ↓
Phase 4 (Difficulty) ──→ Phase 5 (Loot Bias) ──→ Phase 6 (Validation & API)
                                                         │
                                                         ↓
                                             Phase 7 (Integration Tests)
                                                         │
                                                         ↓
                                                Phase 8 (Documentation)
```

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 0 | Verify Dependencies | 8 | 0 | 0 | ⬜ Not Started |
| Phase 1 | Skeleton & Parameters | 12 | 0 | 6 | ⬜ Not Started |
| Phase 2 | Graph Generation | 14 | 0 | 8 | ⬜ Not Started |
| Phase 3 | Room Type Assignment | 11 | 0 | 8 | ⬜ Not Started |
| Phase 4 | Difficulty Assignment | 10 | 0 | 6 | ⬜ Not Started |
| Phase 5 | Loot Bias Assignment | 9 | 0 | 5 | ⬜ Not Started |
| Phase 6 | Validation & API | 12 | 0 | 11 | ⬜ Not Started |
| Phase 7 | Integration & Edge Cases | 10 | 0 | 11 | ⬜ Not Started |
| Phase 8 | Documentation & Cleanup | 8 | 0 | 0 | ⬜ Not Started |
| **Total** | | **94** | **0** | **55** | **⬜ Planning** |

---

## File Change Summary

### New Files
| File | Phase | Purpose |
|------|-------|---------|
| `src/services/dungeon_generator.gd` | 1 | DungeonGeneratorService class — main generation logic |
| `tests/unit/test_dungeon_generator.gd` | 1 | Unit tests for generator methods |
| `tests/integration/test_dungeon_generation_pipeline.gd` | 7 | Integration tests for full pipeline |

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
| 0 | `"Phase 0: Verify TASK-010 dependencies — all upstream models present"` | 0 |
| 1 | `"Phase 1: Add DungeonGeneratorService skeleton & parameter calculation — 6 tests"` | 6 |
| 2 | `"Phase 2: Implement graph generation (MST + shortcuts) — 8 tests"` | 14 |
| 3 | `"Phase 3: Implement room type assignment with element bias — 8 tests"` | 22 |
| 4 | `"Phase 4: Implement difficulty assignment with depth scaling — 6 tests"` | 28 |
| 5 | `"Phase 5: Implement loot bias assignment — 5 tests"` | 33 |
| 6 | `"Phase 6: Implement validation & generate() public API — 11 tests"` | 44 |
| 7 | `"Phase 7: Add integration & edge case tests — all tests green"` | 55 |
| 8 | `"Phase 8: Documentation & cleanup — TASK-010 complete"` | 55 |

---

## Deviations from Ticket

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| _(none yet)_ | — | — | — | — | — |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| MST tie-breaking non-deterministic | Medium | High | Use RNG for tie-breaking with explicit sort key | 2 |
| Shortcut edges create duplicate connections | Low | Medium | Check edge existence before adding | 2 |
| SECRET room placement fails on linear paths | Low | Medium | Fall back to COMBAT if no branches exist | 3 |
| Boss unreachable due to graph generation bug | Low | High | Validate boss reachability in every test | 6 |
| Vigor scaling formula produces negative difficulty | Low | Medium | Clamp all difficulty values to [0, 100] | 4 |
| Element bias weights sum to zero | Low | Medium | Validate weights > 0 before weighted_pick() | 3 |

---

## Handoff State (Initial)

### What's Complete
- _(none — task not started)_

### What's In Progress
- _(none)_

### What's Blocked
- _(none)_

### Next Steps
1. Begin Phase 0: Verify all upstream dependencies (TASK-002, TASK-003, TASK-004, TASK-005)
2. Create `src/services/` directory if it doesn't exist
3. Start Phase 1: Write parameter calculation tests (RED)
4. Implement DungeonGeneratorService skeleton (GREEN)

---

*Plan version: 1.0.0 | Created: 2025-01-19 | Task: TASK-010 | Complexity: 13 points*
