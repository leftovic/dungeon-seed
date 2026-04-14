# TASK-010 · Procedural Dungeon Generator (Seed → Room Graph)

---

## Section 1 · Header

| Field               | Value                                                                 |
|---------------------|-----------------------------------------------------------------------|
| **Task ID**         | TASK-010                                                              |
| **Title**           | Procedural Dungeon Generator (Seed → Room Graph)                      |
| **Priority**        | P0 — Critical (blocks expedition resolution and core loop)            |
| **Tier**            | T2 — Core System                                                      |
| **Complexity**      | 13 points (Complex)                                                   |
| **Phase**           | Phase 2 — Core Mechanics                                              |
| **Wave**            | 3                                                                     |
| **Stream**          | 🔴 MCH (Mechanics) — Primary                                         |
| **Cross-Stream**    | ⚪ TCH (graph algorithms, serialization) · 🟡 WLD (dungeon structure) · 🔵 VIS (room graph positions for future map UI) |
| **GDD Reference**   | GDD-v2 §5.2 Dungeon Graph Structure, §5.3 Generation Pipeline, §5.4 Vigor-Scaled Parameters, §5.5 Room Types, §5.10 Difficulty Rating, §4.3 Seed Properties |
| **Milestone**       | M3 — Dungeon Generation & Expedition Pipeline                        |
| **Dependencies**    | TASK-002 (DeterministicRNG), TASK-003 (Enums & Constants), TASK-004 (SeedData Model), TASK-005 (DungeonData/RoomData Models) |
| **Dependents**      | TASK-015 (Expedition Resolver), TASK-017 (Core Loop Orchestrator), TASK-018 (Dungeon Map UI) |
| **Critical Path**   | ✅ YES — no dungeon can be explored until this generator produces a valid room graph |
| **Estimated Hours** | 18–26 hours                                                           |
| **Engine**          | Godot 4.6, GDScript                                                   |
| **Output Files**    | `src/services/dungeon_generator.gd`, `tests/unit/test_dungeon_generator.gd`, `tests/integration/test_dungeon_generation_pipeline.gd` |

---

## Section 2 · Description

### 2.1 What

TASK-010 implements `DungeonGeneratorService` — the deterministic procedural dungeon generator that transforms a `SeedData` instance into a fully populated `DungeonData` room graph. This is the bridge between the planting/growing meta-game and the expedition combat loop: every dungeon the player ever explores begins life as output from this service.

The service lives at `src/services/dungeon_generator.gd`, extends `RefCounted`, and registers `class_name DungeonGeneratorService`. It is a pure-logic, side-effect-free transformation: given identical seed inputs, it always produces byte-identical dungeon outputs. This determinism guarantee is the architectural cornerstone that enables offline idle resolution, replay verification, and anti-cheat validation.

The generation pipeline follows GDD §5.3 in seven stages:

