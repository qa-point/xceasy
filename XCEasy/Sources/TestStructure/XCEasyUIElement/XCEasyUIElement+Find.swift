import XCTest

// MARK: - Find Methods (Global)

/// Creates a lazy root locator using an accessibility identifier.
///
/// Construction does not read the UI tree. Every action or assertion resolves the locator
/// again so a retained proxy observes element removal and replacement.
///
/// - Parameters:
///   - identifier: The identifier to search for.
///   - index: The index of the element to return.
///   - desc: The description of the element.
///   - timeout: Default positive-resolution timeout used by semantic operations.
/// - Returns: A lazy element proxy.
///
/// ```swift
/// let banner = find(identifier: "promoBanner")
/// banner.assertExists()
/// banner.child(identifier: "promoBanner.closeButton").tap()
/// banner.assertDoesNotExist(timeout: 5)
/// ```
public func find(
    identifier: String,
    index: Int? = nil,
    desc: String? = nil,
    timeout: TimeInterval = XCEasyConfig.findTimeout
) -> XCEasyUIElement {
    return XCEasyUIElement(identifier: identifier, index: index, desc: desc, timeout: timeout)
}

/// Creates a lazy root locator using an NSPredicate format.
///
/// Prefer a stable accessibility identifier when one is available.
///
/// - Parameters:
///   - format: The predicate to search for.
///   - index: The index of the element to return.
///   - desc: The description of the element.
///   - timeout: Default positive-resolution timeout used by semantic operations.
/// - Returns: A lazy element proxy.
public func find(
    format: String,
    index: Int? = nil,
    desc: String? = nil,
    timeout: TimeInterval = XCEasyConfig.findTimeout
) -> XCEasyUIElement {
    return XCEasyUIElement(format: format, index: index, desc: desc, timeout: timeout)
}

/// Creates a lazy typed root locator using an accessibility identifier.
///
/// - Parameters:
///   - type: The type of element to search for.
///   - identifier: The identifier to search for.
///   - index: The index of the element to return.
///   - desc: The description of the element.
///   - timeout: Default positive-resolution timeout used by semantic operations.
/// - Returns: A lazy element proxy.
public func find(
    type: XCEasyUIElement.ElementType,
    identifier: String,
    index: Int? = nil,
    desc: String? = nil,
    timeout: TimeInterval = XCEasyConfig.findTimeout
) -> XCEasyUIElement {
    return XCEasyUIElement(type: type, identifier: identifier, index: index, desc: desc, timeout: timeout)
}

/// Creates a lazy typed root locator using an NSPredicate format.
///
/// - Parameters:
///   - type: The type of element to search for.
///   - format: The predicate to search for.
///   - index: The index of the element to return.
///   - desc: The description of the element.
///   - timeout: Default positive-resolution timeout used by semantic operations.
/// - Returns: A lazy element proxy.
public func find(
    type: XCEasyUIElement.ElementType,
    format: String,
    index: Int? = nil,
    desc: String? = nil,
    timeout: TimeInterval = XCEasyConfig.findTimeout
) -> XCEasyUIElement {
    return XCEasyUIElement(type: type, format: format, index: index, desc: desc, timeout: timeout)
}

/// Creates a lazy root locator using an exact accessibility label.
///
/// Text is less stable than an accessibility identifier and is redacted in diagnostics.
///
/// - Parameters:
///   - text: The text to search for.
///   - index: The index of the element to return.
///   - desc: The description of the element.
///   - timeout: Default positive-resolution timeout used by semantic operations.
/// - Returns: A lazy element proxy.
public func find(
    text: String,
    index: Int? = nil,
    desc: String? = nil,
    timeout: TimeInterval = XCEasyConfig.findTimeout
) -> XCEasyUIElement {
    return XCEasyUIElement(text: text, index: index, desc: desc, timeout: timeout)
}

/// Creates a lazy typed root locator using an exact accessibility label.
///
/// - Parameters:
///   - type: The type of element to search for.
///   - text: The text to search for.
///   - index: The index of the element to return.
///   - desc: The description of the element.
///   - timeout: Default positive-resolution timeout used by semantic operations.
/// - Returns: A lazy element proxy.
public func find(
    type: XCEasyUIElement.ElementType,
    text: String,
    index: Int? = nil,
    desc: String? = nil,
    timeout: TimeInterval = XCEasyConfig.findTimeout
) -> XCEasyUIElement {
    return XCEasyUIElement(type: type, text: text, index: index, desc: desc, timeout: timeout)
}

/// Creates a lazy root locator constrained only by XCUI element type.
///
/// Supply an explicit index when several elements of that type are expected; strict ambiguity
/// policy otherwise rejects multiple matches.
///
/// - Parameters:
///   - type: The type of element to search for.
///   - index: The index of the element to return.
///   - desc: The description of the element.
///   - timeout: Default positive-resolution timeout used by semantic operations.
/// - Returns: A lazy element proxy.
public func find(
    type: XCEasyUIElement.ElementType,
    index: Int? = nil,
    desc: String? = nil,
    timeout: TimeInterval = XCEasyConfig.findTimeout
) -> XCEasyUIElement {
    return XCEasyUIElement(type: type, index: index, desc: desc, timeout: timeout)
}
