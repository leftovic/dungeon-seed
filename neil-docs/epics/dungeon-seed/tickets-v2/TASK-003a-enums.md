# TASK-003a: Enums — Game-Wide Enumerations

---

## Section 1 — Header

| Field              | Value                                                                                    |
| ------------------ | ---------------------------------------------------------------------------------------- |
| **Task ID**        | TASK-003a                                                                                |
| **Parent Task**    | TASK-003 (Enums, Constants & Data Dictionary)                                            |
| **Title**          | Enums — Game-Wide Enumerations                                                           |
| **Priority**       | 🔴 P0 — Critical Path                                                                   |
| **Tier**           | Tier 1 — Foundation                                                                      |
| **Complexity**     | 2 points (Trivial)                                                                       |
| **Phase**          | Wave 1 — Data Foundation                                                                 |
| **Stream**         | 🔴 MCH (Mechanics) — Primary                                                            |
| **Cross-Stream**   | ⚪ TCH (data foundation), 🟣 NAR (element/class display names)                          |
| **GDD Reference**  | GDD-v3.md §4.1 (Seeds), §4.2 (Dungeons), §4.3 (Adventurers), §4.4 (Loot & Economy)     |
| **Milestone**      | M1 — Core Data Models                                                                    |
| **Dependencies**   | None — this sub-task has zero upstream dependencies                                      |
| **Dependents**     | TASK-003b (game_config.gd references Enums.*), TASK-004 through TASK-008                 |
| **Critical Path**  | ✅ YES — TASK-003b and all Wave 2 tasks are blocked until this merges                    |
| **Estimated Hours**| 1–1.5 hours                                                                              |
| **Engine**         | Godot 4.5 — GDScript                                                                     |
| **Output Files**   | `src/models/enums.gd`, `tests/models/test_enums.gd`                                     |

---

## Section 2 — Description

### 2.1 — What This Sub-Task Produces

This sub-task creates a single foundational GDScript file containing every game-wide enumeration for Dungeon Seed:

**`src/models/enums.gd`** (`class_name Enums`) — Ten enums covering seed rarity, elemental affinity, seed growth phases, dungeon room types, adventurer classes, level tiers, item rarity, equipment slots, currency types, and expedition statuses. Plus five static helper methods that return human-readable display names for key enums.

This file is pure data — zero runtime state, zero allocations beyond initial parse, zero side effects. It exists so every downstream system can import a single symbol (`Enums.SeedRarity.COMMON`) instead of scattering magic strings and magic numbers.

### 2.2 — Why Centralized Enums Matter

Without a single source of truth for enumerations:
- **Magic string rot**: `rarity == "common"` vs `rarity == "Common"` vs `rarity == 0` — no compile-time protection
- **Refactor fragility**: Renaming a room type requires codebase-wide find-and-replace with no compiler assistance
- **Type safety erosion**: `var rarity: Enums.SeedRarity` gives editor autocomplete, linter type checking, and developer confidence

By consolidating all enums into `enums.gd`, we gain compile-time type safety, IDE autocomplete, and grep-friendly naming.

### 2.3 — Technical Architecture

```
src/models/enums.gd (class_name Enums)
├── §4.1 Seed Enums: SeedRarity, Element, SeedPhase
├── §4.2 Dungeon Enums: RoomType, ExpeditionStatus
├── §4.3 Adventurer Enums: AdventurerClass, LevelTier, EquipSlot
├── §4.4 Economy Enums: ItemRarity, Currency
└── Helper Methods: seed_rarity_name(), item_rarity_name(),
    adventurer_class_name(), element_name(), equip_slot_name()
```

### 2.4 — Downstream Dependency Map

```
TASK-003a (enums.gd)
├── TASK-003b (game_config.gd) — dict keys are Enums.* values
├── TASK-004 (Seed Data Model) — SeedRarity, Element, SeedPhase
├── TASK-005 (Dungeon Room Graph) — RoomType
├── TASK-006 (Adventurer Data Model) — AdventurerClass, LevelTier
├── TASK-007 (Item & Equipment Models) — ItemRarity, EquipSlot
└── TASK-008 (Economy Wallet) — Currency
```

