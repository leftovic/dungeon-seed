# TASK-006: Adventurer Data Model & Class Definitions

---

## 1. Header

| Field                | Value                                                                                   |
| -------------------- | --------------------------------------------------------------------------------------- |
| **Task ID**          | TASK-006                                                                                |
| **Title**            | Adventurer Data Model & Class Definitions                                               |
| **Epic**             | Dungeon Seed                                                                            |
| **Stream**           | 🔴 MCH (Mechanics) — Primary                                                           |
| **Cross-Stream**     | 🔵 VIS (class portraits/sprites), 🟣 NAR (class lore text), ⚪ TCH (serialization)     |
| **Complexity**       | 5 points (Moderate)                                                                     |
| **Wave**             | 2                                                                                       |
| **Dependencies**     | TASK-003 (Enums & Constants)                                                            |
| **Dependents**       | TASK-013 (Roster), TASK-014 (Equipment), TASK-015 (Expedition Resolver)                 |
| **Critical Path**    | ❌ No                                                                                   |
| **Engine**           | Godot 4.6                                                                               |
| **Language**         | GDScript (static typing enforced)                                                       |
| **Target File**      | `src/models/adventurer_data.gd`                                                         |
| **Test File**        | `tests/models/test_adventurer_data.gd`                                                  |
| **Config Additions** | `src/config/game_config.gd` — `BASE_STATS`, `XP_PER_TIER`, `XP_CURVE`                  |
| **GDD Reference**    | §4.3 — Adventurer System                                                                |
| **Author**           | Copilot                                                                                 |
| **Status**           | Draft                                                                                   |
| **Created**          | 2025-07-15                                                                              |

---

## 2. Description

### 2.1 Overview

TASK-006 defines the core data model for adventurers in Dungeon Seed. Adventurers are the primary
player-controlled agents dispatched into cultivated dungeons. Each adventurer belongs to one of six
distinct classes, carries a set of five base stats shaped by that class, gains experience through
dungeon expeditions, advances through four level tiers, and equips items across three equipment
slots. This task creates the `AdventurerData` class — a pure data container extending `RefCounted`
— along with all supporting configuration constants required to instantiate, level, tier, serialize,
and deserialize adventurer records.

This is a **model-layer** task. It produces no UI, no scene tree nodes, no signals to the game loop.
It is a self-contained, deterministic, fully testable data class that downstream systems (roster
management, equipment, expedition resolution) consume through its public API.

### 2.2 Motivation

The adventurer is the central player-facing entity in Dungeon Seed's dungeon-crawling loop. Every
expedition dispatches a party of adventurers. Every reward screen shows their XP gains. Every roster
screen lists their stats and equipment. Without a rigorous, well-tested data model, every downstream
system inherits ambiguity and coupling risk. By isolating the adventurer's data shape, validation
rules, leveling math, and serialization contract into a single `RefCounted` class, we guarantee:

- **Deterministic behavior**: Given the same inputs, `gain_xp()` always produces the same level and
  tier transitions, regardless of which system calls it.
- **Serialization safety**: `to_dict()` and `from_dict()` form a lossless round-trip contract that
  save/load, network sync, and undo/redo systems can depend on.
- **Stat isolation**: `get_effective_stats()` is the single source of truth for an adventurer's
  combat-ready statistics, preventing ad-hoc stat math from scattering across the codebase.
- **Class identity**: The six adventurer classes are defined once in `GameConfig.BASE_STATS` and
  never duplicated in UI code, AI code, or balance spreadsheets.

### 2.3 Scope of Work

This task produces exactly three artifacts:

1. **`src/models/adventurer_data.gd`** — The `AdventurerData` class (extends `RefCounted`,
   `class_name AdventurerData`). Contains all properties, computed properties, mutation methods,
   query methods, and serialization methods described in this ticket.

2. **`src/config/game_config.gd` additions** — Three new constant dictionaries added to the
   existing `GameConfig` autoload:
   - `BASE_STATS`: Maps `Enums.AdventurerClass` → `Dictionary` of five base stats.
   - `XP_PER_TIER`: Maps `Enums.LevelTier` → cumulative XP threshold for that tier.
   - `XP_CURVE`: Contains the exponential XP scaling parameters used by `xp_to_next_level()`.

3. **`tests/models/test_adventurer_data.gd`** — A comprehensive GUT test suite covering
   construction, class stat verification, XP gain, level-up, tier transitions, stat queries,
   serialization round-trips, edge cases, and error handling.

### 2.4 Adventurer Data Shape

An `AdventurerData` instance holds the following persistent state:

| Property           | Type                       | Default            | Notes                                  |
| ------------------ | -------------------------- | ------------------ | -------------------------------------- |
| `id`               | `String`                   | `""`               | UUID assigned at creation              |
| `display_name`     | `String`                   | `""`               | Player-visible name                    |
| `adventurer_class` | `Enums.AdventurerClass`    | `WARRIOR`          | Immutable after creation               |
| `level`            | `int`                      | `1`                | Current level (1+)                     |
| `xp`               | `int`                      | `0`                | XP within current level                |
| `stats`            | `Dictionary`               | Class base stats   | `{health, attack, defense, speed, utility}` |
| `equipment`        | `Dictionary`               | All slots `null`   | `{weapon: null, armor: null, accessory: null}` |
| `is_available`     | `bool`                     | `true`             | `false` when on active expedition      |

Computed (not stored):

| Property           | Type                       | Derivation                                |
| ------------------ | -------------------------- | ----------------------------------------- |
| `level_tier`       | `Enums.LevelTier`          | Derived from `level` via tier boundaries  |
| `effective_stats`  | `Dictionary`               | `stats` + equipment bonuses (placeholder) |

### 2.5 Class Definitions — Base Stat Distributions

Per GDD §4.3, each adventurer class has a distinct stat profile that defines its role:

| Class        | Health | Attack | Defense | Speed | Utility | Total | Role      |
| ------------ | ------ | ------ | ------- | ----- | ------- | ----- | --------- |
| **Warrior**  | 120    | 18     | 15      | 8     | 5       | 166   | Guardian  |
| **Ranger**   | 85     | 14     | 8       | 18    | 10      | 135   | Scout     |
| **Mage**     | 70     | 12     | 6       | 10    | 20      | 118   | Carry     |
| **Rogue**    | 80     | 15     | 7       | 16    | 14      | 132   | Scout     |
| **Alchemist**| 90     | 10     | 10      | 12    | 18      | 140   | Support   |
| **Sentinel** | 140    | 8      | 20      | 5     | 8       | 181   | Guardian  |

Design intent: Stat totals are intentionally unequal. Classes with lower totals (Mage: 118) gain
disproportionate value from their high-ceiling stats (Utility: 20 enables powerful spell effects in
the expedition resolver). Classes with higher totals (Sentinel: 181) are stat-efficient but
one-dimensional. Balance is achieved through the expedition resolver's encounter mechanics, not
through raw stat parity.

### 2.6 Leveling System

Adventurers gain XP from completed dungeon expeditions. When accumulated XP meets or exceeds the
threshold for the next level, the adventurer levels up. Multiple level-ups from a single XP grant
are supported (e.g., a large XP reward can push an adventurer through two or more levels).

**XP-to-next-level formula** (exponential curve):

```
xp_to_next_level = BASE_XP * (GROWTH_RATE ^ (level - 1))
```

Where:
- `BASE_XP = 100` — XP required from level 1 → level 2.
- `GROWTH_RATE = 1.15` — Each subsequent level requires 15% more XP than the previous.

Examples:
- Level 1 → 2: 100 XP
- Level 2 → 3: 115 XP
- Level 5 → 6: 152 XP (entering Skilled tier)
- Level 10 → 11: 304 XP (entering Veteran tier)
- Level 15 → 16: 614 XP (entering Elite tier)

**Level tier boundaries**:

| Tier       | Level Range | Cumulative XP (approx.) | Milestone                    |
| ---------- | ----------- | ----------------------- | ---------------------------- |
| Novice     | 1 – 5       | 0 – 549                | Starting tier                |
| Skilled    | 6 – 10      | 550 – 1,649             | Unlocks advanced equipment   |
| Veteran    | 11 – 15     | 1,650 – 3,899           | Unlocks elite dungeons       |
| Elite      | 16+         | 3,900+                  | Endgame tier                 |

### 2.7 Serialization Contract

`to_dict()` produces a plain `Dictionary` suitable for JSON serialization via Godot's built-in
`JSON.stringify()`. `from_dict()` is a static factory that reconstructs an `AdventurerData` from
such a dictionary. The round-trip contract is:

```
var original: AdventurerData = create_test_adventurer()
var dict: Dictionary = original.to_dict()
var restored: AdventurerData = AdventurerData.from_dict(dict)
assert(original.to_dict() == restored.to_dict())  # Lossless round-trip
```

Dictionary schema:

```json
{
  "id": "uuid-string",
  "display_name": "Aldric",
  "adventurer_class": 0,
  "level": 5,
  "xp": 42,
  "stats": { "health": 120, "attack": 18, "defense": 15, "speed": 8, "utility": 5 },
  "equipment": { "weapon": null, "armor": null, "accessory": null },
  "is_available": true
}
```

Note: `adventurer_class` is serialized as its integer enum value for JSON compatibility. `from_dict`
casts it back to `Enums.AdventurerClass`. Equipment slot keys are serialized as string names, not
enum integers, for human readability in save files.

### 2.8 Integration Points

This model is consumed by three direct downstream tasks:

- **TASK-013 (Roster Manager)**: Maintains a collection of `AdventurerData` instances. Calls
  `is_available`, iterates by class, filters by tier.
- **TASK-014 (Equipment System)**: Reads and writes `equipment` dictionary. Calls
  `get_effective_stats()` to compute combat stats with gear bonuses applied.
- **TASK-015 (Expedition Resolver)**: Reads `get_effective_stats()`, `adventurer_class`, and
  `level_tier` to resolve dungeon encounters. Calls `gain_xp()` on expedition completion.

### 2.9 What This Task Does NOT Do

This task explicitly excludes:

- UI rendering of adventurer cards, portraits, or stat bars.
- Signal emission for level-up events (TASK-013 wraps this).
- Equipment item definitions (TASK-014 defines `EquipmentData`).
- Stat growth per level (stats are base-only in this task; per-level scaling is a future task).
- Party composition validation (TASK-015 handles synergy checks).
- Name generation (TASK-013 provides a name pool).
- Adventurer recruitment/dismissal logic (TASK-013).

---

## 3. Use Cases

### UC-01: Creating a New Adventurer on Recruitment

**Actor**: Roster Manager (TASK-013)
**Trigger**: Player selects "Recruit" from the guild hall and picks a class.
**Preconditions**: TASK-003 enums are loaded. `GameConfig.BASE_STATS` is populated.

**Flow**:
1. Roster Manager generates a UUID via `ResourceUID` or custom utility.
2. Roster Manager selects a random display name from the name pool.
3. Roster Manager instantiates `AdventurerData.new()`.
4. Roster Manager calls `adventurer.id = generated_uuid`.
5. Roster Manager calls `adventurer.display_name = selected_name`.
6. Roster Manager calls `adventurer.adventurer_class = Enums.AdventurerClass.MAGE` (or chosen class).
7. Roster Manager calls `adventurer.initialize_base_stats()` which copies base stats from
   `GameConfig.BASE_STATS[adventurer_class]` into the `stats` dictionary.
8. The new adventurer is level 1, has 0 XP, no equipment, and `is_available = true`.
9. Roster Manager adds the adventurer to its internal roster array.

**Postconditions**: A fully initialized `AdventurerData` exists in the roster with correct base
stats for the chosen class, level 1, Novice tier, empty equipment, and available status.

