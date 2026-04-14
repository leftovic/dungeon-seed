# Task: Game Balance Configuration Constants (GameConfig)

**Priority:** P2 — Important content  
**Tier:** Core Infrastructure  
**Complexity:** 5 (Fibonacci) — moderate, well-specified data structures  
**Phase:** Pre-Production  
**Stream:** ⚪ TCH (Technical) — Core game configuration class  
**GDD Reference:** GDD §4.1–4.3 — Game Balance Parameters  
**Milestone:** Alpha  
**Blocking Tasks:** TASK-003a (Enums) must complete first  

---

## 1. Header

| Attribute | Value |
|-----------|-------|
| **Output File** | `src/models/game_config.gd` (class_name GameConfig) |
| **Test File** | `tests/models/test_game_config.gd` |
| **Dependencies** | TASK-003a (enums.gd) — GameConfig references Enums.* types |
| **Estimated Hours** | 2 hours (code + tests) |
| **Type** | Data Structure / Configuration Class |

---

## 2. Description

### Overview

GameConfig is a **static utility class** that centralizes all game balance constants. It serves three purposes:

1. **Single source of truth** for balance values (damage scaling, currency rates, difficulty modifiers)
2. **Type-safe configuration** via enum-keyed dictionaries and static methods
3. **Zero-runtime-cost access** — all values are compile-time constants with no allocations

This ticket implements the data layer for the dungeon generation system's balance model. Game designers adjust these values to tune progression, difficulty curves, and economic balance without touching code logic.

### Architecture

```
Enums (TASK-003a)
    ↓
    ├─ enum SeedRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
    ├─ enum LevelTier { NOVICE, SKILLED, VETERAN, ELITE }
    ├─ enum AdventurerClass { WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL }
    ├─ enum Currency { GOLD, ESSENCE, FRAGMENTS, ARTIFACTS }
    ├─ enum RoomType { COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS }
    ├─ enum SeedPhase { SPORE, SPROUT, BUD, BLOOM }
    └─ enum Element { ... (count from Enums) }
    
GameConfig (this ticket)
    ├─ const BASE_GROWTH_SECONDS: Dictionary  [SeedRarity → seconds]
    ├─ const XP_PER_TIER: Dictionary  [LevelTier → XP]
    ├─ const BASE_STATS: Dictionary  [AdventurerClass → stat dict]
    ├─ const MUTATION_SLOTS: Dictionary  [SeedRarity → slot count]
    ├─ const CURRENCY_EARN_RATES: Dictionary  [Currency → rate/second]
    ├─ const ROOM_DIFFICULTY_SCALE: Dictionary  [RoomType → multiplier]
    ├─ const PHASE_GROWTH_MULTIPLIERS: Dictionary  [SeedPhase → multiplier]
    ├─ const ELEMENT_NAMES: Dictionary  [Element → display name]
    ├─ const RARITY_COLORS: Dictionary  [SeedRarity → Color]
    └─ static func get_base_stats(cls: Enums.AdventurerClass) → Dictionary
```

### Player Experience Impact

- **Class selection balance** — BASE_STATS ensures all 6 classes are viable at their design intent (warrior tanky, mage utility-heavy, etc.)
- **Progression pacing** — XP_PER_TIER gates advancement; designers adjust to tune play session length
- **Economic health** — CURRENCY_EARN_RATES controls resource scarcity; tuning prevents inflation/deflation
- **Difficulty curve** — ROOM_DIFFICULTY_SCALE and PHASE_GROWTH_MULTIPLIERS govern encounter scaling

### Development Cost

- **Implementation:** 2 hours (data entry + validation)
- **Testing:** 1.5 hours (GUT test suite + edge case validation)
- **Cross-stream integration:** Minimal — this is a read-only reference layer

---

## 3. Use Cases

### UC-001: Adventurer Class Selection

**Actor:** Player selecting starting class  
**Scenario:** Player sees WARRIOR has 120 HP, 18 ATK, 15 DEF vs ROGUE with 75 HP, 16 ATK, 8 DEF. Player understands warrior is tankier, rogue is more fragile but faster (18 SPD vs 8 SPD). BASE_STATS lookup is synchronous, zero-allocation.

### UC-002: Seed Phase Progression Tuning

**Actor:** Game Designer  
**Scenario:** Playtesters report BLOOM phase (multiplier 3.0x) feels too punishing compared to SPORE (1.0x). Designer opens config, adjusts PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.BLOOM] from 3.0 to 2.5, restarts dungeon. No recompile needed.

### UC-003: Economy Rebalance

**Actor:** Game Economist  
**Scenario:** Economy simulation shows gold inflation over 90-day horizon. Economist adjusts CURRENCY_EARN_RATES[Enums.Currency.GOLD] from 10 to 8 (20% reduction) and re-runs balance verification. All game loops instantly use new rate.

---

## 4. Glossary

| Term | Definition |
|------|-----------|
| **Const dictionary** | A `const` variable holding a Dictionary; all keys/values immutable at runtime |
| **Enum-keyed** | Dictionary uses enum integer values as keys, not strings (safer, faster) |
| **Class_name** | GDScript declaration allowing reference to this class without import (`GameConfig.BASE_STATS`) |
| **Static method** | `static func` — accessed via class name, no instance needed (`GameConfig.get_base_stats(cls)`) |
| **Type hint** | GDScript annotation specifying variable/parameter type (e.g., `-> Dictionary`) |
| **Zero allocation** | No objects created at runtime; all values pre-computed and const |
| **Immutable** | Once assigned, const values cannot be reassigned (const enforced by GDScript compiler) |
| **AdventurerClass** | Enum representing player character class (6 values: WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL) |
| **SeedRarity** | Enum representing plant seed rarity tier (5 values: COMMON, UNCOMMON, RARE, EPIC, LEGENDARY) |
| **SeedPhase** | Enum representing dungeon generation phase (4 values: SPORE, SPROUT, BUD, BLOOM) |
| **Currency** | Enum representing in-game currency types (4 values: GOLD, ESSENCE, FRAGMENTS, ARTIFACTS) |
| **RoomType** | Enum representing dungeon room type (6 values: COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS) |

---

## 5. Out of Scope

- [ ] **Dynamic runtime config** — No loading of balance values from JSON/CSV files (future work)
- [ ] **Remote balance updates** — No live-ops server push of new values (handle via engine update)
- [ ] **Localization strings** — ELEMENT_NAMES are English only; translations handled separately
- [ ] **Validation on save** — No save file import/export of these constants
- [ ] **Inspector exposure** — GameConfig values not exposed in Godot editor (read-only class)
- [ ] **Balance simulation** — This ticket provides data; balance verification happens in TASK-008 (Balance Auditor)
- [ ] **Difficulty presets** — No "Easy/Normal/Hard" multiplier sets; designers adjust individual values
- [ ] **Per-platform overrides** — Same constants across all platforms (PC, web, mobile)

---

## 6. Functional Requirements

