# TASK-009: Save/Load Manager with Versioned Serialization

| Field              | Value                                                      |
| ------------------ | ---------------------------------------------------------- |
| **Task ID**        | TASK-009                                                   |
| **Title**          | Save/Load Manager with Versioned Serialization             |
| **Epic**           | Dungeon Seed                                               |
| **Stream**         | ⚪ TCH (Technical) — Primary                               |
| **Cross-Stream**   | 🔴 MCH (game state serialization), 🔵 VIS (save slot UI)  |
| **Complexity**     | 8 points (Moderate)                                        |
| **Wave**           | 2                                                          |
| **Dependencies**   | TASK-001 (Project Bootstrap)                               |
| **Dependents**     | TASK-017 (Core Loop Orchestrator)                          |
| **Critical Path**  | ❌ No                                                       |
| **Engine**         | Godot 4.6 — GDScript                                      |
| **Target File**    | `src/services/save_service.gd`                             |
| **Replaces**       | `src/gdscript/utils/save_manager.gd`                      |
| **Author**         | Copilot Game Ticket Writer                                 |
| **Status**         | Draft                                                      |

---

## 1. Header

**Summary:** Implement a production-grade save/load manager (`SaveService`) that serializes and deserializes the complete Dungeon Seed game state to JSON files on disk. The service supports three save slots, version-tagged manifests with forward migration, corruption detection via structural validation, and an autosave trigger hook. It replaces the existing single-slot `save_manager.gd` which lacks migration, multi-slot support, and corruption handling.

**Upstream Contracts:**
- TASK-001 provides the project directory skeleton (`src/services/`), autoload registrations, and the coding conventions (typed GDScript, RefCounted services, signal-driven architecture).
- All domain models (seeds, dungeons, adventurers, inventory, wallet) expose `to_dict() -> Dictionary` and `static from_dict(d: Dictionary) -> Model` by convention established in their respective tasks.

**Downstream Consumers:**
- TASK-017 (Core Loop Orchestrator) calls `save_game()` on autosave intervals and `load_game()` on session start.
- Future cloud-save integration will wrap `SaveService` without modifying its public API.

**Delivery Artifacts:**
- `src/services/save_service.gd` — RefCounted, class_name `SaveService`
- `tests/services/test_save_service.gd` — GUT test suite (20+ test methods)
- Removal/deprecation of `src/gdscript/utils/save_manager.gd`

---

## 2. Description

### 2.1 Problem Statement

Dungeon Seed is a single-player idle/management hybrid where players plant magical seeds that grow into procedural dungeons, recruit adventurers to explore those dungeons, and collect loot to plant better seeds. Game sessions can span days or weeks of real time because seeds grow on real-time or accelerated-time clocks. Losing progress is catastrophic to player engagement — a single corrupted or lost save file can cause a player to abandon the game permanently.

The existing `src/gdscript/utils/save_manager.gd` was written as a prototype and has critical limitations:

1. **Single save slot** — Players cannot experiment with different strategies without overwriting their main save.
2. **No version tagging** — When the save format changes between patches, existing saves silently corrupt or crash on load.
3. **No migration path** — There is no mechanism to transform an old save format into the current one.
4. **No corruption detection** — If the JSON file is truncated (power loss), partially written (crash during save), or manually edited into an invalid state, the loader either crashes or silently loads garbage data.
5. **No autosave hook** — The game loop has no standardized way to trigger periodic saves.
6. **No slot metadata** — There is no way to display save slot information (timestamp, preview) without fully deserializing the entire save file.

These limitations are unacceptable for a shipped product. This task delivers a replacement service that addresses all six deficiencies.

### 2.2 Solution Overview

`SaveService` is a `RefCounted` GDScript class (registered via `class_name SaveService`) that lives in `src/services/save_service.gd`. It is instantiated and owned by the `GameManager` autoload, not registered as an autoload itself. This keeps the autoload layer thin and the service layer testable without engine singletons.

The service exposes six public methods:

| Method | Signature | Purpose |
| --- | --- | --- |
| `save_game` | `(slot: int, game_state: Dictionary) -> bool` | Serialize and write to disk |
| `load_game` | `(slot: int) -> Dictionary` | Read and deserialize from disk |
| `list_slots` | `() -> Array[Dictionary]` | Return metadata for all 3 slots |
| `delete_slot` | `(slot: int) -> bool` | Remove a save file |
| `migrate` | `(data: Dictionary, from_ver: int, to_ver: int) -> Dictionary` | Upgrade old saves |
| `_validate` | `(data: Dictionary) -> bool` | Structural integrity check |

### 2.3 Save Manifest Structure

Every save file is a JSON document with this top-level structure:

```json
{
  "version": 2,
  "timestamp": 1719590400,
  "slot": 1,
  "seeds": [
    {
      "id": "seed_001",
      "type": "fire_oak",
      "planted": true,
      "growth_progress": 0.75,
      "mutations": ["thorny", "luminous"],
      "planted_at": 1719580000,
      "plot_index": 2
    }
  ],
  "dungeon": {
    "active": true,
    "seed_id": "seed_001",
    "rooms": [
      {"id": "room_01", "type": "entrance", "connections": ["room_02"]},
      {"id": "room_02", "type": "combat", "connections": ["room_01", "room_03"]},
      {"id": "room_03", "type": "boss", "connections": ["room_02"]}
    ],
    "explored_rooms": ["room_01", "room_02"],
    "loot_table_seed": 48291
  },
  "adventurers": [
    {
      "id": "adv_001",
      "name": "Thornwick",
      "class": "knight",
      "level": 5,
      "xp": 2400,
      "hp_current": 80,
      "hp_max": 100,
      "equipment": {
        "weapon": "iron_sword",
        "armor": "leather_vest",
        "accessory": null
      },
      "status": "idle"
    }
  ],
  "inventory": {
    "items": {
      "health_potion": 12,
      "fire_shard": 3,
      "ancient_bark": 1
    },
    "capacity": 50
  },
  "wallet": {
    "gold": 1500,
    "gems": 25,
    "essence": 340,
    "dust": 80
  },
  "loop_state": {
    "idle_timer_seconds": 3600.0,
    "active_expeditions": [
      {
        "adventurer_id": "adv_001",
        "dungeon_room": "room_02",
        "started_at": 1719588000,
        "duration_seconds": 1200.0
      }
    ],
    "last_tick_timestamp": 1719590400,
    "auto_harvest_enabled": true
  },
  "settings": {
    "master_volume": 0.8,
    "music_volume": 0.6,
    "sfx_volume": 1.0,
    "screen_shake": true,
    "colorblind_mode": "none",
    "text_size": "medium",
    "auto_save_enabled": true,
    "auto_save_interval_seconds": 300
  }
}
```

### 2.4 Versioning and Migration

The `version` field is an integer that starts at 1 and increments whenever the manifest schema changes. The current version is **2**. The `migrate()` method applies sequential transformations:

- **v1 → v2**: Added `loop_state.auto_harvest_enabled` (default `false`), renamed `player_gold` to `wallet.gold`, added `wallet.gems`, `wallet.essence`, `wallet.dust` (all default `0`), added `settings.colorblind_mode` (default `"none"`), added `settings.text_size` (default `"medium"`).

Migration is always forward-only (old → new), applied step by step (v1→v2, v2→v3, etc.) so each migration function only needs to know about one version delta.

### 2.5 Corruption Detection

`_validate()` performs structural checks without deep semantic validation:

1. Top-level keys `version`, `timestamp`, `slot`, `seeds`, `dungeon`, `adventurers`, `inventory`, `wallet`, `loop_state`, `settings` must all exist.
2. `version` must be an integer between 1 and `CURRENT_VERSION`.
3. `timestamp` must be a positive integer.
4. `slot` must be an integer between 1 and `MAX_SLOTS`.
5. `seeds` must be an Array.
6. `dungeon` must be a Dictionary.
7. `adventurers` must be an Array.
8. `inventory` must be a Dictionary with an `items` key.
9. `wallet` must be a Dictionary.
10. `loop_state` must be a Dictionary.
11. `settings` must be a Dictionary.

If any check fails, `_validate()` returns `false` and `load_game()` returns an empty Dictionary.

### 2.6 File I/O Strategy

- Save path pattern: `user://saves/slot_{N}.json` where N is 1, 2, or 3.
- The `saves/` directory is created on first save if it does not exist.
- Writes use Godot's `FileAccess.open()` with `WRITE` mode. The entire JSON string is written in one `store_string()` call.
- Atomic write safety: write to `slot_{N}.json.tmp` first, then rename to `slot_{N}.json` via `DirAccess.rename()`. This prevents half-written files if the process crashes mid-write.
- Reads use `FileAccess.open()` with `READ` mode and `get_as_text()`.
- JSON parsing uses Godot's built-in `JSON.parse_string()` which returns `null` on invalid JSON.
- File existence is checked via `FileAccess.file_exists()`.

### 2.7 Autosave Hook

`SaveService` does not own the autosave timer — that responsibility belongs to `GameManager` or the Core Loop Orchestrator (TASK-017). However, `SaveService` emits no signals and maintains no internal timer. It is a pure request/response service. The autosave integration pattern is:

```gdscript
# In GameManager or CoreLoopOrchestrator:
var _autosave_timer: float = 0.0
func _process(delta: float) -> void:
    _autosave_timer += delta
    if _autosave_timer >= settings.auto_save_interval_seconds:
        _autosave_timer = 0.0
        save_service.save_game(current_slot, build_game_state())
```

### 2.8 Slot Metadata for UI

`list_slots()` returns lightweight metadata without deserializing the full save:

```gdscript
# Returns:
[
    {"slot": 1, "timestamp": 1719590400, "exists": true},
    {"slot": 2, "timestamp": 0, "exists": false},
    {"slot": 3, "timestamp": 1719500000, "exists": true}
]
```

For slots that exist, it reads only enough of the file to extract `version`, `timestamp`, and `slot`. For the MVP, it reads the full file and extracts these fields — a future optimization could read only the first N bytes.

### 2.9 Error Handling Philosophy

Every public method is designed to never crash. Failure modes return safe defaults:

| Method | Failure Return | When |
| --- | --- | --- |
| `save_game` | `false` | Disk full, permission denied, invalid slot |
| `load_game` | `{}` (empty dict) | File missing, corrupted, validation fails |
| `list_slots` | `[{slot:1,exists:false}, ...]` | Cannot read directory |
| `delete_slot` | `false` | File missing, permission denied |
| `migrate` | Input unchanged | Unknown version range |

All errors are logged via `push_warning()` or `push_error()` for debugging but never surfaced to the player as crashes.

---

## 3. Use Cases

### UC-01: Manual Save to Slot

**Actor:** Player
**Trigger:** Player opens the pause menu and selects "Save Game" → chooses Slot 2.
**Preconditions:** A game session is active with at least one planted seed and one recruited adventurer.
**Flow:**
1. The UI calls `GameManager.request_save(2)`.
2. `GameManager` assembles the current game state Dictionary by calling `to_dict()` on every domain model (SeedManager, DungeonManager, AdventurerRoster, Inventory, Wallet, LoopState, Settings).
3. `GameManager` calls `save_service.save_game(2, game_state)`.
4. `SaveService.save_game()` injects `version = CURRENT_VERSION` and `timestamp = int(Time.get_unix_time_from_system())` into the Dictionary.
5. `SaveService` converts the Dictionary to a JSON string via `JSON.stringify(data, "\t")`.
6. `SaveService` writes the JSON string to `user://saves/slot_2.json.tmp`.
7. `SaveService` renames `slot_2.json.tmp` to `slot_2.json`, atomically replacing any previous file.
8. `SaveService` returns `true`.
9. `GameManager` shows a "Game Saved" toast notification via EventBus.
**Postconditions:** `slot_2.json` exists on disk with valid JSON matching the current schema version.
**Failure Paths:**
- If disk is full, `store_string()` throws an error. `SaveService` catches via return code check, logs `push_error()`, returns `false`. The `.tmp` file is cleaned up. UI shows "Save Failed" toast.
- If slot is out of range (not 1-3), `save_game()` returns `false` immediately with a warning log.

### UC-02: Load Game from Slot with Migration

