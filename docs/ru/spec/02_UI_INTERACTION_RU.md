# F02 — UI elements и interaction

Статус 0.1.0: реализовано и проверено; Objective-C forwarding остаётся внутренним technical-debt boundary.

## Цель

Предоставить fluent, типобезопасный и диагностируемый слой над XCUI queries/actions без сокрытия неоднозначности и состояния элемента.

## As-is

- `find`/`child` ищут по type, identifier, predicate, text и index.
- `XCEasyUIElement` lazy-resolves `XCUIElement` и использует Objective-C forwarding.
- Реализованы taps, press, text input/clear, swipes, reads и state checks.
- Все UI-actions используют execution-scoped `XCEasyActionPolicy`: `.hittable` ждёт safe semantic dispatch, а explicit `.displayed` ждёт display и использует coordinate dispatch с warning evidence. Каждый вызов может переопределить policy и timeout локально.
- По умолчанию действует strict ambiguity; index использует `element(boundBy:)`, а явно включённый permissive mode выбирает first match и пишет warning.
- `Device` выполняет coordinate actions, orientation, clipboard read и wait.
- На evidence levels `basic` и `detailed` каждый UI resolution строит immutable redacted root-to-child descriptor и создаёт query lifecycle evidence schema `1.0.0` с SHA-256 fingerprint, expected/initial/final state, bounded observation timeline, duration, attempts, candidate count, selected/failed segment, source/correlation, performance и явной candidate-collection policy.
- `basic` является failure-focused default: bounded candidate snapshots собираются для failed или ambiguous queries. `detailed` собирает их для каждого query; `off` отключает query events без изменения lookup semantics.
- Query events связываются с enclosing action/assertion. Strict ambiguity даёт failure `query.ambiguous_match`; permissive ambiguity фиксируется как `query.ambiguous_first_match`. При failed XCTest issue size-bounded redacted accessibility snapshot и screenshot попадают в diagnostic bundle соответствующего execution.
- Значения predicate/text selectors и candidate label/value заменяются typed placeholders с длиной. Stable identifiers остаются читаемыми после pattern redaction.

## Требования

- `F02-REQ-001`: selector представлен immutable моделью с type, strategy, value, parent и optional index.
- `F02-REQ-002`: при resolve фиксируются normalized selector, timeout, elapsed, candidate count и выбранный candidate.
- `F02-REQ-003`: strict mode завершает ambiguous selector typed failure; permissive mode явно логирует выбор first match.
- `F02-REQ-004`: при failed query сохраняется bounded UI snapshot/accessibility tree и screenshot reference.
- `F02-REQ-005`: action проверяет необходимые preconditions и пишет before/after state.
- `F02-REQ-006`: sensitive text input маскируется в каждом sink, но сохраняет length/type metadata.
- `F02-REQ-007`: ни один public interaction path не использует `fatalError` или force unwrap.
- `F02-REQ-008`: selector priority и stability warning доступны Page Object автору.
- `F02-REQ-009`: fixed sleep заменяется condition-based wait; явный time wait маркируется причиной.
- `F02-REQ-010`: каждая semantic operation (`tap`, assertion, чтение value и аналогичное использование) начинает resolution по текущему accessibility tree; элемент, найденный предыдущей operation, никогда не переиспользуется как актуальное состояние.
- `F02-REQ-011`: каждая попытка polling заново вычисляет полную locator chain по свежему accessibility snapshot, а не проверяет ранее resolved `XCUIElement` или snapshot.
- `F02-REQ-012`: реализация может кешировать immutable locator/query-plan metadata, но никогда не кеширует resolved elements, snapshots, existence, visibility, hittability, values или frames между semantic operations.
- `F02-REQ-013`: каждый built-in UI-action выполняет policy-specific condition wait и не dispatch-ит action после readiness timeout.
- `F02-REQ-014`: автоматический fallback с safe semantic action на coordinate dispatch запрещён.

Модель locator/observation и negative-state semantics определена в [F11 — Состояния UI-элемента и negative assertions](11_ELEMENT_STATE_AND_NEGATIVE_ASSERTIONS_RU.md).

Правила immutable parent chains и переиспользуемых component POM определены в [F12](12_REUSABLE_COMPONENT_POM_RU.md).

Полная матрица action readiness, dispatch и diagnostics определена в [F15](15_UI_ACTION_POLICY_RU.md).

## Acceptance criteria

- Тесты покрывают все query strategies, parent scope, zero/one/many matches и out-of-range index.
- Для failed action diagnostic bundle показывает selector, precondition, observed state и duration.
- Canary password отсутствует в console, JSONL, Allure и attachments.
- Fluent API сохраняет source compatibility либо имеет deprecation migration.
- Locator, сохранённый до изменения UI, при последующем использовании наблюдает дерево после изменения.
- Polling assertion обнаруживает появление, исчезновение или замену элемента во время timeout без пересоздания public locator.

## Открытые вопросы

- `F02-OPEN-001`: сохранить Objective-C proxy или перейти к explicit wrapped operations.
- `F02-DEC-002`: accessibility snapshot хранится как size-bounded redacted attachment; limit задаётся `diagnosticSnapshotByteLimit`, integrity и truncation фиксируются manifest-ом.
