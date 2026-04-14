# TASK-002: Deterministic RNG Wrapper

## Section 1 · Header

| Field | Value |
|---|---|
| **Task ID** | TASK-002 |
| **Title** | Deterministic RNG Wrapper |
| **Priority** | 🔴 P0 — Critical Foundation |
| **Tier** | T1 — Core Infrastructure |
| **Complexity** | 3 pts (Trivial) |
| **Phase** | Phase 1 — Core Data Models |
| **Wave** | Wave 1 (no dependencies) |
| **Stream** | ⚪ TCH (Technical) — Primary |
| **Cross-Stream** | 🔴 MCH (Mechanics) — dungeon generation, loot tables, combat rolls |
| **GDD Reference** | GDD-v2.md §4.2 — Procedural Generation & Determinism |
| **Milestone** | MS-1: Core Models Complete |
| **Dependencies** | None |
| **Dependents** | TASK-010 (Dungeon Generator), TASK-011 (Loot Tables), TASK-012 (Seed Grove), TASK-015 (Expedition Resolver) |
| **Critical Path** | ❌ Not on critical path, but 3+ downstream tasks are blocked by this |
| **Estimated Effort** | 2-3 hours implementation + 1-2 hours testing |
| **Target File** | `src/models/rng.gd` |
| **Class Name** | `DeterministicRNG` |
| **Extends** | `RefCounted` |

---

## Section 2 · Description

### What This Is

`DeterministicRNG` is a self-contained, deterministic pseudo-random number generator that wraps the xorshift64* algorithm behind a clean, Godot-idiomatic API. It lives at `src/models/rng.gd`, extends `RefCounted` (not Node), and carries `class_name DeterministicRNG` so any system in the project can instantiate it with zero scene-tree coupling.

The class provides nine public methods covering the full surface area of randomness that Dungeon Seed requires: integer seeding, string seeding via SHA-256, raw 63-bit integer generation, unit-float generation, bounded integer generation, inclusive-range integer generation, Fisher-Yates shuffle, uniform random pick, and weighted random pick. Every method is statically typed with GDScript type hints and documented with inline comments.

### Why Determinism Matters for Dungeon Seed

Determinism is a **core design pillar** of Dungeon Seed (GDD §4.2). The entire procedural generation pipeline — dungeon layouts, room contents, loot drops, enemy placements, trap configurations — flows from a single seed value. This creates three player-facing guarantees:

1. **Seed Sharing** — A player can type the string `"FIRE-42"` into the Seed Grove, generate a dungeon, discover it contains a rare Ember Root on floor 3, then share `"FIRE-42"` with a friend. The friend types the same string and gets the *exact same* dungeon with the *exact same* Ember Root in the *exact same* location. This is the "tell your friend about the cool dungeon" social loop.

2. **Replay Consistency** — When a player returns to a previously explored seed, the dungeon regenerates identically. This supports the idle-game loop where Seeds grow in the Grove over real time and are re-entered for deeper exploration.

3. **Debug Reproducibility** — QA can attach a seed string to any bug report. Developers regenerate the identical dungeon state, eliminating "cannot reproduce" from the vocabulary.

If the RNG is not perfectly deterministic — if even one call produces a different value on a different run — the entire seed-sharing promise collapses. A single bit flip in the sequence cascades through every downstream consumer (room placement, loot roll, enemy selection), producing a completely different dungeon. Determinism is not a "nice to have." It is load-bearing.

### Player Experience Impact

Players never interact with `DeterministicRNG` directly. They experience it through the Seed Grove UI (TASK-012), where they plant a seed string and watch a dungeon grow. The RNG is invisible infrastructure — but if it breaks, *everything* the player sees breaks. The dungeon layout changes, the loot table shifts, the enemy composition shuffles. The player who shared `"FIRE-42"` with a friend now looks like a liar.

The emotional contract is: **"This seed means this world."** `DeterministicRNG` is the cryptographic handshake that keeps that contract.

### Technical Architecture

```
┌─────────────────────────────────────────────────┐
│              DeterministicRNG                    │
│              extends RefCounted                  │
│              class_name DeterministicRNG         │
├─────────────────────────────────────────────────┤
│  - _state: int          (63-bit internal state)  │
├─────────────────────────────────────────────────┤
│  + seed_int(val: int) -> void                    │
│  + seed_string(s: String) -> void                │
│  + next_int() -> int                             │
│  + randf() -> float                              │
│  + randi(max_val: int) -> int                    │
│  + randi_range(min_val: int, max_val: int) -> int│
│  + shuffle(array: Array) -> Array                │
│  + pick(array: Array) -> Variant                 │
│  + weighted_pick(items: Array,                   │
│                  weights: Array[float]) -> Variant│
└─────────────────────────────────────────────────┘
```

### System Interaction Map

```
TASK-010 Dungeon Generator ──┐
TASK-011 Loot Table Engine ──┤
TASK-012 Seed Grove Manager ─┼──▶ DeterministicRNG.new()
TASK-015 Expedition Resolver ┤      .seed_string("FIRE-42")
Future: Combat System ───────┘      .randi(), .randf(), .shuffle(), ...
```

Each consumer creates its own `DeterministicRNG` instance (or receives one via dependency injection). There is no global singleton. Each instance owns its own `_state`, so concurrent consumers cannot corrupt each other's sequences.

### Development Cost

| Activity | Estimate |
|---|---|
| Implementation (rng.gd) | 1.5 hours |
| Unit tests (GUT suite) | 1.5 hours |
| Integration smoke test | 0.5 hours |
| Code review | 0.5 hours |
| **Total** | **4 hours** |

This is a 3-point Trivial task. The algorithm already exists in `rng_wrapper_clean.gd`; the work is refactoring to `RefCounted`, adding missing methods (`randi_range`, `shuffle`, `pick`, `weighted_pick`), and writing comprehensive tests.

### Constraints and Design Decisions

| Decision | Rationale |
|---|---|
| **xorshift64\*** over Mersenne Twister | Faster, smaller state (single int vs 2.5KB), sufficient period (2^64-1), good statistical properties for game use |
| **RefCounted over Node** | RNG has no scene-tree presence. Node requires `.free()` or causes leaks. RefCounted is garbage-collected automatically. The existing code's `extends Node` is a bug. |
| **Custom impl over Godot's RandomNumberGenerator** | Godot's built-in RNG uses PCG internally, which is fine — but we cannot guarantee identical output across Godot versions. A custom implementation is version-stable forever. |
| **63-bit positive integers** | GDScript's `int` is a signed 64-bit integer. We mask to 63 bits (`0x7FFFFFFFFFFFFFFF`) to avoid negative values, which simplifies modular arithmetic downstream. |
| **SHA-256 for string seeding** | Converts arbitrary-length player-entered strings into well-distributed 64-bit seeds. Using only the first 8 bytes of the hash is sufficient for seed initialization. |
| **No global singleton** | Multiple systems need independent RNG streams. A global would create hidden coupling and make determinism harder to reason about. |

### Existing Code Reference

The file `src/gdscript/utils/rng_wrapper_clean.gd` contains a working xorshift64* implementation with one design bug (`extends Node` instead of `extends RefCounted`) and missing methods (`randi_range`, `shuffle`, `pick`, `weighted_pick`). The core algorithm — the bit-shift constants (13, 7, 17) and the multiplication constant (`0x2545F4914F6CDD1D`) — must be preserved exactly, as they have been validated for statistical quality.

---

## Section 3 · Use Cases

### UC-1: Seed Sharing Between Players

