import Foundation
import XCTest

/// Current UI snapshot used by component-collection polling and deterministic unit tests.
internal struct XCEasyCollectionSnapshot: Equatable {
    let count: Int
    let displayedIndices: [Int]
    let isContextAvailable: Bool
}

/// Lazy, UI-aware collection of reusable component Page Objects.
///
/// Creating the collection and selecting ``first``, ``last``, or ``get(index:componentName:)``
/// builds locator intent only. Count and display operations are explicit: each polling attempt
/// reads the current accessibility tree and writes a localized Allure step plus bounded canonical
/// evidence for human and AI-assisted diagnosis.
public struct XCEasyComponentCollection<Component: XCEasyIndexedComponent> {
    private static var observationInterval: TimeInterval { 0.1 }
    private static var timelineLimit: Int { 50 }
    private static var loggedIndexLimit: Int { 100 }

    private let snapshotProvider: (_ includeDisplayed: Bool) -> XCEasyCollectionSnapshot

    /// Creates a lazy component collection from the component type's common locator.
    ///
    /// Initialization does not read the application or accessibility tree. Public selection,
    /// wait, and assertion calls create their own default report steps.
    public init() {
        self.snapshotProvider = { includeDisplayed in
            Component.collection.collectionSnapshot(includeDisplayed: includeDisplayed)
        }
    }

    /// Creates a collection with an injected snapshot provider for deterministic framework tests.
    ///
    /// - Parameter snapshotProvider: Fresh snapshot producer called for every polling attempt.
    internal init(
        snapshotProvider: @escaping (_ includeDisplayed: Bool) -> XCEasyCollectionSnapshot
    ) {
        self.snapshotProvider = snapshotProvider
    }

    /// Returns a lazy POM for the first current match and records the selection intent.
    ///
    /// This property does not query the UI. The component resolves the first match only when it is
    /// used by an action, assertion, wait, or value read.
    public var first: Component {
        selectionStep(
            operationCode: "component.collection.select_first",
            titleKey: "component_collection_select_first",
            expectation: "select_first",
            position: .first,
            componentName: nil,
            file: #fileID,
            line: #line,
            function: #function
        )
    }

    /// Returns a lazy POM for the last current match and records the selection intent.
    ///
    /// No index is cached. Every later component operation calculates the last index from the
    /// current accessibility tree. An empty collection produces a diagnostic lookup failure
    /// instead of an index trap.
    public var last: Component {
        selectionStep(
            operationCode: "component.collection.select_last",
            titleKey: "component_collection_select_last",
            expectation: "select_last",
            position: .last,
            componentName: nil,
            file: #fileID,
            line: #line,
            function: #function
        )
    }

    /// Returns a lazy POM for a zero-based current match.
    ///
    /// Selection does not read the UI. A negative index is retained as invalid locator intent so
    /// the next semantic component use can report `query.invalid_index` without crashing XCUI.
    ///
    /// - Parameters:
    ///   - index: Zero-based position to resolve when the component is used.
    ///   - componentName: Optional instance-specific name for steps and diagnostics.
    ///   - file: Compiler-provided call-site file.
    ///   - line: Compiler-provided call-site line.
    ///   - function: Compiler-provided call-site function.
    /// - Returns: A lazy component POM.
    public func get(
        index: Int,
        componentName: String? = nil,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) -> Component {
        selectionStep(
            operationCode: "component.collection.select_index",
            titleKey: "component_collection_select_index",
            titleArguments: [index],
            expectation: "select_index",
            position: .index(index),
            componentName: componentName,
            file: file,
            line: line,
            function: function
        )
    }

