# TASK-012: Seed Grove Manager (Plant, Grow, Mutate)

---

## Section 1 · Header

| Field                | Value                                                                                     |
| -------------------- | ----------------------------------------------------------------------------------------- |
| **Task ID**          | TASK-012                                                                                  |
| **Title**            | Seed Grove Manager (Plant, Grow, Mutate)                                                  |
| **Epic**             | Dungeon Seed                                                                              |
| **Story Points**     | 8 (Moderate)                                                                              |
| **Wave**             | 3                                                                                         |
| **Priority**         | P0 — Critical Path                                                                        |
| **Status**           | TODO                                                                                      |
| **Stream**           | 🔴 MCH (Mechanics) — Primary                                                             |
| **Cross-Stream**     | ⚪ TCH (serialization/save), 🔵 VIS (phase visuals for future UI), 🟢 AUD (phase SFX)    |
| **Critical Path**    | ✅ YES — the grow→harvest→dispatch loop is blocked without this                           |
| **Assignee**         | —                                                                                         |
| **Created**          | 2025-07-18                                                                                |
| **Updated**          | 2025-07-18                                                                                |
| **Target Engine**    | Godot 4.6                                                                                 |
| **Language**         | GDScript (static-typed)                                                                   |
| **Test Framework**   | GUT 9.x                                                                                   |
| **Output Files**     | `src/managers/seed_grove.gd`, `tests/managers/test_seed_grove.gd`                         |
| **Dependencies**     | TASK-004 (SeedData, MutationSlot), TASK-002 (DeterministicRNG), TASK-003 (Enums, Config)  |
| **Dependents**       | TASK-017 (Core Loop Orchestrator), TASK-018 (Seed Grove UI)                               |
| **GDD Reference**    | §4 Seed System, §4.1 Seed Grove, §4.5 Growth Timing                                      |

---

## Section 2 · Description

### 2.1 What This Task Does

TASK-012 creates `src/managers/seed_grove.gd` (`class_name SeedGrove`, extends `Node`), the
**primary seed management service** that owns all planted and unplanted seeds, advances their
growth every tick, handles mutation application, and exposes the query surface that downstream
systems (Core Loop Orchestrator, Seed Grove UI, Expedition Launcher) depend on.

The Seed Grove Manager is the **engine** that drives the Plant → Grow → Mutate → Bloom pipeline.
Without it, the core loop cannot advance past "player has a seed" — every downstream system that
reads seed state, checks bloom readiness, or triggers dungeon generation depends on this manager.

### 2.2 Player Experience Impact

| Moment                     | What the Player Feels                                                        |
| -------------------------- | ---------------------------------------------------------------------------- |
| **Plant a seed**           | Commitment — choosing which of their seeds to invest growth time into        |
| **Watch growth tick**      | Anticipation — the living progress bar that rewards patience                 |
| **Phase transition**       | Reward — visual/audio feedback, potential mutation roll                      |
| **Apply reagent**          | Agency — actively shaping the dungeon they will explore                      |
| **Bloom reached**          | Completion — seed is ready; decision point: explore now or keep mutating?    |
| **Uproot a seed**          | Consequence — losing progress is a meaningful sacrifice                      |
| **Return after AFK**       | Delight — offline growth means progress happened while away                  |

### 2.3 Economy Impact

The Seed Grove Manager is the **primary resource transformer** in the game economy:

- **Input faucet**: Raw seeds enter the grove from expedition rewards, shops, and events.
- **Time sink**: Growth phases gate seed availability — scarcity drives engagement.
- **Reagent sink**: Mutation slots consume reagents (crafted or purchased) — the primary reagent drain.
- **Output faucet**: Matured (BLOOM) seeds become dungeon blueprints — the expedition input.
- **Risk mechanism**: Uprooting destroys growth progress — sunk cost creates retention gravity.

```
                         ECONOMY FLOW
  ┌──────────┐      ┌──────────────┐      ┌───────────────┐
  │  Rewards  │─────▶│  Seed Grove  │─────▶│  Expedition   │
  │  Shops    │      │  (THIS TASK) │      │  Launcher     │
  │  Events   │      └──────┬───────┘      └───────────────┘
  └──────────┘             │
                    ┌──────▼───────┐
                    │  Reagent     │
                    │  Inventory   │
                    └──────────────┘
```

### 2.4 Technical Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          SeedGrove (Node)                           │
│                     src/managers/seed_grove.gd                      │
├─────────────────────────────────────────────────────────────────────┤
│  PROPERTIES                                                         │
│  ─────────                                                          │
│  seeds: Array[SeedData]           # all seeds in the grove          │
│  max_grove_slots: int = 3         # expandable via upgrades         │
│  rng: DeterministicRNG            # for mutation rolls              │
│                                                                     │
│  COMPUTED                                                           │
│  ────────                                                           │
│  planted_count -> int             # count of is_planted == true     │
│  available_slots -> int           # max_grove_slots - planted_count │
│                                                                     │
│  LIFECYCLE                                                          │
│  ─────────                                                          │
│  plant_seed(seed) -> bool                                           │
│  uproot_seed(seed_id) -> SeedData                                   │
│  tick(delta) -> Array[Dictionary]                                   │
│  apply_reagent(seed_id, reagent_id) -> bool                         │
│                                                                     │
│  QUERIES                                                            │
│  ───────                                                            │
│  get_planted_seeds() -> Array[SeedData]                             │
│  get_unplanted_seeds() -> Array[SeedData]                           │
│  get_matured_seeds() -> Array[SeedData]                             │
│  is_ready_for_expedition(seed_id) -> bool                           │
│  get_seed_by_id(seed_id) -> SeedData                                │
│  get_seed_count() -> int                                            │
│  get_available_slots() -> int                                       │
│                                                                     │
│  FACTORY                                                            │
│  ───────                                                            │
│  create_seed(rarity, element, rng) -> SeedData                      │
│  add_seed(seed) -> void                                             │
│  remove_seed(seed_id) -> SeedData                                   │
│                                                                     │
│  PERSISTENCE                                                        │
│  ───────────                                                        │
│  serialize() -> Dictionary                                          │
│  deserialize(data) -> void                                          │
├─────────────────────────────────────────────────────────────────────┤
│  SIGNALS (via EventBus)                                             │
│  ───────────────────────                                            │
│  seed_planted(seed_id, slot_index)                                  │
│  seed_phase_changed(seed_id, new_phase)                             │
│  seed_matured(seed_id, slot_index)                                  │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.5 System Interaction Map

```
  ┌───────────────┐         ┌───────────────┐        ┌────────────────┐
  │  TASK-004      │         │  TASK-002      │        │  TASK-003       │
  │  SeedData      │◀────────│  Deterministic │        │  Enums          │
  │  MutationSlot  │         │  RNG           │        │  GameConfig     │
  └───────┬───────┘         └───────┬───────┘        └───────┬────────┘
          │                         │                         │
          │    ┌────────────────────┼─────────────────────────┘
          │    │                    │
          ▼    ▼                    ▼
  ┌──────────────────────────────────────────┐
  │         TASK-012: SeedGrove              │ ◀──── THIS TASK
  │         src/managers/seed_grove.gd       │
  └──────────┬───────────────┬───────────────┘
             │               │
             ▼               ▼
  ┌──────────────┐   ┌──────────────────┐
  │  TASK-017     │   │  TASK-018         │
  │  Core Loop    │   │  Seed Grove UI    │
  │  Orchestrator │   │  (display/input)  │
  └──────────────┘   └──────────────────┘
```

### 2.6 Growth Phase State Machine

```
   ┌────────┐   10 min base   ┌────────┐   30 min base   ┌──────┐   60 min base   ┌───────┐
   │ SPORE  │ ───────────────▶│ SPROUT │ ───────────────▶│ BUD  │ ───────────────▶│ BLOOM │
   └────────┘   (×rarity)     └────────┘   (×rarity)     └──────┘   (×rarity)     └───────┘
                  │                          │                        │               (terminal)
                  ▼                          ▼                        ▼
             mutation roll             mutation roll             mutation roll
             if potential > 0          if potential > 0         if potential > 0
```

### 2.7 Constraints

- **Thread Safety**: All operations are single-threaded (Godot main thread). No mutex needed.
- **Determinism**: Mutation rolls MUST use `DeterministicRNG`, never `randf()` or `randi()`.
- **No UI**: This task produces NO visual output. UI is TASK-018.
- **No Audio**: This task emits NO audio. SFX hookup is downstream via EventBus signals.
- **Signal-Only Communication**: SeedGrove communicates state changes exclusively through EventBus signals. It never calls UI or audio methods directly.
- **Save Compatibility**: `serialize()`/`deserialize()` must produce/consume stable Dictionary schemas. Adding optional keys is allowed; removing or renaming keys is a breaking change.

---

## Section 3 · Use Cases

### UC-01 · The Patient Gardener (Casual Player)

**Archetype**: Plays 20-minute sessions, checks in 2-3 times per day. Values collection over min-maxing.

1. Opens game after 8-hour work day. Sees notification: "2 seeds have bloomed!"
2. Checks the grove — one Common TERRA seed reached BLOOM, one Uncommon FLAME seed reached BLOOM.
3. Plants a new Rare ARCANE seed from yesterday's expedition reward into an open slot.
4. Applies a single "Labyrinthine" reagent to the Rare seed's mutation slot — hopes for complex room layouts.
5. Dispatches the TERRA BLOOM seed on an expedition.
6. Closes game. Seeds continue growing offline.

**SeedGrove touchpoints**: `tick()` (offline catch-up), `get_matured_seeds()`, `plant_seed()`, `apply_reagent()`, `is_ready_for_expedition()`.

### UC-02 · The Min-Maxer (Hardcore Player)

**Archetype**: Plays 2-hour sessions. Optimizes mutation potential, plans reagent application order.

1. Opens game. Checks planted seed growth percentages via `get_planted_seeds()`.
2. Notices a Legendary SHADOW seed is about to transition from SPROUT → BUD.
3. Waits for phase change, watches mutation roll succeed (high mutation_potential on Legendary).
4. Immediately applies "Perilous" reagent to second mutation slot to stack difficulty modifiers.
5. Applies "Bountiful" reagent to third mutation slot for increased loot.
6. Calculates optimal time to return for BUD → BLOOM transition.
7. Uproots a low-value Common seed to free a slot for a newly acquired Epic seed.
8. Plants the Epic seed, knowing the growth multiplier (0.7×) means faster bloom.

**SeedGrove touchpoints**: `get_planted_seeds()`, `tick()`, `apply_reagent()` ×2, `uproot_seed()`, `plant_seed()`, `get_available_slots()`.

### UC-03 · The Experimenter (Discovery Player)

**Archetype**: Plays to explore systems. Tries unusual combinations to discover emergent outcomes.

1. Has 5 seeds in inventory, 3 planted. Wonders what happens with different reagent combos.
2. Calls `get_unplanted_seeds()` to review available options.
3. Uproots a nearly-mature BUD seed (painful!) to test a theory about FROST + "Elemental Surge" reagent.
4. Plants a fresh FROST seed, applies "Elemental Surge" reagent immediately.
5. Plants a fresh FROST seed in another slot WITHOUT reagent, as a control.
6. Plans to compare dungeon_traits when both bloom.

**SeedGrove touchpoints**: `get_unplanted_seeds()`, `uproot_seed()`, `plant_seed()` ×2, `apply_reagent()`, `create_seed()`.

### UC-04 · The Returning Player (Re-engagement)

**Archetype**: Left the game for 3 days. Returns to find offline progress.

1. Opens game after 72-hour absence.
2. `tick()` is called with large accumulated delta (capped by system).
3. All 3 planted seeds have bloomed — massive catch-up growth applied.
4. Player sees 3 bloom notifications queued up.
5. Checks `get_matured_seeds()` — all 3 are in BLOOM phase.
6. Happy surprise drives immediate engagement — dispatches all 3 on expeditions.

**SeedGrove touchpoints**: `tick()` (large delta), `get_matured_seeds()`, `is_ready_for_expedition()`.

---

## Section 4 · Glossary

| #  | Term                    | Definition                                                                                                       |
| -- | ----------------------- | ---------------------------------------------------------------------------------------------------------------- |
| 1  | **Seed**                | The foundational resource; a deterministic dungeon blueprint that grows through four phases.                      |
| 2  | **SeedData**            | The data model (TASK-004) representing a single seed's state: rarity, element, phase, growth, traits, mutations. |
| 3  | **Seed Grove**          | The player's seed collection and planting area. Both inventory and active growth slots.                          |
| 4  | **Planted Seed**        | A seed assigned to a grove slot, actively growing toward BLOOM.                                                  |
| 5  | **Unplanted Seed**      | A seed in the grove inventory but not assigned to a slot. Does not grow.                                         |
| 6  | **Growth Phase**        | One of four stages: SPORE → SPROUT → BUD → BLOOM. Each has a base duration.                                     |
| 7  | **Phase Transition**    | The moment a seed advances from one growth phase to the next. Triggers mutation roll.                            |
| 8  | **BLOOM**               | Terminal growth phase. Seed is mature and ready for dungeon generation or expedition dispatch.                    |
| 9  | **Mutation Slot**       | A slot on a seed that accepts a reagent. Count determined by rarity (1/1/2/2/3).                                 |
| 10 | **Mutation Potential**  | Float 0.0–1.0 representing the probability of a spontaneous mutation on phase transition.                        |
| 11 | **Reagent**             | Consumable item applied to a mutation slot. Modifies dungeon_traits deterministically.                           |
| 12 | **Dungeon Traits**      | Dictionary of seed properties that shape dungeon generation: room_variety, hazard_frequency, loot_bias.          |
| 13 | **Growth Rate**         | Seconds required per phase. Base value modified by rarity multiplier.                                            |
| 14 | **Rarity Multiplier**   | Scaling factor applied to growth time. Higher rarity = lower multiplier = faster growth.                         |
| 15 | **Tick**                | A single frame's growth update. `tick(delta)` advances all planted seeds by `delta` seconds.                     |
| 16 | **Offline Growth**      | Seeds continue growing while the game is closed. Accumulated delta applied on next `tick()`.                     |
| 17 | **Uproot**              | Remove a planted seed from its slot. Loses all growth progress. Seed returns to inventory.                       |
| 18 | **DeterministicRNG**    | TASK-002 random number generator. Ensures mutation rolls are reproducible given same seed state.                  |
| 19 | **EventBus**            | Global signal bus (TASK-001). SeedGrove emits signals here for decoupled communication.                          |
| 20 | **Grove Slot**          | One of `max_grove_slots` positions where a seed can be planted. Starts at 3, expandable.                         |

