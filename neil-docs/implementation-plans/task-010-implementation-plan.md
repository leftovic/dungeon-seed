# Task 010 — Build core game loop orchestration
Short description
- Implement the central orchestrator that sequences planting, growth ticks, dispatch, exploration resolution, and harvest, with save/load resilience and deterministic execution.

Acceptance criteria
- [ ] Core loop implemented as `GameLoopManager.gd` with explicit state machine and transition tests
- [ ] Dispatch -> exploration -> harvest deterministic integration tests (two vectors) pass
- [ ] Loop resilient to save/load (resume at correct state) verified by round-trip test

Phased implementation
- Phase 0: Loop API & state model
  - [ ] Define GameLoop states and transitions in `game/design/loop.md`
  - Tests: LoopStateMachine_ValidTransitions
- Phase 1: Tick & scheduler
  - [ ] Implement scheduler that processes growth ticks and dispatches events using deterministic RNG wrapper
  - Tests: GrowthTick_DeterministicVectors (2)
- Phase 2: Dispatch integration
  - [ ] Integrate with AdventurerEngine and LootEngine (stubbed if necessary)
  - Tests: DispatchEndToEnd_DeterministicVectors (2)
- Phase 3: Save/Load resilience
  - [ ] Ensure GameLoop state serializes in SaveEnvelope and resumes correctly
  - Tests: Loop_Save_Restore_PauseResume

Dependencies
- Tasks 6,7,8,9

Deliverables & artifacts
- game/scripts/loop/GameLoopManager.gd
- game/design/loop.md
- test/loop/GameLoopTests.gd
- artifacts/loop-resume-report.json

Estimated complexity & risks
- Complexity: 13 points
- Risks: Complex race conditions and non-deterministic behavior; mitigate with single-threaded deterministic scheduler and test harness.

Deterministic ID & RNG test vectors (required)
- Deterministic ID: operation IDs in loop are HMAC-signed short IDs for traceability (HMAC dev key fallback)
- RNG vectors (two required):
  - Vector 1:
    - Scenario: Player with party X dispatches seed "ancient-oak|v1" at tick T=0.
    - Expected RNG first 10 outputs for scheduler: [0x...]
    - Expected exploration summary hash: sha256:...
  - Vector 2:
    - Scenario: Different seed + party -> expected outputs
- Tests will assert scheduler outputs and final dungeon summary hash equal to expected.

HMAC key management
- GameLoopManager signs loop event receipts with HMAC to guard against tampering in remote publish scenarios.

TODOs for Game Code Executor
- Implement single-threaded deterministic scheduler, save/resume hooks
- Provide test harness scripts `tools/loop-sim --seed S --runs N`
- Expected outputs:
  - `artifacts/loop-vector-check.json`
  - `artifacts/loop-resume-check.json`

CI checks
- Deterministic vectors (2)
- Save/resume round-trip tests
- Monte Carlo smoke runs (10 seeds) for loop stability
