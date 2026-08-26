import XCTest
@testable import XCEasy

final class XCEasyQueryAmbiguityDecisionTests: XCTestCase {
    func testStrictPolicyTurnsAmbiguousMatchIntoFailure() {
        let decision = XCEasyQueryAmbiguityDecision.evaluate(
            policy: .strict,
            predicateMatched: true,
            candidateCount: 2,
            hasExplicitIndex: false
        )

        XCTAssertTrue(decision.isAmbiguous)
        XCTAssertFalse(decision.matched)
        XCTAssertEqual(decision.reasonCode, "query.ambiguous_match")
        XCTAssertEqual(decision.level, "error")
    }

    func testPermissivePolicyRetainsMatchAndWarns() {
        let decision = XCEasyQueryAmbiguityDecision.evaluate(
            policy: .permissive,
            predicateMatched: true,
            candidateCount: 3,
            hasExplicitIndex: false
        )

        XCTAssertTrue(decision.matched)
        XCTAssertEqual(decision.reasonCode, "query.ambiguous_first_match")
        XCTAssertEqual(decision.level, "warning")
    }

    func testExplicitIndexIsNeverTreatedAsAmbiguous() {
        let decision = XCEasyQueryAmbiguityDecision.evaluate(
            policy: .strict,
            predicateMatched: true,
            candidateCount: 3,
            hasExplicitIndex: true
        )

        XCTAssertFalse(decision.isAmbiguous)
        XCTAssertTrue(decision.matched)
        XCTAssertNil(decision.reasonCode)
    }
}
