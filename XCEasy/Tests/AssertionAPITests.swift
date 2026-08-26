import XCTest
@testable import XCEasy

final class AssertionAPITests: XCTestCase {
    func testBooleanAndComparableAssertionsAcceptMatchingValues() {
        assertTrue(expression: true, label: "true value")
        assertFalse(expression: false, label: "false value")
        assertEqual(actual: 42, expected: 42)
        assertNotEqual(actual: 42, expected: 17)
        assertGreaterThan(actual: 43, expected: 42)
        assertGreaterThanOrEqual(actual: 42, expected: 42)
        assertLessThan(actual: 41, expected: 42)
        assertLessThanOrEqual(actual: 42, expected: 42)
    }

    func testCollectionAndOptionalAssertionsAcceptMatchingValues() {
        assertContains(string: "XCEasy framework", substring: "Easy")
        assertDoesNotContain(string: "XCEasy framework", substring: "secret")
        assertContains(collection: [1, 2, 3], element: 2)
        assertDoesNotContain(collection: [1, 2, 3], element: 4)
        assertNil(actual: Optional<Int>.none)
        assertNotNil(actual: Optional.some(42))
        assertEmpty(actual: [Int]())
        assertNotEmpty(actual: [42])
    }

    func testThrowingAssertionsAcceptExpectedOutcomes() {
        enum SampleError: Error { case expected }

        assertThrows("throwing operation") { throw SampleError.expected }
        let value = assertDoesNotThrow("successful operation") { 42 }

        XCTAssertEqual(value, 42)
    }

    func testPurePredicatesCoverMatchingAndNonMatchingOutcomes() {
        XCTAssertTrue(XCEasyAssertionPredicate.equal(1, 1))
        XCTAssertFalse(XCEasyAssertionPredicate.equal(1, 2))
        XCTAssertTrue(XCEasyAssertionPredicate.notEqual(1, 2))
        XCTAssertFalse(XCEasyAssertionPredicate.notEqual(1, 1))
        XCTAssertTrue(XCEasyAssertionPredicate.greaterThan(2, 1))
        XCTAssertFalse(XCEasyAssertionPredicate.greaterThan(1, 2))
        XCTAssertTrue(XCEasyAssertionPredicate.greaterThanOrEqual(2, 2))
        XCTAssertFalse(XCEasyAssertionPredicate.greaterThanOrEqual(1, 2))
        XCTAssertTrue(XCEasyAssertionPredicate.lessThan(1, 2))
        XCTAssertFalse(XCEasyAssertionPredicate.lessThan(2, 1))
        XCTAssertTrue(XCEasyAssertionPredicate.lessThanOrEqual(2, 2))
        XCTAssertFalse(XCEasyAssertionPredicate.lessThanOrEqual(2, 1))
        XCTAssertTrue(XCEasyAssertionPredicate.contains("framework", "work"))
        XCTAssertFalse(XCEasyAssertionPredicate.contains("framework", "secret"))
        XCTAssertTrue(XCEasyAssertionPredicate.doesNotContain("framework", "secret"))
        XCTAssertFalse(XCEasyAssertionPredicate.doesNotContain("framework", "work"))
        XCTAssertTrue(XCEasyAssertionPredicate.contains([1, 2], 2))
        XCTAssertFalse(XCEasyAssertionPredicate.contains([1, 2], 3))
        XCTAssertTrue(XCEasyAssertionPredicate.doesNotContain([1, 2], 3))
        XCTAssertFalse(XCEasyAssertionPredicate.doesNotContain([1, 2], 2))
        XCTAssertTrue(XCEasyAssertionPredicate.isNil(Optional<Int>.none))
        XCTAssertFalse(XCEasyAssertionPredicate.isNil(Optional.some(1)))
        XCTAssertTrue(XCEasyAssertionPredicate.isNotNil(Optional.some(1)))
        XCTAssertFalse(XCEasyAssertionPredicate.isNotNil(Optional<Int>.none))
        XCTAssertTrue(XCEasyAssertionPredicate.isEmpty([Int]()))
        XCTAssertFalse(XCEasyAssertionPredicate.isEmpty([1]))
        XCTAssertTrue(XCEasyAssertionPredicate.isNotEmpty([1]))
        XCTAssertFalse(XCEasyAssertionPredicate.isNotEmpty([Int]()))
    }

    func testAutoclosureIsEvaluatedOnce() {
        var evaluationCount = 0
        func nextValue() -> Int {
            evaluationCount += 1
            return 42
        }

        assertEqual(actual: nextValue(), expected: 42)

        XCTAssertEqual(evaluationCount, 1)
    }
}