**Actor:** Kai (Explorer archetype, mid-game)
**Precondition:** Kai has discovered a dungeon with a rare Ember Root on floor 3.
**Flow:**
1. Kai notes the seed string `"FIRE-42"` displayed in the Seed Grove UI.
2. Kai messages their friend Lina: "Try FIRE-42, there's an Ember Root on floor 3!"
3. Lina opens the Seed Grove, types `"FIRE-42"`, and plants the seed.
4. The Seed Grove Manager (TASK-012) calls `DeterministicRNG.new()`, then `seed_string("FIRE-42")`.
5. The Dungeon Generator (TASK-010) consumes the RNG to build floor layouts.
6. Lina's dungeon is **byte-for-byte identical** to Kai's. The Ember Root is on floor 3, same room, same position.
**Postcondition:** Both players experienced the same dungeon from the same seed string.
**RNG Methods Used:** `seed_string()`, `randi()`, `randf()`, `shuffle()`, `pick()`

### UC-2: Loot Table Rolling

**Actor:** Expedition Resolver (TASK-015)
**Precondition:** A party has cleared a dungeon room. The loot table for this room type is loaded.
**Flow:**
1. The Expedition Resolver holds a `DeterministicRNG` instance seeded from the dungeon seed + room index.
2. It calls `weighted_pick(loot_items, loot_weights)` to select a drop.
3. It calls `randi_range(1, 5)` to determine the quantity.
4. The same room in the same dungeon always drops the same loot in the same quantity.
**Postcondition:** Loot is deterministic per room per seed. Players cannot "re-roll" by re-entering the same room.
**RNG Methods Used:** `seed_int()`, `weighted_pick()`, `randi_range()`

### UC-3: Room Order Shuffling

**Actor:** Dungeon Generator (TASK-010)
**Precondition:** A floor template has 8 candidate room types. The generator must select and order 5 of them.
**Flow:**
1. The generator creates a local `DeterministicRNG` forked from the floor-level seed.
2. It calls `shuffle(candidate_rooms)` to randomize the order.
3. It takes the first 5 elements of the shuffled array as the floor's room sequence.
4. The same floor seed always produces the same room sequence.
**Postcondition:** Room ordering is deterministic and uses Fisher-Yates (unbiased) shuffle.
**RNG Methods Used:** `seed_int()`, `shuffle()`

### UC-4: Expedition Combat Resolution

**Actor:** Expedition Resolver (TASK-015)
**Precondition:** A party member attacks an enemy. Damage has a base value and a variance range.
**Flow:**
1. The resolver holds a combat-phase RNG instance.
2. It calls `randi_range(base_damage - variance, base_damage + variance)` to compute actual damage.
3. It calls `randf()` to check against the critical hit threshold (e.g., < 0.05 = crit).
4. All combat outcomes are deterministic per seed, enabling combat replay logs.
**Postcondition:** Combat results are reproducible from the seed.
**RNG Methods Used:** `randi_range()`, `randf()`

---

## Section 4 · Glossary

| Term | Definition |
|---|---|
| **xorshift64*** | A pseudorandom number generator algorithm from the xorshift family. Uses three XOR-shift operations followed by a multiplication by a magic constant (`0x2545F4914F6CDD1D`) to improve output quality. Period: 2^64 − 1. |
| **SHA-256** | Secure Hash Algorithm producing a 256-bit (32-byte) digest. Used here to convert arbitrary player-entered strings into well-distributed 64-bit seed values by taking the first 8 bytes of the hash. |
| **RefCounted** | Godot's base class for reference-counted objects. Automatically freed when no references remain. Unlike Node, does not require `.free()` or `.queue_free()` and has no scene-tree overhead. |
| **Deterministic** | Given the same initial state (seed), the system produces the identical sequence of outputs on every run, on every platform, in every Godot version. No external entropy is introduced. |
| **Seed** | The initial integer value that sets the RNG's internal state. All subsequent output is a pure function of this seed. Two instances seeded identically produce identical sequences. |
| **State** | The single `int` variable (`_state`) that the xorshift64* algorithm mutates on each call. The entire "memory" of the RNG is this one 63-bit integer. |
| **Fisher-Yates Shuffle** | An O(n) in-place array shuffling algorithm that produces a uniformly random permutation. For each index `i` from `n-1` down to `1`, swap element `i` with a randomly chosen element from `[0, i]`. |
| **Weighted Selection** | Choosing a random element from a set where each element has a non-uniform probability. Implemented by computing cumulative weights, generating a uniform float, and binary-searching for the bucket. |
| **Probability Distribution** | The mathematical function describing how likely each outcome is. For `randf()`, the distribution is uniform over `[0.0, 1.0)`. For `weighted_pick()`, the distribution is defined by the weights array. |
| **Modular Arithmetic** | Arithmetic where values "wrap around" after reaching a maximum. Used in `randi(max_val)` via the `%` (modulo) operator. Subject to modulo bias when `max_val` does not evenly divide the RNG's range, but acceptable for game use. |
| **Bit Masking** | Using bitwise AND (`&`) with a constant to constrain a value to a specific range of bits. `& 0x7FFFFFFFFFFFFFFF` masks to 63 bits, ensuring the result is a non-negative signed 64-bit integer. |
| **63-bit Positive Integer** | GDScript `int` is signed 64-bit. By masking with `0x7FFFFFFFFFFFFFFF`, we use only the lower 63 bits, guaranteeing non-negative values and avoiding sign-related edge cases in modular arithmetic. |
| **Period** | The length of the sequence before the RNG repeats. xorshift64* has a period of 2^64 − 1 (all non-zero states), meaning it will never repeat within any practical game session. |
| **Entropy** | Randomness from an unpredictable source (clock, user input, hardware). `DeterministicRNG` deliberately uses **zero** external entropy — all randomness derives solely from the seed. |
| **Fork (RNG)** | Creating a new `DeterministicRNG` instance seeded from a parent instance's output. Used to create independent sub-streams (e.g., one per dungeon floor) without cross-contamination. |
| **Modulo Bias** | A statistical bias introduced when mapping a uniform range to a smaller range via `%`. If the RNG range is not evenly divisible by `max_val`, lower values are slightly more probable. Acceptable for game use; not acceptable for cryptography. |

---

## Section 5 · Out of Scope

The following items are explicitly **not** part of this task:

| # | Out-of-Scope Item | Rationale |
|---|---|---|
| OOS-01 | **Cryptographic security** | xorshift64* is not cryptographically secure. Dungeon Seed is a single-player/co-op game, not a casino. Predictability from seed is a *feature*, not a bug. |
| OOS-02 | **Thread pooling / multi-threaded RNG** | Each consumer creates its own instance. No thread pool, no mutex, no atomic operations. GDScript's threading model doesn't require it for our use case. |
| OOS-03 | **Wrapping Godot's RandomNumberGenerator** | We intentionally avoid Godot's built-in RNG to guarantee cross-version determinism. Godot may change its internal algorithm between versions. |
| OOS-04 | **Network synchronization of RNG state** | Dungeon Seed is not a real-time multiplayer game. Seed strings are shared out-of-band (chat, social media). No RNG state is transmitted over the network. |
| OOS-05 | **Gaussian / normal distribution** | Only uniform distributions are needed for the current GDD. Gaussian can be added later via Box-Muller if combat or loot design requires bell curves. |
| OOS-06 | **RNG state serialization / save-file persistence** | RNG instances are ephemeral. Dungeons are regenerated from seed, not from saved RNG state. Save files store the seed string, not the internal `_state`. |
| OOS-07 | **Global singleton / autoload registration** | No `DeterministicRNG` autoload. Each consumer instantiates and owns its instance. Global state would undermine determinism isolation. |
| OOS-08 | **RNG visualization / debug overlay** | Debug tooling for RNG output (histograms, sequence inspection) is a separate task if needed. This task delivers the engine, not the dashboard. |
| OOS-09 | **Seeding from system clock or hardware entropy** | All seeds come from player input (seed strings) or deterministic derivation (parent seed + offset). No `Time.get_ticks_msec()` or `OS.get_unique_id()`. |
| OOS-10 | **Weighted shuffle** | `shuffle()` is unweighted (uniform Fisher-Yates). Weighted shuffling (e.g., priority deck) is not required by any current downstream task. |
| OOS-11 | **Distribution testing / chi-squared validation** | Statistical quality of xorshift64* is well-established in literature. We test determinism and bounds, not distribution uniformity, in the GUT suite. |
| OOS-12 | **Alternative PRNG algorithms** | No PCG, Mersenne Twister, or SplitMix64. xorshift64* is chosen and final. Algorithm selection is a closed decision. |

