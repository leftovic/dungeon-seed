# TASK: Monitor & Instrumentation — Analytics Gateway (reconciled)

- Ticket ID: TASK-MONITOR-ANALYTICS-GTW-RECONCILED
- Short: Add production-grade game-analytics instrumentation for the Gateway (privacy-first, schema-driven, testable, and observable)
- Epic: analytics-and-telemetry
- Authors: reconciliation-team / quality-gate-reviewer
- Date: 2026-04-13

---

1) Executive Summary

Implement a privacy-first, schema-driven analytics/telemetry pipeline for the Gateway. Deliverables: event taxonomy, event schema registry, deterministic event IDs, sampling rules, retention/GDPR policy references, CI e2e telemetry ingestion tests, dashboards and alerting runbooks, and a phased rollout plan with rollback gates.

This ticket reconciles prior pass2 artifacts and produces a single implementable, testable ticket suitable for handoff to engineering + CI automation.

---

2) Motivation & Business Value

- Measure player flows and funnel conversion through the Gateway (login, account-link, purchase-intent, match-initiation).
- Provide production quality telemetry for analytics, troubleshooting, and SLO monitoring without exposing PII.
- Ensure compliance with GDPR/CCPA by design (minimal PII, retention policies, user data deletion hooks).

Success metrics: reliable delivery to telemetry backend (>=99.5% for sampled events), validated schema coverage for 100% new event types, runbooks and dashboards available at ship time.

---

3) Scope (what this ticket includes)

- Define event taxonomy and canonical names for Gateway events.
- Implement client/server instrumentation hooks in Gateway codebase (send to central telemetry producer service).
- Provide deterministic event ID generation guidance and unit tests (HMAC-based deterministic IDs). No secrets in repo.
- Provide RNG/deterministic ID test vector references where relevant (see Test Vectors section).
- Add schema registry entries (JSON Schema or Protobuf) and validation in ingestion path.
- Add e2e ingestion tests (CI job) that exercise schema validation, ingestion, and storage.
- Provide sampling rules and configuration (per-event and per-tenant) and test coverage for sampling logic.
- Provide retention & GDPR policy docs and deletion hooks for user data.
- Dashboard and alerting runbook template (SLOs, runbook steps, playbooks for common incidents).

---

4) Out of Scope

- Analytics modeling, queries, or dashboards beyond the baseline dashboards and example queries listed here are out-of-scope.
- Long-term analytics warehousing, advanced ETL beyond initial ingestion and validated storage.
- Cross-game identity resolution or customer data platform integrations (these will be handled by separate epic).

---

5) Functional Requirements (FRs)

FR-001 Event Taxonomy: Provide a canonical list of events (name, category, description, required fields, optional fields, example payload).
FR-002 Deterministic Event IDs: Every emitted event gets a deterministic event_id derived by HMAC_SHA256(secret, canonical_event_name + '|' + canonical_time) encoded base64url or hex. Secret is environment-specific and stored in Vault/KMS; implementation must support rotation.
FR-003 Schema Registry: Event schemas registered in a schema registry (files under neil-docs/telemetry/schemas/ or remote registry). Ingestion must validate events against registered schemas.
FR-004 Privacy-by-Design: No PII fields in event payloads. If PII is required for a rare use-case, it must be hashed client-side and explicitly gated by Data Protection team.
FR-005 Sampling Rules: Support deterministic sampling (hash-based) with per-event & per-tenant config; config stored in central service and can be overridden via feature flags.
FR-006 Retention & Deletion: Default retention policy (e.g., 90 days / 365 days for aggregated metrics) and a documented GDPR deletion endpoint and processes.
FR-007 E2E Test Harness: CI e2e tests that send test vectors through ingestion pipeline and assert schema validation, storage, and expected downstream message(s).
FR-008 Dashboards & Alerts: Provide baseline dashboards and runbooks mapping key events → SLOs → alerting thresholds.
FR-009 Telemetry Backpressure: Ingestion path must gracefully handle telemetry backend outages; buffering + drop policy documented.
FR-010 CI Coverage: Unit tests for deterministic ID and sampling logic, integration tests for schema validation, e2e pipeline test in CI.

---

6) Non-functional Requirements (NFRs)

