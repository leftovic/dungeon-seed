# TASK-004: Seed Data Model & Maturation State Machine

---

## Section 1 · Header

| Field               | Value                                                                                      |
|---------------------|--------------------------------------------------------------------------------------------|
| **Task ID**         | TASK-004                                                                                   |
| **Title**           | Seed Data Model & Maturation State Machine                                                 |
| **Priority**        | 🔴 P0 — Critical Path                                                                     |
| **Tier**            | Tier 2 — Core Models                                                                       |
| **Complexity**      | 8 points (Moderate)                                                                        |
| **Phase**           | Phase 1 — Core Data Models                                                                 |
| **Wave**            | Wave 2                                                                                     |
| **Stream**          | 🔴 MCH (Mechanics) — Primary                                                              |
| **Cross-Stream**    | ⚪ TCH (serialization), 🔵 VIS (phase visual state for future UI), 🟢 AUD (phase change SFX triggers) |
| **GDD Reference**   | GDD-v2.md §4.1 (Seeds — Maturation, Growth Profiles, Mutation Slots, Dungeon Traits)      |
| **Milestone**       | M1 — Core Data Models                                                                      |
| **Dependencies**    | TASK-003 (Enums & Constants) — requires `Enums.SeedRarity`, `Enums.Element`, `Enums.SeedPhase`, `GameConfig.BASE_GROWTH_SECONDS`, `GameConfig.MUTATION_SLOTS`, `GameConfig.PHASE_GROWTH_MULTIPLIERS` |
| **Dependents**      | TASK-012 (Seed Grove Manager), TASK-015 (Dungeon Generation Pipeline), TASK-018 (Save/Load System), TASK-022 (Seed Inventory UI) |
| **Critical Path**   | ✅ YES — Seed Grove Manager, Dungeon Generation, and the entire grow→harvest loop are blocked without this model |
| **Estimated Hours** | 6–10 hours                                                                                 |
| **Engine**          | Godot 4.6 — GDScript                                                                      |
| **Output Files**    | `src/models/seed_data.gd`, `src/models/mutation_slot.gd`, `tests/unit/test_seed_data.gd`   |

---

## Section 2 · Description

### 2.1 — What This Task Produces

This task creates the **SeedData** model — the single most important data structure in Dungeon Seed. Every seed the player plants, grows, mutates, and harvests into a dungeon is an instance of `SeedData`. This model encapsulates:

1. **`src/models/seed_data.gd`** (`class_name SeedData`, extends `RefCounted`) — A pure data class representing a single plantable seed with all GDD §4.1 attributes: rarity, elemental affinity, growth phase, growth progress, growth rate, mutation slots, mutation potential, dungeon generation traits, planting timestamp, and planted status. Includes a deterministic **maturation state machine** that advances the seed through four phases (Spore → Sprout → Bud → Bloom) based on elapsed time and rarity-derived growth rates.

2. **`src/models/mutation_slot.gd`** (`class_name MutationSlot`, extends `RefCounted`) — A lightweight data class representing a single reagent slot on a seed. Each slot has an index, an optional reagent ID, and an effect dictionary that modifies dungeon generation parameters when the seed blooms.

3. **`tests/unit/test_seed_data.gd`** — A comprehensive GUT test suite covering phase transitions, growth rate calculations, mutation slot management, serialization round-trips, edge cases, and state machine invariants.

### 2.2 — Why This Model Is the Core Pillar

The GDD §4.1 identifies seeds as the **primary progression vector** in Dungeon Seed. The entire core loop revolves around seeds:

```
Plant Seed → Grow Seed → Mutate Seed → Bloom → Generate Dungeon → Dispatch Adventurers → Harvest Loot → Upgrade → Plant Better Seed
```

Without `SeedData`, there is no seed to plant, no growth to track, no phase to transition, no dungeon to generate. Every downstream system reads from or writes to this model:

- **Seed Grove Manager (TASK-012)** holds an `Array[SeedData]` of planted seeds and calls `advance_growth()` every frame.
- **Dungeon Generation (TASK-015)** reads `dungeon_traits`, `rarity`, `element`, and `mutation_slots` to parameterize room generation.
- **Save/Load (TASK-018)** calls `to_dict()` to serialize seed state and `from_dict()` to restore it.
- **Seed Inventory UI (TASK-022)** reads `phase`, `growth_progress`, `rarity`, and `element` to render growth bars and rarity badges.
- **EventBus** receives `seed_phase_changed(seed_id, old_phase, new_phase)` when the state machine transitions, allowing the UI to animate, audio to play SFX, and analytics to track.

### 2.3 — Player Experience Impact

The SeedData model directly shapes the player's moment-to-moment experience:

| Player Moment | Model Property | Feel |
|---|---|---|
| "I found a Rare Frost seed!" | `rarity`, `element` | Discovery excitement, collection motivation |
| "My seed is growing... 67% through Sprout" | `phase`, `growth_progress` | Anticipation, idle satisfaction |
| "It just hit Bud phase!" | State machine transition | Milestone dopamine, progress feedback |
| "I applied a Flame Reagent to slot 2" | `mutation_slots[1].reagent_id` | Agency, build crafting |
| "This seed has high room variety" | `dungeon_traits.room_variety` | Strategic evaluation, meaningful choice |
| "My Legendary seed takes forever to grow" | `growth_rate` scaled by rarity | Tension between patience and power |
| "Full Bloom! Time to enter the dungeon" | Terminal BLOOM phase | Payoff, transition to action gameplay |

### 2.4 — Economy Impact

Seeds are the **primary faucet gate** in the economy. A seed's rarity determines:

- **Growth time**: Legendary seeds take 20× longer than Common seeds (1200s vs 60s). This gates access to high-tier dungeons.
- **Mutation slots**: Legendary seeds have 5 slots vs Common's 1. More slots mean more powerful dungeon modifiers, meaning more loot.
- **Dungeon traits**: Higher-rarity seeds produce dungeons with better loot bias, more room variety, and more interesting hazards.

The growth rate constants from `GameConfig.BASE_GROWTH_SECONDS` flow directly through `SeedData.growth_rate` into the state machine. If these numbers are wrong, the entire idle loop pacing breaks.

### 2.5 — Technical Architecture

#### Data Flow Diagram

```
┌────────────────────────────────────────────────────────────────────────┐
│                         SeedData Instance                             │
│                                                                        │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  ┌───────────────────────┐ │
│  │ id       │  │ rarity   │  │ element   │  │ dungeon_traits        │ │
│  │ (String) │  │ (enum)   │  │ (enum)    │  │ { room_variety: 0.6,  │ │
│  └──────────┘  └──────────┘  └───────────┘  │   hazard_freq: 0.3,   │ │
│                                              │   loot_bias: "gold" } │ │
│  ┌──────────────────────────────────────┐   └───────────────────────┘ │
│  │ MATURATION STATE MACHINE            │                              │
│  │                                      │                              │
│  │  SPORE ──▶ SPROUT ──▶ BUD ──▶ BLOOM │                              │
│  │  (×1.0)   (×1.2)    (×1.5)  (term.) │                              │
│  │                                      │                              │
│  │  phase: Enums.SeedPhase              │                              │
│  │  growth_progress: 0.0 → 1.0         │                              │
│  │  growth_rate: base × rarity_mult     │                              │
│  └──────────────────────────────────────┘                              │
│                                                                        │
│  ┌──────────────────────────────────────┐                              │
│  │ MUTATION SLOTS                       │                              │
│  │  [0] MutationSlot { reagent: "",     │                              │
│  │       effect: {} }                   │                              │
│  │  [1] MutationSlot { reagent: "fire", │                              │
│  │       effect: { "hazard_freq": +0.1 }│                              │
│  │  ... (up to 5 for Legendary)         │                              │
│  └──────────────────────────────────────┘                              │
│                                                                        │
│  planted_at: float    is_planted: bool    mutation_potential: float    │
└────────────────────────────────────────────────────────────────────────┘
```

#### State Machine Transition Logic

```
advance_growth(delta_seconds: float) -> Enums.SeedPhase:
    ┌─────────────────────────────────────────────────┐
    │ Guard: is_planted == false?  → return phase     │
    │ Guard: phase == BLOOM?      → return BLOOM      │
    │                                                  │
    │ phase_duration = growth_rate                     │
    │               × PHASE_GROWTH_MULTIPLIERS[phase]  │
    │                                                  │
    │ growth_progress += delta_seconds / phase_duration│
    │                                                  │
    │ if growth_progress >= 1.0:                       │
    │     old_phase = phase                            │
    │     phase = next_phase(phase)                    │
    │     growth_progress = 0.0                        │
    │     → emit seed_phase_changed                    │
    │                                                  │
    │ return phase                                     │
    └─────────────────────────────────────────────────┘
```

#### File Dependency Graph

```
TASK-003 outputs:
  src/models/enums.gd       ← Enums.SeedRarity, Enums.Element, Enums.SeedPhase
  src/models/game_config.gd ← GameConfig.BASE_GROWTH_SECONDS, .MUTATION_SLOTS,
                               .PHASE_GROWTH_MULTIPLIERS

TASK-004 outputs:
  src/models/mutation_slot.gd  ← MutationSlot (inner data class)
  src/models/seed_data.gd      ← SeedData (primary model)
       │
       ├──▶ TASK-012 Seed Grove Manager (holds Array[SeedData])
       ├──▶ TASK-015 Dungeon Generation (reads traits, slots, rarity, element)
       ├──▶ TASK-018 Save/Load (calls to_dict / from_dict)
       └──▶ TASK-022 Seed Inventory UI (reads phase, progress, rarity)
```

#### System Interaction Map

```
┌──────────────────┐    seed_planted       ┌──────────────┐
│  Seed Grove      │───────────────────────▶│  EventBus    │
│  Manager         │    seed_phase_changed  │              │
│  (TASK-012)      │───────────────────────▶│  (TASK-001)  │
│                  │    seed_matured        │              │
│  holds & ticks   │───────────────────────▶│              │
│  SeedData[]      │                        └──────┬───────┘
└──────────────────┘                               │
        │                                          │ signals consumed by
        │ calls advance_growth(delta)              │
        ▼                                          ▼
┌──────────────────┐                     ┌──────────────────┐
│  SeedData        │                     │  UI / Audio /    │
│  (THIS TASK)     │                     │  Analytics       │
│                  │◀────────────────────│                  │
│  pure model +    │   reads phase,      │  reads model for │
│  state machine   │   progress, rarity  │  display/SFX     │
└──────────────────┘                     └──────────────────┘
        │
        │ to_dict() / from_dict()
        ▼
┌──────────────────┐
│  Save/Load       │
│  (TASK-018)      │
└──────────────────┘
```

### 2.6 — Development Cost

| Activity                                  | Estimated Time |
|-------------------------------------------|----------------|
| Write `mutation_slot.gd`                  | 30 min         |
| Write `seed_data.gd` properties & init    | 60 min         |
| Implement maturation state machine        | 90 min         |
| Implement serialization (to_dict/from_dict)| 60 min         |
| Write helper methods & factory functions  | 30 min         |
| Write GUT test suite (full coverage)      | 120 min        |
| Code review & iteration                   | 30 min         |
| **Total**                                 | **~7 hours**   |

### 2.7 — Constraints and Design Decisions

1. **Pure data model, no Node dependency**: `SeedData` extends `RefCounted`, not `Node`. It has zero scene-tree awareness, zero rendering logic, zero input handling. This keeps it testable in isolation and avoids scene-tree coupling.

2. **State machine is pull-based, not timer-based**: `advance_growth()` is called externally (by Seed Grove Manager) with a `delta_seconds` parameter. The model itself does not create timers, connect signals, or run `_process()`. This makes testing deterministic.

3. **Single-phase-per-tick invariant**: `advance_growth()` advances at most one phase per call. If `delta_seconds` is enormous (e.g., offline progress), the caller must loop. This prevents skipping phases and ensures every phase-change signal fires.

4. **BLOOM is terminal**: Once a seed reaches BLOOM, `advance_growth()` is a no-op. Growth progress stays at 0.0, phase stays BLOOM. This is a hard invariant — no code path may transition past BLOOM.

5. **Mutation slots are bounded by rarity**: A Common seed has exactly 1 slot. A Legendary seed has exactly 5. This count is set at creation time from `GameConfig.MUTATION_SLOTS[rarity]` and never changes.

6. **Serialization is symmetric**: `SeedData.from_dict(seed.to_dict())` must produce a logically identical instance. Every field must survive the round-trip. This is tested exhaustively.

7. **No signals on the model itself**: `SeedData` does not declare or emit signals. Signal emission (e.g., `seed_phase_changed`) is the responsibility of the manager that calls `advance_growth()` and detects the phase change from the return value. This keeps the model free of Godot signal infrastructure.

8. **ID generation is deterministic for testing**: The `generate_id()` static method uses a hash-based approach from seed properties for deterministic IDs in tests, but callers may also supply custom IDs.

9. **Existing `src/gdscript/seeds/seed.gd` is superseded**: The old `Seed` class has no phases, no elements, no dungeon traits, and uses integer tick-based growth. It is replaced entirely by `SeedData`. No migration path is needed — the old class has no persisted data.

10. **Dictionary-based dungeon_traits**: Rather than typed sub-objects, `dungeon_traits` is a plain `Dictionary` with string keys. This provides flexibility for the dungeon generation pipeline to add new trait keys without changing the seed model. Keys are validated at creation time against a known set.

---

## Section 3 · Use Cases

### UC-001: New Player Plants Their First Seed

**Actor:** New Player (Timmy archetype — casual, exploration-driven, low system literacy)
**Trigger:** Player receives a Common Terra seed from the tutorial and taps "Plant" in the Seed Grove.
**Preconditions:** Player has completed tutorial step 3. Seed Grove has an empty plot. Player inventory contains one Common Terra seed.
**Flow:**
1. Player drags the seed onto an empty plot in the Seed Grove UI.
2. The Grove Manager creates a `SeedData` instance via `SeedData.create_seed(Enums.SeedRarity.COMMON, Enums.Element.TERRA)`.
3. The model initializes with `phase = SPORE`, `growth_progress = 0.0`, `growth_rate = GameConfig.BASE_GROWTH_SECONDS[COMMON]` (60s), and 1 mutation slot.
4. The manager calls `seed.plant(current_time)`, setting `is_planted = true` and `planted_at = current_time`.
5. Every frame, the Grove Manager calls `seed.advance_growth(delta)`. The UI reads `growth_progress` to animate a progress bar.
6. After ~60 seconds (SPORE phase × 1.0 multiplier), `advance_growth()` returns `SPROUT`. The manager detects the phase change and emits `seed_phase_changed`.
7. The UI plays a sprout animation. The player sees "Sprout Phase — Basic dungeon structure unlocked!"
8. Growth continues through SPROUT → BUD → BLOOM. Total time for Common seed: ~60 × (1.0 + 1.2 + 1.5) = ~222 seconds (~3.7 minutes).
**Postcondition:** Player's first seed reaches BLOOM. The dungeon generation pipeline can now read the seed's traits to create a dungeon.
**Model properties exercised:** `rarity`, `element`, `phase`, `growth_progress`, `growth_rate`, `is_planted`, `planted_at`, `mutation_slots` (1 slot, unused).

