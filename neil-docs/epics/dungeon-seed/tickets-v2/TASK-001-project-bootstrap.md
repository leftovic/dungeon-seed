# TASK-001: Project Bootstrap & Autoload Skeleton

---

## Section 1 · Header

| Field              | Value                                                                 |
|--------------------|-----------------------------------------------------------------------|
| **Task ID**        | TASK-001                                                              |
| **Title**          | Project Bootstrap & Autoload Skeleton                                 |
| **Priority**       | 🔴 P0 — Critical (all downstream tasks depend on this)               |
| **Tier**           | Foundation                                                            |
| **Complexity**     | 3 points (Trivial)                                                    |
| **Phase**          | Phase 1 — Technical Scaffold                                          |
| **Wave**           | Wave 1 (no dependencies — can start immediately)                      |
| **Stream**         | ⚪ TCH (Technical) — Primary                                          |
| **Cross-Stream**   | 🔴 MCH (provides service hooks) · 🔵 VIS (scene router) · 🟢 AUD (event signals) |
| **GDD Reference**  | GDD-v2.md §Core Loop, §Engine, §Architecture                         |
| **Milestone**      | M1 — Runnable Project Shell                                           |
| **Dependencies**   | None                                                                  |
| **Critical Path**  | ✅ Yes — every subsequent task requires this skeleton                  |
| **Estimated Effort** | 2–4 hours for an experienced Godot developer                       |
| **Assignee**       | Unassigned                                                            |

---

## Section 2 · Description

### 2.1 What This Feature IS

TASK-001 establishes the clean Godot 4.5 project foundation that every other task in the Dungeon Seed pipeline depends on. It converts the existing bare `project.godot` (which names the project and points to `res://src/scenes/main_menu.tscn`) into a fully structured, autoload-equipped project skeleton.

The deliverables are:

1. **Canonical folder structure** — a deterministic directory layout under `src/` and `tests/` that every future task can rely on without creating ad-hoc paths.
2. **EventBus autoload** — a central typed-signal bus that decouples all game systems from each other, mapping directly to the GDD's core-loop transitions.
3. **GameManager autoload** — a lifecycle-aware singleton that holds references to the domain services (SeedGrove, Roster, Wallet, LoopController) and provides orderly initialize/shutdown.
4. **SceneRouter utility** — a lightweight wrapper around `get_tree().change_scene_to_file()` that adds transition support and path validation.
5. **project.godot registration** — both autoloads registered so they are available globally on first frame.

### 2.2 Player Experience Impact

Players never see this task directly, but it is the invisible scaffolding that makes every player-facing feature possible:

- **EventBus** enables the core loop flow: Plant Seed → Grow Dungeon → Monitor Progress → Dispatch Adventurers → Clear Rooms → Harvest Loot → Upgrade → Unlock. Each arrow in that chain is a signal emission. Without EventBus, systems would need hard references to each other, creating a brittle coupling web.
- **GameManager** ensures that when a player launches the game, all services spin up in the correct order and tear down cleanly on exit — no orphan state, no leaked resources.
- **SceneRouter** ensures screen transitions (Seed Grove → Dungeon Board → Adventurer Hall) are smooth, validated, and never hit a missing-scene crash.

### 2.3 Development Cost

| Metric                     | Target          |
|----------------------------|-----------------|
| Lines of production code   | 200–300         |
| Lines of test code         | 100–150         |
| New files created          | 8–12            |
| Existing files modified    | 1 (project.godot) |
| Risk level                 | Very Low        |

### 2.4 Technical Architecture

#### Folder Tree

```
res://
├── project.godot                  # Engine config (modified)
├── src/
│   ├── autoloads/
│   │   ├── event_bus.gd           # ★ NEW — Signal bus singleton
│   │   └── game_manager.gd        # ★ NEW — Service lifecycle singleton
│   ├── models/                    # Pure data classes (RefCounted)
│   ├── services/                  # Domain logic services (RefCounted)
│   ├── managers/                  # Node-based managers (scene tree integration)
│   ├── ui/                        # UI scene scripts
│   ├── scenes/
│   │   └── main_menu.tscn         # Existing (placeholder)
│   ├── resources/                 # .tres resource files
│   └── shaders/                   # .gdshader files
├── tests/
│   ├── unit/                      # GUT unit tests
│   └── integration/               # GUT integration tests
└── src/utils/
    └── scene_router.gd            # ★ NEW — Scene transition utility
```

#### Scene Tree at Runtime

```
Root (Viewport)
 ├── EventBus          (autoload — always first)
 ├── GameManager       (autoload — always second)
 └── Main              (current scene — swapped by SceneRouter)
```

### 2.5 System Interaction Map

