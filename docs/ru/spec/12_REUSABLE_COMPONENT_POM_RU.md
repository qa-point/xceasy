# F12 — Переиспользуемые UI-компоненты и POM

Статус 0.1.0: реализовано и проверено, включая indexed collections и component-aware steps.

## Цель

Пользователь описывает интерфейс переиспользуемыми component Page Objects. Один компонент должен одинаково работать на разных экранах, если получает корректный locator основного элемента. Все дочерние элементы, действия, assertions, логи и self-healing evidence должны сохранять component scope.

## Пример предметной модели

Баннер — это не набор независимых глобальных selectors, а компонент:

```text
BannerComponent
└── element
    ├── title
    ├── subtitle
    └── closeButton
```

Один `BannerComponent` может использоваться на home, catalog и profile screen с разными element locator-ами без копирования POM.

## Реализованный baseline

- Sample использует reusable UIKit/SwiftUI component POMs с lazy elements и `element.child(...)` locators.
- Создание component или child не имеет side effects. Child strongly удерживает immutable parent locator chain, а каждый poll заново resolves все segments без fallback в app scope.
- Diagnostic schema `1.0.0` сериализует полные redacted locator chains, symbolic collection selection, bounded query/collection timelines и явные query/collection reasons. Реальные UIKit/SwiftUI tests проверяют удаление element, отсутствие child, актуальное количество компонентов и их display state.
- Public protocol `XCEasyComponent` предоставляет element-only contract, assertions, disappearance transitions, type-derived либо instance-specific `componentName` и sync/async component-aware `step`. `XCEasyIndexedComponent` объявляет общий locator коллекции и lazy position initializer. `XCEasyComponentCollection` предоставляет lazy first/last/index/range getters и явные current-tree waits/assertions для count, emptiness и all-displayed.

## Component contract

