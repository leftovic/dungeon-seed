# TASK-002a: Deterministic RNG — Core (Seed + Generation)

## Section 1: Header

| Field | Value |
|---|---|
| **Task ID** | TASK-002a |
| **Title** | Deterministic RNG — Core Seeding & Generation |
| **Priority** | 🔴 P0 — Critical Foundation |
| **Tier** | T1 — Core Infrastructure |
| **Complexity** | 2 pts (Trivial) |
| **Phase** | Phase 1 — Core Data Models |
| **Wave** | Wave 1 (no dependencies) |
| **Stream** | ⚪ TCH (Technical) — Primary |
| **Cross-Stream** | 🔴 MCH (Mechanics) — blocks dungeon generation, loot tables, combat |
| **GDD Reference** | GDD-v2.md §4.2 — Procedural Generation & Determinism |
| **Milestone** | MS-1: Core Models Complete |
| **Dependencies** | None — **Wave 1 foundation** |
| **Dependents** | TASK-002b (extended methods), TASK-010 (Dungeon Generator), TASK-011 (Loot Tables), TASK-012 (Seed Grove), TASK-015 (Expedition Resolver) |
| **Target File** | `src/models/rng.gd` |
| **Class Name** | `DeterministicRNG` |
| **Extends** | `RefCounted` |
| **Algorithm** | xorshift64* (63-bit positive integers) |

---

## Section 2: Description

### What This Is

`DeterministicRNG` is a deterministic pseudo-random number generator implementing the xorshift64\* algorithm. This task covers the **core seeding and generation layer**: initialization via integer or string seed, and raw 63-bit integer generation via the xorshift algorithm. Five public methods: `seed_int()`, `seed_string()`, `next_int()`, `randf()`, `randi()`.

The class extends `RefCounted` (not Node) and carries `class_name DeterministicRNG` for zero scene-tree coupling.

### Why Determinism Matters

Dungeon Seed's entire procedural generation pipeline — layouts, rooms, loot, enemies, traps — flows from a single seed string. Determinism is load-bearing:

- **Seed Sharing**: A player types `"FIRE-42"` into the Seed Grove, generates a dungeon with rare loot on floor 3, shares the seed with a friend. The friend gets the *exact same* dungeon with the *exact same* loot in the *exact same* location.
- **Replay Consistency**: Returning to a previously explored seed regenerates identically.
- **Debug Reproducibility**: QA attaches a seed to a bug report; developers regenerate the identical dungeon state.

If the RNG is not perfectly deterministic, a single bit flip in the sequence cascades through every downstream consumer (room placement, loot roll, enemy selection), producing a completely different dungeon. Determinism is not optional.

### Player Experience Impact

Players never interact with `DeterministicRNG` directly — they experience it through the Seed Grove UI, where they plant a seed and watch a dungeon grow. The RNG is invisible infrastructure. If it breaks, the entire procedural generation chain breaks. The emotional contract is: **"This seed means this world."**

### Technical Overview

**Algorithm**: xorshift64\* with shifts (13, 7, 17) and multiplier `0x2545F4914F6CDD1D`.

**Seeding**:
- `seed_int(val: int)` — Direct assignment to internal state (masked to 63-bit positive).
- `seed_string(s: String)` — Hash string via SHA-256, take first 8 bytes as int64, seed.

**Generation**:
- `next_int()` — Core xorshift64\* step; returns 63-bit positive int.
- `randf()` — Normalize `next_int()` to [0.0, 1.0).
- `randi(max_val: int)` — Return [0, max_val) via rejection sampling.

**State**:
- `_state: int` — 63-bit internal state. Never zero after seeding (guards against degenerate state).

### Development Cost

| Activity | Estimate |
|---|---|
| Implementation (seeding + generation) | 1 hour |
| Unit tests (GUT suite, 5 core methods) | 1 hour |
| Code review + integration smoke | 0.5 hours |
| **Total** | **2.5 hours** |

---

## Section 3: Use Cases