**Actor:** Player
**Trigger:** Player is on the main menu, selects "Load Game", picks Slot 1 which was saved on a previous game version.
**Preconditions:** `slot_1.json` exists and contains a valid v1 save manifest.
**Flow:**
1. The UI calls `GameManager.request_load(1)`.
2. `GameManager` calls `save_service.load_game(1)`.
3. `SaveService` reads `user://saves/slot_1.json` as text.
4. `SaveService` parses the text as JSON. The result is a Dictionary.
5. `SaveService` reads `data["version"]` and finds it is `1`, which is less than `CURRENT_VERSION` (2).
6. `SaveService` calls `migrate(data, 1, 2)`.
7. `migrate()` applies the v1→v2 transformation: adds `loop_state.auto_harvest_enabled = false`, restructures `player_gold` into the `wallet` sub-dictionary, adds missing `settings` keys.
8. `SaveService` calls `_validate(data)` on the migrated data. Validation passes.
9. `SaveService` returns the migrated Dictionary.
10. `GameManager` passes the Dictionary to each domain model's `from_dict()` to reconstruct live game state.
11. The game session begins with the migrated state.
**Postconditions:** The player's progress is fully restored. New fields added by migration have sensible defaults. The on-disk file is NOT rewritten — it remains v1 until the next save.
**Failure Paths:**
- If migration produces invalid data (a bug in the migration function), `_validate()` catches it. `load_game()` returns `{}`. UI shows "Save file is corrupted" dialog.
- If the JSON file is not valid JSON (truncated), `JSON.parse_string()` returns `null`. `load_game()` returns `{}`.

### UC-03: Autosave During Gameplay

**Actor:** System (timer-driven)
**Trigger:** The autosave interval timer fires (default: every 300 seconds).
**Preconditions:** `settings.auto_save_enabled` is `true`. A game session is active. The player loaded from Slot 1.
**Flow:**
1. `CoreLoopOrchestrator._process()` detects that 300 seconds have elapsed since the last autosave.
2. It assembles the game state Dictionary (same as UC-01 step 2).
3. It calls `save_service.save_game(current_slot, game_state)` where `current_slot` is the slot the player originally loaded from (1).
4. `SaveService` performs the atomic write sequence (same as UC-01 steps 4-8).
5. On success, a subtle "Autosaved" indicator flashes briefly in the HUD corner (handled by EventBus listener in the UI layer, not by SaveService).
**Postconditions:** The save file is updated with the latest game state. The player did not need to take any action.
**Failure Paths:**
- If the save fails, the autosave timer resets and tries again at the next interval. No intrusive error is shown — only a log warning. After 3 consecutive autosave failures, a non-blocking notification warns the player.

### UC-04: View Save Slot List

**Actor:** Player
**Trigger:** Player opens the "Load Game" or "Save Game" screen.
**Preconditions:** The game is at the main menu or pause menu.
**Flow:**
1. The UI calls `save_service.list_slots()`.
2. `SaveService` iterates slots 1 through `MAX_SLOTS` (3).
3. For each slot, it checks `FileAccess.file_exists(path)`.
4. If the file exists, it reads the file, parses JSON, extracts `timestamp`, and builds `{"slot": N, "timestamp": T, "exists": true}`.
5. If the file does not exist or cannot be parsed, it returns `{"slot": N, "timestamp": 0, "exists": false}`.
6. `SaveService` returns the Array of 3 metadata Dictionaries.
7. The UI renders each slot: "Slot 1 — Saved Jan 12, 2025 3:42 PM" or "Slot 2 — Empty".
**Postconditions:** The UI accurately reflects which slots have saves and when they were last written.

### UC-05: Delete a Save Slot

**Actor:** Player
**Trigger:** Player selects a save slot and presses "Delete" with a confirmation dialog.
**Preconditions:** The selected slot has a valid save file.
**Flow:**
1. UI shows confirmation dialog: "Delete Slot 2? This cannot be undone."
2. Player confirms.
3. UI calls `save_service.delete_slot(2)`.
4. `SaveService` constructs the path `user://saves/slot_2.json`.
5. `SaveService` uses `DirAccess.open("user://saves/")` and calls `remove("slot_2.json")`.
6. `SaveService` also removes `slot_2.json.tmp` if it exists (leftover from a failed write).
7. Returns `true`.
8. UI refreshes the slot list.
**Postconditions:** The file no longer exists on disk. `list_slots()` now shows `exists: false` for Slot 2.
**Failure Paths:**
- If the file was already deleted (race condition), `remove()` may fail or the file may not exist. `delete_slot()` returns `true` anyway because the postcondition (file does not exist) is satisfied.

---

## 4. Glossary

| # | Term | Definition |
|---|------|-----------|
| 1 | **Save Manifest** | The top-level JSON Dictionary written to disk, containing all game state plus metadata (`version`, `timestamp`, `slot`). |
| 2 | **Save Slot** | One of three numbered (1-3) independent save file positions. Each slot maps to one file on disk. |
| 3 | **CURRENT_VERSION** | A constant integer in `SaveService` representing the latest save manifest schema version. Currently `2`. |
| 4 | **Migration** | The process of transforming a save manifest from an older schema version to a newer one by applying sequential version-delta functions. |
| 5 | **Atomic Write** | A two-step write strategy (write to `.tmp`, then rename) that prevents half-written files from corrupting saves. |
| 6 | **Structural Validation** | Checking that required keys exist and have the correct types in a loaded Dictionary, without verifying semantic correctness of values. |
| 7 | **RefCounted** | A Godot base class for objects managed by reference counting rather than the scene tree. Used for services that do not need node lifecycle. |
| 8 | **class_name** | A GDScript keyword that registers a script as a globally available type, enabling `SaveService.new()` without preloading. |
| 9 | **user://** | Godot's user data directory path prefix. On Windows: `%APPDATA%/Godot/app_userdata/<project>/`. On Linux: `~/.local/share/godot/app_userdata/<project>/`. |
| 10 | **Game State Dictionary** | A Dictionary assembled by `GameManager` containing all serializable domain model data, ready for `save_game()` to write. |
| 11 | **to_dict() / from_dict()** | A convention where every domain model exposes serialization (`to_dict() -> Dictionary`) and deserialization (`static from_dict(d: Dictionary) -> Model`) methods. |
| 12 | **Autosave** | A system-initiated periodic save triggered by a timer in the game loop, not by player action. |
| 13 | **Slot Metadata** | Lightweight information about a save slot (slot number, timestamp, existence) used for UI display without full deserialization. |
| 14 | **JSON.stringify()** | Godot 4's built-in method to convert a Variant (Dictionary/Array) into a JSON string. Accepts an optional indent parameter. |
| 15 | **JSON.parse_string()** | Godot 4's built-in method to parse a JSON string into a Variant. Returns `null` on parse failure. |
| 16 | **FileAccess** | Godot 4's file I/O class. Replaces Godot 3's `File` class. Uses static methods like `FileAccess.open()`. |
| 17 | **DirAccess** | Godot 4's directory manipulation class. Used for creating directories, renaming files, and deleting files. |
| 18 | **EventBus** | The project's global signal bus autoload (from TASK-001) used for decoupled communication between systems. |
| 19 | **Corruption** | Any state where a save file exists on disk but cannot be loaded as valid game state — truncated JSON, missing keys, wrong types, or nonsensical values. |
| 20 | **Round-trip** | The full cycle of save → load where the loaded data is identical to the saved data. A fundamental correctness property. |

---

## 5. Out of Scope

The following items are explicitly **not** part of this task. They are documented here to prevent scope creep and to clarify boundaries for implementers and reviewers.

| # | Item | Reason |
|---|------|--------|
| 1 | **Cloud save synchronization** | Requires network infrastructure, account system, and conflict resolution. Planned as a separate post-MVP task. `SaveService` writes to local disk only. |
| 2 | **Save file encryption** | Adds complexity and key management overhead. For MVP, save files are plaintext JSON. Security section addresses the risks and mitigations. |
| 3 | **Save file compression** | JSON save files for Dungeon Seed are expected to be under 100KB. Compression is unnecessary and adds a failure mode. |
| 4 | **Save slot count configuration** | `MAX_SLOTS = 3` is hardcoded. A future task may make this configurable, but for MVP three slots is sufficient. |
| 5 | **Save thumbnails / screenshots** | Some games store a screenshot with each save for the load screen. This requires rendering pipeline integration and is a visual polish task, not a serialization task. |
| 6 | **Binary serialization format** | JSON is chosen for debuggability and human readability. Binary formats (MessagePack, Protocol Buffers) are out of scope. |
| 7 | **Undo/redo for saves** | There is no mechanism to revert to a previous version of a save slot. Players can use multiple slots for experimentation. |
| 8 | **Export/import saves** | Sharing save files between players or transferring between devices (beyond cloud sync) is not supported. |
| 9 | **Save file size limits** | No enforcement of maximum file size. If the game state grows extremely large, that is a domain model concern, not a serialization concern. |
| 10 | **Autosave timer ownership** | `SaveService` does not own or manage the autosave timer. It is a stateless service. Timer logic belongs to `CoreLoopOrchestrator` (TASK-017). |
| 11 | **Semantic validation of game state** | `_validate()` checks structural integrity (keys exist, correct types). It does NOT verify that HP values are within range, that inventory quantities are non-negative, or that referenced IDs actually exist. Deep validation is domain model responsibility. |
| 12 | **Settings persistence as separate file** | Settings are stored inside the save manifest, not in a separate `settings.json`. A future task may separate them so settings persist across all save slots. |
| 13 | **Real-time save progress indicator** | No progress bar during save/load. Operations are expected to complete in under 100ms for MVP-sized game states. |
| 14 | **Backward migration (downgrade)** | Migration is forward-only. If a player downgrades the game, old versions cannot read new save formats. This is standard industry practice. |

---

