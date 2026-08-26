import XCTest
@testable import XCEasy

final class XCEasyActionPolicyTests: XCTestCase {
    func testHittablePolicyUsesSemanticDispatch() {
        let plan = XCEasyActionPlan(policy: .hittable)

        XCTAssertEqual(plan.expectedState, .hittable)
        XCTAssertEqual(plan.dispatch, .semantic)
        XCTAssertTrue(plan.accepts(.hittable))
        XCTAssertFalse(plan.accepts(.visible))
    }

    func testDisplayedPolicyUsesCoordinateDispatch() {
        let plan = XCEasyActionPlan(policy: .displayed)

        XCTAssertEqual(plan.expectedState, .visible)
        XCTAssertEqual(plan.dispatch, .coordinate)
        XCTAssertTrue(plan.accepts(.visible))
        XCTAssertTrue(plan.accepts(.hittable))
        XCTAssertFalse(plan.accepts(.hidden))
    }
}
