# Dungeon Seed — Game Development Pipeline Rulebook

> **Version**: 1.0.0  
> **Created**: 2026-04-13  
> **Epic**: Dungeon Seed  
> **Engine**: Godot 4.x (GDScript)

---

## 🔴 ABSOLUTE RULE: DELEGATE EVERYTHING

The Epic Orchestrator **NEVER writes code, tickets, plans, tests, assets, or design documents directly**. Every artifact is produced by invoking a specialized subagent via `task()`. The orchestrator's only job is to:

1. **Decide** which agent to invoke next (consult the pipeline below)
2. **Compose** a brief prompt (≤3 lines) pointing the agent at input files
3. **Invoke** the agent via `task(agent_type="Agent Name", ...)`
4. **Verify** the output file exists on disk
5. **Update** EPIC-TRACKER.md
6. **Repeat** with the next pipeline stage

---

## Game Development Pipeline Stages

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    DUNGEON SEED PIPELINE FLOW                            │
│                                                                          │
│  STAGE 0: VISION & DESIGN                                               │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────────┐     │
│  │ Game Vision      │─▶│ Narrative         │─▶│ Game Architecture  │     │
│  │ Architect         │  │ Designer          │  │ Planner            │     │
│  │ (GDD)            │  │ (Lore/Story)      │  │ (Tech Architecture)│     │
│  └─────────────────┘  └──────────────────┘  └────────────────────┘     │
│                                                                          │
│  STAGE 1: DECOMPOSITION                                                 │
│  ┌─────────────────┐                                                    │
│  │ The Decomposer   │ → DECOMPOSITION.md with dependency graph          │
│  └─────────────────┘                                                    │
│                                                                          │
│  STAGE 2: TICKET GENERATION                                             │
│  ┌─────────────────┐                                                    │
│  │ Game Ticket       │ → One ticket per task (16-section format)         │
│  │ Writer            │   Fresh subagent per ticket                       │
│  └─────────────────┘                                                    │
│                                                                          │
│  STAGE 3: IMPLEMENTATION PLANNING                                       │
│  ┌──────────────────────┐                                               │
│  │ Implementation Plan   │ → Phased checkbox plan per ticket             │
│  │ Builder               │   Fresh subagent per plan                     │
│  └──────────────────────┘                                               │
│                                                                          │
│  STAGE 4: DESIGN & SPECIFICATION (per-domain, parallel)                 │
│  ┌────────────────┐ ┌──────────────────┐ ┌───────────────────┐         │
│  │ Character       │ │ Combat System    │ │ Game Economist    │         │
│  │ Designer        │ │ Builder          │ │                   │         │
│  └────────────────┘ └──────────────────┘ └───────────────────┘         │
│  ┌────────────────┐ ┌──────────────────┐ ┌───────────────────┐         │
│  │ AI Behavior     │ │ World            │ │ Game Art          │         │
│  │ Designer        │ │ Cartographer     │ │ Director          │         │
│  └────────────────┘ └──────────────────┘ └───────────────────┘         │
│  ┌────────────────┐ ┌──────────────────┐ ┌───────────────────┐         │
│  │ Game Audio      │ │ Game UI          │ │ Weapon & Equipment│         │
│  │ Director        │ │ Designer         │ │ Forger            │         │
│  └────────────────┘ └──────────────────┘ └───────────────────┘         │
│                                                                          │
│  STAGE 5: IMPLEMENTATION (per-task, dependency order)                   │
│  ┌──────────────────┐                                                   │
│  │ Game Code         │ → GDScript code, .tscn scenes, .tres resources   │
│  │ Executor          │   Follows plan checkboxes, runs tests            │
│  └──────────────────┘                                                   │
│                                                                          │
│  STAGE 5b: ASSET GENERATION (parallel with code)                        │
│  ┌────────────────┐ ┌──────────────────┐ ┌───────────────────┐         │
│  │ Procedural Asset│ │ Sprite Sheet     │ │ Sprite Animation  │         │
│  │ Generator       │ │ Generator        │ │ Generator         │         │
│  └────────────────┘ └──────────────────┘ └───────────────────┘         │
│  ┌────────────────┐ ┌──────────────────┐ ┌───────────────────┐         │
│  │ Audio Composer  │ │ VFX Designer     │ │ Tilemap Level     │         │
│  │                 │ │                  │ │ Designer          │         │
│  └────────────────┘ └──────────────────┘ └───────────────────┘         │
│                                                                          │
│  STAGE 6: QUALITY & BALANCE                                             │
│  ┌────────────────┐ ┌──────────────────┐ ┌───────────────────┐         │
│  │ Balance Auditor │ │ Playtest         │ │ Quality Gate      │         │
│  │                 │ │ Simulator        │ │ Reviewer          │         │
│  └────────────────┘ └──────────────────┘ └───────────────────┘         │
│                                                                          │
│  STAGE 7: POLISH & ACCESSIBILITY                                        │
│  ┌────────────────┐ ┌──────────────────┐ ┌───────────────────┐         │
│  │ Accessibility   │ │ Camera System    │ │ Game HUD          │         │
│  │ Auditor         │ │ Architect        │ │ Engineer          │         │
│  └────────────────┘ └──────────────────┘ └───────────────────┘         │
│                                                                          │
│  STAGE 8: BUILD & DISTRIBUTION                                          │
│  ┌────────────────┐ ┌──────────────────┐ ┌───────────────────┐         │
│  │ Game Build &    │ │ Store Submission │ │ Patch & Update    │         │
│  │ Packaging       │ │ Specialist       │ │ Manager           │         │
│  └────────────────┘ └──────────────────┘ └───────────────────┘         │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Agent-to-Stage Mapping

