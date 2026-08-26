# Обычные проверки значений

Русский · [English](../../en/guide/05_VALUE_ASSERTIONS_EN.md) · [Оглавление](../PRODUCT_GUIDE_RU.md) · [Краткий README](../../../README_RU.md)


XCEasy содержит основные hard assertions. Выражения вычисляются один раз, значения редактируются перед записью в лог.

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

Hard assertion сразу отмечает тест как failed, если условие не выполнено.

`actual`, `expected` и Boolean expression вычисляются ровно один раз. `assertDoesNotThrow` возвращает `T?`: результат есть при успехе и равен `nil`, если closure бросил ошибку. `assertThrows` проверяет только сам факт ошибки. `fail("Причина")` создаёт явный failure для ветки, которую нельзя выразить специализированным assertion.

Каждая проверка создаёт локализованный step и стабильный assertion event:

```text
Проверить равенство [200] и [200]              passed
Проверить, что [2] больше [0]                  passed
Проверить наличие [product-42]                 passed
Проверить, что [valid integer] не бросает      passed
```

Значения проходят redaction, но не передавайте secret как `label`: понятное имя условия должно описывать смысл, а не содержать данные пользователя.
