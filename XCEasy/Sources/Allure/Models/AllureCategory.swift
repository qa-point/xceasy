import Foundation

/// Model representing entry in Allure `categories.json`.
public struct AllureCategory: Codable {
    var name: String
    var matchedStatuses: [String]?
    var messageRegex: String?
    var traceRegex: String?
    var flaky: Bool?
}
