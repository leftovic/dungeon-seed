# TASK-011: Loot Table Engine & Drop Resolver

## 1. Header

| Field | Value |
|---|---|
| **Task ID** | TASK-011 |
| **Title** | Loot Table Engine & Drop Resolver |
| **Priority** | P1 — Critical Path |
| **Tier** | Core Gameplay System |
| **Complexity** | 8 points (Moderate) |
| **Phase** | Phase 2 — Core Mechanics |
| **Wave** | Wave 3 |
| **Stream** | 🔴 MCH (Mechanics) — Primary |
| **Cross-Stream** | ⚪ TCH (serialization), 🟡 WLD (room loot bias) |
| **GDD Ref** | §5 Expedition System, §8 Loot & Economy, §10 Currency Model |
| **Milestone** | M3 — Expedition Core Loop |
| **Dependencies** | TASK-002 (DeterministicRNG), TASK-007 (ItemData, ItemDatabase, InventoryData) |
| **Dependents** | TASK-015 (Room-by-Room Expedition Resolver) |
| **Critical Path** | Yes — blocks expedition loot resolution |
| **Est. Effort** | 3–4 dev days |
| **Target Files** | `src/services/loot_service.gd`, `src/resources/loot_tables.gd`, `tests/test_loot_service.gd` |
| **Class Names** | `LootService`, `LootTables` |

---

## 2. Description

### What This Task Does

TASK-011 builds the **Loot Table Engine** — the deterministic, weighted drop-table system that converts random rolls into concrete item drops and currency rewards for every room in every expedition. This is the bridge between the abstract expedition path (TASK-015) and the tangible rewards players collect.

The system comprises two files:

- **`LootService`** (`src/services/loot_service.gd`) — A `RefCounted` service that registers loot tables, resolves weighted rolls against them using `DeterministicRNG`, filters by rarity, and computes currency drops. Every call is deterministic: the same RNG state always produces the same loot.
- **`LootTables`** (`src/resources/loot_tables.gd`) — A static data file containing all pre-built loot table definitions as constant dictionaries: `combat_common`, `combat_rare`, `treasure_common`, `treasure_rare`, `boss_loot`, `trap_consolation`, and `puzzle_reward`.

### Why It Matters

**Player Experience Impact:**
Loot is the primary reward feedback loop in Dungeon Seed. Every room the player clears produces drops, and those drops must feel fair, varied, and exciting. The loot table engine ensures that:
- Combat rooms consistently reward effort with gold and common gear.
- Treasure rooms feel like genuine discoveries with higher-value drops.
- Boss rooms deliver the dopamine spike of guaranteed rare+ items.
- Trap rooms offer consolation so failure still yields something.
- Puzzle rooms reward cleverness with curated drops.

**Economy Impact:**
The loot engine is the primary faucet for all four currencies (Gold, Verdant Essence, Materials, Guild Favor) and for item generation. If drop rates are wrong, the entire economy collapses — either players drown in gold or starve for resources. The engine's deterministic nature means we can simulate thousands of expeditions offline to validate economy balance before shipping.

**Development Cost Justification:**
At 8 complexity points, this task is moderate. The weighted selection algorithm is straightforward, but the combinatorial surface (7 tables × 5 rarity tiers × 6 room types × variable difficulty) demands thorough testing. The deterministic guarantee — same seed, same drops, always — requires careful RNG discipline throughout.

### Technical Architecture

```
┌─────────────────────────────────────────────────────┐
│                  LootService                        │
│  (src/services/loot_service.gd — RefCounted)        │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  _tables: Dictionary<String, Array[Dict]>     │  │
│  │  ─────────────────────────────────────────    │  │
│  │  register_table(id, entries)                  │  │
│  │  get_table(id) -> Array[Dict]                 │  │
│  │  has_table(id) -> bool                        │  │
│  │  roll(id, rng, count) -> Array[Dict]          │  │
│  │  roll_with_rarity_filter(id, rng, min, db)    │  │
│  │  roll_currency(room_type, diff, rng) -> Dict  │  │
│  └───────────────────────────────────────────────┘  │
│           │                         │               │
│           ▼                         ▼               │
│  ┌────────────────┐   ┌──────────────────────────┐  │
│  │ DeterministicRNG│   │   ItemDatabase           │  │
│  │  (TASK-002)    │   │    (TASK-007)            │  │
│  │  pick_weighted │   │    get_item(id)          │  │
│  │  randi_range   │   │    has_item(id)          │  │
│  │  randf         │   │                          │  │
│  └────────────────┘   └──────────────────────────┘  │
└─────────────────────────────────────────────────────┘
           ▲
           │  registers all pre-built tables at init
┌──────────┴──────────────────────────────────────────┐
│                   LootTables                        │
│  (src/resources/loot_tables.gd — static consts)     │
│                                                     │
│  COMBAT_COMMON   : Array[Dictionary]                │
│  COMBAT_RARE     : Array[Dictionary]                │
│  TREASURE_COMMON : Array[Dictionary]                │
│  TREASURE_RARE   : Array[Dictionary]                │
│  BOSS_LOOT       : Array[Dictionary]                │
│  TRAP_CONSOLATION: Array[Dictionary]                │
│  PUZZLE_REWARD   : Array[Dictionary]                │
│                                                     │
│  static func get_all_tables() -> Dictionary         │
└─────────────────────────────────────────────────────┘
```

### System Interaction Map

```
TASK-002 (DeterministicRNG)
    │
    │  provides: seeded random rolls
    ▼
TASK-011 (LootService) ◄──── TASK-007 (ItemDatabase)
    │                          provides: item lookups,
    │                          rarity filtering
    │  provides: resolved drops
    ▼
TASK-015 (Expedition Resolver)
    │
    │  feeds drops into: expedition results
    ▼
Player Inventory (TASK-007 InventoryData)
```

### Key Constraints & Design Decisions

1. **Determinism is non-negotiable.** Given the same RNG seed and the same table, `roll()` must always return the same items in the same order. This enables replay verification, anti-cheat validation, and offline economy simulation.
2. **No Godot Node dependency.** `LootService` extends `RefCounted`, not `Node`. It has no scene tree dependency and can be instantiated in tests without a running engine.
3. **Weight-based selection only.** We use cumulative weight selection, not percentage-based. Weights are integers; the probability of any entry is `weight / total_weight`. This makes tables easy to tune — adding an entry does not require rebalancing percentages.
4. **Quantity ranges are inclusive.** `min_qty` through `max_qty` are both inclusive bounds, resolved via `rng.randi_range(min_qty, max_qty)`.
5. **Currency drops are formula-driven, not table-driven.** Currency amounts use `base × difficulty_mult × rarity_mult + variance` rather than loot table entries, because currency needs smooth scaling rather than discrete weight tiers.
6. **LootTables is data-only.** It contains no logic, only `const` arrays of dictionaries. This separation keeps data tuning isolated from algorithmic changes.
7. **Rarity filtering is applied post-selection.** `roll_with_rarity_filter` rolls from the full table, then discards items below the minimum rarity. This means the effective drop rate of qualifying items increases, which matches the GDD's intent for boss rooms and high-difficulty encounters.

---

## 3. Use Cases

### Use Case 1: Kai the Speedrunner — Combat Room Loot

**Persona:** Kai optimizes runs for speed. He clears combat rooms as fast as possible and expects consistent, predictable drops so he can plan his economy.

**Scenario:** Kai enters a difficulty-3 combat room. The expedition resolver calls `loot_service.roll("combat_common", rng, 2)` to generate 2 drops from the common combat table. The RNG, seeded from the dungeon seed + room index, produces an `iron_sword` (qty 1) and `gold_coins` (qty 12). Kai also receives currency from `roll_currency(RoomType.COMBAT, 3, rng)` which yields `{ GOLD: 18 }`. The drops are identical every time Kai replays this seed — he can plan his route knowing exactly what each room yields.

**System Touchpoints:**
- `LootService.roll()` — weighted item selection
- `LootService.roll_currency()` — formula-based gold drop
- `DeterministicRNG` — seeded randomness
- `ItemDatabase` — item existence validation (downstream)

### Use Case 2: Luna the Completionist — Boss Room Rare+ Filter

**Persona:** Luna hunts every rare item in the game. She specifically targets boss rooms because they guarantee rare-or-better drops per the GDD.

**Scenario:** Luna reaches the boss room at difficulty 8. The expedition resolver calls `loot_service.roll_with_rarity_filter("boss_loot", rng, Enums.ItemRarity.RARE, item_db)` to generate boss drops filtered to RARE or above. The boss table has weighted entries spanning all rarities, but the filter discards any COMMON or UNCOMMON results. The method re-rolls (consuming RNG state deterministically) until it produces a qualifying item. Luna receives an `epic_flame_blade` — the same one she would always get from this seed at this difficulty. She logs it in her collection and moves on.

**System Touchpoints:**
- `LootService.roll_with_rarity_filter()` — rarity-gated selection
- `ItemDatabase.get_item()` — rarity lookup for filter
- `DeterministicRNG` — deterministic re-rolls
- `Enums.ItemRarity` — rarity threshold enum

### Use Case 3: Sam the Casual — Treasure Room Discovery

**Persona:** Sam plays casually and loves opening treasure chests. The thrill of a big gold haul keeps him engaged.

**Scenario:** Sam opens a treasure chest in a difficulty-5 treasure room. The resolver calls `loot_service.roll("treasure_common", rng, 3)` for 3 item drops, then `roll_currency(RoomType.TREASURE, 5, rng)` for currency. The treasure table has higher weights on gold_coins and gems compared to combat tables. Sam receives `gold_coins` (qty 45), `health_potion` (qty 2), and `iron_ore` (qty 3), plus `{ GOLD: 120 }` from the currency formula. The treasure room multiplier (2.5× base) ensures Sam's haul feels meaningfully larger than combat rooms.

**System Touchpoints:**
- `LootService.roll()` — multi-drop treasure selection
- `LootService.roll_currency()` — treasure room multiplier
- `LootTables.TREASURE_COMMON` — treasure-weighted entries

### Use Case 4: Designer Tuning Session — Economy Simulation

**Persona:** A game designer is running 10,000 simulated expeditions to validate gold faucet rates.

**Scenario:** The designer instantiates `LootService`, registers all default tables from `LootTables`, and loops through 10,000 seeds. For each seed, they simulate a 10-room expedition, calling `roll()` and `roll_currency()` for each room, and aggregating total gold output. Because `LootService` is `RefCounted` with no Node dependencies, this runs in a headless test script in under 2 seconds. The designer discovers that treasure rooms at difficulty 10 yield 15% more gold than intended and adjusts the `TREASURE_CURRENCY_MULT` constant.

**System Touchpoints:**
- `LootService` — full API surface
- `LootTables` — all pre-built tables
- `DeterministicRNG` — thousands of seeded runs
- No scene tree required

---

## 4. Glossary

| Term | Definition |
|---|---|
| **Loot Table** | A named collection of weighted entries, each mapping an item ID to a weight and quantity range. The engine selects entries probabilistically based on weight. |
| **Weight** | An integer assigned to a loot table entry. The probability of selecting that entry is `weight / sum(all_weights)`. Higher weight = more likely. |
| **Drop** | A resolved loot result: a concrete `{ item_id, qty }` dictionary produced by rolling against a loot table. |
| **Roll** | A single invocation of the weighted selection algorithm against a loot table, consuming RNG state and producing one drop. |
| **Rarity Tier** | One of five quality levels for items: COMMON, UNCOMMON, RARE, EPIC, LEGENDARY. Determines visual treatment, stat scaling, and drop probability. |
| **Rarity Filter** | A post-roll filter that discards items below a minimum rarity threshold. Used for boss rooms and high-difficulty encounters to guarantee quality drops. |
| **Currency Faucet** | Any system that generates currency for the player. Loot drops are the primary faucet; currency sinks (shops, upgrades) balance it. |
| **Difficulty Multiplier** | A scaling factor applied to currency drops based on room difficulty (1–10). Higher difficulty = more currency per room. |
| **Deterministic RNG** | A pseudo-random number generator that produces identical sequences from identical seeds. Ensures all loot is reproducible. |
| **DeterministicRNG** | The project's specific RNG class (TASK-002) providing `pick_weighted()`, `randi_range()`, and other seeded random methods. |
| **Cumulative Weight Selection** | Algorithm where weights are summed into a running total, a random value in `[0, total)` is generated, and the first entry whose cumulative weight exceeds the random value is selected. |
| **Pre-built Table** | A loot table defined as a constant in `LootTables` — shipped with the game, not user-created. Examples: `combat_common`, `boss_loot`. |
| **Room Type** | One of six expedition room categories: COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS. Each has distinct loot rules. |
| **Quantity Range** | The `[min_qty, max_qty]` inclusive bounds for how many of an item drop in a single roll. Resolved via `rng.randi_range()`. |
| **Loot Bias** | A per-seed modifier from the world generation system that shifts which currency types are favored in drops. Implemented by TASK-015, not this task. |
| **RefCounted** | Godot's reference-counted base class. Objects are freed when no references remain. No scene tree dependency. |
| **GUT** | Godot Unit Testing framework. The test runner used for all automated tests in Dungeon Seed. |
| **Faucet-Sink Model** | Economic design pattern where faucets (loot, quest rewards) generate resources and sinks (shops, upgrades, repairs) consume them. Balance requires sink ≈ faucet over time. |

