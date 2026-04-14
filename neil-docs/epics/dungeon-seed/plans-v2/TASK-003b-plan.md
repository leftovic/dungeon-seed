# TASK-003b: GameConfig — Balance Constants Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-003b-game-config.md`  
> **Parent**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-003-enums-constants.md`  
> **Status**: Planning  
> **Created**: 2026-03-31  
> **Branch**: `users/{alias}/task-003b-game-config`  
> **Repo**: `C:\Users\wrstl\source\dev-agent-tool` (Godot 4.5, GDScript)  
> **Methodology**: TDD Red-Green-Refactor (GUT test framework)  
> **Complexity**: 5 points (Moderate)  
> **Estimated Phases**: 4  
> **Type**: Validation + Correction (NOT greenfield — existing code in `src/models/game_config.gd` needs validation/fixes against spec)

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents **in this order**:

1. **This file** — the implementation checklist (you're reading it)
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-003b-game-config.md`** — the full technical spec with all 25 FRs, 46 ACs, 10 NFRs
3. **Existing source code** — validate against spec:
   - `src/models/game_config.gd` — the GameConfig class (already exists, needs validation)
   - `tests/models/test_enums_and_config.gd` — the test suite (already exists, Section C covers TASK-003b)
4. **GDD sections** `neil-docs/epics/dungeon-seed/GDD-v3.md` §4.1–4.4 — balance values reference

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| GameConfig source | `src/models/game_config.gd` | 9 const dicts + 8 helpers (230 lines) — **ALREADY EXISTS**, validate against spec |
| Test file | `tests/models/test_enums_and_config.gd` | GUT tests covering enums + game_config — **ALREADY EXISTS**, Section C covers TASK-003b (85+ test assertions) |
| GDD reference | `neil-docs/epics/dungeon-seed/GDD-v3.md` | §4.1 (Seeds), §4.2 (Dungeons), §4.3 (Adventurers), §4.4 (Loot & Economy) |
| Ticket | `neil-docs/epics/dungeon-seed/tickets-v2/TASK-003b-game-config.md` | Full 16-section specification with 46 acceptance criteria |
| Sibling plan | `neil-docs/epics/dungeon-seed/plans-v2/TASK-003a-plan.md` | Reference for plan format and non-greenfield approach |

### Build & Test Commands

```powershell
# Verify Godot project loads (from project root)
godot --headless --debug-script -- --test-only

# Run GUT tests (GameConfig-specific tests from test_enums_and_config.gd Section C)
godot -d -s addons/gut/gut_cmdline.gd -gdir=tests/models/ -gtest="test_game_config"

# Validate no parse errors in game_config.gd
godot --check-only --headless

# Quick validation: examine game_config.gd values against GDD §4.1–4.4
# (Search ticket TASK-003b for exact values: FR-002, FR-004, FR-006–FR-011, etc.)
```

### Regression Gate (MUST PASS BEFORE AND AFTER EVERY CHANGE)

- [ ] **RG.1**: `src/models/game_config.gd` compiles with zero parse errors/warnings
- [ ] **RG.2**: All GUT tests in Section C of `test_enums_and_config.gd` pass (46 test functions, 85+ assertions)
- [ ] **RG.3**: All 9 const dictionaries accessible via qualified names (e.g., `GameConfig.BASE_GROWTH_SECONDS`)
- [ ] **RG.4**: `get_base_stats()` returns new Dictionary (not reference to const dict)
- [ ] **RG.5**: All Color values have RGB in [0.0, 1.0] range
- [ ] **RG.6**: XP_PER_TIER is monotonically increasing (RG-006 from ticket)
- [ ] **RG.7**: No downstream files break after running tests (check editor error console)

### Current State (Baseline)

**Existing Code Status:**
- `src/models/game_config.gd` — **EXISTS** with 9 const dicts + 8 helpers, 230 lines
- `tests/models/test_enums_and_config.gd` — **EXISTS** with 485+ lines (Sections A/B for TASK-003a, Section C for TASK-003b)
- GameConfig class_name defined; all dicts have doc comments

**What Needs Validation/Correction:**

