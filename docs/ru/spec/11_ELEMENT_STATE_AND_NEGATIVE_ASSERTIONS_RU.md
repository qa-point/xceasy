# F11 — Состояния UI-элемента и negative assertions

Статус 0.1.0: реализовано и проверено на UIKit/SwiftUI fixtures.

## Цель

Поиск и проверки должны корректно работать, когда элемент отсутствует в accessibility tree. Ожидаемое отсутствие не является ошибкой поиска. Framework обязан различать отсутствие, невидимость, недоступность для взаимодействия и переход между состояниями.

## Мотивационный сценарий

На экране показан баннер с кнопкой закрытия. После tap приложение может:

1. удалить баннер из accessibility tree;
2. оставить его в tree, но скрыть;
3. оставить видимым, но сделать non-hittable;
4. начать animation и убрать позднее;
5. не убрать из-за product defect.

Assertions должны показать, какой именно результат наблюдался, и не падать только потому, что ожидаемо отсутствующий элемент нельзя найти.

## Реализованный baseline

- `find(...)` и `child(...)` создают lazy immutable locator intent; negative assertions наблюдают absence напрямую без предварительного positive wait.
- Реализованы observations `absent`, `hidden`, `visible`, `hittable`, `enabled`, `selected` и `assertDisappears(after:)` с fresh root-to-child resolution на каждом poll.
- Query schema `1.0.0` фиксирует expected/initial/final state, elapsed, attempts, matching count, failed segment, ancestor state, ограниченный state timeline, canonical reasons, source/correlation data и candidate-collection policy. Already-absent root и child под absent ancestor являются разными успешными результатами.
- Существующий selected element имеет приоритет над временно устаревшим `query.count == 0`, что предотвращает ложный `ancestor_absent`.
- Ambiguity по умолчанию обрабатывается строго (`query.ambiguous_match`); явно включённый permissive mode выбирает первый match и пишет bounded evidence. Реализованы `assertBecomesHidden(timeout:after:)`, transition timelines, захват screenshot/debug tree при failure и привязка per-test artifacts. Visibility откалибрована pure geometry matrix для UIKit, SwiftUI и WebView descendants. Измерение snapshot overhead остаётся performance-задачей, а не gap в state semantics.

## Термины и состояния

- Locator — immutable описание query; его создание не обращается к UI и не может завершить тест ошибкой.
- Observation — timestamped результат выполнения locator и чтения state.
- `absent` — element не существует в текущем accessibility snapshot (`exists == false`).
- `present` — `exists == true`, независимо от видимости или hittability.
- `visible` — element present, имеет finite non-empty frame и при default policy `.onScreen` пересекает текущий application viewport. XCUI не гарантирует точное распознавание полного occlusion другим view.
- `hidden` — element present, но не соответствует принятому visibility predicate.
- `hittable` — XCUI `isHittable == true`; это interactability, а не синоним visibility.
- `enabled` — element существует и XCUI сообщает `isEnabled == true`.
- `selected` — element существует и XCUI сообщает `isSelected == true`.
- `disappeared` — подтверждённый во время одной transition assertion переход `present → absent`.

## Архитектурный контракт

- `F11-REQ-001`: `find(...)` возвращает locator/proxy без implicit wait и без log уровня warning/error.
- `F11-REQ-002`: query construction отделена от observation; observation принимает ожидаемый predicate и один deadline.
- `F11-REQ-003`: positive action/assertion может ожидать `present`; negative assertion никогда предварительно не ждёт `present`, если его контракт не требует transition.
- `F11-REQ-004`: все polling используют общий monotonic deadline; вложенные resolve/state checks не умножают timeout.
- `F11-REQ-005`: observation содержит locator, expected state, final state, reason code, elapsed, attempts, first/last snapshots и candidate count.
- `F11-REQ-006`: отсутствие элемента является значением `absent`, а не thrown/fatal search error.
- `F11-REQ-007`: invalid locator, unavailable app/context и XCUI query failure отличаются от корректного `absent`.
- `F11-REQ-008`: logs/Allure/JSONL используют canonical reason codes, а не выводят смысл из локализованной строки.
- `F11-REQ-025`: resolved element и его state живут только в пределах одной попытки observation; следующая попытка или semantic operation заново разрешает immutable locator по текущему tree.
- `F11-REQ-026`: transition assertions хранят значения state, timestamps и bounded evidence, но никогда не используют resolved element handle как источник последующих observations.
- `F11-REQ-027`: `waitForDisplayed(timeout:)`, `waitForHittable(timeout:)`, `waitForEnabled(timeout:)` и `waitForSelected(timeout:)` используют один monotonic deadline, возвращают `true` сразу после достижения состояния и `false` после timeout без XCTest failure.
- `F11-REQ-028`: результат non-asserting wait можно игнорировать, но timeout всё равно оставляет canonical query evidence; отсутствие application context безопасно возвращает `false`, а не создаёт фиктивный XCUI object или Objective-C exception.

## Public assertions

### Конечное состояние

