# Decomposition: Dungeon Seed — MVP Playable Loop

> **Decomposed by**: The Decomposer (the-decomposer)
> **Date**: 2026-07-28
> **Input**: GDD-v2.md (Dungeon Seed Game Design Document v0.1) + EPIC-TRACKER restart directive
> **Target Repo(s)**: C:\Users\wrstl\source\dev-agent-tool (Godot 4.5 project)
> **Total Tasks**: 22
> **Total Complexity**: 152 Fibonacci points
> **Waves**: 6
> **Critical Path**: 8 tasks (67 points)

---

## Epic Summary

Dungeon Seed is a hybrid RPG/idle/progression game where the player — a Seedwarden — plants magical seeds that sprout into procedurally generated dungeons, tends their growth through mutation strategies, dispatches adventurer parties to clear rooms and harvest loot, and reinvests rewards into stronger seeds and heroes. This decomposition targets the **MVP playable loop**: plant a seed → watch it grow → dispatch adventurers → resolve rooms → collect loot → reinvest → repeat. It replaces the v1 decomposition (12 tasks, 96 points) which was too coarse-grained and mixed design documents with implementation work.

**Key v2 changes from v1:**
- All "design document" tasks eliminated — design is embedded in each implementation task
- Existing untrusted code at `src/gdscript/` treated as reference only; each task produces clean, tested code
- Tasks are granular enough for 1–3 focused implementation sessions each
- Proper separation: data models → utilities → domain services → integration → UI
- Explicit seed maturation phases (Spore→Sprout→Bud→Bloom) from GDD now modeled
- Elemental affinity system included in MVP (5 elements)
- 4-currency economy (Gold, Essence, Fragments, Artifacts) from GDD now modeled
- Room-by-room expedition resolution (not just tick-to-completion)

---

## Task Registry

| # | Task ID | Task Name | Complexity | Dependencies | Wave | Critical Path? |
|---|---------|-----------|-----------|-------------|------|----------------|
| 1 | TASK-001 | Project bootstrap & autoload skeleton | 3 | None | 1 | ✅ |
| 2 | TASK-002 | Deterministic RNG wrapper | 3 | None | 1 | ❌ |
| 3 | TASK-003 | Enums, constants & data dictionary | 3 | None | 1 | ✅ |
| 4 | TASK-004 | Seed data model & maturation state machine | 8 | TASK-003 | 2 | ✅ |
| 5 | TASK-005 | Dungeon room graph data model | 5 | TASK-003 | 2 | ✅ |
| 6 | TASK-006 | Adventurer data model & class definitions | 5 | TASK-003 | 2 | ❌ |
| 7 | TASK-007 | Item, equipment & inventory data models | 5 | TASK-003 | 2 | ❌ |
| 8 | TASK-008 | Economy: 4-currency wallet & transaction ledger | 5 | TASK-003 | 2 | ❌ |
| 9 | TASK-009 | Save/load manager with versioned serialization | 8 | TASK-001 | 2 | ❌ |
| 10 | TASK-010 | Procedural dungeon generator (seed→room graph) | 13 | TASK-002, TASK-005 | 3 | ✅ |
| 11 | TASK-011 | Loot table engine & drop resolver | 8 | TASK-002, TASK-007 | 3 | ❌ |
| 12 | TASK-012 | Seed grove manager (plant, grow, mutate) | 8 | TASK-004, TASK-002 | 3 | ✅ |
| 13 | TASK-013 | Adventurer roster & party builder | 5 | TASK-006 | 3 | ❌ |
| 14 | TASK-014 | Equipment system (equip/unequip/stat calc) | 5 | TASK-006, TASK-007 | 3 | ❌ |
| 15 | TASK-015 | Room-by-room expedition resolver | 13 | TASK-010, TASK-006, TASK-011 | 4 | ✅ |
| 16 | TASK-016 | Expedition reward processor & XP distributor | 8 | TASK-015, TASK-008 | 5 | ✅ |
| 17 | TASK-017 | Core loop orchestrator (idle tick + active dispatch) | 13 | TASK-012, TASK-015, TASK-016, TASK-009 | 5 | ✅ |
| 18 | TASK-018 | Seed Grove UI screen | 8 | TASK-001, TASK-012 | 5 | ❌ |
| 19 | TASK-019 | Expedition dispatch & resolution UI | 8 | TASK-001, TASK-015 | 5 | ❌ |
| 20 | TASK-020 | Adventurer Hall & inventory UI | 8 | TASK-001, TASK-013, TASK-014 | 5 | ❌ |
| 21 | TASK-021 | Main menu, hub navigation & screen flow | 5 | TASK-018, TASK-019, TASK-020 | 6 | ❌ |
| 22 | TASK-022 | MVP integration test & end-to-end loop validation | 13 | TASK-017, TASK-021 | 6 | ✅ |

---

## Dependency Graph

```
WAVE 1 (Foundation — no dependencies)
┌───────────────────┐  ┌────────────────────┐  ┌────────────────────────────┐
│ TASK-001           │  │ TASK-002           │  │ TASK-003                   │
│ Project Bootstrap  │  │ Deterministic RNG  │  │ Enums & Data Dictionary    │
│ (3 pts)            │  │ (3 pts)            │  │ (3 pts)                    │
└─────┬─────────────┘  └──────┬─────────────┘  └──┬──────┬──────┬──────┬───┘
      │                       │                    │      │      │      │
      │                       │                    ▼      ▼      ▼      ▼
      │                       │  WAVE 2 (Data Models & Persistence)
      │                       │  ┌─────────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
      │                       │  │ TASK-004     │ │TASK-005 │ │TASK-006 │ │TASK-007 │
      │                       │  │ Seed Model   │ │Room Grph│ │Adventurr│ │Item/Inv │
      │                       │  │ (8 pts) ★    │ │(5 pts)★ │ │(5 pts)  │ │(5 pts)  │
      │                       │  └──────┬──────┘ └────┬────┘ └──┬──┬──┘ └──┬──────┘
      │                       │         │             │         │  │       │
      │     ┌─────────────┐   │  ┌──────┘   ┌────────┘    ┌────┘  │  ┌───┘
      │     │ TASK-008     │   │  │          │             │       │  │
      │     │ Economy      │   │  │          │             │       │  │
      │     │ (5 pts)      │   │  │          │             │       │  │
      │     └──────┬──────┘   │  │          │             │       │  │
      │            │          │  │          │             │       │  │
      ▼            │          ▼  ▼          ▼             ▼       │  ▼
┌──────────────┐   │  WAVE 3 (Domain Services)                   │
│ TASK-009     │   │  ┌─────────────┐ ┌──────────┐ ┌──────────┐  │ ┌──────────┐
│ Save/Load    │   │  │ TASK-010    │ │TASK-011  │ │TASK-012  │  │ │TASK-013  │
│ (8 pts)      │   │  │ Dungeon Gen │ │Loot Engn │ │Seed Grove│  │ │Roster/   │
└──────┬──────┘   │  │ (13 pts) ★  │ │(8 pts)   │ │(8 pts) ★ │  │ │Party     │
       │          │  └──────┬──────┘ └────┬─────┘ └──────┬───┘  │ │(5 pts)   │
       │          │         │             │              │       │ └────┬─────┘
       │          │         │             │              │       │      │
       │          │  ┌──────────┐         │              │       │ ┌────┴─────┐
       │          │  │          │         │              │       │ │TASK-014  │
       │          │  │          ▼         ▼              │       │ │Equipment │
       │          │  │   WAVE 4                          │       │ │(5 pts)   │
       │          │  │   ┌──────────────────────┐        │       │ └────┬─────┘
       │          │  │   │ TASK-015             │        │       │      │
       │          │  │   │ Room-by-Room Resolver│        │       │      │
       │          │  │   │ (13 pts) ★           │        │       │      │
       │          │  │   └──────────┬───────────┘        │       │      │
       │          │  │              │                     │       │      │
       │          │  │              ▼                     │       │      │
       │          │  │   WAVE 5 (Integration & UI)       │       │      │
       │          │  │   ┌──────────────┐                │       │      │
       │          │  │   │ TASK-016     │                │       │      │
       │          │  │   │ Reward Proc. │                │       │      │
       │          │  │   │ (8 pts) ★    │                │       │      │
       │          │  │   └──────┬───────┘                │       │      │
       │          │  │          │                         │       │      │
       ▼          │  │          ▼                         ▼       │      ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ WAVE 5 (continued)                                                          │
│ ┌──────────────────────┐  ┌──────────────┐  ┌──────────┐  ┌──────────────┐ │
│ │ TASK-017             │  │ TASK-018     │  │TASK-019  │  │ TASK-020     │ │
│ │ Core Loop Orchestratr│  │ Seed Grove UI│  │Exped. UI │  │ Adventurer/  │ │
│ │ (13 pts) ★           │  │ (8 pts)      │  │(8 pts)   │  │ Inventory UI │ │
│ │                      │  │              │  │          │  │ (8 pts)      │ │
│ └──────────┬───────────┘  └──────┬───────┘  └────┬─────┘  └──────┬──────┘ │
└────────────┼─────────────────────┼───────────────┼───────────────┼────────┘
             │                     │               │               │
             │                     ▼               ▼               ▼
             │              WAVE 6 (Polish & Validation)
             │              ┌──────────────────────────────┐
             │              │ TASK-021                      │
             │              │ Main Menu & Hub Navigation    │
             │              │ (5 pts)                       │
             │              └──────────────┬───────────────┘
             │                             │
             ▼                             ▼
      ┌────────────────────────────────────────────┐
      │ TASK-022                                    │
      │ MVP Integration Test & E2E Loop Validation  │
      │ (13 pts) ★                                  │
      └────────────────────────────────────────────┘

★ = Critical Path
```

