import CoreGraphics
import Foundation
import XCTest

// MARK: - Basic Actions

public extension XCEasyUIElement {

    // MARK: - Properties

    /// The localization manager instance.
    private var localizationManager: LocalizationManaging {
        XCDependencyContainer.shared.localizationManager
    }

    /// Taps the element after waiting for the state required by the effective action policy.
    ///
    /// - Parameters:
    ///   - timeout: Maximum interval for the readiness observation.
    ///   - policy: Per-call policy override, or `nil` to use ``XCEasyConfig/actionPolicy``.
    ///   - file: Compiler-provided call-site file used for a readiness failure.
    ///   - line: Compiler-provided call-site line used for a readiness failure.
    /// - Returns: The lazy element proxy for fluent calls.
    @discardableResult
    func tap(
        timeout: TimeInterval = XCEasyConfig.actionTimeout,
        policy: XCEasyActionPolicy? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let stepTitle = localizationManager
            .string(forKey: "tap_on_element_title", arguments: [self.desc])
        performConfiguredAction(
            code: "ui.tap",
            title: stepTitle,
            timeout: timeout,
            policy: policy,
            file: file,
            line: line,
            semantic: { $0.tap() },
            coordinate: { self.centerCoordinate(of: $0).tap() }
        )
        return self
    }

    /// Double taps the element after policy-controlled readiness observation.
    ///
    /// - Parameters:
    ///   - timeout: Maximum interval for the readiness observation.
    ///   - policy: Per-call policy override, or `nil` to use the configured default.
    ///   - file: Compiler-provided call-site file used for a readiness failure.
    ///   - line: Compiler-provided call-site line used for a readiness failure.
    /// - Returns: The lazy element proxy for fluent calls.
    @discardableResult
    func doubleTap(
        timeout: TimeInterval = XCEasyConfig.actionTimeout,
        policy: XCEasyActionPolicy? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let stepTitle = localizationManager
            .string(forKey: "double_tap_on_element_title", arguments: [self.desc])
        performConfiguredAction(
            code: "ui.double_tap",
            title: stepTitle,
            timeout: timeout,
            policy: policy,
            file: file,
            line: line,
            semantic: { $0.doubleTap() },
            coordinate: { self.centerCoordinate(of: $0).doubleTap() }
        )
        return self
    }

    /// Presses the element for a specified duration.
    ///
    /// - Parameters:
    ///   - duration: The duration to press the element.
    ///   - timeout: Maximum interval for the readiness observation.
    ///   - policy: Per-call policy override, or `nil` to use the configured default.
    ///   - file: Compiler-provided call-site file used for a readiness failure.
    ///   - line: Compiler-provided call-site line used for a readiness failure.
    /// - Returns: The lazy element proxy for fluent calls.
    @discardableResult
    func press(
        forDuration duration: TimeInterval,
        timeout: TimeInterval = XCEasyConfig.actionTimeout,
        policy: XCEasyActionPolicy? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let stepTitle = localizationManager
            .string(forKey: "press_on_element_title", arguments: [duration, self.desc])
        performConfiguredAction(
            code: "ui.press",
            title: stepTitle,
            timeout: timeout,
            policy: policy,
            file: file,
            line: line,
            semantic: { $0.press(forDuration: duration) },
            coordinate: { self.centerCoordinate(of: $0).press(forDuration: duration) }
        )
        return self
    }

    /// Performs a swipe gesture on an element in the specified direction.
    ///
    /// - Parameters:
    ///   - direction: Direction in which to perform the gesture.
    ///   - timeout: Maximum interval for the readiness observation.
    ///   - policy: Per-call policy override, or `nil` to use the configured default.
    ///   - file: Compiler-provided call-site file used for a readiness failure.
    ///   - line: Compiler-provided call-site line used for a readiness failure.
    /// - Returns: The lazy element proxy for fluent calls.
    @discardableResult
    func swipe(
        _ direction: SwipeDirection,
        timeout: TimeInterval = XCEasyConfig.actionTimeout,
        policy: XCEasyActionPolicy? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let directionTitle = localizedTitle(for: direction)
        let stepTitle = localizationManager
            .string(forKey: "swipe_element_title", arguments: [directionTitle, self.desc])
        performConfiguredAction(
            code: "ui.swipe.\(direction.operationCode)",
            title: stepTitle,
            timeout: timeout,
            policy: policy,
            file: file,
            line: line,
            semantic: { self.performSemanticSwipe(direction, on: $0) },
            coordinate: { self.performCoordinateSwipe(direction, on: $0) }
        )
        return self
    }

