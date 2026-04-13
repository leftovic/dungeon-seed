# Decomposition: CGS-Game — AI Agent Orchestration Platform for Game Development

> **Decomposed by**: The Decomposer (the-decomposer)
> **Date**: 2026-07-28
> **Input**: `neil-docs/game-dev/CGS-GAME-VISION.md` (2,879 lines, ~178KB)
> **Target Repo(s)**: `github.com/org/cgs-game` (new greenfield repository)
> **Total Tasks**: 198
> **Total Complexity**: 836 Fibonacci points
> **Waves**: 24
> **Critical Path**: 38 tasks (184 points) — E1.01→E1.02→E1.05→E1.08→E1.12→E1.13→E3.01→E3.02→E3.04→E3.05→E3.06→E4.01→E4.02→E4.04→E4.05→E4.06→E4.09→E4.11→E5.01→E5.02→E5.04→E5.05→E6.01→E6.02→E6.04→E6.06→E6.08→E8.01→E8.02→E8.05→E8.06→E7.01→E7.03→E7.06→E7.09→V.01→V.02→V.04
> **Epics**: 8 implementation epics + 1 verification epic
> **Constraint**: Every task ≤ 8 story points (junior-developer-sized)

---

## Epic Summary

CGS-Game is a standalone, greenfield AI agent orchestration platform purpose-built for video game development. It manages the full game creation lifecycle — from a one-sentence pitch to a shipped, multi-platform, store-certified, live-operated game — by orchestrating 87+ specialized AI agents across 9 parallel pipelines.

This decomposition breaks the 178KB vision document into 198 implementable tasks across 8 epics, organized into 24 execution waves. The architecture spans: an ACP server exposing ~122 MCP tools via Node.js + better-sqlite3, a 9-pipeline orchestration engine with cross-pipeline dependency graphs, an asset management system with DAG-based dependency tracking, Docker container integration for 6 tool-tier environments, a convergence engine for quality gate enforcement, a web dashboard + Tauri desktop app, a CLI, and a cross-platform build/distribution system targeting 9 store fronts.

Every task is ≤8 story points, independently compilable, testable, and reviewable. Infrastructure comes before consumers. Models come before logic. Shared utilities come before domain-specific features.

---

## Epic Registry

| Epic | Name | Tasks | Points | Waves | Dependencies |
|------|------|-------|--------|-------|-------------|
| **E1** | Core Infrastructure | 30 | 128 | 1–6 | — |
| **E2** | Docker & Container System | 18 | 76 | 5–9 | E1 (partial) |
| **E3** | MCP Tool Surface (Domains 3–12) | 40 | 170 | 7–14 | E1 |
| **E4** | Pipeline Engine & Dependencies | 26 | 116 | 10–16 | E1, E3 (partial) |
| **E5** | Asset Management & Dependency Graph | 22 | 92 | 12–17 | E1, E3 (partial) |
| **E6** | Convergence, Automation & Playtest | 20 | 82 | 15–19 | E3, E4 |
| **E7** | Dashboard & Desktop App | 22 | 88 | 16–22 | E3 |
| **E8** | Distribution, Build & Store | 16 | 64 | 17–22 | E3, E4 |
| **V** | Verification & End-to-End | 4 | 20 | 23–24 | ALL |
| | **TOTALS** | **198** | **836** | **24** | |

---

## Task Registry (All 198 Tasks)

### Epic 1: Core Infrastructure (30 tasks, 128 pts)

| # | Task Name | Pts | Dependencies | Wave | Critical Path? |
|---|-----------|-----|-------------|------|----------------|
| E1.01 | Repository scaffolding & project structure | 3 | — | 1 | ✅ |
| E1.02 | SQLite database bootstrap module & WAL config | 5 | E1.01 | 2 | ✅ |
| E1.03 | Core tables: game_projects, session_state, activity_log | 5 | E1.02 | 3 | ❌ |
| E1.04 | Agent tables: agent_registry, active_agents, dispatches | 5 | E1.02 | 3 | ❌ |
| E1.05 | Prompt tables: prompt_templates, conventions | 3 | E1.02 | 3 | ✅ |
| E1.06 | FTS5 virtual table for asset search | 3 | E1.02 | 3 | ❌ |
| E1.07 | Index creation for all 17 performance indexes | 3 | E1.03, E1.04 | 4 | ❌ |
| E1.08 | ACP server skeleton: MCP protocol, tool registration framework | 8 | E1.05 | 4 | ✅ |
| E1.09 | project.create — Create new game project with defaults | 5 | E1.08 | 5 | ❌ |
| E1.10 | project.configure — Update project settings | 3 | E1.09 | 5 | ❌ |
| E1.11 | project.set_active & project.list | 3 | E1.09 | 5 | ❌ |
| E1.12 | project.get_status — Full project dashboard query | 5 | E1.09 | 5 | ✅ |
| E1.13 | agent.dispatch_next — Priority-aware dispatch engine | 8 | E1.12 | 6 | ✅ |
| E1.14 | agent.dispatch — Dispatch specific agent to specific task | 5 | E1.08, E1.04 | 5 | ❌ |
| E1.15 | agent.complete — Mark agent completed with results | 5 | E1.14 | 6 | ❌ |
| E1.16 | agent.crash — Mark crashed, reset task to pending | 3 | E1.14 | 6 | ❌ |
| E1.17 | agent.get_running — List running agents with timing | 3 | E1.14 | 6 | ❌ |
| E1.18 | agent.health_check — Stale agent detection | 3 | E1.17 | 6 | ❌ |
| E1.19 | agent.crash_recovery — Reset all orphaned agents | 3 | E1.18 | 6 | ❌ |
| E1.20 | agent.get_capacity — Slot utilization metrics | 3 | E1.17 | 6 | ❌ |
| E1.21 | agent.fill_slots — Priority-aware batch dispatch | 5 | E1.13 | 6 | ❌ |
| E1.22 | agent.list_registry — List agents by category | 3 | E1.08, E1.04 | 5 | ❌ |
| E1.23 | agent.performance_stats — Avg time, pass rate, crash rate | 3 | E1.15 | 6 | ❌ |
| E1.24 | Session state management: get/set/snapshot | 5 | E1.08, E1.03 | 5 | ❌ |
| E1.25 | Activity logging: insert + query with filters | 3 | E1.08, E1.03 | 5 | ❌ |
| E1.26 | Convention management: CRUD + query by category | 3 | E1.08, E1.05 | 5 | ❌ |
| E1.27 | Git integration: auto-commit on agent completion | 5 | E1.15 | 6 | ❌ |
| E1.28 | Prompt template engine: load, interpolate, override chain | 5 | E1.05, E1.08 | 5 | ❌ |
| E1.29 | agent.get_prompt — Generate dispatch prompt with context injection | 5 | E1.28 | 6 | ❌ |
| E1.30 | agent.update_prompt_template — DB-backed template CRUD | 3 | E1.28 | 6 | ❌ |

### Epic 2: Docker & Container System (18 tasks, 76 pts)

| # | Task Name | Pts | Dependencies | Wave | Critical Path? |
|---|-----------|-----|-------------|------|----------------|
| E2.01 | Dockerfile: gamedev-base (Python, Node, ImageMagick, ffmpeg, sox, Git) | 5 | E1.01 | 5 | ❌ |
| E2.02 | Dockerfile: gamedev-2d (+ Aseprite CLI, Inkscape, Tiled, GIMP CLI) | 5 | E2.01 | 6 | ❌ |
| E2.03 | Dockerfile: gamedev-3d (+ Blender 4.x, glTF tools, meshoptimizer) | 5 | E2.01 | 6 | ❌ |
| E2.04 | Dockerfile: gamedev-audio (+ SuperCollider, LMMS, pydub) | 5 | E2.01 | 6 | ❌ |
| E2.05 | Dockerfile: gamedev-engine (+ Godot 4.x headless, gdtoolkit) | 5 | E2.01 | 6 | ❌ |
| E2.06 | Dockerfile: gamedev-full (all tools combined) | 5 | E2.02, E2.03, E2.04, E2.05 | 7 | ❌ |
| E2.07 | Docker containers DB table creation | 3 | E1.02 | 5 | ❌ |
| E2.08 | Docker Manager: container lifecycle (start, stop, remove) | 5 | E2.07, E1.08 | 7 | ❌ |
| E2.09 | Docker Manager: container selection (agent_type → image mapping) | 3 | E2.08 | 8 | ❌ |
| E2.10 | Docker Manager: volume mount configuration | 3 | E2.08 | 8 | ❌ |
| E2.11 | Docker Manager: health monitoring (CPU, memory, status) | 3 | E2.08 | 8 | ❌ |
| E2.12 | Docker Manager: warm pool & container reuse (TTL-based) | 5 | E2.08 | 8 | ❌ |
| E2.13 | Shared asset cache volume setup | 3 | E2.10 | 9 | ❌ |
| E2.14 | docker.container_for — Recommend container for agent type | 3 | E2.09 | 9 | ❌ |
| E2.15 | docker.start & docker.stop — MCP tools | 3 | E2.08 | 8 | ❌ |
| E2.16 | docker.health & docker.list — MCP tools | 3 | E2.11 | 9 | ❌ |
| E2.17 | docker.image_status & docker.cleanup — MCP tools | 3 | E2.08 | 9 | ❌ |
| E2.18 | docker.volume_mount — MCP tool | 3 | E2.10 | 9 | ❌ |

### Epic 3: MCP Tool Surface — Domains 3–12 (40 tasks, 170 pts)