| Dictionary | Ticket Spec | Current Code | Status |
|------------|------------|-------------|--------|
| BASE_GROWTH_SECONDS | COMMON=60, UNCOMMON=120, RARE=300, EPIC=600, LEGENDARY=1200 | ✓ Matches | ✅ |
| XP_PER_TIER | NOVICE=0, SKILLED=100, VETERAN=350, ELITE=750 | ✓ Matches | ✅ |
| BASE_STATS (6 classes) | Exact stat dicts per FR-006–FR-011 | ❌ Deviations found (see Phase 1) | ⚠️ |
| MUTATION_SLOTS | COMMON=1, UNCOMMON=2, RARE=3, EPIC=4, LEGENDARY=5 | ✓ Matches | ✅ |
| CURRENCY_EARN_RATES | GOLD=10, ESSENCE=2, FRAGMENTS=1, ARTIFACTS=0 | ✓ Matches | ✅ |
| ROOM_DIFFICULTY_SCALE | Values per FR-017 | ❌ Deviations found (TRAP=1.2 vs spec 0.8) | ⚠️ |
| PHASE_GROWTH_MULTIPLIERS | SPORE=1.0, SPROUT=1.5, BUD=2.0, BLOOM=3.0 | ❌ Deviations found (reversed multipliers) | ⚠️ |
| ELEMENT_NAMES | Element enum keys + display names | ✓ Matches | ✅ |
| RARITY_COLORS | 5 Color values per FR-022 | ❌ Deviations found (see Phase 1) | ⚠️ |

**Non-Greenfield Approach:**
- NO creation of new files — validation and targeted fixes only
- Run existing tests first to establish baseline (Phase 1)
- Identify spec violations with evidence (Phase 2)
- Fix deviations to match spec exactly (Phase 3)
- Confirm all tests pass with corrected code (Phase 4)

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

- **Write NO new tests** — GUT tests already exist in `test_enums_and_config.gd` Section C
- **Run the existing tests** — establish baseline of what's passing
- **Fix code to match ticket spec** — if existing implementation diverges
- **Re-run tests** — confirm fixes pass

### Test Naming Convention (GDScript / GUT)

```gdscript
func test_base_growth_seconds_completeness() -> void:
	# Check: exactly 5 keys (one per SeedRarity)
	
func test_base_growth_seconds_values() -> void:
	# Check: COMMON=60, UNCOMMON=120, etc.
	
func test_base_stats_warrior_matches_spec() -> void:
	# Check: BASE_STATS[WARRIOR] == exact dict from FR-006
```

---

## Phase Dependency Graph

```
Phase 1: Baseline Validation (run tests, identify deviations)
   ↓
Phase 2: Analyze Deviations (document what's wrong and why)
   ↓
Phase 3: Fix Specification Violations (update dicts + helpers to match spec)
   ↓
Phase 4: Final Validation Gate (all tests pass, zero spec violations, commit)
```

---

## Phased Implementation Checklist

## Phase 1: Baseline Validation — Identify Deviations

> **Ticket References**: FR-001–FR-025, AC-001–AC-047, NFR-001–NFR-012  
> **Estimated Items**: 8  
> **Dependencies**: TASK-003a complete (Enums must exist)  
> **Validation Gate**: All regression tests run; deviations documented in Phase 2

### 1.1 Run Existing Test Suite

- [ ] **1.1.1** Run GUT tests: `godot -d -s addons/gut/gut_cmdline.gd -gdir=tests/models/`
  - _File: `tests/models/test_enums_and_config.gd` Section C_
  - _Record: number of tests passing, failing, and skipped_
  - _Expected baseline: 46+ test functions, 85+ assertions_

### 1.2 Verify GameConfig Structure

- [ ] **1.2.1** Check `game_config.gd` has all 9 const dictionaries
  - _Dictionary count: BASE_GROWTH_SECONDS, XP_PER_TIER, BASE_STATS, MUTATION_SLOTS, CURRENCY_EARN_RATES, ROOM_DIFFICULTY_SCALE, PHASE_GROWTH_MULTIPLIERS, ELEMENT_NAMES, RARITY_COLORS_
  - _Each dict must be declared with `const` keyword_
  - _Verify no syntax errors: `godot --check-only --headless`_

