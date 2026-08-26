# ADR 0011: Execution isolation, lazy components, calibrated visibility, and provider boundary

Status: accepted — 2026-08-09. The required-child portion is superseded by ADR 0013.

## Decision

Each XCTest execution owns one lock-protected reference state. Structured-concurrency work receives that state through task-local propagation; the thread-local bridge remains only for synchronous XCTest callbacks. Configuration, lifecycle, logging, attachments, and terminal-result ownership are all attached to the same execution state. A terminal transition is claimed atomically and exactly once.

Reusable Page Objects keep locator intent rather than resolved XCUI objects. `XCEasyComponent` may declare lazy required children, and `XCEasyComponentCollection` creates zero-based indexed components without an implicit UI-backed count. Every action, assertion, and value read resolves against the current accessibility tree.

Default visibility requires a finite nonempty element frame intersecting the application viewport. When XCUI supplies no usable viewport, XCEasy may use a finite element-frame fallback, but records a low-confidence reason. The optional `nonEmptyFrame` policy is explicit and is not the default.

An AI healing provider is an external command behind a versioned request/response contract. The adapter has a bounded timeout, passes arguments without shell evaluation, and accepts only a suggested candidate that already exists in diagnostic evidence. It cannot create approval, change assertions, mutate source, or publish artifacts.

## Consequences

Parallel child tasks share only their owning test state, and unrelated executions remain isolated. Component values can be retained across UI replacement without becoming stale. Negative assertions do not fail merely because an element is absent, while visibility claims expose their geometry confidence. Provider implementations are replaceable without expanding their authority; source changes still require separate review, approval, verification, and rollback.