| # | Task Name | Pts | Dependencies | Wave | Critical Path? |
|---|-----------|-----|-------------|------|----------------|
| **Pipeline Tools (Domain 3)** | | | | | |
| E3.01 | Pipeline tables: pipeline_defs, pipeline_steps, pipeline_state | 5 | E1.02 | 7 | ✅ |
| E3.02 | pipeline.list — All 9 pipelines with completion % | 3 | E3.01, E1.08 | 8 | ✅ |
| E3.03 | pipeline.status — Detailed per-step progress for one pipeline | 5 | E3.02 | 9 | ❌ |
| E3.04 | pipeline.advance — Advance to next step with gate check | 5 | E3.02 | 9 | ✅ |
| E3.05 | pipeline.gate_check — Prerequisite satisfaction check | 5 | E3.04 | 10 | ✅ |
| E3.06 | pipeline.history & pipeline.reset_step & pipeline.skip_step | 5 | E3.04 | 10 | ✅ |
| E3.07 | pipeline.parallel_status — 9-pipeline side-by-side view | 3 | E3.02 | 9 | ❌ |
| E3.08 | pipeline.estimate_completion — ETA from throughput | 3 | E3.02 | 9 | ❌ |
| **Asset Tools (Domain 4)** | | | | | |
| E3.09 | Asset tables: assets, asset_metadata, asset_deps | 5 | E1.02 | 7 | ❌ |
| E3.10 | asset.register — Register new asset with metadata | 5 | E3.09, E1.08 | 8 | ❌ |
| E3.11 | asset.query — Filter by type, category, status, tags | 5 | E3.10 | 9 | ❌ |
| E3.12 | asset.search — FTS5 full-text search | 3 | E3.10, E1.06 | 9 | ❌ |
| E3.13 | asset.get & asset.update_status — Detail + lifecycle transitions | 3 | E3.10 | 9 | ❌ |
| E3.14 | asset.validate — Type-specific validation rules | 5 | E3.10 | 9 | ❌ |
| E3.15 | asset.bulk_register & asset.get_stats & asset.generate_manifest | 5 | E3.10 | 9 | ❌ |
| **Build Tools (Domain 5)** | | | | | |
| E3.16 | Build tables: builds, build_platforms | 5 | E1.02 | 7 | ❌ |
| E3.17 | build.trigger — Trigger build for specified platforms | 5 | E3.16, E1.08 | 8 | ❌ |
| E3.18 | build.status & build.get_matrix — Build status + cross-platform matrix | 5 | E3.17 | 9 | ❌ |
| E3.19 | build.get_latest & build.get_history & build.get_size_trend | 3 | E3.17 | 9 | ❌ |
| E3.20 | build.platform_cert & build.promote & build.cancel | 5 | E3.17 | 9 | ❌ |
| E3.21 | build.smoke_test — Trigger smoke tests on build | 3 | E3.17 | 9 | ❌ |
| **Quality/Audit Tools (Domain 6)** | | | | | |
| E3.22 | Audit tables: audit_scores, audit_findings | 5 | E1.02 | 7 | ❌ |
| E3.23 | audit.score — Record quality score for target × dimension | 3 | E3.22, E1.08 | 8 | ❌ |
| E3.24 | audit.get_scoreboard & audit.get_trend | 5 | E3.23 | 9 | ❌ |
| E3.25 | audit.get_remediation_queue & audit.convergence_status | 5 | E3.23 | 9 | ❌ |
| E3.26 | audit.import_report & audit.get_findings & audit.resolve_finding | 5 | E3.23 | 9 | ❌ |
| E3.27 | audit.stall_check & audit.dimension_summary & audit.get_all_dimensions | 5 | E3.23 | 9 | ❌ |
| **Trope Tools (Domain 7)** | | | | | |
| E3.28 | Trope tables: trope_config, trope_deps | 3 | E1.02 | 7 | ❌ |
| E3.29 | trope.enable & trope.disable — with dependency enforcement | 5 | E3.28, E1.08 | 8 | ❌ |
| E3.30 | trope.list & trope.get_config & trope.update_config | 3 | E3.29 | 9 | ❌ |
| E3.31 | trope.dep_check & trope.get_agents & trope.bulk_enable | 5 | E3.29 | 9 | ❌ |
| **Playtest & Economy Tools (Domain 8)** | | | | | |
| E3.32 | Playtest tables: playtest_runs, playtest_metrics | 5 | E1.02 | 7 | ❌ |
| E3.33 | Economy table: economy_snapshots | 3 | E1.02 | 7 | ❌ |
| E3.34 | playtest.run & playtest.get_results & playtest.get_latest | 5 | E3.32, E1.08 | 8 | ❌ |
| E3.35 | playtest.get_metrics & playtest.compare & playtest.schedule | 5 | E3.34 | 9 | ❌ |
| E3.36 | playtest.get_softlocks & playtest.get_exploits | 3 | E3.34 | 9 | ❌ |
| E3.37 | economy.simulate & economy.get_health | 5 | E3.33, E1.08 | 8 | ❌ |
| **Store & Patch & Analytics (Domains 9, 11, 12)** | | | | | |
| E3.38 | Store tables: store_submissions, store_requirements | 5 | E1.02 | 7 | ❌ |
| E3.39 | Patch tables: patches, patch_assets | 3 | E1.02 | 7 | ❌ |
| E3.40 | analytics.throughput & analytics.pass_rate & analytics.agent_performance | 5 | E1.08, E1.15 | 8 | ❌ |

### Epic 4: Pipeline Engine & Dependencies (26 tasks, 116 pts)

| # | Task Name | Pts | Dependencies | Wave | Critical Path? |
|---|-----------|-----|-------------|------|----------------|
| E4.01 | Pipeline state machine: PENDING→READY→RUNNING→PASSED/COND/FAIL→COMPLETED | 5 | E3.01 | 10 | ✅ |
| E4.02 | 9 pipeline definitions seed data (JSON + DB insert) | 5 | E4.01 | 11 | ✅ |
| E4.03 | Pipeline 1: Core Game Loop — step definitions & ordering | 5 | E4.02 | 12 | ❌ |
| E4.04 | Pipeline 2: Narrative — step definitions & agent assignments | 3 | E4.02 | 12 | ✅ |
| E4.05 | Pipeline 3: Art — step definitions (sculptors → media → assembly) | 5 | E4.02 | 12 | ✅ |
| E4.06 | Pipeline 4: Audio — step definitions (direction → compose → SFX → integrate) | 3 | E4.02 | 12 | ✅ |
| E4.07 | Pipeline 5: World — step definitions (map → terrain → biomes → scenes) | 3 | E4.02 | 12 | ❌ |
| E4.08 | Pipeline 6: Economy — step definitions (model → drop tables → balance → simulate) | 3 | E4.02 | 12 | ❌ |
| E4.09 | Pipeline 7: Distribution — step definitions (build → package → submit → launch) | 3 | E4.02 | 12 | ✅ |
| E4.10 | Pipeline 8: Camera/Cinematic — step definitions | 3 | E4.02 | 12 | ❌ |
| E4.11 | Pipeline 9: Trope Addons — dynamic step generation from enabled tropes | 5 | E4.02, E3.29 | 13 | ✅ |
| E4.12 | Cross-pipeline dependency table: pipeline_deps | 3 | E3.01 | 10 | ❌ |
| E4.13 | Seed cross-pipeline dependency data (13+ dependency rules from vision) | 5 | E4.12, E4.03 | 13 | ❌ |
| E4.14 | pipeline.cross_deps — List all cross-pipeline deps with satisfaction status | 5 | E4.13 | 14 | ❌ |
| E4.15 | pipeline.get_blockers — What's blocking pipeline progress? | 3 | E4.14 | 14 | ❌ |
| E4.16 | Gate check logic: same-pipeline sequential + cross-pipeline deps | 5 | E4.14, E3.05 | 14 | ❌ |
| E4.17 | Priority scoring engine (critical path +100, core +50, early step +30, etc.) | 5 | E4.16 | 15 | ❌ |
| E4.18 | pipeline.get_critical_path — Topological sort across all pipelines | 8 | E4.13 | 14 | ❌ |
| E4.19 | Critical path computation: longest chain with estimated time | 5 | E4.18 | 15 | ❌ |
| E4.20 | Pipeline advancement automation: on-complete → check-gate → advance | 5 | E4.16, E1.15 | 15 | ❌ |
| E4.21 | Pipeline velocity tracking & ETA estimation | 3 | E4.20 | 16 | ❌ |
| E4.22 | Model router: task → AI model routing with cost/capability matching | 5 | E1.08, E1.04 | 10 | ❌ |
| E4.23 | Model router: local (Ollama) vs API routing logic | 3 | E4.22 | 11 | ❌ |
| E4.24 | Pipeline lock: advisory locks per pipeline stream | 3 | E4.01 | 11 | ❌ |
| E4.25 | Pipeline dispatch integration: combine state machine + gate + priority + Docker | 5 | E4.17, E2.09 | 16 | ❌ |
| E4.26 | Agent → pipeline → step tracking in dispatch flow | 3 | E4.25 | 16 | ❌ |

### Epic 5: Asset Management & Dependency Graph (22 tasks, 92 pts)

