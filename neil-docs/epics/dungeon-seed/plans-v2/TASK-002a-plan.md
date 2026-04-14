# TASK-002a: Deterministic RNG — Core Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-002a-rng-core.md`
> **Status**: Planning (Ready for Execution)
> **Created**: 2026-03-20
> **Branch**: `users/{alias}/task-002a-rng-core`
> **Repo**: `dev-agent-tool` (Godot 4.5)
> **Methodology**: TDD Red-Green-Refactor (GUT test-driven)
> **Complexity**: 2 pts (Trivial)
> **Estimated Phases**: 3
> **Work Type**: Code Validation & Fix (existing code)

---

## ⚠️ Important: This is a VALIDATION + FIX task, not greenfield

The `DeterministicRNG` class **already exists** in `src/models/rng.gd` with all 9 methods implemented and a test suite in `tests/models/test_rng.gd`. 

**Your job is NOT to write from scratch.** Your job is to:
1. **Validate** the existing implementation against TASK-002a spec
2. **Fix** any deviations or bugs discovered
3. **Confirm** all tests pass and acceptance criteria are met

This plan guides you through validation systematically using TDD principles.

---

## Quick Start for a New Agent / Developer

### Reading Order

1. **This file** (you're reading it) — the validation checklist
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-002a-rng-core.md`** — full technical spec (sections 1-16)
3. **`src/models/rng.gd`** — the existing implementation to validate
4. **`tests/models/test_rng.gd`** — the existing test suite
5. **GDD v3** (referenced in ticket) for domain context

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| **RNG Class** | `src/models/rng.gd` | Implementation to validate; extends RefCounted |
| **RNG Tests** | `tests/models/test_rng.gd` | Existing test suite (GUT framework) |
| **Godot Project** | `project.godot` | Godot 4.5; GUT plugin pre-installed |
| **Build/Test** | `scripts/` or CI config | See build commands below |

### Build & Test Commands

```powershell
# Run all RNG tests
godot --headless --script tests/models/test_rng.gd

# Or use Godot directly
godot -d res://tests/models/test_rng.gd

# Run just the TASK-002a validation tests
# (If a separate test file is created; see Phase 2)
godot --headless -s res://tests/models/test_rng_core.gd

# Run full test suite to check regressions
godot --headless --script tests/

# Check build (compile GDScript)
godot --export-debug "Custom Build"  # or similar
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

- **xorshift64\***: Pseudorandom number generator using XOR and bit rotation shifts. Period ~2^64. Fast, deterministic.
- **63-bit Positive**: Godot `int` is signed 64-bit; masked to `0x7FFFFFFFFFFFFFFF` to ensure non-negative.
- **Determinism**: Same seed → same sequence forever. Critical for dungeon reproducibility.
- **RefCounted**: Godot memory model (reference-counted, no parent node). Freed when references drop.
- **SHA-256 Seeding**: String seeds are hashed to consistent int seeds via SHA-256.
- **Rejection Sampling**: `randi()` uses bounded-range technique to avoid modulo bias.
- **GUT Framework**: Godot Unit Test framework. Tests extend `GutTest`; use `assert_*` macros.

---

## Current State Analysis

### What Exists Today

The implementation is **substantially complete**:
- ✅ `DeterministicRNG` class defined in `src/models/rng.gd` with all 9 methods
- ✅ Constants `MASK_63`, `MULTIPLIER` defined
- ✅ Private `_state: int` member
- ✅ 5 core methods: `seed_int()`, `seed_string()`, `next_int()`, `randf()`, `randi()`
- ✅ 4 extended methods: `randi_range()`, `shuffle()`, `pick()`, `weighted_pick()`
- ✅ Existing test suite `tests/models/test_rng.gd` with comprehensive coverage

### What's Missing or Needs Validation

1. **Test coverage against TASK-002a spec**: The existing tests cover all methods, but we need to verify they match the TASK-002a acceptance criteria exactly.
2. **Known test vectors**: AC-003 and AC-004 specify hardcoded test vectors (`seed_int(42)` → [620241905386665794, 1566258436636488355, ...]). We need to validate these.
3. **Signature validation**: Confirm method signatures match spec (type hints, return types).
4. **Error handling**: `randi(max_val <= 0)` should raise an assertion error (spec §16 line 540).
5. **randf() bounds**: Spec says return [0.0, 1.0); verify no value == 1.0.
6. **randi_range() and beyond**: These are TASK-002b scope (not TASK-002a), but if they exist, document.

### Regression Boundaries (NEVER break)

- Existing test suite must continue to pass
- All 9 methods must remain accessible via their current names
- Determinism contracts must hold (same seed → same sequence)
- Public API (method names, types) must remain stable

---

## Development Methodology: TDD Red-Green-Refactor

**ALL implementation work follows strict TDD.** No exceptions. For this task, since code exists, the TDD cycle is:
1. **RED**: Write/enable a test that validates against the spec
2. **GREEN**: Fix the implementation if the test fails
3. **REFACTOR**: Optimize, but keep the test passing

### The Cycle (Validation Variant)

1. **RED**: Write a **validation test** for a specific spec requirement
   - Test may already exist in `test_rng.gd` but be incomplete/disabled
   - Or write a new test if the spec requirement is not covered
   - Run the test suite — confirm test FAILS if the spec is violated

2. **GREEN**: If test fails, **fix the implementation**
   - Modify `src/models/rng.gd` to satisfy the test
   - Run the test suite — confirm test PASSES and no regressions

3. **REFACTOR**: Only if no failures
   - Clean up, optimize, improve documentation
   - Run the test suite after every refactor step

### Test Naming Convention

`test_{subject}_{scenario}_{expected_outcome}`:

```gdscript
# Seeding:
func test_seed_int_determinism() -> void:  # Same int seed produces same sequence
func test_seed_int_zero_guard() -> void:   # Zero seed coerced to 1
func test_seed_string_unicode() -> void:   # Unicode strings handled

# Generation:
func test_next_int_non_negative() -> void: # Output always >= 0
func test_randf_bounds() -> void:          # [0.0, 1.0) guarantee
func test_randi_invalid_max() -> void:     # max_val <= 0 raises error

# Cross-method:
func test_full_sequence_determinism() -> void:  # Mixed method calls stay deterministic
```

### Test Structure (Arrange-Act-Assert)

```gdscript
func test_seed_int_known_vector() -> void:
	# Arrange — create RNG, prepare expected values
	var rng = DeterministicRNG.new()
	var expected: Array[int] = [
		620241905386665794,
		1566258436636488355,
		# ... (from spec AC-003)
	]
	
	# Act — seed and generate
	rng.seed_int(42)
	
	# Assert — verify each output matches spec
	for i in range(expected.size()):
		var actual = rng.next_int()
		assert_eq(actual, expected[i],
			"seed_int(42) next_int()[%d]: expected %d, got %d" % [i, expected[i], actual])
```

### Enterprise Coverage Standards

**Minimum test coverage for TASK-002a core methods:**

| Method | Happy Path | Edge Cases | Error Cases | Cross-Calls |
|--------|-----------|-----------|-----------|------------|
| `seed_int()` | Determinism ✅ | Zero guard ✅ | Large int ✅ | Reseed ✅ |
| `seed_string()` | Determinism ✅ | Empty str ✅ | Unicode ✅ | Case-sensitive ✅ |
| `next_int()` | Non-negative ✅ | Period (no repeats) ✅ | — | — |
| `randf()` | Bounds [0, 1) ✅ | Distribution ✅ | Never 1.0 ✅ | Determinism ✅ |
| `randi()` | Bounds [0, max) ✅ | Uniform dist ✅ | max <= 0 error ✅ | Determinism ✅ |

---

## Phase Dependency Graph

```
Phase 1 (Spec Validation)
       ↓
Phase 2 (Known Vector Tests)
       ↓
Phase 3 (Acceptance Criteria & Finalization)
```

All phases are sequential. Each phase must pass its validation gate before proceeding.

---

## Phased Implementation Checklist

### Phase 1: Spec Alignment & Method Signature Validation

> **Ticket References**: FR-001 through FR-006 (all Functional Requirements)
> **Estimated Items**: 8
> **Validation Gate**: All method signatures match spec; no compile errors
> **Commit After**: `"Phase 1: Validate RNG class structure and method signatures"`

#### 1.1 Verify Class Structure

- [ ] **1.1.1** Class `DeterministicRNG` exists in `src/models/rng.gd`
  - _Ticket ref: FR-001, AC-001_
  - _TDD: No test needed (structural); inspect source_
  - _Validation: `grep -n "class_name DeterministicRNG" src/models/rng.gd`_

- [ ] **1.1.2** Class extends `RefCounted` (not Node)
  - _Ticket ref: FR-001, AC-002_
  - _TDD: RED test `test_extends_ref_counted()` confirms type_
  - _Test location: `tests/models/test_rng.gd` (line ~29)_
  - _Status: Test already exists; run and confirm PASS_

- [ ] **1.1.3** Member `_state: int` is private (underscore prefix)
  - _Ticket ref: FR-001, AC-003_
  - _TDD: RED test checks no public `state` property; only `_state` via seeding methods_
  - _Test location: Write `test_state_is_private()` in Phase 1_

- [ ] **1.1.4** Constants defined correctly
  - _Ticket ref: FR-006, AC-004_
  - _MASK_63 = 0x7FFFFFFFFFFFFFFF (2^63 - 1)_
  - _MULTIPLIER = 0x2545F4914F6CDD1D_
  - _TDD: RED test `test_constants_defined()` with exact value assertions_

#### 1.2 Validate Method Signatures

- [ ] **1.2.1** `seed_int(val: int) -> void` signature correct
  - _Ticket ref: FR-001, AC-005_
  - _TDD: Test calls `rng.seed_int(42)` without error; return is void_
  - _File: `src/models/rng.gd` lines ~30-34_
  - _Status: Inspect source; run quick test_

- [ ] **1.2.2** `seed_string(s: String) -> void` signature correct
  - _Ticket ref: FR-002, AC-007_
  - _TDD: Test calls `rng.seed_string("FIRE-42")` without error_
  - _File: `src/models/rng.gd` lines ~40-50_

- [ ] **1.2.3** `next_int() -> int` signature correct
  - _Ticket ref: FR-003, AC-010_
  - _TDD: Test calls `var x: int = rng.next_int()` with proper type_
  - _File: `src/models/rng.gd` lines ~58-68_

- [ ] **1.2.4** `randf() -> float` signature correct
  - _Ticket ref: FR-004, AC-012_
  - _TDD: Test calls `var f: float = rng.randf()` with proper type_
  - _File: `src/models/rng.gd` lines ~73-77_

- [ ] **1.2.5** `randi(max_val: int) -> int` signature correct
  - _Ticket ref: FR-005, AC-013_
  - _TDD: Test calls `var i: int = rng.randi(20)` with proper type_
  - _File: `src/models/rng.gd` lines ~81-85_

- [ ] **1.2.6** All methods have type hints (no untyped `var`)
  - _Ticket ref: NFR-006, AC-018_
  - _TDD: Linter check or manual inspection_
  - _Tool: `gdformat --check src/models/rng.gd`_ (if available)
  - _Or: Manual scan for `var ` without type_

- [ ] **1.2.7** No compile errors when imported
  - _Ticket ref: N/A_
  - _TDD: RED test instantiates and seeds RNG without exception_
  - _Command: `godot --headless --script tests/models/test_rng.gd`_
  - _Expected: No compilation errors in output_

#### Phase 1 Validation Gate

- [ ] **1.V.1** All class structure checks pass (1.1.1 - 1.1.4)
- [ ] **1.V.2** All method signature checks pass (1.2.1 - 1.2.6)
- [ ] **1.V.3** Existing test suite runs without NEW failures
  - _Command: `godot --headless --script tests/models/test_rng.gd`_
  - _Expected: 0 new failures compared to baseline_
- [ ] **1.V.4** Commit: `"Phase 1: Validate RNG class structure and method signatures — all checks pass"`

---

### Phase 2: Core Behavior Validation (Known Test Vectors)

> **Ticket References**: AC-003, AC-004, AC-005 through AC-015 (all ACs)
> **Estimated Items**: 12
> **Dependencies**: Phase 1 complete
> **Validation Gate**: All core behaviors validated; known vectors match spec
> **Commit After**: `"Phase 2: Validate RNG core behavior and known test vectors — {N} tests pass"`

#### 2.1 Seed Determinism & Guards

- [ ] **2.1.1** `seed_int()` determinism: same seed → identical sequences
  - _Ticket ref: AC-005, AC-016_
  - _TDD: RED test `test_seed_int_determinism()` (exists in test suite line ~44)_
  - _Action: Run test; if PASS, check off. If FAIL, fix implementation._
  - _Expected: Two RNGs seeded with same int produce identical `next_int()` sequences_

- [ ] **2.1.2** `seed_int(0)` coerces to 1 (zero guard)
  - _Ticket ref: AC-006, FR-001_
  - _TDD: RED test `test_seed_int_zero_guard()` (exists line ~58)_
  - _Action: Run test; verify state is never zero_
  - _Expected: Seeding with 0 produces non-zero outputs (guard prevents degenerate state)_

- [ ] **2.1.3** `seed_string()` determinism: same string → identical sequences
  - _Ticket ref: AC-009, AC-016_
  - _TDD: RED test `test_seed_string_determinism()` (exists line ~51)_
  - _Action: Run test_
  - _Expected: Two RNGs seeded with `seed_string("FIRE-42")` produce identical sequences_

- [ ] **2.1.4** `seed_string("")` (empty) coerces to 1
  - _Ticket ref: AC-008_
  - _TDD: RED test `test_seed_string_empty()` or write new_
  - _Action: Seed with empty string, verify output is non-zero_
  - _Expected: `rng.seed_string(""); rng.next_int() != 0`_

- [ ] **2.1.5** `seed_string()` handles Unicode
  - _Ticket ref: FR-002 ("MUST handle Unicode")_
  - _TDD: RED test with Unicode seed (e.g., `"你好"`)_
  - _Action: Seed with multi-byte character, verify output non-zero_
  - _Expected: Unicode seeds produce valid, non-zero outputs_

#### 2.2 Known Test Vectors (Spec AC-003, AC-004)

These are hardcoded golden values from the ticket. **Critical for reproducibility.**

- [ ] **2.2.1** `seed_int(42)` produces known vector
  - _Ticket ref: AC-003, FR-003_
  - _TDD: RED test `test_seed_int_known_vector()` (exists line ~103)_
  - _Expected vector (first 10 values):_
    ```
    620241905386665794,
    1566258436636488355,
    3550780404650452178,
    8464459097379017928,
    1710211875670464698,
    7943305522655851255,
    2522163688295927527,
    5361532952505838762,
    972328815649197360,
    6306284809447681201,
    ```
  - _Action: Run test; if FAIL, compare actual vs expected and debug algorithm_
  - _If FAIL: Check constants (MULTIPLIER, shifts), state advancement, masking_

- [ ] **2.2.2** `seed_string("FIRE-42")` produces known vector
  - _Ticket ref: AC-004_
  - _TDD: RED test `test_seed_string_known_vector()` (exists line ~122)_
  - _Expected vector (first 10 values):_
    ```
    7239256415472327821,
    2212067844919420961,
    4835060072245509658,
    6819840240286055128,
    4984536746944521921,
    6484876506533742032,
    2731468740175570616,
    7491040561996635424,
    9079271182136377363,
    5725102609458634546,
    ```
  - _Action: Run test; if FAIL, debug SHA-256 hashing or seed_int integration_
  - _If FAIL: Verify SHA-256 bytes extracted correctly (first 8 bytes as big-endian int64)_

#### 2.3 `next_int()` Behavior

- [ ] **2.3.1** `next_int()` always returns non-negative (0 ≤ x ≤ 2^63 - 1)
  - _Ticket ref: AC-010, FR-003, NFR-005_
  - _TDD: RED test `test_next_int_non_negative()` (exists line ~145)_
  - _Action: Run 100,000 calls, verify all >= 0 and <= MASK_63_
  - _Expected: All values in valid range, PASS test_

- [ ] **2.3.2** `next_int()` sequence advances (no immediate repeats)
  - _Ticket ref: AC-011_
  - _TDD: RED test `test_next_int_sequence_advances()` or similar_
  - _Action: Seed, call next_int() 3+ times, verify values differ_
  - _Expected: val1 != val2, val2 != val3_

#### 2.4 `randf()` Behavior

- [ ] **2.4.1** `randf()` returns [0.0, 1.0); never exactly 0.0 or 1.0
  - _Ticket ref: AC-012, FR-004_
  - _TDD: RED test `test_randf_bounds()` (exists line ~158)_
  - _Action: Run 100,000 calls, verify 0.0 <= x < 1.0 (no value == 1.0)_
  - _Expected: All values in [0.0, 1.0), PASS_
  - _If FAIL: Check randf() implementation — should divide by 2^53, not 2^63_

- [ ] **2.4.2** `randf()` is deterministic
  - _Ticket ref: AC-016_
  - _TDD: RED test `test_randf_determinism()` (exists line ~167)_
  - _Action: Seed two RNGs identically, generate 1000 randf() values, compare_
  - _Expected: All pairs match (within floating-point epsilon)_

#### 2.5 `randi()` Behavior

- [ ] **2.5.1** `randi(20)` returns [0, 20); deterministic
  - _Ticket ref: AC-013, AC-014_
  - _TDD: RED test `test_randi_bounds()` (exists line ~177)_
  - _Action: Run 10,000 calls, verify all in [0, 20)_
  - _Expected: All values 0-19, all values appear at least once, PASS_

- [ ] **2.5.2** `randi(1)` always returns 0
  - _Ticket ref: AC-014_
  - _TDD: RED test `test_randi_edge_case_one()` (exists or write new)_
  - _Action: Call `randi(1)` 100 times, verify all return 0_
  - _Expected: `randi(1) == 0` always, PASS_

- [ ] **2.5.3** `randi(max_val <= 0)` raises assertion error
  - _Ticket ref: AC-015, FR-005, AC-027 (error handling)_
  - _TDD: RED test that verifies error is raised_
  - _Action: Call `randi(0)` and `randi(-5)`, expect assertion failures_
  - _Expected: Both calls raise `AssertionError`, not silent fail_
  - _If FAIL: Add `assert(max_val > 0)` to randi() implementation_

#### Phase 2 Validation Gate

- [ ] **2.V.1** All seed determinism tests PASS (2.1.1 - 2.1.5)
- [ ] **2.V.2** Both known vector tests PASS exactly (2.2.1, 2.2.2)
  - _If either FAILS, debug algorithm constants and implementation_
- [ ] **2.V.3** All next_int(), randf(), randi() behavior tests PASS (2.3 - 2.5)
- [ ] **2.V.4** Existing test suite still passes (no regressions)
- [ ] **2.V.5** Commit: `"Phase 2: Validate RNG core behavior and known test vectors — {N} tests pass"`

---

### Phase 3: Acceptance Criteria & Extended Methods (Scope Validation)

> **Ticket References**: AC-001 through AC-019, NFR-001 through NFR-007
> **Estimated Items**: 10
> **Dependencies**: Phase 2 complete
> **Validation Gate**: All AC pass; extended methods documented for TASK-002b
> **Commit After**: `"Phase 3: Final AC validation and scope boundary documentation — TASK-002a complete"`

#### 3.1 Full Acceptance Criteria Validation

- [ ] **3.1.1** AC-001: Class exists with class_name PASS
  - _Status: Confirmed in Phase 1_

- [ ] **3.1.2** AC-002: Extends RefCounted PASS
  - _Status: Confirmed in Phase 1_

- [ ] **3.1.3** AC-003: `_state` is private PASS
  - _Status: Confirmed in Phase 1_

- [ ] **3.1.4** AC-004: Constants defined PASS
  - _Status: Confirmed in Phase 1_

- [ ] **3.1.5** AC-005 through AC-009: Seeding behavior PASS
  - _Status: Confirmed in Phase 2_

- [ ] **3.1.6** AC-010 through AC-015: Generation behavior PASS
  - _Status: Confirmed in Phase 2_

- [ ] **3.1.7** AC-016: Cross-platform determinism PASS
  - _TDD: Verify with known vectors (done in Phase 2)_
  - _Note: Requires testing on multiple platforms (Windows, Linux, macOS) for full validation, but algorithm is deterministic by definition_

- [ ] **3.1.8** AC-017: No state corruption over 1M calls
  - _Ticket ref: AC-017, NFR-001 (performance)_
  - _TDD: RED test `test_next_int_throughput()` (exists line ~368)_
  - _Action: Run 1M calls to next_int(), measure time_
  - _Expected: Completes in < 2 seconds, no corrupted output_

- [ ] **3.1.9** AC-018: All methods have type hints
  - _Status: Confirmed in Phase 1 (1.2.6)_

- [ ] **3.1.10** AC-019: No implicit type coercions
  - _TDD: Manual code review; scan for `var x = ...` without type_
  - _Action: Grep for untyped `var` declarations in rng.gd_
  - _Command: `grep -n "^\s*var " src/models/rng.gd | grep -v ":"_`

#### 3.2 Extended Methods Scope Boundary

The implementation includes 4 methods **beyond** TASK-002a spec:
- `randi_range(min_val, max_val)` — inclusive range [min, max]
- `shuffle(array)` — Fisher-Yates shuffle
- `pick(array)` — uniform random element
- `weighted_pick(items, weights)` — weighted selection

**These are TASK-002b scope; document for reference.**

- [ ] **3.2.1** Document extended methods as TASK-002b scope
  - _TDD: N/A (documentation)_
  - _Action: Add comment block at top of class or in markdown_
  - _Comment: e.g., "// Extended methods (randi_range, shuffle, pick, weighted_pick) tested in TASK-002b"_

- [ ] **3.2.2** Verify extended methods do NOT interfere with TASK-002a core
  - _TDD: Run full test suite; confirm no failures introduced by these methods_
  - _Action: `godot --headless --script tests/models/test_rng.gd`_
  - _Expected: All tests PASS, no errors_

- [ ] **3.2.3** Confirm extended methods use only TASK-002a core (next_int, randf, randi)
  - _TDD: Code review_
  - _Action: Grep `randi_range`, `shuffle`, `pick`, `weighted_pick` implementations; verify they call only core methods_
  - _Expected: No circular dependencies or scope creep_

#### 3.3 Non-Functional Requirements Validation

- [ ] **3.3.1** NFR-001: Performance < 1μs per next_int() call
  - _Ticket ref: NFR-001_
  - _TDD: Test `test_next_int_throughput()` validates 1M calls in < 2s_
  - _Estimate: 1M × 1μs = 1ms ≈ well under 2s target_
  - _Status: Already validated in Phase 2_

- [ ] **3.3.2** NFR-002: Memory < 1KB per instance
  - _Ticket ref: NFR-002_
  - _TDD: Create 1000 instances, measure total RAM_
  - _Estimate: Single 64-bit int = 8 bytes << 1KB ✓_
  - _Action: Manual estimate (acceptable for trivial task)_

- [ ] **3.3.3** NFR-003: Godot 4.5+ with GDScript 2.0
  - _Ticket ref: NFR-003_
  - _Status: Confirmed by project.godot and type hints_

- [ ] **3.3.4** NFR-004: No async operations (synchronous)
  - _Ticket ref: NFR-004_
  - _Status: Obvious from implementation (no `await`, no signals)_

- [ ] **3.3.5** NFR-005: Determinism across platforms
  - _Ticket ref: NFR-005, AC-016_
  - _Status: Validated by known vector tests_

- [ ] **3.3.6** NFR-006: Type safety (type hints present)
  - _Ticket ref: NFR-006, AC-018_
  - _Status: Confirmed in Phase 1 (1.2.6)_

- [ ] **3.3.7** NFR-007: Accessibility (not applicable)
  - _Ticket ref: NFR-007_
  - _Status: N/A (infrastructure component)_

#### 3.4 Final Integration & Cleanup

- [ ] **3.4.1** All test suite tests PASS
  - _Command: `godot --headless --script tests/models/test_rng.gd`_
  - _Expected: 0 failures_

- [ ] **3.4.2** No compile warnings or errors
  - _Command: Build project or check export logs_
  - _Expected: Clean build_

- [ ] **3.4.3** Code style and documentation complete
  - _Action: Review comments, docstrings, inline explanations of xorshift64\*_
  - _Expected: Code is readable and self-documenting_

- [ ] **3.4.4** Ticket acceptance checklist complete
  - _Action: Review all 19 ACs from ticket; confirm all pass_

#### Phase 3 Validation Gate

- [ ] **3.V.1** All acceptance criteria AC-001 through AC-019 PASS
- [ ] **3.V.2** All non-functional requirements NFR-001 through NFR-007 satisfied
- [ ] **3.V.3** Extended methods documented as out-of-scope (TASK-002b)
- [ ] **3.V.4** Test suite runs cleanly with 0 failures
- [ ] **3.V.5** Commit: `"Phase 3: Final AC validation and scope boundary documentation — TASK-002a complete"`

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 1 | Spec Alignment & Signatures | 8 | 0 | 7+ | ⬜ Not Started |
| Phase 2 | Core Behavior & Known Vectors | 12 | 0 | 25+ | ⬜ Not Started |
| Phase 3 | AC Validation & Scope | 10 | 0 | 1+ | ⬜ Not Started |
| **Total** | | **30** | **0** | **33+** | **🔄 Ready** |

---

## File Change Summary

### Modified Files

| File | Phase | Changes |
|------|-------|---------|
| `src/models/rng.gd` | 2–3 | Fix any bugs discovered during validation; add comments if needed |
| `tests/models/test_rng.gd` | 1–2 | Existing tests; may add edge-case tests if gaps found |

### New Files (if needed)

| File | Phase | Purpose |
|------|-------|---------|
| `neil-docs/epics/dungeon-seed/TASK-002a-VALIDATION-REPORT.md` | 3 | Summary of validation findings and fixes |

### No Deletions

All existing code is retained; only fixes applied.

---

## Commit Strategy

| Phase | Commit Message | Tests After |
|-------|----------------|-------------|
| 1 | `"Phase 1: Validate RNG class structure and method signatures"` | 7+ passing |
| 2 | `"Phase 2: Validate RNG core behavior and known test vectors — {N} tests pass"` | 25+ passing |
| 3 | `"Phase 3: Final AC validation and scope boundary documentation — TASK-002a complete"` | 33+ passing |

---

## Deviation Tracking

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| (Empty — to be populated during execution) | | | | | |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| Known vector test fails | Low | High | Algorithm constants (MULTIPLIER, shifts) or SHA-256 extraction are incorrect. Debug by comparing actual vs. spec output byte-by-byte. | 2 |
| randf() returns 1.0 | Low | Medium | Division logic is wrong (should be 2^53, not 2^63). Fix divisor and re-test. | 2 |
| randi(max_val) has modulo bias | Low | Medium | Rejection sampling loop is missing or incorrect. Verify implementation against spec §16 lines 543-548. | 2 |
| Unicode seed hashing fails | Low | Low | SHA-256 extraction or byte ordering incorrect. Test with multi-byte characters; verify byte order is big-endian. | 2 |
| Test suite has hidden failures | Low | Low | Run full suite; report any existing failures as baseline before starting. | 1 |

---

## Handoff State (Initial)

### What's Ready to Start
- Source code exists and compiles
- Test suite exists
- Spec (ticket) is clear and detailed
- No external blockers

### What's In Progress
- Nothing yet; awaiting executor

### What's Blocked
- Nothing

### Next Steps
1. Read ticket and this plan
2. Run existing test suite to establish baseline
3. Start Phase 1: Validate class structure
4. Proceed through phases 2–3 systematically

---

## Key References

| Document | Purpose |
|----------|---------|
| `neil-docs/epics/dungeon-seed/tickets-v2/TASK-002a-rng-core.md` | **Source of Truth** for spec |
| `neil-docs/epics/dungeon-seed/GDD-v3.md` | Game design context; determinism motivation |
| `src/models/rng.gd` | Implementation to validate |
| `tests/models/test_rng.gd` | Existing test suite |
| `neil-docs/epics/dungeon-seed/tickets-v2/TASK-002b-rng-extended.md` | Extended methods (out of scope for this task) |

---

**Plan Created**: 2026-03-20  
**Executor**: (To be assigned)  
**Estimated Duration**: 2–3 hours (validation + fixes)  
**Complexity**: 2 pts (Trivial)