### Core Dictionaries

| FR-ID | Requirement | Source |
|-------|-------------|--------|
| **FR-001** | BASE_GROWTH_SECONDS: Keys are all SeedRarity enum values (5 entries); values are positive integers (60–1200). | GDD §4.1, TASK-003 FR-013 |
| **FR-002** | BASE_GROWTH_SECONDS: COMMON=60, UNCOMMON=120, RARE=300, EPIC=600, LEGENDARY=1200 seconds. | GDD §4.1, Table 4.1 |
| **FR-003** | XP_PER_TIER: Keys are all LevelTier enum values (4 entries); values are non-negative integers in monotonic increasing order. | GDD §4.3, TASK-003 FR-014 |
| **FR-004** | XP_PER_TIER: NOVICE=0, SKILLED=100, VETERAN=350, ELITE=750 XP. | GDD §4.3, Table 4.3 |
| **FR-005** | BASE_STATS: Keys are all AdventurerClass enum values (6 entries). Values are dictionaries with keys ["health", "attack", "defense", "speed", "utility"], all positive integers. | GDD §4.3, TASK-003 FR-015 |
| **FR-006** | BASE_STATS[WARRIOR] = {"health": 120, "attack": 18, "defense": 15, "speed": 8, "utility": 5}. | GDD §4.3, Table 4.2 |
| **FR-007** | BASE_STATS[RANGER] = {"health": 85, "attack": 14, "defense": 10, "speed": 15, "utility": 10}. | GDD §4.3, Table 4.2 |
| **FR-008** | BASE_STATS[MAGE] = {"health": 70, "attack": 12, "defense": 8, "speed": 10, "utility": 20}. | GDD §4.3, Table 4.2 |
| **FR-009** | BASE_STATS[ROGUE] = {"health": 75, "attack": 16, "defense": 8, "speed": 18, "utility": 12}. | GDD §4.3, Table 4.2 |
| **FR-010** | BASE_STATS[ALCHEMIST] = {"health": 80, "attack": 10, "defense": 12, "speed": 10, "utility": 18}. | GDD §4.3, Table 4.2 |
| **FR-011** | BASE_STATS[SENTINEL] = {"health": 130, "attack": 10, "defense": 20, "speed": 6, "utility": 8}. | GDD §4.3, Table 4.2 |
| **FR-012** | MUTATION_SLOTS: Keys are all SeedRarity enum values (5 entries); values are positive integers (1–5). | GDD §4.1, TASK-003 FR-016 |
| **FR-013** | MUTATION_SLOTS: COMMON=1, UNCOMMON=2, RARE=3, EPIC=4, LEGENDARY=5 slots. | GDD §4.1, Table 4.1 |
| **FR-014** | CURRENCY_EARN_RATES: Keys are all Currency enum values (4 entries); values are non-negative numerics (0–10). | GDD §4.2, TASK-003 FR-017 |
| **FR-015** | CURRENCY_EARN_RATES: GOLD=10, ESSENCE=2, FRAGMENTS=1, ARTIFACTS=0 per second. | GDD §4.2, Table 4.4 |
| **FR-016** | ROOM_DIFFICULTY_SCALE: Keys are all RoomType enum values (6 entries); values are positive floats (0.0–2.0). | GDD §4.2, TASK-003 FR-018 |
| **FR-017** | ROOM_DIFFICULTY_SCALE: COMBAT=1.0, TREASURE=0.5, TRAP=0.8, PUZZLE=0.6, REST=0.0, BOSS=2.0. | GDD §4.2, Table 4.5 |
| **FR-018** | PHASE_GROWTH_MULTIPLIERS: Keys are all SeedPhase enum values (4 entries); values are positive floats (1.0–3.0). | GDD §4.1, TASK-003 FR-019 |
| **FR-019** | PHASE_GROWTH_MULTIPLIERS: SPORE=1.0, SPROUT=1.5, BUD=2.0, BLOOM=3.0. | GDD §4.1, Table 4.1 |
| **FR-020** | ELEMENT_NAMES: Keys are all Element enum values; values are non-empty English strings. | GDD §4.4, TASK-003 FR-020 |
| **FR-021** | RARITY_COLORS: Keys are all SeedRarity enum values (5 entries); values are Color objects (RGBA). | GDD §4.1, TASK-003 FR-021 |
| **FR-022** | RARITY_COLORS exact values: COMMON=gray (0.78,0.78,0.78), UNCOMMON=green (0.18,0.8,0.25), RARE=blue (0.25,0.52,0.96), EPIC=purple (0.64,0.21,0.93), LEGENDARY=gold (0.95,0.77,0.06). | GDD §4.1, Table 4.6 |

### Helper Method

| FR-ID | Requirement | Source |
|-------|-------------|--------|
| **FR-023** | `static func get_base_stats(cls: Enums.AdventurerClass) -> Dictionary` returns the stat dictionary for the given class from BASE_STATS. | TASK-003 FR-022 |
| **FR-024** | get_base_stats() returns a new dictionary reference (not the const dictionary itself) to prevent accidental mutation. | Safety best practice |

### Completeness

| FR-ID | Requirement | Source |
|-------|-------------|--------|
| **FR-025** | Every enum value in Enums.SeedRarity, Enums.LevelTier, Enums.AdventurerClass, Enums.Currency, Enums.RoomType, Enums.SeedPhase, Enums.Element must have exactly one entry in its corresponding GameConfig dictionary. No missing keys, no extra keys. | TASK-003 FR-023 |

---

## 7. Non-Functional Requirements

| NFR-ID | Requirement | Target |
|--------|-------------|--------|
| **NFR-001** | All dictionary and method declarations must have full type hints (no `var` without `: Type`, no return without `->` type). | 100% type coverage |
| **NFR-002** | Zero runtime allocations beyond dictionary instantiation at file load time. Const dictionaries are frozen at compile time. | 0 bytes allocated per method call |
| **NFR-003** | GameConfig file MUST be ≤ 200 lines of code (9 dictionaries + 1 method + comments). | 200 lines max |
| **NFR-004** | get_base_stats() method MUST execute in O(1) time (hash map lookup only). | < 1ms per call |
| **NFR-005** | All English strings in ELEMENT_NAMES MUST be <= 20 characters (UI layout constraint). | 20 char max |
| **NFR-006** | All Color values in RARITY_COLORS MUST have RGB components in range [0.0, 1.0] and be distinguishable (not equal to each other). | 5 distinct colors |
| **NFR-007** | Dictionary keys MUST be enum integer values, not strings (for memory efficiency and type safety). | Enum-only keys |
| **NFR-008** | Test coverage MUST be ≥ 90% (all dictionaries + helper method). | >= 90% lines covered |
| **NFR-009** | All BASE_STATS stat values (health, attack, defense, speed, utility) MUST be positive integers > 0. | All values > 0 |
| **NFR-010** | XP_PER_TIER values MUST be monotonically increasing (each tier requires more XP than previous). | NOVICE ≤ SKILLED ≤ VETERAN ≤ ELITE |
| **NFR-011** | Class initialization via get_base_stats() MUST return a duplicate dict (not a reference to the const dict). | Returns new Dictionary() |
| **NFR-012** | Documentation comment MUST explain the purpose and source (GDD section) of each const dictionary. | Each dict has doc comment |

