# TASK-003: Enums, Constants & Data Dictionary

---

## Section 1 — Header

| Field              | Value                                                                                    |
| ------------------ | ---------------------------------------------------------------------------------------- |
| **Task ID**        | TASK-003                                                                                 |
| **Title**          | Enums, Constants & Data Dictionary                                                       |
| **Priority**       | 🔴 P0 — Critical Path                                                                   |
| **Tier**           | Tier 1 — Foundation                                                                      |
| **Complexity**     | 3 points (Trivial)                                                                       |
| **Phase**          | Wave 1 — Data Foundation                                                                 |
| **Stream**         | 🔴 MCH (Mechanics) — Primary                                                            |
| **Cross-Stream**   | ⚪ TCH (data foundation), 🔵 VIS (rarity colors for UI), 🟣 NAR (element/class names)   |
| **GDD Reference**  | GDD-v2.md §4.1 (Seeds), §4.2 (Dungeons), §4.3 (Adventurers), §4.4 (Loot & Economy)     |
| **Milestone**      | M1 — Core Data Models                                                                    |
| **Dependencies**   | None — this task has zero upstream dependencies                                          |
| **Dependents**     | TASK-004, TASK-005, TASK-006, TASK-007, TASK-008 (all Wave 2)                            |
| **Critical Path**  | ✅ YES — 5 Wave 2 tasks are blocked until TASK-003 merges                                |
| **Estimated Hours**| 2–4 hours                                                                                |
| **Assignee**       | TBD                                                                                      |
| **Engine**         | Godot 4.5 — GDScript                                                                     |
| **Output Files**   | `src/models/enums.gd`, `src/models/game_config.gd`                                       |

---

## Section 2 — Description

### 2.1 — What This Task Produces

This task creates two foundational GDScript autoload-ready files that every other system in Dungeon Seed references:

1. **`src/models/enums.gd`** (`class_name Enums`) — A single file containing every game-wide enumeration drawn directly from the GDD. Ten enums covering seed rarity, elemental affinity, seed growth phases, dungeon room types, adventurer classes, level tiers, item rarity, equipment slots, currency types, and expedition statuses.

2. **`src/models/game_config.gd`** (`class_name GameConfig`) — A single file containing every balance-tuning constant expressed as `const` dictionaries. Growth timers, XP thresholds, base stats per adventurer class, mutation slot counts, currency earn rates, room difficulty scaling, phase growth multipliers, element display names, and rarity UI colors.

Both files are pure data — zero runtime state, zero allocations beyond initial parse, zero side effects. They exist so that every downstream system can import a single symbol (`Enums.SeedRarity.COMMON` or `GameConfig.BASE_GROWTH_SECONDS`) instead of scattering magic strings and magic numbers across the codebase.

### 2.2 — Why Centralized Enums Matter

Without a single source of truth for enumerations, the following failure modes emerge in any project of this scale:

- **Magic string rot**: One file checks `rarity == "common"`, another checks `rarity == "Common"`, a third checks `rarity == 0`. No compile-time protection catches the mismatch.
- **Balance drift**: Growth timers are hardcoded in three different scripts. A designer changes one and misses the others. The game ships with inconsistent balance.
- **Refactor fragility**: Renaming a room type requires a codebase-wide find-and-replace with no compiler assistance. Missed occurrences become silent runtime bugs.
- **Type safety erosion**: GDScript's static typing is only useful when enum types are declared. `var rarity: Enums.SeedRarity` gives the editor autocomplete, the linter type checking, and the developer confidence.

By consolidating all enums into `enums.gd` and all balance constants into `game_config.gd`, we gain:

- **Compile-time type safety** via GDScript's enum type system
- **Single-point balance tuning** — change a number in one place, entire game adjusts
- **IDE autocomplete** for every enum value in every file
- **Grep-friendly naming** — searching for `Enums.SeedRarity` finds every usage instantly
- **No runtime cost** — `const` values are inlined by the GDScript compiler

### 2.3 — Player Experience Impact

Players never see enums directly, but every system they interact with is governed by them:

- **Seed growth speed** flows from `GameConfig.BASE_GROWTH_SECONDS[rarity]` through the growth timer in TASK-004. A player planting a Common seed waits 60 seconds; a Legendary seed requires 1200 seconds (20 minutes). These numbers define the core idle loop pacing.
- **Adventurer strength** flows from `GameConfig.BASE_STATS[class]` through combat resolution in TASK-006. A Warrior with 120 HP and 18 ATK feels tanky; a Mage with 70 HP and 12 ATK but 20 utility feels like a glass cannon. These numbers define the class identity.
- **Loot rarity colors** flow from `GameConfig.RARITY_COLORS[rarity]` through the UI in TASK-007. When a Legendary item drops, the gold glow comes from this dictionary.
- **Economy earn rates** flow from `GameConfig.CURRENCY_EARN_RATES[currency]` through the wallet in TASK-008. If gold earns at 10 per room and Essence at 2 per room, the entire faucet/sink balance of the game is set here.

### 2.4 — Economy Impact

`GameConfig.CURRENCY_EARN_RATES` is the most consequential dictionary in the entire game. It defines the base faucet rate for every currency type:

| Currency   | Base Rate (per room clear) | Role in Economy                          |
| ---------- | -------------------------- | ---------------------------------------- |
| Gold       | 10                         | Primary soft currency — shop purchases   |
| Essence    | 2                          | Seed growth acceleration, mutations      |
| Fragments  | 1                          | Crafting material — equipment upgrades   |
| Artifacts  | 0                          | Premium rare drops — boss-only or events |

These base rates are multiplied by room difficulty, seed rarity bonuses, and adventurer utility stats in downstream systems. But the base values here set the floor.

### 2.5 — Technical Architecture: Downstream Dependency Map

```
TASK-003 (enums.gd + game_config.gd)
├── TASK-004 (Seed Data Model)
│   └── uses: SeedRarity, Element, SeedPhase, BASE_GROWTH_SECONDS, MUTATION_SLOTS, PHASE_GROWTH_MULTIPLIERS
├── TASK-005 (Dungeon Room Graph)
│   └── uses: RoomType, ROOM_DIFFICULTY_SCALE
├── TASK-006 (Adventurer Data Model)
│   └── uses: AdventurerClass, LevelTier, BASE_STATS, XP_PER_TIER
├── TASK-007 (Item & Equipment Models)
│   └── uses: ItemRarity, EquipSlot, RARITY_COLORS
└── TASK-008 (Economy Wallet)
    └── uses: Currency, CURRENCY_EARN_RATES
```

Every arrow above is a hard compile-time dependency. If `enums.gd` does not declare `SeedRarity`, TASK-004 cannot define `var rarity: Enums.SeedRarity`. This is why TASK-003 is on the critical path.

### 2.6 — System Interaction Map

```
┌─────────────────────────────────────────────────┐
│                   enums.gd                      │
│  SeedRarity · Element · SeedPhase · RoomType    │
│  AdventurerClass · LevelTier · ItemRarity       │
│  EquipSlot · Currency · ExpeditionStatus        │
└────────────────────┬────────────────────────────┘
                     │ type references
┌────────────────────▼────────────────────────────┐
│                game_config.gd                   │
│  BASE_GROWTH_SECONDS · XP_PER_TIER · BASE_STATS│
│  MUTATION_SLOTS · CURRENCY_EARN_RATES           │
│  ROOM_DIFFICULTY_SCALE · PHASE_GROWTH_MULT      │
│  ELEMENT_NAMES · RARITY_COLORS                  │
└────────────────────┬────────────────────────────┘
                     │ consumed by
     ┌───────┬───────┼───────┬───────┐
     ▼       ▼       ▼       ▼       ▼
  TASK-004 TASK-005 TASK-006 TASK-007 TASK-008
   Seed     Dungeon  Adv.    Item    Economy
   Model    Graph    Model   Model   Wallet
```

### 2.7 — Development Cost

| Activity                         | Estimated Time |
| -------------------------------- | -------------- |
| Write enums.gd (10 enums)        | 30 min         |
| Write game_config.gd (9 dicts)   | 60 min         |
| Write helper methods             | 30 min         |
| Write GUT test suite             | 45 min         |
| Code review & iteration          | 15 min         |
| **Total**                        | **~3 hours**   |

### 2.8 — Constraints and Design Decisions

1. **`const` only, no `var`**: Every value in `game_config.gd` must be declared `const`. This prevents any runtime mutation and guarantees deterministic behavior across save/load cycles.
2. **Dictionary keys are enum values**: `BASE_GROWTH_SECONDS` is keyed by `Enums.SeedRarity` integer values, not strings. This provides type safety and avoids string comparison overhead.
3. **No inheritance**: Both files extend `RefCounted` implicitly (default). No `extends Node` — these are not autoloads that need the scene tree. They are accessed via `class_name` static references.
4. **GDD is canonical**: If this ticket's example values conflict with GDD-v2.md, the GDD wins. The values listed here are drawn from the GDD and must match exactly.
5. **Color format**: All colors use Godot's `Color()` constructor with standard named colors or hex values for consistency with the UI style guide.

---

## Section 3 — Use Cases

### UC-001: Game Designer Adjusts Balance Values

**Actor:** Game Designer (or developer wearing designer hat)
**Trigger:** Playtest reveals Common seeds grow too fast — players have nothing to wait for.
**Flow:**
1. Designer opens `src/models/game_config.gd`.
2. Locates `BASE_GROWTH_SECONDS` dictionary.
3. Changes `Enums.SeedRarity.COMMON: 60` to `Enums.SeedRarity.COMMON: 90`.
4. Saves the file. No other file needs editing.
5. Runs the game. Every Common seed now takes 90 seconds to grow.
6. The Seed growth system (TASK-004), the UI growth timer (future), and any tooltip showing growth time all reflect the change automatically because they all read from the same `GameConfig.BASE_GROWTH_SECONDS` constant.

**Postcondition:** Single line change propagates to every system that consumes growth time data.

### UC-002: Developer References Enums in Downstream Code

