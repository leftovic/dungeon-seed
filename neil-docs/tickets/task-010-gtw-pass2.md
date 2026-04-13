# Title: Build core game loop orchestration

ID: task-010-gtw-pass2

## Objective
Create the central game loop manager that sequences planting, growth ticks, dispatch scheduling, run simulation, loot harvest, and post-run state transitions. Expose deterministic APIs and event hooks for UI and persistence.

## Background
The Decomposition marks Task 10 as the primary integration bottleneck. This orchestration system must coordinate persistence, dungeon gen, adventurer systems, and economy to realize the core loop defined in the GDD.

## Detailed Requirements
- Implement GameLoopManager autoload with clear states: Idle, Scheduling, Running, Harvesting, Paused.
- Provide APIs: plant_seed(seed_id), schedule_dispatch(dungeon_id, party_config), tick_growth(dt), simulate_run(dungeon_instance, party) → RunResult.
- Ensure event hooks: on_dungeon_ready, on_run_complete, on_loot_harvested for UI and telemetry.
- Integrate with SaveManager, DungeonGenerator, AdventurerManager, RewardEngine.
- Add robust error handling for mid-run interruptions and resume semantics.

## Acceptance Criteria
- [ ] Full run cycle functional in local test: plant → mature → dispatch → simulate → harvest.
- [ ] Hooks fire in correct order and persistence across quick_save/quick_load works.
- [ ] System passes stress test with 20 concurrent scheduled dungeons without breakdown.

## Security considerations
- Validate run outcomes server-side if multiplayer is added; for single-player, include integrity checks on run results.
- Rate-limit rapid dispatch/resolution actions to prevent exploitation of reward loops.

## Performance targets
- Game loop tick must support 20 scheduled dungeons without frame stutter; background processing should be batched and throttled.
- Simulate_run should complete under 100ms for typical party/dungeon sizes on reference hardware.

## UX notes
- Provide a clear timeline/status for scheduled runs and the ability to cancel or accelerate with boosters.
- Show run progress and allow the user to inspect intermediate results for transparency.

## Edge cases
- Mid-run interruptions (app crash, save load) must restore to consistent post-run or pre-run state; define exact semantics.
- Scheduling conflicts (double-assigning a hero) must be prevented by UI-level checks and server-side assertions.

## Data Contracts
- GameLoopManager event spec (on_dungeon_ready, on_run_complete, RunResult struct).
- Scheduling table format for queued dispatches (res://config/scheduling/queue_schema.json).

## Integration points
- Consumes DungeonGenerator, AdventurerManager, RewardEngine, SaveManager.
- Exposes hooks to UI (Task 12) for status and cancel/accelerate actions.

## QA test plan
- End-to-end automation: plant seed, wait (simulate time), dispatch, simulate_run, harvest; assert state transitions and persistence.
- Stress test scheduling with multiple concurrent dungeons.

## Metrics
- Mean time per run simulation.
- Scheduled queue length distribution under load.

## Rollback criteria
- If orchestration introduces race conditions or data loss across runs, revert to a transaction-style orchestration and patch incrementally.

## Dependencies
- Depends on Tasks 6,7,8,9; consumers: Task 12 and Task 11.

## Complexity estimate
- Fibonacci: 13 pts (High)

