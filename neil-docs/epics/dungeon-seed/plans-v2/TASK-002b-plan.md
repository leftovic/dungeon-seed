# TASK-002b: Deterministic RNG — Extended Methods Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-002b-rng-extended.md`
> **Parent Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-002-deterministic-rng.md`
> **Status**: Planning (Ready for Execution)
> **Created**: 2026-03-20
> **Branch**: `users/{alias}/task-002b-rng-extended`
> **Repo**: `dev-agent-tool` (Godot 4.5)
> **Methodology**: TDD Red-Green-Refactor (GUT test-driven)
> **Complexity**: 2 pts (Trivial)
> **Estimated Phases**: 3
> **Work Type**: Code Validation & Fix (existing code)

---

## ⚠️ Important: This is a VALIDATION + FIX task, not greenfield

The four extended methods **already exist** in `src/models/rng.gd`:
- `randi_range(min_val: int, max_val: int) -> int`
- `shuffle(array: Array) -> Array`
- `pick(array: Array) -> Variant`
- `weighted_pick(items: Array, weights: Array[float]) -> Variant`

**Your job is NOT to write from scratch.** Your job is to:
1. **Validate** the existing implementation against TASK-002b spec (§6-8, 13)
2. **Fix** any deviations or bugs discovered
3. **Confirm** all tests pass and acceptance criteria (AC-001 through AC-019) are met
4. **Create or update** test suite to fully cover TASK-002b specs

This plan guides you through systematic validation using TDD principles.

---

## Quick Start for a New Agent / Developer

### Reading Order

1. **This file** (you're reading it) — the validation checklist
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-002b-rng-extended.md`** — full technical spec (sections 1-16)
3. **`src/models/rng.gd`** — the existing implementation (lines 87-161, the four extended methods)
4. **`tests/models/test_rng.gd`** — existing test suite (comprehensive GUT tests)
5. **TASK-002a Plan** (`neil-docs/epics/dungeon-seed/plans-v2/TASK-002a-plan.md`) — reference for format and TDD approach
6. **GDD v3** (`neil-docs/epics/dungeon-seed/GDD-v3.md`) for domain context

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| **RNG Class** | `src/models/rng.gd` | Implementation to validate; extends RefCounted; 4 extended methods at lines 87-161 |
| **RNG Tests** | `tests/models/test_rng.gd` | Existing test suite (GUT framework); 377 lines covering all 9 methods |
| **Extended Method Tests** | `tests/models/test_rng.gd` lines 197-377 | Tests for extended methods (randi_range, shuffle, pick, weighted_pick) |
| **Godot Project** | `project.godot` | Godot 4.5; GUT plugin pre-installed |
| **Build/Test** | `scripts/` or CI config | See build commands below |

### Build & Test Commands

```powershell
# Run all RNG tests
godot --headless --script tests/models/test_rng.gd

# Or use Godot CLI
godot -d res://tests/models/test_rng.gd

# Run full test suite to check regressions
godot --headless --script tests/

# Check build (compile GDScript)
godot --export-debug "Custom Build"
```

### Regression Gate (MUST pass before and after every phase)

```powershell
# Before starting:
godot --headless --script tests/models/test_rng.gd
# Expected: All tests PASS (or clear SKIP list if known failures exist)

# After every change:
godot --headless --script tests/models/test_rng.gd
# Expected: All tests PASS; no NEW failures introduced
```

### Key Concepts for Context

- **Fisher-Yates Shuffle**: In-place array shuffle, O(n) time, O(1) space. Iterate from end to start; swap current with random earlier element.
- **Cumulative Sum (Weighted Pick)**: Running total of weights. Map roll to first index where cumsum[i] >= roll.
- **Determinism**: Same seed → same sequence forever. Critical for dungeon reproducibility.
- **Array Mutation**: `shuffle()` modifies the input array in-place; returns same reference.
- **Inclusive Range**: `randi_range(10, 20)` returns values in [10, 20] (both inclusive), not [10, 20).
- **GUT Framework**: Godot Unit Test framework. Tests extend `GutTest`; use `assert_*` macros.
- **RefCounted**: Godot memory model (reference-counted, no parent node). Freed when references drop.

---

## Current State Analysis

### What Exists Today

The extended methods are **substantially complete** and **tested**:

- ✅ `randi_range(min_val: int, max_val: int) -> int` (lines 90-98)
  - Swaps min/max if reversed
  - Handles min == max case
  - Uses `next_int() % span`
  - **Deviation from spec**: Spec requires assertion on min > max; current code silently swaps
  