- `F12-REQ-001`: reusable component имеет immutable `element: XCEasyUIElement` либо эквивалентный `XCEasyLocator`.
- `F12-REQ-002`: child locator хранит полную immutable parent locator chain, а не resolved `XCUIElement`.
- `F12-REQ-003`: создание component, element и child properties не обращается к UI и не ожидает existence.
- `F12-REQ-004`: locator chain удерживается strongly как value/reference graph до observation; resolved snapshots не кешируются между operations по умолчанию.
- `F12-REQ-005`: отсутствие parent никогда не приводит к fallback search из app root.
- `F12-REQ-006`: nested components получают element через `parent.child(...)` и сохраняют полный scope path.
- `F12-REQ-007`: один component type поддерживает element injection, identifier factory и indexed collection factory без дублирования реализации.
- `F12-REQ-008`: component instance имеет stable type name и optional semantic instance name для logs/telemetry, но identity не зависит от memory address.
- `F12-REQ-027`: сохранение screen, component, element или child в property или local variable сохраняет только immutable locator intent; последующее semantic use разрешает его по актуальному на этот момент accessibility tree.
- `F12-REQ-028`: component может пережить изменения screen, удаление и повторное появление; каждый action, assertion и чтение value заново разрешает полную chain от element до child.
- `F12-REQ-029`: любая оптимизация, переиспользующая resolved `XCUIElement`, UI snapshot или ранее observed state между operations, нарушает component contract, даже если telemetry показывает repeated resolution как медленную операцию.
- `F12-REQ-030`: base component protocol не содержит скрытого списка обязательных children; `assertIsDisplayed()` всегда проверяет только element.
- `F12-REQ-031`: если POM нужен составной readiness contract, он объявляет именованный метод вроде `assertIsReady()`, в котором states children видны непосредственно в коде.
- `F12-REQ-032`: component `waitForDisplayed(timeout:)`, `waitForHittable(timeout:)`, `waitForEnabled(timeout:)` и `waitForSelected(timeout:)` делегируют non-asserting observation только в `element` и возвращают `Bool`; дочерние элементы не проверяются неявно.
- `F12-REQ-033`: для unique components `componentName` по умолчанию равен имени concrete POM type. Indexed components получают стабильное имя с позицией: `First <Type>`, `Last <Type>` или `<Type> at index N`. POM может принять и сохранить аргумент initializer, чтобы различать одинаковые instances на одном экране.
- `F12-REQ-034`: component-owned `step` использует тот же stack, error finalization и task-propagated lifecycle, что global `step`; nested work никогда не превращается в sibling или top-level step.
- `F12-REQ-035`: canonical step events используют `operationCode = component.step`, `target = componentName` и immutable selector `element`. Human-readable Allure title остаётся `<componentName>: <operation>`.
- `F12-REQ-036`: `XCEasyIndexedComponent` требует `collection` и `init(position:componentName:)`; convenience initializers выбирают `.first`, когда index не задан, и передают framework position-aware default, когда instance name не задан.
- `F12-REQ-037`: создание collection и first/last/index/range getters создаёт immutable locator intent без чтения UI tree.
- `F12-REQ-038`: `.last` остаётся symbolic и пересчитывается из текущего candidate count при каждом semantic use; пустая collection сообщает `query.collection_empty` без отрицательного XCUI index.
- `F12-REQ-039`: отрицательный requested index никогда не попадает в `element(boundBy:)` и сообщает `query.invalid_index` без crash.
- `F12-REQ-040`: count, emptiness и all-displayed waits/assertions получают свежий current-tree snapshot на каждой polling attempt.
- `F12-REQ-041`: `assertAllDisplayed` и `waitForAllDisplayed` требуют непустую collection; vacuous success для нуля элементов запрещён.
- `F12-REQ-042`: каждый public collection getter, wait и assertion создаёт локализованный default Allure step и lifecycle `ui.collection.started`/`ui.collection.finished`.
- `F12-REQ-043`: terminal collection evidence содержит stable operation code, selector, expectation, outcome, attempts, duration, current count, relevant display count/failing indices, context availability, source и timeline максимум из 50 observations.
- `F12-REQ-044`: selection evidence ограничен 100 indices, а selection getters не собирают UI screenshots или tree snapshots только ради создания locator intent.
- `F12-REQ-045`: non-asserting collection waits возвращают `false` по timeout и сохраняют warning evidence; assertion variants записывают XCTest failure внутри report step.

## Контракт актуальности

```swift
let banner = screen.promoBanner       // создаёт component и locators; UI query не выполняется
banner.assertExists()                 // fresh element resolution
banner.closeButton.tap()              // fresh element + child resolution
banner.assertDoesNotExist(timeout: 5) // fresh element resolution после изменения UI
```

Чтение POM property намеренно дешёвое и не имеет side effects. Поиск начинается только при semantic use значения: action, assertion, чтении state/value или явном observation API. Каждая polling attempt является новой observation того же immutable locator, а не повторным чтением сохранённого element или tree snapshot.

## Assertions компонента

- `F12-REQ-009`: component `assertExists`/`assertDoesNotExist` применяются к `element`.
- `F12-REQ-010`: element absence является достаточным доказательством отсутствия всего component.
- `F12-REQ-011`: component `assertIsDisplayed` проверяет только element visibility; дочерние элементы не проверяются неявно.
- `F12-REQ-012`: child `assertDoesNotExist` проходит при отсутствующем ancestor с reason `query.ancestor_absent`; locator path сохраняется полностью.
- `F12-REQ-013`: child `assertIsHidden` не проходит при отсутствующем ancestor, потому что presence является частью hidden contract.
- `F12-REQ-014`: component transition `assertDisappears` наблюдает element; удаление element завершает transition, даже если descendants становятся недоступны одновременно.
- `F12-REQ-015`: для проверки закрытия компонента рекомендуется element assertion, чтобы опечатка child selector не дала ложный success.

## Actions компонента

