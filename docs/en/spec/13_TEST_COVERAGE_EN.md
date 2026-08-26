# F13 — Test coverage and quality gates

0.1.0 status: unit/UI coverage gate is implemented; diff coverage is deferred until stable history exists.

## Goal

Keep framework behavior verifiable as XCEasy evolves, while separating deterministic unit contracts from behavior that requires a live XCTest UI runner.

## Implemented baseline

- Framework unit and internal fixture commands enable Xcode code coverage and persist separate `.xcresult` bundles.
- `scripts/validate-code-coverage.sh` exports and merges unit plus fixture coverage with `xccov`, then evaluates only `XCEasy.framework`.
- `scripts/coverage-policy.json` sets a 70% aggregate line floor. Deterministic identity, artifact isolation, privacy redaction, ambiguity, and lifecycle files require 100%; lazy search requires 85% and UI assertion orchestration requires 65%.
- `scripts/evaluate-code-coverage.sh` emits a machine-readable JSON summary and returns a non-zero status on an aggregate, critical-file, or missing-target violation. Shell contract fixtures prove every rejection path.
- Deterministic API behavior uses an injected transport and unit tests instead of the network. All callback/async HTTP methods and typed response branches are exercised.
- The internal fixture target runs every SwiftUI/UIKit integration test. Banner scenarios prove lazy re-resolution, visible/hittable state, removal transitions, and absence-safe negative assertions against a live accessibility tree.

## Requirements

- `F13-REQ-001`: production coverage is collected from both framework unit tests and the supported internal UI integration fixture.
- `F13-REQ-002`: coverage inputs are merged before evaluation so code executed in different XCTest runners is counted once.
- `F13-REQ-003`: the gate selects `XCEasy.framework` explicitly and excludes dependencies, applications, generated code targets, and test targets from the aggregate threshold.
- `F13-REQ-004`: every deterministic branch is covered by unit tests using injected fakes, without real network, external services, or arbitrary sleeps.
- `F13-REQ-005`: XCUI resolution, actions, negative states, and lifecycle integration are covered by simulator tests in both SwiftUI and UIKit fixtures where platform behavior matters.
- `F13-REQ-006`: identity, per-test artifact isolation, redaction, query ambiguity, and lifecycle state-machine files maintain 100% line coverage.
- `F13-REQ-007`: aggregate and file thresholds are machine-readable, reviewed like source code, and may not be reduced merely to make CI pass.
- `F13-REQ-008`: CI uploads raw `.xcresult`, merged coverage JSON, and policy summary for human and AI diagnosis.
- `F13-REQ-009`: a coverage failure reports actual/required values and the exact target or file that failed.
- `F13-REQ-010`: coverage percentage supplements behavioral assertions; it never proves correctness or replaces positive, negative, concurrency, privacy, and artifact-integrity tests.

## Acceptance criteria

- `./scripts/check.sh all` runs contracts, build, complete unit/fixture suites, and the aggregate coverage policy.
- `./scripts/check.sh coverage` can re-evaluate existing unit and fixture `.xcresult` bundles without rerunning tests.
- A fixture below the aggregate threshold, below a critical-file threshold, or missing the framework target is rejected.
- All configured critical files exist in the coverage report and meet their individual thresholds.
- CI artifacts contain enough structured evidence to identify uncovered files without parsing the build console.

## Decisions and remaining work

- `F13-DEC-001`: line coverage is the portable CI gate because Xcode emits it consistently for both unit and UI runners.
- `F13-DEC-002`: thresholds are staged and non-decreasing. Platform failure branches that intentionally call `XCTFail` are not forced to 100% merely for a metric.
- `F13-DEC-003`: third-party and test-code coverage is reported by Xcode but excluded from the product gate.
- `F13-OPEN-004`: introduce diff coverage after the repository has a stable main-branch history and approved external reporting policy.