    /// Returns lazy POMs for every zero-based index in a half-open range.
    ///
    /// The range is converted to component locator intent without reading the UI. Canonical
    /// evidence stores at most the first 100 requested indices, while the returned array contains
    /// the complete range.
    ///
    /// - Parameters:
    ///   - indices: Half-open zero-based index range, for example `0..<3`.
    ///   - file: Compiler-provided call-site file.
    ///   - line: Compiler-provided call-site line.
    ///   - function: Compiler-provided call-site function.
    /// - Returns: Lazy component POMs in range order.
    public func get(
        indices: Range<Int>,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) -> [Component] {
        let title = localizedTitle(
            key: "component_collection_select_range",
            arguments: [indices.lowerBound, indices.upperBound]
        )
        let operationId = beginOperation(
            code: "component.collection.select_range",
            title: title,
            file: file,
            line: line,
            function: function
        )
        return step(title) {
            let components = indices.map { index in
                let position = XCEasyComponentPosition.index(index)
                return Component(
                    position: position,
                    componentName: Component.defaultComponentName(for: position)
                )
            }
            let evidence = XCEasyCollectionEvidence(
                expectation: "select_range",
                expectedCount: nil,
                actualCount: nil,
                matched: true,
                attempts: 0,
                elapsedMilliseconds: 0,
                selectedPosition: "range",
                selectedIndex: nil,
                selectedIndices: Array(indices.prefix(Self.loggedIndexLimit)),
                displayedCount: nil,
                failedIndices: nil,
                isContextAvailable: nil,
                observations: nil
            )
            finishOperation(
                code: "component.collection.select_range",
                operationId: operationId,
                title: title,
                evidence: evidence,
                assertion: false,
                file: file,
                line: line,
                function: function
            )
            return components
        }
    }

    /// Asserts that the current UI contains exactly the requested number of components.
    ///
    /// - Parameters:
    ///   - expectedCount: Required current number of matching component containers.
    ///   - timeout: Maximum polling interval in seconds.
    ///   - file: Compiler-provided call-site file.
    ///   - line: Compiler-provided call-site line.
    ///   - function: Compiler-provided call-site function.
    /// - Returns: This collection for fluent calls.
    @discardableResult
    public func assertCount(
        _ expectedCount: Int,
        timeout: TimeInterval = XCEasyConfig.assertionTimeout,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) -> Self {
        _ = observe(
            operationCode: "component.collection.assert_count_exact",
            titleKey: "component_collection_assert_count_exact",
            titleArguments: [expectedCount],
            expectation: "count_exact",
            expectedCount: expectedCount,
            includeDisplayed: false,
            timeout: timeout,
            assertion: true,
            file: file,
            line: line,
            function: function
        ) { $0.count == expectedCount }
        return self
    }

    /// Asserts that the current UI contains at least the requested number of components.
    ///
    /// - Parameters:
    ///   - minimumCount: Inclusive lower bound for the current component count.
    ///   - timeout: Maximum polling interval in seconds.
    ///   - file: Compiler-provided call-site file.
    ///   - line: Compiler-provided call-site line.
    ///   - function: Compiler-provided call-site function.
    /// - Returns: This collection for fluent calls.
    @discardableResult
    public func assertCount(
        atLeast minimumCount: Int,
        timeout: TimeInterval = XCEasyConfig.assertionTimeout,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) -> Self {
        _ = observe(
            operationCode: "component.collection.assert_count_at_least",
            titleKey: "component_collection_assert_count_at_least",
            titleArguments: [minimumCount],
            expectation: "count_at_least",
            expectedCount: minimumCount,
            includeDisplayed: false,
            timeout: timeout,
            assertion: true,
            file: file,
            line: line,
            function: function
        ) { $0.count >= minimumCount }
        return self
    }

    /// Asserts that the current UI contains at most the requested number of components.
    ///
    /// - Parameters:
    ///   - maximumCount: Inclusive upper bound for the current component count.
    ///   - timeout: Maximum polling interval in seconds.
    ///   - file: Compiler-provided call-site file.
    ///   - line: Compiler-provided call-site line.
    ///   - function: Compiler-provided call-site function.
    /// - Returns: This collection for fluent calls.
    @discardableResult
    public func assertCount(
        atMost maximumCount: Int,
        timeout: TimeInterval = XCEasyConfig.assertionTimeout,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) -> Self {
        _ = observe(
            operationCode: "component.collection.assert_count_at_most",
            titleKey: "component_collection_assert_count_at_most",
            titleArguments: [maximumCount],
            expectation: "count_at_most",
            expectedCount: maximumCount,
            includeDisplayed: false,
            timeout: timeout,
            assertion: true,
            file: file,
            line: line,
            function: function
        ) { $0.count <= maximumCount }
        return self
    }

