# TASK-003a: Enums — Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-003a-enums.md`  
> **Status**: Planning  
> **Created**: 2026-03-31  
> **Branch**: `users/{alias}/task-003a-enums`  
> **Repo**: `C:\Users\wrstl\source\dev-agent-tool` (Godot 4.5, GDScript)  
> **Methodology**: TDD Red-Green-Refactor (GUT test framework)  
> **Complexity**: 2 points (Trivial)  
> **Estimated Phases**: 3  
> **Type**: Validation + Refactoring (NOT greenfield — existing code in `src/models/enums.gd` and `tests/models/test_enums_and_config.gd`)

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents in this order:

1. **This file** — the implementation checklist (you're reading it)
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-003a-enums.md`** — the full technical spec
3. **Existing source code** — validate against spec:
   - `src/models/enums.gd` — the enum definitions (already exists)
   - `tests/models/test_enums_and_config.gd` — the test suite (already exists)

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| Enum source | `src/models/enums.gd` | 10 enums + 5 helper methods — **ALREADY EXISTS**, validate against TASK-003a FR-001 through FR-017 |
| Test file | `tests/models/test_enums_and_config.gd` | GUT tests covering enums + game_config — **ALREADY EXISTS**, extract TASK-003a tests (Section A, B, D of test file) |
| GDD reference | `neil-docs/epics/dungeon-seed/GDD-v3.md` | §4.1 (Seeds), §4.2 (Dungeons), §4.3 (Adventurers), §4.4 (Loot & Economy) |
| Ticket | `neil-docs/epics/dungeon-seed/tickets-v2/TASK-003a-enums.md` | Full 16-section specification |

### Build & Test Commands

```powershell
# Verify Godot project loads (from project root)
godot --headless --debug-script -- --test-only

# Run GUT tests (enum-specific tests extracted from test_enums_and_config.gd)
godot -d -s addons/gut/gut_cmdline.gd -gdir=tests/models/

# Validate no parse errors in enums.gd
godot --check-only --headless

# Verify enum values and helper methods match ticket spec
# (Run GUT subset targeting TASK-003a tests only)
```

### Regression Gate (MUST PASS BEFORE AND AFTER EVERY CHANGE)

- [ ] **R.1**: `src/models/enums.gd` compiles with zero parse errors/warnings
- [ ] **R.2**: All GUT tests in `test_enums_and_config.gd` Section A, B, D pass (24 test functions, ~50+ assertions)
- [ ] **R.3**: All 10 enum values are accessible via qualified names (e.g., `Enums.SeedRarity.COMMON`)
- [ ] **R.4**: No downstream files break after running tests (check editor error console)

### Current State (Baseline)

**Existing Code Status:**
- `src/models/enums.gd` — **EXISTS** with 10 enums + 5 helpers, lines 1-172
- `tests/models/test_enums_and_config.gd` — **EXISTS** with 485 lines covering both enums + game_config
- All 10 enums are defined and have helper methods
- Test file includes TASK-003a tests (lines 11-113, 341-416 approximately)

**What This Plan Does:**
- Phase 1: Validate existing code against TASK-003a spec (FR-001 through FR-017)
- Phase 2: Fix any deviations found (if enum definitions or helpers don't match spec)
- Phase 3: Confirm all tests pass with final code

**Non-Greenfield Approach:**
- NO creation of new files — validation and optional fixes only
- Run existing tests first to establish baseline
- Make targeted corrections if spec violations exist
- Mark deviations in Deviation Tracking section

---

## TDD Methodology Reference

**ALL implementation work follows strict TDD.** No exceptions.

### The Cycle (Red → Green → Refactor)

1. **RED**: Test must fail first (confirms the test is real)
   - If test already passes, you don't need to write code
   - If code exists and test passes, move to validation/refactoring

2. **GREEN**: Make the test pass with minimum code
   - In this task: verify existing code makes tests pass
   - If it doesn't: fix the code to match spec

3. **REFACTOR**: Clean up while keeping tests green
   - Improve doc comments, section headers, consistency
   - Run tests after each refactor

### For This Validation Task

- **Write no new tests** — GUT tests already exist in `test_enums_and_config.gd`
- **Run the existing tests** — establish baseline of what's passing
- **Fix code to match ticket spec** — if existing implementation diverges
- **Verify 100% coverage** — all 10 enums, all 5 helpers, all acceptance criteria

---

## Current State Analysis

### What Exists Today

| Component | Location | Status | Notes |
|-----------|----------|--------|-------|
| 10 enums | `src/models/enums.gd` lines 17-71 | ✅ Exists | SeedRarity, Element, SeedPhase, RoomType, AdventurerClass, LevelTier, ItemRarity, EquipSlot, Currency, ExpeditionStatus |
| 5 helpers | `src/models/enums.gd` lines 78-172 | ✅ Exists | `seed_rarity_name()`, `item_rarity_name()`, `adventurer_class_name()`, `element_name()`, `equip_slot_name()` |
| Test suite | `tests/models/test_enums_and_config.gd` lines 1-485 | ✅ Exists | Section A (enum values/counts), Section B (game_config), Section D (helpers) |
| `class_name Enums` | `src/models/enums.gd` line 8 | ✅ Exists | Top-level directive enables static access |

### What Will Be Validated

| Item | Check | Ticket Ref |
|------|-------|-----------|
| Enum declarations | Verify all 10 enums exist with correct values | FR-001 through FR-011 |
| Helper methods | Verify 5 helpers exist, return Title-Case names | FR-013 through FR-017 |
| Wildcard branches | Verify all helpers include `_` branch with `push_warning()` | FR-018 |
| Doc comments | Verify `##` comments on all enums and helpers | NFR-001 |
| File size | Verify under 200 lines | NFR-002 |
| Type hints | Verify all parameters and returns are typed | NFR-003 |
| Compilation | Verify zero parse errors in Godot 4.5 | NFR-005 |
| Test coverage | Verify GUT tests cover 100% of enum values and helpers | NFR-009 |

### Regression Boundaries (What Must NOT Change)

- ✅ All downstream code that imports `Enums` must continue to work
- ✅ No enum values may shift (appending only allowed)
- ✅ All helper method signatures must remain stable
- ✅ Test names and assertions must remain as-is (part of spec)

---

## Phase Dependency Graph

```
Phase 1 (Validation) ──→ Phase 2 (Fix) ──→ Phase 3 (Final Verification)
                              ↓
                     (only if deviations found)
```

---

## Phase 1: Enum Declaration Validation

> **Ticket References**: FR-001 through FR-011, AC-001 through AC-011  
> **Estimated Items**: 14  
> **Dependencies**: None  
> **Validation Gate**: All 10 enums exist, values match spec, no parse errors

### 1.1 Validate SeedRarity Enum

- [ ] **1.1.1** Open `src/models/enums.gd` and locate `enum SeedRarity`
  - _Ticket ref: FR-002, AC-002_
  - _File: `src/models/enums.gd` line ~17_
  - _Check: Verify declaration is `enum SeedRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }`_

- [ ] **1.1.2** Verify `SeedRarity` values are 0–4 (implicit auto-increment)
  - _Ticket ref: FR-002_
  - _Check: `COMMON=0, UNCOMMON=1, RARE=2, EPIC=3, LEGENDARY=4`_
  - _Run test: `godot -d -s addons/gut/gut_cmdline.gd -gdir=tests/ -g="test_seed_rarity_values"`_

- [ ] **1.1.3** Verify `SeedRarity.size()` returns 5
  - _Ticket ref: AC-002_
  - _Run test: `test_seed_rarity_count`_

### 1.2 Validate Element Enum

- [ ] **1.2.1** Locate `enum Element` in `src/models/enums.gd`
  - _Ticket ref: FR-003, AC-003_
  - _File: `src/models/enums.gd` line ~21_
  - _Check: `enum Element { TERRA, FLAME, FROST, ARCANE, SHADOW, NONE }`_

- [ ] **1.2.2** Verify `Element` values are 0–5
  - _Ticket ref: FR-003_
  - _Check: TERRA=0 through SHADOW=4, then NONE=5_
  - _Run test: `test_element_values`_

- [ ] **1.2.3** Verify `Element.size()` returns 6
  - _Ticket ref: AC-003_
  - _Run test: `test_element_count`_

### 1.3 Validate SeedPhase Enum

- [ ] **1.3.1** Locate `enum SeedPhase` in `src/models/enums.gd`
  - _Ticket ref: FR-004, AC-004_
  - _Check: `enum SeedPhase { SPORE, SPROUT, BUD, BLOOM }`_

- [ ] **1.3.2** Verify values are 0–3
  - _Ticket ref: FR-004_
  - _Run test: `test_seed_phase_values`_

### 1.4 Validate RoomType Enum

- [ ] **1.4.1** Locate `enum RoomType` in `src/models/enums.gd`
  - _Ticket ref: FR-005, AC-005_
  - _Check: `enum RoomType { COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS }`_

- [ ] **1.4.2** Verify values are 0–5
  - _Ticket ref: FR-005_
  - _Run test: `test_room_type_values`_

### 1.5 Validate AdventurerClass Enum

- [ ] **1.5.1** Locate `enum AdventurerClass` in `src/models/enums.gd`
  - _Ticket ref: FR-006, AC-006_
  - _Check: `enum AdventurerClass { WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL }`_

- [ ] **1.5.2** Verify values are 0–5
  - _Ticket ref: FR-006_
  - _Run test: `test_adventurer_class_values`_

### 1.6 Validate LevelTier Enum

- [ ] **1.6.1** Locate `enum LevelTier` in `src/models/enums.gd`
  - _Ticket ref: FR-007, AC-007_
  - _Check: `enum LevelTier { NOVICE, SKILLED, VETERAN, ELITE }`_

- [ ] **1.6.2** Verify values are 0–3
  - _Ticket ref: FR-007_
  - _Run test: `test_level_tier_values`_

### 1.7 Validate ItemRarity Enum

- [ ] **1.7.1** Locate `enum ItemRarity` in `src/models/enums.gd`
  - _Ticket ref: FR-008, AC-008_
  - _Check: `enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }`_

- [ ] **1.7.2** Verify values are 0–4
  - _Ticket ref: FR-008_
  - _Run test: `test_item_rarity_values`_

### 1.8 Validate EquipSlot Enum

- [ ] **1.8.1** Locate `enum EquipSlot` in `src/models/enums.gd`
  - _Ticket ref: FR-009, AC-009_
  - _Check: `enum EquipSlot { NONE = -1, WEAPON = 0, ARMOR = 1, ACCESSORY = 2 }`_
  - _NOTE: NONE must be explicitly set to -1 (not auto-increment)_

- [ ] **1.8.2** Verify NONE=-1, WEAPON=0, ARMOR=1, ACCESSORY=2
  - _Ticket ref: FR-009_
  - _Run test: `test_equip_slot_values`_

### 1.9 Validate Currency Enum

- [ ] **1.9.1** Locate `enum Currency` in `src/models/enums.gd`
  - _Ticket ref: FR-010, AC-010_
  - _Check: `enum Currency { GOLD, ESSENCE, FRAGMENTS, ARTIFACTS }`_

- [ ] **1.9.2** Verify values are 0–3
  - _Ticket ref: FR-010_
  - _Run test: `test_currency_values`_

### 1.10 Validate ExpeditionStatus Enum

- [ ] **1.10.1** Locate `enum ExpeditionStatus` in `src/models/enums.gd`
  - _Ticket ref: FR-011, AC-011_
  - _Check: `enum ExpeditionStatus { PREPARING, IN_PROGRESS, COMPLETED, FAILED }`_

- [ ] **1.10.2** Verify values are 0–3
  - _Ticket ref: FR-011_
  - _Run test: `test_expedition_status_values`_

### 1.11 Verify No Duplicate Enum Names

- [ ] **1.11.1** Search `src/models/enums.gd` for name collisions
  - _Ticket ref: FR-012_
  - _Check: No two enums with same value name (e.g., both enums have `COMMON`)_
  - _All 10 enum types are distinct within the Enums class_

### 1.12 Verify class_name Declaration

- [ ] **1.12.1** Verify line 1 of `src/models/enums.gd` contains `class_name Enums`
  - _Ticket ref: FR-001_
  - _This enables static access: `Enums.SeedRarity.COMMON`_

### Phase 1 Validation Gate

- [ ] **1.V.1** All enum value tests pass: `test_seed_rarity_values`, `test_element_values`, `test_seed_phase_values`, `test_room_type_values`, `test_adventurer_class_values`, `test_level_tier_values`, `test_item_rarity_values`, `test_equip_slot_values`, `test_currency_values`, `test_expedition_status_values` (10 tests)
- [ ] **1.V.2** All enum count tests pass: `test_*_count` (10 tests)
- [ ] **1.V.3** File compiles with zero parse errors: `godot --check-only`
- [ ] **1.V.4** `class_name Enums` is present at top of file
- [ ] **1.V.5** Commit (if changes made): `"Phase 1: Validate enum declarations — 20 tests pass"`

---

## Phase 2: Helper Method Validation & Fix

> **Ticket References**: FR-013 through FR-018, AC-012 through AC-017  
> **Estimated Items**: 12  
> **Dependencies**: Phase 1 complete  
> **Validation Gate**: All 5 helpers exist, return correct names, handle invalid values

### 2.1 Validate seed_rarity_name() Helper

- [ ] **2.1.1** Locate `static func seed_rarity_name(rarity: SeedRarity) -> String:` in `src/models/enums.gd`
  - _Ticket ref: FR-013_
  - _File: `src/models/enums.gd` lines ~79-93_
  - _Check: Function signature is correct with typed parameter and return_

- [ ] **2.1.2** Verify all 5 rarity values map to Title-Case names
  - _Ticket ref: FR-013, AC-012_
  - _Expected: COMMON→"Common", UNCOMMON→"Uncommon", RARE→"Rare", EPIC→"Epic", LEGENDARY→"Legendary"_
  - _Run test: `test_seed_rarity_name_all`_
  - _If any name is wrong (e.g., lowercase, missing suffix), fix the match branch_

- [ ] **2.1.3** Verify wildcard branch exists and calls `push_warning()`, returns "Unknown"
  - _Ticket ref: FR-018_
  - _Check: `_: push_warning(...); return "Unknown"`_

### 2.2 Validate item_rarity_name() Helper

- [ ] **2.2.1** Locate `static func item_rarity_name(rarity: ItemRarity) -> String:` in `src/models/enums.gd`
  - _Ticket ref: FR-014_
  - _File: `src/models/enums.gd` lines ~96-112_
  - _Check: Function signature is correct_

- [ ] **2.2.2** Verify all 5 ItemRarity values return correct Title-Case names
  - _Ticket ref: FR-014, AC-013_
  - _Expected: COMMON→"Common", UNCOMMON→"Uncommon", RARE→"Rare", EPIC→"Epic", LEGENDARY→"Legendary"_
  - _Run test: `test_item_rarity_name_all`_

- [ ] **2.2.3** Verify wildcard branch includes error handling
  - _Ticket ref: FR-018_
  - _Check: `_: push_warning(...); return "Unknown"`_

### 2.3 Validate adventurer_class_name() Helper

- [ ] **2.3.1** Locate `static func adventurer_class_name(cls: AdventurerClass) -> String:` in `src/models/enums.gd`
  - _Ticket ref: FR-015_
  - _File: `src/models/enums.gd` lines ~115-133_
  - _Check: Signature is correct with AdventurerClass parameter_

- [ ] **2.3.2** Verify all 6 classes return Title-Case names
  - _Ticket ref: FR-015, AC-014_
  - _Expected: WARRIOR→"Warrior", RANGER→"Ranger", MAGE→"Mage", ROGUE→"Rogue", ALCHEMIST→"Alchemist", SENTINEL→"Sentinel"_
  - _Run test: `test_adventurer_class_name_all`_

- [ ] **2.3.3** Verify wildcard branch
  - _Ticket ref: FR-018_

### 2.4 Validate element_name() Helper

- [ ] **2.4.1** Locate `static func element_name(element: Element) -> String:` in `src/models/enums.gd`
  - _Ticket ref: FR-016_
  - _File: `src/models/enums.gd` lines ~136-154_
  - _Check: Signature is correct with Element parameter_

- [ ] **2.4.2** Verify all 6 element values return Title-Case names
  - _Ticket ref: FR-016, AC-015_
  - _Expected: TERRA→"Terra", FLAME→"Flame", FROST→"Frost", ARCANE→"Arcane", SHADOW→"Shadow", NONE→"None"_
  - _Run test: `test_element_name_all`_
  - _Special check: "None" must have capital N, not "none"_

- [ ] **2.4.3** Verify wildcard branch
  - _Ticket ref: FR-018_

### 2.5 Validate equip_slot_name() Helper

- [ ] **2.5.1** Locate `static func equip_slot_name(slot: EquipSlot) -> String:` in `src/models/enums.gd`
  - _Ticket ref: FR-017_
  - _File: `src/models/enums.gd` lines ~157-171_
  - _Check: Signature is correct with EquipSlot parameter_

- [ ] **2.5.2** Verify all 4 slot values return Title-Case names
  - _Ticket ref: FR-017, AC-016_
  - _Expected: NONE→"None", WEAPON→"Weapon", ARMOR→"Armor", ACCESSORY→"Accessory"_
  - _Run test: `test_equip_slot_name_all`_

- [ ] **2.5.3** Verify wildcard branch
  - _Ticket ref: FR-018_

### 2.6 Doc Comments Validation

- [ ] **2.6.1** Verify all 10 enums have `##` doc comments explaining purpose and GDD reference
  - _Ticket ref: NFR-001_
  - _Pattern: `## Description. GDD Reference: §X.Y`_
  - _All 10 enums should have comments; if any missing, add them_

- [ ] **2.6.2** Verify all 5 helpers have `##` doc comments
  - _Ticket ref: NFR-001_
  - _Pattern: `## Returns the human-readable display name for a {Type} value.`_

### Phase 2 Validation Gate

- [ ] **2.V.1** All helper method tests pass: `test_seed_rarity_name_all`, `test_item_rarity_name_all`, `test_adventurer_class_name_all`, `test_element_name_all`, `test_equip_slot_name_all` (5 tests)
- [ ] **2.V.2** All helper methods include wildcard `_` branch with error handling (5 helpers × 1 check = 5 checks)
- [ ] **2.V.3** All enums and helpers have `##` doc comments (10 + 5 = 15 comments)
- [ ] **2.V.4** File still compiles: `godot --check-only`
- [ ] **2.V.5** Commit (if changes made): `"Phase 2: Validate and fix helper methods — 5 tests pass, doc comments updated"`

---

## Phase 3: Final Verification & Acceptance

> **Ticket References**: AC-001 through AC-020, NFR-002 through NFR-009  
> **Estimated Items**: 8  
> **Dependencies**: Phase 1 and Phase 2 complete  
> **Validation Gate**: All acceptance criteria met, 100% test coverage, file under 200 lines

### 3.1 Full Test Suite Pass

- [ ] **3.1.1** Run all TASK-003a-related GUT tests in `test_enums_and_config.gd` Section A, B, D
  - _Ticket ref: AC-020_
  - _Command: `godot -d -s addons/gut/gut_cmdline.gd -gdir=tests/models/`_
  - _Expected: 25+ tests pass with 50+ assertions (all enum values + counts + helper names)_

- [ ] **3.1.2** Verify no test failures, warnings, or errors in console output
  - _Ticket ref: AC-020_
  - _Check: GUT output shows "Passed" count = expected, "Failed" count = 0_

### 3.2 Compilation & Type Safety

- [ ] **3.2.1** Verify `src/models/enums.gd` compiles with zero parse errors in Godot 4.5
  - _Ticket ref: NFR-005_
  - _Command: `godot --check-only`_
  - _Check: No errors or warnings related to enums.gd_

- [ ] **3.2.2** Verify all parameters and return types use explicit type hints
  - _Ticket ref: NFR-003_
  - _Pattern check: Every `func` parameter has `: Type`, every `-> Type` on return_
  - _All 5 helpers should be: `static func NAME(param: EnumType) -> String:`_

- [ ] **3.2.3** Verify no circular dependencies
  - _Ticket ref: NFR-007_
  - _Check: `src/models/enums.gd` imports nothing (no `import`, `preload`, `extends Node`)_

### 3.3 Code Quality & Maintainability

- [ ] **3.3.1** Verify file is under 200 lines
  - _Ticket ref: NFR-002_
  - _Command: `wc -l src/models/enums.gd` should be < 200_
  - _Current status: 172 lines ✅_

- [ ] **3.3.2** Verify clear section separators between logical groups
  - _Ticket ref: NFR-002_
  - _Check: File has comment blocks like `# ---------------------------------------------------------------------------`_
  - _Expected: 4 main sections (§4.1 Seeds, §4.2 Dungeons, §4.3 Adventurers, §4.4 Economy) + Helper Methods_

- [ ] **3.3.3** Verify all enum and helper method doc comments are present and clear
  - _Ticket ref: NFR-001_

### 3.4 Acceptance Criteria Verification

- [ ] **3.4.1** Verify AC-001 through AC-011 (all 10 enums exist and have correct values)
  - _Ticket ref: AC-001 through AC-011_
  - _Status: All enum declaration tests pass (from Phase 1)_

- [ ] **3.4.2** Verify AC-012 through AC-017 (all 5 helpers work correctly)
  - _Ticket ref: AC-012 through AC-017_
  - _Status: All helper method tests pass (from Phase 2)_

- [ ] **3.4.3** Verify AC-018 through AC-021 (quality criteria)
  - _Ticket ref: AC-018 through AC-021_
  - **AC-018**: File compiles without errors/warnings → ✅ from 3.2.1
  - **AC-019**: Every enum and helper has `##` doc comments → ✅ from 2.6
  - **AC-020**: All GUT tests pass with 100% enum value coverage → ✅ from 3.1
  - **AC-021**: File is under 200 lines → ✅ from 3.3.1

### 3.5 Regression Validation

- [ ] **3.5.1** Verify downstream code still imports Enums without errors
  - _Ticket ref: Critical Path requirement_
  - _Check: Search `src/` for `Enums.` usage → no errors in downstream files_
  - _Pattern: `var x: Enums.SeedRarity`, `Enums.element_name(...)`, `match enum_val:`_

- [ ] **3.5.2** Verify no enum values have shifted
  - _Ticket ref: Assumption #2_
  - _Check: All integer values are deterministic (no `randf()`, no external deps)_
  - _All 10 enums should produce same values across repeated runs_

### 3.6 Final Documentation

- [ ] **3.6.1** Update this plan's status to "Complete"
  - _File: This plan document_
  - _Change: Set "Status" field to "Complete"_

- [ ] **3.6.2** Add entry to Deviation Tracking (if any deviations were made)
  - _File: This plan document_
  - _List any differences between existing code and TASK-003a spec_

### 3.7 Commit Final State

- [ ] **3.7.1** Commit with message indicating completion
  - _Command: `git add src/models/enums.gd && git commit -m "Phase 3: TASK-003a complete — all 10 enums + 5 helpers validated, 25+ tests pass"`_
  - _Or if no code changes needed: `git log --oneline | head -1` to verify baseline_

### Phase 3 Validation Gate

- [ ] **3.V.1** All GUT tests pass (25+ tests, 50+ assertions)
- [ ] **3.V.2** File compiles with zero errors/warnings
- [ ] **3.V.3** All 20 acceptance criteria (AC-001 through AC-021) are marked as satisfied
- [ ] **3.V.4** File is under 200 lines (currently 172 lines)
- [ ] **3.V.5** All deviations tracked and explained (if any)
- [ ] **3.V.6** Commit: `"Phase 3: TASK-003a complete — validation passed, all AC satisfied"`

---

## Phase Dependency Graph

```
Phase 1: Enum Declarations ──→ Phase 2: Helper Methods ──→ Phase 3: Final Verification
         (20 tests)              (5 tests)                   (25+ tests, AC gate)
```

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 1 | Enum Declaration Validation | 12 | 0 | 20 | ⬜ Not Started |
| Phase 2 | Helper Method Validation & Fix | 12 | 0 | 5 | ⬜ Not Started |
| Phase 3 | Final Verification & Acceptance | 8 | 0 | 25+ | ⬜ Not Started |
| **Total** | | **32** | **0** | **25+** | **🔄 Phase 1 Next** |

---

## File Change Summary

### Modified Files (Validation + Optional Fixes)

| File | Phase | Change | Current Status |
|------|-------|--------|-----------------|
| `src/models/enums.gd` | 1-2 | Validate enum values; fix any name mismatches in helpers if needed | Exists, 172 lines |
| `tests/models/test_enums_and_config.gd` | 3 | Run existing tests (no modifications to test file) | Exists, 485 lines |

### New Files
- None (validation task only)

### Deleted Files
- None (validation task only)

---

## Commit Strategy

| Phase | Commit Message | Tests After | Code Changes |
|-------|----------------|-------------|--------------|
| 1 | `"Phase 1: Validate enum declarations — 20 tests pass"` | 20 | Minimal (doc comments if missing) |
| 2 | `"Phase 2: Validate and fix helper methods — 5 tests pass"` | 25 | Fix helper names if incorrect |
| 3 | `"Phase 3: TASK-003a complete — all AC satisfied, 25+ tests pass"` | 25+ | None (validation only) |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| Existing code deviates from spec | High | Low | Check each enum/helper against spec immediately | 1-2 |
| GUT test failures due to typos | Medium | Low | Run tests incrementally, fix one failure at a time | 1-3 |
| Enum value shift if code was edited | Low | High | Use append-only principle, never reorder; verify no inserts mid-enum | 1 |
| Missing doc comments | Medium | Low | Add `##` comments to all enums/helpers if any missing | 2 |

---

## Deviations from Ticket

| ID | Phase | Summary | Ticket Ref | Reason | Resolution |
|----|-------|---------|------------|--------|-----------|
| — | — | None yet | — | — | Check here after execution |

---

## Handoff State (Initial)

### What's Complete
- None (just started)

### What's In Progress
- None (ready to start Phase 1)

### What's Blocked
- None

### Next Steps
1. Run Phase 1 validation on all 10 enums
2. Compare existing code against TASK-003a spec (FR-001 through FR-011)
3. Fix any deviations found in Phase 2
4. Run all 25+ GUT tests in Phase 3
5. Confirm all 20+ acceptance criteria are satisfied

---

## Quick Reference

### GUT Test Subset for TASK-003a (from test_enums_and_config.gd)

**Section A: Enum Value & Count Tests (20 tests)**
- `test_seed_rarity_values`, `test_seed_rarity_count`
- `test_element_values`, `test_element_count`
- `test_seed_phase_values`, `test_seed_phase_count`
- `test_room_type_values`, `test_room_type_count`
- `test_adventurer_class_values`, `test_adventurer_class_count`
- `test_level_tier_values`, `test_level_tier_count`
- `test_item_rarity_values`, `test_item_rarity_count`
- `test_equip_slot_values`, `test_equip_slot_count`
- `test_currency_values`, `test_currency_count`
- `test_expedition_status_values`, `test_expedition_status_count`

**Section D: Helper Method Tests (5 tests)**
- `test_seed_rarity_name_all`
- `test_item_rarity_name_all`
- `test_adventurer_class_name_all`
- `test_element_name_all`
- `test_equip_slot_name_all`

**Total: 25+ tests covering 100% of FR-001 through FR-017**

---

*Implementation plan for TASK-003a: Enums — Game-Wide Enumerations*  
*Plan version: 1.0 | Created: 2026-03-31 | Type: Validation + Optional Fixes*
