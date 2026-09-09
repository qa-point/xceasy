# XCEasy Project Constitution

Status: active and binding. Version: 1.2. Updated: September 9, 2026.

## 1. Mission

XCEasy makes iOS UI tests predictable, readable, and diagnosable. It must reduce test creation and maintenance cost while retaining XCTest/XCUI as the execution foundation. Safe AI-assisted evolution and diagnosis are first-class requirements.

## 2. Binding principles

### I. Truth over convenience

The framework must not hide ambiguous selectors, missing artifacts, telemetry failures, or failed waits. Convenience APIs are acceptable only when preserving root cause, expected/actual values, and execution context.

### II. Diagnosability is a feature

Every operation capable of failing a test must leave structured evidence: operation type, redacted inputs, result, duration, source location, and correlation IDs. Logs and diagnostic bundles are tested public contracts.

### III. Secure by default

Protect infrastructure credentials and retain targeted credential filtering before text sinks. UI trees, field values, screenshots, and explicit debug output are useful test evidence and may contain application data; do not blanket-mask or disable them without an explicit user requirement. Existing filtering is best effort and does not guarantee anonymization. Use synthetic test accounts and control artifact access/retention. New credential-bearing text logging requires scoped redaction tests; raw HTTP header/body logging remains prohibited. See [ADR 0021](adr/0021-diagnostic-privacy-boundary.md).

### IV. Determinism and isolation

Tests must not depend on order, another test's mutable global state, or absolute local paths. Parallel execution is a design constraint. Shared mutable singletons require explicit justification, synchronization, and concurrency tests.

### V. Compatibility and evolution

Public Swift APIs, telemetry schemas, and artifact layouts are versioned. Breaking changes require a migration guide and major version or an approved deprecation cycle. Every public API addition needs documentation and tests.

### VI. Evidence-driven changes

A defect fix starts with reproduction and ends with a regression test. Features require verifiable acceptance criteria. Build, performance, thread-safety, and compatibility claims require reproducible evidence.

### VII. Simple architecture

Prefer small types, explicit dependencies, and one source of truth. Abstractions must reduce coupling or duplication. Allure is an adapter, not the owner of the entire diagnostic domain model.

### VIII. AI-ready and human-readable

Canonical data is machine-readable and stable; humans receive a clear rendering of the same facts. AI must not infer semantics from localized prose. AI patches cite evidence and pass the same checks as human patches.

### IX. Production and release readiness

A supported capability must have a recorded environment matrix, public documentation, compatibility contract, release metadata, and a reproducible quality gate. Code alone does not imply production support. `release-metadata.json.version` is the single version source; tag, changelog, and API baseline must match it.

## 3. Definition of Done

A change is complete only when:

- acceptance criteria are met;
- appropriate tests are added or updated;
- public behavior and documentation agree;
- RU/EN user examples match the actual public API;
- new failure paths are diagnosable;
- privacy and redaction are verified;
- no machine-specific paths or accidental generated artifacts are added;
- build/test/lint commands ran, or the limitation is explicitly recorded;
- breaking changes, risks, and migration are documented.
- release metadata and API compatibility are verified when the change is shipped.

## 4. Prohibited practices

- `fatalError`, force unwrap, or silent `try?` on user execution paths without proven impossibility of failure;
- logging credentials or complete unprocessed network bodies;
- fixing a flaky test only by increasing a timeout without root-cause analysis;
- index/text selectors when a stable identifier is available;
- deleting or weakening a test solely to make CI green;
- changing public APIs or event schemas without compatibility analysis;
- manually editing generated files;
- claiming support without CI coverage for the relevant matrix.
- duplicate version, schema, or release-status sources that can drift apart.

## 5. Decision governance

Material decisions are recorded as ADRs in `docs/adr/NNNN-title.md`, covering context, alternatives, decision, consequences, and status. ADRs are mandatory for new modules/dependencies, concurrency model, telemetry schema, distribution, breaking APIs, and security/privacy policy.

Precedence: Constitution → approved specification/ADR → code style → contribution/AI guides → README. Exceptions must be narrow, explained in the PR, and amended here when they alter a principle.

## 6. Amendments

An amendment requires dedicated review, motivation, and migration impact. Versioning is major for changed principles, minor for added rules, and patch for meaning-preserving clarification. Amendment history remains in this document.

## 7. History

- 1.0, 2026-08-05 — initial version based on the repository audit and AI-first direction.
- 1.1, 2026-08-11 — added the binding production/release contract and single version source.
- 1.2, 2026-09-09 — preserve diagnostic UI evidence and clarify targeted credential filtering.