**Error Paths**:
- If an invalid enum value is somehow passed, `initialize_base_stats()` logs an error and falls
  back to Warrior stats to prevent a null-stats adventurer from entering the roster.

### UC-02: Gaining XP After an Expedition

**Actor**: Expedition Resolver (TASK-015)
**Trigger**: An expedition completes and XP rewards are distributed to surviving adventurers.
**Preconditions**: Adventurer exists in roster with `is_available = false` (on expedition).

**Flow**:
1. Expedition Resolver calculates XP reward per adventurer (e.g., 250 XP).
2. Expedition Resolver calls `adventurer.gain_xp(250)`.
3. `gain_xp()` adds 250 to `xp`.
4. `gain_xp()` enters a while loop: while `xp >= xp_to_next_level()`:
   a. `xp -= xp_to_next_level()` (consume the threshold).
   b. `level += 1`.
   c. Set `leveled_up = true`.
5. The method returns `true` because at least one level-up occurred.
6. Expedition Resolver marks `adventurer.is_available = true`.
7. Expedition Resolver emits a signal with the adventurer and the `leveled_up` boolean so the UI
   can display a level-up fanfare.

**Postconditions**: Adventurer's `xp` reflects the remainder after level-ups. `level` is correctly
incremented. `level_tier` (computed) may have changed if a tier boundary was crossed.

**Edge Case — Multi-Level-Up**: If the adventurer is level 1 with 0 XP and gains 500 XP:
- Level 1→2 costs 100 XP. Remaining: 400 XP.
- Level 2→3 costs 115 XP. Remaining: 285 XP.
- Level 3→4 costs 132 XP. Remaining: 153 XP.
- Level 4→5 costs 152 XP. Remaining: 1 XP.
- Final state: level 5, xp = 1, tier = Novice.

### UC-03: Saving and Loading Adventurer State

**Actor**: Save/Load System (future task)
**Trigger**: Player saves the game or autosave fires.
**Preconditions**: One or more `AdventurerData` instances exist in the roster.

**Flow**:
1. Save system iterates over the roster's adventurer array.
2. For each adventurer, calls `adventurer.to_dict()`.
3. Collects all dictionaries into an array.
4. Serializes the array via `JSON.stringify()` and writes to disk.
5. On load, reads the JSON string, parses via `JSON.parse_string()`.
6. For each dictionary in the parsed array, calls `AdventurerData.from_dict(dict)`.
7. The reconstructed `AdventurerData` instances are added to the roster.

**Postconditions**: All adventurer state is preserved: id, name, class, level, xp, stats,
equipment, and availability. The round-trip is lossless — `to_dict()` on a restored adventurer
produces a dictionary identical to the one that was saved.

**Error Paths**:
- If a dict is missing a required key, `from_dict()` logs a warning and uses a default value for
  that field, ensuring partial data recovery rather than a hard crash.
- If `adventurer_class` contains an out-of-range integer, `from_dict()` defaults to `WARRIOR` and
  logs an error.

### UC-04: Querying Effective Stats for Combat Resolution

**Actor**: Expedition Resolver (TASK-015)
**Trigger**: An encounter begins during an expedition and the resolver needs combat stats.
**Preconditions**: Adventurer has base stats set. Equipment may or may not be populated.

**Flow**:
1. Expedition Resolver calls `adventurer.get_effective_stats()`.
2. `get_effective_stats()` starts with a deep copy of `stats` (base stats).
3. For each equipment slot, if the slot is not null, the method would add equipment bonuses to the
   corresponding stats. (In this task, equipment bonus resolution is a placeholder that returns
   base stats unmodified — TASK-014 implements the actual lookup.)
4. The resolver uses the returned dictionary to calculate damage, defense rolls, speed order, etc.

**Postconditions**: A fresh `Dictionary` with five stat keys is returned. The original `stats`
dictionary is never mutated by this call.

---

## 4. Glossary

| #  | Term                  | Definition                                                                                                     |
| -- | --------------------- | -------------------------------------------------------------------------------------------------------------- |
| 1  | **AdventurerData**    | The GDScript `RefCounted` class defined by this task. Holds all persistent state for one adventurer.            |
| 2  | **Adventurer Class**  | One of six combat specializations (Warrior, Ranger, Mage, Rogue, Alchemist, Sentinel) that determines base stat distribution and role. |
| 3  | **Base Stats**        | The five core attributes (health, attack, defense, speed, utility) assigned at creation from `GameConfig.BASE_STATS`. |
| 4  | **Effective Stats**   | Base stats plus all bonuses from equipment, buffs, and modifiers. The combat-ready stat block.                  |
| 5  | **Level**             | An integer (1+) representing the adventurer's experience progression. Increases when XP meets the threshold.    |
| 6  | **Level Tier**        | A coarse-grained progression bracket (Novice, Skilled, Veteran, Elite) derived from the adventurer's level.     |
| 7  | **XP (Experience)**   | Integer points accumulated from dungeon expeditions. Resets to remainder after each level-up.                   |
| 8  | **XP Threshold**      | The XP cost to advance from the current level to the next. Computed via exponential curve.                      |
| 9  | **Equipment Slot**    | One of three positions (weapon, armor, accessory) where an item can be attached to an adventurer.               |
| 10 | **RefCounted**        | Godot's base class for reference-counted objects. Used for pure data models that don't need scene tree access.  |
| 11 | **class_name**        | GDScript keyword that registers a class globally, allowing `ClassName.new()` without `preload()`.               |
| 12 | **Serialization**     | The process of converting an `AdventurerData` instance to a plain `Dictionary` via `to_dict()`.                 |
| 13 | **Deserialization**   | The process of reconstructing an `AdventurerData` from a `Dictionary` via the static `from_dict()` method.      |
| 14 | **Round-Trip**        | The guarantee that `from_dict(to_dict(x))` produces an object whose `to_dict()` equals the original dict.      |
| 15 | **GameConfig**        | The project-wide autoload singleton that holds game-balance constants (base stats, XP curves, tier thresholds). |
| 16 | **GUT**               | Godot Unit Test framework. The testing framework used for all Dungeon Seed automated tests.                     |
| 17 | **Expedition**        | A dungeon run where a party of adventurers is dispatched to clear rooms and earn rewards.                       |
| 18 | **Roster**            | The player's collection of recruited adventurers, managed by TASK-013.                                          |
| 19 | **Stat Total**        | The sum of all five base stats for a given class. Intentionally varies per class for balance.                   |
| 20 | **UUID**              | Universally Unique Identifier. A string used to uniquely identify each adventurer instance.                     |

---

## 5. Out of Scope

The following items are explicitly **not** part of TASK-006. Each is either handled by a downstream
task or deferred to a future milestone. Any implementation work that touches these areas must be
rejected during code review.

| #  | Out-of-Scope Item                         | Reason / Owner                                                        |
| -- | ----------------------------------------- | --------------------------------------------------------------------- |
| 1  | **Adventurer UI / portraits / sprites**   | 🔵 VIS stream. TASK-020+ handles adventurer card rendering.           |
| 2  | **Equipment item definitions**            | TASK-014 defines `EquipmentData` and the item database.               |
| 3  | **Equipment bonus calculation**           | TASK-014. `get_effective_stats()` is a placeholder returning base.    |
| 4  | **Roster management (add/remove/filter)** | TASK-013 wraps `AdventurerData[]` with roster logic.                  |
| 5  | **Party composition & synergy bonuses**   | TASK-015. Party-level bonuses are not adventurer-level concerns.       |
| 6  | **Name generation / name pool**           | TASK-013 provides the name pool. This task accepts any string.        |
| 7  | **Signal emission for level-up events**   | TASK-013 wraps `gain_xp()` calls and emits roster-level signals.      |
| 8  | **Stat growth per level**                 | Future task. Stats are base-only in TASK-006. Level-up scaling is a balance feature deferred to vertical slice. |
| 9  | **Adventurer death / permadeath**         | Future task. `AdventurerData` has no `is_alive` flag yet.             |
| 10 | **Skill / ability system**                | Future milestone. Not referenced in TASK-006 data model.              |
| 11 | **Adventurer AI behavior in dungeons**    | TASK-015 expedition resolver handles all combat AI.                   |
| 12 | **Class lore text / flavor descriptions** | 🟣 NAR stream. Lore is not stored on `AdventurerData`.               |
| 13 | **Adventurer animation / VFX**            | 🔵 VIS stream. Pure data model has no visual representation.          |
| 14 | **Multiplayer / network sync of state**   | Not in scope for Dungeon Seed v1.                                     |
| 15 | **Undo/redo for adventurer mutations**    | Future consideration. Command pattern is not implemented here.        |

---

## 6. Functional Requirements

### 6.1 Class Definition & Construction

| ID      | Requirement                                                                                              | Priority |
| ------- | -------------------------------------------------------------------------------------------------------- | -------- |
| FR-001  | `AdventurerData` SHALL extend `RefCounted`.                                                              | P0       |
| FR-002  | `AdventurerData` SHALL declare `class_name AdventurerData`.                                              | P0       |
| FR-003  | `AdventurerData` SHALL expose property `id: String` initialized to `""`.                                 | P0       |
| FR-004  | `AdventurerData` SHALL expose property `display_name: String` initialized to `""`.                       | P0       |
| FR-005  | `AdventurerData` SHALL expose property `adventurer_class: Enums.AdventurerClass` initialized to `WARRIOR`. | P0     |
| FR-006  | `AdventurerData` SHALL expose property `level: int` initialized to `1`.                                  | P0       |
| FR-007  | `AdventurerData` SHALL expose property `xp: int` initialized to `0`.                                    | P0       |
| FR-008  | `AdventurerData` SHALL expose property `stats: Dictionary` initialized to an empty dictionary.           | P0       |
| FR-009  | `AdventurerData` SHALL expose property `equipment: Dictionary` initialized to `{ "weapon": null, "armor": null, "accessory": null }`. | P0 |
| FR-010  | `AdventurerData` SHALL expose property `is_available: bool` initialized to `true`.                       | P0       |

### 6.2 Base Stats & Initialization

| ID      | Requirement                                                                                              | Priority |
| ------- | -------------------------------------------------------------------------------------------------------- | -------- |
| FR-011  | `AdventurerData` SHALL provide method `initialize_base_stats() -> void` that copies base stats from `GameConfig.BASE_STATS[adventurer_class]` into `stats`. | P0 |
| FR-012  | `GameConfig.BASE_STATS` SHALL contain entries for all six `Enums.AdventurerClass` values.                | P0       |
| FR-013  | Warrior base stats SHALL be `{ health: 120, attack: 18, defense: 15, speed: 8, utility: 5 }`.           | P0       |
| FR-014  | Ranger base stats SHALL be `{ health: 85, attack: 14, defense: 8, speed: 18, utility: 10 }`.            | P0       |
| FR-015  | Mage base stats SHALL be `{ health: 70, attack: 12, defense: 6, speed: 10, utility: 20 }`.              | P0       |
| FR-016  | Rogue base stats SHALL be `{ health: 80, attack: 15, defense: 7, speed: 16, utility: 14 }`.             | P0       |
| FR-017  | Alchemist base stats SHALL be `{ health: 90, attack: 10, defense: 10, speed: 12, utility: 18 }`.        | P0       |
| FR-018  | Sentinel base stats SHALL be `{ health: 140, attack: 8, defense: 20, speed: 5, utility: 8 }`.           | P0       |
| FR-019  | Each class's base stats SHALL contain exactly five keys: `health`, `attack`, `defense`, `speed`, `utility`. | P0    |
| FR-020  | All base stat values SHALL be positive integers greater than zero.                                        | P0       |

### 6.3 Leveling & XP

