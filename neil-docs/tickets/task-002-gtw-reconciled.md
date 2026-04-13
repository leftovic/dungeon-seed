# Reconciled Ticket: Define domain models, save contracts, and progression schemas

ID: task-002-gtw-reconciled

Based on: task-002-gtw-pass2.md

Summary:
Preserves Pass2 schema requirements. See neil-docs/tickets/RECONCILIATION-REPORT.md and QUALITY-GATE-REPORT.md for reconciliation decisions and quality fixes (schema versioning, deterministic ID policy, HMAC integration, serialization test vectors).

Full pass2 content preserved at: task-002-gtw-pass2.md

Actions required:
- Add deterministic ID scheme (UUIDv5/HMAC) per quality report
- Include sample save file and migration helpers
- Add unit tests for round-trip serialization