| # | Task Name | Pts | Dependencies | Wave | Critical Path? |
|---|-----------|-----|-------------|------|----------------|
| E5.01 | Asset dependency graph engine: DAG data structure | 5 | E3.09 | 12 | ✅ |
| E5.02 | asset.add_dependency — Add edge with dep_type | 3 | E5.01 | 13 | ✅ |
| E5.03 | Cycle detection: DFS with coloring (white/gray/black) | 5 | E5.02 | 14 | ❌ |
| E5.04 | asset.check_readiness — Recursive dep satisfaction check | 5 | E5.02 | 14 | ✅ |
| E5.05 | asset.get_dep_tree — Upstream + downstream recursive CTE | 5 | E5.02 | 14 | ✅ |
| E5.06 | asset.get_orphans — Find assets with no deps (potential stale) | 3 | E5.01 | 13 | ❌ |
| E5.07 | asset.get_missing — Expected assets from pipeline defs that don't exist | 3 | E5.01, E4.02 | 13 | ❌ |
| E5.08 | Bottleneck detection: assets blocking most downstream work | 5 | E5.05 | 15 | ❌ |
| E5.09 | Cascade triggers: on asset approved → mark children as READY | 5 | E5.04 | 15 | ❌ |
| E5.10 | Asset lifecycle state machine: draft→in-progress→review→approved→integrated | 3 | E3.13 | 12 | ❌ |
| E5.11 | Asset validation: sprite rules (power-of-2, palette, alpha) | 5 | E3.14 | 12 | ❌ |
| E5.12 | Asset validation: 3D model rules (poly count, manifold, UV, glTF) | 5 | E3.14 | 12 | ❌ |
| E5.13 | Asset validation: texture rules (PBR channels, tileable, dims) | 3 | E3.14 | 12 | ❌ |
| E5.14 | Asset validation: audio rules (sample rate, bit depth, loudness LUFS) | 3 | E3.14 | 12 | ❌ |
| E5.15 | Asset validation: scene rules (broken refs, physics layers) | 3 | E3.14 | 12 | ❌ |
| E5.16 | Asset validation: script rules (GDScript lint via gdtoolkit) | 3 | E3.14 | 12 | ❌ |
| E5.17 | Asset validation: tilemap rules (tile IDs, collision, nav mesh) | 3 | E3.14 | 12 | ❌ |
| E5.18 | Asset validation: animation rules (frame count, loop point, timing) | 3 | E3.14 | 12 | ❌ |
| E5.19 | Auto-register assets on agent completion (Rule G4) | 5 | E5.10, E1.15 | 15 | ❌ |
| E5.20 | Unregistered file scanner: flag files in /assets/ not in DB | 3 | E5.19 | 16 | ❌ |
| E5.21 | Git LFS integration: .gitattributes config at project init | 3 | E1.01 | 5 | ❌ |
| E5.22 | Asset metadata enrichment: auto-extract dims, poly count, duration | 5 | E3.10 | 13 | ❌ |

### Epic 6: Convergence, Automation & Playtest (20 tasks, 82 pts)

| # | Task Name | Pts | Dependencies | Wave | Critical Path? |
|---|-----------|-----|-------------|------|----------------|
| E6.01 | Convergence engine core: audit → score check → fix dispatch → re-audit | 8 | E3.23, E4.20 | 15 | ✅ |
| E6.02 | Convergence threshold enforcement: ≥96 to pass (configurable per project) | 3 | E6.01 | 16 | ✅ |
| E6.03 | Convergence round tracking: round counter, previous_score delta | 3 | E6.01 | 16 | ❌ |
| E6.04 | Stall detection: 3 rounds within ±2pts → STALLED (Rule 4.2) | 5 | E6.03 | 17 | ✅ |
| E6.05 | Stall escalation: auto-flag for manual review | 3 | E6.04 | 18 | ❌ |
| E6.06 | Auto-cascade chains: sculptor → media pipeline auto-dispatch | 5 | E6.01, E5.09 | 17 | ✅ |
| E6.07 | Auto-cascade: balance auditor FAIL → game economist re-dispatch | 3 | E6.06 | 18 | ❌ |
| E6.08 | Auto-cascade: playtest FAIL → code executor fix dispatch | 3 | E6.06 | 18 | ✅ |
| E6.09 | Auto-cascade: narrative complete → character designer dispatch | 3 | E6.06 | 18 | ❌ |
| E6.10 | Auto-cascade: world cartographer → terrain sculptor dispatch | 3 | E6.06 | 18 | ❌ |
| E6.11 | Playtest bot dispatch: archetype-based session configuration | 5 | E3.34 | 15 | ❌ |
| E6.12 | Playtest metric collection: structured metrics into playtest_metrics | 3 | E6.11 | 16 | ❌ |
| E6.13 | Playtest scheduling: auto-run after every N code completions | 3 | E6.11 | 16 | ❌ |
| E6.14 | Economy simulation dispatcher | 5 | E3.37 | 15 | ❌ |
| E6.15 | Economy health scoring: aggregated health_score with warnings | 3 | E6.14 | 16 | ❌ |
| E6.16 | Economy simulation trigger: auto-run after balance parameter change (Rule G7) | 3 | E6.14 | 16 | ❌ |
| E6.17 | 10 quality dimension definitions seed data | 3 | E3.22 | 15 | ❌ |
| E6.18 | Per-dimension convergence tracking: all 10 dimensions per system | 5 | E6.17, E6.02 | 17 | ❌ |
| E6.19 | Ship gate: ALL 10 dimensions ≥96 on ALL major systems before build | 3 | E6.18 | 18 | ❌ |
| E6.20 | Smoke test automation: auto-launch + critical path + FPS check (Rule G14) | 5 | E3.21 | 18 | ❌ |

### Epic 7: Dashboard & Desktop App (22 tasks, 88 pts)

| # | Task Name | Pts | Dependencies | Wave | Critical Path? |
|---|-----------|-----|-------------|------|----------------|
| E7.01 | Web dashboard: React project scaffold with Vite | 5 | E1.01 | 16 | ✅ |
| E7.02 | WebSocket server: real-time state push from ACP server | 5 | E1.08 | 16 | ❌ |
| E7.03 | Dashboard: Pipeline Canvas — 9 swimlane progress bars | 5 | E7.01, E7.02 | 17 | ✅ |
| E7.04 | Dashboard: Pipeline Canvas — cross-pipeline dependency edges | 5 | E7.03 | 18 | ❌ |
| E7.05 | Dashboard: Agent Pool Monitor — running agents with timing | 5 | E7.01, E7.02 | 17 | ❌ |
| E7.06 | Dashboard: Build Matrix — platform × status grid | 3 | E7.01, E3.18 | 17 | ✅ |
| E7.07 | Dashboard: Quality Scorecards — 10 dimensions per system | 5 | E7.01, E3.24 | 17 | ❌ |
| E7.08 | Dashboard: Asset Browser — thumbnail grid with metadata panel | 5 | E7.01, E3.11 | 17 | ❌ |
| E7.09 | Dashboard: Asset Browser — dependency tree visualization | 5 | E7.08, E5.05 | 18 | ✅ |
| E7.10 | Dashboard: Trope Toggle Panel — enable/disable with dep warnings | 3 | E7.01, E3.29 | 17 | ❌ |
| E7.11 | Dashboard: Economy Dashboard — live graphs, simulation results | 5 | E7.01, E6.15 | 18 | ❌ |
| E7.12 | Dashboard: Store Tracker — submission status per store | 3 | E7.01, E3.38 | 17 | ❌ |
| E7.13 | Dashboard: Overall progress bar + ETA | 3 | E7.03, E4.21 | 18 | ❌ |
| E7.14 | Dashboard layout: responsive sidebar + main content + panels | 3 | E7.01 | 17 | ❌ |
| E7.15 | Dashboard: Dark theme + game-dev visual identity | 3 | E7.14 | 18 | ❌ |
| E7.16 | Tauri desktop app: project scaffold + IPC bridge | 5 | E7.01 | 19 | ❌ |
| E7.17 | Tauri: window management + native menus | 3 | E7.16 | 20 | ❌ |
| E7.18 | Tauri: system tray with pipeline summary | 3 | E7.17 | 21 | ❌ |
| E7.19 | Tauri: native notifications on agent completion/build events | 3 | E7.17 | 21 | ❌ |
| E7.20 | Tauri: auto-update mechanism | 3 | E7.17 | 21 | ❌ |
| E7.21 | Dashboard: Command palette (Ctrl+K) for quick actions | 3 | E7.01 | 18 | ❌ |
| E7.22 | Dashboard: Keyboard shortcuts for common operations | 3 | E7.21 | 19 | ❌ |

### Epic 8: Distribution, Build & Store (16 tasks, 64 pts)

| # | Task Name | Pts | Dependencies | Wave | Critical Path? |
|---|-----------|-----|-------------|------|----------------|
| E8.01 | Cross-platform build system: Godot CLI export templates | 5 | E3.17 | 17 | ✅ |
| E8.02 | Build per-platform: Windows, macOS, Linux via Godot headless | 5 | E8.01 | 18 | ✅ |
| E8.03 | Build per-platform: Web/HTML5 export | 3 | E8.01 | 18 | ❌ |
| E8.04 | Build per-platform: Android AAB + iOS archive | 5 | E8.01 | 18 | ❌ |
| E8.05 | Store submission tools: requirements checklist engine | 5 | E3.38 | 18 | ✅ |
| E8.06 | Store: Steam requirements seed data (Appendix C from vision) | 3 | E8.05 | 19 | ✅ |
| E8.07 | Store: itch.io, Epic, GOG requirements seed data | 3 | E8.05 | 19 | ❌ |
| E8.08 | Store: Mobile (App Store, Google Play) requirements seed data | 3 | E8.05 | 19 | ❌ |
| E8.09 | store.submit & store.get_status & store.update_status | 5 | E3.38, E1.08 | 18 | ❌ |
| E8.10 | store.requirements_checklist & store.check_requirement | 3 | E8.05 | 19 | ❌ |
| E8.11 | store.generate_metadata — Auto-generate from GDD | 5 | E8.09 | 19 | ❌ |
| E8.12 | store.get_readiness — Overall readiness score per store | 3 | E8.10 | 20 | ❌ |
| E8.13 | Patch management: patch.create & patch.get_manifest | 5 | E3.39, E1.08 | 18 | ❌ |
| E8.14 | Patch: delta manifest generation (what changed between versions) | 5 | E8.13 | 19 | ❌ |
| E8.15 | Patch: save migration check & rollback verification | 3 | E8.13 | 19 | ❌ |
| E8.16 | Patch: staged rollout (rollout_percent management) | 3 | E8.13 | 19 | ❌ |

