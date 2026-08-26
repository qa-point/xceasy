# ADR 0014: Component containers and shared step lifecycle

## Status

Accepted on August 10, 2026. Supersedes the component naming and step-API portions of ADR 0008, ADR 0011, ADR 0012, and ADR 0013. Action-owned readiness from ADR 0013 remains unchanged.

## Context

The beta component contract used `root`, which could be confused with the root of the accessibility tree. It also exposed `componentStep` even though that function used the same Allure step semantics as the ordinary `step`. Users had to remember two names for one lifecycle. A type-only `componentName` was insufficient when several instances of the same POM appeared on one screen.

Indexing does not apply to every component. Making index `0` implicit in the base protocol would hide duplicate identifiers for unique components, while repeated cards and rows benefit from a concise default.

## Decision

- `XCEasyComponent` requires `container: XCEasyUIElement`; the beta `root` requirement is removed without a deprecated alias.
- Component assertions and waits delegate only to `container`. Children remain explicit and lazy.
- `componentName` still defaults to the concrete type name. A POM may accept an optional initializer argument and store an instance-specific name.
- `componentStep` is removed. `XCEasyComponent` provides sync and async instance overloads named `step` with the same source-location defaults as the global function.
- Global and component steps delegate to one internal executor and one execution-scoped stack. Allure nesting, thrown-error finalization, deferred failures, and task-local propagation are identical.
- Component events keep schema `1.0.0` and use existing fields: `operationCode = component.step`, `target = componentName`, and `selector = container.locatorDescriptor`. The Allure title is `<componentName>: <operation>`.
- `XCEasyIndexedComponent` is a separate protocol requiring `init(index:componentName:)`. Its extensions add `init()`, `init(index:)`, and `init(componentName:)`; an omitted index means zero.
- `XCEasyComponentCollection` behavior does not change in this decision.

## Consequences

POM code uses one unambiguous container name and one step spelling. AI tooling receives stable structured component identity instead of parsing localized titles. Multiple identical components can be distinguished at initialization without changing their locator semantics.

The change is source-breaking for the unpublished beta API. Consumers migrate `root` to `container`, `componentStep` to `step`, and repeated POMs to `XCEasyIndexedComponent` when default indexing is useful. Unit tests cover sync, async, nested component and ordinary steps, assertion nesting, structured telemetry, index defaults, and stack restoration after an error. UIKit/SwiftUI sample tests cover real nested actions and assertions.
