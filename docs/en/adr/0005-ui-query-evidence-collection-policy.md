# ADR 0005 — UI query evidence collection policy

Status: accepted. Date: August 8, 2026.

## Context

Development measurements showed that bounded UI candidate snapshots are useful for AI diagnosis, but reading labels, values, frames, and state from XCUI is a remote operation. Collecting those fields after every successful lookup made a representative UIKit banner test take 77.6 seconds. Successful unambiguous queries rarely need that full payload, while failures and ambiguous matches must retain it for self-healing.

The policy must be execution-scoped so parallel tests cannot change one another's evidence level. Canonical events must state whether candidates were absent in the UI or intentionally omitted by policy.

## Alternatives considered

- Always collect all candidate snapshots: strongest success evidence, unacceptable default overhead.
- Remove candidate snapshots entirely: fast, but violates failure-diagnosis and self-healing requirements.
- Randomly sample successful queries: useful at scale, but nondeterministic and harder to reason about in a single test artifact.
- Use deterministic levels with failure-focused default: predictable, configurable, and preserves complete failure evidence.

## Decision

Add execution-scoped `XCEasyConfig.uiQueryEvidenceLevel` with three values:

- `off`: do not emit `ui.query.*` events and skip candidate counts/snapshots; query behavior is unchanged.
- `basic`: default; emit query lifecycle, selector, state, duration, attempts, and candidate count, but capture bounded candidate snapshots only when the query fails or resolves ambiguously.
- `detailed`: emit the same lifecycle and capture up to five candidates for every completed query.

Schema `1.0.0` adds required `queryEvidence.evidenceLevel` and `queryEvidence.candidateCollection`. `candidateCollection` is `bounded` when snapshot collection was attempted and `omitted_by_policy` when the candidate array was intentionally skipped. `detailed` events must use `bounded`; `omitted_by_policy` requires an empty array.

## Verification

On an iPhone 17 Pro simulator running iOS 26.5, the same UIKit promo-banner integration test took 77.561 seconds with the pre-policy always-snapshot implementation and 23.505 seconds with the default `basic` policy, a local reduction of approximately 69.7%. The resulting artifact contained 44 schema-1.0.0 events and 10 completed UI queries; all successful unambiguous queries explicitly used `omitted_by_policy` with empty candidate arrays. This measurement validates the selected direction but is not a cross-device performance guarantee or the final F10 overhead budget.

## Consequences

- Default successful searches avoid the most expensive diagnostic reads.
- Failures and ambiguous selectors remain suitable for AI diagnosis and candidate ranking.
- Consumers can distinguish an empty match set from policy-based omission without inference.
- `off` is an explicit diagnostic tradeoff and should be reserved for controlled performance measurement or environments that prohibit query telemetry.
- Complete span phase accounting and an approved overhead budget remain future F10 work.
- This policy is included in the initial unpublished schema `1.0.0`; no consumer migration is required.
