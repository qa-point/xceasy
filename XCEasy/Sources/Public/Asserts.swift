import XCTest

/// Records an explicit test failure using the current framework localization.
///
/// - Parameters:
///   - message: Human-readable failure message or localization key.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func fail(
    _ message: String = "Test failed",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let localizedMessage = LocalizationManager.shared.string(forKey: message)
    let safeMessage = SensitiveDataRedactor.redact(localizedMessage)
    XCEasyTestLogger.shared.log(safeMessage, level: .error)
    recordAssertionFailure(safeMessage, file: file, line: line)
}

/// Asserts that a Boolean expression is `true`.
///
/// - Parameters:
///   - expression: Expression evaluated exactly once.
///   - label: Optional human-readable name of the checked condition.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertTrue(
    expression: @autoclosure () throws -> Bool,
    label: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    evaluateAssertion(
        titleKey: "assert_true_title",
        errorKey: "assert_true_error",
        arguments: [safeAssertionDescription(label ?? defaultAssertionLabel())],
        file: file,
        line: line
    ) {
        try expression()
    }
}

/// Asserts that a Boolean expression is `false`.
///
/// - Parameters:
///   - expression: Expression evaluated exactly once.
///   - label: Optional human-readable name of the checked condition.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertFalse(
    expression: @autoclosure () throws -> Bool,
    label: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    evaluateAssertion(
        titleKey: "assert_false_title",
        errorKey: "assert_false_error",
        arguments: [safeAssertionDescription(label ?? defaultAssertionLabel())],
        file: file,
        line: line
    ) {
        !(try expression())
    }
}

/// Asserts that two values are equal.
///
/// - Parameters:
///   - actual: Actual value evaluated exactly once.
///   - expected: Expected value evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertEqual<T: Equatable>(
    actual: @autoclosure () throws -> T,
    expected: @autoclosure () throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    evaluateValues(actual: actual, expected: expected, file: file, line: line) { actualValue, expectedValue in
        (
            XCEasyAssertionPredicate.equal(actualValue, expectedValue),
            "assert_equals_title",
            "assert_equals_error"
        )
    }
}

/// Asserts that two values are different.
///
/// - Parameters:
///   - actual: Actual value evaluated exactly once.
///   - expected: Value that must not equal `actual`, evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertNotEqual<T: Equatable>(
    actual: @autoclosure () throws -> T,
    expected: @autoclosure () throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    evaluateValues(actual: actual, expected: expected, file: file, line: line) { actualValue, expectedValue in
        (
            XCEasyAssertionPredicate.notEqual(actualValue, expectedValue),
            "assert_not_equals_title",
            "assert_not_equals_error"
        )
    }
}

/// Asserts that `actual` is strictly greater than `expected`.
///
/// - Parameters:
///   - actual: Actual comparable value evaluated exactly once.
///   - expected: Exclusive lower bound evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertGreaterThan<T: Comparable>(
    actual: @autoclosure () throws -> T,
    expected: @autoclosure () throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    evaluateValues(actual: actual, expected: expected, file: file, line: line) { actualValue, expectedValue in
        (
            XCEasyAssertionPredicate.greaterThan(actualValue, expectedValue),
            "assert_greater_than_title",
            "assert_greater_than_error"
        )
    }
}

/// Asserts that `actual` is greater than or equal to `expected`.
///
/// - Parameters:
///   - actual: Actual comparable value evaluated exactly once.
///   - expected: Inclusive lower bound evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertGreaterThanOrEqual<T: Comparable>(
    actual: @autoclosure () throws -> T,
    expected: @autoclosure () throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    evaluateValues(actual: actual, expected: expected, file: file, line: line) { actualValue, expectedValue in
        (
            XCEasyAssertionPredicate.greaterThanOrEqual(actualValue, expectedValue),
            "assert_greater_or_equal_title",
            "assert_greater_or_equal_error"
        )
    }
}

/// Asserts that `actual` is strictly less than `expected`.
///
/// - Parameters:
///   - actual: Actual comparable value evaluated exactly once.
///   - expected: Exclusive upper bound evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertLessThan<T: Comparable>(
    actual: @autoclosure () throws -> T,
    expected: @autoclosure () throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    evaluateValues(actual: actual, expected: expected, file: file, line: line) { actualValue, expectedValue in
        (
            XCEasyAssertionPredicate.lessThan(actualValue, expectedValue),
            "assert_less_than_title",
            "assert_less_than_error"
        )
    }
}

/// Asserts that `actual` is less than or equal to `expected`.
///
/// - Parameters:
///   - actual: Actual comparable value evaluated exactly once.
///   - expected: Inclusive upper bound evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertLessThanOrEqual<T: Comparable>(
    actual: @autoclosure () throws -> T,
    expected: @autoclosure () throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    evaluateValues(actual: actual, expected: expected, file: file, line: line) { actualValue, expectedValue in
        (
            XCEasyAssertionPredicate.lessThanOrEqual(actualValue, expectedValue),
            "assert_less_or_equal_title",
            "assert_less_or_equal_error"
        )
    }
}

