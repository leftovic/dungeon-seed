# Reconciled Ticket: Implement procedural dungeon generator and room templates

ID: task-007-gtw-reconciled

Based on: task-007-gtw-pass2.md

Summary:
DungeonGenerator requirements preserved. Reconciliation requires deterministic seed policy (deterministic IDs), canonical RNG test vectors, HMAC dev-key management & migration docs, and validation harness hooks for reachability and statistical distribution tests (see neil-docs/tickets/QUALITY-GATE-REPORT.md line 11).

Background / Evidence:
- Quality Gate Report (neil-docs/tickets/QUALITY-GATE-REPORT.md) identifies primary focus areas: deterministic ID scheme, HMAC key management, CI harness specs for probabilistic tests, and migration/rollback details.
- Current reconciled ticket noted RNG vectors and reachability hooks but lacks concrete file paths, test cases, CI metrics, and migration docs. (original brief lines: "deterministic seed salt per player, RNG test vectors, and validation harness hooks")

Requirements (concrete):
1) Deterministic ID Policy
   - Implement deterministic ID generation with canonical format: <epoch-ms>-<playerid-hex>-<counter> (example: 1672543200000-3f7a2b-00000001).
   - Module path: src/Common/Identifiers/DeterministicId.cs (or .ts/.gd for non-.NET projects).
   - Unit tests and vectors: tests/fixtures/ids/task-007-deterministic-ids.json and tests/Unit/IdPolicyTests.cs.
   - Migration note: neil-docs/migrations/ID-MIGRATION.md describing database key re-keying and back-compat strategy.

2) Canonical RNG Test Vectors
   - Add canonical vectors for the RNG used by DungeonGenerator.
   - Fixtures path: tests/fixtures/rng/task-007-canonical-vectors.json (must contain seed, algorithm name, expected first 64 bytes/ints sequence).
   - Generator implementation reference: src/Generators/Random/DungeonRng.cs (ensure PRNG algorithm name and parameters are explicit in header comments).
   - Unit test: tests/Unit/DungeonRngCanonicalTests.cs that asserts exact sequence match for each vector.

3) Reachability Validation Harness
   - Implement a harness that validates tile/room reachability for generated dungeons.
   - Suggested harness paths: tools/validation/reachability_harness/ (C#: tools/validation/reachability_harness/ReachabilityHarness.cs OR Python: tools/validation/reachability_harness/harness.py).
   - Integration test scene (Godot): tests/godot/headless/dungeon_reachability.tscn that loads the generator with a deterministic seed and asserts reachability for all objectives.
   - Output format (for QA): artifacts/reports/task-007-dungeon-<seed>.json (exportable JSON containing graph, regions, unreachable_nodes[], generation_time_ms, peak_memory_kb).

4) Exportable JSON for QA
   - Implement exporter API: src/Generators/Export/DungeonJsonExporter.cs -> writes to tests/fixtures/exported_json/<seed>.json when invoked by tests or CI.
   - JSON schema path: neil-docs/schemas/dungeon-schema-v1.json (add schema file in docs repo).

5) Memory & Performance Targets (measurable CI metrics)
   - CI measurable targets (to be enforced by job):
     - Peak memory per generation ≤ 256 MB (for a standard-gen with map size 80x80 and room templates set A).
     - Generation time 95th percentile ≤ 200 ms over 200 iterations on GitHub Actions runner (self-hosted runners may set different budgets; document in CI job).
   - CI artifact: artifacts/reports/task-007-dungeon-stats.json containing metrics (mean_ms, p50_ms, p95_ms, max_memory_kb).
   - CI job reference: .github/workflows/godot-headless-tests.yml must include a step named "task-007-dungeon-stats" which runs the headless harness and fails the job if thresholds are exceeded.

6) Statistical Distribution Tests
   - Tests must assert distribution properties for key RNG-driven outputs (e.g., room count, corridor length): tests/Statistical/DistributionTests.cs
   - Use chi-squared or Kolmogorov–Smirnov tests with a p-value threshold >= 0.01 to avoid flaky acceptance.
   - Test vector sample: tests/fixtures/rng/distribution-sample-seeds.json (N=1000 seeds) used by the CI statistical job.

7) HMAC Dev-Key Management & Migration
   - HMAC key usage: signing deterministic IDs or seed salts must use a key managed by src/Security/HmacKeyManager.cs.
   - Dev key example file: neil-docs/security/dev-hmac-key.example (never checked in with real secret).
   - Migration doc: neil-docs/security/HMAC-KEY-MIGRATION.md with step-by-step rotation, re-sign strategy, and database migration steps (including: export old signatures, re-sign with new key, phased rollout).
   - CI policy: CI pipeline must fail if any default/example key is used in runtime config or tests that are not marked as dev-only.

Acceptance Criteria (Given/When/Then style):
- AC-1 Given the canonical RNG vector file, when running DungeonRng with the provided seed, then the first 64 output integers must exactly match the vector (path: tests/Unit/DungeonRngCanonicalTests.cs uses tests/fixtures/rng/task-007-canonical-vectors.json).
- AC-2 Given 100 deterministic seeds, when running the reachability harness, then 100% of required objectives must be reachable; any failure must be listed in artifacts/reports/task-007-dungeon-<seed>.json and the CI job should fail.
- AC-3 Given 200 CI iterations, when computing performance stats, then p95 generation time ≤ 200 ms and peak memory ≤ 256 MB; CI artifact artifacts/reports/task-007-dungeon-stats.json must include these stats.
- AC-4 Given HMAC key rotation steps, when following neil-docs/security/HMAC-KEY-MIGRATION.md, then no production data integrity violation occurs and signatures validate with the new key after migration.