### 2.5 — Design Decisions

1. **No `extends` statement**: Implicitly extends `RefCounted`. No `extends Node` — not an autoload.
2. **`class_name Enums`**: Enables static access (`Enums.SeedRarity.COMMON`) without `preload()`.
3. **`Element` includes `NONE`**: Added for seeds/items that have no elemental affinity (unaligned). Values 0-4 are the five elements; NONE=5.
4. **`EquipSlot` includes `NONE = -1`**: Indicates non-equippable items (quest items, materials). WEAPON=0, ARMOR=1, ACCESSORY=2.
5. **Helper methods are `static func`**: No instance needed — callable as `Enums.seed_rarity_name(rarity)`.
6. **All helpers include `_` wildcard branch**: Returns `"Unknown"` with `push_warning()` for invalid values.

---

## Section 3 — Use Cases

### UC-001: Developer References Enums in Downstream Code

**Actor:** Developer implementing TASK-004 (Seed Data Model)
**Flow:** Developer types `var rarity: Enums.SeedRarity` → Godot editor provides autocomplete → misspelling `Enums.SeedRarity.COMON` is caught at parse time, not runtime.
**Postcondition:** Type-safe enum usage with IDE support and compile-time error detection.

### UC-002: UI Displays Element Names

**Actor:** Developer implementing seed tooltip UI
**Flow:** Calls `Enums.element_name(Enums.Element.FROST)` → gets `"Frost"` → displays in tooltip. No string literals in UI code.
**Postcondition:** Display names are centralized and consistent.

### UC-003: Match Statement Covers All Room Types

**Actor:** Developer implementing dungeon logic
**Flow:** Writes `match room_type:` covering all 6 `RoomType` values. Includes `_` wildcard for future safety. If a value is forgotten, GUT tests on `RoomType.size()` catch it.
**Postcondition:** Exhaustive enum handling with safety nets.

---

## Section 4 — Glossary

| Term               | Definition                                                                                          |
| ------------------ | --------------------------------------------------------------------------------------------------- |
| **enum**           | GDScript enumeration — named set of integer constants. Provides type safety and IDE autocomplete.   |
| **class_name**     | GDScript directive registering a script as a globally accessible type without `preload()`.          |
| **RefCounted**     | Godot's default base class for scripts without `extends`. Reference-counted, garbage-collected.     |
| **static typing**  | GDScript feature where variables declare their type: `var r: Enums.SeedRarity`.                     |
| **static func**    | A method callable on the class itself without instantiation: `Enums.seed_rarity_name(rarity)`.      |
| **GUT**            | Godot Unit Testing framework. Test files extend `GutTest`.                                          |
| **magic string**   | Hardcoded string literal for comparison — fragile. `if rarity == "rare"` vs `Enums.SeedRarity.RARE`.|
| **push_warning**   | Godot built-in that logs a warning without crashing. Used for unknown enum values in helpers.        |
| **mutation slot**   | A slot on a seed where a random mutation can be applied during growth.                              |
| **seed phase**      | Growth stages: Spore → Sprout → Bud → Bloom. Each phase unlocks new capabilities.                 |
| **level tier**      | Adventurer progression bracket: Novice (0 XP), Skilled (100), Veteran (350), Elite (750).          |

---

## Section 5 — Out of Scope

| #  | Excluded Item                                        | Reason                                                                     |
| -- | ---------------------------------------------------- | -------------------------------------------------------------------------- |
| 1  | `game_config.gd` (balance constants)                 | Covered by TASK-003b.                                                      |
| 2  | Runtime config modification                          | All values are compile-time enums. No runtime mutation.                    |
| 3  | Enum serialization/deserialization helpers            | Belongs to TASK-009 (Serialization).                                       |
| 4  | Localization of display names                        | Helpers return English strings only. i18n is a future concern.             |
| 5  | Enum bitflags / bitmask combinations                 | No enum is used as a bitfield.                                             |
| 6  | Additional helper methods beyond the five specified   | `seed_rarity_name`, `item_rarity_name`, `adventurer_class_name`, `element_name`, `equip_slot_name` only. |
| 7  | Validation methods (is_valid_seed_rarity, etc.)       | Range validation belongs to deserialization in TASK-009.                   |
| 8  | Enum documentation beyond `##` doc comments           | No external docs required for this tier.                                  |

