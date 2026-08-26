# ADR-0016 — Component `element` and `collection` naming

## Status

Accepted on August 10, 2026. This decision supersedes the public naming portions of ADR-0014 and ADR-0015 for the unpublished beta API.

## Context

`XCEasyComponent.container` could be mistaken for the accessibility-tree root or for an Allure result container. `XCEasyIndexedComponent.collectionContainer` was longer while still failing to make the all-instances versus one-instance relationship immediately clear.

The API needs two short names with distinct meanings: one locator that matches every repeated instance and one locator that represents the selected component instance.

## Decision

- `XCEasyComponent` requires `element: XCEasyUIElement`.
- `XCEasyIndexedComponent` additionally requires static `collection: XCEasyUIElement`.
- A positioned POM derives `element` through `Self.collection.element(at: position, ...)`.
- `container` and `collectionContainer` are removed without deprecated aliases because this public surface has not shipped to production.
- Canonical telemetry keeps the existing generic `selector` field and operation codes. Standard Allure `*-container.json` artifacts are unrelated and remain unchanged.

## Consequences

Call sites read as “all matching instances” (`collection`) versus “this component” (`element`). Component assertions and component-owned steps delegate to `element`; collection count and visibility operations query `collection`. The previous naming existed only in an unpublished beta surface, so no consumer migration contract is retained.