## 6. Functional Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| FR-001 | `SaveService` SHALL be a `RefCounted` class with `class_name SaveService`. | Must | Enables instantiation without preload and keeps it off the scene tree. |
| FR-002 | `SaveService` SHALL define a constant `CURRENT_VERSION: int = 2`. | Must | Single source of truth for the save format version. |
| FR-003 | `SaveService` SHALL define a constant `MAX_SLOTS: int = 3`. | Must | Limits the number of available save slots. |
| FR-004 | `SaveService` SHALL define a constant `SAVE_DIR: String = "user://saves/"`. | Must | Centralizes the save directory path. |
| FR-005 | `save_game(slot: int, game_state: Dictionary) -> bool` SHALL validate that `slot` is between 1 and `MAX_SLOTS` inclusive before proceeding. | Must | Prevents writing to arbitrary paths. |
| FR-006 | `save_game()` SHALL inject `"version": CURRENT_VERSION` into the game state Dictionary before serialization. | Must | Ensures every save file is version-tagged. |
| FR-007 | `save_game()` SHALL inject `"timestamp": int(Time.get_unix_time_from_system())` into the game state Dictionary. | Must | Records when the save was written. |
| FR-008 | `save_game()` SHALL inject `"slot": slot` into the game state Dictionary. | Must | Save file self-identifies its slot for validation. |
| FR-009 | `save_game()` SHALL create the `SAVE_DIR` directory if it does not exist, using `DirAccess.make_dir_recursive_absolute()`. | Must | First save on a fresh install must not fail due to missing directory. |
| FR-010 | `save_game()` SHALL serialize the Dictionary to a JSON string using `JSON.stringify(data, "\t")` (tab-indented). | Must | Human-readable files aid debugging. |
| FR-011 | `save_game()` SHALL write the JSON string to a temporary file `slot_{N}.json.tmp` first. | Must | Atomic write — step 1. |
| FR-012 | `save_game()` SHALL rename the temporary file to `slot_{N}.json` after a successful write. | Must | Atomic write — step 2. |
| FR-013 | `save_game()` SHALL delete the temporary file if the write fails. | Must | Cleanup on failure. |
| FR-014 | `save_game()` SHALL return `true` on success and `false` on any failure. | Must | Caller can react to save failures. |
| FR-015 | `save_game()` SHALL log via `push_error()` on failure with the specific error description. | Must | Debug diagnostics. |
| FR-016 | `load_game(slot: int) -> Dictionary` SHALL validate that `slot` is between 1 and `MAX_SLOTS` inclusive. | Must | Prevents reading from arbitrary paths. |
| FR-017 | `load_game()` SHALL return an empty Dictionary `{}` if the file does not exist. | Must | Missing file is not an error — it means the slot is unused. |
| FR-018 | `load_game()` SHALL read the file as text and parse it with `JSON.parse_string()`. | Must | Leverages Godot's built-in JSON parser. |
| FR-019 | `load_game()` SHALL return `{}` if JSON parsing returns `null`. | Must | Corrupted/truncated files are handled gracefully. |
| FR-020 | `load_game()` SHALL return `{}` if the parsed result is not a Dictionary. | Must | A JSON array or primitive at the top level is invalid. |
| FR-021 | `load_game()` SHALL check the `version` field and call `migrate()` if `version < CURRENT_VERSION`. | Must | Transparent migration on load. |
| FR-022 | `load_game()` SHALL call `_validate()` on the (possibly migrated) data before returning it. | Must | Post-migration validation catches migration bugs. |
| FR-023 | `load_game()` SHALL return `{}` if `_validate()` returns `false`. | Must | Invalid data never reaches the caller. |
| FR-024 | `load_game()` SHALL log via `push_warning()` when returning empty due to corruption or validation failure. | Must | Debug diagnostics. |
| FR-025 | `list_slots() -> Array[Dictionary]` SHALL return exactly `MAX_SLOTS` entries, one per slot. | Must | UI always gets a fixed-size array. |
| FR-026 | Each entry from `list_slots()` SHALL contain keys `slot` (int), `timestamp` (int), and `exists` (bool). | Must | Standardized metadata format. |
| FR-027 | `list_slots()` SHALL set `exists = true` and populate `timestamp` from the file for slots with valid save files. | Must | Accurate slot metadata. |
| FR-028 | `list_slots()` SHALL set `exists = false` and `timestamp = 0` for slots without save files or with corrupted files. | Must | Corrupted files show as empty slots in the UI. |
| FR-029 | `delete_slot(slot: int) -> bool` SHALL validate that `slot` is between 1 and `MAX_SLOTS` inclusive. | Must | Prevents deleting arbitrary files. |
| FR-030 | `delete_slot()` SHALL remove `slot_{N}.json` from the saves directory. | Must | Primary delete action. |
| FR-031 | `delete_slot()` SHALL also remove `slot_{N}.json.tmp` if it exists. | Should | Cleanup leftover temp files. |
| FR-032 | `delete_slot()` SHALL return `true` if the file was successfully removed or did not exist. | Must | Idempotent delete — success means "file is gone". |
| FR-033 | `delete_slot()` SHALL return `false` only if the file exists but cannot be removed. | Must | Distinguishes real errors from no-ops. |
| FR-034 | `migrate(data: Dictionary, from_version: int, to_version: int) -> Dictionary` SHALL apply version-step migrations sequentially from `from_version` to `to_version`. | Must | e.g., v1→v3 applies v1→v2 then v2→v3. |
| FR-035 | `migrate()` SHALL have a dedicated private method for each version step: `_migrate_v1_to_v2(data: Dictionary) -> Dictionary`. | Must | Clean separation of migration logic. |
| FR-036 | `_migrate_v1_to_v2()` SHALL add `loop_state.auto_harvest_enabled = false` if the key is missing. | Must | v2 schema addition. |
| FR-037 | `_migrate_v1_to_v2()` SHALL restructure `player_gold` (int) into `wallet = {"gold": player_gold, "gems": 0, "essence": 0, "dust": 0}`. | Must | v2 schema change: flat currency → wallet object. |
| FR-038 | `_migrate_v1_to_v2()` SHALL add `settings.colorblind_mode = "none"` if the key is missing. | Must | v2 schema addition. |
| FR-039 | `_migrate_v1_to_v2()` SHALL add `settings.text_size = "medium"` if the key is missing. | Must | v2 schema addition. |
| FR-040 | `_migrate_v1_to_v2()` SHALL update `data["version"]` to `2` after applying changes. | Must | Version field must match the schema after migration. |
| FR-041 | `migrate()` SHALL return the data unchanged (with a warning log) if `from_version >= to_version`. | Must | No-op migration for current-version saves. |
| FR-042 | `migrate()` SHALL return the data unchanged (with an error log) if `from_version` is less than 1 or `to_version` exceeds `CURRENT_VERSION`. | Must | Defensive guard against impossible version ranges. |
| FR-043 | `_validate(data: Dictionary) -> bool` SHALL check that all required top-level keys exist: `version`, `timestamp`, `slot`, `seeds`, `dungeon`, `adventurers`, `inventory`, `wallet`, `loop_state`, `settings`. | Must | Structural integrity gate. |
| FR-044 | `_validate()` SHALL check that `version` is an int in range `[1, CURRENT_VERSION]`. | Must | Rejects future/unknown versions. |
| FR-045 | `_validate()` SHALL check that `timestamp` is a positive int. | Must | Rejects nonsensical timestamps. |
| FR-046 | `_validate()` SHALL check that `slot` is an int in range `[1, MAX_SLOTS]`. | Must | Slot self-consistency. |
| FR-047 | `_validate()` SHALL check that `seeds` is an Array. | Must | Type check. |
| FR-048 | `_validate()` SHALL check that `adventurers` is an Array. | Must | Type check. |
| FR-049 | `_validate()` SHALL check that `dungeon`, `inventory`, `wallet`, `loop_state`, `settings` are Dictionaries. | Must | Type check. |
| FR-050 | `_validate()` SHALL check that `inventory` contains an `items` key. | Must | Sub-structure check. |
| FR-051 | `_validate()` SHALL return `false` and log `push_warning()` for the first failed check. | Must | Fail fast with diagnostics. |
| FR-052 | `_get_slot_path(slot: int) -> String` SHALL be a private helper returning `SAVE_DIR + "slot_" + str(slot) + ".json"`. | Should | DRY path construction. |
| FR-053 | `_get_temp_path(slot: int) -> String` SHALL be a private helper returning `_get_slot_path(slot) + ".tmp"`. | Should | DRY temp path construction. |

---

## 7. Non-Functional Requirements

| ID | Requirement | Target | Rationale |
|----|-------------|--------|-----------|
| NFR-001 | `save_game()` SHALL complete in under 100ms for a game state Dictionary with up to 500 seeds, 50 adventurers, and 200 inventory items. | ≤ 100ms | Player should not perceive a save as laggy. Autosave must not cause frame drops. |
| NFR-002 | `load_game()` SHALL complete in under 150ms for the same data scale. | ≤ 150ms | Load screen should feel instant. Migration adds some overhead. |
| NFR-003 | `list_slots()` SHALL complete in under 50ms. | ≤ 50ms | Load/save screen must render immediately. |
| NFR-004 | Save files SHALL be valid UTF-8 JSON, human-readable with tab indentation. | Readability | Aids debugging, modding community, and manual inspection during development. |
| NFR-005 | `SaveService` SHALL have zero scene tree dependencies (no `Node` inheritance, no `_ready()`, no `_process()`). | Decoupled | Enables unit testing without scene tree setup. |
| NFR-006 | `SaveService` SHALL have zero autoload dependencies. | Decoupled | The service does not reference `EventBus`, `GameManager`, or any singleton. It is a pure data service. |
| NFR-007 | All public methods SHALL be fully type-hinted (parameters and return types). | Type Safety | GDScript 4.6 static typing for IDE support and error prevention. |
| NFR-008 | All public methods SHALL be documented with `##` doc comments. | Maintainability | In-editor documentation for future contributors. |
| NFR-009 | `SaveService` SHALL never throw unhandled exceptions or crash the game. | Robustness | All failure modes return safe defaults. Every file I/O operation is guarded. |
| NFR-010 | Save file disk usage SHALL not exceed 200KB per slot for MVP-scale game states. | Disk Budget | JSON with indentation for 500 seeds + 50 adventurers should be well under this. |
| NFR-011 | `SaveService` SHALL be stateless between calls — no cached file handles, no internal game state copy. | Simplicity | Each call is independent. No stale state bugs. |
| NFR-012 | The atomic write strategy SHALL prevent data loss if the game process is killed during a save operation. | Data Safety | The worst case is losing the in-progress save while the previous save remains intact. |
| NFR-013 | `SaveService` SHALL be instantiable in a test harness without Godot project configuration. | Testability | GUT tests can create `SaveService.new()` directly. |
| NFR-014 | `save_game()` SHALL NOT modify the input `game_state` Dictionary beyond injecting `version`, `timestamp`, and `slot`. | Non-destructive | The caller's Dictionary is not corrupted by the save operation. |
| NFR-015 | Migration functions SHALL be idempotent — running migration on already-migrated data SHALL not corrupt it. | Safety | Defensive coding against double-migration bugs. |
| NFR-016 | `SaveService` SHALL use Godot 4.6 API exclusively — no GDNative, no C# interop, no third-party addons. | Portability | Pure GDScript for maximum compatibility. |
| NFR-017 | Log messages SHALL include the slot number and the specific error condition for all warning and error logs. | Debuggability | "SaveService: load_game(2) failed — JSON parse returned null" not "Load failed". |

---

## 8. Designer's Manual

### 8.1 Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                        GameManager                           │
│                     (Autoload / Node)                        │
│                                                              │
│  ┌─────────────┐   ┌──────────────┐   ┌─────────────────┐   │
│  │ SeedManager  │   │ DungeonMgr   │   │ AdventurerRoster│   │
│  └──────┬──────┘   └──────┬───────┘   └────────┬────────┘   │
│         │                 │                     │            │
│         ▼                 ▼                     ▼            │
│  ┌──────────────────────────────────────────────────────┐    │
│  │            build_game_state() -> Dictionary           │    │
│  │  Calls to_dict() on each domain model and merges     │    │
│  └───────────────────────┬──────────────────────────────┘    │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────────────┐    │
│  │                  SaveService                          │    │
│  │               (RefCounted)                            │    │
│  │                                                       │    │
│  │  save_game(slot, state) ──► JSON ──► .tmp ──► .json   │    │
│  │  load_game(slot) ◄──── JSON ◄──── .json               │    │
│  │  migrate(data, from, to) ──► transformed data         │    │
│  │  _validate(data) ──► bool                             │    │
│  │  list_slots() ──► [{slot, timestamp, exists}]         │    │
│  │  delete_slot(slot) ──► bool                           │    │
│  └───────────────────────┬──────────────────────────────┘    │
│                          │                                   │
│                          ▼                                   │
│                   user://saves/                              │
│                   ├── slot_1.json                             │
│                   ├── slot_2.json                             │
│                   └── slot_3.json                             │
└──────────────────────────────────────────────────────────────┘
```

### 8.2 Integration Pattern

`SaveService` is a dependency-injected service, not an autoload. The recommended integration pattern:

```gdscript
# In GameManager (autoload):
class_name GameManager
extends Node

var save_service: SaveService
var current_slot: int = -1

func _ready() -> void:
    save_service = SaveService.new()

func request_save(slot: int) -> bool:
    var state: Dictionary = _build_game_state()
    var success: bool = save_service.save_game(slot, state)
    if success:
        current_slot = slot
        EventBus.game_saved.emit(slot)
    else:
        EventBus.save_failed.emit(slot)
    return success

func request_load(slot: int) -> bool:
    var data: Dictionary = save_service.load_game(slot)
    if data.is_empty():
        EventBus.load_failed.emit(slot)
        return false
    _apply_game_state(data)
    current_slot = slot
    EventBus.game_loaded.emit(slot)
    return true

func _build_game_state() -> Dictionary:
    return {
        "seeds": seed_manager.to_dict(),
        "dungeon": dungeon_manager.to_dict(),
        "adventurers": adventurer_roster.to_dict(),
        "inventory": inventory.to_dict(),
        "wallet": wallet.to_dict(),
        "loop_state": loop_state.to_dict(),
        "settings": settings.to_dict(),
    }

func _apply_game_state(data: Dictionary) -> void:
    seed_manager.from_dict(data.get("seeds", []))
    dungeon_manager.from_dict(data.get("dungeon", {}))
    adventurer_roster.from_dict(data.get("adventurers", []))
    inventory.from_dict(data.get("inventory", {}))
    wallet.from_dict(data.get("wallet", {}))
    loop_state.from_dict(data.get("loop_state", {}))
    settings.from_dict(data.get("settings", {}))
```

### 8.3 Adding a New Save Version

When you need to change the save format:

1. **Increment `CURRENT_VERSION`** in `save_service.gd` from N to N+1.
2. **Add a migration method** `_migrate_vN_to_vN1(data: Dictionary) -> Dictionary`.
3. **Register the migration** in the `migrate()` method's version-step loop.
4. **Update `_validate()`** if new required keys were added.
5. **Add a test** that creates a vN fixture, runs migration, and validates the result.

Example — adding `achievements` to v3:

```gdscript
const CURRENT_VERSION: int = 3

func _migrate_v2_to_v3(data: Dictionary) -> Dictionary:
    if not data.has("achievements"):
        data["achievements"] = []
    data["version"] = 3
    return data
```

Then update `_validate()`:

```gdscript
func _validate(data: Dictionary) -> bool:
    # ... existing checks ...
    if not data.has("achievements"):
        push_warning("SaveService: _validate() failed — missing 'achievements' key")
        return false
    if not (data["achievements"] is Array):
        push_warning("SaveService: _validate() failed — 'achievements' is not an Array")
        return false
    return true
