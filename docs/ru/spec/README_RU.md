# Спецификация XCEasy

Статус: действующий versioned contract 0.1.0. Сверено с исходным кодом: 13 августа 2026 года.

Спецификация разделена по фичам. Статус каждой фичи явно отделяет production behavior от частично реализованных или запланированных требований.

## Карта фич

| ID | Фича | Статус 0.1.0 | Компоненты |
|---|---|---|---|
| F01 | [Lifecycle и test context](01_LIFECYCLE_AND_CONTEXT_RU.md) | Реализовано и проверено | `XCEasyTestCase`, app, observer, context |
| F02 | [UI elements и interaction](02_UI_INTERACTION_RU.md) | Реализовано и проверено | lazy lookup, actions, Device |
| F03 | [Assertions и steps](03_ASSERTIONS_AND_STEPS_RU.md) | Реализовано и проверено | value/UI asserts, GWT, soft assertions |
| F04 | [Reporting и AI diagnostics](04_REPORTING_AND_AI_DIAGNOSTICS_RU.md) | Реализовано; retention/schema window — policy boundary | Allure, JSONL, manifests |
| F05 | [Networking и runtime configuration](05_NETWORKING_AND_RUNTIME_CONFIGURATION_RU.md) | Частично: runtime API готов, полная typed validation/cancellation taxonomy открыта | API, config, launch, deeplink |
| F06 | [Delivery и quality](06_DELIVERY_AND_QUALITY_RU.md) | Release contract реализован; публикация требует maintainer authority | SPM, Tuist, CI, release |
| F07 | [Allure lifecycle и совместимость](07_ALLURE_LIFECYCLE_RU.md) | Реализовано и проверено | identity, fixtures, attachments |
| F09 | [Self-healing и генерация тестов](09_SELF_HEALING_AND_TEST_GENERATION_RU.md) | Частично: controlled healing готов, full test-generation acceptance не закрыт | evidence, provider adapter, safeguards |
| F10 | [Performance telemetry и оптимизация](10_PERFORMANCE_TELEMETRY_RU.md) | Реализовано; project thresholds задаёт пользователь/CI | timings, baselines, budgets |
| F11 | [Состояния UI-элемента и negative assertions](11_ELEMENT_STATE_AND_NEGATIVE_ASSERTIONS_RU.md) | Реализовано и проверено | absent, hidden, displayed, transitions |
| F12 | [Переиспользуемые UI-компоненты и POM](12_REUSABLE_COMPONENT_POM_RU.md) | Реализовано и проверено | components, collections, nested steps |
| F13 | [Test coverage и quality gates](13_TEST_COVERAGE_RU.md) | Реализовано; diff coverage отложен | unit/UI coverage, CI policy |
| F14 | [Параметризованные test executions](14_PARAMETERIZED_TEST_EXECUTION_RU.md) | Реализовано и проверено | datasets, independent cases |
| F15 | [Политика готовности UI-действий](15_UI_ACTION_POLICY_RU.md) | Реализовано и проверено | action policy, waits, dispatch |
| F16 | [Allure metadata-аннотации](16_ALLURE_METADATA_ANNOTATIONS_RU.md) | Реализовано и проверено | macros, manifest, runtime parity |
| F17 | [Пользовательские маркеры](17_CUSTOM_MARKERS_RU.md) | Реализовано и проверено | markers, Allure labels, manifest |

## Правила требований

- `AS-IS`/`Реализованный baseline` — подтверждён текущим source/tests; уровень runtime-проверки указывается в статусе и acceptance evidence.
- `REQ` — обязательное целевое требование; `SHOULD` — рекомендуемое; `OPEN` — нерешённый вопрос.
- ID устойчивы и используются в issue, тестах, PR и telemetry fixtures.
- Изменение требования выполняется синхронно в RU/EN и с migration impact.
- Конституция имеет приоритет над спецификацией.

## Общий Definition of Done

Фича готова, когда выполнены её acceptance criteria, добавлены unit/integration/contract tests, public API и RU/EN docs синхронизированы, privacy проверена, а CI подтверждает поддерживаемую toolchain matrix. Если критерий намеренно отложен, он остаётся открытым и не считается реализованным.
