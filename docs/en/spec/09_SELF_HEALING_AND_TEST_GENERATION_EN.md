# F09 — Self-healing and test generation

0.1.0 status: controlled selector-healing workflow is implemented; full generated-test acceptance remains open.

## Goal

Diagnostic data must let AI make evidence-backed proposals to repair a selector, update a Page Object/assertion, or create a new test without hiding product defects or changing tests without controlled verification.

## Boundaries

- Evidence collection and candidate generation are mandatory.
- Automatic patch application is not default behavior.
- Self-healing must not turn a failed test into passed without rerun and audit trail.
- Product behavior and expected values are never changed automatically merely because the UI changed.

## Evidence requirements

- `F09-REQ-001`: a failed UI query stores canonical selector, parent chain, strategy, timeout, candidate count, and bounded candidate snapshots.
- `F09-REQ-002`: candidates contain element type, redacted identifier/label/value, traits, frame, enabled/selected/hittable state, and hierarchy path.
- `F09-REQ-003`: before/after accessibility snapshots and screenshots are linked through event/attachment IDs.
- `F09-REQ-004`: actions/assertions store intent, preconditions, expected, actual, last observed state, and source location.
- `F09-REQ-005`: the manifest contains git SHA/dirty state, app/framework versions, locale, device/OS, launch config, and relevant test/Page Object source references.
- `F09-REQ-006`: test-generation input records the user journey as semantic actions, not only coordinates/text logs.
- `F09-REQ-007`: secrets and sensitive user-entered values become typed placeholders before AI input.

## Implemented diagnostic handoff baseline

The independent `xceasy-runner` may aggregate per-test evidence into a stable run conclusion, integrity manifest, and worker classifications. Those host artifacts and policies are versioned by the runner, not by the XCEasy Swift package.

Per-test schema `1.0.0` adds complete redacted parent chains, privacy-aware fingerprints, transition observations, source/performance/attachment correlation, failure screenshots, bounded redacted UI hierarchies, and per-test integrity manifests. Default `basic` retains up to five candidates on failure/ambiguity; `detailed` does so for every query.

The deterministic healing engine rejects semantic type mismatches, low-confidence candidates, and near-equal alternatives. `XCEasyHealingConfiguration` defaults to `observe`; `suggest` produces a reviewable proposal and every proposal requires human approval. `scripts/build-ai-handoff.sh` creates provider-neutral healing and test-generation requests. `build-healing-source-bundle.sh` exports at most 20 explicitly mapped Swift files and 1 MiB after path, hash, canary, and probable-secret checks. `invoke-healing-provider.sh` runs an explicitly configured local or external command with a bounded timeout and validates that its response selects an evidence-backed ranked candidate, changes no assertion, and still requires human approval. It never creates an approval record or mutates source. `apply-healing-proposal.sh` accepts only a separately reviewed suggested candidate, validates the source SHA-256, prepares a diff without mutation by default, and may apply exactly one selector literal with a fixed verification profile. Failed verification restores the original source. Assertion rewriting and in-process runtime mutation remain prohibited.

## Healing requirements

- `F09-REQ-008`: the healing engine emits ranked candidates with confidence, evidence, and reason codes.
- `F09-REQ-009`: auto-healable changes are limited to selector metadata/Page Object mapping; assertion expectation changes require human approval.
- `F09-REQ-010`: reject candidates when ambiguity exceeds a configurable threshold or semantic type mismatches.
- `F09-REQ-011`: a patch links to the original execution/failure fingerprint and includes diff, affected tests, and rollback data.
- `F09-REQ-012`: after patching, run the failed test, targeted related tests, and selector contract tests on the original environment.
- `F09-REQ-013`: only rerun outcome may mark the test passed; the report retains original failure and healed attempt as linked executions.
- `F09-REQ-014`: repeated healing of one selector is instability requiring review, not endless auto-update.

## Test-generation requirements

- `F09-REQ-015`: generated tests follow project code style, Page Object boundaries, and Given/When/Then.
- `F09-REQ-016`: generators use stable identifiers; coordinate/index selectors are explicitly marked fallbacks.
- `F09-REQ-017`: every assertion in a generated test links to an observable outcome/evidence, not an arbitrary snapshot property.
- `F09-REQ-018`: generated code compiles and passes lint/targeted run before being proposed.
- `F09-REQ-019`: AI handoff lists assumptions, evidence IDs, confidence, and unverified gaps.
- `F09-REQ-020`: source export is allowlisted, size-bounded, hash-addressed, repository-contained, and rejected when a secret canary or probable embedded credential is found.
- `F09-REQ-021`: application requires a versioned approval record naming reviewer, timestamp, proposal, candidate, exact source hash, and verification profile.
- `F09-REQ-022`: dry-run is the default; applied changes are rolled back on failed verification and produce a machine-readable audit record.
- `F09-REQ-023`: an AI provider is an allowlisted command-array adapter with bounded execution time; shell evaluation is forbidden.
- `F09-REQ-024`: provider output is suggestion-only and is rejected unless proposal ID, evidence candidate index, identifier, reason codes, no-assertion-change flag, and human-approval flag satisfy the local contract.

## Acceptance criteria

- A fixture with a changed identifier ranks the correct replacement first and does not apply it without policy permission.
- A fixture with two visually identical elements stops auto-healing as ambiguous.
- A changed expected business text is not hidden by selector healing.
- Canary secrets are absent from all AI input and generated code.
- A generated regression test fails against the old fixture and passes against the fixed one.

## Decisions

- `F09-DEC-001`: providers are pluggable host commands. The same contract supports a local model or an external-service client without linking a vendor SDK into the test runner. `xceasy.ai-provider.example.json` documents the configuration shape.
- `F09-DEC-002`: the authorized host adapter supports `package`, `unit`, internal `integration`, or `all` verification and rollback.
- `F09-DEC-003`: the source bundle is explicit, hash-addressed, limited to 20 Swift files and 1 MiB.