---

## Section 5 · Out of Scope

| #  | Exclusion                              | Rationale                                                                      |
| -- | -------------------------------------- | ------------------------------------------------------------------------------ |
| 1  | **Seed Grove UI / HUD**                | TASK-018. This task is logic-only; no Control nodes, no rendering.             |
| 2  | **Dungeon Generation from Seeds**      | TASK-019+. SeedGrove only grows seeds to BLOOM; it does not generate dungeons. |
| 3  | **Expedition Dispatch Logic**          | TASK-017. SeedGrove answers `is_ready_for_expedition()` but does not dispatch. |
| 4  | **Reagent Inventory Management**       | Separate reagent system. SeedGrove receives a `reagent_id` string, not items.  |
| 5  | **Reagent Crafting or Acquisition**    | Economy system. SeedGrove only consumes reagents via `apply_reagent()`.        |
| 6  | **Sound Effects / Music**              | 🟢 AUD stream. Downstream systems subscribe to EventBus signals for SFX.      |
| 7  | **Visual Effects / Animations**        | 🔵 VIS stream. Phase change visuals are TASK-018 responsibility.              |
| 8  | **Guild Upgrade System**               | Separate guild system. SeedGrove exposes `max_grove_slots` for external set.   |
| 9  | **Seed Trading / Gifting**             | Social feature. SeedGrove supports `remove_seed()` which trading can call.     |
| 10 | **Seed Fusion / Combination**          | Future feature. Not in initial GDD scope for v1.                               |
| 11 | **Seed Decay / Expiration**            | BLOOM is terminal and stable. Seeds do not decay in v1.                        |
| 12 | **Auto-Plant / Queue System**          | QoL feature for later. Players must manually plant each seed.                  |
| 13 | **Achievement Tracking**               | Achievement system reads EventBus signals; SeedGrove does not track.           |
| 14 | **Notification Push (OS-level)**       | Platform integration. SeedGrove emits signals; notification system subscribes. |
| 15 | **Reagent Effect Definitions**         | Reagent data is config-driven. SeedGrove receives effects as Dictionary.       |

---

## Section 6 · Functional Requirements

### 6.1 Seed Inventory Management

| ID      | Requirement                                                                                                | Priority |
| ------- | ---------------------------------------------------------------------------------------------------------- | -------- |
| FR-001  | SeedGrove SHALL maintain an `Array[SeedData]` containing all seeds (planted and unplanted).                | P0       |
| FR-002  | `add_seed(seed)` SHALL append a SeedData instance to the seeds array.                                      | P0       |
| FR-003  | `remove_seed(seed_id)` SHALL remove and return the seed with matching id, or return null if not found.     | P0       |
| FR-004  | `get_seed_by_id(seed_id)` SHALL return the SeedData with matching id, or null if not found.                | P0       |
| FR-005  | `get_seed_count()` SHALL return the total number of seeds in the grove (planted + unplanted).              | P0       |
| FR-006  | `get_unplanted_seeds()` SHALL return an Array of all seeds where `is_planted == false`.                    | P0       |
| FR-007  | Removing a planted seed via `remove_seed()` SHALL first uproot it (reset growth) before removal.           | P1       |

### 6.2 Planting and Uprooting

| ID      | Requirement                                                                                                | Priority |
| ------- | ---------------------------------------------------------------------------------------------------------- | -------- |
| FR-010  | `plant_seed(seed)` SHALL return `false` if `planted_count >= max_grove_slots`.                             | P0       |
| FR-011  | `plant_seed(seed)` SHALL return `false` if the seed is already planted (`seed.is_planted == true`).        | P0       |
| FR-012  | `plant_seed(seed)` SHALL return `false` if the seed is not in the grove's seeds array.                     | P0       |
| FR-013  | On successful plant, `plant_seed()` SHALL set `seed.is_planted = true` and `seed.planted_at = now`.        | P0       |
| FR-014  | On successful plant, `plant_seed()` SHALL set `seed.phase = Enums.SeedPhase.SPORE` if not already set.     | P0       |
| FR-015  | On successful plant, `plant_seed()` SHALL emit `EventBus.seed_planted(seed.id, slot_index)`.               | P0       |
| FR-016  | `plant_seed()` SHALL return `true` on success.                                                             | P0       |
| FR-017  | `uproot_seed(seed_id)` SHALL set `seed.is_planted = false` and reset `seed.growth_progress = 0.0`.        | P0       |
| FR-018  | `uproot_seed(seed_id)` SHALL reset `seed.phase` to `Enums.SeedPhase.SPORE`.                               | P0       |
| FR-019  | `uproot_seed(seed_id)` SHALL return the SeedData on success, or null if seed_id is not found.              | P0       |
| FR-020  | `uproot_seed(seed_id)` SHALL return null if the seed is not currently planted.                             | P1       |
| FR-021  | `get_planted_seeds()` SHALL return an Array of all seeds where `is_planted == true`.                       | P0       |
| FR-022  | `planted_count` SHALL equal the length of `get_planted_seeds()`.                                           | P0       |
| FR-023  | `get_available_slots()` SHALL return `max_grove_slots - planted_count`.                                    | P0       |

### 6.3 Growth Tick

| ID      | Requirement                                                                                                | Priority |
| ------- | ---------------------------------------------------------------------------------------------------------- | -------- |
| FR-030  | `tick(delta)` SHALL call `seed.advance_growth(delta)` for every planted seed.                              | P0       |
| FR-031  | `tick(delta)` SHALL NOT advance unplanted seeds.                                                           | P0       |
| FR-032  | `tick(delta)` SHALL NOT advance seeds already in BLOOM phase.                                              | P0       |
| FR-033  | If `advance_growth()` returns a new phase, `tick()` SHALL emit `EventBus.seed_phase_changed`.              | P0       |
| FR-034  | On phase transition, `tick()` SHALL perform a mutation roll using `rng.randf()` vs `mutation_potential`.   | P0       |
| FR-035  | If mutation roll succeeds, `tick()` SHALL apply a random mutation to the seed's `dungeon_traits`.          | P0       |
| FR-036  | If phase transitions to BLOOM, `tick()` SHALL emit `EventBus.seed_matured(seed_id, slot_index)`.          | P0       |
| FR-037  | `tick(delta)` SHALL return an `Array[Dictionary]` of all events that occurred during this tick.            | P0       |
| FR-038  | Each event Dictionary SHALL contain keys: `seed_id`, `event`, `data`.                                     | P0       |
| FR-039  | Event types SHALL be: `"phase_changed"`, `"bloom_reached"`, `"mutated"`.                                  | P0       |
| FR-040  | `tick(delta)` SHALL handle delta values from 0.0 to 259200.0 (72 hours) for offline catch-up.             | P0       |
| FR-041  | Seeds SHALL NOT skip phases even with large delta values. Each transition is processed sequentially.       | P1       |

### 6.4 Mutation and Reagent Application

| ID      | Requirement                                                                                                | Priority |
| ------- | ---------------------------------------------------------------------------------------------------------- | -------- |
| FR-050  | `apply_reagent(seed_id, reagent_id)` SHALL return `false` if seed_id is not found.                         | P0       |
| FR-051  | `apply_reagent()` SHALL return `false` if the seed has no empty mutation slots.                             | P0       |
| FR-052  | `apply_reagent()` SHALL fill the first empty MutationSlot with the reagent_id and its effect Dictionary.   | P0       |
| FR-053  | `apply_reagent()` SHALL modify `seed.dungeon_traits` according to the reagent's effect Dictionary.         | P0       |
| FR-054  | `apply_reagent()` SHALL return `true` on successful application.                                           | P0       |
| FR-055  | Reagent effects SHALL be defined as `Dictionary` with keys mapping to dungeon_trait modifiers.              | P0       |
| FR-056  | Spontaneous mutation on phase change SHALL use `rng.randf() < seed.mutation_potential` as the check.       | P0       |
| FR-057  | Spontaneous mutation SHALL select a random dungeon_trait key and apply a random modifier.                  | P1       |
| FR-058  | Failed spontaneous mutation SHALL produce no side effects (no trait changes, no slot consumption).          | P0       |

### 6.5 Query and Readiness

| ID      | Requirement                                                                                                | Priority |
| ------- | ---------------------------------------------------------------------------------------------------------- | -------- |
| FR-060  | `get_matured_seeds()` SHALL return all seeds where `phase == Enums.SeedPhase.BLOOM`.                       | P0       |
| FR-061  | `is_ready_for_expedition(seed_id)` SHALL return `true` if seed phase is SPROUT, BUD, or BLOOM.            | P0       |
| FR-062  | `is_ready_for_expedition(seed_id)` SHALL return `false` if seed is in SPORE phase.                        | P0       |
| FR-063  | `is_ready_for_expedition(seed_id)` SHALL return `false` if seed_id is not found.                          | P0       |

### 6.6 Seed Factory

| ID      | Requirement                                                                                                | Priority |
| ------- | ---------------------------------------------------------------------------------------------------------- | -------- |
| FR-070  | `create_seed()` SHALL generate a unique `id` using `rng`.                                                  | P0       |
| FR-071  | `create_seed()` SHALL initialize `phase` to `SPORE`, `growth_progress` to `0.0`.                          | P0       |
| FR-072  | `create_seed()` SHALL set `growth_rate` based on `GameConfig.BASE_GROWTH_SECONDS` and rarity multiplier.  | P0       |
| FR-073  | `create_seed()` SHALL create mutation slots per `GameConfig.MUTATION_SLOTS_BY_RARITY`.                     | P0       |
| FR-074  | `create_seed()` SHALL initialize `dungeon_traits` with default values.                                     | P0       |
| FR-075  | `create_seed()` SHALL set `mutation_potential` based on rarity (higher rarity = higher potential).          | P1       |
| FR-076  | `create_seed()` SHALL NOT automatically add the seed to the grove. Caller must use `add_seed()`.           | P0       |

### 6.7 Serialization

| ID      | Requirement                                                                                                | Priority |
| ------- | ---------------------------------------------------------------------------------------------------------- | -------- |
| FR-080  | `serialize()` SHALL return a Dictionary containing all grove state needed for save/load.                   | P0       |
| FR-081  | `serialize()` SHALL include `seeds` (array of seed dictionaries), `max_grove_slots`, and `rng` state.      | P0       |
| FR-082  | `deserialize(data)` SHALL restore the grove to the exact state represented by the Dictionary.              | P0       |
| FR-083  | `deserialize()` SHALL handle missing optional keys gracefully (use defaults).                              | P1       |
| FR-084  | Round-trip `serialize()` → `deserialize()` SHALL produce identical grove state.                            | P0       |
| FR-085  | `serialize()` SHALL call `seed.to_dict()` for each seed in the array.                                     | P0       |
| FR-086  | `deserialize()` SHALL call `SeedData.from_dict()` for each seed dictionary.                               | P0       |

---

## Section 7 · Non-Functional Requirements

| ID       | Category        | Requirement                                                                                                            | Target                  |
| -------- | --------------- | ---------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| NFR-001  | Performance     | `tick(delta)` SHALL complete in under 1ms for 50 planted seeds at 60 FPS.                                              | < 1ms                   |
| NFR-002  | Performance     | `tick(delta)` with 72-hour offline catch-up SHALL complete in under 16ms (one frame budget).                            | < 16ms                  |
| NFR-003  | Performance     | `get_planted_seeds()` SHALL not allocate a new array on every call if no seeds changed since last call.                 | Zero-alloc steady state |
| NFR-004  | Memory          | SeedGrove SHALL not hold references to removed seeds (no memory leaks).                                                | 0 orphan refs           |
| NFR-005  | Memory          | Each SeedData instance SHALL consume less than 1 KB of memory.                                                         | < 1 KB / seed           |
| NFR-006  | Determinism     | Given identical RNG seed and identical operations, SeedGrove SHALL produce identical state.                             | Bit-exact               |
| NFR-007  | Determinism     | Mutation rolls SHALL never use global `randf()` / `randi()`. Only `DeterministicRNG` methods.                          | 100% RNG isolation      |
| NFR-008  | Serialization   | `serialize()` output SHALL be valid JSON-compatible Dictionary (no Object references, no Callables).                   | JSON-safe               |
| NFR-009  | Serialization   | Round-trip serialize/deserialize SHALL preserve all seed state including growth_progress float precision to 6 decimals. | ±0.000001               |
| NFR-010  | Testability     | All public methods SHALL be testable without scene tree (unit-testable via `add_child()` in test).                     | 100% unit-testable      |
| NFR-011  | Testability     | SeedGrove SHALL have zero hard-coded dependencies. All dependencies injected or configurable.                          | DI-ready                |
| NFR-012  | Maintainability | All public methods SHALL have doc comments describing parameters, return values, and side effects.                     | 100% documented         |
| NFR-013  | Maintainability | Code SHALL follow GDScript static typing with explicit type hints on all variables and function signatures.             | 100% typed              |
| NFR-014  | Robustness      | All public methods SHALL validate input parameters and return safe defaults (null, false, empty) on invalid input.     | Crash-free              |
| NFR-015  | Robustness      | `tick()` SHALL not emit duplicate events for the same phase transition in a single call.                               | No duplicates           |
| NFR-016  | Compatibility   | SeedGrove SHALL extend Node (not RefCounted) for scene tree integration and potential `_process()` hookup.             | Node subclass           |
| NFR-017  | Scalability     | Grove SHALL support up to 100 total seeds (planted + unplanted) without performance degradation.                       | 100 seeds               |
| NFR-018  | Observability   | All state-changing operations SHALL be traceable via EventBus signals for logging/debug.                               | Full signal coverage    |