```

### 8.4 Testing in Isolation

`SaveService` can be fully tested without a running game:

```gdscript
# In test file:
var service: SaveService

func before_each() -> void:
    service = SaveService.new()
    _clean_save_directory()

func _clean_save_directory() -> void:
    var dir: DirAccess = DirAccess.open("user://")
    if dir:
        if dir.dir_exists("saves"):
            for file_name in DirAccess.get_files_at("user://saves/"):
                DirAccess.remove_absolute("user://saves/" + file_name)
```

### 8.5 Save File Location by Platform

| Platform | Typical `user://` Path |
|----------|----------------------|
| Windows | `%APPDATA%\Godot\app_userdata\Dungeon Seed\saves\` |
| macOS | `~/Library/Application Support/Godot/app_userdata/Dungeon Seed/saves/` |
| Linux | `~/.local/share/godot/app_userdata/Dungeon Seed/saves/` |
| Android | Internal app storage (not user-accessible without root) |
| iOS | App sandbox container |
| Web (HTML5) | IndexedDB via Emscripten virtual filesystem |

### 8.6 Performance Considerations

JSON serialization in Godot is implemented in C++ behind `JSON.stringify()` and `JSON.parse_string()`, so it is fast for typical game state sizes. For reference:
- 100KB JSON string → stringify: ~5ms, parse: ~8ms (desktop, debug build)
- 500KB JSON string → stringify: ~20ms, parse: ~35ms (desktop, debug build)
- Release builds are approximately 2-3x faster.

For Dungeon Seed MVP, save files should be well under 100KB.

### 8.7 Atomic Write Deep Dive

Why atomic writes matter:

1. Player saves the game. `save_game()` begins writing to `slot_1.json`.
2. At 60% written, the computer loses power (or the OS kills the process).
3. `slot_1.json` now contains 60% valid JSON followed by nothing — the file is corrupted.
4. When the player restarts, `load_game()` tries to parse the file and gets `null` from `JSON.parse_string()`.
5. The player has lost their save.

With atomic writes:
1. `save_game()` writes to `slot_1.json.tmp` instead.
2. Power loss at 60% — `slot_1.json.tmp` is corrupted, but `slot_1.json` (the previous save) is untouched.
3. On restart, `load_game()` reads `slot_1.json` successfully. The player loses at most one save interval of progress.
4. The corrupted `.tmp` file is cleaned up on the next save or delete operation.

### 8.8 Migration Strategy Rationale

Sequential step-by-step migration (v1→v2→v3) rather than direct migration (v1→v3) is chosen because:
- Each migration function is small and testable in isolation.
- Adding v4 only requires writing one new function (`_migrate_v3_to_v4`), not updating N-1 functions.
- The composition is linear: O(N) migrations for a save that is N versions behind.
- For a game with <20 version increments over its lifetime, this is negligible cost.

---

## 9. Assumptions

| # | Assumption | Impact if Wrong |
|---|-----------|-----------------|
| 1 | All domain models (SeedManager, DungeonManager, AdventurerRoster, Inventory, Wallet, LoopState, Settings) implement `to_dict() -> Dictionary` and accept reconstruction from a Dictionary. | `SaveService` cannot serialize/deserialize game state. The `build_game_state()` pattern in GameManager breaks. |
| 2 | Godot's `user://` filesystem is writable on all target platforms (Windows, macOS, Linux, Web). | `save_game()` will always fail. A platform-specific storage abstraction would be needed. |
| 3 | JSON is sufficient for the data types used in game state — no custom Resource types, no circular references, no Object references in the serialized data. | `JSON.stringify()` would fail or produce garbage. Domain models would need custom serializers. |
| 4 | Save file sizes will remain under 200KB for the MVP game scope (≤500 seeds, ≤50 adventurers, ≤200 inventory item types). | Performance NFRs may be violated. Compression or chunked I/O would be needed. |
| 5 | TASK-001 (Project Bootstrap) establishes the `src/services/` directory and the RefCounted service pattern before this task begins. | The file location and class registration approach would need to be improvised. |
| 6 | `Time.get_unix_time_from_system()` returns a valid Unix timestamp on all platforms. | Timestamps in save files would be meaningless. A platform-abstracted time source would be needed. |
| 7 | Godot 4.6's `DirAccess.rename()` performs an atomic rename on the underlying filesystem (POSIX `rename()` on Unix, `MoveFileEx` on Windows). | The atomic write strategy would not actually prevent corruption. An alternative approach (backup + write + delete backup) would be needed. |
| 8 | Players will not run more than one instance of the game simultaneously writing to the same save directory. | Concurrent writes could corrupt save files. File locking would be needed. |
| 9 | Three save slots are sufficient for MVP. No player demand for more slots at launch. | A settings-driven or dynamically growing slot system would need to replace the fixed array. |
| 10 | The game ships with at most ~20 save format versions over its entire lifetime. | Sequential migration performance could become noticeable. A direct-migration or checkpoint-migration approach would be needed. |
| 11 | EventBus signals (`game_saved`, `save_failed`, `game_loaded`, `load_failed`) are defined in TASK-001 or a concurrent task. | GameManager integration code in the Designer's Manual would need adjustment, but `SaveService` itself is unaffected. |
| 12 | The GUT testing framework is installed and configured in the project (from TASK-001). | Tests cannot run. Manual verification would be the fallback. |
| 13 | `JSON.parse_string()` in Godot 4.6 returns `null` on invalid JSON rather than throwing an exception. | Error handling logic in `load_game()` would need a try/catch wrapper instead of a null check. |
| 14 | No other system writes to the `user://saves/` directory. SaveService has exclusive ownership. | File conflicts, unexpected files, or naming collisions could cause bugs. |

---

## 10. Security & Anti-Cheat

### 10.1 Threat Model

Save file manipulation is the **number one cheat vector** for single-player games. Since save files are plaintext JSON stored in a user-accessible directory, any player with a text editor can modify their save. This section documents the threats, their severity, and the mitigations chosen for MVP.

### 10.2 Threat Table

| ID | Threat | Severity | Attack | Mitigation |
|----|--------|----------|--------|-----------|
| SEC-001 | **Currency Inflation** | High | Player edits `wallet.gold` from `1500` to `9999999`. | **MVP: Accept.** Single-player game — cheating only affects the cheater. Structural validation confirms `wallet` is a Dictionary but does not range-check values. Post-MVP: optional HMAC checksum in save file header. |
| SEC-002 | **Stat Manipulation** | High | Player edits `adventurers[0].level` to `99` or `hp_max` to `99999`. | **MVP: Accept.** Same rationale as SEC-001. Domain models can add range validation in their `from_dict()` methods independently of SaveService. |
| SEC-003 | **Save File Injection / Path Traversal** | Critical | Malicious actor crafts a save file with deeply nested JSON or keys containing path traversal characters (`../`). | **Mitigated.** Slot numbers are integers 1-3, hardcoded into the path. No user-supplied string is used in file paths. `_validate()` checks key types. JSON parsing is handled by Godot's C++ implementation which is not vulnerable to injection. |
| SEC-004 | **Denial of Service via Giant Save File** | Medium | Player replaces `slot_1.json` with a 2GB JSON file, causing the game to freeze or OOM on load. | **Mitigated.** Add a file size check in `load_game()` before reading: if `FileAccess.get_length() > MAX_SAVE_SIZE_BYTES` (1MB), reject with a warning. This prevents OOM while allowing generous headroom above the expected 200KB. |
| SEC-005 | **Save File Replacement (Cheat Saves)** | Medium | Player downloads a "perfect save" from the internet and places it in the saves directory. | **MVP: Accept.** Single-player game. The save will load correctly if it passes validation. No competitive integrity concern. |
| SEC-006 | **Timestamp Manipulation** | Low | Player edits `timestamp` to a future date to gain idle progress. | **Partially mitigated.** `SaveService` does not interpret timestamps — it only stores them. The idle progress calculation (TASK-017) should clamp elapsed time to a maximum (e.g., 24 hours) to limit the benefit of timestamp cheating. |
| SEC-007 | **Version Field Tampering** | Medium | Player sets `version` to `0` or `999`, potentially causing migration to crash or skip validation. | **Mitigated.** `_validate()` checks `version` is in range `[1, CURRENT_VERSION]`. `migrate()` also validates the range and returns data unchanged for invalid ranges. |
| SEC-008 | **Race Condition on Concurrent Access** | Low | Two game instances write to the same slot simultaneously. | **MVP: Accept.** Assumption #8 states single-instance operation. OS-level file locking is out of scope. The atomic write strategy minimizes (but does not eliminate) corruption risk. |

### 10.3 MVP Security Philosophy

Dungeon Seed is a **single-player offline game**. The security posture prioritizes:

1. **Data integrity** (preventing accidental corruption) over **anti-tamper** (preventing intentional edits).
2. **Never crashing** on malformed input over detecting every possible cheat.
3. **Player trust** — if a player wants to give themselves 99999 gold in their own single-player game, that is their prerogative. The game should not crash or behave unpredictably as a result.

Post-MVP, if leaderboards or achievements are added, an optional integrity layer (HMAC signature, obfuscated keys) can be added without changing the `SaveService` public API.

### 10.4 File Size Guard Implementation

```gdscript
const MAX_SAVE_SIZE_BYTES: int = 1_048_576  # 1 MB

func load_game(slot: int) -> Dictionary:
    # ... slot validation ...
    var path: String = _get_slot_path(slot)
    if not FileAccess.file_exists(path):
        return {}
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("SaveService: load_game(%d) failed — cannot open file" % slot)
        return {}
    if file.get_length() > MAX_SAVE_SIZE_BYTES:
        push_error("SaveService: load_game(%d) failed — file exceeds %d bytes" % [slot, MAX_SAVE_SIZE_BYTES])
        file.close()
        return {}
    # ... proceed with normal read ...
```

---

## 11. Best Practices

| # | Practice | Rationale |
|---|----------|-----------|
| 1 | **Never trust loaded data.** Always run `_validate()` after parsing, even after migration. | A corrupted file, manual edit, or migration bug could produce structurally invalid data. |
| 2 | **Use atomic writes for every save operation.** Write to `.tmp`, then rename. | Prevents data loss on crash, power failure, or process kill during write. |
| 3 | **Log all failure paths with context.** Include slot number, method name, and specific failure reason. | Debugging save issues in production requires clear diagnostics. Players will report "my save is gone" with no other context. |
| 4 | **Keep SaveService stateless.** No cached data, no open file handles between calls, no internal game state. | Eliminates stale state bugs, simplifies testing, and makes the service thread-safe by nature. |
| 5 | **Version every save file.** Inject `CURRENT_VERSION` on every save, check on every load. | Enables forward migration when the schema changes. Without versioning, old saves silently corrupt. |
| 6 | **Migrate sequentially, one version step at a time.** v1→v2, v2→v3, never v1→v3 directly. | Each step is small, testable, and independently verifiable. Adding a new version only requires one new function. |
| 7 | **Make migration functions idempotent.** Check for key existence before adding defaults. | Protects against double-migration if a bug causes migrate() to be called twice. |
| 8 | **Never modify the caller's Dictionary in `save_game()` beyond the documented injections.** | The caller should not observe unexpected side effects after saving. Use `data.duplicate(true)` if deep copy is needed. |
| 9 | **Clamp slot numbers to valid range in every public method.** | Defense in depth — even if the UI validates, the service should too. Prevents path traversal via slot injection. |
| 10 | **Create the saves directory lazily on first write, not on startup.** | Avoids creating empty directories on fresh installs where the player never saves. Reduces filesystem clutter. |
| 11 | **Return safe defaults (empty Dict, false) instead of throwing exceptions.** | GDScript exception handling is limited. Callers should check return values, not catch exceptions. |
| 12 | **Use `push_error()` for conditions that indicate bugs (migration failure, validation after migration). Use `push_warning()` for conditions that are expected in normal operation (file not found, empty slot).** | Differentiates "something is wrong with the code" from "the user hasn't saved to this slot yet". |
| 13 | **Test with fixture files, not live game state.** Create minimal valid Dictionaries in tests rather than depending on other systems. | Isolates SaveService tests from domain model changes. Tests remain stable even when SeedManager's schema evolves. |
| 14 | **Clean up `.tmp` files in `delete_slot()` and on startup.** | Leftover temp files from crashed saves should not accumulate or confuse the slot listing. |

---

## 12. Troubleshooting

### Issue 1: "Save Failed" — `save_game()` Returns `false`