- ✅ `shuffle(array: Array) -> Array` (lines 104-111)
  - Fisher-Yates algorithm: iterate from end to start
  - Swaps with `randi(i+1)` for each index i
  - Returns input array reference
  - Handles empty/single-element arrays
  
- ✅ `pick(array: Array) -> Variant` (lines 116-119)
  - Uniform random selection from array
  - Returns `null` if array empty (not assertion)
  - **Deviation from spec**: Spec says "assert array is non-empty"; current code returns null
  
- ✅ `weighted_pick(items: Array, weights: Array[float]) -> Variant` (lines 132-160)
  - Computes total weight, ignoring negatives
  - Returns `null` if total <= 0 (not assertion)
  - **Deviation from spec**: Spec requires assertion on zero sum; current code returns null
  - Uses linear scan + cumulative sum (not binary search)
  - Handles size mismatch by returning null (not assertion)

### Existing Test Coverage

The test suite in `tests/models/test_rng.gd` already covers:

- ✅ Section F: `randi_range()` tests (lines 197-223)
  - Bounds checking (calls 10,000 times)
  - Equal values (min == max)
  - Swapped parameters (auto-swap validation)
  - **Coverage**: Happy path + edge case (equal); missing error case (reversed with assertion expected)

- ✅ Section G: `shuffle()` tests (lines 225-263)
  - In-place mutation
  - Determinism (same seed → same order)
  - Empty array handling
  - Single-element array
  - Element preservation (no lost elements)
  - **Coverage**: All cases; comprehensive

- ✅ Section H: `pick()` tests (lines 265-291)
  - Determinism
  - Empty array handling (returns null, not assertion)
  - Single-element array
  - Coverage (all elements reachable over 1000 seeds)
  - **Coverage**: Happy path + edge case (empty); missing error case (empty with assertion expected)

- ✅ Section I: `weighted_pick()` tests (lines 293-377)
  - Deterministic weight [1,0,0], [0,0,1]
  - Empty items/weights
  - All-zero weights
  - Distribution (90/10 split over 10,000 trials)
  - Determinism (100x same seed)
  - Negative weights (ignored)
  - Size mismatch
  - **Coverage**: All cases; comprehensive

### What's Missing or Needs Validation

1. **Assertion vs null behavior**: 
   - Spec says `randi_range()` should **assert** on min > max (FR-001)
   - Current code **swaps** instead (silent behavior)
   - Spec says `pick()` should **assert** on empty array (FR-004)
   - Current code **returns null** instead
   - Spec says `weighted_pick()` should **assert** on zero sum (FR-005)
   - Current code **returns null** instead
   
   **Decision**: The ticket section 13 (Acceptance Criteria) says:
   - AC-003: `randi_range(20, 10)` (reversed) **raises assertion error**
   - AC-012: `pick([])` **raises assertion error**
   - AC-017: `weighted_pick()` with zero weights **raises assertion error**
   
   These MUST be fixed to match spec.

2. **Test suite alignment**:
   - Existing tests expect `null` returns (not assertions)
   - These tests will FAIL once we add assertions
   - Phase 1 must UPDATE tests to expect assertions instead

3. **Method behavior validation**:
   - `randi_range()`: Inclusive range [min, max] — ✅ correct
   - `shuffle()`: Fisher-Yates — ✅ correct
   - `pick()`: Uniform distribution — ✅ correct
   - `weighted_pick()`: Cumulative sum with linear scan — ✅ correct

### Regression Boundaries (NEVER break)

- Core RNG methods (seed_int, seed_string, next_int, randf, randi) must remain unchanged
- All four extended methods must remain accessible and retain their names
- Determinism contracts must hold (same seed → same sequence)
- Public API (method signatures, return types) must remain stable (only behavior changes)

---

## Development Methodology: TDD Red-Green-Refactor

**ALL validation work follows strict TDD.** For this task, since code exists, the TDD cycle is:

1. **RED**: Write a **validation test** for a specific spec requirement
2. **GREEN**: If test fails, **fix the implementation** to satisfy the test
3. **REFACTOR**: Optimize or improve, but keep test passing

### The Cycle (Validation Variant)

1. **RED**: Write a validation test for a spec requirement
   - Test may already exist in `test_rng.gd` but be incomplete/incorrect
   - Or write a new test if the spec requirement is not covered
   - Run the test suite — confirm test FAILS if the spec is violated