- [ ] **1.2.2** Verify 8 helper methods exist and have return type hints
  - _Methods: get_base_stats(), get_growth_seconds(), get_mutation_slots(), get_xp_for_tier(), get_rarity_color(), get_room_difficulty(), get_phase_multiplier()_
  - _Each method must have full type hints: `static func name(...) -> ReturnType`_

### 1.3 Validate Dictionary Keys Against Enums

- [ ] **1.3.1** Verify each dictionary uses enum keys (not strings)
  - _Example: `Enums.SeedRarity.COMMON` (int) not `"COMMON"` (string)_
  - _Run assertion: `typeof(dict.keys()[0]) == TYPE_INT` for each dict_

- [ ] **1.3.2** Verify each dictionary has correct key count per spec
  - _BASE_GROWTH_SECONDS: 5 keys (SeedRarity)_
  - _XP_PER_TIER: 4 keys (LevelTier)_
  - _BASE_STATS: 6 keys (AdventurerClass)_
  - _MUTATION_SLOTS: 5 keys (SeedRarity)_
  - _CURRENCY_EARN_RATES: 4 keys (Currency)_
  - _ROOM_DIFFICULTY_SCALE: 6 keys (RoomType)_
  - _PHASE_GROWTH_MULTIPLIERS: 4 keys (SeedPhase)_
  - _ELEMENT_NAMES: N keys (Element count from Enums)_
  - _RARITY_COLORS: 5 keys (SeedRarity)_

### 1.4 Check BASE_STATS Deviations

- [ ] **1.4.1** Validate BASE_STATS exact values against FR-006–FR-011
  - _File: `src/models/game_config.gd` lines 114–133_
  - _Cross-reference ticket TASK-003b FR-006 through FR-011 for exact stats_
  - _Document any mismatches in Phase 2 Deviation Log_
  - _Known issues to verify:_
    - _RANGER: ticket says health=85, need to check current code_
    - _MAGE: ticket says defense=8, need to verify_
    - _ROGUE: ticket says attack=16, need to verify_
    - _ALCHEMIST: ticket says health=80, defense=12, need to verify_
    - _SENTINEL: ticket says utility=8, need to verify_

### 1.5 Check ROOM_DIFFICULTY_SCALE Deviations

- [ ] **1.5.1** Validate ROOM_DIFFICULTY_SCALE exact values against FR-017
  - _File: `src/models/game_config.gd` lines 69–76_
  - _Ticket spec (FR-017): COMBAT=1.0, TREASURE=0.5, TRAP=0.8, PUZZLE=0.6, REST=0.0, BOSS=2.0_
  - _Known issue: current code has TRAP=1.2 (should be 0.8)_
  - _Document in Phase 2 Deviation Log_

### 1.6 Check PHASE_GROWTH_MULTIPLIERS Deviations

- [ ] **1.6.1** Validate PHASE_GROWTH_MULTIPLIERS exact values against FR-019
  - _File: `src/models/game_config.gd` lines 41–46_
  - _Ticket spec (FR-019): SPORE=1.0, SPROUT=1.5, BUD=2.0, BLOOM=3.0_
  - _Known issue: current code has multipliers < 1.0 (reversed direction)_
  - _Spec says later phases grow faster (lower time multiplier), or growth factor scaling?_
  - _Verify against GDD §4.1 and designer's manual in ticket_
  - _Document in Phase 2 Deviation Log_

### 1.7 Check RARITY_COLORS Deviations

- [ ] **1.7.1** Validate RARITY_COLORS exact values against FR-022
  - _File: `src/models/game_config.gd` lines 154–160_
  - _Ticket spec (FR-022): COMMON=gray (0.78,0.78,0.78), UNCOMMON=green (0.18,0.8,0.25), RARE=blue (0.25,0.52,0.96), EPIC=purple (0.64,0.21,0.93), LEGENDARY=gold (0.95,0.77,0.06)_
  - _Known issues: COMMON != 0.78 (code has 0.66), LEGENDARY != 0.95 (code has 1.0)_
  - _Document in Phase 2 Deviation Log_

### 1.8 Summary: Document All Findings

- [ ] **1.8.1** Create baseline summary
  - _Test results: X passing, Y failing, Z skipped_
  - _Spec violations found: list all deviations (use Deviation Tracking section below)_
  - _Severity: which deviations block Phase 2 fixes?_