**Symptoms:** Player clicks Save, the UI shows a failure toast. Console shows `push_error` from SaveService.

**Diagnostic Steps:**
1. Check the Godot console output for the specific error message. It will include the slot number and failure reason.
2. Verify the `user://saves/` directory exists and is writable. On Windows: open `%APPDATA%\Godot\app_userdata\Dungeon Seed\`. On macOS: `~/Library/Application Support/Godot/app_userdata/Dungeon Seed/`.
3. Check available disk space. If the drive is full, `FileAccess.open()` will fail.
4. Check for antivirus software blocking writes to the save directory.
5. Check if a `.tmp` file was left behind — indicates the write succeeded but the rename failed.
6. If the game state Dictionary contains non-serializable types (Resources, Objects, Nodes), `JSON.stringify()` will produce `null` or an error. Verify all values are primitives, Arrays, or Dictionaries.

**Resolution:** Fix the underlying filesystem or data issue. SaveService itself does not need patching unless the error is in the save logic.

### Issue 2: "Save is Corrupted" — `load_game()` Returns Empty Dictionary

**Symptoms:** Player selects a slot that should have a save, but the game reports it as empty or corrupted.

**Diagnostic Steps:**
1. Open the save file in a text editor. Is it valid JSON? Try pasting it into a JSON validator (jsonlint.com).
2. If the file is truncated (e.g., ends mid-object), a crash during save likely occurred. Check for a `.tmp` file — it may contain the last in-progress write.
3. If the JSON is valid but `load_game()` still returns empty, check `_validate()` output. Run the game with verbose logging to see which validation check failed.
4. If the `version` field is lower than `CURRENT_VERSION`, migration should have been applied. Check the migration functions for bugs.
5. If the file was manually edited, ensure all required keys are present and have correct types.

**Resolution:** If the save is truly corrupted beyond recovery, the player must start a new game or use a different slot. There is no repair mechanism in MVP.

### Issue 3: Migration Fails Silently

**Symptoms:** A v1 save loads but has missing data (e.g., wallet shows all zeros when the player had gold).

**Diagnostic Steps:**
1. Check that `_migrate_v1_to_v2()` correctly reads the old field name (`player_gold`) and writes to the new structure (`wallet.gold`).
2. Verify the migration function updates the `version` field to `2`.
3. Check that `migrate()` is actually called — add a temporary `print()` to confirm.
4. Check for key name typos in the migration function.

**Resolution:** Fix the migration function logic. Add a regression test with a v1 fixture file.

### Issue 4: Slot Listing Shows Wrong Data

**Symptoms:** The load screen shows incorrect timestamps, or a slot shows as empty when it has a save.

**Diagnostic Steps:**
1. Verify the save file exists at the expected path (`user://saves/slot_N.json`).
2. Open the file and check that `timestamp` and `slot` fields are present and have correct values.
3. If the file exists but `list_slots()` shows `exists: false`, the JSON parsing may be failing. Open the file in a validator.
4. Check if there are permission issues reading the file.

**Resolution:** Fix the underlying file or parsing issue.

### Issue 5: Autosave Causes Frame Drops

**Symptoms:** The game stutters every 5 minutes (or whatever the autosave interval is).

**Diagnostic Steps:**
1. Profile the `save_game()` call using Godot's built-in profiler. Check if the bottleneck is in Dictionary assembly, JSON stringification, or file I/O.
2. Check the save file size. If it exceeds 500KB, consider optimizing domain model `to_dict()` methods to exclude redundant data.
3. If the issue is file I/O, consider moving the write to a background thread (post-MVP improvement).
4. Check if the autosave is being called more frequently than intended (timer bug).

**Resolution:** For MVP, the save should complete in under 100ms and not cause perceptible frame drops. If it does, optimize the data being serialized, not the SaveService.

### Issue 6: Delete Slot Does Not Free Disk Space

**Symptoms:** After deleting a slot, disk usage for the saves directory does not decrease.

**Diagnostic Steps:**
1. Verify the file was actually deleted — check `user://saves/` manually.
2. Check for leftover `.tmp` files that `delete_slot()` should have cleaned up.
3. On some filesystems, deleted files are not immediately freed if another process has a handle open. Close the game and check again.

**Resolution:** Ensure `delete_slot()` removes both `.json` and `.json.tmp` files. Verify no other code holds a `FileAccess` reference to the deleted file.

---

## 13. Acceptance Criteria

Every criterion must pass for the task to be considered complete. Criteria are grouped by functional area.

### Save Operations

| ID | Criterion | Verification |
|----|-----------|-------------|
| AC-001 | `save_game(1, valid_state)` returns `true` and creates `user://saves/slot_1.json`. | Unit test + manual |
| AC-002 | `save_game(2, valid_state)` creates `slot_2.json`, independent of slot 1. | Unit test |
| AC-003 | `save_game(3, valid_state)` creates `slot_3.json`, independent of slots 1 and 2. | Unit test |
| AC-004 | The saved JSON file contains `"version": 2` (CURRENT_VERSION). | Unit test — parse file and check |
| AC-005 | The saved JSON file contains a `"timestamp"` integer greater than 0. | Unit test — parse file and check |
| AC-006 | The saved JSON file contains `"slot"` matching the slot argument. | Unit test — parse file and check |
| AC-007 | The saved JSON file is valid JSON parseable by `JSON.parse_string()`. | Unit test |
| AC-008 | The saved JSON file is tab-indented (human-readable). | Manual inspection |
| AC-009 | `save_game(0, state)` returns `false` (slot out of range). | Unit test |
| AC-010 | `save_game(4, state)` returns `false` (slot out of range). | Unit test |
| AC-011 | `save_game(-1, state)` returns `false` (slot out of range). | Unit test |
| AC-012 | `save_game()` creates the `user://saves/` directory if it does not exist. | Unit test — delete dir first |
| AC-013 | Overwriting an existing save (same slot) replaces the file contents. | Unit test — save twice, load, check second state |
| AC-014 | `save_game()` does not modify the input Dictionary beyond injecting `version`, `timestamp`, `slot`. | Unit test — compare before/after |

### Load Operations

| ID | Criterion | Verification |
|----|-----------|-------------|
| AC-015 | `load_game(1)` returns the Dictionary that was saved to slot 1. | Unit test — round-trip |
| AC-016 | Round-trip: `save_game(1, state)` then `load_game(1)` produces a Dictionary where all original keys/values match (excluding injected metadata). | Unit test |
| AC-017 | `load_game(2)` on an empty slot (no file) returns `{}`. | Unit test |
| AC-018 | `load_game(1)` on a file containing invalid JSON returns `{}`. | Unit test — write garbage to file |
| AC-019 | `load_game(1)` on a file containing valid JSON that is not a Dictionary (e.g., `[1,2,3]`) returns `{}`. | Unit test |
| AC-020 | `load_game(1)` on a file missing required keys (e.g., no `seeds` key) returns `{}`. | Unit test |
| AC-021 | `load_game(0)` returns `{}` (slot out of range). | Unit test |
| AC-022 | `load_game(4)` returns `{}` (slot out of range). | Unit test |
| AC-023 | `load_game(1)` on a file exceeding `MAX_SAVE_SIZE_BYTES` returns `{}`. | Unit test — write large file |
| AC-024 | `load_game(1)` on a truncated JSON file (simulating crash) returns `{}`. | Unit test |

### Migration

| ID | Criterion | Verification |
|----|-----------|-------------|
| AC-025 | `load_game()` on a v1 save file successfully migrates to v2 and returns valid data. | Unit test with v1 fixture |
| AC-026 | After migration from v1, `wallet.gold` equals the old `player_gold` value. | Unit test |
| AC-027 | After migration from v1, `wallet.gems`, `wallet.essence`, `wallet.dust` are all `0`. | Unit test |
| AC-028 | After migration from v1, `loop_state.auto_harvest_enabled` is `false`. | Unit test |
| AC-029 | After migration from v1, `settings.colorblind_mode` is `"none"`. | Unit test |
| AC-030 | After migration from v1, `settings.text_size` is `"medium"`. | Unit test |
| AC-031 | After migration, the `version` field in the returned Dictionary equals `CURRENT_VERSION`. | Unit test |
| AC-032 | `migrate()` with `from_version == CURRENT_VERSION` returns data unchanged. | Unit test |
| AC-033 | `migrate()` with `from_version > to_version` returns data unchanged. | Unit test |
| AC-034 | `migrate()` with `from_version < 1` returns data unchanged and logs error. | Unit test |
| AC-035 | Migration is idempotent — running `_migrate_v1_to_v2()` on already-v2 data does not corrupt it. | Unit test |

### Validation

| ID | Criterion | Verification |
|----|-----------|-------------|
| AC-036 | `_validate()` returns `true` for a complete, well-formed v2 Dictionary. | Unit test |
| AC-037 | `_validate()` returns `false` when `version` key is missing. | Unit test |
| AC-038 | `_validate()` returns `false` when `seeds` is not an Array. | Unit test |
| AC-039 | `_validate()` returns `false` when `timestamp` is negative. | Unit test |
| AC-040 | `_validate()` returns `false` when `slot` is 0. | Unit test |
| AC-041 | `_validate()` returns `false` when `inventory` lacks `items` key. | Unit test |
| AC-042 | `_validate()` returns `false` when any required top-level key is missing. | Unit test — iterate each key |

### Slot Management

| ID | Criterion | Verification |
|----|-----------|-------------|
| AC-043 | `list_slots()` returns exactly 3 entries when no saves exist (all `exists: false`). | Unit test |
| AC-044 | `list_slots()` returns `exists: true` with correct timestamp for slots with valid save files. | Unit test |
| AC-045 | `list_slots()` returns `exists: false` for slots with corrupted save files. | Unit test |
| AC-046 | `delete_slot(1)` removes `slot_1.json` from disk. | Unit test |
| AC-047 | `delete_slot(1)` returns `true` even if the file does not exist (idempotent). | Unit test |
| AC-048 | `delete_slot(0)` returns `false` (slot out of range). | Unit test |
| AC-049 | `delete_slot()` also removes the `.tmp` file if it exists. | Unit test |
| AC-050 | After `delete_slot(1)`, `list_slots()` shows `exists: false` for slot 1. | Unit test |
| AC-051 | Saving to slot 1, then saving to slot 2, then loading slot 1 returns slot 1's data (not slot 2's). | Unit test — slot independence |

### Code Quality

| ID | Criterion | Verification |
|----|-----------|-------------|
| AC-052 | `SaveService` extends `RefCounted` and has `class_name SaveService`. | Code review |
| AC-053 | All public methods have full type hints (parameters and return types). | Code review |
| AC-054 | All public methods have `##` doc comments. | Code review |
| AC-055 | No autoload dependencies — `SaveService` does not reference any singleton. | Code review / grep |
| AC-056 | `CURRENT_VERSION`, `MAX_SLOTS`, `SAVE_DIR`, `MAX_SAVE_SIZE_BYTES` are constants. | Code review |
| AC-057 | Old `src/gdscript/utils/save_manager.gd` is deleted or deprecated with a comment pointing to `SaveService`. | Code review |
| AC-058 | GUT test file exists at `tests/services/test_save_service.gd` with 20+ test methods. | File exists, test count |
| AC-059 | All tests pass with zero failures and zero errors. | GUT run |

---

## 14. Testing

### 14.1 Test File

**Path:** `tests/services/test_save_service.gd`

