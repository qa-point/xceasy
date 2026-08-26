# Finding and using elements

English · [Русский](../../ru/guide/03_ELEMENT_LOOKUP_RU.md) · [Contents](../PRODUCT_GUIDE_EN.md) · [Short README](../../../README.md)


## How `find` works

`find` does not search immediately. It only remembers **how** to find an element. The actual lookup starts on `tap`, `assert...`, `getValue`, or another operation. XCEasy reads the current element tree again for every such call.

This code therefore remains correct after the screen changes:

```swift
let banner = find(identifier: "promoBanner")

banner.assertExists() // lookup #1 in the current tree
find(identifier: "promoBanner.closeButton").tap()
banner.assertDoesNotExist(timeout: 5) // a new lookup after dismissal
```

If one locator unexpectedly matches several elements, `.strict` fails the operation because XCEasy cannot safely guess which element was intended. Prefer a more specific identifier, scope the lookup to a parent component, or provide an explicit `index`. `.permissive` takes the first result and emits a warning; use it only when first-item behavior is an intentional part of the test contract.

## Search forms

```swift
find(identifier: "submitButton")
find(text: "Login")
find(format: "label CONTAINS 'Welcome'")
find(type: .button, identifier: "submitButton")
find(type: .cell, index: 2)

let list = find(identifier: "productList")
let item = list.child(type: .cell, identifier: "productCard")
```

A stable accessibility identifier is preferable to text and predicates because it is less sensitive to localization and design changes.

Every overload accepts optional `index`, `desc`, and `timeout` values: `index` makes a zero-based selection among matches, `desc` provides a readable element name in steps, and `timeout` is this locator's default positive-search wait. A type may be combined with `identifier`, `text`, or `format`; common cases include `.button`, `.staticText`, `.textField`, `.secureTextField`, `.cell`, `.table`, `.collectionView`, `.scrollView`, `.switch`, and `.webView`.

`child(...)` provides the same `identifier`, `text`, `format`, `type`, `index`, `desc`, and `timeout` forms but scopes the search to the current parent. A chain may contain several levels, and the entire chain is resolved again for every operation.

## Actions and reads

| Method | Result |
|---|---|
| `tap(timeout:policy:)` / `doubleTap(timeout:policy:)` | Single or double tap after waiting for the state required by the action policy. |
| `press(forDuration:timeout:policy:)` | Long press for the specified number of seconds. |
| `swipe(_:timeout:policy:)` | `.up`, `.down`, `.left`, or `.right` swipe within the element frame. |
| `typeText(_:timeout:policy:)` | Focuses the element through the selected dispatch and types text. The text is not written to action logs. |
| `clearField(timeout:policy:)` | Focuses the field, reads its value, and sends the required number of delete keys. The value is not logged. |
| `getLabel(timeout:)` | Waits for existence and returns the accessibility label. |
| `getValue(timeout:)` | Waits for existence and returns the accessibility value as a `String`. |
| `printDebugTree()` | Prints the resolved element's debug tree to the console. |

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

Every UI action uses `XCEasyConfig.actionPolicy == .hittable` by default: it performs a fresh lookup and waits until XCUI reports a safe interaction point. A text, icon, or other child does not need its own handler—the touch is sent to its area and may be handled by the parent tile.

For an unusual accessibility tree, choose `.displayed`. XCEasy then waits for on-screen display and dispatches through element coordinates. This mode is less safe: when an overlay covers the target, the coordinate action may hit that overlay. XCEasy therefore records warning-level `ui.action.policy` and `ui.action.dispatched` events for `.displayed`.

```swift
XCEasyConfig.apply(actionPolicy: .hittable) // safe default for every action

tile.title.tap()                            // global policy
tile.icon.tap(policy: .displayed)           // override this action only
list.swipe(.up, timeout: 5, policy: .displayed)
field.typeText("Hello", policy: .hittable)
```

