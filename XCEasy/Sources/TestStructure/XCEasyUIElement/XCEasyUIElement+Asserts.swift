import Foundation
import XCTest

// MARK: - Assert Methods

extension XCEasyUIElement {

    // MARK: - Properties

    /// The localization manager instance.
    private var localizationManager: LocalizationManaging {
        XCDependencyContainer.shared.localizationManager
    }

    /// Asserts that the element exists.
    ///
    /// - Parameter timeout: The maximum time to wait for the element to exist.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func assertExists(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        let stepTitle = localizationManager
            .string(forKey: "assert_is_exists_title", arguments: [self.desc])
        operationAssertionWithContext(code: "assert.exists", title: stepTitle, target: desc) { operationId in
            self.isExists(timeout: timeout, parentOperationId: operationId)
        }
        return self
    }

    /// Asserts that the element does not exist.
    ///
    /// - Parameter timeout: The maximum time to wait.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func assertDoesNotExist(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        let stepTitle = localizationManager
            .string(forKey: "assert_is_not_exists_title", arguments: [self.desc])
        operationAssertionWithContext(code: "assert.does_not_exist", title: stepTitle, target: desc) { operationId in
            self.isNotExists(timeout: timeout, parentOperationId: operationId)
        }
        return self
    }

    /// Asserts that the element is selected.
    ///
    /// - Parameter timeout: The maximum time to wait.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func assertIsSelected(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        let stepTitle = localizationManager
            .string(forKey: "assert_is_selected_title", arguments: [self.desc])
        operationAssertionWithContext(code: "assert.selected", title: stepTitle, target: desc) { operationId in
            self.isSelected(timeout: timeout, parentOperationId: operationId)
        }
        return self
    }

    /// Asserts that the element is not selected.
    ///
    /// - Parameter timeout: The maximum time to wait.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func assertIsNotSelected(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> XCEasyUIElement {
        let stepTitle = localizationManager
            .string(forKey: "assert_is_not_selected_title", arguments: [self.desc])
        operationAssertionWithContext(code: "assert.not_selected", title: stepTitle, target: desc) { operationId in
            self.isNotSelected(timeout: timeout, parentOperationId: operationId)
        }
        return self
    }

    /// Asserts that the element is enabled.
    ///
    /// - Parameter timeout: The maximum time to wait.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func assertIsEnabled(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        let stepTitle = localizationManager
            .string(forKey: "assert_is_enabled_title", arguments: [self.desc])
        operationAssertionWithContext(code: "assert.enabled", title: stepTitle, target: desc) { operationId in
            self.isEnabled(timeout: timeout, parentOperationId: operationId)
        }
        return self
    }

    /// Asserts that the element is disabled.
    ///
    /// - Parameter timeout: The maximum time to wait.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func assertIsDisabled(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        let stepTitle = localizationManager
            .string(forKey: "assert_is_not_enabled_title", arguments: [self.desc])
        operationAssertionWithContext(code: "assert.disabled", title: stepTitle, target: desc) { operationId in
            self.isDisabled(timeout: timeout, parentOperationId: operationId)
        }
        return self
    }

    /// Asserts that the element is hittable.
    ///
    /// - Parameter timeout: The maximum time to wait.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func assertIsHittable(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        let stepTitle = localizationManager
            .string(forKey: "assert_is_hittable_title", arguments: [self.desc])
        operationAssertionWithContext(code: "assert.hittable", title: stepTitle, target: desc) { operationId in
            self.isHittable(timeout: timeout, parentOperationId: operationId)
        }
        return self
    }

    /// Asserts that the element cannot currently receive an XCUI interaction.
    ///
    /// Absence, hidden state, and visible-but-not-hittable state all satisfy this assertion.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: The lazy element proxy for fluent calls.
    @discardableResult
    public func assertIsNotHittable(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        let title = localizationManager.string(forKey: "assert_is_not_hittable_title", arguments: [desc])
        operationAssertionWithContext(code: "assert.not_hittable", title: title, target: desc) { operationId in
            self.isNotHittable(timeout: timeout, parentOperationId: operationId)
        }
        return self
    }

    /// Asserts that the element exists in the current accessibility tree and is shown on screen.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: The lazy element proxy for fluent calls.
    @discardableResult
    public func assertIsDisplayed(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        let title = localizationManager.string(forKey: "assert_is_displayed_title", arguments: [desc])
        operationAssertionWithContext(code: "assert.visible", title: title, target: desc) { operationId in
            self.isDisplayed(timeout: timeout, parentOperationId: operationId)
        }
        return self
    }

    /// Asserts that the element is not currently shown on screen.
    ///
    /// This succeeds when the element is absent from the accessibility tree and also when the
    /// element still exists there but is hidden or outside the configured visible area. Use
    /// ``assertIsHidden(timeout:)`` when the element must remain in the tree.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: The lazy element proxy for fluent calls.
    ///
    /// ```swift
    /// find(identifier: "loadingIndicator").assertIsNotDisplayed(timeout: 5)
    /// ```
    @discardableResult
    public func assertIsNotDisplayed(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        let title = localizationManager.string(forKey: "assert_is_not_displayed_title", arguments: [desc])
        operationAssertionWithContext(code: "assert.not_visible", title: title, target: desc) { operationId in
            self.isNotDisplayed(timeout: timeout, parentOperationId: operationId)
        }
        return self
    }

    /// Asserts that the element remains in the UI tree but has a hidden state.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: The lazy element proxy for fluent calls.
    @discardableResult
    public func assertIsHidden(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        let title = localizationManager.string(forKey: "assert_is_hidden_title", arguments: [desc])
        operationAssertionWithContext(code: "assert.hidden", title: title, target: desc) { operationId in
            self.isHidden(timeout: timeout, parentOperationId: operationId)
        }
        return self
    }

    /// Proves a present-to-absent transition caused by `action`.
    @discardableResult
    public func assertDisappears(
        timeout: TimeInterval = XCEasyConfig.assertionTimeout,
        after action: () -> Void
    ) -> Self {
        let title = localizationManager.string(forKey: "assert_disappears_title", arguments: [desc])
        let initial = observe(expectedState: "present", timeout: 0) { $0.state != .absent }.first
        guard initial.state != .absent else {
            operationAssertion(
                code: "assert.disappears",
                title: title,
                target: desc,
                reasonCode: "transition_initial_state_not_observed"
            ) { false }
            return self
        }
        operationStep(code: "action.trigger_disappearance", title: title, target: desc, block: action)
        operationAssertionWithContext(
            code: "assert.disappears",
            title: title,
            target: desc,
            reasonCode: "element_remained_present"
        ) { operationId in
            self.isNotExists(timeout: timeout, parentOperationId: operationId)
        }
        return self
    }

    /// Proves a present-to-hidden transition caused by `action`.
    /// Unlike `assertIsNotDisplayed`, absence does not satisfy this assertion.
    @discardableResult
    public func assertBecomesHidden(
        timeout: TimeInterval = XCEasyConfig.assertionTimeout,
        after action: () -> Void
    ) -> Self {
        let title = localizationManager.string(forKey: "assert_is_hidden_title", arguments: [desc])
        let initial = observe(expectedState: "present", timeout: 0) { $0.state != .absent }.first
        guard initial.state != .absent else {
            operationAssertion(
                code: "assert.becomes_hidden",
                title: title,
                target: desc,
                reasonCode: "transition_initial_state_not_observed"
            ) { false }
            return self
        }
        operationStep(code: "action.trigger_hidden", title: title, target: desc, block: action)
        operationAssertionWithContext(
            code: "assert.becomes_hidden",
            title: title,
            target: desc,
            reasonCode: "element_did_not_become_hidden"
        ) { operationId in
            self.isHidden(timeout: timeout, parentOperationId: operationId)
        }
        return self
    }

    /// Asserts that the element label equals the expected value.
    ///
    /// - Parameters:
    ///   - value: The expected label value.
    ///   - desc: Optional custom description for step/assert text.
    ///   - timeout: The maximum time to wait for the element/value.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func assertLabel(
        value: String,
        desc: String? = nil,
        timeout: TimeInterval = XCEasyConfig.assertionTimeout
    ) -> Self {
        let stepTitle = localizationManager
            .string(forKey: "assert_element_label", arguments: [self.desc, value])
        step(stepTitle) {
            assertEqual(
                actual: self.getLabel(timeout: timeout),
                expected: value
            )
        }
        return self
    }

    /// Asserts that the element value equals the expected text.
    ///
    /// - Parameters:
    ///   - text: The expected value text.
    ///   - desc: Optional custom description for step/assert text.
    ///   - timeout: The maximum time to wait for the element/value.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func assertValue(
        text: String,
        desc: String? = nil,
        timeout: TimeInterval = XCEasyConfig.assertionTimeout
    ) -> Self {
        let stepTitle = localizationManager
            .string(forKey: "assert_element_value", arguments: [self.desc, text])
        step(stepTitle) {
            assertEqual(
                actual: self.getValue(timeout: timeout),
                expected: text
            )
        }
        return self
    }
}
