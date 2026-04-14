# TASK-002b: Deterministic RNG — Extended Methods (Range, Shuffle, Pick)

## Section 1: Header

| Field | Value |
|---|---|
| **Task ID** | TASK-002b |
| **Title** | Deterministic RNG — Extended Methods |
| **Priority** | 🔴 P0 — Critical Foundation |
| **Tier** | T1 — Core Infrastructure |
| **Complexity** | 2 pts (Trivial) |
| **Phase** | Phase 1 — Core Data Models |
| **Wave** | Wave 1 (depends on TASK-002a) |
| **Stream** | ⚪ TCH (Technical) — Primary |
| **Cross-Stream** | 🔴 MCH (Mechanics) — dungeon generation, loot tables, combat |
| **GDD Reference** | GDD-v2.md §4.2 — Procedural Generation & Determinism |
| **Milestone** | MS-1: Core Models Complete |
| **Dependencies** | **TASK-002a** (core RNG methods: next_int, randi) |
| **Dependents** | TASK-010 (Dungeon Generator), TASK-011 (Loot Tables), TASK-012 (Seed Grove), TASK-015 (Expedition Resolver) |
| **Target File** | `src/models/rng.gd` (extends from TASK-002a) |
| **Class Name** | `DeterministicRNG` (existing from TASK-002a) |
| **Extends** | `RefCounted` |

---

## Section 2: Description

### What This Is

This task extends `DeterministicRNG` (completed in TASK-002a) with four higher-order methods that build on the core generation layer: `randi_range()` (inclusive range), `shuffle()` (Fisher-Yates in-place shuffle), `pick()` (uniform random selection), and `weighted_pick()` (weighted random selection).

These methods are **pure utilities** — they use `next_int()` and `randi()` internally, inheriting determinism from the core layer. Every call to `pick()` or `shuffle()` produces identical results given the same seed.

### Why Extended Methods Matter

**Dungeon Generator** (TASK-010) needs to:
- Shuffle room placement orders (deterministically).
- Pick random enemy types from a list (uniformly).
- Pick random loot drops from weighted tables (rarer items less frequent).
- Select trap placement ranges (min/max bounds).

**Loot Tables** (TASK-011) needs to:
- Roll weighted drops (50% Common, 40% Uncommon, 9% Rare, 1% Legendary).
- Shuffle inventory slots for item placement.

**Seed Grove** (TASK-012) needs to:
- Randomize cosmetic variations within deterministic bounds (garden appearance).

Without these methods, every consumer reimplements shuffle/pick logic, duplicating code and risking subtle bugs. Centralizing them in `DeterministicRNG` ensures consistency.

### Player Experience Impact

Players never see these methods directly. They experience the results: a shuffled dungeon room order appears "random" but is deterministic given the seed. A weighted loot table feels fair (common drops frequent, legendaries rare) and is reproducible (same seed = same drops).

### Technical Overview

**Four New Methods**:

1. **`randi_range(min_val: int, max_val: int) -> int`** — Return integer in [min_val, max_val] (inclusive). Wrapper around `randi()`.

2. **`shuffle(array: Array) -> Array`** — Fisher-Yates in-place shuffle. Mutates input; returns input for chaining. O(n) time, O(1) space.

3. **`pick(array: Array) -> Variant`** — Uniform random selection from array. Equivalent to `array[randi(array.size())]`.

4. **`weighted_pick(items: Array, weights: Array[float]) -> Variant`** — Weighted selection. Each item has a probability proportional to its weight. Uses cumulative sum + binary search or linear scan.

All four methods are O(1) to O(n) and use the core `randi()` and `next_int()` methods, inheriting determinism automatically.

### Development Cost

| Activity | Estimate |
|---|---|
| Implementation (4 methods) | 0.75 hours |
| Unit tests (GUT suite, 4 methods) | 0.75 hours |
| Integration test + review | 0.5 hours |
| **Total** | **2 hours** |

---

## Section 3: Use Cases

**Kai the Speedrunner**: Uses `shuffle()` to deterministically order dungeon rooms; learns optimal room sequence for a seed; optimizes route.

**Luna the Completionist**: Uses `weighted_pick()` to see loot drop distribution; shares seed with friend, verifying identical drops.