---

## Section 6 — Functional Requirements

### enums.gd — Enum Declarations

| ID     | Requirement                                                                                                                    | GDD Ref | Testable |
| ------ | ------------------------------------------------------------------------------------------------------------------------------ | ------- | -------- |
| FR-001 | `enums.gd` declares `class_name Enums` at the top of the file.                                                                | —       | ✅       |
| FR-002 | `enum SeedRarity` contains exactly: `COMMON, UNCOMMON, RARE, EPIC, LEGENDARY` (values 0–4).                                   | §4.1    | ✅       |
| FR-003 | `enum Element` contains exactly: `TERRA, FLAME, FROST, ARCANE, SHADOW, NONE` (values 0–5).                                    | §4.1    | ✅       |
| FR-004 | `enum SeedPhase` contains exactly: `SPORE, SPROUT, BUD, BLOOM` (values 0–3).                                                  | §4.1    | ✅       |
| FR-005 | `enum RoomType` contains exactly: `COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS` (values 0–5).                                  | §4.2    | ✅       |
| FR-006 | `enum AdventurerClass` contains exactly: `WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL` (values 0–5).                    | §4.3    | ✅       |
| FR-007 | `enum LevelTier` contains exactly: `NOVICE, SKILLED, VETERAN, ELITE` (values 0–3).                                            | §4.3    | ✅       |
| FR-008 | `enum ItemRarity` contains exactly: `COMMON, UNCOMMON, RARE, EPIC, LEGENDARY` (values 0–4).                                   | §4.4    | ✅       |
| FR-009 | `enum EquipSlot` contains exactly: `NONE = -1, WEAPON = 0, ARMOR = 1, ACCESSORY = 2`.                                         | §4.3    | ✅       |
| FR-010 | `enum Currency` contains exactly: `GOLD, ESSENCE, FRAGMENTS, ARTIFACTS` (values 0–3).                                         | §4.4    | ✅       |
| FR-011 | `enum ExpeditionStatus` contains exactly: `PREPARING, IN_PROGRESS, COMPLETED, FAILED` (values 0–3).                           | §4.2    | ✅       |
| FR-012 | No two enums share the same name within the `Enums` class (no compilation ambiguity).                                          | —       | ✅       |

### enums.gd — Helper Methods

| ID     | Requirement                                                                                                                    | GDD Ref | Testable |
| ------ | ------------------------------------------------------------------------------------------------------------------------------ | ------- | -------- |
| FR-013 | `static func seed_rarity_name(rarity: SeedRarity) -> String` returns the Title-Case name for all 5 rarity values.              | —       | ✅       |
| FR-014 | `static func item_rarity_name(rarity: ItemRarity) -> String` returns the Title-Case name for all 5 rarity values.              | —       | ✅       |
| FR-015 | `static func adventurer_class_name(cls: AdventurerClass) -> String` returns the Title-Case name for all 6 class values.        | —       | ✅       |
| FR-016 | `static func element_name(element: Element) -> String` returns the Title-Case name for all 6 element values (including "None").| —       | ✅       |
| FR-017 | `static func equip_slot_name(slot: EquipSlot) -> String` returns the Title-Case name for all 4 slot values (including "None"). | —       | ✅       |
| FR-018 | All helper methods include a `_` wildcard branch that calls `push_warning()` and returns `"Unknown"`.                          | —       | ✅       |

---

## Section 7 — Non-Functional Requirements

