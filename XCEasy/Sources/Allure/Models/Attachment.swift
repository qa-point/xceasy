import Foundation

/// Model representing an Allure attachment.
///
/// Attachments are used to include additional information such as
/// screenshots, logs, or other files in the test report.
public struct Attachment: Codable {
    var name: String?
    var source: String?
    var type: String?

    enum CodingKeys: String, CodingKey {
        case name
        case source
        case type
    }
}
