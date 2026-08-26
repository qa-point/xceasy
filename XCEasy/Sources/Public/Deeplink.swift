import Foundation
import XCTest

/// Opens application deep links using the scheme configured in ``XCEasyConfig``.
public enum Deeplink {
    /// Opens a scheme-relative path on the current simulator or device.
    ///
    /// The leading slash is optional. For example, when `deeplinkSchema` is `"myapp"`, both
    /// `"settings/privacy"` and `"/settings/privacy"` open `myapp://settings/privacy`.
    ///
    /// - Parameters:
    ///   - path: Path and optional query, without the URL scheme.
    ///   - name: Optional human-readable name for logs and Allure. The path is used by default.
    ///
    /// ```swift
    /// XCEasyConfig.deeplinkSchema = "myapp"
    /// Deeplink.open("/settings/privacy", name: "Privacy settings")
    /// ```
    public static func open(_ path: String, name: String? = nil) {
        let target = name ?? path
        let title = LocalizationManager.shared
            .string(forKey: "open_deeplink_title", arguments: [target])
        operationStep(code: "deeplink.open", title: title, target: target) {
            guard let url = makeURL(path: path, scheme: XCEasyConfig.deeplinkSchema) else {
                recordFrameworkFailure(XCEasyFrameworkError(
                    code: "deeplink.invalid_url",
                    safeDescription: SensitiveDataRedactor.redact(
                        "Invalid deeplink path [\(path)] or scheme [\(XCEasyConfig.deeplinkSchema)]"
                    )
                ))
                return
            }
            XCUIDevice.shared.system.open(url)
        }
    }

    /// Builds a validated URL without opening it.
    ///
    /// - Parameters:
    ///   - path: Scheme-relative deep-link path.
    ///   - scheme: Custom application URL scheme.
    /// - Returns: Normalized URL, or `nil` for empty or malformed input.
    internal static func makeURL(path: String, scheme: String) -> URL? {
        let normalizedScheme = scheme.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPath = String(trimmedPath.drop(while: { $0 == "/" }))
        guard !normalizedScheme.isEmpty, !normalizedPath.isEmpty else { return nil }
        guard normalizedScheme.range(
            of: "^[A-Za-z][A-Za-z0-9+.-]*$",
            options: .regularExpression
        ) != nil else { return nil }
        guard !normalizedPath.contains("://") else { return nil }
        return URL(string: "\(normalizedScheme)://\(normalizedPath)")
    }
}
