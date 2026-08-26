import Foundation

/// Defines how XCEasy handles a locator that matches more than one element
/// without an explicit index.
public enum XCEasyUIQueryAmbiguityPolicy: String, Codable, CaseIterable, Sendable {
    /// Fails the current operation with a typed ambiguity reason. This is the default.
    case strict

    /// Uses the first match and emits a warning with bounded candidate evidence.
    case permissive
}
