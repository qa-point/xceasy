import Foundation

internal struct XCEasyHealingInput: Equatable {
    let executionId: String
    let failureFingerprint: String
    let selector: XCEasyLocatorDescriptor
    let candidates: [XCEasyQueryEvidence.Candidate]
}

internal struct XCEasyHealingRankedCandidate: Codable, Equatable {
    let identifier: String
    let elementType: String
    let confidence: Double
    let reasonCodes: [String]
    let evidenceCandidateIndex: Int
}

internal struct XCEasyHealingProposal: Codable, Equatable {
    let schemaVersion: String
    let executionId: String
    let failureFingerprint: String
    let selectorFingerprint: String
    let disposition: String
    let reasonCode: String
    let requiresHumanApproval: Bool
    let rankedCandidates: [XCEasyHealingRankedCandidate]
}

internal enum XCEasyHealingEngine {
    /// Ranks semantically safe candidates and applies review-only healing thresholds.
    ///
    /// The engine never mutates source, selectors, assertions, or runtime behavior.
    ///
    /// - Parameters:
    ///   - input: Failed selector identity and bounded alternative candidates.
    ///   - configuration: Confidence, score-gap, and observe/suggest policy.
    /// - Returns: Deterministic proposal that always requires human approval.
    static func evaluate(
        input: XCEasyHealingInput,
        configuration: XCEasyHealingConfiguration
    ) -> XCEasyHealingProposal {
        let expected = input.selector.segments.last
        let expectedType = expected?.elementType ?? ""
        let expectedIdentifier = expected?.strategy == .identifier ? expected?.value ?? "" : ""
        let ranked = input.candidates.enumerated().compactMap { index, candidate -> XCEasyHealingRankedCandidate? in
            guard candidate.relationship == "alternative",
                  candidate.elementType.lowercased() == expectedType.lowercased(),
                  !candidate.identifier.isEmpty else { return nil }
            let identifierScore = similarity(expectedIdentifier, candidate.identifier)
            var score = 0.35 + (0.45 * identifierScore)
            var reasons = ["healing.semantic_type_match"]
            if identifierScore >= 0.5 { reasons.append("healing.identifier_similarity") }
            if candidate.isHittable {
                score += 0.10
                reasons.append("healing.candidate_hittable")
            }
            if candidate.isEnabled {
                score += 0.10
                reasons.append("healing.candidate_enabled")
            }
            return XCEasyHealingRankedCandidate(
                identifier: candidate.identifier,
                elementType: candidate.elementType,
                confidence: min(1, score),
                reasonCodes: reasons,
                evidenceCandidateIndex: index
            )
        }.sorted {
            if $0.confidence == $1.confidence { return $0.identifier < $1.identifier }
            return $0.confidence > $1.confidence
        }

        let top = ranked.first?.confidence ?? 0
        let gap = top - (ranked.dropFirst().first?.confidence ?? 0)
        let disposition: String
        let reason: String
        if ranked.isEmpty {
            disposition = "blocked"
            reason = "healing.no_semantic_candidate"
        } else if top < configuration.minimumConfidence {
            disposition = "blocked"
            reason = "healing.confidence_below_threshold"
        } else if ranked.count > 1, gap < configuration.minimumScoreGap {
            disposition = "blocked"
            reason = "healing.ambiguous_candidates"
        } else if configuration.mode == .observe {
            disposition = "observed"
            reason = "healing.policy_observe"
        } else {
            disposition = "suggested"
            reason = "healing.candidate_ready_for_review"
        }
        return XCEasyHealingProposal(
            schemaVersion: "1.0.0",
            executionId: input.executionId,
            failureFingerprint: input.failureFingerprint,
            selectorFingerprint: input.selector.fingerprint,
            disposition: disposition,
            reasonCode: reason,
            requiresHumanApproval: true,
            rankedCandidates: ranked
        )
    }

    /// Computes normalized case-insensitive Levenshtein similarity.
    ///
    /// - Parameters:
    ///   - lhs: Expected identifier.
    ///   - rhs: Candidate identifier.
    /// - Returns: Similarity in `0...1`, or zero when either value is empty.
    private static func similarity(_ lhs: String, _ rhs: String) -> Double {
        guard !lhs.isEmpty, !rhs.isEmpty else { return 0 }
        let left = Array(lhs.lowercased())
        let right = Array(rhs.lowercased())
        var previous = Array(0...right.count)
        for (leftIndex, leftCharacter) in left.enumerated() {
            var current = [leftIndex + 1]
            for (rightIndex, rightCharacter) in right.enumerated() {
                current.append(min(
                    current[rightIndex] + 1,
                    previous[rightIndex + 1] + 1,
                    previous[rightIndex] + (leftCharacter == rightCharacter ? 0 : 1)
                ))
            }
            previous = current
        }
        return 1 - (Double(previous[right.count]) / Double(max(left.count, right.count)))
    }
}