---

## 8. Designer's Manual

### Tuning Guide

Each GameConfig constant is tuned to affect game balance and progression:

#### BASE_GROWTH_SECONDS
- **Purpose:** Controls plant growth time per rarity tier
- **Tuning:** Higher values slow progression; lower values accelerate it
- **Example:** Playtesters report EPIC seeds grow too fast → increase `BASE_GROWTH_SECONDS[Enums.SeedRarity.EPIC]` from 600 to 720 seconds

#### BASE_STATS
- **Purpose:** Initial class stat profiles; balanced around warrior/sentinel being tanky, mage having utility, rogue having speed
- **Tuning:** Adjust individual stats to buff/nerf classes relative to each other
- **Example:** MAGE feels too fragile → increase `BASE_STATS[Enums.AdventurerClass.MAGE]["health"]` from 70 to 80

#### XP_PER_TIER
- **Purpose:** Cumulative XP requirements; controls pacing of level progression
- **Tuning:** Increase gaps between tiers to slow leveling; decrease to accelerate
- **Constraint:** Must remain strictly increasing
- **Example:** SKILLED→VETERAN jump feels too large → change VETERAN from 350 to 250

#### CURRENCY_EARN_RATES
- **Purpose:** Passive currency generation per second of gameplay
- **Tuning:** Used to control economy inflation/deflation
- **Example:** Gold inflation detected in economy sim → reduce `CURRENCY_EARN_RATES[Enums.Currency.GOLD]` from 10 to 8

#### ROOM_DIFFICULTY_SCALE
- **Purpose:** Encounter difficulty multiplier per room type
- **Tuning:** Adjust relative difficulty of combat vs puzzles
- **Example:** COMBAT encounters feel too hard → reduce from 1.0 to 0.9

#### PHASE_GROWTH_MULTIPLIERS
- **Purpose:** Scaling factor applied to all growth metrics at each dungeon phase
- **Tuning:** Controls difficulty curve across dungeon progression
- **Example:** BLOOM phase too punishing → reduce from 3.0 to 2.5

#### RARITY_COLORS
- **Purpose:** UI visual distinction of seed rarity
- **Tuning:** Update if art direction requires different palette
- **Constraint:** Colors must be distinguishable in UI (minimum contrast ratio 3:1)
- **Example:** Rare seeds too blue-heavy → shift RARE from (0.25,0.52,0.96) to (0.15,0.60,0.90)

### Config File Location

- **File:** `src/models/game_config.gd`
- **Access:** `GameConfig.BASE_STATS[class_enum]` (all dicts are public const)
- **No editor inspector exposure** (values are compile-time constants, not editable in-engine)

### GDD Cross-Reference

| Constant | GDD Section |
|----------|-------------|
| BASE_GROWTH_SECONDS | §4.1 — Plant Growth Mechanics |
| BASE_STATS | §4.3 — Adventurer Class Balance |
| XP_PER_TIER | §4.3 — Level Progression |
| MUTATION_SLOTS | §4.1 — Seed Mutation System |
| CURRENCY_EARN_RATES | §4.2 — Economy Parameters |
| ROOM_DIFFICULTY_SCALE | §4.2 — Encounter Difficulty |
| PHASE_GROWTH_MULTIPLIERS | §4.1 — Dungeon Phase Scaling |
| ELEMENT_NAMES | §4.4 — Element System (display names) |
| RARITY_COLORS | §4.1 — Rarity UI Colors |

---

## 9. Architecture Notes

### Dependency Graph

```
Enums.gd (TASK-003a) ← must exist first
    ↓
GameConfig.gd (this ticket)
    ↓
    ├→ DungeonGenerator.gd (TASK-004) references GameConfig.PHASE_GROWTH_MULTIPLIERS
    ├→ AdventurerFactory.gd (TASK-005) references GameConfig.BASE_STATS
    ├→ EconomyManager.gd (TASK-006) references GameConfig.CURRENCY_EARN_RATES
    ├→ EncounterScaler.gd (TASK-007) references GameConfig.ROOM_DIFFICULTY_SCALE
    └→ BalanceSimulator.py (TASK-008) reads all GameConfig values for validation
```

### Class Structure

```gdscript
class_name GameConfig

# [9 const dictionaries — see Implementation]

static func get_base_stats(cls: Enums.AdventurerClass) -> Dictionary:
    # Returns a new Dictionary (not reference to const)
    return GameConfig.BASE_STATS[cls].duplicate()
```

### Memory Layout

- Total const dictionaries: 9
- Total entries across all dicts: 5+4+6+5+4+6+4+N(elements)+5 = ~43 entries + element count
- Memory per dict entry: 16–32 bytes (Godot Dictionary overhead)
- **Estimated total:** < 2 KB (negligible)

---

## 10. Security & Compliance

### Threat 1: Const Dictionary Mutation

**Risk:** Code accidentally mutates a const dictionary at runtime (e.g., `GameConfig.BASE_STATS[cls]["health"] = 999`), breaking balance.

**Mitigation:**
- Use `const` keyword (GDScript enforces immutability at compile time)
- Helper method `get_base_stats()` returns duplicate (protects against mutation of returned dict)
- Linting: All FRs explicitly require `const` keyword in implementation

**Detection:** Code review + GUT test validates const enforcement

### Threat 2: Missing Enum Entries

**Risk:** New enum value added (e.g., new AdventurerClass) but GameConfig dict not updated → crash at runtime when accessed.

**Mitigation:**
- FR-025: Acceptance Criteria explicitly tests every enum value has a dict entry
- GUT test iterates all enum values and verifies entry existence

**Detection:** GUT test `test_all_enum_values_present()` per dictionary

### Threat 3: Type Mismatch on Access

**Risk:** Code accesses `BASE_STATS[cls]["nonexistent_key"]` → returns null → crashes downstream.

**Mitigation:**
- Type hints enforce expected dictionary structure
- Helper method `get_base_stats()` guarantees structure via constant definition

**Detection:** Code review + GUT test validates all keys present in returned dict

---

## 11. Acceptance Criteria

### Dictionary Completeness (FR-025)

- [ ] AC-001: BASE_GROWTH_SECONDS has exactly 5 entries (one per SeedRarity enum value)
- [ ] AC-002: XP_PER_TIER has exactly 4 entries (one per LevelTier enum value)
- [ ] AC-003: BASE_STATS has exactly 6 entries (one per AdventurerClass enum value)
- [ ] AC-004: MUTATION_SLOTS has exactly 5 entries (one per SeedRarity enum value)
- [ ] AC-005: CURRENCY_EARN_RATES has exactly 4 entries (one per Currency enum value)
- [ ] AC-006: ROOM_DIFFICULTY_SCALE has exactly 6 entries (one per RoomType enum value)
- [ ] AC-007: PHASE_GROWTH_MULTIPLIERS has exactly 4 entries (one per SeedPhase enum value)
- [ ] AC-008: ELEMENT_NAMES has exactly N entries (one per Element enum value, where N is from Enums.gd)
- [ ] AC-009: RARITY_COLORS has exactly 5 entries (one per SeedRarity enum value)

