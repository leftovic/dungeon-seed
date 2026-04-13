# Task 009 — Implement loot economy and reward systems
Short description
- Implement loot tables, rarity tiers, resource sinks, drop scaling by dungeon difficulty, and inventory credit systems.

Acceptance criteria
- [ ] LootEngine API implemented with deterministic drop tables for seeded runs
- [ ] Drop scaling tests (difficulty -> expected reward range) pass
- [ ] Economy invariants: no free infinite-sink exploit in Monte Carlo smoke tests (basic checks)

Phased implementation
- Phase 0: Loot table spec & schema
  - [ ] Create `game/data/loot_tables/*.json` and `loot.schema.json`
- Phase 1: Loot engine implementation
  - [ ] Implement `LootEngine.gd` with deterministic seeded outcomes
  - Tests: LootVectors_Seeded (2 vectors)
- Phase 2: Economy sinks & balancing hooks
  - [ ] Implement sinks (upgrade costs, mutation reagent prices)
  - Tests: Sink_Payback_Ratio_Basics
- Phase 3: Integration & analytics hooks
  - [ ] Emit telemetry on rewards (for later Game Analytics)
  - CI: Monte Carlo (50 seeds) check for expected distribution statistics

Dependencies
- Task 2 (models), Task 7 (dungeon difficulty mapping), Task 8 (adventurer rewards)

Deliverables & artifacts
- game/scripts/loot/LootEngine.gd
- game/data/loot_tables/*.json
- test/loot/LootTests.gd

Estimated complexity & risks
- Complexity: 8 points
- Risks: Unbalanced economy. Mitigate via parameterized configs and Monte Carlo acceptance thresholds.

Deterministic ID & RNG test vectors
- Deterministic ID: Loot item stable IDs are UUIDv5 based on (lootTemplateId|seed|index)
- RNG vectors:
  - Vector 1:
    - Input seed: "ancient-oak|dungeon-run|1001"
    - Expected drop list: ["gold:120","essence:4","artifact:0"]
  - Vector 2:
    - Input seed: "ember-sprout|dungeon-run|2002"
    - Expected drop list: [...]
- Tests must assert both content and assortment probabilities (deterministic in seeded runs).

HMAC key management
- No HMAC requirement beyond persistence signatures.

TODOs for Game Code Executor
- Implement LootEngine.gd, sample loot tables, and deterministic test fixtures
- Expected outputs: `artifacts/loot-vector-check.json`, `artifacts/economy-montecarlo.json`

CI checks
- Deterministic drop vectors (2)
- Monte Carlo distribution sanity checks
