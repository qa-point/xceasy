# Проверки элементов

Русский · [English](../../en/guide/04_ELEMENT_ASSERTIONS_EN.md) · [Оглавление](../PRODUCT_GUIDE_RU.md) · [Краткий README](../../../README_RU.md)


Все UI-проверки работают с текущим состоянием экрана и по умолчанию используют `XCEasyConfig.assertionTimeout`. Наличие в accessibility tree, отображение и возможность взаимодействия — разные состояния:

| Проверка | Что именно ожидается |
|---|---|
| `assertExists()` | Элемент есть в accessibility tree. Он может быть скрыт. |
| `assertDoesNotExist()` | Элемента нет в accessibility tree. Скрытый элемент считается существующим, поэтому эту проверку не пройдёт. |
| `assertIsDisplayed()` | Элемент есть в дереве и отображается на экране. |
| `assertIsNotDisplayed()` | На экране элемент не отображается. Он может быть удалён из дерева **или** оставаться в нём скрытым. |
| `assertIsHidden()` | Элемент остаётся в дереве, но не отображается. Если он удалён, проверка упадёт. |
| `assertIsHittable()` | XCUI считает, что с элементом сейчас можно взаимодействовать. |
| `assertIsNotHittable()` | Взаимодействовать нельзя; элемент также может отсутствовать. |
| `assertIsEnabled()` | Существующий элемент находится в enabled-состоянии. |
| `assertIsDisabled()` | Существующий элемент находится в disabled-состоянии. |
| `assertIsSelected()` | Существующий элемент выбран, например активный tab или switch. |
| `assertIsNotSelected()` | Существующий элемент не выбран. |
| `assertLabel(value:)` | Accessibility label элемента равен ожидаемой строке. |
| `assertValue(text:)` | Accessibility value элемента равен ожидаемой строке. |
| `assertDisappears(timeout:after:)` | Элемент существует **до** action и отсутствует в дереве после него. |
| `assertBecomesHidden(timeout:after:)` | Элемент существует **до** action, остаётся в дереве и становится скрытым после него. |

`assertDoesNotExist()` и `assertIsNotDisplayed()` не требуют, чтобы элемент сначала появился. Это удобно для проверки конечного состояния, но не доказывает переход. Методы `assertDisappears` и `assertBecomesHidden` сначала проверяют начальное наличие, затем выполняют closure `after` и только после этого ждут новое состояние. Поэтому они обнаружат ситуацию, когда элемент не появился вообще.

Элемент удаляется из accessibility tree:

```swift
let banner = find(identifier: "promoBanner")
banner.assertExists()
find(identifier: "promoBanner.closeButton").tap()
banner.assertDoesNotExist(timeout: 5)
```

Тот же переход можно проверить одним методом:

```swift
let banner = find(identifier: "promoBanner")
banner.assertDisappears(timeout: 5) {
    find(identifier: "promoBanner.closeButton").tap()
}
```

View должен остаться в дереве, но стать скрытым:

```swift
let details = find(identifier: "detailsPanel")
details.assertBecomesHidden(timeout: 5) {
    find(identifier: "collapseButton").tap()
}
details.assertIsHidden()
```

Проверки состояния и значения можно объединять в цепочку, потому что они возвращают тот же `XCEasyUIElement`:

```swift
find(identifier: "notificationsSwitch")
    .assertExists()
    .assertIsDisplayed()
    .assertIsEnabled()
    .assertIsSelected()

find(identifier: "welcomeTitle")
    .assertLabel(value: "Welcome")

find(identifier: "cartCount")
    .assertValue(text: "42")
```

Для проверок внутри условий есть булевы аналоги: `isExists`, `isNotExists`, `isDisplayed`, `isNotDisplayed`, `isHidden`, `isHittable`, `isNotHittable`, `isEnabled`, `isDisabled`, `isSelected`, `isNotSelected`. Они возвращают `Bool` и не создают XCTest failure. Для ожидаемого результата теста используйте `assert...`, а булевы варианты оставляйте для ветвления или промежуточного чтения состояния.

## Пример всех assertions внутри теста

```swift
final class ElementAssertionTests: BaseTestCase {
    func testAllElementStates() {
        find(identifier: "screen").assertExists()
        find(identifier: "removedBanner").assertDoesNotExist(timeout: 2)
        find(identifier: "title").assertIsDisplayed()
        find(identifier: "optionalTooltip").assertIsNotDisplayed()
        find(identifier: "collapsedDetails").assertIsHidden()
        find(identifier: "submitButton").assertIsHittable()
        find(identifier: "blockedButton").assertIsNotHittable()
        find(identifier: "emailField").assertIsEnabled()
        find(identifier: "saveButton").assertIsDisabled()
        find(identifier: "selectedTab").assertIsSelected()
        find(identifier: "otherTab").assertIsNotSelected()
        find(identifier: "title").assertLabel(value: "Каталог")
        find(identifier: "cartCount").assertValue(text: "2")

        find(identifier: "successToast").assertDisappears(timeout: 5) {
            find(identifier: "saveButton").tap()
        }
        find(identifier: "filterSheet").assertBecomesHidden(timeout: 5) {
            find(identifier: "filterSheet.collapse").tap()
        }
    }
}
```

Каждый вызов становится отдельным assertion step:

```text
Проверить, что элемент [title] отображается     assert.visible          passed
  UI query                                     ui.query                passed
Проверить label элемента [title]               assert.equal            passed
Проверить исчезновение [successToast]           assert.disappears       passed
  Действие, вызывающее исчезновение             action.trigger_disappearance
```

При failure step содержит ожидаемое/наблюдаемое состояние, timeout, locator chain и доступные screenshot/tree evidence. Благодаря этому различаются «не найден», «найден, но скрыт», «виден, но не hittable» и ambiguity.
