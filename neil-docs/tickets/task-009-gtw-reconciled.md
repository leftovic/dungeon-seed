# Reconciled Ticket: Implement loot economy and reward systems

ID: task-009-gtw-reconciled

Based on: task-009-gtw-pass2.md

Summary:
Economy and reward engine preserved. Reconciliation requires Monte Carlo simulation outputs, idempotency guarantees, and anti-exploit validation per QUALITY-GATE-REPORT.md.

Actions required:
- Add Monte Carlo scripts and CI job to run simulations
- Implement logging for outlier reward events for telemetry
- Ensure reward calculations are server-validateable if multiplayer added