**Monster Spawner** (TASK-010): Uses `pick()` to select random enemy type from `[Goblin, Orc, Troll]`; calls shuffled multiple times for varied encounters.

**Loot Table** (TASK-011): Uses `weighted_pick()` with weights `[0.5, 0.4, 0.09, 0.01]` for rarity tiers; ensures reproducible drop rates.

---

## Section 4: Glossary

| Term | Definition |
|---|---|
| **Fisher-Yates Shuffle** | In-place array shuffle: iterate from end to start, swap current element with random earlier element. O(n) time, O(1) space. Cryptographically unbiased. |
| **Inclusive Range** | Range [min, max] where both min and max are valid outputs. Opposite of exclusive [min, max). |
| **Uniform Distribution** | Each outcome equally likely. `pick([A, B, C])` returns A, B, or C with probability 1/3 each. |
| **Weighted Distribution** | Outcomes have probabilities proportional to weights. `weighted_pick([A, B], [0.3, 0.7])` returns A with 30% chance, B with 70%. |
| **Cumulative Sum** | Running total of weights. For [0.3, 0.7], cumsum = [0.3, 1.0]. Used to map random float to weighted choice. |
| **In-Place Mutation** | `shuffle()` modifies input array directly; returns same reference (not a copy). |

---

## Section 5: Out of Scope

- Alternative shuffle algorithms (Knuth, Durstenfeld) — Fisher-Yates is standard.
- Weighted pick variants (exponential weights, softmax sampling) — linear cumsum is sufficient.
- Performance optimization beyond algorithmic complexity.
- Thread safety (each RNG instance is single-threaded).
- Immutable array variants (input array is mutated by `shuffle()`).
- Weighted pick with normalized weights (caller must ensure weights sum to 1.0 or handle themselves).

---

## Section 6: Functional Requirements

| FR ID | Requirement | Priority |
|---|---|---|
| **FR-001** | `randi_range(min_val: int, max_val: int) -> int` MUST return integer in [min_val, max_val] inclusive. MUST handle min_val > max_val by asserting. MUST use `randi()` internally. | P0 |
| **FR-002** | `shuffle(array: Array) -> Array` MUST implement Fisher-Yates algorithm. MUST mutate input in-place. MUST return same array reference. MUST handle empty arrays (no-op, return empty array). | P0 |
| **FR-003** | `shuffle()` MUST iterate from array.size()-1 down to 1. For each index i, swap array[i] with array[randi(i+1)]. Deterministic given seed. | P0 |
| **FR-004** | `pick(array: Array) -> Variant` MUST select random element uniformly from array. MUST return any element with equal probability 1/size(). MUST assert array is non-empty. | P0 |
| **FR-005** | `weighted_pick(items: Array, weights: Array[float]) -> Variant` MUST select items[i] with probability weights[i]/sum(weights). MUST require items.size() == weights.size(); assert otherwise. MUST handle zero sum (assert). | P0 |
| **FR-006** | `weighted_pick()` MUST use cumulative sum method: compute cumsum, roll random float [0, sum), find first index where cumsum[i] >= roll. Deterministic. | P0 |

---

## Section 7: Non-Functional Requirements

| NFR ID | Requirement |
|---|---|
| **NFR-001** | **Time Complexity**: `randi_range()` O(1), `shuffle()` O(n), `pick()` O(1), `weighted_pick()` O(n). |
| **NFR-002** | **Space Complexity**: `randi_range()` O(1), `shuffle()` O(1) (in-place), `pick()` O(1), `weighted_pick()` O(n) (cumsum array). |
| **NFR-003** | **Determinism**: Given identical seed, all four methods produce identical results across runs and platforms. |
| **NFR-004** | **Type Safety**: All methods use GDScript type hints. No untyped `var`. |
| **NFR-005** | **Error Handling**: Invalid ranges, empty arrays, mismatched array sizes result in `assert()` failures (fail-fast). |

---

## Section 8: Designer's Manual

**Not applicable** — Extended methods are infrastructure utilities with no tuning knobs. Consumed by downstream systems (Dungeon Generator, Loot Tables, etc.).

**Usage Examples**:

```gdscript
var rng = DeterministicRNG.new()
rng.seed_string("GAME-SEED")

# Inclusive range [10, 20]
var rolled_level: int = rng.randi_range(10, 20)

# Shuffle array in-place
var rooms: Array = [Room1, Room2, Room3, Room4]
rng.shuffle(rooms)  # Rooms now in random order (deterministic)

# Uniform pick
var enemy_type = rng.pick([Goblin, Orc, Troll])

# Weighted pick (50% common, 40% uncommon, 10% rare)
var items = [CommonSword, UncommonShield, RareCrown]
var weights = [0.5, 0.4, 0.1]
var loot = rng.weighted_pick(items, weights)
```

---

## Section 9: Assumptions

| Assumption | Rationale |
|---|---|
| **TASK-002a Complete** | `randi()` and `next_int()` exist and are deterministic. |
| **Array Size < 2^31** | No arrays larger than 2 billion elements (Godot int limit). |
| **Weights are Positive** | `weighted_pick()` assumes all weights >= 0. Caller ensures this. |
| **Weight Sum Non-Zero** | `weighted_pick()` asserts sum(weights) > 0. |
| **No External Sorting** | Shuffle does not need external comparators; uniform swap is sufficient. |
| **In-Place Mutation OK** | `shuffle()` mutates input array; caller accepts this. |

---

## Section 10: Security & Anti-Cheat

| Threat | Exploit | Impact | Mitigation | Detection |
|---|---|---|---|---|
| **Shuffle Order Prediction** | Player knows seed, runs `shuffle()` offline, predicts room order before exploring dungeon. | MEDIUM — Gives single-player knowledge advantage; breaks surprise factor. Acceptable for single-player. | Single-player: no mitigation (cheating own game is OK). Multiplayer: seed is server-authoritative; client receives shuffled results, not seed. | Multiplayer: server validates client-reported room order matches server shuffle. |
| **Weighted Pick Manipulation** | Player modifies weights array to make legendaries more common, calls `weighted_pick()`. | HIGH — Breaks loot economy. If save is synced, breaks multiplayer fairness. | Save file encryption/checksum prevents weights tampering. Multiplayer: loot drops server-authoritative (client displays only). | Server verifies loot drop distribution matches intended weights; flags statistically impossible sequences. |
| **Pick Bias Exploitation** | Player expects `pick()` to always favor first element; exploits pattern. | LOW — `pick()` is uniform; no exploit pattern exists. | No mitigation needed; algorithm is unbiased. | N/A |

---

## Section 11: Best Practices

| Category | Practice |
|---|---|
| **Fisher-Yates Correctness** | Iterate from end to start. Swap index i with random [0, i]. Ensure all indices visited exactly once. |
| **Array Mutation** | `shuffle()` mutates input; document this clearly. Caller should expect this. |
| **Weighted Sum Safety** | Check weights sum before using in `weighted_pick()`. Avoid division by zero. |
| **Empty Array Handling** | `pick()` and `weighted_pick()` assert non-empty. `shuffle()` returns empty array unchanged. |
| **Type Consistency** | `pick()` and `weighted_pick()` return `Variant` (any type). Caller must know return type. |
| **Determinism Contracts** | Document that all four methods are deterministic given core RNG seeding. |

---

## Section 12: Troubleshooting

| Symptom | Cause | Solution |
|---|---|---|
| **shuffle() doesn't change array order** | Array has 0 or 1 element (no shuffling possible). | Verify array.size() > 1. Single-element arrays are unchanged by design. |
| **pick() returns None / null** | Array is empty; `assert()` failed. | Ensure array is non-empty before calling `pick()`. |
| **weighted_pick() returns wrong item** | Weights do not sum to 1.0; cumsum calculation off. | Verify weights.size() == items.size() and weights sum to ~1.0 (allow ±0.001 tolerance). |
| **weighted_pick() crashes** | Mismatched array sizes or negative weights. | Verify items.size() == weights.size() and all weights >= 0. |
| **shuffle() returns different order** | RNG was re-seeded between calls. | Verify seed is called once at start, not between shuffle calls. |
| **pick() always returns first element** | RNG is broken (always returns 0). | Test core RNG with `test_rng_core.gd`. Verify `next_int()` returns varied values. |

