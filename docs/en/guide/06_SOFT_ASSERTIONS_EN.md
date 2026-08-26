# Soft assertions

English · [Русский](../../ru/guide/06_SOFT_ASSERTIONS_RU.md) · [Contents](../PRODUCT_GUIDE_EN.md) · [Short README](../../../README.md)


Use `softly` when several independent checks should run once and report every mismatch. The block uses regular XCEasy assertions; there is no separate `check` object or `expect...` API:

```swift
softly("Verify home screen") {
    homeScreen.navbar.assertIsDisplayed()
    homeScreen.tabbar.assertIsDisplayed()
    homeScreen.cards.get(index: 1).assertIsDisplayed()
    assertEqual(actual: homeScreen.title.getLabel(), expected: "Home")
}
```

The following assertions automatically adopt soft behavior:

| Checks inside `softly` | Behavior |
|---|---|---|
| All value assertions, including `assertTrue`, `assertEqual`, `assertLessThan`, and `assertNotNil` | A mismatch is recorded and the next statement runs. |
| `XCEasyUIElement` and `XCEasyComponent` assertions | Their normal localized step, locator, UI evidence, and timeout are preserved. |
| `XCEasyComponentCollection` assertions | Count, empty-state, and displayed mismatches are accumulated. |

Every mismatched assertion remains an individual failed Allure step with its own diagnostics. The owning `softly` step is failed as well. After the block finishes, XCTest receives one aggregate issue with a bounded list of redacted failures and original source lines. An async overload, `await softly("...") { ... }`, preserves execution context across suspension.

Only assertions become soft. Taps, text entry, network work, configuration errors, and other framework failures remain hard. Do not put a dependent scenario inside this block: if login must succeed before work may continue, check it with a regular assertion outside `softly`.

```text
Verify home screen                        failed
  Assert navbar is displayed              passed
  Assert tab bar is displayed             failed
  Assert card 1 is displayed              failed
  Assert title equals expected            passed
```

After the block, XCTest receives one aggregate failure, so teardown and artifacts for the current execution are preserved normally.