| ID      | Requirement                                                                                              | Priority |
| ------- | -------------------------------------------------------------------------------------------------------- | -------- |
| FR-021  | `AdventurerData` SHALL provide method `gain_xp(amount: int) -> bool`.                                   | P0       |
| FR-022  | `gain_xp()` SHALL add `amount` to `xp`, then process level-ups in a loop until `xp < xp_to_next_level()`. | P0    |
| FR-023  | `gain_xp()` SHALL return `true` if at least one level-up occurred, `false` otherwise.                   | P0       |
| FR-024  | `gain_xp()` SHALL support multi-level-ups from a single call (while loop, not if).                      | P0       |
| FR-025  | `gain_xp()` SHALL NOT accept negative amounts. If `amount <= 0`, return `false` immediately.            | P1       |
| FR-026  | `AdventurerData` SHALL provide method `xp_to_next_level() -> int`.                                      | P0       |
| FR-027  | `xp_to_next_level()` SHALL return `int(GameConfig.XP_CURVE.BASE_XP * pow(GameConfig.XP_CURVE.GROWTH_RATE, level - 1))`. | P0 |
| FR-028  | `GameConfig.XP_CURVE` SHALL define `BASE_XP = 100` and `GROWTH_RATE = 1.15`.                            | P0       |
| FR-029  | After a level-up, `xp` SHALL contain the remainder (excess XP beyond the threshold).                    | P0       |
| FR-030  | `level` SHALL never decrease.                                                                            | P0       |

### 6.4 Level Tiers

| ID      | Requirement                                                                                              | Priority |
| ------- | -------------------------------------------------------------------------------------------------------- | -------- |
| FR-031  | `AdventurerData` SHALL provide method `get_level_tier() -> Enums.LevelTier`.                             | P0       |
| FR-032  | Levels 1–5 SHALL return `Enums.LevelTier.NOVICE`.                                                       | P0       |
| FR-033  | Levels 6–10 SHALL return `Enums.LevelTier.SKILLED`.                                                     | P0       |
| FR-034  | Levels 11–15 SHALL return `Enums.LevelTier.VETERAN`.                                                    | P0       |
| FR-035  | Levels 16+ SHALL return `Enums.LevelTier.ELITE`.                                                        | P0       |
| FR-036  | `GameConfig.XP_PER_TIER` SHALL map `NOVICE: 0, SKILLED: 100, VETERAN: 350, ELITE: 750`.                 | P1       |

### 6.5 Stats Query

| ID      | Requirement                                                                                              | Priority |
| ------- | -------------------------------------------------------------------------------------------------------- | -------- |
| FR-037  | `AdventurerData` SHALL provide method `get_effective_stats() -> Dictionary`.                              | P0       |
| FR-038  | `get_effective_stats()` SHALL return a new `Dictionary` (deep copy), never a reference to `stats`.       | P0       |
| FR-039  | In TASK-006, `get_effective_stats()` SHALL return base stats only (equipment bonuses are a placeholder). | P0       |
| FR-040  | The returned dictionary SHALL contain exactly five keys: `health`, `attack`, `defense`, `speed`, `utility`. | P0    |

### 6.6 Serialization

| ID      | Requirement                                                                                              | Priority |
| ------- | -------------------------------------------------------------------------------------------------------- | -------- |
| FR-041  | `AdventurerData` SHALL provide method `to_dict() -> Dictionary`.                                         | P0       |
| FR-042  | `to_dict()` SHALL serialize `adventurer_class` as its integer enum value.                                | P0       |
| FR-043  | `to_dict()` SHALL serialize equipment slot keys as strings (`"weapon"`, `"armor"`, `"accessory"`).       | P0       |
| FR-044  | `AdventurerData` SHALL provide static method `from_dict(data: Dictionary) -> AdventurerData`.            | P0       |
| FR-045  | `from_dict()` SHALL cast the integer `adventurer_class` value back to `Enums.AdventurerClass`.           | P0       |
| FR-046  | `from_dict(to_dict(x)).to_dict()` SHALL equal `x.to_dict()` for any valid `AdventurerData x`.           | P0       |
| FR-047  | `from_dict()` SHALL use default values for any missing keys, logging a warning per missing key.          | P1       |
| FR-048  | `to_dict()` SHALL produce a dictionary compatible with `JSON.stringify()`.                                | P0       |

---

## 7. Non-Functional Requirements

| ID       | Category        | Requirement                                                                                           | Target          |
| -------- | --------------- | ----------------------------------------------------------------------------------------------------- | --------------- |
| NFR-001  | Performance     | `AdventurerData.new()` SHALL complete in under 1 ms.                                                  | < 1 ms          |
| NFR-002  | Performance     | `gain_xp()` for a single level-up SHALL complete in under 0.1 ms.                                    | < 0.1 ms        |
| NFR-003  | Performance     | `to_dict()` and `from_dict()` SHALL each complete in under 0.5 ms.                                   | < 0.5 ms        |
| NFR-004  | Performance     | `get_effective_stats()` SHALL complete in under 0.1 ms.                                               | < 0.1 ms        |
| NFR-005  | Memory          | A single `AdventurerData` instance SHALL consume less than 2 KB of memory.                            | < 2 KB          |
| NFR-006  | Memory          | A roster of 100 adventurers SHALL consume less than 200 KB total.                                     | < 200 KB        |
| NFR-007  | Determinism     | All methods SHALL be deterministic — identical inputs always produce identical outputs.                | 100%            |
| NFR-008  | Determinism     | No method SHALL depend on frame time, global state, or random number generators.                      | 100%            |
| NFR-009  | Portability     | `AdventurerData` SHALL have zero scene tree dependencies. It SHALL NOT call `get_tree()`, `get_node()`, or access any `Node`. | Zero deps |
| NFR-010  | Portability     | `AdventurerData` SHALL only depend on `Enums` (TASK-003) and `GameConfig` autoload.                  | 2 deps max      |
| NFR-011  | Testability     | All public methods SHALL be testable without instantiating any `Node` or `SceneTree`.                 | 100%            |
| NFR-012  | Code Quality    | All properties and method parameters SHALL use static type hints.                                     | 100%            |
| NFR-013  | Code Quality    | All methods SHALL use `snake_case` naming per GDScript conventions.                                   | 100%            |
| NFR-014  | Code Quality    | The file SHALL contain no `@onready`, `@export`, or signal declarations.                              | Zero            |
| NFR-015  | Compatibility   | Serialized dictionaries SHALL be forward-compatible — future fields added with defaults.              | Additive only   |
| NFR-016  | Compatibility   | `from_dict()` SHALL tolerate missing keys by using defaults, never crashing.                          | Zero crashes    |
| NFR-017  | Maintainability | All magic numbers SHALL be defined in `GameConfig` constants, not inline.                             | Zero magic nums |
| NFR-018  | Maintainability | The `AdventurerData` class SHALL be under 200 lines of code (excluding comments).                    | < 200 LOC       |

---

## 8. Designer's Manual

### 8.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     GameConfig (Autoload)                    │
│  ┌───────────────┐  ┌───────────────┐  ┌─────────────────┐  │
│  │  BASE_STATS   │  │  XP_PER_TIER  │  │    XP_CURVE     │  │
│  │ {Class→Stats} │  │ {Tier→Thresh} │  │ {BASE, GROWTH}  │  │
│  └───────┬───────┘  └───────┬───────┘  └────────┬────────┘  │
└──────────┼──────────────────┼───────────────────┼────────────┘
           │                  │                   │
           ▼                  ▼                   ▼
┌─────────────────────────────────────────────────────────────┐
│                    AdventurerData (RefCounted)               │
│                                                             │
│  Properties:                                                │
│    id: String                                               │
│    display_name: String                                     │
│    adventurer_class: Enums.AdventurerClass                  │
│    level: int                                               │
│    xp: int                                                  │
│    stats: Dictionary                                        │
│    equipment: Dictionary                                    │
│    is_available: bool                                       │
│                                                             │
│  Methods:                                                   │
│    initialize_base_stats() → void                           │
│    gain_xp(amount) → bool                                   │
│    xp_to_next_level() → int                                 │
│    get_level_tier() → Enums.LevelTier                       │
│    get_effective_stats() → Dictionary                        │
│    to_dict() → Dictionary                                   │
│    from_dict(data) → AdventurerData  [static]               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
           │                  │                   │
           ▼                  ▼                   ▼
   ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐
   │  TASK-013    │  │  TASK-014    │  │    TASK-015      │
   │  Roster Mgr  │  │  Equipment   │  │  Expedition Res  │
   └──────────────┘  └──────────────┘  └──────────────────┘
```

### 8.2 File Layout

The implementation file follows a strict section order:

```
# src/models/adventurer_data.gd
#
# Section 1: class_name and extends
# Section 2: Constants (if any local to this file)
# Section 3: Properties (typed, with defaults)
# Section 4: Initialization methods
# Section 5: XP & Leveling methods
# Section 6: Stat query methods
# Section 7: Serialization methods
```

### 8.3 Property Design Decisions

**Why `stats` is a Dictionary, not individual properties:**
Using `stats.health`, `stats.attack`, etc. instead of `var health: int`, `var attack: int` enables:
- Generic stat iteration: `for stat_name in stats:` to display stat bars without hardcoding names.
- Equipment bonus application: `for stat in bonus: effective[stat] += bonus[stat]` without a switch.
- Future stat additions (e.g., `luck`) without changing the class interface.
- Serialization that naturally handles the entire stat block as one unit.

The tradeoff is loss of property-level type safety. We mitigate this by validating stat dictionary
shape in `initialize_base_stats()` and `from_dict()`.

**Why `equipment` uses string keys, not `Enums.EquipSlot` keys:**
GDScript dictionaries with enum keys serialize to JSON with integer keys, which are less readable in
save files and harder to debug. String keys (`"weapon"`, `"armor"`, `"accessory"`) serialize
cleanly and are still type-safe at access time when wrapped by TASK-014's equipment methods.

**Why `is_available` lives on AdventurerData, not on the Roster:**
Availability is intrinsic to the adventurer's current state. When serializing an adventurer, the
availability flag must travel with it. If it lived on the roster, a deserialized adventurer would
lose its expedition status. The adventurer knows whether it's busy; the roster merely queries it.

### 8.4 Leveling System Deep Dive

The XP curve is deliberately exponential to create natural pacing:

```
Level  | XP Required | Cumulative XP | Tier
-------|-------------|---------------|--------
 1→2   |    100      |      100      | Novice
 2→3   |    115      |      215      | Novice
 3→4   |    132      |      347      | Novice
 4→5   |    152      |      499      | Novice
 5→6   |    174      |      673      | → Skilled
 6→7   |    201      |      874      | Skilled
 7→8   |    231      |    1,105      | Skilled
 8→9   |    265      |    1,370      | Skilled
 9→10  |    305      |    1,675      | Skilled
10→11  |    351      |    2,026      | → Veteran
11→12  |    403      |    2,429      | Veteran
12→13  |    464      |    2,893      | Veteran
13→14  |    533      |    3,426      | Veteran
14→15  |    613      |    4,039      | Veteran
15→16  |    705      |    4,744      | → Elite
```

Each level requires ~15% more XP than the previous. This means early levels fly by (good for
onboarding), mid-levels require steady play, and endgame levels demand significant investment.

### 8.5 Tier Boundary Logic

The tier computation is a simple cascading if-else:

```
func get_level_tier() -> Enums.LevelTier:
    if level >= 16:
        return Enums.LevelTier.ELITE
    elif level >= 11:
        return Enums.LevelTier.VETERAN
    elif level >= 6:
        return Enums.LevelTier.SKILLED
    else:
        return Enums.LevelTier.NOVICE
