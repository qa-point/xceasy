import Foundation

// MARK: - Label

/// Model representing an Allure label.
///
/// Labels are used to categorize and organize tests with metadata
/// such as epic, feature, story, owner, severity, etc.
public struct Label: Codable {

    // MARK: - Properties

    /// The name of the label.
    var name: String?

    /// The value of the label.
    var value: String?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case name
        case value
    }
}
