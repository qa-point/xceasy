import Foundation

/// First-class contract for reusable Page Object components.
///
/// Component properties describe how to find their elements without searching immediately.
/// A fresh search of the current accessibility tree starts only when a test performs an action
/// or assertion, so a retained component remains valid after the screen changes.
public protocol XCEasyComponent {
    /// Lazy locator for the UI element representing this component.
    var element: XCEasyUIElement { get }

    /// Stable semantic name used in Allure steps and canonical diagnostics.
    var componentName: String { get }
}

public extension XCEasyComponent {
    /// Default semantic name derived from the concrete component type.
    static var defaultComponentName: String { String(describing: Self.self) }

    /// Semantic component name used when a POM does not provide an instance-specific name.
    var componentName: String { Self.defaultComponentName }

    /// Waits for the component element to be displayed without failing the test on timeout.
    ///
    /// Child properties are not checked. Every polling attempt resolves ``element`` against
    /// the current accessibility tree.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: `true` when the element became displayed, or `false` after the timeout.
    @discardableResult
    func waitForDisplayed(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        element.waitForDisplayed(timeout: timeout)
    }

    /// Waits for the component element to become hittable without failing the test on timeout.
    ///
    /// Child properties are not checked. Every polling attempt resolves ``element`` against
    /// the current accessibility tree.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: `true` when the element became hittable, or `false` after the timeout.
    @discardableResult
    func waitForHittable(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        element.waitForHittable(timeout: timeout)
    }

    /// Waits for the component element to become enabled without failing the test on timeout.
    ///
    /// Child properties are not checked. Every polling attempt resolves ``element`` against
    /// the current accessibility tree.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: `true` when the element became enabled, or `false` after the timeout.
    @discardableResult
    func waitForEnabled(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        element.waitForEnabled(timeout: timeout)
    }

    /// Waits for the component element to become selected without failing the test on timeout.
    ///
    /// Child properties are not checked. Every polling attempt resolves ``element`` against
    /// the current accessibility tree.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: `true` when the element became selected, or `false` after the timeout.
    @discardableResult
    func waitForSelected(timeout: TimeInterval = XCEasyConfig.actionTimeout) -> Bool {
        element.waitForSelected(timeout: timeout)
    }

    /// Asserts that the component element exists in the current accessibility tree.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: The component, enabling fluent calls.
    @discardableResult
    func assertExists(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        element.assertExists(timeout: timeout)
        return self
    }

    /// Asserts that the component element is absent from the current accessibility tree.
    ///
    /// Absence is a successful observation and does not require a preliminary positive lookup.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: The component, enabling fluent calls.
    ///
    /// ```swift
    /// promoBanner.closeButton.tap()
    /// promoBanner.assertDoesNotExist(timeout: 5)
    /// ```
    @discardableResult
    func assertDoesNotExist(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        element.assertDoesNotExist(timeout: timeout)
        return self
    }

    /// Asserts that the component element is shown on screen.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: The component, enabling fluent calls.
    @discardableResult
    func assertIsDisplayed(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        element.assertIsDisplayed(timeout: timeout)
        return self
    }

    /// Asserts that the component element is not shown on screen.
    ///
    /// The assertion succeeds when the element is absent and also when it remains in the tree but
    /// is hidden. Use ``assertDoesNotExist(timeout:)`` when absence from the tree is required.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: The component, enabling fluent calls.
    @discardableResult
    func assertIsNotDisplayed(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        element.assertIsNotDisplayed(timeout: timeout)
        return self
    }

    /// Asserts that the component element remains in the tree but is not shown on screen.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: The component, enabling fluent calls.
    @discardableResult
    func assertIsHidden(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        element.assertIsHidden(timeout: timeout)
        return self
    }

    /// Asserts that the component element can currently receive an XCUI interaction.
    ///
    /// - Parameter timeout: Maximum observation interval in seconds.
    /// - Returns: The component, enabling fluent calls.
    @discardableResult
    func assertIsHittable(timeout: TimeInterval = XCEasyConfig.assertionTimeout) -> Self {
        element.assertIsHittable(timeout: timeout)
        return self
    }

    /// Proves that the component exists before an action and disappears afterward.
    ///
    /// - Parameters:
    ///   - timeout: Maximum interval for each state observation.
    ///   - action: Action expected to remove the component.
    /// - Returns: The component, enabling fluent calls.
    @discardableResult
    func assertDisappears(
        timeout: TimeInterval = XCEasyConfig.assertionTimeout,
        after action: () -> Void
    ) -> Self {
        element.assertDisappears(timeout: timeout, after: action)
        return self
    }