---

## 5. Out of Scope

The following are **explicitly excluded** from TASK-011. Each exclusion references the task or future work where it will be addressed.

| # | Exclusion | Rationale / Cross-Reference |
|---|---|---|
| OOS-1 | **Loot bias from seed rarity** — shifting drop tables based on the dungeon seed's element or rarity tier. | Handled by TASK-015 (Expedition Resolver) which applies bias modifiers before calling `LootService.roll()`. |
| OOS-2 | **Class-specific loot bonuses** — e.g., Rogue gets +20% treasure room drops. | Applied by TASK-015 as a post-roll multiplier based on party composition. LootService is class-agnostic. |
| OOS-3 | **Inventory capacity enforcement** — checking whether the player has room for drops. | Handled by TASK-007 (InventoryData). LootService generates drops; inventory decides whether to accept them. |
| OOS-4 | **Drop UI / loot popup rendering** — visual presentation of loot rewards. | Handled by the UI layer (future UI task). This task produces data dictionaries, not visual elements. |
| OOS-5 | **Item creation / stat generation** — generating new ItemData instances from drops. | LootService returns `{ item_id, qty }` references. The caller uses `ItemDatabase.get_item()` to resolve full item data. |
| OOS-6 | **Loot table hot-reloading** — reloading tables from disk at runtime for live tuning. | Future tooling task. Current tables are compiled constants. Designers modify `loot_tables.gd` and rebuild. |
| OOS-7 | **Multiplayer loot splitting** — dividing drops among multiple players. | Dungeon Seed is single-player. If multiplayer is added later, loot splitting would be a new task. |
| OOS-8 | **Drop animation / particle effects** — visual feedback when items drop. | VFX task, not gameplay logic. LootService is a pure data service with no rendering. |
| OOS-9 | **Pity system / bad luck protection** — guaranteeing drops after N unsuccessful rolls. | Potential future feature. Current design relies on deterministic seeds — players re-roll seeds, not loot. |
| OOS-10 | **Crafting material recipes** — using dropped materials in crafting. | Crafting system is a separate future epic. Materials drop as items; their use is not this task's concern. |
| OOS-11 | **Shop pricing / sell values** — determining what dropped items sell for. | Sell values are defined on `ItemData` (TASK-007). LootService does not interact with shops. |
| OOS-12 | **Loot table editor tool** — a GUI for designers to create/edit loot tables. | Future tooling epic. Current workflow is direct code editing of `loot_tables.gd`. |
| OOS-13 | **Expedition reward summary screen** — aggregating all drops from a full expedition. | Handled by TASK-015 (Expedition Resolver) which accumulates drops across all rooms. |
| OOS-14 | **Save/load of custom loot tables** — persisting player-created or mod tables. | No modding system in current scope. Tables are static constants. |

---

## 6. Functional Requirements

### 6.1 Table Registration & Retrieval

| ID | Requirement | Priority |
|---|---|---|
| FR-001 | `LootService` SHALL provide `register_table(table_id: String, entries: Array[Dictionary]) -> void` that stores a named loot table for later retrieval. | MUST |
| FR-002 | `register_table` SHALL validate that each entry dictionary contains keys `item_id` (String), `weight` (int > 0), `min_qty` (int >= 1), and `max_qty` (int >= min_qty). | MUST |
| FR-003 | `register_table` SHALL overwrite any previously registered table with the same `table_id` without error. | MUST |
| FR-004 | `register_table` SHALL reject entries with `weight <= 0` by printing a warning and skipping the invalid entry. | SHOULD |
| FR-005 | `LootService` SHALL provide `get_table(table_id: String) -> Array[Dictionary]` returning a copy of the registered entries, or an empty array if the table does not exist. | MUST |
| FR-006 | `LootService` SHALL provide `has_table(table_id: String) -> bool` returning `true` if the table is registered. | MUST |
| FR-007 | `register_table` SHALL accept an empty entries array and store it as a valid (but unrollable) table. | SHOULD |

### 6.2 Rolling & Drop Resolution

| ID | Requirement | Priority |
|---|---|---|
| FR-010 | `LootService` SHALL provide `roll(table_id: String, rng: DeterministicRNG, count: int = 1) -> Array[Dictionary]` returning an array of `{ "item_id": String, "qty": int }` dictionaries. | MUST |
| FR-011 | `roll()` SHALL select each drop by computing cumulative weights across all entries in the table and using `rng` to pick a weighted entry. | MUST |
| FR-012 | `roll()` SHALL resolve quantity for each drop by calling `rng.randi_range(entry.min_qty, entry.max_qty)`. | MUST |
| FR-013 | `roll()` SHALL return exactly `count` drops when the table is non-empty. | MUST |
| FR-014 | `roll()` SHALL return an empty array if the table does not exist or is empty. | MUST |
| FR-015 | `roll()` SHALL NOT modify the registered table entries (no side effects on table state). | MUST |
| FR-016 | `roll()` SHALL be deterministic: identical `rng` state and identical `table_id` SHALL always produce identical results. | MUST |
| FR-017 | `roll()` SHALL support `count` values from 1 to 100 inclusive. Values outside this range SHALL be clamped. | SHOULD |

### 6.3 Rarity-Filtered Rolling

| ID | Requirement | Priority |
|---|---|---|
| FR-020 | `LootService` SHALL provide `roll_with_rarity_filter(table_id: String, rng: DeterministicRNG, min_rarity: Enums.ItemRarity, item_db: ItemDatabase) -> Array[Dictionary]` returning a single drop meeting the rarity threshold. | MUST |
| FR-021 | `roll_with_rarity_filter()` SHALL roll from the full table, check the item's rarity via `item_db.get_item(item_id).rarity`, and discard results below `min_rarity`. | MUST |
| FR-022 | `roll_with_rarity_filter()` SHALL retry up to a maximum of 100 rolls if the result does not meet the rarity threshold, to prevent infinite loops. | MUST |
| FR-023 | `roll_with_rarity_filter()` SHALL return an empty array if no qualifying item is found within the retry limit. | MUST |
| FR-024 | `roll_with_rarity_filter()` SHALL consume RNG state consistently regardless of how many retries occur (deterministic). | MUST |
| FR-025 | `roll_with_rarity_filter()` SHALL return `[{ "item_id": String, "qty": int }]` in the same format as `roll()`. | MUST |

### 6.4 Currency Drops

| ID | Requirement | Priority |
|---|---|---|
| FR-030 | `LootService` SHALL provide `roll_currency(room_type: Enums.RoomType, difficulty: int, rng: DeterministicRNG) -> Dictionary` returning `{ Enums.Currency: int }` mappings. | MUST |
| FR-031 | `roll_currency()` SHALL compute gold amount as `base_gold × difficulty_mult × room_type_mult`, where `base_gold` is a configurable constant. | MUST |
| FR-032 | `roll_currency()` SHALL apply a variance factor of ±20% using `rng.randf()` to the computed gold amount. | MUST |
| FR-033 | `roll_currency()` SHALL return Gold for all room types, with room-specific multipliers: COMBAT=1.0, TREASURE=2.5, TRAP=0.3, PUZZLE=1.5, REST=0.0, BOSS=3.0. | MUST |
| FR-034 | `roll_currency()` SHALL return Verdant Essence for BOSS and TREASURE rooms only, scaled by difficulty. | SHOULD |
| FR-035 | `roll_currency()` SHALL clamp all currency values to a minimum of 0 (no negative drops). | MUST |
| FR-036 | `roll_currency()` SHALL round all currency values to integers. | MUST |
| FR-037 | `roll_currency()` SHALL return an empty dictionary for REST rooms (no currency from rest). | MUST |
| FR-038 | `roll_currency()` SHALL scale difficulty multiplier linearly: `difficulty_mult = 1.0 + (difficulty - 1) * 0.15`. | MUST |

### 6.5 Pre-Built Tables

| ID | Requirement | Priority |
|---|---|---|
| FR-040 | `LootTables` SHALL define `COMBAT_COMMON` as a const Array[Dictionary] with at least 6 entries weighted toward common items and gold. | MUST |
| FR-041 | `LootTables` SHALL define `COMBAT_RARE` as a const Array[Dictionary] with entries shifted toward uncommon and rare items. | MUST |
| FR-042 | `LootTables` SHALL define `TREASURE_COMMON` as a const Array[Dictionary] with higher gold and gem weights than combat tables. | MUST |
| FR-043 | `LootTables` SHALL define `TREASURE_RARE` as a const Array[Dictionary] with entries spanning rare through legendary items. | MUST |
| FR-044 | `LootTables` SHALL define `BOSS_LOOT` as a const Array[Dictionary] with entries biased toward rare+ items and unique boss drops. | MUST |
| FR-045 | `LootTables` SHALL define `TRAP_CONSOLATION` as a const Array[Dictionary] with low-value entries (minor potions, small gold). | MUST |
| FR-046 | `LootTables` SHALL define `PUZZLE_REWARD` as a const Array[Dictionary] with entries biased toward utility items and essences. | MUST |
| FR-047 | `LootTables` SHALL provide `static func get_all_tables() -> Dictionary` returning `{ table_id: entries }` for all pre-built tables. | MUST |
| FR-048 | Every entry in every pre-built table SHALL reference an item_id that exists in the base ItemDatabase. | MUST |
| FR-049 | All pre-built table weights SHALL sum to at least 100 per table. | SHOULD |

### 6.6 Validation & Error Handling

| ID | Requirement | Priority |
|---|---|---|
| FR-050 | `LootService` SHALL print a warning (not crash) when `roll()` is called with an unregistered table_id. | MUST |
| FR-051 | `LootService` SHALL print a warning when `register_table()` receives an entry missing required keys. | MUST |
| FR-052 | `LootService` SHALL handle `null` RNG gracefully by returning an empty array and printing an error. | MUST |
| FR-053 | `LootService` SHALL validate `difficulty` parameter in `roll_currency()` is between 1 and 10, clamping if out of range. | SHOULD |

---

## 7. Non-Functional Requirements

| ID | Requirement | Category | Priority |
|---|---|---|---|
| NFR-001 | `LootService.roll()` SHALL complete a single roll in under 0.1ms on average (measured over 10,000 calls). | Performance | MUST |
| NFR-002 | `LootService.roll_currency()` SHALL complete in under 0.05ms per call. | Performance | MUST |
| NFR-003 | `LootService` SHALL produce zero allocations beyond the returned result arrays (no intermediate throwaway objects). | Memory | SHOULD |
| NFR-004 | `LootService` SHALL support at least 100 registered tables simultaneously without degradation. | Scalability | MUST |
| NFR-005 | `LootService` SHALL have no dependency on the Godot scene tree (`Node`, `SceneTree`, `get_tree()`). | Architecture | MUST |
| NFR-006 | `LootService` SHALL be instantiable and fully functional in headless GUT test runs without a display server. | Testability | MUST |
| NFR-007 | All public methods SHALL have static return type hints and parameter type hints. | Code Quality | MUST |
| NFR-008 | All public methods SHALL have `##` doc comments describing parameters, return values, and behavior. | Code Quality | MUST |
| NFR-009 | `LootTables` constant data SHALL be defined as `const` to prevent runtime mutation. | Immutability | MUST |
| NFR-010 | `LootService` SHALL achieve 100% determinism: given identical inputs (same RNG state, same table), output SHALL be bit-identical across runs, platforms, and Godot versions. | Determinism | MUST |
| NFR-011 | Test coverage SHALL include at least 20 distinct test methods covering all public API surface. | Testing | MUST |
| NFR-012 | All GDScript files SHALL pass Godot 4.6 static analysis with zero errors and zero warnings. | Code Quality | MUST |
| NFR-013 | `LootService` memory footprint SHALL remain under 1MB with all 7 pre-built tables registered. | Memory | SHOULD |
| NFR-014 | `LootTables` SHALL be loadable via `const` without triggering autoload or file I/O at runtime. | Performance | MUST |
| NFR-015 | `roll_with_rarity_filter()` SHALL complete within 1ms even in worst-case retry scenarios (100 retries). | Performance | MUST |
| NFR-016 | All numeric constants (base gold, multipliers, retry limits) SHALL be defined as named constants, not magic numbers. | Maintainability | MUST |
| NFR-017 | The system SHALL support future extension with new table types without modifying `LootService` core logic. | Extensibility | SHOULD |

