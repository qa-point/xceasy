# ADR-0016 — Имена `element` и `collection` в компонентах

## Статус

Принято 10 августа 2026 года. Решение заменяет public naming portions ADR-0014 и ADR-0015 для неопубликованного beta API.

## Контекст

`XCEasyComponent.container` можно было спутать с root accessibility tree или с Allure result container. `XCEasyIndexedComponent.collectionContainer` было длинным, но всё равно недостаточно ясно показывало разницу между locator всех instances и одним выбранным instance.

API нужны два коротких имени с разным смыслом: один locator для всех повторяющихся instances и один locator для конкретного компонента.

## Решение

- `XCEasyComponent` требует `element: XCEasyUIElement`.
- `XCEasyIndexedComponent` дополнительно требует static `collection: XCEasyUIElement`.
- Positioned POM получает `element` через `Self.collection.element(at: position, ...)`.
- `container` и `collectionContainer` удаляются без deprecated aliases, потому что этот public surface ещё не использовался в production.
- Canonical telemetry сохраняет существующее универсальное поле `selector` и operation codes. Стандартные Allure artifacts `*-container.json` к component API не относятся и не меняются.

## Последствия

Call sites явно читаются как «все подходящие instances» (`collection`) и «этот компонент» (`element`). Component assertions и component-owned steps делегируют в `element`, а count/visibility operations коллекции обращаются к `collection`. Предыдущее naming существовало только в неопубликованном beta surface, поэтому отдельный consumer migration contract не сохраняется.
