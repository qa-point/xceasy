import Foundation

// MARK: - StatusDetails

/// Model representing additional details about an Allure test status.
///
/// Contains information about test behavior such as flakiness,
/// known issues, and error messages/traces.
public struct StatusDetails: Codable {

    // MARK: - Properties

    /// Indicates if the failure is a known issue.
    var known: Bool? = false

    /// Indicates if the failure is muted/suppressed.
    var muted: Bool? = false

    /// Indicates if the test is flaky.
    var flaky: Bool? = false

    /// The error message.
    var message: String?

    /// The full error stack trace.
    var trace: String?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case known
        case muted
        case flaky
        case message
        case trace
    }
}