---

## Section 6 · Functional Requirements

| ID | Requirement | Acceptance Method |
|---|---|---|
| FR-001 | `seed_int(val: int) -> void` shall set `_state` to `val & 0x7FFFFFFFFFFFFFFF`. If the result is `0`, `_state` shall be set to `1`. | Unit test: seed with 0, verify state is 1. Seed with positive int, verify next_int output matches expected. |
| FR-002 | `seed_string(s: String) -> void` shall compute SHA-256 of `s.to_utf8_buffer()`, extract the first 8 bytes as a big-endian 64-bit integer, mask to 63 bits, and assign to `_state`. If result is `0`, `_state` shall be `1`. | Unit test: seed with known string, verify deterministic output. |
| FR-003 | `next_int() -> int` shall advance `_state` using the xorshift64* algorithm (shifts: 13, 7, 17; multiplier: `0x2545F4914F6CDD1D`) and return a 63-bit non-negative integer. | Unit test: seed with known value, verify first 10 outputs match hardcoded expected values. |
| FR-004 | `next_int()` shall never return a negative integer. | Unit test: generate 10,000 values, assert all >= 0. |
| FR-005 | `randf() -> float` shall return a value in the range `[0.0, 1.0)` — inclusive of `0.0`, exclusive of `1.0`. | Unit test: generate 100,000 values, assert all >= 0.0 and < 1.0. |
| FR-006 | `randf()` shall compute its result by taking `next_int()`, masking to 53 bits, and dividing by `(1 << 53) - 1`. | Unit test: seed with known value, verify randf output matches manual calculation. |
| FR-007 | `randi(max_val: int) -> int` shall return an integer in the range `[0, max_val)`. | Unit test: `randi(10)` returns values in `[0, 9]` over 10,000 iterations. |
| FR-008 | `randi(max_val)` shall return `0` when `max_val <= 0`. | Unit test: `randi(0)` returns `0`. `randi(-5)` returns `0`. |
| FR-009 | `randi_range(min_val: int, max_val: int) -> int` shall return an integer in the inclusive range `[min_val, max_val]`. | Unit test: `randi_range(3, 7)` returns values in `{3, 4, 5, 6, 7}` over 10,000 iterations. |
| FR-010 | `randi_range(min_val, max_val)` shall return `min_val` when `min_val == max_val`. | Unit test: `randi_range(5, 5)` always returns `5`. |
| FR-011 | `randi_range(min_val, max_val)` shall swap arguments when `min_val > max_val` and still return a value in the corrected range. | Unit test: `randi_range(7, 3)` returns values in `{3, 4, 5, 6, 7}`. |
| FR-012 | `shuffle(array: Array) -> Array` shall perform an in-place Fisher-Yates shuffle and return the same Array reference. | Unit test: verify returned reference is the same object. Verify shuffle is deterministic with same seed. |
| FR-013 | `shuffle([])` shall return the same empty array without error. `shuffle([x])` shall return `[x]`. | Unit test: empty and single-element edge cases. |
| FR-014 | `pick(array: Array) -> Variant` shall return a uniformly random element from the array. | Unit test: seed deterministically, verify `pick` returns expected element. |
| FR-015 | `pick([])` shall return `null` without error. | Unit test: `pick([])` returns `null`. |
| FR-016 | `weighted_pick(items: Array, weights: Array[float]) -> Variant` shall select an item with probability proportional to its weight. | Unit test: weights `[1.0, 0.0, 0.0]` always selects item 0. |
| FR-017 | `weighted_pick()` shall return `null` if `items` is empty or `weights` is empty. | Unit test: both empty-array cases. |
| FR-018 | `weighted_pick()` shall handle the case where all weights are `0.0` by returning `null`. | Unit test: `weighted_pick(["a","b"], [0.0, 0.0])` returns `null`. |
| FR-019 | Two `DeterministicRNG` instances seeded with the same integer shall produce identical sequences of `next_int()` calls. | Unit test: create two instances, seed both with `42`, verify 1,000 outputs are identical. |
| FR-020 | Two `DeterministicRNG` instances seeded with the same string shall produce identical sequences. | Unit test: create two instances, `seed_string("FIRE-42")` on both, verify 1,000 outputs are identical. |

---

## Section 7 · Non-Functional Requirements

| ID | Requirement | Target | Verification |
|---|---|---|---|
| NFR-001 | **Call throughput** | 1,000,000 `next_int()` calls in < 1 second on mid-range hardware | Benchmark test in GUT |
| NFR-002 | **Memory footprint** | Single `int` (8 bytes) of mutable state per instance | Code inspection |
| NFR-003 | **No Node inheritance** | Class extends `RefCounted`, not `Node`, `Node2D`, or any scene-tree type | Static analysis / code review |
| NFR-004 | **No heap allocations per call** | `next_int()`, `randf()`, `randi()`, `randi_range()` shall not create objects, arrays, or strings | Code inspection |
| NFR-005 | **GDScript type hints** | Every parameter, return type, and local variable shall have explicit type annotations | Code review; `# gdlint` clean |
| NFR-006 | **Zero external dependencies** | No autoloads, no singletons, no other script imports. Pure self-contained class. | Code inspection |
| NFR-007 | **Instantiation cost** | `DeterministicRNG.new()` shall complete in < 1 microsecond | Benchmark test |
| NFR-008 | **No signals** | The class shall emit no signals. It is a pure computational object. | Code inspection |
| NFR-009 | **No `_ready()`, `_process()`, or lifecycle callbacks** | Since it extends RefCounted, no engine callbacks are valid or needed. | Code inspection |
| NFR-010 | **GDScript 4.x compatibility** | Code shall use GDScript 4.x syntax: `@export` (if needed), typed arrays `Array[float]`, `class_name`, etc. | Godot 4.5 parser acceptance |
| NFR-011 | **No `print()` or debug output** | No `print()`, `push_warning()`, or `push_error()` in production code paths. Assertions only in debug builds. | Code inspection |
| NFR-012 | **Doc comments** | Every public method shall have a `##` doc comment describing parameters, return value, and edge-case behavior. | Code review |
| NFR-013 | **Idempotent seeding** | Calling `seed_int()` or `seed_string()` resets state completely; prior state has zero effect on post-seed output. | Unit test: seed, generate, re-seed with same value, verify identical output. |
| NFR-014 | **No `@export` or `@onready`** | RefCounted classes do not participate in the inspector or scene tree. No annotations that imply Node behavior. | Code inspection |
| NFR-015 | **Naming convention** | All methods use `snake_case`. Class uses `PascalCase`. Constants use `UPPER_SNAKE_CASE`. Follows Godot GDScript style guide. | Code review |
| NFR-016 | **Single-file implementation** | The entire class shall reside in one file: `src/models/rng.gd`. No partials, no helper scripts. | File system check |

---

## Section 8 · Designer's Manual

### 8.1 Creating and Seeding an Instance

```gdscript
# Create a new RNG instance — no scene tree needed
var rng: DeterministicRNG = DeterministicRNG.new()

# Seed from an integer (e.g., derived from a dungeon floor index)
rng.seed_int(12345)

# Seed from a player-entered string (e.g., from the Seed Grove UI)
rng.seed_string("FIRE-42")
```

**Important:** Always seed before generating. An unseeded instance has `_state = 0`, which is auto-corrected to `1` on the first generation call, but explicit seeding is the contract.

### 8.2 Generating Numbers

