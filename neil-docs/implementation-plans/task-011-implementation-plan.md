# Task 011 — Implement seed growth, mutation, progression, and unlocks
Short description
- Implement seed maturation mechanics, mutation reagent system, growth stages, unlocks, and long-term progression tie-ins.

Acceptance criteria
- [ ] Growth engine implemented with predictable stage transitions
- [ ] Mutation application deterministic given seed + reagent inputs
- [ ] Unlock tables for biomes/classes tested (unit tests for each unlock threshold)
- [ ] Integration tests with generator and loop demonstrate consistent outcomes (2 RNG vectors)

Phased implementation
- Phase 0: Growth model specification
  - [ ] Create `game/design/growth.md` with stage model, reagent effects, and capacity scaling
- Phase 1: Growth engine & state machine
  - [ ] Implement `GrowthEngine.gd` with tick(dt) and apply_reagent APIs
  - Tests: GrowthStageTransition_Basic
- Phase 2: Mutation system
  - [ ] Implement mutation slots, deterministic mutation selection, stacking rules
  - Tests: Mutation_DeterministicVectors (2)
- Phase 3: Unlock table & progression hooks
  - [ ] Implement progression manager for unlocking biomes/classes
  - Tests: UnlockThresholds
- Phase 4: Integration & balancing
  - CI: Monte Carlo progress simulation (simulate long-run progression over 500 seeds with simplified model)

Dependencies
- Tasks 7 (generator), 8 (adventurer), 9 (loot), 10 (loop)

Deliverables & artifacts
- game/scripts/growth/GrowthEngine.gd
- game/scripts/growth/MutationSystem.gd
- game/design/growth.md
- test/growth/*.gd
- artifacts/growth-sim-report.json

Estimated complexity & risks
- Complexity: 13 points
- Risks: Overpowered progression or grind; mitigate via parametric configs and Monte Carlo acceptance thresholds.

Deterministic ID & RNG test vectors (required)
- Deterministic ID: mutation instance IDs use UUIDv5(payload="seed:{seed}|mutation:{slot}")
- RNG vectors:
  - Vector 1:
    - Seed: "ancient-oak|v1", reagent="ember-sap"
    - Expected mutation outcome: {"mutation":"ember-favor","value":3}
    - Expected RNG first10: [...]
  - Vector 2:
    - Seed: "ember-sprout|v1", reagent="lunar-dust"
    - Expected mutation outcome: {...}
- Tests should assert deterministic outcomes and progression unlocking.

HMAC key management
- No direct HMAC need except for save signatures.

TODOs for Game Code Executor
- Implement GrowthEngine.gd, MutationSystem.gd with deterministic tests
- Provide fixtures under `test/fixtures/growth_vectors.json`
- Expected outputs:
  - `artifacts/growth-vector-check.json`
  - `artifacts/growth-sim-report.json`

CI checks
- Deterministic mutation vectors (2)
- Monte Carlo long-run progression smoke test
