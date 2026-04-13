# Title: Implement adventurer management and recruitment engine

ID: task-008-gtw-pass2

## Objective
Implement the adventurer roster and recruitment system with classes, stats, XP progression, equipment slots, and party management APIs. Ensure adventurers serialize and interact with dungeon systems.

## Background
Adventurers are the execution agents in runs. The GDD lists classes and stat systems; this task turns them into runtime objects, recruitment UI contracts, and progression paths compatible with the economy and loop.

## Detailed Requirements
- Create Adventurer class prototypes with class_name declarations for Warrior, Ranger, Mage, Rogue, Alchemist, Sentinel.
- Implement stat model (health, attack, defense, speed, utility) and XP progression system with level thresholds.
- Provide recruitment flow API: recruit(candidate_id), hire(cost), roster management, equip_item(item_id).
- Ensure adventurer state serializes and integrates with dispatch APIs.
- Provide simple AI behavior profiles for run simulation (abstracted from combat implementation).

## Acceptance Criteria
- [ ] Adventurer objects persist and reload correctly.
- [ ] Recruitment flow documented and testable in isolation.
- [ ] Basic run-simulation uses adventurer stats to produce expected XP/gold outputs within tolerance.

## Security considerations
- Sanitize any user-supplied names or inputs to avoid formatting exploits in tooltips.
- Prevent adventurer state tampering via save integrity checks.

## Performance targets
- Adventurer roster screens render <60ms frame time impact; roster of 50 heroes must not cause frame hiccups.
- Level-up calculations should be O(1) per hero and use cached values where possible.

## UX notes
- Recruiting should present clear cost and expected yield; highlight class role and synergy suggestions.
- Allow quick-swap of party configurations and save presets for dispatch.

## Edge cases
- Duplicate unique artifacts equipped: enforce unique-item rules.
- Full roster and inventory limits should provide clear 'full' indicators and prevention UI.

## Data Contracts
- Adventurer schema (res://config/schemas/adventurer.schema.json) with fields for id, class, level, stats, equipment_slots.
- Recruitment API spec (GDScript method signatures) for UI integration.

## Integration points
- Dispatch UI will consume party presets from AdventurerManager.
- XP and equipment changes feed into SaveManager and RewardEngine.

## QA test plan
- Unit tests for level progression, XP gain, and equipment application.
- Integration test: recruit → dispatch → run simulation → XP awarded matches expectations.

## Metrics
- Average time to recruit first hero in onboarding.
- Roster growth rate by player session length.

## Rollback criteria
- If adventurer system design introduces progression holes or critically imbalanced classes, revert to conservative stats and remove problematic abilities until balanced.

## Dependencies
- Depends on Tasks 2 and 3; consumers: Tasks 10 and 11.

## Complexity estimate
- Fibonacci: 13 pts (High)

