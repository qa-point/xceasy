import Foundation

/// Model representing Allure executor metadata.
public struct Executor: Codable {
    var name: String?
    var type: String?
    var url: String?
    var buildOrder: Int?
    var buildName: String?
    var buildUrl: String?
    var reportName: String?
    var reportUrl: String?
}