NFR-001 Privacy/Compliance: Telemetry shall avoid storing raw PII. Any PII flow must be documented and approved.
NFR-002 Reliability: Delivery success (sampled) >= 99.5% over 24h for the baseline sampling rate (as measured by test harness).
NFR-003 Performance: Telemetry instrumentation should add <2ms latency to Gateway critical path when async; synchronous calls must be avoided on hot paths.
NFR-004 Security: No secrets in code; HMAC keys in Vault/KMS with rotate policy. All ingestion endpoints require mutual TLS or signed tokens.
NFR-005 Observability: Ingestion metrics (received, validated, rejected_by_schema, dropped, backlog) must be exported to Prometheus.

---

7) Acceptance Criteria (ACs) — testable

AC-001 Given the canonical taxonomy, when producing a sample event for "gateway.login.success", then the schema registry validates the event and ingestion marks it accepted.
AC-002 Given a known deterministic key (test key in unit tests only) and canonical inputs, deterministic event ID generation unit test must produce the expected test vector output (unit test asserts exact hex/base64).
AC-003 Given a configured sampling rate of 1% for event type X, a deterministic hash-based sampler run over 10000 canonical IDs returns ~100 accepted events (±2%).
AC-004 Given an ingestion endpoint outage, telemetry producer buffers up to N events (configurable) and drops beyond that with metrics emitted (ingested_retries, dropped_due_to_backpressure).
AC-005 Given a GDPR deletion request, a documented deletion job / API removes events for the subject within SLA (e.g., 72h) from primary hot store and marks them for removal in downstream stores.
AC-006 CI: A CI job exists that runs the telemetry e2e pipeline and passes on PRs; job name: .github/workflows/ci-telemetry.yml::telemetry-e2e.

---

8) Test Cases (unit/integration/e2e) — minimal list

TC-001 Unit: deterministic_event_id.test — input: (key=test-k1, event_name="gateway.login.success", ts=2026-04-13T12:00:00Z) → expected HMAC hex/base64 (see Test Vectors section). Must run in dotnet/npm unit suites.
TC-002 Unit: sampler.test — deterministic distribution validation for sampling rates {0.1%,1%,10%,100%}.
TC-003 Integration: schema_validation.test — event rejected if missing required fields; accepted when optional fields present.
TC-004 E2E: e2e_telemetry_pipeline.test — send instrumented sample payloads through ingestion; assert persisted records and metrics incremented.
TC-005 Regression: privacy_violation_scan — static analyzer to fail build if schema contains fields named email, ssn, full_name, or raw_phone unless explicitly marked hashed=true and approved.

Run these tests via CI job: .github/workflows/ci-telemetry.yml with jobs: telemetry-unit, telemetry-integration, telemetry-e2e.

---

9) Security Threat Model (brief STRIDE + mitigations)

Threats and mitigations (specific to telemetry):
- Spoofing: Ingestion endpoints require mTLS/RBAC tokens; issuers validated. (Mitigation: mutual TLS + signed JWT tokens.)
- Tampering: Schemas validated and events verified with a signature header (optional). (Mitigation: sign messages or HMAC via environment key for high-sensitivity events.)
- Repudiation: Deterministic event_id + ingestion timestamp + producer metadata logged with non-repudiation where required.
- Information Disclosure: PII prohibited; schema linter fails builds on PII-like fields. (Mitigation: Static checks + code review.)
- Denial of Service: Backpressure + quotas per producer. (Mitigation: per-tenant ingestion quotas.)
- Elevation of Privilege: Principle of least privilege for schema registry and ingestion admin operations.

---

10) Data Privacy & Retention (GDPR/CCPA)

- Default retention: 90 days for raw events, 365 days for aggregated metrics, unless business justification approved by DPO.
- User Deletion: Support deletion via GUID or pseudonymous ID; deletion process documented under neil-docs/privacy/telemetry-deletion.md.
- PII Avoidance: Schemas must not include raw PII fields; where identifiers are required, include pseudonymous IDs only (hashed with per-tenant salt, not reversible; salt stored in Vault with restricted access).
- Data Transfer: Any cross-border transfer must be documented and DPO-approved.
- Audit: Log deletion operations and preserve an audit trail (who/when/what) for compliance.

Referenced policy documents (placeholders — link to org policy files):
- neil-docs/privacy/GDPR-PRIVACY-POLICY.md
- neil-docs/privacy/RETENTION-POLICY.md

---

11) Event Taxonomy (canonical examples)

(Complete taxonomy must be a separate file: neil-docs/telemetry/event-taxonomy.md — see Implementation Prompt)