1. **Seed Parsing** — Extract `rarity`, `element`, `phase`, `vigor`, and `dungeon_traits` from the input `SeedData`.
2. **Parameter Calculation** — Compute room count, branching factor, enemy/treasure/trap densities, and elite chance using vigor-scaled interpolation tables from GDD §5.4.
3. **Room Graph Generation** — Place rooms on an abstract 2D grid, build a minimum spanning tree (Prim's algorithm) for guaranteed connectivity, then add random shortcut edges controlled by the branching factor.
4. **Room Type Assignment** — Distribute room types (ENTRANCE, COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS, SECRET) according to weighted probabilities biased by element affinity and the `room_variety` trait.
5. **Difficulty Assignment** — Calculate per-room difficulty using `EffectiveDifficulty = (Vigor × BiomeDifficultyMultiplier) + MutationDifficultySum`, scaled by positional depth along the critical path and modulated by room-type modifiers.
6. **Loot Bias Assignment** — Set per-room currency weighting from the seed's `loot_bias` trait combined with room-type defaults (e.g., TREASURE rooms bias toward GOLD, BOSS rooms bias toward ARTIFACTS).
7. **Validation** — Verify the critical path from ENTRANCE to BOSS is reachable, all rooms are connected, and difficulty/loot invariants hold.

### 2.2 Why

The existing prototype in `src/gdscript/dungeon/dungeon_generator.gd` uses spatial room placement with pixel-level overlap detection. This was appropriate for a visual tilemap dungeon, but the GDD (§5.2) specifies that Dungeon Seed dungeons are **abstract node-and-edge graphs**, not spatial tilemaps. The player experiences dungeons as a room-by-room expedition, not a free-roaming map. The new generator produces the correct data structure for this design.

Additionally, the prototype has no determinism guarantee — it uses Godot's global `randi()` which shares state with every other system. The new generator uses `DeterministicRNG` (TASK-002) seeded exclusively from the seed's identity, ensuring the same seed always generates the same dungeon regardless of game state, frame count, or system time.

### 2.3 Player Experience Impact

Every dungeon the player explores is the output of this system. The generator's quality directly determines:

- **Replayability** — Varied room layouts, branching paths, and element-biased distributions keep dungeons feeling fresh even when farming the same seed rarity tier.
- **Strategic Depth** — Branching paths with shortcut edges create meaningful routing decisions: take the safe path through REST rooms, or risk the shortcut that bypasses treasure but reaches the boss faster?
- **Fairness** — Vigor-scaled difficulty ensures that a Vigor-10 seed never produces a Vigor-80 dungeon. Players can trust that difficulty labels are accurate.
- **Idle Integrity** — Because generation is deterministic, the game can regenerate dungeons from saved seed data during offline resolution without storing the full room graph. This keeps save files small and enables server-side validation.
- **Discovery Moments** — SECRET rooms on branch paths reward exploration-oriented players who don't beeline for the boss.

### 2.4 Economy Impact

The generator's loot bias assignments directly feed the economy pipeline:

- **Room-type loot biases** determine the expected gold/essence/fragment/artifact distribution per dungeon run.
- If bias assignment is wrong, players farming TREASURE-heavy dungeons may receive incorrect currency ratios, disrupting the economy's faucet-sink balance.
- BOSS rooms carry premium currency (ARTIFACTS) bias — incorrect boss loot bias would inflate or deflate the rarest currency tier.
- The `loot_bias` trait from seeds allows players to influence reward distribution through seed selection, creating a meaningful choice between seed types.

### 2.5 Technical Architecture

#### Generation Pipeline Flow

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   SeedData   │────▶│ DungeonGenerator │────▶│   DungeonData    │
│              │     │    Service       │     │  (Room Graph)    │
│ - id         │     │                  │     │ - rooms[]        │
│ - rarity     │     │ Pipeline:        │     │ - edges[]        │
│ - element    │     │ 1. Parse seed    │     │ - entry_room_idx │
│ - phase      │     │ 2. Calc params   │     │ - boss_room_idx  │
│ - vigor      │     │ 3. Gen graph     │     │ - difficulty      │
│ - traits{}   │     │ 4. Assign types  │     │ - element        │
│ - mutations[]│     │ 5. Assign diff   │     └──────────────────┘
└──────────────┘     │ 6. Assign loot   │
                     │ 7. Validate      │
        ┌───────────▶│                  │
        │            └──────────────────┘
┌───────┴────────┐
│DeterministicRNG│
│ (seeded from   │
│  seed_id+phase)│
└────────────────┘
```

#### Graph Construction Detail

```
Step 3a: Place rooms on abstract grid
  ┌───┬───┬───┬───┐
  │ 0 │   │ 1 │   │    (rooms placed at random grid cells)
  ├───┼───┼───┼───┤
  │   │ 2 │   │ 3 │
  ├───┼───┼───┼───┤
  │ 4 │   │ 5 │   │
  ├───┼───┼───┼───┤
  │   │ 6 │   │ 7 │
  └───┴───┴───┴───┘

Step 3b: Build MST (Prim's) — guaranteed connectivity
  0 ─── 1
  │     │
  2 ─── 3
  │
  4 ─── 5
        │
  6 ─── 7

Step 3c: Add shortcut edges (branching factor)
  0 ─── 1
  │ ╲   │
  2 ─── 3
  │     │     (added: 0-2 diagonal, 3-5 shortcut)
  4 ─── 5
        │
  6 ─── 7
```

#### Room Type Distribution (Example: FLAME element, Vigor 50)

```
Room Index:  0       1       2       3       4       5       6       7
Type:       ENTR   COMBAT  TREAS  COMBAT  REST   COMBAT   TRAP    BOSS
Difficulty:  0.0    0.45    0.35    0.55   0.0    0.65    0.70    1.0
Loot Bias:  none   gold    gold+   gold   none   essence  frag   artifact
```

### 2.6 System Interaction Map

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     DungeonGeneratorService                             │
│  generate(seed_data) → DungeonData                                      │
├─────────────────────────────────────────────────────────────────────────┤
│  CONSUMES (upstream):                                                   │
│  ┌──────────────┐  ┌──────────┐  ┌─────────────┐  ┌───────────────┐   │
│  │ SeedData     │  │ Enums    │  │ Deterministic│  │ DungeonData/  │   │
│  │ (TASK-004)   │  │(TASK-003)│  │ RNG          │  │ RoomData      │   │
│  │ .id          │  │.RoomType │  │ (TASK-002)   │  │ (TASK-005)    │   │
│  │ .rarity      │  │.Element  │  │ .randf()     │  │ .rooms[]      │   │
│  │ .element     │  │.SeedPhase│  │ .randi()     │  │ .edges[]      │   │
│  │ .phase       │  │.Currency │  │ .shuffle()   │  │ .entry_idx    │   │
│  │ .vigor       │  │.SeedRar  │  │ .pick()      │  │ .boss_idx     │   │
│  │ .traits{}    │  │          │  │ .weighted()  │  │               │   │
│  │ .mutations[] │  │          │  │              │  │               │   │
│  └──────────────┘  └──────────┘  └─────────────┘  └───────────────┘   │
│                                                                         │
│  PRODUCES (downstream consumers):                                       │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐      │
│  │ Expedition       │  │ Core Loop        │  │ Dungeon Map UI   │      │
│  │ Resolver         │  │ Orchestrator     │  │ (TASK-018)       │      │
│  │ (TASK-015)       │  │ (TASK-017)       │  │ Reads rooms/     │      │
│  │ Traverses graph, │  │ Triggers gen on  │  │ edges for visual │      │
│  │ resolves combat  │  │ seed maturation  │  │ graph rendering  │      │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘      │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.7 Development Cost

| Metric                     | Target          |
|----------------------------|-----------------|
| Lines of production code   | 400–550         |
| Lines of test code         | 350–500         |
| New files created          | 3               |
| Existing files modified    | 0               |
| Risk level                 | Medium (graph algorithms, balancing) |

### 2.8 Constraints and Design Decisions

| Decision | Rationale |
|----------|-----------|
| RefCounted, not Node | Generator is a pure-logic service with no scene tree dependency. Avoids orphan node leaks. |
| Prim's MST over Kruskal's | Prim's is simpler to implement for small graphs (≤28 rooms) and easier to seed deterministically. |
| Abstract grid placement, not force-directed | Grid placement is O(n) and deterministic. Force-directed layout involves iterative convergence that is harder to make deterministic. |
| Vigor-scaled interpolation tables | Follows GDD §5.4 exactly. Linear interpolation between breakpoints prevents discontinuous difficulty jumps. |
| Element biases as weight multipliers | Multiplicative biases compose cleanly and never zero out a room type entirely. A FLAME dungeon has more COMBAT, but TREASURE rooms can still appear. |
| Shortcut edges capped at branching_factor × room_count | Prevents over-connected graphs that trivialize pathfinding. At most ~50% additional edges beyond the MST. |
| SECRET rooms only on branch paths | Follows GDD §5.5. SECRET rooms reward exploration and are never on the critical path. |
| seed_id + phase as RNG seed | Different growth phases of the same seed produce different dungeons, but the same phase always produces the same dungeon. |
| No spatial collision detection | Unlike the prototype, rooms are abstract graph nodes. No overlap detection, no pixel coordinates. Position is for UI layout hints only. |
| generate_from_params() for testing | Allows tests to exercise the generator without constructing full SeedData objects, reducing test coupling to TASK-004. |

---

## Section 3 · Use Cases

### UC-01: Kai the Speedrunner — Blitz Through a Known Dungeon

**Archetype:** Kai plants dozens of seeds per session and dispatches adventurers the moment a dungeon matures. He exploits determinism by memorizing optimal routes through seeds he's seen before.

**Scenario:**
1. Kai plants a Legendary FLAME seed (Vigor 80) at the Bloom growth stage.
2. The seed matures and the Core Loop Orchestrator (TASK-017) calls `DungeonGeneratorService.generate(seed_data)`.
3. The generator produces a 15-room dungeon with high COMBAT density (FLAME bias), 2 shortcut edges, and a SECRET room containing an ARTIFACT-biased treasure node.
4. Kai dispatches his strongest party. The Expedition Resolver (TASK-015) traverses the room graph, resolving encounters along the shortest path to the BOSS room.
5. On a subsequent run with an identical seed, Kai notices the dungeon layout is byte-identical — same rooms, same edges, same difficulty values. He routes his party through the shortcut edge he discovered last time, skipping 3 COMBAT rooms.
6. The determinism guarantee means Kai's route knowledge carries across sessions.

**Success Criteria:** Two `generate()` calls with the same `SeedData` produce identical `DungeonData`. The speedrunner's learned knowledge of dungeon layouts is valid across game sessions.

### UC-02: Luna the Completionist — Exhaust Every Room

**Archetype:** Luna never leaves a dungeon until every room is cleared. She values dungeons with high room counts, SECRET rooms, and varied room types.

**Scenario:**
1. Luna plants a Rare ARCANE seed (Vigor 60) at the Bud growth stage.
2. The generator produces a 10-room dungeon (base 8 for Bud + 2 rarity bonus for Rare).
3. Room type distribution includes 1 ENTRANCE, 4 COMBAT, 1 TREASURE, 1 TRAP, 1 REST, 1 SECRET (on a branch path), and 1 BOSS.
4. Luna's party explores every room in order. She discovers the SECRET room by taking the branch off the main path.
5. The SECRET room has elevated loot bias (FRAGMENTS currency) that Luna values for crafting.
6. Luna checks `DungeonData.is_fully_cleared()` — it returns `true` only after all 10 rooms have `is_cleared = true`.
7. The ARCANE element bias gave slightly higher PUZZLE weight, but the phase was Bud (pre-MVP puzzle cap), so the PUZZLE probability was absorbed into COMBAT and TRAP.

**Success Criteria:** Room count follows phase + rarity formula. SECRET rooms exist on branches, not the critical path. `is_fully_cleared()` requires all rooms, not just boss kill.

### UC-03: Sam the Casual Parent — Quick Predictable Run

**Archetype:** Sam has 10 minutes to play. He wants a short dungeon with no surprises — just enough rooms to feel progress, with predictable difficulty.

**Scenario:**
1. Sam plants a Common TERRA seed (Vigor 15) at the Spore growth stage.
2. The generator produces a 3-room dungeon (base 3 for Spore + 0 rarity bonus for Common).
3. The minimal dungeon has: ENTRANCE (room 0), COMBAT (room 1), BOSS (room 2).
4. The graph is linear (only 2 edges: 0→1, 1→2) because 3 rooms leave no room for branching or shortcuts.
5. Difficulty is low across all rooms — Vigor 15 × TERRA multiplier (1.0) = base difficulty 0.15.
6. Sam dispatches a party and the expedition resolves quickly. Loot is modest (TERRA has no special currency bias, so default GOLD weighting applies).
7. Sam pockets his rewards and closes the game in under 5 minutes.

**Success Criteria:** Minimal dungeon (3 rooms) is valid, playable, and has correct ENTRANCE → COMBAT → BOSS type sequence. Low-vigor seeds produce low-difficulty rooms.

### UC-04: Morgan the Theorycrafting Optimizer — Analyzing Seed Traits

**Archetype:** Morgan studies the dungeon_traits system to understand how room_variety, loot_bias, and hazard_frequency affect generation outcomes.

**Scenario:**
1. Morgan plants two identical Uncommon FROST seeds (Vigor 40) but one has `room_variety: 0.8` and the other has `room_variety: 0.2`.
2. The high-variety seed produces a dungeon with evenly distributed room types: COMBAT, TREASURE, TRAP, PUZZLE, REST all represented.
3. The low-variety seed produces a COMBAT-heavy dungeon with minimal type diversity — the reduced variety weight concentrates probability mass on the dominant type.
4. Morgan observes that the FROST element bias increased TRAP weight in both dungeons, but the effect is more visible in the high-variety dungeon where non-COMBAT rooms have room to express.
5. Morgan then compares `loot_bias: "gold"` versus `loot_bias: "essence"` seeds and confirms that room-level loot bias dictionaries shift accordingly.

**Success Criteria:** `room_variety` trait meaningfully affects type distribution. Element bias and trait bias stack predictably. Different trait values on otherwise identical seeds produce different (but deterministic) dungeons.

---

## Section 4 · Glossary

| Term | Definition |
|------|------------|
| **Room Graph** | An abstract undirected graph where nodes are dungeon rooms and edges are passable connections between rooms. Not a spatial tilemap — rooms have no physical dimensions, only connectivity. |
| **Minimum Spanning Tree (MST)** | A tree that connects all rooms with the minimum total edge weight, guaranteeing that every room is reachable from every other room. Used as the connectivity backbone before adding shortcut edges. |
| **Prim's Algorithm** | A greedy MST algorithm that starts from one node and repeatedly adds the cheapest edge connecting the tree to a non-tree node. Chosen for deterministic behavior with seeded RNG. |
| **Branching Factor** | A vigor-scaled parameter (0.1–0.5) controlling how many shortcut edges are added beyond the MST. Higher branching = more alternate paths through the dungeon. |
| **Critical Path** | The shortest path from the ENTRANCE room (index 0) to the BOSS room (last index). This is the minimum set of rooms a player must clear to complete the dungeon. |
| **Shortcut Edge** | An edge added after MST construction that creates an alternate route, potentially bypassing rooms on the critical path. Controlled by branching factor. |
| **Vigor** | A seed stat (1–100) that scales all dungeon parameters: room count, enemy density, trap frequency, elite chance, and base difficulty. The primary difficulty dial. |
| **Element Affinity** | One of five elements (TERRA, FLAME, FROST, ARCANE, SHADOW) carried by a seed that biases room type distribution, difficulty multipliers, and aesthetic theming. |
| **Growth Phase** | The seed's maturation stage (SPORE, SPROUT, BUD, BLOOM) that determines base room count and available room types. Higher phases = larger, more complex dungeons. |
| **Seed Rarity** | One of five tiers (COMMON, UNCOMMON, RARE, EPIC, LEGENDARY) that grants bonus rooms and mutation slots. |
| **Room Type** | One of eight categories (ENTRANCE, COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS, SECRET) defining what encounter the player faces in that room. |
| **Loot Bias** | A per-room Dictionary mapping `Enums.Currency` to float weights that influence what rewards the Expedition Resolver distributes when clearing that room. |
| **DeterministicRNG** | A project-specific seeded random number generator (TASK-002) that produces reproducible pseudo-random sequences. All generator randomness flows through this object. |
| **Abstract Position** | A `Vector2` coordinate assigned to each room for UI layout purposes. Not a game-world position — rooms have no physical size. Used by the Dungeon Map UI (TASK-018) to render the node graph. |
| **Biome Difficulty Multiplier** | A per-element scalar applied to base difficulty. SHADOW has the highest (1.3), TERRA the lowest (1.0). From GDD §5.10. |
| **Mutation Difficulty Sum** | The total difficulty contributed by active mutations on the seed. Each mutation slot adds 0–5 difficulty points. Feeds the EffectiveDifficulty formula. |
| **Room Variety Trait** | A float (0.0–1.0) in the seed's `dungeon_traits` that modulates how evenly room types are distributed vs. concentrating on the dominant type. |
| **Loot Bias Trait** | A string in the seed's `dungeon_traits` (e.g., "gold", "essence") that shifts all room loot biases toward the named currency. |
| **Hazard Frequency Trait** | A float (0.0–1.0) in the seed's `dungeon_traits` that increases TRAP room weight and trap difficulty modifiers. |
| **DungeonData** | The authoritative data model (TASK-005) for a generated dungeon. Contains `rooms: Array[RoomData]`, `edges: Array[Vector2i]`, indices, and graph operations. |
| **RoomData** | The per-room data model (TASK-005). Contains `index`, `type`, `difficulty`, `is_cleared`, `loot_bias`, and `position`. |
| **SeedData** | The seed data model (TASK-004). Contains `id`, `rarity`, `element`, `phase`, `vigor`, `dungeon_traits`, and `mutation_slots`. The primary input to the generator. |

---

## Section 5 · Out of Scope

The following items are explicitly **NOT** part of TASK-010. They belong to other tasks and must not be implemented, stubbed with logic, or planned for in this ticket's code:

| # | Excluded Item | Belongs To |
|---|--------------|------------|
| 1 | Expedition resolution — traversing the dungeon, resolving combat encounters, calculating damage, advancing room-by-room | TASK-015 (Expedition Resolver) |
| 2 | Visual rendering of the dungeon map — drawing nodes, edges, fog of war, room icons on screen | TASK-018 (Dungeon Map UI) |
| 3 | Core loop orchestration — triggering generation on seed maturation, dispatching adventurers, collecting loot | TASK-017 (Core Loop Orchestrator) |
| 4 | Seed growth and maturation timers — the process by which a planted seed becomes ready for dungeon generation | TASK-011 (Seed Growth & Mutations) |
| 5 | Adventurer stats, abilities, party composition, and combat resolution within rooms | TASK-006 (Adventurer Model), TASK-015 (Expedition Resolver) |
| 6 | Loot table resolution — converting room loot_bias into actual item drops with quantities and rarities | TASK-009 (Loot & Economy), TASK-015 (Expedition Resolver) |
| 7 | Save/load serialization of generated dungeons — `DungeonData.to_dict()` / `from_dict()` is defined in TASK-005 | TASK-005 (DungeonData Model), TASK-009 (Save/Load Manager) |
| 8 | Mutation system — applying mutations to seeds that modify dungeon traits or generation parameters | TASK-011 (Seed Growth & Mutations) |
| 9 | Biome templates — visual theming, tile palettes, background art, ambient audio per element type | TASK-018+ (Dungeon Map UI), Audio tasks |
| 10 | Encounter placement — specific enemy types, enemy levels, enemy abilities within COMBAT rooms | TASK-015 (Expedition Resolver) |
| 11 | Trap mechanics — specific trap types, damage values, disarm checks within TRAP rooms | TASK-015 (Expedition Resolver) |
| 12 | Puzzle mechanics — puzzle type selection, solve conditions, failure consequences | Future (post-MVP) |
| 13 | Dynamic difficulty adjustment — modifying dungeon difficulty based on player performance or party strength | Out of scope for v1 |
| 14 | Multi-floor dungeons — generating multiple connected floors with staircase rooms | Out of scope for v1 |
| 15 | Dungeon modifiers / affixes — global dungeon-wide effects like "all enemies have +20% HP" | TASK-011 (Mutations provide this) |

---

## Section 6 · Functional Requirements

Each requirement is independently testable. Status: ☐ = not started.

### Core Service

| ID | Requirement | Priority |
|----|------------|----------|
| FR-001 | `dungeon_generator.gd` MUST extend `RefCounted` and declare `class_name DungeonGeneratorService`. | MUST |
| FR-002 | `DungeonGeneratorService` MUST expose `generate(seed_data: SeedData) -> DungeonData` as the primary public API. | MUST |
| FR-003 | `DungeonGeneratorService` MUST expose `generate_from_params(seed_id: String, rarity: int, element: int, phase: int, vigor: int, traits: Dictionary) -> DungeonData` for testing without full SeedData. | MUST |
| FR-004 | Both `generate()` and `generate_from_params()` MUST produce identical output when given equivalent input parameters. | MUST |

### Seed Parsing (Pipeline Stage 1)

| ID | Requirement | Priority |
|----|------------|----------|
| FR-005 | The generator MUST extract `rarity`, `element`, `phase`, `vigor`, and `dungeon_traits` from the input `SeedData`. | MUST |
| FR-006 | If `dungeon_traits` is empty or missing keys, the generator MUST use default values: `room_variety: 0.5`, `loot_bias: "gold"`, `hazard_frequency: 0.2`. | MUST |
| FR-007 | The generator MUST seed the `DeterministicRNG` using a combination of `seed_id` and `phase` to ensure different phases produce different dungeons. | MUST |

### Parameter Calculation (Pipeline Stage 2)

| ID | Requirement | Priority |
|----|------------|----------|
| FR-008 | Room count MUST be calculated as: base count from phase (SPORE=3, SPROUT=5, BUD=8, BLOOM=12) + rarity bonus (COMMON=0, UNCOMMON=1, RARE=2, EPIC=3, LEGENDARY=3) + vigor bonus (floor(vigor / 33), yielding 0–3). | MUST |
| FR-009 | Room count MUST be clamped to the vigor-scaled range from GDD §5.4 (e.g., Vigor 1 → 5–7, Vigor 50 → 12–16, Vigor 100 → 20–28). | MUST |
| FR-010 | Branching factor MUST be interpolated linearly from the GDD §5.4 table: Vigor 1 → 0.1, Vigor 25 → 0.2, Vigor 50 → 0.3, Vigor 75 → 0.4, Vigor 100 → 0.5. | MUST |
| FR-011 | Enemy density, treasure density, trap density, and elite chance MUST be interpolated from GDD §5.4 breakpoints using linear interpolation. | MUST |
| FR-012 | Biome difficulty multiplier MUST be looked up per element: TERRA=1.0, FLAME=1.1, FROST=1.05, ARCANE=1.15, SHADOW=1.3. | MUST |

### Room Graph Generation (Pipeline Stage 3)

| ID | Requirement | Priority |
|----|------------|----------|
| FR-013 | The generator MUST place rooms at abstract 2D positions on a grid with sufficient spacing to avoid visual overlap in the future map UI. | MUST |
| FR-014 | Room positions MUST be assigned using the seeded RNG so they are deterministic for a given seed. | MUST |
| FR-015 | The generator MUST build a minimum spanning tree connecting all rooms using Prim's algorithm with Euclidean distance as edge weight. | MUST |
| FR-016 | The MST construction MUST use `DeterministicRNG` for tie-breaking to ensure deterministic output. | MUST |
| FR-017 | After MST construction, the generator MUST add `floor(branching_factor × room_count)` random shortcut edges (minimum 0, capped at available non-MST edges). | MUST |
| FR-018 | Shortcut edges MUST NOT create duplicate edges (no two edges connecting the same pair of rooms). | MUST |
| FR-019 | The resulting graph MUST be fully connected — every room is reachable from every other room via some path. | MUST |
| FR-020 | Room index 0 MUST be designated as the entry room (`DungeonData.entry_room_index = 0`). | MUST |
| FR-021 | The last room index (room_count - 1) MUST be designated as the boss room (`DungeonData.boss_room_index = room_count - 1`). | MUST |

### Room Type Assignment (Pipeline Stage 4)

| ID | Requirement | Priority |
|----|------------|----------|
| FR-022 | Room 0 MUST always be assigned type `Enums.RoomType.ENTRANCE`. | MUST |
| FR-023 | The last room (boss_room_index) MUST always be assigned type `Enums.RoomType.BOSS`. | MUST |
| FR-024 | Exactly 1 REST room MUST be placed if room count ≥ 4. For room count ≥ 8, exactly 2 REST rooms MUST be placed, positioned at approximately 40% and 70% of the critical path length. | MUST |
| FR-025 | SECRET rooms (0–3) MUST be placed only on rooms that are NOT on the critical path (branch-only). If no branch rooms exist, zero SECRET rooms are placed. | MUST |
| FR-026 | The number of SECRET rooms MUST scale: 0 for room count ≤ 5, 1 for 6–10, 2 for 11–18, 3 for 19+. | SHOULD |
| FR-027 | Remaining rooms (after ENTRANCE, BOSS, REST, SECRET are placed) MUST be assigned types via weighted random selection using base weights: COMBAT=40, TREASURE=20, TRAP=15, PUZZLE=15, REST=10. | MUST |
| FR-028 | Element biases MUST modify the base weights: FLAME adds +15 to COMBAT, FROST adds +15 to TRAP, ARCANE adds +10 to PUZZLE and +5 to TREASURE, SHADOW adds +10 to TRAP and +5 to COMBAT, TERRA leaves weights unmodified. | MUST |
| FR-029 | The `room_variety` trait MUST modulate weight distribution: high variety (>0.5) flattens weights toward equal distribution; low variety (<0.5) amplifies the dominant weight. | SHOULD |
| FR-030 | The `hazard_frequency` trait MUST increase TRAP weight by `hazard_frequency × 20` additional points. | SHOULD |

### Difficulty Assignment (Pipeline Stage 5)

| ID | Requirement | Priority |
|----|------------|----------|
| FR-031 | Base difficulty MUST be calculated as `vigor × biome_difficulty_multiplier / 100.0` (normalized to 0.0–1.3 range). | MUST |
| FR-032 | Each room's difficulty MUST be scaled by a positional depth factor: `depth_along_critical_path / max_depth`, ranging from 0.0 (ENTRANCE) to 1.0 (BOSS). Rooms not on the critical path use the depth of their nearest critical-path neighbor. | MUST |
| FR-033 | Room-type difficulty modifiers MUST be applied: ENTRANCE=0.0, COMBAT=1.0, TREASURE=0.7, TRAP=0.9, PUZZLE=0.6, REST=0.0, BOSS=1.5, SECRET=0.8. | MUST |
| FR-034 | The final per-room difficulty formula MUST be: `base_difficulty × (0.3 + 0.7 × depth_factor) × room_type_modifier`. | MUST |
| FR-035 | Mutation difficulty sum from `seed_data.mutation_slots` MUST be added to the `DungeonData.difficulty_rating` (total dungeon difficulty). | MUST |
| FR-036 | `DungeonData.difficulty_rating` MUST be the average of all non-zero room difficulties plus the mutation sum. | MUST |

### Loot Bias Assignment (Pipeline Stage 6)

| ID | Requirement | Priority |
|----|------------|----------|
| FR-037 | Each room MUST have a `loot_bias: Dictionary` mapping currency enum values to float weights. | MUST |
| FR-038 | Default loot bias by room type MUST be: ENTRANCE={}, COMBAT={GOLD:0.6, ESSENCE:0.3, FRAGMENTS:0.1}, TREASURE={GOLD:0.5, ESSENCE:0.2, FRAGMENTS:0.2, ARTIFACTS:0.1}, TRAP={FRAGMENTS:0.5, GOLD:0.3, ESSENCE:0.2}, PUZZLE={ESSENCE:0.5, FRAGMENTS:0.3, GOLD:0.2}, REST={}, BOSS={ARTIFACTS:0.4, GOLD:0.3, ESSENCE:0.2, FRAGMENTS:0.1}, SECRET={FRAGMENTS:0.4, ARTIFACTS:0.3, ESSENCE:0.2, GOLD:0.1}. | MUST |
| FR-039 | The seed's `loot_bias` trait MUST shift all room biases by adding +0.2 to the named currency and renormalizing weights to sum to 1.0. | SHOULD |
| FR-040 | Rooms with empty loot_bias (ENTRANCE, REST) MUST remain empty — no loot is distributed from these rooms. | MUST |

### Validation (Pipeline Stage 7)

| ID | Requirement | Priority |
|----|------------|----------|
| FR-041 | The generator MUST verify that a path exists from `entry_room_index` to `boss_room_index` using BFS. | MUST |
| FR-042 | The generator MUST verify that every room is reachable from the entry room (full connectivity check). | MUST |
| FR-043 | The generator MUST verify that exactly one ENTRANCE room and at least one BOSS room exist. | MUST |
| FR-044 | If validation fails, the generator MUST push an error and return a minimal valid fallback dungeon (3 rooms: ENTRANCE → COMBAT → BOSS, linear graph). | MUST |

### Determinism

| ID | Requirement | Priority |
|----|------------|----------|
| FR-045 | All random decisions MUST flow through a single `DeterministicRNG` instance seeded from `seed_id + phase`. | MUST |
| FR-046 | No calls to `randf()`, `randi()`, `randi_range()`, or any global Godot RNG functions are permitted. | MUST |
| FR-047 | Calling `generate()` twice with the same SeedData MUST produce byte-identical DungeonData (identical rooms, edges, positions, difficulties, loot biases). | MUST |
| FR-048 | The same seed at different phases (SPORE vs BLOOM) MUST produce different dungeons. | MUST |

### Output Contract

| ID | Requirement | Priority |
|----|------------|----------|
| FR-049 | The returned `DungeonData.seed_id` MUST match the input seed's `id`. | MUST |
| FR-050 | The returned `DungeonData.element` MUST match the input seed's `element`. | MUST |
| FR-051 | The returned `DungeonData.rooms` array MUST have length equal to the calculated room count. | MUST |
| FR-052 | Every `RoomData` in the rooms array MUST have its `index` field matching its position in the array. | MUST |
| FR-053 | Every `RoomData` MUST have `is_cleared = false` (fresh dungeon, no rooms explored yet). | MUST |
| FR-054 | `DungeonData.edges` MUST contain only valid room index pairs (both indices in range `[0, room_count)`). | MUST |
| FR-055 | All edges MUST be stored with the smaller index first: `Vector2i(min(a,b), max(a,b))` to prevent duplicate representation. | MUST |

---

## Section 7 · Non-Functional Requirements

| ID | Requirement | Category |
|----|------------|----------|
| NFR-001 | `generate()` MUST complete in under 50ms for dungeons up to 28 rooms on a standard development machine (i7/Ryzen 5+, 16 GB RAM). | Performance |
| NFR-002 | The generator MUST allocate zero Nodes. All intermediate data structures MUST be arrays, dictionaries, or RefCounted objects. | Memory |
| NFR-003 | The generator MUST produce zero orphan objects — all allocated RefCounted objects must be referenced by the returned DungeonData or released before return. | Memory |
| NFR-004 | All GDScript files MUST use static type hints on every variable declaration, function parameter, and return type. No untyped `var` declarations. | Code Quality |
| NFR-005 | All GDScript files MUST follow Godot style guide: `snake_case` for functions/variables, `PascalCase` for classes, `UPPER_SNAKE_CASE` for constants. | Code Quality |
| NFR-006 | All public methods and constants MUST have `##` doc comments explaining purpose, parameters, and return value. | Documentation |
| NFR-007 | The service MUST be stateless between calls — no persistent state carried from one `generate()` call to the next. Each call is independent. | Architecture |
| NFR-008 | The service MUST NOT access any global state (no autoload references, no singletons, no `Engine` queries). All inputs come through method parameters. | Architecture |
| NFR-009 | The generator MUST NOT produce dungeons where the BOSS room is unreachable. If the algorithm fails, the fallback dungeon MUST still be valid. | Reliability |
| NFR-010 | The total line count of `dungeon_generator.gd` MUST stay under 600 lines (excluding blank lines and comments). If exceeded, internal helper methods should be extracted to a private inner scope, not a separate file. | Maintainability |
| NFR-011 | The generator MUST support room counts from 3 (minimum Spore dungeon) to 31 (maximum Bloom + Legendary + high vigor) without algorithmic degradation. | Scalability |
| NFR-012 | All file paths referenced in code MUST use `res://` prefix and forward slashes. | Portability |
| NFR-013 | The generator MUST NOT import or depend on any UI, audio, or rendering systems. Dependencies are limited to: `DeterministicRNG`, `DungeonData`, `RoomData`, `SeedData`, `Enums`. | Coupling |
| NFR-014 | Tests MUST achieve 100% branch coverage on the generation pipeline (every room type, every element bias, every edge case). | Testing |
| NFR-015 | The generator MUST be parseable by GDScript 2.0 (Godot 4.6) with zero parser warnings. | Compatibility |
| NFR-016 | Determinism MUST hold across platforms (Windows, macOS, Linux) — the same seed produces the same dungeon on every OS. This is guaranteed by using integer arithmetic in `DeterministicRNG` and avoiding floating-point-dependent branching. | Portability |
| NFR-017 | The service MUST be instantiable and callable from GUT tests without a running scene tree (no `get_tree()` calls, no Node hierarchy required). | Testability |

---

## Section 8 · Designer's Manual

### 8.1 Tuning Guide — Room Count

The room count formula is:

```
room_count = phase_base + rarity_bonus + vigor_bonus
```

| Phase | Base | Rationale |
|-------|------|-----------|
| SPORE | 3 | Minimal dungeon — tutorial-friendly, quick to clear |
| SPROUT | 5 | Short dungeon — introduces branching |
| BUD | 8 | Medium dungeon — full room type diversity |
| BLOOM | 12 | Large dungeon — multiple paths, secrets, strategic routing |

| Rarity | Bonus | Rationale |
|--------|-------|-----------|
| COMMON | 0 | No bonus — baseline experience |
| UNCOMMON | 1 | Slight expansion — one more encounter |
| RARE | 2 | Notable expansion — room for a SECRET |
| EPIC | 3 | Significant expansion — multiple branches |
| LEGENDARY | 3 | Same as EPIC — Legendary's value is in mutation slots and loot, not room count |

| Vigor Range | Bonus | Rationale |
|-------------|-------|-----------|
| 1–32 | 0 | Low vigor — no room expansion |
| 33–65 | 1 | Mid vigor — one extra room |
| 66–98 | 2 | High vigor — two extra rooms |
| 99–100 | 3 | Max vigor — three extra rooms |

After calculation, the room count is clamped to the GDD §5.4 vigor-scaled range to prevent low-vigor seeds from having artificially large dungeons.

### 8.2 Tuning Guide — Room Type Weights

Base weights (out of 100):

```
COMBAT:   40    (dominant — most rooms are fights)
TREASURE: 20    (reward rooms — keep dungeon exciting)
TRAP:     15    (hazard rooms — create risk/reward)
PUZZLE:   15    (brain rooms — variety pacing)
REST:     10    (recovery rooms — placed algorithmically, not weighted)
```

Element bias modifiers (additive):

```
TERRA:   no changes           → balanced dungeon
FLAME:   COMBAT += 15         → aggressive, fight-heavy
FROST:   TRAP += 15           → hazardous, punishing
ARCANE:  PUZZLE += 10, TREAS += 5  → intellectual, rewarding
SHADOW:  TRAP += 10, COMBAT += 5   → dangerous all around
```

Room variety trait effect:

```
variety = 0.0: dominant weight amplified 2×, others reduced proportionally
variety = 0.5: weights used as-is (default)
variety = 1.0: all weights equalized (flat distribution)
```

Formula: `adjusted_weight = base_weight × (1 + (variety - 0.5) × (average_weight / base_weight - 1))`

### 8.3 Tuning Guide — Difficulty Scaling

Per-room difficulty formula:

```
room_difficulty = base_diff × (0.3 + 0.7 × depth_factor) × type_modifier

where:
  base_diff = vigor × biome_multiplier / 100.0
  depth_factor = room_depth_on_critical_path / max_critical_path_depth
  type_modifier = { ENTRANCE: 0.0, COMBAT: 1.0, TREASURE: 0.7, TRAP: 0.9,
                    PUZZLE: 0.6, REST: 0.0, BOSS: 1.5, SECRET: 0.8 }
```

Biome difficulty multipliers:

| Element | Multiplier | Effect |
|---------|-----------|--------|
| TERRA | 1.0 | Baseline — no difficulty adjustment |
| FLAME | 1.1 | Slightly harder — aggressive enemies |
| FROST | 1.05 | Slightly harder — environmental hazards |
| ARCANE | 1.15 | Notably harder — magical complexity |
| SHADOW | 1.3 | Significantly harder — elites and surprises |

### 8.4 Tuning Guide — Loot Bias

Default room type loot biases (pre-trait adjustment):

| Room Type | GOLD | ESSENCE | FRAGMENTS | ARTIFACTS |
|-----------|------|---------|-----------|-----------|
| ENTRANCE | — | — | — | — |
| COMBAT | 0.6 | 0.3 | 0.1 | — |
| TREASURE | 0.5 | 0.2 | 0.2 | 0.1 |
| TRAP | 0.3 | 0.2 | 0.5 | — |
| PUZZLE | 0.2 | 0.5 | 0.3 | — |
| REST | — | — | — | — |
| BOSS | 0.3 | 0.2 | 0.1 | 0.4 |
| SECRET | 0.1 | 0.2 | 0.4 | 0.3 |

Seed loot_bias trait adds +0.2 to the named currency, then all weights are renormalized to sum to 1.0.

### 8.5 Config Reference — Constants

All tuning constants are declared as `const` at the top of `dungeon_generator.gd`:

| Constant | Value | Purpose |
|----------|-------|---------|
| `PHASE_ROOM_COUNTS` | `{0: 3, 1: 5, 2: 8, 3: 12}` | Base room counts per SeedPhase ordinal |
| `RARITY_ROOM_BONUS` | `{0: 0, 1: 1, 2: 2, 3: 3, 4: 3}` | Room count bonus per SeedRarity ordinal |
| `VIGOR_BREAKPOINTS` | `[1, 25, 50, 75, 100]` | Vigor breakpoints for parameter interpolation |
| `ROOM_COUNT_RANGES` | `[[5,7],[8,11],[12,16],[16,22],[20,28]]` | Min/max room counts per vigor breakpoint |
| `BRANCHING_FACTORS` | `[0.1, 0.2, 0.3, 0.4, 0.5]` | Branching factor per vigor breakpoint |
| `BIOME_DIFFICULTY` | `{0:1.0, 1:1.1, 2:1.05, 3:1.15, 4:1.3}` | Per-element difficulty multiplier |
| `ROOM_TYPE_WEIGHTS` | `{COMBAT:40, TREASURE:20, TRAP:15, PUZZLE:15, REST:10}` | Base room type selection weights |
| `ROOM_DIFF_MODIFIERS` | `{ENTRANCE:0.0, COMBAT:1.0, ...}` | Per-room-type difficulty multiplier |
| `ROOM_LOOT_DEFAULTS` | `{COMBAT:{...}, TREASURE:{...}, ...}` | Default loot bias dictionaries per type |
| `ELEMENT_WEIGHT_BIAS` | `{FLAME:{COMBAT:15}, FROST:{TRAP:15}, ...}` | Additive weight modifiers per element |
| `GRID_SPACING` | `120.0` | Abstract grid cell size for room placement |

### 8.6 Signal Map

`DungeonGeneratorService` emits no signals. It is a pure synchronous transformation.

Consumers that use the output:
- **EventBus.expedition_started** — emitted by the Core Loop Orchestrator when it hands the generated `DungeonData` to the Expedition Resolver.
- **EventBus.seed_matured** — the signal that triggers dungeon generation in the orchestrator.

### 8.7 Debug Tools

The generator provides a debug inspection method:

```gdscript
## Returns a human-readable multi-line string describing the dungeon layout.
## Useful for console debugging and test assertions.
static func describe_dungeon(dungeon: DungeonData) -> String
```

Output format:
```
Dungeon [seed_abc123] | Element: FLAME | Difficulty: 0.72
Rooms (8):
  [0] ENTRANCE  diff=0.00  loot={}  pos=(0,0)
  [1] COMBAT    diff=0.31  loot={GOLD:0.6,ESSENCE:0.3,FRAGMENTS:0.1}  pos=(120,0)
  [2] TREASURE  diff=0.28  loot={GOLD:0.5,ESSENCE:0.2,...}  pos=(120,120)
  ...
Edges (9): (0,1) (1,2) (1,3) (2,4) (3,4) (3,5) (4,6) (5,6) (6,7)
Critical path: 0 → 1 → 3 → 5 → 6 → 7
Entry: 0 | Boss: 7
```

### 8.8 How to Add a New Room Type

1. Add the new type to `Enums.RoomType` in `src/models/enums.gd`.
2. Add a base weight entry in `ROOM_TYPE_WEIGHTS` in `dungeon_generator.gd`.
3. Add a difficulty modifier in `ROOM_DIFF_MODIFIERS`.
4. Add a default loot bias dictionary in `ROOM_LOOT_DEFAULTS`.
5. Add element bias entries in `ELEMENT_WEIGHT_BIAS` if the new type should be affected by element affinity.
6. Add placement constraints (e.g., "only on branches" for SECRET-like types) in `_assign_room_types()`.
7. Add tests verifying the new type appears in generated dungeons with expected frequency.

### 8.9 How to Add a New Element

1. Add the element to `Enums.Element` in `src/models/enums.gd`.
2. Add a biome difficulty multiplier in `BIOME_DIFFICULTY`.
3. Add weight bias entries in `ELEMENT_WEIGHT_BIAS`.
4. Add tests verifying the new element produces expected room type distributions.

---

## Section 9 · Assumptions

| # | Assumption | Impact if Wrong |
|---|-----------|-----------------|
| 1 | `DeterministicRNG` (TASK-002) is implemented and tested, providing all methods listed in the dependency API: `seed_string()`, `seed_int()`, `randf()`, `randi()`, `randi_range()`, `shuffle()`, `pick()`, `weighted_pick()`. | Generator cannot function without seeded RNG. Would need to implement a temporary RNG stub. |
| 2 | `DungeonData` and `RoomData` (TASK-005) are implemented with all properties and methods listed in the dependency API, including `rooms`, `edges`, `entry_room_index`, `boss_room_index`, `get_adjacent()`, `get_path_to_boss()`. | Generator output format would not match consumer expectations. Would need to create compatible stubs. |
| 3 | `SeedData` (TASK-004) is implemented with all properties listed: `id`, `rarity`, `element`, `phase`, `vigor`, `dungeon_traits`, `mutation_slots`. | Generator input parsing would fail. Would need seed stubs for testing. |
| 4 | `Enums` (TASK-003) is implemented with `RoomType`, `Element`, `SeedRarity`, `SeedPhase`, and `Currency` enums with the ordinal values matching the dependency API. | Type comparisons and dictionary lookups would fail. |
| 5 | Dungeons cap at 28 rooms maximum (GDD §5.4, Vigor 100 range 20–28). The generator will not be asked to produce dungeons larger than 31 rooms (28 + 3 from Legendary rarity). | If room counts exceed 31, grid placement may need larger grids, and MST performance should still be fine (O(n²) for n≤31 is trivial). |
| 6 | Prim's algorithm with Euclidean distance produces aesthetically pleasing graphs for abstract dungeon maps. | If the map UI team (TASK-018) finds layouts visually poor, room placement may need to switch to a different strategy (e.g., force-directed with fixed iteration count). |
| 7 | Linear interpolation between GDD §5.4 breakpoints is acceptable for parameter scaling. | If designers want non-linear curves (exponential, sigmoid), the interpolation function must be replaced. |
| 8 | The `weighted_pick()` method on `DeterministicRNG` accepts parallel arrays of items and weights. | If the API differs, the room type selection code must be adapted to the actual API signature. |
| 9 | `Vector2i` is used for edges (pairs of room indices) and `Vector2` for abstract positions. These are both available in Godot 4.6 GDScript. | If only `Vector2` is available, edge storage would use `Vector2` with integer casting. |
| 10 | SECRET rooms being branch-only is a hard GDD requirement (§5.5). There are always enough branch rooms to place the required SECRET count, or the count degrades gracefully to 0. | If the MST produces a path graph (no branches), zero SECRET rooms are placed even if the target count is higher. |
| 11 | The `mutation_slots` array on `SeedData` contains objects with a `difficulty_value: float` property (or equivalent) that can be summed for the mutation difficulty contribution. | If mutation objects have a different structure, the difficulty sum calculation must be adapted. |
| 12 | The generator does not need to support hot-reloading or mid-generation cancellation. A single `generate()` call runs to completion synchronously. | If async generation is needed for very large dungeons, the architecture would need to change to a coroutine/yield pattern. |
| 13 | All room types in `Enums.RoomType` have sequential ordinal values starting from 0 (ENTRANCE=0, COMBAT=1, TREASURE=2, TRAP=3, PUZZLE=4, REST=5, BOSS=6, SECRET=7). | If ordinal values differ, dictionary lookups by enum value must be updated. |
| 14 | The GUT testing framework (v9.x+) is pre-installed and functional. Tests extend `GutTest` and use `assert_eq`, `assert_true`, `assert_not_null`, etc. | Tests will not compile without GUT. |
| 15 | Godot 4.6 supports typed arrays (`Array[RoomData]`, `Array[Vector2i]`) in variable declarations and function parameters. | If typed arrays are not fully supported, fallback to untyped arrays with runtime casts. |
| 16 | The `DungeonData` class allows direct property assignment (e.g., `dungeon.rooms = rooms_array`). If properties are read-only with setter methods, the assignment code must use setters. | Generator output construction would need API changes. |
| 17 | Floating-point arithmetic in GDScript 4.6 is IEEE 754 compliant and produces identical results across Windows, macOS, and Linux for the operations used (addition, multiplication, division, floor). | If cross-platform floating-point divergence occurs, difficulty values may differ by ULP-level amounts. The generator avoids float-dependent branching to mitigate this. |

---

## Section 10 · Security & Anti-Cheat

> **Context:** The generator produces the authoritative dungeon data that determines encounter difficulty, loot distribution, and completion state. Manipulating generation inputs or outputs can grant unfair advantages in an idle/RPG economy.

### Threat 1: Seed ID Manipulation for Favorable Dungeons

| Field | Detail |
|-------|--------|
| **Threat** | A player crafts seed IDs that produce dungeons with disproportionately high TREASURE rooms, low difficulty, or premium loot bias — effectively "mining" for optimal seeds. |
| **Exploit Description** | Since generation is deterministic, a player could brute-force seed IDs offline, testing millions of combinations to find seeds that produce TREASURE-heavy, low-difficulty dungeons with ARTIFACT bias. |
| **Attack Vector** | Client-side seed creation or modification of saved seed data. |
| **Impact** | Economy inflation — player generates premium currency at rates far beyond intended design. Undermines progression pacing. |
| **Risk Level** | Medium (requires technical knowledge, but determinism makes it feasible) |
| **Mitigations** | 1. Seed IDs are server-assigned (or assigned by a trusted SeedFactory service) — players cannot choose arbitrary IDs. 2. Seed rarity gates the reward ceiling — even an "optimal" Common seed has lower loot potential than a random Legendary. 3. Vigor caps per-room difficulty and loot quality. 4. Rate limiting on seed acquisition prevents rapid brute-forcing. 5. Economy monitoring detects statistical anomalies in loot distribution per player. |
| **This Task's Role** | Implement the generation algorithm honestly — no hidden backdoors, no special-case seed IDs. Document that seed ID assignment is a security boundary owned by the SeedFactory (future task). |

### Threat 2: RNG Seed Tampering

| Field | Detail |
|-------|--------|
| **Threat** | A player modifies the RNG seed (e.g., by editing save data) to force the generator to produce a known-favorable dungeon layout. |
| **Exploit Description** | By changing `seed_id` or `phase` in the save file, the player can regenerate a dungeon with a pre-computed favorable layout — more treasure, fewer combat rooms, easier boss. |
| **Attack Vector** | Save file editing (JSON/binary modification). |
| **Impact** | Same as Threat 1 — economy exploitation, progression bypass. |
| **Risk Level** | Medium (save files are typically accessible) |
| **Mitigations** | 1. Save file integrity validation (checksums, HMAC) handled by TASK-009 (Save/Load Manager). 2. The generator itself is deterministic and stateless — it cannot detect tampering. 3. Server-side validation (future) can regenerate the dungeon from the seed and compare against the player's claimed dungeon state. 4. Anti-cheat monitoring can flag players whose dungeon distributions deviate from expected probabilities. |
| **This Task's Role** | Ensure the generator is purely functional — identical inputs always produce identical outputs. This property enables server-side verification. Do NOT add any non-deterministic "anti-tamper" logic that would break reproducibility. |

### Threat 3: Difficulty Manipulation via Trait Injection

| Field | Detail |
|-------|--------|
| **Threat** | A player modifies `dungeon_traits` to set `hazard_frequency: 0.0` and `room_variety: 0.0`, producing a dungeon with zero TRAP rooms and concentrated COMBAT (which their party is optimized for). |
| **Exploit Description** | By editing the trait dictionary on a SeedData object before generation, the player can eliminate undesirable room types and concentrate loot bias. |
| **Attack Vector** | Memory editing (Cheat Engine) or save file modification. |
| **Impact** | Reduced dungeon diversity, optimized farming routes, undermining the trait system's purpose. |
| **Risk Level** | Low-Medium (traits have bounded effects — even 0.0 hazard frequency only removes the bonus, not the base TRAP weight) |
| **Mitigations** | 1. Traits are clamped to valid ranges: `room_variety` ∈ [0.0, 1.0], `hazard_frequency` ∈ [0.0, 1.0], `loot_bias` ∈ valid currency names. 2. The generator applies element bias independently of traits, so FROST dungeons always have elevated TRAP weight regardless of hazard_frequency. 3. Save integrity (TASK-009). 4. Trait validation before generation — reject or clamp out-of-range values. |
| **This Task's Role** | Implement trait clamping and validation. Reject unknown trait keys. Log warnings for out-of-range values. |

### Threat 4: Graph Structure Exploitation

| Field | Detail |
|-------|--------|
| **Threat** | A modified client skips non-critical-path rooms and marks them as cleared, or modifies the edge list to create shortcuts that don't exist in the generated graph. |
| **Exploit Description** | By editing `DungeonData.edges` or `RoomData.is_cleared` flags in memory, a player could skip difficult rooms or claim loot from rooms they never actually explored. |
| **Attack Vector** | Memory editing during expedition resolution. |
| **Impact** | Free loot, skipped difficulty, accelerated progression. |
| **Risk Level** | Medium (requires real-time memory editing) |
| **Mitigations** | 1. The Expedition Resolver (TASK-015) should validate all room transitions against `get_adjacent()` — it should be impossible to "jump" to a non-adjacent room. 2. Server-side replay validation can regenerate the dungeon and verify the claimed expedition path. 3. Dungeon data should be treated as immutable after generation — only `is_cleared` flags should change, and only through the Expedition Resolver. |
| **This Task's Role** | Produce a well-formed graph with valid adjacency. Provide `get_adjacent()` (via DungeonData, TASK-005) for the resolver to validate transitions. Document that generated DungeonData should be treated as read-only except for `is_cleared` flags. |

### Threat 5: Denial of Service via Extreme Parameters

| Field | Detail |
|-------|--------|
| **Threat** | A crafted SeedData with extreme values (vigor=999999, rarity=100) causes the generator to allocate excessive memory or loop indefinitely. |
| **Exploit Description** | If parameter validation is absent, the generator could attempt to create millions of rooms, exhaust memory, or enter infinite loops in MST construction. |
| **Attack Vector** | Modified save data or crafted API calls. |
| **Impact** | Game crash, device freeze, potential memory exhaustion on mobile. |
| **Risk Level** | Low (requires intentional abuse) |
| **Mitigations** | 1. Vigor is clamped to [1, 100] at the start of generation. 2. Room count is clamped to [3, 31] after calculation. 3. Rarity and phase are validated against enum range. 4. The grid placement algorithm has a fixed maximum grid size (8×8 = 64 cells), preventing unbounded room placement. 5. MST runs in O(n²) time for n rooms — at n=31 this is ~1000 iterations, trivially fast. |
| **This Task's Role** | Implement input validation and parameter clamping at the start of `generate()` and `generate_from_params()`. Log warnings for out-of-range inputs. |

---

## Section 11 · Best Practices

### BP-01: Deterministic RNG Discipline

**Do:** Route every random decision through the single `DeterministicRNG` instance created at the start of `generate()`.
**Don't:** Call `randf()`, `randi()`, or any global Godot RNG function. Don't create multiple RNG instances.
**Why:** A single seeded RNG instance guarantees that the same seed always produces the same dungeon. Multiple RNG instances or global state breaks determinism.

### BP-02: Stateless Service Pattern

**Do:** Create all state (RNG, intermediate arrays, working data) inside `generate()` and return it as the `DungeonData` result.
**Don't:** Store state in member variables that persist between calls.
**Why:** Stateless services are trivially thread-safe, trivially testable, and never produce spooky action-at-a-distance bugs where a previous generation affects the next one.

### BP-03: Validate Inputs Early, Fail Fast

**Do:** Clamp vigor to [1, 100], validate enum ranges, and check trait keys at the top of `generate()` before any computation.
**Don't:** Let invalid inputs propagate into the algorithm and produce corrupt output silently.
**Why:** Early validation produces clear error messages. Late failures in MST construction or room assignment are nearly impossible to debug.

### BP-04: Canonical Edge Representation

**Do:** Always store edges as `Vector2i(min(a, b), max(a, b))`.
**Don't:** Store edges as `(a, b)` without ordering, allowing both `(2, 5)` and `(5, 2)` to exist.
**Why:** Canonical representation makes duplicate detection trivial (set membership) and simplifies serialization and comparison.

### BP-05: Separate Placement from Assignment

**Do:** First place rooms on the grid and connect them, THEN assign types, difficulties, and loot.
**Don't:** Assign room types during placement or connect rooms based on their type.
**Why:** Separating structural generation from content assignment makes each stage independently testable and tunable.

### BP-06: Use Constants for Tuning Values

**Do:** Declare all weights, multipliers, thresholds, and breakpoints as `const` dictionaries/arrays at the top of the file.
**Don't:** Hardcode magic numbers inside algorithm functions.
**Why:** Constants are self-documenting, easily tunable, and grep-able. A designer can adjust all balance parameters without reading algorithm code.

### BP-07: BFS for Path Validation, Not DFS

**Do:** Use BFS (breadth-first search) for critical path finding and connectivity validation.
**Don't:** Use recursive DFS, which can stack-overflow on large graphs in GDScript.
**Why:** BFS is iterative (no stack overflow risk), finds shortest paths (useful for critical path), and has predictable memory usage.

### BP-08: Test Determinism Explicitly

**Do:** Write tests that call `generate()` twice with the same seed and assert byte-identical output.
**Don't:** Assume determinism is "probably fine" because you used a seeded RNG.
**Why:** Subtle non-determinism (hash ordering, floating-point platform differences, accidentally reading a global) is the #1 cause of desyncs in deterministic systems.

### BP-09: Prefer Integer Arithmetic for Branching Decisions

**Do:** Use integer comparisons for decisions that affect graph structure (room count, edge count, room type selection).
**Don't:** Use floating-point comparisons like `if randf() < 0.5` for structural decisions.
**Why:** Integer arithmetic is identical across platforms. Floating-point comparison can differ by ULP between x86 and ARM, breaking cross-platform determinism.

### BP-10: Document the Pipeline Stage in Each Method

**Do:** Name internal methods to reflect their pipeline stage: `_parse_seed()`, `_calculate_params()`, `_generate_graph()`, `_assign_types()`, `_assign_difficulty()`, `_assign_loot()`, `_validate()`.
**Don't:** Use generic names like `_step1()`, `_process_data()`, `_helper()`.
**Why:** Pipeline-stage names make the code self-documenting and make it trivial to find the code for a specific generation stage.

### BP-11: Fallback Dungeon for Safety

**Do:** If validation fails (broken connectivity, missing boss room), return a minimal valid fallback dungeon (3 rooms: ENTRANCE → COMBAT → BOSS).
**Don't:** Crash, return null, or return an invalid DungeonData that will break downstream systems.
**Why:** A fallback dungeon is always playable. A null or invalid dungeon crashes the Expedition Resolver, the Map UI, and the save system.

### BP-12: Type Hints Everywhere

**Do:** Type every variable, parameter, return value, and array element. Use `Array[RoomData]`, `Dictionary`, `Vector2i`, etc.
**Don't:** Use bare `var` or `Array` without element types.
**Why:** Static typing catches bugs at parse time, enables editor autocomplete, and serves as documentation.

### BP-13: Log Pipeline Stage Completion

**Do:** Add `print("[DungeonGen] Stage N complete: ...")` debug output at the end of each pipeline stage (guarded by a `DEBUG` flag or removed before merge).
**Don't:** Add no logging and make debugging a black-box guessing game.
**Why:** When a generated dungeon looks wrong, stage-by-stage logging lets you pinpoint exactly where the algorithm diverged from expectations.

### BP-14: Keep the Service File Under 600 Lines

**Do:** Extract reusable utilities (e.g., `_lerp_from_breakpoints()`, `_bfs_path()`) into clearly named private methods within the same file.
**Don't:** Let the main `generate()` method grow to 300+ lines or create separate utility files for what should be private implementation details.
**Why:** A single file under 600 lines is readable in one sitting. Private methods stay co-located with their caller for easy navigation.

---

## Section 12 · Troubleshooting

### Issue 1: Generated dungeon differs between runs with the same seed

**Symptoms:** Two calls to `generate()` with identical `SeedData` produce `DungeonData` with different rooms, edges, or difficulty values.

**Causes:**
- A global RNG function (`randf()`, `randi()`) is called somewhere in the pipeline instead of the local `DeterministicRNG` instance.
- The `DeterministicRNG` is not seeded consistently — e.g., `seed_string()` is called with a value that includes a timestamp or frame count.
- Dictionary iteration order is non-deterministic and is being used to drive generation decisions.
- A floating-point comparison produces different results on different platforms due to rounding differences.

**Resolution:**
1. Grep the generator file for `randf`, `randi`, `randi_range` — none should appear without the RNG instance prefix.
2. Verify the RNG seed is exactly `seed_id + str(phase)` — no additional inputs.
3. Replace any `for key in dictionary` loops that drive generation logic with sorted-key iteration: `for key in dictionary.keys().sorted()`.
4. Replace any float-dependent branching with integer comparisons where possible.

### Issue 2: Boss room is unreachable from entry

**Symptoms:** `DungeonData.get_path_to_boss()` returns an empty array, or the Expedition Resolver cannot reach the boss.

**Causes:**
- MST construction failed to include all rooms (off-by-one in Prim's algorithm).
- The boss room index was set incorrectly (not `room_count - 1`).
- A bug in shortcut edge addition disconnected the graph (should be impossible if MST is correct, but edge removal could cause this).

**Resolution:**
1. Run the `_validate()` stage in isolation — it performs BFS from entry and checks all rooms are visited.
2. Log the MST edges separately from shortcut edges to isolate which stage introduced the disconnection.
3. Verify `boss_room_index = len(rooms) - 1` and that the MST includes this index.
4. If MST is correct but shortcuts broke something, check that shortcuts only ADD edges, never remove them.

### Issue 3: Room type distribution is skewed far from expected weights

**Symptoms:** A FLAME dungeon produces zero COMBAT rooms, or a FROST dungeon has no TRAP rooms despite the element bias.

**Causes:**
- Element bias weights are being subtracted instead of added.
- The `weighted_pick()` call receives weights in the wrong order (mismatched with the items array).
- Room variety trait is amplifying the wrong weight (e.g., amplifying the minimum instead of the maximum at low variety).
- Fixed-type rooms (ENTRANCE, BOSS, REST, SECRET) consume most of the room count, leaving too few rooms for weighted selection.

**Resolution:**
1. Log the final weight array after applying element bias and variety modifier — verify it matches expectations.
2. Verify the items array and weights array are parallel (same length, matching indices).
3. For small dungeons (3–5 rooms), accept that there may be zero weighted-selection rooms after fixed types are placed.
4. Test with `room_variety: 0.5` (neutral) to isolate whether the issue is in base weights or variety modification.

### Issue 4: Generator takes longer than 50ms for large dungeons

**Symptoms:** `generate()` call for a Vigor-100 Legendary Bloom seed takes >50ms, causing a visible frame hitch.

**Causes:**
- MST construction is using O(n³) naive implementation instead of O(n²) Prim's.
- Room placement is retrying excessively due to grid collisions (all cells occupied).
- BFS validation is running multiple times unnecessarily.

**Resolution:**
1. Profile the generator with Godot's built-in profiler to identify the bottleneck stage.
2. Ensure Prim's algorithm uses a simple priority tracking (not a full heap — unnecessary for n≤31).
3. Verify the grid size is large enough for the maximum room count (8×8 = 64 cells for ≤31 rooms).
4. Run BFS once for connectivity, not once per room.

### Issue 5: Fallback dungeon returned unexpectedly

**Symptoms:** The generator returns a 3-room linear dungeon (ENTRANCE → COMBAT → BOSS) for seeds that should produce larger dungeons.

**Causes:**
- Input validation is rejecting valid inputs (e.g., clamping vigor too aggressively).
- The validation stage is failing on a valid dungeon due to a bug in BFS implementation.
- An exception in one of the pipeline stages is being caught and triggering the fallback path.

**Resolution:**
1. Check for push_error() messages in the Godot output — the generator logs errors before returning the fallback.
2. Run `generate()` with debug logging enabled to see which pipeline stage triggered the fallback.
3. Test the BFS validation in isolation with a known-good graph to verify it correctly identifies connected graphs.
4. Verify enum values match expected ordinals — a mismatched `Enums.SeedPhase.BLOOM` value could produce incorrect room counts that fail validation.

### Issue 6: Loot bias values don't sum to 1.0

**Symptoms:** Room loot_bias dictionaries have weights that sum to more or less than 1.0 after trait modification.

**Causes:**
- The renormalization step after applying the `loot_bias` trait is missing or incorrect.
- The trait adds +0.2 to a currency that doesn't exist in the room's default bias dictionary, creating an unbalanced total.
- Floating-point accumulation error produces a sum of 0.9999... or 1.0001...

**Resolution:**
1. Verify the renormalization code: `total = sum(weights.values()); for key in weights: weights[key] /= total`.
2. When adding the trait bias to a currency not in the default, initialize it to 0.0 first.
3. Accept floating-point imprecision up to ±0.001 — downstream consumers should handle this gracefully.

---

## Section 13 · Acceptance Criteria

All criteria must pass before this task is considered complete. PAC = Playtesting Acceptance Criterion. BAC = Balance Acceptance Criterion.

### Core Service Structure

- [ ] **AC-001:** File `src/services/dungeon_generator.gd` exists and is parseable by Godot 4.6 with zero warnings.
- [ ] **AC-002:** `DungeonGeneratorService` extends `RefCounted` and declares `class_name DungeonGeneratorService`.
- [ ] **AC-003:** `generate(seed_data: SeedData) -> DungeonData` method exists and is callable.
- [ ] **AC-004:** `generate_from_params(seed_id: String, rarity: int, element: int, phase: int, vigor: int, traits: Dictionary) -> DungeonData` method exists and is callable.
- [ ] **AC-005:** Both `generate()` and `generate_from_params()` produce identical output for equivalent inputs.
- [ ] **AC-006:** The service has zero member variable state between calls — fully stateless.
- [ ] **AC-007:** All public methods and constants have `##` doc comments.

### Seed Parsing

- [ ] **AC-008:** The generator correctly extracts `rarity`, `element`, `phase`, `vigor`, and `dungeon_traits` from `SeedData`.
- [ ] **AC-009:** Missing `dungeon_traits` keys default to: `room_variety=0.5`, `loot_bias="gold"`, `hazard_frequency=0.2`.
- [ ] **AC-010:** The RNG is seeded from `seed_id + str(phase)` — verified by determinism tests.

### Parameter Calculation

- [ ] **AC-011:** SPORE phase produces base room count of 3.
- [ ] **AC-012:** SPROUT phase produces base room count of 5.
- [ ] **AC-013:** BUD phase produces base room count of 8.
- [ ] **AC-014:** BLOOM phase produces base room count of 12.
- [ ] **AC-015:** COMMON rarity adds 0 bonus rooms.
- [ ] **AC-016:** UNCOMMON rarity adds 1 bonus room.
- [ ] **AC-017:** RARE rarity adds 2 bonus rooms.
- [ ] **AC-018:** EPIC rarity adds 3 bonus rooms.
- [ ] **AC-019:** LEGENDARY rarity adds 3 bonus rooms.
- [ ] **AC-020:** Vigor bonus is `floor(vigor / 33)`, producing 0–3 additional rooms.
- [ ] **AC-021:** Final room count is clamped to the GDD §5.4 vigor-scaled range.
- [ ] **AC-022:** Branching factor is correctly interpolated from vigor breakpoints (Vigor 1→0.1, Vigor 50→0.3, Vigor 100→0.5).
- [ ] **AC-023:** Biome difficulty multiplier is correct per element: TERRA=1.0, FLAME=1.1, FROST=1.05, ARCANE=1.15, SHADOW=1.3.

### Graph Generation

- [ ] **AC-024:** All rooms are placed at abstract 2D positions using the seeded RNG.
- [ ] **AC-025:** A minimum spanning tree connects all rooms (Prim's algorithm).
- [ ] **AC-026:** MST guarantees full connectivity — BFS from room 0 visits every room.
- [ ] **AC-027:** `floor(branching_factor × room_count)` shortcut edges are added after MST construction.
- [ ] **AC-028:** No duplicate edges exist in the final edge list.
- [ ] **AC-029:** All edges are stored in canonical form: `Vector2i(min(a,b), max(a,b))`.
- [ ] **AC-030:** `entry_room_index` is always 0.
- [ ] **AC-031:** `boss_room_index` is always `room_count - 1`.

### Room Type Assignment

- [ ] **AC-032:** Room 0 is always ENTRANCE.
- [ ] **AC-033:** Last room is always BOSS.
- [ ] **AC-034:** For room count ≥ 4, exactly 1 REST room is placed. For room count ≥ 8, exactly 2 REST rooms are placed.
- [ ] **AC-035:** REST rooms are positioned at approximately 40% and 70% of the critical path length.
- [ ] **AC-036:** SECRET rooms are placed only on branch rooms (not on the critical path).
- [ ] **AC-037:** SECRET room count scales: 0 for ≤5 rooms, 1 for 6–10, 2 for 11–18, 3 for 19+.
- [ ] **AC-038:** Remaining rooms use weighted random selection with base weights: COMBAT=40, TREASURE=20, TRAP=15, PUZZLE=15, REST=10.
- [ ] **AC-039:** FLAME element adds +15 to COMBAT weight.
- [ ] **AC-040:** FROST element adds +15 to TRAP weight.
- [ ] **AC-041:** ARCANE element adds +10 to PUZZLE and +5 to TREASURE weight.
- [ ] **AC-042:** SHADOW element adds +10 to TRAP and +5 to COMBAT weight.
- [ ] **AC-043:** TERRA element leaves weights unmodified.
- [ ] **AC-044:** `room_variety` trait modulates weight distribution (high variety → flatter, low variety → more concentrated).
- [ ] **AC-045:** `hazard_frequency` trait increases TRAP weight by `hazard_frequency × 20`.

### Difficulty Assignment

- [ ] **AC-046:** Base difficulty = `vigor × biome_multiplier / 100.0`.
- [ ] **AC-047:** Depth factor ranges from 0.0 (ENTRANCE) to 1.0 (BOSS) along the critical path.
- [ ] **AC-048:** Room type modifiers are applied: ENTRANCE=0.0, COMBAT=1.0, TREASURE=0.7, TRAP=0.9, PUZZLE=0.6, REST=0.0, BOSS=1.5, SECRET=0.8.
- [ ] **AC-049:** Final formula: `base_diff × (0.3 + 0.7 × depth_factor) × type_modifier`.
- [ ] **AC-050:** ENTRANCE rooms always have difficulty 0.0.
- [ ] **AC-051:** REST rooms always have difficulty 0.0.
- [ ] **AC-052:** BOSS room has the highest difficulty in the dungeon.
- [ ] **AC-053:** `DungeonData.difficulty_rating` = average of non-zero room difficulties + mutation difficulty sum.

### Loot Bias Assignment

- [ ] **AC-054:** Each room has a `loot_bias: Dictionary` with currency weights.
- [ ] **AC-055:** ENTRANCE and REST rooms have empty loot_bias `{}`.
- [ ] **AC-056:** COMBAT rooms default to `{GOLD: 0.6, ESSENCE: 0.3, FRAGMENTS: 0.1}`.
- [ ] **AC-057:** BOSS rooms default to `{ARTIFACTS: 0.4, GOLD: 0.3, ESSENCE: 0.2, FRAGMENTS: 0.1}`.
- [ ] **AC-058:** Seed `loot_bias` trait shifts weights by +0.2 to the named currency and renormalizes.
- [ ] **AC-059:** After renormalization, all non-empty loot_bias dictionaries have weights summing to approximately 1.0 (±0.001).

### Validation

- [ ] **AC-060:** BFS from entry to boss finds a valid path for every generated dungeon.
- [ ] **AC-061:** BFS from entry visits all rooms (full connectivity verified).
- [ ] **AC-062:** Exactly one ENTRANCE room exists.
- [ ] **AC-063:** At least one BOSS room exists.
- [ ] **AC-064:** If validation fails, a 3-room fallback dungeon (ENTRANCE → COMBAT → BOSS) is returned.
- [ ] **AC-065:** Validation failure produces a `push_error()` message.

### Determinism

- [ ] **AC-066:** Two calls to `generate()` with the same SeedData produce byte-identical DungeonData.
- [ ] **AC-067:** Determinism holds for rooms, edges, positions, difficulties, and loot biases.
- [ ] **AC-068:** No calls to global `randf()`, `randi()`, or `randi_range()` exist in the source file.
- [ ] **AC-069:** The same seed at SPORE and BLOOM phases produces different dungeons.
- [ ] **AC-070:** The same seed with different IDs produces different dungeons.

### Output Contract

- [ ] **AC-071:** `DungeonData.seed_id` matches the input seed's `id`.
- [ ] **AC-072:** `DungeonData.element` matches the input seed's `element`.
- [ ] **AC-073:** `DungeonData.rooms.size()` equals the calculated room count.
- [ ] **AC-074:** Every `RoomData.index` matches its position in the `rooms` array.
- [ ] **AC-075:** Every `RoomData.is_cleared` is `false` on fresh generation.
- [ ] **AC-076:** All edge indices are in range `[0, room_count)`.
- [ ] **AC-077:** The edge count is ≥ `room_count - 1` (MST minimum) and ≤ `room_count × (room_count - 1) / 2` (complete graph maximum).

### Input Validation

- [ ] **AC-078:** Vigor values outside [1, 100] are clamped and a warning is logged.
- [ ] **AC-079:** Invalid rarity/element/phase enum values trigger a warning and use defaults.
- [ ] **AC-080:** Trait values outside valid ranges are clamped: `room_variety` ∈ [0.0, 1.0], `hazard_frequency` ∈ [0.0, 1.0].
- [ ] **AC-081:** Unknown trait keys are ignored with a warning.

### Playtesting Acceptance Criteria (PACs)

- [ ] **PAC-001:** Generate a SPORE/COMMON/TERRA/Vigor-1 dungeon — verify 3 rooms, linear path, low difficulty.
- [ ] **PAC-002:** Generate a BLOOM/LEGENDARY/SHADOW/Vigor-100 dungeon — verify 18+ rooms, multiple branches, high difficulty, SECRET rooms present.
- [ ] **PAC-003:** Generate 100 FLAME dungeons — verify COMBAT rooms appear at higher frequency than the base 40%.
- [ ] **PAC-004:** Generate the same seed twice — verify byte-identical output.
- [ ] **PAC-005:** Generate the same seed at all four phases — verify four different dungeon layouts.

### Balance Acceptance Criteria (BACs)

- [ ] **BAC-001:** Average room count across 1000 random Vigor-50 BUD seeds is within [10, 14].
- [ ] **BAC-002:** BOSS room difficulty is always the highest in its dungeon (across 100 test dungeons).
- [ ] **BAC-003:** ENTRANCE and REST rooms always have difficulty 0.0 (across 100 test dungeons).
- [ ] **BAC-004:** The percentage of COMBAT rooms in FLAME dungeons (1000 samples) exceeds the percentage in TERRA dungeons by at least 5 percentage points.
- [ ] **BAC-005:** SECRET rooms never appear on the critical path (verified across 500 test dungeons).

---

## Section 14 · Testing Requirements

### 14.1 Test File: `tests/unit/test_dungeon_generator.gd`

```gdscript
## Unit tests for DungeonGeneratorService.
## Covers all 7 pipeline stages, determinism, input validation, and edge cases.
extends GutTest


# ─── Helpers ──────────────────────────────────────────────────────────

var _gen: DungeonGeneratorService


func before_each() -> void:
	_gen = DungeonGeneratorService.new()


func _make_seed(
	id: String,
	rarity: int,
	element: int,
	phase: int,
	vigor: int,
	traits: Dictionary
) -> SeedData:
	var sd := SeedData.new()
	sd.id = id
	sd.rarity = rarity
	sd.element = element
	sd.phase = phase
	sd.vigor = vigor
	sd.dungeon_traits = traits
	sd.mutation_slots = []
	return sd


func _count_room_type(dungeon: DungeonData, room_type: int) -> int:
	var count: int = 0
	for room: RoomData in dungeon.rooms:
		if room.type == room_type:
			count += 1
	return count


func _has_edge(dungeon: DungeonData, a: int, b: int) -> bool:
	var edge := Vector2i(mini(a, b), maxi(a, b))
	return dungeon.edges.has(edge)


func _bfs_reachable(dungeon: DungeonData, start: int) -> Array[int]:
	var visited: Array[int] = []
	var queue: Array[int] = [start]
	while queue.size() > 0:
		var current: int = queue.pop_front()
		if visited.has(current):
			continue
		visited.append(current)
		var neighbors: Array[int] = dungeon.get_adjacent(current)
		for neighbor: int in neighbors:
			if not visited.has(neighbor):
				queue.append(neighbor)
	return visited


func _is_on_critical_path(dungeon: DungeonData, room_index: int) -> bool:
	var path: Array[int] = dungeon.get_path_to_boss()
	return path.has(room_index)


# ─── Core Service Tests ──────────────────────────────────────────────

func test_service_extends_ref_counted() -> void:
	assert_is(_gen, RefCounted, "DungeonGeneratorService must extend RefCounted")


func test_generate_returns_dungeon_data() -> void:
	var seed_data := _make_seed("test_001", Enums.SeedRarity.COMMON, Enums.Element.TERRA, Enums.SeedPhase.SPORE, 10, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_not_null(result, "generate() must return a DungeonData instance")
	assert_is(result, DungeonData, "generate() must return DungeonData type")


func test_generate_from_params_returns_dungeon_data() -> void:
	var result: DungeonData = _gen.generate_from_params("test_002", Enums.SeedRarity.COMMON, Enums.Element.TERRA, Enums.SeedPhase.SPORE, 10, {})
	assert_not_null(result, "generate_from_params() must return a DungeonData instance")


func test_generate_and_generate_from_params_produce_identical_output() -> void:
	var traits: Dictionary = {"room_variety": 0.5, "loot_bias": "gold", "hazard_frequency": 0.2}
	var seed_data := _make_seed("match_test", Enums.SeedRarity.RARE, Enums.Element.FLAME, Enums.SeedPhase.BUD, 50, traits)
	var result_a: DungeonData = _gen.generate(seed_data)
	var result_b: DungeonData = _gen.generate_from_params("match_test", Enums.SeedRarity.RARE, Enums.Element.FLAME, Enums.SeedPhase.BUD, 50, traits)
	assert_eq(result_a.rooms.size(), result_b.rooms.size(), "Room counts must match")
	assert_eq(result_a.edges.size(), result_b.edges.size(), "Edge counts must match")
	for i: int in range(result_a.rooms.size()):
		assert_eq(result_a.rooms[i].type, result_b.rooms[i].type, "Room %d type must match" % i)
		assert_almost_eq(result_a.rooms[i].difficulty, result_b.rooms[i].difficulty, 0.001, "Room %d difficulty must match" % i)


# ─── Room Count Tests ────────────────────────────────────────────────

func test_spore_common_low_vigor_room_count() -> void:
	var seed_data := _make_seed("spore_test", Enums.SeedRarity.COMMON, Enums.Element.TERRA, Enums.SeedPhase.SPORE, 10, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_eq(result.rooms.size(), 3, "SPORE/COMMON/Vigor-10 should produce 3 rooms (base 3 + 0 rarity + 0 vigor)")


func test_sprout_uncommon_room_count() -> void:
	var seed_data := _make_seed("sprout_test", Enums.SeedRarity.UNCOMMON, Enums.Element.TERRA, Enums.SeedPhase.SPROUT, 20, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_eq(result.rooms.size(), 6, "SPROUT/UNCOMMON/Vigor-20 should produce 6 rooms (base 5 + 1 rarity + 0 vigor)")


func test_bud_rare_mid_vigor_room_count() -> void:
	var seed_data := _make_seed("bud_test", Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_eq(result.rooms.size(), 11, "BUD/RARE/Vigor-50 should produce 11 rooms (base 8 + 2 rarity + 1 vigor)")


func test_bloom_legendary_high_vigor_room_count() -> void:
	var seed_data := _make_seed("bloom_test", Enums.SeedRarity.LEGENDARY, Enums.Element.SHADOW, Enums.SeedPhase.BLOOM, 100, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_gte(result.rooms.size(), 18, "BLOOM/LEGENDARY/Vigor-100 should produce at least 18 rooms")
	assert_lte(result.rooms.size(), 28, "BLOOM/LEGENDARY/Vigor-100 should not exceed GDD cap of 28 rooms")


func test_room_count_never_below_three() -> void:
	var seed_data := _make_seed("min_test", Enums.SeedRarity.COMMON, Enums.Element.TERRA, Enums.SeedPhase.SPORE, 1, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_gte(result.rooms.size(), 3, "Minimum room count is 3")


func test_room_count_never_above_28() -> void:
	var seed_data := _make_seed("max_test", Enums.SeedRarity.LEGENDARY, Enums.Element.SHADOW, Enums.SeedPhase.BLOOM, 100, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_lte(result.rooms.size(), 28, "Maximum room count per GDD is 28")


# ─── Graph Connectivity Tests ────────────────────────────────────────

func test_all_rooms_reachable_from_entry() -> void:
	var seed_data := _make_seed("connect_test", Enums.SeedRarity.EPIC, Enums.Element.ARCANE, Enums.SeedPhase.BLOOM, 75, {})
	var result: DungeonData = _gen.generate(seed_data)
	var visited: Array[int] = _bfs_reachable(result, result.entry_room_index)
	assert_eq(visited.size(), result.rooms.size(), "All rooms must be reachable from entry")


func test_boss_reachable_from_entry() -> void:
	var seed_data := _make_seed("boss_path_test", Enums.SeedRarity.RARE, Enums.Element.FROST, Enums.SeedPhase.BUD, 60, {})
	var result: DungeonData = _gen.generate(seed_data)
	var path: Array[int] = result.get_path_to_boss()
	assert_gt(path.size(), 0, "Path to boss must exist")
	assert_eq(path[0], result.entry_room_index, "Path must start at entry")
	assert_eq(path[-1], result.boss_room_index, "Path must end at boss")


func test_entry_room_is_index_zero() -> void:
	var seed_data := _make_seed("entry_test", Enums.SeedRarity.COMMON, Enums.Element.TERRA, Enums.SeedPhase.SPROUT, 30, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_eq(result.entry_room_index, 0, "Entry room must be index 0")


func test_boss_room_is_last_index() -> void:
	var seed_data := _make_seed("boss_idx_test", Enums.SeedRarity.UNCOMMON, Enums.Element.FLAME, Enums.SeedPhase.BUD, 45, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_eq(result.boss_room_index, result.rooms.size() - 1, "Boss room must be the last index")


func test_no_duplicate_edges() -> void:
	var seed_data := _make_seed("dup_edge_test", Enums.SeedRarity.EPIC, Enums.Element.SHADOW, Enums.SeedPhase.BLOOM, 90, {})
	var result: DungeonData = _gen.generate(seed_data)
	var edge_set: Dictionary = {}
	for edge: Vector2i in result.edges:
		var key: String = "%d_%d" % [edge.x, edge.y]
		assert_false(edge_set.has(key), "Duplicate edge found: %s" % key)
		edge_set[key] = true


func test_edges_in_canonical_form() -> void:
	var seed_data := _make_seed("canon_test", Enums.SeedRarity.RARE, Enums.Element.ARCANE, Enums.SeedPhase.BUD, 55, {})
	var result: DungeonData = _gen.generate(seed_data)
	for edge: Vector2i in result.edges:
		assert_lte(edge.x, edge.y, "Edge (%d,%d) must have x <= y" % [edge.x, edge.y])


func test_edge_indices_in_valid_range() -> void:
	var seed_data := _make_seed("range_test", Enums.SeedRarity.LEGENDARY, Enums.Element.FLAME, Enums.SeedPhase.BLOOM, 80, {})
	var result: DungeonData = _gen.generate(seed_data)
	for edge: Vector2i in result.edges:
		assert_gte(edge.x, 0, "Edge index must be >= 0")
		assert_lt(edge.y, result.rooms.size(), "Edge index must be < room count")


func test_minimum_edge_count_is_mst() -> void:
	var seed_data := _make_seed("min_edge_test", Enums.SeedRarity.COMMON, Enums.Element.TERRA, Enums.SeedPhase.SPROUT, 20, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_gte(result.edges.size(), result.rooms.size() - 1, "Edge count must be at least room_count - 1 (MST)")


func test_shortcut_edges_added_for_high_branching() -> void:
	var seed_data := _make_seed("shortcut_test", Enums.SeedRarity.EPIC, Enums.Element.FLAME, Enums.SeedPhase.BLOOM, 100, {})
	var result: DungeonData = _gen.generate(seed_data)
	var mst_edges: int = result.rooms.size() - 1
	assert_gt(result.edges.size(), mst_edges, "High-vigor dungeon should have shortcut edges beyond MST")


# ─── Room Type Assignment Tests ──────────────────────────────────────

func test_entrance_is_always_room_zero() -> void:
	var seed_data := _make_seed("entrance_test", Enums.SeedRarity.RARE, Enums.Element.FROST, Enums.SeedPhase.BUD, 50, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_eq(result.rooms[0].type, Enums.RoomType.ENTRANCE, "Room 0 must be ENTRANCE")


func test_boss_is_always_last_room() -> void:
	var seed_data := _make_seed("boss_type_test", Enums.SeedRarity.UNCOMMON, Enums.Element.ARCANE, Enums.SeedPhase.SPROUT, 35, {})
	var result: DungeonData = _gen.generate(seed_data)
	var last_idx: int = result.rooms.size() - 1
	assert_eq(result.rooms[last_idx].type, Enums.RoomType.BOSS, "Last room must be BOSS")


func test_rest_room_placed_when_four_or_more_rooms() -> void:
	var seed_data := _make_seed("rest_4_test", Enums.SeedRarity.UNCOMMON, Enums.Element.TERRA, Enums.SeedPhase.SPORE, 15, {})
	var result: DungeonData = _gen.generate(seed_data)
	if result.rooms.size() >= 4:
		var rest_count: int = _count_room_type(result, Enums.RoomType.REST)
		assert_gte(rest_count, 1, "Dungeons with 4+ rooms must have at least 1 REST room")


func test_two_rest_rooms_for_eight_or_more_rooms() -> void:
	var seed_data := _make_seed("rest_8_test", Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
	var result: DungeonData = _gen.generate(seed_data)
	if result.rooms.size() >= 8:
		var rest_count: int = _count_room_type(result, Enums.RoomType.REST)
		assert_eq(rest_count, 2, "Dungeons with 8+ rooms must have exactly 2 REST rooms")


func test_exactly_one_entrance() -> void:
	var seed_data := _make_seed("one_entr_test", Enums.SeedRarity.EPIC, Enums.Element.SHADOW, Enums.SeedPhase.BLOOM, 80, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_eq(_count_room_type(result, Enums.RoomType.ENTRANCE), 1, "Exactly one ENTRANCE room")


func test_exactly_one_boss() -> void:
	var seed_data := _make_seed("one_boss_test", Enums.SeedRarity.EPIC, Enums.Element.SHADOW, Enums.SeedPhase.BLOOM, 80, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_eq(_count_room_type(result, Enums.RoomType.BOSS), 1, "Exactly one BOSS room")


func test_secret_rooms_on_branches_only() -> void:
	for i: int in range(50):
		var seed_data := _make_seed("secret_branch_%d" % i, Enums.SeedRarity.EPIC, Enums.Element.ARCANE, Enums.SeedPhase.BLOOM, 80, {})
		var result: DungeonData = _gen.generate(seed_data)
		for room: RoomData in result.rooms:
			if room.type == Enums.RoomType.SECRET:
				assert_false(_is_on_critical_path(result, room.index), "SECRET room %d must not be on critical path (seed %d)" % [room.index, i])


func test_flame_increases_combat_weight() -> void:
	var flame_combat_total: int = 0
	var terra_combat_total: int = 0
	var room_total: int = 0
	for i: int in range(100):
		var flame_seed := _make_seed("flame_%d" % i, Enums.SeedRarity.RARE, Enums.Element.FLAME, Enums.SeedPhase.BUD, 50, {})
		var terra_seed := _make_seed("terra_%d" % i, Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
		var flame_result: DungeonData = _gen.generate(flame_seed)
		var terra_result: DungeonData = _gen.generate(terra_seed)
		flame_combat_total += _count_room_type(flame_result, Enums.RoomType.COMBAT)
		terra_combat_total += _count_room_type(terra_result, Enums.RoomType.COMBAT)
		room_total += flame_result.rooms.size()
	assert_gt(flame_combat_total, terra_combat_total, "FLAME element should produce more COMBAT rooms than TERRA across 100 seeds")


func test_frost_increases_trap_weight() -> void:
	var frost_trap_total: int = 0
	var terra_trap_total: int = 0
	for i: int in range(100):
		var frost_seed := _make_seed("frost_%d" % i, Enums.SeedRarity.RARE, Enums.Element.FROST, Enums.SeedPhase.BUD, 50, {})
		var terra_seed := _make_seed("terra_t_%d" % i, Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
		frost_trap_total += _count_room_type(_gen.generate(frost_seed), Enums.RoomType.TRAP)
		terra_trap_total += _count_room_type(_gen.generate(terra_seed), Enums.RoomType.TRAP)
	assert_gt(frost_trap_total, terra_trap_total, "FROST element should produce more TRAP rooms than TERRA across 100 seeds")


# ─── Difficulty Tests ────────────────────────────────────────────────

func test_entrance_difficulty_is_zero() -> void:
	var seed_data := _make_seed("diff_entr_test", Enums.SeedRarity.RARE, Enums.Element.FLAME, Enums.SeedPhase.BUD, 70, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_almost_eq(result.rooms[0].difficulty, 0.0, 0.001, "ENTRANCE difficulty must be 0.0")


func test_rest_difficulty_is_zero() -> void:
	var seed_data := _make_seed("diff_rest_test", Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
	var result: DungeonData = _gen.generate(seed_data)
	for room: RoomData in result.rooms:
		if room.type == Enums.RoomType.REST:
			assert_almost_eq(room.difficulty, 0.0, 0.001, "REST room difficulty must be 0.0")


func test_boss_has_highest_difficulty() -> void:
	var seed_data := _make_seed("diff_boss_test", Enums.SeedRarity.EPIC, Enums.Element.SHADOW, Enums.SeedPhase.BLOOM, 80, {})
	var result: DungeonData = _gen.generate(seed_data)
	var boss_diff: float = result.rooms[result.boss_room_index].difficulty
	for room: RoomData in result.rooms:
		if room.index != result.boss_room_index:
			assert_lte(room.difficulty, boss_diff, "No room should exceed boss difficulty")


func test_shadow_higher_difficulty_than_terra() -> void:
	var shadow_seed := _make_seed("diff_shadow", Enums.SeedRarity.RARE, Enums.Element.SHADOW, Enums.SeedPhase.BUD, 50, {})
	var terra_seed := _make_seed("diff_terra", Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
	var shadow_result: DungeonData = _gen.generate(shadow_seed)
	var terra_result: DungeonData = _gen.generate(terra_seed)
	assert_gt(shadow_result.difficulty_rating, terra_result.difficulty_rating, "SHADOW dungeons should have higher difficulty than TERRA at same vigor")


func test_difficulty_increases_with_vigor() -> void:
	var low_seed := _make_seed("diff_low_vig", Enums.SeedRarity.COMMON, Enums.Element.TERRA, Enums.SeedPhase.BUD, 10, {})
	var high_seed := _make_seed("diff_high_vig", Enums.SeedRarity.COMMON, Enums.Element.TERRA, Enums.SeedPhase.BUD, 90, {})
	var low_result: DungeonData = _gen.generate(low_seed)
	var high_result: DungeonData = _gen.generate(high_seed)
	assert_gt(high_result.difficulty_rating, low_result.difficulty_rating, "Higher vigor should produce higher dungeon difficulty")


func test_difficulty_rating_is_set() -> void:
	var seed_data := _make_seed("diff_rating_test", Enums.SeedRarity.RARE, Enums.Element.ARCANE, Enums.SeedPhase.BLOOM, 60, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_gt(result.difficulty_rating, 0.0, "Dungeon difficulty_rating must be positive")


# ─── Loot Bias Tests ────────────────────────────────────────────────

func test_entrance_has_empty_loot_bias() -> void:
	var seed_data := _make_seed("loot_entr_test", Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_eq(result.rooms[0].loot_bias.size(), 0, "ENTRANCE room must have empty loot_bias")


func test_rest_has_empty_loot_bias() -> void:
	var seed_data := _make_seed("loot_rest_test", Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
	var result: DungeonData = _gen.generate(seed_data)
	for room: RoomData in result.rooms:
		if room.type == Enums.RoomType.REST:
			assert_eq(room.loot_bias.size(), 0, "REST room must have empty loot_bias")


func test_combat_room_has_loot_bias() -> void:
	var seed_data := _make_seed("loot_combat_test", Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
	var result: DungeonData = _gen.generate(seed_data)
	for room: RoomData in result.rooms:
		if room.type == Enums.RoomType.COMBAT:
			assert_gt(room.loot_bias.size(), 0, "COMBAT room must have loot_bias entries")
			break


func test_boss_room_has_artifact_bias() -> void:
	var seed_data := _make_seed("loot_boss_test", Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
	var result: DungeonData = _gen.generate(seed_data)
	var boss_bias: Dictionary = result.rooms[result.boss_room_index].loot_bias
	assert_true(boss_bias.has(Enums.Currency.ARTIFACTS), "BOSS room must have ARTIFACTS in loot_bias")
	assert_gt(boss_bias[Enums.Currency.ARTIFACTS], 0.0, "BOSS room ARTIFACTS weight must be positive")


func test_loot_bias_sums_to_one() -> void:
	var seed_data := _make_seed("loot_sum_test", Enums.SeedRarity.EPIC, Enums.Element.ARCANE, Enums.SeedPhase.BLOOM, 70, {"loot_bias": "essence"})
	var result: DungeonData = _gen.generate(seed_data)
	for room: RoomData in result.rooms:
		if room.loot_bias.size() > 0:
			var total: float = 0.0
			for weight: float in room.loot_bias.values():
				total += weight
			assert_almost_eq(total, 1.0, 0.01, "Loot bias for room %d must sum to ~1.0, got %f" % [room.index, total])


func test_loot_bias_trait_shifts_weights() -> void:
	var default_seed := _make_seed("loot_default", Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
	var essence_seed := _make_seed("loot_essence", Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {"loot_bias": "essence"})
	var default_result: DungeonData = _gen.generate(default_seed)
	var essence_result: DungeonData = _gen.generate(essence_seed)
	var default_essence_total: float = 0.0
	var shifted_essence_total: float = 0.0
	for room: RoomData in default_result.rooms:
		if room.loot_bias.has(Enums.Currency.ESSENCE):
			default_essence_total += room.loot_bias[Enums.Currency.ESSENCE]
	for room: RoomData in essence_result.rooms:
		if room.loot_bias.has(Enums.Currency.ESSENCE):
			shifted_essence_total += room.loot_bias[Enums.Currency.ESSENCE]
	assert_gt(shifted_essence_total, default_essence_total, "loot_bias='essence' trait should increase total ESSENCE weight")


# ─── Determinism Tests ───────────────────────────────────────────────

func test_determinism_identical_output() -> void:
	var seed_data := _make_seed("det_test", Enums.SeedRarity.EPIC, Enums.Element.SHADOW, Enums.SeedPhase.BLOOM, 85, {"room_variety": 0.7, "loot_bias": "fragments", "hazard_frequency": 0.4})
	var result_a: DungeonData = _gen.generate(seed_data)
	var result_b: DungeonData = _gen.generate(seed_data)
	assert_eq(result_a.rooms.size(), result_b.rooms.size(), "Determinism: room count must match")
	assert_eq(result_a.edges.size(), result_b.edges.size(), "Determinism: edge count must match")
	assert_eq(result_a.entry_room_index, result_b.entry_room_index, "Determinism: entry index must match")
	assert_eq(result_a.boss_room_index, result_b.boss_room_index, "Determinism: boss index must match")
	assert_almost_eq(result_a.difficulty_rating, result_b.difficulty_rating, 0.001, "Determinism: difficulty must match")
	for i: int in range(result_a.rooms.size()):
		assert_eq(result_a.rooms[i].type, result_b.rooms[i].type, "Determinism: room %d type must match" % i)
		assert_almost_eq(result_a.rooms[i].difficulty, result_b.rooms[i].difficulty, 0.001, "Determinism: room %d difficulty must match" % i)
		assert_eq(result_a.rooms[i].position, result_b.rooms[i].position, "Determinism: room %d position must match" % i)
	for i: int in range(result_a.edges.size()):
		assert_eq(result_a.edges[i], result_b.edges[i], "Determinism: edge %d must match" % i)


func test_different_phases_produce_different_dungeons() -> void:
	var seed_spore := _make_seed("phase_diff", Enums.SeedRarity.RARE, Enums.Element.FLAME, Enums.SeedPhase.SPORE, 50, {})
	var seed_bloom := _make_seed("phase_diff", Enums.SeedRarity.RARE, Enums.Element.FLAME, Enums.SeedPhase.BLOOM, 50, {})
	var result_spore: DungeonData = _gen.generate(seed_spore)
	var result_bloom: DungeonData = _gen.generate(seed_bloom)
	assert_ne(result_spore.rooms.size(), result_bloom.rooms.size(), "Different phases should produce different room counts")


func test_different_seed_ids_produce_different_dungeons() -> void:
	var seed_a := _make_seed("seed_aaa", Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
	var seed_b := _make_seed("seed_bbb", Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
	var result_a: DungeonData = _gen.generate(seed_a)
	var result_b: DungeonData = _gen.generate(seed_b)
	var types_differ: bool = false
	if result_a.rooms.size() == result_b.rooms.size():
		for i: int in range(result_a.rooms.size()):
			if result_a.rooms[i].type != result_b.rooms[i].type:
				types_differ = true
				break
	else:
		types_differ = true
	assert_true(types_differ, "Different seed IDs should produce different dungeon layouts")


# ─── Input Validation Tests ──────────────────────────────────────────

func test_vigor_clamped_to_valid_range() -> void:
	var low_vigor_seed := _make_seed("vigor_low", Enums.SeedRarity.COMMON, Enums.Element.TERRA, Enums.SeedPhase.SPORE, -10, {})
	var high_vigor_seed := _make_seed("vigor_high", Enums.SeedRarity.COMMON, Enums.Element.TERRA, Enums.SeedPhase.SPORE, 500, {})
	var low_result: DungeonData = _gen.generate(low_vigor_seed)
	var high_result: DungeonData = _gen.generate(high_vigor_seed)
	assert_not_null(low_result, "Generator must handle vigor < 1 gracefully")
	assert_not_null(high_result, "Generator must handle vigor > 100 gracefully")


func test_traits_with_out_of_range_values_are_clamped() -> void:
	var seed_data := _make_seed("clamp_test", Enums.SeedRarity.COMMON, Enums.Element.TERRA, Enums.SeedPhase.SPORE, 50, {"room_variety": 5.0, "hazard_frequency": -1.0})
	var result: DungeonData = _gen.generate(seed_data)
	assert_not_null(result, "Generator must handle out-of-range traits gracefully")
	assert_gte(result.rooms.size(), 3, "Result must be a valid dungeon despite bad traits")


func test_empty_traits_use_defaults() -> void:
	var seed_data := _make_seed("empty_traits", Enums.SeedRarity.COMMON, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_not_null(result, "Generator must handle empty traits")
	assert_gte(result.rooms.size(), 3, "Result must be a valid dungeon with empty traits")


# ─── Output Contract Tests ───────────────────────────────────────────

func test_seed_id_matches_input() -> void:
	var seed_data := _make_seed("id_match_test", Enums.SeedRarity.COMMON, Enums.Element.TERRA, Enums.SeedPhase.SPORE, 20, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_eq(result.seed_id, "id_match_test", "DungeonData.seed_id must match input seed id")


func test_element_matches_input() -> void:
	var seed_data := _make_seed("elem_test", Enums.SeedRarity.COMMON, Enums.Element.FROST, Enums.SeedPhase.SPORE, 20, {})
	var result: DungeonData = _gen.generate(seed_data)
	assert_eq(result.element, Enums.Element.FROST, "DungeonData.element must match input element")


func test_room_indices_match_array_positions() -> void:
	var seed_data := _make_seed("idx_test", Enums.SeedRarity.EPIC, Enums.Element.ARCANE, Enums.SeedPhase.BLOOM, 70, {})
	var result: DungeonData = _gen.generate(seed_data)
	for i: int in range(result.rooms.size()):
		assert_eq(result.rooms[i].index, i, "Room at position %d must have index %d" % [i, i])


func test_all_rooms_start_uncleared() -> void:
	var seed_data := _make_seed("cleared_test", Enums.SeedRarity.RARE, Enums.Element.FLAME, Enums.SeedPhase.BUD, 50, {})
	var result: DungeonData = _gen.generate(seed_data)
	for room: RoomData in result.rooms:
		assert_false(room.is_cleared, "All rooms must start with is_cleared = false")


# ─── Fallback Dungeon Tests ─────────────────────────────────────────

func test_fallback_dungeon_is_valid() -> void:
	# We cannot easily trigger fallback without mocking, but we can verify the
	# fallback structure by calling generate_from_params with extreme values
	# that might trigger validation failure, and confirming the result is still valid.
	var result: DungeonData = _gen.generate_from_params("fallback_test", Enums.SeedRarity.COMMON, Enums.Element.TERRA, Enums.SeedPhase.SPORE, 1, {})
	assert_not_null(result, "Must always return a DungeonData, never null")
	assert_gte(result.rooms.size(), 3, "Minimum valid dungeon is 3 rooms")
	assert_eq(result.rooms[0].type, Enums.RoomType.ENTRANCE, "First room must be ENTRANCE")
	assert_eq(result.rooms[result.rooms.size() - 1].type, Enums.RoomType.BOSS, "Last room must be BOSS")
	var visited: Array[int] = _bfs_reachable(result, 0)
	assert_eq(visited.size(), result.rooms.size(), "All rooms must be reachable")


# ─── Describe Dungeon Debug Test ─────────────────────────────────────

func test_describe_dungeon_returns_string() -> void:
	var seed_data := _make_seed("describe_test", Enums.SeedRarity.RARE, Enums.Element.FLAME, Enums.SeedPhase.BUD, 50, {})
	var result: DungeonData = _gen.generate(seed_data)
	var description: String = DungeonGeneratorService.describe_dungeon(result)
	assert_true(description.length() > 0, "describe_dungeon() must return a non-empty string")
	assert_true(description.contains("ENTRANCE"), "Description must mention ENTRANCE room")
	assert_true(description.contains("BOSS"), "Description must mention BOSS room")
```

### 14.2 Test File: `tests/integration/test_dungeon_generation_pipeline.gd`

```gdscript
## Integration tests for the full dungeon generation pipeline.
## Verifies end-to-end generation across many seeds and parameter combinations.
extends GutTest


var _gen: DungeonGeneratorService


func before_each() -> void:
	_gen = DungeonGeneratorService.new()


func _make_seed(
	id: String,
	rarity: int,
	element: int,
	phase: int,
	vigor: int,
	traits: Dictionary
) -> SeedData:
	var sd := SeedData.new()
	sd.id = id
	sd.rarity = rarity
	sd.element = element
	sd.phase = phase
	sd.vigor = vigor
	sd.dungeon_traits = traits
	sd.mutation_slots = []
	return sd


func _count_room_type(dungeon: DungeonData, room_type: int) -> int:
	var count: int = 0
	for room: RoomData in dungeon.rooms:
		if room.type == room_type:
			count += 1
	return count


## Verify 500 random dungeons all pass structural validity.
func test_mass_generation_structural_validity() -> void:
	var elements: Array[int] = [Enums.Element.TERRA, Enums.Element.FLAME, Enums.Element.FROST, Enums.Element.ARCANE, Enums.Element.SHADOW]
	var phases: Array[int] = [Enums.SeedPhase.SPORE, Enums.SeedPhase.SPROUT, Enums.SeedPhase.BUD, Enums.SeedPhase.BLOOM]
	var rarities: Array[int] = [Enums.SeedRarity.COMMON, Enums.SeedRarity.UNCOMMON, Enums.SeedRarity.RARE, Enums.SeedRarity.EPIC, Enums.SeedRarity.LEGENDARY]
	var rng := DeterministicRNG.new()
	rng.seed_string("mass_test_runner")
	for i: int in range(500):
		var elem: int = elements[rng.randi(elements.size())]
		var phase: int = phases[rng.randi(phases.size())]
		var rarity: int = rarities[rng.randi(rarities.size())]
		var vigor: int = rng.randi_range(1, 100)
		var seed_data := _make_seed("mass_%d" % i, rarity, elem, phase, vigor, {})
		var result: DungeonData = _gen.generate(seed_data)
		assert_not_null(result, "Dungeon %d must not be null" % i)
		assert_gte(result.rooms.size(), 3, "Dungeon %d must have at least 3 rooms" % i)
		assert_eq(result.rooms[0].type, Enums.RoomType.ENTRANCE, "Dungeon %d room 0 must be ENTRANCE" % i)
		assert_eq(result.rooms[result.rooms.size() - 1].type, Enums.RoomType.BOSS, "Dungeon %d last room must be BOSS" % i)
		assert_gte(result.edges.size(), result.rooms.size() - 1, "Dungeon %d must have MST minimum edges" % i)


## Verify that no SECRET room appears on the critical path across 500 dungeons.
func test_secret_rooms_never_on_critical_path() -> void:
	for i: int in range(500):
		var seed_data := _make_seed("secret_cp_%d" % i, Enums.SeedRarity.EPIC, Enums.Element.ARCANE, Enums.SeedPhase.BLOOM, 80, {})
		var result: DungeonData = _gen.generate(seed_data)
		var critical_path: Array[int] = result.get_path_to_boss()
		for room: RoomData in result.rooms:
			if room.type == Enums.RoomType.SECRET:
				assert_false(critical_path.has(room.index), "Dungeon %d: SECRET room %d must not be on critical path" % [i, room.index])


## Verify BOSS room is always the highest difficulty across 100 dungeons.
func test_boss_always_highest_difficulty() -> void:
	for i: int in range(100):
		var seed_data := _make_seed("boss_diff_%d" % i, Enums.SeedRarity.RARE, Enums.Element.SHADOW, Enums.SeedPhase.BLOOM, 70, {})
		var result: DungeonData = _gen.generate(seed_data)
		var boss_diff: float = result.rooms[result.boss_room_index].difficulty
		for room: RoomData in result.rooms:
			if room.index != result.boss_room_index:
				assert_lte(room.difficulty, boss_diff + 0.001, "Dungeon %d: room %d diff %.3f exceeds boss diff %.3f" % [i, room.index, room.difficulty, boss_diff])


## Verify average room count for Vigor-50 BUD seeds is in expected range.
func test_average_room_count_vigor_50_bud() -> void:
	var total_rooms: int = 0
	var sample_count: int = 1000
	for i: int in range(sample_count):
		var seed_data := _make_seed("avg_rooms_%d" % i, Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
		var result: DungeonData = _gen.generate(seed_data)
		total_rooms += result.rooms.size()
	var average: float = float(total_rooms) / float(sample_count)
	assert_gte(average, 10.0, "Average room count for V50/BUD/RARE should be >= 10, got %.1f" % average)
	assert_lte(average, 14.0, "Average room count for V50/BUD/RARE should be <= 14, got %.1f" % average)


## Verify FLAME vs TERRA combat room percentage difference.
func test_flame_combat_percentage_exceeds_terra() -> void:
	var flame_combat: int = 0
	var flame_total: int = 0
	var terra_combat: int = 0
	var terra_total: int = 0
	for i: int in range(1000):
		var flame_seed := _make_seed("fpct_%d" % i, Enums.SeedRarity.RARE, Enums.Element.FLAME, Enums.SeedPhase.BUD, 50, {})
		var terra_seed := _make_seed("tpct_%d" % i, Enums.SeedRarity.RARE, Enums.Element.TERRA, Enums.SeedPhase.BUD, 50, {})
		var fr: DungeonData = _gen.generate(flame_seed)
		var tr: DungeonData = _gen.generate(terra_seed)
		flame_combat += _count_room_type(fr, Enums.RoomType.COMBAT)
		flame_total += fr.rooms.size()
		terra_combat += _count_room_type(tr, Enums.RoomType.COMBAT)
		terra_total += tr.rooms.size()
	var flame_pct: float = float(flame_combat) / float(flame_total) * 100.0
	var terra_pct: float = float(terra_combat) / float(terra_total) * 100.0
	assert_gt(flame_pct - terra_pct, 5.0, "FLAME combat%% (%.1f) must exceed TERRA combat%% (%.1f) by >5 points" % [flame_pct, terra_pct])
```

---

## Section 15 · Playtesting Verification

### PV-01: Minimal Dungeon Generation (SPORE/COMMON)

| Field | Detail |
|-------|--------|
| **Setup** | Create a `SeedData` with `id="pv01"`, rarity=COMMON, element=TERRA, phase=SPORE, vigor=10, traits=`{}`. |
| **Action** | Call `DungeonGeneratorService.new().generate(seed_data)`. Inspect the returned `DungeonData`. |
| **Expected** | 3 rooms: ENTRANCE (idx 0), COMBAT or REST (idx 1), BOSS (idx 2). 2 edges connecting them linearly. `entry_room_index=0`, `boss_room_index=2`. All difficulty values are low (< 0.2). All rooms have `is_cleared=false`. |
| **Pass/Fail** | ☐ |

### PV-02: Maximum Dungeon Generation (BLOOM/LEGENDARY/SHADOW)

| Field | Detail |
|-------|--------|
| **Setup** | Create a `SeedData` with `id="pv02"`, rarity=LEGENDARY, element=SHADOW, phase=BLOOM, vigor=100, traits=`{"room_variety": 0.8, "hazard_frequency": 0.5}`. |
| **Action** | Call `generate()`. Inspect the returned `DungeonData`. Use `DungeonGeneratorService.describe_dungeon()` to print the layout. |
| **Expected** | 18–28 rooms. Multiple room types present (COMBAT, TREASURE, TRAP, REST, SECRET, BOSS). At least 1 SECRET room on a branch path. Multiple shortcut edges beyond MST. Boss difficulty is the highest. SHADOW biome multiplier (1.3) produces high difficulty values. |
| **Pass/Fail** | ☐ |

### PV-03: Determinism Verification

| Field | Detail |
|-------|--------|
| **Setup** | Create a `SeedData` with fixed parameters: `id="determinism_check"`, rarity=EPIC, element=FLAME, phase=BUD, vigor=75, traits=`{"room_variety": 0.6}`. |
| **Action** | Call `generate()` twice with the same seed_data. Compare every field of both results. |
| **Expected** | Both `DungeonData` instances are byte-identical: same rooms, same edges, same positions, same difficulties, same loot biases. No field differs. |
| **Pass/Fail** | ☐ |

### PV-04: Phase Variation

| Field | Detail |
|-------|--------|
| **Setup** | Create four `SeedData` instances with identical parameters except phase: SPORE, SPROUT, BUD, BLOOM. All with `id="phase_test"`, rarity=RARE, element=FROST, vigor=50. |
| **Action** | Generate all four dungeons. Compare room counts and layouts. |
| **Expected** | Four different dungeons with increasing room counts (approximately 5, 7, 10, 14). Room type distributions differ. Edge structures differ. The SPORE dungeon is a subset of the complexity seen in the BLOOM dungeon. |
| **Pass/Fail** | ☐ |

### PV-05: Element Bias Verification

| Field | Detail |
|-------|--------|
| **Setup** | Generate 50 dungeons each for FLAME and TERRA, all with identical parameters (rarity=RARE, phase=BUD, vigor=50, empty traits), varying only the element. |
| **Action** | Count COMBAT rooms across all 50 FLAME dungeons and all 50 TERRA dungeons. |
| **Expected** | FLAME dungeons have a noticeably higher COMBAT room count (at least 10% more total COMBAT rooms across 50 dungeons). |
| **Pass/Fail** | ☐ |

### PV-06: Room Variety Trait Effect

| Field | Detail |
|-------|--------|
| **Setup** | Generate two dungeons: same seed ID and parameters, but one with `room_variety: 0.1` and the other with `room_variety: 0.9`. Both RARE/TERRA/BUD/vigor=50. |
| **Action** | Compare room type distributions. |
| **Expected** | Low-variety dungeon has more concentrated room types (e.g., mostly COMBAT). High-variety dungeon has more evenly distributed types (TREASURE, TRAP, PUZZLE all represented). |
| **Pass/Fail** | ☐ |

### PV-07: Loot Bias Trait Effect

| Field | Detail |
|-------|--------|
| **Setup** | Generate two dungeons: same parameters, but one with default traits and one with `loot_bias: "artifacts"`. |
| **Action** | Sum the ARTIFACTS weight across all room loot_bias dictionaries for both dungeons. |
| **Expected** | The `loot_bias: "artifacts"` dungeon has a higher total ARTIFACTS weight than the default dungeon. |
| **Pass/Fail** | ☐ |

### PV-08: Graph Connectivity Stress Test

| Field | Detail |
|-------|--------|
| **Setup** | Generate 100 dungeons with maximum parameters (BLOOM/LEGENDARY/vigor=100) and 100 with minimum (SPORE/COMMON/vigor=1). |
| **Action** | For every generated dungeon, run BFS from entry and verify all rooms are visited. |
| **Expected** | All 200 dungeons pass connectivity check. No disconnected rooms. Boss is always reachable from entry. |
| **Pass/Fail** | ☐ |

### PV-09: Critical Path Validity

| Field | Detail |
|-------|--------|
| **Setup** | Generate 50 dungeons with varied parameters. |
| **Action** | For each dungeon, call `get_path_to_boss()`. Verify path starts at entry, ends at boss, and every consecutive pair of rooms in the path is connected by an edge. |
| **Expected** | All 50 paths are valid. No gaps, no impossible transitions, no rooms appearing that don't exist in the edge list. |
| **Pass/Fail** | ☐ |

### PV-10: Debug Description Output

| Field | Detail |
|-------|--------|
| **Setup** | Generate a medium dungeon (BUD/RARE/FLAME/vigor=60). |
| **Action** | Call `DungeonGeneratorService.describe_dungeon(result)` and print to console. |
| **Expected** | A readable multi-line string listing: dungeon metadata, all rooms with type/difficulty/loot/position, all edges, critical path, and entry/boss indices. No missing data, no placeholder text. |
| **Pass/Fail** | ☐ |

---

## Section 16 · Implementation Prompt

> **This section contains the complete, copy-pasteable GDScript implementation.**
> Every file below is production-ready. No stubs, no TODOs, no placeholders.

### 16.1 `src/services/dungeon_generator.gd`

```gdscript
## DungeonGeneratorService — Deterministic procedural dungeon generator.
##
## Transforms a SeedData instance into a fully populated DungeonData room graph.
## All random decisions flow through a single DeterministicRNG instance seeded
## from seed_id + phase, guaranteeing identical output for identical inputs.
##
## Pipeline:
##   1. Parse seed → 2. Calculate params → 3. Generate graph →
##   4. Assign types → 5. Assign difficulty → 6. Assign loot → 7. Validate
##
## Usage:
##   var gen := DungeonGeneratorService.new()
##   var dungeon: DungeonData = gen.generate(seed_data)
class_name DungeonGeneratorService
extends RefCounted


# ─── Constants: Room Count ────────────────────────────────────────────

## Base room count per SeedPhase ordinal (SPORE=0, SPROUT=1, BUD=2, BLOOM=3).
const PHASE_ROOM_COUNTS: Dictionary = {0: 3, 1: 5, 2: 8, 3: 12}

## Bonus rooms per SeedRarity ordinal (COMMON=0..LEGENDARY=4).
const RARITY_ROOM_BONUS: Dictionary = {0: 0, 1: 1, 2: 2, 3: 3, 4: 3}

## Maximum allowed room count (GDD §5.4 cap).
const MAX_ROOM_COUNT: int = 28

## Minimum allowed room count.
const MIN_ROOM_COUNT: int = 3


# ─── Constants: Vigor Interpolation ───────────────────────────────────

## Vigor breakpoints for parameter interpolation (GDD §5.4).
const VIGOR_BREAKPOINTS: Array[int] = [1, 25, 50, 75, 100]

## Room count min/max ranges per vigor breakpoint.
const ROOM_COUNT_RANGES: Array[Array] = [[5, 7], [8, 11], [12, 16], [16, 22], [20, 28]]

## Branching factor per vigor breakpoint.
const BRANCHING_FACTORS: Array[float] = [0.1, 0.2, 0.3, 0.4, 0.5]

## Enemy density per vigor breakpoint.
const ENEMY_DENSITIES: Array[float] = [0.4, 0.5, 0.65, 0.75, 0.85]

## Treasure density per vigor breakpoint.
const TREASURE_DENSITIES: Array[float] = [0.2, 0.25, 0.3, 0.33, 0.35]

## Trap density per vigor breakpoint.
const TRAP_DENSITIES: Array[float] = [0.1, 0.15, 0.2, 0.25, 0.3]

## Elite chance per vigor breakpoint.
const ELITE_CHANCES: Array[float] = [0.02, 0.05, 0.08, 0.12, 0.15]


# ─── Constants: Biome & Difficulty ────────────────────────────────────

## Per-element difficulty multiplier (Element ordinal → multiplier).
const BIOME_DIFFICULTY: Dictionary = {0: 1.0, 1: 1.1, 2: 1.05, 3: 1.15, 4: 1.3}

## Per-room-type difficulty modifier (RoomType ordinal → modifier).
const ROOM_DIFF_MODIFIERS: Dictionary = {0: 0.0, 1: 1.0, 2: 0.7, 3: 0.9, 4: 0.6, 5: 0.0, 6: 1.5, 7: 0.8}


# ─── Constants: Room Type Weights ─────────────────────────────────────

## Base room type selection weights (RoomType ordinal → weight).
## Only types eligible for weighted selection (not ENTRANCE, BOSS, REST, SECRET).
const ROOM_TYPE_WEIGHTS: Dictionary = {
	1: 40,   # COMBAT
	2: 20,   # TREASURE
	3: 15,   # TRAP
	4: 15,   # PUZZLE
}

## Element-specific additive weight biases (Element ordinal → {RoomType ordinal → bonus}).
const ELEMENT_WEIGHT_BIAS: Dictionary = {
	0: {},                          # TERRA — no bias
	1: {1: 15},                     # FLAME — +15 COMBAT
	2: {3: 15},                     # FROST — +15 TRAP
	3: {4: 10, 2: 5},              # ARCANE — +10 PUZZLE, +5 TREASURE
	4: {3: 10, 1: 5},              # SHADOW — +10 TRAP, +5 COMBAT
}


# ─── Constants: Loot Bias Defaults ────────────────────────────────────

## Default loot bias per room type (RoomType ordinal → {Currency ordinal → weight}).
const ROOM_LOOT_DEFAULTS: Dictionary = {
	0: {},  # ENTRANCE — no loot
	1: {0: 0.6, 1: 0.3, 2: 0.1},                    # COMBAT: GOLD, ESSENCE, FRAGMENTS
	2: {0: 0.5, 1: 0.2, 2: 0.2, 3: 0.1},            # TREASURE: GOLD, ESSENCE, FRAGMENTS, ARTIFACTS
	3: {0: 0.3, 1: 0.2, 2: 0.5},                     # TRAP: GOLD, ESSENCE, FRAGMENTS
	4: {0: 0.2, 1: 0.5, 2: 0.3},                     # PUZZLE: GOLD, ESSENCE, FRAGMENTS
	5: {},  # REST — no loot
	6: {0: 0.3, 1: 0.2, 2: 0.1, 3: 0.4},            # BOSS: GOLD, ESSENCE, FRAGMENTS, ARTIFACTS
	7: {0: 0.1, 1: 0.2, 2: 0.4, 3: 0.3},            # SECRET: GOLD, ESSENCE, FRAGMENTS, ARTIFACTS
}

## Loot bias trait name → Currency ordinal mapping.
const LOOT_BIAS_CURRENCY_MAP: Dictionary = {
	"gold": 0,
	"essence": 1,
	"fragments": 2,
	"artifacts": 3,
}

## Loot bias trait bonus amount added before renormalization.
const LOOT_BIAS_TRAIT_BONUS: float = 0.2


# ─── Constants: Graph Layout ──────────────────────────────────────────

## Abstract grid cell spacing for room placement.
const GRID_SPACING: float = 120.0

## Grid size (cells per axis). 8×8 = 64 cells, supports up to 31 rooms.
const GRID_SIZE: int = 8


# ─── Constants: Secret Room Scaling ───────────────────────────────────

## Secret room count thresholds: [max_rooms_for_this_tier, secret_count].
const SECRET_ROOM_TIERS: Array[Array] = [[5, 0], [10, 1], [18, 2], [999, 3]]


# ─── Public API ───────────────────────────────────────────────────────

## Generates a complete DungeonData room graph from a SeedData instance.
##
## [param seed_data] The seed to generate a dungeon for.
## [return] A fully populated DungeonData with rooms, edges, types, difficulty, and loot.
func generate(seed_data: SeedData) -> DungeonData:
	var traits: Dictionary = seed_data.dungeon_traits if seed_data.dungeon_traits != null else {}
	var mutation_diff_sum: float = _calculate_mutation_difficulty(seed_data.mutation_slots)
	return _run_pipeline(
		seed_data.id,
		seed_data.rarity,
		seed_data.element,
		seed_data.phase,
		seed_data.vigor,
		traits,
		mutation_diff_sum,
	)


## Generates a DungeonData from explicit parameters (for testing without SeedData).
##
## [param seed_id] Unique seed identifier for RNG seeding.
## [param rarity] SeedRarity ordinal value.
## [param element] Element ordinal value.
## [param phase] SeedPhase ordinal value.
## [param vigor] Vigor value (1–100).
## [param traits] Dungeon traits dictionary.
## [return] A fully populated DungeonData.
func generate_from_params(
	seed_id: String,
	rarity: int,
	element: int,
	phase: int,
	vigor: int,
	traits: Dictionary,
) -> DungeonData:
	return _run_pipeline(seed_id, rarity, element, phase, vigor, traits, 0.0)


## Returns a human-readable multi-line string describing the dungeon layout.
##
## [param dungeon] The DungeonData to describe.
## [return] A formatted debug string.
static func describe_dungeon(dungeon: DungeonData) -> String:
	var lines: Array[String] = []
	var elem_names: Array[String] = ["TERRA", "FLAME", "FROST", "ARCANE", "SHADOW"]
	var type_names: Array[String] = ["ENTRANCE", "COMBAT", "TREASURE", "TRAP", "PUZZLE", "REST", "BOSS", "SECRET"]
	var elem_name: String = elem_names[dungeon.element] if dungeon.element < elem_names.size() else "UNKNOWN"
	lines.append("Dungeon [%s] | Element: %s | Difficulty: %.2f" % [dungeon.seed_id, elem_name, dungeon.difficulty_rating])
	lines.append("Rooms (%d):" % dungeon.rooms.size())
	for room: RoomData in dungeon.rooms:
		var type_name: String = type_names[room.type] if room.type < type_names.size() else "UNKNOWN"
		var bias_str: String = ""
		if room.loot_bias.size() > 0:
			var parts: Array[String] = []
			for key: int in room.loot_bias.keys():
				parts.append("%d:%.2f" % [key, room.loot_bias[key]])
			bias_str = "{%s}" % ",".join(parts)
		else:
			bias_str = "{}"
		lines.append("  [%d] %-9s diff=%.2f  loot=%s  pos=(%d,%d)" % [room.index, type_name, room.difficulty, bias_str, int(room.position.x), int(room.position.y)])
	var edge_strs: Array[String] = []
	for edge: Vector2i in dungeon.edges:
		edge_strs.append("(%d,%d)" % [edge.x, edge.y])
	lines.append("Edges (%d): %s" % [dungeon.edges.size(), " ".join(edge_strs)])
	var path: Array[int] = dungeon.get_path_to_boss()
	var path_strs: Array[String] = []
	for idx: int in path:
		path_strs.append(str(idx))
	lines.append("Critical path: %s" % " → ".join(path_strs))
	lines.append("Entry: %d | Boss: %d" % [dungeon.entry_room_index, dungeon.boss_room_index])
	return "\n".join(lines)


# ─── Pipeline Orchestrator ────────────────────────────────────────────

func _run_pipeline(
	seed_id: String,
	rarity: int,
	element: int,
	phase: int,
	vigor: int,
	traits: Dictionary,
	mutation_diff_sum: float,
) -> DungeonData:
	# Stage 0: Input validation and clamping
	vigor = clampi(vigor, 1, 100)
	rarity = clampi(rarity, 0, 4)
	element = clampi(element, 0, 4)
	phase = clampi(phase, 0, 3)
	var safe_traits: Dictionary = _sanitize_traits(traits)

	# Stage 1: Initialize RNG
	var rng := DeterministicRNG.new()
	rng.seed_string(seed_id + str(phase))

	# Stage 2: Calculate dungeon parameters
	var room_count: int = _calculate_room_count(phase, rarity, vigor)
	var branching_factor: float = _interpolate_vigor(vigor, BRANCHING_FACTORS)
	var biome_multiplier: float = BIOME_DIFFICULTY.get(element, 1.0)

	# Stage 3: Generate room graph (positions + edges)
	var positions: Array[Vector2] = _place_rooms_on_grid(room_count, rng)
	var mst_edges: Array[Vector2i] = _build_mst(positions)
	var all_edges: Array[Vector2i] = _add_shortcut_edges(mst_edges, room_count, branching_factor, positions, rng)

	# Stage 4: Assign room types
	var room_types: Array[int] = _assign_room_types(room_count, element, safe_traits, all_edges, positions, rng)

	# Stage 5: Assign difficulty per room
	var critical_path: Array[int] = _bfs_shortest_path(0, room_count - 1, all_edges, room_count)
	var room_difficulties: Array[float] = _assign_difficulties(room_count, room_types, vigor, biome_multiplier, critical_path, all_edges)

	# Stage 6: Assign loot bias per room
	var room_loot_biases: Array[Dictionary] = _assign_loot_biases(room_count, room_types, safe_traits)

	# Stage 7: Assemble DungeonData
	var dungeon := DungeonData.new()
	dungeon.seed_id = seed_id
	dungeon.element = element
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = room_count - 1
	dungeon.edges = all_edges

	var rooms: Array[RoomData] = []
	for i: int in range(room_count):
		var room := RoomData.new()
		room.index = i
		room.type = room_types[i]
		room.difficulty = room_difficulties[i]
		room.is_cleared = false
		room.loot_bias = room_loot_biases[i]
		room.position = positions[i]
		rooms.append(room)
	dungeon.rooms = rooms

	# Calculate overall difficulty rating
	var diff_sum: float = 0.0
	var diff_count: int = 0
	for room: RoomData in rooms:
		if room.difficulty > 0.0:
			diff_sum += room.difficulty
			diff_count += 1
	if diff_count > 0:
		dungeon.difficulty_rating = (diff_sum / float(diff_count)) + mutation_diff_sum
	else:
		dungeon.difficulty_rating = mutation_diff_sum

	# Stage 7b: Validate
	if not _validate_dungeon(dungeon):
		push_error("[DungeonGen] Validation failed for seed '%s'. Returning fallback dungeon." % seed_id)
		return _create_fallback_dungeon(seed_id, element)

	return dungeon


# ─── Stage 1: Trait Sanitization ──────────────────────────────────────

func _sanitize_traits(traits: Dictionary) -> Dictionary:
	var result: Dictionary = {
		"room_variety": 0.5,
		"loot_bias": "gold",
		"hazard_frequency": 0.2,
	}
	if traits.has("room_variety"):
		result["room_variety"] = clampf(float(traits["room_variety"]), 0.0, 1.0)
	if traits.has("loot_bias"):
		var bias_val: String = str(traits["loot_bias"])
		if LOOT_BIAS_CURRENCY_MAP.has(bias_val):
			result["loot_bias"] = bias_val
		else:
			push_warning("[DungeonGen] Unknown loot_bias trait value: '%s'. Using default 'gold'." % bias_val)
	if traits.has("hazard_frequency"):
		result["hazard_frequency"] = clampf(float(traits["hazard_frequency"]), 0.0, 1.0)
	for key: String in traits.keys():
		if not result.has(key):
			push_warning("[DungeonGen] Unknown trait key: '%s'. Ignoring." % key)
	return result


# ─── Stage 2: Parameter Calculation ───────────────────────────────────

func _calculate_room_count(phase: int, rarity: int, vigor: int) -> int:
	var base: int = PHASE_ROOM_COUNTS.get(phase, 3)
	var rarity_bonus: int = RARITY_ROOM_BONUS.get(rarity, 0)
	var vigor_bonus: int = int(floorf(float(vigor) / 33.0))
	vigor_bonus = clampi(vigor_bonus, 0, 3)
	var total: int = base + rarity_bonus + vigor_bonus
	# Clamp to vigor-scaled range from GDD §5.4
	var vigor_range: Array = _get_vigor_room_range(vigor)
	total = clampi(total, int(vigor_range[0]), int(vigor_range[1]))
	total = clampi(total, MIN_ROOM_COUNT, MAX_ROOM_COUNT)
	return total


func _get_vigor_room_range(vigor: int) -> Array:
	## Returns [min_rooms, max_rooms] for the given vigor value via interpolation.
	if vigor <= VIGOR_BREAKPOINTS[0]:
		return ROOM_COUNT_RANGES[0]
	if vigor >= VIGOR_BREAKPOINTS[VIGOR_BREAKPOINTS.size() - 1]:
		return ROOM_COUNT_RANGES[ROOM_COUNT_RANGES.size() - 1]
	for i: int in range(VIGOR_BREAKPOINTS.size() - 1):
		if vigor <= VIGOR_BREAKPOINTS[i + 1]:
			var t: float = float(vigor - VIGOR_BREAKPOINTS[i]) / float(VIGOR_BREAKPOINTS[i + 1] - VIGOR_BREAKPOINTS[i])
			var min_rooms: int = int(lerpf(float(ROOM_COUNT_RANGES[i][0]), float(ROOM_COUNT_RANGES[i + 1][0]), t))
			var max_rooms: int = int(lerpf(float(ROOM_COUNT_RANGES[i][1]), float(ROOM_COUNT_RANGES[i + 1][1]), t))
			return [min_rooms, max_rooms]
	return [MIN_ROOM_COUNT, MAX_ROOM_COUNT]


func _interpolate_vigor(vigor: int, values: Array[float]) -> float:
	## Linearly interpolates a value from the vigor breakpoint table.
	if vigor <= VIGOR_BREAKPOINTS[0]:
		return values[0]
	if vigor >= VIGOR_BREAKPOINTS[VIGOR_BREAKPOINTS.size() - 1]:
		return values[values.size() - 1]
	for i: int in range(VIGOR_BREAKPOINTS.size() - 1):
		if vigor <= VIGOR_BREAKPOINTS[i + 1]:
			var t: float = float(vigor - VIGOR_BREAKPOINTS[i]) / float(VIGOR_BREAKPOINTS[i + 1] - VIGOR_BREAKPOINTS[i])
			return lerpf(values[i], values[i + 1], t)
	return values[0]


func _calculate_mutation_difficulty(mutation_slots: Array) -> float:
	var total: float = 0.0
	if mutation_slots == null:
		return 0.0
	for slot: Variant in mutation_slots:
		if slot != null and slot.has_method("get") and slot.get("difficulty_value") != null:
			total += float(slot.get("difficulty_value"))
		elif slot is Dictionary and slot.has("difficulty_value"):
			total += float(slot["difficulty_value"])
	return total


# ─── Stage 3: Room Placement & Graph ─────────────────────────────────

func _place_rooms_on_grid(room_count: int, rng: DeterministicRNG) -> Array[Vector2]:
	## Places rooms at unique grid cells using seeded RNG.
	var positions: Array[Vector2] = []
	var occupied: Dictionary = {}
	var max_attempts: int = room_count * 10
	var attempts: int = 0
	while positions.size() < room_count and attempts < max_attempts:
		var gx: int = rng.randi(GRID_SIZE)
		var gy: int = rng.randi(GRID_SIZE)
		var key: String = "%d_%d" % [gx, gy]
		if not occupied.has(key):
			occupied[key] = true
			positions.append(Vector2(float(gx) * GRID_SPACING, float(gy) * GRID_SPACING))
		attempts += 1
	# If grid is too full, fill remaining with sequential cells
	if positions.size() < room_count:
		for gx: int in range(GRID_SIZE):
			for gy: int in range(GRID_SIZE):
				if positions.size() >= room_count:
					break
				var key: String = "%d_%d" % [gx, gy]
				if not occupied.has(key):
					occupied[key] = true
					positions.append(Vector2(float(gx) * GRID_SPACING, float(gy) * GRID_SPACING))
			if positions.size() >= room_count:
				break
	return positions


func _build_mst(positions: Array[Vector2]) -> Array[Vector2i]:
	## Builds a minimum spanning tree using Prim's algorithm with Euclidean distance.
	var n: int = positions.size()
	if n <= 1:
		return []
	var in_tree: Array[bool] = []
	var min_cost: Array[float] = []
	var min_edge: Array[int] = []
	for i: int in range(n):
		in_tree.append(false)
		min_cost.append(INF)
		min_edge.append(-1)
	in_tree[0] = true
	# Initialize costs from node 0
	for i: int in range(1, n):
		min_cost[i] = positions[0].distance_to(positions[i])
		min_edge[i] = 0
	var edges: Array[Vector2i] = []
	for _iter: int in range(n - 1):
		# Find the non-tree node with minimum cost
		var best: int = -1
		var best_cost: float = INF
		for i: int in range(n):
			if not in_tree[i] and min_cost[i] < best_cost:
				best_cost = min_cost[i]
				best = i
		if best == -1:
			break
		in_tree[best] = true
		var a: int = mini(best, min_edge[best])
		var b: int = maxi(best, min_edge[best])
		edges.append(Vector2i(a, b))
		# Update costs for remaining nodes
		for i: int in range(n):
			if not in_tree[i]:
				var dist: float = positions[best].distance_to(positions[i])
				if dist < min_cost[i]:
					min_cost[i] = dist
					min_edge[i] = best
	return edges


func _add_shortcut_edges(
	mst_edges: Array[Vector2i],
	room_count: int,
	branching_factor: float,
	positions: Array[Vector2],
	rng: DeterministicRNG,
) -> Array[Vector2i]:
	## Adds random shortcut edges beyond the MST controlled by branching factor.
	var all_edges: Array[Vector2i] = mst_edges.duplicate()
	var edge_set: Dictionary = {}
	for edge: Vector2i in all_edges:
		edge_set["%d_%d" % [edge.x, edge.y]] = true
	var shortcut_count: int = int(floorf(branching_factor * float(room_count)))
	# Build candidate list of non-MST edges sorted by distance
	var candidates: Array[Array] = []
	for i: int in range(room_count):
		for j: int in range(i + 1, room_count):
			var key: String = "%d_%d" % [i, j]
			if not edge_set.has(key):
				var dist: float = positions[i].distance_to(positions[j])
				candidates.append([i, j, dist])
	# Sort by distance (prefer shorter shortcuts)
	candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[2] < b[2])
	# Add shortcuts using RNG for selection among close candidates
	var added: int = 0
	var candidate_idx: int = 0
	while added < shortcut_count and candidate_idx < candidates.size():
		# Pick from top candidates with some randomness
		var pick_range: int = mini(candidates.size() - candidate_idx, maxi(3, shortcut_count))
		var pick_offset: int = rng.randi(pick_range)
		var actual_idx: int = candidate_idx + pick_offset
		if actual_idx < candidates.size():
			var c: Array = candidates[actual_idx]
			var edge := Vector2i(int(c[0]), int(c[1]))
			var key: String = "%d_%d" % [edge.x, edge.y]
			if not edge_set.has(key):
				all_edges.append(edge)
				edge_set[key] = true
				added += 1
			# Remove the picked candidate
			candidates.remove_at(actual_idx)
		else:
			candidate_idx += 1
	return all_edges


# ─── Stage 4: Room Type Assignment ────────────────────────────────────

func _assign_room_types(
	room_count: int,
	element: int,
	traits: Dictionary,
	edges: Array[Vector2i],
	positions: Array[Vector2],
	rng: DeterministicRNG,
) -> Array[int]:
	var types: Array[int] = []
	for i: int in range(room_count):
		types.append(-1)  # Unassigned

	# Fixed assignments
	types[0] = Enums.RoomType.ENTRANCE
	types[room_count - 1] = Enums.RoomType.BOSS

	# Find critical path for REST and SECRET placement
	var critical_path: Array[int] = _bfs_shortest_path(0, room_count - 1, edges, room_count)

	# Place REST rooms
	if room_count >= 8:
		# Two REST rooms at ~40% and ~70% of critical path
		var rest_pos_a: int = int(floorf(float(critical_path.size()) * 0.4))
		var rest_pos_b: int = int(floorf(float(critical_path.size()) * 0.7))
		rest_pos_a = clampi(rest_pos_a, 1, critical_path.size() - 2)
		rest_pos_b = clampi(rest_pos_b, rest_pos_a + 1, critical_path.size() - 2)
		var rest_idx_a: int = critical_path[rest_pos_a]
		var rest_idx_b: int = critical_path[rest_pos_b]
		if types[rest_idx_a] == -1:
			types[rest_idx_a] = Enums.RoomType.REST
		if types[rest_idx_b] == -1:
			types[rest_idx_b] = Enums.RoomType.REST
	elif room_count >= 4:
		# One REST room at ~50% of critical path
		var rest_pos: int = int(floorf(float(critical_path.size()) * 0.5))
		rest_pos = clampi(rest_pos, 1, critical_path.size() - 2)
		var rest_idx: int = critical_path[rest_pos]
		if types[rest_idx] == -1:
			types[rest_idx] = Enums.RoomType.REST

	# Find branch rooms (not on critical path) for SECRET placement
	var branch_rooms: Array[int] = []
	for i: int in range(room_count):
		if types[i] == -1 and not critical_path.has(i):
			branch_rooms.append(i)

	# Determine SECRET room count
	var target_secrets: int = 0
	for tier: Array in SECRET_ROOM_TIERS:
		if room_count <= int(tier[0]):
			target_secrets = int(tier[1])
			break
	target_secrets = mini(target_secrets, branch_rooms.size())

	# Place SECRET rooms
	if target_secrets > 0 and branch_rooms.size() > 0:
		var shuffled_branches: Array = branch_rooms.duplicate()
		shuffled_branches = rng.shuffle(shuffled_branches)
		for i: int in range(target_secrets):
			var branch_idx: int = int(shuffled_branches[i])
			types[branch_idx] = Enums.RoomType.SECRET

	# Weighted random assignment for remaining unassigned rooms
	var weight_items: Array[int] = []
	var weight_values: Array[float] = []
	var base_weights: Dictionary = ROOM_TYPE_WEIGHTS.duplicate()
	# Apply element bias
	var elem_bias: Dictionary = ELEMENT_WEIGHT_BIAS.get(element, {})
	for type_key: int in elem_bias.keys():
		if base_weights.has(type_key):
			base_weights[type_key] = int(base_weights[type_key]) + int(elem_bias[type_key])
		else:
			base_weights[type_key] = int(elem_bias[type_key])
	# Apply hazard_frequency trait (increases TRAP weight)
	var hazard_freq: float = float(traits.get("hazard_frequency", 0.2))
	if base_weights.has(3):  # TRAP
		base_weights[3] = int(base_weights[3]) + int(hazard_freq * 20.0)
	# Apply room_variety trait
	var variety: float = float(traits.get("room_variety", 0.5))
	var avg_weight: float = 0.0
	var type_keys: Array = base_weights.keys()
	type_keys.sort()
	for key: Variant in type_keys:
		avg_weight += float(base_weights[key])
	if type_keys.size() > 0:
		avg_weight /= float(type_keys.size())
	for key: Variant in type_keys:
		var w: float = float(base_weights[key])
		# Variety effect: high variety flattens toward average, low variety amplifies deviation
		var adjusted: float = w + (variety - 0.5) * 2.0 * (avg_weight - w)
		adjusted = maxf(adjusted, 1.0)  # Minimum weight of 1
		weight_items.append(int(key))
		weight_values.append(adjusted)

	# Assign remaining rooms
	for i: int in range(room_count):
		if types[i] == -1:
			var picked: Variant = rng.weighted_pick(weight_items, weight_values)
			types[i] = int(picked)

	return types


# ─── Stage 5: Difficulty Assignment ───────────────────────────────────

func _assign_difficulties(
	room_count: int,
	room_types: Array[int],
	vigor: int,
	biome_multiplier: float,
	critical_path: Array[int],
	edges: Array[Vector2i],
) -> Array[float]:
	var base_diff: float = float(vigor) * biome_multiplier / 100.0
	var max_depth: int = critical_path.size() - 1
	if max_depth <= 0:
		max_depth = 1

	# Build depth map: distance from entry along edges (BFS)
	var depth_map: Array[int] = _bfs_depths(0, edges, room_count)

	# Build critical path depth lookup
	var cp_depth: Dictionary = {}
	for i: int in range(critical_path.size()):
		cp_depth[critical_path[i]] = i

	var difficulties: Array[float] = []
	for i: int in range(room_count):
		var type_mod: float = ROOM_DIFF_MODIFIERS.get(room_types[i], 1.0)
		# Determine depth factor
		var depth_factor: float = 0.0
		if cp_depth.has(i):
			depth_factor = float(cp_depth[i]) / float(max_depth)
		else:
			# For non-critical-path rooms, use BFS depth normalized
			depth_factor = float(depth_map[i]) / float(max_depth)
			depth_factor = clampf(depth_factor, 0.0, 1.0)
		var room_diff: float = base_diff * (0.3 + 0.7 * depth_factor) * type_mod
		difficulties.append(room_diff)
	return difficulties


func _bfs_depths(start: int, edges: Array[Vector2i], room_count: int) -> Array[int]:
	## Returns BFS distance from start to each room.
	var depths: Array[int] = []
	for i: int in range(room_count):
		depths.append(-1)
	depths[start] = 0
	var queue: Array[int] = [start]
	var adj: Dictionary = _build_adjacency(edges, room_count)
	while queue.size() > 0:
		var current: int = queue.pop_front()
		var neighbors: Array = adj.get(current, [])
		for neighbor: Variant in neighbors:
			var n: int = int(neighbor)
			if depths[n] == -1:
				depths[n] = depths[current] + 1
				queue.append(n)
	# Replace any unreachable (-1) with max depth
	var max_d: int = 0
	for d: int in depths:
		if d > max_d:
			max_d = d
	for i: int in range(depths.size()):
		if depths[i] == -1:
			depths[i] = max_d
	return depths


# ─── Stage 6: Loot Bias Assignment ───────────────────────────────────

func _assign_loot_biases(
	room_count: int,
	room_types: Array[int],
	traits: Dictionary,
) -> Array[Dictionary]:
	var biases: Array[Dictionary] = []
	var trait_currency_name: String = str(traits.get("loot_bias", "gold"))
	var trait_currency: int = LOOT_BIAS_CURRENCY_MAP.get(trait_currency_name, 0)
	for i: int in range(room_count):
		var room_type: int = room_types[i]
		var default_bias: Dictionary = ROOM_LOOT_DEFAULTS.get(room_type, {})
		if default_bias.size() == 0:
			biases.append({})
			continue
		# Deep copy and apply trait bonus
		var bias: Dictionary = default_bias.duplicate()
		if not bias.has(trait_currency):
			bias[trait_currency] = 0.0
		bias[trait_currency] = float(bias[trait_currency]) + LOOT_BIAS_TRAIT_BONUS
		# Renormalize to sum to 1.0
		var total: float = 0.0
		for key: Variant in bias.keys():
			total += float(bias[key])
		if total > 0.0:
			for key: Variant in bias.keys():
				bias[key] = float(bias[key]) / total
		biases.append(bias)
	return biases


# ─── Stage 7: Validation ─────────────────────────────────────────────

func _validate_dungeon(dungeon: DungeonData) -> bool:
	var room_count: int = dungeon.rooms.size()
	if room_count < MIN_ROOM_COUNT:
		return false
	# Check ENTRANCE exists at index 0
	if dungeon.rooms[0].type != Enums.RoomType.ENTRANCE:
		return false
	# Check BOSS exists at last index
	if dungeon.rooms[room_count - 1].type != Enums.RoomType.BOSS:
		return false
	# Check full connectivity via BFS from entry
	var visited: Array[int] = _bfs_visit(dungeon.entry_room_index, dungeon.edges, room_count)
	if visited.size() != room_count:
		return false
	# Check boss is reachable
	if not visited.has(dungeon.boss_room_index):
		return false
	return true


func _bfs_visit(start: int, edges: Array[Vector2i], room_count: int) -> Array[int]:
	## Returns all rooms reachable from start via BFS.
	var visited: Array[int] = []
	var queue: Array[int] = [start]
	var seen: Dictionary = {}
	seen[start] = true
	while queue.size() > 0:
		var current: int = queue.pop_front()
		visited.append(current)
		var adj: Dictionary = _build_adjacency(edges, room_count)
		var neighbors: Array = adj.get(current, [])
		for neighbor: Variant in neighbors:
			var n: int = int(neighbor)
			if not seen.has(n):
				seen[n] = true
				queue.append(n)
	return visited


# ─── Graph Utilities ──────────────────────────────────────────────────

func _build_adjacency(edges: Array[Vector2i], room_count: int) -> Dictionary:
	## Builds adjacency list from edge list.
	var adj: Dictionary = {}
	for i: int in range(room_count):
		adj[i] = []
	for edge: Vector2i in edges:
		adj[edge.x].append(edge.y)
		adj[edge.y].append(edge.x)
	return adj


func _bfs_shortest_path(start: int, goal: int, edges: Array[Vector2i], room_count: int) -> Array[int]:
	## Returns the shortest path from start to goal as an array of room indices.
	if start == goal:
		return [start]
	var adj: Dictionary = _build_adjacency(edges, room_count)
	var visited: Dictionary = {}
	var parent: Dictionary = {}
	var queue: Array[int] = [start]
	visited[start] = true
	parent[start] = -1
	while queue.size() > 0:
		var current: int = queue.pop_front()
		if current == goal:
			# Reconstruct path
			var path: Array[int] = []
			var node: int = goal
			while node != -1:
				path.insert(0, node)
				node = int(parent.get(node, -1))
			return path
		var neighbors: Array = adj.get(current, [])
		for neighbor: Variant in neighbors:
			var n: int = int(neighbor)
			if not visited.has(n):
				visited[n] = true
				parent[n] = current
				queue.append(n)
	# No path found — return entry only (should not happen with valid MST)
	return [start]


# ─── Fallback Dungeon ────────────────────────────────────────────────

func _create_fallback_dungeon(seed_id: String, element: int) -> DungeonData:
	## Creates a minimal 3-room linear dungeon as a safe fallback.
	var dungeon := DungeonData.new()
	dungeon.seed_id = seed_id
	dungeon.element = element
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = 2

	var rooms: Array[RoomData] = []
	# Room 0: ENTRANCE
	var room_0 := RoomData.new()
	room_0.index = 0
	room_0.type = Enums.RoomType.ENTRANCE
	room_0.difficulty = 0.0
	room_0.is_cleared = false
	room_0.loot_bias = {}
	room_0.position = Vector2(0.0, 0.0)
	rooms.append(room_0)

	# Room 1: COMBAT
	var room_1 := RoomData.new()
	room_1.index = 1
	room_1.type = Enums.RoomType.COMBAT
	room_1.difficulty = 0.3
	room_1.is_cleared = false
	room_1.loot_bias = {0: 0.6, 1: 0.3, 2: 0.1}
	room_1.position = Vector2(GRID_SPACING, 0.0)
	rooms.append(room_1)

	# Room 2: BOSS
	var room_2 := RoomData.new()
	room_2.index = 2
	room_2.type = Enums.RoomType.BOSS
	room_2.difficulty = 0.5
	room_2.is_cleared = false
	room_2.loot_bias = {0: 0.3, 1: 0.2, 2: 0.1, 3: 0.4}
	room_2.position = Vector2(GRID_SPACING * 2.0, 0.0)
	rooms.append(room_2)

	dungeon.rooms = rooms
	dungeon.edges = [Vector2i(0, 1), Vector2i(1, 2)]
	dungeon.difficulty_rating = 0.4
	return dungeon
```
