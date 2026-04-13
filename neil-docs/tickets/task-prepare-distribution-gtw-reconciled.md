# Reconciled Ticket: Prepare build & store submission artifacts

ID: task-prepare-distribution-gtw-reconciled

Summary:
Coordinate Game Build & Packaging and Store Submission flows to produce platform-ready builds, signed artifacts, storefront metadata, and CI packaging jobs. Incorporates Quality Gate requirements: deterministic ID/HMAC notes, CI headless test integration, artifact signing, and reproducible builds.

Deliverables (concrete paths):
- build/scripts/create_builds.sh (or .ps1) — orchestrates exports for Windows, macOS, Linux, Web, Android (AAB), iOS (IPA stub), and Headless server builds.
- build/manifests/BUILD-MANIFEST.json — records build hashes, sizes, target, export templates used, and deterministic build seed.
- build/signing/README.md — instructions for code signing, key storage, and notarization steps.
- ci/workflows/build-and-package.yml — CI job that runs builds on tagged commits and produces artifacts in actions/artifacts/
- docs/store/STORE-SUBMISSION-CHECKLIST.md — per-store checklist (Steam, Play Store, App Store, itch.io) including metadata, rating, screenshots, trailers, and age-rating guidance.
- docs/release/RELEASE_NOTES_TEMPLATE.md — templated release notes for PRs and store submissions.
- scripts/verify_reproducible_builds.py — verifies BUILD-MANIFEST.json hashes match produced artifacts; used in CI to assert reproducibility.

Quality Gate MUST-HAVES (actionable):
1) Deterministic build metadata
   - Each build must include deterministic build seed & metadata in BUILD-MANIFEST.json: { "timestamp", "seed", "git_ref", "tool_versions": {"godot": "4.x", "compressor": "zstd"}, "files": [...] }
   - Store manifest path: build/manifests/BUILD-MANIFEST.json
2) Artifact signing & notarization
   - CI references for signing: ci/workflows/build-and-package.yml must include steps for signing using secrets (GH Actions secrets or external KMS). Document signing key rotation in build/signing/README.md.
3) Reproducible builds validation
   - Add CI step: run scripts/verify_reproducible_builds.py across two consecutive build outputs and assert identical content hashes for released assets built from same seed.
4) Headless QA smoke tests on each packaged build
   - For each exported build, run headless smoke test: (native headless or runner) to verify process launches, main scene parses, and exit code 0. CI must collect logs into actions/artifacts/build-<target>-smoke.log.
5) Store submission artifacts & metadata
   - For each platform, build/packaging step must produce:
     - Store-ready package (.zip/.aab/.ipa) with metadata folder: store/<platform>/<version>/{screenshots/, trailer.mp4, store_metadata.json}
     - store_metadata.json includes: title, short_description, long_description, supported_locales[], age_rating, content_descriptors[], build_hash
6) Security & secrets management
   - Signing keys are never committed. Use secrets manager; reference keys via environment variables in CI.
   - Document key usage and emergency revocation in build/signing/README.md.

Acceptance Criteria (testable):
- AC-1: CI job ci/workflows/build-and-package.yml produces artifacts for Windows, Linux, and Web and uploads them to action artifacts on success.
- AC-2: scripts/verify_reproducible_builds.py returns exit code 0 for two identical builds created from the same seed and project state.
- AC-3: Headless smoke test passes on each exported build and logs are uploaded to artifacts.
- AC-4: STORE-SUBMISSION-CHECKLIST.md contains per-store required fields and matches store_metadata.json output for each platform.

Test cases (explicit):
- TC-BUILD-001: Reproducible build verification
  - Run create_builds.sh with seed S twice in clean environment; verify scripts/verify_reproducible_builds.py returns 0.
- TC-BUILD-002: Smoke-run exported build
  - Launch exported native build with --headless or equivalent; assert main scene loads and exit code 0.
- TC-BUILD-003: Signed artifact validation
  - Ensure CI signing step produces a signature file alongside package; verify signature can be validated using public-key in build/signing/README.md.

Files to create/modify (concise list):
- build/scripts/create_builds.sh (.ps1)
- build/manifests/BUILD-MANIFEST.json (generated)
- build/signing/README.md
- ci/workflows/build-and-package.yml
- scripts/verify_reproducible_builds.py
- docs/store/STORE-SUBMISSION-CHECKLIST.md
- docs/release/RELEASE_NOTES_TEMPLATE.md

Recommended commit message:
"chore(build): add packaging & store-submission reconciled ticket — manifests, CI job, reproducible build validation, and signing docs"

Notes:
- This reconciled ticket integrates Quality Gate requirements (deterministic seeds, HMAC key notes) into packaging flow. Implementation must avoid committing secrets and must provide CI-run verification for reproducibility and smoke tests.