**Actor:** Developer implementing TASK-004 (Seed Data Model)
**Trigger:** Developer needs to declare a seed's rarity as a typed field.
**Flow:**
1. Developer types `var rarity: Enums.SeedRarity` in their seed resource script.
2. The Godot editor provides autocomplete for `Enums.SeedRarity.COMMON`, `.UNCOMMON`, `.RARE`, `.EPIC`, `.LEGENDARY`.
3. Developer writes a match statement:
   ```gdscript
   match rarity:
       Enums.SeedRarity.COMMON:
           growth_time = GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.COMMON]
       Enums.SeedRarity.UNCOMMON:
           growth_time = GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.UNCOMMON]
       # ... etc
   ```
4. If the developer misspells `Enums.SeedRarity.COMON`, the GDScript parser immediately flags an error — no silent runtime failure.

**Postcondition:** Type-safe enum usage with IDE support and compile-time error detection.

### UC-003: Downstream TASK-006 Reads Adventurer Base Stats

**Actor:** Developer implementing TASK-006 (Adventurer Data Model)
**Trigger:** Developer needs to initialize a new Warrior adventurer with correct starting stats.
**Flow:**
1. Developer calls `GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)`.
2. Receives a dictionary: `{ "health": 120, "attack": 18, "defense": 15, "speed": 8, "utility": 5 }`.
3. Uses these values to populate the adventurer's stat block.
4. If the designer later buffs Warrior defense from 15 to 18, only `game_config.gd` changes — TASK-006 code remains untouched.

**Postcondition:** Adventurer creation code is decoupled from balance values.

### UC-004: UI System Reads Rarity Colors

**Actor:** Developer implementing item tooltip UI (downstream of TASK-007)
**Trigger:** An Epic item drops and the UI needs to display it with the correct rarity color.
**Flow:**
1. UI code retrieves `GameConfig.RARITY_COLORS[Enums.ItemRarity.EPIC]`.
2. Receives `Color(0.64, 0.21, 0.93)` (purple).
3. Applies this color to the item name label, border glow, and particle effect.
4. Every item tooltip, inventory slot, and loot popup uses the same color source — visual consistency is guaranteed.

**Postcondition:** Rarity color palette is defined once and consumed everywhere.

### UC-005: Economy System Reads Currency Earn Rates

**Actor:** Developer implementing TASK-008 (Economy Wallet)
**Trigger:** Player clears a dungeon room and the system must calculate currency rewards.
**Flow:**
1. Room clear handler reads `GameConfig.CURRENCY_EARN_RATES[Enums.Currency.GOLD]` → 10.
2. Multiplies by room difficulty scale from `GameConfig.ROOM_DIFFICULTY_SCALE[room_type]`.
3. Awards the calculated gold to the player's wallet.
4. If the designer wants to double gold income globally, they change one number in `game_config.gd`.

**Postcondition:** Economy faucet rates are centrally controlled and consistently applied.

---

## Section 4 — Glossary

| Term                    | Definition                                                                                                                                                                     |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **enum**                | GDScript enumeration — a named set of integer constants. `enum Foo { A, B, C }` assigns A=0, B=1, C=2. Provides type safety and IDE autocomplete.                             |
| **const**               | GDScript compile-time constant. Declared with `const NAME = value`. Cannot be reassigned at runtime. Dictionaries declared `const` have immutable structure.                   |
| **class_name**          | GDScript directive that registers a script as a globally accessible type. `class_name Enums` allows any script to reference `Enums.SeedRarity` without `preload()`.           |
| **Dictionary**          | GDScript's hash-map type. Used here for lookup tables keyed by enum values. `const FOO: Dictionary = { Enums.Bar.A: 10, Enums.Bar.B: 20 }`.                                  |
| **Color**               | Godot's built-in color type. Constructed via `Color(r, g, b)` with floats 0.0–1.0, or `Color.hex(0xRRGGBB)`, or named constants like `Color.WHITE`.                          |
| **RefCounted**          | Godot's default base class for scripts without `extends`. Reference-counted, garbage-collected. Both `enums.gd` and `game_config.gd` implicitly extend this.                  |
| **static typing**       | GDScript feature where variables declare their type: `var x: int = 5`. Enum types participate: `var r: Enums.SeedRarity = Enums.SeedRarity.COMMON`.                          |
| **balance tuning**      | The process of adjusting numerical game values (damage, growth time, costs) to create a fair and engaging player experience. GameConfig centralizes all tuning knobs.          |
| **faucet/sink**         | Game economy model. Faucets generate currency (room clears, rewards). Sinks consume it (shop purchases, upgrades). `CURRENCY_EARN_RATES` defines the primary faucet flow.     |
| **XP curve**            | The relationship between experience points earned and level progression. `XP_PER_TIER` defines the thresholds where adventurers advance from Novice→Skilled→Veteran→Elite.    |
| **magic number**        | A hardcoded numeric literal in source code with no explanation. `if health > 120` is a magic number. `if health > GameConfig.BASE_STATS[cls]["health"]` is self-documenting.  |
| **magic string**        | A hardcoded string literal used for comparison. `if rarity == "rare"` is fragile. `if rarity == Enums.SeedRarity.RARE` is type-safe.                                         |
| **critical path**       | The longest chain of dependent tasks that determines minimum project duration. TASK-003 is on it because 5 Wave 2 tasks cannot start without it.                              |
| **GUT**                 | Godot Unit Testing framework. GDScript test runner used for all automated tests in Dungeon Seed. Test files extend `GutTest`.                                                 |
| **autoload**            | Godot singleton pattern — a script/scene added to Project Settings → AutoLoad. Not used for enums/config (they use `class_name` static access instead).                       |
| **mutation slot**       | A slot on a seed where a random mutation can be applied during growth. Higher rarity seeds have more slots, allowing more powerful trait combinations.                         |
| **seed phase**          | The four growth stages a seed passes through: Spore → Sprout → Bud → Bloom. Each phase unlocks new capabilities and visual changes.                                          |
| **level tier**          | Adventurer progression bracket. Novice (0 XP), Skilled (100 XP), Veteran (350 XP), Elite (750 XP). Each tier unlocks new abilities and stat scaling.                         |

---

## Section 5 — Out of Scope

The following items are explicitly **NOT** part of TASK-003. They may be addressed in future tasks or are intentionally excluded from the game's architecture.

| #   | Excluded Item                                        | Reason                                                                                      |
| --- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| 1   | Runtime config modification                          | All values are `const`. Live-tuning belongs to a future debug/cheat console (if ever).      |
| 2   | Save/load of config values                           | Constants are baked into the build. Persistence is for player state, not game rules.         |
| 3   | UI for balance tuning (editor plugin)                | Useful but not MVP. Designers edit `game_config.gd` directly for now.                       |
| 4   | Localization of enum display names                   | `ELEMENT_NAMES` provides English strings only. i18n is a future cross-cutting concern.      |
| 5   | Derived/computed constants                           | Values like "DPS per class" that could be computed from BASE_STATS are not pre-calculated.  |
| 6   | Enum serialization/deserialization helpers            | Converting enums to/from strings for save files belongs to TASK-009 (Serialization).        |
| 7   | Animated rarity color effects (glow, pulse)          | `RARITY_COLORS` provides static colors only. Shader effects belong to VIS stream.           |
| 8   | Difficulty scaling formulas                           | `ROOM_DIFFICULTY_SCALE` provides per-room-type multipliers, not full scaling algorithms.    |
| 9   | Config validation at editor time                     | A custom Godot plugin that validates config integrity is out of scope for this task.         |
| 10  | Enum bitflags / bitmask combinations                 | No enum is used as a bitfield. Multi-element seeds (if added) would need a different design. |
| 11  | Remote config / feature flags                        | No server-side config. This is a single-player offline game.                                |
| 12  | Platform-specific config overrides                   | No per-platform (mobile vs desktop) balance differences in MVP.                             |
| 13  | Audio or visual asset references in config           | GameConfig stores numbers and colors only. Asset paths belong to resource files.            |
| 14  | Procedural generation parameters                     | Dungeon generation algorithms and their tuning constants belong to TASK-005.                |

---

## Section 6 — Functional Requirements

### enums.gd Requirements

| ID     | Requirement                                                                                                                    | GDD Ref | Testable |
| ------ | ------------------------------------------------------------------------------------------------------------------------------ | ------- | -------- |
| FR-001 | `enums.gd` declares `class_name Enums` at the top of the file.                                                                | —       | ✅       |
| FR-002 | `enum SeedRarity` contains exactly: `COMMON, UNCOMMON, RARE, EPIC, LEGENDARY` (in that order, values 0–4).                    | §4.1    | ✅       |
| FR-003 | `enum Element` contains exactly: `TERRA, FLAME, FROST, ARCANE, SHADOW` (in that order, values 0–4).                           | §4.1    | ✅       |
| FR-004 | `enum SeedPhase` contains exactly: `SPORE, SPROUT, BUD, BLOOM` (in that order, values 0–3).                                   | §4.1    | ✅       |
| FR-005 | `enum RoomType` contains exactly: `COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS` (in that order, values 0–5).                   | §4.2    | ✅       |
| FR-006 | `enum AdventurerClass` contains exactly: `WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL` (in that order, values 0–5).     | §4.3    | ✅       |
| FR-007 | `enum LevelTier` contains exactly: `NOVICE, SKILLED, VETERAN, ELITE` (in that order, values 0–3).                             | §4.3    | ✅       |
| FR-008 | `enum ItemRarity` contains exactly: `COMMON, UNCOMMON, RARE, EPIC, LEGENDARY` (in that order, values 0–4).                    | §4.4    | ✅       |
| FR-009 | `enum EquipSlot` contains exactly: `WEAPON, ARMOR, ACCESSORY` (in that order, values 0–2).                                    | §4.3    | ✅       |
| FR-010 | `enum Currency` contains exactly: `GOLD, ESSENCE, FRAGMENTS, ARTIFACTS` (in that order, values 0–3).                          | §4.4    | ✅       |
| FR-011 | `enum ExpeditionStatus` contains exactly: `PREPARING, IN_PROGRESS, COMPLETED, FAILED` (in that order, values 0–3).            | §4.2    | ✅       |
| FR-012 | No two enums share the same name within the `Enums` class (no compilation ambiguity).                                          | —       | ✅       |

### game_config.gd Requirements

