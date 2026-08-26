import CoreGraphics

/// Deterministic result of applying one visibility policy to XCUI geometry.
internal struct XCEasyVisibilityEvaluation: Equatable {
    let isVisible: Bool
    let reasonCode: String
    let confidence: String
}

/// Pure visibility classifier shared by runtime observation and unit calibration tests.
internal enum XCEasyVisibilityEvaluator {
    /// Classifies one present, non-hittable element from its current geometry.
    ///
    /// - Parameters:
    ///   - elementFrame: Frame reported by the element's accessibility representation.
    ///   - applicationFrame: Current app viewport, when XCUI exposes one.
    ///   - policy: Configured visibility policy.
    /// - Returns: Visibility, canonical reason, and confidence for diagnostics.
    static func evaluate(
        elementFrame: CGRect,
        applicationFrame: CGRect?,
        policy: XCEasyVisibilityPolicy
    ) -> XCEasyVisibilityEvaluation {
        guard isValid(elementFrame) else {
            return XCEasyVisibilityEvaluation(
                isVisible: false,
                reasonCode: "visibility.invalid_element_frame",
                confidence: "high"
            )
        }

        guard policy == .onScreen else {
            return XCEasyVisibilityEvaluation(
                isVisible: true,
                reasonCode: "visibility.non_empty_frame",
                confidence: "medium"
            )
        }

        guard let applicationFrame, isValid(applicationFrame) else {
            return XCEasyVisibilityEvaluation(
                isVisible: true,
                reasonCode: "visibility.viewport_unavailable_fallback",
                confidence: "low"
            )
        }

        let intersection = elementFrame.intersection(applicationFrame)
        guard isValid(intersection) else {
            return XCEasyVisibilityEvaluation(
                isVisible: false,
                reasonCode: "visibility.outside_viewport",
                confidence: "high"
            )
        }
        return XCEasyVisibilityEvaluation(
            isVisible: true,
            reasonCode: "visibility.intersects_viewport",
            confidence: "high"
        )
    }

    /// Checks whether geometry is finite and has a positive area.
    ///
    /// - Parameter frame: Geometry reported by XCUI.
    /// - Returns: `true` for finite, nonempty rectangles.
    private static func isValid(_ frame: CGRect) -> Bool {
        !frame.isEmpty && !frame.isNull && !frame.isInfinite
    }
}