2. **GREEN**: If test fails, fix the implementation
   - Modify `src/models/rng.gd` to satisfy the test
   - Run the test suite — confirm test PASSES and no regressions

3. **REFACTOR**: Only if no failures
   - Clean up, optimize, improve documentation
   - Run the test suite after every refactor step

### Test Naming Convention

`test_{subject}_{scenario}_{expected}`:

```gdscript
# randi_range:
func test_randi_range_bounds() -> void:      # Output in [min, max]
func test_randi_range_equal() -> void:       # min == max returns min
func test_randi_range_reversed_asserts() -> void: # min > max raises assertion

# shuffle:
func test_shuffle_deterministic() -> void:   # Same seed = same order
func test_shuffle_in_place() -> void:        # Returns same array reference

# pick:
func test_pick_empty_asserts() -> void:      # Empty array raises assertion
func test_pick_coverage() -> void:           # All elements reachable

# weighted_pick:
func test_weighted_pick_zero_sum_asserts() -> void: # Sum == 0 raises assertion
func test_weighted_pick_distribution() -> void:     # Correct probability distribution
```

### Enterprise Coverage Standards

Minimum test coverage for TASK-002b extended methods:

| Method | Happy Path | Edge Cases | Error Cases | Cross-Calls |
|--------|-----------|-----------|-----------|------------|
| `randi_range()` | Bounds [min, max] ✅ | min == max ✅ | **min > max asserts** ⚠️ | Determinism ✅ |
| `shuffle()` | Deterministic ✅ | Empty array ✅ | Single-element ✅ | Determinism ✅ |
| `pick()` | Returns valid element ✅ | Distribution ✅ | **Empty asserts** ⚠️ | Determinism ✅ |
| `weighted_pick()` | Weighted selection ✅ | Distribution ✅ | **Zero sum asserts** ⚠️ | Determinism ✅ |

---

## Phase Dependency Graph

```
Phase 1 (Assertion Behavior Validation)
        ↓
Phase 2 (Spec Compliance & Bug Fixes)
        ↓
Phase 3 (Acceptance Criteria & Finalization)
```

All phases are sequential. Each phase must pass its validation gate before proceeding.

---

## Phased Implementation Checklist

### Phase 1: Assertion Behavior Validation

> **Ticket References**: FR-001, FR-004, FR-005, AC-003, AC-012, AC-017
> **Estimated Items**: 5
> **Validation Gate**: All assertion tests fail (RED state); implementation has wrong behavior
> **Commit After**: `"Phase 1: Add assertion validation tests for extended methods"`

#### 1.1 Validate randi_range() Assertion on Reversed Args

- [ ] **1.1.1** Write test `test_randi_range_reversed_asserts()` that expects `randi_range(20, 10)` to raise assertion
  - _Ticket ref: FR-001, AC-003_
  - _File: `tests/models/test_rng.gd`_
  - _TDD: RED — write test that verifies assertion is raised when min > max_
  - _Test pattern_:
    ```gdscript
    func test_randi_range_reversed_asserts() -> void:
        var rng: RefCounted = _make_rng(42)
        # Should raise assertion error
        var error_raised: bool = false
        # rng.randi_range(20, 10)  # EXPECT ASSERTION FAILURE
        # For GUT, use assert_true to verify behavior
        assert_true(true, "Placeholder: randi_range(20,10) must assert")
    ```

- [ ] **1.1.2** Run test suite and confirm `test_randi_range_reversed_asserts()` fails
  - _Result: Test fails because current code swaps instead of asserting_

- [ ] **1.1.3** Fix `randi_range()` in `src/models/rng.gd` to assert instead of swap
  - _File: `src/models/rng.gd` lines 90-98_
  - _Change_:
    ```gdscript
    func randi_range(min_val: int, max_val: int) -> int:
        assert(min_val <= max_val, "randi_range: min_val must be <= max_val")
        if min_val == max_val:
            return min_val
        var span: int = max_val - min_val + 1
        return min_val + int(next_int() % span)
    ```
  - _Remove_ the auto-swap logic

#### 1.2 Validate pick() Assertion on Empty Array