| ID     | Requirement                                                                                                                    | GDD Ref | Testable |
| ------ | ------------------------------------------------------------------------------------------------------------------------------ | ------- | -------- |
| FR-013 | `game_config.gd` declares `class_name GameConfig` at the top of the file.                                                     | —       | ✅       |
| FR-014 | `const BASE_GROWTH_SECONDS: Dictionary` maps every `SeedRarity` value to a positive integer (COMMON=60, UNCOMMON=120, RARE=300, EPIC=600, LEGENDARY=1200). | §4.1    | ✅       |
| FR-015 | `const XP_PER_TIER: Dictionary` maps every `LevelTier` value to a non-negative integer (NOVICE=0, SKILLED=100, VETERAN=350, ELITE=750). Values are monotonically increasing. | §4.3    | ✅       |
| FR-016 | `const BASE_STATS: Dictionary` maps every `AdventurerClass` to a Dictionary with exactly five keys: `"health"`, `"attack"`, `"defense"`, `"speed"`, `"utility"`. All values are positive integers. | §4.3    | ✅       |
| FR-017 | `const MUTATION_SLOTS: Dictionary` maps every `SeedRarity` to a positive integer (COMMON=1, UNCOMMON=2, RARE=3, EPIC=4, LEGENDARY=5). | §4.1    | ✅       |
| FR-018 | `const CURRENCY_EARN_RATES: Dictionary` maps every `Currency` to a non-negative numeric value (GOLD=10, ESSENCE=2, FRAGMENTS=1, ARTIFACTS=0). | §4.4    | ✅       |
| FR-019 | `const ROOM_DIFFICULTY_SCALE: Dictionary` maps every `RoomType` to a positive float scaling factor.                            | §4.2    | ✅       |
| FR-020 | `const PHASE_GROWTH_MULTIPLIERS: Dictionary` maps every `SeedPhase` to a positive float multiplier.                            | §4.1    | ✅       |
| FR-021 | `const ELEMENT_NAMES: Dictionary` maps every `Element` to a non-empty `String` display name.                                   | §4.1    | ✅       |
| FR-022 | `const RARITY_COLORS: Dictionary` maps every `SeedRarity` to a `Color` value. Dictionary has exactly 5 entries matching the 5 rarity tiers. | §4.4    | ✅       |
| FR-023 | A static helper `Enums.seed_rarity_name(rarity: SeedRarity) -> String` returns the human-readable rarity name.                 | —       | ✅       |
| FR-024 | A static helper `GameConfig.get_base_stats(cls: Enums.AdventurerClass) -> Dictionary` returns the stat dictionary for a class.  | —       | ✅       |
| FR-025 | All `const` dictionaries in `game_config.gd` have entries for every value of their corresponding enum — no missing keys.        | —       | ✅       |

---

## Section 7 — Non-Functional Requirements

| ID      | Category       | Requirement                                                                                                                          |
| ------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| NFR-001 | Performance    | Zero runtime heap allocations from enums.gd or game_config.gd after initial script parse. All data is `const` and interned.          |
| NFR-002 | Performance    | Total memory footprint of both files combined shall not exceed 8 KB of static data.                                                  |
| NFR-003 | Performance    | Script parse/load time for both files combined shall be under 1 ms on a mid-range desktop CPU.                                       |
| NFR-004 | Performance    | Dictionary lookups on `const` dictionaries shall be O(1) hash-map access — no linear scans.                                         |
| NFR-005 | Maintainability| Every enum and const dictionary has a `##` doc comment explaining its purpose and GDD reference.                                     |
| NFR-006 | Maintainability| Adding a new enum value requires editing exactly 1 file (enums.gd) plus updating corresponding GameConfig dictionaries.              |
| NFR-007 | Maintainability| Adding a new GameConfig dictionary requires editing exactly 1 file (game_config.gd).                                                 |
| NFR-008 | Maintainability| Both files are under 200 lines each, with clear section separators between logical groups.                                            |
| NFR-009 | Type Safety    | Every variable, parameter, and return type in both files uses explicit GDScript type hints (`: int`, `: String`, `: Dictionary`).     |
| NFR-010 | Type Safety    | No implicit type coercion — enum values are always accessed via their qualified name (`Enums.SeedRarity.COMMON`), never as raw ints.  |
| NFR-011 | Compatibility  | Both files compile without warnings in Godot 4.5 with GDScript strict mode enabled.                                                  |
| NFR-012 | Compatibility  | Both files are usable via `class_name` without requiring autoload registration in project settings.                                   |
| NFR-013 | Testing        | GUT test suite achieves 100% coverage of all enum values and all GameConfig dictionary entries.                                        |
| NFR-014 | Testing        | GUT test suite runs in under 500 ms total.                                                                                            |
| NFR-015 | Code Quality   | Both files pass GDScript linter (`gdtoolkit`) with zero warnings using the project's `.gdlintrc` configuration.                       |
| NFR-016 | Code Quality   | No circular dependencies — enums.gd depends on nothing; game_config.gd depends only on enums.gd.                                     |
| NFR-017 | Determinism    | All values are deterministic across runs. No `randf()`, no `Time.get_ticks_msec()`, no external data sources.                         |
| NFR-018 | Portability    | Color values use Godot's cross-platform `Color()` constructor — no platform-specific color representations.                           |

---

## Section 8 — Designer's Manual

### 8.1 — How to Add a New Enum Value

**Example: Adding a new Element called `VOID`**

1. Open `src/models/enums.gd`.
2. Find the `Element` enum declaration:
   ```gdscript
   enum Element { TERRA, FLAME, FROST, ARCANE, SHADOW }
   ```
3. Append the new value at the end (do NOT insert in the middle — this would shift integer values and break serialized data):
   ```gdscript
   enum Element { TERRA, FLAME, FROST, ARCANE, SHADOW, VOID }
   ```
4. Open `src/models/game_config.gd`.
5. Add the new element to every dictionary that is keyed by `Element`:
   - `ELEMENT_NAMES`: Add `Enums.Element.VOID: "Void"`
6. Run the GUT test suite. It will fail on any dictionary that is missing the new key, telling you exactly what to update.
7. Search the codebase for `match` statements on `Element` — each must gain a `VOID` branch or a `_` wildcard.

**Rules:**
- Always append new enum values at the end. Never reorder existing values.
- Every enum value added to `enums.gd` must have corresponding entries added to every `GameConfig` dictionary keyed by that enum.
- Run tests after every change.

### 8.2 — How to Add a New GameConfig Constant

**Example: Adding `SEED_SELL_PRICES` (gold value per seed rarity)**

1. Open `src/models/game_config.gd`.
2. Add the new constant in the appropriate section (seed-related constants group):
   ```gdscript
   ## Gold value when selling a seed, keyed by SeedRarity.
   ## GDD Reference: §4.4 (Economy — Seed Selling)
   const SEED_SELL_PRICES: Dictionary = {
       Enums.SeedRarity.COMMON: 5,
       Enums.SeedRarity.UNCOMMON: 15,
       Enums.SeedRarity.RARE: 50,
       Enums.SeedRarity.EPIC: 150,
       Enums.SeedRarity.LEGENDARY: 500,
   }
   ```
3. Ensure the dictionary has an entry for every value of the keying enum.
4. Add a GUT test in the test file to verify completeness and value ranges.
5. Update this ticket's dependency map if downstream tasks will consume the new constant.

### 8.3 — How to Adjust Balance Values

**Example: Making Legendary seeds grow faster (1200s → 900s)**

1. Open `src/models/game_config.gd`.
2. Find `BASE_GROWTH_SECONDS`.
3. Change:
   ```gdscript
   Enums.SeedRarity.LEGENDARY: 1200,
   ```
   to:
   ```gdscript
   Enums.SeedRarity.LEGENDARY: 900,
   ```
4. Save. Done. Every system that reads `GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.LEGENDARY]` now uses 900.
5. No other files need editing. No downstream code changes required.

### 8.4 — Naming Conventions

| Entity           | Convention         | Example                                |
| ---------------- | ------------------ | -------------------------------------- |
| Enum type name   | PascalCase         | `SeedRarity`, `AdventurerClass`        |
| Enum value       | UPPER_SNAKE_CASE   | `COMMON`, `IN_PROGRESS`                |
| Const name       | UPPER_SNAKE_CASE   | `BASE_GROWTH_SECONDS`, `XP_PER_TIER`  |
| Dict string key  | lower_snake_case   | `"health"`, `"attack"`, `"defense"`    |
| Helper method    | snake_case         | `seed_rarity_name()`, `get_base_stats()`|
| Doc comment      | `##` prefix        | `## Growth time in seconds per rarity` |

### 8.5 — Where Downstream Code Picks Up Changes

Downstream tasks access enums and config via static class references:

```gdscript
# In TASK-004 (Seed Data Model):
var rarity: Enums.SeedRarity = Enums.SeedRarity.COMMON
var growth_time: int = GameConfig.BASE_GROWTH_SECONDS[rarity]

# In TASK-006 (Adventurer Data Model):
var cls: Enums.AdventurerClass = Enums.AdventurerClass.WARRIOR
var stats: Dictionary = GameConfig.get_base_stats(cls)

# In TASK-008 (Economy Wallet):
var gold_rate: int = GameConfig.CURRENCY_EARN_RATES[Enums.Currency.GOLD]
```

No `preload()`, no autoload reference, no singleton — just `ClassName.CONSTANT`. This works because `class_name` registers the type globally in Godot 4.5.

---

## Section 9 — Assumptions

