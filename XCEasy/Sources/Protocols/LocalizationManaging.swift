import Foundation

// MARK: - LocalizationManaging

/// Protocol defining the interface for localization management.
///
/// Conforming types are responsible for managing application localization,
/// including setting the language and retrieving localized strings.
public protocol LocalizationManaging {

    // MARK: - Methods

    /// Sets the localization language.
    /// - Parameter language: The language code (e.g., "en", "ru").
    func setLocalization(for language: String)

    /// Retrieves a localized string for the specified key.
    /// - Parameter key: The localization key.
    /// - Returns: The localized string, or the key if not found.
    func string(forKey key: String) -> String

    /// Retrieves a localized string for the specified key with arguments.
    /// - Parameters:
    ///   - key: The localization key.
    ///   - arguments: The arguments to substitute in the format string.
    /// - Returns: The localized string with substituted arguments.
    func string(forKey key: String, arguments: [CVarArg]) -> String
}