---

## Wave Plan

### Wave 1 — Foundation (no dependencies)
| Task | Complexity | Description |
|------|-----------|-------------|
| TASK-001 | 3 | Project bootstrap: clean autoload skeleton, folder structure, scene manager |
| TASK-002 | 3 | Deterministic RNG wrapper: xorshift64*, string seeding, reproducible sequences |
| TASK-003 | 3 | Enums, constants & data dictionary: rarity tiers, elements, room types, class types, currencies |

**Wave 1 total**: 9 points | 3 tasks | All parallelizable

### Wave 2 — Data Models & Persistence (depends on Wave 1)
| Task | Complexity | Description | Blocked By |
|------|-----------|-------------|------------|
| TASK-004 | 8 | Seed data model with Spore→Sprout→Bud→Bloom maturation state machine | TASK-003 |
| TASK-005 | 5 | Dungeon room graph data model (rooms, edges, room types, room metadata) | TASK-003 |
| TASK-006 | 5 | Adventurer data model: 6 classes, 5 stats, level tiers, XP curves | TASK-003 |
| TASK-007 | 5 | Item, equipment & inventory data models with rarity and slot system | TASK-003 |
| TASK-008 | 5 | Economy: 4-currency wallet (Gold/Essence/Fragments/Artifacts) + transaction ledger | TASK-003 |
| TASK-009 | 8 | Save/load manager with JSON serialization, versioning, migration stubs | TASK-001 |

**Wave 2 total**: 36 points | 6 tasks | All parallelizable within wave

### Wave 3 — Domain Services (depends on Waves 1-2)
| Task | Complexity | Description | Blocked By |
|------|-----------|-------------|------------|
| TASK-010 | 13 | Procedural dungeon generator: seed attributes → deterministic room graph | TASK-002, TASK-005 |
| TASK-011 | 8 | Loot table engine: weighted drop tables, rarity filtering, multi-roll sampling | TASK-002, TASK-007 |
| TASK-012 | 8 | Seed grove manager: planting, tick-based growth, mutation reagents, maturation | TASK-004, TASK-002 |
| TASK-013 | 5 | Adventurer roster manager: recruitment, party composition, roster serialization | TASK-006 |
| TASK-014 | 5 | Equipment system: equip/unequip, stat aggregation, slot validation | TASK-006, TASK-007 |

**Wave 3 total**: 39 points | 5 tasks | All parallelizable within wave

### Wave 4 — Expedition Core (depends on Wave 3)
| Task | Complexity | Description | Blocked By |
|------|-----------|-------------|------------|
| TASK-015 | 13 | Room-by-room expedition resolver: party vs rooms, combat, traps, treasure, boss | TASK-010, TASK-006, TASK-011 |

**Wave 4 total**: 13 points | 1 task | Serialization bottleneck (critical path)

### Wave 5 — Integration & UI (depends on Waves 3-4)
| Task | Complexity | Description | Blocked By |
|------|-----------|-------------|------------|
| TASK-016 | 8 | Expedition reward processor: loot distribution, XP, currency gains | TASK-015, TASK-008 |
| TASK-017 | 13 | Core loop orchestrator: idle ticks, active dispatch, state transitions, save hooks | TASK-012, TASK-015, TASK-016, TASK-009 |
| TASK-018 | 8 | Seed Grove UI: seed cards, growth progress bars, plant/mutate buttons | TASK-001, TASK-012 |
| TASK-019 | 8 | Expedition dispatch & resolution UI: party select, room-by-room progress, results | TASK-001, TASK-015 |
| TASK-020 | 8 | Adventurer Hall & inventory UI: roster view, equipment paper doll, item list | TASK-001, TASK-013, TASK-014 |

**Wave 5 total**: 45 points | 5 tasks | TASK-016/017 serial; TASK-018/019/020 parallelizable

### Wave 6 — Polish & Validation (depends on Wave 5)
| Task | Complexity | Description | Blocked By |
|------|-----------|-------------|------------|
| TASK-021 | 5 | Main menu, hub navigation & screen flow connecting all UI screens | TASK-018, TASK-019, TASK-020 |
| TASK-022 | 13 | MVP integration test: full loop plant→grow→dispatch→resolve→reward→reinvest | TASK-017, TASK-021 |

**Wave 6 total**: 18 points | 2 tasks | TASK-021 then TASK-022

---

## Critical Path Analysis

```
TASK-003 (3) → TASK-004 (8) → TASK-012 (8) ─────────────────────────────────────┐
                                                                                  │
TASK-003 (3) → TASK-005 (5) → TASK-010 (13) → TASK-015 (13) → TASK-016 (8) ────┤
                                                                                  │
                                                                                  ▼
                                                              TASK-017 (13) → TASK-022 (13)

Critical path (longest chain):
  TASK-003 (3) → TASK-005 (5) → TASK-010 (13) → TASK-015 (13) → TASK-016 (8) → TASK-017 (13) → TASK-022 (13)
  Total: 68 points across 7 tasks

Alternative critical path (through seed model):
  TASK-003 (3) → TASK-004 (8) → TASK-012 (8) → TASK-017 (13) → TASK-022 (13)
  Total: 45 points across 5 tasks (not the bottleneck)
```

**Primary critical path**: TASK-003 → TASK-005 → TASK-010 → TASK-015 → TASK-016 → TASK-017 → TASK-022
**Length**: 7 tasks, 68 points

**Bottleneck**: TASK-015 (Room-by-Room Expedition Resolver, 13 pts) is the single hardest integration point — it must combine dungeon graphs, adventurer stats, combat formulas, and loot tables into a coherent resolution system. This task gates both the reward processor and the core loop.

**Parallelism opportunity**: At peak (Wave 3), 5 tasks can execute simultaneously. Across the full plan, 14 of 22 tasks are off the critical path and can proceed in parallel with critical-path work.

---

## Task Descriptions