### Stage 0: Vision & Design (Run Once at Epic Start)

| Agent | `task()` agent_type | Produces | When |
|-------|---------------------|----------|------|
| Game Vision Architect | `"Game Vision Architect"` | GDD.md (50-100KB Game Design Document) | Epic kickoff |
| Narrative Designer | `"Narrative Designer"` | Lore bible, faction relationships, quest arcs | After GDD |
| Game Architecture Planner | `"Game Architecture Planner"` | Technical architecture, engine config, scene management | After GDD |
| Game Art Director | `"Game Art Director"` | Style guide, color palettes, visual identity | After GDD |
| Game Audio Director | `"Game Audio Director"` | Audio identity, music direction, SFX taxonomy | After GDD |

### Stage 1: Decomposition

| Agent | `task()` agent_type | Produces | When |
|-------|---------------------|----------|------|
| The Decomposer | `"general-purpose"` | DECOMPOSITION.md with dependency graph | After Stage 0 |

### Stage 2: Ticket Generation (One Per Task)

| Agent | `task()` agent_type | Produces | When |
|-------|---------------------|----------|------|
| Game Ticket Writer | `"Game Ticket Writer"` | 16-section ticket .md per task | After decomposition approved |

**🔴 RULE**: Fresh subagent per ticket. Never batch.

### Stage 3: Implementation Planning (One Per Ticket)

| Agent | `task()` agent_type | Produces | When |
|-------|---------------------|----------|------|
| Implementation Plan Builder | `"general-purpose"` | Phased checkbox plan .md per ticket | After ticket exists on disk |

**🔴 RULE**: Fresh subagent per plan. Never batch.

### Stage 4: Domain Design (Parallel, Per-System)

These agents produce **design specifications** (JSON/MD) that feed into Stage 5 implementation.

| Agent | `task()` agent_type | Produces | When |
|-------|---------------------|----------|------|
| Character Designer | `"Character Designer"` | Character sheets, stat systems, ability trees | Tasks involving characters |
| Combat System Builder | `"Combat System Builder"` | Damage formulas, skill trees, hitbox data | Tasks involving combat |
| Game Economist | `"Game Economist"` | Currency systems, drop tables, economy model | Tasks involving economy/loot |
| AI Behavior Designer | `"AI Behavior Designer"` | Behavior trees, state machines, enemy AI | Tasks involving AI/enemies |
| World Cartographer | `"World Cartographer"` | World map, biome definitions, dungeon layouts | Tasks involving world/levels |
| Game UI Designer | `"Game UI Designer"` | Screen-based UI specs, menu flows | Tasks involving UI screens |
| Game HUD Engineer | `"Game HUD Engineer"` | HUD overlay specs, health bars, minimaps | Tasks involving HUD |
| Weapon & Equipment Forger | `"Weapon & Equipment Forger"` | Equipment databases, loot tables, item specs | Tasks involving items/gear |
| Pet Companion System Builder | `"Pet Companion System Builder"` | Pet bonding, evolution, companion AI | Tasks involving companions |
| Crafting System Builder | `"Crafting System Builder"` | Recipe databases, workstation networks | Tasks involving crafting |