---

## Phase 2: Analyze Deviations — Document Evidence

> **Ticket References**: AC-001–AC-047 (focus on failing ACs)  
> **Estimated Items**: 5  
> **Dependencies**: Phase 1 complete  
> **Validation Gate**: All deviations documented with evidence + root cause; ready for fixes

### 2.1 BASE_STATS Deviation Analysis

- [ ] **2.1.1** Compare current BASE_STATS to ticket FR-006–FR-011
  - _File: `src/models/game_config.gd` lines 114–133_
  - _Ticket TASK-003b FR-006–FR-011 (lines 141–146 of ticket)_
  - _For each class (WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL):_
    - _Current: (list actual values)_
    - _Spec: (list expected values from ticket)_
    - _Deviation: (stat-by-stat diff)_
  - _Root cause analysis: Why does current code differ? (typo, old spec, intentional?)_
  - _Entry in Deviation Tracking: DEV-001–DEV-N for each class mismatch_

### 2.2 ROOM_DIFFICULTY_SCALE Deviation Analysis

- [ ] **2.2.1** Compare TRAP difficulty: current vs spec
  - _File: `src/models/game_config.gd` line 72_
  - _Ticket spec (FR-017, line 152): TRAP=0.8_
  - _Current code: TRAP=1.2_
  - _Deviation: 1.2 vs 0.8 (1.5x difference)_
  - _Root cause: Design intent changed? Designer commentary in ticket §8 doesn't mention this_
  - _Entry in Deviation Tracking: DEV-TRAP-DIFF_

### 2.3 PHASE_GROWTH_MULTIPLIERS Deviation Analysis

- [ ] **2.3.1** Compare phase multipliers: current vs spec
  - _File: `src/models/game_config.gd` lines 41–46_
  - _Ticket spec (FR-019, line 154): SPORE=1.0, SPROUT=1.5, BUD=2.0, BLOOM=3.0_
  - _Current code: SPORE=1.0, SPROUT=0.9, BUD=0.75, BLOOM=0.5_
  - _Deviation: Entire multiplier direction reversed (ascending vs descending)_
  - _Root cause: Doc comment says "faster growth" for later phases; spec says growth multiplier increases per phase; semantics conflict?_
  - _Clarification: Does "1.5x multiplier" mean "1.5x slower" or "1.5x faster"?_
  - _Entry in Deviation Tracking: DEV-PHASE-MULTIPLIER_

### 2.4 RARITY_COLORS Deviation Analysis

- [ ] **2.4.1** Compare each color: current vs spec
  - _File: `src/models/game_config.gd` lines 154–160_
  - _Ticket spec (FR-022, lines 369–373):_
    - _COMMON: (0.78, 0.78, 0.78) gray_
    - _UNCOMMON: (0.18, 0.8, 0.25) green_
    - _RARE: (0.25, 0.52, 0.96) blue_
    - _EPIC: (0.64, 0.21, 0.93) purple_
    - _LEGENDARY: (0.95, 0.77, 0.06) gold_
  - _Current code vs above: list RGB differences_
  - _Acceptable tolerance? (NFR-006: colors must be distinguishable; ±0.05 RGB drift acceptable?)_
  - _Entry in Deviation Tracking: DEV-COMMON-GRAY, DEV-LEGENDARY-GOLD, etc._

### 2.5 Evidence Summary

- [ ] **2.5.1** Create Phase 2 evidence table
  - _Table: Deviation ID | Dictionary | Key | Ticket Spec | Current Code | Difference | Severity_
  - _Mark each as CRITICAL (breaks test), MAJOR (spec violation), MINOR (rounding tolerance)_

---

## Phase 3: Fix Specification Violations

> **Ticket References**: FR-001–FR-025 (implement fixes)  
> **Estimated Items**: 9  
> **Dependencies**: Phase 2 complete (all deviations identified)  
> **Validation Gate**: All fixes applied; no new test failures introduced

### 3.1 Fix BASE_STATS (if needed)

