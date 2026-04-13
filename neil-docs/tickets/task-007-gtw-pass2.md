# Title: Implement procedural dungeon generator and room templates

ID: task-007-gtw-pass2

## Objective
Build the dungeon generation engine: deterministic seed parsing, entropy mapping, room template selection, graph connectivity, and theme application. Deliver a validation harness to assert navigability and difficulty scaling.

## Background
Dungeon generation is core to the game promise. The GDD specifies inputs (seed, mutation, maturity) and room types. This task must deliver reproducible layouts that support room roles and reward bias.

## Detailed Requirements
- Implement DungeonGenerator with deterministic seed input and `generate(seed_instance)` API returning a DungeonInstance graph.
- Provide room templates for Combat, Treasure, Trap, Puzzle, Rest, Boss with parametric difficulty and reward multipliers.
- Implement pathfinding and navigability validation to ensure no unreachable rooms.
- Provide a validation harness to assert difficulty scaling matches expected tuning tables.
- Provide editor tools for sampling generated dungeons and exporting as JSON for QA.

## Acceptance Criteria
- [ ] DungeonGenerator produces identical graph for same seed & mutation inputs.
- [ ] All rooms are reachable from entry node in 99/100 sampled seeds.
- [ ] Difficulty curve validated against tuning tables within +/-10% expected reward signals.

## Security considerations
- Prevent exploit via deterministic seed manipulation by including a player-specific salt in RNG.
- Ensure template data is read-only at runtime; designers only modify via approved tools.

## Performance targets
- Single dungeon generation under 50ms for sampling mode; 500ms acceptable for full validation runs.
- Memory usage per dungeon graph should be bounded (target <5MB per instance in large runs).

## UX notes
- Designer preview should visualize room roles clearly (icons + color-coded difficulty).
- For players, show path and key room types before dispatch.

## Edge cases
- Generator failure should fall back to a simple linear layout with safe defaults.
- Extremely dense mutation combinations should be clamped to avoid impossible rooms.

## Data Contracts
- res://config/room_templates/*.json describing room roles and parameter ranges.
- DungeonInstance JSON contract documented for use by rendering and simulation.

## Integration points
- Dungeon rendering preview will consume DungeonInstance JSON.
- GameLoopManager will request generator outputs for run simulation.

## QA test plan
- Validation harness: generate 10k dungeons across tiers and assert reachability and room-type distribution.
- Manual QA: designer walks through preview tool for sampled seeds.

## Metrics
- Reachability success rate.
- Distribution variance vs tuning table targets.

## Rollback criteria
- If generator produces unplayable layouts that cannot be tuned within reasonable effort, revert to a simpler deterministic layout generator and escalate redesign.

## Dependencies
- Depends on Tasks 2 and 3; consumers: Tasks 10 and 11.

## Complexity estimate
- Fibonacci: 13 pts (High)

