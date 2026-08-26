import Foundation

/// Executes work inside correlated diagnostic and Allure operation steps.
///
/// - Parameters:
///   - code: Stable semantic operation code.
///   - title: Localized human-readable step title.
///   - target: Optional redacted operation target.
///   - block: Work whose value and thrown error are preserved.
/// - Returns: Value returned by `block`.
/// - Throws: Rethrows errors from `block` after recording failed timing evidence.
@discardableResult
internal func operationStep<T>(
    code: String,
    title: String,
    target: String? = nil,
    block: () throws -> T
) rethrows -> T {
    try operationStepWithContext(code: code, title: title, target: target) { _ in
        try block()
    }
}

/// Executes work with access to the generated operation identifier.
///
/// - Parameters:
///   - code: Stable semantic operation code.
///   - title: Localized human-readable step title.
///   - target: Optional redacted operation target.
///   - block: Work receiving the operation ID used to parent nested queries.
/// - Returns: Value returned by `block`.
/// - Throws: Rethrows errors from `block` after recording failed timing evidence.
@discardableResult
internal func operationStepWithContext<T>(
    code: String,
    title: String,
    target: String? = nil,
    block: (_ operationId: String) throws -> T
) rethrows -> T {
    let operationId = UUID().uuidString.lowercased()
    let started = DispatchTime.now().uptimeNanoseconds
    XCEasyTestLogger.shared.event(DiagnosticEvent(
        event: "operation.started",
        testId: XCEasyTestContext.shared.testId,
        operationCode: code,
        operationId: operationId,
        statusCode: "running",
        target: target,
        title: title,
        monotonicNanoseconds: started
    ))

    do {
        let result = try step(title) { try block(operationId) }
        let duration = elapsedMilliseconds(since: started)
        XCEasyTestLogger.shared.event(DiagnosticEvent(
            event: "operation.finished",
            testId: XCEasyTestContext.shared.testId,
            operationCode: code,
            operationId: operationId,
            statusCode: "passed",
            durationMilliseconds: duration,
            target: target,
            title: title,
            performance: diagnosticPerformanceEvidence(
                operationKey: code,
                durationMilliseconds: duration
            )
        ))
        enforcePerformanceBudget(
            operationKey: code,
            durationMilliseconds: duration,
            parentOperationId: operationId
        )
        return result
    } catch {
        let duration = elapsedMilliseconds(since: started)
        XCEasyTestLogger.shared.event(DiagnosticEvent(
            event: "operation.finished",
            level: "error",
            testId: XCEasyTestContext.shared.testId,
            operationCode: code,
            operationId: operationId,
            statusCode: "failed",
            reasonCode: "thrown_error",
            durationMilliseconds: duration,
            target: target,
            title: title,
            performance: diagnosticPerformanceEvidence(
                operationKey: code,
                durationMilliseconds: duration
            )
        ))
        throw error
    }
}

/// Computes a saturating monotonic duration.
///
/// - Parameter start: Monotonic start timestamp in nanoseconds.
/// - Returns: Nonnegative elapsed milliseconds capped at `Int64.max`.
private func elapsedMilliseconds(since start: UInt64) -> Int64 {
    let now = DispatchTime.now().uptimeNanoseconds
    let elapsed = now >= start ? now - start : 0
    return Int64(min(elapsed / 1_000_000, UInt64(Int64.max)))
}

/// Evaluates a Boolean assertion inside correlated diagnostics and an Allure step.
///
/// - Parameters:
///   - code: Stable semantic assertion code.
///   - title: Localized human-readable assertion title.
///   - target: Optional redacted assertion target.
///   - reasonCode: Failure reason emitted when the predicate does not match.
///   - evaluate: Predicate that returns the observed assertion outcome.
internal func operationAssertion(
    code: String,
    title: String,
    target: String? = nil,
    reasonCode: String = "predicate_not_matched",
    evaluate: () -> Bool
) {
    operationAssertionWithContext(
        code: code,
        title: title,
        target: target,
        reasonCode: reasonCode
    ) { _ in evaluate() }
}

/// Evaluates an assertion with access to the parent operation identifier.
///
/// - Parameters:
///   - code: Stable semantic assertion code.
///   - title: Localized human-readable assertion title.
///   - target: Optional redacted assertion target.
///   - reasonCode: Failure reason emitted when the predicate does not match.
///   - evaluate: Predicate receiving the ID used to parent nested queries.
internal func operationAssertionWithContext(
    code: String,
    title: String,
    target: String? = nil,
    reasonCode: String = "predicate_not_matched",
    evaluate: (_ operationId: String) -> Bool
) {
    let operationId = UUID().uuidString.lowercased()
    let started = DispatchTime.now().uptimeNanoseconds
    XCEasyTestLogger.shared.event(DiagnosticEvent(
        event: "operation.started",
        testId: XCEasyTestContext.shared.testId,
        operationCode: code,
        operationId: operationId,
        statusCode: "running",
        target: target,
        title: title,
        monotonicNanoseconds: started
    ))
    let matched = evaluate(operationId)
    let duration = elapsedMilliseconds(since: started)
    XCEasyTestLogger.shared.event(DiagnosticEvent(
        event: "operation.finished",
        level: matched ? "info" : "error",
        testId: XCEasyTestContext.shared.testId,
        operationCode: code,
        operationId: operationId,
        statusCode: matched ? "passed" : "failed",
        reasonCode: matched ? "predicate_matched" : reasonCode,
        durationMilliseconds: duration,
        target: target,
        title: title,
        performance: diagnosticPerformanceEvidence(
            operationKey: code,
            durationMilliseconds: duration
        )
    ))
    enforcePerformanceBudget(
        operationKey: code,
        durationMilliseconds: duration,
        parentOperationId: operationId
    )
    step(title) { assertTrue(expression: matched, label: title) }
}
