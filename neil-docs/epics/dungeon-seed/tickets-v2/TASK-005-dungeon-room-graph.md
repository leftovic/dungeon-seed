# TASK-005 · Dungeon Room Graph Data Model

---

## Section 1 · Header

| Field               | Value                                                                 |
|---------------------|-----------------------------------------------------------------------|
| **Task ID**         | TASK-005                                                              |
| **Title**           | Dungeon Room Graph Data Model                                         |
| **Priority**        | P1 — Critical                                                         |
| **Tier**            | T1 — Core Data Model                                                  |
| **Complexity**      | 5 points (Moderate)                                                   |
| **Phase**           | Foundation                                                            |
| **Wave**            | 2                                                                     |
| **Stream**          | 🔴 MCH (Mechanics) — Primary                                         |
| **Cross-Stream**    | ⚪ TCH (serialization, graph algorithms), 🔵 VIS (room layout positions), 🟡 WLD (dungeon structure) |
| **GDD Reference**   | §4.2 Dungeon Generation, §4.2.1 Room Types, §4.2.2 Dungeon Flow      |
| **Milestone**       | M2 — Core Systems                                                     |
| **Dependencies**    | TASK-003 (Enums & Constants — `Enums.RoomType`, `Enums.Element`, `Enums.Currency`, `Enums.SeedRarity`, `Enums.SeedPhase`, `GameConfig.ROOM_DIFFICULTY_SCALE`) |
| **Dependents**      | TASK-010 (Procedural Dungeon Generator), TASK-015 (Expedition Resolver), TASK-018 (Dungeon Map UI), TASK-022 (Save/Load System) |
| **Critical Path**   | ✅ YES — blocks dungeon generation, expedition resolution, and map rendering |
| **Estimated Hours** | 10–14 hours                                                           |
| **Engine**          | Godot 4.6, GDScript                                                   |
| **Output Files**    | `src/models/dungeon_data.gd`, `src/models/room_data.gd`, `tests/models/test_dungeon_data.gd`, `tests/models/test_room_data.gd` |

---

## Section 2 · Description

### 2.1 What

TASK-005 introduces two pure-data RefCounted classes — **DungeonData** and **RoomData** — that together model a procedurally generated dungeon as a connected, undirected graph. `DungeonData` is the single authoritative representation of a dungeon instance from the moment the Procedural Dungeon Generator (TASK-010) produces it, through the Expedition Resolver (TASK-015) mutating `is_cleared` flags, to the Dungeon Map UI (TASK-018) rendering it, to the Save/Load System (TASK-022) persisting it.

The graph is stored as an **adjacency-edge list**: `rooms: Array[RoomData]` holds every room node indexed by position, and `edges: Array[Vector2i]` records undirected connections as `(room_index_a, room_index_b)` pairs. This representation was chosen over an adjacency-matrix or adjacency-list-of-arrays because it is compact, trivially serialisable, and allows O(E) traversal which is acceptable for dungeons capped at 25 rooms.

### 2.2 Why

The existing prototype in `src/gdscript/dungeon/dungeon_generator.gd` returns a flat `Dictionary` with loosely-typed room arrays. This has three critical problems:

1. **No type safety** — callers cast at runtime, producing silent failures.
2. **No graph operations** — adjacency, pathfinding, and reachability are reimplemented ad-hoc in every consumer.
3. **No serialization contract** — save/load is fragile and version-locked.

A proper typed model eliminates all three problems and gives every downstream system a single, validated data contract to code against.

### 2.3 Player Experience Impact

Players never interact with `DungeonData` directly, but every player-facing dungeon feature depends on it:

- **Dungeon Map Screen** reads `rooms`, `edges`, `entry_room_index`, and `boss_room_index` to render the node-and-edge map the player navigates.
- **Expedition Resolution** iterates `get_adjacent()` to determine legal moves, reads `type` and `difficulty` to resolve encounters, and writes `is_cleared` as rooms are completed.
- **Loot Distribution** reads `loot_bias` per room to weight currency drops toward the room's designated reward type.
- **Completion Tracking** calls `is_fully_cleared()` to award dungeon-completion bonuses.
- **Idle Replay** re-instantiates dungeons from serialized `to_dict()` payloads for offline progress resolution.

A bug in this model propagates to every dungeon interaction the player has. Correctness here is non-negotiable.

### 2.4 Economy Impact

`loot_bias` on each `RoomData` steers the reward distribution within a dungeon run. If room bias is wrong:

- Players farming a Treasure Room expecting Gold may receive Dust instead.
- Bosses may not grant their intended premium-currency bonus.
- Economy sinks tied to dungeon completion milestones may trigger at incorrect rates.

The model itself does not compute loot — that is the Expedition Resolver's job — but it carries the bias data that the resolver reads. Incorrect serialization or default values here silently corrupt the economy.

### 2.5 Development Cost

This is a moderate-complexity data model task. The code volume is modest (~300 lines across two files), but the design decisions are load-bearing: every downstream system couples to the API surface defined here. The investment is:

- **Design** (2–3 hours): API surface, edge encoding, serialization format.
- **Implementation** (3–4 hours): Two classes, graph operations, BFS pathfinding.
- **Testing** (3–4 hours): Connectivity validation, round-trip serialization, edge cases.
- **Documentation** (1–2 hours): Designer's manual, inline docs.

### 2.6 Technical Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        DungeonData                           │
│  (class_name: DungeonData, extends: RefCounted)              │
├──────────────────────────────────────────────────────────────┤
│  seed_id        : String                                     │
│  rooms          : Array[RoomData]                            │
│  edges          : Array[Vector2i]                            │
│  entry_room_index : int                                      │
│  boss_room_index  : int                                      │
│  element        : Enums.Element                              │
│  difficulty     : int                                        │
├──────────────────────────────────────────────────────────────┤
│  + get_adjacent(room_index: int) -> Array[int]               │
│  + get_path_to_boss() -> Array[int]                          │
│  + get_uncleared_rooms() -> Array[int]                       │
│  + is_fully_cleared() -> bool                                │
│  + get_room(index: int) -> RoomData                          │
│  + get_room_count() -> int                                   │
│  + get_edge_count() -> int                                   │
│  + has_boss_room() -> bool                                   │
│  + validate() -> bool                                        │
│  + to_dict() -> Dictionary                                   │
│  + static from_dict(data: Dictionary) -> DungeonData         │
└──────────────────────────────────────────────────────────────┘
           │ contains 1..*
           ▼
┌──────────────────────────────────────────────────────────────┐
│                         RoomData                             │
│  (class_name: RoomData, extends: RefCounted)                 │
├──────────────────────────────────────────────────────────────┤
│  index          : int                                        │
│  type           : Enums.RoomType                             │
│  position       : Vector2                                    │
│  size           : Vector2                                    │
│  difficulty     : int                                        │
│  loot_bias      : Enums.Currency                             │
│  is_cleared     : bool                                       │
│  metadata       : Dictionary                                 │
├──────────────────────────────────────────────────────────────┤
│  + to_dict() -> Dictionary                                   │
│  + static from_dict(data: Dictionary) -> RoomData            │
│  + is_combat() -> bool                                       │
│  + is_boss() -> bool                                         │
│  + is_rest() -> bool                                         │
└──────────────────────────────────────────────────────────────┘
```

### 2.7 Graph Encoding Detail

Edges are stored as `Array[Vector2i]` where each `Vector2i(a, b)` represents an undirected connection between `rooms[a]` and `rooms[b]`. Invariants:

- `a < b` for every edge (canonical ordering prevents duplicates).
- `a >= 0` and `b < rooms.size()` (indices are valid).
- No self-loops: `a != b`.
- No duplicate edges.

This encoding is chosen because:

1. `Vector2i` is a Godot built-in — no custom class needed.
2. Serialization to JSON is trivial (`[a, b]` pairs).
3. Edge count is explicit (`edges.size()`).
4. Adjacency lookup is O(E) which is acceptable for E ≤ 40 in a 25-room dungeon.

### 2.8 System Interaction Map

```
TASK-003 (Enums)          TASK-005 (This Task)         TASK-010 (Generator)
┌────────────┐            ┌──────────────────┐         ┌──────────────────┐
│ RoomType   │───────────▶│   RoomData       │◀────────│ Builds rooms     │
│ Element    │───────────▶│   DungeonData    │◀────────│ Connects edges   │
│ Currency   │───────────▶│                  │         │ Sets entry/boss  │
│ SeedRarity │            └────────┬─────────┘         └──────────────────┘
│ SeedPhase  │                     │
└────────────┘                     │
                                   ▼
                    ┌──────────────────────────────┐
                    │  TASK-015 (Expedition)        │
                    │  - Reads rooms, edges         │
                    │  - Calls get_adjacent()       │
                    │  - Writes is_cleared          │
                    │  - Calls is_fully_cleared()   │
                    └──────────────┬───────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────────┐
                    │  TASK-018 (Dungeon Map UI)    │
                    │  - Reads position, size       │
                    │  - Reads edges for lines      │
                    │  - Highlights cleared rooms   │
                    │  - Shows boss room marker     │
                    └──────────────────────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────────┐
                    │  TASK-022 (Save/Load)         │
                    │  - Calls to_dict()            │
                    │  - Calls from_dict()          │
                    │  - Stores in save file        │
                    └──────────────────────────────┘
