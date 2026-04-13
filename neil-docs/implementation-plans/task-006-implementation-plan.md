# Task 006 — Implement persistence and state serialization
Short description
- Implement robust versioned save/load with migration support and integrity checks.

Acceptance criteria
- [ ] Save file format: `SaveEnvelope` used for all saves
- [ ] Round-trip tests for representative save states pass (3 sample save fixtures)
- [ ] Corrupted save detection returns graceful error and does not crash
- [ ] Save version migration test (v1->v2 stub) passes

Phased implementation
- Phase 0: Persistence API spec
  - [ ] Define `IPersistence` API: Save(playerId, SaveEnvelope) / Load(playerId) / Export()
  - Tests: IPersistence_ContractExists (failing initially)
- Phase 1: Local storage adapter
  - [ ] Implement `persistence/LocalPersistence.gd` (file-based)
  - [ ] Implement `persistence/SaveValidator.gd` (checksum + HMAC)
  - Tests: LocalPersistence_RoundTrip_SaveLoad
- Phase 2: HMAC signing + key management hooks
  - [ ] Add `security/HmacSigner.gd` which signs SaveEnvelope using HMAC_SHA256
  - [ ] Local dev uses `secrets/dev-hmac.key`; CI injects HMAC_KEY from KMS
  - Tests: Save_HasValidHmac, Load_WithInvalidHmac_FailsGracefully
- Phase 3: Cloud/Remote adapter stub & migration
  - [ ] Implement RemotePersistence stub for future backend
  - Tests: Migration_Run_V1ToV2

Dependencies
- Task 1 (project), Task 2 (schemas)

Deliverables & artifacts
- game/scripts/persistence/LocalPersistence.gd
- game/scripts/persistence/SaveValidator.gd
- game/scripts/security/HmacSigner.gd
- test/persistence/*.gd
- docs/persistence.md

Estimated complexity & risks
- Complexity: 8 points
- Risks: Data corruption and key leakage. Mitigation: HMAC checks, secret scanning, KMS.

Deterministic ID & RNG guidance
- Deterministic IDs: used in SaveEnvelope for deterministic references (seed IDs). Provide UUIDv5 test vectors:
  - Example canonical payload for save manifest: {"player":"alice","created":"2026-04-13T12:00:00Z"}
  - Test vector 1: payload -> UUIDv5 expected A (generate during initial implementation)
  - Test vector 2: payload -> HMAC_SHA256 expected hex B (CI uses production key)
- RNG test vectors (for any serialized generated dungeons):
  - Vector 1: seed=1001 -> first 10 u32 = [0x11111111,...] (placeholder; record real values in tests)
  - Vector 2: seed=2002 -> first 10 u32 = [...]

HMAC key management
- Local developer:
  - secrets/dev-hmac.key (40+ hex chars), gitignored.
  - Load via env HMAC_KEY or file fallback (never check in).
- Production:
  - Create key in KMS, grant CI read access, rotate quarterly.
  - Migration: maintain old key for 30-day validation window; re-sign saves as needed.

TODOs for Game Code Executor
- Implement LocalPersistence.gd and HmacSigner.gd
- Provide sample save fixtures in `test/fixtures/save_v1.json`
- Expected outputs: `artifacts/persistence-test-report.json` with round-trip checks & HMAC verification statuses

CI checks
- Secret scan (HMAC keys not committed)
- HMAC verification test
- Save round-trip tests (3 fixtures)
- Artifact signing of save fixtures for release builds