- [ ] **3.1.1** Update WARRIOR stats (if deviations found in Phase 2)
  - _File: `src/models/game_config.gd` line 115–117_
  - _Spec: health=120, attack=18, defense=15, speed=8, utility=5 (from FR-006)_
  - _TDD: Tests already exist; apply fix to make them pass_

- [ ] **3.1.2** Update RANGER stats (if deviations found)
  - _File: line 118–120_
  - _Spec: health=85, attack=14, defense=10, speed=15, utility=10 (from FR-007)_

- [ ] **3.1.3** Update MAGE stats (if deviations found)
  - _File: line 121–123_
  - _Spec: health=70, attack=12, defense=8, speed=10, utility=20 (from FR-008)_

- [ ] **3.1.4** Update ROGUE stats (if deviations found)
  - _File: line 124–126_
  - _Spec: health=75, attack=16, defense=8, speed=18, utility=12 (from FR-009)_

- [ ] **3.1.5** Update ALCHEMIST stats (if deviations found)
  - _File: line 127–129_
  - _Spec: health=80, attack=10, defense=12, speed=10, utility=18 (from FR-010)_

- [ ] **3.1.6** Update SENTINEL stats (if deviations found)
  - _File: line 130–132_
  - _Spec: health=130, attack=10, defense=20, speed=6, utility=8 (from FR-011)_

- [ ] **3.1.7** Run tests after BASE_STATS changes
  - _Command: `godot -d -s addons/gut/gut_cmdline.gd -gdir=tests/models/ -gtest="test_base_stats"`_
  - _Confirm: All BASE_STATS tests pass (AC-021–AC-027)_

### 3.2 Fix ROOM_DIFFICULTY_SCALE (if needed)

- [ ] **3.2.1** Update TRAP difficulty value
  - _File: `src/models/game_config.gd` line 72_
  - _Current: `Enums.RoomType.TRAP: 1.2,`_
  - _Spec: `Enums.RoomType.TRAP: 0.8,` (from FR-017)_
  - _Change: 1.2 → 0.8_
  - _TDD: Test `test_room_difficulty_scale_values()` expects 0.8; apply fix to make it pass_

- [ ] **3.2.2** Verify other ROOM_DIFFICULTY_SCALE values match spec
  - _File: lines 69–76_
  - _Spec (FR-017): COMBAT=1.0, TREASURE=0.5, TRAP=0.8, PUZZLE=0.6, REST=0.0, BOSS=2.0_
  - _Check all 6 values match_

- [ ] **3.2.3** Run tests after ROOM_DIFFICULTY_SCALE changes
  - _Command: `godot -d -s addons/gut/gut_cmdline.gd -gdir=tests/models/ -gtest="test_room_difficulty"`_
  - _Confirm: All ROOM_DIFFICULTY_SCALE tests pass (AC-030)_

### 3.3 Fix PHASE_GROWTH_MULTIPLIERS (if needed)

- [ ] **3.3.1** Clarify phase multiplier semantics
  - _File: `src/models/game_config.gd` lines 41–46_
  - _Ambiguity: Does multiplier mean "1.5x slower growth" or "apply 1.5x as growth scaling factor"?_
  - _Resolution: Check GDD §4.1 and ticket designer commentary (Section 8)_
  - _Ticket FR-019 (line 154) says: "SPORE=1.0, SPROUT=1.5, BUD=2.0, BLOOM=3.0"_
  - _Interpretation: Later phases use higher multipliers (growth accelerates through phases)_
  - _Doc comment (line 38–39) says "faster growth" for later phases → contradicts current code (0.5 for BLOOM)_

- [ ] **3.3.2** Update PHASE_GROWTH_MULTIPLIERS to spec
  - _File: lines 41–46_
  - _Current: SPORE=1.0, SPROUT=0.9, BUD=0.75, BLOOM=0.5_
  - _Spec: SPORE=1.0, SPROUT=1.5, BUD=2.0, BLOOM=3.0_
  - _Changes: SPROUT 0.9→1.5, BUD 0.75→2.0, BLOOM 0.5→3.0_
  - _Note: If multiplier means "slower growth", update doc comment to clarify (e.g., "time = base * multiplier")_

