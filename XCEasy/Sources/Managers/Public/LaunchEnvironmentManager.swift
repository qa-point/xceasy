import Foundation

/// Thread-safe store for environment values passed to the application at its next launch.
///
/// Assigning the same key again replaces its previous value. Values configured outside a test
/// become defaults; each test receives an execution-owned copy that is applied to
/// `XCUIApplication.launchEnvironment` without leaking changes to parallel tests.
public enum LaunchEnvironmentManager {
    private static let defaultsLock = NSLock()
    private static var defaultValues: [String: String] = [:]
    private static let executionValues = ThreadLocal<[String: String]>()

    /// Snapshot of all configured launch-environment values.
    public static var values: [String: String] {
        if let values = executionValues.value { return values }
        return defaultsLock.xceasyWithLock { defaultValues }
    }

    /// Adds or replaces one environment value.
    ///
    /// - Parameters:
    ///   - value: Value visible to the launched application.
    ///   - key: Environment-variable name.
    public static func set(_ value: String, for key: String) {
        mutate { $0[key] = value }
    }

    /// Adds or replaces several environment values atomically.
    ///
    /// - Parameter values: Key/value pairs to merge into the current store.
    public static func set(_ values: [String: String]) {
        mutate { $0.merge(values) { _, newValue in newValue } }
    }

    /// Returns the configured value for one key.
    ///
    /// - Parameter key: Environment-variable name.
    /// - Returns: Stored value, or `nil` when the key is not configured.
    public static func value(for key: String) -> String? {
        values[key]
    }

    /// Removes one environment value when it is present.
    ///
    /// - Parameter key: Environment-variable name to remove.
    public static func remove(_ key: String) {
        mutate { _ = $0.removeValue(forKey: key) }
    }

    /// Removes every configured launch-environment value.
    public static func removeAll() {
        mutate { $0.removeAll() }
    }

    /// Copies process defaults into the current test execution.
    internal static func beginExecution() {
        executionValues.value = defaultsLock.xceasyWithLock { defaultValues }
    }

    /// Releases environment values owned by the completed test execution.
    internal static func endExecution() {
        executionValues.value = nil
    }

    /// Mutates the current test values, or process defaults outside a test execution.
    ///
    /// - Parameter body: In-place values update.
    private static func mutate(_ body: (inout [String: String]) -> Void) {
        if var values = executionValues.value {
            body(&values)
            executionValues.value = values
            return
        }
        defaultsLock.xceasyWithLock { body(&defaultValues) }
    }
}