### TASK-001: Project Bootstrap & Autoload Skeleton
**Complexity**: 3 | **Wave**: 1 | **Dependencies**: None

Establish the clean Godot 4.5 project foundation. The existing `project.godot` names the project "Dungeon Seed" and points to `res://src/scenes/main_menu.tscn` as the main scene — this is kept. Create the canonical folder structure:

```
src/
  autoloads/         # Singleton autoloads (GameManager, EventBus)
  models/            # Pure data classes (RefCounted)
  services/          # Domain logic services (RefCounted)
  managers/          # Node-based managers (for scene tree integration)
  ui/                # UI scene scripts
  scenes/            # .tscn scene files
  resources/         # .tres resource files
  shaders/           # .gdshader files
tests/
  unit/              # Unit tests
  integration/       # Integration tests
```

Create two autoload singletons:
- **EventBus** (`src/autoloads/event_bus.gd`): Central signal bus with typed signals for `seed_planted`, `seed_matured`, `expedition_started`, `expedition_completed`, `loot_gained`, `adventurer_recruited`. This decouples all systems.
- **GameManager** (`src/autoloads/game_manager.gd`): Holds references to active services (SeedGrove, Roster, Wallet, LoopController). Provides `initialize()` and `shutdown()` lifecycle.

Register both as autoloads in `project.godot`. Create a minimal `SceneRouter` utility that wraps `get_tree().change_scene_to_file()` with transition support. Verify the project opens and runs to a blank screen without errors.

**Tests**: Autoloads are accessible from a test scene. EventBus signal emission/connection works. GameManager initializes and shuts down cleanly.

**Existing code reference**: `src/scenes/main_menu.gd` has basic scene transitions. `src/gdscript/utils/` has accessibility and save utilities. These are reference only — the new structure replaces them.

---

### TASK-002: Deterministic RNG Wrapper
**Complexity**: 3 | **Wave**: 1 | **Dependencies**: None

Implement a clean, tested deterministic RNG wrapper as `src/models/rng.gd` (extends RefCounted, class_name `DeterministicRNG`). The existing `rng_wrapper.gd` uses xorshift64* — this is a reasonable algorithm but the implementation has issues (extends Node unnecessarily, requiring `.free()` calls).

Requirements:
- Extends `RefCounted` (no manual memory management needed)
- `seed_int(val: int) -> void` — seed from integer
- `seed_string(s: String) -> void` — seed from string via SHA-256 hash
- `next_int() -> int` — next 63-bit positive integer
- `randf() -> float` — float in [0.0, 1.0)
- `randi(max_val: int) -> int` — integer in [0, max_val)
- `randi_range(min_val: int, max_val: int) -> int` — integer in [min_val, max_val]
- `shuffle(array: Array) -> Array` — in-place Fisher-Yates shuffle
- `pick(array: Array) -> Variant` — pick random element

Algorithm: xorshift64* (same as existing, proven to work). Key fix: extend RefCounted, not Node.

**Tests**: Determinism — same seed produces identical sequences. Variance — different seeds produce different sequences. Distribution — randf() is within [0,1), randi(N) is within [0,N). Shuffle produces valid permutations. 100 sequential calls produce no duplicates with distinct seeds.

**Existing code reference**: `src/gdscript/utils/rng_wrapper.gd` — reuse algorithm, fix class hierarchy.

---

### TASK-003: Enums, Constants & Data Dictionary
**Complexity**: 3 | **Wave**: 1 | **Dependencies**: None

Create `src/models/enums.gd` (a const-only script with `class_name Enums`) containing all game-wide enumerations and constants from the GDD:

```gdscript
# Seed rarity tiers
enum SeedRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

# Elemental affinities
enum Element { TERRA, FLAME, FROST, ARCANE, SHADOW }

# Seed maturation phases
enum SeedPhase { SPORE, SPROUT, BUD, BLOOM }

# Room types
enum RoomType { COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS }

# Adventurer classes
enum AdventurerClass { WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL }

# Adventurer level tiers
enum LevelTier { NOVICE, SKILLED, VETERAN, ELITE }

# Item rarity (matches loot system)
enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

# Equipment slots
enum EquipSlot { WEAPON, ARMOR, ACCESSORY }

# Currency types
enum Currency { GOLD, ESSENCE, FRAGMENTS, ARTIFACTS }

# Expedition status
enum ExpeditionStatus { PREPARING, IN_PROGRESS, COMPLETED, FAILED }
```

Also create `src/models/game_config.gd` (class_name `GameConfig`) with tuning constants:
- Base growth times per seed rarity (seconds)
- XP curves per level tier
- Base stats per adventurer class
- Mutation slot counts per seed rarity
- Currency earn rates
- Room encounter difficulty scaling factors

All values are `const` — no runtime mutation. This becomes the single source of truth for balance tuning.

**Tests**: All enum values are accessible. GameConfig constants are non-zero and within expected ranges. No duplicate enum values.

---

### TASK-004: Seed Data Model & Maturation State Machine
**Complexity**: 8 | **Wave**: 2 | **Dependencies**: TASK-003

Create `src/models/seed_data.gd` (extends RefCounted, class_name `SeedData`) representing a single plantable seed with full GDD attributes:

**Properties**:
- `id: String` — unique identifier (UUID or deterministic from seed)
- `rarity: Enums.SeedRarity`
- `element: Enums.Element`
- `phase: Enums.SeedPhase` — current maturation phase (Spore→Sprout→Bud→Bloom)
- `growth_progress: float` — 0.0 to 1.0 within current phase
- `growth_rate: float` — seconds per phase (modified by rarity)
- `mutation_slots: Array[MutationSlot]` — available reagent slots
- `mutation_potential: float` — 0.0 to 1.0, chance of beneficial mutation
- `dungeon_traits: Dictionary` — `{ room_variety: float, hazard_frequency: float, loot_bias: String }`
- `planted_at: float` — timestamp when planted (0 if unplanted)
- `is_planted: bool`

**State machine** (`advance_growth(delta_seconds: float) -> Enums.SeedPhase`):
- Each phase has a duration derived from `growth_rate` and `rarity` (from GameConfig)
- When `growth_progress >= 1.0`, transition to next phase and reset progress
- BLOOM is terminal — no further growth
- Returns the new phase (or current if unchanged)

**Mutation slot** (inner class or separate `src/models/mutation_slot.gd`):
- `slot_index: int`
- `reagent_id: String` (empty if unused)
- `effect: Dictionary` (stat modifiers applied to dungeon generation)

**Serialization**: `to_dict() -> Dictionary` and `static from_dict(d: Dictionary) -> SeedData`

**Tests**: Phase transitions at correct thresholds. Growth rate varies by rarity. Mutation slots are bounded by rarity. Serialization round-trip preserves all fields. BLOOM is terminal. Unplanted seeds don't advance.

**Existing code reference**: `src/gdscript/seeds/seed.gd` — much simpler (no phases, no element, no traits). Replace entirely.

---

### TASK-005: Dungeon Room Graph Data Model
**Complexity**: 5 | **Wave**: 2 | **Dependencies**: TASK-003

Create `src/models/dungeon_data.gd` (extends RefCounted, class_name `DungeonData`) representing a generated dungeon as a connected graph:

**DungeonData properties**:
- `seed_id: String` — the seed that spawned this dungeon
- `rooms: Array[RoomData]` — all rooms in the dungeon
- `edges: Array[Vector2i]` — connections between rooms (indices into rooms array)
- `entry_room_index: int` — starting room
- `boss_room_index: int` — final room (-1 if none)
- `element: Enums.Element` — inherited from seed
- `difficulty: int` — computed from seed rarity + phase

**RoomData** (inner class or `src/models/room_data.gd`, extends RefCounted, class_name `RoomData`):
- `index: int`
- `type: Enums.RoomType`
- `position: Vector2` — abstract position for layout visualization
- `size: Vector2` — abstract room dimensions
- `difficulty: int` — enemy/trap difficulty rating
- `loot_bias: Enums.Currency` — which currency this room tends to drop
- `is_cleared: bool` — expedition state
- `metadata: Dictionary` — extensible room-specific data