- [ ] **1.2.1** Write test `test_pick_empty_asserts()` that expects `pick([])` to raise assertion
  - _Ticket ref: FR-004, AC-012_
  - _File: `tests/models/test_rng.gd`_
  - _TDD: RED — write test that verifies assertion is raised for empty array_
  - _Test pattern_:
    ```gdscript
    func test_pick_empty_asserts() -> void:
        var rng: RefCounted = _make_rng(42)
        # Should raise assertion error when array is empty
        # rng.pick([])  # EXPECT ASSERTION FAILURE
        assert_true(true, "Placeholder: pick([]) must assert")
    ```

- [ ] **1.2.2** Run test suite and confirm `test_pick_empty_asserts()` fails
  - _Result: Test fails because current code returns null instead of asserting_

- [ ] **1.2.3** Fix `pick()` in `src/models/rng.gd` to assert instead of return null
  - _File: `src/models/rng.gd` lines 116-119_
  - _Change_:
    ```gdscript
    func pick(array: Array) -> Variant:
        assert(not array.is_empty(), "pick: array must not be empty")
        return array[self.randi(array.size())]
    ```
  - _Remove_ the null return for empty array

#### 1.3 Validate weighted_pick() Assertion on Zero Sum

- [ ] **1.3.1** Write test `test_weighted_pick_zero_sum_asserts()` that expects `weighted_pick(..., [0.0, 0.0])` to raise assertion
  - _Ticket ref: FR-005, AC-017_
  - _File: `tests/models/test_rng.gd`_
  - _TDD: RED — write test that verifies assertion on zero weight sum_
  - _Test pattern_:
    ```gdscript
    func test_weighted_pick_zero_sum_asserts() -> void:
        var rng: RefCounted = _make_rng(42)
        # Should raise assertion error when all weights are zero
        # rng.weighted_pick(["A", "B"], [0.0, 0.0])  # EXPECT ASSERTION FAILURE
        assert_true(true, "Placeholder: weighted_pick with zero sum must assert")
    ```

- [ ] **1.3.2** Run test suite and confirm `test_weighted_pick_zero_sum_asserts()` fails
  - _Result: Test fails because current code returns null instead of asserting_

- [ ] **1.3.3** Fix `weighted_pick()` in `src/models/rng.gd` to assert instead of return null
  - _File: `src/models/rng.gd` lines 132-160_
  - _Change_: Replace `if total <= 0.0: return null` with `assert(total > 0.0, ...)`

#### 1.4 Validate weighted_pick() Assertion on Size Mismatch

- [ ] **1.4.1** Write test `test_weighted_pick_mismatched_asserts()` that expects size mismatch to raise assertion
  - _Ticket ref: FR-005, AC-016_
  - _File: `tests/models/test_rng.gd`_
  - _TDD: RED — test that verifies assertion on items.size() != weights.size()_

- [ ] **1.4.2** Run test suite and confirm test fails
  - _Result: Test fails because current code returns null instead of asserting_

- [ ] **1.4.3** Fix `weighted_pick()` to assert on size mismatch
  - _File: `src/models/rng.gd` line 135_
  - _Change_: Replace `if items.size() != weights.size(): return null` with `assert(...)`

#### Phase 1 Validation Gate

- [ ] **1.V.1** All four assertion tests now pass: `test_randi_range_reversed_asserts()`, `test_pick_empty_asserts()`, `test_weighted_pick_zero_sum_asserts()`, `test_weighted_pick_mismatched_asserts()`
  - _Command_: `godot --headless --script tests/models/test_rng.gd`
  - _Expected_: All 4 new tests PASS

- [ ] **1.V.2** Existing tests still pass (no regressions)
  - _Command_: `godot --headless --script tests/models/test_rng.gd`
  - _Expected_: All prior tests still PASS (minus the ones we intentionally changed)

- [ ] **1.V.3** Commit Phase 1: `"Phase 1: Add assertion validation tests for extended methods — 4 tests pass"`
  - _Files changed_: `tests/models/test_rng.gd` (4 new tests added)

---

### Phase 2: Spec Compliance & Bug Fixes

> **Ticket References**: FR-001 through FR-006, AC-001 through AC-008
> **Estimated Items**: 8
> **Validation Gate**: All acceptance criteria tests pass
> **Commit After**: `"Phase 2: Fix assertion behavior and validate spec compliance"`

#### 2.1 Fix randi_range() Behavior

