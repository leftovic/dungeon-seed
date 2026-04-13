HMAC key provisioning and migration plan

Goal: Move from SHA-only deterministic IDs to HMAC-SHA256-backed IDs in production, with safe rollout and rotation.

1) Key generation
   - Generate a high-entropy 32-byte key using a secure KMS or openssl: openssl rand -hex 32
   - Store the key in a secure secret manager (GitHub Actions Secret `HMAC_KEY` for CI; production should use a managed KMS/Secret Store)

2) Application changes
   - Add support in deterministic_id_impl.gd for optional HMAC signing when HMAC_KEY present in env/config
   - If HMAC_KEY not present, fall back to current SHA256 hex behavior (backward-compatible read-only)
   - Add migration flag to enable writing HMAC IDs for new objects only

3) CI integration
   - Add `HMAC_KEY` as a Actions secret for test/staging runs where needed
   - Tests should include a fixture key for deterministic outputs in CI

4) Migration strategy
   - Phase 1: Read-only HMAC support; don't write HMAC IDs
   - Phase 2: Enable HMAC for new writes behind a feature flag; continue accepting SHA and HMAC formats
   - Phase 3: Migrate old IDs gradually using a background job that rekeys objects when safe (validate no downstream assumptions)

5) Rotation
   - Use KMS to support key rotation without downtime using key versioning
   - Maintain a key ID header in the HMAC output to allow multiple active keys (e.g., key-v1:BASE64_HMAC)
   - Re-sign on write with newest key; background job re-signs existing objects

6) Testing
   - Unit tests for both SHA-only and HMAC modes
   - CI secrets: set HMAC_KEY to a known test key for deterministic tests

7) Rollback
   - If issues encountered, disable HMAC write mode; system continues to accept SHA IDs

Security notes
- Never commit production HMAC keys. Use secrets managers and limit access.
- Log only key identifiers, not key material.

Tasks to complete:
- Implement HMAC support in deterministic_id_impl.gd
- Add feature flag and migration tools (tools/id_rekey.py updated)
- Add tests and CI config to include HMAC_KEY fixture
- Run migration job in staging and validate
