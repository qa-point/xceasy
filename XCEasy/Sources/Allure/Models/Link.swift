import Foundation

/// Model representing an Allure link.
///
/// Links are used to associate tests with external resources
/// such as JIRA issues, TMS test cases, or other URLs.
public struct AllureLinkRecord: Codable {
    /// Readable link name.
    public var name: String?
    /// Resolved safe URL.
    public var url: String?
    /// Standard or project-defined Allure link type.
    public var type: String?

    /// Creates an Allure link value used by custom test-context implementations.
    /// - Parameters:
    ///   - name: Readable link name.
    ///   - url: Resolved URL after caller-side secret removal.
    ///   - type: Allure link type such as `issue`, `tms`, or `custom`.
    public init(name: String? = nil, url: String? = nil, type: String? = nil) {
        self.name = name
        self.url = url
        self.type = type
    }

    enum CodingKeys: String, CodingKey {
        case name
        case url
        case type
    }
}