- `F12-REQ-016`: public POM actions выражают semantic intent (`close`, `select`, `fill`) и могут возвращать `Self` для chaining.
- `F12-REQ-017`: action step содержит component type/instance, element locator path, child target и source location.
- `F12-REQ-018`: действие, после которого element должен исчезнуть, может быть связано с transition assertion в одном semantic operation.
- `F12-REQ-019`: component не хранит mutable cross-test UI state; данные instance безопасны для параллельных tests.

## Public API

```swift
public protocol XCEasyComponent {
    var element: XCEasyUIElement { get }
    var componentName: String { get }
}

struct BannerComponent: XCEasyComponent {
    let element: XCEasyUIElement
    let componentName: String

    init(element: XCEasyUIElement, componentName: String? = nil) {
        self.element = element
        self.componentName = componentName ?? Self.defaultComponentName
    }

    var title: XCEasyUIElement {
        element.child(identifier: "title")
    }

    var subtitle: XCEasyUIElement {
        element.child(identifier: "subtitle")
    }

    var closeButton: XCEasyUIElement {
        element.child(identifier: "closeButton")
    }

    @discardableResult
    func assertIsReady(timeout: TimeInterval = 5) -> Self {
        element.assertIsDisplayed(timeout: timeout)
        title.assertIsDisplayed(timeout: timeout)
        subtitle.assertIsDisplayed(timeout: timeout)
        closeButton.assertIsHittable(timeout: timeout)
        return self
    }

    @discardableResult
    func closeAndAssertGone(timeout: TimeInterval = 5) -> Self {
        step("Закрыть и проверить удаление") {
            element.assertDisappears(timeout: timeout) {
                closeButton.tap()
            }
        }
        return self
    }
}
```

Переиспользование на разных экранах:

```swift
var promoBanner: BannerComponent {
    BannerComponent(
        element: find(identifier: "home.promoBanner"),
        componentName: "Главный промобаннер"
    )
}

var catalogBanner: BannerComponent {
    BannerComponent(
        element: find(identifier: "catalog.content")
            .child(identifier: "promoBanner")
    )
}
```

Indexed components включают отдельный protocol, поэтому unique component никогда не получает index `0` неявно:

```swift
struct ProductCard: XCEasyIndexedComponent {
    static var collection: XCEasyUIElement {
        find(identifier: "productCard")
    }

    private let position: XCEasyComponentPosition
    let componentName: String

    init(position: XCEasyComponentPosition, componentName: String?) {
        self.position = position
        self.componentName = componentName ?? Self.defaultComponentName(for: position)
    }

    var element: XCEasyUIElement {
        Self.collection.element(at: position, desc: componentName)
    }
}

let cards = XCEasyComponentCollection<ProductCard>()
cards.assertCount(3).assertAllDisplayed()
cards.first.assertExists()
cards.get(index: 2, componentName: "Рекомендованный товар").assertIsDisplayed()
cards.last.assertExists()
```

## Observation и reason codes

Для child locator observation дополнительно содержит:

- component operation code и instance `target`;
- полный element-to-child selector в `selector`;
- `failed_segment_index`;
- `ancestor_state`;
- reason `query.ancestor_absent`, `query.ancestor_ambiguous`, `query.element_absent`, `query.child_hidden` или `query.child_present`.

`query.ancestor_absent` является корректным success reason для `assertDoesNotExist`, но не должен теряться в общем сообщении «child not found».

## Self-healing

- `F12-REQ-020`: healing ищет replacement внутри исходного component element, а не по всему app tree.
- `F12-REQ-021`: если element изменился, engine сначала предлагает element mapping, затем повторно оценивает descendants.
- `F12-REQ-022`: одинаковые children в разных component instances не смешиваются в candidate ranking.
- `F12-REQ-023`: изменение shared component POM перечисляет все screens/tests, которые потенциально затрагиваются.

## Performance telemetry

- `F12-REQ-024`: spans сохраняют component/element/child path и отдельно измеряют каждый segment resolution.
- `F12-REQ-025`: repeated resolution одного element отображается как finding, но caching предлагается только после анализа staleness.
- `F12-REQ-026`: component-level action/assertion является parent span для внутренних UI operations.