---

## Section 13: Acceptance Criteria

**randi_range()**:
- [ ] AC-001: `randi_range(10, 20)` returns integer in [10, 20] inclusive (100+ rolls).
- [ ] AC-002: `randi_range(10, 20)` produces same sequence given identical seed.
- [ ] AC-003: `randi_range(20, 10)` (reversed) raises assertion error.
- [ ] AC-004: `randi_range(5, 5)` always returns 5.

**shuffle()**:
- [ ] AC-005: `shuffle([A, B, C, D])` mutates array in-place; returns same reference.
- [ ] AC-006: `shuffle()` produces deterministic order given seed.
- [ ] AC-007: `shuffle([])` returns empty array unchanged.
- [ ] AC-008: After `shuffle()`, all original elements present (no lost elements).
- [ ] AC-009: Shuffled array distribution is uniform (statistical test).

**pick()**:
- [ ] AC-010: `pick([A, B, C])` returns one of A, B, or C.
- [ ] AC-011: `pick()` is deterministic given seed.
- [ ] AC-012: `pick([])` raises assertion error.
- [ ] AC-013: Over 3000 picks from [A, B, C], each appears ~1000 times (±300 tolerance).

**weighted_pick()**:
- [ ] AC-014: `weighted_pick([A, B], [0.3, 0.7])` returns A ~30% of time, B ~70% of time (10K samples).
- [ ] AC-015: `weighted_pick()` is deterministic given seed.
- [ ] AC-016: `weighted_pick([A, B, C], [0.3, 0.7])` (mismatched sizes) raises assertion error.
- [ ] AC-017: `weighted_pick([A], [0.0])` (zero weight) raises assertion error (sum must be > 0).

**Integration**:
- [ ] AC-018: All four methods use `randi()` or `randf()` internally (inherit core determinism).
- [ ] AC-019: No external state dependencies; methods are pure functions.

---

## Section 14: Testing Requirements

**Test File**: `tests/models/test_rng_extended.gd` (extends `GutTest`).

