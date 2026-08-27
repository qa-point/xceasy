# F07 — Allure lifecycle and compatibility

0.1.1 status: implemented and verified.

## Accepted product decisions

- XCEasy supports Allure Report 2 and Allure Report 3.
- XCEasy does not upload launches to Allure TestOps. It creates standard results; an external CLI performs upload.
- XCEasy's mandatory output is an aggregated `allure-results` directory. The framework does not generate HTML.
- Canonical diagnostic events do not depend on Allure; the Allure writer is an adapter.

## Goal

After every XCTest execution, emit a complete, valid, independently written Allure artifact set suitable for aggregation, report generation by both Allure versions, and later CLI upload.

## Implemented baseline

- `*-result.json`, `*-container.json`, screenshots, logs, `executor.json`, `environment.properties`, and `categories.json` are created.
- Models contain most basic Allure 2 fields.
- Execution UUID, stable SHA-256 `testCaseId`, deterministic parameter-aware `historyId`, standard labels, and a public redacted parameter API are implemented.
- Parameters support excluded/default/masked/hidden modes. Result, container, service JSON, screenshots, diagnostic data, and performance summaries use atomic writes.
- In-process Allure validation checks identities, timelines, fixture links, and every attachment. Aggregate shell validation applies the same stable-identity contract. Allure 2/3 generator fixtures remain an external compatibility gate.

## Lifecycle requirements

- `F07-REQ-001`: the adapter implements explicit key-addressed schedule/start/update/stop/write lifecycle for tests, fixtures, and steps.
- `F07-REQ-002`: `uuid` is unique per execution; `testCaseId` is stable per XCTest case; `historyId` is deterministic from `testCaseId` and sorted non-excluded parameters.
- `F07-REQ-003`: full name uses module, qualified class, and method, independent of display name.
- `F07-REQ-004`: retries of one test+parameters have different UUIDs and the same history ID.
- `F07-REQ-005`: parameters support `excluded`, `masked`, and `hidden`; UI hiding never replaces pre-storage redaction.
- `F07-REQ-006`: `framework`, `language`, `host`, `thread`, `package`, `testClass`, `testMethod`, suite hierarchy, and device/environment labels are added automatically.
- `F07-REQ-007`: Setup/Teardown are container fixtures; every `children` entry references an existing test UUID.
- `F07-REQ-008`: attachments have UUID filenames, MIME types, and owning test/fixture/step; results are written only after referenced attachments complete.
- `F07-REQ-009`: JSON and attachments use temporary files plus atomic rename.
- `F07-REQ-010`: status/stage/statusDetails conform to Allure enums and distinguish assertion failure, unexpected framework error, skipped, and interrupted.
- `F07-REQ-011`: Allure 2 environment/executor/categories/history inputs remain conflict-free; Allure 3 receives labels required for environments.
- `F07-REQ-012`: no custom field substitutes for a standard Allure field.
- `F07-REQ-013`: contract fixtures are processed by both Allure 2 and Allure 3 generators.
- `F07-REQ-014`: XCEasy never invokes `allure generate`, does not require Allure CLI during tests, and completes a run after validating aggregated `allure-results`.
- `F07-REQ-015`: simulator/device test-runner artifacts are exported to a host-level directory by a deterministic post-run command; export refuses a non-empty destination to prevent cross-run contamination.

## Public capability

Expose metadata, parameter, link, issue/TMS, description, severity/owner/tags, known/muted/flaky, step, text/data/file attachment, and environment APIs. Keep the low-level lifecycle internal or advanced so users cannot accidentally violate its state machine.

## Acceptance criteria

- One test creates exactly one valid result and a correct fixture container.
- Nested steps and attachments render under the correct owner in Allure 2 and 3.
- History survives display-name changes; device parameters separate matrix executions.
- An interrupted/crashed worker cannot corrupt completed results from other tests.
- Allure CLI accepts generated results without missing-reference/invalid-field warnings.

## Official contracts

- [Test result file](https://allurereport.org/docs/how-it-works-test-result-file/)
- [Container file](https://allurereport.org/docs/how-it-works-container-file/)
- [Test identifiers](https://allurereport.org/docs/how-it-works-test-identifiers/)
- [History and retries](https://allurereport.org/docs/history-and-retries/)