```
┌─────────────────────────────────────────────────────────────────┐
│                        EventBus (autoload)                      │
│  Signals: seed_planted · seed_matured · expedition_started      │
│           expedition_completed · loot_gained                    │
│           adventurer_recruited                                  │
├─────────────────────────────────────────────────────────────────┤
│         ▲ emit              ▲ emit              ▲ emit          │
│         │                   │                   │               │
│  ┌──────┴──────┐   ┌───────┴───────┐   ┌───────┴──────┐       │
│  │  SeedGrove  │   │ LoopController│   │   Roster     │       │
│  │  (future)   │   │   (future)    │   │  (future)    │       │
│  └─────────────┘   └───────────────┘   └──────────────┘       │
│         ▲                   ▲                   ▲               │
│         └───────────────────┴───────────────────┘               │
│                     GameManager (autoload)                       │
│              initialize() / shutdown() lifecycle                 │
├─────────────────────────────────────────────────────────────────┤
│                     SceneRouter (utility)                        │
│         change_scene(path) · preload · validate                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.6 Constraints and Design Decisions

| Decision | Rationale |
|----------|-----------|
| EventBus before GameManager in autoload order | Ensures signals are available when GameManager initializes services |
| Typed signals with explicit parameters | Enables editor autocomplete and prevents silent emission mismatches |
| SceneRouter as utility, not autoload | Keeps autoload count minimal; SceneRouter is stateless and can be instantiated by GameManager |
| `src/` prefix for all game code | Separates game logic from engine/addon files at the root |
| `tests/` at root level | Mirrors GUT convention; keeps test code out of export builds |
| RefCounted for models/services | Avoids scene tree dependency; garbage collected automatically |
| Node-based for managers/ | Allows `_process()`, `_ready()`, and signal connections via the scene tree |
| No gameplay logic in this task | This is pure infrastructure — gameplay lands in subsequent tasks |

---

## Section 3 · Use Cases

### UC-01: Kai the Speedrunner — Fast Iteration Bootstrap

**Archetype:** Kai is a developer who wants to get a runnable project in under five minutes so he can start prototyping seed-planting mechanics immediately.

**Scenario:**
1. Kai clones the repository and opens the project in Godot 4.5.
2. The editor loads without errors or warnings in the Output panel.
3. Kai presses F5 (Run Project). The game launches to a blank/placeholder main menu screen.
4. In the Remote scene tree, Kai confirms `EventBus` and `GameManager` are present as autoload nodes.
5. Kai opens `event_bus.gd` and sees all six typed signals with clear parameter documentation.
6. Kai creates a throwaway test script, connects to `EventBus.seed_planted`, emits the signal, and confirms the connection fires.
7. Kai opens `game_manager.gd`, calls `initialize()`, and confirms it prints lifecycle debug output.
8. Total time from clone to confirmed working skeleton: under 5 minutes.

**Success Criteria:** Zero errors on open, autoloads visible in remote tree, signals connectable from any script.

### UC-02: Luna the Completionist — Full Exploration of Structure

**Archetype:** Luna is a meticulous developer who inspects every folder, every file, and every configuration before writing a single line of game code.

**Scenario:**
1. Luna opens the FileSystem dock in the Godot editor.
2. She verifies every folder listed in the canonical folder tree exists: `src/autoloads/`, `src/models/`, `src/services/`, `src/managers/`, `src/ui/`, `src/scenes/`, `src/resources/`, `src/shaders/`, `src/utils/`, `tests/unit/`, `tests/integration/`.
3. She opens `project.godot` in a text editor and confirms `EventBus` is listed before `GameManager` in the `[autoload]` section.
4. She reads each autoload script end-to-end, confirming type hints on every variable, every signal parameter, and every function return type.
5. She opens `scene_router.gd` and verifies it validates scene paths before attempting transitions.
6. She runs the GUT test suite and confirms all tests pass green.
7. She checks that no orphan `.import` files or stale references exist.

**Success Criteria:** All folders exist, autoload order is correct, all code is fully typed, all tests pass.

### UC-03: Sam the Casual Parent — Quick Session Confidence

**Archetype:** Sam has 20 minutes between kid activities. He wants to verify the project scaffold is solid and move on to the next task without debugging infrastructure.

**Scenario:**
1. Sam opens the project in Godot. No error dialogs appear.
2. He hits F5. A window appears (blank or placeholder). No crash.
3. He checks the Output panel — zero errors, zero warnings from the autoload scripts.
4. He opens `GameManager` in the script editor, sees the `initialize()` and `shutdown()` methods with clear docstrings.
5. He is confident the foundation is solid and moves to TASK-002 (Seed Data Model).
6. Total time: under 3 minutes.

**Success Criteria:** Project runs clean, no investigation needed, clear code with docstrings.

---

## Section 4 · Glossary

| Term | Definition |
|------|------------|
| **Autoload** | A Godot feature that registers a script or scene as a global singleton node, available from any script via its registered name. Autoloads persist across scene changes. |
| **Signal** | Godot's observer-pattern implementation. A signal is declared on a node/object and emitted when an event occurs. Other objects connect to signals to react without direct coupling. |
| **Typed Signal** | A signal declared with explicit parameter types (e.g., `signal seed_planted(seed_id: StringName, slot_index: int)`), enabling editor autocomplete and runtime type safety. |
| **EventBus** | A design pattern where a single global object exposes signals that any system can emit or connect to, decoupling producers from consumers. In Dungeon Seed, EventBus maps to core-loop transitions. |
| **Singleton** | An object with exactly one instance accessible globally. In Godot, autoloads are the canonical singleton mechanism. |
| **RefCounted** | Godot's base class for reference-counted objects. Automatically freed when no references remain. Used for pure data classes that do not need the scene tree. |
| **Node** | Godot's base scene-tree element. Provides lifecycle callbacks (`_ready()`, `_process()`), signal connections, and parent-child hierarchy. |
| **SceneTree** | The runtime tree of all active Nodes. Godot processes the tree top-down for `_process()` and bottom-up for `_exit_tree()`. |
| **class_name** | A GDScript keyword that registers a script as a globally available type, enabling static typing and editor integration without `preload()`. |
| **.tscn** | Godot's text-based scene file format. Describes a tree of nodes with properties, connections, and resources. |
| **.tres** | Godot's text-based resource file format. Stores data objects (themes, materials, custom resources) independently of scenes. |
| **.gd** | GDScript source file extension. GDScript is Godot's native scripting language with Python-like syntax and deep engine integration. |
| **GUT** | Godot Unit Test framework. A popular addon for writing and running automated tests in GDScript with `extends GutTest`. |
| **get_tree()** | Returns the active SceneTree instance from any Node. Used to access global scene management functions. |
| **change_scene_to_file()** | A SceneTree method that unloads the current scene and loads a new scene from a file path. The basis of scene transitions. |
| **SceneRouter** | A utility class in Dungeon Seed that wraps `change_scene_to_file()` with path validation, preloading, and transition signals. Not an autoload — instantiated by GameManager. |
| **GameManager** | The lifecycle-managing autoload singleton. Holds references to active domain services and provides orderly `initialize()` / `shutdown()` sequencing. |
| **SeedGrove** | (Future) The service managing the player's seed collection and planting grid. Referenced by GameManager but NOT implemented in this task. |
| **Roster** | (Future) The service managing the player's adventurer team. Referenced by GameManager but NOT implemented in this task. |
| **Wallet** | (Future) The service managing the player's currency and resources. Referenced by GameManager but NOT implemented in this task. |

---

## Section 5 · Out of Scope

The following items are explicitly **NOT** part of TASK-001. They belong to subsequent tasks and must not be implemented, stubbed with logic, or planned for in this ticket's code:

| # | Excluded Item | Belongs To |
|---|--------------|------------|
| 1 | Seed data model, seed planting logic, seed growth timers | TASK-002 (Seed Data Model) |
| 2 | Dungeon generation, room layouts, biome rules | TASK-003+ (Dungeon Systems) |
| 3 | Combat system, damage formulas, turn resolution | TASK-005+ (Combat) |
| 4 | Adventurer data model, recruitment, stat progression | TASK-004 (Adventurer System) |
| 5 | Save/load system, serialization, persistence | TASK-010+ (Persistence) |
| 6 | UI screens beyond a blank placeholder main_menu.tscn | TASK-006+ (UI) |
| 7 | Audio playback, SFX, music, adaptive audio | TASK-020+ (Audio) |
| 8 | Visual effects, shaders, particles | TASK-015+ (VFX) |
| 9 | Input remapping, gamepad support, accessibility features | TASK-018+ (Accessibility) |
| 10 | Monetization, IAP, ad integration | Out of scope for entire v1 |
| 11 | Multiplayer, networking, leaderboards | Out of scope for entire v1 |
| 12 | Localization, i18n string tables | TASK-025+ (Localization) |
| 13 | CI/CD pipeline, export templates, build automation | TASK-030+ (DevOps) |
| 14 | Plugin/addon installation (GUT is assumed pre-installed) | Pre-requisite, not this task |
| 15 | Migration of existing v1 prototype code from `src/gdscript/` | TASK-050+ (Migration) |

---

## Section 6 · Functional Requirements

Each requirement is independently testable. Status: ☐ = not started.

### Folder Structure

| ID | Requirement | Priority |
|----|------------|----------|
| FR-001 | The directory `res://src/autoloads/` MUST exist and contain `event_bus.gd` and `game_manager.gd`. | MUST |
| FR-002 | The directories `res://src/models/`, `res://src/services/`, `res://src/managers/`, `res://src/ui/`, `res://src/scenes/`, `res://src/resources/`, `res://src/shaders/` MUST each exist (may be empty with `.gdkeep` placeholder). | MUST |
| FR-003 | The directory `res://src/utils/` MUST exist and contain `scene_router.gd`. | MUST |
| FR-004 | The directories `res://tests/unit/` and `res://tests/integration/` MUST each exist. | MUST |

### EventBus Autoload

| ID | Requirement | Priority |
|----|------------|----------|
| FR-005 | `event_bus.gd` MUST extend `Node`. | MUST |
| FR-006 | `event_bus.gd` MUST declare `class_name EventBus`. | MUST |
| FR-007 | `event_bus.gd` MUST declare typed signal `seed_planted(seed_id: StringName, slot_index: int)`. | MUST |
| FR-008 | `event_bus.gd` MUST declare typed signal `seed_matured(seed_id: StringName, slot_index: int)`. | MUST |
| FR-009 | `event_bus.gd` MUST declare typed signal `expedition_started(dungeon_id: StringName, party_ids: Array[StringName])`. | MUST |
| FR-010 | `event_bus.gd` MUST declare typed signal `expedition_completed(dungeon_id: StringName, success: bool, turns_taken: int)`. | MUST |
| FR-011 | `event_bus.gd` MUST declare typed signal `loot_gained(item_id: StringName, quantity: int, source: StringName)`. | MUST |
| FR-012 | `event_bus.gd` MUST declare typed signal `adventurer_recruited(adventurer_id: StringName, class_type: StringName)`. | MUST |