---

## Section 8 · Designer's Manual

### 8.1 Overview

The Seed Grove Manager (`SeedGrove`) is the single source of truth for all seed state in the game.
Every system that needs to read, modify, or react to seed changes goes through this manager.

Think of it as a **garden with limited planting beds** and an **infinite seed bag**:
- The seed bag (`seeds` array, unplanted) holds all seeds the player owns.
- The planting beds (`max_grove_slots`) determine how many can grow simultaneously.
- Each tick, the planted seeds grow a little closer to BLOOM.

### 8.2 Tuning Guide

#### Growth Duration Tuning

The base growth times are defined in `GameConfig.BASE_GROWTH_SECONDS`:

```
Phase       Base Time    Player Feel
─────────   ──────────   ─────────────────────────────────────
SPORE       (initial)    Instant — seed starts here when planted
SPROUT      600s (10m)   Quick win — first phase change comes fast
BUD         1800s (30m)  Medium wait — time to apply reagents
BLOOM       3600s (60m)  Long anticipation — offline growth shines
─────────   ──────────   ─────────────────────────────────────
Total       ~6000s       About 100 minutes base
```

#### Rarity Multiplier Tuning

Higher-rarity seeds grow **faster** (lower multiplier). This is intentional:
- Rewards rare seed acquisition with faster results.
- Prevents legendary seeds from feeling like a punishment to grow.
- Creates a desirable "premium feel" for high-rarity seeds.

```
Rarity       Multiplier   Total Time    Savings
───────────  ──────────   ──────────    ───────
COMMON       1.0×         100 min       —
UNCOMMON     0.9×         90 min        10 min
RARE         0.8×         80 min        20 min
EPIC         0.7×         70 min        30 min
LEGENDARY    0.6×         60 min        40 min
```

**Tuning tip**: If player feedback says "growth is too slow," adjust BASE_GROWTH_SECONDS first.
If only high-rarity feels wrong, adjust RARITY_GROWTH_MULTIPLIER. Do not change both at once.

#### Mutation Potential Tuning

Mutation potential is the chance of a spontaneous mutation on phase change:

```
Rarity       Suggested Potential   Expected Mutations (3 transitions)
───────────  ───────────────────   ──────────────────────────────────
COMMON       0.05 (5%)             ~0.15 (very rare)
UNCOMMON     0.10 (10%)            ~0.30 (unlikely)
RARE         0.20 (20%)            ~0.60 (possible one)
EPIC         0.35 (35%)            ~1.05 (likely one)
LEGENDARY    0.50 (50%)            ~1.50 (one to two expected)
```

**Tuning tip**: Mutation potential is the "excitement factor." Too low = boring transitions.
Too high = makes reagents feel less special. Target: reagents are the primary mutation source,
spontaneous mutations are "bonus surprises."

#### Mutation Slot Count

```
Rarity       Slots   Design Intent
───────────  ─────   ──────────────────────────────────────────
COMMON       1       One knob to turn — simple, approachable
UNCOMMON     1       Same as Common — upgrade comes at Rare
RARE         2       Two dimensions of control — meaningful choice
EPIC         2       Same as Rare — upgrade comes at Legendary
LEGENDARY    3       Full control — master gardener territory
```

### 8.3 Configuration Reference

All constants live in `GameConfig` (TASK-003). SeedGrove reads them, never hard-codes them:

| Constant                       | Type         | Default                      | Used By              |
| ------------------------------ | ------------ | ---------------------------- | -------------------- |
| `BASE_GROWTH_SECONDS`          | Dictionary   | {SPORE:0, SPROUT:600, ...}  | `create_seed()`      |
| `RARITY_GROWTH_MULTIPLIER`     | Dictionary   | {COMMON:1.0, ...LEGEND:0.6} | `create_seed()`      |
| `MUTATION_SLOTS_BY_RARITY`     | Dictionary   | {COMMON:1, ...LEGENDARY:3}  | `create_seed()`      |
| `DEFAULT_MAX_GROVE_SLOTS`      | int          | 3                            | `SeedGrove._ready()` |
| `DEFAULT_DUNGEON_TRAITS`       | Dictionary   | (see below)                  | `create_seed()`      |

Default dungeon traits:
```gdscript
const DEFAULT_DUNGEON_TRAITS: Dictionary = {
    "room_variety": 0.5,
    "hazard_frequency": 0.3,
    "loot_bias": "BALANCED",
    "corridor_complexity": 0.5,
    "secret_room_chance": 0.1,
    "elite_spawn_rate": 0.15,
}
```

### 8.4 Signal Map

```
┌──────────────────┐          ┌──────────────────┐
│   SeedGrove      │──emit───▶│   EventBus       │
│                  │          │                  │
│  plant_seed()    │──────────│─▶ seed_planted   │───▶ UI, Achievements, Analytics
│  tick()          │──────────│─▶ seed_phase_    │───▶ UI, SFX, VFX, Achievements
│                  │          │   changed        │
│  tick()          │──────────│─▶ seed_matured   │───▶ UI, SFX, Expedition, Quests
└──────────────────┘          └──────────────────┘
```

| Signal                 | Emitted When                        | Payload                           |
| ---------------------- | ----------------------------------- | --------------------------------- |
| `seed_planted`         | `plant_seed()` succeeds             | `(seed_id: StringName, slot: int)`|
| `seed_phase_changed`   | Phase transition during `tick()`    | `(seed_id: StringName, phase: int)`|
| `seed_matured`         | Seed reaches BLOOM during `tick()`  | `(seed_id: StringName, slot: int)`|

### 8.5 Debug Tools

The following debug methods should be available in debug builds:

```gdscript
## Force a seed to a specific phase (debug only).
func debug_set_phase(seed_id: String, phase: Enums.SeedPhase) -> void:
    var seed := get_seed_by_id(seed_id)
    if seed:
        seed.phase = phase
        seed.growth_progress = 0.0

## Force-bloom all planted seeds instantly (debug only).
func debug_bloom_all() -> void:
    for seed in get_planted_seeds():
        seed.phase = Enums.SeedPhase.BLOOM
        seed.growth_progress = 1.0

## Print grove state to console (debug only).
func debug_print_state() -> void:
    print("=== SeedGrove State ===")
    print("Total seeds: %d | Planted: %d / %d" % [seeds.size(), planted_count, max_grove_slots])
    for seed in seeds:
        var status := "PLANTED" if seed.is_planted else "inventory"
        print("  [%s] %s %s | Phase: %s | Progress: %.2f | %s" % [
            seed.id.left(8), Enums.SeedRarity.keys()[seed.rarity],
            Enums.Element.keys()[seed.element],
            Enums.SeedPhase.keys()[seed.phase],
            seed.growth_progress, status
        ])

## Advance time by N seconds for a specific seed (debug only).
func debug_advance_seed(seed_id: String, seconds: float) -> void:
    var seed := get_seed_by_id(seed_id)
    if seed and seed.is_planted:
        seed.advance_growth(seconds)
```

### 8.6 Common Integration Patterns

#### Pattern: Planting from UI

```gdscript
# In Seed Grove UI (TASK-018):
func _on_plant_button_pressed(seed: SeedData) -> void:
    var success := seed_grove.plant_seed(seed)
    if not success:
        show_error("No available grove slots!")
```

#### Pattern: Offline Growth Catch-Up

```gdscript
# In Core Loop Orchestrator (TASK-017):
func _on_game_resumed(last_save_timestamp: float) -> void:
    var now := Time.get_unix_time_from_system()
    var offline_delta := now - last_save_timestamp
    var events := seed_grove.tick(offline_delta)
    for event in events:
        _process_grove_event(event)
```

#### Pattern: Reagent Application from Inventory

```gdscript
# In Reagent UI:
func _on_reagent_applied(seed_id: String, reagent_id: String) -> void:
    var success := seed_grove.apply_reagent(seed_id, reagent_id)
    if success:
        reagent_inventory.consume(reagent_id)
    else:
        show_error("No empty mutation slots on this seed!")
```

#### Pattern: Expedition Readiness Check

```gdscript
# In Expedition Launcher:
func _can_dispatch(seed_id: String) -> bool:
    return seed_grove.is_ready_for_expedition(seed_id)
```

---

## Section 9 · Assumptions

| #  | Assumption                                                                                                          | Impact if Wrong                                                        |
| -- | ------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| 1  | TASK-004 `SeedData.advance_growth(delta)` returns the **new** phase if a transition occurred, or the current phase. | If it returns only bool, `tick()` logic needs to compare before/after. |
| 2  | TASK-002 `DeterministicRNG` is stateless per-call (no hidden internal mutation beyond its seed).                    | Mutation determinism could break if RNG has side-channel state.        |
| 3  | TASK-001 `EventBus` is an autoloaded singleton accessible as `EventBus`.                                           | Signal emission calls need to change if EventBus path differs.         |
| 4  | TASK-003 `Enums` is an autoloaded singleton or a const class accessible as `Enums.SeedPhase`, etc.                 | All enum references need to change if access pattern differs.          |
| 5  | `GameConfig` constants are accessible as static class members (e.g., `GameConfig.BASE_GROWTH_SECONDS`).            | Need to change access pattern if GameConfig is instance-based.         |
| 6  | `SeedData.planted_at` stores a float Unix timestamp from `Time.get_unix_time_from_system()`.                       | Offline growth calculation would need adjustment.                      |
| 7  | `MutationSlot.is_empty()` returns `true` when `reagent_id` is empty string.                                        | Slot-finding logic in `apply_reagent()` would break.                   |
| 8  | Growth phases are strictly linear: SPORE → SPROUT → BUD → BLOOM. No branching or skipping.                         | State machine logic would need redesign.                               |
| 9  | BLOOM is a terminal state. Seeds in BLOOM do not decay, expire, or transition further.                              | Would need new states and transition logic.                            |
| 10 | `max_grove_slots` starts at 3 and can only increase (never decrease below planted count).                           | Decreasing slots could orphan planted seeds.                           |
| 11 | Reagent effects are provided as a Dictionary by the caller. SeedGrove does not look up reagent definitions.         | Would need reagent database dependency if SeedGrove must resolve IDs.  |
| 12 | `seed.dungeon_traits` is a flat Dictionary (no nested Dictionaries). Modifiers are additive floats or string sets.  | Nested merging logic would be needed for complex trait structures.     |
| 13 | EventBus signals are fire-and-forget. SeedGrove does not wait for signal handlers to complete.                      | Synchronous signal handlers could cause re-entrancy issues.            |
| 14 | All time values in the system use seconds as the base unit (not milliseconds, not ticks).                           | Unit conversion bugs in growth timing.                                 |
| 15 | The game supports offline growth by storing the last-save timestamp and computing delta on resume.                  | If offline growth is real-time server-based, architecture changes.     |
| 16 | Seed IDs are globally unique strings (UUID or similar). No two seeds ever share an ID.                              | Lookup-by-ID methods could return wrong seeds.                         |
| 17 | A seed must be in the grove's `seeds` array before it can be planted. External seeds are added first via `add_seed()`. | `plant_seed()` on foreign seeds would fail silently.               |

---

## Section 10 · Security & Anti-Cheat

### Threat Model

| #  | Threat                        | Attack Vector                                                       | Severity | Mitigation                                                                                                   |
| -- | ----------------------------- | ------------------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------ |
| 1  | **Save File Manipulation**    | Player edits save JSON to set all seeds to BLOOM phase instantly.   | HIGH     | Validate deserialized data: phase must be valid enum, growth_progress must be 0.0–1.0, planted_at must be ≤ now. Add checksum to save data. |
| 2  | **Clock Manipulation**        | Player advances system clock forward to trigger offline growth.     | MEDIUM   | Cap maximum offline delta (e.g., 72 hours). Use server timestamp if available. Track cumulative growth time per seed and compare against theoretical maximum. |
| 3  | **Mutation Potential Hack**   | Player edits save to set `mutation_potential = 1.0` on all seeds.   | MEDIUM   | Validate mutation_potential is within expected range per rarity on deserialize. Clamp to `[0.0, MAX_POTENTIAL_FOR_RARITY]`. |
| 4  | **Infinite Slot Exploit**     | Player edits `max_grove_slots` in save to 9999.                    | MEDIUM   | Clamp `max_grove_slots` to `[1, MAX_ALLOWED_GROVE_SLOTS]` on deserialize. Track slot upgrades separately.    |
| 5  | **Reagent Duplication**       | Player applies reagent via save edit without consuming it.         | LOW      | SeedGrove returns success/fail; the *caller* is responsible for consuming the reagent. Audit trail in save.  |
| 6  | **Seed Duplication**          | Player duplicates seed entries in save file.                       | HIGH     | Validate seed ID uniqueness on deserialize. Reject duplicates, keep first occurrence.                        |
| 7  | **Growth Rate Manipulation**  | Player edits `growth_rate` to 0.001 for instant growth.            | MEDIUM   | Validate growth_rate against GameConfig expected values on deserialize. Recalculate from rarity if invalid.  |