### Epic V: Verification & End-to-End (4 tasks, 20 pts)

| # | Task Name | Pts | Dependencies | Wave | Critical Path? |
|---|-----------|-----|-------------|------|----------------|
| V.01 | E2E: Create toy game project via CLI → verify all 26 tables populated | 5 | ALL E1–E8 | 23 | ✅ |
| V.02 | E2E: Dispatch 5 agents across 3 pipelines → verify state machine + deps | 5 | V.01 | 23 | ✅ |
| V.03 | Performance: 500+ assets, 9 pipelines, 5 concurrent agents | 5 | V.01 | 23 | ❌ |
| V.04 | E2E: Full build → smoke test → store readiness check | 5 | V.02 | 24 | ✅ |

---

## CLI Tasks (Cross-cutting — included in task counts above but called out for visibility)

The CLI is built incrementally alongside the epics. These tasks are woven into the waves:

| CLI Command | Built In | Dependencies |
|-------------|----------|-------------|
| `cgs-game init` | E1 Wave 5 (E1.09) | project.create |
| `cgs-game status` | E1 Wave 5 (E1.12) | project.get_status |
| `cgs-game dispatch` | E1 Wave 6 (E1.13) | agent.dispatch_next |
| `cgs-game build` | E8 Wave 18 (E8.01) | build.trigger |
| `cgs-game playtest` | E6 Wave 15 (E6.11) | playtest.run |
| `cgs-game audit` | E6 Wave 15 (E6.01) | audit tools |
| `cgs-game ship` | E8 Wave 19 (E8.09) | store.submit |
| `cgs-game trope` | E3 Wave 8 (E3.29) | trope tools |
| `cgs-game patch` | E8 Wave 18 (E8.13) | patch tools |
| `cgs-game asset` | E3 Wave 8 (E3.10) | asset tools |
| `cgs-game docker` | E2 Wave 8 (E2.15) | docker tools |
| `cgs-game agent` | E1 Wave 6 (E1.17) | agent tools |
| `cgs-game pipeline` | E3 Wave 8 (E3.02) | pipeline tools |
| `cgs-game store` | E8 Wave 18 (E8.09) | store tools |
| `cgs-game config` | E1 Wave 5 (E1.10) | project.configure |

---

## Dependency Graph

```
EPIC 1: CORE INFRASTRUCTURE                     EPIC 2: DOCKER
═══════════════════════                          ═════════════

┌──────────┐                                     ┌──────────┐
│ E1.01(3) │ Repo scaffold                       │ E2.01(5) │ gamedev-base
│          │──────────────────────────────────────│ Dockerfile│
└────┬─────┘                                     └──┬───┬───┘
     │                                              │   │
     ▼                                              ▼   ▼
┌──────────┐                                  ┌────┐┌────┐┌────┐┌────┐
│ E1.02(5) │ SQLite bootstrap                 │2.02││2.03││2.04││2.05│
│          │                                  │ 2d ││ 3d ││aud││eng│
└──┬─┬─┬───┘                                 └──┬─┘└──┬─┘└──┬─┘└──┬─┘
   │ │ │                                        │     │     │     │
   │ │ │   ┌─────────────────────────────────┐  └──┬──┘     │     │
   ▼ ▼ ▼   │                                 │     │  ┌─────┘     │
┌──┐┌──┐┌──┐│                                 │     ▼  ▼           │
│03││04││05││   (core, agent, prompt tables)   │  ┌──────┐         │
└──┘└──┘└──┘│                                 │  │E2.06 │ full    │
   │  │  │  │                                 │  │      │◄────────┘
   ▼  ▼  ▼  ▼                                 │  └──┬───┘
┌──────────┐                                  │     │
│ E1.08(8) │ ACP Server skeleton              │     ▼
│          │──────────────────────────────────►│ E2.08 Docker Manager
└──┬───────┘                                  │ ┌──────┐
   │                                          │ │      │
   ├──→ E1.09–E1.12 (project tools)           │ └──┬───┘
   ├──→ E1.14 (agent.dispatch)                │    │
   ├──→ E1.24–E1.26 (session, logs, convs)    │    ├──→ E2.09 container selection
   └──→ E1.28 (prompt engine)                 │    ├──→ E2.10 volume mounts
                                              │    ├──→ E2.11 health monitor
   E1.13 (dispatch_next) ← E1.12             │    └──→ E2.12 warm pool
                                              │
                                              │

EPIC 3: MCP TOOLS (40 tools)                  EPIC 4: PIPELINE ENGINE
════════════════════════                       ═══════════════════════

  E3.01 (pipeline tables) ←── E1.02           E4.01 (state machine) ← E3.01
  E3.09 (asset tables)    ←── E1.02               │
  E3.16 (build tables)    ←── E1.02               ▼
  E3.22 (audit tables)    ←── E1.02           E4.02 (9 pipeline defs)
  E3.28 (trope tables)    ←── E1.02               │
  E3.32 (playtest tables) ←── E1.02               ├──→ E4.03–E4.10 (per-pipeline steps)
  E3.33 (economy table)   ←── E1.02               │
  E3.38 (store tables)    ←── E1.02               ├──→ E4.11 (trope addon pipeline)
  E3.39 (patch tables)    ←── E1.02               │
                                                   └──→ E4.13 (cross-pipeline deps)
  Each table → tools → advanced queries               │
                                                       ├──→ E4.14 (cross_deps tool)
                                                       ├──→ E4.18 (critical path)
                                                       └──→ E4.16 (gate check logic)
                                                              │
                                                              ▼
                                                       E4.17 (priority scoring)
                                                              │
                                                              ▼
                                                       E4.25 (full dispatch integration)


EPIC 5: ASSET DEP GRAPH       EPIC 6: CONVERGENCE            EPIC 7: DASHBOARD
═══════════════════            ═══════════════════            ═══════════════

E5.01 (DAG engine) ← E3.09   E6.01 (convergence core)       E7.01 (React scaffold)
    │                            ← E3.23, E4.20                  │
    ▼                              │                             ├──→ E7.03 (pipeline canvas)
E5.02 (add_dependency)             ▼                             ├──→ E7.05 (agent pool)
    │                         E6.02 (threshold)                  ├──→ E7.06 (build matrix)
    ├──→ E5.03 (cycles)            │                             ├──→ E7.07 (quality scores)
    ├──→ E5.04 (readiness)         ▼                             ├──→ E7.08 (asset browser)
    └──→ E5.05 (dep tree)    E6.04 (stall detection)            └──→ E7.10 (trope toggles)
         │                         │
         ▼                         ▼                         E7.16 (Tauri) ← E7.01
    E5.08 (bottleneck)        E6.06 (auto-cascade)               │
    E5.09 (cascade trigger)        │                              ▼
                                   ├──→ E6.07–E6.10          E7.17–E7.20 (native features)
                                   │    (specific cascades)
                                   │
                              E6.11 (playtest dispatch)
                              E6.14 (economy sim)


EPIC 8: DISTRIBUTION               EPIC V: VERIFICATION
═══════════════════                 ════════════════════

E8.01 (Godot build) ← E3.17       V.01 (E2E toy game)
    │                                  │
    ├──→ E8.02 (Win/Mac/Linux)         ▼
    ├──→ E8.03 (Web)               V.02 (multi-agent dispatch)
    └──→ E8.04 (Mobile)               │
                                       ▼
E8.05 (store checklist)            V.04 (full build → ship)
    │
    ├──→ E8.06 (Steam)
    ├──→ E8.07 (itch/Epic/GOG)
    └──→ E8.08 (Mobile stores)

E8.13 (patch mgmt) ← E3.39
    │
    ├──→ E8.14 (delta manifest)
    ├──→ E8.15 (save migration)
    └──→ E8.16 (staged rollout)
```

---

## Wave Plan

### Wave 1 — Repository Foundation (no dependencies) | 3 pts
| Task | Pts | Description |
|------|-----|-------------|
| E1.01 | 3 | Create repository structure: src/, docker/, agents/, pipelines/, templates/, tests/, docs/ |

### Wave 2 — Database Bootstrap (depends on Wave 1) | 5 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E1.02 | 5 | E1.01 | SQLite bootstrap module: WAL mode, better-sqlite3, migration runner |

### Wave 3 — Schema Tables (depends on Wave 2) | 19 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E1.03 | 5 | E1.02 | game_projects, session_state, activity_log tables |
| E1.04 | 5 | E1.02 | agent_registry, active_agents, dispatches tables |
| E1.05 | 3 | E1.02 | prompt_templates, conventions tables |
| E1.06 | 3 | E1.02 | FTS5 virtual table for asset search |
| E2.07 | 3 | E1.02 | docker_containers table |

### Wave 4 — Server Skeleton + Indexes (depends on Wave 3) | 11 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E1.07 | 3 | E1.03, E1.04 | 17 performance indexes |
| E1.08 | 8 | E1.05 | ACP server skeleton: MCP protocol, tool registration framework |