---

## 8. Designer's Manual

### 8.1 Overview

The Loot Table Engine is your primary tool for controlling what players receive from every room in every expedition. This manual covers how to tune drop rates, add new items to tables, adjust currency formulas, and debug loot issues.

### 8.2 Loot Table Format

Each loot table is an array of entry dictionaries. Every entry has exactly four fields:

```gdscript
{
    "item_id": "iron_sword",   # Must match an ID in ItemDatabase
    "weight": 100,              # Relative probability (higher = more common)
    "min_qty": 1,               # Minimum quantity per drop (inclusive)
    "max_qty": 1                # Maximum quantity per drop (inclusive)
}
```

**Weight is relative, not absolute.** If a table has three entries with weights 100, 200, and 300, their drop probabilities are 16.7%, 33.3%, and 50.0% respectively (100/600, 200/600, 300/600). You can use any positive integers — the system normalizes automatically.

**Design tip:** Use weights in the 10–1000 range for fine-grained control. Very small weights (1–5) make it hard to fine-tune; very large weights (10,000+) are unwieldy.

### 8.3 Pre-Built Table Reference

| Table ID | Room Type | Bias | Total Weight | Entry Count | Notes |
|---|---|---|---|---|---|
| `combat_common` | COMBAT | Common gear, gold | ~1000 | 8 | Default combat room drops |
| `combat_rare` | COMBAT | Uncommon+ gear | ~600 | 6 | High-difficulty combat rooms |
| `treasure_common` | TREASURE | Gold, gems, potions | ~1200 | 8 | Standard treasure chests |
| `treasure_rare` | TREASURE | Rare+ gear, essences | ~500 | 6 | Rare treasure rooms |
| `boss_loot` | BOSS | Rare+, unique items | ~400 | 7 | Guaranteed quality drops |
| `trap_consolation` | TRAP | Minor potions, scraps | ~800 | 5 | Consolation for trap damage |
| `puzzle_reward` | PUZZLE | Utility, essences | ~700 | 6 | Reward for puzzle solving |

### 8.4 Currency Formula Reference

The currency drop formula is:

```
final_amount = round(base_gold × difficulty_mult × room_type_mult × (1.0 + variance))
```

Where:
- `base_gold = 10` — configurable constant
- `difficulty_mult = 1.0 + (difficulty - 1) × 0.15` — linear scaling from difficulty 1 (1.0×) to 10 (2.35×)
- `room_type_mult` — per room type:
  - COMBAT: 1.0
  - TREASURE: 2.5
  - TRAP: 0.3
  - PUZZLE: 1.5
  - REST: 0.0 (no currency)
  - BOSS: 3.0
- `variance` — random float in range `[-0.2, +0.2]` from `rng.randf() * 0.4 - 0.2`

**Example:** Difficulty 5 TREASURE room:
```
difficulty_mult = 1.0 + (5-1) × 0.15 = 1.6
base = 10 × 1.6 × 2.5 = 40.0
with +10% variance: round(40.0 × 1.1) = 44 Gold
```

**Verdant Essence** drops only from BOSS and TREASURE rooms:
```
essence_amount = round(difficulty × 0.5 × room_essence_mult)
```
Where `room_essence_mult` is 1.0 for TREASURE, 2.0 for BOSS.

### 8.5 Tuning Guide

#### How to Make an Item Drop More Often
Increase its `weight` in the relevant table. Example: to double the drop rate of `health_potion` in `combat_common`, change its weight from 150 to 300.

#### How to Add a New Item to a Table
Add a new entry dictionary to the table's const array in `loot_tables.gd`:
```gdscript
{ "item_id": "new_item_id", "weight": 100, "min_qty": 1, "max_qty": 3 },
```
Ensure `new_item_id` exists in ItemDatabase.

#### How to Create a New Loot Table
1. Define a new const in `loot_tables.gd`:
```gdscript
const MY_NEW_TABLE: Array[Dictionary] = [
    { "item_id": "item_a", "weight": 100, "min_qty": 1, "max_qty": 1 },
    { "item_id": "item_b", "weight": 200, "min_qty": 1, "max_qty": 5 },
]
```
2. Add it to `get_all_tables()` return dictionary.
3. Register it in `LootService` via `register_table("my_new_table", LootTables.MY_NEW_TABLE)`.

#### How to Increase Gold Drops Globally
Increase `BASE_GOLD` in `loot_service.gd`. This scales all rooms proportionally.

#### How to Increase Gold for a Specific Room Type
Modify the room type multiplier in `ROOM_CURRENCY_MULT`. Example: change TREASURE from 2.5 to 3.0 for richer chests.

#### How to Make Boss Drops Guaranteed Epic+
Call `roll_with_rarity_filter()` with `min_rarity = Enums.ItemRarity.EPIC` in the expedition resolver. No changes to LootService needed.

### 8.6 Configuration Constants

All tunable constants are defined at the top of `loot_service.gd`:

```gdscript
const BASE_GOLD: int = 10
const DIFFICULTY_SCALE: float = 0.15
const VARIANCE_RANGE: float = 0.2
const MAX_RARITY_RETRIES: int = 100
const MAX_ROLL_COUNT: int = 100
const ESSENCE_BASE_MULT: float = 0.5
const BOSS_ESSENCE_MULT: float = 2.0
const TREASURE_ESSENCE_MULT: float = 1.0

const ROOM_CURRENCY_MULT: Dictionary = {
    Enums.RoomType.COMBAT: 1.0,
    Enums.RoomType.TREASURE: 2.5,
    Enums.RoomType.TRAP: 0.3,
    Enums.RoomType.PUZZLE: 1.5,
    Enums.RoomType.REST: 0.0,
    Enums.RoomType.BOSS: 3.0,
}
```

### 8.7 Debug Tools

#### Printing Table Contents
```gdscript
var entries: Array[Dictionary] = loot_service.get_table("combat_common")
for entry in entries:
    print("  %s  w=%d  qty=%d-%d" % [entry.item_id, entry.weight, entry.min_qty, entry.max_qty])
```

#### Simulating 1,000 Rolls for Distribution Analysis
```gdscript
var rng := DeterministicRNG.new()
rng.seed_int(42)
var counts: Dictionary = {}
for i in range(1000):
    var drops: Array[Dictionary] = loot_service.roll("combat_common", rng, 1)
    var item_id: String = drops[0].item_id
    counts[item_id] = counts.get(item_id, 0) + 1
for item_id in counts:
    print("  %s: %d (%.1f%%)" % [item_id, counts[item_id], counts[item_id] / 10.0])
```

#### Verifying Determinism
```gdscript
var rng_a := DeterministicRNG.new()
var rng_b := DeterministicRNG.new()
rng_a.seed_int(12345)
rng_b.seed_int(12345)
var drops_a: Array[Dictionary] = loot_service.roll("combat_common", rng_a, 5)
var drops_b: Array[Dictionary] = loot_service.roll("combat_common", rng_b, 5)
assert(drops_a == drops_b, "Determinism check failed!")
```

#### Currency Formula Debug Output
```gdscript
var rng := DeterministicRNG.new()
rng.seed_int(99)
for difficulty in range(1, 11):
    var currency: Dictionary = loot_service.roll_currency(Enums.RoomType.COMBAT, difficulty, rng)
    print("  diff=%d  gold=%d" % [difficulty, currency.get(Enums.Currency.GOLD, 0)])
```

### 8.8 Signal Map

`LootService` emits no signals. It is a pure computational service — all outputs are return values. This is intentional: signals would introduce ordering dependencies and make determinism harder to verify.

If downstream systems need event-driven loot notifications (e.g., UI popups), the caller (expedition resolver) should emit signals after receiving drops from `LootService`, not `LootService` itself.

### 8.9 Integration Points

| System | Direction | Data Exchanged |
|---|---|---|
| DeterministicRNG (TASK-002) | LootService ← RNG | Seeded random values for weighted selection and quantity resolution |
| ItemDatabase (TASK-007) | LootService ← ItemDB | Item rarity lookups for `roll_with_rarity_filter()` |
| Expedition Resolver (TASK-015) | LootService → Resolver | `[{ item_id, qty }]` drops and `{ Currency: amount }` for each room |
| LootTables (this task) | LootService ← LootTables | Pre-built table definitions registered at initialization |

---

## 9. Assumptions

### Engine & Platform Assumptions

| # | Assumption | Impact if Wrong |
|---|---|---|
| A-001 | Godot 4.6 is the target engine version. GDScript static typing, typed arrays, and `class_name` registration work as documented. | Build failures; must adapt syntax. |
| A-002 | GUT (Godot Unit Testing) framework is installed and configured at `res://addons/gut/`. | Tests won't run; must install GUT or adapt to alternative framework. |
| A-003 | `RefCounted` subclasses can be instantiated in headless test environments without a display server or scene tree. | Must restructure as Node-based if RefCounted fails headless. |
| A-004 | `Dictionary` and `Array` comparison via `==` operator works for value equality (not reference equality) in GDScript. | Determinism tests may need custom comparison functions. |
| A-005 | GDScript `const` arrays of dictionaries are truly immutable at runtime — no code path can mutate them. | Must deep-copy table data on registration to prevent mutation. |

### Dependency Assumptions

| # | Assumption | Impact if Wrong |
|---|---|---|
| A-006 | TASK-002 `DeterministicRNG` provides `pick_weighted(options, weights)` that selects from parallel arrays deterministically. | Must implement custom cumulative weight selection in LootService. |
| A-007 | TASK-002 `DeterministicRNG.randi_range(min, max)` is inclusive on both bounds. | Quantity resolution may be off-by-one; must verify and adjust. |
| A-008 | TASK-002 `DeterministicRNG.randf()` returns values in `[0.0, 1.0)` range. | Variance formula must be adjusted if range differs. |
| A-009 | TASK-007 `ItemDatabase.get_item(id)` returns `null` for unknown IDs (not crash). | Must add null checks in `roll_with_rarity_filter()` or risk crashes. |
| A-010 | TASK-007 `ItemData.rarity` is always a valid `Enums.ItemRarity` enum value, never null or unset. | Must add rarity validation in filter method. |
| A-011 | TASK-003 `Enums.gd` is already implemented and registered as an autoload or `class_name`, making `Enums.RoomType.COMBAT` accessible. | Must import or preload Enums explicitly. |

### Design & Integration Assumptions

| # | Assumption | Impact if Wrong |
|---|---|---|
| A-012 | The expedition resolver (TASK-015) will call `LootService` methods directly — no event bus or signal intermediary. | Must add signal/event wrappers if resolver uses event-driven architecture. |
| A-013 | Item IDs in loot tables (e.g., `"iron_sword"`) will match IDs registered in `ItemDatabase` before any rolls occur. | Rolls will produce references to nonexistent items; must add validation. |
| A-014 | Room difficulty ranges from 1 to 10 inclusive, as defined in the GDD. | Currency formula scaling may over/under-produce if range differs. |
| A-015 | The GDD's stated rarity distribution (55% Common, 25% Uncommon, etc.) is a guideline for table weight design, not a hard runtime constraint. | Must add runtime distribution enforcement if weights must exactly match GDD percentages. |
| A-016 | Currency amounts are integers (no fractional gold). | Must change return types to float if fractional currency is needed. |
| A-017 | No concurrent access to LootService — single-threaded game loop. | Must add thread safety (mutexes) if multithreaded access is required. |

---

## 10. Security & Anti-Cheat

### Threat Model

Since Dungeon Seed uses deterministic RNG for all loot, the primary attack surface is **seed manipulation** and **table tampering**. This section documents known threats and mitigations.

### Threat 1: Seed Prediction for Optimal Loot

| Field | Detail |
|---|---|
| **Exploit** | Player discovers or brute-forces seeds that produce high-value drops in specific rooms, then shares "loot seeds" in communities. |
| **Attack Vector** | Offline seed enumeration using a copy of the loot tables and RNG algorithm. |
| **Impact** | Medium — undermines exploration incentive, but deterministic loot is a design feature (seed sharing is expected). |
| **Mitigation** | This is **by design** in Dungeon Seed. Seed sharing is a feature, not a bug. The GDD explicitly encourages players to share good seeds. No mitigation needed. |

### Threat 2: Loot Table Modification via Save File

| Field | Detail |
|---|---|
| **Exploit** | Player modifies the local game files to alter loot table weights — e.g., setting `boss_loot` to 100% legendary drops. |
| **Attack Vector** | Editing `loot_tables.gd` in the exported PCK, or modifying memory at runtime. |
| **Impact** | Medium — single-player game, so cheating affects only the cheater. No competitive/multiplayer impact. |
| **Mitigation** | Tables are compiled `const` values, not loaded from external files. PCK modification requires reverse engineering. Accept risk for single-player context. If leaderboards are added, validate server-side using reference tables. |

