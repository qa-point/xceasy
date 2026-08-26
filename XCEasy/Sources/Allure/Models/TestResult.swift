import Foundation

// MARK: - TestResult

/// Model representing an Allure test result.
///
/// This structure contains all information about a test execution,
/// including its status, steps, attachments, and metadata.
public struct TestResult: Codable {

    // MARK: - Properties

    /// Unique identifier for the test.
    var uuid: String?

    /// History identifier for tracking test across runs.
    var historyId: String?

    /// Test case identifier.
    var testCaseId: String?

    /// Identifier of the test this is a rerun of.
    var rerunOf: String?

    /// Full name of the test.
    var fullName: String?

    /// Source-level test method name.
    var testCaseName: String?

    /// Labels associated with the test.
    var labels: [Label]?

    /// Links associated with the test.
    var links: [AllureLinkRecord]?

    /// Display name of the test.
    var name: String?

    /// Status of the test.
    var status: Status?

    /// Execution stage of the test.
    var stage: Stage?

    /// Additional details about the test status.
    var statusDetails: StatusDetails?

    /// Description of the test.
    var description: String?

    /// HTML description of the test.
    var descriptionHtml: String?

    /// Start time of the test (Unix timestamp in milliseconds).
    var start: Int64?

    /// Stop time of the test (Unix timestamp in milliseconds).
    var stop: Int64?

    /// Nested steps.
    var steps: [StepResult]?

    /// Attachments associated with the test.
    var attachments: [Attachment]?

    /// Parameters associated with the test.
    var parameters: [Parameter]?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case uuid
        case historyId
        case testCaseId
        case rerunOf
        case fullName
        case testCaseName
        case labels
        case links
        case name
        case status
        case stage
        case statusDetails
        case description
        case descriptionHtml
        case start
        case stop
        case steps
        case attachments
        case parameters
    }
}
