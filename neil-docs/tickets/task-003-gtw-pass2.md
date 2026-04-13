# Title: Design core gameplay systems

ID: task-003-gtw-pass2

## Objective
Design the core gameplay systems (seed growth, procedural dungeon mapping, mutation mechanics, adventurer progression, and loot economy) into a coherent, data-driven architecture with clear interfaces and tuning knobs.

## Background
The GDD outlines the macro/micro loops and key systems. This task produces system diagrams, data flow, and deterministic rules that downstream implementers (generator, adventurer engine, economy) will follow.

## Detailed Requirements
- Produce a system-level design doc (res://docs/system_design.md) covering: seed→dungeon pipeline, mutation hooks, adventurer lifecycle, and economy interactions.
- Define interfaces (GDScript class_name APIs) for DungeonGenerator, SeedController, AdventurerManager, and RewardEngine.
- Provide tuning tables for seed-to-dungeon mappings: seed_tier → expected_room_count, hazard_density, reward_bias.
- Provide determinism guarantees: RNG seeding rules, entropy consumption rules, and replayability checks.
- Deliver sequence diagrams for micro/meso/macro loops.

## Acceptance Criteria
- [ ] System design doc reviewed and approved by design and engineering.
- [ ] Interfaces have example usage and unit tests.
- [ ] Tuning tables committed in a data-driven format (.csv or .tres).

## Security considerations
- Ensure deterministic RNG seeds are not trivially guessable to prevent players from trivially farming specific layouts. Use seed salt per-player.
- Validate designer-tuned tables to prevent negative/overflow values.

## Performance targets
- System design should allow dungeon generation for a single seed under 50ms on reference PC for sampling; bulk generation (for validation) may be slower with batch mode.
- Tuning tables load within 50ms.

## UX notes
- Expose high-level tuning knobs to designers (room_count, hazard_density) through data files; do not expose raw RNG.
- Provide deterministic preview mode for designers.

## Edge cases
- Malformed tuning table entries should default to safe fallbacks.
- Contradictory mutation rules must be detected during validation and flagged as design errors.

## Data Contracts
- Interface definitions for DungeonGenerator, SeedController, AdventurerManager, RewardEngine (GDScript class_name with method signatures).
- Tuning tables (CSV/.tres) for seed-to-dungeon mappings.

## Integration points
- DungeonGenerator and RewardEngine must use the same data contracts for room reward bias.
- AdventurerManager interfaces consumed by GameLoopManager for dispatch.

## QA test plan
- Integration tests validating pipeline: seed -> generator -> run simulator -> reward engine.
- Design sign-off checklist for balancing tables.

## Metrics
- Determinism pass rate (same seed → same dungeon) across sample set.
- Time to generate single dungeon for sampling.

## Rollback criteria
- If system design introduces unsolvable coupling, revert to earlier design iteration and re-scope to interface-first approach.

## Dependencies
- Depends on Task 1; consumers: Tasks 7,8,9.

## Complexity estimate
- Fibonacci: 8 pts (Moderate)