### Threat 3: RNG State Manipulation

| Field | Detail |
|---|---|
| **Exploit** | Player manipulates the RNG state mid-expedition (e.g., save-scumming between rooms) to reroll loot. |
| **Attack Vector** | Saving after seeing room contents, reloading to try different RNG paths. |
| **Impact** | Low — deterministic RNG means the same seed always produces the same loot regardless of save/load timing, as long as RNG consumption order is fixed. |
| **Mitigation** | RNG state is derived from seed + room index, not from a running counter. Each room's loot is computed from `seed_string(dungeon_seed + "_room_" + str(room_index))`, making save-scumming ineffective. |

### Threat 4: Memory Editing for Drop Quantities

| Field | Detail |
|---|---|
| **Exploit** | Player uses Cheat Engine or similar to modify the quantity values in returned drop dictionaries before they reach the inventory. |
| **Attack Vector** | Runtime memory scanning for known quantity values, then modification. |
| **Impact** | Low — single-player only. No economy damage to other players. |
| **Mitigation** | Accept risk for single-player. If competitive features are added, implement server-side drop verification by replaying the RNG sequence. |

### Threat 5: Injecting Custom Loot Tables

| Field | Detail |
|---|---|
| **Exploit** | Player calls `register_table()` with custom entries at runtime via GDScript console injection or modded scripts. |
| **Attack Vector** | Debug console access, script injection, or modded game builds. |
| **Impact** | Low — single-player, self-inflicted. |
| **Mitigation** | Disable debug console in release builds. Consider adding a `_frozen` flag that prevents table registration after initialization. Not implemented in this task — defer to hardening pass. |

### Threat 6: Denial of Service via Large Tables

| Field | Detail |
|---|---|
| **Exploit** | Malicious mod registers a table with millions of entries, causing `roll()` to consume excessive memory or CPU. |
| **Attack Vector** | Modded `loot_tables.gd` or runtime `register_table()` calls with massive arrays. |
| **Impact** | Low — self-inflicted performance degradation. |
| **Mitigation** | Add an entry count limit (e.g., 1000 entries per table) in `register_table()`. Log warning if exceeded. |

---

## 11. Best Practices

### Architecture

| # | Practice | Rationale |
|---|---|---|
| BP-001 | **Extend RefCounted, not Node.** LootService has no rendering, no process loop, no scene tree interaction. RefCounted enables lightweight instantiation in tests and simulations. | Decouples from engine lifecycle; enables headless testing. |
| BP-002 | **Separate data from logic.** `LootTables` holds static const data; `LootService` holds algorithms. Changes to drop weights never touch algorithmic code, and vice versa. | Single Responsibility Principle; reduces merge conflicts. |
| BP-003 | **Use dependency injection for RNG and ItemDB.** Pass `DeterministicRNG` and `ItemDatabase` as method parameters, not as constructor-injected fields or globals. This makes each call self-contained and testable. | Testability; determinism; no hidden state. |
| BP-004 | **Return new arrays, never internal references.** `get_table()` and `roll()` return copies, not references to internal state. Callers cannot accidentally mutate service state. | Defensive programming; prevents side-effect bugs. |

### Code Quality

| # | Practice | Rationale |
|---|---|---|
| BP-005 | **Static type hints on every declaration.** All variables, parameters, and return types use explicit type annotations (`var x: int`, `func f() -> Array[Dictionary]`). | Catches bugs at parse time; self-documenting; enables IDE completion. |
| BP-006 | **Named constants for all magic numbers.** Every numeric literal used in formulas (base gold, multipliers, retry limits) is a `const` with a descriptive name. | Readable; tunable; searchable. |
| BP-007 | **Doc comments (`##`) on all public methods.** Every public function has a `##` comment block describing what it does, its parameters, and its return value. | Self-documenting API; GDScript documentation generator compatible. |
| BP-008 | **Snake_case everywhere.** Variables, functions, constants, file names — all snake_case per GDScript convention. Constants use UPPER_SNAKE_CASE. | GDScript style guide compliance. |

### Testing

| # | Practice | Rationale |
|---|---|---|
| BP-009 | **Test determinism explicitly.** Every test that uses RNG should seed with a known value and assert exact output values, not just "some output exists." | Catches RNG regression; validates the core determinism guarantee. |
| BP-010 | **Test edge cases: empty tables, zero count, max retries.** Don't just test the happy path. Exercise boundary conditions that real usage may never hit but bugs will. | Prevents silent failures in production edge cases. |
| BP-011 | **Test each table independently.** Each pre-built table gets its own test verifying it can be registered and rolled without errors. | Catches typos in item_ids, missing fields, weight=0 entries. |
| BP-012 | **Use factory methods in tests.** Create helper functions like `_make_rng(seed)` and `_make_service_with_tables()` to reduce test boilerplate. | DRY; readable tests; easy to update if constructor changes. |

### Performance

| # | Practice | Rationale |
|---|---|---|
| BP-013 | **Pre-compute total weight on registration.** When `register_table()` is called, compute and cache `total_weight` so `roll()` doesn't recompute it every call. | O(1) lookup per roll instead of O(n) summation. |
| BP-014 | **Avoid allocations in hot paths.** `roll()` should allocate only the result array. No intermediate arrays, no string formatting, no dictionary copies during selection. | Keeps GC pressure low during expeditions. |

---

## 12. Troubleshooting

### Issue 1: Rolls Always Return the Same Item

| Field | Detail |
|---|---|
| **Symptoms** | Every call to `roll()` returns the same `item_id` regardless of table contents. |
| **Likely Cause** | RNG is not being advanced between calls. The caller is re-seeding the RNG with the same value before each roll, resetting the state. |
| **Solution** | Ensure the RNG is seeded once per room (or per expedition), then passed to multiple `roll()` calls without re-seeding. Each `roll()` call advances the RNG state. |
| **Verification** | Seed RNG once, call `roll()` 10 times, verify that results vary (unless the table has only one entry). |

### Issue 2: Currency Always Returns 0

| Field | Detail |
|---|---|
| **Symptoms** | `roll_currency()` returns `{ GOLD: 0 }` or an empty dictionary for all room types. |
| **Likely Cause** | `room_type` is `REST` (which has a 0.0 multiplier), or `difficulty` is being passed as 0 (below the valid range). |
| **Solution** | Check that the caller is passing the correct `Enums.RoomType` value and a difficulty in the 1–10 range. REST rooms intentionally return no currency. |
| **Verification** | Call `roll_currency(Enums.RoomType.COMBAT, 5, rng)` directly and verify non-zero Gold. |

### Issue 3: `roll_with_rarity_filter()` Returns Empty Array

| Field | Detail |
|---|---|
| **Symptoms** | Boss room drops are empty despite having a valid `boss_loot` table registered. |
| **Likely Cause** | The `min_rarity` threshold is set too high (e.g., LEGENDARY), and the table has no entries that qualify within 100 retries. Or `ItemDatabase` does not have the items registered, so `get_item()` returns null. |
| **Solution** | Ensure the table contains items at or above the requested rarity. Verify all `item_id` values in the table are registered in `ItemDatabase` before rolling. Lower the `min_rarity` threshold if appropriate. |
| **Verification** | Call `item_db.get_item(item_id)` for every entry in the table and verify non-null results with valid rarity values. |

### Issue 4: Non-Deterministic Results Across Runs

| Field | Detail |
|---|---|
| **Symptoms** | Same seed produces different drops on different runs or different machines. |
| **Likely Cause** | Something is consuming RNG state between the seed and the roll — possibly another system calling the same RNG instance, or dictionary iteration order differing across platforms. |
| **Solution** | Ensure each room's loot uses a dedicated RNG instance seeded from `dungeon_seed + "_room_" + str(room_index)`, not a shared global RNG. Verify that dictionary iteration order is not affecting computation (use arrays for ordered data). |
| **Verification** | Run the same seed 100 times in a loop and assert all results are identical. |

### Issue 5: Table Registration Fails Silently

| Field | Detail |
|---|---|
| **Symptoms** | `has_table()` returns `false` after calling `register_table()`. |
| **Likely Cause** | All entries in the provided array failed validation (e.g., missing `item_id` key, `weight <= 0`). The table was registered with an empty entries array after filtering. |
| **Solution** | Check the Godot output console for validation warnings. Fix entry dictionaries to include all required keys with valid values. |
| **Verification** | Register a table with known-good entries and call `has_table()` immediately after. |

### Issue 6: Weight Distribution Doesn't Match Expected Probabilities

| Field | Detail |
|---|---|
| **Symptoms** | After 10,000 rolls, item distribution percentages don't match the expected weight ratios. |
| **Likely Cause** | Statistical variance at low sample counts, or a bug in the cumulative weight selection algorithm. |
| **Solution** | Increase sample count to 100,000+ for accurate distribution measurement. If distribution is still wrong, verify that `pick_weighted()` or the custom selection algorithm correctly normalizes weights. |
| **Verification** | Use the debug simulation script from Designer's Manual §8.7 with 100,000 rolls and compare actual percentages to expected `weight/total_weight` ratios within ±2% tolerance. |

### Issue 7: Performance Degradation with Many Tables

| Field | Detail |
|---|---|
| **Symptoms** | `roll()` takes >1ms after registering 50+ tables. |
| **Likely Cause** | Dictionary lookup is not the issue (O(1) hash lookup). More likely, individual table entry counts are very large (1000+ entries per table), causing slow cumulative weight computation. |
| **Solution** | Pre-compute and cache `total_weight` per table on registration (per BP-013). If individual tables are excessively large, consider splitting them into sub-tables. |
| **Verification** | Profile `roll()` with a 1000-entry table and verify it completes under 0.1ms. |

---

## 13. Acceptance Criteria

### Process Acceptance Criteria (PAC)

- [ ] **PAC-001:** `src/services/loot_service.gd` exists, declares `class_name LootService`, and extends `RefCounted`.
- [ ] **PAC-002:** `src/resources/loot_tables.gd` exists, declares `class_name LootTables`, and contains all 7 pre-built tables as `const` arrays.
- [ ] **PAC-003:** `tests/test_loot_service.gd` exists and contains at least 20 test methods.
- [ ] **PAC-004:** All GDScript files pass Godot 4.6 static analysis with zero errors.
- [ ] **PAC-005:** All public methods have `##` doc comments.
- [ ] **PAC-006:** All public methods have static type hints on parameters and return values.
- [ ] **PAC-007:** No magic numbers exist — all numeric constants are named `const` declarations.
- [ ] **PAC-008:** All test methods use real assertions (no `pass`, no `# TODO`, no stubs).
- [ ] **PAC-009:** Code follows GDScript snake_case naming convention throughout.
- [ ] **PAC-010:** `LootService` has no `extends Node`, no `@onready`, no `get_tree()`, no scene tree dependency.

### Behavioral Acceptance Criteria (BAC) — Table Registration

- [ ] **BAC-001:** `register_table("test_table", entries)` stores the table such that `has_table("test_table")` returns `true`.
- [ ] **BAC-002:** `has_table("nonexistent")` returns `false`.
- [ ] **BAC-003:** `get_table("test_table")` returns an array matching the registered entries.
- [ ] **BAC-004:** `get_table("nonexistent")` returns an empty array without crashing.
- [ ] **BAC-005:** Calling `register_table()` with the same `table_id` twice overwrites the first registration.
- [ ] **BAC-006:** `register_table()` with an empty entries array succeeds; `has_table()` returns `true`.
- [ ] **BAC-007:** `register_table()` skips entries with `weight <= 0` and logs a warning.
- [ ] **BAC-008:** `register_table()` skips entries missing required keys (`item_id`, `weight`, `min_qty`, `max_qty`) and logs a warning.
- [ ] **BAC-009:** `get_table()` returns a copy — modifying the returned array does not affect the internal table.

### Behavioral Acceptance Criteria (BAC) — Rolling

- [ ] **BAC-010:** `roll("combat_common", rng, 1)` returns an array with exactly 1 element.
- [ ] **BAC-011:** `roll("combat_common", rng, 5)` returns an array with exactly 5 elements.
- [ ] **BAC-012:** Each element in `roll()` result has keys `"item_id"` (String) and `"qty"` (int).
- [ ] **BAC-013:** `roll()` with `count=0` returns an empty array.
- [ ] **BAC-014:** `roll("nonexistent", rng, 1)` returns an empty array and prints a warning.
- [ ] **BAC-015:** `roll()` on an empty table returns an empty array.
- [ ] **BAC-016:** `roll()` quantity values are within `[min_qty, max_qty]` for the selected entry.
- [ ] **BAC-017:** `roll()` is deterministic: same RNG seed + same table → identical results, verified over 100 iterations.
- [ ] **BAC-018:** `roll()` with `count > MAX_ROLL_COUNT` clamps to `MAX_ROLL_COUNT`.
- [ ] **BAC-019:** `roll()` does not modify the registered table entries (no side effects).
- [ ] **BAC-020:** `roll()` with a `null` RNG returns an empty array and prints an error.

