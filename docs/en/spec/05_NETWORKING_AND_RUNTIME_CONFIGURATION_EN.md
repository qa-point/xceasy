# F05 — Networking and runtime configuration

0.1.1 status: runtime API is implemented; `F05-REQ-002` and complete cancellation/error taxonomy remain open.

## Goal

Provide reproducible test configuration, secure API-based data setup, and controlled integrations without global state leakage.

## As-is

- `XCEasyConfig` keeps backward-compatible static APIs, but snapshots mutable values per XCTest execution thread; localization catalogs use the same isolation boundary.
- `actionPolicy` belongs to the same execution snapshot; a local action override does not mutate configuration.
- `XCEasyAllureConfig` stores standard Allure link patterns such as `issue` and `tms`.
- The sole public launch Managers create execution-owned argument/environment copies before app launch; there is no duplicate DSL.
- `Deeplink.open(_ path:name:)` builds a URL from the path and current execution scheme without a separate route model. `LocalizationManager` and `XCDependencyContainer` provide the remaining runtime services.
- `ApiManager` preserves CRUD/PATCH callback and async APIs over an internal injectable transport. The production adapter uses Alamofire off the main queue; deterministic unit tests inject fakes. Every request uses the effective `XCEasyConfig.requestTimeout`; wait timeouts and invalid non-HTTP(S) URLs produce typed failures. Request logs include method/URL and sizes rather than raw headers/bodies.

## Requirements

- `F05-REQ-001`: effective configuration is immutable per execution and serialized after redaction.
- `F05-REQ-002`: validation rejects negative timeouts, invalid URLs/schemes, and unwritable destinations with typed errors.
- `F05-REQ-003`: environment/arguments are isolated between tests and deterministically ordered.
- `F05-REQ-004`: secrets are typed and never rendered raw.
- `F05-REQ-005`: networking is async-first with injectable transport; unit tests never use the real network.
- `F05-REQ-006`: API events contain sanitized URL, method, status, timings, sizes, and redacted attachment references.
- `F05-REQ-007`: timeout, cancellation, network, HTTP, and decoding failures have stable distinct codes.
- `F05-REQ-008`: deep-link construction validates scheme/path and emits a typed failure, never `fatalError`.
- `F05-REQ-009`: localization fallback is deterministic and missing keys are diagnosed.
- `F05-REQ-010`: reset APIs restore services to documented defaults.
- `F05-REQ-011`: report/log presentation locale is an execution-scoped configuration value; out of the box it defaults deterministically to English (`.en`, preserving the current public default) rather than depending on shared mutable process state.
- `F05-REQ-012`: XCEasy ships complete RU and EN catalogs for every built-in operation; applications may provide overrides or additional locales without changing canonical codes.
- `F05-REQ-013`: localization lookup follows `execution override → application catalog → framework catalog for requested locale → framework English fallback → diagnostic placeholder`; missing keys and parameters emit a non-recursive diagnostic event.
- `F05-REQ-014`: callback and async APIs use the execution-scoped `requestTimeout` and pass the same value to both the transport request and completion wait.
- `F05-REQ-015`: `actionPolicy` has documented default `.hittable`, is isolated between executions, and is read at semantic action time.

## Acceptance criteria

- Unit tests use fake transport/clock/config store and require no simulator/network.
- Parallel tests never observe another execution's environment/configuration.
- A redaction matrix covers headers, query, JSON, form, and text bodies.
- Cancellation and timeout complete a request/step exactly once.
- Callback and async success/failure branches are unit-tested without a real network.
- Changing `requestTimeout` is reflected in the created `URLRequest` and does not leak into a neighboring parallel execution.
- Changing `actionPolicy` inside one execution does not leak into a neighboring parallel execution; a local override does not change the snapshot.
- Two parallel executions may use different presentation locales without mixing localized steps or logs.
- An unknown locale or missing application override still produces a readable built-in message and a localization diagnostic without failing the test.

## Open questions

- `F05-OPEN-001`: retain Alamofire or move to a URLSession abstraction.
- `F05-OPEN-002`: compatibility strategy for singleton static APIs.