### Dictionary Values (FR-001 through FR-022)

- [ ] AC-010: BASE_GROWTH_SECONDS all values are positive integers
- [ ] AC-011: BASE_GROWTH_SECONDS[COMMON] == 60
- [ ] AC-012: BASE_GROWTH_SECONDS[UNCOMMON] == 120
- [ ] AC-013: BASE_GROWTH_SECONDS[RARE] == 300
- [ ] AC-014: BASE_GROWTH_SECONDS[EPIC] == 600
- [ ] AC-015: BASE_GROWTH_SECONDS[LEGENDARY] == 1200
- [ ] AC-016: XP_PER_TIER[NOVICE] == 0
- [ ] AC-017: XP_PER_TIER[SKILLED] == 100
- [ ] AC-018: XP_PER_TIER[VETERAN] == 350
- [ ] AC-019: XP_PER_TIER[ELITE] == 750
- [ ] AC-020: XP_PER_TIER values are in strictly increasing order (or equal for NOVICE=0)
- [ ] AC-021: BASE_STATS[WARRIOR] == {"health": 120, "attack": 18, "defense": 15, "speed": 8, "utility": 5}
- [ ] AC-022: BASE_STATS[RANGER] == {"health": 85, "attack": 14, "defense": 10, "speed": 15, "utility": 10}
- [ ] AC-023: BASE_STATS[MAGE] == {"health": 70, "attack": 12, "defense": 8, "speed": 10, "utility": 20}
- [ ] AC-024: BASE_STATS[ROGUE] == {"health": 75, "attack": 16, "defense": 8, "speed": 18, "utility": 12}
- [ ] AC-025: BASE_STATS[ALCHEMIST] == {"health": 80, "attack": 10, "defense": 12, "speed": 10, "utility": 18}
- [ ] AC-026: BASE_STATS[SENTINEL] == {"health": 130, "attack": 10, "defense": 20, "speed": 6, "utility": 8}
- [ ] AC-027: BASE_STATS all values (health, attack, defense, speed, utility) are positive integers > 0
- [ ] AC-028: MUTATION_SLOTS values are COMMON=1, UNCOMMON=2, RARE=3, EPIC=4, LEGENDARY=5
- [ ] AC-029: CURRENCY_EARN_RATES values are GOLD=10, ESSENCE=2, FRAGMENTS=1, ARTIFACTS=0
- [ ] AC-030: ROOM_DIFFICULTY_SCALE values are COMBAT=1.0, TREASURE=0.5, TRAP=0.8, PUZZLE=0.6, REST=0.0, BOSS=2.0
- [ ] AC-031: PHASE_GROWTH_MULTIPLIERS values are SPORE=1.0, SPROUT=1.5, BUD=2.0, BLOOM=3.0
- [ ] AC-032: ELEMENT_NAMES all values are non-empty strings, max 20 chars each
- [ ] AC-033: RARITY_COLORS[COMMON] is Color(0.78, 0.78, 0.78) gray
- [ ] AC-034: RARITY_COLORS[UNCOMMON] is Color(0.18, 0.8, 0.25) green
- [ ] AC-035: RARITY_COLORS[RARE] is Color(0.25, 0.52, 0.96) blue
- [ ] AC-036: RARITY_COLORS[EPIC] is Color(0.64, 0.21, 0.93) purple
- [ ] AC-037: RARITY_COLORS[LEGENDARY] is Color(0.95, 0.77, 0.06) gold

### Helper Method (FR-023, FR-024)

- [ ] AC-038: get_base_stats(Enums.AdventurerClass.WARRIOR) returns dict with health=120, attack=18, defense=15, speed=8, utility=5
- [ ] AC-039: get_base_stats() returns a NEW Dictionary, not a reference to the const dict (calling code cannot mutate the const)
- [ ] AC-040: get_base_stats() is a static method (callable via GameConfig.get_base_stats, no instance needed)

### Code Quality (NFRs)

- [ ] AC-041: All declarations have full type hints (no bare `var` without `: Type`)
- [ ] AC-042: All const dictionaries are declared with `const` keyword (immutable)
- [ ] AC-043: Dictionary keys use enum integer values, not strings
- [ ] AC-044: All Color values have RGB components in [0.0, 1.0] range
- [ ] AC-045: GameConfig file ≤ 200 lines total
- [ ] AC-046: Documentation comment present on each const dictionary explaining purpose + GDD reference
- [ ] AC-047: No hardcoded magic strings or numbers (all values inline in dict definitions)

---

## 12. Regression Gate

- [ ] RG-001: After changes, all existing ACs still pass
- [ ] RG-002: get_base_stats() still returns dict with correct structure (no keys added/removed)
- [ ] RG-003: Const dictionaries still have expected entry count (no keys added/removed)
- [ ] RG-004: All dictionary values still match GDD §4.1–4.4 (no accidental edits)
- [ ] RG-005: Color values still distinguishable (no accidental swaps)
- [ ] RG-006: XP_PER_TIER still monotonically increasing
- [ ] RG-007: No runtime allocations on const dictionary access (profile in Release build)
- [ ] RG-008: GUT test suite still ≥ 90% code coverage
- [ ] RG-009: File still ≤ 200 lines
- [ ] RG-010: All type hints still present (no regressions to `var` without type)

---

## 13. Dependencies

| Dependency | Status | Reason |
|------------|--------|--------|
| **TASK-003a (Enums)** | Blocking | GameConfig references Enums.* types; Enums must exist first |
| **GDD §4.1–4.4** | Non-blocking | Values sourced from GDD; document is reference only |
| **Godot 4.5** | Non-blocking | Engine version (target platform) |

---

## 14. Test Implementations

**Framework:** GUT (Godot Unit Test)  
**Test file:** `tests/models/test_game_config.gd`  
**Extends:** GutTest  