### Behavioral Acceptance Criteria (BAC) — Rarity Filter

- [ ] **BAC-021:** `roll_with_rarity_filter("boss_loot", rng, RARE, item_db)` returns only items with rarity >= RARE.
- [ ] **BAC-022:** `roll_with_rarity_filter()` returns `[{ item_id, qty }]` format matching `roll()`.
- [ ] **BAC-023:** `roll_with_rarity_filter()` returns an empty array if no qualifying item is found within 100 retries.
- [ ] **BAC-024:** `roll_with_rarity_filter()` is deterministic: same seed → same filtered result.
- [ ] **BAC-025:** `roll_with_rarity_filter()` with `min_rarity = COMMON` returns any item (no filtering).
- [ ] **BAC-026:** `roll_with_rarity_filter()` with an unknown item_id in the table (not in ItemDatabase) skips that entry gracefully.
- [ ] **BAC-027:** `roll_with_rarity_filter()` with a `null` ItemDatabase returns an empty array and prints an error.

### Behavioral Acceptance Criteria (BAC) — Currency

- [ ] **BAC-028:** `roll_currency(COMBAT, 1, rng)` returns a dictionary with `Enums.Currency.GOLD` key and a positive integer value.
- [ ] **BAC-029:** `roll_currency(REST, 5, rng)` returns an empty dictionary (no currency from rest rooms).
- [ ] **BAC-030:** `roll_currency(TREASURE, 5, rng)` returns Gold value significantly higher than `roll_currency(COMBAT, 5, rng)` (at least 2× on average).
- [ ] **BAC-031:** `roll_currency(BOSS, 5, rng)` returns Gold value higher than TREASURE at same difficulty.
- [ ] **BAC-032:** `roll_currency()` Gold values increase with difficulty (difficulty 10 > difficulty 1).
- [ ] **BAC-033:** `roll_currency()` is deterministic: same seed + same parameters → same currency amounts.
- [ ] **BAC-034:** `roll_currency(BOSS, 5, rng)` includes `Enums.Currency.ESSENCE` in the result dictionary.
- [ ] **BAC-035:** `roll_currency(TREASURE, 5, rng)` includes `Enums.Currency.ESSENCE` in the result dictionary.
- [ ] **BAC-036:** `roll_currency(COMBAT, 5, rng)` does NOT include `Enums.Currency.ESSENCE`.
- [ ] **BAC-037:** All currency values are non-negative integers (no fractions, no negatives).
- [ ] **BAC-038:** `roll_currency()` with difficulty 0 clamps to difficulty 1.
- [ ] **BAC-039:** `roll_currency()` with difficulty 15 clamps to difficulty 10.

### Behavioral Acceptance Criteria (BAC) — Pre-Built Tables

- [ ] **BAC-040:** `LootTables.get_all_tables()` returns a dictionary with exactly 7 keys.
- [ ] **BAC-041:** `LootTables.COMBAT_COMMON` is a non-empty const array of dictionaries.
- [ ] **BAC-042:** `LootTables.COMBAT_RARE` is a non-empty const array of dictionaries.
- [ ] **BAC-043:** `LootTables.TREASURE_COMMON` is a non-empty const array of dictionaries.
- [ ] **BAC-044:** `LootTables.TREASURE_RARE` is a non-empty const array of dictionaries.
- [ ] **BAC-045:** `LootTables.BOSS_LOOT` is a non-empty const array of dictionaries.
- [ ] **BAC-046:** `LootTables.TRAP_CONSOLATION` is a non-empty const array of dictionaries.
- [ ] **BAC-047:** `LootTables.PUZZLE_REWARD` is a non-empty const array of dictionaries.
- [ ] **BAC-048:** Every entry in every pre-built table has all four required keys: `item_id`, `weight`, `min_qty`, `max_qty`.
- [ ] **BAC-049:** Every entry in every pre-built table has `weight > 0`, `min_qty >= 1`, and `max_qty >= min_qty`.
- [ ] **BAC-050:** All pre-built tables can be registered and rolled without errors.

### Behavioral Acceptance Criteria (BAC) — Integration

- [ ] **BAC-051:** `LootService` can be instantiated with `LootService.new()` without a scene tree.
- [ ] **BAC-052:** All 7 pre-built tables from `LootTables.get_all_tables()` can be registered in a single `LootService` instance.
- [ ] **BAC-053:** A simulated 10-room expedition using all relevant roll methods completes without errors.
- [ ] **BAC-054:** Rolling 1,000 times from `combat_common` produces a distribution where every entry appears at least once.
- [ ] **BAC-055:** The total Gold from 1,000 difficulty-5 COMBAT rooms falls within expected range (±15% of theoretical mean).

---

## 14. Testing Requirements

All tests use the GUT framework and target `tests/test_loot_service.gd`.