**Kai the Speedrunner**: Plants a known seed `"SPEED-001"` with deterministic RNG, speedruns dungeons with reproducible enemy placements, practices optimal routes.

**Luna the Completionist**: Shares a seed string `"LOOT-99"` with a friend after discovering rare chest placement. Friend enters same seed, finds identical chest, verifies loot location.

**Developer (QA)**: Reports bug with seed string `"CRASH-42"` in crash report. Developer runs same seed, reproduces dungeon state and crash identically.

---

## Section 4: Glossary

| Term | Definition |
|---|---|
| **xorshift64\*** | Pseudorandom number generator: applies XOR and rotation shifts to internal state; output multiplied by constant. Fast, 64-bit, period ~2^64. |
| **Determinism** | Given the same seed, the RNG produces the same sequence forever. |
| **RefCounted** | Godot memory model: reference-counted (no parent node). Freed when all references drop. |
| **SHA-256** | Cryptographic hash function. Converts string to fixed 256-bit digest; first 8 bytes used as seed int. |
| **Rejection Sampling** | Technique for bounded random integers: generate values until result is in valid range, discard out-of-range. |
| **63-bit Positive** | Integer range [0, 2^63 - 1]. Godot `int` is signed 64-bit; mask to [0, 0x7FFFFFFFFFFFFFFF] to ensure positive. |

---

## Section 5: Out of Scope

- Higher-order methods (`randi_range`, `shuffle`, `pick`, `weighted_pick`) — see TASK-002b.
- Godot's global `randf()` / `randi()` replacement or monkey-patching.
- Visualization or debug UI for RNG state.
- Performance optimization beyond algorithmic correctness.
- Thread safety or concurrent seeding (each RNG instance is single-threaded).
- Cryptographic-grade randomness (xorshift64\* is NOT cryptographically secure).
- Save/load persistence of RNG state (handled per consumer, e.g., Dungeon Generator).

---

## Section 6: Functional Requirements

| FR ID | Requirement | Priority |
|---|---|---|
| **FR-001** | `seed_int(val: int) -> void` MUST set `_state` to `val & MASK_63`, ensuring 63-bit positive value. MUST NOT allow zero state; if `val & MASK_63 == 0`, set `_state = 1`. | P0 |
| **FR-002** | `seed_string(s: String) -> void` MUST hash string via SHA-256, extract first 8 bytes as int64, and seed via `seed_int()`. MUST handle empty strings (seed to zero → coerced to 1). MUST handle Unicode strings. | P0 |
| **FR-003** | `next_int() -> int` MUST implement xorshift64\* with shifts (13, 7, 17) and multiplier `0x2545F4914F6CDD1D`. MUST return 63-bit positive integer. MUST advance `_state` each call. | P0 |
| **FR-004** | `randf() -> float` MUST return `next_int() / (2^63 - 1)` as float in [0.0, 1.0). MUST NOT return exactly 1.0. MUST be deterministic given seed. | P0 |
| **FR-005** | `randi(max_val: int) -> int` MUST return integer in [0, max_val). MUST reject max_val <= 0 and raise error. MUST use rejection sampling to avoid modulo bias. | P0 |
| **FR-006** | MASK_63 constant MUST equal `0x7FFFFFFFFFFFFFFF` (2^63 - 1). MULTIPLIER constant MUST equal `0x2545F4914F6CDD1D`. Shifts MUST be (13, 7, 17). | P0 |

---

## Section 7: Non-Functional Requirements

| NFR ID | Requirement |
|---|---|
| **NFR-001** | **Performance**: `next_int()` MUST complete in < 1 microsecond on target hardware (xorshift64\* is O(1) bit operations). |
| **NFR-002** | **Memory**: `_state` is single 64-bit int. Total memory footprint < 1KB per instance. |
| **NFR-003** | **Godot Version**: Requires Godot 4.5+ (GDScript 2.0 type hints). |
| **NFR-004** | **Input Latency**: RNG calls are synchronous. No async operations. |
| **NFR-005** | **Determinism**: Given identical seed, sequence MUST be identical across platforms (Windows, Linux, macOS, Web). |
| **NFR-006** | **Type Safety**: All methods MUST use GDScript type hints (no `var` without type). |
| **NFR-007** | **Accessibility**: Not applicable (infrastructure component; no player-facing UI). |