```gdscript
extends GutTest

## Test all dictionaries exist and have correct enum-value keys

func test_base_growth_seconds_completeness() -> void:
	var expected_keys: Array[int] = [
		Enums.SeedRarity.COMMON,
		Enums.SeedRarity.UNCOMMON,
		Enums.SeedRarity.RARE,
		Enums.SeedRarity.EPIC,
		Enums.SeedRarity.LEGENDARY,
	]
	
	gut.assert_eq(GameConfig.BASE_GROWTH_SECONDS.size(), 5,
		"BASE_GROWTH_SECONDS should have exactly 5 entries (one per SeedRarity)")
	
	for key in expected_keys:
		gut.assert_true(GameConfig.BASE_GROWTH_SECONDS.has(key),
			"BASE_GROWTH_SECONDS missing SeedRarity enum key: %d" % key)

func test_base_growth_seconds_values() -> void:
	gut.assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.COMMON], 60,
		"COMMON growth time should be 60 seconds")
	gut.assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.UNCOMMON], 120,
		"UNCOMMON growth time should be 120 seconds")
	gut.assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.RARE], 300,
		"RARE growth time should be 300 seconds")
	gut.assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.EPIC], 600,
		"EPIC growth time should be 600 seconds")
	gut.assert_eq(GameConfig.BASE_GROWTH_SECONDS[Enums.SeedRarity.LEGENDARY], 1200,
		"LEGENDARY growth time should be 1200 seconds")
	
	for value in GameConfig.BASE_GROWTH_SECONDS.values():
		gut.assert_true(value > 0, "All growth times must be positive")

func test_xp_per_tier_completeness() -> void:
	var expected_keys: Array[int] = [
		Enums.LevelTier.NOVICE,
		Enums.LevelTier.SKILLED,
		Enums.LevelTier.VETERAN,
		Enums.LevelTier.ELITE,
	]
	
	gut.assert_eq(GameConfig.XP_PER_TIER.size(), 4,
		"XP_PER_TIER should have exactly 4 entries (one per LevelTier)")
	
	for key in expected_keys:
		gut.assert_true(GameConfig.XP_PER_TIER.has(key),
			"XP_PER_TIER missing LevelTier enum key: %d" % key)

func test_xp_per_tier_values() -> void:
	gut.assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.NOVICE], 0,
		"NOVICE XP threshold should be 0")
	gut.assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.SKILLED], 100,
		"SKILLED XP threshold should be 100")
	gut.assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.VETERAN], 350,
		"VETERAN XP threshold should be 350")
	gut.assert_eq(GameConfig.XP_PER_TIER[Enums.LevelTier.ELITE], 750,
		"ELITE XP threshold should be 750")

func test_xp_per_tier_monotonic() -> void:
	var prev_xp: int = -1
	var tiers: Array[int] = [
		Enums.LevelTier.NOVICE,
		Enums.LevelTier.SKILLED,
		Enums.LevelTier.VETERAN,
		Enums.LevelTier.ELITE,
	]
	
	for tier in tiers:
		var xp: int = GameConfig.XP_PER_TIER[tier]
		gut.assert_true(xp >= prev_xp,
			"XP_PER_TIER must be monotonically increasing (tier %d: %d >= %d)" % [tier, xp, prev_xp])
		prev_xp = xp

func test_base_stats_completeness() -> void:
	var expected_keys: Array[int] = [
		Enums.AdventurerClass.WARRIOR,
		Enums.AdventurerClass.RANGER,
		Enums.AdventurerClass.MAGE,
		Enums.AdventurerClass.ROGUE,
		Enums.AdventurerClass.ALCHEMIST,
		Enums.AdventurerClass.SENTINEL,
	]
	
	gut.assert_eq(GameConfig.BASE_STATS.size(), 6,
		"BASE_STATS should have exactly 6 entries (one per AdventurerClass)")
	
	for key in expected_keys:
		gut.assert_true(GameConfig.BASE_STATS.has(key),
			"BASE_STATS missing AdventurerClass enum key: %d" % key)

func test_base_stats_structure() -> void:
	var required_keys: Array[String] = ["health", "attack", "defense", "speed", "utility"]
	
	for stats_dict in GameConfig.BASE_STATS.values():
		for req_key in required_keys:
			gut.assert_true(stats_dict.has(req_key),
				"BASE_STATS entry missing required key: %s" % req_key)
			var value = stats_dict[req_key]
			gut.assert_true(value > 0,
				"All stat values must be positive integers, got %s: %s" % [req_key, value])

func test_base_stats_values_warrior() -> void:
	var warrior_stats: Dictionary = GameConfig.BASE_STATS[Enums.AdventurerClass.WARRIOR]
	gut.assert_eq(warrior_stats["health"], 120, "WARRIOR health should be 120")
	gut.assert_eq(warrior_stats["attack"], 18, "WARRIOR attack should be 18")
	gut.assert_eq(warrior_stats["defense"], 15, "WARRIOR defense should be 15")
	gut.assert_eq(warrior_stats["speed"], 8, "WARRIOR speed should be 8")
	gut.assert_eq(warrior_stats["utility"], 5, "WARRIOR utility should be 5")

func test_base_stats_values_ranger() -> void:
	var ranger_stats: Dictionary = GameConfig.BASE_STATS[Enums.AdventurerClass.RANGER]
	gut.assert_eq(ranger_stats["health"], 85, "RANGER health should be 85")
	gut.assert_eq(ranger_stats["attack"], 14, "RANGER attack should be 14")
	gut.assert_eq(ranger_stats["defense"], 10, "RANGER defense should be 10")
	gut.assert_eq(ranger_stats["speed"], 15, "RANGER speed should be 15")
	gut.assert_eq(ranger_stats["utility"], 10, "RANGER utility should be 10")

func test_base_stats_values_mage() -> void:
	var mage_stats: Dictionary = GameConfig.BASE_STATS[Enums.AdventurerClass.MAGE]
	gut.assert_eq(mage_stats["health"], 70, "MAGE health should be 70")
	gut.assert_eq(mage_stats["attack"], 12, "MAGE attack should be 12")
	gut.assert_eq(mage_stats["defense"], 8, "MAGE defense should be 8")
	gut.assert_eq(mage_stats["speed"], 10, "MAGE speed should be 10")
	gut.assert_eq(mage_stats["utility"], 20, "MAGE utility should be 20")

func test_base_stats_values_rogue() -> void:
	var rogue_stats: Dictionary = GameConfig.BASE_STATS[Enums.AdventurerClass.ROGUE]
	gut.assert_eq(rogue_stats["health"], 75, "ROGUE health should be 75")
	gut.assert_eq(rogue_stats["attack"], 16, "ROGUE attack should be 16")
	gut.assert_eq(rogue_stats["defense"], 8, "ROGUE defense should be 8")
	gut.assert_eq(rogue_stats["speed"], 18, "ROGUE speed should be 18")
	gut.assert_eq(rogue_stats["utility"], 12, "ROGUE utility should be 12")

func test_base_stats_values_alchemist() -> void:
	var alchemist_stats: Dictionary = GameConfig.BASE_STATS[Enums.AdventurerClass.ALCHEMIST]
	gut.assert_eq(alchemist_stats["health"], 80, "ALCHEMIST health should be 80")
	gut.assert_eq(alchemist_stats["attack"], 10, "ALCHEMIST attack should be 10")
	gut.assert_eq(alchemist_stats["defense"], 12, "ALCHEMIST defense should be 12")
	gut.assert_eq(alchemist_stats["speed"], 10, "ALCHEMIST speed should be 10")
	gut.assert_eq(alchemist_stats["utility"], 18, "ALCHEMIST utility should be 18")

func test_base_stats_values_sentinel() -> void:
	var sentinel_stats: Dictionary = GameConfig.BASE_STATS[Enums.AdventurerClass.SENTINEL]
	gut.assert_eq(sentinel_stats["health"], 130, "SENTINEL health should be 130")
	gut.assert_eq(sentinel_stats["attack"], 10, "SENTINEL attack should be 10")
	gut.assert_eq(sentinel_stats["defense"], 20, "SENTINEL defense should be 20")
	gut.assert_eq(sentinel_stats["speed"], 6, "SENTINEL speed should be 6")
	gut.assert_eq(sentinel_stats["utility"], 8, "SENTINEL utility should be 8")

func test_mutation_slots_completeness() -> void:
	var expected_keys: Array[int] = [
		Enums.SeedRarity.COMMON,
		Enums.SeedRarity.UNCOMMON,
		Enums.SeedRarity.RARE,
		Enums.SeedRarity.EPIC,
		Enums.SeedRarity.LEGENDARY,
	]
	
	gut.assert_eq(GameConfig.MUTATION_SLOTS.size(), 5,
		"MUTATION_SLOTS should have exactly 5 entries (one per SeedRarity)")
	
	for key in expected_keys:
		gut.assert_true(GameConfig.MUTATION_SLOTS.has(key),
			"MUTATION_SLOTS missing SeedRarity enum key: %d" % key)

func test_mutation_slots_values() -> void:
	gut.assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.COMMON], 1,
		"COMMON mutation slots should be 1")
	gut.assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.UNCOMMON], 2,
		"UNCOMMON mutation slots should be 2")
	gut.assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.RARE], 3,
		"RARE mutation slots should be 3")
	gut.assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.EPIC], 4,
		"EPIC mutation slots should be 4")
	gut.assert_eq(GameConfig.MUTATION_SLOTS[Enums.SeedRarity.LEGENDARY], 5,
		"LEGENDARY mutation slots should be 5")
	
	for value in GameConfig.MUTATION_SLOTS.values():
		gut.assert_true(value > 0, "All mutation slot counts must be positive")

func test_currency_earn_rates_completeness() -> void:
	var expected_keys: Array[int] = [
		Enums.Currency.GOLD,
		Enums.Currency.ESSENCE,
		Enums.Currency.FRAGMENTS,
		Enums.Currency.ARTIFACTS,
	]
	
	gut.assert_eq(GameConfig.CURRENCY_EARN_RATES.size(), 4,
		"CURRENCY_EARN_RATES should have exactly 4 entries (one per Currency)")
	
	for key in expected_keys:
		gut.assert_true(GameConfig.CURRENCY_EARN_RATES.has(key),
			"CURRENCY_EARN_RATES missing Currency enum key: %d" % key)

func test_currency_earn_rates_values() -> void:
	gut.assert_eq(GameConfig.CURRENCY_EARN_RATES[Enums.Currency.GOLD], 10,
		"GOLD earn rate should be 10/sec")
	gut.assert_eq(GameConfig.CURRENCY_EARN_RATES[Enums.Currency.ESSENCE], 2,
		"ESSENCE earn rate should be 2/sec")
	gut.assert_eq(GameConfig.CURRENCY_EARN_RATES[Enums.Currency.FRAGMENTS], 1,
		"FRAGMENTS earn rate should be 1/sec")
	gut.assert_eq(GameConfig.CURRENCY_EARN_RATES[Enums.Currency.ARTIFACTS], 0,
		"ARTIFACTS earn rate should be 0/sec")
	
	for value in GameConfig.CURRENCY_EARN_RATES.values():
		gut.assert_true(value >= 0, "All currency rates must be non-negative")

func test_room_difficulty_scale_completeness() -> void:
	var expected_keys: Array[int] = [
		Enums.RoomType.COMBAT,
		Enums.RoomType.TREASURE,
		Enums.RoomType.TRAP,
		Enums.RoomType.PUZZLE,
		Enums.RoomType.REST,
		Enums.RoomType.BOSS,
	]
	
	gut.assert_eq(GameConfig.ROOM_DIFFICULTY_SCALE.size(), 6,
		"ROOM_DIFFICULTY_SCALE should have exactly 6 entries (one per RoomType)")
	
	for key in expected_keys:
		gut.assert_true(GameConfig.ROOM_DIFFICULTY_SCALE.has(key),
			"ROOM_DIFFICULTY_SCALE missing RoomType enum key: %d" % key)

func test_room_difficulty_scale_values() -> void:
	gut.assert_almost_eq(GameConfig.ROOM_DIFFICULTY_SCALE[Enums.RoomType.COMBAT], 1.0, 0.01,
		"COMBAT difficulty scale should be 1.0")
	gut.assert_almost_eq(GameConfig.ROOM_DIFFICULTY_SCALE[Enums.RoomType.TREASURE], 0.5, 0.01,
		"TREASURE difficulty scale should be 0.5")
	gut.assert_almost_eq(GameConfig.ROOM_DIFFICULTY_SCALE[Enums.RoomType.TRAP], 0.8, 0.01,
		"TRAP difficulty scale should be 0.8")
	gut.assert_almost_eq(GameConfig.ROOM_DIFFICULTY_SCALE[Enums.RoomType.PUZZLE], 0.6, 0.01,
		"PUZZLE difficulty scale should be 0.6")
	gut.assert_almost_eq(GameConfig.ROOM_DIFFICULTY_SCALE[Enums.RoomType.REST], 0.0, 0.01,
		"REST difficulty scale should be 0.0")
	gut.assert_almost_eq(GameConfig.ROOM_DIFFICULTY_SCALE[Enums.RoomType.BOSS], 2.0, 0.01,
		"BOSS difficulty scale should be 2.0")
	
	for value in GameConfig.ROOM_DIFFICULTY_SCALE.values():
		gut.assert_true(value >= 0, "All difficulty scales must be non-negative")

func test_phase_growth_multipliers_completeness() -> void:
	var expected_keys: Array[int] = [
		Enums.SeedPhase.SPORE,
		Enums.SeedPhase.SPROUT,
		Enums.SeedPhase.BUD,
		Enums.SeedPhase.BLOOM,
	]
	
	gut.assert_eq(GameConfig.PHASE_GROWTH_MULTIPLIERS.size(), 4,
		"PHASE_GROWTH_MULTIPLIERS should have exactly 4 entries (one per SeedPhase)")
	
	for key in expected_keys:
		gut.assert_true(GameConfig.PHASE_GROWTH_MULTIPLIERS.has(key),
			"PHASE_GROWTH_MULTIPLIERS missing SeedPhase enum key: %d" % key)

func test_phase_growth_multipliers_values() -> void:
	gut.assert_almost_eq(GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.SPORE], 1.0, 0.01,
		"SPORE growth multiplier should be 1.0")
	gut.assert_almost_eq(GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.SPROUT], 1.5, 0.01,
		"SPROUT growth multiplier should be 1.5")
	gut.assert_almost_eq(GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.BUD], 2.0, 0.01,
		"BUD growth multiplier should be 2.0")
	gut.assert_almost_eq(GameConfig.PHASE_GROWTH_MULTIPLIERS[Enums.SeedPhase.BLOOM], 3.0, 0.01,
		"BLOOM growth multiplier should be 3.0")
	
	for value in GameConfig.PHASE_GROWTH_MULTIPLIERS.values():
		gut.assert_true(value > 0, "All growth multipliers must be positive")

func test_rarity_colors_completeness() -> void:
	var expected_keys: Array[int] = [
		Enums.SeedRarity.COMMON,
		Enums.SeedRarity.UNCOMMON,
		Enums.SeedRarity.RARE,
		Enums.SeedRarity.EPIC,
		Enums.SeedRarity.LEGENDARY,
	]
	
	gut.assert_eq(GameConfig.RARITY_COLORS.size(), 5,
		"RARITY_COLORS should have exactly 5 entries (one per SeedRarity)")
	
	for key in expected_keys:
		gut.assert_true(GameConfig.RARITY_COLORS.has(key),
			"RARITY_COLORS missing SeedRarity enum key: %d" % key)

func test_rarity_colors_values() -> void:
	var common_color: Color = GameConfig.RARITY_COLORS[Enums.SeedRarity.COMMON]
	gut.assert_almost_eq(common_color.r, 0.78, 0.01, "COMMON red channel")
	gut.assert_almost_eq(common_color.g, 0.78, 0.01, "COMMON green channel")
	gut.assert_almost_eq(common_color.b, 0.78, 0.01, "COMMON blue channel")
	
	var uncommon_color: Color = GameConfig.RARITY_COLORS[Enums.SeedRarity.UNCOMMON]
	gut.assert_almost_eq(uncommon_color.r, 0.18, 0.01, "UNCOMMON red channel")
	gut.assert_almost_eq(uncommon_color.g, 0.8, 0.01, "UNCOMMON green channel")
	gut.assert_almost_eq(uncommon_color.b, 0.25, 0.01, "UNCOMMON blue channel")
	
	var rare_color: Color = GameConfig.RARITY_COLORS[Enums.SeedRarity.RARE]
	gut.assert_almost_eq(rare_color.r, 0.25, 0.01, "RARE red channel")
	gut.assert_almost_eq(rare_color.g, 0.52, 0.01, "RARE green channel")
	gut.assert_almost_eq(rare_color.b, 0.96, 0.01, "RARE blue channel")
	
	var epic_color: Color = GameConfig.RARITY_COLORS[Enums.SeedRarity.EPIC]
	gut.assert_almost_eq(epic_color.r, 0.64, 0.01, "EPIC red channel")
	gut.assert_almost_eq(epic_color.g, 0.21, 0.01, "EPIC green channel")
	gut.assert_almost_eq(epic_color.b, 0.93, 0.01, "EPIC blue channel")
	
	var legendary_color: Color = GameConfig.RARITY_COLORS[Enums.SeedRarity.LEGENDARY]
	gut.assert_almost_eq(legendary_color.r, 0.95, 0.01, "LEGENDARY red channel")
	gut.assert_almost_eq(legendary_color.g, 0.77, 0.01, "LEGENDARY green channel")
	gut.assert_almost_eq(legendary_color.b, 0.06, 0.01, "LEGENDARY blue channel")
	
	# Verify all colors are in valid [0.0, 1.0] range
	for color in GameConfig.RARITY_COLORS.values():
		gut.assert_true(color.r >= 0.0 and color.r <= 1.0, "Color R channel out of range")
		gut.assert_true(color.g >= 0.0 and color.g <= 1.0, "Color G channel out of range")
		gut.assert_true(color.b >= 0.0 and color.b <= 1.0, "Color B channel out of range")

func test_get_base_stats_warrior() -> void:
	var stats: Dictionary = GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)
	gut.assert_eq(stats["health"], 120, "WARRIOR get_base_stats health")
	gut.assert_eq(stats["attack"], 18, "WARRIOR get_base_stats attack")
	gut.assert_eq(stats["defense"], 15, "WARRIOR get_base_stats defense")
	gut.assert_eq(stats["speed"], 8, "WARRIOR get_base_stats speed")
	gut.assert_eq(stats["utility"], 5, "WARRIOR get_base_stats utility")

func test_get_base_stats_all_classes() -> void:
	var classes: Array[int] = [
		Enums.AdventurerClass.WARRIOR,
		Enums.AdventurerClass.RANGER,
		Enums.AdventurerClass.MAGE,
		Enums.AdventurerClass.ROGUE,
		Enums.AdventurerClass.ALCHEMIST,
		Enums.AdventurerClass.SENTINEL,
	]
	
	for cls in classes:
		var stats: Dictionary = GameConfig.get_base_stats(cls)
		gut.assert_true(stats.has("health"), "Stats missing health for class %d" % cls)
		gut.assert_true(stats.has("attack"), "Stats missing attack for class %d" % cls)
		gut.assert_true(stats.has("defense"), "Stats missing defense for class %d" % cls)
		gut.assert_true(stats.has("speed"), "Stats missing speed for class %d" % cls)
		gut.assert_true(stats.has("utility"), "Stats missing utility for class %d" % cls)

func test_get_base_stats_returns_duplicate() -> void:
	var stats1: Dictionary = GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)
	var stats2: Dictionary = GameConfig.get_base_stats(Enums.AdventurerClass.WARRIOR)
	
	# Mutate stats1 to verify it's a separate instance
	stats1["health"] = 9999
	
	# stats2 should still have original value
	gut.assert_eq(stats2["health"], 120,
		"get_base_stats should return duplicate; mutations should not affect other instances")
	
	# Verify const dict itself unchanged
	var const_stats: Dictionary = GameConfig.BASE_STATS[Enums.AdventurerClass.WARRIOR]
	gut.assert_eq(const_stats["health"], 120,
		"Const BASE_STATS should not be mutated by get_base_stats caller")
```

