# ADR 0006: strict UI ambiguity and observable state transitions

Status: accepted — 2026-08-08.

## Decision

Unindexed locators use `XCEasyUIQueryAmbiguityPolicy.strict` by default. More than one candidate is `query.ambiguous_match`, not an implicit `firstMatch`. `.permissive` is an explicit compatibility mode and reports `query.ambiguous_first_match`. Every poll resolves the immutable root-to-child locator again and a bounded state-change timeline is retained. `assertBecomesHidden` proves `visible → hidden`; absence does not satisfy it.

## Consequences

Selectors that accidentally relied on first-match behavior now fail and must add a stable identifier, scope, or explicit index. Negative assertions continue to treat valid absence as success, but ambiguity never masquerades as absence. Failure-focused evidence captures a screenshot and bounded redacted hierarchy.