    /// Asserts that no matching component element is currently present.
    ///
    /// - Parameters:
    ///   - timeout: Maximum polling interval in seconds.
    ///   - file: Compiler-provided call-site file.
    ///   - line: Compiler-provided call-site line.
    ///   - function: Compiler-provided call-site function.
    /// - Returns: This collection for fluent calls.
    @discardableResult
    public func assertIsEmpty(
        timeout: TimeInterval = XCEasyConfig.assertionTimeout,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) -> Self {
        _ = observe(
            operationCode: "component.collection.assert_empty",
            titleKey: "component_collection_assert_empty",
            expectation: "empty",
            expectedCount: 0,
            includeDisplayed: false,
            timeout: timeout,
            assertion: true,
            file: file,
            line: line,
            function: function
        ) { $0.count == 0 }
        return self
    }

    /// Asserts that at least one matching component element is currently present.
    ///
    /// - Parameters:
    ///   - timeout: Maximum polling interval in seconds.
    ///   - file: Compiler-provided call-site file.
    ///   - line: Compiler-provided call-site line.
    ///   - function: Compiler-provided call-site function.
    /// - Returns: This collection for fluent calls.
    @discardableResult
    public func assertIsNotEmpty(
        timeout: TimeInterval = XCEasyConfig.assertionTimeout,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) -> Self {
        _ = observe(
            operationCode: "component.collection.assert_not_empty",
            titleKey: "component_collection_assert_not_empty",
            expectation: "not_empty",
            expectedCount: 1,
            includeDisplayed: false,
            timeout: timeout,
            assertion: true,
            file: file,
            line: line,
            function: function
        ) { $0.count > 0 }
        return self
    }

    /// Waits until the current UI contains exactly the requested number of components.
    ///
    /// Timeout is a normal `false` result and does not fail the test.
    ///
    /// - Parameters:
    ///   - expectedCount: Required current number of matching component containers.
    ///   - timeout: Maximum polling interval in seconds.
    ///   - file: Compiler-provided call-site file.
    ///   - line: Compiler-provided call-site line.
    ///   - function: Compiler-provided call-site function.
    /// - Returns: `true` when the count matched, or `false` after the timeout.
    @discardableResult
    public func waitForCount(
        _ expectedCount: Int,
        timeout: TimeInterval = XCEasyConfig.actionTimeout,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) -> Bool {
        observe(
            operationCode: "component.collection.wait_count_exact",
            titleKey: "component_collection_wait_count_exact",
            titleArguments: [expectedCount],
            expectation: "count_exact",
            expectedCount: expectedCount,
            includeDisplayed: false,
            timeout: timeout,
            assertion: false,
            file: file,
            line: line,
            function: function
        ) { $0.count == expectedCount }.matched
    }

    /// Waits until the current UI contains at least the requested number of components.
    ///
    /// - Parameters:
    ///   - minimumCount: Inclusive lower bound for the current component count.
    ///   - timeout: Maximum polling interval in seconds.
    ///   - file: Compiler-provided call-site file.
    ///   - line: Compiler-provided call-site line.
    ///   - function: Compiler-provided call-site function.
    /// - Returns: `true` when the count matched, or `false` after the timeout.
    @discardableResult
    public func waitForCount(
        atLeast minimumCount: Int,
        timeout: TimeInterval = XCEasyConfig.actionTimeout,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) -> Bool {
        observe(
            operationCode: "component.collection.wait_count_at_least",
            titleKey: "component_collection_wait_count_at_least",
            titleArguments: [minimumCount],
            expectation: "count_at_least",
            expectedCount: minimumCount,
            includeDisplayed: false,
            timeout: timeout,
            assertion: false,
            file: file,
            line: line,
            function: function
        ) { $0.count >= minimumCount }.matched
    }