| ID      | Category       | Requirement                                                                                                    |
| ------- | -------------- | -------------------------------------------------------------------------------------------------------------- |
| NFR-001 | Maintainability| Every enum and helper method has a `##` doc comment explaining its purpose and GDD reference.                  |
| NFR-002 | Maintainability| File is under 200 lines, with clear section separators between logical groups.                                 |
| NFR-003 | Type Safety    | Every parameter and return type uses explicit GDScript type hints (`: SeedRarity`, `-> String`).               |
| NFR-004 | Type Safety    | Enum values are accessed via qualified names (`Enums.SeedRarity.COMMON`), never as raw ints.                  |
| NFR-005 | Compatibility  | File compiles without warnings in Godot 4.5 with GDScript strict mode enabled.                                |
| NFR-006 | Compatibility  | File is usable via `class_name` without requiring autoload registration.                                      |
| NFR-007 | Code Quality   | No circular dependencies — enums.gd depends on nothing.                                                       |
| NFR-008 | Determinism    | All values are deterministic across runs. No `randf()`, no external data sources.                             |
| NFR-009 | Testing        | GUT test suite achieves 100% coverage of all enum values and all helper method return values.                 |
| NFR-010 | Testing        | GUT test suite runs in under 200 ms.                                                                          |

---

## Section 8 — Designer's Manual

### 8.1 — How to Add a New Enum Value

**Example: Adding `Element.VOID`**

1. Open `src/models/enums.gd`.
2. Find `enum Element { TERRA, FLAME, FROST, ARCANE, SHADOW, NONE }`.
3. Insert the new value **before NONE** (NONE should remain last as the "null" sentinel):
   ```gdscript
   enum Element { TERRA, FLAME, FROST, ARCANE, SHADOW, VOID, NONE }
   ```
4. Update `element_name()` helper to handle the new value.
5. Open `src/models/game_config.gd` and add the new element to every dictionary keyed by `Element` (e.g., `ELEMENT_NAMES`).
6. Run tests. The completeness tests will flag any dictionary missing the new key.

**Rules:**
- Always append new values at the end (before sentinel values like NONE).
- Never reorder existing values — this shifts integers and breaks saved data.
- Every new enum value must get corresponding entries in all GameConfig dictionaries keyed by that enum.

### 8.2 — Naming Conventions

| Entity           | Convention       | Example                            |
| ---------------- | ---------------- | ---------------------------------- |
| Enum type name   | PascalCase       | `SeedRarity`, `AdventurerClass`    |
| Enum value       | UPPER_SNAKE_CASE | `COMMON`, `IN_PROGRESS`            |
| Helper method    | snake_case       | `seed_rarity_name()`, `element_name()` |
| Doc comment      | `##` prefix      | `## Growth phases a seed passes through` |

### 8.3 — How Downstream Code Uses Enums

```gdscript
# Type-safe variable declaration:
var rarity: Enums.SeedRarity = Enums.SeedRarity.COMMON

# Match statement with exhaustive handling:
match rarity:
    Enums.SeedRarity.COMMON: pass
    Enums.SeedRarity.UNCOMMON: pass
    _: push_warning("Unhandled rarity: %d" % rarity)

# Display name for UI:
var name: String = Enums.seed_rarity_name(rarity)  # "Common"
```

---

## Section 9 — Assumptions

| #  | Assumption                                                                                          | Risk if Wrong                                                      |
| -- | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| 1  | Godot 4.5 supports `class_name` for static-only scripts without `extends Node`.                    | Would need autoload instead. Low risk — works in 4.x.              |
| 2  | Enum integer values auto-increment from 0 when not explicitly assigned.                             | Would need explicit values. Godot guarantees this behavior.        |
| 3  | GDD values listed in parent TASK-003 are final and approved for MVP.                                | If GDD changes, enum values must be updated to match.              |
| 4  | Five rarity tiers (Common–Legendary) are sufficient for MVP.                                        | Adding a 6th tier is an append-only change — low risk.             |
| 5  | Six elements (Terra, Flame, Frost, Arcane, Shadow, None) are sufficient for MVP.                    | New elements can be appended before NONE.                          |
| 6  | Six adventurer classes are sufficient for MVP.                                                       | New classes follow the same append pattern.                        |
| 7  | `EquipSlot.NONE = -1` is needed for non-equippable items.                                          | If not needed, remove NONE and shift values.                       |
| 8  | GUT framework is available and configured before this task begins.                                  | TASK-001 or TASK-002 must set up GUT first.                        |
| 9  | The directory `src/models/` exists or will be created as part of this task.                          | Create with `mkdir -p` equivalent if needed.                       |
| 10 | `Element.NONE` and `EquipSlot.NONE` are needed by downstream systems for null-safe sentinel values. | If not, they can be removed — append-only principle still holds.   |