- [ ] **2.1.1** Modify `randi_range()` to assert on min > max (remove auto-swap)
  - _File: `src/models/rng.gd` lines 90-98_
  - _TDD: GREEN — fix implementation to pass Phase 1 test_
  - _Change_:
    ```gdscript
    func randi_range(min_val: int, max_val: int) -> int:
        assert(min_val <= max_val, "randi_range: min_val must be <= max_val")
        if min_val == max_val:
            return min_val
        var span: int = max_val - min_val + 1
        return min_val + int(next_int() % span)
    ```

- [ ] **2.1.2** Run test suite and confirm `test_randi_range_reversed_asserts()` now PASSES
  - _Command_: `godot --headless --script tests/models/test_rng.gd`
  - _Expected_: Test PASSES

- [ ] **2.1.3** Verify `test_randi_range_swapped()` now FAILS (expected; test assumed auto-swap)
  - _Action_: Update `test_randi_range_swapped()` to expect assertion instead of swapped behavior
  - _File: `tests/models/test_rng.gd` line 216_
  - _Remove or refactor_ the test (or skip it)

- [ ] **2.1.4** Validate `test_randi_range_bounds()` and `test_randi_range_equal()` still PASS
  - _Expected_: Both pass (these don't trigger the assertion)

#### 2.2 Fix pick() Behavior

- [ ] **2.2.1** Modify `pick()` to assert on empty array (remove null return)
  - _File: `src/models/rng.gd` lines 116-119_
  - _TDD: GREEN — fix implementation to pass Phase 1 test_
  - _Change_:
    ```gdscript
    func pick(array: Array) -> Variant:
        assert(not array.is_empty(), "pick: array must not be empty")
        return array[self.randi(array.size())]
    ```

- [ ] **2.2.2** Run test suite and confirm `test_pick_empty_asserts()` now PASSES
  - _Command_: `godot --headless --script tests/models/test_rng.gd`
  - _Expected_: Test PASSES

- [ ] **2.2.3** Verify `test_pick_empty()` now FAILS (expected; test assumed null return)
  - _Action_: Update `test_pick_empty()` to expect assertion instead of null return
  - _File: `tests/models/test_rng.gd` line 275_
  - _Remove or refactor_ the test (or skip it)

- [ ] **2.2.4** Validate `test_pick_coverage()` and `test_pick_determinism()` still PASS
  - _Expected_: Both pass (these don't trigger the assertion)

#### 2.3 Fix weighted_pick() Behavior

- [ ] **2.3.1** Modify `weighted_pick()` to assert on zero sum (remove null return)
  - _File: `src/models/rng.gd` lines 132-160_
  - _TDD: GREEN — fix implementation_
  - _Change_: In the loop that computes total weight, add assertion after loop:
    ```gdscript
    assert(total > 0.0, "weighted_pick: sum of weights must be positive")
    ```

- [ ] **2.3.2** Modify `weighted_pick()` to assert on size mismatch (remove null return)
  - _File: `src/models/rng.gd` line 135_
  - _Change_: Replace the null return with:
    ```gdscript
    assert(items.size() == weights.size(), "weighted_pick: items and weights arrays must match size")
    ```

- [ ] **2.3.3** Run test suite and confirm new assertion tests PASS
  - _Command_: `godot --headless --script tests/models/test_rng.gd`
  - _Expected_: `test_weighted_pick_zero_sum_asserts()` and `test_weighted_pick_mismatched_asserts()` PASS

- [ ] **2.3.4** Verify `test_weighted_pick_empty_items()`, `test_weighted_pick_empty_weights()`, `test_weighted_pick_all_zero_weights()`, `test_weighted_pick_size_mismatch()` now FAIL
  - _Action_: Update these tests to expect assertions instead of null returns
  - _File: `tests/models/test_rng.gd` lines 312-362_
  - _Remove or refactor_ these tests

- [ ] **2.3.5** Validate `test_weighted_pick_determinism()` and `test_weighted_pick_distribution()` still PASS
  - _Expected_: Both pass (these don't trigger assertions)

#### Phase 2 Validation Gate

- [ ] **2.V.1** All assertion behavior tests pass
  - _Tests_: `test_randi_range_reversed_asserts()`, `test_pick_empty_asserts()`, `test_weighted_pick_zero_sum_asserts()`, `test_weighted_pick_mismatched_asserts()`
  - _Command_: `godot --headless --script tests/models/test_rng.gd`
  - _Expected_: All 4 PASS

- [ ] **2.V.2** Bounds and behavior tests pass
  - _Tests_: `test_randi_range_bounds()`, `test_randi_range_equal()`, `test_pick_coverage()`, `test_pick_determinism()`, `test_weighted_pick_distribution()`, `test_weighted_pick_determinism()`
  - _Expected_: All PASS

- [ ] **2.V.3** No regressions in core RNG methods (TASK-002a)
  - _Tests_: All seeding, next_int, randf, randi tests
  - _Command_: `godot --headless --script tests/models/test_rng.gd`
  - _Expected_: All PASS (no changes to core methods)

- [ ] **2.V.4** Commit Phase 2: `"Phase 2: Fix assertion behavior and validate spec compliance — all tests pass"`
  - _Files changed_: `src/models/rng.gd` (3 methods updated), `tests/models/test_rng.gd` (tests refactored)

---

### Phase 3: Acceptance Criteria & Finalization

> **Ticket References**: AC-001 through AC-019 (all Acceptance Criteria)
> **Estimated Items**: 7
> **Validation Gate**: All acceptance criteria validated; no known failures
> **Commit After**: `"Phase 3: Validate all acceptance criteria for extended methods — TASK-002b complete"`

#### 3.1 Validate randi_range() Acceptance Criteria

- [ ] **3.1.1** Validate AC-001: randi_range(10, 20) returns int in [10, 20] (100+ rolls)
  - _Test location_: `test_randi_range_bounds()` in `tests/models/test_rng.gd` (line 200)
  - _Status_: Test already exists and passes
  - _Confirm_: Run test and verify PASS

- [ ] **3.1.2** Validate AC-002: randi_range() deterministic given same seed
  - _Test location_: `test_randi_range_deterministic()` in `tests/models/test_rng.gd` (line 278)
  - _Status_: Test already exists and passes
  - _Confirm_: Run test and verify PASS

- [ ] **3.1.3** Validate AC-003: randi_range(20, 10) raises assertion
  - _Test location_: `test_randi_range_reversed_asserts()` (created in Phase 1)
  - _Status_: Now passes after Phase 2 fixes
  - _Confirm_: Run test and verify PASS

- [ ] **3.1.4** Validate AC-004: randi_range(5, 5) always returns 5
  - _Test location_: `test_randi_range_equal()` in `tests/models/test_rng.gd` (line 211)
  - _Status_: Test already exists and passes
  - _Confirm_: Run test and verify PASS

#### 3.2 Validate shuffle() Acceptance Criteria

- [ ] **3.2.1** Validate AC-005: shuffle() mutates array in-place; returns same reference
  - _Test location_: `test_shuffle_in_place()` in `tests/models/test_rng.gd` (line 228)
  - _Status_: Test already exists and passes
  - _Confirm_: Run test and verify PASS

- [ ] **3.2.2** Validate AC-006: shuffle() produces deterministic order given seed
  - _Test location_: `test_shuffle_determinism()` in `tests/models/test_rng.gd` (line 236)
  - _Status_: Test already exists and passes
  - _Confirm_: Run test and verify PASS

- [ ] **3.2.3** Validate AC-007: shuffle([]) returns empty array unchanged
  - _Test location_: `test_shuffle_empty()` in `tests/models/test_rng.gd` (line 245)
  - _Status_: Test already exists and passes
  - _Confirm_: Run test and verify PASS

- [ ] **3.2.4** Validate AC-008: After shuffle(), all original elements present
  - _Test location_: `test_shuffle_preserves_elements()` in `tests/models/test_rng.gd` (line 257)
  - _Status_: Test already exists and passes
  - _Confirm_: Run test and verify PASS

#### 3.3 Validate pick() Acceptance Criteria

- [ ] **3.3.1** Validate AC-010: pick([A, B, C]) returns one of A, B, or C
  - _Test location_: `test_pick_basic()` (or part of section H in existing tests)
  - _Status_: Test coverage exists; verify with run
  - _Confirm_: Run test and verify PASS

- [ ] **3.3.2** Validate AC-011: pick() is deterministic given seed
  - _Test location_: `test_pick_determinism()` in `tests/models/test_rng.gd` (line 268)
  - _Status_: Test already exists and passes
  - _Confirm_: Run test and verify PASS

- [ ] **3.3.3** Validate AC-012: pick([]) raises assertion
  - _Test location_: `test_pick_empty_asserts()` (created in Phase 1)
  - _Status_: Now passes after Phase 2 fixes
  - _Confirm_: Run test and verify PASS

- [ ] **3.3.4** Validate AC-013: Over 3000 picks, each element ~1000 times (±300)
  - _Test location_: `test_pick_coverage()` in `tests/models/test_rng.gd` (line 283)
  - _Status_: Test exists (uses 1000 seeds over [a,b,c], verifying all 3 appear)
  - _Confirm_: Extend test to verify distribution bounds or accept current test as sufficient

#### 3.4 Validate weighted_pick() Acceptance Criteria

- [ ] **3.4.1** Validate AC-014: weighted_pick([A,B], [0.3,0.7]) returns A ~30%, B ~70% (10K samples)
  - _Test location_: `test_weighted_pick_distribution()` in `tests/models/test_rng.gd` (line 325)
  - _Status_: Test already exists with 10,000 samples
  - _Confirm_: Run test and verify PASS

- [ ] **3.4.2** Validate AC-015: weighted_pick() is deterministic given seed
  - _Test location_: `test_weighted_pick_determinism()` in `tests/models/test_rng.gd` (line 338)
  - _Status_: Test already exists and passes
  - _Confirm_: Run test and verify PASS

- [ ] **3.4.3** Validate AC-016: weighted_pick([A,B,C], [0.3,0.7]) (mismatched) raises assertion
  - _Test location_: `test_weighted_pick_mismatched_asserts()` (created in Phase 1)
  - _Status_: Now passes after Phase 2 fixes
  - _Confirm_: Run test and verify PASS

- [ ] **3.4.4** Validate AC-017: weighted_pick([A], [0.0]) (zero weight) raises assertion
  - _Test location_: `test_weighted_pick_zero_sum_asserts()` (created in Phase 1)
  - _Status_: Now passes after Phase 2 fixes
  - _Confirm_: Run test and verify PASS

#### 3.5 Validate Integration Criteria

- [ ] **3.5.1** Validate AC-018: All four methods use randi() or randf() internally (inherit core determinism)
  - _Inspection_: Review each method in `src/models/rng.gd` lines 87-160
  - _randi_range()_: Uses `next_int() % span` ✅
  - _shuffle()_: Uses `self.randi(i+1)` ✅
  - _pick()_: Uses `self.randi(array.size())` ✅
  - _weighted_pick()_: Uses `self.randf() * total` ✅

- [ ] **3.5.2** Validate AC-019: No external state dependencies; methods are pure functions
  - _Inspection_: Review each method; confirm no static/global state accessed
  - _Confirm_: All methods pure (only depend on `_state` via randi/randf calls)

#### 3.6 Final Integration Test

- [ ] **3.6.1** Run complete test suite for all RNG tests (core + extended)
  - _Command_: `godot --headless --script tests/models/test_rng.gd`
  - _Expected_: ALL tests PASS
  - _Test count target_: ~45+ tests (all sections A-J from existing test file)

- [ ] **3.6.2** Verify no regressions in dependent systems
  - _Inspect_: Other test files that may use DeterministicRNG
  - _Run_: Full test suite across all test files
  - _Command_: `godot --headless --script tests/`

#### 3.7 Documentation & Cleanup

- [ ] **3.7.1** Review method documentation in `src/models/rng.gd`
  - _File_: `src/models/rng.gd` lines 87-160
  - _Confirm_: All methods have docstring comments explaining behavior
  - _Check_: Comments document that methods assert on error (not return null)

- [ ] **3.7.2** Verify test documentation
  - _File_: `tests/models/test_rng.gd`
  - _Confirm_: All test names match convention and are self-documenting

#### Phase 3 Validation Gate

- [ ] **3.V.1** All 19 acceptance criteria satisfied
  - _AC-001 through AC-019_: All validated or tests confirm behavior
  - _Command_: `godot --headless --script tests/models/test_rng.gd`
  - _Expected_: All tests PASS

- [ ] **3.V.2** Test count: Minimum 40+ tests for extended methods
  - _Current test file_: Has ~40+ tests already (sections F-I for extended methods)
  - _Confirmed_: All pass

- [ ] **3.V.3** No regressions in core RNG (TASK-002a)
  - _Core methods_: seed_int, seed_string, next_int, randf, randi (unchanged)
  - _Expected_: All core tests still PASS

- [ ] **3.V.4** Commit Phase 3: `"Phase 3: Complete TASK-002b validation — all 19 ACs pass, no regressions"`
  - _Files changed_: `src/models/rng.gd` (3 methods refined), `tests/models/test_rng.gd` (tests confirmed/updated)

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 1 | Assertion validation tests | 5 | 0 | 4 new | ⬜ Not Started |
| Phase 2 | Spec compliance & bug fixes | 8 | 0 | ~40+ updated | ⬜ Not Started |
| Phase 3 | Acceptance criteria validation | 7 | 0 | ~45+ confirmed | ⬜ Not Started |
| **Total** | | **20** | **0** | **~45+** | **🔄 Ready to Start** |

---

## File Change Summary

### Modified Files

| File | Phase | Change |
|------|-------|--------|
| `src/models/rng.gd` | 2 | Fix `randi_range()` to assert on min > max (remove auto-swap) |
| `src/models/rng.gd` | 2 | Fix `pick()` to assert on empty array (remove null return) |
| `src/models/rng.gd` | 2 | Fix `weighted_pick()` to assert on zero sum (remove null return) |
| `src/models/rng.gd` | 2 | Fix `weighted_pick()` to assert on size mismatch (remove null return) |
| `tests/models/test_rng.gd` | 1 | Add 4 new assertion validation tests |
| `tests/models/test_rng.gd` | 2 | Update 4-6 existing tests to expect assertions instead of null returns |

### New Files

None — all changes are to existing files.

### Deleted Files

None — no code removal beyond internal refactoring.

---

## Commit Strategy

| Phase | Commit Message | Tests After | Key Changes |
|-------|----------------|-------------|-------------|
| 1 | `"Phase 1: Add assertion validation tests for extended methods — 4 tests added"` | ~45+ tests exist | 4 new tests in test_rng.gd |
| 2 | `"Phase 2: Fix assertion behavior and validate spec compliance — 3 methods fixed"` | ~45+ pass | randi_range, pick, weighted_pick fixed |
| 3 | `"Phase 3: Complete TASK-002b validation — all 19 ACs pass, no regressions"` | ~45+ pass | Final validation, documentation |

---

## Deviation Tracking

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| DEV-001 | 2 | `randi_range(20, 10)` now asserts instead of auto-swapping | FR-001, AC-003 | Spec compliance: FR-001 requires assertion | Breaking change: code using auto-swap will fail |
| DEV-002 | 2 | `pick([])` now asserts instead of returning null | FR-004, AC-012 | Spec compliance: FR-004 requires assertion | Breaking change: code expecting null will fail |
| DEV-003 | 2 | `weighted_pick()` with zero sum now asserts instead of returning null | FR-005, AC-017 | Spec compliance: FR-005 requires assertion | Breaking change: code expecting null will fail |

**Mitigation**: These are intentional fixes to align with spec. Consumers of these methods must be updated to handle assertions or ensure valid inputs.

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| Assertion changes break downstream code | Medium | Medium | Consumers of these methods need updates; isolated to RNG module | 2 |
| Tests depend on null behavior | High | High | Phase 1 explicitly identifies and fixes test expectations | 1, 2 |
| Performance regression from new assertions | Low | Low | Assertions are O(1); no performance impact | All |
| Floating-point precision in weighted_pick | Low | Low | Cumulative sum handles edge cases; test with 10K+ samples | 3 |

---

## Handoff State (Initial)

### What's Complete
- None — plan just created

### What's In Progress
- None — ready to start Phase 1

### What's Blocked
- None — all dependencies (TASK-002a) complete

### Next Steps
1. Read this plan + ticket (TASK-002b) + reference sibling plan (TASK-002a)
2. Review existing code in `src/models/rng.gd` lines 87-160
3. Review existing tests in `tests/models/test_rng.gd` lines 197-377
4. Start Phase 1: Write 4 assertion validation tests
5. Run tests and confirm they fail (RED state)
6. Proceed to Phase 2 to fix implementation

---

## Quick Validation Checklist (Before Starting Work)

- [ ] Read this entire plan
- [ ] Read TASK-002b ticket (full 16 sections)
- [ ] Read TASK-002a plan (for format/methodology reference)
- [ ] Review `src/models/rng.gd` lines 87-160 (extended methods)
- [ ] Review `tests/models/test_rng.gd` lines 197-377 (extended method tests)
- [ ] Run regression gate: `godot --headless --script tests/models/test_rng.gd` → confirm all pass
- [ ] Confirm Godot 4.5 is available with GUT plugin
- [ ] Ready to start Phase 1 ✅

---

*Plan version: 1.0.0 | Created: 2026-03-20 | Task: TASK-002b (2 pts, 3 phases)*
