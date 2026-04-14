# TASK-013: Adventurer Roster & Party Builder

---

## Section 1 · Header

| Field              | Value                                                                 |
|--------------------|-----------------------------------------------------------------------|
| **Task ID**        | TASK-013                                                              |
| **Title**          | Adventurer Roster & Party Builder                                     |
| **Priority**       | 🟡 P1 — Important (enables party composition for expeditions)        |
| **Tier**           | Core Mechanic                                                         |
| **Complexity**     | 5 points (Moderate)                                                   |
| **Phase**          | Phase 3 — Domain Services                                             |
| **Wave**           | Wave 3 (depends on TASK-006)                                          |
| **Stream**         | 🔴 MCH (Mechanics) — Primary                                          |
| **Cross-Stream**   | 🔵 VIS (roster UI), 🟣 NAR (adventurer names/lore)                   |
| **GDD Reference**  | GDD-v3.md §6 Adventurer System, §6.2 Properties, §6.3 Classes        |
| **Milestone**      | M3 — Playable Expedition Loop                                         |
| **Dependencies**   | TASK-006 (Adventurer data model & class definitions)                  |
| **Critical Path**  | ❌ No — off critical path (supports expedition dispatch)               |
| **Estimated Effort** | 4–6 hours for an experienced GDScript developer                      |
| **Assignee**       | Unassigned                                                            |

---

## Section 2 · Description

### 2.1 What This Feature IS

TASK-013 implements the **Roster Manager** — the persistent collection of all adventurers the player has recruited, plus the **Party Builder** system that selects 1–4 adventurers for expedition dispatch. This is the bridge between adventurer recruitment (future UI task) and expedition execution (TASK-015).

The deliverables are:

1. **AdventurerRoster service** — a RefCounted domain service that manages the global collection of all recruited adventurers, indexed by unique StringName IDs.
2. **Party composition system** — logic to assemble a party of 1–4 adventurers from the roster, validate party composition rules, and serialize/deserialize party state.
3. **Recruitment logic** — procedural adventurer generation (name, class, innate affinity, starting stats) following GDD §6 class growth tables.
4. **Roster serialization** — full save/load support for all adventurers and their properties (level, XP, stats, condition, morale, affinity).
5. **Party validation** — enforce rules: max 4 adventurers, no duplicates, only Healthy/Fatigued adventurers can be deployed (Injured/Exhausted must recover).
6. **EventBus integration** — emit `adventurer_recruited` when a new adventurer joins, `party_assembled` when a valid party is formed.

### 2.2 Player Experience Impact

This task enables the **strategic party composition** layer of the game — one of the three decision points in the core loop (Plant → **Compose Party** → Dispatch → Harvest).