---

## Section 10 — Security & Anti-Cheat Considerations

### THREAT-001: Memory Editing of Enum Values

**Attack Vector:** Player uses Cheat Engine to change an enum value in RAM (e.g., `SeedRarity.COMMON` → `SeedRarity.LEGENDARY` by overwriting 0 → 4).
**Impact:** Player obtains Legendary-tier benefits from a Common seed.
**Mitigation (Current Scope):** Enum definitions themselves are read-only in the GDScript VM. Protection of runtime game state belongs to save/load validation (TASK-009).

### THREAT-002: Enum Value Injection via Deserialization

**Attack Vector:** Tampered save file contains enum integer outside valid range (e.g., `SeedRarity = 99`).
**Impact:** Match statements without `_` branch produce undefined behavior; dictionary lookups return `null`.
**Mitigation:** All helper methods include `_` wildcard branches. Primary deserialization validation belongs to TASK-009.

---

## Section 11 — Best Practices

| #  | Practice                                                                                                              |
| -- | --------------------------------------------------------------------------------------------------------------------- |
| 1  | **Always use qualified enum names**: `Enums.SeedRarity.COMMON`, never `0` or bare `SeedRarity.COMMON`.                |
| 2  | **Append-only enum evolution**: New values go at the end. Never insert in the middle.                                 |
| 3  | **One enum per concept**: `SeedRarity` and `ItemRarity` are separate even with same values — prevents coupling.       |
| 4  | **Type-hint everything**: Parameters, return types, variables — always use explicit type hints.                        |
| 5  | **Doc comment every enum**: Use `##` for docs, `#` for implementation notes.                                          |
| 6  | **Match exhaustiveness**: Every `match` on an enum should cover all values or include `_` wildcard.                   |
| 7  | **No logic in data files**: `enums.gd` contains definitions and trivial name lookups only. No algorithms, no state.   |
| 8  | **Test every value**: GUT suite must explicitly assert every enum value's integer assignment.                          |

---

## Section 12 — Troubleshooting

### Issue 1: "Identifier not found" When Referencing Enums

**Symptom:** `Enums.SeedRarity.COMMON` → parser error: `Identifier "Enums" not declared`.
**Cause:** `class_name Enums` is missing/misspelled, or file has a parse error.
**Fix:** Verify `enums.gd` starts with `class_name Enums` (capital E). Restart Godot editor if `class_name` was just added.

### Issue 2: Enum Values Shifted After Inserting in Middle

**Symptom:** Old save files load with wrong enum values.
**Cause:** Inserting a value in the middle of an enum shifts all subsequent integer values.
**Fix:** Never insert — always append. If reorder is necessary, implement save migration in TASK-009.

### Issue 3: Helper Returns "Unknown" Unexpectedly

**Symptom:** `Enums.seed_rarity_name(some_value)` returns `"Unknown"`.
**Cause:** `some_value` is not a valid `SeedRarity` enum value (possibly a raw int from deserialization).
**Fix:** Check the source of `some_value`. Ensure it's cast to `Enums.SeedRarity` type. Check `push_warning()` output in Godot console.

---

## Section 13 — Acceptance Criteria

### Enum Declaration ACs

