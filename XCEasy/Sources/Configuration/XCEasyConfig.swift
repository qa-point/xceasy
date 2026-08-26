import Foundation
import XCTest

/// Mutable configuration snapshot owned by one test execution.
internal final class XCEasyExecutionConfigurationState: @unchecked Sendable {
    struct Values {
        var bundleId = String.empty
        var findTimeout: TimeInterval = 10
        var actionTimeout: TimeInterval = 10
        var assertionTimeout: TimeInterval = 10
        var requestTimeout: TimeInterval = 10
        var actionPolicy: XCEasyActionPolicy = .hittable
        var localization: XCEasyConfig.Language = .en
        var deeplinkSchema = "DEFAULT_DEEPLINK_SCHEMA"
        var printLogToConsole = true
        var uiQueryEvidenceLevel: XCEasyUIQueryEvidenceLevel = .basic
        var uiQueryAmbiguityPolicy: XCEasyUIQueryAmbiguityPolicy = .strict
        var visibilityPolicy: XCEasyVisibilityPolicy = .onScreen
        var performance = XCEasyPerformanceConfiguration()
        var healing = XCEasyHealingConfiguration()
        var diagnosticSnapshotByteLimit = 64 * 1024
    }

    private let lock = NSLock()
    private var values: Values

    /// Creates an execution configuration from synchronized defaults.
    ///
    /// - Parameter values: Immutable value snapshot to own.
    init(values: Values) {
        self.values = values
    }

    /// Reads a configuration value under the snapshot lock.
    ///
    /// - Parameter keyPath: Value to project.
    /// - Returns: Current execution-scoped value.
    func read<T>(_ keyPath: KeyPath<Values, T>) -> T {
        lock.lock()
        defer { lock.unlock() }
        return values[keyPath: keyPath]
    }

    /// Writes a configuration value under the snapshot lock.
    ///
    /// - Parameters:
    ///   - keyPath: Value to update.
    ///   - value: New execution-scoped value.
    func write<T>(_ keyPath: WritableKeyPath<Values, T>, _ value: T) {
        lock.lock()
        values[keyPath: keyPath] = value
        lock.unlock()
    }
}

// MARK: - XCEasyConfig

/// Configuration manager for the XCEasy framework.
///
/// This class provides access to various configuration settings used throughout
/// the testing framework, including timeouts, localization, and application settings.
public class XCEasyConfig: ConfigProviding {

    // MARK: - Properties

    /// Singleton instance of the configuration.
    private static let shared = XCEasyConfig()

    private let executionValues = ThreadLocal<XCEasyExecutionConfigurationState>()
    private let defaultsLock = NSLock()
    private var defaults = XCEasyExecutionConfigurationState.Values()

    /// Reads an execution-scoped value and falls back to the synchronized defaults.
    ///
    /// - Parameter keyPath: Key path of the configuration value to read.
    /// - Returns: The value captured for the current execution, or the current default.
    private func read<T>(_ keyPath: KeyPath<XCEasyExecutionConfigurationState.Values, T>) -> T {
        if let taskValues = XCEasyTaskExecutionScope.state?.read(\.configuration) {
            return taskValues.read(keyPath)
        }
        if let values = executionValues.value { return values.read(keyPath) }
        defaultsLock.lock()
        defer { defaultsLock.unlock() }
        return defaults[keyPath: keyPath]
    }

    /// Updates the current execution snapshot without leaking changes to parallel tests.
    ///
    /// - Parameters:
    ///   - keyPath: Writable key path of the configuration value.
    ///   - value: New execution-scoped value, or a new default outside an execution.
    private func write<T>(_ keyPath: WritableKeyPath<XCEasyExecutionConfigurationState.Values, T>, _ value: T) {
        if let taskValues = XCEasyTaskExecutionScope.state?.read(\.configuration) {
            taskValues.write(keyPath, value)
            return
        }
        if let values = executionValues.value {
            values.write(keyPath, value)
            return
        }
        defaultsLock.lock()
        defaults[keyPath: keyPath] = value
        defaultsLock.unlock()
    }

    /// Captures defaults for the current XCTest execution thread.
    internal static func beginExecution() {
        shared.defaultsLock.lock()
        let snapshot = shared.defaults
        shared.defaultsLock.unlock()
        let executionState = XCEasyExecutionConfigurationState(values: snapshot)
        shared.executionValues.value = executionState
        XCEasyTestContext.shared.setExecutionConfiguration(executionState)
        LocalizationManager.shared.setLocalization(for: snapshot.localization.rawValue)
    }

    /// Clears settings scoped to the completed XCTest execution thread.
    internal static func endExecution() {
        XCEasyTestContext.shared.setExecutionConfiguration(nil)
        shared.executionValues.value = nil
    }

    // MARK: - Public Properties