    /// Waits until the current UI contains at most the requested number of components.
    ///
    /// - Parameters:
    ///   - maximumCount: Inclusive upper bound for the current component count.
    ///   - timeout: Maximum polling interval in seconds.
    ///   - file: Compiler-provided call-site file.
    ///   - line: Compiler-provided call-site line.
    ///   - function: Compiler-provided call-site function.
    /// - Returns: `true` when the count matched, or `false` after the timeout.
    @discardableResult
    public func waitForCount(
        atMost maximumCount: Int,
        timeout: TimeInterval = XCEasyConfig.actionTimeout,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) -> Bool {
        observe(
            operationCode: "component.collection.wait_count_at_most",
            titleKey: "component_collection_wait_count_at_most",
            titleArguments: [maximumCount],
            expectation: "count_at_most",
            expectedCount: maximumCount,
            includeDisplayed: false,
            timeout: timeout,
            assertion: false,
            file: file,
            line: line,
            function: function
        ) { $0.count <= maximumCount }.matched
    }

    /// Asserts that the collection is nonempty and every current component is displayed.
    ///
    /// - Parameters:
    ///   - timeout: Maximum polling interval in seconds.
    ///   - file: Compiler-provided call-site file.
    ///   - line: Compiler-provided call-site line.
    ///   - function: Compiler-provided call-site function.
    /// - Returns: This collection for fluent calls.
    @discardableResult
    public func assertAllDisplayed(
        timeout: TimeInterval = XCEasyConfig.assertionTimeout,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) -> Self {
        _ = observe(
            operationCode: "component.collection.assert_all_displayed",
            titleKey: "component_collection_assert_all_displayed",
            expectation: "all_displayed",
            expectedCount: nil,
            includeDisplayed: true,
            timeout: timeout,
            assertion: true,
            file: file,
            line: line,
            function: function
        ) { snapshot in
            snapshot.count > 0 && snapshot.displayedIndices.count == snapshot.count
        }
        return self
    }

    /// Waits until the collection is nonempty and every current component is displayed.
    ///
    /// Timeout is a normal `false` result and does not fail the test.
    ///
    /// - Parameters:
    ///   - timeout: Maximum polling interval in seconds.
    ///   - file: Compiler-provided call-site file.
    ///   - line: Compiler-provided call-site line.
    ///   - function: Compiler-provided call-site function.
    /// - Returns: `true` when all current components are displayed, or `false` after timeout.
    @discardableResult
    public func waitForAllDisplayed(
        timeout: TimeInterval = XCEasyConfig.actionTimeout,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) -> Bool {
        observe(
            operationCode: "component.collection.wait_all_displayed",
            titleKey: "component_collection_wait_all_displayed",
            expectation: "all_displayed",
            expectedCount: nil,
            includeDisplayed: true,
            timeout: timeout,
            assertion: false,
            file: file,
            line: line,
            function: function
        ) { snapshot in
            snapshot.count > 0 && snapshot.displayedIndices.count == snapshot.count
        }.matched
    }

    /// Records one lazy single-component selection and returns the new POM.
    ///
    /// - Parameters:
    ///   - operationCode: Stable collection operation code.
    ///   - titleKey: Localization key for the default Allure title.
    ///   - titleArguments: Optional localization arguments.
    ///   - expectation: Stable evidence expectation.
    ///   - position: Lazy component position.
    ///   - componentName: Optional instance-specific component name.
    ///   - file: Call-site file.
    ///   - line: Call-site line.
    ///   - function: Call-site function.
    /// - Returns: A lazy component POM.
    private func selectionStep(
        operationCode: String,
        titleKey: String,
        titleArguments: [CVarArg] = [],
        expectation: String,
        position: XCEasyComponentPosition,
        componentName: String?,
        file: StaticString,
        line: UInt,
        function: StaticString
    ) -> Component {
        let title = localizedTitle(key: titleKey, arguments: titleArguments)
        let operationId = beginOperation(
            code: operationCode,
            title: title,
            file: file,
            line: line,
            function: function
        )
        return step(title) {
            let resolvedComponentName = componentName
                ?? Component.defaultComponentName(for: position)
            let component = Component(
                position: position,
                componentName: resolvedComponentName
            )
            let evidence = selectionEvidence(expectation: expectation, position: position)
            finishOperation(
                code: operationCode,
                operationId: operationId,
                title: title,
                evidence: evidence,
                assertion: false,
                file: file,
                line: line,
                function: function
            )
            return component
        }
    }