/// Asserts that a string contains a substring.
///
/// - Parameters:
///   - string: Source string evaluated exactly once.
///   - substring: Required substring evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertContains(
    string: @autoclosure () throws -> String,
    substring: @autoclosure () throws -> String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    evaluateValues(actual: string, expected: substring, file: file, line: line) { value, member in
        (
            XCEasyAssertionPredicate.contains(value, member),
            "assert_contains_title",
            "assert_contains_error"
        )
    }
}

/// Asserts that a string does not contain a substring.
///
/// - Parameters:
///   - string: Source string evaluated exactly once.
///   - substring: Forbidden substring evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertDoesNotContain(
    string: @autoclosure () throws -> String,
    substring: @autoclosure () throws -> String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    evaluateValues(actual: string, expected: substring, file: file, line: line) { value, member in
        (
            XCEasyAssertionPredicate.doesNotContain(value, member),
            "assert_not_contains_title",
            "assert_not_contains_error"
        )
    }
}

/// Asserts that a collection contains an element.
///
/// - Parameters:
///   - collection: Source collection evaluated exactly once.
///   - element: Required element evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertContains<C: Collection>(
    collection: @autoclosure () throws -> C,
    element: @autoclosure () throws -> C.Element,
    file: StaticString = #filePath,
    line: UInt = #line
) where C.Element: Equatable {
    evaluateValues(actual: collection, expected: element, file: file, line: line) { value, member in
        (
            XCEasyAssertionPredicate.contains(value, member),
            "assert_contains_title",
            "assert_contains_error"
        )
    }
}

/// Asserts that a collection does not contain an element.
///
/// - Parameters:
///   - collection: Source collection evaluated exactly once.
///   - element: Forbidden element evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertDoesNotContain<C: Collection>(
    collection: @autoclosure () throws -> C,
    element: @autoclosure () throws -> C.Element,
    file: StaticString = #filePath,
    line: UInt = #line
) where C.Element: Equatable {
    evaluateValues(actual: collection, expected: element, file: file, line: line) { value, member in
        (
            XCEasyAssertionPredicate.doesNotContain(value, member),
            "assert_not_contains_title",
            "assert_not_contains_error"
        )
    }
}

/// Asserts that an optional value is `nil`.
///
/// - Parameters:
///   - actual: Optional evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertNil<T>(
    actual: @autoclosure () throws -> T?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    evaluateSingleValue(
        actual: actual,
        titleKey: "assert_nil_title",
        errorKey: "assert_nil_error",
        file: file,
        line: line
    ) { value in
        XCEasyAssertionPredicate.isNil(value)
    }
}

/// Asserts that an optional value is not `nil`.
///
/// - Parameters:
///   - actual: Optional evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertNotNil<T>(
    actual: @autoclosure () throws -> T?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    evaluateSingleValue(
        actual: actual,
        titleKey: "assert_not_nil_title",
        errorKey: "assert_not_nil_error",
        file: file,
        line: line
    ) { value in
        XCEasyAssertionPredicate.isNotNil(value)
    }
}

/// Asserts that a collection has no elements.
///
/// - Parameters:
///   - actual: Collection evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertEmpty<C: Collection>(
    actual: @autoclosure () throws -> C,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    evaluateSingleValue(
        actual: actual,
        titleKey: "assert_empty_title",
        errorKey: "assert_empty_error",
        file: file,
        line: line
    ) { value in
        XCEasyAssertionPredicate.isEmpty(value)
    }
}

/// Asserts that a collection contains at least one element.
///
/// - Parameters:
///   - actual: Collection evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertNotEmpty<C: Collection>(
    actual: @autoclosure () throws -> C,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    evaluateSingleValue(
        actual: actual,
        titleKey: "assert_not_empty_title",
        errorKey: "assert_not_empty_error",
        file: file,
        line: line
    ) { value in
        XCEasyAssertionPredicate.isNotEmpty(value)
    }
}

/// Asserts that a closure throws an error.
///
/// - Parameters:
///   - label: Optional human-readable name of the operation.
///   - expression: Throwing closure evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
public func assertThrows<T>(
    _ label: String? = nil,
    expression: () throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    var didThrow = false
    do {
        _ = try expression()
    } catch {
        didThrow = true
    }
    performAssertion(
        condition: didThrow,
        titleKey: "assert_throws_title",
        errorKey: "assert_throws_error",
        arguments: [safeAssertionDescription(label ?? defaultAssertionLabel())],
        file: file,
        line: line
    )
}

/// Asserts that a closure completes without throwing and returns its value when successful.
///
/// - Parameters:
///   - label: Optional human-readable name of the operation.
///   - expression: Throwing closure evaluated exactly once.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
/// - Returns: Closure result, or `nil` when the closure threw.
@discardableResult
public func assertDoesNotThrow<T>(
    _ label: String? = nil,
    expression: () throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) -> T? {
    var result: T?
    var didThrow = false
    do {
        result = try expression()
    } catch {
        didThrow = true
    }
    performAssertion(
        condition: !didThrow,
        titleKey: "assert_does_not_throw_title",
        errorKey: "assert_does_not_throw_error",
        arguments: [safeAssertionDescription(label ?? defaultAssertionLabel())],
        file: file,
        line: line
    )
    return result
}

