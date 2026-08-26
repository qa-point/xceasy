import ObjectiveC
import XCTest

// MARK: - XCEasyUIElement

/// A proxy class for lazy initialization of XCEasyUIElement.
///
/// This class provides a fluent interface for interacting with UI elements
/// in XCUI tests, with built-in support for dependency injection.
public class XCEasyUIElement: NSObject {

    // MARK: - Properties

    /// The type of element to search for.
    internal let type: ElementType?

    /// The identifier to search for.
    internal let identifier: String?

    /// The predicate format to search for.
    internal let format: String?

    /// The text to search for.
    internal let text: String?

    /// The index of the element to return.
    internal let index: Int?

    /// Optional symbolic component position resolved from the current candidate collection.
    internal let componentPosition: XCEasyComponentPosition?

    /// The maximum amount of time to wait for the element to appear.
    internal let timeout: TimeInterval

    /// The test context provider for dependency injection.
    private let testContext: TestContextProviding

    /// Immutable parent locator. A child strongly owns its parent locator so the
    /// complete scope can be rebuilt against the current accessibility tree for
    /// every operation. There is no retain cycle because parents do not own children.
    internal let parentLocator: XCEasyUIElement?

    /// The description of the element.
    var desc: String

    /// The current application, read only when a semantic operation resolves the locator.
    internal var application: XCUIApplication? {
        testContext.app
    }

    // MARK: - Initialization

    /// Initializes the proxy with search parameters and a timeout.
    ///
    /// - Parameters:
    ///   - type: The type of element to search for.
    ///   - identifier: The identifier to search for.
    ///   - format: The predicate to search for.
    ///   - text: The text to search for.
    ///   - index: The index of the element to return.
    ///   - componentPosition: Optional symbolic selection used by component collections.
    ///   - desc: The description of the element.
    ///   - timeout: The maximum amount of time to wait for the element to appear.
    ///   - testContext: The test context provider (defaults to shared container).
    init(
        type: ElementType? = nil,
        identifier: String? = nil,
        format: String? = nil,
        text: String? = nil,
        index: Int? = nil,
        componentPosition: XCEasyComponentPosition? = nil,
        desc: String? = nil,
        timeout: TimeInterval,
        testContext: TestContextProviding = XCDependencyContainer.shared.testContext,
        parentLocator: XCEasyUIElement? = nil
    ) {
        self.type = type
        self.identifier = identifier
        self.format = format
        self.text = text
        self.index = index
        self.componentPosition = componentPosition
        self.testContext = testContext
        self.parentLocator = parentLocator
        self.desc = Self.generateDescription(type, identifier, format, text, desc)
        self.timeout = timeout
    }

    /// Creates a lazy copy that selects one current match by component position.
    ///
    /// The method does not read the application or accessibility tree. ``XCEasyComponentPosition/last``
    /// remains symbolic until an action, assertion, wait, or value read resolves the element.
    ///
    /// - Parameters:
    ///   - position: First, last, or zero-based current match to select.
    ///   - desc: Optional human-readable description for reports. The existing description is
    ///     preserved when this argument is omitted.
    /// - Returns: A new lazy locator with the same query and parent scope.
    public func element(
        at position: XCEasyComponentPosition,
        desc: String? = nil
    ) -> XCEasyUIElement {
        let explicitIndex: Int?
        switch position {
        case .first:
            explicitIndex = 0
        case .last:
            explicitIndex = nil
        case .index(let index):
            explicitIndex = index
        }
        return XCEasyUIElement(
            type: type,
            identifier: identifier,
            format: format,
            text: text,
            index: explicitIndex,
            componentPosition: position,
            desc: desc ?? self.desc,
            timeout: timeout,
            testContext: testContext,
            parentLocator: parentLocator
        )
    }

    // MARK: - Private Methods

    /// Generate current element description.
    private static func generateDescription(
        _ type: ElementType? = nil,
        _ identifier: String? = nil,
        _ format: String? = nil,
        _ text: String? = nil,
        _ desc: String? = nil
    ) -> String {
        let elementType = type?.properties.description ?? ElementType.any.properties.description
        if let desc = desc {
            return desc
        } else if let identifier = identifier {
            return "\(elementType) with identifier '\(identifier)'"
        } else if let format = format {
            return "\(elementType) with predicate \"\(format)\""
        } else if let text = text {
            return "\(elementType) with text '\(text)'"
        } else {
            return "\(elementType)"
        }
    }

    /// Resolves the actual XCUIElement based on the search parameters.
    ///
    /// - Returns: The resolved XCUIElement.
    internal func resolve(parentOperationId: String? = nil) -> XCUIElement {
        search(timeout: timeout, parentOperationId: parentOperationId)
    }

    // MARK: - Method Forwarding

    /// Forwards method calls to the resolved XCUIElement.
    ///
    /// - Parameter aSelector: The selector of the method to forward.
    /// - Returns: The resolved XCUIElement.
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return resolve()
    }

    /// Checks if the resolved XCUIElement responds to the given selector.
    ///
    /// - Parameter aSelector: The selector to check.
    /// - Returns: A Boolean value indicating whether the resolved XCUIElement responds to the selector.
    public override func responds(to aSelector: Selector!) -> Bool {
        return resolve().responds(to: aSelector)
    }
}