- [ ] AC-001: File `src/models/enums.gd` exists and begins with `class_name Enums`.
- [ ] AC-002: `Enums.SeedRarity` has exactly 5 values: COMMON=0, UNCOMMON=1, RARE=2, EPIC=3, LEGENDARY=4.
- [ ] AC-003: `Enums.Element` has exactly 6 values: TERRA=0, FLAME=1, FROST=2, ARCANE=3, SHADOW=4, NONE=5.
- [ ] AC-004: `Enums.SeedPhase` has exactly 4 values: SPORE=0, SPROUT=1, BUD=2, BLOOM=3.
- [ ] AC-005: `Enums.RoomType` has exactly 6 values: COMBAT=0, TREASURE=1, TRAP=2, PUZZLE=3, REST=4, BOSS=5.
- [ ] AC-006: `Enums.AdventurerClass` has exactly 6 values: WARRIOR=0, RANGER=1, MAGE=2, ROGUE=3, ALCHEMIST=4, SENTINEL=5.
- [ ] AC-007: `Enums.LevelTier` has exactly 4 values: NOVICE=0, SKILLED=1, VETERAN=2, ELITE=3.
- [ ] AC-008: `Enums.ItemRarity` has exactly 5 values: COMMON=0, UNCOMMON=1, RARE=2, EPIC=3, LEGENDARY=4.
- [ ] AC-009: `Enums.EquipSlot` has exactly 4 values: NONE=-1, WEAPON=0, ARMOR=1, ACCESSORY=2.
- [ ] AC-010: `Enums.Currency` has exactly 4 values: GOLD=0, ESSENCE=1, FRAGMENTS=2, ARTIFACTS=3.
- [ ] AC-011: `Enums.ExpeditionStatus` has exactly 4 values: PREPARING=0, IN_PROGRESS=1, COMPLETED=2, FAILED=3.

### Helper Method ACs

- [ ] AC-012: `Enums.seed_rarity_name()` returns correct Title-Case name for all 5 SeedRarity values.
- [ ] AC-013: `Enums.item_rarity_name()` returns correct Title-Case name for all 5 ItemRarity values.
- [ ] AC-014: `Enums.adventurer_class_name()` returns correct Title-Case name for all 6 AdventurerClass values.
- [ ] AC-015: `Enums.element_name()` returns correct Title-Case name for all 6 Element values (including "None").
- [ ] AC-016: `Enums.equip_slot_name()` returns correct Title-Case name for all 4 EquipSlot values (including "None").
- [ ] AC-017: All helpers return `"Unknown"` for invalid input values.

### Quality ACs

- [ ] AC-018: File compiles without errors or warnings in Godot 4.5.
- [ ] AC-019: Every enum and helper has `##` doc comments.
- [ ] AC-020: All GUT tests pass with 100% enum value coverage.
- [ ] AC-021: File is under 200 lines.

---

## Section 14 — Test Implementations

```gdscript
## tests/models/test_enums.gd
## GUT test suite for TASK-003a: Enums (enums.gd)
## Covers: all 10 enums + all 5 helper methods
extends GutTest


# ---------------------------------------------------------------------------
# Section A: Enum Value and Count Tests
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
	assert_eq(Enums.Element.NONE, 5, "Element.NONE should be 5")


func test_element_count() -> void:
	assert_eq(Enums.Element.size(), 6, "Element should have exactly 6 values (including NONE)")


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
	assert_eq(Enums.EquipSlot.NONE, -1, "EquipSlot.NONE should be -1")
	assert_eq(Enums.EquipSlot.WEAPON, 0, "EquipSlot.WEAPON should be 0")
	assert_eq(Enums.EquipSlot.ARMOR, 1, "EquipSlot.ARMOR should be 1")
	assert_eq(Enums.EquipSlot.ACCESSORY, 2, "EquipSlot.ACCESSORY should be 2")


func test_equip_slot_count() -> void:
	assert_eq(Enums.EquipSlot.size(), 4, "EquipSlot should have exactly 4 values (NONE, WEAPON, ARMOR, ACCESSORY)")


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
# Section B: Helper Method Tests
# ---------------------------------------------------------------------------

func test_seed_rarity_name_all() -> void:
	assert_eq(Enums.seed_rarity_name(Enums.SeedRarity.COMMON), "Common")
	assert_eq(Enums.seed_rarity_name(Enums.SeedRarity.UNCOMMON), "Uncommon")
	assert_eq(Enums.seed_rarity_name(Enums.SeedRarity.RARE), "Rare")
	assert_eq(Enums.seed_rarity_name(Enums.SeedRarity.EPIC), "Epic")
	assert_eq(Enums.seed_rarity_name(Enums.SeedRarity.LEGENDARY), "Legendary")


func test_item_rarity_name_all() -> void:
	assert_eq(Enums.item_rarity_name(Enums.ItemRarity.COMMON), "Common")
	assert_eq(Enums.item_rarity_name(Enums.ItemRarity.UNCOMMON), "Uncommon")
	assert_eq(Enums.item_rarity_name(Enums.ItemRarity.RARE), "Rare")
	assert_eq(Enums.item_rarity_name(Enums.ItemRarity.EPIC), "Epic")
	assert_eq(Enums.item_rarity_name(Enums.ItemRarity.LEGENDARY), "Legendary")


func test_adventurer_class_name_all() -> void:
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.WARRIOR), "Warrior")
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.RANGER), "Ranger")
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.MAGE), "Mage")
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.ROGUE), "Rogue")
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.ALCHEMIST), "Alchemist")
	assert_eq(Enums.adventurer_class_name(Enums.AdventurerClass.SENTINEL), "Sentinel")


func test_element_name_all() -> void:
	assert_eq(Enums.element_name(Enums.Element.TERRA), "Terra")
	assert_eq(Enums.element_name(Enums.Element.FLAME), "Flame")
	assert_eq(Enums.element_name(Enums.Element.FROST), "Frost")
	assert_eq(Enums.element_name(Enums.Element.ARCANE), "Arcane")
	assert_eq(Enums.element_name(Enums.Element.SHADOW), "Shadow")
	assert_eq(Enums.element_name(Enums.Element.NONE), "None")


func test_equip_slot_name_all() -> void:
	assert_eq(Enums.equip_slot_name(Enums.EquipSlot.NONE), "None")
	assert_eq(Enums.equip_slot_name(Enums.EquipSlot.WEAPON), "Weapon")
	assert_eq(Enums.equip_slot_name(Enums.EquipSlot.ARMOR), "Armor")
	assert_eq(Enums.equip_slot_name(Enums.EquipSlot.ACCESSORY), "Accessory")
```