Example canonical events:
- gateway.login.attempt — { event_time, method, outcome, error_code? }
- gateway.login.success — { event_time, method, auth_provider, latency_ms }
- gateway.account.link.request — { event_time, provider, success }
- gateway.purchase.intent — { event_time, product_id (pseudonymized), price_bucket }
- gateway.matchmaking.request — { event_time, mode, region }

Each event entry must include: canonical name, description, required fields, field types, example payload, recommended sampling tier (always/sample/rare).

---

12) Schema Registry & Validation

- Schema format: JSON Schema Draft 2020-12 or Protobuf — pick one consistently. Implementation should support JSON Schema v2020 or Protobuf depending on downstream consumers.
- Location: initial schemas stored under repo path neil-docs/telemetry/schemas/<event-name>.schema.json. A lightweight registry component will read these files and expose an endpoint for ingestion service to fetch schemas in CI and at runtime.
- Validation: ingestion node validates incoming payloads against registered schema; rejected events increment rejected_by_schema metric and are logged (no PII in logs).

---

13) Deterministic ID & RNG Guidance (deterministic ID, RNG test vectors)

Deterministic Event ID algorithm (recommended):
- event_id = HMAC_SHA256(K_env, canonical_event_name + "|" + canonical_timestamp)
- encode event_id as base64url (without padding) OR hex (consistent across systems).
- K_env is an environment-specific key stored in Vault/KMS (never in repo). Rotation: support key version in event metadata so old keys can still be validated by ingestion for a configured overlap window.

Deterministic ID considerations:
- Use UTC ISO 8601 for canonical_timestamp (truncate to seconds or milliseconds consistently across producers).
- If absolute determinism across retries is required, include a monotonic attempt index or server-assigned sequence to avoid duplicate HMAC inputs.
- Deterministic IDs should be stable for the same logical event; avoid including ephemeral fields (e.g., local request ids) unless intended.

RNG / Test Vectors (references and guidance):
- Use standard HMAC-SHA256 test vectors from published RFCs when implementing tests (see RFC 4231 provides HMAC test vectors for SHA algorithms) or NIST SP 800-90A where DRBG is required.
- Unit test pattern: include a small test-only secret key (e.g., "telemetry-test-key") and precomputed HMAC outputs in the test code to assert deterministic ID generation implementation. Example (pseudocode):
  - key: "telemetry-test-key"
  - input: "gateway.login.success|2026-04-13T12:00:00Z"
  - expected_hex: "<compute via known-good tool — include in test file as constant>"
- DO NOT check in production keys. Tests may use ephemeral test key constants.

Note: For cryptographic test vectors, reference RFCs in test comments (best practice): RFC 4231 (HMAC test vectors), RFC 6979 (deterministic nonce generation for ECDSA) and NIST SP 800-90A (DRBG guidance).

---

14) Deployment & Rollout Plan

Phased rollout with feature flag and dry-run:
- Phase 0 — tests only: CI runs unit/integration/e2e for telemetry with fake endpoints.
- Phase 1 — internal dry-run: instrumentation emits to staging ingestion endpoint with 100% acceptance and validation; dashboards created in staging.
- Phase 2 — canary: enable telemetry for 1% of production traffic to ingestion cluster; monitor rejected_by_schema, backlog, and latency.
- Phase 3 — ramp: increase sampling per rules to target; validate dashboards and alerts.

Rollback gates: if rejected_by_schema > 0.5% of events for 10 minutes or ingestion backlog grows > 10x baseline, immediately rollback feature flag and return to previous phase.

---

15) Monitoring, Dashboards & Runbooks

Baseline dashboards (create in chosen dashboard system — e.g., Grafana):
- Ingestion Overview: events_received, events_accepted, events_rejected_by_schema, events_dropped, backlog_size, avg_ingest_latency
- Sampling Metrics: sampling_rate_effective per event type
- Delivery SLOs: delivery_success_rate (sampled)

Alerting and runbooks (template):
- Alert: ingestion_rejected_rate_high — condition: rejected_by_schema / received > 0.5% for 5m.
  - Runbook: check schema registry service logs, recent schema changes, check event samples (neil-docs/telemetry/samples/), rollback recent schema or flag producers, escalate to Telemetry Oncall.
- Alert: ingestion_backlog_growth — condition: backlog_size > 10x baseline for 5m.
  - Runbook: verify backend health, scale ingestion cluster, enable temporary throttling of low-priority events.

Store runbooks under neil-docs/telemetry/runbooks/ with explicit steps, commands, and escalation contacts.

---

16) Implementation Prompt (developer-ready)

