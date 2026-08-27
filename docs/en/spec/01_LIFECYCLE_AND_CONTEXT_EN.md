# F01 — Lifecycle and test context

0.1.1 status: implemented and verified.

## Goal

Provide a predictable lifecycle for every XCTest, isolated context, and correct artifact finalization for success, assertion failure, throw, setup/teardown failure, and interruption.

## Implemented baseline

- `XCEasyTestCase` performs configuration, app creation/launch, hooks, and teardown within Allure steps.
- `XCEasyApp` manages `XCUIApplication`; an empty bundle ID means the UI-test target app.
- `XCEasyTestObserver` is registered by an Objective-C bootstrap and handles bundle/suite/case/issues.
- `XCEasyTestContext.shared` owns one lock-protected reference state per execution. A task-local carrier propagates that same state through structured Swift concurrency while thread-local ownership remains the synchronous fallback.
- Lifecycle transitions are typed and diagnosed; missing app/context is a typed framework failure instead of a force unwrap. Plain XCTest and XCEasyTestCase executions produce exactly one terminal event.
- Atomic collection updates, exactly-one terminal claims, synchronous logger closure, 100-child-task propagation, Thread Sanitizer, and multi-device stress contracts cover in-process isolation. Process death before XCTest `didFinish` is reconciled by the host as an explicitly synthetic interrupted result.

## Requirements

- `F01-REQ-001`: lifecycle states are `created → setting_up → running → tearing_down → finished`; invalid transitions are diagnosed.
- `F01-REQ-002`: each execution receives `run_id`, stable `test_id`, unique `execution_id`, `attempt`, and `shard_id`.
- `F01-REQ-003`: mutable test-scoped state never crosses parallel tests.
- `F01-REQ-004`: Setup/Teardown are fixtures while user steps remain the test body.
- `F01-REQ-005`: every started lifecycle scope is finished or marked interrupted with a reason.
- `F01-REQ-006`: missing app/context yields a typed framework failure, never a force unwrap/crash.
- `F01-REQ-007`: hooks execute exactly once in documented order.
- `F01-REQ-008`: telemetry/reporting failure never masks the original XCTest status.
- `F01-SHOULD-001`: clock, ID generator, app factory, and artifact store are injectable for unit tests.

## Acceptance criteria

- Contract tests cover success, throw, assertion, setup, teardown, timeout/interruption, and multiple issues.
- A parallel test with at least 20 executions shows no mixed IDs, steps, screenshots, or logs.
- Every execution has exactly one terminal event/result.
- An integration test proves observer bootstrap in a real UI-test bundle.

## Decisions

- `F01-DEC-001`: execution state is a lock-protected reference propagated by task-local scope; this preserves synchronous APIs while allowing structured child tasks to share one atomic lifecycle.
- `F01-DEC-002`: abrupt runner loss is a host concern. Crash reconciliation preserves completed real results and creates clearly labelled synthetic `broken` evidence for executions that cannot reach `didFinish`.