---

## Section 8: Designer's Manual

**Not applicable** — `DeterministicRNG` is infrastructure code with no tuning knobs. It is consumed by downstream systems (Dungeon Generator, Loot Tables, etc.), which expose designer-facing parameters.

**For consumers**: Create an instance, seed it, and use `next_int()`, `randf()`, or `randi()`. Example:

```gdscript
var rng = DeterministicRNG.new()
rng.seed_string("FIRE-42")
var random_int = rng.next_int()
var random_float = rng.randf()
var roll_d20 = rng.randi(20)  # [0, 20)
```

---

## Section 9: Assumptions

| Assumption | Rationale |
|---|---|
| **Godot 4.5+** | GDScript 2.0 type hints required. Older versions lack strict typing. |
| **GDScript int is 64-bit** | Godot GDScript `int` is signed 64-bit. Masking to 63 bits is required. |
| **SHA-256 available** | Godot 4.5 provides `sha256_text()` string method. No external crypto library needed. |
| **No global RNG state** | Each `DeterministicRNG` instance is independent. No global singleton or shared state. |
| **Stateless seeding** | Seeding does not depend on current `_state`. `seed_int(42)` always sets `_state = 42`. |
| **Single-threaded** | RNG state is not protected by locks. Each thread (or coroutine) needs its own `DeterministicRNG` instance. |
| **xorshift64\* is sufficient** | Period ~2^64 is adequate for Dungeon Seed. Higher-period generators (PCG, MT19937) not required. |

---

## Section 10: Security & Anti-Cheat

| Threat | Exploit | Impact | Mitigation | Detection |
|---|---|---|---|---|
| **Seed Prediction** | Player intercepts RNG state from memory, predicts next random value, exploits dungeon layout knowledge before exploring. | MEDIUM — Gives single player unfair knowledge; multiplayer co-op cheating if seed is private. | RNG state is volatile (only in RAM during session). Seed string is public (by design). Prediction requires knowledge of xorshift64\* algorithm + internal state snapshot. Store RNG state in memory only; never persist unencrypted. | Monitor for statistical impossibilities in loot rolls (e.g., 5 legendaries in a row from a 1% drop). |
| **Seed Injection** | Player modifies save file to inject a known "lucky" seed, regenerate dungeon with optimal loot placement. | MEDIUM — Breaks determinism promise ("your seed, your dungeon"). Unfair advantage if save is synced to multiplayer leaderboard. | Seeds are strings; save file checksums/encryption prevent hex editing. If multiplayer, server-side seed validation: server generates RNG, client reads only results. | Log seed strings in telemetry. Flag accounts with statistically unlikely seed sequences (e.g., same rare seed twice in one day). |
| **Algorithm Substitution** | Player patches `DeterministicRNG` bytecode (decompile GDScript, swap algorithm), changes RNG output to always roll high. | HIGH — Completely breaks fairness in any competitive feature (leaderboards, PvP). | RNG state is server-authoritative in multiplayer. Single-player: RNG is client-side (accept): client can cheat their own dungeon for no multiplayer benefit. | Multiplayer: server regenerates dungeon from seed, compares with client state. Single-player: no mitigation needed (cheating own game is allowed). |

---

## Section 11: Best Practices

| Category | Practice |
|---|---|
| **State Management** | Never expose `_state` as public property. State is private; mutations only via `seed_int()` / `seed_string()`. |
| **Type Safety** | All methods use GDScript type hints. Avoid untyped `var` declarations. |
| **Determinism Contracts** | Document that seeding with the same value ALWAYS produces the same sequence. Tests verify this. |
| **Error Handling** | `randi(max_val)` rejects max_val <= 0 with `assert()` (fail fast). `seed_string()` handles empty strings gracefully (coerce to state 1). |
| **Dependency Injection** | Consumers receive RNG instances via constructor or method parameters, not global singletons. Enables testing and isolation. |
| **Signal-Free Design** | RNG emits no signals. It is a pure deterministic function; state changes are not observed elsewhere. |
| **Comments** | Inline comments explain xorshift64\* bit operations (shifts, XOR, multiplication). |