```

Why not a lookup table? Because tier boundaries are simple, static, and unlikely to change. A
dictionary lookup would add indirection without benefit. If boundaries become dynamic (e.g., varies
per class), we would refactor to a table then.

### 8.6 Serialization Contract Details

The `to_dict()` / `from_dict()` contract is the most critical API in this class because it crosses
system boundaries (save/load, potential network, debug tools). Key design rules:

1. **Flat structure**: No nested `AdventurerData` references. Equipment stores `item_id` strings,
   not item objects. This prevents circular references and keeps JSON clean.
2. **Enum-as-int**: `adventurer_class` serializes as `int(adventurer_class)`. This is compact and
   stable as long as enum ordering doesn't change (enforced by TASK-003's enum stability guarantee).
3. **Missing-key tolerance**: `from_dict()` uses `.get(key, default)` for every field. A save file
   from an older version that lacks a newly added field will deserialize cleanly with the default.
4. **No version field yet**: Version migration is out of scope for TASK-006. When we add fields
   that require migration logic, a `"version": 1` field will be added.

### 8.7 How Downstream Tasks Consume This Model

**TASK-013 (Roster Manager)** will:
- Maintain an `Array[AdventurerData]`.
- Provide `get_available_adventurers() -> Array[AdventurerData]` filtering by `is_available`.
- Call `initialize_base_stats()` on newly recruited adventurers.
- Call `to_dict()` / `from_dict()` for roster serialization.

**TASK-014 (Equipment System)** will:
- Define `EquipmentData` with stat bonuses.
- Override or extend `get_effective_stats()` to apply equipment bonuses.
- Read/write `equipment` dictionary slots.

**TASK-015 (Expedition Resolver)** will:
- Read `get_effective_stats()` for combat calculations.
- Read `adventurer_class` for synergy bonus computation.
- Read `get_level_tier()` for encounter difficulty scaling.
- Call `gain_xp()` on expedition completion.
- Toggle `is_available` before/after expeditions.

### 8.8 Extension Points

The `AdventurerData` class is designed with these future extensions in mind:

- **Stat growth per level**: Add a `stat_growth` dictionary to `GameConfig` per class. `gain_xp()`
  would apply growth on level-up. The `stats` dictionary already supports mutation.
- **Skills/abilities**: Add an `abilities: Array[String]` property. Serialization handles arrays.
- **Status effects**: Add a `status_effects: Array[Dictionary]` property. Transient (not saved).
- **Affinity/element**: Add to `Enums`, reference in `AdventurerData`. No structural change needed.

---

## 9. Assumptions

| #  | Assumption                                                                                                  | Impact if Wrong                                                    |
| -- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| 1  | TASK-003 provides `Enums.AdventurerClass` with values `WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL`. | Must update enum references if names differ.                       |
| 2  | TASK-003 provides `Enums.LevelTier` with values `NOVICE, SKILLED, VETERAN, ELITE`.                         | Must update tier logic if enum names differ.                       |
| 3  | TASK-003 provides `Enums.EquipSlot` with values `WEAPON, ARMOR, ACCESSORY`.                                | Must update equipment dictionary keys.                             |
| 4  | `GameConfig` exists as an autoload singleton accessible globally.                                           | Must create it or use a different constant-hosting pattern.         |
| 5  | Godot 4.6 supports `class_name` on `RefCounted` subclasses for global registration.                        | Must use `preload()` pattern instead if not supported.             |
| 6  | GDScript `pow()` returns `float`. We `int()` cast for XP thresholds.                                       | Rounding errors at very high levels. Acceptable for gameplay.      |
| 7  | Stat values are always positive integers. No stat can be zero or negative at base.                          | If zero stats are needed, validation logic must change.            |
| 8  | Equipment slots are fixed at three (weapon, armor, accessory) for the entire game.                          | Adding slots requires `equipment` dictionary and serialization update. |
| 9  | Level has no hard cap. Adventurers can theoretically level beyond 16.                                       | If a cap is needed, `gain_xp()` must early-return at the cap.     |
| 10 | XP is always a non-negative integer. Fractional XP is not supported.                                        | If fractional XP is needed, change `xp` to `float`.               |
| 11 | The save file format is JSON via Godot's `JSON` class.                                                      | Binary formats would bypass `to_dict()` contract.                  |
| 12 | No two adventurers share the same `id`. UUID uniqueness is the caller's responsibility.                     | Duplicate IDs would cause roster corruption.                       |
| 13 | `display_name` has no character limit enforced at the model level.                                           | UI truncation is the UI layer's concern.                           |
| 14 | The GUT testing framework is available and configured in the project.                                        | Tests cannot run without GUT.                                      |

---

## 10. Security & Anti-Cheat

### Threat 1: Save File XP Manipulation

**Threat**: Player edits the JSON save file to set `xp` to 999999 or `level` to 100.
**Impact**: Adventurer becomes overpowered, trivializing all dungeon content.
**Mitigation**:
- `from_dict()` validates that `level >= 1`. Values below 1 are clamped to 1.
- `from_dict()` validates that `xp >= 0`. Negative XP is clamped to 0.
- `from_dict()` validates that `xp < xp_to_next_level()` for the given level. If XP exceeds the
  threshold, it is clamped to `xp_to_next_level() - 1`.
- Future: Save file checksum/HMAC validation (out of scope for TASK-006).

### Threat 2: Save File Stat Tampering

**Threat**: Player edits `stats.attack` to 9999 in the save file.
**Impact**: Adventurer one-shots all enemies.
**Mitigation**:
- `from_dict()` validates each stat against `GameConfig.BASE_STATS` for the adventurer's class.
  In TASK-006, stats must exactly match base stats (no equipment bonuses are persistent). If a stat
  value differs from the expected base, it is reset to the base value and a warning is logged.
- Future tasks with stat growth will need a more nuanced validation (base + growth per level).

### Threat 3: Enum Value Injection

**Threat**: Player sets `adventurer_class` to an invalid integer (e.g., 99) in the save file.
**Impact**: `Enums.AdventurerClass` cast produces undefined behavior or crash.
**Mitigation**:
- `from_dict()` validates the integer is within the valid range `[0, Enums.AdventurerClass.size() - 1]`.
  Out-of-range values default to `WARRIOR` with an error log.

### Threat 4: Equipment Slot Injection

**Threat**: Player adds extra equipment slots in the save file (e.g., `"ring": "item_123"`).
**Impact**: Adventurer gains equipment bonuses from non-existent slots.
**Mitigation**:
- `from_dict()` only reads the three canonical slot keys (`"weapon"`, `"armor"`, `"accessory"`).
  Any extra keys in the equipment dictionary are silently discarded.

### Threat 5: ID Collision Attack

**Threat**: Player duplicates an adventurer's ID in the save file to create clones.
**Impact**: Roster has two adventurers with the same ID, causing equipment/expedition logic errors.
**Mitigation**:
- ID uniqueness enforcement is TASK-013's responsibility (roster-level validation on load).
- `AdventurerData` itself does not enforce uniqueness — it's a single-entity model.

---

## 11. Best Practices

| #  | Practice                                                                                                      |
| -- | ------------------------------------------------------------------------------------------------------------- |
| 1  | **Always call `initialize_base_stats()` after setting `adventurer_class`**. Constructing an `AdventurerData` and forgetting to initialize stats is the #1 integration bug. |
| 2  | **Never modify `stats` directly from outside the class**. Use the class's own methods or, for equipment, wait for TASK-014's `apply_equipment()`. |
| 3  | **Use `get_effective_stats()` for all combat/display calculations**, never raw `stats`. This ensures equipment bonuses are always included when TASK-014 is integrated. |
| 4  | **Check `is_available` before adding an adventurer to an expedition party**. Dispatching an unavailable adventurer is a logic error that the expedition resolver should reject. |
| 5  | **Use `to_dict()` / `from_dict()` for all persistence**, never `var2str()` or custom serialization. This keeps the contract centralized. |
| 6  | **Never store `AdventurerData` in a `Resource`**. It's `RefCounted`, not `Resource`. Attempting to `ResourceSaver.save()` it will fail silently. |
| 7  | **Pass `AdventurerData` by reference, not by value**. `RefCounted` objects are reference-counted. Assigning to a new variable does not copy — it shares the reference. |
| 8  | **Deep-copy via `from_dict(to_dict())` if you need an independent copy**. This is the sanctioned clone pattern. |
| 9  | **Log warnings, don't crash**. `from_dict()` handles malformed data by defaulting and logging, never by throwing or asserting in release builds. |
| 10 | **Keep GameConfig constants frozen after launch**. Changing `BASE_STATS` values between versions invalidates existing save files unless migration logic is added. |
| 11 | **Test tier boundaries explicitly**. Off-by-one errors at levels 5/6, 10/11, and 15/16 are the most common leveling bugs. Write tests for the exact boundary levels. |
| 12 | **Use `Enums.AdventurerClass` typed parameters in all APIs**, never raw integers. This prevents accidental class confusion. |
| 13 | **Validate stat dictionary shape after any mutation**. After any operation that modifies `stats`, assert all five keys are present and positive. |
| 14 | **Do not add signals to AdventurerData**. It's a pure data model. Event notification is the roster/manager layer's concern. |

---

## 12. Troubleshooting

### Issue 1: `initialize_base_stats()` Produces Empty Stats

**Symptom**: After calling `initialize_base_stats()`, `stats` is `{}` or missing keys.
**Root Cause**: `adventurer_class` was not set before calling `initialize_base_stats()`, so the
lookup in `GameConfig.BASE_STATS` used the default `WARRIOR` key, OR `GameConfig` is not loaded.
**Fix**:
1. Verify `adventurer_class` is set before calling `initialize_base_stats()`.
2. Verify `GameConfig` autoload is registered in `project.godot` under `[autoload]`.
3. Add a debug print: `print("Looking up class: ", adventurer_class)` before the lookup.

### Issue 2: `gain_xp()` Never Returns `true`

**Symptom**: After granting XP, `gain_xp()` returns `false` even though the adventurer should level.
**Root Cause**: The XP amount is less than `xp_to_next_level()`, OR `xp_to_next_level()` is
returning an unexpectedly large value due to misconfigured `GameConfig.XP_CURVE`.
**Fix**:
1. Print `xp_to_next_level()` and compare against the granted amount.
2. Verify `GameConfig.XP_CURVE.BASE_XP == 100` and `GameConfig.XP_CURVE.GROWTH_RATE == 1.15`.
3. Check that `level` is correct — a high level means a high threshold.

### Issue 3: Serialization Round-Trip Fails

**Symptom**: `from_dict(to_dict(x)).to_dict() != x.to_dict()`.
**Root Cause**: Float-to-int conversion in `xp_to_next_level()` or enum serialization mismatch.
**Fix**:
1. Print both dictionaries and diff them key by key.
2. Check that `adventurer_class` round-trips correctly (int → enum → int).
3. Check that `stats` values are all `int`, not `float` (JSON parse can produce floats).

### Issue 4: Level Tier Returns Wrong Value at Boundary

**Symptom**: Level 6 adventurer shows `NOVICE` instead of `SKILLED`.
**Root Cause**: Off-by-one in `get_level_tier()` — using `> 5` instead of `>= 6`.
**Fix**:
1. Verify `get_level_tier()` uses `>=` comparisons: `level >= 16`, `level >= 11`, `level >= 6`.
2. Run the tier boundary tests (AC-025 through AC-028) to catch the exact failure.

### Issue 5: `get_effective_stats()` Returns a Reference Instead of Copy

**Symptom**: Modifying the returned dictionary from `get_effective_stats()` also changes `stats`.
**Root Cause**: Returning `stats` directly instead of `stats.duplicate(true)`.
**Fix**:
1. Ensure `get_effective_stats()` calls `stats.duplicate(true)` (deep copy).
2. Write a test that mutates the returned dict and asserts `stats` is unchanged.

### Issue 6: JSON Parse Returns Float Stats

**Symptom**: After loading from JSON, `stats.health` is `120.0` (float) instead of `120` (int).
**Root Cause**: Godot's `JSON.parse_string()` returns all numbers as `float` by default.
**Fix**:
1. In `from_dict()`, explicitly cast each stat value to `int`: `int(data.stats.health)`.
2. Apply the same cast to `level`, `xp`, and `adventurer_class`.

### Issue 7: `from_dict()` Crashes on Missing Key

**Symptom**: `from_dict()` throws a "key not found" error when loading an old save file.
**Root Cause**: Accessing `data["new_field"]` instead of `data.get("new_field", default)`.
**Fix**:
1. Ensure every field access in `from_dict()` uses `.get(key, default)` pattern.
2. Add a test that calls `from_dict({})` with an empty dictionary and verifies no crash.

---

## 13. Acceptance Criteria

Every criterion below must pass for TASK-006 to be marked complete. Criteria are grouped by
category and ordered by priority.

### 13.1 Class Structure

| ID     | Criterion                                                                                               | Verify By  |
| ------ | ------------------------------------------------------------------------------------------------------- | ---------- |
| AC-001 | File `src/models/adventurer_data.gd` exists and parses without errors.                                  | CI build   |
| AC-002 | Class extends `RefCounted`.                                                                             | Code review|
| AC-003 | Class declares `class_name AdventurerData`.                                                             | Code review|
| AC-004 | `AdventurerData.new()` succeeds and returns a non-null instance.                                        | GUT test   |

### 13.2 Properties

| ID     | Criterion                                                                                               | Verify By  |
| ------ | ------------------------------------------------------------------------------------------------------- | ---------- |
| AC-005 | Property `id` is type `String`, defaults to `""`.                                                       | GUT test   |
| AC-006 | Property `display_name` is type `String`, defaults to `""`.                                             | GUT test   |
| AC-007 | Property `adventurer_class` is type `Enums.AdventurerClass`, defaults to `WARRIOR`.                     | GUT test   |
| AC-008 | Property `level` is type `int`, defaults to `1`.                                                        | GUT test   |
| AC-009 | Property `xp` is type `int`, defaults to `0`.                                                           | GUT test   |
| AC-010 | Property `stats` is type `Dictionary`, defaults to `{}`.                                                | GUT test   |
| AC-011 | Property `equipment` is type `Dictionary` with keys `"weapon"`, `"armor"`, `"accessory"` all set to `null`. | GUT test |
| AC-012 | Property `is_available` is type `bool`, defaults to `true`.                                             | GUT test   |

### 13.3 Base Stats & Initialization

| ID     | Criterion                                                                                               | Verify By  |
| ------ | ------------------------------------------------------------------------------------------------------- | ---------- |
| AC-013 | `initialize_base_stats()` populates `stats` with exactly 5 keys: `health, attack, defense, speed, utility`. | GUT test |
| AC-014 | Warrior stats after `initialize_base_stats()`: `{health:120, attack:18, defense:15, speed:8, utility:5}`. | GUT test |
| AC-015 | Ranger stats after `initialize_base_stats()`: `{health:85, attack:14, defense:8, speed:18, utility:10}`.  | GUT test |
| AC-016 | Mage stats after `initialize_base_stats()`: `{health:70, attack:12, defense:6, speed:10, utility:20}`.    | GUT test |
| AC-017 | Rogue stats after `initialize_base_stats()`: `{health:80, attack:15, defense:7, speed:16, utility:14}`.   | GUT test |
| AC-018 | Alchemist stats after `initialize_base_stats()`: `{health:90, attack:10, defense:10, speed:12, utility:18}`. | GUT test |
| AC-019 | Sentinel stats after `initialize_base_stats()`: `{health:140, attack:8, defense:20, speed:5, utility:8}`.   | GUT test |
| AC-020 | All six classes have all stat values > 0 after initialization.                                           | GUT test   |
| AC-021 | `GameConfig.BASE_STATS` has exactly 6 entries, one per `Enums.AdventurerClass`.                         | GUT test   |

### 13.4 XP & Leveling

| ID     | Criterion                                                                                               | Verify By  |
| ------ | ------------------------------------------------------------------------------------------------------- | ---------- |
| AC-022 | `xp_to_next_level()` at level 1 returns `100`.                                                          | GUT test   |
| AC-023 | `xp_to_next_level()` at level 2 returns `115`.                                                          | GUT test   |
| AC-024 | `gain_xp(50)` on a level 1 adventurer with 0 XP sets `xp = 50` and returns `false`.                    | GUT test   |
| AC-025 | `gain_xp(100)` on a level 1 adventurer with 0 XP sets `level = 2`, `xp = 0` and returns `true`.        | GUT test   |
| AC-026 | `gain_xp(250)` on a level 1 adventurer with 0 XP triggers multi-level-up to level 3 with correct XP remainder. | GUT test |
| AC-027 | `gain_xp(0)` returns `false` and does not change state.                                                 | GUT test   |
| AC-028 | `gain_xp(-10)` returns `false` and does not change state.                                               | GUT test   |
| AC-029 | After `gain_xp()`, `xp` is always `>= 0` and `< xp_to_next_level()`.                                  | GUT test   |
| AC-030 | `level` never decreases after any `gain_xp()` call.                                                     | GUT test   |

### 13.5 Level Tiers

| ID     | Criterion                                                                                               | Verify By  |
| ------ | ------------------------------------------------------------------------------------------------------- | ---------- |
| AC-031 | Level 1 → `get_level_tier()` returns `NOVICE`.                                                          | GUT test   |
| AC-032 | Level 5 → `get_level_tier()` returns `NOVICE`.                                                          | GUT test   |
| AC-033 | Level 6 → `get_level_tier()` returns `SKILLED`.                                                         | GUT test   |
| AC-034 | Level 10 → `get_level_tier()` returns `SKILLED`.                                                        | GUT test   |
| AC-035 | Level 11 → `get_level_tier()` returns `VETERAN`.                                                        | GUT test   |
| AC-036 | Level 15 → `get_level_tier()` returns `VETERAN`.                                                        | GUT test   |
| AC-037 | Level 16 → `get_level_tier()` returns `ELITE`.                                                          | GUT test   |
| AC-038 | Level 99 → `get_level_tier()` returns `ELITE`.                                                          | GUT test   |

### 13.6 Effective Stats

| ID     | Criterion                                                                                               | Verify By  |
| ------ | ------------------------------------------------------------------------------------------------------- | ---------- |
| AC-039 | `get_effective_stats()` returns a dictionary with 5 keys matching stat names.                            | GUT test   |
| AC-040 | `get_effective_stats()` returns a deep copy — mutating it does not change `stats`.                       | GUT test   |
| AC-041 | In TASK-006, `get_effective_stats()` values equal base `stats` values (no equipment bonuses yet).        | GUT test   |

### 13.7 Serialization

| ID     | Criterion                                                                                               | Verify By  |
| ------ | ------------------------------------------------------------------------------------------------------- | ---------- |
| AC-042 | `to_dict()` returns a `Dictionary` with keys: `id, display_name, adventurer_class, level, xp, stats, equipment, is_available`. | GUT test |
| AC-043 | `to_dict()` serializes `adventurer_class` as an integer.                                                 | GUT test   |
| AC-044 | `from_dict(to_dict(x)).to_dict()` equals `x.to_dict()` for all six classes.                             | GUT test   |
| AC-045 | `from_dict()` with missing keys uses defaults and does not crash.                                        | GUT test   |
| AC-046 | `from_dict()` with out-of-range `adventurer_class` defaults to `WARRIOR`.                               | GUT test   |
| AC-047 | `to_dict()` output is compatible with `JSON.stringify()` (no non-serializable types).                   | GUT test   |
| AC-048 | `from_dict()` with extra unknown keys ignores them silently.                                             | GUT test   |

### 13.8 GameConfig Constants

| ID     | Criterion                                                                                               | Verify By  |
| ------ | ------------------------------------------------------------------------------------------------------- | ---------- |
| AC-049 | `GameConfig.BASE_STATS` exists and is a `Dictionary`.                                                   | GUT test   |
| AC-050 | `GameConfig.XP_CURVE` exists with `BASE_XP = 100` and `GROWTH_RATE = 1.15`.                            | GUT test   |
| AC-051 | `GameConfig.XP_PER_TIER` exists with `NOVICE: 0, SKILLED: 100, VETERAN: 350, ELITE: 750`.              | GUT test   |

### 13.9 Code Quality

| ID     | Criterion                                                                                               | Verify By    |
| ------ | ------------------------------------------------------------------------------------------------------- | ------------ |
| AC-052 | All properties have explicit type hints.                                                                 | Code review  |
| AC-053 | All method parameters have explicit type hints.                                                          | Code review  |
| AC-054 | All method return types have explicit type hints.                                                        | Code review  |
| AC-055 | No `@onready`, `@export`, or `signal` declarations exist in the file.                                   | Code review  |
| AC-056 | No magic numbers exist — all constants reference `GameConfig`.                                           | Code review  |
| AC-057 | File is under 200 lines of code (excluding blank lines and comments).                                   | LOC count    |

---

## 14. Testing Requirements

### 14.1 Test File Location

`tests/models/test_adventurer_data.gd`

### 14.2 Complete GUT Test Suite

```gdscript
# tests/models/test_adventurer_data.gd
extends GutTest

