import XCTest

// MARK: - TestExpectationFactory

/// Protocol defining the interface for creating and managing test expectations.
///
/// This protocol abstracts the XCTest expectation mechanism, allowing for
/// dependency injection and easier testing of components that rely on
/// asynchronous operations.
///
/// ## Usage
///
/// The protocol is primarily used by `ApiManager` and other components that
/// need to wait for asynchronous operations to complete.
///
/// ```swift
/// // Default implementation using XCTestCase
/// extension XCTestCase: TestExpectationFactory {}
///
/// // Custom implementation for testing
/// class MockExpectationFactory: TestExpectationFactory {
///     func makeExpectation(description: String) -> XCTestExpectation { ... }
///     func waitForExpectations(timeout: TimeInterval) { ... }
/// }
/// ```
public protocol TestExpectationFactory {

    // MARK: - Methods

    /// Creates a new test expectation with the specified description.
    ///
    /// - Parameter description: A description of the expectation.
    /// - Returns: An `XCTestExpectation` instance.
    func makeExpectation(description: String) -> XCTestExpectation

    /// Waits for all expectations to be fulfilled or for the timeout to expire.
    ///
    /// - Parameter timeout: The maximum time to wait in seconds.
    /// - Returns: `true` if all expectations were fulfilled, `false` if timeout occurred.
    func waitForExpectations(timeout: TimeInterval) -> Bool
}

// MARK: - Default Implementation

extension XCTestCase: TestExpectationFactory {

    /// Creates a new test expectation.
    ///
    /// - Parameter description: A description of the expectation.
    /// - Returns: An `XCTestExpectation` instance.
    public func makeExpectation(description: String) -> XCTestExpectation {
        return self.expectation(description: description)
    }

    /// Waits for all expectations to be fulfilled or for the timeout to expire.
    ///
    /// - Parameter timeout: The maximum time to wait in seconds.
    /// - Returns: `true` if all expectations were fulfilled, `false` if timeout occurred.
    public func waitForExpectations(timeout: TimeInterval) -> Bool {
        var fulfilled = true
        self.waitForExpectations(timeout: timeout) { error in
            fulfilled = error == nil
        }
        return fulfilled
    }
}