### UC-002: Veteran Player Min-Maxes a Legendary Shadow Seed

**Actor:** Min-Maxer (Spike archetype — optimization-driven, seeks maximum power output)
**Trigger:** Player acquires a Legendary Shadow seed from a boss drop and plans to optimize it with reagents before planting.
**Preconditions:** Player has a Legendary Shadow seed, 5 reagents of varying types, and deep knowledge of dungeon trait interactions.
**Flow:**
1. Player inspects the seed in inventory. UI reads `SeedData.dungeon_traits`: `{ room_variety: 0.9, hazard_frequency: 0.7, loot_bias: "artifacts" }`.
2. Player opens the mutation slot panel. Legendary seed has 5 `MutationSlot` instances (from `GameConfig.MUTATION_SLOTS[LEGENDARY]`).
3. Player applies a "Chaos Reagent" to slot 0. The service layer sets `mutation_slots[0].reagent_id = "chaos_reagent"` and `mutation_slots[0].effect = { "room_variety": 0.15 }`.
4. Player applies 4 more reagents to slots 1–4, each modifying different dungeon traits.
5. Player plants the seed. `growth_rate = GameConfig.BASE_GROWTH_SECONDS[LEGENDARY]` = 1200s base.
6. Phase durations: SPORE=1200×1.0=1200s, SPROUT=1200×1.2=1440s, BUD=1200×1.5=1800s. Total: 4440s (~74 minutes).
7. Player uses Booster items (handled by Grove Manager, not this model) to accelerate growth.
8. At each phase transition, the model returns the new phase. The Grove Manager emits signals. The UI updates.
9. At BLOOM, the dungeon generation pipeline reads all 5 mutation slot effects and adds them to the base `dungeon_traits`, creating a heavily modified dungeon.
**Postcondition:** Legendary seed with 5 mutations produces the most powerful dungeon in the game.
**Model properties exercised:** All properties, all 5 mutation slots, full state machine traversal, serialization for save during long growth.

### UC-003: Player Closes Game Mid-Growth and Resumes Later

**Actor:** Casual Player (mobile-style session pattern — plays 5 minutes, closes, returns hours later)
**Trigger:** Player has a Rare Frost seed at 40% through SPROUT phase and closes the game.
**Preconditions:** Seed is planted and actively growing. Save system (TASK-018) is operational.
**Flow:**
1. At save time, the Save system calls `seed.to_dict()`. The returned dictionary contains:
   ```
   { "id": "seed_abc123", "rarity": 2, "element": 2, "phase": 1,
     "growth_progress": 0.4, "growth_rate": 300.0, ... }
   ```
2. Player closes the game. Save file persists to disk.
3. Player reopens the game 2 hours later. Save system loads the dictionary and calls `SeedData.from_dict(data)`.
4. The restored `SeedData` has identical state: phase=SPROUT, growth_progress=0.4, growth_rate=300.0.
5. The Grove Manager calculates offline elapsed time (7200 seconds) and calls `advance_growth()` in a loop, advancing one phase at a time.
6. With 7200 seconds of offline progress, the seed easily completes all remaining phases and reaches BLOOM.
7. Player sees "Your Rare Frost seed bloomed while you were away!"
**Postcondition:** Serialization round-trip preserves exact state. Offline progress advances correctly phase-by-phase.
**Model properties exercised:** `to_dict()`, `from_dict()`, state machine loop for offline catch-up, all field serialization.

### UC-004: Designer Rebalances Growth Timing

**Actor:** Game Designer
**Trigger:** Playtest data shows Common seeds grow too fast — players don't engage with the idle loop.
**Flow:**
1. Designer opens `src/models/game_config.gd` and changes `BASE_GROWTH_SECONDS[COMMON]` from 60 to 120.
2. No changes needed in `seed_data.gd` — the model reads from `GameConfig` at creation time.
3. New Common seeds now take ~120 × (1.0 + 1.2 + 1.5) = ~444 seconds (~7.4 minutes) total.
4. Existing planted seeds (created with old rate) retain their original `growth_rate` of 60.0 — the rate is baked at creation, not read live.
5. Designer runs the test suite to verify the state machine still functions correctly with the new values.
**Postcondition:** Balance change propagates to new seeds. Existing seeds are unaffected. No code changes in the model.
**Model properties exercised:** `growth_rate` baked at creation, independence from live config reads.

---

## Section 4 · Glossary

| Term | Definition |
|---|---|
| **SeedData** | The primary data model for a plantable seed in Dungeon Seed. Extends `RefCounted`. Contains all GDD §4.1 attributes and a maturation state machine. Class name: `SeedData`. |
| **MutationSlot** | A data class representing one reagent slot on a seed. Contains a slot index, optional reagent ID, and an effect dictionary. Class name: `MutationSlot`. |
| **maturation state machine** | The four-phase progression system (Spore → Sprout → Bud → Bloom) that governs seed growth. Each phase has a duration derived from `growth_rate × PHASE_GROWTH_MULTIPLIERS[phase]`. |
| **SeedPhase** | Enum from TASK-003: `SPORE (0), SPROUT (1), BUD (2), BLOOM (3)`. Represents the current growth stage of a seed. |
| **SeedRarity** | Enum from TASK-003: `COMMON (0), UNCOMMON (1), RARE (2), EPIC (3), LEGENDARY (4)`. Determines growth rate, mutation slot count, and dungeon quality. |
| **Element** | Enum from TASK-003: `TERRA (0), FLAME (1), FROST (2), ARCANE (3), SHADOW (4)`. Determines dungeon elemental theme and enemy types. |
| **growth_progress** | A `float` in range [0.0, 1.0] representing completion percentage within the current phase. Resets to 0.0 on phase transition. |
| **growth_rate** | Base seconds per phase for this seed. Derived from `GameConfig.BASE_GROWTH_SECONDS[rarity]` at creation time. Modified by boosters externally. |
| **phase duration** | The actual seconds required to complete a specific phase: `growth_rate × GameConfig.PHASE_GROWTH_MULTIPLIERS[phase]`. |
| **mutation_potential** | A `float` in [0.0, 1.0] representing the probability that applying a reagent produces a beneficial (rather than neutral or negative) mutation. Higher rarity seeds have higher mutation potential. |
| **dungeon_traits** | A `Dictionary` with keys `room_variety`, `hazard_frequency`, and `loot_bias` that parameterize dungeon generation. Values are set at seed creation based on rarity and element. |
| **reagent** | A consumable item that can be applied to a seed's mutation slot to modify dungeon generation parameters. Reagent application is handled by a service layer, not by SeedData itself. |
| **terminal phase** | BLOOM is the terminal (final) phase. Once reached, the state machine halts. No further growth occurs. The seed is ready for dungeon generation. |
| **pull-based state machine** | A state machine that advances only when explicitly called (`advance_growth(delta)`), rather than running on its own timer. Enables deterministic testing and external control. |
| **serialization round-trip** | The property that `SeedData.from_dict(seed.to_dict())` produces a logically identical instance. Every field must survive the conversion to Dictionary and back. |
| **RefCounted** | Godot's default base class. Reference-counted, garbage-collected. No scene tree integration. Ideal for pure data models. |
| **GUT** | Godot Unit Testing framework. All TASK-004 tests use `extends GutTest` and run via the GUT test runner. |
| **offline progress** | The elapsed real time while the game was closed. On resume, the Grove Manager calculates this delta and feeds it to `advance_growth()` in a loop to catch up. |
| **EventBus** | Singleton autoload (TASK-001) that provides typed signals for cross-system communication. SeedData itself does not emit signals — the Grove Manager does after detecting phase changes. |
| **loot_bias** | A string key in `dungeon_traits` indicating preferred drop types: `"gold"`, `"crafting"`, `"artifacts"`, `"balanced"`. Consumed by the loot table generator. |

---

## Section 5 · Out of Scope

The following items are explicitly **NOT** part of TASK-004. They may be addressed in future tasks or are intentionally excluded.

| # | Excluded Item | Reason |
|---|---|---|
| 1 | Seed Grove Manager (planting/harvesting workflow) | TASK-012 — consumes SeedData but owns the grove logic. |
| 2 | Dungeon generation from seed traits | TASK-015 — reads `dungeon_traits` and `mutation_slots` but owns the procedural generation pipeline. |
| 3 | Save/Load persistence layer | TASK-018 — calls `to_dict()`/`from_dict()` but owns file I/O, encryption, and versioning. |
| 4 | Seed Inventory UI (visual rendering) | TASK-022 — reads model properties for display but owns all Control nodes. |
| 5 | Reagent item definitions | A separate item/reagent data model task. MutationSlot stores `reagent_id: String` but does not define what reagents exist. |
| 6 | Booster items (growth acceleration) | Boosters modify `growth_rate` externally via the Grove Manager or a service. SeedData does not know about boosters. |
| 7 | Signal emission on phase change | EventBus signals are emitted by the Seed Grove Manager, not by SeedData. The model returns the new phase from `advance_growth()` and the caller decides whether to emit. |
| 8 | Seed acquisition/drop logic | How players obtain seeds (shop, boss drops, crafting) is outside this model's scope. |
| 9 | Visual/audio assets for phases | Sprite sheets, particle effects, and sound effects for phase transitions belong to VIS/AUD streams. |
| 10 | Multi-phase advancement in single call | `advance_growth()` advances at most one phase per invocation. Multi-phase catch-up (offline progress) requires the caller to loop. |
| 11 | Seed fusion/combining mechanics | Future feature. SeedData does not support merging two seeds into one. |
| 12 | Procedural seed name generation | Seed naming (e.g., "Frostwhisper Spore") is a presentation concern handled by UI, not the data model. |
| 13 | Network synchronization | Dungeon Seed is single-player. No multiplayer sync of seed state. |
| 14 | Undo/redo for mutation slot application | Once a reagent is applied to a slot, it cannot be removed via this model. Undo mechanics belong to a service layer. |

---

## Section 6 · Functional Requirements

### SeedData Core Properties

| ID | Requirement | GDD Ref | Priority | Testable |
|---|---|---|---|---|
| FR-001 | `seed_data.gd` MUST declare `class_name SeedData` and `extends RefCounted`. | — | MUST | ✅ |
| FR-002 | `SeedData` MUST have a property `id: String` that uniquely identifies the seed instance. | §4.1 | MUST | ✅ |
| FR-003 | `SeedData` MUST have a property `rarity: Enums.SeedRarity` representing the seed's rarity tier. | §4.1 | MUST | ✅ |
| FR-004 | `SeedData` MUST have a property `element: Enums.Element` representing the seed's elemental affinity. | §4.1 | MUST | ✅ |
| FR-005 | `SeedData` MUST have a property `phase: Enums.SeedPhase` initialized to `Enums.SeedPhase.SPORE`. | §4.1 | MUST | ✅ |
| FR-006 | `SeedData` MUST have a property `growth_progress: float` initialized to `0.0`, clamped to range [0.0, 1.0]. | §4.1 | MUST | ✅ |
| FR-007 | `SeedData` MUST have a property `growth_rate: float` representing base seconds per phase. | §4.1 | MUST | ✅ |
| FR-008 | `SeedData.growth_rate` MUST be initialized from `GameConfig.BASE_GROWTH_SECONDS[rarity]` when created via the factory method. | §4.1 | MUST | ✅ |
| FR-009 | `SeedData` MUST have a property `mutation_slots: Array[MutationSlot]` containing exactly `GameConfig.MUTATION_SLOTS[rarity]` elements when created via the factory method. | §4.1 | MUST | ✅ |
| FR-010 | `SeedData` MUST have a property `mutation_potential: float` in range [0.0, 1.0]. | §4.1 | MUST | ✅ |
| FR-011 | `SeedData` MUST have a property `dungeon_traits: Dictionary` with keys `"room_variety"` (float), `"hazard_frequency"` (float), and `"loot_bias"` (String). | §4.1 | MUST | ✅ |
| FR-012 | `SeedData` MUST have a property `planted_at: float` initialized to `0.0` (unplanted). | §4.1 | MUST | ✅ |
| FR-013 | `SeedData` MUST have a property `is_planted: bool` initialized to `false`. | §4.1 | MUST | ✅ |

### MutationSlot

| ID | Requirement | GDD Ref | Priority | Testable |
|---|---|---|---|---|
| FR-014 | `mutation_slot.gd` MUST declare `class_name MutationSlot` and `extends RefCounted`. | §4.1 | MUST | ✅ |
| FR-015 | `MutationSlot` MUST have a property `slot_index: int` representing its position in the slot array. | §4.1 | MUST | ✅ |
| FR-016 | `MutationSlot` MUST have a property `reagent_id: String` initialized to `""` (empty = unused). | §4.1 | MUST | ✅ |
| FR-017 | `MutationSlot` MUST have a property `effect: Dictionary` initialized to `{}` (empty = no modifiers). | §4.1 | MUST | ✅ |
| FR-018 | `MutationSlot` MUST have a method `is_empty() -> bool` that returns `true` when `reagent_id == ""`. | — | MUST | ✅ |
| FR-019 | `MutationSlot` MUST have methods `to_dict() -> Dictionary` and `static from_dict(d: Dictionary) -> MutationSlot` for serialization. | — | MUST | ✅ |

### Maturation State Machine

| ID | Requirement | GDD Ref | Priority | Testable |
|---|---|---|---|---|
| FR-020 | `SeedData` MUST have a method `advance_growth(delta_seconds: float) -> Enums.SeedPhase`. | §4.1 | MUST | ✅ |
| FR-021 | `advance_growth()` MUST return the current phase without modifying state when `is_planted == false`. | §4.1 | MUST | ✅ |
| FR-022 | `advance_growth()` MUST return `Enums.SeedPhase.BLOOM` without modifying state when `phase == BLOOM`. | §4.1 | MUST | ✅ |
| FR-023 | `advance_growth()` MUST calculate phase duration as `growth_rate * GameConfig.PHASE_GROWTH_MULTIPLIERS[phase]`. | §4.1 | MUST | ✅ |
| FR-024 | `advance_growth()` MUST increment `growth_progress` by `delta_seconds / phase_duration`. | §4.1 | MUST | ✅ |
| FR-025 | When `growth_progress >= 1.0`, `advance_growth()` MUST transition `phase` to the next sequential `SeedPhase` value. | §4.1 | MUST | ✅ |
| FR-026 | On phase transition, `advance_growth()` MUST reset `growth_progress` to `0.0`. | §4.1 | MUST | ✅ |
| FR-027 | `advance_growth()` MUST advance at most one phase per invocation, even if `delta_seconds` exceeds the current phase duration. | — | MUST | ✅ |
| FR-028 | `advance_growth()` MUST NOT allow `phase` to exceed `Enums.SeedPhase.BLOOM` (value 3). | §4.1 | MUST | ✅ |
| FR-029 | `advance_growth()` MUST NOT accept negative `delta_seconds`. If negative, it MUST return the current phase unchanged. | — | MUST | ✅ |
| FR-030 | The phase transition order MUST be exactly: SPORE → SPROUT → BUD → BLOOM. No phase may be skipped. | §4.1 | MUST | ✅ |

