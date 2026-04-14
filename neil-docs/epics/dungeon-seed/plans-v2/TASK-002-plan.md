# TASK-002: Deterministic RNG Wrapper — Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-002-deterministic-rng.md`
> **GDD**: `neil-docs/epics/dungeon-seed/GDD-v2.md`
> **Status**: Planning
> **Created**: 2025-07-18
> **Repo**: `dev-agent-tool` (local — `C:\Users\wrstl\source\dev-agent-tool`)
> **Methodology**: TDD Red-Green-Refactor (mandatory for all phases)
> **Complexity**: 3 points (Trivial) — Fibonacci
> **Estimated Phases**: 6 (Phase 0–5)
> **Estimated Checkboxes**: ~55

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents in this order:

1. **This file** (you're reading it) — the phased checklist of what to do, with status
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-002-deterministic-rng.md`** — the full technical spec with exact code to implement
3. **`neil-docs/epics/dungeon-seed/GDD-v2.md`** — the Game Design Document for understanding domain context
4. **`src/models/rng.gd`** — the target file (does NOT exist yet — you will create it)
5. **`src/gdscript/utils/rng_wrapper_clean.gd`** — the v1 prototype reference (DO NOT MODIFY — read-only reference)

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| Target source file | `src/models/rng.gd` | **NEW** — `DeterministicRNG` class |
| Test file | `tests/models/test_rng.gd` | **NEW** — 31 GUT test functions |
| v1 prototype reference | `src/gdscript/utils/rng_wrapper_clean.gd` | **DO NOT TOUCH** — read-only reference for algorithm constants |
| Models directory | `src/models/` | **SHOULD EXIST** from TASK-001 |
| Test models directory | `tests/models/` | **MAY NOT EXIST** — create if needed |
| GUT addon | `addons/gut/` | **PRE-REQUISITE** — GUT must be available for test execution |

### Key Concepts (5-minute primer)

- **xorshift64***: A PRNG algorithm using three XOR-shift operations (13, 7, 17) and a multiplication constant (`0x2545F4914F6CDD1D`). Period: 2^64 − 1.
- **RefCounted**: Godot base class for garbage-collected objects. No `.free()` needed. No scene tree coupling. Used for pure data/logic classes.
- **Determinism**: Same seed → same sequence, always. No external entropy. This is the core promise of Dungeon Seed.
- **63-bit masking**: GDScript `int` is signed 64-bit. We mask with `0x7FFFFFFFFFFFFFFF` to stay non-negative.
- **SHA-256 string seeding**: Converts player-entered strings into well-distributed 64-bit seeds using first 8 bytes of SHA-256 hash.
- **Fisher-Yates shuffle**: O(n) in-place unbiased shuffle. For each index `i` from `n-1` down to `1`, swap element `i` with random element from `[0, i]`.
- **Weighted selection**: Cumulative weight sum + uniform float roll + linear scan to find the bucket.
- **GUT**: Godot Unit Test framework. Tests extend `GutTest` and use `assert_*` methods.
- **`class_name`**: GDScript keyword that registers a script as a globally available type — no `preload()` needed.

### Build & Verification Commands

```powershell
# There is no CLI build for GDScript — verification is done in-editor.
# However, you can verify script syntax via headless Godot:

# Open project in editor (manual)
# Press F5 to run — should launch to main_menu.tscn

# Run GUT tests from within the editor:
#   1. Open GUT panel (bottom dock)
#   2. Click "Run All" — all tests must pass green

# Alternatively, run tests via command line (if Godot is on PATH):
# godot --headless -s addons/gut/gut_cmdln.gd -gdir=tests/models/ -gexit
```

### Regression Gate

Before AND after every phase:
1. `project.godot` must remain unchanged (this task does NOT modify it)
2. `src/scenes/main_menu.tscn` must still load correctly
3. No existing test files are broken by our changes
4. All new GUT tests pass green (once written and implementation complete)
5. No `class_name` conflicts with existing code

---

## Current State Analysis

### What Exists Today

| Item | Status | Location |
|------|--------|----------|
| `src/models/` directory | ✅ Should exist | Created by TASK-001 with `.gdkeep` |
| `src/gdscript/utils/rng_wrapper_clean.gd` | ✅ Exists | v1 prototype — read-only reference |
| `project.godot` | ✅ Exists | Engine config — NOT modified by this task |
| `tests/unit/` | ✅ Exists | v1 test directory — not used by this task |
| `addons/gut/` | ✅ Should exist | GUT addon — pre-requisite for testing |

### What's Missing (Gap Analysis)

| Item | Status | Required By |
|------|--------|-------------|
| `src/models/rng.gd` | ❌ Missing | FR-001 through FR-020 |
| `tests/models/` directory | ❓ May not exist | Test file location |
| `tests/models/test_rng.gd` | ❌ Missing | Section 14 — 31 test functions |

### What Must NOT Change

- `project.godot` — no modifications needed for this task (no autoload)
- `src/gdscript/utils/rng_wrapper_clean.gd` — v1 prototype, read-only reference
- `src/scenes/main_menu.tscn` — existing main menu scene
- Any existing files in `tests/unit/` — must not be broken
- Any files created by TASK-001 (autoloads, utils, etc.)

---

## Development Methodology: TDD Red-Green-Refactor

**ALL implementation work follows strict TDD.** No exceptions.

### The Cycle

1. **RED**: Write a failing test that describes the desired behavior
   - The test MUST fail initially — if it passes, you don't need the test
   - The test MUST be specific and descriptive: `test_method_name_scenario_expected`
   - Run the test suite — confirm it fails

2. **GREEN**: Write the MINIMUM code to make the test pass
   - Do NOT write more code than needed
   - Do NOT refactor yet
   - Do NOT add features not covered by the failing test
   - Run the test suite — confirm it passes (and nothing else broke)

3. **REFACTOR**: Clean up while keeping tests green
   - Extract methods, rename variables, remove duplication
   - Run the test suite after EVERY refactor step
   - If any test fails → undo the refactor and try again

### Test Naming Convention (GDScript / GUT)

```gdscript
# Existence checks
func test_extends_ref_counted() -> void:

# Determinism verification
func test_seed_int_determinism() -> void:

# Bounds checking
func test_randf_bounds() -> void:

# Edge cases
func test_randi_zero() -> void:
```

### Test Structure (GUT)

Every test follows Arrange-Act-Assert:
```gdscript
func test_method_scenario_expected() -> void:
    # Arrange — create instance and seed
    var rng: DeterministicRNG = DeterministicRNG.new()
    rng.seed_int(42)

    # Act — execute the behavior
    var result: int = rng.next_int()

    # Assert — verify the outcome
    assert_gt(result, 0, "next_int() should return positive integer")
```

### Coverage Requirements Per Phase

- ✅ **Existence**: Class exists, extends `RefCounted`, has `class_name`
- ✅ **Seeding**: Integer and string seeding produce deterministic state
- ✅ **Core generation**: `next_int()` produces non-negative 63-bit integers
- ✅ **Numeric methods**: `randf()`, `randi()`, `randi_range()` have correct bounds
- ✅ **Array methods**: `shuffle()`, `pick()`, `weighted_pick()` behave correctly
- ✅ **Edge cases**: Zero seed, empty arrays, swapped arguments, all-zero weights
- ✅ **Performance**: 1M `next_int()` calls under 2 seconds

---

## Phase 0: Pre-Flight & Directory Setup

> **Ticket References**: NFR-016 (single-file), NFR-006 (zero dependencies)
> **AC References**: AC-001
> **Estimated Items**: 6
> **Dependencies**: TASK-001 complete (directory skeleton exists)
> **Validation Gate**: All prerequisite directories exist; no `class_name DeterministicRNG` conflict; GUT available

This phase verifies prerequisites and creates any missing directories. No code is written yet.

### 0.1 Verify Prerequisites

- [ ] **0.1.1** Verify `src/models/` directory exists (created by TASK-001)
  - _Ticket ref: AC-001 (target directory)_
  - _If missing: create `src/models/` directory_
- [ ] **0.1.2** Verify `tests/models/` directory exists; create if not
  - _Ticket ref: Section 14 (test file location)_
  - _If missing: create `tests/models/` directory_
- [ ] **0.1.3** Search codebase for existing `class_name DeterministicRNG` — must find zero results
  - _Ticket ref: NFR-006 (zero external dependencies), Assumption A-08_
  - _Command: `grep -r "class_name DeterministicRNG" src/`_
- [ ] **0.1.4** Verify GUT addon is available at `addons/gut/`
  - _Ticket ref: Assumption A-15_
  - _If missing: note as blocker for test execution phases_
- [ ] **0.1.5** Verify no existing `tests/models/test_rng.gd` file that would be overwritten
  - _Ticket ref: Section 14_

### Phase 0 Validation Gate

- [ ] **0.V.1** `src/models/` directory exists
- [ ] **0.V.2** `tests/models/` directory exists
- [ ] **0.V.3** No `class_name DeterministicRNG` conflict found in codebase
- [ ] **0.V.4** `project.godot` is unchanged (no edits in this phase)
- [ ] **0.V.5** Commit: `"Phase 0: Verify prerequisites and create tests/models/ directory for TASK-002"`

---

## Phase 1: Test File (RED)

> **Ticket References**: Section 14 (all 31 test functions), FR-001 through FR-020
> **AC References**: AC-001 through AC-025 (tests cover all ACs)
> **Estimated Items**: 5
> **Dependencies**: Phase 0 complete (directories exist)
> **Validation Gate**: `tests/models/test_rng.gd` exists with 31 test functions; tests reference `DeterministicRNG` which does not exist = RED

This phase writes the complete test file. All tests will fail because `DeterministicRNG` does not exist yet.

### 1.1 Create Test File

- [ ] **1.1.1** Create `tests/models/test_rng.gd` with helper functions `_make_rng()` and `_make_rng_str()`
  - _Ticket ref: Section 14 — helper functions_
  - _File: `tests/models/test_rng.gd`_
  - _TDD: RED — helpers reference `DeterministicRNG` which does not exist_

- [ ] **1.1.2** Add Section A tests: `test_extends_ref_counted`, `test_is_not_node`, `test_instantiation_without_scene_tree` (3 tests)
  - _Ticket ref: FR-019, AC-001, AC-002, NFR-003_
  - _File: `tests/models/test_rng.gd`_
  - _Tests verify: class structure, RefCounted inheritance, no Node_

- [ ] **1.1.3** Add Section B + C tests: `test_seed_int_determinism`, `test_seed_string_determinism`, `test_seed_int_zero_guard`, `test_reseed_resets_sequence`, `test_different_seeds_different_sequences`, `test_different_string_seeds_different_sequences`, `test_next_int_non_negative` (7 tests)
  - _Ticket ref: FR-001, FR-002, FR-003, FR-004, FR-019, FR-020, AC-003, AC-004, AC-005, AC-006, AC-007, AC-022, AC-023_
  - _File: `tests/models/test_rng.gd`_
  - _Tests verify: seeding, determinism, zero guard, non-negative output_

- [ ] **1.1.4** Add Section D + E + F tests: `test_randf_bounds`, `test_randf_determinism`, `test_randi_bounds`, `test_randi_zero`, `test_randi_negative`, `test_randi_range_bounds`, `test_randi_range_equal`, `test_randi_range_swapped` (8 tests)
  - _Ticket ref: FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, AC-008, AC-009, AC-010, AC-011, AC-012, AC-013_
  - _File: `tests/models/test_rng.gd`_
  - _Tests verify: numeric method bounds, edge cases, auto-swap_

- [ ] **1.1.5** Add Section G + H + I + J tests: `test_shuffle_in_place`, `test_shuffle_determinism`, `test_shuffle_empty`, `test_shuffle_single`, `test_shuffle_preserves_elements`, `test_pick_determinism`, `test_pick_empty`, `test_pick_single`, `test_pick_coverage`, `test_weighted_pick_deterministic_weight`, `test_weighted_pick_last_item`, `test_weighted_pick_empty_items`, `test_weighted_pick_empty_weights`, `test_weighted_pick_all_zero_weights`, `test_weighted_pick_distribution`, `test_weighted_pick_determinism`, `test_next_int_throughput` (13 tests, including 4 shuffle + 4 pick + 7 weighted_pick + 1 perf)
  - _Ticket ref: FR-012, FR-013, FR-014, FR-015, FR-016, FR-017, FR-018, AC-014, AC-015, AC-016, AC-017, AC-018, AC-019, AC-020, AC-021, NFR-001_
  - _File: `tests/models/test_rng.gd`_
  - _Tests verify: shuffle, pick, weighted_pick, performance_

> **Implementation source**: Ticket Section 14 has the complete, copy-pasteable test file with all 31 functions.

### Phase 1 Validation Gate

- [ ] **1.V.1** `tests/models/test_rng.gd` exists and is parseable GDScript
- [ ] **1.V.2** File contains exactly 31 test functions (plus 2 helpers)
- [ ] **1.V.3** All tests reference `DeterministicRNG` — confirm RED state (class does not exist)
- [ ] **1.V.4** Commit: `"Phase 1: Add 31 GUT tests for DeterministicRNG — RED (class not yet implemented)"`

---

## Phase 2: Core Implementation — Seeding & next_int() (GREEN — partial)

> **Ticket References**: FR-001, FR-002, FR-003, FR-004, FR-019, FR-020
> **AC References**: AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007, AC-022, AC-023
> **Estimated Items**: 10
> **Dependencies**: Phase 1 complete (test file exists)
> **Validation Gate**: Section A, B, C tests pass (10 of 31 tests); seeding and next_int() work correctly

### 2.1 Create Class Shell

- [ ] **2.1.1** Create `src/models/rng.gd` with `extends RefCounted` and `class_name DeterministicRNG`
  - _Ticket ref: AC-001, NFR-003 (no Node inheritance)_
  - _File: `src/models/rng.gd`_
  - _Content: class declaration, top-level doc comment_

- [ ] **2.1.2** Add constants `MASK_63` and `MULTIPLIER`
  - _Ticket ref: FR-003 (xorshift64* algorithm), NFR-015 (UPPER_SNAKE_CASE)_
  - _File: `src/models/rng.gd`_
  - _Content: `const MASK_63: int = 0x7FFFFFFFFFFFFFFF`, `const MULTIPLIER: int = 0x2545F4914F6CDD1D`_

- [ ] **2.1.3** Add `_state: int = 0` private state variable
  - _Ticket ref: NFR-002 (single int state), NFR-004 (no heap allocations)_
  - _File: `src/models/rng.gd`_

### 2.2 Implement Seeding Methods

- [ ] **2.2.1** Implement `seed_int(val: int) -> void` with 63-bit masking and zero guard
  - _Ticket ref: FR-001, AC-022 (zero seed guard), NFR-013 (idempotent seeding)_
  - _File: `src/models/rng.gd`_
  - _Logic: `_state = val & MASK_63; if _state == 0: _state = 1`_
  - _Doc comment: `##` describing parameters, masking, zero guard_

- [ ] **2.2.2** Implement `seed_string(s: String) -> void` with SHA-256 hashing
  - _Ticket ref: FR-002, AC-004 (string determinism), NFR-006 (no external deps — uses built-in HashingContext)_
  - _File: `src/models/rng.gd`_
  - _Logic: SHA-256 → first 8 bytes → big-endian int → mask → zero guard_
  - _Doc comment: `##` describing SHA-256 pipeline, byte extraction_

### 2.3 Implement Core Generator

- [ ] **2.3.1** Implement `next_int() -> int` with xorshift64* algorithm
  - _Ticket ref: FR-003, FR-004 (non-negative), AC-003, AC-007_
  - _File: `src/models/rng.gd`_
  - _Logic: XOR shifts (13, 7, 17) → mask → zero guard → multiply → mask → return_
  - _Doc comment: `##` describing algorithm, shift triplet, period_

### 2.4 Verify Section A, B, C Tests

- [ ] **2.4.1** Run Section A tests: `test_extends_ref_counted`, `test_is_not_node`, `test_instantiation_without_scene_tree` — all 3 pass
  - _Ticket ref: AC-001, AC-002, NFR-003_
  - _Expected: 3 pass_

- [ ] **2.4.2** Run Section B tests: `test_seed_int_determinism`, `test_seed_string_determinism`, `test_seed_int_zero_guard`, `test_reseed_resets_sequence`, `test_different_seeds_different_sequences`, `test_different_string_seeds_different_sequences` — all 6 pass
  - _Ticket ref: FR-001, FR-002, FR-019, FR-020, AC-003, AC-004, AC-005, AC-006, AC-022, AC-023_
  - _Expected: 6 pass_

- [ ] **2.4.3** Run Section C test: `test_next_int_non_negative` — passes
  - _Ticket ref: FR-004, AC-007_
  - _Expected: 1 pass (100,000 iterations, all non-negative)_

### Phase 2 Validation Gate

- [ ] **2.V.1** `src/models/rng.gd` exists and is parseable GDScript
- [ ] **2.V.2** File extends `RefCounted` and declares `class_name DeterministicRNG`
- [ ] **2.V.3** `seed_int()` masks to 63 bits and guards zero (FR-001)
- [ ] **2.V.4** `seed_string()` uses SHA-256 and extracts first 8 bytes big-endian (FR-002)
- [ ] **2.V.5** `next_int()` uses xorshift64* with shifts (13, 7, 17) and multiplier (FR-003)
- [ ] **2.V.6** `next_int()` never returns negative (FR-004)
- [ ] **2.V.7** Two instances with same int seed produce identical sequences (FR-019, AC-005)
- [ ] **2.V.8** Two instances with same string seed produce identical sequences (FR-020, AC-006)
- [ ] **2.V.9** All 10 tests in Sections A + B + C pass green
- [ ] **2.V.10** Commit: `"Phase 2: Implement DeterministicRNG class shell, seeding, and next_int() — 10/31 tests green"`

---

## Phase 3: Numeric Methods (GREEN — continued)

> **Ticket References**: FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011
> **AC References**: AC-008, AC-009, AC-010, AC-011, AC-012, AC-013
> **Estimated Items**: 7
> **Dependencies**: Phase 2 complete (core generation works)
> **Validation Gate**: Section D, E, F tests pass (18 of 31 tests cumulative)

### 3.1 Implement Numeric Methods

- [ ] **3.1.1** Implement `randf() -> float` with 53-bit precision and `/ float(1 << 53)` divisor
  - _Ticket ref: FR-005 (range [0.0, 1.0)), FR-006 (53-bit precision), AC-008_
  - _File: `src/models/rng.gd`_
  - _Logic: `next_int()` → mask to 53 bits → divide by 2^53_
  - _Doc comment: `##` describing precision, range guarantee_

- [ ] **3.1.2** Implement `randi(max_val: int) -> int` with modulo and zero/negative guard
  - _Ticket ref: FR-007 (range [0, max_val)), FR-008 (return 0 for max_val ≤ 0), AC-009, AC-010_
  - _File: `src/models/rng.gd`_
  - _Logic: guard `max_val <= 0` → return 0; otherwise `next_int() % max_val`_
  - _Doc comment: `##` describing range, edge cases_

- [ ] **3.1.3** Implement `randi_range(min_val: int, max_val: int) -> int` with auto-swap
  - _Ticket ref: FR-009 (inclusive range), FR-010 (equal returns min), FR-011 (auto-swap), AC-011, AC-012, AC-013_
  - _File: `src/models/rng.gd`_
  - _Logic: swap if min > max → guard equal → `min + next_int() % span`_
  - _Doc comment: `##` describing inclusive range, auto-swap behavior_

### 3.2 Verify Section D, E, F Tests

- [ ] **3.2.1** Run Section D tests: `test_randf_bounds`, `test_randf_determinism` — both pass
  - _Ticket ref: FR-005, FR-006, AC-008_
  - _Expected: 2 pass (100,000 iterations for bounds)_

- [ ] **3.2.2** Run Section E tests: `test_randi_bounds`, `test_randi_zero`, `test_randi_negative` — all 3 pass
  - _Ticket ref: FR-007, FR-008, AC-009, AC-010_
  - _Expected: 3 pass_

- [ ] **3.2.3** Run Section F tests: `test_randi_range_bounds`, `test_randi_range_equal`, `test_randi_range_swapped` — all 3 pass
  - _Ticket ref: FR-009, FR-010, FR-011, AC-011, AC-012, AC-013_
  - _Expected: 3 pass_

### Phase 3 Validation Gate

- [ ] **3.V.1** `randf()` returns values in `[0.0, 1.0)` over 100,000 calls (FR-005, AC-008)
- [ ] **3.V.2** `randi(10)` returns values in `{0..9}` and all 10 values appear (FR-007, AC-009)
- [ ] **3.V.3** `randi(0)` returns `0`; `randi(-5)` returns `0` (FR-008, AC-010)
- [ ] **3.V.4** `randi_range(3, 7)` returns values in `{3,4,5,6,7}` (FR-009, AC-011)
- [ ] **3.V.5** `randi_range(5, 5)` always returns `5` (FR-010, AC-012)
- [ ] **3.V.6** `randi_range(7, 3)` auto-swaps and produces same output as `randi_range(3, 7)` (FR-011, AC-013)
- [ ] **3.V.7** Cumulative: 18 of 31 tests pass green
- [ ] **3.V.8** Commit: `"Phase 3: Add randf(), randi(), randi_range() numeric methods — 18/31 tests green"`

---

## Phase 4: Array Methods (GREEN — complete)

> **Ticket References**: FR-012, FR-013, FR-014, FR-015, FR-016, FR-017, FR-018
> **AC References**: AC-014, AC-015, AC-016, AC-017, AC-018, AC-019, AC-020, AC-021
> **Estimated Items**: 8
> **Dependencies**: Phase 3 complete (numeric methods available for shuffle/pick)
> **Validation Gate**: ALL 31 tests pass green; Section G, H, I, J tests pass

### 4.1 Implement Array Methods

- [ ] **4.1.1** Implement `shuffle(array: Array) -> Array` with Fisher-Yates in-place shuffle
  - _Ticket ref: FR-012 (Fisher-Yates, returns same reference), FR-013 (empty/single edge cases), AC-014, AC-015_
  - _File: `src/models/rng.gd`_
  - _Logic: iterate `i` from `n-1` to `1` → swap `array[i]` with `array[randi(i+1)]`_
  - _Doc comment: `##` describing in-place, Fisher-Yates, edge cases_

- [ ] **4.1.2** Implement `pick(array: Array) -> Variant` with uniform random selection
  - _Ticket ref: FR-014 (uniform pick), FR-015 (empty returns null), AC-016, AC-017_
  - _File: `src/models/rng.gd`_
  - _Logic: guard empty → return null; otherwise `array[randi(array.size())]`_
  - _Doc comment: `##` describing uniform selection, null on empty_

- [ ] **4.1.3** Implement `weighted_pick(items: Array, weights: Array[float]) -> Variant` with cumulative weight scan
  - _Ticket ref: FR-016 (probability proportional to weight), FR-017 (empty returns null), FR-018 (all-zero returns null), AC-018, AC-019, AC-020, AC-021_
  - _File: `src/models/rng.gd`_
  - _Logic: guard empty/mismatched → sum positive weights → guard zero total → roll → cumulative scan → fallback_
  - _Doc comment: `##` describing weight normalization, null cases, negative weight handling_

### 4.2 Verify Section G, H, I, J Tests

- [ ] **4.2.1** Run Section G tests: `test_shuffle_in_place`, `test_shuffle_determinism`, `test_shuffle_empty`, `test_shuffle_single`, `test_shuffle_preserves_elements` — all 5 pass
  - _Ticket ref: FR-012, FR-013, AC-014, AC-015_
  - _Expected: 5 pass_

- [ ] **4.2.2** Run Section H tests: `test_pick_determinism`, `test_pick_empty`, `test_pick_single`, `test_pick_coverage` — all 4 pass
  - _Ticket ref: FR-014, FR-015, AC-016, AC-017_
  - _Expected: 4 pass_

- [ ] **4.2.3** Run Section I tests: `test_weighted_pick_deterministic_weight`, `test_weighted_pick_last_item`, `test_weighted_pick_empty_items`, `test_weighted_pick_empty_weights`, `test_weighted_pick_all_zero_weights`, `test_weighted_pick_distribution`, `test_weighted_pick_determinism` — all 7 pass
  - _Ticket ref: FR-016, FR-017, FR-018, AC-018, AC-019, AC-020, AC-021_
  - _Expected: 7 pass_

- [ ] **4.2.4** Run Section J test: `test_next_int_throughput` — passes
  - _Ticket ref: NFR-001 (1M calls < 2 seconds)_
  - _Expected: 1 pass_

### Phase 4 Validation Gate

- [ ] **4.V.1** `shuffle()` returns same array reference (in-place) (FR-012, AC-014)
- [ ] **4.V.2** `shuffle([])` returns `[]`; `shuffle([42])` returns `[42]` (FR-013, AC-015)
- [ ] **4.V.3** `pick([])` returns `null` (FR-015, AC-017)
- [ ] **4.V.4** `weighted_pick(["A","B"], [1.0, 0.0])` always returns `"A"` (FR-016, AC-018)
- [ ] **4.V.5** `weighted_pick([], [])` returns `null` (FR-017, AC-020)
- [ ] **4.V.6** `weighted_pick(["A","B"], [0.0, 0.0])` returns `null` (FR-018, AC-021)
- [ ] **4.V.7** ALL 31 tests pass green
- [ ] **4.V.8** Commit: `"Phase 4: Add shuffle(), pick(), weighted_pick() array methods — ALL 31 tests green"`

---

## Phase 5: End-to-End Validation & Cleanup

> **Ticket References**: All FRs, all NFRs, all ACs
> **AC References**: AC-001 through AC-025, NFR-001 through NFR-016
> **Estimated Items**: 12
> **Dependencies**: ALL prior phases complete (all 31 tests green)
> **Validation Gate**: Full code quality pass, all NFRs verified, final commit

### 5.1 Full Test Suite Run

- [ ] **5.1.1** Run complete GUT test suite for `tests/models/test_rng.gd` — all 31 tests pass green
  - _Ticket ref: Section 14_
  - _Expected: 31 pass, 0 fail, 0 error_
- [ ] **5.1.2** Verify no existing tests in `tests/unit/` are broken by our changes
  - _Ticket ref: Regression gate_

### 5.2 Code Quality Verification (NFRs)

- [ ] **5.2.1** Verify class extends `RefCounted`, NOT `Node` (NFR-003, AC-001)
  - _Inspect: `extends RefCounted` on line 1_
- [ ] **5.2.2** Verify all parameters, return types, and local variables have explicit type annotations (NFR-005, AC-025)
  - _Inspect: every `func`, `var`, `const` has `: Type`_
- [ ] **5.2.3** Verify zero external dependencies — no `preload()`, no autoload references, no imports (NFR-006)
  - _Inspect: only built-in `HashingContext` used_
- [ ] **5.2.4** Verify no signals declared (NFR-008)
  - _Inspect: no `signal` keyword in file_
- [ ] **5.2.5** Verify no `_ready()`, `_process()`, or other lifecycle callbacks (NFR-009)
  - _Inspect: no engine callback functions_
- [ ] **5.2.6** Verify no `@export` or `@onready` annotations (NFR-014)
  - _Inspect: no `@` annotations_
- [ ] **5.2.7** Verify no `print()`, `push_warning()`, or `push_error()` in production code (NFR-011)
  - _Inspect: zero debug output statements_
- [ ] **5.2.8** Verify all 9 public methods have `##` doc comments (NFR-012, AC-024)
  - _Methods: `seed_int`, `seed_string`, `next_int`, `randf`, `randi`, `randi_range`, `shuffle`, `pick`, `weighted_pick`_
- [ ] **5.2.9** Verify naming conventions: `snake_case` methods, `PascalCase` class, `UPPER_SNAKE_CASE` constants (NFR-015)
  - _Inspect: `DeterministicRNG`, `MASK_63`, `MULTIPLIER`, `seed_int`, `next_int`, etc._
- [ ] **5.2.10** Verify entire class resides in single file `src/models/rng.gd` (NFR-016)
  - _No partials, no helper scripts_

### Phase 5 Validation Gate

- [ ] **5.V.1** All 31 tests pass green
- [ ] **5.V.2** All NFRs (NFR-001 through NFR-016) verified
- [ ] **5.V.3** All ACs (AC-001 through AC-025) satisfied
- [ ] **5.V.4** `project.godot` unchanged from pre-task state
- [ ] **5.V.5** Commit: `"TASK-002 complete: Deterministic RNG wrapper (DeterministicRNG) — 31 tests, all green"`

---

## Phase Dependency Graph

```
Phase 0 (Pre-Flight) ──→ Phase 1 (Test File — RED) ──→ Phase 2 (Seeding + next_int — GREEN partial)
                                                              │
                                                              ▼
                                                        Phase 3 (Numeric Methods — GREEN continued)
                                                              │
                                                              ▼
                                                        Phase 4 (Array Methods — GREEN complete)
                                                              │
                                                              ▼
                                                        Phase 5 (E2E Validation + Cleanup)
```

**Parallelism note**: This task is strictly sequential — each phase builds on the previous one. Phase 2 cannot begin until Phase 1's test file exists. Phases 3 and 4 depend on prior methods being implemented.

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 0 | Pre-flight & directory setup | 6 | 0 | 0 | ⬜ Not Started |
| Phase 1 | Test file — RED | 5 | 0 | 31 (RED) | ⬜ Not Started |
| Phase 2 | Seeding & next_int() — GREEN partial | 10 | 0 | 10 | ⬜ Not Started |
| Phase 3 | Numeric methods — GREEN continued | 7 | 0 | 8 | ⬜ Not Started |
| Phase 4 | Array methods — GREEN complete | 8 | 0 | 13 | ⬜ Not Started |
| Phase 5 | E2E validation & cleanup | 12 | 0 | 31 | ⬜ Not Started |
| **Total** | | **48** | **0** | **31** | **⬜ Phase 0 Next** |

---

## File Change Summary

### New Files

| File | Phase | Purpose |
|------|-------|---------|
| `src/models/rng.gd` | 2–4 | `DeterministicRNG` class — xorshift64* PRNG with 9 public methods |
| `tests/models/test_rng.gd` | 1 | 31 GUT unit tests covering all FRs and ACs |

### Modified Files

None — this task creates new files only and does not modify `project.godot` or any existing code.

### Deleted Files

None — this task is additive only.

### Directories Created (if missing)

| Directory | Phase | Purpose |
|-----------|-------|---------|
| `tests/models/` | 0 | Test file location (may already exist) |

---

## Commit Strategy

| Phase | Commit Message | Tests After |
|-------|----------------|-------------|
| 0 | `"Phase 0: Verify prerequisites and create tests/models/ directory for TASK-002"` | 0 (no tests yet) |
| 1 | `"Phase 1: Add 31 GUT tests for DeterministicRNG — RED (class not yet implemented)"` | 31 (RED) |
| 2 | `"Phase 2: Implement DeterministicRNG class shell, seeding, and next_int() — 10/31 tests green"` | 10 ✅ / 21 ❌ |
| 3 | `"Phase 3: Add randf(), randi(), randi_range() numeric methods — 18/31 tests green"` | 18 ✅ / 13 ❌ |
| 4 | `"Phase 4: Add shuffle(), pick(), weighted_pick() array methods — ALL 31 tests green"` | 31 ✅ |
| 5 | `"TASK-002 complete: Deterministic RNG wrapper (DeterministicRNG) — 31 tests, all green"` | 31 ✅ |

---

## Deviation Tracking

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| _(none yet)_ | | | | | |

> **Note**: The ticket references `src/gdscript/utils/rng_wrapper_clean.gd` as a v1 prototype. The new implementation must preserve the same algorithm constants (shifts: 13, 7, 17; multiplier: `0x2545F4914F6CDD1D`) but fix the design bug (`extends Node` → `extends RefCounted`) and add missing methods (`randi_range`, `shuffle`, `pick`, `weighted_pick`).

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| `src/models/` directory doesn't exist (TASK-001 not yet run) | Medium | Low | Create directory in Phase 0 if missing | 0 |
| `tests/models/` directory doesn't exist | High | Low | Create directory in Phase 0 | 0 |
| `class_name DeterministicRNG` conflicts with existing v1 code | Low | High | Search codebase in Phase 0; rename if conflict found | 0 |
| GUT addon not installed / incompatible with Godot 4.5+ | Medium | High | Verify in Phase 0; install GUT v9.x+ if missing | 0 |
| GDScript `int` overflow behavior differs across platforms | Very Low | Critical | xorshift64* relies on wrapping overflow; tested by determinism tests | 2 |
| `HashingContext.HASH_SHA256` unavailable in target Godot version | Very Low | High | Verify SHA-256 availability; fall back to simpler hash if needed | 2 |
| `Array[float]` typed array syntax not supported in method signatures | Low | Medium | Fall back to untyped `Array` and document as deviation | 4 |
| Performance test (`test_next_int_throughput`) fails on slow hardware | Low | Low | Test is non-blocking per ticket; increase threshold if needed | 4 |

---

## Handoff State (2025-07-18)

### What's Complete
- Implementation plan written and ready for execution

### What's In Progress
- Nothing — plan is at Phase 0 (not started)

### What's Blocked
- Nothing — TASK-002 has no upstream dependencies (Wave 1)

### Next Steps
1. Execute Phase 0: Verify prerequisites, create `tests/models/` directory
2. Execute Phase 1: Write complete test file with 31 functions (RED)
3. Execute Phase 2: Implement class shell, seeding methods, `next_int()` (GREEN partial — 10/31)
4. Execute Phase 3: Implement `randf()`, `randi()`, `randi_range()` (GREEN continued — 18/31)
5. Execute Phase 4: Implement `shuffle()`, `pick()`, `weighted_pick()` (GREEN complete — 31/31)
6. Execute Phase 5: Full end-to-end validation, NFR audit, final commit

---

## Ticket FR/AC Coverage Matrix

Every Functional Requirement and Acceptance Criterion from the ticket is mapped below.

### Functional Requirements → Phase Items

| FR | Description | Phase | Checkbox |
|----|-------------|-------|----------|
| FR-001 | `seed_int(val)` sets `_state` with masking and zero guard | 2 | 2.2.1 |
| FR-002 | `seed_string(s)` uses SHA-256, first 8 bytes, big-endian, mask, zero guard | 2 | 2.2.2 |
| FR-003 | `next_int()` uses xorshift64* (shifts 13,7,17; multiplier) returns 63-bit int | 2 | 2.3.1 |
| FR-004 | `next_int()` never returns negative | 2 | 2.3.1, 2.4.3 |
| FR-005 | `randf()` returns `[0.0, 1.0)` | 3 | 3.1.1 |
| FR-006 | `randf()` uses 53-bit precision with `/ float(1 << 53)` | 3 | 3.1.1 |
| FR-007 | `randi(max_val)` returns `[0, max_val)` | 3 | 3.1.2 |
| FR-008 | `randi(max_val)` returns 0 when `max_val <= 0` | 3 | 3.1.2 |
| FR-009 | `randi_range(min, max)` returns inclusive `[min, max]` | 3 | 3.1.3 |
| FR-010 | `randi_range(min, max)` returns `min` when `min == max` | 3 | 3.1.3 |
| FR-011 | `randi_range(min, max)` auto-swaps when `min > max` | 3 | 3.1.3 |
| FR-012 | `shuffle()` does Fisher-Yates in-place, returns same reference | 4 | 4.1.1 |
| FR-013 | `shuffle([])` returns `[]`; `shuffle([x])` returns `[x]` | 4 | 4.1.1 |
| FR-014 | `pick()` returns uniformly random element | 4 | 4.1.2 |
| FR-015 | `pick([])` returns `null` | 4 | 4.1.2 |
| FR-016 | `weighted_pick()` selects proportional to weight | 4 | 4.1.3 |
| FR-017 | `weighted_pick()` returns `null` if items or weights empty | 4 | 4.1.3 |
| FR-018 | `weighted_pick()` returns `null` if all weights are 0.0 | 4 | 4.1.3 |
| FR-019 | Two instances with same int seed produce identical sequences | 2 | 2.4.2 |
| FR-020 | Two instances with same string seed produce identical sequences | 2 | 2.4.2 |

### Acceptance Criteria → Validation Gates

| AC | Description | Phase | Verification |
|----|-------------|-------|--------------|
| AC-001 | File exists with `extends RefCounted` and `class_name DeterministicRNG` | 2 | 2.V.1, 2.V.2 |
| AC-002 | `DeterministicRNG.new()` succeeds without scene tree | 2 | 2.4.1 |
| AC-003 | `seed_int(42)` + 10 `next_int()` = hardcoded expected sequence | 2 | 2.4.2 (determinism test) |
| AC-004 | `seed_string("FIRE-42")` + 10 `next_int()` = hardcoded expected sequence | 2 | 2.4.2 (determinism test) |
| AC-005 | Two instances seeded `seed_int(42)` produce identical 1,000-element sequences | 2 | 2.V.7 |
| AC-006 | Two instances seeded `seed_string("FIRE-42")` produce identical 1,000-element sequences | 2 | 2.V.8 |
| AC-007 | `next_int()` never negative over 100,000 calls | 2 | 2.4.3, 2.V.6 |
| AC-008 | `randf()` in `[0.0, 1.0)` over 100,000 calls | 3 | 3.V.1 |
| AC-009 | `randi(10)` in `{0..9}`, all 10 values appear | 3 | 3.V.2 |
| AC-010 | `randi(0)` returns 0; `randi(-1)` returns 0 | 3 | 3.V.3 |
| AC-011 | `randi_range(3,7)` in `{3,4,5,6,7}`, all 5 values appear | 3 | 3.V.4 |
| AC-012 | `randi_range(5,5)` always returns 5 | 3 | 3.V.5 |
| AC-013 | `randi_range(7,3)` auto-swaps | 3 | 3.V.6 |
| AC-014 | `shuffle([1,2,3,4,5])` returns same reference, deterministic order | 4 | 4.V.1 |
| AC-015 | `shuffle([])` returns `[]`; `shuffle([42])` returns `[42]` | 4 | 4.V.2 |
| AC-016 | `pick(["a","b","c"])` deterministic per seed; all elements appear | 4 | 4.2.2 |
| AC-017 | `pick([])` returns `null` | 4 | 4.V.3 |
| AC-018 | `weighted_pick(["A","B"], [1.0, 0.0])` always returns `"A"` | 4 | 4.V.4 |
| AC-019 | `weighted_pick(["A","B"], [0.0, 1.0])` always returns `"B"` | 4 | 4.2.3 |
| AC-020 | `weighted_pick([], [])` returns `null` | 4 | 4.V.5 |
| AC-021 | `weighted_pick(["A","B"], [0.0, 0.0])` returns `null` | 4 | 4.V.6 |
| AC-022 | `seed_int(0)` does not produce stuck sequence (zero guard) | 2 | 2.4.2, 2.V.3 |
| AC-023 | Re-seeding resets sequence identically | 2 | 2.4.2 |
| AC-024 | All public methods have `##` doc comments | 5 | 5.2.8 |
| AC-025 | All parameters and return types have type annotations | 5 | 5.2.2 |

### Non-Functional Requirements → Verification

| NFR | Description | Phase | Verification |
|-----|-------------|-------|--------------|
| NFR-001 | 1M `next_int()` in < 1s (2s threshold in test) | 4 | 4.2.4 |
| NFR-002 | Single `int` mutable state | 2 | 2.1.3 |
| NFR-003 | Extends `RefCounted`, not `Node` | 2, 5 | 2.V.2, 5.2.1 |
| NFR-004 | No heap allocations per call (numeric methods) | 5 | 5.2.3 (code inspection) |
| NFR-005 | Type hints on all variables, params, returns | 5 | 5.2.2 |
| NFR-006 | Zero external dependencies | 5 | 5.2.3 |
| NFR-007 | Instantiation < 1 μs | 2 | 2.4.1 (implicit) |
| NFR-008 | No signals | 5 | 5.2.4 |
| NFR-009 | No `_ready()`, `_process()`, or lifecycle callbacks | 5 | 5.2.5 |
| NFR-010 | GDScript 4.x compatibility | 2–4 | All phases (parseable by Godot 4.5) |
| NFR-011 | No `print()` or debug output | 5 | 5.2.7 |
| NFR-012 | `##` doc comments on all public methods | 5 | 5.2.8 |
| NFR-013 | Idempotent seeding | 2 | 2.4.2 (reseed test) |
| NFR-014 | No `@export` or `@onready` | 5 | 5.2.6 |
| NFR-015 | Naming convention (snake_case, PascalCase, UPPER_SNAKE) | 5 | 5.2.9 |
| NFR-016 | Single-file implementation | 5 | 5.2.10 |

---

*End of TASK-002 Implementation Plan*
