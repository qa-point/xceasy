import Foundation

/// Model representing Allure execution stage.
public enum Stage: String, Codable {
    case scheduled = "scheduled"
    case running = "running"
    case finished = "finished"
    case pending = "pending"
    case interrupted = "interrupted"
}
