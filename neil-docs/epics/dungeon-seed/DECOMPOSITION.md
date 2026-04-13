# Decomposition: Dungeon Seed

> **Decomposed by**: The Decomposer (the-decomposer)
> **Date**: 2026-04-12
> **Input**: neil-docs/epics/dungeon-seed/GDD.md + approved epic brief
> **Target Repo(s)**: c:\Users\wrstl\source\dev-agent-tool
> **Total Tasks**: 12
> **Total Complexity**: 96 Fibonacci points
> **Waves**: 3
> **Critical Path**: 5 tasks (49 points)

---

## Epic Summary

Dungeon Seed is a hybrid idle/RPG progression epic in which players plant magical seeds that sprout into procedurally generated dungeons over time. The core experience centers on growing dungeons, choosing mutations, dispatching adventurers, harvesting loot, and reinvesting rewards into seeds and hero progression. This decomposition splits the work into foundation design, core system implementation, and integration for a first playable MVP consistent with the GDD’s Seedwarden fantasy and growth loop.

---

## Task Registry

| # | Task Name | Complexity | Dependencies | Wave | On Critical Path? |
|---|-----------|-----------|-------------|------|-------------------|
| 1 | Set up Godot project with basic scenes | 5 | None | 1 | ✅ |
| 2 | Define domain models, save contracts, and progression schemas | 5 | Task 1 | 1 | ❌ |
| 3 | Design core gameplay systems | 8 | Task 1 | 1 | ❌ |
| 4 | Design UI/UX framework and visual themes | 5 | Task 1 | 1 | ❌ |
| 5 | Define audio and lore foundation | 5 | Task 1 | 1 | ❌ |
| 6 | Implement persistence and state serialization | 8 | Tasks 1,2 | 2 | ❌ |
| 7 | Implement procedural dungeon generator and room templates | 13 | Tasks 2,3 | 2 | ✅ |
| 8 | Implement adventurer management and recruitment engine | 13 | Tasks 2,3 | 2 | ❌ |
| 9 | Implement loot economy and reward systems | 8 | Tasks 2,3 | 2 | ❌ |
| 10 | Build core game loop orchestration | 13 | Tasks 6,7,8,9 | 3 | ✅ |
| 11 | Implement seed growth, mutation, progression, and unlocks | 13 | Tasks 7,8,9 | 3 | ✅ |
| 12 | Build planting/dispatch UI, dungeon rendering integration, and MVP polish | 5 | Tasks 4,7,10,11 | 3 | ✅ |

---

## Dependency Graph

```
Task 1 (Project, 5pts) ──→ Task 2 (Models, 5pts) ──→ Task 6 (Persistence, 8pts) ──→ Task 10 (Loop, 13pts) ──→ Task 12 (UI/Render MVP, 5pts)
                       ╲                             ╱
                        → Task 3 (Design, 8pts) ──→ Task 7 (Dungeon Gen, 13pts) ──┐
                       ╱                             ╲                       │
Task 4 (UI/Theme, 5pts) ──────────────────────────────→ Task 12 (UI/Render MVP, 5pts) │
                       ╱                                                     │
Task 5 (Audio/Lore, 5pts) ───────────────────────────────────────────────────────┘

Task 3 (Design, 8pts) ──→ Task 8 (Adventurer, 13pts) ──→
                                                  ╲
                                                   → Task 10 (Loop, 13pts)
                                                  ╱
Task 3 (Design, 8pts) ──→ Task 9 (Loot, 8pts) ──────┘

Task 7 (Dungeon Gen, 13pts) ──→ Task 11 (Growth/Progression, 13pts) ──→ Task 12 (UI/Render MVP, 5pts)
Task 8 (Adventurer, 13pts) ──┘
Task 9 (Loot, 8pts) ─────────┘
```

---

## Wave Plan

### Wave 1 — Foundation (no dependencies after project bootstrap)
| Task | Complexity | Description |
|------|-----------|-------------|
| Task 1 | 5 | Establish the Godot 4.x project, main scene setup, and core folder structure. |
| Task 2 | 5 | Define the data model, save/load contract, and progression schema for seeds, dungeons, heroes, and rewards. |
| Task 3 | 8 | Design the core gameplay systems for seed-based dungeon generation, adventurer progression, and the loot economy. |
| Task 4 | 5 | Create the UI/UX framework, hub flow, and dungeon theme guide for the first biomes. |
| Task 5 | 5 | Define audio direction and lore foundations that support the Seedwarden fantasy and magical dungeon world. |

