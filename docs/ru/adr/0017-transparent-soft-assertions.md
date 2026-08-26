# ADR-0017 — Прозрачные execution-scoped soft assertions

## Статус

Принято 10 августа 2026 года. Решение заменяет неопубликованный public collector API из первоначальной реализации F03.

## Контекст

Прежний синтаксис `softly { check in check.expect... }` создавал второй набор assertions и не поддерживал проверки UI-элементов и component collections. Автору POM приходилось переписывать обычные проверки в collector calls, теряя естественный component-oriented вид теста и часть operation-specific evidence.

Soft behavior должен явно включаться на границе группы, но каждая проверка внутри обязана сохранять обычный API, locator diagnostics, timing, локализацию и Allure nesting. Параллельные тесты и async suspension не должны смешивать ошибки. Actions и framework errors нельзя ослаблять.

## Решение

- `softly("Название") { ... }` устанавливает bounded storage в текущем `XCEasyExecutionState` и принимает closure без параметров.
- Ошибки value, UI-element, component и component-collection assertions проходят через единый internal router. При активном soft scope router записывает redacted mismatch вместо немедленного XCTest issue.
- Монотонная execution-scoped версия failure помечает причинный assertion step и всех родителей как failed, не бросая исключение и не останавливая блок.
- При закрытии scope создаётся один aggregate XCTest issue максимум с 50 подробными mismatches; остальные продолжают учитываться в count.
- Sync и async overloads используют один task-propagated execution state.
- Actions, thrown step errors, configuration failures, performance-policy failures и другие framework failures обходят assertion router и остаются hard.
- Неопубликованные public API `XCEasySoftAssertions`, `expect`, `expectEqual` и `expectNotNil` удаляются без deprecated aliases.

## Последствия

Тесты и POM используют один набор assertions в hard- и soft-контексте. Per-operation diagnostics остаются доступными человеку и ИИ, а XCTest получает одно компактное падение группы. Внутри scope должны находиться только независимые проверки; prerequisite assertion следует выполнять перед `softly`.
