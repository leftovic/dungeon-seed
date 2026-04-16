# Epic: Dungeon Seed

> **Status**: 🟢 IN PROGRESS — Pipeline v2 executing  
> **Created**: 2026-04-12  
> **Updated**: 2026-04-14  
> **Priority**: P2  
> **Total Tasks**: 22 (DECOMPOSITION-v2)  
> **Total Points**: 152  
> **Waves**: 6  
> **Pipeline Rulebook**: [GAME-DEV-PIPELINE.md](./GAME-DEV-PIPELINE.md)

## Pipeline Status

### v2 Pipeline (Current)
- ✅ Game Vision Architect → GDD-v2.md, GDD-v3.md
- ✅ The Decomposer → DECOMPOSITION-v2.md (22 tasks, 6 waves, 152pts)
- ✅ Game Ticket Writer → TASK-001 through TASK-014 tickets
- ✅ Implementation Plan Builder → TASK-001 through TASK-014 plans
- ✅ **Wave 1 complete** — Bootstrap, RNG, Enums & GameConfig (TASK-001/002/003)
- ✅ **Wave 2 complete** — Data Models, Economy, Save Service (TASK-004 through TASK-009)
- ✅ **Wave 3 complete** — Generators & Managers (TASK-010 through TASK-014) — 866 tests passing

### Pre-Pipeline Code (Legacy)
Existing code at `src/gdscript/` and `tests/unit/` was written without specialist oversight (sessions 1-9).
Code review found 3 critical bugs. Gap analysis found ~40% GDD coverage.
This code is NOT trusted. Clean v2 code lives in `src/models/`, `src/services/`, `tests/models/`, `tests/services/`.

## 🔴 Pipeline Rule

**ALL work MUST be produced by specialist subagents via `task()` calls.**  
The orchestrator delegates only — never writes code, tickets, plans, or assets directly.  
See GAME-DEV-PIPELINE.md for the full agent-to-stage mapping.

## Task Registry (v2 Decomposition)

### Wave 1 — Foundation ✅
| # | Task Name | Pts | Dependencies | Ticket | Plan | Code | Audit |
|---|-----------|-----|-------------|--------|------|------|-------|
| 001 | Project Bootstrap | 3 | None | ✅ | ✅ | ✅ | ✅ |
| 002 | Deterministic RNG | 5 | TASK-001 | ✅ | ✅ | ✅ | ✅ |
| 003 | Enums & GameConfig | 5 | TASK-001 | ✅ | ✅ | ✅ | ✅ |

### Wave 2 — Data Models ✅
| # | Task Name | Pts | Dependencies | Ticket | Plan | Code | Audit |
|---|-----------|-----|-------------|--------|------|------|-------|
| 004 | Seed Data Model | 8 | TASK-003 | ✅ | ✅ | ✅ | ✅ PASS |
| 005 | Dungeon Room Graph | 5 | TASK-003 | ✅ | ✅ | ✅ | ✅ PASS (79 tests) |
| 006 | Adventurer Model | 5 | TASK-003 | ✅ | ✅ | ✅ | ✅ PASS (100+ tests) |
| 007 | Item/Equipment/Inventory | 5 | TASK-003 | ✅ | ✅ | ✅ | ✅ PASS (145+ tests) |
| 008 | Economy Wallet & Ledger | 5 | TASK-003 | ✅ | ✅ | ✅ | ✅ PASS (115+ tests) |
| 009 | Save/Load Manager | 8 | TASK-003 | ✅ | ✅ | ✅ | ✅ PASS (52 tests) |

### Wave 3 — Generators & Managers ✅
| # | Task Name | Pts | Dependencies | Ticket | Plan | Code | Audit |
|---|-----------|-----|-------------|--------|------|------|-------|
| 010 | Dungeon Generator | 13 | TASK-004,005 | ✅ | ✅ | ✅ | ✅ PASS (682 lines) |
| 011 | Loot Table Engine | 8 | TASK-007,008 | ✅ | ✅ | ✅ | ✅ PASS (292+108 lines) |
| 012 | Seed Grove Manager | 8 | TASK-004 | ✅ | ✅ | ✅ | ✅ PASS (455 lines, 650 test lines) |
| 013 | Adventurer Roster | 8 | TASK-006 | ✅ | ✅ | ✅ | ✅ PASS (336 lines, 704 test lines) |
| 014 | Equipment System | 5 | TASK-006,007 | ✅ | ✅ | ✅ | ✅ PASS (241 lines, 661 test lines) |

