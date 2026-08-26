import XCTest

/// Default implementation of TestExpectationFactory for use outside XCTestCase.
///
/// This class provides a standalone way to create and wait for expectations
/// without requiring an XCTestCase instance. It uses XCTWaiter directly.
///
/// ## Usage
///
/// ```swift
/// // Use as default (ApiManager uses it by default)
/// let apiManager = ApiManager(baseURL: "https://api.example.com")
///
/// // Or explicitly specify
/// let apiManager = ApiManager(
///     baseURL: "https://api.example.com",
///     expectationFactory: DefaultExpectationFactory()
/// )
/// ```
public final class DefaultExpectationFactory: TestExpectationFactory {

    // MARK: - Properties

    /// Storage for created expectations.
    private var expectations: [XCTestExpectation] = []

    // MARK: - Initialization

    /// Creates a new instance of DefaultExpectationFactory.
    public init() {}

    // MARK: - TestExpectationFactory

    /// Creates a new test expectation.
    ///
    /// - Parameter description: A description of the expectation.
    /// - Returns: An `XCTestExpectation` instance.
    public func makeExpectation(description: String) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: description)
        expectations.append(expectation)
        return expectation
    }

    /// Waits for all created expectations to be fulfilled or for the timeout to expire.
    ///
    /// - Parameter timeout: The maximum time to wait in seconds.
    /// - Returns: `true` if all expectations were fulfilled, `false` if timeout occurred.
    public func waitForExpectations(timeout: TimeInterval) -> Bool {
        guard !expectations.isEmpty else {
            return true
        }

        // Use XCTWaiter for synchronous waiting
        let waiter = XCTWaiter()
        let result = waiter.wait(for: expectations, timeout: timeout)

        // Clear expectations after waiting
        expectations.removeAll()

        // Return true only if completed successfully
        return result == .completed
    }
}
