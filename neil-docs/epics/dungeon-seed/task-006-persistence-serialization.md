# Task 006 — Implement persistence and state serialization

Complexity: 8
Dependencies: Tasks 1,2

Description:
Implement a versioned save/load subsystem. Persist seed inventories, dungeon progress, hero rosters, inventory balances, and unlock state. Include migration strategy for schema evolution and tests for save fidelity.

Acceptance Criteria:
- Save and load functions with version tags
- Migration path for at least one schema change example
- Automated tests validating save/restore fidelity
