# XCEasy Code Style

## 1. Baseline

Follow Swift API Design Guidelines and the existing project structure. This document defines binding local rules. SwiftLint is pinned in `mise.toml`; `.swiftlint.yml` is the executable source of truth without overriding the constitution.

## 2. Formatting and files

- Four spaces, no tabs or trailing whitespace, and one final newline.
- One primary public/internal type per file; filename matches the type. Group extensions as `Type+Concern.swift`.
- Order: imports, type declaration, nested types, properties, initializer, public methods, internal/private methods, extensions.
- Use `// MARK: -` for substantial sections, not every method.
- Never edit generated directories or treat them as style examples.
- Keep imports minimal; order Apple/system modules before external modules.
- Render documentation diagrams as ASCII in fenced `text` blocks. Do not use Mermaid, so diagrams stay readable in GitHub, IDEs, terminals, and AI context.

## 3. Naming and APIs

- Types use `UpperCamelCase`; methods, properties, and locals use `lowerCamelCase`.
- Booleans read as assertions: `isEnabled`, `hasAttachments`, `shouldRedact`.
- Avoid obscure abbreviations; XCTest, UI, URL, ID, API, and HTTP are acceptable.
- Design public APIs from the caller's perspective and document behavior, parameters, return value, failure semantics, and thread safety where relevant.
- Default parameters must not conceal expensive or dangerous operations.
- State-changing fluent methods consistently use `@discardableResult` and return `Self`.
- New API spelling mistakes are prohibited. Migrate existing `Delimeters` to `Delimiters` through deprecation rather than an immediate break.

## 4. Types, errors, and optionals

- Prefer value types for immutable event/config/model data.
- Inject dependencies through protocols/initializers; a new global singleton requires an ADR.
- Do not use `!`, `as!`, `try!`, or `fatalError` on runtime paths. A proven programmer invariant requires a comment and test.
- Do not suppress errors with `try?` when they affect artifacts/results; emit a typed error and return or throw it.
- Domain errors use enums/structs with a machine-readable code and safe description.
- Use `guard` for preconditions and early exits; keep the happy path flat.

## 5. Concurrency

- Every mutable shared state has a documented owner and synchronization strategy.
- Never invoke user callbacks while holding a lock/barrier.
- IDs and test-scoped state must not rely solely on a global singleton during parallel execution.
- Execution state shared by structured child tasks uses task-local propagation plus one documented lock-protected reference owner; thread-local storage is only a synchronous XCTest bridge.
- Prefer async APIs to blocking expectation wrappers; resume continuations exactly once.
- Add race/parallel tests when changing context, observer, logger, or sinks, and run `./scripts/check.sh race` before handoff.

## 6. Logging and telemetry

- Event names use lowercase dot notation (`ui.query.failed`); fields use `snake_case`.
- Canonical keys/message codes are English; localized text is a presentation field.
- Log facts and evidence, not guesses. Mark hypotheses explicitly.
- Every event gets source/correlation IDs through a common emitter.
- Redact before a sink; never write raw data and sanitize it later.
- Store expected and actual separately; durations are numeric with units in field names.
- Do not alter event semantics without schema versioning and migration.

## 7. XCTest and UI tests

- Test names describe behavior and outcome; business IDs belong in `id()`.
- Use Arrange/Act/Assert or Given/When/Then consistently.
- Encapsulate UI details in Page Objects; outcome assertions may remain in tests.
- Selector priority: accessibility identifier → typed stable predicate → text → index.
- Timeouts come from configuration or a named reason; magic sleeps are prohibited unless time itself is under test.
- Failure messages contain operation, target, expected, actual, and elapsed time.
- A regression test fails on the old implementation and passes after the fix.

## 8. Testability

- Cover pure logic with simulator-free unit tests.
- Cover observer/UI integration with integration/UI tests.
- Test telemetry/serialization with schema, golden, and malformed-input cases.
- Use table-driven redaction tests with canary secrets.
- Do not use the real network in deterministic unit tests; inject a stubbed protocol/session.

## 9. Comments

Comments explain why, an invariant, or an external constraint rather than restating code. TODOs include an owner/issue: `TODO(QP-123): ...`. Delete commented-out code and author/date/file banners.

Every callable declaration in hand-written production Swift sources has an English DocC comment. Public API documentation states behavior, parameters, return value, thrown/failure semantics, and concurrency or privacy constraints where relevant. Add a compiling usage example for non-obvious public workflows; trivial private helpers need a concise contract instead of a ceremonial example. Documentation must describe lazy or deferred behavior accurately and must not claim that work happens during construction when it happens during a later operation. `scripts/validate-swift-documentation.sh` enforces coverage and rejects legacy banners. User guides remain aligned in RU/EN.
