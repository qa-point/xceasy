# Поиск и работа с элементами

Русский · [English](../../en/guide/03_ELEMENT_LOOKUP_EN.md) · [Оглавление](../PRODUCT_GUIDE_RU.md) · [Краткий README](../../../README_RU.md)


## Как работает `find`

`find` не ищет элемент сразу. Он только запоминает, **как** найти элемент. Реальный поиск начинается при `tap`, `assert...`, `getValue` и других операциях. При каждом таком вызове XCEasy снова читает текущее дерево элементов.

Поэтому этот код безопасен после изменения экрана:

```swift
let banner = find(identifier: "promoBanner")

banner.assertExists() // поиск №1 в текущем дереве
find(identifier: "promoBanner.closeButton").tap()
banner.assertDoesNotExist(timeout: 5) // новый поиск после закрытия
```

Если один locator неожиданно нашёл несколько элементов, режим `.strict` завершит операцию ошибкой: XCEasy не может безопасно угадать, какой элемент нужен. Лучше уточнить identifier, ограничить поиск родительским компонентом или явно передать `index`. Режим `.permissive` берёт первый результат и пишет предупреждение; он полезен только там, где первый элемент действительно является частью контракта теста.

## Варианты поиска

```swift
find(identifier: "submitButton")
find(text: "Login")
find(format: "label CONTAINS 'Welcome'")
find(type: .button, identifier: "submitButton")
find(type: .cell, index: 2)

let list = find(identifier: "productList")
let item = list.child(type: .cell, identifier: "productCard")
```

Стабильный accessibility identifier предпочтительнее текста и predicate: он меньше зависит от локализации и изменения дизайна.

Все overloads принимают опциональные `index`, `desc` и `timeout`: `index` — zero-based выбор среди нескольких совпадений, `desc` — понятное название элемента в шагах, `timeout` — default ожидание положительного поиска для этого locator-а. Тип можно комбинировать с `identifier`, `text` или `format`; часто используются `.button`, `.staticText`, `.textField`, `.secureTextField`, `.cell`, `.table`, `.collectionView`, `.scrollView`, `.switch` и `.webView`.

`child(...)` имеет те же варианты `identifier`, `text`, `format`, `type`, `index`, `desc`, `timeout`, но ограничивает поиск текущим родителем. Цепочка может иметь несколько уровней, и вся цепочка заново разрешается при каждой операции.

## Действия и чтение

| Метод | Результат |
|---|---|
| `tap(timeout:policy:)` / `doubleTap(timeout:policy:)` | Одинарное или двойное нажатие после ожидания состояния, заданного action policy. |
| `press(forDuration:timeout:policy:)` | Длительное нажатие заданное число секунд. |
| `swipe(_:timeout:policy:)` | Swipe `.up`, `.down`, `.left` или `.right` внутри frame элемента. |
| `typeText(_:timeout:policy:)` | Фокусирует элемент выбранным способом и вводит текст. Сам текст не записывается в action log. |
| `clearField(timeout:policy:)` | Фокусирует поле, читает текущее value и отправляет нужное число delete-клавиш. Значение не логируется. |
| `getLabel(timeout:)` | Ждёт существования и возвращает accessibility label. |
| `getValue(timeout:)` | Ждёт существования и возвращает accessibility value как `String`. |
| `printDebugTree()` | Печатает debug tree найденного элемента в консоль. |

```swift
find(identifier: "button").tap()
find(identifier: "button").doubleTap()
find(identifier: "button").press(forDuration: 2)
find(identifier: "field").typeText("Hello")
find(identifier: "field").clearField()
find(identifier: "list").swipe(.up)

let label = find(identifier: "title").getLabel()
let value = find(identifier: "field").getValue()
```

Все UI-действия по умолчанию используют `XCEasyConfig.actionPolicy == .hittable`: каждое действие заново находит элемент и ждёт, пока XCUI разрешит безопасное взаимодействие. Текст, иконка или другой дочерний элемент не обязаны иметь собственный обработчик — нажатие отправляется в их область, а событие может обработать родительская плитка.

Для нестандартного accessibility tree можно выбрать `.displayed`. Тогда XCEasy ждёт отображения и отправляет жест через координаты элемента. Такой режим менее безопасен: если цель перекрыта overlay, coordinate action может попасть в overlay. Поэтому `.displayed` всегда отражается warning-событиями `ui.action.policy` и `ui.action.dispatched`.

```swift
XCEasyConfig.apply(actionPolicy: .hittable) // безопасный default для всех действий

tile.title.tap()                            // global policy
tile.icon.tap(policy: .displayed)           // override только этого действия
list.swipe(.up, timeout: 5, policy: .displayed)
field.typeText("Hello", policy: .hittable)
```

Global policy входит в execution-scoped конфигурацию конкретного теста. Не меняйте её как общий default во время параллельного прогона; для исключений используйте локальный `policy`. При `.displayed` `tap`, `doubleTap`, `press` и `swipe` выполняются координатами, а `typeText`/`clearField` сначала делают coordinate tap для передачи фокуса.

Actions и assertions возвращают тот же lazy proxy, поэтому допустимы цепочки `field.clearField().typeText("new value").assertValue(text: "new value")`. Каждая операция при этом выполняет новый поиск; цепочка не превращает элемент в сохранённый snapshot.

