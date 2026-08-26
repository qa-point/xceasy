# F02 — UI elements and interaction

0.1.0 status: implemented and verified; Objective-C forwarding remains an internal technical-debt boundary.

## Goal

Provide a fluent, type-safe, diagnosable layer over XCUI queries/actions without hiding ambiguity or element state.

## As-is

- `find`/`child` query by type, identifier, predicate, text, and index.
- `XCEasyUIElement` lazily resolves `XCUIElement` and uses Objective-C forwarding.
- Taps, press, text input/clear, swipes, reads, and state checks are implemented.
- Every UI action uses execution-scoped `XCEasyActionPolicy`: `.hittable` waits for safe semantic dispatch, while explicit `.displayed` waits for display and uses coordinate dispatch with warning evidence. Each call may override policy and timeout locally.
- Strict ambiguity is the default; indexes use `element(boundBy:)`, while explicit permissive mode uses the first match and records a warning.
- `Device` supports coordinate actions, orientation, clipboard read, and wait.
- At evidence levels `basic` and `detailed`, every UI resolution builds an immutable redacted root-to-child descriptor and emits schema `1.0.0` query lifecycle evidence with SHA-256 fingerprint, expected/initial/final state, bounded observation timeline, duration, attempts, candidate count, selected/failed segment, source/correlation, performance, and explicit candidate-collection policy.
- `basic` is the failure-focused default: bounded candidate snapshots are collected for failed or ambiguous queries. `detailed` collects them for every query; `off` suppresses query events without changing lookup semantics.
- Query events link to their enclosing action/assertion. Strict ambiguity fails with `query.ambiguous_match`; permissive ambiguity is reported as `query.ambiguous_first_match`. Failed XCTest issues capture a size-bounded redacted accessibility snapshot and screenshot into the owning diagnostic bundle.
- Predicate/text selector values and candidate label/value fields use typed placeholders plus lengths. Stable identifiers remain readable after pattern redaction.

## Requirements

- `F02-REQ-001`: selectors use an immutable model containing type, strategy, value, parent, and optional index.
- `F02-REQ-002`: resolution records normalized selector, timeout, elapsed time, candidate count, and selected candidate.
- `F02-REQ-003`: strict mode fails ambiguous selectors with a typed error; permissive mode explicitly logs first-match selection.
- `F02-REQ-004`: failed queries save a bounded UI snapshot/accessibility tree and screenshot reference.
- `F02-REQ-005`: actions validate required preconditions and emit before/after state.
- `F02-REQ-006`: sensitive text input is redacted in every sink while length/type metadata remains.
- `F02-REQ-007`: no public interaction path uses `fatalError` or force unwrap.
- `F02-REQ-008`: selector priority and stability warnings are available to Page Object authors.
- `F02-REQ-009`: condition-based waits replace fixed sleeps; intentional time waits require a reason.
- `F02-REQ-010`: every semantic operation (`tap`, assertion, value read, and equivalent use) starts resolution against the current accessibility tree; an element resolved by an earlier operation is never reused as current state.
- `F02-REQ-011`: every polling attempt reevaluates the complete locator chain against a fresh accessibility snapshot rather than polling a previously resolved `XCUIElement` or snapshot.
- `F02-REQ-012`: implementations may cache immutable locator/query-plan metadata, but never cache resolved elements, snapshots, existence, visibility, hittability, values, or frames across semantic operations.
- `F02-REQ-013`: every built-in UI action performs a policy-specific condition wait and never dispatches after a readiness timeout.
- `F02-REQ-014`: automatic fallback from a safe semantic action to coordinate dispatch is prohibited.

The locator/observation model and negative-state semantics are defined in [F11 — UI element state and negative assertions](11_ELEMENT_STATE_AND_NEGATIVE_ASSERTIONS_EN.md).

Immutable parent-chain and reusable component-POM rules are defined in [F12](12_REUSABLE_COMPONENT_POM_EN.md).

The complete action-readiness, dispatch, and diagnostic matrix is defined in [F15](15_UI_ACTION_POLICY_EN.md).

## Acceptance criteria

- Tests cover every query strategy, parent scope, zero/one/many matches, and out-of-range index.
- A failed-action bundle identifies selector, precondition, observed state, and duration.
- A canary password is absent from console, JSONL, Allure, and attachments.
- The fluent API remains source-compatible or provides deprecation migration.
- A locator stored before a UI mutation observes the post-mutation tree when it is used afterward.
- A polling assertion detects an element that appears, disappears, or is replaced during its timeout without reconstructing the public locator.

## Open questions

- `F02-OPEN-001`: retain the Objective-C proxy or move to explicit wrapped operations.
- `F02-DEC-002`: an accessibility snapshot is a size-bounded redacted attachment; `diagnosticSnapshotByteLimit` controls the limit, while the manifest records integrity and truncation.
