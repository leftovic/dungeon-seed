# Task 003 — Design core gameplay systems
Short description
- Produce the system-level design and interface contracts for dungeon generation, seed growth, adventurer progression, mutation mechanics, and loot economy.

Acceptance criteria
- [ ] System design doc (`game/design/system-design.md`) approved and referenced by other tasks
- [ ] Public APIs (interfaces) for Generator, GrowthEngine, AdventurerEngine, LootEngine are specified with method signatures and expected side-effects
- [ ] Integration contract examples (sequence diagrams) provided for seed planting -> dungeon generation -> dispatch -> harvest

Phased implementation
- Phase 0: Produce design skeleton and interfaces (TDD: failing interface tests)
  - [ ] Create `game/design/system-design.md`
  - [ ] Define interfaces:
    - IGenerator: generate(seedSpec) -> DungeonSpec
    - IGrowthEngine: tick(seedId, dt) -> GrowthEvent[]
    - IAdventurerEngine: recruit(params), dispatch(party, dungeon)
    - ILootEngine: computeLoot(dungeonResult) -> LootBundle
  - Tests: InterfaceCompilationTests (ensure stubs compile)
- Phase 1: Edge-case & invariants
  - [ ] Document deterministic invariants (seed->layout), test expectations (navigable graph, difficulty monotonicity)
  - Tests: InvariantsSpec validations
- Phase 2: Playground prototypes (small GDScript stubs)
  - [ ] Implement prototype stubs for each interface with deterministic outputs for unit tests
  - Tests: PrototypeIntegration_1 (seed->dungeon mapping deterministic)
- Phase 3: Finalize for implementation handoff
  - [ ] Provide "Game Code Executor TODOs" section filled (see below)
  - CI: design lint + doc presence required

Dependencies
- Task 1 (project), Task 2 (models)

Deliverables & artifacts
- game/design/system-design.md
- game/scripts/interfaces/IGenerator.gd, IGrowthEngine.gd, IAdventurerEngine.gd, ILootEngine.gd
- test/design/InterfaceTests.gd

Estimated complexity & risks
- Complexity: 8 points
- Risk: Under-specified interfaces cause rework. Mitigate via early prototypes and integration tests.

Deterministic ID & RNG guidance
- Deterministic ID: specify where to use UUIDv5 vs HMAC for different domains (IDs for display vs idempotent content-only IDs).
- RNG test vectors:
  - Generator must produce deterministic outputs for same seed + version. Include two sample vectors:
    - Vector A: seed_str="ancient-oak|v1" -> first 10 u32 outputs: [0x1a2b3c4d, 0x5e6f7081, ...] and dungeon_hash="sha256:..."
    - Vector B: seed_str="ember-sprout|v1" -> [...]
  - Implementation note: use a seeded Xoshiro256** instance seeded from SHA256(payload).

TODOs for Game Code Executor
- Implement interface stubs and prototype deterministic generator to be used by Tasks 7 & 10
- Produce `game/design/compatibility.md` explaining expectations for save/load and RNG seeding outputs
- Expected outputs: `artifacts/design-signoff.md` with signed acceptance by lead designer

CI checks
- Documentation presence
- Interface compilation stubs tests