Булевы методы `isExists`, `isDisplayed`, `isHittable`, `isEnabled`, `isSelected` и их отрицательные варианты возвращают результат без XCTest assertion. Явные `waitForDisplayed`, `waitForHittable`, `waitForEnabled` и `waitForSelected` используют ту же безопасную polling-механику, но лучше показывают намерение синхронизации в тесте. Для финальной проверки теста обычно лучше методы `assert...`, потому что они создают явное падение и диагностический шаг.

## Ожидание без падения теста

| Метод | Поведение |
|---|---|
| `waitForDisplayed(timeout:) -> Bool` | Сразу возвращает `true`, когда элемент появился на экране; после таймаута возвращает `false`. |
| `waitForHittable(timeout:) -> Bool` | Сразу возвращает `true`, когда XCUI разрешает взаимодействие; после таймаута возвращает `false`. |
| `waitForEnabled(timeout:) -> Bool` | Сразу возвращает `true`, когда существующий элемент перешёл в enabled-состояние; после таймаута возвращает `false`. |
| `waitForSelected(timeout:) -> Bool` | Сразу возвращает `true`, когда существующий элемент перешёл в selected-состояние; после таймаута возвращает `false`. |

Все четыре метода по умолчанию используют `XCEasyConfig.actionTimeout`, на каждой попытке заново находят элемент в текущем accessibility tree и не создают XCTest failure. Результат помечен `@discardableResult`: его можно проигнорировать и продолжить тест после таймаута, но для optional UI обычно понятнее обработать `Bool`. Неуспешное ожидание остаётся в структурированной диагностике и не маскируется как успешный поиск. Для `waitForEnabled` и `waitForSelected` элемент должен существовать: отсутствие не считается enabled- или selected-состоянием.

```swift
let optionalBanner = find(identifier: "optionalBanner")

if optionalBanner.waitForDisplayed(timeout: 2) {
    optionalBanner.child(identifier: "optionalBanner.closeButton").tap()
}

guard submitButton.waitForHittable(timeout: 5) else { return }
guard submitButton.waitForEnabled(timeout: 5) else { return }
submitButton.tap()

filterChip.tap()
guard filterChip.waitForSelected(timeout: 2) else { return }
```

## Полный пример внутри теста

```swift
final class ElementApiTests: BaseTestCase {
    func testLookupActionsReadsAndState() {
        let byId = find(identifier: "submitButton", desc: "Отправить", timeout: 5)
        let byText = find(text: "Войти")
        let byPredicate = find(format: "label BEGINSWITH 'Добро'")
        let typedById = find(type: .button, identifier: "submitButton")
        let typedByText = find(type: .staticText, text: "Главная")
        let typedByPredicate = find(type: .cell, format: "identifier BEGINSWITH 'product'")
        let typedByIndex = find(type: .cell, index: 2)

        let list = find(identifier: "productList")
        let childById = list.child(identifier: "productCard", index: 0)
        let childByText = list.child(text: "Товар")
        let childByPredicate = list.child(format: "label CONTAINS '₽'")
        let typedChildById = list.child(type: .button, identifier: "buyButton")
        let typedChildByText = list.child(type: .staticText, text: "Цена")
        let typedChildByPredicate = list.child(type: .cell, format: "isEnabled == true")

        byId.tap().doubleTap().press(forDuration: 0.5)
        list.swipe(.up)
        find(identifier: "searchField")
            .clearField()
            .typeText("iPhone")

        let title = find(identifier: "screenTitle").getLabel()
        let query = find(identifier: "searchField").getValue()
        assertNotEmpty(actual: title)
        assertEqual(actual: query, expected: "iPhone")

        _ = byText.isExists()
        _ = byPredicate.isNotExists(timeout: 1)
        _ = typedById.isHittable()
        _ = typedByText.isNotHittable()
        _ = typedByPredicate.isDisplayed()
        _ = typedByIndex.isNotDisplayed()
        _ = childById.isHidden()
        _ = childByText.isEnabled()
        _ = childByPredicate.isDisabled()
        _ = typedChildById.isSelected()
        _ = typedChildByText.isNotSelected()
        typedChildByPredicate.printDebugTree()
    }
}
```

В production-тесте не нужно вызывать все варианты сразу: пример служит каталогом сигнатур. `desc` попадает в человекочитаемые шаги вместо технического locator-а. `index` zero-based и должен применяться только когда порядок является частью контракта UI.

## Что будет в логах и отчёте

Операции создают отдельные timed steps, а внутренний повторный поиск остаётся дочерней диагностикой:

```text
Нажать на элемент [Отправить]              ui.tap          passed
  UI query                                  ui.query        passed
Двойное нажатие [Отправить]                ui.double_tap   passed
Свайп вверх [productList]                  ui.swipe.up     passed
Очистить текстовое поле                    ui.clear_text   passed
Ввести текст в элемент [searchField]       ui.type_text    passed
```

Вводимый текст и прочитанные `label`/`value` не включаются в action title. Булевы методы и waits не создают XCTest failure, но query evidence и timing помогают понять, почему вернулся `false`.