### Validation Rules Applied on Deserialize

```gdscript
# These validations run inside deserialize():
# 1. seed.phase must be in range [0, 3] (SPORE..BLOOM)
# 2. seed.growth_progress must be in range [0.0, 1.0]
# 3. seed.mutation_potential must be in range [0.0, 0.6]
# 4. seed.rarity must be valid Enums.SeedRarity value
# 5. seed.element must be valid Enums.Element value
# 6. max_grove_slots must be in range [1, 20]
# 7. No duplicate seed IDs in the seeds array
# 8. planted_at must be <= current system time (no future timestamps)
# 9. Planted seed count must not exceed max_grove_slots
# 10. growth_rate must be >= minimum for rarity (prevents instant-growth hacks)
```

---

## Section 11 · Best Practices

| #  | Practice                               | Rationale                                                                                                     |
| -- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| 1  | **Use DeterministicRNG exclusively**   | Never call global `randf()` or `randi()`. All randomness flows through the injected RNG for reproducibility.  |
| 2  | **Return copies, not references**      | Query methods like `get_planted_seeds()` should return filtered copies to prevent external mutation.           |
| 3  | **Validate all public method inputs**  | Check for null, empty strings, invalid IDs before operating. Return safe defaults on failure.                 |
| 4  | **Emit signals after state change**    | Signal emission happens AFTER the state mutation is complete, so listeners see consistent state.              |
| 5  | **Keep tick() allocation-light**       | Pre-allocate the events array. Avoid creating Dictionaries in the hot path unless an event actually occurred. |
| 6  | **Single Responsibility for tick()**   | `tick()` only advances growth and handles phase transitions. It does not trigger UI, audio, or expedition.    |
| 7  | **Document all signals with payload**  | Every signal emission site should have a comment listing the payload format.                                  |
| 8  | **Use static types everywhere**        | Every variable, parameter, and return type must have an explicit GDScript type annotation.                    |
| 9  | **Prefer early returns**               | Guard clauses at the top of methods reduce nesting and improve readability.                                   |
| 10 | **Separate creation from registration**| `create_seed()` makes the object; `add_seed()` puts it in the grove. Two distinct steps for flexibility.     |
| 11 | **Config over constants**              | Read tuning values from GameConfig, never hard-code numbers. Designers must be able to tune without code.     |
| 12 | **Test offline growth explicitly**     | Large-delta tick() is a critical path. Dedicated tests for multi-hour offline scenarios are mandatory.        |
| 13 | **Cap offline delta**                  | Clamp the delta passed to tick() to a maximum (72h). Prevents absurd growth from far-future timestamps.      |
| 14 | **Log phase transitions**              | Print debug info on phase transitions for development. Guard behind OS.is_debug_build() or feature flag.     |
| 15 | **Idempotent deserialize**             | Calling deserialize() twice with the same data should produce identical state. No cumulative side effects.    |

---

## Section 12 · Troubleshooting

### Issue 1: Seeds Not Growing

| Field       | Detail                                                                                          |
| ----------- | ----------------------------------------------------------------------------------------------- |
| **Symptom** | Planted seeds remain at SPORE phase with 0.0 growth_progress despite time passing.              |
| **Cause A** | `tick()` is not being called. The Core Loop Orchestrator (TASK-017) must call `tick(delta)` each frame or on a timer. |
| **Cause B** | Seeds are not marked as planted. Check `seed.is_planted == true`.                               |
| **Cause C** | Delta is always 0.0. Verify the caller is passing actual elapsed seconds, not fixed zero.       |
| **Solution** | 1. Verify `tick()` is called every frame with `get_process_delta_time()` or accumulated delta. 2. Verify `seed.is_planted` is `true`. 3. Add `print(delta)` inside `tick()` to confirm non-zero delta. |

### Issue 2: Phase Transition Not Emitting Signals

| Field       | Detail                                                                                          |
| ----------- | ----------------------------------------------------------------------------------------------- |
| **Symptom** | Seed phase changes but no `seed_phase_changed` signal is emitted on EventBus.                   |
| **Cause A** | EventBus autoload is not registered in project settings.                                        |
| **Cause B** | Signal name mismatch between SeedGrove emit and UI connect.                                     |
| **Cause C** | `advance_growth()` returns the *current* phase (no change), so tick() thinks no transition.     |
| **Solution** | 1. Verify EventBus is in Project → AutoLoad. 2. Check signal names match exactly. 3. Compare phase before and after `advance_growth()` call to detect transitions independently. |

### Issue 3: Mutation Roll Always Fails

| Field       | Detail                                                                                          |
| ----------- | ----------------------------------------------------------------------------------------------- |
| **Symptom** | Phase transitions occur but spontaneous mutations never happen, even on Legendary seeds.        |
| **Cause A** | `mutation_potential` is 0.0. Check seed creation — potential may not be set.                     |
| **Cause B** | RNG is seeded to a value that always produces > potential. Check RNG seed diversity.             |
| **Cause C** | Mutation roll comparison is `>=` instead of `<`. Roll should succeed when `rng.randf() < potential`. |
| **Solution** | 1. Verify `mutation_potential` is set in `create_seed()`. 2. Test with `mutation_potential = 1.0` to confirm roll can succeed. 3. Check comparison operator direction. |

### Issue 4: Offline Growth Gives Too Much Progress

| Field       | Detail                                                                                          |
| ----------- | ----------------------------------------------------------------------------------------------- |
| **Symptom** | Player closes game for 1 hour, returns to find all seeds bloomed (expected: only partial growth).|
| **Cause A** | Delta is not in seconds (could be milliseconds from a different time API).                       |
| **Cause B** | Growth rate calculation is inverted (dividing instead of multiplying by rarity modifier).        |
| **Cause C** | Max offline delta cap is not applied, and system clock delta was miscalculated.                  |
| **Solution** | 1. Verify delta units are seconds. 2. Check `growth_rate = base_seconds * rarity_multiplier` (multiply, not divide). 3. Clamp delta to `MAX_OFFLINE_DELTA_SECONDS` before passing to tick(). |

### Issue 5: apply_reagent() Returns False on Valid Seed

| Field       | Detail                                                                                          |
| ----------- | ----------------------------------------------------------------------------------------------- |
| **Symptom** | Player tries to apply reagent to a seed with empty slots but `apply_reagent()` returns false.   |
| **Cause A** | `seed_id` does not match any seed in the grove (typo, or seed was removed).                     |
| **Cause B** | `MutationSlot.is_empty()` is returning `false` because `reagent_id` is not an empty string (could be null). |
| **Cause C** | Seed is not in the grove's `seeds` array (created externally, never added with `add_seed()`).   |
| **Solution** | 1. Verify `seed_id` matches an existing seed via `get_seed_by_id()`. 2. Check MutationSlot initialization — `reagent_id` should default to `""`. 3. Ensure seed was added to grove before applying reagent. |

### Issue 6: Serialization Round-Trip Loses Seed Data

| Field       | Detail                                                                                          |
| ----------- | ----------------------------------------------------------------------------------------------- |
| **Symptom** | After save/load cycle, some seeds are missing or have incorrect state.                          |
| **Cause A** | `SeedData.to_dict()` does not include all fields (e.g., omits `mutation_slots`).                |
| **Cause B** | `SeedData.from_dict()` fails silently on malformed data and returns partial seed.               |
| **Cause C** | `deserialize()` clears the existing array before populating, but `from_dict()` returns null on error. |
| **Solution** | 1. Verify `to_dict()` serializes ALL SeedData fields. 2. Add null checks after `from_dict()` — skip null results with a warning. 3. Write a round-trip test that compares every field. |

### Issue 7: Planted Count Exceeds Max Slots

| Field       | Detail                                                                                          |
| ----------- | ----------------------------------------------------------------------------------------------- |
| **Symptom** | More seeds are planted than `max_grove_slots` allows.                                           |
| **Cause A** | `plant_seed()` check uses `>` instead of `>=` for slot comparison.                              |
| **Cause B** | `max_grove_slots` was decreased (e.g., via deserialize) below current planted count.            |
| **Cause C** | Race condition: two rapid plant calls before first one updates `planted_count`.                  |
| **Solution** | 1. Verify guard: `if planted_count >= max_grove_slots: return false`. 2. On deserialize, if planted > max, uproot excess seeds (oldest first). 3. Since Godot is single-threaded, race conditions are not possible — check logic order instead. |

---

## Section 13 · Acceptance Criteria

### 13.1 File Structure

- [ ] `src/managers/seed_grove.gd` exists and declares `class_name SeedGrove`
- [ ] `SeedGrove` extends `Node`
- [ ] `tests/managers/test_seed_grove.gd` exists and extends `GutTest`
- [ ] All files have `## @file` doc comment header with description

### 13.2 Properties

- [ ] `seeds: Array[SeedData]` property exists and initializes to empty array
- [ ] `max_grove_slots: int` property exists and defaults to 3
- [ ] `rng: DeterministicRNG` property exists and is settable (dependency injection)
- [ ] `planted_count` computed property returns count of planted seeds
- [ ] `planted_count` is always consistent with `get_planted_seeds().size()`

### 13.3 Planting

- [ ] `plant_seed(seed: SeedData) -> bool` method exists with correct signature
- [ ] `plant_seed()` returns `false` when grove is full (planted_count >= max_grove_slots)
- [ ] `plant_seed()` returns `false` when seed is already planted
- [ ] `plant_seed()` returns `false` when seed is not in the grove's seeds array
- [ ] `plant_seed()` sets `seed.is_planted = true` on success
- [ ] `plant_seed()` sets `seed.planted_at` to current time on success
- [ ] `plant_seed()` emits `EventBus.seed_planted(seed.id, slot_index)` on success
- [ ] `plant_seed()` returns `true` on success
- [ ] Planting increments `planted_count` by exactly 1

### 13.4 Uprooting

- [ ] `uproot_seed(seed_id: String) -> SeedData` method exists with correct signature
- [ ] `uproot_seed()` sets `seed.is_planted = false`
- [ ] `uproot_seed()` resets `seed.growth_progress = 0.0`
- [ ] `uproot_seed()` resets `seed.phase = Enums.SeedPhase.SPORE`
- [ ] `uproot_seed()` returns the uprooted SeedData on success
- [ ] `uproot_seed()` returns `null` when seed_id is not found
- [ ] `uproot_seed()` returns `null` when seed is not planted
- [ ] Uprooting decrements `planted_count` by exactly 1
- [ ] Uprooted seed remains in the grove's `seeds` array (not removed)

### 13.5 Growth Tick

- [ ] `tick(delta: float) -> Array[Dictionary]` method exists with correct signature
- [ ] `tick()` calls `advance_growth(delta)` on each planted seed
- [ ] `tick()` does NOT advance unplanted seeds
- [ ] `tick()` does NOT advance BLOOM seeds
- [ ] `tick()` detects phase transitions and emits `EventBus.seed_phase_changed`
- [ ] `tick()` performs mutation roll on phase transition using `rng.randf()`
- [ ] `tick()` emits `EventBus.seed_matured` when seed reaches BLOOM
- [ ] `tick()` returns array of event Dictionaries with keys: `seed_id`, `event`, `data`
- [ ] `tick()` handles delta of 0.0 gracefully (no events, no errors)
- [ ] `tick()` handles large delta (72 hours) correctly — seeds can transition multiple phases
- [ ] Each phase transition in a multi-phase tick produces its own event entry

### 13.6 Mutation and Reagents

- [ ] `apply_reagent(seed_id: String, reagent_id: String) -> bool` method exists
- [ ] `apply_reagent()` returns `false` when seed_id is not found
- [ ] `apply_reagent()` returns `false` when seed has no empty mutation slots
- [ ] `apply_reagent()` fills first empty MutationSlot on success
- [ ] `apply_reagent()` modifies `seed.dungeon_traits` according to reagent effect
- [ ] `apply_reagent()` returns `true` on success
- [ ] Spontaneous mutation uses `rng.randf() < seed.mutation_potential` check
- [ ] Failed spontaneous mutation produces no state changes

### 13.7 Query Methods

- [ ] `get_planted_seeds() -> Array[SeedData]` returns only planted seeds
- [ ] `get_unplanted_seeds() -> Array[SeedData]` returns only unplanted seeds
- [ ] `get_matured_seeds() -> Array[SeedData]` returns only BLOOM phase seeds
- [ ] `is_ready_for_expedition(seed_id: String) -> bool` returns true for SPROUT, BUD, BLOOM
- [ ] `is_ready_for_expedition()` returns false for SPORE
- [ ] `is_ready_for_expedition()` returns false for unknown seed_id
- [ ] `get_seed_by_id(seed_id: String) -> SeedData` returns correct seed or null
- [ ] `get_seed_count() -> int` returns total seeds (planted + unplanted)
- [ ] `get_available_slots() -> int` returns `max_grove_slots - planted_count`