    /// Types text into the element.
    ///
    /// The action focuses the element through the selected semantic or coordinate dispatch before
    /// sending text. Text is never included in action diagnostics.
    ///
    /// - Parameters:
    ///   - text: Text to enter. It is not written to logs or diagnostic events.
    ///   - timeout: Maximum interval for the readiness observation.
    ///   - policy: Per-call policy override, or `nil` to use the configured default.
    ///   - file: Compiler-provided call-site file used for a readiness failure.
    ///   - line: Compiler-provided call-site line used for a readiness failure.
    /// - Returns: The lazy element proxy for fluent calls.
    @discardableResult
    func typeText(
        _ text: String,
        timeout: TimeInterval = XCEasyConfig.actionTimeout,
        policy: XCEasyActionPolicy? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let stepTitle = localizationManager
            .string(forKey: "type_text_to_element_title", arguments: [self.desc])
        performConfiguredAction(
            code: "ui.type_text",
            title: stepTitle,
            timeout: timeout,
            policy: policy,
            file: file,
            line: line,
            semantic: {
                $0.tap()
                $0.typeText(text)
            },
            coordinate: {
                self.centerCoordinate(of: $0).tap()
                $0.typeText(text)
            }
        )
        return self
    }

    /// Waits until the element is displayed without creating an XCTest assertion failure.
    ///
    /// Every polling attempt resolves the locator again against the current accessibility tree.
    /// The method returns immediately after observing either a visible or hittable state. A
    /// timeout is recorded in query diagnostics but does not fail the test.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: `true` when the element became displayed, or `false` after the timeout.
    ///
    /// ```swift
    /// if promoBanner.waitForDisplayed(timeout: 5) {
    ///     promoBanner.child(identifier: "promoBanner.closeButton").tap()
    /// }
    /// ```
    @discardableResult
    func waitForDisplayed(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        isDisplayed(timeout: timeout, parentOperationId: nil)
    }

    /// Waits until XCUI reports that the element can receive an interaction.
    ///
    /// Every polling attempt resolves the locator from the current accessibility tree. The method
    /// returns immediately when `isHittable` becomes `true`. A timeout returns `false` and leaves
    /// diagnostic evidence without creating an XCTest assertion failure.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: `true` when the element became hittable, or `false` after the timeout.
    ///
    /// ```swift
    /// guard submitButton.waitForHittable(timeout: 5) else { return }
    /// submitButton.tap()
    /// ```
    @discardableResult
    func waitForHittable(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        isHittable(timeout: timeout, parentOperationId: nil)
    }

    /// Waits until XCUI reports that the element is enabled.
    ///
    /// Every polling attempt resolves the locator from the current accessibility tree. The method
    /// returns immediately when `isEnabled` becomes `true`. A timeout returns `false` and leaves
    /// diagnostic evidence without creating an XCTest assertion failure.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: `true` when the element became enabled, or `false` after the timeout.
    ///
    /// ```swift
    /// guard submitButton.waitForEnabled(timeout: 5) else { return }
    /// submitButton.tap()
    /// ```
    @discardableResult
    func waitForEnabled(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        isEnabled(timeout: timeout, parentOperationId: nil)
    }

