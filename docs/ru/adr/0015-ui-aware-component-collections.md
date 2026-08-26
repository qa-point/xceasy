# ADR-0015 — UI-aware коллекции компонентов

## Статус

Принято 10 августа 2026 года. Решение заменяет часть F12-DEC-003 и ADR-0011 про отсутствие UI-count для неопубликованного beta API коллекции.

## Контекст

Closure-based `XCEasyComponentCollection` умел только создавать optional component по integer index. Factory дублировался в каждом месте использования, актуальный `last` выразить было нельзя, а domain operations для count, emptiness и visibility отсутствовали. Тесты использовали optional subscript и `prefix`, которые не описывали ни ожидаемое UI state, ни полезное failure evidence.

Доступ к компонентам должен оставаться lazy, а явные waits и assertions должны наблюдать актуальное accessibility tree. Каждая operation должна быть понятной в локализованном Allure и structured AI diagnostics.

## Решение

- `XCEasyIndexedComponent` объявляет общий `collectionContainer` и `init(position:componentName:)`.
- `XCEasyComponentPosition` представляет `.first`, `.last` или `.index(Int)`. `last` остаётся symbolic до semantic use.
- `XCEasyComponentCollection<Component>()` заменяет closure initializer. Optional subscript, `component(at:)` и `prefix(_:)` beta APIs удаляются без deprecated aliases.
- `first`, `last`, `get(index:)` и `get(indices:)` создают locator intent без чтения UI.
- Exact/lower/upper count, empty/nonempty и all-displayed waits/assertions явно получают свежий current-tree snapshot на каждой polling attempt.
- Пустая collection не удовлетворяет all-displayed. Negative indices и empty-last selection завершаются диагностически без передачи invalid index в XCUI.
- Каждый public collection getter, wait и assertion создаёт локализованный default step и canonical events `ui.collection.started`/`ui.collection.finished`.
- Diagnostic schema 1.0.0 добавляет `selection` в selector segment и bounded `collectionEvidence`: expected/actual counts, attempts, duration, display failures, source, performance, context availability, максимум 50 observations или 100 requested indices.

## Последствия

Selection остаётся безопасным до появления UI, а чтение state видно из имени method. Сохранённый `last` следует за изменениями collection. Failure evidence подходит человеку и automated repair tools без разбора локализованного текста. Source break затрагивал только неопубликованный beta surface; отдельный consumer migration contract не требуется.

Real SwiftUI sample покрывает count, all-displayed, first, last и indexed access. Deterministic unit tests покрывают успешные и failing bounds, empty collection, evidence, steps и symbolic locator descriptors.
