# Epic: Dungeon Seed

> **Status**: In Progress
> **Created**: 2026-04-12
> **Priority**: P2
> **Total Tasks**: 12
> **Complexity**: 96

## Task Dependency Graph

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

## Task Registry

| # | Task Name | Complexity | Dependencies | Ticket | Plan | Status | QA | Audit | Bugs | Loops |
|---|-----------|-----------|-------------|--------|------|--------|----|-------|------|-------|
| 1 | Set up Godot project with basic scenes | 5 | None | ⬜ | ⬜ | ⬜ Not Started | ⬜ Pending | ⬜ Pending | — | — |
| 2 | Define domain models, save contracts, and progression schemas | 5 | Task 1 | ⬜ | ⬜ | ⬜ Not Started | ⬜ Pending | ⬜ Pending | — | — |
| 3 | Design core gameplay systems | 8 | Task 1 | ⬜ | ⬜ | ⬜ Not Started | ⬜ Pending | ⬜ Pending | — | — |
| 4 | Design UI/UX framework and visual themes | 5 | Task 1 | ⬜ | ⬜ | ⬜ Not Started | ⬜ Pending | ⬜ Pending | — | — |
| 5 | Define audio and lore foundation | 5 | Task 1 | ⬜ | ⬜ | ⬜ Not Started | ⬜ Pending | ⬜ Pending | — | — |
| 6 | Implement persistence and state serialization | 8 | Tasks 1,2 | ⬜ | ⬜ | ⬜ Not Started | ⬜ Pending | ⬜ Pending | — | — |
| 7 | Implement procedural dungeon generator and room templates | 13 | Tasks 2,3 | ⬜ | ⬜ | ⬜ Not Started | ⬜ Pending | ⬜ Pending | — | — |
| 8 | Implement adventurer management and recruitment engine | 13 | Tasks 2,3 | ⬜ | ⬜ | ⬜ Not Started | ⬜ Pending | ⬜ Pending | — | — |
| 9 | Implement loot economy and reward systems | 8 | Tasks 2,3 | ⬜ | ⬜ | ⬜ Not Started | ⬜ Pending | ⬜ Pending | — | — |
| 10 | Build core game loop orchestration | 13 | Tasks 6,7,8,9 | ⬜ | ⬜ | ⬜ Not Started | ⬜ Pending | ⬜ Pending | — | — |
| 11 | Implement seed growth, mutation, progression, and unlocks | 13 | Tasks 7,8,9 | ⬜ | ⬜ | ⬜ Not Started | ⬜ Pending | ⬜ Pending | — | — |
| 12 | Build planting/dispatch UI, dungeon rendering integration, and MVP polish | 5 | Tasks 4,7,10,11 | ⬜ | ⬜ | ⬜ Not Started | ⬜ Pending | ⬜ Pending | — | — |

*QA column shows: ⬜ Pending | ✅ All Pass (pass/total) | 🐛 N bugs (pass/total) | ⬜ N/A (no UI/opted out)*

## Artifact Paths

| Artifact | Path |
|----------|------|
| Epic Brief | `neil-docs/epics/dungeon-seed/APPROVED-EPIC-BRIEF.md` |
| GDD | `neil-docs/epics/dungeon-seed/GDD.md` |
| Decomposition | `neil-docs/epics/dungeon-seed/DECOMPOSITION.md` |
| Tickets | `neil-docs/tickets/task-{NNN}-*.md` |
| Plans | `neil-docs/implementation-plans/dungeon-seed/task-{NNN}-plan.md` |
| QA Test Plans | `neil-docs/qa-test-plans/dungeon-seed/task-{NNN}-qa-plan.md` |
| QA Test Results | `neil-docs/qa-test-results/dungeon-seed/task-{NNN}-results-{date}.md` |
| Bug Log | `neil-docs/qa-test-results/dungeon-seed/BUG-LOG.md` |
| Audit Reports | `neil-docs/audit-reports/task-{NNN}-audit.md` |
| Epic Audit | `neil-docs/audit-reports/dungeon-seed-epic-audit.md` |

## Epic Audit

| Dimension | Score | Notes |
|-----------|-------|-------|
| Cross-Task Consistency | ⬜ | |
| Integration Completeness | ⬜ | |
| Dependency Satisfaction | ⬜ | |
| Scope Fidelity | ⬜ | |
| End-to-End Validation | ⬜ | |
| **Epic Verdict** | ⬜ | |

## Session Log

| Date | Session | What Happened |
|------|---------|--------------|
| 2026-04-12 | 1 | Restarted the Dungeon Seed epic from the pitch with a fresh GDD and decomposition |</content>
<parameter name="filePath">c:\Users\wrstl\source\dev-agent-tool\neil-docs\epics\dungeon-seed\EPIC-TRACKER.md