```gdscript
## tests/test_loot_service.gd
## GUT test suite for LootService and LootTables.
## Covers registration, rolling, rarity filtering, currency, pre-built tables, and determinism.
extends GutTest

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

var _service: LootService
var _rng: DeterministicRNG

const SIMPLE_TABLE: Array[Dictionary] = [
	{ "item_id": "sword", "weight": 100, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "shield", "weight": 200, "min_qty": 1, "max_qty": 2 },
	{ "item_id": "potion", "weight": 300, "min_qty": 1, "max_qty": 5 },
]

const SINGLE_ENTRY_TABLE: Array[Dictionary] = [
	{ "item_id": "only_item", "weight": 100, "min_qty": 3, "max_qty": 3 },
]

const RARITY_TEST_TABLE: Array[Dictionary] = [
	{ "item_id": "common_gem", "weight": 500, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "uncommon_ring", "weight": 300, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "rare_blade", "weight": 150, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "epic_staff", "weight": 40, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "legendary_crown", "weight": 10, "min_qty": 1, "max_qty": 1 },
]

func _make_rng(seed_val: int = 42) -> DeterministicRNG:
	var rng := DeterministicRNG.new()
	rng.seed_int(seed_val)
	return rng

func _make_item_db() -> ItemDatabase:
	var db := ItemDatabase.new()
	var items: Array[Dictionary] = [
		{ "id": "common_gem", "rarity": Enums.ItemRarity.COMMON },
		{ "id": "uncommon_ring", "rarity": Enums.ItemRarity.UNCOMMON },
		{ "id": "rare_blade", "rarity": Enums.ItemRarity.RARE },
		{ "id": "epic_staff", "rarity": Enums.ItemRarity.EPIC },
		{ "id": "legendary_crown", "rarity": Enums.ItemRarity.LEGENDARY },
		{ "id": "sword", "rarity": Enums.ItemRarity.COMMON },
		{ "id": "shield", "rarity": Enums.ItemRarity.COMMON },
		{ "id": "potion", "rarity": Enums.ItemRarity.COMMON },
		{ "id": "only_item", "rarity": Enums.ItemRarity.RARE },
	]
	for item_dict in items:
		var item := ItemData.new()
		item.id = item_dict.id
		item.rarity = item_dict.rarity
		item.display_name = item_dict.id.capitalize()
		db.register_item(item)
	return db

func before_each() -> void:
	_service = LootService.new()
	_rng = _make_rng(42)

# ---------------------------------------------------------------------------
# Section A: Table Registration & Retrieval
# ---------------------------------------------------------------------------

func test_register_and_has_table() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	assert_true(_service.has_table("test"), "Table should be registered")

func test_has_table_returns_false_for_unknown() -> void:
	assert_false(_service.has_table("nonexistent"), "Unknown table should return false")

func test_get_table_returns_entries() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	var entries: Array[Dictionary] = _service.get_table("test")
	assert_eq(entries.size(), 3, "Should return 3 entries")
	assert_eq(entries[0].item_id, "sword", "First entry should be sword")

func test_get_table_returns_copy() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	var entries: Array[Dictionary] = _service.get_table("test")
	entries.clear()
	var original: Array[Dictionary] = _service.get_table("test")
	assert_eq(original.size(), 3, "Original table should be unaffected by clearing returned copy")

func test_get_table_unknown_returns_empty() -> void:
	var entries: Array[Dictionary] = _service.get_table("nonexistent")
	assert_eq(entries.size(), 0, "Unknown table should return empty array")

func test_register_table_overwrites_existing() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	_service.register_table("test", SINGLE_ENTRY_TABLE)
	var entries: Array[Dictionary] = _service.get_table("test")
	assert_eq(entries.size(), 1, "Overwritten table should have 1 entry")
	assert_eq(entries[0].item_id, "only_item", "Entry should be from second registration")

func test_register_empty_table() -> void:
	var empty: Array[Dictionary] = []
	_service.register_table("empty", empty)
	assert_true(_service.has_table("empty"), "Empty table should still be registered")
	assert_eq(_service.get_table("empty").size(), 0, "Empty table should have 0 entries")

func test_register_skips_zero_weight_entries() -> void:
	var bad_entries: Array[Dictionary] = [
		{ "item_id": "good", "weight": 100, "min_qty": 1, "max_qty": 1 },
		{ "item_id": "bad", "weight": 0, "min_qty": 1, "max_qty": 1 },
	]
	_service.register_table("partial", bad_entries)
	var entries: Array[Dictionary] = _service.get_table("partial")
	assert_eq(entries.size(), 1, "Should skip zero-weight entry")
	assert_eq(entries[0].item_id, "good", "Only valid entry should remain")

func test_register_skips_entries_missing_keys() -> void:
	var incomplete: Array[Dictionary] = [
		{ "item_id": "valid", "weight": 100, "min_qty": 1, "max_qty": 1 },
		{ "item_id": "no_weight", "min_qty": 1, "max_qty": 1 },
		{ "weight": 50, "min_qty": 1, "max_qty": 1 },
	]
	_service.register_table("incomplete", incomplete)
	var entries: Array[Dictionary] = _service.get_table("incomplete")
	assert_eq(entries.size(), 1, "Should only keep the fully valid entry")

# ---------------------------------------------------------------------------
# Section B: Rolling
# ---------------------------------------------------------------------------

func test_roll_returns_correct_count() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	var drops: Array[Dictionary] = _service.roll("test", _rng, 3)
	assert_eq(drops.size(), 3, "Should return exactly 3 drops")

func test_roll_single_returns_one() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	var drops: Array[Dictionary] = _service.roll("test", _rng, 1)
	assert_eq(drops.size(), 1, "Default single roll should return 1 drop")

func test_roll_returns_valid_item_ids() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	var valid_ids: Array[String] = ["sword", "shield", "potion"]
	var drops: Array[Dictionary] = _service.roll("test", _rng, 10)
	for drop in drops:
		assert_has(valid_ids, drop.item_id, "Drop item_id should be from the table")

func test_roll_quantity_within_range() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	for i in range(50):
		var drops: Array[Dictionary] = _service.roll("test", _rng, 1)
		var drop: Dictionary = drops[0]
		var entry: Dictionary = {}
		for e in SIMPLE_TABLE:
			if e.item_id == drop.item_id:
				entry = e
				break
		assert_true(drop.qty >= entry.min_qty, "Qty should be >= min_qty")
		assert_true(drop.qty <= entry.max_qty, "Qty should be <= max_qty")

func test_roll_single_entry_table_always_returns_that_item() -> void:
	_service.register_table("single", SINGLE_ENTRY_TABLE)
	for i in range(20):
		var drops: Array[Dictionary] = _service.roll("single", _rng, 1)
		assert_eq(drops[0].item_id, "only_item", "Single-entry table must always return that item")
		assert_eq(drops[0].qty, 3, "Fixed qty range (3-3) should always produce 3")

func test_roll_unknown_table_returns_empty() -> void:
	var drops: Array[Dictionary] = _service.roll("nonexistent", _rng, 1)
	assert_eq(drops.size(), 0, "Rolling unknown table should return empty array")

func test_roll_empty_table_returns_empty() -> void:
	_service.register_table("empty", [])
	var drops: Array[Dictionary] = _service.roll("empty", _rng, 1)
	assert_eq(drops.size(), 0, "Rolling empty table should return empty array")

func test_roll_zero_count_returns_empty() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	var drops: Array[Dictionary] = _service.roll("test", _rng, 0)
	assert_eq(drops.size(), 0, "Count of 0 should return empty array")

func test_roll_clamps_excessive_count() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	var drops: Array[Dictionary] = _service.roll("test", _rng, 999)
	assert_eq(drops.size(), LootService.MAX_ROLL_COUNT, "Should clamp to MAX_ROLL_COUNT")

func test_roll_does_not_modify_table() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	var before: Array[Dictionary] = _service.get_table("test")
	_service.roll("test", _rng, 10)
	var after: Array[Dictionary] = _service.get_table("test")
	assert_eq(before.size(), after.size(), "Table size should not change after rolling")
	for i in range(before.size()):
		assert_eq(before[i].weight, after[i].weight, "Weights should not change after rolling")

func test_roll_null_rng_returns_empty() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	var drops: Array[Dictionary] = _service.roll("test", null, 1)
	assert_eq(drops.size(), 0, "Null RNG should return empty array")

func test_roll_drop_has_required_keys() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	var drops: Array[Dictionary] = _service.roll("test", _rng, 1)
	assert_true(drops[0].has("item_id"), "Drop must have item_id key")
	assert_true(drops[0].has("qty"), "Drop must have qty key")

# ---------------------------------------------------------------------------
# Section C: Determinism
# ---------------------------------------------------------------------------

func test_roll_determinism_same_seed() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	var rng_a := _make_rng(12345)
	var rng_b := _make_rng(12345)
	var drops_a: Array[Dictionary] = _service.roll("test", rng_a, 5)
	var drops_b: Array[Dictionary] = _service.roll("test", rng_b, 5)
	assert_eq(drops_a.size(), drops_b.size(), "Both runs should produce same count")
	for i in range(drops_a.size()):
		assert_eq(drops_a[i].item_id, drops_b[i].item_id, "Item ID at index %d must match" % i)
		assert_eq(drops_a[i].qty, drops_b[i].qty, "Qty at index %d must match" % i)

func test_roll_determinism_100_iterations() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	var reference_rng := _make_rng(9999)
	var reference_drops: Array[Dictionary] = _service.roll("test", reference_rng, 3)
	for iteration in range(100):
		var test_rng := _make_rng(9999)
		var test_drops: Array[Dictionary] = _service.roll("test", test_rng, 3)
		for i in range(reference_drops.size()):
			assert_eq(test_drops[i].item_id, reference_drops[i].item_id,
				"Iteration %d index %d: item_id mismatch" % [iteration, i])
			assert_eq(test_drops[i].qty, reference_drops[i].qty,
				"Iteration %d index %d: qty mismatch" % [iteration, i])

func test_different_seeds_produce_different_results() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	var rng_a := _make_rng(111)
	var rng_b := _make_rng(222)
	var drops_a: Array[Dictionary] = _service.roll("test", rng_a, 10)
	var drops_b: Array[Dictionary] = _service.roll("test", rng_b, 10)
	var any_different: bool = false
	for i in range(drops_a.size()):
		if drops_a[i].item_id != drops_b[i].item_id or drops_a[i].qty != drops_b[i].qty:
			any_different = true
			break
	assert_true(any_different, "Different seeds should produce different results over 10 rolls")

# ---------------------------------------------------------------------------
# Section D: Rarity Filter
# ---------------------------------------------------------------------------

func test_rarity_filter_returns_qualifying_item() -> void:
	_service.register_table("rarity", RARITY_TEST_TABLE)
	var item_db := _make_item_db()
	var rng := _make_rng(42)
	var drops: Array[Dictionary] = _service.roll_with_rarity_filter(
		"rarity", rng, Enums.ItemRarity.RARE, item_db
	)
	assert_eq(drops.size(), 1, "Should return exactly 1 filtered drop")
	var item: ItemData = item_db.get_item(drops[0].item_id)
	assert_true(item.rarity >= Enums.ItemRarity.RARE,
		"Filtered item rarity (%d) should be >= RARE (%d)" % [item.rarity, Enums.ItemRarity.RARE])

func test_rarity_filter_common_returns_any() -> void:
	_service.register_table("rarity", RARITY_TEST_TABLE)
	var item_db := _make_item_db()
	var rng := _make_rng(42)
	var drops: Array[Dictionary] = _service.roll_with_rarity_filter(
		"rarity", rng, Enums.ItemRarity.COMMON, item_db
	)
	assert_eq(drops.size(), 1, "COMMON filter should always return a result")

func test_rarity_filter_determinism() -> void:
	_service.register_table("rarity", RARITY_TEST_TABLE)
	var item_db := _make_item_db()
	var rng_a := _make_rng(777)
	var rng_b := _make_rng(777)
	var drops_a: Array[Dictionary] = _service.roll_with_rarity_filter(
		"rarity", rng_a, Enums.ItemRarity.RARE, item_db
	)
	var drops_b: Array[Dictionary] = _service.roll_with_rarity_filter(
		"rarity", rng_b, Enums.ItemRarity.RARE, item_db
	)
	if drops_a.size() > 0 and drops_b.size() > 0:
		assert_eq(drops_a[0].item_id, drops_b[0].item_id, "Same seed should produce same filtered item")
		assert_eq(drops_a[0].qty, drops_b[0].qty, "Same seed should produce same filtered qty")

func test_rarity_filter_empty_on_impossible_rarity() -> void:
	var impossible_table: Array[Dictionary] = [
		{ "item_id": "common_gem", "weight": 1000, "min_qty": 1, "max_qty": 1 },
	]
	_service.register_table("all_common", impossible_table)
	var item_db := _make_item_db()
	var rng := _make_rng(42)
	var drops: Array[Dictionary] = _service.roll_with_rarity_filter(
		"all_common", rng, Enums.ItemRarity.LEGENDARY, item_db
	)
	assert_eq(drops.size(), 0, "Should return empty when no item meets LEGENDARY threshold after retries")

func test_rarity_filter_null_item_db_returns_empty() -> void:
	_service.register_table("rarity", RARITY_TEST_TABLE)
	var rng := _make_rng(42)
	var drops: Array[Dictionary] = _service.roll_with_rarity_filter(
		"rarity", rng, Enums.ItemRarity.RARE, null
	)
	assert_eq(drops.size(), 0, "Null ItemDatabase should return empty array")

# ---------------------------------------------------------------------------
# Section E: Currency
# ---------------------------------------------------------------------------

func test_currency_combat_returns_gold() -> void:
	var rng := _make_rng(42)
	var currency: Dictionary = _service.roll_currency(Enums.RoomType.COMBAT, 5, rng)
	assert_true(currency.has(Enums.Currency.GOLD), "COMBAT room should drop Gold")
	assert_true(currency[Enums.Currency.GOLD] > 0, "Gold amount should be positive")

func test_currency_rest_returns_empty() -> void:
	var rng := _make_rng(42)
	var currency: Dictionary = _service.roll_currency(Enums.RoomType.REST, 5, rng)
	assert_eq(currency.size(), 0, "REST room should return empty dictionary")

func test_currency_treasure_higher_than_combat() -> void:
	var total_treasure: int = 0
	var total_combat: int = 0
	for i in range(100):
		var rng_t := _make_rng(i)
		var rng_c := _make_rng(i + 10000)
		var treasure: Dictionary = _service.roll_currency(Enums.RoomType.TREASURE, 5, rng_t)
		var combat: Dictionary = _service.roll_currency(Enums.RoomType.COMBAT, 5, rng_c)
		total_treasure += treasure.get(Enums.Currency.GOLD, 0)
		total_combat += combat.get(Enums.Currency.GOLD, 0)
	assert_true(total_treasure > total_combat * 2,
		"Treasure gold (%d) should be >2x combat gold (%d)" % [total_treasure, total_combat])

func test_currency_boss_higher_than_treasure() -> void:
	var total_boss: int = 0
	var total_treasure: int = 0
	for i in range(100):
		var rng_b := _make_rng(i)
		var rng_t := _make_rng(i + 10000)
		var boss: Dictionary = _service.roll_currency(Enums.RoomType.BOSS, 5, rng_b)
		var treasure: Dictionary = _service.roll_currency(Enums.RoomType.TREASURE, 5, rng_t)
		total_boss += boss.get(Enums.Currency.GOLD, 0)
		total_treasure += treasure.get(Enums.Currency.GOLD, 0)
	assert_true(total_boss > total_treasure,
		"Boss gold (%d) should exceed treasure gold (%d)" % [total_boss, total_treasure])

func test_currency_scales_with_difficulty() -> void:
	var rng_low := _make_rng(42)
	var rng_high := _make_rng(42)
	var low_total: int = 0
	var high_total: int = 0
	for i in range(100):
		rng_low = _make_rng(i)
		rng_high = _make_rng(i + 50000)
		low_total += _service.roll_currency(Enums.RoomType.COMBAT, 1, rng_low).get(Enums.Currency.GOLD, 0)
		high_total += _service.roll_currency(Enums.RoomType.COMBAT, 10, rng_high).get(Enums.Currency.GOLD, 0)
	assert_true(high_total > low_total,
		"Difficulty 10 gold (%d) should exceed difficulty 1 gold (%d)" % [high_total, low_total])

func test_currency_determinism() -> void:
	var rng_a := _make_rng(555)
	var rng_b := _make_rng(555)
	var currency_a: Dictionary = _service.roll_currency(Enums.RoomType.COMBAT, 5, rng_a)
	var currency_b: Dictionary = _service.roll_currency(Enums.RoomType.COMBAT, 5, rng_b)
	assert_eq(currency_a, currency_b, "Same seed should produce same currency")

func test_currency_values_are_non_negative_integers() -> void:
	for room_type in [Enums.RoomType.COMBAT, Enums.RoomType.TREASURE, Enums.RoomType.TRAP,
			Enums.RoomType.PUZZLE, Enums.RoomType.BOSS]:
		var rng := _make_rng(42)
		var currency: Dictionary = _service.roll_currency(room_type, 5, rng)
		for key in currency:
			assert_true(currency[key] >= 0, "Currency value should be non-negative")
			assert_eq(currency[key], int(currency[key]), "Currency value should be integer")

func test_currency_boss_includes_essence() -> void:
	var rng := _make_rng(42)
	var currency: Dictionary = _service.roll_currency(Enums.RoomType.BOSS, 5, rng)
	assert_true(currency.has(Enums.Currency.ESSENCE),
		"Boss rooms should include Verdant Essence drops")
	assert_true(currency[Enums.Currency.ESSENCE] > 0,
		"Boss essence should be positive")

func test_currency_treasure_includes_essence() -> void:
	var rng := _make_rng(42)
	var currency: Dictionary = _service.roll_currency(Enums.RoomType.TREASURE, 5, rng)
	assert_true(currency.has(Enums.Currency.ESSENCE),
		"Treasure rooms should include Verdant Essence drops")

func test_currency_combat_no_essence() -> void:
	var rng := _make_rng(42)
	var currency: Dictionary = _service.roll_currency(Enums.RoomType.COMBAT, 5, rng)
	assert_false(currency.has(Enums.Currency.ESSENCE),
		"Combat rooms should NOT include Verdant Essence")

func test_currency_clamps_low_difficulty() -> void:
	var rng := _make_rng(42)
	var currency: Dictionary = _service.roll_currency(Enums.RoomType.COMBAT, -5, rng)
	assert_true(currency.get(Enums.Currency.GOLD, 0) > 0,
		"Clamped difficulty should still produce positive gold")

func test_currency_clamps_high_difficulty() -> void:
	var rng_normal := _make_rng(42)
	var rng_high := _make_rng(42)
	var normal: Dictionary = _service.roll_currency(Enums.RoomType.COMBAT, 10, rng_normal)
	var high: Dictionary = _service.roll_currency(Enums.RoomType.COMBAT, 99, rng_high)
	assert_eq(normal[Enums.Currency.GOLD], high[Enums.Currency.GOLD],
		"Difficulty 99 should clamp to 10 and match difficulty 10 result")

# ---------------------------------------------------------------------------
# Section F: Pre-Built Tables
# ---------------------------------------------------------------------------

func test_loot_tables_get_all_returns_seven() -> void:
	var all_tables: Dictionary = LootTables.get_all_tables()
	assert_eq(all_tables.size(), 7, "Should have exactly 7 pre-built tables")

func test_all_prebuilt_tables_have_valid_entries() -> void:
	var all_tables: Dictionary = LootTables.get_all_tables()
	for table_id in all_tables:
		var entries: Array = all_tables[table_id]
		assert_true(entries.size() > 0, "Table '%s' should have at least 1 entry" % table_id)
		for entry in entries:
			assert_true(entry.has("item_id"), "Entry in '%s' missing item_id" % table_id)
			assert_true(entry.has("weight"), "Entry in '%s' missing weight" % table_id)
			assert_true(entry.has("min_qty"), "Entry in '%s' missing min_qty" % table_id)
			assert_true(entry.has("max_qty"), "Entry in '%s' missing max_qty" % table_id)
			assert_true(entry.weight > 0, "Entry in '%s' has invalid weight" % table_id)
			assert_true(entry.min_qty >= 1, "Entry in '%s' has invalid min_qty" % table_id)
			assert_true(entry.max_qty >= entry.min_qty, "Entry in '%s' max_qty < min_qty" % table_id)

func test_all_prebuilt_tables_can_be_registered_and_rolled() -> void:
	var all_tables: Dictionary = LootTables.get_all_tables()
	for table_id in all_tables:
		_service.register_table(table_id, all_tables[table_id])
		assert_true(_service.has_table(table_id), "Table '%s' should be registered" % table_id)
		var rng := _make_rng(42)
		var drops: Array[Dictionary] = _service.roll(table_id, rng, 1)
		assert_eq(drops.size(), 1, "Rolling '%s' should return 1 drop" % table_id)
		assert_true(drops[0].has("item_id"), "Drop from '%s' should have item_id" % table_id)
		assert_true(drops[0].has("qty"), "Drop from '%s' should have qty" % table_id)

# ---------------------------------------------------------------------------
# Section G: Distribution & Integration
# ---------------------------------------------------------------------------

func test_weight_distribution_approximate() -> void:
	_service.register_table("test", SIMPLE_TABLE)
	var counts: Dictionary = { "sword": 0, "shield": 0, "potion": 0 }
	var total_rolls: int = 10000
	var rng := _make_rng(12345)
	for i in range(total_rolls):
		var drops: Array[Dictionary] = _service.roll("test", rng, 1)
		counts[drops[0].item_id] += 1
	var total_weight: float = 600.0
	var sword_expected: float = (100.0 / total_weight) * total_rolls
	var shield_expected: float = (200.0 / total_weight) * total_rolls
	var potion_expected: float = (300.0 / total_weight) * total_rolls
	var tolerance: float = total_rolls * 0.03
	assert_almost_eq(float(counts["sword"]), sword_expected, tolerance,
		"Sword distribution should be ~%.0f (got %d)" % [sword_expected, counts["sword"]])
	assert_almost_eq(float(counts["shield"]), shield_expected, tolerance,
		"Shield distribution should be ~%.0f (got %d)" % [shield_expected, counts["shield"]])
	assert_almost_eq(float(counts["potion"]), potion_expected, tolerance,
		"Potion distribution should be ~%.0f (got %d)" % [potion_expected, counts["potion"]])

func test_simulated_expedition_10_rooms() -> void:
	var all_tables: Dictionary = LootTables.get_all_tables()
	for table_id in all_tables:
		_service.register_table(table_id, all_tables[table_id])
	var room_types: Array = [
		Enums.RoomType.COMBAT, Enums.RoomType.COMBAT, Enums.RoomType.TREASURE,
		Enums.RoomType.TRAP, Enums.RoomType.COMBAT, Enums.RoomType.PUZZLE,
		Enums.RoomType.COMBAT, Enums.RoomType.REST, Enums.RoomType.COMBAT,
		Enums.RoomType.BOSS,
	]
	var table_map: Dictionary = {
		Enums.RoomType.COMBAT: "combat_common",
		Enums.RoomType.TREASURE: "treasure_common",
		Enums.RoomType.TRAP: "trap_consolation",
		Enums.RoomType.PUZZLE: "puzzle_reward",
		Enums.RoomType.BOSS: "boss_loot",
	}
	var total_gold: int = 0
	var total_items: int = 0
	for room_idx in range(room_types.size()):
		var room_type: Enums.RoomType = room_types[room_idx]
		var rng := DeterministicRNG.new()
		rng.seed_string("test_seed_room_%d" % room_idx)
		if table_map.has(room_type):
			var drops: Array[Dictionary] = _service.roll(table_map[room_type], rng, 1)
			total_items += drops.size()
		var currency: Dictionary = _service.roll_currency(room_type, 5, rng)
		total_gold += currency.get(Enums.Currency.GOLD, 0)
	assert_true(total_items >= 9, "Should get items from 9 non-REST rooms (got %d)" % total_items)
	assert_true(total_gold > 0, "Should accumulate some Gold across 10 rooms")
```