# =============================================================================
# HELPERS
# =============================================================================

func _create_adventurer(
	adv_class: Enums.AdventurerClass = Enums.AdventurerClass.WARRIOR,
	name: String = "Test Hero",
	id: String = "test-uuid-001"
) -> AdventurerData:
	var adv: AdventurerData = AdventurerData.new()
	adv.id = id
	adv.display_name = name
	adv.adventurer_class = adv_class
	adv.initialize_base_stats()
	return adv


func _all_classes() -> Array[Enums.AdventurerClass]:
	return [
		Enums.AdventurerClass.WARRIOR,
		Enums.AdventurerClass.RANGER,
		Enums.AdventurerClass.MAGE,
		Enums.AdventurerClass.ROGUE,
		Enums.AdventurerClass.ALCHEMIST,
		Enums.AdventurerClass.SENTINEL,
	]


func _expected_base_stats(adv_class: Enums.AdventurerClass) -> Dictionary:
	match adv_class:
		Enums.AdventurerClass.WARRIOR:
			return { "health": 120, "attack": 18, "defense": 15, "speed": 8, "utility": 5 }
		Enums.AdventurerClass.RANGER:
			return { "health": 85, "attack": 14, "defense": 8, "speed": 18, "utility": 10 }
		Enums.AdventurerClass.MAGE:
			return { "health": 70, "attack": 12, "defense": 6, "speed": 10, "utility": 20 }
		Enums.AdventurerClass.ROGUE:
			return { "health": 80, "attack": 15, "defense": 7, "speed": 16, "utility": 14 }
		Enums.AdventurerClass.ALCHEMIST:
			return { "health": 90, "attack": 10, "defense": 10, "speed": 12, "utility": 18 }
		Enums.AdventurerClass.SENTINEL:
			return { "health": 140, "attack": 8, "defense": 20, "speed": 5, "utility": 8 }
		_:
			return {}


# =============================================================================
# SECTION A: CONSTRUCTION & DEFAULT VALUES
# =============================================================================

func test_new_instance_is_not_null() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_not_null(adv, "AdventurerData.new() should return a non-null instance")


func test_default_id_is_empty_string() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_eq(adv.id, "", "Default id should be empty string")


