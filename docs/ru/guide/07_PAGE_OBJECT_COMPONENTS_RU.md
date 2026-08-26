# Компоненты Page Object

Русский · [English](../../en/guide/07_PAGE_OBJECT_COMPONENTS_EN.md) · [Оглавление](../PRODUCT_GUIDE_RU.md) · [Краткий README](../../../README_RU.md)


Компонент объединяет основной UI-элемент и его внутренние элементы. Один и тот же Page Object можно использовать на разных экранах.

```swift
struct PromoBanner: XCEasyComponent {
    let element = find(identifier: "promoBanner")
    let componentName: String

    init(componentName: String? = nil) {
        self.componentName = componentName ?? Self.defaultComponentName
    }

    var title: XCEasyUIElement {
        element.child(identifier: "promoBanner.title")
    }

    var closeButton: XCEasyUIElement {
        element.child(type: .button, identifier: "promoBanner.closeButton")
    }

    @discardableResult
    func dismiss() -> Self {
        step("Закрыть") {
            closeButton.tap()
        }
        return self
    }
}
```

Если конкретное имя не нужно, `componentName` можно вообще не объявлять: protocol возьмёт `PromoBanner` из имени типа. Stored property и initializer нужны только тогда, когда одинаковые компоненты хочется различать в отчёте:

```swift
let topBanner = PromoBanner(componentName: "Верхний промобаннер")
let bottomBanner = PromoBanner(componentName: "Нижний промобаннер")
```

В Allure появятся шаги `Верхний промобаннер: Закрыть` и `Нижний промобаннер: Закрыть`. В canonical JSONL те же операции имеют code `component.step`, отдельное поле `target` с именем instance и полный locator `element`. Поэтому ИИ не обязан извлекать component context из локализованного текста.

## Проверка компонента и его частей

`XCEasyComponent` намеренно требует только `element`. Компонентные assertions проверяют только этот основной элемент, поэтому их смысл не зависит от скрытого списка дочерних элементов:

| Вызов | Что проверяется |
|---|---|
| `banner.assertExists()` | Только наличие `element` в accessibility tree. |
| `banner.assertIsDisplayed()` | Только отображение `element`. |
| `banner.assertDoesNotExist()` | Только отсутствие `element`; дочерние элементы уже не проверяются. |
| `banner.assertIsNotDisplayed()` / `assertIsHidden()` / `assertIsHittable()` | Соответствующее состояние `element`. |
| `banner.waitForDisplayed()` / `waitForHittable()` / `waitForEnabled()` / `waitForSelected()` | Non-asserting ожидание соответствующего состояния только для `element`; результат — `Bool`. |

Действие само ждёт нужное состояние. Например, `banner.closeButton.tap()` по умолчанию ждёт `.hittable`, поэтому отдельный readiness descriptor перед нажатием не нужен. Если бизнес-тесту важно отдельно доказать полную загрузку компонента, опишите понятный метод непосредственно в POM:

```swift
extension PromoBanner {
    @discardableResult
    func assertIsReady(timeout: TimeInterval = 5) -> Self {
        element.assertIsDisplayed(timeout: timeout)
        title.assertIsDisplayed(timeout: timeout)
        closeButton.assertIsHittable(timeout: timeout)
        return self
    }
}

let banner = PromoBanner(componentName: "Промобаннер каталога")
banner.assertIsReady().dismiss()
```

## `step` внутри POM

У component нет отдельной команды, которую нужно запоминать. Тот же вызов `step`, использованный внутри метода POM, автоматически добавляет `componentName` и locator `element`. Он работает для action, assertion, чтения данных и sync/async closure. Под капотом используется тот же lifecycle и тот же stack, что у глобального `step`, поэтому вложенность не теряется:

```swift
extension PromoBanner {
    @discardableResult
    func assertTitle(_ expectedTitle: String) -> Self {
        step("Проверить заголовок") {
            title.assertLabel(value: expectedTitle)
        }
        return self
    }
}

let banner = PromoBanner(componentName: "Промобаннер каталога")

step("Проверить каталог") {
    banner.assertTitle("Специальное предложение")
}
```

