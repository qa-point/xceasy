# Element assertions

English · [Русский](../../ru/guide/04_ELEMENT_ASSERTIONS_RU.md) · [Contents](../PRODUCT_GUIDE_EN.md) · [Short README](../../../README.md)


Every UI assertion reads the current screen state and uses `XCEasyConfig.assertionTimeout` by default. Presence in the accessibility tree, display, and interactability are different states:

| Assertion | Exact expectation |
|---|---|
| `assertExists()` | The element is in the accessibility tree. It may be hidden. |
| `assertDoesNotExist()` | The element is absent from the accessibility tree. A hidden element still exists and does not satisfy this assertion. |
| `assertIsDisplayed()` | The element is in the tree and displayed on screen. |
| `assertIsNotDisplayed()` | Nothing is displayed on screen. The element may have been removed from the tree **or** may remain there in a hidden state. |
| `assertIsHidden()` | The element remains in the tree but is not displayed. The assertion fails if it was removed. |
| `assertIsHittable()` | XCUI reports that the element can currently receive an interaction. |
| `assertIsNotHittable()` | It cannot receive an interaction; it may also be absent. |
| `assertIsEnabled()` | An existing element is in the enabled state. |
| `assertIsDisabled()` | An existing element is in the disabled state. |
| `assertIsSelected()` | An existing element is selected, such as an active tab or switch. |
| `assertIsNotSelected()` | An existing element is not selected. |
| `assertLabel(value:)` | The element's accessibility label equals the expected string. |
| `assertValue(text:)` | The element's accessibility value equals the expected string. |
| `assertDisappears(timeout:after:)` | The element exists **before** the action and is absent from the tree afterward. |
| `assertBecomesHidden(timeout:after:)` | The element exists **before** the action, remains in the tree, and becomes hidden afterward. |

`assertDoesNotExist()` and `assertIsNotDisplayed()` do not require the element to appear first. That is useful for checking a final state, but it does not prove a transition. `assertDisappears` and `assertBecomesHidden` first verify initial presence, run the `after` closure, and only then wait for the new state. They therefore catch the case where the element never appeared.

An element is removed from the accessibility tree:

```swift
let banner = find(identifier: "promoBanner")
banner.assertExists()
find(identifier: "promoBanner.closeButton").tap()
banner.assertDoesNotExist(timeout: 5)
```

The same transition can be verified with one method:

```swift
let banner = find(identifier: "promoBanner")
banner.assertDisappears(timeout: 5) {
    find(identifier: "promoBanner.closeButton").tap()
}
```

A view must remain in the tree but become hidden:

```swift
let details = find(identifier: "detailsPanel")
details.assertBecomesHidden(timeout: 5) {
    find(identifier: "collapseButton").tap()
}
details.assertIsHidden()
```

State and value assertions can be chained because they return the same `XCEasyUIElement`:

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

Boolean counterparts are available for conditions: `isExists`, `isNotExists`, `isDisplayed`, `isNotDisplayed`, `isHidden`, `isHittable`, `isNotHittable`, `isEnabled`, `isDisabled`, `isSelected`, and `isNotSelected`. They return `Bool` and do not create an XCTest failure. Use `assert...` for expected test outcomes; reserve Boolean forms for branching or intermediate state reads.

## Every assertion in a test

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
        find(identifier: "title").assertLabel(value: "Catalog")
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

Each call becomes an assertion step:

```text
Assert element [title] is displayed            assert.visible          passed
  UI query                                     ui.query                passed
Assert element [title] label                   assert.equal            passed
Assert [successToast] disappears               assert.disappears       passed
  Trigger disappearance                        action.trigger_disappearance
```

On failure, the step contains expected/observed state, timeout, locator chain, and available screenshot/tree evidence. This distinguishes “not found,” “found but hidden,” “visible but not hittable,” and ambiguity.