func test_default_display_name_is_empty_string() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_eq(adv.display_name, "", "Default display_name should be empty string")


func test_default_adventurer_class_is_warrior() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_eq(adv.adventurer_class, Enums.AdventurerClass.WARRIOR, "Default class should be WARRIOR")


func test_default_level_is_one() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_eq(adv.level, 1, "Default level should be 1")


func test_default_xp_is_zero() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_eq(adv.xp, 0, "Default xp should be 0")


func test_default_is_available_is_true() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_true(adv.is_available, "Default is_available should be true")


func test_default_equipment_has_three_null_slots() -> void:
	var adv: AdventurerData = AdventurerData.new()
	assert_eq(adv.equipment.size(), 3, "Equipment should have 3 slots")
	assert_null(adv.equipment.get("weapon"), "Weapon slot should be null")
	assert_null(adv.equipment.get("armor"), "Armor slot should be null")
	assert_null(adv.equipment.get("accessory"), "Accessory slot should be null")


# =============================================================================
# SECTION B: BASE STATS INITIALIZATION — PER CLASS
# =============================================================================

func test_warrior_base_stats() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.WARRIOR)
	var expected: Dictionary = { "health": 120, "attack": 18, "defense": 15, "speed": 8, "utility": 5 }
	assert_eq(adv.stats, expected, "Warrior base stats should match GDD spec")


func test_ranger_base_stats() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.RANGER)
	var expected: Dictionary = { "health": 85, "attack": 14, "defense": 8, "speed": 18, "utility": 10 }
	assert_eq(adv.stats, expected, "Ranger base stats should match GDD spec")


func test_mage_base_stats() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.MAGE)
	var expected: Dictionary = { "health": 70, "attack": 12, "defense": 6, "speed": 10, "utility": 20 }
	assert_eq(adv.stats, expected, "Mage base stats should match GDD spec")


func test_rogue_base_stats() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.ROGUE)
	var expected: Dictionary = { "health": 80, "attack": 15, "defense": 7, "speed": 16, "utility": 14 }
	assert_eq(adv.stats, expected, "Rogue base stats should match GDD spec")


func test_alchemist_base_stats() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.ALCHEMIST)
	var expected: Dictionary = { "health": 90, "attack": 10, "defense": 10, "speed": 12, "utility": 18 }
	assert_eq(adv.stats, expected, "Alchemist base stats should match GDD spec")


func test_sentinel_base_stats() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.SENTINEL)
	var expected: Dictionary = { "health": 140, "attack": 8, "defense": 20, "speed": 5, "utility": 8 }
	assert_eq(adv.stats, expected, "Sentinel base stats should match GDD spec")


func test_all_classes_have_five_stat_keys() -> void:
	var expected_keys: Array[String] = ["health", "attack", "defense", "speed", "utility"]
	for adv_class in _all_classes():
		var adv: AdventurerData = _create_adventurer(adv_class)
		for key in expected_keys:
			assert_has(adv.stats, key, "Class %s missing stat key: %s" % [adv_class, key])
		assert_eq(adv.stats.size(), 5, "Class %s should have exactly 5 stat keys" % adv_class)


func test_all_classes_have_positive_stat_values() -> void:
	for adv_class in _all_classes():
		var adv: AdventurerData = _create_adventurer(adv_class)
		for stat_name in adv.stats:
			assert_gt(adv.stats[stat_name], 0, "Class %s stat %s should be > 0" % [adv_class, stat_name])


func test_each_class_has_distinct_stat_distribution() -> void:
	var stat_sets: Array[Dictionary] = []
	for adv_class in _all_classes():
		var adv: AdventurerData = _create_adventurer(adv_class)
		for existing in stat_sets:
			assert_ne(adv.stats, existing, "Each class must have a unique stat distribution")
		stat_sets.append(adv.stats.duplicate())


func test_game_config_base_stats_has_six_entries() -> void:
	assert_eq(GameConfig.BASE_STATS.size(), 6, "GameConfig.BASE_STATS should have 6 class entries")


# =============================================================================
# SECTION C: XP-TO-NEXT-LEVEL CALCULATION
# =============================================================================

func test_xp_to_next_level_at_level_1() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 1
	assert_eq(adv.xp_to_next_level(), 100, "Level 1 → 2 should cost 100 XP")


func test_xp_to_next_level_at_level_2() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 2
	assert_eq(adv.xp_to_next_level(), 115, "Level 2 → 3 should cost 115 XP")


func test_xp_to_next_level_at_level_5() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 5
	var expected: int = int(100 * pow(1.15, 4))
	assert_eq(adv.xp_to_next_level(), expected, "Level 5 → 6 should follow exponential curve")


func test_xp_to_next_level_at_level_10() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 10
	var expected: int = int(100 * pow(1.15, 9))
	assert_eq(adv.xp_to_next_level(), expected, "Level 10 → 11 should follow exponential curve")


func test_xp_to_next_level_at_level_15() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 15
	var expected: int = int(100 * pow(1.15, 14))
	assert_eq(adv.xp_to_next_level(), expected, "Level 15 → 16 should follow exponential curve")


func test_xp_to_next_level_always_positive() -> void:
	var adv: AdventurerData = _create_adventurer()
	for lvl in range(1, 50):
		adv.level = lvl
		assert_gt(adv.xp_to_next_level(), 0, "XP threshold at level %d should be positive" % lvl)


func test_xp_to_next_level_increases_with_level() -> void:
	var adv: AdventurerData = _create_adventurer()
	var prev_xp: int = 0
	for lvl in range(1, 30):
		adv.level = lvl
		var current_xp: int = adv.xp_to_next_level()
		assert_gt(current_xp, prev_xp, "XP threshold should increase at level %d" % lvl)
		prev_xp = current_xp


# =============================================================================
# SECTION D: GAIN XP & LEVEL-UP
# =============================================================================

func test_gain_xp_no_levelup() -> void:
	var adv: AdventurerData = _create_adventurer()
	var leveled: bool = adv.gain_xp(50)
	assert_false(leveled, "50 XP should not trigger level-up from level 1")
	assert_eq(adv.xp, 50, "XP should be 50")
	assert_eq(adv.level, 1, "Level should remain 1")


func test_gain_xp_exact_levelup() -> void:
	var adv: AdventurerData = _create_adventurer()
	var leveled: bool = adv.gain_xp(100)
	assert_true(leveled, "100 XP should trigger level-up from level 1")
	assert_eq(adv.level, 2, "Level should be 2")
	assert_eq(adv.xp, 0, "XP should be 0 after exact level-up")


func test_gain_xp_with_remainder() -> void:
	var adv: AdventurerData = _create_adventurer()
	var leveled: bool = adv.gain_xp(130)
	assert_true(leveled, "130 XP should trigger level-up from level 1")
	assert_eq(adv.level, 2, "Level should be 2")
	assert_eq(adv.xp, 30, "XP remainder should be 30")


func test_gain_xp_multi_levelup() -> void:
	var adv: AdventurerData = _create_adventurer()
	# Level 1→2: 100, Level 2→3: 115 → total 215 for 2 level-ups
	var leveled: bool = adv.gain_xp(250)
	assert_true(leveled, "250 XP should trigger multi-level-up")
	assert_eq(adv.level, 3, "Level should be 3 after multi-level-up")
	assert_eq(adv.xp, 35, "XP remainder should be 250 - 100 - 115 = 35")


func test_gain_xp_zero_returns_false() -> void:
	var adv: AdventurerData = _create_adventurer()
	var leveled: bool = adv.gain_xp(0)
	assert_false(leveled, "0 XP should not trigger level-up")
	assert_eq(adv.xp, 0, "XP should remain 0")
	assert_eq(adv.level, 1, "Level should remain 1")


func test_gain_xp_negative_returns_false() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.xp = 50
	var leveled: bool = adv.gain_xp(-10)
	assert_false(leveled, "Negative XP should not trigger level-up")
	assert_eq(adv.xp, 50, "XP should remain unchanged")
	assert_eq(adv.level, 1, "Level should remain 1")


func test_gain_xp_large_amount_many_levels() -> void:
	var adv: AdventurerData = _create_adventurer()
	var leveled: bool = adv.gain_xp(5000)
	assert_true(leveled, "5000 XP should trigger many level-ups")
	assert_gt(adv.level, 10, "Level should be well above 10")
	assert_ge(adv.xp, 0, "XP remainder should be non-negative")
	assert_lt(adv.xp, adv.xp_to_next_level(), "XP remainder should be less than next threshold")


func test_gain_xp_accumulates_across_calls() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.gain_xp(50)
	assert_eq(adv.xp, 50)
	assert_eq(adv.level, 1)
	adv.gain_xp(50)
	assert_eq(adv.level, 2, "Two 50 XP grants should total to 100, triggering level-up")
	assert_eq(adv.xp, 0)


func test_level_never_decreases() -> void:
	var adv: AdventurerData = _create_adventurer()
	var prev_level: int = adv.level
	for i in range(20):
		adv.gain_xp(randi_range(10, 200))
		assert_ge(adv.level, prev_level, "Level should never decrease")
		prev_level = adv.level


func test_xp_remainder_always_valid_after_gain() -> void:
	var adv: AdventurerData = _create_adventurer()
	for i in range(50):
		adv.gain_xp(randi_range(1, 500))
		assert_ge(adv.xp, 0, "XP should never be negative after gain_xp")
		assert_lt(adv.xp, adv.xp_to_next_level(), "XP should be less than threshold after gain_xp")


# =============================================================================
# SECTION E: LEVEL TIER
# =============================================================================

func test_tier_novice_level_1() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 1
	assert_eq(adv.get_level_tier(), Enums.LevelTier.NOVICE, "Level 1 should be NOVICE")


func test_tier_novice_level_5() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 5
	assert_eq(adv.get_level_tier(), Enums.LevelTier.NOVICE, "Level 5 should be NOVICE")


func test_tier_skilled_level_6() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 6
	assert_eq(adv.get_level_tier(), Enums.LevelTier.SKILLED, "Level 6 should be SKILLED")


func test_tier_skilled_level_10() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 10
	assert_eq(adv.get_level_tier(), Enums.LevelTier.SKILLED, "Level 10 should be SKILLED")


func test_tier_veteran_level_11() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 11
	assert_eq(adv.get_level_tier(), Enums.LevelTier.VETERAN, "Level 11 should be VETERAN")


func test_tier_veteran_level_15() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 15
	assert_eq(adv.get_level_tier(), Enums.LevelTier.VETERAN, "Level 15 should be VETERAN")


func test_tier_elite_level_16() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 16
	assert_eq(adv.get_level_tier(), Enums.LevelTier.ELITE, "Level 16 should be ELITE")


func test_tier_elite_level_99() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 99
	assert_eq(adv.get_level_tier(), Enums.LevelTier.ELITE, "Level 99 should be ELITE")


func test_tier_transitions_through_levelup() -> void:
	var adv: AdventurerData = _create_adventurer()
	assert_eq(adv.get_level_tier(), Enums.LevelTier.NOVICE, "Start as NOVICE")
	adv.level = 6
	assert_eq(adv.get_level_tier(), Enums.LevelTier.SKILLED, "Level 6 transitions to SKILLED")
	adv.level = 11
	assert_eq(adv.get_level_tier(), Enums.LevelTier.VETERAN, "Level 11 transitions to VETERAN")
	adv.level = 16
	assert_eq(adv.get_level_tier(), Enums.LevelTier.ELITE, "Level 16 transitions to ELITE")


# =============================================================================
# SECTION F: EFFECTIVE STATS
# =============================================================================

