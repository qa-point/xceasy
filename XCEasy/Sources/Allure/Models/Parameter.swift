import Foundation

// MARK: - Parameter

/// Model representing an Allure test parameter.
///
/// Parameters are key-value pairs that provide additional context
/// to test executions, such as input data or configuration values.
public struct Parameter: Codable {

    // MARK: - Properties

    /// The name of the parameter.
    var name: String?

    /// The value of the parameter.
    var value: String?

    /// Indicates whether parameter should be excluded from history key.
    var excluded: Bool?

    /// Parameter display mode in Allure.
    /// Known values: "default", "masked", "hidden".
    var mode: String?

    /// Creates a redacted Allure parameter.
    ///
    /// Redaction occurs before the value reaches the result model. Mark volatile values as
    /// excluded when they should be visible in a report but must not split test history.
    ///
    /// - Parameters:
    ///   - name: Parameter name written to Allure after redaction.
    ///   - value: Parameter value written to Allure after redaction.
    ///   - excluded: Whether the parameter is omitted from `historyId` calculation.
    ///   - mode: Allure display mode, normally one of ``AllureParameterMode`` values.
    ///
    /// ```swift
    /// let parameter = Parameter(
    ///     name: "account",
    ///     value: "test-user",
    ///     excluded: true,
    ///     mode: AllureParameterMode.masked.rawValue
    /// )
    /// ```
    public init(
        name: String,
        value: String,
        excluded: Bool = false,
        mode: String = AllureParameterMode.default.rawValue
    ) {
        self.name = SensitiveDataRedactor.redact(name)
        self.value = SensitiveDataRedactor.redact(value)
        self.excluded = excluded
        self.mode = mode
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case name
        case value
        case excluded
        case mode
    }
}
