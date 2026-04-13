# Title: Implement loot economy and reward systems

ID: task-009-gtw-pass2

## Objective
Design and implement loot tables, reward flows (idle vs active), currency types (Gold, Essence, Fragments, Artifacts), and resource sinks. Provide tuning interfaces for reward curves and Monte Carlo simulation scripts.

## Background
Loot and economy design underpins progression and retention. The GDD lists reward types and economy principles; this task delivers deterministic drop logic, rarity tiers, and integration hooks for crafting and upgrades.

## Detailed Requirements
- Build reward engine with drop tables per room type and rarity multipliers.
- Implement idle accumulation and active-run bonus modifiers.
- Define currency sinks and upgrade costs for seeds, reagents, and adventurer gear.
- Provide Monte Carlo simulation scripts to validate long-term economy stability.
- Ensure artifacts and relics are flagged as unique and have proper inventory rules.

## Acceptance Criteria
- [ ] Drop tables produce expected rarity distribution in 10k simulated runs.
- [ ] Economy simulation shows no runaway inflation for baseline parameters.
- [ ] Reward engine integrates with SaveManager and GameLoop hooks.

## Security considerations
- Ensure reward calculations cannot be manipulated by tampering with client-side RNG seeds.
- Flag and log outlier reward events for telemetry and fraud detection.

## Performance targets
- Monte Carlo simulations should be executable offline and complete within reasonable time (10k runs < 2 minutes in batch on CI worker).
- Reward engine runtime overhead per run must be <5ms.

## UX notes
- Present clear reward previews and mark unique items distinctly.
- Provide inventory overflow management (auto-convert fragments to essence with confirmation).

## Edge cases
- Reward duplicates for unique artifacts should be converted to fragments or sent to vault with notification.
- Extremely rare drop triggers: ensure player sees a prominent notification and the item is correctly tracked.

## Data Contracts
- Drop table definitions (res://config/economy/drop_tables.csv)
- Currency definitions (res://config/economy/currencies.json)

## Integration points
- RewardEngine used by GameLoopManager to compute run outcomes and idle accrual.
- Economy metrics sent to analytics for balance monitoring.

## QA test plan
- Run Monte Carlo simulations and verify distribution metrics.
- Verify inventory and currency sink behaviors in end-to-end runs.

## Metrics
- Drop rate distribution vs expected.
- Currency inflation metrics over simulated 90-day runs.

## Rollback criteria
- If economy tuning causes runaway inflation or blocks progression, revert drop tables to previous stable parameters and open a balance hotfix.

## Dependencies
- Depends on Tasks 2 and 3; consumers: Tasks 10 and 11.

## Complexity estimate
- Fibonacci: 8 pts (Moderate)

