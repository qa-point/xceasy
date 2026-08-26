import Foundation

/// Controls how an Allure parameter is rendered. Values are still redacted
/// before persistence regardless of the display mode.
public enum AllureParameterMode: String, Codable, CaseIterable, Sendable {
    case `default`
    case masked
    case hidden
}