### Wave 5 — Core Tools + Dockerfiles (depends on Wave 4) | 48 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E1.09 | 5 | E1.08 | project.create |
| E1.10 | 3 | E1.09 | project.configure |
| E1.11 | 3 | E1.09 | project.set_active & project.list |
| E1.12 | 5 | E1.09 | project.get_status (full dashboard query) |
| E1.14 | 5 | E1.08, E1.04 | agent.dispatch (specific) |
| E1.22 | 3 | E1.08, E1.04 | agent.list_registry |
| E1.24 | 5 | E1.08, E1.03 | Session state: get/set/snapshot |
| E1.25 | 3 | E1.08, E1.03 | Activity logging |
| E1.26 | 3 | E1.08, E1.05 | Convention management |
| E1.28 | 5 | E1.05, E1.08 | Prompt template engine |
| E2.01 | 5 | E1.01 | Dockerfile: gamedev-base |
| E5.21 | 3 | E1.01 | Git LFS .gitattributes setup |

### Wave 6 — Dispatch Engine + Agent Lifecycle + Docker Builds (depends on Wave 5) | 40 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E1.13 | 8 | E1.12 | agent.dispatch_next (priority-aware) |
| E1.15 | 5 | E1.14 | agent.complete |
| E1.16 | 3 | E1.14 | agent.crash |
| E1.17 | 3 | E1.14 | agent.get_running |
| E1.18 | 3 | E1.17 | agent.health_check |
| E1.19 | 3 | E1.18 | agent.crash_recovery |
| E1.20 | 3 | E1.17 | agent.get_capacity |
| E1.21 | 5 | E1.13 | agent.fill_slots |
| E1.23 | 3 | E1.15 | agent.performance_stats |
| E1.27 | 5 | E1.15 | Git auto-commit on completion |
| E1.29 | 5 | E1.28 | agent.get_prompt |
| E1.30 | 3 | E1.28 | agent.update_prompt_template |
| E2.02 | 5 | E2.01 | Dockerfile: gamedev-2d |
| E2.03 | 5 | E2.01 | Dockerfile: gamedev-3d |
| E2.04 | 5 | E2.01 | Dockerfile: gamedev-audio |
| E2.05 | 5 | E2.01 | Dockerfile: gamedev-engine |

### Wave 7 — Domain Tables + Docker Full (depends on Wave 6) | 49 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E2.06 | 5 | E2.02–E2.05 | Dockerfile: gamedev-full |
| E2.08 | 5 | E2.07, E1.08 | Docker Manager: container lifecycle |
| E3.01 | 5 | E1.02 | Pipeline tables (defs, steps, state) |
| E3.09 | 5 | E1.02 | Asset tables (assets, metadata, deps) |
| E3.16 | 5 | E1.02 | Build tables |
| E3.22 | 5 | E1.02 | Audit tables |
| E3.28 | 3 | E1.02 | Trope tables |
| E3.32 | 5 | E1.02 | Playtest tables |
| E3.33 | 3 | E1.02 | Economy table |
| E3.38 | 5 | E1.02 | Store tables |
| E3.39 | 3 | E1.02 | Patch tables |

### Wave 8 — Domain Tool Foundations (depends on Wave 7) | 39 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E2.09 | 3 | E2.08 | Container selection (agent→image) |
| E2.10 | 3 | E2.08 | Volume mount configuration |
| E2.11 | 3 | E2.08 | Container health monitoring |
| E2.15 | 3 | E2.08 | docker.start & docker.stop MCP tools |
| E3.02 | 3 | E3.01, E1.08 | pipeline.list |
| E3.10 | 5 | E3.09, E1.08 | asset.register |
| E3.17 | 5 | E3.16, E1.08 | build.trigger |
| E3.23 | 3 | E3.22, E1.08 | audit.score |
| E3.29 | 5 | E3.28, E1.08 | trope.enable & trope.disable |
| E3.34 | 5 | E3.32, E1.08 | playtest.run & get_results |
| E3.37 | 5 | E3.33, E1.08 | economy.simulate & get_health |
| E3.40 | 5 | E1.08, E1.15 | analytics.throughput/pass_rate/agent_perf |

### Wave 9 — Domain Tool Expansion (depends on Wave 8) | 74 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E2.12 | 5 | E2.08 | Warm pool & container reuse |
| E2.13 | 3 | E2.10 | Shared asset cache volume |
| E2.14 | 3 | E2.09 | docker.container_for |
| E2.16 | 3 | E2.11 | docker.health & docker.list |
| E2.17 | 3 | E2.08 | docker.image_status & docker.cleanup |
| E2.18 | 3 | E2.10 | docker.volume_mount |
| E3.03 | 5 | E3.02 | pipeline.status (detailed) |
| E3.04 | 5 | E3.02 | pipeline.advance |
| E3.07 | 3 | E3.02 | pipeline.parallel_status |
| E3.08 | 3 | E3.02 | pipeline.estimate_completion |
| E3.11 | 5 | E3.10 | asset.query |
| E3.12 | 3 | E3.10, E1.06 | asset.search (FTS5) |
| E3.13 | 3 | E3.10 | asset.get & asset.update_status |
| E3.14 | 5 | E3.10 | asset.validate |
| E3.15 | 5 | E3.10 | asset.bulk_register, get_stats, generate_manifest |
| E3.18 | 5 | E3.17 | build.status & build.get_matrix |
| E3.19 | 3 | E3.17 | build.get_latest, get_history, get_size_trend |
| E3.20 | 5 | E3.17 | build.platform_cert, promote, cancel |
| E3.21 | 3 | E3.17 | build.smoke_test |
| E3.24 | 5 | E3.23 | audit.get_scoreboard & audit.get_trend |
| E3.25 | 5 | E3.23 | audit.get_remediation_queue & convergence_status |
| E3.26 | 5 | E3.23 | audit.import_report, get_findings, resolve_finding |
| E3.27 | 5 | E3.23 | audit.stall_check, dimension_summary, get_all_dimensions |
| E3.30 | 3 | E3.29 | trope.list, get_config, update_config |
| E3.31 | 5 | E3.29 | trope.dep_check, get_agents, bulk_enable |
| E3.35 | 5 | E3.34 | playtest.get_metrics, compare, schedule |
| E3.36 | 3 | E3.34 | playtest.get_softlocks, get_exploits |

### Wave 10 — Pipeline State Machine + Gate Checks (depends on Wave 9) | 18 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E3.05 | 5 | E3.04 | pipeline.gate_check |
| E3.06 | 5 | E3.04 | pipeline.history, reset_step, skip_step |
| E4.01 | 5 | E3.01 | Pipeline state machine implementation |
| E4.12 | 3 | E3.01 | Cross-pipeline dependency table |
| E4.22 | 5 | E1.08, E1.04 | Model router: task→model routing |

### Wave 11 — Pipeline Definitions (depends on Wave 10) | 11 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E4.02 | 5 | E4.01 | 9 pipeline definitions seed data |
| E4.23 | 3 | E4.22 | Model router: local (Ollama) vs API |
| E4.24 | 3 | E4.01 | Pipeline advisory locks |

### Wave 12 — Per-Pipeline Steps + Asset Validation (depends on Wave 11) | 50 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E4.03 | 5 | E4.02 | Pipeline 1: Core Game Loop steps |
| E4.04 | 3 | E4.02 | Pipeline 2: Narrative steps |
| E4.05 | 5 | E4.02 | Pipeline 3: Art steps |
| E4.06 | 3 | E4.02 | Pipeline 4: Audio steps |
| E4.07 | 3 | E4.02 | Pipeline 5: World steps |
| E4.08 | 3 | E4.02 | Pipeline 6: Economy steps |
| E4.09 | 3 | E4.02 | Pipeline 7: Distribution steps |
| E4.10 | 3 | E4.02 | Pipeline 8: Camera steps |
| E5.01 | 5 | E3.09 | Asset DAG engine |
| E5.10 | 3 | E3.13 | Asset lifecycle state machine |
| E5.11 | 5 | E3.14 | Sprite validation rules |
| E5.12 | 5 | E3.14 | 3D model validation rules |
| E5.13 | 3 | E3.14 | Texture validation rules |
| E5.14 | 3 | E3.14 | Audio validation rules |
| E5.15 | 3 | E3.14 | Scene validation rules |
| E5.16 | 3 | E3.14 | Script validation rules (GDScript lint) |
| E5.17 | 3 | E3.14 | Tilemap validation rules |
| E5.18 | 3 | E3.14 | Animation validation rules |

### Wave 13 — Asset Deps + Trope Pipeline + Cross-Deps (depends on Wave 12) | 22 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E4.11 | 5 | E4.02, E3.29 | Pipeline 9: Trope addon dynamic steps |
| E4.13 | 5 | E4.12, E4.03 | Cross-pipeline dependency seed data |
| E5.02 | 3 | E5.01 | asset.add_dependency |
| E5.06 | 3 | E5.01 | asset.get_orphans |
| E5.07 | 3 | E5.01, E4.02 | asset.get_missing |
| E5.22 | 5 | E3.10 | Asset metadata auto-extraction |

### Wave 14 — Cross-Dep Resolution + DAG Algorithms (depends on Wave 13) | 26 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E4.14 | 5 | E4.13 | pipeline.cross_deps tool |
| E4.15 | 3 | E4.14 | pipeline.get_blockers |
| E4.18 | 8 | E4.13 | pipeline.get_critical_path (topological sort) |
| E5.03 | 5 | E5.02 | Cycle detection (DFS coloring) |
| E5.04 | 5 | E5.02 | asset.check_readiness (recursive) |
| E5.05 | 5 | E5.02 | asset.get_dep_tree (recursive CTE) |

