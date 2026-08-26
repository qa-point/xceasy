import Foundation

// MARK: - LocalizationManager

/// Internal localization manager for the XCEasy framework.
///
/// Provides methods for managing application localization,
/// including setting the language and retrieving localized strings.
internal class LocalizationManager: LocalizationManaging {

    // MARK: - Properties

    /// Shared instance of the localization manager.
    static let shared = LocalizationManager()

    /// Per-execution-thread catalog. Parallel tests can render different
    /// locales without mutating a shared dictionary.
    private let localizedStringsStorage = ThreadLocal<[String: String]>()

    private var localizedStrings: [String: String] {
        get { localizedStringsStorage.value ?? [:] }
        set { localizedStringsStorage.value = newValue }
    }

    // MARK: - Initialization

    /// Creates the shared manager and loads the configured execution locale.
    private init() {
        setLocalization(for: XCEasyConfig.localization.rawValue)
    }

    // MARK: - LocalizationManaging

    /// Sets the localization language.
    /// - Parameter language: The language code (e.g., "en", "ru").
    func setLocalization(for language: String) {
        let bundle = Bundle.module
        let languageFolder = "\(language).lproj"
        let requestedPath = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: languageFolder)
        let fallbackPath = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: "en.lproj")
        guard let path = requestedPath ?? fallbackPath else { return }

        guard let data = FileManager.default.contents(atPath: path) else {
            return
        }

        let propertyList: Any
        do {
            propertyList = try PropertyListSerialization.propertyList(from: data, format: nil)
        } catch {
            return
        }
        guard let dict = propertyList as? [String: String] else { return }

        localizedStrings = dict
    }

    /// Retrieves a localized string for the specified key.
    /// - Parameter key: The localization key.
    /// - Returns: The localized string, or the key if not found.
    func string(forKey key: String) -> String {
        if localizedStrings.isEmpty {
            setLocalization(for: XCEasyConfig.localization.rawValue)
        }
        return localizedStrings[key] ?? key
    }

    /// Retrieves a localized string for the specified key with arguments.
    /// - Parameters:
    ///   - key: The localization key.
    ///   - arguments: The arguments to substitute in the format string.
    /// - Returns: The localized string with substituted arguments.
    func string(forKey key: String, arguments: [CVarArg] = []) -> String {
        let format = string(forKey: key)
        return String(format: format, arguments: arguments)
    }
}
