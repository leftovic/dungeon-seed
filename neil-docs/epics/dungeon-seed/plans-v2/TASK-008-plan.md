# TASK-008: Economy — 4-Currency Wallet & Transaction Ledger — Implementation Plan

> **Ticket**: `neil-docs/epics/dungeon-seed/tickets-v2/TASK-008-economy-wallet.md`
> **GDD**: `neil-docs/epics/dungeon-seed/GDD-v2.md`
> **Status**: Planning
> **Created**: 2025-07-27
> **Repo**: `dev-agent-tool` (local — `C:\Users\wrstl\source\dev-agent-tool`)
> **Methodology**: TDD Red-Green-Refactor (mandatory for all phases)
> **Complexity**: 5 points (Moderate) — Fibonacci
> **Estimated Phases**: 6 (Phase 0–5)
> **Estimated Checkboxes**: ~75

---

## Quick Start for a New Agent / Developer

If you are a fresh agent picking this up with zero context, read these documents in this order:

1. **This file** (you're reading it) — the phased checklist of what to do, with status
2. **`neil-docs/epics/dungeon-seed/tickets-v2/TASK-008-economy-wallet.md`** — the full technical spec with exact code to implement
3. **`neil-docs/epics/dungeon-seed/GDD-v2.md`** — the Game Design Document for understanding domain context
4. **`src/models/enums.gd`** — the existing Enums class providing `Enums.Currency`
5. **`src/models/game_config.gd`** — the existing GameConfig with `CURRENCY_EARN_RATES`

### Repository Layout

| What | Where | Notes |
|------|-------|-------|
| Engine config | `project.godot` | **EXISTS** — do NOT modify |
| Autoload scripts | `src/autoloads/` | **EXISTS** — `event_bus.gd`, `game_manager.gd` (EventBus, GameManager autoloads) |
| Enum definitions | `src/models/enums.gd` | **EXISTS** — provides `Enums.Currency { GOLD, ESSENCE, FRAGMENTS, ARTIFACTS }` |
| Game config | `src/models/game_config.gd` | **EXISTS** — provides `GameConfig.CURRENCY_EARN_RATES` |
| RNG model | `src/models/rng.gd` | **EXISTS** — DeterministicRNG (not touched by this task) |
| New: TransactionLog | `src/models/transaction_log.gd` | **NEW** — circular buffer for transaction history |
| New: Wallet | `src/models/wallet.gd` | **NEW** — 4-currency wallet with atomic transactions |
| TransactionLog tests | `tests/models/test_transaction_log.gd` | **NEW** — ~30 GUT tests |
| Wallet tests | `tests/models/test_wallet.gd` | **NEW** — ~50 GUT tests |
| GUT addon | `addons/gut/` | **EXISTS** — pre-installed |
| Existing tests | `tests/models/test_enums_and_config.gd`, `tests/models/test_rng.gd` | **EXISTS** — must not break |

### Key Concepts (5-minute primer)

- **Wallet**: A pure-data RefCounted object holding 4 currency balances (Gold, Essence, Fragments, Artifacts). Single source of truth for all economy state.
- **TransactionLog**: A fixed-capacity circular buffer recording the last N financial transactions. Append-only, bounded memory.
- **Enums.Currency**: `enum Currency { GOLD, ESSENCE, FRAGMENTS, ARTIFACTS }` — defined in TASK-003.
- **Atomic Transaction**: `transact()` validates ALL costs first, then applies all debits, then all credits. If any cost fails, nothing changes.
- **RefCounted**: Godot base class for garbage-collected objects. No scene tree dependency. Both Wallet and TransactionLog extend RefCounted.
- **class_name**: GDScript keyword that registers a script as a globally available type — no `preload()` needed. Both new files use `class_name`.
- **EventBus**: Existing autoload. Wallet emits `currency_changed` and `currency_gained` signals through it if available, with guarded checks.
- **GUT**: Godot Unit Test framework. Tests extend `GutTest` and use `assert_*` methods.

### Build & Verification Commands

```powershell
# Run GUT tests from command line (headless):
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/models -ginclude=test_wallet.gd,test_transaction_log.gd

# Run ALL model tests (includes existing enums/rng tests):
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/models

# Run in-editor:
#   1. Open GUT panel (bottom dock)
#   2. Click "Run All" — all tests must pass green
```

### Regression Gate

Before AND after every phase:
1. `project.godot` must be unchanged (we do NOT modify it in this task)
2. Existing tests in `tests/models/` (`test_enums_and_config.gd`, `test_rng.gd`) must still pass
3. No existing files are broken by our additions
4. All new GUT tests pass green (once written)

---

## Current State Analysis

### What Exists Today

| Item | Status | Location |
|------|--------|----------|
| `project.godot` | ✅ Exists | Root — names project "Dungeon Seed" |
| `src/autoloads/event_bus.gd` | ✅ Exists | EventBus autoload with typed signals |
| `src/autoloads/game_manager.gd` | ✅ Exists | GameManager autoload with lifecycle methods |
| `src/models/enums.gd` | ✅ Exists | `class_name Enums` — provides `Enums.Currency { GOLD=0, ESSENCE=1, FRAGMENTS=2, ARTIFACTS=3 }` |
| `src/models/game_config.gd` | ✅ Exists | `class_name GameConfig` — provides `CURRENCY_EARN_RATES` |
| `src/models/rng.gd` | ✅ Exists | `DeterministicRNG` — not relevant to this task |
| `tests/models/test_enums_and_config.gd` | ✅ Exists | GUT tests for enums and config |
| `tests/models/test_rng.gd` | ✅ Exists | GUT tests for RNG |
| `addons/gut/` | ✅ Exists | GUT test framework installed |

### What's Missing (Gap Analysis)

| Item | Status | Required By |
|------|--------|-------------|
| `src/models/transaction_log.gd` | ❌ Missing | FR-035 through FR-048 |
| `src/models/wallet.gd` | ❌ Missing | FR-001 through FR-034 |
| `tests/models/test_transaction_log.gd` | ❌ Missing | Section 14.1 |
| `tests/models/test_wallet.gd` | ❌ Missing | Section 14.2 |

### What Must NOT Change

- `project.godot` — no modifications needed for this task
- `src/autoloads/event_bus.gd` — existing autoload, DO NOT modify
- `src/autoloads/game_manager.gd` — existing autoload, DO NOT modify
- `src/models/enums.gd` — upstream dependency (TASK-003), DO NOT modify
- `src/models/game_config.gd` — upstream dependency (TASK-003), DO NOT modify
- `src/models/rng.gd` — unrelated model, DO NOT modify
- `tests/models/test_enums_and_config.gd` — existing tests must continue passing
- `tests/models/test_rng.gd` — existing tests must continue passing

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
# Single scenarios
func test_fresh_wallet_gold_is_zero() -> void:

# Specific behavior
func test_credit_gold_increases_balance() -> void:

# Error / edge cases
func test_debit_fails_when_insufficient() -> void:

# Boundary conditions
func test_circular_buffer_overwrite() -> void:
```

### Test Structure (GUT)

Every test follows Arrange-Act-Assert:
```gdscript
func test_credit_gold_increases_balance() -> void:
    # Arrange — wallet created in before_each()

    # Act — execute the behavior
    _wallet.credit(Enums.Currency.GOLD, 100)

    # Assert — verify the outcome
    assert_eq(_wallet.get_balance(Enums.Currency.GOLD), 100, "Gold should be 100 after credit")
```

### Coverage Requirements Per Phase

- ✅ **Existence**: Class exists, extends correct base, has `class_name`
- ✅ **Construction**: Default state is correct (all balances zero, log empty)
- ✅ **Method behavior**: Public methods produce correct results
- ✅ **Edge cases**: Circular buffer wrapping, zero-amount guards, empty dicts
- ✅ **Error handling**: Insufficient funds, negative amounts, invalid data
- ✅ **Atomicity**: transact() either fully applies or fully reverts
- ✅ **Serialization**: Round-trip consistency, defensive deserialization
- ✅ **Invariants**: No balance ever goes negative

---

## Phase 0: Pre-Flight & Dependency Verification

> **Ticket References**: TASK-003 dependency check
> **AC References**: AC-001, AC-040
> **Estimated Items**: 8
> **Dependencies**: TASK-003 (Enums — IMPLEMENTED)
> **Validation Gate**: Enums.Currency exists with 4 values; existing tests pass; no file collisions

### 0.1 Verify TASK-003 Dependency

- [ ] **0.1.1** Verify `src/models/enums.gd` exists and contains `enum Currency { GOLD, ESSENCE, FRAGMENTS, ARTIFACTS }`
  - _Ticket ref: Assumption #1_
  - _File: `src/models/enums.gd`_
  - _Check: `Enums.Currency.GOLD == 0`, `Enums.Currency.ESSENCE == 1`, `Enums.Currency.FRAGMENTS == 2`, `Enums.Currency.ARTIFACTS == 3`_

- [ ] **0.1.2** Verify `src/models/game_config.gd` exists and contains `CURRENCY_EARN_RATES`
  - _Ticket ref: Assumption #2_
  - _File: `src/models/game_config.gd`_

### 0.2 Verify No File Collisions

- [ ] **0.2.1** Verify `src/models/transaction_log.gd` does NOT already exist
  - _If it exists, record deviation DEV-001_

- [ ] **0.2.2** Verify `src/models/wallet.gd` does NOT already exist
  - _If it exists, record deviation DEV-002_

- [ ] **0.2.3** Verify `tests/models/test_transaction_log.gd` does NOT already exist

- [ ] **0.2.4** Verify `tests/models/test_wallet.gd` does NOT already exist

### 0.3 Run Existing Test Baseline

- [ ] **0.3.1** Run existing GUT tests in `tests/models/` — all must pass green (baseline)
  - _Command: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/models`_
  - _Expected: `test_enums_and_config.gd` and `test_rng.gd` pass with 0 failures_

### Phase 0 Validation Gate

- [ ] **0.V.1** `Enums.Currency` enum confirmed with 4 values (GOLD=0, ESSENCE=1, FRAGMENTS=2, ARTIFACTS=3)
- [ ] **0.V.2** No file collisions detected for the 4 output files
- [ ] **0.V.3** Existing model tests pass green (baseline established)

---

## Phase 1: TransactionLog Model (TDD)

> **Ticket References**: FR-035 through FR-048
> **AC References**: AC-040 through AC-053
> **Estimated Items**: 14
> **Dependencies**: Phase 0 complete (Enums.Currency available)
> **Validation Gate**: `transaction_log.gd` exists, extends RefCounted, class_name TransactionLog, ~30 tests pass green

### 1.1 Write Test File (RED)

- [ ] **1.1.1** Create `tests/models/test_transaction_log.gd` with all ~30 test functions from ticket Section 14.1
  - _Ticket ref: Section 14.1_
  - _File: `tests/models/test_transaction_log.gd`_
  - _Tests (Section A — Construction):_ `test_default_capacity_is_100`, `test_custom_capacity`, `test_initial_count_is_zero`, `test_initial_get_all_is_empty`
  - _Tests (Section B — Recording):_ `test_record_single_entry`, `test_record_entry_has_five_keys`, `test_record_entry_values_are_correct`, `test_record_multiple_entries`
  - _Tests (Section C — get_recent):_ `test_get_recent_returns_requested_count`, `test_get_recent_returns_most_recent_entries`, `test_get_recent_chronological_order`, `test_get_recent_more_than_available`, `test_get_recent_zero_count`, `test_get_recent_returns_defensive_copy`
  - _Tests (Section D — Circular Buffer):_ `test_circular_buffer_overwrite`, `test_circular_buffer_multiple_overwrites`, `test_circular_buffer_get_recent_after_wrap`
  - _Tests (Section E — get_all/get_count):_ `test_get_all_returns_all_entries_in_order`, `test_get_count_increments_correctly`, `test_get_count_caps_at_max_entries`
  - _Tests (Section F — clear):_ `test_clear_resets_count`, `test_clear_empties_get_all`, `test_record_after_clear_works`
  - _Tests (Section G — Serialization):_ `test_to_dict_has_required_keys`, `test_to_dict_max_entries_value`, `test_to_dict_entries_count`, `test_to_dict_only_populated_entries`, `test_round_trip_serialization`, `test_round_trip_after_circular_overwrite`
  - _TDD: RED — tests reference `TransactionLog` class which does not exist yet_
  - _AC refs: AC-040 through AC-053_

### 1.2 Implement TransactionLog (GREEN)

- [ ] **1.2.1** Create `src/models/transaction_log.gd` with class declaration
  - _Ticket ref: FR-035, FR-036_
  - _File: `src/models/transaction_log.gd`_
  - _Content: `class_name TransactionLog` + `extends RefCounted`_
  - _AC ref: AC-040_

- [ ] **1.2.2** Add constants and internal state variables
  - _Ticket ref: FR-037_
  - _Constants: `DEFAULT_MAX_ENTRIES: int = 100`_
  - _Variables: `_entries: Array[Dictionary]`, `_max_entries: int`, `_write_index: int`, `_count: int`_

- [ ] **1.2.3** Add `_init(max_entries: int = DEFAULT_MAX_ENTRIES)` constructor
  - _Ticket ref: FR-037_
  - _Logic: Set `_max_entries`, resize `_entries`, initialize all slots to `{}`, reset `_write_index` and `_count` to 0_
  - _AC refs: AC-041, AC-042_

- [ ] **1.2.4** Add `record(type: String, currency: Enums.Currency, amount: int, balance: int) -> void`
  - _Ticket ref: FR-038, FR-039, FR-040, FR-041_
  - _Logic: Create entry dict with 5 keys (timestamp, type, currency, amount, balance_after), write at `_write_index`, advance pointer with modulo wrap, update count capped at `_max_entries`_
  - _AC refs: AC-043, AC-047, AC-048_

- [ ] **1.2.5** Add `get_recent(count: int) -> Array[Dictionary]`
  - _Ticket ref: FR-042, FR-043_
  - _Logic: Calculate start index from write pointer, read forward with wrap, return defensive copies_
  - _AC refs: AC-044, AC-045, AC-049_

- [ ] **1.2.6** Add `get_all() -> Array[Dictionary]` and `get_count() -> int`
  - _Ticket ref: FR-044, FR-045_
  - _AC ref: AC-046_

- [ ] **1.2.7** Add `clear() -> void`
  - _Ticket ref: FR-046_
  - _Logic: Reset all slots to `{}`, reset `_write_index` and `_count` to 0_
  - _AC ref: AC-050_

- [ ] **1.2.8** Add `to_dict() -> Dictionary` and `from_dict(data: Dictionary) -> void`
  - _Ticket ref: FR-047, FR-048_
  - _`to_dict()` serializes only populated entries + max_entries_
  - _`from_dict()` validates entry structure via `_is_valid_entry()` helper_
  - _AC refs: AC-051, AC-052, AC-053_

- [ ] **1.2.9** Add `_is_valid_entry(entry: Dictionary) -> bool` private helper
  - _Logic: Check for 5 required keys, validate types (timestamp is float/int, type is String, etc.)_

> **Implementation source**: Ticket Section 16.1 has the complete `transaction_log.gd`.

### 1.3 Run Tests (GREEN confirmation)

- [ ] **1.3.1** Run `tests/models/test_transaction_log.gd` — verify all ~30 tests pass green
  - _Expected: ~30 pass, 0 fail, 0 error_

- [ ] **1.3.2** Run existing model tests — verify no regressions
  - _Expected: `test_enums_and_config.gd` and `test_rng.gd` still pass_

### Phase 1 Validation Gate

- [ ] **1.V.1** `src/models/transaction_log.gd` exists and is parseable GDScript
- [ ] **1.V.2** File declares `class_name TransactionLog` and `extends RefCounted`
- [ ] **1.V.3** All 7 public methods implemented: `record()`, `get_recent()`, `get_all()`, `get_count()`, `clear()`, `to_dict()`, `from_dict()`
- [ ] **1.V.4** Circular buffer correctly overwrites oldest entries when full
- [ ] **1.V.5** All ~30 TransactionLog tests pass green
- [ ] **1.V.6** No regressions in existing model tests
- [ ] **1.V.7** File is under 150 lines (NFR-012)
- [ ] **1.V.8** Commit: `"Phase 1: Add TransactionLog circular buffer model — ~30 tests"`

---

## Phase 2: Wallet Core — Initialization, Credit, Debit (TDD)

> **Ticket References**: FR-001 through FR-020, FR-032, FR-033, FR-034
> **AC References**: AC-001 through AC-019, AC-025
> **Estimated Items**: 14
> **Dependencies**: Phase 1 complete (TransactionLog available)
> **Validation Gate**: `wallet.gd` exists, Wallet.new() creates 4-currency wallet, credit/debit/can_afford work, ~35 tests pass green

### 2.1 Write Test File — Sections A through D (RED)

- [ ] **2.1.1** Create `tests/models/test_wallet.gd` with test functions for Sections A–D from ticket Section 14.2
  - _Ticket ref: Section 14.2_
  - _File: `tests/models/test_wallet.gd`_
  - _Tests (Section A — Initialization):_ `test_fresh_wallet_gold_is_zero`, `test_fresh_wallet_essence_is_zero`, `test_fresh_wallet_fragments_is_zero`, `test_fresh_wallet_artifacts_is_zero`, `test_get_all_balances_has_four_keys`, `test_get_all_balances_returns_copy`, `test_wallet_has_transaction_log`
  - _Tests (Section B — Credit):_ `test_credit_gold_increases_balance`, `test_credit_essence_increases_balance`, `test_credit_fragments_increases_balance`, `test_credit_artifacts_increases_balance`, `test_credit_accumulates`, `test_credit_does_not_affect_other_currencies`, `test_credit_records_transaction`, `test_credit_large_amount`
  - _Tests (Section C — Debit):_ `test_debit_succeeds_when_sufficient`, `test_debit_exact_balance`, `test_debit_fails_when_insufficient`, `test_debit_fails_on_zero_balance`, `test_debit_does_not_affect_other_currencies`, `test_debit_records_transaction_on_success`, `test_debit_does_not_record_on_failure`, `test_debit_works_for_all_currencies`
  - _Tests (Section D — can_afford):_ `test_can_afford_single_currency_true`, `test_can_afford_single_currency_exact`, `test_can_afford_single_currency_false`, `test_can_afford_multi_currency_true`, `test_can_afford_multi_currency_one_short`, `test_can_afford_empty_costs_always_true`, `test_can_afford_does_not_modify_balances`, `test_can_afford_all_four_currencies`
  - _TDD: RED — tests reference `Wallet` class which does not exist yet_
  - _AC refs: AC-001 through AC-025_

### 2.2 Implement Wallet Core (GREEN)

- [ ] **2.2.1** Create `src/models/wallet.gd` with class declaration
  - _Ticket ref: FR-001, FR-002_
  - _File: `src/models/wallet.gd`_
  - _Content: `class_name Wallet` + `extends RefCounted`_
  - _AC ref: AC-001_

- [ ] **2.2.2** Add internal state: `_balances: Dictionary` and `_log: TransactionLog`
  - _Ticket ref: FR-003, FR-004_

- [ ] **2.2.3** Add `_init()` constructor — initialize `_balances` with all 4 currencies at 0, create `TransactionLog.new()`
  - _Ticket ref: FR-003, FR-004_
  - _AC refs: AC-002, AC-003, AC-004, AC-005_

- [ ] **2.2.4** Add `get_balance(currency: Enums.Currency) -> int`
  - _Ticket ref: FR-005, FR-006_

- [ ] **2.2.5** Add `get_all_balances() -> Dictionary` — returns `_balances.duplicate()` (defensive copy)
  - _Ticket ref: FR-034_
  - _AC refs: AC-006, AC-007_

- [ ] **2.2.6** Add `get_transaction_log() -> TransactionLog`
  - _Ticket ref: FR-032_

- [ ] **2.2.7** Add `can_afford(costs: Dictionary) -> bool`
  - _Ticket ref: FR-007, FR-008, FR-009_
  - _Logic: Iterate costs, check each balance ≥ cost. Return true for empty dict._
  - _AC refs: AC-020 through AC-025_

- [ ] **2.2.8** Add `credit(currency: Enums.Currency, amount: int) -> void`
  - _Ticket ref: FR-010, FR-011, FR-012, FR-013, FR-014_
  - _Logic: Assert amount > 0, guard `if amount <= 0: return`, add to balance, log "credit", emit EventBus signals if available_
  - _AC refs: AC-008 through AC-012_

- [ ] **2.2.9** Add `debit(currency: Enums.Currency, amount: int) -> bool`
  - _Ticket ref: FR-015, FR-016, FR-017, FR-018, FR-019, FR-020_
  - _Logic: Assert amount > 0, guard `if amount <= 0: return false`, check balance >= amount, subtract, log "debit", emit signal. Return false on insufficient funds — NO state change, NO log entry._
  - _AC refs: AC-013 through AC-019_

- [ ] **2.2.10** Add `_emit_currency_changed()` and `_emit_currency_gained()` private helpers
  - _Logic: Check `Engine.has_singleton("EventBus")` before emitting. Silently skip if unavailable._
  - _Ticket ref: FR-013, FR-014, FR-020_

### 2.3 Run Tests (GREEN confirmation)

- [ ] **2.3.1** Run `tests/models/test_wallet.gd` — verify all Section A–D tests pass green
  - _Expected: ~30 pass, 0 fail, 0 error_

- [ ] **2.3.2** Run ALL model tests — verify no regressions (TransactionLog + existing tests still pass)

### Phase 2 Validation Gate

- [ ] **2.V.1** `src/models/wallet.gd` exists and is parseable GDScript
- [ ] **2.V.2** File declares `class_name Wallet` and `extends RefCounted`
- [ ] **2.V.3** `Wallet.new()` initializes all 4 currencies to 0
- [ ] **2.V.4** `credit()` increases balance, records log, guards against non-positive amounts
- [ ] **2.V.5** `debit()` returns true/false correctly, no state change on failure, no log on failure
- [ ] **2.V.6** `can_afford()` is read-only, handles empty dict, multi-currency
- [ ] **2.V.7** `get_all_balances()` returns a copy, not internal reference
- [ ] **2.V.8** All ~30 Wallet core tests pass green
- [ ] **2.V.9** No regressions in TransactionLog or existing tests
- [ ] **2.V.10** Commit: `"Phase 2: Add Wallet core — init, credit, debit, can_afford — ~30 tests"`

---

## Phase 3: Wallet Advanced — Atomic transact(), Serialization, Reset (TDD)

> **Ticket References**: FR-021 through FR-031, FR-033
> **AC References**: AC-026 through AC-039
> **Estimated Items**: 10
> **Dependencies**: Phase 2 complete (Wallet core with credit/debit/can_afford)
> **Validation Gate**: `transact()`, `to_dict()`, `from_dict()`, `reset()` work; ~20 additional tests pass green

### 3.1 Add Test Functions — Sections E through H (RED)

- [ ] **3.1.1** Append Sections E–H test functions to `tests/models/test_wallet.gd`
  - _Tests (Section E — Atomic Transactions):_ `test_transact_debit_only_succeeds`, `test_transact_debit_and_credit`, `test_transact_fails_atomically_no_partial_debit`, `test_transact_pure_grant_always_succeeds`, `test_transact_records_log_entries`, `test_transact_failed_does_not_log`, `test_transact_same_currency_in_costs_and_gains`, `test_transact_all_four_currencies`
  - _Tests (Section F — Serialization):_ `test_to_dict_has_balances_key`, `test_to_dict_has_log_key`, `test_to_dict_balances_values`, `test_round_trip_preserves_balances`, `test_from_dict_missing_currency_defaults_to_zero`, `test_from_dict_negative_balance_clamped_to_zero`, `test_from_dict_ignores_unknown_keys`, `test_from_dict_with_string_keys_from_json`
  - _Tests (Section G — Reset):_ `test_reset_zeros_all_balances`, `test_reset_clears_transaction_log`, `test_wallet_works_after_reset`
  - _Tests (Section H — Edge Cases):_ `test_balance_never_negative_after_operations`, `test_rapid_credit_debit_cycle`, `test_multiple_currencies_independent`, `test_transact_with_empty_costs_and_empty_gains`, `test_sequential_transactions`
  - _TDD: RED — new tests reference `transact()`, `to_dict()`, `from_dict()`, `reset()` which do not exist yet_
  - _AC refs: AC-026 through AC-039_

### 3.2 Implement Advanced Features (GREEN)

- [ ] **3.2.1** Add `transact(costs: Dictionary, gains: Dictionary) -> bool`
  - _Ticket ref: FR-021, FR-022, FR-023, FR-024, FR-025, FR-026_
  - _Logic: Phase 1 — validate via `can_afford(costs)`, return false if insufficient. Phase 2 — debit all costs (guaranteed safe). Phase 3 — credit all gains. Log each mutation as "transact_debit" or "transact_credit"._
  - _AC refs: AC-026 through AC-032_

- [ ] **3.2.2** Add `to_dict() -> Dictionary`
  - _Ticket ref: FR-027_
  - _Logic: Serialize `_balances` to a new dict, include `_log.to_dict()`_
  - _AC refs: AC-033, AC-034_

- [ ] **3.2.3** Add `from_dict(data: Dictionary) -> void`
  - _Ticket ref: FR-028, FR-029, FR-030_
  - _Logic: Reset balances to 0, iterate valid currencies, check for both integer keys and string keys (JSON compatibility), clamp negatives to 0, ignore unknown keys, restore log from nested dict_
  - _AC refs: AC-035, AC-036, AC-037, AC-038_

- [ ] **3.2.4** Add `reset() -> void`
  - _Ticket ref: FR-031_
  - _Logic: Set all 4 balances to 0, call `_log.clear()`_
  - _AC ref: AC-039_

### 3.3 Run Tests (GREEN confirmation)

- [ ] **3.3.1** Run `tests/models/test_wallet.gd` — verify ALL ~50 tests pass green (Sections A–H)
  - _Expected: ~50 pass, 0 fail, 0 error_

- [ ] **3.3.2** Run ALL model tests — verify no regressions

### Phase 3 Validation Gate

- [ ] **3.V.1** `transact()` is atomic: validates all costs before any mutation; failed transact leaves all balances unchanged
- [ ] **3.V.2** `transact()` handles overlapping costs and gains (same currency in both)
- [ ] **3.V.3** `to_dict()` produces JSON-compatible output with "balances" and "log" keys
- [ ] **3.V.4** `from_dict()` handles string keys from JSON, clamps negatives, ignores unknown keys
- [ ] **3.V.5** Round-trip `from_dict(wallet.to_dict())` preserves all balances
- [ ] **3.V.6** `reset()` zeros all balances and clears log
- [ ] **3.V.7** All ~50 Wallet tests pass green
- [ ] **3.V.8** No regressions in TransactionLog or existing tests
- [ ] **3.V.9** `wallet.gd` file is under 150 lines (NFR-012)
- [ ] **3.V.10** Commit: `"Phase 3: Add Wallet transact, serialization, reset — ~50 tests total"`

---

## Phase 4: Integration & Cross-Model Validation

> **Ticket References**: FR-004, FR-012, FR-019, FR-024, FR-032
> **AC References**: AC-011, AC-017, AC-031, AC-047
> **Estimated Items**: 8
> **Dependencies**: Phases 1–3 complete (both models fully implemented)
> **Validation Gate**: Wallet correctly uses TransactionLog internally; edge cases and stress tests pass

### 4.1 Cross-Model Integration Tests

- [ ] **4.1.1** Verify Wallet `credit()` creates entries in its internal TransactionLog
  - _Already covered by `test_credit_records_transaction` — re-verify in full suite context_

- [ ] **4.1.2** Verify Wallet `debit()` creates log entries only on success
  - _Already covered by `test_debit_records_transaction_on_success` and `test_debit_does_not_record_on_failure`_

- [ ] **4.1.3** Verify Wallet `transact()` records correct log entries (transact_debit, transact_credit)
  - _Already covered by `test_transact_records_log_entries` and `test_transact_failed_does_not_log`_

- [ ] **4.1.4** Verify Wallet round-trip serialization preserves TransactionLog state
  - _Test: Credit some amounts, serialize, restore to new wallet, check log entries match_

### 4.2 Edge Case / Stress Validation

- [ ] **4.2.1** Verify `test_rapid_credit_debit_cycle` — 100 cycles of +10/-5 Gold yields balance 500
  - _Already in test suite — confirm passes in combined run_

- [ ] **4.2.2** Verify `test_credit_large_amount` — 999,999,999 Gold handled correctly
  - _Already in test suite — confirm passes_

- [ ] **4.2.3** Verify `test_sequential_transactions` — multiple transact() calls in sequence produce correct cumulative state

### Phase 4 Validation Gate

- [ ] **4.V.1** All ~80 tests pass green in a single combined GUT run (both test files)
- [ ] **4.V.2** No regressions in existing model tests (`test_enums_and_config.gd`, `test_rng.gd`)
- [ ] **4.V.3** Wallet internal TransactionLog correctly records all mutations
- [ ] **4.V.4** Edge cases (rapid cycles, large amounts, empty transact) all pass
- [ ] **4.V.5** Commit: `"Phase 4: Integration validation — all ~80 TASK-008 tests pass"`

---

## Phase 5: Final Validation & Cleanup

> **Ticket References**: All FRs, ACs, NFRs, Playtesting Verification
> **AC References**: All 59 ACs verified
> **Estimated Items**: 15
> **Dependencies**: ALL prior phases complete
> **Validation Gate**: Full test suite green, code quality NFRs met, all FRs covered

### 5.1 Code Quality Verification (NFRs)

- [ ] **5.1.1** All GDScript files have static type hints on every variable, parameter, and return type (NFR-009)
- [ ] **5.1.2** All files follow GDScript style guide: snake_case variables/functions, PascalCase classes, UPPER_SNAKE constants (NFR-009)
- [ ] **5.1.3** `transaction_log.gd` is under 150 lines excluding comments/blanks (NFR-012)
- [ ] **5.1.4** `wallet.gd` is under 150 lines excluding comments/blanks (NFR-012)
- [ ] **5.1.5** All public methods have `##` doc comments
- [ ] **5.1.6** No circular dependencies: `transaction_log.gd` depends only on `Enums`; `wallet.gd` depends on `transaction_log.gd` and `Enums` (NFR-020)
- [ ] **5.1.7** Both files compile with zero GDScript parser warnings (NFR-013)
- [ ] **5.1.8** `credit()`, `debit()`, `get_balance()` are O(1); `can_afford()` is O(k); `transact()` is O(k) (NFR-001, NFR-002, NFR-003)
- [ ] **5.1.9** `TransactionLog.record()` is O(1) — no array resizing (NFR-004)
- [ ] **5.1.10** All operations are deterministic — no `randf()`, no non-deterministic system calls (NFR-015)

### 5.2 Final Test Run

- [ ] **5.2.1** Run complete GUT test suite for `tests/models/` — ALL tests pass green
  - _Expected: ~80 TASK-008 tests + existing enums/rng tests — 0 failures_

- [ ] **5.2.2** Verify total disk footprint of new files under 50 KB
  - _4 new files: `transaction_log.gd`, `wallet.gd`, `test_transaction_log.gd`, `test_wallet.gd`_

### 5.3 Cleanup

- [ ] **5.3.1** Remove any temporary debug code or commented-out experiments
- [ ] **5.3.2** Verify no `.uid` files need manual management (Godot auto-generates these)

### Phase 5 Validation Gate

- [ ] **5.V.1** All NFRs verified (type safety, performance, maintainability, compatibility)
- [ ] **5.V.2** All ~80 TASK-008 tests pass green with zero failures
- [ ] **5.V.3** All existing model tests pass green (no regressions)
- [ ] **5.V.4** Total disk footprint of new files under 50 KB
- [ ] **5.V.5** Commit: `"TASK-008 complete: Economy — 4-Currency Wallet & Transaction Ledger — ~80 tests, all green"`

---

## Phase Dependency Graph

```
Phase 0 (Pre-Flight) ──→ Phase 1 (TransactionLog TDD) ──→ Phase 2 (Wallet Core TDD)
                                                                    │
                                                                    ▼
                                                           Phase 3 (Wallet Advanced TDD)
                                                                    │
                                                                    ▼
                                                           Phase 4 (Integration Validation)
                                                                    │
                                                                    ▼
                                                           Phase 5 (Final Validation & Cleanup)
```

**Sequential dependency note**: Phase 1 must complete before Phase 2 because `wallet.gd` instantiates `TransactionLog` internally. There is no parallelism opportunity between Phases 1–3.

---

## Progress Summary

| Phase | Description | Items | Completed | Tests | Status |
|-------|-------------|-------|-----------|-------|--------|
| Phase 0 | Pre-flight & dependency verification | 8 | 0 | 0 | ⬜ Not Started |
| Phase 1 | TransactionLog model (TDD) | 14 | 0 | ~30 | ⬜ Not Started |
| Phase 2 | Wallet core — init, credit, debit, can_afford (TDD) | 14 | 0 | ~30 | ⬜ Not Started |
| Phase 3 | Wallet advanced — transact, serialization, reset (TDD) | 10 | 0 | ~20 | ⬜ Not Started |
| Phase 4 | Integration & cross-model validation | 8 | 0 | ~80 | ⬜ Not Started |
| Phase 5 | Final validation & cleanup | 15 | 0 | ~80 | ⬜ Not Started |
| **Total** | | **~69** | **0** | **~80** | **⬜ Phase 0 Next** |

---

## File Change Summary

### New Files

| File | Phase | Purpose |
|------|-------|---------|
| `src/models/transaction_log.gd` | 1 | TransactionLog circular buffer — bounded transaction history |
| `src/models/wallet.gd` | 2–3 | Wallet — 4-currency wallet with atomic transactions |
| `tests/models/test_transaction_log.gd` | 1 | ~30 GUT tests for TransactionLog |
| `tests/models/test_wallet.gd` | 2–3 | ~50 GUT tests for Wallet |

### Modified Files

None — this task is additive only. No existing files are modified.

### Deleted Files

None.

---

## Commit Strategy

| Phase | Commit Message | Tests After |
|-------|----------------|-------------|
| 0 | _(no commit — verification only)_ | 0 new (baseline confirmed) |
| 1 | `"Phase 1: Add TransactionLog circular buffer model — ~30 tests"` | ~30 ✅ |
| 2 | `"Phase 2: Add Wallet core — init, credit, debit, can_afford — ~30 tests"` | ~60 ✅ |
| 3 | `"Phase 3: Add Wallet transact, serialization, reset — ~50 tests total"` | ~80 ✅ |
| 4 | `"Phase 4: Integration validation — all ~80 TASK-008 tests pass"` | ~80 ✅ |
| 5 | `"TASK-008 complete: Economy — 4-Currency Wallet & Transaction Ledger — ~80 tests, all green"` | ~80 ✅ |

---

## Deviation Tracking

| ID | Phase | Summary | Ticket Ref | Reason | Impact |
|----|-------|---------|------------|--------|--------|
| _(none yet)_ | | | | | |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation | Phase |
|------|-----------|--------|------------|-------|
| `Enums.Currency` not available (TASK-003 not merged) | Very Low | High (blocked) | Verified in Phase 0.1.1 — TASK-003 is confirmed IMPLEMENTED | 0 |
| `class_name TransactionLog` conflicts with existing code | Very Low | High | Search codebase for existing `class_name TransactionLog` in Phase 0.2.1 | 0 |
| `class_name Wallet` conflicts with existing code | Very Low | High | Search codebase for existing `class_name Wallet` in Phase 0.2.2 | 0 |
| EventBus autoload not available during tests | Medium | Low | Wallet uses `Engine.has_singleton("EventBus")` guard — signal emission silently skipped. Tests work without EventBus. | 2 |
| GDScript `assert()` stripped in release builds | Expected | Low | Dual-layer defense: `assert(amount > 0)` + `if amount <= 0: return`. Both debug and release paths are safe. | 2 |
| JSON parsing converts integer keys to strings | Expected | Medium | `from_dict()` checks both integer keys and `str(int(currency))` string keys. Covered by `test_from_dict_with_string_keys_from_json`. | 3 |
| Circular buffer index math wrong after wrap | Medium | Medium | Extensive tests with capacity=5 and 8+ writes. Tests `test_circular_buffer_overwrite`, `test_circular_buffer_multiple_overwrites`, `test_circular_buffer_get_recent_after_wrap` cover wrapping. | 1 |
| Wallet `transact()` partial debit on failure | Low | High | `can_afford()` validates ALL costs before any mutation. Tests `test_transact_fails_atomically_no_partial_debit` and `test_transact_failed_does_not_log` verify atomicity. | 3 |

---

## Handoff State (2025-07-27)

### What's Complete
- Implementation plan written and ready for execution

### What's In Progress
- Nothing — plan is at Phase 0 (not started)

### What's Blocked
- Nothing — TASK-003 (Enums) is confirmed IMPLEMENTED; all dependencies satisfied

### Next Steps
1. Execute Phase 0: Verify TASK-003 dependency, check for file collisions, establish test baseline
2. Execute Phase 1: Write TransactionLog tests (RED), implement TransactionLog (GREEN)
3. Execute Phase 2: Write Wallet core tests (RED), implement Wallet core (GREEN)
4. Execute Phase 3: Write Wallet advanced tests (RED), implement transact/serialization/reset (GREEN)
5. Execute Phase 4: Integration validation — all ~80 tests in combined run
6. Execute Phase 5: Final validation, code quality audit, cleanup

---

## Ticket FR/AC Coverage Matrix

Every Functional Requirement and Acceptance Criterion from the ticket is mapped below.

### Functional Requirements → Phase Items

| FR | Description | Phase | Checkbox |
|----|-------------|-------|----------|
| FR-001 | `wallet.gd` declares `class_name Wallet` | 2 | 2.2.1 |
| FR-002 | `wallet.gd` declares `extends RefCounted` | 2 | 2.2.1 |
| FR-003 | `_balances` initialized with all 4 currencies at 0 | 2 | 2.2.3 |
| FR-004 | Wallet holds internal `TransactionLog` | 2 | 2.2.3 |
| FR-005 | `get_balance()` returns current balance | 2 | 2.2.4 |
| FR-006 | `get_balance()` returns 0 for uncredited currency | 2 | 2.2.4 |
| FR-007 | `can_afford()` validates all costs | 2 | 2.2.7 |
| FR-008 | `can_afford({})` returns true | 2 | 2.2.7 |
| FR-009 | `can_afford()` is read-only | 2 | 2.2.7 |
| FR-010 | `credit()` increases balance | 2 | 2.2.8 |
| FR-011 | `credit()` asserts amount > 0 | 2 | 2.2.8 |
| FR-012 | `credit()` records transaction log entry | 2 | 2.2.8 |
| FR-013 | `credit()` emits EventBus.currency_changed | 2 | 2.2.10 |
| FR-014 | `credit()` emits EventBus.currency_gained | 2 | 2.2.10 |
| FR-015 | `debit()` subtracts from balance | 2 | 2.2.9 |
| FR-016 | `debit()` returns true/false | 2 | 2.2.9 |
| FR-017 | `debit()` no state change on failure | 2 | 2.2.9 |
| FR-018 | `debit()` asserts amount > 0 | 2 | 2.2.9 |
| FR-019 | `debit()` records log only on success | 2 | 2.2.9 |
| FR-020 | `debit()` emits EventBus.currency_changed on success | 2 | 2.2.10 |
| FR-021 | `transact()` atomic multi-currency | 3 | 3.2.1 |
| FR-022 | `transact()` validates all costs first | 3 | 3.2.1 |
| FR-023 | `transact()` debits first, then credits | 3 | 3.2.1 |
| FR-024 | `transact()` logs transact_debit / transact_credit | 3 | 3.2.1 |
| FR-025 | `transact()` with empty costs always succeeds | 3 | 3.2.1 |
| FR-026 | `transact()` with empty gains = multi-debit | 3 | 3.2.1 |
| FR-027 | `to_dict()` serializes balances + log | 3 | 3.2.2 |
| FR-028 | `from_dict()` validates and restores | 3 | 3.2.3 |
| FR-029 | `from_dict()` clamps negative balances to 0 | 3 | 3.2.3 |
| FR-030 | Round-trip consistency | 3 | 3.2.3 |
| FR-031 | `reset()` zeros all balances and clears log | 3 | 3.2.4 |
| FR-032 | `get_transaction_log()` returns internal log | 2 | 2.2.6 |
| FR-033 | No balance ever negative (core invariant) | 2, 3 | 2.2.9, 3.2.1 |
| FR-034 | `get_all_balances()` returns copy | 2 | 2.2.5 |
| FR-035 | `transaction_log.gd` declares `class_name TransactionLog` | 1 | 1.2.1 |
| FR-036 | `transaction_log.gd` declares `extends RefCounted` | 1 | 1.2.1 |
| FR-037 | Constructor accepts optional `max_entries` (default 100) | 1 | 1.2.3 |
| FR-038 | `record()` appends transaction entry | 1 | 1.2.4 |
| FR-039 | Entry has exactly 5 keys | 1 | 1.2.4 |
| FR-040 | Timestamp from `Time.get_ticks_msec() / 1000.0` | 1 | 1.2.4 |
| FR-041 | Circular buffer overwrites oldest when full | 1 | 1.2.4 |
| FR-042 | `get_recent()` returns chronological order | 1 | 1.2.5 |
| FR-043 | `get_recent()` returns defensive copy | 1 | 1.2.5 |
| FR-044 | `get_all()` returns all populated entries | 1 | 1.2.6 |
| FR-045 | `get_count()` returns current count | 1 | 1.2.6 |
| FR-046 | `clear()` resets write pointer and count | 1 | 1.2.7 |
| FR-047 | `to_dict()` serializes only populated entries | 1 | 1.2.8 |
| FR-048 | `from_dict()` restores and validates | 1 | 1.2.8 |

### Acceptance Criteria → Validation Gates

| AC | Description | Phase | Verification |
|----|-------------|-------|--------------|
| AC-001 | `wallet.gd` exists with class_name Wallet, extends RefCounted | 2 | 2.V.1, 2.V.2 |
| AC-002 | Fresh wallet Gold = 0 | 2 | `test_fresh_wallet_gold_is_zero` |
| AC-003 | Fresh wallet Essence = 0 | 2 | `test_fresh_wallet_essence_is_zero` |
| AC-004 | Fresh wallet Fragments = 0 | 2 | `test_fresh_wallet_fragments_is_zero` |
| AC-005 | Fresh wallet Artifacts = 0 | 2 | `test_fresh_wallet_artifacts_is_zero` |
| AC-006 | `get_all_balances()` has 4 keys | 2 | `test_get_all_balances_has_four_keys` |
| AC-007 | `get_all_balances()` returns copy | 2 | `test_get_all_balances_returns_copy` |
| AC-008 | credit(GOLD, 100) → balance 100 | 2 | `test_credit_gold_increases_balance` |
| AC-009 | Two credit(GOLD, 50) → balance 100 | 2 | `test_credit_accumulates` |
| AC-010 | credit() works for all 4 currencies | 2 | `test_credit_*_increases_balance` (4 tests) |
| AC-011 | credit() records log entry type "credit" | 2 | `test_credit_records_transaction` |
| AC-012 | credit() with amount ≤ 0 triggers assertion | 2 | Guard in `credit()` implementation |
| AC-013 | debit(GOLD, 30) on 100 → true, balance 70 | 2 | `test_debit_succeeds_when_sufficient` |
| AC-014 | debit(GOLD, 100) on 100 → true, balance 0 | 2 | `test_debit_exact_balance` |
| AC-015 | debit(GOLD, 101) on 100 → false, balance 100 | 2 | `test_debit_fails_when_insufficient` |
| AC-016 | debit() works for all 4 currencies | 2 | `test_debit_works_for_all_currencies` |
| AC-017 | debit() logs "debit" on success | 2 | `test_debit_records_transaction_on_success` |
| AC-018 | Failed debit() does not log | 2 | `test_debit_does_not_record_on_failure` |
| AC-019 | debit() with amount ≤ 0 triggers assertion | 2 | Guard in `debit()` implementation |
| AC-020 | can_afford({GOLD: 50}) true when balance 100 | 2 | `test_can_afford_single_currency_true` |
| AC-021 | can_afford({GOLD: 150}) false when balance 100 | 2 | `test_can_afford_single_currency_false` |
| AC-022 | can_afford multi-currency true | 2 | `test_can_afford_multi_currency_true` |
| AC-023 | can_afford multi-currency one short → false | 2 | `test_can_afford_multi_currency_one_short` |
| AC-024 | can_afford({}) → true | 2 | `test_can_afford_empty_costs_always_true` |
| AC-025 | can_afford() does not modify balances | 2 | `test_can_afford_does_not_modify_balances` |
| AC-026 | transact() debit-only succeeds | 3 | `test_transact_debit_only_succeeds` |
| AC-027 | transact() fails when one currency insufficient | 3 | `test_transact_fails_atomically_no_partial_debit` |
| AC-028 | transact() debit + credit atomic | 3 | `test_transact_debit_and_credit` |
| AC-029 | transact({}, {GOLD: 100}) pure grant succeeds | 3 | `test_transact_pure_grant_always_succeeds` |
| AC-030 | Failed transact() leaves ALL balances unchanged | 3 | `test_transact_fails_atomically_no_partial_debit` |
| AC-031 | Successful transact() records one log per currency | 3 | `test_transact_records_log_entries` |
| AC-032 | transact() same currency in costs and gains | 3 | `test_transact_same_currency_in_costs_and_gains` |
| AC-033 | to_dict() has "balances" key | 3 | `test_to_dict_has_balances_key` |
| AC-034 | to_dict() has "log" key | 3 | `test_to_dict_has_log_key` |
| AC-035 | Round-trip preserves balances | 3 | `test_round_trip_preserves_balances` |
| AC-036 | from_dict() missing currency → 0 | 3 | `test_from_dict_missing_currency_defaults_to_zero` |
| AC-037 | from_dict() negative → clamped to 0 | 3 | `test_from_dict_negative_balance_clamped_to_zero` |
| AC-038 | from_dict() unknown keys → ignored | 3 | `test_from_dict_ignores_unknown_keys` |
| AC-039 | reset() zeros all and clears log | 3 | `test_reset_zeros_all_balances`, `test_reset_clears_transaction_log` |
| AC-040 | `transaction_log.gd` exists with class_name, extends RefCounted | 1 | 1.V.1, 1.V.2 |
| AC-041 | Default capacity 100 | 1 | `test_default_capacity_is_100` |
| AC-042 | Custom capacity | 1 | `test_custom_capacity` |
| AC-043 | Entry has 5 keys | 1 | `test_record_entry_has_five_keys` |
| AC-044 | get_recent(3) returns 3 most recent chronological | 1 | `test_get_recent_chronological_order` |
| AC-045 | get_recent(N) where N > count returns all | 1 | `test_get_recent_more_than_available` |
| AC-046 | get_count() tracks correctly | 1 | `test_get_count_increments_correctly` |
| AC-047 | Circular buffer caps at max_entries | 1 | `test_get_count_caps_at_max_entries`, `test_circular_buffer_overwrite` |
| AC-048 | Oldest entries overwritten when full | 1 | `test_circular_buffer_overwrite`, `test_circular_buffer_multiple_overwrites` |
| AC-049 | get_recent() returns defensive copy | 1 | `test_get_recent_returns_defensive_copy` |
| AC-050 | clear() resets count, get_all() empty | 1 | `test_clear_resets_count`, `test_clear_empties_get_all` |
| AC-051 | to_dict() has max_entries and entries keys | 1 | `test_to_dict_has_required_keys` |
| AC-052 | Round-trip serialization | 1 | `test_round_trip_serialization`, `test_round_trip_after_circular_overwrite` |
| AC-053 | to_dict() only populated entries | 1 | `test_to_dict_only_populated_entries` |

---

*End of TASK-008 Implementation Plan*