---

## 15. Playtesting Verification

### Scenario 1: Combat Room — Basic Gold Drop

| Field | Detail |
|---|---|
| **Setup** | Instantiate `LootService`, register all pre-built tables from `LootTables`. Create `DeterministicRNG` seeded with `42`. |
| **Actions** | Call `roll("combat_common", rng, 2)` and `roll_currency(COMBAT, 3, rng)`. |
| **Expected** | Two item drops with valid `item_id` and `qty` values. Currency dictionary with GOLD key, value between 7 and 15 (base 10 × diff_mult 1.3 × room_mult 1.0 ± 20%). |
| **Pass Criteria** | Items are from `combat_common` table entries. Gold is a positive integer. Results are deterministic on replay. |

### Scenario 2: Treasure Room — High-Value Chest

| Field | Detail |
|---|---|
| **Setup** | Same service. New RNG seeded with `100`. |
| **Actions** | Call `roll("treasure_common", rng, 3)` and `roll_currency(TREASURE, 5, rng)`. |
| **Expected** | Three item drops. Currency Gold significantly higher than combat at same difficulty (expected ~32–48 range). Essence also present. |
| **Pass Criteria** | Gold ≥ 25 (2.5× combat baseline at difficulty 5). Essence > 0. Items from `treasure_common`. |

### Scenario 3: Boss Room — Rare+ Guaranteed Drop

| Field | Detail |
|---|---|
| **Setup** | Same service with `ItemDatabase` populated. New RNG seeded with `777`. |
| **Actions** | Call `roll_with_rarity_filter("boss_loot", rng, RARE, item_db)` and `roll_currency(BOSS, 8, rng)`. |
| **Expected** | One drop with rarity ≥ RARE. Currency includes both GOLD (high amount) and ESSENCE. |
| **Pass Criteria** | Item rarity is RARE, EPIC, or LEGENDARY. Gold ≥ 40. Essence > 0. Deterministic on replay. |

### Scenario 4: Trap Room — Consolation Drops

| Field | Detail |
|---|---|
| **Setup** | Same service. New RNG seeded with `999`. |
| **Actions** | Call `roll("trap_consolation", rng, 1)` and `roll_currency(TRAP, 4, rng)`. |
| **Expected** | One low-value drop. Currency Gold is very small (trap mult 0.3). |
| **Pass Criteria** | Item is from `trap_consolation` table. Gold < 10 at difficulty 4. No Essence. |

### Scenario 5: Rest Room — No Drops

| Field | Detail |
|---|---|
| **Setup** | Same service. New RNG seeded with `55`. |
| **Actions** | Call `roll_currency(REST, 5, rng)`. |
| **Expected** | Empty dictionary — no currency from rest rooms. |
| **Pass Criteria** | Return value is `{}`. |

### Scenario 6: Puzzle Room — Utility Rewards

| Field | Detail |
|---|---|
| **Setup** | Same service. New RNG seeded with `333`. |
| **Actions** | Call `roll("puzzle_reward", rng, 2)` and `roll_currency(PUZZLE, 6, rng)`. |
| **Expected** | Two drops from puzzle_reward table. Currency Gold at 1.5× combat baseline. |
| **Pass Criteria** | Items from `puzzle_reward`. Gold between 15–25 at difficulty 6. Deterministic. |

### Scenario 7: Full Expedition Simulation (10 Rooms)

| Field | Detail |
|---|---|
| **Setup** | Service with all tables. RNG seeded per room: `seed_string("expedition_42_room_" + str(i))`. |
| **Actions** | Simulate 10-room expedition: 5 COMBAT, 2 TREASURE, 1 TRAP, 1 PUZZLE, 1 BOSS. Roll items and currency for each. |
| **Expected** | Total gold between 200–600 at difficulty 5. At least 10 item drops. Boss drop is rare+. |
| **Pass Criteria** | No errors. All drops valid. Currency sums reasonable. Fully deterministic across replays. |

### Scenario 8: Economy Validation — 1000 Expeditions

| Field | Detail |
|---|---|
| **Setup** | Service with all tables. Loop 1000 seeds (0–999). |
| **Actions** | For each seed, simulate a 10-room expedition and aggregate total Gold. Compute mean and standard deviation. |
| **Expected** | Mean Gold per expedition between 300–500 at difficulty 5. Standard deviation < 50% of mean. |
| **Pass Criteria** | Economy faucet is within GDD-specified bounds. No seeds produce 0 gold. No seeds produce >2000 gold. |

### Scenario 9: Determinism Verification — Replay Check

| Field | Detail |
|---|---|
| **Setup** | Service with all tables. Fixed seed `12345`. |
| **Actions** | Run full 10-room expedition twice with identical seeds. Compare all drops item-by-item and currency-by-currency. |
| **Expected** | Every drop and every currency amount is bit-identical between the two runs. |
| **Pass Criteria** | Zero differences in item_id, qty, or currency amounts across all 10 rooms. |

---

## 16. Implementation Prompt

### File 1: `src/resources/loot_tables.gd`

```gdscript
## src/resources/loot_tables.gd
## Static loot table definitions for all pre-built drop tables.
## Contains no logic — only const data arrays consumed by LootService.
## Each entry: { "item_id": String, "weight": int, "min_qty": int, "max_qty": int }
class_name LootTables
extends RefCounted


## Combat room drops — common tier. Weighted toward consumables and gold.
const COMBAT_COMMON: Array[Dictionary] = [
	{ "item_id": "iron_sword", "weight": 80, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "iron_shield", "weight": 60, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "health_potion", "weight": 200, "min_qty": 1, "max_qty": 3 },
	{ "item_id": "mana_potion", "weight": 150, "min_qty": 1, "max_qty": 2 },
	{ "item_id": "gold_coins", "weight": 250, "min_qty": 5, "max_qty": 25 },
	{ "item_id": "iron_ore", "weight": 100, "min_qty": 1, "max_qty": 3 },
	{ "item_id": "monster_hide", "weight": 100, "min_qty": 1, "max_qty": 2 },
	{ "item_id": "arcane_dust", "weight": 60, "min_qty": 1, "max_qty": 2 },
]


## Combat room drops — rare tier. Shifted toward uncommon+ equipment.
const COMBAT_RARE: Array[Dictionary] = [
	{ "item_id": "steel_sword", "weight": 150, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "steel_armor", "weight": 120, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "enchanted_ring", "weight": 80, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "greater_health_potion", "weight": 100, "min_qty": 1, "max_qty": 2 },
	{ "item_id": "gold_coins", "weight": 100, "min_qty": 15, "max_qty": 50 },
	{ "item_id": "elemental_essence", "weight": 50, "min_qty": 1, "max_qty": 2 },
]


## Treasure room drops — common tier. Higher gold and gem weights.
const TREASURE_COMMON: Array[Dictionary] = [
	{ "item_id": "gold_coins", "weight": 300, "min_qty": 20, "max_qty": 80 },
	{ "item_id": "ruby_gem", "weight": 120, "min_qty": 1, "max_qty": 3 },
	{ "item_id": "sapphire_gem", "weight": 120, "min_qty": 1, "max_qty": 3 },
	{ "item_id": "health_potion", "weight": 150, "min_qty": 2, "max_qty": 5 },
	{ "item_id": "iron_ore", "weight": 100, "min_qty": 3, "max_qty": 8 },
	{ "item_id": "monster_hide", "weight": 80, "min_qty": 2, "max_qty": 5 },
	{ "item_id": "enchanted_ring", "weight": 60, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "arcane_dust", "weight": 70, "min_qty": 2, "max_qty": 5 },
]


## Treasure room drops — rare tier. Spanning rare through legendary.
const TREASURE_RARE: Array[Dictionary] = [
	{ "item_id": "enchanted_blade", "weight": 150, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "mithril_armor", "weight": 100, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "ancient_amulet", "weight": 80, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "diamond_gem", "weight": 60, "min_qty": 1, "max_qty": 2 },
	{ "item_id": "gold_coins", "weight": 80, "min_qty": 50, "max_qty": 200 },
	{ "item_id": "elemental_essence", "weight": 30, "min_qty": 2, "max_qty": 5 },
]


## Boss room drops — biased toward rare+ items and unique drops.
const BOSS_LOOT: Array[Dictionary] = [
	{ "item_id": "enchanted_blade", "weight": 100, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "mithril_armor", "weight": 80, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "ancient_amulet", "weight": 70, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "dragon_scale", "weight": 50, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "legendary_crown", "weight": 15, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "elemental_essence", "weight": 60, "min_qty": 2, "max_qty": 5 },
	{ "item_id": "gold_coins", "weight": 25, "min_qty": 100, "max_qty": 500 },
]


## Trap room consolation drops — low-value items for surviving a trap.
const TRAP_CONSOLATION: Array[Dictionary] = [
	{ "item_id": "health_potion", "weight": 300, "min_qty": 1, "max_qty": 2 },
	{ "item_id": "gold_coins", "weight": 250, "min_qty": 1, "max_qty": 10 },
	{ "item_id": "arcane_dust", "weight": 100, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "iron_ore", "weight": 80, "min_qty": 1, "max_qty": 2 },
	{ "item_id": "bandage", "weight": 70, "min_qty": 1, "max_qty": 3 },
]


## Puzzle room rewards — utility items and essences for solving puzzles.
const PUZZLE_REWARD: Array[Dictionary] = [
	{ "item_id": "mana_potion", "weight": 150, "min_qty": 1, "max_qty": 3 },
	{ "item_id": "arcane_dust", "weight": 120, "min_qty": 2, "max_qty": 5 },
	{ "item_id": "elemental_essence", "weight": 100, "min_qty": 1, "max_qty": 3 },
	{ "item_id": "enchanted_ring", "weight": 80, "min_qty": 1, "max_qty": 1 },
	{ "item_id": "gold_coins", "weight": 150, "min_qty": 10, "max_qty": 40 },
	{ "item_id": "scroll_of_insight", "weight": 100, "min_qty": 1, "max_qty": 2 },
]


## Returns all pre-built tables as a dictionary keyed by table_id.
## Used by LootService to batch-register all tables at initialization.
static func get_all_tables() -> Dictionary:
	return {
		"combat_common": COMBAT_COMMON,
		"combat_rare": COMBAT_RARE,
		"treasure_common": TREASURE_COMMON,
		"treasure_rare": TREASURE_RARE,
		"boss_loot": BOSS_LOOT,
		"trap_consolation": TRAP_CONSOLATION,
		"puzzle_reward": PUZZLE_REWARD,
	}
```

