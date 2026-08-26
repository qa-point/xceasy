import Foundation
import XCTest

/// One redacted assertion mismatch captured by an active `softly` block.
internal struct XCEasySoftAssertionFailure: Equatable, Sendable {
    let label: String
    let expected: String?
    let actual: String?
    let file: String
    let line: UInt
}

/// Lock-protected bounded storage owned by one `softly` invocation.
internal final class XCEasySoftAssertionCollector: @unchecked Sendable {
    private let lock = NSLock()
    private let maximumRecordedFailures: Int
    private var storedFailures: [XCEasySoftAssertionFailure] = []
    private var totalFailureCount = 0

    /// Creates storage with a bounded diagnostic payload.
    ///
    /// - Parameter maximumRecordedFailures: Maximum detailed mismatches retained in the summary.
    init(maximumRecordedFailures: Int = 50) {
        self.maximumRecordedFailures = min(100, max(1, maximumRecordedFailures))
    }

    /// Stores one already-redacted mismatch.
    ///
    /// - Parameter failure: Assertion evidence captured at its original call site.
    func record(_ failure: XCEasySoftAssertionFailure) {
        lock.xceasyWithLock {
            totalFailureCount += 1
            if storedFailures.count < maximumRecordedFailures {
                storedFailures.append(failure)
            }
        }
        XCEasyTestLogger.shared.event(DiagnosticEvent(
            event: "soft_assertion.recorded",
            level: "error",
            testId: XCEasyTestContext.shared.testId,
            operationCode: "assert.soft",
            operationId: UUID().uuidString.lowercased(),
            statusCode: "failed",
            reasonCode: "soft_assertion.predicate_not_matched",
            title: failure.label,
            source: DiagnosticSource(file: failure.file, line: Int(failure.line), function: nil)
        ))
    }

    /// Builds one bounded aggregate suitable for an XCTest issue and Allure status details.
    ///
    /// - Parameter title: Human-readable group name.
    /// - Returns: Multiline failure summary, or `nil` when all assertions passed.
    func failureSummary(title: String) -> String? {
        lock.xceasyWithLock {
            guard totalFailureCount > 0 else { return nil }
            var lines = [
                "\(SensitiveDataRedactor.redact(title)): \(totalFailureCount) assertion(s) failed"
            ]
            for (index, failure) in storedFailures.enumerated() {
                let expected = failure.expected.map { " expected=\($0)" } ?? ""
                let actual = failure.actual.map { " actual=\($0)" } ?? ""
                lines.append(
                    "\(index + 1). \(failure.label)\(expected)\(actual) at \(failure.file):\(failure.line)"
                )
            }
            let omitted = totalFailureCount - storedFailures.count
            if omitted > 0 {
                lines.append("… \(omitted) additional failure(s) omitted by the collection bound")
            }
            return lines.joined(separator: "\n")
        }
    }
}

/// Routes an assertion failure either to the active soft scope or directly to XCTest.
///
/// - Parameters:
///   - message: Human-readable localized mismatch description.
///   - expected: Optional redacted expected value.
///   - actual: Optional redacted actual value.
///   - file: Compiler-provided call-site file.
///   - line: Compiler-provided call-site line.
internal func recordAssertionFailure(
    _ message: String,
    expected: String? = nil,
    actual: String? = nil,
    file: StaticString,
    line: UInt
) {
    let failure = XCEasySoftAssertionFailure(
        label: SensitiveDataRedactor.redact(message),
        expected: expected.map(SensitiveDataRedactor.redact),
        actual: actual.map(SensitiveDataRedactor.redact),
        file: URL(fileURLWithPath: "\(file)").lastPathComponent,
        line: line
    )
    guard XCEasyTestContext.shared.recordSoftAssertionFailure(failure) else {
        XCTFail(failure.label, file: file, line: line)
        return
    }
}

/// Runs regular XCEasy assertions in aggregate mode.
///
/// Existing value, UI-element, component, and component-collection assertions keep their normal
/// syntax and diagnostic steps. A mismatch is recorded and execution continues with the next
/// statement. After the block, XCEasy reports one XCTest issue containing every mismatch retained
/// by the bounded collector. Actions and framework errors remain hard failures.
///
/// - Parameters:
///   - title: Human-readable group name used in Allure and the aggregate issue.
///   - file: Compiler-provided call-site file for the aggregate issue.
///   - line: Compiler-provided call-site line for the aggregate issue.
///   - block: Assertions and ordinary test code to execute.
///
/// ```swift
/// softly("Home screen") {
///     home.navbar.assertIsDisplayed()
///     home.cards.get(index: 1).assertIsDisplayed()
///     assertEqual(actual: home.title.label, expected: "Home")
/// }
/// ```
public func softly(
    _ title: String = "Soft assertions",
    file: StaticString = #filePath,
    line: UInt = #line,
    block: () -> Void
) {
    step(title, file: (file), line: line) {
        let collector = XCEasySoftAssertionCollector()
        XCEasyTestContext.shared.pushSoftAssertionScope(collector)
        block()
        let completedCollector = XCEasyTestContext.shared.popSoftAssertionScope() ?? collector
        if let summary = completedCollector.failureSummary(title: title) {
            XCTFail(summary, file: file, line: line)
        }
    }
}

/// Runs regular XCEasy assertions in aggregate mode across structured concurrency suspension.
///
/// - Parameters:
///   - title: Human-readable group name used in Allure and the aggregate issue.
///   - file: Compiler-provided call-site file for the aggregate issue.
///   - line: Compiler-provided call-site line for the aggregate issue.
///   - block: Async assertions and ordinary test code to execute.
@available(iOS 15.0, *)
public func softly(
    _ title: String = "Soft assertions",
    file: StaticString = #filePath,
    line: UInt = #line,
    block: () async -> Void
) async {
    await XCEasyTestContext.shared.withCurrentExecution {
        await step(title, file: (file), line: line) {
            let collector = XCEasySoftAssertionCollector()
            XCEasyTestContext.shared.pushSoftAssertionScope(collector)
            await block()
            let completedCollector = XCEasyTestContext.shared.popSoftAssertionScope() ?? collector
            if let summary = completedCollector.failureSummary(title: title) {
                XCTFail(summary, file: file, line: line)
            }
        }
    }
}

extension NSLock {
    /// Executes a closure while holding the lock.
    ///
    /// - Parameter body: Critical-section work.
    /// - Returns: Value returned by `body`.
    internal func xceasyWithLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