### Factory & Initialization

| ID | Requirement | GDD Ref | Priority | Testable |
|---|---|---|---|---|
| FR-031 | `SeedData` MUST have a static method `create_seed(rarity: Enums.SeedRarity, element: Enums.Element, custom_id: String = "") -> SeedData` that returns a fully initialized instance. | — | MUST | ✅ |
| FR-032 | `create_seed()` MUST generate a unique `id` if `custom_id` is empty, using `generate_id()`. | — | MUST | ✅ |
| FR-033 | `create_seed()` MUST initialize `growth_rate` from `GameConfig.BASE_GROWTH_SECONDS[rarity]` cast to `float`. | §4.1 | MUST | ✅ |
| FR-034 | `create_seed()` MUST create exactly `GameConfig.MUTATION_SLOTS[rarity]` `MutationSlot` instances with sequential `slot_index` values starting at 0. | §4.1 | MUST | ✅ |
| FR-035 | `create_seed()` MUST initialize `dungeon_traits` with default values based on rarity: higher rarity → higher `room_variety` and `hazard_frequency`. | §4.1 | MUST | ✅ |
| FR-036 | `create_seed()` MUST initialize `mutation_potential` scaled by rarity: COMMON=0.1, UNCOMMON=0.2, RARE=0.4, EPIC=0.6, LEGENDARY=0.8. | §4.1 | MUST | ✅ |

### Planting

| ID | Requirement | GDD Ref | Priority | Testable |
|---|---|---|---|---|
| FR-037 | `SeedData` MUST have a method `plant(timestamp: float) -> void` that sets `is_planted = true` and `planted_at = timestamp`. | §4.1 | MUST | ✅ |
| FR-038 | `plant()` MUST NOT allow planting an already-planted seed. If `is_planted == true`, the call MUST be a no-op. | — | MUST | ✅ |
| FR-039 | `plant()` MUST NOT accept a timestamp of `0.0` or negative. If invalid, the call MUST be a no-op. | — | MUST | ✅ |

### Serialization

| ID | Requirement | GDD Ref | Priority | Testable |
|---|---|---|---|---|
| FR-040 | `SeedData` MUST have a method `to_dict() -> Dictionary` that serializes all properties to a plain Dictionary. | — | MUST | ✅ |
| FR-041 | `to_dict()` MUST serialize enum values as their integer representation (e.g., `Enums.SeedRarity.RARE` → `2`). | — | MUST | ✅ |
| FR-042 | `to_dict()` MUST serialize `mutation_slots` as an `Array` of `MutationSlot.to_dict()` results. | — | MUST | ✅ |
| FR-043 | `SeedData` MUST have a static method `from_dict(data: Dictionary) -> SeedData` that reconstructs an instance from a serialized Dictionary. | — | MUST | ✅ |
| FR-044 | `from_dict()` MUST restore enum values from their integer representations. | — | MUST | ✅ |
| FR-045 | `from_dict()` MUST reconstruct `mutation_slots` from the serialized array using `MutationSlot.from_dict()`. | — | MUST | ✅ |
| FR-046 | The round-trip `SeedData.from_dict(seed.to_dict())` MUST produce a logically identical instance: all properties MUST match the original. | — | MUST | ✅ |

### Helpers

| ID | Requirement | GDD Ref | Priority | Testable |
|---|---|---|---|---|
| FR-047 | `SeedData` MUST have a static method `generate_id() -> String` that returns a unique string identifier. | — | MUST | ✅ |
| FR-048 | `SeedData` MUST have a method `get_phase_duration() -> float` returning the current phase's duration in seconds (`growth_rate * PHASE_GROWTH_MULTIPLIERS[phase]`). | — | MUST | ✅ |
| FR-049 | `SeedData` MUST have a method `get_total_growth_time() -> float` returning the sum of all phase durations from SPORE to BUD (3 phases, since BLOOM has no duration). | — | MUST | ✅ |
| FR-050 | `SeedData` MUST have a method `get_remaining_time() -> float` returning estimated seconds until BLOOM, based on current phase and progress. | — | MUST | ✅ |
| FR-051 | `SeedData` MUST have a method `get_overall_progress() -> float` returning a [0.0, 1.0] value representing total maturation progress across all phases. | — | MUST | ✅ |
| FR-052 | `SeedData` MUST have a method `get_filled_slot_count() -> int` returning the number of mutation slots with non-empty `reagent_id`. | — | MUST | ✅ |
| FR-053 | `SeedData` MUST have a method `get_slot(index: int) -> MutationSlot` returning the mutation slot at the given index, or `null` if out of bounds. | — | MUST | ✅ |

---

## Section 7 · Non-Functional Requirements

| ID | Requirement | Category | Priority | Testable |
|---|---|---|---|---|
| NFR-001 | `SeedData` instantiation via `create_seed()` MUST complete in under 1ms on a mid-range desktop CPU (i5-class, 2020+). | Performance | MUST | ✅ |
| NFR-002 | `advance_growth()` MUST complete in under 0.01ms per call (100,000 calls/second budget for 60fps with 100 planted seeds). | Performance | MUST | ✅ |
| NFR-003 | `to_dict()` MUST complete in under 0.1ms per call. | Performance | MUST | ✅ |
| NFR-004 | `from_dict()` MUST complete in under 0.1ms per call. | Performance | MUST | ✅ |
| NFR-005 | A single `SeedData` instance MUST consume less than 2KB of heap memory (properties + mutation slots). | Memory | MUST | ✅ |
| NFR-006 | All public methods MUST use GDScript static type hints on parameters and return values. | Code Quality | MUST | ✅ |
| NFR-007 | All public methods MUST include a doc comment (`##`) describing purpose, parameters, and return value. | Code Quality | MUST | ✅ |
| NFR-008 | `SeedData` and `MutationSlot` MUST have zero dependencies on Node, scene tree, or any autoload singleton at runtime. | Architecture | MUST | ✅ |
| NFR-009 | `SeedData` MUST be safe to instantiate and use in GUT tests without a running SceneTree. | Testability | MUST | ✅ |
| NFR-010 | `SeedData` MUST NOT emit signals, create timers, or access `Engine.get_main_loop()`. | Architecture | MUST NOT | ✅ |
| NFR-011 | All magic numbers MUST be replaced with references to `GameConfig` constants. | Maintainability | MUST | ✅ |
| NFR-012 | File names MUST use snake_case: `seed_data.gd`, `mutation_slot.gd`. | Naming | MUST | ✅ |
| NFR-013 | `to_dict()` output MUST be JSON-serializable (no Godot-specific types like `Color`, `Vector2`, or object references). | Serialization | MUST | ✅ |
| NFR-014 | `from_dict()` MUST gracefully handle missing optional keys by using default values, rather than crashing. | Robustness | MUST | ✅ |
| NFR-015 | The state machine MUST be deterministic: given the same `SeedData` state and the same `delta_seconds` input, the output MUST always be identical. | Correctness | MUST | ✅ |
| NFR-016 | `SeedData` MUST be thread-safe for read operations (no mutable global state). Write operations (advance_growth, plant) are single-threaded by design. | Thread Safety | SHOULD | ✅ |
| NFR-017 | Test coverage for `seed_data.gd` MUST exceed 95% line coverage and 90% branch coverage. | Testing | MUST | ✅ |

---

## Section 8 · Designer's Manual

### 8.1 — Tuning Guide: Growth Timing

The seed growth system has three layers of timing control. Each layer multiplies with the others to produce the final phase duration:

**Layer 1: Base Growth Rate (set at seed creation)**

```
growth_rate = float(GameConfig.BASE_GROWTH_SECONDS[rarity])
```

| Rarity | Base Seconds | Total Time (all phases) | Player Feel |
|---|---|---|---|
| COMMON | 60 | ~222s (~3.7 min) | Quick gratification, tutorial-friendly |
| UNCOMMON | 120 | ~444s (~7.4 min) | Short session goal |
| RARE | 300 | ~1110s (~18.5 min) | Medium-term investment |
| EPIC | 600 | ~2220s (~37 min) | Meaningful commitment |
| LEGENDARY | 1200 | ~4440s (~74 min) | Major milestone, possibly multi-session |

**Layer 2: Phase Growth Multipliers (from GameConfig)**

Each phase takes a different proportion of the base growth rate:

```
GameConfig.PHASE_GROWTH_MULTIPLIERS = {
    Enums.SeedPhase.SPORE:  1.0,   # Baseline — fastest phase
    Enums.SeedPhase.SPROUT: 1.2,   # 20% longer — building anticipation
    Enums.SeedPhase.BUD:    1.5,   # 50% longer — delayed gratification peak
}
# BLOOM has no multiplier — it is terminal, growth stops.
```

**Phase duration formula:**
```
phase_duration_seconds = growth_rate × PHASE_GROWTH_MULTIPLIERS[current_phase]
```

**Example — Common Seed:**
| Phase | Multiplier | Duration | Cumulative |
|---|---|---|---|
| SPORE | ×1.0 | 60s | 60s |
| SPROUT | ×1.2 | 72s | 132s |
| BUD | ×1.5 | 90s | 222s |
| BLOOM | terminal | — | 222s total |

**Layer 3: External Modifiers (NOT in this model)**

The Seed Grove Manager (TASK-012) may apply external multipliers to `delta_seconds` before passing it to `advance_growth()`:
- Booster items: multiply delta by 1.5×, 2×, etc.
- Environmental bonuses: Terra seeds in Terra-themed grove get 1.1× speed
- These are NOT part of SeedData — they are applied by the caller.

### 8.2 — Tuning Guide: Mutation Slots

Mutation slots scale linearly with rarity:

| Rarity | Slot Count | Design Intent |
|---|---|---|
| COMMON | 1 | Minimal customization — training wheels |
| UNCOMMON | 2 | Introduce the concept of slot synergy |
| RARE | 3 | Sweet spot for build diversity |
| EPIC | 4 | Deep customization, meta-game territory |
| LEGENDARY | 5 | Maximum investment, maximum payoff |

**Mutation Potential** determines the probability that a reagent produces a beneficial effect:

| Rarity | Mutation Potential | Design Intent |
|---|---|---|
| COMMON | 0.1 (10%) | Most mutations are neutral — low risk/reward |
| UNCOMMON | 0.2 (20%) | Slightly better odds |
| RARE | 0.4 (40%) | Coin-flip territory — exciting |
| EPIC | 0.6 (60%) | More likely positive than not |
| LEGENDARY | 0.8 (80%) | Almost guaranteed positive — worth the investment |

### 8.3 — Tuning Guide: Dungeon Traits

Default dungeon traits are assigned at seed creation based on rarity:

```gdscript
# In create_seed() factory method:
var base_variety: float = 0.3 + (rarity * 0.15)     # COMMON=0.3, LEGENDARY=0.9
var base_hazard: float = 0.2 + (rarity * 0.1)       # COMMON=0.2, LEGENDARY=0.6
var bias_options: Array[String] = ["gold", "crafting", "artifacts", "balanced"]
var base_bias: String = bias_options[mini(rarity, bias_options.size() - 1)]
```

| Rarity | room_variety | hazard_frequency | loot_bias | Design Intent |
|---|---|---|---|---|
| COMMON | 0.30 | 0.20 | "gold" | Simple dungeons, gold focus |
| UNCOMMON | 0.45 | 0.30 | "crafting" | More variety, crafting materials |
| RARE | 0.60 | 0.40 | "artifacts" | Interesting layouts, rare drops |
| EPIC | 0.75 | 0.50 | "balanced" | High variety, balanced rewards |
| LEGENDARY | 0.90 | 0.60 | "balanced" | Maximum variety and challenge |

### 8.4 — Config Reference: All Configurable Parameters

| Parameter | Location | Type | Range | Default | Effect |
|---|---|---|---|---|---|
| `BASE_GROWTH_SECONDS` | `GameConfig` | `Dict[SeedRarity→int]` | 1–86400 | 60–1200 | Base seconds per phase by rarity |
| `MUTATION_SLOTS` | `GameConfig` | `Dict[SeedRarity→int]` | 1–10 | 1–5 | Number of reagent slots by rarity |
| `PHASE_GROWTH_MULTIPLIERS` | `GameConfig` | `Dict[SeedPhase→float]` | 0.1–10.0 | 1.0–1.5 | Per-phase duration scaling |
| `mutation_potential` | `SeedData` | `float` | 0.0–1.0 | 0.1–0.8 | Beneficial mutation probability |
| `dungeon_traits.room_variety` | `SeedData` | `float` | 0.0–1.0 | 0.3–0.9 | Room type diversity in dungeon |
| `dungeon_traits.hazard_frequency` | `SeedData` | `float` | 0.0–1.0 | 0.2–0.6 | How often hazards appear |
| `dungeon_traits.loot_bias` | `SeedData` | `String` | enum-like | rarity-based | Preferred loot category |

### 8.5 — Signal Map (Consumed by EventBus via Grove Manager)

These signals are NOT emitted by SeedData itself, but by the Seed Grove Manager (TASK-012) after calling `advance_growth()` and detecting state changes:

| Signal | Parameters | Trigger | Consumers |
|---|---|---|---|
| `seed_planted` | `seed_id: String, rarity: int, element: int` | After `plant()` is called | UI (show planting animation), Audio (plant SFX) |
| `seed_phase_changed` | `seed_id: String, old_phase: int, new_phase: int` | When `advance_growth()` returns a different phase | UI (phase transition animation), Audio (phase SFX), Analytics |
| `seed_matured` | `seed_id: String, rarity: int, element: int` | When `advance_growth()` transitions to BLOOM | UI (bloom celebration), Dungeon Generator (enable dungeon entry) |

### 8.6 — How the Grove Manager Calls SeedData

