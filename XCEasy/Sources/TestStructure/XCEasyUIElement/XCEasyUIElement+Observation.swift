import CoreGraphics
import Foundation
import XCTest

/// Stable UI states used by assertions, logs, and future JSONL diagnostics.
public enum XCEasyElementState: String, Codable {
    case absent
    case hidden
    case visible
    case hittable
}

internal struct XCEasyElementObservation {
    let state: XCEasyElementState
    let exists: Bool
    let isHittable: Bool
    let frame: CGRect
    let element: XCUIElement?
    let filteredQuery: XCUIElementQuery?
    let alternativeQuery: XCUIElementQuery?
    let candidateCount: Int
    let selectedIndex: Int?
    let failedSegmentIndex: Int?
    let ancestorState: String?
    let isContextAvailable: Bool
    let visibilityReasonCode: String?
    let visibilityConfidence: String?
    let selectionFailureReason: String?
}

extension XCEasyUIElement {
    private static let stateObservationInterval: TimeInterval = 0.1
    private static let candidateSnapshotLimit = 5
    private static let observationTimelineLimit = 50

    /// Polls fresh locator resolutions until the expected state matches or time expires.
    ///
    /// The method emits one correlated query lifecycle, bounded evidence, performance timing,
    /// and a review-only healing proposal on failure.
    ///
    /// - Parameters:
    ///   - expectedState: Stable state name written to canonical diagnostics.
    ///   - timeout: Maximum observation interval in seconds.
    ///   - parentOperationId: Optional action/assertion event that owns this query.
    ///   - matches: Predicate defining the accepted observation state.
    /// - Returns: First/last observations, timing, samples, attempts, and match outcome.
    internal func observe(
        expectedState: String,
        timeout: TimeInterval,
        parentOperationId: String? = nil,
        matches: (XCEasyElementObservation) -> Bool
    ) -> ObservationResult<XCEasyElementObservation> {
        let evidenceLevel = XCEasyConfig.uiQueryEvidenceLevel
        let shouldEmitEvents = XCEasyQueryEvidencePolicy.shouldEmitEvents(level: evidenceLevel)
        let queryOperationId = shouldEmitEvents ? UUID().uuidString.lowercased() : nil
        let descriptor = shouldEmitEvents ? locatorDescriptor : nil
        if let queryOperationId, let descriptor {
            XCEasyTestLogger.shared.event(DiagnosticEvent(
                event: "ui.query.started",
                testId: XCEasyTestContext.shared.testId,
                operationCode: "ui.query",
                operationId: queryOperationId,
                parentOperationId: parentOperationId,
                statusCode: "running",
                target: desc,
                selector: descriptor
            ))
        }

        let result = ObservationEngine().observe(
            timeout: timeout,
            interval: Self.stateObservationInterval,
            sample: {
                self.currentObservation(collectCandidateCount: evidenceLevel != .off)
            },
            matches: matches
        )
        let ambiguity = XCEasyQueryAmbiguityDecision.evaluate(
            policy: XCEasyConfig.uiQueryAmbiguityPolicy,
            predicateMatched: result.matched,
            candidateCount: result.last.candidateCount,
            hasExplicitIndex: index != nil
                || componentPosition != nil
        )
        let normalizedResult = ObservationResult(
            matched: ambiguity.matched,
            first: result.first,
            last: result.last,
            attempts: result.attempts,
            elapsedMilliseconds: result.elapsedMilliseconds,
            samples: result.samples
        )
        let reasonCode = ambiguity.reasonCode
            ?? queryReasonCode(
                expectedState: expectedState,
                matched: normalizedResult.matched,
                observation: normalizedResult.last
            )
        let candidateCollection = XCEasyQueryEvidencePolicy.candidateCollection(
            level: evidenceLevel,
            matched: normalizedResult.matched,
            candidateCount: normalizedResult.last.candidateCount
        )
        let candidates = candidateCollection == .bounded
            ? candidateSnapshots(for: normalizedResult.last)
            : []
        let evidence = XCEasyQueryEvidence(
            expectedState: expectedState,
            initialState: normalizedResult.first.state.rawValue,
            finalState: normalizedResult.last.state.rawValue,
            evidenceLevel: evidenceLevel.rawValue,
            candidateCollection: candidateCollection.rawValue,
            matched: normalizedResult.matched,
            reasonCode: reasonCode,
            attempts: normalizedResult.attempts,
            elapsedMilliseconds: normalizedResult.elapsedMilliseconds,
            candidateCount: normalizedResult.last.candidateCount,
            selectedIndex: normalizedResult.last.selectedIndex,
            failedSegmentIndex: normalizedResult.last.failedSegmentIndex,
            ancestorState: normalizedResult.last.ancestorState,
            candidates: candidates,
            observations: compactTimeline(normalizedResult.samples)
        )
        var failureAttachments = normalizedResult.matched || evidenceLevel == .off
            ? []
            : XCEasyTestLogger.shared.captureUIFailureEvidence(producerEventId: queryOperationId)
        if !normalizedResult.matched,
           evidenceLevel != .off,
           let proposal = XCEasyTestLogger.shared.recordHealingProposal(
               selector: descriptor ?? locatorDescriptor,
               candidates: candidates,
               reasonCode: reasonCode,
               producerEventId: queryOperationId
           ) {
            failureAttachments.append(proposal)
        }
        if let queryOperationId, let descriptor {
            XCEasyTestLogger.shared.event(DiagnosticEvent(
                event: normalizedResult.matched ? "ui.query.resolved" : "ui.query.failed",
                level: ambiguity.level ?? (normalizedResult.matched ? "info" : "error"),
                testId: XCEasyTestContext.shared.testId,
                operationCode: "ui.query",
                operationId: queryOperationId,
                parentOperationId: parentOperationId,
                statusCode: normalizedResult.matched ? "passed" : "failed",
                reasonCode: reasonCode,
                durationMilliseconds: normalizedResult.elapsedMilliseconds,
                target: desc,
                selector: descriptor,
                queryEvidence: evidence,
                attachments: failureAttachments.isEmpty ? nil : failureAttachments,
                performance: diagnosticPerformanceEvidence(
                    operationKey: "ui.query",
                    durationMilliseconds: normalizedResult.elapsedMilliseconds,
                    phasesMilliseconds: ["resolve": normalizedResult.elapsedMilliseconds]
                )
            ))
        }
        return normalizedResult
    }

