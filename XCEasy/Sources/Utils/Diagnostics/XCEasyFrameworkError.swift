import Foundation
import XCTest

internal struct XCEasyFrameworkError: Error, Equatable {
    let code: String
    let safeDescription: String
}

/// Records a typed framework failure in diagnostics and XCTest.
///
/// - Parameters:
///   - error: Machine-readable code and privacy-safe human description.
///   - operationId: Optional operation that failed.
///   - file: Call-site file forwarded to XCTest.
///   - line: Call-site line forwarded to XCTest.
/// - Returns: Always `false`, allowing use in guard-style predicates.
@discardableResult
internal func recordFrameworkFailure(
    _ error: XCEasyFrameworkError,
    operationId: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
) -> Bool {
    XCEasyTestLogger.shared.event(DiagnosticEvent(
        event: "framework.error",
        level: "error",
        testId: XCEasyTestContext.shared.testId,
        operationCode: "framework.error",
        operationId: operationId,
        statusCode: "failed",
        reasonCode: error.code,
        title: error.safeDescription,
        source: DiagnosticSource(file: String(describing: file), line: Int(line), function: nil)
    ))
    XCTFail("[\(error.code)] \(error.safeDescription)", file: file, line: line)
    return false
}
