/// Pure predicates shared by hard/soft assertion APIs and their unit tests.
internal enum XCEasyAssertionPredicate {
    /// Returns whether two equatable values are equal.
    static func equal<T: Equatable>(_ actual: T, _ expected: T) -> Bool {
        actual == expected
    }

    /// Returns whether two equatable values differ.
    static func notEqual<T: Equatable>(_ actual: T, _ expected: T) -> Bool {
        actual != expected
    }

    /// Returns whether `actual` is strictly greater than `expected`.
    static func greaterThan<T: Comparable>(_ actual: T, _ expected: T) -> Bool {
        actual > expected
    }

    /// Returns whether `actual` is greater than or equal to `expected`.
    static func greaterThanOrEqual<T: Comparable>(_ actual: T, _ expected: T) -> Bool {
        actual >= expected
    }

    /// Returns whether `actual` is strictly less than `expected`.
    static func lessThan<T: Comparable>(_ actual: T, _ expected: T) -> Bool {
        actual < expected
    }

    /// Returns whether `actual` is less than or equal to `expected`.
    static func lessThanOrEqual<T: Comparable>(_ actual: T, _ expected: T) -> Bool {
        actual <= expected
    }

    /// Returns whether a string contains the requested substring.
    static func contains(_ string: String, _ substring: String) -> Bool {
        string.contains(substring)
    }

    /// Returns whether a string excludes the requested substring.
    static func doesNotContain(_ string: String, _ substring: String) -> Bool {
        !string.contains(substring)
    }

    /// Returns whether a collection contains the requested element.
    static func contains<C: Collection>(_ collection: C, _ element: C.Element) -> Bool where C.Element: Equatable {
        collection.contains(element)
    }

    /// Returns whether a collection excludes the requested element.
    static func doesNotContain<C: Collection>(_ collection: C, _ element: C.Element) -> Bool where C.Element: Equatable {
        !collection.contains(element)
    }

    /// Returns whether an optional has no value.
    static func isNil<T>(_ value: T?) -> Bool {
        value == nil
    }

    /// Returns whether an optional contains a value.
    static func isNotNil<T>(_ value: T?) -> Bool {
        value != nil
    }

    /// Returns whether a collection has no elements.
    static func isEmpty<C: Collection>(_ collection: C) -> Bool {
        collection.isEmpty
    }

    /// Returns whether a collection contains at least one element.
    static func isNotEmpty<C: Collection>(_ collection: C) -> Bool {
        !collection.isEmpty
    }
}