```gdscript
# In Seed Grove Manager's _process(delta):
for seed: SeedData in planted_seeds:
    var old_phase: Enums.SeedPhase = seed.phase
    var new_phase: Enums.SeedPhase = seed.advance_growth(delta)
    if new_phase != old_phase:
        EventBus.seed_phase_changed.emit(seed.id, old_phase, new_phase)
        if new_phase == Enums.SeedPhase.BLOOM:
            EventBus.seed_matured.emit(seed.id, seed.rarity, seed.element)
```

### 8.7 — How Save/Load Calls SeedData

```gdscript
# Saving:
var seed_array: Array[Dictionary] = []
for seed: SeedData in all_seeds:
    seed_array.append(seed.to_dict())
save_data["seeds"] = seed_array

# Loading:
for seed_dict: Dictionary in save_data["seeds"]:
    var seed: SeedData = SeedData.from_dict(seed_dict)
    restored_seeds.append(seed)
```

### 8.8 — Offline Progress Pattern

```gdscript
# When game resumes after being closed:
var elapsed_offline: float = current_time - last_save_time
for seed: SeedData in planted_seeds:
    var remaining: float = elapsed_offline
    while remaining > 0.0 and seed.phase != Enums.SeedPhase.BLOOM:
        var phase_time_left: float = seed.get_phase_duration() * (1.0 - seed.growth_progress)
        if remaining >= phase_time_left:
            seed.advance_growth(phase_time_left)
            remaining -= phase_time_left
        else:
            seed.advance_growth(remaining)
            remaining = 0.0
```

---

## Section 9 · Assumptions

| # | Assumption | Impact if Wrong | Mitigation |
|---|---|---|---|
| 1 | TASK-003 is merged and `Enums.SeedRarity`, `Enums.Element`, `Enums.SeedPhase`, `GameConfig.BASE_GROWTH_SECONDS`, `GameConfig.MUTATION_SLOTS`, and `GameConfig.PHASE_GROWTH_MULTIPLIERS` are all available. | TASK-004 cannot compile. | TASK-004 is Wave 2; TASK-003 is Wave 1. Dependency is explicit. |
| 2 | Godot 4.6 GDScript supports `class_name` on `RefCounted` scripts without scene tree registration. | Models would need `preload()` instead. | Verified in Godot 4.x documentation — `class_name` works on all script types. |
| 3 | GDScript `Array[MutationSlot]` typed arrays enforce type safety at runtime. | Untyped array could accept wrong types. | Godot 4.x typed arrays do enforce types. Manual validation as fallback. |
| 4 | `GameConfig.PHASE_GROWTH_MULTIPLIERS` does NOT contain a key for `BLOOM`. Only SPORE, SPROUT, and BUD have multipliers. | `advance_growth()` would crash if it tried to look up BLOOM's multiplier. | Guard clause returns early when `phase == BLOOM` before any multiplier lookup. |
| 5 | Seeds are single-threaded — only one thread calls `advance_growth()` on any given `SeedData` instance at a time. | Race conditions on `growth_progress` and `phase`. | Godot's main loop is single-threaded. Document this assumption. |
| 6 | `growth_rate` is immutable after creation. Boosters modify `delta_seconds` externally, not `growth_rate` on the model. | If boosters modify `growth_rate`, serialization and balance become more complex. | Design decision documented in Section 2.7. Boosters are external multipliers. |
| 7 | `dungeon_traits` keys are a fixed set: `"room_variety"`, `"hazard_frequency"`, `"loot_bias"`. No dynamic keys. | Dungeon generation might expect additional keys. | Validate keys at creation time. Add new keys via model version migration if needed. |
| 8 | The `id` field is unique across all seeds in a save file. No collision detection is needed beyond the generation algorithm. | Duplicate IDs would cause save/load corruption. | UUID-style generation has negligible collision probability. |
| 9 | `float` precision is sufficient for growth_progress tracking. No fixed-point arithmetic needed. | Rounding errors could cause phase transitions to trigger slightly early/late. | IEEE 754 float64 has ~15 decimal digits of precision — more than enough for [0.0, 1.0] range. |
| 10 | The old `src/gdscript/seeds/seed.gd` (`class_name Seed`) has no persistent save data that needs migration. | Players could lose data. | Game is pre-alpha. No player save files exist. Old class is completely superseded. |
| 11 | `MutationSlot.effect` dictionary values are always numeric (floats/ints) or strings — no nested dictionaries or arrays. | Serialization could fail on complex types. | Validate effect dictionary contents at assignment time. |
| 12 | The four-phase system (SPORE → SPROUT → BUD → BLOOM) is final for MVP. No additional phases will be added before v1.0. | Adding phases would require state machine changes and save migration. | Enum-based design makes adding phases relatively easy — add to enum, add multiplier, increment next_phase. |
| 13 | `planted_at` timestamps use engine time (`Time.get_unix_time_from_system()` or equivalent), not frame counts. | Time-based calculations would be wrong with frame-based timestamps. | Document the expected timestamp source in the `plant()` method doc comment. |

---

## Section 10 · Security & Anti-Cheat

### THREAT-001: Save File Manipulation — Growth Acceleration

**Exploit Vector:** Player edits the save file (JSON/Dictionary) to set `growth_progress` to 0.99 or `phase` to BLOOM on a freshly planted seed, bypassing the entire growth timer.

**Impact:** Severe — undermines the core idle loop. Players skip 74 minutes of Legendary seed growth instantly.

**Mitigations:**
1. **Validation on load**: `from_dict()` validates that `growth_progress` is in [0.0, 1.0] and `phase` is a valid `SeedPhase` enum value. Invalid values are clamped or reset to defaults.
2. **Planted-time cross-check**: The Grove Manager validates that `planted_at + elapsed_growth_time >= expected_time_for_current_phase`. If the seed claims to be at BUD but was planted 5 seconds ago, flag as suspicious.
3. **Checksum layer** (TASK-018): The save/load system applies a checksum to the serialized data. Tampering invalidates the checksum, triggering a save corruption warning.

### THREAT-002: Save File Manipulation — Rarity Escalation

**Exploit Vector:** Player edits the save file to change `rarity` from 0 (COMMON) to 4 (LEGENDARY), gaining 5 mutation slots and superior dungeon traits from a Common seed.

**Impact:** High — breaks the rarity progression curve. Players skip the collection/upgrade loop entirely.

**Mitigations:**
1. **Consistency validation**: On load, verify that `mutation_slots.size() == GameConfig.MUTATION_SLOTS[rarity]`. If mismatch, reset the seed or flag as corrupted.
2. **Trait range validation**: Verify that `dungeon_traits` values fall within expected ranges for the claimed rarity. A COMMON seed with `room_variety: 0.9` is suspicious.
3. **Checksum layer** (TASK-018): Same as THREAT-001.

### THREAT-003: Memory Manipulation — Runtime Phase Override

**Exploit Vector:** Player uses a memory editor (Cheat Engine) to locate the `phase` variable in RAM and set it to BLOOM directly.

**Impact:** High — same as THREAT-001 but harder to detect since it bypasses save files.

**Mitigations:**
1. **Server-side validation** (future, if multiplayer is added): Client seed state is validated against server records.
2. **Consistency checks**: When a seed enters BLOOM, the Grove Manager checks that the seed has been planted for at least `get_total_growth_time() * 0.5` seconds (allowing for boosters). If not, flag as suspicious.
3. **Accept for single-player**: Dungeon Seed is a single-player game. Memory editing is the player's choice and does not affect others. Log the anomaly for analytics but do not punish.

### THREAT-004: Mutation Slot Overflow — Adding Extra Slots

**Exploit Vector:** Player manipulates save data to add more `mutation_slots` entries than `GameConfig.MUTATION_SLOTS[rarity]` allows (e.g., 10 slots on a Common seed).

**Impact:** Medium — overpowered dungeon generation from excessive mutations.

**Mitigations:**
1. **Array size validation in `from_dict()`**: If `mutation_slots` array length exceeds `GameConfig.MUTATION_SLOTS[rarity]`, truncate to the allowed count.
2. **Immutable slot count**: `SeedData` does not expose a method to add or remove slots after creation. The `mutation_slots` array length is set once in `create_seed()` and in `from_dict()`.
3. **Slot index validation**: `get_slot(index)` returns `null` for out-of-bounds indices rather than crashing.

### THREAT-005: Negative Delta Injection

**Exploit Vector:** A modified client passes negative `delta_seconds` to `advance_growth()`, potentially reversing growth or causing underflow in `growth_progress`.

**Impact:** Low — could cause seeds to never mature or exhibit undefined behavior.

**Mitigations:**
1. **Guard clause**: `advance_growth()` checks `delta_seconds <= 0.0` and returns current phase immediately without modifying state.
2. **Clamp progress**: `growth_progress` is clamped to [0.0, 1.0] after every modification as a defense-in-depth measure.

---

## Section 11 · Best Practices

