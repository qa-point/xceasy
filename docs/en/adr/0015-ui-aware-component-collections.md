# ADR-0015 — UI-aware component collections

## Status

Accepted on August 10, 2026. This decision supersedes the no-UI-count portion of F12-DEC-003 and ADR-0011 for the unpublished beta collection API.

## Context

The closure-based `XCEasyComponentCollection` only created optional components by an integer index. It duplicated a factory at every call site, could not represent a current `last` item, and offered no domain operations for count, emptiness, or visibility. Tests fell back to optional subscripts and `prefix`, which described neither the expected UI state nor useful failure evidence.

Collection access must remain lazy, while explicit waits and assertions must observe the current accessibility tree. Every operation must be understandable in localized Allure output and in structured AI diagnostics.

## Decision

- `XCEasyIndexedComponent` declares a common `collectionContainer` and `init(position:componentName:)`.
- `XCEasyComponentPosition` represents `.first`, `.last`, or `.index(Int)`. `last` stays symbolic until semantic use.
- `XCEasyComponentCollection<Component>()` replaces the closure initializer. The optional subscript, `component(at:)`, and `prefix(_:)` beta APIs are removed without deprecated aliases.
- `first`, `last`, `get(index:)`, and `get(indices:)` create locator intent without reading UI.
- Exact/lower/upper count, empty/nonempty, and all-displayed waits/assertions explicitly query a fresh current-tree snapshot on every polling attempt.
- An empty collection never satisfies all-displayed. Negative indices and empty-last selection fail diagnostically without passing an invalid index to XCUI.
- Every public collection getter, wait, and assertion creates a localized default step and canonical `ui.collection.started`/`ui.collection.finished` events.
- Diagnostic schema 1.0.0 adds selector-segment `selection` and bounded `collectionEvidence`. It retains expected/actual counts, attempts, duration, display failures, source, performance, context availability, and at most 50 state observations or 100 requested indices.

## Consequences

Selection remains safe before UI availability, while state reads are visible in method names. A retained `last` component follows collection mutations. Failure evidence is usable by people and automated repair tools without parsing localized prose. The source break affected an unpublished beta surface only; no consumer migration contract is required.

Real SwiftUI sample coverage exercises count, all-displayed, first, last, and indexed access. Deterministic unit tests cover successful and failing bounds, empty collections, evidence, steps, and symbolic locator descriptors.
