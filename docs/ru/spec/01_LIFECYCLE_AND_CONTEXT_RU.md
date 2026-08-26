# F01 — Lifecycle и test context

Статус 0.1.0: реализовано и проверено.

## Цель

Обеспечить предсказуемый lifecycle каждого XCTest, изолированный context и корректное завершение артефактов при success, assertion failure, throw, setup/teardown failure и interruption.

## Реализованный baseline

- `XCEasyTestCase` выполняет configuration, создание app, launch, hooks и teardown внутри Allure-шагов.
- `XCEasyApp` управляет `XCUIApplication`; пустой bundle ID означает app UI-test target.
- `XCEasyTestObserver` регистрируется Objective-C bootstrap-ом и обрабатывает bundle/suite/case/issues.
- `XCEasyTestContext.shared` владеет одним lock-protected reference state на execution. Task-local carrier переносит тот же state через structured Swift concurrency, а thread-local ownership остаётся synchronous fallback.
- Lifecycle transitions типизированы и диагностируются; отсутствие app/context даёт typed framework failure без force unwrap. Plain XCTest и XCEasyTestCase создают ровно один terminal event.
- Atomic updates коллекций, exactly-one terminal claim, synchronous logger closure, propagation через 100 child tasks, Thread Sanitizer и multi-device stress contracts покрывают in-process isolation. Process death до XCTest `didFinish` reconciled host-инструментом как явно synthetic interrupted result.

## Требования

- `F01-REQ-001`: lifecycle имеет состояния `created → setting_up → running → tearing_down → finished` и запрещённые переходы диагностируются.
- `F01-REQ-002`: каждый execution получает `run_id`, stable `test_id`, unique `execution_id`, `attempt` и `shard_id`.
- `F01-REQ-003`: test-scoped mutable state не пересекается между параллельными тестами.
- `F01-REQ-004`: Setup/Teardown сохраняются как fixtures, а пользовательские steps — как test body.
- `F01-REQ-005`: каждый started lifecycle scope завершается либо помечается interrupted с причиной.
- `F01-REQ-006`: отсутствие app/context возвращает typed framework failure без force unwrap/crash.
- `F01-REQ-007`: hooks вызываются ровно один раз в документированном порядке.
- `F01-REQ-008`: telemetry/reporting failure не скрывает исходный XCTest status.
- `F01-SHOULD-001`: clock, ID generator, app factory и artifact store инъецируются для unit tests.

## Acceptance criteria

- Contract tests покрывают success, throw, assertion, setup, teardown, timeout/interruption и multiple issues.
- Parallel test минимум из 20 executions не смешивает IDs, steps, screenshots и logs.
- Для каждого execution существует ровно один terminal event/result.
- Observer bootstrap доказан интеграционным тестом в реальном UI-test bundle.

## Решения

- `F01-DEC-001`: execution state является lock-protected reference и переносится task-local scope; synchronous API сохраняется, а structured child tasks используют один atomic lifecycle.
- `F01-DEC-002`: abrupt runner loss обрабатывается host-слоем. Crash reconciliation сохраняет завершённые real results и создаёт явно помеченный synthetic `broken` evidence для executions без `didFinish`.
