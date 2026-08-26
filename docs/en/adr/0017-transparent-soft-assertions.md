# ADR-0017 — Transparent execution-scoped soft assertions

## Status

Accepted on August 10, 2026. This decision replaces the unpublished public collector API described by the original F03 implementation.

## Context

The former `softly { check in check.expect... }` syntax created a second assertion vocabulary and did not support UI-element or component-collection assertions. POM authors had to translate ordinary checks into collector calls, losing the natural component-oriented test form and part of the operation-specific evidence.

Soft behavior must remain explicit at the group boundary while every assertion inside the group keeps its regular API, locator diagnostics, timing, localization, and Allure nesting. Parallel tests and async suspension must not share failures. Actions and framework errors must not be weakened.

## Decision

- `softly("Title") { ... }` installs bounded storage in the current `XCEasyExecutionState` and accepts a closure without parameters.
- Value, UI-element, component, and component-collection assertion failures use one internal router. When a soft scope exists, the router records a redacted mismatch instead of immediately creating an XCTest issue.
- A monotonic execution-scoped failure version marks the causal assertion step and every enclosing step as failed without throwing or stopping the block.
- Closing the scope emits one aggregate XCTest issue containing at most 50 detailed mismatches; additional mismatches remain counted.
- Sync and async overloads share the same task-propagated execution state.
- Actions, thrown step errors, configuration failures, performance-policy failures, and other framework failures bypass the assertion router and remain hard.
- The unpublished `XCEasySoftAssertions`, `expect`, `expectEqual`, and `expectNotNil` public API is removed without deprecated aliases.

## Consequences

Tests and POMs use one assertion vocabulary in hard and soft contexts. Existing per-operation diagnostics remain available to humans and AI tooling, while XCTest receives one concise group failure. The scope boundary is behaviorally significant and should contain independent checks only; a prerequisite assertion belongs outside `softly`.
