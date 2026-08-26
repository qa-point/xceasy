import Foundation
import XCTest

// MARK: - Status

/// Model representing an Allure test status.
///
/// Status indicates the outcome of a test execution.
public enum Status: String, Codable {

    // MARK: - Cases

    /// Test failed due to assertion failure.
    case failed = "failed"

    /// Test failed due to unexpected error.
    case broken = "broken"

    /// Test passed successfully.
    case passed = "passed"

    /// Test was skipped.
    case skipped = "skipped"

    /// Test status is unknown.
    case unknown = "unknown"

    // MARK: - Methods

    /// Returns the raw string value of the status.
    var value: String {
        return self.rawValue
    }

    /// Creates a Status from a string value.
    /// - Parameter value: The string value to convert.
    /// - Returns: A Status instance if the value is valid, nil otherwise.
    static func fromValue(_ value: String) -> Status? {
        return Status(rawValue: value)
    }

    /// Creates a Status from an XCTestRun instance.
    /// - Parameter testRun: The XCTestRun instance to evaluate.
    /// - Returns: A Status instance based on the test run results.
    static func fromTestRun(_ testRun: XCTestRun?) -> Status {
        guard let testRun = testRun else { return .unknown }

        if testRun.hasSucceeded {
            return .passed
        } else if testRun.unexpectedExceptionCount > 0 {
            return .broken
        } else if testRun.hasBeenSkipped {
            return .skipped
        } else if testRun.failureCount > 0 {
            return .failed
        } else {
            return .unknown
        }
    }
}
