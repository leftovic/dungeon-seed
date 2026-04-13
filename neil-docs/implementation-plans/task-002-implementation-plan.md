# Task 002 — Define domain models, save contracts, and progression schemas
Short description
- Define serializable data models for seeds, dungeons, adventurers, loot, and player progress. Provide JSON schema prototypes and GDScript data wrappers.

Acceptance criteria
- [ ] JSON schemas for Seed, Dungeon, Adventurer, Loot, PlayerProgress exist under `game/schemas/`
- [ ] Load/save round-trip tests (serialize -> deserialize) pass for representative objects
- [ ] Versioned save contract implemented with schema version field and migration stub

Phased implementation
- Phase 0: Read GDD and align fields (TDD: failing tests listing expected fields)
  - [ ] Create `neil-docs/epics/dungeon-seed/models.md` (fields map)
- Phase 1: Add JSON schemas & canonical serialization helpers
  - [ ] Files: `game/schemas/seed.schema.json`, `dungeon.schema.json`, `adventurer.schema.json`, `loot.schema.json`, `progress.schema.json`
  - [ ] Implement `game/scripts/serialization/Serializer.gd` with canonical JSON (sorted keys)
  - Tests: SchemaValidation_RoundTrip
- Phase 2: Versioning & migrations
  - [ ] Implement `SaveEnvelope` structure: { "version": int, "payload": {...}, "meta": { "created": ISO8601 } }
  - [ ] Add migration stub `migrations/v1_to_v2.gd`
  - Tests: MigrationStub_Runs_NoCrash
- Phase 3: Integrate with persistence API (Task 6 later)
  - CI: require save/load tests to pass on headless runner

Dependencies
- Task 1 (project)
- Necessary for Tasks 6,7,8,9

Deliverables & artifacts
- game/schemas/*.schema.json
- game/scripts/serialization/Serializer.gd
- neil-docs/epics/dungeon-seed/models.md
- test/serialization/SerializerTests.gd

Estimated complexity & risks
- Complexity: 5 points
- Risks: Schema drift causing save incompatibility. Mitigate by strict versioning and migration tests.

Deterministic ID & test vector (for objects)
- Deterministic ID recommendation:
  - Use UUIDv5(namespace=UUID("6ba7b810-9dad-11d1-80b4-00c04fd430c8"), payload=CanonicalString)
  - Example canonical payload (seed):
    {"name":"Ancient Oak","rarity":"rare","planted_at": "2026-04-13T12:00:00Z"}
  - Unit test vector 1 (UUIDv5): payload->expected UUID (record real value during implementation)
  - Unit test vector 2 (HMAC_SHA256): hexkey dev -> expected hex; CI uses KMS key
- RNG vectors: not applicable here, but Serializer tests must not depend on RNG.

TODOs for Game Code Executor
- Create schema files and Serializer.gd
- Implement canonicalizer: JSON keys sorted, deterministic numeric formatting
- Expected outputs:
  - `artifacts/schema-check.json` containing validation results

CI checks
- Schema validation (JSON Schema)
- Round-trip tests passing
