import Foundation

internal struct XCEasyQueryAmbiguityDecision: Equatable {
    let isAmbiguous: Bool
    let matched: Bool
    let reasonCode: String?
    let level: String?

    /// Applies strict or permissive behavior to a query with multiple candidates.
    ///
    /// - Parameters:
    ///   - policy: Configured ambiguity policy.
    ///   - predicateMatched: Whether the requested state matched the selected element.
    ///   - candidateCount: Number of matching elements in the current UI tree.
    ///   - hasExplicitIndex: Whether the caller explicitly disambiguated by index.
    /// - Returns: Normalized match result plus stable reason and log level.
    static func evaluate(
        policy: XCEasyUIQueryAmbiguityPolicy,
        predicateMatched: Bool,
        candidateCount: Int,
        hasExplicitIndex: Bool
    ) -> XCEasyQueryAmbiguityDecision {
        let isAmbiguous = candidateCount > 1 && !hasExplicitIndex
        guard isAmbiguous else {
            return XCEasyQueryAmbiguityDecision(
                isAmbiguous: false,
                matched: predicateMatched,
                reasonCode: nil,
                level: nil
            )
        }

        switch policy {
        case .strict:
            return XCEasyQueryAmbiguityDecision(
                isAmbiguous: true,
                matched: false,
                reasonCode: "query.ambiguous_match",
                level: "error"
            )
        case .permissive:
            return XCEasyQueryAmbiguityDecision(
                isAmbiguous: true,
                matched: predicateMatched,
                reasonCode: "query.ambiguous_first_match",
                level: "warning"
            )
        }
    }
}