### Stage 5: Implementation (Per-Task, Dependency Order)

| Agent | `task()` agent_type | Produces | When |
|-------|---------------------|----------|------|
| Game Code Executor | `"Game Code Executor"` | GDScript .gd, .tscn scenes, .tres resources, tests | After plan exists + deps pass audit |

**🔴 RULE**: One task at a time. Verify plan checkboxes updated after completion.

### Stage 5b: Asset Generation (Parallel with Code)

| Agent | `task()` agent_type | Produces | When |
|-------|---------------------|----------|------|
| Procedural Asset Generator | `"Procedural Asset Generator"` | 3D models, 2D sprites, textures, tilesets | After art direction established |
| Sprite Sheet Generator | `"Sprite Sheet Generator"` | Sprite frames, atlas sheets, frame data JSON | After character/creature designs |
| Sprite Animation Generator | `"Sprite Animation Generator"` | Animation sequences, SpriteFrames .tres | After sprite sheets exist |
| Animation Sequencer | `"Animation Sequencer"` | AnimationTree state machines, blend spaces | After sprite frames exist |
| Audio Composer | `"Audio Composer"` | WAV/OGG music, SFX, ambient audio | After audio direction established |
| VFX Designer | `"VFX Designer"` | GPUParticles2D configs, .gdshader effects | After art direction established |
| Tilemap Level Designer | `"Tilemap Level Designer"` | Godot 4 tilemaps, collision, navigation | After world cartography + tile assets |
| Scene Compositor | `"Scene Compositor"` | Populated game regions, object placement | After tilemap + asset generation |
| Texture & Material Artist | `"Texture & Material Artist"` | PBR textures, materials, shader graphs | After art direction established |

### Stage 6: Quality & Balance

| Agent | `task()` agent_type | Produces | When |
|-------|---------------------|----------|------|
| Balance Auditor | `"Balance Auditor"` | Balance report (scored 0-100), Monte Carlo results | After combat/economy implemented |
| Playtest Simulator | `"Playtest Simulator"` | Playtest reports, behavioral heatmaps, friction findings | After core loop implemented |
| Quality Gate Reviewer | `"Quality Gate Reviewer"` | Audit report with verdict (PASS/COND/FAIL) | After each task implementation |

### Stage 7: Polish & Accessibility

| Agent | `task()` agent_type | Produces | When |
|-------|---------------------|----------|------|
| Accessibility Auditor | `"Accessibility Auditor"` | WCAG compliance report, remediation plan | After UI implemented |
| Camera System Architect | `"Camera System Architect"` | Camera configs, SpringArm rigs, shake generators | After dungeon rendering |
| Cinematic Director | `"Cinematic Director"` | Cutscene sequences, camera paths, storyboards | After core scenes exist |
| Photo Mode Designer | `"Photo Mode Designer"` | Photo mode system, filters, capture | Late polish phase |
| Weather & Day-Night Cycle Designer | `"Weather & Day-Night Cycle Designer"` | Time/weather simulation, skybox rendering | Late polish phase |

### Stage 8: Build & Distribution

| Agent | `task()` agent_type | Produces | When |
|-------|---------------------|----------|------|
| Game Build & Packaging Specialist | `"Game Build & Packaging Specialist"` | Platform builds, export configs, installers | After all features complete |
| Store Submission Specialist | `"Store Submission Specialist"` | Store metadata, capsule art specs, rating questionnaires | Before launch |
| Patch & Update Manager | `"Patch & Update Manager"` | Delta patches, version management, save migration | Post-launch |
| Live Ops Designer | `"Live Ops Designer"` | Season passes, event calendars, content cadence | Post-launch planning |
| Game Analytics Designer | `"Game Analytics Designer"` | Telemetry instrumentation, dashboards, A/B tests | Pre-launch or post-launch |

---

## Pipeline Execution Rules

### Rule 1: Always Check the Pipeline

Before doing ANY work, ask:
> "What stage am I at? Which agent handles this stage?"

Then invoke that agent. Never improvise.

### Rule 2: One Agent Per Artifact

```
task(agent_type="Game Ticket Writer", name="ticket-007", prompt="...", mode="background")
```

Wait for completion. Verify file on disk. Then invoke next agent.