### Wave 15 — Convergence Core + Priority Engine + Bottlenecks (depends on Wave 14) | 41 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E4.16 | 5 | E4.14, E3.05 | Gate check: sequential + cross-pipeline |
| E4.17 | 5 | E4.16 | Priority scoring engine |
| E4.19 | 5 | E4.18 | Critical path: longest chain + time estimate |
| E4.20 | 5 | E4.16, E1.15 | Pipeline auto-advance on completion |
| E5.08 | 5 | E5.05 | Bottleneck detection |
| E5.09 | 5 | E5.04 | Cascade triggers on asset approval |
| E5.19 | 5 | E5.10, E1.15 | Auto-register assets on completion (Rule G4) |
| E6.01 | 8 | E3.23, E4.20 | Convergence engine core |
| E6.11 | 5 | E3.34 | Playtest bot dispatch |
| E6.14 | 5 | E3.37 | Economy simulation dispatcher |
| E6.17 | 3 | E3.22 | 10 quality dimensions seed data |

### Wave 16 — Convergence Features + Dashboard Start (depends on Wave 15) | 41 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E4.21 | 3 | E4.20 | Pipeline velocity & ETA |
| E4.25 | 5 | E4.17, E2.09 | Full dispatch integration (state + gate + Docker) |
| E5.20 | 3 | E5.19 | Unregistered file scanner |
| E6.02 | 3 | E6.01 | Convergence threshold (≥96) enforcement |
| E6.03 | 3 | E6.01 | Round tracking: counter + delta |
| E6.12 | 3 | E6.11 | Playtest metric collection |
| E6.13 | 3 | E6.11 | Playtest auto-scheduling |
| E6.15 | 3 | E6.14 | Economy health scoring |
| E6.16 | 3 | E6.14 | Economy sim auto-trigger (Rule G7) |
| E7.01 | 5 | E1.01 | React + Vite project scaffold |
| E7.02 | 5 | E1.08 | WebSocket server for real-time push |
| E4.26 | 3 | E4.25 | Agent→pipeline→step tracking |

### Wave 17 — Dashboard Panels + Stall Detection + Builds (depends on Wave 16) | 54 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E6.04 | 5 | E6.03 | Stall detection (3 rounds ±2pts) |
| E6.06 | 5 | E6.01, E5.09 | Auto-cascade chains (sculptor→media) |
| E6.18 | 5 | E6.17, E6.02 | Per-dimension convergence (all 10) |
| E7.03 | 5 | E7.01, E7.02 | Pipeline Canvas (9 swimlanes) |
| E7.05 | 5 | E7.01, E7.02 | Agent Pool Monitor |
| E7.06 | 3 | E7.01, E3.18 | Build Matrix panel |
| E7.07 | 5 | E7.01, E3.24 | Quality Scorecards |
| E7.08 | 5 | E7.01, E3.11 | Asset Browser (thumbnails + metadata) |
| E7.10 | 3 | E7.01, E3.29 | Trope Toggle Panel |
| E7.12 | 3 | E7.01, E3.38 | Store Tracker |
| E7.14 | 3 | E7.01 | Dashboard layout: sidebar + content + panels |
| E8.01 | 5 | E3.17 | Cross-platform build system (Godot CLI) |

### Wave 18 — Advanced Dashboard + Cascade Rules + Distribution (depends on Wave 17) | 52 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E6.05 | 3 | E6.04 | Stall escalation |
| E6.07 | 3 | E6.06 | Cascade: balance auditor FAIL → economist |
| E6.08 | 3 | E6.06 | Cascade: playtest FAIL → code executor |
| E6.09 | 3 | E6.06 | Cascade: narrative→character designer |
| E6.10 | 3 | E6.06 | Cascade: cartographer→terrain sculptor |
| E6.19 | 3 | E6.18 | Ship gate: all dimensions ≥96 |
| E6.20 | 5 | E3.21 | Smoke test automation (Rule G14) |
| E7.04 | 5 | E7.03 | Pipeline Canvas: cross-pipeline dep edges |
| E7.09 | 5 | E7.08, E5.05 | Asset Browser: dependency tree viz |
| E7.11 | 5 | E7.01, E6.15 | Economy Dashboard |
| E7.13 | 3 | E7.03, E4.21 | Overall progress bar + ETA |
| E7.15 | 3 | E7.14 | Dark theme + game-dev visual identity |
| E7.21 | 3 | E7.01 | Command palette (Ctrl+K) |
| E8.02 | 5 | E8.01 | Build: Windows, macOS, Linux |
| E8.03 | 3 | E8.01 | Build: Web/HTML5 |
| E8.04 | 5 | E8.01 | Build: Android + iOS |
| E8.05 | 5 | E3.38 | Store requirements checklist engine |
| E8.09 | 5 | E3.38, E1.08 | store.submit, get_status, update_status |
| E8.13 | 5 | E3.39, E1.08 | patch.create & get_manifest |

### Wave 19 — Store Data + Patch Features + Tauri Start (depends on Wave 18) | 30 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E7.16 | 5 | E7.01 | Tauri desktop app scaffold + IPC |
| E7.22 | 3 | E7.21 | Keyboard shortcuts |
| E8.06 | 3 | E8.05 | Steam requirements seed data |
| E8.07 | 3 | E8.05 | itch.io, Epic, GOG requirements |
| E8.08 | 3 | E8.05 | Mobile store requirements |
| E8.10 | 3 | E8.05 | store.requirements_checklist, check_requirement |
| E8.11 | 5 | E8.09 | store.generate_metadata |
| E8.14 | 5 | E8.13 | Delta manifest generation |
| E8.15 | 3 | E8.13 | Save migration check + rollback verification |
| E8.16 | 3 | E8.13 | Staged rollout management |

### Wave 20 — Store Readiness + Tauri (depends on Wave 19) | 6 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E7.17 | 3 | E7.16 | Tauri: window management + native menus |
| E8.12 | 3 | E8.10 | store.get_readiness |

### Wave 21 — Tauri Polish (depends on Wave 20) | 9 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| E7.18 | 3 | E7.17 | Tauri: system tray with pipeline summary |
| E7.19 | 3 | E7.17 | Tauri: native notifications |
| E7.20 | 3 | E7.17 | Tauri: auto-update mechanism |

### Wave 22 — (Buffer wave, catch-up for parallel work) | 0 pts

### Wave 23 — End-to-End Verification (depends on ALL) | 15 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| V.01 | 5 | ALL E1–E8 | E2E: Create toy game, verify 26 tables |
| V.02 | 5 | V.01 | E2E: Dispatch 5 agents across 3 pipelines |
| V.03 | 5 | V.01 | Performance: 500+ assets, 5 concurrent agents |

### Wave 24 — Final Verification (depends on Wave 23) | 5 pts
| Task | Pts | Blocked By | Description |
|------|-----|------------|-------------|
| V.04 | 5 | V.02 | E2E: Full build → smoke test → store readiness |

---

## Critical Path Analysis

```
E1.01(3) → E1.02(5) → E1.05(3) → E1.08(8) → E1.12(5) → E1.13(8) →
→ E3.01(5) → E3.02(3) → E3.04(5) → E3.05(5) → E3.06(5) →
→ E4.01(5) → E4.02(5) → E4.04(3) → E4.05(5) → E4.06(3) → E4.09(3) → E4.11(5) →
→ E5.01(5) → E5.02(3) → E5.04(5) → E5.05(5) →
→ E6.01(8) → E6.02(3) → E6.04(5) → E6.06(5) → E6.08(3) →
→ E8.01(5) → E8.02(5) → E8.05(5) → E8.06(3) →
→ E7.01(5) → E7.03(5) → E7.06(3) → E7.09(5) →
→ V.01(5) → V.02(5) → V.04(5)

38 tasks on critical path = 184 points (of 836 total)
```

**Bottleneck**: E1.08 (ACP server skeleton, 8 pts) is the highest-risk task — every subsequent tool, pipeline, and domain depends on the MCP protocol framework being solid. If the tool registration pattern is wrong, every subsequent tool needs refactoring.

**Second bottleneck**: E6.01 (Convergence engine core, 8 pts) — the audit→fix→re-audit loop with score tracking, round counting, and auto-dispatch touches nearly every other subsystem.

**Parallelism**: Up to 16 tasks can run concurrently at peak (Wave 12: 8 per-pipeline step definitions + 8 asset validation rules). Average parallelism across all waves: 8.3 tasks per wave.

**Estimated timeline** (assuming 3 parallel developers, 5 pts/day throughput each):
- Total: 836 pts ÷ 15 pts/day = ~56 working days = **~11 weeks**
- With overhead/rework buffer (1.5x): **~17 weeks**

---

## Task Descriptions

### Epic 1: Core Infrastructure

---

#### E1.01: Repository scaffolding & project structure (3 pts)
**Wave**: 1 | **Dependencies**: None | **Critical Path**: ✅

Create the greenfield repository with the canonical directory structure defined in the vision (Section 19). Initialize npm package, Git, .gitignore, .editorconfig, and README.

**What to build**:
- `src/acp-server/` — MCP server entry point (`server.mjs`)
- `src/cli/` — CLI entry point (`index.mjs`)
- `src/desktop/` — Tauri placeholder
- `src/dashboard/` — React dashboard placeholder
- `docker/` — 6 Dockerfile directories (gamedev-base, -2d, -3d, -audio, -engine, -full)
- `agents/` — Empty, will hold 87+ .agent.md files
- `pipelines/` — Empty, will hold pipeline definitions JSON
- `templates/` — Empty, will hold prompt templates
- `tests/` — Test framework setup (Vitest)
- `docs/` — Copy vision doc as historical reference
- `package.json` with dependencies: `better-sqlite3`, `@modelcontextprotocol/sdk`, `commander`, `chalk`, `ora`
- `.gitignore` for node_modules, *.db, build artifacts
- `.editorconfig` for consistent formatting