### Wave 2 — Core implementation
| Task | Complexity | Description | Blocked By |
|------|-----------|-------------|------------|
| Task 6 | 8 | Implement persistence, versioned save state, and serialization so game progress survives sessions. | Tasks 1,2 |
| Task 7 | 13 | Build the procedural dungeon generator, room templates, and seed-to-layout pipeline. | Tasks 2,3 |
| Task 8 | 13 | Implement adventurer recruitment, class/stat progression, and party management logic. | Tasks 2,3 |
| Task 9 | 8 | Implement the loot economy, drop rewards, inventory credits, and resource sinks for upgrades. | Tasks 2,3 |

### Wave 3 — Integration and MVP delivery
| Task | Complexity | Description | Blocked By |
|------|-----------|-------------|------------|
| Task 10 | 13 | Create the core game loop manager that orchestrates planting, growth, dispatch, exploration, and harvest. | Tasks 6,7,8,9 |
| Task 11 | 13 | Implement seed growth, mutation mechanics, dungeon maturation, and progression unlock systems. | Tasks 7,8,9 |
| Task 12 | 5 | Build the planting/dispatch UI, integrate dungeon rendering with themes, and polish the first playable MVP. | Tasks 4,7,10,11 |

---

## Critical Path Analysis

```
Task 1 (5) → Task 7 (13) → Task 10 (13) → Task 11 (13) → Task 12 (5)
Total critical path: 49 points across 5 tasks
```

**Bottleneck**: Task 10 is the most consequential integration point because it must connect persistence, dungeon generation, adventurer systems, and loot flow.
**Parallelism opportunity**: Wave 1 and Wave 2 support strong parallel execution; UI, lore/audio, and economy design can proceed independently while the core generator and hero systems are built.

---

## Task Descriptions

### Task 1: Set up Godot project with basic scenes
**Complexity**: 5 | **Wave**: 1 | **Dependencies**: None

Establish the Dungeon Seed project in Godot 4.x with a clean folder structure, main scene, and runtime bootstrap. Create the root scene that can host the Seed Grove, Dungeon Dashboard, Adventurer Hall, and Vault screens. Configure input actions, project settings, export templates, and a basic scene manager. This task creates the baseline environment for all later game systems and should verify that the project opens and runs without runtime errors.

### Task 2: Define domain models, save contracts, and progression schemas
**Complexity**: 5 | **Wave**: 1 | **Dependencies**: Task 1

Detail the core data schemas for seeds, dungeons, adventurers, loot, and player progress. Define serializable contracts for save/load state and versioning. Capture the fields required by the GDD: seed rarity, affinity, growth stage, dungeon room graph, mutation state, hero stats, inventory, and economy metrics. Produce reference documents or JSON schema prototypes to keep later implementation aligned and testable.

### Task 3: Design core gameplay systems
**Complexity**: 8 | **Wave**: 1 | **Dependencies**: Task 1

Design the functional structure for the epic’s main systems: procedural dungeon generation, seed-driven growth, adventurer progression, and loot economy. Map out how seed attributes drive dungeon size, difficulty, and reward bias. Define mutation mechanics, class roles, and reward curves. Produce a system-level design that supports reproducible dungeons, idle growth pacing, and meaningful player choices.

### Task 4: Design UI/UX framework and visual themes
**Complexity**: 5 | **Wave**: 1 | **Dependencies**: Task 1

Create the UI architecture and visual design foundation for the hub experience. Define reusable UI components, layout patterns, and screen flows for planting, growth monitoring, expedition setup, and inventory. Establish dungeon theme direction for the first biome set and the visual language for seed states, room types, and rarity tiers. This serves as the guide for subsequent implementation and art integration.

### Task 5: Define audio and lore foundation
**Complexity**: 5 | **Wave**: 1 | **Dependencies**: Task 1

Capture the narrative tone and audio identity for Dungeon Seed. Define the Seedwarden story hook, world-building pillars, and the audio palette for planting, growth, dungeon atmosphere, adventurer action, and loot harvesting. This task ensures the experience maintains a coherent theme while the first playable features are developed.

### Task 6: Implement persistence and state serialization
**Complexity**: 8 | **Wave**: 2 | **Dependencies**: Tasks 1,2

Build the save/load subsystem with version-aware state serialization. Persist seed inventories, dungeon progress, hero rosters, inventory balances, and unlocked progression. Ensure the system gracefully handles corrupted files, schema upgrades, and session restoration. Add test coverage for save fidelity across multiple sessions.

### Task 7: Implement procedural dungeon generator and room templates
**Complexity**: 13 | **Wave**: 2 | **Dependencies**: Tasks 2,3

