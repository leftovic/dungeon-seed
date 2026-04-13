# Dungeon Seed — MASTER Implementation Plan
Agent run: impl-plan-builder-dungeon-seed-regen
Created: 2026-04-13
Status: Planning
Repo: C:\Users\wrstl\source\dev-agent-tool
Branch suggestion: users/impl-plan-builder/dungeon-seed-regen
Methodology: TDD Red-Green-Refactor
Estimated total complexity: 96 points (per decomposition)
Estimated phases (waves): 3 (Foundation, Core Implementation, Integration & MVP)

Summary
- This master plan synthesizes all 12 per-task implementation plans into coordinated waves, maps the critical path, prescribes CI and deterministic-quality gates (UUID/HMAC deterministic IDs, RNG test vectors), and lists files to create under neil-docs/implementation-plans/.
- Keep every phase green: each phase must end with a passing test suite and a single, concise commit.

High-level Wave & Phase Map
- Wave 1 — Foundation (Tasks 1–5)
  - Phase 0 (Repo/Branch/CI bootstrap)
  - Phase 1 (Godot project, basic scenes)
  - Phase 2 (Domain models & design docs)
- Wave 2 — Core Implementation (Tasks 6–9)
  - Phase 3 (Persistence, generation, heroes, economy)
  - Phase 4 (Unit & integration tests for subsystems)
- Wave 3 — Integration & MVP (Tasks 10–12)
  - Phase 5 (Core loop orchestration + seed mechanics)
  - Phase 6 (UI integration, rendering, end-to-end validation)
  - Phase 7 (Polish, performance, release candidate)

Critical Path (execute with priority)
- Task 1 → Task 7 → Task 10 → Task 11 → Task 12
- Maintain dev pairs on Task 7 (dungeon gen) + Task 10 (loop) to prevent blocking.

Assignment suggestions
- Team A (Engine & Build): Task 1, CI harness, headless Godot
- Team B (Core Systems): Task 2,3,6,7
- Team C (Gameplay & Econ): Task 8,9,11
- Team D (UI/UX/Audio/Polish): Task 4,5,12
- Rotation: pair a core-team member to Task 10 during Wave 2 → Wave 3.

CI / Harness Requirements (must exist before Phase 1 commit)
- Headless Godot test runner configured (Godot 4.x headless export/--test)
- Deterministic seed test harness:
  - Exposes RNG seeding API so unit tests call SeededRandom(seed).next() reproducibly.
  - Provide wrapper for Xoshiro256** and Godot RandomNumberGenerator (RNG) with seeded deterministic output across platforms.
- Deterministic ID library:
  - Provide utility `DetId.GenerateUUIDv5(namespace:UUID, payload:string)` and `DetId.HmacSha256(hexKey, payload)` with canonical payload canonicalization.
- Monte Carlo smoke harness:
  - CLI tool that runs N deterministic seeds with given hardware baseline note, sample: `mono-montecarlo --seeds-file seeds.txt --runs 100 --max-time 60s`.
  - Export deterministic artifact: seed -> summary hash (SHA256 of first 32 RNG outputs).
- Secrets & HMAC management in CI:
  - Local-dev fallback: look for env var HMAC_KEY; if absent load `secrets/dev-hmac.key` (gitignored).
  - Production: use KMS (Azure Key Vault / AWS KMS) — steps below.