    /// Testing application bundleId.
    /// By default bundleId is empty.
    public static var bundleId: String {
        get { shared.read(\.bundleId) }
        set { shared.write(\.bundleId, newValue) }
    }

    /// Timeout for elements safe search.
    /// Default timeout 10 seconds.
    public static var findTimeout: TimeInterval {
        get { shared.read(\.findTimeout) }
        set { shared.write(\.findTimeout, newValue) }
    }

    /// Timeout for safe actions with elements.
    /// Default timeout 10 seconds.
    public static var actionTimeout: TimeInterval {
        get { shared.read(\.actionTimeout) }
        set { shared.write(\.actionTimeout, newValue) }
    }

    /// Timeout for safe assertions.
    /// Default timeout 10 seconds.
    public static var assertionTimeout: TimeInterval {
        get { shared.read(\.assertionTimeout) }
        set { shared.write(\.assertionTimeout, newValue) }
    }

    /// Timeout for requests.
    /// Default timeout 10 seconds.
    public static var requestTimeout: TimeInterval {
        get { shared.read(\.requestTimeout) }
        set { shared.write(\.requestTimeout, newValue) }
    }

    /// Readiness and dispatch policy used by UI actions.
    ///
    /// Defaults to ``XCEasyActionPolicy/hittable``. Configure this value before parallel test
    /// execution or override the policy on one action call.
    public static var actionPolicy: XCEasyActionPolicy {
        get { shared.read(\.actionPolicy) }
        set { shared.write(\.actionPolicy, newValue) }
    }

    /// Localization language.
    /// Used in asserts labels and etc.
    public static var localization: Language {
        get { shared.read(\.localization) }
        set {
            shared.write(\.localization, newValue)
            LocalizationManager.shared.setLocalization(for: newValue.rawValue)
        }
    }

    /// Schema for deeplinking.
    public static var deeplinkSchema: String {
        get { shared.read(\.deeplinkSchema) }
        set { shared.write(\.deeplinkSchema, newValue) }
    }

    /// Print framework logs to console during tests.
    /// Default value is true.
    public static var printLogToConsole: Bool {
        get { shared.read(\.printLogToConsole) }
        set { shared.write(\.printLogToConsole, newValue) }
    }

    /// Structured UI query evidence collection level.
    /// Defaults to failure-focused `basic` collection.
    public static var uiQueryEvidenceLevel: XCEasyUIQueryEvidenceLevel {
        get { shared.read(\.uiQueryEvidenceLevel) }
        set { shared.write(\.uiQueryEvidenceLevel, newValue) }
    }

    /// Behavior for locators that match multiple elements without an index.
    /// Defaults to `strict` so ambiguity cannot be hidden by `firstMatch`.
    public static var uiQueryAmbiguityPolicy: XCEasyUIQueryAmbiguityPolicy {
        get { shared.read(\.uiQueryAmbiguityPolicy) }
        set { shared.write(\.uiQueryAmbiguityPolicy, newValue) }
    }

    /// Geometry policy used for displayed, not-displayed, and hidden observations.
    /// Defaults to viewport intersection with a documented fallback when XCUI omits app geometry.
    public static var visibilityPolicy: XCEasyVisibilityPolicy {
        get { shared.read(\.visibilityPolicy) }
        set { shared.write(\.visibilityPolicy, newValue) }
    }

    /// Performance telemetry and budget policy for the current execution.
    public static var performance: XCEasyPerformanceConfiguration {
        get { shared.read(\.performance) }
        set { shared.write(\.performance, newValue) }
    }

    /// Selector-healing analysis policy. Source changes always require review.
    public static var healing: XCEasyHealingConfiguration {
        get { shared.read(\.healing) }
        set { shared.write(\.healing, newValue) }
    }

    /// Maximum UTF-8 size of one accessibility snapshot attachment.
    /// Values below zero are normalized to zero by collectors.
    public static var diagnosticSnapshotByteLimit: Int {
        get { shared.read(\.diagnosticSnapshotByteLimit) }
        set { shared.write(\.diagnosticSnapshotByteLimit, newValue) }
    }

    // MARK: - Enums

    /// Supported localization languages.
    public enum Language: String {
        case en = "en"
        case ru = "ru"
    }

    // MARK: - Public Methods