### Test Execution Matrix

| Test Function                        | Type | What It Verifies                         | Expected Result  |
| ------------------------------------ | ---- | ---------------------------------------- | ---------------- |
| `test_seed_rarity_values`            | Unit | Integer values 0-4 assigned correctly    | All assertions pass |
| `test_seed_rarity_count`             | Unit | Exactly 5 values in enum                 | size() == 5      |
| `test_element_values`                | Unit | Integer values 0-5 assigned correctly    | All assertions pass |
| `test_element_count`                 | Unit | Exactly 6 values (including NONE)        | size() == 6      |
| `test_seed_phase_values`             | Unit | Integer values 0-3 assigned correctly    | All assertions pass |
| `test_seed_phase_count`              | Unit | Exactly 4 values                         | size() == 4      |
| `test_room_type_values`              | Unit | Integer values 0-5 assigned correctly    | All assertions pass |
| `test_room_type_count`               | Unit | Exactly 6 values                         | size() == 6      |
| `test_adventurer_class_values`       | Unit | Integer values 0-5 assigned correctly    | All assertions pass |
| `test_adventurer_class_count`        | Unit | Exactly 6 values                         | size() == 6      |
| `test_level_tier_values`             | Unit | Integer values 0-3 assigned correctly    | All assertions pass |
| `test_level_tier_count`              | Unit | Exactly 4 values                         | size() == 4      |
| `test_item_rarity_values`            | Unit | Integer values 0-4 assigned correctly    | All assertions pass |
| `test_item_rarity_count`             | Unit | Exactly 5 values                         | size() == 5      |
| `test_equip_slot_values`             | Unit | NONE=-1, WEAPON=0, ARMOR=1, ACCESSORY=2 | All assertions pass |
| `test_equip_slot_count`              | Unit | Exactly 4 values                         | size() == 4      |
| `test_currency_values`               | Unit | Integer values 0-3 assigned correctly    | All assertions pass |
| `test_currency_count`                | Unit | Exactly 4 values                         | size() == 4      |
| `test_expedition_status_values`      | Unit | Integer values 0-3 assigned correctly    | All assertions pass |
| `test_expedition_status_count`       | Unit | Exactly 4 values                         | size() == 4      |
| `test_seed_rarity_name_all`          | Unit | All 5 display names correct              | Title-case strings |
| `test_item_rarity_name_all`          | Unit | All 5 display names correct              | Title-case strings |
| `test_adventurer_class_name_all`     | Unit | All 6 display names correct              | Title-case strings |
| `test_element_name_all`              | Unit | All 6 display names correct (incl. None) | Title-case strings |
| `test_equip_slot_name_all`           | Unit | All 4 display names correct (incl. None) | Title-case strings |