Create the following files and changes. This section is intentionally specific and designed to bootstrap an AI coding agent or a mid-level developer.

A. Repo files to add (suggested paths & contents):
- neil-docs/tickets/task-monitor-analytics-gtw-reconciled.md (this ticket)
- neil-docs/telemetry/event-taxonomy.md — full event taxonomy CSV/markdown table (FR-001)
- neil-docs/telemetry/schemas/gateway.login.success.schema.json — JSON Schema for gateway.login.success
- neil-docs/telemetry/schemas/README.md — registry README describing schema format and registration process
- neil-docs/telemetry/runbooks/ingestion_rejected_runbook.md — runbook text
- neil-docs/privacy/telemetry-deletion.md — deletion API and operator steps
- src/Gateway/Telemetry/TelemetryProducer.cs (or equivalent language) — instrumentation producer wrapper with async, batch, and retry semantics
- src/Gateway/Telemetry/DeterministicId.cs — deterministic HMAC_SHA256 event id generator (unit-tested)
- src/Gateway/Telemetry/Sampler.cs — deterministic sampler (hash-based) with config
- tests/telemetry/unit/deterministic_event_id.test.* — unit tests using test key
- tests/telemetry/integration/schema_validation.test.* — integration test using local schema registry mock
- .github/workflows/ci-telemetry.yml — CI workflow with jobs: telemetry-unit, telemetry-integration, telemetry-e2e

B. Code patterns & constraints:
- Language idioms: follow existing project conventions (namespace: Game.Gateway.Telemetry), DI via existing Container (register TelemetryProducer as singleton), use ILogger for structured logging.
- Secrets: Telemetry HMAC key read at runtime from environment via existing secret manager adapter (do NOT read from config files).
- Async: TelemetryProducer.SendAsync must be non-blocking; instrumented code should await only in non-critical paths or fire-and-forget with safe background tasks and measured instrumentation.

C. Unit tests & test vectors:
- Add deterministic_event_id.test which uses test-only key "telemetry-test-key" and a precomputed HMAC result. Provide instructions in test header to regenerate expected value with openssl or node crypto if necessary.
- Provide CI job `telemetry-unit` that runs `dotnet test --filter Category=TelemetryUnit` or `npm test -- --grep telemetry` depending on project stack.

D. CI / workflow definitions (example job names + checks):
- .github/workflows/ci-telemetry.yml
  - jobs:
    - telemetry-unit: runs unit tests, lints schemas, runs static PII-scan (script: scripts/privacy-scan.sh)
    - telemetry-integration: boots local schema registry mock and runs schema validation tests
    - telemetry-e2e: uses test harness to send sample events via instrumented producer to a test ingestion environment and asserts expected metrics. This job must run in PR gating for telemetry-related files.

E. QA and Oncall:
- Add telemetry-oncall rotation entry in ops roster and include runbook slack channel: #oncall-telemetry.

F. Documentation & Ownership:
- Add a document neil-docs/telemetry/OWNERS.md with contact for DPO, Telemetry Engineer, and Release Manager.

G. Compliance artifacts to include in PR description:
- Link to neil-docs/privacy/GDPR-PRIVACY-POLICY.md and brief summary of how new event types comply.
- Mention that the PR must include schema diff (new/changed schemas) and sample payloads under neil-docs/telemetry/samples/.

---

Notes & Remediation Checklist (for PR reviewers):
- Check schema presence for each new event. No schema-less events allowed.
- Verify CI jobs are added and run automatically for PRs touching telemetry files.
- Validate unit test deterministic vectors exist and are deterministic (regenerate locally and assert equality).
- Run privacy scan script and ensure no PII fields in schema or samples.

---

References & Standards (for implementers)

- HMAC test vectors: see RFC 4231 (HMAC-SHA256 vectors) — include a test harness that uses a known-good implementation to generate expected values for unit tests.
- Deterministic nonce guidance: RFC 6979 (if deterministic crypto nonces are involved anywhere).
- RNG/DRBG guidance: NIST SP 800-90A (if random generation is required).
- Internal policy documents: neil-docs/privacy/GDPR-PRIVACY-POLICY.md, neil-docs/privacy/RETENTION-POLICY.md

---

Review notes (quality-gate):
- This reconciled ticket enforces: event taxonomy, privacy-first design (no PII by default), sampling & deterministic IDs, schema registry validation, e2e tests, CI gating, dashboards and runbooks.
- Implementation Prompt (section 16) includes precise file paths and CI job names required by Quality Gate.