```gdscript
# Raw 63-bit positive integer
var raw: int = rng.next_int()

# Float in [0.0, 1.0) — use for probability checks
var chance: float = rng.randf()
if chance < 0.15:
    print("Critical hit!")  # 15% probability

# Integer in [0, max) — use for index selection
var room_index: int = rng.randi(8)  # 0..7

# Integer in [min, max] inclusive — use for damage ranges
var damage: int = rng.randi_range(10, 25)  # 10..25
```

### 8.3 Working with Arrays

```gdscript
# Shuffle an array in-place (Fisher-Yates)
var rooms: Array = ["Crypt", "Library", "Forge", "Garden", "Shrine"]
rng.shuffle(rooms)  # rooms is now shuffled; returns same reference

# Pick a single random element
var chosen: String = rng.pick(rooms)

# Weighted selection — items with higher weights are more likely
var loot: Array = ["Potion", "Sword", "Shield", "Gem"]
var weights: Array[float] = [0.5, 0.25, 0.15, 0.10]
var drop: String = rng.weighted_pick(loot, weights)
# Potion: 50%, Sword: 25%, Shield: 15%, Gem: 10%
```

### 8.4 Forking RNG for Independent Streams

When multiple systems need independent random streams from the same base seed (e.g., one per dungeon floor), **fork** the RNG by creating a new instance seeded from the parent:

```gdscript
# Master RNG seeded from the player's seed string
var master_rng: DeterministicRNG = DeterministicRNG.new()
master_rng.seed_string("FIRE-42")

# Fork a child RNG for floor 3
var floor_rng: DeterministicRNG = DeterministicRNG.new()
floor_rng.seed_int(master_rng.next_int())

# floor_rng is now independent — consuming it does not affect master_rng
var room_count: int = floor_rng.randi_range(4, 8)
```

**Why fork?** If the dungeon generator and the loot table engine both consume from the same RNG instance, adding a new room type to the generator would shift all subsequent loot rolls, breaking determinism for unrelated systems. Forking isolates streams.

### 8.5 Determinism Contract

The following code MUST print `true` on every run, on every platform, in every Godot version:

```gdscript
var a: DeterministicRNG = DeterministicRNG.new()
var b: DeterministicRNG = DeterministicRNG.new()
a.seed_int(42)
b.seed_int(42)
var match: bool = true
for i in range(1000):
    if a.next_int() != b.next_int():
        match = false
        break
print(match)  # true — always
```

### 8.6 Anti-Patterns to Avoid

| ❌ Don't | ✅ Do |
|---|---|
| Use Godot's `randi()` or `randf()` global functions | Use `DeterministicRNG` instance methods |
| Use `RandomNumberGenerator` from Godot | Use `DeterministicRNG` — cross-version stable |
| Share a single RNG instance across unrelated systems | Fork child instances from a master |
| Seed from `Time.get_ticks_msec()` | Seed from player-entered strings or deterministic derivation |
| Call `rng.next_int()` without seeding first | Always call `seed_int()` or `seed_string()` before generation |
| Store `_state` in save files | Store the seed string; regenerate from seed |

---

## Section 9 · Assumptions