```gdscript
extends GutTest
## Tests for SaveService — save/load manager with versioned serialization.
##
## These tests exercise round-trip serialization, corruption handling,
## migration, validation, slot management, and edge cases.

const SAVE_DIR: String = "user://saves/"

var service: SaveService


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _build_valid_state() -> Dictionary:
    return {
        "seeds": [
            {
                "id": "seed_001",
                "type": "fire_oak",
                "planted": true,
                "growth_progress": 0.75,
                "mutations": ["thorny"],
                "planted_at": 1719580000,
                "plot_index": 2,
            }
        ],
        "dungeon": {
            "active": true,
            "seed_id": "seed_001",
            "rooms": [
                {"id": "room_01", "type": "entrance", "connections": ["room_02"]},
                {"id": "room_02", "type": "boss", "connections": ["room_01"]},
            ],
            "explored_rooms": ["room_01"],
            "loot_table_seed": 48291,
        },
        "adventurers": [
            {
                "id": "adv_001",
                "name": "Thornwick",
                "class": "knight",
                "level": 5,
                "xp": 2400,
                "hp_current": 80,
                "hp_max": 100,
                "equipment": {"weapon": "iron_sword", "armor": "leather_vest", "accessory": null},
                "status": "idle",
            }
        ],
        "inventory": {
            "items": {"health_potion": 12, "fire_shard": 3},
            "capacity": 50,
        },
        "wallet": {
            "gold": 1500,
            "gems": 25,
            "essence": 340,
            "dust": 80,
        },
        "loop_state": {
            "idle_timer_seconds": 3600.0,
            "active_expeditions": [],
            "last_tick_timestamp": 1719590400,
            "auto_harvest_enabled": true,
        },
        "settings": {
            "master_volume": 0.8,
            "music_volume": 0.6,
            "sfx_volume": 1.0,
            "screen_shake": true,
            "colorblind_mode": "none",
            "text_size": "medium",
            "auto_save_enabled": true,
            "auto_save_interval_seconds": 300,
        },
    }


func _build_v1_state() -> Dictionary:
    return {
        "version": 1,
        "timestamp": 1719500000,
        "slot": 1,
        "seeds": [{"id": "seed_001", "type": "fire_oak", "planted": true, "growth_progress": 0.5, "mutations": [], "planted_at": 1719400000, "plot_index": 0}],
        "dungeon": {"active": false, "seed_id": "", "rooms": [], "explored_rooms": [], "loot_table_seed": 0},
        "adventurers": [],
        "inventory": {"items": {}, "capacity": 30},
        "player_gold": 750,
        "loop_state": {"idle_timer_seconds": 0.0, "active_expeditions": [], "last_tick_timestamp": 1719500000},
        "settings": {"master_volume": 1.0, "music_volume": 1.0, "sfx_volume": 1.0, "screen_shake": true, "auto_save_enabled": false, "auto_save_interval_seconds": 300},
    }


func _clean_saves() -> void:
    var dir: DirAccess = DirAccess.open("user://")
    if dir == null:
        return
    if not dir.dir_exists("saves"):
        return
    var files: PackedStringArray = DirAccess.get_files_at(SAVE_DIR)
    for file_name in files:
        DirAccess.remove_absolute(SAVE_DIR + file_name)


func _write_raw_file(path: String, content: String) -> void:
    var dir: DirAccess = DirAccess.open("user://")
    if dir and not dir.dir_exists("saves"):
        dir.make_dir("saves")
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file:
        file.store_string(content)
        file.close()


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func before_each() -> void:
    service = SaveService.new()
    _clean_saves()


func after_each() -> void:
    _clean_saves()


# ---------------------------------------------------------------------------
# save_game tests
# ---------------------------------------------------------------------------

func test_save_game_returns_true_on_success() -> void:
    var state: Dictionary = _build_valid_state()
    var result: bool = service.save_game(1, state)
    assert_true(result, "save_game should return true on success")


func test_save_game_creates_file_on_disk() -> void:
    var state: Dictionary = _build_valid_state()
    service.save_game(1, state)
    assert_true(FileAccess.file_exists(SAVE_DIR + "slot_1.json"), "slot_1.json should exist")


func test_save_game_file_is_valid_json() -> void:
    var state: Dictionary = _build_valid_state()
    service.save_game(1, state)
    var file: FileAccess = FileAccess.open(SAVE_DIR + "slot_1.json", FileAccess.READ)
    var text: String = file.get_as_text()
    file.close()
    var parsed: Variant = JSON.parse_string(text)
    assert_not_null(parsed, "Saved file should be valid JSON")
    assert_true(parsed is Dictionary, "Parsed JSON should be a Dictionary")


func test_save_game_injects_version() -> void:
    var state: Dictionary = _build_valid_state()
    service.save_game(1, state)
    var loaded: Dictionary = service.load_game(1)
    assert_eq(loaded["version"], SaveService.CURRENT_VERSION, "version should be CURRENT_VERSION")


func test_save_game_injects_timestamp() -> void:
    var state: Dictionary = _build_valid_state()
    service.save_game(1, state)
    var loaded: Dictionary = service.load_game(1)
    assert_true(loaded["timestamp"] is float or loaded["timestamp"] is int, "timestamp should be numeric")
    assert_true(loaded["timestamp"] > 0, "timestamp should be positive")


func test_save_game_injects_slot_number() -> void:
    var state: Dictionary = _build_valid_state()
    service.save_game(2, state)
    var loaded: Dictionary = service.load_game(2)
    assert_eq(loaded["slot"], 2, "slot should match the save slot argument")


func test_save_game_slot_zero_returns_false() -> void:
    var state: Dictionary = _build_valid_state()
    assert_false(service.save_game(0, state), "slot 0 should be rejected")


func test_save_game_slot_four_returns_false() -> void:
    var state: Dictionary = _build_valid_state()
    assert_false(service.save_game(4, state), "slot 4 should be rejected")


func test_save_game_slot_negative_returns_false() -> void:
    var state: Dictionary = _build_valid_state()
    assert_false(service.save_game(-1, state), "negative slot should be rejected")


func test_save_game_creates_directory_if_missing() -> void:
    _clean_saves()
    var dir: DirAccess = DirAccess.open("user://")
    if dir and dir.dir_exists("saves"):
        dir.remove("saves")
    var state: Dictionary = _build_valid_state()
    var result: bool = service.save_game(1, state)
    assert_true(result, "save should succeed even when saves dir is missing")
    assert_true(FileAccess.file_exists(SAVE_DIR + "slot_1.json"), "file should be created")


func test_save_game_overwrites_existing_save() -> void:
    var state_a: Dictionary = _build_valid_state()
    state_a["wallet"]["gold"] = 100
    service.save_game(1, state_a)
    var state_b: Dictionary = _build_valid_state()
    state_b["wallet"]["gold"] = 9999
    service.save_game(1, state_b)
    var loaded: Dictionary = service.load_game(1)
    assert_eq(loaded["wallet"]["gold"], 9999, "second save should overwrite first")


func test_save_game_does_not_mutate_input_beyond_metadata() -> void:
    var state: Dictionary = _build_valid_state()
    var original_keys: Array = state.keys().duplicate()
    service.save_game(1, state)
    for key in original_keys:
        assert_true(state.has(key), "original key '%s' should still exist" % key)


func test_save_game_no_tmp_file_left_on_success() -> void:
    var state: Dictionary = _build_valid_state()
    service.save_game(1, state)
    assert_false(FileAccess.file_exists(SAVE_DIR + "slot_1.json.tmp"), "tmp file should not exist after success")


# ---------------------------------------------------------------------------
# load_game tests
# ---------------------------------------------------------------------------

func test_load_game_round_trip() -> void:
    var state: Dictionary = _build_valid_state()
    service.save_game(1, state)
    var loaded: Dictionary = service.load_game(1)
    assert_eq(loaded["wallet"]["gold"], 1500, "gold should round-trip")
    assert_eq(loaded["seeds"].size(), 1, "seeds array should round-trip")
    assert_eq(loaded["seeds"][0]["id"], "seed_001", "seed id should round-trip")
    assert_eq(loaded["adventurers"][0]["name"], "Thornwick", "adventurer name should round-trip")
    assert_eq(loaded["inventory"]["items"]["health_potion"], 12, "inventory should round-trip")
    assert_eq(loaded["settings"]["master_volume"], 0.8, "settings should round-trip")


func test_load_game_empty_slot_returns_empty_dict() -> void:
    var loaded: Dictionary = service.load_game(2)
    assert_true(loaded.is_empty(), "loading empty slot should return {}")


func test_load_game_invalid_json_returns_empty_dict() -> void:
    _write_raw_file(SAVE_DIR + "slot_1.json", "this is not json {{{")
    var loaded: Dictionary = service.load_game(1)
    assert_true(loaded.is_empty(), "invalid JSON should return {}")


func test_load_game_truncated_json_returns_empty_dict() -> void:
    _write_raw_file(SAVE_DIR + "slot_1.json", '{"version": 2, "timestamp": 123, "slot": 1, "seeds": [')
    var loaded: Dictionary = service.load_game(1)
    assert_true(loaded.is_empty(), "truncated JSON should return {}")


func test_load_game_json_array_returns_empty_dict() -> void:
    _write_raw_file(SAVE_DIR + "slot_1.json", '[1, 2, 3]')
    var loaded: Dictionary = service.load_game(1)
    assert_true(loaded.is_empty(), "JSON array at root should return {}")


func test_load_game_missing_keys_returns_empty_dict() -> void:
    _write_raw_file(SAVE_DIR + "slot_1.json", '{"version": 2, "timestamp": 100, "slot": 1}')
    var loaded: Dictionary = service.load_game(1)
    assert_true(loaded.is_empty(), "missing required keys should return {}")


func test_load_game_slot_zero_returns_empty_dict() -> void:
    var loaded: Dictionary = service.load_game(0)
    assert_true(loaded.is_empty(), "slot 0 should return {}")


func test_load_game_slot_four_returns_empty_dict() -> void:
    var loaded: Dictionary = service.load_game(4)
    assert_true(loaded.is_empty(), "slot 4 should return {}")


func test_load_game_oversized_file_returns_empty_dict() -> void:
    var big_content: String = '{"version": 2, "padding": "' + "X".repeat(2_000_000) + '"}'
    _write_raw_file(SAVE_DIR + "slot_1.json", big_content)
    var loaded: Dictionary = service.load_game(1)
    assert_true(loaded.is_empty(), "oversized file should return {}")


# ---------------------------------------------------------------------------
# Migration tests
# ---------------------------------------------------------------------------

func test_migrate_v1_to_v2_creates_wallet() -> void:
    var v1_data: Dictionary = _build_v1_state()
    var migrated: Dictionary = service.migrate(v1_data, 1, 2)
    assert_true(migrated.has("wallet"), "migrated data should have wallet")
    assert_eq(migrated["wallet"]["gold"], 750, "wallet.gold should equal old player_gold")
    assert_eq(migrated["wallet"]["gems"], 0, "wallet.gems should default to 0")
    assert_eq(migrated["wallet"]["essence"], 0, "wallet.essence should default to 0")
    assert_eq(migrated["wallet"]["dust"], 0, "wallet.dust should default to 0")


func test_migrate_v1_to_v2_adds_auto_harvest() -> void:
    var v1_data: Dictionary = _build_v1_state()
    var migrated: Dictionary = service.migrate(v1_data, 1, 2)
    assert_true(migrated["loop_state"].has("auto_harvest_enabled"), "should have auto_harvest_enabled")
    assert_false(migrated["loop_state"]["auto_harvest_enabled"], "auto_harvest_enabled should default to false")


func test_migrate_v1_to_v2_adds_colorblind_mode() -> void:
    var v1_data: Dictionary = _build_v1_state()
    var migrated: Dictionary = service.migrate(v1_data, 1, 2)
    assert_eq(migrated["settings"]["colorblind_mode"], "none", "colorblind_mode should default to none")


func test_migrate_v1_to_v2_adds_text_size() -> void:
    var v1_data: Dictionary = _build_v1_state()
    var migrated: Dictionary = service.migrate(v1_data, 1, 2)
    assert_eq(migrated["settings"]["text_size"], "medium", "text_size should default to medium")


func test_migrate_v1_to_v2_updates_version() -> void:
    var v1_data: Dictionary = _build_v1_state()
    var migrated: Dictionary = service.migrate(v1_data, 1, 2)
    assert_eq(migrated["version"], 2, "version should be updated to 2")


func test_migrate_same_version_returns_unchanged() -> void:
    var v2_data: Dictionary = _build_valid_state()
    v2_data["version"] = 2
    var result: Dictionary = service.migrate(v2_data, 2, 2)
    assert_eq(result, v2_data, "same-version migration should return data unchanged")


func test_migrate_higher_from_returns_unchanged() -> void:
    var data: Dictionary = _build_valid_state()
    data["version"] = 3
    var result: Dictionary = service.migrate(data, 3, 2)
    assert_eq(result["version"], 3, "higher from_version should not change data")


func test_migrate_invalid_from_returns_unchanged() -> void:
    var data: Dictionary = _build_valid_state()
    data["version"] = 0
    var result: Dictionary = service.migrate(data, 0, 2)
    assert_eq(result["version"], 0, "invalid from_version should not change data")


func test_migrate_idempotent_on_v2_data() -> void:
    var v2_data: Dictionary = _build_valid_state()
    v2_data["version"] = 2
    v2_data["timestamp"] = 1719590400
    v2_data["slot"] = 1
    var before_gold: int = v2_data["wallet"]["gold"]
    service.migrate(v2_data, 1, 2)
    assert_eq(v2_data["wallet"]["gold"], before_gold, "migration should not corrupt existing wallet")


func test_load_game_auto_migrates_v1() -> void:
    var v1_data: Dictionary = _build_v1_state()
    var json_text: String = JSON.stringify(v1_data, "\t")
    _write_raw_file(SAVE_DIR + "slot_1.json", json_text)
    var loaded: Dictionary = service.load_game(1)
    assert_false(loaded.is_empty(), "v1 save should load successfully after migration")
    assert_eq(loaded["version"], SaveService.CURRENT_VERSION, "version should be migrated to current")
    assert_true(loaded.has("wallet"), "wallet should exist after migration")


# ---------------------------------------------------------------------------
# Validation tests
# ---------------------------------------------------------------------------

func test_validate_valid_data_returns_true() -> void:
    var data: Dictionary = _build_valid_state()
    data["version"] = 2
    data["timestamp"] = 1719590400
    data["slot"] = 1
    assert_true(service._validate(data), "valid data should pass validation")


func test_validate_missing_version_returns_false() -> void:
    var data: Dictionary = _build_valid_state()
    data["timestamp"] = 100
    data["slot"] = 1
    data.erase("version")
    assert_false(service._validate(data), "missing version should fail")


func test_validate_missing_seeds_returns_false() -> void:
    var data: Dictionary = _build_valid_state()
    data["version"] = 2
    data["timestamp"] = 100
    data["slot"] = 1
    data.erase("seeds")
    assert_false(service._validate(data), "missing seeds should fail")


func test_validate_seeds_not_array_returns_false() -> void:
    var data: Dictionary = _build_valid_state()
    data["version"] = 2
    data["timestamp"] = 100
    data["slot"] = 1
    data["seeds"] = "not an array"
    assert_false(service._validate(data), "seeds as string should fail")


func test_validate_negative_timestamp_returns_false() -> void:
    var data: Dictionary = _build_valid_state()
    data["version"] = 2
    data["timestamp"] = -100
    data["slot"] = 1
    assert_false(service._validate(data), "negative timestamp should fail")


func test_validate_slot_zero_returns_false() -> void:
    var data: Dictionary = _build_valid_state()
    data["version"] = 2
    data["timestamp"] = 100
    data["slot"] = 0
    assert_false(service._validate(data), "slot 0 should fail")


func test_validate_slot_too_high_returns_false() -> void:
    var data: Dictionary = _build_valid_state()
    data["version"] = 2
    data["timestamp"] = 100
    data["slot"] = 99
    assert_false(service._validate(data), "slot 99 should fail")


func test_validate_inventory_missing_items_returns_false() -> void:
    var data: Dictionary = _build_valid_state()
    data["version"] = 2
    data["timestamp"] = 100
    data["slot"] = 1
    data["inventory"] = {"capacity": 50}
    assert_false(service._validate(data), "inventory without items should fail")


func test_validate_version_too_high_returns_false() -> void:
    var data: Dictionary = _build_valid_state()
    data["version"] = 999
    data["timestamp"] = 100
    data["slot"] = 1
    assert_false(service._validate(data), "version 999 should fail")


func test_validate_version_zero_returns_false() -> void:
    var data: Dictionary = _build_valid_state()
    data["version"] = 0
    data["timestamp"] = 100
    data["slot"] = 1
    assert_false(service._validate(data), "version 0 should fail")


# ---------------------------------------------------------------------------
# Slot management tests
# ---------------------------------------------------------------------------

func test_list_slots_empty_returns_three_entries() -> void:
    var slots: Array[Dictionary] = service.list_slots()
    assert_eq(slots.size(), 3, "should return exactly 3 entries")
    for entry in slots:
        assert_false(entry["exists"], "all slots should show as not existing")
        assert_eq(entry["timestamp"], 0, "timestamp should be 0 for empty slots")


func test_list_slots_with_one_save() -> void:
    var state: Dictionary = _build_valid_state()
    service.save_game(2, state)
    var slots: Array[Dictionary] = service.list_slots()
    assert_false(slots[0]["exists"], "slot 1 should not exist")
    assert_true(slots[1]["exists"], "slot 2 should exist")
    assert_false(slots[2]["exists"], "slot 3 should not exist")
    assert_true(slots[1]["timestamp"] > 0, "slot 2 timestamp should be positive")


func test_list_slots_corrupted_file_shows_not_exists() -> void:
    _write_raw_file(SAVE_DIR + "slot_1.json", "corrupted garbage data not json")
    var slots: Array[Dictionary] = service.list_slots()
    assert_false(slots[0]["exists"], "corrupted slot should show as not existing")


func test_delete_slot_removes_file() -> void:
    var state: Dictionary = _build_valid_state()
    service.save_game(1, state)
    assert_true(FileAccess.file_exists(SAVE_DIR + "slot_1.json"), "file should exist before delete")
    service.delete_slot(1)
    assert_false(FileAccess.file_exists(SAVE_DIR + "slot_1.json"), "file should not exist after delete")


func test_delete_slot_idempotent() -> void:
    var result: bool = service.delete_slot(1)
    assert_true(result, "deleting non-existent slot should return true")


func test_delete_slot_out_of_range_returns_false() -> void:
    assert_false(service.delete_slot(0), "slot 0 should return false")
    assert_false(service.delete_slot(4), "slot 4 should return false")


func test_delete_slot_removes_tmp_file() -> void:
    _write_raw_file(SAVE_DIR + "slot_1.json.tmp", "leftover temp data")
    service.delete_slot(1)
    assert_false(FileAccess.file_exists(SAVE_DIR + "slot_1.json.tmp"), "tmp file should be cleaned up")


func test_delete_then_list_shows_empty() -> void:
    var state: Dictionary = _build_valid_state()
    service.save_game(1, state)
    service.delete_slot(1)
    var slots: Array[Dictionary] = service.list_slots()
    assert_false(slots[0]["exists"], "deleted slot should show as not existing")


# ---------------------------------------------------------------------------
# Slot independence tests
# ---------------------------------------------------------------------------

func test_slots_are_independent() -> void:
    var state_a: Dictionary = _build_valid_state()
    state_a["wallet"]["gold"] = 111
    service.save_game(1, state_a)
    var state_b: Dictionary = _build_valid_state()
    state_b["wallet"]["gold"] = 222
    service.save_game(2, state_b)
    var state_c: Dictionary = _build_valid_state()
    state_c["wallet"]["gold"] = 333
    service.save_game(3, state_c)
    var loaded_a: Dictionary = service.load_game(1)
    var loaded_b: Dictionary = service.load_game(2)
    var loaded_c: Dictionary = service.load_game(3)
    assert_eq(loaded_a["wallet"]["gold"], 111, "slot 1 should have 111 gold")
    assert_eq(loaded_b["wallet"]["gold"], 222, "slot 2 should have 222 gold")
    assert_eq(loaded_c["wallet"]["gold"], 333, "slot 3 should have 333 gold")


func test_overwrite_one_slot_does_not_affect_others() -> void:
    var state: Dictionary = _build_valid_state()
    state["wallet"]["gold"] = 500
    service.save_game(1, state)
    service.save_game(2, state)
    var updated_state: Dictionary = _build_valid_state()
    updated_state["wallet"]["gold"] = 9999
    service.save_game(1, updated_state)
    var loaded_2: Dictionary = service.load_game(2)
    assert_eq(loaded_2["wallet"]["gold"], 500, "slot 2 should be unaffected by slot 1 overwrite")
```