| #  | Assumption                                                                                                                              | Risk if Wrong                                                          |
| -- | --------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| 1  | Godot 4.5 supports `class_name` for static-only scripts (no `extends Node` required).                                                  | Would need to register as autoload instead. Low risk — works in 4.x.   |
| 2  | GDScript `const Dictionary` is truly immutable at runtime (no `.erase()`, `.merge()` on const ref).                                     | If mutable, a runtime guard or freeze wrapper would be needed.          |
| 3  | Enum integer values auto-increment from 0 when not explicitly assigned.                                                                 | If Godot changes this default, explicit values would need assignment.   |
| 4  | The GDD values listed in this ticket are final and approved for MVP.                                                                     | If GDD changes, `game_config.gd` values must be updated to match.      |
| 5  | Five rarity tiers (Common through Legendary) are sufficient for MVP launch.                                                              | Adding a 6th tier (Mythic) is an append-only enum change — low risk.   |
| 6  | Five elements (Terra through Shadow) are sufficient for MVP launch.                                                                      | Adding a 6th element follows the same append pattern as rarity.         |
| 7  | Six adventurer classes are sufficient for MVP launch.                                                                                     | New classes can be appended to the enum without breaking existing data. |
| 8  | Four currency types cover all MVP economy needs.                                                                                          | A 5th currency (e.g., "Tickets") can be appended if needed.            |
| 9  | `Color()` constructor accepts RGB float values (0.0–1.0) consistently across all platforms.                                              | Godot guarantees this — no platform risk.                               |
| 10 | Base stat values (health 70–120, attack 8–18, etc.) produce a balanced combat experience.                                                | Balance Auditor or playtest may require adjustments — that is expected. |
| 11 | Growth seconds (60–1200) feel appropriate for an idle game with active play sessions of 15–30 minutes.                                   | Playtesting may reveal that 1200s (20 min) for Legendary is too long.  |
| 12 | XP thresholds (0, 100, 350, 750) create a satisfying progression curve with diminishing returns.                                         | Curve may feel grindy at Veteran tier — adjustable via single edit.     |
| 13 | Currency earn rates (Gold=10, Essence=2, etc.) create healthy faucet flow relative to planned sink costs.                                 | Economy simulation in TASK-008 may require rebalancing.                 |
| 14 | No enum will exceed 20 values in the foreseeable future (Godot has no hard limit, but readability suffers).                               | If an enum grows past 20, consider splitting into sub-enums.            |
| 15 | GUT (Godot Unit Testing) framework is available and configured in the project before this task begins.                                    | If not, TASK-001 or TASK-002 must set up GUT first.                     |
| 16 | Downstream tasks (TASK-004 through TASK-008) will not begin implementation until TASK-003 is merged to the development branch.            | Starting early risks merge conflicts on enum definitions.               |
| 17 | The project directory structure `src/models/` exists or will be created as part of this task.                                              | If it does not exist, `mkdir -p` equivalent in the file system.         |

---

## Section 10 — Security & Anti-Cheat Considerations

### Threat Model

Since Dungeon Seed is a single-player offline game, the primary threats are memory editing and save file tampering — not network-based exploits. However, enum and config integrity still matters for game experience quality.

### THREAT-001: Memory Editing of Enum Values

**Attack Vector:** A player uses Cheat Engine or similar memory editor to change an enum value in RAM (e.g., changing a `SeedRarity.COMMON` seed to `SeedRarity.LEGENDARY` by overwriting the integer from 0 to 4).

**Impact:** Player obtains Legendary-tier growth times, mutation slots, and rewards from a Common seed.

**Mitigation (Current Scope):**
- `const` declarations make the config values themselves read-only in the GDScript VM.
- Enum values stored on game objects (seeds, adventurers) are mutable by design — protection belongs to the save/load system (TASK-009), not the enum definition.
- **Scope for TASK-003:** Document that enum values are NOT tamper-proof at runtime. Downstream tasks must validate enum ranges on load.

### THREAT-002: Config File Tampering (Exported Build)

**Attack Vector:** A player modifies the exported `.pck` file to change `game_config.gd` constants (e.g., setting `BASE_GROWTH_SECONDS[LEGENDARY]` to 1 second).

**Impact:** Trivializes game progression entirely.

**Mitigation (Current Scope):**
- Godot's `.pck` export provides basic obfuscation but not encryption.
- **Scope for TASK-003:** None. File integrity checking (CRC/hash validation) is out of scope for a Tier 1 data-definition task.
- **Recommendation for future task:** If anti-cheat becomes a priority, implement a config hash check at startup that compares `game_config.gd` values against a baked-in expected hash.

### THREAT-003: Modding Balance Values (Intentional)

**Attack Vector:** A player intentionally mods `game_config.gd` to customize their experience (e.g., faster growth, more gold).

**Impact:** Player has fun on their own terms. No competitive integrity concern (single-player).

**Mitigation (Current Scope):**
- **No mitigation needed.** Single-player modding is a feature, not a threat.
- **Design consideration:** The clean separation of all balance values into `game_config.gd` makes the game inherently mod-friendly. This is a positive side effect of good architecture.
- **Future consideration:** If achievements or leaderboards are added, a "modded save" flag should be set when config values differ from defaults.

### THREAT-004: Enum Value Injection via Deserialization

**Attack Vector:** A tampered save file contains an enum integer value outside the valid range (e.g., `SeedRarity = 99`).

**Impact:** Match statements without a wildcard `_` branch could produce undefined behavior. Dictionary lookups with an invalid key would return `null`.

**Mitigation (Current Scope):**
- **Scope for TASK-003:** Provide helper methods that validate enum ranges. `Enums.is_valid_seed_rarity(value: int) -> bool` patterns should be considered.
- **Primary mitigation belongs to TASK-009 (Serialization):** All deserialized enum values must be range-checked before use.

---

## Section 11 — Best Practices

| #  | Practice                                                                                                                                   |
| -- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| 1  | **Always use qualified enum names**: Write `Enums.SeedRarity.COMMON`, never `0` or `SeedRarity.COMMON` without the class prefix.           |
| 2  | **Append-only enum evolution**: New values go at the end. Never insert in the middle — this shifts integer values and breaks saved data.    |
| 3  | **One enum per concept**: `SeedRarity` and `ItemRarity` are separate enums even though they share the same values. This prevents coupling.  |
| 4  | **Const immutability is your friend**: Declare all GameConfig values as `const`. If you feel the need for `var`, stop and reconsider.       |
| 5  | **Type-hint everything**: `const BASE_GROWTH_SECONDS: Dictionary = { ... }`. The `: Dictionary` is mandatory even though GDScript can infer.|
| 6  | **Doc comment every constant**: Use `##` (double-hash) for documentation comments. Single `#` is for implementation notes.                 |
| 7  | **Keep dictionaries complete**: Every `const` dictionary keyed by an enum must have an entry for every enum value. No exceptions.           |
| 8  | **Color consistency**: Use the same color values for the same rarity tier across `RARITY_COLORS` and any future color dictionaries.         |
| 9  | **Avoid magic numbers in downstream code**: If you're writing `60` in a growth calculation, you should be writing `GameConfig.BASE_GROWTH_SECONDS[rarity]` instead. |
| 10 | **Match exhaustiveness**: Every `match` statement on an enum should either cover all values explicitly or include a `_` wildcard with an error/warning. |
| 11 | **Group related constants**: In `game_config.gd`, keep seed-related constants together, adventurer-related together, economy-related together. Use section comment banners. |
| 12 | **Test every value**: The GUT test suite must explicitly assert every enum value and every dictionary entry. Untested values are undocumented assumptions. |
| 13 | **Trailing commas**: Always use trailing commas in dictionary literals for cleaner git diffs when adding entries.                           |
| 14 | **No logic in data files**: `enums.gd` and `game_config.gd` contain data definitions and trivial helper lookups only. No algorithms, no state. |
| 15 | **Enum-keyed, not string-keyed**: Use `Enums.Element.TERRA` as a dictionary key, not the string `"TERRA"`. This provides compile-time safety. |

---

## Section 12 — Troubleshooting

### Issue 1: "Identifier not found" Error When Referencing Enums

**Symptom:** Another script writes `Enums.SeedRarity.COMMON` and gets a parser error: `Identifier "Enums" not declared in the current scope.`

**Cause:** The `class_name Enums` directive is missing or misspelled in `enums.gd`, or the file has a parse error preventing it from loading.

**Fix:**
1. Verify `enums.gd` starts with `class_name Enums` (capital E, no typo).
2. Verify `enums.gd` has no syntax errors — open it in the Godot editor and check for red error indicators.
3. Try restarting the Godot editor — `class_name` registration sometimes requires a restart after file creation.

### Issue 2: Enum Name Collision Between Enums

**Symptom:** GDScript error about duplicate names, or unexpected enum value resolution.

**Cause:** Two enums within the same class have overlapping value names (e.g., `SeedRarity.COMMON` and `ItemRarity.COMMON` both exist in `Enums`).

**Fix:** This is actually fine in GDScript — enum values are namespaced under their enum type. `Enums.SeedRarity.COMMON` (value 0) and `Enums.ItemRarity.COMMON` (value 0) are distinct identifiers. No collision occurs. If confusion arises in code, always use the fully qualified path.

### Issue 3: Missing Enum Value in Match Statement

**Symptom:** A match statement on `Enums.RoomType` handles 5 of 6 room types. The unhandled type silently does nothing.

**Cause:** GDScript does not enforce exhaustive match statements. A missing branch is not a compile error.

**Fix:**
1. Always include a `_` wildcard branch that pushes a warning: `push_warning("Unhandled RoomType: %s" % room_type)`.
2. In tests, iterate over all enum values and verify each is handled.

### Issue 4: GameConfig Dictionary Key Typo

**Symptom:** `GameConfig.BASE_STATS[Enums.AdventurerClass.WARRIOR]["helth"]` returns `null` instead of a health value.

**Cause:** String key `"helth"` is misspelled. Dictionary access with a missing key returns `null` in GDScript (no error by default).

**Fix:**
1. Always use the exact keys: `"health"`, `"attack"`, `"defense"`, `"speed"`, `"utility"`.
2. In downstream code, consider using `dict.get("health", 0)` with a default value to catch typos gracefully.
3. The GUT test suite verifies all expected keys exist in every BASE_STATS entry.

### Issue 5: Color Format Errors

**Symptom:** A rarity color displays as black or white unexpectedly.

**Cause:** `Color()` was constructed with integer values (0–255) instead of float values (0.0–1.0), or arguments were in the wrong order.

**Fix:**
1. Verify all `Color()` calls use float values: `Color(0.64, 0.21, 0.93)`, not `Color(163, 53, 238)`.
2. Godot `Color()` takes (R, G, B) or (R, G, B, A) as floats 0.0–1.0.
3. Alternatively, use hex notation: `Color("a335ee")` for purple.

### Issue 6: Adding a New Enum Value Breaks Downstream Tests

**Symptom:** After adding `Element.VOID`, GUT tests in TASK-004 fail because a dictionary lookup returns `null`.