---

## Section 12: Troubleshooting

| Symptom | Cause | Solution |
|---|---|---|
| **Seed changes but RNG output is identical** | SHA-256 hash collision for two different seed strings (astronomically rare, but possible). | Verify input seed strings. Use string comparison test: `assert(hash1 != hash2)` for different inputs. |
| **RNG output is zero** | State was seeded to zero; guard coerces to 1. Verify `seed_int(0)` sets state to 1, not 0. | Check test `test_seed_int_zero_becomes_one()`. |
| **randf() returns exactly 1.0** | Division by zero or rounding error. Should return [0.0, 1.0). | Verify `randf()` returns `next_int() / float(0x7FFFFFFFFFFFFFFF)` (cast to float). Test: `assert(rng.randf() < 1.0)`. |
| **randi(max) occasionally returns max_val or higher** | Modulo bias or overflow. Rejection sampling implementation is broken. | Verify rejection sampling: loop until `next_int() < max_val * (2^63 / max_val)`. |
| **Sequence is different after recompile** | Algorithm constants (MULTIPLIER, shifts) are wrong in compiled code. | Check constants in source: MULTIPLIER = 0x2545F4914F6CDD1D, shifts = (13, 7, 17). |
| **Unicode seed hashes to zero** | UTF-8 encoding edge case. | Test: `rng.seed_string("你好")` (Chinese characters). Verify state != 0. |

---

## Section 13: Acceptance Criteria

**Core Functionality**:
- [ ] AC-001: `DeterministicRNG` class exists in `src/models/rng.gd` with `class_name DeterministicRNG`.
- [ ] AC-002: Extends `RefCounted` (not Node).
- [ ] AC-003: `_state: int` member variable is private.
- [ ] AC-004: Constants defined: `MASK_63 = 0x7FFFFFFFFFFFFFFF`, `MULTIPLIER = 0x2545F4914F6CDD1D`.

**Seeding**:
- [ ] AC-005: `seed_int(val: int) -> void` sets `_state = val & MASK_63`.
- [ ] AC-006: `seed_int(0)` coerces state to 1 (never zero).
- [ ] AC-007: `seed_string(s: String) -> void` hashes via SHA-256 and seeds.
- [ ] AC-008: `seed_string("")` (empty string) results in state != 0.
- [ ] AC-009: `seed_string("FIRE-42") == seed_string("FIRE-42")` produces identical sequences.

**Generation**:
- [ ] AC-010: `next_int() -> int` returns 63-bit positive integer (no negatives, no overflow).
- [ ] AC-011: `next_int()` sequence changes each call (no repeats within 1000 calls).
- [ ] AC-012: `randf() -> float` returns value in [0.0, 1.0); never exactly 0.0 or 1.0.
- [ ] AC-013: `randi(20) -> int` returns value in [0, 20); deterministic and uniform.
- [ ] AC-014: `randi(1)` returns 0 (only valid value).
- [ ] AC-015: `randi(0)` or negative raises error with assertion.

**Determinism**:
- [ ] AC-016: Given seed "TEST-001", sequence of 100 `randf()` calls is identical on Windows, Linux, macOS.
- [ ] AC-017: No state corruption across 1M calls to `next_int()`.

**Type Safety**:
- [ ] AC-018: All methods have GDScript type hints (no untyped `var`).
- [ ] AC-019: No implicit type coercions (cast explicitly).

---

## Section 14: Testing Requirements

**Test File**: `tests/models/test_rng_core.gd` (extends `GutTest`).