---

## 15. Reference Implementation

**File:** `src/models/game_config.gd`

```gdscript
## Game balance configuration constants.
## 
## Provides centralized access to all game tuning parameters sourced from GDD §4.1–4.4.
## All values are compile-time constants (zero runtime allocations).
class_name GameConfig

## Growth time in seconds per seed rarity (GDD §4.1, Table 4.1).
## Higher values slow progression; lower values accelerate it.
const BASE_GROWTH_SECONDS: Dictionary = {
	Enums.SeedRarity.COMMON: 60,
	Enums.SeedRarity.UNCOMMON: 120,
	Enums.SeedRarity.RARE: 300,
	Enums.SeedRarity.EPIC: 600,
	Enums.SeedRarity.LEGENDARY: 1200,
}

## Cumulative XP thresholds per level tier (GDD §4.3, Table 4.3).
## Monotonically increasing; controls pacing of level progression.
const XP_PER_TIER: Dictionary = {
	Enums.LevelTier.NOVICE: 0,
	Enums.LevelTier.SKILLED: 100,
	Enums.LevelTier.VETERAN: 350,
	Enums.LevelTier.ELITE: 750,
}

## Base stat profiles per adventurer class (GDD §4.3, Table 4.2).
## Each entry is a Dictionary with keys: "health", "attack", "defense", "speed", "utility".
## Stat distributions designed around class archetypes (warrior=tanky, mage=utility, etc).
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
		"defense": 10,
		"speed": 15,
		"utility": 10,
	},
	Enums.AdventurerClass.MAGE: {
		"health": 70,
		"attack": 12,
		"defense": 8,
		"speed": 10,
		"utility": 20,
	},
	Enums.AdventurerClass.ROGUE: {
		"health": 75,
		"attack": 16,
		"defense": 8,
		"speed": 18,
		"utility": 12,
	},
	Enums.AdventurerClass.ALCHEMIST: {
		"health": 80,
		"attack": 10,
		"defense": 12,
		"speed": 10,
		"utility": 18,
	},
	Enums.AdventurerClass.SENTINEL: {
		"health": 130,
		"attack": 10,
		"defense": 20,
		"speed": 6,
		"utility": 8,
	},
}

## Mutation slot count per seed rarity (GDD §4.1, Table 4.1).
## Higher rarity = more slots for mutations; affects seed customization depth.
const MUTATION_SLOTS: Dictionary = {
	Enums.SeedRarity.COMMON: 1,
	Enums.SeedRarity.UNCOMMON: 2,
	Enums.SeedRarity.RARE: 3,
	Enums.SeedRarity.EPIC: 4,
	Enums.SeedRarity.LEGENDARY: 5,
}

## Currency generation rates per second (GDD §4.2, Table 4.4).
## Controls passive currency accumulation during gameplay.
## Tuning these values affects economy inflation/deflation.
const CURRENCY_EARN_RATES: Dictionary = {
	Enums.Currency.GOLD: 10,
	Enums.Currency.ESSENCE: 2,
	Enums.Currency.FRAGMENTS: 1,
	Enums.Currency.ARTIFACTS: 0,
}

## Difficulty multiplier per room type (GDD §4.2, Table 4.5).
## Applied to encounter difficulty and resource drops.
## REST=0.0 means no combat scaling for rest rooms.
const ROOM_DIFFICULTY_SCALE: Dictionary = {
	Enums.RoomType.COMBAT: 1.0,
	Enums.RoomType.TREASURE: 0.5,
	Enums.RoomType.TRAP: 0.8,
	Enums.RoomType.PUZZLE: 0.6,
	Enums.RoomType.REST: 0.0,
	Enums.RoomType.BOSS: 2.0,
}

## Growth multiplier per dungeon phase (GDD §4.1, Table 4.1).
## Applied to all growth metrics (seed growth, difficulty, rewards).
## Controls difficulty curve across dungeon progression (SPORE=easy → BLOOM=hard).
const PHASE_GROWTH_MULTIPLIERS: Dictionary = {
	Enums.SeedPhase.SPORE: 1.0,
	Enums.SeedPhase.SPROUT: 1.5,
	Enums.SeedPhase.BUD: 2.0,
	Enums.SeedPhase.BLOOM: 3.0,
}

## Display names for elemental types (GDD §4.4).
## Used in UI for skill descriptions, seed properties, etc.
const ELEMENT_NAMES: Dictionary = {
	Enums.Element.FIRE: "Fire",
	Enums.Element.WATER: "Water",
	Enums.Element.EARTH: "Earth",
	Enums.Element.AIR: "Air",
	Enums.Element.LIGHTNING: "Lightning",
	Enums.Element.NATURE: "Nature",
	Enums.Element.LIGHT: "Light",
	Enums.Element.DARK: "Dark",
}

## Color per rarity tier for UI visualization (GDD §4.1, Table 4.6).
## Used to tint rarity badges, borders, and text in item displays.
const RARITY_COLORS: Dictionary = {
	Enums.SeedRarity.COMMON: Color(0.78, 0.78, 0.78),      # Gray
	Enums.SeedRarity.UNCOMMON: Color(0.18, 0.8, 0.25),    # Green
	Enums.SeedRarity.RARE: Color(0.25, 0.52, 0.96),        # Blue
	Enums.SeedRarity.EPIC: Color(0.64, 0.21, 0.93),        # Purple
	Enums.SeedRarity.LEGENDARY: Color(0.95, 0.77, 0.06),  # Gold
}

## Returns a duplicate of the base stats dictionary for the given adventurer class.
## Returns a new Dictionary (not a reference to the const) to prevent accidental mutation.
static func get_base_stats(cls: Enums.AdventurerClass) -> Dictionary:
	return GameConfig.BASE_STATS[cls].duplicate()
```