**Cause:** The new enum value was added to `enums.gd` but not to all `GameConfig` dictionaries keyed by `Element`.

**Fix:**
1. After adding any enum value, run the TASK-003 test suite first — it checks dictionary completeness.
2. Then update every `GameConfig` dictionary that uses the modified enum as a key.
3. Then run downstream test suites.

### Issue 7: Enum Integer Value Assumptions in Save Data

**Symptom:** After inserting a new enum value in the middle of an enum, old save files load with wrong values.

**Cause:** Enum values are stored as integers. Inserting `VOID` between `ARCANE` and `SHADOW` shifts `SHADOW` from 4 to 5. Old saves with `4` now map to `VOID` instead of `SHADOW`.

**Fix:**
1. **Never insert enum values in the middle.** Always append at the end.
2. If you must reorder, implement a save migration in TASK-009 that remaps old integer values to new ones.
3. The test suite validates that enum values match expected integer assignments.

---

## Section 13 — Acceptance Criteria

### enums.gd Acceptance Criteria

| ID     | Criterion                                                                                                                      | Verification    |
| ------ | ------------------------------------------------------------------------------------------------------------------------------ | --------------- |
| AC-001 | File `src/models/enums.gd` exists and begins with `class_name Enums`.                                                         | Code review     |
| AC-002 | `Enums.SeedRarity` has exactly 5 values: COMMON=0, UNCOMMON=1, RARE=2, EPIC=3, LEGENDARY=4.                                   | GUT test        |
| AC-003 | `Enums.Element` has exactly 5 values: TERRA=0, FLAME=1, FROST=2, ARCANE=3, SHADOW=4.                                          | GUT test        |
| AC-004 | `Enums.SeedPhase` has exactly 4 values: SPORE=0, SPROUT=1, BUD=2, BLOOM=3.                                                    | GUT test        |
| AC-005 | `Enums.RoomType` has exactly 6 values: COMBAT=0, TREASURE=1, TRAP=2, PUZZLE=3, REST=4, BOSS=5.                                | GUT test        |
| AC-006 | `Enums.AdventurerClass` has exactly 6 values: WARRIOR=0, RANGER=1, MAGE=2, ROGUE=3, ALCHEMIST=4, SENTINEL=5.                  | GUT test        |
| AC-007 | `Enums.LevelTier` has exactly 4 values: NOVICE=0, SKILLED=1, VETERAN=2, ELITE=3.                                              | GUT test        |
| AC-008 | `Enums.ItemRarity` has exactly 5 values: COMMON=0, UNCOMMON=1, RARE=2, EPIC=3, LEGENDARY=4.                                   | GUT test        |
| AC-009 | `Enums.EquipSlot` has exactly 3 values: WEAPON=0, ARMOR=1, ACCESSORY=2.                                                       | GUT test        |
| AC-010 | `Enums.Currency` has exactly 4 values: GOLD=0, ESSENCE=1, FRAGMENTS=2, ARTIFACTS=3.                                           | GUT test        |
| AC-011 | `Enums.ExpeditionStatus` has exactly 4 values: PREPARING=0, IN_PROGRESS=1, COMPLETED=2, FAILED=3.                             | GUT test        |

### game_config.gd Acceptance Criteria

| ID     | Criterion                                                                                                                      | Verification    |
| ------ | ------------------------------------------------------------------------------------------------------------------------------ | --------------- |
| AC-012 | File `src/models/game_config.gd` exists and begins with `class_name GameConfig`.                                               | Code review     |
| AC-013 | `GameConfig.BASE_GROWTH_SECONDS` has 5 entries (one per `SeedRarity`), all positive integers, values match GDD (60/120/300/600/1200). | GUT test        |
| AC-014 | `GameConfig.XP_PER_TIER` has 4 entries (one per `LevelTier`), values are monotonically increasing (0 < 100 < 350 < 750).       | GUT test        |
| AC-015 | `GameConfig.BASE_STATS` has 6 entries (one per `AdventurerClass`), each containing exactly 5 keys: health, attack, defense, speed, utility. All values are positive integers. | GUT test        |
| AC-016 | `GameConfig.MUTATION_SLOTS` has 5 entries (one per `SeedRarity`), all positive integers, values are monotonically increasing (1/2/3/4/5). | GUT test        |
| AC-017 | `GameConfig.CURRENCY_EARN_RATES` has 4 entries (one per `Currency`), all non-negative integers.                                 | GUT test        |
| AC-018 | `GameConfig.ROOM_DIFFICULTY_SCALE` has 6 entries (one per `RoomType`), all positive floats.                                     | GUT test        |
| AC-019 | `GameConfig.PHASE_GROWTH_MULTIPLIERS` has 4 entries (one per `SeedPhase`), all positive floats.                                 | GUT test        |
| AC-020 | `GameConfig.ELEMENT_NAMES` has 5 entries (one per `Element`), all non-empty Strings.                                            | GUT test        |
| AC-021 | `GameConfig.RARITY_COLORS` has 5 entries (one per `SeedRarity`), all valid `Color` objects.                                     | GUT test        |

### Helper Method Acceptance Criteria

| ID     | Criterion                                                                                                                      | Verification    |
| ------ | ------------------------------------------------------------------------------------------------------------------------------ | --------------- |
| AC-022 | `Enums.seed_rarity_name(Enums.SeedRarity.COMMON)` returns `"Common"`.                                                         | GUT test        |
| AC-023 | `Enums.seed_rarity_name()` returns correct names for all 5 rarity values.                                                      | GUT test        |
| AC-024 | `GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)` returns a Dictionary with keys health, attack, defense, speed, utility. | GUT test        |
| AC-025 | Both files compile without errors or warnings in Godot 4.5 strict mode.                                                        | Editor check    |

---

## Section 14 — Testing Requirements

All tests use the GUT (Godot Unit Testing) framework. Test file location: `tests/models/test_enums_and_config.gd`.