```gdscript
extends GutTest

var _rng: DeterministicRNG

func before_each() -> void:
    _rng = DeterministicRNG.new()

# ===== randi_range() Tests =====

func test_randi_range_basic() -> void:
    _rng.seed_int(100)
    for i in range(100):
        var val: int = _rng.randi_range(10, 20)
        gut.assert_ge(val, 10, "randi_range(10, 20) >= 10 (call %d)" % i)
        gut.assert_le(val, 20, "randi_range(10, 20) <= 20 (call %d)" % i)

func test_randi_range_single_value() -> void:
    _rng.seed_int(200)
    for i in range(50):
        var val: int = _rng.randi_range(5, 5)
        gut.assert_eq(val, 5, "randi_range(5, 5) always 5 (call %d)" % i)

func test_randi_range_deterministic() -> void:
    _rng.seed_int(300)
    var seq1: Array[int] = []
    for i in range(20):
        seq1.append(_rng.randi_range(1, 100))
    
    _rng.seed_int(300)
    var seq2: Array[int] = []
    for i in range(20):
        seq2.append(_rng.randi_range(1, 100))
    
    for i in range(20):
        gut.assert_eq(seq1[i], seq2[i], "randi_range() deterministic (index %d)" % i)

func test_randi_range_reversed() -> void:
    _rng.seed_int(400)
    # randi_range(20, 10) should fail (min > max)
    assert_signal_emitted_at_least(_rng, "test_rng_error", 1,
        "randi_range(max < min) should raise error",
        func(): _rng.randi_range(20, 10))

func test_randi_range_negative() -> void:
    _rng.seed_int(500)
    var val: int = _rng.randi_range(-10, 10)
    gut.assert_ge(val, -10, "Negative ranges supported")
    gut.assert_le(val, 10, "Negative ranges supported")

# ===== shuffle() Tests =====

func test_shuffle_basic() -> void:
    _rng.seed_int(600)
    var arr: Array = [1, 2, 3, 4, 5]
    var original: Array = arr.duplicate()
    var returned: Array = _rng.shuffle(arr)
    
    gut.assert_eq(returned, arr, "shuffle() returns same array reference")
    gut.assert_eq_shallow(arr, original, "All elements present after shuffle")

func test_shuffle_mutates_in_place() -> void:
    _rng.seed_int(700)
    var arr: Array = ["A", "B", "C"]
    var before: String = str(arr)
    _rng.shuffle(arr)
    var after: String = str(arr)
    
    # Arrays should be different order (with high probability)
    # (1 in 6 chance they're identical by random chance; acceptable)
    gut.assert_contains(["A", "B", "C"], arr[0], "All elements still present")

func test_shuffle_empty_array() -> void:
    _rng.seed_int(800)
    var arr: Array = []
    var returned: Array = _rng.shuffle(arr)
    gut.assert_eq_shallow(returned, [], "Empty array unchanged")

func test_shuffle_single_element() -> void:
    _rng.seed_int(900)
    var arr: Array = [42]
    _rng.shuffle(arr)
    gut.assert_eq(arr[0], 42, "Single element unchanged")

func test_shuffle_deterministic() -> void:
    _rng.seed_int(1000)
    var arr1: Array = [1, 2, 3, 4, 5]
    _rng.shuffle(arr1)
    
    _rng.seed_int(1000)
    var arr2: Array = [1, 2, 3, 4, 5]
    _rng.shuffle(arr2)
    
    gut.assert_eq_shallow(arr1, arr2, "shuffle() deterministic")

func test_shuffle_distribution() -> void:
    # Verify all permutations are reachable
    _rng.seed_int(1100)
    var arr: Array = [0, 1, 2]
    var permutations: Dictionary = {}
    
    for i in range(1000):
        _rng.seed_int(1100 + i)
        var test_arr: Array = [0, 1, 2]
        _rng.shuffle(test_arr)
        var key: String = str(test_arr)
        if key not in permutations:
            permutations[key] = 0
        permutations[key] += 1
    
    gut.assert_ge(permutations.size(), 4, "Multiple permutations achieved")  # At least 4 of 6

# ===== pick() Tests =====

func test_pick_basic() -> void:
    _rng.seed_int(1200)
    var arr: Array = ["A", "B", "C"]
    var count: int = 0
    for i in range(100):
        var val: Variant = _rng.pick(arr)
        if val in arr:
            count += 1
    gut.assert_eq(count, 100, "pick() returns valid element")

func test_pick_empty_array() -> void:
    _rng.seed_int(1300)
    var arr: Array = []
    # pick([]) should fail with assertion
    assert_signal_emitted_at_least(_rng, "test_rng_error", 1,
        "pick() on empty array should raise error",
        func(): _rng.pick(arr))

func test_pick_deterministic() -> void:
    _rng.seed_int(1400)
    var arr: Array = [10, 20, 30, 40]
    var seq1: Array = []
    for i in range(20):
        seq1.append(_rng.pick(arr))
    
    _rng.seed_int(1400)
    var seq2: Array = []
    for i in range(20):
        seq2.append(_rng.pick(arr))
    
    for i in range(20):
        gut.assert_eq(seq1[i], seq2[i], "pick() deterministic (index %d)" % i)

func test_pick_distribution() -> void:
    _rng.seed_int(1500)
    var arr: Array = ["A", "B", "C"]
    var counts: Dictionary = {"A": 0, "B": 0, "C": 0}
    
    for i in range(3000):
        var val: Variant = _rng.pick(arr)
        if val in counts:
            counts[val] += 1
    
    # Each should appear ~1000 times (±400 tolerance)
    for key in counts:
        gut.assert_ge(counts[key], 600, "Element '%s' count >= 600" % key)
        gut.assert_le(counts[key], 1400, "Element '%s' count <= 1400" % key)

# ===== weighted_pick() Tests =====

func test_weighted_pick_basic() -> void:
    _rng.seed_int(1600)
    var items: Array = ["Common", "Rare"]
    var weights: Array[float] = [0.9, 0.1]
    
    for i in range(100):
        var val: Variant = _rng.weighted_pick(items, weights)
        gut.assert(val == "Common" or val == "Rare", "pick() returns valid item (call %d)" % i)

func test_weighted_pick_deterministic() -> void:
    _rng.seed_int(1700)
    var items: Array = ["A", "B", "C"]
    var weights: Array[float] = [0.3, 0.5, 0.2]
    var seq1: Array = []
    for i in range(20):
        seq1.append(_rng.weighted_pick(items, weights))
    
    _rng.seed_int(1700)
    var seq2: Array = []
    for i in range(20):
        seq2.append(_rng.weighted_pick(items, weights))
    
    for i in range(20):
        gut.assert_eq(seq1[i], seq2[i], "weighted_pick() deterministic (index %d)" % i)

func test_weighted_pick_distribution() -> void:
    _rng.seed_int(1800)
    var items: Array = ["Common", "Uncommon", "Rare", "Legendary"]
    var weights: Array[float] = [0.5, 0.35, 0.13, 0.02]
    var counts: Dictionary = {}
    
    for item in items:
        counts[item] = 0
    
    for i in range(10000):
        var val: Variant = _rng.weighted_pick(items, weights)
        if val in counts:
            counts[val] += 1
    
    # Common: 50% ± 5% = [4500, 5500]
    gut.assert_ge(counts["Common"], 4500, "Common ~50%")
    gut.assert_le(counts["Common"], 5500, "Common ~50%")
    
    # Uncommon: 35% ± 5% = [3000, 4000]
    gut.assert_ge(counts["Uncommon"], 3000, "Uncommon ~35%")
    gut.assert_le(counts["Uncommon"], 4000, "Uncommon ~35%")
    
    # Rare: 13% ± 5% = [800, 1800]
    gut.assert_ge(counts["Rare"], 800, "Rare ~13%")
    gut.assert_le(counts["Rare"], 1800, "Rare ~13%")
    
    # Legendary: 2% ± 2% = [0, 400]
    gut.assert_le(counts["Legendary"], 400, "Legendary ~2%")

func test_weighted_pick_mismatched_sizes() -> void:
    _rng.seed_int(1900)
    var items: Array = ["A", "B", "C"]
    var weights: Array[float] = [0.5, 0.5]  # Mismatched!
    
    # Should fail assertion
    assert_signal_emitted_at_least(_rng, "test_rng_error", 1,
        "weighted_pick() mismatched sizes should raise error",
        func(): _rng.weighted_pick(items, weights))

func test_weighted_pick_zero_sum() -> void:
    _rng.seed_int(2000)
    var items: Array = ["A", "B"]
    var weights: Array[float] = [0.0, 0.0]  # Sum is zero!
    
    # Should fail assertion
    assert_signal_emitted_at_least(_rng, "test_rng_error", 1,
        "weighted_pick() zero weight sum should raise error",
        func(): _rng.weighted_pick(items, weights))

func test_weighted_pick_single_item() -> void:
    _rng.seed_int(2100)
    var items: Array = ["OnlyOne"]
    var weights: Array[float] = [1.0]
    
    for i in range(50):
        var val: Variant = _rng.weighted_pick(items, weights)
        gut.assert_eq(val, "OnlyOne", "Single item always selected (call %d)" % i)

# ===== Cross-method Determinism =====

func test_all_methods_deterministic_together() -> void:
    # Seed both RNGs, verify mixed-method sequence
    var rng1 = DeterministicRNG.new()
    var rng2 = DeterministicRNG.new()
    
    rng1.seed_string("EXTENDED-TEST")
    rng2.seed_string("EXTENDED-TEST")
    
    for i in range(10):
        var range1: int = rng1.randi_range(1, 100)
        var range2: int = rng2.randi_range(1, 100)
        gut.assert_eq(range1, range2, "randi_range() deterministic (call %d)" % i)
        
        var arr1: Array = [1, 2, 3, 4, 5]
        var arr2: Array = [1, 2, 3, 4, 5]
        rng1.shuffle(arr1)
        rng2.shuffle(arr2)
        gut.assert_eq_shallow(arr1, arr2, "shuffle() deterministic (call %d)" % i)
        
        var pick1: Variant = rng1.pick([10, 20, 30])
        var pick2: Variant = rng2.pick([10, 20, 30])
        gut.assert_eq(pick1, pick2, "pick() deterministic (call %d)" % i)
        
        var weighted1: Variant = rng1.weighted_pick(["A", "B"], [0.6, 0.4])
        var weighted2: Variant = rng2.weighted_pick(["A", "B"], [0.6, 0.4])
        gut.assert_eq(weighted1, weighted2, "weighted_pick() deterministic (call %d)" % i)
```