### 13.8 Seed Factory

- [ ] `create_seed(rarity, element, rng) -> SeedData` returns valid SeedData
- [ ] Created seed has unique ID
- [ ] Created seed starts at SPORE phase with 0.0 growth_progress
- [ ] Created seed has correct growth_rate based on rarity
- [ ] Created seed has correct number of mutation slots based on rarity
- [ ] Created seed has default dungeon_traits
- [ ] Created seed is NOT automatically added to the grove

### 13.9 Inventory Management

- [ ] `add_seed(seed: SeedData) -> void` adds seed to the seeds array
- [ ] `remove_seed(seed_id: String) -> SeedData` removes and returns the seed
- [ ] `remove_seed()` returns null when seed_id is not found
- [ ] `remove_seed()` on a planted seed uproots it first before removing

### 13.10 Serialization

- [ ] `serialize() -> Dictionary` returns complete grove state
- [ ] `deserialize(data: Dictionary) -> void` restores complete grove state
- [ ] Round-trip serialize → deserialize produces identical state
- [ ] `deserialize()` handles missing optional keys with defaults
- [ ] `deserialize()` validates data bounds (phase range, growth_progress range, slot count)
- [ ] `deserialize()` rejects duplicate seed IDs

### 13.11 Code Quality (PAC — Programmatic Acceptance Criteria)

- [ ] All public methods have static type annotations on parameters and return values
- [ ] All public methods have `##` doc comments
- [ ] No calls to global `randf()`, `randi()`, or `RandomNumberGenerator` — only `DeterministicRNG`
- [ ] No hard-coded growth times — all values from GameConfig
- [ ] No direct UI or audio calls — communication only via EventBus signals
- [ ] Zero GDScript parser errors
- [ ] Zero GDScript warnings with `--strict` mode
- [ ] All tests pass with `gut` runner
- [ ] Test coverage: every public method has at least one test
- [ ] Test coverage: every error path (null, invalid, full) has a test

---

## Section 14 · Testing Requirements

### 14.1 Test File: `tests/managers/test_seed_grove.gd`

