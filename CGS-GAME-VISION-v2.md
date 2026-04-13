# CGS-Game — AI Agent Orchestration Platform for Game Development

> **Created**: 2026-07-28
> **Author**: Idea Architect Agent
> **Status**: Strategic Vision — Complete Blueprint
> **Classification**: Product Strategy
> **Lineage**: Inspired by CGS (ConverGeniSys) enterprise orchestration platform + Game Dev Agent Ecosystem (87+ agents, 9 pipelines)
> **Purpose**: THE blueprint for building a standalone, greenfield, game-development-specific AI agent orchestration platform

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Why CGS-Game Must Be Standalone](#2-why-cgs-game-must-be-standalone)
3. [Architecture Blueprint](#3-architecture-blueprint)
4. [Database Schema](#4-database-schema)
5. [MCP Tool Catalog](#5-mcp-tool-catalog)
6. [Pipeline Engine](#6-pipeline-engine)
7. [Asset Management System](#7-asset-management-system)
8. [Agent Registry & Dispatch Engine](#8-agent-registry--dispatch-engine)
9. [Dashboard & Visualization](#9-dashboard--visualization)
10. [Docker Integration](#10-docker-integration)
11. [Automation Rules & Convergence Engine](#11-automation-rules--convergence-engine)
12. [CLI Design](#12-cli-design)
13. [Quality & Audit System](#13-quality--audit-system)
14. [Build & Distribution System](#14-build--distribution-system)
15. [Playtest & Balance System](#15-playtest--balance-system)
16. [Trope Addon System](#16-trope-addon-system)
17. [Operational Rules (Inherited + Game-Specific)](#17-operational-rules)
18. [Monetization & Business Model](#18-monetization--business-model)
19. [Migration Path](#19-migration-path)
20. [Decomposition Hints](#20-decomposition-hints)
21. [Risk Inventory](#21-risk-inventory)
22. [Appendices](#22-appendices)

---

## 1. Executive Summary

### What CGS-Game Is

**CGS-Game** is a purpose-built AI agent orchestration platform for video game development. It manages the full lifecycle of game creation — from a single-sentence pitch to a shipped, multi-platform, store-certified, live-operated game — by dispatching, coordinating, and quality-gating 87+ specialized AI agents across 9 parallel pipelines.

Think of it as **the game engine for building games with AI agents.** Unity and Unreal are runtime engines — they execute game code at 60fps. CGS-Game is a **creation engine** — it orchestrates AI agents that produce the game's code, art, audio, levels, economy, narrative, and distribution artifacts.

```
One sentence: "I want a hack-and-slash isometric co-op pet trainer with chibi graphics"
    ↓
CGS-Game orchestrates 87+ agents across 9 pipelines
    ↓
Shipped game on Steam, itch.io, mobile stores — with live ops running
```

### The Core Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        CGS-GAME PLATFORM                                │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    PRESENTATION LAYER                            │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐  │   │
│  │  │ Desktop App  │  │ Web Dashboard│  │ CLI                   │  │   │
│  │  │ (Tauri+React)│  │ (localhost)  │  │ (cgs-game ...)        │  │   │
│  │  │              │  │              │  │                       │  │   │
│  │  │ • Pipeline   │  │ • 9 pipeline │  │ • init / status       │  │   │
│  │  │   canvas     │  │   status bars│  │ • dispatch / build    │  │   │
│  │  │ • Asset      │  │ • Agent pool │  │ • playtest / audit    │  │   │
│  │  │   browser    │  │ • Asset grid │  │ • ship / patch        │  │   │
│  │  │ • Agent pool │  │ • Build      │  │ • trope enable/       │  │   │
│  │  │ • Economy    │  │   matrix     │  │   disable             │  │   │
│  │  │   dashboard  │  │              │  │                       │  │   │
│  │  │ • Build      │  │              │  │                       │  │   │
│  │  │   matrix     │  │              │  │                       │  │   │
│  │  │ • Trope      │  │              │  │                       │  │   │
│  │  │   toggles    │  │              │  │                       │  │   │
│  │  └──────────────┘  └──────────────┘  └───────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                              │ IPC / WebSocket / HTTP                    │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    ORCHESTRATION LAYER                            │   │
│  │                                                                  │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐  │   │
│  │  │ ACP Server   │  │ Pipeline     │  │ Convergence Engine    │  │   │
│  │  │ (MCP Tools)  │  │ Engine       │  │                       │  │   │
│  │  │              │  │              │  │ • Audit → Fix → Re-   │  │   │
│  │  │ • ~120 tools │  │ • 9 parallel │  │   audit until ≥96     │  │   │
│  │  │ • dispatch   │  │   pipelines  │  │ • Stall detection     │  │   │
│  │  │ • assets     │  │ • dependency │  │ • Auto-cascade chains │  │   │
│  │  │ • builds     │  │   gates      │  │                       │  │   │
│  │  │ • playtest   │  │ • critical   │  │                       │  │   │
│  │  │ • economy    │  │   path calc  │  │                       │  │   │
│  │  └──────────────┘  └──────────────┘  └───────────────────────┘  │   │
│  │                                                                  │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐  │   │
│  │  │ Docker Mgr   │  │ Model Router │  │ Asset Dependency      │  │   │
│  │  │              │  │              │  │ Graph Engine           │  │   │
│  │  │ • container  │  │ • task→model │  │                       │  │   │
│  │  │   selection  │  │   routing    │  │ • DAG resolution      │  │   │
│  │  │ • volume     │  │ • cost opt   │  │ • cycle detection     │  │   │
│  │  │   mounts     │  │ • capability │  │ • readiness checks    │  │   │
│  │  │ • health     │  │   matching   │  │ • cascade triggers    │  │   │
│  │  └──────────────┘  └──────────────┘  └───────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                              │                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    DATA & STATE LAYER                             │   │
│  │                                                                  │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐  │   │
│  │  │ SQLite DB    │  │ Asset Store  │  │ Knowledge Graph       │  │   │
│  │  │ (ACP State)  │  │ (Filesystem) │  │ (Convention Store)    │  │   │
│  │  │              │  │              │  │                       │  │   │
│  │  │ • 20+ tables │  │ • /assets/   │  │ • Agent capabilities  │  │   │
│  │  │ • FTS5 search│  │ • /builds/   │  │ • Pipeline patterns   │  │   │
│  │  │ • WAL mode   │  │ • /exports/  │  │ • Style conventions   │  │   │
│  │  │ • Triggers   │  │ • Git LFS    │  │ • Learned heuristics  │  │   │
│  │  └──────────────┘  └──────────────┘  └───────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                              │                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    RUNTIME LAYER                                  │   │
│  │                                                                  │   │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌──────────────┐  │   │
│  │  │Copilot │ │Claude  │ │Ollama  │ │Codex   │ │ Docker       │  │   │
│  │  │CLI     │ │Code    │ │(local) │ │CLI     │ │ Containers   │  │   │
│  │  │        │ │        │ │        │ │        │ │              │  │   │
│  │  │AI agent│ │AI agent│ │AI agent│ │AI agent│ │ gamedev-3d   │  │   │
│  │  │runtime │ │runtime │ │runtime │ │runtime │ │ gamedev-2d   │  │   │
│  │  │        │ │        │ │        │ │        │ │ gamedev-audio│  │   │
│  │  │        │ │        │ │        │ │        │ │ gamedev-engine│ │   │
│  │  └────────┘ └────────┘ └────────┘ └────────┘ └──────────────┘  │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Why This Matters

No tool in the market today can orchestrate the full game development lifecycle with AI agents. Game engines (Unity, Unreal, Godot) are RUNTIME engines. Asset tools (Blender, Aseprite, FMOD) are CREATION tools. CI/CD (GitHub Actions, Jenkins) are BUILD tools. **Nobody orchestrates the CREATION process itself** — the coordination of dozens of AI agents producing art, code, audio, levels, economy, and narrative in parallel, with quality gates, dependency tracking, and convergence loops.

CGS-Game fills this gap. It is the **Kubernetes of game development** — it doesn't make games, it orchestrates the agents that make games.

### Key Numbers

| Metric | Value |
|--------|-------|
| Agent types | 87+ across 11 categories |
| Pipelines | 9 parallel creation streams |
| Quality dimensions | 10 game-specific audit lenses |
| Trope addons | 18 optional game mechanic modules |
| Docker containers | 6 tiered environments |
| MCP tools | ~120 for full lifecycle management |
| Database tables | 20+ SQLite tables |
| Platform targets | Windows, macOS, Linux, Web, Android, iOS, consoles |
| Store targets | Steam, Epic, itch.io, GOG, App Store, Google Play, Nintendo, PlayStation, Xbox |

---

## 2. Why CGS-Game Must Be Standalone

### The Fork vs. Standalone Decision

CGS (ConverGeniSys) was designed for **enterprise software engineering** — .NET microservices, REST APIs, database schemas, deployment pipelines. Its data model assumes code repositories with services, its quality lenses audit code quality, its pipelines track implementation→audit→ship flows.

Game development is a fundamentally different domain. The data model, the pipelines, the quality dimensions, the agent types, the build system, the distribution channels, and the automation rules are ALL different. Trying to adapt CGS for games would be like trying to make Photoshop edit video — technically possible, but you'd end up with a worse product for both domains.

### The 12 Reasons for Standalone

| # | Dimension | CGS (Enterprise) | CGS-Game | Why Different |
|---|-----------|------------------|----------|---------------|
| 1 | **Primary artifact** | Source code (.cs, .ts, .py) | Assets + Code (sprites, models, textures, sounds, levels, scripts) | Enterprise ships code; games ship multimedia experiences |
| 2 | **Pipeline shape** | Linear belt: implement → audit → ship | 9 parallel streams: narrative, art, audio, world, mechanics, technical, economy, camera, distribution | Games have 6× more creation streams running concurrently |
| 3 | **Quality dimensions** | 24 code-focused lenses (security, code-style, performance) | 10 game-focused dimensions (gameplay feel, visual coherence, audio fit, economy health, fun factor) | "Does the combat feel good?" is not a code review question |
| 4 | **State model** | Services × audit scores | Assets × pipeline stages × platform builds × store submissions × playtest results | 5× more state dimensions to track |
| 5 | **Dependencies** | Code module dependencies | Asset dependency graph (character → skeleton → rig → mesh → texture → animation → scene) | Game asset deps are a deep DAG, not flat module deps |
| 6 | **Build output** | Docker images, NuGet packages | Platform-specific executables (Windows .exe, macOS .app, Android AAB, WebGL, console packages) | Cross-platform builds with platform-specific certification |
| 7 | **Distribution** | Container registries, cloud deployment | Game stores (Steam, Epic, itch.io, App Store, Google Play, console stores) — each with unique requirements | Each store has different metadata, screenshot, rating, and binary requirements |
| 8 | **Testing** | Unit tests, integration tests, E2E tests | AI playtest bots, balance simulation, performance profiling, accessibility auditing, fun-factor scoring | "Is the game fun?" is the test that matters most |
| 9 | **Toolchain** | IDEs, compilers, linters | Blender, Aseprite, SuperCollider, Godot, ImageMagick, ffmpeg — all CLI-driven inside Docker | Heavy creative tool containers, not compiler toolchains |
| 10 | **Optional modules** | Different lenses enabled per project | 18 trope addons (crafting, fishing, pets, housing, etc.) — each adds agents, tables, and pipeline steps | Enterprise doesn't have "optional fishing system" |
| 11 | **Live operations** | Blue-green deployment, feature flags | Season passes, battle passes, daily challenges, content drops, delta patches, save migration | Post-launch game ops are a different world from post-deploy software ops |
| 12 | **Economic model** | SaaS pricing, subscription billing | In-game economy (drop tables, crafting recipes, currency flows, XP curves) that must be balanced and simulated | Games have an INTERNAL economy that needs constant tuning |

### What CGS-Game Inherits (The DNA)

CGS-Game isn't built in ignorance of CGS — it's **inspired by** CGS's battle-tested architecture:

| Inherited Concept | CGS Origin | CGS-Game Adaptation |
|------------------|------------|---------------------|
| **ACP (Agent Context Protocol)** | SQLite-backed MCP server with 60+ tools | Expanded to ~120 tools with game-specific domains (assets, builds, playtests) |
| **Convergence Engine** | Audit → fix → re-audit → converge ≥96 | Same pattern applied to game quality dimensions |
| **4-Pass Blind Ticket Pipeline** | Pass1 + Pass2 → Reconcile → Audit | Identical — proven to catch 58% more requirements |
| **Operational Rules** | 39 rules learned from real failures | Inherited wholesale + 15 game-specific additions |
| **Stagger Dispatch** | 20-30s stagger between agent dispatches | Inherited — same rate limit management |
| **Completion Mantra** | "I have X, CAN have Y, MUST dispatch Z" | Inherited — same slot management discipline |
| **Agent Slot System** | Hard ceiling on concurrent agents | Inherited with per-pipeline slot allocation |
| **Crash Recovery** | Auto-reset orphaned agents on session resume | Inherited + Docker container recovery |
| **Branch Locking** | Advisory locks preventing dispatch collisions | Adapted as pipeline-stream locking |
| **Team Management** | Multi-orchestrator coordination | Adapted for multi-pipeline team assignment |

### What CGS-Game Adds (The Game DNA)

| New Concept | Why Enterprise CGS Doesn't Have It |
|------------|-----------------------------------|
| **Asset Dependency Graph** | Enterprise code has module deps; games have deep asset DAGs (character → skeleton → rig → mesh → texture → animation) |
| **Multi-Pipeline Orchestration** | Enterprise has one linear belt; games have 9 parallel creation streams with cross-stream dependencies |
| **Docker Container Selection** | Enterprise agents use same toolchain; game agents need different Docker images (gamedev-3d vs gamedev-audio) |
| **Playtest Simulation** | Enterprise has unit tests; games need AI bots that PLAY the game and report if it's fun |
| **Economy Simulation** | Enterprise doesn't have in-game economies to balance |
| **Cross-Platform Build Matrix** | Enterprise deploys to cloud; games deploy to 10+ platform/store combinations |
| **Store Submission Tracking** | Enterprise doesn't submit to Steam or the App Store |
| **Trope Addon System** | Enterprise doesn't have optional "fishing system" modules |
| **Asset Metadata Tracking** | Poly count, texture dimensions, palette info, LOD tiers — enterprise code doesn't have these |
| **Patch & DLC Management** | Delta patches, save migration, mod compatibility — game-specific post-launch concerns |

---

## 3. Architecture Blueprint

### System Architecture — Full Stack

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         CGS-GAME FULL ARCHITECTURE                           │
│                                                                              │
│ ┌─────────────────────────────────────────────────────────────────────────┐  │
│ │                         PRESENTATION LAYER                              │  │
│ │                                                                         │  │
│ │  ┌───────────────────┐  ┌───────────────────┐  ┌────────────────────┐  │  │
│ │  │ DESKTOP APP        │  │ WEB DASHBOARD      │  │ CLI                │  │  │
│ │  │ (Tauri 2 + React)  │  │ (localhost:3300)   │  │ (cgs-game)         │  │  │
│ │  │                    │  │                    │  │                    │  │  │
│ │  │ Pipeline Canvas    │  │ Pipeline Status    │  │ init               │  │  │
│ │  │ ├ 9 swimlanes      │  │ Asset Gallery      │  │ status             │  │  │
│ │  │ ├ drag-drop tropes │  │ Agent Pool         │  │ dispatch           │  │  │
│ │  │ ├ dep edges        │  │ Build Matrix       │  │ build              │  │  │
│ │  │                    │  │ Economy Dashboard  │  │ playtest           │  │  │
│ │  │ Asset Browser      │  │ Quality Scorecards │  │ audit              │  │  │
│ │  │ ├ thumbnails       │  │ Store Tracker      │  │ ship               │  │  │
│ │  │ ├ metadata panel   │  │                    │  │ trope enable/off   │  │  │
│ │  │ ├ dependency tree  │  │ WebSocket live     │  │ patch              │  │  │
│ │  │                    │  │ updates            │  │ asset list/inspect │  │  │
│ │  │ Economy Simulator  │  │                    │  │ docker status      │  │  │
│ │  │ ├ live graphs      │  │                    │  │                    │  │  │
│ │  │ ├ bot replays      │  │                    │  │                    │  │  │
│ │  │                    │  │                    │  │                    │  │  │
│ │  │ Build Matrix       │  │                    │  │                    │  │  │
│ │  │ ├ platform grid    │  │                    │  │                    │  │  │
│ │  │ ├ cert checklists  │  │                    │  │                    │  │  │
│ │  │                    │  │                    │  │                    │  │  │
│ │  │ Trope Manager      │  │                    │  │                    │  │  │
│ │  │ ├ toggle switches  │  │                    │  │                    │  │  │
│ │  │ ├ dep warnings     │  │                    │  │                    │  │  │
│ │  └───────────────────┘  └───────────────────┘  └────────────────────┘  │  │
│ └─────────────────────────────────────────────────────────────────────────┘  │
│                                    │                                         │
│                          IPC / WebSocket / HTTP                              │
│                                    │                                         │
│ ┌─────────────────────────────────────────────────────────────────────────┐  │
│ │                      ORCHESTRATION LAYER (Node.js)                      │  │
│ │                                                                         │  │
│ │  ┌─────────────────────────────────────────────────────────────────┐    │  │
│ │  │                    ACP SERVER (MCP Protocol)                     │    │  │
│ │  │                                                                 │    │  │
│ │  │  ~120 MCP Tools organized in 12 domains:                       │    │  │
│ │  │                                                                 │    │  │
│ │  │  PROJECT         AGENT           PIPELINE        ASSET          │    │  │
│ │  │  create          dispatch_next   advance         register       │    │  │
│ │  │  configure       complete        gate_check      query          │    │  │
│ │  │  set_active      get_running     status          validate       │    │  │
│ │  │  get_status      health_check    history         dep_check      │    │  │
│ │  │                  crash_recovery  critical_path   get_thumbnail  │    │  │
│ │  │                                                                 │    │  │
│ │  │  BUILD           QUALITY         TROPE           PLAYTEST       │    │  │
│ │  │  trigger         audit           enable          run_bot        │    │  │
│ │  │  platform_status score           disable         get_results    │    │  │
│ │  │  get_matrix      remediation_q   dep_check       get_metrics    │    │  │
│ │  │  cert_check      trend           list_active     balance_check  │    │  │
│ │  │                  convergence_st  get_config                     │    │  │
│ │  │                                                                 │    │  │
│ │  │  DOCKER          ECONOMY         STORE           ANALYTICS      │    │  │
│ │  │  container_for   sim_run         submit          throughput     │    │  │
│ │  │  health          get_curves      cert_status     pass_rate      │    │  │
│ │  │  volume_mount    validate        req_checklist   agent_perf     │    │  │
│ │  │  image_status    balance_report  metadata_gen    eta            │    │  │
│ │  └─────────────────────────────────────────────────────────────────┘    │  │
│ │                                                                         │  │
│ │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────────┐  │  │
│ │  │ Pipeline     │  │ Asset Dep    │  │ Convergence Engine           │  │  │
│ │  │ Engine       │  │ Graph Engine │  │                              │  │  │
│ │  │              │  │              │  │ audit → find issues → fix →  │  │  │
│ │  │ 9 parallel   │  │ DAG resolver │  │ re-audit → converge ≥96     │  │  │
│ │  │ pipelines    │  │ cycle detect │  │                              │  │  │
│ │  │ dep gates    │  │ readiness    │  │ 3-round stall detection      │  │  │
│ │  │ cross-stream │  │ checks       │  │ auto-escalation              │  │  │
│ │  │ deps         │  │ cascade      │  │ score ±2 plateau → STALLED  │  │  │
│ │  │              │  │ triggers     │  │                              │  │  │
│ │  └──────────────┘  └──────────────┘  └──────────────────────────────┘  │  │
│ │                                                                         │  │
│ │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────────┐  │  │
│ │  │ Docker Mgr   │  │ Model Router │  │ Prompt Template Engine       │  │  │
│ │  │              │  │              │  │                              │  │  │
│ │  │ agent→image  │  │ task→model   │  │ 87+ agent prompt templates  │  │  │
│ │  │ mapping      │  │ cost/speed/  │  │ with context injection:     │  │  │
│ │  │ container    │  │ capability   │  │ - GDD excerpts              │  │  │
│ │  │ lifecycle    │  │ matching     │  │ - style guide refs          │  │  │
│ │  │ volume mgmt  │  │ local vs API │  │ - asset manifests           │  │  │
│ │  │ shared cache │  │              │  │ - pipeline state            │  │  │
│ │  └──────────────┘  └──────────────┘  └──────────────────────────────┘  │  │
│ └─────────────────────────────────────────────────────────────────────────┘  │
│                                    │                                         │
│ ┌─────────────────────────────────────────────────────────────────────────┐  │
│ │                         DATA LAYER                                      │  │
│ │                                                                         │  │
│ │  ┌────────────────────────────────────────────────────────────────────┐ │  │
│ │  │                    SQLite Database (acp-game-state.db)              │ │  │
│ │  │                                                                    │ │  │
│ │  │  game_projects     agents            pipeline_defs                 │ │  │
│ │  │  pipeline_state    pipeline_steps    pipeline_deps                 │ │  │
│ │  │  assets            asset_deps        asset_metadata                │ │  │
│ │  │  dispatches        active_agents     audit_scores                  │ │  │
│ │  │  audit_findings    builds            build_platforms               │ │  │
│ │  │  store_submissions store_requirements trope_config                 │ │  │
│ │  │  trope_deps        playtest_runs     playtest_metrics              │ │  │
│ │  │  economy_snapshots patches           patch_assets                  │ │  │
│ │  │  prompt_templates  session_state     docker_containers             │ │  │
│ │  │  agent_registry    conventions       activity_log                  │ │  │
│ │  └────────────────────────────────────────────────────────────────────┘ │  │
│ │                                                                         │  │
│ │  ┌──────────────────────────┐  ┌─────────────────────────────────────┐ │  │
│ │  │ Asset Filesystem          │  │ Git Repository                      │ │  │
│ │  │                           │  │                                     │ │  │
│ │  │ /project-root/            │  │ Git LFS for large assets            │ │  │
│ │  │   /assets/                │  │ Text files tracked normally         │ │  │
│ │  │     /sprites/             │  │ .gitignore for temp/build artifacts │ │  │
│ │  │     /models/              │  │                                     │ │  │
│ │  │     /textures/            │  │ Branch per feature/task             │ │  │
│ │  │     /audio/               │  │ Auto-commit on agent completion     │ │  │
│ │  │     /scenes/              │  │                                     │ │  │
│ │  │     /tilemaps/            │  │                                     │ │  │
│ │  │   /builds/                │  │                                     │ │  │
│ │  │   /exports/               │  │                                     │ │  │
│ │  │   /docs/                  │  │                                     │ │  │
│ │  └──────────────────────────┘  └─────────────────────────────────────┘ │  │
│ └─────────────────────────────────────────────────────────────────────────┘  │
│                                    │                                         │
│ ┌─────────────────────────────────────────────────────────────────────────┐  │
│ │                      RUNTIME LAYER                                      │  │
│ │                                                                         │  │
│ │  AI RUNTIMES (provider-agnostic)         TOOL CONTAINERS (Docker)       │  │
│ │  ┌────────┐ ┌────────┐ ┌────────┐       ┌─────────────────────────┐    │  │
│ │  │Copilot │ │Claude  │ │Ollama  │       │ gamedev-base            │    │  │
│ │  │CLI     │ │Code    │ │(local) │       │ gamedev-2d (Aseprite)   │    │  │
│ │  └────────┘ └────────┘ └────────┘       │ gamedev-3d (Blender)    │    │  │
│ │  ┌────────┐ ┌────────┐ ┌────────┐       │ gamedev-audio (SC,LMMS) │    │  │
│ │  │Codex   │ │Aider   │ │Custom  │       │ gamedev-engine (Godot)  │    │  │
│ │  │CLI     │ │        │ │stdio   │       │ gamedev-full (all)      │    │  │
│ │  └────────┘ └────────┘ └────────┘       └─────────────────────────┘    │  │
│ └─────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **Desktop Shell** | Tauri 2.x (Rust) | Native perf, small binary (~15MB), cross-platform |
| **Frontend** | React 18 + TypeScript + Vite | Industry standard, component reuse |
| **UI Components** | Custom design system + Tailwind CSS | Dark-mode-first, game-dev aesthetic |
| **Visualization** | D3.js v7 + Three.js (asset preview) | Pipeline graphs, asset 3D preview |
| **Backend Core** | Node.js (ES modules) | MCP server implementation, async I/O |
| **Database** | SQLite (better-sqlite3) | Zero-config, WAL mode, FTS5, embedded |
| **Asset Preview** | Sharp (images), Three.js (3D), Howler.js (audio) | In-browser asset inspection |
| **Process Mgmt** | node-pty (PTY) / Docker SDK | Terminal-based AI runtimes + containerized tools |
| **Real-time** | WebSocket (ws) | Push updates to all connected dashboards |
| **Container Mgmt** | Dockerode (Docker SDK for Node.js) | Programmatic container lifecycle |

### Data Flow — From Pitch to Shipped Game

```
PITCH (one sentence)
    │
    ▼
┌──────────────────────────────────────────────────────────────────────┐
│ PHASE 1: VISION                                                      │
│                                                                      │
│ Game Vision Architect → GDD (80-100KB)                              │
│   ├→ Narrative Designer → Lore Bible, Character Bible, Quest Arc    │
│   ├→ Character Designer → Character Sheets (JSON)                   │
│   ├→ World Cartographer → World Map, Biome Definitions (JSON)       │
│   ├→ Game Economist → Economy Model (JSON)                          │
│   ├→ Game Art Director → Style Guide                                │
│   ├→ Game Audio Director → Music Direction                          │
│   └→ Game Architecture Planner → Technical Architecture Doc          │
└──────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────────────────┐
│ PHASE 2: DECOMPOSITION                                               │
│                                                                      │
│ The Decomposer → 6 stream decompositions (≤8pts per task)           │
│ The Aggregator → Master Task Matrix (cross-stream deps resolved)    │
└──────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────────────────┐
│ PHASE 3: TICKETING (4-Pass Blind Pipeline)                           │
│                                                                      │
│ Per task: Pass1 + Pass2 (parallel blind) → Reconcile → Audit        │
│ Game Ticket Writer produces game-specific 16-section tickets        │
└──────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────────────────┐
│ PHASE 4: CREATION (9 PARALLEL PIPELINES)                             │
│                                                                      │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│ │NARRATIVE │ │  ART     │ │ AUDIO    │ │ WORLD    │ │MECHANICS │  │
│ │          │ │          │ │          │ │          │ │          │  │
│ │ Dialogue │ │ Sculptors│ │ Composer │ │ Terrain  │ │ Combat   │  │
│ │ Quests   │ │ Media    │ │ SFX      │ │ Biomes   │ │ AI       │  │
│ │ Lore     │ │ Assembly │ │ Ambient  │ │ Dungeons │ │ Economy  │  │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐              │
│ │TECHNICAL │ │ CAMERA   │ │ ECONOMY  │ │ TROPES   │              │
│ │          │ │          │ │          │ │(optional)│              │
│ │ Engine   │ │ Systems  │ │ Balance  │ │ Pets     │              │
│ │ Network  │ │ Cutscenes│ │ Playtest │ │ Crafting │              │
│ │ Optimize │ │ Trailers │ │ Simulate │ │ Housing  │              │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘              │
└──────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────────────────┐
│ PHASE 5: CONVERGENCE                                                 │
│                                                                      │
│ Audit → Find Issues → Fix → Re-Audit → Converge (≥96 per dim)      │
│ 10 quality dimensions scored independently                           │
│ Stall detection: 3 rounds within ±2pts → STALLED (manual review)    │
└──────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────────────────┐
│ PHASE 6: BUILD & DISTRIBUTE                                          │
│                                                                      │
│ Cross-platform builds → Store submissions → Launch → Live Ops       │
│ Delta patches → Save migration → Content drops → Season passes      │
└──────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| **ACP Server** | All state management, tool exposure via MCP protocol | Node.js, better-sqlite3, MCP SDK |
| **Pipeline Engine** | Manage 9 parallel pipelines with dependency gates | State machine per pipeline, DAG for cross-pipeline deps |
| **Asset Dep Graph** | Track asset creation DAG, readiness checks, cascade triggers | SQLite recursive CTEs, topological sort |
| **Docker Manager** | Select container for agent, manage volumes, health monitoring | Dockerode SDK, health checks |
| **Model Router** | Route agent tasks to optimal AI model based on complexity/cost | Rule engine with capability matching |
| **Convergence Engine** | Audit loops, stall detection, quality gate enforcement | Score tracking, round counting, auto-dispatch |
| **Prompt Engine** | Generate agent prompts with game-specific context injection | Template system with SQLite-backed overrides |
| **Dashboard** | Real-time visualization of all system state | React + D3.js + WebSocket |
| **CLI** | Developer-facing command interface | Commander.js, chalk, ora |

---

## 4. Database Schema

### Design Philosophy

The database is the **single source of truth** for all CGS-Game state. Every agent, every asset, every pipeline step, every build, every playtest result lives in SQLite. The schema is designed for:

1. **Query-first**: Every dashboard panel maps to a single SQL query
2. **Dependency-aware**: Asset deps, pipeline deps, and trope deps are first-class entities with cycle detection
3. **Audit-complete**: Every state change is logged with agent ID, timestamp, and previous value
4. **FTS5-enabled**: Full-text search on asset names, descriptions, agent outputs, and findings

### Entity-Relationship Diagram

```
game_projects ──1:N──→ pipeline_state ──N:1──→ pipeline_defs
     │                      │
     │                 ┌────┘
     │                 ▼
     ├──1:N──→ assets ──1:N──→ asset_deps ──N:1──→ assets (self-ref)
     │            │
     │            └──1:1──→ asset_metadata
     │
     ├──1:N──→ dispatches ──N:1──→ agent_registry
     │            │
     │            └──1:1──→ active_agents
     │
     ├──1:N──→ audit_scores ──1:N──→ audit_findings
     │
     ├──1:N──→ builds ──1:N──→ build_platforms
     │
     ├──1:N──→ store_submissions ──N:1──→ store_requirements
     │
     ├──1:N──→ trope_config ──1:N──→ trope_deps
     │
     ├──1:N──→ playtest_runs ──1:N──→ playtest_metrics
     │
     ├──1:N──→ economy_snapshots
     │
     └──1:N──→ patches ──1:N──→ patch_assets
```

### Table Definitions

#### Core Tables

```sql
-- ============================================================================
-- TABLE: game_projects
-- The top-level entity. Multiple games can be managed simultaneously.
-- ============================================================================
CREATE TABLE game_projects (
    id                TEXT PRIMARY KEY,          -- 'pet-trainer-rpg'
    name              TEXT NOT NULL,             -- 'Chibi Pet Trainer RPG'
    pitch             TEXT,                      -- Original one-sentence pitch
    gdd_path          TEXT,                      -- Path to Game Design Document
    style_guide_path  TEXT,                      -- Path to Art Director's style guide
    engine            TEXT DEFAULT 'godot-4',    -- 'godot-4', 'unity', 'unreal', 'custom'
    target_platforms  TEXT DEFAULT '[]',         -- JSON array: ['windows','macos','linux','web','android','ios']
    target_stores     TEXT DEFAULT '[]',         -- JSON array: ['steam','itch','epic','gog','appstore','googleplay']
    status            TEXT DEFAULT 'active',     -- 'active', 'paused', 'shipped', 'archived'
    created_at        TEXT DEFAULT (datetime('now')),
    updated_at        TEXT DEFAULT (datetime('now')),
    
    -- Game-specific metadata
    genre             TEXT,                      -- 'action-rpg', 'platformer', 'survival', etc.
    art_style         TEXT,                      -- 'chibi', 'pixel-art', 'realistic', 'cel-shaded'
    perspective       TEXT,                      -- 'isometric', 'topdown', 'side-scroll', 'third-person', 'first-person'
    multiplayer       INTEGER DEFAULT 0,         -- 0=single, 1=co-op, 2=pvp, 3=mmo
    monetization      TEXT,                      -- 'premium', 'f2p', 'freemium', 'subscription'
    
    -- Configuration
    convergence_threshold INTEGER DEFAULT 96,    -- Quality score needed to pass
    max_agents        INTEGER DEFAULT 5,         -- Max concurrent agents
    stagger_delay_ms  INTEGER DEFAULT 25000,     -- Delay between dispatches
    docker_enabled    INTEGER DEFAULT 1          -- 0=local tools, 1=Docker containers
);

-- ============================================================================
-- TABLE: agent_registry
-- All 87+ available agents with their capabilities, container requirements,
-- and input/output contracts.
-- ============================================================================
CREATE TABLE agent_registry (
    id                TEXT PRIMARY KEY,          -- 'humanoid-character-sculptor'
    name              TEXT NOT NULL,             -- 'Humanoid Character Sculptor'
    category          TEXT NOT NULL,             -- 'vision', 'form-sculptor', 'media-pipeline', etc.
    description       TEXT,                      -- What this agent does
    
    -- Container requirements
    docker_image      TEXT,                      -- 'gamedev-3d', 'gamedev-2d', 'gamedev-audio', etc.
    required_tools    TEXT DEFAULT '[]',         -- JSON: ['blender','imagemagick']
    
    -- I/O contract
    consumes          TEXT DEFAULT '[]',         -- JSON: ['style-guide.md','character-bible.md']
    produces          TEXT DEFAULT '[]',         -- JSON: ['character-model.glb','character-sprite.png']
    
    -- Dispatch metadata
    default_model     TEXT DEFAULT 'sonnet',     -- AI model tier: 'haiku', 'sonnet', 'opus'
    estimated_minutes INTEGER DEFAULT 15,        -- Expected completion time
    pipeline_ids      TEXT DEFAULT '[]',         -- JSON: pipelines this agent belongs to
    is_trope_agent    INTEGER DEFAULT 0,         -- 1 if this agent requires trope activation
    trope_id          TEXT,                      -- Which trope activates this agent (if trope agent)
    
    -- Prompt
    prompt_template   TEXT,                      -- Agent prompt template with {placeholders}
    agent_md_path     TEXT,                      -- Path to .agent.md file
    
    status            TEXT DEFAULT 'active',     -- 'active', 'deprecated', 'experimental'
    created_at        TEXT DEFAULT (datetime('now'))
);
```

#### Pipeline Tables

```sql
-- ============================================================================
-- TABLE: pipeline_defs
-- The 9 pipeline definitions with their step ordering.
-- ============================================================================
CREATE TABLE pipeline_defs (
    id                TEXT PRIMARY KEY,          -- 'pipeline-3-art'
    name              TEXT NOT NULL,             -- 'Art Pipeline'
    description       TEXT,
    layout            TEXT DEFAULT 'sequential', -- 'sequential', 'parallel', 'mixed'
    project_id        TEXT NOT NULL,
    
    FOREIGN KEY (project_id) REFERENCES game_projects(id)
);

-- ============================================================================
-- TABLE: pipeline_steps
-- Ordered steps within each pipeline. Defines which agent runs at each step
-- and what it produces/consumes.
-- ============================================================================
CREATE TABLE pipeline_steps (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    pipeline_id       TEXT NOT NULL,
    step_order        REAL NOT NULL,             -- 1, 2, 2.5 (allows parallel within pipeline)
    agent_id          TEXT NOT NULL,
    produces          TEXT DEFAULT '[]',         -- JSON array of artifact names
    consumes          TEXT DEFAULT '[]',         -- JSON array of artifact names
    note              TEXT,                      -- Human-readable annotation
    
    FOREIGN KEY (pipeline_id) REFERENCES pipeline_defs(id),
    FOREIGN KEY (agent_id) REFERENCES agent_registry(id)
);

-- ============================================================================
-- TABLE: pipeline_state
-- Per-pipeline, per-step progress tracking. One row per pipeline step per task.
-- ============================================================================
CREATE TABLE pipeline_state (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id        TEXT NOT NULL,
    pipeline_id       TEXT NOT NULL,
    step_id           INTEGER NOT NULL,          -- References pipeline_steps.id
    task_id           TEXT,                      -- Task being processed (nullable for non-task steps)
    
    status            TEXT DEFAULT 'pending',    -- 'pending','running','completed','failed','stalled','blocked'
    agent_id          TEXT,                      -- Dispatched agent instance ID
    
    started_at        TEXT,
    completed_at      TEXT,
    score             INTEGER,                   -- Quality score (0-100)
    verdict           TEXT,                      -- 'PASS','CONDITIONAL','FAIL'
    output_path       TEXT,                      -- Path to output artifact
    error_message     TEXT,                      -- Error details if failed
    attempt_count     INTEGER DEFAULT 0,         -- How many times this step has been attempted
    
    FOREIGN KEY (project_id) REFERENCES game_projects(id),
    FOREIGN KEY (pipeline_id) REFERENCES pipeline_defs(id),
    FOREIGN KEY (step_id) REFERENCES pipeline_steps(id)
);

-- ============================================================================
-- TABLE: pipeline_deps
-- Cross-pipeline dependencies. "Art Pipeline step 3 requires Narrative Pipeline step 2"
-- ============================================================================
CREATE TABLE pipeline_deps (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    source_pipeline   TEXT NOT NULL,             -- Pipeline that must complete first
    source_step       INTEGER NOT NULL,          -- Step in source pipeline
    target_pipeline   TEXT NOT NULL,             -- Pipeline that depends on source
    target_step       INTEGER NOT NULL,          -- Step in target pipeline
    dep_type          TEXT DEFAULT 'blocks',     -- 'blocks', 'informs', 'optional'
    description       TEXT,                      -- Human-readable: "Character models needed for animation"
    
    FOREIGN KEY (source_pipeline) REFERENCES pipeline_defs(id),
    FOREIGN KEY (target_pipeline) REFERENCES pipeline_defs(id)
);
```

#### Asset Tables

```sql
-- ============================================================================
-- TABLE: assets
-- Every generated asset tracked with full metadata. This is the asset registry.
-- ============================================================================
CREATE TABLE assets (
    id                TEXT PRIMARY KEY,          -- 'sprite-hero-idle-001'
    project_id        TEXT NOT NULL,
    name              TEXT NOT NULL,             -- 'Hero Idle Animation'
    
    -- Classification
    asset_type        TEXT NOT NULL,             -- 'sprite', 'model', 'texture', 'sound', 'music',
                                                -- 'tilemap', 'scene', 'script', 'shader', 'vfx',
                                                -- 'ui-element', 'font', 'animation', 'dialogue-tree'
    category          TEXT,                      -- 'character', 'environment', 'ui', 'weapon', 'creature',
                                                -- 'building', 'terrain', 'vfx', 'audio'
    
    -- File info
    file_path         TEXT NOT NULL,             -- Relative path from project root
    file_size_bytes   INTEGER,
    file_hash         TEXT,                      -- SHA-256 for change detection
    format            TEXT,                      -- 'png', 'glb', 'gltf', 'wav', 'ogg', 'tscn', 'gd', 'json'
    
    -- Status
    status            TEXT DEFAULT 'draft',      -- 'draft','in-progress','review','approved','integrated','deprecated'
    quality_score     INTEGER,                   -- Latest quality audit score (0-100)
    
    -- Provenance
    created_by_agent  TEXT,                      -- Agent ID that created this asset
    created_by_step   INTEGER,                   -- Pipeline step that produced this
    pipeline_id       TEXT,                      -- Which pipeline produced this asset
    task_id           TEXT,                      -- Which task this asset fulfills
    
    -- Timestamps
    created_at        TEXT DEFAULT (datetime('now')),
    updated_at        TEXT DEFAULT (datetime('now')),
    approved_at       TEXT,
    
    -- Search
    tags              TEXT DEFAULT '[]',         -- JSON: ['hero','idle','animation','chibi']
    description       TEXT,                      -- Full-text searchable description
    
    FOREIGN KEY (project_id) REFERENCES game_projects(id)
);

-- FTS5 index for asset search
CREATE VIRTUAL TABLE assets_fts USING fts5(
    name, description, tags, asset_type, category,
    content='assets', content_rowid='rowid'
);

-- ============================================================================
-- TABLE: asset_metadata
-- Type-specific metadata. Different fields for sprites vs models vs audio.
-- Stored as JSON to accommodate varying shapes.
-- ============================================================================
CREATE TABLE asset_metadata (
    asset_id          TEXT PRIMARY KEY,
    
    -- Visual assets (sprites, textures)
    width_px          INTEGER,
    height_px         INTEGER,
    color_depth       INTEGER,                   -- bits per channel
    has_alpha         INTEGER,                   -- 0/1
    palette_colors    INTEGER,                   -- Number of unique colors
    animation_frames  INTEGER,                   -- For animated sprites
    frame_rate        REAL,                      -- FPS for animations
    
    -- 3D assets (models)
    poly_count        INTEGER,                   -- Triangle count
    vertex_count      INTEGER,
    bone_count        INTEGER,                   -- Skeleton bone count
    blend_shape_count INTEGER,
    lod_tiers         INTEGER,                   -- Number of LOD levels
    uv_channels       INTEGER,
    bounding_box      TEXT,                      -- JSON: {x,y,z}
    
    -- Audio assets
    duration_seconds  REAL,
    sample_rate       INTEGER,                   -- 44100, 48000, etc.
    channels          INTEGER,                   -- 1=mono, 2=stereo
    bit_depth         INTEGER,                   -- 16, 24, 32
    loudness_lufs     REAL,                      -- Loudness Units
    
    -- Texture-specific
    is_tileable       INTEGER,                   -- 0/1
    is_pbr            INTEGER,                   -- 0/1 (has albedo/normal/roughness/metal)
    texture_type      TEXT,                      -- 'albedo', 'normal', 'roughness', 'metallic', 'emission'
    
    -- All types
    extra_metadata    TEXT,                      -- JSON blob for anything else
    
    FOREIGN KEY (asset_id) REFERENCES assets(id)
);

-- ============================================================================
-- TABLE: asset_deps
-- Dependency graph between assets. A character animation depends on the
-- character model which depends on the character design spec.
-- ============================================================================
CREATE TABLE asset_deps (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    parent_asset_id   TEXT NOT NULL,             -- The asset being depended upon
    child_asset_id    TEXT NOT NULL,             -- The asset that depends on parent
    dep_type          TEXT DEFAULT 'requires',   -- 'requires', 'extends', 'variant-of', 'supersedes'
    description       TEXT,                      -- "Animation requires base model skeleton"
    
    FOREIGN KEY (parent_asset_id) REFERENCES assets(id),
    FOREIGN KEY (child_asset_id) REFERENCES assets(id),
    UNIQUE(parent_asset_id, child_asset_id, dep_type)
);

-- Prevent cycles with a trigger (application-level cycle detection also required)
-- CREATE TRIGGER prevent_self_dep BEFORE INSERT ON asset_deps
-- WHEN NEW.parent_asset_id = NEW.child_asset_id
-- BEGIN SELECT RAISE(ABORT, 'Asset cannot depend on itself'); END;
```

#### Agent & Dispatch Tables

```sql
-- ============================================================================
-- TABLE: active_agents
-- Currently running agents. Mirrors CGS's active_agents but with game-specific fields.
-- ============================================================================
CREATE TABLE active_agents (
    agent_id          TEXT PRIMARY KEY,          -- 'sculptor-humanoid-001'
    agent_type        TEXT NOT NULL,             -- 'Humanoid Character Sculptor'
    project_id        TEXT NOT NULL,
    
    -- What they're doing
    target            TEXT,                      -- Task or asset being worked on
    pipeline_id       TEXT,                      -- Which pipeline
    step_id           INTEGER,                   -- Which pipeline step
    docker_container  TEXT,                      -- Running container ID
    
    -- Status
    status            TEXT DEFAULT 'running',    -- 'running', 'completed', 'crashed', 'stalled'
    dispatched_at     TEXT DEFAULT (datetime('now')),
    completed_at      TEXT,
    
    -- Results
    score             INTEGER,
    verdict           TEXT,
    output_paths      TEXT DEFAULT '[]',         -- JSON: paths to produced artifacts
    summary           TEXT,
    error_message     TEXT,
    
    FOREIGN KEY (project_id) REFERENCES game_projects(id)
);

-- ============================================================================
-- TABLE: dispatches
-- Full dispatch history. Every agent dispatch ever made.
-- ============================================================================
CREATE TABLE dispatches (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id          TEXT NOT NULL,             -- Instance ID
    agent_type        TEXT NOT NULL,
    project_id        TEXT NOT NULL,
    pipeline_id       TEXT,
    step_id           INTEGER,
    target            TEXT,
    
    docker_image      TEXT,                      -- Container used
    ai_model          TEXT,                      -- AI model used
    ai_runtime        TEXT,                      -- Runtime used (copilot, claude, ollama)
    
    status            TEXT DEFAULT 'dispatched', -- 'dispatched','running','completed','crashed','failed'
    dispatched_at     TEXT DEFAULT (datetime('now')),
    started_at        TEXT,
    completed_at      TEXT,
    duration_seconds  INTEGER,
    
    score             INTEGER,
    verdict           TEXT,
    output_paths      TEXT DEFAULT '[]',
    error_message     TEXT,
    
    -- Cost tracking
    tokens_input      INTEGER,
    tokens_output     INTEGER,
    cost_usd          REAL,
    
    FOREIGN KEY (project_id) REFERENCES game_projects(id)
);
```

#### Quality & Audit Tables

```sql
-- ============================================================================
-- TABLE: audit_scores
-- Quality audit scores per system/module. 10 game-specific quality dimensions.
-- ============================================================================
CREATE TABLE audit_scores (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id        TEXT NOT NULL,
    
    -- What was audited
    target            TEXT NOT NULL,             -- System/module: 'combat', 'economy', 'ui-hud', etc.
    dimension         TEXT NOT NULL,             -- 'gameplay-feel', 'visual-coherence', 'audio-fit',
                                                -- 'narrative-flow', 'economy-health', 'performance',
                                                -- 'accessibility', 'fun-factor', 'technical-quality',
                                                -- 'monetization-ethics'
    
    -- Results
    score             INTEGER NOT NULL,          -- 0-100
    verdict           TEXT NOT NULL,             -- 'PASS' (≥96), 'CONDITIONAL' (70-91), 'FAIL' (<70)
    
    -- Audit metadata
    auditor_agent     TEXT NOT NULL,             -- Agent that performed the audit
    audit_round       INTEGER DEFAULT 1,         -- Which round of convergence
    report_path       TEXT,                      -- Path to full audit report
    
    -- Convergence tracking
    previous_score    INTEGER,                   -- Score from previous round (for delta calc)
    is_converged      INTEGER DEFAULT 0,         -- 1 if this dimension has converged (≥threshold)
    is_stalled        INTEGER DEFAULT 0,         -- 1 if 3 rounds within ±2pts (Rule 4.2)
    
    created_at        TEXT DEFAULT (datetime('now')),
    
    FOREIGN KEY (project_id) REFERENCES game_projects(id)
);

-- ============================================================================
-- TABLE: audit_findings
-- Individual findings from quality audits. Issues discovered during auditing.
-- ============================================================================
CREATE TABLE audit_findings (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    audit_score_id    INTEGER NOT NULL,
    project_id        TEXT NOT NULL,
    
    severity          TEXT NOT NULL,             -- 'critical', 'high', 'medium', 'low'
    category          TEXT NOT NULL,             -- 'gameplay', 'visual', 'audio', 'narrative', 'economy',
                                                -- 'performance', 'accessibility', 'fun', 'technical',
                                                -- 'monetization', 'balance', 'ux'
    title             TEXT NOT NULL,
    description       TEXT,
    
    -- Location
    file_path         TEXT,                      -- File where issue was found
    line_number       INTEGER,
    asset_id          TEXT,                      -- Related asset (if applicable)
    
    -- Resolution
    status            TEXT DEFAULT 'open',       -- 'open', 'assigned', 'fixed', 'deferred', 'wont-fix'
    fix_agent         TEXT,                      -- Agent assigned to fix
    fix_description   TEXT,                      -- What was done to fix it
    fixed_at          TEXT,
    
    created_at        TEXT DEFAULT (datetime('now')),
    
    FOREIGN KEY (audit_score_id) REFERENCES audit_scores(id),
    FOREIGN KEY (project_id) REFERENCES game_projects(id),
    FOREIGN KEY (asset_id) REFERENCES assets(id)
);
```

#### Build & Distribution Tables

```sql
-- ============================================================================
-- TABLE: builds
-- Build history. Each row is one build attempt.
-- ============================================================================
CREATE TABLE builds (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id        TEXT NOT NULL,
    
    version           TEXT NOT NULL,             -- Semver: '0.1.0', '1.0.0-beta.3'
    build_number      INTEGER,                   -- Monotonic build counter
    build_type        TEXT DEFAULT 'development', -- 'development', 'staging', 'release', 'hotfix'
    
    -- Git reference
    git_commit        TEXT,                      -- Commit SHA
    git_branch        TEXT,                      -- Branch name
    git_tag           TEXT,                      -- Tag (for releases)
    
    -- Status
    status            TEXT DEFAULT 'pending',    -- 'pending','building','succeeded','failed','cancelled'
    started_at        TEXT,
    completed_at      TEXT,
    duration_seconds  INTEGER,
    
    -- Artifacts
    changelog         TEXT,                      -- Markdown changelog for this version
    release_notes     TEXT,                      -- Player-facing release notes
    total_size_bytes  INTEGER,                   -- Total build size across all platforms
    
    -- Smoke test results
    smoke_test_passed INTEGER DEFAULT 0,
    smoke_test_report TEXT,                      -- Path to smoke test report
    
    triggered_by      TEXT,                      -- 'manual', 'auto-commit', 'schedule', 'agent'
    created_at        TEXT DEFAULT (datetime('now')),
    
    FOREIGN KEY (project_id) REFERENCES game_projects(id)
);

-- ============================================================================
-- TABLE: build_platforms
-- Per-platform build status within a build. One row per (build × platform).
-- ============================================================================
CREATE TABLE build_platforms (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    build_id          INTEGER NOT NULL,
    
    platform          TEXT NOT NULL,             -- 'windows', 'macos', 'linux', 'web', 'android', 'ios',
                                                -- 'nintendo-switch', 'playstation', 'xbox'
    architecture      TEXT,                      -- 'x86_64', 'arm64', 'wasm'
    
    status            TEXT DEFAULT 'pending',    -- 'pending','building','succeeded','failed','skipped'
    started_at        TEXT,
    completed_at      TEXT,
    
    -- Artifact
    output_path       TEXT,                      -- Path to built artifact
    file_size_bytes   INTEGER,
    checksum          TEXT,                      -- SHA-256
    
    -- Platform-specific
    min_os_version    TEXT,                      -- 'Windows 10', 'macOS 12', 'Android 11'
    cert_status       TEXT DEFAULT 'not-started',-- 'not-started','in-progress','passed','failed'
    cert_notes        TEXT,
    
    error_message     TEXT,
    
    FOREIGN KEY (build_id) REFERENCES builds(id)
);

-- ============================================================================
-- TABLE: store_submissions
-- Per-store submission tracking.
-- ============================================================================
CREATE TABLE store_submissions (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id        TEXT NOT NULL,
    build_id          INTEGER NOT NULL,
    
    store             TEXT NOT NULL,             -- 'steam', 'epic', 'itch', 'gog', 'appstore',
                                                -- 'googleplay', 'nintendo', 'playstation', 'xbox'
    
    -- Status
    status            TEXT DEFAULT 'not-started',-- 'not-started','preparing','submitted','in-review',
                                                -- 'approved','rejected','published','delisted'
    submitted_at      TEXT,
    reviewed_at       TEXT,
    published_at      TEXT,
    
    -- Store-specific metadata
    store_app_id      TEXT,                      -- Store's internal ID for this game
    store_url         TEXT,                      -- Public URL on the store
    price_usd         REAL,                      -- Price in USD
    pricing_tiers     TEXT,                      -- JSON: regional pricing overrides
    
    -- Age rating
    age_rating_system TEXT,                      -- 'ESRB', 'PEGI', 'CERO', 'USK', 'GRAC'
    age_rating        TEXT,                      -- 'E', 'T', 'M', 'PEGI 7', 'PEGI 12', etc.
    content_descriptors TEXT DEFAULT '[]',       -- JSON: ['Fantasy Violence','Mild Language']
    
    -- Store page assets
    capsule_images    TEXT DEFAULT '{}',         -- JSON: {header: 'path', small: 'path', ...}
    screenshots       TEXT DEFAULT '[]',         -- JSON: ['path1','path2',...]
    trailer_url       TEXT,
    description_short TEXT,
    description_long  TEXT,
    
    -- Rejection/feedback
    rejection_reason  TEXT,
    reviewer_notes    TEXT,
    
    -- Requirements checklist progress
    checklist_total   INTEGER DEFAULT 0,
    checklist_done    INTEGER DEFAULT 0,
    
    FOREIGN KEY (project_id) REFERENCES game_projects(id),
    FOREIGN KEY (build_id) REFERENCES builds(id)
);

-- ============================================================================
-- TABLE: store_requirements
-- Per-store requirements checklist. What each store requires for submission.
-- ============================================================================
CREATE TABLE store_requirements (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    store             TEXT NOT NULL,
    category          TEXT NOT NULL,             -- 'metadata', 'assets', 'technical', 'legal', 'content'
    requirement       TEXT NOT NULL,             -- Description of the requirement
    is_mandatory      INTEGER DEFAULT 1,
    validation_type   TEXT DEFAULT 'manual',     -- 'manual', 'automated', 'api-check'
    validation_query  TEXT,                      -- Automated check (if applicable)
    
    -- Store-specific details
    spec_url          TEXT,                      -- Link to store's documentation
    example           TEXT,                      -- Example of correct value/format
    notes             TEXT
);
```

#### Trope & Economy Tables

```sql
-- ============================================================================
-- TABLE: trope_config
-- Which of the 18 trope addon modules are active for this game project.
-- ============================================================================
CREATE TABLE trope_config (
    id                TEXT PRIMARY KEY,          -- 'crafting', 'fishing', 'pets', etc.
    project_id        TEXT NOT NULL,
    name              TEXT NOT NULL,             -- 'Crafting System'
    
    enabled           INTEGER DEFAULT 0,         -- 0=disabled, 1=enabled
    enabled_at        TEXT,
    enabled_by        TEXT,                      -- 'user', 'auto-from-gdd'
    
    -- Agent mapping
    agent_id          TEXT NOT NULL,             -- 'crafting-system-builder'
    agent_count       INTEGER DEFAULT 1,         -- How many agents this trope adds
    
    -- Pipeline integration
    pipeline_steps    TEXT DEFAULT '[]',         -- JSON: additional pipeline steps this trope adds
    
    -- Configuration
    config            TEXT DEFAULT '{}',         -- JSON: trope-specific config
    
    FOREIGN KEY (project_id) REFERENCES game_projects(id),
    FOREIGN KEY (agent_id) REFERENCES agent_registry(id)
);

-- ============================================================================
-- TABLE: trope_deps
-- Dependencies between tropes. "Cooking requires Crafting base system"
-- ============================================================================
CREATE TABLE trope_deps (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    trope_id          TEXT NOT NULL,
    requires_trope_id TEXT NOT NULL,
    dep_type          TEXT DEFAULT 'requires',   -- 'requires', 'enhances', 'conflicts'
    description       TEXT,
    
    FOREIGN KEY (trope_id) REFERENCES trope_config(id),
    FOREIGN KEY (requires_trope_id) REFERENCES trope_config(id)
);

-- ============================================================================
-- TABLE: economy_snapshots
-- Point-in-time snapshots of the game's economy state from simulation runs.
-- ============================================================================
CREATE TABLE economy_snapshots (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id        TEXT NOT NULL,
    
    snapshot_type     TEXT NOT NULL,             -- 'currency-flow', 'drop-rate', 'progression-curve',
                                                -- 'crafting-cost', 'shop-prices', 'xp-curve'
    
    -- Simulation parameters
    sim_days          INTEGER,                   -- How many in-game days simulated
    player_archetype  TEXT,                      -- 'speedrunner', 'completionist', 'casual', 'grinder', 'whale'
    
    -- Results
    data              TEXT NOT NULL,             -- JSON: full economy snapshot data
    health_score      INTEGER,                   -- 0-100 economy health rating
    warnings          TEXT DEFAULT '[]',         -- JSON: ['inflation detected', 'dead-end build path']
    
    -- Agent
    generated_by      TEXT,                      -- Agent that ran the simulation
    created_at        TEXT DEFAULT (datetime('now')),
    
    FOREIGN KEY (project_id) REFERENCES game_projects(id)
);
```

#### Playtest Tables

```sql
-- ============================================================================
-- TABLE: playtest_runs
-- AI bot playtest sessions. Bots play the game as different archetypes.
-- ============================================================================
CREATE TABLE playtest_runs (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id        TEXT NOT NULL,
    build_id          INTEGER,                   -- Which build was tested
    
    -- Playtest configuration
    bot_archetype     TEXT NOT NULL,             -- 'speedrunner', 'completionist', 'casual', 'grinder',
                                                -- 'explorer', 'social', 'competitive'
    session_count     INTEGER DEFAULT 1,         -- Number of play sessions simulated
    session_duration  INTEGER,                   -- Minutes per session
    
    -- Results
    status            TEXT DEFAULT 'pending',    -- 'pending','running','completed','failed'
    started_at        TEXT,
    completed_at      TEXT,
    
    -- Summary scores
    fun_score         INTEGER,                   -- 0-100 fun factor rating
    friction_score    INTEGER,                   -- 0-100 (lower = more friction = bad)
    engagement_score  INTEGER,                   -- 0-100 engagement rating
    
    -- Findings
    softlocks_found   INTEGER DEFAULT 0,         -- Number of softlock situations
    exploits_found    INTEGER DEFAULT 0,         -- Number of exploitable mechanics
    crashes_found     INTEGER DEFAULT 0,         -- Number of crashes during play
    boring_zones      TEXT DEFAULT '[]',         -- JSON: ['zone-3-basement', 'tutorial-step-5']
    
    -- Full report
    report_path       TEXT,                      -- Path to detailed playtest report
    
    generated_by      TEXT,                      -- Playtest agent ID
    created_at        TEXT DEFAULT (datetime('now')),
    
    FOREIGN KEY (project_id) REFERENCES game_projects(id),
    FOREIGN KEY (build_id) REFERENCES builds(id)
);

-- ============================================================================
-- TABLE: playtest_metrics
-- Detailed metrics from playtest sessions. Time-series data per session.
-- ============================================================================
CREATE TABLE playtest_metrics (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    playtest_run_id   INTEGER NOT NULL,
    
    metric_name       TEXT NOT NULL,             -- 'session_length_min', 'deaths_per_hour', 'gold_earned',
                                                -- 'quests_completed', 'areas_discovered', 'items_crafted',
                                                -- 'fps_avg', 'fps_min', 'load_time_avg', 'memory_peak_mb'
    metric_value      REAL NOT NULL,
    metric_unit       TEXT,                      -- 'minutes', 'count', 'gold', 'fps', 'mb', 'seconds'
    
    -- Context
    game_area         TEXT,                      -- Where in the game this metric was recorded
    game_time         TEXT,                      -- In-game time
    session_number    INTEGER,                   -- Which play session
    
    FOREIGN KEY (playtest_run_id) REFERENCES playtest_runs(id)
);
```

#### Patch & Version Tables

```sql
-- ============================================================================
-- TABLE: patches
-- Version and patch tracking. Delta patches, hotfixes, DLC.
-- ============================================================================
CREATE TABLE patches (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id        TEXT NOT NULL,
    
    version_from      TEXT NOT NULL,             -- '1.0.0'
    version_to        TEXT NOT NULL,             -- '1.0.1'
    patch_type        TEXT NOT NULL,             -- 'hotfix', 'minor', 'major', 'dlc', 'season'
    
    -- Content
    changelog         TEXT NOT NULL,             -- Markdown changelog
    player_notes      TEXT,                      -- Player-facing patch notes
    
    -- Files
    total_size_bytes  INTEGER,                   -- Total patch size
    files_changed     INTEGER,                   -- Number of files changed
    files_added       INTEGER,
    files_removed     INTEGER,
    
    -- Save compatibility
    save_compatible   INTEGER DEFAULT 1,         -- 0=requires save migration, 1=compatible
    migration_script  TEXT,                      -- Path to save migration script
    
    -- Rollback
    rollback_path     TEXT,                      -- Path to rollback package
    rollback_tested   INTEGER DEFAULT 0,
    
    -- Status
    status            TEXT DEFAULT 'draft',      -- 'draft','testing','staged','rolling-out','complete','rolled-back'
    rollout_percent   INTEGER DEFAULT 0,         -- 0-100 staged rollout progress
    
    created_at        TEXT DEFAULT (datetime('now')),
    released_at       TEXT,
    
    FOREIGN KEY (project_id) REFERENCES game_projects(id)
);

-- ============================================================================
-- TABLE: patch_assets
-- Which assets changed in each patch. Links patches to the asset registry.
-- ============================================================================
CREATE TABLE patch_assets (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    patch_id          INTEGER NOT NULL,
    asset_id          TEXT NOT NULL,
    change_type       TEXT NOT NULL,             -- 'added', 'modified', 'removed', 'renamed'
    old_hash          TEXT,                      -- Previous file hash
    new_hash          TEXT,                      -- New file hash
    
    FOREIGN KEY (patch_id) REFERENCES patches(id),
    FOREIGN KEY (asset_id) REFERENCES assets(id)
);
```

#### Infrastructure Tables

```sql
-- ============================================================================
-- TABLE: docker_containers
-- Active Docker containers for agent work environments.
-- ============================================================================
CREATE TABLE docker_containers (
    container_id      TEXT PRIMARY KEY,          -- Docker container ID
    project_id        TEXT NOT NULL,
    
    image             TEXT NOT NULL,             -- 'gamedev-3d', 'gamedev-audio', etc.
    agent_id          TEXT,                      -- Agent using this container
    
    status            TEXT DEFAULT 'created',    -- 'created','running','stopped','removed'
    created_at        TEXT DEFAULT (datetime('now')),
    started_at        TEXT,
    stopped_at        TEXT,
    
    -- Resource usage
    cpu_percent       REAL,
    memory_mb         REAL,
    disk_mb           REAL,
    
    -- Mounts
    volume_mounts     TEXT DEFAULT '[]',         -- JSON: [{host:'path',container:'path'}]
    
    FOREIGN KEY (project_id) REFERENCES game_projects(id)
);

-- ============================================================================
-- TABLE: prompt_templates
-- Per-agent-type prompt templates with placeholder support.
-- ============================================================================
CREATE TABLE prompt_templates (
    agent_type        TEXT PRIMARY KEY,          -- 'humanoid-character-sculptor'
    prompt_template   TEXT NOT NULL,             -- Template with {project_name}, {style_guide}, etc.
    output_path_template TEXT,                   -- Where output should go
    updated_at        TEXT DEFAULT (datetime('now'))
);

-- ============================================================================
-- TABLE: session_state
-- Key-value store for session-level state.
-- ============================================================================
CREATE TABLE session_state (
    key               TEXT PRIMARY KEY,
    value             TEXT NOT NULL,
    updated_at        TEXT DEFAULT (datetime('now'))
);

-- ============================================================================
-- TABLE: conventions
-- Game project conventions. Style rules, naming patterns, quality thresholds.
-- ============================================================================
CREATE TABLE conventions (
    id                TEXT PRIMARY KEY,          -- 'sprite-naming'
    project_id        TEXT NOT NULL,
    category          TEXT NOT NULL,             -- 'naming', 'quality', 'style', 'technical', 'pipeline'
    rule              TEXT NOT NULL,             -- The convention rule
    example           TEXT,                      -- Example of correct usage
    severity          TEXT DEFAULT 'warning',    -- 'error', 'warning', 'info'
    created_at        TEXT DEFAULT (datetime('now')),
    
    FOREIGN KEY (project_id) REFERENCES game_projects(id)
);

-- ============================================================================
-- TABLE: activity_log
-- Full audit trail. Every significant action logged with timestamp and actor.
-- ============================================================================
CREATE TABLE activity_log (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id        TEXT NOT NULL,
    
    action            TEXT NOT NULL,             -- 'agent_dispatched', 'agent_completed', 'asset_created',
                                                -- 'build_triggered', 'audit_completed', 'trope_enabled',
                                                -- 'pipeline_advanced', 'store_submitted', 'patch_released'
    actor             TEXT,                      -- Agent ID, user, or 'system'
    target            TEXT,                      -- What was acted upon
    details           TEXT,                      -- JSON with action-specific details
    
    created_at        TEXT DEFAULT (datetime('now')),
    
    FOREIGN KEY (project_id) REFERENCES game_projects(id)
);

-- ============================================================================
-- INDEXES
-- ============================================================================
CREATE INDEX idx_assets_project ON assets(project_id);
CREATE INDEX idx_assets_type ON assets(asset_type);
CREATE INDEX idx_assets_status ON assets(status);
CREATE INDEX idx_assets_pipeline ON assets(pipeline_id);
CREATE INDEX idx_asset_deps_parent ON asset_deps(parent_asset_id);
CREATE INDEX idx_asset_deps_child ON asset_deps(child_asset_id);
CREATE INDEX idx_dispatches_project ON dispatches(project_id);
CREATE INDEX idx_dispatches_status ON dispatches(status);
CREATE INDEX idx_dispatches_agent_type ON dispatches(agent_type);
CREATE INDEX idx_audit_scores_project ON audit_scores(project_id);
CREATE INDEX idx_audit_scores_target ON audit_scores(target);
CREATE INDEX idx_audit_scores_dimension ON audit_scores(dimension);
CREATE INDEX idx_audit_findings_severity ON audit_findings(severity);
CREATE INDEX idx_audit_findings_status ON audit_findings(status);
CREATE INDEX idx_builds_project ON builds(project_id);
CREATE INDEX idx_builds_version ON builds(version);
CREATE INDEX idx_pipeline_state_project ON pipeline_state(project_id);
CREATE INDEX idx_pipeline_state_status ON pipeline_state(status);
CREATE INDEX idx_activity_log_project ON activity_log(project_id);
CREATE INDEX idx_activity_log_action ON activity_log(action);
CREATE INDEX idx_activity_log_created ON activity_log(created_at);
```

### Schema Statistics

| Metric | Count |
|--------|-------|
| Total tables | 26 (including FTS) |
| Total columns | ~250 |
| Foreign key relationships | 28 |
| Indexes | 17 |
| FTS5 virtual tables | 1 (assets_fts) |

---

## 5. MCP Tool Catalog

The ACP server exposes ~120 MCP tools organized into 12 domains. Every tool is callable by AI agents or the CLI. All tools are atomic, transactional (single SQLite transaction), and return structured JSON.

### Domain 1: Project Management (8 tools)

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `project.create` | Create a new game project with all defaults | name, pitch, genre, art_style, perspective, engine |
| `project.configure` | Update project settings (platforms, stores, convergence threshold) | project_id, settings (JSON) |
| `project.set_active` | Switch the active project context | project_id |
| `project.get_status` | Full project status: pipeline progress, asset counts, build status, agent pool | project_id |
| `project.list` | List all registered game projects | — |
| `project.import_gdd` | Parse a GDD and auto-populate project metadata (genre, platforms, tropes) | project_id, gdd_path |
| `project.export_snapshot` | Export complete project state to JSON for handoff/backup | project_id |
| `project.archive` | Mark project as archived (no new dispatches) | project_id |

### Domain 2: Agent Dispatch & Management (14 tools)

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `agent.dispatch_next` | Get next available task across all pipelines, respecting deps and priorities | pipeline_filter?, priority? |
| `agent.dispatch` | Dispatch a specific agent to a specific task | agent_type, target, pipeline_id |
| `agent.complete` | Mark agent as completed with results | agent_id, score?, verdict?, output_paths?, summary? |
| `agent.crash` | Mark agent as crashed, reset task to pending | agent_id, error_message? |
| `agent.get_running` | List all currently running agents with timing | stale_threshold_min? |
| `agent.health_check` | Detect stalled agents (running > threshold) | threshold_minutes |
| `agent.crash_recovery` | Reset all orphaned agents back to pending | stale_threshold_min? |
| `agent.get_capacity` | Running count, available slots, utilization % | — |
| `agent.get_prompt` | Generate dispatch prompt for an agent type with full context injection | agent_type, target |
| `agent.update_prompt_template` | Update an agent's prompt template in the DB | agent_type, template |
| `agent.list_registry` | List all registered agents with capabilities | category_filter? |
| `agent.get_container` | Get the Docker container config for an agent type | agent_type |
| `agent.fill_slots` | Dispatch agents to fill all available slots (priority-aware) | max_slots? |
| `agent.performance_stats` | Agent type performance: avg time, pass rate, common failures | agent_type? |

### Domain 3: Pipeline Operations (12 tools)

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `pipeline.list` | List all 9 pipelines with completion percentage | — |
| `pipeline.status` | Detailed status for one pipeline: per-step progress, running agents, blockers | pipeline_id |
| `pipeline.advance` | Advance to next step in pipeline (with gate check) | pipeline_id, task_id? |
| `pipeline.gate_check` | Check if all prerequisites for next step are met | pipeline_id, target_step? |
| `pipeline.history` | Activity log for a pipeline | pipeline_id, twig? |
| `pipeline.get_critical_path` | Longest dependency chain across all pipelines | — |
| `pipeline.cross_deps` | List all cross-pipeline dependencies with satisfaction status | — |
| `pipeline.get_blockers` | What's blocking pipeline progress right now? | pipeline_id? |
| `pipeline.parallel_status` | Show all 9 pipelines side-by-side with progress bars | — |
| `pipeline.reset_step` | Reset a pipeline step back to pending (for re-dispatch) | pipeline_id, step_id |
| `pipeline.skip_step` | Skip a step (with justification logged) | pipeline_id, step_id, reason |
| `pipeline.estimate_completion` | ETA based on current throughput and remaining work | — |

### Domain 4: Asset Management (14 tools)

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `asset.register` | Register a new asset with metadata | name, type, file_path, category, metadata |
| `asset.query` | Search assets by type, category, status, tags | filters (JSON) |
| `asset.search` | Full-text search across asset names and descriptions | query_text |
| `asset.get` | Get full asset details including metadata and dependencies | asset_id |
| `asset.update_status` | Transition asset status (draft → review → approved) | asset_id, new_status |
| `asset.validate` | Run validation checks on an asset (format, size, naming) | asset_id |
| `asset.add_dependency` | Add a dependency edge between two assets | parent_id, child_id, dep_type |
| `asset.get_dep_tree` | Get full dependency tree for an asset (up and downstream) | asset_id, direction?, depth? |
| `asset.check_readiness` | Check if all dependencies of an asset are in 'approved' status | asset_id |
| `asset.get_orphans` | Find assets with no dependencies (potential stale assets) | — |
| `asset.get_missing` | Find expected assets that don't exist yet (from pipeline defs) | — |
| `asset.bulk_register` | Register multiple assets at once (batch operation) | assets (JSON array) |
| `asset.get_stats` | Asset counts by type, category, status | — |
| `asset.generate_manifest` | Generate ASSET-MANIFEST.json from current asset registry | output_path? |

### Domain 5: Build Management (10 tools)

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `build.trigger` | Trigger a new build for specified platforms | version, build_type, platforms[] |
| `build.status` | Get status of a specific build | build_id |
| `build.get_matrix` | Cross-platform build matrix (all platforms × latest builds) | — |
| `build.get_latest` | Get the latest successful build per platform | platform? |
| `build.platform_cert` | Update certification status for a platform build | build_id, platform, cert_status |
| `build.smoke_test` | Trigger smoke tests on a build | build_id |
| `build.get_history` | Build history with pass/fail trends | limit? |
| `build.cancel` | Cancel a running build | build_id |
| `build.promote` | Promote a build from development → staging → release | build_id, target_stage |
| `build.get_size_trend` | Track build size over versions (detect bloat) | platform? |

### Domain 6: Quality & Audit (12 tools)

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `audit.score` | Record a quality score for a target × dimension | target, dimension, score, agent_id |
| `audit.get_scoreboard` | All targets ranked by score across dimensions | dimension? |
| `audit.get_trend` | Score progression over audit rounds per target | target |
| `audit.get_remediation_queue` | CONDITIONAL/FAIL targets ordered by severity | dimension? |
| `audit.convergence_status` | Per-target: converged, stalled, or in-progress per dimension | target? |
| `audit.import_report` | Parse an audit report file and import scores + findings | report_path, target |
| `audit.get_findings` | List findings filtered by severity, category, status | filters |
| `audit.assign_finding` | Assign a finding to a fix agent | finding_id, agent_id |
| `audit.resolve_finding` | Mark finding as fixed/deferred | finding_id, status, fix_description |
| `audit.stall_check` | Detect targets with 3+ rounds within ±2pts (Rule 4.2) | — |
| `audit.dimension_summary` | Summary per quality dimension: avg score, pass rate, worst targets | — |
| `audit.get_all_dimensions` | List all 10 quality dimensions with descriptions | — |

### Domain 7: Trope Management (8 tools)

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `trope.enable` | Enable a trope addon for the project | trope_id |
| `trope.disable` | Disable a trope (with dependency warning if others depend on it) | trope_id |
| `trope.list` | List all 18 tropes with enabled/disabled status | — |
| `trope.get_config` | Get configuration for a specific trope | trope_id |
| `trope.update_config` | Update trope-specific configuration | trope_id, config (JSON) |
| `trope.dep_check` | Check if enabling/disabling a trope would break dependencies | trope_id, action |
| `trope.get_agents` | List all agents activated by enabled tropes | — |
| `trope.bulk_enable` | Enable multiple tropes at once (with dep resolution) | trope_ids[] |

### Domain 8: Playtest & Balance (10 tools)

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `playtest.run` | Dispatch a playtest bot session | bot_archetype, session_count, session_duration |
| `playtest.get_results` | Get results from a playtest run | playtest_run_id |
| `playtest.get_latest` | Get the most recent playtest results per archetype | archetype? |
| `playtest.get_metrics` | Query specific metrics from playtest data | metric_name, playtest_run_id? |
| `playtest.compare` | Compare metrics between two playtest runs | run_id_a, run_id_b |
| `playtest.get_softlocks` | List all discovered softlock situations across playtests | — |
| `playtest.get_exploits` | List all discovered exploitable mechanics | — |
| `playtest.schedule` | Schedule automatic playtests after every N completions | interval_completions |
| `economy.simulate` | Run economy simulation with specified parameters | archetype, sim_days |
| `economy.get_health` | Current economy health score with breakdown | — |

### Domain 9: Store & Distribution (8 tools)

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `store.submit` | Create a store submission for a build | store, build_id |
| `store.get_status` | Get submission status for a specific store | submission_id |
| `store.get_all` | All store submissions for the project | — |
| `store.update_status` | Update submission status (e.g., after store review) | submission_id, new_status |
| `store.requirements_checklist` | Get per-store requirements with completion status | store |
| `store.check_requirement` | Mark a requirement as satisfied | requirement_id |
| `store.generate_metadata` | Auto-generate store page metadata from GDD | store, build_id |
| `store.get_readiness` | Overall readiness score per store | store? |

### Domain 10: Docker & Container Management (8 tools)

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `docker.container_for` | Get the recommended container for an agent type | agent_type |
| `docker.start` | Start a container for an agent | image, agent_id, volume_mounts[] |
| `docker.stop` | Stop a running container | container_id |
| `docker.health` | Container health check (running, CPU, memory) | container_id |
| `docker.list` | List all active containers | — |
| `docker.image_status` | Check if all required Docker images are built/pulled | — |
| `docker.cleanup` | Remove stopped containers and dangling images | — |
| `docker.volume_mount` | Get the volume mount configuration for a project | project_id |

### Domain 11: Patch & Version Management (8 tools)

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `patch.create` | Create a new patch record | version_from, version_to, patch_type, changelog |
| `patch.get_manifest` | Generate delta manifest (what changed between versions) | patch_id |
| `patch.add_asset` | Link a changed asset to a patch | patch_id, asset_id, change_type |
| `patch.get_history` | Version history with patch sizes and changelogs | limit? |
| `patch.rollback_check` | Verify rollback package exists and is valid | patch_id |
| `patch.rollout_status` | Current staged rollout progress | patch_id |
| `patch.update_rollout` | Update staged rollout percentage | patch_id, percent |
| `patch.save_migration_check` | Verify save file compatibility with new version | patch_id |

### Domain 12: Analytics & Session (10 tools)

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `analytics.throughput` | Completions per hour, current throughput | — |
| `analytics.pass_rate` | Pass/conditional/fail distribution | dimension? |
| `analytics.agent_performance` | Per-agent-type avg score, avg time, crash rate | — |
| `analytics.estimated_completion` | ETA for project completion based on current velocity | — |
| `analytics.cost_summary` | Token spend, cost per dispatch, cost by model | time_range? |
| `analytics.pipeline_velocity` | Per-pipeline completion rate and bottleneck identification | — |
| `session.snapshot` | Export full session state to JSON | — |
| `session.get_state` | Get session key-value pairs | key? |
| `session.set_state` | Set session state | key, value |
| `session.reset_commit_counter` | Reset the git commit counter | — |

### Tool Count Summary

| Domain | Tools |
|--------|-------|
| Project Management | 8 |
| Agent Dispatch | 14 |
| Pipeline Operations | 12 |
| Asset Management | 14 |
| Build Management | 10 |
| Quality & Audit | 12 |
| Trope Management | 8 |
| Playtest & Balance | 10 |
| Store & Distribution | 8 |
| Docker Management | 8 |
| Patch & Version | 8 |
| Analytics & Session | 10 |
| **TOTAL** | **122** |

---

## 6. Pipeline Engine

### The 9 Pipelines

Game development isn't a linear belt — it's 9 parallel creation streams that converge at integration points. The Pipeline Engine manages all 9 simultaneously, tracking per-step progress, enforcing dependency gates, and orchestrating cross-pipeline handoffs.

```
                    ┌─────────────────────────────────────────────────────┐
                    │              THE 9 GAME DEV PIPELINES               │
                    │                                                     │
  Pipeline 1:  ════╪═══════════════════════════════════════════════════╗ │
  CORE GAME LOOP   │  GDD → Bibles → Decompose → Tickets → Code → Test → Ship
                    │                                                     │
  Pipeline 2:  ────┤─ Narrative → Characters → Dialogue → Quests ─── ↗  │
  NARRATIVE         │                                                     │
                    │                                                     │
  Pipeline 3:  ────┤─ Style Guide → Sculptors → Media → Assembly ─── ↗  │
  ART               │                                                     │
                    │                                                     │
  Pipeline 4:  ────┤─ Audio Dir → Composer → SFX → Integration ───── ↗  │
  AUDIO             │                                                     │
                    │                                                     │
  Pipeline 5:  ────┤─ World Map → Terrain → Biomes → Scenes ──────── ↗  │
  WORLD             │                                                     │
                    │                                                     │
  Pipeline 6:  ────┤─ Economy → Drop Tables → Balance → Simulate ─── ↗  │
  ECONOMY           │                                                     │
                    │                                                     │
  Pipeline 7:  ────┤─ Build → Package → Submit → Launch → Patches ── ↗  │
  DISTRIBUTION      │                                                     │
                    │                                                     │
  Pipeline 8:  ────┤─ Camera → Cutscenes → Cinematics → Trailer ──── ↗  │
  CAMERA/CINEMATIC  │                                                     │
                    │                                                     │
  Pipeline 9:  ────┤─ [Pets] [Crafting] [Housing] [Fishing] [...] ─── ↗  │
  TROPE ADDONS      │  (only enabled tropes generate pipeline steps)      │
                    └─────────────────────────────────────────────────────┘
```

### Pipeline State Machine

Each pipeline step goes through a state machine:

```
                    ┌─────────┐
                    │ PENDING │ ← Initial state
                    └────┬────┘
                         │ All dependencies satisfied
                         ▼
                    ┌─────────┐
              ┌─────│ READY   │ ← Can be dispatched
              │     └────┬────┘
              │          │ Agent dispatched
              │          ▼
              │     ┌─────────┐
              │     │ RUNNING │ ← Agent working
              │     └────┬────┘
              │          │
              │    ┌─────┼─────┐
              │    │     │     │
              │    ▼     ▼     ▼
              │ ┌──────┐ ┌──────┐ ┌─────────┐
              │ │PASSED│ │COND. │ │ FAILED  │
              │ │ ≥96  │ │70-91 │ │  <70    │
              │ └──┬───┘ └──┬───┘ └────┬────┘
              │    │        │          │
              │    │    ┌───┘    ┌─────┘
              │    │    ▼        ▼
              │    │  ┌──────────────┐
              │    │  │ CONVERGING   │ ← Fix → Re-audit loop
              │    │  └──────┬───────┘
              │    │         │ 3 rounds ±2pts
              │    │         ▼
              │    │  ┌──────────────┐
              │    │  │ STALLED      │ ← Manual review needed
              │    │  └──────────────┘
              │    │
              │    ▼
              │ ┌──────────────┐
              │ │ COMPLETED    │ ← Unblocks downstream
              │ └──────────────┘
              │
              └─ Agent crashed → back to READY
```

### Cross-Pipeline Dependencies

The Pipeline Engine maintains a dependency graph between pipelines. Key cross-pipeline dependencies:

```
                         ┌───────────────┐
                         │ Pipeline 1    │
                         │ CORE GAME LOOP│
                         └───────┬───────┘
                                 │ GDD, Bibles, Style Guide
                    ┌────────────┼────────────┬───────────┐
                    │            │            │           │
                    ▼            ▼            ▼           ▼
          ┌─────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
          │ Pipeline 2  │ │Pipeline 3│ │Pipeline 4│ │Pipeline 5│
          │ NARRATIVE   │ │ ART      │ │ AUDIO    │ │ WORLD    │
          └──────┬──────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
                 │             │            │             │
                 │     ┌───────┘            │             │
                 │     │ Character models   │             │
                 │     │ needed for         │             │
                 │     │ animation          │             │
                 ▼     ▼                    ▼             ▼
          ┌───────────────────────────────────────────────────────┐
          │                 INTEGRATION POINT                      │
          │ All art + audio + world + narrative must exist before  │
          │ full implementation and playtesting can proceed        │
          └───────────────────────┬───────────────────────────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
          ┌─────────────┐ ┌──────────┐ ┌──────────┐
          │ Pipeline 6  │ │Pipeline 8│ │Pipeline 9│
          │ ECONOMY     │ │ CAMERA   │ │ TROPES   │
          └──────┬──────┘ └────┬─────┘ └────┬─────┘
                 │             │             │
                 └─────────────┼─────────────┘
                               ▼
                    ┌──────────────────┐
                    │ Pipeline 7       │
                    │ DISTRIBUTION     │
                    │ (Build → Ship)   │
                    └──────────────────┘
```

### Key Cross-Pipeline Dependencies (Codified)

| From Pipeline | From Step | To Pipeline | To Step | Dependency |
|--------------|-----------|-------------|---------|------------|
| 1-Core | GDD | ALL | Step 1 | GDD feeds every pipeline's first step |
| 1-Core | Style Guide | 3-Art | All steps | Art Director's guide is the style authority |
| 1-Core | Music Direction | 4-Audio | All steps | Audio Director's guide governs all audio |
| 2-Narrative | Character Bible | 3-Art | Sculptors | Character designs needed before art creation |
| 2-Narrative | Lore Bible | 5-World | World Map | Lore informs region design and naming |
| 3-Art | Character Models | 3-Art | Animation | Can't animate what doesn't exist yet |
| 3-Art | Tilesets | 5-World | Level Design | Levels need tilesets to build with |
| 3-Art | UI Assets | 1-Core | Code Executor | Code can't reference UI elements that don't exist |
| 4-Audio | Music Stems | 1-Core | Code Executor | Code integrates audio assets |
| 5-World | Level Layouts | 1-Core | Playtest | Can't playtest without levels |
| 1-Core | Economy Model | 6-Economy | All | Economy params define what to balance |
| 6-Economy | Balance Report | 7-Distribution | Build | Can't ship an unbalanced game |
| ALL | Quality ≥96 | 7-Distribution | Build | All dimensions must pass before build |

### Pipeline Engine Implementation

```typescript
class PipelineEngine {
  // Get the next dispatchable task across ALL pipelines
  // Returns the highest-priority task whose dependencies are satisfied
  getNextDispatchable(projectId: string): DispatchTarget | null {
    // Priority order:
    // 1. Critical path tasks (longest dependency chain)
    // 2. Tasks that unblock the most downstream work
    // 3. Main pipeline (Core Game Loop) over subsidiary pipelines
    // 4. Earlier pipeline steps over later ones
    // 5. Trope pipeline steps only when primary slots are full
  }

  // Check if a specific pipeline step can proceed
  checkGate(pipelineId: string, stepId: number): GateResult {
    // Checks:
    // 1. Previous step in same pipeline is COMPLETED
    // 2. All cross-pipeline dependencies are COMPLETED
    // 3. All required asset dependencies are APPROVED
    // 4. Agent slot is available
    // 5. Docker container is healthy (if required)
  }

  // Get cross-pipeline dependency status
  getCrossDepStatus(): CrossDepStatus[] {
    // Recursive CTE to walk pipeline_deps table
    // Returns: satisfied, unsatisfied, percentage complete
  }

  // Compute critical path across all pipelines
  getCriticalPath(): CriticalPath {
    // Topological sort across all pipeline steps + cross-deps
    // Returns longest chain with total estimated time
  }
}
```

---

## 7. Asset Management System

### The Asset Lifecycle

Every game asset — sprite, 3D model, texture, sound, tilemap, scene, script — goes through a tracked lifecycle:

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  DRAFT   │────▶│IN-PROGRESS│────▶│  REVIEW  │────▶│ APPROVED │────▶│INTEGRATED│
│          │     │           │     │          │     │          │     │          │
│ Spec     │     │ Agent     │     │ Quality  │     │ Passes   │     │ In the   │
│ exists   │     │ working   │     │ audit    │     │ audit    │     │ game     │
│ but no   │     │ on it     │     │ pending  │     │          │     │ build    │
│ file yet │     │           │     │          │     │          │     │          │
└──────────┘     └──────────┘     └──────────┘     └──────────┘     └──────────┘
                                       │                                  │
                                       │ Fails audit                      │
                                       ▼                                  ▼
                                  back to                            ┌──────────┐
                                  IN-PROGRESS                        │DEPRECATED│
                                  for fixes                          │ (replaced│
                                                                     │ by newer) │
                                                                     └──────────┘
```

### Asset Dependency Graph

The most critical game-specific feature. Enterprise CGS tracks module dependencies (A → B means A imports B). CGS-Game tracks asset creation dependencies — a deep DAG where each asset requires other assets to exist first:

```
CHARACTER DESIGN SPEC (from Character Designer)
    │
    ├──→ CHARACTER MODEL (from Sculptor)
    │        │
    │        ├──→ SKELETON RIG (from 3D Pipeline Specialist)
    │        │        │
    │        │        ├──→ WALK ANIMATION (from Animation Sequencer)
    │        │        ├──→ IDLE ANIMATION
    │        │        ├──→ ATTACK ANIMATION
    │        │        └──→ DEATH ANIMATION
    │        │
    │        ├──→ TEXTURE MAP (from Texture & Material Artist)
    │        │        ├──→ ALBEDO MAP
    │        │        ├──→ NORMAL MAP
    │        │        └──→ EMISSION MAP
    │        │
    │        └──→ LOD CHAIN (from 3D Pipeline Specialist)
    │                 ├──→ LOD0 (full detail)
    │                 ├──→ LOD1 (medium)
    │                 └──→ LOD2 (distant)
    │
    ├──→ SPRITE SHEET (from 2D Asset Renderer)
    │        │
    │        ├──→ SPRITE ANIMATIONS (from Animation Sequencer)
    │        │
    │        └──→ PORTRAIT ICON (from 2D Asset Renderer)
    │
    └──→ CHARACTER SCENE (.tscn) (from Game Code Executor)
             │
             ├──→ References: model OR spritesheet
             ├──→ References: animations
             ├──→ References: sound effects (hit, footstep, voice)
             └──→ References: AI behavior tree
```

### Dependency Resolution Algorithm

```typescript
class AssetDepGraph {
  // Check if an asset's dependencies are all satisfied
  checkReadiness(assetId: string): ReadinessResult {
    // Walk up the dependency tree
    // For each parent dependency:
    //   - Does the parent asset exist?
    //   - Is the parent asset in 'approved' or 'integrated' status?
    //   - Are the parent's dependencies satisfied? (recursive)
    // Return: ready, blocked (with list of blocking assets), or circular
  }

  // Cycle detection using DFS with coloring
  detectCycles(): Cycle[] {
    // White (unvisited), Gray (in current DFS path), Black (fully processed)
    // If we reach a Gray node during DFS → cycle detected
    // Return all cycles found
  }

  // Get the full upstream dependency chain (what this asset needs)
  getUpstream(assetId: string, depth?: number): AssetNode[] {
    // Recursive CTE:
    // WITH RECURSIVE upstream AS (
    //   SELECT parent_asset_id FROM asset_deps WHERE child_asset_id = ?
    //   UNION ALL
    //   SELECT ad.parent_asset_id FROM asset_deps ad
    //   JOIN upstream u ON ad.child_asset_id = u.parent_asset_id
    // )
  }

  // Get the full downstream dependency chain (what depends on this asset)
  getDownstream(assetId: string, depth?: number): AssetNode[] {
    // Same recursive CTE but walking child→parent direction
  }

  // Find which assets are blocking the most downstream work
  getBottlenecks(): AssetBottleneck[] {
    // For each asset in 'draft' or 'in-progress' status:
    //   Count downstream dependents (recursive)
    //   Rank by downstream count (most-blocking first)
  }

  // Trigger cascade when an asset is approved
  onAssetApproved(assetId: string): CascadeAction[] {
    // Find all direct children in asset_deps
    // For each child: if ALL of child's deps are now satisfied → mark as READY
    // Return list of assets that became dispatchable
  }
}
```

### Asset Validation Rules

Every asset type has validation rules that are checked before the asset can move to 'approved' status:

| Asset Type | Validation Rules |
|-----------|-----------------|
| **Sprites** | Dimensions are power-of-2, palette ≤ 256 colors, alpha channel present, filename follows convention |
| **3D Models** | Poly count within LOD budget, manifold geometry, UV unwrapped, no degenerate faces, glTF valid |
| **Textures** | Power-of-2 dimensions, correct PBR channels (albedo/normal/roughness), tileable if flagged |
| **Audio** | Sample rate ≥ 44100, bit depth ≥ 16, duration within expected range, loudness within ±3 LUFS of target |
| **Tilemaps** | Tile IDs reference existing tilesets, no orphan tiles, collision layer present, navigation mesh valid |
| **Scenes** | All referenced assets exist, no broken references, scene tree valid, physics layers correct |
| **Scripts** | GDScript lint passes (gdtoolkit), no syntax errors, follows naming conventions |
| **Animations** | Frame count matches spec, loop point correct, timing within tolerance, events registered |

---

## 8. Agent Registry & Dispatch Engine

### Agent Categories (11 Categories, 87+ Agents)

| Category | Agent Count | Pipeline(s) | Container |
|----------|------------|-------------|-----------|
| 🎮 Vision & Pre-Production | 7 | Pipeline 1 | gamedev-base |
| 🗿 Form Sculptors | 11 | Pipeline 3 | gamedev-3d |
| 🎬 Media Pipeline Specialists | 4 | Pipeline 3 | gamedev-2d/3d |
| 🏗️ Asset Creation & Assembly | 7 | Pipeline 3, 5 | gamedev-2d/3d/engine |
| 💻 Implementation | 7 | Pipeline 1 | gamedev-engine |
| 🎰 Game Trope Addons | 18 | Pipeline 9 | gamedev-engine |
| 🧪 Quality & Balance | 6 | Pipeline 6 | gamedev-engine |
| 🚀 Ship & Live Ops | 5 | Pipeline 7 | gamedev-engine |
| 🎥 Camera & Cinematics | 2 | Pipeline 8 | gamedev-engine |
| 🔧 Pipeline Infrastructure | 8 | All | gamedev-base |
| 📊 Distribution | 8 | Pipeline 7 | gamedev-base |

### Dispatch Engine Architecture

The dispatch engine is the brain of CGS-Game. It decides WHAT to dispatch, WHEN, WHERE (which container), and WITH WHAT CONTEXT.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       CGS-GAME DISPATCH ENGINE                          │
│                                                                         │
│  INPUT: "I need the next task to dispatch"                              │
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │ STEP 1: PIPELINE SCAN                                              │ │
│  │                                                                    │ │
│  │ For each of 9 pipelines:                                          │ │
│  │   Find first step where status = 'pending' or 'ready'            │ │
│  │   Check gate: are all dependencies satisfied?                     │ │
│  │   If yes → add to candidate list with priority score              │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                           │                                             │
│  ┌────────────────────────▼───────────────────────────────────────────┐ │
│  │ STEP 2: PRIORITY SCORING                                          │ │
│  │                                                                    │ │
│  │ Each candidate gets a priority score:                              │ │
│  │   +100  Critical path task (blocks the most downstream)           │ │
│  │   +50   Core Game Loop pipeline (Pipeline 1)                      │ │
│  │   +30   Early pipeline step (step 1-3 > step 10+)                │ │
│  │   +20   Asset that unblocks other pipelines                       │ │
│  │   +10   Convergence loop (already started, needs fixing)          │ │
│  │   -20   Trope pipeline (lower priority than core)                 │ │
│  │   -50   Optional quality pass (nice-to-have)                      │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                           │                                             │
│  ┌────────────────────────▼───────────────────────────────────────────┐ │
│  │ STEP 3: CONTAINER SELECTION                                       │ │
│  │                                                                    │ │
│  │ Look up agent_registry.docker_image for the winning agent type    │ │
│  │ Check if container is running → reuse                              │ │
│  │ If not → start new container with project volume mounts           │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                           │                                             │
│  ┌────────────────────────▼───────────────────────────────────────────┐ │
│  │ STEP 4: PROMPT GENERATION                                         │ │
│  │                                                                    │ │
│  │ Load prompt template from prompt_templates table                   │ │
│  │ Inject context:                                                    │ │
│  │   {project_name} → from game_projects                             │ │
│  │   {style_guide} → path to Art Director's style guide              │ │
│  │   {gdd_excerpt} → relevant section of GDD                        │ │
│  │   {asset_manifest} → current asset registry state                 │ │
│  │   {pipeline_state} → current pipeline progress                    │ │
│  │   {conventions} → project conventions from conventions table       │ │
│  │   {dependencies} → what this agent needs as input                 │ │
│  │   {target} → specific task/asset to work on                       │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                           │                                             │
│  ┌────────────────────────▼───────────────────────────────────────────┐ │
│  │ STEP 5: DISPATCH                                                   │ │
│  │                                                                    │ │
│  │ 1. Insert into active_agents (status='running')                   │ │
│  │ 2. Insert into dispatches (audit trail)                           │ │
│  │ 3. Update pipeline_state (status='running')                       │ │
│  │ 4. Start Docker container (if needed)                             │ │
│  │ 5. Launch AI runtime with generated prompt                        │ │
│  │ 6. Log to activity_log                                            │ │
│  │                                                                    │ │
│  │ All 6 steps in a single SQLite transaction (atomic)               │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

### Auto-Cascade Chains

When certain agents complete, CGS-Game automatically dispatches the next agent in the chain without orchestrator intervention:

| Trigger (Agent Completes) | Auto-Dispatch (Next Agent) | Condition |
|--------------------------|---------------------------|-----------|
| Humanoid Character Sculptor | 3D Asset Pipeline Specialist | If project uses 3D |
| Humanoid Character Sculptor | 2D Asset Renderer | If project uses 2D |
| Beast & Creature Sculptor | 3D Asset Pipeline Specialist | If project uses 3D |
| Any Form Sculptor | Texture & Material Artist | Always (textures needed) |
| 3D Asset Pipeline Specialist | Animation Sequencer | If animations specified |
| 2D Asset Renderer | Sprite Sheet Generator | If sprite sheet needed |
| Sprite Sheet Generator | Animation Sequencer | If animations specified |
| Game Economist | Balance Auditor | Always (balance check) |
| Game Code Executor | Playtest Simulator | Every 10 code completions |
| Balance Auditor (FAIL) | Game Economist | Auto-fix cycle |
| Playtest Simulator (FAIL) | Game Code Executor | Fix identified issues |
| Narrative Designer | Character Designer | Character bible done |
| World Cartographer | Terrain & Environment Sculptor | World map done |

### Sculptor → Media Pipeline Chain Example

```
┌──────────────────────┐
│ Humanoid Character   │ ← Dispatched with character spec from Character Designer
│ Sculptor             │
│                      │
│ Produces:            │
│ - design-spec.json   │  ← Form, proportions, equipment slots, variant body types
│ - reference-sheet.md │  ← Visual reference document
│ - rig-requirements   │  ← Bone count, blend shapes, IK targets
└──────────┬───────────┘
           │
           │ AUTO-CASCADE: asset_deps triggers downstream readiness
           │
     ┌─────┴─────────────────────────────┐
     │                                   │
     ▼                                   ▼
┌──────────────────┐           ┌──────────────────┐
│ 3D Asset Pipeline│           │ 2D Asset Renderer│
│ Specialist       │           │                  │
│                  │           │ Produces:        │
│ Produces:        │           │ - character.png  │
│ - character.glb  │           │ - portrait.png   │
│ - character.gltf │           │ - icon-32x32.png │
│ - skeleton.tres  │           │                  │
└──────────┬───────┘           └──────────┬───────┘
           │                              │
           ▼                              ▼
┌──────────────────┐           ┌──────────────────┐
│ Texture &        │           │ Sprite Sheet     │
│ Material Artist  │           │ Generator        │
│                  │           │                  │
│ Produces:        │           │ Produces:        │
│ - albedo.png     │           │ - spritesheet.png│
│ - normal.png     │           │ - frames.json    │
│ - roughness.png  │           │                  │
└──────────┬───────┘           └──────────┬───────┘
           │                              │
           └──────────┬───────────────────┘
                      │
                      ▼
           ┌──────────────────┐
           │ Animation        │
           │ Sequencer        │
           │                  │
           │ Produces:        │
           │ - idle.tres      │
           │ - walk.tres      │
           │ - attack.tres    │
           │ - death.tres     │
           └──────────────────┘
```

---

## 9. Dashboard & Visualization

### The Game Dev Command Center

The CGS-Game dashboard is a real-time visualization of the entire game development state. It's designed for information density — a game dev orchestrator needs to see all 9 pipelines, 87 agents, hundreds of assets, multiple build targets, and quality scores AT A GLANCE.

### Dashboard Panels

#### Panel 1: Pipeline Canvas (Primary View)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ 🎮 CGS-Game Dashboard — Pet Trainer RPG                   [Ctrl+K] ⚡  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  PIPELINE STATUS (9 streams)                                            │
│                                                                         │
│  1. Core Game Loop  ████████████████░░░░░░░░░░░░░░  48%  [12/25 steps] │
│  2. Narrative        █████████████████████░░░░░░░░░  62%  [5/8 steps]  │
│  3. Art Pipeline     ████████░░░░░░░░░░░░░░░░░░░░░  28%  [2/7 steps]  │
│  4. Audio Pipeline   ██████████████████░░░░░░░░░░░  55%  [3/5 steps]  │
│  5. World Pipeline   ████░░░░░░░░░░░░░░░░░░░░░░░░░  15%  [1/6 steps]  │
│  6. Economy/Balance  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   0%  [0/4 steps]  │
│  7. Distribution     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   0%  [0/6 steps]  │
│  8. Camera/Cinematic ██████████░░░░░░░░░░░░░░░░░░░  33%  [1/3 steps]  │
│  9. Trope Addons     ████████████░░░░░░░░░░░░░░░░░  40%  [2/5 active] │
│     ├ 🐾 Pets        ████████████████████████████░  90%  ✅            │
│     ├ 🔨 Crafting    ████████████░░░░░░░░░░░░░░░░  40%  🔄            │
│     ├ 🏠 Housing     ░░░░░░░░░░░░░░░░░░░░░░░░░░░   0%  ⏳            │
│     ├ 🎣 Fishing     ████████░░░░░░░░░░░░░░░░░░░░  30%  🔄            │
│     └ 🌤️ Weather     ██████████████████░░░░░░░░░░  60%  🔄            │
│                                                                         │
│  OVERALL: ██████████████░░░░░░░░░░░░░░  38%  ETA: ~14 hours           │
└─────────────────────────────────────────────────────────────────────────┘
```

#### Panel 2: Agent Pool Monitor

```
┌─────────────────────────────────────────────────────────────────────────┐
│  AGENT POOL  [4/5 running]  [1 slot available]                         │
│                                                                         │
│  🟢 sculptor-beast-001    Beast & Creature Sculptor   Pipeline 3       │
│     Target: Wolf Pack Alpha    Container: gamedev-3d    12 min ⏱️       │
│                                                                         │
│  🟢 composer-bgm-003     Audio Composer               Pipeline 4       │
│     Target: Forest Biome BGM   Container: gamedev-audio  8 min ⏱️      │
│                                                                         │
│  🟢 code-exec-007        Game Code Executor            Pipeline 1       │
│     Target: Combat System      Container: gamedev-engine 22 min ⏱️     │
│                                                                         │
│  🟡 balance-audit-002    Balance Auditor               Pipeline 6       │
│     Target: Economy sim run    Container: gamedev-engine 45 min ⏱️ ⚠️  │
│                                                                         │
│  ⬜ [OPEN SLOT]           Ready for dispatch                            │
│     Next: Terrain Sculptor → Pipeline 5, Step 2                        │
└─────────────────────────────────────────────────────────────────────────┘
```

#### Panel 3: Build Matrix

```
┌─────────────────────────────────────────────────────────────────────────┐
│  BUILD MATRIX  v0.3.0-alpha  Build #47                                 │
│                                                                         │
│  Platform      │ Status │ Size   │ Cert    │ Store                     │
│  ──────────────┼────────┼────────┼─────────┼─────────────────────      │
│  Windows x64   │ ✅ OK  │ 245MB  │ N/A     │ Steam: ⬜ Not submitted   │
│  macOS arm64   │ ✅ OK  │ 260MB  │ N/A     │ Steam: ⬜ Not submitted   │
│  Linux x64     │ ✅ OK  │ 238MB  │ N/A     │ itch.io: ⬜               │
│  Web/HTML5     │ 🔄 ...  │ —      │ N/A     │ itch.io: ⬜               │
│  Android AAB   │ ❌ FAIL │ —      │ ⬜      │ Play: ⬜                  │
│  iOS           │ ⬜ Skip │ —      │ ⬜      │ App Store: ⬜             │
└─────────────────────────────────────────────────────────────────────────┘
```

#### Panel 4: Quality Scorecards + Trope Toggle Panel

(See Sections 13 and 16 for detailed descriptions of these panels.)

---

## 10. Docker Integration

### Container Lifecycle

Agents don't install tools on your machine. They work inside Docker containers with all tools pre-installed. CGS-Game manages the full container lifecycle:

1. **SELECT**: Look up `agent_registry.docker_image` for the agent type
2. **REUSE**: Check if a matching container is already running → reuse it
3. **MOUNT**: Configure volume mounts for project files, output, shared cache
4. **START**: `docker run` with configured volumes and resource limits
5. **WORK**: Agent executes commands inside container via AI runtime
6. **COMPLETE**: Copy output artifacts to project directory, register in DB
7. **WARM**: Keep container alive for reuse (configurable TTL, default 5 min)
8. **CLEANUP**: Stop and remove containers after TTL expires

### Container → Agent Mapping

| Container | Agents | Key Pre-Installed Tools |
|-----------|--------|------------------------|
| `gamedev-base` | ALL infrastructure agents, vision agents | Python, Node.js, ImageMagick, ffmpeg, sox, Git |
| `gamedev-2d` | 2D Renderer, Sprite Gen, Animation Seq, Tilemap, UI | + Aseprite CLI, Inkscape, Tiled, GIMP CLI |
| `gamedev-3d` | ALL 11 Sculptors, 3D Pipeline, VR XR, Texture, Scene | + Blender 4.x, glTF tools, meshoptimizer |
| `gamedev-audio` | Audio Composer, Audio Director | + SuperCollider, LMMS, pydub |
| `gamedev-engine` | Code Executor, AI Behavior, Combat, Dialogue, ALL Trope agents | + Godot 4.x headless, gdtoolkit |
| `gamedev-full` | Game Orchestrator, Build Specialist | Everything from all containers |

### Shared Asset Cache

A shared volume (`/shared-cache/`) prevents re-downloading large tools (Blender 500MB+) on every container start. Contains pre-installed binaries, Python packages, npm packages, and tool configs.

---

## 11. Automation Rules & Convergence Engine

### What Happens Automatically

| Action | Automatic? | Condition |
|--------|-----------|-----------|
| Dispatch next agent | ✅ Yes | Slot available + deps satisfied |
| Auto-cascade: sculptor → media pipeline | ✅ Yes | Sculptor completes with assets |
| Convergence loop: audit → fix → re-audit | ✅ Yes | Score < threshold (default 96) |
| Stall detection | ✅ Yes | 3 rounds within ±2pts → STALLED |
| Crash recovery | ✅ Yes | On session resume |
| Git commit on completion | ✅ Yes | Always (Rule 12.2) |
| Build trigger on code change | ⚙️ Configurable | `auto_build: true` |
| Playtest after N completions | ⚙️ Configurable | `auto_playtest_interval: 10` |

### What Requires Human Approval

| Action | Why Manual |
|--------|-----------|
| Enable/disable trope addon | Design decision affecting game scope |
| Store submission | Legal/business decision with financial implications |
| Patch rollout to live | Risk of breaking live players |
| Change convergence threshold | Quality policy decision |
| Switch game engine | Architectural decision requiring full rebuild |

---

## 12. CLI Design

### Command Structure

```
cgs-game <command> [subcommand] [options]

CORE COMMANDS:
  init              Initialize a new game project
  status            Show project dashboard in terminal
  dispatch          Dispatch agents (auto or manual)
  build             Trigger cross-platform builds
  playtest          Run AI playtest sessions
  audit             Run quality audit sweep
  ship              Full release pipeline

MANAGEMENT:
  patch             Create and manage patches
  trope             Manage trope addons (enable/disable/list/detect)
  asset             Query and manage assets (list/search/deps/validate)
  docker            Container management (status/pull/cleanup)
  agent             Agent pool management (list/health/crash-recovery)
  pipeline          Pipeline operations (status/advance/blockers)
  store             Store submission management (submit/status/checklist)
  config            Project configuration
```

---

## 13. Quality & Audit System

### The 10 Game Quality Dimensions

| # | Dimension | Auditor Agent | Pass Threshold |
|---|-----------|---------------|---------------|
| 1 | **Gameplay Feel** | Playtest Simulator | ≥96 |
| 2 | **Visual Coherence** | Game Art Director | ≥96 |
| 3 | **Audio Fit** | Game Audio Director | ≥96 |
| 4 | **Narrative Flow** | Narrative Designer | ≥96 |
| 5 | **Economy Health** | Balance Auditor | ≥96 |
| 6 | **Performance** | Performance Engineer | ≥96 |
| 7 | **Accessibility** | Accessibility Auditor | ≥96 |
| 8 | **Fun Factor** | Playtest Simulator | ≥96 |
| 9 | **Technical Quality** | Quality Gate Reviewer | ≥96 |
| 10 | **Monetization Ethics** | Game Economist | ≥96 |

A game can only ship when **ALL 10 dimensions** score ≥96 on ALL major systems.

---

## 14. Build & Distribution System

### Cross-Platform Build Pipeline

1. **Pre-build checks**: Quality gates, asset validation, lint, tests
2. **Build**: `godot --headless --export` per platform target
3. **Smoke test**: Auto-launch, save/load, critical path, FPS check
4. **Package**: Platform-specific installers/archives
5. **Store prep**: Generate metadata, screenshots, descriptions per store

### Store Requirements

Each store has unique submission requirements (capsule images, age ratings, binary formats, review timelines). CGS-Game maintains a `store_requirements` table with per-store checklists and automated validation where possible.

---

## 15. Playtest & Balance System

### Bot Archetypes

| Archetype | What It Tests |
|-----------|---------------|
| **Speedrunner** | Critical path completion, main quest feasibility |
| **Completionist** | 100% completion, edge-case content |
| **Casual** | Core loop accessibility without optimization |
| **Grinder** | Economy exploits, farming loops |
| **Explorer** | Out-of-bounds, missing collision, empty areas |
| **Social** | Multiplayer stability, co-op balance |
| **Competitive** | PvP balance, dominant strategies |

### Economy Simulation

The Balance Auditor runs multi-day economy simulations answering: Can F2P players reach endgame? Are there dead-end build paths? Does the economy inflate? Are drop tables varied? Are there material bottlenecks?

---

## 16. Trope Addon System

### The 18 Tropes

Optional game mechanic modules that plug into the pipeline. Each adds agents, pipeline steps, and database tables. Dependencies enforced (e.g., Cooking requires Crafting, Taming requires Pets).

| # | Trope | Dependencies | Key Feature |
|---|-------|-------------|-------------|
| 1 | 🐾 Pets | None | Companion bonding, evolution, combat AI |
| 2 | 🔨 Crafting | None | Recipes, materials, workbenches |
| 3 | 🏠 Housing | None | Placement, room detection, furniture |
| 4 | 🌾 Farming | None | Crops, seasons, livestock |
| 5 | 🎣 Fishing | None | Cast/reel minigame, 200+ species |
| 6 | 🍳 Cooking | **Crafting** | Ingredients, buff potions |
| 7 | 🐴 Mounts | None | Riding, vehicle physics |
| 8 | 👥 Guilds | None | Clans, shared storage, events |
| 9 | 🏆 Achievements | None | Platform trophies, tracking |
| 10 | 💕 Romance | None | Affinity, gifts, dating events |
| 11 | 🌤️ Weather | None | Dynamic weather, time, NPC schedules |
| 12 | 📸 Photo Mode | None | Free camera, filters, poses |
| 13 | 👤 Customization | None | Character creator, transmog |
| 14 | ⚔️ Survival | None | Hunger, thirst, temperature |
| 15 | 🥚 Taming | **Pets** | Capture, genetics, breeding |
| 16 | 📋 Procedural Quests | None | Bounty boards, daily rotations |
| 17 | 💰 Trading | None | Auction house, NPC shops |
| 18 | 🎮 Minigames | None | Card games, puzzles, races |

---

## 17. Operational Rules

CGS-Game inherits ALL 39 operational rules from CGS (documented in `CGS-OPERATIONAL-RULES.md`) and adds 15 game-specific rules.

### Inherited Rules (Critical Subset)

| Rule | Name | CGS-Game Adaptation |
|------|------|---------------------|
| 0 | **STOP if tools are broken** | Applies equally — broken Docker container = broken tool |
| 1.1 | **Chunked writing for large docs** | GDD can be 100KB+ — chunking mandatory |
| 2.1 | **Never batch dispatches** | 25s stagger between dispatches |
| 2.2 | **Completion Mantra** | "I have X agents. I CAN have Y. I MUST dispatch Z NOW." |
| 2.3 | **Commit before ghosts can overwrite** | Every completion = immediate git commit |
| 4.1 | **Orchestrator decides pass/fail** | Auditor scores, system applies ≥96 threshold |
| 4.2 | **Stall detection** | 3 rounds within ±2pts → STALLED |
| 5.1 | **Strict deferral policy** | Deferrals verified against task dependency graph |
| 7.1 | **Agent limit is hard ceiling** | Never exceed max concurrent agents |
| 9.1 | **Verify disk, not dispatch count** | Count files on disk, not completion events |
| 10.1 | **Accuracy over speed** | Meticulous mode — verify every step |
| 12.2 | **Commit every completion** | No batching commits |
| 14.1 | **You are upper management** | Orchestrator decides and delegates, never implements |

### Game-Specific Rules (15 New)

#### Rule G1: Art Director's Style Guide Is Constitutional Law
**Rationale**: Visual coherence requires a single style authority. Every visual agent MUST read the style guide before producing any output. Art style (chibi, realistic, pixel, cel-shaded) comes from the Art Director — not from individual sculptors or renderers.
**Implementation**: `cgs-game.art.styleGuideRequired: true` — agents cannot be dispatched for visual tasks until a style guide exists and is referenced in their prompt.

#### Rule G2: Form Sculptors Produce Design Specs, Not Final Assets
**Rationale**: Sculptors define WHAT something looks like (form, proportions, anatomy). Media Pipeline Specialists handle the TECHNICAL pipeline for each output format. Don't merge these roles.
**Implementation**: Sculptor output is `design-spec.json` + `reference-sheet`, not `.glb` or `.png`. Media pipeline agents consume these specs.

#### Rule G3: Asset Dependencies Must Exist Before Work Begins
**Rationale**: You can't texture a model that doesn't exist. You can't animate a character without a skeleton. The asset dependency graph must be checked before dispatching.
**Implementation**: `asset.check_readiness()` is called automatically before dispatch. If deps aren't met, the task stays in PENDING.

#### Rule G4: Every Asset Gets Registered in the DB
**Rationale**: Unregistered assets are invisible to the dependency graph, validation system, and build pipeline. An asset that exists only on disk is a liability.
**Implementation**: Agent completion handler auto-registers produced assets via `asset.bulk_register()`. Unregistered files in `/assets/` are flagged by periodic scans.

#### Rule G5: Docker Containers Are Reusable, Not Disposable
**Rationale**: Starting a container with Blender takes 10-15 seconds. Starting 50 containers per hour wastes 8+ minutes. Warm containers reuse the existing process.
**Implementation**: `cgs-game.docker.containerTTL: 300` — containers stay alive 5 minutes after agent completes, available for the next agent of the same type.

#### Rule G6: Playtest Results Must Be Quantitative
**Rationale**: "The game feels good" is not actionable. "Input-to-action latency is 180ms (target: <100ms)" is. Playtest bots must produce metrics, not opinions.
**Implementation**: Playtest reports must populate `playtest_metrics` table with named metrics, numeric values, and units.

#### Rule G7: Economy Simulation Before Every Balance Change
**Rationale**: Changing a drop rate without simulating the downstream effects causes cascading balance issues. Every economy parameter change must be followed by a simulation run.
**Implementation**: Balance Auditor auto-dispatches economy simulation after any economy model change is detected.

#### Rule G8: Cross-Pipeline Dependencies Are First-Class Entities
**Rationale**: "The art pipeline is 80% done but the world pipeline can't start because it needs tilesets from art step 3" — these cross-pipeline blockers must be tracked, not discovered by accident.
**Implementation**: `pipeline_deps` table with `pipeline.cross_deps()` tool for visibility.

#### Rule G9: Trope Activation Is Irreversible After Implementation
**Rationale**: Once a trope's agents have produced artifacts and code, disabling the trope leaves orphaned assets and broken code references. Better to leave it enabled but deprioritized.
**Implementation**: If a trope has `pipeline_state` rows with status 'completed', disabling it requires `--force` and logs a warning about orphaned artifacts.

#### Rule G10: Build Every Platform Early and Often
**Rationale**: Discovering that the Android build fails at version 0.9 wastes weeks. Build all target platforms from the first working prototype.
**Implementation**: `cgs-game.build.autoTrigger: true` — build all platforms after every 10 code completions.

#### Rule G11: Store Requirements Checked Continuously, Not At Ship Time
**Rationale**: "Steam requires 5 screenshots at 1920x1080" is easy to satisfy early. Discovering it 2 hours before launch is panic-inducing.
**Implementation**: `store.get_readiness()` included in the `cgs-game status` output. Red items flagged continuously.

#### Rule G12: Audio and Art Pipelines Can Run Fully Parallel
**Rationale**: Audio doesn't depend on art, and art doesn't depend on audio. They both depend on the GDD and style/music guides. Serialize them and you waste half the available parallelism.
**Implementation**: Pipeline Engine explicitly allows Pipelines 3 (Art) and 4 (Audio) to run concurrently from step 1.

#### Rule G13: Narrative Must Complete Before Full Implementation
**Rationale**: You can implement combat mechanics without narrative, but you can't implement quest logic, dialogue trees, or cutscene triggers without the narrative pipeline's output. Block implementation of narrative-dependent tasks until the Narrative Pipeline completes.
**Implementation**: Pipeline 2 (Narrative) tasks are prerequisites for Pipeline 1 (Core) implementation tasks tagged `narrative-dependent`.

#### Rule G14: The Game Must Be Playable After Every Sprint
**Rationale**: A game that compiles but isn't playable provides no signal about quality, fun, or balance. After every batch of code completions, the game must be in a launchable state.
**Implementation**: Smoke test runs automatically after every build. Failures block further dispatches until resolved.

#### Rule G15: Mod Compatibility Is a Post-Launch Concern
**Rationale**: Don't design for mod support in v1.0. It adds complexity to every system. Plan for it (stable APIs, documented data formats) but don't implement until post-launch.
**Implementation**: Mod API and compatibility checks are in Pipeline 7 (Distribution) step 17 (Patch Manager), not in core implementation.

---

## 18. Monetization & Business Model

### CGS-Game Product Tiers

```
┌──────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    CGS-GAME OPEN SOURCE (FREE)                    │   │
│  │                                                                   │   │
│  │  • ACP server with full 122-tool MCP surface                     │   │
│  │  • CLI (init, status, dispatch, build, playtest, audit)          │   │
│  │  • All 87+ agent definitions (.agent.md files)                   │   │
│  │  • 9 pipeline definitions                                        │   │
│  │  • 10 quality dimensions                                         │   │
│  │  • SQLite state management                                       │   │
│  │  • Docker container definitions                                   │   │
│  │  • 18 trope addon definitions                                    │   │
│  │  • Single-agent dispatch (1 concurrent)                          │   │
│  │  • Basic terminal dashboard                                       │   │
│  │                                                                   │   │
│  │  → Enough to build a complete game with one agent at a time      │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                  CGS-GAME PRO ($29/month)                         │   │
│  │                                                                   │   │
│  │  Everything in Open Source, plus:                                 │   │
│  │  • Up to 5 concurrent agents                                     │   │
│  │  • Desktop app (Tauri) with full dashboard                       │   │
│  │  • Asset browser with thumbnails and metadata                    │   │
│  │  • Pipeline canvas visualization                                  │   │
│  │  • Build matrix dashboard                                         │   │
│  │  • Economy simulation visualization                               │   │
│  │  • Auto-cascade chains (sculptor → media pipeline)               │   │
│  │  • Multi-model routing (cost optimization)                       │   │
│  │  • Agent performance analytics                                    │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │               CGS-GAME STUDIO ($99/month)                         │   │
│  │                                                                   │   │
│  │  Everything in Pro, plus:                                         │   │
│  │  • Unlimited concurrent agents                                    │   │
│  │  • Multi-machine (Hub + Satellites with GPU agents)              │   │
│  │  • Team collaboration features                                    │   │
│  │  • Cross-project asset library (reuse assets between games)      │   │
│  │  • Custom agent creation tools                                    │   │
│  │  • Custom quality dimension definitions                           │   │
│  │  • Priority email support                                         │   │
│  │  • Advanced build pipeline (CI/CD integration)                   │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │              CGS-GAME PUBLISHER ($499/month)                      │   │
│  │                                                                   │   │
│  │  Everything in Studio, plus:                                      │   │
│  │  • Multi-game project management                                  │   │
│  │  • Publisher dashboard (all games at a glance)                    │   │
│  │  • Store submission automation                                    │   │
│  │  • Live ops automation (season pass, event management)           │   │
│  │  • White-label option (remove CGS-Game branding)                 │   │
│  │  • Custom agent development support                               │   │
│  │  • SLA with 24-hour response                                     │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────┘
```

### Marketplace for Game Dev

| Item Type | Examples | Revenue Model |
|-----------|---------|---------------|
| **Agent Packs** | "Pixel Art Specialist Pack" (5 agents optimized for pixel art) | $9.99 or subscription |
| **Trope Extensions** | "Dragon Taming Mega-Pack" (expanded taming with 50 dragon breeds) | $4.99 |
| **Style Presets** | "Pixel-Perfect SNES Style Guide" — Art Director preset with palette, proportions | Free / $2.99 |
| **Economy Templates** | "Balanced F2P Economy Model" — pre-tuned economy parameters | Free / $4.99 |
| **Pipeline Plugins** | "Console Certification Pipeline" — PS5/Xbox cert automation | $29.99 |
| **Docker Images** | "gamedev-ml" — ML tools for procedural generation | Free |

---

## 19. Migration Path

### From Current State to CGS-Game v1.0

The current game dev setup lives entirely within the EOIC repo as documentation artifacts (`neil-docs/game-dev/`). The migration path transforms these artifacts into a running platform:

#### Phase 0: Repository Setup (Week 1)

```
Create new repository: github.com/org/cgs-game
├── src/
│   ├── acp-server/          ← MCP server (Node.js)
│   ├── cli/                  ← CLI tool
│   ├── desktop/              ← Tauri desktop app
│   └── dashboard/            ← Web dashboard
├── docker/
│   ├── gamedev-base/         ← Dockerfile
│   ├── gamedev-2d/
│   ├── gamedev-3d/
│   ├── gamedev-audio/
│   ├── gamedev-engine/
│   └── gamedev-full/
├── agents/                   ← 87+ .agent.md files (migrated)
├── pipelines/                ← workflow-pipelines.json (migrated)
├── templates/                ← Prompt templates
├── tests/
└── docs/
```

#### Phase 1: Core Infrastructure (Weeks 2-4)

1. **SQLite database schema** — Create all 26 tables from Section 4
2. **ACP server** — Implement first 40 tools (project, agent, pipeline, asset domains)
3. **CLI foundation** — `init`, `status`, basic `dispatch`
4. **Agent registry** — Import all 87 agents from `agent-registry.json`
5. **Pipeline engine** — Basic sequential pipeline with gate checks

#### Phase 2: Docker & Containers (Weeks 5-6)

1. **Build all 6 Docker images** — From existing Dockerfiles in `THIRD-PARTY-TOOLS.md`
2. **Docker Manager** — Container selection, lifecycle, volume mounts
3. **Shared cache volume** — Pre-installed tools shared across containers
4. **Agent ↔ Container mapping** — Automated selection based on agent type

#### Phase 3: Full MCP Surface (Weeks 7-10)

1. **Remaining 80 tools** — Build, quality, trope, playtest, store, patch, analytics, docker domains
2. **Asset dependency graph engine** — DAG resolution, cycle detection, readiness checks
3. **Prompt template engine** — Context injection with game-specific data
4. **Model router** — Task → AI model routing with cost optimization

#### Phase 4: Convergence & Automation (Weeks 11-12)

1. **Convergence engine** — Audit → fix → re-audit loops with stall detection
2. **Auto-cascade chains** — Sculptor → media pipeline auto-dispatch
3. **Playtest automation** — Bot dispatch, metric collection, economy simulation
4. **Cross-pipeline dependency enforcement** — Block downstream until upstream completes

#### Phase 5: Dashboard & Desktop App (Weeks 13-16)

1. **Web dashboard** — Pipeline canvas, agent pool, asset browser, build matrix
2. **Desktop app (Tauri)** — Full desktop experience with all panels
3. **WebSocket real-time updates** — Push state changes to all connected clients
4. **Trope toggle panel** — Enable/disable with dependency warnings

#### Phase 6: Distribution Pipeline (Weeks 17-18)

1. **Build system** — Cross-platform build via Godot CLI
2. **Store submission tools** — Requirements checklists, metadata generation
3. **Patch management** — Delta manifests, save migration, rollback
4. **Smoke testing** — Automated post-build validation

#### Phase 7: Polish & Testing (Weeks 19-20)

1. **End-to-end test** — Build a complete toy game using CGS-Game
2. **Performance testing** — 500+ assets, 9 pipelines, 5 concurrent agents
3. **Documentation** — User guide, API reference, contribution guide
4. **Dogfooding** — Use CGS-Game to build a real game project

### Migration of Existing Artifacts

| Current Artifact | Current Location | Migration Target |
|-----------------|-----------------|-----------------|
| 87+ .agent.md files | `neil-docs/game-dev/.github/agents/` | `cgs-game/agents/` |
| agent-registry.json | `neil-docs/game-dev/.github/agents/` | Imported into `agent_registry` table |
| workflow-pipelines.json | `neil-docs/game-dev/.github/agents/` | Imported into `pipeline_defs` + `pipeline_steps` tables |
| GAME-DEV-VISION.md | `neil-docs/game-dev/` | `cgs-game/docs/vision.md` (historical reference) |
| HOW-IT-ALL-WORKS.md | `neil-docs/game-dev/` | `cgs-game/docs/how-it-works.md` |
| THIRD-PARTY-TOOLS.md | `neil-docs/game-dev/` | `cgs-game/docker/README.md` + Dockerfiles |
| CGS-GAME-VISION.md (this doc) | `neil-docs/game-dev/` | `cgs-game/docs/CGS-GAME-VISION.md` (this is the EPIC-BRIEF) |

---

## 20. Decomposition Hints

### Recommended Epic Breakdown

This vision document should be decomposed into **8 implementation epics**, each independently deliverable:

| Epic | Name | Estimated Tasks | Depends On |
|------|------|----------------|------------|
| **E1** | Core Infrastructure | ~45 tasks | — |
| **E2** | Docker & Container System | ~20 tasks | E1 |
| **E3** | Full MCP Tool Surface | ~60 tasks | E1 |
| **E4** | Pipeline Engine & Dependencies | ~30 tasks | E1, E3 |
| **E5** | Asset Management & Dependency Graph | ~25 tasks | E1, E3 |
| **E6** | Convergence, Automation & Playtest | ~25 tasks | E3, E4 |
| **E7** | Dashboard & Desktop App | ~40 tasks | E3 |
| **E8** | Distribution, Build & Store | ~25 tasks | E3, E4 |

**Total estimated tasks: ~270**
**Estimated Fibonacci points: ~800-1,200**

### Epic 1: Core Infrastructure (Foundation)

```
E1 — Core Infrastructure (~45 tasks)
├── SQLite schema creation (26 tables, indexes, FTS)
├── ACP server skeleton (MCP protocol, tool registration)
├── Project management tools (create, configure, set_active, get_status)
├── Agent dispatch tools (dispatch_next, complete, crash, get_running)
├── CLI skeleton (init, status)
├── Session state management
├── Activity logging
├── Convention management
├── Git integration (auto-commit on completion)
└── Basic prompt template engine
```

### Epic 2: Docker & Containers

```
E2 — Docker & Container System (~20 tasks)
├── Dockerfiles for all 6 container tiers
├── Docker Manager (start, stop, health, cleanup)
├── Container selection logic (agent → image mapping)
├── Volume mount configuration
├── Shared asset cache
├── Container health monitoring
├── Container reuse / warm pool
├── Docker MCP tools (8 tools)
└── requirements-gamedev.txt and tool validation script
```

### Epic 3: Full MCP Surface

```
E3 — Full MCP Tool Surface (~60 tasks)
├── Pipeline tools (12 tools)
├── Asset tools (14 tools)
├── Build tools (10 tools)
├── Quality/audit tools (12 tools)
├── Trope tools (8 tools)
├── Playtest tools (10 tools)
├── Store tools (8 tools)
├── Patch tools (8 tools)
├── Analytics tools (10 tools)
└── Each tool: implementation + tests + documentation
```

### Epic 4: Pipeline Engine

```
E4 — Pipeline Engine & Dependencies (~30 tasks)
├── Pipeline state machine implementation
├── 9 pipeline definitions with step ordering
├── Cross-pipeline dependency table and checks
├── Gate check logic (dependency satisfaction)
├── Critical path computation
├── Priority scoring for dispatch
├── Pipeline advancement automation
├── Cross-pipeline blocker detection
├── Pipeline history and activity logging
└── Pipeline velocity and ETA estimation
```

### Implementation Order

```
E1 ──→ E2 (Docker needs core infra)
  │
  ├──→ E3 (Tools need core DB/server)
  │     │
  │     ├──→ E4 (Pipeline engine uses tools)
  │     │     │
  │     │     └──→ E6 (Convergence uses pipelines)
  │     │
  │     ├──→ E5 (Asset management uses tools)
  │     │
  │     ├──→ E7 (Dashboard queries tools)
  │     │
  │     └──→ E8 (Build/store uses tools + pipelines)
  │
  └──→ E7 can start early (dashboard framework while tools are built)
```

### Using CGS to Build CGS-Game

The ultimate dogfooding: use CGS (the enterprise orchestration platform) to orchestrate the building of CGS-Game (the game dev orchestration platform).

```
CGS Orchestrator
├── Register project: "CGS-Game" in CGS's multi-project system
├── Import this EPIC-BRIEF as the vision document
├── Run The Decomposer on each of the 8 epics
├── Run The Aggregator to produce the Master Task Matrix
├── Run the 4-Pass Blind Ticket Pipeline on all ~270 tasks
├── Run Implementation Plan Builder on each ticket
├── Run Implementation Executor with convergence (95+ to pass)
└── Ship CGS-Game v1.0
```

---

## 21. Risk Inventory

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|------------|
| R1 | **Docker complexity** — Users without Docker can't use containerized agents | High | High | Provide non-Docker fallback (local tool installation scripts). Docker is optional enhancement. |
| R2 | **Large asset files** — Git doesn't handle binary assets well | High | Medium | Git LFS integration mandatory from day 1. `.gitattributes` configured at `init`. |
| R3 | **AI model cost** — Running 87 agents is expensive | High | Medium | Model router prioritizes cheap/local models. Ollama for local GPU. Most agents don't need opus-tier. |
| R4 | **Godot lock-in** — Tight coupling to Godot 4 | Medium | High | Abstract engine interactions through scripts. Core platform is engine-agnostic; only `gamedev-engine` container and Code Executor are Godot-specific. |
| R5 | **Asset quality** — AI-generated assets may not meet professional standards | High | High | Convergence engine with human review option. Assets go through 'review' stage before 'approved'. Style guide enforcement. |
| R6 | **Pipeline complexity** — 9 parallel pipelines with cross-dependencies is complex to manage | Medium | High | Extensive automated testing. Pipeline state machine has clear states. Cross-dep table with validation queries. |
| R7 | **Trope interaction bugs** — Enabling 10+ tropes may create unexpected interactions | Medium | Medium | Trope dependency table catches known conflicts. Comprehensive playtest after trope changes. |
| R8 | **Blender/tool updates** — CLI interfaces change between versions | Low | High | Pin tool versions in Dockerfiles. Test containers against CI on tool version updates. |
| R9 | **Playtest bot accuracy** — AI bots may not play like real humans | High | Medium | Multiple bot archetypes with different strategies. Bot behavior tunable. Supplement with real playtesting. |
| R10 | **Store submission failures** — Each store has unique, changing requirements | Medium | Medium | `store_requirements` table maintained as living document. Automated checks where APIs exist. |
| R11 | **Scope creep** — 87+ agents × 18 tropes × 9 pipelines is enormous scope | High | High | Phased delivery. E1-E4 deliver a working core without tropes, dashboard, or stores. MVP = core pipeline + CLI. |
| R12 | **Audio generation quality** — SuperCollider output may sound synthetic | High | Medium | Position generated audio as placeholder/prototype. Support importing professionally created audio. |

---

## 22. Appendices

### Appendix A: Full Agent → Pipeline × Container Matrix

| Agent | Category | Pipeline(s) | Container | Model Tier |
|-------|----------|-------------|-----------|------------|
| Game Vision Architect | Vision | 1 | gamedev-base | opus |
| Narrative Designer | Vision | 1, 2 | gamedev-base | opus |
| Character Designer | Vision | 1, 2 | gamedev-base | sonnet |
| World Cartographer | Vision | 1, 5 | gamedev-base | sonnet |
| Game Economist | Vision | 1, 6 | gamedev-base | sonnet |
| Game Art Director | Vision | 1, 3 | gamedev-base | opus |
| Game Audio Director | Vision | 1, 4 | gamedev-base | opus |
| Humanoid Character Sculptor | Sculptor | 3 | gamedev-3d | sonnet |
| Beast & Creature Sculptor | Sculptor | 3 | gamedev-3d | sonnet |
| Eldritch Horror Sculptor | Sculptor | 3 | gamedev-3d | sonnet |
| Undead & Spectral Sculptor | Sculptor | 3 | gamedev-3d | sonnet |
| Mechanical & Construct Sculptor | Sculptor | 3 | gamedev-3d | sonnet |
| Mythic & Divine Sculptor | Sculptor | 3 | gamedev-3d | sonnet |
| Flora & Organic Sculptor | Sculptor | 3 | gamedev-3d | sonnet |
| Aquatic & Marine Sculptor | Sculptor | 3 | gamedev-3d | sonnet |
| Architecture & Interior Sculptor | Sculptor | 3 | gamedev-3d | sonnet |
| Weapon & Equipment Forger | Sculptor | 3 | gamedev-3d | sonnet |
| Terrain & Environment Sculptor | Sculptor | 3, 5 | gamedev-3d | sonnet |
| 2D Asset Renderer | Media | 3 | gamedev-2d | sonnet |
| 3D Asset Pipeline Specialist | Media | 3 | gamedev-3d | sonnet |
| VR XR Asset Optimizer | Media | 3 | gamedev-3d | sonnet |
| Texture & Material Artist | Media | 3 | gamedev-3d | sonnet |
| Procedural Asset Generator | Assembly | 3 | gamedev-3d | sonnet |
| Scene Compositor | Assembly | 3, 5 | gamedev-full | sonnet |
| Sprite Sheet Generator | Assembly | 3 | gamedev-2d | haiku |
| Animation Sequencer | Assembly | 3 | gamedev-2d | sonnet |
| Tilemap Level Designer | Assembly | 3, 5 | gamedev-engine | sonnet |
| Audio Composer | Assembly | 4 | gamedev-audio | sonnet |
| VFX Designer | Assembly | 3 | gamedev-engine | sonnet |
| Game Code Executor | Implementation | 1 | gamedev-engine | sonnet |
| AI Behavior Designer | Implementation | 1 | gamedev-engine | sonnet |
| Combat System Builder | Implementation | 1 | gamedev-engine | sonnet |
| Dialogue Engine Builder | Implementation | 1, 2 | gamedev-engine | sonnet |
| Multiplayer Network Builder | Implementation | 1 | gamedev-engine | opus |
| Game UI Designer | Implementation | 1, 3 | gamedev-engine | sonnet |
| Game HUD Engineer | Implementation | 1, 3 | gamedev-engine | sonnet |
| Camera System Architect | Camera | 8 | gamedev-engine | sonnet |
| Cinematic Director | Camera | 8 | gamedev-engine | opus |
| Playtest Simulator | Quality | 6 | gamedev-engine | sonnet |
| Balance Auditor | Quality | 6 | gamedev-engine | opus |
| Game Analytics Designer | Quality | 1, 6 | gamedev-engine | sonnet |
| Accessibility Auditor | Quality | 1 | gamedev-base | sonnet |
| Quality Gate Reviewer | Quality | 1 | gamedev-base | opus |
| Code Style Enforcer | Quality | 1 | gamedev-engine | haiku |
| Game Build & Packaging | Distribution | 7 | gamedev-engine | sonnet |
| Store Submission Specialist | Distribution | 7 | gamedev-base | sonnet |
| Demo & Showcase Builder | Distribution | 7 | gamedev-full | sonnet |
| Localization Manager | Distribution | 7 | gamedev-base | sonnet |
| Compliance Officer | Distribution | 7 | gamedev-base | sonnet |
| Release Manager | Distribution | 7 | gamedev-base | sonnet |
| Live Ops Designer | Distribution | 7 | gamedev-base | sonnet |
| Patch & Update Manager | Distribution | 7 | gamedev-base | sonnet |
| The Decomposer | Infrastructure | 1 | gamedev-base | opus |
| The Aggregator | Infrastructure | 1 | gamedev-base | opus |
| Reconciliation Specialist | Infrastructure | 1 | gamedev-base | opus |
| Game Ticket Writer | Infrastructure | 1 | gamedev-base | opus |
| Implementation Plan Builder | Infrastructure | 1 | gamedev-base | opus |
| Game Orchestrator | Infrastructure | ALL | gamedev-full | opus |
| Documentation Writer | Infrastructure | ALL | gamedev-base | sonnet |
| The Artificer | Infrastructure | ALL | gamedev-base | opus |

*Plus 18 Trope Addon agents (all use gamedev-engine container, sonnet model tier)*

### Appendix B: Quality Dimension × Auditor Agent Matrix

| Dimension | Primary Auditor | Secondary Auditor | Convergence Target |
|-----------|----------------|-------------------|-------------------|
| Gameplay Feel | Playtest Simulator | Combat System Builder | 96 |
| Visual Coherence | Game Art Director | Quality Gate Reviewer | 96 |
| Audio Fit | Game Audio Director | Audio Composer | 96 |
| Narrative Flow | Narrative Designer | Quality Gate Reviewer | 96 |
| Economy Health | Balance Auditor | Game Economist | 96 |
| Performance | Performance Engineer | Game Build Specialist | 96 |
| Accessibility | Accessibility Auditor | Game UI Designer | 96 |
| Fun Factor | Playtest Simulator | Balance Auditor | 96 |
| Technical Quality | Quality Gate Reviewer | Code Style Enforcer | 96 |
| Monetization Ethics | Game Economist | Compliance Officer | 96 |

### Appendix C: Default Store Requirements (Steam)

| Category | Requirement | Automated Check? |
|----------|------------|-----------------|
| Metadata | App name (≤ 30 chars recommended) | ✅ |
| Metadata | Short description (≤ 300 chars) | ✅ |
| Metadata | Long description (HTML, ≤ 20,000 chars) | ✅ |
| Metadata | System requirements (min + recommended) | ⬜ Manual |
| Assets | Header capsule (460×215 PNG) | ✅ File dims check |
| Assets | Small capsule (231×87 PNG) | ✅ |
| Assets | Main capsule (616×353 PNG) | ✅ |
| Assets | Page background (1438×810 PNG) | ✅ |
| Assets | Library hero (3840×1240 PNG) | ✅ |
| Assets | Library logo (1280×720 PNG) | ✅ |
| Assets | Min 5 screenshots (1920×1080) | ✅ Count + dims |
| Assets | Trailer (YouTube, ≤ 3 min recommended) | ⬜ Manual |
| Technical | Windows .exe (signed recommended) | ✅ File exists |
| Technical | Steamworks SDK integrated | ⬜ Manual |
| Technical | Cloud save support (if applicable) | ⬜ Manual |
| Legal | EULA (or use Steam default) | ✅ File exists |
| Legal | Privacy policy URL | ✅ URL format check |
| Content | Self-rated content descriptors | ⬜ Manual |
| Content | No illegal content | ⬜ Manual (human review) |
| Financial | Pricing set in Steamworks | ⬜ Manual |
| Financial | Revenue share agreement signed | ⬜ Manual |

---

## Summary

CGS-Game is a **standalone, purpose-built AI agent orchestration platform** for video game development. It is NOT a fork of CGS — it is a new product inspired by CGS's battle-tested architecture, designed from scratch for the unique demands of game creation.

### The Key Numbers

| What | Count |
|------|-------|
| AI Agents | 87+ across 11 categories |
| Pipelines | 9 parallel creation streams |
| MCP Tools | 122 across 12 domains |
| Database Tables | 26 + FTS |
| Quality Dimensions | 10 game-specific |
| Docker Containers | 6 tiered environments |
| Trope Addons | 18 optional modules |
| Operational Rules | 39 inherited + 15 game-specific = 54 |
| Platform Targets | 6 (Windows, macOS, Linux, Web, Android, iOS) + consoles |
| Store Targets | 9 (Steam, Epic, itch.io, GOG, App Store, Google Play, Nintendo, PS, Xbox) |
| Estimated Tasks | ~270 across 8 epics |
| Estimated Timeline | ~20 weeks to v1.0 |

### The One-Line Vision

> **CGS-Game: Type one sentence. Get a shipped game.**

---

*Document version: 1.0.0 | Created: 2026-07-28 | Author: Idea Architect Agent*
*This document serves as the EPIC-BRIEF for the CGS-Game platform.*
*Next step: Hand to The Decomposer for task decomposition into 8 epics.*
