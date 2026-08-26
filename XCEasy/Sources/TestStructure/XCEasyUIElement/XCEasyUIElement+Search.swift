import Foundation
import XCTest

// MARK: - Fresh element resolution

extension XCEasyUIElement {

    /// Resolves a positive lookup using the shared observation engine and emits
    /// structured query evidence for the complete locator chain.
    internal func search(timeout: TimeInterval, parentOperationId: String? = nil) -> XCUIElement {
        let observation = observe(
            expectedState: "present",
            timeout: timeout,
            parentOperationId: parentOperationId
        ) { $0.state != .absent }
        guard let element = observation.last.element else {
            return XCUIApplication()
        }
        return element
    }

    /// Observes presence or absence using a fresh query for every polling attempt.
    ///
    /// - Parameters:
    ///   - expected: `true` for presence or `false` for absence.
    ///   - timeout: Maximum observation interval in seconds.
    ///   - parentOperationId: Optional action/assertion event that owns the query.
    /// - Returns: Whether the requested existence state was observed.
    internal func observeExistence(
        expected: Bool,
        timeout: TimeInterval,
        parentOperationId: String? = nil
    ) -> Bool {
        observe(
            expectedState: expected ? "present" : XCEasyElementState.absent.rawValue,
            timeout: timeout,
            parentOperationId: parentOperationId,
            // Asking XCUI for the count of a scoped query while its last match disappears can
            // record an XCTest infrastructure failure instead of returning zero. The selected
            // element's `exists` value is sufficient for an absence observation and remains safe.
            collectCandidateCount: expected
        ) { observation in
            expected ? observation.state != .absent : observation.state == .absent
        }.matched
    }

    /// Builds a new XCUI query from the immutable root-to-child locator chain.
    /// This method never waits and never logs a missing element as an error.
    ///
    /// - Returns: The selected XCUI element, or `nil` when no application context is available.
    internal func queryElement() -> XCUIElement? {
        queryEvaluation().element
    }

    /// Rebuilds and evaluates the complete locator chain against the current application tree.
    ///
    /// - Parameter collectCandidateCount: Whether to evaluate XCUI query counts for evidence.
    /// - Returns: Optional selected element plus context needed for ambiguity and failure diagnosis.
    internal func queryEvaluation(
        collectCandidateCount: Bool = true
    ) -> XCEasyQueryEvaluation {
        let locators = locatorChain
        guard let application else {
            return XCEasyQueryEvaluation(
                element: nil,
                filteredQuery: nil,
                alternativeQuery: nil,
                candidateCount: 0,
                selectedIndex: nil,
                failedSegmentIndex: 0,
                ancestorState: nil,
                isContextAvailable: false,
                selectionFailureReason: nil
            )
        }

        var scope: XCUIElement = application
        var selectedElement: XCUIElement? = application
        var finalFilteredQuery: XCUIElementQuery?
        var firstFailureAlternativeQuery: XCUIElementQuery?
        var finalCandidateCount = 0
        var finalSelectedIndex: Int?
        var firstFailedSegmentIndex: Int?
        var firstSelectionFailureReason: String?

        for (segmentIndex, locator) in locators.enumerated() {
            let baseQuery = scope.descendants(matching: locator.type?.properties.type ?? .any)
            let filteredQuery = locator.filteredQuery(from: baseQuery)
            let reportedCount = collectCandidateCount || locator.componentPosition == .last
                ? filteredQuery.count
                : 0
            let selection = locator.componentPosition ?? locator.index.map(XCEasyComponentPosition.index)
            let selectionResolution = XCEasyQuerySelection.resolve(
                position: selection,
                reportedCount: reportedCount
            )
            if selectionResolution.selectedIndex == nil {
                if firstFailedSegmentIndex == nil {
                    firstFailedSegmentIndex = segmentIndex
                    firstFailureAlternativeQuery = baseQuery
                    firstSelectionFailureReason = selectionResolution.failureReason
                }
                finalFilteredQuery = filteredQuery
                finalCandidateCount = max(0, reportedCount)
                selectedElement = nil
                break
            }
            let selectedIndex = selectionResolution.selectedIndex ?? 0
            let element = selectionResolution.usesFirstMatch
                ? filteredQuery.firstMatch
                : filteredQuery.element(boundBy: selectedIndex)
            if firstSelectionFailureReason == nil {
                firstSelectionFailureReason = selectionResolution.failureReason
            }
            let segmentMatched = element.exists
            let candidateCount = XCEasyQueryAccounting.effectiveCandidateCount(
                reportedCount: reportedCount,
                selectedIndex: selectedIndex,
                selectedElementExists: segmentMatched
            )

            if !segmentMatched && firstFailedSegmentIndex == nil {
                firstFailedSegmentIndex = segmentIndex
                firstFailureAlternativeQuery = baseQuery
            }

            scope = element
            selectedElement = element
            finalFilteredQuery = filteredQuery
            finalCandidateCount = candidateCount
            finalSelectedIndex = segmentMatched ? selectedIndex : nil
        }

        let normalizedFailedSegmentIndex = XCEasyQueryAccounting.failedSegmentIndex(
            firstObservedFailure: firstFailedSegmentIndex,
            finalElementExists: finalSelectedIndex != nil
        )
        let ancestorState = normalizedFailedSegmentIndex.flatMap { index in
            index < locators.count - 1 ? XCEasyElementState.absent.rawValue : nil
        }
        return XCEasyQueryEvaluation(
            element: selectedElement,
            filteredQuery: finalFilteredQuery,
            alternativeQuery: normalizedFailedSegmentIndex == nil
                ? nil
                : firstFailureAlternativeQuery,
            candidateCount: finalCandidateCount,
            selectedIndex: finalSelectedIndex,
            failedSegmentIndex: normalizedFailedSegmentIndex,
            ancestorState: ancestorState,
            isContextAvailable: true,
            selectionFailureReason: firstSelectionFailureReason
        )
    }