### GameManager Autoload

| ID | Requirement | Priority |
|----|------------|----------|
| FR-013 | `game_manager.gd` MUST extend `Node`. | MUST |
| FR-014 | `game_manager.gd` MUST declare `class_name GameManager`. | MUST |
| FR-015 | `game_manager.gd` MUST expose an `initialize() -> void` method that sets an `_initialized: bool` flag to `true` and emits a `game_initialized` signal. | MUST |
| FR-016 | `game_manager.gd` MUST expose a `shutdown() -> void` method that sets `_initialized` to `false` and emits a `game_shutdown` signal. | MUST |
| FR-017 | `game_manager.gd` MUST declare typed nullable properties for future services: `seed_grove`, `roster`, `wallet`, `loop_controller` (all typed as `RefCounted` initially, defaulting to `null`). | MUST |
| FR-018 | `game_manager.gd` MUST NOT call `initialize()` automatically in `_ready()`. Initialization is explicit. | MUST |

### SceneRouter Utility

| ID | Requirement | Priority |
|----|------------|----------|
| FR-019 | `scene_router.gd` MUST provide a static or instance method `change_scene(scene_path: String) -> Error` that validates the path exists before calling `get_tree().change_scene_to_file()`. | MUST |
| FR-020 | `scene_router.gd` MUST return `ERR_FILE_NOT_FOUND` if the provided scene path does not exist on disk. | MUST |
| FR-021 | `scene_router.gd` MUST declare a signal `scene_change_started(target_path: String)` and `scene_change_completed(target_path: String)`. | MUST |

### project.godot Registration

| ID | Requirement | Priority |
|----|------------|----------|
| FR-022 | `project.godot` MUST register `EventBus` as an autoload pointing to `res://src/autoloads/event_bus.gd`. | MUST |
| FR-023 | `project.godot` MUST register `GameManager` as an autoload pointing to `res://src/autoloads/game_manager.gd`. | MUST |
| FR-024 | `EventBus` MUST appear BEFORE `GameManager` in the `[autoload]` section to guarantee initialization order. | MUST |

---

## Section 7 · Non-Functional Requirements

| ID | Requirement | Category |
|----|------------|----------|
| NFR-001 | The project MUST open in Godot 4.5 editor without any errors or warnings in the Output panel related to autoloads, missing files, or parse failures. | Stability |
| NFR-002 | The project MUST run (F5) and reach the main scene without crash, displaying a window within 3 seconds on a standard development machine. | Performance |
| NFR-003 | All GDScript files MUST use static type hints on every variable declaration, function parameter, and return type. | Code Quality |
| NFR-004 | All GDScript files MUST follow the official Godot GDScript style guide: snake_case for variables/functions, PascalCase for classes, UPPER_SNAKE for constants. | Code Quality |
| NFR-005 | No autoload script may contain more than 150 lines of code (excluding comments and blank lines). | Maintainability |
| NFR-006 | `event_bus.gd` MUST have zero runtime allocations during signal declaration (signals are metadata, not runtime objects). | Performance |
| NFR-007 | All public methods MUST have a doc comment (`##`) explaining purpose, parameters, and return value. | Documentation |
| NFR-008 | No script may produce orphan nodes. All dynamically created nodes must be added to the tree or explicitly freed. | Memory |
| NFR-009 | The autoload initialization sequence MUST complete in under 50ms on a standard development machine. | Performance |
| NFR-010 | All file paths referenced in code MUST use `res://` prefix and forward slashes, never OS-native paths. | Portability |
| NFR-011 | The project MUST NOT depend on any third-party addons except GUT for testing. | Dependency |
| NFR-012 | All signals MUST include parameter names (not just types) for self-documenting API surfaces. | Code Quality |
| NFR-013 | The folder structure MUST support Godot's import system — no folder may contain characters that break `res://` path resolution. | Compatibility |
| NFR-014 | SceneRouter MUST NOT block the main thread during scene transitions. | Performance |
| NFR-015 | All scripts MUST be parseable by GDScript 2.0 (Godot 4.x) with zero parser warnings when opening the script editor. | Compatibility |
| NFR-016 | The total disk footprint of all new files created by this task MUST be under 50 KB. | Size |

---

## Section 8 · Designer's Manual

### 8.1 How to Add a New Autoload

1. Create the script in `res://src/autoloads/your_autoload.gd`.
2. The script MUST extend `Node`.
3. Declare `class_name YourAutoload` at the top of the file.
4. Open `project.godot` and add to the `[autoload]` section:
   ```ini
   YourAutoload="*res://src/autoloads/your_autoload.gd"
   ```
   The `*` prefix means "enabled." Order matters — add below existing entries unless your autoload must initialize before others.
5. Restart the editor or use Project → Project Settings → Autoload to verify.

### 8.2 How to Add a New Signal to EventBus

1. Open `res://src/autoloads/event_bus.gd`.
2. Add the signal declaration with full type annotations:
   ```gdscript
   ## Emitted when [describe the event].
   signal your_event_name(param_one: Type, param_two: Type)
   ```
3. Document the signal with a `##` doc comment above the declaration.
4. Add a corresponding test in `tests/unit/test_event_bus.gd`:
   ```gdscript
   func test_your_event_name_emission() -> void:
       watch_signals(EventBus)
       EventBus.your_event_name.emit(value_one, value_two)
       assert_signal_emitted(EventBus, "your_event_name")
   ```
5. No registration step is needed — signals are available immediately after declaration.

### 8.3 How to Add a New Scene

1. Create the `.tscn` file in `res://src/scenes/your_scene.tscn`.
2. Attach a script from the appropriate folder:
   - UI scenes → `res://src/ui/your_scene.gd`
   - Gameplay scenes → create in relevant domain folder
3. Transition to it using SceneRouter:
   ```gdscript
   var router := SceneRouter.new()
   add_child(router)
   var err := router.change_scene("res://src/scenes/your_scene.tscn")
   if err != OK:
       push_error("Scene transition failed: %s" % error_string(err))
   ```

### 8.4 Folder Conventions

| Folder | Contents | Base Class | When to Use |
|--------|---------|------------|-------------|
| `src/autoloads/` | Global singletons | `Node` | System-wide services that must persist across scenes |
| `src/models/` | Pure data classes | `RefCounted` or `Resource` | Data containers with no behavior beyond getters/setters |
| `src/services/` | Domain logic | `RefCounted` | Stateless or state-light business logic (calculations, queries) |
| `src/managers/` | Scene-tree managers | `Node` | Stateful controllers that need `_process()`, `_ready()`, or child nodes |
| `src/ui/` | UI scripts | `Control` subclasses | Scripts attached to UI `.tscn` scenes |
| `src/scenes/` | Scene files | N/A (`.tscn`) | All `.tscn` files live here, organized by feature subfolder |
| `src/resources/` | Resource files | N/A (`.tres`) | Custom resources, themes, style overrides |
| `src/shaders/` | Shader files | N/A (`.gdshader`) | Visual shaders and code shaders |
| `src/utils/` | Utility classes | `RefCounted` or static | Stateless helpers (SceneRouter, math utils, formatters) |
| `tests/unit/` | Unit tests | `GutTest` | Isolated tests for single classes/functions |
| `tests/integration/` | Integration tests | `GutTest` | Tests that verify multi-system interactions |

