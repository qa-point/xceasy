/// Records a Given precondition as a nested Allure step.
///
/// - Parameters:
///   - name: Human-readable precondition without the `GIVEN` prefix.
///   - actionStep: Work performed to establish the precondition.
///
/// ```swift
/// given("the user is authenticated") {
///     loginScreen.login()
/// }
/// ```
public func given(_ name: String, actionStep: () -> Void) {
    step("GIVEN: \(name)", block: actionStep)
}

/// Records a When action as a nested Allure step.
///
/// - Parameters:
///   - name: Human-readable action without the `WHEN` prefix.
///   - actionStep: Work performed by the user or system.
public func when(_ name: String, actionStep: () -> Void) {
    step("WHEN: \(name)", block: actionStep)
}

/// Records a Then outcome as a nested Allure step.
///
/// - Parameters:
///   - name: Human-readable expected outcome without the `THEN` prefix.
///   - actionStep: Assertions that verify the observable outcome.
public func then(_ name: String, actionStep: () -> Void) {
    step("THEN: \(name)", block: actionStep)
}

/// Appends another condition or action to the current Given/When/Then flow.
///
/// - Parameters:
///   - name: Human-readable continuation without the `AND` prefix.
///   - actionStep: Work recorded inside the continuation step.
public func and(_ name: String, actionStep: () -> Void) {
    step("AND: \(name)", block: actionStep)
}

/// Records an async Given precondition and preserves execution context across suspension.
///
/// - Parameters:
///   - name: Human-readable precondition without the `GIVEN` prefix.
///   - actionStep: Async work used to establish the precondition.
/// - Returns: Value returned by `actionStep`.
/// - Throws: Rethrows an error from `actionStep`.
@available(iOS 15.0, *)
@discardableResult
public func given<T>(_ name: String, actionStep: () async throws -> T) async rethrows -> T {
    try await step("GIVEN: \(name)", block: actionStep)
}

/// Records an async When action and preserves execution context across suspension.
///
/// - Parameters:
///   - name: Human-readable action without the `WHEN` prefix.
///   - actionStep: Async user or system work.
/// - Returns: Value returned by `actionStep`.
/// - Throws: Rethrows an error from `actionStep`.
@available(iOS 15.0, *)
@discardableResult
public func when<T>(_ name: String, actionStep: () async throws -> T) async rethrows -> T {
    try await step("WHEN: \(name)", block: actionStep)
}

/// Records an async Then outcome and preserves execution context across suspension.
///
/// - Parameters:
///   - name: Human-readable expected outcome without the `THEN` prefix.
///   - actionStep: Async assertions for the observable outcome.
/// - Returns: Value returned by `actionStep`.
/// - Throws: Rethrows an error from `actionStep`.
@available(iOS 15.0, *)
@discardableResult
public func then<T>(_ name: String, actionStep: () async throws -> T) async rethrows -> T {
    try await step("THEN: \(name)", block: actionStep)
}

/// Records an async continuation in a Given/When/Then flow.
///
/// - Parameters:
///   - name: Human-readable continuation without the `AND` prefix.
///   - actionStep: Async continuation work.
/// - Returns: Value returned by `actionStep`.
/// - Throws: Rethrows an error from `actionStep`.
@available(iOS 15.0, *)
@discardableResult
public func and<T>(_ name: String, actionStep: () async throws -> T) async rethrows -> T {
    try await step("AND: \(name)", block: actionStep)
}
