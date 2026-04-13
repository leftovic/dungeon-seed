# ID Migration - Implementation Notes

This document describes steps to migrate deterministic ID formats and re-key strategies.

Key points:
- When changing ID format, ensure backward compatibility by supporting legacy parsing for a transition period.
- Re-keying: export existing signatures, verify with old key, re-sign with new key and store alongside legacy signature until rollout complete.
- Always provide a rollback plan that preserves old signatures until new signatures are validated.