- [ ] **3.3.3** Run tests after PHASE_GROWTH_MULTIPLIERS changes
  - _Command: `godot -d -s addons/gut/gut_cmdline.gd -gdir=tests/models/ -gtest="test_phase_growth"`_
  - _Confirm: All PHASE_GROWTH_MULTIPLIERS tests pass (AC-031)_

### 3.4 Fix RARITY_COLORS (if needed)

- [ ] **3.4.1** Update COMMON color
  - _File: `src/models/game_config.gd` line 155_
  - _Current: `Color(0.66, 0.66, 0.66)`_
  - _Spec: `Color(0.78, 0.78, 0.78)` (from FR-022, AC-033)_
  - _Change: 0.66 → 0.78 (all RGB components)_

- [ ] **3.4.2** Update UNCOMMON color
  - _File: line 156_
  - _Current: `Color(0.18, 0.80, 0.25)`_
  - _Spec: `Color(0.18, 0.8, 0.25)` (same — no change)_

- [ ] **3.4.3** Update RARE color
  - _File: line 157_
  - _Current: `Color(0.26, 0.52, 0.96)`_
  - _Spec: `Color(0.25, 0.52, 0.96)` (from FR-022, AC-035)_
  - _Change: 0.26 → 0.25 (minor rounding correction)_

- [ ] **3.4.4** Update EPIC color
  - _File: line 158_
  - _Current: `Color(0.64, 0.21, 0.93)`_
  - _Spec: `Color(0.64, 0.21, 0.93)` (same — no change)_

- [ ] **3.4.5** Update LEGENDARY color
  - _File: line 159_
  - _Current: `Color(1.00, 0.78, 0.06)`_
  - _Spec: `Color(0.95, 0.77, 0.06)` (from FR-022, AC-037)_
  - _Changes: 1.00→0.95 (R), 0.78→0.77 (G)_

- [ ] **3.4.6** Verify all colors are distinguishable (NFR-006)
  - _Check: No two colors have identical RGB values_
  - _Check: Each color's RGB components all in [0.0, 1.0] range_
  - _Post-fix validation: run color tests_

- [ ] **3.4.7** Run tests after RARITY_COLORS changes
  - _Command: `godot -d -s addons/gut/gut_cmdline.gd -gdir=tests/models/ -gtest="test_rarity_colors"`_
  - _Confirm: All RARITY_COLORS tests pass (AC-033–AC-037)_

### 3.5 Verify Unchanged Dictionaries Still Match Spec

- [ ] **3.5.1** Confirm BASE_GROWTH_SECONDS unchanged (no deviations found in Phase 1)
  - _File: lines 17–23_
  - _Spec: COMMON=60, UNCOMMON=120, RARE=300, EPIC=600, LEGENDARY=1200 (FR-002)_
  - _Expected: No changes needed_

- [ ] **3.5.2** Confirm XP_PER_TIER unchanged
  - _File: lines 87–92_
  - _Spec: NOVICE=0, SKILLED=100, VETERAN=350, ELITE=750 (FR-004)_
  - _Expected: No changes needed_

- [ ] **3.5.3** Confirm MUTATION_SLOTS unchanged
  - _File: lines 28–34_
  - _Spec: COMMON=1, UNCOMMON=2, RARE=3, EPIC=4, LEGENDARY=5 (FR-013)_
  - _Expected: No changes needed_

- [ ] **3.5.4** Confirm CURRENCY_EARN_RATES unchanged
  - _File: lines 144–149_
  - _Spec: GOLD=10, ESSENCE=2, FRAGMENTS=1, ARTIFACTS=0 (FR-015)_
  - _Expected: No changes needed_

- [ ] **3.5.5** Confirm ELEMENT_NAMES unchanged
  - _File: lines 51–58_
  - _Spec: All Element enum values with display names (FR-020)_
  - _Expected: No changes needed_

---

## Phase 4: Final Validation Gate

> **Ticket References**: RG-001–RG-010 (regression gate), AC-001–AC-047 (all acceptance criteria)  
> **Estimated Items**: 5  
> **Dependencies**: Phase 3 complete (all fixes applied)  
> **Validation Gate**: All tests pass; zero regressions; code ready to merge

### 4.1 Run Full Test Suite

