import Foundation

/// Policy used to classify a present XCUI element as visible or hidden.
public enum XCEasyVisibilityPolicy: String, Codable, Sendable {
    /// Requires a valid element frame to intersect the current application viewport.
    ///
    /// This is the default for UIKit, SwiftUI, and WebKit accessibility elements. When XCUI
    /// cannot provide a valid application frame, the evaluator falls back to a valid element
    /// frame and emits an explicit low-confidence reason code.
    case onScreen

    /// Treats any present element with a finite, nonempty frame as visible.
    ///
    /// Use this only for platforms whose accessibility bridge does not expose a stable viewport.
    case nonEmptyFrame
}
