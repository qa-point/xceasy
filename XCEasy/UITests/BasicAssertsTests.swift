import XCEasy

class BasicAssertsTests: XCEasyTestCase {
    override func configuration() {
        XCEasyConfig.apply(
            bundleId: "com.apple.mobilesafari"
        )
        super.configuration()
    }

    // MARK: - Positive tests

    func testAssertEqual() {
        assertEqual(actual: "test_sting", expected: "test_sting")
    }

    func testAssertEqualNumbers() {
        assertEqual(actual: 1, expected: 1)
    }

    func test_assertTrue() {
        assertTrue(expression: true, label: "Assert True Label")
    }

    func test_assertFalse() {
        assertFalse(expression: false, label: "Assert False Label")
    }

    func testAssertGreaterThanOrEqualSame() {
        assertGreaterThanOrEqual(actual: 1, expected: 1)
    }

    func testAssertGreaterThanOrEqual() {
        assertGreaterThanOrEqual(actual: 2, expected: 1)
    }

    // MARK: - Negative tests

    func testAssertEqualNumbersFailed() {
        assertEqual(actual: 1, expected: 2)
    }

    func testAssertEqualFailed() {
        assertEqual(actual: "test_sting", expected: "test_sting2")
    }

    func test_assertTrueFailed() {
        assertTrue(expression: false, label: "Assert True Label")
    }

    func test_assertFalseFailed() {
        assertFalse(expression: true, label: "Assert False Label")
    }

    func testAssertGreaterThanOrEqualFailed() {
        assertGreaterThanOrEqual(actual: 1, expected: 2)
    }
}
