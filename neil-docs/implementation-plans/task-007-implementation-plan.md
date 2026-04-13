# Task 007 — Implement procedural dungeon generator and room templates
Short description
- Build deterministic dungeon generation engine: seed → layout pipeline, room templates, connectivity validation, and theme application.

Acceptance criteria
- [ ] Generator API implemented: `Generator.generate(seedSpec) -> DungeonSpec`
- [ ] Two deterministic test vectors validate generator output (first 10 RNG outputs and dungeon hash)
- [ ] Generated dungeon passes navigability checks (path exists between entrance and exit)
- [ ] Room templates for combat/treasure/puzzle/rest present and selectable by theme

Phased implementation
- Phase 0: Interface & prototype deterministic generator
  - [ ] Implement `game/scripts/generator/IGenerator.gd` and `PrototypeGenerator.gd` returning deterministic structure for seed strings
  - Tests: Prototype_Generator_IsDeterministic
- Phase 1: RNG wrapper & seeding strategy
  - [ ] Implement `utils/SeededRNG.gd` (wrap Xoshiro256** seeded by SHA256(payload))
  - Tests: SeededRNG_First10MatchesTest (2 vectors)
- Phase 2: Room templates & layout algorithms
  - [ ] Implement room templates folder and selection logic
  - [ ] Implement graph builder, connectivity repair, and difficulty scaler
  - Tests: Dungeon_Navigability_Test, RoomTemplate_Distribution_Test
- Phase 3: Theme integration & output serialization
  - [ ] Apply theme tokens from Task 4 into generated dungeon metadata
  - Tests: Dungeon_ThemeConsistency_Test (2 sample seeds)
- Phase 4: Performance & Monte Carlo validation
  - [ ] Run Monte Carlo harness (100 seeds) and assert no layout failures > 0.5%
  - CI: Monte Carlo smoke runs

Dependencies
- Task 1 (project), Task 2 (models), Task 3 (design)

Deliverables & artifacts
- game/scripts/generator/PrototypeGenerator.gd
- game/scripts/generator/Generator.gd (final)
- game/scripts/generator/SeededRNG.gd
- game/data/room_templates/*.json
- test/generator/GeneratorTests.gd
- artifacts/generator-montecarlo-report.json

Estimated complexity & risks
- Complexity: 13 points
- Risks: Non-deterministic behavior across platforms and navigability bugs. Mitigate via wrapper RNG and robust layout validation.

Deterministic ID & RNG test vectors (must be included in tests)
- Deterministic ID: Dungeon tile/room IDs use UUIDv5(namespace: DUNGEON_NAMESPACE_UUID, payload: canonical "dungeon:{seed}|room:{index}")
  - Unit vector: payload "dungeon:ancient-oak|room:0" -> UUIDv5 expected (recorded on first-run authoritative)
- RNG test vectors (implementers: derive from SeededRNG using SHA256(seedString) → seed state)
  - Vector 1:
    - Seed string: "ancient-oak|v1"
    - Expected first 10 u32 (example placeholders — replace during implementation):
      [0x1a2b3c4d,0x5e6f7081,0x9a0b1c2d,0x3e4f5061,0x7a8b9c0d,0x11223344,0x55667788,0x99aabbcc,0xddeeff00,0x01020304]
    - Dungeon hash (SHA256 of canonical dungeon spec): sha256:abcdef...
  - Vector 2:
    - Seed string: "ember-sprout|v1"
    - Expected first 10 u32: [...]
  - Test harness must compute hash and compare to stored expected vector.

HMAC key management note
- Save validator must verify generator version metadata with HMAC when embedding generation provenance in saved dungeons.

TODOs for Game Code Executor
- Implement SeededRNG.gd (Xoshiro256**), PrototypeGenerator.gd, room template selection, connectivity repair
- Provide deterministic test fixture seeds and expected vector files under `test/fixtures/generator_vectors.json`
- Expected outputs:
  - `artifacts/generator-vector-check.json` (seed -> first10 -> dungeon_sha)
  - `artifacts/generator-montecarlo-report.json`

CI checks
- Deterministic vector tests (2 vectors) must pass
- Monte Carlo smoke (10 seeds) on PRs touching generator
- Performance regression check: average generation time < threshold (document in CI)