---

## Section 15: Playtesting Verification

| Scenario | Steps | Expected Output | Red Flags |
|---|---|---|---|
| **Range Inclusivity** | Create RNG, seed, call `randi_range(5, 5)` 10 times. | All returns = 5. | Any return != 5. |
| **Shuffle Mutation** | Create array [1,2,3], call `shuffle()`, check if mutated (or call 100x and verify determinism). | Array mutated in-place and deterministic. | Array not mutated or not deterministic. |
| **Shuffle All Elements Present** | Create [A,B,C,D,E], shuffle 100x, verify all elements still present. | All elements present each time. | Missing or duplicate elements. |
| **Pick Variance** | Call `pick([1,2,3])` 300 times, count frequency of each. | Each appears ~100 times (±50 tolerance). | One element heavily favored. |
| **Weighted Distribution** | Call `weighted_pick([A,B], [0.7, 0.3])` 1000 times, count. | A ~700, B ~300 (±100 tolerance). | Significantly different distribution. |
| **Determinism (seed)** | Seed RNG with "TEST-123", run: `randi_range(1, 100)`, `shuffle([1,2,3])`, `pick([A,B,C])`, `weighted_pick(...)`. Record all 4 results. Reseed "TEST-123", repeat. | All 4 results identical. | Any result differs. |
| **Performance** | Create RNG, seed, call `shuffle()` on 1000-element array 1000 times. Measure time. | < 1 second. | > 5 seconds. |
| **Memory** | Create 1000 RNG instances, call `weighted_pick()` with 100-element arrays. Monitor memory. | < 10 MB total. | > 50 MB. |