```gdscript
## @file tests/managers/test_seed_grove.gd
## @brief Comprehensive unit tests for SeedGrove manager.
## @task TASK-012
extends GutTest

var grove: SeedGrove
var rng: DeterministicRNG


func _make_seed(
	id: String = "seed-001",
	rarity: int = Enums.SeedRarity.COMMON,
	element: int = Enums.Element.TERRA,
	phase: int = Enums.SeedPhase.SPORE
) -> SeedData:
	var seed := SeedData.new()
	seed.id = id
	seed.rarity = rarity
	seed.element = element
	seed.phase = phase
	seed.growth_progress = 0.0
	seed.is_planted = false
	seed.planted_at = 0.0
	seed.mutation_potential = 0.1
	seed.growth_rate = GameConfig.BASE_GROWTH_SECONDS[Enums.SeedPhase.SPROUT] * GameConfig.RARITY_GROWTH_MULTIPLIER[rarity]
	seed.dungeon_traits = {
		"room_variety": 0.5,
		"hazard_frequency": 0.3,
		"loot_bias": "BALANCED",
		"corridor_complexity": 0.5,
		"secret_room_chance": 0.1,
		"elite_spawn_rate": 0.15,
	}
	var slot_count: int = GameConfig.MUTATION_SLOTS_BY_RARITY[rarity]
	seed.mutation_slots = []
	for i in range(slot_count):
		var slot := MutationSlot.new()
		slot.slot_index = i
		slot.reagent_id = ""
		slot.effect = {}
		seed.mutation_slots.append(slot)
	return seed


func before_each() -> void:
	grove = SeedGrove.new()
	rng = DeterministicRNG.new()
	rng.seed_int(42)
	grove.rng = rng
	add_child_autofree(grove)


# ─── Inventory Management ──────────────────────────────────────────────────

func test_add_seed_increases_count() -> void:
	var seed := _make_seed("seed-add-1")
	grove.add_seed(seed)
	assert_eq(grove.get_seed_count(), 1, "Grove should contain 1 seed after add")


func test_add_multiple_seeds() -> void:
	grove.add_seed(_make_seed("s1"))
	grove.add_seed(_make_seed("s2"))
	grove.add_seed(_make_seed("s3"))
	assert_eq(grove.get_seed_count(), 3, "Grove should contain 3 seeds")


func test_remove_seed_returns_seed() -> void:
	var seed := _make_seed("seed-rm-1")
	grove.add_seed(seed)
	var removed := grove.remove_seed("seed-rm-1")
	assert_not_null(removed, "remove_seed should return the removed seed")
	assert_eq(removed.id, "seed-rm-1", "Returned seed should have correct ID")
	assert_eq(grove.get_seed_count(), 0, "Grove should be empty after removal")


func test_remove_seed_not_found_returns_null() -> void:
	var result := grove.remove_seed("nonexistent")
	assert_null(result, "remove_seed should return null for unknown ID")


func test_remove_planted_seed_uproots_first() -> void:
	var seed := _make_seed("seed-rm-planted")
	grove.add_seed(seed)
	grove.plant_seed(seed)
	assert_true(seed.is_planted, "Seed should be planted before removal")
	var removed := grove.remove_seed("seed-rm-planted")
	assert_not_null(removed, "Should return the removed seed")
	assert_false(removed.is_planted, "Removed seed should be uprooted")
	assert_eq(removed.phase, Enums.SeedPhase.SPORE, "Removed seed should reset to SPORE")


func test_get_seed_by_id_found() -> void:
	var seed := _make_seed("lookup-1")
	grove.add_seed(seed)
	var found := grove.get_seed_by_id("lookup-1")
	assert_not_null(found, "Should find the seed")
	assert_eq(found.id, "lookup-1", "Should return correct seed")


func test_get_seed_by_id_not_found() -> void:
	var found := grove.get_seed_by_id("ghost")
	assert_null(found, "Should return null for unknown ID")


# ─── Planting ──────────────────────────────────────────────────────────────

func test_plant_seed_success() -> void:
	var seed := _make_seed("plant-ok")
	grove.add_seed(seed)
	var result := grove.plant_seed(seed)
	assert_true(result, "plant_seed should return true on success")
	assert_true(seed.is_planted, "Seed should be marked as planted")
	assert_eq(grove.planted_count, 1, "Planted count should be 1")


func test_plant_seed_sets_phase_to_spore() -> void:
	var seed := _make_seed("plant-phase")
	grove.add_seed(seed)
	grove.plant_seed(seed)
	assert_eq(seed.phase, Enums.SeedPhase.SPORE, "Planted seed should start at SPORE")


func test_plant_seed_full_grove_returns_false() -> void:
	for i in range(3):
		var seed := _make_seed("fill-%d" % i)
		grove.add_seed(seed)
		grove.plant_seed(seed)
	var overflow := _make_seed("overflow")
	grove.add_seed(overflow)
	var result := grove.plant_seed(overflow)
	assert_false(result, "plant_seed should return false when grove is full")
	assert_false(overflow.is_planted, "Overflow seed should not be planted")


func test_plant_already_planted_returns_false() -> void:
	var seed := _make_seed("double-plant")
	grove.add_seed(seed)
	grove.plant_seed(seed)
	var result := grove.plant_seed(seed)
	assert_false(result, "plant_seed should return false for already-planted seed")


func test_plant_foreign_seed_returns_false() -> void:
	var seed := _make_seed("foreign")
	var result := grove.plant_seed(seed)
	assert_false(result, "plant_seed should return false for seed not in grove")


func test_plant_seed_emits_signal() -> void:
	var seed := _make_seed("sig-plant")
	grove.add_seed(seed)
	watch_signals(EventBus)
	grove.plant_seed(seed)
	assert_signal_emitted(EventBus, "seed_planted", "Should emit seed_planted signal")


# ─── Uprooting ─────────────────────────────────────────────────────────────

func test_uproot_seed_success() -> void:
	var seed := _make_seed("uproot-ok")
	grove.add_seed(seed)
	grove.plant_seed(seed)
	seed.phase = Enums.SeedPhase.BUD
	seed.growth_progress = 0.7
	var uprooted := grove.uproot_seed("uproot-ok")
	assert_not_null(uprooted, "uproot_seed should return the seed")
	assert_false(uprooted.is_planted, "Uprooted seed should not be planted")
	assert_eq(uprooted.phase, Enums.SeedPhase.SPORE, "Uprooted seed resets to SPORE")
	assert_eq(uprooted.growth_progress, 0.0, "Uprooted seed resets growth to 0.0")


func test_uproot_seed_not_found() -> void:
	var result := grove.uproot_seed("ghost-id")
	assert_null(result, "uproot_seed should return null for unknown ID")


func test_uproot_unplanted_seed_returns_null() -> void:
	var seed := _make_seed("not-planted")
	grove.add_seed(seed)
	var result := grove.uproot_seed("not-planted")
	assert_null(result, "uproot_seed should return null for unplanted seed")


func test_uproot_decrements_planted_count() -> void:
	var seed := _make_seed("uproot-count")
	grove.add_seed(seed)
	grove.plant_seed(seed)
	assert_eq(grove.planted_count, 1, "Should have 1 planted seed")
	grove.uproot_seed("uproot-count")
	assert_eq(grove.planted_count, 0, "Should have 0 planted seeds after uproot")


func test_uproot_seed_remains_in_grove() -> void:
	var seed := _make_seed("uproot-stay")
	grove.add_seed(seed)
	grove.plant_seed(seed)
	grove.uproot_seed("uproot-stay")
	assert_eq(grove.get_seed_count(), 1, "Uprooted seed should remain in grove inventory")


# ─── Growth Tick ───────────────────────────────────────────────────────────

func test_tick_advances_planted_seeds() -> void:
	var seed := _make_seed("tick-grow")
	grove.add_seed(seed)
	grove.plant_seed(seed)
	grove.tick(60.0)
	assert_gt(seed.growth_progress, 0.0, "Planted seed should have growth after tick")


func test_tick_does_not_advance_unplanted() -> void:
	var seed := _make_seed("tick-no-grow")
	grove.add_seed(seed)
	grove.tick(60.0)
	assert_eq(seed.growth_progress, 0.0, "Unplanted seed should not grow")


func test_tick_does_not_advance_bloom() -> void:
	var seed := _make_seed("tick-bloom")
	seed.phase = Enums.SeedPhase.BLOOM
	seed.growth_progress = 1.0
	seed.is_planted = true
	grove.add_seed(seed)
	grove.tick(600.0)
	assert_eq(seed.phase, Enums.SeedPhase.BLOOM, "BLOOM seed should stay at BLOOM")


func test_tick_returns_phase_changed_event() -> void:
	var seed := _make_seed("tick-phase")
	seed.growth_rate = 10.0
	grove.add_seed(seed)
	grove.plant_seed(seed)
	var events: Array[Dictionary] = grove.tick(15.0)
	var phase_events := events.filter(func(e: Dictionary) -> bool: return e["event"] == "phase_changed")
	assert_gt(phase_events.size(), 0, "Should have at least one phase_changed event")


func test_tick_returns_bloom_reached_event() -> void:
	var seed := _make_seed("tick-bloom-event")
	seed.phase = Enums.SeedPhase.BUD
	seed.growth_progress = 0.99
	seed.growth_rate = 10.0
	seed.is_planted = true
	grove.add_seed(seed)
	var events: Array[Dictionary] = grove.tick(5.0)
	var bloom_events := events.filter(func(e: Dictionary) -> bool: return e["event"] == "bloom_reached")
	assert_gt(bloom_events.size(), 0, "Should have a bloom_reached event")


func test_tick_emits_seed_phase_changed_signal() -> void:
	var seed := _make_seed("tick-sig-phase")
	seed.growth_rate = 10.0
	grove.add_seed(seed)
	grove.plant_seed(seed)
	watch_signals(EventBus)
	grove.tick(15.0)
	assert_signal_emitted(EventBus, "seed_phase_changed", "Should emit seed_phase_changed")


func test_tick_emits_seed_matured_signal() -> void:
	var seed := _make_seed("tick-sig-mature")
	seed.phase = Enums.SeedPhase.BUD
	seed.growth_progress = 0.99
	seed.growth_rate = 10.0
	seed.is_planted = true
	grove.add_seed(seed)
	watch_signals(EventBus)
	grove.tick(5.0)
	assert_signal_emitted(EventBus, "seed_matured", "Should emit seed_matured")


func test_tick_large_delta_multi_phase() -> void:
	var seed := _make_seed("tick-mega")
	seed.growth_rate = 100.0
	grove.add_seed(seed)
	grove.plant_seed(seed)
	var events: Array[Dictionary] = grove.tick(500.0)
	assert_eq(seed.phase, Enums.SeedPhase.BLOOM, "Seed should reach BLOOM with large delta")
	var phase_events := events.filter(func(e: Dictionary) -> bool: return e["event"] == "phase_changed")
	assert_gte(phase_events.size(), 2, "Should have multiple phase_changed events")


func test_tick_zero_delta_no_events() -> void:
	var seed := _make_seed("tick-zero")
	grove.add_seed(seed)
	grove.plant_seed(seed)
	var events: Array[Dictionary] = grove.tick(0.0)
	assert_eq(events.size(), 0, "Zero delta should produce no events")


func test_tick_event_has_required_keys() -> void:
	var seed := _make_seed("tick-keys")
	seed.growth_rate = 10.0
	grove.add_seed(seed)
	grove.plant_seed(seed)
	var events: Array[Dictionary] = grove.tick(15.0)
	if events.size() > 0:
		var event: Dictionary = events[0]
		assert_true(event.has("seed_id"), "Event should have seed_id key")
		assert_true(event.has("event"), "Event should have event key")
		assert_true(event.has("data"), "Event should have data key")


# ─── Mutation / Reagent ────────────────────────────────────────────────────

func test_apply_reagent_success() -> void:
	var seed := _make_seed("reagent-ok")
	grove.add_seed(seed)
	var result := grove.apply_reagent("reagent-ok", "fire_reagent")
	assert_true(result, "apply_reagent should return true on success")
	assert_eq(seed.mutation_slots[0].reagent_id, "fire_reagent", "Slot should have reagent ID")


func test_apply_reagent_not_found() -> void:
	var result := grove.apply_reagent("ghost", "fire_reagent")
	assert_false(result, "apply_reagent should return false for unknown seed ID")


func test_apply_reagent_no_empty_slots() -> void:
	var seed := _make_seed("reagent-full", Enums.SeedRarity.COMMON)
	grove.add_seed(seed)
	grove.apply_reagent("reagent-full", "reagent_a")
	var result := grove.apply_reagent("reagent-full", "reagent_b")
	assert_false(result, "apply_reagent should return false when all slots full")


func test_apply_reagent_modifies_dungeon_traits() -> void:
	var seed := _make_seed("reagent-trait")
	grove.add_seed(seed)
	var original_hazard: float = seed.dungeon_traits["hazard_frequency"]
	grove.apply_reagent("reagent-trait", "fire_reagent")
	var new_hazard: float = seed.dungeon_traits["hazard_frequency"]
	assert_ne(new_hazard, original_hazard, "Reagent should modify dungeon_traits")


func test_spontaneous_mutation_on_phase_change() -> void:
	var seed := _make_seed("mutate-spont")
	seed.mutation_potential = 1.0
	seed.growth_rate = 10.0
	grove.add_seed(seed)
	grove.plant_seed(seed)
	var events: Array[Dictionary] = grove.tick(15.0)
	var mutated_events := events.filter(func(e: Dictionary) -> bool: return e["event"] == "mutated")
	assert_gt(mutated_events.size(), 0, "Should have mutation event with potential 1.0")


func test_no_mutation_with_zero_potential() -> void:
	var seed := _make_seed("no-mutate")
	seed.mutation_potential = 0.0
	seed.growth_rate = 10.0
	grove.add_seed(seed)
	grove.plant_seed(seed)
	var events: Array[Dictionary] = grove.tick(15.0)
	var mutated_events := events.filter(func(e: Dictionary) -> bool: return e["event"] == "mutated")
	assert_eq(mutated_events.size(), 0, "Should have no mutation events with potential 0.0")


# ─── Query Methods ─────────────────────────────────────────────────────────

func test_get_planted_seeds() -> void:
	var s1 := _make_seed("planted-1")
	var s2 := _make_seed("planted-2")
	var s3 := _make_seed("unplanted-1")
	grove.add_seed(s1)
	grove.add_seed(s2)
	grove.add_seed(s3)
	grove.plant_seed(s1)
	grove.plant_seed(s2)
	var planted := grove.get_planted_seeds()
	assert_eq(planted.size(), 2, "Should return 2 planted seeds")


func test_get_unplanted_seeds() -> void:
	var s1 := _make_seed("p-1")
	var s2 := _make_seed("up-1")
	grove.add_seed(s1)
	grove.add_seed(s2)
	grove.plant_seed(s1)
	var unplanted := grove.get_unplanted_seeds()
	assert_eq(unplanted.size(), 1, "Should return 1 unplanted seed")
	assert_eq(unplanted[0].id, "up-1", "Unplanted seed should be up-1")


func test_get_matured_seeds() -> void:
	var s1 := _make_seed("bloom-1")
	s1.phase = Enums.SeedPhase.BLOOM
	var s2 := _make_seed("bud-1")
	s2.phase = Enums.SeedPhase.BUD
	grove.add_seed(s1)
	grove.add_seed(s2)
	var matured := grove.get_matured_seeds()
	assert_eq(matured.size(), 1, "Should return 1 matured seed")
	assert_eq(matured[0].id, "bloom-1", "Matured seed should be bloom-1")


func test_is_ready_for_expedition_sprout() -> void:
	var seed := _make_seed("exped-sprout")
	seed.phase = Enums.SeedPhase.SPROUT
	grove.add_seed(seed)
	assert_true(grove.is_ready_for_expedition("exped-sprout"), "SPROUT should be expedition-ready")


func test_is_ready_for_expedition_bud() -> void:
	var seed := _make_seed("exped-bud")
	seed.phase = Enums.SeedPhase.BUD
	grove.add_seed(seed)
	assert_true(grove.is_ready_for_expedition("exped-bud"), "BUD should be expedition-ready")


func test_is_ready_for_expedition_bloom() -> void:
	var seed := _make_seed("exped-bloom")
	seed.phase = Enums.SeedPhase.BLOOM
	grove.add_seed(seed)
	assert_true(grove.is_ready_for_expedition("exped-bloom"), "BLOOM should be expedition-ready")


func test_is_ready_for_expedition_spore() -> void:
	var seed := _make_seed("exped-spore")
	seed.phase = Enums.SeedPhase.SPORE
	grove.add_seed(seed)
	assert_false(grove.is_ready_for_expedition("exped-spore"), "SPORE should NOT be expedition-ready")


func test_is_ready_for_expedition_unknown_id() -> void:
	assert_false(grove.is_ready_for_expedition("ghost"), "Unknown ID should return false")


func test_get_available_slots() -> void:
	assert_eq(grove.get_available_slots(), 3, "Should have 3 available slots initially")
	var seed := _make_seed("slot-1")
	grove.add_seed(seed)
	grove.plant_seed(seed)
	assert_eq(grove.get_available_slots(), 2, "Should have 2 available slots after planting 1")


# ─── Seed Factory ──────────────────────────────────────────────────────────

func test_create_seed_returns_valid_seed() -> void:
	var seed := grove.create_seed(Enums.SeedRarity.RARE, Enums.Element.FLAME, rng)
	assert_not_null(seed, "create_seed should return a SeedData instance")
	assert_ne(seed.id, "", "Created seed should have non-empty ID")
	assert_eq(seed.rarity, Enums.SeedRarity.RARE, "Rarity should match")
	assert_eq(seed.element, Enums.Element.FLAME, "Element should match")
	assert_eq(seed.phase, Enums.SeedPhase.SPORE, "Should start at SPORE")
	assert_eq(seed.growth_progress, 0.0, "Should start at 0 progress")


func test_create_seed_unique_ids() -> void:
	var s1 := grove.create_seed(Enums.SeedRarity.COMMON, Enums.Element.TERRA, rng)
	var s2 := grove.create_seed(Enums.SeedRarity.COMMON, Enums.Element.TERRA, rng)
	assert_ne(s1.id, s2.id, "Each created seed should have a unique ID")


func test_create_seed_correct_slot_count() -> void:
	var common := grove.create_seed(Enums.SeedRarity.COMMON, Enums.Element.TERRA, rng)
	assert_eq(common.mutation_slots.size(), 1, "Common should have 1 mutation slot")
	var rare := grove.create_seed(Enums.SeedRarity.RARE, Enums.Element.FROST, rng)
	assert_eq(rare.mutation_slots.size(), 2, "Rare should have 2 mutation slots")
	var legend := grove.create_seed(Enums.SeedRarity.LEGENDARY, Enums.Element.SHADOW, rng)
	assert_eq(legend.mutation_slots.size(), 3, "Legendary should have 3 mutation slots")


func test_create_seed_not_auto_added() -> void:
	grove.create_seed(Enums.SeedRarity.COMMON, Enums.Element.TERRA, rng)
	assert_eq(grove.get_seed_count(), 0, "Created seed should not auto-add to grove")


func test_create_seed_growth_rate_by_rarity() -> void:
	var common := grove.create_seed(Enums.SeedRarity.COMMON, Enums.Element.TERRA, rng)
	var legend := grove.create_seed(Enums.SeedRarity.LEGENDARY, Enums.Element.TERRA, rng)
	assert_lt(legend.growth_rate, common.growth_rate, "Legendary should grow faster than Common")


# ─── Serialization ─────────────────────────────────────────────────────────

func test_serialize_returns_dictionary() -> void:
	var data := grove.serialize()
	assert_typeof(data, TYPE_DICTIONARY, "serialize() should return Dictionary")
	assert_true(data.has("seeds"), "Serialized data should have 'seeds' key")
	assert_true(data.has("max_grove_slots"), "Serialized data should have 'max_grove_slots' key")


func test_serialize_deserialize_round_trip() -> void:
	var s1 := _make_seed("rt-1", Enums.SeedRarity.RARE, Enums.Element.FROST)
	var s2 := _make_seed("rt-2", Enums.SeedRarity.EPIC, Enums.Element.ARCANE)
	grove.add_seed(s1)
	grove.add_seed(s2)
	grove.plant_seed(s1)

	var data := grove.serialize()
	var grove2 := SeedGrove.new()
	grove2.rng = DeterministicRNG.new()
	add_child_autofree(grove2)
	grove2.deserialize(data)

	assert_eq(grove2.get_seed_count(), 2, "Restored grove should have 2 seeds")
	assert_eq(grove2.planted_count, 1, "Restored grove should have 1 planted seed")
	assert_eq(grove2.max_grove_slots, grove.max_grove_slots, "Slots should match")

	var restored_s1 := grove2.get_seed_by_id("rt-1")
	assert_not_null(restored_s1, "Should find seed rt-1 after restore")
	assert_eq(restored_s1.rarity, Enums.SeedRarity.RARE, "Rarity should be preserved")
	assert_true(restored_s1.is_planted, "Planted state should be preserved")


func test_deserialize_handles_missing_keys() -> void:
	var data := {"seeds": [], "max_grove_slots": 5}
	grove.deserialize(data)
	assert_eq(grove.max_grove_slots, 5, "Should accept max_grove_slots from data")
	assert_eq(grove.get_seed_count(), 0, "Should have no seeds")


func test_deserialize_rejects_duplicate_ids() -> void:
	var seed_dict := _make_seed("dup-1").to_dict()
	var data := {
		"seeds": [seed_dict, seed_dict],
		"max_grove_slots": 3,
	}
	grove.deserialize(data)
	assert_eq(grove.get_seed_count(), 1, "Should reject duplicate seed IDs and keep only first")


func test_deserialize_validates_phase_range() -> void:
	var seed_dict := _make_seed("bad-phase").to_dict()
	seed_dict["phase"] = 99
	var data := {"seeds": [seed_dict], "max_grove_slots": 3}
	grove.deserialize(data)
	var seed := grove.get_seed_by_id("bad-phase")
	if seed:
		assert_true(
			seed.phase >= Enums.SeedPhase.SPORE and seed.phase <= Enums.SeedPhase.BLOOM,
			"Invalid phase should be clamped to valid range"
		)


func test_deserialize_clamps_grove_slots() -> void:
	var data := {"seeds": [], "max_grove_slots": 9999}
	grove.deserialize(data)
	assert_lte(grove.max_grove_slots, 20, "Grove slots should be clamped to max allowed")
```

---

## Section 15 · Playtesting Verification

### PV-01 · Fresh Start — First Seed Plant

| Field           | Detail                                                                          |
| --------------- | ------------------------------------------------------------------------------- |
| **Scenario**    | New player receives first seed and plants it.                                   |
| **Setup**       | Empty grove, 1 Common TERRA seed in inventory.                                  |
| **Steps**       | 1. Call `add_seed(seed)`. 2. Call `plant_seed(seed)`. 3. Call `tick(1.0)`.      |
| **Expected**    | Seed is planted, `planted_count == 1`, seed grows, no errors.                   |
| **Pass Signal** | `EventBus.seed_planted` emitted with correct seed_id.                           |

### PV-02 · Full Grove — Slot Management

| Field           | Detail                                                                          |
| --------------- | ------------------------------------------------------------------------------- |
| **Scenario**    | Player tries to plant when all 3 slots are occupied.                            |
| **Setup**       | 3 planted seeds, 1 unplanted seed.                                              |
| **Steps**       | 1. Attempt `plant_seed()` with 4th seed. 2. Uproot 1 seed. 3. Plant 4th seed.  |
| **Expected**    | Step 1 returns false. Steps 2-3 succeed. Final planted count == 3.              |
| **Pass Signal** | No crash, no slot overflow.                                                     |

### PV-03 · Phase Progression — Spore to Bloom

| Field           | Detail                                                                          |
| --------------- | ------------------------------------------------------------------------------- |
| **Scenario**    | Observe a seed growing through all 4 phases.                                    |
| **Setup**       | 1 Common TERRA seed planted at SPORE.                                           |
| **Steps**       | Call `tick()` with increasing deltas until BLOOM.                               |
| **Expected**    | Phase transitions: SPORE→SPROUT (600s), SPROUT→BUD (1800s), BUD→BLOOM (3600s). |
| **Pass Signal** | 3 `seed_phase_changed` signals + 1 `seed_matured` signal.                      |

### PV-04 · Offline Growth — 8-Hour Absence