### Rule 3: Stage Gates Are Mandatory

| Gate | Requirement |
|------|-------------|
| Stage 0 → 1 | GDD.md exists on disk |
| Stage 1 → 2 | DECOMPOSITION.md approved by user |
| Stage 2 → 3 | Ticket .md file exists for the task |
| Stage 3 → 4/5 | Plan .md file exists for the task |
| Stage 5 → 6 | Code compiles, tests pass (verified by Game Code Executor) |
| Stage 6 → 7 | Balance verdict is PASS or CONDITIONAL |
| Stage 7 → 8 | Accessibility score meets minimum threshold |

### Rule 4: Dependency Order Within Stages

Within Stage 5 (Implementation), tasks execute in dependency order from DECOMPOSITION.md:
- Wave 1: Tasks with no dependencies (parallel OK)
- Wave 2: Tasks depending only on Wave 1 (parallel OK)
- Wave N: Continue until all tasks complete

### Rule 5: The Orchestrator's Allowed Files

The orchestrator may ONLY create/edit:
- `neil-docs/epics/dungeon-seed/EPIC-TRACKER.md`
- `neil-docs/epics/dungeon-seed/GAME-DEV-PIPELINE.md` (this file)
- Session memory files

**Everything else is delegated to subagents.**

---

## Dungeon Seed — Domain-Specific Agent Chains

### Chain A: Dungeon Generation
```
World Cartographer → Tilemap Level Designer → Scene Compositor → Game Code Executor
```

### Chain B: Combat & Enemies  
```
Character Designer → AI Behavior Designer → Combat System Builder → Game Code Executor
```

### Chain C: Loot & Economy
```
Game Economist → Weapon & Equipment Forger → Crafting System Builder → Game Code Executor
```

### Chain D: Visual Assets
```
Game Art Director → Procedural Asset Generator → Sprite Sheet Generator → Sprite Animation Generator → Animation Sequencer
```

### Chain E: Audio
```
Game Audio Director → Audio Composer
```

### Chain F: UI & HUD
```
Game UI Designer → Game HUD Engineer → Game Code Executor
```

### Chain G: Seeds & Progression (Dungeon Seed Specific)
```
Character Designer (seed entities) → Game Economist (growth curves) → Game Code Executor
```

---

## Quick Reference: Common task() Invocations

```
# Generate a ticket
task(agent_type="Game Ticket Writer", name="ticket-gen", 
     prompt="Write a game dev ticket for: <description>. Save to neil-docs/tickets/task-007-dungeon-gen.md",
     mode="background")

# Build an implementation plan  
task(agent_type="general-purpose", name="plan-build",
     prompt="Read ticket at neil-docs/tickets/task-007-dungeon-gen.md. Create implementation plan at neil-docs/implementation-plans/task-007-implementation-plan.md.",
     mode="background")

# Implement code
task(agent_type="Game Code Executor", name="impl-007",
     prompt="Execute plan at neil-docs/implementation-plans/task-007-implementation-plan.md. Ticket at neil-docs/tickets/task-007-dungeon-gen.md. Go.",
     mode="background")

# Audit implementation
task(agent_type="Quality Gate Reviewer", name="audit-007",
     prompt="Audit task-007 implementation. Ticket: neil-docs/tickets/task-007-dungeon-gen.md. Plan: neil-docs/implementation-plans/task-007-implementation-plan.md. Go.",
     mode="background")

# Design combat system
task(agent_type="Combat System Builder", name="combat-design",
     prompt="Design combat system for Dungeon Seed. Read GDD at neil-docs/epics/dungeon-seed/GDD.md. Produce damage formulas, skill trees, and combat configs.",
     mode="background")

# Balance audit
task(agent_type="Balance Auditor", name="balance-check",
     prompt="Audit balance for Dungeon Seed. Read GDD, combat configs, economy model. Run Monte Carlo simulations.",
     mode="background")
```

---

## Current Epic State

As of 2026-04-13, significant implementation exists from prior sessions (done without proper pipeline). The next step is to:

1. **Audit existing implementation** against the EPIC-TRACKER tasks
2. **Generate proper tickets** for remaining/rework tasks via Game Ticket Writer
3. **Follow the pipeline** for all future work

All 12 original tasks have code written but lack formal tickets, plans, and audits per the pipeline. The pipeline should be followed going forward for any new features, bug fixes, or rework.