```

### 2.9 Constraints and Design Decisions

| Decision | Rationale |
|----------|-----------|
| RefCounted base, not Resource | Data is transient per-run, not saved as .tres. RefCounted avoids filesystem coupling. |
| Edge list, not adjacency matrix | Sparse graphs (E ≈ 1.5×V) make edge lists more memory-efficient than V×V matrices. |
| `Vector2i` for edges | Native Godot type, serializes cleanly, enforces integer indices. |
| Canonical edge ordering `a < b` | Eliminates duplicate edges without a Set data structure. |
| `position: Vector2` is abstract | Not pixel coordinates. Layout-to-pixel mapping is the UI's responsibility. |
| `metadata: Dictionary` on RoomData | Extensibility escape hatch for room-specific data (trap type, puzzle ID, enemy wave config) without bloating the base class. |
| `difficulty: int` on both classes | Dungeon-level difficulty is the baseline; per-room difficulty allows local scaling (boss rooms harder, rest rooms easier). |
| `boss_room_index: int` defaults to -1 | Not all dungeons have bosses (early-game, tutorial). -1 sentinel avoids nullable types. |
| BFS for `get_path_to_boss()` | BFS guarantees shortest path in an unweighted graph. Dijkstra is unnecessary. |
| `validate()` as explicit method | Called after construction and after deserialization. Fail-fast on corrupted data. |

---

## Section 3 · Use Cases

### UC-01: Procedural Dungeon Generator Builds a Dungeon

**Actor**: TASK-010 Procedural Dungeon Generator  
**Precondition**: A `SeedData` instance exists with valid rarity, element, and phase.  
**Flow**:

1. Generator reads seed parameters (rarity → room count range, element → theme, phase → unlocked room types).
2. Generator creates an empty `DungeonData` instance and sets `seed_id`, `element`, and `difficulty`.
3. Generator instantiates `RoomData` objects, assigning `index`, `type`, `position`, `size`, `difficulty`, and `loot_bias` per the generation algorithm.
4. Generator appends each `RoomData` to `DungeonData.rooms`.
5. Generator computes connectivity and appends `Vector2i` edge pairs to `DungeonData.edges`, ensuring canonical ordering (`a < b`).
6. Generator designates `entry_room_index` (always index 0 by convention) and `boss_room_index` (the farthest room from entry, or -1 for boss-less dungeons).
7. Generator calls `DungeonData.validate()` to confirm the graph is connected, all indices are valid, and the boss room is reachable.
8. Generator returns the validated `DungeonData` to the caller.

**Postcondition**: A fully-formed, validated `DungeonData` is ready for expedition resolution.

### UC-02: Expedition Resolver Processes a Dungeon Run

**Actor**: TASK-015 Expedition Resolver  
**Precondition**: A validated `DungeonData` exists. A player team is assigned.  
**Flow**:

1. Resolver reads `entry_room_index` and begins at that room.
2. Resolver calls `get_adjacent(current_room_index)` to determine legal next moves.
3. For each chosen room, resolver reads `rooms[i].type` and `rooms[i].difficulty` to determine encounter parameters.
4. Resolver reads `rooms[i].loot_bias` to weight reward currency distribution.
5. After the encounter resolves, resolver sets `rooms[i].is_cleared = true`.
6. Resolver checks `is_fully_cleared()` — if true, awards dungeon completion bonus.
7. If the player reaches the boss room (index == `boss_room_index`), resolver triggers the boss encounter with elevated difficulty and premium loot.
8. Resolver calls `get_path_to_boss()` to display remaining distance on the map HUD.

**Postcondition**: One or more rooms are cleared. Dungeon state is mutated in-place. If all rooms cleared, completion bonus awarded.

### UC-03: Save/Load System Persists and Restores Dungeon State

**Actor**: TASK-022 Save/Load System  
**Precondition**: A `DungeonData` with partial progress exists in memory.  
**Flow**:

1. Save system calls `dungeon_data.to_dict()` to obtain a plain Dictionary representation.
2. Save system writes the Dictionary into the player's save file as JSON.
3. On load, save system reads the JSON and parses it into a Dictionary.
4. Save system calls `DungeonData.from_dict(data)` to reconstruct the full object graph.
5. Save system calls `validate()` on the restored `DungeonData` to detect corruption.
6. If validation fails, save system logs the error and discards the corrupted dungeon (fail-safe).
7. If validation passes, the `DungeonData` is handed back to the game state manager with all `is_cleared` flags intact.

**Postcondition**: Player resumes the dungeon exactly where they left off, with all room-cleared state preserved.

### UC-04: Dungeon Map UI Renders the Graph

**Actor**: TASK-018 Dungeon Map UI  
**Precondition**: A `DungeonData` exists for the active dungeon.  
**Flow**:

1. UI reads `rooms` array and maps each `RoomData.position` (abstract coords) to screen-space pixel coordinates via a layout transform.
2. UI reads `RoomData.size` to scale room node visual size.
3. UI reads `edges` array and draws connection lines between room nodes.
4. UI highlights `entry_room_index` with a distinct icon (green flag).
5. UI highlights `boss_room_index` with a skull icon (if != -1).
6. UI reads `is_cleared` per room to toggle between "explored" (dimmed) and "unexplored" (bright) visual states.
7. UI calls `get_adjacent(selected_room)` to highlight legal move targets when the player taps a room.
8. UI calls `get_path_to_boss()` to render a suggested path overlay.

**Postcondition**: The player sees an accurate, interactive dungeon map reflecting current progress.

---

## Section 4 · Glossary

| # | Term | Definition |
|---|------|------------|
| 1 | **DungeonData** | The top-level data model representing a complete dungeon instance as a connected graph of rooms and edges. |
| 2 | **RoomData** | A single node in the dungeon graph, carrying type, position, difficulty, loot bias, and clearance state. |
| 3 | **Edge** | An undirected connection between two rooms, stored as a `Vector2i(a, b)` where `a < b`. |
| 4 | **Adjacency** | The set of rooms directly connected to a given room by edges. |
| 5 | **Entry Room** | The room where expedition teams begin. Always a valid index into the rooms array. |
| 6 | **Boss Room** | The final high-difficulty room in a dungeon. Index is -1 if the dungeon has no boss. |
| 7 | **Canonical Edge Ordering** | The invariant that for every edge `Vector2i(a, b)`, `a < b`. Prevents duplicate edges. |
| 8 | **Room Type** | An `Enums.RoomType` value: COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS. Determines encounter logic. |
| 9 | **Loot Bias** | An `Enums.Currency` value on each room that weights which currency type drops are favoured. |
| 10 | **Difficulty Rating** | An integer on both `DungeonData` (global baseline) and `RoomData` (per-room scaling). Higher = harder enemies/traps. |
| 11 | **Graph Connectivity** | The property that every room in the dungeon is reachable from every other room via edges. Required invariant. |
| 12 | **BFS (Breadth-First Search)** | The algorithm used by `get_path_to_boss()` to find the shortest path in an unweighted graph. |
| 13 | **Abstract Position** | The `Vector2` coordinates on `RoomData` representing spatial layout in an arbitrary coordinate space, not pixel coordinates. |
| 14 | **Metadata Dictionary** | An extensible `Dictionary` on `RoomData` for room-specific data (e.g., trap type ID, puzzle configuration, enemy wave setup). |
| 15 | **Serialization Round-Trip** | The property that `from_dict(to_dict(x))` produces an object semantically equal to `x`. |
| 16 | **Sentinel Value** | The value -1 used for `boss_room_index` when no boss room exists. Avoids nullable int types. |
| 17 | **Seed ID** | The string identifier of the seed that produced this dungeon. Links dungeon back to its source `SeedData`. |
| 18 | **Expedition** | A player-initiated run through a dungeon, resolving rooms sequentially. Consumes `DungeonData`. |
| 19 | **RefCounted** | Godot base class for reference-counted objects. Used for pure data models that don't need Node lifecycle. |
| 20 | **Validate** | An explicit integrity check ensuring all graph invariants hold (connectivity, index bounds, canonical edges, entry/boss validity). |

---

## Section 5 · Out of Scope

| # | Exclusion | Rationale |
|---|-----------|-----------|
| 1 | **Procedural generation algorithm** | TASK-010 owns generation logic. This task only defines the data structure that generation populates. |
| 2 | **Encounter resolution logic** | TASK-015 (Expedition Resolver) reads DungeonData but combat/trap/puzzle mechanics are its responsibility. |
| 3 | **Dungeon Map UI rendering** | TASK-018 converts abstract positions to pixels. This task provides the data, not the visuals. |
| 4 | **Save file format or I/O** | TASK-022 handles file read/write. This task provides `to_dict()` / `from_dict()` for the payload only. |
| 5 | **Loot table definitions** | `loot_bias` indicates which currency is favoured; actual drop tables and rates belong to the economy system. |
| 6 | **Enemy spawning and AI** | Room `difficulty` informs enemy selection, but spawning logic is separate. |
| 7 | **Weighted or directed edges** | All edges are undirected and unweighted. One-way doors or variable-cost corridors are not in the GDD. |
| 8 | **Dynamic graph mutation** | Rooms and edges are fixed after generation. No runtime addition/removal of rooms. `is_cleared` is the only mutable state. |
| 9 | **Multi-floor dungeons** | GDD §4.2 defines single-floor dungeons. Multi-floor is a future expansion. |
| 10 | **Room interior layout** | `size` is abstract dimensions for the map. Tile-level interior design is not part of this model. |
| 11 | **Multiplayer dungeon sharing** | Network serialization and sync are out of scope. `to_dict()` produces a local-only payload. |
| 12 | **Dungeon difficulty scaling at runtime** | `difficulty` is set at generation time and does not change during an expedition. |
| 13 | **Room visual theming** | Element-to-theme mapping for art assets is the Art Director's domain, not the data model. |

---

## Section 6 · Functional Requirements

### RoomData Class

| ID | Requirement |
|----|-------------|
| FR-001 | `RoomData` SHALL extend `RefCounted` and declare `class_name RoomData`. |
| FR-002 | `RoomData` SHALL expose property `index: int` initialized to `0`. |
| FR-003 | `RoomData` SHALL expose property `type: Enums.RoomType` initialized to `Enums.RoomType.COMBAT`. |
| FR-004 | `RoomData` SHALL expose property `position: Vector2` initialized to `Vector2.ZERO`. |
| FR-005 | `RoomData` SHALL expose property `size: Vector2` initialized to `Vector2(1.0, 1.0)`. |
| FR-006 | `RoomData` SHALL expose property `difficulty: int` initialized to `1`. |
| FR-007 | `RoomData` SHALL expose property `loot_bias: Enums.Currency` initialized to `Enums.Currency.GOLD`. |
| FR-008 | `RoomData` SHALL expose property `is_cleared: bool` initialized to `false`. |
| FR-009 | `RoomData` SHALL expose property `metadata: Dictionary` initialized to `{}`. |
| FR-010 | `RoomData.to_dict()` SHALL return a Dictionary containing all properties with enum values stored as integers. |
| FR-011 | `RoomData.from_dict(data: Dictionary)` SHALL be a static method returning a new `RoomData` with all properties restored from the Dictionary. |
| FR-012 | `RoomData.is_combat()` SHALL return `true` if `type == Enums.RoomType.COMBAT`. |
| FR-013 | `RoomData.is_boss()` SHALL return `true` if `type == Enums.RoomType.BOSS`. |
| FR-014 | `RoomData.is_rest()` SHALL return `true` if `type == Enums.RoomType.REST`. |

### DungeonData Class

| ID | Requirement |
|----|-------------|
| FR-015 | `DungeonData` SHALL extend `RefCounted` and declare `class_name DungeonData`. |
| FR-016 | `DungeonData` SHALL expose property `seed_id: String` initialized to `""`. |
| FR-017 | `DungeonData` SHALL expose property `rooms: Array[RoomData]` initialized to `[]`. |
| FR-018 | `DungeonData` SHALL expose property `edges: Array[Vector2i]` initialized to `[]`. |
| FR-019 | `DungeonData` SHALL expose property `entry_room_index: int` initialized to `0`. |
| FR-020 | `DungeonData` SHALL expose property `boss_room_index: int` initialized to `-1`. |
| FR-021 | `DungeonData` SHALL expose property `element: Enums.Element` initialized to `Enums.Element.NONE`. |
| FR-022 | `DungeonData` SHALL expose property `difficulty: int` initialized to `1`. |

### Graph Operations

| ID | Requirement |
|----|-------------|
| FR-023 | `get_adjacent(room_index: int) -> Array[int]` SHALL return all room indices directly connected to `room_index` via edges. |
| FR-024 | `get_adjacent()` SHALL return an empty array if `room_index` is out of bounds. |
| FR-025 | `get_path_to_boss() -> Array[int]` SHALL return the shortest path (BFS) from `entry_room_index` to `boss_room_index` as an ordered array of room indices including both endpoints. |
| FR-026 | `get_path_to_boss()` SHALL return an empty array if `boss_room_index == -1`. |
| FR-027 | `get_path_to_boss()` SHALL return an empty array if the boss room is unreachable (graph invariant violation). |
| FR-028 | `get_uncleared_rooms() -> Array[int]` SHALL return indices of all rooms where `is_cleared == false`. |
| FR-029 | `is_fully_cleared() -> bool` SHALL return `true` only when every room's `is_cleared` is `true`. |
| FR-030 | `get_room(index: int) -> RoomData` SHALL return the `RoomData` at the given index, or `null` if out of bounds. |
| FR-031 | `get_room_count() -> int` SHALL return `rooms.size()`. |
| FR-032 | `get_edge_count() -> int` SHALL return `edges.size()`. |
| FR-033 | `has_boss_room() -> bool` SHALL return `true` if `boss_room_index >= 0 and boss_room_index < rooms.size()`. |

### Validation

| ID | Requirement |
|----|-------------|
| FR-034 | `validate() -> bool` SHALL verify that `rooms.size() >= 1`. |
| FR-035 | `validate()` SHALL verify that `entry_room_index` is a valid index into `rooms`. |
| FR-036 | `validate()` SHALL verify that `boss_room_index` is either `-1` or a valid index into `rooms`. |
| FR-037 | `validate()` SHALL verify that all edges reference valid room indices. |
| FR-038 | `validate()` SHALL verify canonical edge ordering (`edge.x < edge.y` for all edges). |
| FR-039 | `validate()` SHALL verify no duplicate edges exist. |
| FR-040 | `validate()` SHALL verify no self-loops exist (`edge.x != edge.y`). |
| FR-041 | `validate()` SHALL verify the graph is connected (all rooms reachable from `entry_room_index` via BFS). |
| FR-042 | `validate()` SHALL verify that if `boss_room_index >= 0`, the boss room is reachable from entry. |

### Serialization

| ID | Requirement |
|----|-------------|
| FR-043 | `DungeonData.to_dict()` SHALL return a Dictionary containing `seed_id`, `rooms` (as array of room dicts), `edges` (as array of `[x, y]`), `entry_room_index`, `boss_room_index`, `element` (as int), and `difficulty`. |
| FR-044 | `DungeonData.from_dict(data: Dictionary)` SHALL be a static method returning a fully reconstructed `DungeonData`. |
| FR-045 | Serialization SHALL be round-trip stable: `DungeonData.from_dict(original.to_dict())` produces an equivalent object. |
| FR-046 | `from_dict()` SHALL handle missing optional keys gracefully by using default values. |

---

## Section 7 · Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-001 | `get_adjacent()` SHALL complete in O(E) time where E is the number of edges. |
| NFR-002 | `get_path_to_boss()` SHALL complete in O(V + E) time using BFS. |
| NFR-003 | `validate()` SHALL complete in O(V + E) time. |
| NFR-004 | `is_fully_cleared()` SHALL complete in O(V) time. |
| NFR-005 | `to_dict()` SHALL complete in O(V + E) time. |
| NFR-006 | `from_dict()` SHALL complete in O(V + E) time. |
| NFR-007 | Memory footprint for a 25-room, 40-edge dungeon SHALL NOT exceed 10 KB in the Dictionary representation. |
| NFR-008 | Both classes SHALL use explicit GDScript type hints on all properties, parameters, and return values. |
| NFR-009 | Both classes SHALL follow GDScript style: `snake_case` for variables/methods, `PascalCase` for class names. |
| NFR-010 | Both classes SHALL include doc-comments (`##`) on every public method and every exported property. |
| NFR-011 | No `print()` or `push_warning()` calls in production code paths. Use return values and validation booleans. |
| NFR-012 | `from_dict()` SHALL NOT crash on malformed input. It SHALL return a default-initialised object or `null`. |
| NFR-013 | Code SHALL have zero cyclic dependencies. `RoomData` SHALL NOT reference `DungeonData`. |
| NFR-014 | Test coverage SHALL exercise every public method with at least positive and negative cases. |
| NFR-015 | Both files SHALL be loadable via `load("res://src/models/dungeon_data.gd")` and `load("res://src/models/room_data.gd")` without errors. |
| NFR-016 | Serialized Dictionary output SHALL be JSON-compatible (no Godot-only types like Object references). |
| NFR-017 | `edges` array in serialized form SHALL store each edge as a two-element array `[a, b]`, not as a `Vector2i` string. |
| NFR-018 | `position` and `size` in serialized form SHALL store as `{"x": float, "y": float}` dictionaries for JSON compatibility. |