| Field           | Detail                                                                          |
| --------------- | ------------------------------------------------------------------------------- |
| **Scenario**    | Player returns after 8 hours (28800 seconds).                                   |
| **Setup**       | 2 Common seeds planted at SPORE, 1 Rare seed planted at SPROUT.                |
| **Steps**       | Call `tick(28800.0)`.                                                            |
| **Expected**    | All 3 seeds should be at BLOOM. Events array contains all transitions.          |
| **Pass Signal** | 3 `seed_matured` signals. No skipped phases in events.                          |

### PV-05 · Reagent Application — Mutation Slot Fill

| Field           | Detail                                                                          |
| --------------- | ------------------------------------------------------------------------------- |
| **Scenario**    | Player applies reagents to a Rare seed (2 slots).                               |
| **Setup**       | 1 Rare FLAME seed in grove (not planted required).                              |
| **Steps**       | 1. `apply_reagent(id, "fire_reagent")`. 2. `apply_reagent(id, "ice_reagent")`. 3. `apply_reagent(id, "third_reagent")`. |
| **Expected**    | Steps 1-2 return true. Step 3 returns false (no empty slots). Traits modified.  |
| **Pass Signal** | `dungeon_traits` reflects both reagent effects.                                 |

### PV-06 · Uproot Penalty — Progress Loss

| Field           | Detail                                                                          |
| --------------- | ------------------------------------------------------------------------------- |
| **Scenario**    | Player uproots a seed that was halfway through BUD phase.                       |
| **Setup**       | 1 seed at BUD phase with 50% growth_progress.                                  |
| **Steps**       | Call `uproot_seed(id)`.                                                         |
| **Expected**    | Seed returns to SPORE, growth_progress = 0.0. Seed remains in grove inventory. |
| **Pass Signal** | No signals emitted for uproot (uproot is silent).                               |

### PV-07 · Rarity Growth Speed — Legendary vs Common

| Field           | Detail                                                                          |
| --------------- | ------------------------------------------------------------------------------- |
| **Scenario**    | Compare growth speed of Common (1.0×) vs Legendary (0.6×) seeds.               |
| **Setup**       | 1 Common seed, 1 Legendary seed, both planted at SPORE.                         |
| **Steps**       | Call `tick(3600.0)` (1 hour).                                                   |
| **Expected**    | Legendary seed is further along (more phases completed) than Common.            |
| **Pass Signal** | Legendary bloom time total < Common bloom time total.                           |

### PV-08 · Serialization Round-Trip — Full State Preservation

| Field           | Detail                                                                          |
| --------------- | ------------------------------------------------------------------------------- |
| **Scenario**    | Save and load grove state with mixed seed states.                               |
| **Setup**       | 3 planted seeds (SPORE, BUD, BLOOM), 2 unplanted, 1 with reagents applied.     |
| **Steps**       | 1. `serialize()`. 2. Create new grove. 3. `deserialize(data)`. 4. Compare.     |
| **Expected**    | All seeds, phases, growth, mutations, and slot assignments preserved exactly.   |
| **Pass Signal** | `grove1.serialize()` deep-equals `grove2.serialize()` after round-trip.         |

### PV-09 · Mutation Roll — Deterministic Outcome

| Field           | Detail                                                                          |
| --------------- | ------------------------------------------------------------------------------- |
| **Scenario**    | Verify mutation rolls are deterministic given same RNG seed.                    |
| **Setup**       | 2 identical groves with same RNG seed (42), same seed planted.                  |
| **Steps**       | Tick both groves identically. Compare mutation outcomes.                        |
| **Expected**    | Both groves produce identical mutation results.                                 |
| **Pass Signal** | Seed dungeon_traits match exactly between both groves.                          |

### PV-10 · Edge Case — Empty Grove Operations

| Field           | Detail                                                                          |
| --------------- | ------------------------------------------------------------------------------- |
| **Scenario**    | Call all methods on an empty grove.                                             |
| **Setup**       | Fresh SeedGrove with no seeds.                                                  |
| **Steps**       | Call every public method with valid-but-empty parameters.                       |
| **Expected**    | No crashes, no errors. Methods return empty arrays, null, false, 0 as appropriate. |
| **Pass Signal** | Zero exceptions, all return values are type-correct.                            |

---

## Section 16 · Implementation Prompt

### 16.1 Primary File: `src/managers/seed_grove.gd`

