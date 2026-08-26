# ADR 0008: components, performance, and controlled healing

Status: accepted — 2026-08-08.

## Decision

`XCEasyComponent` is the public reusable-POM boundary: it owns a lazy root, semantic name, root assertions, disappearance, and component steps. Performance collection is execution-scoped (`off/basic/detailed`) and produces per-test min/max/mean/median/p90/p95/p99 metrics plus budget findings. Budgets default to observe; warn and fail are explicit.

Healing is evidence-backed and defaults to observe. It ranks only type-compatible alternatives, blocks low confidence and near-equal candidates, and always marks proposals `requiresHumanApproval`. XCEasy never rewrites business expectations or source code automatically. `build-ai-handoff.sh` emits healing proposals, a semantic test-generation request, assumptions, evidence IDs, confidence, gaps, and reproduction guidance.

## Consequences

Optimization and healing findings cannot silently change a test from failed to passed. A changed selector requires review and a controlled rerun that retains the original failure.