Test Cases (concrete):
1. Unit: IdPolicyTests
   - Path: tests/Unit/IdPolicyTests.cs
   - Test vectors: tests/fixtures/ids/task-007-deterministic-ids.json
   - Assertions: deterministic id format, collision-free for sequential counters, stable for same inputs.

2. Unit: DungeonRngCanonicalTests
   - Path: tests/Unit/DungeonRngCanonicalTests.cs
   - Vectors: tests/fixtures/rng/task-007-canonical-vectors.json
   - Assertions: exact sequence equality (first 64 ints)

3. Integration: ReachabilityIntegration (Godot headless)
   - Path: tests/Integration/ReachabilityIntegration.cs OR tests/godot/headless/dungeon_reachability.tscn
   - Runs: run headless scene with seed list tests/fixtures/rng/distribution-sample-seeds.json (N=100)
   - Assertions: all objectives reachable; write artifacts/reports/task-007-dungeon-<seed>.json per seed

4. Statistical: DistributionTests
   - Path: tests/Statistical/DistributionTests.cs
   - Dataset: tests/fixtures/rng/distribution-sample-seeds.json (N=1000)
   - Assertions: p-value >= 0.01 for key distributions

Files to add / modify (explicit paths)
- src/Common/Identifiers/DeterministicId.cs
- src/Generators/Random/DungeonRng.cs (document algorithm header)
- src/Generators/Export/DungeonJsonExporter.cs
- src/Security/HmacKeyManager.cs
- tests/Unit/IdPolicyTests.cs
- tests/Unit/DungeonRngCanonicalTests.cs
- tests/Integration/ReachabilityIntegration.cs
- tests/Statistical/DistributionTests.cs
- tests/fixtures/rng/task-007-canonical-vectors.json
- tests/fixtures/rng/distribution-sample-seeds.json
- tests/fixtures/ids/task-007-deterministic-ids.json
- tests/fixtures/exported_json/ (folder for output)
- tools/validation/reachability_harness/ReachabilityHarness.cs OR harness.py
- neil-docs/schemas/dungeon-schema-v1.json
- neil-docs/security/HMAC-KEY-MIGRATION.md
- neil-docs/migrations/ID-MIGRATION.md
- .github/workflows/godot-headless-tests.yml (ensure job step "task-007-dungeon-stats" exists and references harness)

TODO Checklist (actionable, assignable)
- [ ] Create deterministic ID module: src/Common/Identifiers/DeterministicId.cs (owner: eng-dungeon)
- [ ] Add canonical RNG vectors: tests/fixtures/rng/task-007-canonical-vectors.json (owner: eng-dungeon + QA)
- [ ] Implement DungeonRng canonical assertions: tests/Unit/DungeonRngCanonicalTests.cs (owner: eng-test)
- [ ] Implement reachability harness and Godot headless scene: tools/validation/reachability_harness/ + tests/godot/headless/dungeon_reachability.tscn (owner: eng-dungeon)
- [ ] Implement exporter to JSON: src/Generators/Export/DungeonJsonExporter.cs (owner: eng-dungeon)
- [ ] Add statistical distribution tests and sample seeds: tests/Statistical/DistributionTests.cs (owner: eng-data)
- [ ] Add HMAC key manager and migration doc: src/Security/HmacKeyManager.cs + neil-docs/security/HMAC-KEY-MIGRATION.md (owner: security)
- [ ] Update CI workflow: .github/workflows/godot-headless-tests.yml to include step "task-007-dungeon-stats" that runs harness and uploads artifacts (owner: infra)
- [ ] Add JSON schema: neil-docs/schemas/dungeon-schema-v1.json (owner: docs)

Security & Migration Notes (must-follow)
- Never commit real HMAC keys. Commit neil-docs/security/dev-hmac-key.example and ensure secrets are injected in CI via repository secrets (GH Actions secrets or Vault).
- The migration doc must include a safe rollback: preserve old signatures until new-signed data is fully verified by canary rollouts.

Implementation Prompt (for AI/coding agent)
- Create/modify files listed above. Use existing project PRNG if available; otherwise, adopt xoshiro256** with documented parameters and a seed-derivation function: seed = HMAC_SHA256(hmac_key, concat(project_namespace, seed_input)) % (2^64).
- Tests must be deterministic: use test-only dev-hmac-key loaded from neil-docs/security/dev-hmac-key.example during tests.
- Add CI headless job that runs: dotnet test (or project test runner) then run the headless harness with 200 deterministic seeds and fail if p95 > 200 ms or peak memory > 256 MB. Upload artifacts to GitHub Actions for post-failure inspection.

Acceptance / Exit criteria for Quality Gate Re-run
- All files above added/modified and referenced tests pass locally and in CI
- CI produces artifacts/reports/task-007-dungeon-stats.json with mean/p50/p95 and peak memory fields
- Review re-run returns weighted score ≥92 for task-007

References
- neil-docs/tickets/QUALITY-GATE-REPORT.md (see key outcome items)


Please use the file paths above in your implementation. If any path conflicts with repo language (C#/Godot/GDScript), adapt file extensions accordingly but keep the same directory structure and filenames.
