import Foundation

/// Controls the amount of structured evidence collected for UI queries.
public enum XCEasyUIQueryEvidenceLevel: String, Codable, CaseIterable, Sendable {
    /// Disables `ui.query.*` events while preserving normal query behavior.
    case off

    /// Emits query lifecycle and state evidence, collecting candidate snapshots
    /// only for failures and ambiguous matches. This is the default.
    case basic

    /// Collects bounded candidate snapshots for every completed query.
    case detailed
}