```gdscript
## @file src/managers/seed_grove.gd
## @brief Seed Grove Manager — owns all seeds, advances growth, handles mutations.
## @task TASK-012
## @deps TASK-002 (DeterministicRNG), TASK-004 (SeedData, MutationSlot), TASK-003 (Enums, GameConfig)
class_name SeedGrove
extends Node

## Maximum number of simultaneously planted seeds. Starts at 3, expandable via upgrades.
@export var max_grove_slots: int = 3

## All seeds in the grove (planted and unplanted).
var seeds: Array[SeedData] = []

## Deterministic RNG instance for mutation rolls. Must be injected before use.
var rng: DeterministicRNG = null

## Maximum allowed grove slots (anti-cheat clamp ceiling).
const MAX_ALLOWED_GROVE_SLOTS: int = 20

## Maximum offline delta in seconds (72 hours).
const MAX_OFFLINE_DELTA_SECONDS: float = 259200.0

## Reagent effect definitions — maps reagent_id to trait modifier dictionaries.
## In production, this would be loaded from a config resource. Here as a reference default.
const REAGENT_EFFECTS: Dictionary = {
	"fire_reagent": {
		"hazard_frequency": 0.15,
		"loot_bias": "ESSENCE",
		"elite_spawn_rate": 0.05,
	},
	"ice_reagent": {
		"hazard_frequency": -0.10,
		"corridor_complexity": 0.20,
		"secret_room_chance": 0.05,
	},
	"nature_reagent": {
		"room_variety": 0.20,
		"loot_bias": "BALANCED",
		"secret_room_chance": 0.10,
	},
	"shadow_reagent": {
		"hazard_frequency": 0.20,
		"elite_spawn_rate": 0.10,
		"loot_bias": "GEAR",
	},
	"arcane_reagent": {
		"corridor_complexity": 0.15,
		"room_variety": 0.15,
		"secret_room_chance": 0.08,
	},
}

## Mutation potential base values by rarity.
const MUTATION_POTENTIAL_BY_RARITY: Dictionary = {
	Enums.SeedRarity.COMMON: 0.05,
	Enums.SeedRarity.UNCOMMON: 0.10,
	Enums.SeedRarity.RARE: 0.20,
	Enums.SeedRarity.EPIC: 0.35,
	Enums.SeedRarity.LEGENDARY: 0.50,
}

## Keys available in dungeon_traits for spontaneous mutation targeting.
const MUTABLE_TRAIT_KEYS: Array[String] = [
	"room_variety",
	"hazard_frequency",
	"corridor_complexity",
	"secret_room_chance",
	"elite_spawn_rate",
]

## Default dungeon traits for newly created seeds.
const DEFAULT_DUNGEON_TRAITS: Dictionary = {
	"room_variety": 0.5,
	"hazard_frequency": 0.3,
	"loot_bias": "BALANCED",
	"corridor_complexity": 0.5,
	"secret_room_chance": 0.1,
	"elite_spawn_rate": 0.15,
}


# ─── Computed Properties ───────────────────────────────────────────────────

## Returns the number of currently planted seeds.
var planted_count: int:
	get:
		var count: int = 0
		for seed in seeds:
			if seed.is_planted:
				count += 1
		return count


# ─── Lifecycle Methods ─────────────────────────────────────────────────────

## Plants a seed into an available grove slot.
## Returns true on success, false if grove is full, seed is already planted,
## or seed is not in the grove.
func plant_seed(seed: SeedData) -> bool:
	if seed == null:
		return false
	if seed.is_planted:
		return false
	if planted_count >= max_grove_slots:
		return false
	if not seeds.has(seed):
		return false

	seed.is_planted = true
	seed.planted_at = Time.get_unix_time_from_system()
	if seed.phase == Enums.SeedPhase.SPORE:
		seed.growth_progress = 0.0

	var slot_index: int = _get_planted_slot_index(seed)
	EventBus.seed_planted.emit(seed.id, slot_index)
	return true


## Uproots a planted seed, resetting its growth progress.
## Returns the uprooted SeedData, or null if not found or not planted.
func uproot_seed(seed_id: String) -> SeedData:
	if seed_id.is_empty():
		return null

	var seed := get_seed_by_id(seed_id)
	if seed == null:
		return null
	if not seed.is_planted:
		return null

	seed.is_planted = false
	seed.phase = Enums.SeedPhase.SPORE
	seed.growth_progress = 0.0
	seed.planted_at = 0.0
	return seed


## Advances all planted seeds by delta seconds.
## Returns an array of event dictionaries describing what happened.
## Each event has keys: "seed_id" (String), "event" (String), "data" (Dictionary).
func tick(delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []

	if delta <= 0.0:
		return events

	var clamped_delta: float = minf(delta, MAX_OFFLINE_DELTA_SECONDS)

	for seed in seeds:
		if not seed.is_planted:
			continue
		if seed.phase == Enums.SeedPhase.BLOOM:
			continue

		var phase_before: int = seed.phase
		var remaining_delta: float = clamped_delta

		while remaining_delta > 0.0 and seed.phase != Enums.SeedPhase.BLOOM:
			var current_phase_before: int = seed.phase
			var new_phase: int = seed.advance_growth(remaining_delta)

			if new_phase != current_phase_before:
				# Phase transition occurred
				var time_to_transition: float = _estimate_time_for_transition(seed, current_phase_before)
				remaining_delta -= maxf(time_to_transition, 0.0)

				# Emit phase changed event
				events.append({
					"seed_id": seed.id,
					"event": "phase_changed",
					"data": {
						"old_phase": current_phase_before,
						"new_phase": new_phase,
					},
				})
				EventBus.seed_phase_changed.emit(seed.id, new_phase)

				# Mutation roll on phase transition
				var mutation_event := _try_spontaneous_mutation(seed)
				if mutation_event.size() > 0:
					events.append(mutation_event)

				# Check for bloom
				if new_phase == Enums.SeedPhase.BLOOM:
					var slot_index: int = _get_planted_slot_index(seed)
					events.append({
						"seed_id": seed.id,
						"event": "bloom_reached",
						"data": {
							"slot_index": slot_index,
						},
					})
					EventBus.seed_matured.emit(seed.id, slot_index)
					break
			else:
				# No phase change — all remaining delta consumed within current phase
				break

	return events


## Applies a reagent to the first empty mutation slot on a seed.
## Returns true on success, false if seed not found or no empty slots.
func apply_reagent(seed_id: String, reagent_id: String) -> bool:
	if seed_id.is_empty() or reagent_id.is_empty():
		return false

	var seed := get_seed_by_id(seed_id)
	if seed == null:
		return false

	# Find the first empty mutation slot
	var target_slot: MutationSlot = null
	for slot in seed.mutation_slots:
		if slot.is_empty():
			target_slot = slot
			break

	if target_slot == null:
		return false

	# Resolve reagent effect
	var effect: Dictionary = _get_reagent_effect(reagent_id)

	# Apply reagent to slot
	target_slot.apply_reagent(reagent_id, effect)

	# Modify dungeon traits
	_apply_trait_modifiers(seed, effect)

	return true


# ─── Query Methods ─────────────────────────────────────────────────────────

## Returns all currently planted seeds.
func get_planted_seeds() -> Array[SeedData]:
	var result: Array[SeedData] = []
	for seed in seeds:
		if seed.is_planted:
			result.append(seed)
	return result


## Returns all seeds not currently planted.
func get_unplanted_seeds() -> Array[SeedData]:
	var result: Array[SeedData] = []
	for seed in seeds:
		if not seed.is_planted:
			result.append(seed)
	return result


## Returns all seeds in BLOOM phase (ready for dungeon generation).
func get_matured_seeds() -> Array[SeedData]:
	var result: Array[SeedData] = []
	for seed in seeds:
		if seed.phase == Enums.SeedPhase.BLOOM:
			result.append(seed)
	return result


## Returns true if the seed is at least SPROUT phase (expedition-ready).
## Returns false for SPORE phase, unknown seed_id, or null.
func is_ready_for_expedition(seed_id: String) -> bool:
	if seed_id.is_empty():
		return false
	var seed := get_seed_by_id(seed_id)
	if seed == null:
		return false
	return seed.phase >= Enums.SeedPhase.SPROUT


## Looks up a seed by its unique ID.
## Returns the SeedData or null if not found.
func get_seed_by_id(seed_id: String) -> SeedData:
	for seed in seeds:
		if seed.id == seed_id:
			return seed
	return null


## Returns the total number of seeds in the grove (planted + unplanted).
func get_seed_count() -> int:
	return seeds.size()


## Returns the number of available planting slots.
func get_available_slots() -> int:
	return max_grove_slots - planted_count


# ─── Factory Methods ───────────────────────────────────────────────────────

## Creates a new SeedData with random traits based on rarity and element.
## Does NOT add the seed to the grove — caller must use add_seed().
func create_seed(
	rarity: Enums.SeedRarity,
	element: Enums.Element,
	seed_rng: DeterministicRNG
) -> SeedData:
	var seed := SeedData.new()

	# Generate unique ID from RNG
	seed.id = "seed-%d-%d" % [seed_rng.randi(999999), seed_rng.randi(999999)]

	seed.rarity = rarity
	seed.element = element
	seed.phase = Enums.SeedPhase.SPORE
	seed.growth_progress = 0.0
	seed.is_planted = false
	seed.planted_at = 0.0

	# Calculate growth rate from config
	var base_time: float = GameConfig.BASE_GROWTH_SECONDS[Enums.SeedPhase.SPROUT]
	var rarity_mult: float = GameConfig.RARITY_GROWTH_MULTIPLIER[rarity]
	seed.growth_rate = base_time * rarity_mult

	# Set mutation potential by rarity
	seed.mutation_potential = MUTATION_POTENTIAL_BY_RARITY.get(rarity, 0.05)

	# Create mutation slots per rarity
	var slot_count: int = GameConfig.MUTATION_SLOTS_BY_RARITY.get(rarity, 1)
	seed.mutation_slots = []
	for i in range(slot_count):
		var slot := MutationSlot.new()
		slot.slot_index = i
		slot.reagent_id = ""
		slot.effect = {}
		seed.mutation_slots.append(slot)

	# Initialize default dungeon traits with slight element-based variation
	seed.dungeon_traits = DEFAULT_DUNGEON_TRAITS.duplicate()
	_apply_element_bias(seed, element, seed_rng)

	return seed


## Adds a seed to the grove inventory. Does not plant it.
func add_seed(seed: SeedData) -> void:
	if seed == null:
		return
	if get_seed_by_id(seed.id) != null:
		return
	seeds.append(seed)


## Removes a seed from the grove entirely.
## If the seed is planted, it is uprooted first (progress lost).
## Returns the removed SeedData, or null if not found.
func remove_seed(seed_id: String) -> SeedData:
	if seed_id.is_empty():
		return null

	var seed := get_seed_by_id(seed_id)
	if seed == null:
		return null

	# Uproot if planted
	if seed.is_planted:
		seed.is_planted = false
		seed.phase = Enums.SeedPhase.SPORE
		seed.growth_progress = 0.0
		seed.planted_at = 0.0

	seeds.erase(seed)
	return seed


# ─── Serialization ─────────────────────────────────────────────────────────

## Serializes the entire grove state to a Dictionary for save/load.
func serialize() -> Dictionary:
	var seed_dicts: Array[Dictionary] = []
	for seed in seeds:
		seed_dicts.append(seed.to_dict())

	return {
		"max_grove_slots": max_grove_slots,
		"seeds": seed_dicts,
		"version": 1,
	}


## Restores grove state from a serialized Dictionary.
## Validates data bounds and rejects invalid entries.
func deserialize(data: Dictionary) -> void:
	if data == null:
		return

	# Restore max_grove_slots with clamp
	var raw_slots: int = data.get("max_grove_slots", 3)
	max_grove_slots = clampi(raw_slots, 1, MAX_ALLOWED_GROVE_SLOTS)

	# Restore seeds
	seeds.clear()
	var seen_ids: Dictionary = {}
	var seed_dicts: Array = data.get("seeds", [])

	for seed_dict in seed_dicts:
		if not seed_dict is Dictionary:
			continue

		var seed_id: String = seed_dict.get("id", "")
		if seed_id.is_empty():
			continue

		# Reject duplicate IDs
		if seen_ids.has(seed_id):
			push_warning("SeedGrove.deserialize: Duplicate seed ID '%s' — skipping." % seed_id)
			continue
		seen_ids[seed_id] = true

		var seed := SeedData.from_dict(seed_dict)
		if seed == null:
			push_warning("SeedGrove.deserialize: Failed to parse seed '%s' — skipping." % seed_id)
			continue

		# Validate phase range
		if seed.phase < Enums.SeedPhase.SPORE or seed.phase > Enums.SeedPhase.BLOOM:
			seed.phase = Enums.SeedPhase.SPORE
			seed.growth_progress = 0.0

		# Validate growth_progress range
		seed.growth_progress = clampf(seed.growth_progress, 0.0, 1.0)

		# Validate mutation_potential range
		seed.mutation_potential = clampf(seed.mutation_potential, 0.0, 0.6)

		# Validate planted_at is not in the future
		var now: float = Time.get_unix_time_from_system()
		if seed.planted_at > now:
			seed.planted_at = now

		# Validate growth_rate against rarity minimum
		var expected_min_rate: float = _get_minimum_growth_rate(seed.rarity)
		if seed.growth_rate < expected_min_rate:
			seed.growth_rate = expected_min_rate

		seeds.append(seed)

	# Validate planted count does not exceed max_grove_slots
	var current_planted: int = planted_count
	if current_planted > max_grove_slots:
		push_warning("SeedGrove.deserialize: %d planted seeds exceed %d slots. Uprooting excess." % [current_planted, max_grove_slots])
		var planted := get_planted_seeds()
		# Sort by planted_at ascending (oldest first) — uproot oldest
		planted.sort_custom(func(a: SeedData, b: SeedData) -> bool: return a.planted_at < b.planted_at)
		var excess: int = current_planted - max_grove_slots
		for i in range(excess):
			var excess_seed: SeedData = planted[i]
			excess_seed.is_planted = false
			excess_seed.phase = Enums.SeedPhase.SPORE
			excess_seed.growth_progress = 0.0
			excess_seed.planted_at = 0.0


# ─── Debug Methods (debug builds only) ────────────────────────────────────

## Force a seed to a specific phase (debug only).
func debug_set_phase(seed_id: String, phase: Enums.SeedPhase) -> void:
	if not OS.is_debug_build():
		return
	var seed := get_seed_by_id(seed_id)
	if seed:
		seed.phase = phase
		seed.growth_progress = 0.0


## Force-bloom all planted seeds instantly (debug only).
func debug_bloom_all() -> void:
	if not OS.is_debug_build():
		return
	for seed in get_planted_seeds():
		seed.phase = Enums.SeedPhase.BLOOM
		seed.growth_progress = 1.0


## Print grove state to console (debug only).
func debug_print_state() -> void:
	if not OS.is_debug_build():
		return
	print("=== SeedGrove State ===")
	print("Total seeds: %d | Planted: %d / %d" % [seeds.size(), planted_count, max_grove_slots])
	for seed in seeds:
		var status: String = "PLANTED" if seed.is_planted else "inventory"
		print("  [%s] %s %s | Phase: %s | Progress: %.2f | %s" % [
			seed.id.left(8),
			Enums.SeedRarity.keys()[seed.rarity],
			Enums.Element.keys()[seed.element],
			Enums.SeedPhase.keys()[seed.phase],
			seed.growth_progress,
			status,
		])


## Advance time by N seconds for a specific seed (debug only).
func debug_advance_seed(seed_id: String, seconds: float) -> void:
	if not OS.is_debug_build():
		return
	var seed := get_seed_by_id(seed_id)
	if seed and seed.is_planted:
		seed.advance_growth(seconds)


# ─── Private Helpers ───────────────────────────────────────────────────────

## Returns the slot index for a planted seed (position among planted seeds).
func _get_planted_slot_index(target: SeedData) -> int:
	var index: int = 0
	for seed in seeds:
		if seed == target:
			return index
		if seed.is_planted:
			index += 1
	return index


## Attempts a spontaneous mutation roll on a seed.
## Returns an event Dictionary if mutation occurred, or empty Dictionary if not.
func _try_spontaneous_mutation(seed: SeedData) -> Dictionary:
	if rng == null:
		return {}
	if seed.mutation_potential <= 0.0:
		return {}

	var roll: float = rng.randf()
	if roll >= seed.mutation_potential:
		return {}

	# Mutation succeeded — pick a random trait to modify
	var trait_key: String = MUTABLE_TRAIT_KEYS[rng.randi(MUTABLE_TRAIT_KEYS.size())]
	var modifier: float = (rng.randf() * 0.2) - 0.05

	if seed.dungeon_traits.has(trait_key):
		var current_value: float = seed.dungeon_traits[trait_key]
		if current_value is float:
			seed.dungeon_traits[trait_key] = clampf(current_value + modifier, 0.0, 1.0)

	return {
		"seed_id": seed.id,
		"event": "mutated",
		"data": {
			"trait_key": trait_key,
			"modifier": modifier,
			"source": "spontaneous",
		},
	}


## Estimates the time needed for a seed to transition from its current phase.
## Used for large-delta multi-phase tick calculation.
func _estimate_time_for_transition(seed: SeedData, from_phase: int) -> float:
	var remaining_progress: float = 1.0 - seed.growth_progress
	var rarity_mult: float = GameConfig.RARITY_GROWTH_MULTIPLIER.get(seed.rarity, 1.0)
	var next_phase: int = from_phase + 1
	if next_phase > Enums.SeedPhase.BLOOM:
		return 0.0
	var base_time: float = GameConfig.BASE_GROWTH_SECONDS.get(next_phase, 600.0)
	return remaining_progress * base_time * rarity_mult


## Applies trait modifiers from a reagent effect dictionary to a seed.
func _apply_trait_modifiers(seed: SeedData, effect: Dictionary) -> void:
	for key in effect.keys():
		if not seed.dungeon_traits.has(key):
			seed.dungeon_traits[key] = effect[key]
			continue

		var current_value = seed.dungeon_traits[key]
		var modifier_value = effect[key]

		if current_value is float and modifier_value is float:
			seed.dungeon_traits[key] = clampf(current_value + modifier_value, 0.0, 1.0)
		elif current_value is String and modifier_value is String:
			seed.dungeon_traits[key] = modifier_value


## Returns the reagent effect dictionary for a given reagent_id.
## Falls back to empty dict for unknown reagents.
func _get_reagent_effect(reagent_id: String) -> Dictionary:
	return REAGENT_EFFECTS.get(reagent_id, {})


## Applies a slight elemental bias to a seed's dungeon traits.
func _apply_element_bias(seed: SeedData, element: Enums.Element, seed_rng: DeterministicRNG) -> void:
	match element:
		Enums.Element.TERRA:
			seed.dungeon_traits["room_variety"] += 0.05
			seed.dungeon_traits["secret_room_chance"] += 0.02
		Enums.Element.FLAME:
			seed.dungeon_traits["hazard_frequency"] += 0.08
			seed.dungeon_traits["elite_spawn_rate"] += 0.03
		Enums.Element.FROST:
			seed.dungeon_traits["corridor_complexity"] += 0.07
			seed.dungeon_traits["hazard_frequency"] -= 0.03
		Enums.Element.ARCANE:
			seed.dungeon_traits["room_variety"] += 0.08
			seed.dungeon_traits["corridor_complexity"] += 0.05
		Enums.Element.SHADOW:
			seed.dungeon_traits["hazard_frequency"] += 0.10
			seed.dungeon_traits["secret_room_chance"] += 0.05
			seed.dungeon_traits["elite_spawn_rate"] += 0.05

	# Add a tiny RNG jitter to each numeric trait for seed-level uniqueness
	for key in MUTABLE_TRAIT_KEYS:
		if seed.dungeon_traits.has(key):
			var jitter: float = (seed_rng.randf() * 0.04) - 0.02
			seed.dungeon_traits[key] = clampf(seed.dungeon_traits[key] + jitter, 0.0, 1.0)


## Returns the minimum valid growth_rate for a given rarity (anti-cheat).
func _get_minimum_growth_rate(rarity: int) -> float:
	var base: float = GameConfig.BASE_GROWTH_SECONDS.get(Enums.SeedPhase.SPROUT, 600.0)
	var mult: float = GameConfig.RARITY_GROWTH_MULTIPLIER.get(rarity, 1.0)
	return base * mult * 0.5
```

### 16.2 EventBus Signal Addition

The following signal must be added to `src/autoloads/event_bus.gd` (TASK-001) if not already present:

```gdscript
## Emitted when a seed transitions between growth phases.
## @param seed_id The unique identifier of the seed.
## @param new_phase The Enums.SeedPhase value of the new phase.
signal seed_phase_changed(seed_id: StringName, new_phase: int)
```

### 16.3 GameConfig Additions

The following constants should be verified in `src/config/game_config.gd` (TASK-003):

```gdscript
## Default maximum number of grove planting slots.
const DEFAULT_MAX_GROVE_SLOTS: int = 3

## Default dungeon trait values for new seeds.
const DEFAULT_DUNGEON_TRAITS: Dictionary = {
	"room_variety": 0.5,
	"hazard_frequency": 0.3,
	"loot_bias": "BALANCED",
	"corridor_complexity": 0.5,
	"secret_room_chance": 0.1,
	"elite_spawn_rate": 0.15,
}
```

### 16.4 File Registration

| File                              | Class Name    | Extends     | Purpose                     |
| --------------------------------- | ------------- | ----------- | --------------------------- |
| `src/managers/seed_grove.gd`      | `SeedGrove`   | `Node`      | Seed management service     |
| `tests/managers/test_seed_grove.gd` | —           | `GutTest`   | Unit tests for SeedGrove    |

### 16.5 Integration Checklist

1. Verify TASK-004 `SeedData` and `MutationSlot` are implemented and accessible.
2. Verify TASK-002 `DeterministicRNG` is implemented and accessible.
3. Verify TASK-003 `Enums` and `GameConfig` constants exist.
4. Verify TASK-001 `EventBus` autoload is registered with required signals.
5. Add `seed_phase_changed` signal to EventBus if not present.
6. Create `src/managers/` directory if it does not exist.
7. Implement `seed_grove.gd` per Section 16.1.
8. Implement `test_seed_grove.gd` per Section 14.1.
9. Run all tests: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/managers/ -gexit`.
10. Verify all tests pass with zero failures.
11. Run GDScript linter: verify zero errors and zero warnings.
12. Manual smoke test: create grove, add seeds, plant, tick, verify signals in debugger.

---

*End of TASK-012 ticket.*
