# ADR 0010: Host reconciliation, performance history, and controlled healing

Status: accepted — 2026-08-09.

## Decision

Evidence that may outlive an XCTest process is reconciled by host tools, never by shared mutable runtime state. Missing planned executions become explicitly marked synthetic `broken` Allure results in a new directory; the logical run remains interrupted.

Cross-run performance comparisons use versioned JSON baselines segmented by an explicit environment key. A regression requires minimum sample count plus relative and absolute p95 growth. Historical retention belongs to CI or the user.

Healing remains provider-neutral and review-first. AI receives only an explicit, bounded, hash-addressed source bundle that passes secret checks. Applying a selector proposal requires a versioned human approval, exact source hash, one literal replacement, a fixed verification profile, and rollback on failure. Assertions and business expectations cannot be changed by this adapter.

## Consequences

Crash evidence is recoverable without fabricating success. Performance advice is reproducible and references source summaries. AI providers can change without changing the artifact contract. No source is mutated in the test runtime, and publication/signing authority remains outside automation.