### 8.5 Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Script files | `snake_case.gd` | `event_bus.gd`, `scene_router.gd` |
| Class names | `PascalCase` | `EventBus`, `SceneRouter` |
| Signals | `snake_case` (past tense for events) | `seed_planted`, `expedition_completed` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_PARTY_SIZE`, `DEFAULT_SLOT_COUNT` |
| Private variables | `_prefixed_snake_case` | `_initialized`, `_scene_cache` |
| Public variables | `snake_case` | `seed_grove`, `roster` |
| Methods | `snake_case` (verb-first) | `initialize()`, `change_scene()` |

---

## Section 9 · Assumptions

| # | Assumption | Impact if Wrong |
|---|-----------|-----------------|
| 1 | Godot 4.5 stable is the target engine version. | GDScript syntax changes may break scripts if targeting 4.3 or earlier. |
| 2 | GDScript is the sole scripting language — no C#, no GDExtension, no VisualScript. | Architecture would change significantly if C# interop were needed. |
| 3 | The GUT testing framework (v9.x+) is pre-installed as an addon in `addons/gut/`. | Tests will not run if GUT is missing. Installation is a pre-requisite, not part of this task. |
| 4 | The existing `project.godot` at the repository root is the authoritative project file. | If there are multiple `.godot` files, the wrong one may be modified. |
| 5 | The existing `res://src/scenes/main_menu.tscn` exists or will be created as a minimal placeholder. | The project will crash on F5 if the main scene is missing. |
| 6 | Developers have Godot 4.5 editor installed locally for manual verification. | Cannot verify F5-run behavior without the editor. |
| 7 | The `src/gdscript/` folder contains v1 prototype code that will NOT be deleted or migrated by this task. | If deleted, historical reference code is lost. If migrated, scope creep occurs. |
| 8 | Autoload order in `project.godot` is deterministic — first listed = first initialized. | If Godot changes autoload ordering behavior, EventBus-before-GameManager guarantee breaks. |
| 9 | `class_name` registration is globally unique — no two scripts may share a class_name. | Duplicate class_name causes parser errors on project open. |
| 10 | The `res://` virtual filesystem root maps to the repository root where `project.godot` lives. | All file paths in code assume this mapping. |
| 11 | Signal parameters in Godot 4.5 support full type annotations including `Array[StringName]`. | If typed arrays in signals are not supported, FR-009 signal declaration must be adjusted. |
| 12 | No other developer will be modifying `project.godot` concurrently during this task. | Merge conflicts in project.godot are notoriously difficult to resolve. |
| 13 | The project targets desktop (PC/Mac/Linux) as the primary platform. | Mobile-specific constraints (touch input, screen size) are not considered. |
| 14 | UTF-8 encoding is used for all script files. | Non-UTF-8 encoding may cause parser failures in Godot. |
| 15 | The development machine has at least 4 GB RAM and a GPU supporting Vulkan or OpenGL 3.3. | Godot 4.5 requires these minimums to run the editor and game. |
| 16 | No export templates are needed for this task — development is editor-only. | Export testing belongs to a later DevOps task. |

---

## Section 10 · Security & Anti-Cheat

> **Note:** TASK-001 is infrastructure-only with no player-facing attack surface. However, the architectural decisions made here establish security patterns for all downstream tasks.

### Threat 1: Autoload Tampering via File Replacement

| Field | Detail |
|-------|--------|
| **Threat** | An attacker replaces `event_bus.gd` or `game_manager.gd` with a malicious script that executes arbitrary code on game launch. |
| **Risk Level** | Medium (requires filesystem access to the installed game) |
| **Mitigation** | 1. Export builds should use PCK encryption (handled in DevOps task). 2. Autoload paths are hardcoded in `project.godot`, not dynamically resolved. 3. Future: checksum validation of autoload scripts at startup. |
| **This Task's Role** | Establish the pattern of static autoload paths in `project.godot`. Do NOT implement dynamic autoload loading. |

### Threat 2: Signal Injection / Spoofing

| Field | Detail |
|-------|--------|
| **Threat** | A modded script emits `loot_gained` with inflated quantities, or `expedition_completed` with `success=true` for a dungeon that was never started. |
| **Risk Level** | High in moddable builds, Low in signed exports |
| **Mitigation** | 1. Signals are fire-and-forget; consumers MUST validate signal payloads against authoritative state. 2. GameManager should track active expeditions and reject phantom completions. 3. Future: signal audit log for debugging. |
| **This Task's Role** | Establish typed signals with explicit parameters so consumers can validate payload shape. Document that consumers MUST NOT trust signal data blindly. |

### Threat 3: Scene Path Manipulation