- [ ] **4.1.1** Run all GameConfig tests (Section C of `test_enums_and_config.gd`)
  - _Command: `godot -d -s addons/gut/gut_cmdline.gd -gdir=tests/models/ -gtest="test_game_config"`_
  - _Expected result: All 46 test functions pass, 85+ assertions pass_
  - _Record: test count, pass count, fail count, coverage percentage_

### 4.2 Validate Against All Acceptance Criteria

- [ ] **4.2.1** Verify AC-001–AC-009 (dictionary completeness)
  - _Each dict has correct key count (no keys added/removed)_
  - _Recount: BASE_GROWTH_SECONDS=5, XP_PER_TIER=4, BASE_STATS=6, MUTATION_SLOTS=5, CURRENCY_EARN_RATES=4, ROOM_DIFFICULTY_SCALE=6, PHASE_GROWTH_MULTIPLIERS=4, ELEMENT_NAMES=N, RARITY_COLORS=5_

- [ ] **4.2.2** Verify AC-010–AC-037 (dictionary values)
  - _All values match spec exactly (per Phase 3 fixes)_
  - _No rounding errors; no typos; colors in [0.0, 1.0] range_

- [ ] **4.2.3** Verify AC-038–AC-047 (helpers + code quality)
  - _AC-038: get_base_stats(WARRIOR) returns exact stat dict_
  - _AC-039: get_base_stats() returns NEW Dictionary (not reference)_
  - _AC-040: get_base_stats() is static_
  - _AC-041: All declarations have type hints_
  - _AC-042: All const dicts use `const` keyword_
  - _AC-043: Dict keys are enum integers, not strings_
  - _AC-044: All Color RGB components in [0.0, 1.0]_
  - _AC-045: GameConfig file ≤ 200 lines_
  - _AC-046: Doc comments present on each const dict_
  - _AC-047: No magic strings/numbers_

### 4.3 Verify Regression Gate (RG-001–RG-010)

- [ ] **4.3.1** RG-001: After changes, all existing ACs still pass
  - _Run full test suite; confirm zero new failures_

- [ ] **4.3.2** RG-002: get_base_stats() returns dict with correct structure
  - _Test: call get_base_stats() for each class; verify dict has ["health", "attack", "defense", "speed", "utility"]_

- [ ] **4.3.3** RG-003: Const dicts have expected entry count
  - _Recount all 9 dicts; no keys added/removed_

- [ ] **4.3.4** RG-004: All dict values match GDD §4.1–4.4
  - _Cross-reference: GDD Balance Parameters sections against GameConfig values_

- [ ] **4.3.5** RG-005: Color values still distinguishable
  - _Visual check: no two colors identical; all 5 rarity colors visually distinct_

- [ ] **4.3.6** RG-006: XP_PER_TIER still monotonically increasing
  - _Test: NOVICE ≤ SKILLED ≤ VETERAN ≤ ELITE (with equality allowed for 0)_

- [ ] **4.3.7** RG-007: No runtime allocations on const dict access
  - _Profile in Release build: const dicts pre-allocated, zero new allocations per access_

- [ ] **4.3.8** RG-008: GUT test suite ≥ 90% code coverage
  - _GUT coverage report: 90%+ of game_config.gd lines covered by tests_

- [ ] **4.3.9** RG-009: File still ≤ 200 lines
  - _Line count: `wc -l src/models/game_config.gd` ≤ 200_

- [ ] **4.3.10** RG-010: All type hints still present
  - _Grep: no `var` declarations without `: Type`, no methods without `-> ReturnType`_

### 4.4 Code Review Checklist

- [ ] **4.4.1** All const dictionaries are immutable (use `const` keyword)
  - _No assignments to dict contents after declaration_

- [ ] **4.4.2** Helper methods all return correct types
  - _get_base_stats(): Dictionary_
  - _get_growth_seconds(): int_
  - _get_mutation_slots(): int_
  - _get_xp_for_tier(): int_
  - _get_rarity_color(): Color_
  - _get_room_difficulty(): float_
  - _get_phase_multiplier(): float_

- [ ] **4.4.3** No hardcoded business logic in helpers
  - _Helpers are pure data lookups only (dict access + return)_
  - _No calculations, no side effects_

- [ ] **4.4.4** Doc comments are accurate and complete
  - _Each const dict has comment explaining purpose + GDD reference_
  - _Each helper has comment with example usage_

