import XCTest

// MARK: - XCUIElement Properties

extension XCUIElement {

    /// Enumeration representing element properties.
    enum Properties: String {
        case hittable
        case selected
        case exists
        case enabled
    }

    // MARK: - Methods

    /// Checks if an element matches the specified property within the given timeout.
    ///
    /// - Parameters:
    ///   - property: The property to check.
    ///   - state: The expected state (default is true).
    ///   - timeout: The maximum amount of time to wait for the property to match.
    /// - Returns: `true` if the element matches the property within the timeout, `false` otherwise.
    @discardableResult
    func isElement(_ property: Properties, _ state: Bool = true, timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        XCEasyTestLogger.shared.log("Checking property '\(property)=\(state)' of \(self.description)", level: .def)
        let pollingInterval: TimeInterval = 0.3
        let endTime = Date().addingTimeInterval(timeout)

        while Date() < endTime {
            XCEasyTestLogger.shared.log("Checking property '\(property)=\(state)' condition", level: .def)
            let predicate = NSPredicate(format: "\(property.rawValue) == \(state)")
            if predicate.evaluate(with: self) {
                XCEasyTestLogger.shared.log("Condition '\(property.rawValue)=\(state)' for \(self.description) is true!", level: .def)
                return true
            }

            Thread.sleep(forTimeInterval: pollingInterval)
        }
        XCEasyTestLogger.shared.log("Condition '\(property)=\(state)' for \(self.description) is false!", level: .def)
        return false
    }

    /// Waits for an element to appear in the tree within a specified time.
    ///
    /// - Parameters:
    ///   - timeout: Wait timeout in seconds.
    ///   - soft: If true, does not fail the test on timeout.
    /// - Returns: Self for method chaining.
    @discardableResult
    func waitForExists(timeout: TimeInterval = XCEasyConfig.actionTimeout, soft: Bool = false) -> Self {
        let predicate = NSPredicate(format: "\(Properties.exists.rawValue) == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let startTime = Date()
        while !expectation.predicate.evaluate(with: self) {
            if Date().timeIntervalSince(startTime) > timeout {
                if !soft {
                    print(self.debugDescription)
                    XCTFail("Element did not exists within \(timeout) seconds")
                }
                break
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        return self
    }
}