Таким образом, тест работает с доменным методом `assertTitle`, а информация о внутреннем элементе и способе его проверки остаётся внутри POM. В Allure дерево будет `Проверить каталог` → `Промобаннер каталога: Проверить заголовок` → assertion. Ошибка или `await` не превращают внутренний шаг в соседний top-level step.

## Что такое `XCEasyComponentCollection`

Это ленивый и UI-aware набор однотипных Page Object-компонентов: карточек товара, строк таблицы, сообщений или ячеек. Компонент один раз описывает общий locator всех экземпляров, а коллекция даёт понятные getters, ожидания и assertions по их текущему состоянию.

```swift
struct ProductCard: XCEasyIndexedComponent {
    static var collection: XCEasyUIElement {
        find(type: .cell, identifier: "productCard", desc: "Карточки товара")
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

    var title: XCEasyUIElement {
        element.child(identifier: "productCard.title")
    }
}

let cards = XCEasyComponentCollection<ProductCard>()

cards.first.assertIsDisplayed()
cards.last.title.assertExists()
cards.get(index: 2).assertIsDisplayed()
cards.get(index: 2, componentName: "Рекомендованный товар").title.assertExists()

for card in cards.get(indices: 0..<3) {
    card.assertExists()
}
```

Если `componentName` не задан, framework без обращения к UI формирует имя с позицией: `First ProductCard`, `Last ProductCard` или `ProductCard at index 2`. Передавайте `componentName` только тогда, когда у instance есть более полезный доменный смысл, например `Recommended product`.

`collection` должен совпадать со всеми экземплярами компонента, а не только с первым. Свойство `element` получает из него один экземпляр по `position`: `.first`, `.last` или `.index(Int)`. `element(at:)` не ищет UI сразу, а создаёт lazy locator. Поэтому сохранённый `cards.last` при каждом действии или assertion заново вычисляет последний элемент и остаётся актуальным после добавления или удаления карточек.

Доступные getters:

| Вызов | Результат |
|---|---|
| `cards.first` | Lazy POM первого текущего match. |
| `cards.last` | Lazy POM последнего текущего match; index заранее не кешируется. |
| `cards.get(index: 2)` | Lazy POM по zero-based index. |
| `cards.get(index: 2, componentName: "...")` | То же, но с конкретным именем instance для отчёта. |
| `cards.get(indices: 0..<3)` | Массив lazy POM для индексов `0`, `1`, `2`; UI при создании массива не читается. |

Отрицательный index не приводит к crash внутри XCUI. Locator сохраняет его как некорректное намерение, а semantic use элемента завершится с reason `query.invalid_index`. `last` на пустой коллекции аналогично даёт `query.collection_empty`, а не обращается к index `-1`.

Явные проверки и ожидания коллекции:

| Вызов | Что происходит |
|---|---|
| `cards.assertCount(3)` | Падает, если текущих matches не ровно 3. |
| `cards.assertCount(atLeast: 2)` | Падает, если matches меньше 2. |
| `cards.assertCount(atMost: 5)` | Падает, если matches больше 5. |
| `cards.assertIsEmpty()` | Ожидает отсутствие всех matching containers. |
| `cards.assertIsNotEmpty()` | Ожидает хотя бы один matching container. |
| `cards.waitForCount(3)` | Ждёт ровно 3 и возвращает `Bool`, не падая по timeout. |
| `cards.waitForCount(atLeast: 2)` | Ждёт нижнюю границу и возвращает `Bool`. |
| `cards.waitForCount(atMost: 5)` | Ждёт верхнюю границу и возвращает `Bool`. |
| `cards.assertAllDisplayed()` | Требует непустую коллекцию и отображение каждого текущего match. |
| `cards.waitForAllDisplayed()` | Ждёт то же состояние и возвращает `Bool` без assertion failure. |

Каждая polling attempt заново читает текущее accessibility tree. Публичные getters, waits и assertions автоматически создают локализованный Allure step. Canonical события `ui.collection.started`/`ui.collection.finished` отдельно сохраняют operation code, locator, expected/actual count, attempts, duration, displayed count, проблемные indices и ограниченную timeline. Обычный лог дублирует эти данные короткой строкой, поэтому причину может восстановить и человек, и ИИ. У `init()` шага нет: создание collection остаётся безопасным до начала test lifecycle и не обращается к UI.