Develop the dungeon generation engine in Godot using the seed-to-layout design. Implement deterministic seed parsing, entropy mapping, room template selection, and graph connectivity. Create base room types for combat, treasure, puzzle, and rest experiences. Validate generated dungeons for navigability, difficulty scaling, and theme consistency.

### Task 8: Implement adventurer management and recruitment engine
**Complexity**: 13 | **Wave**: 2 | **Dependencies**: Tasks 2,3

Build the adventurer roster system with class definitions, recruitment flow, leveling, and equipment slots. Implement hero stats, XP gain, ability unlocks, and party selection rules. Ensure adventurer state is serializable and integrates with mission dispatch. This task underpins player choice and run planning.

### Task 9: Implement loot economy and reward systems
**Complexity**: 8 | **Wave**: 2 | **Dependencies**: Tasks 2,3

Implement the currency and reward systems that drive progression. Create loot tables, rarity tiers, resource sinks, and reward scaling tied to dungeon difficulty. Implement gold, essence, fragments, and artifact earning logic. Ensure the economy supports both idle and active reward flows.

### Task 10: Build core game loop orchestration
**Complexity**: 13 | **Wave**: 3 | **Dependencies**: Tasks 6,7,8,9

Create the central system that coordinates planting, dungeon growth, adventurer dispatch, exploration completion, and loot harvest. Implement the sequence of state transitions across idle progression, active runs, and reward unlocking. Ensure the loop is robust to interruption, save/load restore, and repeated play sessions. This is the epic’s primary integration task.

### Task 11: Implement seed growth, mutation, progression, and unlocks
**Complexity**: 13 | **Wave**: 3 | **Dependencies**: Tasks 7,8,9

Build the seed maturation mechanics, mutation reagent system, and progression unlock layer. Implement growth stages, mutation slot effects, dungeon capacity scaling, and long-term unlocks for new biomes and hero classes. Tie these systems back into dungeon generation, adventurer suitability, and loot reward pacing.

### Task 12: Build planting/dispatch UI, dungeon rendering integration, and MVP polish
**Complexity**: 5 | **Wave**: 3 | **Dependencies**: Tasks 4,7,10,11

Create the first playable frontend for seed planting, dungeon dispatch, and exploration feedback. Integrate dungeon visuals with the theme guide and render generated layouts. Polish interactions, onboarding cues, and the MVP experience. Validate that the core loop is playable end-to-end.

---

## Assumptions & Decisions

| # | Assumption/Decision | Rationale | Impact if Wrong |
|---|---------------------|-----------|-----------------|
| D-001 | Godot 4.x is the implementation engine. | The approved brief and GDD explicitly recommend Godot 4.x for this epic. | If another engine is chosen, the task breakdown changes significantly. |
| D-002 | The first release is an MVP-focused seed/dungeon/adventurer loop, not a full season system. | The brief emphasizes core loop validation and a focused first playable experience. | Expanding scope prematurely would increase schedule risk and require additional task decomposition. |
| D-003 | Audio and lore may be scoped as supporting design rather than full production work. | Narrative and audio support the MVP but are secondary to engineering integration. | If audio/lore must be fully produced now, a separate content task should be added. |

---

## Gaps & Risks

| # | Gap/Risk | Severity | Mitigation |
|---|----------|----------|------------|
| R-001 | No existing Godot implementation is present in the repo, creating startup risk. | Medium | Start with a clean project scaffold and validate early with small engine spikes. |
| R-002 | Procedural dungeon generation must be deterministic and replayable. | High | Prioritize design and automated validation as part of the dungeon generator task. |
| R-003 | Save/load consistency across dynamic dungeon and hero progression states is complex. | High | Lock down serialization contracts early and add persistence regression tests. |

---

## Codebase Research Notes

- The Dungeon Seed GDD and approved epic brief define the game as a hybrid idle/RPG progression experience with seed planting, dungeon growth, adventurer dispatch, and loot harvesting.
- The local epic folder already contains an approved brief and a previous decomposition draft; this update replaces the draft with a fresh, dependency-ordered plan.
- A related ticket exists for dungeon generation design (`neil-docs/tickets/task-004-design-dungeon-generation-algorithm.md`).
- The epic’s highest technical risks are save/load state, procedural generation correctness, and the core integration loop.

---

## Supporting Subagents

| Subagent | When Used |
|----------|-----------|
| **The Artificer** (`artificer-agent`) | If a repeatable analysis script is required for seed entropy mapping or dungeon graph validation. |