    /// Resolves the immutable locator chain once and classifies its current state.
    ///
    /// - Parameter collectCandidateCount: Whether to ask XCUI for the candidate count.
    /// - Returns: Current element, state, query context, and bounded accounting metadata.
    internal func currentObservation(
        collectCandidateCount: Bool = true
    ) -> XCEasyElementObservation {
        let evaluation = queryEvaluation(collectCandidateCount: collectCandidateCount)
        guard evaluation.isContextAvailable,
              let element = evaluation.element,
              element.exists else {
            return XCEasyElementObservation(
                state: .absent,
                exists: false,
                isHittable: false,
                frame: .zero,
                element: evaluation.element,
                filteredQuery: evaluation.filteredQuery,
                alternativeQuery: evaluation.alternativeQuery,
                candidateCount: evaluation.candidateCount,
                selectedIndex: evaluation.selectedIndex,
                failedSegmentIndex: evaluation.failedSegmentIndex,
                ancestorState: evaluation.ancestorState,
                isContextAvailable: evaluation.isContextAvailable,
                visibilityReasonCode: nil,
                visibilityConfidence: nil,
                selectionFailureReason: evaluation.selectionFailureReason
            )
        }

        let frame = element.frame
        let isHittable = element.isHittable
        let observedSelectedIndex = evaluation.selectedIndex ?? (index ?? 0)
        let observedCandidateCount = max(
            evaluation.candidateCount,
            observedSelectedIndex + 1
        )
        let state: XCEasyElementState
        let visibilityReasonCode: String
        let visibilityConfidence: String
        if isHittable {
            state = .hittable
            visibilityReasonCode = "visibility.hittable"
            visibilityConfidence = "high"
        } else {
            let visibility = XCEasyVisibilityEvaluator.evaluate(
                elementFrame: frame,
                applicationFrame: application?.frame,
                policy: XCEasyConfig.visibilityPolicy
            )
            state = visibility.isVisible ? .visible : .hidden
            visibilityReasonCode = visibility.reasonCode
            visibilityConfidence = visibility.confidence
        }
        return XCEasyElementObservation(
            state: state,
            exists: true,
            isHittable: isHittable,
            frame: frame,
            element: element,
            filteredQuery: evaluation.filteredQuery,
            alternativeQuery: nil,
            candidateCount: observedCandidateCount,
            selectedIndex: observedSelectedIndex,
            failedSegmentIndex: nil,
            ancestorState: nil,
            isContextAvailable: evaluation.isContextAvailable,
            visibilityReasonCode: visibilityReasonCode,
            visibilityConfidence: visibilityConfidence,
            selectionFailureReason: evaluation.selectionFailureReason
        )
    }