---

## Section 8 · Designer's Manual

### 8.1 Overview

The Dungeon Room Graph Data Model provides the canonical data structure for every dungeon in Dungeon Seed. When the Procedural Dungeon Generator creates a dungeon, it produces a `DungeonData` object. When the Expedition Resolver runs a dungeon, it reads and mutates that same object. When the game saves, that object serializes to a Dictionary. This manual explains how to work with these classes correctly.

### 8.2 Creating a DungeonData Manually (Testing / Debug)

```gdscript
# Create rooms
var room_0 := RoomData.new()
room_0.index = 0
room_0.type = Enums.RoomType.COMBAT
room_0.position = Vector2(0.0, 0.0)
room_0.size = Vector2(2.0, 2.0)
room_0.difficulty = 3
room_0.loot_bias = Enums.Currency.GOLD

var room_1 := RoomData.new()
room_1.index = 1
room_1.type = Enums.RoomType.TREASURE
room_1.position = Vector2(3.0, 0.0)
room_1.size = Vector2(1.5, 1.5)
room_1.difficulty = 1
room_1.loot_bias = Enums.Currency.DUST

var room_2 := RoomData.new()
room_2.index = 2
room_2.type = Enums.RoomType.BOSS
room_2.position = Vector2(6.0, 0.0)
room_2.size = Vector2(3.0, 3.0)
room_2.difficulty = 8
room_2.loot_bias = Enums.Currency.GEMS

# Create dungeon
var dungeon := DungeonData.new()
dungeon.seed_id = "seed_abc123"
dungeon.rooms = [room_0, room_1, room_2]
dungeon.edges = [Vector2i(0, 1), Vector2i(1, 2)]
dungeon.entry_room_index = 0
dungeon.boss_room_index = 2
dungeon.element = Enums.Element.FIRE
dungeon.difficulty = 5

# Validate
assert(dungeon.validate(), "Dungeon graph is invalid!")
```

### 8.3 Edge Encoding Rules

Edges are **always** stored with the smaller index first:

```gdscript
# CORRECT — canonical ordering
dungeon.edges.append(Vector2i(0, 3))
dungeon.edges.append(Vector2i(2, 5))

# WRONG — will fail validation
dungeon.edges.append(Vector2i(3, 0))  # 3 > 0, violates a < b
dungeon.edges.append(Vector2i(5, 2))  # 5 > 2, violates a < b
```

If you are building edges programmatically, always normalize:

```gdscript
func add_edge(dungeon: DungeonData, a: int, b: int) -> void:
    var edge := Vector2i(mini(a, b), maxi(a, b))
    if edge not in dungeon.edges:
        dungeon.edges.append(edge)
```

### 8.4 Graph Operations Usage

#### Finding Adjacent Rooms

```gdscript
var neighbors: Array[int] = dungeon.get_adjacent(0)
# Returns [1] for the example above (room 0 connects to room 1)

for neighbor_index in neighbors:
    var neighbor_room: RoomData = dungeon.get_room(neighbor_index)
    print("Adjacent room type: ", neighbor_room.type)
```

#### Finding the Path to the Boss

```gdscript
var path: Array[int] = dungeon.get_path_to_boss()
# Returns [0, 1, 2] for the linear example above

if path.is_empty():
    print("No boss room or boss unreachable")
else:
    print("Steps to boss: ", path.size() - 1)
    print("Path: ", path)
```

#### Tracking Exploration Progress

```gdscript
# Mark a room as cleared
dungeon.rooms[0].is_cleared = true

# Check remaining
var uncleared: Array[int] = dungeon.get_uncleared_rooms()
print("Rooms remaining: ", uncleared.size())

# Check full clear
if dungeon.is_fully_cleared():
    print("Dungeon complete! Award bonus.")
```

### 8.5 Serialization Usage

```gdscript
# Save
var save_payload: Dictionary = dungeon.to_dict()
var json_string: String = JSON.stringify(save_payload)
# Write json_string to file...

# Load
var parsed: Dictionary = JSON.parse_string(json_string)
var restored: DungeonData = DungeonData.from_dict(parsed)
assert(restored.validate(), "Restored dungeon failed validation")
```

### 8.6 Room Type Convenience Methods

```gdscript
var room: RoomData = dungeon.get_room(2)

if room.is_boss():
    print("This is the boss room!")
elif room.is_combat():
    print("Standard combat encounter")
elif room.is_rest():
    print("Safe room — heal up")
```

### 8.7 Metadata Dictionary Usage

The `metadata` Dictionary on `RoomData` is an extensibility point. Downstream systems can store room-specific configuration here:

```gdscript
# Trap room: store trap type
var trap_room := RoomData.new()
trap_room.type = Enums.RoomType.TRAP
trap_room.metadata = {
    "trap_type": "spike_floor",
    "damage": 15,
    "avoidance_stat": "agility"
}

# Puzzle room: store puzzle config
var puzzle_room := RoomData.new()
puzzle_room.type = Enums.RoomType.PUZZLE
puzzle_room.metadata = {
    "puzzle_id": "sliding_tiles_01",
    "time_limit": 30.0,
    "bonus_reward_multiplier": 1.5
}

# Boss room: store boss encounter data
var boss_room := RoomData.new()
boss_room.type = Enums.RoomType.BOSS
boss_room.metadata = {
    "boss_id": "flame_warden",
    "phase_count": 3,
    "enrage_timer": 120.0
}
```

Metadata keys are not validated by the model. Downstream consumers are responsible for checking key existence before access.

### 8.8 Validation Checklist

Call `validate()` in these situations:

1. **After generation** — before returning from the generator.
2. **After deserialization** — before using a restored dungeon.
3. **In debug builds** — periodically during expedition to catch mutation bugs.

`validate()` checks:
- At least one room exists
- Entry room index is valid
- Boss room index is valid or -1
- All edge indices are in bounds
- All edges have canonical ordering (a < b)
- No duplicate edges
- No self-loops
- Graph is connected (BFS from entry reaches all rooms)
- Boss room is reachable (if it exists)

### 8.9 Performance Characteristics

| Operation | Complexity | 25-room dungeon |
|-----------|------------|-----------------|
| `get_adjacent()` | O(E) | ~40 edge scans |
| `get_path_to_boss()` | O(V + E) | ~65 operations |
| `get_uncleared_rooms()` | O(V) | ~25 iterations |
| `is_fully_cleared()` | O(V) | ~25 iterations |
| `validate()` | O(V + E) | ~65 operations |
| `to_dict()` | O(V + E) | ~65 operations |
| `from_dict()` | O(V + E) | ~65 operations |

All operations are well under 1ms for the maximum dungeon size. No caching or indexing structures are needed.

---

## Section 9 · Assumptions