    private var locatorChain: [XCEasyUIElement] {
        (parentLocator?.locatorChain ?? []) + [self]
    }

    /// Applies this locator segment's identifier, predicate, or text strategy.
    ///
    /// - Parameter baseQuery: Type-filtered descendant query for the current parent scope.
    /// - Returns: Query narrowed by the segment strategy, or the original query for `.any`.
    private func filteredQuery(from baseQuery: XCUIElementQuery) -> XCUIElementQuery {
        if let identifier {
            return baseQuery.matching(identifier: identifier)
        }
        if let format {
            return baseQuery.matching(NSPredicate(format: format))
        }
        if let text {
            return baseQuery.matching(NSPredicate(format: "label == %@", text))
        }
        return baseQuery
    }
}

/// Pure index-selection rules shared by XCUI query resolution and unit tests.
internal enum XCEasyQuerySelection {
    /// Result of selecting one item from a current query count.
    internal struct Resolution: Equatable {
        let selectedIndex: Int?
        let usesFirstMatch: Bool
        let failureReason: String?
    }

    /// Resolves symbolic or explicit position without touching `XCUIApplication`.
    ///
    /// - Parameters:
    ///   - position: Requested collection position, or `nil` for ordinary first-match lookup.
    ///   - reportedCount: Current nonnegative number of matching elements.
    /// - Returns: Safe selection instructions and an optional stable failure reason.
    internal static func resolve(
        position: XCEasyComponentPosition?,
        reportedCount: Int
    ) -> Resolution {
        switch position {
        case .first, .none:
            return Resolution(selectedIndex: 0, usesFirstMatch: true, failureReason: nil)
        case .last:
            guard reportedCount > 0 else {
                return Resolution(
                    selectedIndex: 0,
                    usesFirstMatch: true,
                    failureReason: "query.collection_empty"
                )
            }
            return Resolution(
                selectedIndex: reportedCount - 1,
                usesFirstMatch: false,
                failureReason: nil
            )
        case .index(let index):
            guard index >= 0 else {
                return Resolution(
                    selectedIndex: nil,
                    usesFirstMatch: false,
                    failureReason: "query.invalid_index"
                )
            }
            return Resolution(selectedIndex: index, usesFirstMatch: false, failureReason: nil)
        }
    }
}

internal struct XCEasyQueryEvaluation {
    let element: XCUIElement?
    let filteredQuery: XCUIElementQuery?
    let alternativeQuery: XCUIElementQuery?
    let candidateCount: Int
    let selectedIndex: Int?
    let failedSegmentIndex: Int?
    let ancestorState: String?
    let isContextAvailable: Bool
    let selectionFailureReason: String?
}

internal enum XCEasyQueryAccounting {
    /// Normalizes XCUI's occasionally stale zero count when the selected element exists.
    ///
    /// - Parameters:
    ///   - reportedCount: Candidate count reported by XCUI.
    ///   - selectedIndex: Index used to select the element.
    ///   - selectedElementExists: Whether the selected element currently exists.
    /// - Returns: A nonnegative count consistent with the observed selected element.
    static func effectiveCandidateCount(
        reportedCount: Int,
        selectedIndex: Int,
        selectedElementExists: Bool
    ) -> Int {
        guard selectedElementExists else { return max(0, reportedCount) }
        return max(reportedCount, selectedIndex + 1)
    }

    /// Clears transient ancestor failures when the final element resolves successfully.
    ///
    /// - Parameters:
    ///   - firstObservedFailure: First locator segment that failed during chain traversal.
    ///   - finalElementExists: Whether the complete chain resolved after traversal.
    /// - Returns: Stable failed segment index, or `nil` for a successful final resolution.
    static func failedSegmentIndex(
        firstObservedFailure: Int?,
        finalElementExists: Bool
    ) -> Int? {
        finalElementExists ? nil : firstObservedFailure
    }
}
