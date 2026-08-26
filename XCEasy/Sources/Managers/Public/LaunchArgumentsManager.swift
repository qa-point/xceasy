import Foundation

/// Thread-safe store for arguments passed to the application at its next launch.
///
/// Values configured outside a test become defaults. At test start the framework creates an
/// execution-owned copy, applies changes made in `configuration()`, and copies ``values`` into
/// `XCUIApplication.launchArguments` without leaking them to parallel tests.
public enum LaunchArgumentsManager {
    private static let defaultsLock = NSLock()
    private static var defaultValues: [String] = []
    private static let executionValues = ThreadLocal<[String]>()

    /// Current launch arguments in insertion order.
    public static var values: [String] {
        if let values = executionValues.value { return values }
        return defaultsLock.xceasyWithLock { defaultValues }
    }

    /// Adds one argument for subsequent application launches.
    ///
    /// - Parameter argument: Complete launch argument, for example `"-ui_testing"`.
    public static func add(_ argument: String) {
        mutate { $0.append(argument) }
    }

    /// Removes the first occurrence of an argument when it is present.
    ///
    /// - Parameter argument: Exact argument to remove.
    public static func remove(_ argument: String) {
        mutate { values in
            guard let index = values.firstIndex(of: argument) else { return }
            values.remove(at: index)
        }
    }

    /// Removes every configured launch argument.
    public static func removeAll() {
        mutate { $0.removeAll() }
    }

    /// Copies process defaults into the current test execution.
    internal static func beginExecution() {
        executionValues.value = defaultsLock.xceasyWithLock { defaultValues }
    }

    /// Releases arguments owned by the completed test execution.
    internal static func endExecution() {
        executionValues.value = nil
    }

    /// Mutates the current test values, or process defaults outside a test execution.
    ///
    /// - Parameter body: In-place values update.
    private static func mutate(_ body: (inout [String]) -> Void) {
        if var values = executionValues.value {
            body(&values)
            executionValues.value = values
            return
        }
        defaultsLock.xceasyWithLock { body(&defaultValues) }
    }
}