The global policy belongs to the current execution-scoped configuration. Do not mutate the shared default during a parallel run; use a local `policy` for exceptions. With `.displayed`, `tap`, `doubleTap`, `press`, and `swipe` use coordinates, while `typeText` and `clearField` first coordinate-tap to request focus.

Actions and assertions return the same lazy proxy, so chains such as `field.clearField().typeText("new value").assertValue(text: "new value")` are valid. Every operation still performs a new lookup; chaining does not turn the element into a retained snapshot.

Boolean methods such as `isExists`, `isDisplayed`, `isHittable`, `isEnabled`, `isSelected`, and their negative counterparts return a result without an XCTest assertion. Explicit `waitForDisplayed`, `waitForHittable`, `waitForEnabled`, and `waitForSelected` methods use the same safe polling mechanism while making synchronization intent clearer. Prefer `assert...` for a final test expectation because it creates an explicit failure and diagnostic step.

## Waiting without failing the test

| Method | Behavior |
|---|---|
| `waitForDisplayed(timeout:) -> Bool` | Returns `true` immediately after the element appears on screen; returns `false` after the timeout. |
| `waitForHittable(timeout:) -> Bool` | Returns `true` immediately after XCUI allows interaction; returns `false` after the timeout. |
| `waitForEnabled(timeout:) -> Bool` | Returns `true` immediately after the existing element becomes enabled; returns `false` after the timeout. |
| `waitForSelected(timeout:) -> Bool` | Returns `true` immediately after the existing element becomes selected; returns `false` after the timeout. |

All four methods use `XCEasyConfig.actionTimeout` by default, resolve the element again against the current accessibility tree on every poll, and never create an XCTest failure. Their result is marked `@discardableResult`: a test may ignore it and continue after timeout, although handling the `Bool` is usually clearer for optional UI. An unsuccessful wait remains available in structured diagnostics rather than being disguised as a successful lookup. `waitForEnabled` and `waitForSelected` require the element to exist; absence never counts as enabled or selected.

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

## Complete in-test example

```swift
final class ElementApiTests: BaseTestCase {
    func testLookupActionsReadsAndState() {
        let byId = find(identifier: "submitButton", desc: "Submit", timeout: 5)
        let byText = find(text: "Log in")
        let byPredicate = find(format: "label BEGINSWITH 'Welc'")
        let typedById = find(type: .button, identifier: "submitButton")
        let typedByText = find(type: .staticText, text: "Home")
        let typedByPredicate = find(type: .cell, format: "identifier BEGINSWITH 'product'")
        let typedByIndex = find(type: .cell, index: 2)

        let list = find(identifier: "productList")
        let childById = list.child(identifier: "productCard", index: 0)
        let childByText = list.child(text: "Product")
        let childByPredicate = list.child(format: "label CONTAINS '$'")
        let typedChildById = list.child(type: .button, identifier: "buyButton")
        let typedChildByText = list.child(type: .staticText, text: "Price")
        let typedChildByPredicate = list.child(type: .cell, format: "isEnabled == true")

        byId.tap().doubleTap().press(forDuration: 0.5)
        list.swipe(.up)
        find(identifier: "searchField").clearField().typeText("iPhone")

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

A production test does not need every form at once; this example is a signature catalog. `desc` replaces the technical locator in human-readable steps. `index` is zero-based and should be used only when order is part of the UI contract.

## Log and report output

Operations create separate timed steps, while fresh lookup remains nested diagnostic evidence:

```text
Tap element [Submit]                       ui.tap          passed
  UI query                                  ui.query        passed
Double tap element [Submit]                ui.double_tap   passed
Swipe up [productList]                     ui.swipe.up     passed
Clear text field                           ui.clear_text   passed
Type text into element [searchField]       ui.type_text    passed
```

Entered text and read `label`/`value` are not included in action titles. Boolean methods and waits create no XCTest failure, but query evidence and timing explain why they returned `false`.