**Testing**: `npm install` succeeds, `node src/acp-server/server.mjs` starts without error (empty server).

---

#### E1.02: SQLite database bootstrap module & WAL config (5 pts)
**Wave**: 2 | **Dependencies**: E1.01 | **Critical Path**: ✅

Create the database initialization module that creates/opens the SQLite database with WAL mode, foreign keys enabled, and a migration system for schema evolution.

**What to build**:
- `src/acp-server/db.mjs` — Database singleton with `getDb()`, `runMigration()`, `close()`
- WAL mode: `PRAGMA journal_mode=WAL`
- Foreign keys: `PRAGMA foreign_keys=ON`
- Migration table: `CREATE TABLE IF NOT EXISTS schema_migrations (version INTEGER PRIMARY KEY, applied_at TEXT)`
- Migration runner: reads SQL files from `src/acp-server/migrations/` in order, applies unapplied ones
- Database path configurable via env var `CGS_GAME_DB_PATH` (default: `acp-game-state.db` in project root)

**Testing**: Module creates DB file, applies test migration, verifies WAL mode and FK enforcement.

---

#### E1.03–E1.07: Schema Tables & Indexes (19 pts total)
See Task Registry above. Each task creates one logical group of tables from Section 4 of the vision document. Each is a migration SQL file in `src/acp-server/migrations/`.

---

#### E1.08: ACP server skeleton — MCP protocol & tool registration framework (8 pts)
**Wave**: 4 | **Dependencies**: E1.05 | **Critical Path**: ✅

Create the core MCP server using `@modelcontextprotocol/sdk` that exposes tools via the Model Context Protocol. This is the framework every subsequent tool plugs into.

**What to build**:
- `src/acp-server/server.mjs` — MCP server bootstrap with `stdio` transport
- Tool registration pattern: `registerTool(name, description, schema, handler)`
- Request routing: tool name → handler function dispatch
- Error handling wrapper: catch errors, return structured error JSON
- DB injection: every handler receives `db` instance
- Project context: active project ID from session_state
- Response shape contract: every tool returns `{ success: boolean, ...data }` or `{ error: string }`
- Health endpoint for self-check

**Patterns to follow**: Mirror the CGS ACP server pattern from `neil-docs/tools/acp-server/server.mjs` — same MCP SDK, same tool registration pattern, adapted for game-dev schema.

**Testing**: Server starts, registers a test tool, tool responds to MCP request with correct shape.

---

#### E1.09–E1.12: Project Management Tools (16 pts total)
Four tools implementing the Section 5, Domain 1 of the vision. `project.create` inserts into `game_projects` with sensible defaults for genre, art_style, perspective, and creates all 9 pipeline definitions. `project.get_status` is the most complex — a single query that joins across pipelines, assets, agents, and builds to produce the full project dashboard.

---

#### E1.13: agent.dispatch_next — Priority-aware dispatch engine (8 pts)
**Wave**: 6 | **Dependencies**: E1.12 | **Critical Path**: ✅

The brain of the system. Implements the 5-step dispatch algorithm from Section 8: pipeline scan → priority scoring → container selection → prompt generation → dispatch. For this task, implement the core priority scan and DB updates; Docker integration comes in E4.25.

**What to build**:
- Scan all 9 pipelines for steps with `status = 'pending'` where all deps are satisfied
- Priority scoring: critical path (+100), core pipeline (+50), early step (+30), cross-pipeline unblock (+20), convergence loop (+10), trope (-20)
- Select highest-priority candidate
- Insert into `active_agents` + `dispatches`
- Update `pipeline_state` to `running`
- Return: `{ agent_type, target, pipeline_id, step_id, priority_score }`

**Testing**: With seeded pipeline data, verify dispatch_next returns highest-priority task. Verify it skips tasks with unsatisfied deps.

---

#### E1.14–E1.30: Remaining Agent & Utility Tools
See Task Registry. Each implements one MCP tool from Domain 2 (Agent Dispatch) or supporting utility. Pattern: validate input → DB transaction → return structured JSON → log to activity_log.

---

### Epic 2: Docker & Container System

---

#### E2.01: Dockerfile — gamedev-base (5 pts)
**Wave**: 5 | **Dependencies**: E1.01 | **Critical Path**: ❌

Create the base Docker image that all other game-dev containers inherit from. Contains common tools needed by all agents.

**What to build** (`docker/gamedev-base/Dockerfile`):
- Base: `python:3.12-slim` (small but includes pip)
- System packages: `git`, `curl`, `wget`, `ffmpeg`, `sox`, `imagemagick`
- Node.js 20.x LTS via NodeSource
- ImageMagick policies configured for game asset sizes
- Non-root user `gamedev` for security
- Working directory `/workspace`
- Volume mount points: `/workspace`, `/output`, `/shared-cache`

**Testing**: `docker build` succeeds, `docker run gamedev-base python --version` and `node --version` both work.

---

#### E2.02–E2.06: Tier-specific Dockerfiles (25 pts total)
Each adds domain-specific tools on top of gamedev-base. The vision (Section 10) specifies the exact tool lists per container. gamedev-3d is the largest (Blender 4.x = ~500MB). gamedev-full combines everything.

---

#### E2.08–E2.12: Docker Manager (21 pts total)
Implements the container lifecycle from Section 10 using the Dockerode npm SDK. Container selection maps `agent_registry.docker_image` → running container. Warm pool keeps containers alive for 5 minutes (configurable TTL, Rule G5) to avoid re-initialization overhead.

---

### Epic 3: MCP Tool Surface (40 tasks)

Each task implements 1–3 related MCP tools from one of the 12 domains in Section 5. Every tool follows the same pattern:
1. Validate input parameters against JSON Schema
2. Execute SQL within a `db.transaction()` block
3. Log the action to `activity_log`
4. Return structured JSON matching the documented shape

The 40 tasks cover all 122 tools across domains 3–12 (domains 1–2 are in E1).

---

### Epic 4: Pipeline Engine (26 tasks)

---

#### E4.01: Pipeline state machine (5 pts)
**Wave**: 10 | **Dependencies**: E3.01 | **Critical Path**: ✅

Implement the pipeline step state machine from Section 6: PENDING → READY → RUNNING → PASSED/CONDITIONAL/FAILED → CONVERGING → STALLED/COMPLETED. Each transition validated. Invalid transitions rejected with error.

**What to build**:
- `src/acp-server/pipeline-engine.mjs` — PipelineEngine class
- `validateTransition(currentStatus, newStatus)` — returns boolean
- `transitionStep(stepId, newStatus, metadata)` — atomic DB update
- `getNextReady(pipelineId)` — find first READY step
- Status constants and transition rules as a state map

---

#### E4.02: 9 pipeline definitions seed data (5 pts)
**Wave**: 11 | **Dependencies**: E4.01 | **Critical Path**: ✅

Create the JSON definitions for all 9 pipelines from Section 6 and a seeder that inserts them into `pipeline_defs` + `pipeline_steps`. Each pipeline has its step ordering, agent assignments, produces/consumes contracts.

---

#### E4.03–E4.10: Per-pipeline step definitions (26 pts total)
Eight tasks, one per pipeline (Pipeline 9 is in E4.11). Each reads the pipeline details from Section 6 and the agent matrix from Appendix A to define the concrete step ordering with agent assignments.

---

#### E4.11: Pipeline 9 — Trope Addons dynamic step generation (5 pts)
**Wave**: 13 | **Dependencies**: E4.02, E3.29 | **Critical Path**: ✅

Pipeline 9 is unique — its steps are dynamically generated based on which of the 18 tropes are enabled. When `trope.enable` is called, new pipeline steps are inserted into `pipeline_steps` for Pipeline 9.

---

#### E4.13: Cross-pipeline dependency seed data (5 pts)
**Wave**: 13 | **Dependencies**: E4.12, E4.03 | **Critical Path**: ❌

Insert all 13+ cross-pipeline dependency rules from Section 6's "Key Cross-Pipeline Dependencies" table into the `pipeline_deps` table.

---

#### E4.18: pipeline.get_critical_path — Topological sort (8 pts)
**Wave**: 14 | **Dependencies**: E4.13 | **Critical Path**: ❌

The most algorithmically complex task. Perform topological sort across ALL pipeline steps plus cross-pipeline dependencies to find the longest dependency chain. Uses Kahn's algorithm or DFS-based topological sort.

---

### Epic 5: Asset Management & Dependency Graph (22 tasks)

---

#### E5.01: Asset dependency graph engine (5 pts)
**Wave**: 12 | **Dependencies**: E3.09 | **Critical Path**: ✅

Core DAG data structure and operations for the asset dependency graph described in Section 7. This is the most game-specific subsystem — enterprise CGS has nothing equivalent.

**What to build**:
- `src/acp-server/asset-dep-graph.mjs` — AssetDepGraph class
- `addEdge(parentId, childId, depType)` — with self-reference prevention
- `getParents(assetId)` — direct parents
- `getChildren(assetId)` — direct children
- SQL-backed with `asset_deps` table
- Recursive CTE helpers for upstream/downstream traversal

---

#### E5.03: Cycle detection via DFS coloring (5 pts)
**Wave**: 14 | **Dependencies**: E5.02 | **Critical Path**: ❌

Implement the cycle detection algorithm from Section 7: White (unvisited) → Gray (in current DFS path) → Black (fully processed). If DFS reaches a Gray node → cycle detected. Returns all cycles found.

---

