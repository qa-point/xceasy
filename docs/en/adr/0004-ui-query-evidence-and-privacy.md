# ADR 0004 — UI query evidence and privacy

Status: accepted. Date: August 8, 2026.

## Context

Lazy locator chains and correct negative assertions make UI tests reliable, but they do not by themselves explain why a query succeeded or failed. Human and AI diagnosis needs the complete selector scope, observed state, candidate count, polling timeline, and bounded alternatives. Raw text, predicates, labels, and values may contain credentials or personal data and therefore cannot be copied into diagnostics by default.

XCUI also exposes a consistency edge case: `XCUIElementQuery.count` may temporarily report zero while the selected `firstMatch.exists` is true. Treating the count as stronger evidence creates false `ancestor_absent` conclusions.

## Decision

Diagnostic event schema `1.0.0` adds `parentOperationId`, `selector`, and `queryEvidence`. Every semantic UI resolution emits `ui.query.started` followed by `ui.query.resolved` or `ui.query.failed`. The query operation has its own ID and links to the enclosing action/assertion operation when one exists.

`selector` is an immutable root-to-child sequence of type, strategy, redacted value metadata, and optional index. Its SHA-256 fingerprint is deterministic over the privacy-safe representation. `fingerprintConfidence` is `exact` for unchanged stable identifiers and `privacy_reduced` when predicate/text/secret-bearing input was replaced; consumers must not treat a privacy-reduced collision as element identity proof.

`queryEvidence` records expected, initial, and final states; match result; canonical reason code; elapsed milliseconds; attempts; matching candidate count; selected index; failed locator segment; ancestor state; and up to five candidate snapshots. Candidate identifiers receive pattern redaction. Selector text/predicate and candidate labels/values become typed placeholders with original lengths before any sink.

An existing selected element is primary evidence of a segment match. The effective candidate count is at least `selectedIndex + 1` when `exists == true`, even if XCUI reports a smaller count. A missing ancestor produces `query.ancestor_absent`; a missing final segment produces `query.element_absent`; permissive multi-match selection produces `query.ambiguous_first_match` with warning level.

The checked-in JSON Schema is `schemas/diagnostic-event-1.0.0.schema.json`. `scripts/validate-diagnostic-events.sh` provides the dependency-free structural/canary contract check used by the repository.

## Consequences

- AI can reconstruct component scope and negative-assertion outcomes without parsing localized prose.
- Query events correlate with the action/assertion that caused resolution.
- Sensitive labels, values, text selectors, and predicates are unavailable in raw form; diagnosis uses stable identifiers, lengths, state, geometry, and bounded alternatives.
- Candidate counting and snapshot reads add query overhead. The evidence is bounded, and performance must continue to be measured.
- Strict ambiguity failure, complete accessibility snapshots, screenshots on timeout, source locations, and configurable privacy policy remain future work.
- This decision is part of the initial unpublished schema `1.0.0`; no consumer migration is required.