- `F11-REQ-009`: `assertExists(timeout:)` проходит, когда observation достигает `present`.
- `F11-REQ-010`: `assertDoesNotExist(timeout:)` проходит, когда observation достигает `absent`, включая already absent на первой попытке.
- `F11-REQ-011`: `assertIsDisplayed(timeout:)` требует, чтобы элемент присутствовал и соответствовал внутреннему состоянию `visible` или `hittable`.
- `F11-REQ-012`: `assertIsNotDisplayed(timeout:)` проходит для `absent` или `hidden` и в результате явно указывает, какой вариант произошёл.
- `F11-REQ-013`: `assertIsHidden(timeout:)` требует `present + hidden`; `absent` является failure, потому что DOM/tree presence — часть контракта.
- `F11-REQ-014`: `assertIsHittable(timeout:)` требует `present + hittable`.
- `F11-REQ-015`: `assertIsNotHittable(timeout:)` допускает `absent` или `present + non-hittable` и явно записывает reason.

### Переход состояния

- `F11-REQ-016`: `assertDisappears(timeout:)` проходит только при наблюдении `present → absent` внутри assertion window.
- `F11-REQ-017`: если первая observation уже `absent`, `assertDisappears` возвращает failure `transition_initial_state_not_observed`, а не выдаёт отсутствие за доказанное исчезновение.
- `F11-REQ-018`: `assertBecomesHidden(timeout:)` требует `visible → hidden`; удаление из tree не удовлетворяет этому узкому контракту.
- `F11-REQ-019`: transition assertion хранит timeline наблюдаемых state changes и связывает её с triggering step/action, если он известен.

## Нейминг

Public API использует canonical names: `assertExists`, `assertDoesNotExist`, `assertIsDisplayed`, `assertIsNotDisplayed`, `assertIsHidden`, `assertDisappears`.

## Логи и performance telemetry

- `F11-REQ-020`: successful negative assertion логируется как success, а не warning «element not found».
- `F11-REQ-021`: result содержит `initial_state`, `final_state`, `matched_reason` и `duration_ms`.
- `F11-REQ-022`: performance span разделяет query evaluation, polling wait и snapshot collection.
- `F11-REQ-023`: при timeout сохраняются last observation, UI snapshot и screenshot; при immediate expected absence тяжёлые artifacts по умолчанию не создаются.
- `F11-REQ-024`: ambiguous query не считается отсутствием; strict mode возвращает `ambiguous_match`, даже для negative assertion, если найдены неожиданные candidates.

## Пример API

Non-asserting ожидание для optional UI:

```swift
if find(identifier: "optionalBanner").waitForDisplayed(timeout: 2) {
    find(identifier: "optionalBanner.closeButton").tap()
}

guard find(identifier: "submit").waitForHittable(timeout: 5) else { return }
guard find(identifier: "submit").waitForEnabled(timeout: 5) else { return }

find(identifier: "filterChip").tap()
guard find(identifier: "filterChip").waitForSelected(timeout: 2) else { return }
```

Финальная проверка состояния:

```swift
let banner = find(identifier: "promoBanner")

banner.assertExists()
find(identifier: "promoBanner.closeButton").tap()
banner.assertDoesNotExist(timeout: 5)
```

Если тесту важно доказать именно переход:

```swift
let banner = find(identifier: "promoBanner")
banner.assertDisappears(timeout: 5) {
    find(identifier: "promoBanner.closeButton").tap()
}
```

Closure-вариант связывает triggering action и transition timeline в одной операции.

Для переиспользуемых component POM container/child semantics и рекомендуемый `closeAndAssertGone` определены в [F12](12_REUSABLE_COMPONENT_POM_RU.md).

## Acceptance criteria

- Already absent element немедленно проходит `assertDoesNotExist` без ожидания find timeout.
- Present element, исчезающий через animation, проходит после наблюдения `absent` в пределах одного deadline.
- Element, оставшийся present после timeout, даёт failure с last state и evidence, не «not found».
- `assertDisappears` падает, если element уже отсутствовал до начала transition.
- `assertIsNotDisplayed` различает `absent` и `hidden`; `assertIsHidden` не проходит для absent.
- Static text может быть visible и non-hittable одновременно.
- Parallel assertions не смешивают locator, observations и timelines разных tests.
- Performance telemetry показывает реальный elapsed одного wait, без двойного timeout.
- Одна и та же locator variable может наблюдать `present`, затем `absent`, затем снова `present` при изменениях UI; пересоздавать public variable не требуется.
- Каждая polling attempt способна увидеть изменение tree, произошедшее после предыдущей попытки.
- Non-asserting wait немедленно возвращает `true` при совпадении, возвращает `false` после одного timeout и не создаёт XCTest failure.
- Non-asserting wait при отсутствующем application context возвращает `false` без XCUI exception.

## Решения и оставшиеся вопросы

- `F11-DEC-001`: `.onScreen` — default visibility policy для UIKit, SwiftUI и accessibility descendants WebView. Полное или частичное пересечение viewport является high-confidence visible observation; valid frame вне viewport — high-confidence hidden. Если XCUI не предоставляет valid app viewport, framework принимает valid element frame с явным low-confidence reason `visibility.viewport_unavailable_fallback`. `.nonEmptyFrame` остаётся explicit medium-confidence compatibility policy.
- `F11-DEC-002`: основной transition API принимает closure `after`, поэтому trigger и observation входят в одну semantic operation.
- `F11-DEC-003`: strict ambiguity является default; first-match permissive behavior включается только явной конфигурацией.