---

## 16. Appendix

### GDD Cross-Reference

| Constant | GDD Section | Purpose |
|----------|-------------|---------|
| BASE_GROWTH_SECONDS | §4.1 — Plant Growth Mechanics | Defines growth time per rarity tier; tuned for progression pacing |
| XP_PER_TIER | §4.3 — Level Progression | Defines cumulative XP per tier; gates advancement |
| BASE_STATS | §4.3 — Adventurer Class Balance | Defines starting stats per class; core to game balance |
| MUTATION_SLOTS | §4.1 — Seed Mutation System | Defines mutation capacity per rarity; gating mechanism |
| CURRENCY_EARN_RATES | §4.2 — Economy Parameters | Defines passive currency generation; economy tuning |
| ROOM_DIFFICULTY_SCALE | §4.2 — Encounter Difficulty | Defines difficulty per room type; affects encounters and drops |
| PHASE_GROWTH_MULTIPLIERS | §4.1 — Dungeon Phase Scaling | Defines scaling per phase; controls difficulty curve |
| ELEMENT_NAMES | §4.4 — Element System | Display strings for elements (not gameplay data) |
| RARITY_COLORS | §4.1 — Rarity Visual Identity | Color codes for UI rarity badges (not gameplay data) |

### Value Sourcing Summary

**Numeric values sourced directly from GDD tables:**
- All growth times, XP thresholds, stat values, and rate multipliers come from GDD §4.1–4.3
- Colors match official GDD rarity palette (§4.1)

**Dictionary structure design:**
- Enum-keyed (not string-keyed) for type safety and performance
- Nested dictionaries (BASE_STATS) for multi-attribute entries
- All entries required per FR-025; completeness validated by GUT tests

### Estimated Token Usage

- Code: ~140 lines
- Tests: ~420 lines
- Ticket: ~20KB
- Total: ~30KB

---

*Ticket created: 2025-01 | Parent: TASK-003 | Sibling: TASK-003a | Blocks: TASK-004, TASK-005, TASK-006, TASK-007, TASK-008*