## Compatibility

Components используют `element.child(...)` и сохраняют immutable locator chain; resolved UI elements никогда не хранятся как component parents. Удаление beta-имён `root` и `componentStep` является намеренным и описано в component API migration guide.

Неопубликованные closure initializer, optional subscript, `component(at:)` и `prefix(_:)` удалены без deprecated aliases. Consumer объявляет `XCEasyIndexedComponent.collection`, создаёт `XCEasyComponentCollection<Component>()` и использует `first`, `last`, `get(index:)`, `get(indices:)` либо явные collection state operations.

## Acceptance criteria

- Чтение `banner.title` не выполняет query и не ждёт timeout.
- Два banner instances с одинаковыми child identifiers разрешаются только внутри своих elements.
- Удалённый element не вызывает global fallback и корректно проходит component `assertDoesNotExist`.
- Child negative assertion при удалённом element проходит с reason `query.ancestor_absent`.
- Child positive assertion при удалённом element падает с locator path и failed ancestor segment.
- Shared component POM работает под elements на двух разных screens без копирования кода.
- Nested components глубиной минимум 3 сохраняют scope, telemetry и attachment ownership.
- Параллельные tests с одинаковыми component types не смешивают observations.
- Component, созданный до появления element, позже находит его без пересоздания component.
- Один и тот же сохранённый component наблюдает удаление и повторное появление element и никогда не возвращает cached state.
- Child operation после изменения screen заново разрешает каждый parent segment и не использует stale parent handle.
- `banner.assertIsDisplayed()` проверяет только element; component waits наблюдают element без XCTest failure, а `banner.closeButton.tap()` самостоятельно ждёт effective action state.
- Составная readiness-проверка имеет явное domain name и перечисляет child assertions в POM.
- Global step, содержащий component step, nested component steps и их внутренний assertion/action, сохраняет точную Allure hierarchy в sync и async tests.
- Throw из component step отмечает hierarchy failed, восстанавливает parent stack и оставляет следующий step на корректном уровне.
- Два одинаковых component с разными initializer names имеют разные human-readable step targets, а locator evidence остаётся structured.
- Сохранённые `first` и `last` components разрешаются по текущей collection после вставки или удаления без cached indices.
- Exact/lower/upper count, empty/nonempty и all-displayed wait/assertion variants имеют deterministic unit coverage и real SwiftUI sample coverage.
- Каждая collection operation имеет локализованный step и terminal evidence schema 1.0.0 для восстановления expected и observed state.

## Решения и оставшиеся вопросы

- `F12-DEC-001`: `XCEasyComponent` является public protocol фреймворка с default element assertions и component-aware overload обычного имени `step`.
- `F12-DEC-002`: решение о hidden required-child descriptors отменено 10 августа 2026 года до production-релиза. `XCEasyComponentRequirement`, `XCEasyRequiredChildState`, `requiredChildren` и `assertRequiredChildren()` удалены; component assertions имеют только element semantics, а составная готовность выражается именованным POM-методом.
- `F12-DEC-003`: superseded ADR-0015. `XCEasyComponentCollection` сохраняет selection metadata side-effect-free, но предоставляет явные UI-reading methods, чьи имена (`assertCount`, `waitForCount`, `assertAllDisplayed`) делают момент query видимым.
- `F12-DEC-004`: public beta names `root` и `componentStep` удаляются без deprecated aliases. `element` не путается с root accessibility tree, а единое имя `step` не создаёт parallel lifecycle API.
- `F12-DEC-005`: optional default-index convenience принадлежит `XCEasyIndexedComponent`. Base component protocol не подразумевает indexing.
- `F12-DEC-006`: ADR-0016 заменяет beta-имена `container`/`collectionContainer` на `element`/`collection`; Allure result containers и canonical selector fields не меняются.