```gdscript
extends GutTest

var _rng: DeterministicRNG

func before_each() -> void:
    _rng = DeterministicRNG.new()

# ===== Seeding Tests =====

func test_seed_int_basic() -> void:
    # Arrange
    var seed_val: int = 42
    
    # Act
    _rng.seed_int(seed_val)
    var val1: int = _rng.next_int()
    
    # Reset and reseed
    _rng.seed_int(seed_val)
    var val2: int = _rng.next_int()
    
    # Assert
    gut.assert_eq(val1, val2, "Same seed must produce same sequence")

func test_seed_int_zero_becomes_one() -> void:
    _rng.seed_int(0)
    var val1: int = _rng.next_int()
    
    _rng.seed_int(0)
    var val2: int = _rng.next_int()
    
    gut.assert_eq(val1, val2, "Zero seed coerced to 1; sequence must be identical")
    gut.assert_ne(val1, 0, "Zero seed should not produce zero output")

func test_seed_int_large_value() -> void:
    var seed_val: int = 0x7FFFFFFFFFFFFFFF  # 2^63 - 1
    _rng.seed_int(seed_val)
    var val: int = _rng.next_int()
    gut.assert_ge(val, 0, "next_int() must be non-negative")
    gut.assert_le(val, 0x7FFFFFFFFFFFFFFF, "next_int() must be 63-bit")

func test_seed_string_basic() -> void:
    _rng.seed_string("FIRE-42")
    var val1: int = _rng.next_int()
    
    _rng.seed_string("FIRE-42")
    var val2: int = _rng.next_int()
    
    gut.assert_eq(val1, val2, "Same seed string must produce same sequence")

func test_seed_string_empty() -> void:
    _rng.seed_string("")
    var val: int = _rng.next_int()
    gut.assert_ne(val, 0, "Empty seed coerced to 1; output must not be zero")

func test_seed_string_unicode() -> void:
    _rng.seed_string("你好")  # Chinese characters
    var val: int = _rng.next_int()
    gut.assert_ge(val, 0, "Unicode seed must produce valid output")

func test_seed_string_different_seeds_different_sequences() -> void:
    _rng.seed_string("FIRE-42")
    var val1: int = _rng.next_int()
    
    _rng.seed_string("WATER-99")
    var val2: int = _rng.next_int()
    
    gut.assert_ne(val1, val2, "Different seeds must produce different sequences")

# ===== next_int() Tests =====

func test_next_int_returns_positive() -> void:
    _rng.seed_int(12345)
    for i in range(100):
        var val: int = _rng.next_int()
        gut.assert_ge(val, 0, "next_int() must be non-negative (call %d)" % i)
        gut.assert_le(val, 0x7FFFFFFFFFFFFFFF, "next_int() must be 63-bit (call %d)" % i)

func test_next_int_sequence_advances() -> void:
    _rng.seed_int(999)
    var val1: int = _rng.next_int()
    var val2: int = _rng.next_int()
    var val3: int = _rng.next_int()
    gut.assert_ne(val1, val2, "Sequence must advance (val1 != val2)")
    gut.assert_ne(val2, val3, "Sequence must advance (val2 != val3)")

func test_next_int_period() -> void:
    # Verify no repeats in 10K calls (xorshift64* has period ~2^64)
    _rng.seed_int(1)
    var seen: Dictionary = {}
    var repeats: int = 0
    for i in range(10000):
        var val: int = _rng.next_int()
        if val in seen:
            repeats += 1
        seen[val] = true
    gut.assert_eq(repeats, 0, "No repeats in 10K calls (period test)")

# ===== randf() Tests =====

func test_randf_in_range() -> void:
    _rng.seed_int(555)
    for i in range(1000):
        var val: float = _rng.randf()
        gut.assert_ge(val, 0.0, "randf() >= 0.0 (call %d)" % i)
        gut.assert_lt(val, 1.0, "randf() < 1.0 (call %d)" % i)

func test_randf_distribution() -> void:
    _rng.seed_int(777)
    var buckets: Array[int] = [0, 0, 0, 0, 0]  # [0-0.2), [0.2-0.4), ... [0.8-1.0)
    for i in range(10000):
        var val: float = _rng.randf()
        var bucket: int = int(val * 5.0)
        if bucket >= 0 and bucket < 5:
            buckets[bucket] += 1
    # Expect roughly 2000 in each bucket (±500 tolerance for randomness)
    for i in range(5):
        gut.assert_ge(buckets[i], 1500, "Bucket %d count >= 1500" % i)
        gut.assert_le(buckets[i], 2500, "Bucket %d count <= 2500" % i)

func test_randf_deterministic() -> void:
    _rng.seed_int(111)
    var seq1: Array[float] = []
    for i in range(10):
        seq1.append(_rng.randf())
    
    _rng.seed_int(111)
    var seq2: Array[float] = []
    for i in range(10):
        seq2.append(_rng.randf())
    
    for i in range(10):
        gut.assert_almost_eq(seq1[i], seq2[i], 1e-6, "randf() sequence deterministic (index %d)" % i)

# ===== randi(max) Tests =====

func test_randi_basic() -> void:
    _rng.seed_int(222)
    for i in range(1000):
        var val: int = _rng.randi(20)
        gut.assert_ge(val, 0, "randi(20) >= 0 (call %d)" % i)
        gut.assert_lt(val, 20, "randi(20) < 20 (call %d)" % i)

func test_randi_edge_case_one() -> void:
    _rng.seed_int(333)
    for i in range(100):
        var val: int = _rng.randi(1)
        gut.assert_eq(val, 0, "randi(1) must always return 0 (call %d)" % i)

func test_randi_invalid_max() -> void:
    _rng.seed_int(444)
    # randi(0) should fail with assertion
    assert_signal_emitted_at_least(_rng, "test_rng_error", 1,
        "randi(0) must raise error",
        func(): _rng.randi(0))

func test_randi_deterministic() -> void:
    _rng.seed_int(555)
    var seq1: Array[int] = []
    for i in range(20):
        seq1.append(_rng.randi(100))
    
    _rng.seed_int(555)
    var seq2: Array[int] = []
    for i in range(20):
        seq2.append(_rng.randi(100))
    
    for i in range(20):
        gut.assert_eq(seq1[i], seq2[i], "randi() sequence deterministic (index %d)" % i)

func test_randi_distribution() -> void:
    _rng.seed_int(666)
    var buckets: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]  # 0-9, 10-19, ..., 90-99
    for i in range(10000):
        var val: int = _rng.randi(100)
        var bucket: int = val / 10
        if bucket >= 0 and bucket < 10:
            buckets[bucket] += 1
    # Expect roughly 1000 in each bucket (±300 tolerance)
    for i in range(10):
        gut.assert_ge(buckets[i], 700, "Bucket %d >= 700" % i)
        gut.assert_le(buckets[i], 1300, "Bucket %d <= 1300" % i)

# ===== Cross-call Determinism =====

func test_full_sequence_determinism() -> void:
    # Seed both RNGs identically, verify full sequence of mixed calls
    var rng1 = DeterministicRNG.new()
    var rng2 = DeterministicRNG.new()
    
    rng1.seed_string("DETERMINISM-TEST")
    rng2.seed_string("DETERMINISM-TEST")
    
    for i in range(50):
        var int1: int = rng1.next_int()
        var int2: int = rng2.next_int()
        gut.assert_eq(int1, int2, "next_int() deterministic (call %d)" % i)
        
        var float1: float = rng1.randf()
        var float2: float = rng2.randf()
        gut.assert_almost_eq(float1, float2, 1e-6, "randf() deterministic (call %d)" % i)
        
        var rand1: int = rng1.randi(1000)
        var rand2: int = rng2.randi(1000)
        gut.assert_eq(rand1, rand2, "randi() deterministic (call %d)" % i)
```