    /// Maps the final query state to a stable machine-readable reason code.
    ///
    /// - Parameters:
    ///   - expectedState: Stable name of the requested state.
    ///   - matched: Whether the requested state was observed.
    ///   - observation: Final sampled UI state.
    /// - Returns: Canonical reason code for logs and AI diagnostics.
    private func queryReasonCode(
        expectedState: String,
        matched: Bool,
        observation: XCEasyElementObservation
    ) -> String {
        if !observation.isContextAvailable {
            return "query.context_unavailable"
        }
        if let selectionFailureReason = observation.selectionFailureReason {
            return selectionFailureReason
        }
        if observation.state == .absent,
           observation.ancestorState == XCEasyElementState.absent.rawValue {
            return "query.ancestor_absent"
        }
        if observation.state == .absent,
           let index,
           observation.candidateCount <= index {
            return "query.index_out_of_range"
        }
        if observation.state == .absent {
            return "query.element_absent"
        }
        let visibilityStates = Set([
            XCEasyElementState.hidden.rawValue,
            XCEasyElementState.visible.rawValue,
            XCEasyElementState.hittable.rawValue,
            "not_visible",
            "not_hittable"
        ])
        if !matched,
           visibilityStates.contains(expectedState),
           let visibilityReasonCode = observation.visibilityReasonCode {
            return visibilityReasonCode
        }
        return matched ? "query.expected_state_observed" : "query.state_not_matched"
    }

    /// Compresses repeated states while retaining the terminal sample.
    ///
    /// - Parameter samples: Raw polling samples in chronological order.
    /// - Returns: At most 50 state transitions suitable for the event envelope.
    private func compactTimeline(
        _ samples: [ObservationSample<XCEasyElementObservation>]
    ) -> [XCEasyQueryEvidence.Observation] {
        var result: [XCEasyQueryEvidence.Observation] = []
        for sample in samples {
            let observation = XCEasyQueryEvidence.Observation(
                attempt: sample.attempt,
                elapsedMilliseconds: sample.elapsedMilliseconds,
                state: sample.value.state.rawValue,
                exists: sample.value.exists,
                isHittable: sample.value.isHittable
            )
            if result.last?.state != observation.state || sample.attempt == samples.last?.attempt {
                result.append(observation)
            }
            if result.count == Self.observationTimelineLimit {
                break
            }
        }
        return result
    }

    /// Collects a bounded candidate list from the matched or nearest alternative query.
    ///
    /// - Parameter observation: Failed or ambiguous query observation.
    /// - Returns: Up to five privacy-safe candidate snapshots.
    private func candidateSnapshots(
        for observation: XCEasyElementObservation
    ) -> [XCEasyQueryEvidence.Candidate] {
        let isAlternative = observation.failedSegmentIndex != nil
        guard let query = isAlternative
            ? observation.alternativeQuery
            : observation.filteredQuery else {
            return []
        }

        var candidates: [XCEasyQueryEvidence.Candidate] = []
        for candidateIndex in 0..<Self.candidateSnapshotLimit {
            let element = query.element(boundBy: candidateIndex)
            guard element.exists else { break }
            candidates.append(XCEasyQueryEvidence.Candidate(
                element: element,
                relationship: isAlternative ? "alternative" : "matched"
            ))
        }
        return candidates
    }
}