    /// Waits until XCUI reports that the element is selected.
    ///
    /// Every polling attempt resolves the locator from the current accessibility tree. The method
    /// returns immediately when `isSelected` becomes `true`. A timeout returns `false` and leaves
    /// diagnostic evidence without creating an XCTest assertion failure.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: `true` when the element became selected, or `false` after the timeout.
    ///
    /// ```swift
    /// filterChip.tap()
    /// guard filterChip.waitForSelected(timeout: 2) else { return }
    /// ```
    @discardableResult
    func waitForSelected(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        isSelected(timeout: timeout, parentOperationId: nil)
    }

    /// Checks if the element exists.
    ///
    /// - Returns: A Boolean value indicating whether the element exists.
    @discardableResult
    func isExists(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        isExists(timeout: timeout, parentOperationId: nil)
    }

    /// Checks if the element does not exist.
    ///
    /// - Returns: A Boolean value indicating whether the element does not exist.
    @discardableResult
    func isNotExists(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        isNotExists(timeout: timeout, parentOperationId: nil)
    }

    /// Checks if the element is hittable.
    ///
    /// - Returns: A Boolean value indicating whether the element is hittable.
    @discardableResult
    func isHittable(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        isHittable(timeout: timeout, parentOperationId: nil)
    }

    /// Checks if the element is not hittable.
    ///
    /// - Returns: A Boolean value indicating whether the element is not hittable.
    @discardableResult
    func isNotHittable(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        isNotHittable(timeout: timeout, parentOperationId: nil)
    }

    /// Checks whether the element is currently shown on screen.
    ///
    /// The check succeeds only when the element exists in the current accessibility tree and
    /// its frame satisfies ``XCEasyConfig/visibilityPolicy``.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: `true` when the element is displayed.
    @discardableResult
    func isDisplayed(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        isDisplayed(timeout: timeout, parentOperationId: nil)
    }

    /// Checks that the element is not currently shown on screen.
    ///
    /// Both valid situations are accepted: the element is absent from the accessibility tree,
    /// or it still exists there but is hidden or outside the configured visible area.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: `true` when the element is not displayed.
    @discardableResult
    func isNotDisplayed(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        isNotDisplayed(timeout: timeout, parentOperationId: nil)
    }

    /// Requires the element to remain present but not visible.
    @discardableResult
    func isHidden(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        isHidden(timeout: timeout, parentOperationId: nil)
    }

    /// Checks if the element is enabled.
    ///
    /// - Returns: A Boolean value indicating whether the element is enabled.
    @discardableResult
    func isEnabled(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        isEnabled(timeout: timeout, parentOperationId: nil)
    }

    /// Checks if the element is disabled.
    ///
    /// - Returns: A Boolean value indicating whether the element is disabled.
    @discardableResult
    func isDisabled(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        isDisabled(timeout: timeout, parentOperationId: nil)
    }

    /// Checks if the element is selected.
    ///
    /// - Returns: A Boolean value indicating whether the element is selected.
    @discardableResult
    func isSelected(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        isSelected(timeout: timeout, parentOperationId: nil)
    }

    /// Checks if the element is not selected.
    ///
    /// - Returns: A Boolean value indicating whether the element is not selected.
    @discardableResult
    func isNotSelected(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        isNotSelected(timeout: timeout, parentOperationId: nil)
    }

