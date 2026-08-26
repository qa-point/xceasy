# Page Object components

English · [Русский](../../ru/guide/07_PAGE_OBJECT_COMPONENTS_RU.md) · [Contents](../PRODUCT_GUIDE_EN.md) · [Short README](../../../README.md)


A component groups its primary UI element and children. The same Page Object can be reused on different screens.

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
        step("Dismiss") {
            closeButton.tap()
        }
        return self
    }
}
```

When no explicit name is needed, omit `componentName` entirely and the protocol uses the concrete type name, `PromoBanner`. Add the stored property and initializer only when identical instances should be distinguishable in a report:

```swift
let topBanner = PromoBanner(componentName: "Top promo banner")
let bottomBanner = PromoBanner(componentName: "Bottom promo banner")
```

Allure then contains `Top promo banner: Dismiss` and `Bottom promo banner: Dismiss`. Canonical JSONL stores the same operations with code `component.step`, a separate `target` instance name, and the complete `element` locator. AI tooling therefore does not need to infer component context from localized prose.

## Validating a component and its children

`XCEasyComponent` deliberately requires only `element`. Component assertions validate only that primary element, so their meaning does not depend on a hidden child list:

| Call | What is validated |
|---|---|
| `banner.assertExists()` | Only the presence of `element` in the accessibility tree. |
| `banner.assertIsDisplayed()` | Only display of `element`. |
| `banner.assertDoesNotExist()` | Only absence of `element`; children are no longer checked. |
| `banner.assertIsNotDisplayed()` / `assertIsHidden()` / `assertIsHittable()` | The corresponding state of `element`. |
| `banner.waitForDisplayed()` / `waitForHittable()` / `waitForEnabled()` / `waitForSelected()` | Non-asserting wait for the corresponding `element` state; returns `Bool`. |

An action waits for its required state itself. For example, `banner.closeButton.tap()` waits for `.hittable` by default, so a separate readiness descriptor is unnecessary. When a business test must independently prove full component readiness, give that contract an explicit POM method:

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

let banner = PromoBanner(componentName: "Catalog promo banner")
banner.assertIsReady().dismiss()
```

## `step` inside a POM

A component does not add another command to remember. The same `step` call used inside a POM method automatically adds `componentName` and the `element` locator. It works for actions, assertions, value reads, and sync or async closures. It uses the same lifecycle and stack as the global `step`, so nesting is preserved:

```swift
extension PromoBanner {
    @discardableResult
    func assertTitle(_ expectedTitle: String) -> Self {
        step("Check title") {
            title.assertLabel(value: expectedTitle)
        }
        return self
    }
}

let banner = PromoBanner(componentName: "Catalog promo banner")

step("Check catalog") {
    banner.assertTitle("Special offer")
}
```

The test now uses the domain method `assertTitle`, while the child element and its validation details stay inside the POM. The Allure tree is `Check catalog` → `Catalog promo banner: Check title` → assertion. An error or `await` does not flatten the inner operation into a sibling top-level step.

## What `XCEasyComponentCollection` is

It is a lazy, UI-aware set of repeated Page Object components such as product cards, table rows, messages, or cells. A component declares the common locator once; the collection provides clear getters, waits, and assertions for its current state.

```swift
struct ProductCard: XCEasyIndexedComponent {
    static var collection: XCEasyUIElement {
        find(type: .cell, identifier: "productCard", desc: "Product cards")
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
cards.get(index: 2, componentName: "Recommended product").title.assertExists()

for card in cards.get(indices: 0..<3) {
    card.assertExists()
}
```

When `componentName` is omitted, the framework derives a position-aware name without querying UI: `First ProductCard`, `Last ProductCard`, or `ProductCard at index 2`. Pass `componentName` only when the instance has a more useful domain meaning, such as `Recommended product`.

`collection` must match every component instance rather than only the first. The `element` property selects one instance from it through `.first`, `.last`, or `.index(Int)` position. `element(at:)` does not query immediately; it creates a lazy locator. A retained `cards.last` therefore recalculates the last current match for every action or assertion and stays correct after cards are inserted or removed.

Available getters:

| Call | Result |
|---|---|
| `cards.first` | Lazy POM for the first current match. |
| `cards.last` | Lazy POM for the last current match; no index is cached. |
| `cards.get(index: 2)` | Lazy POM for a zero-based index. |
| `cards.get(index: 2, componentName: "...")` | The same locator with a report-specific instance name. |
| `cards.get(indices: 0..<3)` | Lazy POM array for indices `0`, `1`, and `2`; creation does not read the UI. |

A negative index never traps inside XCUI. The locator retains invalid intent and its semantic use finishes with `query.invalid_index`. Using `last` against an empty collection similarly reports `query.collection_empty` instead of addressing index `-1`.

Explicit collection waits and assertions:

| Call | Behavior |
|---|---|
| `cards.assertCount(3)` | Fails unless the current match count is exactly 3. |
| `cards.assertCount(atLeast: 2)` | Fails when fewer than 2 matches exist. |
| `cards.assertCount(atMost: 5)` | Fails when more than 5 matches exist. |
| `cards.assertIsEmpty()` | Requires all matching containers to be absent. |
| `cards.assertIsNotEmpty()` | Requires at least one matching container. |
| `cards.waitForCount(3)` | Waits for exactly 3 and returns `Bool` without failing on timeout. |
| `cards.waitForCount(atLeast: 2)` | Waits for the inclusive lower bound and returns `Bool`. |
| `cards.waitForCount(atMost: 5)` | Waits for the inclusive upper bound and returns `Bool`. |
| `cards.assertAllDisplayed()` | Requires a nonempty collection and every current match to be displayed. |
| `cards.waitForAllDisplayed()` | Waits for the same state and returns `Bool` without assertion failure. |

Every polling attempt reads the current accessibility tree again. Public getters, waits, and assertions automatically create localized Allure steps. Canonical `ui.collection.started`/`ui.collection.finished` events separately retain the operation code, locator, expected and actual count, attempts, duration, displayed count, failing indices, and a bounded timeline. The readable log mirrors the important fields, making the outcome diagnosable by both humans and AI tooling. `init()` has no step: collection construction remains safe before test lifecycle startup and never reads the UI.
