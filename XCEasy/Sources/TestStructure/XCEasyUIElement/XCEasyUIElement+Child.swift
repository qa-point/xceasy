import XCTest

// MARK: - Child Element Methods

extension XCEasyUIElement {

    /// Creates a lazy child locator using an accessibility identifier.
    ///
    /// Neither the parent nor child is resolved during construction; semantic operations rebuild
    /// the complete chain against the current UI tree.
    ///
    /// - Parameters:
    ///   - identifier: The identifier to search for.
    ///   - index: The index of the element to return.
    ///   - desc: The description of the element.
    ///   - timeout: Default positive-resolution timeout used by semantic operations.
    /// - Returns: A lazy child proxy scoped to this parent locator.
    public func child(
        identifier: String,
        index: Int? = nil,
        desc: String? = nil,
        timeout: TimeInterval = XCEasyConfig.findTimeout
    ) -> XCEasyUIElement {
        return XCEasyUIElement(
            identifier: identifier,
            index: index,
            desc: desc,
            timeout: timeout,
            parentLocator: self
        )
    }

    /// Creates a lazy child locator using an NSPredicate format.
    ///
    /// - Parameters:
    ///   - format: The predicate to search for.
    ///   - index: The index of the element to return.
    ///   - desc: The description of the element.
    ///   - timeout: Default positive-resolution timeout used by semantic operations.
    /// - Returns: A lazy child proxy scoped to this parent locator.
    public func child(
        format: String,
        index: Int? = nil,
        desc: String? = nil,
        timeout: TimeInterval = XCEasyConfig.findTimeout
    ) -> XCEasyUIElement {
        return XCEasyUIElement(
            format: format,
            index: index,
            desc: desc,
            timeout: timeout,
            parentLocator: self
        )
    }

    /// Creates a lazy typed child locator using an accessibility identifier.
    ///
    /// - Parameters:
    ///   - type: The type of element to search for.
    ///   - identifier: The identifier to search for.
    ///   - index: The index of the element to return.
    ///   - desc: The description of the element.
    ///   - timeout: Default positive-resolution timeout used by semantic operations.
    /// - Returns: A lazy child proxy scoped to this parent locator.
    public func child(
        type: ElementType,
        identifier: String,
        index: Int? = nil,
        desc: String? = nil,
        timeout: TimeInterval = XCEasyConfig.findTimeout
    ) -> XCEasyUIElement {
        return XCEasyUIElement(
            type: type,
            identifier: identifier,
            index: index,
            desc: desc,
            timeout: timeout,
            parentLocator: self
        )
    }

    /// Creates a lazy typed child locator using an NSPredicate format.
    ///
    /// - Parameters:
    ///   - type: The type of element to search for.
    ///   - format: The predicate to search for.
    ///   - index: The index of the element to return.
    ///   - desc: The description of the element.
    ///   - timeout: Default positive-resolution timeout used by semantic operations.
    /// - Returns: A lazy child proxy scoped to this parent locator.
    public func child(
        type: ElementType,
        format: String,
        index: Int? = nil,
        desc: String? = nil,
        timeout: TimeInterval = XCEasyConfig.findTimeout
    ) -> XCEasyUIElement {
        return XCEasyUIElement(
            type: type,
            format: format,
            index: index,
            desc: desc,
            timeout: timeout,
            parentLocator: self
        )
    }

    /// Creates a lazy child locator using an exact accessibility label.
    ///
    /// - Parameters:
    ///   - text: The text to search for.
    ///   - index: The index of the element to return.
    ///   - desc: The description of the element.
    ///   - timeout: Default positive-resolution timeout used by semantic operations.
    /// - Returns: A lazy child proxy scoped to this parent locator.
    public func child(
        text: String,
        index: Int? = nil,
        desc: String? = nil,
        timeout: TimeInterval = XCEasyConfig.findTimeout
    ) -> XCEasyUIElement {
        return XCEasyUIElement(
            text: text,
            index: index,
            desc: desc,
            timeout: timeout,
            parentLocator: self
        )
    }

    /// Creates a lazy typed child locator using an exact accessibility label.
    ///
    /// - Parameters:
    ///   - type: The type of element to search for.
    ///   - text: The text to search for.
    ///   - index: The index of the element to return.
    ///   - desc: The description of the element.
    ///   - timeout: Default positive-resolution timeout used by semantic operations.
    /// - Returns: A lazy child proxy scoped to this parent locator.
    public func child(
        type: ElementType,
        text: String,
        index: Int? = nil,
        desc: String? = nil,
        timeout: TimeInterval = XCEasyConfig.findTimeout
    ) -> XCEasyUIElement {
        return XCEasyUIElement(
            type: type,
            text: text,
            index: index,
            desc: desc,
            timeout: timeout,
            parentLocator: self
        )
    }
}