### Wave 4 — Core Loop ⬜
| # | Task Name | Pts | Dependencies | Ticket | Plan | Code | Audit |
|---|-----------|-----|-------------|--------|------|------|-------|
| 015 | Expedition Runner | 13 | TASK-010,011,013,014 | ⬜ | ⬜ | ⬜ | ⬜ |
| 016 | Core Loop Orchestrator | 8 | TASK-012,015 | ⬜ | ⬜ | ⬜ | ⬜ |

### Wave 5 — UI & Presentation ⬜
| # | Task Name | Pts | Dependencies | Ticket | Plan | Code | Audit |
|---|-----------|-----|-------------|--------|------|------|-------|
| 017 | Grove UI | 5 | TASK-012,016 | ⬜ | ⬜ | ⬜ | ⬜ |
| 018 | Expedition UI | 5 | TASK-015,016 | ⬜ | ⬜ | ⬜ | ⬜ |
| 019 | Inventory & Equipment UI | 5 | TASK-007,014 | ⬜ | ⬜ | ⬜ | ⬜ |
| 020 | HUD & Notifications | 5 | TASK-016 | ⬜ | ⬜ | ⬜ | ⬜ |

### Wave 6 — Integration & Polish ⬜
| # | Task Name | Pts | Dependencies | Ticket | Plan | Code | Audit |
|---|-----------|-----|-------------|--------|------|------|-------|
| 021 | Scene Router & Flow | 5 | TASK-017,018,019,020 | ⬜ | ⬜ | ⬜ | ⬜ |
| 022 | MVP Integration & Polish | 8 | TASK-021 | ⬜ | ⬜ | ⬜ | ⬜ |

## Artifact Paths (v2)

| Artifact | Path |
|----------|------|
| GDD v2 | `neil-docs/epics/dungeon-seed/GDD-v2.md` |
| GDD v3 | `neil-docs/epics/dungeon-seed/GDD-v3.md` |
| Decomposition v2 | `neil-docs/epics/dungeon-seed/DECOMPOSITION-v2.md` |
| Pipeline Rulebook | `neil-docs/epics/dungeon-seed/GAME-DEV-PIPELINE.md` |
| Tickets (v2) | `neil-docs/epics/dungeon-seed/tickets-v2/TASK-{NNN}-*.md` |
| Plans (v2) | `neil-docs/epics/dungeon-seed/plans-v2/TASK-{NNN}-plan.md` |
| Source (models) | `src/models/*.gd` |
| Source (services) | `src/services/*.gd` |
| Tests (models) | `tests/models/*.gd` |
| Tests (services) | `tests/services/*.gd` |

## Session Log

| Date | Session | What Happened |
|------|---------|--------------|
| 2026-04-12 | 1 | Restarted the Dungeon Seed epic from the pitch with a fresh GDD and decomposition |
| 2026-04-12-13 | 2-8 | Pre-pipeline implementation: All 12 tasks implemented directly. All tests passing. |
| 2026-04-13 | 9 | Created GAME-DEV-PIPELINE.md rulebook. Transitioned to pipeline-driven development. |
| 2026-04-13 | 10 | **PIPELINE COMPLIANCE AUDIT & FULL RESTART.** All prior work marked untrusted. Dispatched Game Vision Architect for proper GDD. |
| 2026-04-13 | 11+ | v2 pipeline execution: GDD-v2, DECOMPOSITION-v2, tickets/plans written by specialist agents. Wave 1 implemented and committed. |
| 2026-04-14 | — | **Wave 2 complete.** 6 tasks (TASK-004→009) audited and committed. 490+ unit tests across 11 models + save service. All audits PASS. |

## Next Steps

1. **Wave 3** (TASK-010 through TASK-014): Tickets and plans already exist. Implementation files for TASK-010/011 may exist as untracked drafts — audit before committing.
2. **Wave 4-6** (TASK-015 through TASK-022): Tickets and plans need to be written by specialist agents.</content>
<parameter name="filePath">c:\Users\wrstl\source\dev-agent-tool\neil-docs\epics\dungeon-seed\EPIC-TRACKER.md