### 4.5 Final Commit

- [ ] **4.5.1** Commit all fixes with message
  - _Message: `"Phase 3–4: Fix GameConfig values to match TASK-003b spec — 46 tests pass"`_
  - _Include: count of spec deviations fixed, test count_
  - _Reference: TASK-003b ticket link_

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 1 | Baseline Validation | 8 | 0 | 46+ | ⬜ Not Started |
| Phase 2 | Deviation Analysis | 5 | 0 | — | ⬜ Not Started |
| Phase 3 | Fix Violations | 9 | 0 | 46+ | ⬜ Not Started |
| Phase 4 | Final Validation | 5 | 0 | 46+ | ⬜ Not Started |
| **Total** | | **27** | **0** | **46+** | **🔴 Ready to start** |

---

## File Change Summary

### Modified Files

| File | Phase | Change |
|------|-------|--------|
| `src/models/game_config.gd` | 3 | Fix BASE_STATS (up to 6 classes), ROOM_DIFFICULTY_SCALE (TRAP), PHASE_GROWTH_MULTIPLIERS (4 values), RARITY_COLORS (3 colors) |

### Test Files (No Changes)

| File | Phase | Status |
|------|-------|--------|
| `tests/models/test_enums_and_config.gd` | All | Runs as-is; Section C tests validate GameConfig |

---

## Commit Strategy

| Phase | Commit Message | Tests After |
|-------|----------------|-------------|
| 3–4 | `"Phase 3–4: Fix GameConfig values to match TASK-003b spec — 46 tests pass"` | 46 pass, 0 fail |

---

## Deviations from Ticket

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| (None yet) | — | (To be filled as deviations are discovered) | — | — | — |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| Phase multiplier semantics ambiguous | Medium | Medium | Check GDD §4.1 and ticket designer commentary; confirm multiplier direction (ascending vs descending) | 2 |
| Color RGB drift acceptable? | Low | Low | NFR-006 says "distinguishable"; tolerance ±0.05 acceptable; validate visually post-fix | 3 |
| Test file out of sync with fixes | Low | High | Run Phase 1 baseline; if tests already pass, no fixes needed; if tests fail, fixes required | 1 |
| Downstream code depends on old values | Low | High | Search codebase for references to GameConfig constants; verify no breakage | 4 |

---

## Handoff State (YYYY-MM-DD)

### What's Complete
- (Nothing yet — plan is ready to execute)

### What's In Progress
- (Ready for Phase 1)

### What's Blocked
- (None)

### Next Steps
1. Run Phase 1 baseline validation (tests + structure verification)
2. Document deviations found in Phase 2
3. Apply fixes in Phase 3
4. Validate in Phase 4
5. Commit with message from Commit Strategy table

---

## Quick Reference — Deviations to Watch

Based on code inspection (not yet Phase 1 validation), these deviations are likely:

| Dictionary | Likely Deviation | Spec Value | Current Code | Phase |
|------------|------------------|-----------|--------------|-------|
| BASE_STATS | RANGER health | 85 | 90 (likely) | 3 |
| BASE_STATS | MAGE defense | 8 | 6 (likely) | 3 |
| BASE_STATS | ROGUE attack | 16 | 20 (likely) | 3 |
| ROOM_DIFFICULTY_SCALE | TRAP | 0.8 | 1.2 | 3 |
| PHASE_GROWTH_MULTIPLIERS | All 4 values | 1.0, 1.5, 2.0, 3.0 | 1.0, 0.9, 0.75, 0.5 (reversed) | 3 |
| RARITY_COLORS | COMMON | (0.78,0.78,0.78) | (0.66,0.66,0.66) | 3 |
| RARITY_COLORS | RARE | (0.25,0.52,0.96) | (0.26,0.52,0.96) | 3 |
| RARITY_COLORS | LEGENDARY | (0.95,0.77,0.06) | (1.00,0.78,0.06) | 3 |

**Note:** These are pre-Phase-1 observations based on code review. Phase 1 will confirm via tests.

---

*Agent version: 1.0.0 | Plan template: Gold Standard (TASK-003a) | Updated: 2026-03-31*
