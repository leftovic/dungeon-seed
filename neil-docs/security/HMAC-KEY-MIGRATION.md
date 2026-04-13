# HMAC Key Migration - Implementation Notes

This document outlines the recommended approach to rotate HMAC keys used for deterministic ID signing and save blob integrity checks.

Important:
- Never commit real HMAC keys to source control.
- Use a KMS or CI secret store to provide keys to test and runtime environments.

High-level steps:
1. Add new key to KMS and mark as active for verification only.
2. Deploy services that verify signatures with both old and new keys.
3. Re-sign records in controlled batches and verify with new key.
4. After canary verification, remove old key from verification list.

Local dev/testing:
- Use neil-docs/security/dev-hmac-key.example as a developer-only key for unit tests and CI sample runs.
\n
