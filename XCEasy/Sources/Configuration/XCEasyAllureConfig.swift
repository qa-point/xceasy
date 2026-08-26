import Foundation

/// Process-level configuration for standard Allure link types.
public final class XCEasyAllureConfig {
    private static let shared = XCEasyAllureConfig()
    private let lock = NSLock()
    private var patterns: [String: String] = [:]

    /// Creates the process-level configuration singleton.
    private init() {}

    /// Replaces configured Allure link patterns.
    ///
    /// A pattern may contain `{}` or `%s`; XCEasy substitutes the issue/TMS value. Without a
    /// placeholder, the value is appended as one URL path component.
    ///
    /// - Parameter linkPatterns: Mapping from Allure link type to URL pattern.
    ///
    /// ```swift
    /// XCEasyAllureConfig.apply(linkPatterns: [
    ///     "issue": "https://issues.example.test/browse/{}",
    ///     "tms": "https://tms.example.test/case/{}"
    /// ])
    /// ```
    public static func apply(linkPatterns: [String: String]) {
        shared.lock.lock()
        shared.patterns = linkPatterns.reduce(into: [:]) { result, item in
            let key = item.key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { return }
            result[key] = SensitiveDataRedactor.redact(item.value)
        }
        shared.lock.unlock()
    }

    /// Removes all configured link patterns.
    public static func reset() {
        apply(linkPatterns: [:])
    }

    /// Resolves one standard Allure link through a configured type pattern.
    ///
    /// - Parameters:
    ///   - type: Allure link type such as `issue` or `tms`.
    ///   - value: Safe issue or test-case key.
    /// - Returns: Expanded URL, or the original value when no pattern exists.
    internal static func resolveLink(type: String, value: String) -> String {
        shared.lock.lock()
        let pattern = shared.patterns[type]
        shared.lock.unlock()
        guard let pattern, !pattern.isEmpty else { return value }
        if pattern.contains("{}") {
            return pattern.replacingOccurrences(of: "{}", with: value)
        }
        if pattern.contains("%s") {
            return pattern.replacingOccurrences(of: "%s", with: value)
        }
        return pattern.hasSuffix("/") ? pattern + value : pattern + "/" + value
    }

    /// Returns configured link types without exposing their URL patterns.
    internal static var configuredLinkTypes: [String] {
        shared.lock.lock()
        let types = shared.patterns.keys.sorted()
        shared.lock.unlock()
        return types
    }

    /// Writes configured link types without exposing full URLs to logs.
    public static func logConfig() {
        let types = configuredLinkTypes
        step(LocalizationManager.shared.string(forKey: "xceasy_allure_config_title")) {
            XCEasyTestLogger.shared.log("allure.linkTypes: \(types.joined(separator: ","))")
        }
    }
}
