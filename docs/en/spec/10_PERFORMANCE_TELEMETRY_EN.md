# F10 — Performance telemetry and optimization

0.1.1 status: per-test collection and budgets are implemented; cross-run comparison is implemented by the independent runner and project thresholds belong to user/CI.

## Goal

Measure the cost of XCEasy operations in every execution, identify slow and regressed test paths, and provide evidence-backed optimization recommendations without conflating application, test-code, and infrastructure latency.

## Measurement scope

Mandatory instrumentation covers:

- UI query/resolution and condition waits;
- UI actions: tap, type, clear, swipe, press, and coordinate actions;
- general/UI assertions and polling;
- user steps and Setup/Teardown fixtures;
- app launch/terminate/reopen;
- API request and response phases;
- screenshots, UI snapshots, serialization, and artifact writes;
- per-test serialization and artifact writes; an external runner measures its own aggregation and validation;
- self-healing analysis and verification rerun when enabled.

## Implemented slice

Execution-scoped `XCEasyConfig.performance` implements `off`, `basic`, and `detailed`; `basic` is the default. UI queries, operations, assertions, and user/fixture steps record monotonic durations and schema 1.0.0 performance evidence. Every test attaches `performance-summary.json` with count, min, max, mean, median, p90, p95, and p99 plus budget findings and dominant-phase suggestions. Cross-run baseline construction, comparison policy, and run-level summaries belong to the independent `xceasy-runner`; XCEasy emits the versioned per-test input. Critical-path reconstruction and instrumentation-overhead measurement remain future work.

## Time model

- Wall-clock timestamps provide the global timeline and Allure `start`/`stop`.
- Durations use only a monotonic clock and survive system-clock changes.
- Every operation is a span with `span_id`, `parent_span_id`, `operation_key`, start/stop, outcome, and phase durations.
- `operation_key` is stable across runs and contains no dynamic selector values, secrets, or UUIDs.

Example UI action breakdown:

```json
{
  "event": "ui.action.finished",
  "operation_key": "ui.button.tap",
  "duration_ms": 8420,
  "phases_ms": {
    "resolve": 34,
    "wait_exists": 8010,
    "wait_hittable": 210,
    "interaction": 41,
    "stabilization": 125
  },
  "outcome": "passed"
}
```

## Collection requirements

- `F10-REQ-001`: every instrumented operation records wall start/stop and monotonic `duration_ns`/`duration_ms`.
- `F10-REQ-002`: duration is split into meaningful phases; phase totals do not exceed total beyond documented overlap.
- `F10-REQ-003`: waiting is separated from active framework work and application/network latency.
- `F10-REQ-004`: spans link to run, execution, test, step, worker, device, source location, and canonical target ID.
- `F10-REQ-005`: success, failure, timeout, cancellation, and interruption always terminate the span with an outcome.
- `F10-REQ-006`: async/parallel child spans are not summed as sequential time; the critical path is preserved.
- `F10-REQ-007`: instrumentation overhead is measured separately and excluded from operation duration.
- `F10-REQ-008`: dynamic/sensitive values are not metric dimensions; redaction occurs before sinks.
- `F10-REQ-009`: users can select `off`, `basic`, or `detailed`; default is low-overhead `basic`.
- `F10-REQ-010`: successful high-frequency operations may be sampled, while failures/timeouts are always complete.

## Aggregation and trends

- `F10-REQ-011`: per-run `performance-summary.json` contains count, success/failure, min, max, mean, median, p90, p95, and p99 by operation key.
- `F10-REQ-012`: statistics are segmented by compatible environment: device class, OS major, app build, Xcode/toolchain, and execution mode.
- `F10-REQ-013`: shard/worker IDs do not split baselines when environments match; simulators and physical devices are not compared directly.
- `F10-REQ-014`: a baseline has ID/version, sample count, time window, and environment matcher.
- `F10-REQ-015`: regression requires relative change, absolute change, and a minimum sample threshold to suppress noise.
- `F10-REQ-016`: cold start, warm-up, retry, and healed executions are tagged and compared only to the matching class.
- `F10-REQ-017`: run summary reports top slow operations, top regressions, near-timeout operations, and critical-path contribution.
- `F10-REQ-018`: Allure steps retain duration for visual analysis; detailed aggregate statistics are attached as separate JSON/Markdown artifacts.
- `F10-REQ-019`: XCEasy does not retain history indefinitely; external CI/report storage provides the prior baseline or history input.

## Budgets and recommendations

- `F10-REQ-020`: configuration supports global, operation-type, and exact-operation budgets with warning/fail/observe policies.
- `F10-REQ-021`: budget breaches do not change test outcome by default; they create performance findings. Fail policy is explicit opt-in.
- `F10-REQ-022`: recommendations include operation/source, evidence span IDs, baseline/current metrics, dominant phase, confidence, and suggested action.
- `F10-REQ-023`: recommendations distinguish likely slow app state, unstable selector, excessive timeout, repeated query, serializable parallel work, slow network, heavy artifact, and framework overhead.
- `F10-REQ-024`: AI never recommends lowering a timeout unless observed p99 and timeout margin prove it safe.
- `F10-REQ-025`: optimization proposals are not auto-applied; changes require a controlled A/B rerun on a comparable environment.

## Recommendation examples

- 94% of `tap` time is `wait_exists`: optimize app-state preparation or locator, not tap implementation.
- One selector resolves 37 times in a step: suggest caching only after proving the XCUI snapshot will not become stale.
- Screenshot serialization consumes 18% of the suite critical path: reduce success-artifact frequency or size.
- Independent API setup calls are sequential: suggest bounded parallelism.
- An assertion consistently passes in 120 ms with a 15-second timeout: timeout is not causing current slowness and changing it is pointless.

## Acceptance criteria

- A fake monotonic clock produces deterministic span/golden tests.
- A timed-out action separates wait and interaction duration.
- Parallel nested spans produce correct wall duration and critical path without double counting.
- The same regression fixture is detected with sufficient samples and ignored below noise/sample thresholds.
- One test's performance telemetry contains no spans from another parallel execution.
- Basic instrumentation overhead meets the approved budget on a representative suite.
- AI recommendations reference existing span IDs and reproducible metrics.

## Open questions

- `F10-OPEN-001`: exact default overhead budget.
- `F10-DEC-002`: the versioned default requires 3 execution samples, 25% relative growth, and 250 ms absolute growth.
- `F10-DEC-003`: CI or the user supplies the versioned JSON baseline; XCEasy does not own indefinite history storage.
- `F10-OPEN-004`: richer framework-side trend presentation; the runner already emits a machine-readable run artifact.
