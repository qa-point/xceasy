import CoreGraphics
import XCTest
@testable import XCEasy

final class XCEasyVisibilityEvaluatorTests: XCTestCase {
    func testOnScreenPolicyAcceptsUIKitAndSwiftUIFramesInsideViewport() {
        let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
        let uiKit = XCEasyVisibilityEvaluator.evaluate(
            elementFrame: CGRect(x: 16, y: 100, width: 358, height: 44),
            applicationFrame: viewport,
            policy: .onScreen
        )
        let swiftUI = XCEasyVisibilityEvaluator.evaluate(
            elementFrame: CGRect(x: 20, y: 200, width: 350, height: 80),
            applicationFrame: viewport,
            policy: .onScreen
        )

        XCTAssertTrue(uiKit.isVisible)
        XCTAssertTrue(swiftUI.isVisible)
        XCTAssertEqual(uiKit.reasonCode, "visibility.intersects_viewport")
        XCTAssertEqual(swiftUI.confidence, "high")
    }

    func testOnScreenPolicyRejectsOffscreenWebViewDescendantFrame() {
        let result = XCEasyVisibilityEvaluator.evaluate(
            elementFrame: CGRect(x: 0, y: 1_200, width: 390, height: 50),
            applicationFrame: CGRect(x: 0, y: 0, width: 390, height: 844),
            policy: .onScreen
        )

        XCTAssertFalse(result.isVisible)
        XCTAssertEqual(result.reasonCode, "visibility.outside_viewport")
        XCTAssertEqual(result.confidence, "high")
    }

    func testOnScreenPolicyAcceptsPartialViewportIntersection() {
        let result = XCEasyVisibilityEvaluator.evaluate(
            elementFrame: CGRect(x: 350, y: 820, width: 80, height: 80),
            applicationFrame: CGRect(x: 0, y: 0, width: 390, height: 844),
            policy: .onScreen
        )

        XCTAssertTrue(result.isVisible)
        XCTAssertEqual(result.reasonCode, "visibility.intersects_viewport")
    }

    func testInvalidElementGeometryIsHiddenForEveryPolicy() {
        for policy in [XCEasyVisibilityPolicy.onScreen, .nonEmptyFrame] {
            let result = XCEasyVisibilityEvaluator.evaluate(
                elementFrame: .zero,
                applicationFrame: CGRect(x: 0, y: 0, width: 390, height: 844),
                policy: policy
            )
            XCTAssertFalse(result.isVisible)
            XCTAssertEqual(result.reasonCode, "visibility.invalid_element_frame")
        }
    }

    func testUnavailableViewportUsesExplicitLowConfidenceFallback() {
        let result = XCEasyVisibilityEvaluator.evaluate(
            elementFrame: CGRect(x: 1, y: 1, width: 10, height: 10),
            applicationFrame: nil,
            policy: .onScreen
        )

        XCTAssertTrue(result.isVisible)
        XCTAssertEqual(result.reasonCode, "visibility.viewport_unavailable_fallback")
        XCTAssertEqual(result.confidence, "low")
    }

    func testNonEmptyFramePolicyDoesNotRequireViewportIntersection() {
        let result = XCEasyVisibilityEvaluator.evaluate(
            elementFrame: CGRect(x: 0, y: 2_000, width: 100, height: 50),
            applicationFrame: CGRect(x: 0, y: 0, width: 390, height: 844),
            policy: .nonEmptyFrame
        )

        XCTAssertTrue(result.isVisible)
        XCTAssertEqual(result.reasonCode, "visibility.non_empty_frame")
        XCTAssertEqual(result.confidence, "medium")
    }
}
