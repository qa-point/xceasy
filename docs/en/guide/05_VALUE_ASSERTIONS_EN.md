# Value assertions

English · [Русский](../../ru/guide/05_VALUE_ASSERTIONS_RU.md) · [Contents](../PRODUCT_GUIDE_EN.md) · [Short README](../../../README.md)


XCEasy provides the common hard assertions. Expressions are evaluated once, and values are redacted before logging.

```swift
final class ValueAssertionTests: BaseTestCase {
    private enum ParseError: Error { case invalidInteger }

    private func parseInteger(_ text: String) throws -> Int {
        guard let value = Int(text) else { throw ParseError.invalidInteger }
        return value
    }

    func testProfileResponse() {
        let productIds = ["product-42", "product-77"]
        let roles = ["premium", "buyer"]
        let optionalError: Error? = nil
        let currentUser: String? = "Alex"
        let validationErrors: [String] = []

        assertTrue(expression: !productIds.isEmpty, label: "products loaded")
        assertFalse(expression: roles.contains("blocked"), label: "no blocked role")
        assertEqual(actual: 200, expected: 200)
        assertNotEqual(actual: "premium", expected: "guest")
        assertGreaterThan(actual: productIds.count, expected: 0)
        assertGreaterThanOrEqual(actual: 0.75, expected: 0.5)
        assertLessThan(actual: 1.2, expected: 2.0)
        assertLessThanOrEqual(actual: 2, expected: 3)
        assertContains(string: "status=success", substring: "success")
        assertDoesNotContain(string: "status=success", substring: "error")
        assertContains(collection: productIds, element: "product-42")
        assertDoesNotContain(collection: roles, element: "blocked")
        assertNil(actual: optionalError)
        assertNotNil(actual: currentUser)
        assertEmpty(actual: validationErrors)
        assertNotEmpty(actual: productIds)
        assertThrows("invalid integer") { try parseInteger("abc") }
        let value = assertDoesNotThrow("valid integer") { try parseInteger("42") }
        assertEqual(actual: value, expected: 42)
    }
}
```

A hard assertion marks the test as failed as soon as its condition is not met.

`actual`, `expected`, and Boolean expressions are evaluated exactly once. `assertDoesNotThrow` returns `T?`: it contains the result on success and is `nil` when the closure throws. `assertThrows` checks only that an error occurred. `fail("Reason")` records an explicit failure for a branch that has no specialized assertion.

Every check creates a localized step and a stable assertion event:

```text
Assert [200] equals [200]                     passed
Assert [2] is greater than [0]                passed
Assert contains [product-42]                  passed
Assert [valid integer] does not throw         passed
```

Values pass through redaction, but do not put secrets in `label`: a condition name should describe intent rather than user data.