    /// Polls fresh UI snapshots, emits a bounded lifecycle, and optionally fails on mismatch.
    ///
    /// - Parameters:
    ///   - operationCode: Stable collection operation code.
    ///   - titleKey: Localization key for the default Allure title.
    ///   - titleArguments: Optional localization arguments.
    ///   - expectation: Stable evidence expectation.
    ///   - expectedCount: Optional exact or boundary count written to evidence.
    ///   - includeDisplayed: Whether each snapshot must classify every current component.
    ///   - timeout: Maximum polling interval.
    ///   - assertion: Whether terminal mismatch records an XCTest failure.
    ///   - file: Call-site file.
    ///   - line: Call-site line.
    ///   - function: Call-site function.
    ///   - matches: Predicate defining success.
    /// - Returns: Complete bounded observation result.
    private func observe(
        operationCode: String,
        titleKey: String,
        titleArguments: [CVarArg] = [],
        expectation: String,
        expectedCount: Int?,
        includeDisplayed: Bool,
        timeout: TimeInterval,
        assertion: Bool,
        file: StaticString,
        line: UInt,
        function: StaticString,
        matches: @escaping (XCEasyCollectionSnapshot) -> Bool
    ) -> ObservationResult<XCEasyCollectionSnapshot> {
        let title = localizedTitle(key: titleKey, arguments: titleArguments)
        let operationId = beginOperation(
            code: operationCode,
            title: title,
            file: file,
            line: line,
            function: function
        )
        return step(title) {
            let result = ObservationEngine().observe(
                timeout: timeout,
                interval: Self.observationInterval,
                sample: { snapshotProvider(includeDisplayed) },
                matches: { snapshot in
                    snapshot.isContextAvailable && matches(snapshot)
                }
            )
            let evidence = observationEvidence(
                expectation: expectation,
                expectedCount: expectedCount,
                result: result,
                includeDisplayed: includeDisplayed
            )
            finishOperation(
                code: operationCode,
                operationId: operationId,
                title: title,
                evidence: evidence,
                assertion: assertion,
                file: file,
                line: line,
                function: function
            )
            if assertion, !result.matched {
                let message = localizedTitle(
                    key: "component_collection_assertion_failed",
                    arguments: [title, result.last.count]
                )
                XCEasyTestLogger.shared.log(message, level: .error)
                recordAssertionFailure(
                    message,
                    expected: expectation,
                    actual: "count=\(result.last.count)",
                    file: file,
                    line: line
                )
            }
            return result
        }
    }

    /// Starts one canonical component-collection lifecycle.
    ///
    /// - Parameters:
    ///   - code: Stable operation code.
    ///   - title: Localized human-readable title.
    ///   - file: Call-site file.
    ///   - line: Call-site line.
    ///   - function: Call-site function.
    /// - Returns: Unique operation identifier used by the terminal event.
    private func beginOperation(
        code: String,
        title: String,
        file: StaticString,
        line: UInt,
        function: StaticString
    ) -> String {
        let operationId = UUID().uuidString.lowercased()
        XCEasyTestLogger.shared.event(DiagnosticEvent(
            event: "ui.collection.started",
            testId: XCEasyTestContext.shared.testId,
            operationCode: code,
            operationId: operationId,
            statusCode: "running",
            target: Component.defaultComponentName,
            title: title,
            selector: Component.collection.locatorDescriptor,
            source: DiagnosticSource(
                file: String(describing: file),
                line: Int(line),
                function: String(describing: function)
            )
        ))
        return operationId
    }

