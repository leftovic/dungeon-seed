# Task 008 — Implement adventurer management and recruitment engine
Short description
- Implement adventurer roster, recruitment flows, leveling, ability unlocks, equipment slots, and serialization.

Acceptance criteria
- [ ] Adventurer model implemented and serializable
- [ ] Recruitment flow API implemented with deterministic random outcomes when seeded
- [ ] Adventurer leveling and XP tests exist (edge cases: level cap, overflow)
- [ ] Integration test: dispatching a deterministic party produces deterministic combat result summary (stubbed)

Phased implementation
- Phase 0: Model & interfaces
  - [ ] Implement `Adventurer` model per schema
  - Tests: Adventurer_RoundTrip_Serializable
- Phase 1: Recruitment & roster
  - [ ] Implement `RecruitmentEngine.gd` with deterministic recruit(seed, candidatePool)
  - Tests: Recruitment_DeterministicVectors (2 vectors)
- Phase 2: Leveling & abilities
  - [ ] Implement XP/Level progression, skill unlock table
  - Tests: Leveling_EdgeCases
- Phase 3: Dispatch and combat stub integration
  - [ ] Implement dispatch API hooking into generator (Task 7) and loot engine (Task 9)
  - Tests: DispatchIntegration_DeterministicOutcome (stubbed combat)

Dependencies
- Task 2 (models), Task 3 (design), Task 7 (generator integration for deterministic dispatch)

Deliverables & artifacts
- game/scripts/adventurers/Adventurer.gd
- game/scripts/adventurers/RecruitmentEngine.gd
- game/scripts/adventurers/DispatchManager.gd
- test/adventurers/*.gd

Estimated complexity & risks
- Complexity: 13 points
- Risks: Non-deterministic recruitment outcomes. Mitigate by seeding recruitment RNG with canonical inputs (playerId|timestamp|seed).

Deterministic ID & RNG test vectors
- Deterministic ID usage: hero IDs use HMAC_SHA256 with canonical payload for privacy (e.g., to avoid leaking player-public data)
  - Vector: payload {"player":"bob","name":"Garr"} -> expected HMAC hex (generate in CI)
- RNG recruitment vectors (2):
  - Vector 1: seed="player1|recruit|42" -> expected recruit result list (names/classes)
  - Vector 2: seed="player1|recruit|43" -> expected list
- Combat stub outcome vector for integration test (1 seed -> deterministic summary hash)

HMAC key management
- Recruitment uses HMAC only for ID generation; do not use keys for core RNG.

TODOs for Game Code Executor
- Implement RecruitmentEngine.gd with seeding strategy and test fixtures
- Implement DispatchManager.gd that calls Generator and LootEngine stub
- Expected outputs: `artifacts/recruitment-vectors.json`, `artifacts/dispatch-stub-report.json`

CI checks
- Recruitment deterministic tests
- Adventurer serialization round-trip
- Secret scanning for dev HMAC key
