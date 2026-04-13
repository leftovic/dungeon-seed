# Title: Define domain models, save contracts, and progression schemas

ID: task-002-gtw-pass2

## Objective
Produce authoritative data models and serializable contracts for seeds, dungeons, adventurers, inventory, and progression. Deliver JSON schema prototypes and a versioning plan for save migration.

## Background
The GDD defines seed attributes, dungeon graphs, adventurer stats, loot types, and progression expectations. A precise schema is required to ensure deterministic dungeon generation, robust persistence, and testable simulations (addresses R-002 and R-003).

## Detailed Requirements
- Provide JSON Schema (or .tres) for Seed, DungeonInstance, Room, Adventurer, Inventory, and PlayerProfile with field types and optionality.
- Versioning strategy: include `schema_version` on root save and migration helper functions.
- Deterministic ID scheme for seed instances (UUID v4 + seeded RNG salt) and dungeon random seeds for reproducibility.
- Document sample save file with all fields populated for automated compatibility tests.
- Provide serialization helpers and unit tests for round-trip save/load fidelity.

## Acceptance Criteria
- [ ] Schemas committed under res://config/schemas/ and in docs.
- [ ] Round-trip serialization test passes for 10 representative objects.
- [ ] Migration plan documented for v0→v1 schema changes.

## Security considerations
- Design schemas to avoid injection by treating player data as data-only; validate all fields during load.
- Include schema-version checks to avoid deserialization mismatches.

## Performance targets
- Serialization/deserialization round-trip for full player state completes <200ms on reference PC.
- Save file size target: <1MB for typical player state; provide compression option if larger.

## UX notes
- Expose save/load feedback to players (saving indicator, last saved timestamp).
- Provide a 'restore defaults' and 'export/import save' dev option (hidden behind dev toggle).

## Edge cases
- Corrupt save: surface a Recover or Revert option; allow user to revert to last good checkpoint.
- Schema mismatch: provide migration assistant and clear messaging.

## Data Contracts
- res://config/schemas/seed.schema.json
- res://config/schemas/dungeon_instance.schema.json
- res://config/schemas/adventurer.schema.json
- res://config/schemas/player_profile.schema.json

## Integration points
- SaveManager (Task 6) will consume these schemas.
- DungeonGenerator uses Seed and Mutation fields from these contracts.
- AdventurerManager maps to adventurer.schema.json.

## QA test plan
- Unit tests for serialization round-trip covering seeds, dungeons, and adventurers.
- Schema validation tests for sample save files.

## Metrics
- Serialization round-trip success rate.
- Average save file size.

## Rollback criteria
- If schema commits break backward compatibility with existing saves and migration is non-trivial, revert to last known-good schema and place migration in a separate hotfix branch.

## Dependencies
- Depends on Task 1 (project scaffold); consumers: Tasks 6,7,8,9.

## Complexity estimate
- Fibonacci: 5 pts (Design/Foundation)