```gdscript
## tests/models/test_enums_and_config.gd
## GUT test suite for TASK-003: Enums, Constants & Data Dictionary
## Covers: enums.gd (all 10 enums) and game_config.gd (all 9 const dictionaries + helpers)
extends GutTest


# ---------------------------------------------------------------------------
# Section A: Enum Existence and Value Tests
# ---------------------------------------------------------------------------

func test_seed_rarity_values() -> void:
	assert_eq(Enums.SeedRarity.COMMON, 0, "SeedRarity.COMMON should be 0")
	assert_eq(Enums.SeedRarity.UNCOMMON, 1, "SeedRarity.UNCOMMON should be 1")
	assert_eq(Enums.SeedRarity.RARE, 2, "SeedRarity.RARE should be 2")
	assert_eq(Enums.SeedRarity.EPIC, 3, "SeedRarity.EPIC should be 3")
	assert_eq(Enums.SeedRarity.LEGENDARY, 4, "SeedRarity.LEGENDARY should be 4")


func test_seed_rarity_count() -> void:
	assert_eq(Enums.SeedRarity.size(), 5, "SeedRarity should have exactly 5 values")


func test_element_values() -> void:
	assert_eq(Enums.Element.TERRA, 0, "Element.TERRA should be 0")
	assert_eq(Enums.Element.FLAME, 1, "Element.FLAME should be 1")
	assert_eq(Enums.Element.FROST, 2, "Element.FROST should be 2")
	assert_eq(Enums.Element.ARCANE, 3, "Element.ARCANE should be 3")
	assert_eq(Enums.Element.SHADOW, 4, "Element.SHADOW should be 4")


func test_element_count() -> void:
	assert_eq(Enums.Element.size(), 5, "Element should have exactly 5 values")


func test_seed_phase_values() -> void:
	assert_eq(Enums.SeedPhase.SPORE, 0, "SeedPhase.SPORE should be 0")
	assert_eq(Enums.SeedPhase.SPROUT, 1, "SeedPhase.SPROUT should be 1")
	assert_eq(Enums.SeedPhase.BUD, 2, "SeedPhase.BUD should be 2")
	assert_eq(Enums.SeedPhase.BLOOM, 3, "SeedPhase.BLOOM should be 3")


func test_seed_phase_count() -> void:
	assert_eq(Enums.SeedPhase.size(), 4, "SeedPhase should have exactly 4 values")


func test_room_type_values() -> void:
	assert_eq(Enums.RoomType.COMBAT, 0, "RoomType.COMBAT should be 0")
	assert_eq(Enums.RoomType.TREASURE, 1, "RoomType.TREASURE should be 1")
	assert_eq(Enums.RoomType.TRAP, 2, "RoomType.TRAP should be 2")
	assert_eq(Enums.RoomType.PUZZLE, 3, "RoomType.PUZZLE should be 3")
	assert_eq(Enums.RoomType.REST, 4, "RoomType.REST should be 4")
	assert_eq(Enums.RoomType.BOSS, 5, "RoomType.BOSS should be 5")


func test_room_type_count() -> void:
	assert_eq(Enums.RoomType.size(), 6, "RoomType should have exactly 6 values")


func test_adventurer_class_values() -> void:
	assert_eq(Enums.AdventurerClass.WARRIOR, 0, "AdventurerClass.WARRIOR should be 0")
	assert_eq(Enums.AdventurerClass.RANGER, 1, "AdventurerClass.RANGER should be 1")
	assert_eq(Enums.AdventurerClass.MAGE, 2, "AdventurerClass.MAGE should be 2")
	assert_eq(Enums.AdventurerClass.ROGUE, 3, "AdventurerClass.ROGUE should be 3")
	assert_eq(Enums.AdventurerClass.ALCHEMIST, 4, "AdventurerClass.ALCHEMIST should be 4")
	assert_eq(Enums.AdventurerClass.SENTINEL, 5, "AdventurerClass.SENTINEL should be 5")


func test_adventurer_class_count() -> void:
	assert_eq(Enums.AdventurerClass.size(), 6, "AdventurerClass should have exactly 6 values")


func test_level_tier_values() -> void:
	assert_eq(Enums.LevelTier.NOVICE, 0, "LevelTier.NOVICE should be 0")
	assert_eq(Enums.LevelTier.SKILLED, 1, "LevelTier.SKILLED should be 1")
	assert_eq(Enums.LevelTier.VETERAN, 2, "LevelTier.VETERAN should be 2")
	assert_eq(Enums.LevelTier.ELITE, 3, "LevelTier.ELITE should be 3")


func test_level_tier_count() -> void:
	assert_eq(Enums.LevelTier.size(), 4, "LevelTier should have exactly 4 values")


func test_item_rarity_values() -> void:
	assert_eq(Enums.ItemRarity.COMMON, 0, "ItemRarity.COMMON should be 0")
	assert_eq(Enums.ItemRarity.UNCOMMON, 1, "ItemRarity.UNCOMMON should be 1")
	assert_eq(Enums.ItemRarity.RARE, 2, "ItemRarity.RARE should be 2")
	assert_eq(Enums.ItemRarity.EPIC, 3, "ItemRarity.EPIC should be 3")
	assert_eq(Enums.ItemRarity.LEGENDARY, 4, "ItemRarity.LEGENDARY should be 4")


func test_item_rarity_count() -> void:
	assert_eq(Enums.ItemRarity.size(), 5, "ItemRarity should have exactly 5 values")


func test_equip_slot_values() -> void:
	assert_eq(Enums.EquipSlot.WEAPON, 0, "EquipSlot.WEAPON should be 0")
	assert_eq(Enums.EquipSlot.ARMOR, 1, "EquipSlot.ARMOR should be 1")
	assert_eq(Enums.EquipSlot.ACCESSORY, 2, "EquipSlot.ACCESSORY should be 2")


func test_equip_slot_count() -> void:
	assert_eq(Enums.EquipSlot.size(), 3, "EquipSlot should have exactly 3 values")


func test_currency_values() -> void:
	assert_eq(Enums.Currency.GOLD, 0, "Currency.GOLD should be 0")
	assert_eq(Enums.Currency.ESSENCE, 1, "Currency.ESSENCE should be 1")
	assert_eq(Enums.Currency.FRAGMENTS, 2, "Currency.FRAGMENTS should be 2")
	assert_eq(Enums.Currency.ARTIFACTS, 3, "Currency.ARTIFACTS should be 3")


func test_currency_count() -> void:
	assert_eq(Enums.Currency.size(), 4, "Currency should have exactly 4 values")


func test_expedition_status_values() -> void:
	assert_eq(Enums.ExpeditionStatus.PREPARING, 0, "ExpeditionStatus.PREPARING should be 0")
	assert_eq(Enums.ExpeditionStatus.IN_PROGRESS, 1, "ExpeditionStatus.IN_PROGRESS should be 1")
	assert_eq(Enums.ExpeditionStatus.COMPLETED, 2, "ExpeditionStatus.COMPLETED should be 2")
	assert_eq(Enums.ExpeditionStatus.FAILED, 3, "ExpeditionStatus.FAILED should be 3")


func test_expedition_status_count() -> void:
	assert_eq(Enums.ExpeditionStatus.size(), 4, "ExpeditionStatus should have exactly 4 values")


# ---------------------------------------------------------------------------
# Section B: GameConfig Dictionary Completeness Tests
# ---------------------------------------------------------------------------

func test_base_growth_seconds_completeness() -> void:
	for rarity_value: int in Enums.SeedRarity.values():
		assert_true(
			GameConfig.BASE_GROWTH_SECONDS.has(rarity_value),
			"BASE_GROWTH_SECONDS missing key for SeedRarity value %d" % rarity_value
		)


func test_base_growth_seconds_values() -> void:
	assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.COMMON], 60)
	assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.UNCOMMON], 120)
	assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.RARE], 300)
	assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.EPIC], 600)
	assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.LEGENDARY], 1200)


func test_base_growth_seconds_positive() -> void:
	for rarity_value: int in Enums.SeedRarity.values():
		assert_gt(
			GameConfig.BASE_GROWTH_SECONDS[rarity_value], 0,
			"BASE_GROWTH_SECONDS must be positive for rarity %d" % rarity_value
		)


func test_base_growth_seconds_monotonically_increasing() -> void:
	var values: Array = Enums.SeedRarity.values()
	for i: int in range(1, values.size()):
		assert_gt(
			GameConfig.BASE_GROWTH_SECONDS[values[i]],
			GameConfig.BASE_GROWTH_SECONDS[values[i - 1]],
			"BASE_GROWTH_SECONDS should increase with rarity"
		)


func test_xp_per_tier_completeness() -> void:
	for tier_value: int in Enums.LevelTier.values():
		assert_true(
			GameConfig.XP_PER_TIER.has(tier_value),
			"XP_PER_TIER missing key for LevelTier value %d" % tier_value
		)


func test_xp_per_tier_values() -> void:
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.NOVICE], 0)
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.SKILLED], 100)
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.VETERAN], 350)
	assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.ELITE], 750)


func test_xp_per_tier_monotonically_increasing() -> void:
	var values: Array = Enums.LevelTier.values()
	for i: int in range(1, values.size()):
		assert_gt(
			GameConfig.XP_PER_TIER[values[i]],
			GameConfig.XP_PER_TIER[values[i - 1]],
			"XP_PER_TIER should be monotonically increasing"
		)


func test_base_stats_completeness() -> void:
	for cls_value: int in Enums.AdventurerClass.values():
		assert_true(
			GameConfig.BASE_STATS.has(cls_value),
			"BASE_STATS missing key for AdventurerClass value %d" % cls_value
		)


func test_base_stats_required_keys() -> void:
	var required_keys: Array[String] = ["health", "attack", "defense", "speed", "utility"]
	for cls_value: int in Enums.AdventurerClass.values():
		var stats: Dictionary = GameConfig.BASE_STATS[cls_value]
		for key: String in required_keys:
			assert_true(
				stats.has(key),
				"BASE_STATS[%d] missing key '%s'" % [cls_value, key]
			)


func test_base_stats_all_positive() -> void:
	for cls_value: int in Enums.AdventurerClass.values():
		var stats: Dictionary = GameConfig.BASE_STATS[cls_value]
		for key: String in stats.keys():
			assert_gt(
				stats[key], 0,
				"BASE_STATS[%d]['%s'] must be positive" % [cls_value, key]
			)


func test_base_stats_exactly_five_keys() -> void:
	for cls_value: int in Enums.AdventurerClass.values():
		assert_eq(
			GameConfig.BASE_STATS[cls_value].size(), 5,
			"BASE_STATS[%d] should have exactly 5 keys" % cls_value
		)


func test_mutation_slots_completeness() -> void:
	for rarity_value: int in Enums.SeedRarity.values():
		assert_true(
			GameConfig.MUTATION_SLOTS.has(rarity_value),
			"MUTATION_SLOTS missing key for SeedRarity value %d" % rarity_value
		)


func test_mutation_slots_values() -> void:
	assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.COMMON], 1)
	assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.UNCOMMON], 2)
	assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.RARE], 3)
	assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.EPIC], 4)
	assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.LEGENDARY], 5)


func test_mutation_slots_monotonically_increasing() -> void:
	var values: Array = Enums.SeedRarity.values()
	for i: int in range(1, values.size()):
		assert_gt(
			GameConfig.MUTATION_SLOTS[values[i]],
			GameConfig.MUTATION_SLOTS[values[i - 1]],
			"MUTATION_SLOTS should increase with rarity"
		)


func test_currency_earn_rates_completeness() -> void:
	for curr_value: int in Enums.Currency.values():
		assert_true(
			GameConfig.CURRENCY_EARN_RATES.has(curr_value),
			"CURRENCY_EARN_RATES missing key for Currency value %d" % curr_value
		)


func test_currency_earn_rates_non_negative() -> void:
	for curr_value: int in Enums.Currency.values():
		assert_true(
			GameConfig.CURRENCY_EARN_RATES[curr_value] >= 0,
			"CURRENCY_EARN_RATES must be non-negative for currency %d" % curr_value
		)


func test_room_difficulty_scale_completeness() -> void:
	for room_value: int in Enums.RoomType.values():
		assert_true(
			GameConfig.ROOM_DIFFICULTY_SCALE.has(room_value),
			"ROOM_DIFFICULTY_SCALE missing key for RoomType value %d" % room_value
		)


func test_room_difficulty_scale_positive() -> void:
	for room_value: int in Enums.RoomType.values():
		assert_gt(
			GameConfig.ROOM_DIFFICULTY_SCALE[room_value], 0.0,
			"ROOM_DIFFICULTY_SCALE must be positive for room type %d" % room_value
		)


func test_phase_growth_multipliers_completeness() -> void:
	for phase_value: int in Enums.SeedPhase.values():
		assert_true(
			GameConfig.PHASE_GROWTH_MULTIPLIERS.has(phase_value),
			"PHASE_GROWTH_MULTIPLIERS missing key for SeedPhase value %d" % phase_value
		)


func test_phase_growth_multipliers_positive() -> void:
	for phase_value: int in Enums.SeedPhase.values():
		assert_gt(
			GameConfig.PHASE_GROWTH_MULTIPLIERS[phase_value], 0.0,
			"PHASE_GROWTH_MULTIPLIERS must be positive for phase %d" % phase_value
		)


func test_element_names_completeness() -> void:
	for elem_value: int in Enums.Element.values():
		assert_true(
			GameConfig.ELEMENT_NAMES.has(elem_value),
			"ELEMENT_NAMES missing key for Element value %d" % elem_value
		)


func test_element_names_non_empty() -> void:
	for elem_value: int in Enums.Element.values():
		assert_ne(
			GameConfig.ELEMENT_NAMES[elem_value], "",
			"ELEMENT_NAMES must not be empty for element %d" % elem_value
		)


func test_rarity_colors_completeness() -> void:
	for rarity_value: int in Enums.SeedRarity.values():
		assert_true(
			GameConfig.RARITY_COLORS.has(rarity_value),
			"RARITY_COLORS missing key for SeedRarity value %d" % rarity_value
		)


func test_rarity_colors_are_color_type() -> void:
	for rarity_value: int in Enums.SeedRarity.values():
		assert_true(
			GameConfig.RARITY_COLORS[rarity_value] is Color,
			"RARITY_COLORS[%d] must be a Color instance" % rarity_value
		)


# ---------------------------------------------------------------------------
# Section C: Helper Method Tests
# ---------------------------------------------------------------------------

func test_seed_rarity_name_common() -> void:
	assert_eq(Enums.seed_rarity_name(Enums.SeedRarity.COMMON), "Common")


func test_seed_rarity_name_uncommon() -> void:
	assert_eq(Enums.seed_rarity_name(Enums.SeedRarity.UNCOMMON), "Uncommon")


func test_seed_rarity_name_rare() -> void:
	assert_eq(Enums.seed_rarity_name(Enums.SeedRarity.RARE), "Rare")


func test_seed_rarity_name_epic() -> void:
	assert_eq(Enums.seed_rarity_name(Enums.SeedRarity.EPIC), "Epic")


func test_seed_rarity_name_legendary() -> void:
	assert_eq(Enums.seed_rarity_name(Enums.SeedRarity.LEGENDARY), "Legendary")


func test_get_base_stats_warrior() -> void:
	var stats: Dictionary = GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)
	assert_true(stats.has("health"), "Warrior stats must have 'health'")
	assert_true(stats.has("attack"), "Warrior stats must have 'attack'")
	assert_true(stats.has("defense"), "Warrior stats must have 'defense'")
	assert_true(stats.has("speed"), "Warrior stats must have 'speed'")
	assert_true(stats.has("utility"), "Warrior stats must have 'utility'")
	assert_eq(stats.size(), 5, "Warrior stats should have exactly 5 keys")


func test_get_base_stats_all_classes() -> void:
	for cls_value: int in Enums.AdventurerClass.values():
		var stats: Dictionary = GameConfig.get_base_stats(cls_value)
		assert_eq(
			stats.size(), 5,
			"get_base_stats(%d) should return a Dictionary with 5 keys" % cls_value
		)
```

