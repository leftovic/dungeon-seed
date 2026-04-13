# Reconciled Ticket: Build core game loop orchestration

ID: task-010-gtw-reconciled

Based on: task-010-gtw-pass2.md

Summary:
GameLoopManager orchestration preserved. Reconciliation requires robust resume semantics, transaction-like operations around runs, and integration tests with SaveManager and DungeonGenerator.

Actions required:
- Add resume/recovery test cases
- Ensure event hooks have deterministic ordering verified by tests
- Add stress test CI job for queued runs