---

## Section 15 — Reference Implementation

```gdscript
## src/models/enums.gd
## Centralized game-wide enumerations for Dungeon Seed.
## All enums are drawn directly from GDD-v3.md.
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
## NONE indicates no elemental affinity (unaligned).
## GDD Reference: §4.1 (Seed System — Elemental Affinity)
enum Element { TERRA, FLAME, FROST, ARCANE, SHADOW, NONE }

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
## NONE = -1 indicates a non-equippable item (quest items, materials, etc.).
## GDD Reference: §4.3 (Adventurer System — Equipment)
enum EquipSlot { NONE = -1, WEAPON = 0, ARMOR = 1, ACCESSORY = 2 }


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
		Element.NONE:
			return "None"
		_:
			push_warning("Unknown Element value: %d" % element)
			return "Unknown"


## Returns the human-readable display name for an EquipSlot value.
## Example: Enums.equip_slot_name(Enums.EquipSlot.WEAPON) -> "Weapon"
static func equip_slot_name(slot: EquipSlot) -> String:
	match slot:
		EquipSlot.NONE:
			return "None"
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

### Implementation Notes

1. **File creation**: Create `src/models/enums.gd` first. Create `src/models/` directory if it doesn't exist.
2. **No `extends` statement**: Implicitly extends `RefCounted`. Do NOT add `extends Node`.
3. **`class_name Enums`** is mandatory — without it, other scripts cannot reference `Enums.*` without `preload()`.
4. **`Element.NONE`**: Added as value 5 (after SHADOW) for seeds/items with no elemental affinity.
5. **`EquipSlot.NONE = -1`**: Explicitly set to -1 so equippable slots remain 0-indexed. Used for non-equippable items.
6. **All helpers include `_` wildcard**: Returns `"Unknown"` and calls `push_warning()` for invalid values.
7. **Test file location**: `tests/models/test_enums.gd` (separate from game_config tests in TASK-003b).

---

## Section 16 — Appendix

### Enum Value Summary Table

| Enum             | Values                                                        | Count | Int Range |
| ---------------- | ------------------------------------------------------------- | ----- | --------- |
| SeedRarity       | COMMON, UNCOMMON, RARE, EPIC, LEGENDARY                      | 5     | 0–4       |
| Element          | TERRA, FLAME, FROST, ARCANE, SHADOW, NONE                    | 6     | 0–5       |
| SeedPhase        | SPORE, SPROUT, BUD, BLOOM                                    | 4     | 0–3       |
| RoomType         | COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS                   | 6     | 0–5       |
| ExpeditionStatus | PREPARING, IN_PROGRESS, COMPLETED, FAILED                    | 4     | 0–3       |
| AdventurerClass  | WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL            | 6     | 0–5       |
| LevelTier        | NOVICE, SKILLED, VETERAN, ELITE                               | 4     | 0–3       |
| EquipSlot        | NONE, WEAPON, ARMOR, ACCESSORY                                | 4     | -1–2      |
| ItemRarity       | COMMON, UNCOMMON, RARE, EPIC, LEGENDARY                      | 5     | 0–4       |
| Currency         | GOLD, ESSENCE, FRAGMENTS, ARTIFACTS                           | 4     | 0–3       |

### Deviations from Parent TASK-003

| Deviation | Parent TASK-003 Spec | TASK-003a Spec | Reason |
| --------- | -------------------- | -------------- | ------ |
| Element.NONE | Not present (5 values) | Present (6 values, NONE=5) | Downstream systems need a null-safe sentinel for unaligned seeds/items |
| EquipSlot.NONE | Not present (3 values, 0-2) | Present (4 values, NONE=-1) | Non-equippable items (quest items, materials) need a sentinel slot |
| Helper count | 5 helpers in parent FR-023 | 5 helpers (FR-013 through FR-017) | Same count, explicitly enumerated |

---

*End of TASK-003a: Enums — Game-Wide Enumerations*
