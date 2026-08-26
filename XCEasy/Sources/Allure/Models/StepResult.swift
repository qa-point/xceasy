import Foundation

// MARK: - StepResult

/// Model representing an Allure step result.
///
/// Steps represent individual actions within a test, forming a hierarchy
/// of operations that led to the final test result.
public struct StepResult: Codable {

    // MARK: - Properties

    /// The name of the step.
    var name: String?

    /// The status of the step.
    var status: Status?

    /// Execution stage of the step.
    var stage: Stage?

    /// Additional details about the step status.
    var statusDetails: StatusDetails?

    /// The description of the step.
    var description: String?

    /// The HTML description of the step.
    var descriptionHtml: String?

    /// The start time of the step (Unix timestamp in milliseconds).
    var start: Int64?

    /// The stop time of the step (Unix timestamp in milliseconds).
    var stop: Int64?

    /// Nested steps.
    var steps: [StepResult]?

    /// Attachments associated with the step.
    var attachments: [Attachment]?

    /// Parameters associated with the step.
    var parameters: [Parameter]?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
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
