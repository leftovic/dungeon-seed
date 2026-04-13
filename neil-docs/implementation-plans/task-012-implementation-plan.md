# Task 012 — Build planting/dispatch UI, dungeon rendering integration, and MVP polish
Short description
- Implement the player-facing planting/dispatch screens, integrate dungeon renderer with themes, and polish the MVP for first playable release.

Acceptance criteria
- [ ] Planting UI: plant a seed, see growth/stage UI, and observe deterministic preview data
- [ ] Dispatch UI: assemble party, dispatch to a generated dungeon, and view exploration summary
- [ ] Dungeon rendering presents generated layout (tile placement or abstract visualization)
- [ ] End-to-end playtest scenario (plant -> grow -> dispatch -> harvest) works deterministically for two seeds (RNG vectors)

Phased implementation
- Phase 0: UI integration plan
  - [ ] Map UI events to engine APIs (GameLoopManager, GrowthEngine, Generator)
  - Tests: UIBinding_PlanExists
- Phase 1: Planting & dispatch screens
  - [ ] Implement `game/scenes/PlantScreen.tscn`, `DispatchScreen.tscn`, bind to SceneManager
  - Tests: PlantingFlow_UnitTests (stubbed)
- Phase 2: Dungeon rendering integration
  - [ ] Create `DungeonRenderer.gd` that consumes `DungeonSpec` and renders tiles or schematic
  - Tests: Renderer_MapsDungeonSpecToNodes
- Phase 3: E2E deterministic playtest & polish
  - [ ] Run two deterministic playthrough vectors end-to-end and assert final summary matches expected
  - CI: E2E smoke test in headless mode (deterministic check only)
- Phase 4: Accessibility & performance polish
  - [ ] Add tooltips, text-scaling, high contrast mode; profile render speed on target baseline

Dependencies
- Tasks 4,7,10,11

Deliverables & artifacts
- game/scenes/PlantScreen.tscn, DispatchScreen.tscn
- game/scripts/ui/PlantController.gd, DispatchController.gd
- game/scripts/renderer/DungeonRenderer.gd
- test/e2e/PlaythroughTests.gd
- artifacts/e2e-playthrough-report.json

Estimated complexity & risks
- Complexity: 5 points
- Risks: Rendering performance on CI headless runners; mitigate by schematic renderer and not full physics.

Deterministic ID & RNG test vectors (required E2E)
- Deterministic ID: displayed seed IDs should match DetId output used by backend
- RNG vectors:
  - Vector 1 (E2E):
    - Seed: "ancient-oak|v1", party: ["Garr","Lila"]
    - Expected end summary hash: sha256:...
    - Expected first10 RNG outputs (scheduler & generator): [...]
  - Vector 2 (E2E):
    - Seed: "ember-sprout|v1", party: ["Miko"]
    - Expected outputs: [...]
- Tests assert exact dungeon hash and reward bundle equality.

HMAC key management
- UI should never expose raw HMAC keys. For client-side checks (if any), validate via signed receipts from server or offline verification using public verification scheme.

TODOs for Game Code Executor
- Implement PlantController.gd binding to GameLoopManager and GrowthEngine
- Implement DungeonRenderer.gd (schematic renderer for MVP)
- Provide authoritative expected vectors in `test/fixtures/e2e_vectors.json` after first authoritative run
- Expected outputs:
  - `artifacts/e2e-playthrough-report.json` (seed -> summary hash -> rewards)

CI checks
- E2E deterministic playthrough vectors (2) must pass on PRs touching UI/loop/renderer
- Performance profiling snapshot must be present on PR