**Graph operations**:
- `get_adjacent(room_index: int) -> Array[int]` — connected rooms
- `get_path_to_boss() -> Array[int]` — shortest path from entry to boss
- `get_uncleared_rooms() -> Array[int]`
- `is_fully_cleared() -> bool`

**Serialization**: `to_dict()` / `from_dict()` for both DungeonData and RoomData.

**Tests**: Graph connectivity — all rooms reachable from entry. Boss room exists and is reachable. get_adjacent returns correct neighbors. Path to boss is valid. Serialization round-trip. Edge cases: single-room dungeon, max-room dungeon.

**Existing code reference**: `src/gdscript/dungeon/dungeon_generator.gd` returns a flat Dictionary with rooms array — the new model is a proper graph with typed room data.

---

### TASK-006: Adventurer Data Model & Class Definitions
**Complexity**: 5 | **Wave**: 2 | **Dependencies**: TASK-003

Create `src/models/adventurer_data.gd` (extends RefCounted, class_name `AdventurerData`):

**Properties**:
- `id: String`
- `display_name: String`
- `adventurer_class: Enums.AdventurerClass`
- `level: int` (starts at 1)
- `level_tier: Enums.LevelTier` (computed from level: 1-5 Novice, 6-10 Skilled, 11-15 Veteran, 16+ Elite)
- `xp: int` (current XP within level)
- `stats: Dictionary` — `{ health: int, attack: int, defense: int, speed: int, utility: int }`
- `equipment: Dictionary` — `{ EquipSlot → item_id or null }`
- `is_available: bool` — false if on active expedition

**Class definitions** (in `GameConfig` or inline):
Per GDD — 6 classes with distinct base stat distributions:
- **Warrior**: high health/defense, medium attack
- **Ranger**: high speed, medium attack, low defense
- **Mage**: high attack/utility, low health/defense
- **Rogue**: high speed/utility, medium attack
- **Alchemist**: high utility, medium everything else
- **Sentinel**: highest defense/health, low speed/attack

**Methods**:
- `gain_xp(amount: int) -> bool` — returns true if level-up occurred
- `xp_to_next_level() -> int` — exponential curve from GameConfig
- `get_effective_stats() -> Dictionary` — base + equipment bonuses (placeholder for TASK-014)
- `get_level_tier() -> Enums.LevelTier`

**Serialization**: Full `to_dict()` / `from_dict()`.

**Tests**: Each class has distinct base stats. XP gain triggers level-up at correct thresholds. Level tier transitions at correct levels. Serialization preserves all fields. Stat totals are positive.

**Existing code reference**: `src/gdscript/adventurer/adventurer.gd` — similar shape but uses `class_name_str` string instead of enum, lacks level tiers. Replace.

---

### TASK-007: Item, Equipment & Inventory Data Models
**Complexity**: 5 | **Wave**: 2 | **Dependencies**: TASK-003

Create three models:

**`src/models/item_data.gd`** (RefCounted, class_name `ItemData`):
- `id: String`
- `display_name: String`
- `rarity: Enums.ItemRarity`
- `slot: Enums.EquipSlot` (WEAPON/ARMOR/ACCESSORY, or -1 if not equippable)
- `is_equippable: bool`
- `stat_bonuses: Dictionary` — `{ "attack": 5, "defense": 3 }` etc.
- `sell_value: Dictionary` — `{ Currency.GOLD: 10 }` etc.
- `description: String`

**`src/models/item_database.gd`** (RefCounted, class_name `ItemDatabase`):
- Static registry of all item definitions (loaded from a Dictionary or JSON resource)
- `get_item(id: String) -> ItemData`
- `get_items_by_rarity(rarity: Enums.ItemRarity) -> Array[ItemData]`
- `get_items_by_slot(slot: Enums.EquipSlot) -> Array[ItemData]`
- Pre-populate with ~20 starter items: 3-4 weapons per tier, 3-4 armors, 3-4 accessories

**`src/models/inventory_data.gd`** (RefCounted, class_name `InventoryData`):
- `items: Dictionary` — `{ item_id: int }` (id → quantity)
- `add_item(item_id: String, qty: int) -> void`
- `remove_item(item_id: String, qty: int) -> bool`
- `has_item(item_id: String, qty: int) -> bool`
- `get_quantity(item_id: String) -> int`
- `list_all() -> Array[Dictionary]` — `[{ item_id, qty }]`
- `to_dict()` / `from_dict()`

**Tests**: Add/remove items with quantity tracking. Remove fails gracefully when insufficient. ItemDatabase returns correct items by filter. Serialization round-trip.

**Existing code reference**: `src/gdscript/items/item.gd` and `src/gdscript/inventory/inventory.gd` — similar but lack rarity enums and item database.

---

### TASK-008: Economy — 4-Currency Wallet & Transaction Ledger
**Complexity**: 5 | **Wave**: 2 | **Dependencies**: TASK-003

Create `src/models/wallet.gd` (RefCounted, class_name `Wallet`):

**Properties**:
- `balances: Dictionary` — `{ Currency.GOLD: 0, Currency.ESSENCE: 0, Currency.FRAGMENTS: 0, Currency.ARTIFACTS: 0 }`

**Methods**:
- `get_balance(currency: Enums.Currency) -> int`
- `can_afford(costs: Dictionary) -> bool` — checks multiple currencies at once
- `credit(currency: Enums.Currency, amount: int) -> void` — add funds (emits EventBus signal)
- `debit(currency: Enums.Currency, amount: int) -> bool` — subtract funds, returns false if insufficient
- `transact(costs: Dictionary, gains: Dictionary) -> bool` — atomic multi-currency transaction
- `to_dict()` / `from_dict()`

Create `src/models/transaction_log.gd` (RefCounted, class_name `TransactionLog`):
- Records last N transactions for debug/UI display
- Each entry: `{ timestamp: float, type: String, currency: Currency, amount: int, balance_after: int }`
- `record(type: String, currency: Enums.Currency, amount: int, balance: int) -> void`
- `get_recent(count: int) -> Array[Dictionary]`

**Tests**: Fresh wallet has zero balances. Credit increases balance. Debit decreases balance. Debit fails when insufficient. Multi-currency transact is atomic (all-or-nothing). Transaction log records correctly. Serialization round-trip.

---

### TASK-009: Save/Load Manager with Versioned Serialization
**Complexity**: 8 | **Wave**: 2 | **Dependencies**: TASK-001

Create `src/services/save_service.gd` (RefCounted, class_name `SaveService`):

**Responsibilities**:
- Serialize complete game state to JSON
- Load and deserialize game state
- Version-tagged saves with migration support
- Corruption detection (basic JSON validation)
- Multiple save slots (3 slots for MVP)
- Autosave trigger hook

**Save manifest structure**:
```json
{
  "version": 2,
  "timestamp": 1719590400,
  "slot": 1,
  "seeds": [...],
  "dungeon": {...},
  "adventurers": [...],
  "inventory": {...},
  "wallet": {...},
  "loop_state": {...},
  "settings": {...}
}
```

**Methods**:
- `save_game(slot: int, game_state: Dictionary) -> bool`
- `load_game(slot: int) -> Dictionary` (empty dict on failure)
- `list_slots() -> Array[Dictionary]` — `[{ slot, timestamp, exists }]`
- `delete_slot(slot: int) -> bool`
- `migrate(data: Dictionary, from_version: int, to_version: int) -> Dictionary`
- `_validate(data: Dictionary) -> bool` — check required keys exist

Save path: `user://saves/slot_{N}.json`

**Tests**: Save and load round-trip. Corrupted file returns empty. Migration from v1→v2 works. Missing keys detected. Multiple slots independent. Slot listing correct.