/// Resolves the localized default label at call time so parallel locales remain isolated.
///
/// - Returns: Current execution's localized default assertion label.
private func defaultAssertionLabel() -> String {
    LocalizationManager.shared.string(forKey: "asserts_default_element_title")
}

/// Converts a value into a redacted string before it reaches logs or report steps.
///
/// - Parameter value: Value whose description must be safe for diagnostics.
/// - Returns: Redacted description.
private func safeAssertionDescription<T>(_ value: T) -> String {
    SensitiveDataRedactor.redact(String(describing: value))
}

/// Evaluates one throwing Boolean predicate and reports its result.
///
/// - Parameters:
///   - titleKey: Localization key for a successful/checking step.
///   - errorKey: Localization key for a failure message.
///   - arguments: Redacted interpolation values.
///   - file: Call-site file.
///   - line: Call-site line.
///   - predicate: Predicate evaluated exactly once.
private func evaluateAssertion(
    titleKey: String,
    errorKey: String,
    arguments: [CVarArg],
    file: StaticString,
    line: UInt,
    predicate: () throws -> Bool
) {
    do {
        performAssertion(
            condition: try predicate(),
            titleKey: titleKey,
            errorKey: errorKey,
            arguments: arguments,
            expected: "true",
            actual: "false",
            file: file,
            line: line
        )
    } catch {
        let safeError = SensitiveDataRedactor.redact(String(describing: error))
        fail("Assertion evaluation threw: \(safeError)", file: file, line: line)
    }
}

/// Evaluates two values once and reports a typed comparison.
///
/// - Parameters:
///   - actual: Actual-value closure.
///   - expected: Expected-value closure.
///   - file: Call-site file.
///   - line: Call-site line.
///   - predicate: Comparison returning its condition and localization keys.
private func evaluateValues<Actual, Expected>(
    actual: () throws -> Actual,
    expected: () throws -> Expected,
    file: StaticString,
    line: UInt,
    predicate: (Actual, Expected) -> (Bool, String, String)
) {
    do {
        let actualValue = try actual()
        let expectedValue = try expected()
        let evaluation = predicate(actualValue, expectedValue)
        let safeActual = safeAssertionDescription(actualValue)
        let safeExpected = safeAssertionDescription(expectedValue)
        performAssertion(
            condition: evaluation.0,
            titleKey: evaluation.1,
            errorKey: evaluation.2,
            arguments: [safeActual, safeExpected],
            expected: safeExpected,
            actual: safeActual,
            file: file,
            line: line
        )
    } catch {
        let safeError = SensitiveDataRedactor.redact(String(describing: error))
        fail("Assertion evaluation threw: \(safeError)", file: file, line: line)
    }
}

/// Evaluates one value once and reports a typed predicate.
///
/// - Parameters:
///   - actual: Value closure.
///   - titleKey: Localization key for the checking step.
///   - errorKey: Localization key for the failure.
///   - file: Call-site file.
///   - line: Call-site line.
///   - predicate: Predicate applied to the value.
private func evaluateSingleValue<T>(
    actual: () throws -> T,
    titleKey: String,
    errorKey: String,
    file: StaticString,
    line: UInt,
    predicate: (T) -> Bool
) {
    do {
        let value = try actual()
        let safeValue = safeAssertionDescription(value)
        performAssertion(
            condition: predicate(value),
            titleKey: titleKey,
            errorKey: errorKey,
            arguments: [safeValue],
            expected: nil,
            actual: safeValue,
            file: file,
            line: line
        )
    } catch {
        let safeError = SensitiveDataRedactor.redact(String(describing: error))
        fail("Assertion evaluation threw: \(safeError)", file: file, line: line)
    }
}

/// Creates the localized Allure step and XCTest issue for one assertion result.
///
/// - Parameters:
///   - condition: Whether the assertion passed.
///   - titleKey: Localization key for the step title.
///   - errorKey: Localization key for the failure text.
///   - arguments: Redacted interpolation values.
///   - file: Call-site file.
///   - line: Call-site line.
private func performAssertion(
    condition: Bool,
    titleKey: String,
    errorKey: String,
    arguments: [CVarArg],
    expected: String? = nil,
    actual: String? = nil,
    file: StaticString,
    line: UInt
) {
    let title = LocalizationManager.shared.string(forKey: titleKey, arguments: arguments)
    let errorMessage = LocalizationManager.shared.string(forKey: errorKey, arguments: arguments)
    step(title) {
        XCEasyTestLogger.shared.log("assertion evaluated: \(condition ? "passed" : "failed")")
        guard condition else {
            XCEasyTestLogger.shared.log(errorMessage, level: .error)
            recordAssertionFailure(
                errorMessage,
                expected: expected,
                actual: actual,
                file: file,
                line: line
            )
            return
        }
        XCEasyTestLogger.shared.log("assertion passed")
    }
}