| Field | Detail |
|-------|--------|
| **Threat** | A crafted scene path passed to SceneRouter resolves to a file outside the expected `res://src/scenes/` directory, potentially loading a malicious scene. |
| **Risk Level** | Low (Godot's `res://` sandbox prevents filesystem escape) |
| **Mitigation** | 1. SceneRouter validates that the path starts with `res://src/scenes/` before loading. 2. SceneRouter checks `ResourceLoader.exists()` before calling `change_scene_to_file()`. 3. Godot's PCK system prevents arbitrary file access in exports. |
| **This Task's Role** | Implement path prefix validation in SceneRouter. |

### Threat 4: Initialization Order Exploitation

| Field | Detail |
|-------|--------|
| **Threat** | A script accesses GameManager services before `initialize()` is called, reading null references and causing undefined behavior or crashes. |
| **Risk Level** | Medium (developer error, not external attack) |
| **Mitigation** | 1. GameManager exposes `is_initialized() -> bool` for consumers to check. 2. Service getters return null-safe defaults or push warnings when accessed before initialization. 3. `game_initialized` signal allows deferred access patterns. |
| **This Task's Role** | Implement the `_initialized` flag and `is_initialized()` getter. Document the initialize-before-access contract. |

---

## Section 11 · Best Practices

### BP-01: Signal Decoupling Over Direct References

**Do:** Connect to `EventBus.seed_planted` from your system.
**Don't:** Import `SeedGrove` directly and call `seed_grove.get_planted_seeds()` from unrelated systems.
**Why:** Signals allow systems to be developed, tested, and deployed independently. A combat system should not need to know how seeds work.

### BP-02: Typed Signals Always

**Do:** `signal seed_planted(seed_id: StringName, slot_index: int)`
**Don't:** `signal seed_planted` (no parameters) or `signal seed_planted(data)` (untyped)
**Why:** Typed parameters enable editor autocomplete, catch emission mismatches at parse time, and serve as living documentation.

### BP-03: Autoload Minimalism

**Do:** Keep autoloads thin — they hold signals and references, not business logic.
**Don't:** Put 500 lines of gameplay logic in `game_manager.gd`.
**Why:** Autoloads are global state. The more logic they contain, the harder they are to test and the more they resist refactoring.

### BP-04: Initialize Explicitly, Never Implicitly

**Do:** Call `GameManager.initialize()` from the main scene's `_ready()` when the game starts.
**Don't:** Call `initialize()` inside GameManager's own `_ready()`.
**Why:** Explicit initialization allows test harnesses to control when services spin up, and allows main menu to exist without full game state.

### BP-05: RefCounted for Data, Node for Behavior

**Do:** Use `RefCounted` (or `Resource`) for pure data models in `src/models/`.
**Don't:** Extend `Node` for a data class that never enters the scene tree.
**Why:** Nodes that are never added to the tree leak memory unless manually freed. RefCounted objects are garbage-collected automatically.

### BP-06: Path Validation Before Scene Transitions

**Do:** Check `ResourceLoader.exists(path)` before calling `change_scene_to_file()`.
**Don't:** Assume the path is valid and let Godot crash with an obscure error.
**Why:** Crash-on-invalid-path is the #1 cause of developer frustration during rapid iteration.

### BP-07: Forward Slashes in All Paths

**Do:** `"res://src/scenes/main_menu.tscn"`
**Don't:** `"res:\\src\\scenes\\main_menu.tscn"`
**Why:** Godot uses forward slashes internally regardless of OS. Backslashes cause path resolution failures on all platforms.

### BP-08: Doc Comments on Every Public API

**Do:** Use `##` doc comments above every public method, signal, and property.
**Don't:** Leave public APIs undocumented or use `#` (which is not a doc comment).
**Why:** `##` comments appear in the Godot editor's documentation hover and Help panel.

### BP-09: One Class Per File

**Do:** Define `class_name EventBus` in `event_bus.gd` and nothing else.
**Don't:** Define multiple `class_name` declarations in one file or define inner classes with `class_name`.
**Why:** Godot registers `class_name` globally per file. Multiple declarations in one file cause conflicts.

### BP-10: Test Isolation with GUT

**Do:** Each test function creates its own state, tests one thing, and cleans up.
**Don't:** Share mutable state between test functions or depend on test execution order.
**Why:** GUT does not guarantee test execution order. Shared state causes flaky tests.

### BP-11: Use StringName for Identifiers

**Do:** Use `StringName` for IDs (seed_id, adventurer_id, dungeon_id, item_id).
**Don't:** Use `String` for identifiers that are compared frequently.
**Why:** `StringName` comparisons are O(1) pointer equality. `String` comparisons are O(n) character-by-character.

### BP-12: Keep Autoload Count Low

**Do:** Use two autoloads (EventBus + GameManager) and let GameManager manage everything else.
**Don't:** Create an autoload for every system (SeedAutoload, CombatAutoload, UIAutoload...).
**Why:** Every autoload is a global singleton. Global state is hard to test, hard to reason about, and creates initialization-order dependencies.

### BP-13: Emit Signals with Named Arguments

**Do:** `EventBus.seed_planted.emit(seed_id, slot_index)` where variables match signal parameter names.
**Don't:** `EventBus.seed_planted.emit("oak", 3)` with magic literals.
**Why:** Named variables at the call site make signal emissions self-documenting and debuggable.

---

## Section 12 · Troubleshooting

### Issue 1: "Autoload not found" error on project open

**Symptoms:** Godot Output panel shows `Cannot preload script "res://src/autoloads/event_bus.gd"` or similar.

**Causes:**
- The script file does not exist at the specified path.
- The `[autoload]` entry in `project.godot` has a typo in the path.
- The file has a syntax error preventing Godot from parsing it.

**Resolution:**
1. Verify the file exists: check `res://src/autoloads/event_bus.gd` in the FileSystem dock.
2. Open `project.godot` in a text editor and confirm the path matches exactly.
3. Open the script in the Godot editor and check for parse errors (red underlines).

### Issue 2: Signal not connecting — "Invalid signal name"

**Symptoms:** `connect()` or `.connect()` raises an error about the signal not existing on the target object.

**Causes:**
- The signal name is misspelled in the `connect()` call.
- The object being connected to is not the autoload instance (e.g., using a local variable instead of the global `EventBus`).
- The signal was declared with `signal` but the script has a parse error above it, preventing declaration.

**Resolution:**
1. Verify the signal name matches exactly (case-sensitive).
2. Use the global name `EventBus` not a local reference.
3. Test in isolation: `print(EventBus.has_signal("seed_planted"))` — should print `true`.

### Issue 3: Cyclic dependency between autoloads

**Symptoms:** Godot hangs on startup or prints "Cyclic dependency detected" errors.

**Causes:**
- `event_bus.gd` references `GameManager` and `game_manager.gd` references `EventBus` at the top level (class body, not inside functions).
- `class_name` + `preload()` creates a circular reference chain.

**Resolution:**
1. Autoloads should NEVER reference each other at the class body level.
2. Use deferred access: reference other autoloads inside `_ready()` or later lifecycle methods, never in variable declarations.
3. EventBus should be completely standalone — it exposes signals, it does not consume them.

### Issue 4: Scene not loading — blank screen after transition

**Symptoms:** `SceneRouter.change_scene()` is called, the old scene disappears, but the new scene never appears.

**Causes:**
- The target `.tscn` file exists but has a broken root node or missing script.
- The scene path is correct but the scene has an error in its `_ready()` that crashes silently.
- The scene tree is in a transitional state and the new scene was freed before display.

**Resolution:**
1. Open the target `.tscn` in the editor and verify it displays correctly.
2. Check the Output panel for errors after the transition call.
3. Verify `SceneRouter.change_scene()` returns `OK`, not an error code.
4. Add `await get_tree().process_frame` after the transition to ensure one frame renders.

### Issue 5: GameManager.initialize() does nothing

**Symptoms:** `initialize()` is called but `is_initialized()` still returns `false`, or the `game_initialized` signal is never emitted.

**Causes:**
- `initialize()` is being called on a local instance, not the autoload singleton.
- A script error inside `initialize()` causes early return before the flag is set.
- The method was overridden by a subclass without calling `super.initialize()`.

**Resolution:**
1. Use the global `GameManager.initialize()`, not `var gm = GameManager.new(); gm.initialize()`.
2. Add a `print("GameManager.initialize() called")` at the top of the method for debugging.
3. Check that no exceptions are thrown before the `_initialized = true` line.

### Issue 6: Tests fail with "Cannot find class EventBus"

**Symptoms:** GUT tests fail at parse time because `EventBus` or `GameManager` class names are not recognized.

**Causes:**
- The test file is being run outside the Godot editor context (e.g., in a CI environment without project import).
- The autoload scripts have parse errors preventing `class_name` registration.
- GUT version is incompatible with Godot 4.5.

**Resolution:**
1. Ensure tests are run from within the Godot editor or via `godot --headless --script` with the correct project path.
2. Open each autoload script in the editor and confirm zero parse errors.
3. Verify GUT version compatibility with Godot 4.5 (GUT v9.x+ recommended).

---

## Section 13 · Acceptance Criteria

All criteria must pass before this task is considered complete. PAC = Playtesting Acceptance Criterion.

### Folder Structure

- [ ] **AC-001:** Directory `res://src/autoloads/` exists and contains `event_bus.gd` and `game_manager.gd`.
- [ ] **AC-002:** Directory `res://src/models/` exists (may contain only `.gdkeep`).
- [ ] **AC-003:** Directory `res://src/services/` exists (may contain only `.gdkeep`).
- [ ] **AC-004:** Directory `res://src/managers/` exists (may contain only `.gdkeep`).
- [ ] **AC-005:** Directory `res://src/ui/` exists (may contain only `.gdkeep`).
- [ ] **AC-006:** Directory `res://src/scenes/` exists and contains `main_menu.tscn`.
- [ ] **AC-007:** Directory `res://src/resources/` exists (may contain only `.gdkeep`).
- [ ] **AC-008:** Directory `res://src/shaders/` exists (may contain only `.gdkeep`).
- [ ] **AC-009:** Directory `res://src/utils/` exists and contains `scene_router.gd`.
- [ ] **AC-010:** Directory `res://tests/unit/` exists.
- [ ] **AC-011:** Directory `res://tests/integration/` exists.

### EventBus

- [ ] **AC-012:** `event_bus.gd` extends `Node` and declares `class_name EventBus`.
- [ ] **AC-013:** `event_bus.gd` declares all six typed signals: `seed_planted`, `seed_matured`, `expedition_started`, `expedition_completed`, `loot_gained`, `adventurer_recruited` — each with named, typed parameters.
- [ ] **AC-014:** Each signal in `event_bus.gd` has a `##` doc comment describing when it is emitted and what each parameter means.

### GameManager

- [ ] **AC-015:** `game_manager.gd` extends `Node` and declares `class_name GameManager`.
- [ ] **AC-016:** `game_manager.gd` has `initialize() -> void` that sets `_initialized = true` and emits `game_initialized`.
- [ ] **AC-017:** `game_manager.gd` has `shutdown() -> void` that sets `_initialized = false` and emits `game_shutdown`.
- [ ] **AC-018:** `game_manager.gd` has `is_initialized() -> bool` returning the current state.
- [ ] **AC-019:** `game_manager.gd` declares nullable typed properties `seed_grove`, `roster`, `wallet`, `loop_controller` defaulting to `null`.
- [ ] **AC-020:** `game_manager.gd` does NOT call `initialize()` in `_ready()`.

### SceneRouter

- [ ] **AC-021:** `scene_router.gd` provides `change_scene(scene_path: String) -> Error`.
- [ ] **AC-022:** `scene_router.gd` returns `ERR_FILE_NOT_FOUND` for non-existent scene paths.
- [ ] **AC-023:** `scene_router.gd` validates that the scene path starts with `"res://src/scenes/"`.
- [ ] **AC-024:** `scene_router.gd` declares `scene_change_started` and `scene_change_completed` signals.

### project.godot

- [ ] **AC-025:** `project.godot` `[autoload]` section contains `EventBus="*res://src/autoloads/event_bus.gd"`.
- [ ] **AC-026:** `project.godot` `[autoload]` section contains `GameManager="*res://src/autoloads/game_manager.gd"`.
- [ ] **AC-027:** In the `[autoload]` section, the `EventBus` line appears BEFORE the `GameManager` line.

### Playtesting Acceptance Criteria (PACs)

- [ ] **PAC-001:** Open the project in Godot 4.5 editor — zero errors in Output panel.
- [ ] **PAC-002:** Press F5 — game window appears with no crash, showing placeholder main menu.
- [ ] **PAC-003:** In the Remote scene tree inspector, `EventBus` and `GameManager` nodes are visible as autoloads.
- [ ] **PAC-004:** All GUT tests pass green with zero failures and zero errors.

---

## Section 14 · Testing Requirements

### 14.1 Test File: `tests/unit/test_event_bus.gd`

```gdscript
## Unit tests for the EventBus autoload singleton.
## Verifies all six core-loop signals are declared, typed, and emittable.
extends GutTest


func test_event_bus_is_node() -> void:
	var bus := EventBus.new()
	assert_is(bus, Node, "EventBus must extend Node")
	bus.free()


func test_seed_planted_signal_exists() -> void:
	var bus := EventBus.new()
	assert_true(bus.has_signal("seed_planted"), "EventBus must have seed_planted signal")
	bus.free()


func test_seed_matured_signal_exists() -> void:
	var bus := EventBus.new()
	assert_true(bus.has_signal("seed_matured"), "EventBus must have seed_matured signal")
	bus.free()


func test_expedition_started_signal_exists() -> void:
	var bus := EventBus.new()
	assert_true(bus.has_signal("expedition_started"), "EventBus must have expedition_started signal")
	bus.free()


func test_expedition_completed_signal_exists() -> void:
	var bus := EventBus.new()
	assert_true(bus.has_signal("expedition_completed"), "EventBus must have expedition_completed signal")
	bus.free()


func test_loot_gained_signal_exists() -> void:
	var bus := EventBus.new()
	assert_true(bus.has_signal("loot_gained"), "EventBus must have loot_gained signal")
	bus.free()


func test_adventurer_recruited_signal_exists() -> void:
	var bus := EventBus.new()
	assert_true(bus.has_signal("adventurer_recruited"), "EventBus must have adventurer_recruited signal")
	bus.free()


func test_seed_planted_emission() -> void:
	var bus := EventBus.new()
	add_child(bus)
	watch_signals(bus)
	bus.seed_planted.emit(&"oak_seed", 0)
	assert_signal_emitted(bus, "seed_planted")
	bus.queue_free()


func test_seed_matured_emission() -> void:
	var bus := EventBus.new()
	add_child(bus)
	watch_signals(bus)
	bus.seed_matured.emit(&"oak_seed", 0)
	assert_signal_emitted(bus, "seed_matured")
	bus.queue_free()


func test_expedition_started_emission() -> void:
	var bus := EventBus.new()
	add_child(bus)
	watch_signals(bus)
	var party: Array[StringName] = [&"warrior_01", &"mage_01"]
	bus.expedition_started.emit(&"forest_dungeon", party)
	assert_signal_emitted(bus, "expedition_started")
	bus.queue_free()


func test_expedition_completed_emission() -> void:
	var bus := EventBus.new()
	add_child(bus)
	watch_signals(bus)
	bus.expedition_completed.emit(&"forest_dungeon", true, 42)
	assert_signal_emitted(bus, "expedition_completed")
	bus.queue_free()


func test_loot_gained_emission() -> void:
	var bus := EventBus.new()
	add_child(bus)
	watch_signals(bus)
	bus.loot_gained.emit(&"iron_ore", 5, &"dungeon_chest")
	assert_signal_emitted(bus, "loot_gained")
	bus.queue_free()


func test_adventurer_recruited_emission() -> void:
	var bus := EventBus.new()
	add_child(bus)
	watch_signals(bus)
	bus.adventurer_recruited.emit(&"hero_001", &"warrior")
	assert_signal_emitted(bus, "adventurer_recruited")
	bus.queue_free()
```

### 14.2 Test File: `tests/unit/test_game_manager.gd`

```gdscript
## Unit tests for the GameManager autoload singleton.
## Verifies lifecycle methods, initialization state, and service placeholders.
extends GutTest


func test_game_manager_is_node() -> void:
	var gm := GameManager.new()
	assert_is(gm, Node, "GameManager must extend Node")
	gm.free()


func test_not_initialized_by_default() -> void:
	var gm := GameManager.new()
	assert_false(gm.is_initialized(), "GameManager must not be initialized by default")
	gm.free()


func test_initialize_sets_flag() -> void:
	var gm := GameManager.new()
	add_child(gm)
	gm.initialize()
	assert_true(gm.is_initialized(), "initialize() must set _initialized to true")
	gm.queue_free()


func test_initialize_emits_signal() -> void:
	var gm := GameManager.new()
	add_child(gm)
	watch_signals(gm)
	gm.initialize()
	assert_signal_emitted(gm, "game_initialized")
	gm.queue_free()


func test_shutdown_clears_flag() -> void:
	var gm := GameManager.new()
	add_child(gm)
	gm.initialize()
	gm.shutdown()
	assert_false(gm.is_initialized(), "shutdown() must set _initialized to false")
	gm.queue_free()


func test_shutdown_emits_signal() -> void:
	var gm := GameManager.new()
	add_child(gm)
	watch_signals(gm)
	gm.initialize()
	gm.shutdown()
	assert_signal_emitted(gm, "game_shutdown")
	gm.queue_free()


func test_service_properties_default_to_null() -> void:
	var gm := GameManager.new()
	assert_null(gm.seed_grove, "seed_grove must default to null")
	assert_null(gm.roster, "roster must default to null")
	assert_null(gm.wallet, "wallet must default to null")
	assert_null(gm.loop_controller, "loop_controller must default to null")
	gm.free()


func test_double_initialize_is_safe() -> void:
	var gm := GameManager.new()
	add_child(gm)
	gm.initialize()
	gm.initialize()
	assert_true(gm.is_initialized(), "Double initialize must not break state")
	gm.queue_free()


func test_shutdown_without_initialize_is_safe() -> void:
	var gm := GameManager.new()
	add_child(gm)
	gm.shutdown()
	assert_false(gm.is_initialized(), "Shutdown without init must not break state")
	gm.queue_free()
```

### 14.3 Test File: `tests/unit/test_scene_router.gd`

```gdscript
## Unit tests for the SceneRouter utility.
## Verifies path validation, error handling, and signal declarations.
extends GutTest

const SceneRouterClass := preload("res://src/utils/scene_router.gd")


func test_scene_router_has_change_scene_method() -> void:
	var router := SceneRouterClass.new()
	assert_true(router.has_method("change_scene"), "SceneRouter must have change_scene method")
	router.free()


func test_scene_router_rejects_nonexistent_path() -> void:
	var router := SceneRouterClass.new()
	add_child(router)
	var result: Error = router.change_scene("res://src/scenes/does_not_exist.tscn")
	assert_eq(result, ERR_FILE_NOT_FOUND, "Must return ERR_FILE_NOT_FOUND for missing scene")
	router.queue_free()


func test_scene_router_rejects_invalid_prefix() -> void:
	var router := SceneRouterClass.new()
	add_child(router)
	var result: Error = router.change_scene("res://some/other/path.tscn")
	assert_ne(result, OK, "Must reject paths outside res://src/scenes/")
	router.queue_free()


func test_scene_router_has_started_signal() -> void:
	var router := SceneRouterClass.new()
	assert_true(router.has_signal("scene_change_started"), "Must have scene_change_started signal")
	router.free()


func test_scene_router_has_completed_signal() -> void:
	var router := SceneRouterClass.new()
	assert_true(router.has_signal("scene_change_completed"), "Must have scene_change_completed signal")
	router.free()
```

---

## Section 15 · Playtesting Verification

### PV-01: Clean Project Open

| Field | Detail |
|-------|--------|
| **Setup** | Clone repository. Open `project.godot` in Godot 4.5 editor. |
| **Action** | Wait for import to complete. Observe the Output panel. |
| **Expected** | Zero errors, zero warnings related to autoloads, scripts, or missing files. The FileSystem dock shows the full folder structure. |
| **Pass/Fail** | ☐ |

### PV-02: Run to Main Scene

| Field | Detail |
|-------|--------|
| **Setup** | Project is open in editor with successful import. |
| **Action** | Press F5 (Run Project). |
| **Expected** | A game window opens within 3 seconds. The window shows the placeholder main menu (may be blank). No crash, no error dialog. |
| **Pass/Fail** | ☐ |

### PV-03: Autoloads Visible in Remote Tree

| Field | Detail |
|-------|--------|
| **Setup** | Game is running (F5). |
| **Action** | Switch to the "Remote" tab in the Scene dock. Expand the root node. |
| **Expected** | `EventBus` and `GameManager` appear as child nodes of root, in that order. Both are green (active). |
| **Pass/Fail** | ☐ |

### PV-04: EventBus Signal Verification

| Field | Detail |
|-------|--------|
| **Setup** | Open `res://src/autoloads/event_bus.gd` in the script editor. |
| **Action** | Read the signal declarations. Hover over each signal name to view the doc comment tooltip. |
| **Expected** | Six signals are declared with typed parameters. Each has a `##` doc comment. No red underlines or parse errors. |
| **Pass/Fail** | ☐ |

### PV-05: GameManager Lifecycle Verification

| Field | Detail |
|-------|--------|
| **Setup** | Open `res://src/autoloads/game_manager.gd` in the script editor. |
| **Action** | Read `initialize()` and `shutdown()` methods. Verify `_ready()` does NOT call `initialize()`. |
| **Expected** | `initialize()` sets `_initialized = true` and emits `game_initialized`. `shutdown()` sets `_initialized = false` and emits `game_shutdown`. `_ready()` has no call to `initialize()`. |
| **Pass/Fail** | ☐ |

### PV-06: SceneRouter Path Validation

| Field | Detail |
|-------|--------|
| **Setup** | Open `res://src/utils/scene_router.gd` in the script editor. |
| **Action** | Read the `change_scene()` method. Verify path prefix check and `ResourceLoader.exists()` call. |
| **Expected** | Method checks that path starts with `"res://src/scenes/"`. Method checks `ResourceLoader.exists()`. Returns `ERR_FILE_NOT_FOUND` on failure. |
| **Pass/Fail** | ☐ |

### PV-07: GUT Test Suite Passes

| Field | Detail |
|-------|--------|
| **Setup** | GUT addon is installed in `addons/gut/`. |
| **Action** | Open the GUT runner panel. Run all tests in `tests/unit/`. |
| **Expected** | All tests pass green. Zero failures, zero errors. Console shows test count and pass count matching. |
| **Pass/Fail** | ☐ |

### PV-08: Folder Structure Completeness

| Field | Detail |
|-------|--------|
| **Setup** | Project is open in editor. |
| **Action** | Expand every folder in the FileSystem dock. Verify against the canonical folder tree in Section 2.4. |
| **Expected** | All 11 directories exist: `src/autoloads/`, `src/models/`, `src/services/`, `src/managers/`, `src/ui/`, `src/scenes/`, `src/resources/`, `src/shaders/`, `src/utils/`, `tests/unit/`, `tests/integration/`. Empty folders contain `.gdkeep` so they are tracked by git. |
| **Pass/Fail** | ☐ |

---

## Section 16 · Implementation Prompt

> **This section contains the complete, copy-pasteable GDScript implementation.**
> Every file below is production-ready. No stubs, no TODOs, no placeholders.

### 16.1 `src/autoloads/event_bus.gd`

```gdscript
## EventBus — Central signal bus for Dungeon Seed.
##
## All cross-system communication flows through this singleton.
## Signals map directly to the GDD core-loop transitions:
##   Plant Seed → Grow Dungeon → Monitor → Dispatch → Clear → Harvest → Upgrade → Unlock
##
## Usage:
##   EventBus.seed_planted.connect(_on_seed_planted)
##   EventBus.seed_planted.emit(&"oak_seed", 0)
##
## This autoload is registered FIRST in project.godot to guarantee
## availability when GameManager and all other systems initialize.
class_name EventBus
extends Node


# ─── Core Loop Signals ────────────────────────────────────────────────

## Emitted when a seed is placed into a grove slot.
## [param seed_id] The unique identifier of the seed being planted.
## [param slot_index] The zero-based index of the grove slot.
signal seed_planted(seed_id: StringName, slot_index: int)

## Emitted when a planted seed completes its growth cycle and the dungeon is ready.
## [param seed_id] The unique identifier of the matured seed.
## [param slot_index] The zero-based index of the grove slot.
signal seed_matured(seed_id: StringName, slot_index: int)

## Emitted when an adventuring party is dispatched into a dungeon.
## [param dungeon_id] The unique identifier of the target dungeon.
## [param party_ids] Array of adventurer IDs forming the party.
signal expedition_started(dungeon_id: StringName, party_ids: Array[StringName])

## Emitted when an expedition resolves (success or failure).
## [param dungeon_id] The unique identifier of the completed dungeon.
## [param success] Whether the party cleared the dungeon.
## [param turns_taken] Number of turns the expedition consumed.
signal expedition_completed(dungeon_id: StringName, success: bool, turns_taken: int)

## Emitted when the player gains loot from any source.
## [param item_id] The unique identifier of the gained item.
## [param quantity] The number of items gained.
## [param source] The origin of the loot (e.g., "dungeon_chest", "quest_reward").
signal loot_gained(item_id: StringName, quantity: int, source: StringName)

## Emitted when a new adventurer joins the player's roster.
## [param adventurer_id] The unique identifier of the recruited adventurer.
## [param class_type] The adventurer's class (e.g., "warrior", "mage", "healer").
signal adventurer_recruited(adventurer_id: StringName, class_type: StringName)
```

### 16.2 `src/autoloads/game_manager.gd`

```gdscript
## GameManager — Lifecycle-managing singleton for Dungeon Seed.
##
## Holds references to all active domain services and provides orderly
## initialize/shutdown sequencing. Services are registered as typed
## nullable properties that downstream tasks will populate.
##
## Usage:
##   GameManager.initialize()       # Call from main scene _ready()
##   GameManager.is_initialized()   # Check before accessing services
##   GameManager.shutdown()         # Call on game exit
##
## IMPORTANT: initialize() is NOT called in _ready(). The main scene
## or a bootstrap script must call it explicitly. This allows test
## harnesses and menus to exist without full game state.
class_name GameManager
extends Node


# ─── Signals ──────────────────────────────────────────────────────────

## Emitted after all services have been initialized and the game is ready.
signal game_initialized

## Emitted after all services have been shut down cleanly.
signal game_shutdown


# ─── Service References ───────────────────────────────────────────────
## These are typed as RefCounted (the common base for non-Node services).
## Downstream tasks will replace the type annotations with concrete types.

## Reference to the SeedGrove service (manages seed collection and planting).
var seed_grove: RefCounted = null

## Reference to the Roster service (manages adventurer team).
var roster: RefCounted = null

## Reference to the Wallet service (manages currencies and resources).
var wallet: RefCounted = null

## Reference to the LoopController service (manages the core game loop).
var loop_controller: RefCounted = null


# ─── Private State ────────────────────────────────────────────────────

## Whether initialize() has been called successfully.
var _initialized: bool = false


# ─── Lifecycle ────────────────────────────────────────────────────────

## Returns whether the GameManager has been initialized.
func is_initialized() -> bool:
	return _initialized


## Initializes all game services in the correct order.
## Call this from the main scene's _ready() or a bootstrap script.
## Safe to call multiple times — subsequent calls are no-ops.
func initialize() -> void:
	if _initialized:
		push_warning("GameManager.initialize() called but already initialized. Ignoring.")
		return

	# Future: instantiate and wire up services here.
	# seed_grove = SeedGroveService.new()
	# roster = RosterService.new()
	# wallet = WalletService.new()
	# loop_controller = LoopControllerService.new()

	_initialized = true
	game_initialized.emit()
	print("[GameManager] Initialized.")


## Shuts down all game services in reverse order.
## Call this on game exit or when returning to the title screen.
## Safe to call without prior initialize() — will no-op gracefully.
func shutdown() -> void:
	if not _initialized:
		push_warning("GameManager.shutdown() called but not initialized. Ignoring.")
		return

	# Future: tear down services in reverse order.
	# loop_controller = null
	# wallet = null
	# roster = null
	# seed_grove = null

	_initialized = false
	game_shutdown.emit()
	print("[GameManager] Shut down.")
```

### 16.3 `src/utils/scene_router.gd`

```gdscript
## SceneRouter — Scene transition utility for Dungeon Seed.
##
## Wraps get_tree().change_scene_to_file() with:
## - Path prefix validation (must start with "res://src/scenes/")
## - File existence check via ResourceLoader.exists()
## - Transition signals for UI fade-in/fade-out hooks
##
## Usage:
##   var router := SceneRouter.new()
##   add_child(router)
##   var err := router.change_scene("res://src/scenes/seed_grove.tscn")
##   if err != OK:
##       push_error("Scene transition failed")
##
## SceneRouter is NOT an autoload — it is instantiated by the system
## that needs scene transitions (typically GameManager or a UI controller).
class_name SceneRouter
extends Node


# ─── Constants ────────────────────────────────────────────────────────

## All valid scene paths must start with this prefix.
const SCENE_PATH_PREFIX: String = "res://src/scenes/"


# ─── Signals ──────────────────────────────────────────────────────────

## Emitted immediately before the scene transition begins.
## [param target_path] The validated scene path being loaded.
signal scene_change_started(target_path: String)

## Emitted after the scene transition completes successfully.
## [param target_path] The scene path that was loaded.
signal scene_change_completed(target_path: String)


# ─── Public API ───────────────────────────────────────────────────────

## Transitions to the specified scene with validation.
##
## [param scene_path] The full res:// path to the target .tscn file.
## [return] OK on success, ERR_INVALID_PARAMETER for bad prefix,
##          ERR_FILE_NOT_FOUND if the scene does not exist.
func change_scene(scene_path: String) -> Error:
	# Validate path prefix
	if not scene_path.begins_with(SCENE_PATH_PREFIX):
		push_error(
			"SceneRouter: Invalid scene path prefix. Expected '%s', got '%s'."
			% [SCENE_PATH_PREFIX, scene_path]
		)
		return ERR_INVALID_PARAMETER

	# Validate file existence
	if not ResourceLoader.exists(scene_path):
		push_error("SceneRouter: Scene file not found: '%s'." % scene_path)
		return ERR_FILE_NOT_FOUND

	# Perform transition
	scene_change_started.emit(scene_path)

	var tree := get_tree()
	if tree == null:
		push_error("SceneRouter: Not in scene tree. Cannot change scene.")
		return ERR_UNCONFIGURED

	var result: Error = tree.change_scene_to_file(scene_path)
	if result == OK:
		scene_change_completed.emit(scene_path)
	else:
		push_error("SceneRouter: change_scene_to_file() returned error: %s" % error_string(result))

	return result
```

### 16.4 `project.godot` (complete file after modification)

```ini
config_version=5

[application]

config/name="Dungeon Seed"
config/description="A deterministic dungeon-crawl game"
run/main_scene="res://src/scenes/main_menu.tscn"
config/features=PackedStringArray("4.5")
config/author="Dev Team"

[autoload]

EventBus="*res://src/autoloads/event_bus.gd"
GameManager="*res://src/autoloads/game_manager.gd"

[rendering]

use_vsync=false
```

### 16.5 `src/scenes/main_menu.tscn` (minimal placeholder)

```ini
[gd_scene format=3 uid="uid://placeholder_main_menu"]

[node name="MainMenu" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
```

### 16.6 Folder Placeholder Files

Create `.gdkeep` (empty file) in each empty directory to ensure git tracks them:

```
src/models/.gdkeep
src/services/.gdkeep
src/managers/.gdkeep
src/ui/.gdkeep
src/resources/.gdkeep
src/shaders/.gdkeep
tests/unit/.gdkeep
tests/integration/.gdkeep
```

### 16.7 Implementation Checklist

| Step | Action | Files |
|------|--------|-------|
| 1 | Create folder structure | All `src/*/` and `tests/*/` directories |
| 2 | Create `.gdkeep` in empty folders | 8 files |
| 3 | Create `event_bus.gd` | `src/autoloads/event_bus.gd` |
| 4 | Create `game_manager.gd` | `src/autoloads/game_manager.gd` |
| 5 | Create `scene_router.gd` | `src/utils/scene_router.gd` |
| 6 | Create `main_menu.tscn` placeholder | `src/scenes/main_menu.tscn` |
| 7 | Modify `project.godot` to add `[autoload]` section | `project.godot` |
| 8 | Create test files | `tests/unit/test_event_bus.gd`, `tests/unit/test_game_manager.gd`, `tests/unit/test_scene_router.gd` |
| 9 | Open project in Godot 4.5, verify zero errors | Manual |
| 10 | Press F5, verify game runs to placeholder screen | Manual |
| 11 | Run GUT test suite, verify all green | Manual |

---

*End of TASK-001: Project Bootstrap & Autoload Skeleton*