| # | Practice | Rationale |
|---|---|---|
| 1 | **Use typed properties everywhere**: `var rarity: Enums.SeedRarity`, not `var rarity: int`. | GDScript's type system catches assignment errors at parse time. Enum types provide IDE autocomplete and prevent invalid values. |
| 2 | **Use `RefCounted`, never `Node`**: Data models must not depend on the scene tree. `RefCounted` provides automatic memory management without scene-tree coupling. | Keeps models testable in isolation. GUT tests can instantiate `SeedData` without `add_child()`. |
| 3 | **Factory method pattern**: Use `SeedData.create_seed()` static factory instead of exposing `_init()` with many parameters. | Centralizes initialization logic, sets derived fields (growth_rate, mutation_slots, dungeon_traits) consistently, and provides a clean public API. |
| 4 | **Guard clauses at method entry**: Check preconditions (`is_planted`, `phase != BLOOM`, `delta > 0`) at the top of `advance_growth()` and return early. | Prevents defensive code from being scattered throughout the method body. Makes control flow obvious. |
| 5 | **Single-responsibility state machine**: `advance_growth()` only advances growth. It does not emit signals, update UI, play sounds, or write to disk. | The caller (Grove Manager) decides what to do with the result. This separation enables deterministic testing and clean architecture. |
| 6 | **Immutable after creation for structural fields**: `rarity`, `element`, `growth_rate`, and `mutation_slots.size()` do not change after `create_seed()`. | Prevents mid-lifecycle mutations that would break serialization consistency and balance assumptions. |
| 7 | **Serialize enums as integers**: `to_dict()` stores `rarity` as `2` (not `"RARE"` or `"Enums.SeedRarity.RARE"`). | Integers are compact, fast to compare, and immune to enum rename refactors. `from_dict()` casts back to the enum type. |
| 8 | **Defensive deserialization**: `from_dict()` uses `data.get("key", default_value)` for every field, never raw `data["key"]`. | Handles missing keys gracefully (e.g., loading a save from a version that didn't have `mutation_potential`). |
| 9 | **Doc comments (`##`) on all public methods**: Every public method has a `##` doc comment explaining its purpose, parameters, return value, and any preconditions. | GDScript `##` comments are displayed in the Godot editor's documentation panel. |
| 10 | **Test-driven development**: Write GUT tests for each FR before (or alongside) the implementation. Red-green-refactor cycle. | Ensures the state machine behaves correctly before downstream tasks depend on it. |
| 11 | **Use `clampf()` for float bounds**: Always clamp `growth_progress` to [0.0, 1.0] after arithmetic. Never trust floating-point addition to stay in bounds. | IEEE 754 floating-point arithmetic can produce values like 1.0000000001 due to rounding. Explicit clamping prevents off-by-epsilon bugs. |
| 12 | **Avoid `_init()` parameter overload**: GDScript `_init()` should have zero or very few parameters. Use the factory method to set fields after construction. | GDScript's `_init()` with many parameters is hard to read and prone to argument-order bugs. The factory method uses named field assignment. |
| 13 | **Keep serialized dictionary flat**: `to_dict()` output should be a single-level dictionary (except for `mutation_slots` array and `dungeon_traits` sub-dict). No deeply nested structures. | Flat dictionaries are easier to inspect in debug logs, easier to version-migrate, and faster to serialize/deserialize. |
| 14 | **Use constants for dungeon trait keys**: Define trait key strings as class constants (`const TRAIT_ROOM_VARIETY := "room_variety"`) to avoid typos in dictionary access. | A typo in a string key silently returns `null`. A typo in a constant name is a compile-time error. |

---

## Section 12 · Troubleshooting

### ISSUE-001: Seed Never Advances Past SPORE

**Symptoms:** `advance_growth()` always returns `SPORE`. `growth_progress` stays at 0.0 or increases very slowly.

**Possible Causes:**
1. `is_planted` is `false` — the seed was never planted. `advance_growth()` returns early without modifying state.
2. `delta_seconds` passed to `advance_growth()` is very small (e.g., frame delta of 0.016s) and the phase duration is very long (e.g., 1200s for Legendary SPORE).
3. `growth_rate` is unexpectedly large (e.g., `BASE_GROWTH_SECONDS` returns a much larger value than expected).
4. The Grove Manager is not calling `advance_growth()` in its `_process()` loop.

**Solutions:**
1. Verify `seed.is_planted == true` before expecting growth.
2. Check `seed.get_phase_duration()` to confirm the expected phase duration. For a Common seed in SPORE, it should be 60.0 seconds.
3. Print `delta_seconds` in the Grove Manager to verify it is receiving frame delta correctly.
4. Add a debug print in `advance_growth()`: `print("advance_growth: delta=", delta_seconds, " progress=", growth_progress, " phase=", phase)`.

### ISSUE-002: Phase Skips (SPORE → BUD, Missing SPROUT)

**Symptoms:** Seed jumps from SPORE to BUD without passing through SPROUT. `seed_phase_changed` signal fires only once.

**Possible Causes:**
1. `advance_growth()` is being called with an enormous `delta_seconds` (e.g., entire offline duration in one call) and the implementation incorrectly advances multiple phases in a single call.
2. The `next_phase()` helper returns wrong values (e.g., SPORE → BUD instead of SPORE → SPROUT).

**Solutions:**
1. Verify that `advance_growth()` advances AT MOST ONE phase per call (FR-027). The caller must loop for multi-phase catch-up.
2. Check the `next_phase()` method: it should return `phase + 1` clamped to BLOOM. Unit test this helper explicitly.
3. Use the offline progress pattern from Section 8.8, which correctly loops.

### ISSUE-003: Serialization Round-Trip Loses Data

**Symptoms:** After `SeedData.from_dict(seed.to_dict())`, some fields are wrong — e.g., `mutation_slots` is empty, `dungeon_traits` is missing keys, or `rarity` is wrong.

**Possible Causes:**
1. `to_dict()` is missing a field (forgot to serialize `mutation_potential`, for example).
2. `from_dict()` is reading the wrong key name (e.g., `data.get("growth_prog", 0.0)` instead of `data.get("growth_progress", 0.0)`).
3. Enum values are serialized as strings but deserialized as integers (or vice versa).
4. `MutationSlot.to_dict()` or `MutationSlot.from_dict()` has a bug.

**Solutions:**
1. Run the round-trip test (AC-040 through AC-042). It will catch any asymmetry.
2. Add a `_debug_compare(other: SeedData) -> Array[String]` method that returns a list of differing field names. Use it in tests.
3. Ensure enum serialization is always integer: `"rarity": int(rarity)` in `to_dict()`, `Enums.SeedRarity.values()[data.get("rarity", 0)]` in `from_dict()`.

### ISSUE-004: Mutation Slot Count Mismatch After Load

**Symptoms:** A Rare seed (should have 3 slots) loads with 1 slot or 5 slots.

**Possible Causes:**
1. `from_dict()` is not reading the `mutation_slots` array from the serialized data.
2. The serialized data was manually edited (save tampering — see THREAT-004).
3. The save file is from a version where `MUTATION_SLOTS` had different values.

**Solutions:**
1. Verify `from_dict()` reads `data.get("mutation_slots", [])` and reconstructs each `MutationSlot`.
2. Add validation in `from_dict()`: if loaded slot count does not match `GameConfig.MUTATION_SLOTS[rarity]`, truncate or pad with empty slots to match.
3. Log a warning when slot count correction occurs.

### ISSUE-005: `get_remaining_time()` Returns Negative Value

**Symptoms:** `get_remaining_time()` returns a negative number for a seed in BLOOM phase or a seed with `growth_progress > 1.0`.

**Possible Causes:**
1. BLOOM phase has no duration — the method tries to compute remaining time for a terminal phase.
2. `growth_progress` exceeded 1.0 due to a floating-point rounding issue before clamping.

**Solutions:**
1. `get_remaining_time()` should return `0.0` immediately when `phase == BLOOM`.
2. Clamp `growth_progress` to [0.0, 1.0] in `advance_growth()` and in `from_dict()`.
3. Use `maxf(0.0, computed_remaining)` as a final safety clamp.

### ISSUE-006: `create_seed()` Crashes with "Invalid get index" on GameConfig

**Symptoms:** `SeedData.create_seed(Enums.SeedRarity.RARE, Enums.Element.FROST)` throws "Invalid get index 'RARE' (on base: 'Dictionary')" or similar.

**Possible Causes:**
1. TASK-003 is not merged — `GameConfig.BASE_GROWTH_SECONDS` does not exist.
2. `GameConfig.BASE_GROWTH_SECONDS` uses different keys than expected (e.g., string keys instead of enum keys).
3. The enum value integer does not match the dictionary key (e.g., `RARE = 2` in enum but the dict uses `2` as a key, and you're passing the enum directly — this should work in Godot 4.x).

**Solutions:**
1. Ensure TASK-003 is merged and `GameConfig` is loadable.
2. Verify `GameConfig.BASE_GROWTH_SECONDS` keys match `Enums.SeedRarity` enum values. In TASK-003, keys are `Enums.SeedRarity.COMMON` etc.
3. Test with `print(GameConfig.BASE_GROWTH_SECONDS.has(Enums.SeedRarity.RARE))` to confirm key presence.

---

## Section 13 · Acceptance Criteria

### Structural Acceptance Criteria (SACs)

| ID | Criterion | Verification |
|---|---|---|
| AC-001 | File `src/models/seed_data.gd` exists and declares `class_name SeedData`. | File inspection |
| AC-002 | File `src/models/mutation_slot.gd` exists and declares `class_name MutationSlot`. | File inspection |
| AC-003 | `SeedData` extends `RefCounted` (explicitly or implicitly). | File inspection |
| AC-004 | `MutationSlot` extends `RefCounted` (explicitly or implicitly). | File inspection |
| AC-005 | File `tests/unit/test_seed_data.gd` exists and extends `GutTest`. | File inspection |
| AC-006 | All public methods in `SeedData` have GDScript type hints on parameters and return values. | File inspection |
| AC-007 | All public methods in `SeedData` have `##` doc comments. | File inspection |
| AC-008 | All public methods in `MutationSlot` have GDScript type hints on parameters and return values. | File inspection |
| AC-009 | No `Node`, `SceneTree`, `Timer`, or signal declarations exist in `seed_data.gd` or `mutation_slot.gd`. | File inspection / grep |

### Property Acceptance Criteria (PACs)

| ID | Criterion | Verification |
|---|---|---|
| AC-010 | `SeedData.id` is a `String` property. | Unit test |
| AC-011 | `SeedData.rarity` is an `Enums.SeedRarity` property. | Unit test |
| AC-012 | `SeedData.element` is an `Enums.Element` property. | Unit test |
| AC-013 | `SeedData.phase` is an `Enums.SeedPhase` property, defaults to `SPORE`. | Unit test |
| AC-014 | `SeedData.growth_progress` is a `float`, defaults to `0.0`. | Unit test |
| AC-015 | `SeedData.growth_rate` is a `float`, set from `GameConfig.BASE_GROWTH_SECONDS[rarity]`. | Unit test |
| AC-016 | `SeedData.mutation_slots` is an `Array[MutationSlot]` with length matching `GameConfig.MUTATION_SLOTS[rarity]`. | Unit test |
| AC-017 | `SeedData.mutation_potential` is a `float` in [0.0, 1.0]. | Unit test |
| AC-018 | `SeedData.dungeon_traits` is a `Dictionary` with keys `"room_variety"`, `"hazard_frequency"`, `"loot_bias"`. | Unit test |
| AC-019 | `SeedData.planted_at` is a `float`, defaults to `0.0`. | Unit test |
| AC-020 | `SeedData.is_planted` is a `bool`, defaults to `false`. | Unit test |
| AC-021 | `MutationSlot.slot_index` is an `int`. | Unit test |
| AC-022 | `MutationSlot.reagent_id` is a `String`, defaults to `""`. | Unit test |
| AC-023 | `MutationSlot.effect` is a `Dictionary`, defaults to `{}`. | Unit test |

### Behavioral Acceptance Criteria (BACs) — State Machine

| ID | Criterion | Verification |
|---|---|---|
| AC-024 | `advance_growth(delta)` on an unplanted seed returns current phase without modifying any state. | Unit test |
| AC-025 | `advance_growth(delta)` on a BLOOM seed returns BLOOM without modifying any state. | Unit test |
| AC-026 | A Common SPORE seed transitions to SPROUT after exactly 60.0 seconds of cumulative delta (60s base × 1.0 multiplier). | Unit test |
| AC-027 | A Common SPROUT seed transitions to BUD after exactly 72.0 seconds of cumulative delta (60s base × 1.2 multiplier). | Unit test |
| AC-028 | A Common BUD seed transitions to BLOOM after exactly 90.0 seconds of cumulative delta (60s base × 1.5 multiplier). | Unit test |
| AC-029 | BLOOM is terminal: repeated calls to `advance_growth()` on a BLOOM seed do not change phase or progress. | Unit test |
| AC-030 | Phase transitions reset `growth_progress` to `0.0`. | Unit test |
| AC-031 | `advance_growth()` advances at most one phase per invocation, even with delta exceeding phase duration. | Unit test |
| AC-032 | `advance_growth()` with negative delta returns current phase without modifying state. | Unit test |
| AC-033 | `advance_growth()` with delta of 0.0 returns current phase without modifying state. | Unit test |
| AC-034 | After many small delta calls summing to exactly one phase duration, the seed transitions exactly once. | Unit test |
| AC-035 | A Legendary seed requires 1200.0 seconds base per phase (SPORE=1200, SPROUT=1440, BUD=1800). | Unit test |

### Behavioral Acceptance Criteria (BACs) — Factory & Planting

| ID | Criterion | Verification |
|---|---|---|
| AC-036 | `create_seed(COMMON, TERRA)` produces a seed with `rarity=COMMON`, `element=TERRA`, `phase=SPORE`, `growth_progress=0.0`, `is_planted=false`. | Unit test |
| AC-037 | `create_seed(LEGENDARY, SHADOW)` produces a seed with 5 mutation slots and `growth_rate=1200.0`. | Unit test |
| AC-038 | Two calls to `create_seed()` with no custom_id produce seeds with different `id` values. | Unit test |
| AC-039 | `create_seed()` with a `custom_id` parameter uses that ID instead of generating one. | Unit test |
| AC-040 | `plant(timestamp)` sets `is_planted=true` and `planted_at=timestamp`. | Unit test |
| AC-041 | `plant()` on an already-planted seed is a no-op — `planted_at` does not change. | Unit test |
| AC-042 | `plant(0.0)` is a no-op — invalid timestamp rejected. | Unit test |
| AC-043 | `plant(-5.0)` is a no-op — negative timestamp rejected. | Unit test |

### Behavioral Acceptance Criteria (BACs) — Serialization

| ID | Criterion | Verification |
|---|---|---|
| AC-044 | `to_dict()` returns a Dictionary containing all SeedData fields. | Unit test |
| AC-045 | `to_dict()` serializes enums as integers. | Unit test |
| AC-046 | `to_dict()` serializes `mutation_slots` as an Array of Dictionaries. | Unit test |
| AC-047 | `from_dict(to_dict())` produces a SeedData with identical `id`, `rarity`, `element`, `phase`, `growth_progress`, `growth_rate`, `mutation_potential`, `planted_at`, `is_planted`. | Unit test |
| AC-048 | `from_dict(to_dict())` produces identical `dungeon_traits` (same keys and values). | Unit test |
| AC-049 | `from_dict(to_dict())` produces identical `mutation_slots` (same count, same reagent_ids, same effects). | Unit test |
| AC-050 | `from_dict()` with missing optional keys uses default values without crashing. | Unit test |
| AC-051 | `from_dict()` with invalid `phase` integer (e.g., 99) clamps to a valid SeedPhase. | Unit test |
| AC-052 | `from_dict()` with excess mutation slots truncates to `GameConfig.MUTATION_SLOTS[rarity]`. | Unit test |

### Behavioral Acceptance Criteria (BACs) — Helpers

| ID | Criterion | Verification |
|---|---|---|
| AC-053 | `get_phase_duration()` returns `growth_rate * PHASE_GROWTH_MULTIPLIERS[phase]` for non-BLOOM phases. | Unit test |
| AC-054 | `get_phase_duration()` returns `0.0` for BLOOM phase. | Unit test |
| AC-055 | `get_total_growth_time()` returns the sum of phase durations for SPORE + SPROUT + BUD. | Unit test |
| AC-056 | `get_total_growth_time()` for a Common seed returns `60*(1.0+1.2+1.5) = 222.0`. | Unit test |
| AC-057 | `get_remaining_time()` for a freshly planted SPORE seed equals `get_total_growth_time()`. | Unit test |
| AC-058 | `get_remaining_time()` for a BLOOM seed returns `0.0`. | Unit test |
| AC-059 | `get_overall_progress()` returns `0.0` for a freshly planted SPORE seed. | Unit test |
| AC-060 | `get_overall_progress()` returns `1.0` for a BLOOM seed. | Unit test |
| AC-061 | `get_overall_progress()` returns approximately `0.5` for a seed halfway through its total growth. | Unit test |
| AC-062 | `get_filled_slot_count()` returns `0` for a seed with no reagents applied. | Unit test |
| AC-063 | `get_filled_slot_count()` returns correct count after filling some slots. | Unit test |
| AC-064 | `get_slot(0)` returns the first mutation slot. | Unit test |
| AC-065 | `get_slot(-1)` returns `null`. | Unit test |
| AC-066 | `get_slot(999)` returns `null`. | Unit test |

### MutationSlot Acceptance Criteria

| ID | Criterion | Verification |
|---|---|---|
| AC-067 | `MutationSlot.is_empty()` returns `true` when `reagent_id == ""`. | Unit test |
| AC-068 | `MutationSlot.is_empty()` returns `false` when `reagent_id == "fire_reagent"`. | Unit test |
| AC-069 | `MutationSlot.to_dict()` produces `{ "slot_index": N, "reagent_id": "...", "effect": {...} }`. | Unit test |
| AC-070 | `MutationSlot.from_dict(slot.to_dict())` round-trips all fields. | Unit test |

---

## Section 14 · Testing Requirements

### Complete GUT Test Suite: `tests/unit/test_seed_data.gd`

```gdscript
extends GutTest
## Unit tests for SeedData and MutationSlot models.
## Covers: properties, state machine, factory, planting, serialization, helpers.

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _create_common_terra() -> SeedData:
	return SeedData.create_seed(Enums.SeedRarity.COMMON, Enums.Element.TERRA, "test_common_terra")

func _create_legendary_shadow() -> SeedData:
	return SeedData.create_seed(Enums.SeedRarity.LEGENDARY, Enums.Element.SHADOW, "test_legendary_shadow")

func _plant_seed(seed: SeedData, timestamp: float = 1000.0) -> void:
	seed.plant(timestamp)

func _advance_to_phase(seed: SeedData, target_phase: Enums.SeedPhase) -> void:
	while seed.phase < target_phase and seed.phase != Enums.SeedPhase.BLOOM:
		var duration: float = seed.get_phase_duration()
		seed.advance_growth(duration)

# ---------------------------------------------------------------------------
# MutationSlot Tests
# ---------------------------------------------------------------------------

func test_mutation_slot_defaults() -> void:
	var slot := MutationSlot.new()
	slot.slot_index = 0
	assert_eq(slot.slot_index, 0, "slot_index should be 0")
	assert_eq(slot.reagent_id, "", "reagent_id should default to empty string")
	assert_eq(slot.effect, {}, "effect should default to empty dict")

func test_mutation_slot_is_empty_true() -> void:
	var slot := MutationSlot.new()
	slot.slot_index = 0
	assert_true(slot.is_empty(), "Slot with no reagent should be empty")

func test_mutation_slot_is_empty_false() -> void:
	var slot := MutationSlot.new()
	slot.slot_index = 0
	slot.reagent_id = "fire_reagent"
	slot.effect = { "hazard_frequency": 0.1 }
	assert_false(slot.is_empty(), "Slot with reagent should not be empty")

func test_mutation_slot_to_dict() -> void:
	var slot := MutationSlot.new()
	slot.slot_index = 2
	slot.reagent_id = "chaos_reagent"
	slot.effect = { "room_variety": 0.15 }
	var d: Dictionary = slot.to_dict()
	assert_eq(d["slot_index"], 2)
	assert_eq(d["reagent_id"], "chaos_reagent")
	assert_eq(d["effect"]["room_variety"], 0.15)

func test_mutation_slot_from_dict() -> void:
	var d := { "slot_index": 3, "reagent_id": "ice_reagent", "effect": { "hazard_frequency": -0.05 } }
	var slot: MutationSlot = MutationSlot.from_dict(d)
	assert_eq(slot.slot_index, 3)
	assert_eq(slot.reagent_id, "ice_reagent")
	assert_eq(slot.effect["hazard_frequency"], -0.05)

func test_mutation_slot_round_trip() -> void:
	var slot := MutationSlot.new()
	slot.slot_index = 1
	slot.reagent_id = "shadow_reagent"
	slot.effect = { "loot_bias_weight": 0.2 }
	var restored: MutationSlot = MutationSlot.from_dict(slot.to_dict())
	assert_eq(restored.slot_index, slot.slot_index)
	assert_eq(restored.reagent_id, slot.reagent_id)
	assert_eq(restored.effect, slot.effect)

# ---------------------------------------------------------------------------
# SeedData Property Tests
# ---------------------------------------------------------------------------

func test_create_seed_common_terra_properties() -> void:
	var seed: SeedData = _create_common_terra()
	assert_eq(seed.id, "test_common_terra", "ID should match custom_id")
	assert_eq(seed.rarity, Enums.SeedRarity.COMMON, "Rarity should be COMMON")
	assert_eq(seed.element, Enums.Element.TERRA, "Element should be TERRA")
	assert_eq(seed.phase, Enums.SeedPhase.SPORE, "Phase should start at SPORE")
	assert_almost_eq(seed.growth_progress, 0.0, 0.001, "Growth progress should be 0.0")
	assert_eq(seed.is_planted, false, "Seed should not be planted")
	assert_almost_eq(seed.planted_at, 0.0, 0.001, "planted_at should be 0.0")

func test_create_seed_common_growth_rate() -> void:
	var seed: SeedData = _create_common_terra()
	var expected: float = float(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.COMMON])
	assert_almost_eq(seed.growth_rate, expected, 0.001, "Growth rate should match GameConfig")

func test_create_seed_legendary_growth_rate() -> void:
	var seed: SeedData = _create_legendary_shadow()
	var expected: float = float(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.LEGENDARY])
	assert_almost_eq(seed.growth_rate, expected, 0.001, "Legendary growth rate should be 1200.0")

func test_create_seed_common_mutation_slots_count() -> void:
	var seed: SeedData = _create_common_terra()
	var expected_count: int = GameConfig.MUTATION_SLOTS[Enums.SeedRarity.COMMON]
	assert_eq(seed.mutation_slots.size(), expected_count, "Common seed should have 1 mutation slot")

func test_create_seed_legendary_mutation_slots_count() -> void:
	var seed: SeedData = _create_legendary_shadow()
	var expected_count: int = GameConfig.MUTATION_SLOTS[Enums.SeedRarity.LEGENDARY]
	assert_eq(seed.mutation_slots.size(), expected_count, "Legendary seed should have 5 mutation slots")

func test_create_seed_mutation_slots_sequential_indices() -> void:
	var seed: SeedData = _create_legendary_shadow()
	for i in range(seed.mutation_slots.size()):
		assert_eq(seed.mutation_slots[i].slot_index, i, "Slot index should be sequential")

func test_create_seed_mutation_slots_initially_empty() -> void:
	var seed: SeedData = _create_legendary_shadow()
	for slot in seed.mutation_slots:
		assert_true(slot.is_empty(), "All slots should be empty at creation")

func test_create_seed_mutation_potential_by_rarity() -> void:
	var expected_potentials: Dictionary = {
		Enums.SeedRarity.COMMON: 0.1,
		Enums.SeedRarity.UNCOMMON: 0.2,
		Enums.SeedRarity.RARE: 0.4,
		Enums.SeedRarity.EPIC: 0.6,
		Enums.SeedRarity.LEGENDARY: 0.8,
	}
	for rarity_val in expected_potentials:
		var seed: SeedData = SeedData.create_seed(rarity_val, Enums.Element.TERRA, "test_mp_%d" % rarity_val)
		assert_almost_eq(seed.mutation_potential, expected_potentials[rarity_val], 0.001,
			"Mutation potential should match rarity for rarity=%d" % rarity_val)

func test_create_seed_dungeon_traits_keys() -> void:
	var seed: SeedData = _create_common_terra()
	assert_true(seed.dungeon_traits.has("room_variety"), "Should have room_variety")
	assert_true(seed.dungeon_traits.has("hazard_frequency"), "Should have hazard_frequency")
	assert_true(seed.dungeon_traits.has("loot_bias"), "Should have loot_bias")

func test_create_seed_dungeon_traits_scale_with_rarity() -> void:
	var common: SeedData = SeedData.create_seed(Enums.SeedRarity.COMMON, Enums.Element.TERRA, "dt_c")
	var legendary: SeedData = SeedData.create_seed(Enums.SeedRarity.LEGENDARY, Enums.Element.TERRA, "dt_l")
	assert_gt(legendary.dungeon_traits["room_variety"], common.dungeon_traits["room_variety"],
		"Legendary should have higher room_variety than Common")
	assert_gt(legendary.dungeon_traits["hazard_frequency"], common.dungeon_traits["hazard_frequency"],
		"Legendary should have higher hazard_frequency than Common")

func test_create_seed_unique_ids() -> void:
	var seed1: SeedData = SeedData.create_seed(Enums.SeedRarity.COMMON, Enums.Element.TERRA)
	var seed2: SeedData = SeedData.create_seed(Enums.SeedRarity.COMMON, Enums.Element.TERRA)
	assert_ne(seed1.id, seed2.id, "Auto-generated IDs should be unique")

func test_create_seed_custom_id() -> void:
	var seed: SeedData = SeedData.create_seed(Enums.SeedRarity.RARE, Enums.Element.FROST, "my_custom_id")
	assert_eq(seed.id, "my_custom_id", "Custom ID should be used when provided")

# ---------------------------------------------------------------------------
# Planting Tests
# ---------------------------------------------------------------------------

func test_plant_sets_planted_state() -> void:
	var seed: SeedData = _create_common_terra()
	seed.plant(1000.0)
	assert_true(seed.is_planted, "Seed should be planted")
	assert_almost_eq(seed.planted_at, 1000.0, 0.001, "planted_at should be 1000.0")

func test_plant_already_planted_is_noop() -> void:
	var seed: SeedData = _create_common_terra()
	seed.plant(1000.0)
	seed.plant(2000.0)
	assert_almost_eq(seed.planted_at, 1000.0, 0.001, "planted_at should not change on re-plant")

func test_plant_zero_timestamp_is_noop() -> void:
	var seed: SeedData = _create_common_terra()
	seed.plant(0.0)
	assert_false(seed.is_planted, "Seed should not be planted with timestamp 0.0")

func test_plant_negative_timestamp_is_noop() -> void:
	var seed: SeedData = _create_common_terra()
	seed.plant(-5.0)
	assert_false(seed.is_planted, "Seed should not be planted with negative timestamp")

# ---------------------------------------------------------------------------
# State Machine Tests
# ---------------------------------------------------------------------------

func test_advance_growth_unplanted_noop() -> void:
	var seed: SeedData = _create_common_terra()
	var result: Enums.SeedPhase = seed.advance_growth(1000.0)
	assert_eq(result, Enums.SeedPhase.SPORE, "Unplanted seed should stay SPORE")
	assert_almost_eq(seed.growth_progress, 0.0, 0.001, "Progress should not change")

func test_advance_growth_bloom_noop() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	_advance_to_phase(seed, Enums.SeedPhase.BLOOM)
	assert_eq(seed.phase, Enums.SeedPhase.BLOOM, "Precondition: seed is BLOOM")
	var progress_before: float = seed.growth_progress
	var result: Enums.SeedPhase = seed.advance_growth(9999.0)
	assert_eq(result, Enums.SeedPhase.BLOOM, "BLOOM seed should stay BLOOM")
	assert_almost_eq(seed.growth_progress, progress_before, 0.001, "Progress should not change in BLOOM")

func test_advance_growth_negative_delta_noop() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	var result: Enums.SeedPhase = seed.advance_growth(-10.0)
	assert_eq(result, Enums.SeedPhase.SPORE, "Negative delta should not change phase")
	assert_almost_eq(seed.growth_progress, 0.0, 0.001, "Progress should not change")

func test_advance_growth_zero_delta_noop() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	var result: Enums.SeedPhase = seed.advance_growth(0.0)
	assert_eq(result, Enums.SeedPhase.SPORE, "Zero delta should not change phase")
	assert_almost_eq(seed.growth_progress, 0.0, 0.001, "Progress should not change")

func test_spore_to_sprout_transition_common() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	var spore_duration: float = 60.0 * GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.SPORE]
	var result: Enums.SeedPhase = seed.advance_growth(spore_duration)
	assert_eq(result, Enums.SeedPhase.SPROUT, "Should transition to SPROUT after full SPORE duration")
	assert_almost_eq(seed.growth_progress, 0.0, 0.001, "Progress should reset to 0.0")

func test_sprout_to_bud_transition_common() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	_advance_to_phase(seed, Enums.SeedPhase.SPROUT)
	var sprout_duration: float = 60.0 * GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.SPROUT]
	var result: Enums.SeedPhase = seed.advance_growth(sprout_duration)
	assert_eq(result, Enums.SeedPhase.BUD, "Should transition to BUD after full SPROUT duration")

func test_bud_to_bloom_transition_common() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	_advance_to_phase(seed, Enums.SeedPhase.BUD)
	var bud_duration: float = 60.0 * GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.BUD]
	var result: Enums.SeedPhase = seed.advance_growth(bud_duration)
	assert_eq(result, Enums.SeedPhase.BLOOM, "Should transition to BLOOM after full BUD duration")

func test_full_lifecycle_common() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	assert_eq(seed.phase, Enums.SeedPhase.SPORE)
	_advance_to_phase(seed, Enums.SeedPhase.BLOOM)
	assert_eq(seed.phase, Enums.SeedPhase.BLOOM, "Seed should reach BLOOM after full lifecycle")

func test_advance_growth_at_most_one_phase_per_call() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	var result: Enums.SeedPhase = seed.advance_growth(99999.0)
	assert_eq(result, Enums.SeedPhase.SPROUT, "Should only advance one phase even with huge delta")
	assert_eq(seed.phase, Enums.SeedPhase.SPROUT)

func test_growth_progress_increments_correctly() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	var phase_dur: float = seed.get_phase_duration()
	seed.advance_growth(phase_dur * 0.5)
	assert_almost_eq(seed.growth_progress, 0.5, 0.01, "Progress should be ~50% after half duration")

func test_growth_progress_resets_on_transition() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	var phase_dur: float = seed.get_phase_duration()
	seed.advance_growth(phase_dur)
	assert_eq(seed.phase, Enums.SeedPhase.SPROUT)
	assert_almost_eq(seed.growth_progress, 0.0, 0.001, "Progress should reset on transition")

func test_many_small_deltas_sum_to_transition() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	var phase_dur: float = seed.get_phase_duration()
	var small_delta: float = phase_dur / 100.0
	for i in range(100):
		seed.advance_growth(small_delta)
	assert_eq(seed.phase, Enums.SeedPhase.SPROUT, "100 small deltas summing to phase duration should trigger transition")

func test_legendary_spore_duration() -> void:
	var seed: SeedData = _create_legendary_shadow()
	_plant_seed(seed)
	var expected_dur: float = 1200.0 * GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.SPORE]
	assert_almost_eq(seed.get_phase_duration(), expected_dur, 0.001)
	seed.advance_growth(expected_dur - 1.0)
	assert_eq(seed.phase, Enums.SeedPhase.SPORE, "Should still be SPORE 1s before transition")
	seed.advance_growth(1.0)
	assert_eq(seed.phase, Enums.SeedPhase.SPROUT, "Should transition to SPROUT at exact duration")

func test_bloom_is_truly_terminal() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	_advance_to_phase(seed, Enums.SeedPhase.BLOOM)
	for i in range(100):
		seed.advance_growth(1000.0)
	assert_eq(seed.phase, Enums.SeedPhase.BLOOM, "BLOOM should remain after 100 calls")
	assert_almost_eq(seed.growth_progress, 0.0, 0.001, "Progress should stay 0.0 in BLOOM")

func test_all_rarities_phase_durations() -> void:
	var rarities: Array = [
		Enums.SeedRarity.COMMON,
		Enums.SeedRarity.UNCOMMON,
		Enums.SeedRarity.RARE,
		Enums.SeedRarity.EPIC,
		Enums.SeedRarity.LEGENDARY,
	]
	for rarity_val in rarities:
		var seed: SeedData = SeedData.create_seed(rarity_val, Enums.Element.TERRA, "dur_test_%d" % rarity_val)
		_plant_seed(seed)
		var base: float = float(GameConfig.BASE_GROWTH_SECONDS[rarity_val])
		var spore_mult: float = GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.SPORE]
		var expected: float = base * spore_mult
		assert_almost_eq(seed.get_phase_duration(), expected, 0.001,
			"Phase duration should match base*mult for rarity=%d" % rarity_val)

# ---------------------------------------------------------------------------
# Serialization Tests
# ---------------------------------------------------------------------------

func test_to_dict_contains_all_keys() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	var d: Dictionary = seed.to_dict()
	var required_keys: Array[String] = [
		"id", "rarity", "element", "phase", "growth_progress", "growth_rate",
		"mutation_slots", "mutation_potential", "dungeon_traits", "planted_at", "is_planted"
	]
	for key in required_keys:
		assert_true(d.has(key), "to_dict() should contain key: %s" % key)

func test_to_dict_enum_as_int() -> void:
	var seed: SeedData = SeedData.create_seed(Enums.SeedRarity.RARE, Enums.Element.FROST, "enum_test")
	var d: Dictionary = seed.to_dict()
	assert_eq(d["rarity"], int(Enums.SeedRarity.RARE), "Rarity should serialize as int")
	assert_eq(d["element"], int(Enums.Element.FROST), "Element should serialize as int")
	assert_eq(d["phase"], int(Enums.SeedPhase.SPORE), "Phase should serialize as int")

func test_to_dict_mutation_slots_as_array() -> void:
	var seed: SeedData = _create_legendary_shadow()
	var d: Dictionary = seed.to_dict()
	assert_true(d["mutation_slots"] is Array, "mutation_slots should be an Array")
	assert_eq(d["mutation_slots"].size(), 5, "Legendary should have 5 serialized slots")

func test_from_dict_round_trip_basic() -> void:
	var original: SeedData = _create_common_terra()
	_plant_seed(original)
	original.advance_growth(30.0)
	var restored: SeedData = SeedData.from_dict(original.to_dict())
	assert_eq(restored.id, original.id)
	assert_eq(restored.rarity, original.rarity)
	assert_eq(restored.element, original.element)
	assert_eq(restored.phase, original.phase)
	assert_almost_eq(restored.growth_progress, original.growth_progress, 0.001)
	assert_almost_eq(restored.growth_rate, original.growth_rate, 0.001)
	assert_almost_eq(restored.mutation_potential, original.mutation_potential, 0.001)
	assert_almost_eq(restored.planted_at, original.planted_at, 0.001)
	assert_eq(restored.is_planted, original.is_planted)

func test_from_dict_round_trip_dungeon_traits() -> void:
	var original: SeedData = _create_common_terra()
	var restored: SeedData = SeedData.from_dict(original.to_dict())
	assert_eq(restored.dungeon_traits["room_variety"], original.dungeon_traits["room_variety"])
	assert_eq(restored.dungeon_traits["hazard_frequency"], original.dungeon_traits["hazard_frequency"])
	assert_eq(restored.dungeon_traits["loot_bias"], original.dungeon_traits["loot_bias"])

func test_from_dict_round_trip_mutation_slots() -> void:
	var original: SeedData = _create_legendary_shadow()
	original.mutation_slots[0].reagent_id = "fire_reagent"
	original.mutation_slots[0].effect = { "hazard_frequency": 0.1 }
	original.mutation_slots[2].reagent_id = "ice_reagent"
	original.mutation_slots[2].effect = { "room_variety": -0.05 }
	var restored: SeedData = SeedData.from_dict(original.to_dict())
	assert_eq(restored.mutation_slots.size(), original.mutation_slots.size())
	assert_eq(restored.mutation_slots[0].reagent_id, "fire_reagent")
	assert_eq(restored.mutation_slots[0].effect["hazard_frequency"], 0.1)
	assert_eq(restored.mutation_slots[2].reagent_id, "ice_reagent")
	assert_true(restored.mutation_slots[1].is_empty())

func test_from_dict_round_trip_mid_growth() -> void:
	var original: SeedData = _create_common_terra()
	_plant_seed(original)
	original.advance_growth(30.0)
	original.advance_growth(30.0)
	original.advance_growth(36.0)
	var restored: SeedData = SeedData.from_dict(original.to_dict())
	assert_eq(restored.phase, original.phase)
	assert_almost_eq(restored.growth_progress, original.growth_progress, 0.001)

func test_from_dict_missing_optional_keys() -> void:
	var minimal: Dictionary = {
		"id": "minimal_seed",
		"rarity": int(Enums.SeedRarity.COMMON),
		"element": int(Enums.Element.TERRA),
	}
	var seed: SeedData = SeedData.from_dict(minimal)
	assert_eq(seed.id, "minimal_seed")
	assert_eq(seed.rarity, Enums.SeedRarity.COMMON)
	assert_eq(seed.phase, Enums.SeedPhase.SPORE, "Missing phase should default to SPORE")
	assert_almost_eq(seed.growth_progress, 0.0, 0.001, "Missing progress should default to 0.0")

func test_from_dict_invalid_phase_clamps() -> void:
	var d: Dictionary = {
		"id": "invalid_phase_seed",
		"rarity": int(Enums.SeedRarity.COMMON),
		"element": int(Enums.Element.TERRA),
		"phase": 99,
	}
	var seed: SeedData = SeedData.from_dict(d)
	assert_true(seed.phase >= Enums.SeedPhase.SPORE and seed.phase <= Enums.SeedPhase.BLOOM,
		"Invalid phase should be clamped to valid range")

func test_from_dict_excess_mutation_slots_truncated() -> void:
	var d: Dictionary = _create_common_terra().to_dict()
	d["mutation_slots"] = []
	for i in range(10):
		d["mutation_slots"].append({ "slot_index": i, "reagent_id": "", "effect": {} })
	var seed: SeedData = SeedData.from_dict(d)
	var max_slots: int = GameConfig.MUTATION_SLOTS[Enums.SeedRarity.COMMON]
	assert_eq(seed.mutation_slots.size(), max_slots,
		"Excess mutation slots should be truncated to rarity limit")

# ---------------------------------------------------------------------------
# Helper Method Tests
# ---------------------------------------------------------------------------

func test_get_phase_duration_spore_common() -> void:
	var seed: SeedData = _create_common_terra()
	var expected: float = 60.0 * GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.SPORE]
	assert_almost_eq(seed.get_phase_duration(), expected, 0.001)

func test_get_phase_duration_bloom_returns_zero() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	_advance_to_phase(seed, Enums.SeedPhase.BLOOM)
	assert_almost_eq(seed.get_phase_duration(), 0.0, 0.001, "BLOOM phase duration should be 0.0")

func test_get_total_growth_time_common() -> void:
	var seed: SeedData = _create_common_terra()
	var mult_spore: float = GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.SPORE]
	var mult_sprout: float = GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.SPROUT]
	var mult_bud: float = GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.BUD]
	var expected: float = 60.0 * (mult_spore + mult_sprout + mult_bud)
	assert_almost_eq(seed.get_total_growth_time(), expected, 0.01,
		"Total growth time for Common should be 60*(1.0+1.2+1.5)=222.0")

func test_get_remaining_time_fresh_spore() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	assert_almost_eq(seed.get_remaining_time(), seed.get_total_growth_time(), 0.01,
		"Fresh SPORE seed remaining time should equal total growth time")

func test_get_remaining_time_bloom() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	_advance_to_phase(seed, Enums.SeedPhase.BLOOM)
	assert_almost_eq(seed.get_remaining_time(), 0.0, 0.001, "BLOOM seed remaining time should be 0.0")

func test_get_remaining_time_mid_growth() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	seed.advance_growth(30.0)
	var remaining: float = seed.get_remaining_time()
	assert_gt(remaining, 0.0, "Remaining time should be positive mid-growth")
	assert_lt(remaining, seed.get_total_growth_time(), "Remaining time should be less than total")

func test_get_overall_progress_fresh_spore() -> void:
	var seed: SeedData = _create_common_terra()
	assert_almost_eq(seed.get_overall_progress(), 0.0, 0.001, "Fresh seed overall progress should be 0.0")

func test_get_overall_progress_bloom() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	_advance_to_phase(seed, Enums.SeedPhase.BLOOM)
	assert_almost_eq(seed.get_overall_progress(), 1.0, 0.001, "BLOOM seed overall progress should be 1.0")

func test_get_overall_progress_midpoint() -> void:
	var seed: SeedData = _create_common_terra()
	_plant_seed(seed)
	var total: float = seed.get_total_growth_time()
	var half_time: float = total / 2.0
	var elapsed: float = 0.0
	while elapsed < half_time and seed.phase != Enums.SeedPhase.BLOOM:
		var step: float = minf(seed.get_phase_duration() * (1.0 - seed.growth_progress), half_time - elapsed)
		if step <= 0.0:
			break
		seed.advance_growth(step)
		elapsed += step
	var progress: float = seed.get_overall_progress()
	assert_almost_eq(progress, 0.5, 0.05, "Overall progress should be ~0.5 at halfway point")

func test_get_filled_slot_count_none_filled() -> void:
	var seed: SeedData = _create_legendary_shadow()
	assert_eq(seed.get_filled_slot_count(), 0, "No filled slots initially")

func test_get_filled_slot_count_some_filled() -> void:
	var seed: SeedData = _create_legendary_shadow()
	seed.mutation_slots[0].reagent_id = "fire_reagent"
	seed.mutation_slots[3].reagent_id = "ice_reagent"
	assert_eq(seed.get_filled_slot_count(), 2, "Two filled slots")

func test_get_slot_valid_index() -> void:
	var seed: SeedData = _create_common_terra()
	var slot: MutationSlot = seed.get_slot(0)
	assert_not_null(slot, "get_slot(0) should return a valid slot")
	assert_eq(slot.slot_index, 0)

func test_get_slot_negative_index_returns_null() -> void:
	var seed: SeedData = _create_common_terra()
	var slot: MutationSlot = seed.get_slot(-1)
	assert_null(slot, "get_slot(-1) should return null")

func test_get_slot_out_of_bounds_returns_null() -> void:
	var seed: SeedData = _create_common_terra()
	var slot: MutationSlot = seed.get_slot(999)
	assert_null(slot, "get_slot(999) should return null")

func test_generate_id_returns_nonempty_string() -> void:
	var id: String = SeedData.generate_id()
	assert_gt(id.length(), 0, "Generated ID should be non-empty")

func test_generate_id_unique() -> void:
	var ids: Array[String] = []
	for i in range(100):
		ids.append(SeedData.generate_id())
	var unique_set: Dictionary = {}
	for id in ids:
		unique_set[id] = true
	assert_eq(unique_set.size(), 100, "100 generated IDs should all be unique")
```

---

## Section 15 · Playtesting Verification

### PV-001: Common Seed Full Lifecycle Timing

**Setup:** Create a Common Terra seed. Plant it. Run a timer.
**Action:** Let the growth tick in real-time (or accelerated via debug). Observe phase transitions.
**Expected:** SPORE→SPROUT at ~60s, SPROUT→BUD at ~132s cumulative, BUD→BLOOM at ~222s cumulative (with default multipliers 1.0/1.2/1.5).
**Metric:** Phase transitions occur within ±1 second of expected times.
**Feel Check:** Common seeds should feel fast and rewarding — tutorial-appropriate pacing.

### PV-002: Legendary Seed Patience Test

**Setup:** Create a Legendary Shadow seed. Plant it without boosters.
**Action:** Observe growth over an extended session.
**Expected:** Total growth time ~4440 seconds (~74 minutes). SPORE lasts 1200s, SPROUT 1440s, BUD 1800s.
**Metric:** Verify each phase transition occurs at the expected time.
**Feel Check:** Legendary seeds should feel like a significant investment. Players should feel compelled to use boosters or check back later — not frustrated, but anticipatory.

### PV-003: Offline Progress Catch-Up

**Setup:** Plant a Rare Frost seed. Advance to 40% through SPROUT phase. Simulate closing the game.
**Action:** Simulate 2 hours of offline time. Feed 7200 seconds into the offline progress loop.
**Expected:** Seed advances through SPROUT → BUD → BLOOM (since 7200s far exceeds total remaining growth time for Rare). Player sees "Your seed bloomed while you were away!"
**Metric:** Final state is BLOOM. No intermediate phases were skipped (each was processed in the loop).
**Feel Check:** Players should feel rewarded for returning, not punished for leaving.

### PV-004: Mutation Slot Application (Legendary)

**Setup:** Create a Legendary Shadow seed with 5 empty slots.
**Action:** Fill slots 0, 2, and 4 with different reagents. Leave slots 1 and 3 empty.
**Expected:** `get_filled_slot_count()` returns 3. Filled slots have correct reagent_ids. Empty slots return `is_empty() == true`.
**Metric:** Slot operations are correct. No index errors. UI can read slot state accurately.
**Feel Check:** Players should feel agency — choosing which slots to fill and which to leave empty is a meaningful decision.

### PV-005: Save/Load Fidelity

**Setup:** Create a seed of each rarity. Plant all of them. Advance them to various phases. Fill some mutation slots.
**Action:** Serialize all seeds via `to_dict()`. Simulate a save/load cycle. Deserialize via `from_dict()`.
**Expected:** Every restored seed has identical properties to the original. Phase, progress, rarity, element, dungeon_traits, mutation_slots (including filled reagents) all match.
**Metric:** Zero fields differ. Automated round-trip test passes.
**Feel Check:** Players should never notice that a save/load happened. Continuity is seamless.

### PV-006: Phase Transition Signal Consumption

**Setup:** Plant a Common seed. Wire up a mock listener that counts `seed_phase_changed` emissions (simulating what Grove Manager does).
**Action:** Advance the seed through all phases by calling `advance_growth()` in a loop.
**Expected:** Exactly 3 phase transitions detected: SPORE→SPROUT, SPROUT→BUD, BUD→BLOOM. The mock listener fires exactly 3 times.
**Metric:** Signal count matches expected phase transition count.
**Feel Check:** UI animations and SFX should trigger exactly once per transition — no duplicates, no misses.

### PV-007: Rarity-Scaled Properties Comparison

**Setup:** Create one seed of each rarity (COMMON through LEGENDARY), all TERRA element.
**Action:** Compare growth_rate, mutation_slots.size(), mutation_potential, and dungeon_traits across rarities.
**Expected:** All values scale monotonically with rarity: higher rarity → longer growth, more slots, higher mutation potential, better dungeon traits.
**Metric:** Strict monotonic increase for numeric properties. No two rarities have identical values.
**Feel Check:** Finding a higher-rarity seed should always feel like an upgrade. The numbers should support the fantasy.

### PV-008: Stress Test — 100 Seeds Growing Simultaneously

**Setup:** Create 100 seeds (20 of each rarity). Plant all. Run a simulated growth loop.
**Action:** Call `advance_growth(0.016)` on all 100 seeds (simulating 60fps) for 5000 iterations (≈83 seconds of game time).
**Expected:** No errors, no crashes, no NaN values. All Common seeds reach BLOOM. Some Uncommon seeds may reach BLOOM. Higher rarities are mid-growth.
**Metric:** Total frame time for 100 `advance_growth()` calls is under 1ms. No memory leaks (RefCounted instances are freed when dereferenced).
**Feel Check:** Performance should be invisible. Players with many planted seeds should see smooth UI.

---

## Section 16 · Implementation Prompt

### Complete Implementation: `src/models/mutation_slot.gd`

```gdscript
class_name MutationSlot
extends RefCounted
## Represents a single reagent slot on a seed.
##
## Each seed has a number of mutation slots determined by its rarity.
## Slots can be filled with reagents to modify the dungeon generated
## from the seed. An empty slot has reagent_id == "" and effect == {}.

## The position of this slot in the seed's mutation_slots array.
var slot_index: int = 0

## The ID of the reagent applied to this slot. Empty string if unused.
var reagent_id: String = ""

## A dictionary of stat modifiers applied to dungeon generation when
## the seed blooms. Keys are dungeon trait names (e.g., "room_variety"),
## values are numeric modifiers (positive = increase, negative = decrease).
var effect: Dictionary = {}

## Returns true if this slot has no reagent applied.
func is_empty() -> bool:
	return reagent_id == ""

## Serializes this slot to a plain Dictionary for save/load.
func to_dict() -> Dictionary:
	return {
		"slot_index": slot_index,
		"reagent_id": reagent_id,
		"effect": effect.duplicate(),
	}

## Reconstructs a MutationSlot from a serialized Dictionary.
static func from_dict(data: Dictionary) -> MutationSlot:
	var slot := MutationSlot.new()
	slot.slot_index = data.get("slot_index", 0) as int
	slot.reagent_id = data.get("reagent_id", "") as String
	var raw_effect: Variant = data.get("effect", {})
	if raw_effect is Dictionary:
		slot.effect = (raw_effect as Dictionary).duplicate()
	else:
		slot.effect = {}
	return slot
```

### Complete Implementation: `src/models/seed_data.gd`

```gdscript
class_name SeedData
extends RefCounted
## The primary data model for a plantable seed in Dungeon Seed.
##
## Encapsulates all GDD §4.1 seed attributes: rarity, elemental affinity,
## growth phase, growth progress, growth rate, mutation slots, mutation
## potential, dungeon generation traits, and planting status.
##
## Includes a pull-based maturation state machine that advances through
## four phases: SPORE → SPROUT → BUD → BLOOM. The state machine is
## advanced externally by calling advance_growth(delta_seconds).

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const TRAIT_ROOM_VARIETY := "room_variety"
const TRAIT_HAZARD_FREQUENCY := "hazard_frequency"
const TRAIT_LOOT_BIAS := "loot_bias"

const MUTATION_POTENTIAL_BY_RARITY: Dictionary = {
	Enums.SeedRarity.COMMON: 0.1,
	Enums.SeedRarity.UNCOMMON: 0.2,
	Enums.SeedRarity.RARE: 0.4,
	Enums.SeedRarity.EPIC: 0.6,
	Enums.SeedRarity.LEGENDARY: 0.8,
}

const LOOT_BIAS_BY_RARITY: Array[String] = [
	"gold",       # COMMON (0)
	"crafting",   # UNCOMMON (1)
	"artifacts",  # RARE (2)
	"balanced",   # EPIC (3)
	"balanced",   # LEGENDARY (4)
]

# ---------------------------------------------------------------------------
# Properties
# ---------------------------------------------------------------------------

## Unique identifier for this seed instance.
var id: String = ""

## The rarity tier of this seed, determining growth time and slot count.
var rarity: Enums.SeedRarity = Enums.SeedRarity.COMMON

## The elemental affinity, determining dungeon theme and enemy types.
var element: Enums.Element = Enums.Element.TERRA

## Current maturation phase in the state machine.
var phase: Enums.SeedPhase = Enums.SeedPhase.SPORE

## Completion percentage within the current phase, range [0.0, 1.0].
var growth_progress: float = 0.0

## Base seconds per phase. Set from GameConfig at creation time.
var growth_rate: float = 60.0

## Array of mutation slots available for reagent application.
var mutation_slots: Array[MutationSlot] = []

## Probability [0.0, 1.0] that a reagent produces a beneficial mutation.
var mutation_potential: float = 0.1

## Dungeon generation parameters derived from rarity and element.
var dungeon_traits: Dictionary = {}

## Engine timestamp when this seed was planted. 0.0 if unplanted.
var planted_at: float = 0.0

## Whether this seed is currently planted in a grove plot.
var is_planted: bool = false

# ---------------------------------------------------------------------------
# Static ID Generator
# ---------------------------------------------------------------------------

## Internal counter for generating unique IDs within a session.
static var _id_counter: int = 0

## Generates a unique string identifier for a seed.
## Uses a combination of timestamp hash and an incrementing counter.
static func generate_id() -> String:
	_id_counter += 1
	var time_hash: int = Time.get_ticks_usec()
	return "seed_%s_%d" % [String.num_int64(time_hash, 16), _id_counter]

# ---------------------------------------------------------------------------
# Factory Method
# ---------------------------------------------------------------------------

## Creates a fully initialized SeedData instance with all properties
## derived from the given rarity and element.
##
## @param p_rarity: The rarity tier of the seed.
## @param p_element: The elemental affinity of the seed.
## @param custom_id: Optional custom ID. If empty, one is generated.
## @return: A new SeedData instance ready for planting.
static func create_seed(
	p_rarity: Enums.SeedRarity,
	p_element: Enums.Element,
	custom_id: String = ""
) -> SeedData:
	var seed := SeedData.new()

	# Identity
	if custom_id.is_empty():
		seed.id = generate_id()
	else:
		seed.id = custom_id

	# Core attributes
	seed.rarity = p_rarity
	seed.element = p_element

	# Growth configuration from GameConfig
	seed.growth_rate = float(GameConfig.BASE_GROWTH_SECONDS[p_rarity])

	# Mutation slots — count determined by rarity
	var slot_count: int = GameConfig.MUTATION_SLOTS[p_rarity]
	seed.mutation_slots = []
	for i in range(slot_count):
		var slot := MutationSlot.new()
		slot.slot_index = i
		seed.mutation_slots.append(slot)

	# Mutation potential — scaled by rarity
	seed.mutation_potential = MUTATION_POTENTIAL_BY_RARITY.get(p_rarity, 0.1)

	# Dungeon traits — base values scale with rarity
	var rarity_index: int = int(p_rarity)
	seed.dungeon_traits = {
		TRAIT_ROOM_VARIETY: 0.3 + (rarity_index * 0.15),
		TRAIT_HAZARD_FREQUENCY: 0.2 + (rarity_index * 0.1),
		TRAIT_LOOT_BIAS: LOOT_BIAS_BY_RARITY[mini(rarity_index, LOOT_BIAS_BY_RARITY.size() - 1)],
	}

	# Initial state
	seed.phase = Enums.SeedPhase.SPORE
	seed.growth_progress = 0.0
	seed.planted_at = 0.0
	seed.is_planted = false

	return seed

# ---------------------------------------------------------------------------
# Planting
# ---------------------------------------------------------------------------

## Plants this seed at the given timestamp.
## No-op if already planted, or if timestamp is <= 0.0.
##
## @param timestamp: The engine time when planting occurs. Must be > 0.0.
func plant(timestamp: float) -> void:
	if is_planted:
		return
	if timestamp <= 0.0:
		return
	is_planted = true
	planted_at = timestamp

# ---------------------------------------------------------------------------
# Maturation State Machine
# ---------------------------------------------------------------------------

## Advances the seed's growth by the given delta time.
##
## The state machine transitions through phases SPORE → SPROUT → BUD → BLOOM.
## Each phase has a duration of growth_rate * PHASE_GROWTH_MULTIPLIERS[phase].
## At most one phase transition occurs per call.
##
## @param delta_seconds: Elapsed time in seconds. Must be > 0.0.
## @return: The current phase after advancement.
func advance_growth(delta_seconds: float) -> Enums.SeedPhase:
	# Guard: not planted
	if not is_planted:
		return phase

	# Guard: terminal phase
	if phase == Enums.SeedPhase.BLOOM:
		return Enums.SeedPhase.BLOOM

	# Guard: invalid delta
	if delta_seconds <= 0.0:
		return phase

	# Calculate phase duration
	var phase_duration: float = _get_current_phase_duration()
	if phase_duration <= 0.0:
		return phase

	# Advance growth progress
	growth_progress += delta_seconds / phase_duration
	growth_progress = clampf(growth_progress, 0.0, 2.0)  # Allow slight overshoot for detection

	# Check for phase transition
	if growth_progress >= 1.0:
		var next: Enums.SeedPhase = _next_phase(phase)
		phase = next
		growth_progress = 0.0

	return phase

## Returns the next phase in the sequence, clamped to BLOOM.
func _next_phase(current: Enums.SeedPhase) -> Enums.SeedPhase:
	var next_val: int = int(current) + 1
	if next_val > int(Enums.SeedPhase.BLOOM):
		return Enums.SeedPhase.BLOOM
	return next_val as Enums.SeedPhase

## Returns the duration in seconds for the current phase.
func _get_current_phase_duration() -> float:
	if phase == Enums.SeedPhase.BLOOM:
		return 0.0
	return growth_rate * GameConfig.PHASE_GROWTH_MULTIPLIERS[phase]

# ---------------------------------------------------------------------------
# Helper Methods
# ---------------------------------------------------------------------------

## Returns the duration in seconds for the current phase.
## Returns 0.0 if the seed is in BLOOM (terminal phase).
func get_phase_duration() -> float:
	return _get_current_phase_duration()

## Returns the total growth time from SPORE through BUD (in seconds).
## BLOOM is terminal and has no duration.
func get_total_growth_time() -> float:
	var total: float = 0.0
	var growth_phases: Array[Enums.SeedPhase] = [
		Enums.SeedPhase.SPORE,
		Enums.SeedPhase.SPROUT,
		Enums.SeedPhase.BUD,
	]
	for p in growth_phases:
		total += growth_rate * GameConfig.PHASE_GROWTH_MULTIPLIERS[p]
	return total

## Returns the estimated seconds remaining until BLOOM.
## Based on current phase, progress, and growth rate.
## Returns 0.0 if already in BLOOM.
func get_remaining_time() -> float:
	if phase == Enums.SeedPhase.BLOOM:
		return 0.0

	# Remaining time in current phase
	var current_dur: float = _get_current_phase_duration()
	var remaining: float = current_dur * (1.0 - growth_progress)

	# Add full durations of subsequent phases (excluding BLOOM)
	var phase_val: int = int(phase) + 1
	while phase_val < int(Enums.SeedPhase.BLOOM):
		var future_phase: Enums.SeedPhase = phase_val as Enums.SeedPhase
		remaining += growth_rate * GameConfig.PHASE_GROWTH_MULTIPLIERS[future_phase]
		phase_val += 1

	return maxf(0.0, remaining)

## Returns overall maturation progress as a float in [0.0, 1.0].
## 0.0 = freshly created SPORE, 1.0 = BLOOM.
func get_overall_progress() -> float:
	if phase == Enums.SeedPhase.BLOOM:
		return 1.0

	var total: float = get_total_growth_time()
	if total <= 0.0:
		return 0.0

	# Sum completed phase durations
	var elapsed: float = 0.0
	var growth_phases: Array[Enums.SeedPhase] = [
		Enums.SeedPhase.SPORE,
		Enums.SeedPhase.SPROUT,
		Enums.SeedPhase.BUD,
	]
	for p in growth_phases:
		if int(p) < int(phase):
			elapsed += growth_rate * GameConfig.PHASE_GROWTH_MULTIPLIERS[p]
		elif p == phase:
			elapsed += _get_current_phase_duration() * growth_progress
			break

	return clampf(elapsed / total, 0.0, 1.0)

## Returns the number of mutation slots that have a reagent applied.
func get_filled_slot_count() -> int:
	var count: int = 0
	for slot in mutation_slots:
		if not slot.is_empty():
			count += 1
	return count

## Returns the MutationSlot at the given index, or null if out of bounds.
##
## @param index: The slot index to retrieve.
## @return: The MutationSlot, or null if index is invalid.
func get_slot(index: int) -> MutationSlot:
	if index < 0 or index >= mutation_slots.size():
		return null
	return mutation_slots[index]

# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

## Serializes this SeedData to a plain Dictionary suitable for JSON/save.
## Enum values are stored as integers. Mutation slots are stored as an array
## of dictionaries.
func to_dict() -> Dictionary:
	var slots_array: Array[Dictionary] = []
	for slot in mutation_slots:
		slots_array.append(slot.to_dict())

	return {
		"id": id,
		"rarity": int(rarity),
		"element": int(element),
		"phase": int(phase),
		"growth_progress": growth_progress,
		"growth_rate": growth_rate,
		"mutation_slots": slots_array,
		"mutation_potential": mutation_potential,
		"dungeon_traits": dungeon_traits.duplicate(),
		"planted_at": planted_at,
		"is_planted": is_planted,
	}

## Reconstructs a SeedData instance from a serialized Dictionary.
## Uses defensive get() with defaults for all fields to handle
## missing keys gracefully (e.g., loading saves from older versions).
##
## @param data: The serialized Dictionary.
## @return: A reconstructed SeedData instance.
static func from_dict(data: Dictionary) -> SeedData:
	var seed := SeedData.new()

	seed.id = data.get("id", "") as String

	# Restore enums from integer values with clamping
	var rarity_int: int = clampi(data.get("rarity", 0) as int, 0, int(Enums.SeedRarity.LEGENDARY))
	seed.rarity = rarity_int as Enums.SeedRarity

	var element_int: int = clampi(data.get("element", 0) as int, 0, int(Enums.Element.SHADOW))
	seed.element = element_int as Enums.Element

	var phase_int: int = clampi(data.get("phase", 0) as int, 0, int(Enums.SeedPhase.BLOOM))
	seed.phase = phase_int as Enums.SeedPhase

	seed.growth_progress = clampf(data.get("growth_progress", 0.0) as float, 0.0, 1.0)
	seed.growth_rate = maxf(data.get("growth_rate", 60.0) as float, 1.0)
	seed.mutation_potential = clampf(data.get("mutation_potential", 0.1) as float, 0.0, 1.0)
	seed.planted_at = maxf(data.get("planted_at", 0.0) as float, 0.0)
	seed.is_planted = data.get("is_planted", false) as bool

	# Restore dungeon traits with defaults
	var raw_traits: Variant = data.get("dungeon_traits", {})
	if raw_traits is Dictionary:
		seed.dungeon_traits = (raw_traits as Dictionary).duplicate()
	else:
		seed.dungeon_traits = {
			TRAIT_ROOM_VARIETY: 0.3,
			TRAIT_HAZARD_FREQUENCY: 0.2,
			TRAIT_LOOT_BIAS: "gold",
		}

	# Ensure required trait keys exist
	if not seed.dungeon_traits.has(TRAIT_ROOM_VARIETY):
		seed.dungeon_traits[TRAIT_ROOM_VARIETY] = 0.3
	if not seed.dungeon_traits.has(TRAIT_HAZARD_FREQUENCY):
		seed.dungeon_traits[TRAIT_HAZARD_FREQUENCY] = 0.2
	if not seed.dungeon_traits.has(TRAIT_LOOT_BIAS):
		seed.dungeon_traits[TRAIT_LOOT_BIAS] = "gold"

	# Restore mutation slots with truncation to rarity limit
	var max_slots: int = GameConfig.MUTATION_SLOTS.get(seed.rarity, 1) as int
	var raw_slots: Variant = data.get("mutation_slots", [])
	seed.mutation_slots = []

	if raw_slots is Array:
		var slots_data: Array = raw_slots as Array
		var count: int = mini(slots_data.size(), max_slots)
		for i in range(count):
			if slots_data[i] is Dictionary:
				seed.mutation_slots.append(MutationSlot.from_dict(slots_data[i] as Dictionary))
			else:
				var empty_slot := MutationSlot.new()
				empty_slot.slot_index = i
				seed.mutation_slots.append(empty_slot)

	# Pad with empty slots if fewer than allowed
	while seed.mutation_slots.size() < max_slots:
		var pad_slot := MutationSlot.new()
		pad_slot.slot_index = seed.mutation_slots.size()
		seed.mutation_slots.append(pad_slot)

	return seed
```

---

*End of TASK-004: Seed Data Model & Maturation State Machine*