---

## Section 15 — Playtesting Verification

These scenarios verify that the enum and config values produce a good player experience when consumed by downstream systems.

| #  | Scenario                                          | What to Verify                                                                                                             | Expected Outcome                                                                                 |
| -- | ------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| 1  | **Common seed growth feels snappy**               | Plant a Common seed. Time the growth from Spore to Sprout at base rate.                                                    | Growth completes in 60 seconds — feels fast, rewarding, teaches the mechanic.                    |
| 2  | **Legendary seed growth feels meaningful**         | Plant a Legendary seed. Observe the 1200-second (20-minute) timer.                                                         | Growth feels like a worthwhile investment. Player can do other activities while waiting.          |
| 3  | **Warrior feels tanky vs. Mage feels fragile**     | Create a Warrior and a Mage. Compare their health and attack stats.                                                         | Warrior has noticeably more HP and defense. Mage has higher utility. Class identity is clear.     |
| 4  | **Gold income feels rewarding**                    | Clear 10 rooms. Check accumulated gold.                                                                                     | ~100 gold (10 per room base). Enough to feel progress toward shop purchases.                     |
| 5  | **Rarity colors are visually distinct**             | Display all 5 rarity tiers side-by-side in the UI.                                                                          | Each rarity has a clearly distinct color. Common (gray) vs Legendary (gold) is unmistakable.     |
| 6  | **Element names are clear and evocative**           | Show all 5 element names in a tooltip.                                                                                       | "Terra", "Flame", "Frost", "Arcane", "Shadow" — each immediately communicates its fantasy.       |
| 7  | **XP progression feels achievable**                | Earn XP through combat. Track progress from Novice (0) to Skilled (100).                                                    | Reaching Skilled tier takes a satisfying number of combats. Not too fast, not grindy.            |
| 8  | **Room difficulty scaling feels fair**              | Enter a Boss room after several Combat rooms. Compare difficulty.                                                            | Boss room feels appropriately harder (higher scaling factor) without feeling unfair.              |
| 9  | **Phase growth multipliers create progression**     | Observe seed growth speed in Spore vs. Bloom phase.                                                                          | Later phases feel faster (multiplier < 1.0) — reward for nurturing a seed through early phases.  |
| 10 | **Mutation slots motivate rarity chasing**          | Compare a Common seed (1 mutation slot) to an Epic seed (4 mutation slots).                                                  | The difference in customization potential makes higher-rarity seeds feel dramatically more valuable.|

---

## Section 16 — Implementation Prompt

### 16.1 — `src/models/enums.gd` — Complete Implementation

```gdscript
## src/models/enums.gd
## Centralized game-wide enumerations for Dungeon Seed.
## All enums are drawn directly from GDD-v2.md.
## This file is the single source of truth for every named constant in the game.
##
## Usage: Enums.SeedRarity.COMMON, Enums.Element.TERRA, etc.
## No instantiation needed — access via class_name static reference.
class_name Enums


# ---------------------------------------------------------------------------
# §4.1 — Seed System Enums
# ---------------------------------------------------------------------------

## Seed rarity tiers determine growth time, mutation slots, and loot quality.
## GDD Reference: §4.1 (Seed System — Rarity Tiers)
enum SeedRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

## Elemental affinity of a seed. Affects dungeon generation and combat bonuses.
## GDD Reference: §4.1 (Seed System — Elemental Affinity)
enum Element { TERRA, FLAME, FROST, ARCANE, SHADOW }

## Growth phases a seed passes through from planting to harvest.
## GDD Reference: §4.1 (Seed System — Growth Phases)
enum SeedPhase { SPORE, SPROUT, BUD, BLOOM }


# ---------------------------------------------------------------------------
# §4.2 — Dungeon System Enums
# ---------------------------------------------------------------------------

## Types of rooms that can appear in a dungeon layout.
## GDD Reference: §4.2 (Dungeon Generation — Room Types)
enum RoomType { COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS }

## Status of an expedition (adventurer party sent into a dungeon).
## GDD Reference: §4.2 (Dungeon Generation — Expedition Flow)
enum ExpeditionStatus { PREPARING, IN_PROGRESS, COMPLETED, FAILED }


# ---------------------------------------------------------------------------
# §4.3 — Adventurer System Enums
# ---------------------------------------------------------------------------

## Adventurer class archetypes with distinct stat distributions.
## GDD Reference: §4.3 (Adventurer System — Classes)
enum AdventurerClass { WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL }

## Adventurer experience/progression tiers.
## GDD Reference: §4.3 (Adventurer System — Level Tiers)
enum LevelTier { NOVICE, SKILLED, VETERAN, ELITE }

## Equipment slots available on each adventurer.
## GDD Reference: §4.3 (Adventurer System — Equipment)
enum EquipSlot { WEAPON, ARMOR, ACCESSORY }


# ---------------------------------------------------------------------------
# §4.4 — Loot & Economy Enums
# ---------------------------------------------------------------------------

## Loot/item rarity tiers. Mirrors SeedRarity values but is a separate type
## to avoid coupling seed systems with item systems.
## GDD Reference: §4.4 (Loot & Economy — Item Rarity)
enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

## Currency types in the game economy.
## GDD Reference: §4.4 (Loot & Economy — Currency Types)
enum Currency { GOLD, ESSENCE, FRAGMENTS, ARTIFACTS }


# ---------------------------------------------------------------------------
# Helper Methods
# ---------------------------------------------------------------------------

## Returns the human-readable display name for a SeedRarity value.
## Example: Enums.seed_rarity_name(Enums.SeedRarity.EPIC) -> "Epic"
static func seed_rarity_name(rarity: SeedRarity) -> String:
	match rarity:
		SeedRarity.COMMON:
			return "Common"
		SeedRarity.UNCOMMON:
			return "Uncommon"
		SeedRarity.RARE:
			return "Rare"
		SeedRarity.EPIC:
			return "Epic"
		SeedRarity.LEGENDARY:
			return "Legendary"
		_:
			push_warning("Unknown SeedRarity value: %d" % rarity)
			return "Unknown"


## Returns the human-readable display name for an ItemRarity value.
## Example: Enums.item_rarity_name(Enums.ItemRarity.RARE) -> "Rare"
static func item_rarity_name(rarity: ItemRarity) -> String:
	match rarity:
		ItemRarity.COMMON:
			return "Common"
		ItemRarity.UNCOMMON:
			return "Uncommon"
		ItemRarity.RARE:
			return "Rare"
		ItemRarity.EPIC:
			return "Epic"
		ItemRarity.LEGENDARY:
			return "Legendary"
		_:
			push_warning("Unknown ItemRarity value: %d" % rarity)
			return "Unknown"


## Returns the human-readable display name for an AdventurerClass value.
## Example: Enums.adventurer_class_name(Enums.AdventurerClass.MAGE) -> "Mage"
static func adventurer_class_name(cls: AdventurerClass) -> String:
	match cls:
		AdventurerClass.WARRIOR:
			return "Warrior"
		AdventurerClass.RANGER:
			return "Ranger"
		AdventurerClass.MAGE:
			return "Mage"
		AdventurerClass.ROGUE:
			return "Rogue"
		AdventurerClass.ALCHEMIST:
			return "Alchemist"
		AdventurerClass.SENTINEL:
			return "Sentinel"
		_:
			push_warning("Unknown AdventurerClass value: %d" % cls)
			return "Unknown"


## Returns the human-readable display name for an Element value.
## Example: Enums.element_name(Enums.Element.FROST) -> "Frost"
static func element_name(element: Element) -> String:
	match element:
		Element.TERRA:
			return "Terra"
		Element.FLAME:
			return "Flame"
		Element.FROST:
			return "Frost"
		Element.ARCANE:
			return "Arcane"
		Element.SHADOW:
			return "Shadow"
		_:
			push_warning("Unknown Element value: %d" % element)
			return "Unknown"


## Returns the human-readable display name for an EquipSlot value.
## Example: Enums.equip_slot_name(Enums.EquipSlot.WEAPON) -> "Weapon"
static func equip_slot_name(slot: EquipSlot) -> String:
	match slot:
		EquipSlot.WEAPON:
			return "Weapon"
		EquipSlot.ARMOR:
			return "Armor"
		EquipSlot.ACCESSORY:
			return "Accessory"
		_:
			push_warning("Unknown EquipSlot value: %d" % slot)
			return "Unknown"
```

### 16.2 — `src/models/game_config.gd` — Complete Implementation