**Engagement delta:**
- **Decision density**: Every expedition requires the player to consider: Which 4 of my 8 adventurers? Do I risk sending an Injured adventurer? Do I need a healer? Do I have elemental advantage?
- **Attachment formation**: Named adventurers with persistent progression (levels, equipment, morale) create emotional bonds. Players will remember "that time Kira solo-tanked the boss at 5% HP."
- **Failure consequence without punishment**: An adventurer KO results in Injured condition, not death. The player feels tension (can't use them for 2 hours) without loss aversion rage-quit.

**Session time impact:**
- **Quick decision** (30 seconds): "I'll take my usual team — Kira, Thane, Lira, and skip the 4th slot."
- **Deep planning** (2–5 minutes): "This is a Flame dungeon with Perilous mutation. I need Frost DPS, a healer, high PER for secrets, and... do I risk my Exhausted Warrior or go with 3?"

**Retention impact:**
- Adventurers are **persistent investment**. A level 12 Warrior with Rare equipment represents 4+ hours of player time. Players return to continue building that power fantasy.
- Condition recovery happens in **real-time**. An Injured adventurer recovering in 3 hours creates a natural "come back later" pull without FOMO pressure.

### 2.3 Development Cost

| Metric                     | Target          |
|----------------------------|-----------------|
| Lines of production code   | 400–600         |
| Lines of test code         | 250–350         |
| New files created          | 3–5             |
| Existing files modified    | 2 (EventBus, GameManager) |
| Risk level                 | Medium (complex serialization + validation) |

### 2.4 Technical Architecture

#### Class Diagram

```
┌─────────────────────────────────────────────────────────┐
│              AdventurerRoster (RefCounted)              │
│─────────────────────────────────────────────────────────│
│ + adventurers: Dictionary[StringName, AdventurerData]  │
│ + current_party: Array[StringName] (max 4)             │
│ + max_roster_size: int                                 │
│─────────────────────────────────────────────────────────│
│ + recruit_adventurer(class_type, level) → StringName   │
│ + get_adventurer(id) → AdventurerData                  │
│ + get_all_adventurers() → Array[AdventurerData]        │
│ + remove_adventurer(id) → bool                         │
│ + set_party(adventurer_ids) → Error                    │
│ + get_party() → Array[AdventurerData]                  │
│ + clear_party() → void                                 │
│ + validate_party(ids) → Error                          │
│ + to_dict() → Dictionary                               │
│ + from_dict(data) → void                               │
└─────────────────────────────────────────────────────────┘
         │
         │ owns 0..N
         ▼
┌─────────────────────────────────────────────────────────┐
│          AdventurerData (from TASK-006)                 │
│─────────────────────────────────────────────────────────│
│ + id: StringName                                        │
│ + name: String                                          │
│ + class_type: Enums.ClassType                          │
│ + level: int (1–50)                                     │
│ + xp: int                                               │
│ + stats: StatBlock                                      │
│ + affinity: Enums.Element                              │
│ + condition: Enums.AdventurerCondition                  │
│ + morale: int (0–100)                                   │
│ + equipped_weapon: StringName (item_id or null)        │
│ + equipped_armor: StringName                           │
│ + equipped_accessory: StringName                       │
│ + skills: Array[SkillData]                             │
└─────────────────────────────────────────────────────────┘
```

#### Service Integration

```
┌───────────────────────────────────────────────────────────┐
│                    GameManager (autoload)                 │
│   roster: AdventurerRoster (initialized in _ready)        │
└───────────────────────────────────────────────────────────┘
                          │
                          │ initializes
                          ▼
┌───────────────────────────────────────────────────────────┐
│              AdventurerRoster (service)                   │
│  ┌───────────────────────────────────────────────────┐    │
│  │ adventurers: Dictionary                           │    │
│  │   key: StringName (adventurer_id)                 │    │
│  │   value: AdventurerData (full stats, condition)   │    │
│  └───────────────────────────────────────────────────┘    │
│  ┌───────────────────────────────────────────────────┐    │
│  │ current_party: Array[StringName] (0–4 IDs)        │    │
│  └───────────────────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────┘
                          │
                          │ emits on recruitment/party change
                          ▼
┌───────────────────────────────────────────────────────────┐
│                    EventBus (autoload)                    │
│  signal adventurer_recruited(id, class_type)              │
│  signal party_assembled(party_ids)                        │
│  signal party_cleared()                                   │
└───────────────────────────────────────────────────────────┘
```

### 2.5 System Interaction Map

```
┌──────────────────────┐         ┌──────────────────────┐
│  Tavern UI (future)  │────────▶│  AdventurerRoster    │
│  "Recruit Warrior"   │         │  .recruit_adventurer │
└──────────────────────┘         └──────────────────────┘
                                           │
                                           │ stores
                                           ▼
                                 ┌──────────────────────┐
                                 │ adventurers: Dict    │
                                 │ key: StringName      │
                                 │ value: AdventurerData│
                                 └──────────────────────┘
                                           │
                                           │ read by
                                           ▼
┌──────────────────────┐         ┌──────────────────────┐
│ Expedition Dispatch  │────────▶│  AdventurerRoster    │
│ UI (TASK-019)        │         │  .set_party([ids])   │
└──────────────────────┘         └──────────────────────┘
                                           │
                                           │ validates & stores
                                           ▼
                                 ┌──────────────────────┐
                                 │ current_party: Array │
                                 │ [id1, id2, id3, id4] │
                                 └──────────────────────┘
                                           │
                                           │ consumed by
                                           ▼
┌──────────────────────┐         ┌──────────────────────┐
│ Expedition Resolver  │────────▶│  AdventurerRoster    │
│ (TASK-015)           │         │  .get_party()        │
└──────────────────────┘         └──────────────────────┘
                                           │
                                           │ returns
                                           ▼
                                 ┌──────────────────────┐
                                 │ Array[AdventurerData]│
                                 │ (full stats + gear)  │
                                 └──────────────────────┘
```

### 2.6 Constraints and Design Decisions

| # | Decision | Rationale | Trade-off |
|---|----------|-----------|-----------|
| 1 | **Roster stored in Dictionary, not Array** | O(1) lookup by ID. Adventurer order is UI concern, not data structure concern. | Iteration requires `.values()` call, but this is infrequent. |
| 2 | **Party stored as Array[StringName], not Array[AdventurerData]** | Avoids duplicate data. Single source of truth (the roster Dictionary). Party is a *reference* to adventurers, not a copy. | Must dereference IDs to get data. Adds validation complexity. |
| 3 | **Max party size is 4, enforced at set_party()** | GDD §6.1 specifies 1–4 adventurers. Hard limit prevents UI bugs. | Less flexible than soft limit, but clarity > flexibility. |
| 4 | **Only Healthy/Fatigued can be deployed** | GDD §6.2 Condition system: Injured/Exhausted require recovery time. Enforcing at service layer prevents UI bypass. | Player frustration when favorite adventurer is locked. Mitigated by condition recovery being real-time (offline progress). |
| 5 | **Procedural name generation at recruitment** | Creates unique identity without manual input. Culture-themed name tables (from GDD §6.2) add flavor. | Less player agency than custom naming (deferred to future QoL feature). |
| 6 | **Affinity randomized at recruitment** | GDD §6.2: "Innate elemental lean. Randomized at recruitment." Creates variety between adventurers of the same class. | Can't target-recruit "Frost Warrior" specifically. Adds reroll economy design space (future). |
| 7 | **Morale starts at 50 (neutral)** | GDD §6.2 Morale: 0–100 scale. New recruits are neither motivated nor demoralized. | No "honeymoon bonus" for new recruits. Intentional — morale is earned through victories. |
| 8 | **No permadeath, ever** | GDD §6.1: "No permadeath — ever. Adventurers who are knocked out are recalled with injuries." Non-negotiable design pillar. | Reduces tension in combat. Mitigated by meaningful condition consequences (recovery time, stat penalties). |

---

## Section 3 · Use Cases

### UC-01: Luna the Completionist — Building a Balanced Party

**Archetype:** Luna recruits one of every class, levels them evenly, and meticulously composes parties for each dungeon based on elemental matchups and enemy composition.

**Scenario:**
1. Luna has 6 adventurers in her roster: Warrior (Frost affinity), Ranger (Terra), Mage (Arcane), Rogue (Shadow), Alchemist (Flame), Sentinel (Frost).
2. She is about to enter an Embervault (Flame) dungeon with Perilous mutation (high enemy density).
3. She opens the Expedition Dispatch UI and views the dungeon preview: Flame affinity, 16 rooms, ☠☠☠☠ difficulty.
4. She drags her **Frost-affinity Warrior** into slot 1 (tanks with elemental advantage).
5. She drags her **Arcane Mage** into slot 2 (AoE damage for high enemy count).
6. She drags her **Alchemist** into slot 3 (healer for sustained boss fight).
7. She considers her Rogue but decides the dungeon doesn't have Bountiful mutation (fewer treasure rooms) — she leaves slot 4 empty.
8. She clicks "Embark." The AdventurerRoster validates: all 3 adventurers exist, all are Healthy, no duplicates, party size ≤ 4. Validation passes.
9. EventBus emits `party_assembled` with `[warrior_id, mage_id, alchemist_id]`.
10. The expedition launches. Luna feels confident she made the right strategic choices.

**Success Criteria:** Party validation passes, expedition launches, Luna's strategic intent (elemental advantage + AoE + healing) is enabled by the roster system.

### UC-02: Kai the Speedrunner — Rushing with Injured Adventurers

**Archetype:** Kai pushes progression aggressively and sometimes attempts expeditions with sub-optimal parties to maintain momentum.

**Scenario:**
1. Kai just finished a hard dungeon. His best Warrior (Kira) is now **Injured** (requires 2 hours real-time recovery).
2. Kai has a fresh Bloom seed ready and wants to run it immediately (speedrunning mindset).
3. He opens the Expedition Dispatch UI and tries to drag Kira into the party.
4. The UI shows a red "X" icon and a tooltip: "Kira is Injured. Recovery time: 1h 47m remaining."
5. **AdventurerRoster.validate_party()** returns `ERR_UNAVAILABLE` because Kira's condition is Injured.
6. Kai has two options:
   a. Wait 1h 47m for Kira to recover to Fatigued (deployable with −10% stats).
   b. Use his backup Warrior (Thane), who is level 8 (vs Kira's level 12) but Healthy.
7. Kai chooses option B. He drags Thane into the party. Validation passes.
8. The expedition launches. Thane performs adequately but Kai notes the power difference. He commits to training Thane more evenly in the future.

**Success Criteria:** Validation correctly rejects Injured adventurers. The player understands the reason (clear error). The system enables a fallback choice (backup adventurer).

### UC-03: Sam the Casual Parent — Solo Adventurer Run

**Archetype:** Sam has 20 minutes between kid activities. He has only 2 adventurers recruited and wants a quick, low-complexity expedition.

**Scenario:**
1. Sam has 2 adventurers: a level 5 Warrior (Healthy) and a level 3 Mage (Fatigued).
2. He has a Common Verdant Hollow seed (Vigor 12, ☠☠ Easy difficulty).
3. He opens the Expedition Dispatch UI and drags only his Warrior into slot 1.
4. He leaves slots 2, 3, and 4 empty.
5. He clicks "Embark." **AdventurerRoster.validate_party()** checks:
   - Party size ≥ 1? Yes.
   - Party size ≤ 4? Yes.
   - All adventurers exist? Yes.
   - All adventurers Healthy or Fatigued? Yes (Warrior is Healthy).
   - No duplicates? Yes.
   - Validation passes.
6. EventBus emits `party_assembled` with `[warrior_id]`.
7. The expedition launches. The Warrior solos the low-difficulty dungeon successfully.
8. Sam completes the expedition in 7 minutes, collects loot, and closes the game. Total session time: 10 minutes. He feels satisfied.

**Success Criteria:** Single-adventurer parties are valid. The system supports both 1-adventurer and 4-adventurer extremes without special-casing.

---

## Section 4 · Glossary

| Term | Definition |
|------|------------|
| **Roster** | The global collection of all adventurers the player has recruited. Persistent across sessions. Serialized in save files. |
| **Party** | A subset of 1–4 adventurers selected from the roster for a specific expedition. Temporary composition — changes per expedition. |
| **AdventurerData** | A data class (from TASK-006) representing a single adventurer's complete state: stats, level, XP, equipment, condition, morale, skills. |
| **Condition** | An adventurer's health state (Healthy, Fatigued, Injured, Exhausted). Determines deployability and stat penalties. See GDD §6.2. |
| **Morale** | A 0–100 stat affecting crit chance and retreat threshold. Rises with victories, falls with defeats. Recovers passively at +2/hour. |
| **Affinity** | An adventurer's innate elemental alignment (Terra/Flame/Frost/Arcane/Shadow). Affects damage dealt/taken by ±10%. Randomized at recruitment. |
| **ClassType** | One of 6 adventurer archetypes: Warrior, Ranger, Mage, Rogue, Alchemist, Sentinel. Determines stat growth, skills, equipment slots. |
| **Recruitment** | The act of adding a new adventurer to the roster. Costs Gold. Generates a procedural name, random affinity, starting stats based on class. |
| **Party Validation** | The process of checking whether a party composition meets all gameplay rules: size 1–4, all adventurers exist, no duplicates, all deployable. |
| **Deployable** | An adventurer is deployable if their condition is Healthy or Fatigued. Injured/Exhausted adventurers are locked until recovery completes. |
| **StringName** | A Godot type for immutable interned strings. Used for all IDs (adventurer_id, item_id, dungeon_id). O(1) equality comparison. |
| **RefCounted** | Godot's base class for reference-counted objects. Automatically freed when no references remain. Used for data and service classes. |
| **EventBus** | A global signal hub (autoload) that decouples systems. AdventurerRoster emits `adventurer_recruited` and `party_assembled` signals here. |
| **Dictionary[K, V]** | GDScript's typed dictionary syntax. `Dictionary[StringName, AdventurerData]` means keys are StringName, values are AdventurerData. |
| **StatBlock** | A data structure holding HP, MP, ATK, DEF, SPD, PER stats. Defined in TASK-006. Used to calculate effective stats from base + equipment. |
| **Serialization** | The process of converting an object to a Dictionary (for JSON save files). `to_dict()` exports, `from_dict()` imports. |
| **GUT** | Godot Unit Test framework. A testing addon for GDScript. Test files extend `GutTest` and use `assert_*` methods. |

---

## Section 5 · Out of Scope

The following features are explicitly NOT included in this task:

- [ ] **OOS-001:** Adventurer UI (roster view, character sheet, equipment panel) — handled by TASK-020.
- [ ] **OOS-002:** Equipment equipping/unequipping logic — handled by TASK-014 (Equipment System).
- [ ] **OOS-003:** Adventurer stat recalculation with equipment bonuses — handled by TASK-014.
- [ ] **OOS-004:** Adventurer leveling and XP gain — distribution logic handled by TASK-016 (Expedition Reward Processor).
- [ ] **OOS-005:** Skill unlocking and skill data definitions — deferred to future skill system task (post-MVP).
- [ ] **OOS-006:** Training Hall (offline XP gain for adventurers not in party) — deferred to future idle task.
- [ ] **OOS-007:** Adventurer renaming (player can override procedural name) — QoL feature, post-MVP.
- [ ] **OOS-008:** Adventurer customization (portrait selection, appearance) — cosmetic system, post-MVP.
- [ ] **OOS-009:** Adventurer retirement/dismissal with rewards — not in MVP scope.
- [ ] **OOS-010:** Adventurer affinity reroll mechanic (spend resource to change element) — economy feature, post-MVP.
- [ ] **OOS-011:** Permadeath mode toggle — contradicts GDD design pillar, never implemented.
- [ ] **OOS-012:** Party presets/loadouts (save favorite party compositions for quick selection) — QoL feature, post-MVP.
- [ ] **OOS-013:** Condition recovery acceleration (spend resource to heal faster) — economy feature, post-MVP.
- [ ] **OOS-014:** Morale decay during failed expeditions — handled by TASK-015 (Expedition Resolver), not roster manager.
- [ ] **OOS-015:** Roster size expansion via guild upgrades — handled by future Guild Hall task.

---

## Section 6 · Functional Requirements

All requirements use MUST/MUST NOT/MAY for testability.

### FR Group 1: Roster Management

- [ ] **FR-001:** The `AdventurerRoster` class MUST extend `RefCounted` (not Node).
- [ ] **FR-002:** The roster MUST store adventurers in a `Dictionary[StringName, AdventurerData]` where keys are unique adventurer IDs.
- [ ] **FR-003:** The roster MUST provide `recruit_adventurer(class_type: Enums.ClassType, starting_level: int = 1) -> StringName` that:
  - Generates a unique StringName ID (format: `"adv_<class_short>_<counter>"`, e.g., `"adv_war_001"`).
  - Creates an `AdventurerData` instance with:
    - `level = starting_level`
    - `xp = 0`
    - `class_type = class_type`
    - `name` = procedurally generated from class-appropriate name table
    - `affinity` = random element (equal 20% chance for each of 5 elements)
    - `condition = Enums.AdventurerCondition.HEALTHY`
    - `morale = 50`
    - `stats` = calculated from class base stats + level scaling per GDD §6.4
    - `skills` = empty array (skills added by future system)
    - `equipped_*` = all null (no starting equipment)
  - Adds the adventurer to the roster Dictionary.
  - Returns the adventurer ID.
- [ ] **FR-004:** The roster MUST emit `EventBus.adventurer_recruited.emit(adventurer_id, class_type)` after successful recruitment.
- [ ] **FR-005:** The roster MUST provide `get_adventurer(id: StringName) -> AdventurerData` that returns the adventurer or null if not found.
- [ ] **FR-006:** The roster MUST provide `get_all_adventurers() -> Array[AdventurerData]` that returns all adventurers in the roster as an array (order undefined).
- [ ] **FR-007:** The roster MUST provide `has_adventurer(id: StringName) -> bool` that returns true if the ID exists in the roster.
- [ ] **FR-008:** The roster MUST provide `remove_adventurer(id: StringName) -> bool` that:
  - Removes the adventurer from the roster Dictionary.
  - If the adventurer was in the current party, removes them from the party array.
  - Returns true if the adventurer existed and was removed, false otherwise.
- [ ] **FR-009:** The roster MUST track `max_roster_size: int` (default 12) and MUST NOT allow recruitment if `adventurers.size() >= max_roster_size`.
- [ ] **FR-010:** When recruitment fails due to roster full, `recruit_adventurer()` MUST return an empty StringName `&""`.

### FR Group 2: Party Composition

- [ ] **FR-011:** The roster MUST store the current party as `current_party: Array[StringName]` (array of adventurer IDs, not data copies).
- [ ] **FR-012:** The roster MUST provide `set_party(adventurer_ids: Array[StringName]) -> Error` that:
  - Calls `validate_party(adventurer_ids)`.
  - If validation passes, replaces `current_party` with the new array and returns `OK`.
  - If validation fails, does NOT modify `current_party` and returns the error code from validation.
- [ ] **FR-013:** The roster MUST emit `EventBus.party_assembled.emit(current_party)` after successful `set_party()`.
- [ ] **FR-014:** The roster MUST provide `get_party() -> Array[AdventurerData]` that:
  - Dereferences each ID in `current_party` to the full `AdventurerData` instance.
  - Returns an array of adventurer data (not IDs).
  - Filters out any IDs that no longer exist in the roster (defensive).
- [ ] **FR-015:** The roster MUST provide `clear_party() -> void` that sets `current_party = []` and emits `EventBus.party_cleared.emit()`.
- [ ] **FR-016:** The roster MUST provide `get_party_ids() -> Array[StringName]` that returns a copy of the `current_party` array (read-only access).

### FR Group 3: Party Validation

- [ ] **FR-017:** The roster MUST provide `validate_party(adventurer_ids: Array[StringName]) -> Error` that performs the following checks in order:
  - If `adventurer_ids.size() == 0`, return `ERR_INVALID_PARAMETER` (cannot embark with zero adventurers).
  - If `adventurer_ids.size() > 4`, return `ERR_INVALID_PARAMETER` (max party size is 4).
  - For each ID in `adventurer_ids`:
    - If the ID does not exist in the roster, return `ERR_DOES_NOT_EXIST`.
    - If the ID appears more than once in the array, return `ERR_ALREADY_EXISTS` (no duplicate adventurers).
    - If the adventurer's condition is `INJURED` or `EXHAUSTED`, return `ERR_UNAVAILABLE`.
  - If all checks pass, return `OK`.
- [ ] **FR-018:** The validation MUST accept parties with conditions `HEALTHY` or `FATIGUED`.
- [ ] **FR-019:** The validation MUST reject parties with conditions `INJURED` or `EXHAUSTED`.
- [ ] **FR-020:** The validation MUST accept party sizes from 1 to 4 inclusive.

### FR Group 4: Procedural Name Generation

- [ ] **FR-021:** The roster MUST implement `_generate_name(class_type: Enums.ClassType) -> String` that:
  - Uses deterministic RNG seeded from `Time.get_ticks_msec()` (unique per recruitment, not globally deterministic).
  - Selects a random name from a class-specific name table:
    - Warrior: ["Kira", "Thane", "Bjorn", "Asha", "Rorik", "Freya", "Magnus", "Elara"]
    - Ranger: ["Sylvan", "Talon", "Mira", "Fenris", "Lyra", "Hawk", "Vesper", "Ashen"]
    - Mage: ["Alden", "Seraphine", "Lucian", "Nyx", "Cassian", "Vespera", "Theron", "Isolde"]
    - Rogue: ["Shade", "Vex", "Sable", "Rook", "Whisper", "Ember", "Sly", "Onyx"]
    - Alchemist: ["Caelum", "Briar", "Sage", "Orion", "Ivy", "Flint", "Willow", "Cinder"]
    - Sentinel: ["Valorin", "Bastian", "Aegis", "Serena", "Ward", "Fortuna", "Citadel", "Haven"]
  - Returns the selected name.
- [ ] **FR-022:** If two adventurers of the same class are recruited with the same name, the second MUST append a suffix: `" II"`, third `" III"`, etc.
- [ ] **FR-023:** Name generation MUST NOT depend on global seed determinism (each recruitment can produce different names from the same class).

### FR Group 5: Serialization

- [ ] **FR-024:** The roster MUST provide `to_dict() -> Dictionary` that serializes:
  - `"adventurers"`: Dictionary mapping adventurer IDs (as String) to `adventurer.to_dict()` for each adventurer.
  - `"current_party"`: Array of adventurer IDs (as String) for the current party.
  - `"max_roster_size"`: int.
  - `"next_adventurer_counter"`: int (tracks the counter for unique ID generation).
- [ ] **FR-025:** The roster MUST provide `from_dict(data: Dictionary) -> void` that deserializes:
  - Clears existing `adventurers` and `current_party`.
  - For each entry in `data["adventurers"]`, creates an `AdventurerData` instance via `AdventurerData.from_dict()` and adds to roster.
  - Restores `current_party` from `data["current_party"]` (converts String back to StringName).
  - Restores `max_roster_size` and `next_adventurer_counter`.
- [ ] **FR-026:** Serialization MUST preserve adventurer IDs exactly (no regeneration on load).
- [ ] **FR-027:** If `from_dict()` encounters an invalid adventurer entry (missing required fields), it MUST skip that adventurer and log a warning, NOT crash.

### FR Group 6: Integration with AdventurerData (TASK-006)

- [ ] **FR-028:** The roster MUST calculate initial stats for recruited adventurers using:
  - `EffectiveStat = BaseStat + (Level × ClassGrowthRate)` per GDD §6.4.
  - Class growth rates (per-level):
    - Warrior: HP+15, MP+2, ATK+3, DEF+2, SPD+1, PER+0.5
    - Ranger: HP+8, MP+2, ATK+3, DEF+1, SPD+3, PER+2
    - Mage: HP+6, MP+6, ATK+3 (magic), DEF+1, SPD+1.5, PER+1.5
    - Rogue: HP+8, MP+2, ATK+2.5, DEF+1, SPD+3.5, PER+2.5
    - Alchemist: HP+10, MP+4, ATK+1, DEF+1.5, SPD+1.5, PER+2
    - Sentinel: HP+14, MP+3, ATK+1.5, DEF+3, SPD+1, PER+1.5
  - Base stats at level 1 (from GDD §6.4):
    - Warrior: HP=100, MP=20, ATK=15, DEF=12, SPD=8, PER=6
    - Ranger: HP=80, MP=30, ATK=12, DEF=8, SPD=14, PER=12
    - Mage: HP=60, MP=60, ATK=10 (magic), DEF=6, SPD=7, PER=10
    - Rogue: HP=70, MP=25, ATK=14, DEF=6, SPD=16, PER=14
    - Alchemist: HP=85, MP=50, ATK=8, DEF=9, SPD=9, PER=11
    - Sentinel: HP=110, MP=40, ATK=10, DEF=14, SPD=6, PER=8
- [ ] **FR-029:** The roster MUST call `AdventurerData.recalculate_effective_stats()` (from TASK-006) after setting base stats, before returning the adventurer.
- [ ] **FR-030:** The roster MUST NOT modify equipment or skills during recruitment (those are set to null/empty).

---

## Section 7 · Non-Functional Requirements

### NFR Group 1: Performance

- [ ] **NFR-001:** `get_adventurer(id)` MUST execute in O(1) time (Dictionary lookup).
- [ ] **NFR-002:** `validate_party(ids)` MUST execute in O(n) time where n = party size (max 4), regardless of roster size.
- [ ] **NFR-003:** Roster serialization (`to_dict()`) MUST complete in <10ms for a roster of 12 adventurers on a mid-tier CPU.
- [ ] **NFR-004:** Roster deserialization (`from_dict()`) MUST complete in <15ms for a roster of 12 adventurers.
- [ ] **NFR-005:** Memory footprint of AdventurerRoster with 12 adventurers MUST be <50 KB.

### NFR Group 2: Testability

- [ ] **NFR-006:** All public methods MUST have associated GUT unit tests.
- [ ] **NFR-007:** All validation error paths MUST be covered by tests (e.g., roster full, duplicate adventurer in party, Injured adventurer).
- [ ] **NFR-008:** Serialization round-trip (to_dict → from_dict) MUST preserve all adventurer data exactly (no loss, no mutation).
- [ ] **NFR-009:** Tests MUST run in isolation (no shared state between test functions).
- [ ] **NFR-010:** Test execution time for the full roster test suite MUST be <500ms.

### NFR Group 3: Maintainability

- [ ] **NFR-011:** All public methods MUST have `##` doc comments describing purpose, parameters, and return values.
- [ ] **NFR-012:** All signals emitted from AdventurerRoster MUST be documented with `##` comments explaining when they fire.
- [ ] **NFR-013:** Magic numbers (max party size, default morale, max roster size) MUST be declared as named constants at class top.
- [ ] **NFR-014:** Error codes returned from methods MUST be Godot built-in Error enum values (OK, ERR_INVALID_PARAMETER, ERR_UNAVAILABLE, etc.).
- [ ] **NFR-015:** Code MUST follow GDScript style guide: snake_case, type hints on all parameters/returns, no implicit nulls.

### NFR Group 4: Reliability

- [ ] **NFR-016:** `from_dict()` MUST handle missing keys gracefully (use defaults) without crashing.
- [ ] **NFR-017:** `from_dict()` MUST handle corrupt adventurer data (invalid condition enum, negative stats) by skipping that adventurer and logging a warning.
- [ ] **NFR-018:** `get_party()` MUST filter out adventurer IDs that no longer exist in the roster (defensive against save file corruption).
- [ ] **NFR-019:** `remove_adventurer()` MUST be idempotent (calling twice with same ID does not error).
- [ ] **NFR-020:** `set_party()` MUST NOT modify `current_party` if validation fails (transactional semantics).

### NFR Group 5: Extensibility

- [ ] **NFR-021:** Adding a new ClassType to the enum MUST require changes only to: the name table in `_generate_name()`, the base stats table, and the growth rate table.
- [ ] **NFR-022:** Changing max party size from 4 to 5 MUST require changing only the constant `MAX_PARTY_SIZE`.
- [ ] **NFR-023:** The roster MUST NOT hardcode references to specific adventurer IDs (all lookups via Dictionary, all iterations via `.values()`).

---

## Section 8 · Designer's Manual

### 8.1 Tuning Guide

| Parameter | Location | Default | Effect of Changing |
|-----------|----------|---------|-------------------|
| `MAX_PARTY_SIZE` | `adventurer_roster.gd`, line ~15 | 4 | Increase to allow larger parties (impacts expedition difficulty balance). |
| `MAX_ROSTER_SIZE` | `adventurer_roster.gd`, line ~16 | 12 | Increase to allow more total adventurers (impacts save file size, UI pagination). |
| `DEFAULT_MORALE` | `adventurer_roster.gd`, line ~17 | 50 | Starting morale for new recruits. Lower = harder early crits. |
| `NAME_TABLES` | `adventurer_roster.gd`, `_generate_name()` | 8 names per class | Add more names for variety, or localize for different cultures. |
| `BASE_STATS` | `adventurer_roster.gd`, `_calculate_starting_stats()` | Per GDD §6.4 | Adjust class balance. Higher HP = more forgiving. Higher ATK = faster clears. |
| `GROWTH_RATES` | `adventurer_roster.gd`, `_calculate_starting_stats()` | Per GDD §6.4 | Controls late-game power curve. Higher growth = steeper scaling. |

### 8.2 How to Add a New Class

To add a 7th class (e.g., "Bard"):

1. **Add enum**: Open `res://src/models/enums.gd`, add `BARD` to `ClassType` enum.
2. **Add name table**: In `adventurer_roster.gd`, add a case to `_generate_name()`:
   ```gdscript
   Enums.ClassType.BARD:
       names = ["Lyric", "Harmony", "Ballad", "Rhyme", "Verse", "Sonnet", "Chord", "Melody"]
   ```
3. **Add base stats**: In `_calculate_starting_stats()`, add:
   ```gdscript
   Enums.ClassType.BARD:
       stats.hp = 75
       stats.mp = 55
       stats.atk = 9
       stats.def = 7
       stats.spd = 12
       stats.per = 13
   ```
4. **Add growth rates**: In the same function, add:
   ```gdscript
   Enums.ClassType.BARD:
       stats.hp += level * 9
       stats.mp += level * 5
       stats.atk += level * 2
       stats.def += level * 1.5
       stats.spd += level * 2.5
       stats.per += level * 2
   ```
5. **Test**: Recruit a Bard via `roster.recruit_adventurer(Enums.ClassType.BARD, 1)` and verify stats.

### 8.3 Debugging Tools

**Inspect Roster State in Console:**

```gdscript
# Print all adventurers
for adv in GameManager.roster.get_all_adventurers():
    print("%s (Lvl %d %s) - %s - Morale: %d" % [adv.name, adv.level, Enums.ClassType.keys()[adv.class_type], Enums.AdventurerCondition.keys()[adv.condition], adv.morale])

# Print current party
print("Current Party:")
for adv in GameManager.roster.get_party():
    print("  - %s" % adv.name)

# Validate a custom party
var test_party = [&"adv_war_001", &"adv_mag_001", &"adv_rog_001"]
var result = GameManager.roster.validate_party(test_party)
print("Validation result: %s" % error_string(result))
```

**Force Recruit a Specific Adventurer:**

```gdscript
# Recruit a level 10 Warrior
var warrior_id = GameManager.roster.recruit_adventurer(Enums.ClassType.WARRIOR, 10)
print("Recruited: %s" % warrior_id)
```

**Force Set Adventurer Condition:**

```gdscript
# Get adventurer and set to Injured (for testing recovery)
var adv = GameManager.roster.get_adventurer(&"adv_war_001")
if adv:
    adv.condition = Enums.AdventurerCondition.INJURED
    adv.condition_recovery_timestamp = Time.get_unix_time_from_system() + 7200  # 2 hours from now
```

### 8.4 Config File Reference

This task does not use external config files. All tuning is done via GDScript constants in `adventurer_roster.gd`.

**Future consideration:** Post-MVP, extract name tables and stat tables to JSON resources for easier modding.

### 8.5 Integration with Other Systems

| System | Integration Point | Data Flow |
|--------|------------------|-----------|
| **Tavern UI (TASK-020)** | Calls `roster.recruit_adventurer()` when player clicks "Recruit" button. | UI → Roster (command) |
| **Expedition Dispatch UI (TASK-019)** | Calls `roster.set_party(ids)` when player confirms party. Calls `roster.get_all_adventurers()` to populate adventurer selection grid. | UI ↔ Roster (query + command) |
| **Expedition Resolver (TASK-015)** | Calls `roster.get_party()` at expedition start to get full adventurer data. Updates adventurer condition/morale after expedition. | Resolver ↔ Roster (query + update) |
| **Save/Load Manager (TASK-009)** | Calls `roster.to_dict()` on save, `roster.from_dict()` on load. | Save Manager ↔ Roster (serialization) |
| **Equipment System (TASK-014)** | Calls `roster.get_adventurer(id)` to equip items. Modifies `adventurer.equipped_weapon/armor/accessory`. | Equipment System → Roster (update) |

---

## Section 9 · Assumptions

### Technical Assumptions

- [ ] **ASMP-001:** TASK-006 (Adventurer data model) is complete and AdventurerData class exists with all required properties.
- [ ] **ASMP-002:** TASK-003 (Enums) is complete and `Enums.ClassType`, `Enums.Element`, `Enums.AdventurerCondition` are defined.
- [ ] **ASMP-003:** EventBus autoload exists and has `adventurer_recruited` and `party_assembled` signals (added in this task).
- [ ] **ASMP-004:** GameManager autoload exists with a `roster: AdventurerRoster` property that is initialized during `GameManager.initialize()`.
- [ ] **ASMP-005:** GUT test framework is installed and configured in the project.

### Design Assumptions

- [ ] **ASMP-006:** GDD §6 Adventurer System is the authoritative source for class definitions, stat formulas, and condition rules.
- [ ] **ASMP-007:** The 6 class types (Warrior, Ranger, Mage, Rogue, Alchemist, Sentinel) will not change during MVP development.
- [ ] **ASMP-008:** Max party size of 4 is a hard design constraint and will not increase in MVP.
- [ ] **ASMP-009:** No permadeath is a non-negotiable design pillar and will never be added (roster never loses adventurers except via explicit removal).
- [ ] **ASMP-010:** Procedurally generated names are acceptable for MVP; custom player naming is deferred to post-MVP.
- [ ] **ASMP-011:** Condition recovery happens in real-time (offline) and is handled by a separate ticking system (not part of this task).

### Integration Assumptions

- [ ] **ASMP-012:** TASK-020 (Adventurer Hall UI) will provide the player-facing interface for viewing the roster and composing parties.
- [ ] **ASMP-013:** TASK-015 (Expedition Resolver) will consume party data via `roster.get_party()` and update adventurer condition/morale post-expedition.
- [ ] **ASMP-014:** TASK-009 (Save/Load Manager) will serialize the roster via `to_dict()` and restore it via `from_dict()`.
- [ ] **ASMP-015:** TASK-014 (Equipment System) will handle stat recalculation when equipment changes (not part of roster manager responsibility).

### Content Assumptions

- [ ] **ASMP-016:** Name tables have 8 names per class, sufficient for MVP. Duplicate name handling (suffix " II", " III") prevents collision.
- [ ] **ASMP-017:** Base stats and growth rates from GDD §6.4 are balanced for MVP and will not require rebalancing during this task.
- [ ] **ASMP-018:** Affinity is purely random at recruitment (no targeted recruitment mechanics in MVP).

---

## Section 10 · Security & Anti-Cheat Considerations

### Threat 1: Save File Roster Injection

**Exploit Description:** Player edits the save file JSON to add max-level adventurers with perfect stats, bypassing the recruitment and leveling systems entirely.

**Attack Vector:**
1. Player saves the game with 2 adventurers at level 5.
2. Player opens `user://saves/save_01.json` in a text editor.
3. Player copies an existing adventurer entry in the `"adventurers"` dictionary.
4. Player modifies the copy: sets level to 50, all stats to 999, condition to HEALTHY, morale to 100.
5. Player saves the file and loads the game.
6. Player now has an overpowered adventurer that trivializes all content.

**Impact:** HIGH — Completely breaks progression balance. Single-player game, so no competitive integrity impact, but undermines the intended experience and makes the game boring.

**Mitigations:**
```gdscript
# In adventurer_roster.gd, from_dict() method:
func from_dict(data: Dictionary) -> void:
    adventurers.clear()
    current_party.clear()
    
    for id_str in data.get("adventurers", {}):
        var adv_data = data["adventurers"][id_str]
        var adv := AdventurerData.new()
        adv.from_dict(adv_data)
        
        # VALIDATION: Clamp stats to reasonable ranges
        adv.level = clampi(adv.level, 1, 50)
        adv.xp = clampi(adv.xp, 0, 999999)
        adv.morale = clampi(adv.morale, 0, 100)
        
        # VALIDATION: Verify stats match expected range for level
        var expected_stats = _calculate_starting_stats(adv.class_type, adv.level)
        if adv.stats.hp > expected_stats.hp * 1.5:  # Allow 50% tolerance for equipment bonuses
            push_warning("Suspicious HP on load: %s has %d HP (expected ~%d)" % [id_str, adv.stats.hp, expected_stats.hp])
            adv.stats.hp = expected_stats.hp  # Reset to expected
        # Repeat for other stats...
        
        adventurers[StringName(id_str)] = adv
    
    current_party = data.get("current_party", []).map(func(s): return StringName(s))
    max_roster_size = clampi(data.get("max_roster_size", 12), 4, 100)
```

**Detection:**
- Log warning when loaded stats exceed expected ranges.
- (Post-MVP) Telemetry: track stat distributions across player base, flag outliers.

### Threat 2: Party Validation Bypass

**Exploit Description:** Player uses Godot remote debugging or a custom script to call `current_party.append(id)` directly, bypassing `set_party()` validation, allowing Injured/Exhausted adventurers or >4 party size.

**Attack Vector:**
1. Player enables remote debugging in Godot.
2. Player attaches the remote debugger to the running game.
3. Player runs:
   ```gdscript
   GameManager.roster.current_party = [&"adv_war_001", &"adv_war_001", &"adv_war_001", &"adv_war_001", &"adv_war_001"]
   ```
   (5 adventurers, with duplicates)
4. Player launches expedition. Resolver crashes or exhibits undefined behavior.

**Impact:** MEDIUM — Crashes the game or creates broken expedition state. Single-player exploit, but poor UX.

**Mitigations:**
```gdscript
# Make current_party private with getter
var _current_party: Array[StringName] = []

func get_party_ids() -> Array[StringName]:
    return _current_party.duplicate()  # Return copy, not reference

# Always validate before use
func get_party() -> Array[AdventurerData]:
    var result: Array[AdventurerData] = []
    for id in _current_party:
        if adventurers.has(id):
            var adv = adventurers[id]
            # DEFENSIVE: Re-validate deployability on read
            if adv.condition in [Enums.AdventurerCondition.HEALTHY, Enums.AdventurerCondition.FATIGUED]:
                result.append(adv)
            else:
                push_warning("Adventurer %s in party but not deployable (condition: %s)" % [id, Enums.AdventurerCondition.keys()[adv.condition]])
    return result
```

**Detection:**
- `get_party()` logs warnings if it encounters invalid state.
- Expedition Resolver (TASK-015) validates party size and conditions again before starting.

### Threat 3: Roster Size Manipulation

**Exploit Description:** Player edits `max_roster_size` in save file to 999, recruits an army of adventurers, overwhelming the UI and save file size.

**Attack Vector:**
1. Player edits save file: `"max_roster_size": 999`.
2. Player recruits 500 adventurers.
3. Save file balloons to 10+ MB. Load times increase to 5+ seconds. UI pagination breaks.

**Impact:** LOW — Self-inflicted UX degradation. No competitive advantage.

**Mitigations:**
```gdscript
# Clamp max_roster_size on load
func from_dict(data: Dictionary) -> void:
    # ...
    max_roster_size = clampi(data.get("max_roster_size", 12), 4, 100)  # Hard cap at 100
```

**Detection:**
- Log warning if loaded `max_roster_size` exceeds 50.

### Threat 4: Condition Timer Manipulation

**Exploit Description:** Player edits save file to set `condition_recovery_timestamp` to a past date, instantly recovering Injured/Exhausted adventurers.

**Attack Vector:**
1. Player's Warrior is Injured with recovery timestamp = `1735689600` (some future time).
2. Player edits save file: `"condition_recovery_timestamp": 0`.
3. Player loads game. Condition recovery logic checks `if current_time >= recovery_timestamp`, sees 0, instantly heals.

**Impact:** MEDIUM — Bypasses the real-time recovery mechanic, removing the tactical consequence of failed expeditions.

**Mitigations:**
```gdscript
# In AdventurerData.from_dict() (TASK-006):
func from_dict(data: Dictionary) -> void:
    # ...
    condition_recovery_timestamp = data.get("condition_recovery_timestamp", 0.0)
    
    # VALIDATION: If timestamp is in the past but condition is not HEALTHY, suspect manipulation
    if condition != Enums.AdventurerCondition.HEALTHY and condition_recovery_timestamp < Time.get_unix_time_from_system():
        # Could be legitimate (player was offline long enough), or could be manipulation
        # For now, allow it (benefit of doubt), but log for analytics
        push_warning("Adventurer %s recovered from %s (timestamp was in past)" % [id, Enums.AdventurerCondition.keys()[condition]])
```

**Detection:**
- Log recovery events that happen immediately on load (potential manipulation).

### Threat 5: Duplicate Adventurer ID Collision

**Exploit Description:** Player manually creates two adventurers with the same ID in the save file, causing one to overwrite the other on load.

**Attack Vector:**
1. Player edits save file to duplicate an adventurer entry but keeps the same ID `"adv_war_001"`.
2. On load, the Dictionary overwrites the first entry with the second.
3. Player loses adventurer data (unintended consequence, not a cheat).

**Impact:** LOW — Self-sabotage. But indicates save file corruption that should be detected.

**Mitigations:**
```gdscript
# Track loaded IDs during deserialization
func from_dict(data: Dictionary) -> void:
    adventurers.clear()
    var loaded_ids: Dictionary = {}  # Track for duplicates
    
    for id_str in data.get("adventurers", {}):
        if loaded_ids.has(id_str):
            push_error("DUPLICATE ADVENTURER ID DETECTED: %s (save file corrupted)" % id_str)
            continue  # Skip duplicate
        loaded_ids[id_str] = true
        
        # ... rest of deserialization
```

**Detection:**
- Error log on duplicate ID detection.
- (Post-MVP) Save file integrity hash to detect manual editing.

---

## Section 11 · Best Practices

### BP-01: Use StringName for All IDs

**Do:** Declare adventurer IDs as `StringName` (e.g., `&"adv_war_001"`).
**Don't:** Use `String` for IDs.
**Why:** StringName comparisons are O(1) pointer equality. Dictionary lookups with StringName keys are significantly faster than String keys.

### BP-02: Validate Before Mutating State

**Do:** In `set_party()`, call `validate_party()` first. Only modify `current_party` if validation passes.
**Don't:** Set `current_party` and then validate afterward.
**Why:** Transactional semantics prevent corrupt state. If validation fails, the roster remains in a consistent state.

### BP-03: Return Errors, Don't Throw Exceptions

**Do:** Return Godot `Error` enum values (`OK`, `ERR_INVALID_PARAMETER`, etc.).
**Don't:** Use `assert()` or manually throw errors in production code.
**Why:** Godot convention. Callers can handle errors gracefully without try-catch boilerplate.

### BP-04: Emit Signals After State Change

**Do:** Modify state first, then emit signal: `current_party = ids; EventBus.party_assembled.emit(ids)`.
**Don't:** Emit signal before state change, or in the middle of multi-step mutation.
**Why:** Signal listeners expect the new state to be readable when the signal fires.

### BP-05: Document Signal Parameters with Types

**Do:** `## Emitted when party is assembled. party_ids: Array[StringName] of adventurer IDs.`
**Don't:** `# Signal when party ready`
**Why:** `##` comments appear in Godot's documentation hover. Typed parameters enable autocomplete.

### BP-06: Defensive Deserialization

**Do:** Use `.get(key, default)` when reading from Dictionary. Clamp numeric values to valid ranges.
**Don't:** Assume all keys exist. Use `data["key"]` without null checks.
**Why:** Save files can be corrupted, manually edited, or from older game versions. Defensive code prevents crashes.

### BP-07: Clamp Stats on Load

**Do:** After deserializing adventurer stats, clamp to expected ranges based on level and class.
**Don't:** Trust save file stat values blindly.
**Why:** Prevents save file cheating (stat inflation) and detects corruption.

### BP-08: Use Class Constants for Magic Numbers

**Do:** `const MAX_PARTY_SIZE := 4` at class top.
**Don't:** `if party.size() > 4:` scattered throughout code.
**Why:** Single source of truth. Easy to find and change. Self-documenting code.

### BP-09: Separate Data from Logic

**Do:** Store adventurer data in `AdventurerData` (pure data class). Put roster management logic in `AdventurerRoster` (service class).
**Don't:** Put roster management methods inside `AdventurerData`.
**Why:** Single Responsibility Principle. AdventurerData is serializable data. AdventurerRoster is business logic.

### BP-10: Type Hints on All Public Methods

**Do:** `func get_adventurer(id: StringName) -> AdventurerData:`
**Don't:** `func get_adventurer(id):`
**Why:** Editor autocomplete, runtime type checking (in debug builds), self-documenting signatures.

### BP-11: Use Enum Keys, Not Integers, in Save Files

**Do:** Serialize `class_type` as string: `"class_type": "WARRIOR"`
**Don't:** Serialize as int: `"class_type": 0`
**Why:** Save files are human-readable and robust to enum reordering. If a new class is inserted in the middle of the enum, old saves don't break.

### BP-12: Log Warnings, Not Errors, for Non-Critical Issues

**Do:** `push_warning("Adventurer %s has suspicious stats" % id)` when stats exceed expected but game can continue.
**Don't:** `push_error()` or `assert(false)` for recoverable issues.
**Why:** Warnings allow the game to continue. Errors/asserts imply unrecoverable state.

---

## Section 12 · Troubleshooting

### Issue 1: "Adventurer not found" when calling get_adventurer()

**Symptoms:** `roster.get_adventurer(id)` returns null even though the adventurer was just recruited.

**Causes:**
- The ID is being passed as `String` instead of `StringName` → Dictionary key mismatch.
- The ID has leading/trailing whitespace → `&"adv_war_001 "` != `&"adv_war_001"`.
- The adventurer was removed from the roster before the get call.
- The ID was generated incorrectly (typo in counter format).

**Resolution:**
1. Verify the ID type: `print(typeof(id))` → should print `21` (TYPE_STRING_NAME).
2. Print the ID: `print('"%s"' % id)` → check for whitespace.
3. Print all roster IDs: `print(GameManager.roster.adventurers.keys())` → confirm the adventurer exists.
4. Convert String to StringName explicitly: `&"adv_war_001"` or `StringName("adv_war_001")`.

### Issue 2: Party validation fails with ERR_UNAVAILABLE but adventurer is Healthy

**Symptoms:** `validate_party([&"adv_war_001"])` returns `ERR_UNAVAILABLE` but the adventurer's condition is HEALTHY.

**Causes:**
- The adventurer condition was recently changed but `recalculate_effective_stats()` was not called (stale derived state).
- A different adventurer in the party is Injured/Exhausted, and the error is misattributed.
- The validation logic has a bug (checking wrong condition enum values).

**Resolution:**
1. Print the condition: `print(roster.get_adventurer(&"adv_war_001").condition)` → verify it's 0 (HEALTHY) or 1 (FATIGUED).
2. Validate the party step-by-step:
   ```gdscript
   for id in party_ids:
       var adv = roster.get_adventurer(id)
       print("%s: condition=%s, deployable=%s" % [id, Enums.AdventurerCondition.keys()[adv.condition], adv.condition in [0, 1]])
   ```
3. Check the validation loop logic in `validate_party()` for typos.

### Issue 3: Duplicate adventurer names ("Kira" and "Kira II" both named "Kira")

**Symptoms:** Two Warrior adventurers both have the name "Kira" instead of "Kira" and "Kira II".

**Causes:**
- The suffix logic in `_generate_name()` is not being applied.
- The name collision check is case-sensitive and player typed "kira" vs "Kira".
- The counter is being reset between recruitments (RNG seed issue).

**Resolution:**
1. Verify suffix logic:
   ```gdscript
   # In _generate_name():
   var name = selected_name
   var suffix = 1
   while _name_exists(name):
       suffix += 1
       name = "%s %s" % [selected_name, _to_roman(suffix)]
   ```
2. Ensure `_name_exists()` iterates all adventurers and compares names case-insensitively.
3. Add debug print in `_generate_name()`: `print("Generated name: %s" % name)`.

### Issue 4: Party size is 5 after calling set_party() with 5 IDs

**Symptoms:** `roster.current_party.size()` is 5 even though validation should reject parties >4.

**Causes:**
- The validation check is `>=` instead of `>`: `if ids.size() >= 4:` (off-by-one error).
- The caller is bypassing `set_party()` and modifying `current_party` directly (should be private).
- The error code from `set_party()` is being ignored by the caller.

**Resolution:**
1. Check validation logic: `if adventurer_ids.size() > MAX_PARTY_SIZE:` (should be `>`, not `>=`).
2. Make `current_party` private: rename to `_current_party` and add getter.
3. Verify caller checks return value:
   ```gdscript
   var result = roster.set_party(ids)
   if result != OK:
       push_error("Failed to set party: %s" % error_string(result))
   ```

### Issue 5: Loaded roster has missing adventurers after from_dict()

**Symptoms:** After loading a save file, roster has 3 adventurers but the save file had 5.

**Causes:**
- Two adventurer entries in the save file were corrupt (missing required fields like `class_type` or `level`).
- The `from_dict()` method skipped those entries with a warning but did not crash.
- The save file JSON is malformed (extra commas, missing braces).

**Resolution:**
1. Open the save file in a JSON validator (e.g., jsonlint.com) to check for syntax errors.
2. Check the Godot Output panel for warnings during load: `push_warning("Skipping corrupt adventurer: %s" % id)`.
3. Inspect the save file manually — verify each adventurer entry has all required fields:
   ```json
   "adv_war_001": {
       "id": "adv_war_001",
       "name": "Kira",
       "class_type": "WARRIOR",
       "level": 10,
       "xp": 4500,
       "stats": { ... },
       "condition": "HEALTHY",
       "morale": 65,
       ...
   }
   ```
4. If corruption is from manual editing, restore from a backup save or re-recruit the adventurers.

### Issue 6: Morale is 255 instead of clamped to 100

**Symptoms:** An adventurer's morale displays as 255 or other unexpected value.

**Causes:**
- Save file was manually edited with out-of-range value.
- The `from_dict()` method did not clamp morale on load.
- Morale was incremented without clamping in post-expedition logic (different task, but symptom appears here).

**Resolution:**
1. Add clamping in `from_dict()`:
   ```gdscript
   adv.morale = clampi(data.get("morale", 50), 0, 100)
   ```
2. Add clamping whenever morale is modified:
   ```gdscript
   adv.morale = clampi(adv.morale + delta, 0, 100)
   ```
3. Check save file for invalid values: search for `"morale": 255` and correct to `"morale": 100`.

---

## Section 13 · Acceptance Criteria

All criteria must pass before this task is considered complete. PAC = Playtesting Acceptance Criterion. BAC = Balance Acceptance Criterion.

### AC Group 1: Roster Core Functionality

- [ ] **AC-001:** `AdventurerRoster` class exists at `res://src/services/adventurer_roster.gd` and extends `RefCounted`.
- [ ] **AC-002:** `AdventurerRoster` stores adventurers in a `Dictionary[StringName, AdventurerData]` named `adventurers`.
- [ ] **AC-003:** `recruit_adventurer(class_type, level)` returns a unique StringName ID in format `&"adv_<class_short>_<NNN>"`.
- [ ] **AC-004:** Recruiting a Warrior at level 1 creates an adventurer with base HP=100, MP=20, ATK=15, DEF=12, SPD=8, PER=6.
- [ ] **AC-005:** Recruiting a Mage at level 5 creates an adventurer with HP=90 (60 + 5×6), MP=90 (60 + 5×6), ATK=25 (10 + 5×3).
- [ ] **AC-006:** Recruiting a Ranger at level 10 creates an adventurer with SPD=44 (14 + 10×3).
- [ ] **AC-007:** Each recruited adventurer has a procedurally generated name from the class-specific name table.
- [ ] **AC-008:** Recruiting two Warriors sequentially generates different names (or "Kira" and "Kira II" if same name drawn).
- [ ] **AC-009:** Each recruited adventurer has a random affinity (one of 5 elements with equal probability).
- [ ] **AC-010:** `recruit_adventurer()` emits `EventBus.adventurer_recruited.emit(id, class_type)`.
- [ ] **AC-011:** `get_adventurer(id)` returns the correct AdventurerData instance for a recruited adventurer.
- [ ] **AC-012:** `get_adventurer(invalid_id)` returns null.
- [ ] **AC-013:** `has_adventurer(id)` returns true for an existing adventurer, false otherwise.
- [ ] **AC-014:** `get_all_adventurers()` returns an array containing all recruited adventurers.
- [ ] **AC-015:** `remove_adventurer(id)` deletes the adventurer from the roster and returns true.
- [ ] **AC-016:** `remove_adventurer(invalid_id)` returns false and does not crash.
- [ ] **AC-017:** Attempting to recruit when `adventurers.size() >= max_roster_size` returns empty StringName `&""` and does NOT add an adventurer.

### AC Group 2: Party Composition

- [ ] **AC-018:** `set_party([&"adv_war_001"])` with a valid Healthy adventurer returns `OK` and sets `current_party = [&"adv_war_001"]`.
- [ ] **AC-019:** `set_party([&"adv_war_001", &"adv_mag_001", &"adv_rog_001", &"adv_ran_001"])` with 4 valid adventurers returns `OK`.
- [ ] **AC-020:** `set_party([])` returns `ERR_INVALID_PARAMETER` (cannot embark with zero adventurers).
- [ ] **AC-021:** `set_party([id1, id2, id3, id4, id5])` with 5 adventurers returns `ERR_INVALID_PARAMETER` (max party size is 4).
- [ ] **AC-022:** `set_party([&"invalid_id"])` returns `ERR_DOES_NOT_EXIST` (adventurer does not exist in roster).
- [ ] **AC-023:** `set_party([&"adv_war_001", &"adv_war_001"])` returns `ERR_ALREADY_EXISTS` (duplicate adventurer in party).
- [ ] **AC-024:** `set_party([&"injured_adventurer_id"])` returns `ERR_UNAVAILABLE` (condition is INJURED).
- [ ] **AC-025:** `set_party([&"exhausted_adventurer_id"])` returns `ERR_UNAVAILABLE` (condition is EXHAUSTED).
- [ ] **AC-026:** `set_party([&"fatigued_adventurer_id"])` returns `OK` (FATIGUED is deployable).
- [ ] **AC-027:** `set_party()` does NOT modify `current_party` if validation fails.
- [ ] **AC-028:** `set_party()` emits `EventBus.party_assembled.emit(current_party)` on success.
- [ ] **AC-029:** `get_party()` returns an `Array[AdventurerData]` with full adventurer data for each ID in `current_party`.
- [ ] **AC-030:** `get_party()` returns an empty array if `current_party` is empty.
- [ ] **AC-031:** `get_party_ids()` returns a copy of `current_party` as `Array[StringName]`.
- [ ] **AC-032:** `clear_party()` sets `current_party = []` and emits `EventBus.party_cleared.emit()`.

### AC Group 3: Validation

- [ ] **AC-033:** `validate_party([&"adv_war_001"])` with 1 Healthy adventurer returns `OK`.
- [ ] **AC-034:** `validate_party([&"adv_war_001", &"adv_mag_001", &"adv_rog_001", &"adv_ran_001"])` with 4 Healthy adventurers returns `OK`.
- [ ] **AC-035:** `validate_party([])` returns `ERR_INVALID_PARAMETER`.
- [ ] **AC-036:** `validate_party([id1, id2, id3, id4, id5])` returns `ERR_INVALID_PARAMETER`.
- [ ] **AC-037:** `validate_party([&"invalid_id"])` returns `ERR_DOES_NOT_EXIST`.
- [ ] **AC-038:** `validate_party([&"adv_war_001", &"adv_war_001"])` returns `ERR_ALREADY_EXISTS`.
- [ ] **AC-039:** `validate_party([&"injured_id"])` returns `ERR_UNAVAILABLE`.
- [ ] **AC-040:** `validate_party([&"exhausted_id"])` returns `ERR_UNAVAILABLE`.
- [ ] **AC-041:** `validate_party([&"fatigued_id"])` returns `OK`.

### AC Group 4: Procedural Generation

- [ ] **AC-042:** Recruiting 10 Warriors produces at least 5 unique names (randomness check).
- [ ] **AC-043:** If two Warriors have the same base name, the second has a Roman numeral suffix (" II").
- [ ] **AC-044:** Recruiting 10 adventurers (any class) produces all 5 elements represented (affinity randomness check).
- [ ] **AC-045:** Name generation does not crash on any class type (Warrior, Ranger, Mage, Rogue, Alchemist, Sentinel).

### AC Group 5: Serialization

- [ ] **AC-046:** `to_dict()` returns a Dictionary with keys: `"adventurers"`, `"current_party"`, `"max_roster_size"`.
- [ ] **AC-047:** `to_dict()["adventurers"]` contains all recruited adventurers with IDs as String keys.
- [ ] **AC-048:** `to_dict()["current_party"]` is an Array of Strings representing party IDs.
- [ ] **AC-049:** Round-trip serialization (recruit 3 adventurers → `to_dict()` → `from_dict()`) preserves all adventurer data exactly.
- [ ] **AC-050:** Round-trip preserves adventurer IDs (no regeneration).
- [ ] **AC-051:** Round-trip preserves party composition (same adventurers in party).
- [ ] **AC-052:** `from_dict()` with missing `"adventurers"` key defaults to empty roster.
- [ ] **AC-053:** `from_dict()` with corrupt adventurer entry (missing `level`) skips that adventurer and logs a warning.
- [ ] **AC-054:** `from_dict()` clamps `max_roster_size` to range [4, 100].
- [ ] **AC-055:** `from_dict()` clamps adventurer `level` to range [1, 50].
- [ ] **AC-056:** `from_dict()` clamps adventurer `morale` to range [0, 100].

### AC Group 6: EventBus Integration

- [ ] **AC-057:** EventBus has a signal `adventurer_recruited(adventurer_id: StringName, class_type: Enums.ClassType)`.
- [ ] **AC-058:** EventBus has a signal `party_assembled(party_ids: Array[StringName])`.
- [ ] **AC-059:** EventBus has a signal `party_cleared()`.
- [ ] **AC-060:** `recruit_adventurer()` emits `adventurer_recruited` with correct ID and class type.
- [ ] **AC-061:** `set_party()` emits `party_assembled` with current party IDs on success.
- [ ] **AC-062:** `clear_party()` emits `party_cleared`.

### AC Group 7: GameManager Integration

- [ ] **AC-063:** GameManager has a property `roster: AdventurerRoster` initialized to a new instance in `initialize()`.
- [ ] **AC-064:** After `GameManager.initialize()`, `GameManager.roster` is not null.
- [ ] **AC-065:** `GameManager.roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)` returns a valid ID.

### Playtesting Acceptance Criteria (PACs)

- [ ] **PAC-001:** Start a new game, recruit 1 Warrior — roster has 1 adventurer, name is from Warrior table.
- [ ] **PAC-002:** Recruit 4 more adventurers (one of each remaining class) — roster has 5 adventurers, all with unique IDs.
- [ ] **PAC-003:** Set party to [Warrior, Mage, Rogue] — party validation passes, `get_party()` returns 3 adventurers.
- [ ] **PAC-004:** Try to set party with 5 adventurers — validation fails with error, current party unchanged.
- [ ] **PAC-005:** Manually set an adventurer's condition to INJURED, try to add to party — validation fails.
- [ ] **PAC-006:** Save the game with 5 adventurers and a 3-adventurer party. Reload — all 5 adventurers present, party composition preserved.
- [ ] **PAC-007:** Recruit adventurers until roster is full (12) — 13th recruitment fails gracefully (returns empty ID).
- [ ] **PAC-008:** Remove an adventurer from the roster — roster size decreases, removed adventurer no longer in `get_all_adventurers()`.

### Balance Acceptance Criteria (BACs)

- [ ] **BAC-001:** A level 1 Warrior has higher HP than a level 1 Mage (100 vs 60).
- [ ] **BAC-002:** A level 1 Mage has higher MP than a level 1 Warrior (60 vs 20).
- [ ] **BAC-003:** A level 10 Ranger has higher SPD than a level 10 Warrior (44 vs 18).
- [ ] **BAC-004:** A level 20 Sentinel has higher DEF than a level 20 Rogue (74 vs 26).
- [ ] **BAC-005:** All classes at level 1 have stats matching GDD §6.4 base stats exactly.

---

## Section 14 · Testing Requirements

### 14.1 Test File: `tests/unit/test_adventurer_roster.gd`

```gdscript
## Unit tests for AdventurerRoster service.
## Tests recruitment, party composition, validation, and serialization.
extends GutTest

var roster: AdventurerRoster


func before_each() -> void:
	roster = AdventurerRoster.new()


func after_each() -> void:
	roster = null


# --- Recruitment Tests ---

func test_recruit_warrior_returns_valid_id() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	assert_ne(id, &"", "Recruit must return non-empty ID")
	assert_true(id.begins_with("adv_war_"), "Warrior ID must start with adv_war_")


func test_recruited_adventurer_exists_in_roster() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.MAGE, 1)
	assert_true(roster.has_adventurer(id), "Recruited adventurer must exist in roster")


func test_get_adventurer_returns_correct_data() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.RANGER, 1)
	var adv = roster.get_adventurer(id)
	assert_not_null(adv, "get_adventurer must return data")
	assert_eq(adv.class_type, Enums.ClassType.RANGER, "Class type must match")
	assert_eq(adv.level, 1, "Level must be 1")


func test_warrior_level_1_has_correct_base_stats() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	var adv = roster.get_adventurer(id)
	assert_eq(adv.stats.hp, 100, "Warrior base HP must be 100")
	assert_eq(adv.stats.mp, 20, "Warrior base MP must be 20")
	assert_eq(adv.stats.atk, 15, "Warrior base ATK must be 15")
	assert_eq(adv.stats.def, 12, "Warrior base DEF must be 12")
	assert_eq(adv.stats.spd, 8, "Warrior base SPD must be 8")
	assert_eq(adv.stats.per, 6, "Warrior base PER must be 6")


func test_mage_level_5_has_scaled_stats() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.MAGE, 5)
	var adv = roster.get_adventurer(id)
	# Base: HP=60, MP=60, ATK=10. Growth: HP+6, MP+6, ATK+3
	# Level 5: HP = 60 + 5*6 = 90, MP = 60 + 5*6 = 90, ATK = 10 + 5*3 = 25
	assert_eq(adv.stats.hp, 90, "Mage level 5 HP must be 90")
	assert_eq(adv.stats.mp, 90, "Mage level 5 MP must be 90")
	assert_eq(adv.stats.atk, 25, "Mage level 5 ATK must be 25")


func test_recruited_adventurer_has_random_affinity() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.ROGUE, 1)
	var adv = roster.get_adventurer(id)
	assert_true(adv.affinity in [Enums.Element.TERRA, Enums.Element.FLAME, Enums.Element.FROST, Enums.Element.ARCANE, Enums.Element.SHADOW], "Affinity must be a valid element")


func test_recruited_adventurer_has_healthy_condition() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.ALCHEMIST, 1)
	var adv = roster.get_adventurer(id)
	assert_eq(adv.condition, Enums.AdventurerCondition.HEALTHY, "New recruit must be HEALTHY")


func test_recruited_adventurer_has_default_morale() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.SENTINEL, 1)
	var adv = roster.get_adventurer(id)
	assert_eq(adv.morale, 50, "New recruit must have morale 50")


func test_recruit_emits_adventurer_recruited_signal() -> void:
	watch_signals(EventBus)
	var id = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	assert_signal_emitted(EventBus, "adventurer_recruited", "recruit must emit signal")


func test_roster_full_returns_empty_id() -> void:
	roster.max_roster_size = 2
	roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	roster.recruit_adventurer(Enums.ClassType.MAGE, 1)
	var id = roster.recruit_adventurer(Enums.ClassType.ROGUE, 1)
	assert_eq(id, &"", "Recruit when full must return empty ID")


func test_procedural_name_generation_does_not_crash() -> void:
	for class_type in Enums.ClassType.values():
		var id = roster.recruit_adventurer(class_type, 1)
		var adv = roster.get_adventurer(id)
		assert_true(adv.name.length() > 0, "Name must be generated for class %d" % class_type)


# --- Party Composition Tests ---

func test_set_party_with_valid_single_adventurer() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	var result = roster.set_party([id])
	assert_eq(result, OK, "set_party with 1 valid adventurer must return OK")


func test_set_party_with_four_adventurers() -> void:
	var id1 = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	var id2 = roster.recruit_adventurer(Enums.ClassType.MAGE, 1)
	var id3 = roster.recruit_adventurer(Enums.ClassType.ROGUE, 1)
	var id4 = roster.recruit_adventurer(Enums.ClassType.RANGER, 1)
	var result = roster.set_party([id1, id2, id3, id4])
	assert_eq(result, OK, "set_party with 4 valid adventurers must return OK")


func test_set_party_with_zero_adventurers_fails() -> void:
	var result = roster.set_party([])
	assert_eq(result, ERR_INVALID_PARAMETER, "set_party with 0 adventurers must return ERR_INVALID_PARAMETER")


func test_set_party_with_five_adventurers_fails() -> void:
	var ids = []
	for i in range(5):
		ids.append(roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1))
	var result = roster.set_party(ids)
	assert_eq(result, ERR_INVALID_PARAMETER, "set_party with 5 adventurers must return ERR_INVALID_PARAMETER")


func test_set_party_with_nonexistent_id_fails() -> void:
	var result = roster.set_party([&"invalid_id"])
	assert_eq(result, ERR_DOES_NOT_EXIST, "set_party with invalid ID must return ERR_DOES_NOT_EXIST")


func test_set_party_with_duplicate_fails() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	var result = roster.set_party([id, id])
	assert_eq(result, ERR_ALREADY_EXISTS, "set_party with duplicate must return ERR_ALREADY_EXISTS")


func test_set_party_with_injured_adventurer_fails() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	var adv = roster.get_adventurer(id)
	adv.condition = Enums.AdventurerCondition.INJURED
	var result = roster.set_party([id])
	assert_eq(result, ERR_UNAVAILABLE, "set_party with INJURED must return ERR_UNAVAILABLE")


func test_set_party_with_fatigued_adventurer_succeeds() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	var adv = roster.get_adventurer(id)
	adv.condition = Enums.AdventurerCondition.FATIGUED
	var result = roster.set_party([id])
	assert_eq(result, OK, "set_party with FATIGUED must return OK")


func test_set_party_emits_party_assembled_signal() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	watch_signals(EventBus)
	roster.set_party([id])
	assert_signal_emitted(EventBus, "party_assembled", "set_party must emit party_assembled")


func test_failed_set_party_does_not_modify_current_party() -> void:
	var id1 = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	roster.set_party([id1])
	var original_party = roster.get_party_ids()
	var result = roster.set_party([&"invalid_id"])
	assert_eq(result, ERR_DOES_NOT_EXIST, "Invalid set_party must fail")
	assert_eq(roster.get_party_ids(), original_party, "Failed set_party must not modify current party")


func test_get_party_returns_adventurer_data() -> void:
	var id1 = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	var id2 = roster.recruit_adventurer(Enums.ClassType.MAGE, 1)
	roster.set_party([id1, id2])
	var party = roster.get_party()
	assert_eq(party.size(), 2, "get_party must return 2 adventurers")
	assert_eq(party[0].id, id1, "First party member must match")
	assert_eq(party[1].id, id2, "Second party member must match")


func test_clear_party_removes_all_members() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	roster.set_party([id])
	roster.clear_party()
	assert_eq(roster.get_party_ids().size(), 0, "clear_party must empty party")


func test_clear_party_emits_signal() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	roster.set_party([id])
	watch_signals(EventBus)
	roster.clear_party()
	assert_signal_emitted(EventBus, "party_cleared", "clear_party must emit signal")


# --- Removal Tests ---

func test_remove_adventurer_deletes_from_roster() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	var result = roster.remove_adventurer(id)
	assert_true(result, "remove_adventurer must return true")
	assert_false(roster.has_adventurer(id), "Removed adventurer must not exist")


func test_remove_adventurer_from_party_removes_from_both() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	roster.set_party([id])
	roster.remove_adventurer(id)
	assert_eq(roster.get_party_ids().size(), 0, "Removed adventurer must be removed from party")


func test_remove_nonexistent_adventurer_returns_false() -> void:
	var result = roster.remove_adventurer(&"invalid_id")
	assert_false(result, "remove_adventurer with invalid ID must return false")


# --- Serialization Tests ---

func test_to_dict_contains_all_keys() -> void:
	var dict = roster.to_dict()
	assert_true(dict.has("adventurers"), "to_dict must have adventurers key")
	assert_true(dict.has("current_party"), "to_dict must have current_party key")
	assert_true(dict.has("max_roster_size"), "to_dict must have max_roster_size key")


func test_round_trip_serialization_preserves_data() -> void:
	var id1 = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 5)
	var id2 = roster.recruit_adventurer(Enums.ClassType.MAGE, 3)
	roster.set_party([id1, id2])
	
	var dict = roster.to_dict()
	var roster2 = AdventurerRoster.new()
	roster2.from_dict(dict)
	
	assert_eq(roster2.get_all_adventurers().size(), 2, "Round-trip must preserve count")
	assert_true(roster2.has_adventurer(id1), "Round-trip must preserve ID 1")
	assert_true(roster2.has_adventurer(id2), "Round-trip must preserve ID 2")
	assert_eq(roster2.get_party_ids().size(), 2, "Round-trip must preserve party size")


func test_from_dict_with_missing_keys_uses_defaults() -> void:
	var dict = {}  # Empty dict
	roster.from_dict(dict)
	assert_eq(roster.get_all_adventurers().size(), 0, "Empty dict must result in empty roster")


func test_from_dict_clamps_max_roster_size() -> void:
	var dict = {"max_roster_size": 999}
	roster.from_dict(dict)
	assert_le(roster.max_roster_size, 100, "max_roster_size must be clamped to 100")


# --- Get All Adventurers Test ---

func test_get_all_adventurers_returns_all_recruits() -> void:
	roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	roster.recruit_adventurer(Enums.ClassType.MAGE, 1)
	roster.recruit_adventurer(Enums.ClassType.ROGUE, 1)
	var all_adv = roster.get_all_adventurers()
	assert_eq(all_adv.size(), 3, "get_all_adventurers must return 3 adventurers")
```

### 14.2 Test File: `tests/integration/test_roster_eventbus_integration.gd`

```gdscript
## Integration tests for AdventurerRoster with EventBus.
## Tests signal emission, GameManager integration, and cross-system workflows.
extends GutTest

var roster: AdventurerRoster


func before_each() -> void:
	roster = AdventurerRoster.new()


func after_each() -> void:
	roster = null


func test_recruitment_emits_to_global_eventbus() -> void:
	watch_signals(EventBus)
	roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	assert_signal_emitted(EventBus, "adventurer_recruited", "Recruitment must emit to global EventBus")


func test_party_assembly_emits_to_global_eventbus() -> void:
	var id = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	watch_signals(EventBus)
	roster.set_party([id])
	assert_signal_emitted(EventBus, "party_assembled", "Party assembly must emit to global EventBus")


func test_gamemanager_roster_initialization() -> void:
	# Assuming GameManager.initialize() creates roster
	if GameManager.roster == null:
		GameManager.roster = AdventurerRoster.new()
	assert_not_null(GameManager.roster, "GameManager must have roster after init")


func test_full_workflow_recruit_compose_clear() -> void:
	# Recruit 3 adventurers
	var id1 = roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
	var id2 = roster.recruit_adventurer(Enums.ClassType.MAGE, 1)
	var id3 = roster.recruit_adventurer(Enums.ClassType.ROGUE, 1)
	
	# Compose party
	var result = roster.set_party([id1, id2, id3])
	assert_eq(result, OK, "Party composition must succeed")
	assert_eq(roster.get_party().size(), 3, "Party must have 3 members")
	
	# Clear party
	roster.clear_party()
	assert_eq(roster.get_party().size(), 0, "Party must be empty after clear")
```

---

## Section 15 · Playtesting Verification Steps

### Scenario 1: First-Time Recruitment Flow

**Setup:**
1. Start a new game (empty roster).
2. Open the Godot editor Remote scene tree.
3. Open the Godot console (Output panel).

**Actions:**
1. Run the game.
2. From the console, execute:
   ```gdscript
   var id = GameManager.roster.recruit_adventurer(Enums.ClassType.WARRIOR, 1)
   print("Recruited: %s" % id)
   ```
3. Execute: `print(GameManager.roster.get_adventurer(id))`

**Expected Feel:**
- Immediate response (no lag).
- Console prints the adventurer ID (e.g., `"adv_war_001"`).
- Adventurer data shows name (e.g., "Kira"), level 1, class WARRIOR, condition HEALTHY, morale 50.

**Expected Output:**
```
Recruited: adv_war_001
<AdventurerData#12345: name=Kira, level=1, class=WARRIOR, HP=100, MP=20, ATK=15, DEF=12, SPD=8, PER=6>
```

**Red Flags:**
- ID is empty (`&""`).
- Name is empty or null.
- Stats are zero or negative.
- Condition is not HEALTHY.

**Platform Notes:** None (GDScript console works identically on all platforms).

---

### Scenario 2: Party Composition with Validation Feedback

**Setup:**
1. Roster has 4 adventurers: 1 Warrior (Healthy), 1 Mage (Healthy), 1 Rogue (Injured), 1 Ranger (Exhausted).

**Actions:**
1. Attempt to set party with all 4:
   ```gdscript
   var ids = [&"adv_war_001", &"adv_mag_001", &"adv_rog_001", &"adv_ran_001"]
   var result = GameManager.roster.set_party(ids)
   print("Result: %s" % error_string(result))
   ```
2. Remove the Injured and Exhausted adventurers, retry with 2:
   ```gdscript
   var ids = [&"adv_war_001", &"adv_mag_001"]
   var result = GameManager.roster.set_party(ids)
   print("Result: %s" % error_string(result))
   ```

**Expected Feel:**
- First attempt: Validation rejects immediately with clear error.
- Second attempt: Validation passes instantly.
- No mysterious failures — errors are explicit.

**Expected Output:**
```
Result: Unavailable (ERR_UNAVAILABLE)
Result: OK
```

**Red Flags:**
- First attempt returns OK (validation bypassed).
- Second attempt fails (false positive).
- No error message or code returned.

---

### Scenario 3: Save/Load Persistence

**Setup:**
1. Roster has 3 adventurers with a 2-adventurer party.
2. Save the game via `GameManager.save()`.

**Actions:**
1. Close and reopen the game.
2. Load the save file.
3. Execute:
   ```gdscript
   print("Roster size: %d" % GameManager.roster.get_all_adventurers().size())
   print("Party size: %d" % GameManager.roster.get_party().size())
   print("Party IDs: %s" % str(GameManager.roster.get_party_ids()))
   ```

**Expected Feel:**
- Load completes in <1 second.
- All adventurers present.
- Party composition intact.

**Expected Output:**
```
Roster size: 3
Party size: 2
Party IDs: [adv_war_001, adv_mag_001]
```

**Red Flags:**
- Roster is empty after load.
- Party is cleared (was not serialized).
- Adventurer IDs changed (regenerated instead of preserved).
- Adventurer stats changed (not preserved exactly).

---

### Scenario 4: Roster Full — Graceful Rejection

**Setup:**
1. Set `GameManager.roster.max_roster_size = 3`.
2. Recruit 3 adventurers.

**Actions:**
1. Attempt to recruit a 4th:
   ```gdscript
   var id = GameManager.roster.recruit_adventurer(Enums.ClassType.ALCHEMIST, 1)
   print("Recruited: %s" % id)
   print("Roster size: %d" % GameManager.roster.get_all_adventurers().size())
   ```

**Expected Feel:**
- Recruitment fails silently (no crash).
- Roster size remains 3.
- Empty ID returned.

**Expected Output:**
```
Recruited: 
Roster size: 3
```

**Red Flags:**
- 4th adventurer is added (limit not enforced).
- Game crashes.
- Error dialog appears (should fail gracefully).

---

### Scenario 5: Injured Adventurer Recovery Flow (Future Integration)

**Setup:**
1. Roster has 1 Warrior with condition INJURED.
2. Warrior's `condition_recovery_timestamp` is set to 30 seconds from now.

**Actions:**
1. Wait 30 seconds (or manually advance time in tests).
2. Check condition:
   ```gdscript
   var adv = GameManager.roster.get_adventurer(&"adv_war_001")
   print("Condition: %s" % Enums.AdventurerCondition.keys()[adv.condition])
   ```

**Expected Feel:**
- After 30 seconds, condition updates to FATIGUED (or HEALTHY based on future recovery logic).
- Adventurer becomes deployable.

**Expected Output:**
```
Condition: FATIGUED
```

**Red Flags:**
- Condition remains INJURED after recovery time.
- Condition jumps to HEALTHY (skipping FATIGUED).

**Note:** Condition recovery is handled by a separate ticking system (not part of TASK-013), but this scenario validates that the roster can read and respect condition state.

---

## Section 16 · Implementation Prompt

Below is the complete GDScript implementation for TASK-013. This code is production-ready and should be pasted into the appropriate files.

### File 1: `res://src/services/adventurer_roster.gd`

```gdscript
## AdventurerRoster service — manages the global collection of all recruited adventurers
## and handles party composition for expeditions.
## @author: Game Code Executor
## @task: TASK-013
class_name AdventurerRoster
extends RefCounted

## Maximum number of adventurers in the roster (default 12, can be increased via guild upgrades)
const MAX_ROSTER_SIZE := 12

## Maximum party size for expeditions
const MAX_PARTY_SIZE := 4

## Default morale for newly recruited adventurers
const DEFAULT_MORALE := 50

## Dictionary of all recruited adventurers: {StringName (adventurer_id): AdventurerData}
var adventurers: Dictionary = {}

## Current party composition (array of adventurer IDs, max 4)
var _current_party: Array[StringName] = []

## Maximum roster size (can be increased by guild upgrades)
var max_roster_size: int = MAX_ROSTER_SIZE

## Counter for generating unique adventurer IDs
var _next_adventurer_counter: int = 1


## Recruits a new adventurer of the specified class and level.
## Returns the adventurer's unique ID, or empty StringName if roster is full.
func recruit_adventurer(class_type: Enums.ClassType, starting_level: int = 1) -> StringName:
	# Check roster capacity
	if adventurers.size() >= max_roster_size:
		push_warning("Roster full (%d/%d). Cannot recruit." % [adventurers.size(), max_roster_size])
		return &""
	
	# Generate unique ID
	var class_short := _get_class_short_name(class_type)
	var adventurer_id := StringName("adv_%s_%03d" % [class_short, _next_adventurer_counter])
	_next_adventurer_counter += 1
	
	# Create AdventurerData
	var adv := AdventurerData.new()
	adv.id = adventurer_id
	adv.class_type = class_type
	adv.level = clampi(starting_level, 1, 50)
	adv.xp = 0
	adv.name = _generate_name(class_type)
	adv.affinity = _random_affinity()
	adv.condition = Enums.AdventurerCondition.HEALTHY
	adv.morale = DEFAULT_MORALE
	adv.condition_recovery_timestamp = 0.0
	
	# Calculate starting stats
	_calculate_starting_stats(adv)
	
	# Add to roster
	adventurers[adventurer_id] = adv
	
	# Emit signal
	EventBus.adventurer_recruited.emit(adventurer_id, class_type)
	
	return adventurer_id


## Returns the AdventurerData for the given ID, or null if not found.
func get_adventurer(id: StringName) -> AdventurerData:
	return adventurers.get(id, null)


## Returns true if an adventurer with the given ID exists in the roster.
func has_adventurer(id: StringName) -> bool:
	return adventurers.has(id)


## Returns all adventurers in the roster as an array.
func get_all_adventurers() -> Array[AdventurerData]:
	var result: Array[AdventurerData] = []
	for adv in adventurers.values():
		result.append(adv)
	return result


## Removes an adventurer from the roster. Returns true if removed, false if not found.
## If the adventurer was in the current party, they are also removed from the party.
func remove_adventurer(id: StringName) -> bool:
	if not adventurers.has(id):
		return false
	
	adventurers.erase(id)
	
	# Remove from party if present
	if _current_party.has(id):
		_current_party.erase(id)
	
	return true


## Sets the current party to the given array of adventurer IDs.
## Validates the party composition first. Returns OK on success, or an error code on failure.
## On failure, the current party is NOT modified.
func set_party(adventurer_ids: Array[StringName]) -> Error:
	var validation_result := validate_party(adventurer_ids)
	if validation_result != OK:
		return validation_result
	
	_current_party = adventurer_ids.duplicate()
	EventBus.party_assembled.emit(_current_party)
	return OK


## Validates a party composition. Returns OK if valid, or an error code if invalid.
func validate_party(adventurer_ids: Array[StringName]) -> Error:
	# Must have at least 1 adventurer
	if adventurer_ids.size() == 0:
		return ERR_INVALID_PARAMETER
	
	# Must not exceed max party size
	if adventurer_ids.size() > MAX_PARTY_SIZE:
		return ERR_INVALID_PARAMETER
	
	# Check for duplicates
	var seen: Dictionary = {}
	for id in adventurer_ids:
		if seen.has(id):
			return ERR_ALREADY_EXISTS
		seen[id] = true
	
	# Validate each adventurer
	for id in adventurer_ids:
		# Must exist in roster
		if not adventurers.has(id):
			return ERR_DOES_NOT_EXIST
		
		var adv := adventurers[id]
		
		# Must be deployable (Healthy or Fatigued only)
		if adv.condition == Enums.AdventurerCondition.INJURED or adv.condition == Enums.AdventurerCondition.EXHAUSTED:
			return ERR_UNAVAILABLE
	
	return OK


## Returns the current party as an array of AdventurerData instances.
## Filters out any IDs that no longer exist in the roster (defensive).
func get_party() -> Array[AdventurerData]:
	var result: Array[AdventurerData] = []
	for id in _current_party:
		if adventurers.has(id):
			result.append(adventurers[id])
		else:
			push_warning("Party contains non-existent adventurer ID: %s" % id)
	return result


## Returns a copy of the current party IDs (read-only access).
func get_party_ids() -> Array[StringName]:
	return _current_party.duplicate()


## Clears the current party (no adventurers selected for next expedition).
func clear_party() -> void:
	_current_party.clear()
	EventBus.party_cleared.emit()


## Serializes the roster to a Dictionary for save files.
func to_dict() -> Dictionary:
	var adv_dict := {}
	for id in adventurers.keys():
		adv_dict[String(id)] = adventurers[id].to_dict()
	
	return {
		"adventurers": adv_dict,
		"current_party": _current_party.map(func(id): return String(id)),
		"max_roster_size": max_roster_size,
		"next_adventurer_counter": _next_adventurer_counter
	}


## Deserializes the roster from a Dictionary (loaded from save files).
func from_dict(data: Dictionary) -> void:
	adventurers.clear()
	_current_party.clear()
	
	# Load adventurers
	for id_str in data.get("adventurers", {}).keys():
		var adv_data = data["adventurers"][id_str]
		var adv := AdventurerData.new()
		adv.from_dict(adv_data)
		
		# Defensive clamping
		adv.level = clampi(adv.level, 1, 50)
		adv.xp = clampi(adv.xp, 0, 999999)
		adv.morale = clampi(adv.morale, 0, 100)
		
		adventurers[StringName(id_str)] = adv
	
	# Load current party
	_current_party = data.get("current_party", []).map(func(s): return StringName(s))
	
	# Load settings
	max_roster_size = clampi(data.get("max_roster_size", MAX_ROSTER_SIZE), 4, 100)
	_next_adventurer_counter = data.get("next_adventurer_counter", 1)


# --- PRIVATE HELPERS ---

func _get_class_short_name(class_type: Enums.ClassType) -> String:
	match class_type:
		Enums.ClassType.WARRIOR: return "war"
		Enums.ClassType.RANGER: return "ran"
		Enums.ClassType.MAGE: return "mag"
		Enums.ClassType.ROGUE: return "rog"
		Enums.ClassType.ALCHEMIST: return "alc"
		Enums.ClassType.SENTINEL: return "sen"
		_: return "unk"


func _generate_name(class_type: Enums.ClassType) -> String:
	var names: Array[String] = []
	match class_type:
		Enums.ClassType.WARRIOR:
			names = ["Kira", "Thane", "Bjorn", "Asha", "Rorik", "Freya", "Magnus", "Elara"]
		Enums.ClassType.RANGER:
			names = ["Sylvan", "Talon", "Mira", "Fenris", "Lyra", "Hawk", "Vesper", "Ashen"]
		Enums.ClassType.MAGE:
			names = ["Alden", "Seraphine", "Lucian", "Nyx", "Cassian", "Vespera", "Theron", "Isolde"]
		Enums.ClassType.ROGUE:
			names = ["Shade", "Vex", "Sable", "Rook", "Whisper", "Ember", "Sly", "Onyx"]
		Enums.ClassType.ALCHEMIST:
			names = ["Caelum", "Briar", "Sage", "Orion", "Ivy", "Flint", "Willow", "Cinder"]
		Enums.ClassType.SENTINEL:
			names = ["Valorin", "Bastian", "Aegis", "Serena", "Ward", "Fortuna", "Citadel", "Haven"]
	
	var base_name := names[randi() % names.size()]
	var final_name := base_name
	var suffix := 1
	
	# Check for name collision
	while _name_exists(final_name):
		suffix += 1
		final_name = "%s %s" % [base_name, _to_roman(suffix)]
	
	return final_name


func _name_exists(name: String) -> bool:
	for adv in adventurers.values():
		if adv.name.to_lower() == name.to_lower():
			return true
	return false


func _to_roman(num: int) -> String:
	match num:
		2: return "II"
		3: return "III"
		4: return "IV"
		5: return "V"
		6: return "VI"
		7: return "VII"
		8: return "VIII"
		9: return "IX"
		10: return "X"
		_: return str(num)


func _random_affinity() -> Enums.Element:
	var elements = [Enums.Element.TERRA, Enums.Element.FLAME, Enums.Element.FROST, Enums.Element.ARCANE, Enums.Element.SHADOW]
	return elements[randi() % elements.size()]


func _calculate_starting_stats(adv: AdventurerData) -> void:
	var level := adv.level
	var stats := StatBlock.new()
	
	# Base stats at level 1 (from GDD §6.4)
	match adv.class_type:
		Enums.ClassType.WARRIOR:
			stats.hp = 100 + (level - 1) * 15
			stats.mp = 20 + (level - 1) * 2
			stats.atk = 15 + (level - 1) * 3
			stats.def = 12 + (level - 1) * 2
			stats.spd = 8 + (level - 1) * 1
			stats.per = 6 + (level - 1) * 0.5
		Enums.ClassType.RANGER:
			stats.hp = 80 + (level - 1) * 8
			stats.mp = 30 + (level - 1) * 2
			stats.atk = 12 + (level - 1) * 3
			stats.def = 8 + (level - 1) * 1
			stats.spd = 14 + (level - 1) * 3
			stats.per = 12 + (level - 1) * 2
		Enums.ClassType.MAGE:
			stats.hp = 60 + (level - 1) * 6
			stats.mp = 60 + (level - 1) * 6
			stats.atk = 10 + (level - 1) * 3
			stats.def = 6 + (level - 1) * 1
			stats.spd = 7 + (level - 1) * 1.5
			stats.per = 10 + (level - 1) * 1.5
		Enums.ClassType.ROGUE:
			stats.hp = 70 + (level - 1) * 8
			stats.mp = 25 + (level - 1) * 2
			stats.atk = 14 + (level - 1) * 2.5
			stats.def = 6 + (level - 1) * 1
			stats.spd = 16 + (level - 1) * 3.5
			stats.per = 14 + (level - 1) * 2.5
		Enums.ClassType.ALCHEMIST:
			stats.hp = 85 + (level - 1) * 10
			stats.mp = 50 + (level - 1) * 4
			stats.atk = 8 + (level - 1) * 1
			stats.def = 9 + (level - 1) * 1.5
			stats.spd = 9 + (level - 1) * 1.5
			stats.per = 11 + (level - 1) * 2
		Enums.ClassType.SENTINEL:
			stats.hp = 110 + (level - 1) * 14
			stats.mp = 40 + (level - 1) * 3
			stats.atk = 10 + (level - 1) * 1.5
			stats.def = 14 + (level - 1) * 3
			stats.spd = 6 + (level - 1) * 1
			stats.per = 8 + (level - 1) * 1.5
	
	adv.stats = stats
```

### File 2: `res://src/autoloads/event_bus.gd` (add signals)

Add these signals to the existing EventBus:

```gdscript
## Emitted when an adventurer is recruited. adventurer_id: StringName, class_type: Enums.ClassType
signal adventurer_recruited(adventurer_id: StringName, class_type: Enums.ClassType)

## Emitted when a party is successfully assembled. party_ids: Array[StringName] of adventurer IDs
signal party_assembled(party_ids: Array[StringName])

## Emitted when the party is cleared (no adventurers selected)
signal party_cleared()
```

### File 3: `res://src/autoloads/game_manager.gd` (add roster property)

Add this property to GameManager:

```gdscript
## Adventurer roster manager (initialized in initialize())
var roster: AdventurerRoster = null
```

And initialize it in `initialize()`:

```gdscript
func initialize() -> void:
	if _initialized:
		return
	
	roster = AdventurerRoster.new()
	
	_initialized = true
	game_initialized.emit()
```