#### E5.11–E5.18: Asset validation rules (26 pts total)
Eight tasks implementing the type-specific validation rules from Section 7's "Asset Validation Rules" table. Each validates assets of one type against format, dimension, naming, and content rules. These are critical for the quality gate — an asset cannot move to 'approved' without passing validation.

---

### Epic 6: Convergence, Automation & Playtest (20 tasks)

---

#### E6.01: Convergence engine core (8 pts)
**Wave**: 15 | **Dependencies**: E3.23, E4.20 | **Critical Path**: ✅

The heart of quality enforcement. Implements the audit → score check → fix dispatch → re-audit loop from Section 11. When an audit scores <96, the engine auto-dispatches a fix agent for the identified issues, then re-dispatches the auditor.

**What to build**:
- `src/acp-server/convergence-engine.mjs` — ConvergenceEngine class
- `onAuditComplete(target, dimension, score, findings)` — decides next action
- If score ≥ threshold → mark converged
- If score < threshold → dispatch fix agent, increment round
- If 3 rounds within ±2pts → mark STALLED
- Round tracking in `audit_scores` (audit_round, previous_score)
- Auto-dispatch of appropriate fix agent based on dimension

---

#### E6.06: Auto-cascade chains (5 pts)
**Wave**: 17 | **Dependencies**: E6.01, E5.09 | **Critical Path**: ✅

Implement the auto-cascade dispatch rules from Section 8's "Auto-Cascade Chains" table. When certain agents complete, the system automatically dispatches the next agent in the chain. 12 cascade rules covering sculptor→media, balance→economist, playtest→code, narrative→character, etc.

---

### Epic 7: Dashboard & Desktop App (22 tasks)

---

#### E7.03: Dashboard — Pipeline Canvas with 9 swimlanes (5 pts)
**Wave**: 17 | **Dependencies**: E7.01, E7.02 | **Critical Path**: ✅

The primary dashboard view from Section 9. Shows all 9 pipelines as horizontal progress bars with step-level status indicators. Real-time updates via WebSocket.

---

#### E7.16: Tauri desktop app scaffold (5 pts)
**Wave**: 19 | **Dependencies**: E7.01 | **Critical Path**: ❌

Set up the Tauri 2 project that wraps the web dashboard in a native desktop application. IPC bridge for native features (file system access, system tray, notifications).

---

### Epic 8: Distribution, Build & Store (16 tasks)

---

#### E8.01: Cross-platform build system (5 pts)
**Wave**: 17 | **Dependencies**: E3.17 | **Critical Path**: ✅

Integrate with Godot's headless CLI to trigger cross-platform builds. `godot --headless --export-release` for each target platform. Build artifacts tracked in `builds` + `build_platforms` tables.

---

#### E8.05: Store requirements checklist engine (5 pts)
**Wave**: 18 | **Dependencies**: E3.38 | **Critical Path**: ✅

Generic engine that evaluates store requirements against project state. Some checks are automated (file dimensions, character counts), others are manual. Produces a completeness percentage per store.

---

### Epic V: Verification

---

#### V.01: E2E — Create toy game via CLI (5 pts)
**Wave**: 23 | **Dependencies**: ALL | **Critical Path**: ✅

Create a complete toy game project using only CGS-Game CLI commands. Verify all 26 tables are populated, 9 pipelines are created, agent registry is loaded, and the full project.get_status query returns valid data.

---

#### V.04: E2E — Full build → smoke test → store readiness (5 pts)
**Wave**: 24 | **Dependencies**: V.02 | **Critical Path**: ✅

Trigger a cross-platform build, run smoke tests, check store readiness for Steam and itch.io. Verify the entire distribution pipeline works end-to-end.

---

## Assumptions & Decisions

| # | Assumption/Decision | Rationale | Impact if Wrong |
|---|---------------------|-----------|-----------------|
| D-001 | Greenfield repo — no code from EOIC CGS is copied | Vision doc says standalone; avoids licensing and coupling issues | If forking was intended, save ~40% of E1 effort but gain tech debt |
| D-002 | Node.js + better-sqlite3 for ACP server | Proven stack from CGS; MCP SDK is Node-native | If Python was preferred, rewrite E1.08 and all tools |
| D-003 | Godot 4 as default engine (configurable) | Vision specifies Godot 4 as default; most Docker images assume it | If Unity/Unreal needed, E2.05 and E8.01 need rework |
| D-004 | Vitest for test framework | Fast, ESM-native, works with Node.js MCP patterns | Low impact — test migration is cheap |
| D-005 | All 87 agents defined as .agent.md files (not implemented) | Agents are prompt templates, not code; AI runtimes execute them | If agents need code implementations, add ~87 tasks |
| D-006 | Max task size = 8 pts (junior developer constraint) | Requested in decomposition prompt | Some tasks (E1.08, E6.01) are at the ceiling |
| D-007 | Tauri 2 for desktop app (not Electron) | Vision specifies Tauri; smaller binary, Rust backend | If Electron required, E7.16–E7.20 need rewrite |
| D-008 | Single SQLite DB per project (not multi-project single DB) | Simpler; matches CGS pattern for per-project isolation | If multi-project single DB needed, add E1 migration task |
| D-009 | Docker is optional enhancement (Rule R1 mitigation) | Vision's risk inventory says Docker-less fallback needed | If Docker is mandatory, skip fallback tasks |
| D-010 | CLI uses Commander.js + chalk + ora | Vision Section 12 specifies these | Low impact — CLI framework is thin layer |

---

## Gaps & Risks

| # | Gap/Risk | Severity | Mitigation |
|---|----------|----------|------------|
| R-001 | 87 agent .agent.md files not decomposed into tasks | Medium | Separate task to migrate/write all 87 agent prompts. Estimated 3 days of template writing. |
| R-002 | SuperCollider/Blender CLI interfaces may be unstable | High | Pin exact versions in Dockerfiles (E2.02–E2.05). Test against CI on updates. |
| R-003 | Cross-pipeline dependency graph may have emergent deadlocks | Medium | E4.18 (critical path) includes deadlock detection. E5.03 (cycle detection) catches circular deps. |
| R-004 | 122 MCP tools is a massive API surface | High | E3 is 40 tasks but each is small (3–5 pts). Each tool is independently testable. |
| R-005 | Convergence engine (E6.01) touches every subsystem | High | Built last in the critical chain; all subsystems stable by Wave 15. Extensive E2E testing in V.01–V.04. |
| R-006 | Tauri 2 is newer and less battle-tested than Electron | Low | Dashboard is fully functional as web app; Tauri is enhancement layer only. |
| R-007 | Asset validation rules (E5.11–E5.18) need domain expertise | Medium | Rules are codified in vision Section 7; implementation is constraint checking, not AI. |
| R-008 | Store requirements change over time | Medium | `store_requirements` table is a living dataset; E8.06–E8.08 are seed data, not hardcoded logic. |
| R-009 | Playtest bots (E6.11) are the weakest link — AI playing games is hard | High | Position as "automated QA" not "fun evaluator." Bots find softlocks and exploits; fun is human-judged. |
| R-010 | Scope is enormous (198 tasks, 836 pts) | High | MVP path: E1→E3→E4 delivers a working CLI-driven orchestrator (96 tasks, 414 pts). Dashboard and desktop are enhancement layers. |

---

## Codebase Research Notes

**This is a greenfield project.** No existing codebase to research. Key design references:

1. **CGS ACP Server** (`neil-docs/tools/acp-server/`) — The battle-tested reference implementation. Same MCP protocol, same tool registration pattern, same SQLite state management. CGS-Game's server.mjs should mirror this architecture with game-specific schema.

2. **CGS Tier 1 Decomposition** (`neil-docs/CGS/sub-epics/tier1-core-extraction/DECOMPOSITION.md`) — Format reference for this document. 28 tasks, 120 pts, 14 waves.

3. **Vision Document Section 4** — Complete SQL DDL for all 26 tables. These can be used almost verbatim as migration files.

4. **Vision Document Section 5** — Complete MCP tool catalog (122 tools across 12 domains) with parameter lists. These define the exact API surface.

5. **Vision Document Appendix A** — Full agent→pipeline→container→model matrix. This is the seed data for the `agent_registry` table.

6. **Vision Document Section 8** — Dispatch engine algorithm with 5-step flow and priority scoring formula. This is the blueprint for E1.13.

7. **Vision Document Section 7** — Asset dependency graph algorithms with TypeScript pseudocode. This is the blueprint for E5.01–E5.09.

8. **Vision Document Section 6** — Pipeline state machine diagram and cross-pipeline dependency rules. This is the blueprint for E4.01–E4.18.

---

## MVP Path (Minimum Viable Product)

If scope must be cut, the MVP that delivers a working orchestration platform is:

```
E1 (Core Infrastructure) → E3 (MCP Tools) → E4 (Pipeline Engine) = 96 tasks, 414 pts

MVP delivers:
✅ SQLite database with full schema
✅ ACP server with 122 MCP tools
✅ CLI for init, status, dispatch, build, audit
✅ 9-pipeline engine with cross-pipeline deps
✅ Agent dispatch with priority scoring
✅ Basic convergence (audit→fix→re-audit)
✅ Git auto-commit on completion

MVP defers:
❌ Docker containers (agents use local tools)
❌ Asset dependency graph (manual dep tracking)
❌ Web dashboard (CLI only)
❌ Desktop app (CLI only)
❌ Store submission automation (manual)
❌ Playtest bots (manual testing)
```

---

*Decomposition version: 1.0.0 | Total: 198 tasks, 836 Fibonacci points, 24 waves, 38-task critical path*
*Next step: Hand to The Aggregator for Master Task Matrix production, then to 4-Pass Blind Ticket Pipeline for ticket generation.*