    /// Returns the element `label` with implicit wait.
    ///
    /// This method waits until the element exists within the provided timeout,
    /// then returns the element label.
    ///
    /// - Parameter timeout: The maximum amount of time to wait for the element to exist.
    /// - Returns: The element label.
    @discardableResult
    func getLabel(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> String {
        return resolve().waitForExists(timeout: timeout).label
    }

    /// Returns the element `value` with implicit wait.
    ///
    /// This method waits until the element exists within the provided timeout,
    /// then safely converts `value` to `String`.
    ///
    /// - Parameter timeout: The maximum amount of time to wait for the element to exist.
    /// - Returns: The string representation of the element value.
    @discardableResult
    func getValue(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> String {
        let element = resolve().waitForExists(timeout: timeout)

        guard let rawValue = element.value else {
            fail("Element value is nil for \(self.desc)")
            return String.empty
        }

        if let value = rawValue as? String {
            return value
        }

        return String(describing: rawValue)
    }

    /// Clears text in an input field by sending delete key presses.
    ///
    /// The number of delete key presses is based on the current element value length.
    ///
    /// - Parameters:
    ///   - timeout: Maximum interval for the readiness observation.
    ///   - policy: Per-call policy override, or `nil` to use the configured default.
    ///   - file: Compiler-provided call-site file used for a readiness failure.
    ///   - line: Compiler-provided call-site line used for a readiness failure.
    /// - Returns: Self for method chaining.
    @discardableResult
    func clearField(
        timeout: TimeInterval = XCEasyConfig.actionTimeout,
        policy: XCEasyActionPolicy? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let stepTitle = localizationManager
            .string(forKey: "clear_text_field")
        performConfiguredAction(
            code: "ui.clear_text",
            title: stepTitle,
            timeout: timeout,
            policy: policy,
            file: file,
            line: line,
            semantic: { try self.clearText(in: $0, coordinateFocus: false) },
            coordinate: { try self.clearText(in: $0, coordinateFocus: true) }
        )
        return self
    }

    /// Prints the element's debug tree description.
    @discardableResult
    func printDebugTree() -> Self {
        print(resolve().debugDescription)
        return self
    }
}

private extension XCEasyUIElement {
    static let coordinateSwipePressDuration: TimeInterval = 0.05

    /// Executes one UI action with a fresh, policy-specific readiness observation.
    ///
    /// - Parameters:
    ///   - code: Stable operation code written to diagnostics and performance summaries.
    ///   - title: Localized Allure and human-log title.
    ///   - timeout: Maximum readiness observation interval.
    ///   - policy: Per-call override, or `nil` for the execution-scoped default.
    ///   - file: Original caller file used if readiness fails.
    ///   - line: Original caller line used if readiness fails.
    ///   - semantic: Action dispatched through `XCUIElement` after a hittable wait.
    ///   - coordinate: Action dispatched through coordinates after a displayed wait.
    func performConfiguredAction(
        code: String,
        title: String,
        timeout: TimeInterval,
        policy: XCEasyActionPolicy?,
        file: StaticString,
        line: UInt,
        semantic: (XCUIElement) throws -> Void,
        coordinate: (XCUIElement) throws -> Void
    ) {
        let effectivePolicy = policy ?? XCEasyConfig.actionPolicy
        let plan = XCEasyActionPlan(policy: effectivePolicy)
        var parentOperationId: String?

        do {
            try operationStepWithContext(code: code, title: title, target: desc) { operationId in
                parentOperationId = operationId
                reportActionPolicy(
                    effectivePolicy,
                    plan: plan,
                    code: code,
                    operationId: operationId
                )
                let observation = observe(
                    expectedState: plan.expectedState.rawValue,
                    timeout: timeout,
                    parentOperationId: operationId
                ) { plan.accepts($0.state) }
                guard observation.matched,
                      let element = observation.last.element else {
                    let message = localizationManager.string(
                        forKey: "ui_action_not_ready_error",
                        arguments: [desc, effectivePolicy.rawValue, timeout]
                    )
                    throw XCEasyFrameworkError(
                        code: "ui.action.target_not_ready",
                        safeDescription: message
                    )
                }

                reportActionDispatch(plan.dispatch, code: code, operationId: operationId)
                switch plan.dispatch {
                case .semantic:
                    try semantic(element)
                case .coordinate:
                    try coordinate(element)
                }
            }
        } catch let error as XCEasyFrameworkError {
            recordFrameworkFailure(
                error,
                operationId: parentOperationId,
                file: file,
                line: line
            )
        } catch {
            recordFrameworkFailure(
                XCEasyFrameworkError(
                    code: "ui.action.unexpected_error",
                    safeDescription: SensitiveDataRedactor.redact(String(describing: error))
                ),
                operationId: parentOperationId,
                file: file,
                line: line
            )
        }
    }

    /// Emits canonical and human-readable evidence for the selected action policy.
    ///
    /// - Parameters:
    ///   - policy: Effective action policy.
    ///   - plan: Derived wait-and-dispatch plan.
    ///   - code: Owning action operation code.
    ///   - operationId: Owning action operation identifier.
    func reportActionPolicy(
        _ policy: XCEasyActionPolicy,
        plan: XCEasyActionPlan,
        code: String,
        operationId: String
    ) {
        XCEasyTestLogger.shared.log(
            "action_policy=\(policy.rawValue) waited_state=\(plan.expectedState.rawValue) "
                + "dispatch=\(plan.dispatch.rawValue) operation=\(code) target=\(desc)"
        )
        XCEasyTestLogger.shared.event(DiagnosticEvent(
            event: "ui.action.policy",
            level: policy == .displayed ? "warning" : "info",
            testId: XCEasyTestContext.shared.testId,
            operationCode: code,
            operationId: operationId,
            statusCode: "selected",
            reasonCode: "action.policy.\(policy.rawValue)",
            target: desc,
            selector: locatorDescriptor
        ))
    }

    /// Emits the actual semantic or coordinate dispatch mechanism.
    ///
    /// - Parameters:
    ///   - dispatch: Dispatch selected by the action plan.
    ///   - code: Owning action operation code.
    ///   - operationId: Owning action operation identifier.
    func reportActionDispatch(
        _ dispatch: XCEasyActionPlan.Dispatch,
        code: String,
        operationId: String
    ) {
        XCEasyTestLogger.shared.event(DiagnosticEvent(
            event: "ui.action.dispatched",
            level: dispatch == .coordinate ? "warning" : "info",
            testId: XCEasyTestContext.shared.testId,
            operationCode: code,
            operationId: operationId,
            statusCode: "passed",
            reasonCode: "action.dispatch.\(dispatch.rawValue)",
            target: desc,
            selector: locatorDescriptor
        ))
    }

    /// Returns the center coordinate for an already observed element.
    ///
    /// - Parameter element: Fresh target element from the readiness observation.
    /// - Returns: Coordinate at the center of the element frame.
    func centerCoordinate(of element: XCUIElement) -> XCUICoordinate {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    }

    /// Performs a semantic XCUI swipe in the requested direction.
    ///
    /// - Parameters:
    ///   - direction: Requested swipe direction.
    ///   - element: Fresh target element.
    func performSemanticSwipe(_ direction: SwipeDirection, on element: XCUIElement) {
        switch direction {
        case .up:
            element.swipeUp()
        case .down:
            element.swipeDown()
        case .left:
            element.swipeLeft()
        case .right:
            element.swipeRight()
        }
    }

    /// Performs a coordinate drag that represents a swipe inside the target frame.
    ///
    /// - Parameters:
    ///   - direction: Requested swipe direction.
    ///   - element: Fresh displayed target element.
    func performCoordinateSwipe(_ direction: SwipeDirection, on element: XCUIElement) {
        let offsets = direction.coordinateOffsets
        let start = element.coordinate(withNormalizedOffset: offsets.start)
        let end = element.coordinate(withNormalizedOffset: offsets.end)
        start.press(forDuration: Self.coordinateSwipePressDuration, thenDragTo: end)
    }

    /// Focuses a field, then deletes its current string value without logging that value.
    ///
    /// - Parameters:
    ///   - element: Fresh field element from the readiness observation.
    ///   - coordinateFocus: Whether focus must be requested through the element center coordinate.
    /// - Throws: `XCEasyFrameworkError` when the field exposes no value.
    func clearText(in element: XCUIElement, coordinateFocus: Bool) throws {
        guard let rawValue = element.value else {
            throw XCEasyFrameworkError(
                code: "ui.clear_text.value_missing",
                safeDescription: localizationManager.string(
                    forKey: "element_value_missing_error",
                    arguments: [desc]
                )
            )
        }
        let currentValue = rawValue as? String ?? String(describing: rawValue)
        guard !currentValue.isEmpty else { return }

        if coordinateFocus {
            centerCoordinate(of: element).tap()
        } else {
            element.tap()
        }
        let deleteText = String(
            repeating: XCUIKeyboardKey.delete.rawValue,
            count: currentValue.count
        )
        element.typeText(deleteText)
    }

    /// Resolves the localized direction title used in a human-readable swipe step.
    ///
    /// - Parameter direction: Requested swipe direction.
    /// - Returns: Localized direction name.
    func localizedTitle(for direction: SwipeDirection) -> String {
        localizationManager.string(forKey: direction.localizationKey)
    }
}

private extension XCEasyUIElement.SwipeDirection {
    /// Stable operation-code suffix for swipe diagnostics.
    var operationCode: String {
        switch self {
        case .up: return "up"
        case .down: return "down"
        case .left: return "left"
        case .right: return "right"
        }
    }

    /// Localization key for the human-readable direction title.
    var localizationKey: String {
        switch self {
        case .up: return "up_direction"
        case .down: return "down_direction"
        case .left: return "left_direction"
        case .right: return "right_direction"
        }
    }

    /// Start and end offsets used by displayed-policy coordinate dispatch.
    var coordinateOffsets: (start: CGVector, end: CGVector) {
        switch self {
        case .up:
            return (CGVector(dx: 0.5, dy: 0.8), CGVector(dx: 0.5, dy: 0.2))
        case .down:
            return (CGVector(dx: 0.5, dy: 0.2), CGVector(dx: 0.5, dy: 0.8))
        case .left:
            return (CGVector(dx: 0.8, dy: 0.5), CGVector(dx: 0.2, dy: 0.5))
        case .right:
            return (CGVector(dx: 0.2, dy: 0.5), CGVector(dx: 0.8, dy: 0.5))
        }
    }
}

extension XCEasyUIElement {
    /// Observes whether the element exists while preserving the parent operation relationship.
    ///
    /// - Parameters:
    ///   - timeout: Maximum observation interval in seconds.
    ///   - parentOperationId: Optional action/assertion event that owns the query.
    /// - Returns: `true` when the current UI tree contains the element.
    internal func isExists(timeout: TimeInterval, parentOperationId: String?) -> Bool {
        observeExistence(expected: true, timeout: timeout, parentOperationId: parentOperationId)
    }

    /// Observes absence without first requiring the element to exist.
    ///
    /// - Parameters:
    ///   - timeout: Maximum observation interval in seconds.
    ///   - parentOperationId: Optional action/assertion event that owns the query.
    /// - Returns: `true` when the element is absent from the current UI tree.
    internal func isNotExists(timeout: TimeInterval, parentOperationId: String?) -> Bool {
        observeExistence(expected: false, timeout: timeout, parentOperationId: parentOperationId)
    }

    /// Observes whether the element reaches the hittable state.
    ///
    /// - Parameters:
    ///   - timeout: Maximum observation interval in seconds.
    ///   - parentOperationId: Optional action/assertion event that owns the query.
    /// - Returns: `true` when the element is present and hittable.
    internal func isHittable(timeout: TimeInterval, parentOperationId: String?) -> Bool {
        observe(
            expectedState: XCEasyElementState.hittable.rawValue,
            timeout: timeout,
            parentOperationId: parentOperationId
        ) { $0.state == .hittable }.matched
    }

    /// Observes either an absent, hidden, visible-but-not-hittable state.
    ///
    /// - Parameters:
    ///   - timeout: Maximum observation interval in seconds.
    ///   - parentOperationId: Optional action/assertion event that owns the query.
    /// - Returns: `true` when the element is not hittable, including when it is absent.
    internal func isNotHittable(timeout: TimeInterval, parentOperationId: String?) -> Bool {
        observe(
            expectedState: "not_hittable",
            timeout: timeout,
            parentOperationId: parentOperationId
        ) { $0.state != .hittable }.matched
    }

    /// Observes whether the element is present and displayed according to the visibility policy.
    ///
    /// - Parameters:
    ///   - timeout: Maximum observation interval in seconds.
    ///   - parentOperationId: Optional action/assertion event that owns the query.
    /// - Returns: `true` for displayed or hittable states.
    internal func isDisplayed(timeout: TimeInterval, parentOperationId: String?) -> Bool {
        observe(
            expectedState: XCEasyElementState.visible.rawValue,
            timeout: timeout,
            parentOperationId: parentOperationId
        ) { $0.state == .visible || $0.state == .hittable }.matched
    }

    /// Observes a state that is not displayed, accepting both hidden and absent elements.
    ///
    /// - Parameters:
    ///   - timeout: Maximum observation interval in seconds.
    ///   - parentOperationId: Optional action/assertion event that owns the query.
    /// - Returns: `true` when nothing is displayed, whether the element is absent or hidden.
    internal func isNotDisplayed(timeout: TimeInterval, parentOperationId: String?) -> Bool {
        observe(
            expectedState: "not_visible",
            timeout: timeout,
            parentOperationId: parentOperationId
        ) { $0.state == .absent || $0.state == .hidden }.matched
    }

    /// Observes the stricter state where the element remains in the tree but is hidden.
    ///
    /// - Parameters:
    ///   - timeout: Maximum observation interval in seconds.
    ///   - parentOperationId: Optional action/assertion event that owns the query.
    /// - Returns: `true` only when the element exists but is hidden.
    internal func isHidden(timeout: TimeInterval, parentOperationId: String?) -> Bool {
        observe(
            expectedState: XCEasyElementState.hidden.rawValue,
            timeout: timeout,
            parentOperationId: parentOperationId
        ) { $0.state == .hidden }.matched
    }

    /// Observes whether an existing element reaches the enabled state.
    ///
    /// - Parameters:
    ///   - timeout: Maximum observation interval in seconds.
    ///   - parentOperationId: Optional action/assertion event that owns the query.
    /// - Returns: `true` when the element exists and XCUI reports it enabled.
    internal func isEnabled(timeout: TimeInterval, parentOperationId: String?) -> Bool {
        observe(
            expectedState: "enabled",
            timeout: timeout,
            parentOperationId: parentOperationId
        ) { observation in
            observation.exists && observation.element?.isEnabled == true
        }.matched
    }

    /// Observes whether an existing element reaches the disabled state.
    ///
    /// - Parameters:
    ///   - timeout: Maximum observation interval in seconds.
    ///   - parentOperationId: Optional action/assertion event that owns the query.
    /// - Returns: `true` when the element exists and XCUI reports it disabled.
    internal func isDisabled(timeout: TimeInterval, parentOperationId: String?) -> Bool {
        observe(
            expectedState: "disabled",
            timeout: timeout,
            parentOperationId: parentOperationId
        ) { observation in
            observation.exists && observation.element?.isEnabled == false
        }.matched
    }

    /// Observes whether an existing element reaches the selected state.
    ///
    /// - Parameters:
    ///   - timeout: Maximum observation interval in seconds.
    ///   - parentOperationId: Optional action/assertion event that owns the query.
    /// - Returns: `true` when the element exists and XCUI reports it selected.
    internal func isSelected(timeout: TimeInterval, parentOperationId: String?) -> Bool {
        observe(
            expectedState: "selected",
            timeout: timeout,
            parentOperationId: parentOperationId
        ) { observation in
            observation.exists && observation.element?.isSelected == true
        }.matched
    }

    /// Observes whether an existing element reaches the not-selected state.
    ///
    /// - Parameters:
    ///   - timeout: Maximum observation interval in seconds.
    ///   - parentOperationId: Optional action/assertion event that owns the query.
    /// - Returns: `true` when the element exists and XCUI reports it not selected.
    internal func isNotSelected(timeout: TimeInterval, parentOperationId: String?) -> Bool {
        observe(
            expectedState: "not_selected",
            timeout: timeout,
            parentOperationId: parentOperationId
        ) { observation in
            observation.exists && observation.element?.isSelected == false
        }.matched
    }
}