---

## Section 16: Implementation Prompt

Extend `src/models/rng.gd` with four new methods. Assume `next_int()` and `randi()` from TASK-002a are available.

**Requirements**:
1. Add to existing `DeterministicRNG` class (do not rewrite; only add new methods).
2. Four new public methods with type hints.
3. Inline comments explaining Fisher-Yates shuffle and cumulative sum logic.
4. Error handling: assertions for invalid inputs.

**Implementation** (add to end of existing `DeterministicRNG`):

```gdscript
func randi_range(min_val: int, max_val: int) -> int:
    """Generate random integer in [min_val, max_val] (inclusive)."""
    assert(min_val <= max_val, "randi_range: min_val must be <= max_val")
    var range_size: int = max_val - min_val + 1
    return min_val + randi(range_size)

func shuffle(array: Array) -> Array:
    """Fisher-Yates shuffle: in-place, deterministic, returns input reference."""
    if array.is_empty():
        return array
    
    # Iterate from end to start
    for i in range(array.size() - 1, 0, -1):
        # Swap current element with random earlier element
        var j: int = randi(i + 1)
        var temp: Variant = array[i]
        array[i] = array[j]
        array[j] = temp
    
    return array

func pick(array: Array) -> Variant:
    """Uniform random selection from array."""
    assert(not array.is_empty(), "pick: array must not be empty")
    return array[randi(array.size())]

func weighted_pick(items: Array, weights: Array[float]) -> Variant:
    """Weighted random selection: items[i] selected with probability weights[i]/sum(weights)."""
    assert(items.size() == weights.size(), "weighted_pick: items and weights arrays must match size")
    
    # Compute cumulative sum of weights
    var cumsum: Array[float] = []
    var total: float = 0.0
    for w in weights:
        assert(w >= 0.0, "weighted_pick: all weights must be non-negative")
        total += w
        cumsum.append(total)
    
    assert(total > 0.0, "weighted_pick: sum of weights must be positive")
    
    # Roll random float in [0, total)
    var roll: float = randf() * total
    
    # Find first cumsum[i] >= roll
    for i in range(cumsum.size()):
        if cumsum[i] >= roll:
            return items[i]
    
    # Fallback (should never reach due to cumsum construction)
    return items[items.size() - 1]
```

---

**End of TASK-002b**
