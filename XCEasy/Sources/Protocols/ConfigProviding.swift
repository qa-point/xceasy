import Foundation

// MARK: - ConfigProviding

/// Protocol defining the interface for configuration management.
///
/// Conforming types provide access to various configuration settings
/// used throughout the testing framework, including timeouts,
/// localization, and application settings.
///
/// ## Usage
///
/// Configuration is global and static, so the protocol defines static requirements.
///
/// ```swift
/// // Access configuration directly through static properties
/// let timeout = XCEasyConfig.findTimeout
///
/// // Or through the protocol
/// func setTimeout(_ timeout: TimeInterval) {
///     XCEasyConfig.findTimeout = timeout
/// }
/// ```
public protocol ConfigProviding {

    // MARK: - Static Properties

    /// The bundle identifier of the application under test.
    static var bundleId: String { get set }

    /// The timeout for finding elements.
    static var findTimeout: TimeInterval { get set }

    /// The timeout for performing actions.
    static var actionTimeout: TimeInterval { get set }

    /// The timeout for performing assertions.
    static var assertionTimeout: TimeInterval { get set }

    /// The timeout for network requests.
    static var requestTimeout: TimeInterval { get set }

    /// Default readiness and dispatch policy for UI actions.
    static var actionPolicy: XCEasyActionPolicy { get set }

    /// The localization language setting.
    static var localization: XCEasyConfig.Language { get set }

    /// The deeplink schema.
    static var deeplinkSchema: String { get set }

    /// Whether to print logs to console.
    static var printLogToConsole: Bool { get set }

    /// Structured UI query evidence collection level.
    static var uiQueryEvidenceLevel: XCEasyUIQueryEvidenceLevel { get set }

    /// Behavior for ambiguous UI queries without an explicit index.
    static var uiQueryAmbiguityPolicy: XCEasyUIQueryAmbiguityPolicy { get set }

    /// Geometry policy for visible and hidden UI states.
    static var visibilityPolicy: XCEasyVisibilityPolicy { get set }

    /// Performance collection and budget policy.
    static var performance: XCEasyPerformanceConfiguration { get set }

    /// Evidence-backed selector-healing proposal policy.
    static var healing: XCEasyHealingConfiguration { get set }

    /// Maximum accessibility snapshot attachment size.
    static var diagnosticSnapshotByteLimit: Int { get set }

}
