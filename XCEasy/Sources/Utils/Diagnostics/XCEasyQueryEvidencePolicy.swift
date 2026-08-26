import Foundation

internal enum XCEasyQueryEvidencePolicy {
    internal enum CandidateCollection: String {
        case omittedByPolicy = "omitted_by_policy"
        case bounded
    }

    /// Determines whether canonical UI query events are enabled.
    ///
    /// - Parameter level: Configured evidence level.
    /// - Returns: `false` only for the explicit `off` level.
    static func shouldEmitEvents(level: XCEasyUIQueryEvidenceLevel) -> Bool {
        level != .off
    }

    /// Selects bounded candidate collection based on privacy/overhead policy and outcome.
    ///
    /// - Parameters:
    ///   - level: Configured evidence level.
    ///   - matched: Whether the expected state was observed.
    ///   - candidateCount: Number of elements matched by the query.
    /// - Returns: Whether candidate details are omitted or collected with a fixed bound.
    static func candidateCollection(
        level: XCEasyUIQueryEvidenceLevel,
        matched: Bool,
        candidateCount: Int
    ) -> CandidateCollection {
        switch level {
        case .off:
            return .omittedByPolicy
        case .basic:
            return !matched || candidateCount > 1 ? .bounded : .omittedByPolicy
        case .detailed:
            return .bounded
        }
    }
}