| # | Assumption |
|---|------------|
| 1 | TASK-003 (Enums & Constants) is complete and provides `Enums.RoomType` with values: `COMBAT`, `TREASURE`, `TRAP`, `PUZZLE`, `REST`, `BOSS`. |
| 2 | TASK-003 provides `Enums.Element` with at least: `NONE`, `FIRE`, `WATER`, `EARTH`, `AIR`, `SHADOW`, `LIGHT`. |
| 3 | TASK-003 provides `Enums.Currency` with at least: `GOLD`, `DUST`, `GEMS`. |
| 4 | TASK-003 provides `Enums.SeedRarity` and `Enums.SeedPhase` for use by the generator (this task does not directly use them but `difficulty` is derived from them). |
| 5 | Dungeons contain between 1 and 25 rooms inclusive. The upper bound is a design constant, not enforced by this model (generator's responsibility). |
| 6 | Dungeons are single-floor. No vertical layering or floor transitions. |
| 7 | All edges are undirected. If room A connects to room B, room B connects to room A. |
| 8 | The graph is always connected. Disconnected subgraphs are invalid. |
| 9 | `entry_room_index` is always 0 by convention, but the model does not enforce this — the generator may choose any valid index. |
| 10 | `boss_room_index` is -1 for boss-less dungeons (tutorial, early-game). The model treats -1 as "no boss". |
| 11 | `position` and `size` on `RoomData` use abstract coordinate units. The mapping to screen pixels is owned by the UI layer. |
| 12 | `metadata` Dictionary values are limited to JSON-compatible types: `String`, `int`, `float`, `bool`, `Array`, `Dictionary`. No Object references. |
| 13 | `is_cleared` is the only mutable property during an expedition. All other properties are set at generation time and do not change. |
| 14 | The Godot project file structure places models at `res://src/models/` and tests at `res://tests/models/`. |
| 15 | GUT (Godot Unit Testing) framework is available for running tests. |

---

## Section 10 · Security & Anti-Cheat

### THREAT-001: Save File Manipulation — Room Clearance Flags

**Vector**: Player edits the save file JSON to set `is_cleared = true` on all rooms, skipping encounters and claiming completion rewards without playing.

**Mitigation**: The Save/Load system (TASK-022) should compute a checksum over the serialized DungeonData. `from_dict()` in this task does not enforce checksums (that is the save system's responsibility), but the `validate()` method ensures structural integrity so tampered graphs with invalid indices or broken connectivity are rejected.

**Severity**: Medium — affects progression rate but not other players (single-player game).

### THREAT-002: Save File Manipulation — Difficulty Downgrade

**Vector**: Player edits `difficulty` on DungeonData or individual rooms to 0, trivialising encounters.

**Mitigation**: The Expedition Resolver should clamp difficulty to `max(1, room.difficulty)` as a defensive check. This model stores the data as-generated; the resolver enforces floors. Additionally, the save checksum from TASK-022 detects tampering.

**Severity**: Medium — economy impact if rewards are not also clamped.

### THREAT-003: Save File Manipulation — Loot Bias Override

**Vector**: Player edits `loot_bias` on every room to the most valuable currency (e.g., `GEMS`), skewing reward distribution.

**Mitigation**: Same checksum approach as THREAT-001. The Expedition Resolver should also verify that `loot_bias` distribution matches expected ratios for the seed's rarity tier, logging anomalies.

**Severity**: Low-Medium — affects economy pacing for that player only.

### THREAT-004: Crafted Dictionary Injection via from_dict()

**Vector**: A malformed Dictionary is passed to `from_dict()` attempting to crash the game or create an exploitable state (e.g., negative room indices, enormous room counts, circular references in metadata).

**Mitigation**: `from_dict()` SHALL use safe access patterns (`data.get("key", default)`), clamp values to valid ranges, and reject clearly invalid data. `validate()` called after `from_dict()` catches structural issues. The method SHALL NOT crash on any input.

**Severity**: Low — single-player, local save files only. But robustness prevents crash exploits.

### THREAT-005: Memory Exhaustion via Oversized Rooms Array

**Vector**: A tampered save file contains thousands of rooms, causing memory exhaustion or lag when the dungeon is loaded.

**Mitigation**: `from_dict()` SHALL enforce a hard cap on room count (e.g., 100 rooms) and edge count (e.g., 500 edges). Any data exceeding these limits results in a `null` return or default object.

**Severity**: Low — local-only attack surface. Defense-in-depth measure.

---

## Section 11 · Best Practices

| # | Practice |
|---|----------|
| 1 | **Always call `validate()` after construction or deserialization.** Never assume a `DungeonData` is valid just because it was created without errors. |
| 2 | **Use canonical edge ordering.** Always create edges with `Vector2i(mini(a, b), maxi(a, b))`. Never rely on insertion order to imply direction. |
| 3 | **Check `has_boss_room()` before calling `get_path_to_boss()`.** The path method returns empty for no-boss dungeons, but checking first communicates intent. |
| 4 | **Do not store Object references in `metadata`.** Only JSON-compatible primitives. This ensures `to_dict()` works without special serialization. |
| 5 | **Do not modify `rooms` or `edges` arrays after generation.** The only mutable runtime state is `is_cleared` on individual rooms. |
| 6 | **Use `get_room()` instead of direct array access.** It returns `null` for out-of-bounds indices instead of crashing. |
| 7 | **Prefer `get_adjacent()` over manual edge scanning.** The method handles both directions of undirected edges correctly. |
| 8 | **Keep `RoomData` free of DungeonData references.** Rooms should not know about their parent dungeon. This prevents circular references and simplifies serialization. |
| 9 | **Use `from_dict()` for deserialization, not manual property assignment.** The static factory handles all edge cases, defaults, and type conversions. |
| 10 | **Test with both minimal and maximal dungeons.** A 1-room dungeon and a 25-room dungeon exercise different code paths (empty edge lists, BFS on large graphs). |
| 11 | **Use type hints on all variables that hold `RoomData` or `DungeonData`.** This enables editor autocompletion and catches type errors early. |
| 12 | **Document metadata keys per room type in a central location.** This task defines the extensibility point; downstream tasks should maintain a registry of used keys. |
| 13 | **Never use `==` to compare two `DungeonData` instances.** RefCounted objects compare by reference, not value. Compare via `to_dict()` output if semantic equality is needed. |
| 14 | **Log validation failures in debug builds.** In release, silently reject. This helps catch generator bugs during development without exposing internals to players. |

---

## Section 12 · Troubleshooting

### ISSUE-001: `validate()` Returns False After Generation

**Symptoms**: The generator creates a `DungeonData`, calls `validate()`, and gets `false`.

**Diagnosis**:
1. Check that `rooms.size() >= 1`. An empty rooms array fails immediately.
2. Check that `entry_room_index` is within `[0, rooms.size())`.
3. Check that all edges have `edge.x < edge.y` (canonical ordering).
4. Check for duplicate edges — `edges` should contain no repeated `Vector2i` values.
5. Run a BFS from `entry_room_index` and verify it visits every room. If any room is unreachable, the graph is disconnected.
6. If `boss_room_index >= 0`, verify it appears in the BFS visited set.

**Resolution**: Fix the generation algorithm. Common bugs: forgetting to normalize edge order, creating islands of rooms not connected to the main graph, setting `boss_room_index` to an index that doesn't exist.

### ISSUE-002: `get_path_to_boss()` Returns Empty When Boss Exists

**Symptoms**: `has_boss_room()` returns `true`, but `get_path_to_boss()` returns `[]`.

**Diagnosis**:
1. Confirm `boss_room_index` is a valid index.
2. Run `validate()` — if it returns `false`, the graph may be disconnected.
3. Check that edges actually connect the entry to the boss. A common bug is creating the boss room but forgetting to add an edge connecting it to the rest of the graph.

**Resolution**: Ensure the generator always connects the boss room to at least one other room before finalizing edges.

### ISSUE-003: Serialization Round-Trip Changes Data

**Symptoms**: `from_dict(original.to_dict())` produces a `DungeonData` that differs from the original.

**Diagnosis**:
1. Check `position` and `size` serialization. `Vector2` must be stored as `{"x": float, "y": float}` and restored exactly.
2. Check enum serialization. Enums must be stored as integers and restored via `Enums.RoomType.values()[int_val]` or equivalent.
3. Check `metadata` — nested Dictionaries and Arrays must survive JSON round-trip. Godot's `JSON.stringify` / `JSON.parse_string` can alter types (e.g., `int` → `float`).

**Resolution**: Use explicit `int()` and `float()` casts during deserialization. Test round-trip with a known fixture.

### ISSUE-004: `get_adjacent()` Returns Unexpected Results

**Symptoms**: A room shows more or fewer neighbors than expected.

**Diagnosis**:
1. Print `edges` and manually check which edges include the room index.
2. Remember edges are undirected: `Vector2i(0, 3)` means room 0 and room 3 are neighbors. `get_adjacent(3)` should include 0.
3. Check for duplicate edges — they would cause a room to appear twice in the adjacency list.

**Resolution**: Verify edge creation logic uses canonical ordering and duplicate checking.

### ISSUE-005: Memory Leak with DungeonData

**Symptoms**: Long play sessions show increasing memory usage correlated with dungeon count.

**Diagnosis**:
1. `DungeonData` and `RoomData` extend `RefCounted`, so they are freed when all references are dropped.
2. Check that no global array or dictionary is holding onto old `DungeonData` instances.
3. Check that `metadata` dictionaries do not contain circular references (this would prevent RefCounted cleanup).

**Resolution**: Ensure expedition completion clears the reference to the consumed `DungeonData`. Use `WeakRef` if caching is needed.

### ISSUE-006: `from_dict()` Crashes on Corrupted Save Data

**Symptoms**: Loading a save file causes a crash in `from_dict()`.

**Diagnosis**:
1. Check that `from_dict()` uses `data.get("key", default)` for every field, never direct `data["key"]` access.
2. Check that type conversions use safe casts: `int(data.get("difficulty", 1))`.
3. Check that the rooms array size is capped to prevent memory exhaustion.

**Resolution**: Ensure every access in `from_dict()` is guarded with `.get()` and a sensible default. Add the room count cap (100 rooms max).

---

## Section 13 · Acceptance Criteria

### RoomData Construction & Properties

| ID | Criterion |
|----|-----------|
| AC-001 | `RoomData.new()` creates an instance with `index == 0`. |
| AC-002 | `RoomData.new()` creates an instance with `type == Enums.RoomType.COMBAT`. |
| AC-003 | `RoomData.new()` creates an instance with `position == Vector2.ZERO`. |
| AC-004 | `RoomData.new()` creates an instance with `size == Vector2(1.0, 1.0)`. |
| AC-005 | `RoomData.new()` creates an instance with `difficulty == 1`. |
| AC-006 | `RoomData.new()` creates an instance with `loot_bias == Enums.Currency.GOLD`. |
| AC-007 | `RoomData.new()` creates an instance with `is_cleared == false`. |
| AC-008 | `RoomData.new()` creates an instance with `metadata` as an empty Dictionary. |
| AC-009 | Setting `room.index = 5` and reading `room.index` returns `5`. |
| AC-010 | Setting `room.type = Enums.RoomType.BOSS` and calling `room.is_boss()` returns `true`. |
| AC-011 | `room.is_combat()` returns `true` when `type == Enums.RoomType.COMBAT`, `false` otherwise. |
| AC-012 | `room.is_rest()` returns `true` when `type == Enums.RoomType.REST`, `false` otherwise. |
| AC-013 | `room.is_boss()` returns `false` for non-BOSS room types. |

### RoomData Serialization

| ID | Criterion |
|----|-----------|
| AC-014 | `room.to_dict()` returns a Dictionary with keys: `"index"`, `"type"`, `"position"`, `"size"`, `"difficulty"`, `"loot_bias"`, `"is_cleared"`, `"metadata"`. |
| AC-015 | `room.to_dict()["type"]` is an integer matching the enum's integer value. |
| AC-016 | `room.to_dict()["position"]` is a Dictionary `{"x": float, "y": float}`. |
| AC-017 | `room.to_dict()["size"]` is a Dictionary `{"x": float, "y": float}`. |
| AC-018 | `room.to_dict()["loot_bias"]` is an integer matching the enum's integer value. |
| AC-019 | `RoomData.from_dict(room.to_dict())` produces a `RoomData` with identical property values. |
| AC-020 | `RoomData.from_dict({})` returns a `RoomData` with all default values (no crash). |
| AC-021 | `RoomData.from_dict(room.to_dict()).metadata` deep-equals `room.metadata` when metadata contains nested structures. |

### DungeonData Construction & Properties

| ID | Criterion |
|----|-----------|
| AC-022 | `DungeonData.new()` creates an instance with `seed_id == ""`. |
| AC-023 | `DungeonData.new()` creates an instance with `rooms` as an empty array. |
| AC-024 | `DungeonData.new()` creates an instance with `edges` as an empty array. |
| AC-025 | `DungeonData.new()` creates an instance with `entry_room_index == 0`. |
| AC-026 | `DungeonData.new()` creates an instance with `boss_room_index == -1`. |
| AC-027 | `DungeonData.new()` creates an instance with `element == Enums.Element.NONE`. |
| AC-028 | `DungeonData.new()` creates an instance with `difficulty == 1`. |

### Graph Operations

| ID | Criterion |
|----|-----------|
| AC-029 | `get_adjacent(0)` on a 3-room linear graph `[0-1, 1-2]` returns `[1]`. |
| AC-030 | `get_adjacent(1)` on a 3-room linear graph `[0-1, 1-2]` returns `[0, 2]`. |
| AC-031 | `get_adjacent(2)` on a 3-room linear graph `[0-1, 1-2]` returns `[1]`. |
| AC-032 | `get_adjacent(-1)` returns an empty array (out of bounds). |
| AC-033 | `get_adjacent(99)` returns an empty array when only 3 rooms exist. |
| AC-034 | `get_path_to_boss()` on a linear graph `[0-1-2]` with boss at index 2 returns `[0, 1, 2]`. |
| AC-035 | `get_path_to_boss()` on a branching graph returns the shortest path, not a longer alternative. |
| AC-036 | `get_path_to_boss()` returns `[]` when `boss_room_index == -1`. |
| AC-037 | `get_uncleared_rooms()` returns all room indices when no rooms are cleared. |
| AC-038 | `get_uncleared_rooms()` returns an empty array when all rooms are cleared. |
| AC-039 | `get_uncleared_rooms()` returns only uncleared indices after partial clearing. |
| AC-040 | `is_fully_cleared()` returns `false` when at least one room is uncleared. |
| AC-041 | `is_fully_cleared()` returns `true` when every room's `is_cleared` is `true`. |
| AC-042 | `get_room(0)` returns the first `RoomData` in the array. |
| AC-043 | `get_room(-1)` returns `null`. |
| AC-044 | `get_room(rooms.size())` returns `null`. |
| AC-045 | `get_room_count()` returns `rooms.size()`. |
| AC-046 | `get_edge_count()` returns `edges.size()`. |
| AC-047 | `has_boss_room()` returns `true` when `boss_room_index` is a valid index. |
| AC-048 | `has_boss_room()` returns `false` when `boss_room_index == -1`. |

### Validation

| ID | Criterion |
|----|-----------|
| AC-049 | `validate()` returns `false` for an empty rooms array. |
| AC-050 | `validate()` returns `false` when `entry_room_index` is out of bounds. |
| AC-051 | `validate()` returns `false` when `boss_room_index` is out of bounds (and not -1). |
| AC-052 | `validate()` returns `false` when an edge references an out-of-bounds room index. |
| AC-053 | `validate()` returns `false` when an edge has `edge.x >= edge.y` (non-canonical). |
| AC-054 | `validate()` returns `false` when duplicate edges exist. |
| AC-055 | `validate()` returns `false` when a self-loop exists. |
| AC-056 | `validate()` returns `false` for a disconnected graph (two islands). |
| AC-057 | `validate()` returns `true` for a valid connected graph with boss. |
| AC-058 | `validate()` returns `true` for a valid single-room dungeon (no edges, no boss). |
| AC-059 | `validate()` returns `true` for a valid dungeon with `boss_room_index == -1`. |

### DungeonData Serialization

| ID | Criterion |
|----|-----------|
| AC-060 | `dungeon.to_dict()` returns a Dictionary with keys: `"seed_id"`, `"rooms"`, `"edges"`, `"entry_room_index"`, `"boss_room_index"`, `"element"`, `"difficulty"`. |
| AC-061 | `dungeon.to_dict()["rooms"]` is an Array of Dictionaries (one per room). |
| AC-062 | `dungeon.to_dict()["edges"]` is an Array of two-element Arrays `[[a, b], ...]`. |
| AC-063 | `dungeon.to_dict()["element"]` is an integer. |
| AC-064 | `DungeonData.from_dict(dungeon.to_dict())` produces a `DungeonData` that passes `validate()`. |
| AC-065 | Round-trip serialization preserves `seed_id` exactly. |
| AC-066 | Round-trip serialization preserves all room properties including `metadata`. |
| AC-067 | Round-trip serialization preserves all edges. |
| AC-068 | Round-trip serialization preserves `entry_room_index` and `boss_room_index`. |
| AC-069 | `DungeonData.from_dict({})` returns a `DungeonData` without crashing (uses defaults). |
| AC-070 | `DungeonData.from_dict()` caps room count at 100, discarding excess rooms. |

### Edge Cases

| ID | Criterion |
|----|-----------|
| AC-071 | Single-room dungeon: 1 room, 0 edges, entry=0, boss=-1. `validate()` returns `true`. `is_fully_cleared()` works correctly. |
| AC-072 | Single-room boss dungeon: 1 room (BOSS type), 0 edges, entry=0, boss=0. `validate()` returns `true`. `get_path_to_boss()` returns `[0]`. |
| AC-073 | Fully connected 4-room graph (6 edges). `get_adjacent(0)` returns 3 neighbors. |
| AC-074 | Star topology: room 0 connects to rooms 1, 2, 3, 4. `get_path_to_boss()` with boss=4 returns `[0, 4]` (direct path). |
| AC-075 | Large dungeon: 25 rooms, ~35 edges. `validate()` returns `true`. All operations complete without error. |

---

## Section 14 · Testing Requirements

All tests use the GUT (Godot Unit Testing) framework. Two test files are required.

### File: `tests/models/test_room_data.gd`

```gdscript
extends GutTest
## Unit tests for RoomData data model.


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_room(idx: int, room_type: Enums.RoomType, pos: Vector2, sz: Vector2,
		diff: int, bias: Enums.Currency, cleared: bool,
		meta: Dictionary) -> RoomData:
	var room := RoomData.new()
	room.index = idx
	room.type = room_type
	room.position = pos
	room.size = sz
	room.difficulty = diff
	room.loot_bias = bias
	room.is_cleared = cleared
	room.metadata = meta
	return room


func _make_default_room() -> RoomData:
	return RoomData.new()


# ---------------------------------------------------------------------------
# Default Construction
# ---------------------------------------------------------------------------

func test_default_index() -> void:
	var room := _make_default_room()
	assert_eq(room.index, 0, "Default index should be 0")


func test_default_type() -> void:
	var room := _make_default_room()
	assert_eq(room.type, Enums.RoomType.COMBAT, "Default type should be COMBAT")


func test_default_position() -> void:
	var room := _make_default_room()
	assert_eq(room.position, Vector2.ZERO, "Default position should be ZERO")


func test_default_size() -> void:
	var room := _make_default_room()
	assert_eq(room.size, Vector2(1.0, 1.0), "Default size should be (1,1)")


func test_default_difficulty() -> void:
	var room := _make_default_room()
	assert_eq(room.difficulty, 1, "Default difficulty should be 1")


func test_default_loot_bias() -> void:
	var room := _make_default_room()
	assert_eq(room.loot_bias, Enums.Currency.GOLD, "Default loot_bias should be GOLD")


func test_default_is_cleared() -> void:
	var room := _make_default_room()
	assert_false(room.is_cleared, "Default is_cleared should be false")


func test_default_metadata() -> void:
	var room := _make_default_room()
	assert_eq(room.metadata, {}, "Default metadata should be empty dict")


# ---------------------------------------------------------------------------
# Property Assignment
# ---------------------------------------------------------------------------

func test_set_index() -> void:
	var room := _make_default_room()
	room.index = 7
	assert_eq(room.index, 7)


func test_set_type() -> void:
	var room := _make_default_room()
	room.type = Enums.RoomType.BOSS
	assert_eq(room.type, Enums.RoomType.BOSS)


func test_set_position() -> void:
	var room := _make_default_room()
	room.position = Vector2(10.5, -3.2)
	assert_almost_eq(room.position.x, 10.5, 0.001)
	assert_almost_eq(room.position.y, -3.2, 0.001)


func test_set_size() -> void:
	var room := _make_default_room()
	room.size = Vector2(4.0, 3.0)
	assert_eq(room.size, Vector2(4.0, 3.0))


func test_set_difficulty() -> void:
	var room := _make_default_room()
	room.difficulty = 10
	assert_eq(room.difficulty, 10)


func test_set_loot_bias() -> void:
	var room := _make_default_room()
	room.loot_bias = Enums.Currency.GEMS
	assert_eq(room.loot_bias, Enums.Currency.GEMS)


func test_set_is_cleared() -> void:
	var room := _make_default_room()
	room.is_cleared = true
	assert_true(room.is_cleared)


func test_set_metadata() -> void:
	var room := _make_default_room()
	room.metadata = {"trap_type": "spike", "damage": 15}
	assert_eq(room.metadata["trap_type"], "spike")
	assert_eq(room.metadata["damage"], 15)


# ---------------------------------------------------------------------------
# Convenience Methods
# ---------------------------------------------------------------------------

func test_is_combat_true() -> void:
	var room := _make_room(0, Enums.RoomType.COMBAT, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	assert_true(room.is_combat())


func test_is_combat_false_for_boss() -> void:
	var room := _make_room(0, Enums.RoomType.BOSS, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	assert_false(room.is_combat())


func test_is_boss_true() -> void:
	var room := _make_room(0, Enums.RoomType.BOSS, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	assert_true(room.is_boss())


func test_is_boss_false_for_combat() -> void:
	var room := _make_room(0, Enums.RoomType.COMBAT, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	assert_false(room.is_boss())


func test_is_rest_true() -> void:
	var room := _make_room(0, Enums.RoomType.REST, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	assert_true(room.is_rest())


func test_is_rest_false_for_trap() -> void:
	var room := _make_room(0, Enums.RoomType.TRAP, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	assert_false(room.is_rest())


# ---------------------------------------------------------------------------
# Serialization — to_dict
# ---------------------------------------------------------------------------

func test_to_dict_has_all_keys() -> void:
	var room := _make_default_room()
	var d: Dictionary = room.to_dict()
	assert_has(d, "index")
	assert_has(d, "type")
	assert_has(d, "position")
	assert_has(d, "size")
	assert_has(d, "difficulty")
	assert_has(d, "loot_bias")
	assert_has(d, "is_cleared")
	assert_has(d, "metadata")


func test_to_dict_type_is_int() -> void:
	var room := _make_room(0, Enums.RoomType.TREASURE, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	var d: Dictionary = room.to_dict()
	assert_typeof(d["type"], TYPE_INT)


func test_to_dict_position_is_dict() -> void:
	var room := _make_room(0, Enums.RoomType.COMBAT, Vector2(5.5, 3.2), Vector2.ONE, 1, Enums.Currency.GOLD, false, {})
	var d: Dictionary = room.to_dict()
	assert_typeof(d["position"], TYPE_DICTIONARY)
	assert_almost_eq(float(d["position"]["x"]), 5.5, 0.001)
	assert_almost_eq(float(d["position"]["y"]), 3.2, 0.001)


func test_to_dict_size_is_dict() -> void:
	var room := _make_room(0, Enums.RoomType.COMBAT, Vector2.ZERO, Vector2(2.0, 3.0), 1, Enums.Currency.GOLD, false, {})
	var d: Dictionary = room.to_dict()
	assert_typeof(d["size"], TYPE_DICTIONARY)
	assert_almost_eq(float(d["size"]["x"]), 2.0, 0.001)
	assert_almost_eq(float(d["size"]["y"]), 3.0, 0.001)


func test_to_dict_loot_bias_is_int() -> void:
	var room := _make_room(0, Enums.RoomType.COMBAT, Vector2.ZERO, Vector2.ONE, 1, Enums.Currency.DUST, false, {})
	var d: Dictionary = room.to_dict()
	assert_typeof(d["loot_bias"], TYPE_INT)


func test_to_dict_metadata_preserved() -> void:
	var meta := {"boss_id": "flame_warden", "phases": [1, 2, 3]}
	var room := _make_room(0, Enums.RoomType.BOSS, Vector2.ZERO, Vector2.ONE, 8, Enums.Currency.GEMS, false, meta)
	var d: Dictionary = room.to_dict()
	assert_eq(d["metadata"]["boss_id"], "flame_warden")
	assert_eq(d["metadata"]["phases"], [1, 2, 3])


# ---------------------------------------------------------------------------
# Serialization — from_dict Round-Trip
# ---------------------------------------------------------------------------

func test_round_trip_default() -> void:
	var original := _make_default_room()
	var restored := RoomData.from_dict(original.to_dict())
	assert_eq(restored.index, original.index)
	assert_eq(restored.type, original.type)
	assert_eq(restored.position, original.position)
	assert_eq(restored.size, original.size)
	assert_eq(restored.difficulty, original.difficulty)
	assert_eq(restored.loot_bias, original.loot_bias)
	assert_eq(restored.is_cleared, original.is_cleared)
	assert_eq(restored.metadata, original.metadata)


func test_round_trip_custom() -> void:
	var original := _make_room(5, Enums.RoomType.PUZZLE, Vector2(10.0, -5.0),
		Vector2(3.0, 2.0), 7, Enums.Currency.DUST, true,
		{"puzzle_id": "slider_01", "time_limit": 30.0})
	var restored := RoomData.from_dict(original.to_dict())
	assert_eq(restored.index, 5)
	assert_eq(restored.type, Enums.RoomType.PUZZLE)
	assert_almost_eq(restored.position.x, 10.0, 0.001)
	assert_almost_eq(restored.position.y, -5.0, 0.001)
	assert_almost_eq(restored.size.x, 3.0, 0.001)
	assert_almost_eq(restored.size.y, 2.0, 0.001)
	assert_eq(restored.difficulty, 7)
	assert_eq(restored.loot_bias, Enums.Currency.DUST)
	assert_true(restored.is_cleared)
	assert_eq(restored.metadata["puzzle_id"], "slider_01")
	assert_almost_eq(float(restored.metadata["time_limit"]), 30.0, 0.001)


func test_from_dict_empty_dict() -> void:
	var restored := RoomData.from_dict({})
	assert_not_null(restored, "from_dict({}) should not return null")
	assert_eq(restored.index, 0)
	assert_eq(restored.type, Enums.RoomType.COMBAT)
	assert_false(restored.is_cleared)
```

### File: `tests/models/test_dungeon_data.gd`

```gdscript
extends GutTest
## Unit tests for DungeonData graph data model.


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_room(idx: int, room_type: Enums.RoomType) -> RoomData:
	var room := RoomData.new()
	room.index = idx
	room.type = room_type
	room.position = Vector2(float(idx) * 3.0, 0.0)
	room.size = Vector2(2.0, 2.0)
	room.difficulty = idx + 1
	room.loot_bias = Enums.Currency.GOLD
	return room


func _make_linear_dungeon(room_count: int, boss_index: int) -> DungeonData:
	## Creates a linear chain: 0-1-2-...-n with optional boss.
	var dungeon := DungeonData.new()
	dungeon.seed_id = "test_linear"
	dungeon.element = Enums.Element.FIRE
	dungeon.difficulty = 5
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = boss_index
	for i in range(room_count):
		var rtype: Enums.RoomType = Enums.RoomType.BOSS if i == boss_index else Enums.RoomType.COMBAT
		dungeon.rooms.append(_make_room(i, rtype))
	for i in range(room_count - 1):
		dungeon.edges.append(Vector2i(i, i + 1))
	return dungeon


func _make_branching_dungeon() -> DungeonData:
	## Creates a graph:
	##   0 -- 1 -- 3 (boss)
	##   |         |
	##   2 --------+
	## Shortest path 0->3 is [0, 1, 3] (length 2), not [0, 2, 3] (also length 2, but BFS finds 0-1-3 first).
	var dungeon := DungeonData.new()
	dungeon.seed_id = "test_branch"
	dungeon.element = Enums.Element.WATER
	dungeon.difficulty = 3
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = 3
	for i in range(4):
		var rtype: Enums.RoomType = Enums.RoomType.BOSS if i == 3 else Enums.RoomType.COMBAT
		dungeon.rooms.append(_make_room(i, rtype))
	dungeon.edges = [
		Vector2i(0, 1),
		Vector2i(0, 2),
		Vector2i(1, 3),
		Vector2i(2, 3),
	]
	return dungeon


func _make_star_dungeon() -> DungeonData:
	## Room 0 in center, connected to rooms 1..4. Boss at 4.
	var dungeon := DungeonData.new()
	dungeon.seed_id = "test_star"
	dungeon.element = Enums.Element.EARTH
	dungeon.difficulty = 4
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = 4
	for i in range(5):
		var rtype: Enums.RoomType = Enums.RoomType.BOSS if i == 4 else Enums.RoomType.COMBAT
		dungeon.rooms.append(_make_room(i, rtype))
	for i in range(1, 5):
		dungeon.edges.append(Vector2i(0, i))
	return dungeon


func _make_single_room_dungeon() -> DungeonData:
	var dungeon := DungeonData.new()
	dungeon.seed_id = "test_single"
	dungeon.element = Enums.Element.NONE
	dungeon.difficulty = 1
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = -1
	dungeon.rooms.append(_make_room(0, Enums.RoomType.COMBAT))
	return dungeon


func _make_large_dungeon(count: int) -> DungeonData:
	## Creates a chain of `count` rooms for stress testing.
	return _make_linear_dungeon(count, count - 1)


# ---------------------------------------------------------------------------
# Default Construction
# ---------------------------------------------------------------------------

func test_default_seed_id() -> void:
	var d := DungeonData.new()
	assert_eq(d.seed_id, "")


func test_default_rooms() -> void:
	var d := DungeonData.new()
	assert_eq(d.rooms.size(), 0)


func test_default_edges() -> void:
	var d := DungeonData.new()
	assert_eq(d.edges.size(), 0)


func test_default_entry_room_index() -> void:
	var d := DungeonData.new()
	assert_eq(d.entry_room_index, 0)


func test_default_boss_room_index() -> void:
	var d := DungeonData.new()
	assert_eq(d.boss_room_index, -1)


func test_default_element() -> void:
	var d := DungeonData.new()
	assert_eq(d.element, Enums.Element.NONE)


func test_default_difficulty() -> void:
	var d := DungeonData.new()
	assert_eq(d.difficulty, 1)


# ---------------------------------------------------------------------------
# get_adjacent
# ---------------------------------------------------------------------------

func test_adjacent_linear_start() -> void:
	var d := _make_linear_dungeon(3, 2)
	var adj: Array[int] = d.get_adjacent(0)
	assert_eq(adj.size(), 1)
	assert_has(adj, 1)


func test_adjacent_linear_middle() -> void:
	var d := _make_linear_dungeon(3, 2)
	var adj: Array[int] = d.get_adjacent(1)
	assert_eq(adj.size(), 2)
	assert_has(adj, 0)
	assert_has(adj, 2)


func test_adjacent_linear_end() -> void:
	var d := _make_linear_dungeon(3, 2)
	var adj: Array[int] = d.get_adjacent(2)
	assert_eq(adj.size(), 1)
	assert_has(adj, 1)


func test_adjacent_star_center() -> void:
	var d := _make_star_dungeon()
	var adj: Array[int] = d.get_adjacent(0)
	assert_eq(adj.size(), 4)
	assert_has(adj, 1)
	assert_has(adj, 2)
	assert_has(adj, 3)
	assert_has(adj, 4)


func test_adjacent_star_leaf() -> void:
	var d := _make_star_dungeon()
	var adj: Array[int] = d.get_adjacent(3)
	assert_eq(adj.size(), 1)
	assert_has(adj, 0)


func test_adjacent_out_of_bounds_negative() -> void:
	var d := _make_linear_dungeon(3, 2)
	var adj: Array[int] = d.get_adjacent(-1)
	assert_eq(adj.size(), 0)


func test_adjacent_out_of_bounds_large() -> void:
	var d := _make_linear_dungeon(3, 2)
	var adj: Array[int] = d.get_adjacent(99)
	assert_eq(adj.size(), 0)


func test_adjacent_single_room() -> void:
	var d := _make_single_room_dungeon()
	var adj: Array[int] = d.get_adjacent(0)
	assert_eq(adj.size(), 0)


# ---------------------------------------------------------------------------
# get_path_to_boss
# ---------------------------------------------------------------------------

func test_path_to_boss_linear() -> void:
	var d := _make_linear_dungeon(3, 2)
	var path: Array[int] = d.get_path_to_boss()
	assert_eq(path, [0, 1, 2])


func test_path_to_boss_star_direct() -> void:
	var d := _make_star_dungeon()
	var path: Array[int] = d.get_path_to_boss()
	assert_eq(path, [0, 4])


func test_path_to_boss_branching_shortest() -> void:
	var d := _make_branching_dungeon()
	var path: Array[int] = d.get_path_to_boss()
	# Both [0,1,3] and [0,2,3] are length 2; BFS finds one of them.
	assert_eq(path.size(), 3, "Shortest path should be length 3 (3 nodes)")
	assert_eq(path[0], 0, "Path starts at entry")
	assert_eq(path[path.size() - 1], 3, "Path ends at boss")


func test_path_to_boss_no_boss() -> void:
	var d := _make_single_room_dungeon()
	var path: Array[int] = d.get_path_to_boss()
	assert_eq(path, [])


func test_path_to_boss_single_room_boss() -> void:
	var d := _make_single_room_dungeon()
	d.boss_room_index = 0
	d.rooms[0].type = Enums.RoomType.BOSS
	var path: Array[int] = d.get_path_to_boss()
	assert_eq(path, [0])


func test_path_to_boss_five_room_chain() -> void:
	var d := _make_linear_dungeon(5, 4)
	var path: Array[int] = d.get_path_to_boss()
	assert_eq(path, [0, 1, 2, 3, 4])


# ---------------------------------------------------------------------------
# get_uncleared_rooms / is_fully_cleared
# ---------------------------------------------------------------------------

func test_uncleared_all_rooms_initially() -> void:
	var d := _make_linear_dungeon(3, 2)
	var uncleared: Array[int] = d.get_uncleared_rooms()
	assert_eq(uncleared.size(), 3)


func test_uncleared_after_partial_clear() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.rooms[0].is_cleared = true
	d.rooms[1].is_cleared = true
	var uncleared: Array[int] = d.get_uncleared_rooms()
	assert_eq(uncleared.size(), 1)
	assert_has(uncleared, 2)


func test_uncleared_all_cleared() -> void:
	var d := _make_linear_dungeon(3, 2)
	for room in d.rooms:
		room.is_cleared = true
	var uncleared: Array[int] = d.get_uncleared_rooms()
	assert_eq(uncleared.size(), 0)


func test_is_fully_cleared_false() -> void:
	var d := _make_linear_dungeon(3, 2)
	assert_false(d.is_fully_cleared())


func test_is_fully_cleared_partial() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.rooms[0].is_cleared = true
	d.rooms[1].is_cleared = true
	assert_false(d.is_fully_cleared())


func test_is_fully_cleared_true() -> void:
	var d := _make_linear_dungeon(3, 2)
	for room in d.rooms:
		room.is_cleared = true
	assert_true(d.is_fully_cleared())


func test_is_fully_cleared_single_room() -> void:
	var d := _make_single_room_dungeon()
	assert_false(d.is_fully_cleared())
	d.rooms[0].is_cleared = true
	assert_true(d.is_fully_cleared())


# ---------------------------------------------------------------------------
# get_room / get_room_count / get_edge_count / has_boss_room
# ---------------------------------------------------------------------------

func test_get_room_valid() -> void:
	var d := _make_linear_dungeon(3, 2)
	var room: RoomData = d.get_room(1)
	assert_not_null(room)
	assert_eq(room.index, 1)


func test_get_room_out_of_bounds_negative() -> void:
	var d := _make_linear_dungeon(3, 2)
	assert_null(d.get_room(-1))


func test_get_room_out_of_bounds_large() -> void:
	var d := _make_linear_dungeon(3, 2)
	assert_null(d.get_room(3))


func test_get_room_count() -> void:
	var d := _make_linear_dungeon(5, 4)
	assert_eq(d.get_room_count(), 5)


func test_get_edge_count() -> void:
	var d := _make_linear_dungeon(5, 4)
	assert_eq(d.get_edge_count(), 4)


func test_has_boss_room_true() -> void:
	var d := _make_linear_dungeon(3, 2)
	assert_true(d.has_boss_room())


func test_has_boss_room_false() -> void:
	var d := _make_single_room_dungeon()
	assert_false(d.has_boss_room())


# ---------------------------------------------------------------------------
# validate — positive cases
# ---------------------------------------------------------------------------

func test_validate_linear_dungeon() -> void:
	var d := _make_linear_dungeon(3, 2)
	assert_true(d.validate())


func test_validate_branching_dungeon() -> void:
	var d := _make_branching_dungeon()
	assert_true(d.validate())


func test_validate_star_dungeon() -> void:
	var d := _make_star_dungeon()
	assert_true(d.validate())


func test_validate_single_room() -> void:
	var d := _make_single_room_dungeon()
	assert_true(d.validate())


func test_validate_no_boss() -> void:
	var d := _make_linear_dungeon(3, -1)
	# Override: no boss room, all rooms COMBAT
	d.boss_room_index = -1
	for room in d.rooms:
		room.type = Enums.RoomType.COMBAT
	assert_true(d.validate())


# ---------------------------------------------------------------------------
# validate — negative cases
# ---------------------------------------------------------------------------

func test_validate_empty_rooms() -> void:
	var d := DungeonData.new()
	assert_false(d.validate())


func test_validate_entry_out_of_bounds() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.entry_room_index = 10
	assert_false(d.validate())


func test_validate_boss_out_of_bounds() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.boss_room_index = 10
	assert_false(d.validate())


func test_validate_edge_out_of_bounds() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.edges.append(Vector2i(1, 99))
	assert_false(d.validate())


func test_validate_non_canonical_edge() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.edges.append(Vector2i(2, 0))  # 2 > 0, non-canonical
	assert_false(d.validate())


func test_validate_duplicate_edge() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.edges.append(Vector2i(0, 1))  # duplicate of existing edge
	assert_false(d.validate())


func test_validate_self_loop() -> void:
	var d := _make_linear_dungeon(3, 2)
	d.edges.append(Vector2i(1, 1))  # self-loop (also non-canonical since not a < b)
	assert_false(d.validate())


func test_validate_disconnected_graph() -> void:
	var d := DungeonData.new()
	d.seed_id = "test_disconnected"
	d.entry_room_index = 0
	d.boss_room_index = -1
	d.rooms.append(_make_room(0, Enums.RoomType.COMBAT))
	d.rooms.append(_make_room(1, Enums.RoomType.COMBAT))
	# No edges — rooms are disconnected
	assert_false(d.validate())


# ---------------------------------------------------------------------------
# Serialization — DungeonData
# ---------------------------------------------------------------------------

func test_to_dict_has_all_keys() -> void:
	var d := _make_linear_dungeon(3, 2)
	var data: Dictionary = d.to_dict()
	assert_has(data, "seed_id")
	assert_has(data, "rooms")
	assert_has(data, "edges")
	assert_has(data, "entry_room_index")
	assert_has(data, "boss_room_index")
	assert_has(data, "element")
	assert_has(data, "difficulty")


func test_to_dict_rooms_is_array() -> void:
	var d := _make_linear_dungeon(3, 2)
	var data: Dictionary = d.to_dict()
	assert_typeof(data["rooms"], TYPE_ARRAY)
	assert_eq(data["rooms"].size(), 3)


func test_to_dict_edges_format() -> void:
	var d := _make_linear_dungeon(3, 2)
	var data: Dictionary = d.to_dict()
	assert_typeof(data["edges"], TYPE_ARRAY)
	assert_eq(data["edges"].size(), 2)
	assert_eq(data["edges"][0], [0, 1])
	assert_eq(data["edges"][1], [1, 2])


func test_to_dict_element_is_int() -> void:
	var d := _make_linear_dungeon(3, 2)
	var data: Dictionary = d.to_dict()
	assert_typeof(data["element"], TYPE_INT)


func test_round_trip_linear() -> void:
	var original := _make_linear_dungeon(3, 2)
	var restored := DungeonData.from_dict(original.to_dict())
	assert_true(restored.validate(), "Restored dungeon should be valid")
	assert_eq(restored.seed_id, original.seed_id)
	assert_eq(restored.rooms.size(), original.rooms.size())
	assert_eq(restored.edges.size(), original.edges.size())
	assert_eq(restored.entry_room_index, original.entry_room_index)
	assert_eq(restored.boss_room_index, original.boss_room_index)
	assert_eq(restored.element, original.element)
	assert_eq(restored.difficulty, original.difficulty)


func test_round_trip_preserves_room_data() -> void:
	var original := _make_linear_dungeon(3, 2)
	original.rooms[1].is_cleared = true
	original.rooms[1].metadata = {"key": "value"}
	var restored := DungeonData.from_dict(original.to_dict())
	assert_true(restored.rooms[1].is_cleared)
	assert_eq(restored.rooms[1].metadata["key"], "value")


func test_round_trip_preserves_edges() -> void:
	var original := _make_branching_dungeon()
	var restored := DungeonData.from_dict(original.to_dict())
	assert_eq(restored.edges.size(), original.edges.size())
	for i in range(original.edges.size()):
		assert_eq(restored.edges[i], original.edges[i])


func test_round_trip_preserves_positions() -> void:
	var original := _make_linear_dungeon(3, 2)
	original.rooms[0].position = Vector2(1.5, -2.7)
	var restored := DungeonData.from_dict(original.to_dict())
	assert_almost_eq(restored.rooms[0].position.x, 1.5, 0.001)
	assert_almost_eq(restored.rooms[0].position.y, -2.7, 0.001)


func test_from_dict_empty() -> void:
	var restored := DungeonData.from_dict({})
	assert_not_null(restored, "from_dict({}) should not return null")
	assert_eq(restored.seed_id, "")
	assert_eq(restored.rooms.size(), 0)


func test_from_dict_caps_room_count() -> void:
	var data: Dictionary = {
		"seed_id": "overflow_test",
		"rooms": [],
		"edges": [],
		"entry_room_index": 0,
		"boss_room_index": -1,
		"element": 0,
		"difficulty": 1,
	}
	for i in range(150):
		data["rooms"].append({"index": i})
	var restored := DungeonData.from_dict(data)
	assert_true(restored.rooms.size() <= 100, "Room count should be capped at 100")


# ---------------------------------------------------------------------------
# Edge Cases
# ---------------------------------------------------------------------------

func test_single_room_boss_dungeon() -> void:
	var d := _make_single_room_dungeon()
	d.boss_room_index = 0
	d.rooms[0].type = Enums.RoomType.BOSS
	assert_true(d.validate())
	assert_true(d.has_boss_room())
	assert_eq(d.get_path_to_boss(), [0])


func test_fully_connected_four_rooms() -> void:
	var d := DungeonData.new()
	d.seed_id = "full_four"
	d.entry_room_index = 0
	d.boss_room_index = 3
	for i in range(4):
		var rtype: Enums.RoomType = Enums.RoomType.BOSS if i == 3 else Enums.RoomType.COMBAT
		d.rooms.append(_make_room(i, rtype))
	d.edges = [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3),
		Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 3),
	]
	assert_true(d.validate())
	var adj: Array[int] = d.get_adjacent(0)
	assert_eq(adj.size(), 3)
	var path: Array[int] = d.get_path_to_boss()
	assert_eq(path, [0, 3])  # Direct connection


func test_large_dungeon_25_rooms() -> void:
	var d := _make_large_dungeon(25)
	assert_true(d.validate())
	assert_eq(d.get_room_count(), 25)
	assert_eq(d.get_edge_count(), 24)
	var path: Array[int] = d.get_path_to_boss()
	assert_eq(path.size(), 25)
	assert_eq(path[0], 0)
	assert_eq(path[24], 24)


func test_clearing_rooms_does_not_affect_graph() -> void:
	var d := _make_linear_dungeon(3, 2)
	for room in d.rooms:
		room.is_cleared = true
	assert_true(d.validate())
	assert_eq(d.get_adjacent(1).size(), 2)
	assert_eq(d.get_path_to_boss(), [0, 1, 2])
```

---

## Section 15 · Playtesting Verification

### PV-01: Generate and Validate 100 Random Dungeons

**Setup**: Use the Procedural Dungeon Generator (TASK-010) or a test harness that creates random `DungeonData` instances with varying room counts (1–25), edge densities, and boss placements.

**Steps**:
1. Generate 100 dungeons with different seeds.
2. Call `validate()` on each.
3. For each valid dungeon with a boss, call `get_path_to_boss()` and verify the path is non-empty and starts at entry.
4. For each valid dungeon, call `get_adjacent()` on every room and verify no room returns itself.

**Expected**: 100% of generated dungeons pass validation. All path and adjacency queries return correct results.

### PV-02: Single-Room Tutorial Dungeon

**Setup**: Create a dungeon with exactly 1 room, no edges, entry=0, boss=-1.

**Steps**:
1. Call `validate()` — should pass.
2. Call `get_adjacent(0)` — should return `[]`.
3. Call `get_path_to_boss()` — should return `[]`.
4. Set `rooms[0].is_cleared = true`.
5. Call `is_fully_cleared()` — should return `true`.
6. Serialize with `to_dict()`, restore with `from_dict()`, re-validate.

**Expected**: All operations behave correctly for the degenerate single-room case.

### PV-03: Maximum-Size Dungeon Stress Test

**Setup**: Create a 25-room dungeon with ~35 edges forming a realistic graph topology (not fully connected).

**Steps**:
1. Validate the dungeon.
2. Call `get_path_to_boss()` and verify it returns a valid path ≤ 25 rooms long.
3. Call `get_adjacent()` on every room and verify the sum of adjacency sizes equals `2 * edge_count`.
4. Serialize and deserialize. Re-validate.
5. Measure wall-clock time for all operations — should be < 1ms total.

**Expected**: All operations complete correctly and quickly. No performance degradation at max size.

### PV-04: Expedition Walkthrough — Full Clear

**Setup**: Create a 5-room linear dungeon with boss at index 4.

**Steps**:
1. Start at entry (room 0). Verify `get_adjacent(0)` returns `[1]`.
2. Move to room 1. Mark room 0 as cleared. Verify `get_uncleared_rooms()` returns `[1, 2, 3, 4]`.
3. Continue clearing rooms in order: 1, 2, 3, 4.
4. After clearing room 3, verify `is_fully_cleared()` is `false`.
5. Clear room 4 (boss). Verify `is_fully_cleared()` is `true`.

**Expected**: The expedition can navigate room-by-room, clearing state updates correctly, and full-clear detection triggers exactly when the last room is cleared.

### PV-05: Save Mid-Expedition and Restore

**Setup**: Create a 5-room dungeon. Clear rooms 0 and 1.

**Steps**:
1. Serialize the dungeon with `to_dict()`.
2. Convert to JSON string and back to Dictionary (simulating file I/O).
3. Restore with `DungeonData.from_dict()`.
4. Verify `rooms[0].is_cleared == true`, `rooms[1].is_cleared == true`, `rooms[2].is_cleared == false`.
5. Verify `get_uncleared_rooms()` returns `[2, 3, 4]`.
6. Verify `validate()` passes.

**Expected**: Partial expedition progress survives serialization round-trip with perfect fidelity.

### PV-06: Corrupted Save Data Resilience

**Setup**: Manually construct a malformed Dictionary with missing keys, negative indices, and invalid edge data.

**Steps**:
1. Call `DungeonData.from_dict({"seed_id": "corrupt"})` — missing rooms/edges.
2. Call `DungeonData.from_dict({"rooms": "not_an_array"})` — wrong type.
3. Call `DungeonData.from_dict({"rooms": [], "edges": [[99, 100]]})` — invalid edges.
4. Verify none of these calls crash the application.
5. Verify the returned objects either have default values or are safely constructed.

**Expected**: `from_dict()` never crashes. Malformed data produces default or degraded objects that fail `validate()` gracefully.

### PV-07: Metadata Extensibility Verification

**Setup**: Create rooms with various metadata configurations.

**Steps**:
1. Create a TRAP room with `metadata = {"trap_type": "spike", "damage": 15, "avoidance_stat": "agility"}`.
2. Create a PUZZLE room with `metadata = {"puzzle_id": "slider_01", "time_limit": 30.0}`.
3. Create a BOSS room with `metadata = {"boss_id": "flame_warden", "phases": [1, 2, 3]}`.
4. Serialize the entire dungeon and restore.
5. Verify all metadata survives round-trip, including nested arrays.

**Expected**: Metadata dictionaries with diverse value types (string, int, float, array) serialize and deserialize correctly.

### PV-08: Dungeon Map UI Data Extraction

**Setup**: Create a 4-room branching dungeon with varied positions and sizes.

**Steps**:
1. Iterate `rooms` and read `position` and `size` for each room — verify all are valid `Vector2` values.
2. Iterate `edges` and for each edge, verify both indices map to valid rooms.
3. Read `entry_room_index` and `boss_room_index` — verify they correspond to expected rooms.
4. For each room, call `get_adjacent()` and verify the count matches the number of edges touching that room.
5. Call `get_path_to_boss()` and visually trace the path through the graph to confirm it is valid and shortest.

**Expected**: All data needed by the Dungeon Map UI is correctly accessible and consistent. The graph can be rendered accurately from the data model alone.

### PV-09: Enum Value Stability Across Serialization

**Setup**: Create rooms using every `Enums.RoomType` value and every `Enums.Currency` value.

**Steps**:
1. Create 6 rooms, one per `RoomType`: COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS.
2. Assign each room a different `loot_bias` from `Enums.Currency`.
3. Serialize the dungeon, restore it.
4. Verify every room's `type` and `loot_bias` match the original enum values after round-trip.

**Expected**: Enum serialization as integers and deserialization back to enum values is lossless for all defined enum members.

---

## Section 16 · Implementation Prompt

### File: `src/models/room_data.gd`

```gdscript
class_name RoomData
extends RefCounted
## A single room node in a dungeon graph.
##
## Carries type, spatial layout, difficulty, loot weighting, clearance state,
## and an extensible metadata dictionary. Owned by DungeonData.


## The index of this room in the parent DungeonData.rooms array.
var index: int = 0

## The functional type of this room (combat, treasure, trap, etc.).
var type: Enums.RoomType = Enums.RoomType.COMBAT

## Abstract 2D position for map layout. Not pixel coordinates.
var position: Vector2 = Vector2.ZERO

## Abstract 2D dimensions for map layout.
var size: Vector2 = Vector2(1.0, 1.0)

## Encounter difficulty rating. Higher means harder enemies/traps.
var difficulty: int = 1

## Which currency type this room's drops are biased toward.
var loot_bias: Enums.Currency = Enums.Currency.GOLD

## Whether this room has been completed during the current expedition.
var is_cleared: bool = false

## Extensible room-specific data (trap config, puzzle ID, boss phases, etc.).
var metadata: Dictionary = {}


## Returns true if this room is a standard combat encounter.
func is_combat() -> bool:
	return type == Enums.RoomType.COMBAT


## Returns true if this room is the dungeon boss.
func is_boss() -> bool:
	return type == Enums.RoomType.BOSS


## Returns true if this room is a rest/recovery room.
func is_rest() -> bool:
	return type == Enums.RoomType.REST


## Serializes this room to a JSON-compatible Dictionary.
func to_dict() -> Dictionary:
	return {
		"index": index,
		"type": int(type),
		"position": {"x": position.x, "y": position.y},
		"size": {"x": size.x, "y": size.y},
		"difficulty": difficulty,
		"loot_bias": int(loot_bias),
		"is_cleared": is_cleared,
		"metadata": metadata.duplicate(true),
	}


## Constructs a RoomData from a Dictionary. Uses safe defaults for missing keys.
static func from_dict(data: Dictionary) -> RoomData:
	var room := RoomData.new()
	room.index = int(data.get("index", 0))
	room.type = int(data.get("type", 0)) as Enums.RoomType
	var pos_data: Variant = data.get("position", {})
	if pos_data is Dictionary:
		room.position = Vector2(
			float(pos_data.get("x", 0.0)),
			float(pos_data.get("y", 0.0))
		)
	var size_data: Variant = data.get("size", {})
	if size_data is Dictionary:
		room.size = Vector2(
			float(size_data.get("x", 1.0)),
			float(size_data.get("y", 1.0))
		)
	room.difficulty = int(data.get("difficulty", 1))
	room.loot_bias = int(data.get("loot_bias", 0)) as Enums.Currency
	room.is_cleared = bool(data.get("is_cleared", false))
	var meta_val: Variant = data.get("metadata", {})
	if meta_val is Dictionary:
		room.metadata = (meta_val as Dictionary).duplicate(true)
	else:
		room.metadata = {}
	return room
```

### File: `src/models/dungeon_data.gd`

```gdscript
class_name DungeonData
extends RefCounted
## A procedurally generated dungeon represented as a connected graph.
##
## Rooms are stored as an indexed array. Edges are stored as Vector2i pairs
## with canonical ordering (a < b). Provides graph traversal operations,
## validation, and JSON-compatible serialization.


## The seed identifier that produced this dungeon.
var seed_id: String = ""

## All rooms in the dungeon, indexed by position in this array.
var rooms: Array[RoomData] = []

## Undirected edges connecting rooms. Each Vector2i(a, b) has a < b.
var edges: Array[Vector2i] = []

## Index of the room where expeditions begin.
var entry_room_index: int = 0

## Index of the boss room, or -1 if no boss exists.
var boss_room_index: int = -1

## The elemental affinity inherited from the seed.
var element: Enums.Element = Enums.Element.NONE

## Global difficulty baseline computed from seed rarity and phase.
var difficulty: int = 1

## Maximum room count accepted by from_dict() to prevent memory abuse.
const MAX_ROOM_COUNT: int = 100

## Maximum edge count accepted by from_dict() to prevent memory abuse.
const MAX_EDGE_COUNT: int = 500


## Returns all room indices directly connected to the given room via edges.
## Returns an empty array if room_index is out of bounds.
func get_adjacent(room_index: int) -> Array[int]:
	var result: Array[int] = []
	if room_index < 0 or room_index >= rooms.size():
		return result
	for edge in edges:
		if edge.x == room_index:
			result.append(edge.y)
		elif edge.y == room_index:
			result.append(edge.x)
	return result


## Returns the shortest path from entry_room_index to boss_room_index
## as an ordered array of room indices (including both endpoints).
## Returns an empty array if there is no boss room or the boss is unreachable.
func get_path_to_boss() -> Array[int]:
	if boss_room_index < 0 or boss_room_index >= rooms.size():
		return []
	if entry_room_index == boss_room_index:
		return [entry_room_index]
	# BFS
	var visited: Dictionary = {}
	var parent: Dictionary = {}
	var queue: Array[int] = []
	queue.append(entry_room_index)
	visited[entry_room_index] = true
	var found: bool = false
	while queue.size() > 0:
		var current: int = queue[0]
		queue.remove_at(0)
		if current == boss_room_index:
			found = true
			break
		var neighbors: Array[int] = get_adjacent(current)
		for neighbor in neighbors:
			if not visited.has(neighbor):
				visited[neighbor] = true
				parent[neighbor] = current
				queue.append(neighbor)
	if not found:
		return []
	# Reconstruct path from boss back to entry
	var path: Array[int] = []
	var step: int = boss_room_index
	while step != entry_room_index:
		path.append(step)
		step = parent[step]
	path.append(entry_room_index)
	path.reverse()
	return path


## Returns indices of all rooms that have not been cleared.
func get_uncleared_rooms() -> Array[int]:
	var result: Array[int] = []
	for i in range(rooms.size()):
		if not rooms[i].is_cleared:
			result.append(i)
	return result


## Returns true only when every room in the dungeon has been cleared.
func is_fully_cleared() -> bool:
	for room in rooms:
		if not room.is_cleared:
			return false
	return true


## Returns the RoomData at the given index, or null if out of bounds.
func get_room(idx: int) -> RoomData:
	if idx < 0 or idx >= rooms.size():
		return null
	return rooms[idx]


## Returns the total number of rooms.
func get_room_count() -> int:
	return rooms.size()


## Returns the total number of edges.
func get_edge_count() -> int:
	return edges.size()


## Returns true if a boss room is designated and its index is valid.
func has_boss_room() -> bool:
	return boss_room_index >= 0 and boss_room_index < rooms.size()


## Validates all graph invariants. Returns true if the dungeon is well-formed.
## Checks: non-empty rooms, valid entry/boss indices, valid edges, canonical
## ordering, no duplicates, no self-loops, connectivity, boss reachability.
func validate() -> bool:
	# At least one room
	if rooms.size() == 0:
		return false
	# Entry room index valid
	if entry_room_index < 0 or entry_room_index >= rooms.size():
		return false
	# Boss room index valid or sentinel
	if boss_room_index != -1:
		if boss_room_index < 0 or boss_room_index >= rooms.size():
			return false
	# Edge validation
	var seen_edges: Dictionary = {}
	for edge in edges:
		# Self-loop check
		if edge.x == edge.y:
			return false
		# Canonical ordering check
		if edge.x >= edge.y:
			return false
		# Bounds check
		if edge.x < 0 or edge.y >= rooms.size():
			return false
		# Duplicate check
		var key: Vector2i = edge
		if seen_edges.has(key):
			return false
		seen_edges[key] = true
	# Connectivity check — BFS from entry must reach all rooms
	var visited: Dictionary = {}
	var queue: Array[int] = []
	queue.append(entry_room_index)
	visited[entry_room_index] = true
	while queue.size() > 0:
		var current: int = queue[0]
		queue.remove_at(0)
		var neighbors: Array[int] = get_adjacent(current)
		for neighbor in neighbors:
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	if visited.size() != rooms.size():
		return false
	# Boss reachability (already guaranteed by full connectivity, but explicit check)
	if boss_room_index >= 0 and not visited.has(boss_room_index):
		return false
	return true


## Serializes the entire dungeon to a JSON-compatible Dictionary.
func to_dict() -> Dictionary:
	var rooms_array: Array = []
	for room in rooms:
		rooms_array.append(room.to_dict())
	var edges_array: Array = []
	for edge in edges:
		edges_array.append([edge.x, edge.y])
	return {
		"seed_id": seed_id,
		"rooms": rooms_array,
		"edges": edges_array,
		"entry_room_index": entry_room_index,
		"boss_room_index": boss_room_index,
		"element": int(element),
		"difficulty": difficulty,
	}


## Constructs a DungeonData from a Dictionary. Uses safe defaults for missing keys.
## Caps room count at MAX_ROOM_COUNT and edge count at MAX_EDGE_COUNT.
static func from_dict(data: Dictionary) -> DungeonData:
	var dungeon := DungeonData.new()
	dungeon.seed_id = str(data.get("seed_id", ""))
	dungeon.entry_room_index = int(data.get("entry_room_index", 0))
	dungeon.boss_room_index = int(data.get("boss_room_index", -1))
	dungeon.element = int(data.get("element", 0)) as Enums.Element
	dungeon.difficulty = int(data.get("difficulty", 1))
	# Deserialize rooms with cap
	var raw_rooms: Variant = data.get("rooms", [])
	if raw_rooms is Array:
		var count: int = mini(raw_rooms.size(), MAX_ROOM_COUNT)
		for i in range(count):
			var room_val: Variant = raw_rooms[i]
			if room_val is Dictionary:
				dungeon.rooms.append(RoomData.from_dict(room_val))
			else:
				dungeon.rooms.append(RoomData.new())
	# Deserialize edges with cap
	var raw_edges: Variant = data.get("edges", [])
	if raw_edges is Array:
		var count: int = mini(raw_edges.size(), MAX_EDGE_COUNT)
		for i in range(count):
			var edge_val: Variant = raw_edges[i]
			if edge_val is Array and edge_val.size() >= 2:
				dungeon.edges.append(Vector2i(int(edge_val[0]), int(edge_val[1])))
	return dungeon
```

---

*End of TASK-005 · Dungeon Room Graph Data Model*
