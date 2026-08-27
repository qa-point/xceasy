# F10 — Performance telemetry и оптимизация

Статус 0.1.1: per-test сбор и budgets реализованы; cross-run comparison реализован независимым runner, а project thresholds задаёт пользователь/CI.

## Цель

Измерять стоимость операций XCEasy в каждом execution, находить медленные и деградировавшие участки тестов и выдавать пользователю доказательные рекомендации по оптимизации без смешения скорости приложения, test code и инфраструктуры.

## Область измерений

Обязательной instrumentation подлежат:

- UI query/resolution и condition wait;
- UI actions: tap, type, clear, swipe, press и coordinate actions;
- general/UI assertions и polling;
- user steps и Setup/Teardown fixtures;
- app launch/terminate/reopen;
- API request и response phases;
- screenshots, UI snapshots, serialization и artifact writes;
- per-test serialization и artifact writes; внешний runner отдельно измеряет собственные aggregation и validation;
- self-healing analysis и verification rerun, если включены.

## Реализованный slice

Execution-scoped `XCEasyConfig.performance` реализует `off`, `basic` и `detailed`; default — `basic`. UI queries, operations, assertions и user/fixture steps фиксируют monotonic durations и performance evidence schema 1.0.0. Каждый test прикладывает `performance-summary.json` с count, min, max, mean, median, p90, p95, p99, budget findings и dominant-phase suggestions. Cross-run baseline, comparison policy и run-level summary принадлежат независимому `xceasy-runner`; XCEasy создаёт версионированный per-test input. Critical-path reconstruction и измерение instrumentation overhead остаются дальнейшей работой.

## Модель времени

- Wall-clock timestamp нужен для общей timeline и Allure `start`/`stop`.
- Duration вычисляется только monotonic clock, устойчивым к изменению системного времени.
- Каждая операция является span с `span_id`, `parent_span_id`, `operation_key`, start/stop, outcome и phase durations.
- `operation_key` стабилен между запусками и не содержит dynamic selector values, secret data или UUID.

Пример разложения UI action:

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

## Требования к сбору

- `F10-REQ-001`: каждая instrumented операция записывает wall start/stop и monotonic `duration_ns`/`duration_ms`.
- `F10-REQ-002`: duration разбивается на meaningful phases; сумма фаз не должна превышать total за пределами documented overlap.
- `F10-REQ-003`: ожидание отделено от active framework work и application/network latency.
- `F10-REQ-004`: span связан с run, execution, test, step, worker, device, source location и canonical target ID.
- `F10-REQ-005`: success, failure, timeout, cancellation и interruption всегда завершают span terminal outcome.
- `F10-REQ-006`: async/parallel child spans не суммируются как sequential time; сохраняется critical path.
- `F10-REQ-007`: instrumentation overhead измеряется отдельно и не включается в operation duration.
- `F10-REQ-008`: dynamic/sensitive values не используются как metric dimensions; redaction выполняется до sink.
- `F10-REQ-009`: пользователь может включать уровни `off`, `basic`, `detailed`; default — `basic` с минимальным overhead.
- `F10-REQ-010`: sampling допускается для high-frequency successful operations, но failures/timeouts всегда записываются полностью.

## Агрегация и динамика

- `F10-REQ-011`: per-run `performance-summary.json` содержит count, success/failure, min, max, mean, median, p90, p95 и p99 по operation key.
- `F10-REQ-012`: статистика сегментируется по совместимой environment: device class, OS major, app build, Xcode/toolchain и execution mode.
- `F10-REQ-013`: shard/worker IDs не дробят baseline, если environment эквивалентна; simulator и physical device не сравниваются напрямую.
- `F10-REQ-014`: baseline имеет ID/version, sample count, time window и environment matcher.
- `F10-REQ-015`: regression определяется одновременно relative change, absolute change и minimum sample threshold, чтобы исключить шум.
- `F10-REQ-016`: cold start, warm-up, retry и healed execution маркируются и сравниваются только с соответствующим классом.
- `F10-REQ-017`: run summary показывает top slow operations, top regressions, timeout-near operations и critical-path contribution.
- `F10-REQ-018`: Allure steps сохраняют duration для визуального анализа; подробная агрегированная статистика прикладывается отдельным JSON/Markdown artifact.
- `F10-REQ-019`: XCEasy не хранит историю бессрочно сам; внешний CI/report storage передаёт предыдущий baseline либо history input.

## Budgets и рекомендации

- `F10-REQ-020`: config поддерживает global, operation-type и exact operation budgets с warning/fail/observe policy.
- `F10-REQ-021`: превышение budget по умолчанию не меняет test result; оно создаёт performance finding. Fail policy включается явно.
- `F10-REQ-022`: рекомендация содержит operation/source, evidence span IDs, baseline/current metrics, dominant phase, confidence и suggested action.
- `F10-REQ-023`: рекомендации различают вероятные причины: slow app state, unstable selector, excessive timeout, repeated query, serializable parallel work, slow network, heavy artifact или framework overhead.
- `F10-REQ-024`: ИИ не предлагает уменьшить timeout, если observed p99/timeout margin не подтверждает безопасность.
- `F10-REQ-025`: optimization proposal не применяется автоматически; после изменения выполняется controlled A/B rerun на сопоставимой environment.

## Примеры рекомендаций

- 94% времени `tap` ушло в `wait_exists`: оптимизировать подготовку app state или locator, а не реализацию tap.
- Один selector разрешается 37 раз в одном step: предложить caching только после проверки, что XCUI snapshot не устаревает.
- Screenshot serialization занимает 18% suite critical path: уменьшить частоту/размер success artifacts.
- API setup выполняется последовательно, хотя запросы независимы: предложить bounded parallelism.
- Assertion стабильно проходит за 120 мс при timeout 15 с: timeout не является текущей причиной медленного прогона и менять его бессмысленно.

## Acceptance criteria

- Fake monotonic clock даёт детерминированные span/golden tests.
- Timeout action показывает отдельно wait и interaction duration.
- Parallel nested spans дают корректный wall duration и critical path без двойного счёта.
- Одинаковая regression fixture детектируется при достаточной выборке и не детектируется ниже noise/sample thresholds.
- Performance telemetry одного теста не содержит spans другого parallel execution.
- Basic instrumentation overhead соответствует утверждённому budget на representative suite.
- AI recommendation ссылается на существующие span IDs и воспроизводимые metrics.

## Открытые вопросы

- `F10-OPEN-001`: точный default overhead budget.
- `F10-DEC-002`: versioned default требует 3 execution samples, 25% relative роста и 250 ms absolute роста.
- `F10-DEC-003`: CI или пользователь передаёт versioned JSON baseline; XCEasy не хранит историю бессрочно.
- `F10-OPEN-004`: более богатый framework-side trend presentation; runner уже создаёт machine-readable run artifact.
