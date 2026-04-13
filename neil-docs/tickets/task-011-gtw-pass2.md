# Title: Implement seed growth, mutation, progression, and unlocks

ID: task-011-gtw-pass2

## Objective
Implement seed maturation, mutation reagent application, progression unlocks, and growth scheduling. Deliver a mutation system that offers trade-offs and R&D hooks for future seasonal seeds.

## Background
Per GDD, mutations change dungeon composition and reward bias; growth stages (Spore→Bloom) determine capacity and room counts. This task ties generator inputs to player-facing progression and unlocks.

## Detailed Requirements
- Implement growth state machine for seeds (Spore, Sprout, Bud, Bloom) with time-to-next-stage per rarity and modifiers from reagents.
- Design mutation slots API: apply_reagent(seed_id, reagent_id) → modifies growth_profile, reward_bias, hazard_multiplier.
- Provide unlockables mapping: seed_tier → biome_unlocks, adventurer_class_unlocks, reagent_recipes.
- Ensure interactions with DungeonGenerator inputs and GameLoopManager scheduling.

## Acceptance Criteria
- [ ] Seeds progress through stages over simulated time as per tuning table.
- [ ] Applying mutation reagents updates generator inputs and is reflected in subsequent generated dungeons.
- [ ] Unlock conditions trigger once resource thresholds are met and persist across saves.

## Security considerations
- Mutations and reagent application must be validated to prevent constructing impossible attribute combinations.
- Prevent manipulation of growth timers via local clock by using monotonic timers and persisted tick counts.

## Performance targets
- Growth tick processing for up to 50 planted seeds should complete under 30ms when processed in batch.
- Mutation application should be near-instant (<20ms) in UI to maintain responsiveness.

## UX notes
- Clearly communicate trade-offs for mutations (e.g., increased treasure vs increased traps) with numeric previews.
- Provide undo window (5s) after reagent application or explicit confirmation for irreversible changes.

## Edge cases
- Applying multiple reagents simultaneously must be queued and resolved deterministically.
- Reagent inventory underflow: prevent negative counts and show clear error.

## Data Contracts
- Mutation schema (res://config/schemas/mutation.schema.json) with effects and stacking rules.
- Growth schedule entry format (res://config/growth/schedule.json).

## Integration points
- Mutation outputs are inputs to DungeonGenerator and RewardEngine.
- Unlock events are emitted via GameLoopManager hooks.

## QA test plan
- Simulate reagent application scenarios and assert generator inputs mutated accordingly.
- Verify unlock gating triggers at expected thresholds.

## Metrics
- Mutation adoption rate in playtests.
- Growth-to-harvest cycle time distribution.

## Rollback criteria
- If mutation and unlock systems break progression or cause data inconsistencies, pause mutation rollout and revert the server/engine to safe defaults.

## Dependencies
- Depends on Tasks 7,8,9; consumers: Task 12.

## Complexity estimate
- Fibonacci: 13 pts (High)

