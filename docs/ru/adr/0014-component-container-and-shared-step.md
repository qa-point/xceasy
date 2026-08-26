# ADR 0014: Container компонента и общий lifecycle шагов

## Статус

Принято 10 августа 2026 года. Заменяет части ADR 0008, ADR 0011, ADR 0012 и ADR 0013, относящиеся к component naming и step API. Action-owned readiness из ADR 0013 остаётся без изменений.

## Контекст

Beta component contract использовал `root`, который можно было перепутать с корнем accessibility tree. Он также предоставлял `componentStep`, хотя функция имела ту же Allure semantics, что обычный `step`. Пользователю приходилось помнить два имени для одного lifecycle. Имени component type было недостаточно, когда на одном экране находилось несколько instances одного POM.

Indexing нужен не каждому component. Неявный index `0` в base protocol скрывал бы duplicate identifiers у unique components, тогда как повторяющимся карточкам и строкам полезен короткий default.

## Решение

- `XCEasyComponent` требует `container: XCEasyUIElement`; beta requirement `root` удаляется без deprecated alias.
- Component assertions и waits делегируют только в `container`. Children остаются явными и lazy.
- `componentName` по умолчанию берётся из concrete type. POM может принять optional initializer argument и сохранить instance-specific name.
- `componentStep` удаляется. `XCEasyComponent` предоставляет sync и async instance-overloads с именем `step` и теми же default source locations, что global function.
- Global и component steps делегируют одному internal executor и одному execution-scoped stack. Allure nesting, thrown-error finalization, deferred failures и task-local propagation идентичны.
- Component events сохраняют schema `1.0.0` и используют существующие поля: `operationCode = component.step`, `target = componentName`, `selector = container.locatorDescriptor`. Allure title имеет вид `<componentName>: <operation>`.
- `XCEasyIndexedComponent` является отдельным protocol с requirement `init(index:componentName:)`. Extensions добавляют `init()`, `init(index:)` и `init(componentName:)`; отсутствие index означает zero.
- Поведение `XCEasyComponentCollection` этим решением не меняется.

## Последствия

POM использует одно понятное имя контейнера и одно написание шага. AI tooling получает stable structured component identity, а не разбирает локализованный title. Несколько одинаковых components можно различить при initialization без изменения locator semantics.

Изменение source-breaking для unpublished beta API. Consumer переименовывает `root` в `container`, `componentStep` в `step`, а повторяющиеся POM при необходимости переводит на `XCEasyIndexedComponent`. Unit tests покрывают sync, async, nested component и ordinary steps, assertion nesting, structured telemetry, index defaults и восстановление stack после error. UIKit/SwiftUI sample tests покрывают реальные nested actions и assertions.
