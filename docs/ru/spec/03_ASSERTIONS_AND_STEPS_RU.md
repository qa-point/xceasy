# F03 — Assertions и steps

Статус 0.1.0: реализовано и проверено.

## Цель

Дать единый контракт проверок и бизнес-шагов с точными expected/actual, корректной вложенностью и воспроизводимыми failure semantics.

## As-is

- Public assertions покрывают Boolean, equality/inequality, строгие и нестрогие comparison, String/Collection contains, optional, empty и throwing closures.
- UI assertions отдельно покрывают presence в tree, display на экране, hidden, selection, enabled, hittable, label, value и transitions.
- Sync и async `given/when/then/and` оборачивают generic sync/async `step<T>`, сохраняют return value и thrown error и переносят execution state через suspension.
- Deferred failures и observer пытаются сохранить дерево при прерывании XCTest.
- Служебные step/assert messages локализуются RU/EN.
- `softly` прозрачно направляет mismatches обычных value, UI, component и collection assertions в execution-scoped bounded storage. Отдельные assertion steps остаются failed, следующие проверки продолжаются, а scope создаёт один redacted aggregate XCTest issue.

## Требования

- `F03-REQ-001`: assertion model хранит matcher, expected, actual, target, timeout и elapsed отдельно.
- `F03-REQ-002`: hard/soft behavior задаётся явно и одинаково для general/UI asserts.
- `F03-REQ-003`: каждый step получает ID, parent ID, source location, start/stop и terminal status.
- `F03-REQ-004`: throw/issue внутри nested step помечает причинный deepest step и предков без дублирования.
- `F03-REQ-005`: локализация меняет rendered text, но не canonical event/error codes.
- `F03-REQ-006`: custom description не уничтожает canonical selector/operation evidence.
- `F03-REQ-007`: invalid matcher input возвращает typed failure.
- `F03-REQ-008`: каждое встроенное действие и assertion фреймворка автоматически создаёт step без необходимости оборачивать его пользователем в `step {}`.
- `F03-REQ-009`: каталог встроенных operations включает как минимум поиск/observation элемента, варианты tap и press, ввод и очистку текста, swipe/scroll, чтение value/state, waits, assertions, launch/termination приложения, orientation, clipboard, deep-link и API operations, поддерживаемые public framework.
- `F03-REQ-010`: одно canonical operation event является источником и Allure step, и записи обычного framework log, поэтому их status, duration, target и failure reason не могут расходиться.
- `F03-REQ-011`: встроенные step titles и log messages формируются из versioned localization templates с named parameters; public operation code не содержит hard-coded пользовательских фраз.
- `F03-REQ-012`: default templates создают короткие человекочитаемые предложения с semantic operation, безопасным описанием target, outcome и duration, когда он известен; raw selector diagnostics остаются structured details и не заменяют title.
- `F03-REQ-013`: пользовательские business steps могут содержать автоматические built-in steps; nesting и verbosity policy настраиваются без отключения canonical events или timing data.
- `F03-REQ-014`: success, failure, timeout, skipped и retry используют единый localization catalog, а canonical operation/status/reason codes не зависят от языка.
- `F03-REQ-015`: `softly` использует существующий синтаксис assertions без параметра-коллектора и никогда не превращает actions, configuration errors или framework failures в soft outcomes.
- `F03-REQ-016`: каждый assertion mismatch внутри `softly` помечает собственный Allure step и всех родителей как failed, но блок продолжается и при закрытии scope создаёт ровно один aggregate XCTest issue.

## Примеры отображения по умолчанию

Для русской локали типовые titles выглядят как `Нажать «Закрыть»`, `Ввести текст в «Email»`, `Проверить, что «Промо-баннер» отсутствует в дереве` и `Проверить, что «Оформление заказа» отображается на экране`. Английский каталог отображает эквивалентные `Tap “Close”`, `Enter text into “Email”`, `Verify that “Promo banner” does not exist in the tree` и `Verify that “Checkout” is displayed on screen`.

Sensitive values никогда не подставляются в текст. Для target по порядку используются explicit semantic POM name, локализованный accessibility label, если он безопасен, либо bounded normalized locator description. Локализация влияет только на presentation; event по-прежнему содержит стабильные `operation_code`, `target_id`, `status_code`, `reason_code` и `duration_ms`.

Точные контракты `does not exist`, `not displayed`, `hidden`, `not hittable` и `disappears` определены в [F11](11_ELEMENT_STATE_AND_NEGATIVE_ASSERTIONS_RU.md).

## Acceptance criteria

- Unit matrix проверяет каждый matcher на pass/fail/optional/boundary cases.
- Golden tests проверяют дерево nested steps для success, throw и XCTest issue.
- Один failure не создаёт несколько логически одинаковых root failures.
- По structured events можно восстановить Given/When/Then дерево без text parsing.
- Каждая built-in operation из коробки появляется и в per-test framework log, и в принадлежащем тесту Allure result с одинаковыми status и duration.
- Golden tests покрывают каждый built-in operation template на RU и EN, missing parameters, pluralization при её использовании и deterministic fallback.
- Смена языка отчёта меняет rendered titles, но оставляет canonical structured events byte-equivalent, кроме presentation fields.

## Решения

- `F03-DEC-001`: async/throwing GWT и component steps используют один task-propagated execution context и сохраняют generic return values.
- `F03-DEC-002`: soft assertions включаются явно через `softly` с closure без параметров; detailed failures по умолчанию ограничены 50, превышение учитывается в aggregate count, а старый public collector API удалён до production release.