```gdscript
## src/models/game_config.gd
## Centralized balance-tuning constants for Dungeon Seed.
## All values are const — no runtime mutation. Change values here to rebalance the game.
## Every downstream system reads from GameConfig instead of hardcoding numbers.
##
## Usage: GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.COMMON] -> 60
## No instantiation needed — access via class_name static reference.
class_name GameConfig


# ===========================================================================
# §4.1 — Seed System Constants
# ===========================================================================

## Base growth time in seconds for each seed rarity tier.
## Higher rarity seeds take longer to grow, rewarding patience.
## GDD Reference: §4.1 (Seed System — Growth Timers)
const BASE_GROWTH_SECONDS: Dictionary = {
	Enums.SeedRarity.COMMON: 60,
	Enums.SeedRarity.UNCOMMON: 120,
	Enums.SeedRarity.RARE: 300,
	Enums.SeedRarity.EPIC: 600,
	Enums.SeedRarity.LEGENDARY: 1200,
}

## Number of mutation slots available per seed rarity.
## More slots = more trait combinations = more powerful dungeon seeds.
## GDD Reference: §4.1 (Seed System — Mutation Slots)
const MUTATION_SLOTS: Dictionary = {
	Enums.SeedRarity.COMMON: 1,
	Enums.SeedRarity.UNCOMMON: 2,
	Enums.SeedRarity.RARE: 3,
	Enums.SeedRarity.EPIC: 4,
	Enums.SeedRarity.LEGENDARY: 5,
}

## Growth speed multiplier per seed phase.
## Later phases grow faster, rewarding players who nurture seeds through early stages.
## Multiplier is applied to base growth rate: effective_time = base_time * multiplier.
## Values < 1.0 mean faster growth; values > 1.0 mean slower growth.
## GDD Reference: §4.1 (Seed System — Phase Progression)
const PHASE_GROWTH_MULTIPLIERS: Dictionary = {
	Enums.SeedPhase.SPORE: 1.0,
	Enums.SeedPhase.SPROUT: 0.9,
	Enums.SeedPhase.BUD: 0.75,
	Enums.SeedPhase.BLOOM: 0.5,
}

## Human-readable display names for each element.
## Used in UI tooltips, seed descriptions, and lore text.
## GDD Reference: §4.1 (Seed System — Elemental Affinity)
const ELEMENT_NAMES: Dictionary = {
	Enums.Element.TERRA: "Terra",
	Enums.Element.FLAME: "Flame",
	Enums.Element.FROST: "Frost",
	Enums.Element.ARCANE: "Arcane",
	Enums.Element.SHADOW: "Shadow",
}


# ===========================================================================
# §4.2 — Dungeon System Constants
# ===========================================================================

## Difficulty scaling factor per room type.
## Combat and Boss rooms are harder; Treasure and Rest rooms are easier.
## Applied as a multiplier to base enemy stats and reward calculations.
## GDD Reference: §4.2 (Dungeon Generation — Room Difficulty)
const ROOM_DIFFICULTY_SCALE: Dictionary = {
	Enums.RoomType.COMBAT: 1.0,
	Enums.RoomType.TREASURE: 0.5,
	Enums.RoomType.TRAP: 1.2,
	Enums.RoomType.PUZZLE: 0.8,
	Enums.RoomType.REST: 0.0,
	Enums.RoomType.BOSS: 2.0,
}


# ===========================================================================
# §4.3 — Adventurer System Constants
# ===========================================================================

## XP thresholds for each adventurer level tier.
## An adventurer advances to a tier when their cumulative XP >= the threshold.
## Values are monotonically increasing. NOVICE starts at 0 (immediate).
## GDD Reference: §4.3 (Adventurer System — Level Tiers)
const XP_PER_TIER: Dictionary = {
	Enums.LevelTier.NOVICE: 0,
	Enums.LevelTier.SKILLED: 100,
	Enums.LevelTier.VETERAN: 350,
	Enums.LevelTier.ELITE: 750,
}

## Base stat blocks per adventurer class.
## Each class has 5 stats: health, attack, defense, speed, utility.
## These are starting values at Novice tier — scaling is applied by downstream systems.
## GDD Reference: §4.3 (Adventurer System — Class Stats)
const BASE_STATS: Dictionary = {
	Enums.AdventurerClass.WARRIOR: {
		"health": 120,
		"attack": 18,
		"defense": 15,
		"speed": 8,
		"utility": 5,
	},
	Enums.AdventurerClass.RANGER: {
		"health": 90,
		"attack": 15,
		"defense": 10,
		"speed": 16,
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
		"attack": 20,
		"defense": 8,
		"speed": 18,
		"utility": 8,
	},
	Enums.AdventurerClass.ALCHEMIST: {
		"health": 85,
		"attack": 10,
		"defense": 9,
		"speed": 11,
		"utility": 22,
	},
	Enums.AdventurerClass.SENTINEL: {
		"health": 130,
		"attack": 10,
		"defense": 20,
		"speed": 6,
		"utility": 7,
	},
}


# ===========================================================================
# §4.4 — Loot & Economy Constants
# ===========================================================================

## Base currency earned per room clear, before modifiers.
## These define the primary economic faucet rate.
## ARTIFACTS earn 0 at base — they are boss-only or event drops.
## GDD Reference: §4.4 (Loot & Economy — Currency Earn Rates)
const CURRENCY_EARN_RATES: Dictionary = {
	Enums.Currency.GOLD: 10,
	Enums.Currency.ESSENCE: 2,
	Enums.Currency.FRAGMENTS: 1,
	Enums.Currency.ARTIFACTS: 0,
}

## UI display colors per rarity tier (used for item names, borders, particles).
## Colors are designed for readability on dark backgrounds.
## GDD Reference: §4.4 (Loot & Economy — Rarity Visual Identity)
const RARITY_COLORS: Dictionary = {
	Enums.SeedRarity.COMMON: Color(0.66, 0.66, 0.66),
	Enums.SeedRarity.UNCOMMON: Color(0.18, 0.80, 0.25),
	Enums.SeedRarity.RARE: Color(0.26, 0.52, 0.96),
	Enums.SeedRarity.EPIC: Color(0.64, 0.21, 0.93),
	Enums.SeedRarity.LEGENDARY: Color(1.00, 0.78, 0.06),
}


# ===========================================================================
# Helper Methods
# ===========================================================================

## Returns the base stat dictionary for a given adventurer class.
## Returns a copy to prevent accidental mutation of the const source.
## Example: GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)
##   -> { "health": 120, "attack": 18, "defense": 15, "speed": 8, "utility": 5 }
static func get_base_stats(cls: Enums.AdventurerClass) -> Dictionary:
	if BASE_STATS.has(cls):
		return BASE_STATS[cls].duplicate()
	push_warning("Unknown AdventurerClass value: %d" % cls)
	return {}


## Returns the growth time in seconds for a given seed rarity.
## Example: GameConfig.get_growth_seconds(Enums.SeedRarity.RARE) -> 300
static func get_growth_seconds(rarity: Enums.SeedRarity) -> int:
	if BASE_GROWTH_SECONDS.has(rarity):
		return BASE_GROWTH_SECONDS[rarity]
	push_warning("Unknown SeedRarity value: %d" % rarity)
	return 0


## Returns the number of mutation slots for a given seed rarity.
## Example: GameConfig.get_mutation_slots(Enums.SeedRarity.EPIC) -> 4
static func get_mutation_slots(rarity: Enums.SeedRarity) -> int:
	if MUTATION_SLOTS.has(rarity):
		return MUTATION_SLOTS[rarity]
	push_warning("Unknown SeedRarity value: %d" % rarity)
	return 0


## Returns the XP threshold required to reach a given level tier.
## Example: GameConfig.get_xp_for_tier(Enums.LevelTier.VETERAN) -> 350
static func get_xp_for_tier(tier: Enums.LevelTier) -> int:
	if XP_PER_TIER.has(tier):
		return XP_PER_TIER[tier]
	push_warning("Unknown LevelTier value: %d" % tier)
	return 0


## Returns the UI display color for a given seed/item rarity.
## Example: GameConfig.get_rarity_color(Enums.SeedRarity.LEGENDARY) -> Color(1.0, 0.78, 0.06)
static func get_rarity_color(rarity: Enums.SeedRarity) -> Color:
	if RARITY_COLORS.has(rarity):
		return RARITY_COLORS[rarity]
	push_warning("Unknown SeedRarity value: %d" % rarity)
	return Color.WHITE


## Returns the room difficulty scale factor for a given room type.
## Example: GameConfig.get_room_difficulty(Enums.RoomType.BOSS) -> 2.0
static func get_room_difficulty(room_type: Enums.RoomType) -> float:
	if ROOM_DIFFICULTY_SCALE.has(room_type):
		return ROOM_DIFFICULTY_SCALE[room_type]
	push_warning("Unknown RoomType value: %d" % room_type)
	return 1.0


## Returns the phase growth multiplier for a given seed phase.
## Example: GameConfig.get_phase_multiplier(Enums.SeedPhase.BLOOM) -> 0.5
static func get_phase_multiplier(phase: Enums.SeedPhase) -> float:
	if PHASE_GROWTH_MULTIPLIERS.has(phase):
		return PHASE_GROWTH_MULTIPLIERS[phase]
	push_warning("Unknown SeedPhase value: %d" % phase)
	return 1.0
```

### 16.3 — Implementation Notes

1. **File creation order**: Create `src/models/enums.gd` first, then `src/models/game_config.gd` (since `game_config.gd` references `Enums.*`).
2. **No `extends` statement**: Both files implicitly extend `RefCounted`. Do not add `extends Node` — these files should not be autoloads.
3. **`class_name` is mandatory**: Without `class_name Enums`, other scripts cannot access the enums without `preload()`.
4. **Helper methods return copies**: `get_base_stats()` returns `duplicate()` of the dictionary to prevent callers from accidentally mutating shared data.
5. **All helpers include fallback behavior**: Invalid enum values produce a `push_warning()` and return a safe default (empty dict, 0, Color.WHITE).
6. **Trailing commas**: Every dictionary entry ends with a trailing comma for clean git diffs when adding entries.
7. **Section banners**: Use `# ===========================================================================` in `game_config.gd` and `# ---------------------------------------------------------------------------` in `enums.gd` to visually separate GDD sections.
8. **Test file**: Place the GUT test suite at `tests/models/test_enums_and_config.gd` as shown in Section 14.

---

*End of TASK-003: Enums, Constants & Data Dictionary*