Quality Gate fixes (apply across tasks)
1. Deterministic ID schema
   - Prefer UUIDv5 (namespace + canonical payload) for human-readable deterministic IDs when collision domain is name-like (seed names, template names).
   - For high-security deterministic IDs (e.g., signed tokens of content), use HMAC_SHA256(payload, key) hex (lowercase) with canonical JSON payload (sorted keys, no whitespace).
   - Canonical payload example for unit tests:
     {"seed_id":"ancient-oak","growth_stage":2}
   - UUIDv5 example: namespace = UUID("6ba7b810-9dad-11d1-80b4-00c04fd430c8")
     - Test vector 1 (UUIDv5): payload="seed:ancient-oak|2" -> expected: 3fa85f64-5717-4562-b3fc-2c963f66afa6 (replace with team-approved vector during implementation).
     - HMAC_SHA256 example: hexkey = "0f1e2d3c4b5a69788796a5b4c3d2e1f0"
       - payload canonical JSON -> expected hex: "a1b2c3...". (Placeholders; devs must generate authoritative vectors in first-phase tests.)
   - Unit policy: include both UUIDv5 and HMAC tests where applicable.

2. RNG & Generation test vectors
   - Provide two test vectors per generation-using module (seed -> deterministic outputs).
   - Recommend Xoshiro256** for performance and high-quality randomness; provide Godot RNG wrapper for parity tests.
   - Test vector format: Seed (uint64 or deterministic string) -> first 10 u32 outputs (hex) and overall dungeon hash (SHA256).
   - Example vector format in tests: assert SequenceEquals( expected[], Generator(seed).NextU32(10) ).
   - Include fallbacks: if engine RNG behavior differs between platforms, tests rely on the library wrapper, not engine internals.

3. HMAC Key Management recommendation
   - Local dev: store `secrets/dev-hmac.key` (40 bytes hex) gitignored; CI reads from secure variable `HMAC_KEY`.
   - Production: use KMS with rotation; CI retrieves HMAC_KEY from KMS at job start. Steps:
     1. Create key in KMS (production alias: projects/dungeon-seed/hmac-key)
     2. Grant CI service principal read-only access
     3. CI job fetches and stores in ephemeral env var HMAC_KEY (never written to logs)
     4. To rotate: create new key, run migration job that re-signs ephemeral tokens if needed; keep old key for verification grace period (30 days).
   - Migration path: include a migration job that, on deploy, verifies existing HMAC-signed assets using old keys and re-issues using new key if required. Log transitional mapping.

CI checklist (mandatory for every PR touching game systems)
- [ ] Secret scanning (Snyk/Trufflehog)
- [ ] Headless Godot unit tests (run with --test or headless export)
- [ ] Deterministic RNG tests & generation test vectors (2 vectors)
- [ ] Deterministic ID tests (UUIDv5 + HMAC_SHA256)
- [ ] Artifact signing: sign builds with CI signing key, publish signature alongside artifact
- [ ] Monte Carlo smoke runs (10 deterministically seeded runs) for any PR touching generator/loop code
- [ ] Performance baseline check (timing for core loop on CI runner class; fail if regression > 20%)

Files to create under neil-docs/implementation-plans/
- MASTER-implementation-plan.md
- task-001-implementation-plan.md
- task-002-implementation-plan.md
- task-003-implementation-plan.md
- task-004-implementation-plan.md
- task-005-implementation-plan.md
- task-006-implementation-plan.md
- task-007-implementation-plan.md
- task-008-implementation-plan.md
- task-009-implementation-plan.md
- task-010-implementation-plan.md
- task-011-implementation-plan.md
- task-012-implementation-plan.md

Progress & Governance rules
- Each phase completion requires:
  - Passing tests on CI
  - Single commit with message: "Phase X: {short description} — {# tests passing}"
  - Update progress table in per-task plan (manually) and link PR to ticket
- Deviation policy: Add deviation entry to plan if implementation differs from ticket (why, impact, revert path).

Quick start (for new developer)
1. Read this MASTER file
2. Read the specific task-00X plan for assigned work
3. Checkout branch: users/impl-plan-builder/dungeon-seed-regen
4. Build & run Godot headless tests:
   - dotnet-like example: (project-specific) use Godot CLI: `godot --headless --script res://test_runner.gd --run-tests`
5. Run deterministic generator tests: `./tools/gen-test --seed 42 --count 10`
6. Before PR: ensure CI checklist is green.
