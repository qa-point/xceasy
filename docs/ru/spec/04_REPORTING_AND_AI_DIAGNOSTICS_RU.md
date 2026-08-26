# F04 — Reporting и AI diagnostics

Статус 0.1.0: runtime и host artifacts реализованы; retention и schema-support window являются внешней policy boundary.

## Цель

Создавать безопасный self-contained diagnostic bundle, одинаково полезный человеку, Allure и ИИ, при сохранении первичных фактов и versioned contracts.

## Реализованный baseline

- Per-test human-readable log проходит redaction до console/file sinks и сохраняется без ANSI control sequences.
- Versioned per-test JSONL stream прикладывается к Allure. Schema `1.0.0` добавляет execution/process/thread correlation, source, обязательную privacy metadata, attachment links, performance evidence и bounded transition observations.
- Каждый test создаёт per-test manifest, diagnostic summary, reproduction note, immutable log snapshot, performance summary и owned artifacts. Registry хранит ID, basename, MIME, bytes, SHA-256, producer event, truncation и privacy.
- Реализованы execution-scoped levels `off`/`basic`/`detailed`. Default `basic` сохраняет canonical query facts, но собирает дорогие candidate snapshots только при failures и ambiguous matches.
- Observer создаёт Allure result/container, executor, environment и categories JSON.
- На XCTest issue screenshot сохраняется и прикладывается к test/failed step, если foreground window приложения уже существует. При launch/context failure screenshot пропускается без регистрации нового XCTest issue.
- Stable SHA-256 test ID отделён от execution UUID; multi-device launch передаёт run/device/shard/attempt correlation в events и Allure labels.
- При использовании независимого `xceasy-runner` он потребляет per-test artifacts и владеет run-level diagnostic summary, worker classifications и integrity manifest.
- API request logs содержат URL/method и размеры payload вместо raw headers/body; для URL/payload всё ещё нужна более широкая redaction matrix.

## Требования

- `F04-REQ-001`: canonical append-only `events.jsonl` соответствует versioned JSON Schema.
- `F04-REQ-002`: envelope содержит schema version, timestamp, monotonic time, level, event, IDs, source, duration, data, attachments и privacy.
- `F04-REQ-003`: bundle содержит `manifest.json`, `events.jsonl`, `summary.json`, artifact subdirectories и reproduction summary.
- `F04-REQ-004`: artifact registry хранит ID, relative path, MIME, size, SHA-256, producer event и truncation.
- `F04-REQ-005`: redaction применяется до console/file/Allure/attachment sinks и проверяется canary tests.
- `F04-REQ-006`: failure taxonomy различает product, test, infrastructure, framework и unknown; fingerprint строится из стабильных полей.
- `F04-REQ-007`: Allure является adapter canonical model; отсутствие Allure не отключает diagnostics.
- `F04-REQ-008`: telemetry errors видимы, но не заменяют исходный test outcome.
- `F04-REQ-009`: retention, payload limits и sensitive attachments configurable.
- `F04-REQ-010`: CLI/validator проверяет schema, links, hashes и secret scan.
- `F04-REQ-011`: console log, per-test text log и Allure используют одно canonical operation event и отображают его через настроенный localization catalog.
- `F04-REQ-012`: человекочитаемые log lines содержат timestamp, level, локализованный action text, outcome и duration, сохраняя execution/test/step correlation fields в стабильной machine-readable форме.
- `F04-REQ-013`: sink configuration может менять verbosity или скрывать presentation entries успешных операций, но canonical events, необходимые для AI diagnosis, восстановления lifecycle и performance analysis, остаются доступны в per-test bundle.

Подробный контракт duration spans, агрегатов и regression findings определён в [F10 — Performance telemetry](10_PERFORMANCE_TELEMETRY_RU.md).

## Acceptance criteria

- Каждый failed test создаёт валидный bundle, читаемый без console output.
- Bundle однозначно показывает first causal failure, expected/actual, source и evidence IDs.
- Повтор одного дефекта даёт одинаковый fingerprint после нормализации динамических данных.
- Canary secrets отсутствуют побайтово во всех artifacts.
- Golden fixtures обнаруживают incompatible schema/artifact changes.
- Успешный built-in action и failed assertion имеют согласованное человекочитаемое представление в text logs и Allure и при этом восстанавливаются из canonical events без parsing локализованного текста.
- Изменение indexed artifact или `.xcresult` bundle приводит к ошибке manifest validation, а diagnostic summary предоставляет стабильные reason codes для conclusion и actions.

## Открытые вопросы

- `F04-OPEN-001`: определить compatibility support window при публикации diagnostic event schema новее первоначального контракта `1.0.0`.
- `F04-DEC-002`: AI handoff по умолчанию локальный и evidence-only; внешний transport требует явного разрешения.
- `F04-OPEN-003`: performance/storage budgets.
