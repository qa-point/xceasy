# F04 — Reporting and AI diagnostics

0.1.1 status: runtime and host artifacts are implemented; retention and schema-support window are external policy boundaries.

## Goal

Produce a secure, self-contained diagnostic bundle useful to humans, Allure, and AI while preserving primary facts and versioned contracts.

## Implemented baseline

- Per-test human-readable logs are redacted before console/file sinks and persisted without ANSI control sequences.
- A versioned per-test JSONL stream is attached to Allure. Schema `1.0.0` adds execution/process/thread correlation, source, mandatory privacy metadata, attachment links, performance evidence, and bounded transition observations.
- Every test creates a per-test manifest, diagnostic summary, reproduction note, immutable log snapshot, performance summary, and owned artifacts. The registry records ID, basename, MIME, bytes, SHA-256, producer event, truncation, and privacy.
- Execution-scoped `off`/`basic`/`detailed` levels are implemented. The default `basic` preserves canonical query facts while collecting expensive candidate snapshots only for failures and ambiguous matches.
- The observer creates Allure result/container, executor, environment, and categories JSON.
- On an XCTest issue, a screenshot is saved and attached to the test/failed step when a foreground application window exists. Launch/context failures skip screenshot capture without recording another XCTest issue.
- A stable SHA-256 test ID is separate from the execution UUID; multi-device launches propagate run/device/shard/attempt correlation into events and Allure labels.
- When the independent `xceasy-runner` is used, it consumes these per-test artifacts and owns run-level diagnostic summaries, worker classifications, and integrity manifests.
- API request logs expose URL/method and payload sizes rather than raw headers/bodies; broader URL/payload redaction remains required.

## Requirements

- `F04-REQ-001`: canonical append-only `events.jsonl` conforms to a versioned JSON Schema.
- `F04-REQ-002`: the envelope contains schema version, timestamp, monotonic time, level, event, IDs, source, duration, data, attachments, and privacy.
- `F04-REQ-003`: the bundle contains `manifest.json`, `events.jsonl`, `summary.json`, artifact subdirectories, and a reproduction summary.
- `F04-REQ-004`: the artifact registry stores ID, relative path, MIME, size, SHA-256, producer event, and truncation.
- `F04-REQ-005`: targeted filtering of supported credential forms occurs before text sinks and is verified by canary tests. UI evidence and explicit debug output retain useful detail under [ADR 0021](../adr/0021-diagnostic-privacy-boundary.md); this is not a claim of complete anonymization.
- `F04-REQ-006`: failure taxonomy distinguishes product, test, infrastructure, framework, and unknown; fingerprints use stable fields.
- `F04-REQ-007`: Allure is an adapter of the canonical model; diagnostics work without Allure.
- `F04-REQ-008`: telemetry errors remain visible but never replace the original test outcome.
- `F04-REQ-009`: retention, payload limits, and sensitive attachments are configurable.
- `F04-REQ-010`: a CLI/validator checks schema, links, hashes, and secret scanning.
- `F04-REQ-011`: console log, per-test text log, and Allure consume the same canonical operation event and render it through the configured localization catalog.
- `F04-REQ-012`: human-readable log lines include timestamp, level, localized action text, outcome, and duration while preserving execution/test/step correlation fields in a stable machine-readable form.
- `F04-REQ-013`: sink configuration may change verbosity or suppress successful presentation entries, but canonical events required for AI diagnosis, lifecycle reconstruction, and performance analysis remain available in the per-test bundle.

The detailed contract for duration spans, aggregates, and regression findings is defined in [F10 — Performance telemetry](10_PERFORMANCE_TELEMETRY_EN.md).

## Acceptance criteria

- Every failed test creates a valid bundle readable without console output.
- The bundle identifies the first causal failure, expected/actual, source, and evidence IDs.
- Repeated instances of one defect produce the same fingerprint after dynamic-data normalization.
- Canary credentials covered by the tested filtering rules are absent from the corresponding text artifacts. UI/screenshot data is not asserted to be fully anonymized.
- Golden fixtures detect incompatible schema/artifact changes.
- A built-in successful action and a failed assertion have matching human-readable representations in text logs and Allure while remaining reconstructable from canonical events without parsing localized text.
- A changed indexed artifact or `.xcresult` bundle fails manifest validation, and the diagnostic summary exposes stable conclusion/action reason codes.

## Open questions

- `F04-OPEN-001`: define the compatibility support window when a diagnostic event schema newer than the initial `1.0.0` contract is published.
- `F04-DEC-002`: AI handoff is local and evidence-only by default; external transport requires explicit authorization.
- `F04-OPEN-003`: performance and storage budgets.