    /// Method for updating configuration.
    ///
    /// - Parameters:
    ///   - bundleId: Testing application bundleId.
    ///   - findTimeout: Timeout for elements safe search.
    ///   - actionTimeout: Timeout for safe actions with elements.
    ///   - assertionTimeout: Timeout for safe assertions.
    ///   - requestTimeout: Timeout for requests.
    ///   - actionPolicy: Default readiness and dispatch policy for UI actions.
    ///   - localization: Language of the localization.
    ///   - deeplinkSchema: Schema name.
    ///   - printLogToConsole: Whether to print logs to console.
    ///   - uiQueryEvidenceLevel: Structured UI query evidence collection level.
    ///   - uiQueryAmbiguityPolicy: Whether multiple matches fail or explicitly select the first.
    ///   - visibilityPolicy: Geometry policy for displayed and hidden element states.
    ///   - performance: Performance collection and budget policy.
    ///   - healing: Evidence-backed selector-healing policy.
    ///   - diagnosticSnapshotByteLimit: Maximum accessibility snapshot attachment size.
    public static func apply(
        bundleId: String? = nil,
        findTimeout: TimeInterval? = nil,
        actionTimeout: TimeInterval? = nil,
        assertionTimeout: TimeInterval? = nil,
        requestTimeout: TimeInterval? = nil,
        actionPolicy: XCEasyActionPolicy? = nil,
        localization: Language? = nil,
        deeplinkSchema: String? = nil,
        printLogToConsole: Bool? = nil,
        uiQueryEvidenceLevel: XCEasyUIQueryEvidenceLevel? = nil,
        uiQueryAmbiguityPolicy: XCEasyUIQueryAmbiguityPolicy? = nil,
        visibilityPolicy: XCEasyVisibilityPolicy? = nil,
        performance: XCEasyPerformanceConfiguration? = nil,
        healing: XCEasyHealingConfiguration? = nil,
        diagnosticSnapshotByteLimit: Int? = nil
    ) {
        if let bundleId = bundleId {
            self.bundleId = bundleId
        }
        if let findTimeout = findTimeout {
            self.findTimeout = findTimeout
        }
        if let actionTimeout = actionTimeout {
            self.actionTimeout = actionTimeout
        }
        if let assertionTimeout = assertionTimeout {
            self.assertionTimeout = assertionTimeout
        }
        if let requestTimeout = requestTimeout {
            self.requestTimeout = requestTimeout
        }
        if let actionPolicy {
            self.actionPolicy = actionPolicy
        }
        if let localization = localization {
            self.localization = localization
        }
        if let deeplinkSchema = deeplinkSchema {
            self.deeplinkSchema = deeplinkSchema
        }
        if let printLogToConsole = printLogToConsole {
            self.printLogToConsole = printLogToConsole
        }
        if let uiQueryEvidenceLevel = uiQueryEvidenceLevel {
            self.uiQueryEvidenceLevel = uiQueryEvidenceLevel
        }
        if let uiQueryAmbiguityPolicy {
            self.uiQueryAmbiguityPolicy = uiQueryAmbiguityPolicy
        }
        if let visibilityPolicy {
            self.visibilityPolicy = visibilityPolicy
        }
        if let performance {
            self.performance = performance
        }
        if let healing {
            self.healing = healing
        }
        if let diagnosticSnapshotByteLimit {
            self.diagnosticSnapshotByteLimit = diagnosticSnapshotByteLimit
        }
    }

    /// Logs the current configuration.
    public static func logConfig() {
        let stepTitle = LocalizationManager.shared
            .string(forKey: "xceasy_basic_config_title")
        step(stepTitle) {
            XCEasyTestLogger.shared.log("bundleId: \(bundleId)")
            XCEasyTestLogger.shared.log("findTimeout: \(findTimeout)")
            XCEasyTestLogger.shared.log("actionTimeout: \(actionTimeout)")
            XCEasyTestLogger.shared.log("assertionTimeout: \(assertionTimeout)")
            XCEasyTestLogger.shared.log("requestTimeout: \(requestTimeout)")
            XCEasyTestLogger.shared.log("actionPolicy: \(actionPolicy.rawValue)")
            XCEasyTestLogger.shared.log("localization: \(localization.rawValue)")
            XCEasyTestLogger.shared.log("deeplinkSchema: \(deeplinkSchema)")
            XCEasyTestLogger.shared.log("printLogToConsole: \(printLogToConsole)")
            XCEasyTestLogger.shared.log("uiQueryEvidenceLevel: \(uiQueryEvidenceLevel.rawValue)")
            XCEasyTestLogger.shared.log("uiQueryAmbiguityPolicy: \(uiQueryAmbiguityPolicy.rawValue)")
            XCEasyTestLogger.shared.log("visibilityPolicy: \(visibilityPolicy.rawValue)")
            XCEasyTestLogger.shared.log("performance.level: \(performance.level.rawValue)")
            XCEasyTestLogger.shared.log("performance.budgetPolicy: \(performance.budgetPolicy.rawValue)")
            XCEasyTestLogger.shared.log("healing.mode: \(healing.mode.rawValue)")
            XCEasyTestLogger.shared.log("diagnosticSnapshotByteLimit: \(diagnosticSnapshotByteLimit)")
        }
    }

    // MARK: - Initialization

    /// Creates the single configuration store used to snapshot per-test values.
    private init() {}
}