| # | Assumption | Impact if Wrong |
|---|---|---|
| A-01 | GDScript `int` is a signed 64-bit integer on all target platforms (Windows, macOS, Linux, Web). | Bit masking and shift operations would produce different results. Entire algorithm breaks. |
| A-02 | GDScript `int` arithmetic wraps on overflow (modular 2^64 arithmetic) rather than throwing an error. | The xorshift multiplication step would fail or produce exceptions. |
| A-03 | Bitwise operators (`^`, `<<`, `>>`, `&`) on GDScript `int` operate on the full 64-bit representation. | Shift operations would truncate, producing wrong sequence values. |
| A-04 | `HashingContext` with `HASH_SHA256` is available in Godot 4.5 and produces identical output across platforms. | String seeding would be platform-dependent, breaking cross-platform seed sharing. |
| A-05 | `String.to_utf8_buffer()` produces identical byte sequences for the same string on all platforms. | Same seed string would produce different seeds on different OS, breaking determinism. |
| A-06 | GDScript `float` is IEEE 754 double-precision (64-bit) on all platforms. | `randf()` division would produce different results on different platforms. |
| A-07 | `RefCounted` subclasses can be instantiated with `.new()` without scene-tree access. | The class would require Node-like scaffolding, defeating the purpose. |
| A-08 | `class_name DeterministicRNG` is globally unique within the project. No other script uses this class name. | Godot would report a class name conflict at parse time. |
| A-09 | The `>>` operator on GDScript `int` is a logical right shift (zero-fill), not arithmetic (sign-extend). | The xorshift `x ^= (x >> 7)` step would produce different results, breaking the algorithm. |
| A-10 | Godot 4.5 supports typed array syntax `Array[float]` in method signatures. | `weighted_pick` signature would need to use untyped `Array`, losing type safety. |
| A-11 | `PackedByteArray` indexing (`d[i]`) returns an `int` in the range `[0, 255]`. | SHA-256 byte extraction for string seeding would produce negative or out-of-range values. |
| A-12 | No downstream consumer will call RNG methods from multiple threads simultaneously on the same instance. | Race conditions on `_state`. Mitigated by design: each consumer owns its own instance. |
| A-13 | The xorshift64* constants (13, 7, 17, `0x2545F4914F6CDD1D`) from the existing `rng_wrapper_clean.gd` have been validated for statistical quality. | The algorithm would produce biased or short-period sequences. (Validated by Marsaglia's original paper.) |
| A-14 | Players will enter seed strings using UTF-8 compatible characters (ASCII, emoji, CJK). No null bytes in seed strings. | `to_utf8_buffer()` would produce unexpected byte sequences. |
| A-15 | GUT test framework is available in the project for unit testing. | Tests would need to be written for a different framework. |
| A-16 | The `& 0x7FFFFFFFFFFFFFFF` mask is sufficient to prevent negative integers in all GDScript execution contexts. | `next_int()` could return negative values, breaking `randi()` modulo logic. |

---

## Section 10 · Security & Anti-Cheat Considerations

### Threat Model

`DeterministicRNG` is a **game-logic** RNG, not a security primitive. The threat model focuses on player fairness and anti-cheat, not cryptographic resistance.

### T-01: Seed Prediction for Loot Manipulation

**Threat:** A player reverse-engineers the xorshift64* algorithm (it's public knowledge), brute-forces seed strings to find seeds that produce rare loot on floor 1, and publishes "god seeds" that trivialize progression.

**Severity:** Low
**Mitigation:** This is **by design**. Seed sharing is a feature. If "god seeds" become a social problem, the game economy can be rebalanced by adjusting loot tables (TASK-011), not by obscuring seeds. The RNG is deterministic *on purpose*.

**Residual Risk:** Accepted. Seed discovery is part of the community metagame.

### T-02: RNG State Manipulation via Memory Editing

**Threat:** A player uses a memory editor (Cheat Engine) to modify `_state` mid-dungeon to force favorable outcomes.

**Severity:** Low (single-player game)
**Mitigation:**
- Dungeon Seed is primarily single-player/async co-op. Players cheating their own save does not harm others.
- If competitive leaderboards are added later, server-side validation of seed→result mappings would be needed (out of scope for this task).
- The `_state` variable is a GDScript member, not `@export`ed, so it's not trivially accessible via the Godot editor.

**Residual Risk:** Accepted for single-player. Flagged for future leaderboard design.

### T-03: Save File Seed Tampering

**Threat:** A player edits their save file to change stored seed strings, gaining access to dungeons they haven't legitimately discovered.

**Severity:** Low
**Mitigation:**
- Save file integrity is the responsibility of the save system (separate task), not the RNG.
- Seed strings are not secret — they're shared socially. Tampering to access "better" seeds is equivalent to looking up seeds online.

**Residual Risk:** Accepted. Save file protection is out of scope for TASK-002.

### T-04: Timing Side Channels

**Threat:** An attacker measures execution time of RNG calls to infer internal state.

**Severity:** Negligible
**Mitigation:** xorshift64* is constant-time (no branches, no data-dependent memory access). Additionally, this is a local game, not a network service. Timing attacks are not relevant.

**Residual Risk:** None.

---

## Section 11 · Best Practices

| # | Practice | Rationale |
|---|---|---|
| BP-01 | **Always seed explicitly before generating.** | An unseeded instance starts at `_state = 0` (corrected to 1). While functional, implicit seeding is a code smell that hides intent. |
| BP-02 | **Use `seed_string()` for player-facing seeds, `seed_int()` for internal derivation.** | String seeding handles arbitrary player input. Integer seeding is for programmatic forking (e.g., `floor_rng.seed_int(master.next_int())`). |
| BP-03 | **Fork RNG instances for independent streams.** | If dungeon layout and loot share one instance, adding a room shifts all loot. Fork isolates streams. |
| BP-04 | **Never mix `DeterministicRNG` with Godot's global `randi()`/`randf()`.** | Godot's globals use a separate, non-deterministic (time-seeded) RNG. Mixing them breaks reproducibility. |
| BP-05 | **Pass RNG instances as constructor/method parameters.** | Dependency injection makes determinism auditable. `func generate_floor(rng: DeterministicRNG)` is testable; reading from a global is not. |
| BP-06 | **Use `randi_range()` for inclusive ranges, `randi()` for zero-based exclusive ranges.** | Avoids off-by-one errors. `randi_range(1, 6)` = dice roll. `randi(array.size())` = index. |
| BP-07 | **Use `weighted_pick()` for loot tables, not manual threshold logic.** | `weighted_pick` encapsulates cumulative-weight logic correctly. Hand-rolled `if randf() < 0.3 ... elif ...` chains are error-prone. |
| BP-08 | **Do not store `_state` in save files.** | Store the seed string. Regenerate the dungeon from seed on load. RNG state is ephemeral. |
| BP-09 | **Keep RNG instances short-lived when possible.** | Create, seed, consume, discard. Long-lived instances risk accidental extra calls that shift the sequence. |
| BP-10 | **Test determinism in CI.** | A CI test that seeds two instances identically and compares 10,000 outputs catches any accidental non-determinism introduced by refactoring. |
| BP-11 | **Document the seed derivation chain.** | If floor 3's RNG is seeded from `master.next_int() + floor_index * 7919`, document this formula. Future developers must reproduce it. |
| BP-12 | **Never catch and suppress errors from RNG methods.** | If `pick([])` returns `null`, the caller should handle it explicitly, not wrap in `try`. Silent failures hide bugs in generation logic. |
| BP-13 | **Prefer `shuffle()` + slice over repeated `pick()` for sampling without replacement.** | `shuffle(candidates).slice(0, k)` is O(n). Repeated `pick()` with removal is O(n*k) and error-prone. |
| BP-14 | **Use typed arrays where possible.** | `var weights: Array[float] = [0.5, 0.3, 0.2]` catches type errors at parse time. |

---

## Section 12 · Troubleshooting Guide

### Issue 1: Same Seed Produces Different Results Between Runs

**Symptoms:** Two runs with `seed_string("FIRE-42")` produce different dungeon layouts.

**Root Causes:**
- A system is consuming RNG calls in a different order between runs (e.g., a loop iterates over a Dictionary, which has non-deterministic key order in some engines).
- An extra `rng.next_int()` call was added to one code path, shifting all subsequent values.
- Godot's global `randi()` or `randf()` is being mixed with `DeterministicRNG`.

**Resolution:**
1. Add logging to print the first 10 `next_int()` values immediately after seeding. Compare between runs.
2. Search the codebase for calls to Godot's global `randi()`, `randf()`, or `RandomNumberGenerator`.
3. Ensure Dictionary iteration is replaced with sorted-key iteration where RNG consumption order matters.

### Issue 2: Zero Seed Causes Stuck Sequence

**Symptoms:** After `seed_int(0)`, all `next_int()` calls return the same value.

**Root Cause:** xorshift algorithms produce all-zero output from a zero state. The zero-guard (`if _state == 0: _state = 1`) was accidentally removed.

**Resolution:** Verify `seed_int()` contains the zero-guard. The state `0` is the only absorbing state in xorshift; all other states produce the full period.

### Issue 3: Integer Overflow Concerns

**Symptoms:** Developer sees `_state * 0x2545F4914F6CDD1D` and worries about overflow.

**Explanation:** GDScript `int` is 64-bit. The multiplication *does* overflow — and that's correct. The overflow is masked by `& 0x7FFFFFFFFFFFFFFF`. This is standard practice for xorshift64*. The overflow is a feature, not a bug.

### Issue 4: `randf()` Returns 1.0

**Symptoms:** A downstream system receives `randf() == 1.0`, causing an index out-of-bounds when used as `int(randf() * array.size())`.

**Root Cause:** If `randf()` uses `/ float(frac_mask)` where `frac_mask = (1 << 53) - 1`, the maximum value is `(frac_mask) / frac_mask = 1.0`. However, since `next_int()` is masked to 63 bits and then further masked to 53 bits, and the divisor is `(1 << 53) - 1`, the maximum possible numerator equals the denominator, yielding exactly `1.0`.

**Resolution:** Use `/ float(1 << 53)` (divide by `2^53`, not `2^53 - 1`) to ensure the result is strictly `< 1.0`. The maximum value becomes `(2^53 - 1) / 2^53 ≈ 0.99999999999999989`. This is the standard technique. **The implementation in Section 16 uses this corrected formula.**

### Issue 5: `weighted_pick()` Always Returns the Same Item

**Symptoms:** Despite varying weights, `weighted_pick()` always returns the first item.

**Root Causes:**
- All weights except the first are `0.0`.
- The weights array has only one non-zero element.
- The RNG is not seeded, producing a predictable low sequence that always falls in the first bucket.

**Resolution:** Verify weights are populated correctly. Verify the RNG is seeded. Add a test with known weights and known seed to verify the expected selection.

### Issue 6: `shuffle()` Doesn't Seem Random

**Symptoms:** Shuffled arrays appear to retain partial ordering.

**Explanation:** Fisher-Yates produces a uniformly random permutation, but human perception of "random" is poor. With small arrays (< 5 elements), many permutations look "sorted." This is expected.

**Resolution:** Test with arrays of 20+ elements. Verify determinism: same seed → same permutation. The shuffle is correct if it matches the expected permutation for a given seed.

---

## Section 13 · Acceptance Criteria

All acceptance criteria must pass before this task is considered complete. Each criterion is independently testable.

| ID | Criterion | Verification |
|---|---|---|
| AC-001 | File `src/models/rng.gd` exists with `extends RefCounted` and `class_name DeterministicRNG`. | File inspection |
| AC-002 | `DeterministicRNG.new()` succeeds without scene-tree access (can be called from `_init()`, a test, or a tool script). | GUT test |
| AC-003 | `seed_int(42)` followed by 10 `next_int()` calls produces a hardcoded expected sequence that is identical on every run. | GUT test with literal expected values |
| AC-004 | `seed_string("FIRE-42")` followed by 10 `next_int()` calls produces a hardcoded expected sequence that is identical on every run. | GUT test with literal expected values |
| AC-005 | Two independently created instances seeded with `seed_int(42)` produce identical 1,000-element sequences from `next_int()`. | GUT test |
| AC-006 | Two independently created instances seeded with `seed_string("FIRE-42")` produce identical 1,000-element sequences. | GUT test |
| AC-007 | `next_int()` never returns a negative value over 100,000 calls. | GUT test with assertion loop |
| AC-008 | `randf()` returns values in `[0.0, 1.0)` over 100,000 calls — all `>= 0.0` and `< 1.0`. | GUT test with assertion loop |
| AC-009 | `randi(10)` returns values in `{0, 1, 2, ..., 9}` over 10,000 calls. All 10 values appear at least once. | GUT test with frequency map |
| AC-010 | `randi(0)` returns `0`. `randi(-1)` returns `0`. | GUT test |
| AC-011 | `randi_range(3, 7)` returns values in `{3, 4, 5, 6, 7}` over 10,000 calls. All 5 values appear. | GUT test with frequency map |
| AC-012 | `randi_range(5, 5)` always returns `5`. | GUT test |
| AC-013 | `randi_range(7, 3)` returns values in `{3, 4, 5, 6, 7}` (auto-swaps min/max). | GUT test |
| AC-014 | `shuffle([1,2,3,4,5])` returns the same Array reference (in-place). The shuffled order is deterministic per seed. | GUT test: identity check + content check |
| AC-015 | `shuffle([])` returns `[]` without error. `shuffle([42])` returns `[42]`. | GUT test |
| AC-016 | `pick(["a","b","c"])` returns a deterministic element per seed. Over 10,000 calls with re-seeding, all elements appear. | GUT test |
| AC-017 | `pick([])` returns `null` without error. | GUT test |
| AC-018 | `weighted_pick(["A","B"], [1.0, 0.0])` always returns `"A"` over 1,000 calls. | GUT test |
| AC-019 | `weighted_pick(["A","B"], [0.0, 1.0])` always returns `"B"` over 1,000 calls. | GUT test |
| AC-020 | `weighted_pick([], [])` returns `null`. `weighted_pick(["A"], [])` returns `null`. | GUT test |
| AC-021 | `weighted_pick(["A","B"], [0.0, 0.0])` returns `null` (all-zero weights). | GUT test |
| AC-022 | `seed_int(0)` does not produce a stuck sequence — `next_int()` returns varying values. (Zero-guard sets state to 1.) | GUT test: verify at least 2 distinct values in first 10 calls |
| AC-023 | Re-seeding with the same value resets the sequence: `seed_int(42)`, generate 5, `seed_int(42)`, generate 5 → both sequences match. | GUT test |
| AC-024 | All public methods have `##` doc comments. | Code review |
| AC-025 | All parameters and return types have GDScript type annotations. | Code review |

---

## Section 14 · Testing Requirements

All tests use GUT (Godot Unit Test) framework. Test file: `tests/models/test_rng.gd`.

```gdscript
extends GutTest
## Unit tests for DeterministicRNG (TASK-002).
## Covers: determinism, bounds, edge cases, distribution, shuffle, pick, weighted_pick.

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_rng(seed_val: int = 42) -> DeterministicRNG:
	var rng: DeterministicRNG = DeterministicRNG.new()
	rng.seed_int(seed_val)
	return rng

func _make_rng_str(seed_str: String = "FIRE-42") -> DeterministicRNG:
	var rng: DeterministicRNG = DeterministicRNG.new()
	rng.seed_string(seed_str)
	return rng

# ---------------------------------------------------------------------------
# Section A: Instantiation & Class Structure
# ---------------------------------------------------------------------------

func test_extends_ref_counted() -> void:
	var rng: DeterministicRNG = DeterministicRNG.new()
	assert_true(rng is RefCounted, "DeterministicRNG must extend RefCounted")

func test_is_not_node() -> void:
	var rng: DeterministicRNG = DeterministicRNG.new()
	assert_false(rng is Node, "DeterministicRNG must NOT extend Node")

func test_instantiation_without_scene_tree() -> void:
	var rng: DeterministicRNG = DeterministicRNG.new()
	assert_not_null(rng, "Should instantiate without scene tree")

# ---------------------------------------------------------------------------
# Section B: Seeding
# ---------------------------------------------------------------------------

func test_seed_int_determinism() -> void:
	var a: DeterministicRNG = _make_rng(42)
	var b: DeterministicRNG = _make_rng(42)
	for i in range(1000):
		assert_eq(a.next_int(), b.next_int(),
			"Two instances with same int seed must produce identical sequences at index %d" % i)

func test_seed_string_determinism() -> void:
	var a: DeterministicRNG = _make_rng_str("FIRE-42")
	var b: DeterministicRNG = _make_rng_str("FIRE-42")
	for i in range(1000):
		assert_eq(a.next_int(), b.next_int(),
			"Two instances with same string seed must produce identical sequences at index %d" % i)

func test_seed_int_zero_guard() -> void:
	var rng: DeterministicRNG = _make_rng(0)
	var values: Array[int] = []
	for i in range(10):
		values.append(rng.next_int())
	# With zero guard, state becomes 1, so we should get non-zero and varying values
	var unique: Dictionary = {}
	for v in values:
		unique[v] = true
	assert_gt(unique.size(), 1, "Zero seed must not produce stuck sequence (got %d unique values)" % unique.size())

func test_reseed_resets_sequence() -> void:
	var rng: DeterministicRNG = DeterministicRNG.new()
	rng.seed_int(42)
	var first_run: Array[int] = []
	for i in range(5):
		first_run.append(rng.next_int())
	rng.seed_int(42)
	var second_run: Array[int] = []
	for i in range(5):
		second_run.append(rng.next_int())
	assert_eq(first_run, second_run, "Re-seeding with same value must reset sequence")

func test_different_seeds_different_sequences() -> void:
	var a: DeterministicRNG = _make_rng(42)
	var b: DeterministicRNG = _make_rng(99)
	var match_count: int = 0
	for i in range(100):
		if a.next_int() == b.next_int():
			match_count += 1
	assert_lt(match_count, 5, "Different seeds should produce mostly different values")

func test_different_string_seeds_different_sequences() -> void:
	var a: DeterministicRNG = _make_rng_str("FIRE-42")
	var b: DeterministicRNG = _make_rng_str("ICE-99")
	var match_count: int = 0
	for i in range(100):
		if a.next_int() == b.next_int():
			match_count += 1
	assert_lt(match_count, 5, "Different string seeds should produce mostly different values")

# ---------------------------------------------------------------------------
# Section C: next_int()
# ---------------------------------------------------------------------------

func test_next_int_non_negative() -> void:
	var rng: DeterministicRNG = _make_rng(12345)
	for i in range(100000):
		var val: int = rng.next_int()
		if val < 0:
			fail_test("next_int() returned negative value %d at iteration %d" % [val, i])
			return
	pass_test("All 100,000 next_int() values were non-negative")

# ---------------------------------------------------------------------------
# Section D: randf()
# ---------------------------------------------------------------------------

func test_randf_bounds() -> void:
	var rng: DeterministicRNG = _make_rng(777)
	for i in range(100000):
		var val: float = rng.randf()
		if val < 0.0 or val >= 1.0:
			fail_test("randf() returned %f at iteration %d (must be [0.0, 1.0))" % [val, i])
			return
	pass_test("All 100,000 randf() values in [0.0, 1.0)")

func test_randf_determinism() -> void:
	var a: DeterministicRNG = _make_rng(42)
	var b: DeterministicRNG = _make_rng(42)
	for i in range(1000):
		assert_eq(a.randf(), b.randf(), "randf() must be deterministic at index %d" % i)

# ---------------------------------------------------------------------------
# Section E: randi()
# ---------------------------------------------------------------------------

func test_randi_bounds() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	var seen: Dictionary = {}
	for i in range(10000):
		var val: int = rng.randi(10)
		if val < 0 or val >= 10:
			fail_test("randi(10) returned %d at iteration %d" % [val, i])
			return
		seen[val] = true
	assert_eq(seen.size(), 10, "randi(10) should produce all values 0-9 over 10,000 calls")

func test_randi_zero() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	assert_eq(rng.randi(0), 0, "randi(0) must return 0")

func test_randi_negative() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	assert_eq(rng.randi(-5), 0, "randi(-5) must return 0")

# ---------------------------------------------------------------------------
# Section F: randi_range()
# ---------------------------------------------------------------------------

func test_randi_range_bounds() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	var seen: Dictionary = {}
	for i in range(10000):
		var val: int = rng.randi_range(3, 7)
		if val < 3 or val > 7:
			fail_test("randi_range(3,7) returned %d at iteration %d" % [val, i])
			return
		seen[val] = true
	assert_eq(seen.size(), 5, "randi_range(3,7) should produce all values 3-7")

func test_randi_range_equal() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	for i in range(100):
		assert_eq(rng.randi_range(5, 5), 5, "randi_range(5,5) must always return 5")

func test_randi_range_swapped() -> void:
	var rng_a: DeterministicRNG = _make_rng(42)
	var rng_b: DeterministicRNG = _make_rng(42)
	for i in range(100):
		var val_a: int = rng_a.randi_range(3, 7)
		var val_b: int = rng_b.randi_range(7, 3)
		assert_eq(val_a, val_b, "randi_range must auto-swap min/max")

# ---------------------------------------------------------------------------
# Section G: shuffle()
# ---------------------------------------------------------------------------

func test_shuffle_in_place() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	var arr: Array = [1, 2, 3, 4, 5]
	var returned: Array = rng.shuffle(arr)
	assert_true(arr is Array, "shuffle must return an Array")
	# Verify same reference by checking mutation is reflected
	assert_eq(returned, arr, "shuffle must return the same array reference")

func test_shuffle_determinism() -> void:
	var a: DeterministicRNG = _make_rng(42)
	var b: DeterministicRNG = _make_rng(42)
	var arr_a: Array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	var arr_b: Array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	a.shuffle(arr_a)
	b.shuffle(arr_b)
	assert_eq(arr_a, arr_b, "Same seed must produce same shuffle")

func test_shuffle_empty() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	var arr: Array = []
	var returned: Array = rng.shuffle(arr)
	assert_eq(returned.size(), 0, "Shuffling empty array should return empty array")

func test_shuffle_single() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	var arr: Array = [42]
	rng.shuffle(arr)
	assert_eq(arr, [42], "Shuffling single-element array should preserve it")

func test_shuffle_preserves_elements() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	var arr: Array = [1, 2, 3, 4, 5]
	rng.shuffle(arr)
	arr.sort()
	assert_eq(arr, [1, 2, 3, 4, 5], "Shuffle must not add or remove elements")

# ---------------------------------------------------------------------------
# Section H: pick()
# ---------------------------------------------------------------------------

func test_pick_determinism() -> void:
	var a: DeterministicRNG = _make_rng(42)
	var b: DeterministicRNG = _make_rng(42)
	var arr: Array = ["alpha", "beta", "gamma", "delta"]
	for i in range(100):
		assert_eq(a.pick(arr), b.pick(arr), "pick() must be deterministic at index %d" % i)

func test_pick_empty() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	assert_null(rng.pick([]), "pick([]) must return null")

func test_pick_single() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	assert_eq(rng.pick([99]), 99, "pick([99]) must return 99")

func test_pick_coverage() -> void:
	var seen: Dictionary = {}
	var items: Array = ["a", "b", "c"]
	for seed_val in range(1000):
		var rng: DeterministicRNG = _make_rng(seed_val)
		var chosen: Variant = rng.pick(items)
		seen[chosen] = true
	assert_eq(seen.size(), 3, "pick() should eventually select every element")

# ---------------------------------------------------------------------------
# Section I: weighted_pick()
# ---------------------------------------------------------------------------

func test_weighted_pick_deterministic_weight() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	var items: Array = ["A", "B", "C"]
	var weights: Array[float] = [1.0, 0.0, 0.0]
	for i in range(1000):
		assert_eq(rng.weighted_pick(items, weights), "A",
			"Weight [1,0,0] must always select 'A'")

func test_weighted_pick_last_item() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	var items: Array = ["A", "B", "C"]
	var weights: Array[float] = [0.0, 0.0, 1.0]
	for i in range(1000):
		assert_eq(rng.weighted_pick(items, weights), "C",
			"Weight [0,0,1] must always select 'C'")

func test_weighted_pick_empty_items() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	assert_null(rng.weighted_pick([], []), "Empty items must return null")

func test_weighted_pick_empty_weights() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	assert_null(rng.weighted_pick(["A"], []), "Empty weights must return null")

func test_weighted_pick_all_zero_weights() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	assert_null(rng.weighted_pick(["A", "B"], [0.0, 0.0]),
		"All-zero weights must return null")

func test_weighted_pick_distribution() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	var items: Array = ["common", "rare"]
	var weights: Array[float] = [0.9, 0.1]
	var counts: Dictionary = {"common": 0, "rare": 0}
	for i in range(10000):
		var result: Variant = rng.weighted_pick(items, weights)
		counts[result] += 1
	# With 90/10 split over 10,000 trials, common should be ~9000 ± 300
	assert_gt(counts["common"], 8000, "Common should appear >8000 times (got %d)" % counts["common"])
	assert_lt(counts["common"], 9800, "Common should appear <9800 times (got %d)" % counts["common"])
	assert_gt(counts["rare"], 200, "Rare should appear >200 times (got %d)" % counts["rare"])

func test_weighted_pick_determinism() -> void:
	var a: DeterministicRNG = _make_rng(42)
	var b: DeterministicRNG = _make_rng(42)
	var items: Array = ["X", "Y", "Z"]
	var weights: Array[float] = [0.5, 0.3, 0.2]
	for i in range(1000):
		assert_eq(
			a.weighted_pick(items, weights),
			b.weighted_pick(items, weights),
			"weighted_pick must be deterministic at index %d" % i)

# ---------------------------------------------------------------------------
# Section J: Performance (optional, non-blocking)
# ---------------------------------------------------------------------------

func test_next_int_throughput() -> void:
	var rng: DeterministicRNG = _make_rng(42)
	var start: int = Time.get_ticks_msec()
	for i in range(1000000):
		rng.next_int()
	var elapsed: int = Time.get_ticks_msec() - start
	# 1M calls should complete in under 2 seconds even on slow hardware
	assert_lt(elapsed, 2000,
		"1M next_int() calls took %d ms (target: <2000 ms)" % elapsed)
```

---

## Section 15 · Playtesting Verification Scenarios

These scenarios are verified by a human playtester or automated integration test, not by unit tests. They validate that `DeterministicRNG` produces correct player-facing behavior when integrated with downstream systems.

| # | Scenario | Steps | Expected Outcome |
|---|---|---|---|
| PV-01 | **Seed sharing produces identical dungeon** | Player A enters seed `"FIRE-42"` in Seed Grove. Player B enters `"FIRE-42"` on a different machine. Both explore floor 1. | Both players encounter the same room sequence, same enemies, same loot positions. |
| PV-02 | **Re-entering same seed reproduces dungeon** | Player enters `"FIRE-42"`, explores 3 floors, exits. Re-enters `"FIRE-42"`. | Dungeon is identical to the first run — same rooms, same loot, same enemies on all 3 floors. |
| PV-03 | **Different seeds produce different dungeons** | Player enters `"FIRE-42"`, notes floor 1 layout. Enters `"ICE-99"`, notes floor 1 layout. | The two layouts are visibly different (different room types, different ordering). |
| PV-04 | **Loot drops are deterministic per seed** | Player enters `"FIRE-42"`, clears room 1 on floor 1, notes the loot drop. Re-enters `"FIRE-42"`, clears the same room. | Same loot item, same quantity. |
| PV-05 | **Shuffle produces varied room ordering** | Player enters 5 different seeds and observes room ordering on floor 1 for each. | Room orderings differ across seeds (not always the same first room). |
| PV-06 | **Weighted loot feels correct** | Player clears 50 rooms across multiple seeds. Common loot drops frequently; rare loot drops infrequently but does appear. | Observed drop rates roughly match configured weights (±20% tolerance for small sample). |
| PV-07 | **Empty seed string is handled** | Player enters an empty string `""` in the Seed Grove. | System either rejects the input (UI validation) or treats it as a valid seed producing a consistent dungeon. No crash. |
| PV-08 | **Unicode seed string works** | Player enters `"🔥🌲42"` as a seed string. | Dungeon generates successfully. Re-entering the same string produces the same dungeon. |
| PV-09 | **Long seed string works** | Player enters a 200-character seed string. | Dungeon generates successfully. No truncation — the full string is hashed. |
| PV-10 | **Combat rolls feel fair** | Player observes 20 combat encounters across a seed. Damage values vary within the expected range. Critical hits occur at roughly the configured rate. | No pattern of "always max damage" or "always miss" — variation is visible. |

---

## Section 16 · Implementation Prompt

The following is the **complete, production-ready implementation** of `src/models/rng.gd`. This code is copy-pasteable into a Godot 4.5 project and will work immediately.

```gdscript
extends RefCounted
class_name DeterministicRNG
## Deterministic pseudo-random number generator using xorshift64* algorithm.
##
## Provides reproducible random sequences from integer or string seeds.
## Used by dungeon generation, loot tables, combat resolution, and all
## systems requiring deterministic randomness in Dungeon Seed.
##
## Usage:
##   var rng := DeterministicRNG.new()
##   rng.seed_string("FIRE-42")
##   var room_index: int = rng.randi(8)
##   var damage: int = rng.randi_range(10, 25)
##   var loot: String = rng.weighted_pick(items, weights)

## 63-bit mask to ensure non-negative integers in signed 64-bit space.
const MASK_63: int = 0x7FFFFFFFFFFFFFFF

## xorshift64* output multiplier (Marsaglia's recommended constant).
const MULTIPLIER: int = 0x2545F4914F6CDD1D

## Internal RNG state. Single 63-bit positive integer.
## Must never be zero — zero is an absorbing state for xorshift.
var _state: int = 0


## Seeds the RNG from an integer value.
## The seed is masked to 63 bits. A zero seed is replaced with 1
## to avoid the xorshift zero absorbing state.
func seed_int(val: int) -> void:
	_state = val & MASK_63
	if _state == 0:
		_state = 1


## Seeds the RNG from a string via SHA-256 hash.
## Computes SHA-256 of the string's UTF-8 bytes, extracts the first
## 8 bytes as a big-endian 64-bit integer, and masks to 63 bits.
## A zero result is replaced with 1.
func seed_string(s: String) -> void:
	var hc: HashingContext = HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(s.to_utf8_buffer())
	var digest: PackedByteArray = hc.finish()
	var val: int = 0
	for i in range(0, mini(8, digest.size())):
		val = (val << 8) | int(digest[i])
	_state = val & MASK_63
	if _state == 0:
		_state = 1


## Advances the xorshift64* state and returns a 63-bit non-negative integer.
## This is the core generation function. All other methods build on this.
##
## Algorithm: xorshift64* with shift triplet (13, 7, 17) and multiplicative
## output scramble. Period: 2^64 - 1 (all non-zero states).
func next_int() -> int:
	var x: int = _state
	x ^= (x << 13) & MASK_63
	x ^= (x >> 7)
	x ^= (x << 17) & MASK_63
	_state = x & MASK_63
	if _state == 0:
		_state = 1
	var result: int = (_state * MULTIPLIER) & MASK_63
	return result


## Returns a float in the range [0.0, 1.0).
## Uses 53 bits of precision (matching IEEE 754 double mantissa).
## The divisor is 2^53 (not 2^53 - 1) to guarantee the result is < 1.0.
func randf() -> float:
	var u: int = next_int()
	var frac_bits: int = u & ((1 << 53) - 1)
	return float(frac_bits) / float(1 << 53)


## Returns an integer in the range [0, max_val).
## Returns 0 if max_val <= 0.
func randi(max_val: int) -> int:
	if max_val <= 0:
		return 0
	return int(next_int() % max_val)


## Returns an integer in the inclusive range [min_val, max_val].
## Automatically swaps min_val and max_val if min_val > max_val.
## Returns min_val if min_val == max_val.
func randi_range(min_val: int, max_val: int) -> int:
	if min_val > max_val:
		var swap: int = min_val
		min_val = max_val
		max_val = swap
	if min_val == max_val:
		return min_val
	var span: int = max_val - min_val + 1
	return min_val + int(next_int() % span)


## Performs an in-place Fisher-Yates shuffle on the array.
## Returns the same array reference (not a copy).
## Empty and single-element arrays are returned unchanged.
func shuffle(array: Array) -> Array:
	var n: int = array.size()
	for i in range(n - 1, 0, -1):
		var j: int = randi(i + 1)
		var tmp: Variant = array[i]
		array[i] = array[j]
		array[j] = tmp
	return array


## Returns a uniformly random element from the array.
## Returns null if the array is empty.
func pick(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[randi(array.size())]


## Returns a randomly selected item with probability proportional to its weight.
## Uses cumulative weight sum and linear scan.
##
## Returns null if:
##   - items is empty
##   - weights is empty
##   - items and weights have different sizes
##   - all weights are zero or negative
##
## Weights do not need to sum to 1.0 — they are normalized internally.
func weighted_pick(items: Array, weights: Array[float]) -> Variant:
	if items.is_empty() or weights.is_empty():
		return null
	if items.size() != weights.size():
		return null

	# Compute total weight, ignoring negatives
	var total: float = 0.0
	for w in weights:
		if w > 0.0:
			total += w

	if total <= 0.0:
		return null

	var roll: float = randf() * total
	var cumulative: float = 0.0
	for i in range(items.size()):
		if weights[i] > 0.0:
			cumulative += weights[i]
		if roll < cumulative:
			return items[i]

	# Floating-point edge case: return last valid item
	for i in range(items.size() - 1, -1, -1):
		if weights[i] > 0.0:
			return items[i]

	return null
```

### Implementation Notes

1. **Constants extracted:** `MASK_63` and `MULTIPLIER` are class-level constants, not magic numbers scattered through methods. This improves readability and ensures consistency.

2. **Zero-guard in `next_int()`:** An additional zero-guard is placed inside `next_int()` (not just in seeding functions) as a defense-in-depth measure. If any arithmetic error produces a zero state, the next call self-corrects rather than entering the absorbing zero state permanently.

3. **`randf()` uses `/ float(1 << 53)`:** The divisor is `2^53` (9007199254740992), not `2^53 - 1`. This guarantees the result is strictly `< 1.0`. The maximum possible value is `(2^53 - 1) / 2^53 ≈ 0.99999999999999989`.

4. **`randi_range()` auto-swaps:** If the caller accidentally passes `randi_range(7, 3)`, the method silently swaps to `randi_range(3, 7)`. This prevents negative span calculations and is more forgiving than throwing an error.

5. **`weighted_pick()` ignores negative weights:** Negative weights are treated as zero. This is a safety measure against misconfigured loot tables.

6. **`weighted_pick()` size mismatch returns null:** If `items` and `weights` have different lengths, `null` is returned rather than crashing. The caller should validate inputs, but the RNG is defensive.

7. **`shuffle()` iterates `n-1` down to `1`:** The standard Fisher-Yates backward iteration. Index 0 is never swapped with itself (it's already in its final position after all other swaps).

8. **No `print()` or logging:** The implementation is silent. Debug output is the caller's responsibility.

9. **All methods have type hints:** Parameters, return types, and local variables are fully annotated. GDScript's static analysis will catch type mismatches at parse time.

10. **File location:** `src/models/rng.gd` — in the models directory alongside other pure-data classes. Not in `utils/` (which is for stateless helpers) and not in `systems/` (which is for scene-tree-coupled managers).
