import Foundation

/// Model representing Allure test result container (`*-container.json`).
public struct TestResultContainer: Codable {
    var uuid: String?
    var name: String?
    var children: [String]?
    var description: String?
    var descriptionHtml: String?
    var befores: [StepResult]?
    var afters: [StepResult]?
    var links: [AllureLinkRecord]?
    var start: Int64?
    var stop: Int64?
}