### File 2: `src/services/loot_service.gd`

```gdscript
## src/services/loot_service.gd
## Deterministic, weighted loot table engine for resolving item drops and currency rewards.
## Pure computational service — no scene tree dependency, no signals, no side effects.
## All randomness flows through DeterministicRNG for full reproducibility.
class_name LootService
extends RefCounted


# ---------------------------------------------------------------------------
# Constants — all tunable values are named, never magic numbers
# ---------------------------------------------------------------------------

## Base gold amount before multipliers are applied.
const BASE_GOLD: int = 10

## Per-difficulty scaling factor. Formula: 1.0 + (difficulty - 1) * DIFFICULTY_SCALE
const DIFFICULTY_SCALE: float = 0.15

## Maximum ± variance applied to currency drops (0.2 = ±20%).
const VARIANCE_RANGE: float = 0.2

## Maximum retry attempts for rarity-filtered rolls before giving up.
const MAX_RARITY_RETRIES: int = 100

## Maximum number of drops per single roll() call.
const MAX_ROLL_COUNT: int = 100

## Base multiplier for Verdant Essence drops.
const ESSENCE_BASE_MULT: float = 0.5

## Essence multiplier for BOSS rooms.
const BOSS_ESSENCE_MULT: float = 2.0

## Essence multiplier for TREASURE rooms.
const TREASURE_ESSENCE_MULT: float = 1.0

## Minimum valid difficulty value.
const MIN_DIFFICULTY: int = 1

## Maximum valid difficulty value.
const MAX_DIFFICULTY: int = 10

## Room-type currency multipliers. REST = 0.0 means no currency.
const ROOM_CURRENCY_MULT: Dictionary = {
	Enums.RoomType.COMBAT: 1.0,
	Enums.RoomType.TREASURE: 2.5,
	Enums.RoomType.TRAP: 0.3,
	Enums.RoomType.PUZZLE: 1.5,
	Enums.RoomType.REST: 0.0,
	Enums.RoomType.BOSS: 3.0,
}


# ---------------------------------------------------------------------------
# Internal state
# ---------------------------------------------------------------------------

## Registered loot tables: { table_id: Array[Dictionary] }
var _tables: Dictionary = {}

## Cached total weights per table for O(1) roll setup: { table_id: int }
var _total_weights: Dictionary = {}


# ---------------------------------------------------------------------------
# Table Registration & Retrieval
# ---------------------------------------------------------------------------

## Registers a loot table with the given ID and entries.
## Each entry must be a Dictionary with keys: item_id (String), weight (int > 0),
## min_qty (int >= 1), max_qty (int >= min_qty).
## Invalid entries are skipped with a warning. Re-registering overwrites the previous table.
func register_table(table_id: String, entries: Array[Dictionary]) -> void:
	var valid_entries: Array[Dictionary] = []
	var total_weight: int = 0
	for entry in entries:
		if not _validate_entry(entry, table_id):
			continue
		valid_entries.append(entry.duplicate())
		total_weight += entry.weight
	_tables[table_id] = valid_entries
	_total_weights[table_id] = total_weight


## Returns true if a table with the given ID is registered.
func has_table(table_id: String) -> bool:
	return _tables.has(table_id)


## Returns a copy of the entries for the given table, or an empty array if not found.
func get_table(table_id: String) -> Array[Dictionary]:
	if not _tables.has(table_id):
		return []
	var result: Array[Dictionary] = []
	for entry in _tables[table_id]:
		result.append(entry.duplicate())
	return result


# ---------------------------------------------------------------------------
# Rolling
# ---------------------------------------------------------------------------

## Rolls the specified loot table [count] times using the provided RNG.
## Returns an array of { "item_id": String, "qty": int } dictionaries.
## Returns an empty array if the table is unknown, empty, or RNG is null.
func roll(table_id: String, rng: DeterministicRNG, count: int = 1) -> Array[Dictionary]:
	if rng == null:
		push_error("LootService.roll(): RNG is null")
		return []
	if not _tables.has(table_id):
		push_warning("LootService.roll(): Unknown table '%s'" % table_id)
		return []
	var entries: Array[Dictionary] = _tables[table_id]
	if entries.is_empty():
		return []
	var clamped_count: int = clampi(count, 0, MAX_ROLL_COUNT)
	if clamped_count <= 0:
		return []
	var total_weight: int = _total_weights[table_id]
	var results: Array[Dictionary] = []
	for i in range(clamped_count):
		var selected: Dictionary = _weighted_select(entries, total_weight, rng)
		var qty: int = rng.randi_range(selected.min_qty, selected.max_qty)
		results.append({ "item_id": selected.item_id, "qty": qty })
	return results


## Rolls the specified table and filters results by minimum rarity.
## Uses item_db to look up the rarity of each rolled item.
## Retries up to MAX_RARITY_RETRIES times. Returns [{ "item_id", "qty" }] or empty.
func roll_with_rarity_filter(
	table_id: String,
	rng: DeterministicRNG,
	min_rarity: Enums.ItemRarity,
	item_db: ItemDatabase
) -> Array[Dictionary]:
	if rng == null:
		push_error("LootService.roll_with_rarity_filter(): RNG is null")
		return []
	if item_db == null:
		push_error("LootService.roll_with_rarity_filter(): ItemDatabase is null")
		return []
	if not _tables.has(table_id):
		push_warning("LootService.roll_with_rarity_filter(): Unknown table '%s'" % table_id)
		return []
	var entries: Array[Dictionary] = _tables[table_id]
	if entries.is_empty():
		return []
	var total_weight: int = _total_weights[table_id]
	for attempt in range(MAX_RARITY_RETRIES):
		var selected: Dictionary = _weighted_select(entries, total_weight, rng)
		var qty: int = rng.randi_range(selected.min_qty, selected.max_qty)
		var item: ItemData = item_db.get_item(selected.item_id)
		if item == null:
			continue
		if item.rarity >= min_rarity:
			return [{ "item_id": selected.item_id, "qty": qty }]
	return []


# ---------------------------------------------------------------------------
# Currency Drops
# ---------------------------------------------------------------------------

## Computes currency drops for a given room type and difficulty.
## Returns a Dictionary mapping Enums.Currency -> int.
## REST rooms return an empty dictionary. All values are non-negative integers.
func roll_currency(
	room_type: Enums.RoomType,
	difficulty: int,
	rng: DeterministicRNG
) -> Dictionary:
	if rng == null:
		push_error("LootService.roll_currency(): RNG is null")
		return {}
	var room_mult: float = ROOM_CURRENCY_MULT.get(room_type, 0.0)
	if room_mult <= 0.0:
		return {}
	var clamped_diff: int = clampi(difficulty, MIN_DIFFICULTY, MAX_DIFFICULTY)
	var diff_mult: float = 1.0 + (clamped_diff - 1) * DIFFICULTY_SCALE
	var variance: float = rng.randf() * (VARIANCE_RANGE * 2.0) - VARIANCE_RANGE
	var gold_raw: float = BASE_GOLD * diff_mult * room_mult * (1.0 + variance)
	var gold: int = maxi(0, roundi(gold_raw))
	var result: Dictionary = {}
	if gold > 0:
		result[Enums.Currency.GOLD] = gold
	if room_type == Enums.RoomType.BOSS or room_type == Enums.RoomType.TREASURE:
		var essence_mult: float = BOSS_ESSENCE_MULT if room_type == Enums.RoomType.BOSS else TREASURE_ESSENCE_MULT
		var essence_raw: float = clamped_diff * ESSENCE_BASE_MULT * essence_mult
		var essence: int = maxi(1, roundi(essence_raw))
		result[Enums.Currency.ESSENCE] = essence
	return result


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

## Validates a single loot table entry dictionary.
## Returns true if the entry has all required keys with valid values.
func _validate_entry(entry: Dictionary, table_id: String) -> bool:
	var required_keys: Array[String] = ["item_id", "weight", "min_qty", "max_qty"]
	for key in required_keys:
		if not entry.has(key):
			push_warning("LootService: Entry in table '%s' missing key '%s' — skipping" % [table_id, key])
			return false
	if entry.weight <= 0:
		push_warning("LootService: Entry '%s' in table '%s' has weight <= 0 — skipping" % [entry.item_id, table_id])
		return false
	if entry.min_qty < 1:
		push_warning("LootService: Entry '%s' in table '%s' has min_qty < 1 — skipping" % [entry.item_id, table_id])
		return false
	if entry.max_qty < entry.min_qty:
		push_warning("LootService: Entry '%s' in table '%s' has max_qty < min_qty — skipping" % [entry.item_id, table_id])
		return false
	return true


## Selects a single entry from the table using cumulative weight selection.
## Consumes one RNG call. Deterministic for the same RNG state and table.
func _weighted_select(
	entries: Array[Dictionary],
	total_weight: int,
	rng: DeterministicRNG
) -> Dictionary:
	var roll_value: int = rng.randi(total_weight)
	var cumulative: int = 0
	for entry in entries:
		cumulative += entry.weight
		if roll_value < cumulative:
			return entry
	return entries[entries.size() - 1]
```

### File 3: `tests/test_loot_service.gd`

The complete test file is provided in Section 14 above. Copy it directly to `tests/test_loot_service.gd`.

### Implementation Checklist

1. **Create `src/resources/loot_tables.gd`** — Copy File 1 above verbatim. Verify all 7 const tables are defined and `get_all_tables()` returns all 7.
2. **Create `src/services/loot_service.gd`** — Copy File 2 above verbatim. Verify `class_name LootService` and `extends RefCounted`.
3. **Create `tests/test_loot_service.gd`** — Copy the test file from Section 14 above. Verify it extends `GutTest` and has 40+ test methods.
4. **Run tests** — Execute `gut -gtest=tests/test_loot_service.gd` and verify all tests pass.
5. **Verify determinism** — Run the determinism tests 10 times in a row. All must produce identical results.
6. **Verify no scene tree dependency** — Confirm `LootService.new()` works in a headless GUT runner without errors.
7. **Verify static analysis** — Run Godot editor static analysis on all three files. Zero errors, zero warnings.
8. **Integration smoke test** — Register all pre-built tables, simulate a 10-room expedition, verify reasonable drop quantities and currency totals.

### Architecture Notes for Implementer

- **Do NOT add signals to LootService.** It is intentionally a pure function service. Event-driven patterns belong in the expedition resolver (TASK-015).
- **Do NOT use `@onready`, `_ready()`, or any Node lifecycle methods.** The class extends `RefCounted`.
- **Do NOT use global state or singletons.** All dependencies (RNG, ItemDB) are passed as method parameters.
- **Do NOT hardcode item IDs in `loot_service.gd`.** All item references live in `loot_tables.gd`. The service is table-agnostic.
- **DO use `push_warning()` for recoverable issues** (unknown table, invalid entry) and `push_error()` for programming errors (null RNG).
- **DO cache `total_weight` per table** on registration to avoid recomputing during every `roll()` call.
- **DO use `entry.duplicate()`** when storing entries to prevent external mutation of internal state.