func test_effective_stats_returns_dictionary_with_five_keys() -> void:
	var adv: AdventurerData = _create_adventurer()
	var effective: Dictionary = adv.get_effective_stats()
	assert_eq(effective.size(), 5, "Effective stats should have 5 keys")
	assert_has(effective, "health")
	assert_has(effective, "attack")
	assert_has(effective, "defense")
	assert_has(effective, "speed")
	assert_has(effective, "utility")


func test_effective_stats_equals_base_stats_without_equipment() -> void:
	for adv_class in _all_classes():
		var adv: AdventurerData = _create_adventurer(adv_class)
		var effective: Dictionary = adv.get_effective_stats()
		assert_eq(effective, adv.stats, "Effective stats should equal base stats without equipment")


func test_effective_stats_returns_deep_copy() -> void:
	var adv: AdventurerData = _create_adventurer()
	var effective: Dictionary = adv.get_effective_stats()
	effective["health"] = 999
	assert_ne(adv.stats["health"], 999, "Mutating effective stats should not change base stats")
	assert_eq(adv.stats["health"], 120, "Base health should remain 120 for Warrior")


# =============================================================================
# SECTION G: SERIALIZATION — to_dict()
# =============================================================================

func test_to_dict_contains_all_keys() -> void:
	var adv: AdventurerData = _create_adventurer()
	var d: Dictionary = adv.to_dict()
	var expected_keys: Array[String] = [
		"id", "display_name", "adventurer_class", "level",
		"xp", "stats", "equipment", "is_available"
	]
	for key in expected_keys:
		assert_has(d, key, "to_dict() missing key: %s" % key)


func test_to_dict_serializes_class_as_int() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.MAGE)
	var d: Dictionary = adv.to_dict()
	assert_typeof(d["adventurer_class"], TYPE_INT, "adventurer_class should serialize as int")
	assert_eq(d["adventurer_class"], int(Enums.AdventurerClass.MAGE))


func test_to_dict_preserves_all_values() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.ROGUE, "Shadow", "rogue-42")
	adv.level = 7
	adv.xp = 55
	adv.is_available = false
	var d: Dictionary = adv.to_dict()
	assert_eq(d["id"], "rogue-42")
	assert_eq(d["display_name"], "Shadow")
	assert_eq(d["level"], 7)
	assert_eq(d["xp"], 55)
	assert_eq(d["is_available"], false)


func test_to_dict_equipment_uses_string_keys() -> void:
	var adv: AdventurerData = _create_adventurer()
	var d: Dictionary = adv.to_dict()
	var equip: Dictionary = d["equipment"]
	assert_has(equip, "weapon", "Equipment should have 'weapon' string key")
	assert_has(equip, "armor", "Equipment should have 'armor' string key")
	assert_has(equip, "accessory", "Equipment should have 'accessory' string key")


func test_to_dict_is_json_compatible() -> void:
	var adv: AdventurerData = _create_adventurer()
	var d: Dictionary = adv.to_dict()
	var json_str: String = JSON.stringify(d)
	assert_gt(json_str.length(), 0, "JSON.stringify() should produce non-empty string")
	var parsed: Variant = JSON.parse_string(json_str)
	assert_not_null(parsed, "JSON.parse_string() should successfully parse the output")


# =============================================================================
# SECTION H: SERIALIZATION — from_dict() ROUND-TRIP
# =============================================================================

func test_round_trip_all_classes() -> void:
	for adv_class in _all_classes():
		var original: AdventurerData = _create_adventurer(adv_class, "Hero %d" % adv_class, "id-%d" % adv_class)
		original.level = 8
		original.xp = 42
		original.is_available = false
		var d: Dictionary = original.to_dict()
		var restored: AdventurerData = AdventurerData.from_dict(d)
		assert_eq(restored.to_dict(), d, "Round-trip should be lossless for class %s" % adv_class)


func test_from_dict_restores_correct_types() -> void:
	var adv: AdventurerData = _create_adventurer(Enums.AdventurerClass.ALCHEMIST)
	adv.level = 12
	adv.xp = 200
	var d: Dictionary = adv.to_dict()
	var restored: AdventurerData = AdventurerData.from_dict(d)
	assert_eq(restored.adventurer_class, Enums.AdventurerClass.ALCHEMIST)
	assert_eq(restored.level, 12)
	assert_eq(restored.xp, 200)
	assert_typeof(restored.level, TYPE_INT, "Level should be int after deserialization")
	assert_typeof(restored.xp, TYPE_INT, "XP should be int after deserialization")


func test_from_dict_missing_keys_uses_defaults() -> void:
	var partial: Dictionary = { "id": "partial-hero" }
	var adv: AdventurerData = AdventurerData.from_dict(partial)
	assert_eq(adv.id, "partial-hero")
	assert_eq(adv.display_name, "", "Missing display_name should default to empty")
	assert_eq(adv.level, 1, "Missing level should default to 1")
	assert_eq(adv.xp, 0, "Missing xp should default to 0")
	assert_true(adv.is_available, "Missing is_available should default to true")


func test_from_dict_empty_dict_no_crash() -> void:
	var adv: AdventurerData = AdventurerData.from_dict({})
	assert_not_null(adv, "from_dict({}) should not crash and should return an instance")
	assert_eq(adv.level, 1)
	assert_eq(adv.xp, 0)


func test_from_dict_invalid_class_defaults_to_warrior() -> void:
	var d: Dictionary = _create_adventurer().to_dict()
	d["adventurer_class"] = 99
	var adv: AdventurerData = AdventurerData.from_dict(d)
	assert_eq(adv.adventurer_class, Enums.AdventurerClass.WARRIOR, "Invalid class should default to WARRIOR")


func test_from_dict_extra_keys_are_ignored() -> void:
	var d: Dictionary = _create_adventurer().to_dict()
	d["unknown_field"] = "should be ignored"
	d["another_unknown"] = 42
	var adv: AdventurerData = AdventurerData.from_dict(d)
	assert_eq(adv.to_dict().has("unknown_field"), false, "Extra keys should not appear in to_dict()")


func test_from_dict_json_round_trip() -> void:
	var original: AdventurerData = _create_adventurer(Enums.AdventurerClass.SENTINEL, "Iron Wall", "sent-01")
	original.level = 16
	original.xp = 300
	var json_str: String = JSON.stringify(original.to_dict())
	var parsed: Dictionary = JSON.parse_string(json_str)
	var restored: AdventurerData = AdventurerData.from_dict(parsed)
	assert_eq(restored.display_name, "Iron Wall")
	assert_eq(restored.adventurer_class, Enums.AdventurerClass.SENTINEL)
	assert_eq(restored.level, 16)
	assert_eq(restored.xp, 300)
	assert_eq(restored.get_level_tier(), Enums.LevelTier.ELITE)


# =============================================================================
# SECTION I: GAMECONFIG CONSTANTS
# =============================================================================

func test_game_config_base_stats_exists() -> void:
	assert_not_null(GameConfig.BASE_STATS, "GameConfig.BASE_STATS should exist")
	assert_typeof(GameConfig.BASE_STATS, TYPE_DICTIONARY, "BASE_STATS should be a Dictionary")


func test_game_config_xp_curve_exists() -> void:
	assert_not_null(GameConfig.XP_CURVE, "GameConfig.XP_CURVE should exist")
	assert_eq(GameConfig.XP_CURVE["BASE_XP"], 100, "BASE_XP should be 100")
	assert_eq(GameConfig.XP_CURVE["GROWTH_RATE"], 1.15, "GROWTH_RATE should be 1.15")


func test_game_config_xp_per_tier_exists() -> void:
	assert_not_null(GameConfig.XP_PER_TIER, "GameConfig.XP_PER_TIER should exist")
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.NOVICE], 0)
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.SKILLED], 100)
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.VETERAN], 350)
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.ELITE], 750)


# =============================================================================
# SECTION J: EDGE CASES & STRESS
# =============================================================================

func test_gain_xp_from_high_level() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.level = 50
	var threshold: int = adv.xp_to_next_level()
	var leveled: bool = adv.gain_xp(threshold)
	assert_true(leveled, "Should still be able to level up at level 50")
	assert_eq(adv.level, 51)
	assert_eq(adv.xp, 0)


func test_many_small_xp_gains() -> void:
	var adv: AdventurerData = _create_adventurer()
	for i in range(100):
		adv.gain_xp(1)
	assert_eq(adv.level, 2, "100 XP in single-point increments should reach level 2")
	assert_eq(adv.xp, 0, "XP should be exactly 0 after reaching level 2 threshold")


func test_availability_toggle() -> void:
	var adv: AdventurerData = _create_adventurer()
	assert_true(adv.is_available)
	adv.is_available = false
	assert_false(adv.is_available)
	adv.is_available = true
	assert_true(adv.is_available)


func test_equipment_slot_assignment() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.equipment["weapon"] = "sword_001"
	adv.equipment["armor"] = "plate_001"
	adv.equipment["accessory"] = "ring_001"
	assert_eq(adv.equipment["weapon"], "sword_001")
	assert_eq(adv.equipment["armor"], "plate_001")
	assert_eq(adv.equipment["accessory"], "ring_001")


func test_equipment_survives_serialization() -> void:
	var adv: AdventurerData = _create_adventurer()
	adv.equipment["weapon"] = "bow_003"
	var d: Dictionary = adv.to_dict()
	var restored: AdventurerData = AdventurerData.from_dict(d)
	assert_eq(restored.equipment["weapon"], "bow_003", "Equipment should survive serialization")
	assert_null(restored.equipment["armor"], "Unset slots should remain null")