**Existing code reference**: `src/gdscript/utils/save_manager.gd` — single slot only, no migration, no corruption handling. Replace.

---

### TASK-010: Procedural Dungeon Generator (Seed → Room Graph)
**Complexity**: 13 | **Wave**: 3 | **Dependencies**: TASK-002, TASK-005

Create `src/services/dungeon_generator.gd` (RefCounted, class_name `DungeonGeneratorService`):

**Core algorithm**: Given a `SeedData` instance (or its key properties), produce a `DungeonData` room graph deterministically.

**Generation pipeline**:
1. **Seed parsing**: Extract `rarity`, `element`, `phase`, `dungeon_traits` from seed
2. **Room count**: Base count from phase (Spore=3, Sprout=5, Bud=8, Bloom=12) + rarity bonus (0-3)
3. **Room type distribution**: Weighted by `room_variety` trait and element:
   - Always 1 BOSS room (last room)
   - Always 1 REST room
   - Remaining rooms: weighted random from COMBAT(40%), TREASURE(20%), TRAP(15%), PUZZLE(15%), REST(10%)
   - Element biases: FLAME increases COMBAT weight, FROST increases TRAP weight, etc.
4. **Graph connectivity**: Build a connected graph using spanning-tree + random extra edges
   - Place rooms in abstract 2D positions (grid-based or force-directed)
   - Connect via minimum spanning tree (Prim's) for guaranteed connectivity
   - Add 1-3 random shortcut edges for variety
   - Entry room = index 0, Boss room = last index
5. **Difficulty assignment**: Per-room difficulty = base (from seed rarity) × positional depth factor × room-type modifier
6. **Loot bias assignment**: Per-room currency bias from seed's `loot_bias` trait + room type defaults

**Determinism**: All random decisions use `DeterministicRNG` seeded from `seed_id + phase`. Same inputs always produce same output.

**Methods**:
- `generate(seed_data: SeedData) -> DungeonData` — main entry point
- `generate_from_params(seed_id: String, rarity: int, element: int, phase: int, traits: Dictionary) -> DungeonData` — for testing without a full SeedData

**Tests**:
- Determinism: same seed → identical dungeon (run twice, compare)
- Variance: different seeds → different dungeons
- Connectivity: all rooms reachable from entry
- Boss room: always exists, always reachable
- Room count scales with phase (Spore < Bloom)
- Difficulty increases along path to boss
- Room type distribution roughly matches weights (over many generations)

**Existing code reference**: `src/gdscript/dungeon/dungeon_generator.gd` — uses spatial room placement with overlap detection. The new approach uses abstract graph generation (no pixel-level placement) since the game uses semi-abstract room-by-room exploration per the GDD. The spatial approach is more suited to visual dungeon rendering but is overkill for the expedition resolution system.

---

### TASK-011: Loot Table Engine & Drop Resolver
**Complexity**: 8 | **Wave**: 3 | **Dependencies**: TASK-002, TASK-007

Create `src/services/loot_service.gd` (RefCounted, class_name `LootService`):

**Loot table structure**: Each table is a named collection of weighted entries:
```gdscript
{
  "table_id": "combat_common",
  "entries": [
    { "item_id": "iron_sword", "weight": 100, "min_qty": 1, "max_qty": 1 },
    { "item_id": "gold_coins", "weight": 200, "min_qty": 5, "max_qty": 20 },
    { "item_id": "health_potion", "weight": 150, "min_qty": 1, "max_qty": 3 },
    ...
  ]
}
```

**Methods**:
- `register_table(table_id: String, entries: Array) -> void`
- `roll(table_id: String, rng: DeterministicRNG, count: int = 1) -> Array[Dictionary]` — returns `[{ item_id, qty }]`
- `roll_with_rarity_filter(table_id: String, rng: DeterministicRNG, min_rarity: Enums.ItemRarity) -> Array[Dictionary]` — filter out items below rarity threshold
- `roll_currency(room_type: Enums.RoomType, difficulty: int, rng: DeterministicRNG) -> Dictionary` — returns `{ Currency: amount }` for direct currency drops

**Pre-built tables** (defined in a `src/resources/loot_tables.gd` or JSON):
- `combat_common`, `combat_rare` — combat room drops
- `treasure_common`, `treasure_rare` — treasure room drops
- `boss_loot` — boss room drops (higher rarity weights)
- `trap_consolation` — minor drops from trap rooms

**Currency drop formula**: `base_amount × difficulty_mult × rarity_mult`, with variance from RNG.

**Tests**: Weighted sampling produces items proportional to weights (statistical test over 1000 rolls). Rarity filter excludes low-rarity items. Currency amounts scale with difficulty. Empty table returns empty. Determinism with same RNG seed.

**Existing code reference**: `src/gdscript/economy/loot_table.gd` and `loot_manager.gd` — similar concept but no rarity filtering, no currency drops, no pre-built tables. Replace.

---

### TASK-012: Seed Grove Manager (Plant, Grow, Mutate)
**Complexity**: 8 | **Wave**: 3 | **Dependencies**: TASK-004, TASK-002

Create `src/managers/seed_grove.gd` (extends Node, class_name `SeedGrove`):

This is the primary seed management service — it owns all planted seeds and advances their growth.

**Properties**:
- `seeds: Array[SeedData]` — all seeds (planted and unplanted)
- `max_grove_slots: int` — maximum simultaneous planted seeds (starts at 3, expandable)
- `rng: DeterministicRNG` — for mutation rolls

**Methods**:
- `plant_seed(seed: SeedData) -> bool` — marks seed as planted if slot available
- `uproot_seed(seed_id: String) -> SeedData` — remove a planted seed (loses progress)
- `tick(delta: float) -> Array[Dictionary]` — advance all planted seeds by delta seconds, returns array of events `[{ seed_id, event: "phase_changed" | "mutated", ... }]`
- `apply_reagent(seed_id: String, reagent_id: String) -> bool` — fill a mutation slot
- `get_planted_seeds() -> Array[SeedData]`
- `get_matured_seeds() -> Array[SeedData]` — seeds in BLOOM phase
- `get_ready_for_expedition(seed_id: String) -> bool` — at least SPROUT phase
- `create_seed(rarity: Enums.SeedRarity, element: Enums.Element) -> SeedData` — factory method
- `serialize() -> Dictionary` / `deserialize(data: Dictionary) -> void`

**Growth tick logic**:
- For each planted seed, call `seed.advance_growth(delta)`
- If phase changed, emit `EventBus.seed_phase_changed(seed_id, new_phase)`
- If BLOOM reached, emit `EventBus.seed_matured(seed_id)`
- On each tick where seed is BLOOM, roll for bonus mutation (low chance)

**Mutation logic**:
- Each reagent modifies dungeon traits (e.g., "fire_reagent" → increases hazard_frequency, shifts loot_bias toward ESSENCE)
- Mutation potential determines success chance
- Failed mutations consume the reagent with no effect

**Tests**: Plant seed advances through phases with tick. Max grove slots enforced. Matured seeds reported correctly. Reagent application fills correct slot. Serialization preserves grove state. Events emitted on phase transitions.

**Existing code reference**: `src/gdscript/seeds/seed_manager.gd` — basic plant/tick but no phases, no grove slots, no mutation reagents. Replace.

---

### TASK-013: Adventurer Roster & Party Builder
**Complexity**: 5 | **Wave**: 3 | **Dependencies**: TASK-006

Create `src/managers/adventurer_roster.gd` (extends Node, class_name `AdventurerRoster`):

**Properties**:
- `adventurers: Array[AdventurerData]`
- `max_roster_size: int` — maximum total adventurers (starts at 8)

**Methods**:
- `recruit(display_name: String, adventurer_class: Enums.AdventurerClass) -> AdventurerData` — creates and adds to roster
- `dismiss(adventurer_id: String) -> bool` — remove from roster
- `get_available() -> Array[AdventurerData]` — not on active expedition
- `get_by_id(id: String) -> AdventurerData`
- `get_by_class(cls: Enums.AdventurerClass) -> Array[AdventurerData]`
- `form_party(adventurer_ids: Array[String]) -> Array[AdventurerData]` — validates all exist and are available, marks as unavailable, returns party
- `release_party(adventurer_ids: Array[String]) -> void` — marks as available again
- `serialize() -> Array[Dictionary]` / `deserialize(data: Array) -> void`

**Party validation rules**:
- Party size: 1-4 adventurers
- All must be available (not on expedition)
- No duplicate adventurers

**Tests**: Recruit adds to roster. Max roster enforced. Party formation marks unavailable. Release marks available. Form party with unavailable adventurer fails. Serialize/deserialize preserves roster.

**Existing code reference**: `src/gdscript/adventurer/manager.gd` — similar but no availability tracking, no party formation. Replace.

---

### TASK-014: Equipment System (Equip/Unequip/Stat Calc)
**Complexity**: 5 | **Wave**: 3 | **Dependencies**: TASK-006, TASK-007

Create `src/services/equipment_service.gd` (RefCounted, class_name `EquipmentService`):

**Methods**:
- `equip(adventurer: AdventurerData, item: ItemData, inventory: InventoryData) -> Dictionary` — equip item from inventory. Returns `{ success: bool, unequipped_item_id: String or "" }`. Removes from inventory, puts on adventurer, returns any replaced item to inventory.
- `unequip(adventurer: AdventurerData, slot: Enums.EquipSlot, inventory: InventoryData) -> bool` — remove equipped item, return to inventory
- `get_effective_stats(adventurer: AdventurerData, item_db: ItemDatabase) -> Dictionary` — base stats + all equipment bonuses
- `get_equipped_items(adventurer: AdventurerData, item_db: ItemDatabase) -> Array[ItemData]` — resolve item IDs to ItemData

**Rules**:
- Item must have matching `slot` to equip
- Item must exist in inventory
- If slot already occupied, auto-unequip existing item first (swap)
- Equipment stat bonuses are additive to base stats

**Tests**: Equip puts item on adventurer, removes from inventory. Unequip returns to inventory. Effective stats = base + equipment. Slot mismatch fails. Swap correctly returns old item.

**Existing code reference**: `src/gdscript/items/equipment_manager.gd` — similar concept, equip/unequip work. Adapt approach but integrate with new models.

---

### TASK-015: Room-by-Room Expedition Resolver
**Complexity**: 13 | **Wave**: 4 | **Dependencies**: TASK-010, TASK-006, TASK-011

Create `src/services/expedition_resolver.gd` (RefCounted, class_name `ExpeditionResolver`):

This is the core gameplay engine — it resolves a party's journey through a dungeon room by room.

**Input**: `DungeonData` (generated dungeon), `Array[AdventurerData]` (party), `DeterministicRNG`

**Resolution pipeline** (per room along the path from entry to boss):

1. **Room selection**: Follow path from entry → boss. Each room resolved in order.
2. **Room resolution by type**:
   - **COMBAT**: Party vs enemies. Enemies generated from room difficulty. Turn-based resolution:
     - Each party member and enemy acts in speed order
     - Actions: attack (damage = max(1, attacker.attack - defender.defense) + variance), heal (Alchemist special), defend (reduce next incoming damage by 50%)
     - Party members can fall (HP ≤ 0) — removed from active party for remainder of expedition
     - Combat ends when all enemies or all party members are defeated
   - **TREASURE**: No combat. Roll loot table. Bonus loot for Rogue (utility stat bonus)
   - **TRAP**: Each party member makes a speed check. Failed check = damage. Rogue/Ranger advantage.
   - **PUZZLE**: Utility check for bonus loot. No penalty for failure. Mage advantage.
   - **REST**: Heal party members by 25% of max HP. No other effect.
   - **BOSS**: Like COMBAT but single strong enemy with 2-3× stats. Drops guaranteed rare+ loot.
3. **Per-room result**: `{ room_index, type, success: bool, party_casualties: Array, loot: Array, currency: Dictionary }`
4. **Expedition ends**: When boss defeated (success), all party dead (failure), or player retreats (partial)

**Output**: `ExpeditionResult` — a data class containing:
- `success: bool`
- `rooms_cleared: int`
- `total_rooms: int`
- `room_results: Array[Dictionary]` — per-room breakdown
- `total_loot: Array[Dictionary]` — all items gained
- `total_currency: Dictionary` — all currency gained
- `xp_earned: int` — based on rooms cleared and difficulty
- `party_casualties: Array[String]` — adventurer IDs who fell (they recover after expedition, not permadeath)

**Methods**:
- `resolve_expedition(dungeon: DungeonData, party: Array[AdventurerData], rng: DeterministicRNG) -> ExpeditionResult`
- `resolve_room(room: RoomData, party: Array[AdventurerData], rng: DeterministicRNG, loot_service: LootService) -> Dictionary`
- `resolve_combat(party_stats: Array[Dictionary], enemy_stats: Array[Dictionary], rng: DeterministicRNG) -> Dictionary`

**Tests**:
- Full expedition completes (party strong enough for difficulty)
- Party wipe results in failure with partial loot
- Deterministic: same inputs → same expedition result
- Boss room always last and drops loot
- Rest rooms heal party
- Treasure rooms produce loot without combat
- Trap rooms deal damage based on speed
- XP scales with rooms cleared
- Edge case: single-member party

**Existing code reference**: `src/gdscript/combat/combat_manager.gd` (basic combat loop), `src/gdscript/combat/combat_core.gd` (damage formula), `src/gdscript/loop/loop_controller.gd` (tick-based expedition). The new system replaces all three with room-by-room resolution.

---

### TASK-016: Expedition Reward Processor & XP Distributor
**Complexity**: 8 | **Wave**: 5 | **Dependencies**: TASK-015, TASK-008

Create `src/services/reward_processor.gd` (RefCounted, class_name `RewardProcessor`):

**Responsibilities**: Take an `ExpeditionResult` and apply all rewards to the player's state.

**Methods**:
- `process_rewards(result: ExpeditionResult, inventory: InventoryData, wallet: Wallet, party: Array[AdventurerData]) -> Dictionary`:
  1. Add all `total_loot` items to `inventory`
  2. Credit all `total_currency` to `wallet`
  3. Distribute XP to surviving party members (fallen members get 50% XP)
  4. Return summary: `{ items_gained: int, currency_gained: Dictionary, xp_per_adventurer: Dictionary, level_ups: Array[String] }`

- `calculate_xp_distribution(result: ExpeditionResult, party: Array[AdventurerData]) -> Dictionary`:
  - Base XP = rooms_cleared × difficulty × 10
  - Bonus XP for full clear (all rooms + boss)
  - Split evenly among party members
  - Fallen members get 50%
  - Returns `{ adventurer_id: xp_amount }`

**Events emitted**:
- `EventBus.loot_gained(items)` for each item
- `EventBus.currency_gained(currency, amount)` for each currency gain
- `EventBus.adventurer_leveled_up(adventurer_id, new_level)` for level-ups

**Tests**: Loot added to inventory. Currency added to wallet. XP distributed proportionally. Fallen members get half XP. Level-ups detected and reported. Empty expedition result produces no rewards. Events emitted correctly.

---

### TASK-017: Core Loop Orchestrator (Idle Tick + Active Dispatch)
**Complexity**: 13 | **Wave**: 5 | **Dependencies**: TASK-012, TASK-015, TASK-016, TASK-009

Create `src/managers/game_loop.gd` (extends Node, class_name `GameLoop`):

This is the central coordinator that ties all systems together.

**State machine**:
```
IDLE ←→ PLANTING → GROWING → READY → DISPATCHING → RESOLVING → REWARDING → IDLE
```

**Properties**:
- `seed_grove: SeedGrove` — reference to autoloaded seed grove
- `roster: AdventurerRoster` — reference to autoloaded roster
- `inventory: InventoryData`
- `wallet: Wallet`
- `save_service: SaveService`
- `dungeon_generator: DungeonGeneratorService`
- `loot_service: LootService`
- `expedition_resolver: ExpeditionResolver`
- `reward_processor: RewardProcessor`
- `active_expedition: Dictionary` — currently running expedition data (or empty)
- `idle_tick_rate: float` — seconds between idle processing (1.0s default)

**Core methods**:
- `_process(delta: float)` — called every frame:
  - Advance seed grove growth: `seed_grove.tick(delta)`
  - Process idle gains (if any matured seeds generating passive income)
  - Check autosave timer
- `plant_seed(seed: SeedData) -> bool` — delegate to seed grove
- `dispatch_expedition(seed_id: String, party_ids: Array[String]) -> Dictionary`:
  1. Validate seed is ready (≥ SPROUT)
  2. Validate party (form_party on roster)
  3. Generate dungeon from seed: `dungeon_generator.generate(seed_data)`
  4. Resolve expedition: `expedition_resolver.resolve_expedition(dungeon, party, rng)`
  5. Process rewards: `reward_processor.process_rewards(result, inventory, wallet, party)`
  6. Release party: `roster.release_party(party_ids)`
  7. Return full expedition result + reward summary
- `save_game(slot: int) -> bool` — collect all state, delegate to save_service
- `load_game(slot: int) -> bool` — load state, distribute to all managers
- `new_game() -> void` — initialize fresh state with starter seed + starter adventurer
- `get_game_state() -> Dictionary` — snapshot of all state for save

**Idle gains**: When a seed reaches BLOOM, it passively generates small currency rewards per tick (Gold primarily). This implements the GDD's idle reward track.

**Autosave**: Every 60 seconds, auto-save to slot 0.

**Tests**:
- New game initializes with starter seed and adventurer
- Plant → grow (fast-forward ticks) → dispatch → resolve → rewards returned
- Save/load round-trip preserves full state
- Idle gains accumulate over time for BLOOM seeds
- Dispatch with unready seed fails
- Dispatch with unavailable party fails

**Existing code reference**: `src/gdscript/loop/loop_controller.gd` — tick-based but much simpler. The new orchestrator coordinates all subsystems.

---

### TASK-018: Seed Grove UI Screen
**Complexity**: 8 | **Wave**: 5 | **Dependencies**: TASK-001, TASK-012

Create `src/ui/seed_grove_screen.gd` + `src/scenes/seed_grove_screen.tscn`:

**Layout**:
- Grid of seed slot cards (3 initially, expandable)
- Each card shows:
  - Seed rarity (color-coded border)
  - Element icon
  - Current phase label (Spore/Sprout/Bud/Bloom)
  - Growth progress bar (animated fill)
  - Mutation slot indicators (filled/empty)
  - "Ready" badge when ≥ SPROUT
- Below grid:
  - "Plant New Seed" button (opens seed selection popup)
  - "Apply Reagent" button (context-sensitive, only when seed selected)
  - Resource bar showing current currencies

**Interactions**:
- Tap seed card → select seed, show details panel
- Plant button → if empty slot, create seed with random rarity/element (for MVP, fancier selection later)
- Dispatch button → navigate to expedition dispatch screen with selected seed

**Signals**: Connected to EventBus for real-time growth updates (progress bar animates as `seed_grove.tick()` fires).

**Scene structure**: VBoxContainer root → HBoxContainer for seed cards → Panel per card with Label, ProgressBar, TextureRect placeholders.

**Tests**: UI scene instantiates without error. Seed cards render correct count. Progress bar updates on tick signal. Plant button disabled when grove full.

---

### TASK-019: Expedition Dispatch & Resolution UI
**Complexity**: 8 | **Wave**: 5 | **Dependencies**: TASK-001, TASK-015

Create `src/ui/expedition_screen.gd` + `src/scenes/expedition_screen.tscn`:

**Two-phase screen**:

**Phase 1 — Dispatch Setup**:
- Selected seed info (rarity, element, phase, expected room count)
- Party selection panel: show available adventurers with class/level/stats
- Drag or tap adventurers to add to party (1-4 members)
- Party power estimation vs dungeon difficulty indicator (green/yellow/red)
- "Begin Expedition" button

**Phase 2 — Resolution Display**:
- Room-by-room progress visualization
- Each room shows: type icon, result (cleared/failed), loot gained
- Animated sequential reveal (room by room with brief delay for drama)
- Final summary panel: total loot, currency gained, XP earned, level-ups
- "Return to Grove" button

**Implementation**: Resolution is instant (computed in TASK-015) but displayed progressively with timers/tweens for game feel.

**Scene structure**: MarginContainer → VBoxContainer → ScrollContainer with room cards → summary panel at bottom.

**Tests**: Screen instantiates. Party selection respects availability. Dispatch triggers expedition. Results display correctly. Return button navigates back.

---

### TASK-020: Adventurer Hall & Inventory UI
**Complexity**: 8 | **Wave**: 5 | **Dependencies**: TASK-001, TASK-013, TASK-014

Create two sub-screens:

**`src/ui/adventurer_hall_screen.gd`** + `.tscn`:
- Roster grid showing all adventurers
- Each card: name, class icon, level, tier badge, availability status
- Tap card → detail panel with full stats, equipment slots, XP progress
- "Recruit" button (costs Gold) → random name + player-chosen class
- Equipment slots: tap slot → open inventory filtered to equippable items for that slot

**`src/ui/inventory_screen.gd`** + `.tscn`:
- Scrollable item list grouped by type
- Each row: item name, rarity color, quantity, equip/sell buttons
- Currency display bar at top (Gold, Essence, Fragments, Artifacts)
- Filter tabs: All / Weapons / Armor / Accessories / Materials

**Interactions**:
- Equip item: select adventurer first, then tap equip → delegates to EquipmentService
- Sell item: sells for item's sell_value, credits wallet

**Tests**: Screens instantiate. Roster displays correct adventurer count. Equipment swap works through UI. Inventory filters correctly. Sell updates wallet.

---

### TASK-021: Main Menu, Hub Navigation & Screen Flow
**Complexity**: 5 | **Wave**: 6 | **Dependencies**: TASK-018, TASK-019, TASK-020

Create the glue that connects all screens into a coherent game experience:

**Main Menu** (`src/ui/main_menu_screen.gd` + `src/scenes/main_menu_screen.tscn`):
- Title: "Dungeon Seed"
- Buttons: New Game, Continue (load), Settings, Quit
- New Game → initialize GameLoop → navigate to Hub
- Continue → show save slot picker → load → navigate to Hub

**Hub Screen** (`src/ui/hub_screen.gd` + `src/scenes/hub_screen.tscn`):
- Tab bar or button row at bottom: Seed Grove | Expeditions | Adventurers | Inventory
- Each tab switches the active sub-screen (instantiate/show/hide pattern or SceneTree changes)
- Persistent top bar: currency display, settings gear icon
- Back button from any sub-screen returns to hub

**Screen flow**:
```
Main Menu → Hub → Seed Grove Screen
                 → Expedition Screen
                 → Adventurer Hall Screen
                 → Inventory Screen
                 → Settings Screen (overlay)
```

**SceneRouter integration**: Use the TASK-001 SceneRouter for transitions with optional fade.

**Tests**: Main menu buttons navigate correctly. Hub tabs switch screens. Back navigation works. New game creates fresh state. Continue loads saved state.

---

### TASK-022: MVP Integration Test & End-to-End Loop Validation
**Complexity**: 13 | **Wave**: 6 | **Dependencies**: TASK-017, TASK-021

Create `tests/integration/test_mvp_loop.gd` — a comprehensive integration test that validates the full MVP game loop can execute from start to finish:

**Test scenarios**:

1. **Full loop — headless** (no UI):
   - New game → get starter seed + adventurer
   - Plant seed
   - Fast-forward growth ticks until SPROUT
   - Dispatch expedition (party of 1 adventurer)
   - Verify expedition resolves (success or failure based on RNG)
   - Verify loot added to inventory
   - Verify currency added to wallet
   - Verify adventurer gained XP
   - Save game → load game → verify state matches

2. **Growth through all phases**:
   - Plant seed → tick through Spore → Sprout → Bud → Bloom
   - Verify each phase transition fires events
   - Verify BLOOM dungeon has max room count
   - Dispatch into BLOOM dungeon → verify full room set

3. **Multiple expeditions**:
   - Recruit 4 adventurers
   - Run 3 sequential expeditions
   - Verify XP accumulates and level-ups occur
   - Verify inventory grows with loot

4. **Economy flow**:
   - Start with initial Gold
   - Run expedition → earn currency
   - Recruit new adventurer (costs Gold)
   - Verify wallet debited correctly

5. **Save/load fidelity**:
   - Build up game state (seeds, adventurers, inventory, wallet)
   - Save → load → compare all fields
   - Verify loaded game continues correctly

6. **Idle gains**:
   - Plant seed → grow to BLOOM
   - Tick idle loop for N seconds
   - Verify passive currency generated

7. **Determinism**:
   - Run same expedition twice with same seed
   - Verify identical results

**Also validate**: All screens instantiate without Godot errors. No null reference exceptions in autoloads. EventBus signals fire for all key actions.

**Acceptance criteria**: All 7 test scenarios pass. The game loop is mechanically complete: a player can plant, grow, dispatch, resolve, collect loot, level up, and repeat indefinitely.

---

## Assumptions & Decisions

| # | Assumption/Decision | Rationale | Impact if Wrong |
|---|---------------------|-----------|-----------------|
| D-001 | Godot 4.5 with GDScript only (no C#, no GDExtension) | project.godot already configured for 4.5. GDScript is the simplest path for MVP. | If C# needed, all class_name registrations and autoload patterns change. |
| D-002 | Existing `src/gdscript/` code is treated as reference, not reused directly | EPIC-TRACKER mandates pipeline restart. Code has known bugs (deprecated APIs, undeclared vars). ~40% GDD coverage. | If code is trustworthy, some tasks shrink by 30-40%. But audit said otherwise. |
| D-003 | Expedition resolution is instant (computed), displayed progressively | GDD describes "watch rooms clear" but the resolution math runs instantly; UI adds dramatic timing. | If real-time resolution is required, TASK-015 becomes significantly more complex (~21 pts). |
| D-004 | MVP scope = 1 biome, ~20 items, 6 classes, 4 currencies | Full GDD lists 5 biomes, seasonal trials, prestige. MVP focuses on one playable loop. | Post-MVP tasks needed for full GDD coverage. |
| D-005 | No multiplayer, no leaderboards, no MTX in MVP | GDD mentions these as stretch. MVP is single-player local. | If needed sooner, add tasks for networking and backend. |
| D-006 | Party members who fall in expeditions recover afterward (no permadeath) | GDD doesn't specify permadeath. Casual-friendly default for idle/progression genre. | If permadeath added, adventurer loss/grief systems needed. |
| D-007 | Adventurer casualties in expedition are temporary (recover after expedition) | This aligns with the idle/progression genre where permanent loss would be punishing | If permadeath is desired, TASK-015 and TASK-016 need rework |
| D-008 | Abstract dungeon representation (graph), not spatial tilemap | GDD says "semi-abstract: players send teams through rooms with results resolved per room." | If visual dungeon exploration needed, add tilemap rendering task (~13 pts). |

---

## Gaps & Risks

| # | Gap/Risk | Severity | Mitigation |
|---|----------|----------|------------|
| R-001 | Balance tuning (damage numbers, XP curves, loot rates) will need iteration | Medium | All balance values in GameConfig as constants. Easy to tune post-MVP. Balance Auditor agent can run simulations. |
| R-002 | UI placeholder art — no artist pipeline yet | Medium | Use Godot's built-in theme with colored rectangles and text labels. Art can be layered on later. |
| R-003 | Existing test runner (`tests/unit/test_runner.gd`) uses custom pattern, not GdUnit4 | Low | MVP tests use simple assert-based pattern matching existing convention. Can migrate to GdUnit4 later. |
| R-004 | Mutation reagent content (specific reagent definitions) not in GDD | Medium | Create 5 basic reagents (one per element) with simple trait modifiers. Expand post-MVP. |
| R-005 | Idle gains formula undefined in GDD | Medium | Implement simple passive Gold generation for BLOOM seeds. Tune later. |
| R-006 | No sound/music in MVP | Low | Audio hooks (EventBus signals) are in place for Audio Composer to attach to post-MVP. |
| R-007 | Procedural name generation for adventurers not specified | Low | Use a small hardcoded name list for MVP. Procedural generation post-MVP. |
| R-008 | DungeonData graph serialization could be complex for large dungeons | Low | MVP dungeons are small (3-12 rooms). Simple array serialization sufficient. |

---

## Codebase Research Notes

### Project Structure
- Godot 4.5 project at repo root with `project.godot` configured for "Dungeon Seed"
- Main scene: `res://src/scenes/main_menu.tscn`
- Existing GDScript code in `src/gdscript/` organized by domain (seeds, dungeon, adventurer, combat, economy, etc.)
- Existing test suite in `tests/unit/` with ~40 test files using custom test runner
- Existing scenes in `src/scenes/` for main menu, planting, combat, expedition summary, shop, inventory, settings

### Existing Code Quality Assessment
- **RNG Wrapper** (`rng_wrapper.gd`): Functional xorshift64* but extends Node (should be RefCounted). Algorithm reusable.
- **Seed** (`seed.gd`): Minimal — no phases, no element, no traits. Just growth_rate/rarity/age/matured.
- **DungeonGenerator** (`dungeon_generator.gd`): Spatial room placement with overlap detection. 135 lines. Works but is overkill for abstract room graphs.
- **Adventurer** (`adventurer.gd`): Basic stats + XP. Uses `class_name_str` string instead of enum. No level tiers.
- **CombatManager** (`combat_manager.gd`): Very simple alternating-turn combat. No speed ordering, no class abilities.
- **LootTable** (`loot_table.gd`): Weighted sampling works. Has a bug: `s.empty()` should be `s.is_empty()` (Godot 4 API).
- **Inventory** (`inventory.gd`): Simple item_id→qty dictionary. Functional but no integration with item database.
- **SaveManager** (`save_manager.gd`): Single slot only, no versioning, no corruption handling.
- **LoopController** (`loop_controller.gd`): Tick-based expedition with simple completion. No room-by-room resolution.
- **UI Scenes**: Basic button→action patterns. Planting UI, shop, inventory, expedition summary, settings (with accessibility).

### Patterns to Follow
- All data models: extend `RefCounted`, provide `to_dict()`/`from_dict()` for serialization
- All managers: extend `Node` for scene tree integration, registered as autoloads
- All services: extend `RefCounted`, stateless computation
- Use `class_name` for all scripts for type safety
- Use `EventBus` autoload for cross-system communication (decouple systems)
- Tests: simple assert-based in `tests/unit/`, integration tests in `tests/integration/`

### Key Conventions
- File naming: `snake_case.gd`
- Class naming: `PascalCase`
- Enum naming: `UPPER_SNAKE_CASE` for values, `PascalCase` for enum names
- All tuning constants in `GameConfig` — never hardcoded in logic
- Deterministic RNG for all game-affecting randomness (reproducible expeditions)