    /// Finishes one canonical component-collection lifecycle and enforces timing policy.
    ///
    /// - Parameters:
    ///   - code: Stable operation code.
    ///   - operationId: Identifier returned by ``beginOperation(code:title:file:line:function:)``.
    ///   - title: Localized human-readable title.
    ///   - evidence: Bounded selection or polling evidence.
    ///   - assertion: Whether mismatch represents a failing assertion.
    ///   - file: Call-site file.
    ///   - line: Call-site line.
    ///   - function: Call-site function.
    private func finishOperation(
        code: String,
        operationId: String,
        title: String,
        evidence: XCEasyCollectionEvidence,
        assertion: Bool,
        file: StaticString,
        line: UInt,
        function: StaticString
    ) {
        let matched = evidence.matched
        let level = matched ? "info" : (assertion ? "error" : "warning")
        let status = matched ? "passed" : (assertion ? "failed" : "not_matched")
        let reason: String
        if matched {
            reason = evidence.attempts == 0 ? "collection.locator_intent_created" : "collection.expected_state_observed"
        } else if evidence.isContextAvailable == false {
            reason = "collection.context_unavailable"
        } else {
            reason = "collection.state_not_matched"
        }
        let attachments = matched
            ? []
            : XCEasyTestLogger.shared.captureUIFailureEvidence(producerEventId: operationId)
        XCEasyTestLogger.shared.event(DiagnosticEvent(
            event: "ui.collection.finished",
            level: level,
            testId: XCEasyTestContext.shared.testId,
            operationCode: code,
            operationId: operationId,
            statusCode: status,
            reasonCode: reason,
            durationMilliseconds: evidence.elapsedMilliseconds,
            target: Component.defaultComponentName,
            title: title,
            selector: Component.collection.locatorDescriptor,
            collectionEvidence: evidence,
            source: DiagnosticSource(
                file: String(describing: file),
                line: Int(line),
                function: String(describing: function)
            ),
            attachments: attachments.isEmpty ? nil : attachments,
            performance: diagnosticPerformanceEvidence(
                operationKey: code,
                durationMilliseconds: evidence.elapsedMilliseconds,
                phasesMilliseconds: ["observe": evidence.elapsedMilliseconds]
            )
        ))
        enforcePerformanceBudget(
            operationKey: code,
            durationMilliseconds: evidence.elapsedMilliseconds,
            parentOperationId: operationId
        )
    }

    /// Builds evidence for a lazy selection without reading the UI.
    ///
    /// - Parameters:
    ///   - expectation: Stable selection expectation.
    ///   - position: Selected symbolic or indexed position.
    /// - Returns: Canonical selection evidence with zero polling attempts.
    private func selectionEvidence(
        expectation: String,
        position: XCEasyComponentPosition
    ) -> XCEasyCollectionEvidence {
        let selectedPosition: String
        let selectedIndex: Int?
        switch position {
        case .first:
            selectedPosition = "first"
            selectedIndex = 0
        case .last:
            selectedPosition = "last"
            selectedIndex = nil
        case .index(let index):
            selectedPosition = "index"
            selectedIndex = index
        }
        return XCEasyCollectionEvidence(
            expectation: expectation,
            expectedCount: nil,
            actualCount: nil,
            matched: true,
            attempts: 0,
            elapsedMilliseconds: 0,
            selectedPosition: selectedPosition,
            selectedIndex: selectedIndex,
            selectedIndices: nil,
            displayedCount: nil,
            failedIndices: nil,
            isContextAvailable: nil,
            observations: nil
        )
    }

    /// Converts a polling result into bounded AI-readable collection evidence.
    ///
    /// - Parameters:
    ///   - expectation: Stable state expectation.
    ///   - expectedCount: Optional requested count or boundary.
    ///   - result: Polling result to encode.
    ///   - includeDisplayed: Whether display classifications are meaningful.
    /// - Returns: Bounded canonical collection evidence.
    private func observationEvidence(
        expectation: String,
        expectedCount: Int?,
        result: ObservationResult<XCEasyCollectionSnapshot>,
        includeDisplayed: Bool
    ) -> XCEasyCollectionEvidence {
        let failedIndices = failedIndices(
            count: result.last.count,
            displayedIndices: result.last.displayedIndices,
            includeDisplayed: includeDisplayed
        )
        let observations = compactTimeline(result.samples, includeDisplayed: includeDisplayed)
        return XCEasyCollectionEvidence(
            expectation: expectation,
            expectedCount: expectedCount,
            actualCount: result.last.count,
            matched: result.matched,
            attempts: result.attempts,
            elapsedMilliseconds: result.elapsedMilliseconds,
            selectedPosition: nil,
            selectedIndex: nil,
            selectedIndices: nil,
            displayedCount: includeDisplayed ? result.last.displayedIndices.count : nil,
            failedIndices: failedIndices,
            isContextAvailable: result.last.isContextAvailable,
            observations: observations
        )
    }