```

---

## 15. Playtesting Verification

These scenarios are verified manually or via integration tests during vertical-slice playtesting.
Each scenario describes a player-observable behavior and the expected outcome.

### PV-01: Recruit Each Class and Verify Stats Display

**Setup**: Open the roster/guild hall screen. Recruit one adventurer of each class.
**Action**: Inspect each adventurer's stat panel.
**Expected**: Each class shows the correct base stat values per the GDD table. Warriors have the
highest health (120), Sentinels have the highest defense (20), Mages have the highest utility (20),
Rangers and Rogues have the highest speed (18 and 16 respectively), Alchemists show balanced mid
stats. No stat is zero. No stat is negative. The stat labels are spelled correctly.

### PV-02: XP Gain from First Dungeon Run

**Setup**: Recruit a level 1 Warrior. Dispatch to the tutorial dungeon.
**Action**: Complete the dungeon. Observe XP reward screen.
**Expected**: Warrior receives the displayed XP amount. If XP >= 100, the warrior levels up to 2
and the level-up fanfare plays. Remaining XP is shown in the XP bar. The XP bar fills proportional
to `xp / xp_to_next_level()`.

### PV-03: Multi-Level-Up from Large XP Reward

**Setup**: A level 1 adventurer with 0 XP. Configure a test dungeon that awards 500 XP.
**Action**: Complete the dungeon.
**Expected**: The adventurer levels up multiple times (to approximately level 5). Each level-up is
displayed in sequence on the reward screen. Final XP bar shows the correct remainder. Level tier
remains Novice (level 5 is still Novice).

### PV-04: Tier Transition Visuals

**Setup**: A level 5 adventurer with XP close to the level-up threshold.
**Action**: Complete a dungeon that grants enough XP to reach level 6.
**Expected**: The adventurer levels up to 6. The tier badge changes from "Novice" to "Skilled."
A tier-up celebration plays (distinct from regular level-up). The adventurer card border/color
reflects the new tier.

### PV-05: Save and Load Preserves Adventurer State

**Setup**: A roster with 3 adventurers: a level 8 Rogue with equipment, a level 1 Mage, and a
level 16 Sentinel currently on expedition (is_available = false).
**Action**: Save the game. Close the game. Reopen. Load the save.
**Expected**: All three adventurers are restored with correct names, classes, levels, XP, stats,
equipment, and availability. The Sentinel is still shown as "on expedition." The Rogue's equipment
is still equipped. The Mage is still level 1 with 0 XP.

### PV-06: Effective Stats Match Base Stats (Pre-Equipment)

**Setup**: Any adventurer without equipment.
**Action**: Open the stat detail panel. Compare "Base Stats" and "Effective Stats" sections.
**Expected**: Both sections show identical values. No equipment bonuses are listed. The effective
stats do not show mysterious extra values or zeroed-out entries.

### PV-07: Adventurer Unavailability During Expedition

**Setup**: Recruit 4 adventurers. Send 2 on an expedition.
**Action**: Open the roster. Attempt to send the same 2 on a second expedition.
**Expected**: The 2 adventurers on expedition are grayed out / marked as unavailable. They cannot
be selected for a new expedition. The remaining 2 are selectable. When the first expedition
completes, the 2 adventurers become available again.

### PV-08: High-Level Adventurer Remains Functional

**Setup**: Use debug tools to set an adventurer to level 50.
**Action**: View stats, dispatch to dungeon, complete, receive XP.
**Expected**: `xp_to_next_level()` returns a large but valid number. XP gain works. Level-up works.
Tier is Elite. No integer overflow. No visual glitches on the XP bar. Serialization works.

### PV-09: Class Stat Distinctness is Visually Obvious

**Setup**: Recruit all 6 classes. Open a comparison view (if available) or inspect side by side.
**Action**: Compare stat distributions.
**Expected**: Each class has a clearly distinct stat profile. A Warrior is obviously tankier than a
Mage. A Ranger is obviously faster than a Sentinel. The visual stat bars (radar chart or bar graph)
make the class identity immediately apparent without reading numbers.

### PV-10: Corrupt Save File Recovery

**Setup**: Manually edit the save file to: (a) set a Mage's health to 99999, (b) set an
adventurer's class to 99, (c) remove the `xp` field entirely.
**Action**: Load the save file.
**Expected**: (a) Mage health is reset to base (70) with a warning logged. (b) Invalid class
defaults to Warrior with an error logged. (c) Missing XP defaults to 0 with a warning logged. The
game does not crash. Other adventurers load normally.

---

## 16. Implementation Prompt

### 16.1 GameConfig Additions — `src/config/game_config.gd`

Add the following constants to the existing `GameConfig` autoload script. If `GameConfig` does not
yet exist, create it as an autoload extending `Node`.

```gdscript
# src/config/game_config.gd
# GameConfig — project-wide balance constants
# This is an autoload singleton registered in project.godot
extends Node
class_name GameConfig


# ---------------------------------------------------------------------------
# Adventurer Base Stats — per class
# Maps Enums.AdventurerClass → Dictionary of 5 stat values
# ---------------------------------------------------------------------------
const BASE_STATS: Dictionary = {
	Enums.AdventurerClass.WARRIOR: {
		"health": 120,
		"attack": 18,
		"defense": 15,
		"speed": 8,
		"utility": 5,
	},
	Enums.AdventurerClass.RANGER: {
		"health": 85,
		"attack": 14,
		"defense": 8,
		"speed": 18,
		"utility": 10,
	},
	Enums.AdventurerClass.MAGE: {
		"health": 70,
		"attack": 12,
		"defense": 6,
		"speed": 10,
		"utility": 20,
	},
	Enums.AdventurerClass.ROGUE: {
		"health": 80,
		"attack": 15,
		"defense": 7,
		"speed": 16,
		"utility": 14,
	},
	Enums.AdventurerClass.ALCHEMIST: {
		"health": 90,
		"attack": 10,
		"defense": 10,
		"speed": 12,
		"utility": 18,
	},
	Enums.AdventurerClass.SENTINEL: {
		"health": 140,
		"attack": 8,
		"defense": 20,
		"speed": 5,
		"utility": 8,
	},
}


# ---------------------------------------------------------------------------
# XP Curve Parameters
# xp_to_next_level = BASE_XP * pow(GROWTH_RATE, level - 1)
# ---------------------------------------------------------------------------
const XP_CURVE: Dictionary = {
	"BASE_XP": 100,
	"GROWTH_RATE": 1.15,
}


# ---------------------------------------------------------------------------
# Level Tier Thresholds — cumulative XP entry points
# Used for reference/display. Tier assignment is level-based, not XP-based.
# ---------------------------------------------------------------------------
const XP_PER_TIER: Dictionary = {
	Enums.LevelTier.NOVICE: 0,
	Enums.LevelTier.SKILLED: 100,
	Enums.LevelTier.VETERAN: 350,
	Enums.LevelTier.ELITE: 750,
}


# ---------------------------------------------------------------------------
# Stat Keys — canonical ordered list of stat names
# Used for validation and iteration
# ---------------------------------------------------------------------------
const STAT_KEYS: Array[String] = ["health", "attack", "defense", "speed", "utility"]


# ---------------------------------------------------------------------------
# Equipment Slot Keys — canonical slot names
# ---------------------------------------------------------------------------
const EQUIP_SLOT_KEYS: Array[String] = ["weapon", "armor", "accessory"]
```

### 16.2 Adventurer Data Model — `src/models/adventurer_data.gd`

```gdscript
# src/models/adventurer_data.gd
# AdventurerData — pure data model for a single adventurer
# Extends RefCounted (no scene tree dependency). Fully serializable.
extends RefCounted
class_name AdventurerData


# ===========================================================================
# PROPERTIES
# ===========================================================================

var id: String = ""
var display_name: String = ""
var adventurer_class: Enums.AdventurerClass = Enums.AdventurerClass.WARRIOR
var level: int = 1
var xp: int = 0
var stats: Dictionary = {}
var equipment: Dictionary = {
	"weapon": null,
	"armor": null,
	"accessory": null,
}
var is_available: bool = true


# ===========================================================================
# INITIALIZATION
# ===========================================================================

func initialize_base_stats() -> void:
	if not GameConfig.BASE_STATS.has(adventurer_class):
		push_error(
			"AdventurerData: Unknown class %s. Falling back to WARRIOR." % adventurer_class
		)
		stats = GameConfig.BASE_STATS[Enums.AdventurerClass.WARRIOR].duplicate(true)
		return
	stats = GameConfig.BASE_STATS[adventurer_class].duplicate(true)


# ===========================================================================
# XP & LEVELING
# ===========================================================================

func xp_to_next_level() -> int:
	var base_xp: int = GameConfig.XP_CURVE["BASE_XP"]
	var growth_rate: float = GameConfig.XP_CURVE["GROWTH_RATE"]
	return int(base_xp * pow(growth_rate, level - 1))


func gain_xp(amount: int) -> bool:
	if amount <= 0:
		return false

	xp += amount
	var leveled_up: bool = false

	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		leveled_up = true

	return leveled_up


# ===========================================================================
# LEVEL TIER
# ===========================================================================

func get_level_tier() -> Enums.LevelTier:
	if level >= 16:
		return Enums.LevelTier.ELITE
	elif level >= 11:
		return Enums.LevelTier.VETERAN
	elif level >= 6:
		return Enums.LevelTier.SKILLED
	else:
		return Enums.LevelTier.NOVICE


# ===========================================================================
# STAT QUERIES
# ===========================================================================

func get_effective_stats() -> Dictionary:
	var effective: Dictionary = stats.duplicate(true)
	# Placeholder: Equipment bonuses will be applied here by TASK-014.
	# For now, return base stats unmodified.
	return effective


# ===========================================================================
# SERIALIZATION
# ===========================================================================

func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"adventurer_class": int(adventurer_class),
		"level": level,
		"xp": xp,
		"stats": stats.duplicate(true),
		"equipment": equipment.duplicate(true),
		"is_available": is_available,
	}


static func from_dict(data: Dictionary) -> AdventurerData:
	var adv: AdventurerData = AdventurerData.new()

	adv.id = str(data.get("id", ""))
	adv.display_name = str(data.get("display_name", ""))

	# Deserialize adventurer class with validation
	var raw_class: int = int(data.get("adventurer_class", 0))
	if raw_class >= 0 and raw_class < Enums.AdventurerClass.size():
		adv.adventurer_class = raw_class as Enums.AdventurerClass
	else:
		push_error(
			"AdventurerData.from_dict: Invalid adventurer_class %d. Defaulting to WARRIOR." % raw_class
		)
		adv.adventurer_class = Enums.AdventurerClass.WARRIOR

	# Deserialize level with validation
	adv.level = max(1, int(data.get("level", 1)))

	# Deserialize XP with validation
	adv.xp = max(0, int(data.get("xp", 0)))

	# Deserialize stats — validate against base stats for the class
	var raw_stats: Variant = data.get("stats", {})
	if raw_stats is Dictionary and raw_stats.size() > 0:
		var validated_stats: Dictionary = {}
		var base: Dictionary = GameConfig.BASE_STATS.get(
			adv.adventurer_class, GameConfig.BASE_STATS[Enums.AdventurerClass.WARRIOR]
		)
		for key in GameConfig.STAT_KEYS:
			if raw_stats.has(key):
				validated_stats[key] = int(raw_stats[key])
			else:
				push_warning("AdventurerData.from_dict: Missing stat '%s'. Using base value." % key)
				validated_stats[key] = base.get(key, 0)
		adv.stats = validated_stats
	else:
		adv.initialize_base_stats()

	# Deserialize equipment — only read canonical slot keys
	var raw_equipment: Variant = data.get("equipment", {})
	if raw_equipment is Dictionary:
		for slot_key in GameConfig.EQUIP_SLOT_KEYS:
			if raw_equipment.has(slot_key):
				adv.equipment[slot_key] = raw_equipment[slot_key]
			else:
				adv.equipment[slot_key] = null
	else:
		adv.equipment = { "weapon": null, "armor": null, "accessory": null }

	# Deserialize availability
	adv.is_available = bool(data.get("is_available", true))

	return adv
```

### 16.3 Implementation Notes

1. **File creation order**: Create `GameConfig` additions first (or create the file if it doesn't
   exist), then create `adventurer_data.gd`. The model depends on `GameConfig` constants.

2. **Autoload registration**: Ensure `GameConfig` is registered in `project.godot`:
   ```ini
   [autoload]
   GameConfig="*res://src/config/game_config.gd"
   ```

3. **Enum dependency**: This implementation assumes TASK-003 has already defined:
   ```gdscript
   # In src/enums/enums.gd (or equivalent)
   enum AdventurerClass { WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL }
   enum LevelTier { NOVICE, SKILLED, VETERAN, ELITE }
   enum EquipSlot { WEAPON, ARMOR, ACCESSORY }
   ```

4. **XP curve precision**: The `int()` cast in `xp_to_next_level()` truncates (floors) the float
   result. This is intentional — fractional XP thresholds don't make gameplay sense. At level 50,
   the threshold is approximately `int(100 * pow(1.15, 49))` = ~86,781 XP, well within int range.

5. **`from_dict()` defensive coding**: Every field is read via `.get(key, default)`. Every numeric
   field is cast to `int()` to handle JSON's float-by-default parsing. Every validation failure
   logs a message and falls back to a safe default rather than crashing.

6. **Deep copy in `to_dict()`**: Both `stats` and `equipment` are `.duplicate(true)` to prevent
   the caller from holding a reference that mutates internal state.

7. **No signals**: This class intentionally has zero signals. Level-up notifications, roster change
   events, and availability state changes are all the responsibility of the manager layer (TASK-013).

8. **Testing without Godot editor**: All tests use GUT assertions and require no scene tree. The
   test suite can run headless via `godot --headless --script res://addons/gut/gut_cmdln.gd`.

---

*End of TASK-006: Adventurer Data Model & Class Definitions*