---

## 15. Playtesting Verification

These verification steps are performed by a human playtester in a running Godot build, not by automated tests. They confirm end-to-end behavior through the game's UI and actual gameplay.

| # | Verification Step | Expected Outcome | Pass/Fail |
|---|------------------|-----------------|-----------|
| PV-01 | Start a new game. Plant a seed and recruit an adventurer. Open the pause menu and save to Slot 1. Close the game completely. Reopen the game and load Slot 1. | The planted seed and recruited adventurer are present with correct state. Growth progress reflects the saved value. | ☐ |
| PV-02 | With a game loaded from Slot 1, make significant progress (grow seed to maturity, complete an expedition, collect loot). Save to Slot 2 without overwriting Slot 1. Load Slot 1. | Slot 1 reflects the earlier state (before the new progress). Loading Slot 2 afterwards reflects the later state. The two slots are fully independent. | ☐ |
| PV-03 | Let the game autosave (wait for the configured interval, default 5 minutes). While the autosave occurs, verify the game does not freeze, stutter, or display any visual glitch. | Autosave completes silently. A small "Autosaved" indicator may flash. No frame drops are perceptible. | ☐ |
| PV-04 | Open the Save/Load screen. Verify that each slot shows the correct status: either "Empty" or a human-readable timestamp (e.g., "Jan 12, 2025 3:42 PM"). Save to Slot 3. Verify the slot list updates to show Slot 3 as occupied. | All three slots display accurate metadata. The newly saved slot immediately reflects its saved state. | ☐ |
| PV-05 | Select a save slot with data and press "Delete". Confirm the deletion dialog. Verify the slot now shows as "Empty" in the list. Attempt to load the deleted slot. | The slot is empty. Loading it does nothing (no crash, no error dialog — the Load button is disabled for empty slots, or the attempt is silently ignored). | ☐ |
| PV-06 | Navigate to the save directory on disk (`%APPDATA%\Godot\app_userdata\Dungeon Seed\saves\` on Windows). Open `slot_1.json` in a text editor. Manually corrupt it by deleting the last 50 characters (simulating a truncated write). Open the game and attempt to load Slot 1. | The game reports "Save file is corrupted" or shows the slot as empty. The game does not crash. Other slots are unaffected. | ☐ |
| PV-07 | With a game running, navigate to the save directory and manually edit `slot_1.json` — change `wallet.gold` to `99999999`. Load Slot 1 in-game. | The game loads successfully with the modified gold value (single-player, no anti-tamper for MVP). The game does not crash or display errors. All other data is intact. | ☐ |
| PV-08 | Create a v1 save fixture file by manually writing a JSON file with `"version": 1` and the old v1 schema (includes `player_gold` instead of `wallet`). Place it as `slot_1.json`. Load it in-game. | The game detects the old version, migrates it to v2, and loads correctly. `wallet.gold` equals the old `player_gold`. New fields have sensible defaults. | ☐ |
| PV-09 | Save to all three slots. Close the game. Re-open and verify all three slots show correct timestamps and can be loaded independently. | Three independent saves persist across game restarts. Each loads the correct state. | ☐ |
| PV-10 | While the game is saving (trigger a save on a very large game state, or add a breakpoint/delay for testing), force-kill the game process (Task Manager → End Process). Re-open the game and load the slot. | The previous save is intact (atomic write protects it). At worst, the save from the interrupted attempt is lost, but no data corruption occurs. A `.tmp` file may exist and is cleaned up on next save. | ☐ |

---

## 16. Implementation Prompt

### 16.1 Complete Implementation: `src/services/save_service.gd`

```gdscript
class_name SaveService
extends RefCounted
## Manages saving and loading game state to JSON files on disk.
##
## Supports multiple save slots, version-tagged manifests with forward
## migration, structural validation, and atomic writes to prevent corruption.
## This service is stateless — it holds no cached data between calls.

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## The current save manifest schema version. Increment when the format changes.
const CURRENT_VERSION: int = 2

## Maximum number of save slots available to the player.
const MAX_SLOTS: int = 3

## Directory path under user:// where save files are stored.
const SAVE_DIR: String = "user://saves/"

## Maximum allowed save file size in bytes (1 MB). Files larger than this
## are rejected to prevent out-of-memory conditions from malicious or
## corrupted files.
const MAX_SAVE_SIZE_BYTES: int = 1_048_576

## Required top-level keys in a valid save manifest.
const REQUIRED_KEYS: PackedStringArray = PackedStringArray([
	"version",
	"timestamp",
	"slot",
	"seeds",
	"dungeon",
	"adventurers",
	"inventory",
	"wallet",
	"loop_state",
	"settings",
])


# ---------------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------------

## Serializes [param game_state] to JSON and writes it to the specified
## [param slot] (1 through MAX_SLOTS). Injects version, timestamp, and slot
## metadata before writing. Returns [code]true[/code] on success,
## [code]false[/code] on any failure.
func save_game(slot: int, game_state: Dictionary) -> bool:
	if not _is_valid_slot(slot):
		push_warning("SaveService: save_game(%d) failed — slot out of range [1, %d]" % [slot, MAX_SLOTS])
		return false

	# Ensure save directory exists
	if not _ensure_save_directory():
		push_error("SaveService: save_game(%d) failed — cannot create save directory" % slot)
		return false

	# Inject metadata
	game_state["version"] = CURRENT_VERSION
	game_state["timestamp"] = int(Time.get_unix_time_from_system())
	game_state["slot"] = slot

	# Serialize to JSON
	var json_text: String = JSON.stringify(game_state, "\t")
	if json_text.is_empty():
		push_error("SaveService: save_game(%d) failed — JSON.stringify returned empty string" % slot)
		return false

	# Atomic write: write to temp file first, then rename
	var temp_path: String = _get_temp_path(slot)
	var final_path: String = _get_slot_path(slot)

	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: save_game(%d) failed — cannot open temp file: %s" % [slot, temp_path])
		return false

	file.store_string(json_text)
	file.close()

	# Rename temp to final (atomic on most filesystems)
	var dir: DirAccess = DirAccess.open(SAVE_DIR)
	if dir == null:
		push_error("SaveService: save_game(%d) failed — cannot open save directory for rename" % slot)
		_remove_file(temp_path)
		return false

	# Remove existing final file if present (rename may fail if target exists on some OS)
	if FileAccess.file_exists(final_path):
		dir.remove(_file_name_from_path(final_path))

	var rename_error: int = dir.rename(_file_name_from_path(temp_path), _file_name_from_path(final_path))
	if rename_error != OK:
		push_error("SaveService: save_game(%d) failed — rename error code %d" % [slot, rename_error])
		_remove_file(temp_path)
		return false

	return true


## Loads and deserializes the save file from the specified [param slot].
## Returns the game state Dictionary on success, or an empty Dictionary
## on any failure (missing file, corrupted data, validation failure).
## Automatically migrates old save versions to CURRENT_VERSION.
func load_game(slot: int) -> Dictionary:
	if not _is_valid_slot(slot):
		push_warning("SaveService: load_game(%d) failed — slot out of range [1, %d]" % [slot, MAX_SLOTS])
		return {}

	var path: String = _get_slot_path(slot)

	if not FileAccess.file_exists(path):
		return {}

	# File size guard
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveService: load_game(%d) failed — cannot open file" % slot)
		return {}

	var file_size: int = file.get_length()
	if file_size > MAX_SAVE_SIZE_BYTES:
		push_error("SaveService: load_game(%d) failed — file size %d exceeds limit %d" % [slot, file_size, MAX_SAVE_SIZE_BYTES])
		file.close()
		return {}

	var text: String = file.get_as_text()
	file.close()

	# Parse JSON
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_warning("SaveService: load_game(%d) failed — JSON parse returned null (corrupted file)" % slot)
		return {}

	if not (parsed is Dictionary):
		push_warning("SaveService: load_game(%d) failed — parsed JSON is not a Dictionary" % slot)
		return {}

	var data: Dictionary = parsed as Dictionary

	# Migration
	var file_version: int = data.get("version", 0)
	if file_version > 0 and file_version < CURRENT_VERSION:
		data = migrate(data, file_version, CURRENT_VERSION)

	# Validation
	if not _validate(data):
		push_warning("SaveService: load_game(%d) failed — validation failed after load/migration" % slot)
		return {}

	return data


## Returns metadata for all save slots. Each entry contains:
## [code]slot[/code] (int), [code]timestamp[/code] (int), and
## [code]exists[/code] (bool). Always returns exactly MAX_SLOTS entries.
func list_slots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(1, MAX_SLOTS + 1):
		var entry: Dictionary = {"slot": i, "timestamp": 0, "exists": false}
		var path: String = _get_slot_path(i)

		if FileAccess.file_exists(path):
			var file: FileAccess = FileAccess.open(path, FileAccess.READ)
			if file != null:
				var text: String = file.get_as_text()
				file.close()
				var parsed: Variant = JSON.parse_string(text)
				if parsed != null and parsed is Dictionary:
					var dict: Dictionary = parsed as Dictionary
					if dict.has("timestamp"):
						entry["timestamp"] = dict.get("timestamp", 0)
						entry["exists"] = true

		result.append(entry)
	return result


## Deletes the save file for the specified [param slot]. Returns
## [code]true[/code] if the file was removed or did not exist (idempotent).
## Returns [code]false[/code] for invalid slot numbers or if removal fails.
func delete_slot(slot: int) -> bool:
	if not _is_valid_slot(slot):
		push_warning("SaveService: delete_slot(%d) failed — slot out of range [1, %d]" % [slot, MAX_SLOTS])
		return false

	var final_path: String = _get_slot_path(slot)
	var temp_path: String = _get_temp_path(slot)

	# Remove main file
	_remove_file(final_path)

	# Remove temp file if leftover
	_remove_file(temp_path)

	# Success means "file is gone" — true even if it didn't exist
	return not FileAccess.file_exists(final_path)


## Applies sequential version-step migrations to [param data] from
## [param from_version] to [param to_version]. Each step is a dedicated
## private method. Returns the migrated Dictionary.
func migrate(data: Dictionary, from_version: int, to_version: int) -> Dictionary:
	if from_version < 1:
		push_error("SaveService: migrate() — invalid from_version %d" % from_version)
		return data

	if to_version > CURRENT_VERSION:
		push_error("SaveService: migrate() — invalid to_version %d (CURRENT_VERSION is %d)" % [to_version, CURRENT_VERSION])
		return data

	if from_version >= to_version:
		return data

	var current: Dictionary = data
	var version_cursor: int = from_version

	while version_cursor < to_version:
		match version_cursor:
			1:
				current = _migrate_v1_to_v2(current)
			_:
				push_error("SaveService: migrate() — no migration defined for v%d to v%d" % [version_cursor, version_cursor + 1])
				return current
		version_cursor += 1

	return current


## Validates the structural integrity of a save manifest Dictionary.
## Checks that all required top-level keys exist and have correct types.
## Returns [code]true[/code] if valid, [code]false[/code] otherwise.
func _validate(data: Dictionary) -> bool:
	# Check all required keys exist
	for key in REQUIRED_KEYS:
		if not data.has(key):
			push_warning("SaveService: _validate() failed — missing required key '%s'" % key)
			return false

	# version: int in [1, CURRENT_VERSION]
	var version: Variant = data["version"]
	if not (version is int or version is float):
		push_warning("SaveService: _validate() failed — 'version' is not numeric")
		return false
	var version_int: int = int(version)
	if version_int < 1 or version_int > CURRENT_VERSION:
		push_warning("SaveService: _validate() failed — 'version' %d out of range [1, %d]" % [version_int, CURRENT_VERSION])
		return false

	# timestamp: positive int
	var timestamp: Variant = data["timestamp"]
	if not (timestamp is int or timestamp is float):
		push_warning("SaveService: _validate() failed — 'timestamp' is not numeric")
		return false
	if int(timestamp) <= 0:
		push_warning("SaveService: _validate() failed — 'timestamp' %d is not positive" % int(timestamp))
		return false

	# slot: int in [1, MAX_SLOTS]
	var slot: Variant = data["slot"]
	if not (slot is int or slot is float):
		push_warning("SaveService: _validate() failed — 'slot' is not numeric")
		return false
	var slot_int: int = int(slot)
	if slot_int < 1 or slot_int > MAX_SLOTS:
		push_warning("SaveService: _validate() failed — 'slot' %d out of range [1, %d]" % [slot_int, MAX_SLOTS])
		return false

	# seeds: Array
	if not (data["seeds"] is Array):
		push_warning("SaveService: _validate() failed — 'seeds' is not an Array")
		return false

	# adventurers: Array
	if not (data["adventurers"] is Array):
		push_warning("SaveService: _validate() failed — 'adventurers' is not an Array")
		return false

	# dungeon: Dictionary
	if not (data["dungeon"] is Dictionary):
		push_warning("SaveService: _validate() failed — 'dungeon' is not a Dictionary")
		return false

	# inventory: Dictionary with 'items' key
	if not (data["inventory"] is Dictionary):
		push_warning("SaveService: _validate() failed — 'inventory' is not a Dictionary")
		return false
	var inventory: Dictionary = data["inventory"] as Dictionary
	if not inventory.has("items"):
		push_warning("SaveService: _validate() failed — 'inventory' missing 'items' key")
		return false

	# wallet: Dictionary
	if not (data["wallet"] is Dictionary):
		push_warning("SaveService: _validate() failed — 'wallet' is not a Dictionary")
		return false

	# loop_state: Dictionary
	if not (data["loop_state"] is Dictionary):
		push_warning("SaveService: _validate() failed — 'loop_state' is not a Dictionary")
		return false

	# settings: Dictionary
	if not (data["settings"] is Dictionary):
		push_warning("SaveService: _validate() failed — 'settings' is not a Dictionary")
		return false

	return true


# ---------------------------------------------------------------------------
# Migration Methods
# ---------------------------------------------------------------------------

## Migrates a v1 save manifest to v2.
## Changes:
##   - Restructures player_gold (int) into wallet Dictionary
##   - Adds loop_state.auto_harvest_enabled (default false)
##   - Adds settings.colorblind_mode (default "none")
##   - Adds settings.text_size (default "medium")
func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	# Restructure player_gold into wallet
	if not data.has("wallet") or not (data["wallet"] is Dictionary):
		var old_gold: int = data.get("player_gold", 0)
		data["wallet"] = {
			"gold": old_gold,
			"gems": 0,
			"essence": 0,
			"dust": 0,
		}
	# Remove old field if present
	if data.has("player_gold"):
		data.erase("player_gold")

	# Add auto_harvest_enabled to loop_state
	if data.has("loop_state") and data["loop_state"] is Dictionary:
		var loop_state: Dictionary = data["loop_state"] as Dictionary
		if not loop_state.has("auto_harvest_enabled"):
			loop_state["auto_harvest_enabled"] = false

	# Add colorblind_mode and text_size to settings
	if data.has("settings") and data["settings"] is Dictionary:
		var settings: Dictionary = data["settings"] as Dictionary
		if not settings.has("colorblind_mode"):
			settings["colorblind_mode"] = "none"
		if not settings.has("text_size"):
			settings["text_size"] = "medium"

	# Update version
	data["version"] = 2

	return data


# ---------------------------------------------------------------------------
# Private Helpers
# ---------------------------------------------------------------------------

## Returns the file path for a given save slot.
func _get_slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_" + str(slot) + ".json"


## Returns the temporary file path for a given save slot (used for atomic writes).
func _get_temp_path(slot: int) -> String:
	return _get_slot_path(slot) + ".tmp"


## Returns whether the given slot number is in the valid range [1, MAX_SLOTS].
func _is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= MAX_SLOTS


## Ensures the save directory exists. Returns true on success.
func _ensure_save_directory() -> bool:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return false
	if not dir.dir_exists("saves"):
		var err: int = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		if err != OK:
			return false
	return true


## Removes a file at the given path if it exists. Silent no-op if missing.
func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		var dir_path: String = path.get_base_dir()
		var file_name: String = path.get_file()
		var dir: DirAccess = DirAccess.open(dir_path)
		if dir != null:
			dir.remove(file_name)


## Extracts the file name from a full path for DirAccess operations.
func _file_name_from_path(path: String) -> String:
	return path.get_file()
```

### 16.2 File Removal: `src/gdscript/utils/save_manager.gd`

The old `save_manager.gd` should be deleted. If other code references it, add a deprecation stub:

```gdscript
class_name SaveManager
extends RefCounted
## @deprecated Use SaveService instead. This file will be removed in a future version.
##
## Migration guide:
##   - SaveManager.save() → SaveService.save_game(slot, state)
##   - SaveManager.load() → SaveService.load_game(slot)
##   - SaveManager had no slot support — use slot 1 as default.

func _init() -> void:
	push_warning("SaveManager is deprecated. Use SaveService instead. See save_service.gd.")
```

### 16.3 Test File Registration

Ensure `tests/services/test_save_service.gd` is discovered by GUT. The project's `.gutconfig.json` should include the test directory:

```json
{
    "dirs": ["res://tests/"],
    "prefix": "test_",
    "suffix": ".gd",
    "should_maximize": false,
    "log_level": 1
}
```

### 16.4 Integration Checklist

After implementing `save_service.gd` and the test file:

1. Verify `SaveService.new()` works without errors in the Godot editor's script console.
2. Run the GUT test suite — all tests should pass green.
3. Delete or deprecate `src/gdscript/utils/save_manager.gd`.
4. Update any existing references to `SaveManager` to use `SaveService`.
5. Verify that the `user://saves/` directory is created on first save.
6. Manually save and load through the game's pause menu (if UI exists).
7. Verify slot independence by saving different states to different slots.
8. Verify corruption handling by manually breaking a save file.
9. Verify migration by creating a v1 fixture file and loading it.
10. Check Godot output console for any unexpected warnings or errors during all operations.

---

*End of TASK-009: Save/Load Manager with Versioned Serialization*