    /// Retains state changes and the terminal sample while enforcing the evidence bound.
    ///
    /// - Parameters:
    ///   - samples: Raw polling samples.
    ///   - includeDisplayed: Whether display classifications are meaningful.
    /// - Returns: At most 50 compact observations.
    private func compactTimeline(
        _ samples: [ObservationSample<XCEasyCollectionSnapshot>],
        includeDisplayed: Bool
    ) -> [XCEasyCollectionEvidence.Observation] {
        var observations: [XCEasyCollectionEvidence.Observation] = []
        for sample in samples {
            let failedIndices = failedIndices(
                count: sample.value.count,
                displayedIndices: sample.value.displayedIndices,
                includeDisplayed: includeDisplayed
            )
            let observation = XCEasyCollectionEvidence.Observation(
                attempt: sample.attempt,
                elapsedMilliseconds: sample.elapsedMilliseconds,
                count: sample.value.count,
                displayedCount: includeDisplayed ? sample.value.displayedIndices.count : nil,
                failedIndices: failedIndices,
                isContextAvailable: sample.value.isContextAvailable
            )
            let isTerminal = sample.attempt == samples.last?.attempt
            let changed = observations.last?.count != observation.count
                || observations.last?.displayedCount != observation.displayedCount
                || observations.last?.isContextAvailable != observation.isContextAvailable
            guard changed || isTerminal else { continue }
            if observations.count < Self.timelineLimit {
                observations.append(observation)
            } else if isTerminal {
                observations[Self.timelineLimit - 1] = observation
            }
        }
        return observations
    }

    /// Calculates a bounded list of items that are not currently displayed.
    ///
    /// - Parameters:
    ///   - count: Current collection size.
    ///   - displayedIndices: Zero-based indices classified as displayed.
    ///   - includeDisplayed: Whether visibility was requested for this operation.
    /// - Returns: At most 100 sorted failing indices, or `nil` when visibility was not sampled.
    private func failedIndices(
        count: Int,
        displayedIndices: [Int],
        includeDisplayed: Bool
    ) -> [Int]? {
        guard includeDisplayed else { return nil }
        return Array(
            Set(0..<max(0, count))
                .subtracting(displayedIndices)
                .sorted()
                .prefix(Self.loggedIndexLimit)
        )
    }

    /// Resolves one localization key using the configured per-test language.
    ///
    /// - Parameters:
    ///   - key: String-catalog key.
    ///   - arguments: Optional format arguments.
    /// - Returns: Localized human-readable operation title.
    private func localizedTitle(key: String, arguments: [CVarArg] = []) -> String {
        LocalizationManager.shared.string(forKey: key, arguments: arguments)
    }
}

private extension XCEasyUIElement {
    /// Captures the current count and optional visibility state for every matching element.
    ///
    /// - Parameter includeDisplayed: Whether to classify each current match as displayed.
    /// - Returns: Fresh collection snapshot. Missing test context is represented explicitly.
    func collectionSnapshot(includeDisplayed: Bool) -> XCEasyCollectionSnapshot {
        let evaluation = queryEvaluation(collectCandidateCount: true)
        guard evaluation.isContextAvailable, let query = evaluation.filteredQuery else {
            return XCEasyCollectionSnapshot(
                count: 0,
                displayedIndices: [],
                isContextAvailable: false
            )
        }
        let count = max(0, query.count)
        guard includeDisplayed, count > 0 else {
            return XCEasyCollectionSnapshot(
                count: count,
                displayedIndices: [],
                isContextAvailable: true
            )
        }
        let applicationFrame = application?.frame
        var displayedIndices: [Int] = []
        for index in 0..<count {
            let element = query.element(boundBy: index)
            guard element.exists else { continue }
            if element.isHittable {
                displayedIndices.append(index)
                continue
            }
            let visibility = XCEasyVisibilityEvaluator.evaluate(
                elementFrame: element.frame,
                applicationFrame: applicationFrame,
                policy: XCEasyConfig.visibilityPolicy
            )
            if visibility.isVisible {
                displayedIndices.append(index)
            }
        }
        return XCEasyCollectionSnapshot(
            count: count,
            displayedIndices: displayedIndices,
            isContextAvailable: true
        )
    }
}