---

## Section 15: Playtesting Verification

| Scenario | Steps | Expected Output | Red Flags |
|---|---|---|---|
| **Seed Consistency** | Create RNG, seed with "FIRE-42", call `next_int()` 10 times, record values. Restart process, seed "FIRE-42", verify identical 10 values. | All 10 values match exactly. | Values differ between runs. |
| **Seed String Hashing** | Create two RNGs, seed one with "TEST" and one with "test" (different case), call `next_int()` on both. | Different sequences (case-sensitive hash). | Identical sequences (hash ignoring case). |
| **Zero Seed Guard** | Create RNG, seed with 0, call `next_int()`, check output is nonzero. | Output is nonzero. | Output is zero (guard failed). |
| **Float Range** | Create RNG, seed with 12345, call `randf()` 1000 times, verify all in [0, 1). | All values in [0.0, 1.0). | Any value < 0 or >= 1.0. |
| **Integer Bounds** | Create RNG, seed with 99999, call `randi(100)` 1000 times, verify all in [0, 100). | All values in range. | Any value < 0 or >= 100. |
| **Performance** | Create RNG, seed, call `next_int()` in a loop 1M times, measure elapsed time. | < 1 second on target hardware. | > 5 seconds (algorithm inefficiency). |
| **Error Handling** | Create RNG, call `randi(-1)`, `randi(0)`. | Both raise assertion errors. | No error; code runs. |
| **Memory** | Create 1000 RNG instances, monitor memory usage. | < 1 MB total (1KB per instance). | > 10 MB (memory leak). |

