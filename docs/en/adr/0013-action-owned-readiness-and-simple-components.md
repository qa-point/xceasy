# ADR 0013: Actions own readiness and component contracts stay simple

## Status

Accepted on August 10, 2026. Supersedes the required-child parts of ADR 0011 and ADR 0012.

## Context

The first component API allowed `requiredChildren`. This gave `component.assertIsDisplayed()` hidden semantics: the same call could validate only the root or an arbitrary child set. Users still expected `closeButton.tap()` to wait for actionability itself. A dedicated `tapPolicy` would fix only one gesture and leave other actions with a different lifecycle.

The project is not used in production, so retaining extra beta API through deprecated aliases has no migration value.

## Considered options

1. Keep `requiredChildren` as automatic component readiness.
2. Remove hidden child metadata and let every action own its wait.
3. Add a policy only for `tap`.
4. Add one execution-scoped policy for every UI action with a local override.
5. Automatically fall back from hittable to coordinate dispatch.

## Decision

- `XCEasyComponent` requires only `root`; `componentName` and root helpers remain default API.
- `XCEasyComponentRequirement`, `XCEasyRequiredChildState`, `requiredChildren`, and `assertRequiredChildren()` are removed without deprecated aliases.
- `component.assertIsDisplayed()` validates only the root. Composite readiness receives an explicit domain name such as `assertIsReady()` inside the POM.
- `XCEasyActionPolicy` applies to `tap`, `doubleTap`, `press`, `swipe`, `typeText`, and `clearField`.
- `.hittable` is the default and performs semantic XCUI dispatch after a fresh state observation.
- `.displayed` is an explicit compatibility mode: it waits for display and uses coordinate dispatch. There is no automatic fallback.
- `XCEasyConfig.actionPolicy` is execution scoped; an action's `policy` argument is a local override.
- Effective policy, waited state, and dispatch are stored in canonical diagnostics; coordinate mode has warning level. Input text and current field values are not logged.

## Consequences

Page Objects are shorter, and identical component assertions have identical meaning. Actions targeting text, icons, or containers wait for an appropriate state themselves. `.displayed` remains available for unusual accessibility trees, but its risk is visible in source and artifacts.

A beta user removes `requiredChildren` and, when needed, moves composite validation into a named POM method. Existing no-argument action calls continue to compile and gain safe `.hittable` readiness.

The public Swift interface and RU/EN documentation update in one iteration. Unit plan/config tests and UIKit/SwiftUI samples verify the behavior.