    /// Executes component-owned work inside the same nested lifecycle as a regular Allure step.
    ///
    /// - Parameters:
    ///   - operation: Human-readable operation appended to ``componentName``.
    ///   - file: Call-site file captured in canonical diagnostics.
    ///   - line: Call-site line captured in canonical diagnostics.
    ///   - function: Call-site function captured in canonical diagnostics.
    ///   - block: Component work whose return value and thrown error are preserved.
    /// - Returns: The value returned by `block`.
    /// - Throws: Rethrows any error produced by `block`.
    ///
    /// ```swift
    /// @discardableResult
    /// func dismiss() -> Self {
    ///     step("Dismiss") { closeButton.tap() }
    ///     return self
    /// }
    /// ```
    @discardableResult
    func step<T>(
        _ operation: String,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function,
        block: () throws -> T
    ) rethrows -> T {
        try executeXCEasyStep(
            "\(componentName): \(operation)",
            metadata: .component(name: componentName, element: element),
            file: file,
            line: line,
            function: function,
            block: block
        )
    }

    /// Executes async component work through the shared task-propagated Allure step lifecycle.
    ///
    /// - Parameters:
    ///   - operation: Human-readable operation appended to ``componentName``.
    ///   - file: Call-site file captured in canonical diagnostics.
    ///   - line: Call-site line captured in canonical diagnostics.
    ///   - function: Call-site function captured in canonical diagnostics.
    ///   - block: Async component work whose return value and error are preserved.
    /// - Returns: Value returned by `block`.
    /// - Throws: Rethrows any error produced by `block`.
    @available(iOS 15.0, *)
    @discardableResult
    func step<T>(
        _ operation: String,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function,
        block: () async throws -> T
    ) async rethrows -> T {
        try await executeXCEasyStep(
            "\(componentName): \(operation)",
            metadata: .component(name: componentName, element: element),
            file: file,
            line: line,
            function: function,
            block: block
        )
    }
}

/// Lazy position of one component inside a repeated UI collection.
///
/// A position stores only locator intent. In particular, ``last`` is resolved from the current
/// accessibility tree every time the returned component is used, so it stays correct when the
/// collection changes after the POM was created.
public enum XCEasyComponentPosition: Equatable, Sendable {
    /// Selects the first current match.
    case first

    /// Selects the last current match.
    case last

    /// Selects one current match by a zero-based index.
    case index(Int)
}

/// Component contract for repeated UI instances addressed by a lazy collection position.
///
/// A conforming POM declares one common locator through ``collection`` and stores the
/// requested position. The framework supplies convenience initializers for index `0` and for
/// calls that omit an instance-specific name.
public protocol XCEasyIndexedComponent: XCEasyComponent {
    /// Common lazy locator matching every component element in the collection.
    static var collection: XCEasyUIElement { get }

    /// Creates a lazy positioned component with optional instance-specific naming.
    ///
    /// - Parameters:
    ///   - position: Symbolic or zero-based position resolved only when the component is used.
    ///   - componentName: Optional semantic instance name. `nil` selects the POM's default name.
    init(position: XCEasyComponentPosition, componentName: String?)
}

public extension XCEasyIndexedComponent {
    /// Returns the default semantic instance name for a lazy collection position.
    ///
    /// The name is derived without reading the UI tree and can be overridden by passing an
    /// explicit `componentName` to a collection getter or initializer.
    ///
    /// - Parameter position: Symbolic or zero-based collection position.
    /// - Returns: A stable human-readable name containing the component type and position.
    static func defaultComponentName(for position: XCEasyComponentPosition) -> String {
        switch position {
        case .first:
            return "First \(defaultComponentName)"
        case .last:
            return "Last \(defaultComponentName)"
        case .index(let index):
            return "\(defaultComponentName) at index \(index)"
        }
    }

    /// Creates the first component instance with its position-aware default semantic name.
    init() {
        self.init(
            position: .first,
            componentName: Self.defaultComponentName(for: .first)
        )
    }

    /// Creates an indexed component with its position-aware default semantic name.
    ///
    /// - Parameter index: Nonnegative zero-based component index.
    init(index: Int) {
        let position = XCEasyComponentPosition.index(index)
        self.init(
            position: position,
            componentName: Self.defaultComponentName(for: position)
        )
    }

    /// Creates an indexed component with an explicit semantic name.
    ///
    /// - Parameters:
    ///   - index: Zero-based component index. A negative value is retained as invalid intent and
    ///     reported safely when the component is used; it never traps in XCUI.
    ///   - componentName: Name written to Allure and canonical diagnostics.
    init(index: Int, componentName: String?) {
        self.init(position: .index(index), componentName: componentName)
    }

    /// Creates the first component instance with an explicit semantic name.
    ///
    /// - Parameter componentName: Name written to Allure and canonical diagnostics.
    init(componentName: String) {
        self.init(position: .first, componentName: componentName)
    }
}