---

## Section 16: Implementation Prompt

Write `src/models/rng.gd` — a self-contained deterministic RNG class implementing xorshift64\*.

**Requirements**:
1. Class name `DeterministicRNG`, extends `RefCounted`.
2. Private member `_state: int` (63-bit positive).
3. Constants: `MASK_63 = 0x7FFFFFFFFFFFFFFF`, `MULTIPLIER = 0x2545F4914F6CDD1D`.
4. Methods (all with type hints, no untyped `var`):
   - `seed_int(val: int) -> void`
   - `seed_string(s: String) -> void`
   - `next_int() -> int`
   - `randf() -> float`
   - `randi(max_val: int) -> int`
5. Inline comments explaining xorshift64\* bit operations.
6. Error handling: `randi()` asserts max_val > 0.

**Implementation**:

```gdscript
class_name DeterministicRNG
extends RefCounted

# Constants for xorshift64* algorithm
const MASK_63: int = 0x7FFFFFFFFFFFFFFF
const MULTIPLIER: int = 0x2545F4914F6CDD1D

var _state: int = 1  # 63-bit positive state; never zero

func seed_int(val: int) -> void:
    """Seed the RNG with an integer value."""
    _state = val & MASK_63
    if _state == 0:
        _state = 1  # Prevent degenerate zero state

func seed_string(s: String) -> void:
    """Seed the RNG with a string (hashed via SHA-256)."""
    if s.is_empty():
        _state = 1
        return
    
    var hash: String = s.sha256_text()
    # Take first 8 bytes of hash as int64
    var seed_val: int = 0
    for i in range(8):
        var byte_val: int = hash[i].to_int()
        seed_val = (seed_val << 8) | byte_val
    
    seed_int(seed_val)

func next_int() -> int:
    """Generate next 63-bit positive integer via xorshift64*."""
    # xorshift64* algorithm: x ^= x >> 13; x ^= x << 7; x ^= x >> 17
    var x: int = _state
    x ^= x >> 13
    x ^= x << 7
    x ^= x >> 17
    
    # Update state for next call
    _state = x
    
    # Output transformation: multiply by constant
    var output: int = (x * MULTIPLIER) & MASK_63
    return output

func randf() -> float:
    """Generate random float in [0.0, 1.0)."""
    var val: int = next_int()
    # Normalize to [0, 1) by dividing by max 63-bit value
    return float(val) / float(MASK_63)

func randi(max_val: int) -> int:
    """Generate random integer in [0, max_val)."""
    assert(max_val > 0, "randi() max_val must be positive")
    
    # Rejection sampling to avoid modulo bias
    var limit: int = (MASK_63 / max_val) * max_val
    var val: int
    while true:
        val = next_int()
        if val < limit:
            return val % max_val
```

---

**End of TASK-002a**
